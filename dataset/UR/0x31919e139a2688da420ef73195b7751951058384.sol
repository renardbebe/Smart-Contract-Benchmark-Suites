 

pragma solidity ^0.4.13;

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

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startBlock;
  uint256 public endBlock;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startBlock, uint256 _endBlock, uint256 _rate, address _wallet) {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startBlock = _startBlock;
    endBlock = _endBlock;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    uint256 current = block.number;
    bool withinPeriod = current >= startBlock && current <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return block.number > endBlock;
  }


}

contract WhiteListCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public whiteListEndBlock;
  mapping(address => bool) isWhiteListed;

  event InvestorWhiteListAddition(address investor);

  function WhiteListCrowdsale(uint256 _whiteListEndBlock) {
    require(_whiteListEndBlock > startBlock);
    whiteListEndBlock = _whiteListEndBlock;
  }

  function addToWhiteList(address investor) public {
    require(startBlock > block.number);
    require(!isWhiteListed[investor]);
    require(investor != 0);

    isWhiteListed[investor] = true;
    InvestorWhiteListAddition(investor);
  }

   
   
  function buyTokens(address beneficiary) payable {
    require(validWhiteListedPurchase(beneficiary));
    return super.buyTokens(beneficiary);
  }

  function validWhiteListedPurchase(address beneficiary) internal constant returns (bool) {
    return isWhiteListed[beneficiary] || whiteListEndBlock <= block.number;
  }

}

contract BonusWhiteListCrowdsale is WhiteListCrowdsale {
  using SafeMath for uint256;

  uint256 bonusWhiteListRate;

  event BonusWhiteList(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function BonusWhiteListCrowdsale(uint256 _bonusWhiteListRate) {
    require(_bonusWhiteListRate > 0);
    bonusWhiteListRate = _bonusWhiteListRate;
  }

  function buyTokens(address beneficiary) payable {
    super.buyTokens(beneficiary);

    if(whiteListEndBlock > block.number && isWhiteListed[beneficiary]){
      uint256 weiAmount = msg.value;
      uint256 bonusTokens = weiAmount.mul(rate).mul(bonusWhiteListRate).div(100);
      token.mint(beneficiary, bonusTokens);
      BonusWhiteList(msg.sender, beneficiary, weiAmount, bonusTokens);
    }
  }

}

contract ReferedCrowdsale is WhiteListCrowdsale {
  using SafeMath for uint256;

  mapping(address => address) referrals;

  event ReferredInvestorAddition(address whiteListedInvestor, address referredInvestor);

  function ReferedCrowdsale() {}

  function addToReferrals(address whiteListedInvestor, address referredInvestor) public {
    require(isWhiteListed[whiteListedInvestor]);
    require(!isWhiteListed[referredInvestor]);
    require(whiteListedInvestor != 0);
    require(referredInvestor != 0);
    require(referrals[referredInvestor] == 0x0);

    referrals[referredInvestor] = whiteListedInvestor;
    ReferredInvestorAddition(whiteListedInvestor, referredInvestor);
  }

  function validWhiteListedPurchase(address beneficiary) internal constant returns (bool) {
    return super.validWhiteListedPurchase(beneficiary) || referrals[beneficiary] != 0x0;
  }

}

contract BonusReferrerCrowdsale is ReferedCrowdsale, BonusWhiteListCrowdsale {
  using SafeMath for uint256;

  uint256 bonusReferredRate;

  event BonusReferred(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function BonusReferrerCrowdsale(uint256 _bonusReferredRate) {
    require(_bonusReferredRate > 0 && _bonusReferredRate < bonusWhiteListRate);
    bonusReferredRate = _bonusReferredRate;
  }

  function buyTokens(address beneficiary) payable {
    super.buyTokens(beneficiary);

    if(whiteListEndBlock > block.number && referrals[beneficiary] != 0x0){
      uint256 weiAmount = msg.value;
      uint256 bonusReferrerTokens = weiAmount.mul(rate).mul(bonusWhiteListRate - bonusReferredRate).div(100);
      uint256 bonusReferredTokens = weiAmount.mul(rate).mul(bonusReferredRate).div(100);
      token.mint(beneficiary, bonusReferredTokens);
      token.mint(referrals[beneficiary], bonusReferrerTokens);
      BonusWhiteList(msg.sender, referrals[beneficiary], weiAmount, bonusReferrerTokens);
      BonusReferred(msg.sender, beneficiary, weiAmount, bonusReferredTokens);
    }
  }

}

contract PartialOwnershipCrowdsale is BonusReferrerCrowdsale {
  using SafeMath for uint256;

  uint256 percentToInvestor;

  event CompanyTokenIssued(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function PartialOwnershipCrowdsale(uint256 _percentToInvestor) {
    require(_percentToInvestor != 0);
    percentToInvestor = _percentToInvestor;
  }

  function buyTokens(address beneficiary) payable {
    super.buyTokens(beneficiary);
    uint256 weiAmount = msg.value;
    uint256 investorTokens = weiAmount.mul(rate);
    uint256 companyTokens = investorTokens.mul(100 - percentToInvestor).div(percentToInvestor);
    if(whiteListEndBlock > block.number && (referrals[beneficiary] != 0x0 || isWhiteListed[beneficiary])){
      companyTokens = companyTokens.sub(investorTokens.mul(bonusWhiteListRate).div(100));
    }

    token.mint(wallet, companyTokens);
    CompanyTokenIssued(msg.sender, beneficiary, weiAmount, companyTokens);
  }

}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
   
  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();
    
    isFinalized = true;
  }

   
   
  function finalization() internal {
    token.finishMinting();
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

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

}

contract DemeterCrowdsale is
  Crowdsale,
  CappedCrowdsale,
  RefundableCrowdsale,
  WhiteListCrowdsale,
  ReferedCrowdsale,
  BonusWhiteListCrowdsale,
  BonusReferrerCrowdsale,
  PartialOwnershipCrowdsale {

    uint256 endBlock;

  function DemeterCrowdsale(
    uint256 _startBlock,
    uint256 _endBlock,
    uint256 _rate,
    address _wallet,
    uint256 _cap,
    uint256 _goal,
    uint256 _whiteListEndBlock,
    uint256 _bonusWhiteListRate,
    uint256 _bonusReferredRate,
    uint256 _percentToInvestor
  )
    Crowdsale(_startBlock, _endBlock, _rate, _wallet)
    CappedCrowdsale(_cap)
    RefundableCrowdsale(_goal)
    WhiteListCrowdsale(_whiteListEndBlock)
    ReferedCrowdsale()
    BonusWhiteListCrowdsale(_bonusWhiteListRate)
    BonusReferrerCrowdsale(_bonusReferredRate)
    PartialOwnershipCrowdsale(_percentToInvestor)
  {
    DemeterToken(token).setEndBlock(_endBlock);
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new DemeterToken();
  }

}

contract DemeterCrowdsaleInstance is DemeterCrowdsale {

  function DemeterCrowdsaleInstance() DemeterCrowdsale(
    4164989,
    4176989,
    1000000000000,
    0x14f01e00092a5b0dBD43414793541df316363D82,
    20000000000000000,
    10000000000000000,
    4168989,
    7,
    3,
    30
  ){}

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract TimeBlockedToken is ERC20, Ownable {

  uint256 endBlock;

   
  modifier canTransfer() {
    require(block.number > endBlock);
    _;
  }

  function setEndBlock(uint256 _endBlock) onlyOwner {
    endBlock = _endBlock;
  }

   
  function transfer(address _to, uint256 _value) canTransfer returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) canTransfer returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract DemeterToken is MintableToken, TimeBlockedToken {
  string public name = "Demeter";
  string public symbol = "DMT";
  uint256 public decimals = 18;
}