 

 


pragma solidity ^0.4.24;

 

 
contract IUserRegistry {

  function registerManyUsers(address[] _addresses, uint256 _validUntilTime)
    public;

  function attachManyAddresses(uint256[] _userIds, address[] _addresses)
    public;

  function detachManyAddresses(address[] _addresses)
    public;

  function userCount() public view returns (uint256);
  function userId(address _address) public view returns (uint256);
  function addressConfirmed(address _address) public view returns (bool);
  function validUntilTime(uint256 _userId) public view returns (uint256);
  function suspended(uint256 _userId) public view returns (bool);
  function extended(uint256 _userId, uint256 _key)
    public view returns (uint256);

  function isAddressValid(address _address) public view returns (bool);
  function isValid(uint256 _userId) public view returns (bool);

  function registerUser(address _address, uint256 _validUntilTime) public;
  function attachAddress(uint256 _userId, address _address) public;
  function confirmSelf() public;
  function detachAddress(address _address) public;
  function detachSelf() public;
  function detachSelfAddress(address _address) public;
  function suspendUser(uint256 _userId) public;
  function unsuspendUser(uint256 _userId) public;
  function suspendManyUsers(uint256[] _userIds) public;
  function unsuspendManyUsers(uint256[] _userIds) public;
  function updateUser(uint256 _userId, uint256 _validUntil, bool _suspended)
    public;

  function updateManyUsers(
    uint256[] _userIds,
    uint256 _validUntil,
    bool _suspended) public;

  function updateUserExtended(uint256 _userId, uint256 _key, uint256 _value)
    public;

  function updateManyUsersExtended(
    uint256[] _userIds,
    uint256 _key,
    uint256 _value) public;
}

 

 
contract IRatesProvider {
  function rateWEIPerCHFCent() public view returns (uint256);
  function convertWEIToCHFCent(uint256 _amountWEI)
    public view returns (uint256);

  function convertCHFCentToWEI(uint256 _amountCHFCent)
    public view returns (uint256);
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ITokensale {

  function () external payable;

  uint256 constant MINIMAL_AUTO_WITHDRAW = 0.5 ether;
  uint256 constant MINIMAL_BALANCE = 0.5 ether;
  uint256 constant MINIMAL_INVESTMENT = 50;  
  uint256 constant BASE_PRICE_CHF_CENT = 500;
  uint256 constant KYC_LEVEL_KEY = 1;

  function minimalAutoWithdraw() public view returns (uint256);
  function minimalBalance() public view returns (uint256);
  function basePriceCHFCent() public view returns (uint256);

   
  function token() public view returns (ERC20);
  function vaultETH() public view returns (address);
  function vaultERC20() public view returns (address);
  function userRegistry() public view returns (IUserRegistry);
  function ratesProvider() public view returns (IRatesProvider);
  function sharePurchaseAgreementHash() public view returns (bytes32);

   
  function startAt() public view returns (uint256);
  function endAt() public view returns (uint256);
  function raisedETH() public view returns (uint256);
  function raisedCHF() public view returns (uint256);
  function totalRaisedCHF() public view returns (uint256);
  function totalUnspentETH() public view returns (uint256);
  function totalRefundedETH() public view returns (uint256);
  function availableSupply() public view returns (uint256);

   
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256);

  function investorInvestedCHF(uint256 _investorId)
    public view returns (uint256);

  function investorAcceptedSPA(uint256 _investorId)
    public view returns (bool);

  function investorAllocations(uint256 _investorId)
    public view returns (uint256);

  function investorTokens(uint256 _investorId) public view returns (uint256);
  function investorCount() public view returns (uint256);

  function investorLimit(uint256 _investorId) public view returns (uint256);

   
  function defineSPA(bytes32 _sharePurchaseAgreementHash)
    public returns (bool);

  function acceptSPA(bytes32 _sharePurchaseAgreementHash)
    public payable returns (bool);

   
  function investETH() public payable;
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public;

   
  function updateSchedule(uint256 _startAt, uint256 _endAt) public;

   
  function allocateTokens(address _investor, uint256 _amount)
    public returns (bool);

  function allocateManyTokens(address[] _investors, uint256[] _amounts)
    public returns (bool);

   
  function fundETH() public payable;
  function refundManyUnspentETH(address[] _receivers) public;
  function refundUnspentETH(address _receiver) public;
  function withdrawETHFunds() public;

  event SalePurchaseAgreementHash(bytes32 sharePurchaseAgreement);
  event Allocation(
    uint256 investorId,
    uint256 tokens
  );
  event Investment(
    uint256 investorId,
    uint256 spentCHF
  );
  event ChangeETHCHF(
    address investor,
    uint256 amount,
    uint256 converted,
    uint256 rate
  );
  event FundETH(uint256 amount);
  event WithdrawETH(address receiver, uint256 amount);
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

 

 
contract Authority is Ownable {

  address authority;

   
  modifier onlyAuthority {
    require(msg.sender == authority, "AU01");
    _;
  }

   
  function authorityAddress() public view returns (address) {
    return authority;
  }

   
  function defineAuthority(string _name, address _address) public onlyOwner {
    emit AuthorityDefined(_name, _address);
    authority = _address;
  }

  event AuthorityDefined(
    string name,
    address _address
  );
}

 

 
contract Tokensale is ITokensale, Authority, Pausable {
  using SafeMath for uint256;

  uint32[5] contributionLimits = [
    5000,
    500000,
    1500000,
    10000000,
    25000000
  ];

   
  ERC20 public token;
  address public vaultETH;
  address public vaultERC20;
  IUserRegistry public userRegistry;
  IRatesProvider public ratesProvider;

  uint256 public minimalBalance = MINIMAL_BALANCE;
  bytes32 public sharePurchaseAgreementHash;

  uint256 public startAt = 4102441200;
  uint256 public endAt = 4102441200;
  uint256 public raisedETH;
  uint256 public raisedCHF;
  uint256 public totalRaisedCHF;
  uint256 public totalUnspentETH;
  uint256 public totalRefundedETH;
  uint256 public allocatedTokens;

  struct Investor {
    uint256 unspentETH;
    uint256 investedCHF;
    bool acceptedSPA;
    uint256 allocations;
    uint256 tokens;
  }
  mapping(uint256 => Investor) investors;
  mapping(uint256 => uint256) investorLimits;
  uint256 public investorCount;

   
  modifier beforeSaleIsOpened {
    require(currentTime() < startAt, "TOS01");
    _;
  }

   
  modifier saleIsOpened {
    require(currentTime() >= startAt && currentTime() <= endAt, "TOS02");
    _;
  }

   
  modifier beforeSaleIsClosed {
    require(currentTime() <= endAt, "TOS03");
    _;
  }

   
  constructor(
    ERC20 _token,
    IUserRegistry _userRegistry,
    IRatesProvider _ratesProvider,
    address _vaultERC20,
    address _vaultETH
  ) public
  {
    token = _token;
    userRegistry = _userRegistry;
    ratesProvider = _ratesProvider;
    vaultERC20 = _vaultERC20;
    vaultETH = _vaultETH;
  }

   
  function () external payable {
    require(msg.data.length == 0, "TOS05");
    investETH();
  }

   
  function token() public view returns (ERC20) {
    return token;
  }

   
  function vaultETH() public view returns (address) {
    return vaultETH;
  }

   
  function vaultERC20() public view returns (address) {
    return vaultERC20;
  }

  function userRegistry() public view returns (IUserRegistry) {
    return userRegistry;
  }

  function ratesProvider() public view returns (IRatesProvider) {
    return ratesProvider;
  }

  function sharePurchaseAgreementHash() public view returns (bytes32) {
    return sharePurchaseAgreementHash;
  }

   
  function startAt() public view returns (uint256) {
    return startAt;
  }

  function endAt() public view returns (uint256) {
    return endAt;
  }

  function raisedETH() public view returns (uint256) {
    return raisedETH;
  }

  function raisedCHF() public view returns (uint256) {
    return raisedCHF;
  }

  function totalRaisedCHF() public view returns (uint256) {
    return totalRaisedCHF;
  }

  function totalUnspentETH() public view returns (uint256) {
    return totalUnspentETH;
  }

  function totalRefundedETH() public view returns (uint256) {
    return totalRefundedETH;
  }

  function availableSupply() public view returns (uint256) {
    uint256 vaultSupply = token.balanceOf(vaultERC20);
    uint256 allowance = token.allowance(vaultERC20, address(this));
    return (vaultSupply < allowance) ? vaultSupply : allowance;
  }
 
   
  function investorUnspentETH(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].unspentETH;
  }

  function investorInvestedCHF(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].investedCHF;
  }

  function investorAcceptedSPA(uint256 _investorId)
    public view returns (bool)
  {
    return investors[_investorId].acceptedSPA;
  }

  function investorAllocations(uint256 _investorId)
    public view returns (uint256)
  {
    return investors[_investorId].allocations;
  }

  function investorTokens(uint256 _investorId) public view returns (uint256) {
    return investors[_investorId].tokens;
  }

  function investorCount() public view returns (uint256) {
    return investorCount;
  }

  function investorLimit(uint256 _investorId) public view returns (uint256) {
    return investorLimits[_investorId];
  }

   
  function minimalAutoWithdraw() public view returns (uint256) {
    return MINIMAL_AUTO_WITHDRAW;
  }

   
  function minimalBalance() public view returns (uint256) {
    return minimalBalance;
  }

   
  function basePriceCHFCent() public view returns (uint256) {
    return BASE_PRICE_CHF_CENT;
  }

   
  function contributionLimit(uint256 _investorId)
    public view returns (uint256)
  {
    uint256 kycLevel = userRegistry.extended(_investorId, KYC_LEVEL_KEY);
    uint256 limit = 0;
    if (kycLevel < 5) {
      limit = contributionLimits[kycLevel];
    } else {
      limit = (investorLimits[_investorId] > 0
        ) ? investorLimits[_investorId] : contributionLimits[4];
    }
    return limit.sub(investors[_investorId].investedCHF);
  }

   
  function updateMinimalBalance(uint256 _minimalBalance)
    public returns (uint256)
  {
    minimalBalance = _minimalBalance;
  }

   
  function updateInvestorLimits(uint256[] _investorIds, uint256 _limit)
    public returns (uint256)
  {
    for (uint256 i = 0; i < _investorIds.length; i++) {
      investorLimits[_investorIds[i]] = _limit;
    }
  }

   
   
  function defineSPA(bytes32 _sharePurchaseAgreementHash)
    public onlyOwner returns (bool)
  {
    sharePurchaseAgreementHash = _sharePurchaseAgreementHash;
    emit SalePurchaseAgreementHash(_sharePurchaseAgreementHash);
  }

   
  function acceptSPA(bytes32 _sharePurchaseAgreementHash)
    public beforeSaleIsClosed payable returns (bool)
  {
    require(
      _sharePurchaseAgreementHash == sharePurchaseAgreementHash, "TOS06");
    uint256 investorId = userRegistry.userId(msg.sender);
    require(investorId > 0, "TOS07");
    investors[investorId].acceptedSPA = true;
    investorCount++;

    if (msg.value > 0) {
      investETH();
    }
  }

   
  function investETH() public
    saleIsOpened whenNotPaused payable
  {
     
     
     
    investInternal(msg.sender, msg.value, 0);
    withdrawETHFundsInternal();
  }

   
  function addOffChainInvestment(address _investor, uint256 _amountCHF)
    public onlyAuthority
  {
    investInternal(_investor, 0, _amountCHF);
  }

    
   
  function updateSchedule(uint256 _startAt, uint256 _endAt)
    public onlyAuthority beforeSaleIsOpened
  {
    require(_startAt < _endAt, "TOS09");
    startAt = _startAt;
    endAt = _endAt;
  }

   
   
  function allocateTokens(address _investor, uint256 _amount)
    public onlyAuthority beforeSaleIsClosed returns (bool)
  {
    uint256 investorId = userRegistry.userId(_investor);
    require(investorId > 0, "TOS10");
    Investor storage investor = investors[investorId];
    
    allocatedTokens = allocatedTokens.sub(investor.allocations).add(_amount);
    require(allocatedTokens <= availableSupply(), "TOS11");

    investor.allocations = _amount;
    emit Allocation(investorId, _amount);
  }

   
  function allocateManyTokens(address[] _investors, uint256[] _amounts)
    public onlyAuthority beforeSaleIsClosed returns (bool)
  {
    require(_investors.length == _amounts.length, "TOS12");
    for (uint256 i = 0; i < _investors.length; i++) {
      allocateTokens(_investors[i], _amounts[i]);
    }
  }

   
   
  function fundETH() public payable onlyAuthority {
    emit FundETH(msg.value);
  }

   
  function refundManyUnspentETH(address[] _receivers) public onlyAuthority {
    for (uint256 i = 0; i < _receivers.length; i++) {
      refundUnspentETH(_receivers[i]);
    }
  }

   
  function refundUnspentETH(address _receiver) public onlyAuthority {
    uint256 investorId = userRegistry.userId(_receiver);
    require(investorId != 0, "TOS13");
    Investor storage investor = investors[investorId];

    if (investor.unspentETH > 0) {
       
      require(_receiver.send(investor.unspentETH), "TOS14");
      totalRefundedETH = totalRefundedETH.add(investor.unspentETH);
      emit WithdrawETH(_receiver, investor.unspentETH);
      totalUnspentETH = totalUnspentETH.sub(investor.unspentETH);
      investor.unspentETH = 0;
    }
  }

   
  function withdrawETHFunds() public onlyAuthority {
    withdrawETHFundsInternal();
  }

   
  function withdrawAllETHFunds() public onlyAuthority {
    uint256 balance = address(this).balance;
     
    require(vaultETH.send(balance), "TOS15");
    emit WithdrawETH(vaultETH, balance);
  }

   
  function allowedTokenInvestment(
    uint256 _investorId, uint256 _contributionCHF)
    public view returns (uint256)
  {
    uint256 tokens = 0;
    uint256 allowedContributionCHF = contributionLimit(_investorId);
    if (_contributionCHF < allowedContributionCHF) {
      allowedContributionCHF = _contributionCHF;
    }
    tokens = allowedContributionCHF.div(BASE_PRICE_CHF_CENT);
    uint256 availableTokens = availableSupply().sub(
      allocatedTokens).add(investors[_investorId].allocations);
    if (tokens > availableTokens) {
      tokens = availableTokens;
    }
    if (tokens < MINIMAL_INVESTMENT) {
      tokens = 0;
    }
    return tokens;
  }

   
  function withdrawETHFundsInternal() internal {
    uint256 balance = address(this).balance;

    if (balance > totalUnspentETH && balance > minimalBalance) {
      uint256 amount = balance.sub(minimalBalance);
       
      require(vaultETH.send(amount), "TOS15");
      emit WithdrawETH(vaultETH, amount);
    }
  }

   
  function investInternal(
    address _investor, uint256 _amountETH, uint256 _amountCHF)
    private
  {
     
     
     
    bool isInvesting = (
        _amountETH != 0 && _amountCHF == 0
      ) || (
      _amountETH == 0 && _amountCHF != 0
      );
    require(isInvesting, "TOS16");
    require(ratesProvider.rateWEIPerCHFCent() != 0, "TOS17");
    uint256 investorId = userRegistry.userId(_investor);
    require(userRegistry.isValid(investorId), "TOS18");

    Investor storage investor = investors[investorId];

    uint256 contributionCHF = ratesProvider.convertWEIToCHFCent(
      investor.unspentETH);

    if (_amountETH > 0) {
      contributionCHF = contributionCHF.add(
        ratesProvider.convertWEIToCHFCent(_amountETH));
    }
    if (_amountCHF > 0) {
      contributionCHF = contributionCHF.add(_amountCHF);
    }

    uint256 tokens = allowedTokenInvestment(investorId, contributionCHF);
    require(tokens != 0, "TOS19");

     
    uint256 investedCHF = tokens.mul(BASE_PRICE_CHF_CENT);
    uint256 unspentContributionCHF = contributionCHF.sub(investedCHF);

    uint256 unspentETH = 0;
    if (unspentContributionCHF != 0) {
      if (_amountCHF > 0) {
         
         
        require(unspentContributionCHF < BASE_PRICE_CHF_CENT, "TOS21");
      }
      unspentETH = ratesProvider.convertCHFCentToWEI(
        unspentContributionCHF);
    }

     
    uint256 spentETH = 0;
    if (investor.unspentETH == unspentETH) {
      spentETH = _amountETH;
    } else {
      uint256 unspentETHDiff = (unspentETH > investor.unspentETH)
        ? unspentETH.sub(investor.unspentETH)
        : investor.unspentETH.sub(unspentETH);

      if (_amountCHF > 0) {
        if (unspentETH < investor.unspentETH) {
          spentETH = unspentETHDiff;
        }
         
         
         
      }
      if (_amountETH > 0) {
        spentETH = (unspentETH > investor.unspentETH)
          ? _amountETH.sub(unspentETHDiff)
          : _amountETH.add(unspentETHDiff);
      }
    }

    totalUnspentETH = totalUnspentETH.sub(
      investor.unspentETH).add(unspentETH);
    investor.unspentETH = unspentETH;
    investor.investedCHF = investor.investedCHF.add(investedCHF);
    investor.tokens = investor.tokens.add(tokens);
    raisedCHF = raisedCHF.add(_amountCHF);
    raisedETH = raisedETH.add(spentETH);
    totalRaisedCHF = totalRaisedCHF.add(investedCHF);

    allocatedTokens = allocatedTokens.sub(investor.allocations);
    investor.allocations = (investor.allocations > tokens)
      ? investor.allocations.sub(tokens) : 0;
    allocatedTokens = allocatedTokens.add(investor.allocations);
    require(
      token.transferFrom(vaultERC20, _investor, tokens),
      "TOS22");

    if (spentETH > 0) {
      emit ChangeETHCHF(
        _investor,
        spentETH,
        ratesProvider.convertWEIToCHFCent(spentETH),
        ratesProvider.rateWEIPerCHFCent());
    }
    emit Investment(investorId, investedCHF);
  }

   
   
  function currentTime() private view returns (uint256) {
     
    return now;
  }
}