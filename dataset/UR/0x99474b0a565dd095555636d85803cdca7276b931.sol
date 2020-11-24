 

pragma solidity ^0.4.18;

contract AccessControl {
    address public owner;
    address[] public admins;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmins {
        bool found = false;

        for (uint i = 0; i < admins.length; i++) {
            if (admins[i] == msg.sender) {
                found = true;
                break;
            }
        }
        require(found);
        _;
    }

    function addAdmin(address _adminAddress) public onlyOwner {
        admins.push(_adminAddress);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

}

contract ERC721 {
     
    function implementsERC721() public pure returns (bool);
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) public view returns (uint256);
    function ownerOf(uint256 _tokenId) public view returns (address);
    function transfer(address _to, uint _tokenId) public;
    function approve(address _to, uint256 _tokenId) public;
    function transferFrom(address _from, address _to, uint256 _tokenId) public;

     
    function name() public pure returns (string);
    function symbol() public pure returns (string);
     
     

     
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
}


contract CryptoLandmarks is AccessControl, ERC721 {
     
    event Creation(uint256 tokenId, string name, address owner);

     
    event Purchase(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address owner, uint256 charityId);

     
    event PriceChange(uint256 tokenId, uint256 price);

     
    event Charity(uint256 charityId, address charity);

    string public constant NAME = "Crypto Landmarks"; 
    string public constant SYMBOL = "LANDMARK"; 

     
    uint256 private startingPrice = 0.001 ether;

     
    bool charityEnabled;

     
    struct Landmark {
         
        string name;

         
        uint256 price;

         
        uint256 maxPrice;
    }

    Landmark[] public landmarks;

    address[] public charities;
    
    mapping (uint256 => address) public landmarkToOwner;
    mapping (address => uint256) public landmarkOwnershipCount;
    mapping (uint256 => address) public landmarkToApproved;

    function CryptoLandmarks() public {
        owner = msg.sender;
        admins.push(msg.sender);
        charityEnabled = false;
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return landmarks.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return landmarkOwnershipCount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = landmarkToOwner[_tokenId];
        require(owner != address(0));
    }
    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(landmarkToOwner[_tokenId] == msg.sender);

        _transfer(msg.sender, _to, _tokenId);
    }
    function approve(address _to, uint256 _tokenId) public {
        require(landmarkToOwner[_tokenId] == msg.sender);
        landmarkToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(landmarkToApproved[_tokenId] == _to);
        require(_to != address(0));
        require(landmarkToOwner[_tokenId] == _from);

        _transfer(_from, _to, _tokenId);
    }
    function name() public pure returns (string) {
        return NAME;
    }
    function symbol() public pure returns (string) {
        return SYMBOL;
    }

    function addCharity(address _charity) public onlyAdmins {
        require(_charity != address(0));

        uint256 newCharityId = charities.push(_charity) - 1;

         
        Charity(newCharityId, _charity);
    }

    function deleteCharity(uint256 _charityId) public onlyAdmins {
        delete charities[_charityId];

         
        Charity(_charityId, address(0));
    }

    function getCharity(uint256 _charityId) public view returns (address) {
        return charities[_charityId];
    }

    function createLandmark(string _name, address _owner, uint256 _price) public onlyAdmins {
        if (_price <= 0) {
            _price = startingPrice;
        }
        
        Landmark memory _landmark = Landmark({
            name: _name,
            price: _price,
            maxPrice: _price
        });
        uint256 newLandmarkId = landmarks.push(_landmark) - 1;

        Creation(newLandmarkId, _name, _owner);

        _transfer(address(0), _owner, newLandmarkId);


    }

    function getLandmark(uint256 _tokenId) public view returns (
        string landmarkName,
        uint256 sellingPrice,
        uint256 maxPrice,
        address owner
    ) {
        Landmark storage landmark = landmarks[_tokenId];
        landmarkName = landmark.name;
        sellingPrice = landmark.price;
        maxPrice = landmark.maxPrice;
        owner = landmarkToOwner[_tokenId];
    }

    function purchase(uint256 _tokenId, uint256 _charityId) public payable {
         
        address oldOwner = landmarkToOwner[_tokenId];
         
        uint sellingPrice = landmarks[_tokenId].price;
         
        address newOwner = msg.sender;
        
        
        require(oldOwner != newOwner);
        require(newOwner != address(0));
        require(msg.value >= sellingPrice);

        uint256 payment = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 95), 100));
        uint256 excess = SafeMath.sub(msg.value, sellingPrice);

        if (charityEnabled == true) {
            
             
            address charity = charities[_charityId];

             
            require(charity != address(0));
            
             
            uint256 donate = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 1), 100));

             
            charity.transfer(donate);
            
        }

        uint priceIncrease = 120;

         
        if (sellingPrice <= 32 finney) {
            priceIncrease = 200;
        }

         
        landmarks[_tokenId].price = SafeMath.div(SafeMath.mul(sellingPrice, priceIncrease), 95);
        
         
        landmarks[_tokenId].maxPrice = SafeMath.div(SafeMath.mul(sellingPrice, priceIncrease), 95);

         
        _transfer(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

         
        Purchase(_tokenId, sellingPrice, landmarks[_tokenId].price, oldOwner, newOwner, _charityId);
        

         
        newOwner.transfer(excess);
    }

     
    function changePrice(uint256 _tokenId, uint256 _price) public {
         
        require(landmarkToOwner[_tokenId] == msg.sender);

         
        require(landmarks[_tokenId].maxPrice >= _price);

         
        landmarks[_tokenId].price = _price;
        
         
        PriceChange(_tokenId, _price);
    }

    function priceOfLandmark(uint256 _tokenId) public view returns (uint256) {
        return landmarks[_tokenId].price;
    }

    function tokensOfOwner(address _owner) public view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        uint256 total = totalSupply();
        uint256 resultIndex = 0;

        for(uint256 i = 0; i <= total; i++) {
            if (landmarkToOwner[i] == _owner) {
                result[resultIndex] = i;
                resultIndex++;
            }
        }
        return result;
    }


    function _transfer(address _from, address _to, uint256 _tokenId) private {
        landmarkOwnershipCount[_to]++;
        landmarkToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            landmarkOwnershipCount[_from]--;
            delete landmarkToApproved[_tokenId];
        }
        Transfer(_from, _to, _tokenId);
    }

    function enableCharity() external onlyOwner {
        require(!charityEnabled);
        charityEnabled = true;
    }

    function disableCharity() external onlyOwner {
        require(charityEnabled);
        charityEnabled = false;
    }

    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
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