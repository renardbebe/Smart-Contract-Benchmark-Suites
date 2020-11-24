 

pragma solidity ^0.5.0;

 

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) public view returns (uint256 balance);
    function ownerOf(uint256 tokenId) public view returns (address owner);

    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) public;
    function safeTransferFrom(address from, address to, uint256 tokenId) public;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 

 
contract ERC165 is IERC165 {
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;
     

     
    mapping(bytes4 => bool) private _supportedInterfaces;

     
    constructor () internal {
        _registerInterface(_INTERFACE_ID_ERC165);
    }

     
    function supportsInterface(bytes4 interfaceId) external view returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

     
    function _registerInterface(bytes4 interfaceId) internal {
        require(interfaceId != 0xffffffff);
        _supportedInterfaces[interfaceId] = true;
    }
}

 

 
contract ERC721 is ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
     

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0));
        return _ownedTokensCount[owner];
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0));
        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner);
        require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId));
        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
        require(_isApprovedOrOwner(msg.sender, tokenId));

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data));
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _ownedTokensCount[owner] = _ownedTokensCount[owner].sub(1);
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from);
        require(to != address(0));

        _clearApproval(tokenId);

        _ownedTokensCount[from] = _ownedTokensCount[from].sub(1);
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

 

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

 
contract ERC721Mintable is ERC721, MinterRole {
     
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }
}

 

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender));
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}

 

 
contract Pausable is PauserRole {
    event Paused(address account);
    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

 

 
contract ERC721Pausable is ERC721, Pausable {
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
        super.transferFrom(from, to, tokenId);
    }
}

 

 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 

 
contract ERC721Enumerable is ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;
     

     
    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner));
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply());
        return _allTokens[index];
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        super._transferFrom(from, to, tokenId);

        _removeTokenFromOwnerEnumeration(from, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);
    }

     
    function _mint(address to, uint256 tokenId) internal {
        super._mint(to, tokenId);

        _addTokenToOwnerEnumeration(to, tokenId);

        _addTokenToAllTokensEnumeration(tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

        _removeTokenFromOwnerEnumeration(owner, tokenId);
         
        _ownedTokensIndex[tokenId] = 0;

        _removeTokenFromAllTokensEnumeration(tokenId);
    }

     
    function _tokensOfOwner(address owner) internal view returns (uint256[] storage) {
        return _ownedTokens[owner];
    }

     
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        _ownedTokensIndex[tokenId] = _ownedTokens[to].length;
        _ownedTokens[to].push(tokenId);
    }

     
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

     
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _ownedTokens[from].length.sub(1);
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

         
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId;  
            _ownedTokensIndex[lastTokenId] = tokenIndex;  
        }

         
        _ownedTokens[from].length--;

         
         
    }

     
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
         
         

        uint256 lastTokenIndex = _allTokens.length.sub(1);
        uint256 tokenIndex = _allTokensIndex[tokenId];

         
         
         
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId;  
        _allTokensIndex[lastTokenId] = tokenIndex;  

         
        _allTokens.length--;
        _allTokensIndex[tokenId] = 0;
    }
}

 

 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

contract ERC721Metadata is ERC165, ERC721, IERC721Metadata {
     
    string private _name;

     
    string private _symbol;

     
    mapping(uint256 => string) private _tokenURIs;

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
     

     
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;

         
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

 

 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

 

 
pragma solidity 0.5.4;





contract LandSectorAsset is ERC721Full, ERC721Mintable, ERC721Pausable {


  uint256 public constant SHARE_RATE_DECIMAL = 10**18;

  uint16 public constant LEGENDARY_RARITY = 5;
  uint16 public constant EPIC_RARITY = 4;
  uint16 public constant RARE_RARITY = 3;
  uint16 public constant UNCOMMON_RARITY = 2;
  uint16 public constant COMMON_RARITY = 1;

  uint16 public constant NO_LAND = 0;

  string public tokenURIPrefix = "https://www.mycryptoheroes.net/metadata/land/";

  mapping(uint16 => uint256) private landTypeToTotalVolume;
  mapping(uint16 => uint256) private landTypeToSectorSupplyLimit;
  mapping(uint16 => mapping(uint16 => uint256)) private landTypeAndRarityToSectorSupply;
  mapping(uint16 => uint256[]) private landTypeToLandSectorList;
  mapping(uint16 => uint256) private landTypeToLandSectorIndex;
  mapping(uint16 => mapping(uint16 => uint256)) private landTypeAndRarityToLandSectorCount;
  mapping(uint16 => uint256) private rarityToSectorVolume;

  mapping(uint256 => bool) private allowed;

  event MintEvent(
    address indexed assetOwner,
    uint256 tokenId,
    uint256 at,
    bytes32 indexed eventHash
  );

  constructor() public ERC721Full("MyCryptoHeroes:Land", "MCHL") {
    rarityToSectorVolume[5] = 100;
    rarityToSectorVolume[4] = 20;
    rarityToSectorVolume[3] = 5;
    rarityToSectorVolume[2] = 2;
    rarityToSectorVolume[1] = 1;
    landTypeToTotalVolume[NO_LAND] = 0;
  }

  function setSupplyAndSector(
    uint16 _landType,
    uint256 _totalVolume,
    uint256 _sectorSupplyLimit,
    uint256 legendarySupply,
    uint256 epicSupply,
    uint256 rareSupply,
    uint256 uncommonSupply,
    uint256 commonSupply
  ) external onlyMinter {
    require(_landType != 0, "landType 0 is noland");
    require(_totalVolume != 0, "totalVolume must not be 0");
    require(getMintedSectorCount(_landType) == 0, "This LandType already exists");
    require(
      legendarySupply.mul(rarityToSectorVolume[LEGENDARY_RARITY])
      .add(epicSupply.mul(rarityToSectorVolume[EPIC_RARITY]))
      .add(rareSupply.mul(rarityToSectorVolume[RARE_RARITY]))
      .add(uncommonSupply.mul(rarityToSectorVolume[UNCOMMON_RARITY]))
      .add(commonSupply.mul(rarityToSectorVolume[COMMON_RARITY]))
      == _totalVolume
    );
    require(
      legendarySupply
      .add(epicSupply)
      .add(rareSupply)
      .add(uncommonSupply)
      .add(commonSupply)
      == _sectorSupplyLimit
    );
    landTypeToTotalVolume[_landType] = _totalVolume;
    landTypeToSectorSupplyLimit[_landType] = _sectorSupplyLimit;
    landTypeAndRarityToSectorSupply[_landType][LEGENDARY_RARITY] = legendarySupply;
    landTypeAndRarityToSectorSupply[_landType][EPIC_RARITY] = epicSupply;
    landTypeAndRarityToSectorSupply[_landType][RARE_RARITY] = rareSupply;
    landTypeAndRarityToSectorSupply[_landType][UNCOMMON_RARITY] = uncommonSupply;
    landTypeAndRarityToSectorSupply[_landType][COMMON_RARITY] = commonSupply;
  }

  function approve(address _to, uint256 _tokenId) public {
    require(allowed[_tokenId]);
    super.approve(_to, _tokenId);
  }

  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(allowed[_tokenId]);
    super.transferFrom(_from, _to, _tokenId);
  }

  function unLockToken(uint256 _tokenId) public onlyMinter {
    allowed[_tokenId] = true;
  }

  function setTokenURIPrefix(string calldata _tokenURIPrefix) external onlyMinter {
    tokenURIPrefix = _tokenURIPrefix;
  }

  function isAlreadyMinted(uint256 _tokenId) public view returns (bool) {
    return _exists(_tokenId);
  }

  function isValidLandSector(uint256 _tokenId) public view returns (bool) {
    uint16 rarity = getRarity(_tokenId);
    if (!(rarityToSectorVolume[rarity] > 0)) {
      return false;
    }
    uint16 landType = getLandType(_tokenId);
    if (!(landTypeToTotalVolume[landType] > 0)) {
      return false;
    }
    uint256 serial = _tokenId % 10000;
    if (serial == 0) {
      return false;
    }
    if (serial > landTypeAndRarityToSectorSupply[landType][rarity]) {
      return false;
    }
    return true;
  }

  function canTransfer(uint256 _tokenId) public view returns (bool) {
    return allowed[_tokenId];
  }

  function getTotalVolume(uint16 _landType) public view returns (uint256) {
    return landTypeToTotalVolume[_landType];
  }

  function getSectorSupplyLimit(uint16 _landType) public view returns (uint256) {
    return landTypeToSectorSupplyLimit[_landType];
  }

  function getLandType(uint256 _landSector) public view returns (uint16) {
    uint16 _landType = uint16((_landSector.div(10000)) % 1000);
    return _landType;
  }

  function getRarity(uint256 _landSector) public view returns (uint16) {
    return uint16(_landSector.div(10**7));
  }

  function getMintedSectorCount(uint16 _landType) public view returns (uint256) {
    return landTypeToLandSectorIndex[_landType];
  }

  function getMintedSectorCountByRarity(uint16 _landType, uint16 _rarity) public view returns (uint256) {
    return landTypeAndRarityToLandSectorCount[_landType][_rarity];
  }

  function getSectorSupplyByRarity(uint16 _landType, uint16 _rarity) public view returns (uint256) {
    return landTypeAndRarityToSectorSupply[_landType][_rarity];
  }

  function getMintedSectorList(uint16 _landType) public view returns (uint256[] memory) {
    return landTypeToLandSectorList[_landType];
  }

  function getSectorVolumeByRarity(uint16 _rarity) public view returns (uint256) {
    return rarityToSectorVolume[_rarity];
  }

  function getShareRateWithDecimal(uint256 _landSector) public view returns (uint256, uint256) {
    return (
      getSectorVolumeByRarity(getRarity(_landSector))
        .mul(SHARE_RATE_DECIMAL)
        .div(getTotalVolume(getLandType(_landSector))),
      SHARE_RATE_DECIMAL
    );
  }

  function mintLandSector(address _owner, uint256 _landSector, bytes32 _eventHash) public onlyMinter {
    require(!isAlreadyMinted(_landSector));
    require(isValidLandSector(_landSector));
    uint16 _landType = getLandType(_landSector);
    require(landTypeToLandSectorIndex[_landType] < landTypeToSectorSupplyLimit[_landType]);
    uint16 rarity = getRarity(_landSector);
    require(landTypeAndRarityToLandSectorCount[_landType][rarity] < landTypeAndRarityToSectorSupply[_landType][rarity], "supply over");
    _mint(_owner, _landSector);
    landTypeToLandSectorList[_landType].push(_landSector);
    landTypeToLandSectorIndex[_landType]++;
    landTypeAndRarityToLandSectorCount[_landType][rarity]++;

    emit MintEvent(
      _owner,
      _landSector,
      block.timestamp,
      _eventHash
    );
  }

  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    bytes32 tokenIdBytes;
    if (_tokenId == 0) {
      tokenIdBytes = "0";
    } else {
      uint256 value = _tokenId;
      while (value > 0) {
        tokenIdBytes = bytes32(uint256(tokenIdBytes) / (2 ** 8));
        tokenIdBytes |= bytes32(((value % 10) + 48) * 2 ** (8 * 31));
        value /= 10;
      }
    }

    bytes memory prefixBytes = bytes(tokenURIPrefix);
    bytes memory tokenURIBytes = new bytes(prefixBytes.length + tokenIdBytes.length);

    uint8 i;
    uint8 index = 0;

    for (i = 0; i < prefixBytes.length; i++) {
      tokenURIBytes[index] = prefixBytes[i];
      index++;
    }

    for (i = 0; i < tokenIdBytes.length; i++) {
      tokenURIBytes[index] = tokenIdBytes[i];
      index++;
    }

    return string(tokenURIBytes);
  }
}
 