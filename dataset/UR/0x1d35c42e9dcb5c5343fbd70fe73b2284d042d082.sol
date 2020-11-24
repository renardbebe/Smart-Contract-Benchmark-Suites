 

pragma solidity ^0.5.0;

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
        require(b <= a, "SafeMath: subtraction overflow");
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
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}
contract ERC20 is IERC20 {
    using SafeMath for uint256;

     
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
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
contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
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
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}
contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
        _removePauser(msg.sender);
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
contract Pausable is PauserRole {
     
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
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

    function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseAllowance(spender, addedValue);
    }

    function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseAllowance(spender, subtractedValue);
    }
}
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
 

contract ERC1132 {
     
    mapping(address => bytes32[]) public lockReason;

     
    struct lockToken {
        uint256 amount;
        uint256 validity;
        bool claimed;
    }

     
    mapping(address => mapping(bytes32 => lockToken)) public locked;

     
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

     
     
    function lock(bytes32 _reason, uint256 _amount, uint256 _time, address _of) public returns (bool);

     
    function tokensLocked(address _of, bytes32 _reason) public view returns (uint256 amount);

     
    function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) public view returns (uint256 amount);

     
    function totalBalanceOf(address _of) public view returns (uint256 amount);

     
    function extendLock(bytes32 _reason, uint256 _time) public returns (bool);

     
    function increaseLockAmount(bytes32 _reason, uint256 _amount) public returns (bool);

     
    function tokensUnlockable(address _of, bytes32 _reason) public view returns (uint256 amount);

     
    function unlock(address _of) public returns (uint256 unlockableTokens);

     
    function getUnlockableTokens(address _of) public view returns (uint256 unlockableTokens);

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

 
contract HugCoin is ERC20Detailed, ERC20, ERC20Mintable, ERC20Pausable, ERC20Burnable, Ownable,ERC1132 {
	 
	string internal constant ALREADY_LOCKED = 'Tokens already locked';
	string internal constant NOT_LOCKED = 'No tokens locked';
	string internal constant AMOUNT_ZERO = 'Amount can not be 0';
	string internal constant NOT_ENOUGH_TOKENS = 'Not enough tokens';

  constructor(string memory name, string memory symbol, uint8 decimals, uint256 totalSupply) ERC20Detailed(name, symbol, decimals) public {
    _mint(owner(), totalSupply * 10 ** uint(decimals));
  }

	 
	function lock(bytes32 _reason, uint256 _amount, uint256 _time, address _of) public onlyOwner returns (bool) {
		uint256 validUntil = now.add(_time);  

		 
		 
		require(_amount <= _balances[_of], NOT_ENOUGH_TOKENS);  
		require(tokensLocked(_of, _reason) == 0, ALREADY_LOCKED);
		require(_amount != 0, AMOUNT_ZERO);

		if (locked[_of][_reason].amount == 0){
			lockReason[_of].push(_reason);
		}

		 
		_balances[address(this)] = _balances[address(this)].add(_amount);
		_balances[_of] = _balances[_of].sub(_amount);

		locked[_of][_reason] = lockToken(_amount, validUntil, false);

			 
		emit Transfer(_of, address(this), _amount);
		emit Locked(_of, _reason, _amount, validUntil);
		return true;
	}

	 
	function transferWithLock(address _to, bytes32 _reason, uint256 _amount, uint256 _time) public onlyOwner returns (bool) {
		uint256 validUntil = now.add(_time );  

		require(tokensLocked(_to, _reason) == 0, ALREADY_LOCKED);
		require(_amount != 0, AMOUNT_ZERO);

		if (locked[_to][_reason].amount == 0){
			lockReason[_to].push(_reason);
		}

		transfer(address(this), _amount);

		locked[_to][_reason] = lockToken(_amount, validUntil, false);

		emit Locked(_to, _reason, _amount, validUntil);
		return true;
	}

	 
	function tokensLocked(address _of, bytes32 _reason) public onlyOwner view returns (uint256 amount) {
		if (!locked[_of][_reason].claimed){
			amount = locked[_of][_reason].amount;
		}
	}

	 
	function tokensLockedAtTime(address _of, bytes32 _reason, uint256 _time) public onlyOwner view returns (uint256 amount) {
		if (locked[_of][_reason].validity > _time){
			amount = locked[_of][_reason].amount;
		}
	}

	 
	function totalBalanceOf(address _of) public onlyOwner view returns (uint256 amount) {
		amount = balanceOf(_of);
		for (uint256 i = 0; i < lockReason[_of].length; i++) {
			amount = amount.add(tokensLocked(_of, lockReason[_of][i]));
		}
	}

	 
	function extendLock(bytes32 _reason, uint256 _time) public onlyOwner returns (bool) {
		require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
		locked[msg.sender][_reason].validity = locked[msg.sender][_reason].validity.add(_time);
		emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
		return true;
	}


	 
	function increaseLockAmount(bytes32 _reason, uint256 _amount) public onlyOwner returns (bool) {
		require(tokensLocked(msg.sender, _reason) > 0, NOT_LOCKED);
		transfer(address(this), _amount);

		locked[msg.sender][_reason].amount = locked[msg.sender][_reason].amount.add(_amount);

		emit Locked(msg.sender, _reason, locked[msg.sender][_reason].amount, locked[msg.sender][_reason].validity);
		return true;
	}

	 
	function tokensUnlockable(address _of, bytes32 _reason) public onlyOwner view returns (uint256 amount) {
		 
		 
		amount = locked[_of][_reason].amount;
	}

	 
	function unlock(address _of) public onlyOwner returns (uint256 unlockableTokens) {
		uint256 lockedTokens;
		for (uint256 i = 0; i < lockReason[_of].length; i++) {
			lockedTokens = tokensUnlockable(_of, lockReason[_of][i]);
			if (lockedTokens > 0) {
				unlockableTokens = unlockableTokens.add(lockedTokens);
				locked[_of][lockReason[_of][i]].claimed = true;
				emit Unlocked(_of, lockReason[_of][i], lockedTokens);
			}
		}

		if (unlockableTokens > 0) {
			this.transfer(_of, unlockableTokens);
		}
	}

	 
	function getUnlockableTokens(address _of) public onlyOwner view returns (uint256 unlockableTokens){
		for (uint256 i = 0; i < lockReason[_of].length; i++) {
			unlockableTokens = unlockableTokens.add(tokensUnlockable(_of, lockReason[_of][i]));
		}
	}
}