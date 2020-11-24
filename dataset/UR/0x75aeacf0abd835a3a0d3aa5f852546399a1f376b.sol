 
contract DragonCoin is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (uint => address) private _dragonClaimers;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    event DragonBorn(uint index, address owner);

    uint public endDate;

    string public constant name = "Daenerys Coin";

    string public constant symbol = "DAE";

    uint8 public constant decimals = 0;

     
     
    constructor(uint end) public {
      endDate = end;
    }

     
    function totalSupply() public view returns (uint256) {
        return 3;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
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
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function birthDragon(uint index) public {
        require(now < endDate, "Cannot create a new dragon after the finale");
        require(index < 3, "There are only 3 dragons poossible");
        require(_dragonClaimers[index] == address(0), "Cannot claim the same dragon twice");
        require(_dragonClaimers[0] != msg.sender, "Don't be greedy, you can only claim 1 dragon");
        require(_dragonClaimers[1] != msg.sender, "Don't be greedy, you can only claim 1 dragon");
        require(_dragonClaimers[2] != msg.sender, "Don't be greedy, you can only claim 1 dragon");
        
        _dragonClaimers[index] = msg.sender;
        emit DragonBorn(index, msg.sender);
        _mint(msg.sender, 1);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}