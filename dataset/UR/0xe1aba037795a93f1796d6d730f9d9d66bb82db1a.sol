 

pragma solidity 0.4.24;

 

 
 
 
contract ERC780 {
    function setClaim(address subject, bytes32 key, bytes32 value) public;
    function setSelfClaim(bytes32 key, bytes32 value) public;
    function getClaim(address issuer, address subject, bytes32 key) public view returns (bytes32);
    function removeClaim(address issuer, address subject, bytes32 key) public;
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
 
contract RBACInterface {
    function hasRole(address addr, string role) public view returns (bool);
}

 

 
 
contract RBACManaged is Ownable {

    RBACInterface public rbac;

     
    constructor(address rbacAddr) public {
        rbac = RBACInterface(rbacAddr);
    }

    function roleAdmin() internal pure returns (string);

     
     
     
     
    function hasRole(address addr, string role) public view returns (bool) {
        return rbac.hasRole(addr, role);
    }

    modifier onlyRole(string role) {
        require(hasRole(msg.sender, role), "Access denied: missing role");
        _;
    }

    modifier onlyOwnerOrAdmin() {
        require(
            msg.sender == owner || hasRole(msg.sender, roleAdmin()), "Access denied: missing role");
        _;
    }

     
     
     
    function setRBACAddress(address rbacAddr) public onlyOwnerOrAdmin {
        rbac = RBACInterface(rbacAddr);
    }
}

 

 
 
 
 
contract UserAddressAliasable is RBACManaged {

    event UserAddressAliased(address indexed oldAddr, address indexed newAddr);

    mapping(address => address) addressAlias;   

    function roleAddressAliaser() internal pure returns (string);

     
     
     
     
     
    function setAddressAlias(address oldAddr, address newAddr) public onlyRole(roleAddressAliaser()) {
        require(addressAlias[oldAddr] == address(0), "oldAddr is already aliased to another address");
        require(addressAlias[newAddr] == address(0), "newAddr is already aliased to another address");
        require(oldAddr != newAddr, "oldAddr and newAddr must be different");
        setAddressAliasUnsafe(oldAddr, newAddr);
    }

     
     
     
     
     
     
    function setAddressAliasUnsafe(address oldAddr, address newAddr) public onlyRole(roleAddressAliaser()) {
        addressAlias[newAddr] = oldAddr;
        emit UserAddressAliased(oldAddr, newAddr);
    }

     
     
     
     
    function unsetAddressAlias(address addr) public onlyRole(roleAddressAliaser()) {
        setAddressAliasUnsafe(0, addr);
    }

     
     
     
    function resolveAddress(address addr) public view returns (address) {
        address parentAddr = addressAlias[addr];
        if (parentAddr == address(0)) {
            return addr;
        } else {
            return parentAddr;
        }
    }
}

 

 
 
 
 
 
 
 
 
 
 
contract ODEMClaimsRegistry is RBACManaged, UserAddressAliasable, ERC780 {

    event ClaimSet(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        bytes32 value,
        uint updatedAt
    );
    event ClaimRemoved(
        address indexed issuer,
        address indexed subject,
        bytes32 indexed key,
        uint removedAt
    );

    string constant ROLE_ADMIN = "claims__admin";
    string constant ROLE_ISSUER = "claims__issuer";
    string constant ROLE_ADDRESS_ALIASER = "claims__address_aliaser";

    struct Claim {
        bytes uri;
        bytes32 hash;
    }

    mapping(address => mapping(bytes32 => Claim)) internal claims;   

     
    mapping(address => bool) internal hasClaims;

     
     
    constructor(address rbacAddr) RBACManaged(rbacAddr) public {}

     
     
     
     
     
    function getODEMClaim(address subject, bytes32 key) public view returns (bytes uri, bytes32 hash) {
        address resolved = resolveAddress(subject);
        return (claims[resolved][key].uri, claims[resolved][key].hash);
    }

     
     
     
     
     
     
     
    function setODEMClaim(address subject, bytes32 key, bytes uri, bytes32 hash) public onlyRole(ROLE_ISSUER) {
        address resolved = resolveAddress(subject);
        claims[resolved][key].uri = uri;
        claims[resolved][key].hash = hash;
        hasClaims[resolved] = true;
        emit ClaimSet(msg.sender, subject, key, hash, now);
    }

     
     
     
     
     
     
     
    function removeODEMClaim(address subject, bytes32 key) public {
        require(hasRole(msg.sender, ROLE_ISSUER) || msg.sender == subject, "Access denied: missing role");
        address resolved = resolveAddress(subject);
        delete claims[resolved][key];
        emit ClaimRemoved(msg.sender, subject, key, now);
    }

     
     
     
     
     
     
     
    function setAddressAlias(address oldAddr, address newAddr) public onlyRole(ROLE_ADDRESS_ALIASER) {
        require(!hasClaims[newAddr], "newAddr already has claims");
        super.setAddressAlias(oldAddr, newAddr);
    }

     
     
     
     
     
     
    function getClaim(address issuer, address subject, bytes32 key) public view returns (bytes32) {
        if (hasRole(issuer, ROLE_ISSUER)) {
            return claims[subject][key].hash;
        } else {
            return bytes32(0);
        }
    }

     
    function setClaim(address subject, bytes32 key, bytes32 value) public {
        revert();
    }

     
    function setSelfClaim(bytes32 key, bytes32 value) public {
        revert();
    }

     
     
     
     
     
     
     
     
     
     
    function removeClaim(address issuer, address subject, bytes32 key) public {
        require(hasRole(issuer, ROLE_ISSUER), "Issuer not recognized");
        removeODEMClaim(subject, key);
    }

     
    function roleAdmin() internal pure returns (string) {
        return ROLE_ADMIN;
    }

     
    function roleAddressAliaser() internal pure returns (string) {
        return ROLE_ADDRESS_ALIASER;
    }
}