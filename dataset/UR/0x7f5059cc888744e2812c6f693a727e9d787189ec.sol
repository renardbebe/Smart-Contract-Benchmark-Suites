 

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


 

contract Ownable {
    address public owner;
    function Ownable() {
    owner = msg.sender;
    }

  modifier onlyOwner() {
    if (msg.sender == owner)
      _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) owner = newOwner;
  }

}

 
 
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


contract Avatarium is Ownable, ERC721 {


     


     
    event Birth(
        uint256 tokenId, 
        string name, 
        address owner);

     
    event TokenSold(
        uint256 tokenId, 
        uint256 oldPrice, 
        uint256 newPrice, 
        address prevOwner, 
        address winner, 
        string name);
    
    
     


     
    string public constant NAME = "Avatarium";
    string public constant SYMBOL = "ΛV";

     
    uint256 private startingPrice = 0.02 ether;
    uint256 private firstIterationLimit = 0.05 ether;
    uint256 private secondIterationLimit = 0.5 ether;

     
    address public addressCEO;
    address public addressCOO;


     


     
    mapping (uint => address) public avatarIndexToOwner;

     
    mapping (address => uint256) public ownershipTokenCount;

     
     
    mapping (uint256 => address) public avatarIndexToApproved;

     
    mapping (uint256 => uint256) private avatarIndexToPrice;


     


     
    struct Avatar {
        string name;
    }

    Avatar[] public avatars;


     


     
    modifier onlyCEO() {
        require(msg.sender == addressCEO);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == addressCOO);
        _;
    }

     
    modifier onlyCLevel() {
        require(msg.sender == addressCEO || msg.sender == addressCOO);
        _;
    }


     


    function Avatarium() public {
        addressCEO = msg.sender;
        addressCOO = msg.sender;
    }


     


     
    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));

        addressCEO = _newCEO;
    }

     
    function setCOO(address _newCOO) public onlyCEO {
        require(_newCOO != address(0));

        addressCOO = _newCOO;
    }

     
     
    function approve(address _to, uint256 _tokenId) public {
         
        require(_owns(msg.sender, _tokenId));

        avatarIndexToApproved[_tokenId] = _to;

         
        Approval(msg.sender, _to, _tokenId);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return ownershipTokenCount[_owner];
    }

     
    function createAvatar(string _name, uint256 _rank) public onlyCLevel {
        _createAvatar(_name, address(this), _rank);
    }

     
    function getAvatar(uint256 _tokenId) public view returns (
        string avatarName,
        uint256 sellingPrice,
        address owner
    ) {
        Avatar storage avatar = avatars[_tokenId];
        avatarName = avatar.name;
        sellingPrice = avatarIndexToPrice[_tokenId];
        owner = avatarIndexToOwner[_tokenId];
    }

    function implementsERC721() public pure returns (bool) {
        return true;
    }

     
    function ownerOf(uint256 _tokenId) public view returns (address owner) {
        owner = avatarIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function payout(address _to) public onlyCLevel {
        _payout(_to);
    }

     
    function purchase(uint256 _tokenId) public payable {
        address oldOwner = avatarIndexToOwner[_tokenId];
        address newOwner = msg.sender;

        uint256 sellingPrice = avatarIndexToPrice[_tokenId];

        require(oldOwner != newOwner);
        require(_addressNotNull(newOwner));
        require(msg.value == sellingPrice);

        uint256 payment = uint256(SafeMath.div(
                                  SafeMath.mul(sellingPrice, 94), 100));
        uint256 purchaseExcess = SafeMath.sub(msg.value, sellingPrice);

         
        if (sellingPrice < firstIterationLimit) {
         
            avatarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 200), 94);
        } else if (sellingPrice < secondIterationLimit) {
         
            avatarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 120), 94);
        } else {
         
            avatarIndexToPrice[_tokenId] = SafeMath.div(SafeMath.mul(sellingPrice, 115), 94);
        }

        _transfer(oldOwner, newOwner, _tokenId);

         
        if (oldOwner != address(this)) {
            oldOwner.transfer(payment);
        }

         
        
        TokenSold(
            _tokenId,
            sellingPrice,
            avatarIndexToPrice[_tokenId],
            oldOwner,
            newOwner,
            avatars[_tokenId].name);

         
        msg.sender.transfer(purchaseExcess);
    }

     
    function priceOf(uint256 _tokenId) public view returns (uint256 price) {
        return avatarIndexToPrice[_tokenId];
    }
    
     
    function takeOwnership(uint256 _tokenId) public {
        address newOwner = msg.sender;
        address oldOwner = avatarIndexToOwner[_tokenId];

         
        require(_addressNotNull(newOwner));

         
        require(_approved(newOwner, _tokenId));

        _transfer(oldOwner, newOwner, _tokenId);
    }

     
    function totalSupply() public view returns (uint256 total) {
        return avatars.length;
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

     
    function _approved(address _to, uint256 _tokenId)
    private 
    view 
    returns (bool) {
        return avatarIndexToApproved[_tokenId] == _to;
    }

     
    function _createAvatar(
        string _name,
        address _owner, 
        uint256 _rank) 
        private {
    
     
    uint256 _price;
    if (_rank == 1) {
        _price = startingPrice;
    } else if (_rank == 2) {
        _price = 2 * startingPrice;
    } else if (_rank == 3) {
        _price = SafeMath.mul(4, startingPrice);
    } else if (_rank == 4) {
        _price = SafeMath.mul(8, startingPrice);
    } else if (_rank == 5) {
        _price = SafeMath.mul(16, startingPrice);
    } else if (_rank == 6) {
        _price = SafeMath.mul(32, startingPrice);
    } else if (_rank == 7) {
        _price = SafeMath.mul(64, startingPrice);
    } else if (_rank == 8) {
        _price = SafeMath.mul(128, startingPrice);
    } else if (_rank == 9) {
        _price = SafeMath.mul(256, startingPrice);
    } 

    Avatar memory _avatar = Avatar({name: _name});

    uint256 newAvatarId = avatars.push(_avatar) - 1;

    avatarIndexToPrice[newAvatarId] = _price;

     
    Birth(newAvatarId, _name, _owner);

     
    _transfer(address(0), _owner, newAvatarId);
    }

     
    function _owns(address claimant, uint256 _tokenId) 
    private 
    view 
    returns (bool) {
        return claimant == avatarIndexToOwner[_tokenId];
    }

     
    function _payout(address _to) private {
        if (_to == address(0)) {
            addressCEO.transfer(this.balance);
        } else {
            _to.transfer(this.balance);
        }
    }

     
    function _transfer(address _from, address _to, uint256 _tokenId) private {
        ownershipTokenCount[_to]++;
        avatarIndexToOwner[_tokenId] = _to;

        if (_from != address(0)) {
            ownershipTokenCount[_from]--;
            delete avatarIndexToApproved[_tokenId];
        }

         
        Transfer(_from, _to, _tokenId);
    }
}