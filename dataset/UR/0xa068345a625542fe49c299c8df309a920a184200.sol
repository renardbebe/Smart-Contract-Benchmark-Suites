 

pragma solidity ^0.4.19;  


 
 
contract ERC721 {
   
  function approve(address _to, uint256 _tokenId) public;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function implementsERC721() public pure returns (bool);
  function ownerOf(uint256 _tokenId) public view returns (address addr);
  function takeOwnership(uint256 _tokenId) public;
  function totalSupply() public view returns (uint256 total);
  function transferFrom(address _from, address _to, uint256 _tokenId) public;
  function transfer(address _to, uint256 _tokenId) public;

  event Transfer(address indexed from, address indexed to, uint256 tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

}

contract CryptonToken is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner, bool isProtected, uint8 category);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
  event PaymentTransferredToPreviousOwner(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
  event CryptonIsProtected(uint256 tokenId);

     
    event MarkupChanged(string name, uint256 newMarkup);
    
     
    event ProtectedCryptonSellingPriceChanged(uint256 tokenId, uint256 newSellingPrice);
    
     
    event OwnerProtectedCrypton(uint256 _tokenId, uint256 newSellingPrice);

     
    event ContractIsPaused(bool paused);

   

   
  string public constant NAME = "Cryptons";  
  string public constant SYMBOL = "CRYPTON";  

  uint256 private startingPrice = 0.1 ether;
  uint256 private defaultMarkup = 2 ether;
  uint256 private FIRST_STEP_LIMIT =  1.0 ether;
  uint16 private FIRST_STEP_MULTIPLIER = 200;  
  uint16 private SECOND_STEP_MULTIPLIER = 120;  
  uint16 private XPROMO_MULTIPLIER = 500;  
  uint16 private CRYPTON_CUT = 6;  
  uint16 private NET_PRICE_PERCENT = 100 - CRYPTON_CUT;  

   
  uint8 private constant PROMO = 1;
  uint8 private constant STANDARD = 2;
  uint8 private constant RESERVED = 7;
  uint8 private constant XPROMO = 10;  
  
   

   
   
  mapping (uint256 => address) public cryptonIndexToOwner;

  mapping (uint256 => bool) public cryptonIndexToProtected;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public cryptonIndexToApproved;

   
  mapping (uint256 => uint256) private cryptonIndexToPrice;


   
  address public ceoAddress;
  address public cooAddress;

   
  struct Crypton {
    string name;
    uint8  category;
    uint256 markup;
  }

  Crypton[] private cryptons;

     
    bool public paused = false;

   
   
   
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

     
     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause()
        external
        onlyCLevel
        whenNotPaused
    {
        paused = true;
        emit ContractIsPaused(paused);
    }

     
     
     
    function unpause()
        public
        onlyCEO
        whenPaused
    {
         
        paused = false;
        emit ContractIsPaused(paused);
    }
   
  constructor() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public whenNotPaused {
     
    require(_owns(msg.sender, _tokenId));

    cryptonIndexToApproved[_tokenId] = _to;

    emit Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createCrypton(
    string _name,                            
    uint8 _category,                         
    uint256 _startingPrice,                  
    uint256 _markup,                         
    address _owner                           
    ) public onlyCLevel {
      address cryptonOwner = _owner;
      if (cryptonOwner == address(0)) {
        cryptonOwner = address(this);
      }
      
      if (_category == XPROMO) {     
          cryptonOwner = address(this);
      }

      if (_markup <= 0) {
          _markup = defaultMarkup;
      }
        
      if (_category == PROMO) {  
        _markup = 0;  
      }

      if (_startingPrice <= 0) {
        _startingPrice = startingPrice;
      }


      bool isProtected = (_category == PROMO)?true:false;  
      
      _createCrypton(_name, cryptonOwner, _startingPrice, _markup, isProtected, _category);
  }

   
   
  function getCrypton(uint256 _tokenId) public view returns (
    string cryptonName,
    uint8 category,
    uint256 markup,
    uint256 sellingPrice,
    address owner,
    bool isProtected
  ) {
    Crypton storage crypton = cryptons[_tokenId];
    cryptonName = crypton.name;
    sellingPrice = cryptonIndexToPrice[_tokenId];
    owner = cryptonIndexToOwner[_tokenId];
    isProtected = cryptonIndexToProtected[_tokenId];
    category = crypton.category;
    markup = crypton.markup;
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
    owner = cryptonIndexToOwner[_tokenId];
    require(owner != address(0));
  }

   
   
   
  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function setPriceForProtectedCrypton(uint256 _tokenId, uint256 newSellingPrice) public whenNotPaused {
    address oldOwner = cryptonIndexToOwner[_tokenId];  
    address newOwner = msg.sender;                     
    require(oldOwner == newOwner);  
    require(cryptonIndexToProtected[_tokenId]);  
    require(newSellingPrice > 0);   
    cryptonIndexToPrice[_tokenId] = newSellingPrice;
    emit ProtectedCryptonSellingPriceChanged(_tokenId, newSellingPrice);
 }

   
  function setProtectionForMyUnprotectedCrypton(uint256 _tokenId, uint256 newSellingPrice) public payable whenNotPaused {
    address oldOwner = cryptonIndexToOwner[_tokenId];  
    address newOwner = msg.sender;                     
    uint256 markup = cryptons[_tokenId].markup;
    if (cryptons[_tokenId].category != PROMO) {
      require(markup > 0);  
    }
    
    require(oldOwner == newOwner);  
    require(! cryptonIndexToProtected[_tokenId]);  
    require(newSellingPrice > 0);   
    require(msg.value >= markup);    
    
    cryptonIndexToPrice[_tokenId] = newSellingPrice;
    cryptonIndexToProtected[_tokenId] = true;
    
    emit OwnerProtectedCrypton(_tokenId, newSellingPrice);
 }
 
  function getMarkup(uint256 _tokenId) public view returns (uint256 markup) {
    return cryptons[_tokenId].markup;
  }

   
  function setMarkup(uint256 _tokenId, uint256 newMarkup) public onlyCLevel {
    require(newMarkup >= 0);
    cryptons[_tokenId].markup = newMarkup;
    emit MarkupChanged(cryptons[_tokenId].name, newMarkup);
  }
    
   
  function purchase(uint256 _tokenId, uint256 newSellingPrice) public payable whenNotPaused {
    address oldOwner = cryptonIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    bool isAlreadyProtected = cryptonIndexToProtected[_tokenId];
    
    uint256 sellingPrice = cryptonIndexToPrice[_tokenId];
    uint256 markup = cryptons[_tokenId].markup;
    
    if (cryptons[_tokenId].category != PROMO) {
      require(markup > 0);  
    }

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);  

    if (newSellingPrice > 0) {  
        uint256 purchasePrice = sellingPrice;  
        if (! cryptonIndexToProtected[_tokenId] ) {  
            purchasePrice = sellingPrice + markup;   
        }

         
         
        require(msg.value >= purchasePrice); 

         
        cryptonIndexToPrice[_tokenId] = newSellingPrice;   
        cryptonIndexToProtected[_tokenId] = true;          
        emit CryptonIsProtected(_tokenId);                 

    } else {
         
         
        if (
          (oldOwner == address(this)) &&                 
          (cryptons[_tokenId].category == XPROMO)       
          ) 
        {
          cryptonIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, XPROMO_MULTIPLIER), NET_PRICE_PERCENT);            
        } else {
          if (sellingPrice < FIRST_STEP_LIMIT) {
             
            cryptonIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, FIRST_STEP_MULTIPLIER), NET_PRICE_PERCENT);
          } else {
             
            cryptonIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, SECOND_STEP_MULTIPLIER), NET_PRICE_PERCENT);
          }
        }

    }
       
    _transfer(oldOwner, newOwner, _tokenId);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, NET_PRICE_PERCENT), 100));
    string storage cname = cryptons[_tokenId].name;

    bool isReservedToken = (cryptons[_tokenId].category == RESERVED);
  
    if (isReservedToken && isAlreadyProtected) {
      oldOwner.transfer(payment);  
      emit PaymentTransferredToPreviousOwner(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);
      emit TokenSold(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);
      return;
    }

     
    if ((oldOwner != address(this)) && !isReservedToken )  
    {
      oldOwner.transfer(payment);  
      emit PaymentTransferredToPreviousOwner(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);
    }

    emit TokenSold(_tokenId, sellingPrice, cryptonIndexToPrice[_tokenId], oldOwner, newOwner, cname);

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return cryptonIndexToPrice[_tokenId];
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

   
   
   
  function takeOwnership(uint256 _tokenId) public whenNotPaused {
    address newOwner = msg.sender;
    address oldOwner = cryptonIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
   
   
   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCryptons = totalSupply();
      uint256 resultIndex = 0;

      uint256 cryptonId;
      for (cryptonId = 0; cryptonId <= totalCryptons; cryptonId++) {
        if (cryptonIndexToOwner[cryptonId] == _owner) {
          result[resultIndex] = cryptonId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return cryptons.length;
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  ) public whenNotPaused {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public whenNotPaused {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return cryptonIndexToApproved[_tokenId] == _to;
  }

   
  function _createCrypton(string _name, address _owner, uint256 _price, uint256 _markup, bool _isProtected, uint8 _category) private {
    Crypton memory _crypton = Crypton({
      name: _name,
      category: _category,
      markup: _markup
    });
    uint256 newCryptonId = cryptons.push(_crypton) - 1;

     
     
    require(newCryptonId == uint256(uint32(newCryptonId)));

    emit Birth(newCryptonId, _name, _owner, _isProtected, _category);

    cryptonIndexToPrice[newCryptonId] = _price;
    
    cryptonIndexToProtected[newCryptonId] = _isProtected;  

     
     
    _transfer(address(0), _owner, newCryptonId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == cryptonIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    address myAddress = this;
    if (_to == address(0)) {
      ceoAddress.transfer(myAddress.balance);
    } else {
      _to.transfer(myAddress.balance);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    cryptonIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete cryptonIndexToApproved[_tokenId];
    }

     
    emit Transfer(_from, _to, _tokenId);
  }

 

  function setFIRST_STEP_LIMIT(uint256 newLimit) public onlyCLevel {
    require(newLimit > 0 && newLimit < 100 ether);
    FIRST_STEP_LIMIT = newLimit;
  }
  function getFIRST_STEP_LIMIT() public view returns (uint256 value) {
    return FIRST_STEP_LIMIT;
  }

  function setFIRST_STEP_MULTIPLIER(uint16 newValue) public onlyCLevel {
    require(newValue >= 110 && newValue <= 200);
    FIRST_STEP_MULTIPLIER = newValue;
  }
  function getFIRST_STEP_MULTIPLIER() public view returns (uint16 value) {
    return FIRST_STEP_MULTIPLIER;
  }

  function setSECOND_STEP_MULTIPLIER(uint16 newValue) public onlyCLevel {
    require(newValue >= 110 && newValue <= 200);
    SECOND_STEP_MULTIPLIER = newValue;
  }
  function getSECOND_STEP_MULTIPLIER() public view returns (uint16 value) {
    return SECOND_STEP_MULTIPLIER;
  }

  function setXPROMO_MULTIPLIER(uint16 newValue) public onlyCLevel {
    require(newValue >= 100 && newValue <= 10000);  
    XPROMO_MULTIPLIER = newValue;
  }
  function getXPROMO_MULTIPLIER() public view returns (uint16 value) {
    return XPROMO_MULTIPLIER;
  }

  function setCRYPTON_CUT(uint16 newValue) public onlyCLevel {
    require(newValue > 0 && newValue < 10);
    CRYPTON_CUT = newValue;
  }
  function getCRYPTON_CUT() public view returns (uint16 value) {
    return CRYPTON_CUT;
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