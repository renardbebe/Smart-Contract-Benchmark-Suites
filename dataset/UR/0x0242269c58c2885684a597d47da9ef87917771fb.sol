 

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

 

 
contract ERC20Basic {
  uint256 public totalSupply;
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

 

 

pragma solidity ^0.4.23;


contract DragonKingConfig is Ownable {

  struct PurchaseRequirement {
    address[] tokens;
    uint256[] amounts;
  }

   
  constructor(uint8 characterFee, uint8 eruptionThresholdInHours, uint8 percentageOfCharactersToKill, uint128[] charactersCosts, address[] tokens) public {
    fee = characterFee;
    for (uint8 i = 0; i < charactersCosts.length; i++) {
      costs.push(uint128(charactersCosts[i]) * 1 finney);
      values.push(costs[i] - costs[i] / 100 * fee);
    }
    eruptionThreshold = uint256(eruptionThresholdInHours) * 60 * 60;  
    castleLootDistributionThreshold = 1 days;  
    percentageToKill = percentageOfCharactersToKill;
    maxCharacters = 600;
    teleportPrice = 1000000000000000000;
    protectionPrice = 1000000000000000000;
    luckThreshold = 4200;
    fightFactor = 4;
    giftTokenAmount = 1000000000000000000;
    giftToken = ERC20(tokens[8]);
     
     
    purchaseRequirements[7].tokens = [tokens[5]];  
    purchaseRequirements[7].amounts = [250];
    purchaseRequirements[8].tokens = [tokens[5]];  
    purchaseRequirements[8].amounts = [5*(10**2)];
    purchaseRequirements[9].tokens = [tokens[5]];  
    purchaseRequirements[9].amounts = [10*(10**2)];
    purchaseRequirements[10].tokens = [tokens[5]];  
    purchaseRequirements[10].amounts = [20*(10**2)];
    purchaseRequirements[11].tokens = [tokens[5]];  
    purchaseRequirements[11].amounts = [50*(10**2)];
     
    purchaseRequirements[15].tokens = [tokens[2], tokens[3]];  
    purchaseRequirements[15].amounts = [25*(10**17), 5*(10**2)];
    purchaseRequirements[16].tokens = [tokens[2], tokens[3], tokens[4]];  
    purchaseRequirements[16].amounts = [5*(10**18), 10*(10**2), 250];
    purchaseRequirements[17].tokens = [tokens[2], tokens[3], tokens[4]];  
    purchaseRequirements[17].amounts = [10*(10**18), 20*(10**2), 5*(10**2)];
    purchaseRequirements[18].tokens = [tokens[2], tokens[3], tokens[4]];  
    purchaseRequirements[18].amounts = [25*(10**18), 50*(10**2), 10*(10**2)];
    purchaseRequirements[19].tokens = [tokens[2], tokens[3], tokens[4]];  
    purchaseRequirements[19].amounts = [50*(10**18), 100*(10**2), 20*(10**2)]; 
    purchaseRequirements[20].tokens = [tokens[2], tokens[3], tokens[4]];  
    purchaseRequirements[20].amounts = [100*(10**18), 200*(10**2), 50*(10**2)];
     
    purchaseRequirements[21].tokens = [tokens[2], tokens[3]];  
    purchaseRequirements[21].amounts = [25*(10**17), 5*(10**2)];
    purchaseRequirements[22].tokens = [tokens[2], tokens[3], tokens[6]];  
    purchaseRequirements[22].amounts = [5*(10**18), 10*(10**2), 250];
    purchaseRequirements[23].tokens = [tokens[2], tokens[3], tokens[6]];  
    purchaseRequirements[23].amounts = [10*(10**18), 20*(10**2), 5*(10**2)];
    purchaseRequirements[24].tokens = [tokens[2], tokens[3], tokens[6]];  
    purchaseRequirements[24].amounts = [25*(10**18), 50*(10**2), 10*(10**2)];
    purchaseRequirements[25].tokens = [tokens[2], tokens[3], tokens[6]];  
    purchaseRequirements[25].amounts = [50*(10**18), 100*(10**2), 20*(10**2)]; 
    purchaseRequirements[26].tokens = [tokens[2], tokens[3], tokens[6]];  
    purchaseRequirements[26].amounts = [100*(10**18), 200*(10**2), 50*(10**2)];
  }

   
  ERC20 public giftToken;
   
  uint256 public giftTokenAmount;
   
  PurchaseRequirement[30] purchaseRequirements; 
   
  uint128[] public costs;
   
  uint128[] public values;
   
  uint8 fee;
   
  uint16 public maxCharacters;
   
  uint256 public eruptionThreshold;
   
  uint256 public castleLootDistributionThreshold;
   
  uint8 public percentageToKill;
   
  uint256 public constant CooldownThreshold = 1 days;
   
  uint8 public fightFactor;

   
  uint256 public teleportPrice;
   
  uint256 public protectionPrice;
   
  uint256 public luckThreshold;

  function hasEnoughTokensToPurchase(address buyer, uint8 characterType) external returns (bool canBuy) {
    for (uint256 i = 0; i < purchaseRequirements[characterType].tokens.length; i++) {
      if (ERC20(purchaseRequirements[characterType].tokens[i]).balanceOf(buyer) < purchaseRequirements[characterType].amounts[i]) {
        return false;
      }
    }
    return true;
  }


  function setPurchaseRequirements(uint8 characterType, address[] tokens, uint256[] amounts) external {
    purchaseRequirements[characterType].tokens = tokens;
    purchaseRequirements[characterType].amounts = amounts;
  } 

  function getPurchaseRequirements(uint8 characterType) view external returns (address[] tokens, uint256[] amounts) {
    tokens = purchaseRequirements[characterType].tokens;
    amounts = purchaseRequirements[characterType].amounts;
  }

   
  function setPrices(uint16[] prices) external onlyOwner {
    for (uint8 i = 0; i < prices.length; i++) {
      costs[i] = uint128(prices[i]) * 1 finney;
      values[i] = costs[i] - costs[i] / 100 * fee;
    }
  }

   
  function setEruptionThreshold(uint256 _value) external onlyOwner {
    eruptionThreshold = _value;
  }

   
  function setCastleLootDistributionThreshold(uint256 _value) external onlyOwner {
    castleLootDistributionThreshold = _value;
  }

   
  function setFee(uint8 _value) external onlyOwner {
    fee = _value;
  }

   
  function setPercentageToKill(uint8 _value) external onlyOwner {
    percentageToKill = _value;
  }

   
  function setMaxCharacters(uint16 _value) external onlyOwner {
    maxCharacters = _value;
  }

   
  function setFightFactor(uint8 _value) external onlyOwner {
    fightFactor = _value;
  }

   
  function setTeleportPrice(uint256 _value) external onlyOwner {
    teleportPrice = _value;
  }

   
  function setProtectionPrice(uint256 _value) external onlyOwner {
    protectionPrice = _value;
  }

   
  function setLuckThreshold(uint256 _value) external onlyOwner {
    luckThreshold = _value;
  }

   
  function setGiftTokenAmount(uint256 _value) {
    giftTokenAmount = _value;
  }

   
  function setGiftToken(address _value) {
    giftToken = ERC20(_value);
  }


}