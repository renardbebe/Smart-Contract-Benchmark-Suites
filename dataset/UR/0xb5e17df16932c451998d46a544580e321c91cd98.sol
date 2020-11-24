 

pragma solidity ^0.4.23;

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
contract KuendeCoinToken is StandardToken, Ownable {
   
  event EnabledTransfers();

   
  event SetCrowdsaleAddress(address indexed crowdsale);

   
  address public crowdsale;

   
  string public name = "KuendeCoin"; 
  uint8 public decimals = 18;
  string public symbol = "KNC";

   
  bool public transferable = false;

   
  constructor(address initialAccount, uint256 initialBalance) public {
    totalSupply_ = initialBalance;
    balances[initialAccount] = initialBalance;
    emit Transfer(0x0, initialAccount, initialBalance);
  }

   
  modifier canTransfer() {
    require(transferable || (crowdsale != address(0) && crowdsale == msg.sender));
    _; 
  }

   
  function enableTransfers() external onlyOwner {
    require(!transferable);
    transferable = true;
    emit EnabledTransfers();
  }

   
  function setCrowdsaleAddress(address _addr) external onlyOwner {
    require(_addr != address(0));
    crowdsale = _addr;
    emit SetCrowdsaleAddress(_addr);
  }

   
  function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

 

 
contract KuendeCrowdsale is Ownable {
  using SafeMath for uint256;

   
  event ChangedWalletAddress(address indexed newWallet, address indexed oldWallet);
  
   
  event TokenPurchase(address indexed investor, uint256 value, uint256 amount);

   
  struct Investor {
    uint256 weiBalance;     
    uint256 tokenBalance;   
    bool whitelisted;       
    bool purchasing;        
  }

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public registrar;

   
  uint256 public exchangeRate;

   
  address public wallet;

   
  KuendeCoinToken public token;

   
  uint256 public cap;

   
  uint256 public investorCap;

   
  uint256 public constant minInvestment = 100 finney;

   
  uint256 public constant gasPriceLimit = 1e11 wei;

   
  uint256 public weiRaised;

   
  uint256 public numInvestors;
  mapping (address => Investor) public investors;

   
  constructor (
    uint256 _startTime,
    uint256 _endTime,
    uint256 _cap,
    uint256 _exchangeRate,
    address _registrar,
    address _wallet,
    address _token
  )
    public
  {
     
    require(_startTime > now);
    require(_endTime > _startTime);
    require(_cap > 0);
    require(_exchangeRate > 0);
    require(_registrar != address(0));
    require(_wallet != address(0));
    require(_token != address(0));

     
    startTime = _startTime;
    endTime = _endTime;
    cap = _cap;
    exchangeRate = _exchangeRate;
    registrar = _registrar;
    wallet = _wallet;
    token = KuendeCoinToken(_token);
  }

   
  modifier notStarted() { 
    require(now < startTime);
    _;
  }

   
  modifier notEnded() { 
    require(now <= endTime);
    _;
  }
  
   
  function () external payable {
    buyTokens();
  }

   
  function changeWalletAddress(address _wallet) external notStarted onlyOwner {
     
    require(_wallet != address(0));
    require(_wallet != wallet);

     
    address _oldWallet = wallet;
    wallet = _wallet;

     
    emit ChangedWalletAddress(_wallet, _oldWallet);
  }

   
  function whitelistInvestors(address[] addrs) external {
    require(addrs.length > 0 && addrs.length <= 30);
    for (uint i = 0; i < addrs.length; i++) {
      whitelistInvestor(addrs[i]);
    }
  }

   
  function whitelistInvestor(address addr) public notEnded {
    require((msg.sender == registrar || msg.sender == owner) && !limited());
    if (!investors[addr].whitelisted && addr != address(0)) {
      investors[addr].whitelisted = true;
      numInvestors++;
    }
  }

   
  function buyTokens() public payable {
     
    updateInvestorCap();

    address investor = msg.sender;

     
    validPurchase();

     
    investors[investor].purchasing = true;

     
    uint256 weiAmount = msg.value.sub(refundExcess());

     
    require(weiAmount >= minInvestment);

     
    uint256 tokens = weiAmount.mul(1 ether).div(exchangeRate);

     
    weiRaised = weiRaised.add(weiAmount);
    investors[investor].weiBalance = investors[investor].weiBalance.add(weiAmount);
    investors[investor].tokenBalance = investors[investor].tokenBalance.add(tokens);

     
    require(transfer(investor, tokens));

     
    emit TokenPurchase(msg.sender, weiAmount, tokens);

     
    wallet.transfer(weiAmount);

     
    investors[investor].purchasing = false;
  }

   
  function updateInvestorCap() internal {
    require(now >= startTime);

    if (investorCap == 0) {
      investorCap = cap.div(numInvestors);
    }
  }

   
  function transfer(address to, uint256 value) internal returns (bool) {
    if (!(
      token.allowance(owner, address(this)) >= value &&
      token.balanceOf(owner) >= value &&
      token.crowdsale() == address(this)
    )) {
      return false;
    }
    return token.transferFrom(owner, to, value);
  }
  
   
  function refundExcess() internal returns (uint256 excess) {
    uint256 weiAmount = msg.value;
    address investor = msg.sender;

     
    if (limited() && !withinInvestorCap(investor, weiAmount)) {
      excess = investors[investor].weiBalance.add(weiAmount).sub(investorCap);
      weiAmount = msg.value.sub(excess);
    }

     
    if (!withinCap(weiAmount)) {
      excess = excess.add(weiRaised.add(weiAmount).sub(cap));
    }
    
     
    if (excess > 0) {
      investor.transfer(excess);
    }
  }

   
  function validPurchase() internal view {
    require (msg.sender != address(0));            
    require (tx.gasprice <= gasPriceLimit);        
    require (!investors[msg.sender].purchasing);   
    require (startTime <= now && now <= endTime);  
    require (investorCap != 0);                    
    require (msg.value >= minInvestment);          
    require (whitelisted(msg.sender));             
    require (withinCap(0));                        
    require (withinInvestorCap(msg.sender, 0));    
  }

   
  function withinCap(uint256 weiAmount) internal view returns (bool) {
    return weiRaised.add(weiAmount) <= cap;
  }

   
  function withinInvestorCap(address investor, uint256 weiAmount) internal view returns (bool) {
    return limited() ? investors[investor].weiBalance.add(weiAmount) <= investorCap : true;
  }

   
  function whitelisted(address investor) internal view returns (bool) {
    return investors[investor].whitelisted;
  }

   
  function limited() internal view returns (bool) {
    return  startTime <= now && now < startTime.add(3 days);
  }
}