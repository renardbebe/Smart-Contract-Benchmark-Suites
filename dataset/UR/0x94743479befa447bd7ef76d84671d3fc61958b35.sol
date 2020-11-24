 

pragma solidity 0.5.0;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint);
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract Ownable {
  address private _owner;
  address private _operator;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  event OperatorTransferred(address indexed previousOperator, address indexed newOperator);

   
  constructor() public {
    _owner = msg.sender;
    _operator = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
    emit OperatorTransferred(address(0), _operator);
  }

   
  function owner() public view returns (address) {
    return _owner;
  }

   
  function operator() public view returns (address) {
    return _operator;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  modifier onlyOwnerOrOperator() {
    require(isOwner() || isOperator());
    _;
  }


   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }

   
  function isOperator() public view returns (bool) {
    return msg.sender == _operator;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));

    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }

   
  function transferOperator(address newOperator) public onlyOwner {
    require(newOperator != address(0));

    emit OperatorTransferred(_operator, newOperator);
    _operator = newOperator;
  }


}


 
contract Pausable is Ownable {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor () internal {
    _paused = false;
  }

   
  function paused() public view returns (bool) {
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

   
  function pause() public onlyOwnerOrOperator whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyOwnerOrOperator whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 
library SafeMath {

   
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }

    uint c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint a, uint b) internal pure returns (uint) {
     
    require(b > 0);
    uint c = a / b;
     

    return c;
  }

   
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    uint c = a - b;

    return c;
  }

   
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint a, uint b) internal pure returns (uint) {
    require(b != 0);
    return a % b;
  }

}


 
contract StandardToken is ERC20, Pausable {
  using SafeMath for uint;

  mapping (address => uint) private _balances;

  mapping (address => mapping (address => uint)) private _allowed;

  uint private _totalSupply;

   
  function totalSupply() public view returns (uint) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint) {
    return _balances[owner];
  }

   
  function allowance(address owner, address spender) public view returns (uint) {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint value) public whenNotPaused returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint value) public whenNotPaused returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint value) public whenNotPaused returns (bool) {
    _transferFrom(from, to, value);
    return true;
  }

   
  function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }

   
  function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }

   
  function _transfer(address from, address to, uint value) internal {
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _transferFrom(address from, address to, uint value) internal {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
  }

   
  function _mint(address account, uint value) internal {
    require(account != address(0));

    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(uint value) internal {
    _totalSupply = _totalSupply.sub(value);
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    emit Transfer(msg.sender, address(0), value);
  }

   
  function _approve(address owner, address spender, uint value) internal {
    require(spender != address(0));
    require(owner != address(0));

    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }
}

 
contract MintableToken is StandardToken {
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address to, uint amount) public whenNotPaused onlyOwner canMint returns (bool) {
    _mint(to, amount);
    return true;
  }

   
  function finishMinting() public whenNotPaused onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 
contract BurnableToken is MintableToken {
   
  function burn(uint value) public whenNotPaused onlyOwner returns (bool) {
    _burn(value);
    return true;
  }
}



 
contract LockableToken is BurnableToken {

  using SafeMath for uint;

   
  struct Lock {
    uint amount;
    uint expiresAt;
  }

  mapping (address => Lock[]) public grantedLocks;

   
  function transfer(address to, uint value) public whenNotPaused returns (bool) {
    _verifyTransferLock(msg.sender, value);
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function transferFrom(address from, address to, uint value) public whenNotPaused returns (bool) {
    _verifyTransferLock(from, value);
    _transferFrom(from, to, value);
    return true;
  }

   
  function addLock(address granted, uint amount, uint expiresAt) public whenNotPaused onlyOwnerOrOperator {
    require(amount > 0);
    require(expiresAt > now);

    grantedLocks[granted].push(Lock(amount, expiresAt));
  }

   
  function deleteLock(address granted, uint8 index) public whenNotPaused onlyOwnerOrOperator {
    require(grantedLocks[granted].length > index);

    uint len = grantedLocks[granted].length;
    if (len == 1) {
      delete grantedLocks[granted];
    } else {
      if (len - 1 != index) {
        grantedLocks[granted][index] = grantedLocks[granted][len - 1];
      }
      delete grantedLocks[granted][len - 1];
    }
  }

   
  function _verifyTransferLock(address from, uint value) internal view {
    uint lockedAmount = getLockedAmount(from);
    uint balanceAmount = balanceOf(from);

    require(balanceAmount.sub(lockedAmount) >= value);
  }

   
  function getLockedAmount(address granted) public view returns(uint) {
    uint lockedAmount = 0;

    uint len = grantedLocks[granted].length;
    for (uint i = 0; i < len; i++) {
      if (now < grantedLocks[granted][i].expiresAt) {
        lockedAmount = lockedAmount.add(grantedLocks[granted][i].amount);
      }
    }
    return lockedAmount;
  }
}

 
contract MzcToken is LockableToken {

  string public constant name = "Muze creative";
  string public constant symbol = "MZC";
  uint32 public constant decimals = 18;

  uint public constant INITIAL_SUPPLY = 5000000000e18;

   
  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
    emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
  }
}