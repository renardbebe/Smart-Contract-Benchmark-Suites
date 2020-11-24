 

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
contract RBACOperator is Ownable, RBAC{

   
  string public constant ROLE_OPERATOR = "operator";

   
  modifier hasOperationPermission() {
    checkRole(msg.sender, ROLE_OPERATOR);
    _;
  }

   
  function addOperater(address _operator) public onlyOwner {
    addRole(_operator, ROLE_OPERATOR);
  }

   
  function removeOperater(address _operator) public onlyOwner {
    removeRole(_operator, ROLE_OPERATOR);
  }
}


contract IncentivePoolContract is Ownable, RBACOperator{
  using SafeMath for uint256;
  uint256 public openingTime;


   
  function setOpeningTime(uint32 _newOpeningTime) public hasOperationPermission {
     require(_newOpeningTime > 0);
     openingTime = _newOpeningTime;
  }


   
  function getIncentiveNum() public view returns(uint256 yearSum, uint256 daySum, uint256 currentYear) {
    require(openingTime > 0 && openingTime < now);
    (yearSum, daySum, currentYear) = getIncentiveNumByTime(now);
  }



   
  function getIncentiveNumByTime(uint256 _time) public view returns(uint256 yearSum, uint256 daySum, uint256 currentYear) {
    require(openingTime > 0 && _time > openingTime);
    uint256 timeSpend = _time - openingTime;
    uint256 tempYear = timeSpend / 31536000;
    if (tempYear == 0) {
      yearSum = 2400000000000000000000000000;
      daySum = 6575342000000000000000000;
      currentYear = 1;
    } else if (tempYear == 1) {
      yearSum = 1080000000000000000000000000;
      daySum = 2958904000000000000000000;
      currentYear = 2;
    } else if (tempYear == 2) {
      yearSum = 504000000000000000000000000;
      daySum = 1380821000000000000000000;
      currentYear = 3;
    } else {
      uint256 year = tempYear - 3;
      uint256 d = 9 ** year;
      uint256 e = uint256(201600000000000000000000000).mul(d);
      uint256 f = 10 ** year;
      uint256 y2 = e.div(f);

      yearSum = y2;
      daySum = y2 / 365;
      currentYear = tempYear+1;
    }
  }
}