 

pragma solidity ^0.4.13;

interface ERC721Enumerable   {
     
     
     
    function totalSupply() public view returns (uint256);

     
     
     
     
     
    function tokenByIndex(uint256 _index) external view returns (uint256);

     
     
     
     
     
     
     
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256 _tokenId);
}

interface ERC721Metadata   {
     
    function name() external pure returns (string _name);

     
    function symbol() external pure returns (string _symbol);

     
     
     
     
    function tokenURI(uint256 _tokenId) external view returns (string);
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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));
    OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }

}

interface ERC721TokenReceiver {
     
     
     
     
     
     
     
     
     
     
     
	function onERC721Received(address _from, uint256 _tokenId, bytes _data) external returns(bytes4);
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

contract LicenseAccessControl {
   
  event ContractUpgrade(address newContract);
  event Paused();
  event Unpaused();

   
  address public ceoAddress;

   
  address public cfoAddress;

   
  address public cooAddress;

   
  address public withdrawalAddress;

  bool public paused = false;

   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCFO() {
    require(msg.sender == cfoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress ||
      msg.sender == cfoAddress
    );
    _;
  }

   
  modifier onlyCEOOrCFO() {
    require(
      msg.sender == cfoAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

   
  modifier onlyCEOOrCOO() {
    require(
      msg.sender == cooAddress ||
      msg.sender == ceoAddress
    );
    _;
  }

   
  function setCEO(address _newCEO) external onlyCEO {
    require(_newCEO != address(0));
    ceoAddress = _newCEO;
  }

   
  function setCFO(address _newCFO) external onlyCEO {
    require(_newCFO != address(0));
    cfoAddress = _newCFO;
  }

   
  function setCOO(address _newCOO) external onlyCEO {
    require(_newCOO != address(0));
    cooAddress = _newCOO;
  }

   
  function setWithdrawalAddress(address _newWithdrawalAddress) external onlyCEO {
    require(_newWithdrawalAddress != address(0));
    withdrawalAddress = _newWithdrawalAddress;
  }

   
  function withdrawBalance() external onlyCEOOrCFO {
    require(withdrawalAddress != address(0));
    withdrawalAddress.transfer(this.balance);
  }

   

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() public onlyCLevel whenNotPaused {
    paused = true;
    Paused();
  }

   
  function unpause() public onlyCEO whenPaused {
    paused = false;
    Unpaused();
  }
}

contract LicenseBase is LicenseAccessControl {
   
  event LicenseIssued(
    address indexed owner,
    address indexed purchaser,
    uint256 licenseId,
    uint256 productId,
    uint256 attributes,
    uint256 issuedTime,
    uint256 expirationTime,
    address affiliate
  );

  event LicenseRenewal(
    address indexed owner,
    address indexed purchaser,
    uint256 licenseId,
    uint256 productId,
    uint256 expirationTime
  );

  struct License {
    uint256 productId;
    uint256 attributes;
    uint256 issuedTime;
    uint256 expirationTime;
    address affiliate;
  }

   
  License[] licenses;

   
  function _isValidLicense(uint256 _licenseId) internal view returns (bool) {
    return licenseProductId(_licenseId) != 0;
  }

   

   
  function licenseProductId(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].productId;
  }

   
  function licenseAttributes(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].attributes;
  }

   
  function licenseIssuedTime(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].issuedTime;
  }

   
  function licenseExpirationTime(uint256 _licenseId) public view returns (uint256) {
    return licenses[_licenseId].expirationTime;
  }

   
  function licenseAffiliate(uint256 _licenseId) public view returns (address) {
    return licenses[_licenseId].affiliate;
  }

   
  function licenseInfo(uint256 _licenseId)
    public view returns (uint256, uint256, uint256, uint256, address)
  {
    return (
      licenseProductId(_licenseId),
      licenseAttributes(_licenseId),
      licenseIssuedTime(_licenseId),
      licenseExpirationTime(_licenseId),
      licenseAffiliate(_licenseId)
    );
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

contract AffiliateProgram is Pausable {
  using SafeMath for uint256;

  event AffiliateCredit(
     
    address affiliate,
     
    uint256 productId,
     
    uint256 amount
  );

  event Withdraw(address affiliate, address to, uint256 amount);
  event Whitelisted(address affiliate, uint256 amount);
  event RateChanged(uint256 rate, uint256 amount);

   
  mapping (address => uint256) public balances;

   
  mapping (address => uint256) public lastDepositTimes;

   
  uint256 public lastDepositTime;

   
   
   
   
  uint256 private constant hardCodedMaximumRate = 5000;

   
   
  uint256 private constant commissionExpiryTime = 30 days;

   
  uint256 public baselineRate = 0;

   
  mapping (address => uint256) public whitelistRates;

   
   
  uint256 public maximumRate = 5000;

   
  address public storeAddress;

   
   
   
  bool public retired = false;


   
  modifier onlyStoreOrOwner() {
    require(
      msg.sender == storeAddress ||
      msg.sender == owner);
    _;
  }

   
  function AffiliateProgram(address _storeAddress) public {
    require(_storeAddress != address(0));
    storeAddress = _storeAddress;
    paused = true;
  }

   
  function isAffiliateProgram() public pure returns (bool) {
    return true;
  }

   
  function rateFor(
    address _affiliate,
    uint256  ,
    uint256  ,
    uint256  )
    public
    view
    returns (uint256)
  {
    uint256 whitelistedRate = whitelistRates[_affiliate];
    if(whitelistedRate > 0) {
       
      if(whitelistedRate == 1) {
        return 0;
      } else {
        return Math.min256(whitelistedRate, maximumRate);
      }
    } else {
      return Math.min256(baselineRate, maximumRate);
    }
  }

   
  function cutFor(
    address _affiliate,
    uint256 _productId,
    uint256 _purchaseId,
    uint256 _purchaseAmount)
    public
    view
    returns (uint256)
  {
    uint256 rate = rateFor(
      _affiliate,
      _productId,
      _purchaseId,
      _purchaseAmount);
    require(rate <= hardCodedMaximumRate);
    return (_purchaseAmount.mul(rate)).div(10000);
  }

   
  function credit(
    address _affiliate,
    uint256 _purchaseId)
    public
    onlyStoreOrOwner
    whenNotPaused
    payable
  {
    require(msg.value > 0);
    require(_affiliate != address(0));
    balances[_affiliate] += msg.value;
    lastDepositTimes[_affiliate] = now;  
    lastDepositTime = now;  
    AffiliateCredit(_affiliate, _purchaseId, msg.value);
  }

   
  function _performWithdraw(address _from, address _to) private {
    require(balances[_from] > 0);
    uint256 balanceValue = balances[_from];
    balances[_from] = 0;
    _to.transfer(balanceValue);
    Withdraw(_from, _to, balanceValue);
  }

   
  function withdraw() public whenNotPaused {
    _performWithdraw(msg.sender, msg.sender);
  }

   
  function withdrawFrom(address _affiliate, address _to) onlyOwner public {
     
    require(now > lastDepositTimes[_affiliate].add(commissionExpiryTime));
    _performWithdraw(_affiliate, _to);
  }

   
  function retire(address _to) onlyOwner whenPaused public {
     
    require(now > lastDepositTime.add(commissionExpiryTime));
    _to.transfer(this.balance);
    retired = true;
  }

   
  function whitelist(address _affiliate, uint256 _rate) onlyOwner public {
    require(_rate <= hardCodedMaximumRate);
    whitelistRates[_affiliate] = _rate;
    Whitelisted(_affiliate, _rate);
  }

   
  function setBaselineRate(uint256 _newRate) onlyOwner public {
    require(_newRate <= hardCodedMaximumRate);
    baselineRate = _newRate;
    RateChanged(0, _newRate);
  }

   
  function setMaximumRate(uint256 _newRate) onlyOwner public {
    require(_newRate <= hardCodedMaximumRate);
    maximumRate = _newRate;
    RateChanged(1, _newRate);
  }

   
  function unpause() onlyOwner whenPaused public {
    require(!retired);
    paused = false;
    Unpause();
  }

}

contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);
  event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes data) public;
  function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
  function transfer(address _to, uint256 _tokenId) external;
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) external;
  function setApprovalForAll(address _to, bool _approved) external;
  function getApproved(uint256 _tokenId) public view returns (address);
  function isApprovedForAll(address _owner, address _operator) public view returns (bool);
}

contract LicenseInventory is LicenseBase {
  using SafeMath for uint256;

  event ProductCreated(
    uint256 id,
    uint256 price,
    uint256 available,
    uint256 supply,
    uint256 interval,
    bool renewable
  );
  event ProductInventoryAdjusted(uint256 productId, uint256 available);
  event ProductPriceChanged(uint256 productId, uint256 price);
  event ProductRenewableChanged(uint256 productId, bool renewable);


   
  struct Product {
    uint256 id;
    uint256 price;
    uint256 available;
    uint256 supply;
    uint256 sold;
    uint256 interval;
    bool renewable;
  }

   
  uint256[] public allProductIds;

   
  mapping (uint256 => Product) public products;

   

   
  function _productExists(uint256 _productId) internal view returns (bool) {
    return products[_productId].id != 0;
  }

  function _productDoesNotExist(uint256 _productId) internal view returns (bool) {
    return products[_productId].id == 0;
  }

  function _createProduct(
    uint256 _productId,
    uint256 _initialPrice,
    uint256 _initialInventoryQuantity,
    uint256 _supply,
    uint256 _interval)
    internal
  {
    require(_productDoesNotExist(_productId));
    require(_initialInventoryQuantity <= _supply);

    Product memory _product = Product({
      id: _productId,
      price: _initialPrice,
      available: _initialInventoryQuantity,
      supply: _supply,
      sold: 0,
      interval: _interval,
      renewable: _interval == 0 ? false : true
    });

    products[_productId] = _product;
    allProductIds.push(_productId);

    ProductCreated(
      _product.id,
      _product.price,
      _product.available,
      _product.supply,
      _product.interval,
      _product.renewable
      );
  }

  function _incrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    internal
  {
    require(_productExists(_productId));
    uint256 newInventoryLevel = products[_productId].available.add(_inventoryAdjustment);

     
    if(products[_productId].supply > 0) {
       
      require(products[_productId].sold.add(newInventoryLevel) <= products[_productId].supply);
    }

    products[_productId].available = newInventoryLevel;
  }

  function _decrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    internal
  {
    require(_productExists(_productId));
    uint256 newInventoryLevel = products[_productId].available.sub(_inventoryAdjustment);
     
     
    products[_productId].available = newInventoryLevel;
  }

  function _clearInventory(uint256 _productId) internal
  {
    require(_productExists(_productId));
    products[_productId].available = 0;
  }

  function _setPrice(uint256 _productId, uint256 _price) internal
  {
    require(_productExists(_productId));
    products[_productId].price = _price;
  }

  function _setRenewable(uint256 _productId, bool _isRenewable) internal
  {
    require(_productExists(_productId));
    products[_productId].renewable = _isRenewable;
  }

  function _purchaseOneUnitInStock(uint256 _productId) internal {
    require(_productExists(_productId));
    require(availableInventoryOf(_productId) > 0);

     
    _decrementInventory(_productId, 1);

     
    products[_productId].sold = products[_productId].sold.add(1);
  }

  function _requireRenewableProduct(uint256 _productId) internal view {
     
    require(_productId != 0);
     
    require(isSubscriptionProduct(_productId));
     
    require(renewableOf(_productId));
  }

   

   

   
  function createProduct(
    uint256 _productId,
    uint256 _initialPrice,
    uint256 _initialInventoryQuantity,
    uint256 _supply,
    uint256 _interval)
    external
    onlyCEOOrCOO
  {
    _createProduct(
      _productId,
      _initialPrice,
      _initialInventoryQuantity,
      _supply,
      _interval);
  }

   
  function incrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    external
    onlyCLevel
  {
    _incrementInventory(_productId, _inventoryAdjustment);
    ProductInventoryAdjusted(_productId, availableInventoryOf(_productId));
  }

   
  function decrementInventory(
    uint256 _productId,
    uint256 _inventoryAdjustment)
    external
    onlyCLevel
  {
    _decrementInventory(_productId, _inventoryAdjustment);
    ProductInventoryAdjusted(_productId, availableInventoryOf(_productId));
  }

   
  function clearInventory(uint256 _productId)
    external
    onlyCLevel
  {
    _clearInventory(_productId);
    ProductInventoryAdjusted(_productId, availableInventoryOf(_productId));
  }

   
  function setPrice(uint256 _productId, uint256 _price)
    external
    onlyCLevel
  {
    _setPrice(_productId, _price);
    ProductPriceChanged(_productId, _price);
  }

   
  function setRenewable(uint256 _productId, bool _newRenewable)
    external
    onlyCLevel
  {
    _setRenewable(_productId, _newRenewable);
    ProductRenewableChanged(_productId, _newRenewable);
  }

   

   
  function priceOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].price;
  }

   
  function availableInventoryOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].available;
  }

   
  function totalSupplyOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].supply;
  }

   
  function totalSold(uint256 _productId) public view returns (uint256) {
    return products[_productId].sold;
  }

   
  function intervalOf(uint256 _productId) public view returns (uint256) {
    return products[_productId].interval;
  }

   
  function renewableOf(uint256 _productId) public view returns (bool) {
    return products[_productId].renewable;
  }


   
  function productInfo(uint256 _productId)
    public
    view
    returns (uint256, uint256, uint256, uint256, bool)
  {
    return (
      priceOf(_productId),
      availableInventoryOf(_productId),
      totalSupplyOf(_productId),
      intervalOf(_productId),
      renewableOf(_productId));
  }

   
  function getAllProductIds() public view returns (uint256[]) {
    return allProductIds;
  }

   
  function costForProductCycles(uint256 _productId, uint256 _numCycles)
    public
    view
    returns (uint256)
  {
    return priceOf(_productId).mul(_numCycles);
  }

   
  function isSubscriptionProduct(uint256 _productId) public view returns (bool) {
    return intervalOf(_productId) > 0;
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

interface ERC165 {
     
     
     
     
     
     
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}

contract LicenseOwnership is LicenseInventory, ERC721, ERC165, ERC721Metadata, ERC721Enumerable {
  using SafeMath for uint256;

   
  uint256 private totalTokens;

   
  mapping (uint256 => address) private tokenOwner;

   
  mapping (uint256 => address) private tokenApprovals;

   
  mapping (address => mapping (address => bool)) private operatorApprovals;

   
  mapping (address => uint256[]) private ownedTokens;

   
  mapping(uint256 => uint256) private ownedTokensIndex;

   
   
  string public constant NAME = "Dottabot";
  string public constant SYMBOL = "DOTTA";
  string public tokenMetadataBaseURI = "https://api.dottabot.com/";

   
  function name() external pure returns (string) {
    return NAME;
  }

   
  function symbol() external pure returns (string) {
    return SYMBOL;
  }

  function implementsERC721() external pure returns (bool) {
    return true;
  }

  function tokenURI(uint256 _tokenId)
    external
    view
    returns (string infoUrl)
  {
    return Strings.strConcat(
      tokenMetadataBaseURI,
      Strings.uint2str(_tokenId));
  }

  function supportsInterface(
    bytes4 interfaceID)  
    external view returns (bool)
  {
    return
      interfaceID == this.supportsInterface.selector ||  
      interfaceID == 0x5b5e139f ||  
      interfaceID == 0x6466353c ||  
      interfaceID == 0x780e9d63;  
  }

  function setTokenMetadataBaseURI(string _newBaseURI) external onlyCEOOrCOO {
    tokenMetadataBaseURI = _newBaseURI;
  }

   
  modifier onlyOwnerOf(uint256 _tokenId) {
    require(ownerOf(_tokenId) == msg.sender);
    _;
  }

   
  function totalSupply() public view returns (uint256) {
    return totalTokens;
  }

   
  function tokenByIndex(uint256 _index) external view returns (uint256) {
    require(_index < totalSupply());
    return _index;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    require(_owner != address(0));
    return ownedTokens[_owner].length;
  }

   
  function tokensOf(address _owner) public view returns (uint256[]) {
    return ownedTokens[_owner];
  }

   
  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    external
    view
    returns (uint256 _tokenId)
  {
    require(_index < balanceOf(_owner));
    return ownedTokens[_owner][_index];
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address) {
    address owner = tokenOwner[_tokenId];
    require(owner != address(0));
    return owner;
  }

   
  function getApproved(uint256 _tokenId) public view returns (address) {
    return tokenApprovals[_tokenId];
  }

   
  function isSenderApprovedFor(uint256 _tokenId) internal view returns (bool) {
    return
      ownerOf(_tokenId) == msg.sender ||
      isSpecificallyApprovedFor(msg.sender, _tokenId) ||
      isApprovedForAll(ownerOf(_tokenId), msg.sender);
  }

   
  function isSpecificallyApprovedFor(address _asker, uint256 _tokenId) internal view returns (bool) {
    return getApproved(_tokenId) == _asker;
  }

   
  function isApprovedForAll(address _owner, address _operator) public view returns (bool)
  {
    return operatorApprovals[_owner][_operator];
  }

   
  function transfer(address _to, uint256 _tokenId)
    external
    whenNotPaused
    onlyOwnerOf(_tokenId)
  {
    _clearApprovalAndTransfer(msg.sender, _to, _tokenId);
  }

   
  function approve(address _to, uint256 _tokenId)
    external
    whenNotPaused
    onlyOwnerOf(_tokenId)
  {
    address owner = ownerOf(_tokenId);
    require(_to != owner);
    if (getApproved(_tokenId) != 0 || _to != 0) {
      tokenApprovals[_tokenId] = _to;
      Approval(owner, _to, _tokenId);
    }
  }

   
  function setApprovalForAll(address _to, bool _approved)
    external
    whenNotPaused
  {
    if(_approved) {
      approveAll(_to);
    } else {
      disapproveAll(_to);
    }
  }

   
  function approveAll(address _to)
    public
    whenNotPaused
  {
    require(_to != msg.sender);
    require(_to != address(0));
    operatorApprovals[msg.sender][_to] = true;
    ApprovalForAll(msg.sender, _to, true);
  }

   
  function disapproveAll(address _to)
    public
    whenNotPaused
  {
    require(_to != msg.sender);
    delete operatorApprovals[msg.sender][_to];
    ApprovalForAll(msg.sender, _to, false);
  }

   
  function takeOwnership(uint256 _tokenId)
   external
   whenNotPaused
  {
    require(isSenderApprovedFor(_tokenId));
    _clearApprovalAndTransfer(ownerOf(_tokenId), msg.sender, _tokenId);
  }

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    public
    whenNotPaused
  {
    require(isSenderApprovedFor(_tokenId));
    require(ownerOf(_tokenId) == _from);
    _clearApprovalAndTransfer(ownerOf(_tokenId), _to, _tokenId);
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes _data
  )
    public
    whenNotPaused
  {
    require(_to != address(0));
    require(_isValidLicense(_tokenId));
    transferFrom(_from, _to, _tokenId);
    if (_isContract(_to)) {
      bytes4 tokenReceiverResponse = ERC721TokenReceiver(_to).onERC721Received.gas(50000)(
        _from, _tokenId, _data
      );
      require(tokenReceiverResponse == bytes4(keccak256("onERC721Received(address,uint256,bytes)")));
    }
  }

   
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external
    whenNotPaused
  {
    safeTransferFrom(_from, _to, _tokenId, "");
  }

   
  function _mint(address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    _addToken(_to, _tokenId);
    Transfer(0x0, _to, _tokenId);
  }

   
  function _clearApprovalAndTransfer(address _from, address _to, uint256 _tokenId) internal {
    require(_to != address(0));
    require(_to != ownerOf(_tokenId));
    require(ownerOf(_tokenId) == _from);
    require(_isValidLicense(_tokenId));

    _clearApproval(_from, _tokenId);
    _removeToken(_from, _tokenId);
    _addToken(_to, _tokenId);
    Transfer(_from, _to, _tokenId);
  }

   
  function _clearApproval(address _owner, uint256 _tokenId) private {
    require(ownerOf(_tokenId) == _owner);
    tokenApprovals[_tokenId] = 0;
    Approval(_owner, 0, _tokenId);
  }

   
  function _addToken(address _to, uint256 _tokenId) private {
    require(tokenOwner[_tokenId] == address(0));
    tokenOwner[_tokenId] = _to;
    uint256 length = balanceOf(_to);
    ownedTokens[_to].push(_tokenId);
    ownedTokensIndex[_tokenId] = length;
    totalTokens = totalTokens.add(1);
  }

   
  function _removeToken(address _from, uint256 _tokenId) private {
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

  function _isContract(address addr) internal view returns (bool) {
    uint size;
    assembly { size := extcodesize(addr) }
    return size > 0;
  }
}

contract LicenseSale is LicenseOwnership {
  AffiliateProgram public affiliateProgram;

   
  uint256 public renewalsCreditAffiliatesFor = 1 years;

   
  function _performPurchase(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    uint256 _attributes,
    address _affiliate)
    internal returns (uint)
  {
    _purchaseOneUnitInStock(_productId);
    return _createLicense(
      _productId,
      _numCycles,
      _assignee,
      _attributes,
      _affiliate
      );
  }

  function _createLicense(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    uint256 _attributes,
    address _affiliate)
    internal
    returns (uint)
  {
     
    if(isSubscriptionProduct(_productId)) {
      require(_numCycles != 0);
    }

     
    uint256 expirationTime = isSubscriptionProduct(_productId) ?
      now.add(intervalOf(_productId).mul(_numCycles)) :  
      0;

    License memory _license = License({
      productId: _productId,
      attributes: _attributes,
      issuedTime: now,  
      expirationTime: expirationTime,
      affiliate: _affiliate
    });

    uint256 newLicenseId = licenses.push(_license) - 1;  
    LicenseIssued(
      _assignee,
      msg.sender,
      newLicenseId,
      _license.productId,
      _license.attributes,
      _license.issuedTime,
      _license.expirationTime,
      _license.affiliate);
    _mint(_assignee, newLicenseId);
    return newLicenseId;
  }

  function _handleAffiliate(
    address _affiliate,
    uint256 _productId,
    uint256 _licenseId,
    uint256 _purchaseAmount)
    internal
  {
    uint256 affiliateCut = affiliateProgram.cutFor(
      _affiliate,
      _productId,
      _licenseId,
      _purchaseAmount);
    if(affiliateCut > 0) {
      require(affiliateCut < _purchaseAmount);
      affiliateProgram.credit.value(affiliateCut)(_affiliate, _licenseId);
    }
  }

  function _performRenewal(uint256 _tokenId, uint256 _numCycles) internal {
     
     
     
    uint256 productId = licenseProductId(_tokenId);

     
     
    uint256 renewalBaseTime = Math.max256(now, licenses[_tokenId].expirationTime);

     
    uint256 newExpirationTime = renewalBaseTime.add(intervalOf(productId).mul(_numCycles));

    licenses[_tokenId].expirationTime = newExpirationTime;

    LicenseRenewal(
      ownerOf(_tokenId),
      msg.sender,
      _tokenId,
      productId,
      newExpirationTime
    );
  }

  function _affiliateProgramIsActive() internal view returns (bool) {
    return
      affiliateProgram != address(0) &&
      affiliateProgram.storeAddress() == address(this) &&
      !affiliateProgram.paused();
  }

   
  function setAffiliateProgramAddress(address _address) external onlyCEO {
    AffiliateProgram candidateContract = AffiliateProgram(_address);
    require(candidateContract.isAffiliateProgram());
    affiliateProgram = candidateContract;
  }

  function setRenewalsCreditAffiliatesFor(uint256 _newTime) external onlyCEO {
    renewalsCreditAffiliatesFor = _newTime;
  }

  function createPromotionalPurchase(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    uint256 _attributes
    )
    external
    onlyCEOOrCOO
    whenNotPaused
    returns (uint256)
  {
    return _performPurchase(
      _productId,
      _numCycles,
      _assignee,
      _attributes,
      address(0));
  }

  function createPromotionalRenewal(
    uint256 _tokenId,
    uint256 _numCycles
    )
    external
    onlyCEOOrCOO
    whenNotPaused
  {
    uint256 productId = licenseProductId(_tokenId);
    _requireRenewableProduct(productId);

    return _performRenewal(_tokenId, _numCycles);
  }

   

   
  function purchase(
    uint256 _productId,
    uint256 _numCycles,
    address _assignee,
    address _affiliate
    )
    external
    payable
    whenNotPaused
    returns (uint256)
  {
    require(_productId != 0);
    require(_numCycles != 0);
    require(_assignee != address(0));
     

     
     
    require(msg.value == costForProductCycles(_productId, _numCycles));

     
     
    if(!isSubscriptionProduct(_productId)) {
      require(_numCycles == 1);
    }

     
     
     
    uint256 attributes = uint256(keccak256(block.blockhash(block.number-1)))^_productId^(uint256(_assignee));
    uint256 licenseId = _performPurchase(
      _productId,
      _numCycles,
      _assignee,
      attributes,
      _affiliate);

    if(
      priceOf(_productId) > 0 &&
      _affiliate != address(0) &&
      _affiliateProgramIsActive()
    ) {
      _handleAffiliate(
        _affiliate,
        _productId,
        licenseId,
        msg.value);
    }

    return licenseId;
  }

   
  function renew(
    uint256 _tokenId,
    uint256 _numCycles
    )
    external
    payable
    whenNotPaused
  {
    require(_numCycles != 0);
    require(ownerOf(_tokenId) != address(0));

    uint256 productId = licenseProductId(_tokenId);
    _requireRenewableProduct(productId);

     
     
    uint256 renewalCost = costForProductCycles(productId, _numCycles);
    require(msg.value == renewalCost);

    _performRenewal(_tokenId, _numCycles);

    if(
      renewalCost > 0 &&
      licenseAffiliate(_tokenId) != address(0) &&
      _affiliateProgramIsActive() &&
      licenseIssuedTime(_tokenId).add(renewalsCreditAffiliatesFor) > now
    ) {
      _handleAffiliate(
        licenseAffiliate(_tokenId),
        productId,
        _tokenId,
        msg.value);
    }
  }

}

contract LicenseCore is LicenseSale {
  address public newContractAddress;

  function LicenseCore() public {
    paused = true;

    ceoAddress = msg.sender;
    cooAddress = msg.sender;
    cfoAddress = msg.sender;
    withdrawalAddress = msg.sender;
  }

  function setNewAddress(address _v2Address) external onlyCEO whenPaused {
    newContractAddress = _v2Address;
    ContractUpgrade(_v2Address);
  }

  function() external {
    assert(false);
  }

  function unpause() public onlyCEO whenPaused {
    require(newContractAddress == address(0));
    super.unpause();
  }
}

library Strings {
   
  function strConcat(string _a, string _b, string _c, string _d, string _e) internal pure returns (string) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0;
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint i) internal pure returns (string) {
        if (i == 0) return "0";
        uint j = i;
        uint len;
        while (j != 0){
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }
}