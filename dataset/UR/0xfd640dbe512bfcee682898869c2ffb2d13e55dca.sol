 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


   
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

contract CryptoPhoenixes is Ownable, Pausable {
  using SafeMath for uint256;

  address public subDev;
  Phoenix[] private phoenixes;
  uint256 public PHOENIX_POOL;
  uint256 public EXPLOSION_DENOMINATOR = 1000;  
  bool public ALLOW_BETA = true;
  uint BETA_CUTOFF;

   
  mapping (address => uint256) public devFunds;

   
  mapping (address => uint256) public userFunds;

   
  event PhoenixPurchased(
    uint256 _phoenixId,
    address oldOwner,
    address newOwner,
    uint256 price,
    uint256 nextPrice
  );
  
  event PhoenixExploded(
      uint256 phoenixId,
      address owner,
      uint256 payout,
      uint256 price,
      uint nextExplosionTime
  );

  event WithdrewFunds(
    address owner
  );

   
  uint256 constant private QUARTER_ETH_CAP  = 0.25 ether;
  uint256 constant private ONE_ETH_CAP  = 1.0 ether;
  uint256 public BASE_PRICE = 0.0025 ether;
  uint256 public PRICE_CUTOFF = 1.0 ether;
  uint256 public HIGHER_PRICE_RESET_PERCENTAGE = 20;
  uint256 public LOWER_PRICE_RESET_PERCENTAGE = 10;

   
  struct Phoenix {
    uint256 price;   
    uint256 dividendPayout;  
    uint256 explosivePower;  
    uint cooldown;  
    uint nextExplosionTime;  
    address previousOwner;   
    address currentOwner;  
  }

 
  modifier inBeta() {
    require(ALLOW_BETA);
    _;
  }

 
  function CryptoPhoenixes(address _subDev) {
    BETA_CUTOFF = now + 90 * 1 days;  
    subDev = _subDev;
  }
  
 
  function closeBeta() {
    require(now >= BETA_CUTOFF);
    ALLOW_BETA = false;
  }

  function createPhoenix(uint256 _payoutPercentage, uint256 _explosivePower, uint _cooldown) onlyOwner public {
    
    var phoenix = Phoenix({
    price: BASE_PRICE,
    dividendPayout: _payoutPercentage,
    explosivePower: _explosivePower,
    cooldown: _cooldown,
    nextExplosionTime: now,
    previousOwner: address(0),
    currentOwner: this
    });

    phoenixes.push(phoenix);
  }

  function createMultiplePhoenixes(uint256[] _payoutPercentages, uint256[] _explosivePowers, uint[] _cooldowns) onlyOwner public {
    require(_payoutPercentages.length == _explosivePowers.length);
    require(_explosivePowers.length == _cooldowns.length);
    
    for (uint256 i = 0; i < _payoutPercentages.length; i++) {
      createPhoenix(_payoutPercentages[i],_explosivePowers[i],_cooldowns[i]);
    }
  }

  function getPhoenix(uint256 _phoenixId) public view returns (
    uint256 price,
    uint256 nextPrice,
    uint256 dividendPayout,
    uint256 effectivePayout,
    uint256 explosivePower,
    uint cooldown,
    uint nextExplosionTime,
    address previousOwner,
    address currentOwner
  ) {
    var phoenix = phoenixes[_phoenixId];
    price = phoenix.price;
    nextPrice = getNextPrice(phoenix.price);
    dividendPayout = phoenix.dividendPayout;
    effectivePayout = phoenix.dividendPayout.mul(10000).div(getTotalPayout());
    explosivePower = phoenix.explosivePower;
    cooldown = phoenix.cooldown;
    nextExplosionTime = phoenix.nextExplosionTime;
    previousOwner = phoenix.previousOwner;
    currentOwner = phoenix.currentOwner;
  }

 
  function getNextPrice (uint256 _price) private pure returns (uint256 _nextPrice) {
    if (_price < QUARTER_ETH_CAP) {
      return _price.mul(140).div(100);  
    } else if (_price < ONE_ETH_CAP) {
      return _price.mul(130).div(100);  
    } else {
      return _price.mul(125).div(100);  
    }
  }

 
  function setDividendPayout (uint256 _phoenixId, uint256 _payoutPercentage) onlyOwner inBeta {
    Phoenix phoenix = phoenixes[_phoenixId];
    phoenix.dividendPayout = _payoutPercentage;
  }

 
  function setExplosivePower (uint256 _phoenixId, uint256 _explosivePower) onlyOwner inBeta {
    Phoenix phoenix = phoenixes[_phoenixId];
    phoenix.explosivePower = _explosivePower;
  }

 
  function setCooldown (uint256 _phoenixId, uint256 _cooldown) onlyOwner inBeta {
    Phoenix phoenix = phoenixes[_phoenixId];
    phoenix.cooldown = _cooldown;
  }

 
  function setPriceCutoff (uint256 _price) onlyOwner {
    PRICE_CUTOFF = _price;
  }

 
  function setHigherPricePercentage (uint256 _percentage) onlyOwner inBeta {
    require(_percentage > 0);
    require(_percentage < 100);
    HIGHER_PRICE_RESET_PERCENTAGE = _percentage;
  }

 
  function setLowerPricePercentage (uint256 _percentage) onlyOwner inBeta {
    require(_percentage > 0);
    require(_percentage < 100);
    LOWER_PRICE_RESET_PERCENTAGE = _percentage;
  }

 
  function setBasePrice (uint256 _amount) onlyOwner {
    require(_amount > 0);
    BASE_PRICE = _amount;
  }

 
  function purchasePhoenix(uint256 _phoenixId) whenNotPaused public payable {
    Phoenix phoenix = phoenixes[_phoenixId];
     
    uint256 price = phoenix.price;

     
    require(price > 0);
    require(msg.value >= price);
     
    require(outgoingOwner != msg.sender);

     
    address previousOwner = phoenix.previousOwner;
    address outgoingOwner = phoenix.currentOwner;

     
    uint256 devCut;  
    uint256 dividendsCut; 
    uint256 previousOwnerCut;
    uint256 phoenixPoolCut;
    uint256 phoenixPoolPurchaseExcessCut;
    
     
    uint256 purchaseExcess = msg.value.sub(price);

     
    if (previousOwner == address(0)) {
        phoenix.previousOwner = msg.sender;
    }
    
     
    (devCut,dividendsCut,previousOwnerCut,phoenixPoolCut) = calculateCuts(price);

     
    uint256 outgoingOwnerCut = price.sub(devCut);
    outgoingOwnerCut = outgoingOwnerCut.sub(dividendsCut);
    outgoingOwnerCut = outgoingOwnerCut.sub(previousOwnerCut);
    outgoingOwnerCut = outgoingOwnerCut.sub(phoenixPoolCut);
    
     
    phoenixPoolPurchaseExcessCut = purchaseExcess.mul(2).div(100);
    purchaseExcess = purchaseExcess.sub(phoenixPoolPurchaseExcessCut);
    phoenixPoolCut = phoenixPoolCut.add(phoenixPoolPurchaseExcessCut);

     
    phoenix.price = getNextPrice(price);

     
    phoenix.currentOwner = msg.sender;

     
    devFunds[owner] = devFunds[owner].add(devCut.mul(7).div(10));  
    devFunds[subDev] = devFunds[subDev].add(devCut.mul(3).div(10));  
    distributeDividends(dividendsCut);
    userFunds[previousOwner] = userFunds[previousOwner].add(previousOwnerCut);
    PHOENIX_POOL = PHOENIX_POOL.add(phoenixPoolCut);

     
    if (outgoingOwner != address(this)) {
      sendFunds(outgoingOwner,outgoingOwnerCut);
    }

     
    if (purchaseExcess > 0) {
      sendFunds(msg.sender,purchaseExcess);
    }

     
    PhoenixPurchased(_phoenixId, outgoingOwner, msg.sender, price, phoenix.price);
  }

  function calculateCuts(uint256 _price) private pure returns (
    uint256 devCut, 
    uint256 dividendsCut,
    uint256 previousOwnerCut,
    uint256 phoenixPoolCut
    ) {
       
       
      devCut = _price.mul(2).div(100);

       
      dividendsCut = _price.mul(25).div(1000); 

       
      previousOwnerCut = _price.mul(5).div(1000);

       
      phoenixPoolCut = calculatePhoenixPoolCut(_price);
    }

  function calculatePhoenixPoolCut (uint256 _price) private pure returns (uint256 _poolCut) {
      if (_price < QUARTER_ETH_CAP) {
          return _price.mul(12).div(100);  
      } else if (_price < ONE_ETH_CAP) {
          return _price.mul(11).div(100);  
      } else {
          return _price.mul(10).div(100);  
      }
  }

  function distributeDividends(uint256 _dividendsCut) private {
    uint256 totalPayout = getTotalPayout();

    for (uint256 i = 0; i < phoenixes.length; i++) {
      var phoenix = phoenixes[i];
      var payout = _dividendsCut.mul(phoenix.dividendPayout).div(totalPayout);
      userFunds[phoenix.currentOwner] = userFunds[phoenix.currentOwner].add(payout);
    }
  }

  function getTotalPayout() private view returns(uint256) {
    uint256 totalPayout = 0;

    for (uint256 i = 0; i < phoenixes.length; i++) {
      var phoenix = phoenixes[i];
      totalPayout = totalPayout.add(phoenix.dividendPayout);
    }

    return totalPayout;
  }
    
 
  function explodePhoenix(uint256 _phoenixId) whenNotPaused public {
      Phoenix phoenix = phoenixes[_phoenixId];
      require(msg.sender == phoenix.currentOwner);
      require(PHOENIX_POOL > 0);
      require(now >= phoenix.nextExplosionTime);
      
      uint256 payout = phoenix.explosivePower.mul(PHOENIX_POOL).div(EXPLOSION_DENOMINATOR);

       
      PHOENIX_POOL = PHOENIX_POOL.sub(payout);
      
       
      if (phoenix.price >= PRICE_CUTOFF) {
        phoenix.price = phoenix.price.mul(HIGHER_PRICE_RESET_PERCENTAGE).div(100);
      } else {
        phoenix.price = phoenix.price.mul(LOWER_PRICE_RESET_PERCENTAGE).div(100);
        if (phoenix.price < BASE_PRICE) {
          phoenix.price = BASE_PRICE;
          }
      }

       
      phoenix.previousOwner = msg.sender;
       
      phoenix.nextExplosionTime = now + (phoenix.cooldown * 1 minutes);
      
       
      sendFunds(msg.sender,payout);
      
       
      PhoenixExploded(_phoenixId, msg.sender, payout, phoenix.price, phoenix.nextExplosionTime);
  }
  
 
  function sendFunds(address _user, uint256 _payout) private {
    if (!_user.send(_payout)) {
      userFunds[_user] = userFunds[_user].add(_payout);
    }
  }

 
  function devWithdraw() public {
    uint256 funds = devFunds[msg.sender];
    require(funds > 0);
    devFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
  }

 
  function withdrawFunds() public {
    uint256 funds = userFunds[msg.sender];
    require(funds > 0);
    userFunds[msg.sender] = 0;
    msg.sender.transfer(funds);
    WithdrewFunds(msg.sender);
  }
}