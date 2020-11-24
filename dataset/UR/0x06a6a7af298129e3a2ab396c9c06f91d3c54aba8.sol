 

pragma solidity 0.4.24;

 

contract ISaleClockAuction {

    function isSaleClockAuction() public returns(bool);


     
     
     
     
     
     
    function createAuction(
        uint256 _tokenId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration,
        address _seller
    )
    external;

     
     
    function bid(uint256 _tokenId)
    external
    payable;

    function cancelAuction(uint256 _tokenId)
    external;

     
    function clearAll(address _seller, uint planetLimitation)
    external;

     
    function clearOne(address _seller, uint256 _tokenId)
    external;

    function averageExpansionSalePrice(uint256 _rarity) external view returns (uint256);

    function withdrawBalance() external;
}

 

contract ArrayArchiveTools {

    function _splitUint40ToArray(uint256 _hash) internal pure returns (uint256[5] _array) {
        for (uint i = 0; i < 5; i++) {
            _array[i] = uint256(uint8(_hash >> (8 * i)));
        }
    }

    function _mergeArrayToUint40(uint256[5] _array) internal pure returns (uint256 _hash) {
        for (uint i = 0; i < 5; i++) {
            _hash |= (_array[i] << (8 * i));
        }
    }

    function _splitUint80ToArray(uint256 _hash) internal pure returns (uint256[5] _array) {
        for (uint i = 0; i < 5; i++) {
            _array[i] = uint256(uint16(_hash >> (16 * i)));
        }
    }

    function _mergeArrayToUint80(uint256[5] _array) internal pure returns (uint256 _hash) {
        for (uint i = 0; i < 5; i++) {
            _hash |= (_array[i] << (16 * i));
        }
    }
}

 

contract MathTools {
    function _divisionWithRound(uint _numerator, uint _denominator) internal pure returns (uint _r) {
        _r = _numerator / _denominator;
        if (_numerator % _denominator >= _denominator / 2) {
            _r++;
        }
    }
}

 

 
contract UniverseDiscoveryConstant {
     
    uint256 internal constant MAX_RANKS_COUNT = 20;

     
    uint256 internal constant MAX_ID_LIST_LENGTH = 5;
}

 

contract IUniversePlanetExploration is UniverseDiscoveryConstant {

    function isUniversePlanetExploration() external returns(bool);

    function explorePlanet(uint256 _rarity)
    external
    returns (
        uint[MAX_ID_LIST_LENGTH] resourcesId,
        uint[MAX_ID_LIST_LENGTH] resourcesVelocity
    );
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Treasurer is Ownable {
    address public treasurer;

     
    modifier onlyTreasurer() {
        require(msg.sender == treasurer, "Only treasurer");
        _;
    }

    function transferTreasurer(address _treasurer) public onlyOwner {
        if (_treasurer != address(0)) {
            treasurer = _treasurer;
        }
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

contract AccessControl is Ownable, Treasurer, Pausable {

    modifier onlyTeam() {
        require(
            msg.sender == owner ||
            msg.sender == treasurer
        , "Only owner and treasure have access"
        );
        _;
    }

    function pause() public onlyTeam {
        return super.pause();
    }
}

 

 
contract Random {
    uint internal saltForRandom;

    function _rand() internal returns (uint256) {
        uint256 lastBlockNumber = block.number - 1;

        uint256 hashVal = uint256(blockhash(lastBlockNumber));

         
         
        uint256 factor = 1157920892373161954235709850086879078532699846656405640394575840079131296399;

        saltForRandom += uint256(msg.sender) % 100 + uint256(uint256(hashVal) / factor);

        return saltForRandom;
    }

    function _randRange(uint256 min, uint256 max) internal returns (uint256) {
        return uint256(keccak256(_rand())) % (max - min + 1) + min;
    }

    function _randChance(uint percent) internal returns (bool) {
        return _randRange(0, 100) < percent;
    }

    function _now() internal view returns (uint256) {
        return now;
    }
}

 

contract IUniverseBalance {
    function isUniverseBalance() external returns(bool);

    function autoClearAuction() external returns(bool);

    function getUIntValue(uint record) external view returns (uint);
    function getUIntArray2Value(uint record) external view returns (uint[2]);
    function getUIntArray3Value(uint record) external view returns (uint[3]);
    function getUIntArray4Value(uint record) external view returns (uint[4]);

    function getRankParamsValue(uint rankId) external view returns (uint[3]);
    function getRankResourcesCountByRarity(uint rankId) external view returns (uint[4]);

    function getGroupId(uint _x, uint _y) external view returns (uint);

    function getResourcesQuantityByRarity(uint256 rarity) external pure returns (uint256[2]);
}

 

 
contract UniverseGalaxyConstant {
     
    uint256 internal constant SECTOR_X_MAX = 25;
    uint256 internal constant SECTOR_Y_MAX = 40;

    uint256 internal constant PLANETS_COUNT = 1000000;

    uint256 internal constant SECTORS_COUNT = SECTOR_X_MAX * SECTOR_Y_MAX;  

    uint256 internal constant PLANETS_COUNT_PER_SECTOR = PLANETS_COUNT / SECTORS_COUNT;  

     
    uint256 internal constant MAX_ID_LIST_LENGTH = 5;
}

 

 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}

 

contract IUniverseGalaxy is ERC721Basic, UniverseGalaxyConstant{

    function getPlanet(uint256 _id) external view
    returns (
        uint256 rarity,
        uint256 discovered,
        uint256 sectorX,
        uint256 sectorY,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesVelocity
    );

    function createSaleAuction(uint256 _planetId, uint256 _startingPrice, uint256 _endingPrice, uint256 _duration) external;

    function findAvailableResource(address _owner, uint _rarity) external returns (int8);
    function getDiscoveredPlanetsDensity(uint sectorX, uint sectorY) external view returns (uint);

    function createPlanet(
        address _owner,
        uint256 _rarity,
        uint256 _sectorX,
        uint256 _sectorY,
        uint256 _startPopulation
    ) external returns(uint256);

    function spendResources(address _owner, uint[MAX_ID_LIST_LENGTH] _resourcesId, uint[MAX_ID_LIST_LENGTH] _resourcesNeeded) external;

    function spendResourceOnPlanet(address _owner, uint _planetId, uint _resourceId, uint _resourceValue) external;

    function spendKnowledge(address _owner, uint _spentKnowledge) external;

    function recountPlanetResourcesAndUserKnowledge(address _owner, uint256 _planetId) external;

    function countPlanetsByRarityInGroup(uint _groupIndex, uint _rarity) external view returns (uint);

    function countPlanetsByRarity(uint _rarity) external view returns (uint);

    function checkWhetherEnoughPromoPlanet() external;
}

 

 
contract Whitelist is Ownable {
  mapping(address => bool) public whitelist;

  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

   
  modifier onlyWhitelisted() {
    require(whitelist[msg.sender]);
    _;
  }

   
  function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
    if (!whitelist[addr]) {
      whitelist[addr] = true;
      emit WhitelistedAddressAdded(addr);
      success = true;
    }
  }

   
  function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (addAddressToWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

   
  function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
    if (whitelist[addr]) {
      whitelist[addr] = false;
      emit WhitelistedAddressRemoved(addr);
      success = true;
    }
  }

   
  function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
    for (uint256 i = 0; i < addrs.length; i++) {
      if (removeAddressFromWhitelist(addrs[i])) {
        success = true;
      }
    }
  }

}

 

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
}


 
contract ERC721Metadata is ERC721Basic {
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string);
}


 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}

 

 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId));
    _;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function exists(uint256 _tokenId) public view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
    require(_from != address(0));
    require(_to != address(0));

    clearApproval(_from, _tokenId);
    removeTokenFrom(_from, _tokenId);
    addTokenTo(_to, _tokenId);

    emit Transfer(_from, _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addTokenTo(_to, _tokenId);
    emit Transfer(address(0), _to, _tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    clearApproval(_owner, _tokenId);
    removeTokenFrom(_owner, _tokenId);
    emit Transfer(_owner, address(0), _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
      emit Approval(_owner, address(0), _tokenId);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    require(ownerOf(_tokenId) == _from);
    ownedTokensCount[_from] = ownedTokensCount[_from].sub(1);
    tokenOwner[_tokenId] = address(0);
  }

   
  function checkAndCallSafeTransfer(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 

 
contract ERC721Token is ERC721, ERC721BasicToken {
   
  string internal name_;

   
  string internal symbol_;

   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  function ERC721Token(string _name, string _symbol) public {
    name_ = _name;
    symbol_ = _symbol;
  }

   
  function name() public view returns (string) {
    return name_;
  }

   
  function symbol() public view returns (string) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function _setTokenURI(uint256 _tokenId, string _uri) internal {
    require(exists(_tokenId));
    tokenURIs[_tokenId] = _uri;
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal {
    super.removeTokenFrom(_from, _tokenId);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = ownedTokens[_from].length.sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    super._mint(_to, _tokenId);

    allTokensIndex[_tokenId] = allTokens.length;
    allTokens.push(_tokenId);
  }

   
  function _burn(address _owner, uint256 _tokenId) internal {
    super._burn(_owner, _tokenId);

     
    if (bytes(tokenURIs[_tokenId]).length != 0) {
      delete tokenURIs[_tokenId];
    }

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

}

 

contract UniverseGalaxyStore is IUniverseGalaxy, ERC721Token, Whitelist, AccessControl, Random, MathTools, ArrayArchiveTools {
     
    event PlanetCreated(
        address indexed owner,
        uint256 indexed planetId,
        uint256 sectorX,
        uint256 sectorY,
        uint256 rarity,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesVelocity,
        uint256 startPopulation
    );

     

    struct Planet {
        uint256 rarity;
        uint256 discovered;
        uint256 updated;
        uint256 sectorX;
        uint256 sectorY;
        uint[MAX_ID_LIST_LENGTH] resourcesId;
        uint[MAX_ID_LIST_LENGTH] resourcesVelocity;
        uint[MAX_ID_LIST_LENGTH] resourcesUpdated;
    }

     

     
     
     
     
     
     
     
     
    uint256[] public planets;

     
     
     
     
     
    mapping (uint256 => uint256) planetStates;

     
    mapping (uint => mapping ( uint => uint )) discoveredPlanetsCountMap;

     
    mapping (uint => mapping (uint => uint)) planetCountByRarityInGroups;

     
    mapping (uint => uint) planetCountByRarity;

    IUniverseBalance public universeBalance;
    IUniversePlanetExploration public universePlanetExploration;

    function UniverseGalaxyStore() ERC721Token("0xUniverse", "PLANET")
    public { }

    function _getPlanet(uint256 _id)
    internal view
    returns(Planet memory _planet)
    {
        uint256 planet = planets[_id];
        uint256 planetState = planetStates[_id];

        _planet.discovered = uint256(uint48(planet));
        _planet.resourcesId = _splitUint40ToArray(uint40(planet >> 48));
        _planet.resourcesVelocity = _splitUint40ToArray(uint40(planet >> 88));
        _planet.sectorX = uint256(uint8(planet >> 128));
        _planet.sectorY = uint256(uint8(planet >> 136));
        _planet.rarity = uint256(uint8(planet >> 144));

        _planet.updated = uint256(uint48(planetState));
        _planet.resourcesUpdated = _splitUint80ToArray(uint80(planetState >> 88));
    }

    function _convertPlanetToPlanetHash(Planet memory _planet)
    internal
    pure
    returns(uint256 _planetHash)
    {
        _planetHash = _planet.discovered;
        _planetHash |= _mergeArrayToUint40(_planet.resourcesId) << 48;
        _planetHash |= _mergeArrayToUint40(_planet.resourcesVelocity) << 88;
        _planetHash |= _planet.sectorX << 128;
        _planetHash |= _planet.sectorY << 136;
        _planetHash |= uint256(_planet.rarity) << 144;
    }

    function _convertPlanetToPlanetStateHash(Planet memory _planet)
    internal
    pure
    returns(uint256 _planetStateHash)
    {
        _planetStateHash = _planet.updated;
        _planetStateHash |= _mergeArrayToUint40(_planet.resourcesId) << 48;
        _planetStateHash |= _mergeArrayToUint80(_planet.resourcesUpdated) << 88;
    }

    function getDiscoveredPlanetsDensity(uint sectorX, uint sectorY) external view returns (uint) {
        uint discoveredPlanetsCount = discoveredPlanetsCountMap[sectorX][sectorY];
         
        if (discoveredPlanetsCount >= PLANETS_COUNT_PER_SECTOR) {
            return 0;
        }
        return 100 - (discoveredPlanetsCount * 100) / PLANETS_COUNT_PER_SECTOR;
    }

    function countPlanetsByRarityInGroup(uint _groupIndex, uint _rarity) external view returns (uint){
        return planetCountByRarityInGroups[_groupIndex][_rarity];
    }

    function countPlanetsByRarity(uint _rarity) external view returns (uint){
        return planetCountByRarity[_rarity];
    }

    function setUniverseBalanceAddress(address _address) external onlyOwner {
        IUniverseBalance candidateContract = IUniverseBalance(_address);

         
         
        require(candidateContract.isUniverseBalance(), "Incorrect address param");

         
        universeBalance = candidateContract;
    }

    function setUniversePlanetExplorationAddress(address _address) external onlyOwner {
        IUniversePlanetExploration candidateContract = IUniversePlanetExploration(_address);

         
         
        require(candidateContract.isUniversePlanetExploration(), "Incorrect address param");

         
        universePlanetExploration = candidateContract;
    }

    function getPlanet(uint256 _id)
    external
    view
    returns (
        uint256 rarity,
        uint256 discovered,
        uint256 sectorX,
        uint256 sectorY,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesVelocity
    ) {
        Planet memory pl = _getPlanet(_id);

        rarity = pl.rarity;
        discovered = pl.discovered;
        sectorX = pl.sectorX;
        sectorY = pl.sectorY;
        resourcesId = pl.resourcesId;
        resourcesVelocity = pl.resourcesVelocity;
    }

    function _getOwnedTokensCount(address _owner) internal view returns (uint256){
        return ownedTokens[_owner].length;
    }

    function _getOwnedTokensByIndex(address _owner, uint256 _ownerTokenIndex) internal view returns (uint256){
        return ownedTokens[_owner][_ownerTokenIndex];
    }

    function findAvailableResource(address _owner, uint _rarity) external returns (int8) {
        uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

        uint[] memory resourceList = new uint[](ownedPlanetsCount * MAX_ID_LIST_LENGTH);

        uint[2] memory resourcesOrderByRarity = universeBalance.getResourcesQuantityByRarity(_rarity);
        uint firstResourceId = resourcesOrderByRarity[0];
        uint lastResourceId = resourcesOrderByRarity[0] + resourcesOrderByRarity[1] - 1;

        uint maxResourceListElement = 0;
        for (uint i = 0; i < ownedPlanetsCount; i++) {
            Planet memory planet = _getPlanet( _getOwnedTokensByIndex(_owner, i) );

            for (uint k = 1; k < planet.resourcesId.length; k++) {
                uint resourceId = planet.resourcesId[k];
                if(resourceId == 0) break;

                if(resourceId >= firstResourceId && resourceId <= lastResourceId) {
                    resourceList[maxResourceListElement] = resourceId;  
                    maxResourceListElement++;
                }
            }
        }

        if (maxResourceListElement > 0) {  
            return int8(resourceList[_randRange(0, maxResourceListElement - 1)]);
        } else {
            return -1;
        }
    }

    function createPlanet(
        address _owner,
        uint256 _rarity,
        uint256 _sectorX,
        uint256 _sectorY,
        uint256 _startPopulation
    )
    external
    onlyWhitelisted
    returns (uint256)
    {
        Planet memory planet = _createPlanetWithRandomResources(_rarity, _sectorX, _sectorY, _startPopulation);
        return _savePlanet(_owner, planet);
    }

    function _savePlanet(
        address _owner,
        Planet _planet
    )
    internal
    returns (uint)
    {
        uint256 planet = _convertPlanetToPlanetHash(_planet);
        uint256 planetState = _convertPlanetToPlanetStateHash(_planet);

        uint256 newPlanetId = planets.push(planet) - 1;
        planetStates[newPlanetId] = planetState;

        require(newPlanetId < PLANETS_COUNT, "No more planets");

        emit PlanetCreated(
            _owner,
            newPlanetId,
            _planet.sectorX,
            _planet.sectorY,
            _planet.rarity,
            _planet.resourcesId,
            _planet.resourcesVelocity,
            _planet.resourcesUpdated[0]
        );

        discoveredPlanetsCountMap[_planet.sectorX][_planet.sectorY] += 1;

        if (_planet.rarity == 3) {
            uint groupIndex = universeBalance.getGroupId(_planet.sectorX, _planet.sectorY);
            planetCountByRarityInGroups[groupIndex][3] += 1;
        }

        if (_planet.rarity == 4) {
            planetCountByRarity[4] += 1;
        }

        _mint(_owner, newPlanetId);

        return newPlanetId;
    }

    function _createPlanetWithRandomResources(uint _rarity, uint _sectorX, uint _sectorY, uint _startPopulation)
    internal
    returns (Planet memory _planet)
    {
        uint[MAX_ID_LIST_LENGTH] memory resourcesId;
        uint[MAX_ID_LIST_LENGTH] memory resourcesVelocity;
        (resourcesId, resourcesVelocity) = universePlanetExploration.explorePlanet(_rarity);

        uint[MAX_ID_LIST_LENGTH] memory resourcesUpdated;
        resourcesUpdated[0] = _startPopulation;

        _planet = Planet({
            rarity: _rarity,
            discovered: uint256(now),
            updated: uint256(now),
            sectorX: _sectorX,
            sectorY: _sectorY,
            resourcesId: resourcesId,
            resourcesVelocity: resourcesVelocity,
            resourcesUpdated: resourcesUpdated
            });
    }
}

 

contract UniverseAuction is UniverseGalaxyStore {

    ISaleClockAuction public saleAuction;

    function setSaleAuctionAddress(address _address) external onlyOwner {
        ISaleClockAuction candidateContract = ISaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction(), "Incorrect address param");

         
        saleAuction = candidateContract;
    }

    function createSaleAuction(
        uint256 _planetId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
    external
    whenNotPaused
    {
        if (universeBalance.autoClearAuction()) saleAuction.clearOne(msg.sender, _planetId);
         
         
         
        require(ownerOf(_planetId) == msg.sender, "Not owner");

        approve(saleAuction, _planetId);
         
         
        saleAuction.createAuction(
            _planetId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }

    function withdrawAuctionBalances() external onlyTeam {
        saleAuction.withdrawBalance();
    }
}

 

contract UniverseGalaxyState is UniverseAuction {

    uint internal constant SECONDS_IN_DAY = 60 * 60 * 24;

    mapping (address => uint) public ownerToKnowledge;
    mapping (address => uint) public lastKnowledgeSpentDateByOwner;

    function getPlanetUpdatedResources(uint256 _id)
    external
    view
    returns (
        uint256 updated,
        uint256[MAX_ID_LIST_LENGTH] resourcesId,
        uint256[MAX_ID_LIST_LENGTH] resourcesUpdated
    ) {
        Planet memory pl = _getPlanet(_id);

        updated = pl.updated;
        resourcesId = pl.resourcesId;
        resourcesUpdated = pl.resourcesUpdated;
    }

    function spendResourceOnPlanet(
        address _owner,
        uint _planetId,
        uint _resourceId,
        uint _resourceValue
    )
    external
    onlyWhitelisted
    {
        require(_owner != address(0), "Owner param should be defined");
        require(_resourceValue > 0, "ResourceValue param should be bigger that zero");

        Planet memory planet = _getPlanet(_planetId);
        planet = _recountPlanetStateAndUpdateUserKnowledge(_owner, planet);

        require(planet.resourcesUpdated[_resourceId] >= _resourceValue, "Resource current should be bigger that ResourceValue");

        planet.resourcesUpdated[_resourceId] -= _resourceValue;
        _updatePlanetStateHash(_planetId, planet);
    }

    function spendResources(
        address _owner,
        uint[MAX_ID_LIST_LENGTH] _resourcesId,
        uint[MAX_ID_LIST_LENGTH] _resourcesNeeded
    ) external onlyWhitelisted {
        uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

        for (uint j = 0; j < _resourcesId.length; j++) {  
            uint resourceId = _resourcesId[j];
            uint resourceNeeded = _resourcesNeeded[j];

            if (resourceNeeded == 0) { continue; }

            for (uint i = 0; i < ownedPlanetsCount; i++) {  
                if (resourceNeeded == 0) { break; }

                uint planetId = _getOwnedTokensByIndex(_owner, i);
                Planet memory planet = _getPlanet(planetId);

                uint foundResourceIndex = 9999;

                for (uint k = 0; k < planet.resourcesId.length; k++) {  
                    if (resourceId == planet.resourcesId[k]) {
                        foundResourceIndex = k;
                        break;
                    }
                }

                if(foundResourceIndex == 9999) {continue;}

                planet = _recountPlanetStateAndUpdateUserKnowledge(_owner, planet);
                if (planet.resourcesUpdated[foundResourceIndex] > 0) {
                    if (planet.resourcesUpdated[foundResourceIndex] >= resourceNeeded) {
                        planet.resourcesUpdated[foundResourceIndex] -= resourceNeeded;
                        resourceNeeded = 0;
                    } else {
                        resourceNeeded -= planet.resourcesUpdated[foundResourceIndex];
                        planet.resourcesUpdated[foundResourceIndex] = 0;
                    }
                }
                _updatePlanetStateHash(planetId, planet);

            }

            if (resourceNeeded > 0) {
                revert("NotEnoughResources");
            }
        }
    }

    function spendKnowledge(address _owner, uint _spentKnowledge) external onlyWhitelisted {
        if (ownerToKnowledge[_owner] < _spentKnowledge) {
            uint balanceVelocity = universeBalance.getUIntValue(  34);

            uint spentKnowledge = _spentKnowledge * SECONDS_IN_DAY;  

            uint knowledge = ownerToKnowledge[_owner] * SECONDS_IN_DAY;

            uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

            bool enoughKnowledge = false;

            for (uint i = 0; i < ownedPlanetsCount; i++) {
                Planet memory planet = _getPlanet( _getOwnedTokensByIndex(_owner, i) );

                uint interval = (_now() - _getLastKnowledgeUpdateForPlanet(_owner, planet)) * balanceVelocity;
                knowledge += (planet.resourcesUpdated[0] + _divisionWithRound(planet.resourcesVelocity[0] * interval, 2 * SECONDS_IN_DAY))
                    * universeBalance.getUIntValue( 17)
                    * interval;

                if (knowledge >= spentKnowledge) {
                    enoughKnowledge = true;
                    break;
                }
            }

            if(!enoughKnowledge) {
                revert("NotEnoughKnowledge");
            }
        }

        ownerToKnowledge[_owner] = 0;
        lastKnowledgeSpentDateByOwner[_owner] = _now();
    }

     
    function getCurrentKnowledgeOfOwner(address _owner) external view returns(uint) {
        uint balanceVelocity = universeBalance.getUIntValue(  34);

        uint knowledge = ownerToKnowledge[_owner] * SECONDS_IN_DAY;

        uint ownedPlanetsCount = _getOwnedTokensCount(_owner);

        for (uint i = 0; i < ownedPlanetsCount; i++) {
            Planet memory planet = _getPlanet( _getOwnedTokensByIndex(_owner, i) );

            uint interval = (_now() - _getLastKnowledgeUpdateForPlanet(_owner, planet)) * balanceVelocity;
            knowledge += (planet.resourcesUpdated[0] + _divisionWithRound(planet.resourcesVelocity[0] * interval, 2 * SECONDS_IN_DAY))
                * universeBalance.getUIntValue( 17)
                * interval;
        }

        return _divisionWithRound(knowledge, SECONDS_IN_DAY);
    }

    function recountPlanetResourcesAndUserKnowledge(address _owner, uint256 _planetId) external onlyWhitelisted {
        Planet memory planet = _getPlanet(_planetId);
        planet = _recountPlanetStateAndUpdateUserKnowledge(_owner, planet);
        _updatePlanetStateHash(_planetId, planet);
    }

    function _updatePlanetStateHash(uint256 _planetID, Planet memory _planet) internal {
        _planet.updated = _now();

        uint256 planetState = _convertPlanetToPlanetStateHash(_planet);
        planetStates[_planetID] = planetState;
    }

    function _getLastKnowledgeUpdateForPlanet(address _owner, Planet memory _planet) internal view returns (uint256) {
        return ((_planet.updated > lastKnowledgeSpentDateByOwner[_owner]) ? _planet.updated : lastKnowledgeSpentDateByOwner[_owner]);
    }

    function _recountPlanetStateAndUpdateUserKnowledge(address _owner, Planet memory _planet) internal returns (Planet) {
        uint balanceVelocity = universeBalance.getUIntValue(  34);

         
        uint intervalForKnowledge = (_now() - _getLastKnowledgeUpdateForPlanet(_owner, _planet)) * balanceVelocity;
        uint knowledge = (_planet.resourcesUpdated[0] + _divisionWithRound(_planet.resourcesVelocity[0] * intervalForKnowledge, 2 * SECONDS_IN_DAY))
            * universeBalance.getUIntValue(  17)
            * intervalForKnowledge;

        ownerToKnowledge[_owner] += _divisionWithRound(knowledge, SECONDS_IN_DAY);


         
        uint interval = (_now() - _planet.updated) * balanceVelocity;

        uint resourcesMultiplierMAX = universeBalance.getUIntValue(  18);

         
        for (uint j = 0; j < _planet.resourcesVelocity.length; j++) {
            if (_planet.resourcesVelocity[j] == 0) { continue; }

            _planet.resourcesUpdated[j] += _divisionWithRound(_planet.resourcesVelocity[j] * interval, SECONDS_IN_DAY);

            uint maxResourceAmount = _planet.resourcesVelocity[j] * resourcesMultiplierMAX;
            if (_planet.resourcesUpdated[j] > maxResourceAmount) {
                _planet.resourcesUpdated[j] = maxResourceAmount;
            }
        }

        return _planet;
    }

    function getPlanetCurrentResources(uint _planetId) external view returns (uint[MAX_ID_LIST_LENGTH]) {
        uint balanceVelocity = universeBalance.getUIntValue(  34);

        Planet memory planet = _getPlanet(_planetId);

        uint interval = (_now() - planet.updated) * balanceVelocity;

        uint[MAX_ID_LIST_LENGTH] memory velocities = planet.resourcesVelocity;

        uint resourcesMultiplierMAX = universeBalance.getUIntValue(  18);

         
        for (uint j = 0; j < velocities.length; j++) {
            if (velocities[j] == 0) { continue; }

            planet.resourcesUpdated[j] += _divisionWithRound(planet.resourcesVelocity[j] * interval, SECONDS_IN_DAY);

            uint maxResourceAmount = planet.resourcesVelocity[j] * resourcesMultiplierMAX;
            if (planet.resourcesUpdated[j] > maxResourceAmount) {
                planet.resourcesUpdated[j] = maxResourceAmount;
            }
        }

        return planet.resourcesUpdated;
    }
}

 

contract UniverseGalaxy is UniverseGalaxyState {

    uint256 public constant PROMO_PLANETS_LIMIT = 10000;

    uint256 public promoCreatedCount;

    function UniverseGalaxy() public {
        paused = true;
        transferTreasurer(owner);
    }

    function initialize(address _earthOwner) external onlyOwner {
        require(planets.length == 0, "Earth was created");

        uint[2] memory earthSector = universeBalance.getUIntArray2Value(  20);

        uint[3] memory earthResourcesId = universeBalance.getUIntArray3Value(  21);
        uint[3] memory earthResourcesVelocity = universeBalance.getUIntArray3Value(  22);
        uint[3] memory earthResourcesUpdated = universeBalance.getUIntArray3Value(  24);

        Planet memory earth = Planet({
            rarity: 3,
            discovered: uint256(now),
            updated: uint256(now),
            sectorX: earthSector[0],
            sectorY: earthSector[1],
            resourcesId: [earthResourcesId[0], earthResourcesId[1], earthResourcesId[2], 0, 0],
            resourcesVelocity: [earthResourcesVelocity[0], earthResourcesVelocity[1], earthResourcesVelocity[2], 0, 0],
            resourcesUpdated: [earthResourcesUpdated[0], earthResourcesUpdated[1], earthResourcesUpdated[2], 0, 0]
            });

        _savePlanet(_earthOwner, earth);
    }

    function checkWhetherEnoughPromoPlanet()
    external
    onlyWhitelisted
    {
        promoCreatedCount++;

        require( promoCreatedCount < PROMO_PLANETS_LIMIT, "Promo planet limit is reached" );
    }

    function() external payable onlyWhitelisted {
    }

    function unpause() public onlyOwner whenPaused {
        require(saleAuction != address(0), "SaleClock contract should be defined");
        require(universeBalance != address(0), "Balance contract should be defined");

         
        super.unpause();
    }

    function withdrawBalance() external onlyTreasurer {
        uint256 balance = address(this).balance;

        treasurer.transfer(balance);
    }
}