 

pragma solidity 0.4.19;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

 

 
contract DisbursementHandler is Ownable {
    using SafeMath for uint256;

    struct Disbursement {
         
        uint256 timestamp;

         
        uint256 tokens;
    }

    event LogSetup(address indexed vestor, uint256 timestamp, uint256 tokens);
    event LogWithdraw(address indexed to, uint256 value);

    ERC20 public token;
    uint256 public totalAmount;
    mapping(address => Disbursement[]) public disbursements;
    mapping(address => uint256) public withdrawnTokens;

    function DisbursementHandler(address _token) public {
        token = ERC20(_token);
    }

     
     
     
     
    function setupDisbursement(
        address vestor,
        uint256 tokens,
        uint256 timestamp
    )
        external
        onlyOwner
    {
        require(block.timestamp < timestamp);
        disbursements[vestor].push(Disbursement(timestamp, tokens));
        totalAmount = totalAmount.add(tokens);
        LogSetup(vestor, timestamp, tokens);
    }

     
    function withdraw()
        external
    {
        uint256 withdrawAmount = calcMaxWithdraw(msg.sender);
        require(withdrawAmount != 0);
        withdrawnTokens[msg.sender] = withdrawnTokens[msg.sender].add(withdrawAmount);
        require(token.transfer(msg.sender, withdrawAmount));
        LogWithdraw(msg.sender, withdrawAmount);
    }

     
     
    function calcMaxWithdraw(address beneficiary)
        public
        view
        returns (uint256)
    {
        uint256 maxTokens = 0;

         
        Disbursement[] storage temp = disbursements[beneficiary];
        uint256 tempLength = temp.length;
        for (uint256 i = 0; i < tempLength; i++) {
            if (block.timestamp > temp[i].timestamp) {
                maxTokens = maxTokens.add(temp[i].tokens);
            }
        }

         
        return maxTokens.sub(withdrawnTokens[beneficiary]);
    }
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

 

 

 
contract Vault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Success, Refunding, Closed }

    uint256 public constant DISBURSEMENT_DURATION = 4 weeks;

    mapping (address => uint256) public deposited;
    uint256 public disbursementAmount;  
    address public trustedWallet;  

    uint256 public initialAmount;  

    uint256 public lastDisbursement;  

    uint256 public totalDeposited;  
    uint256 public refundable;  

    uint256 public closingDuration;
    uint256 public closingDeadline;  

    State public state;

    event LogClosed();
    event LogRefundsEnabled();
    event LogRefunded(address indexed contributor, uint256 amount);

    modifier atState(State _state) {
        require(state == _state);
        _;
    }

    function Vault(
        address wallet,
        uint256 _initialAmount,
        uint256 _disbursementAmount,
        uint256 _closingDuration
    ) 
        public 
    {
        require(wallet != address(0));
        require(_disbursementAmount != 0);
        require(_closingDuration != 0);
        trustedWallet = wallet;
        initialAmount = _initialAmount;
        disbursementAmount = _disbursementAmount;
        closingDuration = _closingDuration;
        state = State.Active;
    }

     
    function deposit(address contributor) onlyOwner external payable {
        require(state == State.Active || state == State.Success);
        totalDeposited = totalDeposited.add(msg.value);
        refundable = refundable.add(msg.value);
        deposited[contributor] = deposited[contributor].add(msg.value);
    }

     
    function saleSuccessful() onlyOwner external atState(State.Active){
        state = State.Success;
        refundable = refundable.sub(initialAmount);
        if (initialAmount != 0) {
          trustedWallet.transfer(initialAmount);
        }
    }

     
    function enableRefunds() onlyOwner external {
        state = State.Refunding;
        LogRefundsEnabled();
    }

     
    function refund(address contributor) external atState(State.Refunding) {
        uint256 refundAmount = deposited[contributor].mul(refundable).div(totalDeposited);
        deposited[contributor] = 0;
        contributor.transfer(refundAmount);
        LogRefunded(contributor, refundAmount);
    }

     
    function beginClosingPeriod() external onlyOwner atState(State.Success) {
        require(closingDeadline == 0);
        closingDeadline = now.add(closingDuration);
    }

     
    function close() external atState(State.Success) {
        require(closingDeadline != 0 && closingDeadline <= now);
        state = State.Closed;
        LogClosed();
    }

     
    function sendFundsToWallet() external atState(State.Closed) {
        require(lastDisbursement.add(DISBURSEMENT_DURATION) <= now);

        lastDisbursement = now;
        uint256 amountToSend = Math.min256(address(this).balance, disbursementAmount);
        refundable = refundable.sub(amountToSend);
        trustedWallet.transfer(amountToSend);
    }
}

 

 
contract Whitelistable is Ownable {
    bytes constant PREFIX = "\x19Ethereum Signed Message:\n32";

    address public whitelistAdmin;

     
    mapping(address => bool) public blacklist;

    event LogAdminUpdated(address indexed newAdmin);

    modifier validAdmin(address _admin) {
        require(_admin != 0);
        _;
    }

    modifier onlyAdmin {
        require(msg.sender == whitelistAdmin);
        _;
    }

     
     
    function Whitelistable(address _admin) public validAdmin(_admin) {
        whitelistAdmin = _admin;        
    }

     
     
     
    function changeAdmin(address _admin)
        external
        onlyOwner
        validAdmin(_admin)
    {
        LogAdminUpdated(_admin);
        whitelistAdmin = _admin;
    }

     
     
    function addToBlacklist(address _contributor)
        external
        onlyAdmin
    {
        blacklist[_contributor] = true;
    }

     
     
    function removeFromBlacklist(address _contributor)
        external
        onlyAdmin
    {
        blacklist[_contributor] = false;
    }

     
     
     
     
     
     
     
     
    function checkWhitelisted(
        address contributor,
        uint256 contributionLimit,
        uint256 currentSaleCap,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public view returns(bool) {
        bytes32 prefixed = keccak256(PREFIX, keccak256(contributor, contributionLimit, currentSaleCap));
        return !(blacklist[contributor]) && (whitelistAdmin == ecrecover(prefixed, v, r, s));
    }
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

    event LogTransition(bytes32 stateId, uint256 blockNumber);

     
    modifier checkAllowed {
        conditionalTransitions();
        require(states[currentStateId].allowedFunctions[msg.sig]);
        _;
    }

     
     
    function conditionalTransitions() public {

        bytes32 next = states[currentStateId].nextStateId;
        bool stateChanged;

        while (next != 0) {
             
            stateChanged = false;
            for (uint256 i = 0; i < states[next].startConditions.length; i++) {
                if (states[next].startConditions[i](next)) {
                    goToNextState();
                    next = states[next].nextStateId;
                    stateChanged = true;
                    break;
                }
            }
             
            if (!stateChanged) break;
        }
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

     
     
     
    function allowFunction(bytes32 _stateId, bytes4 _functionSelector) internal {
        states[_stateId].allowedFunctions[_functionSelector] = true;
    }

     
    function goToNextState() internal {
        bytes32 next = states[currentStateId].nextStateId;
        require(next != 0);

        currentStateId = next;
        for (uint256 i = 0; i < states[next].transitionCallbacks.length; i++) {
            states[next].transitionCallbacks[i]();
        }

        LogTransition(next, block.number);
    }

     
     
     
    function addStartCondition(bytes32 _stateId, function(bytes32) internal returns(bool) _condition) internal {
        states[_stateId].startConditions.push(_condition);
    }

     
     
     
    function addCallback(bytes32 _stateId, function() internal _callback) internal {
        states[_stateId].transitionCallbacks.push(_callback);
    }

}

 

 
contract TimedStateMachine is StateMachine {

    event LogSetStateStartTime(bytes32 indexed _stateId, uint256 _startTime);

     
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

        LogSetStateStartTime(_stateId, _timestamp);
    }

    function hasStartTimePassed(bytes32 _stateId) internal returns(bool) {
        return startTime[_stateId] <= block.timestamp;
    }

}

 

 
contract TokenControllerI {

     
     
    function transferAllowed(address _from, address _to) external view returns (bool);
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
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

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
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

     
     
    function transfer(address _to, uint256 _value) isAllowed(msg.sender, _to) public returns (bool) {        
        return super.transfer(_to, _value);
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) isAllowed(_from, _to) public returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }
}

 

contract DetailedERC20 is ERC20 {
  string public name;
  string public symbol;
  uint8 public decimals;

  function DetailedERC20(string _name, string _symbol, uint8 _decimals) public {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }
}

 

 
contract Token is ControllableToken, DetailedERC20 {

	 
    function Token(
        uint256 _supply,
        string _name,
        string _symbol,
        uint8 _decimals
    ) DetailedERC20(_name, _symbol, _decimals) public {
        require(_supply != 0);
        totalSupply_ = _supply;
        balances[msg.sender] = _supply;
        Transfer(address(0), msg.sender, _supply);   
    }
}

 

 
contract Sale is Ownable, Whitelistable, TimedStateMachine, TokenControllerI {
    using SafeMath for uint256;

     
    bytes32 private constant SETUP = 'setup';
    bytes32 private constant FREEZE = 'freeze';
    bytes32 private constant SALE_IN_PROGRESS = 'saleInProgress';
    bytes32 private constant SALE_ENDED = 'saleEnded';
    bytes32[] public states = [SETUP, FREEZE, SALE_IN_PROGRESS, SALE_ENDED];

     
    mapping(address => uint256) public contributions;
     
    mapping(address => bool) public hasContributed;

    DisbursementHandler public disbursementHandler;

    uint256 public weiContributed = 0;
    uint256 public totalSaleCap;
    uint256 public minContribution;
    uint256 public minThreshold;

     
    uint256 public tokensPerWei;
    uint256 public tokensForSale;

    Token public trustedToken;
    Vault public trustedVault;

    event LogContribution(address indexed contributor, uint256 value, uint256 excess);
    event LogTokensAllocated(address indexed contributor, uint256 amount);

    function Sale(
        uint256 _totalSaleCap,
        uint256 _minContribution,
        uint256 _minThreshold,
        uint256 _maxTokens,
        address _whitelistAdmin,
        address _wallet,
        uint256 _closingDuration,
        uint256 _vaultInitialAmount,
        uint256 _vaultDisbursementAmount,
        uint256 _startTime,
        string _tokenName,
        string _tokenSymbol,
        uint8 _tokenDecimals
    ) 
        Whitelistable(_whitelistAdmin)
        public 
    {
        require(_totalSaleCap != 0);
        require(_maxTokens != 0);
        require(_wallet != 0);
        require(_minThreshold <= _totalSaleCap);
        require(_vaultInitialAmount <= _minThreshold);
        require(now < _startTime);

        totalSaleCap = _totalSaleCap;
        minContribution = _minContribution;
        minThreshold = _minThreshold;

         
        trustedToken = new Token(_maxTokens, _tokenName, _tokenSymbol, _tokenDecimals);
        disbursementHandler = new DisbursementHandler(trustedToken);

        trustedToken.setController(this);

        trustedVault = new Vault(
            _wallet,
            _vaultInitialAmount,
            _vaultDisbursementAmount,  
            _closingDuration
        );

         
        setStates(states);

        allowFunction(SETUP, this.setup.selector);
        allowFunction(FREEZE, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.setEndTime.selector);
        allowFunction(SALE_IN_PROGRESS, this.contribute.selector);
        allowFunction(SALE_IN_PROGRESS, this.endSale.selector);
        allowFunction(SALE_ENDED, this.allocateTokens.selector);

         
        addStartCondition(SALE_ENDED, wasCapReached);

         
        addCallback(SALE_ENDED, onSaleEnded);

         
        setStateStartTime(SALE_IN_PROGRESS, _startTime);
    }

     
     
    function setup() public onlyOwner checkAllowed {
        require(trustedToken.transfer(disbursementHandler, disbursementHandler.totalAmount()));
        tokensForSale = trustedToken.balanceOf(this);       
        require(tokensForSale >= totalSaleCap);

         
        goToNextState();
    }

     
    function contribute(uint256 contributionLimit, uint256 currentSaleCap, uint8 v, bytes32 r, bytes32 s) 
        external 
        payable
        checkAllowed 
    {
         
        require(currentSaleCap <= totalSaleCap);
        require(weiContributed < currentSaleCap);
        require(checkWhitelisted(msg.sender, contributionLimit, currentSaleCap, v, r, s));

        uint256 current = contributions[msg.sender];
        require(current < contributionLimit);

         
        uint256 remaining = Math.min256(contributionLimit.sub(current), currentSaleCap.sub(weiContributed));

         
        uint256 contribution = Math.min256(msg.value, remaining);

         
        uint256 totalContribution = current.add(contribution);
        require(totalContribution >= minContribution);

        contributions[msg.sender] = totalContribution;
        hasContributed[msg.sender] = true;

        weiContributed = weiContributed.add(contribution);

        trustedVault.deposit.value(contribution)(msg.sender);

        if (weiContributed >= minThreshold && trustedVault.state() != Vault.State.Success) trustedVault.saleSuccessful();

         
        uint256 excess = msg.value.sub(contribution);
        if (excess > 0) msg.sender.transfer(excess);

        LogContribution(msg.sender, contribution, excess);

        assert(totalContribution <= contributionLimit);
    }

     
     
    function setEndTime(uint256 _endTime) external onlyOwner checkAllowed {
        require(now < _endTime);
        require(getStateStartTime(SALE_ENDED) == 0);
        setStateStartTime(SALE_ENDED, _endTime);
    }

     
     
    function allocateTokens(address _contributor) external checkAllowed {
        require(contributions[_contributor] != 0);

         
        uint256 amount = contributions[_contributor].mul(tokensPerWei);

         
        contributions[_contributor] = 0;

        require(trustedToken.transfer(_contributor, amount));

        LogTokensAllocated(_contributor, amount);
    }

     
    function endSale() external onlyOwner checkAllowed {
        goToNextState();
    }

     
     
    function transferAllowed(address _from, address) external view returns (bool) {
        return _from == address(this) || _from == address(disbursementHandler);
    }

     
     
     
     
    function setupDisbursement(address _beneficiary, uint256 _amount, uint256 _duration) internal {
        require(tokensForSale == 0);
        disbursementHandler.setupDisbursement(_beneficiary, _amount, now.add(_duration));
    }
   
     
    function wasCapReached(bytes32) internal returns (bool) {
        return totalSaleCap <= weiContributed;
    }

     
    function onSaleEnded() internal {
         
        if (weiContributed < minThreshold) {
            trustedVault.enableRefunds();
        } else {
            trustedVault.beginClosingPeriod();
            tokensPerWei = tokensForSale.div(weiContributed);
        }

        trustedToken.transferOwnership(owner); 
        trustedVault.transferOwnership(owner);
    }

}

 

contract VirtuePokerSale is Sale {

    function VirtuePokerSale() 
        Sale(
            25000 ether,  
            1 ether,  
            12000 ether,  
            500000000 * (10 ** 18),  
            0x13ebf15f2e32d05ea944927ef5e6a3cad8187440,  
            0xaa0aE3459F9f3472d1237015CaFC1aAfc6F03C63,  
            28 days,  
            12000 ether,  
            25000 ether,  
            1524218400,  
            "Virtue Player Points",  
            "VPP",  
            18  
        )
        public 
    {
         
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 1 years);
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 2 years);
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 3 years);
        setupDisbursement(0x2e286dA6Ee6E8e0Afb2c1CfADb1B74669a3cD642, 12500000 * (10 ** 18), 4 years);

         
        setupDisbursement(0xaa0aE3459F9f3472d1237015CaFC1aAfc6F03C63, 250000000 * (10 ** 18), 1 days);

         
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 0.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 1 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 1.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 2 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 2.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 3 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 3.5 years);
        setupDisbursement(0x5ca71f050865092468CF8184D09e087F3DC58e31, 8000000 * (10 ** 18), 4 years);

        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 0.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 1 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 1.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 2 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 2.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 3 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 3.5 years);
        setupDisbursement(0x35fc8cA81E1b5992a0727c6Aa87DbeB8cca42094, 2250000 * (10 ** 18), 4 years);

        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 0.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 1 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 1.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 2 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 2.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 3 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 3.5 years);
        setupDisbursement(0xce3EFA6763e23DF21aF74DA46C6489736F96d4B6, 2250000 * (10 ** 18), 4 years);
    }
}