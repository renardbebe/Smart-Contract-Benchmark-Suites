 

pragma solidity ^0.4.18;

 
 
 
 

 
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
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

 
contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

 
 
 
 
 
 
 
 
contract BoomrCoinCrowdsale is Ownable{
  using SafeMath for uint256;

   
   
   

   
  uint256 private minGoal = 0;

   
  uint256 private maxGoal = 0;

   
  uint256 private tokenLimitPresale    =  0;

   
  uint256 private tokenLimitCrowdsale  = 0;

   
  uint256 private presaleDiscount    = 0;
  uint256 private crowdsaleDiscount1 = 0;
  uint256 private crowdsaleDiscount2 = 0;
  uint256 private crowdsaleDiscount3 = 0;
  uint256 private crowdsaleDiscount4 = 0;

   
  uint256 private  presaleDuration    = 0; 
  uint256 private  crowdsaleDuration1 = 0; 
  uint256 private  crowdsaleDuration2 = 0; 
  uint256 private  crowdsaleDuration3 = 0; 
  uint256 private  crowdsaleDuration4 = 0; 

   
   
   

   
  uint256 private tokenPresaleTotalSold  = 0;
  uint256 private tokenCrowdsaleTotalSold  = 0;

   
  uint256 private totalBackers  = 0;

   
  uint256 private weiRaised = 0;

   
  uint256 private presaleTokenPrice    = 0;
  uint256 private baseTokenPrice = 0;
  uint256 private crowdsaleTokenPrice1 = 0;
  uint256 private crowdsaleTokenPrice2 = 0;
  uint256 private crowdsaleTokenPrice3 = 0;
  uint256 private crowdsaleTokenPrice4 = 0;

   
  uint256 private presaleTokenSent     = 0;
  uint256 private crowdsaleTokenSold1  = 0;
  uint256 private crowdsaleTokenSold2  = 0;
  uint256 private crowdsaleTokenSold3  = 0;
  uint256 private crowdsaleTokenSold4  = 0;

   
   
   

   
  bool private finalized = false;

   
  bool private halted = false;

  uint256 public startTime;

   
  PausableToken public boomrToken;

   
  address private wallet;

   
  RefundVault private vault;

   
  mapping (address => uint256) public deposits;

   
  mapping (address => uint256) public purchases;

   
   
   

   
  event TokenPurchase(address indexed Purchaser, address indexed Beneficiary, uint256 ValueInWei, uint256 TokenAmount);

   
  event PresalePurchase(address indexed Purchaser, address indexed Beneficiary, uint256 ValueInWei);

   
  event PresaleDistribution(address indexed Purchaser, address indexed Beneficiary, uint256 TokenAmount);

   
  event Finalized();

   
   
   
  function BoomrCoinCrowdsale() public{

  }

  function StartCrowdsale(address _token, address _wallet, uint256 _startTime) public onlyOwner{
    require(_startTime >= now);
    require(_token != 0x0);
    require(_wallet != 0x0);

     
    startTime = _startTime;

     
    boomrToken = PausableToken(_token);

     
    wallet = _wallet;

     
    vault = new RefundVault(wallet);

     
    minGoal = 5000 * 10**18;  
     

     
    maxGoal = 28600 * 10**18;  
     

     
    tokenLimitPresale    =  30000000 * 10**18;
     

     
    tokenLimitCrowdsale  = 120000000 * 10**18;
     

     
    presaleDiscount    = 25 * 10**16;   
    crowdsaleDiscount1 = 15 * 10**16;   
    crowdsaleDiscount2 = 10 * 10**16;   
    crowdsaleDiscount3 =  5 * 10**16;   
    crowdsaleDiscount4 =           0;   

     
    presaleDuration    = 604800;  
    crowdsaleDuration1 = 604800;  
    crowdsaleDuration2 = 604800;  
    crowdsaleDuration3 = 604800;  
    crowdsaleDuration4 = 604800;  

  }

   
   
   

  function currentStateActive() public constant returns ( bool presaleWaitPhase,
                                                          bool presalePhase,
                                                          bool crowdsalePhase1,
                                                          bool crowdsalePhase2,
                                                          bool crowdsalePhase3,
                                                          bool crowdsalePhase4,
                                                          bool buyable,
                                                          bool distributable,
                                                          bool reachedMinimumEtherGoal,
                                                          bool reachedMaximumEtherGoal,
                                                          bool completed,
                                                          bool finalizedAndClosed,
                                                          bool stopped){

    return (  isPresaleWaitPhase(),
              isPresalePhase(),
              isCrowdsalePhase1(),
              isCrowdsalePhase2(),
              isCrowdsalePhase3(),
              isCrowdsalePhase4(),
              isBuyable(),
              isDistributable(),
              minGoalReached(),
              maxGoalReached(),
              isCompleted(),
              finalized,
              halted);
  }

  function currentStateSales() public constant returns (uint256 PresaleTokenPrice,
                                                        uint256 BaseTokenPrice,
                                                        uint256 CrowdsaleTokenPrice1,
                                                        uint256 CrowdsaleTokenPrice2,
                                                        uint256 CrowdsaleTokenPrice3,
                                                        uint256 CrowdsaleTokenPrice4,
                                                        uint256 TokenPresaleTotalSold,
                                                        uint256 TokenCrowdsaleTotalSold,
                                                        uint256 TotalBackers,
                                                        uint256 WeiRaised,
                                                        address Wallet,
                                                        uint256 GoalInWei,
                                                        uint256 RemainingTokens){

    return (  presaleTokenPrice,
              baseTokenPrice,
              crowdsaleTokenPrice1,
              crowdsaleTokenPrice2,
              crowdsaleTokenPrice3,
              crowdsaleTokenPrice4,
              tokenPresaleTotalSold,
              tokenCrowdsaleTotalSold,
              totalBackers,
              weiRaised,
              wallet,
              minGoal,
              getContractTokenBalance());

  }

  function currentTokenDistribution() public constant returns (uint256 PresalePhaseTokens,
                                                               uint256 CrowdsalePhase1Tokens,
                                                               uint256 CrowdsalePhase2Tokens,
                                                               uint256 CrowdsalePhase3Tokens,
                                                               uint256 CrowdsalePhase4Tokens){

    return (  presaleTokenSent,
              crowdsaleTokenSold1,
              crowdsaleTokenSold2,
              crowdsaleTokenSold3,
              crowdsaleTokenSold4);

  }

  function isPresaleWaitPhase() internal constant returns (bool){
    return startTime >= now;
  }

  function isPresalePhase() internal constant returns (bool){
    return startTime < now && (startTime + presaleDuration) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase1() internal constant returns (bool){
    return (startTime + presaleDuration) < now && (startTime + presaleDuration + crowdsaleDuration1) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase2() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1) < now && (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase3() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2) < now && (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3) >= now && !maxGoalReached();
  }

  function isCrowdsalePhase4() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3) < now && (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3 + crowdsaleDuration4) >= now && !maxGoalReached();
  }

  function isCompleted() internal constant returns (bool){
    return (startTime + presaleDuration + crowdsaleDuration1 + crowdsaleDuration2 + crowdsaleDuration3 + crowdsaleDuration4) < now || maxGoalReached();
  }

  function isDistributable() internal constant returns (bool){
    return (startTime + presaleDuration) < now;
  }

  function isBuyable() internal constant returns (bool){
    return isDistributable() && !isCompleted();
  }

   
  function minGoalReached() internal constant returns (bool) {
    return weiRaised >= minGoal;
  }

  function maxGoalReached() internal constant returns (bool) {
    return weiRaised >= maxGoal;
  }

   
   
   
  function getContractTokenBalance() internal constant returns (uint256) {
    return boomrToken.balanceOf(this);
  }

   
   
   
  function halt() public onlyOwner{
    halted = true;
  }

  function unHalt() public onlyOwner{
    halted = false;
  }

   
   
   
  function updatePrices() internal {

    presaleTokenPrice = weiRaised.mul(1 ether).div(tokenLimitPresale);
    baseTokenPrice = (presaleTokenPrice * (1 ether)) / ((1 ether) - presaleDiscount);
    crowdsaleTokenPrice1 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount1)/(1 ether));
    crowdsaleTokenPrice2 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount2)/(1 ether));
    crowdsaleTokenPrice3 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount3)/(1 ether));
    crowdsaleTokenPrice4 = baseTokenPrice - ((baseTokenPrice * crowdsaleDiscount4)/(1 ether));
  }

   
   
   
  function () public payable{
    if(msg.value == 0 && isDistributable())
    {
      distributePresale(msg.sender);
    }else{
      require(!isPresaleWaitPhase() && !isCompleted());

       
      if (isPresalePhase()){

         
        depositPresale(msg.sender);

      }else{
         
        buyTokens(msg.sender);
      }
    }
  }

   
   
   
  function depositPresale(address beneficiary) public payable{
    internalDepositPresale(beneficiary, msg.value);
  }

  function internalDepositPresale(address beneficiary, uint256 deposit) internal{
    require(!halted);
    require(beneficiary != 0x0);
    require(deposit != 0);
    require(isPresalePhase());
    require(!maxGoalReached());

     
    uint256 weiAmount = deposit;

     
     
     
    if (msg.value > 0)
    {
       
      forwardFunds();
    }

     
    weiRaised = weiRaised.add(weiAmount);

     
    deposits[beneficiary] += weiAmount;
    totalBackers++;

     
    updatePrices();

     
    PresalePurchase(msg.sender, beneficiary, weiAmount);
  }

   
   
   
  function distributePresale(address beneficiary) public{
    require(!halted);
    require(isDistributable());
    require(deposits[beneficiary] > 0);
    require(beneficiary != 0x0);

     
    uint256 weiDeposit = deposits[beneficiary];

     
    deposits[beneficiary] = 0;

     
    uint256 tokensOut = weiDeposit.mul(1 ether).div(presaleTokenPrice);

     
    tokenPresaleTotalSold += tokensOut;
     

     
    boomrToken.transfer(beneficiary, tokensOut);

     
    PresaleDistribution(msg.sender, beneficiary, tokensOut);
  }

   
   
   
  function buyTokens(address beneficiary) public payable{
    internalBuyTokens(beneficiary, msg.value);
  }

  function internalBuyTokens(address beneficiary, uint256 deposit) internal{
    require(!halted);
    require(beneficiary != 0x0);
    require(deposit != 0);
    require(isCrowdsalePhase1() || isCrowdsalePhase2() || isCrowdsalePhase3() || isCrowdsalePhase4());
    require(!maxGoalReached());

    uint256 price = 0;

    if (isCrowdsalePhase1()){
      price = crowdsaleTokenPrice1;
    }else if (isCrowdsalePhase2()){
      price = crowdsaleTokenPrice2;
    }else if (isCrowdsalePhase3()){
      price = crowdsaleTokenPrice3;
    }else if (isCrowdsalePhase4()){
      price = crowdsaleTokenPrice4;
    }else{
      price = baseTokenPrice;
    }

     
    uint256 weiAmount = deposit;

     
    uint256 tokensOut = weiAmount.mul(1 ether).div(price);

     
    require(tokensOut + tokenCrowdsaleTotalSold < tokenLimitCrowdsale);

     
     
     
    if (msg.value > 0)
    {
       
      forwardFunds();
    }

     
    weiRaised = weiRaised.add(weiAmount);

     
    purchases[beneficiary] += weiRaised;

     
    tokenCrowdsaleTotalSold += tokensOut;

    if (isCrowdsalePhase1()){
      crowdsaleTokenSold1 += tokensOut;
    }else if (isCrowdsalePhase2()){
      crowdsaleTokenSold2 += tokensOut;
    }else if (isCrowdsalePhase3()){
      crowdsaleTokenSold3 += tokensOut;
    }else if (isCrowdsalePhase4()){
      crowdsaleTokenSold4 += tokensOut;
    }

     
    boomrToken.transfer(beneficiary, tokensOut);

     
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokensOut);

     
    totalBackers++;
  }

   
  function externalDeposit(address beneficiary, uint256 amount) public onlyOwner{
      require(!isPresaleWaitPhase() && !isCompleted());

       
      if (isPresalePhase()){

         
        internalDepositPresale(beneficiary, amount);

      }else{
         
        internalBuyTokens(beneficiary, amount);
      }
  }

   
   
  function forwardFunds() internal {
     
    vault.deposit.value(msg.value)(msg.sender);
  }

     
  function claimRefund() public{
    require(!halted);
    require(finalized);
    require(!minGoalReached());

    vault.refund(msg.sender);
  }

   
   
  function finalize() public onlyOwner{
    require(!finalized);
    require(isCompleted());

    if (minGoalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    finalized = true;
    Finalized();
  }
}