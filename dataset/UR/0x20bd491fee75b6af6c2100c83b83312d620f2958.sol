 

pragma solidity 0.5.1;

 

 
contract ERC20Interface {
  function transfer(address to, uint tokens) public returns (bool success);
  event Transfer(address indexed from, address indexed to, uint tokens);
}

 
interface ERC165 {

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool);
}

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
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
}


 
contract ERC721Receiver {
   
  bytes4 internal constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(
    address _from,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    returns(bytes4);
}

 
contract SupportsInterfaceWithLookup is ERC165 {
  bytes4 public constant InterfaceId_ERC165 = 0x01ffc9a7;
   

   
  mapping(bytes4 => bool) internal supportedInterfaces;

   
  constructor()
    public
  {
    _registerInterface(InterfaceId_ERC165);
  }

   
  function supportsInterface(bytes4 _interfaceId)
    external
    view
    returns (bool)
  {
    return supportedInterfaces[_interfaceId];
  }

   
  function _registerInterface(bytes4 _interfaceId)
    internal
  {
    require(_interfaceId != 0xffffffff);
    supportedInterfaces[_interfaceId] = true;
  }
}

 
contract Pausable {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;
  address public pauser;

  constructor () internal {
    _paused = false;
    pauser = msg.sender;
  }

   
  function paused() public view returns (bool) {
    return _paused;
  }

   
  modifier onlyPauser() {
    require(msg.sender == pauser);
    _;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }


   
  function pause() public onlyPauser {
    require(!_paused);
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser {
    require(_paused);
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 
contract ERC721Basic is ERC165, Pausable {
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId)
    public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator)
    public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId)
    public;

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public;
}

 
contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721Basic {

  bytes4 private constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 private constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 private constant ERC721_RECEIVED = 0xf0b9e5ba;

   
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

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
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

   
  function approve(address _to, uint256 _tokenId) public whenNotPaused {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    tokenApprovals[_tokenId] = _to;
    emit Approval(owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public whenNotPaused {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    public
    view
    returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    canTransfer(_tokenId)
    whenNotPaused
  {
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
    whenNotPaused
  {
     
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes memory _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
     
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address owner = ownerOf(_tokenId);
     
     
     
    return (
      _spender == owner ||
      getApproved(_tokenId) == _spender ||
      isApprovedForAll(owner, _spender)
    );
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
    bytes memory _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(
      _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}

 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256 _tokenId);

  function tokenByIndex(uint256 _index) public view returns (uint256);
}

 
contract ERC721Metadata is ERC721Basic {
  function name() external view returns (string memory _name);
  function symbol() external view returns (string memory _symbol);
  function tokenURI(uint256 _tokenId) public view returns (string memory);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable, ERC721Metadata {
}

 
contract ERC721Token is SupportsInterfaceWithLookup, ERC721BasicToken, ERC721 {

  bytes4 private constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 private constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   

   
  string internal name_;

   
  string internal symbol_;

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  mapping(uint256 => string) internal tokenURIs;

   
  constructor(string memory _name, string memory _symbol) public {
    name_ = _name;
    symbol_ = _symbol;

     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string memory) {
    return name_;
  }

   
  function symbol() external view returns (string memory) {
    return symbol_;
  }

   
  function tokenURI(uint256 _tokenId) public view returns (string memory) {
    require(exists(_tokenId));
    return tokenURIs[_tokenId];
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
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

   
  function _setTokenURI(uint256 _tokenId, string memory _uri) internal {
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

 
contract Ownership is Pausable {
  address public owner;
  event OwnershipUpdated(address oldOwner, address newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function updateOwner(address _newOwner)
    public
    onlyOwner
    whenNotPaused
  {
    owner = _newOwner;
    emit OwnershipUpdated(msg.sender, owner);
  }
}

 
contract Operators is Ownership {
   
  address[] private operators;
  uint8 MAX_OP_LEVEL;
  mapping (address => uint8) operatorLevel;  

   
  event OperatorAdded (address _operator, uint8 _level);
  event OperatorUpdated (address _operator, uint8 _level);
  event OperatorRemoved (address _operator);

  constructor()
    public
  {
    MAX_OP_LEVEL = 3;
  }

  modifier onlyLevel(uint8 level) {
    uint8 opLevel = getOperatorLevel(msg.sender);
    if (level > 0) {
      require( opLevel <= level && opLevel != 0);
      _;
    } else {
      _;
    }
  }

  modifier onlyValidLevel(uint8 _level){
    require(_level> 0 && _level <= MAX_OP_LEVEL);
    _;
  }

  function addOperator(address _newOperator, uint8 _level)
    public 
    onlyOwner
    whenNotPaused
    onlyValidLevel(_level)
    returns (bool)
  {
    require (operatorLevel[_newOperator] == 0);  
    operatorLevel[_newOperator] = _level;
    operators.push(_newOperator);
    emit OperatorAdded(_newOperator, _level);
    return true;
  }

  function updateOperator(address _operator, uint8 _level)
    public
    onlyOwner
    whenNotPaused
    onlyValidLevel(_level)
    returns (bool)
  {
    require (operatorLevel[_operator] != 0);  
    operatorLevel[_operator] = _level;
    emit OperatorUpdated(_operator, _level);
    return true;
  }

  function removeOperatorByIndex(uint index)
    public
    onlyOwner
    whenNotPaused
    returns (bool)
  {
    index = index - 1;
    operatorLevel[operators[index]] = 0;
    operators[index] = operators[operators.length - 1];
    operators.length -- ;
    return true;

  }

  
     
  function removeOperator(address _operator)
    public
    onlyOwner
    whenNotPaused
    returns (bool)
  {
    uint index = getOperatorIndex(_operator);
    require(index > 0);
    return removeOperatorByIndex(index);
  }

  function getOperatorIndex(address _operator)
    public
    view
    returns (uint)
  {
    for (uint i=0; i<operators.length; i++) {
      if (operators[i] == _operator) return i+1;
    }
    return 0;
  }

  function getOperators()
    public
    view
    returns (address[] memory)
  {
    return operators;
  }

  function getOperatorLevel(address _operator)
    public
    view
    returns (uint8)
  {
    return operatorLevel[_operator];
  }

}

 
contract RealityClashWeapon is ERC721Token, Operators {

   
  mapping (uint => string) gameDataOf;
  mapping (uint => string) weaponDataOf;
  mapping (uint => string) ownerDataOf;

 
  event WeaponAdded(uint indexed weaponId, string gameData, string weaponData, string ownerData, string tokenURI);
  event WeaponUpdated(uint indexed weaponId, string gameData, string weaponData, string ownerData, string tokenURI);
  event WeaponOwnerUpdated (uint indexed  _weaponId, address indexed  _oldOwner, address indexed  _newOwner);

  constructor() public  ERC721Token('Reality Clash Weapon', 'RC GUN'){
  }

   
  function mint(uint256 _id, string memory _gameData, string memory _weaponData, string memory _ownerData, address _to)
    public
    onlyLevel(1)
    whenNotPaused
  {
    super._mint(_to, _id);
    gameDataOf[_id] = _gameData;
    weaponDataOf[_id] = _weaponData;
    ownerDataOf[_id] = _ownerData;
    emit WeaponAdded(_id, _gameData, _weaponData, _ownerData, '');
  }

   
  function mintWithURI(uint256 _id, address _to, string memory _uri)
    public
    onlyLevel(1)
    whenNotPaused
  {
    super._mint(_to, _id);
    super._setTokenURI(_id, _uri);
    emit WeaponAdded(_id, '', '', '', _uri);
  }


   
  function transfer(address _to, uint256 _tokenId)
    public
    whenNotPaused
  {
    safeTransferFrom(msg.sender, _to, _tokenId);
  }

   
  function updateMetaData(uint _id, string memory _gameData, string memory _weaponData, string memory _ownerData)
    public 
    onlyLevel(2)
    whenNotPaused
  {
    gameDataOf[_id] = _gameData;
    weaponDataOf[_id] = _weaponData;
    ownerDataOf[_id] = _ownerData;
  }

   
  function burn(uint _id)
    public
    whenNotPaused
  {
   super._burn(msg.sender, _id);
  }


   
  function updateGameData (uint _id, string memory _gameData)
    public
    onlyLevel(2)
    whenNotPaused
    returns(bool)
  {
    gameDataOf[_id] = _gameData;
    emit WeaponUpdated(_id, _gameData, "", "", "");
    return true;
  }

   
  function updateWeaponData (uint _id,  string memory _weaponData)
    public 
    onlyLevel(2)
    whenNotPaused
    returns(bool) 
  {
    weaponDataOf[_id] = _weaponData;
    emit WeaponUpdated(_id, "", _weaponData, "", "");
    return true;
  }

   
  function updateOwnerData (uint _id, string memory _ownerData)
    public
    onlyLevel(2)
    whenNotPaused
    returns(bool)
  {
    ownerDataOf[_id] = _ownerData;
    emit WeaponUpdated(_id, "", "", _ownerData, "");
    return true;
  }

   
  function updateURI (uint _id, string memory _uri)
    public
    onlyLevel(2)
    whenNotPaused
    returns(bool)
  {
    super._setTokenURI(_id, _uri);
    emit WeaponUpdated(_id, "", "", "", _uri);
    return true;
  }

   
   
   

   
  function getGameData (uint _id) public view returns(string memory _gameData) {
    return gameDataOf[_id];
  }

   
  function getWeaponData (uint _id) public view returns(string memory _pubicData) {
    return weaponDataOf[_id];
  }

   
  function getOwnerData (uint _id) public view returns(string memory _ownerData) {
    return ownerDataOf[_id] ;
  }

   
  function getMetaData (uint _id) public view returns(string memory _gameData,string memory _pubicData,string memory _ownerData ) {
    return (gameDataOf[_id], weaponDataOf[_id], ownerDataOf[_id]);
  }
}


 
contract AdvancedRealityClashWeapon is RealityClashWeapon {

   
  mapping(address => uint) private userNonce;

  bool public isNormalUserAllowed;  
  
  constructor() public {
    isNormalUserAllowed = false;
  }

   
  function allowNormalUser(bool _perm)
    public 
    onlyOwner
    whenNotPaused
  {
    isNormalUserAllowed = _perm;
  }

   
  function provable_setApprovalForAll(bytes32 message, bytes32 r, bytes32 s, uint8 v, address spender, bool approved)
    public
    whenNotPaused
  {
    if (!isNormalUserAllowed) {
      uint8 opLevel = getOperatorLevel(msg.sender);
      require (opLevel != 0 && opLevel < 3);  
    }
    address signer = getSigner(message, r, s, v);
    require (signer != address(0));

    bytes32 proof = getMessageSendApprovalForAll(signer, spender, approved);
    require( proof == message);

     
    operatorApprovals[signer][spender] = approved;
    emit ApprovalForAll(signer, spender, approved);
    userNonce[signer] = userNonce[signer].add(1);
  }

   
  function provable_transfer(bytes32 message, bytes32 r, bytes32 s, uint8 v, address to, uint tokenId)
    public 
    whenNotPaused
  {
    if (!isNormalUserAllowed) {
      uint8 opLevel = getOperatorLevel(msg.sender);
      require (opLevel != 0 && opLevel < 3);  
    }
    address signer = getSigner(message, r, s, v);
    require (signer != address(0));

    bytes32 proof = getMessageTransfer(signer, to, tokenId);
    require (proof == message);
    
     
    require(to != address(0));
    clearApproval(signer, tokenId);
    removeTokenFrom(signer, tokenId);
    addTokenTo(to, tokenId);
    emit Transfer(signer, to, tokenId);

     
    userNonce[signer] = userNonce[signer].add(1);
  }

   
  function getSigner(bytes32 message, bytes32 r, bytes32 s,  uint8 v) public pure returns (address){
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, message));
    address signer = ecrecover(prefixedHash,v,r,s);
    return signer;
  }

   
  function getMessageTransfer(address signer, address to, uint id)
    public
    view
    returns (bytes32) 
  {
    return keccak256(abi.encodePacked(
      bytes4(0xb483afd3),
      address(this),
      userNonce[signer],
      to,
      id
    ));
  }

   
  function getMessageSendApprovalForAll(address signer, address spender, bool approved)
    public 
    view 
    returns (bytes32)
  {
    bytes32 proof = keccak256(abi.encodePacked(
      bytes4(0xbad4c8ea),
      address(this),
      userNonce[signer],
      spender,
      approved
    ));
    return proof;
  }

   
  function getUserNonce(address user) public view returns (uint) {
    return userNonce[user];
  }

   
  function transferAnyERC20Token(address contractAddress, address to,  uint value) public onlyOwner {
    ERC20Interface(contractAddress).transfer(to, value);
  }

   
  function withdrawAnyERC721Token(address contractAddress, address to, uint tokenId) public onlyOwner {
    ERC721Basic(contractAddress).safeTransferFrom(address(this), to, tokenId);
  }

   
  function kill(uint message) public onlyOwner {
    require (message == 123456789987654321);
     
    selfdestruct(msg.sender);
  }

}