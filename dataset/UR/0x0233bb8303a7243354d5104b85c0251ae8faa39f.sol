 

pragma solidity ^0.4.11;

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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

contract KolkhaCoin {

  modifier msgDataSize(uint nVar) {assert(msg.data.length == nVar*32 + 4); _ ;}

  string public constant name = "Kolkha";
  string public constant symbol = "KHC";
  uint public constant decimals = 6;
  uint public totalSupply;

  using SafeMath for uint;

  event Transfer(address indexed _from, address indexed _to, uint _value);
  event Approved(address indexed _owner, address indexed _spender, uint _value);

  mapping(address => uint) public balanceOf;
  mapping(address => mapping(address => uint)) public allowance;

  function KolkhaCoin(uint initialSupply){
    balanceOf[msg.sender] = initialSupply;
    totalSupply = initialSupply;
  }

  function transfer(address _to, uint _value) public msgDataSize(2) returns(bool success)
  {
    success = false;
    require(balanceOf[msg.sender] >= _value);  
    require(balanceOf[_to].add(_value) > balanceOf[_to]);  
    require(_value > 0);  

     
    balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

    Transfer(msg.sender, _to, _value);  
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) public msgDataSize(3) returns (bool success)  {
    require(allowance[_from][_to] >= _value);  
    require(balanceOf[_from] >= _value);  
    require(balanceOf[_to].add(_value) > balanceOf[_to]);  
    require(_value > 0);  

     
    balanceOf[_from] = balanceOf[_from].sub(_value);
    balanceOf[_to] = balanceOf[_to].add(_value);

     
    allowance[_from][_to] = allowance[_from][_to].sub(_value);

     
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value) public msgDataSize(2) returns(bool success) {
    success = false;
    allowance[msg.sender][_spender] = _value;
    Approved(msg.sender, _spender, _value);
    return true;
  }

   
   
}