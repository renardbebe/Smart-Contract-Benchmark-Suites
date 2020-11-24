 

pragma solidity 0.5.11;

 

contract Ownable {
  address private _owner;
  
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
  
   
  constructor () internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }
  
   
  function owner() public view returns (address) {
    return _owner;
  }
  
   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }
  
   
  function isOwner() public view returns (bool) {
    return msg.sender == _owner;
  }
  
   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
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


contract IERC20 {
  function transfer(address to, uint256 value) external returns (bool);
  
  function transfer2(address to, uint256 value) external returns (bool);
  
  function approve(address spender, uint256 value) external returns (bool);
  
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  
  function totalSupply() external view returns (uint256);
  
  function balanceOf(address who) external view returns (uint256);
  
  function allowance(address owner, address spender) external view returns (uint256);
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {
  using SafeMath for uint256;
  
  mapping (address => uint256) public _balances;
  
  mapping (address => mapping (address => uint256)) private _allowed;
  
  uint256 public totalSupply;
  
  
   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  
   
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  
   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }
  
  function transfer2(address to, uint256 value) public returns (bool) {
    _transfer2(msg.sender, to, value);
    return true;
  }
  
   
  
  function approve(address spender, uint256 value) public returns (bool) {
    _approve(msg.sender, spender, value);
    return true;
  }
  
   
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    _transfer(from, to, value);
    _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
    return true;
  }
  
   
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
    return true;
  }
  
   
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
    return true;
  }
  
   
  function _transfer(address from, address to, uint256 value) internal {
    require(to != address(0));
    
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }
  
  function _transfer2(address from, address to, uint256 value) internal {
    
    
    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }
  
  
  
   
  function _approve(address owner, address spender, uint256 value) internal {
    require(spender != address(0));
    require(owner != address(0));
    
    _allowed[owner][spender] = value;
    emit Approval(owner, spender, value);
  }
  
  
}




contract ERC20Pausable is ERC20, Pausable {
  
  function transfer(address to, uint256 value) public whenNotPaused returns (bool) {
    return super.transfer(to, value);
  }
  
  function transferFrom(address from, address to, uint256 value) public whenNotPaused returns (bool) {
    return super.transferFrom(from, to, value);
  }
  
  function approve(address spender, uint256 value) public whenNotPaused returns (bool) {
    return super.approve(spender, value);
  }
  
  function increaseAllowance(address spender, uint addedValue) public whenNotPaused returns (bool success) {
    return super.increaseAllowance(spender, addedValue);
  }
  
  function decreaseAllowance(address spender, uint subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseAllowance(spender, subtractedValue);
  }
}


contract ReentrancyGuard {
   
  uint256 private _guardCounter;
  
  constructor () internal {
     
     
    _guardCounter = 1;
  }
  
   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
  }
}




contract BCTcontract is Pausable, ReentrancyGuard {
  using SafeMath for uint256;
  
   
  BCTToken public token;
  
  mapping(address => uint256) balances;
  mapping (address => mapping (address => uint256)) internal allowed;
  
  uint256 constant public tokenDecimals = 18;
  
   
  uint256 public totalSupply = 1000000000 * (10 ** uint256(tokenDecimals));
  
   
  uint256 public investorMinCap = 1 ether; 
  
   
  uint256 public weiRaised;
  
   
  uint256 public contractCap;
  uint256 public soldTokens;
  bool public contractEnabled = false;
  
  address payable private walletOne = 0xafe8B6022896B41E18b74Fa22e09240e1F375508;
  
   
  uint256 public STANDARD_RATE = 560;
  
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  
  constructor () public {
    token = createTokenContract();
    
  }
  
  
   
   
   
   
   
  function createTokenContract() internal returns (BCTToken) {
    return new BCTToken();
  }
  
   
  function enableTokenTransferability() external onlyOwner {
    token.unpause();
  }
  
   
  function disableTokenTransferability() external onlyOwner {
    token.pause();
  }
  
   
  function transfer(address to, uint256 value) external onlyOwner returns (bool ok)  {
    uint256 converterdValue = value * (10 ** uint256(tokenDecimals));
    return token.transfer(to, converterdValue);
  }
  
  
  
   
  
  function enableOperation() external onlyOwner{
    contractEnabled = true;
    contractCap = totalSupply;
  }
  
   
  function () external payable whenNotPaused  {
    buyTokens(msg.sender);
  }
  
   
  function buyTokens(address beneficiary) public nonReentrant payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());
    
    
    uint256 weiAmount = msg.value;
    uint256 returnWeiAmount;
    
     
    uint rate = getRate();
    assert(rate > 0);
    uint256 tokens = weiAmount.mul(rate);
    
    uint256 newsoldTokens = soldTokens.add(tokens);
    
    if (newsoldTokens > contractCap) {
      newsoldTokens = contractCap;
      tokens = contractCap.sub(soldTokens);
      uint256 newWeiAmount = tokens.div(rate);
      returnWeiAmount = weiAmount.sub(newWeiAmount);
      weiAmount = newWeiAmount;
    }
    
     
    weiRaised = weiRaised.add(weiAmount);
    
    token.transfer(beneficiary, tokens);
    soldTokens = newsoldTokens;
    if (returnWeiAmount > 0){
      msg.sender.transfer(returnWeiAmount);
    }
    
    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    
    forwardFunds();
  }
  
   
   
  function forwardFunds() internal {
    walletOne.transfer(address(this).balance);
  }
  
   
  function validPurchase() internal view returns (bool) {
    
    bool nonMinimumPurchase;
    
    nonMinimumPurchase = msg.value >= investorMinCap;
    
    return nonMinimumPurchase;
  }
  
  
  
   
  function endIco(uint256 value) external onlyOwner {
    uint256 converterdValue = value * (10 ** uint256(tokenDecimals));
    token.transfer2(0x0000000000000000000000000000000000000000, converterdValue);
    
    
  }
  
  
  function setRate(uint256 value) external onlyOwner()  {
    uint256 converterdValue = value;
    STANDARD_RATE = converterdValue * 10;
  }
  
  
  function getRate() public view returns(uint)  {
    return STANDARD_RATE;
  }
  
}





contract BCTToken is ERC20Pausable {
  string constant public name = "Best Cash Token";
  string constant public symbol = "BCT";
  uint8 constant public decimals = 18;
  uint256 constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 constant INITIAL_SUPPLY = 1000000000 * TOKEN_UNIT;
  
  
  constructor () public {
     
    paused = true;
     
    totalSupply = INITIAL_SUPPLY;
    
    _balances[msg.sender] = INITIAL_SUPPLY;
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