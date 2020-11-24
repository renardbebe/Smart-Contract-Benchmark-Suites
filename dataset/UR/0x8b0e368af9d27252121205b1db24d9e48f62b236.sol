 

pragma solidity ^0.4.13;

contract ERC20Interface {
  function totalSupply() constant public returns (uint256 supply);
  function balanceOf(address _owner) constant public returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract KiCoin is ERC20Interface {
  string public constant symbol = "KIC";
  string public constant name = "KiCoin";
  uint8 public constant decimals = 2;
  uint256 _totalSupply = 245000000;
  address public owner;
  mapping(address => uint256) balances;
  mapping(address => mapping (address => uint256)) allowed;
  modifier onlyOwner() {
    if (msg.sender != owner) {revert();}
    _;
  }
  
  function KiCoin() public {
    owner = msg.sender;
    balances[owner] = _totalSupply;
  }
  
  function transferOwnership(address newOwner) public onlyOwner {owner = newOwner;}
  
  function totalSupply() constant public returns (uint256 supply) {
    supply = _totalSupply;
  }
   
  function balanceOf(address _owner) constant public returns (uint256 balance) {
    return balances[_owner];
  }
   
  function transfer(address _to, uint256 _amount) public returns (bool success) {
    if (balances[msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
      balances[msg.sender] -= _amount;
      balances[_to] += _amount;
      Transfer(msg.sender, _to, _amount);
      return true;
    } else {return false;}
  }
   
  function transferFrom(address _from,address _to,uint256 _amount) public returns (bool success) {
    if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to] + _amount > balances[_to]) {
      balances[_from] -= _amount;
       allowed[_from][msg.sender] -= _amount;
       balances[_to] += _amount;
       Transfer(_from, _to, _amount);
       return true;
    } else {return false;}
  }
  
  function approve(address _spender, uint256 _amount) public returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
  }
  
  function allowance(address _owner, address _spender) public returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  function () external {
    revert();
  }
   
}