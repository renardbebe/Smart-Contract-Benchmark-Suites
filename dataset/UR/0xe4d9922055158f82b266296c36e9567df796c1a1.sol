 

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

    constructor() public {
       
      controller = msg.sender;
       
    }

     
     
    function changeController(address _newController) onlyController public {
        controller = _newController;
    }
}

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable public returns(bool);

     
     
     
     
     
     
     

     
     
     
     
     
     
     
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


     

     
     
     
     
     
     
     
    function approveAndCall(
        address _spender,
        uint256 _amount,
        bytes _extraData
    ) public returns (bool success);


     

     
     
     
     
    function generateTokens(address _owner, uint _amount) public returns (bool);


     
     
     
     
    function destroyTokens(address _owner, uint _amount) public returns (bool);

     
     
    function enableTransfers(bool _transfersEnabled) public;


     

     
     
     
     
    function claimTokens(address[] _tokens) public;


     

    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
}


contract Token915 is TokenI {
    using SafeMath for uint256;

    address public owner;

    string public techProvider = "WeYii Tech(https://weyii.co)";
    string public officialSite = "https://915club.com";

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

     
    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        address initialOwner
    ) public {
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

     
    function addLockStep(uint8 _step, uint _endTime) onlyController external returns(bool) {
        stepLockend[_step] = _endTime;
    }

     
    function transfer(address _to, uint256 _value) realUser(_to) moreThanZero(_value) transable public returns (bool) {
         
         
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                      
        balanceOf[_to] = balanceOf[_to].add(_value);                             
        emit Transfer(msg.sender, _to, _value);                    
        return true;
    }

     
    function approve(address _spender, uint256 _value) transable public
        returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function unApprove(address _spender, uint256 _value) moreThanZero(_value) transable public
        returns (bool success) {
        require(_value == 0 || (allowance[msg.sender][_spender] == 0));
        allowance[msg.sender][_spender] = allowance[msg.sender][_spender].sub(_value);
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) transable public returns (bool success) {
        require(approve(_spender, _amount));

        ApproveAndCallReceiver(_spender).receiveApproval(
            msg.sender,
            _amount,
            this,
            _extraData
        );

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
        require(_to.length == _value.length && _to.length <= 1024);
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
    
    function transferMultiSameVaule(address[] _to, uint256 _value) transable public returns (bool){
        require(_to.length <= 1024);
         
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

     
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyController public returns (bool success) {
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user].sub(_value);
        freezeOfUser[_user] = freezeOfUser[_user].add(_value);
        freezeOf[_step].push(uint256(_user)<<96|_value);
        emit Freeze(_user, _value);
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
         
        require(isContract(controller));
        bool proxyPayment = TokenController(controller).proxyPayment.value(msg.value)(msg.sender);
        require(proxyPayment);
    }

 
 
 

     
     
     
     
    function generateTokens(address _user, uint _amount) onlyController public returns (bool) {
         
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

 
 
 

     
     
     
    function claimTokens(address[] tokens) onlyOwner public {
        address _token;
        uint256 balance;
        for(uint256 i; i<tokens.length; i++){
            _token = tokens[i];
            if (_token == 0x0) {
                balance = address(this).balance;
                if(balance > 0){
                    owner.transfer(balance);
                }
            }else{
                ERC20Token token = ERC20Token(_token);
                balance = token.balanceOf(address(this));
                token.transfer(owner, balance);
                emit ClaimedTokens(_token, owner, balance);
            }
        }
    }
}