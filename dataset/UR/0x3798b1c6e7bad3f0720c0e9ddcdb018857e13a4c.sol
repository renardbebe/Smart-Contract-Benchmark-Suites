 

pragma solidity ^0.4.18;
 
 
 
contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

contract AccessAdmin is Ownable {

   
  mapping (address => bool) adminContracts;

   
  mapping (address => bool) actionContracts;

  function setAdminContract(address _addr, bool _useful) public onlyOwner {
    require(_addr != address(0));
    adminContracts[_addr] = _useful;
  }

  modifier onlyAdmin {
    require(adminContracts[msg.sender]); 
    _;
  }

  function setActionContract(address _actionAddr, bool _useful) public onlyAdmin {
    actionContracts[_actionAddr] = _useful;
  }

  modifier onlyAccess() {
    require(actionContracts[msg.sender]);
    _;
  }
}

 
 
 
contract ERC721   {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);
  
  function balanceOf(address _owner) external view returns (uint256);
  function ownerOf(uint256 _tokenId) external view returns (address);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function transferFrom(address _from, address _to, uint256 _tokenId) external payable;
  function approve(address _approved, uint256 _tokenId) external payable;
  function setApprovalForAll(address _operator, bool _approved) external;
  function getApproved(uint256 _tokenId) external view returns (address);
  function isApprovedForAll(address _owner, address _operator) external view returns (bool);
}

interface ERC165 {
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

 
interface ERC721TokenReceiver {
  function onERC721Received(address _from, uint256 _tokenId, bytes data) external returns(bytes4);
}

 
 
 
 

 
 
 
interface ERC721Enumerable   {
  function totalSupply() external view returns (uint256);
  function tokenByIndex(uint256 _index) external view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

contract RareCards is AccessAdmin, ERC721 {
  using SafeMath for SafeMath;
   
  event eCreateRare(uint256 tokenId, uint256 price, address owner);

   
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  struct RareCard {
    uint256 rareId;      
    uint256 rareClass;   
    uint256 cardId;      
    uint256 rareValue;   
  }

  RareCard[] public rareArray;  

  function RareCards() public {
    rareArray.length += 1;
    setAdminContract(msg.sender,true);
    setActionContract(msg.sender,true);
  }

   
  uint256 private constant PROMO_CREATION_LIMIT = 20;
  uint256 private constant startPrice = 0.5 ether;

  address thisAddress = this;
  uint256 PLATPrice = 65000;
   
   
  mapping (uint256 => address) public IndexToOwner;
   
  mapping (uint256 => uint256) indexOfOwnedToken;
   
  mapping (address => uint256[]) ownerToRareArray;
   
  mapping (uint256 => uint256) IndexToPrice;
   
  mapping (uint256 => address) public IndexToApproved;
   
  mapping (address => mapping(address => bool)) operatorToApprovals;

   
   
  modifier isValidToken(uint256 _tokenId) {
    require(_tokenId >= 1 && _tokenId <= rareArray.length);
    require(IndexToOwner[_tokenId] != address(0)); 
    _;
  }
   
  modifier onlyOwnerOf(uint _tokenId) {
    require(msg.sender == IndexToOwner[_tokenId] || msg.sender == IndexToApproved[_tokenId]);
    _;
  }

   
  function createRareCard(uint256 _rareClass, uint256 _cardId, uint256 _rareValue) public onlyOwner {
    require(rareArray.length < PROMO_CREATION_LIMIT); 
    _createRareCard(thisAddress, startPrice, _rareClass, _cardId, _rareValue);
  }


   
  function _createRareCard(address _owner, uint256 _price, uint256 _rareClass, uint256 _cardId, uint256 _rareValue) internal returns(uint) {
    uint256 newTokenId = rareArray.length;
    RareCard memory _rarecard = RareCard({
      rareId: newTokenId,
      rareClass: _rareClass,
      cardId: _cardId,
      rareValue: _rareValue
    });
    rareArray.push(_rarecard);
     
    eCreateRare(newTokenId, _price, _owner);

    IndexToPrice[newTokenId] = _price;
     
     
    _transfer(address(0), _owner, newTokenId);

  } 

   
   
   
   
  function _transfer(address _from, address _to, uint256 _tokenId) internal {
    if (_from != address(0)) {
      uint256 indexFrom = indexOfOwnedToken[_tokenId];
      uint256[] storage rareArrayOfOwner = ownerToRareArray[_from];
      require(rareArrayOfOwner[indexFrom] == _tokenId);

       
      if (indexFrom != rareArrayOfOwner.length - 1) {
        uint256 lastTokenId = rareArrayOfOwner[rareArrayOfOwner.length - 1];
        rareArrayOfOwner[indexFrom] = lastTokenId;
        indexOfOwnedToken[lastTokenId] = indexFrom;
      }
      rareArrayOfOwner.length -= 1;

       
      if (IndexToApproved[_tokenId] != address(0)) {
        delete IndexToApproved[_tokenId];
      } 
    }
     
    IndexToOwner[_tokenId] = _to;
    ownerToRareArray[_to].push(_tokenId);
    indexOfOwnedToken[_tokenId] = ownerToRareArray[_to].length - 1;
     
    Transfer(_from != address(0) ? _from : this, _to, _tokenId);
  }

   
   
  function getRareInfo(uint256 _tokenId) external view returns (
      uint256 sellingPrice,
      address owner,
      uint256 nextPrice,
      uint256 rareClass,
      uint256 cardId,
      uint256 rareValue
  ) {
    RareCard storage rarecard = rareArray[_tokenId];
    sellingPrice = IndexToPrice[_tokenId];
    owner = IndexToOwner[_tokenId];
    nextPrice = SafeMath.div(SafeMath.mul(sellingPrice,125),100);
    rareClass = rarecard.rareClass;
    cardId = rarecard.cardId;
    rareValue = rarecard.rareValue;
  }

   
   
  function getRarePLATInfo(uint256 _tokenId) external view returns (
    uint256 sellingPrice,
    address owner,
    uint256 nextPrice,
    uint256 rareClass,
    uint256 cardId,
    uint256 rareValue
  ) {
    RareCard storage rarecard = rareArray[_tokenId];
    sellingPrice = SafeMath.mul(IndexToPrice[_tokenId],PLATPrice);
    owner = IndexToOwner[_tokenId];
    nextPrice = SafeMath.div(SafeMath.mul(sellingPrice,125),100);
    rareClass = rarecard.rareClass;
    cardId = rarecard.cardId;
    rareValue = rarecard.rareValue;
  }


  function getRareItemsOwner(uint256 rareId) external view returns (address) {
    return IndexToOwner[rareId];
  }

  function getRareItemsPrice(uint256 rareId) external view returns (uint256) {
    return IndexToPrice[rareId];
  }

  function getRareItemsPLATPrice(uint256 rareId) external view returns (uint256) {
    return SafeMath.mul(IndexToPrice[rareId],PLATPrice);
  }

  function setRarePrice(uint256 _rareId, uint256 _price) external onlyAccess {
    IndexToPrice[_rareId] = _price;
  }

  function rareStartPrice() external pure returns (uint256) {
    return startPrice;
  }

   
   
  function balanceOf(address _owner) external view returns (uint256) {
    require(_owner != address(0));
    return ownerToRareArray[_owner].length;
  }

   
  function ownerOf(uint256 _tokenId) external view returns (address _owner) {
    return IndexToOwner[_tokenId];
  }

   
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) external payable {
    _safeTransferFrom(_from, _to, _tokenId, data);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external payable {
    _safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function _safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) 
    internal
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
  {
    address owner = IndexToOwner[_tokenId];
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
            
    _transfer(_from, _to, _tokenId);

     
     
    bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(_from, _tokenId, data);
     
    require(retval == 0xf0b9e5ba);
  }

   
   
   

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) 
    external 
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
    payable 
  {
    address owner = IndexToOwner[_tokenId];
     
     
    require(owner != address(0) && owner == _from);
    require(_to != address(0));
    _transfer(_from, _to, _tokenId);
  }

   
   
   
   
   
   
   
   

   
   
   
  function approve(address _approved, uint256 _tokenId) 
    external 
    isValidToken(_tokenId)
    onlyOwnerOf(_tokenId) 
    payable 
  {
    address owner = IndexToOwner[_tokenId];
    require(operatorToApprovals[owner][msg.sender]);
    IndexToApproved[_tokenId] = _approved;
    Approval(owner, _approved, _tokenId);
  }


   
   
   
  function setApprovalForAll(address _operator, bool _approved) 
    external 
  {
    operatorToApprovals[msg.sender][_operator] = _approved;
    ApprovalForAll(msg.sender, _operator, _approved);
  }

   
   
   
  function getApproved(uint256 _tokenId) external view isValidToken(_tokenId) returns (address) {
    return IndexToApproved[_tokenId];
  }

   
   
   
   
  function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
    return operatorToApprovals[_owner][_operator];
  }

   
   
   
  function totalSupply() external view returns (uint256) {
    return rareArray.length -1;
  }

   
   
   
   
   
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index <= (rareArray.length - 1));
    return _index;
  }

   
   
   
   
   
   
   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
    require(_index < ownerToRareArray[_owner].length);
    if (_owner != address(0)) {
      uint256 tokenId = ownerToRareArray[_owner][_index];
      return tokenId;
    }
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) external view returns(uint256[]) {
    uint256 tokenCount = ownerToRareArray[_owner].length;
    if (tokenCount == 0) {
       
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalRare = rareArray.length - 1;
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalRare; tokenId++) {
        if (IndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
  function transferToken(address _from, address _to, uint256 _tokenId) external onlyAccess {
    _transfer(_from,  _to, _tokenId);
  }

   
  function transferTokenByContract(uint256 _tokenId,address _to) external onlyAccess {
    _transfer(thisAddress,  _to, _tokenId);
  }

   
  function getRareItemInfo() external view returns (address[], uint256[], uint256[]) {
    address[] memory itemOwners = new address[](rareArray.length-1);
    uint256[] memory itemPrices = new uint256[](rareArray.length-1);
    uint256[] memory itemPlatPrices = new uint256[](rareArray.length-1);
        
    uint256 startId = 1;
    uint256 endId = rareArray.length-1;
        
    uint256 i;
    while (startId <= endId) {
      itemOwners[i] = IndexToOwner[startId];
      itemPrices[i] = IndexToPrice[startId];
      itemPlatPrices[i] = SafeMath.mul(IndexToPrice[startId],PLATPrice);
      i++;
      startId++;
    }   
    return (itemOwners, itemPrices, itemPlatPrices);
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