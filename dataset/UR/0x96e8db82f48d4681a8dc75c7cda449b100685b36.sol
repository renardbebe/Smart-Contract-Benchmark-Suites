 

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

 
contract FinalizableCrowdsale is Ownable, TimedCrowdsale {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 





 
contract CustomAdmin is Ownable {
   
  mapping(address => bool) public admins;

  event AdminAdded(address indexed _address);
  event AdminRemoved(address indexed _address);

   
  modifier onlyAdmin() {
    require(admins[msg.sender] || msg.sender == owner);
    _;
  }

   
   
  function addAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(!admins[_address]);

     
    require(_address != owner);

    admins[_address] = true;

    emit AdminAdded(_address);
  }

   
   
  function addManyAdmins(address[] _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && !admins[account] && account != owner){
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }
  }
  
   
   
  function removeAdmin(address _address) external onlyAdmin {
    require(_address != address(0));
    require(admins[_address]);

     
    require(_address != owner);

    admins[_address] = false;
    emit AdminRemoved(_address);
  }


   
   
  function removeManyAdmins(address[] _accounts) external onlyAdmin {
    for(uint8 i=0; i<_accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && admins[account] && account != owner){
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }
  }
}

 


 





 
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() external onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

   
  function unpause() external onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}

 




 
contract CustomWhitelist is CustomPausable {
  mapping(address => bool) public whitelist;

  event WhitelistAdded(address indexed _account);
  event WhitelistRemoved(address indexed _account);

   
  modifier ifWhitelisted(address _account) {
    require(_account != address(0));
    require(whitelist[_account]);

    _;
  }

   
   
  function addWhitelist(address _account) external whenNotPaused onlyAdmin {
    require(_account!=address(0));

    if(!whitelist[_account]) {
      whitelist[_account] = true;

      emit WhitelistAdded(_account);
    }
  }

   
   
  function addManyWhitelist(address[] _accounts) external whenNotPaused onlyAdmin {
    for(uint8 i=0;i<_accounts.length;i++) {
      if(_accounts[i] != address(0) && !whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = true;

        emit WhitelistAdded(_accounts[i]);
      }
    }
  }

   
   
  function removeWhitelist(address _account) external whenNotPaused onlyAdmin {
    require(_account != address(0));
    if(whitelist[_account]) {
      whitelist[_account] = false;

      emit WhitelistRemoved(_account);
    }
  }

   
   
  function removeManyWhitelist(address[] _accounts) external whenNotPaused onlyAdmin {
    for(uint8 i=0;i<_accounts.length;i++) {
      if(_accounts[i] != address(0) && whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = false;
        
        emit WhitelistRemoved(_accounts[i]);
      }
    }
  }
}

 




 
contract TokenPrice is CustomPausable {
   
  uint256 public tokenPriceInCents;

  event TokenPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setTokenPrice(uint256 _cents) public onlyAdmin whenNotPaused {
    require(_cents > 0);
    
    emit TokenPriceChanged(_cents, tokenPriceInCents );
    tokenPriceInCents  = _cents;
  }
}

 




 
contract EtherPrice is CustomPausable {
  uint256 public etherPriceInCents;  

  event EtherPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setEtherPrice(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit EtherPriceChanged(_cents, etherPriceInCents);
    etherPriceInCents = _cents;
  }
}

 

 


 
contract BinanceCoinPrice is CustomPausable {
  uint256 public binanceCoinPriceInCents;

  event BinanceCoinPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setBinanceCoinPrice(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit BinanceCoinPriceChanged(_cents, binanceCoinPriceInCents);
    binanceCoinPriceInCents = _cents;
  }
}

 

 


 
contract CreditsTokenPrice is CustomPausable {
  uint256 public creditsTokenPriceInCents;

  event CreditsTokenPriceChanged(uint256 _newPrice, uint256 _oldPrice);

  function setCreditsTokenPrice(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit CreditsTokenPriceChanged(_cents, creditsTokenPriceInCents);
    creditsTokenPriceInCents = _cents;
  }
}

 






 
contract BonusHolder is CustomPausable {
  using SafeMath for uint256;

   
  mapping(address => uint256) public bonusHolders;

   
  uint256 public releaseDate;

   
  ERC20 public bonusCoin;

   
  uint256 public bonusProvided;

   
  uint256 public bonusWithdrawn;

  event BonusReleaseDateSet(uint256 _releaseDate);
  event BonusAssigned(address indexed _address, uint _amount);
  event BonusWithdrawn(address indexed _address, uint _amount);

   
   
  constructor(ERC20 _bonusCoin) internal {
    bonusCoin = _bonusCoin;
  }

   
   
   
  function setReleaseDate(uint256 _releaseDate) external onlyAdmin whenNotPaused {
    require(releaseDate == 0);
    require(_releaseDate > now);

    releaseDate = _releaseDate;

    emit BonusReleaseDateSet(_releaseDate);
  }

   
   
   
  function assignBonus(address _investor, uint256 _bonus) internal {
    if(_bonus == 0){
      return;
    }

    bonusProvided = bonusProvided.add(_bonus);
    bonusHolders[_investor] = bonusHolders[_investor].add(_bonus);

    emit BonusAssigned(_investor, _bonus);
  }

   
   
  function withdrawBonus() external whenNotPaused {
    require(releaseDate != 0);
    require(now > releaseDate);

    uint256 amount = bonusHolders[msg.sender];
    require(amount > 0);

    bonusWithdrawn = bonusWithdrawn.add(amount);

    bonusHolders[msg.sender] = 0;
    require(bonusCoin.transfer(msg.sender, amount));

    emit BonusWithdrawn(msg.sender, amount);
  }

   
  function getRemainingBonus() public view returns(uint256) {
    return bonusProvided.sub(bonusWithdrawn);
  }
}

 












 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract PrivateSale is TokenPrice, EtherPrice, BinanceCoinPrice, CreditsTokenPrice, BonusHolder, FinalizableCrowdsale, CustomWhitelist {
   
  ERC20 public binanceCoin;

   
  ERC20 public creditsToken;

   
  uint256 public totalTokensSold;

   
  uint256 public totalSaleAllocation;

   
  uint256 public minContributionInUSDCents;

  mapping(address => uint256) public assignedBonusRates;
  uint[3] public bonusLimits;
  uint[3] public bonusPercentages;

   
  bool public initialized;

  event SaleInitialized();

  event MinimumContributionChanged(uint256 _newContribution, uint256 _oldContribution);
  event ClosingTimeChanged(uint256 _newClosingTime, uint256 _oldClosingTime);
  event FundsWithdrawn(address indexed _wallet, uint256 _amount);
  event ERC20Withdrawn(address indexed _contract, uint256 _amount);
  event TokensAllocatedForSale(uint256 _newAllowance, uint256 _oldAllowance);

   
   
   
   
   
   
  constructor(uint256 _startTime, uint256 _endTime, ERC20 _binanceCoin, ERC20 _creditsToken, ERC20 _vrhToken) public
  TimedCrowdsale(_startTime, _endTime)
  Crowdsale(1, msg.sender, _vrhToken)
  BonusHolder(_vrhToken) {
     
     
    binanceCoin = _binanceCoin;
    creditsToken = _creditsToken;
  }

   
   
   
   
   
   
  function initializePrivateSale(uint _etherPriceInCents, uint _tokenPriceInCents, uint _binanceCoinPriceInCents, uint _creditsTokenPriceInCents, uint _minContributionInUSDCents) external onlyAdmin {
    require(!initialized);
    require(_etherPriceInCents > 0);
    require(_tokenPriceInCents > 0);
    require(_binanceCoinPriceInCents > 0);
    require(_creditsTokenPriceInCents > 0);
    require(_minContributionInUSDCents > 0);

    setEtherPrice(_etherPriceInCents);
    setTokenPrice(_tokenPriceInCents);
    setBinanceCoinPrice(_binanceCoinPriceInCents);
    setCreditsTokenPrice(_creditsTokenPriceInCents);
    setMinimumContribution(_minContributionInUSDCents);

    increaseTokenSaleAllocation();

    bonusLimits[0] = 25000000;
    bonusLimits[1] = 10000000;
    bonusLimits[2] = 1500000;

    bonusPercentages[0] = 50;
    bonusPercentages[1] = 40;
    bonusPercentages[2] = 35;


    initialized = true;

    emit SaleInitialized();
  }

   
  function contributeInBNB() external ifWhitelisted(msg.sender) whenNotPaused onlyWhileOpen {
    require(initialized);

     
    uint256 allowance = binanceCoin.allowance(msg.sender, this);
    require (allowance > 0, "You have not approved any Binance Coin for this contract to receive.");

     
    uint256 contributionCents  = convertToCents(allowance, binanceCoinPriceInCents, 18);


    if(assignedBonusRates[msg.sender] == 0) {
      require(contributionCents >= minContributionInUSDCents);
      assignedBonusRates[msg.sender] = getBonusPercentage(contributionCents);
    }

     
    uint256 numTokens = contributionCents.mul(1 ether).div(tokenPriceInCents);

     
    uint256 bonus = calculateBonus(numTokens, assignedBonusRates[msg.sender]);

    require(totalTokensSold.add(numTokens).add(bonus) <= totalSaleAllocation);

     
    require(binanceCoin.transferFrom(msg.sender, this, allowance));

     
    require(token.transfer(msg.sender, numTokens));

     
    assignBonus(msg.sender, bonus);

    totalTokensSold = totalTokensSold.add(numTokens).add(bonus);
  }

  function contributeInCreditsToken() external ifWhitelisted(msg.sender) whenNotPaused onlyWhileOpen {
    require(initialized);

     
    uint256 allowance = creditsToken.allowance(msg.sender, this);
    require (allowance > 0, "You have not approved any Credits Token for this contract to receive.");

     
    uint256 contributionCents = convertToCents(allowance, creditsTokenPriceInCents, 6);

    if(assignedBonusRates[msg.sender] == 0) {
      require(contributionCents >= minContributionInUSDCents);
      assignedBonusRates[msg.sender] = getBonusPercentage(contributionCents);
    }

     
    uint256 numTokens = contributionCents.mul(1 ether).div(tokenPriceInCents);

     
    uint256 bonus = calculateBonus(numTokens, assignedBonusRates[msg.sender]);

    require(totalTokensSold.add(numTokens).add(bonus) <= totalSaleAllocation);

     
    require(creditsToken.transferFrom(msg.sender, this, allowance));

     
    require(token.transfer(msg.sender, numTokens));

     
    assignBonus(msg.sender, bonus);

    totalTokensSold = totalTokensSold.add(numTokens).add(bonus);
  }

  function setMinimumContribution(uint256 _cents) public whenNotPaused onlyAdmin {
    require(_cents > 0);

    emit MinimumContributionChanged(minContributionInUSDCents, _cents);
    minContributionInUSDCents = _cents;
  }

   
  uint256 private amountInUSDCents;

   
   
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused ifWhitelisted(_beneficiary) {
    require(initialized);

    amountInUSDCents = convertToCents(_weiAmount, etherPriceInCents, 18);

    if(assignedBonusRates[_beneficiary] == 0) {
      require(amountInUSDCents >= minContributionInUSDCents);
      assignedBonusRates[_beneficiary] = getBonusPercentage(amountInUSDCents);
    }

     
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

   
   
   
   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
     
    uint256 bonus = calculateBonus(_tokenAmount, assignedBonusRates[_beneficiary]);

     
    require(totalTokensSold.add(_tokenAmount).add(bonus) <= totalSaleAllocation);

     
    assignBonus(_beneficiary, bonus);

     
    totalTokensSold = totalTokensSold.add(_tokenAmount).add(bonus);

     
    super._processPurchase(_beneficiary, _tokenAmount);
  }

   
   
   
  function calculateBonus(uint256 _tokenAmount, uint256 _percentage) public pure returns (uint256) {
    return _tokenAmount.mul(_percentage).div(100);
  }

   
   
  function setBonuses(uint[] _bonusLimits, uint[] _bonusPercentages) public onlyAdmin {
    require(_bonusLimits.length == _bonusPercentages.length);
    require(_bonusPercentages.length == 3);
    for(uint8 i=0;i<_bonusLimits.length;i++) {
      bonusLimits[i] = _bonusLimits[i];
      bonusPercentages[i] = _bonusPercentages[i];
    }
  }


   
  function getBonusPercentage(uint _cents) view public returns(uint256) {
    for(uint8 i=0;i<bonusLimits.length;i++) {
      if(_cents >= bonusLimits[i]) {
        return bonusPercentages[i];
      }
    }
  }

   
   
  function convertToCents(uint256 _tokenAmount, uint256 _priceInCents, uint256 _decimals) public pure returns (uint256) {
    return _tokenAmount.mul(_priceInCents).div(10**_decimals);
  }

   
   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(etherPriceInCents).div(tokenPriceInCents);
  }

   
   
  function getTokenAmountForWei(uint256 _weiAmount) external view returns (uint256) {
    return _getTokenAmount(_weiAmount);
  }

   
  function increaseTokenSaleAllocation() public whenNotPaused onlyAdmin {
     
    uint256 allowance = token.allowance(msg.sender, this);

     
    uint256 current = totalSaleAllocation;

     
    totalSaleAllocation = totalSaleAllocation.add(allowance);

     
    require(token.transferFrom(msg.sender, this, allowance));

    emit TokensAllocatedForSale(totalSaleAllocation, current);
  }


   
   
  function withdrawToken(address _token) external onlyAdmin {
    bool isVRH = _token == address(token);
    ERC20 erc20 = ERC20(_token);

    uint256 balance = erc20.balanceOf(this);

     
     
    if(isVRH) {
      balance = balance.sub(getRemainingBonus());
      changeClosingTime(now);
    }

    require(erc20.transfer(msg.sender, balance));

    emit ERC20Withdrawn(_token, balance);
  }


   
  function finalizeCrowdsale() public onlyAdmin {
    require(!isFinalized);
    require(hasClosed());

    uint256 unsold = token.balanceOf(this).sub(bonusProvided);

    if(unsold > 0) {
      require(token.transfer(msg.sender, unsold));
    }

    isFinalized = true;

    emit Finalized();
  }

   
   
  function hasClosed() public view returns (bool) {
    return (totalTokensSold >= totalSaleAllocation) || super.hasClosed();
  }

   
   
  function finalization() internal {
    revert();
  }

   
  function _forwardFunds() internal {
     
  }

   
   
  function withdrawFunds(uint256 _amount) external whenNotPaused onlyAdmin {
    require(_amount <= address(this).balance);

    msg.sender.transfer(_amount);

    emit FundsWithdrawn(msg.sender, _amount);
  }

   
   
  function changeClosingTime(uint256 _closingTime) public whenNotPaused onlyAdmin {
    emit ClosingTimeChanged(_closingTime, closingTime);

    closingTime = _closingTime;
  }

  function getRemainingTokensForSale() public view returns(uint256) {
    return totalSaleAllocation.sub(totalTokensSold);
  }
}