 

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

contract CryptoColors {
  using SafeMath for uint256;

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
  event Payout(address referrer, uint256 balance);

   
  event ReferrerRegistered(address referrer, address referral);

   
   
  event Transfer(address from, address to, uint256 tokenId);

  event Approval(address indexed owner, address indexed approved, uint256 tokenId);

   

   
  string public constant NAME = "CryptoColors";  
  string public constant SYMBOL = "CLRS";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.02 ether;
  uint256 private secondStepLimit = 0.5 ether;
  uint256 private thirdStepLimit = 2 ether;
  uint256 private forthStepLimit = 5 ether;

   

   
   
  mapping (uint256 => address) public tokenIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public tokenIndexToApproved;

   
  mapping (uint256 => uint256) private tokenIndexToPrice;

   
  mapping (address => uint256) private referrerBalance;

   
  mapping (address => address) private referralToRefferer;

   
  address public ceoAddress;
  address public cooAddress;

   
  struct Token {
    string name;
  }

  Token[] private tokens;

   
   
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

   
  function CryptoColors() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  )
  public
  {
     
    require(_owns(msg.sender, _tokenId));

    tokenIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function _calculateNextPrice(uint256 _sellingPrice) private view returns (uint256 price) {
    if (_sellingPrice < firstStepLimit) {
       
      return _sellingPrice.mul(200).div(100);
    } else if (_sellingPrice < secondStepLimit) {
       
     return _sellingPrice.mul(135).div(100);
    } else if (_sellingPrice < thirdStepLimit) {
       
      return _sellingPrice.mul(125).div(100);
    } else if (_sellingPrice < forthStepLimit) {
       
      return _sellingPrice.mul(120).div(100);
    } else {
       
      return _sellingPrice.mul(115).div(100);
    }
  }

   
  function createContractToken(string _name) public onlyCLevel {
    _createToken(_name, address(this), startingPrice);
  }

   
   
  function getToken(uint256 _tokenId) public view returns (
    string tokenName,
    uint256 sellingPrice,
    address owner
  ) {
    Token storage token = tokens[_tokenId];
    tokenName = token.name;
    sellingPrice = tokenIndexToPrice[_tokenId];
    owner = tokenIndexToOwner[_tokenId];
  }

   
  function getReferrer(address _address) public view returns (address referrerAddress) {
    return referralToRefferer[_address];
  }

   
  function getReferrerBalance(address _address) public view returns (uint256 totalAmount) {
    return referrerBalance[_address];
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

  function payoutToReferrer() public payable {
    address referrer = msg.sender;
    uint256 totalAmount = referrerBalance[referrer];
    if (totalAmount > 0) {
      msg.sender.transfer(totalAmount);
      referrerBalance[referrer] = 0;
      Payout(referrer, totalAmount);
    }
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return tokenIndexToPrice[_tokenId];
  }

     
  function purchase(uint256 _tokenId, address _referrer) public payable {
    address newOwner = msg.sender;
    address oldOwner = tokenIndexToOwner[_tokenId];
    uint256 sellingPrice = tokenIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);
     
    require(_addressNotNull(newOwner));
     
    require(msg.value >= sellingPrice);

    uint256 payment = sellingPrice.mul(95).div(100);
    uint256 purchaseExcess = msg.value.sub(sellingPrice);
     
    uint256 referrerPayout = sellingPrice.sub(payment).mul(15).div(100);   
    address storedReferrer = getReferrer(newOwner);

     
    if (_addressNotNull(storedReferrer)) {
       
      referrerBalance[storedReferrer] += referrerPayout;
    } else if (_addressNotNull(_referrer)) {
       
      referralToRefferer[newOwner] = _referrer;
       
      ReferrerRegistered(_referrer, newOwner);
      referrerBalance[_referrer] += referrerPayout;      
    } 

     
    tokenIndexToPrice[_tokenId] = _calculateNextPrice(sellingPrice);

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);
    }

    TokenSold(_tokenId, sellingPrice, tokenIndexToPrice[_tokenId], oldOwner, newOwner, tokens[_tokenId].name);

     
    if (purchaseExcess > 0) {
      msg.sender.transfer(purchaseExcess);
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
    return tokens.length;
  }

   
   
   
   
  function transfer(
    address _to,
    uint256 _tokenId
  )
  public
  {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));

    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
  public
  {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return tokenIndexToApproved[_tokenId] == _to;
  }

   
  function _createToken(string _name, address _owner, uint256 _price) private {
    Token memory _token = Token({
      name: _name
    });
    uint256 newTokenId = tokens.push(_token) - 1;

     
     
    require(newTokenId == uint256(uint32(newTokenId)));

    Birth(newTokenId, _name, _owner);

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