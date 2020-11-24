 

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

contract LibraryToken is ERC721 {
  using SafeMath for uint256;

   

   
  event Created(uint256 indexed _tokenId, string _language, string _name, address indexed _owner);

   
  event Sold(uint256 indexed _tokenId, address indexed _owner, uint256 indexed _price);

   
  event Bought(uint256 indexed _tokenId, address indexed _owner, uint256 indexed _price);

   
  event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

   
  event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

   
  event FounderSet(address indexed _founder, uint256 indexed _tokenId);




   

   
  string public constant NAME = "CryptoLibraries";  
  string public constant SYMBOL = "CL";  

   
  uint256 private startingPrice = 0.002 ether;
  uint256 private developersCut = 0 ether;
  uint256 private TIER1 = 0.02 ether;
  uint256 private TIER2 = 0.5 ether;
  uint256 private TIER3 = 2.0 ether;
  uint256 private TIER4 = 5.0 ether;

   

   
  mapping (uint256 => address) public libraryIndexToOwner;

   
  mapping (uint256 => address) public libraryIndexToFounder;

   
  mapping (address => uint256) public libraryIndexToFounderCount;

   
  mapping (address => uint256) private ownershipTokenCount;

   
  mapping (uint256 => address) public libraryIndexToApproved;

   
  mapping (uint256 => uint256) private libraryIndexToPrice;

   
  mapping (uint256 => uint256) private libraryIndexToFunds;

   
  address public owner;



   
  struct Library {
    string language;
    string name;
  }

  Library[] private libraries;



   

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyFounder(uint256 _tokenId) {
    require(msg.sender == founderOf(_tokenId));
    _;
  }



   

  function LibraryToken() public {
    owner = msg.sender;
  }



   

   
  function approve(
    address _to,
    uint256 _tokenId
  )
    public
  {
     
    require(msg.sender != _to);

     
    require(_owns(msg.sender, _tokenId));

    libraryIndexToApproved[_tokenId] = _to;

    Approval(msg.sender, _to, _tokenId);
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return ownershipTokenCount[_owner];
  }

   
  function implementsERC721() public pure returns (bool) {
    return true;
  }

   
  function ownerOf(uint256 _tokenId) public view returns (address tokenOwner) {
    tokenOwner = libraryIndexToOwner[_tokenId];
    require(tokenOwner != address(0));
  }

   
  function takeOwnership(uint256 _tokenId) public {
     
    require(_addressNotNull(newOwner));

     
    require(_approved(newOwner, _tokenId));

    address newOwner = msg.sender;
    address oldOwner = libraryIndexToOwner[_tokenId];

    _transfer(oldOwner, newOwner, _tokenId);
  }

   
  function totalSupply() public view returns (uint256 total) {
    return libraries.length;
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

   
  function name() public pure returns (string) {
    return NAME;
  }

   
  function symbol() public pure returns (string) {
    return SYMBOL;
  }



   

   
  function createLibrary(string _language, string _name) public onlyOwner {
    _createLibrary(_language, _name, address(this), address(0), 0, startingPrice);
  }

   
  function createLibraryWithFounder(string _language, string _name, address _founder) public onlyOwner {
    require(_addressNotNull(_founder));
    _createLibrary(_language, _name, address(this), _founder, 0, startingPrice);
  }

   
  function createLibraryBounty(string _language, string _name, address _owner, uint256 _startingPrice) public onlyOwner {
    require(_addressNotNull(_owner));
    _createLibrary(_language, _name, _owner, address(0), 0, _startingPrice);
  }

   
  function getLibrary(uint256 _tokenId) public view returns (
    string language,
    string libraryName,
    uint256 tokenPrice,
    uint256 funds,
    address tokenOwner,
    address founder
  ) {
    Library storage x = libraries[_tokenId];
    libraryName = x.name;
    language = x.language;
    founder = libraryIndexToFounder[_tokenId];
    funds = libraryIndexToFunds[_tokenId];
    tokenPrice = libraryIndexToPrice[_tokenId];
    tokenOwner = libraryIndexToOwner[_tokenId];
  }

   
  function priceOf(uint256 _tokenId) public view returns (uint256 _price) {
    return libraryIndexToPrice[_tokenId];
  }

   
  function nextPriceOf(uint256 _tokenId) public view returns (uint256 _nextPrice) {
    return calculateNextPrice(priceOf(_tokenId));
  }

   
  function founderOf(uint256 _tokenId) public view returns (address _founder) {
    _founder = libraryIndexToFounder[_tokenId];
    require(_founder != address(0));
  }

   
  function fundsOf(uint256 _tokenId) public view returns (uint256 _funds) {
    _funds = libraryIndexToFunds[_tokenId];
  }

   
  function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
    if (_price < TIER1) {
      return _price.mul(200).div(95);
    } else if (_price < TIER2) {
      return _price.mul(135).div(96);
    } else if (_price < TIER3) {
      return _price.mul(125).div(97);
    } else if (_price < TIER4) {
      return _price.mul(117).div(97);
    } else {
      return _price.mul(115).div(98);
    }
  }

   
  function calculateDevCut (uint256 _price) public view returns (uint256 _devCut) {
    if (_price < TIER1) {
      return _price.mul(5).div(100);  
    } else if (_price < TIER2) {
      return _price.mul(4).div(100);  
    } else if (_price < TIER3) {
      return _price.mul(3).div(100);  
    } else if (_price < TIER4) {
      return _price.mul(3).div(100);  
    } else {
      return _price.mul(2).div(100);  
    }
  }

   
  function calculateFounderCut (uint256 _price) public pure returns (uint256 _founderCut) {
    return _price.mul(1).div(100);
  }

   
  function withdrawAll () onlyOwner() public {
    owner.transfer(developersCut);
     
    developersCut = 0;
  }

   
  function withdrawAmount (uint256 _amount) onlyOwner() public {
    require(_amount >= developersCut);

    owner.transfer(_amount);
    developersCut = developersCut.sub(_amount);
  }

     
  function withdrawFounderFunds (uint256 _tokenId) onlyFounder(_tokenId) public {
    address founder = founderOf(_tokenId);
    uint256 funds = fundsOf(_tokenId);
    founder.transfer(funds);

     
    libraryIndexToFunds[_tokenId] = 0;
  }

   
  function purchase(uint256 _tokenId) public payable {
    address oldOwner = libraryIndexToOwner[_tokenId];
    address newOwner = msg.sender;
     
    require(oldOwner != newOwner);

     
    require(_addressNotNull(newOwner));

     
    uint256 price = libraryIndexToPrice[_tokenId];
    require(msg.value >= price);

    uint256 excess = msg.value.sub(price);

    _transfer(oldOwner, newOwner, _tokenId);
    libraryIndexToPrice[_tokenId] = nextPriceOf(_tokenId);

    Bought(_tokenId, newOwner, price);
    Sold(_tokenId, oldOwner, price);

     
     
    uint256 devCut = calculateDevCut(price);
    developersCut = developersCut.add(devCut);

     
     
    uint256 founderCut = calculateFounderCut(price);
    libraryIndexToFunds[_tokenId] = libraryIndexToFunds[_tokenId].add(founderCut);

     
    if (oldOwner != address(this)) {
      oldOwner.transfer(price.sub(devCut.add(founderCut)));
    }

    if (excess > 0) {
      newOwner.transfer(excess);
    }
  }

   
  function tokensOfOwner(address _owner) public view returns(uint256[] ownerTokens) {
    uint256 tokenCount = balanceOf(_owner);
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalLibraries = totalSupply();
      uint256 resultIndex = 0;

      uint256 libraryId;
      for (libraryId = 0; libraryId <= totalLibraries; libraryId++) {
        if (libraryIndexToOwner[libraryId] == _owner) {
          result[resultIndex] = libraryId;
          resultIndex++;
        }
      }
      return result;
    }
  }

     
  function tokensOfFounder(address _founder) public view returns(uint256[] founderTokens) {
    uint256 tokenCount = libraryIndexToFounderCount[_founder];
    if (tokenCount == 0) {
         
      return new uint256[](0);
    } else {
      uint256[] memory result = new uint256[](tokenCount);
      uint256 totalLibraries = totalSupply();
      uint256 resultIndex = 0;

      uint256 libraryId;
      for (libraryId = 0; libraryId <= totalLibraries; libraryId++) {
        if (libraryIndexToFounder[libraryId] == _founder) {
          result[resultIndex] = libraryId;
          resultIndex++;
        }
      }
      return result;
    }
  }


     
  function allTokens() public pure returns(Library[] _libraries) {
    return _libraries;
  }

   
  function setOwner(address _newOwner) public onlyOwner {
    require(_newOwner != address(0));

    owner = _newOwner;
  }

     
  function setFounder(uint256 _tokenId, address _newFounder) public onlyOwner {
    require(_newFounder != address(0));

    address oldFounder = founderOf(_tokenId);

    libraryIndexToFounder[_tokenId] = _newFounder;
    FounderSet(_newFounder, _tokenId);

    libraryIndexToFounderCount[_newFounder] = libraryIndexToFounderCount[_newFounder].add(1);
    libraryIndexToFounderCount[oldFounder] = libraryIndexToFounderCount[oldFounder].sub(1);
  }



   

   
  function _addressNotNull(address _to) private pure returns (bool) {
    return _to != address(0);
  }

   
  function _approved(address _to, uint256 _tokenId) private view returns (bool) {
    return libraryIndexToApproved[_tokenId] == _to;
  }

   
  function _createLibrary(
    string _language,
    string _name,
    address _owner,
    address _founder,
    uint256 _funds,
    uint256 _price
  )
    private
  {
    Library memory _library = Library({
      name: _name,
      language: _language
    });
    uint256 newLibraryId = libraries.push(_library) - 1;

    Created(newLibraryId, _language, _name, _owner);

    libraryIndexToPrice[newLibraryId] = _price;
    libraryIndexToFounder[newLibraryId] = _founder;
    libraryIndexToFunds[newLibraryId] = _funds;

     
    _transfer(address(0), _owner, newLibraryId);
  }

   
  function _owns(address claimant, uint256 _tokenId) private view returns (bool) {
    return claimant == libraryIndexToOwner[_tokenId];
  }

   
  function _transfer(address _from, address _to, uint256 _tokenId) private {
     
    ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);

     
    libraryIndexToOwner[_tokenId] = _to;

     
    if (_from != address(0)) {
      ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);

       
      delete libraryIndexToApproved[_tokenId];
    }

     
    Transfer(_from, _to, _tokenId);
  }
}