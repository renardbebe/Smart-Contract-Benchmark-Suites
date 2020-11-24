 

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

 
 
contract EtherGrey is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
  uint256 private startingPrice = 0.001 ether;

   
  string public constant NAME = "EtherGreys";  
  string public constant SYMBOL = "EtherGrey";  

   

   
   
  mapping (uint256 => address) public greyIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public greyIndexToApproved;

   
  mapping (uint256 => uint256) private greyIndexToPrice;

   
   
  mapping (uint256 => uint256) private greyIndexToPreviousPrice;

   
  mapping (uint256 => address[5]) private greyIndexToPreviousOwners;


   
  address public ceoAddress;
  address public cooAddress;

   
  struct Grey {
    string name;
  }

  Grey[] private greys;

   
   
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

   
  function EtherGrey() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    greyIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractGrey(string _name) public onlyCOO {
    _createGrey(_name, address(this), startingPrice);
  }

   
   
  function getGrey(uint256 _tokenId) public view returns (
    string greyName,
    uint256 sellingPrice,
    address owner,
    uint256 previousPrice,
    address[5] previousOwners
  ) {
    Grey storage grey = greys[_tokenId];
    greyName = grey.name;
    sellingPrice = greyIndexToPrice[_tokenId];
    owner = greyIndexToOwner[_tokenId];
    previousPrice = greyIndexToPreviousPrice[_tokenId];
    previousOwners = greyIndexToPreviousOwners[_tokenId];
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
    owner = greyIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = greyIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    address[5] storage previousOwners = greyIndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = greyIndexToPrice[_tokenId];
    uint256 previousPrice = greyIndexToPreviousPrice[_tokenId];
     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 ownerPayout = SafeMath.add(previousPrice, SafeMath.mul(SafeMath.div(priceDelta, 100), 40));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    greyIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 125), 100);
    greyIndexToPreviousPrice[_tokenId] = sellingPrice;

    uint256 strangePrice = uint256(SafeMath.div(SafeMath.mul(priceDelta, 10), 100));
     
     
    if (oldOwner != address(this)) {
       
      oldOwner.transfer(ownerPayout);
    } else {
      strangePrice = SafeMath.add(ownerPayout, strangePrice);
    }

     
    for (uint i = 0; i <= 5; i++) {
        if (previousOwners[i] != address(this)) {
            previousOwners[i].transfer(uint256(SafeMath.div(SafeMath.mul(priceDelta, 10), 100)));
        } else {
            strangePrice = SafeMath.add(strangePrice, uint256(SafeMath.div(SafeMath.mul(priceDelta, 10), 100)));
        }
    }
    ceoAddress.transfer(strangePrice);

    _transfer(oldOwner, newOwner, _tokenId);

     

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return greyIndexToPrice[_tokenId];
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
    address oldOwner = greyIndexToOwner[_tokenId];

     
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
      uint256 totalGreys = totalSupply();
      uint256 resultIndex = 0;
      uint256 greyId;
      for (greyId = 0; greyId <= totalGreys; greyId++) {
        if (greyIndexToOwner[greyId] == _owner) {
          result[resultIndex] = greyId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return greys.length;
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
    return greyIndexToApproved[_tokenId] == _to;
  }

   
  function _createGrey(string _name, address _owner, uint256 _price) private {
    Grey memory _grey = Grey({
      name: _name
    });
    uint256 newGreyId = greys.push(_grey) - 1;

     
     
    require(newGreyId == uint256(uint32(newGreyId)));

    Birth(newGreyId, _name, _owner);

    greyIndexToPrice[newGreyId] = _price;
    greyIndexToPreviousPrice[newGreyId] = 0;
    greyIndexToPreviousOwners[newGreyId] =
        [address(this), address(this), address(this), address(this)];

     
     
    _transfer(address(0), _owner, newGreyId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == greyIndexToOwner[_tokenId];
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
     
    greyIndexToOwner[_tokenId] = _to;
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete greyIndexToApproved[_tokenId];
    }
     
    greyIndexToPreviousOwners[_tokenId][4]=greyIndexToPreviousOwners[_tokenId][3];
    greyIndexToPreviousOwners[_tokenId][3]=greyIndexToPreviousOwners[_tokenId][2];
    greyIndexToPreviousOwners[_tokenId][2]=greyIndexToPreviousOwners[_tokenId][1];
    greyIndexToPreviousOwners[_tokenId][1]=greyIndexToPreviousOwners[_tokenId][0];
     
    if (_from != address(0)) {
        greyIndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        greyIndexToPreviousOwners[_tokenId][0]=address(this);
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