 

 
 
 
pragma solidity ^0.4.23;

  
contract Ownable {
  
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  modifier stopNonOwnersInEmergency {
    require(!halted && msg.sender == owner);
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

 
library SafeMathLib {

  function times(uint a, uint b) public pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

   
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


 
contract FractionalERC20 {

  uint public decimals;

  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);

  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}


 
contract HoardCrowdsale is Haltable {

  using SafeMathLib for uint;

   
  FractionalERC20 public token;

   
  address public multisigWallet;
  
   
  address public foundersTeamMultisig;
  
   
  uint public minimumFundingGoal = 3265000000000000000000;  

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public presaleTokensSold = 0;

   
  uint public prePresaleTokensSold = 0;

    
  uint public presaleTokenLimit = 80000000000000000000000000;  

    
  uint public crowdsaleTokenLimit = 120000000000000000000000000;  
  
   
  uint public percentageOfSoldTokensForFounders = 50;  
  
   
  uint public tokensForFoundingBoardWallet;
  
   
  address public beneficiary;
  
   
  uint public weiRaised = 0;

   
  uint public presaleWeiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

   
  mapping (address => bool) public presaleWhitelist;

   
  mapping (address => bool) public participantWhitelist;

   
  uint public ownerTestValue;

  uint public oneTokenInWei;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount);

   
  event Refund(address investor, uint weiAmount);

   
  event Whitelisted(address[] addr, bool status);

   
  event PresaleWhitelisted(address addr, bool status);
    
   
  event StartsAtChanged(uint newStartsAt);
      
   
  event EndsAtChanged(uint newEndsAt);
  
   
  event TokenPriceChanged(uint tokenPrice);
    
   
  event MultiSigChanged(address newAddr);
  
   
  event BeneficiaryChanged(address newAddr);
  
   
  event FoundersWalletChanged(address newAddr);
  
   
  event FoundersTokenAllocationChanged(uint newValue);
  
   
  event PrePresaleTokensValueChanged(uint newValue);

  constructor(address _token, uint _oneTokenInWei, address _multisigWallet, uint _start, uint _end, address _beneficiary, address _foundersTeamMultisig) public {

    require(_multisigWallet != address(0) && _start != 0 && _end != 0 && _start <= _end);
    owner = msg.sender;

    token = FractionalERC20(_token);
    oneTokenInWei = _oneTokenInWei;

    multisigWallet = _multisigWallet;
    startsAt = _start;
    endsAt = _end;

    beneficiary = _beneficiary;
    foundersTeamMultisig = _foundersTeamMultisig;
  }
  
   
  function() payable public {
    investInternal(msg.sender,0);
  }
  
   
  function invest(address addr,uint tokenAmount) public payable {
    investInternal(addr,tokenAmount);
  }
  
   
  function investInternal(address receiver, uint tokens) stopInEmergency internal returns(uint tokensBought) {

    uint weiAmount = msg.value;
    uint tokenAmount = tokens;
    if(getState() == State.PreFunding || getState() == State.Funding) {
      if(presaleWhitelist[msg.sender]){
         
        presaleWeiRaised = presaleWeiRaised.add(weiAmount);
        presaleTokensSold = presaleTokensSold.add(tokenAmount);
        require(presaleTokensSold <= presaleTokenLimit); 
      }
      else if(participantWhitelist[receiver]){
        uint multiplier = 10 ** token.decimals();
        tokenAmount = weiAmount.times(multiplier) / oneTokenInWei;
         
      }
      else {
        revert();
      }
    } else {
       
      revert();
    }
    
     
    require(tokenAmount != 0);

    if(investedAmountOf[receiver] == 0) {
       
      investorCount++;
    }

     
    investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    tokensSold = tokensSold.add(tokenAmount);
    
    require(tokensSold.sub(presaleTokensSold) <= crowdsaleTokenLimit);
    
     
    require(!isBreakingCap(tokenAmount));
    require(token.transferFrom(beneficiary, receiver, tokenAmount));

    emit Invested(receiver, weiAmount, tokenAmount);
    multisigWallet.transfer(weiAmount);
    return tokenAmount;
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {
    require(!finalized);  
    
     
    tokensForFoundingBoardWallet = tokensSold.times(percentageOfSoldTokensForFounders) / 100;
    tokensForFoundingBoardWallet = tokensForFoundingBoardWallet.add(prePresaleTokensSold);
    require(token.transferFrom(beneficiary, foundersTeamMultisig, tokensForFoundingBoardWallet));
    
    finalized = true;
  }

    
  function setFoundersTokenAllocation(uint _percentageOfSoldTokensForFounders) public onlyOwner{
    percentageOfSoldTokensForFounders = _percentageOfSoldTokensForFounders;
    emit FoundersTokenAllocationChanged(percentageOfSoldTokensForFounders);
  }

   
  function setEndsAt(uint time) onlyOwner public {
    require(now < time && startsAt < time);
    endsAt = time;
    emit EndsAtChanged(endsAt);
  }
  
    
  function setStartsAt(uint time) onlyOwner public {
    require(time < endsAt);
    startsAt = time;
    emit StartsAtChanged(startsAt);
  }

   
  function setMultisig(address addr) public onlyOwner {
    multisigWallet = addr;
    emit MultiSigChanged(addr);
  }

   
  function loadRefund() public payable inState(State.Failure) {
    require(msg.value > 0);
    loadedRefund = loadedRefund.add(msg.value);
  }

   
  function refund() public inState(State.Refunding) {
     
    uint256 weiValue = investedAmountOf[msg.sender];
    require(weiValue > 0);
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.add(weiValue);
    emit Refund(msg.sender, weiValue);
    msg.sender.transfer(weiValue);
  }

   
  function isMinimumGoalReached() public view  returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }


   
  function getState() public view returns (State) {
    if(finalized) return State.Finalized;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

   
  function setOwnerTestValue(uint val) onlyOwner public {
    ownerTestValue = val;
  }

   
  function setPrePresaleTokens(uint _value) onlyOwner public {
    prePresaleTokensSold = _value;
    emit PrePresaleTokensValueChanged(_value);
  }

   
  function setParticipantWhitelist(address[] addr, bool status) onlyOwner public {
    for(uint i = 0; i < addr.length; i++ ){
      participantWhitelist[addr[i]] = status;
    }
    emit Whitelisted(addr, status);
  }

   
  function setPresaleWhitelist(address addr, bool status) onlyOwner public {
    presaleWhitelist[addr] = status;
    emit PresaleWhitelisted(addr, status);
  }
  
   
  function setPricing(uint _oneTokenInWei) onlyOwner public{
    oneTokenInWei = _oneTokenInWei;
    emit TokenPriceChanged(oneTokenInWei);
  } 
  
   
  function changeBeneficiary(address _beneficiary) onlyOwner public{
    beneficiary = _beneficiary; 
    emit BeneficiaryChanged(beneficiary);
  }
  
   
  function changeFoundersWallet(address _foundersTeamMultisig) onlyOwner public{
    foundersTeamMultisig = _foundersTeamMultisig;
    emit FoundersWalletChanged(foundersTeamMultisig);
  } 
  
   
  function isCrowdsale() public pure returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    require(getState() == state);
    _;
  }

  
  function isBreakingCap(uint tokenAmount) public view returns (bool limitBroken)  {
    if(tokenAmount > getTokensLeft()) {
      return true;
    } else {
      return false;
    }
  }

   
  function isCrowdsaleFull() public view returns (bool) {
    return getTokensLeft() == 0;
  }

   
  function getTokensLeft() public view returns (uint) {
    return token.allowance(beneficiary, this);
  }

}