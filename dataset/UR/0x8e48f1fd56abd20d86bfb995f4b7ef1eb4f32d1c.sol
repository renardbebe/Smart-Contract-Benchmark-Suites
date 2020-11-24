 

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

contract SkinBase is Pausable {

    struct Skin {
        uint128 appearance;
        uint64 cooldownEndTime;
        uint64 mixingWithId;
    }

     
    mapping (uint256 => Skin) skins;

     
    mapping (uint256 => address) public skinIdToOwner;

     
    mapping (uint256 => bool) public isOnSale;

     
     
    uint256 public nextSkinId = 1;  

     
    mapping (address => uint256) public numSkinOfAccounts;

     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    function skinOfAccountById(address account, uint256 id) external view returns (uint256) {
       uint256 count = 0;
       uint256 numSkinOfAccount = numSkinOfAccounts[account];
       require(numSkinOfAccount > 0);
       require(id < numSkinOfAccount);
       for (uint256 i = 1; i < nextSkinId; i++) {
           if (skinIdToOwner[i] == account) {
                
               if (count == id) {
                    
                    return i;
               } 
               count++;
           }
        }
        revert();
    }

     
    function getSkin(uint256 id) public view returns (uint128, uint64, uint64) {
        require(id > 0);
        require(id < nextSkinId);
        Skin storage skin = skins[id];
        return (skin.appearance, skin.cooldownEndTime, skin.mixingWithId);
    }

    function withdrawETH() external onlyOwner {
        owner.transfer(this.balance);
    }
}
contract MixFormulaInterface {
    function calcNewSkinAppearance(uint128 x, uint128 y) public pure returns (uint128);

     
    function randomSkinAppearance() public view returns (uint128);

     
    function bleachAppearance(uint128 appearance, uint128 attributes) public pure returns (uint128);
}
contract SkinMix is SkinBase {

     
    MixFormulaInterface public mixFormula;


     
    uint256 public prePaidFee = 2500000 * 5000000000;  

     
    event MixStart(address account, uint256 skinAId, uint256 skinBId);
    event AutoMix(address account, uint256 skinAId, uint256 skinBId, uint64 cooldownEndTime);
    event MixSuccess(address account, uint256 skinId, uint256 skinAId, uint256 skinBId);

     
    function setMixFormulaAddress(address mixFormulaAddress) external onlyOwner {
        mixFormula = MixFormulaInterface(mixFormulaAddress);
    }

     
    function setPrePaidFee(uint256 newPrePaidFee) external onlyOwner {
        prePaidFee = newPrePaidFee;
    }

     
    function _isCooldownReady(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].cooldownEndTime <= uint64(now)) && (skins[skinBId].cooldownEndTime <= uint64(now));
    }

     
    function _isNotMixing(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].mixingWithId == 0) && (skins[skinBId].mixingWithId == 0);
    }

     
    function _setCooldownEndTime(uint256 skinAId, uint256 skinBId) private {
        uint256 end = now + 5 minutes;
         
        skins[skinAId].cooldownEndTime = uint64(end);
        skins[skinBId].cooldownEndTime = uint64(end);
    }

     
     
     
     
    function _isValidSkin(address account, uint256 skinAId, uint256 skinBId) private view returns (bool) {
         
        if (skinAId == skinBId) {
            return false;
        }
        if ((skinAId == 0) || (skinBId == 0)) {
            return false;
        }
        if ((skinAId >= nextSkinId) || (skinBId >= nextSkinId)) {
            return false;
        }
        return (skinIdToOwner[skinAId] == account) && (skinIdToOwner[skinBId] == account);
    }

     
    function _isNotOnSale(uint256 skinId) private view returns (bool) {
        return (isOnSale[skinId] == false);
    }

     
    function mix(uint256 skinAId, uint256 skinBId) public whenNotPaused {

         
        require(_isValidSkin(msg.sender, skinAId, skinBId));

         
        require(_isNotOnSale(skinAId) && _isNotOnSale(skinBId));

         
        require(_isCooldownReady(skinAId, skinBId));

         
        require(_isNotMixing(skinAId, skinBId));

         
        _setCooldownEndTime(skinAId, skinBId);

         
        skins[skinAId].mixingWithId = uint64(skinBId);
        skins[skinBId].mixingWithId = uint64(skinAId);

         
        MixStart(msg.sender, skinAId, skinBId);
    }

     
    function mixAuto(uint256 skinAId, uint256 skinBId) public payable whenNotPaused {
        require(msg.value >= prePaidFee);

        mix(skinAId, skinBId);

        Skin storage skin = skins[skinAId];

        AutoMix(msg.sender, skinAId, skinBId, skin.cooldownEndTime);
    }

     
    function getMixingResult(uint256 skinAId, uint256 skinBId) public whenNotPaused {
         
        address account = skinIdToOwner[skinAId];
        require(account == skinIdToOwner[skinBId]);

         
        Skin storage skinA = skins[skinAId];
        Skin storage skinB = skins[skinBId];
        require(skinA.mixingWithId == uint64(skinBId));
        require(skinB.mixingWithId == uint64(skinAId));

         
        require(_isCooldownReady(skinAId, skinBId));

         
        uint128 newSkinAppearance = mixFormula.calcNewSkinAppearance(skinA.appearance, skinB.appearance);
        Skin memory newSkin = Skin({appearance: newSkinAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = account;
        isOnSale[nextSkinId] = false;
        nextSkinId++;

         
        skinA.mixingWithId = 0;
        skinB.mixingWithId = 0;

         
         
         
        delete skinIdToOwner[skinAId];
        delete skinIdToOwner[skinBId];
         
        numSkinOfAccounts[account] -= 1;

        MixSuccess(account, nextSkinId - 1, skinAId, skinBId);
    }
}
contract SkinMarket is SkinMix {

     
     
    uint128 public trCut = 290;

     
    mapping (uint256 => uint256) public desiredPrice;

     
    event PutOnSale(address account, uint256 skinId);
    event WithdrawSale(address account, uint256 skinId);
    event BuyInMarket(address buyer, uint256 skinId);

     

     
    function putOnSale(uint256 skinId, uint256 price) public whenNotPaused {
         
        require(skinIdToOwner[skinId] == msg.sender);

         
        require(skins[skinId].mixingWithId == 0);

         
        require(isOnSale[skinId] == false);

        require(price > 0); 

         
        desiredPrice[skinId] = price;
        isOnSale[skinId] = true;

         
        PutOnSale(msg.sender, skinId);
    }
  
     
    function withdrawSale(uint256 skinId) external whenNotPaused {
         
        require(isOnSale[skinId] == true);
        
         
        require(skinIdToOwner[skinId] == msg.sender);

         
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

         
        WithdrawSale(msg.sender, skinId);
    }
 
     
    function buyInMarket(uint256 skinId) external payable whenNotPaused {
         
        require(isOnSale[skinId] == true);

        address seller = skinIdToOwner[skinId];

         
        require(msg.sender != seller);

        uint256 _price = desiredPrice[skinId];
         
        require(msg.value >= _price);

         
        uint256 sellerProceeds = _price - _computeCut(_price);

        seller.transfer(sellerProceeds);

         
        numSkinOfAccounts[seller] -= 1;
        skinIdToOwner[skinId] = msg.sender;
        numSkinOfAccounts[msg.sender] += 1;
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

         
        BuyInMarket(msg.sender, skinId);
    }

     
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price * trCut / 10000;
    }
}
contract SkinMinting is SkinMarket {

     
    uint256 public skinCreatedLimit = 50000;

     
    mapping (address => uint256) public accoutToSummonNum;

     
    mapping (address => uint256) public accoutToPayLevel;
    mapping (address => uint256) public accountsLastClearTime;

    uint256 public levelClearTime = now;

     
    uint256 public baseSummonPrice = 3 finney;
    uint256 public bleachPrice = 30 finney;

     
    uint256[5] public levelSplits = [10,
                                     20,
                                     50,
                                     100,
                                     200];
    
    uint256[6] public payMultiple = [1,
                                     2,
                                     4,
                                     8,
                                     20,
                                     100];


     
    event CreateNewSkin(uint256 skinId, address account);
    event Bleach(uint256 skinId, uint128 newAppearance);

     

     
    function setBaseSummonPrice(uint256 newPrice) external onlyOwner {
        baseSummonPrice = newPrice;
    }

    function setBleachPrice(uint256 newPrice) external onlyOwner {
        bleachPrice = newPrice;
    }

     
    function createSkin(uint128 specifiedAppearance, uint256 salePrice) external onlyOwner whenNotPaused {
        require(numSkinOfAccounts[owner] < skinCreatedLimit);

         
         
        Skin memory newSkin = Skin({appearance: specifiedAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = owner;
        isOnSale[nextSkinId] = false;

         
        CreateNewSkin(nextSkinId, owner);

         
        putOnSale(nextSkinId, salePrice);

        nextSkinId++;
        numSkinOfAccounts[owner] += 1;   
    }

     
    function summon() external payable whenNotPaused {
         
        if (accountsLastClearTime[msg.sender] == uint256(0)) {
             
            accountsLastClearTime[msg.sender] = now;
        } else {
            if (accountsLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accoutToSummonNum[msg.sender] = 0;
                accoutToPayLevel[msg.sender] = 0;
                accountsLastClearTime[msg.sender] = now;
            }
        }

        uint256 payLevel = accoutToPayLevel[msg.sender];
        uint256 price = payMultiple[payLevel] * baseSummonPrice;
        require(msg.value >= price);

         
        uint128 randomAppearance = mixFormula.randomSkinAppearance();
         
        Skin memory newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;

         
        CreateNewSkin(nextSkinId, msg.sender);

        nextSkinId++;
        numSkinOfAccounts[msg.sender] += 1;
        
        accoutToSummonNum[msg.sender] += 1;
        
         
        if (payLevel < 5) {
            if (accoutToSummonNum[msg.sender] >= levelSplits[payLevel]) {
                accoutToPayLevel[msg.sender] = payLevel + 1;
            }
        }
    }

     
    function bleach(uint128 skinId, uint128 attributes) external payable whenNotPaused {
         
        require(msg.sender == skinIdToOwner[skinId]);

         
        require(isOnSale[skinId] == false);

         
        require(msg.value >= bleachPrice);

        Skin storage originSkin = skins[skinId];
         
        require(originSkin.mixingWithId == 0);

        uint128 newAppearance = mixFormula.bleachAppearance(originSkin.appearance, attributes);
        originSkin.appearance = newAppearance;

         
        Bleach(skinId, newAppearance);
    }

     
    function clearSummonNum() external onlyOwner {
        uint256 nextDay = levelClearTime + 1 days;
        if (now > nextDay) {
            levelClearTime = nextDay;
        }
    }
}