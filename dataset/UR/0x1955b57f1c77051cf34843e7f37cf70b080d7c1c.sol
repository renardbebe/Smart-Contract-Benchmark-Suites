 

pragma solidity ^0.4.18;

 

 
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

 

 
contract BRDLockup is Ownable {
  using SafeMath for uint256;

   
  struct Allocation {
    address beneficiary;       
    uint256 allocation;        
    uint256 remainingBalance;  
    uint256 currentInterval;   
    uint256 currentReward;     
  }

   
  Allocation[] public allocations;

   
  uint256 public unlockDate;

   
  uint256 public currentInterval;

   
  uint256 public intervalDuration;

   
  uint256 public numIntervals;

  event Lock(address indexed _to, uint256 _amount);

  event Unlock(address indexed _to, uint256 _amount);

   
   
  function BRDLockup(uint256 _crowdsaleEndDate, uint256 _numIntervals, uint256 _intervalDuration)  public {
    unlockDate = _crowdsaleEndDate;
    numIntervals = _numIntervals;
    intervalDuration = _intervalDuration;
    currentInterval = 0;
  }

   
  function processInterval() onlyOwner public returns (bool _shouldProcessRewards) {
     
    bool _correctInterval = now >= unlockDate && now.sub(unlockDate) > currentInterval.mul(intervalDuration);
    bool _validInterval = currentInterval < numIntervals;
    if (!_correctInterval || !_validInterval)
      return false;

     
    currentInterval = currentInterval.add(1);

     
    uint _allocationsIndex = allocations.length;

     
    for (uint _i = 0; _i < _allocationsIndex; _i++) {
       
      uint256 _amountToReward;

       
      if (currentInterval == numIntervals) {
        _amountToReward = allocations[_i].remainingBalance;
      } else {
         
        _amountToReward = allocations[_i].allocation.div(numIntervals);
      }
       
      allocations[_i].currentReward = _amountToReward;
    }

    return true;
  }

   
  function numAllocations() constant public returns (uint) {
    return allocations.length;
  }

   
  function allocationAmount(uint _index) constant public returns (uint256) {
    return allocations[_index].allocation;
  }

   
  function unlock(uint _index) onlyOwner public returns (bool _shouldReward, address _beneficiary, uint256 _rewardAmount) {
     
    if (allocations[_index].currentInterval < currentInterval) {
       
      allocations[_index].currentInterval = currentInterval;
       
      allocations[_index].remainingBalance = allocations[_index].remainingBalance.sub(allocations[_index].currentReward);
       
      Unlock(allocations[_index].beneficiary, allocations[_index].currentReward);
       
      _shouldReward = true;
    } else {
       
      _shouldReward = false;
    }

     
    _rewardAmount = allocations[_index].currentReward;
    _beneficiary = allocations[_index].beneficiary;
  }

   
  function pushAllocation(address _beneficiary, uint256 _numTokens) onlyOwner public {
    require(now < unlockDate);
    allocations.push(
      Allocation(
        _beneficiary,
        _numTokens,
        _numTokens,
        0,
        0
      )
    );
    Lock(_beneficiary, _numTokens);
  }
}