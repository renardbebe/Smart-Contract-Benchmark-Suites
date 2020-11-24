 

pragma solidity ^0.4.18;

 

 
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

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

 
contract Timelock is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  uint256 public startTime;

   
  uint256 public cliffDuration;

   
  uint256 public cliffReleasePercentage;

   
  uint256 public slopeDuration;

   
  uint256 public slopeReleasePercentage;

   
  bool public allocationFinished;

   
  uint256 public cliffTime;

   
  uint256 public timelockEndTime;

   
  mapping (address => uint256) public allocatedTokens;

   
  mapping (address => uint256) public withdrawnTokens;

   
  mapping (address => bool) public withdrawalPaused;

   
  function Timelock(ERC20Basic _token, uint256 _startTime, uint256 _cliffDuration, uint256 _cliffReleasePercent, uint256 _slopeDuration, uint256 _slopeReleasePercentage) public {

     
    require(_cliffReleasePercent.add(_slopeReleasePercentage) <= 100);
    require(_startTime > now);
    require(_token != address(0));

     
    allocationFinished = false;

     
    token = _token;
    startTime = _startTime;
    cliffDuration = _cliffDuration;
    cliffReleasePercentage = _cliffReleasePercent;
    slopeDuration = _slopeDuration;
    slopeReleasePercentage = _slopeReleasePercentage;

     
    cliffTime = startTime.add(cliffDuration);
    timelockEndTime = cliffTime.add(slopeDuration);
  }

   
  function allocateTokens(address _address, uint256 _amount) onlyOwner external returns (bool) {
    require(!allocationFinished);

    allocatedTokens[_address] = _amount;
    return true;
  }

   
  function finishAllocation() onlyOwner external returns (bool) {
    allocationFinished = true;

    return true;
  }

   
  function pauseWithdrawal(address _address) onlyOwner external returns (bool) {
    withdrawalPaused[_address] = true;
    return true;
  }

   
  function unpauseWithdrawal(address _address) onlyOwner external returns (bool) {
    withdrawalPaused[_address] = false;
    return true;
  }

   
  function availableForWithdrawal(address _address) public view returns (uint256) {
    if (now < cliffTime) {
      return 0;
    } else if (now < timelockEndTime) {
      uint256 cliffTokens = (cliffReleasePercentage.mul(allocatedTokens[_address])).div(100);
      uint256 slopeTokens = (allocatedTokens[_address].mul(slopeReleasePercentage)).div(100);
      uint256 timeAtSlope = now.sub(cliffTime);
      uint256 slopeTokensByNow = (slopeTokens.mul(timeAtSlope)).div(slopeDuration);

      return (cliffTokens.add(slopeTokensByNow)).sub(withdrawnTokens[_address]);
    } else {
      return allocatedTokens[_address].sub(withdrawnTokens[_address]);
    }
  }

   
  function withdraw() external returns (bool) {
    require(!withdrawalPaused[msg.sender]);

    uint256 availableTokens = availableForWithdrawal(msg.sender);
    require (availableTokens > 0);
    withdrawnTokens[msg.sender] = withdrawnTokens[msg.sender].add(availableTokens);
    token.safeTransfer(msg.sender, availableTokens);
    return true;
  }

}