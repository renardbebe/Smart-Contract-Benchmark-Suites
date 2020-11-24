 

pragma solidity ^0.5.2;

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
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

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}

 

 
interface IERC1132 {
   
  event Locked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount,
    uint256 _validity
  );

   
  event Unlocked(
    address indexed _of,
    bytes32 indexed _reason,
    uint256 _amount
  );
  
   
  function lock(bytes32 _reason, uint256 _amount, uint256 _time)
    external returns (bool);
 
   
  function tokensLocked(address _of, bytes32 _reason)
    external view returns (uint256 amount);
  
   
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
    external view returns (uint256 amount);
  
   
  function totalBalanceOf(address _of)
    external view returns (uint256 amount);
  
   
  function extendLock(bytes32 _reason, uint256 _time)
    external returns (bool);
  
   
  function increaseLockAmount(bytes32 _reason, uint256 _amount)
    external returns (bool);

   
  function tokensUnlockable(address _of, bytes32 _reason)
    external view returns (uint256 amount);
 
   
  function unlock(address _of)
    external returns (uint256 unlockableTokens);

   
  function getUnlockableTokens(address _of)
    external view returns (uint256 unlockableTokens);

}

 

 
contract ERC1132 is ERC20,  IERC1132 {
   
  string internal constant ALREADY_LOCKED = "Tokens already locked";
  string internal constant NOT_LOCKED = "No tokens locked";
  string internal constant AMOUNT_ZERO = "Amount can not be 0";

   
  mapping(address => bytes32[]) public lockReason;

   
  struct LockToken {
    uint256 amount;
    uint256 validity;
    bool claimed;
  }

   
  mapping(address => mapping(bytes32 => LockToken)) public locked;

   
  function lock(bytes32 _reason, uint256 _amount, uint256 _time)
    public
    returns (bool)
  {
     
    uint256 validUntil = now.add(_time);  

     
     
    require(tokensLocked(msg.sender, _reason) == 0, ALREADY_LOCKED);
    require(_amount != 0, AMOUNT_ZERO);

    if (locked[msg.sender][_reason].amount == 0)
      lockReason[msg.sender].push(_reason);

    transfer(address(this), _amount);

    locked[msg.sender][_reason] = LockToken(_amount, validUntil, false);

    emit Locked(
      msg.sender,
      _reason, 
      _amount, 
      validUntil
    );
    return true;
  }
  
   
  function transferWithLock(
    address _to, 
    bytes32 _reason, 
    uint256 _amount, 
    uint256 _time
  )
    public
    returns (bool)
  {
     
    uint256 validUntil = now.add(_time);  

    require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
    require(_amount != 0, AMOUNT_ZERO);

    if (locked[_to][_reason].amount == 0)
      lockReason[_to].push(_reason);

    transfer(address(this), _amount);

    locked[_to][_reason] = LockToken(_amount, validUntil, false);
    
    emit Locked(
      _to, 
      _reason, 
      _amount, 
      validUntil
    );
    return true;
  }

   
  function tokensLocked(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
    if (!locked[_of][_reason].claimed)
      amount = locked[_of][_reason].amount;
  }
  
   
  function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time)
    public
    view
    returns (uint256 amount)
  {
    if (locked[_of][_reason].validity > _time)
      amount = locked[_of][_reason].amount;
  }

   
  function totalBalanceOf(address _of)
    public
    view
    returns (uint256 amount)
  {
    amount = balanceOf(_of);

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
    }  
  }  
  
   
  function extendLock(bytes32 _reason, uint256 _time)
    public
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);

    locked[msg.sender][_reason].validity += _time;

    emit Locked(
      msg.sender, _reason, 
      locked[msg.sender][_reason].amount, 
      locked[msg.sender][_reason].validity
    );
    return true;
  }
  
   
  function increaseLockAmount(bytes32 _reason, uint256 _amount)
    public
    returns (bool)
  {
    require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
    transfer(address(this), _amount);

    locked[msg.sender][_reason].amount += _amount;

    emit Locked(
      msg.sender, _reason, 
      locked[msg.sender][_reason].amount,
      locked[msg.sender][_reason].validity
    );
    return true;
  }

   
  function tokensUnlockable(address _of, bytes32 _reason)
    public
    view
    returns (uint256 amount)
  {
     
    if (locked[_of][_reason].validity <= now && 
      !locked[_of][_reason].claimed) 
      amount = locked[_of][_reason].amount;
  }

   
  function unlock(address _of)
    public
    returns (uint256 unlockableTokens)
  {
    uint256 lockedTokens;

    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
      if (lockedTokens > 0) {
        unlockableTokens = unlockableTokens.add(lockedTokens);
        locked[_of][lockReason[_of][i]].claimed = true;
        emit Unlocked(_of, lockReason[_of][i], lockedTokens);
      }
    } 

    if (unlockableTokens > 0)
      this.transfer(_of, unlockableTokens);
  }

   
  function getUnlockableTokens(address _of)
    public
    view
    returns (uint256 unlockableTokens)
  {
    for (uint256 i = 0; i < lockReason[_of].length; i++) {
      unlockableTokens = unlockableTokens.add(
        tokensUnlockable(_of, lockReason[_of][i])
      );
    } 
  }
}

 

 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

 

 
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

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender));
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address to, uint256 value) public onlyMinter returns (bool) {
        _mint(to, value);
        return true;
    }
}

 

 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 value) public {
        _burn(msg.sender, value);
    }

     
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}

 

contract RebornDollar is ERC1132, ERC20Detailed, ERC20Mintable, ERC20Burnable {
  string public constant NAME = "Reborn Dollar";
  string public constant SYMBOL = "REBD";
  uint8 public constant DECIMALS = 18;

  uint256 public constant INITIAL_SUPPLY = 10000000000 * (10 ** uint256(DECIMALS));

  constructor()
    ERC20Burnable()
    ERC20Mintable()
    ERC20Detailed(NAME, SYMBOL, DECIMALS)
    ERC20()
    public
  {
    _mint(msg.sender, INITIAL_SUPPLY);
  }
}