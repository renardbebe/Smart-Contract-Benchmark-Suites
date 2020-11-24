 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

 

pragma solidity ^0.5.0;



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
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

 

pragma solidity ^0.5.0;



 
contract Pausable is Context, PauserRole {
     
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
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

     
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

 

pragma solidity ^0.5.0;


 
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

     
    function balanceOf(address owner) public view returns (uint256 balance);

     
    function ownerOf(uint256 tokenId) public view returns (address owner);

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
     
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 

pragma solidity ^0.5.0;


 
library Counters {
    using SafeMath for uint256;

    struct Counter {
         
         
         
        uint256 _value;  
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

 

pragma solidity ^0.5.0;


 
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
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

 

pragma solidity ^0.5.0;








 
contract ERC721 is Context, ERC165, IERC721 {
    using SafeMath for uint256;
    using Address for address;
    using Counters for Counters.Counter;

     
     
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

     
    mapping (uint256 => address) private _tokenOwner;

     
    mapping (uint256 => address) private _tokenApprovals;

     
    mapping (address => Counters.Counter) private _ownedTokensCount;

     
    mapping (address => mapping (address => bool)) private _operatorApprovals;

     
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721);
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _ownedTokensCount[owner].current();
    }

     
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _tokenOwner[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");

        return owner;
    }

     
    function approve(address to, uint256 tokenId) public {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

     
    function getApproved(uint256 tokenId) public view returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

     
    function setApprovalForAll(address to, bool approved) public {
        require(to != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][to] = approved;
        emit ApprovalForAll(_msgSender(), to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public {
         
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransferFrom(from, to, tokenId, _data);
    }

     
    function _safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) internal {
        _transferFrom(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _exists(uint256 tokenId) internal view returns (bool) {
        address owner = _tokenOwner[tokenId];
        return owner != address(0);
    }

     
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

     
    function _safeMint(address to, uint256 tokenId) internal {
        _safeMint(to, tokenId, "");
    }

     
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

     
    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _tokenOwner[tokenId] = to;
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner, "ERC721: burn of token that is not own");

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
        _tokenOwner[tokenId] = address(0);

        emit Transfer(owner, address(0), tokenId);
    }

     
    function _burn(uint256 tokenId) internal {
        _burn(ownerOf(tokenId), tokenId);
    }

     
    function _transferFrom(address from, address to, uint256 tokenId) internal {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _clearApproval(tokenId);

        _ownedTokensCount[from].decrement();
        _ownedTokensCount[to].increment();

        _tokenOwner[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

     
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        internal returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }

        bytes4 retval = IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data);
        return (retval == _ERC721_RECEIVED);
    }

     
    function _clearApproval(uint256 tokenId) private {
        if (_tokenApprovals[tokenId] != address(0)) {
            _tokenApprovals[tokenId] = address(0);
        }
    }
}

 

pragma solidity ^0.5.0;


 
contract IERC721Enumerable is IERC721 {
    function totalSupply() public view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) public view returns (uint256);
}

 

pragma solidity ^0.5.0;





 
contract ERC721Enumerable is Context, ERC165, ERC721, IERC721Enumerable {
     
    mapping(address => uint256[]) private _ownedTokens;

     
    mapping(uint256 => uint256) private _ownedTokensIndex;

     
    uint256[] private _allTokens;

     
    mapping(uint256 => uint256) private _allTokensIndex;

     
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

     
    constructor () public {
         
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

     
    function tokenOfOwnerByIndex(address owner, uint256 index) public view returns (uint256) {
        require(index < balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

     
    function totalSupply() public view returns (uint256) {
        return _allTokens.length;
    }

     
    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
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

 

pragma solidity ^0.5.0;


 
contract IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

 

pragma solidity ^0.5.0;





contract ERC721Metadata is Context, ERC165, ERC721, IERC721Metadata {
     
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
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        return _tokenURIs[tokenId];
    }

     
    function _setTokenURI(uint256 tokenId, string memory uri) internal {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = uri;
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        super._burn(owner, tokenId);

         
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

 

pragma solidity ^0.5.0;




 
contract ERC721Full is ERC721, ERC721Enumerable, ERC721Metadata {
    constructor (string memory name, string memory symbol) public ERC721Metadata(name, symbol) {
         
    }
}

 

pragma solidity ^0.5.0;



contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
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

 

pragma solidity ^0.5.0;



 
contract ERC721Mintable is ERC721, MinterRole {
     
    function mint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _mint(to, tokenId);
        return true;
    }

     
    function safeMint(address to, uint256 tokenId) public onlyMinter returns (bool) {
        _safeMint(to, tokenId);
        return true;
    }

     
    function safeMint(address to, uint256 tokenId, bytes memory _data) public onlyMinter returns (bool) {
        _safeMint(to, tokenId, _data);
        return true;
    }
}

 

pragma solidity ^0.5.0;



 
contract ERC721Pausable is ERC721, Pausable {
    function approve(address to, uint256 tokenId) public whenNotPaused {
        super.approve(to, tokenId);
    }

    function setApprovalForAll(address to, bool approved) public whenNotPaused {
        super.setApprovalForAll(to, approved);
    }

    function _transferFrom(address from, address to, uint256 tokenId) internal whenNotPaused {
        super._transferFrom(from, to, tokenId);
    }
}

 

pragma solidity ^0.5.5;




contract GuildAsset is ERC721Full, ERC721Mintable, ERC721Pausable {

    uint16 public constant GUILD_TYPE_OFFSET = 10000;
    uint16 public constant GUILD_RARITY_OFFSET = 1000;
    uint256 public constant SHARE_RATE_DECIMAL = 10**18;

    uint16 public constant LEGENDARY_RARITY = 3;
    uint16 public constant GOLD_RARITY = 2;
    uint16 public constant SILVER_RARITY = 1;

    uint16 public constant NO_GUILD = 0;

    string public tokenURIPrefix = "https://cryptospells.jp/metadata/guild/";

    mapping(uint16 => uint256) private guildTypeToTotalVolume;
    mapping(uint16 => uint256) private guildTypeToStockSupplyLimit;
    mapping(uint16 => mapping(uint16 => uint256)) private guildTypeAndRarityToStockSupply;
    mapping(uint16 => uint256[]) private guildTypeToGuildStockList;
    mapping(uint16 => uint256) private guildTypeToGuildStockIndex;
    mapping(uint16 => mapping(uint16 => uint256)) private guildTypeAndRarityToGuildStockCount;
    mapping(uint16 => uint256) private rarityToStockVolume;

     
     

    constructor() ERC721Full("CryptoSpells:Guild", "CSPL") public {
      rarityToStockVolume[LEGENDARY_RARITY] = 100;
      rarityToStockVolume[GOLD_RARITY] = 10;
      rarityToStockVolume[SILVER_RARITY] = 1;
      guildTypeToTotalVolume[NO_GUILD] = 0;
    }

    function setSupplyAndStock(
      uint16 _guildType,  
      uint256 _totalVolume,
      uint256 _stockSupplyLimit,
      uint256 legendarySupply,
      uint256 goldSupply,
      uint256 silverSupply
    ) external onlyMinter {
      require(_guildType != 0, "guildType 0 is noguild");
      require(_totalVolume != 0, "totalVolume must not be 0");
       
      require(
        legendarySupply.mul(rarityToStockVolume[LEGENDARY_RARITY])
        .add(goldSupply.mul(rarityToStockVolume[GOLD_RARITY]))
        .add(silverSupply.mul(rarityToStockVolume[SILVER_RARITY]))
        == _totalVolume
      );
      require(
        legendarySupply
        .add(goldSupply)
        .add(silverSupply)
        == _stockSupplyLimit
      );
      guildTypeToTotalVolume[_guildType] = _totalVolume;
      guildTypeToStockSupplyLimit[_guildType] = _stockSupplyLimit;
      guildTypeAndRarityToStockSupply[_guildType][LEGENDARY_RARITY] = legendarySupply;
      guildTypeAndRarityToStockSupply[_guildType][GOLD_RARITY] = goldSupply;
      guildTypeAndRarityToStockSupply[_guildType][SILVER_RARITY] = silverSupply;
    }

     

     
     

    function isAlreadyMinted(uint256 _tokenId) public view returns (bool) {
      return _exists(_tokenId);
    }

    function isValidGuildStock(uint256 _guildTokenId) public view {

      uint16 rarity = getRarity(_guildTokenId);
      require((rarityToStockVolume[rarity] > 0), "invalid rarityToStockVolume");

      uint16 guildType = getGuildType(_guildTokenId);
      require((guildTypeToTotalVolume[guildType] > 0), "invalid guildTypeToTotalVolume");

      uint256 serial = _guildTokenId % GUILD_TYPE_OFFSET;
      require(serial != 0, "invalid serial zero");
      require(serial <= guildTypeAndRarityToStockSupply[guildType][rarity], "invalid serial guildTypeAndRarityToStockSupply");
    }

    function getTotalVolume(uint16 _guildType) public view returns (uint256) {
      return guildTypeToTotalVolume[_guildType];
    }

    function getStockSupplyLimit(uint16 _guildType) public view returns (uint256) {
      return guildTypeToStockSupplyLimit[_guildType];
    }

    function getGuildType(uint256 _guildTokenId) public view returns (uint16) {
      uint16 _guildType = uint16((_guildTokenId.div(GUILD_TYPE_OFFSET)) % GUILD_RARITY_OFFSET);
      return _guildType;
    }

    function getRarity(uint256 _guildTokenId) public view returns (uint16) {
      return uint16(_guildTokenId.div(GUILD_TYPE_OFFSET).div(GUILD_RARITY_OFFSET) % 10);
    }

    function getMintedStockCount(uint16 _guildType) public view returns (uint256) {
      return guildTypeToGuildStockIndex[_guildType];
    }

    function getMintedStockCountByRarity(uint16 _guildType, uint16 _rarity) public view returns (uint256) {
      return guildTypeAndRarityToGuildStockCount[_guildType][_rarity];
    }

    function getStockSupplyByRarity(uint16 _guildType, uint16 _rarity) public view returns (uint256) {
      return guildTypeAndRarityToStockSupply[_guildType][_rarity];
    }

    function getMintedStockList(uint16 _guildType) public view returns (uint256[] memory) {
      return guildTypeToGuildStockList[_guildType];
    }

    function getStockVolumeByRarity(uint16 _rarity) public view returns (uint256) {
      return rarityToStockVolume[_rarity];
    }

    function getShareRateWithDecimal(uint256 _guildTokenId) public view returns (uint256, uint256) {
      return (
        getStockVolumeByRarity(getRarity(_guildTokenId))
          .mul(SHARE_RATE_DECIMAL)
          .div(getTotalVolume(getGuildType(_guildTokenId))),
        SHARE_RATE_DECIMAL
      );
    }


 
    function setTokenURIPrefix(string calldata _tokenURIPrefix) external onlyMinter {
        tokenURIPrefix = _tokenURIPrefix;
    }
 
    function mintGuildStock(address _owner, uint256 _guildTokenId) public onlyMinter {
       
      require(!isAlreadyMinted(_guildTokenId), "is Already Minted");

       
      isValidGuildStock(_guildTokenId);

       
      uint16 _guildType = getGuildType(_guildTokenId);
      require(guildTypeToGuildStockIndex[_guildType] < guildTypeToStockSupplyLimit[_guildType]);
      uint16 rarity = getRarity(_guildTokenId);
      require(guildTypeAndRarityToGuildStockCount[_guildType][rarity] < guildTypeAndRarityToStockSupply[_guildType][rarity], "supply over");

      _mint(_owner, _guildTokenId);
      guildTypeToGuildStockList[_guildType].push(_guildTokenId);
      guildTypeToGuildStockIndex[_guildType]++;
      guildTypeAndRarityToGuildStockCount[_guildType][rarity]++;
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

 

pragma solidity ^0.5.5;




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

contract CSPLGuildPool is Ownable, Pausable, ReentrancyGuard {

  GuildAsset public guildAsset;

   
  mapping(uint16 => uint256) private guildTypeToTotalAmount;
   
  mapping(uint256 => uint256) private guildStockToWithdrawnAmount;
   
  mapping(address => bool) private allowedAddresses;

  event EthAddedToPool(
    uint16 indexed guildType,
    address txSender,
    address indexed purchaseBy,
    uint256 value,
    uint256 at
  );

  event WithdrawEther(
    uint256 indexed guildTokenId,
    address indexed owner,
    uint256 value,
    uint256 at
  );

  event AllowedAddressSet(
    address allowedAddress,
    bool allowedStatus
  );

  constructor(address _guildAssetAddress) public {
    guildAsset = GuildAsset(_guildAssetAddress);
  }

   
  function setGuildAssetAddress(address _guildAssetAddress) external onlyOwner() {
    guildAsset = GuildAsset(_guildAssetAddress);
  }

   
  function getAllowedAddress(address _address) public view returns (bool) {
    return allowedAddresses[_address];
  }

  function setAllowedAddress(address _address, bool desired) external onlyOwner() {
    allowedAddresses[_address] = desired;
  }

  function getGuildStockWithdrawnAmount(uint256 _guildTokenId) public view returns (uint256) {
    return guildStockToWithdrawnAmount[_guildTokenId];
  }

  function getGuildTypeToTotalAmount(uint16 _guildType) public view returns (uint256) {
    return guildTypeToTotalAmount[_guildType];
  }

   
   
  function addEthToGuildPool(uint16 _guildType, address _purchaseBy) external payable whenNotPaused() nonReentrant() {
   
    require(guildAsset.getTotalVolume(_guildType) > 0);
    require(allowedAddresses[msg.sender]);
    guildTypeToTotalAmount[_guildType] += msg.value;

    emit EthAddedToPool(
      _guildType,
      msg.sender,
      _purchaseBy,
      msg.value,
      block.timestamp
    );
  }

  function withdrawMyAllRewards() external whenNotPaused() nonReentrant() {
    require(getWithdrawableBalance(msg.sender) > 0);

    uint256 withdrawValue;
    uint256 balance = guildAsset.balanceOf(msg.sender);

    for (uint256 i=balance; i > 0; i--) {
      uint256 guildStock = guildAsset.tokenOfOwnerByIndex(msg.sender, i-1);
      uint256 tmpAmount = getGuildStockWithdrawableBalance(guildStock);
      withdrawValue += tmpAmount;
      guildStockToWithdrawnAmount[guildStock] += tmpAmount;

      emit WithdrawEther(
        guildStock,
        msg.sender,
        tmpAmount,
        block.timestamp
      );
    }
    msg.sender.transfer(withdrawValue);
  }

   
  function withdrawMyReward(uint256 _guildTokenId) external whenNotPaused() nonReentrant() {
    require(guildAsset.ownerOf(_guildTokenId) == msg.sender);
    uint256 withdrawableAmount = getGuildStockWithdrawableBalance(_guildTokenId);
    require(withdrawableAmount > 0);

    guildStockToWithdrawnAmount[_guildTokenId] += withdrawableAmount;
    msg.sender.transfer(withdrawableAmount);

    emit WithdrawEther(
      _guildTokenId,
      msg.sender,
      withdrawableAmount,
      block.timestamp
    );
  }

   
   
  function getGuildStockWithdrawableBalance(uint256 _guildTokenId) public view returns (uint256) {
    guildAsset.isValidGuildStock(_guildTokenId);

    uint16 _guildType = guildAsset.getGuildType(_guildTokenId);
    (uint256 shareRate, uint256 decimal) = guildAsset.getShareRateWithDecimal(_guildTokenId);
    uint256 maxAmount = guildTypeToTotalAmount[_guildType] * shareRate / decimal;
    return maxAmount - guildStockToWithdrawnAmount[_guildTokenId];
  }

   
  function getWithdrawableBalance(address _ownerAddress) public view returns (uint256) {
    uint256 balance = guildAsset.balanceOf(_ownerAddress);
    uint256 withdrawableAmount;

    for (uint256 i=balance; i > 0; i--) {
      uint256 guildTokenId = guildAsset.tokenOfOwnerByIndex(_ownerAddress, i-1);
      withdrawableAmount += getGuildStockWithdrawableBalance(guildTokenId);
    }

    return withdrawableAmount;
  }

}
 

 

pragma solidity ^0.5.5;







contract Withdrawable is Ownable {
  function withdrawEther() external onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

  function withdrawToken(IERC20 _token) external onlyOwner {
    require(_token.transfer(msg.sender, _token.balanceOf(address(this))));
  }
}

contract DJTBase is Withdrawable, Pausable, ReentrancyGuard {
    using SafeMath for uint256;
}
contract CSPLSPLGatewayV11 is DJTBase {

  struct Campaign {
    uint256 since;
    uint256 until;
    uint8 purchaseType;
  }

  Campaign public campaign;

  mapping(uint256 => bool) public payableOptions;

  GuildAsset public guildAsset;
  CSPLGuildPool public guildPool;

  uint256 public guildPercentage;

  event Sold(
    address indexed user,
    address indexed referrer,
    uint8 purchaseType,
    uint256 grossValue,
    uint256 referralValue,
    uint256 guildValue,
    uint256 netValue,
    uint16 indexed guildType,
    int64 at
  );

  event CampaignUpdated(
    uint256 since,
    uint256 until,
    uint8 purchaseType
  );

  event Updated(
    uint256 guildPercentage
  );

  constructor(
    address _guildAssetAddress,
    address _guildPoolAddress
  ) public payable {
    guildAsset = GuildAsset(_guildAssetAddress);
    guildPool = CSPLGuildPool(_guildPoolAddress);

    campaign = Campaign(0, 0, 0);
    guildPercentage = 15;

    payableOptions[0.05 ether] = true;
    payableOptions[0.1 ether] = true;
    payableOptions[0.5 ether] = true;
    payableOptions[1 ether] = true;
    payableOptions[5 ether] = true;
    payableOptions[10 ether] = true;
  }

  function setPayableOption(uint256 _option, bool desired) external onlyOwner() {
    payableOptions[_option] = desired;
  }

  function setCampaign(uint256 _since, uint256 _until, uint8 _purchaseType) external onlyOwner() {
    campaign = Campaign(_since, _until, _purchaseType);
    emit CampaignUpdated(_since, _until, _purchaseType);
  }

  function setGuildAssetAddress(address _guildAssetAddress) external onlyOwner() {
    guildAsset = GuildAsset(_guildAssetAddress);
  }

  function setGuildPoolAddress(address payable _guildPoolAddress) external onlyOwner() {
    guildPool = CSPLGuildPool(_guildPoolAddress);
  }

  function update(uint256 _new) external onlyOwner() {
    guildPercentage = _new;
    emit Updated(
      guildPercentage
    );
  }

  function buySPL(
                  address payable _referrer,
                  uint256 _referralPercentage,
                  uint16 _guildType,
                  int64 _time
                  ) external payable whenNotPaused() {

    require(_referralPercentage + guildPercentage <= 100, "Invalid percentages");
    require(payableOptions[msg.value], "Invalid msg.value");

 
    uint256 referralValue = 0;
    uint256 guildValue = _guildPoolBack(_guildType);
     
 
    uint256 netValue = guildValue;

    emit Sold(
      msg.sender,
      _referrer,
      getPurchaseType(block.number),
      msg.value,
      referralValue,
      guildValue,
      netValue,
      _guildType,
      _time
    );
  }

  function getPurchaseType(uint256 _block) public view returns (uint8) {
     
     
     
     
     
    if(campaign.until < _block) {
      return 0;
    }
    if(campaign.since > _block) {
      return 0;
    }
    return campaign.purchaseType;
  }

  function _guildPoolBack(uint16 _guildType) internal returns (uint256) {
    if(_guildType == 0) {
      return 0;
    }

    require(guildAsset.getTotalVolume(_guildType) != 0, "Invalid _guildType");

    uint256 guildValue = msg.value.mul(guildPercentage).div(100);

    guildPool.addEthToGuildPool.value(guildValue)(_guildType, msg.sender);
    return guildValue;
  }

  function _referrerBack(address payable _referrer, uint256 _referralPercentage) internal returns (uint256) {
    if(_referrer == address(0x0) || _referrer == msg.sender) {
      return 0;
    }

    uint256 referralValue;
    referralValue = msg.value.mul(_referralPercentage).div(100);
    _referrer.transfer(referralValue);
    return referralValue;
  }

  function kill() external onlyOwner() {
    selfdestruct(msg.sender);
  }
}
 