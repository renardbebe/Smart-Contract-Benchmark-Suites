 

pragma solidity ^0.4.24;
 


 
contract Ownable {
  address private _owner;

  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


 
contract MidnightRun is Ownable {
  using SafeMath
  for uint;

  modifier isHuman() {
    uint32 size;
    address investor = msg.sender;
    assembly {
      size: = extcodesize(investor)
    }
    if (size > 0) {
      revert("Inhuman");
    }
    _;
  }

  event DailyDividendPayout(address indexed _address, uint value, uint periodCount, uint percent, uint time);
  event ReferralPayout(address indexed _addressFrom, address indexed _addressTo, uint value, uint percent, uint time);
  event MidnightRunPayout(address indexed _address, uint value, uint totalValue, uint userValue, uint time);

  uint public period = 24 hours;
  uint public startTime = 1537833600;  

  uint public dailyDividendPercent = 300;  
  uint public referredDividendPercent = 330;  

  uint public referrerPercent = 250;  
  uint public minBetLevel = 0.01 ether;

  uint public referrerAndOwnerPercent = 2000;  
  uint public currentStakeID = 1;

  struct DepositInfo {
    uint value;
    uint firstBetTime;
    uint lastBetTime;
    uint lastPaymentTime;
    uint nextPayAfterTime;
    bool isExist;
    uint id;
    uint referrerID;
  }

  mapping(address => DepositInfo) public investorToDepostIndex;
  mapping(uint => address) public idToAddressIndex;

   
  uint public midnightPrizePercent = 1000;  
  uint public midnightPrize = 0;
  uint public nextPrizeTime = startTime + period;

  uint public currentPrizeStakeID = 0;

  struct MidnightRunDeposit {
    uint value;
    address user;
  }
  mapping(uint => MidnightRunDeposit) public stakeIDToDepositIndex;

  
  constructor() public {
  }

   
  function() public payable isHuman {
    if (msg.value == 0) {
      collectPayoutForAddress(msg.sender);
    } else {
      uint refId = 1;
      address referrer = bytesToAddress(msg.data);
      if (investorToDepostIndex[referrer].isExist) {
        refId = investorToDepostIndex[referrer].id;
      }
      deposit(refId);
    }
  }

 
  function bytesToAddress(bytes bys) private pure returns(address addr) {
    assembly {
      addr: = mload(add(bys, 20))
    }
  }

 
  function addToMidnightPrize() public payable onlyOwner {
    midnightPrize += msg.value;
  }

 
  function getNextPayoutTime() public view returns(uint) {
    if (now<startTime) return startTime + period;
    return startTime + ((now.sub(startTime)).div(period)).mul(period) + period;
  }

 
  function deposit(uint _referrerID) public payable isHuman {
    require(_referrerID <= currentStakeID, "Who referred you?");
    require(msg.value >= minBetLevel, "Doesn't meet minimum stake.");

     
    uint nextPayAfterTime = getNextPayoutTime();

    if (investorToDepostIndex[msg.sender].isExist) {
      if (investorToDepostIndex[msg.sender].nextPayAfterTime < now) {
        collectPayoutForAddress(msg.sender);
      }
      investorToDepostIndex[msg.sender].value += msg.value;
      investorToDepostIndex[msg.sender].lastBetTime = now;
    } else {
      DepositInfo memory newDeposit;

      newDeposit = DepositInfo({
        value: msg.value,
        firstBetTime: now,
        lastBetTime: now,
        lastPaymentTime: 0,
        nextPayAfterTime: nextPayAfterTime,
        isExist: true,
        id: currentStakeID,
        referrerID: _referrerID
      });

      investorToDepostIndex[msg.sender] = newDeposit;
      idToAddressIndex[currentStakeID] = msg.sender;

      currentStakeID++;
    }

    if (now > nextPrizeTime) {
      doMidnightRun();
    }

    currentPrizeStakeID++;

    MidnightRunDeposit memory midnitrunDeposit;
    midnitrunDeposit.user = msg.sender;
    midnitrunDeposit.value = msg.value;

    stakeIDToDepositIndex[currentPrizeStakeID] = midnitrunDeposit;

     
    midnightPrize += msg.value.mul(midnightPrizePercent).div(10000);
     
    if (investorToDepostIndex[msg.sender].referrerID != 0) {

      uint refToPay = msg.value.mul(referrerPercent).div(10000);
       
      idToAddressIndex[investorToDepostIndex[msg.sender].referrerID].transfer(refToPay);
       
      owner().transfer(msg.value.mul(referrerAndOwnerPercent - referrerPercent).div(10000));
      emit ReferralPayout(msg.sender, idToAddressIndex[investorToDepostIndex[msg.sender].referrerID], refToPay, referrerPercent, now);
    } else {
       
      owner().transfer(msg.value.mul(referrerAndOwnerPercent).div(10000));
    }
  }



 
  function collectPayout() public isHuman {
    collectPayoutForAddress(msg.sender);
  }

 
  function getRewardForAddress(address _address) public onlyOwner {
    collectPayoutForAddress(_address);
  }

 
  function collectPayoutForAddress(address _address) internal {
    require(investorToDepostIndex[_address].isExist == true, "Who are you?");
    require(investorToDepostIndex[_address].nextPayAfterTime < now, "Not yet.");

    uint periodCount = now.sub(investorToDepostIndex[_address].nextPayAfterTime).div(period).add(1);
    uint percent = dailyDividendPercent;

    if (investorToDepostIndex[_address].referrerID > 0) {
      percent = referredDividendPercent;
    }

    uint toPay = periodCount.mul(investorToDepostIndex[_address].value).div(10000).mul(percent);

    investorToDepostIndex[_address].lastPaymentTime = now;
    investorToDepostIndex[_address].nextPayAfterTime += periodCount.mul(period);

     
    if (toPay.add(midnightPrize) < address(this).balance.sub(msg.value))
    {
      _address.transfer(toPay);
      emit DailyDividendPayout(_address, toPay, periodCount, percent, now);
    }
  }

 
  function doMidnightRun() public isHuman {
    require(now>nextPrizeTime , "Not yet");

     
    nextPrizeTime = getNextPayoutTime();

    if (currentPrizeStakeID > 5) {
      uint toPay = midnightPrize;
      midnightPrize = 0;

      if (toPay > address(this).balance){
        toPay = address(this).balance;
      }

      uint totalValue = stakeIDToDepositIndex[currentPrizeStakeID].value + stakeIDToDepositIndex[currentPrizeStakeID - 1].value + stakeIDToDepositIndex[currentPrizeStakeID - 2].value + stakeIDToDepositIndex[currentPrizeStakeID - 3].value + stakeIDToDepositIndex[currentPrizeStakeID - 4].value;

      stakeIDToDepositIndex[currentPrizeStakeID].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 1].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 1].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 1].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 1].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 1].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 2].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 2].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 2].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 2].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 2].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 3].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 3].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 3].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 3].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 3].value, now);

      stakeIDToDepositIndex[currentPrizeStakeID - 4].user.transfer(toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 4].value).div(totalValue));
      emit MidnightRunPayout(stakeIDToDepositIndex[currentPrizeStakeID - 4].user, toPay.mul(stakeIDToDepositIndex[currentPrizeStakeID - 4].value).div(totalValue), totalValue, stakeIDToDepositIndex[currentPrizeStakeID - 4].value, now);
    }
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