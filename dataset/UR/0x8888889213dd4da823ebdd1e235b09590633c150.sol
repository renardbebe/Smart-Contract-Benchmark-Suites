 

pragma solidity ^0.5.10;

 
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


 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes memory data) public;
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


contract AdministratorRole {
    using Roles for Roles.Role;

    event AdministratorAdded(address indexed account);
    event AdministratorRemoved(address indexed account);

    Roles.Role private _administrators;

    constructor () internal {
        _addAdministrator(msg.sender);
    }

    modifier onlyAdministrator() {
        require(isAdministrator(msg.sender), "AdministratorRole: caller does not have the Administrator role");
        _;
    }

    function isAdministrator(address account) public view returns (bool) {
        return _administrators.has(account);
    }

    function addAdministrator(address account) public onlyAdministrator {
        _addAdministrator(account);
    }

    function renounceAdministrator() public {
        _removeAdministrator(msg.sender);
    }

    function _addAdministrator(address account) internal {
        _administrators.add(account);
        emit AdministratorAdded(account);
    }

    function _removeAdministrator(address account) internal {
        _administrators.remove(account);
        emit AdministratorRemoved(account);
    }
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





 
contract ERC20Burnable is ERC20 {
     
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

     
    function burnFrom(address account, uint256 amount) public {
        _burnFrom(account, amount);
    }
}



 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}



 
 
 
 
 

 
 
 
 
 
contract MarbleCoin is ERC20, Owned, AdministratorRole, ERC20Detailed, ERC20Burnable {

     
    bool private _supplycapped = false;

     
    uint256 private MBC = 1e18;

     
    constructor () public ERC20Detailed("Marblecoin", "MBC", 18) {
         
        mint(msg.sender, 100000000 * MBC);
    }

     
    modifier onlyAdministratorOrOwner() {
        require(isAdministrator(msg.sender) || isOwner());
        _;
    }

     
    function addAdministrator(address account) public onlyOwner {
        _addAdministrator(account);
    }

     
    function removeAdministrator(address account) public onlyOwner {
        _removeAdministrator(account);
    }

     
    function renounceOwnership() public onlyOwner {
    }

     

     
    bool private _paused;

     
    modifier whenNotPaused() {
        require(!_paused);
        _;
    }

     
    modifier whenPaused() {
        require(_paused);
        _;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

     
    function pause() external onlyAdministratorOrOwner whenNotPaused {
        _paused = true;
    }

     
     
    function unpause() public onlyOwner whenPaused {
        _paused = false;
    }

     
    function transfer(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        return super.transfer(recipient, amount);
    }

     
     
    function transferMBC(address recipient, uint256 amount) public whenNotPaused returns (bool) {
        return super.transfer(recipient, amount * MBC);
    }

     
    function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value);
    }

     
     
    function transferMBCFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
        return super.transferFrom(from, to, value * MBC);
    }

     
    function mint(address account, uint256 amount) public onlyAdministratorOrOwner whenNotPaused returns (bool) {
        require(totalSupply() + amount > totalSupply(), "Increase in supply would cause overflow.");
        require(!isSupplyCapped(), "Supply has been capped.");
        _mint(account, amount);
        return true;
    }

     
    function mintMBC(address account, uint256 amount) public onlyAdministratorOrOwner whenNotPaused returns (bool) {
        return mint(account, amount * MBC);
    }

     
     
    function freezeMint() public onlyOwner returns (bool) {
        _supplycapped = true;
        return isSupplyCapped();
    }

     
    function isSupplyCapped() public view returns (bool) {
        return _supplycapped;
    }

     
    function burnMBC(uint256 amount) public {
        burn(amount * MBC);
    }

     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        _approve(msg.sender, spender, tokens);
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

     
    function () external payable {
        revert();
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyAdministratorOrOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(owner, tokens);
    }
}