 

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
  address public owner;


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    owner = newOwner;
  }

}

 
contract ERC20 is Ownable {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function transfer(address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
}


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}

 
contract ReleasableToken is StandardToken {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  modifier canTransfer(address _sender) {
    require(released || transferAgents[_sender]);
    _;
  }

   
  modifier inReleaseState(bool releaseState) {
    require(releaseState == released);
    _;
  }

   
  modifier onlyReleaseAgent() {
    require(msg.sender == releaseAgent);
    _;
  }

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {

     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 

contract MintableToken is ReleasableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

 
contract UpgradeAgent {

  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

  function upgradeFrom(address _from, uint256 _value) public;

}


 
contract UpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint256 public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint256 _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) {
    upgradeMaster = _upgradeMaster;
  }

   
  function upgrade(uint256 value) public {

      UpgradeState state = getUpgradeState();
      if(!(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading)) {
         
        throw;
      }

       
      if (value == 0) throw;

      balances[msg.sender] = balances[msg.sender].sub(value);

       
      totalSupply = totalSupply.sub(value);
      totalUpgraded = totalUpgraded.add(value);

       
      upgradeAgent.upgradeFrom(msg.sender, value);
      Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {

      if (agent == 0x0) throw;
       
      if (msg.sender != upgradeMaster) throw;
       
      if (getUpgradeState() == UpgradeState.Upgrading) throw;

      upgradeAgent = UpgradeAgent(agent);

       
      if(!upgradeAgent.isUpgradeAgent()) throw;
       
      if (upgradeAgent.originalSupply() != totalSupply) throw;

      UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if(address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if(totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function setUpgradeMaster(address master) public {
      if (master == 0x0) throw;
      if (msg.sender != upgradeMaster) throw;
      upgradeMaster = master;
  }


}

 
contract MatryxToken is MintableToken, UpgradeableToken{

  string public name = "MatryxToken";
  string public symbol = "MTX";
  uint public decimals = 18;

   
  function MatryxToken() UpgradeableToken(msg.sender) {

  }
}

 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
     
    require(!halted);
    _;
  }

  modifier onlyInEmergency {
     
    require(halted);
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


 
contract Crowdsale is Ownable, Haltable {
  using SafeMath for uint256;

   
  MatryxToken public token;

   
  uint256 public presaleStartTime;
  uint256 public startTime;
  uint256 public endTime;

   
  uint public purchaserCount = 0;

   
  address public wallet;

   
  uint256 public baseRate = 1164;

   
  uint256 public tierTwoRate = 1294;

   
  uint256 public tierThreeRate = 1371;

   
  uint256 public whitelistRate = 1456;

   
  uint256 public tierOnePurchase = 75 * 10**18;

   
  uint256 public tierTwoPurchase = 150 * 10**18;

   
  uint256 public tierThreePurchase = 300 * 10**18;

   
  uint256 public weiRaised;

   
  uint256 public cap = 161803 * 10**18;

   
  uint256 public presaleCap = 809015 * 10**17;

   
  bool public isFinalized = false;

   
  mapping (address => uint256) public purchasedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => bool) public whitelist;

    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  event Whitelisted(address addr, bool status);

   
  event EndsAtChanged(uint newEndsAt);

  event Finalized();

  function Crowdsale(uint256 _presaleStartTime, uint256 _startTime, uint256 _endTime, address _wallet, address _token) {
    require(_startTime >= now);
    require(_presaleStartTime >= now && _presaleStartTime < _startTime);
    require(_endTime >= _startTime);
    require(_wallet != 0x0);
    require(_token != 0x0);

    token = MatryxToken(_token);
    wallet = _wallet;
    presaleStartTime = _presaleStartTime;
    startTime = _startTime;
    endTime = _endTime;
  }

   
  function () {
    throw;
  }

   
  function buy() public payable {
    buyTokens(msg.sender);
  }
  
   
   
  function buyTokens(address beneficiary) stopInEmergency payable {
    require(beneficiary != 0x0);
    require(msg.value != 0);
    
    if(isPresale()) {
      require(validPrePurchase());
      buyPresale(beneficiary);
    } else {
      require(validPurchase());
      buySale(beneficiary);
    }
  }

  function buyPresale(address beneficiary) internal {
    uint256 weiAmount = msg.value;
    uint256 tokens = 0;
    
     
    if(whitelist[msg.sender]) {
      tokens = weiAmount.mul(whitelistRate);
    } else if(weiAmount < tierTwoPurchase) {
       
      tokens = weiAmount.mul(baseRate);
    } else if(weiAmount < tierThreePurchase) {
       
      tokens = weiAmount.mul(tierTwoRate);
    } else {
       
      tokens = weiAmount.mul(tierThreeRate);
    }

     
    weiRaised = weiRaised.add(weiAmount);

     
    if(purchasedAmountOf[msg.sender] == 0) purchaserCount++;
    purchasedAmountOf[msg.sender] = purchasedAmountOf[msg.sender].add(msg.value);
    tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);

    token.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  function buySale(address beneficiary) internal {
    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(baseRate);

     
    weiRaised = weiRaised.add(weiAmount);

     
    if(purchasedAmountOf[msg.sender] == 0) purchaserCount++;
    purchasedAmountOf[msg.sender] = purchasedAmountOf[msg.sender].add(msg.value);
    tokenAmountOf[msg.sender] = tokenAmountOf[msg.sender].add(tokens);

    token.mint(beneficiary, tokens);

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();
    
    isFinalized = true;
  }

   
  function finalization() internal {
     
     
    uint256 piTokens = 314159265*10**18;
     
    uint256 tokens = piTokens.sub(token.totalSupply());
     
    token.mint(wallet, tokens);
    token.finishMinting();
    token.transferOwnership(msg.sender);
    token.releaseTokenTransfer();
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function updateWhitelist(address _purchaser, bool _listed) onlyOwner {
    whitelist[_purchaser] = _listed;
    Whitelisted(_purchaser, _listed);
  }

   
  function setEndsAt(uint time) onlyOwner {
    require(now < time);

    endTime = time;
    EndsAtChanged(endTime);
  }


   
  function validPrePurchase() internal constant returns (bool) {
     
     
    bool canPrePurchase = tierOnePurchase <= msg.value || whitelist[msg.sender];
    bool withinCap = weiRaised.add(msg.value) <= presaleCap;
    return canPrePurchase && withinCap;
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinPeriod && withinCap;
  }

   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return now > endTime || capReached;
  }

   
  function isPresale() public constant returns (bool) {
    bool withinPresale = now >= presaleStartTime && now < startTime;
    return withinPresale;
  }

}