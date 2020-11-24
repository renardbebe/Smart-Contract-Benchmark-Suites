 

 
pragma solidity ^0.4.11;


 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}



 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 



 




 





 
contract Haltable is Ownable {
  bool public halted;

  modifier stopInEmergency {
    if (halted) throw;
    _;
  }

  modifier stopNonOwnersInEmergency {
    if (halted && msg.sender != owner) throw;
    _;
  }

  modifier onlyInEmergency {
    if (!halted) throw;
    _;
  }

   
  function halt() external onlyOwner {
    halted = true;
  }

   
  function unhalt() external onlyOwner onlyInEmergency {
    halted = false;
  }

}


 



 
contract FinalizeAgent {

  function isFinalizeAgent() public constant returns(bool) {
    return true;
  }

   
  function isSane() public constant returns (bool);

   
  function finalizeCrowdsale();

}

 









 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract FractionalERC20Ext is ERC20 {

  uint public decimals;
  uint public minCap;

}



 
contract CrowdsaleExt is Haltable {

   
  uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

  using SafeMathLibExt for uint;

   
  FractionalERC20Ext public token;

   
  PricingStrategy public pricingStrategy;

   
  FinalizeAgent public finalizeAgent;

   
  string public name;

   
  address public multisigWallet;

   
  uint public minimumFundingGoal;

   
  uint public startsAt;

   
  uint public endsAt;

   
  uint public tokensSold = 0;

   
  uint public weiRaised = 0;

   
  uint public presaleWeiRaised = 0;

   
  uint public investorCount = 0;

   
  uint public loadedRefund = 0;

   
  uint public weiRefunded = 0;

   
  bool public finalized;

   
  bool public requireCustomerId;

  bool public isWhiteListed;

  address[] public joinedCrowdsales;
  uint public joinedCrowdsalesLen = 0;

  address public lastCrowdsale;

   
  bool public requiredSignedAddress;

   
  address public signerAddress;

   
  mapping (address => uint256) public investedAmountOf;

   
  mapping (address => uint256) public tokenAmountOf;

  struct WhiteListData {
    bool status;
    uint minCap;
    uint maxCap;
  }

   
  bool public isUpdatable;

   
  mapping (address => WhiteListData) public earlyParticipantWhitelist;

   
  address[] public whitelistedParticipants;

   
  uint public ownerTestValue;

   
  enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}

   
  event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

   
  event Refund(address investor, uint weiAmount);

   
  event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);

   
  event Whitelisted(address addr, bool status);

   
  event StartsAtChanged(uint newStartsAt);

   
  event EndsAtChanged(uint newEndsAt);

  function CrowdsaleExt(string _name, address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal, bool _isUpdatable, bool _isWhiteListed) {

    owner = msg.sender;

    name = _name;

    token = FractionalERC20Ext(_token);

    setPricingStrategy(_pricingStrategy);

    multisigWallet = _multisigWallet;
    if(multisigWallet == 0) {
        throw;
    }

    if(_start == 0) {
        throw;
    }

    startsAt = _start;

    if(_end == 0) {
        throw;
    }

    endsAt = _end;

     
    if(startsAt >= endsAt) {
        throw;
    }

     
    minimumFundingGoal = _minimumFundingGoal;

    isUpdatable = _isUpdatable;

    isWhiteListed = _isWhiteListed;
  }

   
  function() payable {
    throw;
  }

   
  function investInternal(address receiver, uint128 customerId) stopInEmergency private {

     
    if(getState() == State.PreFunding) {
       
      throw;
    } else if(getState() == State.Funding) {
       
       
      if(isWhiteListed) {
        if(!earlyParticipantWhitelist[receiver].status) {
          throw;
        }
      }
    } else {
       
      throw;
    }

    uint weiAmount = msg.value;

     
    uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());

    if(tokenAmount == 0) {
       
      throw;
    }

    if(isWhiteListed) {
      if(tokenAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
         
        throw;
      }
      if(tokenAmount > earlyParticipantWhitelist[receiver].maxCap) {
         
        throw;
      }

       
      if (isBreakingInvestorCap(receiver, tokenAmount)) {
        throw;
      }
    } else {
      if(tokenAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
        throw;
      }
    }

    if(investedAmountOf[receiver] == 0) {
        
       investorCount++;
    }

     
    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

     
    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    if(pricingStrategy.isPresalePurchase(receiver)) {
        presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
    }

     
    if(isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold)) {
      throw;
    }

    assignTokens(receiver, tokenAmount);

     
    if(!multisigWallet.send(weiAmount)) throw;

    if (isWhiteListed) {
      uint num = 0;
      for (var i = 0; i < joinedCrowdsalesLen; i++) {
        if (this == joinedCrowdsales[i])
          num = i;
      }

      if (num + 1 < joinedCrowdsalesLen) {
        for (var j = num + 1; j < joinedCrowdsalesLen; j++) {
          CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
          crowdsale.updateEarlyParticipantWhitelist(msg.sender, this, tokenAmount);
        }
      }
    }

     
    Invested(receiver, weiAmount, tokenAmount, customerId);
  }

   
  function preallocate(address receiver, uint fullTokens, uint weiPrice) public onlyOwner {

    uint tokenAmount = fullTokens * 10**token.decimals();
    uint weiAmount = weiPrice * fullTokens;  

    weiRaised = weiRaised.plus(weiAmount);
    tokensSold = tokensSold.plus(tokenAmount);

    investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
    tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

    assignTokens(receiver, tokenAmount);

     
    Invested(receiver, weiAmount, tokenAmount, 0);
  }

   
  function investWithSignedAddress(address addr, uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
     bytes32 hash = sha256(addr);
     if (ecrecover(hash, v, r, s) != signerAddress) throw;
     if(customerId == 0) throw;   
     investInternal(addr, customerId);
  }

   
  function investWithCustomerId(address addr, uint128 customerId) public payable {
    if(requiredSignedAddress) throw;  
    if(customerId == 0) throw;   
    investInternal(addr, customerId);
  }

   
  function invest(address addr) public payable {
    if(requireCustomerId) throw;  
    if(requiredSignedAddress) throw;  
    investInternal(addr, 0);
  }

   
  function buyWithSignedAddress(uint128 customerId, uint8 v, bytes32 r, bytes32 s) public payable {
    investWithSignedAddress(msg.sender, customerId, v, r, s);
  }

   
  function buyWithCustomerId(uint128 customerId) public payable {
    investWithCustomerId(msg.sender, customerId);
  }

   
  function buy() public payable {
    invest(msg.sender);
  }

   
  function finalize() public inState(State.Success) onlyOwner stopInEmergency {

     
    if(finalized) {
      throw;
    }

     
    if(address(finalizeAgent) != 0) {
      finalizeAgent.finalizeCrowdsale();
    }

    finalized = true;
  }

   
  function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
    finalizeAgent = addr;

     
    if(!finalizeAgent.isFinalizeAgent()) {
      throw;
    }
  }

   
  function setRequireCustomerId(bool value) onlyOwner {
    requireCustomerId = value;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setRequireSignedAddress(bool value, address _signerAddress) onlyOwner {
    requiredSignedAddress = value;
    signerAddress = _signerAddress;
    InvestmentPolicyChanged(requireCustomerId, requiredSignedAddress, signerAddress);
  }

   
  function setEarlyParticipantWhitelist(address addr, bool status, uint minCap, uint maxCap) onlyOwner {
    if (!isWhiteListed) throw;
    assert(addr != address(0));
    assert(maxCap > 0);
    assert(minCap <= maxCap);

    if (earlyParticipantWhitelist[addr].maxCap == 0) {
      earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
      whitelistedParticipants.push(addr);
      Whitelisted(addr, status);
    }
  }

  function setEarlyParticipantsWhitelist(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) onlyOwner {
    if (!isWhiteListed) throw;
    for (uint iterator = 0; iterator < addrs.length; iterator++) {
      setEarlyParticipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
    }
  }

  function updateEarlyParticipantWhitelist(address addr, address contractAddr, uint tokensBought) {
    if (tokensBought < earlyParticipantWhitelist[addr].minCap) throw;
    if (!isWhiteListed) throw;
    if (addr != msg.sender && contractAddr != msg.sender) throw;
    uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
    newMaxCap = newMaxCap.minus(tokensBought);
    earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
  }

  function updateJoinedCrowdsales(address addr) onlyOwner {
    joinedCrowdsales[joinedCrowdsalesLen++] = addr;
  }

  function setLastCrowdsale(address addr) onlyOwner {
    lastCrowdsale = addr;
  }

  function clearJoinedCrowdsales() onlyOwner {
    joinedCrowdsalesLen = 0;
  }

  function updateJoinedCrowdsalesMultiple(address[] addrs) onlyOwner {
    clearJoinedCrowdsales();
    for (uint iter = 0; iter < addrs.length; iter++) {
      if(joinedCrowdsalesLen == joinedCrowdsales.length) {
          joinedCrowdsales.length += 1;
      }
      joinedCrowdsales[joinedCrowdsalesLen++] = addrs[iter];
      if (iter == addrs.length - 1)
        setLastCrowdsale(addrs[iter]);
    }
  }

  function setStartsAt(uint time) onlyOwner {
    if (finalized) throw;

    if (!isUpdatable) throw;

    if(now > time) {
      throw;  
    }

    if(time > endsAt) {
      throw;
    }

    CrowdsaleExt lastCrowdsaleCntrct = CrowdsaleExt(lastCrowdsale);
    if (lastCrowdsaleCntrct.finalized()) throw;

    startsAt = time;
    StartsAtChanged(startsAt);
  }

   
  function setEndsAt(uint time) onlyOwner {
    if (finalized) throw;

    if (!isUpdatable) throw;

    if(now > time) {
      throw;  
    }

    if(startsAt > time) {
      throw;
    }

    CrowdsaleExt lastCrowdsaleCntrct = CrowdsaleExt(lastCrowdsale);
    if (lastCrowdsaleCntrct.finalized()) throw;

    uint num = 0;
    for (var i = 0; i < joinedCrowdsalesLen; i++) {
      if (this == joinedCrowdsales[i])
        num = i;
    }

    if (num + 1 < joinedCrowdsalesLen) {
      for (var j = num + 1; j < joinedCrowdsalesLen; j++) {
        CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
        if (time > crowdsale.startsAt()) throw;
      }
    }

    endsAt = time;
    EndsAtChanged(endsAt);
  }

   
  function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    pricingStrategy = _pricingStrategy;

     
    if(!pricingStrategy.isPricingStrategy()) {
      throw;
    }
  }

   
  function setMultisig(address addr) public onlyOwner {

     
    if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
      throw;
    }

    multisigWallet = addr;
  }

   
  function loadRefund() public payable inState(State.Failure) {
    if(msg.value == 0) throw;
    loadedRefund = loadedRefund.plus(msg.value);
  }

   
  function refund() public inState(State.Refunding) {
    uint256 weiValue = investedAmountOf[msg.sender];
    if (weiValue == 0) throw;
    investedAmountOf[msg.sender] = 0;
    weiRefunded = weiRefunded.plus(weiValue);
    Refund(msg.sender, weiValue);
    if (!msg.sender.send(weiValue)) throw;
  }

   
  function isMinimumGoalReached() public constant returns (bool reached) {
    return weiRaised >= minimumFundingGoal;
  }

   
  function isFinalizerSane() public constant returns (bool sane) {
    return finalizeAgent.isSane();
  }

   
  function isPricingSane() public constant returns (bool sane) {
    return pricingStrategy.isSane(address(this));
  }

   
  function getState() public constant returns (State) {
    if(finalized) return State.Finalized;
    else if (address(finalizeAgent) == 0) return State.Preparing;
    else if (!finalizeAgent.isSane()) return State.Preparing;
    else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
    else if (block.timestamp < startsAt) return State.PreFunding;
    else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
    else if (isMinimumGoalReached()) return State.Success;
    else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
    else return State.Failure;
  }

   
  function setOwnerTestValue(uint val) onlyOwner {
    ownerTestValue = val;
  }

   
  function isCrowdsale() public constant returns (bool) {
    return true;
  }

   
   
   

   
  modifier inState(State state) {
    if(getState() != state) throw;
    _;
  }


   
   
   

   
  function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);

  function isBreakingInvestorCap(address receiver, uint tokenAmount) constant returns (bool limitBroken);

   
  function isCrowdsaleFull() public constant returns (bool);

   
  function assignTokens(address receiver, uint tokenAmount) private;

  function whitelistedParticipantsLength() public constant returns (uint) {
    return whitelistedParticipants.length;
  }
}


 



 
contract PricingStrategy {

   
  function isPricingStrategy() public constant returns (bool) {
    return true;
  }

   
  function isSane(address crowdsale) public constant returns (bool) {
    return true;
  }

   
  function isPresalePurchase(address purchaser) public constant returns (bool) {
    return false;
  }

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
}

 



 
library SafeMathLibExt {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divides(uint a, uint b) returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}


 
contract FlatPricingExt is PricingStrategy, Ownable {

  using SafeMathLibExt for uint;

   
  uint public oneTokenInWei;

  bool public isUpdatable;

  address public lastCrowdsale;

   
  event RateChanged(uint newOneTokenInWei);

  function FlatPricingExt(uint _oneTokenInWei, bool _isUpdatable) onlyOwner {
    require(_oneTokenInWei > 0);
    oneTokenInWei = _oneTokenInWei;

    isUpdatable = _isUpdatable;
  }

  function setLastCrowdsale(address addr) onlyOwner {
    lastCrowdsale = addr;
  }

  function updateRate(uint newOneTokenInWei) onlyOwner {
    if (!isUpdatable) throw;

    CrowdsaleExt lastCrowdsaleCntrct = CrowdsaleExt(lastCrowdsale);
    if (lastCrowdsaleCntrct.finalized()) throw;

    oneTokenInWei = newOneTokenInWei;
    RateChanged(newOneTokenInWei);
  }

   
  function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint) {
    uint multiplier = 10 ** decimals;
    return value.times(multiplier) / oneTokenInWei;
  }

}