 

pragma solidity ^0.4.18;  

 
 
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


contract CityToken is ERC721 {

   

   
  event TokenCreated(uint256 tokenId, string name, uint256 parentId, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name, uint256 parentId);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "CryptoCities";  
  string public constant SYMBOL = "CityToken";  

  uint256 private startingPrice = 0.05 ether;

   

   
   
  mapping (uint256 => address) public tokenIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public tokenIndexToApproved;

   
  mapping (uint256 => uint256) private tokenIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 private tokenCreatedCount;

   

  struct Token {
    string name;
    uint256 parentId;
  }

  Token[] private tokens;

  mapping(uint256 => Token) private tokenIndexToToken;

   
   
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

   
  function CityToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    tokenIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createToken(uint256 _tokenId, address _owner, string _name, uint256 _parentId, uint256 _price) public onlyCOO {

    address tokenOwner = _owner;
    if (tokenOwner == address(0)) {
      tokenOwner = cooAddress;
    }
    
    if (_price <= 0) {
      _price = startingPrice;
    }

    tokenCreatedCount++;
    _createToken(_tokenId, _name, _parentId, tokenOwner, _price);
  }


   
   
  function getToken(uint256 _tokenId) public view returns (
    string tokenName,
    uint256 parentId,
    uint256 sellingPrice,
    address owner
  ) {
    Token storage token = tokenIndexToToken[_tokenId];

    tokenName = token.name;
    parentId = token.parentId;
    sellingPrice = tokenIndexToPrice[_tokenId];
    owner = tokenIndexToOwner[_tokenId];
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
    owner = tokenIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function withdrawFunds(address _to, uint256 amount) public onlyCLevel {
    _withdrawFunds(_to, amount);
  }
  
   
  function purchase(uint256 _tokenId) public payable {
    
     
    if (_tokenId > 999) {
      _purchaseCountry(_tokenId);
    }else {
      _purchaseCity(_tokenId);
    }

  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return tokenIndexToPrice[_tokenId];
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
    address oldOwner = tokenIndexToOwner[_tokenId];

     
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
      uint256 totalTokens = totalSupply();
      uint256 resultIndex = 0;

      uint256 tokenId;
      for (tokenId = 0; tokenId <= totalTokens; tokenId++) {
        if (tokenIndexToOwner[tokenId] == _owner) {
          result[resultIndex] = tokenId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
     
     
     
    return tokenCreatedCount;
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

   

  function _purchaseCity(uint256 _tokenId) private {

     address oldOwner = tokenIndexToOwner[_tokenId];

     
     

    uint256 sellingPrice = tokenIndexToPrice[_tokenId];

     
    require(oldOwner != msg.sender);

     
    require(_addressNotNull(msg.sender));

     
    require(msg.value >= sellingPrice);

     
     
     
     
     
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 92), 100));

     
    uint256 parentId = tokenIndexToToken[_tokenId].parentId;

     
    address ownerOfParent = tokenIndexToOwner[parentId];

     
    uint256 paymentToOwnerOfParent = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 2), 100));

     
     
     
     
     
    if (_addressNotNull(ownerOfParent)) {

       
      ownerOfParent.transfer(paymentToOwnerOfParent);
      
    } else {

       
      payment = SafeMath.add(payment, paymentToOwnerOfParent);
     
    }

     
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
     
    tokenIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 92);
    
    _transfer(oldOwner, msg.sender, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }
    
    TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, msg.sender, tokenIndexToToken[_tokenId].name, parentId);

    msg.sender.transfer(purchaseExcess);
  }

  function _purchaseCountry(uint256 _tokenId) private {

    address oldOwner = tokenIndexToOwner[_tokenId];

    uint256 sellingPrice = tokenIndexToPrice[_tokenId];

     
    require(oldOwner != msg.sender);

     
    require(_addressNotNull(msg.sender));

     
    require(msg.value >= sellingPrice);

     
     
     
     
    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 96), 100));

     
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
     
    tokenIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 96);
    
    _transfer(oldOwner, msg.sender, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }
    
    TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, msg.sender, tokenIndexToToken[_tokenId].name, 0);

    msg.sender.transfer(purchaseExcess);
  }


   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return tokenIndexToApproved[_tokenId] == _to;
  }


   
  function _createToken(uint256 _tokenId, string _name, uint256 _parentId, address _owner, uint256 _price) private {
    
    Token memory _token = Token({
      name: _name,
      parentId: _parentId
    });

     
     
     
     
    uint256 newTokenId = _tokenId;
    tokenIndexToToken[newTokenId] = _token;

     
     
    
     
     
    require(newTokenId == uint256(uint32(newTokenId)));

    TokenCreated(newTokenId, _name, _parentId, _owner);

    tokenIndexToPrice[newTokenId] = _price;

     
     
    _transfer(address(0), _owner, newTokenId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == tokenIndexToOwner[_tokenId];
  }

   
  function _payout(address _to) private {
    if (_to == address(0)) {
      ceoAddress.transfer(this.balance);
    } else {
      _to.transfer(this.balance);
    }
  }

   
  function _withdrawFunds(address _to, uint256 amount) private {
    require(this.balance >= amount);
    if (_to == address(0)) {
      ceoAddress.transfer(amount);
    } else {
      _to.transfer(amount);
    }
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to]++;
     
    tokenIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete tokenIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
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