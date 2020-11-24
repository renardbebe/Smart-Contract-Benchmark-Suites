 

pragma solidity 0.4.24;

 
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

contract ComponentContainerInterface {
    mapping (bytes32 => address) components;

    event ComponentUpdated (bytes32 _name, address _componentAddress);

    function setComponent(bytes32 _name, address _providerAddress) internal returns (bool success);
    function setComponents(bytes32[] _names, address[] _providerAddresses) internal returns (bool success);
    function getComponentByName(bytes32 name) public view returns (address);
    function getComponents(bytes32[] _names) internal view returns (address[]);

}

contract DerivativeInterface is  Ownable, ComponentContainerInterface {

    enum DerivativeStatus { New, Active, Paused, Closed }
    enum DerivativeType { Index, Fund, Future }

    string public description;
    bytes32 public category;
    
    bytes32 public version;
    DerivativeType public fundType;
    DerivativeStatus public status;


    function _initialize (address _componentList) internal;
    function updateComponent(bytes32 _name) public returns (address);
    function approveComponent(bytes32 _name) internal;


}

contract ComponentContainer is ComponentContainerInterface {

    function setComponent(bytes32 _name, address _componentAddress) internal returns (bool success) {
        require(_componentAddress != address(0));
        components[_name] = _componentAddress;
        return true;
    }

    function getComponentByName(bytes32 _name) public view returns (address) {
        return components[_name];
    }

    function getComponents(bytes32[] _names) internal view returns (address[]) {
        address[] memory addresses = new address[](_names.length);
        for (uint i = 0; i < _names.length; i++) {
            addresses[i] = getComponentByName(_names[i]);
        }

        return addresses;
    }

    function setComponents(bytes32[] _names, address[] _providerAddresses) internal returns (bool success) {
        require(_names.length == _providerAddresses.length);
        require(_names.length > 0);

        for (uint i = 0; i < _names.length; i++ ) {
            setComponent(_names[i], _providerAddresses[i]);
        }

        return true;
    }
}

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

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
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

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
    uint256 _addedValue
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
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

contract ERC20Extended is ERC20 {
    uint256 public decimals;
    string public name;
    string public symbol;

}

contract ComponentListInterface {
    event ComponentUpdated (bytes32 _name, string _version, address _componentAddress);
    function setComponent(bytes32 _name, address _componentAddress) public returns (bool);
    function getComponent(bytes32 _name, string _version) public view returns (address);
    function getLatestComponent(bytes32 _name) public view returns(address);
    function getLatestComponents(bytes32[] _names) public view returns(address[]);
}

contract ERC20NoReturn {
    uint256 public decimals;
    string public name;
    string public symbol;
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public;
    function approve(address spender, uint tokens) public;
    function transferFrom(address from, address to, uint tokens) public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract FeeChargerInterface {
     
     
    ERC20Extended public MOT = ERC20Extended(0x263c618480DBe35C300D8d5EcDA19bbB986AcaeD);
     
    function setMotAddress(address _motAddress) external returns (bool success);
}

contract ComponentInterface {
    string public name;
    string public description;
    string public category;
    string public version;
}

contract WhitelistInterface is ComponentInterface {

     
    mapping (address => mapping(uint => mapping(address => bool))) public whitelist;
     
    mapping (address => mapping(uint => bool)) public enabled;

    function setStatus(uint _key, bool enable) external;
    function isAllowed(uint _key, address _account) external view returns(bool);
    function setAllowed(address[] accounts, uint _key, bool allowed) external returns(bool);
}

contract RiskControlInterface is ComponentInterface {
    function hasRisk(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate)
        external returns(bool isRisky);
}

contract LockerInterface {
     
    function checkLockByBlockNumber(bytes32 _lockerName) external;

    function setBlockInterval(bytes32 _lockerName, uint _blocks) external;
    function setMultipleBlockIntervals(bytes32[] _lockerNames, uint[] _blocks) external;

     
    function checkLockerByTime(bytes32 _timerName) external;

    function setTimeInterval(bytes32 _timerName, uint _seconds) external;
    function setMultipleTimeIntervals(bytes32[] _timerNames, uint[] _hours) external;

}

interface StepInterface {
     
    function getMaxCalls(bytes32 _category) external view returns(uint _maxCall);
     
    function setMaxCalls(bytes32 _category, uint _maxCallsList) external;
     
    function setMultipleMaxCalls(bytes32[] _categories, uint[] _maxCalls) external;
     
    function initializeOrContinue(bytes32 _category) external returns (uint _currentFunctionStep);
     
    function getStatus(bytes32 _category) external view returns (uint _status);
     
    function updateStatus(bytes32 _category) external returns (uint _newStatus);
     
    function goNextStep(bytes32 _category) external returns (bool _shouldCallAgain);
     
    function finalize(bytes32 _category) external returns (bool _success);
}

 
contract Derivative is DerivativeInterface, ERC20Extended, ComponentContainer, PausableToken {

    ERC20Extended internal constant ETH = ERC20Extended(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
    ComponentListInterface public componentList;
    bytes32 public constant MARKET = "MarketProvider";
    bytes32 public constant PRICE = "PriceProvider";
    bytes32 public constant EXCHANGE = "ExchangeProvider";
    bytes32 public constant WITHDRAW = "WithdrawProvider";
    bytes32 public constant RISK = "RiskProvider";
    bytes32 public constant WHITELIST = "WhitelistProvider";
    bytes32 public constant FEE = "FeeProvider";
    bytes32 public constant REIMBURSABLE = "Reimbursable";
    bytes32 public constant REBALANCE = "RebalanceProvider";
    bytes32 public constant STEP = "StepProvider";
    bytes32 public constant LOCKER = "LockerProvider";

    bytes32 public constant GETETH = "GetEth";

    uint public pausedTime;
    uint public pausedCycle;

    function pause() onlyOwner whenNotPaused public {
        paused = true;
        pausedTime = now;
    }

    enum WhitelistKeys { Investment, Maintenance, Admin }

    mapping(bytes32 => bool) internal excludedComponents;

    modifier OnlyOwnerOrPausedTimeout() {
        require( (msg.sender == owner) || ( paused == true && (pausedTime+pausedCycle) <= now ) );
        _;
    }

     
    modifier onlyOwnerOrWhitelisted(WhitelistKeys _key) {
        WhitelistInterface whitelist = WhitelistInterface(getComponentByName(WHITELIST));
        require(
            msg.sender == owner ||
            (whitelist.enabled(address(this), uint(_key)) && whitelist.isAllowed(uint(_key), msg.sender) )
        );
        _;
    }

     
    modifier whitelisted(WhitelistKeys _key) {
        require(WhitelistInterface(getComponentByName(WHITELIST)).isAllowed(uint(_key), msg.sender));
        _;
    }

    modifier withoutRisk(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate) {
        require(!hasRisk(_sender, _receiver, _tokenAddress, _amount, _rate));
        _;
    }

    function _initialize (address _componentList) internal {
        require(_componentList != 0x0);
        componentList = ComponentListInterface(_componentList);
        excludedComponents[MARKET] = true;
        excludedComponents[STEP] = true;
        excludedComponents[LOCKER] = true;
    }

    function updateComponent(bytes32 _name) public onlyOwner returns (address) {
         
        if (super.getComponentByName(_name) == componentList.getLatestComponent(_name)) {
            return super.getComponentByName(_name);
        }
         
        require(super.setComponent(_name, componentList.getLatestComponent(_name)));
         
        if(!excludedComponents[_name]) {
            approveComponent(_name);
        }
        return super.getComponentByName(_name);
    }

    function approveComponent(bytes32 _name) internal {
        address componentAddress = getComponentByName(_name);
        ERC20NoReturn mot = ERC20NoReturn(FeeChargerInterface(componentAddress).MOT());
        mot.approve(componentAddress, 0);
        mot.approve(componentAddress, 2 ** 256 - 1);
    }

    function () public payable {

    }

    function hasRisk(address _sender, address _receiver, address _tokenAddress, uint _amount, uint _rate) public returns(bool) {
        RiskControlInterface riskControl = RiskControlInterface(getComponentByName(RISK));
        bool risk = riskControl.hasRisk(_sender, _receiver, _tokenAddress, _amount, _rate);
        return risk;
    }

    function setMultipleTimeIntervals(bytes32[] _timerNames, uint[] _secondsList) external onlyOwner{
        LockerInterface(getComponentByName(LOCKER)).setMultipleTimeIntervals(_timerNames,  _secondsList);
    }

    function setMaxSteps( bytes32 _category,uint _maxSteps) external onlyOwner {
        StepInterface(getComponentByName(STEP)).setMaxCalls(_category,  _maxSteps);
    }
}

contract ERC20PriceInterface {
    function getPrice() public view returns(uint);
    function getETHBalance() public view returns(uint);
}

contract IndexInterface is DerivativeInterface,  ERC20PriceInterface {

    address[] public tokens;
    uint[] public weights;
    bool public supportRebalance;


    function invest() public payable returns(bool success);

     
    function rebalance() public returns (bool success);
    function getTokens() public view returns (address[] _tokens, uint[] _weights);
    function buyTokens() external returns(bool);
}

contract ExchangeInterface is ComponentInterface {
     
    function supportsTradingPair(address _srcAddress, address _destAddress, bytes32 _exchangeId)
        external view returns(bool supported);

     
    function buyToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId
        ) external payable returns(bool success);

     
    function sellToken
        (
        ERC20Extended _token, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId
        ) external returns(bool success);
}

contract PriceProviderInterface is ComponentInterface {
     
    function getPrice(ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId)
        external view returns(uint expectedRate, uint slippageRate);

     
    function getPriceOrCacheFallback(
        ERC20Extended _sourceAddress, ERC20Extended _destAddress, uint _amount, bytes32 _exchangeId, uint _maxPriceAgeIfCache)
        external returns(uint expectedRate, uint slippageRate, bool isCached);

     
    function getMultiplePricesOrCacheFallback(ERC20Extended[] _destAddresses, uint _maxPriceAgeIfCache)
        external returns(uint[] expectedRates, uint[] slippageRates, bool[] isCached);
}

contract OlympusExchangeInterface is ExchangeInterface, PriceProviderInterface, Ownable {
     
    function buyTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId
        ) external payable returns(bool success);

     
    function sellTokens
        (
        ERC20Extended[] _tokens, uint[] _amounts, uint[] _minimumRates,
        address _depositAddress, bytes32 _exchangeId
        ) external returns(bool success);
    function tokenExchange
        (
        ERC20Extended _src, ERC20Extended _dest, uint _amount, uint _minimumRate,
        address _depositAddress, bytes32 _exchangeId
        ) external returns(bool success);
    function getFailedTrade(address _token) public view returns (uint failedTimes);
    function getFailedTradesArray(ERC20Extended[] _tokens) public view returns (uint[] memory failedTimes);
}

contract RebalanceInterface is ComponentInterface {
    function recalculateTokensToBuyAfterSale(uint _receivedETHFromSale) external
        returns(uint[] _recalculatedAmountsToBuy);
    function rebalanceGetTokensToSellAndBuy(uint _rebalanceDeltaPercentage) external returns
        (address[] _tokensToSell, uint[] _amountsToSell, address[] _tokensToBuy, uint[] _amountsToBuy, address[] _tokensWithPriceIssues);
    function finalize() public returns(bool success);
    function getRebalanceInProgress() external returns (bool inProgress);
    function needsRebalance(uint _rebalanceDeltaPercentage, address _targetAddress) external view returns (bool _needsRebalance);
    function getTotalIndexValueWithoutCache(address _indexAddress) public view returns (uint totalValue);
}

contract WithdrawInterface is ComponentInterface {

    function request(address _requester, uint amount) external returns(bool);
    function withdraw(address _requester) external returns(uint eth, uint tokens);
    function freeze() external;
     
    function isInProgress() external view returns(bool);
    function finalize() external;
    function getUserRequests() external view returns(address[]);
    function getTotalWithdrawAmount() external view returns(uint);

    event WithdrawRequest(address _requester, uint amountOfToken);
    event Withdrawed(address _requester,  uint amountOfToken , uint amountOfEther);
}

contract MarketplaceInterface is Ownable {

    address[] public products;
    mapping(address => address[]) public productMappings;

    function getAllProducts() external view returns (address[] allProducts);
    function registerProduct() external returns(bool success);
    function getOwnProducts() external view returns (address[] addresses);

    event Registered(address product, address owner);
}

contract ChargeableInterface is ComponentInterface {

    uint public DENOMINATOR;
    function calculateFee(address _caller, uint _amount) external returns(uint totalFeeAmount);
    function setFeePercentage(uint _fee) external returns (bool succes);
    function getFeePercentage() external view returns (uint feePercentage);

 }

contract ReimbursableInterface is ComponentInterface {

     
     
    function startGasCalculation() external;
     
    function reimburse() external returns (uint);

}

library Converter {
    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 x) internal pure returns (string) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(x) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }
}

contract OlympusIndex is IndexInterface, Derivative {
    using SafeMath for uint256;

    bytes32 public constant BUYTOKENS = "BuyTokens";
    enum Status { AVAILABLE, WITHDRAWING, REBALANCING, BUYING, SELLINGTOKENS }
    Status public productStatus = Status.AVAILABLE;
     

    uint public constant INITIAL_VALUE =  10**18;
    uint public constant INITIAL_FEE = 10**17;
    uint public constant TOKEN_DENOMINATOR = 10**18;  
    uint[] public weights;
    uint public accumulatedFee = 0;
    uint public rebalanceDeltaPercentage = 0;  
    uint public rebalanceReceivedETHAmountFromSale;
    uint public freezeBalance;  
    ERC20Extended[]  freezeTokens;
    enum RebalancePhases { Initial, SellTokens, BuyTokens }

    constructor (
      string _name,
      string _symbol,
      string _description,
      bytes32 _category,
      uint _decimals,
      address[] _tokens,
      uint[] _weights)
      public {
        require(0<=_decimals&&_decimals<=18);
        require(_tokens.length == _weights.length);
        uint _totalWeight;
        uint i;

        for (i = 0; i < _weights.length; i++) {
            _totalWeight = _totalWeight.add(_weights[i]);
             
            ERC20Extended(_tokens[i]).balanceOf(address(this));
            require( ERC20Extended(_tokens[i]).decimals() <= 18);
        }
        require(_totalWeight == 100);

        name = _name;
        symbol = _symbol;
        totalSupply_ = 0;
        decimals = _decimals;
        description = _description;
        category = _category;
        version = "1.1-20181002";
        fundType = DerivativeType.Index;
        tokens = _tokens;
        weights = _weights;
        status = DerivativeStatus.New;


    }

     
     
    function initialize(
        address _componentList,
        uint _initialFundFee,
        uint _rebalanceDeltaPercentage
   )
   external onlyOwner payable {
        require(status == DerivativeStatus.New);
        require(msg.value >= INITIAL_FEE);  
        require(_componentList != 0x0);
        require(_rebalanceDeltaPercentage <= (10 ** decimals));

        pausedCycle = 365 days;

        rebalanceDeltaPercentage = _rebalanceDeltaPercentage;
        super._initialize(_componentList);
        bytes32[10] memory names = [
            MARKET, EXCHANGE, REBALANCE, RISK, WHITELIST, FEE, REIMBURSABLE, WITHDRAW, LOCKER, STEP
        ];

        for (uint i = 0; i < names.length; i++) {
            updateComponent(names[i]);
        }

        MarketplaceInterface(getComponentByName(MARKET)).registerProduct();
        setManagementFee(_initialFundFee);

        uint[] memory _maxSteps = new uint[](4);
        bytes32[] memory _categories = new bytes32[](4);
        _maxSteps[0] = 3;
        _maxSteps[1] = 10;
        _maxSteps[2] = 5;
        _maxSteps[3] = 5;

        _categories[0] = REBALANCE;
        _categories[1] = WITHDRAW;
        _categories[2] = BUYTOKENS;
        _categories[3] = GETETH;

        StepInterface(getComponentByName(STEP)).setMultipleMaxCalls(_categories, _maxSteps);
        status = DerivativeStatus.Active;

         

        accumulatedFee = accumulatedFee.add(msg.value);
    }


     
     
    function getTokens() public view returns (address[] _tokens, uint[] _weights) {
        return (tokens, weights);
    }

     
    function close() OnlyOwnerOrPausedTimeout public returns(bool success) {
        require(status != DerivativeStatus.New);
        require(productStatus == Status.AVAILABLE);

        status = DerivativeStatus.Closed;
        return true;
    }

    function sellAllTokensOnClosedFund() onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) public returns (bool) {
        require(status == DerivativeStatus.Closed );
        require(productStatus == Status.AVAILABLE || productStatus == Status.SELLINGTOKENS);
        startGasCalculation();
        productStatus = Status.SELLINGTOKENS;
        bool result = getETHFromTokens(TOKEN_DENOMINATOR);
        if(result) {
            productStatus = Status.AVAILABLE;
        }
        reimburse();
        return result;
    }
     
     
    function invest() public payable
     whenNotPaused
     whitelisted(WhitelistKeys.Investment)
     withoutRisk(msg.sender, address(this), ETH, msg.value, 1)
     returns(bool) {
        require(status == DerivativeStatus.Active, "The Fund is not active");
        require(msg.value >= 10**15, "Minimum value to invest is 0.001 ETH");
          
        uint _sharePrice  = INITIAL_VALUE;

        if (totalSupply_ > 0) {
            _sharePrice = getPrice().sub((msg.value.mul(10 ** decimals)).div(totalSupply_));
        }

        uint fee =  ChargeableInterface(getComponentByName(FEE)).calculateFee(msg.sender, msg.value);
        uint _investorShare = (msg.value.sub(fee)).mul(10 ** decimals).div(_sharePrice);

        accumulatedFee = accumulatedFee.add(fee);
        balances[msg.sender] = balances[msg.sender].add(_investorShare);
        totalSupply_ = totalSupply_.add(_investorShare);

         
        emit Transfer(0x0, msg.sender, _investorShare);  
        return true;
    }

    function getPrice() public view returns(uint) {
        if (totalSupply_ == 0) {
            return INITIAL_VALUE;
        }
        uint valueETH = getAssetsValue().add(getETHBalance()).mul(10 ** decimals);
         
        return valueETH.div(totalSupply_);

    }

    function getETHBalance() public view returns(uint) {
        return address(this).balance.sub(accumulatedFee);
    }

    function getAssetsValue() public view returns (uint) {
         
        OlympusExchangeInterface exchangeProvider = OlympusExchangeInterface(getComponentByName(EXCHANGE));
        uint _totalTokensValue = 0;
         
        uint _expectedRate;
        uint _balance;
        uint _decimals;
        ERC20Extended token;

        for (uint i = 0; i < tokens.length; i++) {
            token = ERC20Extended(tokens[i]);
            _decimals = token.decimals();
            _balance = token.balanceOf(address(this));

            if (_balance == 0) {continue;}
            (_expectedRate, ) = exchangeProvider.getPrice(token, ETH, 10**_decimals, 0x0);
            if (_expectedRate == 0) {continue;}
            _totalTokensValue = _totalTokensValue.add(_balance.mul(_expectedRate).div(10**_decimals));
        }
        return _totalTokensValue;
    }

     
     
     
    function addOwnerBalance() external payable {
        accumulatedFee = accumulatedFee.add(msg.value);
    }

   
    function withdrawFee(uint _amount) external onlyOwner whenNotPaused returns(bool) {
        require(_amount > 0 );
        require((
            status == DerivativeStatus.Closed && getAssetsValue() == 0 && getWithdrawAmount() == 0 ) ?  
            (_amount <= accumulatedFee)
            :
            (_amount.add(INITIAL_FEE) <= accumulatedFee)  
        );
        accumulatedFee = accumulatedFee.sub(_amount);
         
        OlympusExchangeInterface exchange = OlympusExchangeInterface(getComponentByName(EXCHANGE));
        ERC20Extended MOT = ERC20Extended(FeeChargerInterface(address(exchange)).MOT());
        uint _rate;
        (, _rate ) = exchange.getPrice(ETH, MOT, _amount, 0x0);
        exchange.buyToken.value(_amount)(MOT, _amount, _rate, owner, 0x0);
        return true;
    }

     
    function setManagementFee(uint _fee) public onlyOwner {
        ChargeableInterface(getComponentByName(FEE)).setFeePercentage(_fee);
    }

     
     
    function requestWithdraw(uint amount) external
      whenNotPaused
      withoutRisk(msg.sender, address(this), address(this), amount, getPrice())
    {
        WithdrawInterface withdrawProvider = WithdrawInterface(getComponentByName(WITHDRAW));
        withdrawProvider.request(msg.sender, amount);
        if(status == DerivativeStatus.Closed && getAssetsValue() == 0 && getWithdrawAmount() == amount) {
            withdrawProvider.freeze();
            handleWithdraw(withdrawProvider, msg.sender);
            withdrawProvider.finalize();
            return;
        }
     }

    function guaranteeLiquidity(uint tokenBalance) internal returns(bool success){

        if(getStatusStep(GETETH) == 0) {
            uint _totalETHToReturn = tokenBalance.mul(getPrice()).div(10**decimals);
            if (_totalETHToReturn <= getETHBalance()) {
                return true;
            }

             
             
            freezeBalance = _totalETHToReturn.sub(getETHBalance()).mul(TOKEN_DENOMINATOR).div(getAssetsValue());
        }
        return getETHFromTokens(freezeBalance);
    }

     
    function withdraw() external onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) whenNotPaused returns(bool) {
        startGasCalculation();

        require(productStatus == Status.AVAILABLE || productStatus == Status.WITHDRAWING);
        productStatus = Status.WITHDRAWING;

        WithdrawInterface withdrawProvider = WithdrawInterface(getComponentByName(WITHDRAW));

         
        address[] memory _requests = withdrawProvider.getUserRequests();
        uint _withdrawStatus = getStatusStep(WITHDRAW);



        if (_withdrawStatus == 0 && getStatusStep(GETETH) == 0) {
            checkLocker(WITHDRAW);
            if (_requests.length == 0) {
                productStatus = Status.AVAILABLE;
                reimburse();
                return true;
            }
        }

        if (_withdrawStatus == 0) {
            if(!guaranteeLiquidity(getWithdrawAmount())) {
                reimburse();
                return false;
            }
            withdrawProvider.freeze();
        }

        uint _transfers = initializeOrContinueStep(WITHDRAW);
        uint i;

        for (i = _transfers; i < _requests.length && goNextStep(WITHDRAW); i++) {
            if(!handleWithdraw(withdrawProvider, _requests[i])){ continue; }
        }

        if (i == _requests.length) {
            withdrawProvider.finalize();
            finalizeStep(WITHDRAW);
            productStatus = Status.AVAILABLE;
        }
        reimburse();
        return i == _requests.length;  
    }

    function handleWithdraw(WithdrawInterface _withdrawProvider, address _investor) private returns (bool) {
        uint _eth;
        uint _tokenAmount;

        (_eth, _tokenAmount) = _withdrawProvider.withdraw(_investor);
        if (_tokenAmount == 0) {return false;}

        balances[_investor] =  balances[_investor].sub(_tokenAmount);
        emit Transfer(_investor, 0x0, _tokenAmount);  

        totalSupply_ = totalSupply_.sub(_tokenAmount);
        address(_investor).transfer(_eth);

        return true;
    }

    function checkLocker(bytes32 category) internal {
        LockerInterface(getComponentByName(LOCKER)).checkLockerByTime(category);
    }

    function startGasCalculation() internal {
        ReimbursableInterface(getComponentByName(REIMBURSABLE)).startGasCalculation();
    }

     
    function reimburse() private {
        uint reimbursedAmount = ReimbursableInterface(getComponentByName(REIMBURSABLE)).reimburse();
        accumulatedFee = accumulatedFee.sub(reimbursedAmount);
         
        msg.sender.transfer(reimbursedAmount);
    }

     
    function tokensWithAmount() public view returns( ERC20Extended[] memory) {
         
        uint length = 0;
        uint[] memory _amounts = new uint[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            _amounts[i] = ERC20Extended(tokens[i]).balanceOf(address(this));
            if (_amounts[i] > 0) {length++;}
        }

        ERC20Extended[] memory _tokensWithAmount = new ERC20Extended[](length);
         
        uint index = 0;
        for (uint j = 0; j < tokens.length; j++) {
            if (_amounts[j] > 0) {
                _tokensWithAmount[index] = ERC20Extended(tokens[j]);
                index++;
            }
        }
        return _tokensWithAmount;
    }

     
    function getETHFromTokens(uint _tokenPercentage) internal returns(bool success) {
        OlympusExchangeInterface exchange = OlympusExchangeInterface(getComponentByName(EXCHANGE));

        uint currentStep = initializeOrContinueStep(GETETH);
        uint i;  
        uint arrayLength = getNextArrayLength(GETETH, currentStep);
        if(currentStep == 0) {
            freezeTokens = tokensWithAmount();
        }

        ERC20Extended[] memory _tokensThisStep = new ERC20Extended[](arrayLength);
        uint[] memory _amounts = new uint[](arrayLength);
        uint[] memory _sellRates = new uint[](arrayLength);

        for(i = currentStep;i < freezeTokens.length && goNextStep(GETETH); i++){
            uint sellIndex = i.sub(currentStep);
            _tokensThisStep[sellIndex] = freezeTokens[i];
            _amounts[sellIndex] = _tokenPercentage.mul(freezeTokens[i].balanceOf(address(this))).div(TOKEN_DENOMINATOR);
            (, _sellRates[sellIndex] ) = exchange.getPrice(freezeTokens[i], ETH, _amounts[sellIndex], 0x0);
             
            approveExchange(address(_tokensThisStep[sellIndex]), _amounts[sellIndex]);
        }
        require(exchange.sellTokens(_tokensThisStep, _amounts, _sellRates, address(this), 0x0));

        if(i == freezeTokens.length) {
            finalizeStep(GETETH);
            return true;
        }
        return false;
    }

     
     
    function buyTokens() external onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) whenNotPaused returns(bool) {
        startGasCalculation();

        require(productStatus == Status.AVAILABLE || productStatus == Status.BUYING);
        productStatus = Status.BUYING;

        OlympusExchangeInterface exchange = OlympusExchangeInterface(getComponentByName(EXCHANGE));

         
        if (getStatusStep(BUYTOKENS) == 0) {
            checkLocker(BUYTOKENS);
            if (tokens.length == 0 || getETHBalance() == 0) {
                productStatus = Status.AVAILABLE;
                reimburse();
                return true;
            }
            freezeBalance = getETHBalance();
        }
        uint currentStep = initializeOrContinueStep(BUYTOKENS);

         
        uint arrayLength = getNextArrayLength(BUYTOKENS, currentStep);

        uint[] memory _amounts = new uint[](arrayLength);
         
        uint[] memory _rates = new uint[](arrayLength);
         
        ERC20Extended[] memory _tokensErc20 = new ERC20Extended[](arrayLength);
        uint _totalAmount = 0;
        uint i;  
        uint _buyIndex;  
        for (i = currentStep; i < tokens.length && goNextStep(BUYTOKENS); i++) {
            _buyIndex = i - currentStep;
            _amounts[_buyIndex] = freezeBalance.mul(weights[i]).div(100);
            _tokensErc20[_buyIndex] = ERC20Extended(tokens[i]);
            (, _rates[_buyIndex] ) = exchange.getPrice(ETH, _tokensErc20[_buyIndex], _amounts[_buyIndex], 0x0);
            _totalAmount = _totalAmount.add(_amounts[_buyIndex]);
        }

        require(exchange.buyTokens.value(_totalAmount)(_tokensErc20, _amounts, _rates, address(this), 0x0));

        if(i == tokens.length) {
            finalizeStep(BUYTOKENS);
            freezeBalance = 0;
            productStatus = Status.AVAILABLE;
            reimburse();
            return true;
        }
        reimburse();
        return false;
    }

     
    function rebalance() public onlyOwnerOrWhitelisted(WhitelistKeys.Maintenance) whenNotPaused returns (bool success) {
        startGasCalculation();

        require(productStatus == Status.AVAILABLE || productStatus == Status.REBALANCING);

        RebalanceInterface rebalanceProvider = RebalanceInterface(getComponentByName(REBALANCE));
        OlympusExchangeInterface exchangeProvider = OlympusExchangeInterface(getComponentByName(EXCHANGE));
        if (!rebalanceProvider.getRebalanceInProgress()) {
            checkLocker(REBALANCE);
        }

        address[] memory _tokensToSell;
        uint[] memory _amounts;
        address[] memory _tokensToBuy;
        uint i;

        (_tokensToSell, _amounts, _tokensToBuy,,) = rebalanceProvider.rebalanceGetTokensToSellAndBuy(rebalanceDeltaPercentage);
        if(_tokensToSell.length == 0) {
            reimburse();  
            return true;
        }
         
        uint ETHBalanceBefore = getETHBalance();

        uint currentStep = initializeOrContinueStep(REBALANCE);
        uint stepStatus = getStatusStep(REBALANCE);
         

        productStatus = Status.REBALANCING;

         
        if ( stepStatus == uint(RebalancePhases.SellTokens)) {
            for (i = currentStep; i < _tokensToSell.length && goNextStep(REBALANCE) ; i++) {
                approveExchange(_tokensToSell[i], _amounts[i]);
                 

                require(exchangeProvider.sellToken(ERC20Extended(_tokensToSell[i]), _amounts[i], 0, address(this), 0x0));
            }

            rebalanceReceivedETHAmountFromSale = rebalanceReceivedETHAmountFromSale.add(getETHBalance()).sub(ETHBalanceBefore) ;
            if (i ==  _tokensToSell.length) {
                updateStatusStep(REBALANCE);
                currentStep = 0;
            }
        }
         
        if (stepStatus == uint(RebalancePhases.BuyTokens)) {
            _amounts = rebalanceProvider.recalculateTokensToBuyAfterSale(rebalanceReceivedETHAmountFromSale);
            for (i = currentStep; i < _tokensToBuy.length && goNextStep(REBALANCE); i++) {
                require(
                     
                    exchangeProvider.buyToken.value(_amounts[i])(ERC20Extended(_tokensToBuy[i]), _amounts[i], 0, address(this), 0x0)
                );
            }

            if(i == _tokensToBuy.length) {
                finalizeStep(REBALANCE);
                rebalanceProvider.finalize();
                rebalanceReceivedETHAmountFromSale = 0;
                productStatus = Status.AVAILABLE;
                reimburse();    
                return true;
            }
        }
        reimburse();  
        return false;
    }
     
    function initializeOrContinueStep(bytes32 category) internal returns(uint) {
        return  StepInterface(getComponentByName(STEP)).initializeOrContinue(category);
    }

    function getStatusStep(bytes32 category) internal view returns(uint) {
        return  StepInterface(getComponentByName(STEP)).getStatus(category);
    }

    function finalizeStep(bytes32 category) internal returns(bool) {
        return  StepInterface(getComponentByName(STEP)).finalize(category);
    }

    function goNextStep(bytes32 category) internal returns(bool) {
        return StepInterface(getComponentByName(STEP)).goNextStep(category);
    }

    function updateStatusStep(bytes32 category) internal returns(uint) {
        return StepInterface(getComponentByName(STEP)).updateStatus(category);
    }

    function getWithdrawAmount() internal view returns(uint) {
        return WithdrawInterface(getComponentByName(WITHDRAW)).getTotalWithdrawAmount();
    }

    function getNextArrayLength(bytes32 stepCategory, uint currentStep) internal view returns(uint) {
        uint arrayLength = StepInterface(getComponentByName(STEP)).getMaxCalls(stepCategory);
        if(arrayLength.add(currentStep) >= tokens.length ) {
            arrayLength = tokens.length.sub(currentStep);
        }
        return arrayLength;
    }

    function approveExchange(address _token, uint amount) internal {
        OlympusExchangeInterface exchange = OlympusExchangeInterface(getComponentByName(EXCHANGE));
        ERC20NoReturn(_token).approve(exchange, 0);
        ERC20NoReturn(_token).approve(exchange, amount);
    }

     
     
    function enableWhitelist(WhitelistKeys _key, bool enable) external onlyOwner returns(bool) {
        WhitelistInterface(getComponentByName(WHITELIST)).setStatus(uint(_key), enable);
        return true;
    }

     
    function setAllowed(address[] accounts, WhitelistKeys _key, bool allowed) public onlyOwner returns(bool) {
        WhitelistInterface(getComponentByName(WHITELIST)).setAllowed(accounts, uint(_key), allowed);
        return true;
    }
}