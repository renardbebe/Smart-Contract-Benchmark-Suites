 

pragma solidity ^0.4.25;

 

contract PremiumFactories {
    
    Bankroll constant bankroll = Bankroll(0x66a9f1e53173de33bec727ef76afa84956ae1b25);
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }
    
    mapping(uint256 => PremiumUnit) premiumUnits;  
    mapping(uint256 => PremiumFactory) premiumFactories;  
    
    uint256 minPrice = 0.5 ether;
    uint256 dailyDegradation = 10;  
    uint256 maxGasPrice = 20000000000;  
    uint256 constant LAUNCH_TIME = 1558814400;
    
    struct PremiumFactory {
        address owner;
        uint256 unitId;
        uint256 price;
        uint256 lastFlipTime;  
        uint256 lastClaimTimestamp;  
    }
    
    function purchaseFactory(uint256 factoryId) external payable {
        require(msg.sender == tx.origin);
        require(tx.gasprice <= maxGasPrice);
        require(now >= LAUNCH_TIME);
        
        PremiumFactory memory factory = premiumFactories[factoryId];
        require(msg.sender != factory.owner && factory.owner > 0);
        
        uint256 currentFactoryPrice = getFactoryPrice(factory);
        require(msg.value >= currentFactoryPrice);
        
        
        PremiumUnit premiumUnit = premiumUnits[factory.unitId];
        uint256 unitsProduced = (now - factory.lastClaimTimestamp) / premiumUnit.unitProductionSeconds();
        if (unitsProduced == 0) {
            unitsProduced++;  
        }
        premiumUnit.mintUnit(factory.owner, unitsProduced);
        
         
        uint256 previousOwnerProfit = currentFactoryPrice * 94 / 100;  
        factory.owner.transfer(previousOwnerProfit);
        bankroll.depositEth.value(currentFactoryPrice - previousOwnerProfit)(50, 50);  
        
         
        factory.price = currentFactoryPrice * 120 / 100;
        factory.owner = msg.sender;
        factory.lastFlipTime = now;
        factory.lastClaimTimestamp = now;
        premiumFactories[factoryId] = factory;
        
         
        if (msg.value > currentFactoryPrice) {
            msg.sender.transfer(msg.value - currentFactoryPrice);
        }
    }
    
    function getFactoryPrice(PremiumFactory factory) internal view returns (uint256 factoryPrice) {
        uint256 secondsSinceLastFlip = 0;
        if (now > factory.lastFlipTime) {  
            secondsSinceLastFlip = now - factory.lastFlipTime;
        }
        
        uint256 priceReduction = (secondsSinceLastFlip * dailyDegradation * factory.price) / 86400000;
        
        factoryPrice = factory.price;
        if (priceReduction > factoryPrice || factoryPrice - priceReduction < minPrice) {
            factoryPrice = minPrice;
        } else {
            factoryPrice -= priceReduction;
        }
    }
    
    function getFactories(uint256 endId) external view returns (uint256[] factoryIds, address[] owners, uint256[] unitIds, uint256[] prices, uint256[] lastClaimTime) {
        factoryIds = new uint256[](endId);
        owners = new address[](endId);
        unitIds = new uint256[](endId);
        prices = new uint256[](endId);
        lastClaimTime = new uint256[](endId);
        
        for (uint256 i = 0; i < endId; i++) {
            PremiumFactory memory factory = premiumFactories[i+1];  
            factoryIds[i] = i+1;
            owners[i] = factory.owner;
            unitIds[i] = factory.unitId;
            prices[i] = getFactoryPrice(factory);
            lastClaimTime[i] = factory.lastClaimTimestamp;
        }
    }
    
     
    function updateFactoryConfig(uint256 newMinPrice, uint256 newDailyDegradation, uint256 newMaxGasPrice) external {
        require(msg.sender == owner);
        minPrice = newMinPrice;
        dailyDegradation = newDailyDegradation;
        maxGasPrice = newMaxGasPrice;
    }
    
    function addPremiumUnit(address premiumUnitContract) external {
        require(msg.sender == owner);
        PremiumUnit unit = PremiumUnit(premiumUnitContract);
        premiumUnits[unit.unitId()] = unit;
    }
    
    function addFactory(uint256 id, uint256 unitId, address player, uint256 startPrice) external {
        require(msg.sender == owner);
        require(premiumFactories[id].owner == 0);
        require(premiumUnits[unitId].unitId() == unitId);
        
        PremiumFactory memory newFactory;
        newFactory.owner = player;
        newFactory.unitId = unitId;
        newFactory.price = startPrice;
        newFactory.lastClaimTimestamp = now;
        newFactory.lastFlipTime = LAUNCH_TIME;
        
        premiumFactories[id] = newFactory;
    }
    
    function claimUnits(uint256 factoryId, bool equip) external {
        PremiumFactory storage factory = premiumFactories[factoryId];
        require(factory.owner == msg.sender);
        
         
        PremiumUnit premiumUnit = premiumUnits[factory.unitId];
        uint256 unitProductionSeconds = premiumUnit.unitProductionSeconds();  
        uint256 unitsProduced = (now - factory.lastClaimTimestamp) / unitProductionSeconds;
        require(unitsProduced > 0);
        factory.lastClaimTimestamp += (unitProductionSeconds * unitsProduced);
        
         
        premiumUnit.mintUnit(msg.sender, unitsProduced);
        
         
        if (equip) {
             premiumUnit.equipUnit(msg.sender, uint80(unitsProduced), 100);
        }
    }
    
    
    
}

interface ERC20 {
    function totalSupply() external constant returns (uint);
    function balanceOf(address tokenOwner) external constant returns (uint balance);
    function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function approveAndCall(address spender, uint tokens, bytes data) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) external;
}

contract Bankroll {
     function depositEth(uint256 gooAllocation, uint256 tokenAllocation) payable external;
}

contract PremiumUnit {
    function mintUnit(address player, uint256 amount) external;
    function equipUnit(address player, uint80 amount, uint8 chosenPosition) external;
    uint256 public unitId;
    uint256 public unitProductionSeconds;
}

contract Units {
    mapping(address => mapping(uint256 => UnitsOwned)) public unitsOwned;
    function mintUnitExternal(uint256 unit, uint80 amount, address player, uint8 chosenPosition) external;
    function deleteUnitExternal(uint80 amount, uint256 unit, address player) external;
    
    struct UnitsOwned {
        uint80 units;
        uint8 factoryBuiltFlag;
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