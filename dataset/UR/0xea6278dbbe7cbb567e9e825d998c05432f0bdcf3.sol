 

pragma solidity ^0.4.14;

  
contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }
}
 
contract ERC20 {
 uint public totalSupply;
 function balanceOf(address who) constant returns (uint);
 function allowance(address owner, address spender) constant returns (uint);
 function mint(address receiver, uint amount);
 function transfer(address to, uint value) returns (bool ok);
 function transferFrom(address from, address to, uint value) returns (bool ok);
 function approve(address spender, uint value) returns (bool ok);
 event Transfer(address indexed from, address indexed to, uint value);
 event Approval(address indexed owner, address indexed spender, uint value);
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
   if (newOwner != address(0)) {
     owner = newOwner;
   }
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
  
contract Killable is Ownable {
  function kill() onlyOwner {
    selfdestruct(owner);
  }
}
  
contract SilentNotaryToken is SafeMath, ERC20, Killable {
  string constant public name = "Silent Notary Token";
  string constant public symbol = "SNTR";
  uint constant public decimals = 4;
   
  uint constant public buyOutPrice = 200 finney;
   
  address[] public holders;
   
  struct Balance {
     
    uint value;
     
    bool exist;
  }
   
  mapping(address => Balance) public balances;
   
  address public crowdsaleAgent;
   
  bool public released = false;
   
  mapping (address => mapping (address => uint)) allowed;

   
  modifier canTransfer() {
    if(!released)
      require(msg.sender == crowdsaleAgent);
    _;
  }

   
   
  modifier inReleaseState(bool _released) {
    require(_released == released);
    _;
  }

   
   
  modifier addIfNotExist(address holder) {
    if(!balances[holder].exist)
      holders.push(holder);
    _;
  }

   
  modifier onlyCrowdsaleAgent() {
    require(msg.sender == crowdsaleAgent);
    _;
  }

   
   
  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
  }

   
  modifier canMint() {
    require(!released);
    _;
  }

   
  event Burned(address indexed burner, address indexed holder, uint burnedAmount);
   
  event Pay(address indexed to, uint value);
   
  event Deposit(address indexed from, uint value);

   
  function SilentNotaryToken() {
  }

   
  function() payable {
    require(msg.value > 0);
    Deposit(msg.sender, msg.value);
  }
   
   
   
  function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint addIfNotExist(receiver) public {
      totalSupply = safeAdd(totalSupply, amount);
      balances[receiver].value = safeAdd(balances[receiver].value, amount);
      balances[receiver].exist = true;
      Transfer(0, receiver, amount);
  }

   
   
  function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
    crowdsaleAgent = _crowdsaleAgent;
  }
   
  function releaseTokenTransfer() public onlyCrowdsaleAgent {
    released = true;
  }
   
   
   
   
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) returns (bool success) {
    balances[msg.sender].value = safeSub(balances[msg.sender].value, _value);
    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_to].exist = true;
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
   
   
   
   
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer addIfNotExist(_to) returns (bool success) {
    var _allowance = allowed[_from][msg.sender];

    balances[_to].value = safeAdd(balances[_to].value, _value);
    balances[_from].value = safeSub(balances[_from].value, _value);
    balances[_to].exist = true;

    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }
   
   
   
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner].value;
  }

   
   
   
   
  function approve(address _spender, uint _value) returns (bool success) {
     
     
     
     
    require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
   
   
   
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
   
   
   
  function buyout(address _holder, uint _amount) onlyOwner addIfNotExist(msg.sender) external  {
    require(_holder != msg.sender);
    require(this.balance >= _amount);
    require(buyOutPrice <= _amount);

    uint multiplier = 10 ** decimals;
    uint buyoutTokens = safeDiv(safeMul(_amount, multiplier), buyOutPrice);

    balances[msg.sender].value = safeAdd(balances[msg.sender].value, buyoutTokens);
    balances[_holder].value = safeSub(balances[_holder].value, buyoutTokens);
    balances[msg.sender].exist = true;

    Transfer(_holder, msg.sender, buyoutTokens);

    _holder.transfer(_amount);
    Pay(_holder, _amount);
  }
}

 
contract SilentNotaryCrowdsale is Haltable, Killable, SafeMath {

  
 uint constant public DURATION = 14 days;

  
 uint public icoDuration = DURATION;

  
 SilentNotaryToken public token;

  
 address public multisigWallet;

  
 address public teamWallet;

  
 uint public startsAt;

  
 uint public tokensSold = 0;

  
 uint public weiRaised = 0;

  
 uint public investorCount = 0;

  
 uint public loadedRefund = 0;

  
 uint public weiRefunded = 0;

  
 bool public finalized;

  
 mapping (address => uint256) public investedAmountOf;

  
 mapping (address => uint256) public tokenAmountOf;

  
 uint public constant FUNDING_GOAL = 1000 ether;

  
 uint constant MULTISIG_WALLET_GOAL = FUNDING_GOAL;

  
 uint public constant MIN_INVESTEMENT = 100 finney;

  
 uint public constant MIN_PRICE = 10e9;

  
 uint public constant MAX_PRICE = 20e10;

  
 uint public constant INVESTOR_TOKENS  = 10e11;

  
 uint public constant TOTAL_TOKENS_FOR_PRICE = INVESTOR_TOKENS;

  
 uint public tokenPrice = MIN_PRICE;

   
   
   
   
   
   
   
 enum State{Unknown, Preparing, Funding, Success, Failure, Finalized, Refunding}

  
 event Invested(address investor, uint weiAmount, uint tokenAmount);

  
 event Refund(address investor, uint weiAmount);

  
 event EndsAtChanged(uint endsAt);

  
 event PriceChanged(uint oldValue, uint newValue);

  
 modifier inState(State state) {
   require(getState() == state);
   _;
 }

  
  
  
  
 function SilentNotaryCrowdsale(address _token, address _multisigWallet, address _teamWallet, uint _start) {
   require(_token != 0);
   require(_multisigWallet != 0);
   require(_teamWallet != 0);
   require(_start != 0);

   token = SilentNotaryToken(_token);
   multisigWallet = _multisigWallet;
   teamWallet = _teamWallet;
   startsAt = _start;
 }

  
 function() payable {
   buy();
 }

   
   
 function investInternal(address receiver) stopInEmergency private {
   require(getState() == State.Funding);
   require(msg.value >= MIN_INVESTEMENT);

   uint weiAmount = msg.value;

   var multiplier = 10 ** token.decimals();
   uint tokenAmount = safeDiv(safeMul(weiAmount, multiplier), tokenPrice);
   assert(tokenAmount > 0);

   if(investedAmountOf[receiver] == 0) {
       
      investorCount++;
   }
    
   investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
   tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokenAmount);
    
   weiRaised = safeAdd(weiRaised, weiAmount);
   tokensSold = safeAdd(tokensSold, tokenAmount);

   var newPrice = calculatePrice(tokensSold);
   PriceChanged(tokenPrice, newPrice);
   tokenPrice = newPrice;

   assignTokens(receiver, tokenAmount);
   if(weiRaised <= MULTISIG_WALLET_GOAL)
     multisigWallet.transfer(weiAmount);
   else {
     int remain = int(weiAmount - weiRaised - MULTISIG_WALLET_GOAL);

     if(remain > 0) {
       multisigWallet.transfer(uint(remain));
       weiAmount = safeSub(weiAmount, uint(remain));
     }

     var distributedAmount = safeDiv(safeMul(weiAmount, 32), 100);
     teamWallet.transfer(distributedAmount);
     multisigWallet.transfer(safeSub(weiAmount, distributedAmount));

   }
    
   Invested(receiver, weiAmount, tokenAmount);
 }

   
   
 function invest(address receiver) public payable {
   investInternal(receiver);
 }

   
 function buy() public payable {
   invest(msg.sender);
 }

  
 function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    
   require(!finalized);

   finalized = true;
   finalizeCrowdsale();
 }

  
 function finalizeCrowdsale() internal {
   var multiplier = 10 ** token.decimals();
   uint investorTokens = safeMul(INVESTOR_TOKENS, multiplier);
   if(investorTokens > tokensSold)
     assignTokens(teamWallet, safeSub(investorTokens, tokensSold));
   token.releaseTokenTransfer();
 }

   
 function loadRefund() public payable inState(State.Failure) {
   if(msg.value == 0)
     revert();
   loadedRefund = safeAdd(loadedRefund, msg.value);
 }

  
 function refund() public inState(State.Refunding) {
   uint256 weiValue = investedAmountOf[msg.sender];
   if (weiValue == 0)
     revert();
   investedAmountOf[msg.sender] = 0;
   weiRefunded = safeAdd(weiRefunded, weiValue);
   Refund(msg.sender, weiValue);
   if (!msg.sender.send(weiValue))
     revert();
 }

   
   
 function getState() public constant returns (State) {
   if (finalized)
     return State.Finalized;
   if (address(token) == 0 || address(multisigWallet) == 0)
     return State.Preparing;
   if (now >= startsAt && now < startsAt + icoDuration && !isCrowdsaleFull())
     return State.Funding;
   if (isMinimumGoalReached())
       return State.Success;
   if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
     return State.Refunding;
   return State.Failure;
 }

  
 function prolongate() public onlyOwner {
   require(icoDuration < DURATION * 2);
   icoDuration += DURATION;
 }

  
  
  
 function calculatePrice(uint totalRaisedTokens) internal returns (uint price) {
   int multiplier = int(10**token.decimals());
   int coefficient = int(safeDiv(totalRaisedTokens, TOTAL_TOKENS_FOR_PRICE)) - multiplier;
   int priceDifference = coefficient * int(MAX_PRICE - MIN_PRICE) / multiplier;
   assert(int(MAX_PRICE) >= -priceDifference);
   return uint(priceDifference + int(MAX_PRICE));
 }

   
   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= FUNDING_GOAL;
  }

   
   
  function isCrowdsaleFull() public constant returns (bool) {
    return tokenPrice >= MAX_PRICE
      || tokensSold >= safeMul(TOTAL_TOKENS_FOR_PRICE,  10 ** token.decimals())
      || now > startsAt + icoDuration;
  }

    
    
    
  function assignTokens(address receiver, uint tokenAmount) private {
    token.mint(receiver, tokenAmount);
  }
}