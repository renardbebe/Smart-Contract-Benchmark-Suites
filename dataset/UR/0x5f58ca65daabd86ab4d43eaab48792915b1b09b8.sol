 

pragma solidity ^0.4.18;

 
contract Utils {
     
    constructor() public{
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IERC20Token {
     
    function name() public pure returns (string) {}
    function symbol() public pure returns (string) {}
    function decimals() public pure returns (uint8) {}
    function totalSupply() public pure returns (uint256) {}
    function balanceOf(address _owner) public pure returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public pure returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract IOwned {
     
    function owner() public pure returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    constructor() public{
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract TokenHolder is ITokenHolder, Owned, Utils {
     
    constructor() public{
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}



 
contract Bitc3Token is IERC20Token, Utils, TokenHolder {

    string public standard = 'Token 0.2';
    string public name = 'Bitc3 Coin';
    string public symbol = 'BITC';
    uint8 public decimals = 18;
    uint256 public totalSupply = 1000000000000000000000000000;
    mapping (address => uint256) public balanceOf;
    mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
     
    event Burn(address indexed from, uint256 value);
	
     
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);


     
    constructor() public{
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }
	
     
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
		notThis(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
		notThis(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
         
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


     
    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value && _value > 0);             
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = safeSub(totalSupply,_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }

    function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value && _value > 0) ;             
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = safeAdd(freezeOf[msg.sender], _value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }
	
    function unfreeze(uint256 _value) public returns (bool success) {
        require (freezeOf[msg.sender] >= _value && _value > 0) ;             
        freezeOf[msg.sender] = safeSub(freezeOf[msg.sender], _value);                       
	balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }

     
    function withdrawEther(uint256 amount) public ownerOnly{
        owner.transfer(amount);
    }

}