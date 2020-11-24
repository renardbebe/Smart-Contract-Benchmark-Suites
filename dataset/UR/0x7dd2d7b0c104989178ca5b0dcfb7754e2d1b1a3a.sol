 

pragma solidity ^0.5.0;

contract Context {
    constructor () internal { }

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}



contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
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



contract PauserRole is Context {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(_msgSender());
    }

    modifier onlyPauser() {
        require(isPauser(_msgSender()), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(_msgSender());
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


contract Pausable is Context, PauserRole {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


contract ERC20Pausable is ERC20, Pausable {
    function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transfer(to, value);
    }

    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        return super.approve(spender, value);
    }

    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}

contract WhitelistAdminRole is Context {
    using Roles for Roles.Role;

    event WhitelistAdminAdded(address indexed account);
    event WhitelistAdminRemoved(address indexed account);

    Roles.Role private _whitelistAdmins;

    constructor () internal {
        _addWhitelistAdmin(_msgSender());
    }

    modifier onlyWhitelistAdmin() {
        require(isWhitelistAdmin(_msgSender()), "WhitelistAdminRole: caller does not have the WhitelistAdmin role");
        _;
    }

    function isWhitelistAdmin(address account) public view returns (bool) {
        return _whitelistAdmins.has(account);
    }

    function addWhitelistAdmin(address account) public onlyWhitelistAdmin {
        _addWhitelistAdmin(account);
    }

    function renounceWhitelistAdmin() public {
        _removeWhitelistAdmin(_msgSender());
    }

    function _addWhitelistAdmin(address account) internal {
        _whitelistAdmins.add(account);
        emit WhitelistAdminAdded(account);
    }

    function _removeWhitelistAdmin(address account) internal {
        _whitelistAdmins.remove(account);
        emit WhitelistAdminRemoved(account);
    }
}







contract IndividualLockableToken is ERC20Pausable, WhitelistAdminRole{
  using SafeMath for uint256;

  event LockTimeSetted(address indexed holder, uint256 old_release_time, uint256 new_release_time);
  event Locked(address indexed holder, uint256 locked_balance_change, uint256 total_locked_balance, uint256 release_time);

  struct lockState {
    uint256 locked_balance;
    uint256 release_time;
  }

  
  uint256 public lock_period = 4 weeks;

  mapping(address => lockState) internal userLock;

  
  function setReleaseTime(address _holder, uint256 _release_time)
    public
    onlyWhitelistAdmin
    returns (bool)
  {
    require(_holder != address(0));
    require(_release_time >= block.timestamp);

    uint256 old_release_time = userLock[_holder].release_time;

    userLock[_holder].release_time = _release_time;
    emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);
    return true;
  }

  
  function getReleaseTime(address _holder)
    public
    view
    returns (uint256)
  {
    require(_holder != address(0));

    return userLock[_holder].release_time;
  }

  
  function clearReleaseTime(address _holder)
    public
    onlyWhitelistAdmin
    returns (bool)
  {
    require(_holder != address(0));
    require(userLock[_holder].release_time > 0);

    uint256 old_release_time = userLock[_holder].release_time;

    userLock[_holder].release_time = 0;
    emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);
    return true;
  }

  
  
  function increaseLockBalance(address _holder, uint256 _value)
    public
    onlyWhitelistAdmin
    returns (bool)
  {
    require(_holder != address(0));
    require(_value > 0);
    require(getFreeBalance(_holder) >= _value);

    if (userLock[_holder].release_time <= block.timestamp) {
        userLock[_holder].release_time  = block.timestamp + lock_period;
    }

    userLock[_holder].locked_balance = (userLock[_holder].locked_balance).add(_value);
    emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
    return true;
  }

  
  
  function increaseLockBalanceWithReleaseTime(address _holder, uint256 _value, uint256 _release_time)
    public
    onlyWhitelistAdmin
    returns (bool)
  {
    require(_holder != address(0));
    require(_value > 0);
    require(getFreeBalance(_holder) >= _value);
    require(_release_time >= block.timestamp);

    uint256 old_release_time = userLock[_holder].release_time;

    userLock[_holder].release_time = _release_time;
    emit LockTimeSetted(_holder, old_release_time, userLock[_holder].release_time);

    userLock[_holder].locked_balance = (userLock[_holder].locked_balance).add(_value);
    emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
    return true;
  }

  
  function decreaseLockBalance(address _holder, uint256 _value)
    public
    onlyWhitelistAdmin
    returns (bool)
  {
    require(_holder != address(0));
    require(_value > 0);
    require(userLock[_holder].locked_balance >= _value);

    userLock[_holder].locked_balance = (userLock[_holder].locked_balance).sub(_value);
    emit Locked(_holder, _value, userLock[_holder].locked_balance, userLock[_holder].release_time);
    return true;
  }

  
  function clearLock(address _holder)
    public
    onlyWhitelistAdmin
    returns (bool)
  {
    require(_holder != address(0));
    require(userLock[_holder].release_time > 0);

    userLock[_holder].locked_balance = 0;
    userLock[_holder].release_time = 0;
    emit Locked(_holder, 0, userLock[_holder].locked_balance, userLock[_holder].release_time);
    return true;
  }

  
  function getLockedBalance(address _holder)
    public
    view
    returns (uint256)
  {
    if(block.timestamp >= userLock[_holder].release_time) return uint256(0);
    return userLock[_holder].locked_balance;
  }

  
  function getFreeBalance(address _holder)
    public
    view
    returns (uint256)
  {
    if(block.timestamp    >= userLock[_holder].release_time  ) return balanceOf(_holder);
    if(balanceOf(_holder) <= userLock[_holder].locked_balance) return uint256(0);
    return balanceOf(_holder).sub(userLock[_holder].locked_balance);
  }

  
  function transfer(
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(msg.sender) >= _value);
    return super.transfer(_to, _value);
  }

  
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(_from) >= _value);
    return super.transferFrom(_from, _to, _value);
  }

  
  function approve(
    address _spender,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(getFreeBalance(msg.sender) >= _value);
    return super.approve(_spender, _value);
  }

  
  function increaseAllowance(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool success)
  {
    require(getFreeBalance(msg.sender) >= allowance(msg.sender, _spender).add(_addedValue));
    return super.increaseAllowance(_spender, _addedValue);
  }

  
  function decreaseAllowance(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool success)
  {
    uint256 oldValue = allowance(msg.sender, _spender);

    if (_subtractedValue < oldValue) {
      require(getFreeBalance(msg.sender) >= oldValue.sub(_subtractedValue));
    }
    return super.decreaseAllowance(_spender, _subtractedValue);
  }
}


contract IDCMAsiaCoin is IndividualLockableToken {
  using SafeMath for uint256;

  string public constant name = "IDCM Asia Coin";
  string public constant symbol = "IDA";
  uint8  public constant decimals = 18;

  uint256 public constant INITIAL_SUPPLY = 300000000 * (10 ** uint256(decimals));

  constructor()
    public
  {
	_mint(msg.sender, INITIAL_SUPPLY);
  }
}