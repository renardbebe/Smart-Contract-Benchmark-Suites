 

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

     
    function max(int256 a, int256 b) internal pure returns (int256) {
        if (a > b) {
            return a;
        } else {
            return b;
        }
    }

     
    function min(int256 a, int256 b) internal pure returns (int256) {
        if (a < b) {
            return a;
        } else {
            return b;
        }
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
        address _owner,
        uint256 _price,
        uint16 _assetID,
        uint8 _category,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats
    )
    external onlyCLevel
    returns (uint256)
    {
         
        require(_owner != address(0));

        uint256 tokenID = ethernautsStorage.createAsset(
            _creatorTokenID,
            _owner,
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
            _owner,
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

 
 
 
 
 
 
 
 
contract EthernautsExplore is EthernautsLogic {

     
    function EthernautsExplore() public
    EthernautsLogic() {}

     
     
    event Explore(uint256 shipId, uint256 sectorID, uint256 crewId, uint256 time);

    event Result(uint256 shipId, uint256 sectorID);

     
    uint8 constant STATS_CAPOUT = 2**8 - 1;  

     
     
    bool public isEthernautsExplore = true;

     
    uint256 public secondsPerBlock = 15;

    uint256 public TICK_TIME = 15;  

     
    uint256 public percentageCut  = 90;

    int256 public SPEED_STAT_MAX = 30;
    int256 public RANGE_STAT_MAX = 20;
    int256 public MIN_TIME_EXPLORE = 60;
    int256 public MAX_TIME_EXPLORE = 2160;
    int256 public RANGE_SCALE = 2;

     
    enum SectorStats {Size, Threat, Difficulty, Slots}

     
    uint256[] explorers;

     
    mapping (uint256 => uint256) internal tokenIndexToExplore;

     
    mapping (uint256 => uint256) internal tokenIndexToSector;

     
    mapping (uint256 => uint256) internal exploreIndexToCrew;

     
    mapping (uint256 => uint16) public missions;

     
    mapping (uint256 => uint256) public sectorToOwnerCut;
    mapping (uint256 => uint256) public sectorToOracleFee;

     
    function getExplorerList() public view returns(
        uint256[3][]
    ) {
        uint256[3][] memory tokens = new uint256[3][](explorers.length < 50 ? explorers.length : 50);
        uint256 index = 0;

        for(uint256 i = 0; i < explorers.length && index < 50; i++) {
            if (explorers[i] != 0) {
                tokens[index][0] = explorers[i];
                tokens[index][1] = tokenIndexToSector[explorers[i]];
                tokens[index][2] = exploreIndexToCrew[i];
                index++;
            }
        }

        if (index == 0) {
             
            return new uint256[3][](0);
        } else {
            return tokens;
        }
    }

    function setOwnerCut(uint256 _sectorId, uint256 _ownerCut) external onlyCLevel {
        sectorToOwnerCut[_sectorId] = _ownerCut;
    }

    function setOracleFee(uint256 _sectorId, uint256 _oracleFee) external onlyCLevel {
        sectorToOracleFee[_sectorId] = _oracleFee;
    }

    function setTickTime(uint256 _tickTime) external onlyCLevel {
        TICK_TIME = _tickTime;
    }

    function setPercentageCut(uint256 _percentageCut) external onlyCLevel {
        percentageCut = _percentageCut;
    }

    function setMissions(uint256 _tokenId, uint16 _total) public onlyCLevel {
        missions[_tokenId] = _total;
    }

     
     
     
     
     
     
     
     
     
     
    function explore(uint256 _shipTokenId, uint256 _sectorTokenId, uint256 _crewTokenId) payable external whenNotPaused {
         
        require(msg.value >= sectorToOwnerCut[_sectorTokenId]);

         
        require(ethernautsStorage.isCategory(_shipTokenId, uint8(AssetCategory.Ship)));

         
        require(ethernautsStorage.isCategory(_sectorTokenId, uint8(AssetCategory.Sector)));

         
        require(ethernautsStorage.isState(_shipTokenId, uint8(AssetState.Available)));

         
        require(!isExploring(_shipTokenId));

         
        require(msg.sender == ethernautsStorage.ownerOf(_shipTokenId));

         
        address sectorOwner = ethernautsStorage.ownerOf(_sectorTokenId);
        require(sectorOwner != address(0));

         
        if (_crewTokenId > 0) {
             
            require(!isExploring(_crewTokenId));

             
            require(ethernautsStorage.isCategory(_crewTokenId, uint8(AssetCategory.CrewMember)));

             
            require(msg.sender == ethernautsStorage.ownerOf(_crewTokenId));
        }

         
        tokenIndexToExplore[_shipTokenId] = explorers.push(_shipTokenId) - 1;
        tokenIndexToSector[_shipTokenId] = _sectorTokenId;

        uint8[STATS_SIZE] memory _shipStats = ethernautsStorage.getStats(_shipTokenId);
        uint8[STATS_SIZE] memory _sectorStats = ethernautsStorage.getStats(_sectorTokenId);

         
        if (_crewTokenId > 0) {
             
            exploreIndexToCrew[tokenIndexToExplore[_shipTokenId]] = _crewTokenId;
            missions[_crewTokenId]++;

             
            uint8[STATS_SIZE] memory _crewStats = ethernautsStorage.getStats(_crewTokenId);
            _shipStats[uint256(ShipStats.Range)] += _crewStats[uint256(ShipStats.Range)];
            _shipStats[uint256(ShipStats.Speed)] += _crewStats[uint256(ShipStats.Speed)];

            if (_shipStats[uint256(ShipStats.Range)] > STATS_CAPOUT) {
                _shipStats[uint256(ShipStats.Range)] = STATS_CAPOUT;
            }
            if (_shipStats[uint256(ShipStats.Speed)] > STATS_CAPOUT) {
                _shipStats[uint256(ShipStats.Speed)] = STATS_CAPOUT;
            }
        }

         
        uint256 time = uint256(_explorationTime(
                _shipStats[uint256(ShipStats.Range)],
                _shipStats[uint256(ShipStats.Speed)],
                _sectorStats[uint256(SectorStats.Size)]
            ));
         
        time *= 60;

        uint64 _cooldownEndBlock = uint64((time/secondsPerBlock) + block.number);
        ethernautsStorage.setAssetCooldown(_shipTokenId, now + time, _cooldownEndBlock);

         
        if (_crewTokenId > 0) {
             
            ethernautsStorage.setAssetCooldown(_crewTokenId, now + time, _cooldownEndBlock);
        }

         
        uint256 feeExcess = SafeMath.sub(msg.value, sectorToOwnerCut[_sectorTokenId]);
        uint256 payment = uint256(SafeMath.div(SafeMath.mul(msg.value, percentageCut), 100)) - sectorToOracleFee[_sectorTokenId];

         
        Explore(_shipTokenId, _sectorTokenId, _crewTokenId, now + time);

         
        oracleAddress.transfer(sectorToOracleFee[_sectorTokenId]);

         
        sectorOwner.transfer(payment);

         
        msg.sender.transfer(feeExcess);
    }

     
     
     
     
     
     
    function explorationResults(
        uint256 _shipTokenId,
        uint256 _sectorTokenId,
        uint16[10] _IDs,
        uint8[10] _attributes,
        uint8[STATS_SIZE][10] _stats
    )
    external onlyOracle
    {
        uint256 cooldown;
        uint64 cooldownEndBlock;
        uint256 builtBy;
        (,,,,,cooldownEndBlock, cooldown, builtBy) = ethernautsStorage.assets(_shipTokenId);

        address owner = ethernautsStorage.ownerOf(_shipTokenId);
        require(owner != address(0));

         
        uint256 i = 0;
        for (i = 0; i < 10 && _IDs[i] > 0; i++) {
            _buildAsset(
                _sectorTokenId,
                owner,
                0,
                _IDs[i],
                uint8(AssetCategory.Object),
                uint8(_attributes[i]),
                _stats[i],
                cooldown,
                cooldownEndBlock
            );
        }

         
        require(i > 0);

         
        delete explorers[tokenIndexToExplore[_shipTokenId]];
        delete tokenIndexToSector[_shipTokenId];

         
        Result(_shipTokenId, _sectorTokenId);
    }

     
     
     
     
     
     
     
     
     
    function _buildAsset(
        uint256 _creatorTokenID,
        address _owner,
        uint256 _price,
        uint16 _assetID,
        uint8 _category,
        uint8 _attributes,
        uint8[STATS_SIZE] _stats,
        uint256 _cooldown,
        uint64 _cooldownEndBlock
    )
    private returns (uint256)
    {
        uint256 tokenID = ethernautsStorage.createAsset(
            _creatorTokenID,
            _owner,
            _price,
            _assetID,
            _category,
            uint8(AssetState.Available),
            _attributes,
            _stats,
            _cooldown,
            _cooldownEndBlock
        );

         
        Build(
            _owner,
            tokenID,
            _assetID,
            _price
        );

        return tokenID;
    }

     
     
     
     
     
    function _explorationTime(
        uint8 _shipRange,
        uint8 _shipSpeed,
        uint8 _sectorSize
    ) private view returns (int256) {
        int256 minToExplore = 0;

        minToExplore = SafeMath.min(_shipSpeed, SPEED_STAT_MAX) - 1;
        minToExplore = -72 * minToExplore;
        minToExplore += MAX_TIME_EXPLORE;

        uint256 minRange = uint256(SafeMath.min(_shipRange, RANGE_STAT_MAX));
        uint256 scaledRange = uint256(RANGE_STAT_MAX * RANGE_SCALE);
        int256 minExplore = (minToExplore - MIN_TIME_EXPLORE);

        minToExplore -= fraction(minExplore, int256(minRange), int256(scaledRange));
        minToExplore += fraction(minToExplore, int256(_sectorSize) - int256(10), 10);
        minToExplore = SafeMath.max(minToExplore, MIN_TIME_EXPLORE);

        return minToExplore;
    }

     
    function fraction(int256 _subject, int256 _numerator, int256 _denominator)
    private pure returns (int256) {
        int256 division = _subject * _numerator - _subject * _denominator;
        int256 total = _subject * _denominator + division;
        return total / _denominator;
    }

     
     
    function setSecondsPerBlock(uint256 _secs) external onlyCLevel {
        require(_secs > 0);
        secondsPerBlock = _secs;
    }
}