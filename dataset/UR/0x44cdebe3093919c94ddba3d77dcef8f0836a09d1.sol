 

pragma solidity ^0.4.18;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract IERC20 {

    function balanceOf(address _to) public constant returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public;
    function approve(address spender, uint256 value) public;
    function allowance(address owner, address spender) public constant returns(uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract StandardToken is IERC20{
    using SafeMath for uint256;
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping(address => uint256)) allowed;

     
     
     
    function balanceOf(address _to) public constant returns (uint256) {
        return balances[_to];
    }

     
     
     
     
    function transfer(address to, uint256 value) public {
        require (
            balances[msg.sender] >= value && value > 0
        );
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        Transfer(msg.sender, to, value);
    }


     
     
     
     
     
    function transferFrom(address from, address to, uint256 value) public {
        require (
            allowed[from][msg.sender] >= value && balances[from] >= value && value > 0
        );
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(value);
        Transfer(from, to, value);
    }

     
     
     
     
     
    function approve(address spender, uint256 value) public {
        require (
            balances[msg.sender] >= value && value > 0
        );
        allowed[msg.sender][spender] = value;
        Approval(msg.sender, spender, value);
    }

     
     
     
     
    function allowance(address _owner, address spender) public constant returns (uint256) {
        return allowed[_owner][spender];
    }
}
contract TLC is StandardToken {
    
  using SafeMath for uint256;
 
  string public constant name = "Toplancer";
  string public constant symbol = "TLC";
  uint256 public constant decimals = 18;
  
  uint256 public constant totalSupply = 400000000e18;  
}


contract TLCMarketCrowdsale is TLC {
    
  uint256 public minContribAmount = 0.1 ether;  
  uint256 public presaleCap = 20000000e18;  
  uint256 public soldTokenInPresale;
  uint256 public publicSaleCap = 320000000e18;  
  uint256 public soldTokenInPublicsale;
  uint256 public distributionSupply = 60000000e18;  
  uint256 public softCap = 5000 ether;
  uint256 public hardCap = 60000 ether;
   
  uint256 public weiRaised = 0;
    
  address public multisig;
   
  address public owner;
    
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public rate = 3500 ;  
   
  mapping (address => uint256) public investedAmountOf;
   
  uint256 public investorCount;
   
  uint256 public fundRaisedDuringPublicSale = 0;
   
  uint256 public loadedRefund = 0;
   
  uint256 public weiRefunded = 0;

  enum Stage {PRESALE, PUBLICSALE, SUCCESS, FAILURE, REFUNDING, CLOSED}
  Stage public stage;
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
   
  event Refund(address investor, uint256 weiAmount);
 

  function TLCMarketCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet) {
        require( _endTime >= _startTime && _wallet != 0x0);

        startTime = _startTime;
        endTime = _endTime;
        multisig = _wallet;
        owner=msg.sender;
        balances[multisig] = totalSupply;
        stage = Stage.PRESALE;
  }
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    uint256 tokens = weiAmount.mul(rate);
    weiRaised = weiRaised.add(weiAmount);
   
    uint256 timebasedBonus = tokens.mul(getTimebasedBonusRate()).div(100);
    tokens = tokens.add(timebasedBonus);
    forwardFunds();
    if (stage == Stage.PRESALE) {
        assert (soldTokenInPresale + tokens <= presaleCap);
        soldTokenInPresale = soldTokenInPresale.add(tokens);
    } else {
        assert (soldTokenInPublicsale + tokens <= publicSaleCap);
         if(investedAmountOf[beneficiary] == 0) {
            
           investorCount++;
        }
         
        investedAmountOf[beneficiary] = investedAmountOf[beneficiary].add(weiAmount);
        fundRaisedDuringPublicSale = fundRaisedDuringPublicSale.add(weiAmount);
        soldTokenInPublicsale = soldTokenInPublicsale.add(tokens);
    }
    balances[multisig] = balances[multisig].sub(tokens);
    balances[beneficiary] = balances[beneficiary].add(tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
  }
     
    
    function forwardFunds() internal {
        multisig.transfer(msg.value);
    }
      
     
    function () public payable {
        buyTokens(msg.sender);
    }
 
     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
     modifier isRefunding {
        require (stage == Stage.REFUNDING);
        _;
    }
     modifier isFailure {
        require (stage == Stage.FAILURE);
        _;
    }
     
    function hasEnded() public constant returns (bool) {
        return getNow() > endTime;
    }
      
    function getNow() public constant returns (uint256) {
        return (now * 1000);
    }
   
   
  function validPurchase() internal constant returns (bool) {
        bool withinPeriod = getNow() >= startTime && getNow() <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        bool minContribution = minContribAmount <= msg.value;
        return withinPeriod && nonZeroPurchase && minContribution;
    }
   
  function getTimebasedBonusRate() internal constant returns (uint256) {
  	  uint256 bonusRate = 0;
      if (stage == Stage.PRESALE) {
          bonusRate = 50;
      } else {
          uint256 nowTime = getNow();
          uint256 bonusFirstWeek = startTime + (7 days * 1000);
          uint256 bonusSecondWeek = bonusFirstWeek + (7 days * 1000);
          uint256 bonusThirdWeek = bonusSecondWeek + (7 days * 1000);
          uint256 bonusFourthWeek = bonusThirdWeek + (7 days * 1000);
          if (nowTime <= bonusFirstWeek) {
              bonusRate = 25;
          } else if (nowTime <= bonusSecondWeek) {
              bonusRate = 20;
          } else if (nowTime <= bonusThirdWeek) {
              bonusRate = 10;
          } else if (nowTime <= bonusFourthWeek) {
              bonusRate = 5;
          }
      }
      return bonusRate;
  }

   
  function startPublicsale(uint256 _startTime, uint256 _endTime, uint256 _tokenPrice) public onlyOwner {
      require(hasEnded() && stage == Stage.PRESALE && _endTime >= _startTime && _tokenPrice > 0);
      stage = Stage.PUBLICSALE;
      startTime = _startTime;
      endTime = _endTime;
      rate = _tokenPrice;
  }
  
     
    function isMaximumGoalReached() public constant returns (bool reached) {
        return weiRaised >= hardCap;
    }

     
    function updateICOStatus() public onlyOwner {
        require(hasEnded() && stage == Stage.PUBLICSALE);
        if (hasEnded() && weiRaised >= softCap) {
            stage = Stage.SUCCESS;
        } else if (hasEnded()) {
            stage = Stage.FAILURE;
        }
    }

     
    function loadRefund() public payable isFailure{
        require(msg.value != 0);
        loadedRefund = loadedRefund.add(msg.value);
        if (loadedRefund <= fundRaisedDuringPublicSale) {
            stage = Stage.REFUNDING;
        }
    }

     
     
    function refund() public isRefunding {
        uint256 weiValue = investedAmountOf[msg.sender];
        require (weiValue != 0);

        investedAmountOf[msg.sender] = 0;
        balances[msg.sender] = 0;
        weiRefunded = weiRefunded.add(weiValue);
        Refund(msg.sender, weiValue);
        
        msg.sender.transfer(weiValue);
        
        if (weiRefunded <= fundRaisedDuringPublicSale) {
            stage = Stage.CLOSED;
        }
    }
  
     
    function changeMultiSignatureWallet (address _multisig)public onlyOwner{
        multisig = _multisig;
    }
     
    function changeMinContribution(uint256 _minContribAmount)public onlyOwner {
        minContribAmount = _minContribAmount;
    }
     
      
     function changeEndTime(uint256 _endTime) public onlyOwner {
        require(endTime > startTime);
    	endTime = _endTime;
    }

     
     
     function sendFounderAndTeamToken(address to, uint256 value) public onlyOwner{
         require (
             to != 0x0 && value > 0 && distributionSupply >= value
         );
         balances[multisig] = balances[multisig].sub(value);
         balances[to] = balances[to].add(value);
         distributionSupply = distributionSupply.sub(value);
         Transfer(multisig, to, value);
     }
}