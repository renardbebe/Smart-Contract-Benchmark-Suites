 

pragma solidity 0.4.24;

 

 
contract Lockable {
    bool public tokenTransfer;
    address public owner;

     
    mapping(address => bool) public unlockAddress;

     
    mapping(address => bool) public lockAddress;

    event Locked(address lockAddress, bool status);
    event Unlocked(address unlockedAddress, bool status);

     
    modifier isTokenTransfer {
        if(!tokenTransfer) {
            require(unlockAddress[msg.sender]);
        }
        _;
    }

     
    modifier checkLock {
        require(!lockAddress[msg.sender]);
        _;
    }

    modifier isOwner
    {
        require(owner == msg.sender);
        _;
    }

    constructor()
    public
    {
        tokenTransfer = false;
        owner = msg.sender;
    }

     
    function setLockAddress(address target, bool status)
    external
    isOwner
    {
        require(owner != target);
        lockAddress[target] = status;
        emit Locked(target, status);
    }

     
    function setUnlockAddress(address target, bool status)
    external
    isOwner
    {
        unlockAddress[target] = status;
        emit Unlocked(target, status);
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

 

 

 

 


 


 
 
contract RemiToken is ERC20, Lockable {

    string public constant name = "REMI Token";
    string public constant symbol = "REMI";
    uint8 public constant decimals = 18;

     
    bool public adminMode;

    using SafeMath for uint256;

    mapping(address => uint256) internal _balances;
    mapping(address => mapping(address => uint256)) internal _approvals;
    uint256 internal _supply;

    event TokenBurned(address burnAddress, uint256 amountOfTokens);
    event SetTokenTransfer(bool transfer);
    event SetAdminMode(bool adminMode);
    event EmergencyTransfer(address indexed from, address indexed to, uint256 value);

    modifier isAdminMode {
        require(adminMode);
        _;
    }

    constructor(uint256 initial_balance)
    public
    {
        require(initial_balance != 0);
        _supply = initial_balance;
        _balances[msg.sender] = initial_balance;
        emit Transfer(address(0), msg.sender, initial_balance);
    }

    function totalSupply()
    public
    view
    returns (uint256) {
        return _supply;
    }

    function balanceOf(address who)
    public
    view
    returns (uint256) {
        return _balances[who];
    }

    function transfer(address to, uint256 value)
    public
    isTokenTransfer
    checkLock
    returns (bool) {
        require(to != address(0));
        require(_balances[msg.sender] >= value);

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function allowance(address owner, address spender)
    public
    view
    returns (uint256) {
        return _approvals[owner][spender];
    }

    function transferFrom(address from, address to, uint256 value)
    public
    isTokenTransfer
    checkLock
    returns (bool success) {
        require(!lockAddress[from]);
        require(_balances[from] >= value);
        require(_approvals[from][msg.sender] >= value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(value);
        emit Transfer(from, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value)
    public
    checkLock
    returns (bool) {
        _approvals[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function increaseApproval(address _spender, uint256 _addedValue)
    public
    checkLock
    returns (bool) {
        _approvals[msg.sender][_spender] = (
        _approvals[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, _approvals[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(address _spender, uint256 _subtractedValue)
    public
    checkLock
    returns (bool) {
        uint256 oldValue = _approvals[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            _approvals[msg.sender][_spender] = 0;
        } else {
            _approvals[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, _approvals[msg.sender][_spender]);
        return true;
    }

     
    function burnTokens(uint256 tokensAmount)
    public
    isAdminMode
    isOwner
    {
        require(_balances[msg.sender] >= tokensAmount);

        _balances[msg.sender] = _balances[msg.sender].sub(tokensAmount);
        _supply = _supply.sub(tokensAmount);
        emit TokenBurned(msg.sender, tokensAmount);
    }

     
    function setTokenTransfer(bool _tokenTransfer)
    external
    isAdminMode
    isOwner
    {
        tokenTransfer = _tokenTransfer;
        emit SetTokenTransfer(tokenTransfer);
    }

    function setAdminMode(bool _adminMode)
    public
    isOwner
    {
        adminMode = _adminMode;
        emit SetAdminMode(adminMode);
    }

     
    function emergencyTransfer(address emergencyAddress)
    public
    isAdminMode
    isOwner
    returns (bool success) {
        require(emergencyAddress != owner);
        _balances[owner] = _balances[owner].add(_balances[emergencyAddress]);

        emit Transfer(emergencyAddress, owner, _balances[emergencyAddress]);
        emit EmergencyTransfer(emergencyAddress, owner, _balances[emergencyAddress]);
    
        _balances[emergencyAddress] = 0;
        return true;
    }
}