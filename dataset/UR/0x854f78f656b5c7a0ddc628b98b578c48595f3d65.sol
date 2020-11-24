 

pragma solidity ^0.4.18;

contract AccessControl {
   
  address public ceoAddress;
  address public cooAddress;

   
  bool public paused = false;

   
  function AccessControl() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(msg.sender == ceoAddress || msg.sender == cooAddress);
    _;
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() public onlyCEO whenNotPaused {
     paused = true;
  }

   
  function unpause() public onlyCEO whenPaused {
    paused = false;
  }
}


contract RacingClubPresale is AccessControl {
  using SafeMath for uint256;

   
  uint256 public constant MAX_CARS = 999;

   
  uint256 public constant MAX_CARS_TO_GIFT = 99;

   
  uint256 public constant MAX_UNICORNS_TO_GIFT = 9;

   
   
  uint256 public constant PRESALE_END_TIMESTAMP = 1542671999;

   
  uint256 private constant PRICE_LIMIT_1 = 0.1 ether;

   
  uint256 private constant APPRECIATION_STEP_1 = 0.0005 ether;
  uint256 private constant APPRECIATION_STEP_2 = 0.0001 ether;

   
  uint256 private constant MAX_ORDER = 5;

   
  uint256 private constant CAR_MODELS = 10;

   
  uint256 public constant UNICORN_ID = 0;

   
  uint256[] private PROBABILITY_MAP = [4, 18, 32, 46, 81, 116, 151, 186, 221, 256];

   
  uint256 public appreciationStep = APPRECIATION_STEP_1;

   
  uint256 public currentPrice = 0.001 ether;

   
  uint256 public carsCount;

   
  uint256 public carsGifted;

   
  uint256 public unicornsGifted;

   
  mapping (address => uint256[]) private ownerToCars;

   
  mapping (address => uint256) private ownerToUpgradePackages;

   
  event CarsPurchased(address indexed _owner, uint256[] _carIds, bool _upgradePackage, uint256 _pricePayed);
  event CarGifted(address indexed _receiver, uint256 _carId, bool _upgradePackage);

  function RacingClubPresale() public {
     
    carsCount = 98;
    carsGifted = 6;
    unicornsGifted = 2;
    currentPrice = 0.05 ether;
  }

   
   
  function purchaseCars(uint256 _carsToBuy, uint256 _pickedId, bool _upgradePackage) public payable whenNotPaused {
    require(now < PRESALE_END_TIMESTAMP);
    require(_carsToBuy > 0 && _carsToBuy <= MAX_ORDER);
    require(carsCount + _carsToBuy <= MAX_CARS);

    uint256 priceToPay = calculatePrice(_carsToBuy, _upgradePackage);
    require(msg.value >= priceToPay);

     
    uint256 excess = msg.value.sub(priceToPay);
    if (excess > 0) {
      msg.sender.transfer(excess);
    }

     
    uint256[] memory randomCars = new uint256[](_carsToBuy);
     
    uint256 startFrom = 0;

     
    if (_carsToBuy == MAX_ORDER) {
      require(_pickedId < CAR_MODELS);
      require(_pickedId != UNICORN_ID);

      randomCars[0] = _pickedId;
      startFrom = 1;
    }
    fillRandomCars(randomCars, startFrom);

     
    for (uint256 i = 0; i < randomCars.length; i++) {
      ownerToCars[msg.sender].push(randomCars[i]);
    }

     
    if (_upgradePackage) {
      ownerToUpgradePackages[msg.sender] += _carsToBuy;
    }

    CarsPurchased(msg.sender, randomCars, _upgradePackage, priceToPay);

    carsCount += _carsToBuy;
    currentPrice += _carsToBuy * appreciationStep;

     
     
    updateAppreciationStep();
  }

   
  function giftCar(address _receiver, uint256 _carId, bool _upgradePackage) public onlyCLevel {
     
     
     

    require(_carId < CAR_MODELS);
    require(_receiver != address(0));

     
    require(carsCount < MAX_CARS);
    require(carsGifted < MAX_CARS_TO_GIFT);
    if (_carId == UNICORN_ID) {
      require(unicornsGifted < MAX_UNICORNS_TO_GIFT);
    }

    ownerToCars[_receiver].push(_carId);
    if (_upgradePackage) {
      ownerToUpgradePackages[_receiver] += 1;
    }

    CarGifted(_receiver, _carId, _upgradePackage);

    carsCount += 1;
    carsGifted += 1;
    if (_carId == UNICORN_ID) {
      unicornsGifted += 1;
    }

    currentPrice += appreciationStep;
    updateAppreciationStep();
  }

  function calculatePrice(uint256 _carsToBuy, bool _upgradePackage) private view returns (uint256) {
     
     
    uint256 lastPrice = currentPrice + (_carsToBuy - 1) * appreciationStep;

     
     
    uint256 priceToPay = _carsToBuy * (currentPrice + lastPrice) / 2;

     
    if (_upgradePackage) {
      if (_carsToBuy < 3) {
        priceToPay = priceToPay * 120 / 100;  
      } else if (_carsToBuy < 5) {
        priceToPay = priceToPay * 115 / 100;  
      } else {
        priceToPay = priceToPay * 110 / 100;  
      }
    }

    return priceToPay;
  }

   
   
  function fillRandomCars(uint256[] _randomCars, uint256 _startFrom) private view {
     
     
     
     
     
     
    bytes32 rand32 = keccak256(currentPrice, now);
    uint256 randIndex = 0;
    uint256 carId;

    for (uint256 i = _startFrom; i < _randomCars.length; i++) {
      do {
         
         
        require(randIndex < 32);
        carId = generateCarId(uint8(rand32[randIndex]));
        randIndex++;
      } while(alreadyContains(_randomCars, carId, i));
      _randomCars[i] = carId;
    }
  }

   
  function generateCarId(uint256 _serialNumber) private view returns (uint256) {
    for (uint256 i = 0; i < PROBABILITY_MAP.length; i++) {
      if (_serialNumber < PROBABILITY_MAP[i]) {
        return i;
      }
    }
     
    assert(false);
  }

   
   
  function alreadyContains(uint256[] _list, uint256 _value, uint256 _to) private pure returns (bool) {
    for (uint256 i = 0; i < _to; i++) {
      if (_list[i] == _value) {
        return true;
      }
    }
    return false;
  }

  function updateAppreciationStep() private {
     
     
    if (currentPrice > PRICE_LIMIT_1) {
       
      if (appreciationStep != APPRECIATION_STEP_2) {
        appreciationStep = APPRECIATION_STEP_2;
      }
    }
  }

  function carCountOf(address _owner) public view returns (uint256 _carCount) {
    return ownerToCars[_owner].length;
  }

  function carOfByIndex(address _owner, uint256 _index) public view returns (uint256 _carId) {
    return ownerToCars[_owner][_index];
  }

  function carsOf(address _owner) public view returns (uint256[] _carIds) {
    return ownerToCars[_owner];
  }

  function upgradePackageCountOf(address _owner) public view returns (uint256 _upgradePackageCount) {
    return ownerToUpgradePackages[_owner];
  }

  function allOf(address _owner) public view returns (uint256[] _carIds, uint256 _upgradePackageCount) {
    return (ownerToCars[_owner], ownerToUpgradePackages[_owner]);
  }

  function getStats() public view returns (uint256 _carsCount, uint256 _carsGifted, uint256 _unicornsGifted, uint256 _currentPrice, uint256 _appreciationStep) {
    return (carsCount, carsGifted, unicornsGifted, currentPrice, appreciationStep);
  }

  function withdrawBalance(address _to, uint256 _amount) public onlyCEO {
    if (_amount == 0) {
      _amount = address(this).balance;
    }

    if (_to == address(0)) {
      ceoAddress.transfer(_amount);
    } else {
      _to.transfer(_amount);
    }
  }


   
   
  uint256 public raffleLimit = 50;

   
  address[] private raffleList;

   
  event Raffle2Registered(address indexed _iuser, address _user);
  event Raffle3Registered(address _user);

  function isInRaffle(address _address) public view returns (bool) {
    for (uint256 i = 0; i < raffleList.length; i++) {
      if (raffleList[i] == _address) {
        return true;
      }
    }
    return false;
  }

  function getRaffleStats() public view returns (address[], uint256) {
    return (raffleList, raffleLimit);
  }

  function drawRaffle(uint256 _carId) public onlyCLevel {
    bytes32 rand32 = keccak256(now, raffleList.length);
    uint256 winner = uint(rand32) % raffleList.length;

    giftCar(raffleList[winner], _carId, true);
  }

  function resetRaffle() public onlyCLevel {
    delete raffleList;
  }

  function setRaffleLimit(uint256 _limit) public onlyCLevel {
    raffleLimit = _limit;
  }

   
  function registerForRaffle() public {
    require(raffleList.length < raffleLimit);
    require(!isInRaffle(msg.sender));
    raffleList.push(msg.sender);
  }

   
  function registerForRaffle2() public {
    Raffle2Registered(msg.sender, msg.sender);
  }

   
  function registerForRaffle3() public payable {
    Raffle3Registered(msg.sender);
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