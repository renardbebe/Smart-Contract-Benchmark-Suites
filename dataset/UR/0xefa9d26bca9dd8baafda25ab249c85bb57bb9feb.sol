 

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

    bool public transfersEnabled = true;

     
    event Burn(address indexed from, uint256 value);
    
     
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