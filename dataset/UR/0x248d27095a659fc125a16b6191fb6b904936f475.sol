 

pragma solidity ^0.4.24;

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

contract PostDeliveryCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  mapping(address => uint256) public balances;

   
  function withdrawTokens() public {
    require(hasClosed());
    uint256 amount = balances[msg.sender];
    require(amount > 0);
    balances[msg.sender] = 0;
    _deliverTokens(msg.sender, amount);
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

contract Oraclized is Ownable {

    address public oracle;

    constructor(address _oracle) public {
        oracle = _oracle;
    }

     
    function setOracle(address _oracle) public onlyOwner {
        oracle = _oracle;
    }

     
    modifier onlyOracle() {
        require(msg.sender == oracle);
        _;
    }

     
    modifier onlyOwnerOrOracle() {
        require((msg.sender == oracle) || (msg.sender == owner));
        _;
    }
}

contract KYCCrowdsale is Oraclized, PostDeliveryCrowdsale {
    using SafeMath for uint256;

     
    uint256 public etherPriceInUsd;
    uint256 public usdRaised;
    mapping (address => uint256) public weiInvested;
    mapping (address => uint256) public usdInvested;

     
    mapping (address => bool) public KYCPassed;
    mapping (address => bool) public KYCRequired;

     
    uint256 public KYCRequiredAmountInUsd;

    event EtherPriceUpdated(uint256 _cents);

     
    constructor(uint256 _kycAmountInUsd, uint256 _etherPrice) public {
        require(_etherPrice > 0);

        KYCRequiredAmountInUsd = _kycAmountInUsd;
        etherPriceInUsd = _etherPrice;
    }

     
    function setKYCRequiredAmount(uint256 _cents) external onlyOwnerOrOracle {
        require(_cents > 0);

        KYCRequiredAmountInUsd = _cents;
    }

     
    function setEtherPrice(uint256 _cents) public onlyOwnerOrOracle {
        require(_cents > 0);

        etherPriceInUsd = _cents;

        emit EtherPriceUpdated(_cents);
    }

     
    function isKYCRequired(address _address) external view returns(bool) {
        return KYCRequired[_address];
    }

     
    function isKYCPassed(address _address) external view returns(bool) {
        return KYCPassed[_address];
    }

     
    function isKYCSatisfied(address _address) public view returns(bool) {
        return !KYCRequired[_address] || KYCPassed[_address];
    }

     
    function weiInvestedOf(address _account) external view returns (uint256) {
        return weiInvested[_account];
    }

     
    function usdInvestedOf(address _account) external view returns (uint256) {
        return usdInvested[_account];
    }

     
    function updateKYCStatus(address[] _addresses, bool _completed) public onlyOwnerOrOracle {
        for (uint16 index = 0; index < _addresses.length; index++) {
            KYCPassed[_addresses[index]] = _completed;
        }
    }

     
    function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
        super._updatePurchasingState(_beneficiary, _weiAmount);

        uint256 usdAmount = _weiToUsd(_weiAmount);
        usdRaised = usdRaised.add(usdAmount);
        usdInvested[_beneficiary] = usdInvested[_beneficiary].add(usdAmount);
        weiInvested[_beneficiary] = weiInvested[_beneficiary].add(_weiAmount);

        if (usdInvested[_beneficiary] >= KYCRequiredAmountInUsd) {
            KYCRequired[_beneficiary] = true;
        }
    }

     
    function withdrawTokens() public {
        require(isKYCSatisfied(msg.sender));

        super.withdrawTokens();
    }

     
    function _weiToUsd(uint256 _wei) internal view returns (uint256) {
        return _wei.mul(etherPriceInUsd).div(1e18);
    }

     
    function _usdToWei(uint256 _cents) internal view returns (uint256) {
        return _cents.mul(1e18).div(etherPriceInUsd);
    }
}

contract KYCRefundableCrowdsale is KYCCrowdsale {
    using SafeMath for uint256;

     
    uint256 private percentage = 100 * 1000;
    uint256 private weiOnFinalize;

     
    bool public goalReached = false;
    bool public isFinalized = false;
    uint256 public tokensWithdrawn;

    event Refund(address indexed _account, uint256 _amountInvested, uint256 _amountRefunded);
    event Finalized();
    event OwnerWithdraw(uint256 _amount);

     
    function setGoalReached(bool _success) external onlyOwner {
        require(!isFinalized);
        goalReached = _success;
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached);

        uint256 refundPercentage = _refundPercentage();
        uint256 amountInvested = weiInvested[msg.sender];
        uint256 amountRefunded = amountInvested.mul(refundPercentage).div(percentage);
        weiInvested[msg.sender] = 0;
        usdInvested[msg.sender] = 0;
        msg.sender.transfer(amountRefunded);

        emit Refund(msg.sender, amountInvested, amountRefunded);
    }

     
    function finalize() public onlyOwner {
        require(!isFinalized);

         
        closingTime = block.timestamp;
        weiOnFinalize = address(this).balance;
        isFinalized = true;

        emit Finalized();
    }

     
    function withdrawTokens() public {
        require(isFinalized);
        require(goalReached);

        tokensWithdrawn = tokensWithdrawn.add(balances[msg.sender]);

        super.withdrawTokens();
    }

     
    function ownerWithdraw(uint256 _amount) external onlyOwner {
        require(_amount > 0);

        wallet.transfer(_amount);

        emit OwnerWithdraw(_amount);
    }

     
    function _forwardFunds() internal {
         
    }

     
    function _refundPercentage() internal view returns (uint256) {
        return weiOnFinalize.mul(percentage).div(weiRaised);
    }
}

contract AerumCrowdsale is KYCRefundableCrowdsale {
    using SafeMath for uint256;

     
    uint256 public minInvestmentInUsd;

     
    uint256 public tokensSold;

     
    uint256 public pledgeTotal;
    uint256 public pledgeClosingTime;
    mapping (address => uint256) public pledges;

     
    uint256 public whitelistedRate;
    uint256 public publicRate;


    event AirDrop(address indexed _account, uint256 _amount);
    event MinInvestmentUpdated(uint256 _cents);
    event RateUpdated(uint256 _whitelistedRate, uint256 _publicRate);
    event Withdraw(address indexed _account, uint256 _amount);

     
    constructor(
        ERC20 _token, address _wallet,
        uint256 _whitelistedRate, uint256 _publicRate,
        uint256 _openingTime, uint256 _closingTime,
        uint256 _pledgeClosingTime,
        uint256 _kycAmountInUsd, uint256 _etherPriceInUsd)
    Oraclized(msg.sender)
    Crowdsale(_whitelistedRate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
    KYCCrowdsale(_kycAmountInUsd, _etherPriceInUsd)
    KYCRefundableCrowdsale()
    public {
        require(_openingTime < _pledgeClosingTime && _pledgeClosingTime < _closingTime);
        pledgeClosingTime = _pledgeClosingTime;

        whitelistedRate = _whitelistedRate;
        publicRate = _publicRate;

        minInvestmentInUsd = 25 * 100;
    }

     
    function setMinInvestment(uint256 _cents) external onlyOwnerOrOracle {
        minInvestmentInUsd = _cents;

        emit MinInvestmentUpdated(_cents);
    }

     
    function setClosingTime(uint256 _closingTime) external onlyOwner {
        require(_closingTime >= openingTime);

        closingTime = _closingTime;
    }

     
    function setPledgeClosingTime(uint256 _pledgeClosingTime) external onlyOwner {
        require(_pledgeClosingTime >= openingTime && _pledgeClosingTime <= closingTime);

        pledgeClosingTime = _pledgeClosingTime;
    }

     
    function setRate(uint256 _whitelistedRate, uint256 _publicRate) public onlyOwnerOrOracle {
        require(_whitelistedRate > 0);
        require(_publicRate > 0);

        whitelistedRate = _whitelistedRate;
        publicRate = _publicRate;

        emit RateUpdated(_whitelistedRate, _publicRate);
    }

     
    function setRateAndEtherPrice(uint256 _whitelistedRate, uint256 _publicRate, uint256 _cents) external onlyOwnerOrOracle {
        setRate(_whitelistedRate, _publicRate);
        setEtherPrice(_cents);
    }

     
    function sendTokens(address _to, uint256 _amount) external onlyOwner {
        if (!isFinalized || goalReached) {
             
            _ensureTokensAvailable(_amount);
        }

        token.transfer(_to, _amount);
    }

     
    function balanceOf(address _address) external view returns (uint256) {
        return balances[_address];
    }

     
    function capReached() public view returns (bool) {
        return tokensSold >= token.balanceOf(this);
    }

     
    function completionPercentage() external view returns (uint256) {
        uint256 balance = token.balanceOf(this);
        if (balance == 0) {
            return 0;
        }

        return tokensSold.mul(100).div(balance);
    }

     
    function tokensRemaining() external view returns(uint256) {
        return token.balanceOf(this).sub(_tokensLocked());
    }

     
    function withdrawTokens() public {
        uint256 amount = balances[msg.sender];
        super.withdrawTokens();

        emit Withdraw(msg.sender, amount);
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount);

        require(_totalInvestmentInUsd(_beneficiary, _weiAmount) >= minInvestmentInUsd);
        _ensureTokensAvailableExcludingPledge(_beneficiary, _getTokenAmount(_weiAmount));
    }

     
    function _totalInvestmentInUsd(address _beneficiary, uint256 _weiAmount) internal view returns(uint256) {
        return usdInvested[_beneficiary].add(_weiToUsd(_weiAmount));
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        super._processPurchase(_beneficiary, _tokenAmount);

        tokensSold = tokensSold.add(_tokenAmount);

        if (pledgeOpen()) {
             
            _decreasePledge(_beneficiary, _tokenAmount);
        }
    }

     
    function _decreasePledge(address _beneficiary, uint256 _tokenAmount) internal {
        if (pledgeOf(_beneficiary) <= _tokenAmount) {
            pledgeTotal = pledgeTotal.sub(pledgeOf(_beneficiary));
            pledges[_beneficiary] = 0;
        } else {
            pledgeTotal = pledgeTotal.sub(_tokenAmount);
            pledges[_beneficiary] = pledges[_beneficiary].sub(_tokenAmount);
        }
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 currentRate = getCurrentRate();
        return _weiAmount.mul(currentRate);
    }

     
    function getCurrentRate() public view returns (uint256) {
        if (pledgeOpen()) {
            return whitelistedRate;
        }
        return publicRate;
    }

     
    function pledgeOpen() public view returns (bool) {
        return (openingTime <= block.timestamp) && (block.timestamp <= pledgeClosingTime);
    }

     
    function pledgeOf(address _address) public view returns (uint256) {
        return pledges[_address];
    }

     
    function pledgeCapReached() public view returns (bool) {
        return pledgeTotal.add(tokensSold) >= token.balanceOf(this);
    }

     
    function pledgeCompletionPercentage() external view returns (uint256) {
        uint256 balance = token.balanceOf(this);
        if (balance == 0) {
            return 0;
        }

        return pledgeTotal.add(tokensSold).mul(100).div(balance);
    }

     
    function pledge(address[] _addresses, uint256[] _tokens) external onlyOwnerOrOracle {
        require(_addresses.length == _tokens.length);
        _ensureTokensListAvailable(_tokens);

        for (uint16 index = 0; index < _addresses.length; index++) {
            pledgeTotal = pledgeTotal.sub(pledges[_addresses[index]]).add(_tokens[index]);
            pledges[_addresses[index]] = _tokens[index];
        }
    }

     
    function airDropTokens(address[] _addresses, uint256[] _tokens) external onlyOwnerOrOracle {
        require(_addresses.length == _tokens.length);
        _ensureTokensListAvailable(_tokens);

        for (uint16 index = 0; index < _addresses.length; index++) {
            tokensSold = tokensSold.add(_tokens[index]);
            balances[_addresses[index]] = balances[_addresses[index]].add(_tokens[index]);

            emit AirDrop(_addresses[index], _tokens[index]);
        }
    }

     
    function _ensureTokensListAvailable(uint256[] _tokens) internal {
        uint256 total;
        for (uint16 index = 0; index < _tokens.length; index++) {
            total = total.add(_tokens[index]);
        }

        _ensureTokensAvailable(total);
    }

     
    function _ensureTokensAvailable(uint256 _tokens) internal view {
        require(_tokens.add(_tokensLocked()) <= token.balanceOf(this));
    }

     
    function _ensureTokensAvailableExcludingPledge(address _account, uint256 _tokens) internal view {
        require(_tokens.add(_tokensLockedExcludingPledge(_account)) <= token.balanceOf(this));
    }

     
    function _tokensLocked() internal view returns(uint256) {
        uint256 locked = tokensSold.sub(tokensWithdrawn);

        if (pledgeOpen()) {
            locked = locked.add(pledgeTotal);
        }

        return locked;
    }

     
    function _tokensLockedExcludingPledge(address _account) internal view returns(uint256) {
        uint256 locked = _tokensLocked();

        if (pledgeOpen()) {
            locked = locked.sub(pledgeOf(_account));
        }

        return locked;
    }
}