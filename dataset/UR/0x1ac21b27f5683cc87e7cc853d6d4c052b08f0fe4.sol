 

pragma solidity ^0.4.19;

 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
    function takeOwnership(uint256 _tokenId) public;
    function implementsERC721() public pure returns (bool);

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);

     
     
     
     
     

     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool);
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

     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
    }


}

 
 
 
contract ClockAuctionBase {

     
    struct Auction {
         
        address seller;
         
        uint128 startingPrice;
         
        uint128 endingPrice;
         
        uint64 duration;
         
         
        uint64 startedAt;
    }

     
    ERC721 public nonFungibleContract;

     
     
    uint256 public ownerCut;

     
    mapping (uint256 => Auction) tokenIdToAuction;

    event AuctionCreated(uint256 tokenId, uint256 startingPrice, uint256 endingPrice, uint256 duration);
    event AuctionSuccessful(uint256 tokenId, uint256 totalPrice, address winner);
    event AuctionCancelled(uint256 tokenId);

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return (nonFungibleContract.ownerOf(_tokenId) == _claimant);
    }

     
     
     
     
    function _transfer(address _receiver, uint256 _tokenId) internal {
         
        nonFungibleContract.transfer(_receiver, _tokenId);
    }

     
     
     
     
    function _addAuction(uint256 _tokenId, Auction _auction) internal {
         
         
        require(_auction.duration >= 1 minutes);

        tokenIdToAuction[_tokenId] = _auction;

        AuctionCreated(
            uint256(_tokenId),
            uint256(_auction.startingPrice),
            uint256(_auction.endingPrice),
            uint256(_auction.duration)
        );
    }

     
    function _cancelAuction(uint256 _tokenId, address _seller) internal {
        _removeAuction(_tokenId);
        _transfer(_seller, _tokenId);
        AuctionCancelled(_tokenId);
    }

     
     
    function _bid(uint256 _tokenId, uint256 _bidAmount)
    internal
    returns (uint256)
    {
         
        Auction storage auction = tokenIdToAuction[_tokenId];

         
         
         
         
        require(_isOnAuction(auction));

         
        uint256 price = _currentPrice(auction);
        require(_bidAmount >= price);

         
         
        address seller = auction.seller;

         
         
        _removeAuction(_tokenId);

         
        if (price > 0) {
             
             
             
            uint256 auctioneerCut = _computeCut(price);
            uint256 sellerProceeds = price - auctioneerCut;

             
             
             
             
             
             
             
             
            seller.transfer(sellerProceeds);
        }

         
         
         
         
        uint256 bidExcess = _bidAmount - price;

         
         
         
        msg.sender.transfer(bidExcess);

         
        AuctionSuccessful(_tokenId, price, msg.sender);

        return price;
    }

     
     
    function _removeAuction(uint256 _tokenId) internal {
        delete tokenIdToAuction[_tokenId];
    }

     
     
    function _isOnAuction(Auction storage _auction) internal view returns (bool) {
        return (_auction.startedAt > 0);
    }

     
     
     
     
    function _currentPrice(Auction storage _auction)
    internal
    view
    returns (uint256)
    {
        uint256 secondsPassed = 0;

         
         
         
        if (now > _auction.startedAt) {
            secondsPassed = now - _auction.startedAt;
        }

        return _computeCurrentPrice(
            _auction.startingPrice,
            _auction.endingPrice,
            _auction.duration,
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
         
         
         
         
         
        return SafeMath.mul(_price, SafeMath.div(ownerCut,10000));
    }

}




 
contract EthernautsBase {

     

     
     
     
     
    bytes4 constant InterfaceSignature_ERC721 =
    bytes4(keccak256('name()')) ^
    bytes4(keccak256('symbol()')) ^
    bytes4(keccak256('totalSupply()')) ^
    bytes4(keccak256('balanceOf(address)')) ^
    bytes4(keccak256('ownerOf(uint256)')) ^
    bytes4(keccak256('approve(address,uint256)')) ^
    bytes4(keccak256('transfer(address,uint256)')) ^
    bytes4(keccak256('transferFrom(address,address,uint256)')) ^
    bytes4(keccak256('takeOwnership(uint256)')) ^
    bytes4(keccak256('tokensOfOwner(address)')) ^
    bytes4(keccak256('tokenMetadata(uint256,string)'));

     
     
    uint8 public constant STATS_SIZE = 10;
    uint8 public constant SHIP_SLOTS = 5;

     
    enum AssetState { Available, UpForLease, Used }

     
     
    enum AssetCategory { NotValid, Sector, Manufacturer, Ship, Object, Factory, CrewMember }

     
    enum ShipStats {Level, Attack, Defense, Speed, Range, Luck}
     
     
     
     
     
     
     
     
     
    bytes2 public ATTR_SEEDED     = bytes2(2**0);
    bytes2 public ATTR_PRODUCIBLE = bytes2(2**1);
    bytes2 public ATTR_EXPLORABLE = bytes2(2**2);
    bytes2 public ATTR_LEASABLE   = bytes2(2**3);
    bytes2 public ATTR_PERMANENT  = bytes2(2**4);
    bytes2 public ATTR_CONSUMABLE = bytes2(2**5);
    bytes2 public ATTR_TRADABLE   = bytes2(2**6);
    bytes2 public ATTR_GOLDENGOOSE = bytes2(2**7);
}

 
 
 
contract EthernautsAccessControl is EthernautsBase {

     
     
     
     
     
     
     
     
     
     
     
     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public ctoAddress;
    address public cooAddress;
    address public oracleAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCTO() {
        require(msg.sender == ctoAddress);
        _;
    }

     
    modifier onlyOracle() {
        require(msg.sender == oracleAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress ||
            msg.sender == cooAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCTO(address _newCTO) external {
        require(
            msg.sender == ceoAddress ||
            msg.sender == ctoAddress
        );
        require(_newCTO != address(0));

        ctoAddress = _newCTO;
    }

     
     
    function setCOO(address _newCOO) external {
        require(
            msg.sender == ceoAddress ||
            msg.sender == cooAddress
        );
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     
     
    function setOracle(address _newOracle) external {
        require(msg.sender == ctoAddress);
        require(_newOracle != address(0));

        oracleAddress = _newOracle;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }

}









 
 
 
 
 
contract EthernautsStorage is EthernautsAccessControl {

    function EthernautsStorage() public {
         
        ceoAddress = msg.sender;

         
        ctoAddress = msg.sender;

         
        cooAddress = msg.sender;

         
        oracleAddress = msg.sender;
    }

     
     
    function() external payable {
        require(msg.sender == address(this));
    }

     
    mapping (address => bool) public contractsGrantedAccess;

     
     
    function grantAccess(address _v2Address) public onlyCTO {
         
        contractsGrantedAccess[_v2Address] = true;
    }

     
     
    function removeAccess(address _v2Address) public onlyCTO {
         
        delete contractsGrantedAccess[_v2Address];
    }

     
    modifier onlyGrantedContracts() {
        require(contractsGrantedAccess[msg.sender] == true);
        _;
    }

    modifier validAsset(uint256 _tokenId) {
        require(assets[_tokenId].ID > 0);
        _;
    }
     

     
     
     
     
    struct Asset {

         
        uint16 ID;

         
        uint8 category;

         
        uint8 state;

         
         
         
         
         
         
         
         
         
         
        bytes2 attributes;

         
        uint64 createdAt;

         
        uint64 cooldownEndBlock;

         
         
         
         
         
        uint8[STATS_SIZE] stats;

         
         
        uint256 cooldown;

         
        uint256 builtBy;
    }

     

     
     
    bool public isEthernautsStorage = true;

     

     
     
    Asset[] public assets;

     
     
    mapping (uint256 => uint256) internal assetIndexToPrice;

     
    mapping (uint256 => address) internal assetIndexToOwner;

     
     
    mapping (address => uint256) internal ownershipTokenCount;

     
     
     
    mapping (uint256 => address) internal assetIndexToApproved;


     

     
     
     
    function setPrice(uint256 _tokenId, uint256 _price) public onlyGrantedContracts {
        assetIndexToPrice[_tokenId] = _price;
    }

     
     
     
    function approve(uint256 _tokenId, address _approved) public onlyGrantedContracts {
        assetIndexToApproved[_tokenId] = _approved;
    }

     
     
     
     
    function transfer(address _from, address _to, uint256 _tokenId) public onlyGrantedContracts {
         
        ownershipTokenCount[_to]++;
         
        assetIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
             
            delete assetIndexToApproved[_tokenId];
        }
    }

     
     
     
     
     
     
     
     
     
     
     
    function createAsset(
        uint256 _creatorTokenID,
        address _owner,
        uint256 _price,
        uint16 _ID,
        uint8 _category,
        uint8 _state,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint256 _cooldown,
        uint64 _cooldownEndBlock
    )
    public onlyGrantedContracts
    returns (uint256)
    {
         
        require(_ID > 0);
        require(_category > 0);
        require(_attributes != 0x0);
        require(_stats.length > 0);

        Asset memory asset = Asset({
            ID: _ID,
            category: _category,
            builtBy: _creatorTokenID,
            attributes: bytes2(_attributes),
            stats: _stats,
            state: _state,
            createdAt: uint64(now),
            cooldownEndBlock: _cooldownEndBlock,
            cooldown: _cooldown
            });

        uint256 newAssetUniqueId = assets.push(asset) - 1;

         
        require(newAssetUniqueId == uint256(uint32(newAssetUniqueId)));

         
        assetIndexToPrice[newAssetUniqueId] = _price;

         
        transfer(address(0), _owner, newAssetUniqueId);

        return newAssetUniqueId;
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function editAsset(
        uint256 _tokenId,
        uint256 _creatorTokenID,
        uint256 _price,
        uint16 _ID,
        uint8 _category,
        uint8 _state,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint16 _cooldown
    )
    external validAsset(_tokenId) onlyCLevel
    returns (uint256)
    {
         
        require(_ID > 0);
        require(_category > 0);
        require(_attributes != 0x0);
        require(_stats.length > 0);

         
        assetIndexToPrice[_tokenId] = _price;

        Asset storage asset = assets[_tokenId];
        asset.ID = _ID;
        asset.category = _category;
        asset.builtBy = _creatorTokenID;
        asset.attributes = bytes2(_attributes);
        asset.stats = _stats;
        asset.state = _state;
        asset.cooldown = _cooldown;
    }

     
     
     
    function updateStats(uint256 _tokenId, uint8[STATS_SIZE] _stats) public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].stats = _stats;
    }

     
     
     
    function updateState(uint256 _tokenId, uint8 _state) public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].state = _state;
    }

     
     
     
    function setAssetCooldown(uint256 _tokenId, uint256 _cooldown, uint64 _cooldownEndBlock)
    public validAsset(_tokenId) onlyGrantedContracts {
        assets[_tokenId].cooldown = _cooldown;
        assets[_tokenId].cooldownEndBlock = _cooldownEndBlock;
    }

     

     
     
     
     
    function getStats(uint256 _tokenId) public view returns (uint8[STATS_SIZE]) {
        return assets[_tokenId].stats;
    }

     
     
    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return assetIndexToPrice[_tokenId];
    }

     
     
     
    function hasAllAttrs(uint256 _tokenId, bytes2 _attributes) public view returns (bool) {
        return assets[_tokenId].attributes & _attributes == _attributes;
    }

     
     
     
    function hasAnyAttrs(uint256 _tokenId, bytes2 _attributes) public view returns (bool) {
        return assets[_tokenId].attributes & _attributes != 0x0;
    }

     
     
     
    function isCategory(uint256 _tokenId, uint8 _category) public view returns (bool) {
        return assets[_tokenId].category == _category;
    }

     
     
     
    function isState(uint256 _tokenId, uint8 _state) public view returns (bool) {
        return assets[_tokenId].state == _state;
    }

     
     
     
    function ownerOf(uint256 _tokenId) public view returns (address owner)
    {
        return assetIndexToOwner[_tokenId];
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ownershipTokenCount[_owner];
    }

     
     
    function approvedFor(uint256 _tokenId) public view onlyGrantedContracts returns (address) {
        return assetIndexToApproved[_tokenId];
    }

     
     
    function totalSupply() public view returns (uint256) {
        return assets.length;
    }

     
     
    function getTokenList(address _owner, uint8 _withAttributes, uint256 start, uint256 count) external view returns(
        uint256[6][]
    ) {
        uint256 totalAssets = assets.length;

        if (totalAssets == 0) {
             
            return new uint256[6][](0);
        } else {
            uint256[6][] memory result = new uint256[6][](totalAssets > count ? count : totalAssets);
            uint256 resultIndex = 0;
            bytes2 hasAttributes  = bytes2(_withAttributes);
            Asset memory asset;

            for (uint256 tokenId = start; tokenId < totalAssets && resultIndex < count; tokenId++) {
                asset = assets[tokenId];
                if (
                    (asset.state != uint8(AssetState.Used)) &&
                    (assetIndexToOwner[tokenId] == _owner || _owner == address(0)) &&
                    (asset.attributes & hasAttributes == hasAttributes)
                ) {
                    result[resultIndex][0] = tokenId;
                    result[resultIndex][1] = asset.ID;
                    result[resultIndex][2] = asset.category;
                    result[resultIndex][3] = uint256(asset.attributes);
                    result[resultIndex][4] = asset.cooldown;
                    result[resultIndex][5] = assetIndexToPrice[tokenId];
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

 
 
 
 
 
 
 
contract EthernautsOwnership is EthernautsAccessControl, ERC721 {

     
    EthernautsStorage public ethernautsStorage;

     
     
    string public constant name = "Ethernauts";
    string public constant symbol = "ETNT";

     
     

    bytes4 constant InterfaceSignature_ERC165 = bytes4(keccak256('supportsInterface(bytes4)'));

     

     
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed owner, address indexed approved, uint256 tokens);

     
     
     
     
     
    event Build(address owner, uint256 tokenId, uint16 assetId, uint256 price);

    function implementsERC721() public pure returns (bool) {
        return true;
    }

     
     
     
    function supportsInterface(bytes4 _interfaceID) external view returns (bool)
    {
        return ((_interfaceID == InterfaceSignature_ERC165) || (_interfaceID == InterfaceSignature_ERC721));
    }

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ethernautsStorage.ownerOf(_tokenId) == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return ethernautsStorage.approvedFor(_tokenId) == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        ethernautsStorage.approve(_tokenId, _approved);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return ethernautsStorage.balanceOf(_owner);
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(ethernautsStorage));

         
        require(_owns(msg.sender, _tokenId));

         
        ethernautsStorage.transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        Approval(msg.sender, _to, _tokenId);
    }


     
     
     
     
     
     
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    internal
    {
         
        require(_to != address(0));
         
         
        require(_owns(_from, _tokenId));
         
        require(_approvedFor(_to, _tokenId));

         
        ethernautsStorage.transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
    external
    whenNotPaused
    {
        _transferFrom(_from, _to, _tokenId);
    }

     
     
     
    function takeOwnership(uint256 _tokenId) public {
        address _from = ethernautsStorage.ownerOf(_tokenId);

         
        require(_from != address(0));
        _transferFrom(_from, msg.sender, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint256) {
        return ethernautsStorage.totalSupply();
    }

     
     
     
    function ownerOf(uint256 _tokenId)
    external
    view
    returns (address owner)
    {
        owner = ethernautsStorage.ownerOf(_tokenId);

        require(owner != address(0));
    }

     
     
     
     
     
     
     
    function createNewAsset(
        uint256 _creatorTokenID,
        uint256 _price,
        uint16 _assetID,
        uint8 _category,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats
    )
    external onlyCLevel
    returns (uint256)
    {
         
        require(msg.sender != address(0));

        uint256 tokenID = ethernautsStorage.createAsset(
            _creatorTokenID,
            msg.sender,
            _price,
            _assetID,
            _category,
            uint8(AssetState.Available),
            _attributes,
            _stats,
            0,
            0
        );

         
        Build(
            msg.sender,
            tokenID,
            _assetID,
            _price
        );

        return tokenID;
    }

     
     
    function isExploring(uint256 _tokenId) public view returns (bool) {
        uint256 cooldown;
        uint64 cooldownEndBlock;
        (,,,,,cooldownEndBlock, cooldown,) = ethernautsStorage.assets(_tokenId);
        return (cooldown > now) || (cooldownEndBlock > uint64(block.number));
    }
}


 
 
contract EthernautsLogic is EthernautsOwnership {

     
    address public newContractAddress;

     
    function EthernautsLogic() public {
         
        ceoAddress = msg.sender;
        ctoAddress = msg.sender;
        cooAddress = msg.sender;
        oracleAddress = msg.sender;

         
        paused = true;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCTO whenPaused {
         
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
    function setEthernautsStorageContract(address _CStorageAddress) public onlyCLevel whenPaused {
        EthernautsStorage candidateContract = EthernautsStorage(_CStorageAddress);
        require(candidateContract.isEthernautsStorage());
        ethernautsStorage = candidateContract;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(ethernautsStorage != address(0));
        require(newContractAddress == address(0));
         
        require(ethernautsStorage.contractsGrantedAccess(address(this)) == true);

         
        super.unpause();
    }

     
    function withdrawBalances(address _to) public onlyCLevel {
        _to.transfer(this.balance);
    }

     
    function getBalance() public view onlyCLevel returns (uint256) {
        return this.balance;
    }
}

 
 
 
 
 
 
 
 
contract EthernautsUpgrade is EthernautsLogic, ClockAuctionBase {

     
     
     
    function EthernautsUpgrade() public
    EthernautsLogic() {}

     
     
    event Upgrade(uint256 indexed tokenId);

     
    uint8 STATS_CAPOUT = 2**8 - 1;  

     

     
     
     
     
     
     
     
     
     
     
     
    function upgradeShip(uint256 _tokenId, uint256[SHIP_SLOTS] _objects) external whenNotPaused {
         
        require(ethernautsStorage.isCategory(_tokenId, uint8(AssetCategory.Ship)));

         
        require(ethernautsStorage.isState(_tokenId, uint8(AssetState.Available)));

         
        require(msg.sender == ethernautsStorage.ownerOf(_tokenId));

         
        require(!isExploring(_tokenId));

         
        uint i = 0;
        uint8[STATS_SIZE] memory _shipStats = ethernautsStorage.getStats(_tokenId);
        uint256 level = _shipStats[uint(ShipStats.Level)];
        uint8[STATS_SIZE][SHIP_SLOTS] memory _objectsStats;

         
        require(level < 5);

         
        uint256[] memory upgradesToTokenIndex = new uint256[](ethernautsStorage.totalSupply());

         
        for(i = 0; i < _objects.length; i++) {
             
            require(msg.sender == ethernautsStorage.ownerOf(_objects[i]));
            require(!isExploring(_objects[i]));
            require(ethernautsStorage.isCategory(_objects[i], uint8(AssetCategory.Object)));
             
            require(upgradesToTokenIndex[_objects[i]] == 0);

             
            upgradesToTokenIndex[_objects[i]] = _objects[i];
            _objectsStats[i] = ethernautsStorage.getStats(_objects[i]);
        }

         
        uint256 attack = _shipStats[uint(ShipStats.Attack)];
        uint256 defense = _shipStats[uint(ShipStats.Defense)];
        uint256 speed = _shipStats[uint(ShipStats.Speed)];
        uint256 range = _shipStats[uint(ShipStats.Range)];
        uint256 luck = _shipStats[uint(ShipStats.Luck)];

        for(i = 0; i < SHIP_SLOTS; i++) {
             
            require(_objectsStats[i][1] +
                    _objectsStats[i][2] +
                    _objectsStats[i][3] +
                    _objectsStats[i][4] +
                    _objectsStats[i][5] > 0);

            attack += _objectsStats[i][uint(ShipStats.Attack)];
            defense += _objectsStats[i][uint(ShipStats.Defense)];
            speed += _objectsStats[i][uint(ShipStats.Speed)];
            range += _objectsStats[i][uint(ShipStats.Range)];
            luck += _objectsStats[i][uint(ShipStats.Luck)];
        }

        if (attack > STATS_CAPOUT) {
            attack = STATS_CAPOUT;
        }
        if (defense > STATS_CAPOUT) {
            defense = STATS_CAPOUT;
        }
        if (speed > STATS_CAPOUT) {
            speed = STATS_CAPOUT;
        }
        if (range > STATS_CAPOUT) {
            range = STATS_CAPOUT;
        }
        if (luck > STATS_CAPOUT) {
            luck = STATS_CAPOUT;
        }

         
        require(attack > _shipStats[uint(ShipStats.Attack)]);
        require(defense > _shipStats[uint(ShipStats.Defense)]);
        require(speed > _shipStats[uint(ShipStats.Speed)]);
        require(range > _shipStats[uint(ShipStats.Range)]);
        require(luck > _shipStats[uint(ShipStats.Luck)]);

        _shipStats[uint(ShipStats.Level)] = uint8(level + 1);
        _shipStats[uint(ShipStats.Attack)] = uint8(attack);
        _shipStats[uint(ShipStats.Defense)] = uint8(defense);
        _shipStats[uint(ShipStats.Speed)] = uint8(speed);
        _shipStats[uint(ShipStats.Range)] = uint8(range);
        _shipStats[uint(ShipStats.Luck)] = uint8(luck);

         
        ethernautsStorage.updateStats(_tokenId, _shipStats);

         
        for(i = 0; i < _objects.length; i++) {
            ethernautsStorage.updateState(_objects[i], uint8(AssetState.Used));

             
            _approve(_objects[i], address(this));
            _transferFrom(msg.sender, address(this), _objects[i]);
        }

        Upgrade(_tokenId);
    }

}