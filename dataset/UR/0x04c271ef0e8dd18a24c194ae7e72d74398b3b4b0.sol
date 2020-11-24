 

pragma solidity ^0.4.24;

 

 
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

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    require(c / a == b, "SafeMath mul failed");
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "SafeMath sub failed");
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    require(c >= a, "SafeMath add failed");
    return c;
  }

   
  function sqrt(uint256 x) internal pure returns (uint256 y) {
    uint256 z = ((add(x,1)) / 2);
    y = x;
    while (z < y)
    {
      y = z;
      z = ((add((x / z),z)) / 2);
    }
  }

   
  function sq(uint256 x) internal pure returns (uint256) {
    return (mul(x,x));
  }

   
  function pwr(uint256 x, uint256 y) internal pure returns (uint256) {
    if (x==0)
      return (0);
    else if (y==0)
      return (1);
    else
    {
      uint256 z = x;
      for (uint256 i=1; i < y; i++)
        z = mul(z,x);
      return (z);
    }
  }
}

 

 
interface ERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
}

 

contract CryptoHeroRocket is Ownable, RBAC {
  using SafeMath for uint256;

  event Transfer(address indexed from, address indexed to, uint256 amount);
  event Approval(address indexed owner, address indexed spender, uint256 amount);
  event Mint(address indexed to, uint256 amount);
  event Burn(address indexed from, uint256 amount);

   
  string internal constant ROLE_MINTER = "minter";
  string internal constant ROLE_BURNER = "burner";

  string public name = 'Crypto Hero Rocket';
  string public symbol = 'CH 🚀';
  uint8 public decimals;  

  uint256 public totalSupply;
  mapping(address => uint256) internal balances;
  mapping (address => mapping (address => uint256)) internal allowed;

  constructor() public {
    addRole(msg.sender, ROLE_MINTER);
    addRole(msg.sender, ROLE_BURNER);
  }

   
  function() external {}


   
  function transfer(address _to, uint256 _value) public returns (bool) {
     
     
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     
 
 
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function increaseApproval(address _spender, uint256 _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint256 _subtractedValue) public returns (bool) {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }



   
  function addMinter(address _minter) external onlyOwner {
    addRole(_minter, ROLE_MINTER);
  }

  function addBurner(address _burner) external onlyOwner {
    addRole(_burner, ROLE_BURNER);
  }

   
  function removeMinter(address _minter) external onlyOwner {
    removeRole(_minter, ROLE_MINTER);
  }

  function removeBurner(address _burner) external onlyOwner {
    removeRole(_burner, ROLE_BURNER);
  }


   
  function mint(address _to, uint256 _amount) external onlyRole(ROLE_MINTER) returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function burn(address _from, uint256 _amount) external onlyRole(ROLE_BURNER) returns (bool) {
     
 

    balances[_from] = balances[_from].sub(_amount);
    totalSupply = totalSupply.sub(_amount);
    emit Burn(_from, _amount);
    emit Transfer(_from, address(0), _amount);
    return true;
  }

   
   
   
   

  function claimTokens(address _token) external onlyOwner {
    if (_token == 0x0) {
      owner.transfer(address(this).balance);
      return;
    }

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
  }

}