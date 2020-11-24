 

pragma solidity ^0.4.24;

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
    function receiveApproval(address _from, uint256 _amount, address _token, bytes _data) public;
}

contract Controlled {
    modifier onlyController { 
        require(msg.sender == controller); 
        _; 
    }

    address public controller;

    constructor() public {
      controller = msg.sender;
    }

    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}

contract TokenAbout is Controlled {
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

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

    function claimTokens(address[] tokens) onlyController public {
        require(tokens.length <= 100, "tokens.length too long");
        address _token;
        uint256 balance;
        ERC20Token token;
        for(uint256 i; i<tokens.length; i++){
            _token = tokens[i];
            if (_token == 0x0) {
                balance = address(this).balance;
                if(balance > 0){
                    msg.sender.transfer(balance);
                }
            }else{
                token = ERC20Token(_token);
                balance = token.balanceOf(address(this));
                token.transfer(msg.sender, balance);
                emit ClaimedTokens(_token, msg.sender, balance);
            }
        }
    }
}

contract TokenController {
    function proxyPayment(address _owner) payable public returns(bool);
    function onTransfer(address _from, address _to, uint _amount) public view returns(bool);
    function onApprove(address _owner, address _spender, uint _amount) public view returns(bool);
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

contract TokenI is ERC20Token, Controlled {
    string public name;                 
    uint8 public decimals = 18;              
    string public symbol;               
    function approveAndCall( address _spender, uint256 _amount, bytes _extraData) public returns (bool success);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount) public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
}

contract Token is TokenI, TokenAbout {
    using SafeMath for uint256;
    address public owner;
    string public techProvider = "WeYii Tech(https://weyii.co)";

    mapping (uint8 => uint256[]) public freezeOf;  
    uint8  currUnlockStep;  
    uint256 currUnlockSeq;  

    mapping (uint8 => bool) public stepUnlockInfo;  
    mapping (address => uint256) public freezeOfUser;  
    mapping (uint8 => uint256) public stepLockend;  

    bool public transfersEnabled = true;

    event Burn(address indexed from, uint256 value);
    event Freeze(address indexed from, uint256 value);
    event Unfreeze(address indexed from, uint256 value);

    constructor(uint256 initialSupply, string tokenName, string tokenSymbol, address initialOwner) public {
        name = tokenName;
        symbol = tokenSymbol;
        owner = initialOwner;
        totalSupply = initialSupply*uint256(10)**decimals;
        balanceOf[owner] = totalSupply;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier ownerOrController(){
        require(msg.sender == owner || msg.sender == controller);
        _;
    }

    modifier transable(){
        require(transfersEnabled);
        _;
    }

    modifier ownerOrUser(address user){
        require(msg.sender == owner || msg.sender == user);
        _;
    }

    modifier userOrController(address user){
        require(msg.sender == user || msg.sender == owner || msg.sender == controller);
        _;
    }

    modifier realUser(address user){
        require(user != 0x0);
        _;
    }

    modifier moreThanZero(uint256 _value){
        require(_value > 0);
        _;
    }

    modifier userEnough(address _user, uint256 _amount) {
        require(balanceOf[_user] >= _amount);
        _;
    }

    function addLockStep(uint8 _step, uint _endTime) onlyController external returns(bool) {
        stepLockend[_step] = _endTime;
    }

    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) transable public returns (bool) {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                      
        balanceOf[_to] = balanceOf[_to].add(_value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }

    function approve(address _spender, uint256 _value) transable public returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function unApprove(address _spender, uint256 _value) moreThanZero(_value) transable public returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) transable public returns (bool success) {
        require(approve(_spender, _amount));
        ApproveAndCallReceiver(_spender).receiveApproval(msg.sender, _amount, this, _extraData);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) realUser(_from) realUser(_to) moreThanZero(_value) transable public returns (bool success) {
        require(balanceOf[_from] >= _value);                 
        require(balanceOf[_to] + _value > balanceOf[_to]);   
        require(_value <= allowance[_from][msg.sender]);     
        balanceOf[_from] = balanceOf[_from].sub(_value);                          
        balanceOf[_to] = balanceOf[_to].add(_value);                              
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
    function transferMulti(address[] _to, uint256[] _value) transable public returns (bool success, uint256 amount){
        require(_to.length == _value.length && _to.length <= 300, "transfer once should be less than 300, or will be slow");
        uint256 balanceOfSender = balanceOf[msg.sender];
        uint256 len = _to.length;
        for(uint256 j; j<len; j++){
            require(_value[j] <= balanceOfSender);  
            amount = amount.add(_value[j]);
        }
        require(balanceOfSender > amount );  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        address _toI;
        uint256 _valueI;
        for(uint256 i; i<len; i++){
            _toI = _to[i];
            _valueI = _value[i];
            balanceOf[_toI] = balanceOf[_toI].add(_valueI);
            emit Transfer(msg.sender, _toI, _valueI);
        }
        return (true, amount);
    }
    
    function transferMultiSameValue(address[] _to, uint256 _value) transable public returns (bool){
        require(_to.length <= 300, "transfer once should be less than 300, or will be slow");
        uint256 len = _to.length;
        uint256 amount = _value.mul(len);
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount);
        address _toI;
        for(uint256 i; i<len; i++){
            _toI = _to[i];
            balanceOf[_toI] = balanceOf[_toI].add(_value);
            emit Transfer(msg.sender, _toI, _value);
        }
        return true;
    }

    function freeze(address _user, uint256[] _value, uint8[] _step) onlyController public returns (bool success) {
        require(_value.length == _step.length, "length of value and step must be equal");
        require(_value.length <= 100, "lock step should less or equal than 100");
        uint256 amount;  
        for(uint i; i<_value.length; i++){
            amount = amount.add(_value[i]);
        }
        require(balanceOf[_user] >= amount, "balance of user must bigger or equal than amount of all steps");
        balanceOf[_user] -= amount;
        freezeOfUser[_user] += amount;
        uint256 _valueI;
        uint8 _stepI;
        for(i=0; i<_value.length; i++){
            _valueI = _value[i];
            _stepI = _step[i];
            freezeOf[_stepI].push(uint256(_user)<<96|_valueI);
        }
        emit Freeze(_user, amount);
        return true;
    }

    function unFreeze(uint8 _step) onlyController public returns (bool unlockOver) {
        require(stepLockend[_step]<now && (currUnlockStep==_step || currUnlockSeq==uint256(0)));
        require(stepUnlockInfo[_step]==false);
        uint256[] memory currArr = freezeOf[_step];
        currUnlockStep = _step;
        if(currUnlockSeq==uint256(0)){
            currUnlockSeq = currArr.length;
        }
        uint256 start = ((currUnlockSeq>99)?(currUnlockSeq-99): 0);

        uint256 userLockInfo;
        uint256 _amount;
        address userAddress;
        for(uint256 end = currUnlockSeq; end>start; end--){
            userLockInfo = freezeOf[_step][end-1];
            _amount = userLockInfo&0xFFFFFFFFFFFFFFFFFFFFFFFF;
            userAddress = address(userLockInfo>>96);
            balanceOf[userAddress] += _amount;
            freezeOfUser[userAddress] = freezeOfUser[userAddress].sub(_amount);
            emit Unfreeze(userAddress, _amount);
        }
        if(start==0){
            stepUnlockInfo[_step] = true;
            currUnlockSeq = 0;
        }else{
            currUnlockSeq = start;
        }
        return true;
    }
    
    function() payable public {
        require(isContract(controller), "controller is not a contract");
        bool proxyPayment = TokenController(controller).proxyPayment.value(msg.value)(msg.sender);
        require(proxyPayment);
    }

    function generateTokens(address _user, uint _amount) onlyController userEnough(owner, _amount) public returns (bool) {
        balanceOf[_user] += _amount;
        balanceOf[owner] -= _amount;
        emit Transfer(0, _user, _amount);
        return true;
    }

    function destroyTokens(address _user, uint _amount) onlyController userEnough(_user, _amount) public returns (bool) {
        require(balanceOf[_user] >= _amount);
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        emit Transfer(_user, 0, _amount);
        emit Burn(_user, _amount);
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
}

contract SomeController is Controlled {

    using SafeMath for uint256;

    bool public paused;

     
     

    uint256 public softCap;  
    uint256 public hardCap = 5000*10**18;  
    
    uint256 public minFunding = 10*10**18;   
     
    uint256 public tokensPerEther1 = 128000;  
    uint256 public tokensPerEther2 = 91500;  


    uint256 public totalCollected;
    Token public tokenContract;
    bool public finalized = false;
    bool public allowChange = true;
    address private vaultAddress;

    bool private initialed = false;

    event Payment(address indexed _sender, uint256 _ethAmount, uint256 _tokenAmount);
    event Info256(string name, uint256 msg);
    event LastFund(uint256 funding, uint256 backValue);

    constructor(address tokenAddr) public {
        tokenContract = Token(tokenAddr);
    }

    function setLockStep(uint8[] steps, uint[] times) onlyController public {
        require(steps.length == times.length, "params length different");
        for(uint i; i<steps.length; i++){
            tokenContract.addLockStep(steps[i], times[i]);
        }
    }

     
    function onTransfer(address _from, address _to, uint _amount) public view returns(bool){
        if ( _from == vaultAddress) {
            return true;
        }
        _to;
        _amount;
        return false;
    }

     
    function onApprove(address _owner, address _spender, uint _amount) public view returns(bool){
        if ( _owner == vaultAddress ) {
            return true;
        }
        _spender;
        _amount;
        return false;
    }

     
     
     
     

    function fixFunding(address[] _owner, uint256[] _value, uint8[] _steps, uint8[] _percents) onlyController public {
        require(_owner.length == _value.length, "length of address is different with value");
        require(_steps.length == _percents.length, "length of steps is different with percents");
        address ownerNow;
        uint256 valueNow;
        for(uint i=0; i<_owner.length; i++){
            ownerNow = _owner[i];
            valueNow = _value[i];
            require(tokenContract.generateTokens(ownerNow, valueNow), "generateTokens executed error");
             
             
            uint256[] memory valueArr = new uint256[](_steps.length);
             
            for(uint j=0; j<_steps.length; j++){
                valueArr[j] = valueNow*_percents[j]/100;
            }
            tokenContract.freeze(ownerNow, valueArr, _steps);
        }
    }

    function changeTokenController(address _newController) onlyController public {
        tokenContract.changeController(_newController);
    }

     
    function changeToken(address _newToken) onlyController public {
        tokenContract = Token(_newToken);
    }

    function changeVault(address _newVaultAddress) onlyController public {
        vaultAddress = _newVaultAddress;
    }

     
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

    function claimTokens(address[] tokens) onlyController public {
        address _token;
        uint256 balance;
        for(uint256 i; i<tokens.length; i++){
            _token = tokens[i];
            if (_token == 0x0) {
                balance = address(this).balance;
                if(balance > 0){
                    msg.sender.transfer(balance);
                }
            }else{
                ERC20Token token = ERC20Token(_token);
                balance = token.balanceOf(address(this));
                token.transfer(msg.sender, balance);
                emit ClaimedTokens(_token, msg.sender, balance);
            }
        }
    }

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);

}