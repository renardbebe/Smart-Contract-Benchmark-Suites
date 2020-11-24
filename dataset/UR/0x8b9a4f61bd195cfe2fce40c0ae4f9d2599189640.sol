 
contract NedCoin is IERC20 {
    uint rand_nonce;

    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

    event NedDead(address from, address to, uint256 value);

    uint public endDate;

    string public constant name = "Ned Coin";

    string public constant symbol = "NED";

    uint8 public constant decimals = 18;

     
    uint public deathChance;

     
     
    constructor(uint end, uint deathDivisor) public {
      endDate = end;
      deathChance = deathDivisor;
    }

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
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

         
        bool nedDies = (random() == 0);

        if (nedDies) {
          emit NedDead(from, to, value);
          _burn(from, value);
        } else {
          _balances[from] = _balances[from].sub(value);
          _balances[to] = _balances[to].add(value);
          emit Transfer(from, to, value);
        }
    }

     
    function getSomeNed() public {
        require(now < endDate, "Cannot mint new coins after the finale");
        uint256 amountAdded = 100 * 1e18;
        _mint(msg.sender, amountAdded);
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

     
    function random() internal returns (uint) {
      uint random_num = uint(keccak256(abi.encodePacked(now, msg.sender, rand_nonce))) % deathChance;
      rand_nonce++;
      return random_num;
    }
}