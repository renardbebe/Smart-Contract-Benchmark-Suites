 

 



interface KYCInterface {
  event AttributesSet(address indexed who, uint256 indexed attributes);

  function getAttribute(address addr, uint8 attribute) external view returns (bool);
}




 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = true;
  }

   
  function remove(Role storage role, address addr)
    internal
  {
    role.bearer[addr] = false;
  }

   
  function check(Role storage role, address addr)
    view
    internal
  {
    require(has(role, addr));
  }

   
  function has(Role storage role, address addr)
    view
    internal
    returns (bool)
  {
    return role.bearer[addr];
  }
}



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
  string public constant ROLE_ADMIN = "admin";

   
  function RBAC()
    public
  {
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function checkRole(address addr, string roleName)
    view
    public
  {
    roles[roleName].check(addr);
  }

   
  function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
  {
    return roles[roleName].has(addr);
  }

   
  function adminAddRole(address addr, string roleName)
    onlyAdmin
    public
  {
    addRole(addr, roleName);
  }

   
  function adminRemoveRole(address addr, string roleName)
    onlyAdmin
    public
  {
    removeRole(addr, roleName);
  }

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}


 
contract BasicKYC is RBAC, KYCInterface {
   
  mapping (bytes32 => bool) public hashes;
   
  mapping (address => uint256) public attributes;

   
  string public constant ROLE_SIGNER = "signer";
  string public constant ROLE_SETTER = "setter";

   
  function writeAttributes(address user, uint256 newAttributes) internal {
    attributes[user] = newAttributes;

    emit AttributesSet(user, attributes[user]);
  }

   
  function setAttributes(address user, uint256 newAttributes) external onlyRole(ROLE_SETTER) {
    writeAttributes(user, newAttributes);
  }

   
  function getAttribute(address user, uint8 attribute) external view returns (bool) {
    return (attributes[user] & 2**attribute) > 0;
  }

   
  function setMyAttributes(address signer, uint256 newAttributes, uint128 nonce, uint8 v, bytes32 r, bytes32 s) external {
    require(hasRole(signer, ROLE_SIGNER));

    bytes32 hash = keccak256(msg.sender, signer, newAttributes, nonce);
    require(hashes[hash] == false);
    require(ecrecover(hash, v, r, s) == signer);

    hashes[hash] = true;
    writeAttributes(msg.sender, newAttributes);
  }

}