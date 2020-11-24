 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
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

 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
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

library Strings {
    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory _concatenatedString) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        bytes memory babcde = new bytes(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        uint k = 0;
        uint i = 0;
        for (i = 0; i < _ba.length; i++) {
            babcde[k++] = _ba[i];
        }
        for (i = 0; i < _bb.length; i++) {
            babcde[k++] = _bb[i];
        }
        for (i = 0; i < _bc.length; i++) {
            babcde[k++] = _bc[i];
        }
        for (i = 0; i < _bd.length; i++) {
            babcde[k++] = _bd[i];
        }
        for (i = 0; i < _be.length; i++) {
            babcde[k++] = _be[i];
        }
        return string(babcde);
    }

    function strConcat(string  memory _a, string  memory _b, string  memory _c, string  memory _d) internal pure returns (string  memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string  memory _a, string  memory _b, string  memory _c) internal pure returns (string  memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string  memory _a, string  memory _b) internal pure returns (string  memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function split(bytes memory _base, uint8[] memory _lengths) internal pure returns (bytes[] memory arr) {
        uint _offset = 0;
        bytes[] memory splitArr = new bytes[](_lengths.length);

        for(uint i = 0; i < _lengths.length; i++) {
            bytes memory _tmpBytes = new bytes(_lengths[i]);

            for(uint j = 0; j < _lengths[i]; j++)
                _tmpBytes[j] = _base[_offset+j];

            splitArr[i] = _tmpBytes;
            _offset += _lengths[i];
        }

        return splitArr;
    }
}









 
contract DeltaTimeNFTBase is ERC165, IERC721, IERC721Metadata, Pausable, MinterRole {

    using SafeMath for uint256;
    using Address for address;
    using Strings for string;

    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
     

    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;
     

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    string private _name;

     
    string private _symbol;

     
    string private _baseTokenURI;

     
    bool private _ipfsMigrated;

     
    uint256 private _totalSupply;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping(uint256 => string) private _tokenURIs;

     
    mapping (uint256 => uint256) private _tokenProperties;

     
    mapping (address => uint256) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;


    event TokenURI(uint256 indexed tokenId, string uri);


     
    constructor (string memory name, string memory symbol, string memory baseTokenURI) public {
        _name = name;
        _symbol = symbol;
        _totalSupply = 0;
        _baseTokenURI = baseTokenURI;
        _ipfsMigrated = false;

         
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
    }

     
    function name() external view returns (string memory) {
        return _name;
    }

     
    function symbol() external view returns (string memory) {
        return _symbol;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function exists(uint256 tokenId) external view returns (bool) {
        return _exists(tokenId);
    }

     
    function ipfsMigrationDone() public onlyMinter {
        _ipfsMigrated = true;
    }

     
    function setTokenURI(uint256 tokenId, string memory uri) public onlyMinter {
        require(!_ipfsMigrated);
        _setTokenURI(tokenId, uri);
    }

     
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        require(_exists(tokenId));

        if (bytes(_tokenURIs[tokenId]).length > 0)
            return _tokenURIs[tokenId];

        return Strings.strConcat(baseTokenURI(),Strings.uint2str(tokenId));
    }

     
    function setBaseTokenURI(string memory baseTokenURI) public onlyMinter {
        _baseTokenURI = baseTokenURI;
    }

     
    function baseTokenURI() public view returns (string memory) {
        return _baseTokenURI;
    }

     
    function tokenProperties(uint256 tokenId) public view returns (uint256) {
        require(_exists(tokenId));
        return _tokenProperties[tokenId];
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

     
    function approve(address to, uint256 tokenId) public whenNotPaused {
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

     
    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        require(to != msg.sender);
        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public whenNotPaused {
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

     
    function mint(address to, uint256 tokenId, string memory uri, uint256 tokenProps)
        public onlyMinter
    {
        _mint(to, tokenId, uri, tokenProps);
        _totalSupply += 1;
    }

     
    function batchMint(
        address[] memory to,
        uint256[] memory tokenIds,
        bytes memory tokenURIs,
        uint8[] memory urisLengths,
        uint256[] memory tokenProps)
        public onlyMinter
    {
        require(tokenIds.length == to.length &&
                tokenIds.length == urisLengths.length &&
                tokenIds.length == tokenProps.length);
        bytes[] memory uris = Strings.split(tokenURIs, urisLengths);
        for (uint i = 0; i < tokenIds.length; i++) {
            _mint(to[i], tokenIds[i], string(uris[i]), tokenProps[i]);
        }
        _totalSupply += tokenIds.length;
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _mint(address to, uint256 tokenId, string memory uri, uint256 tokenProps) internal {
        require(to != address(0));
        require(!_exists(tokenId));

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to] = _ownedTokensCount[to].add(1);
        _setTokenURI(tokenId, uri);
        _tokenProperties[tokenId] = tokenProps;

        emit Transfer(address(0), to, tokenId);
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = uri;
        emit TokenURI(tokenId, uri);
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

contract DeltaTimeNFT is DeltaTimeNFTBase {

  constructor (string memory baseTokenURI) public DeltaTimeNFTBase("F1® Delta Time", "F1DT", baseTokenURI) {
  }

  function tokenType(uint256 tokenId) public view returns (uint256) {
      uint256 properties = tokenProperties(tokenId);
      return properties & 0xFF;
  }

  function tokenSubType(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFF << 8)) >> 8;
  }

  function tokenTeam(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFF << 16)) >> 16;
  }

  function tokenSeason(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFF << 24)) >> 24;
  }

  function tokenRarity(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFF << 32)) >> 32;
  }

  function tokenTrack(uint256 tokenId) public view returns (uint256) {
     
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFF << 40)) >> 40;
  }

  function tokenCollection(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 48)) >> 48;
  }

  function tokenDriverNumber(uint256 tokenId) public view returns (uint256) {
     
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 64)) >> 64;
  }

  function tokenRacingProperty1(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 80)) >> 80;
  }

  function tokenRacingProperty2(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 96)) >> 96;
  }

  function tokenRacingProperty3(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 112)) >> 112;
  }

  function tokenLuck(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 128)) >> 128;
  }

  function tokenEffect(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFF << 144)) >> 144;
  }

  function tokenSpecial1(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 152)) >> 152;
  }

  function tokenSpecial2(uint256 tokenId) public view returns (uint256) {
    uint256 properties = tokenProperties(tokenId);
    return (properties & (0xFFFF << 168)) >> 168;
  }
}