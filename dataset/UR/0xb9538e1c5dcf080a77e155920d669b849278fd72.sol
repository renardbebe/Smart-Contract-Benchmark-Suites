 

pragma solidity 0.4.15;

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


contract Contactable is Ownable{

    string public contactInformation;

     
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}



 
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

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract LockableToken is ERC20 {
    function addToTimeLockedList(address addr) external returns (bool);
}

contract PricingStrategy {

    using SafeMath for uint;

    uint[6] public limits;
    uint[6] public rates;

    function PricingStrategy(
        uint[6] _limits,
        uint[6] _rates
    ) public 
    {
        require(_limits.length == _rates.length);
        
        limits = _limits;
        rates = _rates;
    }

     
    function isPricingStrategy() public constant returns (bool) {
        return true;
    }

     
    function calculateTokenAmount(uint weiAmount, uint tokensSold) public constant returns (uint tokenAmount) {
        uint rate = 0;

        for (uint8 i = 0; i < limits.length; i++) {
            if (tokensSold >= limits[i]) {
                rate = rates[i];
            }
        }

        return weiAmount.mul(rate);
    }
}


 
contract Preico is Pausable, Contactable {
    using SafeMath for uint;
  
     
    LockableToken public token;
  
     
    uint public startTime;
    uint public endTime;
  
     
    address public wallet;
  
     
    PricingStrategy public pricingStrategy;
  
     
    uint public weiRaised;

     
    uint public tokensSold;

     
    uint public weiMaximumGoal;

     
    uint public weiMinimumGoal;

     
    uint public investorCount;

     
    uint public loadedRefund;

     
    uint public weiRefunded;

     
    mapping (address => uint) public investedAmountOf;

     
    mapping (address => bool) public earlyParticipantWhitelist;
  
     
    event TokenPurchase(
        address indexed purchaser,
        address indexed beneficiary,
        uint value,
        uint tokenAmount
    );

     
    event Refund(address investor, uint weiAmount);

    function Preico(
        uint _startTime,
        uint _endTime,
        PricingStrategy _pricingStrategy,
        LockableToken _token,
        address _wallet,
        uint _weiMaximumGoal,
        uint _weiMinimumGoal,
        uint _tokensSold
    ) {
        require(_startTime >= now);
        require(_endTime >= _startTime);
        require(_pricingStrategy.isPricingStrategy());
        require(address(_token) != 0x0);
        require(_wallet != 0x0);
        require(_weiMaximumGoal > 0);
        require(_weiMinimumGoal > 0);

        startTime = _startTime;
        endTime = _endTime;
        pricingStrategy = _pricingStrategy;
        token = _token;
        wallet = _wallet;
        weiMaximumGoal = _weiMaximumGoal;
        weiMinimumGoal = _weiMinimumGoal;
        tokensSold = _tokensSold;
}

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public whenNotPaused payable returns (bool) {
        require(beneficiary != 0x0);
        require(validPurchase());
    
        uint weiAmount = msg.value;
    
         
        uint tokenAmount = pricingStrategy.calculateTokenAmount(weiAmount, tokensSold);
    
         
        if (investedAmountOf[beneficiary] == 0) {
             
            investorCount++;
        }
        investedAmountOf[beneficiary] = investedAmountOf[beneficiary].add(weiAmount);
        weiRaised = weiRaised.add(weiAmount);
        tokensSold = tokensSold.add(tokenAmount);
    
        token.transferFrom(owner, beneficiary, tokenAmount);
        TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);

        wallet.transfer(msg.value);

        return true;
    }

     
    function validPurchase() internal constant returns (bool) {
        bool withinPeriod = (now >= startTime || earlyParticipantWhitelist[msg.sender]) && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool withinCap = weiRaised.add(msg.value) <= weiMaximumGoal;

        return withinPeriod && nonZeroPurchase && withinCap;
    }

     
    function hasEnded() external constant returns (bool) {
        bool capReached = weiRaised >= weiMaximumGoal;
        bool afterEndTime = now > endTime;
        
        return capReached || afterEndTime;
    }

     
    function getWeiLeft() external constant returns (uint) {
        return weiMaximumGoal - weiRaised;
    }

     
    function isMinimumGoalReached() public constant returns (bool) {
        return weiRaised >= weiMinimumGoal;
    }
    
     
    function editEarlyParicipantWhitelist(address addr, bool isWhitelisted) external onlyOwner returns (bool) {
        earlyParticipantWhitelist[addr] = isWhitelisted;
        return true;
    }

     
    function setPricingStrategy(PricingStrategy _pricingStrategy) external onlyOwner returns (bool) {
        pricingStrategy = _pricingStrategy;
        return true;
    }

     
    function loadRefund() external payable {
        require(msg.value > 0);
        require(!isMinimumGoalReached());
        
        loadedRefund = loadedRefund.add(msg.value);
    }

     
    function refund() external {
        require(!isMinimumGoalReached() && loadedRefund > 0);
        uint256 weiValue = investedAmountOf[msg.sender];
        require(weiValue > 0);
        
        investedAmountOf[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }
}