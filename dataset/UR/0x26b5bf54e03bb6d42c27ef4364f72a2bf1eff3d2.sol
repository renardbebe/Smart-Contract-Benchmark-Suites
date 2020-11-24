 

pragma solidity ^0.4.19;

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


contract CryptoBeauty is AccessControl, ERC721 {
     
    event Creation(uint256 tokenId, string name, address owner);

     
    event Purchase(uint256 tokenId, uint256 oldPrice, uint256 newPrice, address prevOwner, address owner, uint256 charityId);

     
    event PriceChange(uint256 tokenId, uint256 price);

     
    event Charity(uint256 charityId, address charity);

    string public constant NAME = "Crypto Beauty"; 
    string public constant SYMBOL = "BEAUTY"; 

     
    uint256 private startingPrice = 0.005 ether;
    uint256 private increaseLimit1 = 0.5 ether;
    uint256 private increaseLimit2 = 50.0  ether;
    uint256 private increaseLimit3 = 100.0  ether;

     
    bool charityEnabled;

     
    struct Beauty {
         
        string name;

         
        uint256 price;

         
        uint256 maxPrice;
    }

    Beauty[] public beauties;

    address[] public charities;
    
    mapping (uint256 => address) public beautyToOwner;
    mapping (address => uint256) public beautyOwnershipCount;
    mapping (uint256 => address) public beautyToApproved;

    function CryptoBeauty() public {
        owner = msg.sender;
        admins.push(msg.sender);
        charityEnabled = false;
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

    function totalSupply() public view returns (uint256) {
        return beauties.length;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return beautyOwnershipCount[_owner];
    }
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = beautyToOwner[_tokenId];
        require(owner != address(0));
    }

    function transfer(address _to, uint256 _tokenId) public {
        require(_to != address(0));
        require(beautyToOwner[_tokenId] == msg.sender);

        _transfer(msg.sender, _to, _tokenId);
    }
    function approve(address _to, uint256 _tokenId) public {
        require(beautyToOwner[_tokenId] == msg.sender);
        beautyToApproved[_tokenId] = _to;
        Approval(msg.sender, _to, _tokenId);
    }
    function transferFrom(address _from, address _to, uint256 _tokenId) public {
        require(beautyToApproved[_tokenId] == _to);
        require(_to != address(0));
        require(beautyToOwner[_tokenId] == _from);

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

    function createBeauty(string _name, address _owner, uint256 _price) public onlyAdmins {
        if (_price <= 0.005 ether) {
            _price = startingPrice;
        }
        
        Beauty memory _beauty = Beauty({
            name: _name,
            price: _price,
            maxPrice: _price
        });
        uint256 newBeautyId = beauties.push(_beauty) - 1;

        Creation(newBeautyId, _name, _owner);

        _transfer(address(0), _owner, newBeautyId);


    }
    
    function newBeauty(string _name, uint256 _price) public onlyAdmins {
        createBeauty(_name, msg.sender, _price);
    }

    function getBeauty(uint256 _tokenId) public view returns (
        string beautyName,
        uint256 sellingPrice,
        uint256 maxPrice,
        address owner
    ) {
        Beauty storage beauty = beauties[_tokenId];
        beautyName = beauty.name;
        sellingPrice = beauty.price;
        maxPrice = beauty.maxPrice;
        owner = beautyToOwner[_tokenId];
    }


    function purchase(uint256 _tokenId, uint256 _charityId) public payable {
         
        address oldOwner = beautyToOwner[_tokenId];
         
        uint sellingPrice = beauties[_tokenId].price;
         
        address newOwner = msg.sender;
        
        require(oldOwner != newOwner);
        require(newOwner != address(0));
        require(msg.value >= sellingPrice);
        
        uint256 devCut;
        uint256 nextPrice;

        if (sellingPrice < increaseLimit1) {
          devCut = SafeMath.div(SafeMath.mul(sellingPrice, 5), 100);  
          nextPrice = SafeMath.div(SafeMath.mul(sellingPrice, 200), 95);
        } else if (sellingPrice < increaseLimit2) {
          devCut = SafeMath.div(SafeMath.mul(sellingPrice, 4), 100);  
          nextPrice = SafeMath.div(SafeMath.mul(sellingPrice, 135), 96);
        } else if (sellingPrice < increaseLimit3) {
          devCut = SafeMath.div(SafeMath.mul(sellingPrice, 3), 100);  
          nextPrice = SafeMath.div(SafeMath.mul(sellingPrice, 125), 97);
        } else {
          devCut = SafeMath.div(SafeMath.mul(sellingPrice, 2), 100);  
          nextPrice = SafeMath.div(SafeMath.mul(sellingPrice, 115), 98);
        }

        uint256 excess = SafeMath.sub(msg.value, sellingPrice);

        if (charityEnabled == true) {
            
             
            address charity = charities[_charityId];

             
            require(charity != address(0));
            
             
            uint256 donate = uint256(SafeMath.div(SafeMath.mul(sellingPrice, 1), 100));

             
            charity.transfer(donate);
            
        }

         
        beauties[_tokenId].price = nextPrice;
        
         
        beauties[_tokenId].maxPrice = nextPrice;

         
        _transfer(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(SafeMath.sub(sellingPrice, devCut));
        }

         
        Purchase(_tokenId, sellingPrice, beauties[_tokenId].price, oldOwner, newOwner, _charityId);
        
         
        if (excess > 0) {
            newOwner.transfer(excess);
        }  
    }

     
    function changePrice(uint256 _tokenId, uint256 _price) public {
         
        require(beautyToOwner[_tokenId] == msg.sender);

         
        require(beauties[_tokenId].maxPrice >= _price);

         
        beauties[_tokenId].price = _price;
        
         
        PriceChange(_tokenId, _price);
    }

    function priceOfBeauty(uint256 _tokenId) public view returns (uint256) {
        return beauties[_tokenId].price;
    }

    function tokensOfOwner(address _owner) public view returns(uint256[]) {
        uint256 tokenCount = balanceOf(_owner);

        uint256[] memory result = new uint256[](tokenCount);
        uint256 total = totalSupply();
        uint256 resultIndex = 0;

        for(uint256 i = 0; i <= total; i++) {
            if (beautyToOwner[i] == _owner) {
                result[resultIndex] = i;
                resultIndex++;
            }
        }
        return result;
    }


    function _transfer(address _from, address _to, uint256 _tokenId) private {
        beautyOwnershipCount[_to]++;
        beautyToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            beautyOwnershipCount[_from]--;
            delete beautyToApproved[_tokenId];
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

    function withdrawAll() external onlyAdmins {
        msg.sender.transfer(this.balance);
    }

    function withdrawAmount(uint256 _amount) external onlyAdmins {
        msg.sender.transfer(_amount);
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