 

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

contract EtherPrincesses is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   

   
  string public constant NAME = "EtherWaifus";  
  string public constant SYMBOL = "WaifuToken";  

  uint256 private startingPrice = 0.001 ether;
  uint256 private firstStepLimit =  0.053613 ether;
  uint256 private secondStepLimit = 0.564957 ether;

   

   
   
  mapping (uint256 => address) public waifuIndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public waifuIndexToApproved;

   
  mapping (uint256 => uint256) private waifuIndexToPrice;

   
  address public ceoAddress;
  address public cooAddress;

   
  struct Waifu {
    string name;
  }

  Waifu[] private waifus;

   
   
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

   
  function EtherPrincesses() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    waifuIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractWaifu(string _name) public onlyCLevel {
    _createWaifu(_name, address(this), startingPrice);
  }

   
   
  function getWaifu(uint256 _tokenId) public view returns (
    string waifuName,
    uint256 sellingPrice,
    address owner
  ) {
    Waifu storage waifu = waifus[_tokenId];
    waifuName = waifu.name;
    sellingPrice = waifuIndexToPrice[_tokenId];
    owner = waifuIndexToOwner[_tokenId];
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
    owner = waifuIndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = waifuIndexToOwner[_tokenId];
    address newOwner = msg.sender;

    uint256 sellingPrice = waifuIndexToPrice[_tokenId];

     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 90), 100));
    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

     
    if (sellingPrice < firstStepLimit) {
       
      waifuIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 90);
    } else if (sellingPrice < secondStepLimit) {
       
      waifuIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 118), 90);
    } else {
       
      waifuIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 113), 90);
    }

    _transfer(oldOwner, newOwner, _tokenId);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(payment);  
    }

    TokenSold(_tokenId, sellingPrice, waifuIndexToPrice[_tokenId], oldOwner, newOwner, waifus[_tokenId].name);

    msg.sender.transfer(purchaseExcess);
  }

  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return waifuIndexToPrice[_tokenId];
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
    address oldOwner = waifuIndexToOwner[_tokenId];

     
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
      uint256 totalWaifus = totalSupply();
      uint256 resultIndex = 0;

      uint256 waifuId;
      for (waifuId = 0; waifuId <= totalWaifus; waifuId++) {
        if (waifuIndexToOwner[waifuId] == _owner) {
          result[resultIndex] = waifuId;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return waifus.length;
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
    return waifuIndexToApproved[_tokenId] == _to;
  }

   
  function _createWaifu(string _name, address _owner, uint256 _price) private {
    Waifu memory _waifu = Waifu({
      name: _name
    });
    uint256 newWaifuId = waifus.push(_waifu) - 1;

     
     
    require(newWaifuId == uint256(uint32(newWaifuId)));

    Birth(newWaifuId, _name, _owner);

    waifuIndexToPrice[newWaifuId] = _price;

     
     
    _transfer(address(0), _owner, newWaifuId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == waifuIndexToOwner[_tokenId];
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
     
    waifuIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete waifuIndexToApproved[_tokenId];
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