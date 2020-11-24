 

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

 

 
contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}

 

contract Marketplace is Ownable {
    ERC721 public nft;

    mapping (uint256 => Listing) public listings;

    uint256 public minListingSeconds;
    uint256 public maxListingSeconds;

    struct Listing {
        address seller;
        uint256 startingPrice;
        uint256 minimumPrice;
        uint256 createdAt;
        uint256 durationSeconds;
    }

    event TokenListed(uint256 indexed _tokenId, uint256 _startingPrice, uint256 _minimumPrice, uint256 _durationSeconds, address _seller);
    event TokenUnlisted(uint256 indexed _tokenId, address _unlister);
    event TokenSold(uint256 indexed _tokenId, uint256 _price, uint256 _paidAmount, address indexed _seller, address _buyer);

    modifier nftOnly() {
        require(msg.sender == address(nft));
        _;
    }

    function Marketplace(ERC721 _nft, uint256 _minListingSeconds, uint256 _maxListingSeconds) public {
        nft = _nft;
        minListingSeconds = _minListingSeconds;
        maxListingSeconds = _maxListingSeconds;
    }

    function list(address _tokenSeller, uint256 _tokenId, uint256 _startingPrice, uint256 _minimumPrice, uint256 _durationSeconds) public nftOnly {
        require(_durationSeconds >= minListingSeconds && _durationSeconds <= maxListingSeconds);
        require(_startingPrice >= _minimumPrice);
        require(! listingActive(_tokenId));
        listings[_tokenId] = Listing(_tokenSeller, _startingPrice, _minimumPrice, now, _durationSeconds);
        nft.takeOwnership(_tokenId);
        TokenListed(_tokenId, _startingPrice, _minimumPrice, _durationSeconds, _tokenSeller);
    }

    function unlist(address _caller, uint256 _tokenId) public nftOnly {
        address _seller = listings[_tokenId].seller;
         
        require(_seller == _caller || address(owner) == _caller);
        nft.transfer(_seller, _tokenId);
        delete listings[_tokenId];
        TokenUnlisted(_tokenId, _caller);
    }

    function purchase(address _caller, uint256 _tokenId, uint256 _totalPaid) public payable nftOnly {
        Listing memory _listing = listings[_tokenId];
        address _seller = _listing.seller;

        require(_caller != _seller);  
        require(listingActive(_tokenId));

        uint256 _price = currentPrice(_tokenId);
        require(_totalPaid >= _price);

        delete listings[_tokenId];

        nft.transfer(_caller, _tokenId);
        _seller.transfer(msg.value);
        TokenSold(_tokenId, _price, _totalPaid, _seller, _caller);
    }

    function currentPrice(uint256 _tokenId) public view returns (uint256) {
        Listing memory listing = listings[_tokenId];
        require(now >= listing.createdAt);

        uint256 _deadline = listing.createdAt + listing.durationSeconds;
        require(now <= _deadline);

        uint256 _elapsedTime = now - listing.createdAt;
        uint256 _progress = (_elapsedTime * 100) / listing.durationSeconds;
        uint256 _delta = listing.startingPrice - listing.minimumPrice;
        return listing.startingPrice - ((_delta * _progress) / 100);
    }

    function listingActive(uint256 _tokenId) internal view returns (bool) {
        Listing memory listing = listings[_tokenId];
        return listing.createdAt + listing.durationSeconds >= now && now >= listing.createdAt;
    }
}

 

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
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

 

contract PineappleArcadeTrophy is ERC721Token, Pausable {
     
    string public constant name = "PineappleArcadeTrophy";
    string public constant symbol = "DEGEN";

    Marketplace public marketplace;
    uint256 public maxTrophies;

     
    mapping (uint256 => bytes32) public trophies;

    function PineappleArcadeTrophy(uint256 _maxTrophies) public {
        maxTrophies = _maxTrophies;
        pause();
    }

    function setMarketplace(Marketplace _marketplace) external onlyOwner {
        marketplace = _marketplace;
    }

    function grantTrophy(address _initialOwner, bytes32 _trophyName) external onlyOwner {
        require(totalSupply() < maxTrophies);
        require(_trophyName != 0x0);
        trophies[nextId()] = _trophyName;
        _mint(_initialOwner, nextId());
    }

    function listTrophy(uint256 _trophyId, uint256 _startingPriceWei, uint256 _minimumPriceWei, uint256 _durationSeconds) external whenNotPaused {
        address _trophySeller = ownerOf(_trophyId);
        require(_trophySeller == msg.sender);
        approve(marketplace, _trophyId);
        marketplace.list(_trophySeller, _trophyId, _startingPriceWei, _minimumPriceWei, _durationSeconds);
    }

    function unlistTrophy(uint256 _trophyId) external {
        marketplace.unlist(msg.sender, _trophyId);
    }

    function currentPrice(uint256 _trophyId) public view returns(uint256) {
        return marketplace.currentPrice(_trophyId);
    }

    function purchaseTrophy(uint256 _trophyId) external payable whenNotPaused {
         
        uint256 _blockadeFee = (msg.value * 375) / 10000;  
        uint256 _sellerTake = msg.value - _blockadeFee;
        marketplace.purchase.value(_sellerTake)(msg.sender, _trophyId, msg.value);
    }

     
     
    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }

    function nextId() internal view returns (uint256) {
        return totalSupply() + 1;
    }
}