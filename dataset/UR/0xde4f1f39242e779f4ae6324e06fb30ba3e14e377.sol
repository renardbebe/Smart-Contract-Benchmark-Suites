 

pragma solidity ^0.4.24;

 
library AddressUtils {
  function isContract(address addr) internal view returns (bool) {
    uint256 size;
    assembly { size := extcodesize(addr) }   
    return size > 0;
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

 
contract Ownable {
  address public owner;

   
  address public ICOController;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
  event ControllerTransferred(address indexed previousController, address indexed newController);


   
  constructor () public {
    owner = msg.sender;
     
    ICOController = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  modifier onlyController() {
    require(msg.sender == owner || msg.sender == ICOController);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   
  function setController(address controller) public onlyOwner {
    require(controller != address(0));
    emit ControllerTransferred(ICOController, controller);
    ICOController = controller;
  }
}

 
contract Pausable is Ownable {
  event Pause();
  event Unpause();

  bool public paused = true;


   
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

 
contract KYCBase {
    using SafeMath for uint256;

    mapping (address => bool) public isKycSigner;
    mapping (uint64 => uint256) public alreadyPayed;

    event KycVerified(address indexed signer, address buyerAddress, uint64 buyerId, uint maxAmount);

    constructor(address[] kycSigners) internal {
        for (uint i = 0; i < kycSigners.length; i++) {
            isKycSigner[kycSigners[i]] = true;
        }
    }

     
    function releaseTokensTo(address buyer) internal returns(bool);

     
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
        return buyer == msg.sender;
    }

    function buyTokensFor(address buyerAddress, uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        require(senderAllowedFor(buyerAddress), "senderAllowedFor");
        return buyImplementation(buyerAddress, buyerId, maxAmount, v, r, s);
    }

    function buyTokens(uint64 buyerId, uint maxAmount, uint8 v, bytes32 r, bytes32 s)
        public payable returns (bool)
    {
        return buyImplementation(msg.sender, buyerId, maxAmount, v, r, s);
    }

    function buyImplementation(
        address buyerAddress,
        uint64 buyerId,
        uint maxAmount,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) private returns (bool)
    {
         
        bytes32 hash = sha256(
            abi.encodePacked(
                "Eidoo icoengine authorization",
                this,
                buyerAddress,
                buyerId,
                maxAmount
            )
        );
        address signer = ecrecover(hash, v, r, s);
        if (!isKycSigner[signer]) {
            revert("!isKycSigner");
        } else {
            uint256 totalPayed = alreadyPayed[buyerId].add(msg.value);
            require(totalPayed <= maxAmount, "totalPayed <= maxAmount");
            alreadyPayed[buyerId] = totalPayed;
            emit KycVerified(signer, buyerAddress, buyerId, maxAmount);
            return releaseTokensTo(buyerAddress);
        }
    }

     
    function () public {
        revert();
    }
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

 
contract CrowdsaleKYC is Pausable, Whitelistable, KYCBase {
    using AddressUtils for address;
    using SafeMath for uint256;

    event LogStartBlockChanged(uint256 indexed startBlock);
    event LogEndBlockChanged(uint256 indexed endBlock);
    event LogMinDepositChanged(uint256 indexed minDeposit);
    event LogTokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 indexed amount, uint256 tokenAmount);
    event AddedSenderAllowed(address semder);
    event RemovedSenderAllowed(address semder);

     
    MintableToken public token;

     
    uint256 public startBlock;
    uint256 public endBlock;

     
    uint256 public rate;

     
    uint256 public raisedFunds;

     
    uint256 public soldTokens;

     
    mapping (address => uint256) public balanceOf;

     
    uint256 public minDeposit;

     
    mapping (address => bool) public isAllowedSender;
    
     
     
    function checkSoldout() internal returns (bool isSoldout);
    function setNextPhaseBlock() internal;
    function startNextPhase(uint256 _startBlock) internal;

    modifier beforeStart() {
        require(block.number < startBlock, "already started");
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock, "already ended");
        _;
    }

    constructor(
        uint256 _startBlock,
        uint256 _endBlock,
        uint256 _rate,
        uint256 _minDeposit,
        uint256 maxWhitelistLength,
        uint256 whitelistThreshold,
        address[] kycSigner
    )
    Whitelistable(maxWhitelistLength, whitelistThreshold)
    KYCBase(kycSigner) internal
    {
        require(_startBlock >= block.number, "_startBlock is lower than current block.number");
        require(_endBlock >= _startBlock, "_endBlock is lower than _startBlock");
        require(_rate > 0, "_rate is zero");
        require(_minDeposit > 0, "_minDeposit is zero");

        startBlock = _startBlock;
        endBlock = _endBlock;
        rate = _rate;
        minDeposit = _minDeposit;
    }

     
    function senderAllowedFor(address buyer)
        internal view returns(bool)
    {
         
        return isAllowedSender[msg.sender] == true;
    }

    function addSenderAllowed(address _sender) external onlyOwner {
        isAllowedSender[_sender] = true;
        emit AddedSenderAllowed(_sender);
    }

    function removeSenderAllowed(address _sender) external onlyOwner {
        delete isAllowedSender[_sender];
        emit RemovedSenderAllowed(_sender);
    }

     
    function hasStarted() public view returns (bool started) {
        return block.number >= startBlock;
    }

     
    function hasEnded() public view returns (bool ended) {
        return block.number > endBlock;
    }

     
    function setStartBlock(uint256 _startBlock) external onlyOwner beforeStart {
        require(_startBlock >= block.number, "_startBlock < current block");
        require(_startBlock <= endBlock, "_startBlock > endBlock");
        require(_startBlock != startBlock, "_startBlock == startBlock");

        startBlock = _startBlock;

        emit LogStartBlockChanged(_startBlock);
    }

     
    function setEndBlock(uint256 _endBlock) external onlyOwner beforeEnd {
        require(_endBlock >= block.number, "_endBlock < current block");
        require(_endBlock >= startBlock, "_endBlock < startBlock");
        require(_endBlock != endBlock, "_endBlock == endBlock");

        endBlock = _endBlock;

        emit LogEndBlockChanged(_endBlock);
    }

     
    function setMinDeposit(uint256 _minDeposit) external onlyOwner beforeEnd {
        require(0 < _minDeposit && _minDeposit < minDeposit, "_minDeposit is not in [0, minDeposit]");

        minDeposit = _minDeposit;

        emit LogMinDepositChanged(minDeposit);
    }

     
    function setMaxWhitelistLength(uint256 maxWhitelistLength) external onlyOwner beforeEnd {
        setMaxWhitelistLengthInternal(maxWhitelistLength);
    }

     
    function setWhitelistThresholdBalance(uint256 whitelistThreshold) external onlyOwner beforeEnd {
        setWhitelistThresholdBalanceInternal(whitelistThreshold);
    }

     
    function addToWhitelist(address subscriber) external onlyOwner beforeEnd {
        addToWhitelistInternal(subscriber);
    }

     
    function removeFromWhitelist(address subscriber) external onlyOwner beforeEnd {
        removeFromWhitelistInternal(subscriber, balanceOf[subscriber]);
    }

     
     
     
     

     
    function () public {
        revert("No payable fallback function");
    }

    function uint2str(uint i) internal pure returns (string){
        if (i == 0) return "0";
        uint j = i;
        uint length;
        while (j != 0){
            length++;
            j /= 10;
        }
        bytes memory bstr = new bytes(length);
        uint k = length - 1;
        while (i != 0){
            bstr[k--] = byte(48 + i % 10);
            i /= 10;
        }
        return string(bstr);
    }

     
     
    function releaseTokensTo(address beneficiary) internal whenNotPaused returns(bool) {
        require(beneficiary != address(0), "beneficiary is zero");
        require(isValidPurchase(beneficiary), "invalid purchase by beneficiary");
        
        balanceOf[beneficiary] = balanceOf[beneficiary].add(msg.value);

        raisedFunds = raisedFunds.add(msg.value);

        uint256 tokenAmount = calculateTokens(msg.value);

        soldTokens = soldTokens.add(tokenAmount);
        
         
        
        distributeTokens(beneficiary, tokenAmount);

         

        emit LogTokenPurchase(msg.sender, beneficiary, msg.value, tokenAmount);

        forwardFunds(msg.value);

        if (checkSoldout()) {
             
            setNextPhaseBlock();
             
            startNextPhase(block.number + 6000);
        }
        return true;
    }

     
    function isAllowedBalance(address beneficiary, uint256 balance) public view returns (bool isReallyAllowed) {
        bool hasMinimumBalance = balance >= minDeposit;
        return hasMinimumBalance && super.isAllowedBalance(beneficiary, balance);
    }

     
    function isValidPurchase(address beneficiary) internal view returns (bool isValid) {
        bool withinPeriod = startBlock <= block.number && block.number <= endBlock;
        bool nonZeroPurchase = msg.value != 0;
        bool isValidBalance = isAllowedBalance(beneficiary, balanceOf[beneficiary].add(msg.value));

        return withinPeriod && nonZeroPurchase && isValidBalance;
    }

     
     
    function calculateTokens(uint256 amount) internal view returns (uint256 tokenAmount) {
        return amount.mul(rate);
    }

     
    function distributeTokens(address beneficiary, uint256 tokenAmount) internal {
        token.mint(beneficiary, tokenAmount);
    }

     
     
    function forwardFunds(uint256 amount) internal;
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor (string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor (ERC20Basic _token, address _beneficiary, uint256 _releaseTime) public {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(this);
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

 
contract TokenVesting is Ownable {
  using SafeMath for uint256;
  using SafeERC20 for ERC20Basic;

  event Released(uint256 amount);
  event Revoked();

   
  address public beneficiary;

  uint256 public cliff;
  uint256 public start;
  uint256 public duration;

  bool public revocable;

  mapping (address => uint256) public released;
  mapping (address => bool) public revoked;

   
  constructor (
    address _beneficiary,
    uint256 _start,
    uint256 _cliff,
    uint256 _duration,
    bool _revocable
  )
    public
  {
    require(_beneficiary != address(0));
    require(_cliff <= _duration);

    beneficiary = _beneficiary;
    revocable = _revocable;
    duration = _duration;
    cliff = _start.add(_cliff);
    start = _start;
  }

   
  function release(ERC20Basic token) public {
    uint256 unreleased = releasableAmount(token);

    require(unreleased > 0);

    released[token] = released[token].add(unreleased);

    token.safeTransfer(beneficiary, unreleased);

    emit Released(unreleased);
  }

   
  function revoke(ERC20Basic token) public onlyOwner {
    require(revocable);
    require(!revoked[token]);

    uint256 balance = token.balanceOf(this);

    uint256 unreleased = releasableAmount(token);
    uint256 refund = balance.sub(unreleased);

    revoked[token] = true;

    token.safeTransfer(owner, refund);

    emit Revoked();
  }

   
  function releasableAmount(ERC20Basic token) public view returns (uint256) {
    return vestedAmount(token).sub(released[token]);
  }

   
  function vestedAmount(ERC20Basic token) public view returns (uint256) {
    uint256 currentBalance = token.balanceOf(this);
    uint256 totalBalance = currentBalance.add(released[token]);

    if (block.timestamp < cliff) {
      return 0;
    } else if (block.timestamp >= start.add(duration) || revoked[token]) {
      return totalBalance;
    } else {
      return totalBalance.mul(block.timestamp.sub(start)).div(duration);
    }
  }
}

 
contract KTunePricingPlan {
     
    function payFee(bytes32 serviceName, uint256 multiplier, address client) public returns(bool paid);

     
    function usageFee(bytes32 serviceName, uint256 multiplier) public constant returns(uint fee);
}

contract KTuneCustomToken is Ownable {

    event LogBurnFinished();
    event LogPricingPlanChanged(address indexed caller, address indexed pricingPlan);

     
    KTunePricingPlan public pricingPlan;

     
    address public serviceProvider;

     
    bool public burningFinished;

     
    modifier onlyServiceProvider() {
        require(msg.sender == serviceProvider, "caller is not service provider");
        _;
    }

    modifier canBurn() {
        require(!burningFinished, "burning finished");
        _;
    }

    constructor(address _pricingPlan, address _serviceProvider) internal {
        require(_pricingPlan != 0, "_pricingPlan is zero");
        require(_serviceProvider != 0, "_serviceProvider is zero");

        pricingPlan = KTunePricingPlan(_pricingPlan);
        serviceProvider = _serviceProvider;
    }

     
    function isCustomToken() public pure returns(bool isCustom) {
        return true;
    }

     
    function finishBurning() public onlyOwner canBurn returns(bool finished) {
        burningFinished = true;

        emit LogBurnFinished();

        return true;
    }

     
    function setPricingPlan(address _pricingPlan) public onlyServiceProvider {
        require(_pricingPlan != 0, "_pricingPlan is 0");
        require(_pricingPlan != address(pricingPlan), "_pricingPlan == pricingPlan");

        pricingPlan = KTunePricingPlan(_pricingPlan);

        emit LogPricingPlanChanged(msg.sender, _pricingPlan);
    }
}

contract BurnableERC20 is ERC20 {
    function burn(uint256 amount) public returns (bool burned);
}

 
contract KTuneTokenBurner is Pausable {
    using SafeMath for uint256;

    event LogKTuneTokenBurnerCreated(address indexed caller, address indexed wallet);
    event LogBurningPercentageChanged(address indexed caller, uint256 indexed burningPercentage);

     
    address public wallet;

     
    uint256 public burningPercentage;

     
    uint256 public burnedTokens;

     
    uint256 public transferredTokens;

     
    constructor(address _wallet) public {
        require(_wallet != address(0), "_wallet is zero");
        
        wallet = _wallet;
        burningPercentage = 100;

        emit LogKTuneTokenBurnerCreated(msg.sender, _wallet);
    }

     
    function setBurningPercentage(uint256 _burningPercentage) public onlyOwner {
        require(0 <= _burningPercentage && _burningPercentage <= 100, "_burningPercentage not in [0, 100]");
        require(_burningPercentage != burningPercentage, "_burningPercentage equal to current one");
        
        burningPercentage = _burningPercentage;

        emit LogBurningPercentageChanged(msg.sender, _burningPercentage);
    }

     
    function tokenReceived(address _token, uint256 _amount) public whenNotPaused {
        require(_token != address(0), "_token is zero");
        require(_amount > 0, "_amount is zero");

        uint256 amountToBurn = _amount.mul(burningPercentage).div(100);
        if (amountToBurn > 0) {
            assert(BurnableERC20(_token).burn(amountToBurn));
            
            burnedTokens = burnedTokens.add(amountToBurn);
        }

        uint256 amountToTransfer = _amount.sub(amountToBurn);
        if (amountToTransfer > 0) {
            assert(BurnableERC20(_token).transfer(wallet, amountToTransfer));

            transferredTokens = transferredTokens.add(amountToTransfer);
        }
    }
}

 
contract KTuneCustomERC20 is KTuneCustomToken, DetailedERC20, MintableToken, BurnableToken {
    using SafeMath for uint256;

    event LogKTuneCustomERC20Created(
        address indexed caller,
        string indexed name,
        string indexed symbol,
        uint8 decimals,
        uint256 transferableFromBlock,
        uint256 lockEndBlock,
        address pricingPlan,
        address serviceProvider
    );
    event LogMintingFeeEnabledChanged(address indexed caller, bool indexed mintingFeeEnabled);
    event LogInformationChanged(address indexed caller, string name, string symbol);
    event LogTransferFeePaymentFinished(address indexed caller);
    event LogTransferFeePercentageChanged(address indexed caller, uint256 indexed transferFeePercentage);

     
    bool public mintingFeeEnabled;

     
    uint256 public transferableFromBlock;

     
    uint256 public lockEndBlock;

     
    mapping (address => uint256) public initiallyLockedBalanceOf;

     
    uint256 public transferFeePercentage;

     
    bool public transferFeePaymentFinished;

    bytes32 public constant BURN_SERVICE_NAME = "KTuneCustomERC20.burn";
    bytes32 public constant MINT_SERVICE_NAME = "KTuneCustomERC20.mint";

    modifier canTransfer(address _from, uint _value) {
        require(block.number >= transferableFromBlock, "token not transferable");

        if (block.number < lockEndBlock) {
            uint256 locked = lockedBalanceOf(_from);
            if (locked > 0) {
                uint256 newBalance = balanceOf(_from).sub(_value);
                require(newBalance >= locked, "_value exceeds locked amount");
            }
        }
        _;
    }

    constructor(
        string _name,
        string _symbol,
        uint8 _decimals,
        uint256 _transferableFromBlock,
        uint256 _lockEndBlock,
        address _pricingPlan,
        address _serviceProvider
    )
    KTuneCustomToken(_pricingPlan, _serviceProvider)
    DetailedERC20(_name, _symbol, _decimals) public
    {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");
        require(_lockEndBlock >= _transferableFromBlock, "_lockEndBlock lower than _transferableFromBlock");

        transferableFromBlock = _transferableFromBlock;
        lockEndBlock = _lockEndBlock;
        mintingFeeEnabled = true;

        emit LogKTuneCustomERC20Created(
            msg.sender,
            _name,
            _symbol,
            _decimals,
            _transferableFromBlock,
            _lockEndBlock,
            _pricingPlan,
            _serviceProvider
        );
    }

    function setMintingFeeEnabled(bool _mintingFeeEnabled) public onlyOwner returns(bool successful) {
        require(_mintingFeeEnabled != mintingFeeEnabled, "_mintingFeeEnabled == mintingFeeEnabled");

        mintingFeeEnabled = _mintingFeeEnabled;

        emit LogMintingFeeEnabledChanged(msg.sender, _mintingFeeEnabled);

        return true;
    }

     
    function setInformation(string _name, string _symbol) public onlyOwner returns(bool successful) {
        require(bytes(_name).length > 0, "_name is empty");
        require(bytes(_symbol).length > 0, "_symbol is empty");

        name = _name;
        symbol = _symbol;

        emit LogInformationChanged(msg.sender, _name, _symbol);

        return true;
    }

     
    function finishTransferFeePayment() public onlyOwner returns(bool finished) {
        require(!transferFeePaymentFinished, "transfer fee finished");

        transferFeePaymentFinished = true;

        emit LogTransferFeePaymentFinished(msg.sender);

        return true;
    }

     
    function setTransferFeePercentage(uint256 _transferFeePercentage) public onlyOwner {
        require(0 <= _transferFeePercentage && _transferFeePercentage <= 100, "_transferFeePercentage not in [0, 100]");
        require(_transferFeePercentage != transferFeePercentage, "_transferFeePercentage equal to current value");

        transferFeePercentage = _transferFeePercentage;

        emit LogTransferFeePercentageChanged(msg.sender, _transferFeePercentage);
    }

    function lockedBalanceOf(address _to) public constant returns(uint256 locked) {
        uint256 initiallyLocked = initiallyLockedBalanceOf[_to];
        if (block.number >= lockEndBlock) return 0;
        else if (block.number <= transferableFromBlock) return initiallyLocked;

        uint256 releaseForBlock = initiallyLocked.div(lockEndBlock.sub(transferableFromBlock));
        uint256 released = block.number.sub(transferableFromBlock).mul(releaseForBlock);
        return initiallyLocked.sub(released);
    }

     
    function transferFee(uint256 _value) public view returns(uint256 usageFee) {
        return _value.mul(transferFeePercentage).div(100);
    }

     
    function freeTransfer() public view returns (bool isTransferFree) {
        return transferFeePaymentFinished || transferFeePercentage == 0;
    }

     
    function transfer(address _to, uint256 _value) canTransfer(msg.sender, _value) public returns(bool transferred) {
        if (freeTransfer()) {
            return super.transfer(_to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transfer(owner, usageFee);
            bool netValueTransferred = super.transfer(_to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) canTransfer(_from, _value) public returns(bool transferred) {
        if (freeTransfer()) {
            return super.transferFrom(_from, _to, _value);
        }
        else {
            uint256 usageFee = transferFee(_value);
            uint256 netValue = _value.sub(usageFee);

            bool feeTransferred = super.transferFrom(_from, owner, usageFee);
            bool netValueTransferred = super.transferFrom(_from, _to, netValue);

            return feeTransferred && netValueTransferred;
        }
    }

     
    function burn(uint256 _amount) public canBurn {
        require(_amount > 0, "_amount is zero");

        super.burn(_amount);

        require(pricingPlan.payFee(BURN_SERVICE_NAME, _amount, msg.sender), "burn fee failed");
    }

     
    function mint(address _to, uint256 _amount) public onlyOwner canMint returns(bool minted) {
        require(_to != 0, "_to is zero");
        require(_amount > 0, "_amount is zero");

        super.mint(_to, _amount);

        if (mintingFeeEnabled) {
            require(pricingPlan.payFee(MINT_SERVICE_NAME, _amount, msg.sender), "mint fee failed");
        }

        return true;
    }

     
    function mintLocked(address _to, uint256 _amount) public onlyOwner canMint returns(bool minted) {
        initiallyLockedBalanceOf[_to] = initiallyLockedBalanceOf[_to].add(_amount);
        
        return mint(_to, _amount);
    }

}

 
contract TokenCappedCrowdsaleKYC is CrowdsaleKYC {
    using SafeMath for uint256;

     
    uint256 public tokenCap;

     
     
    uint256 internal supplyPlatinum;
    uint256 internal supplyGolden;
    uint256 internal supplySilver;

     
     
    function hasEnded() public constant returns (bool) {
        bool capReached = soldTokens >= tokenCap;
        return super.hasEnded() || capReached;
    }

     
     
    function isValidPurchase(address beneficiary) internal constant returns (bool isValid) {
        uint256 tokenAmount = calculateTokens(msg.value);
        bool withinCap = soldTokens.add(tokenAmount) <= tokenCap;
        return withinCap && super.isValidPurchase(beneficiary);
    }
    
    function checkSoldout() internal returns (bool isSoldout) {
        return soldTokens >= tokenCap;
    }
}

 
contract KTuneCustomCrowdsaleKYC is TokenCappedCrowdsaleKYC {
    using AddressUtils for address;
    using SafeMath for uint256;

    event LogKTuneCustomCrowdsaleCreated(
        address sender,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        address indexed wallet
    );
    event LogThreePowerAgesChanged(
        address indexed sender,
        uint256 indexed platinumAgeEndBlock,
        uint256 indexed goldenAgeEndBlock,
        uint256 silverAgeEndBlock,
        uint256 platinumAgeRate,
        uint256 goldenAgeRate,
        uint256 silverAgeRate
    );

    event LogForceThreePowerAgesChanged(
        address indexed sender,
        uint256 indexed platinumAgeEndBlock,
        uint256 indexed goldenAgeEndBlock,
        uint256 silverAgeEndBlock
    );
    
    event LogStartNextPhase(
        address sender,
        uint256 indexed startBlock,
        uint256 indexed endBlock,
        string  indexed phaseName
    );
    
    event LogInvokeNextPhase(
        address sender,
        uint256 indexed invokeBlock
    );

     
    uint256 public platinumAgeEndBlock;

     
    uint256 public goldenAgeEndBlock;

     
    uint256 public silverAgeEndBlock;

     
    uint256 public platinumAgeRate;

     
    uint256 public goldenAgeRate;

     
    uint256 public silverAgeRate;

     
    address public wallet;

     
    uint8 public phaseLevel = 0;

     
    constructor(
        uint256 _minDeposit,
        uint256 _maxWhitelistLength,
        uint256 _whitelistThreshold,
        address _token,
        address _wallet,
        address[] _kycSigner,
	    uint256 _platinumCap,
	    uint256 _goldenCap,
	    uint256 _silverCap,
	    uint256 _platinumRate,
	    uint256 _goldenRate,
	    uint256 _silverRate
    )
    CrowdsaleKYC(
        block.number + 60000,
        block.number + 120000,
        _silverRate,
        _minDeposit,
        _maxWhitelistLength,
        _whitelistThreshold,
        _kycSigner
    )
    public {
        require(_token.isContract(), "_token is not contract");
        require(_platinumCap > 0, "_platinumCap is zero");
        require(_goldenCap > 0, "_goldenCap is zero");
        require(_silverCap > 0, "_silverCap is zero");
        require(_platinumRate > 0, "_platinumRate is zero");
        require(_goldenRate > 0, "_goldenRate is zero");
        require(_silverRate > 0, "_silverRate is zero");

        platinumAgeRate = _platinumRate;
        goldenAgeRate = _goldenRate;
        silverAgeRate = _silverRate;

        token = KTuneCustomERC20(_token);
        wallet = _wallet;

         
         
         
	supplyPlatinum = _platinumCap;
	supplyGolden   = _goldenCap;
	supplySilver   = _silverCap;

        emit LogKTuneCustomCrowdsaleCreated(msg.sender, startBlock, endBlock, _wallet);
    }

     
    function setThreePowerAges(
        uint256 _startBlock,
        uint256 _platinumAgeEndBlock,
        uint256 _goldenAgeEndBlock,
        uint256 _silverAgeEndBlock,
        uint256 _platinumAgeRate,
        uint256 _goldenAgeRate
    )
    external onlyOwner beforeStart
    {
        require(_startBlock < _platinumAgeEndBlock, "_platinumAgeEndBlock not greater than start block");
        require(_platinumAgeEndBlock < _goldenAgeEndBlock, "_platinumAgeEndBlock not lower than _goldenAgeEndBlock");
        require(_goldenAgeEndBlock < _silverAgeEndBlock, "_silverAgeEndBlock not greater than _goldenAgeEndBlock");
         
        require(_platinumAgeRate > _goldenAgeRate, "_platinumAgeRate not greater than _goldenAgeRate");
        require(_goldenAgeRate > rate, "_goldenAgeRate not greater than _silverAgeRate");

         
        startBlock = _startBlock;
        platinumAgeEndBlock = _platinumAgeEndBlock;
        goldenAgeEndBlock = _goldenAgeEndBlock;
        endBlock = silverAgeEndBlock = _silverAgeEndBlock;

        platinumAgeRate = _platinumAgeRate;
        goldenAgeRate = _goldenAgeRate;
        silverAgeRate = rate;

        emit LogThreePowerAgesChanged(
            msg.sender,
            platinumAgeEndBlock,
            goldenAgeEndBlock,
            silverAgeEndBlock,
            platinumAgeRate,
            goldenAgeRate,
            silverAgeRate
        );
    }
    
    function forceThreePowerAgesBlock(
        uint256 _platinumAgeEndBlock,
        uint256 _goldenAgeEndBlock,
        uint256 _silverAgeEndBlock
    )
    external onlyOwner
    {
        require(_platinumAgeEndBlock < _goldenAgeEndBlock, "_platinumAgeEndBlock not lower than _goldenAgeEndBlock");
        require(_goldenAgeEndBlock < _silverAgeEndBlock, "_silverAgeEndBlock not greater than _goldenAgeEndBlock");

        platinumAgeEndBlock = _platinumAgeEndBlock;
        goldenAgeEndBlock = _goldenAgeEndBlock;
        endBlock = silverAgeEndBlock = _silverAgeEndBlock;

        emit LogForceThreePowerAgesChanged(
            msg.sender,
            platinumAgeEndBlock,
            goldenAgeEndBlock,
            silverAgeEndBlock
        );
    }
    
     

    function grantTokenOwnership(address _client) external onlyOwner returns(bool granted) {
        require(!_client.isContract(), "_client is contract");
        require(hasEnded(), "crowdsale not ended yet");

         
        token.transferOwnership(_client);

        return true;
    }

     
    function calculateTokens(uint256 amount) internal view returns(uint256 tokenAmount) {
        uint256 conversionRate = block.number <= platinumAgeEndBlock ? platinumAgeRate :
            block.number <= goldenAgeEndBlock ? goldenAgeRate :
            block.number <= silverAgeEndBlock ? silverAgeRate :
            rate;

        return amount.mul(conversionRate);
    }

     

     
    function forwardFunds(uint256 amount) internal {
        wallet.transfer(amount);
    }

     
    function setNextPhaseBlock() internal {
         if (phaseLevel == 1) {
              platinumAgeEndBlock = block.number;
               
              goldenAgeEndBlock = block.number+66000;
         } else if (phaseLevel == 2) {
              goldenAgeEndBlock = block.number;
         }
          
    }

    function startNextPhase(uint256 _startBlock) internal {
      if (_startBlock >= goldenAgeEndBlock) {
           
          require(phaseLevel == 2, "Not allow Phase 3");
           
          startBlock = _startBlock;
           
          soldTokens = 0;
           
          endBlock = silverAgeEndBlock;
          tokenCap = supplySilver;
          phaseLevel = 3;
	  emit LogStartNextPhase(msg.sender, startBlock, endBlock, "Phase 3");
      }
      else if (_startBlock >= platinumAgeEndBlock) {
           
          require(phaseLevel == 1, "Not allow Phase 2");
           
          startBlock = _startBlock;
           
          soldTokens = 0;
           
          endBlock = goldenAgeEndBlock;
          tokenCap = supplyGolden;
          phaseLevel = 2;
	  emit LogStartNextPhase(msg.sender, startBlock, endBlock, "Phase 2");
      }
      else {
           
          require(phaseLevel == 0, "Not allow Phase 1");
           
          startBlock = _startBlock;
           
          soldTokens = 0;
           
          endBlock = platinumAgeEndBlock;
          tokenCap = supplyPlatinum;
          phaseLevel = 1;
	  emit LogStartNextPhase(msg.sender, startBlock, endBlock, "Phase 1");
      }
      if (paused) {
        paused = false;
        emit Unpause();
      }
    }

    function invokeNextPhase() onlyController public {
      require(block.number < silverAgeEndBlock, "No more phase in This token sale");
      startNextPhase(block.number);
      emit LogInvokeNextPhase(msg.sender, block.number);
    }
}