 

 
 
 
 
 
 
 
 
 
 
 
 
 

pragma solidity ^0.4.17;

contract OwnedEvents {
    event LogSetOwner (address newOwner);
}


contract Owned is OwnedEvents {
    address public owner;

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address owner_) public onlyOwner {
        owner = owner_;
        LogSetOwner(owner);
    }

}

interface SecuredWithRolesI {
    function hasRole(string roleName) public view returns (bool);
    function senderHasRole(string roleName) public view returns (bool);
    function contractHash() public view returns (bytes32);
}


contract SecuredWithRoles is Owned {
    RolesI public roles;
    bytes32 public contractHash;
    bool public stopped = false;

    function SecuredWithRoles(string contractName_, address roles_) public {
        contractHash = keccak256(contractName_);
        roles = RolesI(roles_);
    }

    modifier stoppable() {
        require(!stopped);
        _;
    }

    modifier onlyRole(string role) {
        require(senderHasRole(role));
        _;
    }

    modifier roleOrOwner(string role) {
        require(msg.sender == owner || senderHasRole(role));
        _;
    }

     
    function hasRole(string roleName) public view returns (bool) {
        return roles.knownRoleNames(contractHash, keccak256(roleName));
    }

    function senderHasRole(string roleName) public view returns (bool) {
        return hasRole(roleName) && roles.roleList(contractHash, keccak256(roleName), msg.sender);
    }

    function stop() public roleOrOwner("stopper") {
        stopped = true;
    }

    function restart() public roleOrOwner("restarter") {
        stopped = false;
    }

    function setRolesContract(address roles_) public onlyOwner {
         
        require(this != address(roles));
        roles = RolesI(roles_);
    }

}


interface RolesI {
    function knownRoleNames(bytes32 contractHash, bytes32 nameHash) public view returns (bool);
    function roleList(bytes32 contractHash, bytes32 nameHash, address member) public view returns (bool);

    function addContractRole(bytes32 ctrct, string roleName) public;
    function removeContractRole(bytes32 ctrct, string roleName) public;
    function grantUserRole(bytes32 ctrct, string roleName, address user) public;
    function revokeUserRole(bytes32 ctrct, string roleName, address user) public;
}


contract RolesEvents {
    event LogRoleAdded(bytes32 contractHash, string roleName);
    event LogRoleRemoved(bytes32 contractHash, string roleName);
    event LogRoleGranted(bytes32 contractHash, string roleName, address user);
    event LogRoleRevoked(bytes32 contractHash, string roleName, address user);
}


contract Roles is RolesEvents, SecuredWithRoles {
     
    mapping(bytes32 => mapping (bytes32 => mapping (address => bool))) public roleList;
     
    mapping (bytes32 => mapping (bytes32 => bool)) public knownRoleNames;

    function Roles() SecuredWithRoles("RolesRepository", this) public {}

    function addContractRole(bytes32 ctrct, string roleName) public roleOrOwner("admin") {
        require(!knownRoleNames[ctrct][keccak256(roleName)]);
        knownRoleNames[ctrct][keccak256(roleName)] = true;
        LogRoleAdded(ctrct, roleName);
    }

    function removeContractRole(bytes32 ctrct, string roleName) public roleOrOwner("admin") {
        require(knownRoleNames[ctrct][keccak256(roleName)]);
        delete knownRoleNames[ctrct][keccak256(roleName)];
        LogRoleRemoved(ctrct, roleName);
    }

    function grantUserRole(bytes32 ctrct, string roleName, address user) public roleOrOwner("admin") {
        require(knownRoleNames[ctrct][keccak256(roleName)]);
        roleList[ctrct][keccak256(roleName)][user] = true;
        LogRoleGranted(ctrct, roleName, user);
    }

    function revokeUserRole(bytes32 ctrct, string roleName, address user) public roleOrOwner("admin") {
        delete roleList[ctrct][keccak256(roleName)][user];
        LogRoleRevoked(ctrct, roleName, user);
    }

}