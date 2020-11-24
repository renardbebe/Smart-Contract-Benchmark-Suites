 

 
 
pragma solidity ^0.5.0;
 
interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
 
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
 
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
 
contract ERC20Detailed is IERC20 {
 
  uint8 private _Tokendecimals;
  string private _Tokenname;
  string private _Tokensymbol;
 
  constructor(string memory name, string memory symbol, uint8 decimals) public {
   
   _Tokendecimals = decimals;
    _Tokenname = name;
    _Tokensymbol = symbol;
   
  }
 
  function name() public view returns(string memory) {
    return _Tokenname;
  }
 
  function symbol() public view returns(string memory) {
    return _Tokensymbol;
  }
 
  function decimals() public view returns(uint8) {
    return _Tokendecimals;
  }
}
 
 
 
contract INC8Token is ERC20Detailed {
 
  using SafeMath for uint256;
  mapping (address => uint256) private _INC8TokenBalances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "Incinerate Token v2";
  string constant tokenSymbol = "INC8";
  uint8  constant tokenDecimals = 2;
  uint256 _totalSupply = 100000000;
 
 
 
 
  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }
 
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
 
  function balanceOf(address owner) public view returns (uint256) {
    return _INC8TokenBalances[owner];
  }
 
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
 
 
 
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _INC8TokenBalances[msg.sender]);
    require(to != address(0));
 
    uint256 INC8TokenDecay = value.div(20);
    uint256 tokensToTransfer = value.sub(INC8TokenDecay);
 
    _INC8TokenBalances[msg.sender] = _INC8TokenBalances[msg.sender].sub(value);
    _INC8TokenBalances[to] = _INC8TokenBalances[to].add(tokensToTransfer);
 
    _totalSupply = _totalSupply.sub(INC8TokenDecay);
 
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), INC8TokenDecay);
    return true;
  }
 
  function multiTransfer(address[] memory receivers, uint256[] memory amounts) public {
    for (uint256 i = 0; i < receivers.length; i++) {
      transfer(receivers[i], amounts[i]);
    }
  }
 
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
 
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _INC8TokenBalances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));
 
    _INC8TokenBalances[from] = _INC8TokenBalances[from].sub(value);
 
    uint256 INC8TokenDecay = value.div(20);
    uint256 tokensToTransfer = value.sub(INC8TokenDecay);
 
    _INC8TokenBalances[to] = _INC8TokenBalances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(INC8TokenDecay);
 
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
 
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), INC8TokenDecay);
 
    return true;
  }
 
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
 
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
 
  function _mint(address account, uint256 amount) internal {
    require(amount != 0);
    _INC8TokenBalances[account] = _INC8TokenBalances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }
 
  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }
 
  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _INC8TokenBalances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _INC8TokenBalances[account] = _INC8TokenBalances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
 
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}