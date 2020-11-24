 

pragma solidity ^0.4.19;

 

 
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

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

 
contract HasNoEther is Ownable {

   
  function HasNoEther() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    assert(owner.send(this.balance));
  }
}

 

contract AxiePresale is HasNoEther, Pausable {
  using SafeMath for uint256;

  uint8 constant public CLASS_BEAST = 0;
  uint8 constant public CLASS_AQUATIC = 2;
  uint8 constant public CLASS_PLANT = 4;

  uint256 constant public INITIAL_PRICE_INCREMENT = 1600 szabo;  
  uint256 constant public INITIAL_PRICE = INITIAL_PRICE_INCREMENT;
  uint256 constant public REF_CREDITS_PER_AXIE = 5;

  mapping (uint8 => uint256) public currentPrices;
  mapping (uint8 => uint256) public priceIncrements;

  mapping (uint8 => uint256) public totalAxiesAdopted;
  mapping (address => mapping (uint8 => uint256)) public axiesAdopted;

  mapping (address => uint256) public referralCredits;
  mapping (address => uint256) public axiesRewarded;
  uint256 public totalAxiesRewarded;

  event AxiesAdopted(
    address indexed adopter,
    uint8 indexed clazz,
    uint256 quantity,
    address indexed referrer
  );

  event AxiesRewarded(address indexed receiver, uint256 quantity);

  event AdoptedAxiesRedeemed(address indexed receiver, uint8 indexed clazz, uint256 quantity);
  event RewardedAxiesRedeemed(address indexed receiver, uint256 quantity);

  function AxiePresale() public {
    priceIncrements[CLASS_BEAST] = priceIncrements[CLASS_AQUATIC] =  
      priceIncrements[CLASS_PLANT] = INITIAL_PRICE_INCREMENT;

    currentPrices[CLASS_BEAST] = currentPrices[CLASS_AQUATIC] =  
      currentPrices[CLASS_PLANT] = INITIAL_PRICE;
  }

  function axiesPrice(
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity
  )
    public
    view
    returns (uint256 totalPrice)
  {
    uint256 price;

    (price,,) = _axiesPrice(CLASS_BEAST, beastQuantity);
    totalPrice = totalPrice.add(price);

    (price,,) = _axiesPrice(CLASS_AQUATIC, aquaticQuantity);
    totalPrice = totalPrice.add(price);

    (price,,) = _axiesPrice(CLASS_PLANT, plantQuantity);
    totalPrice = totalPrice.add(price);
  }

  function adoptAxies(
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity,
    address referrer
  )
    public
    payable
    whenNotPaused
  {
    require(beastQuantity <= 3);
    require(aquaticQuantity <= 3);
    require(plantQuantity <= 3);

    address adopter = msg.sender;
    address actualReferrer = 0x0;

     
    if (referrer != adopter) {
      actualReferrer = referrer;
    }

    uint256 value = msg.value;
    uint256 price;

    if (beastQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_BEAST,
        beastQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    if (aquaticQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_AQUATIC,
        aquaticQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    if (plantQuantity > 0) {
      price = _adoptAxies(
        adopter,
        CLASS_PLANT,
        plantQuantity,
        actualReferrer
      );

      require(value >= price);
      value -= price;
    }

    msg.sender.transfer(value);

     
    if (actualReferrer != 0x0) {
      uint256 numCredit = referralCredits[actualReferrer]
        .add(beastQuantity)
        .add(aquaticQuantity)
        .add(plantQuantity);

      uint256 numReward = numCredit / REF_CREDITS_PER_AXIE;

      if (numReward > 0) {
        referralCredits[actualReferrer] = numCredit % REF_CREDITS_PER_AXIE;
        axiesRewarded[actualReferrer] = axiesRewarded[actualReferrer].add(numReward);
        totalAxiesRewarded = totalAxiesRewarded.add(numReward);
        AxiesRewarded(actualReferrer, numReward);
      } else {
        referralCredits[actualReferrer] = numCredit;
      }
    }
  }

  function redeemAdoptedAxies(
    address receiver,
    uint256 beastQuantity,
    uint256 aquaticQuantity,
    uint256 plantQuantity
  )
    public
    onlyOwner
    whenNotPaused
    returns (
      uint256  ,
      uint256  ,
      uint256  
    )
  {
    return (
      _redeemAdoptedAxies(receiver, CLASS_BEAST, beastQuantity),
      _redeemAdoptedAxies(receiver, CLASS_AQUATIC, aquaticQuantity),
      _redeemAdoptedAxies(receiver, CLASS_PLANT, plantQuantity)
    );
  }

  function redeemRewardedAxies(
    address receiver,
    uint256 quantity
  )
    public
    onlyOwner
    whenNotPaused
    returns (uint256 remainingQuantity)
  {
    remainingQuantity = axiesRewarded[receiver] = axiesRewarded[receiver].sub(quantity);

    if (quantity > 0) {
       
       
      totalAxiesRewarded -= quantity;

      RewardedAxiesRedeemed(receiver, quantity);
    }
  }

   
  function _axiesPrice(
    uint8 clazz,
    uint256 quantity
  )
    private
    view
    returns (uint256 totalPrice, uint256 priceIncrement, uint256 currentPrice)
  {
    priceIncrement = priceIncrements[clazz];
    currentPrice = currentPrices[clazz];

    uint256 nextPrice;

    for (uint256 i = 0; i < quantity; i++) {
      totalPrice = totalPrice.add(currentPrice);
      nextPrice = currentPrice.add(priceIncrement);

      if (nextPrice / 100 finney != currentPrice / 100 finney) {
        priceIncrement >>= 1;
      }

      currentPrice = nextPrice;
    }
  }

   
  function _adoptAxies(
    address adopter,
    uint8 clazz,
    uint256 quantity,
    address referrer
  )
    private
    returns (uint256 totalPrice)
  {
    (totalPrice, priceIncrements[clazz], currentPrices[clazz]) = _axiesPrice(clazz, quantity);

    axiesAdopted[adopter][clazz] = axiesAdopted[adopter][clazz].add(quantity);
    totalAxiesAdopted[clazz] = totalAxiesAdopted[clazz].add(quantity);

    AxiesAdopted(
      adopter,
      clazz,
      quantity,
      referrer
    );
  }

   
  function _redeemAdoptedAxies(
    address receiver,
    uint8 clazz,
    uint256 quantity
  )
    private
    returns (uint256 remainingQuantity)
  {
    remainingQuantity = axiesAdopted[receiver][clazz] = axiesAdopted[receiver][clazz].sub(quantity);

    if (quantity > 0) {
       
       
      totalAxiesAdopted[clazz] -= quantity;

      AdoptedAxiesRedeemed(receiver, clazz, quantity);
    }
  }
}