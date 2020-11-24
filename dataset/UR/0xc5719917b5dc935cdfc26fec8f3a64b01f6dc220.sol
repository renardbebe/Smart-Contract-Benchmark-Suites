 

 

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

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable;
     
    function transferFrom(address from, address to, uint256 tokenId) public payable;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public payable;
}

 

pragma solidity ^0.5.0;

 
contract IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes memory data)
    public returns (bytes4);
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
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







 
contract ERC721 is ERC165, IERC721 {
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

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
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
        require(to != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][to] = approved;
        emit ApprovalForAll(msg.sender, to, approved);
    }

     
    function isApprovedForAll(address owner, address operator) public view returns (bool) {
        return _operatorApprovals[owner][operator];
    }

     
    function transferFrom(address from, address to, uint256 tokenId) public payable {
         
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transferFrom(from, to, tokenId);
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
        safeTransferFrom(from, to, tokenId, "");
    }

     
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable {
        transferFrom(from, to, tokenId);
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

        bytes4 retval = IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data);
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

library ArrayUtils {
  function remove(address[] storage array, address deletedAddress) internal view returns (address[] memory) {
    address[] memory copy = new address[](array.length - 1);
    uint copyIndex = 0;
    for(uint i = 0; i < array.length; i++) {
      if(array[i] != deletedAddress) {
        copy[copyIndex] = array[i];
        copyIndex += 1;
      }
    }
    return copy;
  }
}

 

pragma solidity ^0.5.0;



 
contract AdminRole {
  using Roles for Roles.Role;
  using ArrayUtils for address[];

  event AdminAdded(address indexed account);
  event AdminRemoved(address indexed account);

  Roles.Role private _admins;
  address[] private _addresses;  

  constructor () internal {
    _addAdmin(msg.sender);
  }

  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "AdminRole: caller does not have the Admin role");
    _;
  }

  function addAdmin(address account) public onlyAdmin {
    _addAdmin(account);
  }

   
  function removeAdmin(address account) public onlyAdmin {
    require(_addresses.length > 1, "AdminRole should not be 0");  
    _removeAdmin(account);
  }

  function renounceAdmin() public {
    require(_addresses.length > 1, "AdminRole should not be 0");  
    _removeAdmin(msg.sender);
  }

   
  function getAdmin() public view onlyAdmin returns (address[] memory) {
    return _addresses;
  }

  function isAdmin(address account) internal view returns (bool) {
    return _admins.has(account);
  }

  function _addAdmin(address account) internal {
    _admins.add(account);
    _addresses.push(account);  
    emit AdminAdded(account);
  }

  function _removeAdmin(address account) internal {
    _admins.remove(account);
    _addresses = _addresses.remove(account);  
    emit AdminRemoved(account);
  }
}

 

pragma solidity ^0.5.0;




 
contract MinterRole is AdminRole {
  using Roles for Roles.Role;
  using ArrayUtils for address[];

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private _minters;
  address[] private _addresses;  

  constructor () internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
    _;
  }

  function addMinter(address account) public onlyAdmin {
    _addMinter(account);
  }

   
  function removeMinter(address account) public onlyAdmin {
    require(_addresses.length > 1, "MinterRole should not be 0");  
    _removeMinter(account);
  }

  function renounceMinter() public {
    require(_addresses.length > 1, "MinterRole should not be 0");  
    _removeMinter(msg.sender);
  }

   
  function getMinter() public view onlyMinter returns (address[] memory) {
    return _addresses;
  }

  function isMinter(address account) internal view returns (bool) {
    return _minters.has(account);
  }

  function _addMinter(address account) internal {
    _minters.add(account);
    _addresses.push(account);  
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    _minters.remove(account);
    _addresses = _addresses.remove(account);  
    emit MinterRemoved(account);
  }
}

 

pragma solidity ^0.5.0;




 
contract ModeratorRole is AdminRole {
  using Roles for Roles.Role;
  using ArrayUtils for address[];

  event ModeratorAdded(address indexed account);
  event ModeratorRemoved(address indexed account);

  Roles.Role private _moderators;
  address[] private _addresses;  

  constructor () internal {
    _addModerator(msg.sender);
  }

  modifier onlyModerator() {
    require(isModerator(msg.sender), "ModeratorRole: caller does not have the Moderator role");
    _;
  }

  function addModerator(address account) public onlyAdmin {
    _addModerator(account);
  }

   
  function removeModerator(address account) public onlyAdmin {
    _removeModerator(account);
  }

  function renounceModerator() public {
    _removeModerator(msg.sender);
  }

   
  function getModerator() public view onlyModerator returns (address[] memory) {
    return _addresses;
  }

  function isModerator(address account) internal view returns (bool) {
    return _moderators.has(account);
  }

  function _addModerator(address account) internal {
    _moderators.add(account);
    _addresses.push(account);  
    emit ModeratorAdded(account);
  }

  function _removeModerator(address account) internal {
    _moderators.remove(account);
    _addresses = _addresses.remove(account);  
    emit ModeratorRemoved(account);
  }
}

 

pragma solidity ^0.5.0;





 

contract CryptoCollectiveAsset is ERC721, ERC721Enumerable, ERC721Metadata, MinterRole, ModeratorRole {

  address payable private operatorAddress;
  uint256 private operatorRate;
  uint256 private streamerRate;
  uint256 private creatorRate;

  struct CryptoCollectiveAssetMeta {
    string name;
    string description;
    string streamer;
    string creator;
    address payable[] streamerAddresses;
    address payable[] creatorAddresses;
  }
  CryptoCollectiveAssetMeta[] private collections;

  constructor(uint256 initialRate) public ERC721Metadata("Apoitakara", "APOI") {
     
    operatorAddress = msg.sender;
    operatorRate = initialRate;
    streamerRate = initialRate;
    creatorRate = initialRate;
  }

   

  function mint(
    string calldata name,
    string calldata description,
    string calldata streamer,
    string calldata creator,
    address payable[] calldata streamerAddresses,
    address payable[] calldata creatorAddresses
  ) external onlyMinter {
    string memory _name = name;
    string memory _description = description;
    string memory _streamer = streamer;
    string memory _creator = creator;
    address payable[] memory _streamerAddresses = streamerAddresses;
    address payable[] memory _creatorAddresses = creatorAddresses;

    uint256 id = collections.push(CryptoCollectiveAssetMeta(
      _name,
      _description,
      _streamer,
      _creator,
      _streamerAddresses,
      _creatorAddresses
    )) - 1;
    super._mint(msg.sender, id);
  }

  function getCollection(uint256 tokenId) external view returns (
    address,
    uint256,
    string memory,
    string memory,
    string memory,
    string memory,
    address payable[] memory,
    address payable[] memory
  ) {
    CryptoCollectiveAssetMeta memory cca = collections[tokenId];
    return (
      super.ownerOf(tokenId),
      tokenId,
      cca.name,
      cca.description,
      cca.streamer,
      cca.creator,
      cca.streamerAddresses,
      cca.creatorAddresses
    );
  }

  function burn(uint256 tokenId) external onlyModerator {
    address tokenOwner = ownerOf(tokenId);
    super._burn(tokenOwner, tokenId);
  }

  function setTokenURI(uint256 tokenId, string calldata tokenURI) external onlyModerator {
    super._setTokenURI(tokenId, tokenURI);
  }

  function getRate() external view returns(uint256, uint256, uint256) {
    return (operatorRate, streamerRate, creatorRate);
  }

  function setRate(uint256 sort, uint256 rate) external onlyAdmin {
    if (sort == 0) {
      operatorRate = rate;
    } else if(sort == 1) {
      streamerRate = rate;
    } else if(sort == 2) {
      creatorRate = rate;
    }
  }

  function getOperator() external view onlyAdmin returns(string memory) {
    return addressToString(operatorAddress);
  }

  function setOperator(address payable newOperator) external onlyAdmin {
    operatorAddress = newOperator;
  }

   

  function transferFrom(address from, address to, uint256 tokenId) public payable {
    require(_isApprovedOrOwner(msg.sender, tokenId), 'Not approved or owner');
    hookTransferFrom(from, to, tokenId);
  }

  function safeTransferFrom(address from, address to, uint256 tokenId) public payable {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public payable {
    transferFrom(from, to, tokenId);
    require(super._checkOnERC721Received(from, to, tokenId, _data), 'Not check erc721 received');
  }

   

  function hookTransferFrom(address from, address to, uint256 tokenId) private {
     
    if (msg.value > 0) {
      uint256 estimitedValue = _distribute(msg.value, tokenId);
      address payable _from = address(uint160(from));
      _from.transfer(estimitedValue);
    }

    super._transferFrom(from, to, tokenId);
  }

  function _distribute(uint256 value, uint256 tokenId) private returns(uint256) {
    uint256 toValue = value;

     
    CryptoCollectiveAssetMeta memory token = collections[tokenId];
    address payable[] memory streamerAddresses = token.streamerAddresses;
    address payable[] memory creatorAddresses = token.creatorAddresses;

     
    if (operatorRate > 0) {
      uint256 distributedValueForOperator = value * operatorRate / 100;
      operatorAddress.transfer(distributedValueForOperator);
      toValue -= distributedValueForOperator;
    }
     
    if (streamerAddresses.length > 0 && streamerRate > 0) {
      uint256 distributedValueForDistributer = value * streamerRate / 100 / streamerAddresses.length;
      for (uint i = 0; i < streamerAddresses.length; i++) {
        streamerAddresses[i].transfer(distributedValueForDistributer);
        toValue -= distributedValueForDistributer;
      }
    }
     
    if (creatorAddresses.length > 0 && creatorRate > 0) {
      uint256 distributedValueForCreator = value * creatorRate / 100 / creatorAddresses.length;
      for (uint i = 0; i < creatorAddresses.length; i++) {
        creatorAddresses[i].transfer(distributedValueForCreator);
        toValue -= distributedValueForCreator;
      }
    }

    return toValue;
  }

  function addressToString(address _addr) private pure returns(string memory) {
    bytes32 value = bytes32(uint256(_addr));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(42);
    str[0] = '0';
    str[1] = 'x';
    for (uint i = 0; i < 20; i++) {
      str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
      str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }
}