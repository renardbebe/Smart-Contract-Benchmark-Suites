 

 
 
pragma solidity ^0.5.0;

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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

contract MinterRole is Context {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(_msgSender());
    }

    modifier onlyMinter() {
        require(isMinter(_msgSender()), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(_msgSender());
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

contract ERC20Burnable is Context, ERC20 {
     
    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
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

contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

interface ITST {
     
    function setFeeAccount(address feeAccount) external returns (bool);
    
     
    function setMaxTransferFee(uint256 maxTransferFee) external returns (bool);
    
     
    function setMinTransferFee(uint256 minTransferFee) external returns (bool);
    
     
    function setTransferFeePercentage(uint256 transferFeePercentage) external returns (bool);
        
     
    function calculateTransferFee(uint256 weiAmount) external view returns(uint256) ;
    
         
    function feeAccount() external view returns (address);
    
     
    function maxTransferFee() external view returns (uint256);
    
     
    function minTransferFee() external view returns (uint256);

      
    function transferFeePercentage() external view returns (uint256);

     
    function transfer(address recipient, uint256 amount, string calldata message) external returns (bool);
    
     
    event FeeAccountUpdated(address indexed previousFeeAccount, address indexed newFeeAccount);
    
     
    event MaxTransferFeeUpdated(uint256 previousMaxTransferFee, uint256 newMaxTransferFee);
    
     
    event MinTransferFeeUpdated(uint256 previousMinTransferFee, uint256 newMinTransferFee);
    
     
    event TransferFeePercentageUpdated(uint256 previousTransferFeePercentage, uint256 newTransferFeePercentage);
    
     
    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee, string description);
}

 
contract TransferFee is Ownable, ITST {

    address private _feeAccount;
    uint256 private _maxTransferFee;
    uint256 private _minTransferFee;
    uint256 private _transferFeePercentage;
    
     
    constructor (address feeAccount, uint256 maxTransferFee, uint256 minTransferFee, uint256 transferFeePercentage) public {
        require(feeAccount != address(0x0), "TransferFee: feeAccount is 0");
        require(minTransferFee > 0, "TransferFee: minTransferFee is 0");
        require(maxTransferFee > 0, "TransferFee: maxTransferFee is 0");
        require(transferFeePercentage > 0, "TransferFee: transferFeePercentage is 0");
        
         
         
        require(maxTransferFee > minTransferFee, "TransferFee: maxTransferFee should be greater than minTransferFee");

        _feeAccount = feeAccount;
        _maxTransferFee = maxTransferFee;
        _minTransferFee = minTransferFee;
        _transferFeePercentage = transferFeePercentage;
    }
    
     
    function setFeeAccount(address feeAccount) external onlyOwner returns (bool) {
        require(feeAccount != address(0x0), "TransferFee: feeAccount is 0");
        
        emit FeeAccountUpdated(_feeAccount, feeAccount);
        _feeAccount = feeAccount;
        return true;
    }
    
     
    function setMaxTransferFee(uint256 maxTransferFee) external onlyOwner returns (bool) {
        require(maxTransferFee > 0, "TransferFee: maxTransferFee is 0");
         
        require(maxTransferFee > _minTransferFee, "TransferFee: maxTransferFee should be greater than minTransferFee");
        
        emit MaxTransferFeeUpdated(_maxTransferFee, maxTransferFee);
        _maxTransferFee = maxTransferFee;
        return true;
    }

     
    function setMinTransferFee(uint256 minTransferFee) external onlyOwner returns (bool) {
        require(minTransferFee > 0, "TransferFee: minTransferFee is 0");
         
        require(minTransferFee < _maxTransferFee, "TransferFee: minTransferFee should be less than maxTransferFee");
        
        emit MaxTransferFeeUpdated(_minTransferFee, minTransferFee);
        _minTransferFee = minTransferFee;
        return true;
    }

     
    function setTransferFeePercentage(uint256 transferFeePercentage) external onlyOwner returns (bool) {
        require(transferFeePercentage > 0, "TransferFee: transferFeePercentage is 0");
        
        emit TransferFeePercentageUpdated(_transferFeePercentage, transferFeePercentage);
        _transferFeePercentage = transferFeePercentage;
        return true;
    }
    
         
    function feeAccount() public view returns (address) {
        return _feeAccount;
    }

     
    function maxTransferFee() public view returns (uint256) {
        return _maxTransferFee;
    }
    
     
    function minTransferFee() public view returns (uint256) {
        return _minTransferFee;
    }

      
    function transferFeePercentage() public view returns (uint256) {
        return _transferFeePercentage;
    }
}

 
contract TST is Context, Ownable, ERC20, ERC20Detailed, ERC20Burnable, ERC20Mintable, ERC20Pausable, TransferFee  {
    
     
 
     
    event Transfer(address indexed from, address indexed to, uint256 value, uint256 fee, string description, uint256 timestamp);

     
    constructor (string memory name, string memory symbol, uint8 decimals, 
        address feeAccount, uint256 maxTransferFee, uint256 minTransferFee, uint8 transferFeePercentage) 
        public 
        ERC20Detailed(name, symbol, decimals) 
        TransferFee(feeAccount, maxTransferFee, minTransferFee, transferFeePercentage) {
        _mint(_msgSender(), 0);
    }
    
     
    function calculateTransferFee(uint256 weiAmount) public view returns(uint256) {
        uint256 divisor = uint256(100).mul((10**uint256(decimals())));
        uint256 _fee = (transferFeePercentage().mul(weiAmount)).div(divisor);

        if (_fee < minTransferFee()) {
            _fee = minTransferFee();   
        }

        else if (_fee > maxTransferFee()) {
            _fee = maxTransferFee();
        }
        
        return _fee;
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        uint256 _fee = calculateTransferFee(amount);
        uint256 _amount = amount.sub(_fee);

         
        super.transfer(recipient, _amount);
        
         
        super.transfer(feeAccount(), _fee);  
        emit Transfer(msg.sender, recipient, _amount, _fee, "", now);
        return true;
    }
    
     
    function transfer(address recipient, uint256 amount, string memory message) public returns (bool) {
        uint256 _fee = calculateTransferFee(amount);
        uint256 _amount = amount.sub(_fee);

         
        super.transfer(recipient, _amount);
        
         
        super.transfer(feeAccount(), _fee);  
        emit Transfer(msg.sender, recipient, _amount, _fee, message);
        return true;
    }
    
     
    function unpause() public onlyPauser whenPaused {
        require(false, "contract can't be unpaused");
    }
    
     
    function burn(address account, uint256 amount) public onlyOwner {
        _burn(account, amount);
    }
    
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        require(account == owner(), "mint: tokens can be only minted on owner address");
        _mint(account, amount);
        return true;
    }
    
     
    function totalSupply() public view onlyOwner returns (uint256) {
        return super.totalSupply();
    }
    
     
    
      
    function sendFunds(address from, address to, uint256 value, string memory description) public {
        uint256 _fee = calculateTransferFee(value);
        uint256 _amount = value.sub(_fee);

         
        super.transfer(to, _amount);
        
         
        super.transfer(feeAccount(), _fee);  
        emit Transfer(from, to, _amount, _fee, description, now);
    }
    
    function increaseSupply(address target, uint256 amount) public {
        mint(target,amount);
    }

    function decreaseSupply(address target, uint256 amount) public {
        burn(target,amount);
    }
    
    function getOwner() public view returns (address) {
        return owner();
    }
    
    function getName() public view returns (string memory) {
        return name();
    }
    
    function getFeeAccount() public view returns (address) {
        return feeAccount();
    }
    
    function getTotalSupply() public view returns (uint256) {
        return totalSupply();
    }   
    
    function getMaxTransferFee() public view returns (uint256) {
        return maxTransferFee();
    }

    function getMinTransferFee() public view returns (uint256) {
        return minTransferFee();
    }
    
    function getTransferFeePercentage() public view returns (uint256) {
        return transferFeePercentage();
    }

    function getBalance(address balanceAddress) public view returns (uint256) {
        return balanceOf(balanceAddress);
    }
}