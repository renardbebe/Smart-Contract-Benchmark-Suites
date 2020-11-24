 

pragma solidity 0.4.24;

  

 
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
    uint256 c = a - b;
    return c;
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

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}
 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(msg.sender == _owner);
    _;
  }

    
   function isOwner() public view returns (bool) {
    return msg.sender == _owner;
   }
   
   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(_owner, _newOwner);
    _owner = _newOwner;
  }
}

 
contract Pausable is Ownable {
event Pause();
event Unpause();
bool public paused = false;
 
modifier whenNotPaused() {
require(!paused);
_;
}
 
modifier whenPaused() {
require(paused);
_;
}
 
function pauseContract() onlyOwner whenNotPaused public {
paused = true;
emit Pause();
}
 
function unpauseContract() onlyOwner whenPaused public {
paused = false;
emit Unpause();
}
}

 
contract Controlled is Pausable {
  using Roles for Roles.Role;
   
  Roles.Role internal lockedList;
   
  Roles.Role internal adminGroupList;
  
   
  constructor() internal {
    Roles.add(adminGroupList, msg.sender);
  }
  
   
  bool internal _lockedListFlag = false;
  
   
  function lockedListFlag() public view inAdminGroupList returns (bool) {
    return _lockedListFlag;
  }
  
    
  function setLockedListFlag(bool _enable) public inAdminGroupList returns (bool success) {
    _lockedListFlag = _enable;
    return true;
  }
   
   
  function insertToLockedList(address _addr)  public inAdminGroupList  returns (bool success) {
    Roles.add(lockedList, _addr);
    success = true;
  }
  
  function removeFromLockedList(address _addr)  public inAdminGroupList returns (bool success) {
    Roles.remove(lockedList, _addr);
    success = true;
  }
  
  function hasInLockedList(address _addr)  public inAdminGroupList view returns (bool) {
   return Roles.has(lockedList, _addr);
  }
  
  
  function insertToAdminList(address _addr)  public inAdminGroupList  returns (bool success) {
    Roles.add(adminGroupList, _addr);
    success = true;
  }
  
  function removeFromAdminList(address _addr)  public inAdminGroupList  returns (bool success) {
    Roles.remove(adminGroupList, _addr);
    success = true;
  }
  
  function hasInAdminList(address _addr)  public inAdminGroupList view returns (bool) {
      return Roles.has(adminGroupList, _addr);
  }
    
  modifier inAdminGroupList() {
    require(Roles.has(adminGroupList, msg.sender), "you are not Admin Group Member!");
    _;
  }
  modifier notInLockedList() {
        if(_lockedListFlag) {
        require(!Roles.has(lockedList, msg.sender), "you are locked!");
        }
    _;
  }
}

contract ERC20Basic is Controlled {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public whenNotPaused notInLockedList returns (bool) {
    if (_lockedListFlag) { 
     require(!Roles.has(lockedList, _to));
    }  
    require(_value <= balances[msg.sender]);
    require(_to != address(0));
    require(_to != 0x0);  

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    notInLockedList
    returns (bool)
  {
    if (_lockedListFlag) { 
    require(!Roles.has(lockedList, _from));
    require(!Roles.has(lockedList, _to));
    }
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));
    require(_to != 0x0);  

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public whenNotPaused notInLockedList returns (bool) {
    require(_spender != 0x0);  
    if (_lockedListFlag) { 
    require(!Roles.has(lockedList, _spender));
    }
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    if (_lockedListFlag) { 
     require(!Roles.has(lockedList, _owner));
     require(!Roles.has(lockedList, _spender));
    }  
   
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    whenNotPaused
    notInLockedList
    returns (bool)
  {
    require(_spender != 0x0);  
    if (_lockedListFlag) { 
     require(!Roles.has(lockedList, _spender));
    }
   
    allowed[msg.sender][_spender] = (
    allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    whenNotPaused
    notInLockedList
    returns (bool)
  {
    require(_spender != 0x0);  
    if (_lockedListFlag) { 
     require(!Roles.has(lockedList, _spender));
    }
  
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {     
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }
}

 

contract TokenSOX is StandardToken {
  string public name = "Super OX";
  string public symbol = "SOX";
  uint8 public decimals = 18;
  
   
  uint256 internal INITIAL_SUPPLY = (1000000000)*(10**uint256(decimals));
 
   
  bool public burningFinishedFlag = true;
  event Burn(address indexed burner, uint256 value);
  event BurnFinished(address indexed caller, bool burningFinishedFlag);
  event BurnStarted(address indexed caller, bool burningFinishedFlag);
  
   
  constructor() public{
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
  
   
  modifier canBurn() {
    require(!burningFinishedFlag);
    _;
  }
  
   
  function burnFromOwner(uint256 _value) public onlyOwner canBurn returns (bool success) {
    _burn(msg.sender, _value);
    return true;
  }
 
  function _burn(address _who, uint256 _value) internal {
    require(_who != 0x0);  
    require(_value > 0,"Value is greater than 0");
    require(_value <= balances[_who]);
    require(totalSupply_.sub(_value) >= 0,"totalSupply Value is greater than or equal to 0" ) ;
  
    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
  
    
  function setBurningFinishedFlag(bool toggleBurning) public onlyOwner returns (bool) {
    burningFinishedFlag = toggleBurning;
    if (toggleBurning) {
      emit BurnFinished(msg.sender, burningFinishedFlag);
    }
    else {
      emit BurnStarted(msg.sender, burningFinishedFlag);  
    }
    return true;
  }
 
}