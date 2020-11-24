 

pragma solidity ^0.4.18;

contract Manager {
    address public ceo;
    address public cfo;
    address public coo;
    address public cao;

    event OwnershipTransferred(address previousCeo, address newCeo);
    event Pause();
    event Unpause();


     
    function Manager() public {
        coo = msg.sender; 
        cfo = 0x7810704C6197aFA95e940eF6F719dF32657AD5af;
        ceo = 0x96C0815aF056c5294Ad368e3FBDb39a1c9Ae4e2B;
        cao = 0xC4888491B404FfD15cA7F599D624b12a9D845725;
    }

     
    modifier onlyCEO() {
        require(msg.sender == ceo);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == coo);
        _;
    }

    modifier onlyCAO() {
        require(msg.sender == cao);
        _;
    }
    
    bool allowTransfer = false;
    
    function changeAllowTransferState() public onlyCOO {
        if (allowTransfer) {
            allowTransfer = false;
        } else {
            allowTransfer = true;
        }
    }
    
    modifier whenTransferAllowed() {
        require(allowTransfer);
        _;
    }

     
    function demiseCEO(address newCeo) public onlyCEO {
        require(newCeo != address(0));
        emit OwnershipTransferred(ceo, newCeo);
        ceo = newCeo;
    }

    function setCFO(address newCfo) public onlyCEO {
        require(newCfo != address(0));
        cfo = newCfo;
    }

    function setCOO(address newCoo) public onlyCEO {
        require(newCoo != address(0));
        coo = newCoo;
    }

    function setCAO(address newCao) public onlyCEO {
        require(newCao != address(0));
        cao = newCao;
    }

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyCAO whenNotPaused public {
        paused = true;
        emit Pause();
    }

     
    function unpause() onlyCAO whenPaused public {
        paused = false;
        emit Unpause();
    }
}

contract SkinBase is Manager {

    struct Skin {
        uint128 appearance;
        uint64 cooldownEndTime;
        uint64 mixingWithId;
    }

     
    mapping (uint256 => Skin) skins;

     
    mapping (uint256 => address) public skinIdToOwner;

     
    mapping (uint256 => bool) public isOnSale;

     
    mapping (address => uint256) public accountsToActiveSkin;

     
     
    uint256 public nextSkinId = 1;  

     
    mapping (address => uint256) public numSkinOfAccounts;

    event SkinTransfer(address from, address to, uint256 skinId);
    event SetActiveSkin(address account, uint256 skinId);

     
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

    function withdrawETH() external onlyCAO {
        cfo.transfer(address(this).balance);
    }
    
    function transferP2P(uint256 id, address targetAccount) whenTransferAllowed public {
        require(skinIdToOwner[id] == msg.sender);
        require(msg.sender != targetAccount);
        skinIdToOwner[id] = targetAccount;
        
        numSkinOfAccounts[msg.sender] -= 1;
        numSkinOfAccounts[targetAccount] += 1;
        
         
        emit SkinTransfer(msg.sender, targetAccount, id);
    }

    function _isComplete(uint256 id) internal view returns (bool) {
        uint128 _appearance = skins[id].appearance;
        uint128 mask = uint128(65535);
        uint128 _type = _appearance & mask;
        uint128 maskedValue;
        for (uint256 i = 1; i < 8; i++) {
            mask = mask << 16;
            maskedValue = (_appearance & mask) >> (16*i);
            if (maskedValue != _type) {
                return false;
            }
        } 
        return true;
    }

    function setActiveSkin(uint256 id) public {
        require(skinIdToOwner[id] == msg.sender);
        require(_isComplete(id));
        require(isOnSale[id] == false);
        require(skins[id].mixingWithId == 0);

        accountsToActiveSkin[msg.sender] = id;
        emit SetActiveSkin(msg.sender, id);
    }

    function getActiveSkin(address account) public view returns (uint128) {
        uint256 activeId = accountsToActiveSkin[account];
        if (activeId == 0) {
            return uint128(0);
        }
        return (skins[activeId].appearance & uint128(65535));
    }
}


contract SkinMix is SkinBase {

     
    MixFormulaInterface public mixFormula;


     
    uint256 public prePaidFee = 150000 * 5000000000;  

    bool public enableMix = false;

     
    event MixStart(address account, uint256 skinAId, uint256 skinBId);
    event AutoMix(address account, uint256 skinAId, uint256 skinBId, uint64 cooldownEndTime);
    event MixSuccess(address account, uint256 skinId, uint256 skinAId, uint256 skinBId);

     
    function setMixFormulaAddress(address mixFormulaAddress) external onlyCOO {
        mixFormula = MixFormulaInterface(mixFormulaAddress);
    }

     
    function setPrePaidFee(uint256 newPrePaidFee) external onlyCOO {
        prePaidFee = newPrePaidFee;
    }

    function changeMixEnable(bool newState) external onlyCOO {
        enableMix = newState;
    }

     
    function _isCooldownReady(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].cooldownEndTime <= uint64(now)) && (skins[skinBId].cooldownEndTime <= uint64(now));
    }

     
    function _isNotMixing(uint256 skinAId, uint256 skinBId) private view returns (bool) {
        return (skins[skinAId].mixingWithId == 0) && (skins[skinBId].mixingWithId == 0);
    }

     
    function _setCooldownEndTime(uint256 skinAId, uint256 skinBId) private {
        uint256 end = now + 20 minutes;
         
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
        if (accountsToActiveSkin[account] == skinAId || accountsToActiveSkin[account] == skinBId) {
            return false;
        }
        return (skinIdToOwner[skinAId] == account) && (skinIdToOwner[skinBId] == account);
    }

     
    function _isNotOnSale(uint256 skinId) private view returns (bool) {
        return (isOnSale[skinId] == false);
    }

     
    function mix(uint256 skinAId, uint256 skinBId) public whenNotPaused {

        require(enableMix == true);
         
        require(_isValidSkin(msg.sender, skinAId, skinBId));

         
        require(_isNotOnSale(skinAId) && _isNotOnSale(skinBId));

         
        require(_isCooldownReady(skinAId, skinBId));

         
        require(_isNotMixing(skinAId, skinBId));

         
        _setCooldownEndTime(skinAId, skinBId);

         
        skins[skinAId].mixingWithId = uint64(skinBId);
        skins[skinBId].mixingWithId = uint64(skinAId);

         
        emit MixStart(msg.sender, skinAId, skinBId);
    }

     
    function mixAuto(uint256 skinAId, uint256 skinBId) public payable whenNotPaused {
        require(msg.value >= prePaidFee);

        mix(skinAId, skinBId);

        Skin storage skin = skins[skinAId];

        emit AutoMix(msg.sender, skinAId, skinBId, skin.cooldownEndTime);
    }

     
    function getMixingResult(uint256 skinAId, uint256 skinBId) public whenNotPaused {
         
        address account = skinIdToOwner[skinAId];
        require(account == skinIdToOwner[skinBId]);

         
        Skin storage skinA = skins[skinAId];
        Skin storage skinB = skins[skinBId];
        require(skinA.mixingWithId == uint64(skinBId));
        require(skinB.mixingWithId == uint64(skinAId));

         
        require(_isCooldownReady(skinAId, skinBId));

         
        uint128 newSkinAppearance = mixFormula.calcNewSkinAppearance(skinA.appearance, skinB.appearance, getActiveSkin(account));
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

        emit MixSuccess(account, nextSkinId - 1, skinAId, skinBId);
    }
}


contract MixFormulaInterface {
    function calcNewSkinAppearance(uint128 x, uint128 y, uint128 addition) public returns (uint128);

     
    function randomSkinAppearance(uint256 externalNum, uint128 addition) public returns (uint128);

     
    function bleachAppearance(uint128 appearance, uint128 attributes) public returns (uint128);

     
    function recycleAppearance(uint128[5] appearances, uint256 preference, uint128 addition) public returns (uint128);

     
    function summon10SkinAppearance(uint256 externalNum, uint128 addition) public returns (uint128);
}


contract SkinMarket is SkinMix {

     
     
    uint128 public trCut = 400;

     
    mapping (uint256 => uint256) public desiredPrice;

     
    event PutOnSale(address account, uint256 skinId);
    event WithdrawSale(address account, uint256 skinId);
    event BuyInMarket(address buyer, uint256 skinId);

     

    function setTrCut(uint256 newCut) external onlyCOO {
        trCut = uint128(newCut);
    }

     
    function putOnSale(uint256 skinId, uint256 price) public whenNotPaused {
         
        require(skinIdToOwner[skinId] == msg.sender);
        require(accountsToActiveSkin[msg.sender] != skinId);

         
        require(skins[skinId].mixingWithId == 0);

         
        require(isOnSale[skinId] == false);

        require(price > 0); 

         
        desiredPrice[skinId] = price;
        isOnSale[skinId] = true;

         
        emit PutOnSale(msg.sender, skinId);
    }
  
     
    function withdrawSale(uint256 skinId) external whenNotPaused {
         
        require(isOnSale[skinId] == true);
        
         
        require(skinIdToOwner[skinId] == msg.sender);

         
        isOnSale[skinId] = false;
        desiredPrice[skinId] = 0;

         
        emit WithdrawSale(msg.sender, skinId);
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

         
        emit BuyInMarket(msg.sender, skinId);
    }

     
    function _computeCut(uint256 _price) internal view returns (uint256) {
        return _price / 10000 * trCut;
    }
}


contract SkinMinting is SkinMarket {

     
    uint256 public skinCreatedLimit = 50000;
    uint256 public skinCreatedNum;

     
    mapping (address => uint256) public accountToSummonNum;
    mapping (address => uint256) public accountToBleachNum;

     
    mapping (address => uint256) public accountToPayLevel;
    mapping (address => uint256) public accountLastClearTime;
    mapping (address => uint256) public bleachLastClearTime;

     
    mapping (address => uint256) public freeBleachNum;
    bool isBleachAllowed = false;
    bool isRecycleAllowed = false;

    uint256 public levelClearTime = now;

     
    uint256 public bleachDailyLimit = 3;
    uint256 public baseSummonPrice = 1 finney;
    uint256 public bleachPrice = 100 ether;   

     
    uint256[5] public levelSplits = [10,
                                     20,
                                     50,
                                     100,
                                     200];

    uint256[6] public payMultiple = [10,
                                     12,
                                     15,
                                     20,
                                     30,
                                     40];


     
    event CreateNewSkin(uint256 skinId, address account);
    event Bleach(uint256 skinId, uint128 newAppearance);
    event Recycle(uint256 skinId0, uint256 skinId1, uint256 skinId2, uint256 skinId3, uint256 skinId4, uint256 newSkinId);

     

     
    function setBaseSummonPrice(uint256 newPrice) external onlyCOO {
        baseSummonPrice = newPrice;
    }

    function setBleachPrice(uint256 newPrice) external onlyCOO {
        bleachPrice = newPrice;
    }

    function setBleachDailyLimit(uint256 limit) external onlyCOO {
        bleachDailyLimit = limit;
    }

    function switchBleachAllowed(bool newBleachAllowed) external onlyCOO {
        isBleachAllowed = newBleachAllowed;
    }

    function switchRecycleAllowed(bool newRecycleAllowed) external onlyCOO {
        isRecycleAllowed = newRecycleAllowed;
    }

     
    function createSkin(uint128 specifiedAppearance, uint256 salePrice) external onlyCOO {
        require(skinCreatedNum < skinCreatedLimit);

         
         
        Skin memory newSkin = Skin({appearance: specifiedAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = coo;
        isOnSale[nextSkinId] = false;

         
        emit CreateNewSkin(nextSkinId, coo);

         
        putOnSale(nextSkinId, salePrice);

        nextSkinId++;
        numSkinOfAccounts[coo] += 1;
        skinCreatedNum += 1;
    }

     
    function donateSkin(uint128 specifiedAppearance, address donee) external whenNotPaused onlyCOO {
        Skin memory newSkin = Skin({appearance: specifiedAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = donee;
        isOnSale[nextSkinId] = false;

         
        emit CreateNewSkin(nextSkinId, donee);

        nextSkinId++;
        numSkinOfAccounts[donee] += 1;
        skinCreatedNum += 1;
    }

     
    function moveData(uint128[] legacyAppearance, address[] legacyOwner, bool[] legacyIsOnSale, uint256[] legacyDesiredPrice) external onlyCOO {
        Skin memory newSkin = Skin({appearance: 0, cooldownEndTime: 0, mixingWithId: 0});
        for (uint256 i = 0; i < legacyOwner.length; i++) {
            newSkin.appearance = legacyAppearance[i];
            newSkin.cooldownEndTime = uint64(now);
            newSkin.mixingWithId = 0;

            skins[nextSkinId] = newSkin;
            skinIdToOwner[nextSkinId] = legacyOwner[i];
            isOnSale[nextSkinId] = legacyIsOnSale[i];
            desiredPrice[nextSkinId] = legacyDesiredPrice[i];

             
            emit CreateNewSkin(nextSkinId, legacyOwner[i]);

            nextSkinId++;
            numSkinOfAccounts[legacyOwner[i]] += 1;
            if (numSkinOfAccounts[legacyOwner[i]] > freeBleachNum[legacyOwner[i]]*10 || freeBleachNum[legacyOwner[i]] == 0) {
                freeBleachNum[legacyOwner[i]] += 1;
            }
            skinCreatedNum += 1;
        }
    }

     
    function summon() external payable whenNotPaused {
         
        if (accountLastClearTime[msg.sender] == uint256(0)) {
             
            accountLastClearTime[msg.sender] = now;
        } else {
            if (accountLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accountToSummonNum[msg.sender] = 0;
                accountToPayLevel[msg.sender] = 0;
                accountLastClearTime[msg.sender] = now;
            }
        }

        uint256 payLevel = accountToPayLevel[msg.sender];
        uint256 price = payMultiple[payLevel] * baseSummonPrice;
        require(msg.value >= price);

         
        uint128 randomAppearance = mixFormula.randomSkinAppearance(nextSkinId, getActiveSkin(msg.sender));
         
        Skin memory newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;

         
        emit CreateNewSkin(nextSkinId, msg.sender);

        nextSkinId++;
        numSkinOfAccounts[msg.sender] += 1;

        accountToSummonNum[msg.sender] += 1;

         
        if (payLevel < 5) {
            if (accountToSummonNum[msg.sender] >= levelSplits[payLevel]) {
                accountToPayLevel[msg.sender] = payLevel + 1;
            }
        }
    }

     
    function summon10() external payable whenNotPaused {
         
        if (accountLastClearTime[msg.sender] == uint256(0)) {
             
            accountLastClearTime[msg.sender] = now;
        } else {
            if (accountLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accountToSummonNum[msg.sender] = 0;
                accountToPayLevel[msg.sender] = 0;
                accountLastClearTime[msg.sender] = now;
            }
        }

        uint256 payLevel = accountToPayLevel[msg.sender];
        uint256 price = payMultiple[payLevel] * baseSummonPrice;
        require(msg.value >= price*10);

        Skin memory newSkin;
        uint128 randomAppearance;
         
        for (uint256 i = 0; i < 10; i++) {
            randomAppearance = mixFormula.randomSkinAppearance(nextSkinId, getActiveSkin(msg.sender));
            newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
            skins[nextSkinId] = newSkin;
            skinIdToOwner[nextSkinId] = msg.sender;
            isOnSale[nextSkinId] = false;
             
            emit CreateNewSkin(nextSkinId, msg.sender);
            nextSkinId++;
        }

         
        randomAppearance = mixFormula.summon10SkinAppearance(nextSkinId, getActiveSkin(msg.sender));
        newSkin = Skin({appearance: randomAppearance, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;
         
        emit CreateNewSkin(nextSkinId, msg.sender);
        nextSkinId++;

        numSkinOfAccounts[msg.sender] += 11;
        accountToSummonNum[msg.sender] += 10;

         
        if (payLevel < 5) {
            if (accountToSummonNum[msg.sender] >= levelSplits[payLevel]) {
                accountToPayLevel[msg.sender] = payLevel + 1;
            }
        }
    }

     
    function recycleSkin(uint256[5] wasteSkins, uint256 preferIndex) external whenNotPaused {
        require(isRecycleAllowed == true);
        for (uint256 i = 0; i < 5; i++) {
            require(skinIdToOwner[wasteSkins[i]] == msg.sender);
            skinIdToOwner[wasteSkins[i]] = address(0);
        }

        uint128[5] memory apps;
        for (i = 0; i < 5; i++) {
            apps[i] = skins[wasteSkins[i]].appearance;
        }
         
        uint128 recycleApp = mixFormula.recycleAppearance(apps, preferIndex, getActiveSkin(msg.sender));
        Skin memory newSkin = Skin({appearance: recycleApp, cooldownEndTime: uint64(now), mixingWithId: 0});
        skins[nextSkinId] = newSkin;
        skinIdToOwner[nextSkinId] = msg.sender;
        isOnSale[nextSkinId] = false;

         
        emit Recycle(wasteSkins[0], wasteSkins[1], wasteSkins[2], wasteSkins[3], wasteSkins[4], nextSkinId);

        nextSkinId++;
        numSkinOfAccounts[msg.sender] -= 4;
    }

     
    function bleach(uint128 skinId, uint128 attributes) external payable whenNotPaused {
        require(isBleachAllowed);

         
        if (bleachLastClearTime[msg.sender] == uint256(0)) {
             
            bleachLastClearTime[msg.sender] = now;
        } else {
            if (bleachLastClearTime[msg.sender] < levelClearTime && now > levelClearTime) {
                accountToBleachNum[msg.sender] = 0;
                bleachLastClearTime[msg.sender] = now;
            }
        }

        require(accountToBleachNum[msg.sender] < bleachDailyLimit);
        accountToBleachNum[msg.sender] += 1;

         
        require(msg.sender == skinIdToOwner[skinId]);

         
        require(isOnSale[skinId] == false);

        uint256 bleachNum = 0;
        for (uint256 i = 0; i < 8; i++) {
            if ((attributes & (uint128(1) << i)) > 0) {
                if (freeBleachNum[msg.sender] > 0) {
                    freeBleachNum[msg.sender]--;
                } else {
                    bleachNum++;
                }
            }
        }
         
        require(msg.value >= bleachNum * bleachPrice);

        Skin storage originSkin = skins[skinId];
         
        require(originSkin.mixingWithId == 0);

        uint128 newAppearance = mixFormula.bleachAppearance(originSkin.appearance, attributes);
        originSkin.appearance = newAppearance;

         
        emit Bleach(skinId, newAppearance);
    }

     
    function clearSummonNum() external onlyCOO {
        uint256 nextDay = levelClearTime + 1 days;
        if (now > nextDay) {
            levelClearTime = nextDay;
        }
    }
}