 

pragma solidity ^0.4.24;

 

 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(msg.sender));
    _;
  }

   
  function isOwner(address account) public view returns(bool) {
    return account == _owner;
  }

   
  function transferOwnership(address newOwner)
    public
    onlyOwner
  {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner)
    internal
  {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}

 

 
contract Pausable is Ownable {
  event Paused();
  event Unpaused();

  bool private _paused;

  constructor() public {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused);
    _;
  }

   
  modifier whenPaused() {
    require(_paused);
    _;
  }

   
  function pause()
    public
    onlyOwner
    whenNotPaused
  {
    _paused = true;
    emit Paused();
  }

   
  function unpause()
    public
    onlyOwner
    whenPaused
  {
    _paused = false;
    emit Unpaused();
  }
}

 

 
contract Operable is Pausable {
  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  mapping (address => bool) private _operators;

  constructor() public {
    _addOperator(msg.sender);
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  function isOperator(address account)
    public
    view
    returns (bool) 
  {
    require(account != address(0));
    return _operators[account];
  }

  function addOperator(address account)
    public
    onlyOwner
  {
    _addOperator(account);
  }

  function removeOperator(address account)
    public
    onlyOwner
  {
    _removeOperator(account);
  }

  function _addOperator(address account)
    internal
  {
    require(account != address(0));
    _operators[account] = true;
    emit OperatorAdded(account);
  }

  function _removeOperator(address account)
    internal
  {
    require(account != address(0));
    _operators[account] = false;
    emit OperatorRemoved(account);
  }
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

 

contract ManagedToken is Operable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  uint256 private _totalSupply;

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address account) public view returns (uint256) {
    return _balances[account];
  }

   
  function transferFrom(address from, address to, uint256 value)
    public
    onlyOperator
    whenNotPaused
    returns (bool)
  {
    _transfer(from, to, value);
    return true;
  }

   
   
   
   
   
   
   
   

   
  function mint(address to, uint256 value)
    public
    onlyOperator
    whenNotPaused
    returns (bool)
  {
    _mint(to, value);
    return true;
  }

   
  function burn(address from, uint256 value)
    public
    onlyOperator
    whenNotPaused
    returns (bool)
  {
    _burn(from, value);
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
}

 

contract XFTToken is ManagedToken {
  string public constant name = 'XFT Token';
  string public constant symbol = 'XFT';
  uint8 public constant decimals = 18;
  string public constant version = '1.0';
}