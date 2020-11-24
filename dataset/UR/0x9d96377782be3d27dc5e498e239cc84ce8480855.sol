 

 
 

pragma solidity ^0.4.15;

 
contract Token {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

 
contract Owned {
  event NewOwner(address indexed old, address indexed current);

  modifier only_owner {
    require (msg.sender == owner);
    _;
  }

  address public owner = msg.sender;

  function setOwner(address _new) only_owner {
    NewOwner(owner, _new);
    owner = _new;
  }
}

 
contract Certifier {
  function certified(address _who) constant returns (bool);
}

 
contract AmberToken is Token, Owned {
  struct Account {
     
    uint balance;
    mapping (address => uint) allowanceOf;

     
    uint tokensPerPhase;
    uint nextPhase;
  }

  event Minted(address indexed who, uint value);
  event MintedLocked(address indexed who, uint value);

  function AmberToken() {}

   
   
  function mint(address _who, uint _value)
    only_owner
    public
  {
    accounts[_who].balance += _value;
    totalSupply += _value;
    Minted(_who, _value);
  }

   
   
  function mintLocked(address _who, uint _value)
    only_owner
    public
  {
    accounts[_who].tokensPerPhase += _value / UNLOCK_PHASES;
    totalSupply += _value;
    MintedLocked(_who, _value);
  }

   
   
  function finalise()
    only_owner
    public
  {
    locked = false;
    owner = 0;
    phaseStart = now;
  }

   
   
  function currentPhase()
    public
    constant
    returns (uint)
  {
    require (phaseStart > 0);
    uint p = (now - phaseStart) / PHASE_DURATION;
    return p > UNLOCK_PHASES ? UNLOCK_PHASES : p;
  }

   
  function unlockTokens(address _who)
    public
  {
    uint phase = currentPhase();
    uint tokens = accounts[_who].tokensPerPhase;
    uint nextPhase = accounts[_who].nextPhase;
    if (tokens > 0 && phase > nextPhase) {
      accounts[_who].balance += tokens * (phase - nextPhase);
      accounts[_who].nextPhase = phase;
    }
  }

   
  function transfer(address _to, uint256 _value)
    when_owns(msg.sender, _value)
    when_liquid
    returns (bool)
  {
    Transfer(msg.sender, _to, _value);
    accounts[msg.sender].balance -= _value;
    accounts[_to].balance += _value;

    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
    when_owns(_from, _value)
    when_has_allowance(_from, msg.sender, _value)
    when_liquid
    returns (bool)
  {
    Transfer(_from, _to, _value);
    accounts[_from].allowanceOf[msg.sender] -= _value;
    accounts[_from].balance -= _value;
    accounts[_to].balance += _value;

    return true;
  }

   
  function approve(address _spender, uint256 _value)
    when_liquid
    returns (bool)
  {
     
     
    require (_value == 0 || accounts[msg.sender].allowanceOf[_spender] == 0);
    Approval(msg.sender, _spender, _value);
    accounts[msg.sender].allowanceOf[_spender] = _value;

    return true;
  }

   
  function balanceOf(address _who) constant returns (uint256) {
    return accounts[_who].balance;
  }

   
  function allowance(address _owner, address _spender)
    constant
    returns (uint256)
  {
    return accounts[_owner].allowanceOf[_spender];
  }

   
  modifier when_owns(address _owner, uint _amount) {
    require (accounts[_owner].balance >= _amount);
    _;
  }

   
  modifier when_has_allowance(address _owner, address _spender, uint _amount) {
    require (accounts[_owner].allowanceOf[_spender] >= _amount);
    _;
  }

   
  modifier when_liquid {
    require (!locked);
    _;
  }

   
  string constant public name = "Amber Token";
  uint8 constant public decimals = 18;
  string constant public symbol = "AMB";

   
  bool public locked = true;

   
  uint public phaseStart = 0;
  uint public constant PHASE_DURATION = 180 days;
  uint public constant UNLOCK_PHASES = 4;

   
  uint public totalSupply;

   
  mapping (address => Account) accounts;
}

 
 
contract AmbrosusSale {
   
  function AmbrosusSale() {
    tokens = new AmberToken();
    tokens.mint(0x00C269e9D02188E39C9922386De631c6AED5b4d4, 143375759490000000000000000);
    saleRevenue += 143375759490000000000000;
    totalSold += 143375759490000000000000000;

  }

   
  modifier only_admin { require (msg.sender == ADMINISTRATOR); _; }
   
  modifier only_prepurchaser { require (msg.sender == PREPURCHASER); _; }

   
  modifier is_valid_buyin { require (tx.gasprice <= MAX_BUYIN_GAS_PRICE && msg.value >= MIN_BUYIN_VALUE); _; }
   
  modifier is_under_cap_with(uint buyin) { require (buyin + saleRevenue <= MAX_REVENUE); _; }
   
  modifier only_certified(address who) { require (CERTIFIER.certified(who)); _; }

   

   
  modifier only_before_period { require (now < BEGIN_TIME); _; }
   
  modifier only_during_period { require (now >= BEGIN_TIME && now < END_TIME && !isPaused); _; }
   
  modifier only_during_paused_period { require (now >= BEGIN_TIME && now < END_TIME && isPaused); _; }
   
  modifier only_after_sale { require (now >= END_TIME || saleRevenue >= MAX_REVENUE); _; }

   

   
  modifier when_allocations_uninitialised { require (!allocationsInitialised); _; }
   
  modifier when_allocatable_liquid(uint amount) { require (liquidAllocatable >= amount); _; }
   
  modifier when_allocatable_locked(uint amount) { require (lockedAllocatable >= amount); _; }
   
  modifier when_allocations_complete { require (allocationsInitialised && liquidAllocatable == 0 && lockedAllocatable == 0); _; }

   
  event Prepurchased(address indexed recipient, uint etherPaid, uint amberSold);
   
  event Purchased(address indexed recipient, uint amount);
   
  event SpecialPurchased(address indexed recipient, uint etherPaid, uint amberSold);
   
  event Paused();
   
  event Unpaused();
   
  event Allocated(address indexed recipient, uint amount, bool liquid);

   
   
   
   
   
  function notePrepurchase(address _who, uint _etherPaid, uint _amberSold)
    only_prepurchaser
    only_before_period
    public
  {
     
    tokens.mint(_who, _amberSold);
    saleRevenue += _etherPaid;
    totalSold += _amberSold;
    Prepurchased(_who, _etherPaid, _amberSold);
  }

   
   
   
   
   
   
  function specialPurchase()
    only_before_period
    is_under_cap_with(msg.value)
    payable
    public
  {
    uint256 bought = buyinReturn(msg.sender) * msg.value;
    require (bought > 0);    

     
    tokens.mint(msg.sender, bought);
    TREASURY.transfer(msg.value);
    saleRevenue += msg.value;
    totalSold += bought;
    SpecialPurchased(msg.sender, msg.value, bought);
   }

   
   
   
   
   
  function ()
    only_certified(msg.sender)
    payable
    public
  {
    processPurchase(msg.sender);
  }

   
   
   
   
   
  function purchaseTo(address _recipient)
    only_certified(msg.sender)
    payable
    public
  {
    processPurchase(_recipient);
  }

   
   
   
   
   
  function processPurchase(address _recipient)
    only_during_period
    is_valid_buyin
    is_under_cap_with(msg.value)
    private
  {
     
    tokens.mint(_recipient, msg.value * STANDARD_BUYIN);
    TREASURY.transfer(msg.value);
    saleRevenue += msg.value;
    totalSold += msg.value * STANDARD_BUYIN;
    Purchased(_recipient, msg.value);
  }

   
  function buyinReturn(address _who)
    constant
    public
    returns (uint)
  {
     
    if (
      _who == CHINESE_EXCHANGE_1 || _who == CHINESE_EXCHANGE_2 ||
      _who == CHINESE_EXCHANGE_3 || _who == CHINESE_EXCHANGE_4
    )
      return CHINESE_EXCHANGE_BUYIN;

     
    if (_who == BTC_SUISSE_TIER_1)
      return STANDARD_BUYIN;
     
    if (_who == BTC_SUISSE_TIER_2)
      return TIER_2_BUYIN;
     
    if (_who == BTC_SUISSE_TIER_3)
      return TIER_3_BUYIN;
     
    if (_who == BTC_SUISSE_TIER_4)
      return TIER_4_BUYIN;

    return 0;
  }

   
   
   
   
   
  function pause()
    only_admin
    only_during_period
    public
  {
    isPaused = true;
    Paused();
  }

   
   
   
   
   
  function unpause()
    only_admin
    only_during_paused_period
    public
  {
    isPaused = false;
    Unpaused();
  }

   
   
   
   
   
   
   
  function initialiseAllocations()
    public
    only_after_sale
    when_allocations_uninitialised
  {
    allocationsInitialised = true;
    liquidAllocatable = LIQUID_ALLOCATION_PPM * totalSold / SALES_ALLOCATION_PPM;
    lockedAllocatable = LOCKED_ALLOCATION_PPM * totalSold / SALES_ALLOCATION_PPM;
  }

   
   
   
   
   
   
   
  function allocateLiquid(address _who, uint _value)
    only_admin
    when_allocatable_liquid(_value)
    public
  {
     
    tokens.mint(_who, _value);
    liquidAllocatable -= _value;
    Allocated(_who, _value, true);
  }

   
   
   
   
   
   
   
  function allocateLocked(address _who, uint _value)
    only_admin
    when_allocatable_locked(_value)
    public
  {
     
    tokens.mintLocked(_who, _value);
    lockedAllocatable -= _value;
    Allocated(_who, _value, false);
  }

   
   
   
   
   
   
   
  function finalise()
    when_allocations_complete
    public
  {
    tokens.finalise();
  }

   
   
   

   
  uint public constant MIN_BUYIN_VALUE = 10000000000000000;
   
  uint public constant MAX_BUYIN_GAS_PRICE = 25000000000;
   
  uint public constant MAX_REVENUE = 425203 ether;

   
  uint constant public SALES_ALLOCATION_PPM = 400000;
   
  uint constant public LOCKED_ALLOCATION_PPM = 337000;
   
  uint constant public LIQUID_ALLOCATION_PPM = 263000;

   
  Certifier public constant CERTIFIER = Certifier(0x7b1Ab331546F021A40bd4D09fFb802261CaACcc9);
   
  address public constant ADMINISTRATOR = 0x00C269e9D02188E39C9922386De631c6AED5b4d4;
   
  address public constant PREPURCHASER = 0x00D426e9F24E0F426706A1aBf96E375014684C78;
   
  address public constant TREASURY = 0x00D426e9F24E0F426706A1aBf96E375014684C78;
   
  uint public constant BEGIN_TIME = 1505779200;
   
  uint public constant DURATION = 30 days;
   
  uint public constant END_TIME = BEGIN_TIME + DURATION;

   
  address public constant BTC_SUISSE_TIER_1 = 0x53B3D4f98fcb6f0920096fe1cCCa0E4327Da7a1D;
  address public constant BTC_SUISSE_TIER_2 = 0x642fDd12b1Dd27b9E19758F0AefC072dae7Ab996;
  address public constant BTC_SUISSE_TIER_3 = 0x64175446A1e3459c3E9D650ec26420BA90060d28;
  address public constant BTC_SUISSE_TIER_4 = 0xB17C2f9a057a2640309e41358a22Cf00f8B51626;
  address public constant CHINESE_EXCHANGE_1 = 0x36f548fAB37Fcd39cA8725B8fA214fcd784FE0A3;
  address public constant CHINESE_EXCHANGE_2 = 0x877Da872D223AB3D073Ab6f9B4bb27540E387C5F;
  address public constant CHINESE_EXCHANGE_3 = 0xCcC088ec38A4dbc15Ba269A176883F6ba302eD8d;
   
  address public constant CHINESE_EXCHANGE_4 = 0;

   
   
  uint public constant STANDARD_BUYIN = 1000;
  uint public constant TIER_2_BUYIN = 1111;
  uint public constant TIER_3_BUYIN = 1250;
  uint public constant TIER_4_BUYIN = 1429;
  uint public constant CHINESE_EXCHANGE_BUYIN = 1087;

   
   
   
   
   
   
   
   
   

   
  bool public allocationsInitialised = false;
   
  uint public liquidAllocatable;
   
  uint public lockedAllocatable;

   
   
   
   
   

   
   
  uint public saleRevenue = 0;
   
   
  uint public totalSold = 0;

   
   

   
  AmberToken public tokens;

   
   

   
  bool public isPaused = false;
}