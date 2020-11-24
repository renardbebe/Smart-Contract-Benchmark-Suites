 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
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


contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
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

 

pragma solidity ^0.5.0;


 
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
        require(!_paused, "Pausable: paused");
        _;
    }

     
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
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

 

pragma solidity ^0.5.0;

 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.12;


 
interface IERC165 {

     
    function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 

pragma solidity ^0.5.12;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "SafeMath#mul: OVERFLOW");

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "SafeMath#div: DIVISION_BY_ZERO");
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath#sub: UNDERFLOW");
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "SafeMath#add: OVERFLOW");

    return c; 
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "SafeMath#mod: DIVISION_BY_ZERO");
    return a % b;
  }

}

 

pragma solidity ^0.5.12;

 
interface IERC1155TokenReceiver {

   
  function onERC1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);

   
  function onERC1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);

   
  function supportsInterface(bytes4 interfaceID) external view returns (bool);

}

 

pragma solidity ^0.5.12;


interface IERC1155 {
   

   
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);

   
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);

   
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

   
  event URI(string _amount, uint256 indexed _id);

   
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes calldata _data) external;

   
  function safeBatchTransferFrom(address _from, address _to, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external;
  
   
  function balanceOf(address _owner, uint256 _id) external view returns (uint256);

   
  function balanceOfBatch(address[] calldata _owners, uint256[] calldata _ids) external view returns (uint256[] memory);

   
  function setApprovalForAll(address _operator, bool _approved) external;

   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool isOperator);

}

 

 

pragma solidity ^0.5.12;


 
library Address {

   
  function isContract(address account) internal view returns (bool) {
    bytes32 codehash;
    bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

     
     
     
     
     
     
    assembly { codehash := extcodehash(account) }
    return (codehash != 0x0 && codehash != accountHash);
  }

}

 

pragma solidity ^0.5.12;







 
contract ERC1155 is IERC165 {
  using SafeMath for uint256;
  using Address for address;


   

   
  bytes4 constant internal ERC1155_RECEIVED_VALUE = 0xf23a6e61;
  bytes4 constant internal ERC1155_BATCH_RECEIVED_VALUE = 0xbc197c81;

   
  mapping (address => mapping(uint256 => uint256)) internal balances;

   
  mapping (address => mapping(address => bool)) internal operators;

   
  event TransferSingle(address indexed _operator, address indexed _from, address indexed _to, uint256 _id, uint256 _amount);
  event TransferBatch(address indexed _operator, address indexed _from, address indexed _to, uint256[] _ids, uint256[] _amounts);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  event URI(string _uri, uint256 indexed _id);


   

   
  function safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    public
  {
    require((msg.sender == _from) || operators[_from][msg.sender], "ERC1155#safeTransferFrom: INVALID_OPERATOR");
    require(_to != address(0),"ERC1155#safeTransferFrom: INVALID_RECIPIENT");
     

    _safeTransferFrom(_from, _to, _id, _amount);
    _callonERC1155Received(_from, _to, _id, _amount, _data);
  }

   
  function safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    public
  {
     
    require((msg.sender == _from) || operators[_from][msg.sender], "ERC1155#safeBatchTransferFrom: INVALID_OPERATOR");
    require(_to != address(0), "ERC1155#safeBatchTransferFrom: INVALID_RECIPIENT");

    _safeBatchTransferFrom(_from, _to, _ids, _amounts);
    _callonERC1155BatchReceived(_from, _to, _ids, _amounts, _data);
  }


   

   
  function _safeTransferFrom(address _from, address _to, uint256 _id, uint256 _amount)
    internal
  {
     
    balances[_from][_id] = balances[_from][_id].sub(_amount);  
    balances[_to][_id] = balances[_to][_id].add(_amount);      

     
    emit TransferSingle(msg.sender, _from, _to, _id, _amount);
  }

   
  function _callonERC1155Received(address _from, address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
     
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155Received(msg.sender, _from, _id, _amount, _data);
      require(retval == ERC1155_RECEIVED_VALUE, "ERC1155#_callonERC1155Received: INVALID_ON_RECEIVE_MESSAGE");
    }
  }

   
  function _safeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155#_safeBatchTransferFrom: INVALID_ARRAYS_LENGTH");

     
    uint256 nTransfer = _ids.length;

     
    for (uint256 i = 0; i < nTransfer; i++) {
       
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

     
    emit TransferBatch(msg.sender, _from, _to, _ids, _amounts);
  }

   
  function _callonERC1155BatchReceived(address _from, address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
     
    if (_to.isContract()) {
      bytes4 retval = IERC1155TokenReceiver(_to).onERC1155BatchReceived(msg.sender, _from, _ids, _amounts, _data);
      require(retval == ERC1155_BATCH_RECEIVED_VALUE, "ERC1155#_callonERC1155BatchReceived: INVALID_ON_RECEIVE_MESSAGE");
    }
  }


   

   
  function setApprovalForAll(address _operator, bool _approved)
    external
  {
     
    operators[msg.sender][_operator] = _approved;
    emit ApprovalForAll(msg.sender, _operator, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool isOperator)
  {
    return operators[_owner][_operator];
  }


   

   
  function balanceOf(address _owner, uint256 _id)
    public view returns (uint256)
  {
    return balances[_owner][_id];
  }

   
  function balanceOfBatch(address[] memory _owners, uint256[] memory _ids)
    public view returns (uint256[] memory)
  {
    require(_owners.length == _ids.length, "ERC1155#balanceOfBatch: INVALID_ARRAY_LENGTH");

     
    uint256[] memory batchBalances = new uint256[](_owners.length);

     
    for (uint256 i = 0; i < _owners.length; i++) {
      batchBalances[i] = balances[_owners[i]][_ids[i]];
    }

    return batchBalances;
  }


   

   
  bytes4 constant private INTERFACE_SIGNATURE_ERC165 = 0x01ffc9a7;

   
  bytes4 constant private INTERFACE_SIGNATURE_ERC1155 = 0xd9b67a26;

   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    if (_interfaceID == INTERFACE_SIGNATURE_ERC165 ||
        _interfaceID == INTERFACE_SIGNATURE_ERC1155) {
      return true;
    }
    return false;
  }

}

 

pragma solidity ^0.5.11;



 
contract ERC1155Metadata {

   
  string internal baseMetadataURI;
  event URI(string _uri, uint256 indexed _id);


   

   
  function uri(uint256 _id) public view returns (string memory) {
    return string(abi.encodePacked(baseMetadataURI, _uint2str(_id), ".json"));
  }


   

   
  function _logURIs(uint256[] memory _tokenIDs) internal {
    string memory baseURL = baseMetadataURI;
    string memory tokenURI;

    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      tokenURI = string(abi.encodePacked(baseURL, _uint2str(_tokenIDs[i]), ".json"));
      emit URI(tokenURI, _tokenIDs[i]);
    }
  }

   
  function _logURIs(uint256[] memory _tokenIDs, string[] memory _URIs) internal {
    require(_tokenIDs.length == _URIs.length, "ERC1155Metadata#_logURIs: INVALID_ARRAYS_LENGTH");
    for (uint256 i = 0; i < _tokenIDs.length; i++) {
      emit URI(_URIs[i], _tokenIDs[i]);
    }
  }

   
  function _setBaseMetadataURI(string memory _newBaseMetadataURI) internal {
    baseMetadataURI = _newBaseMetadataURI;
  }


   

   
  function _uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
      return "0";
    }

    uint256 j = _i;
    uint256 ii = _i;
    uint256 len;

     
    while (j != 0) {
      len++;
      j /= 10;
    }

    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;

     
    while (ii != 0) {
      bstr[k--] = byte(uint8(48 + ii % 10));
      ii /= 10;
    }

     
    return string(bstr);
  }

}

 

pragma solidity ^0.5.12;



 
contract ERC1155MintBurn is ERC1155 {


   

   
  function _mint(address _to, uint256 _id, uint256 _amount, bytes memory _data)
    internal
  {
     
    balances[_to][_id] = balances[_to][_id].add(_amount);

     
    emit TransferSingle(msg.sender, address(0x0), _to, _id, _amount);

     
    _callonERC1155Received(address(0x0), _to, _id, _amount, _data);
  }

   
  function _batchMint(address _to, uint256[] memory _ids, uint256[] memory _amounts, bytes memory _data)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchMint: INVALID_ARRAYS_LENGTH");

     
    uint256 nMint = _ids.length;

      
    for (uint256 i = 0; i < nMint; i++) {
       
      balances[_to][_ids[i]] = balances[_to][_ids[i]].add(_amounts[i]);
    }

     
    emit TransferBatch(msg.sender, address(0x0), _to, _ids, _amounts);

     
    _callonERC1155BatchReceived(address(0x0), _to, _ids, _amounts, _data);
  }


   

   
  function _burn(address _from, uint256 _id, uint256 _amount)
    internal
  {
     
    balances[_from][_id] = balances[_from][_id].sub(_amount);

     
    emit TransferSingle(msg.sender, _from, address(0x0), _id, _amount);
  }

   
  function _batchBurn(address _from, uint256[] memory _ids, uint256[] memory _amounts)
    internal
  {
    require(_ids.length == _amounts.length, "ERC1155MintBurn#batchBurn: INVALID_ARRAYS_LENGTH");

     
    uint256 nBurn = _ids.length;

      
    for (uint256 i = 0; i < nBurn; i++) {
       
      balances[_from][_ids[i]] = balances[_from][_ids[i]].sub(_amounts[i]);
    }

     
    emit TransferBatch(msg.sender, _from, address(0x0), _ids, _amounts);
  }

}

 

pragma solidity ^0.5.11;

library Strings {
   
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
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
}

 

pragma solidity ^0.5.11;






contract OwnableDelegateProxy { }

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

 
contract ERC1155Tradable is ERC1155, ERC1155MintBurn, ERC1155Metadata, Ownable {
  using Strings for string;

  address proxyRegistryAddress;
  uint256 private _currentTokenID = 0;
  mapping (uint256 => address) public creators;
  mapping (uint256 => uint256) public tokenSupply;
   
  string public name;
   
  string public symbol;

   
  modifier creatorOnly(uint256 _id) {
    require(creators[_id] == msg.sender, "ERC1155Tradable#creatorOnly: ONLY_CREATOR_ALLOWED");
    _;
  }

   
  modifier ownersOnly(uint256 _id) {
    require(balances[msg.sender][_id] > 0, "ERC1155Tradable#ownersOnly: ONLY_OWNERS_ALLOWED");
    _;
  }

  constructor(
    string memory _name,
    string memory _symbol,
    address _proxyRegistryAddress
  ) public {
    name = _name;
    symbol = _symbol;
    proxyRegistryAddress = _proxyRegistryAddress;
  }

  function uri(
    uint256 _id
  ) public view returns (string memory) {
    require(_exists(_id), "ERC721Tradable#uri: NONEXISTENT_TOKEN");
    return Strings.strConcat(
      baseMetadataURI,
      Strings.uint2str(_id)
    );
  }

   
  function totalSupply(
    uint256 _id
  ) public view returns (uint256) {
    return tokenSupply[_id];
  }

   
  function setBaseMetadataURI(
    string memory _newBaseMetadataURI
  ) public onlyOwner {
    _setBaseMetadataURI(_newBaseMetadataURI);
  }

   
  function create(
    address _initialOwner,
    uint256 _initialSupply,
    string calldata _uri,
    bytes calldata _data
  ) external onlyOwner returns (uint256) {

    uint256 _id = _getNextTokenID();
    _incrementTokenTypeId();
    creators[_id] = msg.sender;

    if (bytes(_uri).length > 0) {
      emit URI(_uri, _id);
    }

    _mint(_initialOwner, _id, _initialSupply, _data);
    tokenSupply[_id] = _initialSupply;
    return _id;
  }

   
  function mint(
    address _to,
    uint256 _id,
    uint256 _quantity,
    bytes memory _data
  ) public creatorOnly(_id) {
    _mint(_to, _id, _quantity, _data);
    tokenSupply[_id] += _quantity;
  }

   
  function batchMint(
    address _to,
    uint256[] memory _ids,
    uint256[] memory _quantities,
    bytes memory _data
  ) public {
    for (uint256 i = 0; i < _ids.length; i++) {
      uint256 _id = _ids[i];
      require(creators[_id] == msg.sender, "ERC1155Tradable#batchMint: ONLY_CREATOR_ALLOWED");
      uint256 quantity = _quantities[i];
      tokenSupply[_id] += quantity;
    }
    _batchMint(_to, _ids, _quantities, _data);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view returns (bool isOperator) {
     
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(_owner)) == _operator) {
      return true;
    }

    return ERC1155.isApprovedForAll(_owner, _operator);
  }

   
  function _exists(
    uint256 _id
  ) internal view returns (bool) {
    return creators[_id] != address(0);
  }

   
  function _getNextTokenID() private view returns (uint256) {
    return _currentTokenID.add(1);
  }

   
  function _incrementTokenTypeId() private  {
    _currentTokenID++;
  }
}

 

pragma solidity ^0.5.11;


 
contract MyCollectible is ERC1155Tradable {
  constructor(address _proxyRegistryAddress) ERC1155Tradable(
    "MyCollectible",
    "MCB",
    _proxyRegistryAddress
  ) public {
    _setBaseMetadataURI("https://opensea-creatures-api.herokuapp.com/api/creature/");
  }
}

 

pragma solidity ^0.5.12;

 
interface IFactory {
   
  function name() external view returns (string memory);

   
  function symbol() external view returns (string memory);

   
  function numOptions() external view returns (uint256);

   
  function canMint(uint256 _optionId, uint256 _amount) external view returns (bool);

   
  function uri(uint256 _optionId) external view returns (string memory);

   
  function supportsFactoryInterface() external view returns (bool);

   
  function factorySchemaName() external view returns (string memory);

   
  function mint(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) external;

   
   
   

  function safeTransferFrom(address _from, address _to, uint256 _optionId, uint256 _amount, bytes calldata _data) external;

  function balanceOf(address _owner, uint256 _optionId) external view returns (uint256);

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

pragma solidity ^0.5.11;





 
contract MyFactory is IFactory, Ownable {
  using Strings for string;
  using SafeMath for uint256;

  address public proxyRegistryAddress;
  address public nftAddress;
  string constant internal baseMetadataURI = "https://opensea-creatures-api.herokuapp.com/api/";
  uint256 constant UINT256_MAX = ~uint256(0);

   
  uint256 constant SUPPLY_PER_TOKEN_ID = UINT256_MAX;

   
  enum Option {
    Basic,
    Premium,
    Gold
  }
  uint256 constant NUM_OPTIONS = 3;
  mapping (uint256 => uint256) public optionToTokenID;

  constructor(address _proxyRegistryAddress, address _nftAddress) public {
    proxyRegistryAddress = _proxyRegistryAddress;
    nftAddress = _nftAddress;
  }

   
   
   

  function name() external view returns (string memory) {
    return "My Collectible Pre-Sale";
  }

  function symbol() external view returns (string memory) {
    return "MCP";
  }

  function supportsFactoryInterface() external view returns (bool) {
    return true;
  }

  function factorySchemaName() external view returns (string memory) {
    return "ERC1155";
  }

  function numOptions() external view returns (uint256) {
    return NUM_OPTIONS;
  }

  function canMint(uint256 _optionId, uint256 _amount) external view returns (bool) {
    return _canMint(msg.sender, Option(_optionId), _amount);
  }

  function mint(uint256 _optionId, address _toAddress, uint256 _amount, bytes calldata _data) external {
    return _mint(Option(_optionId), _toAddress, _amount, _data);
  }

  function uri(uint256 _optionId) external view returns (string memory) {
    return Strings.strConcat(
      baseMetadataURI,
      "factory/",
      Strings.uint2str(_optionId)
    );
  }

   
  function _mint(
    Option _option,
    address _toAddress,
    uint256 _amount,
    bytes memory _data
  ) internal {
    require(_canMint(msg.sender, _option, _amount), "MyFactory#_mint: CANNOT_MINT_MORE");
    uint256 optionId = uint256(_option);
    MyCollectible nftContract = MyCollectible(nftAddress);
    uint256 id = optionToTokenID[optionId];
    if (id == 0) {
      id = nftContract.create(_toAddress, _amount, "", _data);
      optionToTokenID[optionId] = id;
    } else {
      nftContract.mint(_toAddress, id, _amount, _data);
    }
  }

   
  function balanceOf(
    address _owner,
    uint256 _optionId
  ) public view returns (uint256) {
    if (!_isOwnerOrProxy(_owner)) {
       
      return 0;
    }
    uint256 id = optionToTokenID[_optionId];
    if (id == 0) {
       
      return SUPPLY_PER_TOKEN_ID;
    }

    MyCollectible nftContract = MyCollectible(nftAddress);
    uint256 currentSupply = nftContract.totalSupply(id);
    return SUPPLY_PER_TOKEN_ID.sub(currentSupply);
  }

   
  function safeTransferFrom(
    address  ,
    address _to,
    uint256 _optionId,
    uint256 _amount,
    bytes calldata _data
  ) external {
    _mint(Option(_optionId), _to, _amount, _data);
  }

   
   
   

  function isApprovedForAll(
    address _owner,
    address _operator
  ) public view returns (bool) {
    return owner() == _owner && _isOwnerOrProxy(_operator);
  }

  function _canMint(
    address _fromAddress,
    Option _option,
    uint256 _amount
  ) internal view returns (bool) {
    uint256 optionId = uint256(_option);
    return _amount > 0 && balanceOf(_fromAddress, optionId) >= _amount;
  }

  function _isOwnerOrProxy(
    address _address
  ) internal view returns (bool) {
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    return owner() == _address || address(proxyRegistry.proxies(owner())) == _address;
  }
}

 

pragma solidity ^0.5.12;

 
interface ILootBox {

   
  function name() external view returns (string memory);

   
  function symbol() external view returns (string memory);

   
  function numOptions() external view returns (uint256);

   
  function canMint(uint256 _optionId, uint256 _amount) external view returns (bool);

   
  function uri(uint256 _optionId) external view returns (string memory);

   
  function supportsFactoryInterface() external view returns (bool);

   
  function factorySchemaName() external view returns (string memory);

   
  function open(uint256 _optionId, address _toAddress, uint256 _amount) external;

   
   
   

   
  function setClassForTokenId(uint256 _tokenId, uint256 _classId) external;

   
  function resetClass(uint256 _classId) external;

   
  function withdraw() external;

   
   
   

  function safeTransferFrom(address _from, address _to, uint256 _optionId, uint256 _amount, bytes calldata _data) external;

  function balanceOf(address _owner, uint256 _optionId) external view returns (uint256);

  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 

pragma solidity ^0.5.11;







 
contract MyLootBox is ILootBox, Ownable, Pausable, ReentrancyGuard, MyFactory {
  using SafeMath for uint256;

   
  event LootBoxOpened(uint256 indexed optionId, address indexed buyer, uint256 boxesPurchased, uint256 itemsMinted);
  event Warning(string message, address account);

   
  enum Class {
    Common,
    Rare,
    Epic,
    Legendary,
    Divine,
    Hidden
  }
  uint256 constant NUM_CLASSES = 6;

   
  struct OptionSettings {
     
     
    uint256 quantityPerOpen;
     
    uint16[NUM_CLASSES] classProbabilities;
  }
  mapping (uint256 => OptionSettings) public optionToSettings;
  mapping (uint256 => uint256[]) public classToTokenIds;
  mapping (uint256 => bool) public classIsPreminted;
  uint256 nonce = 0;
  uint256 constant INVERSE_BASIS_POINT = 10000;

   
  constructor(
    address _proxyRegistryAddress,
    address _nftAddress
  ) MyFactory(
    _proxyRegistryAddress,
    _nftAddress
  ) public {
     
     
    setOptionSettings(Option.Basic, 3, [7300, 2100, 400, 100, 50, 50]);
    setOptionSettings(Option.Premium, 5, [7200, 2100, 400, 200, 50, 50]);
    setOptionSettings(Option.Gold, 7, [7000, 2100, 400, 400, 50, 50]);
  }

   
   
   

   
  function setClassForTokenId(
    uint256 _tokenId,
    uint256 _classId
  ) public onlyOwner {
    _checkTokenApproval();
    _addTokenIdToClass(Class(_classId), _tokenId);
  }

   
  function setTokenIdsForClass(
    Class _class,
    uint256[] memory _tokenIds
  ) public onlyOwner {
    uint256 classId = uint256(_class);
    classIsPreminted[classId] = true;
    classToTokenIds[classId] = _tokenIds;
  }

   
  function resetClass(
    uint256 _classId
  ) public onlyOwner {
    delete classIsPreminted[_classId];
    delete classToTokenIds[_classId];
  }

   
  function setTokenIdsForClasses(
    uint256[NUM_CLASSES] memory _tokenIds
  ) public onlyOwner {
    _checkTokenApproval();
    for (uint256 i = 0; i < _tokenIds.length; i++) {
      Class class = Class(i);
      _addTokenIdToClass(class, _tokenIds[i]);
    }
  }

   
  function setOptionSettings(
    Option _option,
    uint256 _quantityPerOpen,
    uint16[NUM_CLASSES] memory _classProbabilities
  ) public onlyOwner {

    OptionSettings memory settings = OptionSettings({
      quantityPerOpen: _quantityPerOpen,
      classProbabilities: _classProbabilities
    });

    optionToSettings[uint256(_option)] = settings;
  }

   
   
   

   
  function open(
    uint256 _optionId,
    address _toAddress,
    uint256 _amount
  ) external {
    _mint(Option(_optionId), _toAddress, _amount, "");
  }

   
  function _mint(
    Option _option,
    address _toAddress,
    uint256 _amount,
    bytes memory  
  ) internal whenNotPaused nonReentrant {
     
    uint256 optionId = uint256(_option);
    OptionSettings memory settings = optionToSettings[optionId];

    require(settings.quantityPerOpen > 0, "MyLootBox#_mint: OPTION_NOT_ALLOWED");
    require(_canMint(msg.sender, _option, _amount), "MyLootBox#_mint: CANNOT_MINT");

     
    for (uint256 i = 0; i < _amount; i++) {
       
      for (uint256 j = 0; j < settings.quantityPerOpen; j++) {
        Class class = _pickRandomClass(settings.classProbabilities);
        _sendTokenWithClass(class, _toAddress, 1);
      }
    }

     
    uint256 totalMinted = _amount.mul(settings.quantityPerOpen);
    emit LootBoxOpened(optionId, _toAddress, _amount, totalMinted);
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }

   
   
   

  function name() external view returns (string memory) {
    return "My Loot Box";
  }

  function symbol() external view returns (string memory) {
    return "MYLOOT";
  }

  function uri(uint256 _optionId) external view returns (string memory) {
    return Strings.strConcat(
      baseMetadataURI,
      "box/",
      Strings.uint2str(_optionId)
    );
  }

   
   
   

   
  function _sendTokenWithClass(
    Class _class,
    address _toAddress,
    uint256 _amount
  ) internal returns (uint256) {
    uint256 classId = uint256(_class);
    MyCollectible nftContract = MyCollectible(nftAddress);
    uint256 tokenId = _pickRandomAvailableTokenIdForClass(_class, _amount);
    if (classIsPreminted[classId]) {
      nftContract.safeTransferFrom(
        owner(),
        _toAddress,
        tokenId,
        _amount,
        ""
      );
    } else if (tokenId == 0) {
      tokenId = nftContract.create(_toAddress, _amount, "", "");
      classToTokenIds[classId].push(tokenId);
    } else {
      nftContract.mint(_toAddress, tokenId, _amount, "");
    }
    return tokenId;
  }

  function _pickRandomClass(
    uint16[NUM_CLASSES] memory _classProbabilities
  ) internal returns (Class) {
    uint16 value = uint16(_random().mod(INVERSE_BASIS_POINT));
     
     
    for (uint256 i = _classProbabilities.length - 1; i > 0; i--) {
      uint16 probability = _classProbabilities[i];
      if (value < probability) {
        return Class(i);
      } else {
        value = value - probability;
      }
    }
    return Class.Common;
  }

  function _pickRandomAvailableTokenIdForClass(
    Class _class,
    uint256 _minAmount
  ) internal returns (uint256) {
    uint256 classId = uint256(_class);
    uint256[] memory tokenIds = classToTokenIds[classId];
    if (tokenIds.length == 0) {
       
      require(
        !classIsPreminted[classId],
        "MyLootBox#_pickRandomAvailableTokenIdForClass: NO_TOKEN_ON_PREMINTED_CLASS"
      );
      return 0;
    }

    uint256 randIndex = _random().mod(tokenIds.length);

    if (classIsPreminted[classId]) {
       
      MyCollectible nftContract = MyCollectible(nftAddress);
      for (uint256 i = randIndex; i < randIndex + tokenIds.length; i++) {
        uint256 tokenId = tokenIds[i % tokenIds.length];
        if (nftContract.balanceOf(owner(), tokenId) >= _minAmount) {
          return tokenId;
        }
      }
      revert("MyLootBox#_pickRandomAvailableTokenIdForClass: NOT_ENOUGH_TOKENS_FOR_CLASS");
    } else {
      return tokenIds[randIndex];
    }
  }

   
  function _random() internal returns (uint256) {
    uint256 randomNumber = uint256(keccak256(abi.encodePacked(blockhash(block.number - 1), msg.sender, nonce)));
    nonce++;
    return randomNumber;
  }

   
  function _checkTokenApproval() internal {
    MyCollectible nftContract = MyCollectible(nftAddress);
    if (!nftContract.isApprovedForAll(owner(), address(this))) {
      emit Warning("Lootbox contract is not approved for trading collectible by:", owner());
    }
  }

  function _addTokenIdToClass(Class _class, uint256 _tokenId) internal {
    uint256 classId = uint256(_class);
    classIsPreminted[classId] = true;
    classToTokenIds[classId].push(_tokenId);
  }
}