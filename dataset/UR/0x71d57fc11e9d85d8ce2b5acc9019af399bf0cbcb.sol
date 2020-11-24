 

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

contract token {

  function balanceOf(address _owner) public constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);

}

contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  constructor() public{
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract LockToken is Ownable {
	using SafeMath for uint256;

  token token_reward;
  address public beneficiary;
  bool public isLocked = false;
  bool public isReleased = false;
  uint256 public start_time;
  uint256 public end_time;
  
  event TokenReleased(address beneficiary, uint256 token_amount);

  constructor(address tokenContractAddress, address _beneficiary) public{
    token_reward = token(tokenContractAddress);
    beneficiary = _beneficiary;
  }

  function tokenBalance() constant public returns (uint256){
    return token_reward.balanceOf(this);
  }

  function lock(uint256 lockTime) public onlyOwner returns (bool){
  	require(!isLocked);
  	require(tokenBalance() > 0);
  	start_time = now;
  	end_time = lockTime;
  	isLocked = true;
  }

  function lockOver() constant public returns (bool){
  	uint256 current_time = now;
	return current_time > end_time;
  }

	function release() onlyOwner public{
    require(isLocked);
    require(!isReleased);
    require(lockOver());
    uint256 token_amount = tokenBalance();
    token_reward.transfer( beneficiary, token_amount);
    emit TokenReleased(beneficiary, token_amount);
    isReleased = true;
  }
}