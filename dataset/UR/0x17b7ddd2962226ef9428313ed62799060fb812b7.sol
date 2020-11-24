 

pragma solidity ^0.4.15;

 
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

 
contract Haltable is Ownable {
  bool public halted;

  event Halted(bool halted);

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
    Halted(true);
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
    Halted(false);
  }

}

 
library SafeMath {
  function mul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint a, uint b) internal returns (uint) {
     
    uint c = a / b;
     
    return c;
  }

  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint a, uint b) internal constant returns (uint) {
    return a >= b ? a : b;
  }

  function min256(uint a, uint b) internal constant returns (uint) {
    return a < b ? a : b;
  }
}

 
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

   
  function isSane(CrowdsaleToken token) public constant returns (bool);

   
  function finalizeCrowdsale(CrowdsaleToken token) public;

}

 
contract GenericCrowdsale is Haltable {

  using SafeMath for uint;

   
  CrowdsaleToken public token;

   
  FinalizeAgent public finalizeAgent;

   
  address public multisigWallet;

   
  uint public minimumFundingGoal;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized = false;

   
  bool public requireCustomerId = false;

   
  mapping (address => uint) public investedAmountOf;

   
  mapping (address => uint) public tokenAmountOf;

   
  mapping (address => bool) public earlyParticipantWhitelist;

   
  uint8 public ownerTestValue;

   
  enum State{Unknown, PreFunding, Funding, Success, Failure, Finalized, Refunding}


   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Refund(address investor, uint weiAmount);

   
  event InvestmentPolicyChanged(bool requireCId);

   
  event Whitelisted(address addr, bool status);

   
  event Finalized();


  function GenericCrowdsale(address team_multisig, uint start, uint end, uint min_goal) internal {
    setMultisig(team_multisig);

     
    require(start != 0 && end != 0);
    require(block.number < start && start < end);
    startsAt = start;
    endsAt = end;

     
    minimumFundingGoal = min_goal;
  }

   
  function() payable {
    require(false);
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency notFinished private {
     
    if (getState() == State.PreFunding) {
       
      require(earlyParticipantWhitelist[receiver]);
    }

    uint weiAllowedAmount = weiAllowedToReceive(msg.value, receiver);
    uint tokenAmount = calculatePrice(weiAllowedAmount, msg.sender);
    
     
    require(tokenAmount != 0);

    if (investedAmountOf[receiver] == 0) {
       
      investorCount++;
    }
    updateInvestorFunds(tokenAmount, weiAllowedAmount, receiver, customerId);

     
    multisigWallet.transfer(weiAllowedAmount);

     
    uint weiToReturn = msg.value.sub(weiAllowedAmount);
    if (weiToReturn > 0) {
      msg.sender.transfer(weiToReturn);
    }
  }

   
  function weiAllowedToReceive(uint weiAmount, address customer) internal constant returns (uint weiAllowed);

   
  function calculatePrice(uint weiAmount, address customer) internal constant returns (uint tokenAmount);

   
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner notFinished {
    require(receiver != address(0));
    uint tokenAmount = fullTokens.mul(10**uint(token.decimals()));
    require(tokenAmount != 0);
    uint weiAmount = weiPrice.mul(tokenAmount);  
    updateInvestorFunds(tokenAmount, weiAmount, receiver , 0);
  }

   
  function updateInvestorFunds(uint tokenAmount, uint weiAmount, address receiver, uint128 customerId) private {
     
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);

    assignTokens(receiver, tokenAmount);
     
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }



   
  function buyWithCustomerId(uint128 customerId) public payable {
    require(customerId != 0);   
    investInternal(msg.sender, customerId);
  }

   
  function buy() public payable {
    require(!requireCustomerId);  
    investInternal(msg.sender, 0);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    if (address(finalizeAgent) != 0)
      finalizeAgent.finalizeCrowdsale(token);
    finalized = true;
    Finalized();
  }

   
  function setRequireCustomerId(bool value) public onlyOwner stopInEmergency {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId);
  }

   
  function setEarlyParticipantWhitelist(address addr, bool status) public onlyOwner notFinished stopInEmergency {
    earlyParticipantWhitelist[addr] = status;
    Whitelisted(addr, status);
  }

   
  function setFinalizeAgent(FinalizeAgent addr) internal {
     
    require(address(addr) == 0 || addr.isFinalizeAgent());
    finalizeAgent = addr;
    require(isFinalizerSane());
  }

   
  function setMultisig(address addr) internal {
    require(addr != 0);
    multisigWallet = addr;
  }

   
  function loadRefund() public payable inState(State.Failure) stopInEmergency {
    require(msg.value >= weiRaised);
    require(weiRefunded == 0);
    uint excedent = msg.value.sub(weiRaised);
    loadedRefund = loadedRefund.add(msg.value.sub(excedent));
    investedAmountOf[msg.sender].add(excedent);
  }

   
  function refund() public inState(State.Refunding) stopInEmergency {
    uint weiValue = investedAmountOf[msg.sender];
    require(weiValue != 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    Refund(msg.sender, weiValue);
    msg.sender.transfer(weiValue);
  }

   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

  function isCrowdsaleFull() internal constant returns (bool full);

   
  function isFinalizerSane() public constant returns (bool sane) {
    return address(finalizeAgent) == 0 || finalizeAgent.isSane(token);
  }

   
  function getState() public constant returns (State) {
    if (finalized) return State.Finalized;
    else if (block.number < startsAt) return State.PreFunding;
    else if (block.number <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

   
  function setOwnerTestValue(uint8 val) public onlyOwner stopInEmergency {
    ownerTestValue = val;
  }

   
  function assignTokens(address receiver, uint tokenAmount) internal;

   
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  modifier notFinished() {
    State current_state = getState();
    require(current_state == State.PreFunding || current_state == State.Funding);
    _;
  }

}


contract CappedCrowdsale is GenericCrowdsale {

   
  uint public weiFundingCap = 0;

   
  event FundingCapSet(uint newFundingCap);


   


  function setFundingCap(uint newCap) internal onlyOwner notFinished {
    weiFundingCap = newCap;
    require(weiFundingCap >= minimumFundingGoal);
    FundingCapSet(weiFundingCap);
  }
}

 
contract ERC20Basic {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
}


 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool ok);
  function approve(address spender, uint value) public returns (bool ok);
  event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract FractionalERC20 is ERC20 {

  uint8 public decimals;

}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint;

  mapping(address => uint) balances;

   

   
  function transfer(address _to, uint _value) public returns (bool success) {
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }
  
}

 
contract StandardToken is BasicToken, ERC20 {

   
  event Minted(address receiver, uint amount);

  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

   
  function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
    uint _allowance = allowed[_from][msg.sender];

     
     
     

    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint _value) public returns (bool success) {

     
     
     
     
    require (_value == 0 || allowed[msg.sender][_spender] == 0);

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

   
  function addApproval(address _spender, uint _addedValue) public
  returns (bool success) {
      uint oldValue = allowed[msg.sender][_spender];
      allowed[msg.sender][_spender] = oldValue.add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }

   
  function subApproval(address _spender, uint _subtractedValue) public
  returns (bool success) {

      uint oldVal = allowed[msg.sender][_spender];

      if (_subtractedValue > oldVal) {
          allowed[msg.sender][_spender] = 0;
      } else {
          allowed[msg.sender][_spender] = oldVal.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
  }
  
}

 
contract ReleasableToken is StandardToken, Ownable {

   
  address public releaseAgent;

   
  bool public released = false;

   
  mapping (address => bool) public transferAgents;

   
  function setReleaseAgent(address addr) onlyOwner inReleaseState(false) public {
     
    releaseAgent = addr;
  }

   
  function setTransferAgent(address addr, bool state) onlyOwner inReleaseState(false) public {
    transferAgents[addr] = state;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

   
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

   
  function transfer(address _to, uint _value) public canTransfer(msg.sender) returns (bool success) {
     
   return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) public canTransfer(_from) returns (bool success) {
     
    return super.transferFrom(_from, _to, _value);
  }

}

 
contract MintableToken is StandardToken, Ownable {

  using SafeMath for uint;

  bool public mintingFinished = false;

   
  mapping (address => bool) public mintAgents;

  event MintingAgentChanged(address addr, bool state);


  function MintableToken(uint _initialSupply, address _multisig, bool _mintable) internal {
    require(_multisig != address(0));
     
    require(_mintable || _initialSupply != 0);
     
    if (_initialSupply > 0)
        mintInternal(_multisig, _initialSupply);
     
    mintingFinished = !_mintable;
  }

   
  function mint(address receiver, uint amount) onlyMintAgent public {
    mintInternal(receiver, amount);
  }

  function mintInternal(address receiver, uint amount) canMint private {
    totalSupply = totalSupply.add(amount);
    balances[receiver] = balances[receiver].add(amount);

     
     
    Transfer(0, receiver, amount);

    Minted(receiver, amount);
  }

   
  function setMintAgent(address addr, bool state) onlyOwner canMint public {
    mintAgents[addr] = state;
    MintingAgentChanged(addr, state);
  }

  modifier onlyMintAgent() {
     
    require(mintAgents[msg.sender]);
    _;
  }

   
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
}

 
contract UpgradeAgent {

   
  uint public originalSupply;

   
  function isUpgradeAgent() public constant returns (bool) {
    return true;
  }

   
  function upgradeFrom(address _from, uint _value) public;

}

 
contract UpgradeableToken is StandardToken {

   
  address public upgradeMaster;

   
  UpgradeAgent public upgradeAgent;

   
  uint public totalUpgraded;

   
  enum UpgradeState {Unknown, NotAllowed, WaitingForAgent, ReadyToUpgrade, Upgrading}

   
  event Upgrade(address indexed _from, address indexed _to, uint _value);

   
  event UpgradeAgentSet(address agent);

   
  function UpgradeableToken(address _upgradeMaster) {
    setUpgradeMaster(_upgradeMaster);
  }

   
  function upgrade(uint value) public {
    UpgradeState state = getUpgradeState();
     
    require(state == UpgradeState.ReadyToUpgrade || state == UpgradeState.Upgrading);

     
    require(value != 0);

    balances[msg.sender] = balances[msg.sender].sub(value);

     
    totalSupply = totalSupply.sub(value);
    totalUpgraded = totalUpgraded.add(value);

     
    upgradeAgent.upgradeFrom(msg.sender, value);
    Upgrade(msg.sender, upgradeAgent, value);
  }

   
  function setUpgradeAgent(address agent) external {
     
    require(canUpgrade());

    require(agent != 0x0);
     
    require(msg.sender == upgradeMaster);
     
    require(getUpgradeState() != UpgradeState.Upgrading);

    upgradeAgent = UpgradeAgent(agent);

     
    require(upgradeAgent.isUpgradeAgent());
     
    require(upgradeAgent.originalSupply() == totalSupply);

    UpgradeAgentSet(upgradeAgent);
  }

   
  function getUpgradeState() public constant returns(UpgradeState) {
    if (!canUpgrade()) return UpgradeState.NotAllowed;
    else if (address(upgradeAgent) == 0x00) return UpgradeState.WaitingForAgent;
    else if (totalUpgraded == 0) return UpgradeState.ReadyToUpgrade;
    else return UpgradeState.Upgrading;
  }

   
  function changeUpgradeMaster(address new_master) public {
    require(msg.sender == upgradeMaster);
    setUpgradeMaster(new_master);
  }

   
  function setUpgradeMaster(address new_master) private {
    require(new_master != 0x0);
    upgradeMaster = new_master;
  }

   
  function canUpgrade() public constant returns(bool) {
     return true;
  }

}


 
contract CrowdsaleToken is ReleasableToken, MintableToken, UpgradeableToken, FractionalERC20 {

  event UpdatedTokenInformation(string newName, string newSymbol);

  string public name;

  string public symbol;

   
  function CrowdsaleToken(string _name, string _symbol, uint _initialSupply, uint8 _decimals, address _multisig, bool _mintable)
    UpgradeableToken(_multisig) MintableToken(_initialSupply, _multisig, _mintable) {
    name = _name;
    symbol = _symbol;
    decimals = _decimals;
  }

   
  function releaseTokenTransfer() public onlyReleaseAgent {
    mintingFinished = true;
    super.releaseTokenTransfer();
  }

   
  function canUpgrade() public constant returns(bool) {
    return released && super.canUpgrade();
  }

   
  function setTokenInformation(string _name, string _symbol) onlyOwner {
    name = _name;
    symbol = _symbol;

    UpdatedTokenInformation(name, symbol);
  }

}

 
contract Crowdsale is CappedCrowdsale {
  uint private constant minimum_funding = 0 * (10 ** 18);  

  uint private constant token_initial_supply = 0;
  uint8 private constant token_decimals = 16;
  bool private constant token_mintable = true;
  string private constant token_name = "Ribbits";
  string private constant token_symbol = "RNT";

  uint private constant fundingCap = uint(100000000 * (10 ** 18)) / 2700;


  uint private constant decimalTokensPerWei2Eth = 25;
  uint private constant decimalTokensPerWei20Eth = 26;
  uint private constant decimalTokensPerWei50Eth = 27;

  mapping (address => bool) public discountedInvestors;


  function Crowdsale(address team_multisig, uint start, uint end) GenericCrowdsale(team_multisig, start, end, minimum_funding) public {
     
    token = new CrowdsaleToken(token_name, token_symbol, token_initial_supply, token_decimals, team_multisig, token_mintable);
    token.setMintAgent(address(this), true);
    setFundingCap(fundingCap);
  }

   
  function assignTokens(address receiver, uint tokenAmount) internal {
    token.mint(receiver, tokenAmount);
  }

   
  function setStartingBlock(uint startingBlock) public onlyOwner inState(State.PreFunding) {
    require(startingBlock > block.number && startingBlock < endsAt);
    startsAt = startingBlock;
  }

  function setEndingBlock(uint endingBlock) public onlyOwner notFinished {
    require(endingBlock > block.number && endingBlock > startsAt);
    endsAt = endingBlock;
  }

  modifier notLessThan2Eth() {
    require(investedAmountOf[msg.sender].add(msg.value) >= 2 * (10**18));
    _;
  }

   
  function calculatePrice(uint weiAmount, address customer) internal constant returns (uint) {
    uint investedAmount = investedAmountOf[customer].add(weiAmount);
    uint decimalTokensPerWei;
    if (investedAmount <= 20 * (10**18) && !discountedInvestors[customer]) {
      decimalTokensPerWei = decimalTokensPerWei2Eth;
    } else if (investedAmount <= 50 * (10**18)) {
      decimalTokensPerWei = decimalTokensPerWei20Eth;
    } else {
      decimalTokensPerWei = decimalTokensPerWei50Eth;
    }
    uint decimalTokens = weiAmount.mul(decimalTokensPerWei);
    return decimalTokens;
  }

   
  function buy() public payable notLessThan2Eth {
    super.buy();
  }

   
  function() payable {
    buy();
  }

   
  function setDiscountedInvestor(address addr, bool status) public onlyOwner notFinished stopInEmergency {
    discountedInvestors[addr] = status;
  }

   
  function weiAllowedToReceive(uint tentativeAmount, address) internal constant returns (uint) {
     
    if (weiFundingCap == 0) return tentativeAmount;
    uint total = tentativeAmount.add(weiRaised);
    if (total < weiFundingCap) return tentativeAmount;
    else return weiFundingCap.sub(weiRaised);
  }

  function isCrowdsaleFull() internal constant returns (bool) {
    return weiFundingCap > 0 && weiRaised >= weiFundingCap;
  }
}