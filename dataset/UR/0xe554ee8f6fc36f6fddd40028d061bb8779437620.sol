 

pragma solidity ^0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 

 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

contract Contributions is RBAC, Ownable {
  using SafeMath for uint256;

  uint256 private constant TIER_DELETED = 999;
  string public constant ROLE_MINTER = "minter";
  string public constant ROLE_OPERATOR = "operator";

  uint256 public tierLimit;

  modifier onlyMinter () {
    checkRole(msg.sender, ROLE_MINTER);
    _;
  }

  modifier onlyOperator () {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }

  uint256 public totalSoldTokens;
  mapping(address => uint256) public tokenBalances;
  mapping(address => uint256) public ethContributions;
  mapping(address => uint256) private _whitelistTier;
  address[] public tokenAddresses;
  address[] public ethAddresses;
  address[] private whitelistAddresses;

  constructor(uint256 _tierLimit) public {
    addRole(owner, ROLE_OPERATOR);
    tierLimit = _tierLimit;
  }

  function addMinter(address minter) external onlyOwner {
    addRole(minter, ROLE_MINTER);
  }

  function removeMinter(address minter) external onlyOwner {
    removeRole(minter, ROLE_MINTER);
  }

  function addOperator(address _operator) external onlyOwner {
    addRole(_operator, ROLE_OPERATOR);
  }

  function removeOperator(address _operator) external onlyOwner {
    removeRole(_operator, ROLE_OPERATOR);
  }

  function addTokenBalance(
    address _address,
    uint256 _tokenAmount
  )
    external
    onlyMinter
  {
    if (tokenBalances[_address] == 0) {
      tokenAddresses.push(_address);
    }
    tokenBalances[_address] = tokenBalances[_address].add(_tokenAmount);
    totalSoldTokens = totalSoldTokens.add(_tokenAmount);
  }

  function addEthContribution(
    address _address,
    uint256 _weiAmount
  )
    external
    onlyMinter
  {
    if (ethContributions[_address] == 0) {
      ethAddresses.push(_address);
    }
    ethContributions[_address] = ethContributions[_address].add(_weiAmount);
  }

  function setTierLimit(uint256 _newTierLimit) external onlyOperator {
    require(_newTierLimit > 0, "Tier must be greater than zero");

    tierLimit = _newTierLimit;
  }

  function addToWhitelist(
    address _investor,
    uint256 _tier
  )
    external
    onlyOperator
  {
    require(_tier == 1 || _tier == 2, "Only two tier level available");
    if (_whitelistTier[_investor] == 0) {
      whitelistAddresses.push(_investor);
    }
    _whitelistTier[_investor] = _tier;
  }

  function removeFromWhitelist(address _investor) external onlyOperator {
    _whitelistTier[_investor] = TIER_DELETED;
  }

  function whitelistTier(address _investor) external view returns (uint256) {
    return _whitelistTier[_investor] <= 2 ? _whitelistTier[_investor] : 0;
  }

  function getWhitelistedAddresses(
    uint256 _tier
  )
    external
    view
    returns (address[])
  {
    address[] memory tmp = new address[](whitelistAddresses.length);

    uint y = 0;
    if (_tier == 1 || _tier == 2) {
      uint len = whitelistAddresses.length;
      for (uint i = 0; i < len; i++) {
        if (_whitelistTier[whitelistAddresses[i]] == _tier) {
          tmp[y] = whitelistAddresses[i];
          y++;
        }
      }
    }

    address[] memory toReturn = new address[](y);

    for (uint k = 0; k < y; k++) {
      toReturn[k] = tmp[k];
    }

    return toReturn;
  }

  function isAllowedPurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    external
    view
    returns (bool)
  {
    if (_whitelistTier[_beneficiary] == 2) {
      return true;
    } else if (_whitelistTier[_beneficiary] == 1 && ethContributions[_beneficiary].add(_weiAmount) <= tierLimit) {
      return true;
    }

    return false;
  }

  function getTokenAddressesLength() external view returns (uint) {
    return tokenAddresses.length;
  }

  function getEthAddressesLength() external view returns (uint) {
    return ethAddresses.length;
  }
}