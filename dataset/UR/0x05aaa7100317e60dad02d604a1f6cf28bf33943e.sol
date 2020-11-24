 

 

pragma solidity ^0.4.24;


 
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
    require( (allowed[msg.sender][_spender] == 0) || (_value == 0) );
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


 

 
contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferInitiated(
        address indexed previousOwner,
        address indexed newOwner
    );
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

     
    modifier ownedBy(address _a) {
        require( msg.sender == _a );
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function transferOwnershipAtomic(address _newOwner) public onlyOwner {
        owner = _newOwner;
        newOwner = address(0);
        emit OwnershipTransferred(owner, _newOwner);
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, msg.sender);
        owner = msg.sender;
        newOwner = address(0);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        newOwner = _newOwner;
        emit OwnershipTransferInitiated(owner, _newOwner);
    }
}

 

 
contract MintableToken is StandardToken, Ownable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

     
    uint constant public SUPPLY_HARD_CAP = 1500 * 1e6 * 1e18;
    bool public mintingFinished = false;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    modifier hasMintPermission() {
        require(msg.sender == owner);
        _;
    }

     
    function mint(
        address _to,
        uint256 _amount
    )
        public
        hasMintPermission
        canMint
        returns (bool)
    {
        require( totalSupply_.add(_amount) <= SUPPLY_HARD_CAP );
        totalSupply_ = totalSupply_.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);
        return true;
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }
}

contract Allocation is Ownable {
    using SafeMath for uint256;

    address public backend;
    address public team;
    address public partners;
    address public toSendFromStorage; address public rewards;
    OPUCoin public token;
    Vesting public vesting;
    ColdStorage public coldStorage;

    bool public emergencyPaused = false;
    bool public finalizedHoldingsAndTeamTokens = false;
    bool public mintingFinished = false;

     
     
     
    uint constant internal MIL = 1e6 * 1e18;

     
    uint constant internal ICO_DISTRIBUTION    = 550 * MIL;
    uint constant internal TEAM_TOKENS         = 550  * MIL;
    uint constant internal COLD_STORAGE_TOKENS = 75  * MIL;
    uint constant internal PARTNERS_TOKENS     = 175  * MIL;
    uint constant internal REWARDS_POOL        = 150  * MIL;

    uint internal totalTokensSold = 0;

    event TokensAllocated(address _buyer, uint _tokens);
    event TokensAllocatedIntoHolding(address _buyer, uint _tokens);
    event TokensMintedForRedemption(address _to, uint _tokens);
    event TokensSentIntoVesting(address _vesting, address _to, uint _tokens);
    event TokensSentIntoHolding(address _vesting, address _to, uint _tokens);
    event HoldingAndTeamTokensFinalized();
    event BackendUpdated(address oldBackend, address newBackend);
    event TeamUpdated(address oldTeam, address newTeam);
    event PartnersUpdated(address oldPartners, address newPartners);
    event ToSendFromStorageUpdated(address oldToSendFromStorage, address newToSendFromStorage);

     
    constructor(
        address _backend,
        address _team,
        address _partners,
        address _toSendFromStorage,
        address _rewards
    )
        public
    {
        require( _backend           != address(0) );
        require( _team              != address(0) );
        require( _partners          != address(0) );
        require( _toSendFromStorage != address(0) );
        require( _rewards != address(0) );

        backend           = _backend;
        team              = _team;
        partners          = _partners;
        toSendFromStorage = _toSendFromStorage;
        rewards = _rewards;

        token       = new OPUCoin();
        vesting     = new Vesting(address(token), team);
        coldStorage = new ColdStorage(address(token));
    }

    function emergencyPause() public onlyOwner unpaused { emergencyPaused = true; }

    function emergencyUnpause() public onlyOwner paused { emergencyPaused = false; }

    function allocate(
        address _buyer,
        uint _tokensWithStageBonuses
    )
        public
        ownedBy(backend)
        mintingEnabled
    {
        uint tokensAllocated = _allocateTokens(_buyer, _tokensWithStageBonuses);
        emit TokensAllocated(_buyer, tokensAllocated);
    }

    function finalizeHoldingAndTeamTokens()
        public
        ownedBy(backend)
        unpaused
    {
        require( !finalizedHoldingsAndTeamTokens );

        finalizedHoldingsAndTeamTokens = true;

        vestTokens(team, TEAM_TOKENS);
        holdTokens(toSendFromStorage, COLD_STORAGE_TOKENS);
        token.mint(partners, PARTNERS_TOKENS);
        token.mint(rewards, REWARDS_POOL);

         

        vesting.finalizeVestingAllocation();

        mintingFinished = true;
        token.finishMinting();

        emit HoldingAndTeamTokensFinalized();
    }

    function _allocateTokens(
        address _to,
        uint _tokensWithStageBonuses
    )
        internal
        unpaused
        returns (uint)
    {
        require( _to != address(0) );

        checkCapsAndUpdate(_tokensWithStageBonuses);

         
        uint tokensToAllocate = _tokensWithStageBonuses;

         
        require( token.mint(_to, tokensToAllocate) );
        return tokensToAllocate;
    }

    function checkCapsAndUpdate(uint _tokensToSell) internal {
        uint newTotalTokensSold = totalTokensSold.add(_tokensToSell);
        require( newTotalTokensSold <= ICO_DISTRIBUTION );
        totalTokensSold = newTotalTokensSold;
    }

    function vestTokens(address _to, uint _tokens) internal {
        require( token.mint(address(vesting), _tokens) );
        vesting.initializeVesting( _to, _tokens );
        emit TokensSentIntoVesting(address(vesting), _to, _tokens);
    }

    function holdTokens(address _to, uint _tokens) internal {
        require( token.mint(address(coldStorage), _tokens) );
        coldStorage.initializeHolding(_to);
        emit TokensSentIntoHolding(address(coldStorage), _to, _tokens);
    }

    function updateBackend(address _newBackend) public onlyOwner {
        require(_newBackend != address(0));
        backend = _newBackend;
        emit BackendUpdated(backend, _newBackend);
    }

    function updateTeam(address _newTeam) public onlyOwner {
        require(_newTeam != address(0));
        team = _newTeam;
        emit TeamUpdated(team, _newTeam);
    }

    function updatePartners(address _newPartners) public onlyOwner {
        require(_newPartners != address(0));
        partners = _newPartners;
        emit PartnersUpdated(partners, _newPartners);
    }

    function updateToSendFromStorage(address _newToSendFromStorage) public onlyOwner {
        require(_newToSendFromStorage != address(0));
        toSendFromStorage = _newToSendFromStorage;
        emit ToSendFromStorageUpdated(toSendFromStorage, _newToSendFromStorage);
    }

    modifier unpaused() {
        require( !emergencyPaused );
        _;
    }

    modifier paused() {
        require( emergencyPaused );
        _;
    }

    modifier mintingEnabled() {
        require( !mintingFinished );
        _;
    }
}

contract ColdStorage is Ownable {
    using SafeMath for uint8;
    using SafeMath for uint256;

    ERC20 public token;

    uint public lockupEnds;
    uint public lockupPeriod;
    uint public lockupRewind = 109 days;
    bool public storageInitialized = false;
    address public founders;

    event StorageInitialized(address _to, uint _tokens);
    event TokensReleased(address _to, uint _tokensReleased);

    constructor(address _token) public {
        require( _token != address(0) );
        token = ERC20(_token);
        uint lockupYears = 2;
        lockupPeriod = lockupYears.mul(365 days);
    }

    function claimTokens() external {
        require( now > lockupEnds );
        require( msg.sender == founders );

        uint tokensToRelease = token.balanceOf(address(this));
        require( token.transfer(msg.sender, tokensToRelease) );
        emit TokensReleased(msg.sender, tokensToRelease);
    }

    function initializeHolding(address _to) public onlyOwner {
        uint tokens = token.balanceOf(address(this));
        require( !storageInitialized );
        require( tokens != 0 );

        lockupEnds = now.sub(lockupRewind).add(lockupPeriod);
        founders = _to;
        storageInitialized = true;
        emit StorageInitialized(_to, tokens);
    }
}


contract Migrations {
  address public owner;
  uint public last_completed_migration;

  modifier restricted() {
    if (msg.sender == owner) _;
  }

  function Migrations() public {
    owner = msg.sender;
  }

  function setCompleted(uint completed) public restricted {
    last_completed_migration = completed;
  }

  function upgrade(address new_address) public restricted {
    Migrations upgraded = Migrations(new_address);
    upgraded.setCompleted(last_completed_migration);
  }
}

contract OPUCoin is MintableToken {
    string constant public symbol = "OPU";
    string constant public name = "Opu Coin";
    uint8 constant public decimals = 18;

     
	 
     
    constructor() public { }
}


contract Vesting is Ownable {
    using SafeMath for uint;
    using SafeMath for uint256;

    ERC20 public token;
    mapping (address => Holding) public holdings;
    address internal founders;

    uint constant internal PERIOD_INTERVAL = 30 days;
    uint constant internal FOUNDERS_HOLDING = 365 days;
    uint constant internal BONUS_HOLDING = 0;
    uint constant internal TOTAL_PERIODS = 12;

    uint internal totalTokensCommitted = 0;

    bool internal vestingStarted = false;
    uint internal vestingStart = 0;
    uint vestingRewind = 109 days;

    struct Holding {
        uint tokensCommitted;
        uint tokensRemaining;
        uint batchesClaimed;

        bool isFounder;
        bool isValue;
    }

    event TokensReleased(address _to, uint _tokensReleased, uint _tokensRemaining);
    event VestingInitialized(address _to, uint _tokens);
    event VestingUpdated(address _to, uint _totalTokens);

    constructor(address _token, address _founders) public {
        require( _token != 0x0);
        require(_founders != 0x0);
        token = ERC20(_token);
        founders = _founders;
    }

    function claimTokens() external {
        require( holdings[msg.sender].isValue );
        require( vestingStarted );
        uint personalVestingStart =
            (holdings[msg.sender].isFounder) ? (vestingStart.add(FOUNDERS_HOLDING)) : (vestingStart);
        require( now > personalVestingStart );
        uint periodsPassed = now.sub(personalVestingStart).div(PERIOD_INTERVAL);
        uint batchesToClaim = periodsPassed.sub(holdings[msg.sender].batchesClaimed);
        require( batchesToClaim > 0 );
        uint tokensPerBatch = (holdings[msg.sender].tokensRemaining).div(
            TOTAL_PERIODS.sub(holdings[msg.sender].batchesClaimed)
        );
        uint tokensToRelease = 0;

        if (periodsPassed >= TOTAL_PERIODS) {
            tokensToRelease = holdings[msg.sender].tokensRemaining;
            delete holdings[msg.sender];
        } else {
            tokensToRelease = tokensPerBatch.mul(batchesToClaim);
            holdings[msg.sender].tokensRemaining = (holdings[msg.sender].tokensRemaining).sub(tokensToRelease);
            holdings[msg.sender].batchesClaimed = holdings[msg.sender].batchesClaimed.add(batchesToClaim);
        }
        require( token.transfer(msg.sender, tokensToRelease) );
        emit TokensReleased(msg.sender, tokensToRelease, holdings[msg.sender].tokensRemaining);
    }

    function tokensRemainingInHolding(address _user) public view returns (uint) {
        return holdings[_user].tokensRemaining;
    }

    function initializeVesting(address _beneficiary, uint _tokens) public onlyOwner {
        bool isFounder = (_beneficiary == founders);
        _initializeVesting(_beneficiary, _tokens, isFounder);
    }

    function finalizeVestingAllocation() public onlyOwner {
        vestingStarted = true;
        vestingStart = now.sub(vestingRewind);
    }

    function _initializeVesting(address _to, uint _tokens, bool _isFounder) internal {
        require( !vestingStarted );
        if (!_isFounder) totalTokensCommitted = totalTokensCommitted.add(_tokens);
        if (!holdings[_to].isValue) {
            holdings[_to] = Holding({
                tokensCommitted: _tokens,
                tokensRemaining: _tokens,
                batchesClaimed: 0,
                isFounder: _isFounder,
                isValue: true
            });
            emit VestingInitialized(_to, _tokens);
        } else {
            holdings[_to].tokensCommitted = (holdings[_to].tokensCommitted).add(_tokens);
            holdings[_to].tokensRemaining = (holdings[_to].tokensRemaining).add(_tokens);
            emit VestingUpdated(_to, holdings[_to].tokensRemaining);
        }
    }
}