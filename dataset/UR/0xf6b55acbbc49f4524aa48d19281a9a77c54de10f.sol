 

pragma solidity ^0.4.16;

 
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

 
contract Owned {

    address public owner;
    address public newOwner;
    modifier onlyOwner { assert(msg.sender == owner); _; }

    event OwnerUpdate(address _prevOwner, address _newOwner);

    function Owned() {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract ERC20 {
    function totalSupply() constant returns (uint _totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

 
contract ERC20Token is ERC20, SafeMath {

    mapping(address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
    uint256 public totalTokens; 
    uint256 public contributorTokens; 

    function transfer(address _to, uint256 _value) returns (bool success) {
        if (balances[msg.sender] >= _value && _value > 0) {
            balances[msg.sender] = safeSub(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        var _allowance = allowed[_from][msg.sender];
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSub(balances[_from], _value);
            allowed[_from][msg.sender] = safeSub(_allowance, _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function totalSupply() constant returns (uint256) {
        return totalTokens;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract Wolk is ERC20Token, Owned {

     
    string  public constant name = "WOLK TOKEN";
    string  public constant symbol = "WLK";
    uint256 public constant decimals = 18;

     
    uint256 public reserveBalance = 0; 
    uint8   public percentageETHReserve = 5;

     
    address public wolkInc;

     
    bool    public allSaleCompleted = false;

    modifier isTransferable { require(allSaleCompleted); _; }

     
    event WolkCreated(address indexed _to, uint256 _tokenCreated);
    event WolkDestroyed(address indexed _from, uint256 _tokenDestroyed);
    event LogRefund(address indexed _to, uint256 _value);
}

contract WolkTGE is Wolk {

     
    mapping (address => uint256) contribution;
    mapping (address => bool) whitelistContributor;
    
    uint256 public constant tokenGenerationMin =   1 * 10**4 * 10**decimals;
    uint256 public constant tokenGenerationMax = 175 * 10**5 * 10**decimals;
    uint256 public start_block;
    uint256 public end_time;
    bool    kycRequirement = true;

     
     
     
     
     
    function wolkGenesis(uint256 _startBlock, uint256 _endTime, address _wolkinc) onlyOwner returns (bool success){
        require((totalTokens < 1) && (block.number <= _startBlock)); 
        start_block = _startBlock;
        end_time = _endTime;
        wolkInc = _wolkinc;
        return true;
    }
    
     
     
    function updateRequireKYC(bool _kycRequirement) onlyOwner returns (bool success) {
        kycRequirement = _kycRequirement;
        return true;
    } 
    
     
     
    function addParticipant(address[] _participants) onlyOwner returns (bool success) {
        for (uint cnt = 0; cnt < _participants.length; cnt++){           
            whitelistContributor[_participants[cnt]] = true;
        }
        return true;
    } 

     
     
     
    function removeParticipant(address[] _participants) onlyOwner returns (bool success){         
        for (uint cnt = 0; cnt < _participants.length; cnt++){           
            whitelistContributor[_participants[cnt]] = false;
        }
        return true;
    }

     
     
     
    function participantStatus(address _participant) constant returns (bool status) {
        return(whitelistContributor[_participant]);
    }    

     
     
    function tokenGenerationEvent(address _participant) payable external {
        require( ( whitelistContributor[_participant] || whitelistContributor[msg.sender] || balances[_participant] > 0 || kycRequirement )  && !allSaleCompleted && ( block.timestamp <= end_time ) && msg.value > 0);
    
        uint256 rate = 1000;   
        rate = safeDiv( 175 * 10**5 * 10**decimals, safeAdd( 875 * 10**1 * 10**decimals, safeDiv( totalTokens, 2 * 10**3)) );
        if ( rate > 2000 ) rate = 2000;
        if ( rate < 500 ) rate = 500;
        require(block.number >= start_block) ;

        uint256 tokens = safeMul(msg.value, rate);
        uint256 checkedSupply = safeAdd(totalTokens, tokens);
        require(checkedSupply <= tokenGenerationMax);

        totalTokens = checkedSupply;
        contributorTokens = safeAdd(contributorTokens, tokens);
        
        Transfer(address(this), _participant, tokens);
        balances[_participant] = safeAdd(balances[_participant], tokens);
        contribution[_participant] = safeAdd(contribution[_participant], msg.value);
        WolkCreated(_participant, tokens);  
    }

    function finalize() onlyOwner external {
        require(!allSaleCompleted);
        end_time = block.timestamp;

         
        uint256 wolkincTokens =  50 * 10**6 * 10**decimals;
        balances[wolkInc] = wolkincTokens;
        totalTokens = safeAdd(totalTokens, wolkincTokens);                 

        WolkCreated(wolkInc, wolkincTokens);  
        allSaleCompleted = true;
        reserveBalance = safeDiv(safeMul(contributorTokens, percentageETHReserve), 100000);
        var withdrawalBalance = safeSub(this.balance, reserveBalance);
        msg.sender.transfer(withdrawalBalance);
    }

    function refund() external {
        require((contribution[msg.sender] > 0) && (!allSaleCompleted) && (block.timestamp > end_time)  && (totalTokens < tokenGenerationMin));
        uint256 tokenBalance = balances[msg.sender];
        uint256 refundBalance = contribution[msg.sender];
        balances[msg.sender] = 0;
        contribution[msg.sender] = 0;
        totalTokens = safeSub(totalTokens, tokenBalance);
        WolkDestroyed(msg.sender, tokenBalance);
        LogRefund(msg.sender, refundBalance);
        msg.sender.transfer(refundBalance); 
    }

    function transferAnyERC20Token(address _tokenAddress, uint256 _amount) onlyOwner returns (bool success) {
        return ERC20(_tokenAddress).transfer(owner, _amount);
    }
}

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint8 _reserveRatio, uint256 _sellAmount) public constant returns (uint256);
}

contract WolkExchange is  WolkTGE {
    address public exchangeFormula;
    bool    public isPurchasePossible = false;
    bool    public isSellPossible = false;

    modifier isPurchasable { require(isPurchasePossible && allSaleCompleted); _; }
    modifier isSellable { require(isSellPossible && allSaleCompleted); _; }
    
     
     
     
    function setExchangeFormula(address _newExchangeformula) onlyOwner returns (bool success){
        require(sellWolkEstimate(10**decimals, _newExchangeformula) > 0);
        require(purchaseWolkEstimate(10**decimals, _newExchangeformula) > 0);
        isPurchasePossible = false;
        isSellPossible = false;
        exchangeFormula = _newExchangeformula;
        return true;
    }

     
     
     
    function updateReserveRatio(uint8 _newReserveRatio) onlyOwner returns (bool success) {
        require(allSaleCompleted && ( _newReserveRatio > 1 ) && ( _newReserveRatio < 20 ) );
        percentageETHReserve = _newReserveRatio;
        return true;
    }

     
     
     
    function updatePurchasePossible(bool _isRunning) onlyOwner returns (bool success){
        if (_isRunning){
            require(sellWolkEstimate(10**decimals, exchangeFormula) > 0);
            require(purchaseWolkEstimate(10**decimals, exchangeFormula) > 0);   
        }
        isPurchasePossible = _isRunning;
        return true;
    }

     
     
     
    function updateSellPossible(bool _isRunning) onlyOwner returns (bool success){
        if (_isRunning){
            require(sellWolkEstimate(10**decimals, exchangeFormula) > 0);
            require(purchaseWolkEstimate(10**decimals, exchangeFormula) > 0);   
        }
        isSellPossible = _isRunning;
        return true;
    }

    function sellWolkEstimate(uint256 _wolkAmountest, address _formula) internal returns(uint256) {
        uint256 ethReceivable =  IBancorFormula(_formula).calculateSaleReturn(contributorTokens, reserveBalance, percentageETHReserve, _wolkAmountest);
        return ethReceivable;
    }
    
    function purchaseWolkEstimate(uint256 _ethAmountest, address _formula) internal returns(uint256) {
        uint256 wolkReceivable = IBancorFormula(_formula).calculatePurchaseReturn(contributorTokens, reserveBalance, percentageETHReserve, _ethAmountest);
        return wolkReceivable;
    }
    
     
     
     
    function sellWolk(uint256 _wolkAmount) isSellable() returns(uint256) {
        require((balances[msg.sender] >= _wolkAmount));
        uint256 ethReceivable = sellWolkEstimate(_wolkAmount,exchangeFormula);
        require(this.balance > ethReceivable);
        balances[msg.sender] = safeSub(balances[msg.sender], _wolkAmount);
        contributorTokens = safeSub(contributorTokens, _wolkAmount);
        totalTokens = safeSub(totalTokens, _wolkAmount);
        reserveBalance = safeSub(this.balance, ethReceivable);
        WolkDestroyed(msg.sender, _wolkAmount);
        Transfer(msg.sender, 0x00000000000000000000, _wolkAmount);
        msg.sender.transfer(ethReceivable);
        return ethReceivable;     
    }

     
     
    function purchaseWolk(address _buyer) isPurchasable() payable returns(uint256){
        require(msg.value > 0);
        uint256 wolkReceivable = purchaseWolkEstimate(msg.value, exchangeFormula);
        require(wolkReceivable > 0);

        contributorTokens = safeAdd(contributorTokens, wolkReceivable);
        totalTokens = safeAdd(totalTokens, wolkReceivable);
        balances[_buyer] = safeAdd(balances[_buyer], wolkReceivable);
        reserveBalance = safeAdd(reserveBalance, msg.value);
        WolkCreated(_buyer, wolkReceivable);
        Transfer(address(this),_buyer,wolkReceivable);
        return wolkReceivable;
    }

     
     
    function () payable {
        require(msg.value > 0);
        if(!allSaleCompleted){
            this.tokenGenerationEvent.value(msg.value)(msg.sender);
        } else if ( block.timestamp >= end_time ){
            this.purchaseWolk.value(msg.value)(msg.sender);
        } else {
            revert();
        }
    }
}