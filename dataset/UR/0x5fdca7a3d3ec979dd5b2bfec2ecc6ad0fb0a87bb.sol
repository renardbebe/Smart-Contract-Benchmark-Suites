 

pragma solidity ^0.4.11;


 
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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

   
  modifier whenPaused {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused returns (bool) {
    paused = true;
    Pause();
    return true;
  }

   
  function unpause() onlyOwner whenPaused returns (bool) {
    paused = false;
    Unpause();
    return true;
  }
}

contract IMintableToken {
    function mint(address _to, uint256 _amount) returns (bool);
    function finishMinting() returns (bool);
}

contract PricingStrategy {

    using SafeMath for uint;

    uint public rate0;
    uint public rate1;
    uint public rate2;

    uint public threshold1;
    uint public threshold2;

    uint public minimumWeiAmount;

    function PricingStrategy(
        uint _rate0,
        uint _rate1,
        uint _rate2,
        uint _minimumWeiAmount,
        uint _threshold1,
        uint _threshold2
    ) {
        require(_rate0 > 0);
        require(_rate1 > 0);
        require(_rate2 > 0);
        require(_minimumWeiAmount > 0);
        require(_threshold1 > 0);
        require(_threshold2 > 0);

        rate0 = _rate0;
        rate1 = _rate1;
        rate2 = _rate2;
        minimumWeiAmount = _minimumWeiAmount;
        threshold1 = _threshold1;
        threshold2 = _threshold2;
    }

     
    function isPricingStrategy() public constant returns (bool) {
        return true;
    }

     
    function calculateTokenAmount(uint weiAmount) public constant returns (uint tokenAmount) {
        uint bonusRate = 0;

        if (weiAmount >= minimumWeiAmount) {
            bonusRate = rate0;
        }

        if (weiAmount >= threshold1) {
            bonusRate = rate1;
        }

        if (weiAmount >= threshold2) {
            bonusRate = rate2;
        }

        return weiAmount.mul(bonusRate);
    }
}

contract Presale is Pausable {

    using SafeMath for uint;

     
    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 500;

     
    IMintableToken public token;

     
    PricingStrategy public pricingStrategy;

     
    address public multisigWallet;

     
    uint public minimumFundingGoal;

     
    uint public startsAt;

     
    uint public endsAt;

     
    uint public tokensHardCap;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public investorCount = 0;

     
    uint public loadedRefund = 0;

     
    uint public weiRefunded = 0;

     
    mapping (address => uint256) public investedAmountOf;

     
    mapping (address => uint256) public tokenAmountOf;

     
    mapping (address => bool) public earlyParticipantWhitelist;

     
    enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Refunding}

     
    event Invested(address investor, uint weiAmount, uint tokenAmount);

     
    event Refund(address investor, uint weiAmount);

     
    event Whitelisted(address addr, bool status);

     
    event EndsAtChanged(uint endsAt);

    function Presale(
        address _token, 
        address _pricingStrategy, 
        address _multisigWallet, 
        uint _start, 
        uint _end, 
        uint _tokensHardCap,
        uint _minimumFundingGoal
    ) {
        require(_token != 0);
        require(_pricingStrategy != 0);
        require(_multisigWallet != 0);
        require(_start != 0);
        require(_end != 0);
        require(_start < _end);
        require(_tokensHardCap != 0);

        token = IMintableToken(_token);
        setPricingStrategy(_pricingStrategy);
        multisigWallet = _multisigWallet;
        startsAt = _start;
        endsAt = _end;
        tokensHardCap = _tokensHardCap;
        minimumFundingGoal = _minimumFundingGoal;
    }

     
    function() payable {
        invest(msg.sender);
    }

     
    function invest(address receiver) whenNotPaused payable {

         
        if (getState() == State.PreFunding) {
             
            require(earlyParticipantWhitelist[receiver]);
        } else {
            require(getState() == State.Funding);
        }

        uint weiAmount = msg.value;

         
        uint tokenAmount = pricingStrategy.calculateTokenAmount(weiAmount);

         
        require(tokenAmount > 0);

        if (investedAmountOf[receiver] == 0) {
             
            investorCount++;
        }

         
        investedAmountOf[receiver] = investedAmountOf[receiver].add(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].add(tokenAmount);

         
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);

         
        require(!isBreakingCap(tokensSold));

        token.mint(receiver, tokenAmount);

         
        multisigWallet.transfer(weiAmount);

         
        Invested(receiver, weiAmount, tokenAmount);
    }

     
    function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
        earlyParticipantWhitelist[addr] = status;
        Whitelisted(addr, status);
    }

     
    function setEndsAt(uint time) onlyOwner {

        require(now <= time);

        endsAt = time;
        EndsAtChanged(endsAt);
    }

     
    function setPricingStrategy(address _pricingStrategy) onlyOwner {
        pricingStrategy = PricingStrategy(_pricingStrategy);

         
        require(pricingStrategy.isPricingStrategy());
    }

     
    function setMultisig(address addr) public onlyOwner {

        require(investorCount <= MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE);

        multisigWallet = addr;
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
        Refund(msg.sender, weiValue);
        
        msg.sender.transfer(weiValue);
    }

     
    function getState() public constant returns (State) {
        if (address(pricingStrategy) == 0)
            return State.Preparing;
        else if (block.timestamp < startsAt)
            return State.PreFunding;
        else if (block.timestamp <= endsAt && !isPresaleFull())
            return State.Funding;
        else if (isMinimumGoalReached())
            return State.Success;
        else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
            return State.Refunding;
        else
            return State.Failure;
    }

     
    function isMinimumGoalReached() public constant returns (bool reached) {
        return weiRaised >= minimumFundingGoal;
    }

     
    function isBreakingCap(uint tokensSoldTotal) constant returns (bool) {
        return tokensSoldTotal > tokensHardCap;
    }

    function isPresaleFull() public constant returns (bool) {
        return tokensSold >= tokensHardCap;
    }

     
     
     

     
    modifier inState(State state) {
        require(getState() == state);
        _;
    }
}