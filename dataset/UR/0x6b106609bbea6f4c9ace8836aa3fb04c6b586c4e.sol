 

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


contract NewWorld {
  using SafeMath for uint256;
   
   
  event Birth(uint256 tokenId, uint256 startPrice);
   
  event TokenSold(uint256 indexed tokenId, uint256 price, address prevOwner, address winner);
   
  event Transfer(address indexed from, address indexed to, uint256 tokenId);
   
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   

  string public constant NAME = "world-youCollect";
  string public constant SYMBOL = "WYC";
  uint256[] private tokens;

   

   
   
  mapping (uint256 => address) public collectibleIndexToOwner;

   
   
   
  mapping (uint256 => address) public collectibleIndexToApproved;

   
  mapping (uint256 => uint256) public collectibleIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  mapping (uint => address) private subTokenCreator;

  uint16 constant MAX_CONTINENT_INDEX = 10;
  uint16 constant MAX_SUBCONTINENT_INDEX = 100;
  uint16 constant MAX_COUNTRY_INDEX = 10000;
  uint64 constant DOUBLE_TOKENS_INDEX = 10000000000000;
  uint128 constant TRIBLE_TOKENS_INDEX = 10000000000000000000000;
  uint128 constant FIFTY_TOKENS_INDEX = 10000000000000000000000000000000;
  uint256 private constant PROMO_CREATION_LIMIT = 50000;
  uint256 public promoCreatedCount;
  uint8 constant WORLD_TOKEN_ID = 0;
  uint256 constant START_PRICE_CITY = 1 finney;
  uint256 constant START_PRICE_COUNTRY = 10 finney;
  uint256 constant START_PRICE_SUBCONTINENT = 100 finney;
  uint256 constant START_PRICE_CONTINENT = 1 ether;
  uint256 constant START_PRICE_WORLD = 10 ether;


   
  function NewWorld() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }
  function getTotalSupply() public view returns (uint) {
    return tokens.length;
  }
  function getInitialPriceOfToken(uint _tokenId) public pure returns (uint) {
    if (_tokenId > MAX_COUNTRY_INDEX)
      return START_PRICE_CITY;
    if (_tokenId > MAX_SUBCONTINENT_INDEX)
      return START_PRICE_COUNTRY;
    if (_tokenId > MAX_CONTINENT_INDEX)
      return START_PRICE_SUBCONTINENT;
    if (_tokenId > 0)
      return START_PRICE_CONTINENT;
    return START_PRICE_WORLD;
  }

  function getNextPrice(uint price, uint _tokenId) public pure returns (uint) {
    if (_tokenId>DOUBLE_TOKENS_INDEX)
      return price.mul(2);
    if (_tokenId>TRIBLE_TOKENS_INDEX)
      return price.mul(3);
    if (_tokenId>FIFTY_TOKENS_INDEX)
      return price.mul(3).div(2);
    if (price < 1.2 ether)
      return price.mul(200).div(92);
    if (price < 5 ether)
      return price.mul(150).div(92);
    return price.mul(120).div(92);
  }

  function buyToken(uint _tokenId) public payable {
    address oldOwner = collectibleIndexToOwner[_tokenId];
    require(oldOwner!=msg.sender);
    uint256 sellingPrice = collectibleIndexToPrice[_tokenId];
    if (sellingPrice==0) {
      sellingPrice = getInitialPriceOfToken(_tokenId);
       
      if (_tokenId>MAX_COUNTRY_INDEX)
        subTokenCreator[_tokenId] = msg.sender;
    }

    require(msg.value >= sellingPrice);
    uint256 purchaseExcess = msg.value.sub(sellingPrice);

    uint256 payment = sellingPrice.mul(92).div(100);
    uint256 feeOnce = sellingPrice.sub(payment).div(8);

    if (_tokenId > 0) {
       
      if (collectibleIndexToOwner[WORLD_TOKEN_ID]!=address(0))
        collectibleIndexToOwner[WORLD_TOKEN_ID].transfer(feeOnce);
      if (_tokenId > MAX_CONTINENT_INDEX) {
         
        if (collectibleIndexToOwner[_tokenId % MAX_CONTINENT_INDEX]!=address(0))
          collectibleIndexToOwner[_tokenId % MAX_CONTINENT_INDEX].transfer(feeOnce);
        if (_tokenId > MAX_SUBCONTINENT_INDEX) {
           
          if (collectibleIndexToOwner[_tokenId % MAX_SUBCONTINENT_INDEX]!=address(0))
            collectibleIndexToOwner[_tokenId % MAX_SUBCONTINENT_INDEX].transfer(feeOnce);
          if (_tokenId > MAX_COUNTRY_INDEX) {
             
            if (collectibleIndexToOwner[_tokenId % MAX_COUNTRY_INDEX]!=address(0))
              collectibleIndexToOwner[_tokenId % MAX_COUNTRY_INDEX].transfer(feeOnce);
             
            subTokenCreator[_tokenId].transfer(feeOnce);
          }
        }
      }
    }
     
    collectibleIndexToOwner[_tokenId] = msg.sender;
    if (oldOwner != address(0)) {
       
      oldOwner.transfer(payment);
       
      delete collectibleIndexToApproved[_tokenId];
    } else {
      Birth(_tokenId, sellingPrice);
      tokens.push(_tokenId);
    }
     
    collectibleIndexToPrice[_tokenId] = getNextPrice(sellingPrice, _tokenId);

    TokenSold(_tokenId, sellingPrice, oldOwner, msg.sender);
    Transfer(oldOwner, msg.sender, _tokenId);
     
    if (purchaseExcess>0)
      msg.sender.transfer(purchaseExcess);
  }



   
   
  modifier onlyCEO() {
    require(msg.sender == ceoAddress);
    _;
  }

   
  modifier onlyCOO() {
    require(msg.sender == cooAddress);
    _;
  }

   
  modifier onlyCLevel() {
    require(
      msg.sender == ceoAddress ||
      msg.sender == cooAddress
    );
    _;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    collectibleIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
  function createPromoCollectible(uint256 tokenId, address _owner, uint256 _price) public onlyCOO {
    require(collectibleIndexToOwner[tokenId]==address(0));
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address collectibleOwner = _owner;
    if (collectibleOwner == address(0)) {
      collectibleOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = getInitialPriceOfToken(tokenId);
    }

    promoCreatedCount++;
    _createCollectible(tokenId, _price);
     
     
    _transfer(address(0), collectibleOwner, tokenId);

  }

  bool isChangePriceLocked = true;
   
  function changePrice(uint256 newPrice, uint256 _tokenId) public {
    require((_owns(msg.sender, _tokenId) && !isChangePriceLocked) || (_owns(address(0), _tokenId) && msg.sender == cooAddress));
    require(newPrice<collectibleIndexToPrice[_tokenId]);
    collectibleIndexToPrice[_tokenId] = newPrice;
  }
  function unlockPriceChange() public onlyCOO {
    isChangePriceLocked = false;
  }

   
   
  function getToken(uint256 _tokenId) public view returns (uint256 tokenId, uint256 sellingPrice, address owner, uint256 nextSellingPrice) {
    tokenId = _tokenId;
    sellingPrice = collectibleIndexToPrice[_tokenId];
    if (sellingPrice == 0)
      sellingPrice = getInitialPriceOfToken(_tokenId);
    owner = collectibleIndexToOwner[_tokenId];
    nextSellingPrice = getNextPrice(sellingPrice, _tokenId);
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
   
   
  function ownerOf(uint256 _tokenId)
    public
    view
    returns (address owner)
  {
    owner = collectibleIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }


  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    price = collectibleIndexToPrice[_tokenId];
    if (price == 0)
      price = getInitialPriceOfToken(_tokenId);
  }

   
   
  function setCEO(address _newCEO) public onlyCEO {
    require(_newCEO != address(0));

    ceoAddress = _newCEO;
  }

   
   
  function setCOO(address _newCOO) public onlyCEO {
    require(_newCOO != address(0));

    cooAddress = _newCOO;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }

   
   
   
  function takeOwnership(uint256 _tokenId) public {
    address newOwner = msg.sender;
    address oldOwner = collectibleIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return collectibleIndexToApproved[_tokenId] == _to;
  }

   
  function _createCollectible(uint256 tokenId, uint256 _price) private {
    collectibleIndexToPrice[tokenId] = _price;
    Birth(tokenId, _price);
    tokens.push(tokenId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == collectibleIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 result) {
      uint256 totalTokens = tokens.length;
      uint256 tokenIndex;
      uint256 tokenId;
      result = 0;
      for (tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
        tokenId = tokens[tokenIndex];
        if (collectibleIndexToOwner[tokenId] == _owner) {
          result = result.add(1);
        }
      }
      return result;
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    collectibleIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
       
      delete collectibleIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }


    
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalTokens = getTotalSupply();
      uint256 resultIndex = 0;

      uint256 tokenIndex;
      uint256 tokenId;
      for (tokenIndex = 0; tokenIndex < totalTokens; tokenIndex++) {
        tokenId = tokens[tokenIndex];
        if (collectibleIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex = resultIndex.add(1);
        }
      }
      return result;
    }
  }
}