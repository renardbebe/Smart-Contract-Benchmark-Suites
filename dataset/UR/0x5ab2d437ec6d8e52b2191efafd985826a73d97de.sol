 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}


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

contract MultiOwnable {
    using SafeMath for uint256;

    mapping(address => bool) public isOwner;
    address[] public ownerHistory;
    uint256 public ownerCount;


    event OwnerAddedEvent(address indexed _newOwner);
    event OwnerRemovedEvent(address indexed _oldOwner);

    constructor() public
    {
        address owner = msg.sender;
        setOwner(owner);
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender]);
        _;
    }

    function ownerHistoryCount() public view returns (uint) {
        return ownerHistory.length;
    }

    function addOwner(address owner) onlyOwner public {
        require(owner != address(0));
        require(!isOwner[owner]);
        setOwner(owner);
        emit OwnerAddedEvent(owner);
    }

    function removeOwner(address owner) onlyOwner public {
        require(ownerCount > 1);
        require(isOwner[owner]);
        isOwner[owner] = false;
        ownerCount = ownerCount.sub(1);
        emit OwnerRemovedEvent(owner);
    }

    function setOwner(address owner) internal {
        ownerHistory.push(owner);
        isOwner[owner] = true;
        ownerCount = ownerCount.add(1);
    }
}

contract AccessControl is RBAC, MultiOwnable {
    event AddedToWhitelist(address addr);
    event RemovedFromWhitelist(address addr);
    event AdminAddressAdded(address addr);
    event AdminAddressRemoved(address addr);

    string public constant ROLE_WHITELISTED = "whitelist";
    string public constant ROLE_ADMIN = "admin";


    constructor() public
    {
        addToAdminlist(msg.sender);
        addToWhitelist(msg.sender);
    }

     
    modifier onlyAdmin()
    {
        checkRole(msg.sender, ROLE_ADMIN);
        _;
    }

    modifier onlyFromWhitelisted() {
        checkRole(msg.sender, ROLE_WHITELISTED);
        _;
    }

    modifier onlyWhitelisted(address first)
    {
        checkRole(msg.sender, ROLE_WHITELISTED);
        checkRole(first, ROLE_WHITELISTED);
        _;
    }

    modifier onlyWhitelistedParties(address first, address second)
    {
        checkRole(msg.sender, ROLE_WHITELISTED);
        checkRole(first, ROLE_WHITELISTED);
        checkRole(second, ROLE_WHITELISTED);
        _;
    }

     

     
    function addToWhitelist(address addr)
    onlyAdmin
    public
    {
        addRole(addr, ROLE_WHITELISTED);
        emit AddedToWhitelist(addr);
    }

     
    function addManyToWhitelist(address[] addrs)
    onlyAdmin
    public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            addToWhitelist(addrs[i]);
        }
    }

     
    function removeFromWhitelist(address addr)
    onlyAdmin
    public
    {
        removeRole(addr, ROLE_WHITELISTED);
        emit RemovedFromWhitelist(addr);
    }

     
    function removeManyFromWhitelist(address[] addrs)
    onlyAdmin
    public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            removeFromWhitelist(addrs[i]);
        }
    }

     
    function whitelist(address addr)
    public
    view
    returns (bool)
    {
        return hasRole(addr, ROLE_WHITELISTED);
    }

     

     
    function addToAdminlist(address addr)
    onlyOwner
    public
    {
        addRole(addr, ROLE_ADMIN);
        emit AdminAddressAdded(addr);
    }

    function removeFromAdminlist(address addr)
    onlyOwner
    public
    {
        removeRole(addr, ROLE_ADMIN);
        emit AdminAddressRemoved(addr);
    }

     
    function admin(address addr)
    public
    view
    returns (bool)
    {
        return hasRole(addr, ROLE_ADMIN);
    }

}


contract AKJToken is BurnableToken, StandardToken, AccessControl
{
  string public constant name = "AKJ";  
  string public constant symbol = "AKJ";  
  uint8 public constant decimals = 18;  

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));  

   
  constructor() public {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
  function transfer(address _to, uint256 _value) public onlyWhitelisted(_to) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public onlyWhitelistedParties(_from, _to) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public onlyWhitelisted(_spender) returns (bool) {
    return super.approve(_spender, _value);
  }




}