 

pragma solidity ^0.4.24;

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
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

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address addr, string roleName);
  event RoleRemoved(address addr, string roleName);

   
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

   
  function addRole(address addr, string roleName)
    internal
  {
    roles[roleName].add(addr);
    emit RoleAdded(addr, roleName);
  }

   
  function removeRole(address addr, string roleName)
    internal
  {
    roles[roleName].remove(addr);
    emit RoleRemoved(addr, roleName);
  }

   
  modifier onlyRole(string roleName)
  {
    checkRole(msg.sender, roleName);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

contract SaleWhitelist is Ownable, RBAC {
    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    string public constant ROLE_CONTROLLER = "controller";
    string public constant ROLE_WHITELISTED = "whitelist";

    Whitelist public list;

     
    constructor(address whitelist) public {
        require(whitelist != address(0));
        list = Whitelist(whitelist);
    }

     
    function setWhitelist(address addr)
        onlyOwner
        public
    {
        list = Whitelist(addr);
    }

     
    function addController(address addr)
        onlyOwner
        public
    {
        addRole(addr, ROLE_CONTROLLER);
    }

    function removeController(address addr)
        onlyOwner
        public
    {
        removeRole(addr, ROLE_CONTROLLER);
    }

     
    function whitelist(address addr)
        public
        view
        returns (bool)
    {
        return (hasRole(addr, ROLE_WHITELISTED) || list.whitelist(addr));
    }

    function addAddressToWhitelist(address addr)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        addRole(addr, ROLE_WHITELISTED);
        emit WhitelistedAddressAdded(addr);
    }

    function addAddressesToWhitelist(address[] addrs)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addAddressToWhitelist(addrs[i]);
        }
    }

    function removeAddressFromWhitelist(address addr)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        removeRole(addr, ROLE_WHITELISTED);
        emit WhitelistedAddressRemoved(addr);
    }

    function removeAddressesFromWhitelist(address[] addrs)
        onlyRole(ROLE_CONTROLLER)
        public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            removeAddressFromWhitelist(addrs[i]);
        }
    }
}

contract Whitelist is Ownable, RBAC {
  event WhitelistedAddressAdded(address addr);
  event WhitelistedAddressRemoved(address addr);

  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyWhitelisted() {
    checkRole(msg.sender, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address addr)
    onlyOwner
    public
  {
    addRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressAdded(addr);
  }

   
  function whitelist(address addr)
    public
    view
    returns (bool)
  {
    return hasRole(addr, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeAddressFromWhitelist(address addr)
    onlyOwner
    public
  {
    removeRole(addr, ROLE_WHITELISTED);
    emit WhitelistedAddressRemoved(addr);
  }

   
  function removeAddressesFromWhitelist(address[] addrs)
    onlyOwner
    public
  {
    for (uint256 i = 0; i < addrs.length; i++) {
      removeAddressFromWhitelist(addrs[i]);
    }
  }

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