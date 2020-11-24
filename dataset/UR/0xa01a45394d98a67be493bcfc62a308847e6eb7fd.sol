 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
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
     
     
     
    return a / b;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


contract ExternalInterface {
  function giveItem(address _recipient, uint256 _traits) external;

  function giveMultipleItems(address _recipient, uint256[] _traits) external;

  function giveMultipleItemsToMultipleRecipients(address[] _recipients, uint256[] _traits) external;

  function giveMultipleItemsAndDestroyMultipleItems(address _recipient, uint256[] _traits, uint256[] _tokenIds) external;
  
  function destroyItem(uint256 _tokenId) external;

  function destroyMultipleItems(uint256[] _tokenIds) external;

  function updateItemTraits(uint256 _tokenId, uint256 _traits) external;
}



contract LootboxInterface {
  event LootboxPurchased(address indexed owner, address indexed storeAddress, uint16 displayValue);
  
  function buy(address _buyer) external;
}


 
 
interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}



 
contract ERC721Basic {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function exists(uint256 _tokenId) public view returns (bool _exists);

  function approve(address _to, uint256 _tokenId) public;
  function getApproved(uint256 _tokenId) public view returns (address _operator);

  function setApprovalForAll(address _operator, bool _approved) public;
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);

  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public;
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public;
}


 
contract ERC721Enumerable is ERC721Basic {
  function totalSupply() public view returns (uint256);
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256 _tokenId);
  function tokenByIndex(uint256 _index) public view returns (uint256);
  function tokensOf(address _owner) public view returns (uint256[]);
}

 
contract ERC721 is ERC721Basic, ERC721Enumerable {
}



 
contract ERC721BasicToken is ERC721Basic {
  using SafeMath for uint256;
  using AddressUtils for address;

   
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
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

   
  function approve(address _to, uint256 _tokenId) public {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    require(msg.sender == owner || isApprovedForAll(owner, msg.sender));

    if (getApproved(_tokenId) != address(0) || _to != address(0)) {
      tokenApprovals[_tokenId] = _to;
      emit Approval(owner, _to, _tokenId);
    }
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function setApprovalForAll(address _to, bool _approved) public {
    require(_to != msg.sender);
    operatorApprovals[msg.sender][_to] = _approved;
    emit ApprovalForAll(msg.sender, _to, _approved);
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool) {
    return operatorApprovals[_owner][_operator];
  }

   
  function transferFrom(address _from, address _to, uint256 _tokenId) public canTransfer(_tokenId) {
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
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    canTransfer(_tokenId)
  {
    transferFrom(_from, _to, _tokenId);
    require(checkAndCallSafeTransfer(_from, _to, _tokenId, _data));
  }

   
  function isApprovedOrOwner(address _spender, uint256 _tokenId) internal view returns (bool) {
    address owner = ownerOf(_tokenId);
    return _spender == owner || getApproved(_tokenId) == _spender || isApprovedForAll(owner, _spender);
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
    bytes _data
  )
    internal
    returns (bool)
  {
    if (!_to.isContract()) {
      return true;
    }
    bytes4 retval = ERC721Receiver(_to).onERC721Received(_from, _tokenId, _data);
    return (retval == ERC721_RECEIVED);
  }
}


 
contract ERC721Receiver {
   
  bytes4 constant ERC721_RECEIVED = 0xf0b9e5ba;

   
  function onERC721Received(address _from, uint256 _tokenId, bytes _data) public returns(bytes4);
}



 
contract ERC721Token is ERC721, ERC721BasicToken, ERC165 {
   
  mapping (address => uint256[]) internal ownedTokens;

   
  mapping(uint256 => uint256) internal ownedTokensIndex;

   
  uint256[] internal allTokens;

   
  mapping(uint256 => uint256) internal allTokensIndex;

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index) public view returns (uint256) {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }
  
   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function totalSupply() public view returns (uint256) {
    return allTokens.length;
  }

   
  function tokenByIndex(uint256 _index) public view returns (uint256) {
    require(_index < totalSupply());
    return allTokens[_index];
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

     
    uint256 tokenIndex = allTokensIndex[_tokenId];
    uint256 lastTokenIndex = allTokens.length.sub(1);
    uint256 lastToken = allTokens[lastTokenIndex];

    allTokens[tokenIndex] = lastToken;
    allTokens[lastTokenIndex] = 0;

    allTokens.length--;
    allTokensIndex[_tokenId] = 0;
    allTokensIndex[lastToken] = tokenIndex;
  }

   
  function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
    return _interfaceID == 0x01ffc9a7 ||  
           _interfaceID == 0x80ac58cd ||  
           _interfaceID == 0x780e9d63;  
  }
}




 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}


contract Base is ERC721Token, Ownable {

  event NewCRLToken(address indexed owner, uint256 indexed tokenId, uint256 traits);
  event UpdatedCRLToken(uint256 indexed UUID, uint256 indexed tokenId, uint256 traits);

  uint256 TOKEN_UUID;
  uint256 UPGRADE_UUID;

  function _createToken(address _owner, uint256 _traits) internal {
     
    emit NewCRLToken(
      _owner,
      TOKEN_UUID,
      _traits
    );

     
    _mint(_owner, TOKEN_UUID);

    TOKEN_UUID++;
  }

  function _updateToken(uint256 _tokenId, uint256 _traits) internal {
     
    emit UpdatedCRLToken(
      UPGRADE_UUID,
      _tokenId,
      _traits
    );

    UPGRADE_UUID++;
  }

   

   
  function withdrawBalance() onlyOwner external {
    require(address(this).balance > 0);

    msg.sender.transfer(address(this).balance);
  }
}



contract LootboxStore is Base {
   
  mapping(address => uint256) ethPricedLootboxes;

   
  mapping(uint256 => uint256) NOSPackages;

  uint256 UUID;

  event NOSPurchased(uint256 indexed UUID, address indexed owner, uint256 indexed NOSAmtPurchased);

  function addLootbox(address _lootboxAddress, uint256 _price) external onlyOwner {
    ethPricedLootboxes[_lootboxAddress] = _price;
  }

  function removeLootbox(address _lootboxAddress) external onlyOwner {
    delete ethPricedLootboxes[_lootboxAddress];
  }

  function buyEthLootbox(address _lootboxAddress) payable external {
     
    require(ethPricedLootboxes[_lootboxAddress] != 0);
    require(msg.value >= ethPricedLootboxes[_lootboxAddress]);

    LootboxInterface(_lootboxAddress).buy(msg.sender);
  }

  function addNOSPackage(uint256 _NOSAmt, uint256 _ethPrice) external onlyOwner {
    NOSPackages[_NOSAmt] = _ethPrice;
  }
  
  function removeNOSPackage(uint256 _NOSAmt) external onlyOwner {
    delete NOSPackages[_NOSAmt];
  }

  function buyNOS(uint256 _NOSAmt) payable external {
    require(NOSPackages[_NOSAmt] != 0);
    require(msg.value >= NOSPackages[_NOSAmt]);
    
    emit NOSPurchased(UUID, msg.sender, _NOSAmt);
    UUID++;
  }
}

contract Core is LootboxStore, ExternalInterface {
  mapping(address => uint256) authorizedExternal;

  function addAuthorizedExternal(address _address) external onlyOwner {
    authorizedExternal[_address] = 1;
  }

  function removeAuthorizedExternal(address _address) external onlyOwner {
    delete authorizedExternal[_address];
  }

   
  modifier onlyAuthorized() { 
    require(ethPricedLootboxes[msg.sender] != 0 ||
            authorizedExternal[msg.sender] != 0);
      _; 
  }

  function giveItem(address _recipient, uint256 _traits) onlyAuthorized external {
    _createToken(_recipient, _traits);
  }

  function giveMultipleItems(address _recipient, uint256[] _traits) onlyAuthorized external {
    for (uint i = 0; i < _traits.length; ++i) {
      _createToken(_recipient, _traits[i]);
    }
  }

  function giveMultipleItemsToMultipleRecipients(address[] _recipients, uint256[] _traits) onlyAuthorized external {
    require(_recipients.length == _traits.length);

    for (uint i = 0; i < _traits.length; ++i) {
      _createToken(_recipients[i], _traits[i]);
    }
  }

  function giveMultipleItemsAndDestroyMultipleItems(address _recipient, uint256[] _traits, uint256[] _tokenIds) onlyAuthorized external {
    for (uint i = 0; i < _traits.length; ++i) {
      _createToken(_recipient, _traits[i]);
    }

    for (i = 0; i < _tokenIds.length; ++i) {
      _burn(ownerOf(_tokenIds[i]), _tokenIds[i]);
    }
  }

  function destroyItem(uint256 _tokenId) onlyAuthorized external {
    _burn(ownerOf(_tokenId), _tokenId);
  }

  function destroyMultipleItems(uint256[] _tokenIds) onlyAuthorized external {
    for (uint i = 0; i < _tokenIds.length; ++i) {
      _burn(ownerOf(_tokenIds[i]), _tokenIds[i]);
    }
  }

  function updateItemTraits(uint256 _tokenId, uint256 _traits) onlyAuthorized external {
    _updateToken(_tokenId, _traits);
  }
}