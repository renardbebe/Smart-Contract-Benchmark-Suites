 

 

pragma solidity ^0.5.1;

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
  uint256 private _decimals;

  constructor(string memory name, string memory symbol, uint256 decimals) public {
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

  function decimals() public view returns(uint256) {
    return _decimals;
  }
}

contract FailToken is ERC20Detailed {
 
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  string constant tokenName = "FailToken";
  string constant tokenSymbol = "FAIL";
  uint256  constant tokenDecimals = 18;
  uint256 _totalSupply = 150000000000000000000000;           
  uint256 constant maxCap = 500000000000000000000000;        
  uint256 constant halfCap = 250000000000000000000000;       
  uint256 constant minCap = 50000000000000000000000;         

  uint256 public basePercent = 100;
  bool capReached ;

  address withdraw_token_contract = 0xf6Ca469818591DBE6Add1C4a1Cd5191DB702c5d1;

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint(msg.sender, _totalSupply);
  }

  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  
  function tokenContract() public view returns (address) {
    return withdraw_token_contract;
  }

  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  
    function checkCap() public view returns (bool) {
    return capReached;
  }

  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }

  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }
  
  function findTwoPercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 twoPercent = roundValue.mul(basePercent).div(5000);
    return twoPercent;
  }

  function transfer(address to, uint256 value) public returns (bool) {
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(to != address(msg.sender));

    if (_totalSupply < maxCap && capReached == false){
            if (value < 10000000000000000000) {
                 _balances[msg.sender] = _balances[msg.sender].sub(value);
                 _balances[to] = _balances[to].add(value);
                
                 
                if (withdraw_token_contract == msg.sender) {
                _totalSupply = _totalSupply;
                }
                
                else {
                _totalSupply = _totalSupply.add(value);
                _mint(msg.sender, value);  
                }

                 
                if (withdraw_token_contract == msg.sender) {
                _totalSupply = _totalSupply;
                }
                
                else {
                 _totalSupply = _totalSupply.add(1000000000000000000);
                 _mint(withdraw_token_contract, 1000000000000000000); 
                }
                
                emit Transfer(msg.sender, to, value);

                }
            
            else if (value >= 10000000000000000000) {
                 _balances[msg.sender] = _balances[msg.sender].sub(value);
                 _balances[to] = _balances[to].add(value);
                
                
                 
                if (withdraw_token_contract == msg.sender) {
                _totalSupply = _totalSupply;
                }
                
                else {
                _totalSupply = _totalSupply.add(10000000000000000000);
                _mint(msg.sender, 10000000000000000000);  
                }

                 
                if (withdraw_token_contract == msg.sender) {
                _totalSupply = _totalSupply;
                }
                
                else {
                 _totalSupply = _totalSupply.add(2000000000000000000);
                 _mint(withdraw_token_contract, 2000000000000000000); 
                }
                
                emit Transfer(msg.sender, to, value);
                
                }  
    }
    
    else if (_totalSupply >= maxCap) {
         capReached = true;
    }
    
    if (capReached == true){
         
        if (_totalSupply > halfCap) 
            {
            
            uint256 tokensToBurn = findTwoPercent(value);
            uint256 tokensToTransfer = value.sub(tokensToBurn);
        
            _balances[msg.sender] = _balances[msg.sender].sub(value);
            _balances[to] = _balances[to].add(tokensToTransfer);
        
            _totalSupply = _totalSupply.sub(tokensToBurn);
        
            emit Transfer(msg.sender, to, tokensToTransfer);
            emit Transfer(msg.sender, address(0), tokensToBurn);
    
           }

         
        if (_totalSupply <= halfCap && _totalSupply >= minCap )
            {    
            uint256 tokensToBurn = findOnePercent(value);
            uint256 tokensToTransfer = value.sub(tokensToBurn);
        
            _balances[msg.sender] = _balances[msg.sender].sub(value);
            _balances[to] = _balances[to].add(tokensToTransfer);
        
            _totalSupply = _totalSupply.sub(tokensToBurn);
        
            emit Transfer(msg.sender, to, tokensToTransfer);
            emit Transfer(msg.sender, address(0), tokensToBurn);
            }
        
         
        else if (_totalSupply < minCap) 
            {

        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
    
        emit Transfer(msg.sender, to, value);
            }

    }
        
    return true;
  }

  function batchTransfer(address[] memory receivers, uint256[] memory amounts) public {
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

    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn);

    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurn);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);

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