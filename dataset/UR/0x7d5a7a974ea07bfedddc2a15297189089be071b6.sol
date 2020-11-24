 

pragma solidity 0.4.18;

 

 
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

 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract BurnableToken is BasicToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

contract Purpose is StandardToken, BurnableToken, RBAC {
  string public constant name = "Purpose";
  string public constant symbol = "PRPS";
  uint8 public constant decimals = 18;
  string constant public ROLE_BURN = "burn";
  string constant public ROLE_TRANSFER = "transfer";
  address public supplier;

  function Purpose(address _supplier) public {
    supplier = _supplier;
    totalSupply = 1000000000 ether;
    balances[supplier] = totalSupply;
  }
  
   
  function supplyBurn(uint256 _value) external onlyRole(ROLE_BURN) returns (bool) {
    require(_value > 0);

     
    balances[supplier] = balances[supplier].sub(_value);
    totalSupply = totalSupply.sub(_value);

     
    Burn(supplier, _value);

    return true;
  }

   
  function hodlerTransfer(address _from, uint256 _value) external onlyRole(ROLE_TRANSFER) returns (bool) {
    require(_from != address(0));
    require(_value > 0);

     
    address _hodler = msg.sender;

     
    balances[_from] = balances[_from].sub(_value);
    balances[_hodler] = balances[_hodler].add(_value);

     
    Transfer(_from, _hodler, _value);

    return true;
  }
}

 

contract Burner {
  using SafeMath for uint256;

  Purpose public purpose;
  address public supplier;
  uint256 public start;
  uint256 public lastBurn;
  uint256 public burnPerweiYearly;
  uint256 constant public MAXPERWEI = 1 ether;

  function Burner (address _purpose, address _supplier, uint256 _start, uint256 _burnPerweiYearly) public {
    require(_purpose != address(0));
    require(_supplier != address(0));
    require(_start > 0 && _start < now.add(1 days));
    require(_burnPerweiYearly > 0 && _burnPerweiYearly <= MAXPERWEI);

    purpose = Purpose(_purpose);
    supplier = _supplier;
    start = _start;
    lastBurn = _start;
    burnPerweiYearly = _burnPerweiYearly;
  }
  
  function burn () external {
     
    uint256 amount = burnable();
    require(amount > 0);

     
    lastBurn = now;

     
    assert(purpose.supplyBurn(amount));
  }

  function burnable () public view returns (uint256) {
     
    uint256 secsPassed = now.sub(lastBurn);
     
    uint256 perweiToBurn = secsPassed.mul(burnPerweiYearly).div(1 years);

     
    uint256 balance = purpose.balanceOf(supplier);
     
    uint256 amount = balance.mul(perweiToBurn).div(MAXPERWEI);

     
    if (amount > balance) return balance;
    return amount;
  }
}