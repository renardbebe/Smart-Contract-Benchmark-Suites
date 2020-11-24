 

pragma solidity ^0.5.11;

interface StandardERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address _owner) external view returns (uint256);
  function allowance(address _owner, address _spender) external view returns (uint256);
  function transfer(address _to, uint256 _value) external returns (bool);
  function approve(address _spender, uint256 _value) external returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) { return 0; }
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

contract EXM is StandardERC20 {
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

  string public name;
  uint8  public decimals;
  string public symbol;
  string public version;

  constructor() public {
    name = "EXM 102";
    decimals = 18;
    symbol = "EXM";
    version = "V1.0";
    _totalSupply = 100 * 10**uint(6) * 10**uint(decimals);
    _balances[msg.sender] = _totalSupply;
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address _owner) public view returns (uint256) {
    return _balances[_owner];
  }
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return _allowed[_owner][_spender];
  }
  function transfer(address _to, uint256 _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }
  function approve(address _spender, uint256 _value) public returns (bool) {
    require(_spender != address(0));
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }
  function _transfer(address _from, address _to, uint256 _value) internal {
    require(_to != address(0));
    _balances[_from] = _balances[_from].sub(_value);
    _balances[_to] = _balances[_to].add(_value);
    emit Transfer(_from, _to, _value);
  }
}