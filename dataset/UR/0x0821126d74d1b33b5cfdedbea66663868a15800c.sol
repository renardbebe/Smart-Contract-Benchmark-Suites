 

pragma solidity 0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

interface FreeDnaCardRepositoryInterface {
    function airdrop(address to, uint256 animalId) external;

    function giveaway(
        address to,
        uint256 animalId,
        uint8 effectiveness
    )
    external;
}

 

interface CryptoServal {
    function getAnimalsCount() external view returns(uint256 animalsCount);
}


contract Airdrop {
    using SafeMath for uint256;

    mapping (address => mapping (uint256 => bool)) private addressHasWithdraw;
    mapping (uint256 => uint256) private periodDonationCount;

    CryptoServal private cryptoServal;
    FreeDnaCardRepositoryInterface private freeDnaCardRepository;

    uint256 private startTimestamp;
    uint256 private endTimestamp;
    uint256 private periodDuration;  
    uint16 private cardsByPeriod;  

    constructor(
        address _cryptoServalAddress,
        address _freeDnaCardRepositoryAddress,
        uint _startTimestamp,
        uint _endTimestamp,
        uint256 _periodDuration,
        uint16 _cardsByPeriod
    )
    public {
        freeDnaCardRepository =
            FreeDnaCardRepositoryInterface(_freeDnaCardRepositoryAddress);
        cryptoServal = CryptoServal(_cryptoServalAddress);
        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        periodDuration = _periodDuration;
        cardsByPeriod = _cardsByPeriod;
    }

    function withdraw() external {
        require(now >= startTimestamp, "not started yet");
        require(now <= endTimestamp, "ended");

        mapping (uint256 => bool) senderHasWithdraw = addressHasWithdraw[msg.sender];
        uint256 currentPeriodKey = getCurrentPeriodKey();

         
        require(senderHasWithdraw[currentPeriodKey] == false, "once / period");

         
        require(
            periodDonationCount[currentPeriodKey] < cardsByPeriod,
            "period maximum donations reached"
        );

         
        freeDnaCardRepository.airdrop(msg.sender, getRandomAnimalId());

         
        periodDonationCount[currentPeriodKey]++;
        senderHasWithdraw[currentPeriodKey] = true;
    }

    function hasAvailableCard() external view returns(bool) {
        uint256 currentPeriodKey = getCurrentPeriodKey();
        mapping (uint256 => bool) senderHasWithdraw = addressHasWithdraw[msg.sender];

        return (senderHasWithdraw[currentPeriodKey] == false &&
                periodDonationCount[currentPeriodKey] < cardsByPeriod);
    }

    function getAvailableCardCount() external view returns(uint256) {
        return cardsByPeriod - periodDonationCount[getCurrentPeriodKey()];
    }

    function getNextPeriodTimestamp() external view returns(uint256) {
        uint256 nextPeriodKey = getCurrentPeriodKey() + 1;
        return nextPeriodKey.mul(periodDuration);
    }

    function getRandomNumber(uint256 max) public view returns(uint256) {
        require(max != 0);
        return now % max;
    }

    function getAnimalCount() public view returns(uint256) {
        return cryptoServal.getAnimalsCount();
    }

    function getRandomAnimalId() public view returns(uint256) {
        return getRandomNumber(getAnimalCount());
    }

    function getPeriodKey(uint atTime) private view returns(uint256) {
        return atTime.div(periodDuration);
    }

    function getCurrentPeriodKey() private view returns(uint256) {
        return getPeriodKey(now);
    }
}