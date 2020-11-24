 
contract Token is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances; 
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _frozenAccount; 
    
    event FrozenFunds(address indexed target, bool frozen);

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint256 private _decimals;

     
    constructor (string memory name, string memory symbol, uint256 decimals, uint256 initialSupply) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
        _totalSupply = initialSupply * (10**_decimals);
        _balances[msg.sender] = _totalSupply; 
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint256) {
        return _decimals;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
     
    function freezeAccount(address target, bool freeze) external onlyOwner {
        _frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
    
     
    function checkIfFrozen(address target) external view returns(bool){
        return _frozenAccount[target];
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
    
     
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account,amount*(10**decimals()));
    }
    
     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(!_frozenAccount[sender], "ERC20: transfer from frozen account");
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
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