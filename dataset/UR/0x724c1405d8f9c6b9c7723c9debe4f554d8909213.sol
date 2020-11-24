 

pragma solidity ^0.4.24;

 

 
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

 

contract TokenDistributor is Ownable {
  using SafeMath for uint256;

   
  event Started();
  event AssignToken(address indexed account, uint256 value);
  event ClaimToken(address indexed account, uint256 value);

   
  ERC20 private _token;
  bool private _started;
  mapping (address => uint256) private _tokens;
  uint256 private _totalToken;

  constructor(ERC20 token) public {
    require(token != address(0));

    _token = token;
    _started = false;
  }

   
  modifier whenStarted() {
    require(_started);
    _;
  }

   
  modifier whenNotStarted() {
    require(!_started);
    _;
  }

   
  function start() public onlyOwner whenNotStarted {
    require(_token.balanceOf(address(this)) == _totalToken);

    _started = true;
    emit Started();
  }

   
  function isStarted() public view returns (bool) {
    return _started;
  }

   
  function totalToken() public view returns (uint256) {
    return _totalToken;
  }

   
  function tokenOf(address account) public view returns (uint256) {
    return _tokens[account];
  }

   
  function assignToken(address account, uint256 value) public onlyOwner whenNotStarted {
    require(account != address(0));
    require(_tokens[account] == 0);

    _totalToken = _totalToken.add(value);
    _tokens[account] = value;

    emit AssignToken(account, value);
  }

   
  function multipleAssignToken(address[] accounts, uint256[] values) public {
    require(accounts.length > 0);
    require(accounts.length == values.length);

    for (uint256 i = 0; i < accounts.length; i++) {
      assignToken(accounts[i], values[i]);
    }
  }

   
  function claimToken() public {
    claimTokenFor(msg.sender);
  }

   
  function claimTokenFor(address account) public whenStarted {
    require(account != address(0));

    uint256 value = _tokens[account];
    require(value > 0);

    _tokens[account] = 0;
    _token.transfer(account, value);

    emit ClaimToken(account, value);
  }

   
  function multipleClaimToken(address[] accounts) public {
    require(accounts.length > 0);

    for (uint256 i = 0; i < accounts.length; i++) {
      claimTokenFor(accounts[i]);
    }
  }

   
  function withdrawExcessToken(address account) public onlyOwner {
    require(account != address(0));

    uint256 contractToken = _token.balanceOf(address(this));
    uint256 excessToken = contractToken.sub(_totalToken);
    require(excessToken > 0);

    _token.transfer(account, excessToken);
  }
}