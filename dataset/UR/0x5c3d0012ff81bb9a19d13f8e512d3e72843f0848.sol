 

pragma solidity ^0.4.24;

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

contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

contract SimpleFlyDropToken is Claimable {
    using SafeMath for uint256;

    ERC20 internal erc20tk;

    function setToken(address _token) onlyOwner public {
        require(_token != address(0));
        erc20tk = ERC20(_token);
    }

     
    function multiSend(address[] _destAddrs, uint256[] _values) onlyOwner public returns (uint256) {
        require(_destAddrs.length == _values.length);

        uint256 i = 0;
        for (; i < _destAddrs.length; i = i.add(1)) {
            if (!erc20tk.transfer(_destAddrs[i], _values[i])) {
                break;
            }
        }

        return (i);
    }
}

contract DelayedClaimable is Claimable {

  uint256 public end;
  uint256 public start;

   
  function setLimits(uint256 _start, uint256 _end) public onlyOwner {
    require(_start <= _end);
    end = _end;
    start = _start;
  }

   
  function claimOwnership() public onlyPendingOwner {
    require((block.number <= end) && (block.number >= start));
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
    end = 0;
  }

}

contract Poweruser is DelayedClaimable, RBAC {
  string public constant ROLE_POWERUSER = "poweruser";

  constructor () public {
    addRole(msg.sender, ROLE_POWERUSER);
  }

   
  modifier onlyPoweruser() {
    checkRole(msg.sender, ROLE_POWERUSER);
    _;
  }

  modifier onlyOwnerOrPoweruser() {
    require(msg.sender == owner || isPoweruser(msg.sender));
    _;
  }

   
  function isPoweruser(address _addr)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, ROLE_POWERUSER);
  }

   
  function addPoweruser(address _newPoweruser) public onlyOwner {
    require(_newPoweruser != address(0));
    addRole(_newPoweruser, ROLE_POWERUSER);
  }

   
  function removePoweruser(address _oldPoweruser) public onlyOwner {
    require(_oldPoweruser != address(0));
    removeRole(_oldPoweruser, ROLE_POWERUSER);
  }
}

contract FlyDropTokenMgr is Poweruser {
    using SafeMath for uint256;

    address[] dropTokenAddrs;
    SimpleFlyDropToken currentDropTokenContract;
     

     
    function prepare(uint256 _rand,
                     address _from,
                     address _token,
                     uint256 _value) onlyOwnerOrPoweruser public returns (bool) {
        require(_token != address(0));
        require(_from != address(0));
        require(_rand > 0);

        if (ERC20(_token).allowance(_from, this) < _value) {
            return false;
        }

        if (_rand > dropTokenAddrs.length) {
            SimpleFlyDropToken dropTokenContract = new SimpleFlyDropToken();
            dropTokenAddrs.push(address(dropTokenContract));
            currentDropTokenContract = dropTokenContract;
        } else {
            currentDropTokenContract = SimpleFlyDropToken(dropTokenAddrs[_rand.sub(1)]);
        }

        currentDropTokenContract.setToken(_token);
        return ERC20(_token).transferFrom(_from, currentDropTokenContract, _value);
         
         
         
    }

     
     
     

     
     

     
    function flyDrop(address[] _destAddrs, uint256[] _values) onlyOwnerOrPoweruser public returns (uint256) {
        require(address(currentDropTokenContract) != address(0));
        return currentDropTokenContract.multiSend(_destAddrs, _values);
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}