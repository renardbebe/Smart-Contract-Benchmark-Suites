 

pragma solidity 0.4.24;

 

interface DisbursementHandlerI {
    function withdraw(address _beneficiary, uint256 _index) external;
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

 

 
library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}

 

 
contract DisbursementHandler is DisbursementHandlerI, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    struct Disbursement {
         
        uint256 timestamp;

         
        uint256 value;
    }

    event Setup(address indexed _beneficiary, uint256 _timestamp, uint256 _value);
    event TokensWithdrawn(address indexed _to, uint256 _value);

    ERC20 public token;
    uint256 public totalAmount;
    mapping(address => Disbursement[]) public disbursements;

    constructor(ERC20 _token) public {
        require(_token != address(0));
        token = _token;
    }

     
     
     
     
    function setupDisbursement(
        address _beneficiary,
        uint256 _value,
        uint256 _timestamp
    )
        external
        onlyOwner
    {
        require(block.timestamp < _timestamp);
        disbursements[_beneficiary].push(Disbursement(_timestamp, _value));
        totalAmount = totalAmount.add(_value);
        emit Setup(_beneficiary, _timestamp, _value);
    }

     
     
     
    function withdraw(address _beneficiary, uint256 _index)
        external
    {
        Disbursement[] storage beneficiaryDisbursements = disbursements[_beneficiary];
        require(_index < beneficiaryDisbursements.length);

        Disbursement memory disbursement = beneficiaryDisbursements[_index];
        require(disbursement.timestamp < now && disbursement.value > 0);

         
        delete beneficiaryDisbursements[_index];

        token.safeTransfer(_beneficiary, disbursement.value);
        emit TokensWithdrawn(_beneficiary, disbursement.value);
    }
}

 

interface VaultI {
    function deposit(address contributor) external payable;
    function saleSuccessful() external;
    function enableRefunds() external;
    function refund(address contributor) external;
    function close() external;
    function sendFundsToWallet() external;
}

 

 
library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}

 

 

 
contract Vault is VaultI, Ownable {
    using SafeMath for uint256;

    enum State { Active, Success, Refunding, Closed }

     
    uint256 public firstDepositTimestamp; 

    mapping (address => uint256) public deposited;

     
    uint256 public disbursementWei;
    uint256 public disbursementDuration;

     
    address public trustedWallet;

     
    uint256 public initialWei;

     
    uint256 public nextDisbursement;
    
     
    uint256 public totalDeposited;

     
    uint256 public refundable;

    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed contributor, uint256 amount);

    modifier atState(State _state) {
        require(state == _state);
        _;
    }

    constructor (
        address _wallet,
        uint256 _initialWei,
        uint256 _disbursementWei,
        uint256 _disbursementDuration
    ) 
        public 
    {
        require(_wallet != address(0));
        require(_disbursementWei != 0);
        trustedWallet = _wallet;
        initialWei = _initialWei;
        disbursementWei = _disbursementWei;
        disbursementDuration = _disbursementDuration;
        state = State.Active;
    }

     
    function deposit(address _contributor) onlyOwner external payable {
        require(state == State.Active || state == State.Success);
        if (firstDepositTimestamp == 0) {
            firstDepositTimestamp = now;
        }
        totalDeposited = totalDeposited.add(msg.value);
        deposited[_contributor] = deposited[_contributor].add(msg.value);
    }

     
    function saleSuccessful()
        onlyOwner 
        external 
        atState(State.Active)
    {
        state = State.Success;
        transferToWallet(initialWei);
    }

     
    function enableRefunds() onlyOwner external {
        require(state != State.Refunding);
        state = State.Refunding;
        uint256 currentBalance = address(this).balance;
        refundable = currentBalance <= totalDeposited ? currentBalance : totalDeposited;
        emit RefundsEnabled();
    }

     
    function refund(address _contributor) external atState(State.Refunding) {
        require(deposited[_contributor] > 0);
        uint256 refundAmount = deposited[_contributor].mul(refundable).div(totalDeposited);
        deposited[_contributor] = 0;
        _contributor.transfer(refundAmount);
        emit Refunded(_contributor, refundAmount);
    }

     
    function close() external atState(State.Success) onlyOwner {
        state = State.Closed;
        nextDisbursement = now;
        emit Closed();
    }

     
    function sendFundsToWallet() external atState(State.Closed) {
        require(nextDisbursement <= now);

        if (disbursementDuration == 0) {
            trustedWallet.transfer(address(this).balance);
            return;
        }

        uint256 numberOfDisbursements = now.sub(nextDisbursement).div(disbursementDuration).add(1);

        nextDisbursement = nextDisbursement.add(disbursementDuration.mul(numberOfDisbursements));

        transferToWallet(disbursementWei.mul(numberOfDisbursements));
    }

    function transferToWallet(uint256 _amount) internal {
        uint256 amountToSend = Math.min256(_amount, address(this).balance);
        trustedWallet.transfer(amountToSend);
    }
}

 

interface WhitelistableI {
    function changeAdmin(address _admin) external;
    function invalidateHash(bytes32 _hash) external;
    function invalidateHashes(bytes32[] _hashes) external;
}

 

 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig)
    internal
    pure
    returns (address)
  {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
     
     
     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
       
      return ecrecover(hash, v, r, s);
    }
  }

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(
      "\x19Ethereum Signed Message:\n32",
      hash
    );
  }
}

 

 
contract Whitelistable is WhitelistableI, Ownable {
    using ECRecovery for bytes32;

    address public whitelistAdmin;

     
    mapping(bytes32 => bool) public invalidHash;

    event AdminUpdated(address indexed newAdmin);

    modifier validAdmin(address _admin) {
        require(_admin != 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == whitelistAdmin);
        _;
    }

    modifier isWhitelisted(bytes32 _hash, bytes _sig) {
        require(checkWhitelisted(_hash, _sig));
        _;
    }

     
     
    constructor(address _admin) public validAdmin(_admin) {
        whitelistAdmin = _admin;        
    }

     
     
     
    function changeAdmin(address _admin)
        external
        onlyOwner
        validAdmin(_admin)
    {
        emit AdminUpdated(_admin);
        whitelistAdmin = _admin;
    }

     
     
    function invalidateHash(bytes32 _hash) external onlyAdmin {
        invalidHash[_hash] = true;
    }

    function invalidateHashes(bytes32[] _hashes) external onlyAdmin {
        for (uint i = 0; i < _hashes.length; i++) {
            invalidHash[_hashes[i]] = true;
        }
    }

     
     
     
     
    function checkWhitelisted(
        bytes32 _rawHash,
        bytes _sig
    )
        public
        view
        returns(bool)
    {
        bytes32 hash = _rawHash.toEthSignedMessageHash();
        return !invalidHash[_rawHash] && whitelistAdmin == hash.recover(_sig);
    }
}

 

interface EthPriceFeedI {
    function getUnit() external view returns(string);
    function getRate() external view returns(uint256);
    function getLastTimeUpdated() external view returns(uint256); 
}

 

interface SaleI {
    function setup() external;  
    function changeEthPriceFeed(EthPriceFeedI newPriceFeed) external;
    function contribute(address _contributor, uint256 _limit, uint256 _expiration, bytes _sig) external payable; 
    function allocateExtraTokens(address _contributor) external;
    function setEndTime(uint256 _endTime) external;
    function endSale() external;
}

 

contract StateMachine {

    struct State { 
        bytes32 nextStateId;
        mapping(bytes4 => bool) allowedFunctions;
        function() internal[] transitionCallbacks;
        function(bytes32) internal returns(bool)[] startConditions;
    }

    mapping(bytes32 => State) states;

     
    bytes32 private currentStateId;

    event Transition(bytes32 stateId, uint256 blockNumber);

     
    modifier checkAllowed {
        conditionalTransitions();
        require(states[currentStateId].allowedFunctions[msg.sig]);
        _;
    }

     
     
    function conditionalTransitions() public {
        bool checkNextState; 
        do {
            checkNextState = false;

            bytes32 next = states[currentStateId].nextStateId;
             

            for (uint256 i = 0; i < states[next].startConditions.length; i++) {
                if (states[next].startConditions[i](next)) {
                    goToNextState();
                    checkNextState = true;
                    break;
                }
            } 
        } while (checkNextState);
    }

    function getCurrentStateId() view public returns(bytes32) {
        return currentStateId;
    }

     
     
    function setStates(bytes32[] _stateIds) internal {
        require(_stateIds.length > 0);
        require(currentStateId == 0);

        require(_stateIds[0] != 0);

        currentStateId = _stateIds[0];

        for (uint256 i = 1; i < _stateIds.length; i++) {
            require(_stateIds[i] != 0);

            states[_stateIds[i - 1]].nextStateId = _stateIds[i];

             
            require(states[_stateIds[i]].nextStateId == 0);
        }
    }

     
     
     
    function allowFunction(bytes32 _stateId, bytes4 _functionSelector) 
        internal 
    {
        states[_stateId].allowedFunctions[_functionSelector] = true;
    }

     
    function goToNextState() internal {
        bytes32 next = states[currentStateId].nextStateId;
        require(next != 0);

        currentStateId = next;
        for (uint256 i = 0; i < states[next].transitionCallbacks.length; i++) {
            states[next].transitionCallbacks[i]();
        }

        emit Transition(next, block.number);
    }

     
     
     
     
     
     
     
     
     
     
    function addStartCondition(
        bytes32 _stateId,
        function(bytes32) internal returns(bool) _condition
    ) 
        internal 
    {
        states[_stateId].startConditions.push(_condition);
    }

     
     
     
     
     
    function addCallback(bytes32 _stateId, function() internal _callback)
        internal 
    {
        states[_stateId].transitionCallbacks.push(_callback);
    }
}

 

 
contract TimedStateMachine is StateMachine {

    event StateStartTimeSet(bytes32 indexed _stateId, uint256 _startTime);

     
    mapping(bytes32 => uint256) private startTime;

     
     
    function getStateStartTime(bytes32 _stateId) public view returns(uint256) {
        return startTime[_stateId];
    }

     
     
     
     
    function setStateStartTime(bytes32 _stateId, uint256 _timestamp) internal {
        require(block.timestamp < _timestamp);

        if (startTime[_stateId] == 0) {
            addStartCondition(_stateId, hasStartTimePassed);
        }

        startTime[_stateId] = _timestamp;

        emit StateStartTimeSet(_stateId, _timestamp);
    }

    function hasStartTimePassed(bytes32 _stateId) internal returns(bool) {
        return startTime[_stateId] <= block.timestamp;
    }

}

 

 
contract TokenControllerI {

     
     
    function transferAllowed(address _from, address _to)
        external
        view 
        returns (bool);
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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
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

 

 
contract ControllableToken is Ownable, StandardToken {
    TokenControllerI public controller;

     
    modifier isAllowed(address _from, address _to) {
        require(controller.transferAllowed(_from, _to));
        _;
    }

     
    function setController(TokenControllerI _controller) onlyOwner public {
        require(_controller != address(0));
        controller = _controller;
    }

     
     
    function transfer(address _to, uint256 _value) 
        isAllowed(msg.sender, _to)
        public
        returns (bool)
    {
        return super.transfer(_to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value)
        isAllowed(_from, _to) 
        public 
        returns (bool)
    {
        return super.transferFrom(_from, _to, _value);
    }
}

 

 
contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  constructor(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

 
contract Token is ControllableToken, DetailedERC20 {

	 
    constructor(
        uint256 _supply,
        string _name,
        string _symbol,
        uint8 _decimals
    ) DetailedERC20(_name, _symbol, _decimals) public {
        require(_supply != 0);
        totalSupply_ = _supply;
        balances[msg.sender] = _supply;
        emit Transfer(address(0), msg.sender, _supply);   
    }
}

 

 
contract Sale is SaleI, Ownable, Whitelistable, TimedStateMachine, TokenControllerI {
    using SafeMath for uint256;
    using SafeERC20 for Token;

     
    bytes32 private constant SETUP = "setup";
    bytes32 private constant FREEZE = "freeze";
    bytes32 private constant SALE_IN_PROGRESS = "saleInProgress";
    bytes32 private constant SALE_ENDED = "saleEnded";
     
    bytes32[] public states = [SETUP, FREEZE, SALE_IN_PROGRESS, SALE_ENDED];

     
    mapping(address => uint256) public unitContributions;

     
    mapping(address => bool) public extraTokensAllocated;

    DisbursementHandler public disbursementHandler;

    uint256 public totalContributedUnits = 0;  
    uint256 public totalSaleCapUnits;  
    uint256 public minContributionUnits;  
    uint256 public minThresholdUnits;  

     
    uint256 public saleTokensPerUnit;
     
    uint256 public extraTokensPerUnit;
     
    uint256 public tokensForSale;

    Token public trustedToken;
    Vault public trustedVault;
    EthPriceFeedI public ethPriceFeed; 

    event Contribution(
        address indexed contributor,
        address indexed sender,
        uint256 valueUnit,
        uint256 valueWei,
        uint256 excessWei,
        uint256 weiPerUnitRate
    );

    event EthPriceFeedChanged(address previousEthPriceFeed, address newEthPriceFeed);

    event TokensAllocated(address indexed contributor, uint256 tokenAmount);

    constructor (
        uint256 _totalSaleCapUnits,  
        uint256 _minContributionUnits,  
        uint256 _minThresholdUnits,  
        uint256 _maxTokens,
        address _whitelistAdmin,
        address _wallet,
        uint256 _vaultInitialDisburseWei,  
        uint256 _vaultDisbursementWei,  
        uint256 _vaultDisbursementDuration,
        uint256 _startTime,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals, 
        EthPriceFeedI _ethPriceFeed
    ) 
        Whitelistable(_whitelistAdmin)
        public 
    {
        require(_totalSaleCapUnits != 0);
        require(_maxTokens != 0);
        require(_wallet != 0);
        require(_minThresholdUnits <= _totalSaleCapUnits);
        require(_ethPriceFeed != address(0));
        require(now < _startTime);

        totalSaleCapUnits = _totalSaleCapUnits;
        minContributionUnits = _minContributionUnits;
        minThresholdUnits = _minThresholdUnits;

         
        trustedToken = new Token(
            _maxTokens,
            _tokenName,
            _tokenSymbol,
            _tokenDecimals
        );

        disbursementHandler = new DisbursementHandler(trustedToken);
        
        ethPriceFeed = _ethPriceFeed; 

         
        trustedToken.setController(this);

        trustedVault = new Vault(
            _wallet,
            _vaultInitialDisburseWei,
            _vaultDisbursementWei,  
            _vaultDisbursementDuration
        );

         
        setStates(states);

         
        allowFunction(SETUP, this.setup.selector);
        allowFunction(FREEZE, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.contribute.selector);
        allowFunction(SALE_IN_PROGRESS, this.endSale.selector);
        allowFunction(SALE_ENDED, this.allocateExtraTokens.selector);

         
        addStartCondition(SALE_ENDED, wasCapReached);

         
        setStateStartTime(SALE_IN_PROGRESS, _startTime);

         
        addCallback(SALE_ENDED, onSaleEnded);

    }

     
     
    function setup() external onlyOwner checkAllowed {
        trustedToken.safeTransfer(disbursementHandler, disbursementHandler.totalAmount());

        tokensForSale = trustedToken.balanceOf(this);     
        require(tokensForSale >= totalSaleCapUnits);

         
         
        saleTokensPerUnit = tokensForSale.div(totalSaleCapUnits);

         
        goToNextState();
    }

     
    function changeEthPriceFeed(EthPriceFeedI _ethPriceFeed) external onlyOwner {
        require(_ethPriceFeed != address(0));
        emit EthPriceFeedChanged(ethPriceFeed, _ethPriceFeed);
        ethPriceFeed = _ethPriceFeed;
    }

     
    function contribute(
        address _contributor,
        uint256 _contributionLimitUnits, 
        uint256 _payloadExpiration,
        bytes _sig
    ) 
        external 
        payable
        checkAllowed 
        isWhitelisted(keccak256(
            abi.encodePacked(
                _contributor,
                _contributionLimitUnits, 
                _payloadExpiration
            )
        ), _sig)
    {
        require(msg.sender == _contributor);
        require(now < _payloadExpiration); 

        uint256 weiPerUnitRate = ethPriceFeed.getRate(); 
        require(weiPerUnitRate != 0);

        uint256 previouslyContributedUnits = unitContributions[_contributor];

         
        uint256 currentContributionUnits = min256(
            _contributionLimitUnits.sub(previouslyContributedUnits),
            totalSaleCapUnits.sub(totalContributedUnits),
            msg.value.div(weiPerUnitRate)
        );

        require(currentContributionUnits != 0);

         
        require(currentContributionUnits >= minContributionUnits || previouslyContributedUnits != 0);

         
        unitContributions[_contributor] = previouslyContributedUnits.add(currentContributionUnits);
        totalContributedUnits = totalContributedUnits.add(currentContributionUnits);

        uint256 currentContributionWei = currentContributionUnits.mul(weiPerUnitRate);
        trustedVault.deposit.value(currentContributionWei)(msg.sender);

         
        if (totalContributedUnits >= minThresholdUnits &&
            trustedVault.state() != Vault.State.Success) {
            trustedVault.saleSuccessful();
        }

         
        uint256 excessWei = msg.value.sub(currentContributionWei);
        if (excessWei > 0) {
            msg.sender.transfer(excessWei);
        }

        emit Contribution(
            _contributor, 
            msg.sender,
            currentContributionUnits, 
            currentContributionWei, 
            excessWei,
            weiPerUnitRate
        );

         
        uint256 tokenAmount = currentContributionUnits.mul(saleTokensPerUnit);
        trustedToken.safeTransfer(_contributor, tokenAmount);
        emit TokensAllocated(_contributor, tokenAmount);
    }

     
     
    function allocateExtraTokens(address _contributor)
        external 
        checkAllowed
    {    
        require(!extraTokensAllocated[_contributor]);
        require(unitContributions[_contributor] != 0);
         
        require(totalContributedUnits < totalSaleCapUnits);

         
        extraTokensAllocated[_contributor] = true;
        uint256 tokenAmount = unitContributions[_contributor].mul(extraTokensPerUnit);
        trustedToken.safeTransfer(_contributor, tokenAmount);

        emit TokensAllocated(_contributor, tokenAmount);
    }

     
     
    function setEndTime(uint256 _endTime) external onlyOwner checkAllowed {
        require(now < _endTime);
        require(getStateStartTime(SALE_ENDED) == 0);
        setStateStartTime(SALE_ENDED, _endTime);
    }

     
     
    function enableRefunds() external onlyOwner {
        trustedVault.enableRefunds();
    }

     
    function endSale() external onlyOwner checkAllowed {
        goToNextState();
    }

     
     
    function transferAllowed(address _from, address)
        external
        view
        returns (bool)
    {
        return _from == address(this) || _from == address(disbursementHandler);
    }

     
     
     
     
    function setupDisbursement(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _duration
    )
        internal 
    {
        require(tokensForSale == 0);
        disbursementHandler.setupDisbursement(
            _beneficiary,
            _tokenAmount,
            now.add(_duration)
        );
    }
   
     
    function wasCapReached(bytes32) internal returns (bool) {
        return totalSaleCapUnits <= totalContributedUnits;
    }

     
    function onSaleEnded() internal {

        trustedToken.transferOwnership(owner); 

        if (totalContributedUnits == 0) {

             
            trustedToken.safeTransfer(trustedVault.trustedWallet(), tokensForSale);

        } else if (totalContributedUnits < minThresholdUnits) {

             
            trustedVault.enableRefunds();

        } else {

             
            extraTokensPerUnit = tokensForSale.div(totalContributedUnits).sub(saleTokensPerUnit);

             
            trustedVault.close();
            trustedVault.transferOwnership(owner);

        }
    }

     
    function min256(uint256 x, uint256 y, uint256 z) internal pure returns (uint256) {
        return Math.min256(x, Math.min256(y, z));
    }

}

 

contract FoamSale is Sale {

    address private constant FOAM_WALLET = 0x3061CFBAe69Bff0f933353cea20de6C89Ab16acc;

    constructor() 
        Sale(
            24000000,  
            90,  
            1,  
            1000000000 * (10 ** 18),  
            0x8dAB5379f7979df2Fac963c69B66a25AcdaADbB7,  
            FOAM_WALLET,  
            1 ether,  
            25000 ether,  
            0,  
            1532803878,  
            "FOAM Token",  
            "FOAM",  
            18,  
            EthPriceFeedI(0x54bF24e1070784D7F0760095932b47CE55eb3A91)  
        )
        public 
    {
         
        setupDisbursement(FOAM_WALLET, 700000000 * (10 ** 18), 1 hours);
    }
}