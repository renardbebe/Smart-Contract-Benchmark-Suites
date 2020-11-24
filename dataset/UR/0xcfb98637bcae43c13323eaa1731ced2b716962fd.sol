 

pragma solidity ^0.4.11;

 
contract SafeMath {

    function safeAdd(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x + y;
        assert((z >= x) && (z >= y));
        return z;
    }

    function safeSubtract(uint256 x, uint256 y) internal returns(uint256) {
        assert(x >= y);
        uint256 z = x - y;
        return z;
    }

    function safeMult(uint256 x, uint256 y) internal returns(uint256) {
        uint256 z = x * y;
        assert((x == 0)||(z/x == y));
        return z;
    }
}

contract Token {
    uint256 public totalSupply;

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract StandardToken is Token, SafeMath {

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    }

    function transfer(address _to, uint256 _value)
    returns (bool success)
    {
        if (balances[msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[msg.sender] = safeSubtract(balances[msg.sender], _value);
            balances[_to] = safeAdd(balances[_to], _value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success)
    {
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to] + _value > balances[_to]) {
            balances[_to] = safeAdd(balances[_to], _value);
            balances[_from] = safeSubtract(balances[_from], _value);
            allowed[_from][msg.sender] = safeSubtract(allowed[_from][msg.sender], _value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value)
    onlyPayloadSize(2)
    returns (bool success)
    {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender)
    constant
    onlyPayloadSize(2)
    returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }
}

 
contract NEToken is StandardToken {

     
    string public constant name = "Nimiq Network Interim Token";
    string public constant symbol = "NET";
    uint256 public constant decimals = 18;
    string public version = "0.8";

     
    address public ethFundDeposit;

     
    enum ContractState { Fundraising, Finalized, Redeeming, Paused }
    ContractState public state;            
    ContractState private savedState;      

    uint256 public fundingStartBlock;         
    uint256 public fundingEndBlock;           
    uint256 public exchangeRateChangesBlock;  

    uint256 public constant TOKEN_FIRST_EXCHANGE_RATE = 175;  
    uint256 public constant TOKEN_SECOND_EXCHANGE_RATE = 125;  
    uint256 public constant TOKEN_CREATION_CAP = 10.5 * (10**6) * 10**decimals;  
    uint256 public constant ETH_RECEIVED_CAP = 60 * (10**3) * 10**decimals;  
    uint256 public constant ETH_RECEIVED_MIN = 5 * (10**3) * 10**decimals;  
    uint256 public constant TOKEN_MIN = 1 * 10**decimals;  

     
    uint256 public totalReceivedEth = 0;

     
     
    mapping (address => uint256) private ethBalances;

     
    event LogRefund(address indexed _to, uint256 _value);
    event LogCreateNET(address indexed _to, uint256 _value);
    event LogRedeemNET(address indexed _to, uint256 _value, bytes32 _nimiqAddress);

    modifier isFinalized() {
        require(state == ContractState.Finalized);
        _;
    }

    modifier isFundraising() {
        require(state == ContractState.Fundraising);
        _;
    }

    modifier isRedeeming() {
        require(state == ContractState.Redeeming);
        _;
    }

    modifier isPaused() {
        require(state == ContractState.Paused);
        _;
    }

    modifier notPaused() {
        require(state != ContractState.Paused);
        _;
    }

    modifier isFundraisingIgnorePaused() {
        require(state == ContractState.Fundraising || (state == ContractState.Paused && savedState == ContractState.Fundraising));
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == ethFundDeposit);
        _;
    }

    modifier minimumReached() {
        require(totalReceivedEth >= ETH_RECEIVED_MIN);
        _;
    }

     
    function NEToken(
    address _ethFundDeposit,
    uint256 _fundingStartBlock,
    uint256 _fundingEndBlock,
    uint256 _exchangeRateChangesBlock)
    {
         
        require(block.number <= _fundingStartBlock);  
        require(_fundingStartBlock <= _exchangeRateChangesBlock);  
        require(_exchangeRateChangesBlock <= _fundingEndBlock);  

         
        state = ContractState.Fundraising;
        savedState = ContractState.Fundraising;

        ethFundDeposit = _ethFundDeposit;
        fundingStartBlock = _fundingStartBlock;
        fundingEndBlock = _fundingEndBlock;
        exchangeRateChangesBlock = _exchangeRateChangesBlock;
        totalSupply = 0;
    }

     
    function transfer(address _to, uint256 _value)
    isFinalized  
    onlyPayloadSize(2)
    returns (bool success)
    {
        return super.transfer(_to, _value);
    }


     
    function transferFrom(address _from, address _to, uint256 _value)
    isFinalized  
    onlyPayloadSize(3)
    returns (bool success)
    {
        return super.transferFrom(_from, _to, _value);
    }


     
    function createTokens()
    payable
    external
    isFundraising
    {
        require(block.number >= fundingStartBlock);
        require(block.number <= fundingEndBlock);
        require(msg.value > 0);

         
         
        uint256 checkedReceivedEth = safeAdd(totalReceivedEth, msg.value);
        require(checkedReceivedEth <= ETH_RECEIVED_CAP);

         
         
         
        uint256 tokens = safeMult(msg.value, getCurrentTokenPrice());
        require(tokens >= TOKEN_MIN);
        uint256 checkedSupply = safeAdd(totalSupply, tokens);
        require(checkedSupply <= TOKEN_CREATION_CAP);

         
         
        ethBalances[msg.sender] = safeAdd(ethBalances[msg.sender], msg.value);
        totalReceivedEth = checkedReceivedEth;
        totalSupply = checkedSupply;
        balances[msg.sender] += tokens;   

         
        LogCreateNET(msg.sender, tokens);
    }


     
    function getCurrentTokenPrice()
    private
    constant
    returns (uint256 currentPrice)
    {
        if (block.number < exchangeRateChangesBlock) {
            return TOKEN_FIRST_EXCHANGE_RATE;
        } else {
            return TOKEN_SECOND_EXCHANGE_RATE;
        }
    }


     
    function redeemTokens(bytes32 nimiqAddress)
    external
    isRedeeming
    {
        uint256 netVal = balances[msg.sender];
        require(netVal >= TOKEN_MIN);  

         
        if (!super.transfer(ethFundDeposit, netVal)) throw;

         
        LogRedeemNET(msg.sender, netVal, nimiqAddress);
    }


     
    function retrieveEth(uint256 _value)
    external
    minimumReached
    onlyOwner
    {
        require(_value <= this.balance);

         
        ethFundDeposit.transfer(_value);
    }


     
    function finalize()
    external
    isFundraising
    minimumReached
    onlyOwner  
    {
        require(block.number > fundingEndBlock || totalSupply >= TOKEN_CREATION_CAP || totalReceivedEth >= ETH_RECEIVED_CAP);  

         
        state = ContractState.Finalized;
        savedState = ContractState.Finalized;

         
        ethFundDeposit.transfer(this.balance);
    }


     
    function startRedeeming()
    external
    isFinalized  
    onlyOwner    
    {
         
        state = ContractState.Redeeming;
        savedState = ContractState.Redeeming;
    }


     
    function pause()
    external
    notPaused    
    onlyOwner    
    {
         
        savedState = state;
        state = ContractState.Paused;
    }


     
    function proceed()
    external
    isPaused
    onlyOwner    
    {
         
        state = savedState;
    }


     
    function refund()
    external
    isFundraisingIgnorePaused  
    {
        require(block.number > fundingEndBlock);  
        require(totalReceivedEth < ETH_RECEIVED_MIN);   

        uint256 netVal = balances[msg.sender];
        require(netVal > 0);
        uint256 ethVal = ethBalances[msg.sender];
        require(ethVal > 0);

         
        balances[msg.sender] = 0;
        ethBalances[msg.sender] = 0;
        totalSupply = safeSubtract(totalSupply, netVal);  

         
        LogRefund(msg.sender, ethVal);

         
         
        msg.sender.transfer(ethVal);
    }
}