 

pragma solidity ^0.4.24;

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

contract AvatarItemOperator is Operator {

  enum ItemRarity{
    RARITY_LIMITED,
    RARITY_OTEHR
  }

  event ItemCreated(address indexed _owner, uint256 _itemId, ItemRarity _type);
 
  event UpdateLimitedItemCount(bytes8 _hash, uint256 _maxCount);

   
  mapping(bytes8 => uint256) internal itemLimitedCount;
   
  mapping(uint256 => uint256) internal itemPosition;
   
  mapping(bytes8 => uint256) internal itemIndex;

  AvatarItemService internal itemService;
  ERC721 internal ERC721Service;

  constructor() public {
    _setDefaultLimitedItem();
  }

  function injectItemService(AvatarItemService _itemService) external onlyOwner {
    itemService = AvatarItemService(_itemService);
    ERC721Service = ERC721(_itemService);
  }

  function getOwnedItems() external view returns(uint256[] _itemIds) {
    return itemService.getOwnedItems(msg.sender);
  }

  function getItemInfo(uint256 _itemId)
    external 
    view 
    returns(string, string, bool, uint256[4] _attr1, uint8[5] _attr2, uint16[2] _attr3) {
    return itemService.getItemInfo(_itemId);
  }

  function getSameItemCount(uint256 _itemId) external view returns(uint256){
    return itemService.getSameItemCount(_itemId);
  }

  function getSameItemIdByIndex(uint256 _itemId, uint256 _index) external view returns(uint256){
    return itemService.getSameItemIdByIndex(_itemId, _index);
  }

  function getItemHash(uint256 _itemId) external view  returns (bytes8) {
    return itemService.getItemHash(_itemId);
  }

  function isSameItem(uint256 _itemId1, uint256 _itemId2) external view returns (bool) {
    return itemService.isSameItem(_itemId1,_itemId2);
  }

  function getLimitedValue(uint256 _itemId) external view returns(uint256) {
    return itemLimitedCount[itemService.getItemHash(_itemId)];
  }
   
  function getItemPosition(uint256 _itemId) external view returns (uint256 _pos) {
    require(ERC721Service.ownerOf(_itemId) != address(0), "token not exist");
    _pos = itemPosition[_itemId];
  }

  function updateLimitedItemCount(bytes8 _itemBytes8, uint256 _count) public onlyOperator {
    itemLimitedCount[_itemBytes8] = _count;
    emit UpdateLimitedItemCount(_itemBytes8, _count);
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
    require(_attr3[0] >= 0 && _attr3[0] <= 10000, "param must be range to 0 ~ 10000 ");
    require(_attr3[1] >= 0 && _attr3[1] <= 10000, "param must be range to 0 ~ 10000 ");
    _itemId = _mintItem(_owner, _founder, _creator, _isBitizenItem, _attr1, _attr2, _attr3);
  }

   
  function _mintItem( 
    address _owner,
    string _founder,
    string _creator,
    bool _isBitizenItem,
    uint256[4] _attr1,
    uint8[5] _attr2,
    uint16[2] _attr3) 
    internal 
    returns(uint256) {
    uint256 tokenId = itemService.createItem(_owner, _founder, _creator, _isBitizenItem, _attr1, _attr2, _attr3);
    bytes8 itemHash = itemService.getItemHash(tokenId);
    _saveItemIndex(itemHash, tokenId);
    if(itemLimitedCount[itemHash] > 0){
      require(itemService.getSameItemCount(tokenId) <= itemLimitedCount[itemHash], "overflow");   
      emit ItemCreated(_owner, tokenId, ItemRarity.RARITY_LIMITED);
    } else {
      emit ItemCreated(_owner, tokenId,  ItemRarity.RARITY_OTEHR);
    }
    return tokenId;
  }

  function _saveItemIndex(bytes8 _itemHash, uint256 _itemId) private {
    itemIndex[_itemHash]++;
    itemPosition[_itemId] = itemIndex[_itemHash];
  }

  function _setDefaultLimitedItem() private {
    itemLimitedCount[0xc809275c18c405b7] = 3;      
    itemLimitedCount[0x7cb371a84bb16b98] = 100;    
    itemLimitedCount[0x26a27c8bf9dd554b] = 100;    
    itemLimitedCount[0xa8c29099f2421c0b] = 100;    
    itemLimitedCount[0x8060b7c58dce9548] = 100;    
    itemLimitedCount[0x4f7d254af1d033cf] = 25;     
    itemLimitedCount[0x19b6d994c1491e27] = 25;     
    itemLimitedCount[0x71e84d6ef1cf6c85] = 25;     
    itemLimitedCount[0xff5f095a3a3b990f] = 25;     
    itemLimitedCount[0xa066c007ef8c352c] = 1;      
    itemLimitedCount[0x1029368269e054d5] = 1;      
    itemLimitedCount[0xfd0e74b52734b343] = 1;      
    itemLimitedCount[0xf5974771adaa3a6b] = 1;      
    itemLimitedCount[0x405b16d28c964f69] = 10;     
    itemLimitedCount[0x8335384d55547989] = 10;     
    itemLimitedCount[0x679a5e1e0312d35a] = 10;     
    itemLimitedCount[0xe3d973cce112f782] = 10;     
    itemLimitedCount[0xcde6284740e5fde9] = 50;     
  }

  function () public {
    revert();
  }
}