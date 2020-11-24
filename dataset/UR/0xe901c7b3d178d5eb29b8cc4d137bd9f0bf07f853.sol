 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

contract Ownable {
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract ItemBase is Ownable {
    using SafeMath for uint;

    struct Item {
        string name;
        string itemType;
        string size;
        string color;
         
        uint128 price;
    }

    uint128 MAX_ITEMS = 1;
     
    Item[] items;

     
    mapping(uint => address) public itemIndexToOwner;

     
     
    mapping (address => uint) public ownershipTokenCount;

     
     
     
    mapping (uint => address) public itemIndexToApproved;


    function getItem( uint _itemId ) public view returns(string name, string itemType, string size, string color, uint128 price) {
        Item memory _item = items[_itemId];

        name = _item.name;
        itemType = _item.itemType;
        size = _item.size;
        color = _item.color;
        price = _item.price;
    }
}

 

 
 
 
contract ERC721 {
    function totalSupply() public view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function ownerOf(uint256 _tokenId) external view returns (address);
    function approve(address _approved, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;
     

    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
}

 

contract SatoshiZero is ItemBase, ERC721 {
    string public constant name = "Satoshis Closet";
    string public constant symbol = "STCL";
    string public constant tokenName = "Tom's Shirt / The Proof of Concept";

     
    event Purchase(address owner, uint itemId);

     
     

     
     
     
    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return itemIndexToOwner[_tokenId] == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint _tokenId) internal view returns (bool) {
        return itemIndexToApproved[_tokenId] == _claimant;
    }

     
     
     
    function _approve(uint _tokenId, address _approved) internal {
        itemIndexToApproved[_tokenId] = _approved;
    }

    function balanceOf(address _owner) external view returns (uint) {
        return ownershipTokenCount[_owner];
    }

    function tokenMetadata(uint256 _tokenId) public view returns (string) {
        return 'https: 
    }

     
     
    function transfer(address _to, uint _tokenId) external {
         
        require(_to != address(0));
         
        require(_owns(msg.sender, _tokenId));
         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(address _to, uint _tokenId) external {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        emit Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _tokenId) external {
         
        require(_to != address(0));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return items.length;
    }

     
     
    function ownerOf(uint _tokenId) external view returns (address) {
        owner = itemIndexToOwner[_tokenId];
        require(owner != address(0));
    }

    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = ownershipTokenCount[_owner];

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalItems = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 itemId;

            for (itemId = 1; itemId <= totalItems; itemId++) {
                if (itemIndexToOwner[itemId] == _owner) {
                    result[resultIndex] = itemId;
                    resultIndex++;
                }
            }

            return result;
        }
    }

    function _purchase(string _name, string _type, string _size, string _color, uint128 _price) internal returns (uint) {
        Item memory _item = Item({ name: _name, itemType: _type, size: _size, color: _color, price: _price });
        uint itemId = items.push(_item);

         
        emit Purchase(msg.sender, itemId);

         
         
        _transfer(0, owner, itemId);

        return itemId;
    }

     
    function _transfer(address _from, address _to, uint _tokenId) internal {
        ownershipTokenCount[_to] = ownershipTokenCount[_to].add(1);
         
        itemIndexToOwner[_tokenId] = _to;
         
        if (_from != address(0)) {
            ownershipTokenCount[_from] = ownershipTokenCount[_from].sub(1);
             
            delete itemIndexToApproved[_tokenId];
        }
         
        emit Transfer(_from, _to, _tokenId);
    }

    function createItem( string _name, string _itemType, string _size, string _color, uint128 _price) external onlyOwner returns (uint) {
        require(MAX_ITEMS > totalSupply());

        Item memory _item = Item({
            name: _name,
            itemType: _itemType,
            size: _size,
            color: _color,
            price: _price
        });
        uint itemId = items.push(_item);

        _transfer(0, owner, itemId);

        return itemId;
    }
}