 

pragma solidity 0.5.10;


 
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
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseApproval(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseApproval(address spender, uint256 subtractedValue) public returns (bool) {
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

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
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

    function increaseApproval(address spender, uint addedValue) public whenNotPaused returns (bool) {
        return super.increaseApproval(spender, addedValue);
    }

    function decreaseApproval(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
        return super.decreaseApproval(spender, subtractedValue);
    }
}

contract MinterRole is Ownable {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    modifier onlyMinter() {
        require(isMinter(msg.sender) || msg.sender == owner, "MinterRole: caller does not have the Minter role");
        _;
    }
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyOwner {
        _addMinter(account);
    }

    function removeMinter(address account) public onlyOwner {
        _removeMinter(account);
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

 
contract ERC20Capped is ERC20Mintable {
    uint256 internal _cap;
    bool public isFinishMint;

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function _mint(address account, uint256 value) internal {
        require(!isFinishMint, "ERC20Capped: minting has been finished");
        require(totalSupply().add(value) <= _cap, "ERC20Capped: cap exceeded");
        if(totalSupply().add(value) == _cap) {
            isFinishMint = true;
        }
        super._mint(account, value);
    }

    function finishMint() public onlyOwner {
        require(!isFinishMint, "ERC20Capped: minting has been finished");
        isFinishMint = true;
    }
}

 
contract ERC20Burnable is ERC20, Ownable {

    event Burn(address indexed owner, uint256 amount);

     
    function burn(uint256 _value) public onlyOwner {
        require(_value <= _balances[msg.sender], "ERC20Burnable: not enough token balance");
         
         

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _totalSupply = _totalSupply.sub(_value);
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }
}

  
contract TigerCash is ERC20Detailed, ERC20Pausable, ERC20Capped, ERC20Burnable {

     
    mapping (address => uint256) public totalLockAmount;
     
    mapping (address => uint256) public releasedAmount;

    mapping (address => uint256) public lockedAmount;

    mapping (address => allocation[]) public allocations;

    struct allocation {
        uint256 releaseTime;
        uint256 releaseAmount;
    }

    event LockToken(address indexed beneficiary, uint256[] releaseAmounts, uint256[] releaseTimes);
    event ReleaseToken(address indexed user, uint256 releaseAmount, uint256 releaseTime);

     
    constructor(string memory token_name, string memory token_symbol, uint8 token_decimals, uint256 token_cap) public
        ERC20Detailed(token_name, token_symbol, token_decimals) {
        _cap = token_cap * 10 ** uint256(token_decimals);
        
    }

     
    function lockToken(address _beneficiary, uint256[] memory _releaseTimes, uint256[] memory _releaseAmounts) public onlyOwner returns(bool) {
        require(_beneficiary != address(0), "Token: the target address cannot be a zero address");
        require(_releaseTimes.length == _releaseAmounts.length, "Token: the array length must be equal");
        uint256 _lockedAmount;
        for (uint256 i = 0; i < _releaseTimes.length; i++) {
            _lockedAmount = _lockedAmount.add(_releaseAmounts[i]);
            require(_releaseAmounts[i] > 0, "Token: the amount must be greater than 0");
            require(_releaseTimes[i] >= now, "Token: the time must be greater than current time");
             
            allocations[_beneficiary].push(allocation(_releaseTimes[i], _releaseAmounts[i]));
        }
        lockedAmount[_beneficiary] = lockedAmount[_beneficiary].add(_lockedAmount);
        totalLockAmount[_beneficiary] = totalLockAmount[_beneficiary].add(_lockedAmount);
        _balances[owner] = _balances[owner].sub(_lockedAmount);  
        _balances[_beneficiary] = _balances[_beneficiary].add(_lockedAmount);
        emit Transfer(owner, _beneficiary, _lockedAmount);
        emit LockToken(_beneficiary, _releaseAmounts, _releaseTimes);
        return true;
    }

     
    function transfer(address to, uint256 value) public returns (bool) {
        if(releasableAmount(msg.sender) > 0) {
            _releaseToken(msg.sender);
        }

        require(_balances[msg.sender].sub(lockedAmount[msg.sender]) >= value, "Token: not enough token balance");
        super.transfer(to, value);
        return true;
    }

     
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        if(releasableAmount(from) > 0) {
            _releaseToken(from);
        }
        require(_balances[from].sub(lockedAmount[from]) >= value, "Token: not enough token balance");
        super.transferFrom(from, to, value);
        return true;
    }

     
    function releasableAmount(address addr) public view returns(uint256) {
        uint256 num = 0;
        for (uint256 i = 0; i < allocations[addr].length; i++) {
            if (now >= allocations[addr][i].releaseTime) {
                num = num.add(allocations[addr][i].releaseAmount);
            }
        }
        return num.sub(releasedAmount[addr]);
    }

     
    function _releaseToken(address _owner) internal returns(bool) {
        
         
        uint256 amount = releasableAmount(_owner);
        require(amount > 0, "Token: no releasable tokens");
        lockedAmount[_owner] = lockedAmount[_owner].sub(amount);
        releasedAmount[_owner] = releasedAmount[_owner].add(amount);
         
        if (releasedAmount[_owner] == totalLockAmount[_owner]) {
            delete allocations[_owner];  
            totalLockAmount[_owner] = 0;
            releasedAmount[_owner] = 0;
            lockedAmount[_owner] = 0;
        }
        emit ReleaseToken(_owner, amount, now);
        return true;
    }

}