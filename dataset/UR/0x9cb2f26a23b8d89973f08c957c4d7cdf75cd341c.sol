 

pragma solidity 0.5.8;

 
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

contract BlackListableToken is Ownable, ERC20 {

     
    function getBlackListStatus(address _maker) external view returns (bool) {
        return isBlackListed[_maker];
    }

    mapping (address => bool) public isBlackListed;

    function addBlackList(address _evilUser) public onlyOwner {
        require(!isBlackListed[_evilUser], "_evilUser is already in black list");

        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList(address _clearedUser) public onlyOwner {
        require(isBlackListed[_clearedUser], "_clearedUser isn't in black list");

        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

    function destroyBlackFunds(address _blackListedUser) public onlyOwner {
        require(_blackListedUser != address(0x0), "_blackListedUser is the zero address");
        require(isBlackListed[_blackListedUser], "_blackListedUser isn't in black list");

        uint256 dirtyFunds = balanceOf(_blackListedUser);
        super._burn(_blackListedUser, dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }

    event DestroyedBlackFunds(address indexed _blackListedUser, uint256 _balance);

    event AddedBlackList(address indexed _user);

    event RemovedBlackList(address indexed _user);

}

contract UpgradedStandardToken is ERC20 {
     
     
    function transferByLegacy(address from, address to, uint256 value) public returns (bool);
    function transferFromByLegacy(address sender, address from, address to, uint256 value) public returns (bool);
    function approveByLegacy(address owner, address spender, uint256 value) public returns (bool);
    function increaseAllowanceByLegacy(address owner, address spender, uint256 addedValue) public returns (bool);
    function decreaseAllowanceByLegacy(address owner, address spender, uint256 subtractedValue) public returns (bool);
}

contract DZARToken is ERC20, Pausable, BlackListableToken {

    string public name;
    string public symbol;
    uint8 public decimals;
    address public upgradedAddress;
    bool public deprecated;

     
     
     
     
     
     
     
    constructor(uint256 _initialSupply, string memory _name, string memory _symbol, uint8 _decimals) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        deprecated = false;
        super._mint(msg.sender, _initialSupply);
    }

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(!isBlackListed[msg.sender], "can't transfer token from address in black list");
        require(!isBlackListed[_to], "can't transfer token to address in black list");
        if (deprecated) {
            success = UpgradedStandardToken(upgradedAddress).transferByLegacy(msg.sender, _to, _value);
            require(success, "failed to call upgraded contract");
            return true;
        } else {
            return super.transfer(_to, _value);
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(!isBlackListed[_from], "can't transfer token from address in black list");
        require(!isBlackListed[_to], "can't transfer token to address in black list");
        if (deprecated) {
            success = UpgradedStandardToken(upgradedAddress).transferFromByLegacy(msg.sender, _from, _to, _value);
            require(success, "failed to call upgraded contract");
            return true;
        } else {
            return super.transferFrom(_from, _to, _value);
        }
    }

     
    function balanceOf(address who) public view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).balanceOf(who);
        } else {
            return super.balanceOf(who);
        }
    }

     
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        if (deprecated) {
            success = UpgradedStandardToken(upgradedAddress).approveByLegacy(msg.sender, _spender, _value);
            require(success, "failed to call upgraded contract");
            return true;
        } else {
            return super.approve(_spender, _value);
        }
    }

     
    function increaseAllowance(address _spender, uint256 _addedValue) public whenNotPaused returns (bool success) {
        if (deprecated) {
            success = UpgradedStandardToken(upgradedAddress).increaseAllowanceByLegacy(msg.sender, _spender, _addedValue);
            require(success, "failed to call upgraded contract");
            return true;
        } else {
            return super.increaseAllowance(_spender, _addedValue);
        }
    }

     
    function decreaseAllowance(address _spender, uint256 _subtractedValue) public whenNotPaused returns (bool success) {
        if (deprecated) {
            success = UpgradedStandardToken(upgradedAddress).decreaseAllowanceByLegacy(msg.sender, _spender, _subtractedValue);
            require(success, "failed to call upgraded contract");
            return true;
        } else {
            return super.decreaseAllowance(_spender, _subtractedValue);
        }
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).allowance(_owner, _spender);
        } else {
            return super.allowance(_owner, _spender);
        }
    }

     
    function deprecate(address _upgradedAddress) public onlyOwner {
        require(_upgradedAddress != address(0x0), "_upgradedAddress is a zero address");
        require(!deprecated, "this contract has been deprecated");

        deprecated = true;
        upgradedAddress = _upgradedAddress;
        emit Deprecate(_upgradedAddress);
    }

    function totalSupply() public view returns (uint256) {
        if (deprecated) {
            return UpgradedStandardToken(upgradedAddress).totalSupply();
        } else {
            return super.totalSupply();
        }
    }

     
     
     
     
    function issue(uint256 amount) public onlyOwner whenNotPaused {
        require(!deprecated, "this contract has been deprecated");

        super._mint(msg.sender, amount);
        emit Issue(amount);
    }

     
     
     
     
     
    function redeem(uint256 amount) public onlyOwner whenNotPaused {
        require(!deprecated, "this contract has been deprecated");

        super._burn(msg.sender, amount);
        emit Redeem(amount);
    }

     
    event Issue(uint256 amount);

     
    event Redeem(uint256 amount);

     
    event Deprecate(address indexed newAddress);
}