 

pragma solidity ^0.4.17;
 
contract ERC20 {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  function Ownable() {
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
contract Controlled {
     
     
    modifier onlyController { require(msg.sender == controller); _; }
    address public controller;
    function Controlled() public { controller = msg.sender;}
     
     
    function changeController(address _newController) public onlyController {
        controller = _newController;
    }
}
 
contract ERC20MiniMe is ERC20, Controlled {
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) public returns (bool);
    function totalSupply() public view returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint);
    function totalSupplyAt(uint _blockNumber) public view returns(uint);
    function createCloneToken(string _cloneTokenName, uint8 _cloneDecimalUnits, string _cloneTokenSymbol, uint _snapshotBlock, bool _transfersEnabled) public returns(address);
    function generateTokens(address _owner, uint _amount) public returns (bool);
    function destroyTokens(address _owner, uint _amount)  public returns (bool);
    function enableTransfers(bool _transfersEnabled) public;
    function isContract(address _addr) internal view returns(bool);
    function claimTokens(address _token) public;
    event ClaimedTokens(address indexed _token, address indexed _controller, uint _amount);
    event NewCloneToken(address indexed _cloneToken, uint _snapshotBlock);
}
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Crowdsale {
  using SafeMath for uint256;
   
  ERC20MiniMe public token;
   
  uint256 public startTime;
  uint256 public endTime;
   
  address public wallet;
   
  uint256 public rate;
   
  uint256 public weiRaised;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }
   
  function () payable {
    buyTokens(msg.sender);
  }
   
  function buyTokens(address beneficiary) public payable {
    buyTokens(beneficiary, msg.value);
  }
   
  function buyTokens(address beneficiary, uint256 weiAmount) internal {
    require(beneficiary != 0x0);
    require(validPurchase(weiAmount));
     
    weiRaised = weiRaised.add(weiAmount);
    transferToken(beneficiary, weiAmount);
    forwardFunds(weiAmount);
  }
   
   
  function transferToken(address beneficiary, uint256 weiAmount) internal {
     
    uint256 tokens = weiAmount.mul(rate);
    token.generateTokens(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
   
   
  function forwardFunds(uint256 weiAmount) internal {
    wallet.transfer(weiAmount);
  }
   
  function validPurchase(uint256 weiAmount) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = weiAmount != 0;
    return withinPeriod && nonZeroPurchase;
  }
   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
   
  function hasStarted() public view returns (bool) {
    return now >= startTime;
  }
}
 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }
   
   
  function validPurchase(uint256 weiAmount) internal view returns (bool) {
    return super.validPurchase(weiAmount) && !capReached();
  }
   
   
  function hasEnded() public view returns (bool) {
    return super.hasEnded() || capReached();
  }
   
  function capReached() internal view returns (bool) {
   return weiRaised >= cap;
  }
   
  function buyTokens(address beneficiary) public payable {
     uint256 weiToCap = cap.sub(weiRaised);
     uint256 weiAmount = weiToCap < msg.value ? weiToCap : msg.value;
     buyTokens(beneficiary, weiAmount);
     uint256 refund = msg.value.sub(weiAmount);
     if (refund > 0) {
       msg.sender.transfer(refund);
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
 
contract HasNoTokens is Ownable {
    event ExtractedTokens(address indexed _token, address indexed _claimer, uint _amount);
     
     
     
     
     
    function extractTokens(address _token, address _claimer) onlyOwner public {
        if (_token == 0x0) {
            _claimer.transfer(this.balance);
            return;
        }
        ERC20 token = ERC20(_token);
        uint balance = token.balanceOf(this);
        token.transfer(_claimer, balance);
        ExtractedTokens(_token, _claimer, balance);
    }
}
 
contract RefundVault is Ownable, HasNoTokens {
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
  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }
   
   
   
   
  function forwardFunds(uint256 weiAmount) internal {
    if (goalReached())
      wallet.transfer(weiAmount);
    else
      vault.deposit.value(weiAmount)(msg.sender);
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
  function goalReached() public view returns (bool) {
    return weiRaised >= goal;
  }
}
 
contract TokenController {
    ERC20MiniMe public ethealToken;
    address public SALE;  
     
    function addHodlerStake(address _beneficiary, uint _stake) public;
    function setHodlerStake(address _beneficiary, uint256 _stake) public;
    function setHodlerTime(uint256 _time) public;
     
     
     
    function proxyPayment(address _owner) public payable returns(bool);
     
     
     
     
     
     
    function onTransfer(address _from, address _to, uint _amount) public returns(bool);
     
     
     
     
     
     
    function onApprove(address _owner, address _spender, uint _amount) public returns(bool);
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
 
contract EthealPreSale is Pausable, CappedCrowdsale, RefundableCrowdsale {
     
    TokenController public ethealController;
     
     
    uint256 public rate = 1250;
    uint256 public goal = 333 ether;
    uint256 public softCap = 3600 ether;
    uint256 public softCapTime = 120 hours;
    uint256 public softCapClose;
    uint256 public cap = 7200 ether;
     
    uint256 public tokenBalance;
     
    uint256 public tokenSold;
     
     
     
    uint256 public maxGasPrice = 100 * 10**9;
    uint256 public maxGasPricePenalty = 80;
     
    uint256 public minContribution = 0.1 ether;
     
     
     
    uint8 public whitelistDayCount;
    mapping (address => bool) public whitelist;
    mapping (uint8 => uint256) public whitelistDayMaxStake;
    
     
     
    mapping (address => uint256) public stakes;
     
    address[] public contributorsKeys; 
     
    event TokenClaimed(address indexed _claimer, address indexed _beneficiary, uint256 _stake, uint256 _amount);
    event TokenPurchase(address indexed _purchaser, address indexed _beneficiary, uint256 _value, uint256 _stake, uint256 _amount, uint256 _participants, uint256 _weiRaised);
    event TokenGoalReached();
    event TokenSoftCapReached(uint256 _closeTime);
     
    event WhitelistAddressAdded(address indexed _whitelister, address indexed _beneficiary);
    event WhitelistAddressRemoved(address indexed _whitelister, address indexed _beneficiary);
    event WhitelistSetDay(address indexed _whitelister, uint8 _day, uint256 _maxStake);
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function EthealPreSale(
        address _ethealController,
        uint256 _startTime, 
        uint256 _endTime, 
        uint256 _minContribution, 
        uint256 _rate, 
        uint256 _goal, 
        uint256 _softCap, 
        uint256 _softCapTime, 
        uint256 _cap, 
        uint256 _gasPrice, 
        uint256 _gasPenalty, 
        address _wallet
    )
        CappedCrowdsale(_cap)
        FinalizableCrowdsale()
        RefundableCrowdsale(_goal)
        Crowdsale(_startTime, _endTime, _rate, _wallet)
    {
         
        require(_ethealController != address(0));
        ethealController = TokenController(_ethealController);
         
        require(_goal <= _softCap && _softCap <= _cap);
        softCap = _softCap;
        softCapTime = _softCapTime;
         
        cap = _cap;
        goal = _goal;
        rate = _rate;
        maxGasPrice = _gasPrice;
        maxGasPricePenalty = _gasPenalty;
        minContribution = _minContribution;
    }
     
     
    function buyTokens(address _beneficiary) public payable whenNotPaused {
        require(_beneficiary != address(0));
        uint256 weiToCap = howMuchCanXContributeNow(_beneficiary);
        uint256 weiAmount = uint256Min(weiToCap, msg.value);
         
        if (weiRaised < goal && weiRaised.add(weiAmount) >= goal) {
            TokenGoalReached();
        }
         
        buyTokens(_beneficiary, weiAmount);
         
        if (weiRaised >= softCap && softCapClose == 0) {
            softCapClose = now.add(softCapTime);
            TokenSoftCapReached(uint256Min(softCapClose, endTime));
        }
         
        uint256 refund = msg.value.sub(weiAmount);
        if (refund > 0) {
            msg.sender.transfer(refund);
        }
    }
     
     
     
    function transferToken(address _beneficiary, uint256 _weiAmount) internal {
        require(_beneficiary != address(0));
        uint256 weiAmount = _weiAmount;
         
        if (maxGasPrice > 0 && tx.gasprice > maxGasPrice) {
            weiAmount = weiAmount.mul(maxGasPricePenalty).div(100);
        }
         
        uint256 tokens = weiAmount.mul(rate);
        tokenBalance = tokenBalance.add(tokens);
        if (stakes[_beneficiary] == 0) {
            contributorsKeys.push(_beneficiary);
        }
        stakes[_beneficiary] = stakes[_beneficiary].add(weiAmount);
        TokenPurchase(msg.sender, _beneficiary, _weiAmount, weiAmount, tokens, contributorsKeys.length, weiRaised);
    }
     
     
     
    function validPurchase(uint256 _weiAmount) internal view returns (bool) {
        return super.validPurchase(_weiAmount) && _weiAmount >= minContribution;
    }
     
     
    function hasEnded() public view returns (bool) {
        return super.hasEnded() || softCapClose > 0 && now > softCapClose;
    }
     
     
    function claimRefund() public {
        claimRefundFor(msg.sender);
    }
     
    function finalization() internal {
        uint256 _balance = getHealBalance();
         
        if (goalReached()) {
             
            tokenSold = tokenBalance; 
             
            if (_balance > tokenBalance) {
                ethealController.ethealToken().transfer(ethealController.SALE(), _balance.sub(tokenBalance));
            }
        } else if (!goalReached() && _balance > 0) {
             
            tokenBalance = 0;
            ethealController.ethealToken().transfer(ethealController.SALE(), _balance);
        }
        super.finalization();
    }
     
     
     
     
    modifier beforeSale() {
        require(!hasStarted());
        _;
    }
     
     
     
     
     
     
     
     
    function setWhitelist(address[] _add, address[] _remove, uint256[] _whitelistLimits) public onlyOwner beforeSale {
        uint256 i = 0;
        uint8 j = 0;  
         
        if (_whitelistLimits.length > 0) {
             
            whitelistDayCount = uint8(_whitelistLimits.length);
            for (i = 0; i < _whitelistLimits.length; i++) {
                j = uint8(i.add(1));
                if (whitelistDayMaxStake[j] != _whitelistLimits[i]) {
                    whitelistDayMaxStake[j] = _whitelistLimits[i];
                    WhitelistSetDay(msg.sender, j, _whitelistLimits[i]);
                }
            }
        }
         
        for (i = 0; i < _add.length; i++) {
            require(_add[i] != address(0));
            
            if (!whitelist[_add[i]]) {
                whitelist[_add[i]] = true;
                WhitelistAddressAdded(msg.sender, _add[i]);
            }
        }
         
        for (i = 0; i < _remove.length; i++) {
            require(_remove[i] != address(0));
            
            if (whitelist[_remove[i]]) {
                whitelist[_remove[i]] = false;
                WhitelistAddressRemoved(msg.sender, _remove[i]);
            }
        }
    }
     
    function setMaxGas(uint256 _maxGas, uint256 _penalty) public onlyOwner beforeSale {
        maxGasPrice = _maxGas;
        maxGasPricePenalty = _penalty;
    }
     
    function setMinContribution(uint256 _minContribution) public onlyOwner beforeSale {
        minContribution = _minContribution;
    }
     
    function setCaps(uint256 _goal, uint256 _softCap, uint256 _softCapTime, uint256 _cap) public onlyOwner beforeSale {
        require(0 < _goal && _goal <= _softCap && _softCap <= _cap);
        goal = _goal;
        softCap = _softCap;
        softCapTime = _softCapTime;
        cap = _cap;
    }
     
    function setTimes(uint256 _startTime, uint256 _endTime) public onlyOwner beforeSale {
        require(_startTime > now && _startTime < _endTime);
        startTime = _startTime;
        endTime = _endTime;
    }
     
    function setRate(uint256 _rate) public onlyOwner beforeSale {
        require(_rate > 0);
        rate = _rate;
    }
     
     
     
     
     
    modifier afterSaleFail() {
        require(!goalReached() && isFinalized);
        _;
    }
     
     
     
     
     
    modifier afterSaleSuccess() {
        require(goalReached() && isFinalized);
        _;
    }
     
    modifier afterSale() {
        require(isFinalized);
        _;
    }
    
     
     
    function claimRefundFor(address _beneficiary) public afterSaleFail whenNotPaused {
        require(_beneficiary != address(0));
        vault.refund(_beneficiary);
    }
     
     
    function claimRefundsFor(address[] _beneficiaries) external afterSaleFail {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            claimRefundFor(_beneficiaries[i]);
        }
    }
     
    function claimToken() public afterSaleSuccess {
        claimTokenFor(msg.sender);
    }
     
     
     
    function claimTokenFor(address _beneficiary) public afterSaleSuccess whenNotPaused {
        uint256 stake = stakes[_beneficiary];
        require(stake > 0);
         
        stakes[_beneficiary] = 0;
         
        uint256 tokens = stake.mul(rate);
         
        tokenBalance = tokenBalance.sub(tokens);
         
        ethealController.addHodlerStake(_beneficiary, tokens.mul(2));
         
        require(ethealController.ethealToken().transfer(_beneficiary, tokens));
        TokenClaimed(msg.sender, _beneficiary, stake, tokens);
    }
     
     
     
    function claimTokensFor(address[] _beneficiaries) external afterSaleSuccess {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            claimTokenFor(_beneficiaries[i]);
        }
    }
     
    function extractVaultTokens(address _token, address _claimer) public onlyOwner afterSale {
         
        require(_claimer != address(0));
        require(goalReached() || _token != address(0));
        vault.extractTokens(_token, _claimer);
    }
     
     
     
     
    function howMuchCanIContributeNow() view public returns (uint256) {
        return howMuchCanXContributeNow(msg.sender);
    }
     
     
     
     
     
     
    function howMuchCanXContributeNow(address _beneficiary) view public returns (uint256) {
        require(_beneficiary != address(0));
        if (!hasStarted() || hasEnded()) {
            return 0;
        }
         
        uint256 weiToCap = cap.sub(weiRaised);
         
        uint8 _saleDay = getSaleDayNow();
        if (_saleDay <= whitelistDayCount) {
             
             
            if (!whitelist[_beneficiary]) {
                return 0;
            }
             
            uint256 weiToPersonalCap = whitelistDayMaxStake[_saleDay].sub(stakes[_beneficiary]);
             
            if (msg.value > 0 && maxGasPrice > 0 && tx.gasprice > maxGasPrice) {
                weiToPersonalCap = weiToPersonalCap.mul(100).div(maxGasPricePenalty);
            }
            weiToCap = uint256Min(weiToCap, weiToPersonalCap);
        }
        return weiToCap;
    }
     
     
     
     
     
     
    function getSaleDay(uint256 _time) view public returns (uint8) {
        return uint8(_time.sub(startTime).div(60*60*24).add(1));
    }
     
     
    function getSaleDayNow() view public returns (uint8) {
        return getSaleDay(now);
    }
     
    function uint8Min(uint8 a, uint8 b) pure internal returns (uint8) {
        return a > b ? b : a;
    }
     
    function uint256Min(uint256 a, uint256 b) pure internal returns (uint256) {
        return a > b ? b : a;
    }
     
     
     
     
     
    function wasSuccess() view public returns (bool) {
        return hasEnded() && goalReached();
    }
     
     
    function getContributorsCount() view public returns (uint256) {
        return contributorsKeys.length;
    }
     
     
     
     
     
     
    function getContributors(bool _pending, bool _claimed) view public returns (address[] contributors) {
        uint256 i = 0;
        uint256 results = 0;
        address[] memory _contributors = new address[](contributorsKeys.length);
         
        if (goalReached()) {
            for (i = 0; i < contributorsKeys.length; i++) {
                if (_pending && stakes[contributorsKeys[i]] > 0 || _claimed && stakes[contributorsKeys[i]] == 0) {
                    _contributors[results] = contributorsKeys[i];
                    results++;
                }
            }
        } else {
             
            for (i = 0; i < contributorsKeys.length; i++) {
                if (_pending && vault.deposited(contributorsKeys[i]) > 0 || _claimed && vault.deposited(contributorsKeys[i]) == 0) {
                    _contributors[results] = contributorsKeys[i];
                    results++;
                }
            }
        }
        contributors = new address[](results);
        for (i = 0; i < results; i++) {
            contributors[i] = _contributors[i];
        }
        return contributors;
    }
     
    function getHealBalance() view public returns (uint256) {
        return ethealController.ethealToken().balanceOf(address(this));
    }
    
    
     
    function getNow() view public returns (uint256) {
        return now;
    }
}