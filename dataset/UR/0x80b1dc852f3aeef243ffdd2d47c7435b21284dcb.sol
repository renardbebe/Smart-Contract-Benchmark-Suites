 

pragma solidity ^0.5.9;

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

  string private _name;
  string private _symbol;
  uint8 private _decimals;

  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
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
}

contract Miasma is ERC20Detailed {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => uint256) private _SavedDividend;
  mapping (address => bool) public _RestrictedFromDividend;
  mapping (address => uint256) private ClaimTime;

  string constant tokenName = "Miasma";
  string constant tokenSymbol = "MIA";
  uint8  constant tokenDecimals = 18;
  uint256 _totalSupply = 100000000000000000000000000;


  
  
  

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
    _SavedDividend[msg.sender] = 0;
    _RestrictedFromDividend[address(this)] = true;

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
  
  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));

    uint256 tokensToBurn = value.mul(7).div(10000);
    uint256 tokensToDividend = value.mul(3).div(10000);
    uint256 tokensToTransfer = value.sub(tokensToBurn).sub(tokensToDividend);

    _balances[msg.sender] = _balances[msg.sender].sub(tokensToTransfer).sub(tokensToDividend).sub(tokensToBurn);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(this)] = _balances[address(this)].add(tokensToDividend);
    _balances[address(0)] = _balances[address(0)].add(tokensToBurn);

    _totalSupply = _totalSupply.sub(tokensToBurn);
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    emit Transfer(msg.sender, address(this), tokensToDividend);
    
    return true;
  }
  
  function CheckTotalDividendPool() public view returns (uint256) {
      return _balances[address(this)];
  }
 
  
  function ViewDividendOwed(address _addr) public view returns (uint256) {
      uint256 value = (_balances[_addr].div(10**18));
      uint256 v2 = (_balances[address(this)]).div(10**18);
      if (!_RestrictedFromDividend[_addr]) {
       return v2.mul(value).div(100000000);
      }
      else {
          return 0;
      }
  }
  
      
  
  function WithdrawDividend(address) public {
        uint256 value = _balances[msg.sender].div(10**18);
        uint256 v2 = _balances[address(this)].div(10**18);
        if (!_RestrictedFromDividend[msg.sender]) {
            _SavedDividend[msg.sender] = (v2.mul(value).div(100000000)).mul(10**18);  
            uint256 DividendsToBurn = _SavedDividend[msg.sender].mul(10).div(10000);
            uint256 DividendstoDividend = _SavedDividend[msg.sender].sub(DividendsToBurn);
    
            _balances[address(this)] = _balances[address(this)].sub(DividendstoDividend).sub(DividendsToBurn);
            _balances[msg.sender] = _balances[msg.sender].add(DividendstoDividend);
            _balances[address(0)] = _balances[address(0)].add(DividendsToBurn);
            
            _totalSupply = _totalSupply.sub(DividendsToBurn);
            _RestrictedFromDividend[msg.sender] = true;
            ClaimTime[msg.sender] = now;
    
            emit Transfer(address(this), msg.sender, DividendstoDividend);
            emit Transfer(address(this), address(0), DividendsToBurn);
        }
        
        else {
            emit Transfer (address(this), msg.sender, 0);
        }
      
 }

 

  
function ShouldIMakeMyselfEligible(address _addr) public view returns (bool) {
    if (
        _RestrictedFromDividend[_addr] &&
        now >= (ClaimTime[_addr] + 14 days)
    ) {
        return true;
    } else {
        return false;
    }
}
  
function MakeEligible(address) public {
    if (now >= (ClaimTime[msg.sender] + 14 days)) {
        _RestrictedFromDividend[msg.sender] = false;
    } else {
        _RestrictedFromDividend[msg.sender] = true;
    }
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
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurn = value.div(100).mul(7);
    uint256 tokensToDividend = value.div(100).mul(3);
    uint256 tokensToTransfer = value.sub(tokensToBurn).sub(tokensToDividend);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);
    emit Transfer(from, address(this), tokensToBurn);

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
    _balances[account] = _balances[account].add(amount);
    emit Transfer(address(0), account, amount);
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }

  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }

  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}