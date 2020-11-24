 

pragma solidity ^ 0.4.19;

 
 
 

 
 
 

 
contract ERC721 {
  function implementsERC721() public pure returns(bool);
  function totalSupply() public view returns(uint256 total);
  function balanceOf(address _owner) public view returns(uint256 balance);
  function ownerOf(uint256 _tokenId) public view returns(address owner);
  function approve(address _to, uint256 _tokenId) public;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;
  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

   
   
   
   
   
}

 

contract NarcosCoreInterface is ERC721 {
  function getNarco(uint256 _id)
  public
  view
  returns(
    string  narcoName,
    uint256 weedTotal,
    uint256 cokeTotal,
    uint16[6] skills,
    uint8[4] consumables,
    string genes,
    uint8 homeLocation,
    uint16 level,
    uint256[6] cooldowns,
    uint256 id,
    uint16[9] stats
  );

  function updateWeedTotal(uint256 _narcoId, bool _add, uint16 _total) public;
  function updateCokeTotal(uint256 _narcoId, bool _add,  uint16 _total) public;
  function updateConsumable(uint256 _narcoId, uint256 _index, uint8 _new) public;
  function updateSkill(uint256 _narcoId, uint256 _index, uint16 _new) public;
  function incrementStat(uint256 _narcoId, uint256 _index) public;
  function setCooldown(uint256 _narcoId , uint256 _index , uint256 _new) public;
  function getRemainingCapacity(uint256 _id) public view returns (uint8 capacity);
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


 

contract DistrictsAdmin is Ownable, Pausable {
  event ContractUpgrade(address newContract);

  address public newContractAddress;
  address public coreAddress;

  NarcosCoreInterface public narcoCore;

  function setNarcosCoreAddress(address _address) public onlyOwner {
    _setNarcosCoreAddress(_address);
  }

  function _setNarcosCoreAddress(address _address) internal {
    NarcosCoreInterface candidateContract = NarcosCoreInterface(_address);
    require(candidateContract.implementsERC721());
    coreAddress = _address;
    narcoCore = candidateContract;
  }

   
   
   
   
   
  function setNewAddress(address _v2Address) public onlyOwner whenPaused {
    newContractAddress = _v2Address;

    ContractUpgrade(_v2Address);
  }


   
  address [6] public tokenContractAddresses;

  function setTokenAddresses(address[6] _addresses) public onlyOwner {
      tokenContractAddresses = _addresses;
  }

  modifier onlyDopeRaiderContract() {
    require(msg.sender == coreAddress);
    _;
  }

  modifier onlyTokenContract() {
    require(
        msg.sender == tokenContractAddresses[0] ||
        msg.sender == tokenContractAddresses[1] ||
        msg.sender == tokenContractAddresses[2] ||
        msg.sender == tokenContractAddresses[3] ||
        msg.sender == tokenContractAddresses[4] ||
        msg.sender == tokenContractAddresses[5]
      );
    _;
  }

}


 

contract DistrictsCore is DistrictsAdmin {

   
  event NarcoArrived(uint8 indexed location, uint256 indexed narcoId);  
  event NarcoLeft(uint8 indexed location, uint256 indexed narcoId);  
  event TravelBust(uint256 indexed narcoId, uint16 confiscatedWeed, uint16 confiscatedCoke);
  event Hijacked(uint256 indexed hijacker, uint256 indexed victim , uint16 stolenWeed , uint16 stolenCoke);
  event HijackDefended(uint256 indexed hijacker, uint256 indexed victim);
  event EscapedHijack(uint256 indexed hijacker, uint256 indexed victim , uint8 escapeLocation);

  uint256 public airLiftPrice = 0.01 ether;  
  uint256 public hijackPrice = 0.008 ether;  
  uint256 public travelPrice = 0.002 ether;  
  uint256 public spreadPercent = 5;  
  uint256 public devFeePercent = 2;  
  uint256 public currentDevFees = 0;
  uint256 public bustRange = 10;

  function setAirLiftPrice(uint256 _price) public onlyOwner{
    airLiftPrice = _price;
  }

  function setBustRange(uint256 _range) public onlyOwner{
    bustRange = _range;
  }

  function setHijackPrice(uint256 _price) public onlyOwner{
    hijackPrice = _price;
  }

  function setTravelPrice(uint256 _price) public onlyOwner{
    travelPrice = _price;
  }

  function setSpreadPercent(uint256 _spread) public onlyOwner{
    spreadPercent = _spread;
  }

  function setDevFeePercent(uint256 _fee) public onlyOwner{
    devFeePercent = _fee;
  }

  function isDopeRaiderDistrictsCore() public pure returns(bool){ return true; }


   

  struct MarketItem{
    uint256 id;
    string itemName;
    uint8 skillAffected;
    uint8 upgradeAmount;
    uint8 levelRequired;  
  }

   
   
  MarketItem[24] public marketItems;

  function configureMarketItem(uint256 _id, uint8 _skillAffected, uint8  _upgradeAmount, uint8 _levelRequired, string _itemName) public onlyOwner{
    marketItems[_id].skillAffected = _skillAffected;
    marketItems[_id].upgradeAmount = _upgradeAmount;
    marketItems[_id].levelRequired = _levelRequired;
    marketItems[_id].itemName = _itemName;
    marketItems[_id].id = _id;
  }


  struct District {
    uint256[6] exits;
    uint256 weedPot;
    uint256 weedAmountHere;
    uint256 cokePot;
    uint256 cokeAmountHere;
    uint256[24] marketPrices;
    bool[24] isStocked;
    bool hasMarket;
    string name;
  }

  District[8] public districts;  

   
  mapping(uint256 => uint8) narcoIndexToLocation;

  function DistrictsCore() public {
  }

  function getDistrict(uint256 _id) public view returns(uint256[6] exits, bool hasMarket, uint256[24] prices, bool[24] isStocked, uint256 weedPot, uint256 cokePot, uint256 weedAmountHere, uint256 cokeAmountHere, string name){
    District storage district = districts[_id];
    exits = district.exits;
    hasMarket = district.hasMarket;
    prices = district.marketPrices;

     
    prices[0] = max(prices[0], (((district.weedPot / district.weedAmountHere)/100)*(100+spreadPercent))); 
    prices[1] = max(prices[1], (((district.cokePot / district.cokeAmountHere)/100)*(100+spreadPercent)));   
    isStocked = district.isStocked;
    weedPot = district.weedPot;
    cokePot = district.cokePot;
    weedAmountHere = district.weedAmountHere;
    cokeAmountHere = district.cokeAmountHere;
    name = district.name;
  }

  function createNamedDistrict(uint256 _index, string _name, bool _hasMarket) public onlyOwner{
    districts[_index].name = _name;
    districts[_index].hasMarket = _hasMarket;
    districts[_index].weedAmountHere = 1;
    districts[_index].cokeAmountHere = 1;
    districts[_index].weedPot = 0.001 ether;
    districts[_index].cokePot = 0.001 ether;
  }

  function initializeSupply(uint256 _index, uint256 _weedSupply, uint256 _cokeSupply) public onlyOwner{
    districts[_index].weedAmountHere = _weedSupply;
    districts[_index].cokeAmountHere = _cokeSupply;
  }

  function configureDistrict(uint256 _index, uint256[6]_exits, uint256[24] _prices, bool[24] _isStocked) public onlyOwner{
    districts[_index].exits = _exits;  
    districts[_index].marketPrices = _prices;
    districts[_index].isStocked = _isStocked;
  }

   
  function increaseDistrictWeed(uint256 _district, uint256 _quantity) public onlyDopeRaiderContract{
    districts[_district].weedAmountHere += _quantity;
  }
  function increaseDistrictCoke(uint256 _district, uint256 _quantity) public onlyDopeRaiderContract{
    districts[_district].cokeAmountHere += _quantity;
  }

   
  function updateConsumable(uint256 _narcoId,  uint256 _index ,uint8 _newQuantity) public onlyTokenContract {
    narcoCore.updateConsumable(_narcoId,  _index, _newQuantity);
  }

  function updateWeedTotal(uint256 _narcoId,  uint16 _total) public onlyTokenContract {
    narcoCore.updateWeedTotal(_narcoId,  true , _total);
    districts[getNarcoLocation(_narcoId)].weedAmountHere += uint8(_total);
  }

  function updatCokeTotal(uint256 _narcoId,  uint16 _total) public onlyTokenContract {
    narcoCore.updateCokeTotal(_narcoId,  true , _total);
    districts[getNarcoLocation(_narcoId)].cokeAmountHere += uint8(_total);
  }


  function getNarcoLocation(uint256 _narcoId) public view returns(uint8 location){
    location = narcoIndexToLocation[_narcoId];
     
    if (location == 0) {
      (
            ,
            ,
            ,
            ,
            ,
            ,
        location
        ,
        ,
        ,
        ,
        ) = narcoCore.getNarco(_narcoId);

    }

  }

  function getNarcoHomeLocation(uint256 _narcoId) public view returns(uint8 location){
      (
            ,
            ,
            ,
            ,
            ,
            ,
        location
        ,
        ,
        ,
        ,
        ) = narcoCore.getNarco(_narcoId);
  }

   
  function floatEconony() public payable onlyOwner {
        if(msg.value>0){
          for (uint district=1;district<8;district++){
              districts[district].weedPot+=(msg.value/14);
              districts[district].cokePot+=(msg.value/14);
            }
        }
    }

   
  function distributeRevenue(uint256 _district , uint8 _splitW, uint8 _splitC) public payable onlyDopeRaiderContract {
        if(msg.value>0){
         _distributeRevenue(msg.value, _district, _splitW, _splitC);
        }
  }

  uint256 public localRevenuePercent = 80;

  function setLocalRevenuPercent(uint256 _lrp) public onlyOwner{
    localRevenuePercent = _lrp;
  }

  function _distributeRevenue(uint256 _grossRevenue, uint256 _district , uint8 _splitW, uint8 _splitC) internal {
           
          uint256 onePc = _grossRevenue/100;
          uint256 netRevenue = onePc*(100-devFeePercent);
          uint256 devFee = onePc*(devFeePercent);

          uint256 districtRevenue = (netRevenue/100)*localRevenuePercent;
          uint256 federalRevenue = (netRevenue/100)*(100-localRevenuePercent);

           
           
          districts[_district].weedPot+=(districtRevenue/100)*_splitW;
          districts[_district].cokePot+=(districtRevenue/100)*_splitC;

           
           for (uint district=1;district<8;district++){
              districts[district].weedPot+=(federalRevenue/14);
              districts[district].cokePot+=(federalRevenue/14);
            }

           
          currentDevFees+=devFee;
  }

  function withdrawFees() external onlyOwner {
        if (currentDevFees<=address(this).balance){
          currentDevFees = 0;
          msg.sender.transfer(currentDevFees);
        }
    }


  function buyItem(uint256 _narcoId, uint256 _district, uint256 _itemIndex, uint256 _quantity) public payable whenNotPaused{
    require(narcoCore.ownerOf(_narcoId) == msg.sender);  

    uint256 narcoWeedTotal;
    uint256 narcoCokeTotal;
    uint16[6] memory narcoSkills;
    uint8[4] memory narcoConsumables;
    uint16 narcoLevel;

    (
                ,
      narcoWeedTotal,
      narcoCokeTotal,
      narcoSkills,
      narcoConsumables,
                ,
                ,
      narcoLevel,
                ,
                ,
    ) = narcoCore.getNarco(_narcoId);

    require(getNarcoLocation(_narcoId) == uint8(_district));  
    require(uint8(_quantity) > 0 && districts[_district].isStocked[_itemIndex] == true);  
    require(marketItems[_itemIndex].levelRequired <= narcoLevel || _district==7);  
    require(narcoCore.getRemainingCapacity(_narcoId) >= _quantity || _itemIndex>=6);  

     
    if (_itemIndex>=6) {
      require (_quantity==1);

      if (marketItems[_itemIndex].skillAffected!=5){
             
            require (marketItems[_itemIndex].levelRequired==0 || narcoSkills[marketItems[_itemIndex].skillAffected]<marketItems[_itemIndex].upgradeAmount);
          }else{
             
            require (narcoSkills[5]<20+marketItems[_itemIndex].upgradeAmount);
      }
    }

    uint256 costPrice = districts[_district].marketPrices[_itemIndex] * _quantity;

    if (_itemIndex ==0 ) {
      costPrice = max(districts[_district].marketPrices[0], (((districts[_district].weedPot / districts[_district].weedAmountHere)/100)*(100+spreadPercent))) * _quantity;
    }
    if (_itemIndex ==1 ) {
      costPrice = max(districts[_district].marketPrices[1], (((districts[_district].cokePot / districts[_district].cokeAmountHere)/100)*(100+spreadPercent))) * _quantity;
    }

    require(msg.value >= costPrice);  
     
    if (_itemIndex > 1 && _itemIndex < 6) {
       
      narcoCore.updateConsumable(_narcoId, _itemIndex - 2, uint8(narcoConsumables[_itemIndex - 2] + _quantity));
       _distributeRevenue(costPrice, _district , 50, 50);
    }

    if (_itemIndex >= 6) {
         
         
        narcoCore.updateSkill(
          _narcoId,
          marketItems[_itemIndex].skillAffected,
          uint16(narcoSkills[marketItems[_itemIndex].skillAffected] + (marketItems[_itemIndex].upgradeAmount))
        );
        _distributeRevenue(costPrice, _district , 50, 50);
    }
    if (_itemIndex == 0) {
         
        narcoCore.updateWeedTotal(_narcoId, true,  uint16(_quantity));
        districts[_district].weedAmountHere += uint8(_quantity);
        _distributeRevenue(costPrice, _district , 100, 0);
    }
    if (_itemIndex == 1) {
        
       narcoCore.updateCokeTotal(_narcoId, true, uint16(_quantity));
       districts[_district].cokeAmountHere += uint8(_quantity);
       _distributeRevenue(costPrice, _district , 0, 100);
    }

     
    if (msg.value>costPrice){
        msg.sender.transfer(msg.value-costPrice);
    }

  }


  function sellItem(uint256 _narcoId, uint256 _district, uint256 _itemIndex, uint256 _quantity) public whenNotPaused{
    require(narcoCore.ownerOf(_narcoId) == msg.sender);  
    require(_itemIndex < marketItems.length && _district < 8 && _district > 0 && _quantity > 0);  

    uint256 narcoWeedTotal;
    uint256 narcoCokeTotal;

    (
                ,
      narcoWeedTotal,
      narcoCokeTotal,
                ,
                ,
                ,
                ,
                ,
                ,
                ,
            ) = narcoCore.getNarco(_narcoId);


    require(getNarcoLocation(_narcoId) == _district);  
     
    require((_itemIndex == 0 && narcoWeedTotal >= _quantity) || (_itemIndex == 1 && narcoCokeTotal >= _quantity));

    uint256 salePrice = 0;

    if (_itemIndex == 0) {
      salePrice = districts[_district].weedPot / districts[_district].weedAmountHere;   
    }
    if (_itemIndex == 1) {
      salePrice = districts[_district].cokePot / districts[_district].cokeAmountHere;   
    }
    require(salePrice > 0);  

     
    if (_itemIndex == 0) {
      narcoCore.updateWeedTotal(_narcoId, false, uint16(_quantity));
      districts[_district].weedPot=sub(districts[_district].weedPot,salePrice*_quantity);
      districts[_district].weedAmountHere=sub(districts[_district].weedAmountHere,_quantity);
    }
    if (_itemIndex == 1) {
      narcoCore.updateCokeTotal(_narcoId, false, uint16(_quantity));
      districts[_district].cokePot=sub(districts[_district].cokePot,salePrice*_quantity);
      districts[_district].cokeAmountHere=sub(districts[_district].cokeAmountHere,_quantity);
    }
    narcoCore.incrementStat(_narcoId, 0);  
     
    msg.sender.transfer(salePrice*_quantity);

  }



   
   
  function travelTo(uint256 _narcoId, uint256 _exitId) public payable whenNotPaused{
    require(narcoCore.ownerOf(_narcoId) == msg.sender);  
    require((msg.value >= travelPrice && _exitId < 7) || (msg.value >= airLiftPrice && _exitId==7));

     


    uint256 narcoWeedTotal;
    uint256 narcoCokeTotal;
    uint16[6] memory narcoSkills;
    uint8[4] memory narcoConsumables;
    uint256[6] memory narcoCooldowns;

    (
                ,
      narcoWeedTotal,
      narcoCokeTotal,
      narcoSkills,
      narcoConsumables,
                ,
                ,
                ,
      narcoCooldowns,
                ,
    ) = narcoCore.getNarco(_narcoId);

     
    require(now>narcoCooldowns[0] && (narcoConsumables[0]>0 || _exitId==7));

    uint8 sourceLocation = getNarcoLocation(_narcoId);
    District storage sourceDistrict = districts[sourceLocation];  
    require(_exitId==7 || sourceDistrict.exits[_exitId] != 0);  

     
    uint256 localWeedTotal = districts[sourceLocation].weedAmountHere;
    uint256 localCokeTotal = districts[sourceLocation].cokeAmountHere;

    if (narcoWeedTotal < localWeedTotal) {
      districts[sourceLocation].weedAmountHere -= narcoWeedTotal;
    } else {
      districts[sourceLocation].weedAmountHere = 1;  
    }

    if (narcoCokeTotal < localCokeTotal) {
      districts[sourceLocation].cokeAmountHere -= narcoCokeTotal;
    } else {
      districts[sourceLocation].cokeAmountHere = 1;  
    }

     
    uint8 targetLocation = getNarcoHomeLocation(_narcoId);
    if (_exitId<7){
      targetLocation =  uint8(sourceDistrict.exits[_exitId]);
    }

    narcoIndexToLocation[_narcoId] = targetLocation;

     
    _distributeRevenue(msg.value, targetLocation , 50, 50);

     
    districts[targetLocation].weedAmountHere += narcoWeedTotal;
    districts[targetLocation].cokeAmountHere += narcoCokeTotal;

     
    if (_exitId!=7){
      narcoCore.updateConsumable(_narcoId, 0 , narcoConsumables[0]-1);
    }
     
     
    narcoCore.setCooldown( _narcoId ,  0 , now + (455-(5*narcoSkills[0])* 1 seconds));

     
    narcoCore.incrementStat(_narcoId, 7);
     
     uint64 bustChance=random(50+(5*narcoSkills[0]));  

     if (bustChance<=bustRange){
      busted(_narcoId,targetLocation,narcoWeedTotal,narcoCokeTotal);
     }

     NarcoArrived(targetLocation, _narcoId);  
     NarcoLeft(sourceLocation, _narcoId);  

  }

  function busted(uint256 _narcoId, uint256 targetLocation, uint256 narcoWeedTotal, uint256 narcoCokeTotal) private  {
       uint256 bustedWeed=narcoWeedTotal/2;  
       uint256 bustedCoke=narcoCokeTotal/2;  
       districts[targetLocation].weedAmountHere -= bustedWeed;  
       districts[targetLocation].cokeAmountHere -= bustedCoke;  
       districts[7].weedAmountHere += bustedWeed;  
       districts[7].cokeAmountHere += bustedCoke;  
       narcoCore.updateWeedTotal(_narcoId, false, uint16(bustedWeed));  
       narcoCore.updateCokeTotal(_narcoId, false, uint16(bustedCoke));  
       narcoCore.updateWeedTotal(0, true, uint16(bustedWeed));  
       narcoCore.updateCokeTotal(0, true, uint16(bustedCoke));  
       TravelBust(_narcoId, uint16(bustedWeed), uint16(bustedCoke));
  }


  function hijack(uint256 _hijackerId, uint256 _victimId)  public payable whenNotPaused{
    require(narcoCore.ownerOf(_hijackerId) == msg.sender);  
    require(msg.value >= hijackPrice);

     
    if (getNarcoLocation(_hijackerId)!=getNarcoLocation(_victimId)){
        EscapedHijack(_hijackerId, _victimId , getNarcoLocation(_victimId));
        narcoCore.incrementStat(_victimId, 6);  
    }else
    {
       
      uint256 hijackerWeedTotal;
      uint256 hijackerCokeTotal;
      uint16[6] memory hijackerSkills;
      uint8[4] memory hijackerConsumables;
      uint256[6] memory hijackerCooldowns;

      (
                  ,
        hijackerWeedTotal,
        hijackerCokeTotal,
        hijackerSkills,
        hijackerConsumables,
                  ,
                  ,
                  ,
        hijackerCooldowns,
                  ,
      ) = narcoCore.getNarco(_hijackerId);

       

      uint256 victimWeedTotal;
      uint256 victimCokeTotal;
      uint16[6] memory victimSkills;
      uint256[6] memory victimCooldowns;
      uint8 victimHomeLocation;
      (
                  ,
        victimWeedTotal,
        victimCokeTotal,
        victimSkills,
                  ,
                  ,
       victimHomeLocation,
                  ,
        victimCooldowns,
                  ,
      ) = narcoCore.getNarco(_victimId);

       
      require(getNarcoLocation(_victimId)!=victimHomeLocation || _victimId==0);
      require(hijackerConsumables[3] >0);  

      require(now>hijackerCooldowns[3]);  

       
      narcoCore.updateConsumable(_hijackerId, 3 , hijackerConsumables[3]-1);
       

       
       

      if (random((hijackerSkills[3]+victimSkills[4]))+1 >victimSkills[4]) {
         

        doHijack(_hijackerId  , _victimId , victimWeedTotal , victimCokeTotal);

         
        if (_victimId==0){
             narcoCore.incrementStat(_hijackerId, 5);  
        }

      }else{
         
        narcoCore.incrementStat(_victimId, 4);  
        HijackDefended( _hijackerId,_victimId);
      }

    }  

     
     narcoCore.setCooldown( _hijackerId ,  3 , now + (455-(5*hijackerSkills[3])* 1 seconds));  

       
      _distributeRevenue(hijackPrice, getNarcoLocation(_hijackerId) , 50, 50);

  }  

  function doHijack(uint256 _hijackerId  , uint256 _victimId ,  uint256 victimWeedTotal , uint256 victimCokeTotal) private {

        uint256 hijackerCapacity =  narcoCore.getRemainingCapacity(_hijackerId);

         
        uint16 stolenCoke = uint16(min(hijackerCapacity , (victimCokeTotal/2)));  
        uint16 stolenWeed = uint16(min(hijackerCapacity - stolenCoke, (victimWeedTotal/2)));  

         
        if (random(100)>50){
           stolenWeed = uint16(min(hijackerCapacity , (victimWeedTotal/2)));  
           stolenCoke = uint16(min(hijackerCapacity - stolenWeed, (victimCokeTotal/2)));  
        }

         
         
        if (stolenWeed>0){
          narcoCore.updateWeedTotal(_hijackerId, true, stolenWeed);
          narcoCore.updateWeedTotal(_victimId,false, stolenWeed);
        }
        if (stolenCoke>0){
          narcoCore.updateCokeTotal(_hijackerId, true , stolenCoke);
          narcoCore.updateCokeTotal(_victimId,false, stolenCoke);
        }

        narcoCore.incrementStat(_hijackerId, 3);  
        Hijacked(_hijackerId, _victimId , stolenWeed, stolenCoke);


  }


   
  uint64 _seed = 0;
  function random(uint64 upper) private returns (uint64 randomNumber) {
     _seed = uint64(keccak256(keccak256(block.blockhash(block.number-1), _seed), now));
     return _seed % upper;
   }

   function min(uint a, uint b) private pure returns (uint) {
            return a < b ? a : b;
   }
   function max(uint a, uint b) private pure returns (uint) {
            return a > b ? a : b;
   }
   function sub(uint256 a, uint256 b) internal pure returns (uint256) {
     assert(b <= a);
     return a - b;
   }
   
   
  function narcosByDistrict(uint8 _loc) public view returns(uint256[] narcosHere) {
    uint256 tokenCount = numberOfNarcosByDistrict(_loc);
    uint256 totalNarcos = narcoCore.totalSupply();
    uint256[] memory result = new uint256[](tokenCount);
    uint256 narcoId;
    uint256 resultIndex = 0;
    for (narcoId = 0; narcoId <= totalNarcos; narcoId++) {
      if (getNarcoLocation(narcoId) == _loc) {
        result[resultIndex] = narcoId;
        resultIndex++;
      }
    }
    return result;
  }

  function numberOfNarcosByDistrict(uint8 _loc) public view returns(uint256 number) {
    uint256 count = 0;
    uint256 narcoId;
    for (narcoId = 0; narcoId <= narcoCore.totalSupply(); narcoId++) {
      if (getNarcoLocation(narcoId) == _loc) {
        count++;
      }
    }
    return count;
  }

}