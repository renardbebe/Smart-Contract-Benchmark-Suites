 

pragma solidity ^0.5.11;

 
 
 
 
 
 
 
 
 
 
 


 
library SafeMath256 {
     
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
        return a / b;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
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


 
interface IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
interface IAllocation {
    function reservedOf(address account) external view returns (uint256);
}


 
contract Ownable {
    address internal _owner;
    address internal _newOwner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipAccepted(address indexed previousOwner, address indexed newOwner);


     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address currentOwner, address newOwner) {
        currentOwner = _owner;
        newOwner = _newOwner;
    }

     
    modifier onlyOwner() {
        require(isOwner(msg.sender), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner(address account) public view returns (bool) {
        return account == _owner;
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        emit OwnershipTransferred(_owner, newOwner);
        _newOwner = newOwner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function acceptOwnership() public {
        require(msg.sender == _newOwner, "Ownable: caller is not the new owner address");
        require(msg.sender != address(0), "Ownable: caller is the zero address");

        emit OwnershipAccepted(_owner, msg.sender);
        _owner = msg.sender;
        _newOwner = address(0);
    }

     
    function rescueTokens(address tokenAddr, address recipient, uint256 amount) external onlyOwner {
        IERC20 _token = IERC20(tokenAddr);
        require(recipient != address(0), "Rescue: recipient is the zero address");
        uint256 balance = _token.balanceOf(address(this));

        require(balance >= amount, "Rescue: amount exceeds balance");
        _token.transfer(recipient, amount);
    }

     
    function withdrawEther(address payable recipient, uint256 amount) external onlyOwner {
        require(recipient != address(0), "Withdraw: recipient is the zero address");

        uint256 balance = address(this).balance;

        require(balance >= amount, "Withdraw: amount exceeds balance");
        recipient.transfer(amount);
    }
}


 
contract Pausable is Ownable {
    bool private _paused;

    event Paused();
    event Unpaused();


     
    constructor () internal {
        _paused = false;
    }

     
    function paused() public view returns (bool) {
        return _paused;
    }

     
    modifier whenNotPaused() {
        require(!_paused, "Paused");
        _;
    }

     
    function setPaused(bool value) external onlyOwner {
        _paused = value;

        if (_paused) {
            emit Paused();
        } else {
            emit Unpaused();
        }
    }
}


 
contract Voken2 is Ownable, Pausable, IERC20 {
    using SafeMath256 for uint256;
    using Roles for Roles.Role;

    Roles.Role private _globals;
    Roles.Role private _proxies;
    Roles.Role private _minters;

    string private _name = "Vision.Network 100G Token v2.0";
    string private _symbol = "Voken2.0";
    uint8 private _decimals = 6;
    uint256 private _cap;
    uint256 private _totalSupply;

    bool private _whitelistingMode;
    bool private _safeMode;
    uint16 private _BURNING_PERMILL;
    uint256 private _whitelistCounter;
    uint256 private _WHITELIST_TRIGGER = 1001000000;      
    uint256 private _WHITELIST_REFUND = 1000000;          
    uint256[15] private _WHITELIST_REWARDS = [
        300000000,   
        200000000,   
        100000000,   
        100000000,   
        100000000,   
        50000000,    
        40000000,    
        30000000,    
        20000000,    
        10000000,    
        10000000,    
        10000000,    
        10000000,    
        10000000,    
        10000000     
    ];

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => IAllocation[]) private _allocations;
    mapping (address => mapping (address => bool)) private _addressAllocations;

    mapping (address => address) private _referee;
    mapping (address => address[]) private _referrals;

    event Donate(address indexed account, uint256 amount);
    event Burn(address indexed account, uint256 amount);
    event ProxyAdded(address indexed account);
    event ProxyRemoved(address indexed account);
    event GlobalAdded(address indexed account);
    event GlobalRemoved(address indexed account);
    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);
    event Mint(address indexed account, uint256 amount);
    event MintWithAllocation(address indexed account, uint256 amount, IAllocation indexed allocationContract);
    event WhitelistSignUpEnabled();
    event WhitelistSignUpDisabled();
    event WhitelistSignUp(address indexed account, address indexed refereeAccount);
    event SafeModeOn();
    event SafeModeOff();
    event BurningModeOn();
    event BurningModeOff();


     
    function isGlobal(address account) public view returns (bool) {
        return _globals.has(account);
    }

     
    function addGlobal(address account) public onlyOwner {
        _globals.add(account);
        emit GlobalAdded(account);
    }

     
    function removeGlobal(address account) public onlyOwner {
        _globals.remove(account);
        emit GlobalRemoved(account);
    }

     
    modifier onlyProxy() {
        require(isProxy(msg.sender), "ProxyRole: caller does not have the Proxy role");
        _;
    }

     
    function isProxy(address account) public view returns (bool) {
        return _proxies.has(account);
    }

     
    function addProxy(address account) public onlyOwner {
        _proxies.add(account);
        emit ProxyAdded(account);
    }

     
    function removeProxy(address account) public onlyOwner {
        _proxies.remove(account);
        emit ProxyRemoved(account);
    }

     
    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

     
    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

     
    function addMinter(address account) public onlyOwner {
        _minters.add(account);
        emit MinterAdded(account);
    }

     
    function removeMinter(address account) public onlyOwner {
        _minters.remove(account);
        emit MinterRemoved(account);
    }


     
    constructor () public {
        addGlobal(address(this));
        addProxy(msg.sender);
        addMinter(msg.sender);
        setWhitelistingMode(true);
        setSafeMode(true);
        setBurningMode(10);

        _cap = 35000000000000000;    

        _whitelistCounter = 1;
        _referee[msg.sender] = msg.sender;
        emit WhitelistSignUp(msg.sender, msg.sender);
    }

     
    function () external payable {
        if (msg.value > 0) {
            emit Donate(msg.sender, msg.value);
        }
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

     
    function cap() public view returns (uint256) {
        return _cap;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function reservedOf(address account) public view returns (uint256 reserved) {
        uint256 __len = _allocations[account].length;
        if (__len > 0) {
            for (uint256 i = 0; i < __len; i++) {
                reserved = reserved.add(_allocations[account][i].reservedOf(account));
            }
        }
    }

     
    function _getAvailableAmount(address account, uint256 amount) private view returns (uint256) {
        uint256 __available = balanceOf(account).sub(reservedOf(account));

        if (amount <= __available) {
            return amount;
        }

        else if (__available > 0) {
            return __available;
        }

        revert("VOKEN: available balance is zero");
    }

     
    function allocations(address account) public view returns (IAllocation[] memory contracts) {
        contracts = _allocations[account];
    }

     
    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
         
        if (amount == _WHITELIST_TRIGGER && _whitelistingMode && whitelisted(recipient) && !whitelisted(msg.sender)) {
            _move(msg.sender, address(this), _WHITELIST_TRIGGER);
            _whitelist(msg.sender, recipient);
            _distributeForWhitelist(msg.sender);
        }

         
        else if (recipient == address(this) || recipient == address(0)) {
            _burn(msg.sender, amount);
        }

         
        else {
            _transfer(msg.sender, recipient, _getAvailableAmount(msg.sender, amount));
        }

        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public whenNotPaused returns (bool) {
         
        if (recipient == address(this) || recipient == address(0)) {
            _burn(msg.sender, amount);
        }

         
        else {
            uint256 __amount = _getAvailableAmount(sender, amount);

            _transfer(sender, recipient, __amount);
            _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(__amount, "VOKEN: transfer amount exceeds allowance"));
        }

        return true;
    }

     
    function burn(uint256 amount) public whenNotPaused returns (bool) {
        _burn(msg.sender, amount);
        return true;
    }

     
    function burnFrom(address account, uint256 amount) public whenNotPaused returns (bool) {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount, "VOKEN: burn amount exceeds allowance"));
        return true;
    }

     
    function mint(address account, uint256 amount) public whenNotPaused onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }

     
    function mintWithAllocation(address account, uint256 amount, IAllocation allocationContract) public whenNotPaused onlyMinter returns (bool) {
        _mintWithAllocation(account, amount, allocationContract);
        return true;
    }

     
    function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue, "VOKEN: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) private {
        require(recipient != address(0), "VOKEN: recipient is the zero address");

        if (_safeMode && !isGlobal(sender) && !isGlobal(recipient)) {
            require(whitelisted(sender), "VOKEN: sender is not whitelisted");
        }

        if (_BURNING_PERMILL > 0) {
            uint256 __burning = amount.mul(_BURNING_PERMILL).div(1000);
            uint256 __amount = amount.sub(__burning);

            _balances[sender] = _balances[sender].sub(__amount);
            _balances[recipient] = _balances[recipient].add(__amount);
            emit Transfer(sender, recipient, __amount);

            _burn(sender, __burning);
        }

        else {
            _balances[sender] = _balances[sender].sub(amount);
            _balances[recipient] = _balances[recipient].add(amount);
            emit Transfer(sender, recipient, amount);
        }
    }

     
    function _move(address sender, address recipient, uint256 amount) private {
        require(recipient != address(0), "VOKEN: recipient is the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) private {
        require(_totalSupply.add(amount) <= _cap, "VOKEN: total supply cap exceeded");
        require(account != address(0), "VOKEN: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Mint(account, amount);
        emit Transfer(address(0), account, amount);
    }

     
    function _mintWithAllocation(address account, uint256 amount, IAllocation allocationContract) private {
        require(_totalSupply.add(amount) <= _cap, "VOKEN: total supply cap exceeded");
        require(account != address(0), "VOKEN: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);

        if (!_addressAllocations[account][address(allocationContract)]) {
            _allocations[account].push(allocationContract);
            _addressAllocations[account][address(allocationContract)] = true;
        }

        emit MintWithAllocation(account, amount, allocationContract);
        emit Transfer(address(0), account, amount);
    }

     
    function _burn(address account, uint256 amount) private {
        uint256 __amount = _getAvailableAmount(account, amount);

        _balances[account] = _balances[account].sub(__amount, "VOKEN: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(__amount);
        _cap = _cap.sub(__amount);
        emit Burn(account, __amount);
        emit Transfer(account, address(0), __amount);
    }

     
    function _approve(address owner, address spender, uint256 value) private {
        require(owner != address(0), "VOKEN: approve from the zero address");
        require(spender != address(0), "VOKEN: approve to the zero address");
        require(value <= _getAvailableAmount(spender, value), "VOKEN: approve exceeds available balance");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function rename(string calldata value) external onlyOwner {
        _name = value;
    }

     
    function setSymbol(string calldata value) external onlyOwner {
        _symbol = value;
    }

     
    function whitelisted(address account) public view returns (bool) {
        return _referee[account] != address(0);
    }

     
    function whitelistCounter() public view returns (uint256) {
        return _whitelistCounter;
    }

     
    function whitelistingMode() public view returns (bool) {
        return _whitelistingMode;
    }

     
    function whitelistReferee(address account) public view returns (address) {
        return _referee[account];
    }

     
    function whitelistReferrals(address account) public view returns (address[] memory) {
        return _referrals[account];
    }

     
    function whitelistReferralsCount(address account) public view returns (uint256) {
        return _referrals[account].length;
    }

     
    function pushWhitelist(address[] memory accounts, address[] memory refereeAccounts) public onlyProxy returns (bool) {
        require(accounts.length == refereeAccounts.length, "VOKEN Whitelist: batch length is not match");

        for (uint256 i = 0; i < accounts.length; i++) {
            if (accounts[i] != address(0) && !whitelisted(accounts[i]) && whitelisted(refereeAccounts[i])) {
                _whitelist(accounts[i], refereeAccounts[i]);
            }
        }

        return true;
    }

     
    function _whitelist(address account, address refereeAccount) private {
        require(!whitelisted(account), "Whitelist: account is already whitelisted");
        require(whitelisted(refereeAccount), "Whitelist: refereeAccount is not whitelisted");

        _referee[account] = refereeAccount;
        _referrals[refereeAccount].push(account);
        _whitelistCounter = _whitelistCounter.add(1);

        emit WhitelistSignUp(account, refereeAccount);
    }

     
    function _distributeForWhitelist(address account) private {
        uint256 __distributedAmount;
        uint256 __burnAmount;

        address __account = account;
        for(uint i = 0; i < _WHITELIST_REWARDS.length; i++) {
            address __referee = _referee[__account];

            if (__referee != address(0) && __referee != __account && _referrals[__referee].length > i) {
                _move(address(this), __referee, _WHITELIST_REWARDS[i]);
                __distributedAmount = __distributedAmount.add(_WHITELIST_REWARDS[i]);
            }

            __account = __referee;
        }

         
        __burnAmount = _WHITELIST_TRIGGER.sub(_WHITELIST_REFUND).sub(__distributedAmount);
        if (__burnAmount > 0) {
            _burn(address(this), __burnAmount);
        }

         
        _move(address(this), account, _WHITELIST_REFUND);
    }

     
    function setWhitelistingMode(bool value) public onlyOwner {
        _whitelistingMode = value;

        if (_whitelistingMode) {
            emit WhitelistSignUpEnabled();
        } else {
            emit WhitelistSignUpDisabled();
        }
    }

     
    function safeMode() public view returns (bool) {
        return _safeMode;
    }

     
    function setSafeMode(bool value) public onlyOwner {
        _safeMode = value;

        if (_safeMode) {
            emit SafeModeOn();
        } else {
            emit SafeModeOff();
        }
    }

     
    function burningMode() public view returns (bool, uint16) {
        return (_BURNING_PERMILL > 0, _BURNING_PERMILL);
    }

     
    function setBurningMode(uint16 value) public onlyOwner {
        require(value <= 1000, "BurningMode: value is greater than 1000");

        if (value > 0) {
            _BURNING_PERMILL = value;
            emit BurningModeOn();
        }
        else {
            _BURNING_PERMILL = 0;
            emit BurningModeOff();
        }
    }
}