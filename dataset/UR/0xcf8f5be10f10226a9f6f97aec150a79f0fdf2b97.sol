 

pragma solidity 0.4.24;
 
 
 
 
 
interface ITokenPool {
    function balanceOf(uint128 id) public view returns (uint256);
    function allocate(uint128 id, uint256 value) public;
    function withdraw(uint128 id, address to, uint256 value) public;
    function complete() public;
}

contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
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
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract Pausable is Ownable {

    bool public paused = false;

    event Pause();
    event Unpause();

     
    modifier whenNotPaused() {
        require(!paused, "Has to be unpaused");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Has to be paused");
        _;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpause();
    }
}

contract OperatorRole {
    using Roles for Roles.Role;

    event OperatorAdded(address indexed account);
    event OperatorRemoved(address indexed account);

    Roles.Role private operators;

    modifier onlyOperator() {
        require(isOperator(msg.sender), "Can be called only by contract operator");
        _;
    }

    function isOperator(address account) public view returns (bool) {
        return operators.has(account);
    }

    function _addOperator(address account) internal {
        operators.add(account);
        emit OperatorAdded(account);
    }

    function _removeOperator(address account) internal {
        operators.remove(account);
        emit OperatorRemoved(account);
    }
}

contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string name, string symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }

   
  function name() public view returns(string) {
    return _name;
  }

   
  function symbol() public view returns(string) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

contract PausableToken is ERC20, Pausable {

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

contract IPCOToken is PausableToken, ERC20Detailed {
    string public termsUrl = "http://xixoio.com/terms";
    uint256 public hardCap;

     
    constructor(string _name, string _symbol, uint256 _hardCap) ERC20Detailed(_name, _symbol, 18) public {
        require(_hardCap > 0, "Hard cap can't be zero.");
        require(bytes(_name).length > 0, "Name must be defined.");
        require(bytes(_symbol).length > 0, "Symbol must be defined.");
        hardCap = _hardCap;
        pause();
    }

     
    function mint(address to, uint256 value) public onlyOwner returns (bool) {
        require(totalSupply().add(value) <= hardCap, "Mint of this amount would exceed the hard cap.");
        _mint(to, value);
        return true;
    }
}


contract TokenSale is Ownable, OperatorRole {
    using SafeMath for uint256;

    bool public finished = false;
    uint256 public dailyLimit = 100000 ether;
    mapping(uint256 => uint256) public dailyThroughput;

    IPCOToken public token;
    ITokenPool public pool;

    event TransactionId(uint128 indexed id);

     
    constructor(address tokenAddress, address poolAddress) public {
        addOperator(msg.sender);
        token = IPCOToken(tokenAddress);
        pool = ITokenPool(poolAddress);
    }

     
    function throughputToday() public view returns (uint256) {
        return dailyThroughput[currentDay()];
    }

     
     
     

    function mint(address to, uint256 value, uint128 txId) public onlyOperator amountInLimit(value) {
        _mint(to, value, txId);
    }

    function mintToPool(uint128 account, uint256 value, uint128 txId) public onlyOperator amountInLimit(value) {
        _mintToPool(account, value, txId);
    }

    function withdraw(uint128 account, address to, uint256 value, uint128 txId) public onlyOperator amountInLimit(value) {
        _withdraw(account, to, value, txId);
    }

    function batchMint(address[] receivers, uint256[] values, uint128[] txIds) public onlyOperator amountsInLimit(values) {
        require(receivers.length > 0, "Batch can't be empty");
        require(receivers.length == values.length && receivers.length == txIds.length, "Invalid batch");
        for (uint i; i < receivers.length; i++) {
            _mint(receivers[i], values[i], txIds[i]);
        }
    }

    function batchMintToPool(uint128[] accounts, uint256[] values, uint128[] txIds) public onlyOperator amountsInLimit(values) {
        require(accounts.length > 0, "Batch can't be empty");
        require(accounts.length == values.length && accounts.length == txIds.length, "Invalid batch");
        for (uint i; i < accounts.length; i++) {
            _mintToPool(accounts[i], values[i], txIds[i]);
        }
    }

    function batchWithdraw(uint128[] accounts, address[] receivers, uint256[] values, uint128[] txIds) public onlyOperator amountsInLimit(values) {
        require(accounts.length > 0, "Batch can't be empty.");
        require(accounts.length == values.length && accounts.length == receivers.length && accounts.length == txIds.length, "Invalid batch");
        for (uint i; i < accounts.length; i++) {
            _withdraw(accounts[i], receivers[i], values[i], txIds[i]);
        }
    }

     
     
     

    function unrestrictedMint(address to, uint256 value, uint128 txId) public onlyOwner {
        _mint(to, value, txId);
    }

    function unrestrictedMintToPool(uint128 account, uint256 value, uint128 txId) public onlyOwner {
        _mintToPool(account, value, txId);
    }

    function unrestrictedWithdraw(uint128 account, address to, uint256 value, uint128 txId) public onlyOwner {
        _withdraw(account, to, value, txId);
    }

    function addOperator(address operator) public onlyOwner {
        _addOperator(operator);
    }

    function removeOperator(address operator) public onlyOwner {
        _removeOperator(operator);
    }

    function replaceOperator(address operator, address newOperator) public onlyOwner {
        _removeOperator(operator);
        _addOperator(newOperator);
    }

    function setDailyLimit(uint256 newDailyLimit) public onlyOwner {
        dailyLimit = newDailyLimit;
    }

     
    function finish() public onlyOwner {
        finished = true;
        if (token.paused()) token.unpause();
        pool.complete();
        token.renounceOwnership();
    }

     
     
     

    function _mint(address to, uint256 value, uint128 txId) internal {
        token.mint(to, value);
        emit TransactionId(txId);
    }

    function _mintToPool(uint128 account, uint256 value, uint128 txId) internal {
        token.mint(address(pool), value);
        pool.allocate(account, value);
        emit TransactionId(txId);
    }

    function _withdraw(uint128 account, address to, uint256 value, uint128 txId) internal {
        pool.withdraw(account, to, value);
        emit TransactionId(txId);
    }

    function _checkLimit(uint256 value) internal {
        uint256 newValue = throughputToday().add(value);
        require(newValue <= dailyLimit, "Amount to be minted exceeds day limit.");
        dailyThroughput[currentDay()] = newValue;
    }

     
     
     

    modifier amountInLimit(uint256 value) {
        _checkLimit(value);
        _;
    }

    modifier amountsInLimit(uint256[] values) {
        uint256 sum = 0;
        for (uint i; i < values.length; i++) {
            sum = sum.add(values[i]);
        }
        _checkLimit(sum);
        _;
    }

     
     
     

    function currentDay() private view returns (uint256) {
         
        return now / 1 days;
    }
}