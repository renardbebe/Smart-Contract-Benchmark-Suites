 

 


 

pragma solidity >=0.5.0 <0.6.0;


 
contract IERC20 {
  function name() public view returns (string memory);
  function symbol() public view returns (string memory);
  function decimals() public view returns (uint256);
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  function increaseApproval(address spender, uint addedValue)
    public returns (bool);

  function decreaseApproval(address spender, uint subtractedValue)
    public returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

pragma solidity >=0.5.0 <0.6.0;



 
contract ITokensale {

  function () external payable;
  function investETH() public payable;

  function token() public view returns (IERC20);
  function vaultETH() public view returns (address);
  function vaultERC20() public view returns (address);
  function tokenPrice() public view returns (uint256);
  function totalRaised() public view returns (uint256);
  function totalUnspentETH() public view returns (uint256);
  function totalRefundedETH() public view returns (uint256);
  function availableSupply() public view returns (uint256);
  
  function investorUnspentETH(address _investor) public view returns (uint256);
  function investorInvested(address _investor) public view returns (uint256);
  function investorTokens(address _investor) public view returns (uint256);

  function tokenInvestment(address _investor, uint256 _amount) public view returns (uint256);
  function refundManyUnspentETH(address payable[] memory _receivers) public returns (bool);
  function refundUnspentETH() public returns (bool);
  function withdrawAllETHFunds() public returns (bool);
  function fundETH() public payable;

  event RefundETH(address indexed recipient, uint256 amount);
  event WithdrawETH(uint256 amount);
  event FundETH(uint256 amount);
  event Investment(address indexed investor, uint256 invested, uint256 tokens);
}

 

pragma solidity >=0.5.0 <0.6.0;


 
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

 

pragma solidity >=0.5.0 <0.6.0;


 
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

 

pragma solidity >=0.5.0 <0.6.0;



 
contract Operable is Ownable {

  mapping (address => bool) private operators_;

   
  modifier onlyOperator {
    require(operators_[msg.sender], "OP01");
    _;
  }

   
  constructor() public {
    defineOperator("Owner", msg.sender);
  }

   
  function isOperator(address _address) public view returns (bool) {
    return operators_[_address];
  }

   
  function removeOperator(address _address) public onlyOwner {
    require(operators_[_address], "OP02");
    operators_[_address] = false;
    emit OperatorRemoved(_address);
  }

   
  function defineOperator(string memory _role, address _address)
    public onlyOwner
  {
    require(!operators_[_address], "OP03");
    operators_[_address] = true;
    emit OperatorDefined(_role, _address);
  }

  event OperatorRemoved(address address_);
  event OperatorDefined(
    string role,
    address address_
  );
}

 

pragma solidity >=0.5.0 <0.6.0;



 
contract Pausable is Operable {
  event Pause();
  event Unpause();

  bool public paused = false;


   
  modifier whenNotPaused() {
    require(!paused, "PA01");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "PA02");
    _;
  }

   
  function pause() public onlyOperator whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOperator whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

pragma solidity >=0.5.0 <0.6.0;







 
contract BaseTokensale is ITokensale, Operable, Pausable {
  using SafeMath for uint256;

   
  IERC20 internal token_;
  address payable internal vaultETH_;
  address internal vaultERC20_;

  uint256 internal tokenPrice_;
  uint256 internal priceUnit_;

  uint256 internal totalRaised_;
  uint256 internal totalTokensSold_;

  uint256 internal totalUnspentETH_;
  uint256 internal totalRefundedETH_;

  struct Investor {
    uint256 unspentETH;
    uint256 invested;
    uint256 tokens;
  }
  mapping(address => Investor) internal investors;

   
  constructor(
    IERC20 _token,
    address _vaultERC20,
    address payable _vaultETH,
    uint256 _tokenPrice,
    uint256 _priceUnit
  ) public
  {
    require(_tokenPrice > 0, "TOS01");
    require(_priceUnit > 0, "TOS02");

    token_ = _token;
    vaultERC20_ = _vaultERC20;
    vaultETH_ = _vaultETH;
    tokenPrice_ = _tokenPrice;
    priceUnit_ = _priceUnit;
  }

   
   
  function () external payable {
    require(msg.data.length == 0, "TOS03");
    investETH();
  }

   
  function investETH() public payable
  {
    Investor storage investor = investorInternal(msg.sender);
    uint256 amountETH = investor.unspentETH.add(msg.value);

    investInternal(msg.sender, amountETH, false);
  }

   
  function token() public view returns (IERC20) {
    return token_;
  }

   
  function vaultETH() public view returns (address) {
    return vaultETH_;
  }

   
  function vaultERC20() public view returns (address) {
    return vaultERC20_;
  }

   
  function tokenPrice() public view returns (uint256) {
    return tokenPrice_;
  }

   
  function priceUnit() public view returns (uint256) {
    return priceUnit_;
  }

   
  function totalRaised() public view returns (uint256) {
    return totalRaised_;
  }

   
  function totalTokensSold() public view returns (uint256) {
    return totalTokensSold_;
  }

   
  function totalUnspentETH() public view returns (uint256) {
    return totalUnspentETH_;
  }

   
  function totalRefundedETH() public view returns (uint256) {
    return totalRefundedETH_;
  }

   
  function availableSupply() public view returns (uint256) {
    uint256 vaultSupply = token_.balanceOf(vaultERC20_);
    uint256 allowance = token_.allowance(vaultERC20_, address(this));
    return (vaultSupply < allowance) ? vaultSupply : allowance;
  }

   
  function investorUnspentETH(address _investor)
    public view returns (uint256)
  {
    return investorInternal(_investor).unspentETH;
  }

  function investorInvested(address _investor)
    public view returns (uint256)
  {
    return investorInternal(_investor).invested;
  }

  function investorTokens(address _investor) public view returns (uint256) {
    return investorInternal(_investor).tokens;
  }

   
  function tokenInvestment(address, uint256 _amount)
    public view returns (uint256)
  {
    uint256 availableSupplyValue = availableSupply();
    uint256 contribution = _amount.mul(priceUnit_).div(tokenPrice_);

    return (contribution < availableSupplyValue) ? contribution : availableSupplyValue;
  }

   
  function refundManyUnspentETH(address payable[] memory _receivers)
    public onlyOperator returns (bool)
  {
    for (uint256 i = 0; i < _receivers.length; i++) {
      refundUnspentETHInternal(_receivers[i]);
    }
    return true;
  }

   
  function refundUnspentETH() public returns (bool) {
    refundUnspentETHInternal(msg.sender);
    return true;
  }

   
  function withdrawAllETHFunds() public onlyOperator returns (bool) {
    uint256 balance = address(this).balance;
    withdrawETHInternal(balance);
    return true;
  }

   
  function fundETH() public payable onlyOperator {
    emit FundETH(msg.value);
  }

   
  function investorInternal(address _investor)
    internal view returns (Investor storage)
  {
    return investors[_investor];
  }

   
  function evalUnspentETHInternal(
    Investor storage _investor, uint256 _investedETH
  ) internal view returns (uint256)
  {
    return _investor.unspentETH.add(msg.value).sub(_investedETH);
  }

   
  function evalInvestmentInternal(uint256 _tokens)
    internal view returns (uint256, uint256)
  {
    uint256 invested = _tokens.mul(tokenPrice_).div(priceUnit_);
    return (invested, _tokens);
  }

   
  function distributeTokensInternal(address _investor, uint256 _tokens) internal {
    require(
      token_.transferFrom(vaultERC20_, _investor, _tokens),
      "TOS04");
  }

   
  function refundUnspentETHInternal(address payable _investor) internal {
    Investor storage investor = investorInternal(_investor);
    require(investor.unspentETH > 0, "TOS05");

    uint256 unspentETH = investor.unspentETH;
    totalRefundedETH_ = totalRefundedETH_.add(unspentETH);
    totalUnspentETH_ = totalUnspentETH_.sub(unspentETH);
    investor.unspentETH = 0;

     
     
    _investor.transfer(unspentETH);
    emit RefundETH(_investor, unspentETH);
  }

   
  function withdrawETHInternal(uint256 _amount) internal {
     
     
    vaultETH_.transfer(_amount);
    emit WithdrawETH(_amount);
  }

   
  function investInternal(address _investor, uint256 _amount, bool _exactAmountOnly)
    internal whenNotPaused
  {
    require(_amount != 0, "TOS06");

    Investor storage investor = investorInternal(_investor);
    uint256 investment = tokenInvestment(_investor, _amount);
    require(investment != 0, "TOS07");

    (uint256 invested, uint256 tokens) = evalInvestmentInternal(investment);

    if (_exactAmountOnly) {
      require(invested == _amount, "TOS08");
    } else {
      uint256 unspentETH = evalUnspentETHInternal(investor, invested);
      totalUnspentETH_ = totalUnspentETH_.sub(investor.unspentETH).add(unspentETH);
      investor.unspentETH = unspentETH;
    }

    investor.invested = investor.invested.add(invested);
    investor.tokens = investor.tokens.add(tokens);
    totalRaised_ = totalRaised_.add(invested);
    totalTokensSold_ = totalTokensSold_.add(tokens);

    emit Investment(_investor, invested, tokens);

     
    distributeTokensInternal(_investor, tokens);

    uint256 balance = address(this).balance;
    uint256 withdrawableETH = balance.sub(totalUnspentETH_);
    if (withdrawableETH != 0) {
      withdrawETHInternal(withdrawableETH);
    }
  }
}

 

pragma solidity >=0.5.0 <0.6.0;



 
contract SchedulableTokensale is BaseTokensale {

  uint256 internal startAt = ~uint256(0);
  uint256 internal endAt = ~uint256(0);
  bool internal closed;

  event Schedule(uint256 startAt, uint256 endAt);
  event CloseEarly();

   
  modifier beforeSaleIsOpened {
    require(currentTime() < startAt && !closed, "STS01");
    _;
  }

   
  modifier saleIsOpened {
    require(
      currentTime() >= startAt
        && currentTime() <= endAt
        && !closed, "STS02"
    );
    _;
  }

   
  modifier beforeSaleIsClosed {
    require(currentTime() <= endAt && !closed, "STS03");
    _;
  }

   
  modifier afterSaleIsClosed {
    require(isClosed(), "STS04");
    _;
  }

   
  constructor(
    IERC20 _token,
    address _vaultERC20,
    address payable _vaultETH,
    uint256 _tokenPrice,
    uint256 _priceUnit
  ) public
    BaseTokensale(_token, _vaultERC20, _vaultETH, _tokenPrice, _priceUnit)
  {}  

   
  function schedule() public view returns (uint256, uint256) {
    return (startAt, endAt);
  }

   
  function isClosed() public view returns (bool) {
    return currentTime() > endAt || closed;
  }

   
  function updateSchedule(uint256 _startAt, uint256 _endAt)
    public onlyOperator beforeSaleIsOpened
  {
    require(_startAt < _endAt, "STS05");
    startAt = _startAt;
    endAt = _endAt;
    emit Schedule(_startAt, _endAt);
  }

   
  function closeEarly()
    public onlyOperator beforeSaleIsClosed
  {
    closed = true; 
    emit CloseEarly();
  }

   
  function investInternal(address _investor, uint256 _amount, bool _exactAmountOnly) internal
    saleIsOpened
  {
    super.investInternal(_investor, _amount, _exactAmountOnly);
  }

   
   
  function currentTime() internal view returns (uint256) {
     
    return now;
  }
}

 

pragma solidity >=0.5.0 <0.6.0;



 
contract BonusTokensale is SchedulableTokensale {

  enum BonusMode { NONE, EARLY, FIRST }
  uint256 constant MAX_BONUSES = 10;

  BonusMode internal bonusMode_ = BonusMode.NONE;
  uint256[] internal bonusUntils_;
  uint256[] internal bonuses_;

  event BonusesDefined(uint256[] bonuses, BonusMode bonusMode, uint256[] bonusUntils);

   
  constructor(
    IERC20 _token,
    address _vaultERC20,
    address payable _vaultETH,
    uint256 _tokenPrice,
    uint256 _priceUnit
  ) public
    SchedulableTokensale(_token,
      _vaultERC20, _vaultETH, _tokenPrice, _priceUnit)
  {}  
  
    
  function bonuses() public view returns (BonusMode, uint256[] memory, uint256[] memory) {
    return (bonusMode_, bonuses_, bonusUntils_);
  }

   
  function earlyBonus(uint256 _currentTime)
    public view returns (uint256 bonus, uint256 remainingAtBonus)
  {
    if (bonusMode_ != BonusMode.EARLY
      || _currentTime < startAt || _currentTime > endAt) {
      return (uint256(0), uint256(-1));
    }

    for(uint256 i=0; i < bonusUntils_.length; i++) {
      if (_currentTime <= bonusUntils_[i]) {
        return (bonuses_[i], uint256(-1));
      }
    }
    return (uint256(0), uint256(-1));
  }

   
  function firstBonus(uint256 _tokensSold)
    public view returns (uint256 bonus, uint256 remainingAtBonus)
  {
    if (bonusMode_ != BonusMode.FIRST) {
      return (uint256(0), uint256(-1));
    }

    for(uint256 i=0; i < bonusUntils_.length; i++) {
      if (_tokensSold < bonusUntils_[i]) {
        return (bonuses_[i], bonusUntils_[i]-_tokensSold);
      }
    }

    return (uint256(0), uint256(-1));
  }

   
  function defineBonuses(
    BonusMode _bonusMode,
    uint256[] memory _bonuses,
    uint256[] memory _bonusUntils)
    public onlyOperator beforeSaleIsOpened returns (bool)
  {
    require(_bonuses.length == _bonusUntils.length, "BT01");

    if (_bonusMode != BonusMode.NONE) {
      require(_bonusUntils.length > 0, "BT02");
      require(_bonusUntils.length < MAX_BONUSES, "BT03");

      uint256 bonusUntil =
        (_bonusMode == BonusMode.EARLY) ? startAt : 0;

      for(uint256 i=0; i < _bonusUntils.length; i++) {
        require(_bonusUntils[i] > bonusUntil, "BT04");
        bonusUntil = _bonusUntils[i];
      }
    } else {
      require(_bonusUntils.length == 0, "BT05");
    }

    bonuses_ = _bonuses;
    bonusMode_ = _bonusMode;
    bonusUntils_ = _bonusUntils;

    emit BonusesDefined(_bonuses, _bonusMode, _bonusUntils);
    return true;
  }

   
  function tokenBonus(uint256 _tokens)
    public view returns (uint256 tokenBonus_)
  {
    uint256 bonus;
    uint256 remainingAtBonus;
    uint256 unprocessed = _tokens;

    do {
      if(bonusMode_ == BonusMode.EARLY) {
        (bonus, remainingAtBonus) = earlyBonus(currentTime());
      }

      if(bonusMode_ == BonusMode.FIRST) {
        (bonus, remainingAtBonus) =
          firstBonus(totalTokensSold_+_tokens-unprocessed);
      }

      uint256 tokensAtCurrentBonus =
        (unprocessed < remainingAtBonus) ? unprocessed : remainingAtBonus;
      tokenBonus_ += bonus.mul(tokensAtCurrentBonus).div(100);
      unprocessed -= tokensAtCurrentBonus;
    } while(bonus > 0 && unprocessed > 0 && remainingAtBonus > 0);
  }

   
  function evalInvestmentInternal(uint256 _tokens)
    internal view returns (uint256, uint256)
  {
    (uint256 invested, uint256 tokens) = super.evalInvestmentInternal(_tokens);
    uint256 bonus = tokenBonus(tokens);
    return (invested, tokens.add(bonus));
  }
}

 

pragma solidity >=0.5.0 <0.6.0;


 
contract IRatesProvider {

  function defineRatesExternal(uint256[] calldata _rates) external returns (bool);

  function name() public view returns (string memory);

  function rate(bytes32 _currency) public view returns (uint256);

  function currencies() public view
    returns (bytes32[] memory, uint256[] memory, uint256);
  function rates() public view returns (uint256, uint256[] memory);

  function convert(uint256 _amount, bytes32 _fromCurrency, bytes32 _toCurrency)
    public view returns (uint256);

  function defineCurrencies(
    bytes32[] memory _currencies,
    uint256[] memory _decimals,
    uint256 _rateOffset) public returns (bool);
  function defineRates(uint256[] memory _rates) public returns (bool);

  event RateOffset(uint256 rateOffset);
  event Currencies(bytes32[] currencies, uint256[] decimals);
  event Rate(bytes32 indexed currency, uint256 rate);
}

 

pragma solidity >=0.5.0 <0.6.0;




 
contract ChangeTokensale is BaseTokensale {

  bytes32 internal baseCurrency_;
  IRatesProvider internal ratesProvider_;

  uint256 internal totalReceivedETH_;

   
  function investETH() public payable
  {
    require(msg.value > 0, "CTS01");
    totalReceivedETH_ = totalReceivedETH_.add(msg.value);

    Investor storage investor = investorInternal(msg.sender);
    uint256 amountETH = investor.unspentETH.add(msg.value);
    uint256 amountCurrency =
      ratesProvider_.convert(amountETH, "ETH", baseCurrency_);
    require(amountCurrency > 0, "CTS02");

    investInternal(msg.sender, amountCurrency, false);
  }

   
  function baseCurrency() public view returns (bytes32) {
    return baseCurrency_;
  }

   
  function ratesProvider() public view returns (IRatesProvider) {
    return ratesProvider_;
  }

   
  function totalRaisedETH() public view returns (uint256) {
    return totalReceivedETH_.sub(totalUnspentETH_).sub(totalRefundedETH_);
  }

   
  function totalReceivedETH() public view returns (uint256) {
    return totalReceivedETH_;
  }

   
  function addOffchainInvestment(address _investor, uint256 _amount)
    public onlyOperator returns (bool)
  {
    investInternal(_investor, _amount, true);

    return true;
  }

   
  function evalUnspentETHInternal(
    Investor storage _investor, uint256 _invested
  ) internal view returns (uint256)
  {
    uint256 investedETH =
      ratesProvider_.convert(_invested, baseCurrency_, "ETH");
    return super.evalUnspentETHInternal(_investor, investedETH);
  }
}

 

pragma solidity >=0.5.0 <0.6.0;


 
contract IUserRegistry {

  event UserRegistered(uint256 indexed userId, address address_, uint256 validUntilTime);
  event AddressAttached(uint256 indexed userId, address address_);
  event AddressDetached(uint256 indexed userId, address address_);
  event UserSuspended(uint256 indexed userId);
  event UserRestored(uint256 indexed userId);
  event UserValidity(uint256 indexed userId, uint256 validUntilTime);
  event UserExtendedKey(uint256 indexed userId, uint256 key, uint256 value);
  event UserExtendedKeys(uint256 indexed userId, uint256[] values);

  event ExtendedKeysDefinition(uint256[] keys);

  function registerManyUsersExternal(address[] calldata _addresses, uint256 _validUntilTime)
    external returns (bool);
  function registerManyUsersFullExternal(
    address[] calldata _addresses,
    uint256 _validUntilTime,
    uint256[] calldata _values) external returns (bool);
  function attachManyAddressesExternal(uint256[] calldata _userIds, address[] calldata _addresses)
    external returns (bool);
  function detachManyAddressesExternal(address[] calldata _addresses)
    external returns (bool);
  function suspendManyUsersExternal(uint256[] calldata _userIds) external returns (bool);
  function restoreManyUsersExternal(uint256[] calldata _userIds) external returns (bool);
  function updateManyUsersExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended) external returns (bool);
  function updateManyUsersExtendedExternal(
    uint256[] calldata _userIds,
    uint256 _key, uint256 _value) external returns (bool);
  function updateManyUsersAllExtendedExternal(
    uint256[] calldata _userIds,
    uint256[] calldata _values) external returns (bool);
  function updateManyUsersFullExternal(
    uint256[] calldata _userIds,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] calldata _values) external returns (bool);

  function name() public view returns (string memory);
  function currency() public view returns (bytes32);

  function userCount() public view returns (uint256);
  function userId(address _address) public view returns (uint256);
  function validUserId(address _address) public view returns (uint256);
  function validUser(address _address, uint256[] memory _keys)
    public view returns (uint256, uint256[] memory);
  function validity(uint256 _userId) public view returns (uint256, bool);

  function extendedKeys() public view returns (uint256[] memory);
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256);
  function manyExtended(uint256 _userId, uint256[] memory _key)
    public view returns (uint256[] memory);

  function isAddressValid(address _address) public view returns (bool);
  function isValid(uint256 _userId) public view returns (bool);

  function defineExtendedKeys(uint256[] memory _extendedKeys) public returns (bool);

  function registerUser(address _address, uint256 _validUntilTime)
    public returns (bool);
  function registerUserFull(
    address _address,
    uint256 _validUntilTime,
    uint256[] memory _values) public returns (bool);

  function attachAddress(uint256 _userId, address _address) public returns (bool);
  function detachAddress(address _address) public returns (bool);
  function detachSelf() public returns (bool);
  function detachSelfAddress(address _address) public returns (bool);
  function suspendUser(uint256 _userId) public returns (bool);
  function restoreUser(uint256 _userId) public returns (bool);
  function updateUser(uint256 _userId, uint256 _validUntilTime, bool _suspended)
    public returns (bool);
  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public returns (bool);
  function updateUserAllExtended(uint256 _userId, uint256[] memory _values)
    public returns (bool);
  function updateUserFull(
    uint256 _userId,
    uint256 _validUntilTime,
    bool _suspended,
    uint256[] memory _values) public returns (bool);
}

 

pragma solidity >=0.5.0 <0.6.0;




 
contract UserTokensale is ChangeTokensale {

  uint256[] public extendedKeys = [ 0, 1 ];  

   
   
  uint256[] internal contributionLimits_ = new uint256[](0);

  mapping(uint256 => Investor) internal investorIds;
  IUserRegistry internal userRegistry_;

   
  function defineContributionLimits(uint256[] memory _contributionLimits)
    public onlyOperator returns (bool)
  {
    contributionLimits_ = _contributionLimits;
    emit ContributionLimits(_contributionLimits);
    return true;
  }

   
  function contributionLimits() public view returns (uint256[] memory) {
    return contributionLimits_;
  }

   
  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry_;
  }

  function registredInvestorUnspentETH(uint256 _investorId)
    public view returns (uint256)
  {
    return investorIds[_investorId].unspentETH;
  }

  function registredInvestorInvested(uint256 _investorId)
    public view returns (uint256)
  {
    return investorIds[_investorId].invested;
  }

  function registredInvestorTokens(uint256 _investorId)
    public view returns (uint256)
  {
    return investorIds[_investorId].tokens;
  }

  function investorCount()
    public view returns (uint256)
  {
    return userRegistry_.userCount();
  }

   
  function contributionLimit(uint256 _investorId)
    public view returns (uint256)
  {
    uint256 amlLimit = 0;

    uint256[] memory extended = userRegistry_.manyExtended(_investorId, extendedKeys);
    uint256 kycLevel = extended[0];
    uint256 baseAmlLimit = extended[1];

    if (baseAmlLimit > 0) {
      amlLimit = ratesProvider_.convert(
        baseAmlLimit, userRegistry_.currency(), baseCurrency_);
    }

    if (amlLimit == 0 && kycLevel < contributionLimits_.length) {
      amlLimit = contributionLimits_[kycLevel];
    }

    return amlLimit.sub(investorIds[_investorId].invested);
  }

   
  function tokenInvestment(address _investor, uint256 _amount)
    public view returns (uint256)
  {
    uint256 investorId = userRegistry_.validUserId(_investor);
    uint256 amlLimit = contributionLimit(investorId);
    return super.tokenInvestment(_investor, (_amount < amlLimit) ? _amount : amlLimit);
  }

   
  function investorInternal(address _investor)
    internal view returns (Investor storage)
  {
    return investorIds[userRegistry_.userId(_investor)];
  }

  event ContributionLimits(uint256[] contributionLimits);
}

 

pragma solidity >=0.5.0 <0.6.0;




 
contract Tokensale is UserTokensale, BonusTokensale {

   
  constructor(
    IERC20 _token,
    address _vaultERC20,
    address payable _vaultETH,
    uint256 _tokenPrice,
    uint256 _priceUnit,
    bytes32 _baseCurrency,
    IUserRegistry _userRegistry,
    IRatesProvider _ratesProvider,
    uint256 _start,
    uint256 _end
  ) public
    BonusTokensale(_token,
      _vaultERC20, _vaultETH, _tokenPrice, _priceUnit)
  {
    baseCurrency_ = _baseCurrency;
    userRegistry_ = _userRegistry;
    ratesProvider_ = _ratesProvider;

    updateSchedule(_start, _end);
  }
}