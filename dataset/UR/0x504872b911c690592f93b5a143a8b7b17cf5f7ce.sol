 

pragma solidity ^0.5.4;

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string memory _role)
    public
    view
  {
    require(roles[_role].has(_operator), "_operator does not have _role");
  }

   
  function hasRole(address _operator, string memory _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string memory _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string memory _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string memory _role)
  {
    checkRole(msg.sender, _role);
    _;
  }
}

contract Whitelist is Ownable, RBAC {
  function grantPermission(address _operator, string memory _permission) public onlyOwner {
    addRole(_operator, _permission);
  }

  function revokePermission(address _operator, string memory _permission) public onlyOwner {
    removeRole(_operator, _permission);
  }

  function grantPermissionBatch(address[] memory _operators, string memory _permission) public onlyOwner {
    for (uint256 i = 0; i < _operators.length; i++) {
      addRole(_operators[i], _permission);
    }
  }

  function revokePermissionBatch(address[] memory _operators, string memory _permission) public onlyOwner {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeRole(_operators[i], _permission);
    }
  }
}