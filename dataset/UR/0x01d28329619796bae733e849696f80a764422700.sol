 

pragma solidity ^0.4.15;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ApproveAndCallReceiver {
    function receiveApproval(
        address _from, 
        uint256 _amount, 
        address _token, 
        bytes _data
    ) public;
}

 
contract Controlled {
     
     
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

     
    address public controller;

    function Controlled() public {
       
      controller = msg.sender;
       
    }

     
     
    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}

contract ERC20Token {
     
     
    uint256 public totalSupply;
     

     
     
    mapping (address => uint256) public balanceOf;
     

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success);

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
     
     
    mapping (address => mapping (address => uint256)) public allowance;
     

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable public returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
}


contract TokenI is ERC20Token, Controlled {

    string public name;                 
    uint8 public decimals;              
    string public symbol;               

 
 
 

     
     
     
     
     
     
     
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) public returns (bool success);

 
 
 

     
     
     
     
    function generateTokens(address _owner, uint _amount) public returns (bool);


     
     
     
     
    function destroyTokens(address _owner, uint _amount) public returns (bool);

 
 
 

     
     
    function enableTransfers(bool _transfersEnabled) public;

 
 
 

     
     
     
     
    function claimTokens(address _token) public;

 
 
 

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}

contract Token is TokenI {
    using SafeMath for uint256;

    address public owner;

    uint256 public maximumToken = 10 * 10**8 * 10**18;  

    struct FreezeInfo {
        address user;
        uint256 amount;
    }
     
    mapping (uint8 => mapping (uint8 => FreezeInfo)) public freezeOf;  
    mapping (uint8 => uint8) public lastFreezeSeq;  
    mapping (uint8 => uint8) internal unlockTime;

    bool public transfersEnabled;

     
     

     
    event Burn(address indexed from, uint256 value);
    
     
    event Freeze(address indexed from, uint256 value);
    
     
    event Unfreeze(address indexed from, uint256 value);

     
    function Token(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol,
        bool transfersEnable
        ) public {
        balanceOf[msg.sender] = initialSupply;
        totalSupply = initialSupply;
        name = tokenName;
        symbol = tokenSymbol;
        decimals = decimalUnits;
        transfersEnabled = transfersEnable;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ownerOrUser(address user){
        require(msg.sender == owner || msg.sender == user);
        _;
    }

    modifier realUser(address user){
        if(user == 0x0){
            revert();
        }
        _;
    }

    modifier moreThanZero(uint256 _value){
        if (_value <= 0){
            revert();
        }
        _;
    }

    modifier moreOrEqualZero(uint256 _value){
        if(_value < 0){
            revert();
        }
        _;
    }

     
     
     
    function isContract(address _addr) constant internal returns(bool) {
        uint size;
        if (_addr == 0) {
            return false;
        }
        assembly {
            size := extcodesize(_addr)
        }
        return size>0;
    }

     
    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) public returns (bool) {
        require(balanceOf[msg.sender] > _value);            
        require(balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[msg.sender] = balanceOf[msg.sender] - _value;                      
        balanceOf[_to] = balanceOf[_to] + _value;                             
        Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) moreThanZero(_value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallReceiver(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) public returns (bool success) {
        require(balanceOf[_from] > _value);                  
        require(balanceOf[_to] + _value > balanceOf[_to]);   
        require(_value < allowance[_from][msg.sender]);      
        balanceOf[_from] = balanceOf[_from] - _value;                            
        balanceOf[_to] = balanceOf[_to] + _value;                              
        allowance[_from][msg.sender] = allowance[_from][msg.sender] + _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
     
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyController public returns (bool success) {
         
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user] - _value;
        freezeOf[_step][lastFreezeSeq[_step]] = FreezeInfo({user:_user, amount:_value});
        lastFreezeSeq[_step]++;
        Freeze(_user, _value);
        return true;
    }

    event info(string name, uint8 value);
    event info256(string name, uint256 value);
    
     
    function unFreeze(uint8 _step) onlyController public returns (bool unlockOver) {
         
        uint8 _end = lastFreezeSeq[_step];
        require(_end > 0);
         
        unlockOver = (_end <= 49);
        uint8 _start = (_end > 49) ? _end-50 : 0;
         
        for(; _end>_start; _end--){
            FreezeInfo storage fInfo = freezeOf[_step][_end-1];
            uint256 _amount = fInfo.amount;
            balanceOf[fInfo.user] += _amount;
            delete freezeOf[_step][_end-1];
            lastFreezeSeq[_step]--;
            Unfreeze(fInfo.user, _amount);
        }
    }
    
     
    function() payable public {
         
        require(isContract(controller));
        bool proxyPayment = TokenController(controller).proxyPayment.value(msg.value)(msg.sender);
        require(proxyPayment);
    }

 
 
 

     
     
     
     
    function generateTokens(address _user, uint _amount) onlyController public returns (bool) {
        require(balanceOf[owner] >= _amount);
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        Transfer(0, _user, _amount);
        return true;
    }

     
     
     
     
    function destroyTokens(address _user, uint _amount) onlyController public returns (bool) {
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        Transfer(_user, 0, _amount);
        return true;
    }

    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] = balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }

 
 
 

     
     
    function enableTransfers(bool _transfersEnabled) onlyController public {
        transfersEnabled = _transfersEnabled;
    }

 
 
 

     
     
     
    function claimTokens(address _token) onlyController public {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        Token token = Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }
}

contract BaseTokenSale is TokenController, Controlled {

    using SafeMath for uint256;

    uint256 public startFundingTime;
    uint256 public endFundingTime;
    
    uint256 constant public maximumFunding = 1951 ether;  
    uint256 public maxFunding;   
    uint256 public minFunding = 0.001 ether;   
    uint256 public tokensPerEther = 41000;
    uint256 constant public maxGasPrice = 50000000000;
    uint256 constant oneDay = 86400;
    uint256 public totalCollected = 0;
    bool    public paused;
    Token public tokenContract;
    bool public finalized = false;
    bool public allowChange = true;
    bool private transfersEnabled = true;
    address private vaultAddress;

    bool private initialed = false;

    event Payment(address indexed _sender, uint256 _ethAmount, uint256 _tokenAmount);

     
    function BaseTokenSale(
        uint _startFundingTime, 
        uint _endFundingTime, 
        address _vaultAddress,
        address _tokenAddress
    ) public {
        require(_endFundingTime > now);
        require(_endFundingTime >= _startFundingTime);
        require(_vaultAddress != 0);
        require(_tokenAddress != 0);
        require(!initialed);

        startFundingTime = _startFundingTime;
        endFundingTime = _endFundingTime;
        vaultAddress = _vaultAddress;
        tokenContract = Token(_tokenAddress);
        paused = false;
        initialed = true;
    }


    function setTime(uint time1, uint time2) onlyController public {
        require(endFundingTime > now && startFundingTime < endFundingTime);
        startFundingTime = time1;
        endFundingTime = time2;
    }


     
    function () payable notPaused public {
        doPayment(msg.sender);
    }

     
    function proxyPayment(address _owner) payable notPaused public returns(bool success) {
        return doPayment(_owner);
    }

     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool success) {
        if ( _from == vaultAddress || transfersEnabled) {
            return true;
        }
        _to;
        _amount;
        return false;
    }

     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool success) {
        if ( _owner == vaultAddress ) {
            return true;
        }
        _spender;
        _amount;
        return false;
    }

    event info(string name, string msg);
    event info256(string name, uint256 value);

     
     
     
     
    function doPayment(address _owner) internal returns(bool success) {
         
        require(msg.value >= minFunding);
        require(endFundingTime > now);

         
        require(totalCollected < maximumFunding);
        totalCollected = totalCollected.add(msg.value);

         
        require(vaultAddress.send(msg.value));
        
        uint256 tokenValue = tokensPerEther.mul(msg.value);
         
        require(tokenContract.generateTokens(_owner, tokenValue));
        uint256 lock1 = tokenValue / 10;     
        uint256 lock2 = tokenValue / 5;      
        require(tokenContract.freeze(_owner, lock1, 0));  
        tokenContract.freeze(_owner, lock1, 1);  
        tokenContract.freeze(_owner, lock1, 2);
        tokenContract.freeze(_owner, lock1, 3);
        tokenContract.freeze(_owner, lock1, 4);
        tokenContract.freeze(_owner, lock2, 5);
         
        Payment(_owner, msg.value, tokenValue);
        return true;
    }

    function changeTokenController(address _newController) onlyController public {
        tokenContract.changeController(_newController);
    }

     
    function changeTokensPerEther(uint256 _newRate) onlyController public {
        require(allowChange);
        tokensPerEther = _newRate;
    }

    function changeFundingLimit(uint256 _min, uint256 _max) onlyController public {
        require(_min > 0 && _min <= _max);
        minFunding = _min;
        maxFunding = _max;
    }

     
    function allowTransfersEnabled(bool _allow) onlyController public {
        transfersEnabled = _allow;
    }

     
     
     
    function isContract(address _addr) constant internal returns (bool) {
        if (_addr == 0) {
            return false;
        }
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        }
        return (size > 0);
    }

     
     
     
    function finalizeSale() onlyController public {
        require(now > endFundingTime || totalCollected >= maximumFunding);
        require(!finalized);

         
        uint256 totalTokens = totalCollected * tokensPerEther * 10**18;
        if (!tokenContract.generateTokens(vaultAddress, totalTokens)) {
            revert();
        }

        finalized = true;
        allowChange = false;
    }

 
 
 

     
     
     
     
    function claimTokens(address _token) onlyController public {
        if (_token == 0x0) {
            controller.transfer(this.balance);
            return;
        }

        ERC20Token token = ERC20Token(_token);
        uint balance = token.balanceOf(this);
        token.transfer(controller, balance);
        ClaimedTokens(_token, controller, balance);
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

   
    function pauseContribution() onlyController public {
        paused = true;
    }

     
    function resumeContribution() onlyController public {
        paused = false;
    }

    modifier notPaused() {
        require(!paused);
        _;
    }
}