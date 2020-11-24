 

pragma solidity ^0.4.21;

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




contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}






contract AccessControl {
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



 
contract Ownable {
  address public owner;


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

}








contract AccessControlManager is AccessControl {

    string public constant SUPER_ADMIN = "superAdmin";
    string public constant LIMITED_ADMIN = "limitedAdmin";

     
    modifier onlyAdmin()
    {
        checkRole(msg.sender, SUPER_ADMIN);
        _;
    }

     
    modifier canUpdateRole(string role){
        if ((keccak256(abi.encodePacked(role)) != keccak256(abi.encodePacked(SUPER_ADMIN)) && (hasRole(msg.sender, SUPER_ADMIN) || hasRole(msg.sender, LIMITED_ADMIN))))
        _;
    }

     
    constructor()
    public
    {
        addRole(msg.sender, SUPER_ADMIN);
    }

     
    function addAdmin(address addr)
    onlyAdmin
    public
    {
        addRole(addr, SUPER_ADMIN);
    }

     
    function removeAdmin(address addr)
    onlyAdmin
    public
    {
        require(msg.sender != addr);
        removeRole(addr, SUPER_ADMIN);
    }

     
    function adminAddRole(address addr, string roleName)
    canUpdateRole(roleName)
    public
    {
        addRole(addr, roleName);
    }


     
    function adminRemoveRole(address addr, string roleName)
    canUpdateRole(roleName)
    public
    {
        removeRole(addr, roleName);
    }


     
    function adminAddRoles(address[] addrs, string roleName)
    public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            adminAddRole(addrs[i],roleName);
        }
    }


     
    function adminRemoveRoles(address[] addrs, string roleName)
    public
    {
        for (uint256 i = 0; i < addrs.length; i++) {
            adminRemoveRole(addrs[i],roleName);
        }
    }


}



contract AccessControlClient {


    AccessControlManager public acm;


    constructor(AccessControlManager addr) public {
        acm = AccessControlManager(addr);
    }

     
    function addRole(address addr, string roleName)
    public
    {
        acm.adminAddRole(addr,roleName);
    }


     
    function removeRole(address addr, string roleName)
    public
    {
        acm.adminRemoveRole(addr,roleName);
    }

     
    function addRoles(address[] addrs, string roleName)
    public
    {
        acm.adminAddRoles(addrs,roleName);

    }


     
    function removeRoles(address[] addrs, string roleName)
    public
    {
        acm.adminRemoveRoles(addrs,roleName);
    }

     
    function checkRole(address addr, string roleName)
    view
    public
    {
        acm.checkRole(addr, roleName);
    }

     
    function hasRole(address addr, string roleName)
    view
    public
    returns (bool)
    {
        return acm.hasRole(addr, roleName);
    }


}












contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



contract DetailedERC20 is ERC20 {
    string public name;

    string public symbol;

    uint8 public decimals;

constructor (string _name, string _symbol, uint8 _decimals) public {
name = _name;
symbol = _symbol;
decimals = _decimals;
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




contract MintableToken is StandardToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();


  modifier canMint() {
    _;
  }

  modifier canReceive(address addr) {
    _;
  }

   
  function mint(address _to, uint256 _amount) canMint canReceive(_to) public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }


}




contract CaratToken is MintableToken, BurnableToken, DetailedERC20, AccessControlClient {


    string public constant SUPER_ADMIN = "superAdmin";

    string public constant LIMITED_ADMIN = "limitedAdmin";

    string public constant KYC_ROLE = "KycEnabled";


     
    string public constant NAME = "Carats Token";

    string public constant SYMBOL = "CARAT";

    uint8 public constant DECIMALS = 18;



     
    modifier canMint() {
        require(_isMinter(msg.sender));
        _;
    }


     
    modifier canReceive(address addr) {
        if(hasRole(addr, KYC_ROLE) || hasRole(addr, LIMITED_ADMIN) || hasRole(addr, SUPER_ADMIN)){
            _;
        }
    }


    constructor (AccessControlManager acm)
                 AccessControlClient(acm)
                 DetailedERC20(NAME, SYMBOL,DECIMALS) public
                 {}



    function _isMinter(address addr) internal view returns (bool) {
    return hasRole(addr, SUPER_ADMIN) || hasRole(addr, LIMITED_ADMIN);
    }
}