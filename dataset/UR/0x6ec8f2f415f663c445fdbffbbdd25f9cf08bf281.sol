 

pragma solidity ^0.5.2;

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

contract Withdrawable is Ownable {
  function withdrawEther() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function withdrawToken(IERC20 _token) external onlyOwner {
    require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
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

 

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

contract DJTBase is Withdrawable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
}

 

 

library ECDSA {
     
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(hash, v, r, s);
        }
    }

     
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
         
         
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }
}

 

 
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
    if (serial > landTypeAndRarityToSectorSupply[landType][rarity]) {
      return false;
    }
    return true;
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

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    bytes32 tokenIdBytes;
    if (tokenId == 0) {
      tokenIdBytes = "0";
    } else {
      uint256 value = tokenId;
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
 

 

 
pragma solidity 0.5.4;







contract MCHLandPool is Ownable, Pausable, ReentrancyGuard {
  using SafeMath for uint256;


  LandSectorAsset public landSectorAsset;

  mapping(uint16 => uint256) private landTypeToTotalAmount;
  mapping(uint256 => uint256) private landSectorToWithdrawnAmount;
  mapping(address => bool) private allowedAddresses;

  event EthAddedToPool(
    uint16 indexed landType,
    address txSender,
    address indexed purchaseBy,
    uint256 value,
    uint256 at
  );

  event WithdrawEther(
    uint256 indexed landSector,
    address indexed lord,
    uint256 value,
    uint256 at
  );

  event AllowedAddressSet(
    address allowedAddress,
    bool allowedStatus
  );

  constructor(address _landSectorAssetAddress) public {
    landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
  }

  function setLandSectorAssetAddress(address _landSectorAssetAddress) external onlyOwner() {
    landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
  }

  function setAllowedAddress(address _address, bool desired) external onlyOwner() {
    allowedAddresses[_address] = desired;
    emit AllowedAddressSet(
      _address,
      desired
    );
  }

  function addEthToLandPool(uint16 _landType, address _purchaseBy) external payable whenNotPaused() nonReentrant() {
    require(landSectorAsset.getTotalVolume(_landType) > 0);
    require(allowedAddresses[msg.sender]);
    landTypeToTotalAmount[_landType] += msg.value;

    emit EthAddedToPool(
      _landType,
      msg.sender,
      _purchaseBy,
      msg.value,
      block.timestamp
    );
  }

  function withdrawMyAllRewards() external whenNotPaused() nonReentrant() {
    require(getWithdrawableBalance(msg.sender) > 0);

    uint256 withdrawValue;
    uint256 balance = landSectorAsset.balanceOf(msg.sender);
    
    for (uint256 i=balance; i > 0; i--) {
      uint256 landSector = landSectorAsset.tokenOfOwnerByIndex(msg.sender, i-1);
      uint256 tmpAmount = getLandSectorWithdrawableBalance(landSector);
      withdrawValue += tmpAmount;
      landSectorToWithdrawnAmount[landSector] += tmpAmount;

      emit WithdrawEther(
        landSector,
        msg.sender,
        tmpAmount,
        block.timestamp
      );
    }
    msg.sender.transfer(withdrawValue);
  }

  function withdrawMyReward(uint256 _landSector) external whenNotPaused() nonReentrant() {
    require(landSectorAsset.ownerOf(_landSector) == msg.sender);
    uint256 withdrawableAmount = getLandSectorWithdrawableBalance(_landSector);
    require(withdrawableAmount > 0);

    landSectorToWithdrawnAmount[_landSector] += withdrawableAmount;
    msg.sender.transfer(withdrawableAmount);

    emit WithdrawEther(
      _landSector,
      msg.sender,
      withdrawableAmount,
      block.timestamp
    );
  }

  function getAllowedAddress(address _address) public view returns (bool) {
    return allowedAddresses[_address];
  }

  function getTotalEthBackAmountPerLandType(uint16 _landType) public view returns (uint256) {
    return landTypeToTotalAmount[_landType];
  }

  function getLandSectorWithdrawnAmount(uint256 _landSector) public view returns (uint256) {
    return landSectorToWithdrawnAmount[_landSector];
  }

  function getLandSectorWithdrawableBalance(uint256 _landSector) public view returns (uint256) {
    require(landSectorAsset.isValidLandSector(_landSector));
    uint16 _landType = landSectorAsset.getLandType(_landSector);
    (uint256 shareRate, uint256 decimal) = landSectorAsset.getShareRateWithDecimal(_landSector);
    uint256 maxAmount = landTypeToTotalAmount[_landType]
      .mul(shareRate)
      .div(decimal);
    return maxAmount.sub(landSectorToWithdrawnAmount[_landSector]);
  }

  function getWithdrawableBalance(address _lordAddress) public view returns (uint256) {
    uint256 balance = landSectorAsset.balanceOf(_lordAddress);
    uint256 withdrawableAmount;

    for (uint256 i=balance; i > 0; i--) {
      uint256 landSector = landSectorAsset.tokenOfOwnerByIndex(_lordAddress, i-1);
      withdrawableAmount += getLandSectorWithdrawableBalance(landSector);
    }

    return withdrawableAmount;
  }
}
 

 

contract OperatorRole is Ownable {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    constructor() public {
        operators.add(msg.sender);
    }

    modifier onlyOperator() {
        require(isOperator(msg.sender));
        _;
    }
    
    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function addOperator(address account) public onlyOwner() {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function removeOperator(address account) public onlyOwner() {
        operators.remove(account);
        emit OperatorRemoved(account);
    }

}

 

contract Referrers is OperatorRole {
  using Roles for Roles.Role;

  event ReferrerAdded(address indexed account);
  event ReferrerRemoved(address indexed account);

  Roles.Role private referrers;

  uint32 internal index;
  uint16 public constant limit = 10;
  mapping(uint32 => address) internal indexToAddress;
  mapping(address => uint32) internal addressToIndex;

  modifier onlyReferrer() {
    require(isReferrer(msg.sender));
    _;
  }

  function getNumberOfAddresses() public view onlyOperator() returns (uint32) {
    return index;
  }

  function addressOfIndex(uint32 _index) onlyOperator() public view returns (address) {
    return indexToAddress[_index];
  }
  
  function isReferrer(address _account) public view returns (bool) {
    return referrers.has(_account);
  }

  function addReferrer(address _account) public onlyOperator() {
    referrers.add(_account);
    indexToAddress[index] = _account;
    addressToIndex[_account] = index;
    index++;
    emit ReferrerAdded(_account);
  }

  function addReferrers(address[limit] memory accounts) public onlyOperator() {
    for (uint16 i=0; i<limit; i++) {
      if (accounts[i] != address(0x0)) {
        addReferrer(accounts[i]);
      }
    }
  }

  function removeReferrer(address _account) public onlyOperator() {
    referrers.remove(_account);
    indexToAddress[addressToIndex[_account]] = address(0x0);
    emit ReferrerRemoved(_account);
  }
}

 

 

pragma solidity ^0.5.2;







contract MCHGUMGatewayV6 is DJTBase {

  LandSectorAsset public landSectorAsset;
  MCHLandPool public landPool;
  Referrers public referrers;
  address public validater;
  bool public isInGUMUpTerm;

  uint256 public landPercentage;
  uint256 internal referralPercentage;

  mapping(uint256 => bool) private payableOption;

   
   
   
   
   
   
  uint8 public purchaseTypeNormal = 0;
   
  uint8 public purchaseTypeGUMUP;
   

  event LandPercentageUpdated(
    uint256 landPercentage
  );

  event Sold(
    address indexed user,
    address indexed referrer,
    uint8 purchaseType,
    uint256 grossValue,
    uint256 referralValue,
    uint256 landValue,
    uint256 netValue,
    uint256 indexed landType,
    uint256 at
  );

  event GUMUpTermUpdated(
    bool isInGUMUpTerm
  );

  event PurchaseTypeGUMUPUpdated(
    uint8 purchaseTypeGUMUP
  );

  constructor(
    address _validater,
    address _referrersAddress
  ) public {
    validater = _validater;
    referrers = Referrers(_referrersAddress);
    landPercentage = 30;
    referralPercentage = 20;
    purchaseTypeGUMUP = 2;
    payableOption[0.05 ether] = true;
    payableOption[0.1 ether] = true;
    payableOption[0.5 ether] = true;
    payableOption[1 ether] = true;
    payableOption[5 ether] = true;
    payableOption[10 ether] = true;
  }

  function setLandSectorAssetAddress(address _landSectorAssetAddress) external onlyOwner() {
    landSectorAsset = LandSectorAsset(_landSectorAssetAddress);
  }

  function setLandPoolAddress(address payable _landPoolAddress) external onlyOwner() {
    landPool = MCHLandPool(_landPoolAddress);
  }

  function setValidater(address _varidater) external onlyOwner() {
    validater = _varidater;
  }

  function updateLandPercentage(uint256 _newLandPercentage) external onlyOwner() {
    landPercentage = _newLandPercentage;
    emit LandPercentageUpdated(
      landPercentage
    );
  }

  function setReferrersContractAddress(address _referrersAddress) external onlyOwner() {
    referrers = Referrers(_referrersAddress);
  }

  function setPurchaseTypeGUMUP(uint8 _newNum) external onlyOwner() {
    require(_newNum != 0 || _newNum != 1 || _newNum != 3);
    purchaseTypeGUMUP = _newNum;
    emit PurchaseTypeGUMUPUpdated(
      purchaseTypeGUMUP
    );
  }

  function setGUMUpTerm(bool _desired) external onlyOwner() {
    isInGUMUpTerm = _desired;
    emit GUMUpTermUpdated(
      isInGUMUpTerm
    );
  }

  function updateReferralPercentage(uint256 _newReferralPercentage) external onlyOwner() {
    referralPercentage = _newReferralPercentage;
  }

  function setPayableOption(uint256 _option, bool desired) external onlyOwner() {
    payableOption[_option] = desired;
  }

  function buyGUM(uint16 _landType, address payable _referrer, bytes calldata _signature) external payable whenNotPaused() nonReentrant() {
    require(payableOption[msg.value]);
    require(validateSig(_signature, _landType), "invalid signature");

     
    address payable referrer;
    if (_referrer == msg.sender) {
      referrer = address(0x0);
    } else {
      referrer = _referrer;
    }

    uint256 netValue = msg.value;
    uint256 referralValue;
    uint256 landValue;
    if ((_referrer != address(0x0)) && referrers.isReferrer(_referrer)) {
      referralValue = msg.value.mul(referralPercentage).div(100);
      netValue = netValue.sub(referralValue);
      _referrer.transfer(referralValue);
    }

    if (landSectorAsset.getTotalVolume(_landType) != 0) {
      landValue = msg.value.mul(landPercentage).div(100);
      netValue = netValue.sub(landValue);
      landPool.addEthToLandPool.value(landValue)(_landType, msg.sender);
    }

    uint8 purchaseType;
    purchaseType = purchaseTypeNormal;
    if (isInGUMUpTerm) {
      purchaseType = purchaseTypeGUMUP;
    }

    emit Sold(
      msg.sender,
      referrer,
      purchaseType,
      msg.value,
      referralValue,
      landValue,
      netValue,
      _landType,
      block.timestamp
    );
  }

  function getPayableOption(uint256 _option) public view returns (bool) {
    return payableOption[_option];
  }

  function validateSig(bytes memory _signature, uint16 _landType) private view returns (bool) {
    require(validater != address(0));
    uint256 _message = uint256(msg.sender) + uint256(_landType);
    address signer = ECDSA.recover(ECDSA.toEthSignedMessageHash(bytes32(_message)), _signature);
    return (signer == validater);
  }
}
 