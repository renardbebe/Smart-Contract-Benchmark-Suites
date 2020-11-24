 

pragma solidity ^0.4.18;

 

 
contract PlayersStorage {
  struct Player {
    uint256 input; 
    uint256 timestamp;
    bool exist;
  }
  mapping (address => Player) private m_players;
  address private m_owner;
    
  modifier onlyOwner() {
    require(msg.sender == m_owner);
    _;
  }
  
  function PlayersStorage() public {
    m_owner = msg.sender;  
  }

   
   
   
   
   


   
  function newPlayer(address addr, uint256 input, uint256 timestamp) 
    public 
    onlyOwner() 
    returns(bool)
  {
    if (m_players[addr].exist) {
      return false;
    }
    m_players[addr].input = input;
    m_players[addr].timestamp = timestamp;
    m_players[addr].exist = true;
    return true;
  }
  
   
  function deletePlayer(address addr) public onlyOwner() {
    delete m_players[addr];
  }
  
   
  function playerInfo(address addr) 
    public
    view
    onlyOwner() 
    returns(uint256 input, uint256 timestamp, bool exist) 
  {
    input = m_players[addr].input;
    timestamp = m_players[addr].timestamp;
    exist = m_players[addr].exist;
  }
  
   
  function playerInput(address addr) 
    public
    view
    onlyOwner() 
    returns(uint256 input) 
  {
    input = m_players[addr].input;
  }
  
   
  function playerExist(address addr) 
    public
    view
    onlyOwner() 
    returns(bool exist) 
  {
    exist = m_players[addr].exist;
  }
  
   
  function playerTimestamp(address addr) 
    public
    view
    onlyOwner() 
    returns(uint256 timestamp) 
  {
    timestamp = m_players[addr].timestamp;
  }
  
   
  function playerSetInput(address addr, uint256 newInput)
    public
    onlyOwner()
    returns(bool) 
  {
    if (!m_players[addr].exist) {
      return false;
    }
    m_players[addr].input = newInput;
    return true;
  }
  
   
  function kill() public onlyOwner() {
    selfdestruct(m_owner);
  }
}


 
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


 
contract ERC677Recipient {
  function tokenFallback(address from, uint256 amount, bytes data) public returns (bool success);
} 


 
contract PonziTokenMinInterface {
  function balanceOf(address owner) public view returns(uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
}


 
contract TheGame is ERC677Recipient {
  using SafeMath for uint256;

  enum State {
    NotActive,  
    Active      
  }

  State private m_state;
  address private m_owner;
  uint256 private m_level;
  PlayersStorage private m_playersStorage;
  PonziTokenMinInterface private m_ponziToken;
  uint256 private m_interestRateNumerator;
  uint256 private constant INTEREST_RATE_DENOMINATOR = 1000;
  uint256 private m_creationTimestamp;
  uint256 private constant DURATION_TO_ACCESS_FOR_OWNER = 144 days;
  uint256 private constant COMPOUNDING_FREQ = 1 days;
  uint256 private constant DELAY_ON_EXIT = 100 hours;
  uint256 private constant DELAY_ON_NEW_LEVEL = 7 days;
  string private constant NOT_ACTIVE_STR = "NotActive";
  uint256 private constant PERCENT_TAX_ON_EXIT = 10;
  string private constant ACTIVE_STR = "Active";
  uint256 private constant PERCENT_REFERRAL_BOUNTY = 1;
  uint256 private m_levelStartupTimestamp;
  uint256 private m_ponziPriceInWei;
  address private m_priceSetter;

 
 
 
  event NewPlayer(address indexed addr, uint256 input, uint256 when);
  event DeletePlayer(address indexed addr, uint256 when);
  event NewLevel(uint256 when, uint256 newLevel);
  event StateChanged(address indexed who, State newState);
  event PonziPriceChanged(address indexed who, uint256 newPrice);
  
 
 
 
  modifier onlyOwner() {
    require(msg.sender == m_owner);
    _;
  }
  modifier onlyPonziToken() {
    require(msg.sender == address(m_ponziToken));
    _;
  }
  modifier atState(State state) {
    require(m_state == state);
    _;
  }
  
  modifier checkAccess() {
    require(m_state == State.NotActive   
      || now.sub(m_creationTimestamp) <= DURATION_TO_ACCESS_FOR_OWNER); 
    _;
  }
  
  modifier isPlayer(address addr) {
    require(m_playersStorage.playerExist(addr));
    _;
  }
  
  modifier gameIsAvailable() {
    require(now >= m_levelStartupTimestamp.add(DELAY_ON_NEW_LEVEL));
    _;
  }

 
 
 
   
  function TheGame(address ponziTokenAddr) public {
    require(ponziTokenAddr != address(0));
    m_ponziToken = PonziTokenMinInterface(ponziTokenAddr);
    m_owner = msg.sender;
    m_creationTimestamp = now;
    m_state = State.NotActive;
    m_level = 1;
    m_interestRateNumerator = calcInterestRateNumerator(m_level);
  }

   
  function() public payable onlyPonziToken() {  }
  
  
   
  function exit() 
    external
    atState(State.Active) 
    gameIsAvailable()
    isPlayer(msg.sender) 
  {
    uint256 input;
    uint256 timestamp;
    timestamp = m_playersStorage.playerTimestamp(msg.sender);
    input = m_playersStorage.playerInput(msg.sender);
    
     
    require(now >= timestamp.add(DELAY_ON_EXIT));
    
     
    uint256 outputInPonzi = calcOutput(input, now.sub(timestamp).div(COMPOUNDING_FREQ));
    
    assert(outputInPonzi > 0);
    
     
    uint256 outputInWei = ponziToWei(outputInPonzi, m_ponziPriceInWei);
    
     
    m_playersStorage.deletePlayer(msg.sender);
    
    if (m_ponziPriceInWei > 0 && address(this).balance >= outputInWei) {
       
       
      
       
       
      uint256 oldBalance = address(this).balance;
      msg.sender.transfer(outputInWei);
      assert(address(this).balance.add(outputInWei) >= oldBalance);
      
    } else if (m_ponziToken.balanceOf(address(this)) >= outputInPonzi) {
       
       
      
      uint256 oldPonziBalance = m_ponziToken.balanceOf(address(this));
      assert(m_ponziToken.transfer(msg.sender, outputInPonzi));
      assert(m_ponziToken.balanceOf(address(this)).add(outputInPonzi) == oldPonziBalance);
    } else {
       
       
      assert(m_ponziToken.transfer(msg.sender, m_ponziToken.balanceOf(address(this))));
      assert(m_ponziToken.balanceOf(address(this)) == 0);
      nextLevel();
    }
  }
  
   
  function playerInfo(address addr) 
    public 
    view 
    atState(State.Active)
    gameIsAvailable()
    returns(uint256 input, uint256 timestamp, bool inGame) 
  {
    (input, timestamp, inGame) = m_playersStorage.playerInfo(addr);
  }
  
   
  function playerOutputAtNow(address addr) 
    public 
    view 
    atState(State.Active) 
    gameIsAvailable()
    returns(uint256 amount)
  {
    if (!m_playersStorage.playerExist(addr)) {
      return 0;
    }
    uint256 input = m_playersStorage.playerInput(addr);
    uint256 timestamp = m_playersStorage.playerTimestamp(addr);
    uint256 numberOfPayout = now.sub(timestamp).div(COMPOUNDING_FREQ);
    amount = calcOutput(input, numberOfPayout);
  }
  
   
  function playerDelayOnExit(address addr) 
    public 
    view 
    atState(State.Active) 
    gameIsAvailable()
    returns(uint256 delay) 
  {
    if (!m_playersStorage.playerExist(addr)) {
      return 0;
    }
    uint256 timestamp = m_playersStorage.playerTimestamp(msg.sender);
    if (now >= timestamp.add(DELAY_ON_EXIT)) {
      delay = 0;
    } else {
      delay = timestamp.add(DELAY_ON_EXIT).sub(now);
    }
  }
  
   
  function enter(uint256 input, address referralAddress) 
    external 
    atState(State.Active)
    gameIsAvailable()
  {
    require(m_ponziToken.transferFrom(msg.sender, address(this), input));
    require(newPlayer(msg.sender, input, referralAddress));
  }
  
   
  function priceSetter() external view returns(address) {
    return m_priceSetter;
  }
  

   
  function ponziPriceInWei() 
    external 
    view 
    atState(State.Active)  
    returns(uint256) 
  {
    return m_ponziPriceInWei;
  }
  
   
  function compoundingFreq() 
    external 
    view 
    atState(State.Active) 
    returns(uint256) 
  {
    return COMPOUNDING_FREQ;
  }
  
   
  function interestRate() 
    external 
    view
    atState(State.Active)
    returns(uint256 numerator, uint256 denominator) 
  {
    numerator = m_interestRateNumerator;
    denominator = INTEREST_RATE_DENOMINATOR;
  }
  
   
  function level() 
    external 
    view 
    atState(State.Active)
    returns(uint256) 
  {
    return m_level;
  }
  
   
  function state() external view returns(string) {
    if (m_state == State.NotActive) 
      return NOT_ACTIVE_STR;
    else
      return ACTIVE_STR;
  }
  
   
  function levelStartupTimestamp() 
    external 
    view 
    atState(State.Active)
    returns(uint256) 
  {
    return m_levelStartupTimestamp;
  }
  
   
  function totalPonziInGame() 
    external 
    view 
    returns(uint256) 
  {
    return m_ponziToken.balanceOf(address(this));
  }
  
   
  function currentDelayOnNewLevel() 
    external 
    view 
    atState(State.Active)
    returns(uint256 delay) 
  {
    if (now >= m_levelStartupTimestamp.add(DELAY_ON_NEW_LEVEL)) {
      delay = 0;
    } else {
      delay = m_levelStartupTimestamp.add(DELAY_ON_NEW_LEVEL).sub(now);
    }  
  }

 
 
 
   
  function tokenFallback(address from, uint256 amount, bytes data) 
    public
    atState(State.Active)
    gameIsAvailable()
    onlyPonziToken()
    returns (bool)
  {
    address referralAddress = bytesToAddress(data);
    require(newPlayer(from, amount, referralAddress));
    return true;
  }
  
    
  function setPonziPriceinWei(uint256 newPrice) 
    public
    atState(State.Active)   
  {
    require(msg.sender == m_owner || msg.sender == m_priceSetter);
    m_ponziPriceInWei = newPrice;
    PonziPriceChanged(msg.sender, m_ponziPriceInWei);
  }
  
    
  function disown() public onlyOwner() atState(State.Active) {
    delete m_owner;
  }
  
    
  function setState(string newState) public onlyOwner() checkAccess() {
    if (keccak256(newState) == keccak256(NOT_ACTIVE_STR)) {
      m_state = State.NotActive;
    } else if (keccak256(newState) == keccak256(ACTIVE_STR)) {
      if (address(m_playersStorage) == address(0)) 
        m_playersStorage = (new PlayersStorage());
      m_state = State.Active;
    } else {
       
      revert();
    }
    StateChanged(msg.sender, m_state);
  }

   
  function setPriceSetter(address newPriceSetter) 
    public 
    onlyOwner() 
    checkAccess()
    atState(State.Active) 
  {
    m_priceSetter = newPriceSetter;
  }
  
   
  function newPlayer(address addr, uint256 inputAmount, address referralAddr)
    private
    returns(bool)
  {
    uint256 input = inputAmount;
     
     
     
     
    if (m_playersStorage.playerExist(addr) || input < 1000) 
      return false;
    
     
    if (m_playersStorage.playerExist(referralAddr)) {
       
       
       
      uint256 newPlayerInput = inputAmount.mul(uint256(100).sub(PERCENT_REFERRAL_BOUNTY)).div(100);
      uint256 referralInput = m_playersStorage.playerInput(referralAddr);
      referralInput = referralInput.add(inputAmount.sub(newPlayerInput));
      
       
      assert(m_playersStorage.playerSetInput(referralAddr, referralInput));
       
      input = newPlayerInput;
    }
     
    assert(m_playersStorage.newPlayer(addr, input, now));
    NewPlayer(addr, input, now);
    return true;
  }
  
   
  function calcOutput(uint256 input, uint256 numberOfPayout) 
    private
    view
    returns(uint256 output)
  {
    output = input;
    uint256 counter = numberOfPayout;
     
    while (counter > 0) {
      output = output.add(output.mul(m_interestRateNumerator).div(INTEREST_RATE_DENOMINATOR));
      counter = counter.sub(1);
    }
     
    output = output.mul(uint256(100).sub(PERCENT_TAX_ON_EXIT)).div(100); 
  }
  
   
  function nextLevel() private {
    m_playersStorage.kill();
    m_playersStorage = (new PlayersStorage());
    m_level = m_level.add(1);
    m_interestRateNumerator = calcInterestRateNumerator(m_level);
    m_levelStartupTimestamp = now;
    NewLevel(now, m_level);
  }
  
   
  function calcInterestRateNumerator(uint256 newLevel) 
    internal 
    pure 
    returns(uint256 numerator) 
  {
     
     
     
     
     
     
     
    
     
     
     
     
    
     

    if (newLevel <= 5) {
       
      numerator = uint256(6).sub(newLevel).mul(10);
    } else if ( newLevel >= 6 && newLevel <= 14) {
       
      numerator = uint256(15).sub(newLevel);
    } else {
       
      numerator = 1;
    }
  }
  
   
  function ponziToWei(uint256 tokensAmount, uint256 tokenPrice) 
    internal
    pure
    returns(uint256 weiAmount)
  {
    weiAmount = tokensAmount.mul(tokenPrice); 
  } 

   
  function bytesToAddress(bytes source) internal pure returns(address parsedReferer) {
    assembly {
      parsedReferer := mload(add(source,0x14))
    }
    return parsedReferer;
  }
}