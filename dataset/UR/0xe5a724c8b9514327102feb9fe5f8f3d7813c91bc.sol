 

pragma solidity ^0.4.23;

 

 
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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

 
contract Administrable is Ownable {

    event LogAdministratorAdded(address indexed caller, address indexed administrator);
    event LogAdministratorRemoved(address indexed caller, address indexed administrator);

    mapping (address => bool) private administrators;

    modifier onlyAdministrator() {
        require(administrators[msg.sender], "caller is not administrator");
        _;
    }

    constructor() internal {
        administrators[msg.sender] = true;

        emit LogAdministratorAdded(msg.sender, msg.sender);
    }

     
    function addAdministrator(address newAdministrator) public onlyOwner {
        require(newAdministrator != address(0), "newAdministrator is zero");
        require(!administrators[newAdministrator], "newAdministrator is already present");

        administrators[newAdministrator] = true;

        emit LogAdministratorAdded(msg.sender, newAdministrator);
    }

     
    function removeAdministrator(address oldAdministrator) public onlyOwner {
        require(oldAdministrator != address(0), "oldAdministrator is zero");
        require(administrators[oldAdministrator], "oldAdministrator is not present");

        administrators[oldAdministrator] = false;

        emit LogAdministratorRemoved(msg.sender, oldAdministrator);
    }

     
    function isAdministrator(address target) public view returns(bool isReallyAdministrator) {
        return administrators[target];
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        administrators[msg.sender] = false;
        emit LogAdministratorRemoved(msg.sender, msg.sender);

        administrators[newOwner] = true;
        emit LogAdministratorAdded(msg.sender, newOwner);

        Ownable.transferOwnership(newOwner);
    }
}

 

contract TokenSale {
     
    function buyTokens(address beneficiary) public payable;
}

 

 
contract WhitelistableConstraints {

     
    function isAllowedWhitelist(uint256 _maxWhitelistLength, uint256 _weiWhitelistThresholdBalance)
        public pure returns(bool isReallyAllowedWhitelist) {
        return _maxWhitelistLength > 0 || _weiWhitelistThresholdBalance > 0;
    }
}

 

 
contract Whitelistable is WhitelistableConstraints {

    event LogMaxWhitelistLengthChanged(address indexed caller, uint256 indexed maxWhitelistLength);
    event LogWhitelistThresholdBalanceChanged(address indexed caller, uint256 indexed whitelistThresholdBalance);
    event LogWhitelistAddressAdded(address indexed caller, address indexed subscriber);
    event LogWhitelistAddressRemoved(address indexed caller, address indexed subscriber);

    mapping (address => bool) public whitelist;

    uint256 public whitelistLength;

    uint256 public maxWhitelistLength;

    uint256 public whitelistThresholdBalance;

    constructor(uint256 _maxWhitelistLength, uint256 _whitelistThresholdBalance) internal {
        require(isAllowedWhitelist(_maxWhitelistLength, _whitelistThresholdBalance), "parameters not allowed");

        maxWhitelistLength = _maxWhitelistLength;
        whitelistThresholdBalance = _whitelistThresholdBalance;
    }

     
    function isWhitelistEnabled() public view returns(bool isReallyWhitelistEnabled) {
        return maxWhitelistLength > 0;
    }

     
    function isWhitelisted(address _subscriber) public view returns(bool isReallyWhitelisted) {
        return whitelist[_subscriber];
    }

    function setMaxWhitelistLengthInternal(uint256 _maxWhitelistLength) internal {
        require(isAllowedWhitelist(_maxWhitelistLength, whitelistThresholdBalance),
            "_maxWhitelistLength not allowed");
        require(_maxWhitelistLength != maxWhitelistLength, "_maxWhitelistLength equal to current one");

        maxWhitelistLength = _maxWhitelistLength;

        emit LogMaxWhitelistLengthChanged(msg.sender, maxWhitelistLength);
    }

    function setWhitelistThresholdBalanceInternal(uint256 _whitelistThresholdBalance) internal {
        require(isAllowedWhitelist(maxWhitelistLength, _whitelistThresholdBalance),
            "_whitelistThresholdBalance not allowed");
        require(whitelistLength == 0 || _whitelistThresholdBalance > whitelistThresholdBalance,
            "_whitelistThresholdBalance not greater than current one");

        whitelistThresholdBalance = _whitelistThresholdBalance;

        emit LogWhitelistThresholdBalanceChanged(msg.sender, _whitelistThresholdBalance);
    }

    function addToWhitelistInternal(address _subscriber) internal {
        require(_subscriber != address(0), "_subscriber is zero");
        require(!whitelist[_subscriber], "already whitelisted");
        require(whitelistLength < maxWhitelistLength, "max whitelist length reached");

        whitelistLength++;

        whitelist[_subscriber] = true;

        emit LogWhitelistAddressAdded(msg.sender, _subscriber);
    }

    function removeFromWhitelistInternal(address _subscriber, uint256 _balance) internal {
        require(_subscriber != address(0), "_subscriber is zero");
        require(whitelist[_subscriber], "not whitelisted");
        require(_balance <= whitelistThresholdBalance, "_balance greater than whitelist threshold");

        assert(whitelistLength > 0);

        whitelistLength--;

        whitelist[_subscriber] = false;

        emit LogWhitelistAddressRemoved(msg.sender, _subscriber);
    }

     
    function isAllowedBalance(address _subscriber, uint256 _balance) public view returns(bool isReallyAllowed) {
        return !isWhitelistEnabled() || _balance <= whitelistThresholdBalance || whitelist[_subscriber];
    }
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

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract MultipleBidReservation is Administrable, Whitelistable {
    using SafeMath for uint256;

    event LogMultipleBidReservationCreated(
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        uint256 maxSubscribers,
        uint256 maxCap,
        uint256 minDeposit,
        uint256 maxWhitelistLength,
        uint256 indexed whitelistThreshold
    );
    event LogStartBlockChanged(uint256 indexed startBlock);
    event LogEndBlockChanged(uint256 indexed endBlock);
    event LogMaxCapChanged(uint256 indexed maxCap);
    event LogMinDepositChanged(uint256 indexed minDeposit);
    event LogMaxSubscribersChanged(uint256 indexed maxSubscribers);
    event LogCrowdsaleAddressChanged(address indexed crowdsale);
    event LogAbort(address indexed caller);
    event LogDeposit(
        address indexed subscriber,
        uint256 indexed amount,
        uint256 indexed balance,
        uint256 raisedFunds
    );
    event LogBuy(address caller, uint256 indexed from, uint256 indexed to);
    event LogRefund(address indexed subscriber, uint256 indexed amount, uint256 indexed raisedFunds);

     
    uint256 public startBlock;
    uint256 public endBlock;

     
    uint256 public maxCap;

     
    uint256 public minDeposit;

     
    uint256 public maxSubscribers;

     
    TokenSale public crowdsale;

     
    uint256 public raisedFunds;

     
    ERC20 public token;

     
    mapping (address => uint256) public balances;

     
    address[] public subscribers;

     
    bool public aborted;

     
    uint256 constant public MAX_WHITELIST_THRESHOLD = 2**256 - 1;

    modifier beforeStart() {
        require(block.number < startBlock, "already started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "already ended");
        _;
    }

    modifier whenReserving() {
        require(!aborted, "aborted");
        _;
    }

    modifier whenAborted() {
        require(aborted, "not aborted");
        _;
    }

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxSubscribers,
        uint256 _maxCap,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold
    )
    Whitelistable(_maxWhitelistLength, _whitelistThreshold) public
    {
        require(_startBlock >= block.number, "_startBlock < current block");
        require(_endBlock >= _startBlock, "_endBlock < _startBlock");
        require(_maxSubscribers > 0, "_maxSubscribers is 0");
        require(_maxCap > 0, "_maxCap is 0");
        require(_minDeposit > 0, "_minDeposit is 0");

        startBlock = _startBlock;
        endBlock = _endBlock;
        maxSubscribers = _maxSubscribers;
        maxCap = _maxCap;
        minDeposit = _minDeposit;

        emit LogMultipleBidReservationCreated(
            startBlock,
            endBlock,
            maxSubscribers,
            maxCap,
            minDeposit,
            _maxWhitelistLength,
            _whitelistThreshold
        );
    }

    function hasStarted() public view returns(bool started) {
        return block.number >= startBlock;
    }

    function hasEnded() public view returns(bool ended) {
        return block.number > endBlock;
    }

     
    function numSubscribers() public view returns(uint256 numberOfSubscribers) {
        return subscribers.length;
    }

     
    function setStartBlock(uint256 _startBlock) external onlyOwner beforeStart whenReserving {
        require(_startBlock >= block.number, "_startBlock < current block");
        require(_startBlock <= endBlock, "_startBlock > endBlock");
        require(_startBlock != startBlock, "_startBlock == startBlock");

        startBlock = _startBlock;

        emit LogStartBlockChanged(_startBlock);
    }

     
    function setEndBlock(uint256 _endBlock) external onlyOwner beforeEnd whenReserving {
        require(_endBlock >= block.number, "_endBlock < current block");
        require(_endBlock >= startBlock, "_endBlock < startBlock");
        require(_endBlock != endBlock, "_endBlock == endBlock");

        endBlock = _endBlock;

        emit LogEndBlockChanged(_endBlock);
    }

     
    function setMaxCap(uint256 _maxCap) external onlyOwner beforeEnd whenReserving {
        require(_maxCap > 0 && _maxCap >= raisedFunds, "invalid _maxCap");

        maxCap = _maxCap;

        emit LogMaxCapChanged(maxCap);
    }

     
    function setMinDeposit(uint256 _minDeposit) external onlyOwner beforeEnd whenReserving {
        require(_minDeposit > 0 && _minDeposit < minDeposit, "_minDeposit not in (0, minDeposit)");

        minDeposit = _minDeposit;

        emit LogMinDepositChanged(minDeposit);
    }

     
    function setMaxSubscribers(uint256 _maxSubscribers) external onlyOwner beforeEnd whenReserving {
        require(_maxSubscribers > 0 && _maxSubscribers >= subscribers.length, "invalid _maxSubscribers");

        maxSubscribers = _maxSubscribers;

        emit LogMaxSubscribersChanged(maxSubscribers);
    }

     
    function setCrowdsaleAddress(address _crowdsale) external onlyOwner whenReserving {
        require(_crowdsale != address(0), "_crowdsale is 0");

        crowdsale = TokenSale(_crowdsale);

        emit LogCrowdsaleAddressChanged(_crowdsale);
    }

     
    function setMaxWhitelistLength(uint256 _maxWhitelistLength) external onlyOwner beforeEnd whenReserving {
        setMaxWhitelistLengthInternal(_maxWhitelistLength);
    }

     
    function setWhitelistThresholdBalance(uint256 _whitelistThreshold) external onlyOwner beforeEnd whenReserving {
        setWhitelistThresholdBalanceInternal(_whitelistThreshold);
    }

     
    function addToWhitelist(address _subscriber) external onlyOwner beforeEnd whenReserving {
        addToWhitelistInternal(_subscriber);
    }

     
    function removeFromWhitelist(address _subscriber) external onlyOwner beforeEnd whenReserving {
        removeFromWhitelistInternal(_subscriber, balances[_subscriber]);
    }

     
    function abort() external onlyAdministrator whenReserving {
        aborted = true;

        emit LogAbort(msg.sender);
    }

     
    function invest() external payable whenReserving {
        deposit(msg.sender, msg.value);
    }

     
    function buy(uint256 _from, uint256 _to) external onlyAdministrator whenReserving {
        require(_from < _to, "_from >= _to");
        require(crowdsale != address(0), "crowdsale not set");
        require(subscribers.length > 0, "subscribers size is 0");
        require(hasEnded(), "not ended");

        uint to = _to > subscribers.length ? subscribers.length : _to;

        for (uint256 i=_from; i<to; i++) {
            address subscriber = subscribers[i];

            uint256 subscriberBalance = balances[subscriber];

            if (subscriberBalance > 0) {
                balances[subscriber] = 0;

                crowdsale.buyTokens.value(subscriberBalance)(subscriber);
            }
        }

        emit LogBuy(msg.sender, _from, _to);
    }

     
    function refund() external whenAborted {
         
        uint256 subscriberBalance = balances[msg.sender];

         
        require(subscriberBalance > 0, "caller balance is 0");

         
        require(raisedFunds > 0, "token balance is 0");

         
        raisedFunds = raisedFunds.sub(subscriberBalance);

         
        balances[msg.sender] = 0;

        emit LogRefund(msg.sender, subscriberBalance, raisedFunds);

         
        msg.sender.transfer(subscriberBalance);
    }

     
    function () external payable whenReserving {
        deposit(msg.sender, msg.value);
    }

     
    function deposit(address beneficiary, uint256 amount) internal {
         
        require(startBlock <= block.number && block.number <= endBlock, "not open");

        uint256 newRaisedFunds = raisedFunds.add(amount);

         
        require(newRaisedFunds <= maxCap, "over max cap");

        uint256 currentBalance = balances[beneficiary];
        uint256 finalBalance = currentBalance.add(amount);

         
        require(finalBalance >= minDeposit, "deposit < min deposit");

         
        require(isAllowedBalance(beneficiary, finalBalance), "balance not allowed");

         
        if (currentBalance == 0) {
             
            require(subscribers.length < maxSubscribers, "max subscribers reached");

            subscribers.push(beneficiary);
        }

         
        balances[beneficiary] = finalBalance;

        raisedFunds = newRaisedFunds;

        emit LogDeposit(beneficiary, amount, finalBalance, newRaisedFunds);
    }
}

 

 
contract NokuCustomReservation is MultipleBidReservation {
    event LogNokuCustomReservationCreated();

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxSubscribers,
        uint256 _maxCap,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold
    )
    MultipleBidReservation(
        _startBlock,
        _endBlock,
        _maxSubscribers,
        _maxCap,
        _minDeposit,
        _maxWhitelistLength,
        _whitelistThreshold
    )
    public {
        emit LogNokuCustomReservationCreated();
    }
}

 

 
contract NokuPricingPlan {
     
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

     
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
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

 

contract NokuCustomService is Pausable {
    using AddressUtils for address;

    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

     
    NokuPricingPlan public pricingPlan;

    constructor(address _pricingPlan) internal {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");

        pricingPlan = NokuPricingPlan(_pricingPlan);
    }

    function setPricingPlan(address _pricingPlan) public onlyOwner {
        require(_pricingPlan.isContract(), "_pricingPlan is not contract");
        require(NokuPricingPlan(_pricingPlan) != pricingPlan, "_pricingPlan equal to current");
        
        pricingPlan = NokuPricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

 

 
contract NokuCustomReservationService is NokuCustomService {
    event LogNokuCustomReservationServiceCreated(address indexed caller);

    bytes32 public constant SERVICE_NAME = "NokuCustomERC20.reservation";
    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomReservationServiceCreated(msg.sender);
    }

    function createCustomReservation(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _maxSubscribers,
        uint256 _maxCap,
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold
    )
    public returns(NokuCustomReservation customReservation)
    {
        customReservation = new NokuCustomReservation(
            _startBlock,
            _endBlock,
            _maxSubscribers,
            _maxCap,
            _minDeposit,
            _maxWhitelistLength,
            _whitelistThreshold
        );

         
        customReservation.transferOwnership(msg.sender);

        require(pricingPlan.payFee(SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}