 

pragma solidity ^0.4.23;

 

 
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

 

 
library AddressUtils {

   
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
     
     
     
     
     
     
    assembly { size := extcodesize(addr) }   
    return size > 0;
  }

}

 

 
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
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

 

 
contract Presale is Whitelistable, Pausable {
    using AddressUtils for address;
    using SafeMath for uint256;

    event LogCreated(
        address caller,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        uint256 minDeposit,
        address wallet,
        address indexed providerWallet,
        uint256 maxWhitelistLength,
        uint256 whitelistThreshold
    );
    event LogMinDepositChanged(address indexed caller, uint256 indexed minDeposit);
    event LogInvestmentReceived(
        address indexed caller,
        address indexed beneficiary,
        uint256 indexed amount,
        uint256 netAmount
    );
    event LogPresaleTokenChanged(
        address indexed caller,
        address indexed presaleToken,
        uint256 indexed rate
    );

     
    uint256 public startBlock;
    uint256 public endBlock;

     
    address public wallet;

     
    uint256 public minDeposit;

     
    mapping (address => uint256) public balanceOf;
    
     
    uint256 public raisedFunds;

     
    uint256 public providerFees;

     
    address public providerWallet;

     
    uint256 public feeThreshold1;
    uint256 public feeThreshold2;

     
    uint256 public lowFeePercentage;
    uint256 public mediumFeePercentage;
    uint256 public highFeePercentage;

     
    MintableToken public presaleToken;

     
    uint256 public rate;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage
    )
    Whitelistable(_maxWhitelistLength, _whitelistThreshold)
    public
    {
        require(_startBlock >= block.number, "_startBlock is lower than current block number");
        require(_endBlock >= _startBlock, "_endBlock is lower than _startBlock");
        require(_minDeposit > 0, "_minDeposit is zero");
        require(_wallet != address(0) && !_wallet.isContract(), "_wallet is zero or contract");
        require(!_providerWallet.isContract(), "_providerWallet is contract");
        require(_feeThreshold2 >= _feeThreshold1, "_feeThreshold2 is lower than _feeThreshold1");
        require(0 <= _lowFeePercentage && _lowFeePercentage <= 100, "_lowFeePercentage not in range [0, 100]");
        require(0 <= _mediumFeePercentage && _mediumFeePercentage <= 100, "_mediumFeePercentage not in range [0, 100]");
        require(0 <= _highFeePercentage && _highFeePercentage <= 100, "_highFeePercentage not in range [0, 100]");

        startBlock = _startBlock;
        endBlock = _endBlock;
        minDeposit = _minDeposit;
        wallet = _wallet;
        providerWallet = _providerWallet;
        feeThreshold1 = _feeThreshold1;
        feeThreshold2 = _feeThreshold2;
        lowFeePercentage = _lowFeePercentage;
        mediumFeePercentage = _mediumFeePercentage;
        highFeePercentage = _highFeePercentage;

        emit LogCreated(
            msg.sender,
            _startBlock,
            _endBlock,
            _minDeposit,
            _wallet,
            _providerWallet,
            _maxWhitelistLength,
            _whitelistThreshold
        );
    }

    function hasStarted() public view returns (bool ended) {
        return block.number >= startBlock;
    }

     
    function hasEnded() public view returns (bool ended) {
        return block.number > endBlock;
    }

     
    function currentFeePercentage() public view returns (uint256 feePercentage) {
        return raisedFunds < feeThreshold1 ? lowFeePercentage :
            raisedFunds < feeThreshold2 ? mediumFeePercentage : highFeePercentage;
    }

     
    function setMinDeposit(uint256 _minDeposit) external onlyOwner {
        require(0 < _minDeposit && _minDeposit < minDeposit, "_minDeposit not in range [0, minDeposit]");
        require(!hasEnded(), "presale has ended");

        minDeposit = _minDeposit;

        emit LogMinDepositChanged(msg.sender, _minDeposit);
    }

     
    function setMaxWhitelistLength(uint256 _maxWhitelistLength) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        setMaxWhitelistLengthInternal(_maxWhitelistLength);
    }

     
    function setWhitelistThresholdBalance(uint256 _whitelistThreshold) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        setWhitelistThresholdBalanceInternal(_whitelistThreshold);
    }

     
    function addToWhitelist(address _subscriber) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        addToWhitelistInternal(_subscriber);
    }

     
    function removeFromWhitelist(address _subscriber) external onlyOwner {
        require(!hasEnded(), "presale has ended");
        removeFromWhitelistInternal(_subscriber, balanceOf[_subscriber]);
    }

     
    function setPresaleToken(MintableToken _presaleToken, uint256 _rate) external onlyOwner {
        require(_presaleToken != presaleToken || _rate != rate, "both _presaleToken and _rate equal to current ones");
        require(!hasEnded(), "presale has ended");

        presaleToken = _presaleToken;
        rate = _rate;

        emit LogPresaleTokenChanged(msg.sender, _presaleToken, _rate);
    }

    function isAllowedBalance(address _beneficiary, uint256 _balance) public view returns (bool isReallyAllowed) {
        bool hasMinimumBalance = _balance >= minDeposit;
        return hasMinimumBalance && super.isAllowedBalance(_beneficiary, _balance);
    }

    function isValidInvestment(address _beneficiary, uint256 _amount) public view returns (bool isValid) {
        bool withinPeriod = startBlock <= block.number && block.number <= endBlock;
        bool nonZeroPurchase = _amount != 0;
        bool isAllowedAmount = isAllowedBalance(_beneficiary, balanceOf[_beneficiary].add(_amount));

        return withinPeriod && nonZeroPurchase && isAllowedAmount;
    }

    function invest(address _beneficiary) public payable whenNotPaused {
        require(_beneficiary != address(0), "_beneficiary is zero");
        require(_beneficiary != wallet, "_beneficiary is equal to wallet");
        require(_beneficiary != providerWallet, "_beneficiary is equal to providerWallet");
        require(isValidInvestment(_beneficiary, msg.value), "forbidden investment for _beneficiary");

        balanceOf[_beneficiary] = balanceOf[_beneficiary].add(msg.value);
        raisedFunds = raisedFunds.add(msg.value);

         
        if (presaleToken != address(0) && rate != 0) {
            uint256 tokenAmount = msg.value.mul(rate);
            presaleToken.mint(_beneficiary, tokenAmount);
        }

        if (providerWallet == 0) {
            wallet.transfer(msg.value);

            emit LogInvestmentReceived(msg.sender, _beneficiary, msg.value, msg.value);
        }
        else {
            uint256 feePercentage = currentFeePercentage();
            uint256 fees = msg.value.mul(feePercentage).div(100);
            uint256 netAmount = msg.value.sub(fees);

            providerFees = providerFees.add(fees);

            providerWallet.transfer(fees);
            wallet.transfer(netAmount);

            emit LogInvestmentReceived(msg.sender, _beneficiary, msg.value, netAmount);
        }
    }

    function () external payable whenNotPaused {
        invest(msg.sender);
    }
}

 

 
contract CappedPresale is Presale {
    using SafeMath for uint256;

    event LogMaxCapChanged(address indexed caller, uint256 indexed maxCap);

     
    uint256 public maxCap;

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        uint256 _maxCap
    )
    Presale(
        _startBlock,
        _endBlock,
        _minDeposit,
        _wallet,
        _providerWallet,
        _maxWhitelistLength,
        _whitelistThreshold,
        _feeThreshold1,
        _feeThreshold2,
        _lowFeePercentage,
        _mediumFeePercentage,
        _highFeePercentage
    )
    public
    {
        require(_maxCap > 0, "_maxCap is zero");
        require(_maxCap >= _feeThreshold2, "_maxCap is lower than _feeThreshold2");
        
        maxCap = _maxCap;
    }

     
    function setMaxCap(uint256 _maxCap) external onlyOwner {
        require(_maxCap > maxCap, "_maxCap is not greater than current maxCap");
        require(!hasEnded(), "presale has ended");
        
        maxCap = _maxCap;

        emit LogMaxCapChanged(msg.sender, _maxCap);
    }

     
     
    function hasEnded() public view returns (bool ended) {
        bool capReached = raisedFunds >= maxCap;
        
        return super.hasEnded() || capReached;
    }

     
     
    function isValidInvestment(address _beneficiary, uint256 _amount) public view returns (bool isValid) {
        bool withinCap = raisedFunds.add(_amount) <= maxCap;

        return super.isValidInvestment(_beneficiary, _amount) && withinCap;
    }
}

 

 
contract NokuCustomPresale is CappedPresale {
    event LogNokuCustomPresaleCreated(
        address caller,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        uint256 minDeposit,
        address wallet,
        address indexed providerWallet,
        uint256 maxWhitelistLength,
        uint256 whitelistThreshold
    );

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        uint256 _maxCap
    )
    CappedPresale(
        _startBlock,
        _endBlock,
        _minDeposit,
        _wallet,
        _providerWallet,
        _maxWhitelistLength,
        _whitelistThreshold,
        _feeThreshold1,
        _feeThreshold2,
        _lowFeePercentage,
        _mediumFeePercentage,
        _highFeePercentage,
        _maxCap
    )
    public {
        emit LogNokuCustomPresaleCreated(
            msg.sender,
            _startBlock,
            _endBlock,
            _minDeposit,
            _wallet,
            _providerWallet,
            _maxWhitelistLength,
            _whitelistThreshold
        );
    }
}

 

 
contract NokuPricingPlan {
     
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

     
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
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

 

 
contract NokuCustomPresaleService is NokuCustomService {
    event LogNokuCustomPresaleServiceCreated(address indexed caller);

    bytes32 public constant SERVICE_NAME = "NokuCustomERC20.presale";
    uint256 public constant CREATE_AMOUNT = 1 * 10**18;

    constructor(address _pricingPlan) NokuCustomService(_pricingPlan) public {
        emit LogNokuCustomPresaleServiceCreated(msg.sender);
    }

    function createCustomPresale(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _minDeposit,
        address _wallet,
        address _providerWallet,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        uint256 _feeThreshold1,
        uint256 _feeThreshold2,
        uint256 _lowFeePercentage,
        uint256 _mediumFeePercentage,
        uint256 _highFeePercentage,
        uint256 _maxCap
    )
    public returns(NokuCustomPresale customPresale)
    {
        customPresale = new NokuCustomPresale(
            _startBlock,
            _endBlock,
            _minDeposit,
            _wallet,
            _providerWallet,
            _maxWhitelistLength,
            _whitelistThreshold,
            _feeThreshold1,
            _feeThreshold2,
            _lowFeePercentage,
            _mediumFeePercentage,
            _highFeePercentage,
            _maxCap
        );

         
        customPresale.transferOwnership(msg.sender);

        require(pricingPlan.payFee(SERVICE_NAME, CREATE_AMOUNT, msg.sender), "fee payment failed");
    }
}