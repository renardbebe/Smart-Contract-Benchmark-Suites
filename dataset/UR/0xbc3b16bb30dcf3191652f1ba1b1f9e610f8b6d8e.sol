 

pragma solidity ^0.5.11;


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

contract RBACed {
    using Roles for Roles.Role;

    event RoleAdded(string _role);
    event RoleAccessorAdded(string _role, address indexed _address);
    event RoleAccessorRemoved(string _role, address indexed _address);

    string constant public OWNER_ROLE = "OWNER";

    string[] public roles;
    mapping(bytes32 => uint256) roleIndexByName;
    mapping(bytes32 => Roles.Role) private roleByName;

    
    constructor()
    public
    {
        
        _addRole(OWNER_ROLE);

        
        _addRoleAccessor(OWNER_ROLE, msg.sender);
    }

    modifier onlyRoleAccessor(string memory _role) {
        require(isRoleAccessor(_role, msg.sender), "RBACed: sender is not accessor of the role");
        _;
    }

    
    
    function rolesCount()
    public
    view
    returns (uint256)
    {
        return roles.length;
    }

    
    
    
    function isRole(string memory _role)
    public
    view
    returns (bool)
    {
        return 0 != roleIndexByName[_role2Key(_role)];
    }

    
    
    function addRole(string memory _role)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        _addRole(_role);

        
        emit RoleAdded(_role);
    }

    
    
    
    
    function isRoleAccessor(string memory _role, address _address)
    public
    view
    returns (bool)
    {
        return roleByName[_role2Key(_role)].has(_address);
    }

    
    
    
    function addRoleAccessor(string memory _role, address _address)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        _addRoleAccessor(_role, _address);

        
        emit RoleAccessorAdded(_role, _address);
    }

    
    
    
    function removeRoleAccessor(string memory _role, address _address)
    public
    onlyRoleAccessor(OWNER_ROLE)
    {
        
        roleByName[_role2Key(_role)].remove(_address);

        
        emit RoleAccessorRemoved(_role, _address);
    }

    function _addRole(string memory _role)
    internal
    {
        if (0 == roleIndexByName[_role2Key(_role)]) {
            roles.push(_role);
            roleIndexByName[_role2Key(_role)] = roles.length;
        }
    }

    function _addRoleAccessor(string memory _role, address _address)
    internal
    {
        roleByName[_role2Key(_role)].add(_address);
    }

    function _role2Key(string memory _role)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_role));
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

interface Allocator {
    
    function allocate()
    external
    view
    returns (uint256);
}

contract BountyFund is RBACed {
    using SafeMath for uint256;

    event ResolutionEngineSet(address indexed _resolutionEngine);
    event TokensDeposited(address indexed _wallet, uint256 _amount, uint256 _balance);
    event TokensAllocated(address indexed _wallet, address indexed _allocator,
        uint256 _amount, uint256 _balance);
    event Withdrawn(address indexed _wallet, uint256 _amount);

    ERC20 public token;

    address public operator;
    address public resolutionEngine;

    
    constructor(address _token, address _operator)
    public
    {
        
        token = ERC20(_token);

        
        operator = _operator;
    }

    modifier onlyResolutionEngine() {
        require(msg.sender == resolutionEngine, "BountyFund: sender is not the defined resolution engine");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "BountyFund: sender is not the defined operator");
        _;
    }

    
    
    
    function setResolutionEngine(address _resolutionEngine)
    public
    {
        require(address(0) != _resolutionEngine, "BountyFund: resolution engine argument is zero address");
        require(address(0) == resolutionEngine, "BountyFund: resolution engine has already been set");

        
        resolutionEngine = _resolutionEngine;

        
        emit ResolutionEngineSet(_resolutionEngine);
    }

    
    
    
    function depositTokens(uint256 _amount)
    public
    {
        
        token.transferFrom(msg.sender, address(this), _amount);

        
        emit TokensDeposited(msg.sender, _amount, token.balanceOf(address(this)));
    }

    
    
    function allocateTokens(address _allocator)
    public
    onlyResolutionEngine
    returns (uint256)
    {
        
        uint256 amount = Allocator(_allocator).allocate();

        
        token.transfer(msg.sender, amount);

        
        emit TokensAllocated(msg.sender, _allocator, amount, token.balanceOf(address(this)));

        
        return amount;
    }

    
    
    function withdraw(address _wallet)
    public
    onlyOperator
    {
        
        uint256 amount = token.balanceOf(address(this));

        
        token.transfer(_wallet, amount);

        
        emit Withdrawn(_wallet, amount);
    }
}