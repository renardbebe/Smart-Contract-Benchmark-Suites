 

pragma solidity ^0.4.20;  

 
 
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

 
 
contract ViralLovinCreatorToken is ERC721 {

   

   
  event Birth(
      uint256 tokenId, 
      string name, 
      address owner, 
      uint256 collectiblesOrdered
    );

   
  event TokenSold(
      uint256 tokenId, 
      uint256 oldPrice, 
      uint256 newPrice, 
      address prevOwner, 
      address winner, 
      string name, 
      uint256 collectiblesOrdered
    );

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "ViralLovin Creator Token";  
  string public constant SYMBOL = "CREATOR";  

  uint256 private startingPrice = 0.001 ether;

   

   
   
  mapping (uint256 => address) public creatorIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public creatorIndexToApproved;

   
  mapping (uint256 => uint256) private creatorIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

  uint256 public creatorsCreatedCount;

   
  struct Creator {
    string name;
    uint256 collectiblesOrdered;
  }

  Creator[] private creators;

   
  
   
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

   
  
  function ViralLovinCreatorToken() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
  
   
   
   
   
  function approve(address _to, uint256 _tokenId) public {
     
    require(_owns(msg.sender, _tokenId));
    creatorIndexToApproved[_tokenId] = _to;
    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createCreator(
      address _owner, 
      string _name, 
      uint256 _price, 
      uint256 _collectiblesOrdered
    ) public onlyCOO {
    address creatorOwner = _owner;
    if (creatorOwner == address(0)) {
      creatorOwner = cooAddress;
    }

    if (_price <= 0) {
      _price = startingPrice;
    }

    creatorsCreatedCount++;
    _createCreator(_name, creatorOwner, _price, _collectiblesOrdered);
    }

   
   
  function getCreator(
      uint256 _tokenId
    ) public view returns (
        string creatorName, 
        uint256 sellingPrice, 
        address owner, 
        uint256 collectiblesOrdered
    ) {
    Creator storage creator = creators[_tokenId];
    creatorName = creator.name;
    collectiblesOrdered = creator.collectiblesOrdered;
    sellingPrice = creatorIndexToPrice[_tokenId];
    owner = creatorIndexToOwner[_tokenId];
  }

  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function name() public pure returns (string) {
    return NAME;
  }

   
   
   
  function ownerOf(uint256 _tokenId) public view returns (address owner)
  {
    owner = creatorIndexToOwner[_tokenId];
    require(owner != address(0));
  }

   
  function payout(address _to) public onlyCLevel {
    require(_addressNotNull(_to));
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = creatorIndexToOwner[_tokenId];
    address newOwner = msg.sender;
    uint256 sellingPrice = creatorIndexToPrice[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

     
    _transfer(oldOwner, newOwner, _tokenId);

     
    ceoAddress.transfer(sellingPrice);

     
    TokenSold(
        _tokenId, 
        sellingPrice, 
        creatorIndexToPrice[_tokenId], 
        oldOwner, 
        newOwner, 
        creators[_tokenId].name, 
        creators[_tokenId].collectiblesOrdered
    );
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return creatorIndexToPrice[_tokenId];
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
    address oldOwner = creatorIndexToOwner[_tokenId];

     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
   
  function tokensOfOwner(
      address _owner
      ) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalCreators = totalSupply();
      uint256 resultIndex = 0;
      uint256 creatorId;
      for (creatorId = 0; creatorId <= totalCreators; creatorId++) {
        if (creatorIndexToOwner[creatorId] == _owner) {
          result[resultIndex] = creatorId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return creators.length;
  }

   
   
   
   
  function transfer(address _to, uint256 _tokenId) public {
    require(_owns(msg.sender, _tokenId));
    require(_addressNotNull(_to));
    _transfer(msg.sender, _to, _tokenId);
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _tokenId) public {
    require(_owns(_from, _tokenId));
    require(_approved(_to, _tokenId));
    require(_addressNotNull(_to));

    _transfer(_from, _to, _tokenId);
  }

   
  
   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(
      address _to, 
      uint256 _tokenId
      ) private view returns (bool) {
    return creatorIndexToApproved[_tokenId] == _to;
  }

   
  function _createCreator(
      string _name, 
      address _owner, 
      uint256 _price, 
      uint256 _collectiblesOrdered
      ) private {
    Creator memory _creator = Creator({
      name: _name,
      collectiblesOrdered: _collectiblesOrdered
    });
    uint256 newCreatorId = creators.push(_creator) - 1;

    require(newCreatorId == uint256(uint32(newCreatorId)));

    Birth(newCreatorId, _name, _owner, _collectiblesOrdered);

    creatorIndexToPrice[newCreatorId] = _price;

     
    _transfer(address(0), _owner, newCreatorId);
  }

   
  function _owns(
      address claimant, 
      uint256 _tokenId
      ) private view returns (bool) {
    return claimant == creatorIndexToOwner[_tokenId];
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
     
    creatorIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete creatorIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
  
}