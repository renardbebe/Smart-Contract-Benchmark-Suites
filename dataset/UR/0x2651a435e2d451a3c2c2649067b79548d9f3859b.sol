 

pragma solidity ^0.4.18;
 
 

interface CardsInterface {
  function getJadeProduction(address player) external constant returns (uint256);
  function getOwnedCount(address player, uint256 cardId) external view returns (uint256);
  function getUintCoinProduction(address _address, uint256 cardId) external view returns (uint256);
  function getUnitCoinProductionMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitCoinProductionIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitAttackIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitAttackMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitDefenseIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitDefenseMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitJadeStealingIncreases(address _address, uint256 cardId) external view returns (uint256);
  function getUnitJadeStealingMultiplier(address _address, uint256 cardId) external view returns (uint256);
  function getUnitsProduction(address player, uint256 cardId, uint256 amount) external constant returns (uint256);
}

interface GameConfigInterface {
  function productionCardIdRange() external constant returns (uint256, uint256);
  function battleCardIdRange() external constant returns (uint256, uint256);
  function unitCoinProduction(uint256 cardId) external constant returns (uint256);
  function unitAttack(uint256 cardId) external constant returns (uint256);
  function unitDefense(uint256 cardId) external constant returns (uint256); 
  function unitStealingCapacity(uint256 cardId) external constant returns (uint256);
}

contract CardsRead {
  CardsInterface public cards;
  GameConfigInterface public schema;
  address owner;

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function CardsRead() public {
    owner = msg.sender;
  }
     
  function setConfigAddress(address _address) external onlyOwner {
    schema = GameConfigInterface(_address);
  }

      
  function setCardsAddress(address _address) external onlyOwner {
    cards = CardsInterface(_address);
  }
  function getNormalCard(address _owner) private view returns (uint256) {
    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.productionCardIdRange(); 
    uint256 icount;
    while (startId <= endId) {
      if (cards.getOwnedCount(_owner,startId)>=1) {
        icount++;
      }
      startId++;
    }
    return icount;
  }

  function getBattleCard(address _owner) private view returns (uint256) {
    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.battleCardIdRange(); 
    uint256 icount;
    while (startId <= endId) {
      if (cards.getOwnedCount(_owner,startId)>=1) {
        icount++;
      }
      startId++;
    }
    return icount;
  }
   
  function getNormalCardList(address _owner) external view returns(uint256[],uint256[]){
    uint256 len = getNormalCard(_owner);
    uint256[] memory itemId = new uint256[](len);
    uint256[] memory itemNumber = new uint256[](len);
    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.productionCardIdRange(); 
    uint256 i;
    while (startId <= endId) {
      if (cards.getOwnedCount(_owner,startId)>=1) {
        itemId[i] = startId;
        itemNumber[i] = cards.getOwnedCount(_owner,startId);
        i++;
      }
      startId++;
      }   
    return (itemId, itemNumber);
  }

   
  function getBattleCardList(address _owner) external view returns(uint256[],uint256[]){
    uint256 len = getBattleCard(_owner);
    uint256[] memory itemId = new uint256[](len);
    uint256[] memory itemNumber = new uint256[](len);

    uint256 startId;
    uint256 endId;
    (startId,endId) = schema.battleCardIdRange(); 

    uint256 i;
    while (startId <= endId) {
      if (cards.getOwnedCount(_owner,startId)>=1) {
        itemId[i] = startId;
        itemNumber[i] = cards.getOwnedCount(_owner,startId);
        i++;
      }
      startId++;
      }   
    return (itemId, itemNumber);
  }

     
  function getUpgradeValue(address player, uint256 upgradeClass, uint256 unitId, uint256 upgradeValue) external view returns (
    uint256 productionGain ,uint256 preValue,uint256 afterValue) {
    if (cards.getOwnedCount(player,unitId) == 0) {
      if (upgradeClass == 0) {
        productionGain = upgradeValue * 10;
        preValue = schema.unitCoinProduction(unitId);
        afterValue   = preValue + productionGain;
      } else if (upgradeClass == 1){
        productionGain = upgradeValue * schema.unitCoinProduction(unitId);
        preValue = schema.unitCoinProduction(unitId);
        afterValue   = preValue + productionGain;
      } 
    }else {  
      if (upgradeClass == 0) {
        productionGain = (cards.getOwnedCount(player,unitId) * upgradeValue * (10 + cards.getUnitCoinProductionMultiplier(player,unitId)));
        preValue = cards.getUintCoinProduction(player,unitId);
        afterValue   = preValue + productionGain;
     } else if (upgradeClass == 1) {
        productionGain = (cards.getOwnedCount(player,unitId) * upgradeValue * (schema.unitCoinProduction(unitId) + cards.getUnitCoinProductionIncreases(player,unitId)));
        preValue = cards.getUintCoinProduction(player,unitId);
        afterValue   = preValue + productionGain;
     }
    }
  }
}