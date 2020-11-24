 

pragma solidity ^0.4.24;



 
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

   
  function divRemain(uint256 numerator, uint256 denominator) internal pure returns (uint256 quotient, uint256 remainder) {
    quotient  = div(numerator, denominator);
    remainder = sub(numerator, mul(denominator, quotient));
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

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);
  event RoleRemovedAll(string role);

   
  function checkRole(address _operator, string _role)
    view
    public
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    view
    public
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

   
  function removeRoleAll(string _role)
    internal
  {
    delete roles[_role];
    emit RoleRemovedAll(_role);
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


 
contract Administrable is Ownable, RBAC {
  string public constant ROLE_LOCKUP = "lockup";
  string public constant ROLE_MINT = "mint";

  constructor () public {
    addRole(msg.sender, ROLE_LOCKUP);
    addRole(msg.sender, ROLE_MINT);
  }

   
  modifier onlyAdmin(string _role) {
    checkRole(msg.sender, _role);
    _;
  }

  modifier onlyOwnerOrAdmin(string _role) {
    require(msg.sender == owner || isAdmin(msg.sender, _role));
    _;
  }

   
  function isAdmin(address _addr, string _role)
    public
    view
    returns (bool)
  {
    return hasRole(_addr, _role);
  }

   
  function addAdmin(address _operator, string _role)
    public
    onlyOwner
  {
    addRole(_operator, _role);
  }

   
  function removeAdmin(address _operator, string _role)
    public
    onlyOwner
  {
    removeRole(_operator, _role);
  }

   
  function claimAdmin(string _role)
    public
    onlyOwner
  {
    removeRoleAll(_role);

    addRole(msg.sender, _role);
  }
}


 
contract Lockable is Administrable {

  using SafeMath for uint256;

  event Locked(address _granted, uint256 _amount, uint256 _expiresAt);
  event UnlockedAll(address _granted);

   
  struct Lock {
    uint256 amount;
    uint256 expiresAt;
  }

   
  mapping (address => Lock[]) public grantedLocks;
  

   
  function lock
  (
    address _granted, 
    uint256 _amount, 
    uint256 _expiresAt
  ) 
    onlyOwnerOrAdmin(ROLE_LOCKUP) 
    public 
  {
    require(_amount > 0);
    require(_expiresAt > now);

    grantedLocks[_granted].push(Lock(_amount, _expiresAt));

    emit Locked(_granted, _amount, _expiresAt);
  }

   
  function unlock
  (
    address _granted
  ) 
    onlyOwnerOrAdmin(ROLE_LOCKUP) 
    public 
  {
    require(grantedLocks[_granted].length > 0);
    
    delete grantedLocks[_granted];
    emit UnlockedAll(_granted);
  }

  function lockedAmountOf
  (
    address _granted
  ) 
    public
    view
    returns(uint256)
  {
    require(_granted != address(0));
    
    uint256 lockedAmount = 0;
    uint256 lockedCount = grantedLocks[_granted].length;
    if (lockedCount > 0) {
      Lock[] storage locks = grantedLocks[_granted];
      for (uint i = 0; i < locks.length; i++) {
        if (now < locks[i].expiresAt) {
          lockedAmount = lockedAmount.add(locks[i].amount);
        } 
      }
    }

    return lockedAmount;
  }
}


 
contract Pausable is Ownable  {
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

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}


 
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

    function msgSender() 
        public
        view
        returns (address)
    {
        return msg.sender;
    }

    function transfer(
        address _to, 
        uint256 _value
    ) 
        public 
        returns (bool) 
    {
        require(_to != address(0));
        require(_to != msg.sender);
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


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
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

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
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
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


contract BurnableToken is StandardToken {
    
    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) 
        public 
    {
        _burn(msg.sender, _value);
    }

    function _burn(address _who, uint256 _value) 
        internal 
    {
        require(_value <= balances[_who]);
         
         
        
        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}



contract MintableToken is StandardToken, Administrable {
    event Mint(address indexed to, uint256 amount);
    event MintStarted();
    event MintFinished();

    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier cantMint() {
        require(mintingFinished);
        _;
    }
   
     
    function mint(address _to, uint256 _amount) onlyOwnerOrAdmin(ROLE_MINT) canMint public returns (bool) {
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function startMinting() onlyOwner cantMint public returns (bool) {
        mintingFinished = false;
        emit MintStarted();
        return true;
    }

     
    function finishMinting() onlyOwner canMint public returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}




 
contract ReliableToken is MintableToken, BurnableToken, Pausable, Lockable {

  using SafeMath for uint256;

   
  modifier whenNotExceedLock(address _granted, uint256 _value) {
    uint256 lockedAmount = lockedAmountOf(_granted);
    uint256 balance = balanceOf(_granted);

    require(balance > lockedAmount && balance.sub(lockedAmount) >= _value);
    _;
  }

  function transfer
  (
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    whenNotExceedLock(msg.sender, _value)
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferLocked
  (
    address _to, 
    uint256 _value,
    uint256 _lockAmount,
    uint256[] _expiresAtList
  ) 
    public 
    whenNotPaused
    whenNotExceedLock(msg.sender, _value)
    onlyOwnerOrAdmin(ROLE_LOCKUP)
    returns (bool) 
  {
    require(_value >= _lockAmount);

    uint256 lockCount = _expiresAtList.length;
    if (lockCount > 0) {
      (uint256 lockAmountEach, uint256 remainder) = _lockAmount.divRemain(lockCount);
      if (lockAmountEach > 0) {
        for (uint i = 0; i < lockCount; i++) {
          if (i == (lockCount - 1) && remainder > 0)
            lockAmountEach = lockAmountEach.add(remainder);

          lock(_to, lockAmountEach, _expiresAtList[i]);  
        }
      }
    }
    
    return transfer(_to, _value);
  }

  function transferFrom
  (
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    whenNotExceedLock(_from, _value)
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function transferLockedFrom
  (
    address _from,
    address _to, 
    uint256 _value,
    uint256 _lockAmount,
    uint256[] _expiresAtList
  ) 
    public 
    whenNotPaused
    whenNotExceedLock(_from, _value)
    onlyOwnerOrAdmin(ROLE_LOCKUP)
    returns (bool) 
  {
    require(_value >= _lockAmount);

    uint256 lockCount = _expiresAtList.length;
    if (lockCount > 0) {
      (uint256 lockAmountEach, uint256 remainder) = _lockAmount.divRemain(lockCount);
      if (lockAmountEach > 0) {
        for (uint i = 0; i < lockCount; i++) {
          if (i == (lockCount - 1) && remainder > 0)
            lockAmountEach = lockAmountEach.add(remainder);

          lock(_to, lockAmountEach, _expiresAtList[i]);  
        }
      }
    }

    return transferFrom(_from, _to, _value);
  }

  function approve
  (
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval
  (
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval
  (
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

  function () external payable 
  {
    revert();
  }
}


contract BundableToken is ReliableToken {

     
    function transferMultiply
    (
        address[] _recipients,
        uint256[] _values
    )
        public
        returns (bool)
    {
        uint length = _recipients.length;
        require(length > 0);
        require(length == _values.length);

        for (uint i = 0; i < length; i++) {
            require(transfer(
                _recipients[i], 
                _values[i]
            ));
        }

        return true;
    }

     
    function transferLockedMultiply
    (
        address[] _recipients,
        uint256[] _values,
        uint256[] _lockAmounts,
        uint256[] _defaultExpiresAtList
    )
        public
        onlyOwnerOrAdmin(ROLE_LOCKUP)
        returns (bool)
    {
        uint length = _recipients.length;
        require(length > 0);
        require(length == _values.length && length == _lockAmounts.length);
        require(_defaultExpiresAtList.length > 0);

        for (uint i = 0; i < length; i++) {
            require(transferLocked(
                _recipients[i], 
                _values[i], 
                _lockAmounts[i], 
                _defaultExpiresAtList
            ));
        }

        return true;
    }
}


contract AIEToken is BundableToken {

  string public constant name = "AIECOLOGY";
  string public constant symbol = "AIE";
  uint32 public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 1000000000 * (10 ** uint256(decimals));

   
  constructor() public 
  {
    totalSupply_ = INITIAL_SUPPLY;
    balances[msg.sender] = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}