 

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

 

contract DUBI is StandardToken, BurnableToken, RBAC {
  string public constant name = "Decentralized Universal Basic Income";
  string public constant symbol = "DUBI";
  uint8 public constant decimals = 18;
  string constant public ROLE_MINT = "mint";

  event MintLog(address indexed to, uint256 amount);

  function DUBI() public {
    totalSupply = 0;
  }

   
  function mint(address _to, uint256 _amount) external onlyRole(ROLE_MINT) returns (bool) {
    require(_to != address(0));
    require(_amount > 0);

     
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);

     
    MintLog(_to, _amount);
    Transfer(0x0, _to, _amount);
    
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

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 

contract Hodler is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for Purpose;
  using SafeERC20 for DUBI;

  Purpose public purpose;
  DUBI public dubi;

  struct Item {
    uint256 id;
    address beneficiary;
    uint256 value;
    uint256 releaseTime;
    bool fulfilled;
  }

  mapping(address => mapping(uint256 => Item)) private items;

  function Hodler(address _purpose, address _dubi) public {
    require(_purpose != address(0));

    purpose = Purpose(_purpose);
    changeDubiAddress(_dubi);
  }

  function changeDubiAddress(address _dubi) public onlyOwner {
    require(_dubi != address(0));

    dubi = DUBI(_dubi);
  }

  function hodl(uint256 _id, uint256 _value, uint256 _months) external {
    require(_id > 0);
    require(_value > 0);
     
    require(_months == 3 || _months == 6 || _months == 12);

     
    address _user = msg.sender;

     
    Item storage item = items[_user][_id];
     
    require(item.id != _id);

     
    uint256 _seconds = _months.mul(2628000);
     
    uint256 _releaseTime = now.add(_seconds);
    require(_releaseTime > now);

     
    uint256 balance = purpose.balanceOf(_user);
    require(balance >= _value);

     
    uint256 userPercentage = _months.div(3);
     
    uint256 userDubiAmount = _value.mul(userPercentage).div(100);

     
    uint256 ownerPercentage100 = _months.mul(5).div(3);
     
    uint256 ownerDubiAmount = _value.mul(ownerPercentage100).div(10000);

     
    items[_user][_id] = Item(_id, _user, _value, _releaseTime, false);

     
    assert(purpose.hodlerTransfer(_user, _value));

     
    assert(dubi.mint(_user, userDubiAmount));
    assert(dubi.mint(owner, ownerDubiAmount));
  }

  function release(uint256 _id) external {
    require(_id > 0);

     
    address _user = msg.sender;

     
    Item storage item = items[_user][_id];

     
    require(item.id == _id);
     
    require(!item.fulfilled);
     
    require(now >= item.releaseTime);

     
    uint256 balance = purpose.balanceOf(this);
    require(balance >= item.value);

     
    item.fulfilled = true;

     
    purpose.safeTransfer(item.beneficiary, item.value);
  }

  function getItem(address _user, uint256 _id) public view returns (uint256, address, uint256, uint256, bool) {
    Item storage item = items[_user][_id];

    return (
      item.id,
      item.beneficiary,
      item.value,
      item.releaseTime,
      item.fulfilled
    );
  }
}

 

contract HodlFor is Ownable {
  using SafeERC20 for Purpose;
  using SafeERC20 for DUBI;

  Purpose public purpose;
  DUBI public dubi;
  Hodler public hodler;

  struct Item {
    uint256 id;
    address creator;
    address beneficiary;
    bool fulfilled;
  }

  mapping(address => mapping(uint256 => Item)) private items;

  function HodlFor(address _purpose, address _dubi, address _hodler) public {
    require(_purpose != address(0));
    require(_hodler != address(0));

    purpose = Purpose(_purpose);
    changeDubiAddress(_dubi);
    hodler = Hodler(_hodler);
  }

  function changeDubiAddress(address _dubi) public onlyOwner {
    require(_dubi != address(0));

    dubi = DUBI(_dubi);
  }

  function hodl(address _beneficiary, uint256 _id, uint256 _value, uint256 _months) external {
    require(_beneficiary != address(0));
    require(_id > 0);

    address _creator = msg.sender;

     
    Item storage item = items[_creator][_id];
     
    require(item.id != _id);

     
    items[_creator][_id] = Item(_id, _creator, _beneficiary, false);

     
    purpose.safeTransferFrom(_creator, this, _value);
    
     
    hodler.hodl(_id, _value, _months);

     
    uint256 balance = dubi.balanceOf(this);
    dubi.safeTransfer(_beneficiary, balance);
  }

  function release(address _creator, uint256 _id) external {
    require(_creator != address(0));
    require(_id > 0);

    address _beneficiary = msg.sender;

     
    Item storage item = items[_creator][_id];
     
    require(item.id == _id);
     
    require(!item.fulfilled);
     
    require(item.beneficiary == _beneficiary);

     
    item.fulfilled = true;

     
    hodler.release(item.id);

     
    uint256 balance = purpose.balanceOf(this);
    purpose.safeTransfer(_beneficiary, balance);
  }

  function getItem(address _creator, uint256 _id) public view returns (uint256, address, address, bool) {
    Item storage item = items[_creator][_id];

    return (
      item.id,
      item.creator,
      item.beneficiary,
      item.fulfilled
    );
  }
}