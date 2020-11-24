 

pragma solidity 0.4.24;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
 
contract RBACInterface {
    function hasRole(address addr, string role) public view returns (bool);
}

 

 
 
contract RBAC is RBACInterface, Ownable {

    string constant ROLE_ADMIN = "rbac__admin";

    mapping(address => mapping(string => bool)) internal roles;

    event RoleAdded(address indexed addr, string role);
    event RoleRemoved(address indexed addr, string role);

     
     
     
     
    function hasRole(address addr, string role) public view returns (bool) {
        return roles[addr][role];
    }

     
     
     
     
     
    function addRole(address addr, string role) public onlyOwnerOrAdmin {
        roles[addr][role] = true;
        emit RoleAdded(addr, role);
    }

     
     
     
     
     
    function removeRole(address addr, string role) public onlyOwnerOrAdmin {
        roles[addr][role] = false;
        emit RoleRemoved(addr, role);
    }

    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || hasRole(msg.sender, ROLE_ADMIN), "Access denied: missing role");
        _;
    }
}