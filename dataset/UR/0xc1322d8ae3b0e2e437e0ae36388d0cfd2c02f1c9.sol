 

pragma solidity ^0.4.15;

 
contract Ownable {
  
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);
  
   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    assert(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    assert(_newOwner != address(0));      
    newOwner = _newOwner;
  }

   
  function acceptOwnership() public {
    if (msg.sender == newOwner) {
      OwnershipTransferred(owner, newOwner);
      owner = newOwner;
    }
  }
}


 
contract SafeMath {

  function sub(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x - y;
    assert(z <= x);
	  return z;
  }

  function add(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x + y;
	  assert(z >= x);
	  return z;
  }
	
  function div(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x / y;
	  return z;
  }
	
  function mul(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x * y;
    assert(x == 0 || z / x == y);
    return z;
  }

  function min(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x <= y ? x : y;
	  return z;
  }

  function max(uint256 x, uint256 y) internal constant returns (uint256) {
    uint256 z = x >= y ? x : y;
	  return z;
  }
}


 
contract ERC20 {
	function totalSupply() public constant returns (uint);
	function balanceOf(address owner) public constant returns (uint);
	function allowance(address owner, address spender) public constant returns (uint);
	function transfer(address to, uint value) public returns (bool success);
	function transferFrom(address from, address to, uint value) public returns (bool success);
	function approve(address spender, uint value) public returns (bool success);
	function mint(address to, uint value) public returns (bool success);
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is ERC20, SafeMath, Ownable{
	
  uint256 _totalSupply;
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) approvals;
  address public crowdsaleAgent;
  bool public released = false;  
  
   
  modifier onlyPayloadSize(uint numwords) {
    assert(msg.data.length == numwords * 32 + 4);
    _;
  }
  
   
  modifier onlyCrowdsaleAgent() {
    assert(msg.sender == crowdsaleAgent);
    _;
  }

   
  modifier canMint() {
    assert(!released);
    _;
  }
  
   
  modifier canTransfer() {
    assert(released);
    _;
  } 
  
     
  function totalSupply() public constant returns (uint256) {
    return _totalSupply;
  }
  
   
  function balanceOf(address _owner) public constant returns (uint256) {
    return balances[_owner];
  }
  
      
  function allowance(address _owner, address _spender) public constant returns (uint256) {
    return approvals[_owner][_spender];
  }

      
  function transfer(address _to, uint _value) public canTransfer onlyPayloadSize(2) returns (bool success) {
    assert(balances[msg.sender] >= _value);
    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);
    
    Transfer(msg.sender, _to, _value);
    return true;
  }
  
       
  function transferFrom(address _from, address _to, uint _value) public canTransfer onlyPayloadSize(3) returns (bool success) {
    assert(balances[_from] >= _value);
    assert(approvals[_from][msg.sender] >= _value);
    approvals[_from][msg.sender] = sub(approvals[_from][msg.sender], _value);
    balances[_from] = sub(balances[_from], _value);
    balances[_to] = add(balances[_to], _value);
    
    Transfer(_from, _to, _value);
    return true;
  }
  
   
  function approve(address _spender, uint _value) public onlyPayloadSize(2) returns (bool success) {
     
     
     
     
    assert((_value == 0) || (approvals[msg.sender][_spender] == 0));
    approvals[msg.sender][_spender] = _value;
    
    Approval(msg.sender, _spender, _value);
    return true;
  }
  
    
  function mint(address _to, uint _value) public onlyCrowdsaleAgent canMint onlyPayloadSize(2) returns (bool success) {
    _totalSupply = add(_totalSupply, _value);
    balances[_to] = add(balances[_to], _value);
    
    Transfer(0, _to, _value);
    return true;
  }
  
   
  function setCrowdsaleAgent(address _crowdsaleAgent) public onlyOwner {
    assert(!released);
    crowdsaleAgent = _crowdsaleAgent;
  }
  
   
  function releaseTokenTransfer() public onlyCrowdsaleAgent {
    released = true;
  }
}


 
contract DAOPlayMarketToken is StandardToken {
  
  string public name;
  string public symbol;
  uint public decimals;
  
   
  event UpdatedTokenInformation(string newName, string newSymbol);

   
   
  function DAOPlayMarketToken(string _name, string _symbol, uint _initialSupply, uint _decimals, address _addr) public {
    require(_addr != 0x0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
	
    _totalSupply = _initialSupply*10**_decimals;

     
    balances[_addr] = _totalSupply;
  }   
  
    
  function setTokenInformation(string _name, string _symbol) public onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}