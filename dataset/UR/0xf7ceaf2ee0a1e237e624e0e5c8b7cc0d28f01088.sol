 

pragma solidity ^0.4.18;

 
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





contract MultiOwners {

    event AccessGrant(address indexed owner);
    event AccessRevoke(address indexed owner);
    
    mapping(address => bool) owners;

    function MultiOwners() public {
        owners[msg.sender] = true;
    }

    modifier onlyOwner() { 
        require(owners[msg.sender] == true);
        _; 
    }

    function isOwner() public view returns (bool) {
        return owners[msg.sender] ? true : false;
    }

    function grant(address _newOwner) external onlyOwner {
        owners[_newOwner] = true;
        AccessGrant(_newOwner);
    }

    function revoke(address _oldOwner) external onlyOwner {
        require(msg.sender != _oldOwner);
        owners[_oldOwner] = false;
        AccessRevoke(_oldOwner);
    }
}

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 
contract ERC721Token is ERC721 {
  using SafeMath for uint256;

   
  uint256 internal totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping (uint256 => uint256) private ownedTokensIndex;

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function approvedFor(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function transfer(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId) public onlyOwnerOf(_tokenId) {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (approvedFor(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function takeOwnership(uint256 _tokenId) public {
    require(isApprovedFor(msg.sender, _tokenId));
    clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function _burn(uint256 _tokenId) onlyOwnerOf(_tokenId) internal {
    if (approvedFor(_tokenId) != 0) {
      clearApproval(msg.sender, _tokenId);
    }
    removeToken(msg.sender, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function _burnFor(address _owner, uint256 _tokenId) internal {
    if (isApprovedFor(_owner, _tokenId)) {
      clearApproval(_owner, _tokenId);
    }
    removeToken(_owner, _tokenId);
    Transfer(msg.sender, 0x0, _tokenId);
  }

   
  function isApprovedFor(address _owner, uint256 _tokenId) internal view returns (bool) {
    return approvedFor(_tokenId) == _owner;
  }

   
  function clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);

    clearApproval(_from, _tokenId);
    removeToken(_from, _tokenId);
    addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

   
  function addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function removeToken(address _from, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _from);

    uint256 tokenIndex = ownedTokensIndex[_tokenId];
    uint256 lastTokenIndex = balanceOf(_from).sub(1);
    uint256 lastToken = ownedTokens[_from][lastTokenIndex];

    tokenOwner[_tokenId] = 0;
    ownedTokens[_from][tokenIndex] = lastToken;
    ownedTokens[_from][lastTokenIndex] = 0;
     
     
     

    ownedTokens[_from].length--;
    ownedTokensIndex[_tokenId] = 0;
    ownedTokensIndex[lastToken] = tokenIndex;
    totalTokens = totalTokens.sub(1);
  }
}

contract Base is ERC721Token, MultiOwners {

  event NewCRLToken(address indexed owner, uint256 indexed tokenId, uint256 traits);
  event UpdatedCRLToken(uint256 indexed UUID, uint256 indexed tokenId, uint256 traits);

  uint256 TOKEN_UUID;
  uint256 UPGRADE_UUID;

  function _createToken(address _owner, uint256 _traits) internal {
     
    NewCRLToken(
      _owner,
      TOKEN_UUID,
      _traits
    );

     
    _mint(_owner, TOKEN_UUID);

    TOKEN_UUID++;
  }

  function _updateToken(uint256 _tokenId, uint256 _traits) internal {
     
    UpdatedCRLToken(
      UPGRADE_UUID,
      _tokenId,
      _traits
    );

    UPGRADE_UUID++;
  }

   

   
  function withdrawBalance() onlyOwner external {
    require(this.balance > 0);

    msg.sender.transfer(this.balance);
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
    
    NOSPurchased(UUID, msg.sender, _NOSAmt);
    UUID++;
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
      _burnFor(ownerOf(_tokenIds[i]), _tokenIds[i]);
    }
  }

  function destroyItem(uint256 _tokenId) onlyAuthorized external {
    _burnFor(ownerOf(_tokenId), _tokenId);
  }

  function destroyMultipleItems(uint256[] _tokenIds) onlyAuthorized external {
    for (uint i = 0; i < _tokenIds.length; ++i) {
      _burnFor(ownerOf(_tokenIds[i]), _tokenIds[i]);
    }
  }

  function updateItemTraits(uint256 _tokenId, uint256 _traits) onlyAuthorized external {
    _updateToken(_tokenId, _traits);
  }
}


contract LootboxInterface {
  event LootboxPurchased(address indexed owner, uint16 displayValue);
  
  function buy(address _buyer) external;
}