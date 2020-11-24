 

 
pragma solidity ^0.4.24;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 
 
pragma solidity ^0.4.24;

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
 
pragma solidity ^0.4.24;


 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}

 
 
pragma solidity ^0.4.24;

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 
 
pragma solidity ^0.4.24;


 
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

 
 
pragma solidity ^0.4.24;


 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 
 
pragma solidity ^0.4.24;

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 
 
pragma solidity ^0.4.24;


contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 
 
pragma solidity ^0.4.24;


 
contract Pausable is PauserRole {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 
 
pragma solidity ^0.4.24;


 
contract ERC20Pausable is ERC20, Pausable {

  function transfer(
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(to, value);
  }

  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(from, to, value);
  }

  function approve(
    address spender,
    uint256 value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(spender, value);
  }

  function increaseAllowance(
    address spender,
    uint addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseAllowance(spender, addedValue);
  }

  function decreaseAllowance(
    address spender,
    uint subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}

 
 
pragma solidity ^0.4.24;


 
contract ERC20Burnable is ERC20 {

   
  function burn(uint256 value) public {
    _burn(msg.sender, value);
  }

   
  function burnFrom(address from, uint256 value) public {
    _burnFrom(from, value);
  }
}

 
 
pragma solidity ^0.4.24;


contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 
 
pragma solidity ^0.4.24;


 
contract ERC20Mintable is ERC20, MinterRole {
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
  }
}

 
 
pragma solidity ^0.4.24;


 
contract ERC20Capped is ERC20Mintable {

  uint256 private _cap;

  constructor(uint256 cap)
    public
  {
    require(cap > 0);
    _cap = cap;
  }

   
  function cap() public view returns(uint256) {
    return _cap;
  }

  function _mint(address account, uint256 value) internal {
    require(totalSupply().add(value) <= _cap);
    super._mint(account, value);
  }
}

 
 
pragma solidity 0.4.24;


 

contract SgmToken is Ownable, ERC20Detailed, ERC20Pausable, ERC20Burnable, ERC20Mintable, ERC20Capped {
    using SafeERC20 for ERC20;

     
    constructor(string name, string symbol, uint8 decimals, uint256 cap, address newOwner)
        public
        ERC20Detailed(name, symbol, decimals)
        ERC20Capped(cap) {
            roleSetup(newOwner);

        }

     
    function reclaimToken(ERC20 recoveredToken) public onlyOwner {
        uint256 balance = recoveredToken.balanceOf(address(this));
        recoveredToken.safeTransfer(owner(), balance);
    }

     
    function roleSetup(address newOwner) internal {
        addPauser(newOwner);
        _removePauser(msg.sender);

        addMinter(newOwner);
        _removeMinter(msg.sender);
    }
}
 
 
pragma solidity 0.4.24;



 
contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    uint256 private constant DECIMAL_FACTOR = 10**uint256(18);
    uint256 private constant CLIFF_DURATION = 30 days;   
    uint256 private constant DURATION = 420 days;   
    uint256 private constant FIRST_RELEASE_PERCENTAGE = 30;   
    uint256 private constant VESTING_PERCENTAGE = 70;   
    uint256 private constant D_RELEASE = 100;   
    uint256 private constant ALLOCATION = 160500000 * DECIMAL_FACTOR;   

    uint256 private _released;   
    uint256 private _start;
    uint256 private _cliff;
    ERC20 private _token;

    struct Beneficiary {
        uint256 totalBalance;   
        uint256 released;   
    }

    mapping(address => Beneficiary) private beneficiaries;

     
    function setState (address[] accounts, uint256[] balances, address token, uint256 start) public onlyOwner {
         
        require(_token == address(0));
        require(accounts.length == balances.length);

        _start = start;
        _cliff = start.add(CLIFF_DURATION);
        _token = ERC20(token);

        uint256 totalBalance = 0;
        uint256 length = accounts.length;
        for (uint256 i = 0; i < length; i = i.add(1)) {
            beneficiaries[accounts[i]] = Beneficiary(balances[i], 0);
            totalBalance = totalBalance.add(balances[i]);
        }
        require(ALLOCATION == totalBalance);
    }

     
    function duration() public view returns (uint256) {
        return DURATION;
    }

     
    function start() public view returns (uint256) {
        return _start;
    }

     
    function cliff() public view returns (uint256) {
        return _cliff;
    }

     
    function token() public view returns (ERC20) {
        return _token;
    }

     
    function release() public {
        releaseFor(msg.sender);
    }

     
    function releaseFor(address beneficiary) public {
        uint256 unreleased = releasableAmount(beneficiary);
        require(unreleased > 0);

        _released = _released.add(unreleased);
        beneficiaries[beneficiary].released = beneficiaries[beneficiary].released.add(unreleased);
        _token.safeTransfer(beneficiary, unreleased);
    }

     
    function getBalanceFor(address beneficiary) public view returns (uint256) {
        return beneficiaries[beneficiary].totalBalance.sub(beneficiaries[beneficiary].released);
    }

     
    function reclaimToken(ERC20 recoveredToken) public onlyOwner {
        uint256 balance = recoveredToken.balanceOf(address(this));
        uint256 lockedBalance;
        uint256 recoveredBalance;
         
        if (recoveredToken == _token) {
            lockedBalance = ALLOCATION.sub(_released);
        }
        recoveredBalance = balance.sub(lockedBalance);
        recoveredToken.safeTransfer(owner(), recoveredBalance);
    }

     
    function releasableAmount(address beneficiary) private view returns (uint256) {
        return vestedAmount(beneficiary).sub(beneficiaries[beneficiary].released);
    }

     
    function vestedAmount(address beneficiary) private view returns (uint256) {
        uint256 vested = 0;

        if (block.timestamp >= _start) {
             
            vested = beneficiaries[beneficiary].totalBalance.mul(FIRST_RELEASE_PERCENTAGE).div(D_RELEASE);
        }
        if (block.timestamp >= _cliff && block.timestamp < _start.add(DURATION)) {
             
            uint256 amountToVest = beneficiaries[beneficiary].totalBalance.mul(VESTING_PERCENTAGE).div(D_RELEASE);
            vested = vested.add(amountToVest.mul(block.timestamp.sub(_start)).div(DURATION));
        }
        if (block.timestamp >= _start.add(DURATION)) {
            vested = beneficiaries[beneficiary].totalBalance;
        }
        return vested;
    }
}
 