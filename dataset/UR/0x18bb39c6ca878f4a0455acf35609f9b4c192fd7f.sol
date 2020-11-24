 

 
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
 
 
 
 
contract Ownable {
     
    address public owner;
    address public newOwner;

     
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    constructor() public {
        owner = msg.sender;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        newOwner = _newOwner;

    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}
 
 
 
 
contract OpenZeppelinERC20 is StandardToken, Ownable {
    using SafeMath for uint256;

    uint8 public decimals;
    string public name;
    string public symbol;
    string public standard;

    constructor(
        uint256 _totalSupply,
        string _tokenName,
        uint8 _decimals,
        string _tokenSymbol,
        bool _transferAllSupplyToOwner
    ) public {
        standard = 'ERC20 0.1';
        totalSupply_ = _totalSupply;

        if (_transferAllSupplyToOwner) {
            balances[msg.sender] = _totalSupply;
        } else {
            balances[this] = _totalSupply;
        }

        name = _tokenName;
         
        symbol = _tokenSymbol;
         
        decimals = _decimals;
    }

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
 
 
 
 
contract MintableToken is BasicToken, Ownable {

    using SafeMath for uint256;

    uint256 public maxSupply;
    bool public allowedMinting;
    mapping(address => bool) public mintingAgents;
    mapping(address => bool) public stateChangeAgents;

    event Mint(address indexed holder, uint256 tokens);

    modifier onlyMintingAgents () {
        require(mintingAgents[msg.sender]);
        _;
    }

    modifier onlyStateChangeAgents () {
        require(stateChangeAgents[msg.sender]);
        _;
    }

    constructor(uint256 _maxSupply, uint256 _mintedSupply, bool _allowedMinting) public {
        maxSupply = _maxSupply;
        totalSupply_ = totalSupply_.add(_mintedSupply);
        allowedMinting = _allowedMinting;
        mintingAgents[msg.sender] = true;
    }

     
    function mint(address _holder, uint256 _tokens) public onlyMintingAgents() {
        require(allowedMinting == true && totalSupply_.add(_tokens) <= maxSupply);

        totalSupply_ = totalSupply_.add(_tokens);

        balances[_holder] = balanceOf(_holder).add(_tokens);

        if (totalSupply_ == maxSupply) {
            allowedMinting = false;
        }
        emit Mint(_holder, _tokens);
    }

     
    function disableMinting() public onlyStateChangeAgents() {
        allowedMinting = false;
    }

     
    function updateMintingAgent(address _agent, bool _status) public onlyOwner {
        mintingAgents[_agent] = _status;
    }

     
    function updateStateChangeAgent(address _agent, bool _status) public onlyOwner {
        stateChangeAgents[_agent] = _status;
    }

     
    function availableTokens() public view returns (uint256 tokens) {
        return maxSupply.sub(totalSupply_);
    }
}
 
 
 
 
contract MintableBurnableToken is MintableToken, BurnableToken {

    mapping (address => bool) public burnAgents;

    modifier onlyBurnAgents () {
        require(burnAgents[msg.sender]);
        _;
    }

    event Burn(address indexed burner, uint256 value);

    constructor(
        uint256 _maxSupply,
        uint256 _mintedSupply,
        bool _allowedMinting
    ) public MintableToken(
        _maxSupply,
        _mintedSupply,
        _allowedMinting
    ) {

    }

     
    function updateBurnAgent(address _agent, bool _status) public onlyOwner {
        burnAgents[_agent] = _status;
    }

    function burnByAgent(address _holder, uint256 _tokensToBurn) public onlyBurnAgents() returns (uint256) {
        if (_tokensToBurn == 0) {
            _tokensToBurn = balanceOf(_holder);
        }
        _burn(_holder, _tokensToBurn);

        return _tokensToBurn;
    }

    function _burn(address _who, uint256 _value) internal {
        require(_value <= balances[_who]);
         
         

        balances[_who] = balances[_who].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        maxSupply = maxSupply.sub(_value);
        emit Burn(_who, _value);
        emit Transfer(_who, address(0), _value);
    }
}
 
 
 
 
contract TimeLocked {
    uint256 public time;
    mapping(address => bool) public excludedAddresses;

    modifier isTimeLocked(address _holder, bool _timeLocked) {
        bool locked = (block.timestamp < time);
        require(excludedAddresses[_holder] == true || locked == _timeLocked);
        _;
    }

    constructor(uint256 _time) public {
        time = _time;
    }

    function updateExcludedAddress(address _address, bool _status) public;
}
 
 
 
 
contract TimeLockedToken is TimeLocked, StandardToken {

    constructor(uint256 _time) public TimeLocked(_time) {}

    function transfer(address _to, uint256 _tokens) public isTimeLocked(msg.sender, false) returns (bool) {
        return super.transfer(_to, _tokens);
    }

    function transferFrom(
        address _holder,
        address _to,
        uint256 _tokens
    ) public isTimeLocked(_holder, false) returns (bool) {
        return super.transferFrom(_holder, _to, _tokens);
    }
}
contract CHLToken is OpenZeppelinERC20, MintableBurnableToken, TimeLockedToken {

    CHLCrowdsale public crowdsale;

    bool public isSoftCapAchieved;

     
    constructor(uint256 _unlockTokensTime) public
    OpenZeppelinERC20(0, 'ChelleCoin', 18, 'CHL', false)
    MintableBurnableToken(59500000e18, 0, true)
    TimeLockedToken(_unlockTokensTime) {

    }

    function updateMaxSupply(uint256 _newMaxSupply) public onlyOwner {
        require(_newMaxSupply > 0);
        maxSupply = _newMaxSupply;
    }

    function updateExcludedAddress(address _address, bool _status) public onlyOwner {
        excludedAddresses[_address] = _status;
    }

    function setCrowdSale(address _crowdsale) public onlyOwner {
        require(_crowdsale != address(0));
        crowdsale = CHLCrowdsale(_crowdsale);
    }

    function setUnlockTime(uint256 _unlockTokensTime) public onlyStateChangeAgents {
        time = _unlockTokensTime;
    }

    function setIsSoftCapAchieved() public onlyStateChangeAgents {
        isSoftCapAchieved = true;
    }

    function transfer(address _to, uint256 _tokens) public returns (bool) {
        require(true == isTransferAllowed(msg.sender, _tokens));
        return super.transfer(_to, _tokens);
    }

    function transferFrom(address _holder, address _to, uint256 _tokens) public returns (bool) {
        require(true == isTransferAllowed(_holder, _tokens));
        return super.transferFrom(_holder, _to, _tokens);
    }

    function isTransferAllowed(address _address, uint256 _value) public view returns (bool) {
        if (excludedAddresses[_address] == true) {
            return true;
        }

        if (!isSoftCapAchieved && (address(crowdsale) == address(0) || false == crowdsale.isSoftCapAchieved(0))) {
            return false;
        }

        return true;
    }

    function burnUnsoldTokens(uint256 _tokensToBurn) public onlyBurnAgents() returns (uint256) {
        require(totalSupply_.add(_tokensToBurn) <= maxSupply);

        maxSupply = maxSupply.sub(_tokensToBurn);

        emit Burn(address(0), _tokensToBurn);

        return _tokensToBurn;
    }

}
 
 
 
 
contract Agent {
    using SafeMath for uint256;

    function isInitialized() public constant returns (bool) {
        return false;
    }
}
 
 
 
 
contract CrowdsaleAgent is Agent {


    Crowdsale public crowdsale;
    bool public _isInitialized;

    modifier onlyCrowdsale() {
        require(msg.sender == address(crowdsale));
        _;
    }

    constructor(Crowdsale _crowdsale) public {
        crowdsale = _crowdsale;

        if (address(0) != address(_crowdsale)) {
            _isInitialized = true;
        } else {
            _isInitialized = false;
        }
    }

    function isInitialized() public constant returns (bool) {
        return _isInitialized;
    }

    function onContribution(address _contributor, uint256 _weiAmount, uint256 _tokens, uint256 _bonus)
        public onlyCrowdsale();

    function onStateChange(Crowdsale.State _state) public onlyCrowdsale();

    function onRefund(address _contributor, uint256 _tokens) public onlyCrowdsale() returns (uint256 burned);
}
 
 
 
 
 
contract MintableCrowdsaleOnSuccessAgent is CrowdsaleAgent {

    Crowdsale public crowdsale;
    MintableToken public token;
    bool public _isInitialized;

    constructor(Crowdsale _crowdsale, MintableToken _token) public CrowdsaleAgent(_crowdsale) {
        crowdsale = _crowdsale;
        token = _token;

        if (address(0) != address(_token) &&
        address(0) != address(_crowdsale)) {
            _isInitialized = true;
        } else {
            _isInitialized = false;
        }
    }

     
     
    function isInitialized() public constant returns (bool) {
        return _isInitialized;
    }

     
    function onContribution(address _contributor, uint256 _weiAmount, uint256 _tokens, uint256 _bonus)
    public onlyCrowdsale() {
        _contributor = _contributor;
        _weiAmount = _weiAmount;
        _tokens = _tokens;
        _bonus = _bonus;
         
    }

     
     
     
    function onStateChange(Crowdsale.State _state) public onlyCrowdsale() {
        if (_state == Crowdsale.State.Success) {
            token.disableMinting();
        }
    }

    function onRefund(address _contributor, uint256 _tokens) public onlyCrowdsale() returns (uint256 burned) {
        _contributor = _contributor;
        _tokens = _tokens;
    }
}
contract CHLAgent is MintableCrowdsaleOnSuccessAgent, Ownable {

    CHLPricingStrategy public strategy;
    CHLCrowdsale public crowdsale;
    CHLAllocation public allocation;

    bool public isEndProcessed;

    constructor(
        CHLCrowdsale _crowdsale,
        CHLToken _token,
        CHLPricingStrategy _strategy,
        CHLAllocation _allocation
    ) public MintableCrowdsaleOnSuccessAgent(_crowdsale, _token) {
        strategy = _strategy;
        crowdsale = _crowdsale;
        allocation = _allocation;
    }

     
    function setPricingStrategy(CHLPricingStrategy _strategy) public onlyOwner {
        strategy = _strategy;
    }

     
    function setAllocation(CHLAllocation _allocation) public onlyOwner {
        allocation = _allocation;
    }

    function burnUnsoldTokens(uint256 _tierId) public onlyOwner {
        uint256 tierUnsoldTokensAmount = strategy.getTierUnsoldTokens(_tierId);
        require(tierUnsoldTokensAmount > 0);

        CHLToken(token).burnUnsoldTokens(tierUnsoldTokensAmount);
    }

     
    function onContribution(
        address,
        uint256 _tierId,
        uint256 _tokens,
        uint256 _bonus
    ) public onlyCrowdsale() {
        strategy.updateTierTokens(_tierId, _tokens, _bonus);
    }

    function onStateChange(Crowdsale.State _state) public onlyCrowdsale() {
        CHLToken chlToken = CHLToken(token);
        if (
            chlToken.isSoftCapAchieved() == false
            && (_state == Crowdsale.State.Success || _state == Crowdsale.State.Finalized)
            && crowdsale.isSoftCapAchieved(0)
        ) {
            chlToken.setIsSoftCapAchieved();
        }

        if (_state > Crowdsale.State.InCrowdsale && isEndProcessed == false) {
            allocation.allocateFoundersTokens(strategy.getSaleEndDate());
        }
    }

    function onRefund(address _contributor, uint256 _tokens) public onlyCrowdsale() returns (uint256 burned) {
        burned = CHLToken(token).burnByAgent(_contributor, _tokens);
    }

    function updateStateWithPrivateSale(
        uint256 _tierId,
        uint256 _tokensAmount,
        uint256 _usdAmount
    ) public {
        require(msg.sender == address(allocation));

        strategy.updateMaxTokensCollected(_tierId, _tokensAmount);
        crowdsale.updateStatsVars(_usdAmount, _tokensAmount);
    }

    function updateLockPeriod(uint256 _time) public {
        require(msg.sender == address(strategy));
        CHLToken(token).setUnlockTime(_time.add(12 weeks));
    }

}
 
 
 
 
contract TokenAllocator is Ownable {


    mapping(address => bool) public crowdsales;

    modifier onlyCrowdsale() {
        require(crowdsales[msg.sender]);
        _;
    }

    function addCrowdsales(address _address) public onlyOwner {
        crowdsales[_address] = true;
    }

    function removeCrowdsales(address _address) public onlyOwner {
        crowdsales[_address] = false;
    }

    function isInitialized() public constant returns (bool) {
        return false;
    }

    function allocate(address _holder, uint256 _tokens) public onlyCrowdsale() {
        internalAllocate(_holder, _tokens);
    }

    function tokensAvailable() public constant returns (uint256);

    function internalAllocate(address _holder, uint256 _tokens) internal onlyCrowdsale();
}
 
 
 
 
contract MintableTokenAllocator is TokenAllocator {

    using SafeMath for uint256;

    MintableToken public token;

    constructor(MintableToken _token) public {
        require(address(0) != address(_token));
        token = _token;
    }

     
    function tokensAvailable() public constant returns (uint256) {
        return token.availableTokens();
    }

     
    function allocate(address _holder, uint256 _tokens) public onlyCrowdsale() {
        internalAllocate(_holder, _tokens);
    }

     
     
    function isInitialized() public constant returns (bool) {
        return token.mintingAgents(this);
    }

     
    function setToken(MintableToken _token) public onlyOwner {
        token = _token;
    }

    function internalAllocate(address _holder, uint256 _tokens) internal {
        token.mint(_holder, _tokens);
    }

}
 
 
 
 
contract ContributionForwarder {

    using SafeMath for uint256;

    uint256 public weiCollected;
    uint256 public weiForwarded;

    event ContributionForwarded(address receiver, uint256 weiAmount);

    function isInitialized() public constant returns (bool) {
        return false;
    }

     
    function forward() public payable {
        require(msg.value > 0);

        weiCollected += msg.value;

        internalForward();
    }

    function internalForward() internal;
}
 
 
 
 
contract DistributedDirectContributionForwarder is ContributionForwarder {
    Receiver[] public receivers;
    uint256 public proportionAbsMax;
    bool public isInitialized_;

    struct Receiver {
        address receiver;
        uint256 proportion;  
        uint256 forwardedWei;
    }

     
    constructor(uint256 _proportionAbsMax, address[] _receivers, uint256[] _proportions) public {
        proportionAbsMax = _proportionAbsMax;

        require(_receivers.length == _proportions.length);

        require(_receivers.length > 0);

        uint256 totalProportion;

        for (uint256 i = 0; i < _receivers.length; i++) {
            uint256 proportion = _proportions[i];

            totalProportion = totalProportion.add(proportion);

            receivers.push(Receiver(_receivers[i], proportion, 0));
        }

        require(totalProportion == proportionAbsMax);
        isInitialized_ = true;
    }

     
     
    function isInitialized() public constant returns (bool) {
        return isInitialized_;
    }

    function internalForward() internal {
        uint256 transferred;

        for (uint256 i = 0; i < receivers.length; i++) {
            Receiver storage receiver = receivers[i];

            uint256 value = msg.value.mul(receiver.proportion).div(proportionAbsMax);

            if (i == receivers.length - 1) {
                value = msg.value.sub(transferred);
            }

            transferred = transferred.add(value);

            receiver.receiver.transfer(value);

            emit ContributionForwarded(receiver.receiver, value);
        }

        weiForwarded = weiForwarded.add(transferred);
    }
}
contract Crowdsale {

    uint256 public tokensSold;

    enum State {Unknown, Initializing, BeforeCrowdsale, InCrowdsale, Success, Finalized, Refunding}

    function externalContribution(address _contributor, uint256 _wei) public payable;

    function contribute(uint8 _v, bytes32 _r, bytes32 _s) public payable;

    function updateState() public;

    function internalContribution(address _contributor, uint256 _wei) internal;

    function getState() public view returns (State);

}
 
 
 
contract CrowdsaleImpl is Crowdsale, Ownable {

    using SafeMath for uint256;

    State public currentState;
    TokenAllocator public allocator;
    ContributionForwarder public contributionForwarder;
    PricingStrategy public pricingStrategy;
    CrowdsaleAgent public crowdsaleAgent;
    bool public finalized;
    uint256 public startDate;
    uint256 public endDate;
    bool public allowWhitelisted;
    bool public allowSigned;
    bool public allowAnonymous;
    mapping(address => bool) public whitelisted;
    mapping(address => bool) public signers;
    mapping(address => bool) public externalContributionAgents;

    event Contribution(address _contributor, uint256 _wei, uint256 _tokensExcludingBonus, uint256 _bonus);

    constructor(
        TokenAllocator _allocator,
        ContributionForwarder _contributionForwarder,
        PricingStrategy _pricingStrategy,
        uint256 _startDate,
        uint256 _endDate,
        bool _allowWhitelisted,
        bool _allowSigned,
        bool _allowAnonymous
    ) public {
        allocator = _allocator;
        contributionForwarder = _contributionForwarder;
        pricingStrategy = _pricingStrategy;

        startDate = _startDate;
        endDate = _endDate;

        allowWhitelisted = _allowWhitelisted;
        allowSigned = _allowSigned;
        allowAnonymous = _allowAnonymous;

        currentState = State.Unknown;
    }

     
    function() public payable {
        require(allowWhitelisted || allowAnonymous);

        if (!allowAnonymous) {
            if (allowWhitelisted) {
                require(whitelisted[msg.sender]);
            }
        }

        internalContribution(msg.sender, msg.value);
    }

     
    function setCrowdsaleAgent(CrowdsaleAgent _crowdsaleAgent) public onlyOwner {
        crowdsaleAgent = _crowdsaleAgent;
    }

     
    function externalContribution(address _contributor, uint256 _wei) public payable {
        require(externalContributionAgents[msg.sender]);
        internalContribution(_contributor, _wei);
    }

     
    function addExternalContributor(address _contributor) public onlyOwner {
        externalContributionAgents[_contributor] = true;
    }

     
    function removeExternalContributor(address _contributor) public onlyOwner {
        externalContributionAgents[_contributor] = false;
    }

     
    function updateWhitelist(address _address, bool _status) public onlyOwner {
        whitelisted[_address] = _status;
    }

     
    function addSigner(address _signer) public onlyOwner {
        signers[_signer] = true;
    }

     
    function removeSigner(address _signer) public onlyOwner {
        signers[_signer] = false;
    }

     
    function contribute(uint8 _v, bytes32 _r, bytes32 _s) public payable {
        address recoveredAddress = verify(msg.sender, _v, _r, _s);
        require(signers[recoveredAddress]);
        internalContribution(msg.sender, msg.value);
    }

     
    function updateState() public {
        State state = getState();

        if (currentState != state) {
            if (crowdsaleAgent != address(0)) {
                crowdsaleAgent.onStateChange(state);
            }

            currentState = state;
        }
    }

    function internalContribution(address _contributor, uint256 _wei) internal {
        require(getState() == State.InCrowdsale);

        uint256 tokensAvailable = allocator.tokensAvailable();
        uint256 collectedWei = contributionForwarder.weiCollected();

        uint256 tokens;
        uint256 tokensExcludingBonus;
        uint256 bonus;

        (tokens, tokensExcludingBonus, bonus) = pricingStrategy.getTokens(
            _contributor, tokensAvailable, tokensSold, _wei, collectedWei);

        require(tokens > 0 && tokens <= tokensAvailable);
        tokensSold = tokensSold.add(tokens);

        allocator.allocate(_contributor, tokens);

        if (msg.value > 0) {
            contributionForwarder.forward.value(msg.value)();
        }

        emit Contribution(_contributor, _wei, tokensExcludingBonus, bonus);
    }

     
    function verify(address _sender, uint8 _v, bytes32 _r, bytes32 _s) public view returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(this, _sender));

        bytes memory prefix = '\x19Ethereum Signed Message:\n32';

        return ecrecover(keccak256(abi.encodePacked(prefix, hash)), _v, _r, _s);
    }

     
    function getState() public view returns (State) {
        if (finalized) {
            return State.Finalized;
        } else if (allocator.isInitialized() == false) {
            return State.Initializing;
        } else if (contributionForwarder.isInitialized() == false) {
            return State.Initializing;
        } else if (pricingStrategy.isInitialized() == false) {
            return State.Initializing;
        } else if (block.timestamp < startDate) {
            return State.BeforeCrowdsale;
        } else if (block.timestamp >= startDate && block.timestamp <= endDate) {
            return State.InCrowdsale;
        } else if (block.timestamp > endDate) {
            return State.Success;
        }

        return State.Unknown;
    }
}
 
 
 
 
contract HardCappedCrowdsale is CrowdsaleImpl {

    using SafeMath for uint256;

    uint256 public hardCap;

    constructor(
        TokenAllocator _allocator,
        ContributionForwarder _contributionForwarder,
        PricingStrategy _pricingStrategy,
        uint256 _startDate,
        uint256 _endDate,
        bool _allowWhitelisted,
        bool _allowSigned,
        bool _allowAnonymous,
        uint256 _hardCap
    ) public CrowdsaleImpl(
        _allocator,
        _contributionForwarder,
        _pricingStrategy,
        _startDate,
        _endDate,
        _allowWhitelisted,
        _allowSigned,
        _allowAnonymous
    ) {
        hardCap = _hardCap;
    }

     
    function getState() public view returns (State) {
        State state = super.getState();

        if (state == State.InCrowdsale) {
            if (isHardCapAchieved(0)) {
                return State.Success;
            }
        }

        return state;
    }

    function isHardCapAchieved(uint256 _value) public view returns (bool) {
        if (hardCap <= tokensSold.add(_value)) {
            return true;
        }
        return false;
    }

    function internalContribution(address _contributor, uint256 _wei) internal {
        require(getState() == State.InCrowdsale);

        uint256 tokensAvailable = allocator.tokensAvailable();
        uint256 collectedWei = contributionForwarder.weiCollected();

        uint256 tokens;
        uint256 tokensExcludingBonus;
        uint256 bonus;

        (tokens, tokensExcludingBonus, bonus) = pricingStrategy.getTokens(
            _contributor, tokensAvailable, tokensSold, _wei, collectedWei);

        require(tokens <= tokensAvailable && tokens > 0 && false == isHardCapAchieved(tokens.sub(1)));

        tokensSold = tokensSold.add(tokens);

        allocator.allocate(_contributor, tokens);

        if (msg.value > 0) {
            contributionForwarder.forward.value(msg.value)();
        }
        crowdsaleAgent.onContribution(_contributor, _wei, tokensExcludingBonus, bonus);
        emit Contribution(_contributor, _wei, tokensExcludingBonus, bonus);
    }
}
 
 
 
 
contract RefundableCrowdsale is HardCappedCrowdsale {

    using SafeMath for uint256;

    uint256 public softCap;
    mapping(address => uint256) public contributorsWei;
    address[] public contributors;

    event Refund(address _holder, uint256 _wei, uint256 _tokens);

    constructor(
        TokenAllocator _allocator,
        ContributionForwarder _contributionForwarder,
        PricingStrategy _pricingStrategy,
        uint256 _startDate,
        uint256 _endDate,
        bool _allowWhitelisted,
        bool _allowSigned,
        bool _allowAnonymous,
        uint256 _softCap,
        uint256 _hardCap

    ) public HardCappedCrowdsale(
        _allocator, _contributionForwarder, _pricingStrategy,
        _startDate, _endDate,
        _allowWhitelisted, _allowSigned, _allowAnonymous, _hardCap
    ) {
        softCap = _softCap;
    }

     
    function refund() public {
        internalRefund(msg.sender);
    }

     
    function delegatedRefund(address _address) public {
        internalRefund(_address);
    }

    function internalContribution(address _contributor, uint256 _wei) internal {
        require(block.timestamp >= startDate && block.timestamp <= endDate);

        uint256 tokensAvailable = allocator.tokensAvailable();
        uint256 collectedWei = contributionForwarder.weiCollected();

        uint256 tokens;
        uint256 tokensExcludingBonus;
        uint256 bonus;

        (tokens, tokensExcludingBonus, bonus) = pricingStrategy.getTokens(
            _contributor, tokensAvailable, tokensSold, _wei, collectedWei);

        require(tokens <= tokensAvailable && tokens > 0 && hardCap > tokensSold.add(tokens));

        tokensSold = tokensSold.add(tokens);

        allocator.allocate(_contributor, tokens);

         
        if (isSoftCapAchieved(0)) {
            if (msg.value > 0) {
                contributionForwarder.forward.value(address(this).balance)();
            }
        } else {
             
            if (contributorsWei[_contributor] == 0) {
                contributors.push(_contributor);
            }
            contributorsWei[_contributor] = contributorsWei[_contributor].add(msg.value);
        }
        crowdsaleAgent.onContribution(_contributor, _wei, tokensExcludingBonus, bonus);
        emit Contribution(_contributor, _wei, tokensExcludingBonus, bonus);
    }

    function internalRefund(address _holder) internal {
        updateState();
        require(block.timestamp > endDate);
        require(!isSoftCapAchieved(0));
        require(crowdsaleAgent != address(0));

        uint256 value = contributorsWei[_holder];

        require(value > 0);

        contributorsWei[_holder] = 0;
        uint256 burnedTokens = crowdsaleAgent.onRefund(_holder, 0);

        _holder.transfer(value);

        emit Refund(_holder, value, burnedTokens);
    }

     
    function getState() public view returns (State) {
        State state = super.getState();

        if (state == State.Success) {
            if (!isSoftCapAchieved(0)) {
                return State.Refunding;
            }
        }

        return state;
    }

    function isSoftCapAchieved(uint256 _value) public view returns (bool) {
        if (softCap <= tokensSold.add(_value)) {
            return true;
        }
        return false;
    }
}
contract CHLCrowdsale is RefundableCrowdsale {

    uint256 public maxSaleSupply = 38972500e18;

    uint256 public usdCollected;

    address public processingFeeAddress;
    uint256 public percentageAbsMax = 1000;
    uint256 public processingFeePercentage = 25;

    event ProcessingFeeAllocation(address _contributor, uint256 _feeAmount);

    event Contribution(address _contributor, uint256 _usdAmount, uint256 _tokensExcludingBonus, uint256 _bonus);

    constructor(
        MintableTokenAllocator _allocator,
        DistributedDirectContributionForwarder _contributionForwarder,
        CHLPricingStrategy _pricingStrategy,
        uint256 _startTime,
        uint256 _endTime,
        address _processingFeeAddress
    ) public RefundableCrowdsale(
        _allocator,
        _contributionForwarder,
        _pricingStrategy,
        _startTime,
        _endTime,
        true,
        true,
        false,
        10000000e5, 
        102860625e5 
    ) {
        require(_processingFeeAddress != address(0));
        processingFeeAddress = _processingFeeAddress;
    }

    function() public payable {
        require(allowWhitelisted || allowAnonymous);

        if (!allowAnonymous) {
            if (allowWhitelisted) {
                require(whitelisted[msg.sender]);
            }
        }

        internalContribution(
            msg.sender,
            CHLPricingStrategy(pricingStrategy).getUSDAmountByWeis(msg.value)
        );
    }

     
    function contribute(uint8 _v, bytes32 _r, bytes32 _s) public payable {
        address recoveredAddress = verify(msg.sender, _v, _r, _s);
        require(signers[recoveredAddress]);
        internalContribution(
            msg.sender,
            CHLPricingStrategy(pricingStrategy).getUSDAmountByWeis(msg.value)
        );
    }

     
    function externalContribution(address _contributor, uint256 _usdAmount) public payable {
        require(externalContributionAgents[msg.sender]);
        internalContribution(_contributor, _usdAmount);
    }

    function updateState() public {
        (startDate, endDate) = CHLPricingStrategy(pricingStrategy).getActualDates();
        super.updateState();
    }

    function isHardCapAchieved(uint256 _value) public view returns (bool) {
        if (hardCap <= usdCollected.add(_value)) {
            return true;
        }
        return false;
    }

    function isSoftCapAchieved(uint256 _value) public view returns (bool) {
        if (softCap <= usdCollected.add(_value)) {
            return true;
        }
        return false;
    }

    function getUnsoldTokensAmount() public view returns (uint256) {
        return maxSaleSupply.sub(tokensSold);
    }

    function updateStatsVars(uint256 _usdAmount, uint256 _tokensAmount) public {
        require(msg.sender == address(crowdsaleAgent) && _tokensAmount > 0);

        tokensSold = tokensSold.add(_tokensAmount);
        usdCollected = usdCollected.add(_usdAmount);
    }

    function internalContribution(address _contributor, uint256 _usdAmount) internal {
        updateState();

        require(currentState == State.InCrowdsale);

        CHLPricingStrategy pricing = CHLPricingStrategy(pricingStrategy);

        require(!isHardCapAchieved(_usdAmount.sub(1)));

        uint256 tokensAvailable = allocator.tokensAvailable();
        uint256 collectedWei = contributionForwarder.weiCollected();
        uint256 tierIndex = pricing.getTierIndex();
        uint256 tokens;
        uint256 tokensExcludingBonus;
        uint256 bonus;

        (tokens, tokensExcludingBonus, bonus) = pricing.getTokens(
            _contributor, tokensAvailable, tokensSold, _usdAmount, collectedWei);

        require(tokens > 0);

        tokensSold = tokensSold.add(tokens);

        allocator.allocate(_contributor, tokens);

         
        uint256 processingFeeAmount = tokens.mul(processingFeePercentage).div(percentageAbsMax);
        allocator.allocate(processingFeeAddress, processingFeeAmount);

        if (isSoftCapAchieved(_usdAmount)) {
            if (msg.value > 0) {
                contributionForwarder.forward.value(address(this).balance)();
            }
        } else {
             
            if (contributorsWei[_contributor] == 0) {
                contributors.push(_contributor);
            }
            if (msg.value > 0) {
                contributorsWei[_contributor] = contributorsWei[_contributor].add(msg.value);
            }
        }

        usdCollected = usdCollected.add(_usdAmount);

        crowdsaleAgent.onContribution(_contributor, tierIndex, tokensExcludingBonus, bonus);

        emit Contribution(_contributor, _usdAmount, tokensExcludingBonus, bonus);
        emit ProcessingFeeAllocation(_contributor, processingFeeAmount);
    }

}
contract USDExchange is Ownable {

    using SafeMath for uint256;

    uint256 public etherPriceInUSD;
    uint256 public priceUpdateAt;
    mapping(address => bool) public trustedAddresses;

    event NewPriceTicker(string _price);

    modifier onlyTursted() {
        require(trustedAddresses[msg.sender] == true);
        _;
    }

    constructor(uint256 _etherPriceInUSD) public {
        etherPriceInUSD = _etherPriceInUSD;
        priceUpdateAt = block.timestamp;
        trustedAddresses[msg.sender] = true;
    }

    function setTrustedAddress(address _address, bool _status) public onlyOwner {
        trustedAddresses[_address] = _status;
    }

     
     
     
    function setEtherInUSD(string _price) public onlyTursted {
        bytes memory bytePrice = bytes(_price);
        uint256 dot = bytePrice.length.sub(uint256(6));

         
        require(0x2e == uint(bytePrice[dot]));

        uint256 newPrice = uint256(10 ** 23).div(parseInt(_price, 5));

        require(newPrice > 0);

        etherPriceInUSD = parseInt(_price, 5);

        priceUpdateAt = block.timestamp;

        emit NewPriceTicker(_price);
    }

    function parseInt(string _a, uint _b) internal pure returns (uint) {
        bytes memory bresult = bytes(_a);
        uint res = 0;
        bool decimals = false;
        for (uint i = 0; i < bresult.length; i++) {
            if ((bresult[i] >= 48) && (bresult[i] <= 57)) {
                if (decimals) {
                    if (_b == 0) break;
                    else _b--;
                }
                res *= 10;
                res += uint(bresult[i]) - 48;
            } else if (bresult[i] == 46) decimals = true;
        }
        if (_b > 0) res *= 10 ** _b;
        return res;
    }
}
 
 
 
 
contract PricingStrategy {

    function isInitialized() public view returns (bool);

    function getTokens(
        address _contributor,
        uint256 _tokensAvailable,
        uint256 _tokensSold,
        uint256 _weiAmount,
        uint256 _collectedWei
    )
        public
        view
        returns (uint256 tokens, uint256 tokensExcludingBonus, uint256 bonus);

    function getWeis(
        uint256 _collectedWei,
        uint256 _tokensSold,
        uint256 _tokens
    )
        public
        view
        returns (uint256 weiAmount, uint256 tokensBonus);

}
 
 
 
 
contract USDDateTiersPricingStrategy is PricingStrategy, USDExchange {

    using SafeMath for uint256;

     
     
     
     
     
     
     
     
     
    struct Tier {
        uint256 tokenInUSD;
        uint256 maxTokensCollected;
        uint256 bonusCap;
        uint256 soldTierTokens;
        uint256 bonusTierTokens;
        uint256 bonusPercents;
        uint256 minInvestInUSD;
        uint256 startDate;
        uint256 endDate;
    }

    Tier[] public tiers;
    uint256 public decimals;

    constructor(uint256[] _tiers, uint256 _decimals, uint256 _etherPriceInUSD) public USDExchange(_etherPriceInUSD) {
        decimals = _decimals;
        trustedAddresses[msg.sender] = true;
        require(_tiers.length % 9 == 0);

        uint256 length = _tiers.length / 9;

        for (uint256 i = 0; i < length; i++) {
            tiers.push(
                Tier(
                    _tiers[i * 9],
                    _tiers[i * 9 + 1],
                    _tiers[i * 9 + 2],
                    _tiers[i * 9 + 3],
                    _tiers[i * 9 + 4],
                    _tiers[i * 9 + 5],
                    _tiers[i * 9 + 6],
                    _tiers[i * 9 + 7],
                    _tiers[i * 9 + 8]
                )
            );
        }
    }

     
    function getTierIndex() public view returns (uint256) {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (
                block.timestamp >= tiers[i].startDate &&
                block.timestamp < tiers[i].endDate &&
                tiers[i].maxTokensCollected > tiers[i].soldTierTokens
            ) {
                return i;
            }
        }

        return tiers.length;
    }

    function getActualTierIndex() public view returns (uint256) {
        for (uint256 i = 0; i < tiers.length; i++) {
            if (
                block.timestamp >= tiers[i].startDate
                && block.timestamp < tiers[i].endDate
                && tiers[i].maxTokensCollected > tiers[i].soldTierTokens
                || block.timestamp < tiers[i].startDate
            ) {
                return i;
            }
        }

        return tiers.length.sub(1);
    }

     
    function getActualDates() public view returns (uint256 startDate, uint256 endDate) {
        uint256 tierIndex = getActualTierIndex();
        startDate = tiers[tierIndex].startDate;
        endDate = tiers[tierIndex].endDate;
    }

     
    function getTokens(
        address,
        uint256 _tokensAvailable,
        uint256,
        uint256 _usdAmount,
        uint256
    ) public view returns (uint256 tokens, uint256 tokensExcludingBonus, uint256 bonus) {
        if (_usdAmount == 0) {
            return (0, 0, 0);
        }

        uint256 tierIndex = getTierIndex();

        if (tierIndex < tiers.length && _usdAmount < tiers[tierIndex].minInvestInUSD) {
            return (0, 0, 0);
        }
        if (tierIndex == tiers.length) {
            return (0, 0, 0);
        }
        tokensExcludingBonus = _usdAmount.mul(1e18).div(getTokensInUSD(tierIndex));
        if (tiers[tierIndex].maxTokensCollected < tiers[tierIndex].soldTierTokens.add(tokensExcludingBonus)) {
            return (0, 0, 0);
        }

        bonus = calculateBonusAmount(tierIndex, tokensExcludingBonus);

        tokens = tokensExcludingBonus.add(bonus);

        if (tokens > _tokensAvailable) {
            return (0, 0, 0);
        }
    }

     
    function getUSDAmountByTokens(
        uint256 _tokens
    ) public view returns (uint256 totalUSDAmount, uint256 tokensBonus) {
        if (_tokens == 0) {
            return (0, 0);
        }

        uint256 tierIndex = getTierIndex();
        if (tierIndex == tiers.length) {
            return (0, 0);
        }
        if (tiers[tierIndex].maxTokensCollected < tiers[tierIndex].soldTierTokens.add(_tokens)) {
            return (0, 0);
        }

        totalUSDAmount = _tokens.mul(getTokensInUSD(tierIndex)).div(1e18);

        if (totalUSDAmount < tiers[tierIndex].minInvestInUSD) {
            return (0, 0);
        }

        tokensBonus = calculateBonusAmount(tierIndex, _tokens);
    }

     
    function getWeis(
        uint256,
        uint256,
        uint256 _tokens
    ) public view returns (uint256 totalWeiAmount, uint256 tokensBonus) {
        uint256 usdAmount;
        (usdAmount, tokensBonus) = getUSDAmountByTokens(_tokens);

        if (usdAmount == 0) {
            return (0, 0);
        }

        totalWeiAmount = usdAmount.mul(1e18).div(etherPriceInUSD);
    }

     
     
     
    function calculateBonusAmount(uint256 _tierIndex, uint256 _tokens) public view returns (uint256 bonus) {
        if (tiers[_tierIndex].soldTierTokens < tiers[_tierIndex].bonusCap) {
            if (tiers[_tierIndex].soldTierTokens.add(_tokens) <= tiers[_tierIndex].bonusCap) {
                bonus = _tokens.mul(tiers[_tierIndex].bonusPercents).div(100);
            } else {
                bonus = (tiers[_tierIndex].bonusCap.sub(tiers[_tierIndex].soldTierTokens))
                    .mul(tiers[_tierIndex].bonusPercents).div(100);
            }
        }
    }

    function getTokensInUSD(uint256 _tierIndex) public view returns (uint256) {
        if (_tierIndex < uint256(tiers.length)) {
            return tiers[_tierIndex].tokenInUSD;
        }
    }

    function getMinEtherInvest(uint256 _tierIndex) public view returns (uint256) {
        if (_tierIndex < uint256(tiers.length)) {
            return tiers[_tierIndex].minInvestInUSD.mul(1 ether).div(etherPriceInUSD);
        }
    }

    function getUSDAmountByWeis(uint256 _weiAmount) public view returns (uint256) {
        return _weiAmount.mul(etherPriceInUSD).div(1 ether);
    }

     
     
    function isInitialized() public view returns (bool) {
        return true;
    }

     
    function updateDates(uint8 _tierId, uint256 _start, uint256 _end) public onlyOwner() {
        if (_start != 0 && _start < _end && _tierId < tiers.length) {
            Tier storage tier = tiers[_tierId];
            tier.startDate = _start;
            tier.endDate = _end;
        }
    }
}
contract CHLPricingStrategy is USDDateTiersPricingStrategy {

    CHLAgent public agent;

    modifier onlyAgent() {
        require(msg.sender == address(agent));
        _;
    }

    event MaxTokensCollectedDecreased(uint256 tierId, uint256 oldValue, uint256 amount);

    constructor(
        uint256[] _emptyArray,
        uint256[4] _periods,
        uint256 _etherPriceInUSD
    ) public USDDateTiersPricingStrategy(_emptyArray, 18, _etherPriceInUSD) {
         
        tiers.push(Tier(0.75e5, 6247500e18, 0, 0, 0, 0, 100e5, _periods[0], _periods[1]));
         
        tiers.push(Tier(3e5, 32725000e18, 0, 0, 0, 0, 100e5, _periods[2], _periods[3]));
    }

    function getArrayOfTiers() public view returns (uint256[12] tiersData) {
        uint256 j = 0;
        for (uint256 i = 0; i < tiers.length; i++) {
            tiersData[j++] = uint256(tiers[i].tokenInUSD);
            tiersData[j++] = uint256(tiers[i].maxTokensCollected);
            tiersData[j++] = uint256(tiers[i].soldTierTokens);
            tiersData[j++] = uint256(tiers[i].minInvestInUSD);
            tiersData[j++] = uint256(tiers[i].startDate);
            tiersData[j++] = uint256(tiers[i].endDate);
        }
    }

    function updateTier(
        uint256 _tierId,
        uint256 _start,
        uint256 _end,
        uint256 _minInvest,
        uint256 _price,
        uint256 _bonusCap,
        uint256 _bonus,
        bool _updateLockNeeded
    ) public onlyOwner() {
        require(
            _start != 0 &&
            _price != 0 &&
            _start < _end &&
            _tierId < tiers.length
        );

        if (_updateLockNeeded) {
            agent.updateLockPeriod(_end);
        }

        Tier storage tier = tiers[_tierId];
        tier.tokenInUSD = _price;
        tier.minInvestInUSD = _minInvest;
        tier.startDate = _start;
        tier.endDate = _end;
        tier.bonusCap = _bonusCap;
        tier.bonusPercents = _bonus;
    }

    function setCrowdsaleAgent(CHLAgent _crowdsaleAgent) public onlyOwner {
        agent = _crowdsaleAgent;
    }

    function updateTierTokens(uint256 _tierId, uint256 _soldTokens, uint256 _bonusTokens) public onlyAgent {
        require(_tierId < tiers.length && _soldTokens > 0);

        Tier storage tier = tiers[_tierId];
        tier.soldTierTokens = tier.soldTierTokens.add(_soldTokens);
        tier.bonusTierTokens = tier.bonusTierTokens.add(_bonusTokens);
    }

    function updateMaxTokensCollected(uint256 _tierId, uint256 _amount) public onlyAgent {
        require(_tierId < tiers.length && _amount > 0);

        Tier storage tier = tiers[_tierId];

        require(tier.maxTokensCollected.sub(_amount) >= tier.soldTierTokens.add(tier.bonusTierTokens));

        emit MaxTokensCollectedDecreased(_tierId, tier.maxTokensCollected, _amount);

        tier.maxTokensCollected = tier.maxTokensCollected.sub(_amount);
    }

    function getTokensWithoutRestrictions(uint256 _usdAmount) public view returns (
        uint256 tokens,
        uint256 tokensExcludingBonus,
        uint256 bonus
    ) {
        if (_usdAmount == 0) {
            return (0, 0, 0);
        }

        uint256 tierIndex = getActualTierIndex();

        tokensExcludingBonus = _usdAmount.mul(1e18).div(getTokensInUSD(tierIndex));
        bonus = calculateBonusAmount(tierIndex, tokensExcludingBonus);
        tokens = tokensExcludingBonus.add(bonus);
    }

    function getTierUnsoldTokens(uint256 _tierId) public view returns (uint256) {
        if (_tierId >= tiers.length) {
            return 0;
        }

        return tiers[_tierId].maxTokensCollected.sub(tiers[_tierId].soldTierTokens);
    }

    function getSaleEndDate() public view returns (uint256) {
        return tiers[tiers.length.sub(1)].endDate;
    }

}
contract Referral is Ownable {

    using SafeMath for uint256;

    MintableTokenAllocator public allocator;
    CrowdsaleImpl public crowdsale;

    uint256 public constant DECIMALS = 18;

    uint256 public totalSupply;
    bool public unLimited;
    bool public sentOnce;

    mapping(address => bool) public claimed;
    mapping(address => uint256) public claimedBalances;

    constructor(
        uint256 _totalSupply,
        address _allocator,
        address _crowdsale,
        bool _sentOnce
    ) public {
        require(_allocator != address(0) && _crowdsale != address(0));
        totalSupply = _totalSupply;
        if (totalSupply == 0) {
            unLimited = true;
        }
        allocator = MintableTokenAllocator(_allocator);
        crowdsale = CrowdsaleImpl(_crowdsale);
        sentOnce = _sentOnce;
    }

    function setAllocator(address _allocator) public onlyOwner {
        if (_allocator != address(0)) {
            allocator = MintableTokenAllocator(_allocator);
        }
    }

    function setCrowdsale(address _crowdsale) public onlyOwner {
        require(_crowdsale != address(0));
        crowdsale = CrowdsaleImpl(_crowdsale);
    }

    function multivestMint(
        address _address,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(true == crowdsale.signers(verify(msg.sender, _amount, _v, _r, _s)));
        if (true == sentOnce) {
            require(claimed[_address] == false);
            claimed[_address] = true;
        }
        require(
            _address == msg.sender &&
            _amount > 0 &&
            (true == unLimited || _amount <= totalSupply)
        );
        claimedBalances[_address] = claimedBalances[_address].add(_amount);
        if (false == unLimited) {
            totalSupply = totalSupply.sub(_amount);
        }
        allocator.allocate(_address, _amount);
    }

     
    function verify(address _sender, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s) public pure returns (address) {
        bytes32 hash = keccak256(abi.encodePacked(_sender, _amount));

        bytes memory prefix = '\x19Ethereum Signed Message:\n32';

        return ecrecover(keccak256(abi.encodePacked(prefix, hash)), _v, _r, _s);
    }

}
contract CHLReferral is Referral {

    CHLPricingStrategy public pricingStrategy;

    constructor(
        address _allocator,
        address _crowdsale,
        CHLPricingStrategy _strategy
    ) public Referral(1190000e18, _allocator, _crowdsale, true) {
        require(_strategy != address(0));
        pricingStrategy = _strategy;
    }

    function multivestMint(
        address _address,
        uint256 _amount,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(pricingStrategy.getSaleEndDate() <= block.timestamp);
        super.multivestMint(_address, _amount, _v, _r, _s);
    }
}
contract CHLAllocation is Ownable {

    using SafeMath for uint256;

    MintableTokenAllocator public allocator;

    CHLAgent public agent;
     
    uint256 public manualMintingSupply = 5950000e18;

    uint256 public foundersVestingAmountPeriodOne = 7140000e18;
    uint256 public foundersVestingAmountPeriodTwo = 2975000e18;
    uint256 public foundersVestingAmountPeriodThree = 1785000e18;

    address[] public vestings;

    address public foundersAddress;

    bool public isFoundersTokensSent;

    event VestingCreated(
        address _vesting,
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _periods,
        bool _revocable
    );

    event VestingRevoked(address _vesting);

    constructor(MintableTokenAllocator _allocator, address _foundersAddress) public {
        require(_foundersAddress != address(0));
        foundersAddress = _foundersAddress;
        allocator = _allocator;
    }

    function setAllocator(MintableTokenAllocator _allocator) public onlyOwner {
        require(_allocator != address(0));
        allocator = _allocator;
    }

    function setAgent(CHLAgent _agent) public onlyOwner {
        require(_agent != address(0));
        agent = _agent;
    }

    function allocateManualMintingTokens(address[] _addresses, uint256[] _tokens) public onlyOwner {
        require(_addresses.length == _tokens.length);
        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0) && _tokens[i] > 0 && _tokens[i] <= manualMintingSupply);
            manualMintingSupply -= _tokens[i];

            allocator.allocate(_addresses[i], _tokens[i]);
        }
    }

    function allocatePrivateSaleTokens(
        uint256 _tierId,
        uint256 _totalTokensSupply,
        uint256 _tokenPriceInUsd,
        address[] _addresses,
        uint256[] _tokens
    ) public onlyOwner {
        require(
            _addresses.length == _tokens.length &&
            _totalTokensSupply > 0
        );

        agent.updateStateWithPrivateSale(_tierId, _totalTokensSupply, _totalTokensSupply.mul(_tokenPriceInUsd).div(1e18));

        for (uint256 i = 0; i < _addresses.length; i++) {
            require(_addresses[i] != address(0) && _tokens[i] > 0 && _tokens[i] <= _totalTokensSupply);
            _totalTokensSupply = _totalTokensSupply.sub(_tokens[i]);

            allocator.allocate(_addresses[i], _tokens[i]);
        }

        require(_totalTokensSupply == 0);
    }

    function allocateFoundersTokens(uint256 _start) public {
        require(!isFoundersTokensSent && msg.sender == address(agent));

        isFoundersTokensSent = true;

        allocator.allocate(foundersAddress, foundersVestingAmountPeriodOne);

        createVestingInternal(
            foundersAddress,
            _start,
            0,
            365 days,
            1,
            true,
            owner,
            foundersVestingAmountPeriodTwo
        );

        createVestingInternal(
            foundersAddress,
            _start,
            0,
            730 days,
            1,
            true,
            owner,
            foundersVestingAmountPeriodThree
        );
    }

    function createVesting(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _periods,
        bool _revocable,
        address _unreleasedHolder,
        uint256 _amount
    ) public onlyOwner returns (PeriodicTokenVesting vesting) {

        vesting = createVestingInternal(
            _beneficiary,
            _start,
            _cliff,
            _duration,
            _periods,
            _revocable,
            _unreleasedHolder,
            _amount
        );
    }

    function revokeVesting(PeriodicTokenVesting _vesting, ERC20Basic token) public onlyOwner() {
        _vesting.revoke(token);

        emit VestingRevoked(_vesting);
    }

    function createVestingInternal(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _duration,
        uint256 _periods,
        bool _revocable,
        address _unreleasedHolder,
        uint256 _amount
    ) internal returns (PeriodicTokenVesting) {
        PeriodicTokenVesting vesting = new PeriodicTokenVesting(
            _beneficiary, _start, _cliff, _duration, _periods, _revocable, _unreleasedHolder
        );

        vestings.push(vesting);

        emit VestingCreated(vesting, _beneficiary, _start, _cliff, _duration, _periods, _revocable);

        allocator.allocate(address(vesting), _amount);

        return vesting;
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

   
  constructor(
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
contract PeriodicTokenVesting is TokenVesting {
    address public unreleasedHolder;
    uint256 public periods;

    constructor(
        address _beneficiary,
        uint256 _start,
        uint256 _cliff,
        uint256 _periodDuration,
        uint256 _periods,
        bool _revocable,
        address _unreleasedHolder
    ) public TokenVesting(_beneficiary, _start, _cliff, _periodDuration, _revocable) {
        require(_revocable == false || _unreleasedHolder != address(0));
        periods = _periods;
        unreleasedHolder = _unreleasedHolder;
    }

     
    function vestedAmount(ERC20Basic token) public view returns (uint256) {
        uint256 currentBalance = token.balanceOf(this);
        uint256 totalBalance = currentBalance.add(released[token]);

        if (now < cliff) {
            return 0;
        } else if (now >= start.add(duration * periods) || revoked[token]) {
            return totalBalance;
        } else {

            uint256 periodTokens = totalBalance.div(periods);

            uint256 periodsOver = now.sub(start).div(duration);

            if (periodsOver >= periods) {
                return totalBalance;
            }

            return periodTokens.mul(periodsOver);
        }
    }

     
    function revoke(ERC20Basic token) public onlyOwner {
        require(revocable);
        require(!revoked[token]);

        uint256 balance = token.balanceOf(this);

        uint256 unreleased = releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        revoked[token] = true;

        token.safeTransfer(unreleasedHolder, refund);

        emit Revoked();
    }
}
contract Stats {

    using SafeMath for uint256;

    MintableToken public token;
    MintableTokenAllocator public allocator;
    CHLCrowdsale public crowdsale;
    CHLPricingStrategy public pricing;

    constructor(
        MintableToken _token,
        MintableTokenAllocator _allocator,
        CHLCrowdsale _crowdsale,
        CHLPricingStrategy _pricing
    ) public {
        token = _token;
        allocator = _allocator;
        crowdsale = _crowdsale;
        pricing = _pricing;
    }

    function getTokens(
        uint256 _type,
        uint256 _usdAmount
    ) public view returns (uint256 tokens, uint256 tokensExcludingBonus, uint256 bonus) {
        _type = _type;

        return pricing.getTokensWithoutRestrictions(_usdAmount);
    }

    function getWeis(
        uint256 _type,
        uint256 _tokenAmount
    ) public view returns (uint256 totalWeiAmount, uint256 tokensBonus) {
        _type = _type;

        return pricing.getWeis(0, 0, _tokenAmount);
    }

    function getUSDAmount(
        uint256 _type,
        uint256 _tokenAmount
    ) public view returns (uint256 totalUSDAmount, uint256 tokensBonus) {
        _type = _type;

        return pricing.getUSDAmountByTokens(_tokenAmount);
    }

    function getStats(uint256 _userType, uint256[7] _ethPerCurrency) public view returns (
        uint256[8] stats,
        uint256[26] tiersData,
        uint256[21] currencyContr  
    ) {
        stats = getStatsData(_userType);
        tiersData = getTiersData(_userType);
        currencyContr = getCurrencyContrData(_userType, _ethPerCurrency);
    }

    function getTiersData(uint256 _type) public view returns (
        uint256[26] tiersData
    ) {
        _type = _type;
        uint256[12] memory tiers = pricing.getArrayOfTiers();
        uint256 length = tiers.length / 6;

        uint256 j = 0;
        for (uint256 i = 0; i < length; i++) {
            tiersData[j++] = uint256(1e23).div(tiers[i.mul(6)]); 
            tiersData[j++] = 0; 
            tiersData[j++] = uint256(tiers[i.mul(6).add(1)]); 
            tiersData[j++] = uint256(tiers[i.mul(6).add(2)]); 
            tiersData[j++] = 0; 
            tiersData[j++] = 0; 
            tiersData[j++] = uint256(tiers[i.mul(6).add(3)]); 
            tiersData[j++] = 0; 
            tiersData[j++] = 0; 
            tiersData[j++] = 0; 
            tiersData[j++] = uint256(tiers[i.mul(6).add(4)]);  
            tiersData[j++] = uint256(tiers[i.mul(6).add(5)]);  
            tiersData[j++] = 1;
        }

        tiersData[25] = 2;

    }

    function getStatsData(uint256 _type) public view returns (
        uint256[8] stats
    ) {
        _type = _type;
        stats[0] = token.maxSupply();
        stats[1] = token.totalSupply();
        stats[2] = crowdsale.maxSaleSupply();
        stats[3] = crowdsale.tokensSold();
        stats[4] = uint256(crowdsale.currentState());
        stats[5] = pricing.getActualTierIndex();
        stats[6] = pricing.getTierUnsoldTokens(stats[5]);
        stats[7] = pricing.getMinEtherInvest(stats[5]);
    }

    function getCurrencyContrData(uint256 _type, uint256[7] _usdPerCurrency) public view returns (
        uint256[21] currencyContr
    ) {
        _type = _type;
        uint256 j = 0;
        for (uint256 i = 0; i < _usdPerCurrency.length; i++) {
            (currencyContr[j++], currencyContr[j++], currencyContr[j++]) = pricing.getTokensWithoutRestrictions(
                _usdPerCurrency[i]
            );
        }
    }
}