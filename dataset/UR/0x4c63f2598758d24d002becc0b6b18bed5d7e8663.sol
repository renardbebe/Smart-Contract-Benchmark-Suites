 
contract FogCoin is IERC20, ERC20Detailed, MinterRole {
    using SafeMath for uint256;
    uint8 private constant DECIMALS = 18;
    string private constant TOKEN_NAME = "FogCoin";
    string private constant TOKEN_SYMBOL = "FOG";
    uint256 private constant MAX_SUPPLY = 1500000000 * (10 ** uint256(DECIMALS));

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    constructor () public ERC20Detailed(TOKEN_NAME, TOKEN_SYMBOL, DECIMALS) {
        _mint(msg.sender, MAX_SUPPLY);
    }
    
    
    function updateCirculation(address[] memory outOfCirculationAddresses, uint8 numAddresses) public onlyMinter returns (bool) {
        uint256 tokensOutOfCirculation = 0;
        for(uint256 i=0; i<numAddresses; i++){
            tokensOutOfCirculation += balanceOf(outOfCirculationAddresses[i]);
        }
        uint256 tokensInCirculation = MAX_SUPPLY - tokensOutOfCirculation;
        _setTotalSupply(tokensInCirculation);
        return true;
    }


     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
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
        _approve(from, msg.sender, _allowances[from][msg.sender].sub(value));
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

     
    function _transfer(address from, address to, uint256 value) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(value);
        
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
     function _setTotalSupply(uint256 totalInCirculation) internal {
         _totalSupply = totalInCirculation;
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

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(value));
    }
}