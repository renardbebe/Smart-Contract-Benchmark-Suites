 

pragma solidity ^0.5.8;

contract SKYNPToken {

  address admin;
  address admin2=0xa4e81224fC73a9E095809e34f5324aa18fA2a412;

  string public name="SkyNavPro";
  string public symbol="SKYNP";
  uint8 public decimals=6;

  uint256 totalSupplyInternal;
  mapping (address => uint256) balances;
  mapping (address => mapping(address => uint256)) allowances;

  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 _value
  );

  event Approval(
    address indexed _owner,
    address indexed _spender,
    uint256 _value
  );


  constructor (uint256 _initialSupply) public {
    admin=msg.sender;
    totalSupplyInternal = _initialSupply;
    balances[msg.sender]=_initialSupply;
  }

  function totalSupply() public view returns (uint256) {
    return totalSupplyInternal;
  }

  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowances[_owner][_spender];
  }

  function transfer(address _to, uint256 _value) public returns(bool success){
    require(balances[msg.sender]>=_value, "The balance of the sender is not high enough.");

    balances[msg.sender] = SafeMath.sub(balances[msg.sender], _value);
    balances[_to]=SafeMath.add(balances[_to], _value);

    emit Transfer(msg.sender, _to, _value);

    return true;
  }

  function approve(address _spender, uint256 _value) public returns(bool success) {

    allowances[msg.sender][_spender]=_value;

    emit Approval(msg.sender, _spender, _value);

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns(bool success){

    require(balances[_from]>=_value, "The balance of the sender is not high enough.");
    require(allowances[_from][msg.sender]>=_value, "The allowance is not big enough.");

    allowances[_from][msg.sender]=SafeMath.sub(allowances[_from][msg.sender],_value);
    balances[_from]=SafeMath.sub(balances[_from], _value);
    balances[_to]=SafeMath.add(balances[_to],_value);

    emit Transfer(_from, _to, _value);

    return true;
  }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}