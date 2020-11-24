 

pragma solidity ^0.4.24; 

interface ERC165 {
   
  function supportsInterface(bytes4 _interfaceId) external view returns (bool);
}

interface ERC721   {
     
     
     
     
     
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

     
     
     
     
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

     
     
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

     
     
     
     
     
    function balanceOf(address _owner) external view returns (uint256);

     
     
     
     
     
    function ownerOf(uint256 _tokenId) external view returns (address);

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external;

     
     
     
     
     
     
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId) external;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved) external;

     
     
     
     
    function getApproved(uint256 _tokenId) external view returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

 
interface ERC721Enumerable   {
     
     
     
    function totalSupply() external view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

 
interface ERC721Metadata   {
   
  function name() external view returns (string _name);

   
  function symbol() external view returns (string _symbol);

   
   
   
   
  function tokenURI(uint256 _tokenId) external view returns (string);
}

 
interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
     
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
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

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }
    return size > 0;
  }

}
 
library UrlStr {
  
   
   
  function generateUrl(string url,uint256 _tokenId) internal pure returns (string _url){
    _url = url;
    bytes memory _tokenURIBytes = bytes(_url);
    uint256 base_len = _tokenURIBytes.length - 1;
    _tokenURIBytes[base_len - 7] = byte(48 + _tokenId / 10000000 % 10);
    _tokenURIBytes[base_len - 6] = byte(48 + _tokenId / 1000000 % 10);
    _tokenURIBytes[base_len - 5] = byte(48 + _tokenId / 100000 % 10);
    _tokenURIBytes[base_len - 4] = byte(48 + _tokenId / 10000 % 10);
    _tokenURIBytes[base_len - 3] = byte(48 + _tokenId / 1000 % 10);
    _tokenURIBytes[base_len - 2] = byte(48 + _tokenId / 100 % 10);
    _tokenURIBytes[base_len - 1] = byte(48 + _tokenId / 10 % 10);
    _tokenURIBytes[base_len - 0] = byte(48 + _tokenId / 1 % 10);
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
 
 
contract Ownable {
  address public owner;
  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract Operator is Ownable {

    address[] public operators;

    uint public MAX_OPS = 20;  

    mapping(address => bool) public isOperator;

    event OperatorAdded(address operator);
    event OperatorRemoved(address operator);

     
    modifier onlyOperator() {
        require(
            isOperator[msg.sender] || msg.sender == owner,
            "Permission denied. Must be an operator or the owner."
        );
        _;
    }

     
    function addOperator(address _newOperator) public onlyOwner {
        require(
            _newOperator != address(0),
            "Invalid new operator address."
        );

         
        require(
            !isOperator[_newOperator],
            "New operator exists."
        );

         
        require(
            operators.length < MAX_OPS,
            "Overflow."
        );

        operators.push(_newOperator);
        isOperator[_newOperator] = true;

        emit OperatorAdded(_newOperator);
    }

     
    function removeOperator(address _operator) public onlyOwner {
         
        require(
            operators.length > 0,
            "No operator."
        );

         
        require(
            isOperator[_operator],
            "Not an operator."
        );

         
         
         
        address lastOperator = operators[operators.length - 1];
        for (uint i = 0; i < operators.length; i++) {
            if (operators[i] == _operator) {
                operators[i] = lastOperator;
            }
        }
        operators.length -= 1;  

        isOperator[_operator] = false;
        emit OperatorRemoved(_operator);
    }

     
    function removeAllOps() public onlyOwner {
        for (uint i = 0; i < operators.length; i++) {
            isOperator[operators[i]] = false;
        }
        operators.length = 0;
    }
}
 
contract Pausable is Operator {

  event FrozenFunds(address target, bool frozen);

  bool public isPaused = false;
  
  mapping(address => bool)  frozenAccount;

  modifier whenNotPaused {
    require(!isPaused);
    _;
  }

  modifier whenPaused {
    require(isPaused);
    _;  
  }

  modifier whenNotFreeze(address _target) {
    require(_target != address(0));
    require(!frozenAccount[_target]);
    _;
  }

  function isFrozen(address _target) external view returns (bool) {
    require(_target != address(0));
    return frozenAccount[_target];
  }

  function doPause() external  whenNotPaused onlyOwner {
    isPaused = true;
  }

  function doUnpause() external  whenPaused onlyOwner {
    isPaused = false;
  }

  function freezeAccount(address _target, bool _freeze) public onlyOwner {
    require(_target != address(0));
    frozenAccount[_target] = _freeze;
    emit FrozenFunds(_target, _freeze);
  }

}

contract ERC721BasicToken is SupportsInterfaceWithLookup, ERC721, Pausable{

  bytes4 public constant InterfaceId_ERC721 = 0x80ac58cd;
   

  bytes4 public constant InterfaceId_ERC721Exists = 0x4f558e79;
   

  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 public constant ERC721_RECEIVED = 0x150b7a02;

   
  mapping (uint256 => address) internal tokenOwner;

   
  mapping (uint256 => address) internal tokenApprovals;

   
  mapping (address => uint256) internal ownedTokensCount;

   
  mapping (address => mapping (address => bool)) internal operatorApprovals;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(_ownerOf(_tokenId) == msg.sender,"This token not owned by this address");
    _;
  }
  
  function _ownerOf(uint256 _tokenId) internal view returns(address) {
    address _owner = tokenOwner[_tokenId];
    require(_owner != address(0),"Token not exist");
    return _owner;
  }

   
  modifier canTransfer(uint256 _tokenId) {
    require(isApprovedOrOwner(msg.sender, _tokenId), "This address have no permisstion");
    _;
  }

  constructor()
    public
  {
     
    _registerInterface(InterfaceId_ERC721);
    _registerInterface(InterfaceId_ERC721Exists);
    _registerInterface(ERC721_RECEIVED);
  }

   
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownedTokensCount[_owner];
  }

   
  function ownerOf(uint256 _tokenId) external view returns (address) {
    return _ownerOf(_tokenId);
  }

   
  function exists(uint256 _tokenId) internal view returns (bool) {
    address owner = tokenOwner[_tokenId];
    return owner != address(0);
  }

   
  function approve(address _to, uint256 _tokenId) external whenNotPaused {
    address _owner = _ownerOf(_tokenId);
    require(_to != _owner);
    require(msg.sender == _owner || operatorApprovals[_owner][msg.sender]);

    tokenApprovals[_tokenId] = _to;
    emit Approval(_owner, _to, _tokenId);
  }

   
  function getApproved(uint256 _tokenId) external view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) external whenNotPaused {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
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
    external
    canTransfer(_tokenId)
  {
    _transfer(_from,_to,_tokenId);
  }


  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId) internal {
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
    external
    canTransfer(_tokenId)
  {
     
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function _safeTransferFrom( 
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data) internal {
    _transfer(_from, _to, _tokenId);
       
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    external
    canTransfer(_tokenId)
  {
    _safeTransferFrom(_from, _to, _tokenId, _data);
   
  }

   
  function isApprovedOrOwner (
    address _spender,
    uint256 _tokenId
  )
    internal
    view
    returns (bool)
  {
    address _owner = _ownerOf(_tokenId);
     
     
     
    return (
      _spender == _owner ||
      tokenApprovals[_tokenId] == _spender ||
      operatorApprovals[_owner][_spender]
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

   
  function clearApproval(address _owner, uint256 _tokenId) internal whenNotPaused {
    require(_ownerOf(_tokenId) == _owner);
    if (tokenApprovals[_tokenId] != address(0)) {
      tokenApprovals[_tokenId] = address(0);
    }
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    require(tokenOwner[_tokenId] == address(0));
    require(!frozenAccount[_to]);  
    tokenOwner[_tokenId] = _to;
    ownedTokensCount[_to] = ownedTokensCount[_to].add(1);
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused {
    require(_ownerOf(_tokenId) == _from);
    require(!frozenAccount[_from]);  
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
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
      msg.sender, _from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}
 
contract ERC721ExtendToken is ERC721BasicToken, ERC721Enumerable, ERC721Metadata {

  using UrlStr for string;

  bytes4 public constant InterfaceId_ERC721Enumerable = 0x780e9d63;
   

  bytes4 public constant InterfaceId_ERC721Metadata = 0x5b5e139f;
   
  string internal BASE_URL = "https://www.bitguild.com/bitizens/api/item/getItemInfo/00000000";

   
  mapping(address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

  function updateBaseURI(string _url) external onlyOwner {
    BASE_URL = _url;
  }
  
   
  constructor() public {
     
    _registerInterface(InterfaceId_ERC721Enumerable);
    _registerInterface(InterfaceId_ERC721Metadata);
  }

   
  function name() external view returns (string) {
    return "Bitizen item";
  }

   
  function symbol() external view returns (string) {
    return "ITMT";
  }

   
  function tokenURI(uint256 _tokenId) external view returns (string) {
    require(exists(_tokenId));
    return BASE_URL.generateUrl(_tokenId);
  }

   
  function tokenOfOwnerByIndex(
    address _owner,
    uint256 _index
  )
    public
    view
    returns (uint256)
  {
    require(address(0)!=_owner);
    require(_index < ownedTokensCount[_owner]);
    return ownedTokens[_owner][_index];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
  }

   
  function addTokenTo(address _to, uint256 _tokenId) internal whenNotPaused {
    super.addTokenTo(_to, _tokenId);
    uint256 length = ownedTokens[_to].length;
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
  }

   
  function removeTokenFrom(address _from, uint256 _tokenId) internal whenNotPaused {
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

 
interface AvatarChildService {
   
   function compareItemSlots(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _res);

   
   function isAvatarChild(uint256 _tokenId) external view returns(bool);
}

interface AvatarItemService {

  function getTransferTimes(uint256 _tokenId) external view returns(uint256);
  function getOwnedItems(address _owner) external view returns(uint256[] _tokenIds);
  
  function getItemInfo(uint256 _tokenId)
    external 
    view 
    returns(string, string, bool, uint256[4] _attr1, uint8[5] _attr2, uint16[2] _attr3);

  function isBurned(uint256 _tokenId) external view returns (bool); 
  function isSameItem(uint256 _tokenId1, uint256 _tokenId2) external view returns (bool _isSame);
  function getBurnedItemCount() external view returns (uint256);
  function getBurnedItemByIndex(uint256 _index) external view returns (uint256);
  function getSameItemCount(uint256 _tokenId) external view returns(uint256);
  function getSameItemIdByIndex(uint256 _tokenId, uint256 _index) external view returns(uint256);
  function getItemHash(uint256 _tokenId) external view returns (bytes8); 

  function burnItem(address _owner, uint256 _tokenId) external;
   
  function createItem( 
    address _owner,
    string _founder,
    string _creator, 
    bool _isBitizenItem, 
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3)
    external  
    returns(uint256 _tokenId);

  function updateItem(
    uint256 _tokenId,
    bool  _isBitizenItem,
    uint16 _miningTime,
    uint16 _magicFind,
    uint256 _node,
    uint256 _listNumber,
    uint256 _setNumber,
    uint256 _quality,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _energy,
    uint8 _ext
  ) 
  external;
}

contract AvatarItemToken is ERC721ExtendToken, AvatarItemService, AvatarChildService {

  enum ItemHandleType{NULL, CREATE_ITEM, UPDATE_ITEM, BURN_ITEM}
  
  event ItemHandleEvent(address indexed _owner, uint256 indexed _itemId,ItemHandleType _type);

  struct AvatarItem {
    string foundedBy;      
    string createdBy;      
    bool isBitizenItem;    
    uint16 miningTime;     
    uint16 magicFind;      
    uint256 node;          
    uint256 listNumber;    
    uint256 setNumber;     
    uint256 quality;       
    uint8 rarity;          
    uint8 socket;          
    uint8 gender;          
    uint8 energy;          
    uint8 ext;             
  }
  
   
  uint256 internal itemIndex = 0;
   
  mapping(uint256 => AvatarItem) internal avatarItems;
   
  uint256[] internal burnedItemIds;
   
  mapping(uint256 => bool) internal isBurnedItem;
   
  mapping(bytes8 => uint256[]) internal sameItemIds;
   
  mapping(uint256 => uint256) internal sameItemIdIndex;
   
  mapping(uint256 => bytes8) internal itemIdToHash;
   
  mapping(uint256 => uint256) internal itemTransferCount;

   
  address internal avatarAccount = this;

   
  modifier validItem(uint256 _itemId) {
    require(_itemId > 0 && _itemId <= itemIndex, "token not vaild");
    _;
  }

  modifier itemExists(uint256 _itemId){
    require(exists(_itemId), "token error");
    _;
  }

  function setDefaultApprovalAccount(address _account) public onlyOwner {
    avatarAccount = _account;
  }

  function compareItemSlots(uint256 _itemId1, uint256 _itemId2)
    external
    view
    itemExists(_itemId1)
    itemExists(_itemId2)
    returns (bool) {
    require(_itemId1 != _itemId2, "compared token shouldn't be the same");
    return avatarItems[_itemId1].socket == avatarItems[_itemId2].socket;
  }

  function isAvatarChild(uint256 _itemId) external view returns(bool){
    return true;
  }

  function getTransferTimes(uint256 _itemId) external view validItem(_itemId) returns(uint256) {
    return itemTransferCount[_itemId];
  }

  function getOwnedItems(address _owner) external view onlyOperator returns(uint256[] _items) {
    require(_owner != address(0), "address invalid");
    return ownedTokens[_owner];
  }

  function getItemInfo(uint256 _itemId)
    external 
    view 
    validItem(_itemId)
    returns(string, string, bool, uint256[4] _attr1, uint8[5] _attr2, uint16[2] _attr3) {
    AvatarItem storage item = avatarItems[_itemId];
    _attr1[0] = item.node;
    _attr1[1] = item.listNumber;
    _attr1[2] = item.setNumber;
    _attr1[3] = item.quality;  
    _attr2[0] = item.rarity;
    _attr2[1] = item.socket;
    _attr2[2] = item.gender;
    _attr2[3] = item.energy;
    _attr2[4] = item.ext;
    _attr3[0] = item.miningTime;
    _attr3[1] = item.magicFind;
    return (item.foundedBy, item.createdBy, item.isBitizenItem, _attr1, _attr2, _attr3);
  }

  function isBurned(uint256 _itemId) external view validItem(_itemId) returns (bool) {
    return isBurnedItem[_itemId];
  }

  function getBurnedItemCount() external view returns (uint256) {
    return burnedItemIds.length;
  }

  function getBurnedItemByIndex(uint256 _index) external view returns (uint256) {
    require(_index < burnedItemIds.length, "out of boundary");
    return burnedItemIds[_index];
  }

  function getSameItemCount(uint256 _itemId) external view validItem(_itemId) returns(uint256) {
    return sameItemIds[itemIdToHash[_itemId]].length;
  }
  
  function getSameItemIdByIndex(uint256 _itemId, uint256 _index) external view validItem(_itemId) returns(uint256) {
    bytes8 itemHash = itemIdToHash[_itemId];
    uint256[] storage items = sameItemIds[itemHash];
    require(_index < items.length, "out of boundray");
    return items[_index];
  }

  function getItemHash(uint256 _itemId) external view validItem(_itemId) returns (bytes8) {
    return itemIdToHash[_itemId];
  }

  function isSameItem(uint256 _itemId1, uint256 _itemId2)
    external
    view
    validItem(_itemId1)
    validItem(_itemId2)
    returns (bool _isSame) {
    if(_itemId1 == _itemId2) {
      _isSame = true;
    } else {
      _isSame = _calcuItemHash(_itemId1) == _calcuItemHash(_itemId2);
    }
  }

  function burnItem(address _owner, uint256 _itemId) external onlyOperator itemExists(_itemId) {
    _burnItem(_owner, _itemId);
  }

  function createItem( 
    address _owner,
    string _founder,
    string _creator, 
    bool _isBitizenItem, 
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3)
    external  
    onlyOperator
    returns(uint256 _itemId) {
    require(_owner != address(0), "address invalid");
    AvatarItem memory item = _mintItem(_founder, _creator, _isBitizenItem, _attr1, _attr2, _attr3);
    _itemId = ++itemIndex;
    avatarItems[_itemId] = item;
    _mint(_owner, _itemId);
    _saveItemHash(_itemId);
    emit ItemHandleEvent(_owner, _itemId, ItemHandleType.CREATE_ITEM);
  }

  function updateItem(
    uint256 _itemId,
    bool  _isBitizenItem,
    uint16 _miningTime,
    uint16 _magicFind,
    uint256 _node,
    uint256 _listNumber,
    uint256 _setNumber,
    uint256 _quality,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _energy,
    uint8 _ext
  ) 
  external 
  onlyOperator
  itemExists(_itemId){
    _deleteOldValue(_itemId); 
    _updateItem(_itemId,_isBitizenItem,_miningTime,_magicFind,_node,_listNumber,_setNumber,_quality,_rarity,_socket,_gender,_energy,_ext);
    _saveItemHash(_itemId);
  }

  function _deleteOldValue(uint256 _itemId) private {
    uint256[] storage tokenIds = sameItemIds[itemIdToHash[_itemId]];
    require(tokenIds.length > 0);
    uint256 lastTokenId = tokenIds[tokenIds.length - 1];
    tokenIds[sameItemIdIndex[_itemId]] = lastTokenId;
    sameItemIdIndex[lastTokenId] = sameItemIdIndex[_itemId];
    tokenIds.length--;
  }

  function _saveItemHash(uint256 _itemId) private {
    bytes8 itemHash = _calcuItemHash(_itemId);
    uint256 index = sameItemIds[itemHash].push(_itemId);
    sameItemIdIndex[_itemId] = index - 1;
    itemIdToHash[_itemId] = itemHash;
  }
    
  function _calcuItemHash(uint256 _itemId) private view returns (bytes8) {
    AvatarItem storage item = avatarItems[_itemId];
    bytes memory itemBytes = abi.encodePacked(
      item.isBitizenItem,
      item.miningTime,
      item.magicFind,
      item.node,
      item.listNumber,
      item.setNumber,
      item.quality,
      item.rarity,
      item.socket,
      item.gender,
      item.energy,
      item.ext
      );
    return bytes8(keccak256(itemBytes));
  }

  function _mintItem(  
    string _foundedBy,
    string _createdBy, 
    bool _isBitizenItem, 
    uint256[4] _attr1, 
    uint8[5] _attr2,
    uint16[2] _attr3) 
    private
    pure
    returns(AvatarItem _item) {
    _item = AvatarItem(
      _foundedBy,
      _createdBy,
      _isBitizenItem, 
      _attr3[0], 
      _attr3[1], 
      _attr1[0],
      _attr1[1], 
      _attr1[2], 
      _attr1[3],
      _attr2[0], 
      _attr2[1], 
      _attr2[2], 
      _attr2[3],
      _attr2[4]
    );
  }

  function _updateItem(
    uint256 _itemId,
    bool  _isBitizenItem,
    uint16 _miningTime,
    uint16 _magicFind,
    uint256 _node,
    uint256 _listNumber,
    uint256 _setNumber,
    uint256 _quality,
    uint8 _rarity,
    uint8 _socket,
    uint8 _gender,
    uint8 _energy,
    uint8 _ext
  ) private {
    AvatarItem storage item = avatarItems[_itemId];
    item.isBitizenItem = _isBitizenItem;
    item.miningTime = _miningTime;
    item.magicFind = _magicFind;
    item.node = _node;
    item.listNumber = _listNumber;
    item.setNumber = _setNumber;
    item.quality = _quality;
    item.rarity = _rarity;
    item.socket = _socket;
    item.gender = _gender;  
    item.energy = _energy; 
    item.ext = _ext; 
    emit ItemHandleEvent(_ownerOf(_itemId), _itemId, ItemHandleType.UPDATE_ITEM);
  }

  function _burnItem(address _owner, uint256 _itemId) private {
    burnedItemIds.push(_itemId);
    isBurnedItem[_itemId] = true;
    _burn(_owner, _itemId);
    emit ItemHandleEvent(_owner, _itemId, ItemHandleType.BURN_ITEM);
  }

   
   
  function _mint(address _to, uint256 _itemId) internal {
    super._mint(_to, _itemId);
    operatorApprovals[_to][avatarAccount] = true;
  }

   
   
  function _transfer(address _from, address _to, uint256 _itemId) internal {
    super._transfer(_from, _to, _itemId);
    itemTransferCount[_itemId]++;
  }

  function () public payable {
    revert();
  }
}