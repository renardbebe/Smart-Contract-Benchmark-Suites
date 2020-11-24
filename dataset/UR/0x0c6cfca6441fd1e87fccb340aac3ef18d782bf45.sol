 

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

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
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

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract Pausable is Ownable {
  event Pause();
 
  event Unpause();
 
  bool public paused = false;

  modifier whenNotPaused() {
      require(!paused);
      _;
  }

  modifier whenPaused() {
      require(paused);
      _;
  }

  function pause() onlyOwner whenNotPaused public {
      paused = true;
      emit Pause();
  }

  function unpause() onlyOwner whenPaused public {
      paused = false;
      emit Unpause();
  }
}


contract Freezable is Ownable {
  mapping (address => bool) public frozenAccount;
    
  event FrozenFunds(address target, bool frozen);
    
  modifier whenUnfrozen(address target) {
    require(!frozenAccount[target]);
    _;
  }
  
  function freezeAccount(address target, bool freeze) onlyOwner public {
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }
}


contract Suspendable is Ownable {
  mapping (address => bool) public suspendedAccount;
    
  event SuspendedFunds(address target, bool suspended);
  
  function suspendAccount(address target, bool suspend) onlyOwner public {
    _suspendAccount(target,suspend);
  }
  
  function _suspendAccount(address target, bool suspend) internal {
    suspendedAccount[target] = suspend;
    emit SuspendedFunds(target, suspend);
  }
}


contract SafeMode is Ownable {
  event TurnOnSafeMode();
 
  event TurnOffSafeMode();
 
  bool public safeMode = false;

  modifier whenNotSafeMode() {
      require(!safeMode);
      _;
  }

  modifier whenSafeMode() {
      require(safeMode);
      _;
  }

  function turnOn() onlyOwner whenNotSafeMode public {
      safeMode = true;
      emit TurnOnSafeMode();
  }

  function turnOff() onlyOwner whenSafeMode public {
      safeMode = false;
      emit TurnOffSafeMode();
  }
}


contract Whitelist is Ownable {
    event AddWhitelist(address target, bool add);
    
    mapping (address => bool) public whitelist;
    
    function addWhitelist(address target, bool add) onlyOwner public {
        whitelist[target] = add;
        emit AddWhitelist(target, add);
  }
}


contract ERC20 is Pausable, Freezable, Suspendable, SafeMode, Whitelist {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  event Burn(address account, uint256 value);
  
  function burn(uint256 value) external returns (bool) {
    _burn(msg.sender, value);
    emit Burn(msg.sender, value);
    return true;
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

  function transfer(address to, uint256 value) public whenNotPaused whenUnfrozen(msg.sender) returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

  function transferFrom(address from, address to, uint256 value) public whenNotPaused whenUnfrozen(from) returns (bool) {
    require(value <= _allowed[from][msg.sender]);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

  function increaseAllowance(address spender, uint256 addedValue) public whenNotPaused returns(bool)
  {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function decreaseAllowance(address spender, uint256 subtractedValue) public whenNotPaused returns(bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

  function _transfer(address from, address to, uint256 value) internal {
    if (safeMode) {
        if (whitelist[from]) {
            require(value <= _balances[from]);
        } else {
            require(!suspendedAccount[from]);
            require(value == _balances[from]);
        }
    } else {
        require(value <= _balances[from]);
    }
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
    if (safeMode && !whitelist[from]) {
        _suspendAccount(from, true);
    } 
  }

  function _mint(address account, uint256 value) internal {
    require(account != address(0));
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

  function _burn(address account, uint256 value) internal {
    require(account != address(0));
    require(value <= _balances[account]);
    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }
}


contract LNB is ERC20 {
  string public constant name = "LNB";
  string public constant symbol = "LNB";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 300000000 * (10 ** uint256(decimals));

  address address1 = 0x777B005B9877bd37D0ea389eC4AF2F34f0c9C777;
  address address2 = 0x777e0a0Ff858882045eD9FEb1777Ae49c5Ef0777;

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
    transfer(address1, 150000000 * (10 ** uint256(decimals)));
    transfer(address2, 30000000 * (10 ** uint256(decimals)));
  }
}