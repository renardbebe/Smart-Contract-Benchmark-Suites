 

pragma solidity 0.5.11;

 
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

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Ownable: the caller must be owner");
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 internal _totalSupply;

     
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(value, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(value, "ERC20: burn amount exceeds total supply");
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
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 
contract Pausable is Ownable {
     
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

     
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
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

 
contract ERC20Pausable is ERC20Burnable, Pausable {
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

    function burn(uint256 amount) public whenNotPaused {
        super.burn(amount);
    }

    function burnFrom(address account, uint256 amount) public whenNotPaused {
        super.burnFrom(account, amount);
    }
}

contract BITSGToken is ERC20Pausable {
    string public constant name = "BitSG Token";
    string public constant symbol = "BITSG";
    uint8 public constant decimals = 8;
    uint256 internal constant INIT_TOTALSUPPLY = 120000000;

    mapping( address => uint256) public lockedAmount;
    mapping (address => LockItem[]) public lockInfo;
    uint256 private constant DAY_TIMES = 24 * 60 * 60;

    event SendAndLockToken(address indexed beneficiary, uint256 lockAmount, uint256 lockTime);
    event ReleaseToken(address indexed beneficiary, uint256 releaseAmount);
    event LockToken(address indexed targetAddr, uint256 lockAmount);
    event UnlockToken(address indexed targetAddr, uint256 releaseAmount);

    struct LockItem {
        address     lock_address;
        uint256     lock_amount;
        uint256     lock_time;
        uint256     lock_startTime;
    }

     
    constructor() public {
        _totalSupply = formatDecimals(INIT_TOTALSUPPLY);
        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

     
    function sendAndLockToken(address beneficiary, uint256 lockAmount, uint256 lockDays) public onlyOwner {
        require(beneficiary != address(0), "BITSGToken: beneficiary is the zero address");
        require(lockAmount > 0, "BITSGToken: the amount of lock is 0");
        require(lockDays > 0, "BITSGToken: the days of lock is 0");
         
        uint256 _lockAmount = formatDecimals(lockAmount);
        uint256 _lockTime = lockDays.mul(DAY_TIMES);
        lockInfo[beneficiary].push(LockItem(beneficiary, _lockAmount, _lockTime, now));
        emit SendAndLockToken(beneficiary, _lockAmount, _lockTime);
        _balances[owner] = _balances[owner].sub(_lockAmount, "BITSGToken: owner doesn't have enough tokens");
        emit Transfer(owner, address(0), _lockAmount);
    }

     
    function releaseToken(address beneficiary) public returns (bool) {
        uint256 amount = getReleasableAmount(beneficiary);
        require(amount > 0, "BITSGToken: no releasable tokens");
        for(uint256 i; i < lockInfo[beneficiary].length; i++) {
            uint256 lockedTime = (now.sub(lockInfo[beneficiary][i].lock_startTime));
            if (lockedTime >= lockInfo[beneficiary][i].lock_time) {
                delete lockInfo[beneficiary][i];
            }
        }
        _balances[beneficiary] = _balances[beneficiary].add(amount);
        emit Transfer(address(0), beneficiary, amount);
        emit ReleaseToken(beneficiary, amount);
        return true;
    }

     
    function getReleasableAmount(address beneficiary) public view returns (uint256) {
        require(lockInfo[beneficiary].length != 0, "BITSGToken: the address has not lock items");
        uint num = 0;
        for(uint256 i; i < lockInfo[beneficiary].length; i++) {
            uint256 lockedTime = (now.sub(lockInfo[beneficiary][i].lock_startTime));
            if (lockedTime >= lockInfo[beneficiary][i].lock_time) {
                num = num.add(lockInfo[beneficiary][i].lock_amount);
            }
        }
        return num;
    }

     
    function lockToken(address targetAddr, uint256 lockAmount) public onlyOwner {
        require(targetAddr != address(0), "BITSGToken: target address is the zero address");
        require(lockAmount > 0, "BITSGToken: the amount of lock is 0");
        uint256 _lockAmount = formatDecimals(lockAmount);
        lockedAmount[targetAddr] = lockedAmount[targetAddr].add(_lockAmount);
        emit LockToken(targetAddr, _lockAmount);
    }

     
    function unlockToken(address targetAddr, uint256 lockAmount) public onlyOwner {
        require(targetAddr != address(0), "BITSGToken: target address is the zero address");
        require(lockAmount > 0, "BITSGToken: the amount of lock is 0");
        uint256 _lockAmount = formatDecimals(lockAmount);
        if(_lockAmount >= lockedAmount[targetAddr]) {
            lockedAmount[targetAddr] = 0;
        } else {
            lockedAmount[targetAddr] = lockedAmount[targetAddr].sub(_lockAmount);
        }
        emit UnlockToken(targetAddr, _lockAmount);
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        require(_balances[msg.sender].sub(lockedAmount[msg.sender]) >= amount, "BITSGToken: transfer amount exceeds the vailable balance of msg.sender");
        return super.transfer(recipient, amount);
    }
     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        require(_balances[sender].sub(lockedAmount[sender]) >= amount, "BITSGToken: transfer amount exceeds the vailable balance of sender");
        return super.transferFrom(sender, recipient, amount);
    }

     
    function burn(uint256 amount) public {
        require(_balances[msg.sender].sub(lockedAmount[msg.sender]) >= amount, "BITSGToken: destroy amount exceeds the vailable balance of msg.sender");
        super.burn(amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        require(_balances[account].sub(lockedAmount[account]) >= amount, "BITSGToken: destroy amount exceeds the vailable balance of account");
        super.burnFrom(account, amount);
    }

     
    function batchTransfer(address[] memory addrs, uint256[] memory amounts) public onlyOwner returns(bool) {
        require(addrs.length == amounts.length, "BITSGToken: the length of the two arrays is inconsistent");
        require(addrs.length <= 150, "BITSGToken: the number of destination addresses cannot exceed 150");
        for(uint256 i = 0;i < addrs.length;i++) {
            require(addrs[i] != address(0), "BITSGToken: target address is the zero address");
            require(amounts[i] != 0, "BITSGToken: the number of transfers is 0");
            transfer(addrs[i], formatDecimals(amounts[i]));
        }
        return true;
    }

    function formatDecimals(uint256 value) internal pure returns (uint256) {
        return value.mul(10 ** uint256(decimals));
    }
}