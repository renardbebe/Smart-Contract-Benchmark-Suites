 

pragma solidity ^0.5.8;

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

}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  event Transfer(address indexed from,address indexed to,uint256 value);
  event Approval(address indexed owner,address indexed spender,uint256 value);
}

contract Owned {
  address owner;
  constructor () public {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner,"Only owner can do it.");
    _;
  }
}

contract BlockBankToken is IERC20 , Owned{

  string public constant name = "BlockBankToken";
  string public constant symbol = "BBK";
  uint8 public constant decimals = 18;

  uint256 private constant INITIAL_SUPPLY = 5000000000 * (10 ** uint256(decimals));

  using SafeMath for uint256;

  mapping (address => uint256) private _balances;
  
  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  uint256 public beginTime = 0;

  function setBeginTime(uint256 _begin) onlyOwner public{
    beginTime = _begin;
  }

  function allocateTokenByType(address accountAddress,uint256 amount) onlyOwner public {
    require(accountAddress != address(0x0), "accountAddress not right");

    amount = amount.mul(10 ** uint256(decimals));
    
    _balances[accountAddress] = _balances[accountAddress].add(amount);
    _balances[msg.sender] = _balances[msg.sender].sub(amount);
    
  }

  event Burn(address indexed from, uint256 value);

  function burn(uint256 _value) onlyOwner public returns (bool success) {
    require(_value > 0, "_value > 0");
    _value = _value.mul(10 ** uint256(decimals));
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] = _balances[msg.sender].sub(_value);
    _totalSupply = _totalSupply.sub(_value);
    
    emit Burn(msg.sender, _value);
    return true;
  }

  constructor() public {
    _mint(msg.sender, INITIAL_SUPPLY);
  }

  function _mint(address account, uint256 value) internal {
    require(account != address(0x0));
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
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

  function transfer(address to, uint256 value) public returns (bool) {
    if(_canTransfer(msg.sender,value)){ 
      _transfer(msg.sender, to, value);
      return true;
    } else {
      return false;
    }
  }

  function _canTransfer(address from,uint256 _amount) private view returns (bool) {
    if(now < beginTime){
      return false;
    }
    if((balanceOf(from))<=0){
      return false;
    }
    if(balanceOf(from).sub(_amount) < 0){
      return false;
    }
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
    
    if (_canTransfer(from, value)) {
        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    } else {
        return false;
    }
  }

  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));
    
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
    
  }

}