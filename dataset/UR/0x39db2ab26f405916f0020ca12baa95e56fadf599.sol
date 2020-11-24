 

pragma solidity ^0.4.18;

 

 
contract FallbackToken {

  function isContract(address _addr) internal view returns (bool) {
    uint length;
    _addr = _addr;
    assembly {length := extcodesize(_addr)}
    return (length > 0);
  }
}


contract Receiver {
  function tokenFallback(address from, uint value) public;
}

 

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

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
}

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 

 
contract TrustaBitToken is MintableToken, FallbackToken {

  string public constant name = "TrustaBits";

  string public constant symbol = "TAB";

  uint256 public constant decimals = 18;

  bool public released = false;

  event Release();

  modifier isReleased () {
    require(mintingFinished);
    require(released);
    _;
  }

   
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length != size + 4);
    _;
  }

  function release() onlyOwner public returns (bool) {
    require(mintingFinished);
    require(!released);
    released = true;
    Release();

    return true;
  }

  function transfer(address _to, uint256 _value) public isReleased onlyPayloadSize(2 * 32) returns (bool) {
    require(super.transfer(_to, _value));

    if (isContract(_to)) {
      Receiver(_to).tokenFallback(msg.sender, _value);
    }

    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public isReleased returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public isReleased onlyPayloadSize(2 * 32) returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}

 

contract MilestoneCrowdsale {

  using SafeMath for uint256;

   
  uint256 public constant AVAILABLE_TOKENS = 1e9;  

   
  uint256 public constant AVAILABLE_IN_PRE_SALE = 40e6;  

   
  uint256 public constant AVAILABLE_IN_MAIN = 610e6;  

   
  uint256 public constant AVAILABLE_FOR_EARLY_INVESTORS = 100e6;  

   
  uint public preSaleStartDate;

   
  uint public preSaleEndDate;

   
  uint public mainSaleStartDate;

   
  uint public mainSaleEndDate;

  struct Milestone {
    uint start;  
    uint end;  
    uint256 bonus;
    uint256 price;
  }

  Milestone[] public milestones;

  uint256 public rateUSD;  

  uint256 public earlyInvestorTokenRaised;
  uint256 public preSaleTokenRaised;
  uint256 public mainSaleTokenRaised;


  function initMilestones(uint _rate, uint _preSaleStartDate, uint _preSaleEndDate, uint _mainSaleStartDate, uint _mainSaleEndDate) internal {
    rateUSD = _rate;
    preSaleStartDate = _preSaleStartDate;
    preSaleEndDate = _preSaleEndDate;
    mainSaleStartDate = _mainSaleStartDate;
    mainSaleEndDate = _mainSaleEndDate;

     
    uint256 earlyInvestorPrice = uint(25 ether).div(rateUSD.mul(10));
    milestones.push(Milestone(0, preSaleStartDate, 0, earlyInvestorPrice));

     
    uint256 preSalePrice = usdToEther(5);
    milestones.push(Milestone(preSaleStartDate, preSaleEndDate, 20, preSalePrice));

     
    uint256 mainSalePrice = usdToEther(10);
    uint mainSaleStartDateWeek1 = mainSaleStartDate.add(1 weeks);
    uint mainSaleStartDateWeek3 = mainSaleStartDate.add(3 weeks);
    uint mainSaleStartDateWeek2 = mainSaleStartDate.add(2 weeks);

    milestones.push(Milestone(mainSaleStartDate, mainSaleStartDateWeek1, 15, mainSalePrice));
    milestones.push(Milestone(mainSaleStartDateWeek1, mainSaleStartDateWeek2, 10, mainSalePrice));
    milestones.push(Milestone(mainSaleStartDateWeek2, mainSaleStartDateWeek3, 5, mainSalePrice));
    milestones.push(Milestone(mainSaleStartDateWeek3, _mainSaleEndDate, 0, mainSalePrice));
  }

  function usdToEther(uint256 usdValue) public view returns (uint256) {
     
    return usdValue.mul(1 ether).div(rateUSD);
  }

  function getCurrentMilestone() internal view returns (uint256, uint256) {
    for (uint i = 0; i < milestones.length; i++) {
      if (now >= milestones[i].start && now < milestones[i].end) {
        var milestone = milestones[i];
        return (milestone.bonus, milestone.price);
      }
    }

    return (0, 0);
  }

  function getCurrentPrice() public view returns (uint256) {
    var (, price) = getCurrentMilestone();

    return price;
  }

  function getTokenRaised() public view returns (uint256) {
    return mainSaleTokenRaised.add(preSaleTokenRaised.add(earlyInvestorTokenRaised));
  }

  function isEarlyInvestors() public view returns (bool) {
    return now < preSaleStartDate;
  }

  function isPreSale() public view returns (bool) {
    return now >= preSaleStartDate && now < preSaleEndDate;
  }

  function isMainSale() public view returns (bool) {
    return now >= mainSaleStartDate && now < mainSaleEndDate;
  }

  function isEnded() public view returns (bool) {
    return now >= mainSaleEndDate;
  }

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

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
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

 

contract TrustaBitCrowdsale is MilestoneCrowdsale, Ownable {

  using SafeMath for uint256;

   
  uint public constant MINIMUM_CONTRIBUTION = 15e16;

   
  uint public constant softCapUSD = 3e6;  
  uint public softCap;  

   
  uint public constant hardCapUSD = 49e6;  
  uint public hardCap;  

   
  address public addressAdvisoryBountyTeam;
  uint256 public constant tokenAdvisoryBountyTeam = 250e6;

  address[] public investors;

  TrustaBitToken public token;

  address public wallet;

  uint256 public weiRaised;

  RefundVault public vault;

  bool public isFinalized = false;

  event Finalized();

   
  event TokenPurchase(address indexed investor, uint256 value, uint256 amount);

  modifier hasMinimumContribution() {
    require(msg.value >= MINIMUM_CONTRIBUTION);
    _;
  }

  function TrustaBitCrowdsale(address _wallet, address _token, uint _rate, uint _preSaleStartDate, uint _preSaleEndDate, uint _mainSaleStartDate, uint _mainSaleEndDate, address _AdvisoryBountyTeam) public {
    require(_token != address(0));
    require(_AdvisoryBountyTeam != address(0));
    require(_rate > 0);
    require(_preSaleStartDate > 0);
    require(_preSaleEndDate > 0);
    require(_preSaleEndDate > _preSaleStartDate);
    require(_mainSaleStartDate > 0);
    require(_mainSaleStartDate >= _preSaleEndDate);
    require(_mainSaleEndDate > 0);
    require(_mainSaleEndDate > _mainSaleStartDate);

    wallet = _wallet;
    token = TrustaBitToken(_token);
    addressAdvisoryBountyTeam = _AdvisoryBountyTeam;

    initMilestones(_rate, _preSaleStartDate, _preSaleEndDate, _mainSaleStartDate, _mainSaleEndDate);

    softCap = usdToEther(softCapUSD.mul(100));
    hardCap = usdToEther(hardCapUSD.mul(100));

    vault = new RefundVault(wallet);
  }

  function investorsCount() public view returns (uint) {
    return investors.length;
  }

   
  function() external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address investor) public hasMinimumContribution payable {
    require(investor != address(0));
    require(!isEnded());

    uint256 weiAmount = msg.value;

    require(getCurrentPrice() > 0);

    uint256 tokensAmount = calculateTokens(weiAmount);
    require(tokensAmount > 0);

    mintTokens(investor, weiAmount, tokensAmount);
    increaseRaised(weiAmount, tokensAmount);

    if (vault.deposited(investor) == 0) {
      investors.push(investor);
    }
     
    vault.deposit.value(weiAmount)(investor);
  }

  function calculateTokens(uint256 weiAmount) internal view returns (uint256) {
    if ((weiRaised.add(weiAmount)) > hardCap) return 0;

    var (bonus, price) = getCurrentMilestone();

    uint256 tokensAmount = weiAmount.div(price).mul(10 ** token.decimals());
    tokensAmount = tokensAmount.add(tokensAmount.mul(bonus).div(100));

    if (isEarlyInvestorsTokenRaised(tokensAmount)) return 0;
    if (isPreSaleTokenRaised(tokensAmount)) return 0;
    if (isMainSaleTokenRaised(tokensAmount)) return 0;
    if (isTokenAvailable(tokensAmount)) return 0;

    return tokensAmount;
  }

  function isEarlyInvestorsTokenRaised(uint256 tokensAmount) public view returns (bool) {
    return isEarlyInvestors() && (earlyInvestorTokenRaised.add(tokensAmount) > AVAILABLE_FOR_EARLY_INVESTORS.mul(10 ** token.decimals()));
  }

  function isPreSaleTokenRaised(uint256 tokensAmount) public view returns (bool) {
    return isPreSale() && (preSaleTokenRaised.add(tokensAmount) > AVAILABLE_IN_PRE_SALE.mul(10 ** token.decimals()));
  }

  function isMainSaleTokenRaised(uint256 tokensAmount) public view returns (bool) {
    return isMainSale() && (mainSaleTokenRaised.add(tokensAmount) > AVAILABLE_IN_MAIN.mul(10 ** token.decimals()));
  }

  function isTokenAvailable(uint256 tokensAmount) public view returns (bool) {
    return getTokenRaised().add(tokensAmount) > AVAILABLE_TOKENS.mul(10 ** token.decimals());
  }

  function increaseRaised(uint256 weiAmount, uint256 tokensAmount) internal {
    weiRaised = weiRaised.add(weiAmount);

    if (isEarlyInvestors()) {
      earlyInvestorTokenRaised = earlyInvestorTokenRaised.add(tokensAmount);
    }

    if (isPreSale()) {
      preSaleTokenRaised = preSaleTokenRaised.add(tokensAmount);
    }

    if (isMainSale()) {
      mainSaleTokenRaised = mainSaleTokenRaised.add(tokensAmount);
    }
  }

  function mintTokens(address investor, uint256 weiAmount, uint256 tokens) internal {
    token.mint(investor, tokens);
    TokenPurchase(investor, weiAmount, tokens);
  }

  function finalize() onlyOwner public {
    require(!isFinalized);
    require(isEnded());

    if (softCapReached()) {
      vault.close();
      mintAdvisoryBountyTeam();
      token.finishMinting();
    }
    else {
      vault.enableRefunds();
      token.finishMinting();
    }

    token.transferOwnership(owner);

    isFinalized = true;
    Finalized();
  }

  function mintAdvisoryBountyTeam() internal {
    mintTokens(addressAdvisoryBountyTeam, 0, tokenAdvisoryBountyTeam.mul(10 ** token.decimals()));
  }

   
  function claimRefund() public {
    require(isFinalized);
    require(!softCapReached());

    vault.refund(msg.sender);
  }

  function refund() onlyOwner public {
    require(isFinalized);
    require(!softCapReached());

    for (uint i = 0; i < investors.length; i++) {
      address investor = investors[i];
      if (vault.deposited(investor) != 0) {
        vault.refund(investor);
      }
    }
  }

  function softCapReached() public view returns (bool) {
    return weiRaised >= softCap;
  }

  function hardCapReached() public view returns (bool) {
    return weiRaised >= hardCap;
  }

  function destroy() onlyOwner public {
    selfdestruct(owner);
  }
}