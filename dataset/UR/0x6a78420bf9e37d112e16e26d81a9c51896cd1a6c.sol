 

pragma solidity 0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
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

 

 
contract HasNoEther is Ownable {

   
  constructor() public payable {
    require(msg.value == 0);
  }

   
  function() external {
  }

   
  function reclaimEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }
}

 

 
contract Finalizable is Ownable {
  using SafeMath for uint256;

   
  modifier onlyFinalized() {
    require(isFinalized, "Contract not finalized.");
    _;
  }

   
  modifier onlyNotFinalized() {
    require(!isFinalized, "Contract already finalized.");
    _;
  }

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public onlyOwner onlyNotFinalized {
    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
     
  }

}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract TokenEscrow is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  event Deposited(address indexed payee, uint256 amount);
  event Withdrawn(address indexed payee, uint256 amount);

   
  mapping(address => uint256) private deposits;

   
  ERC20 public token;

  constructor(ERC20 _token) public {
    require(_token != address(0), "Token address should not be 0x0.");
    token = _token;
  }

   
  function depositsOf(address _payee) public view returns (uint256) {
    return deposits[_payee];
  }

   
  function deposit(address _payee, uint256 _amount) public onlyOwner {
    require(_payee != address(0), "Destination address should not be 0x0.");
    require(_payee != address(this), "Deposits should not be made to this contract.");

    deposits[_payee] = deposits[_payee].add(_amount);
    token.safeTransferFrom(owner, this, _amount);

    emit Deposited(_payee, _amount);
  }

   
  function withdraw(address _payee) public onlyOwner {
    uint256 payment = deposits[_payee];
    assert(token.balanceOf(address(this)) >= payment);

    deposits[_payee] = 0;
    token.safeTransfer(_payee, payment);

    emit Withdrawn(_payee, payment);
  }
}

 

 
contract TokenConditionalEscrow is TokenEscrow {

   
  function withdrawalAllowed(address _payee) public view returns (bool);

   
  function withdraw(address _payee) public {
    require(withdrawalAllowed(_payee), "Withdrawal is not allowed.");
    super.withdraw(_payee);
  }
}

 

 
contract TokenTimelockEscrow is TokenConditionalEscrow {

   
  uint256 public releaseTime;

  constructor(uint256 _releaseTime) public {
     
    require(_releaseTime > block.timestamp, "Release time should be in the future.");
    releaseTime = _releaseTime;
  }

   
  function withdrawalAllowed(address _payee) public view returns (bool) {
     
    return block.timestamp >= releaseTime;
  }
}

 

 
contract TokenTimelockFactory {

   
  function create(
    ERC20 _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
    returns (address wallet);
}

 

 
contract TokenVestingFactory {

   
  function create(
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
    returns (address wallet);
}

 

 
contract HasNoContracts is Ownable {

   
  function reclaimContract(address _contractAddr) external onlyOwner {
    Ownable contractInst = Ownable(_contractAddr);
    contractInst.transferOwnership(owner);
  }
}

 

 
contract TokenTimelockEscrowImpl is HasNoEther, HasNoContracts, TokenTimelockEscrow {

  constructor(ERC20 _token, uint256 _releaseTime)
    public
    TokenEscrow(_token)
    TokenTimelockEscrow(_releaseTime)
  {
     
  }
}

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 

 
contract HasNoTokens is CanReclaimToken {

  
  function tokenFallback(
    address _from,
    uint256 _value,
    bytes _data
  )
    external
    pure
  {
    _from;
    _value;
    _data;
    revert();
  }

}

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract IndividuallyCappedCrowdsale is Ownable, Crowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public contributions;
  mapping(address => uint256) public caps;

   
  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner {
    caps[_beneficiary] = _cap;
  }

   
  function setGroupCap(
    address[] _beneficiaries,
    uint256 _cap
  )
    external
    onlyOwner
  {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      caps[_beneficiaries[i]] = _cap;
    }
  }

   
  function getUserCap(address _beneficiary) public view returns (uint256) {
    return caps[_beneficiary];
  }

   
  function getUserContribution(address _beneficiary)
    public view returns (uint256)
  {
    return contributions[_beneficiary];
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(contributions[_beneficiary].add(_weiAmount) <= caps[_beneficiary]);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._updatePurchasingState(_beneficiary, _weiAmount);
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
  }

}

 

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  address public tokenWallet;

   
  constructor(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

   
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}

 

 
contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

   
  function withdrawTokens() public {
    _withdrawTokens(msg.sender);
  }

   
  function _withdrawTokens(address _beneficiary) internal {
    require(hasClosed(), "Crowdsale not closed.");
    uint256 amount = balances[_beneficiary];
    require(amount > 0, "Beneficiary has zero balance.");
    balances[_beneficiary] = 0;
    _deliverTokens(_beneficiary, amount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    balances[_beneficiary] = balances[_beneficiary].add(_tokenAmount);
  }

}

 

 
 
contract TokenCrowdsale
  is
    HasNoTokens,
    HasNoContracts,
    TimedCrowdsale,
    CappedCrowdsale,
    IndividuallyCappedCrowdsale,
    PostDeliveryCrowdsale,
    AllowanceCrowdsale
{

   
  uint256 public withdrawTime;

   
  uint256 public tokensSold;

   
  uint256 public tokensDelivered;

  constructor(
    uint256 _rate,
    address _wallet,
    ERC20 _token,
    address _tokenWallet,
    uint256 _cap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _withdrawTime
  )
    public
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    CappedCrowdsale(_cap)
    AllowanceCrowdsale(_tokenWallet)
  {
    require(_withdrawTime >= _closingTime, "Withdrawals should open after crowdsale closes.");
    withdrawTime = _withdrawTime;
  }

   
  function hasEnded() public view returns (bool) {
    return hasClosed() || capReached();
  }

   
  function withdrawTokens(address _beneficiary) public {
    _withdrawTokens(_beneficiary);
  }

   
  function withdrawTokens(address[] _beneficiaries) public {
    for (uint32 i = 0; i < _beneficiaries.length; i ++) {
      _withdrawTokens(_beneficiaries[i]);
    }
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    super._processPurchase(_beneficiary, _tokenAmount);
    tokensSold = tokensSold.add(_tokenAmount);
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    super._deliverTokens(_beneficiary, _tokenAmount);
    tokensDelivered = tokensDelivered.add(_tokenAmount);
  }

   
  function _withdrawTokens(address _beneficiary) internal {
     
    require(block.timestamp > withdrawTime, "Withdrawals not open.");
    super._withdrawTokens(_beneficiary);
  }

}

 

 
contract TokenDistributor is HasNoEther, Finalizable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
   
  event ContractInstantiation(address sender, address instantiation);
  event CrowdsaleInstantiated(address sender, address instantiation, uint256 allowance);

   
   
  address public benefactor;

   
   
   
   
  uint256 public rate;

    
  address public wallet;

   
  ERC20 public token;

   
  uint256 public cap;

   
  uint256 public openingTime;
  uint256 public closingTime;

   
  uint256 public withdrawTime;

   
  uint256 public weiRaised;

   
  TokenCrowdsale public crowdsale;

   
  TokenTimelockEscrow public presaleEscrow;

   
  TokenTimelockEscrow public bonusEscrow;

   
  TokenTimelockFactory public timelockFactory;

   
  TokenVestingFactory public vestingFactory;

   
  modifier onlyIfCrowdsale() {
    require(crowdsale != address(0), "Crowdsale not started.");
    _;
  }

  constructor(
    address _benefactor,
    uint256 _rate,
    address _wallet,
    ERC20 _token,
    uint256 _cap,
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _withdrawTime,
    uint256 _bonusTime
  )
    public
  {
    require(address(_benefactor) != address(0), "Benefactor address should not be 0x0.");
    require(_rate > 0, "Rate should not be > 0.");
    require(_wallet != address(0), "Wallet address should not be 0x0.");
    require(address(_token) != address(0), "Token address should not be 0x0.");
    require(_cap > 0, "Cap should be > 0.");
     
    require(_openingTime > block.timestamp, "Opening time should be in the future.");
    require(_closingTime > _openingTime, "Closing time should be after opening.");
    require(_withdrawTime >= _closingTime, "Withdrawals should open after crowdsale closes.");
    require(_bonusTime > _withdrawTime, "Bonus time should be set after withdrawals open.");

    benefactor = _benefactor;
    rate = _rate;
    wallet = _wallet;
    token = _token;
    cap = _cap;
    openingTime = _openingTime;
    closingTime = _closingTime;
    withdrawTime = _withdrawTime;

    presaleEscrow = new TokenTimelockEscrowImpl(_token, _withdrawTime);
    bonusEscrow = new TokenTimelockEscrowImpl(_token, _bonusTime);
  }

   
  function setUserCap(address _beneficiary, uint256 _cap) external onlyOwner onlyIfCrowdsale {
    crowdsale.setUserCap(_beneficiary, _cap);
  }

   
  function setGroupCap(address[] _beneficiaries, uint256 _cap) external onlyOwner onlyIfCrowdsale {
    crowdsale.setGroupCap(_beneficiaries, _cap);
  }

   
  function getUserCap(address _beneficiary) public view onlyIfCrowdsale returns (uint256) {
    return crowdsale.getUserCap(_beneficiary);
  }

   
  function depositPresale(address _dest, uint256 _amount) public onlyOwner onlyNotFinalized {
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    token.transferFrom(benefactor, this, _amount);
    token.approve(presaleEscrow, _amount);
    presaleEscrow.deposit(_dest, _amount);
  }

   
  function depositPresale(address _dest, uint256 _amount, uint256 _weiAmount) public {
    require(cap >= weiRaised.add(_weiAmount), "Cap reached.");
    depositPresale(_dest, _amount);
    weiRaised = weiRaised.add(_weiAmount);
  }

   
  function withdrawPresale() public {
    presaleEscrow.withdraw(msg.sender);
  }

   
  function withdrawPresale(address _beneficiary) public {
    presaleEscrow.withdraw(_beneficiary);
  }

   
  function withdrawPresale(address[] _beneficiaries) public {
    for (uint32 i = 0; i < _beneficiaries.length; i ++) {
      presaleEscrow.withdraw(_beneficiaries[i]);
    }
  }

   
  function depositBonus(address _dest, uint256 _amount) public onlyOwner onlyNotFinalized {
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    token.transferFrom(benefactor, this, _amount);
    token.approve(bonusEscrow, _amount);
    bonusEscrow.deposit(_dest, _amount);
  }

   
  function withdrawBonus() public {
    bonusEscrow.withdraw(msg.sender);
  }

   
  function withdrawBonus(address _beneficiary) public {
    bonusEscrow.withdraw(_beneficiary);
  }

   
  function withdrawBonus(address[] _beneficiaries) public {
    for (uint32 i = 0; i < _beneficiaries.length; i ++) {
      bonusEscrow.withdraw(_beneficiaries[i]);
    }
  }

   
  function depositPresaleWithBonus(
    address _dest,
    uint256 _amount,
    uint256 _bonusAmount
  )
    public
  {
    depositPresale(_dest, _amount);
    depositBonus(_dest, _bonusAmount);
  }

   
  function depositPresaleWithBonus(
    address _dest,
    uint256 _amount,
    uint256 _weiAmount,
    uint256 _bonusAmount
  )
    public
  {
    depositPresale(_dest, _amount, _weiAmount);
    depositBonus(_dest, _bonusAmount);
  }

   
  function setTokenTimelockFactory(address _timelockFactory) public onlyOwner {
    require(_timelockFactory != address(0), "Factory address should not be 0x0.");
    require(timelockFactory == address(0), "Factory already initalizied.");
    timelockFactory = TokenTimelockFactory(_timelockFactory);
  }

   
  function depositAndLock(
    address _dest,
    uint256 _amount,
    uint256 _releaseTime
  )
    public
    onlyOwner
    onlyNotFinalized
    returns (address tokenWallet)
  {
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    require(_dest != address(0), "Destination address should not be 0x0.");
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(_releaseTime >= withdrawTime, "Tokens should unlock after withdrawals open.");
    tokenWallet = timelockFactory.create(
      token,
      _dest,
      _releaseTime
    );
    token.transferFrom(benefactor, tokenWallet, _amount);
  }

   
  function setTokenVestingFactory(address _vestingFactory) public onlyOwner {
    require(_vestingFactory != address(0), "Factory address should not be 0x0.");
    require(vestingFactory == address(0), "Factory already initalizied.");
    vestingFactory = TokenVestingFactory(_vestingFactory);
  }

   
  function depositAndVest(
    address _dest,
    uint256 _amount,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration
  )
    public
    onlyOwner
    onlyNotFinalized
    returns (address tokenWallet)
  {
    require(token.allowance(benefactor, this) >= _amount, "Not enough allowance.");
    require(_dest != address(0), "Destination address should not be 0x0.");
    require(_dest != address(this), "Transfering tokens to this contract address is not allowed.");
    require(_start.add(_cliff) >= withdrawTime, "Tokens should unlock after withdrawals open.");
    bool revocable = false;
    tokenWallet = vestingFactory.create(
      _dest,
      _start,
      _cliff,
      _duration,
      revocable
    );
    token.transferFrom(benefactor, tokenWallet, _amount);
  }

   
  function claimUnsold(address _beneficiary) public onlyIfCrowdsale onlyOwner {
     
    require(block.timestamp > withdrawTime, "Withdrawals not open.");
    uint256 sold = crowdsale.tokensSold();
    uint256 delivered = crowdsale.tokensDelivered();
    uint256 toDeliver = sold.sub(delivered);

    uint256 balance = token.balanceOf(this);
    uint256 claimable = balance.sub(toDeliver);

    if (claimable > 0) {
      token.safeTransfer(_beneficiary, claimable);
    }
  }

   
  function finalization() internal {
    uint256 crowdsaleCap = cap.sub(weiRaised);
    if (crowdsaleCap < 1 ether) {
       
      return;
    }

    address tokenWallet = this;
    crowdsale = new TokenCrowdsale(
      rate,
      wallet,
      token,
      tokenWallet,
      crowdsaleCap,
      openingTime,
      closingTime,
      withdrawTime
    );
    uint256 allowance = token.allowance(benefactor, this);
    token.transferFrom(benefactor, this, allowance);
    token.approve(crowdsale, allowance);
    emit CrowdsaleInstantiated(msg.sender, crowdsale, allowance);
  }

}