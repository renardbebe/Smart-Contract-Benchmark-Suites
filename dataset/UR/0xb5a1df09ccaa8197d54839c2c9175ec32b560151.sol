 

pragma solidity ^0.4.18;

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

 
contract TokenController {
     
     
     
    function proxyPayment(address _owner) payable public returns(bool);

     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);

     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
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

    string public techProvider = "WeYii Tech";
    string public officialSite = "http://www.beautybloc.io";

    address public owner;

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

    modifier ownerOrController() {
        require(msg.sender == owner || msg.sender == controller);
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
         
         
        require(balanceOf[msg.sender] >= _value);            
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
        require(balanceOf[_from] >= _value);                  
        require(balanceOf[_to] + _value > balanceOf[_to]);   
        require(_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = balanceOf[_from] - _value;                            
        balanceOf[_to] = balanceOf[_to] + _value;                              
        allowance[_from][msg.sender] = allowance[_from][msg.sender] + _value;
        Transfer(_from, _to, _value);
        return true;
    }
    
    function transferMulti(address[] _to, uint256[] _value) public returns (uint256 amount){
        require(_to.length == _value.length);
        uint8 len = uint8(_to.length);
        for(uint8 j; j<len; j++){
            amount += _value[j];
        }
        require(balanceOf[msg.sender] >= amount);
        for(uint8 i; i<len; i++){
            address _toI = _to[i];
            uint256 _valueI = _value[i];
            balanceOf[_toI] += _valueI;
            balanceOf[msg.sender] -= _valueI;
            Transfer(msg.sender, _toI, _valueI);
        }
    }
    
     
    function freeze(address _user, uint256 _value, uint8 _step) moreThanZero(_value) onlyController public returns (bool success) {
         
        require(balanceOf[_user] >= _value);
        balanceOf[_user] = balanceOf[_user] - _value;
        freezeOf[_step][lastFreezeSeq[_step]] = FreezeInfo({user:_user, amount:_value});
        lastFreezeSeq[_step]++;
        Freeze(_user, _value);
        return true;
    }

    event infoBool(string name, bool value);
    event infoAddr(string name, address addr);
    event info(string name, uint8 value);
    event info256(string name, uint256 value);
    
     
    function unFreeze(uint8 _step) onlyOwner public returns (bool unlockOver) {
         
        uint8 _end = lastFreezeSeq[_step];
        require(_end > 0);
         
        unlockOver = (_end <= 99);
        uint8 _start = (_end > 99) ? _end-100 : 0;
         
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

     
     
     
     
    function destroyTokens(address _user, uint _amount) onlyOwner public returns (bool) {
        balanceOf[owner] += _amount;
        balanceOf[_user] -= _amount;
        Transfer(_user, 0, _amount);
        Burn(_user, _amount);
        return true;
    }

     
     
     

     
     
    function enableTransfers(bool _transfersEnabled) onlyOwner public {
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

    function changeOwner(address newOwner) onlyOwner public returns (bool) {
        balanceOf[newOwner] = balanceOf[owner];
        balanceOf[owner] = 0;
        owner = newOwner;
        return true;
    }
}