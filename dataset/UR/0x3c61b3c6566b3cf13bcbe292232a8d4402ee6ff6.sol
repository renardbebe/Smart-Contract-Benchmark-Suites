 

pragma solidity 0.5.13;


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        
        require(b > 0, errorMessage);
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Context {
    
    
    constructor () internal { }
    

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ReentrancyGuard {
    
    uint256 private _guardCounter;

    constructor () internal {
        
        
        _guardCounter = 1;
    }

    
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

interface IMiniMeToken {
    function balanceOf(address _owner) external view returns (uint256 balance);
    function totalSupply() external view returns(uint);
    function generateTokens(address _owner, uint _amount) external returns (bool);
    function destroyTokens(address _owner, uint _amount) external returns (bool);
    function totalSupplyAt(uint _blockNumber) external view returns(uint);
    function balanceOfAt(address _holder, uint _blockNumber) external view returns (uint);
    function transferOwnership(address newOwner) external;
}

contract TokenController {
  
  
  
  function proxyPayment(address _owner) public payable returns(bool);

  
  
  
  
  
  
  function onTransfer(address _from, address _to, uint _amount) public returns(bool);

  
  
  
  
  
  
  function onApprove(address _owner, address _spender, uint _amount) public
    returns(bool);
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    
    function name() public view returns (string memory) {
        return _name;
    }

    
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        
        
        
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

    
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

interface KyberNetwork {
  function getExpectedRate(ERC20Detailed src, ERC20Detailed dest, uint srcQty) external view
      returns (uint expectedRate, uint slippageRate);

  function tradeWithHint(
    ERC20Detailed src, uint srcAmount, ERC20Detailed dest, address payable destAddress, uint maxDestAmount,
    uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);
}

contract Utils {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Detailed;

  
  modifier isValidToken(address _token) {
    require(_token != address(0));
    if (_token != address(ETH_TOKEN_ADDRESS)) {
      require(isContract(_token));
    }
    _;
  }

  address public DAI_ADDR;
  address payable public KYBER_ADDR;
  address payable public DEXAG_ADDR;

  bytes public constant PERM_HINT = "PERM";

  ERC20Detailed internal constant ETH_TOKEN_ADDRESS = ERC20Detailed(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  ERC20Detailed internal dai;
  KyberNetwork internal kyber;

  uint constant internal PRECISION = (10**18);
  uint constant internal MAX_QTY   = (10**28); 
  uint constant internal ETH_DECIMALS = 18;
  uint constant internal MAX_DECIMALS = 18;

  constructor(
    address _daiAddr,
    address payable _kyberAddr,
    address payable _dexagAddr
  ) public {
    DAI_ADDR = _daiAddr;
    KYBER_ADDR = _kyberAddr;
    DEXAG_ADDR = _dexagAddr;

    dai = ERC20Detailed(_daiAddr);
    kyber = KyberNetwork(_kyberAddr);
  }

  
  function getDecimals(ERC20Detailed _token) internal view returns(uint256) {
    if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
      return uint256(ETH_DECIMALS);
    }
    return uint256(_token.decimals());
  }

  
  function getBalance(ERC20Detailed _token, address _addr) internal view returns(uint256) {
    if (address(_token) == address(ETH_TOKEN_ADDRESS)) {
      return uint256(_addr.balance);
    }
    return uint256(_token.balanceOf(_addr));
  }

  
  function calcRateFromQty(uint srcAmount, uint destAmount, uint srcDecimals, uint dstDecimals)
        internal pure returns(uint)
  {
    require(srcAmount <= MAX_QTY);
    require(destAmount <= MAX_QTY);

    if (dstDecimals >= srcDecimals) {
      require((dstDecimals - srcDecimals) <= MAX_DECIMALS);
      return (destAmount * PRECISION / ((10 ** (dstDecimals - srcDecimals)) * srcAmount));
    } else {
      require((srcDecimals - dstDecimals) <= MAX_DECIMALS);
      return (destAmount * PRECISION * (10 ** (srcDecimals - dstDecimals)) / srcAmount);
    }
  }

  
  function __kyberTrade(ERC20Detailed _srcToken, uint256 _srcAmount, ERC20Detailed _destToken)
    internal
    returns(
      uint256 _destPriceInSrc,
      uint256 _srcPriceInDest,
      uint256 _actualDestAmount,
      uint256 _actualSrcAmount
    )
  {
    require(_srcToken != _destToken);

    uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
    uint256 msgValue;
    if (_srcToken != ETH_TOKEN_ADDRESS) {
      msgValue = 0;
      _srcToken.safeApprove(KYBER_ADDR, 0);
      _srcToken.safeApprove(KYBER_ADDR, _srcAmount);
    } else {
      msgValue = _srcAmount;
    }
    _actualDestAmount = kyber.tradeWithHint.value(msgValue)(
      _srcToken,
      _srcAmount,
      _destToken,
      toPayableAddr(address(this)),
      MAX_QTY,
      1,
      0x332D87209f7c8296389C307eAe170c2440830A47,
      PERM_HINT
    );
    _actualSrcAmount = beforeSrcBalance.sub(getBalance(_srcToken, address(this)));
    require(_actualDestAmount > 0 && _actualSrcAmount > 0);
    _destPriceInSrc = calcRateFromQty(_actualDestAmount, _actualSrcAmount, getDecimals(_destToken), getDecimals(_srcToken));
    _srcPriceInDest = calcRateFromQty(_actualSrcAmount, _actualDestAmount, getDecimals(_srcToken), getDecimals(_destToken));
  }

  
  function __dexagTrade(ERC20Detailed _srcToken, uint256 _srcAmount, ERC20Detailed _destToken, bytes memory _calldata)
    internal
    returns(
      uint256 _destPriceInSrc,
      uint256 _srcPriceInDest,
      uint256 _actualDestAmount,
      uint256 _actualSrcAmount
    )
  {
    require(_srcToken != _destToken);

    uint256 beforeSrcBalance = getBalance(_srcToken, address(this));
    uint256 beforeDestBalance = getBalance(_destToken, address(this));
    
    if (_srcToken != ETH_TOKEN_ADDRESS) {
      _actualSrcAmount = 0;
      _srcToken.safeApprove(DEXAG_ADDR, 0);
      _srcToken.safeApprove(DEXAG_ADDR, _srcAmount);
    } else {
      _actualSrcAmount = _srcAmount;
    }

    
    (bool success,) = DEXAG_ADDR.call.value(_actualSrcAmount)(_calldata);
    require(success);

    
    _actualDestAmount = beforeDestBalance.sub(getBalance(_destToken, address(this)));
    _actualSrcAmount = beforeSrcBalance.sub(getBalance(_srcToken, address(this)));
    require(_actualDestAmount > 0 && _actualSrcAmount > 0);
    _destPriceInSrc = calcRateFromQty(_actualDestAmount, _actualSrcAmount, getDecimals(_destToken), getDecimals(_srcToken));
    _srcPriceInDest = calcRateFromQty(_actualSrcAmount, _actualDestAmount, getDecimals(_srcToken), getDecimals(_destToken));

    
    (, uint256 kyberSrcPriceInDest) = kyber.getExpectedRate(_srcToken, _destToken, _srcAmount);
    require(kyberSrcPriceInDest > 0 && _srcPriceInDest >= kyberSrcPriceInDest);
  }

  
  function isContract(address _addr) internal view returns(bool) {
    uint size;
    if (_addr == address(0)) return false;
    assembly {
        size := extcodesize(_addr)
    }
    return size>0;
  }

  function toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }
}

interface BetokenProxyInterface {
  function betokenFundAddress() external view returns (address payable);
  function updateBetokenFundAddress() external;
}

interface ScdMcdMigration {
  
  
  
  function swapSaiToDai(
    uint wad
  ) external;
}

contract BetokenStorage is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  enum CyclePhase { Intermission, Manage }
  enum VoteDirection { Empty, For, Against }
  enum Subchunk { Propose, Vote }

  struct Investment {
    address tokenAddress;
    uint256 cycleNumber;
    uint256 stake;
    uint256 tokenAmount;
    uint256 buyPrice; 
    uint256 sellPrice; 
    uint256 buyTime;
    uint256 buyCostInDAI;
    bool isSold;
  }

  
  uint256 public constant COMMISSION_RATE = 20 * (10 ** 16); 
  uint256 public constant ASSET_FEE_RATE = 1 * (10 ** 15); 
  uint256 public constant NEXT_PHASE_REWARD = 1 * (10 ** 18); 
  uint256 public constant MAX_BUY_KRO_PROP = 1 * (10 ** 16); 
  uint256 public constant FALLBACK_MAX_DONATION = 100 * (10 ** 18); 
  uint256 public constant MIN_KRO_PRICE = 25 * (10 ** 17); 
  uint256 public constant COLLATERAL_RATIO_MODIFIER = 75 * (10 ** 16); 
  uint256 public constant MIN_RISK_TIME = 3 days; 
  uint256 public constant INACTIVE_THRESHOLD = 2; 
  uint256 public constant ROI_PUNISH_THRESHOLD = 1 * (10 ** 17); 
  uint256 public constant ROI_BURN_THRESHOLD = 25 * (10 ** 16); 
  uint256 public constant ROI_PUNISH_SLOPE = 6; 
  uint256 public constant ROI_PUNISH_NEG_BIAS = 5 * (10 ** 17); 
  
  uint256 public constant CHUNK_SIZE = 3 days;
  uint256 public constant PROPOSE_SUBCHUNK_SIZE = 1 days;
  uint256 public constant CYCLES_TILL_MATURITY = 3;
  uint256 public constant QUORUM = 10 * (10 ** 16); 
  uint256 public constant VOTE_SUCCESS_THRESHOLD = 75 * (10 ** 16); 

  

  
  bool public hasInitializedTokenListings;

  
  bool public isInitialized;

  
  address public controlTokenAddr;

  
  address public shareTokenAddr;

  
  address payable public proxyAddr;

  
  address public compoundFactoryAddr;

  
  address public betokenLogic;
  address public betokenLogic2;

  
  address payable public devFundingAccount;

  
  address payable public previousVersion;

  
  address public saiAddr;

  
  uint256 public cycleNumber;

  
  uint256 public totalFundsInDAI;

  
  uint256 public startTimeOfCyclePhase;

  
  uint256 public devFundingRate;

  
  uint256 public totalCommissionLeft;

  
  uint256[2] public phaseLengths;

  
  mapping(address => uint256) internal _lastCommissionRedemption;

  
  mapping(address => mapping(uint256 => bool)) internal _hasRedeemedCommissionForCycle;

  
  mapping(address => mapping(uint256 => uint256)) internal _riskTakenInCycle;

  
  mapping(address => uint256) internal _baseRiskStakeFallback;

  
  mapping(address => Investment[]) public userInvestments;

  
  mapping(address => address payable[]) public userCompoundOrders;

  
  mapping(uint256 => uint256) internal _totalCommissionOfCycle;

  
  mapping(uint256 => uint256) internal _managePhaseEndBlock;

  
  mapping(address => uint256) internal _lastActiveCycle;

  
  mapping(address => bool) public isKyberToken;

  
  mapping(address => bool) public isCompoundToken;

  
  mapping(address => bool) public isPositionToken;

  
  CyclePhase public cyclePhase;

  
  bool public hasFinalizedNextVersion; 
  bool public upgradeVotingActive; 
  address payable public nextVersion; 
  address[5] public proposers; 
  address payable[5] public candidates; 
  uint256[5] public forVotes; 
  uint256[5] public againstVotes; 
  uint256 public proposersVotingWeight; 
  mapping(uint256 => mapping(address => VoteDirection[5])) public managerVotes; 
  mapping(uint256 => uint256) public upgradeSignalStrength; 
  mapping(uint256 => mapping(address => bool)) public upgradeSignal; 

  
  IMiniMeToken internal cToken;
  IMiniMeToken internal sToken;
  BetokenProxyInterface internal proxy;
  ScdMcdMigration internal mcdaiMigration;

  

  event ChangedPhase(uint256 indexed _cycleNumber, uint256 indexed _newPhase, uint256 _timestamp, uint256 _totalFundsInDAI);

  event Deposit(uint256 indexed _cycleNumber, address indexed _sender, address _tokenAddress, uint256 _tokenAmount, uint256 _daiAmount, uint256 _timestamp);
  event Withdraw(uint256 indexed _cycleNumber, address indexed _sender, address _tokenAddress, uint256 _tokenAmount, uint256 _daiAmount, uint256 _timestamp);

  event CreatedInvestment(uint256 indexed _cycleNumber, address indexed _sender, uint256 _id, address _tokenAddress, uint256 _stakeInWeis, uint256 _buyPrice, uint256 _costDAIAmount, uint256 _tokenAmount);
  event SoldInvestment(uint256 indexed _cycleNumber, address indexed _sender, uint256 _id, address _tokenAddress, uint256 _receivedKairo, uint256 _sellPrice, uint256 _earnedDAIAmount);

  event CreatedCompoundOrder(uint256 indexed _cycleNumber, address indexed _sender, uint256 _id, address _order, bool _orderType, address _tokenAddress, uint256 _stakeInWeis, uint256 _costDAIAmount);
  event SoldCompoundOrder(uint256 indexed _cycleNumber, address indexed _sender, uint256 _id, address _order,  bool _orderType, address _tokenAddress, uint256 _receivedKairo, uint256 _earnedDAIAmount);
  event RepaidCompoundOrder(uint256 indexed _cycleNumber, address indexed _sender, uint256 _id, address _order, uint256 _repaidDAIAmount);

  event CommissionPaid(uint256 indexed _cycleNumber, address indexed _sender, uint256 _commission);
  event TotalCommissionPaid(uint256 indexed _cycleNumber, uint256 _totalCommissionInDAI);

  event Register(address indexed _manager, uint256 _donationInDAI, uint256 _kairoReceived);

  event SignaledUpgrade(uint256 indexed _cycleNumber, address indexed _sender, bool indexed _inSupport);
  event DeveloperInitiatedUpgrade(uint256 indexed _cycleNumber, address _candidate);
  event InitiatedUpgrade(uint256 indexed _cycleNumber);
  event ProposedCandidate(uint256 indexed _cycleNumber, uint256 indexed _voteID, address indexed _sender, address _candidate);
  event Voted(uint256 indexed _cycleNumber, uint256 indexed _voteID, address indexed _sender, bool _inSupport, uint256 _weight);
  event FinalizedNextVersion(uint256 indexed _cycleNumber, address _nextVersion);

  

  
  function currentChunk() public view returns (uint) {
    if (cyclePhase != CyclePhase.Manage) {
      return 0;
    }
    return (now - startTimeOfCyclePhase) / CHUNK_SIZE;
  }

  
  function currentSubchunk() public view returns (Subchunk _subchunk) {
    if (cyclePhase != CyclePhase.Manage) {
      return Subchunk.Vote;
    }
    uint256 timeIntoCurrChunk = (now - startTimeOfCyclePhase) % CHUNK_SIZE;
    return timeIntoCurrChunk < PROPOSE_SUBCHUNK_SIZE ? Subchunk.Propose : Subchunk.Vote;
  }

  
  function getVotingWeight(address _of) public view returns (uint256 _weight) {
    if (cycleNumber <= CYCLES_TILL_MATURITY || _of == address(0)) {
      return 0;
    }
    return cToken.balanceOfAt(_of, managePhaseEndBlock(cycleNumber.sub(CYCLES_TILL_MATURITY)));
  }

  
  function getTotalVotingWeight() public view returns (uint256 _weight) {
    if (cycleNumber <= CYCLES_TILL_MATURITY) {
      return 0;
    }
    return cToken.totalSupplyAt(managePhaseEndBlock(cycleNumber.sub(CYCLES_TILL_MATURITY))).sub(proposersVotingWeight);
  }

  
  function kairoPrice() public view returns (uint256 _kairoPrice) {
    if (cToken.totalSupply() == 0) { return MIN_KRO_PRICE; }
    uint256 controlPerKairo = totalFundsInDAI.mul(10 ** 18).div(cToken.totalSupply());
    if (controlPerKairo < MIN_KRO_PRICE) {
      
      return MIN_KRO_PRICE;
    }
    return controlPerKairo;
  }

  function lastCommissionRedemption(address _manager) public view returns (uint256) {
    if (_lastCommissionRedemption[_manager] == 0) {
      return previousVersion == address(0) ? 0 : BetokenStorage(previousVersion).lastCommissionRedemption(_manager);
    }
    return _lastCommissionRedemption[_manager];
  }

  function hasRedeemedCommissionForCycle(address _manager, uint256 _cycle) public view returns (bool) {
    if (_hasRedeemedCommissionForCycle[_manager][_cycle] == false) {
      return previousVersion == address(0) ? false : BetokenStorage(previousVersion).hasRedeemedCommissionForCycle(_manager, _cycle);
    }
    return _hasRedeemedCommissionForCycle[_manager][_cycle];
  }

  function riskTakenInCycle(address _manager, uint256 _cycle) public view returns (uint256) {
    if (_riskTakenInCycle[_manager][_cycle] == 0) {
      return previousVersion == address(0) ? 0 : BetokenStorage(previousVersion).riskTakenInCycle(_manager, _cycle);
    }
    return _riskTakenInCycle[_manager][_cycle];
  }

  function baseRiskStakeFallback(address _manager) public view returns (uint256) {
    if (_baseRiskStakeFallback[_manager] == 0) {
      return previousVersion == address(0) ? 0 : BetokenStorage(previousVersion).baseRiskStakeFallback(_manager);
    }
    return _baseRiskStakeFallback[_manager];
  }

  function totalCommissionOfCycle(uint256 _cycle) public view returns (uint256) {
    if (_totalCommissionOfCycle[_cycle] == 0) {
      return previousVersion == address(0) ? 0 : BetokenStorage(previousVersion).totalCommissionOfCycle(_cycle);
    }
    return _totalCommissionOfCycle[_cycle];
  }

  function managePhaseEndBlock(uint256 _cycle) public view returns (uint256) {
    if (_managePhaseEndBlock[_cycle] == 0) {
      return previousVersion == address(0) ? 0 : BetokenStorage(previousVersion).managePhaseEndBlock(_cycle);
    }
    return _managePhaseEndBlock[_cycle];
  }

  function lastActiveCycle(address _manager) public view returns (uint256) {
    if (_lastActiveCycle[_manager] == 0) {
      return previousVersion == address(0) ? 0 : BetokenStorage(previousVersion).lastActiveCycle(_manager);
    }
    return _lastActiveCycle[_manager];
  }
}

interface Comptroller {
    function enterMarkets(address[] calldata cTokens) external returns (uint[] memory);
    function markets(address cToken) external view returns (bool isListed, uint256 collateralFactorMantissa);
}

interface PriceOracle {
  function getUnderlyingPrice(address cToken) external view returns (uint);
}

interface CERC20 {
  function mint(uint mintAmount) external returns (uint);
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow(uint repayAmount) external returns (uint);
  function borrowBalanceCurrent(address account) external returns (uint);
  function exchangeRateCurrent() external returns (uint);

  function balanceOf(address account) external view returns (uint);
  function decimals() external view returns (uint);
  function underlying() external view returns (address);
}

interface CEther {
  function mint() external payable;
  function redeemUnderlying(uint redeemAmount) external returns (uint);
  function borrow(uint borrowAmount) external returns (uint);
  function repayBorrow() external payable;
  function borrowBalanceCurrent(address account) external returns (uint);
  function exchangeRateCurrent() external returns (uint);

  function balanceOf(address account) external view returns (uint);
  function decimals() external view returns (uint);
}

contract CompoundOrder is Utils(address(0), address(0), address(0)), Ownable {
  
  uint256 internal constant NEGLIGIBLE_DEBT = 10 ** 14; 
  uint256 internal constant MAX_REPAY_STEPS = 3; 
  uint256 internal constant DEFAULT_LIQUIDITY_SLIPPAGE = 10 ** 12; 
  uint256 internal constant FALLBACK_LIQUIDITY_SLIPPAGE = 10 ** 15; 
  uint256 internal constant MAX_LIQUIDITY_SLIPPAGE = 10 ** 17; 

  
  Comptroller public COMPTROLLER; 
  PriceOracle public ORACLE; 
  CERC20 public CDAI; 
  address public CETH_ADDR;

  
  uint256 public stake;
  uint256 public collateralAmountInDAI;
  uint256 public loanAmountInDAI;
  uint256 public cycleNumber;
  uint256 public buyTime; 
  uint256 public outputAmount; 
  address public compoundTokenAddr;
  bool public isSold;
  bool public orderType; 
  bool internal initialized;


  constructor() public {}

  function init(
    address _compoundTokenAddr,
    uint256 _cycleNumber,
    uint256 _stake,
    uint256 _collateralAmountInDAI,
    uint256 _loanAmountInDAI,
    bool _orderType,
    address _daiAddr,
    address payable _kyberAddr,
    address _comptrollerAddr,
    address _priceOracleAddr,
    address _cDAIAddr,
    address _cETHAddr
  ) public {
    require(!initialized);
    initialized = true;
    
    
    require(_compoundTokenAddr != _cDAIAddr);
    require(_stake > 0 && _collateralAmountInDAI > 0 && _loanAmountInDAI > 0); 
    stake = _stake;
    collateralAmountInDAI = _collateralAmountInDAI;
    loanAmountInDAI = _loanAmountInDAI;
    cycleNumber = _cycleNumber;
    compoundTokenAddr = _compoundTokenAddr;
    orderType = _orderType;

    COMPTROLLER = Comptroller(_comptrollerAddr);
    ORACLE = PriceOracle(_priceOracleAddr);
    CDAI = CERC20(_cDAIAddr);
    CETH_ADDR = _cETHAddr;
    DAI_ADDR = _daiAddr;
    KYBER_ADDR = _kyberAddr;
    dai = ERC20Detailed(_daiAddr);
    kyber = KyberNetwork(_kyberAddr);

    
    _transferOwnership(msg.sender);
  }

  
  function executeOrder(uint256 _minPrice, uint256 _maxPrice) public;

  
  function sellOrder(uint256 _minPrice, uint256 _maxPrice) public returns (uint256 _inputAmount, uint256 _outputAmount);

  
  function repayLoan(uint256 _repayAmountInDAI) public;

  function getMarketCollateralFactor() public view returns (uint256);

  function getCurrentCollateralInDAI() public returns (uint256 _amount);

  function getCurrentBorrowInDAI() public returns (uint256 _amount);

  function getCurrentCashInDAI() public view returns (uint256 _amount);

  
  function getCurrentProfitInDAI() public returns (bool _isNegative, uint256 _amount) {
    uint256 l;
    uint256 r;
    if (isSold) {
      l = outputAmount;
      r = collateralAmountInDAI;
    } else {
      uint256 cash = getCurrentCashInDAI();
      uint256 supply = getCurrentCollateralInDAI();
      uint256 borrow = getCurrentBorrowInDAI();
      if (cash >= borrow) {
        l = supply.add(cash);
        r = borrow.add(collateralAmountInDAI);
      } else {
        l = supply;
        r = borrow.sub(cash).mul(PRECISION).div(getMarketCollateralFactor()).add(collateralAmountInDAI);
      }
    }
    
    if (l >= r) {
      return (false, l.sub(r));
    } else {
      return (true, r.sub(l));
    }
  }

  
  function getCurrentCollateralRatioInDAI() public returns (uint256 _amount) {
    uint256 supply = getCurrentCollateralInDAI();
    uint256 borrow = getCurrentBorrowInDAI();
    if (borrow == 0) {
      return uint256(-1);
    }
    return supply.mul(PRECISION).div(borrow);
  }

  
  function getCurrentLiquidityInDAI() public returns (bool _isNegative, uint256 _amount) {
    uint256 supply = getCurrentCollateralInDAI();
    uint256 borrow = getCurrentBorrowInDAI().mul(PRECISION).div(getMarketCollateralFactor());
    if (supply >= borrow) {
      return (false, supply.sub(borrow));
    } else {
      return (true, borrow.sub(supply));
    }
  }

  function __sellDAIForToken(uint256 _daiAmount) internal returns (uint256 _actualDAIAmount, uint256 _actualTokenAmount) {
    ERC20Detailed t = __underlyingToken(compoundTokenAddr);
    (,, _actualTokenAmount, _actualDAIAmount) = __kyberTrade(dai, _daiAmount, t); 
    require(_actualDAIAmount > 0 && _actualTokenAmount > 0); 
  }

  function __sellTokenForDAI(uint256 _tokenAmount) internal returns (uint256 _actualDAIAmount, uint256 _actualTokenAmount) {
    ERC20Detailed t = __underlyingToken(compoundTokenAddr);
    (,, _actualDAIAmount, _actualTokenAmount) = __kyberTrade(t, _tokenAmount, dai); 
    require(_actualDAIAmount > 0 && _actualTokenAmount > 0); 
  }

  
  function __daiToToken(address _cToken, uint256 _daiAmount) internal view returns (uint256) {
    if (_cToken == CETH_ADDR) {
      
      return _daiAmount.mul(ORACLE.getUnderlyingPrice(address(CDAI))).div(PRECISION);
    }
    ERC20Detailed t = __underlyingToken(_cToken);
    return _daiAmount.mul(ORACLE.getUnderlyingPrice(address(CDAI))).mul(10 ** getDecimals(t)).div(ORACLE.getUnderlyingPrice(_cToken).mul(PRECISION));
  }

  
  function __tokenToDAI(address _cToken, uint256 _tokenAmount) internal view returns (uint256) {
    if (_cToken == CETH_ADDR) {
      
      return _tokenAmount.mul(PRECISION).div(ORACLE.getUnderlyingPrice(address(CDAI)));
    }
    ERC20Detailed t = __underlyingToken(_cToken);
    return _tokenAmount.mul(ORACLE.getUnderlyingPrice(_cToken)).mul(PRECISION).div(ORACLE.getUnderlyingPrice(address(CDAI)).mul(10 ** uint256(t.decimals())));
  }

  function __underlyingToken(address _cToken) internal view returns (ERC20Detailed) {
    if (_cToken == CETH_ADDR) {
      
      return ETH_TOKEN_ADDRESS;
    }
    CERC20 ct = CERC20(_cToken);
    address underlyingToken = ct.underlying();
    ERC20Detailed t = ERC20Detailed(underlyingToken);
    return t;
  }

  function() external payable {}
}

contract LongCERC20Order is CompoundOrder {
  modifier isValidPrice(uint256 _minPrice, uint256 _maxPrice) {
    
    uint256 tokenPrice = ORACLE.getUnderlyingPrice(compoundTokenAddr); 
    require(tokenPrice > 0); 
    tokenPrice = __tokenToDAI(CETH_ADDR, tokenPrice); 
    require(tokenPrice >= _minPrice && tokenPrice <= _maxPrice); 
    _;
  }

  function executeOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidToken(compoundTokenAddr)
    isValidPrice(_minPrice, _maxPrice)
  {
    buyTime = now;

    
    dai.safeTransferFrom(owner(), address(this), collateralAmountInDAI); 

    
    (,uint256 actualTokenAmount) = __sellDAIForToken(collateralAmountInDAI);

    
    CERC20 market = CERC20(compoundTokenAddr);
    address[] memory markets = new address[](2);
    markets[0] = compoundTokenAddr;
    markets[1] = address(CDAI);
    uint[] memory errors = COMPTROLLER.enterMarkets(markets);
    require(errors[0] == 0 && errors[1] == 0);

    
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    token.safeApprove(compoundTokenAddr, 0); 
    token.safeApprove(compoundTokenAddr, actualTokenAmount); 
    require(market.mint(actualTokenAmount) == 0); 
    token.safeApprove(compoundTokenAddr, 0); 
    require(CDAI.borrow(loanAmountInDAI) == 0);
    (bool negLiquidity, ) = getCurrentLiquidityInDAI();
    require(!negLiquidity); 

    
    __sellDAIForToken(loanAmountInDAI);

    
    if (dai.balanceOf(address(this)) > 0) {
      uint256 repayAmount = dai.balanceOf(address(this));
      dai.safeApprove(address(CDAI), 0);
      dai.safeApprove(address(CDAI), repayAmount);
      require(CDAI.repayBorrow(repayAmount) == 0);
      dai.safeApprove(address(CDAI), 0);
    }
  }

  function sellOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidPrice(_minPrice, _maxPrice)
    returns (uint256 _inputAmount, uint256 _outputAmount)
  {
    require(buyTime > 0); 
    require(isSold == false);
    isSold = true;
    
    
    
    CERC20 market = CERC20(compoundTokenAddr);
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    for (uint256 i = 0; i < MAX_REPAY_STEPS; i = i.add(1)) {
      uint256 currentDebt = getCurrentBorrowInDAI();
      if (currentDebt > NEGLIGIBLE_DEBT) {
        
        uint256 currentBalance = getCurrentCashInDAI();
        uint256 repayAmount = 0; 
        if (currentDebt <= currentBalance) {
          
          repayAmount = currentDebt;
        } else {
          
          repayAmount = currentBalance;
        }

        
        repayLoan(repayAmount);
      }

      
      (bool isNeg, uint256 liquidity) = getCurrentLiquidityInDAI();
      if (!isNeg) {
        liquidity = __daiToToken(compoundTokenAddr, liquidity);
        uint256 errorCode = market.redeemUnderlying(liquidity.mul(PRECISION.sub(DEFAULT_LIQUIDITY_SLIPPAGE)).div(PRECISION));
        if (errorCode != 0) {
          
          
          errorCode = market.redeemUnderlying(liquidity.mul(PRECISION.sub(FALLBACK_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          if (errorCode != 0) {
            
            
            market.redeemUnderlying(liquidity.mul(PRECISION.sub(MAX_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          }
        }
      }

      if (currentDebt <= NEGLIGIBLE_DEBT) {
        break;
      }
    }

    
    __sellTokenForDAI(token.balanceOf(address(this)));

    
    _inputAmount = collateralAmountInDAI;
    _outputAmount = dai.balanceOf(address(this));
    outputAmount = _outputAmount;
    dai.safeTransfer(owner(), dai.balanceOf(address(this)));
    token.safeTransfer(owner(), token.balanceOf(address(this))); 
  }

  
  function repayLoan(uint256 _repayAmountInDAI) public onlyOwner {
    require(buyTime > 0); 

    
    uint256 repayAmountInToken = __daiToToken(compoundTokenAddr, _repayAmountInDAI);
    (uint256 actualDAIAmount,) = __sellTokenForDAI(repayAmountInToken);
    
    
    uint256 currentDebt = CDAI.borrowBalanceCurrent(address(this));
    if (actualDAIAmount > currentDebt) {
      actualDAIAmount = currentDebt;
    }
    
    
    dai.safeApprove(address(CDAI), 0);
    dai.safeApprove(address(CDAI), actualDAIAmount);
    require(CDAI.repayBorrow(actualDAIAmount) == 0);
    dai.safeApprove(address(CDAI), 0);
  }

  function getMarketCollateralFactor() public view returns (uint256) {
    (, uint256 ratio) = COMPTROLLER.markets(address(compoundTokenAddr));
    return ratio;
  }

  function getCurrentCollateralInDAI() public returns (uint256 _amount) {
    CERC20 market = CERC20(compoundTokenAddr);
    uint256 supply = __tokenToDAI(compoundTokenAddr, market.balanceOf(address(this)).mul(market.exchangeRateCurrent()).div(PRECISION));
    return supply;
  }

  function getCurrentBorrowInDAI() public returns (uint256 _amount) {
    uint256 borrow = CDAI.borrowBalanceCurrent(address(this));
    return borrow;
  }

  function getCurrentCashInDAI() public view returns (uint256 _amount) {
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    uint256 cash = __tokenToDAI(compoundTokenAddr, getBalance(token, address(this)));
    return cash;
  }
}

contract LongCEtherOrder is CompoundOrder {
  modifier isValidPrice(uint256 _minPrice, uint256 _maxPrice) {
    
    uint256 tokenPrice = PRECISION; 
    tokenPrice = __tokenToDAI(CETH_ADDR, tokenPrice); 
    require(tokenPrice >= _minPrice && tokenPrice <= _maxPrice); 
    _;
  }

  function executeOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidToken(compoundTokenAddr)
    isValidPrice(_minPrice, _maxPrice)
  {
    buyTime = now;
    
    
    dai.safeTransferFrom(owner(), address(this), collateralAmountInDAI); 

    
    (,uint256 actualTokenAmount) = __sellDAIForToken(collateralAmountInDAI);

    
    CEther market = CEther(compoundTokenAddr);
    address[] memory markets = new address[](2);
    markets[0] = compoundTokenAddr;
    markets[1] = address(CDAI);
    uint[] memory errors = COMPTROLLER.enterMarkets(markets);
    require(errors[0] == 0 && errors[1] == 0);
    
    
    market.mint.value(actualTokenAmount)(); 
    require(CDAI.borrow(loanAmountInDAI) == 0);
    (bool negLiquidity, ) = getCurrentLiquidityInDAI();
    require(!negLiquidity); 

    
    __sellDAIForToken(loanAmountInDAI);

    
    if (dai.balanceOf(address(this)) > 0) {
      uint256 repayAmount = dai.balanceOf(address(this));
      dai.safeApprove(address(CDAI), 0);
      dai.safeApprove(address(CDAI), repayAmount);
      require(CDAI.repayBorrow(repayAmount) == 0);
      dai.safeApprove(address(CDAI), 0);
    }
  }

  function sellOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidPrice(_minPrice, _maxPrice)
    returns (uint256 _inputAmount, uint256 _outputAmount)
  {
    require(buyTime > 0); 
    require(isSold == false);
    isSold = true;

    
    
    CEther market = CEther(compoundTokenAddr);
    for (uint256 i = 0; i < MAX_REPAY_STEPS; i = i.add(1)) {
      uint256 currentDebt = getCurrentBorrowInDAI();
      if (currentDebt > NEGLIGIBLE_DEBT) {
        
        uint256 currentBalance = getCurrentCashInDAI();
        uint256 repayAmount = 0; 
        if (currentDebt <= currentBalance) {
          
          repayAmount = currentDebt;
        } else {
          
          repayAmount = currentBalance;
        }

        
        repayLoan(repayAmount);
      }

      
      (bool isNeg, uint256 liquidity) = getCurrentLiquidityInDAI();
      if (!isNeg) {
        liquidity = __daiToToken(compoundTokenAddr, liquidity);
        uint256 errorCode = market.redeemUnderlying(liquidity.mul(PRECISION.sub(DEFAULT_LIQUIDITY_SLIPPAGE)).div(PRECISION));
        if (errorCode != 0) {
          
          
          errorCode = market.redeemUnderlying(liquidity.mul(PRECISION.sub(FALLBACK_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          if (errorCode != 0) {
            
            
            market.redeemUnderlying(liquidity.mul(PRECISION.sub(MAX_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          }
        }
      }

      if (currentDebt <= NEGLIGIBLE_DEBT) {
        break;
      }
    }

    
    __sellTokenForDAI(address(this).balance);

    
    _inputAmount = collateralAmountInDAI;
    _outputAmount = dai.balanceOf(address(this));
    outputAmount = _outputAmount;
    dai.safeTransfer(owner(), dai.balanceOf(address(this)));
    toPayableAddr(owner()).transfer(address(this).balance); 
  }

  
  function repayLoan(uint256 _repayAmountInDAI) public onlyOwner {
    require(buyTime > 0); 

    
    uint256 repayAmountInToken = __daiToToken(compoundTokenAddr, _repayAmountInDAI);
    (uint256 actualDAIAmount,) = __sellTokenForDAI(repayAmountInToken);
    
    
    uint256 currentDebt = CDAI.borrowBalanceCurrent(address(this));
    if (actualDAIAmount > currentDebt) {
      actualDAIAmount = currentDebt;
    }

    
    dai.safeApprove(address(CDAI), 0);
    dai.safeApprove(address(CDAI), actualDAIAmount);
    require(CDAI.repayBorrow(actualDAIAmount) == 0);
    dai.safeApprove(address(CDAI), 0);
  }

  function getMarketCollateralFactor() public view returns (uint256) {
    (, uint256 ratio) = COMPTROLLER.markets(address(compoundTokenAddr));
    return ratio;
  }

  function getCurrentCollateralInDAI() public returns (uint256 _amount) {
    CEther market = CEther(compoundTokenAddr);
    uint256 supply = __tokenToDAI(compoundTokenAddr, market.balanceOf(address(this)).mul(market.exchangeRateCurrent()).div(PRECISION));
    return supply;
  }

  function getCurrentBorrowInDAI() public returns (uint256 _amount) {
    uint256 borrow = CDAI.borrowBalanceCurrent(address(this));
    return borrow;
  }

  function getCurrentCashInDAI() public view returns (uint256 _amount) {
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    uint256 cash = __tokenToDAI(compoundTokenAddr, getBalance(token, address(this)));
    return cash;
  }
}

contract ShortCERC20Order is CompoundOrder {
  modifier isValidPrice(uint256 _minPrice, uint256 _maxPrice) {
    
    uint256 tokenPrice = ORACLE.getUnderlyingPrice(compoundTokenAddr); 
    require(tokenPrice > 0); 
    tokenPrice = __tokenToDAI(CETH_ADDR, tokenPrice); 
    require(tokenPrice >= _minPrice && tokenPrice <= _maxPrice); 
    _;
  }

  function executeOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidToken(compoundTokenAddr)
    isValidPrice(_minPrice, _maxPrice)
  {
    buyTime = now;

    
    dai.safeTransferFrom(owner(), address(this), collateralAmountInDAI); 

    
    CERC20 market = CERC20(compoundTokenAddr);
    address[] memory markets = new address[](2);
    markets[0] = compoundTokenAddr;
    markets[1] = address(CDAI);
    uint[] memory errors = COMPTROLLER.enterMarkets(markets);
    require(errors[0] == 0 && errors[1] == 0);
    
    
    uint256 loanAmountInToken = __daiToToken(compoundTokenAddr, loanAmountInDAI);
    dai.safeApprove(address(CDAI), 0); 
    dai.safeApprove(address(CDAI), collateralAmountInDAI); 
    require(CDAI.mint(collateralAmountInDAI) == 0); 
    dai.safeApprove(address(CDAI), 0);
    require(market.borrow(loanAmountInToken) == 0);
    (bool negLiquidity, ) = getCurrentLiquidityInDAI();
    require(!negLiquidity); 

    
    (uint256 actualDAIAmount,) = __sellTokenForDAI(loanAmountInToken);
    loanAmountInDAI = actualDAIAmount; 

    
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    if (token.balanceOf(address(this)) > 0) {
      uint256 repayAmount = token.balanceOf(address(this));
      token.safeApprove(compoundTokenAddr, 0);
      token.safeApprove(compoundTokenAddr, repayAmount);
      require(market.repayBorrow(repayAmount) == 0);
      token.safeApprove(compoundTokenAddr, 0);
    }
  }

  function sellOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidPrice(_minPrice, _maxPrice)
    returns (uint256 _inputAmount, uint256 _outputAmount)
  {
    require(buyTime > 0); 
    require(isSold == false);
    isSold = true;

    
    
    for (uint256 i = 0; i < MAX_REPAY_STEPS; i = i.add(1)) {
      uint256 currentDebt = getCurrentBorrowInDAI();
      if (currentDebt > NEGLIGIBLE_DEBT) {
        
        uint256 currentBalance = getCurrentCashInDAI();
        uint256 repayAmount = 0; 
        if (currentDebt <= currentBalance) {
          
          repayAmount = currentDebt;
        } else {
          
          repayAmount = currentBalance;
        }

        
        repayLoan(repayAmount);
      }

      
      (bool isNeg, uint256 liquidity) = getCurrentLiquidityInDAI();
      if (!isNeg) {
        uint256 errorCode = CDAI.redeemUnderlying(liquidity.mul(PRECISION.sub(DEFAULT_LIQUIDITY_SLIPPAGE)).div(PRECISION));
        if (errorCode != 0) {
          
          
          errorCode = CDAI.redeemUnderlying(liquidity.mul(PRECISION.sub(FALLBACK_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          if (errorCode != 0) {
            
            
            CDAI.redeemUnderlying(liquidity.mul(PRECISION.sub(MAX_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          }
        }
      }

      if (currentDebt <= NEGLIGIBLE_DEBT) {
        break;
      }
    }

    
    _inputAmount = collateralAmountInDAI;
    _outputAmount = dai.balanceOf(address(this));
    outputAmount = _outputAmount;
    dai.safeTransfer(owner(), dai.balanceOf(address(this)));
  }

  
  function repayLoan(uint256 _repayAmountInDAI) public onlyOwner {
    require(buyTime > 0); 

    
    (,uint256 actualTokenAmount) = __sellDAIForToken(_repayAmountInDAI);

    
    CERC20 market = CERC20(compoundTokenAddr);
    uint256 currentDebt = market.borrowBalanceCurrent(address(this));
    if (actualTokenAmount > currentDebt) {
      actualTokenAmount = currentDebt;
    }

    
    ERC20Detailed token = __underlyingToken(compoundTokenAddr);
    token.safeApprove(compoundTokenAddr, 0);
    token.safeApprove(compoundTokenAddr, actualTokenAmount);
    require(market.repayBorrow(actualTokenAmount) == 0);
    token.safeApprove(compoundTokenAddr, 0);
  }

  function getMarketCollateralFactor() public view returns (uint256) {
    (, uint256 ratio) = COMPTROLLER.markets(address(CDAI));
    return ratio;
  }

  function getCurrentCollateralInDAI() public returns (uint256 _amount) {
    uint256 supply = CDAI.balanceOf(address(this)).mul(CDAI.exchangeRateCurrent()).div(PRECISION);
    return supply;
  }

  function getCurrentBorrowInDAI() public returns (uint256 _amount) {
    CERC20 market = CERC20(compoundTokenAddr);
    uint256 borrow = __tokenToDAI(compoundTokenAddr, market.borrowBalanceCurrent(address(this)));
    return borrow;
  }

  function getCurrentCashInDAI() public view returns (uint256 _amount) {
    uint256 cash = getBalance(dai, address(this));
    return cash;
  }
}

contract ShortCEtherOrder is CompoundOrder {
  modifier isValidPrice(uint256 _minPrice, uint256 _maxPrice) {
    
    uint256 tokenPrice = PRECISION; 
    tokenPrice = __tokenToDAI(CETH_ADDR, tokenPrice); 
    require(tokenPrice >= _minPrice && tokenPrice <= _maxPrice); 
    _;
  }

  function executeOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidToken(compoundTokenAddr)
    isValidPrice(_minPrice, _maxPrice)
  {
    buyTime = now;

    
    dai.safeTransferFrom(owner(), address(this), collateralAmountInDAI); 
    
    
    CEther market = CEther(compoundTokenAddr);
    address[] memory markets = new address[](2);
    markets[0] = compoundTokenAddr;
    markets[1] = address(CDAI);
    uint[] memory errors = COMPTROLLER.enterMarkets(markets);
    require(errors[0] == 0 && errors[1] == 0);

    
    uint256 loanAmountInToken = __daiToToken(compoundTokenAddr, loanAmountInDAI);
    dai.safeApprove(address(CDAI), 0); 
    dai.safeApprove(address(CDAI), collateralAmountInDAI); 
    require(CDAI.mint(collateralAmountInDAI) == 0); 
    dai.safeApprove(address(CDAI), 0);
    require(market.borrow(loanAmountInToken) == 0);
    (bool negLiquidity, ) = getCurrentLiquidityInDAI();
    require(!negLiquidity); 

    
    (uint256 actualDAIAmount,) = __sellTokenForDAI(loanAmountInToken);
    loanAmountInDAI = actualDAIAmount; 

    
    if (address(this).balance > 0) {
      uint256 repayAmount = address(this).balance;
      market.repayBorrow.value(repayAmount)();
    }
  }

  function sellOrder(uint256 _minPrice, uint256 _maxPrice)
    public
    onlyOwner
    isValidPrice(_minPrice, _maxPrice)
    returns (uint256 _inputAmount, uint256 _outputAmount)
  {
    require(buyTime > 0); 
    require(isSold == false);
    isSold = true;

    
    
    for (uint256 i = 0; i < MAX_REPAY_STEPS; i = i.add(1)) {
      uint256 currentDebt = getCurrentBorrowInDAI();
      if (currentDebt > NEGLIGIBLE_DEBT) {
        
        uint256 currentBalance = getCurrentCashInDAI();
        uint256 repayAmount = 0; 
        if (currentDebt <= currentBalance) {
          
          repayAmount = currentDebt;
        } else {
          
          repayAmount = currentBalance;
        }

        
        repayLoan(repayAmount);
      }

      
      (bool isNeg, uint256 liquidity) = getCurrentLiquidityInDAI();
      if (!isNeg) {
        uint256 errorCode = CDAI.redeemUnderlying(liquidity.mul(PRECISION.sub(DEFAULT_LIQUIDITY_SLIPPAGE)).div(PRECISION));
        if (errorCode != 0) {
          
          
          errorCode = CDAI.redeemUnderlying(liquidity.mul(PRECISION.sub(FALLBACK_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          if (errorCode != 0) {
            
            
            CDAI.redeemUnderlying(liquidity.mul(PRECISION.sub(MAX_LIQUIDITY_SLIPPAGE)).div(PRECISION));
          }
        }
      }

      if (currentDebt <= NEGLIGIBLE_DEBT) {
        break;
      }
    }

    
    _inputAmount = collateralAmountInDAI;
    _outputAmount = dai.balanceOf(address(this));
    outputAmount = _outputAmount;
    dai.safeTransfer(owner(), dai.balanceOf(address(this)));
  }

  
  function repayLoan(uint256 _repayAmountInDAI) public onlyOwner {
    require(buyTime > 0); 

    
    (,uint256 actualTokenAmount) = __sellDAIForToken(_repayAmountInDAI);

    
    CEther market = CEther(compoundTokenAddr);
    uint256 currentDebt = market.borrowBalanceCurrent(address(this));
    if (actualTokenAmount > currentDebt) {
      actualTokenAmount = currentDebt;
    }

    
    market.repayBorrow.value(actualTokenAmount)();
  }

  function getMarketCollateralFactor() public view returns (uint256) {
    (, uint256 ratio) = COMPTROLLER.markets(address(CDAI));
    return ratio;
  }

  function getCurrentCollateralInDAI() public returns (uint256 _amount) {
    uint256 supply = CDAI.balanceOf(address(this)).mul(CDAI.exchangeRateCurrent()).div(PRECISION);
    return supply;
  }

  function getCurrentBorrowInDAI() public returns (uint256 _amount) {
    CEther market = CEther(compoundTokenAddr);
    uint256 borrow = __tokenToDAI(compoundTokenAddr, market.borrowBalanceCurrent(address(this)));
    return borrow;
  }

  function getCurrentCashInDAI() public view returns (uint256 _amount) {
    uint256 cash = getBalance(dai, address(this));
    return cash;
  }
}

contract CloneFactory {

  function createClone(address target) internal returns (address result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
      mstore(add(clone, 0x14), targetBytes)
      mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
      result := create(0, clone, 0x37)
    }
  }

  function isClone(address target, address query) internal view returns (bool result) {
    bytes20 targetBytes = bytes20(target);
    assembly {
      let clone := mload(0x40)
      mstore(clone, 0x363d3d373d3d3d363d7300000000000000000000000000000000000000000000)
      mstore(add(clone, 0xa), targetBytes)
      mstore(add(clone, 0x1e), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)

      let other := add(clone, 0x40)
      extcodecopy(query, other, 0, 0x2d)
      result := and(
        eq(mload(clone), mload(other)),
        eq(mload(add(clone, 0xd)), mload(add(other, 0xd)))
      )
    }
  }
}

contract CompoundOrderFactory is CloneFactory {
  address public SHORT_CERC20_LOGIC_CONTRACT;
  address public SHORT_CEther_LOGIC_CONTRACT;
  address public LONG_CERC20_LOGIC_CONTRACT;
  address public LONG_CEther_LOGIC_CONTRACT;

  address public DAI_ADDR;
  address payable public KYBER_ADDR;
  address public COMPTROLLER_ADDR;
  address public ORACLE_ADDR;
  address public CDAI_ADDR;
  address public CETH_ADDR;

  constructor(
    address _shortCERC20LogicContract,
    address _shortCEtherLogicContract,
    address _longCERC20LogicContract,
    address _longCEtherLogicContract,
    address _daiAddr,
    address payable _kyberAddr,
    address _comptrollerAddr,
    address _priceOracleAddr,
    address _cDAIAddr,
    address _cETHAddr
  ) public {
    SHORT_CERC20_LOGIC_CONTRACT = _shortCERC20LogicContract;
    SHORT_CEther_LOGIC_CONTRACT = _shortCEtherLogicContract;
    LONG_CERC20_LOGIC_CONTRACT = _longCERC20LogicContract;
    LONG_CEther_LOGIC_CONTRACT = _longCEtherLogicContract;

    DAI_ADDR = _daiAddr;
    KYBER_ADDR = _kyberAddr;
    COMPTROLLER_ADDR = _comptrollerAddr;
    ORACLE_ADDR = _priceOracleAddr;
    CDAI_ADDR = _cDAIAddr;
    CETH_ADDR = _cETHAddr;
  }

  function createOrder(
    address _compoundTokenAddr,
    uint256 _cycleNumber,
    uint256 _stake,
    uint256 _collateralAmountInDAI,
    uint256 _loanAmountInDAI,
    bool _orderType
  ) external returns (CompoundOrder) {
    require(_compoundTokenAddr != address(0));

    CompoundOrder order;

    address payable clone;
    if (_compoundTokenAddr != CETH_ADDR) {
      if (_orderType) {
        
        clone = toPayableAddr(createClone(SHORT_CERC20_LOGIC_CONTRACT));
      } else {
        
        clone = toPayableAddr(createClone(LONG_CERC20_LOGIC_CONTRACT));
      }
    } else {
      if (_orderType) {
        
        clone = toPayableAddr(createClone(SHORT_CEther_LOGIC_CONTRACT));
      } else {
        
        clone = toPayableAddr(createClone(LONG_CEther_LOGIC_CONTRACT));
      }
    }
    order = CompoundOrder(clone);
    order.init(_compoundTokenAddr, _cycleNumber, _stake, _collateralAmountInDAI, _loanAmountInDAI, _orderType,
      DAI_ADDR, KYBER_ADDR, COMPTROLLER_ADDR, ORACLE_ADDR, CDAI_ADDR, CETH_ADDR);
    order.transferOwnership(msg.sender);
    return order;
  }

  function getMarketCollateralFactor(address _compoundTokenAddr) external view returns (uint256) {
    Comptroller troll = Comptroller(COMPTROLLER_ADDR);
    (, uint256 factor) = troll.markets(_compoundTokenAddr);
    return factor;
  }

  function tokenIsListed(address _compoundTokenAddr) external view returns (bool) {
    Comptroller troll = Comptroller(COMPTROLLER_ADDR);
    (bool isListed,) = troll.markets(_compoundTokenAddr);
    return isListed;
  }

  function toPayableAddr(address _addr) internal pure returns (address payable) {
    return address(uint160(_addr));
  }
}

contract BetokenFund is BetokenStorage, Utils, TokenController {
  
  modifier readyForUpgradeMigration {
    require(hasFinalizedNextVersion == true);
    require(now > startTimeOfCyclePhase.add(phaseLengths[uint(CyclePhase.Intermission)]));
    _;
  }


  

  constructor(
    address payable _kroAddr,
    address payable _sTokenAddr,
    address payable _devFundingAccount,
    uint256[2] memory _phaseLengths,
    uint256 _devFundingRate,
    address payable _previousVersion,
    address _daiAddr,
    address payable _kyberAddr,
    address _compoundFactoryAddr,
    address _betokenLogic,
    address _betokenLogic2,
    uint256 _startCycleNumber,
    address payable _dexagAddr,
    address _saiAddr,
    address _mcdaiMigrationAddr
  )
    public
    Utils(_daiAddr, _kyberAddr, _dexagAddr)
  {
    controlTokenAddr = _kroAddr;
    shareTokenAddr = _sTokenAddr;
    devFundingAccount = _devFundingAccount;
    phaseLengths = _phaseLengths;
    devFundingRate = _devFundingRate;
    cyclePhase = CyclePhase.Intermission;
    compoundFactoryAddr = _compoundFactoryAddr;
    betokenLogic = _betokenLogic;
    betokenLogic2 = _betokenLogic2;
    previousVersion = _previousVersion;
    cycleNumber = _startCycleNumber;
    saiAddr = _saiAddr;

    cToken = IMiniMeToken(_kroAddr);
    sToken = IMiniMeToken(_sTokenAddr);
    mcdaiMigration = ScdMcdMigration(_mcdaiMigrationAddr);
  }

  function initTokenListings(
    address[] memory _kyberTokens,
    address[] memory _compoundTokens,
    address[] memory _positionTokens
  )
    public
    onlyOwner
  {
    
    require(!hasInitializedTokenListings);
    hasInitializedTokenListings = true;

    uint256 i;
    for (i = 0; i < _kyberTokens.length; i = i.add(1)) {
      isKyberToken[_kyberTokens[i]] = true;
    }

    for (i = 0; i < _compoundTokens.length; i = i.add(1)) {
      isCompoundToken[_compoundTokens[i]] = true;
    }

    for (i = 0; i < _positionTokens.length; i = i.add(1)) {
      isPositionToken[_positionTokens[i]] = true;
    }
  }

  
  function setProxy(address payable _proxyAddr) public onlyOwner {
    require(_proxyAddr != address(0));
    require(proxyAddr == address(0));
    proxyAddr = _proxyAddr;
    proxy = BetokenProxyInterface(_proxyAddr);
  }

  

  
  function developerInitiateUpgrade(address payable _candidate) public returns (bool _success) {
    (bool success, bytes memory result) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.developerInitiateUpgrade.selector, _candidate));
    if (!success) { return false; }
    return abi.decode(result, (bool));
  }

  
  function signalUpgrade(bool _inSupport) public returns (bool _success) {
    (bool success, bytes memory result) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.signalUpgrade.selector, _inSupport));
    if (!success) { return false; }
    return abi.decode(result, (bool));
  }

  
  function proposeCandidate(uint256 _chunkNumber, address payable _candidate) public returns (bool _success) {
    (bool success, bytes memory result) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.proposeCandidate.selector, _chunkNumber, _candidate));
    if (!success) { return false; }
    return abi.decode(result, (bool));
  }

  
  function voteOnCandidate(uint256 _chunkNumber, bool _inSupport) public returns (bool _success) {
    (bool success, bytes memory result) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.voteOnCandidate.selector, _chunkNumber, _inSupport));
    if (!success) { return false; }
    return abi.decode(result, (bool));
  }

  
  function finalizeSuccessfulVote(uint256 _chunkNumber) public returns (bool _success) {
    (bool success, bytes memory result) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.finalizeSuccessfulVote.selector, _chunkNumber));
    if (!success) { return false; }
    return abi.decode(result, (bool));
  }

  
  function migrateOwnedContractsToNextVersion() public nonReentrant readyForUpgradeMigration {
    cToken.transferOwnership(nextVersion);
    sToken.transferOwnership(nextVersion);
    proxy.updateBetokenFundAddress();
  }

  
  function transferAssetToNextVersion(address _assetAddress) public nonReentrant readyForUpgradeMigration isValidToken(_assetAddress) {
    if (_assetAddress == address(ETH_TOKEN_ADDRESS)) {
      nextVersion.transfer(address(this).balance);
    } else {
      ERC20Detailed token = ERC20Detailed(_assetAddress);
      token.safeTransfer(nextVersion, token.balanceOf(address(this)));
    }
  }

  

  
  function investmentsCount(address _userAddr) public view returns(uint256 _count) {
    return userInvestments[_userAddr].length;
  }

  
  function compoundOrdersCount(address _userAddr) public view returns(uint256 _count) {
    return userCompoundOrders[_userAddr].length;
  }

  
  function getPhaseLengths() public view returns(uint256[2] memory _phaseLengths) {
    return phaseLengths;
  }

  
  function commissionBalanceOf(address _manager) public returns (uint256 _commission, uint256 _penalty) {
    (bool success, bytes memory result) = betokenLogic.delegatecall(abi.encodeWithSelector(this.commissionBalanceOf.selector, _manager));
    if (!success) { return (0, 0); }
    return abi.decode(result, (uint256, uint256));
  }

  
  function commissionOfAt(address _manager, uint256 _cycle) public returns (uint256 _commission, uint256 _penalty) {
    (bool success, bytes memory result) = betokenLogic.delegatecall(abi.encodeWithSelector(this.commissionOfAt.selector, _manager, _cycle));
    if (!success) { return (0, 0); }
    return abi.decode(result, (uint256, uint256));
  }

  

  
  function changeDeveloperFeeAccount(address payable _newAddr) public onlyOwner {
    require(_newAddr != address(0) && _newAddr != address(this));
    devFundingAccount = _newAddr;
  }

  
  function changeDeveloperFeeRate(uint256 _newProp) public onlyOwner {
    require(_newProp < PRECISION);
    require(_newProp < devFundingRate);
    devFundingRate = _newProp;
  }

  
  function listKyberToken(address _token) public onlyOwner {
    isKyberToken[_token] = true;
  }

  
  function listCompoundToken(address _token) public onlyOwner {
    CompoundOrderFactory factory = CompoundOrderFactory(compoundFactoryAddr);
    require(factory.tokenIsListed(_token));
    isCompoundToken[_token] = true;
  }

  
  function nextPhase()
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.nextPhase.selector));
    if (!success) { revert(); }
  }


  

  
  function registerWithDAI(uint256 _donationInDAI) public {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.registerWithDAI.selector, _donationInDAI));
    if (!success) { revert(); }
  }

  
  function registerWithETH() public payable {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.registerWithETH.selector));
    if (!success) { revert(); }
  }

  
  function registerWithToken(address _token, uint256 _donationInTokens) public {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.registerWithToken.selector, _token, _donationInTokens));
    if (!success) { revert(); }
  }


  

  
  function depositEther()
    public
    payable
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.depositEther.selector));
    if (!success) { revert(); }
  }

  
  function depositDAI(uint256 _daiAmount)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.depositDAI.selector, _daiAmount));
    if (!success) { revert(); }
  }

  
  function depositToken(address _tokenAddr, uint256 _tokenAmount)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.depositToken.selector, _tokenAddr, _tokenAmount));
    if (!success) { revert(); }
  }

  
  function withdrawEther(uint256 _amountInDAI)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.withdrawEther.selector, _amountInDAI));
    if (!success) { revert(); }
  }

  
  function withdrawDAI(uint256 _amountInDAI)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.withdrawDAI.selector, _amountInDAI));
    if (!success) { revert(); }
  }

  
  function withdrawToken(address _tokenAddr, uint256 _amountInDAI)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.withdrawToken.selector, _tokenAddr, _amountInDAI));
    if (!success) { revert(); }
  }

  
  function redeemCommission(bool _inShares)
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.redeemCommission.selector, _inShares));
    if (!success) { revert(); }
  }

  
  function redeemCommissionForCycle(bool _inShares, uint256 _cycle)
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.redeemCommissionForCycle.selector, _inShares, _cycle));
    if (!success) { revert(); }
  }

  
  function sellLeftoverToken(address _tokenAddr)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.sellLeftoverToken.selector, _tokenAddr));
    if (!success) { revert(); }
  }

  function sellLeftoverFulcrumToken(address _tokenAddr)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.sellLeftoverFulcrumToken.selector, _tokenAddr));
    if (!success) { revert(); }
  }

  
  function sellLeftoverCompoundOrder(address payable _orderAddress)
    public
  {
    (bool success,) = betokenLogic2.delegatecall(abi.encodeWithSelector(this.sellLeftoverCompoundOrder.selector, _orderAddress));
    if (!success) { revert(); }
  }

  
  function burnDeadman(address _deadman)
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.burnDeadman.selector, _deadman));
    if (!success) { revert(); }
  }

  

  
  function createInvestment(
    address _tokenAddress,
    uint256 _stake,
    uint256 _minPrice,
    uint256 _maxPrice
  )
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.createInvestment.selector, _tokenAddress, _stake, _minPrice, _maxPrice));
    if (!success) { revert(); }
  }

  
  function createInvestmentV2(
    address _tokenAddress,
    uint256 _stake,
    uint256 _minPrice,
    uint256 _maxPrice,
    bytes memory _calldata,
    bool _useKyber
  )
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.createInvestmentV2.selector, _tokenAddress, _stake, _minPrice, _maxPrice, _calldata, _useKyber));
    if (!success) { revert(); }
  }

  
  function sellInvestmentAsset(
    uint256 _investmentId,
    uint256 _tokenAmount,
    uint256 _minPrice,
    uint256 _maxPrice
  )
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.sellInvestmentAsset.selector, _investmentId, _tokenAmount, _minPrice, _maxPrice));
    if (!success) { revert(); }
  }

  
  function sellInvestmentAssetV2(
    uint256 _investmentId,
    uint256 _tokenAmount,
    uint256 _minPrice,
    uint256 _maxPrice,
    bytes memory _calldata,
    bool _useKyber
  )
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.sellInvestmentAssetV2.selector, _investmentId, _tokenAmount, _minPrice, _maxPrice, _calldata, _useKyber));
    if (!success) { revert(); }
  }

  
  function createCompoundOrder(
    bool _orderType,
    address _tokenAddress,
    uint256 _stake,
    uint256 _minPrice,
    uint256 _maxPrice
  )
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.createCompoundOrder.selector, _orderType, _tokenAddress, _stake, _minPrice, _maxPrice));
    if (!success) { revert(); }
  }

  
  function sellCompoundOrder(
    uint256 _orderId,
    uint256 _minPrice,
    uint256 _maxPrice
  )
    public
  {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.sellCompoundOrder.selector, _orderId, _minPrice, _maxPrice));
    if (!success) { revert(); }
  }

  
  function repayCompoundOrder(uint256 _orderId, uint256 _repayAmountInDAI) public {
    (bool success,) = betokenLogic.delegatecall(abi.encodeWithSelector(this.repayCompoundOrder.selector, _orderId, _repayAmountInDAI));
    if (!success) { revert(); }
  }

  

  
  
  function proxyPayment(address _owner) public payable returns(bool) {
    return false;
  }

  
  function onTransfer(address _from, address _to, uint _amount) public returns(bool) {
    return true;
  }

  
  function onApprove(address _owner, address _spender, uint _amount) public
      returns(bool) {
    return true;
  }

  function() external payable {}
}