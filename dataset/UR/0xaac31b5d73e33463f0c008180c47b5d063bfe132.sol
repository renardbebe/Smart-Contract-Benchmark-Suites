 

pragma solidity ^0.4.25;

 
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


contract Freezable is Ownable{
  mapping (address => bool) public frozenAccount;
    
  event FrozenFunds(address target, bool frozen);
    
  modifier whenUnfrozen(address target) {
    require(!frozenAccount[target]);
    _;
  }
  
  function freezeAccount(address target, bool freeze) onlyOwner public{
    frozenAccount[target] = freeze;
    emit FrozenFunds(target, freeze);
  }
}

contract XERC20 is Pausable, Freezable {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  event Transfer(address indexed from, address indexed to, uint256 value);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  event Burn(address account, uint256 value);
  
  function burn(address account, uint256 value) external onlyOwner returns (bool) {
    _burn(account, value);
    emit Burn(account, value);
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
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(value);
    _burn(account, value);
  }

}


contract UCXToken is XERC20 {
  string public constant name = "UCXToken";
  string public constant symbol = "UCX";
  uint8 public constant decimals = 18;
  uint256 public constant INITIAL_SUPPLY = 2100000000 * (10 ** uint256(decimals));

  address address1 = 0x777721dEe44137F84D016D9B8f4D5F654CE5c777;
  address address2 = 0x7770533000cB5CF3f55a20caF22c60438F867777;
  address address3 = 0x7772082428388bd2007822FaDedF33697fF3e777;
  address address4 = 0x777036867957eEE02181157093131CAE6D2fd777;
  address address5 = 0x7776BdF1d3db7536e12143785cD107FdF2cF6777;
  address address6 = 0x7778211a82cDC694c59Dd7451e3FE17E14987777;
  address address7 = 0x777775152FA83fb685d114A6B1302432A4ff8777;
  address address8 = 0x7770ae1b5e71b5FccF1eA236C5CD069850817777;
  address address9 = 0x7776312f8d9aDd9542F4C4a343cC55fBB3bf1777;
  address address10 = 0x7773951672A5A097bAF3AC40bc425066a00d7777;
  address address11 = 0x7771232DDd8d5a4d93Ea958C7B99611B2fe17777;
  address address12 = 0x7778B8b23b7D872e02afb9A7413d103775dC5777;

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);

    transfer(address1, 255000000 * (10 ** uint256(decimals)));
    transfer(address2, 34000000 * (10 ** uint256(decimals)));
    transfer(address3, 34000000 * (10 ** uint256(decimals)));
    transfer(address4, 34000000 * (10 ** uint256(decimals)));
    transfer(address5, 34000000 * (10 ** uint256(decimals)));
    transfer(address6, 34000000 * (10 ** uint256(decimals)));
    transfer(address7, 340000000 * (10 ** uint256(decimals)));
    transfer(address8, 510000000 * (10 ** uint256(decimals)));
    transfer(address9, 170000000 * (10 ** uint256(decimals)));
    transfer(address10, 170000000 * (10 ** uint256(decimals)));
    transfer(address11, 85000000 * (10 ** uint256(decimals)));
    transfer(address12, 400000000 * (10 ** uint256(decimals)));

    freezeAccount(address12,true);
  }

}