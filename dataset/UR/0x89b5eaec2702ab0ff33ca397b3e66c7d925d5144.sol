 

pragma solidity ^0.4.19;

contract Soccer {
  using SafeMath for uint256;
   
   
  event Birth(uint256 tokenId, uint256 startPrice);
   
  event TokenSold(uint256 indexed tokenId, uint256 price, address prevOwner, address winner);
   
  event Transfer(address indexed from, address indexed to, uint256 tokenId);
   
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   

  string public constant NAME = "SoccerAllStars";
  string public constant SYMBOL = "SAS";

   
  struct Token {
    address owner;
    uint256 price;
  }
  mapping (uint256 => Token) collectibleIdx;
  mapping (uint256 => address[3]) mapToLastOwners;
  mapping (uint256 => address) collectibleIndexToApproved;
  uint256[] private tokens;

   
  address public ceoAddress;
  address public cooAddress;

  uint16 constant NATION_INDEX = 1000;
  uint32 constant CLUB_INDEX = 1000000;

  uint256 private constant PROMO_CREATION_LIMIT = 50000;
  uint256 public promoCreatedCount;

  uint256 constant PLAYER_PRICE = 1 finney;
  uint256 constant CLUB_PRICE = 10 finney;
  uint256 constant NATION_PRICE = 100 finney;

   
  function Soccer() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }
  
  function getTotalSupply() public view returns (uint) {
    return tokens.length;
  }
  
  function getInitialPriceOfToken(uint _tokenId) public pure returns (uint) {
    if (_tokenId > CLUB_INDEX)
      return PLAYER_PRICE;
    if (_tokenId > NATION_INDEX)
      return CLUB_PRICE;
    return NATION_PRICE;
  }

  function getNextPrice(uint price, uint _tokenId) public pure returns (uint) {
    if (price < 0.05 ether)
      return price.mul(200).div(93);  
    if (price < 0.5 ether)
      return price.mul(150).div(93);  
    if (price < 2 ether)
      return price.mul(130).div(93);  
    return price.mul(120).div(93);  
  }

  function buyToken(uint _tokenId) public payable {
    require(!isContract(msg.sender));
    
    Token memory token = collectibleIdx[_tokenId];
    address oldOwner = address(0);
    uint256 sellingPrice;
    if (token.owner == address(0)) {
        sellingPrice = getInitialPriceOfToken(_tokenId);
        token = Token({
            owner: msg.sender,
            price: sellingPrice
        });
    } else {
        oldOwner = token.owner;
        sellingPrice = token.price;
        require(oldOwner != msg.sender);
    }
    require(msg.value >= sellingPrice);
    
    address[3] storage lastOwners = mapToLastOwners[_tokenId];
    uint256 payment = _handle(_tokenId, sellingPrice, lastOwners);

     
    token.owner = msg.sender;
    token.price = getNextPrice(sellingPrice, _tokenId);
    mapToLastOwners[_tokenId] = _addLastOwner(lastOwners, oldOwner);

    collectibleIdx[_tokenId] = token;
    if (oldOwner != address(0)) {
       
      oldOwner.transfer(payment);
       
      delete collectibleIndexToApproved[_tokenId];
    } else {
      Birth(_tokenId, sellingPrice);
      tokens.push(_tokenId);
    }

    TokenSold(_tokenId, sellingPrice, oldOwner, msg.sender);
    Transfer(oldOwner, msg.sender, _tokenId);

     
    uint256 purchaseExcess = msg.value.sub(sellingPrice);
    if (purchaseExcess > 0) {
        msg.sender.transfer(purchaseExcess);
    }
  }

function _handle(uint256 _tokenId, uint256 sellingPrice, address[3] lastOwners) private returns (uint256) {
    uint256 pPrice = sellingPrice.div(100);
    uint256 tax = pPrice.mul(7);  
    if (_tokenId > CLUB_INDEX) {
        uint256 clubId = _tokenId % CLUB_INDEX;
        Token storage clubToken = collectibleIdx[clubId];
        if (clubToken.owner != address(0)) {
            uint256 clubTax = pPrice.mul(2);  
            tax += clubTax;
            clubToken.owner.transfer(clubTax);
        }

        uint256 nationId = clubId % NATION_INDEX;
        Token storage nationToken = collectibleIdx[nationId];
        if (nationToken.owner != address(0)) {
            tax += pPrice;  
            nationToken.owner.transfer(pPrice);
        }
    } else if (_tokenId > NATION_INDEX) {
        nationId = _tokenId % NATION_INDEX;
        nationToken = collectibleIdx[nationId];
        if (nationToken.owner != address(0)) {
            tax += pPrice;  
            nationToken.owner.transfer(pPrice);
        }
    }

     
    uint256 lastOwnerTax;
    if (lastOwners[0] != address(0)) {
      tax += pPrice;  
      lastOwners[0].transfer(pPrice);
    }
    if (lastOwners[1] != address(0)) {
      lastOwnerTax = pPrice.mul(2);  
      tax += lastOwnerTax;
      lastOwners[1].transfer(lastOwnerTax);
    }
    if (lastOwners[2] != address(0)) {
      lastOwnerTax = pPrice.mul(3);  
      tax += lastOwnerTax;
      lastOwners[2].transfer(lastOwnerTax);
    }

    return sellingPrice.sub(tax);
}

function _addLastOwner(address[3] lastOwners, address oldOwner) pure private returns (address[3]) {
    lastOwners[0] = lastOwners[1];
    lastOwners[1] = lastOwners[2];
    lastOwners[2] = oldOwner;
    return lastOwners;
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
    require( msg.sender == ceoAddress || msg.sender == cooAddress );
    _;
  }

   
   
   
   
   
   
  function approve(address _to, uint256 _tokenId) public {
     
    require(_owns(msg.sender, _tokenId));

    collectibleIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
  function createPromoCollectible(uint256 tokenId, address _owner, uint256 _price) public onlyCLevel {
    Token memory token = collectibleIdx[tokenId];
    require(token.owner == address(0));
    require(promoCreatedCount < PROMO_CREATION_LIMIT);

    address collectibleOwner = _owner;
    if (collectibleOwner == address(0)) {
      collectibleOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = getInitialPriceOfToken(tokenId);
    }

    promoCreatedCount++;
    token = Token({
        owner: collectibleOwner,
        price: _price
    });
    collectibleIdx[tokenId] = token;
    Birth(tokenId, _price);
    tokens.push(tokenId);

     
     
    _transfer(address(0), collectibleOwner, tokenId);

  }

  bool isChangePriceLocked = false;
   
  function changePrice(uint256 _tokenId, uint256 newPrice) public {
    require((_owns(msg.sender, _tokenId) && !isChangePriceLocked) || (_owns(address(0), _tokenId) && msg.sender == cooAddress));
    Token storage token = collectibleIdx[_tokenId];
    require(newPrice < token.price);
    token.price = newPrice;
    collectibleIdx[_tokenId] = token;
  }
  function unlockPriceChange() public onlyCLevel {
    isChangePriceLocked = false;
  }
  function lockPriceChange() public onlyCLevel {
    isChangePriceLocked = true;
  }

   
   
  function getToken(uint256 _tokenId) public view returns (uint256 tokenId, uint256 sellingPrice, address owner, uint256 nextSellingPrice) {
    tokenId = _tokenId;
    Token storage token = collectibleIdx[_tokenId];
    sellingPrice = token.price;
    if (sellingPrice == 0)
      sellingPrice = getInitialPriceOfToken(_tokenId);
    owner = token.owner;
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
    Token storage token = collectibleIdx[_tokenId];
    require(token.owner != address(0));
    owner = token.owner;
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }


  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    Token storage token = collectibleIdx[_tokenId];
    if (token.owner == address(0)) {
        price = getInitialPriceOfToken(_tokenId);
    } else {
        price = token.price;
    }
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
    Token storage token = collectibleIdx[_tokenId];
    require(token.owner != address(0));
    address oldOwner = token.owner;

     
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

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    Token storage token = collectibleIdx[_tokenId];
    return claimant == token.owner;
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
        if (collectibleIdx[tokenId].owner == _owner) {
          result = result.add(1);
        }
      }
      return result;
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    collectibleIdx[_tokenId].owner = _to;

     
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
        if (collectibleIdx[tokenId].owner == _owner) {
          result[resultIndex] = tokenId;
          resultIndex = resultIndex.add(1);
        }
      }
      return result;
    }
  }

     
  function isContract(address addr) private view returns (bool) {
    uint size;
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