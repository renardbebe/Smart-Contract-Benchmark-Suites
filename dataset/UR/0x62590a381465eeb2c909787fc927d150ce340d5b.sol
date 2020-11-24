 

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

 
 
 
 
 
 
 
 
 
contract EthernautsMarket is EthernautsLogic, ClockAuctionBase {

     
     
     
     
     
    function EthernautsMarket(uint256 _cut) public
    EthernautsLogic() {
        require(_cut <= 10000);
        ownerCut = _cut;
        nonFungibleContract = this;
    }

     
     
    event Purchase(uint256 indexed tokenId, uint256 oldPrice, uint256 newPrice, address indexed prevOwner, address indexed winner);

     
    uint8 private percentageFee1Step = 95;
    uint8 private percentageFee2Step = 95;
    uint8 private percentageFeeSteps = 98;
    uint8 private percentageBase = 100;
    uint8 private percentage1Step = 200;
    uint8 private percentage2Step = 125;
    uint8 private percentageSteps = 115;
    uint256 private firstStepLimit =  0.05 ether;
    uint256 private secondStepLimit = 5 ether;

     
     
     
     
    function bid(uint256 _tokenId)
    external
    payable
    whenNotPaused
    {
         
        uint256 newPrice = _bid(_tokenId, msg.value);
        _transfer(msg.sender, _tokenId);

         
        ethernautsStorage.setPrice(_tokenId, newPrice);
    }

     
     
     
     
     
    function cancelAuction(uint256 _tokenId)
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        address seller = auction.seller;
        require(msg.sender == seller);
        _cancelAuction(_tokenId, seller);
    }

     
     
     
     
    function cancelAuctionWhenPaused(uint256 _tokenId)
    whenPaused
    onlyCLevel
    external
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        _cancelAuction(_tokenId, auction.seller);
    }

     
     
    function getAuction(uint256 _tokenId)
    external
    view
    returns
    (
        address seller,
        uint256 startingPrice,
        uint256 endingPrice,
        uint256 duration,
        uint256 startedAt
    ) {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return (
        auction.seller,
        auction.startingPrice,
        auction.endingPrice,
        auction.duration,
        auction.startedAt
        );
    }

     
     
    function getCurrentPrice(uint256 _tokenId)
    external
    view
    returns (uint256)
    {
        Auction storage auction = tokenIdToAuction[_tokenId];
        require(_isOnAuction(auction));
        return _currentPrice(auction);
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
         
         
        require(_startingPrice == uint256(uint128(_startingPrice)));
        require(_endingPrice == uint256(uint128(_endingPrice)));
        require(_duration == uint256(uint64(_duration)));

         
         
         
        require(_owns(msg.sender, _tokenId));
         
         
        require(ethernautsStorage.hasAllAttrs(_tokenId, ATTR_TRADABLE));
        require(!ethernautsStorage.hasAllAttrs(_tokenId, ATTR_GOLDENGOOSE));

         
        require(ethernautsStorage.isState(_tokenId, uint8(AssetState.Available)));

         
        require(!isExploring(_tokenId));

        ethernautsStorage.approve(_tokenId, address(this));

         
         
        _transferFrom(msg.sender, this, _tokenId);

        Auction memory auction = Auction(
            msg.sender,
            uint128(_startingPrice),
            uint128(_endingPrice),
            uint64(_duration),
            uint64(now)
        );

        _addAuction(_tokenId, auction);
    }

     
    function setOwnerCut(uint256 _ownerCut) public onlyCLevel {
        ownerCut = _ownerCut;
    }


     

     
     
    function purchase(uint256 _tokenId) external payable whenNotPaused {
         
        require(ethernautsStorage.hasAnyAttrs(_tokenId, ATTR_GOLDENGOOSE));

         
        require(!isExploring(_tokenId));

        address oldOwner = ethernautsStorage.ownerOf(_tokenId);
        address newOwner = msg.sender;
        uint256 sellingPrice = ethernautsStorage.priceOf(_tokenId);

         
         
        require(oldOwner != newOwner);

         
        require(newOwner != address(0));

         
        require(msg.value >= sellingPrice);

        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, percentageFee1Step), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);
        uint256 newPrice = sellingPrice;

         
        if (sellingPrice < firstStepLimit) {
             
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, percentage1Step), percentageBase);
        } else if (sellingPrice < secondStepLimit) {
             
            payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, percentageFee2Step), 100));

             
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, percentage2Step), percentageBase);
        } else {
             
            payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, percentageFeeSteps), 100));

             
            newPrice = SafeMath.div(SafeMath.mul(sellingPrice, percentageSteps), percentageBase);
        }

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);  
        }

         
        ethernautsStorage.transfer(oldOwner, newOwner, _tokenId);

         
        ethernautsStorage.setPrice(_tokenId, newPrice);

        Purchase(_tokenId, sellingPrice, newPrice, oldOwner, newOwner);

         
        msg.sender.transfer(purchaseExcess);
    }

     
    function setStepLimits(
        uint256 _firstStepLimit,
        uint256 _secondStepLimit
    ) public onlyCLevel {
        firstStepLimit = _firstStepLimit;
        secondStepLimit = _secondStepLimit;
    }

     
    function setPercentages(
        uint8 _Fee1,
        uint8 _Fee2,
        uint8 _Fees,
        uint8 _1Step,
        uint8 _2Step,
        uint8 _Steps
    ) public onlyCLevel {
        percentageFee1Step = _Fee1;
        percentageFee2Step = _Fee2;
        percentageFeeSteps = _Fees;
        percentage1Step = _1Step;
        percentage2Step = _2Step;
        percentageSteps = _Steps;
    }

}