 

pragma solidity 0.4.24;

 

 
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

 

 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract CappedToken is MintableToken {

  uint256 public cap;

  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    onlyOwner
    canMint
    public
    returns (bool)
  {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
  }

}

 

contract GambioToken is CappedToken {


  using SafeMath for uint256;

  string public name = "GMB";
  string public symbol = "GMB";
  uint8 public decimals = 18;

  event Burn(address indexed burner, uint256 value);
  event BurnTransferred(address indexed previousBurner, address indexed newBurner);

  address burnerRole;

  modifier onlyBurner() {
    require(msg.sender == burnerRole);
    _;
  }

  constructor(address _burner, uint256 _cap) public CappedToken(_cap) {
    burnerRole = _burner;
  }

  function transferBurnRole(address newBurner) public onlyBurner {
    require(newBurner != address(0));
    emit BurnTransferred(burnerRole, newBurner);
    burnerRole = newBurner;
  }

  function burn(uint256 _value) public onlyBurner {
    require(_value <= balances[msg.sender]);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(msg.sender, _value);
    emit Transfer(msg.sender, address(0), _value);
  }
}

 

contract Crowdsale {


  using SafeMath for uint256;

   
  GambioToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

  uint256 public rate;

   
  address public wallet;

   
  uint256 public weiRaised;

  event TokenPurchase(address indexed beneficiary, uint256 indexed value, uint256 indexed amount, uint256 transactionId);

  constructor(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _rate,
    address _wallet,
    uint256 _initialWeiRaised,
    uint256 _tokenCap) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_wallet != address(0));
    require(_rate > 0);
    require(_tokenCap > 0);

    token = new GambioToken(_wallet, _tokenCap);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    weiRaised = _initialWeiRaised;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
}

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 

pragma solidity ^0.4.23;






 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

 

contract GambioVesting is TokenVesting {


  using SafeMath for uint256;

  uint256 public previousRelease;
  uint256 period;

  constructor(uint256 _period, address _beneficiary, uint256 _start, uint256 _cliff, uint256 _duration, bool _revocable)
  public
  TokenVesting(_beneficiary, _start, _cliff, _duration, _revocable) {
     

    period = _period;
    previousRelease = now;
  }

   
  function release(ERC20Basic token) public {
    require(now >= previousRelease.add(period));

    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    previousRelease = now;

    emit Released(unreleased);
  }

}

 

contract CappedCrowdsale is Crowdsale, Ownable {


  using SafeMath for uint256;

  uint256 public hardCap;
  bool public isFinalized = false;

   
  uint256 public vestingTokens;
  uint256 public vestingDuration;
  uint256 public vestingPeriod;
  address public vestingBeneficiary;
  GambioVesting public vesting;

  event Finalized();
  event FinishMinting();

  event TokensMinted(
    address indexed beneficiary,
    uint256 indexed amount
  );

  constructor(uint256 _hardCap, uint256[] _vestingData, address _beneficiary)
  public {

    require(_vestingData.length == 3);
    require(_hardCap > 0);
    require(_vestingData[0] > 0);
    require(_vestingData[1] > 0);
    require(_vestingData[2] > 0);
    require(_beneficiary != address(0));

    hardCap = _hardCap;
    vestingTokens = _vestingData[0];
    vestingDuration = _vestingData[1];
    vestingPeriod = _vestingData[2];
    vestingBeneficiary = _beneficiary;
  }

   
  function finalize() public onlyOwner {
    require(!isFinalized);

    vesting = new GambioVesting(vestingPeriod, vestingBeneficiary, now, 0, vestingDuration, false);

    token.mint(address(vesting), vestingTokens);

    emit Finalized();
    isFinalized = true;
  }

  function finishMinting() public onlyOwner {
    require(token.mintingFinished() == false);
    require(isFinalized);
    token.finishMinting();

    emit FinishMinting();
  }

  function mint(address beneficiary, uint256 amount) public onlyOwner {
    require(!token.mintingFinished());
    require(isFinalized);
    require(amount > 0);
    require(beneficiary != address(0));
    token.mint(beneficiary, amount);

    emit TokensMinted(beneficiary, amount);
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= hardCap;
    return super.hasEnded() || capReached || isFinalized;
  }

}

 

contract OnlyWhiteListedAddresses is Ownable {


  using SafeMath for uint256;
  address utilityAccount;
  mapping(address => bool) whitelist;
  mapping(address => address) public referrals;

  modifier onlyOwnerOrUtility() {
    require(msg.sender == owner || msg.sender == utilityAccount);
    _;
  }

  event WhitelistedAddresses(
    address[] users
  );

  event ReferralsAdded(
    address[] user,
    address[] referral
  );

  constructor(address _utilityAccount) public {
    utilityAccount = _utilityAccount;
  }

  function whitelistAddress(address[] users) public onlyOwnerOrUtility {
    for (uint i = 0; i < users.length; i++) {
      whitelist[users[i]] = true;
    }
    emit WhitelistedAddresses(users);
  }

  function addAddressReferrals(address[] users, address[] _referrals) public onlyOwnerOrUtility {
    require(users.length == _referrals.length);
    for (uint i = 0; i < users.length; i++) {
      require(isWhiteListedAddress(users[i]));

      referrals[users[i]] = _referrals[i];
    }
    emit ReferralsAdded(users, _referrals);
  }

  function isWhiteListedAddress(address addr) public view returns (bool) {
    return whitelist[addr];
  }
}

 

contract GambioCrowdsale is CappedCrowdsale, OnlyWhiteListedAddresses {
  using SafeMath for uint256;

  struct TokenPurchaseRecord {
    uint256 timestamp;
    uint256 weiAmount;
    address beneficiary;
  }

  uint256 transactionId = 1;

  mapping(uint256 => TokenPurchaseRecord) pendingTransactions;

  mapping(uint256 => bool) completedTransactions;

  uint256 public referralPercentage;

  uint256 public individualCap;

   
  event TokenPurchaseRequest(
    uint256 indexed transactionId,
    address beneficiary,
    uint256 indexed timestamp,
    uint256 indexed weiAmount,
    uint256 tokensAmount
  );

  event ReferralTokensSent(
    address indexed beneficiary,
    uint256 indexed tokensAmount,
    uint256 indexed transactionId
  );

  event BonusTokensSent(
    address indexed beneficiary,
    uint256 indexed tokensAmount,
    uint256 indexed transactionId
  );

  constructor(
    uint256 _startTime,
    uint256 _endTime,
    uint256 _icoHardCapWei,
    uint256 _referralPercentage,
    uint256 _rate,
    address _wallet,
    uint256 _privateWeiRaised,
    uint256 _individualCap,
    address _utilityAccount,
    uint256 _tokenCap,
    uint256[] _vestingData
  )
  public
  OnlyWhiteListedAddresses(_utilityAccount)
  CappedCrowdsale(_icoHardCapWei, _vestingData, _wallet)
  Crowdsale(_startTime, _endTime, _rate, _wallet, _privateWeiRaised, _tokenCap)
  {
    referralPercentage = _referralPercentage;
    individualCap = _individualCap;
  }

   
  function() external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(!isFinalized);
    require(beneficiary == msg.sender);
    require(msg.value != 0);
    require(msg.value >= individualCap);

    uint256 weiAmount = msg.value;
    require(isWhiteListedAddress(beneficiary));
    require(validPurchase(weiAmount));

     
    weiRaised = weiRaised.add(weiAmount);

    uint256 _transactionId = transactionId;
    uint256 tokensAmount = weiAmount.mul(rate);

    pendingTransactions[_transactionId] = TokenPurchaseRecord(now, weiAmount, beneficiary);
    transactionId += 1;


    emit TokenPurchaseRequest(_transactionId, beneficiary, now, weiAmount, tokensAmount);
    forwardFunds();
  }

  function delayIcoEnd(uint256 newDate) public onlyOwner {
    require(newDate != 0);
    require(newDate > now);
    require(!hasEnded());
    require(newDate > endTime);

    endTime = newDate;
  }

  function increaseWeiRaised(uint256 amount) public onlyOwner {
    require(now < startTime);
    require(amount > 0);
    require(weiRaised.add(amount) <= hardCap);

    weiRaised = weiRaised.add(amount);
  }

  function decreaseWeiRaised(uint256 amount) public onlyOwner {
    require(now < startTime);
    require(amount > 0);
    require(weiRaised > 0);
    require(weiRaised >= amount);

    weiRaised = weiRaised.sub(amount);
  }

  function issueTokensMultiple(uint256[] _transactionIds, uint256[] bonusTokensAmounts) public onlyOwner {
    require(isFinalized);
    require(_transactionIds.length == bonusTokensAmounts.length);
    for (uint i = 0; i < _transactionIds.length; i++) {
      issueTokens(_transactionIds[i], bonusTokensAmounts[i]);
    }
  }

  function issueTokens(uint256 _transactionId, uint256 bonusTokensAmount) internal {
    require(completedTransactions[_transactionId] != true);
    require(pendingTransactions[_transactionId].timestamp != 0);

    TokenPurchaseRecord memory record = pendingTransactions[_transactionId];
    uint256 tokens = record.weiAmount.mul(rate);
    address referralAddress = referrals[record.beneficiary];

    token.mint(record.beneficiary, tokens);
    emit TokenPurchase(record.beneficiary, record.weiAmount, tokens, _transactionId);

    completedTransactions[_transactionId] = true;

    if (bonusTokensAmount != 0) {
      require(bonusTokensAmount != 0);
      token.mint(record.beneficiary, bonusTokensAmount);
      emit BonusTokensSent(record.beneficiary, bonusTokensAmount, _transactionId);
    }

    if (referralAddress != address(0)) {
      uint256 referralAmount = tokens.mul(referralPercentage).div(uint256(100));
      token.mint(referralAddress, referralAmount);
      emit ReferralTokensSent(referralAddress, referralAmount, _transactionId);
    }
  }

  function validPurchase(uint256 weiAmount) internal view returns (bool) {
    bool withinCap = weiRaised.add(weiAmount) <= hardCap;
    bool withinCrowdsaleInterval = now >= startTime && now <= endTime;
    return withinCrowdsaleInterval && withinCap;
  }

  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

contract Migrations {


  address public owner;
  uint public lastCompletedMigration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  constructor() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    lastCompletedMigration = completed;
  }

  function upgrade(address newAddress) public restricted {
    Migrations upgraded = Migrations(newAddress);
    upgraded.setCompleted(lastCompletedMigration);
  }
}