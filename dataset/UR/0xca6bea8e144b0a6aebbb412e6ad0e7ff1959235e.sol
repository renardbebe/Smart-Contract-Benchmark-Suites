 

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

contract EtherConsole is ERC721 {

   

   
  event Birth(uint256 tokenId, string name, address owner);

   
  event TokenSold(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address winner, string name);

   
   
  event Transfer(address from, address to, uint256 tokenId);

   
   

   
  string public constant NAME = "CrypoConsoles";  
  string public constant SYMBOL = "CryptoConsole";  

   

   
   
  mapping (uint256 => address) public item23IndexToOwner;

   
   
  mapping (address => uint256) private ownershipTokenCount;

   
   
   
  mapping (uint256 => address) public item23IndexToApproved;

   
  mapping (uint256 => uint256) private item23IndexToPrice;

   
   
  mapping (uint256 => uint256) private item23IndexToPreviousPrice;

   
  mapping (uint256 => address[5]) private item23IndexToPreviousOwners;


   
  address public ceoAddress;
  address public cooAddress;

   
  struct Item23 {
    string name;
  }

  Item23[] private item23s;

   
   
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

   
  function EtherConsole() public {
    ceoAddress = msg.sender;
    cooAddress = msg.sender;
  }

   
   
   
   
   
   
  function approve(
    address _to,
    uint256 _tokenId
  ) public {
     
    require(_owns(msg.sender, _tokenId));

    item23IndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
   
   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function createContractItem23(string _name , string _startingP ) public onlyCOO {
    _createItem23(_name, address(this), stringToUint( _startingP));
  }



function stringToUint(string _amount) internal constant returns (uint result) {
    bytes memory b = bytes(_amount);
    uint i;
    uint counterBeforeDot;
    uint counterAfterDot;
    result = 0;
    uint totNum = b.length;
    totNum--;
    bool hasDot = false;

    for (i = 0; i < b.length; i++) {
        uint c = uint(b[i]);

        if (c >= 48 && c <= 57) {
            result = result * 10 + (c - 48);
            counterBeforeDot ++;
            totNum--;
        }

        if(c == 46){
            hasDot = true;
            break;
        }
    }

    if(hasDot) {
        for (uint j = counterBeforeDot + 1; j < 18; j++) {
            uint m = uint(b[j]);

            if (m >= 48 && m <= 57) {
                result = result * 10 + (m - 48);
                counterAfterDot ++;
                totNum--;
            }

            if(totNum == 0){
                break;
            }
        }
    }
     if(counterAfterDot < 18){
         uint addNum = 18 - counterAfterDot;
         uint multuply = 10 ** addNum;
         return result = result * multuply;
     }

     return result;
}


   
   
  function getItem23(uint256 _tokenId) public view returns (
    string item23Name,
    uint256 sellingPrice,
    address owner,
    uint256 previousPrice,
    address[5] previousOwners
  ) {
    Item23 storage item23 = item23s[_tokenId];
    item23Name = item23.name;
    sellingPrice = item23IndexToPrice[_tokenId];
    owner = item23IndexToOwner[_tokenId];
    previousPrice = item23IndexToPreviousPrice[_tokenId];
    previousOwners = item23IndexToPreviousOwners[_tokenId];
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
    owner = item23IndexToOwner[_tokenId];
    require(owner != address(0));
  }

  function payout(address _to) public onlyCLevel {
    _payout(_to);
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = item23IndexToOwner[_tokenId];
    address newOwner = msg.sender;

    address[5] storage previousOwners = item23IndexToPreviousOwners[_tokenId];

    uint256 sellingPrice = item23IndexToPrice[_tokenId];
    uint256 previousPrice = item23IndexToPreviousPrice[_tokenId];
     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    require(msg.value >= sellingPrice);

    uint256 priceDelta = SafeMath.sub(sellingPrice, previousPrice);
    uint256 ownerPayout = SafeMath.add(previousPrice, SafeMath.mul(SafeMath.div(priceDelta, 100), 40));


    uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

    item23IndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 150), 100);
    item23IndexToPreviousPrice[_tokenId] = sellingPrice;

    uint256 strangePrice = uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10));
    uint256 strangePrice2 = uint256(0);


     
     
    if (oldOwner != address(this)) {
       
      oldOwner.transfer(ownerPayout);
    } else {
      strangePrice = SafeMath.add(ownerPayout, strangePrice);
    }

     
    for (uint i = 0; i < 5; i++) {
        if (previousOwners[i] != address(this)) {
            strangePrice2+=uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10));
        } else {
            strangePrice = SafeMath.add(strangePrice, uint256(SafeMath.mul(SafeMath.div(priceDelta, 100), 10)));
        }
    }

    ceoAddress.transfer(strangePrice+strangePrice2);
     
    _transfer(oldOwner, newOwner, _tokenId);

     

    msg.sender.transfer(purchaseExcess);
  }


  function priceOf(uint256 _tokenId) public view returns (uint256 price) {
    return item23IndexToPrice[_tokenId];
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
    address oldOwner = item23IndexToOwner[_tokenId];

     
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
      uint256 totalItem23s = totalSupply();
      uint256 resultIndex = 0;
      uint256 item23Id;
      for (item23Id = 0; item23Id <= totalItem23s; item23Id++) {
        if (item23IndexToOwner[item23Id] == _owner) {
          result[resultIndex] = item23Id;
          resultIndex++;
        }
      }
      return result;
    }
  }

   
   
  function totalSupply() public view returns (uint256 total) {
    return item23s.length;
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
    return item23IndexToApproved[_tokenId] == _to;
  }

   
  function _createItem23(string _name, address _owner, uint256 _price) private {
    Item23 memory _item23 = Item23({
      name: _name
    });
    uint256 newItem23Id = item23s.push(_item23) - 1;

     
     
    require(newItem23Id == uint256(uint32(newItem23Id)));

    Birth(newItem23Id, _name, _owner);

    item23IndexToPrice[newItem23Id] = _price;
    item23IndexToPreviousPrice[newItem23Id] = 0;
    item23IndexToPreviousOwners[newItem23Id] =
        [address(this), address(this), address(this), address(this)];

     
     
    _transfer(address(0), _owner, newItem23Id);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == item23IndexToOwner[_tokenId];
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
     
    item23IndexToOwner[_tokenId] = _to;
     
    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
       
      delete item23IndexToApproved[_tokenId];
    }
     
    item23IndexToPreviousOwners[_tokenId][4]=item23IndexToPreviousOwners[_tokenId][3];
    item23IndexToPreviousOwners[_tokenId][3]=item23IndexToPreviousOwners[_tokenId][2];
    item23IndexToPreviousOwners[_tokenId][2]=item23IndexToPreviousOwners[_tokenId][1];
    item23IndexToPreviousOwners[_tokenId][1]=item23IndexToPreviousOwners[_tokenId][0];
     
    if (_from != address(0)) {
        item23IndexToPreviousOwners[_tokenId][0]=_from;
    } else {
        item23IndexToPreviousOwners[_tokenId][0]=address(this);
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