 

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

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
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

contract Ownable {
  address public owner;

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract HarmToken is ERC721Token, Ownable {
  mapping(uint256 => string) metadataUri;
  mapping(string => uint256) tokenByMetadataUri;
  mapping(string => uint256) prices;

  string public name = "HARM COIN";
  string public symbol = "QQQ";
  uint256 public newTokenPrice = 8500;
  uint256 public priceMultiplier = 1000;

  modifier tokenExists(uint256 _tokenId) {
    require(_tokenId > 0);
    require(_tokenId < totalSupply() + 1);
    _;
  }

  function createEmptyToken() private returns (uint256){
    uint256 tokenId = totalSupply() + 1;
    require(tokenId <= 64);
    _mint(owner, tokenId);
    return tokenId;
  }

  function tokenMetadata(uint256 _tokenId) external view tokenExists(_tokenId)
  returns (string infoUrl) {
    return metadataUri[_tokenId];
  }

  function lookupToken(string _metadataUri) public view returns (uint256) {
    return tokenByMetadataUri[_metadataUri];
  }

  function stringEmpty(string s) pure private returns (bool){
    bytes memory testEmptyString = bytes(s);
    return testEmptyString.length == 0;
  }

  function setTokenMetadata(uint256 _tokenId, string _metadataUri) private tokenExists(_tokenId) {
    require(stringEmpty(metadataUri[_tokenId]));
    metadataUri[_tokenId] = _metadataUri;
    tokenByMetadataUri[_metadataUri] = _tokenId;
  }

  function makeWeiPrice(uint256 _price) public view returns (uint256) {
    return _price * priceMultiplier * 1000 * 1000 * 1000 * 1000;
  }

  function setPriceByMetadataUri(string _metadataUri, uint256 _price) external onlyOwner {
    prices[_metadataUri] = _price;
  }

  function getPriceByMetadataUri(string _metadataUri) view external returns (uint256) {
    require(prices[_metadataUri] > 0);
    return prices[_metadataUri];
  }

  function getWeiPriceByMetadataUri(string _metadataUri) view external returns (uint256) {
    require(prices[_metadataUri] > 0);
    return makeWeiPrice(prices[_metadataUri]);
  }

  function newTokenWeiPrice() view public returns (uint256) {
    return makeWeiPrice(newTokenPrice);
  }

  function buyWildcardToken() payable external returns (uint256) {
    require(msg.value >= newTokenWeiPrice());

    uint256 tokenId = createEmptyToken();
    clearApprovalAndTransfer(owner, msg.sender, tokenId);
    return tokenId;
  }

  function tokenizeAndBuyWork(string _metadataUri) payable external returns (uint256) {
    require(prices[_metadataUri] > 0);
    require(msg.value >= makeWeiPrice(prices[_metadataUri]));
    require(workAdopted(_metadataUri) == false);

    uint256 tokenId = createEmptyToken();
    setTokenMetadata(tokenId, _metadataUri);
    clearApprovalAndTransfer(owner, msg.sender, tokenId);
    return tokenId;
  }

  function buyWorkWithToken(string _metadataUri, uint256 _tokenId) external {
    require(ownerOf(_tokenId) == msg.sender);
    require(workAdopted(_metadataUri) == false);

    setTokenMetadata(_tokenId, _metadataUri);
  }

  function setNewTokenPrice(uint256 _price) onlyOwner external {
    newTokenPrice = _price;  
  }

  function () payable public { }

  function payOut(address destination) external onlyOwner {
    destination.transfer(this.balance);
  }

  function workAdopted(string _metadataUri) public view returns (bool) {
    return lookupToken(_metadataUri) != 0;
  }

  function getBalance() external view onlyOwner returns (uint256) {
    return this.balance;
  }

  function setPriceMultiplier(uint256 _priceMultiplier) external onlyOwner {
    require(_priceMultiplier > 0);
    priceMultiplier = _priceMultiplier;
  }
}