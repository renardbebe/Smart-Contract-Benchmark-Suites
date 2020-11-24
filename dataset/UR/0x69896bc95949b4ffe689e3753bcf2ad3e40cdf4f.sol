 

pragma solidity ^0.4.4;


 
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract SafeWalletCoin is ERC20Basic {
  
  using SafeMath for uint256;
  
  string public name = "SafeWallet Coin";
  string public symbol = "SWC";
  uint8 public decimals = 0;
  uint256 public airDropNum = 1000;
  uint256 public totalSupply = 100000000;
  address public owner;

  mapping(address => uint256) balances;

  uint256 totalSupply_;
 
   
 
  function SafeWalletCoin() public {

    totalSupply_ = totalSupply;
    owner = msg.sender;
    balances[msg.sender] = totalSupply;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(msg.sender == owner);
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
	
    balances[msg.sender] = SafeMath.sub(balances[msg.sender],(_value));
    balances[_to] = SafeMath.add(balances[_to],(_value));

    return true;
  }
  
  function multyTransfer(address[] arrAddr, uint256[] value) public{
    require(msg.sender == owner);
    require(arrAddr.length == value.length);
    for(uint i = 0; i < arrAddr.length; i++) {
      transfer(arrAddr[i],value[i]);
    }
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }
  
   
  function recycle(address _user,uint256 _value) returns (bool success) {
	require(msg.sender == owner);
    require(balances[_user] >= _value);
	require(_value > 0);
	balances[msg.sender] = SafeMath.add(balances[msg.sender],(_value));
	balances[_user] = SafeMath.sub(balances[_user],(_value));           
     
    return true;
    }

}