 

pragma solidity ^0.4.13;
 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool);
  function transferFrom(address from, address to, uint value) returns (bool);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract StandardToken is ERC20 {

  using SafeMath for uint;

   
  mapping (address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool) {
    return true;
  }

   
  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  }

   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[msg.sender] >= _value);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) returns (bool) {
    require(balances[_from] >= _value && allowed[_from][_to] >= _value);
    allowed[_from][_to] = allowed[_from][_to].sub(_value);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
  
   
  function approve(address _spender, uint _value) returns (bool success) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}



 
contract Ownable {
  address public owner = msg.sender;

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));
    owner = newOwner;
  }

}


contract EmeraldToken is StandardToken, Ownable {

  string public name;
  string public symbol;
  uint public decimals;

  mapping (address => bool) public producers;

  bool public released = false;

   
  modifier onlyProducer() {
    require(producers[msg.sender] == true);
    _;
  }

   
  modifier canTransfer(address _sender) {
    if (_sender != owner)
      require(released);
    _;
  }

  modifier inProduction() {
    require(!released);
    _;
  }

  function EmeraldToken(string _name, string _symbol, uint _decimals) {
    require(_decimals > 0);
    name = _name;
    symbol = _symbol;
    decimals = _decimals;

     
    producers[msg.sender] = true;
  }

   
  function setProducer(address _addr, bool _status) onlyOwner {
    producers[_addr] = _status;
  }

   
  function produceEmeralds(address _receiver, uint _amount) onlyProducer inProduction {
    balances[_receiver] = balances[_receiver].add(_amount);
    totalSupply = totalSupply.add(_amount);
    Transfer(0, _receiver, _amount);
  }

   
  function releaseTokenTransfer() onlyOwner {
    released = true;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool) {
     
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool) {
     
    return super.transferFrom(_from, _to, _value);
  }

}