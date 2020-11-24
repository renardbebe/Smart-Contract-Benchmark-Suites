 

pragma solidity ^0.4.25;

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
    require(c / a == b, "overflow in multiplies operation.");

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "b must be greater than zero.");
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "a must be greater than b or equal to b.");
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "c must be greater than b or equal to a.");

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "b must not be zero.");
    return a % b;
  }
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner.");
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "address is zero.");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}


 
contract Pausable is Ownable {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused, "Paused.");
    _;
  }

   
  modifier whenPaused() {
    require(_paused, "Not paused.");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

contract Token is IERC20, Pausable {
  using SafeMath for uint256;

  string private _name;

  string private _symbol;

  uint8 private _decimals;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  constructor(
    uint256 initialSupply,
    string memory tokenName,
    string memory tokenSymbol,
    uint8 tokenDecimals
  ) public {
     
    _name = tokenName;
     
    _symbol = tokenSymbol;
     
    _decimals = tokenDecimals;

     
    _totalSupply = initialSupply * (10 ** uint256(_decimals));
     
    _balances[msg.sender] = _totalSupply;
  }

   
  function name() public view returns(string memory) {
    return _name;
  }

   
  function symbol() public view returns(string memory) {
    return _symbol;
  }

   
  function decimals() public view returns(uint8) {
    return _decimals;
  }

   
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

   
  function transfer(
    address to,
    uint256 value
    )
      public
      whenNotPaused
      returns (bool)
  {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(
    address spender,
    uint256 value
    )
      public
      whenNotPaused
      returns (bool)
  {
    require(spender != address(0), "address is zero.");

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
    whenNotPaused
    returns (bool)
  {
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
    )
    public
    whenNotPaused
    returns (bool)
  {
    require(spender != address(0), "address is zero.");

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
    whenNotPaused
    returns (bool)
  {
    require(spender != address(0), "address is zero.");

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0), "address is zero.");

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }
}