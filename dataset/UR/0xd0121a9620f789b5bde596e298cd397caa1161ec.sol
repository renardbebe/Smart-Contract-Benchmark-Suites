 

pragma solidity ^0.4.15;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract WELToken is MintableToken, PausableToken {
  string public constant name = "Welcome Coin";
  string public constant symbol = "WEL";
  uint8 public constant decimals = 18;
}



 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


 

contract WelCoinCrowdsale is Ownable {

  using SafeMath for uint256;

  struct Bonus {
    uint bonusEndTime;
    uint timePercent;
    uint bonusMinAmount;
    uint amountPercent;
  }

   
  uint256 public goal;

   
  uint256 public tokenEmission;

   
  RefundVault public vault;

   
  bool public isFinalized;

   
  MintableToken public token;

   
  uint256 public preSaleStartTime;
  uint256 public preSaleEndTime;

   
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

   
  uint256 public preSaleWeiCap;
  uint256 public mainSaleWeiCap;

   
  address public wallet;

   
  address public tokenWallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

  Bonus[] public preSaleBonuses;
  Bonus[] public mainSaleBonuses;

  uint256 public preSaleMinimumWei;
  uint256 public mainSaleMinimumWei;

  uint256 public defaultPercent;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FinalisedCrowdsale(uint256 totalSupply, uint256 minterBenefit);

  function WelCoinCrowdsale(uint256 _preSaleStartTime, uint256 _preSaleEndTime, uint256 _preSaleWeiCap, uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _mainSaleWeiCap, uint256 _goal, uint256 _rate, address _wallet, address _tokenWallet) public {

     

     
    require(_preSaleStartTime >= now);

     
    require(_mainSaleStartTime >= now);

     
    require(_preSaleEndTime < _mainSaleStartTime);

     
    require(_preSaleStartTime < _preSaleEndTime);

     
    require(_mainSaleStartTime < _mainSaleEndTime);

    require(_rate > 0);
    require(_preSaleWeiCap > 0);
    require(_mainSaleWeiCap > 0);
    require(_wallet != 0x0);
    require(_tokenWallet != 0x0);

    preSaleMinimumWei = 300000000000000000;   
    mainSaleMinimumWei = 300000000000000000;  
    defaultPercent = 0;

    tokenEmission = 150000000 ether;

    preSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 2, timePercent: 20, bonusMinAmount: 8500 ether, amountPercent: 25}));
    preSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 4, timePercent: 20, bonusMinAmount: 0, amountPercent: 0}));
    preSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 6, timePercent: 15, bonusMinAmount: 0, amountPercent: 0}));
    preSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 7, timePercent: 10, bonusMinAmount: 20000 ether, amountPercent: 15}));

    mainSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 7,  timePercent: 9, bonusMinAmount: 0, amountPercent: 0}));
    mainSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 14, timePercent: 6, bonusMinAmount: 0, amountPercent: 0}));
    mainSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 21, timePercent: 4, bonusMinAmount: 0, amountPercent: 0}));
    mainSaleBonuses.push(Bonus({bonusEndTime: 3600 * 24 * 28, timePercent: 0, bonusMinAmount: 0, amountPercent: 0}));

    preSaleStartTime = _preSaleStartTime;
    preSaleEndTime = _preSaleEndTime;
    preSaleWeiCap = _preSaleWeiCap;
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    mainSaleWeiCap = _mainSaleWeiCap;
    goal = _goal;
    rate = _rate;
    wallet = _wallet;
    tokenWallet = _tokenWallet;

    isFinalized = false;

    token = new WELToken();
    vault = new RefundVault(wallet);
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {

    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(!isFinalized);

    uint256 weiAmount = msg.value;

    validateWithinPeriods();
    validateWithinCaps(weiAmount);

     
    uint256 tokens = weiAmount.mul(rate);

    uint256 percent = getBonusPercent(tokens, now);

     
    uint256 bonusedTokens = applyBonus(tokens, percent);

     
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, bonusedTokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);

    forwardFunds();
  }

   
  function mintTokens(address beneficiary, uint256 weiAmount, uint256 forcePercent) external onlyOwner returns (bool) {

    require(forcePercent <= 100);
    require(beneficiary != 0x0);
    require(weiAmount != 0);
    require(!isFinalized);

    validateWithinCaps(weiAmount);

    uint256 percent = 0;

     
    uint256 tokens = weiAmount.mul(rate);

    if (forcePercent == 0) {
      percent = getBonusPercent(tokens, now);
    } else {
      percent = forcePercent;
    }

     
    uint256 bonusedTokens = applyBonus(tokens, percent);

     
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, bonusedTokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, bonusedTokens);
  }

   
  function setPreSaleParameters(uint256 _preSaleStartTime, uint256 _preSaleEndTime, uint256 _preSaleWeiCap, uint256 _preSaleMinimumWei) public onlyOwner {
    require(!isFinalized);
    require(_preSaleStartTime < _preSaleEndTime);
    require(_preSaleWeiCap > 0);
    preSaleStartTime = _preSaleStartTime;
    preSaleEndTime = _preSaleEndTime;
    preSaleWeiCap = _preSaleWeiCap;
    preSaleMinimumWei = _preSaleMinimumWei;
  }

   
  function setMainSaleParameters(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _mainSaleWeiCap, uint256 _mainSaleMinimumWei) public onlyOwner {
    require(!isFinalized);
    require(_mainSaleStartTime < _mainSaleEndTime);
    require(_mainSaleWeiCap > 0);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    mainSaleWeiCap = _mainSaleWeiCap;
    mainSaleMinimumWei = _mainSaleMinimumWei;
  }

   
  function setWallets(address _wallet, address _tokenWallet) public onlyOwner {
    require(!isFinalized);
    require(_wallet != 0x0);
    require(_tokenWallet != 0x0);
    wallet = _wallet;
    tokenWallet = _tokenWallet;
  }

     
  function setRate(uint256 _rate) public onlyOwner {
    require(!isFinalized);
    require(_rate > 0);
    rate = _rate;
  }

       
  function setGoal(uint256 _goal) public onlyOwner {
    require(!isFinalized);
    require(_goal > 0);
    goal = _goal;
  }


   
  function pauseToken() external onlyOwner {
    require(!isFinalized);
    WELToken(token).pause();
  }

   
  function unpauseToken() external onlyOwner {
    WELToken(token).unpause();
  }

   
  function transferTokenOwnership(address newOwner) external onlyOwner {
    WELToken(token).transferOwnership(newOwner);
  }

   
  function mainSaleHasEnded() external constant returns (bool) {
    return now > mainSaleEndTime;
  }

   
  function preSaleHasEnded() external constant returns (bool) {
    return now > preSaleEndTime;
  }

   
  function forwardFunds() internal {
     
    vault.deposit.value(msg.value)(msg.sender);
  }

   
   
  function getBonusPercent(uint256 tokens, uint256 currentTime) public constant returns (uint256 percent) {
     
    uint i = 0;
    bool isPreSale = currentTime >= preSaleStartTime && currentTime <= preSaleEndTime;
    if (isPreSale) {
      uint256 preSaleDiffInSeconds = currentTime.sub(preSaleStartTime);
      for (i = 0; i < preSaleBonuses.length; i++) {
        if (preSaleDiffInSeconds <= preSaleBonuses[i].bonusEndTime) {
          if (preSaleBonuses[i].bonusMinAmount > 0 && tokens >= preSaleBonuses[i].bonusMinAmount) {
            return preSaleBonuses[i].amountPercent;
          } else {
            return preSaleBonuses[i].timePercent;
          }
        }
      }
    } else {
      uint256 mainSaleDiffInSeconds = currentTime.sub(mainSaleStartTime);
      for (i = 0; i < mainSaleBonuses.length; i++) {
        if (mainSaleDiffInSeconds <= mainSaleBonuses[i].bonusEndTime) {
          if (mainSaleBonuses[i].bonusMinAmount > 0 && tokens >= mainSaleBonuses[i].bonusMinAmount) {
            return mainSaleBonuses[i].amountPercent;
          } else {
            return mainSaleBonuses[i].timePercent;
          }
        }
      }
    }
    return defaultPercent;
  }

  function applyBonus(uint256 tokens, uint256 percent) internal constant returns (uint256 bonusedTokens) {
    uint256 tokensToAdd = tokens.mul(percent).div(100);
    return tokens.add(tokensToAdd);
  }

  function validateWithinPeriods() internal constant {
     
    require((now >= preSaleStartTime && now <= preSaleEndTime) || (now >= mainSaleStartTime && now <= mainSaleEndTime));
  }

  function validateWithinCaps(uint256 weiAmount) internal constant {
    uint256 expectedWeiRaised = weiRaised.add(weiAmount);

     
    if (now >= preSaleStartTime && now <= preSaleEndTime) {
      require(weiAmount >= preSaleMinimumWei);
      require(expectedWeiRaised <= preSaleWeiCap);
    }

     
    if (now >= mainSaleStartTime && now <= mainSaleEndTime) {
      require(weiAmount >= mainSaleMinimumWei);
      require(expectedWeiRaised <= mainSaleWeiCap);
    }
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!goalReached());
    vault.refund(msg.sender);
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

   
   
   

  function finaliseCrowdsale() external onlyOwner returns (bool) {
    require(!isFinalized);
    uint256 totalSupply = token.totalSupply();
    uint256 minterBenefit = tokenEmission.sub(totalSupply);
    if (goalReached()) {
      token.mint(tokenWallet, minterBenefit);
      vault.close();
       
    } else {
      vault.enableRefunds();
    }

    FinalisedCrowdsale(totalSupply, minterBenefit);
    isFinalized = true;
    return true;
  }

}