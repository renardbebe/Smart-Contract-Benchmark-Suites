 

pragma solidity ^0.4.21;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address previousOwner, address newOwner);

    function Ownable() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract StorageBase is Ownable {

    function withdrawBalance() external onlyOwner returns (bool) {
         
         
        bool res = msg.sender.send(address(this).balance);
        return res;
    }
}

 
contract ActivityStorage is StorageBase {

    struct Activity {
         
        bool isPause;
         
        uint16 buyLimit;
         
        uint128 packPrice;
         
        uint64 startDate;
         
        uint64 endDate;
         
        mapping(uint16 => address) soldPackToAddress;
         
        mapping(address => uint16) addressBoughtCount;
    }

     
    mapping(uint16 => Activity) public activities;

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
    {
         
        require(activities[_activityId].buyLimit == 0);

        activities[_activityId] = Activity({
            isPause: false,
            buyLimit: _buyLimit,
            packPrice: _packPrice,
            startDate: _startDate,
            endDate: _endDate
        });
    }

    function sellPackToAddress(
        uint16 _activityId, 
        uint16 _packId, 
        address buyer
    ) 
        external 
        onlyOwner
    {
        Activity storage activity = activities[_activityId];
        activity.soldPackToAddress[_packId] = buyer;
        activity.addressBoughtCount[buyer]++;
    }

    function pauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = true;
    }

    function unpauseActivity(uint16 _activityId) external onlyOwner {
        activities[_activityId].isPause = false;
    }

    function deleteActivity(uint16 _activityId) external onlyOwner {
        delete activities[_activityId];
    }

    function getAddressBoughtCount(uint16 _activityId, address buyer) external view returns (uint16) {
        return activities[_activityId].addressBoughtCount[buyer];
    }

    function getBuyerAddress(uint16 _activityId, uint16 packId) external view returns (address) {
        return activities[_activityId].soldPackToAddress[packId];
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

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract HasNoContracts is Pausable {

    function reclaimContract(address _contractAddr) external onlyOwner whenPaused {
        Ownable contractInst = Ownable(_contractAddr);
        contractInst.transferOwnership(owner);
    }
}

contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
}

contract LogicBase is HasNoContracts {

     
     
     
    bytes4 constant InterfaceSignature_NFC = bytes4(0x9f40b779);

     
    ERC721 public nonFungibleContract;

     
    StorageBase public storageContract;

    function LogicBase(address _nftAddress, address _storageAddress) public {
         
        paused = true;

        setNFTAddress(_nftAddress);

        require(_storageAddress != address(0));
        storageContract = StorageBase(_storageAddress);
    }

     
     
     
    function destroy() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(owner);
    }

     
     
     
    function destroyAndSendToStorageOwner() external onlyOwner whenPaused {
        address storageOwner = storageContract.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(storageOwner);
    }

     
    function unpause() public onlyOwner whenPaused {
         
        require(nonFungibleContract != address(0));
        require(storageContract != address(0));
         
        require(storageContract.owner() == address(this));

        super.unpause();
    }

    function setNFTAddress(address _nftAddress) public onlyOwner {
        require(_nftAddress != address(0));
        ERC721 candidateContract = ERC721(_nftAddress);
        require(candidateContract.supportsInterface(InterfaceSignature_NFC));
        nonFungibleContract = candidateContract;
    }

     
    function withdrawBalance() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
         
        require(msg.sender == owner || msg.sender == nftAddress);
         
         
        bool res = nftAddress.send(address(this).balance);
        return res;
    }

    function withdrawBalanceFromStorageContract() external returns (bool) {
        address nftAddress = address(nonFungibleContract);
         
        require(msg.sender == owner || msg.sender == nftAddress);
         
         
        bool res = storageContract.withdrawBalance();
        return res;
    }
}

contract ActivityCore is LogicBase {

    bool public isActivityCore = true;

    ActivityStorage activityStorage;

    event ActivityCreated(uint16 activityId);
    event ActivityBidSuccess(uint16 activityId, uint16 packId, address winner);

    function ActivityCore(address _nftAddress, address _storageAddress) 
        LogicBase(_nftAddress, _storageAddress) public {
            
        activityStorage = ActivityStorage(_storageAddress);
    }

    function createActivity(
        uint16 _activityId,
        uint16 _buyLimit,
        uint128 _packPrice,
        uint64 _startDate,
        uint64 _endDate
    ) 
        external
        onlyOwner
        whenNotPaused
    {
        activityStorage.createActivity(_activityId, _buyLimit, _packPrice, _startDate, _endDate);

        emit ActivityCreated(_activityId);
    }

     
     
    function deleteActivity(
        uint16 _activityId
    )
        external 
        onlyOwner
        whenPaused
    {
        activityStorage.deleteActivity(_activityId);
    }

    function getActivity(
        uint16 _activityId
    ) 
        external 
        view  
        returns (
            bool isPause,
            uint16 buyLimit,
            uint128 packPrice,
            uint64 startDate,
            uint64 endDate
        )
    {
        return activityStorage.activities(_activityId);
    }
    
    function bid(uint16 _activityId, uint16 _packId)
        external
        payable
        whenNotPaused
    {
        bool isPause;
        uint16 buyLimit;
        uint128 packPrice;
        uint64 startDate;
        uint64 endDate;
        (isPause, buyLimit, packPrice, startDate, endDate) = activityStorage.activities(_activityId);
         
        require(!isPause);
         
        require(buyLimit > 0);
         
        require(msg.value >= packPrice);
         
        require(now >= startDate && now <= endDate);
         
        require(activityStorage.getBuyerAddress(_activityId, _packId) == address(0));
         
        require(activityStorage.getAddressBoughtCount(_activityId, msg.sender) < buyLimit);
         
        activityStorage.sellPackToAddress(_activityId, _packId, msg.sender);
         
        emit ActivityBidSuccess(_activityId, _packId, msg.sender);
    }
}

contract CryptoStorage is StorageBase {

    struct Monster {
        uint32 matronId;
        uint32 sireId;
        uint32 siringWithId;
        uint16 cooldownIndex;
        uint16 generation;
        uint64 cooldownEndBlock;
        uint64 birthTime;
        uint16 monsterId;
        uint32 monsterNum;
        bytes properties;
    }

     
    Monster[] internal monsters;

     
    uint256 public promoCreatedCount;

     
    uint256 public systemCreatedCount;

     
    uint256 public pregnantMonsters;
    
     
    mapping (uint256 => uint32) public monsterCurrentNumber;
    
     
    mapping (uint256 => address) public monsterIndexToOwner;

     
    mapping (address => uint256) public ownershipTokenCount;

     
    mapping (uint256 => address) public monsterIndexToApproved;

    function CryptoStorage() public {
         
        createMonster(0, 0, 0, 0, 0, "");
    }

    function createMonster(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _birthTime,
        uint256 _monsterId,
        bytes _properties
    ) 
        public 
        onlyOwner
        returns (uint256)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));
        require(_birthTime == uint256(uint64(_birthTime)));
        require(_monsterId == uint256(uint16(_monsterId)));

        monsterCurrentNumber[_monsterId]++;

        Monster memory monster = Monster({
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: 0,
            cooldownIndex: 0,
            generation: uint16(_generation),
            cooldownEndBlock: 0,
            birthTime: uint64(_birthTime),
            monsterId: uint16(_monsterId),
            monsterNum: monsterCurrentNumber[_monsterId],
            properties: _properties
        });
        uint256 tokenId = monsters.push(monster) - 1;

         
        require(tokenId == uint256(uint32(tokenId)));

        return tokenId;
    }

    function getMonster(uint256 _tokenId)
        external
        view
        returns (
            bool isGestating,
            bool isReady,
            uint16 cooldownIndex,
            uint64 nextActionAt,
            uint32 siringWithId,
            uint32 matronId,
            uint32 sireId,
            uint64 cooldownEndBlock,
            uint16 generation,
            uint64 birthTime,
            uint32 monsterNum,
            uint16 monsterId,
            bytes properties
        ) 
    {
        Monster storage monster = monsters[_tokenId];

        isGestating = (monster.siringWithId != 0);
        isReady = (monster.cooldownEndBlock <= block.number);
        cooldownIndex = monster.cooldownIndex;
        nextActionAt = monster.cooldownEndBlock;
        siringWithId = monster.siringWithId;
        matronId = monster.matronId;
        sireId = monster.sireId;
        cooldownEndBlock = monster.cooldownEndBlock;
        generation = monster.generation;
        birthTime = monster.birthTime;
        monsterNum = monster.monsterNum;
        monsterId = monster.monsterId;
        properties = monster.properties;
    }

    function getMonsterCount() external view returns (uint256) {
        return monsters.length - 1;
    }

    function getMatronId(uint256 _tokenId) external view returns (uint32) {
        return monsters[_tokenId].matronId;
    }

    function getSireId(uint256 _tokenId) external view returns (uint32) {
        return monsters[_tokenId].sireId;
    }

    function getSiringWithId(uint256 _tokenId) external view returns (uint32) {
        return monsters[_tokenId].siringWithId;
    }
    
    function setSiringWithId(uint256 _tokenId, uint32 _siringWithId) external onlyOwner {
        monsters[_tokenId].siringWithId = _siringWithId;
    }

    function deleteSiringWithId(uint256 _tokenId) external onlyOwner {
        delete monsters[_tokenId].siringWithId;
    }

    function getCooldownIndex(uint256 _tokenId) external view returns (uint16) {
        return monsters[_tokenId].cooldownIndex;
    }

    function setCooldownIndex(uint256 _tokenId) external onlyOwner {
        monsters[_tokenId].cooldownIndex += 1;
    }

    function getGeneration(uint256 _tokenId) external view returns (uint16) {
        return monsters[_tokenId].generation;
    }

    function getCooldownEndBlock(uint256 _tokenId) external view returns (uint64) {
        return monsters[_tokenId].cooldownEndBlock;
    }

    function setCooldownEndBlock(uint256 _tokenId, uint64 _cooldownEndBlock) external onlyOwner {
        monsters[_tokenId].cooldownEndBlock = _cooldownEndBlock;
    }

    function getBirthTime(uint256 _tokenId) external view returns (uint64) {
        return monsters[_tokenId].birthTime;
    }

    function getMonsterId(uint256 _tokenId) external view returns (uint16) {
        return monsters[_tokenId].monsterId;
    }

    function getMonsterNum(uint256 _tokenId) external view returns (uint32) {
        return monsters[_tokenId].monsterNum;
    }

    function getProperties(uint256 _tokenId) external view returns (bytes) {
        return monsters[_tokenId].properties;
    }

    function updateProperties(uint256 _tokenId, bytes _properties) external onlyOwner {
        monsters[_tokenId].properties = _properties;
    }
    
    function setMonsterIndexToOwner(uint256 _tokenId, address _owner) external onlyOwner {
        monsterIndexToOwner[_tokenId] = _owner;
    }

    function increaseOwnershipTokenCount(address _owner) external onlyOwner {
        ownershipTokenCount[_owner]++;
    }

    function decreaseOwnershipTokenCount(address _owner) external onlyOwner {
        ownershipTokenCount[_owner]--;
    }

    function setMonsterIndexToApproved(uint256 _tokenId, address _approved) external onlyOwner {
        monsterIndexToApproved[_tokenId] = _approved;
    }
    
    function deleteMonsterIndexToApproved(uint256 _tokenId) external onlyOwner {
        delete monsterIndexToApproved[_tokenId];
    }

    function increasePromoCreatedCount() external onlyOwner {
        promoCreatedCount++;
    }

    function increaseSystemCreatedCount() external onlyOwner {
        systemCreatedCount++;
    }

    function increasePregnantCounter() external onlyOwner {
        pregnantMonsters++;
    }

    function decreasePregnantCounter() external onlyOwner {
        pregnantMonsters--;
    }
}

contract ClockAuctionStorage is StorageBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    mapping (uint256 => Auction) tokenIdToAuction;

    function addAuction(
        uint256 _tokenId,
        address _seller,
        uint128 _startingPrice,
        uint128 _endingPrice,
        uint64 _duration,
        uint64 _startedAt
    )
        external
        onlyOwner
    {
        tokenIdToAuction[_tokenId] = Auction(
            _seller,
            _startingPrice,
            _endingPrice,
            _duration,
            _startedAt
        );
    }

    function removeAuction(uint256 _tokenId) public onlyOwner {
        delete tokenIdToAuction[_tokenId];
    }

    function getAuction(uint256 _tokenId)
        external
        view
        returns (
            address seller,
            uint128 startingPrice,
            uint128 endingPrice,
            uint64 duration,
            uint64 startedAt
        )
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        return (
            auction.seller,
            auction.startingPrice,
            auction.endingPrice,
            auction.duration,
            auction.startedAt
        );
    }

    function isOnAuction(uint256 _tokenId) external view returns (bool) {
        return (tokenIdToAuction[_tokenId].startedAt > 0);
    }

    function getSeller(uint256 _tokenId) external view returns (address) {
        return tokenIdToAuction[_tokenId].seller;
    }

    function transfer(ERC721 _nonFungibleContract, address _receiver, uint256 _tokenId) external onlyOwner {
         
        _nonFungibleContract.transfer(_receiver, _tokenId);
    }
}

contract SaleClockAuctionStorage is ClockAuctionStorage {
    bool public isSaleClockAuctionStorage = true;

     
    uint256 public totalSoldCount;

     
    uint256[3] public lastSoldPrices;

     
    uint256 public systemOnSaleCount;

     
    mapping (uint256 => bool) systemOnSaleTokens;

    function removeAuction(uint256 _tokenId) public onlyOwner {
         
        super.removeAuction(_tokenId);

         
        if (systemOnSaleTokens[_tokenId]) {
            delete systemOnSaleTokens[_tokenId];
            
            if (systemOnSaleCount > 0) {
                systemOnSaleCount--;
            }
        }
    }

    function recordSystemOnSaleToken(uint256 _tokenId) external onlyOwner {
        if (!systemOnSaleTokens[_tokenId]) {
            systemOnSaleTokens[_tokenId] = true;
            systemOnSaleCount++;
        }
    }

    function recordSoldPrice(uint256 _price) external onlyOwner {
        lastSoldPrices[totalSoldCount % 3] = _price;
        totalSoldCount++;
    }

    function averageSoldPrice() external view returns (uint256) {
        if (totalSoldCount == 0) return 0;
        
        uint256 sum = 0;
        uint256 len = (totalSoldCount < 3 ? totalSoldCount : 3);
        for (uint256 i = 0; i < len; i++) {
            sum += lastSoldPrices[i];
        }
        return sum / len;
    }
}

contract ClockAuction is LogicBase {
    
     
    ClockAuctionStorage public clockAuctionStorage;

     
     
    uint256 public ownerCut;

     
    uint256 public minCutValue;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner, address seller, uint256 sellerProceeds);
    event AuctionCancelled(uint256 tokenId);

    function ClockAuction(address _nftAddress, address _storageAddress, uint256 _cut, uint256 _minCutValue) 
        LogicBase(_nftAddress, _storageAddress) public
    {
        setOwnerCut(_cut);
        setMinCutValue(_minCutValue);

        clockAuctionStorage = ClockAuctionStorage(_storageAddress);
    }

    function setOwnerCut(uint256 _cut) public onlyOwner {
        require(_cut <= 10000);
        ownerCut = _cut;
    }

    function setMinCutValue(uint256 _minCutValue) public onlyOwner {
        minCutValue = _minCutValue;
    }

    function getMinPrice() public view returns (uint256) {
         
         
        return minCutValue;
    }

     
     
    function isValidPrice(uint256 _startingPrice, uint256 _endingPrice) public view returns (bool) {
        return (_startingPrice < _endingPrice ? _startingPrice : _endingPrice) >= getMinPrice();
    }

    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
        public
        whenNotPaused
    {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

        require(msg.sender == address(nonFungibleContract));
        
         
         
        nonFungibleContract.transferFrom(_seller, address(clockAuctionStorage), _tokenId);

         
        require(_duration >= 1 minutes);

        clockAuctionStorage.addAuction(
            _tokenId,
            _seller,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        emit AuctionCreated(_tokenId, _startingPrice, _endingPrice, _duration);
    }

    function cancelAuction(uint256 _tokenId) external {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        address seller = clockAuctionStorage.getSeller(_tokenId);
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

    function cancelAuctionWhenPaused(uint256 _tokenId) external whenPaused onlyOwner {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        address seller = clockAuctionStorage.getSeller(_tokenId);
        _cancelAuction(_tokenId, seller);
    }

    function getAuction(uint256 _tokenId)
        public
        view
        returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        return clockAuctionStorage.getAuction(_tokenId);
    }

    function getCurrentPrice(uint256 _tokenId)
        external
        view
        returns (uint256)
    {
        require(clockAuctionStorage.isOnAuction(_tokenId));
        return _currentPrice(_tokenId);
    }

    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        clockAuctionStorage.removeAuction(_tokenId);
        clockAuctionStorage.transfer(nonFungibleContract, _seller, _tokenId);
        emit AuctionCancelled(_tokenId);
    }

    function _bid(uint256 _tokenId, uint256 _bidAmount, address bidder) internal returns (uint256) {

        require(clockAuctionStorage.isOnAuction(_tokenId));

         
        uint256 price = _currentPrice(_tokenId);
        require(_bidAmount >= price);

        address seller = clockAuctionStorage.getSeller(_tokenId);
        uint256 sellerProceeds = 0;

         
        clockAuctionStorage.removeAuction(_tokenId);

         
        if (price > 0) {
             
            uint256 auctioneerCut = _computeCut(price);
            sellerProceeds = price - auctioneerCut;

             
            seller.transfer(sellerProceeds);
        }

         
         
         
        uint256 bidExcess = _bidAmount - price;
        bidder.transfer(bidExcess);

        emit AuctionSuccessful(_tokenId, price, bidder, seller, sellerProceeds);

        return price;
    }

    function _currentPrice(uint256 _tokenId) internal view returns (uint256) {

        uint256 secondsPassed = 0;

        address seller;
        uint128 startingPrice;
        uint128 endingPrice;
        uint64 duration;
        uint64 startedAt;
        (seller, startingPrice, endingPrice, duration, startedAt) = clockAuctionStorage.getAuction(_tokenId);

        if (now > startedAt) {
            secondsPassed = now - startedAt;
        }

        return _computeCurrentPrice(
            startingPrice,
            endingPrice,
            duration,
            secondsPassed
        );
    }

    function _computeCurrentPrice(
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        uint256 _secondsPassed
    )
        internal
        pure
        returns (uint256)
    {
        if (_secondsPassed >= _duration) {
            return _endingPrice;
        } else {
             
            int256 totalPriceChange = int256(_endingPrice) - int256(_startingPrice);

             
             
             
            int256 currentPriceChange = totalPriceChange * int256(_secondsPassed) / int256(_duration);

             
            int256 currentPrice = int256(_startingPrice) + currentPriceChange;

            return uint256(currentPrice);
        }
    }

    function _computeCut(uint256 _price) internal view returns (uint256) {
        uint256 cutValue = _price * ownerCut / 10000;
        if (_price < minCutValue) return cutValue;
        if (cutValue > minCutValue) return cutValue;
        return minCutValue;
    }
}

contract SaleClockAuction is ClockAuction {

    bool public isSaleClockAuction = true;

    address public systemSaleAddress;
    uint256 public systemStartingPriceMin = 20 finney;
    uint256 public systemEndingPrice = 0;
    uint256 public systemAuctionDuration = 1 days;

    function SaleClockAuction(address _nftAddr, address _storageAddress, address _systemSaleAddress, uint256 _cut, uint256 _minCutValue) 
        ClockAuction(_nftAddr, _storageAddress, _cut, _minCutValue) public
    {
        require(SaleClockAuctionStorage(_storageAddress).isSaleClockAuctionStorage());
        
        setSystemSaleAddress(_systemSaleAddress);
    }
  
    function bid(uint256 _tokenId) external payable {
        uint256 price = _bid(_tokenId, msg.value, msg.sender);
        
        clockAuctionStorage.transfer(nonFungibleContract, msg.sender, _tokenId);
        
        SaleClockAuctionStorage(clockAuctionStorage).recordSoldPrice(price);
    }

    function createSystemAuction(uint256 _tokenId) external {
        require(msg.sender == address(nonFungibleContract));

        createAuction(
            _tokenId,
            computeNextSystemSalePrice(),
            systemEndingPrice,
            systemAuctionDuration,
            systemSaleAddress
        );

        SaleClockAuctionStorage(clockAuctionStorage).recordSystemOnSaleToken(_tokenId);
    }

    function setSystemSaleAddress(address _systemSaleAddress) public onlyOwner {
        require(_systemSaleAddress != address(0));
        systemSaleAddress = _systemSaleAddress;
    }

    function setSystemStartingPriceMin(uint256 _startingPrice) external onlyOwner {
        require(_startingPrice == uint256(uint128(_startingPrice)));
        systemStartingPriceMin = _startingPrice;
    }

    function setSystemEndingPrice(uint256 _endingPrice) external onlyOwner {
        require(_endingPrice == uint256(uint128(_endingPrice)));
        systemEndingPrice = _endingPrice;
    }

    function setSystemAuctionDuration(uint256 _duration) external onlyOwner {
        require(_duration == uint256(uint64(_duration)));
        systemAuctionDuration = _duration;
    }

    function totalSoldCount() external view returns (uint256) {
        return SaleClockAuctionStorage(clockAuctionStorage).totalSoldCount();
    }

    function systemOnSaleCount() external view returns (uint256) {
        return SaleClockAuctionStorage(clockAuctionStorage).systemOnSaleCount();
    }

    function averageSoldPrice() external view returns (uint256) {
        return SaleClockAuctionStorage(clockAuctionStorage).averageSoldPrice();
    }

    function computeNextSystemSalePrice() public view returns (uint256) {
        uint256 avePrice = SaleClockAuctionStorage(clockAuctionStorage).averageSoldPrice();

        require(avePrice == uint256(uint128(avePrice)));

        uint256 nextPrice = avePrice + (avePrice / 2);

        if (nextPrice < systemStartingPriceMin) {
            nextPrice = systemStartingPriceMin;
        }

        return nextPrice;
    }
}

contract SiringClockAuctionStorage is ClockAuctionStorage {
    bool public isSiringClockAuctionStorage = true;
}

contract SiringClockAuction is ClockAuction {

    bool public isSiringClockAuction = true;

    function SiringClockAuction(address _nftAddr, address _storageAddress, uint256 _cut, uint256 _minCutValue) 
        ClockAuction(_nftAddr, _storageAddress, _cut, _minCutValue) public
    {
        require(SiringClockAuctionStorage(_storageAddress).isSiringClockAuctionStorage());
    }

    function bid(uint256 _tokenId, address bidder) external payable {
         
        require(msg.sender == address(nonFungibleContract));
         
        address seller = clockAuctionStorage.getSeller(_tokenId);
         
        _bid(_tokenId, msg.value, bidder);
         
        clockAuctionStorage.transfer(nonFungibleContract, seller, _tokenId);
    }
}

contract ZooAccessControl is HasNoContracts {

    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    function setCFO(address _newCFO) public onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }
    
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
}

contract Zoo721 is ZooAccessControl, ERC721 {

     
    string public constant name = "Giftomon";
     
    string public constant symbol = "GTOM";

    bytes4 constant InterfaceSignature_ERC165 =
        bytes4(keccak256("supportsInterface(bytes4)"));

    bytes4 constant InterfaceSignature_ERC721 =
        bytes4(keccak256('name()')) ^
        bytes4(keccak256('symbol()')) ^
        bytes4(keccak256('totalSupply()')) ^
        bytes4(keccak256('balanceOf(address)')) ^
        bytes4(keccak256('ownerOf(uint256)')) ^
        bytes4(keccak256('approve(address,uint256)')) ^
        bytes4(keccak256('transfer(address,uint256)')) ^
        bytes4(keccak256('transferFrom(address,address,uint256)')) ^
        bytes4(keccak256('tokensOfOwner(address)'));

    CryptoStorage public cryptoStorage;

    function Zoo721(address _storageAddress) public {
        require(_storageAddress != address(0));
        cryptoStorage = CryptoStorage(_storageAddress);
    }

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
    function totalSupply() public view returns (uint) {
        return cryptoStorage.getMonsterCount();
    }
    
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return cryptoStorage.ownershipTokenCount(_owner);
    }

     
    function ownerOf(uint256 _tokenId) external view returns (address owner) {
        owner = cryptoStorage.monsterIndexToOwner(_tokenId);
        require(owner != address(0));
    }

     
    function approve(address _to, uint256 _tokenId) external whenNotPaused {
        require(_owns(msg.sender, _tokenId));
        _approve(_tokenId, _to);
        emit Approval(msg.sender, _to, _tokenId);
    }

     
    function transfer(address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_to != address(0));
         
        require(_to != address(this));
         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
    function transferFrom(address _from, address _to, uint256 _tokenId) external whenNotPaused {
         
        require(_to != address(0));
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));
         
        _transfer(_from, _to, _tokenId);
    }

     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalTokens = totalSupply();
            uint256 resultIndex = 0;

            uint256 tokenId;

            for (tokenId = 1; tokenId <= totalTokens; tokenId++) {
                if (cryptoStorage.monsterIndexToOwner(tokenId) == _owner) {
                    result[resultIndex] = tokenId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        cryptoStorage.increaseOwnershipTokenCount(_to);

         
        cryptoStorage.setMonsterIndexToOwner(_tokenId, _to);

         
        if (_from != address(0)) {
             
            cryptoStorage.decreaseOwnershipTokenCount(_from);
             
            cryptoStorage.deleteMonsterIndexToApproved(_tokenId);
        }
        
        emit Transfer(_from, _to, _tokenId);
    }

    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return cryptoStorage.monsterIndexToOwner(_tokenId) == _claimant;
    }

    function _approve(uint256 _tokenId, address _approved) internal {
        cryptoStorage.setMonsterIndexToApproved(_tokenId, _approved);
    }

    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return cryptoStorage.monsterIndexToApproved(_tokenId) == _claimant;
    }
}

contract CryptoZoo is Zoo721 {

    uint256 public constant SYSTEM_CREATION_LIMIT = 10000;

     
    uint256 public autoBirthFee = 2 finney;

     
    uint256 public secondsPerBlock = 15;

     
     
     
    uint32[] public hatchDurationByTimes = [uint32(1 minutes)];

     
     
     
     
    uint32[] public hatchDurationMultiByGeneration = [uint32(60)];

     
    SaleClockAuction public saleAuction;
    
     
    SiringClockAuction public siringAuction;

     
    ActivityCore public activityCore;

     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 matronCooldownEndBlock, uint256 sireCooldownEndBlock, uint256 breedCost);
    event Birth(address owner, uint256 tokenId, uint256 matronId, uint256 sireId);

     
    function CryptoZoo(address _storageAddress, address _cooAddress, address _cfoAddress) Zoo721(_storageAddress) public {
         
        paused = true;
         
        ceoAddress = msg.sender;

        setCOO(_cooAddress);
        setCFO(_cfoAddress);
    }

    function() external payable {
        require(
            msg.sender == address(saleAuction) ||
            msg.sender == address(siringAuction) ||
            msg.sender == address(activityCore) || 
            msg.sender == cooAddress
        );
    }

     
    function pause() public onlyCLevel whenNotPaused {
        super.pause();
    }

     
    function unpause() public onlyCEO whenPaused {
         
        require(ceoAddress != address(0));
        require(cooAddress != address(0));
        require(cfoAddress != address(0));
         
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(activityCore != address(0));
        require(cryptoStorage != address(0));
         
        require(cryptoStorage.owner() == address(this));

        super.unpause();
    }

     
     
     
    function destroy() external onlyCEO whenPaused {
        address storageOwner = cryptoStorage.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(ceoAddress);
    }

     
     
     
    function destroyAndSendToStorageOwner() external onlyCEO whenPaused {
        address storageOwner = cryptoStorage.owner();
         
        require(storageOwner != address(this));
         
        selfdestruct(storageOwner);
    }

    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);
        require(candidateContract.isSaleClockAuction());
        saleAuction = candidateContract;
    }

    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);
        require(candidateContract.isSiringClockAuction());
        siringAuction = candidateContract;
    }

    function setActivityCoreAddress(address _address) external onlyCEO {
        ActivityCore candidateContract = ActivityCore(_address);
        require(candidateContract.isActivityCore());
        activityCore = candidateContract;
    }

    function withdrawBalance() external onlyCLevel {
        uint256 balance = address(this).balance;
         
        uint256 subtractFees = (cryptoStorage.pregnantMonsters() + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.transfer(balance - subtractFees);
        }
    }

    function withdrawBalancesToNFC() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
        activityCore.withdrawBalance();
        cryptoStorage.withdrawBalance();
    }

    function withdrawBalancesToLogic() external onlyCLevel {
        saleAuction.withdrawBalanceFromStorageContract();
        siringAuction.withdrawBalanceFromStorageContract();
        activityCore.withdrawBalanceFromStorageContract();
    }

    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }

    function setAllHatchConfigs(
        uint32[] _durationByTimes,
        uint256 _secs,
        uint32[] _multiByGeneration
    )
        external 
        onlyCLevel 
    {
        setHatchDurationByTimes(_durationByTimes);
        setSecondsPerBlock(_secs);
        setHatchDurationMultiByGeneration(_multiByGeneration);
    }

    function setSecondsPerBlock(uint256 _secs) public onlyCLevel {
        require(_secs < hatchDurationByTimes[0]);
        secondsPerBlock = _secs;
    }

     
    function setHatchDurationByTimes(uint32[] _durationByTimes) public onlyCLevel {
        uint256 len = _durationByTimes.length;
         
        require(len > 0);
         
        require(len == uint256(uint16(len)));
        
        delete hatchDurationByTimes;
        
        uint32 value;
        for (uint256 idx = 0; idx < len; idx++) {
            value = _durationByTimes[idx];
            
             
            require(value >= 1 minutes && value % 1 minutes == 0);
            
            hatchDurationByTimes.push(value);
        }
    }
    
    function getHatchDurationByTimes() external view returns (uint32[]) {
        return hatchDurationByTimes;
    }

     
    function setHatchDurationMultiByGeneration(uint32[] _multiByGeneration) public onlyCLevel {
        uint256 len = _multiByGeneration.length;
         
        require(len > 0);
         
        require(len == uint256(uint16(len)));
        
        delete hatchDurationMultiByGeneration;
        
        uint32 value;
        for (uint256 idx = 0; idx < len; idx++) {
            value = _multiByGeneration[idx];
            
             
            require(value >= 60 && value % secondsPerBlock == 0);
            
            hatchDurationMultiByGeneration.push(value);
        }
    }

    function getHatchDurationMultiByGeneration() external view returns (uint32[]) {
        return hatchDurationMultiByGeneration;
    }

    function createPromoMonster(
        uint32 _monsterId, 
        bytes _properties, 
        address _owner
    )
        public 
        onlyCOO 
        whenNotPaused 
    {
        require(_owner != address(0));

        _createMonster(
            0, 
            0, 
            0, 
            uint64(now), 
            _monsterId, 
            _properties, 
            _owner
        );

        cryptoStorage.increasePromoCreatedCount();
    }

    function createPromoMonsterWithTokenId(
        uint32 _monsterId, 
        bytes _properties, 
        address _owner, 
        uint256 _tokenId
    ) 
        external 
        onlyCOO 
        whenNotPaused 
    {
        require(_tokenId > 0 && cryptoStorage.getMonsterCount() + 1 == _tokenId);
        
        createPromoMonster(_monsterId, _properties, _owner);
    }

    function createSystemSaleAuction(
        uint32 _monsterId, 
        bytes _properties, 
        uint16 _generation
    )
        external 
        onlyCOO
        whenNotPaused
    {
        require(cryptoStorage.systemCreatedCount() < SYSTEM_CREATION_LIMIT);

        uint256 tokenId = _createMonster(
            0, 
            0, 
            _generation, 
            uint64(now), 
            _monsterId, 
            _properties, 
            saleAuction.systemSaleAddress()
        );

        _approve(tokenId, saleAuction);

        saleAuction.createSystemAuction(tokenId);

        cryptoStorage.increaseSystemCreatedCount();
    }

    function createSaleAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_tokenId > 0);
        require(_owns(msg.sender, _tokenId));
         
        require(!isPregnant(_tokenId));
        require(saleAuction.isValidPrice(_startingPrice, _endingPrice));
        _approve(_tokenId, saleAuction);
         
        saleAuction.createAuction(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function createSiringAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
        require(_tokenId > 0);
        require(_owns(msg.sender, _tokenId));
        require(isReadyToBreed(_tokenId));
        require(siringAuction.isValidPrice(_startingPrice, _endingPrice));
        _approve(_tokenId, siringAuction);
         
        siringAuction.createAuction(
            _tokenId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

     
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
        require(_matronId > 0);
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(isValidMatingPair(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        uint256 breedCost = currentPrice + autoBirthFee;
        require(msg.value >= breedCost);

         
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId, msg.sender);
        _breedWith(_matronId, _sireId, breedCost);
    }

     
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {
         
        require(msg.value >= autoBirthFee);

         
        require(_owns(msg.sender, _matronId));
        require(_owns(msg.sender, _sireId));

         
         

         
        require(isReadyToBreed(_matronId));

         
        require(isReadyToBreed(_sireId));

         
        require(isValidMatingPair(_matronId, _sireId));

         
        _breedWith(_matronId, _sireId, autoBirthFee);
    }

    function giveBirth(uint256 _matronId, uint256 _monsterId, uint256 _birthTime, bytes _properties)
        external
        whenNotPaused
        onlyCOO
        returns (uint256)
    {
         
        require(cryptoStorage.getBirthTime(_matronId) != 0);

        uint256 sireId = cryptoStorage.getSiringWithId(_matronId);
         
        require(sireId != 0);

         
         

         
        uint16 parentGen = cryptoStorage.getGeneration(_matronId);
        uint16 sireGen = cryptoStorage.getGeneration(sireId);
        if (sireGen > parentGen) parentGen = sireGen;

        address owner = cryptoStorage.monsterIndexToOwner(_matronId);
        uint256 tokenId = _createMonster(
            _matronId, 
            sireId,
            parentGen + 1, 
            _birthTime, 
            _monsterId, 
            _properties, 
            owner
        );

         
        cryptoStorage.deleteSiringWithId(_matronId);

         
        cryptoStorage.decreasePregnantCounter();

         
        msg.sender.transfer(autoBirthFee);

        return tokenId;
    }

    function computeCooldownSeconds(uint16 _hatchTimes, uint16 _generation) public view returns (uint32) {
        require(hatchDurationByTimes.length > 0);
        require(hatchDurationMultiByGeneration.length > 0);

        uint16 hatchTimesMax = uint16(hatchDurationByTimes.length - 1);
        uint16 hatchTimes = (_hatchTimes > hatchTimesMax ? hatchTimesMax : _hatchTimes);
        
        uint16 generationMax = uint16(hatchDurationMultiByGeneration.length - 1);
        uint16 generation = (_generation > generationMax ? generationMax : _generation);

        return hatchDurationByTimes[hatchTimes] * hatchDurationMultiByGeneration[generation] / 60;
    }

    function isReadyToBreed(uint256 _tokenId) public view returns (bool) {
         
        return (cryptoStorage.getSiringWithId(_tokenId) == 0) && (cryptoStorage.getCooldownEndBlock(_tokenId) <= uint64(block.number));
    }

    function isPregnant(uint256 _tokenId) public view returns (bool) {
         
        return cryptoStorage.getSiringWithId(_tokenId) != 0;
    }

    function isValidMatingPair(uint256 _matronId, uint256 _sireId) public view returns (bool) {
         
        if (_matronId == _sireId) {
            return false;
        }
        uint32 matron_of_matron = cryptoStorage.getMatronId(_matronId);
        uint32 sire_of_matron = cryptoStorage.getSireId(_matronId);
        uint32 matron_of_sire = cryptoStorage.getMatronId(_sireId);
        uint32 sire_of_sire = cryptoStorage.getSireId(_sireId);
         
        if (matron_of_matron == _sireId || sire_of_matron == _sireId) return false;
        if (matron_of_sire == _matronId || sire_of_sire == _matronId) return false;
         
        if (matron_of_sire == 0 || matron_of_matron == 0) return true;
         
        if (matron_of_sire == matron_of_matron || matron_of_sire == sire_of_matron) return false;
        if (sire_of_sire == matron_of_matron || sire_of_sire == sire_of_matron) return false;    
        return true;
    }

    function _createMonster(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _birthTime,
        uint256 _monsterId,
        bytes _properties,
        address _owner
    )
        internal
        returns (uint256)
    {
        uint256 tokenId = cryptoStorage.createMonster(
            _matronId,
            _sireId,
            _generation,
            _birthTime,
            _monsterId,
            _properties
        );

        _transfer(0, _owner, tokenId);
        
        emit Birth(_owner, tokenId, _matronId, _sireId);

        return tokenId;
    }

    function _breedWith(uint256 _matronId, uint256 _sireId, uint256 _breedCost) internal {
         
        cryptoStorage.setSiringWithId(_matronId, uint32(_sireId));

         
        uint64 sireCooldownEndBlock = _triggerCooldown(_sireId);
        uint64 matronCooldownEndBlock = _triggerCooldown(_matronId);

         
        cryptoStorage.increasePregnantCounter();
        
         
        emit Pregnant(
            cryptoStorage.monsterIndexToOwner(_matronId),
            _matronId,
            _sireId,
            matronCooldownEndBlock,
            sireCooldownEndBlock,
            _breedCost
        );
    }

     
    function _triggerCooldown(uint256 _tokenId) internal returns (uint64) {
        uint32 cooldownSeconds = computeCooldownSeconds(cryptoStorage.getCooldownIndex(_tokenId), cryptoStorage.getGeneration(_tokenId));
        uint64 cooldownEndBlock = uint64((cooldownSeconds / secondsPerBlock) + block.number);
        cryptoStorage.setCooldownEndBlock(_tokenId, cooldownEndBlock);
         
        cryptoStorage.setCooldownIndex(_tokenId);
        return cooldownEndBlock;
    }
}