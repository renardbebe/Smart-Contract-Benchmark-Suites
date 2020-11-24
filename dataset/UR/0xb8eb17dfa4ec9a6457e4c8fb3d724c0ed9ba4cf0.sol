 

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

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
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
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }


}

contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
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


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
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

contract WhiteListCrowdsale is
  CappedCrowdsale,
  Ownable
{

   
  uint8 public constant WHITELIST_BONUS_RATE = 10;

   
  uint8 public constant REFERRAL_SHARE_RATE = 50;

   
  uint256 public whiteListRegistrationEndTime;

   
  uint256 public whiteListEndTime;

   
  mapping(address => bool) public isWhiteListed;

   
  mapping(bytes32 => address) internal referralCodes;

   
  mapping(address => address) internal referrals;

   
  event WhiteListedInvestorAdded(
    address indexed investor,
    string referralCode
  );

   
  event ReferredInvestorAdded(
    string referralCode,
    address referredInvestor
  );

   
  event ReferredBonusTokensEmitted(
    address indexed beneficiary,
    uint256 amount
  );

   
  event WhiteListBonusTokensEmitted(
    address indexed beneficiary,
    uint256 amount
  );

   
  function WhiteListCrowdsale(uint256 _whiteListRegistrationEndTime, uint256 _whiteListEndTime) public {
    require(_whiteListEndTime > startTime);

    whiteListEndTime = _whiteListEndTime;
    whiteListRegistrationEndTime = _whiteListRegistrationEndTime;
  }

   
  function buyTokens(address _beneficiary) public payable
  {
    require(validWhiteListedPurchase(_beneficiary));

     
    super.buyTokens(_beneficiary);
    
    uint256 bonusTokens = computeBonusTokens(_beneficiary, msg.value);
    if (isReferred(_beneficiary))
    {
      uint256 bonusTokensForReferral = bonusTokens.mul(REFERRAL_SHARE_RATE).div(100);
      uint256 bonusTokensForReferred = bonusTokens.sub(bonusTokensForReferral);
      token.mint(_beneficiary, bonusTokensForReferred);
      token.mint(referrals[_beneficiary], bonusTokensForReferral);
      ReferredBonusTokensEmitted(_beneficiary, bonusTokensForReferred);
      WhiteListBonusTokensEmitted(referrals[_beneficiary], bonusTokensForReferral);
    }
    else if (isWhiteListed[_beneficiary])
    {
      token.mint(_beneficiary, bonusTokens);
      WhiteListBonusTokensEmitted(_beneficiary, bonusTokens);
    }
  }

   
  function addWhiteListedInvestor(address _investor, string _referralCode) public
  {
    require(block.timestamp <= whiteListRegistrationEndTime);
    require(_investor != 0);
    require(!isWhiteListed[_investor]);
    bytes32 referralCodeHash = keccak256(_referralCode);
    require(referralCodes[referralCodeHash] == 0x0);
    
    isWhiteListed[_investor] = true;
    referralCodes[referralCodeHash] = _investor;
    WhiteListedInvestorAdded(_investor, _referralCode);
  }

   
  function loadWhiteList(address[] _investors, bytes32[] _referralCodes) public onlyOwner
  {
    require(_investors.length <= 30);
    require(_investors.length == _referralCodes.length);

    for (uint i = 0; i < _investors.length; i++)
    {
      isWhiteListed[_investors[i]] = true;
      referralCodes[_referralCodes[i]] = _investors[i];
    }
  }

   
  function addReferredInvestor(string _referralCode, address _referredInvestor) public
  {
    require(!hasEnded());
    require(!isWhiteListed[_referredInvestor]);
    require(_referredInvestor != 0);
    require(referrals[_referredInvestor] == 0x0);
    bytes32 referralCodeHash = keccak256(_referralCode);
    require(referralCodes[referralCodeHash] != 0);

    referrals[_referredInvestor] = referralCodes[referralCodeHash];
    ReferredInvestorAdded(_referralCode, _referredInvestor);
  }

   
  function loadReferredInvestors(bytes32[] _referralCodes, address[] _investors) public onlyOwner
  {
    require(_investors.length <= 30);
    require(_investors.length == _referralCodes.length);

    for (uint i = 0; i < _investors.length; i++)
    {
      referrals[_investors[i]] = referralCodes[_referralCodes[i]];
    }
  }

   
  function isReferred(address _investor) public constant returns (bool)
  {
    return referrals[_investor] != 0x0;
  }

   
  function validWhiteListedPurchase(address _investor) internal constant returns (bool)
  {
    return isWhiteListed[_investor] || isReferred(_investor) || block.timestamp > whiteListEndTime;
  }

   
  function computeBonusTokens(address _beneficiary, uint256 _weiAmount) internal constant returns (uint256)
  {
    if (isReferred(_beneficiary) || isWhiteListed[_beneficiary]) {
      uint256 bonusTokens = _weiAmount.mul(rate).mul(WHITELIST_BONUS_RATE).div(100);
      if (block.timestamp > whiteListEndTime) {
        bonusTokens = bonusTokens.div(2);
      }
      return bonusTokens;
    }
    else
    {
      return 0;
    }
  }

}

contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
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

contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) public {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() public {
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

contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

contract DemeterCrowdsale is
  RefundableCrowdsale,
  WhiteListCrowdsale,
  Pausable,
  Destructible
{

   
  uint8 constant public PERC_TOKENS_TO_INVESTOR = 30;

   
  uint8 constant public PERC_TOKENS_TO_RELEASE = 25;

   
  address constant public RELEASE_WALLET = 0x867D85437d27cA97e1EB574250efbba487aca637;

   
  uint8 constant public PERC_TOKENS_TO_DEV = 20;

   
  address constant public DEV_WALLET = 0x70323222694584c68BD5a29194bb72c248e715F7;

   
  uint8 constant public PERC_TOKENS_TO_BIZDEV = 25;

   
  address constant public BIZDEV_WALLET = 0xE43053e265F04f690021735E02BBA559Cea681D6;

   
  event CompanyTokensIssued(
    address indexed investor,
    uint256 value,
    uint256 amount
  );

   
  function DemeterCrowdsale(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _whiteListRegistrationEndTime,
    uint256 _whiteListEndTime,
    uint256 _rate,
    uint256 _cap,
    uint256 _goal,
    address _wallet
  ) public
    Crowdsale(_startTime, _endTime, _rate, _wallet)
    CappedCrowdsale(_cap)
    RefundableCrowdsale(_goal)
    WhiteListCrowdsale(_whiteListRegistrationEndTime, _whiteListEndTime)
  {
    DemeterToken(token).setUnlockTime(_endTime);
  }

   
  function buyTokens(address _beneficiary) public payable whenNotPaused {
    require(msg.value >= 0.1 ether);
     
     
    super.buyTokens(_beneficiary);
    
     
    issueCompanyTokens(_beneficiary, msg.value);
  }

   
  function destroy() public onlyOwner {
    vault.close();
    super.destroy();
    DemeterToken(token).destroyAndSend(this);
  }

   
  function destroyAndSend(address _recipient) public onlyOwner {
    vault.close();
    super.destroyAndSend(_recipient);
    DemeterToken(token).destroyAndSend(_recipient);
  }

   
  function updateGoal(uint256 _goal) public onlyOwner {
    require(_goal >= 0 && _goal <= cap);
    require(!hasEnded());

    goal = _goal;
  }

   
  function issueCompanyTokens(address _investor, uint256 _weiAmount) internal {
    uint256 investorTokens = _weiAmount.mul(rate);
    uint256 bonusTokens = computeBonusTokens(_investor, _weiAmount);
    uint256 companyTokens = investorTokens.mul(100 - PERC_TOKENS_TO_INVESTOR).div(PERC_TOKENS_TO_INVESTOR);
    uint256 totalTokens = investorTokens.add(companyTokens);
     
    uint256 devTokens = totalTokens.mul(PERC_TOKENS_TO_DEV).div(100);
    token.mint(DEV_WALLET, devTokens);
     
    uint256 bizDevTokens = (totalTokens.mul(PERC_TOKENS_TO_BIZDEV).div(100)).sub(bonusTokens);
    token.mint(BIZDEV_WALLET, bizDevTokens);
    uint256 actualCompanyTokens = companyTokens.sub(bonusTokens);
    uint256 releaseTokens = actualCompanyTokens.sub(bizDevTokens).sub(devTokens);
    token.mint(RELEASE_WALLET, releaseTokens);

    CompanyTokensIssued(_investor, _weiAmount, actualCompanyTokens);
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new DemeterToken();
  }

   
  function unlockTokens() internal {
    if (DemeterToken(token).unlockTime() > block.timestamp) {
      DemeterToken(token).setUnlockTime(block.timestamp);
    }
  }

   
  function finalization() internal {
    super.finalization();
    unlockTokens();
  }

}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return balances[_owner];
  }

}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval (address _spender, uint _addedValue) public
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public
    returns (bool success) {
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

contract TimeLockedToken is MintableToken
{

   
  uint256 public unlockTime = 0;

   
  modifier canTransfer() {
    require(unlockTime == 0 || block.timestamp > unlockTime);
    _;
  }

   
  function setUnlockTime(uint256 _unlockTime) public onlyOwner {
    require(unlockTime == 0 || _unlockTime < unlockTime);
    require(_unlockTime >= block.timestamp);

    unlockTime = _unlockTime;
  }

   
  function transfer(address _to, uint256 _value) public canTransfer returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint256 _value) public canTransfer returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

}

contract DemeterToken is TimeLockedToken, Destructible
{
  string public name = "Demeter";
  string public symbol = "DMT";
  uint256 public decimals = 18;
}