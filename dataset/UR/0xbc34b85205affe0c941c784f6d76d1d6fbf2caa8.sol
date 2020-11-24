 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public ownerAddress;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    ownerAddress = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == ownerAddress);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(ownerAddress, newOwner);
    ownerAddress = newOwner;
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

 
library SafeMath32 {

  function mul(uint32 a, uint32 b) internal pure returns (uint32) {
    if (a == 0) {
      return 0;
    }
    uint32 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint32 a, uint32 b) internal pure returns (uint32) {
     
    uint32 c = a / b;
     
    return c;
  }

  function sub(uint32 a, uint32 b) internal pure returns (uint32) {
    assert(b <= a);
    return a - b;
  }

  function add(uint32 a, uint32 b) internal pure returns (uint32) {
    uint32 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
library SafeMath16 {

  function mul(uint16 a, uint16 b) internal pure returns (uint16) {
    if (a == 0) {
      return 0;
    }
    uint16 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint16 a, uint16 b) internal pure returns (uint16) {
     
    uint16 c = a / b;
     
    return c;
  }

  function sub(uint16 a, uint16 b) internal pure returns (uint16) {
    assert(b <= a);
    return a - b;
  }

  function add(uint16 a, uint16 b) internal pure returns (uint16) {
    uint16 c = a + b;
    assert(c >= a);
    return c;
  }
}



contract ERC721 {
  event Transfer(address indexed _from, address indexed _to, uint256 _tokenId);
  event Approval(address indexed _owner, address indexed _approved, uint256 _tokenId);

  function balanceOf(address _owner) public view returns (uint256 _balance);
  function ownerOf(uint256 _tokenId) public view returns (address _owner);
  function transfer(address _to, uint256 _tokenId) public;
  function approve(address _to, uint256 _tokenId) public;
  function takeOwnership(uint256 _tokenId) public;
}


contract Solethium is Ownable, ERC721 {

    uint16 private devCutPromille = 25;

     
    event EventSolethiumObjectCreated(uint256 tokenId, string name);
    event EventSolethiumObjectBought(address oldOwner, address newOwner, uint price);

     
    using SafeMath for uint256;  
    using SafeMath for uint32;  
    using SafeMath for uint16;  

     
    struct CrySolObject {
        string name;
        uint256 price;
        uint256 id;
        uint16 parentID;
        uint16 percentWhenParent;
        address owner;
        uint8 specialPropertyType;  
        uint8 specialPropertyValue;  
    }
    

     
    CrySolObject[] public crySolObjects;
     
    uint16 public numberOfCrySolObjects;
     
    uint256 public ETHOfCrySolObjects;

    mapping (address => uint) public ownerCrySolObjectsCount;  
    mapping (address => uint) public ownerAddPercentToParent;  
    mapping (address => string) public ownerToNickname;  


     
    modifier onlyOwnerOf(uint _id) {
        require(msg.sender == crySolObjects[_id].owner);
        _;
    } 

     

    uint256 private nextPriceTreshold1 = 0.05 ether;
    uint256 private nextPriceTreshold2 = 0.3 ether;
    uint256 private nextPriceTreshold3 = 1.0 ether;
    uint256 private nextPriceTreshold4 = 5.0 ether;
    uint256 private nextPriceTreshold5 = 10.0 ether;

    function calculateNextPrice (uint256 _price) public view returns (uint256 _nextPrice) {
        if (_price <= nextPriceTreshold1) {
            return _price.mul(200).div(100);
        } else if (_price <= nextPriceTreshold2) {
            return _price.mul(170).div(100);
        } else if (_price <= nextPriceTreshold3) {
            return _price.mul(150).div(100);
        } else if (_price <= nextPriceTreshold4) {
            return _price.mul(140).div(100);
        } else if (_price <= nextPriceTreshold5) {
            return _price.mul(130).div(100);
        } else {
            return _price.mul(120).div(100);
        }
    }



     
    function createCrySolObject(string _name, uint _price, uint16 _parentID, uint16 _percentWhenParent, uint8 _specialPropertyType, uint8 _specialPropertyValue) external onlyOwner() {
        uint256 _id = crySolObjects.length;
        crySolObjects.push(CrySolObject(_name, _price, _id, _parentID, _percentWhenParent, msg.sender, _specialPropertyType, _specialPropertyValue)) ;  
        ownerCrySolObjectsCount[msg.sender] = ownerCrySolObjectsCount[msg.sender].add(1);  
        numberOfCrySolObjects = (uint16)(numberOfCrySolObjects.add(1));  
        ETHOfCrySolObjects = ETHOfCrySolObjects.add(_price);  
        EventSolethiumObjectCreated(_id, _name);

    }

     
    function getCrySolObjectsByOwner(address _owner) external view returns(uint[]) {
        uint256 tokenCount = ownerCrySolObjectsCount[_owner];
        if (tokenCount == 0) {
            return new uint256[](0);
        } else {
            uint[] memory result = new uint[](tokenCount);
            uint counter = 0;
            for (uint i = 0; i < numberOfCrySolObjects; i++) {
            if (crySolObjects[i].owner == _owner) {
                    result[counter] = i;
                    counter++;
                }
            }
            return result;
        }
    }


     
    function getAllCrySolObjects() external view returns(uint[]) {
        uint[] memory result = new uint[](numberOfCrySolObjects);
        uint counter = 0;
        for (uint i = 0; i < numberOfCrySolObjects; i++) {
                result[counter] = i;
                counter++;
        }
        return result;
    }
    
     
    function returnDevelopersCut(uint256 _price) private view returns(uint) {
            return _price.mul(devCutPromille).div(1000);
    }

     
    function returnParentObjectCut( CrySolObject storage _obj, uint256 _price ) private view returns(uint) {
        uint256 _percentWhenParent = crySolObjects[_obj.parentID].percentWhenParent + (ownerAddPercentToParent[crySolObjects[_obj.parentID].owner]).div(10);
        return _price.mul(_percentWhenParent).div(100);  
    }

    
      
    function _transferOwnershipOnBuy(address _oldOwner, uint _id, address _newOwner) private {
             
            ownerCrySolObjectsCount[_oldOwner] = ownerCrySolObjectsCount[_oldOwner].sub(1); 

             
            crySolObjects[_id].owner = _newOwner;  
            ownerCrySolObjectsCount[_newOwner] = ownerCrySolObjectsCount[_newOwner].add(1);  

            ETHOfCrySolObjects = ETHOfCrySolObjects.sub(crySolObjects[_id].price);
            crySolObjects[_id].price = calculateNextPrice(crySolObjects[_id].price);  
            ETHOfCrySolObjects = ETHOfCrySolObjects.add(crySolObjects[_id].price);
    }
    



     
    function buyCrySolObject(uint _id) external payable {

            CrySolObject storage _obj = crySolObjects[_id];
            uint256 price = _obj.price;
            address oldOwner = _obj.owner;  
            address newOwner = msg.sender;  

            require(msg.value >= price);
            require(msg.sender != _obj.owner);  

            uint256 excess = msg.value.sub(price);
            
             
            crySolObjects[_obj.parentID].owner.transfer(returnParentObjectCut(_obj, price));

             
             uint256 _oldOwnerCut = 0;
            _oldOwnerCut = price.sub(returnDevelopersCut(price));
            _oldOwnerCut = _oldOwnerCut.sub(returnParentObjectCut(_obj, price));
            oldOwner.transfer(_oldOwnerCut);

             
            if (excess > 0) {
                newOwner.transfer(excess);
            }

             
             
            if (_obj.specialPropertyType == 1) {
                if (oldOwner != ownerAddress) {
                    ownerAddPercentToParent[oldOwner] = ownerAddPercentToParent[oldOwner].sub(_obj.specialPropertyValue);
                }
                ownerAddPercentToParent[newOwner] = ownerAddPercentToParent[newOwner].add(_obj.specialPropertyValue);
            } 

            _transferOwnershipOnBuy(oldOwner, _id, newOwner);
            
             
            EventSolethiumObjectBought(oldOwner, newOwner, price);

    }


     
    function setOwnerNickName(address _owner, string _nickName) external {
        require(msg.sender == _owner);
        ownerToNickname[_owner] = _nickName;  
    }

     
    function getOwnerNickName(address _owner) external view returns(string) {
        return ownerToNickname[_owner];
    }

     
    function getContractOwner() external view returns(address) {
        return ownerAddress; 
    }
    function getBalance() external view returns(uint) {
        return this.balance;
    }
    function getNumberOfCrySolObjects() external view returns(uint16) {
        return numberOfCrySolObjects;
    }


     
    function withdrawAll() onlyOwner() public {
        ownerAddress.transfer(this.balance);
    }
    function withdrawAmount(uint256 _amount) onlyOwner() public {
        ownerAddress.transfer(_amount);
    }


     
    function setParentID (uint _crySolObjectID, uint16 _parentID) external onlyOwner() {
        crySolObjects[_crySolObjectID].parentID = _parentID;
    }


    

     mapping (uint => address) crySolObjectsApprovals;

    event Transfer(address indexed _from, address indexed _to, uint256 _id);
    event Approval(address indexed _owner, address indexed _approved, uint256 _id);

    function name() public pure returns (string _name) {
        return "Solethium";
    }

    function symbol() public pure returns (string _symbol) {
        return "SOL";
    }

    function totalSupply() public view returns (uint256 _totalSupply) {
        return crySolObjects.length;
    } 

    function balanceOf(address _owner) public view returns (uint256 _balance) {
        return ownerCrySolObjectsCount[_owner];
    }

    function ownerOf(uint256 _id) public view returns (address _owner) {
        return crySolObjects[_id].owner;
    }

    function _transferHelper(address _from, address _to, uint256 _id) private {
        ownerCrySolObjectsCount[_to] = ownerCrySolObjectsCount[_to].add(1);
        ownerCrySolObjectsCount[_from] = ownerCrySolObjectsCount[_from].sub(1);
        crySolObjects[_id].owner = _to;
        Transfer(_from, _to, _id);  
    }

      function transfer(address _to, uint256 _id) public onlyOwnerOf(_id) {
        _transferHelper(msg.sender, _to, _id);
    }

    function approve(address _to, uint256 _id) public onlyOwnerOf(_id) {
        require(msg.sender != _to);
        crySolObjectsApprovals[_id] = _to;
        Approval(msg.sender, _to, _id);  
    }

    function takeOwnership(uint256 _id) public {
        require(crySolObjectsApprovals[_id] == msg.sender);
        _transferHelper(ownerOf(_id), msg.sender, _id);
    }

   


}