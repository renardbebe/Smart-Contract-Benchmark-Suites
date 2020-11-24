 

pragma solidity ^0.4.24;


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
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


 
contract PriceOracle is RBAC {
  using SafeMath for uint256;

   
  uint256 public ethPriceInCents;

   
   
  uint256 public allowedOracleChangePercent;

   
  string public constant ROLE_ADMIN = "admin";
  string public constant ROLE_ORACLE = "oracle";

   
  modifier onlyAdmin()
  {
    checkRole(msg.sender, ROLE_ADMIN);
    _;
  }

   
  modifier onlyOracle()
  {
    checkRole(msg.sender, ROLE_ORACLE);
    _;
  }

   
  constructor(
    uint256 _initialEthPriceInCents,
    uint256 _allowedOracleChangePercent
  ) public {
    ethPriceInCents = _initialEthPriceInCents;
    allowedOracleChangePercent = _allowedOracleChangePercent;
    addRole(msg.sender, ROLE_ADMIN);
  }

   
  function getUsdCentsFromWei(uint256 _wei) public view returns (uint256) {
    return _wei.mul(ethPriceInCents).div(1 ether);
  }

   
  function getWeiFromUsdCents(uint256 _usdCents)
    public view returns (uint256)
  {
    return _usdCents.mul(1 ether).div(ethPriceInCents);
  }

   
  function setEthPrice(uint256 _cents)
    public
    onlyOracle
  {
    uint256 maxCents = allowedOracleChangePercent.add(100)
    .mul(ethPriceInCents).div(100);
    uint256 minCents = SafeMath.sub(100,allowedOracleChangePercent)
    .mul(ethPriceInCents).div(100);
    require(
      _cents <= maxCents && _cents >= minCents,
      "Price out of allowed range"
    );
    ethPriceInCents = _cents;
  }

   
  function addAdmin(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_ADMIN);
  }

   
  function delAdmin(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_ADMIN);
  }

   
  function addOracle(address addr)
    public
    onlyAdmin
  {
    addRole(addr, ROLE_ORACLE);
  }

   
  function delOracle(address addr)
    public
    onlyAdmin
  {
    removeRole(addr, ROLE_ORACLE);
  }
}