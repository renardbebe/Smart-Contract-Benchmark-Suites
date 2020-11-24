 

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
  event DividentTransfer(address from , address to , uint256 value);
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
contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = 0x2015624d801cF3265598b3698Af21Fb8d844B73E;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
contract BlazingToken is ERC20Detailed, Owned {
    
  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  
  string constant tokenName = "Blazing Token";
  string constant tokenSymbol = "BLA";
  uint8  constant tokenDecimals = 6;
  uint256 _totalSupply = 100000000 * 1000000;
  uint256 public basePercent = 100;
  

  constructor() public payable ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint( 0x2015624d801cF3265598b3698Af21Fb8d844B73E, _totalSupply);
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
  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }
  
  function withdrawDividentByAdmin ()public onlyOwner {
      transfer(owner , balanceOf(address(this)));
  }
  
   function transferDivident(address to, uint256 value) internal  {
      
    require(value <= _balances[address(this)]);
    require(to != address(0));
    
    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensForDividentFunc = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn+tokensForDividentFunc);
    
    _balances[address(this)] = _balances[address(this)].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(this)] = _balances[address(this)].add(tokensForDividentFunc);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    
    emit Transfer(address(this), to, tokensToTransfer);
    emit Transfer(address(this), address(0), tokensToBurn);
    emit Transfer(address(this) , address(this) , tokensForDividentFunc);
}


  function transferFromContract(address to, uint256 value) internal returns (bool) {
      
    address contractAddress = address(this);
    require(value <= _balances[contractAddress]);
    require(to != address(0));
    
    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensForDividentTrans = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn+tokensForDividentTrans);
    
    _balances[contractAddress] = _balances[contractAddress].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(this)] = _balances[address(this)].add(tokensForDividentTrans);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    
    emit Transfer(contractAddress, to, tokensToTransfer);
    emit Transfer(contractAddress, address(0), tokensToBurn);
    emit Transfer(contractAddress , address(this) , tokensForDividentTrans);
    
    return true;
  }
  
  
  function transfer(address to, uint256 value) public returns (bool) {
      
    require(value <= _balances[msg.sender]);
    require(to != address(0));
    
    uint256 tokensToBurn = findOnePercent(value);
    uint256 tokensForDividentTrans = findOnePercent(value);
    uint256 tokensToTransfer = value.sub(tokensToBurn+tokensForDividentTrans);
    
    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(this)] = _balances[address(this)].add(tokensForDividentTrans);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurn);
    emit Transfer(msg.sender , address(this) , tokensForDividentTrans);
    
    return true;
  }
  
  function calculateTokenForTop100 () public view returns (uint256){
      uint256 totalBalance = balanceOf(address(this));
      return findOnePercent(totalBalance);
  }
  
  
  
  function multiTransferToTop100 (address[] memory receivers) public onlyOwner {
    uint256 tokenAmount = calculateTokenForTop100();
    require(tokenAmount > 0);
    for (uint256 i = 0; i < receivers.length; i++) {
      transferFromContract(receivers[i], tokenAmount);
    }
    }
    
       
    function airdrop(address  source, address[] memory dests, uint256[] memory values) public  {
         
         
        require(dests.length == values.length);

        for (uint256 i = 0; i < dests.length; i++) {
            require(transferFrom(source, dests[i], values[i]));
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
    uint256 tokenForDivident = findOnePercent(value);
    
    
    uint256 tokensToTransfer = value.sub(tokensToBurn+tokenForDivident);
    
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[address(this)] = _balances[address(this)].add(tokenForDivident);
    _totalSupply = _totalSupply.sub(tokensToBurn);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    
    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, address(0), tokensToBurn);
    emit Transfer(from , address(this) , tokenForDivident);
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