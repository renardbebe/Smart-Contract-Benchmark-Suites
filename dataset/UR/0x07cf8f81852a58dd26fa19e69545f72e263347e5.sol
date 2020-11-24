 

pragma solidity 0.5.9;  


 
interface IHomeWork {
   
  event NewResident(
    address indexed homeAddress,
    bytes32 key,
    bytes32 runtimeCodeHash
  );

   
  event NewRuntimeStorageContract(
    address runtimeStorageContract,
    bytes32 runtimeCodeHash
  );

   
  event NewController(bytes32 indexed key, address newController);

   
  event NewHighScore(bytes32 key, address submitter, uint256 score);

   
  struct HomeAddress {
    bool exists;
    address controller;
    uint88 deploys;
  }

   
  struct KeyInformation {
    bytes32 key;
    bytes32 salt;
    address submitter;
  }

   
  function deploy(bytes32 key, bytes calldata initializationCode)
    external
    payable
    returns (address homeAddress, bytes32 runtimeCodeHash);

   
  function lock(bytes32 key, address owner) external;

   
  function redeem(uint256 tokenId, address controller) external;

   
  function assignController(bytes32 key, address controller) external;

   
  function relinquishControl(bytes32 key) external;

   
  function redeemAndDeploy(
    uint256 tokenId,
    address controller,
    bytes calldata initializationCode
  )
    external
    payable
    returns (address homeAddress, bytes32 runtimeCodeHash);

   
  function deriveKey(bytes32 salt) external returns (bytes32 key);

   
  function deriveKeyAndLock(bytes32 salt, address owner)
    external
    returns (bytes32 key);

   
  function deriveKeyAndAssignController(bytes32 salt, address controller)
    external
    returns (bytes32 key);

   
  function deriveKeyAndRelinquishControl(bytes32 salt)
    external
    returns (bytes32 key);

   
  function setReverseLookup(bytes32 key) external;

   
  function setDerivedReverseLookup(bytes32 salt, address submitter) external;

   
  function deployRuntimeStorageContract(bytes calldata codePayload)
    external
    returns (address runtimeStorageContract);

   
  function deployViaExistingRuntimeStorageContract(
    bytes32 key,
    address initializationRuntimeStorageContract
  )
    external
    payable
    returns (address homeAddress, bytes32 runtimeCodeHash);

   
  function redeemAndDeployViaExistingRuntimeStorageContract(
    uint256 tokenId,
    address controller,
    address initializationRuntimeStorageContract
  )
    external
    payable
    returns (address homeAddress, bytes32 runtimeCodeHash);

   
  function deriveKeyAndDeploy(bytes32 salt, bytes calldata initializationCode)
    external
    payable
    returns (address homeAddress, bytes32 key, bytes32 runtimeCodeHash);

   
  function deriveKeyAndDeployViaExistingRuntimeStorageContract(
    bytes32 salt,
    address initializationRuntimeStorageContract
  )
    external
    payable
    returns (address homeAddress, bytes32 key, bytes32 runtimeCodeHash);

   
  function batchLock(address owner, bytes32[] calldata keys) external;

   
  function deriveKeysAndBatchLock(address owner, bytes32[] calldata salts)
    external;

   
  function batchLock_63efZf( ) external;

   
  function claimHighScore(bytes32 key) external;

   
  function recover(IERC20 token, address payable recipient) external;

   
  function isDeployable(bytes32 key)
    external
     
    returns (bool deployable);

   
  function getHighScore()
    external
    view
    returns (address holder, uint256 score, bytes32 key);

   
  function getHomeAddressInformation(bytes32 key)
    external
    view
    returns (
      address homeAddress,
      address controller,
      uint256 deploys,
      bytes32 currentRuntimeCodeHash
    );

   
  function hasNeverBeenDeployed(bytes32 key)
    external
    view
    returns (bool neverBeenDeployed);

   
  function reverseLookup(address homeAddress)
    external
    view
    returns (bytes32 key, bytes32 salt, address submitter);

   
  function getDerivedKey(bytes32 salt, address submitter)
    external
    pure
    returns (bytes32 key);

   
  function getHomeAddress(bytes32 key)
    external
    pure
    returns (address homeAddress);

   
  function getMetamorphicDelegatorInitializationCode()
    external
    pure
    returns (bytes32 metamorphicDelegatorInitializationCode);

   
  function getMetamorphicDelegatorInitializationCodeHash()
    external
    pure
    returns (bytes32 metamorphicDelegatorInitializationCodeHash);

   
  function getArbitraryRuntimeCodePrelude()
    external
    pure
    returns (bytes11 prelude);
}


 
interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function transferFrom(address from, address to, uint256 tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}


 
interface IERC721Enumerable {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}


 
interface IERC721Metadata {
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}


 
interface IERC721Receiver {
     
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
      external
      returns (bytes4);
}


 
interface IERC1412 {
   
   
   
   
   
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds, bytes calldata _data) external;
  
   
   
   
   
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _tokenIds) external; 
}


 
interface IERC165 {
     
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
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


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


 
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
        require(owner != address(0));
        return _ownedTokensCount[owner].current();
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
        _ownedTokensCount[to].increment();

        emit Transfer(address(0), to, tokenId);
    }

     
    function _burn(address owner, uint256 tokenId) internal {
        require(ownerOf(tokenId) == owner);

        _clearApproval(tokenId);

        _ownedTokensCount[owner].decrement();
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


 
contract HomeWork is IHomeWork, ERC721Enumerable, IERC721Metadata, IERC1412 {
   
  address private _initializationRuntimeStorageContract;

   
  bytes32 private _highScoreKey;

   
  mapping (bytes32 => HomeAddress) private _home;

   
  mapping (address => KeyInformation) private _key;

   
  bytes21 private constant _FF_AND_THIS_CONTRACT = bytes21(
    0xff0000000000001b84b1cb32787B0D64758d019317
  );

   
  address private constant _URI_END_SEGMENT_STORAGE = address(
    0x000000000071C1c84915c17BF21728BfE4Dac3f3
  );

   
  bytes32 private constant _HOME_INIT_CODE = bytes32(
    0x5859385958601c335a585952fa1582838382515af43d3d93833e601e57fd5bf3
  );

   
  bytes32 private constant _HOME_INIT_CODE_HASH = bytes32(
    0x7816562e7f85866cae07183593075f3b5ec32aeff914a0693e20aaf39672babc
  );

   
  bytes11 private constant _ARBITRARY_RUNTIME_PRELUDE = bytes11(
    0x600b5981380380925939f3
  );

   
  bytes4 private constant _INTERFACE_ID_HOMEWORK = 0xe5399799;
   

  bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

  bytes4 private constant _INTERFACE_ID_ERC1412_BATCH_TRANSFERS = 0x2b89bcaa;

   
  string private constant _NAME = (
    hex"486f6d65576f726b20f09f8fa0f09f9ba0efb88f"
  );

   
  string private constant _SYMBOL = "HWK";

   
  bytes private constant _URI_START_SEGMENT = abi.encodePacked(
    hex"646174613a6170706c69636174696f6e2f6a736f6e2c7b226e616d65223a22486f6d65",
    hex"253230416464726573732532302d2532303078"
  );  

   
  string private constant _ACCOUNT_EXISTS = string(
    "Only non-existent accounts can be deployed or used to mint tokens."
  );

  string private constant _ONLY_CONTROLLER = string(
    "Only the designated controller can call this function."
  );

  string private constant _NO_INIT_CODE_SUPPLIED = string(
    "Cannot deploy a contract with no initialization code supplied."
  );

   
  constructor() public {
     
    assert(address(this) == address(uint160(uint168(_FF_AND_THIS_CONTRACT))));

     
    bytes32 initialDeployKey = bytes32(
      0x486f6d65576f726b20f09f8fa0f09f9ba0efb88faa3c548a76f9bd3c000c0000
    );    
    assert(address(this) == address(
      uint160(                       
        uint256(                     
          keccak256(                 
            abi.encodePacked(        
              bytes1(0xff),          
              msg.sender,            
              initialDeployKey,      
              _HOME_INIT_CODE_HASH   
            )
          )
        )
      )
    ));

     
    bytes32 uriDeployKey = bytes32(
      0x486f6d65576f726b202d20746f6b656e55524920c21352fee5a62228db000000
    );
    bytes32 uriInitCodeHash = bytes32(
      0xdea98294867e3fdc48eb5975ecc53a79e2e1ea6e7e794137a9c34c4dd1565ba2
    );
    assert(_URI_END_SEGMENT_STORAGE == address(
      uint160(                       
        uint256(                     
          keccak256(                 
            abi.encodePacked(        
              bytes1(0xff),          
              msg.sender,            
              uriDeployKey,          
              uriInitCodeHash        
            )
          )
        )
      )
    ));

     
    bytes32 expectedRuntimeStorageHash = bytes32(
      0x8834602968080bb1df9c44c9834c0a93533b72bbfa3865ee2c5be6a0c4125fc3
    );
    address runtimeStorage = _URI_END_SEGMENT_STORAGE;
    bytes32 runtimeStorageHash;
    assembly { runtimeStorageHash := extcodehash(runtimeStorage) }
    assert(runtimeStorageHash == expectedRuntimeStorageHash);

     
    assert(keccak256(abi.encode(_HOME_INIT_CODE)) == _HOME_INIT_CODE_HASH);

     
    _highScoreKey = bytes32(
      0x0000000000000000000000000000000000000000ffffffffffffffffffffffff
    );

     
    _registerInterface(_INTERFACE_ID_HOMEWORK);

     
    _registerInterface(_INTERFACE_ID_ERC721_METADATA);

     
    _registerInterface(_INTERFACE_ID_ERC1412_BATCH_TRANSFERS);
  }

   
  function deploy(bytes32 key, bytes calldata initializationCode)
    external
    payable
    onlyEmpty(key)
    onlyControllerDeployer(key)
    returns (address homeAddress, bytes32 runtimeCodeHash)
  {
     
    require(initializationCode.length > 0, _NO_INIT_CODE_SUPPLIED);

     
    _initializationRuntimeStorageContract = _deployRuntimeStorageContract(
      initializationCode
    );

     
    (homeAddress, runtimeCodeHash) = _deployToHomeAddress(key);
  }

   
  function lock(bytes32 key, address owner)
    external
    onlyEmpty(key)
    onlyController(key)
  {
     
    _validateOwner(owner, key);

     
    HomeAddress storage home = _home[key];

     
    home.exists = true;
    home.controller = address(this);

     
    emit NewController(key, address(this));

     
    _mint(owner, uint256(key));
  }

   
  function redeem(uint256 tokenId, address controller)
    external
    onlyTokenOwnerOrApprovedSpender(tokenId)
  {
     
    bytes32 key = bytes32(tokenId);

     
    _validateController(controller, key);

     
    _burn(tokenId);

     
    _home[key].controller = controller;

     
    emit NewController(key, controller);
  }

   
  function assignController(bytes32 key, address controller)
    external
    onlyController(key)
  {
     
    _validateController(controller, key);

     
    HomeAddress storage home = _home[key];
    home.exists = true;
    home.controller = controller;

     
    emit NewController(key, controller);
  }

   
  function relinquishControl(bytes32 key)
    external
    onlyController(key)
  {
     
    HomeAddress storage home = _home[key];
    home.exists = true;
    home.controller = address(0);

     
    emit NewController(key, address(0));
  }

   
  function redeemAndDeploy(
    uint256 tokenId,
    address controller,
    bytes calldata initializationCode
  )
    external
    payable
    onlyTokenOwnerOrApprovedSpender(tokenId)
    returns (address homeAddress, bytes32 runtimeCodeHash)
  {
     
    require(initializationCode.length > 0, _NO_INIT_CODE_SUPPLIED);

     
    bytes32 key = bytes32(tokenId);

     
    _validateController(controller, key);

     
    _burn(tokenId);

     
    _initializationRuntimeStorageContract = _deployRuntimeStorageContract(
      initializationCode
    );

     
    HomeAddress storage home = _home[key];
    home.exists = true;
    home.controller = controller;
    home.deploys += 1;

     
    emit NewController(key, controller);

     
    (homeAddress, runtimeCodeHash) = _deployToHomeAddress(key);
  }

   
  function deriveKey(bytes32 salt) external returns (bytes32 key) {
     
    key = _deriveKey(salt, msg.sender);

     
    HomeAddress storage home = _home[key];
    if (!home.exists) {
      home.exists = true;
      home.controller = msg.sender;

       
      emit NewController(key, msg.sender);
    }
  }

   
  function deriveKeyAndLock(bytes32 salt, address owner)
    external
    returns (bytes32 key)
  {
     
    key = _deriveKey(salt, msg.sender);

     
    _validateOwner(owner, key);

     
    require(_isNotDeployed(key), _ACCOUNT_EXISTS);

     
    HomeAddress storage home = _home[key];
    if (home.exists) {
      require(home.controller == msg.sender, _ONLY_CONTROLLER);
    }

     
    home.exists = true;
    home.controller = address(this);

     
    _mint(owner, uint256(key));

     
    emit NewController(key, address(this));
  }

   
  function deriveKeyAndAssignController(bytes32 salt, address controller)
    external
    returns (bytes32 key)
  {
     
    key = _deriveKey(salt, msg.sender);

     
    _validateController(controller, key);

     
    HomeAddress storage home = _home[key];
    if (home.exists) {
      require(home.controller == msg.sender, _ONLY_CONTROLLER);
    }

     
    home.exists = true;
    home.controller = controller;

     
    emit NewController(key, controller);
  }

   
  function deriveKeyAndRelinquishControl(bytes32 salt)
    external
    returns (bytes32 key)
  {
     
    key = _deriveKey(salt, msg.sender);

     
    HomeAddress storage home = _home[key];
    if (home.exists) {
      require(home.controller == msg.sender, _ONLY_CONTROLLER);
    }

     
    home.exists = true;
    home.controller = address(0);

     
    emit NewController(key, address(0));
  }

   
  function setReverseLookup(bytes32 key) external {
     
    _key[_getHomeAddress(key)].key = key;
  }

   
  function setDerivedReverseLookup(bytes32 salt, address submitter) external {
     
    bytes32 key = _deriveKey(salt, submitter);

     
    _key[_getHomeAddress(key)] = KeyInformation({
      key: key,
      salt: salt,
      submitter: submitter
    });
  }

   
  function deployRuntimeStorageContract(bytes calldata codePayload)
    external
    returns (address runtimeStorageContract)
  {
     
    require(codePayload.length > 0, "No runtime code payload supplied.");

     
    runtimeStorageContract = _deployRuntimeStorageContract(codePayload);
  }

   
  function deployViaExistingRuntimeStorageContract(
    bytes32 key,
    address initializationRuntimeStorageContract
  )
    external
    payable
    onlyEmpty(key)
    onlyControllerDeployer(key)
    returns (address homeAddress, bytes32 runtimeCodeHash)
  {
     
    _validateRuntimeStorageIsNotEmpty(initializationRuntimeStorageContract);

     
    _initializationRuntimeStorageContract = initializationRuntimeStorageContract;

     
    (homeAddress, runtimeCodeHash) = _deployToHomeAddress(key);
  }

   
  function redeemAndDeployViaExistingRuntimeStorageContract(
    uint256 tokenId,
    address controller,
    address initializationRuntimeStorageContract
  )
    external
    payable
    onlyTokenOwnerOrApprovedSpender(tokenId)
    returns (address homeAddress, bytes32 runtimeCodeHash)
  {
     
    _validateRuntimeStorageIsNotEmpty(initializationRuntimeStorageContract);

     
    bytes32 key = bytes32(tokenId);

     
    _validateController(controller, key);

     
    _burn(tokenId);

     
    _initializationRuntimeStorageContract = initializationRuntimeStorageContract;

     
    HomeAddress storage home = _home[key];
    home.exists = true;
    home.controller = controller;
    home.deploys += 1;

     
    emit NewController(key, controller);

     
    (homeAddress, runtimeCodeHash) = _deployToHomeAddress(key);
  }

   
  function deriveKeyAndDeploy(bytes32 salt, bytes calldata initializationCode)
    external
    payable
    returns (address homeAddress, bytes32 key, bytes32 runtimeCodeHash)
  {
     
    require(initializationCode.length > 0, _NO_INIT_CODE_SUPPLIED);

     
    key = _deriveKeyAndPrepareToDeploy(salt);

     
    _initializationRuntimeStorageContract = _deployRuntimeStorageContract(
      initializationCode
    );

     
    (homeAddress, runtimeCodeHash) = _deployToHomeAddress(key);
  }

   
  function deriveKeyAndDeployViaExistingRuntimeStorageContract(
    bytes32 salt,
    address initializationRuntimeStorageContract
  )
    external
    payable
    returns (address homeAddress, bytes32 key, bytes32 runtimeCodeHash)
  {
     
    _validateRuntimeStorageIsNotEmpty(initializationRuntimeStorageContract);

     
    key = _deriveKeyAndPrepareToDeploy(salt);

     
    _initializationRuntimeStorageContract = initializationRuntimeStorageContract;

     
    (homeAddress, runtimeCodeHash) = _deployToHomeAddress(key);
  }

   
  function batchLock(address owner, bytes32[] calldata keys) external {
     
    bytes32 key;

     
    if (keys.length > 0) {
      _validateOwner(owner, keys[0]);
    }

     
    for (uint256 i; i < keys.length; i++) {
      key = keys[i];

       
      if (!_isNotDeployed(key)) {
        continue;
      }

       
      if (_getController(key) != msg.sender) {
        continue;
      }

       
      HomeAddress storage home = _home[key];
      home.exists = true;
      home.controller = address(this);

       
      emit NewController(key, address(this));

       
      _mint(owner, uint256(key));
    }
  }

   
  function deriveKeysAndBatchLock(address owner, bytes32[] calldata salts)
    external
  {
     
    bytes32 key;

     
    if (salts.length > 0) {
      _validateOwner(owner, _deriveKey(salts[0], msg.sender));
    }

     
    for (uint256 i; i < salts.length; i++) {
       
      key = _deriveKey(salts[i], msg.sender);

       
      if (!_isNotDeployed(key)) {
        continue;
      }

       
      HomeAddress storage home = _home[key];
      if (home.exists && home.controller != msg.sender) {
        continue;
      }

       
      home.exists = true;
      home.controller = address(this);

       
      emit NewController(key, address(this));

       
      _mint(owner, uint256(key));
    }
  }

   
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds
  )
    external
  {
     
    uint256 tokenId;

     
    for (uint256 i = 0; i < tokenIds.length; i++) {
       
      tokenId = tokenIds[i];

       
      safeTransferFrom(from, to, tokenId);
    }
  }

   
  function safeBatchTransferFrom(
    address from,
    address to,
    uint256[] calldata tokenIds,
    bytes calldata data
  )
    external
  {
     
    uint256 tokenId;

     
    for (uint256 i = 0; i < tokenIds.length; i++) {
       
      tokenId = tokenIds[i];

       
      safeTransferFrom(from, to, tokenId, data);
    }
  }

   
  function batchLock_63efZf( ) external {
     
    address owner;

     
    uint256 passedSaltSegments;

     
    assembly {
      owner := shr(0x60, calldataload(4))                   
      passedSaltSegments := div(sub(calldatasize, 24), 12)  
    }

     
    bytes32 key;

     
    for (uint256 i; i < passedSaltSegments; i++) {
       
      assembly {
        key := add(                    
          shl(0x60, caller),           
          shr(0xa0, calldataload(add(24, mul(i, 12))))    
        )
      }

       
      require(_isNotDeployed(key), _ACCOUNT_EXISTS);

       
      HomeAddress storage home = _home[key];
      if (home.exists) {
        require(home.controller == msg.sender, _ONLY_CONTROLLER);
      }

       
      home.exists = true;
      home.controller = address(this);

       
      emit NewController(key, address(this));

       
      _mint(owner, uint256(key));
    }
  }

   
  function staticCreate2Check(bytes32 key) external {
    require(
      msg.sender == address(this),
      "This function can only be called by this contract."
    );

    assembly {
       
      mstore(
        0,
        0x5859385958601c335a585952fa1582838382515af43d3d93833e601e57fd5bf3
      )

       
      let deploymentAddress := create2(0, 0, 32, key)

       
      if deploymentAddress {        
        revert(0, 32)
      }
    }
  }

   
  function claimHighScore(bytes32 key) external {
    require(
      msg.sender == address(bytes20(key)),
      "Only submitters directly encoded in a given key may claim a high score."
    );

     
    address currentHighScore = _getHomeAddress(_highScoreKey);

     
    address newHighScore = _getHomeAddress(key);

     
    require(
      uint160(newHighScore) < uint160(currentHighScore),
      "Submitted high score is not better than the current high score."
    );

     
    _highScoreKey = key;

     
    uint256 score = uint256(uint160(-1) - uint160(newHighScore));

     
    emit NewHighScore(key, msg.sender, score);
  }

   
  function recover(IERC20 token, address payable recipient) external {
    require(
      msg.sender == address(bytes20(_highScoreKey)),
      "Only the current high score holder may recover tokens."
    );

    if (address(token) == address(0)) {
       
      recipient.transfer(address(this).balance);
    } else {
       
      uint256 balance = token.balanceOf(address(this));
      token.transfer(recipient, balance);
    }
  }

   
  function isDeployable(bytes32 key)
    external
     
    returns (bool deployable)
  {
    deployable = _isNotDeployed(key);
  }

   
  function getHighScore()
    external
    view
    returns (address holder, uint256 score, bytes32 key)
  {
     
    key = _highScoreKey;
    holder = address(bytes20(key));

     
    score = uint256(uint160(-1) - uint160(_getHomeAddress(key)));
  }

   
  function getHomeAddressInformation(bytes32 key)
    external
    view
    returns (
      address homeAddress,
      address controller,
      uint256 deploys,
      bytes32 currentRuntimeCodeHash
    )
  {
     
    homeAddress = _getHomeAddress(key);
    HomeAddress memory home = _home[key];

     
    if (!home.exists) {
      controller = address(bytes20(key));
    } else {
      controller = home.controller;
    }

     
    deploys = home.deploys;

     
    assembly { currentRuntimeCodeHash := extcodehash(homeAddress) }
  }

   
  function hasNeverBeenDeployed(bytes32 key)
    external
    view
    returns (bool neverBeenDeployed)
  {
    neverBeenDeployed = (_home[key].deploys == 0);
  }

   
  function reverseLookup(address homeAddress)
    external
    view
    returns (bytes32 key, bytes32 salt, address submitter)
  {
    KeyInformation memory keyInformation = _key[homeAddress];
    key = keyInformation.key;
    salt = keyInformation.salt;
    submitter = keyInformation.submitter;
  }

   
  function getInitializationCodeFromContractRuntime_6CLUNS()
    external
    view
    returns (address initializationRuntimeStorageContract)
  {
     
    initializationRuntimeStorageContract = _initializationRuntimeStorageContract;
  }

   
  function tokenURI(uint256 tokenId)
    external
    view
    returns (string memory)
  {
     
    require(_exists(tokenId), "A token with the given ID does not exist.");

     
    address homeAddress = _getHomeAddress(bytes32(tokenId));

     
    string memory asciiHomeAddress = _toChecksummedAsciiString(homeAddress);
    
    bytes memory uriEndSegment = _getTokenURIStorageRuntime();

     
    return string(
      abi.encodePacked(       
        _URI_START_SEGMENT,   
        asciiHomeAddress,     
        uriEndSegment         
      )
    );
  }

   
  function name() external pure returns (string memory) {
    return _NAME;
  }

   
  function symbol() external pure returns (string memory) {
    return _SYMBOL;
  }

   
  function getDerivedKey(bytes32 salt, address submitter)
    external
    pure
    returns (bytes32 key)
  {
     
    key = _deriveKey(salt, submitter);
  }

   
  function getHomeAddress(bytes32 key)
    external
    pure
    returns (address homeAddress)
  {
     
    homeAddress = _getHomeAddress(key);
  }

   
  function getMetamorphicDelegatorInitializationCode()
    external
    pure
    returns (bytes32 metamorphicDelegatorInitializationCode)
  {
    metamorphicDelegatorInitializationCode = _HOME_INIT_CODE;
  }

   
  function getMetamorphicDelegatorInitializationCodeHash()
    external
    pure
    returns (bytes32 metamorphicDelegatorInitializationCodeHash)
  {
    metamorphicDelegatorInitializationCodeHash = _HOME_INIT_CODE_HASH;
  }

   
  function getArbitraryRuntimeCodePrelude()
    external
    pure
    returns (bytes11 prelude)
  {
    prelude = _ARBITRARY_RUNTIME_PRELUDE;
  }

   
  function _deployRuntimeStorageContract(bytes memory payload)
    internal
    returns (address runtimeStorageContract)
  {
     
    bytes memory runtimeStorageContractCreationCode = abi.encodePacked(
      _ARBITRARY_RUNTIME_PRELUDE,
      payload
    );

    assembly {
       
      let encoded_data := add(0x20, runtimeStorageContractCreationCode)
      let encoded_size := mload(runtimeStorageContractCreationCode)

       
      runtimeStorageContract := create(0, encoded_data, encoded_size)

       
      if iszero(runtimeStorageContract) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

     
    emit NewRuntimeStorageContract(runtimeStorageContract, keccak256(payload));
  }

   
  function _deployToHomeAddress(bytes32 key)
    internal
    returns (address homeAddress, bytes32 runtimeCodeHash)
  {    
    assembly {
       
      mstore(
        0,
        0x5859385958601c335a585952fa1582838382515af43d3d93833e601e57fd5bf3
      )

       
      homeAddress := create2(callvalue, 0, 32, key)

       
      if iszero(homeAddress) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }

       
      runtimeCodeHash := extcodehash(homeAddress)
    }

     
    delete _initializationRuntimeStorageContract;

     
    emit NewResident(homeAddress, key, runtimeCodeHash);
  }

   
  function _deriveKeyAndPrepareToDeploy(bytes32 salt)
    internal
    returns (bytes32 key)
  {
     
    key = _deriveKey(salt, msg.sender);

     
    require(_isNotDeployed(key), _ACCOUNT_EXISTS);

     
    HomeAddress storage home = _home[key];
    if (!home.exists) {
      home.exists = true;
      home.controller = msg.sender;
      home.deploys += 1;

       
      emit NewController(key, msg.sender);
    
    } else {
      home.deploys += 1;
    }

     
    require(home.controller == msg.sender, _ONLY_CONTROLLER);
  }

   
  function _validateOwner(address owner, bytes32 key) internal {
     
    require(
      _checkOnERC721Received(address(0), owner, uint256(key), bytes("")),
      "Owner must be an EOA or a contract that implements `onERC721Received`."
    );
  }

   
  function _isNotDeployed(bytes32 key)
    internal
     
    returns (bool notDeployed)
  {
     
    address homeAddress = _getHomeAddress(key);

     
    bytes32 hash;
    assembly { hash := extcodehash(homeAddress) }

     
    if (hash == bytes32(0)) {
      return true;
    }

     
    uint256 size;
    assembly { size := extcodesize(homeAddress) }
    if (size > 0) {
      return false;
    }

     
    address currentStorage;

     
    if (_initializationRuntimeStorageContract != address(0)) {
       
      currentStorage = _initializationRuntimeStorageContract;
      
       
      delete _initializationRuntimeStorageContract;
    }

     
    uint256 checkGas = 27000 + (block.gaslimit / 1000);
    
     
    (bool contractExists, bytes memory code) = address(this).call.gas(checkGas)(
      abi.encodeWithSelector(this.staticCreate2Check.selector, key)
    );

     
    if (currentStorage != address(0)) {
      _initializationRuntimeStorageContract = currentStorage;
    }

     
    bytes32 revertMessage;
    assembly { revertMessage := mload(add(code, 32)) }

     
    notDeployed = !contractExists && revertMessage == _HOME_INIT_CODE;
  }

   
  function _validateController(address controller, bytes32 key) internal view {
     
    require(
      controller != address(0),
      "The null address may not be set as the controller using this function."
    );
    require(
      controller != address(this),
      "This contract may not be set as the controller using this function."
    );
    require(
      controller != _getHomeAddress(key),
      "Home addresses cannot be set as the controller of themselves."
    );
  }

   
  function _validateRuntimeStorageIsNotEmpty(address target) internal view {
     
    require(
      target.isContract(),
      "No runtime code found at the supplied runtime storage address."
    );
  }

   
  function _getController(bytes32 key)
    internal
    view
    returns (address controller)
  {
     
    HomeAddress memory home = _home[key];
    if (!home.exists) {
      controller = address(bytes20(key));
    } else {
      controller = home.controller;
    }
  }

   
  function _getTokenURIStorageRuntime()
    internal
    view
    returns (bytes memory runtime)
  {
     
    address target = _URI_END_SEGMENT_STORAGE;
    
    assembly {
       
      let size := extcodesize(target)
      
       
      runtime := mload(0x40)
      
       
      mstore(0x40, add(runtime, and(add(size, 0x3f), not(0x1f))))
      
       
      mstore(runtime, size)
      
       
      extcodecopy(target, add(runtime, 0x20), 0, size)
    }
  }

   
  function _getHomeAddress(bytes32 key)
    internal
    pure
    returns (address homeAddress)
  {
     
    homeAddress = address(
      uint160(                        
        uint256(                      
          keccak256(                  
            abi.encodePacked(         
              _FF_AND_THIS_CONTRACT,  
              key,                    
              _HOME_INIT_CODE_HASH    
            )
          )
        )
      )
    );
  }

   
  function _deriveKey(bytes32 salt, address submitter)
    internal
    pure
    returns (bytes32 key)
  {
     
    key = keccak256(abi.encodePacked(salt, submitter));
  }

   
  function _toAsciiString(bytes20 data)
    internal
    pure
    returns (string memory asciiString)
  {
     
    bytes memory asciiBytes = new bytes(40);

     
    uint8 oneByte;
    uint8 leftNibble;
    uint8 rightNibble;

     
    for (uint256 i = 0; i < data.length; i++) {
       
      oneByte = uint8(uint160(data) / (2 ** (8 * (19 - i))));
      leftNibble = oneByte / 16;
      rightNibble = oneByte - 16 * leftNibble;

       
      asciiBytes[2 * i] = byte(leftNibble + (leftNibble < 10 ? 48 : 87));
      asciiBytes[2 * i + 1] = byte(rightNibble + (rightNibble < 10 ? 48 : 87));
    }

    asciiString = string(asciiBytes);
  }

   
  function _getChecksumCapitalizedCharacters(address account)
    internal
    pure
    returns (bool[40] memory characterIsCapitalized)
  {
     
    bytes20 addressBytes = bytes20(account);

     
    bytes32 hash = keccak256(abi.encodePacked(_toAsciiString(addressBytes)));

     
    uint8 leftNibbleAddress;
    uint8 rightNibbleAddress;
    uint8 leftNibbleHash;
    uint8 rightNibbleHash;

     
    for (uint256 i; i < addressBytes.length; i++) {
       
      rightNibbleAddress = uint8(addressBytes[i]) % 16;
      leftNibbleAddress = (uint8(addressBytes[i]) - rightNibbleAddress) / 16;
      rightNibbleHash = uint8(hash[i]) % 16;
      leftNibbleHash = (uint8(hash[i]) - rightNibbleHash) / 16;

       
      characterIsCapitalized[2 * i] = (
        leftNibbleAddress > 9 &&
        leftNibbleHash > 7
      );
      characterIsCapitalized[2 * i + 1] = (
        rightNibbleAddress > 9 &&
        rightNibbleHash > 7
      );
    }
  }

   
  function _toChecksummedAsciiString(address account)
    internal
    pure
    returns (string memory checksummedAsciiString)
  {
     
    bool[40] memory caps = _getChecksumCapitalizedCharacters(account);

     
    bytes memory asciiBytes = new bytes(40);

     
    uint8 oneByte;
    uint8 leftNibble;
    uint8 rightNibble;
    uint8 leftNibbleOffset;
    uint8 rightNibbleOffset;

     
    bytes20 data = bytes20(account);

     
    for (uint256 i = 0; i < data.length; i++) {
       
      oneByte = uint8(uint160(data) / (2 ** (8 * (19 - i))));
      leftNibble = oneByte / 16;
      rightNibble = oneByte - 16 * leftNibble;

       
      if (leftNibble < 10) {
        leftNibbleOffset = 48;
      } else if (caps[i * 2]) {
        leftNibbleOffset = 55;
      } else {
        leftNibbleOffset = 87;
      }

      if (rightNibble < 10) {
        rightNibbleOffset = 48;
      } else {
        rightNibbleOffset = caps[(i * 2) + 1] ? 55 : 87;  
      }

      asciiBytes[2 * i] = byte(leftNibble + leftNibbleOffset);
      asciiBytes[2 * i + 1] = byte(rightNibble + rightNibbleOffset);
    }

    checksummedAsciiString = string(asciiBytes);
  }

   
  modifier onlyEmpty(bytes32 key) {
    require(_isNotDeployed(key), _ACCOUNT_EXISTS);
    _;
  }

   
  modifier onlyController(bytes32 key) {
    require(_getController(key) == msg.sender, _ONLY_CONTROLLER);
    _;
  }

   
  modifier onlyControllerDeployer(bytes32 key) {
    HomeAddress storage home = _home[key];

     
    if (!home.exists) {
      home.exists = true;
      home.controller = address(bytes20(key));
      home.deploys += 1;
    } else {
      home.deploys += 1;
    }

    require(home.controller == msg.sender, _ONLY_CONTROLLER);
    _;
  }

   
  modifier onlyTokenOwnerOrApprovedSpender(uint256 tokenId) {
    require(
      _isApprovedOrOwner(msg.sender, tokenId),
      "Only the token owner or an approved spender may call this function."
    );
    _;
  }
}

 
contract HomeWorkDeployer {
   
  event HomeWorkDeployment(address homeAddress, bytes32 key);

   
  event StorageContractDeployment(address runtimeStorageContract);

   
  address private _initializationRuntimeStorageContract;

   
  bool private _disabled;

   
  bytes11 private constant _ARBITRARY_RUNTIME_PRELUDE = bytes11(
    0x600b5981380380925939f3
  );

   
  function phaseOne(bytes calldata code) external onlyUntilDisabled {
     
    _initializationRuntimeStorageContract = _deployRuntimeStorageContract(
      bytes32(0),
      code
    );
  }

   
  function phaseTwo(bytes32 key) external onlyUntilDisabled {
     
     
    bytes memory code = abi.encodePacked(
      hex"222c226465736372697074696f6e223a22546869732532304e465425323063616e25",
      hex"3230626525323072656465656d65642532306f6e253230486f6d65576f726b253230",
      hex"746f2532306772616e7425323061253230636f6e74726f6c6c657225323074686525",
      hex"32306578636c75736976652532307269676874253230746f2532306465706c6f7925",
      hex"3230636f6e7472616374732532307769746825323061726269747261727925323062",
      hex"797465636f6465253230746f25323074686525323064657369676e61746564253230",
      hex"686f6d65253230616464726573732e222c22696d616765223a22646174613a696d61",
      hex"67652f7376672b786d6c3b636861727365743d7574662d383b6261736536342c5048",
      hex"4e325a79423462577875637a30696148523063446f764c336433647935334d793576",
      hex"636d63764d6a41774d43397a646d636949485a705a58644362336739496a41674d43",
      hex"41784e4451674e7a4969506a787a64486c735a543438495674445245465551567375",
      hex"516e747a64484a766132557462476c755a57707661573436636d3931626d52394c6b",
      hex"4e37633352796232746c4c5731706447567962476c74615851364d5442394c6b5237",
      hex"633352796232746c4c5864705a48526f4f6a4a394c6b56375a6d6c7362446f6a4f57",
      hex"4935596a6c686653354765334e30636d39725a5331736157356c593246774f6e4a76",
      hex"6457356b66563164506a7776633352356247552b5047636764484a68626e4e6d6233",
      hex"4a7450534a74595852796158676f4d5334774d694177494441674d5334774d694134",
      hex"4c6a45674d436b69506a78775958526f49475a706247773949694e6d5a6d59694947",
      hex"5139496b30784f53417a4d6d677a4e4859794e4567784f586f694c7a34385a79427a",
      hex"64484a766132553949694d774d44416949474e7359584e7a50534a4349454d675243",
      hex"492b50484268644767675a6d6c7362443069493245314e7a6b7a4f5349675a443069",
      hex"545449314944517761446c324d545a6f4c546c364969382b50484268644767675a6d",
      hex"6c7362443069497a6b795a444e6d4e5349675a443069545451774944517761446832",
      hex"4e3267744f486f694c7a3438634746306143426d615778735053496a5a5745315954",
      hex"51334969426b50534a4e4e544d674d7a4a494d546c324c5446734d5459744d545967",
      hex"4d5467674d545a364969382b50484268644767675a6d6c7362443069626d39755a53",
      hex"49675a4430695454453549444d7961444d30646a49305344453565694976506a7877",
      hex"5958526f49475a706247773949694e6c595456684e44636949475139496b30794f53",
      hex"41794d5777744e53413164693035614456364969382b5043396e506a77765a7a3438",
      hex"5a794230636d467563325a76636d3039496d316864484a70654367754f4451674d43",
      hex"4177494334344e4341324e5341314b53492b50484268644767675a44306954546b75",
      hex"4e5341794d693435624451754f4341324c6a52684d7934784d69417a4c6a45794944",
      hex"41674d4341784c544d674d693479624330304c6a67744e6934305979347a4c544575",
      hex"4e4341784c6a59744d69343049444d744d693479656949675a6d6c73624430694932",
      hex"517759325a6a5a534976506a78775958526f49475a706247773949694d774d544178",
      hex"4d44456949475139496b30304d53343349444d344c6a56734e5334784c5459754e53",
      hex"4976506a78775958526f49475139496b30304d693435494449334c6a684d4d546775",
      hex"4e4341314f4334784944493049445979624449784c6a67744d6a63754d7941794c6a",
      hex"4d744d693434656949675932786863334d39496b55694c7a3438634746306143426d",
      hex"615778735053496a4d4445774d5441784969426b50534a4e4e444d754e4341794f53",
      hex"347a624330304c6a63674e5334344969382b50484268644767675a44306954545132",
      hex"4c6a67674d7a4a6a4d793479494449754e6941344c6a63674d533479494445794c6a",
      hex"45744d793479637a4d754e6930354c6a6b754d7930784d693431624330314c6a4567",
      hex"4e6934314c5449754f4330754d5330754e7930794c6a63674e5334784c5459754e57",
      hex"4d744d7934794c5449754e6930344c6a63744d5334794c5445794c6a45674d793479",
      hex"6379307a4c6a59674f5334354c53347a494445794c6a556949474e7359584e7a5053",
      hex"4a464969382b50484268644767675a6d6c7362443069493245314e7a6b7a4f534967",
      hex"5a443069545449334c6a4d674d6a5a734d5445754f4341784e53343349444d754e43",
      hex"41794c6a51674f533478494445304c6a51744d793479494449754d79307849433433",
      hex"4c5445774c6a49744d544d754e6930784c6a4d744d7934354c5445784c6a67744d54",
      hex"55754e336f694c7a3438634746306143426b50534a4e4d5449674d546b754f577731",
      hex"4c6a6b674e793435494445774c6a49744e7934324c544d754e4330304c6a567a4e69",
      hex"34344c5455754d5341784d4334334c5451754e574d77494441744e6934324c544d74",
      hex"4d544d754d7941784c6a46544d5449674d546b754f5341784d6941784f5334356569",
      hex"49675932786863334d39496b55694c7a34385a79426d6157787350534a756232356c",
      hex"4969427a64484a766132553949694d774d44416949474e7359584e7a50534a434945",
      hex"4d675243492b50484268644767675a44306954545579494455344c6a6c4d4e444175",
      hex"4f5341304d7934796243307a4c6a45744d69347a4c5445774c6a59744d5451754e79",
      hex"30794c6a6b674d693479494445774c6a59674d5451754e7941784c6a45674d793432",
      hex"494445784c6a55674d5455754e58704e4d5449754e5341784f533434624455754f43",
      hex"4134494445774c6a4d744e7934304c544d754d7930304c6a5a7a4e6934354c545567",
      hex"4d5441754f4330304c6a4e6a4d4341774c5459754e69307a4c6a45744d544d754d79",
      hex"3435637930784d43347a494463754e4330784d43347a494463754e4870744c544975",
      hex"4e6941794c6a6c734e433433494459754e574d744c6a55674d53347a4c5445754e79",
      hex"41794c6a45744d7941794c6a4a734c5451754e7930324c6a566a4c6a4d744d533430",
      hex"494445754e6930794c6a51674d7930794c6a4a364969382b50484268644767675a44",
      hex"3069545451784c6a4d674d7a67754e5777314c6a45744e6934316253307a4c6a5574",
      hex"4d693433624330304c6a59674e533434625467754d53307a4c6a466a4d7934794944",
      hex"49754e6941344c6a63674d533479494445794c6a45744d793479637a4d754e693035",
      hex"4c6a6b754d7930784d693431624330314c6a45674e6934314c5449754f4330754d53",
      hex"30754f4330794c6a63674e5334784c5459754e574d744d7934794c5449754e693034",
      hex"4c6a63744d5334794c5445794c6a45674d7934794c544d754e4341304c6a4d744d79",
      hex"343249446b754f5330754d7941784d6934314969426a6247467a637a306952694976",
      hex"506a78775958526f49475139496b307a4d433434494451304c6a524d4d546b674e54",
      hex"67754f57773049444d674d5441744d5449754e7949675932786863334d39496b5969",
      hex"4c7a34384c32632b5043396e506a777663335a6e50673d3d227d"
    );  

     
    _deployRuntimeStorageContract(key, code);
  }

   
  function phaseThree(bytes32 key) external onlyUntilDisabled {
     
    _deployToHomeAddress(key);

     
    _disabled = true;
  }

   
  function getInitializationCodeFromContractRuntime_6CLUNS()
    external
    view
    returns (address initializationRuntimeStorageContract)
  {
     
    initializationRuntimeStorageContract = _initializationRuntimeStorageContract;
  }

   
  function _deployRuntimeStorageContract(bytes32 key, bytes memory payload)
    internal
    returns (address runtimeStorageContract)
  {
     
    bytes memory runtimeStorageContractCreationCode = abi.encodePacked(
      _ARBITRARY_RUNTIME_PRELUDE,
      payload
    );

    assembly {
       
      let encoded_data := add(0x20, runtimeStorageContractCreationCode)
      let encoded_size := mload(runtimeStorageContractCreationCode)

       
      runtimeStorageContract := create2(0, encoded_data, encoded_size, key)

       
      if iszero(runtimeStorageContract) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

     
    emit StorageContractDeployment(runtimeStorageContract);
  }

   
  function _deployToHomeAddress(bytes32 key) internal {
     
    address homeAddress;

    assembly {
       
      mstore(
        0,
        0x5859385958601c335a585952fa1582838382515af43d3d93833e601e57fd5bf3
      )

       
      homeAddress := create2(callvalue, 0, 32, key)

       
      if iszero(homeAddress) {
        returndatacopy(0, 0, returndatasize)
        revert(0, returndatasize)
      }
    }

     
    delete _initializationRuntimeStorageContract;

     
    emit HomeWorkDeployment(homeAddress, key);
  }

   
  modifier onlyUntilDisabled() {
    require(!_disabled, "Contract is disabled.");
    _;
  }
}