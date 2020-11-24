 

pragma solidity ^0.4.21;

 

 
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
 
 

contract MainFabric is Ownable {

    using SafeMath for uint256;

    struct Contract {
        address addr;
        address owner;
        address fabric;
        string contractType;
        uint256 index;
    }

    struct Fabric {
        address addr;
        address owner;
        bool isActive;
        uint256 index;
    }

    struct Admin {
        address addr;
        address[] contratcs;
        uint256 numContratcs;
        uint256 index;
    }

     
     
    mapping(address => Contract) public contracts;

     
    address[] public contractsAddr;

     
    function numContracts() public view returns (uint256)
    { return contractsAddr.length; }


     
     
    mapping(address => Admin) public admins;

     
    address[] public adminsAddr;

     
    function numAdmins() public view returns (uint256)
    { return adminsAddr.length; }

    function getAdminContract(address _adminAddress, uint256 _index) public view returns (
        address
    ) {
        return (
            admins[_adminAddress].contratcs[_index]
        );
    }

     
     
    mapping(address => Fabric) public fabrics;

     
    address[] public fabricsAddr;

     
    function numFabrics() public view returns (uint256)
    { return fabricsAddr.length; }

     
    modifier onlyFabric() {
        require(fabrics[msg.sender].isActive);
        _;
    }

     

    function MainFabric() public {

    }

     
    function addFabric(
        address _address
    )
    public
    onlyOwner
    returns (bool)
    {
        fabrics[_address].addr = _address;
        fabrics[_address].owner = msg.sender;
        fabrics[_address].isActive = true;
        fabrics[_address].index = fabricsAddr.push(_address) - 1;

        return true;
    }

     
    function removeFabric(
        address _address
    )
    public
    onlyOwner
    returns (bool)
    {
        require(fabrics[_address].isActive);
        fabrics[_address].isActive = false;

        uint rowToDelete = fabrics[_address].index;
        address keyToMove   = fabricsAddr[fabricsAddr.length-1];
        fabricsAddr[rowToDelete] = keyToMove;
        fabrics[keyToMove].index = rowToDelete;
        fabricsAddr.length--;

        return true;
    }

     
    function addContract(
        address _address,
        address _owner,
        string _contractType
    )
    public
    onlyFabric
    returns (bool)
    {
        contracts[_address].addr = _address;
        contracts[_address].owner = _owner;
        contracts[_address].fabric = msg.sender;
        contracts[_address].contractType = _contractType;
        contracts[_address].index = contractsAddr.push(_address) - 1;

        if (admins[_owner].addr != _owner) {
            admins[_owner].addr = _owner;
            admins[_owner].index = adminsAddr.push(_owner) - 1;
        }

        admins[_owner].contratcs.push(contracts[_address].addr);
        admins[_owner].numContratcs++;

        return true;
    }
}