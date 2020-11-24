 

pragma solidity ^0.5.6;

 
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

 
interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value) external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external
    returns (bool);

  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external
    view
    returns (uint256);

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract IDEX is IERC20 {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;
  mapping(address => mapping(address => uint256)) private _allowed;
  uint256 private _totalSupply;
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  IERC20 _oldToken;

  event Swap(address indexed owner, uint256 value);

  constructor(
    string memory name,
    string memory symbol,
    uint8 decimals,
    IERC20 oldToken
  ) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
    _totalSupply = oldToken.totalSupply();
    _balances[address(this)] = _totalSupply;
    _oldToken = oldToken;

    emit Transfer(address(0), address(this), _totalSupply);
  }

  function swap(uint256 value) external returns (bool) {
    require(
      _oldToken.transferFrom(msg.sender, address(this), value),
      "AURA transfer failed"
    );
    require(this.transfer(msg.sender, value), "IDEX transfer failed");

    emit Swap(msg.sender, value);

    return true;
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

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender)
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
    _approve(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
  {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }

   
  function increaseAllowance(address spender, uint256 addedValue)
    public
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowed[msg.sender][spender].add(addedValue)
    );
    return true;
  }

   
  function decreaseAllowance(address spender, uint256 subtractedValue)
    public
    returns (bool)
  {
    _approve(
      msg.sender,
      spender,
      _allowed[msg.sender][spender].sub(subtractedValue)
    );
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(from != address(0), "Invalid from");
    require(to != address(0), "Invalid to");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0), "Invalid spender");

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }
}