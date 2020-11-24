 

pragma solidity ^0.4.24;

 
contract SafeMath {
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256){
    if (_a == 0) {
      return 0;
    }
    uint256 c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  function div(uint256 _a, uint256 _b) internal pure returns (uint256){
    uint256 c = _a / _b;
     
     
    return c;
  }

  function sub(uint256 _a, uint256 _b) internal pure returns (uint256){
    assert(_b <= _a);
    return _a - _b;
  }

  function add(uint256 _a,uint256 _b) internal pure returns (uint256){
    uint256 c = _a + _b;
    assert(c >= _a);
    return c;
  }

}

contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  constructor () public{
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  function transferOwnership(
    address _newOwner
  )
    onlyOwner
    public
  {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract ERC20StdToken is Ownable, SafeMath {
  uint256 public totalSupply;
	string  public name;
	uint8   public decimals;
	string  public symbol;
	bool    public isMint;      
    bool    public isBurn;     
    bool    public isFreeze;  

  mapping (address => uint256) public balanceOf;
  mapping (address => uint256) public freezeOf;
  mapping (address => mapping (address => uint256)) public allowance;

  constructor(
    address _owner,
    string _name,
    string _symbol,
    uint8 _decimals,
    uint256 _initialSupply,
    bool _isMint,
    bool _isBurn,
    bool _isFreeze) public {
    require(_owner != address(0));
    owner             = _owner;
  	decimals          = _decimals;
  	symbol            = _symbol;
  	name              = _name;
  	isMint            = _isMint;
    isBurn            = _isBurn;
    isFreeze          = _isFreeze;
  	totalSupply       = _initialSupply * 10 ** uint256(decimals);
    balanceOf[_owner] = totalSupply;
 }

  
 event Transfer(address indexed _from, address indexed _to, uint256 _value);
 event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  
 event Burn(address indexed _from, uint256 value);

   
 event Freeze(address indexed _from, uint256 value);

   
 event Unfreeze(address indexed _from, uint256 value);

 function approve(address _spender, uint256 _value) public returns (bool success) {
   allowance[msg.sender][_spender] = _value;
   emit Approval(msg.sender, _spender, _value);
   success = true;
 }

  
  
  
  
 function transfer(address _to, uint256 _value) public returns (bool success) {
   require(_to != 0);
   require(balanceOf[msg.sender] >= _value);
   require(balanceOf[_to] + _value >= balanceOf[_to]);
    
   balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);

    
   balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

   emit Transfer(msg.sender, _to, _value);
   success = true;
 }

  
  
  
  
  
 function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
   require(_to != 0);
   require(balanceOf[_from] >= _value);
   require(allowance[_from][msg.sender] >= _value);
   require(balanceOf[_to] + _value >= balanceOf[_to]);
    
   balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);
    
   balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);

    
   allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);

   emit Transfer(_from, _to, _value);
   success = true;
 }

  function mint(uint256 amount) onlyOwner public {
  	require(isMint);
  	require(amount >= 0);
  	 
    balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], amount);
  	 
    totalSupply = SafeMath.add(totalSupply, amount);
  }

  function burn(uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value);             
    require(_value > 0);
    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                       
    totalSupply = SafeMath.sub(totalSupply, _value);                                 
    emit Burn(msg.sender, _value);
    success = true;
 }

  function freeze(uint256 _value) public returns (bool success) {
    require(balanceOf[msg.sender] >= _value);             
    require(_value > 0);
    balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                       
    freezeOf[msg.sender] = SafeMath.add(freezeOf[msg.sender], _value);                                 
    emit Freeze(msg.sender, _value);
    success = true;
  }

  function unfreeze(uint256 _value) public returns (bool success) {
    require(freezeOf[msg.sender] >= _value);             
    require(_value > 0);
    freezeOf[msg.sender] = SafeMath.sub(freezeOf[msg.sender], _value);                       
    balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], _value);
    emit Unfreeze(msg.sender, _value);
    success = true;
  }
}