 

pragma solidity 0.4.20;

 
 
 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

 function div(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b > 0);  
    uint256 c = a / b;
    assert(a == b * c + a % b);  
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


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

interface ERC20Interface {
     function totalSupply() external constant returns (uint);
     function balanceOf(address tokenOwner) external constant returns (uint balance);
     function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
     function transfer(address to, uint tokens) external returns (bool success);
     function approve(address spender, uint tokens) external returns (bool success);
     function transferFrom(address from, address to, uint tokens) external returns (bool success);
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract BaapPayCrowdsale is Ownable{
  using SafeMath for uint256;
 
   
  ERC20Interface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWei = 4200;

   
  uint256 public weiRaised;

  uint256 TOKENS_SOLD;
  uint256 minimumContribution = 1 * 10 ** 16;  
  
  uint256 maxTokensToSaleInPreICOPhase = 3000000;
  uint256 maxTokensToSaleInICOPhase = 83375000;
  uint256 maxTokensToSale = 94000000;
  
  bool isCrowdsalePaused = false;
  
  struct Buyers 
  {
      address buyerAddress;
      uint tokenAmount;
  }
   Buyers[] tokenBuyers;
   Buyers buyer;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   modifier checkSize(uint numwords) {
        assert(msg.data.length >= (numwords * 32) + 4);
        _;
    }     
    
  function BaapPayCrowdsale(uint256 _startTime, address _wallet, address _tokenToBeUsed) public 
  {
     
    require(_wallet != 0x0);

     
    startTime = now;
    endTime = startTime + 61 days;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSaleInPreICOPhase = maxTokensToSaleInPreICOPhase.mul(10**18);
    maxTokensToSaleInICOPhase = maxTokensToSaleInICOPhase.mul(10**18);
    maxTokensToSale = maxTokensToSale.mul(10**18);
    
    token = ERC20Interface(_tokenToBeUsed);
  }
  
   
  function () public  payable {
    buyTokens(msg.sender);
  }
    function determineBonus(uint tokens) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        if (timeElapsedInDays <20)
        {
            if (TOKENS_SOLD <maxTokensToSaleInPreICOPhase)
            {
                bonus = tokens.mul(20);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInPreICOPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInPreICOPhase && TOKENS_SOLD < maxTokensToSale)
            {
                bonus = tokens.mul(15);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
            }
            else 
            {
                bonus = 0;
            }
        }
        else if (timeElapsedInDays >= 20 && timeElapsedInDays <27)
        {
            revert();   
        }
        else if (timeElapsedInDays >= 27 && timeElapsedInDays<36)
        {
            if (TOKENS_SOLD < maxTokensToSaleInICOPhase)
            {
                bonus = tokens.mul(15);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInICOPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInICOPhase && TOKENS_SOLD < maxTokensToSale)
            {
                bonus = tokens.mul(10);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
            }
        }
        else if (timeElapsedInDays >= 36 && timeElapsedInDays<46)
        {
            if (TOKENS_SOLD < maxTokensToSaleInICOPhase)
            {
                bonus = tokens.mul(10);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInICOPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInICOPhase && TOKENS_SOLD < maxTokensToSale)
            {
                bonus = tokens.mul(5);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSale);
            }
        }
        else if (timeElapsedInDays >= 46 && timeElapsedInDays<56)
        {
            if (TOKENS_SOLD < maxTokensToSaleInICOPhase)
            {
                bonus = tokens.mul(5);  
                bonus = bonus.div(100);
                require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInICOPhase);
            }
            else if (TOKENS_SOLD >= maxTokensToSaleInICOPhase && TOKENS_SOLD < maxTokensToSale)
            {
                bonus = 0;
            }
        }
        else 
        {
            bonus = 0;
        }
    }

   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(validPurchase());
    require(msg.value>= minimumContribution);
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    require(TOKENS_SOLD.add(tokens)<=maxTokensToSale);
    
     
    weiRaised = weiRaised.add(weiAmount);
    
    buyer = Buyers({buyerAddress:beneficiary,tokenAmount:tokens});
    tokenBuyers.push(buyer);
    TokenPurchase(owner, beneficiary, weiAmount, tokens);
    TOKENS_SOLD = TOKENS_SOLD.add(tokens);
    forwardFunds();
  }

   
  function forwardFunds() internal {
    owner.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
   
    function changeEndDate(uint256 endTimeUnixTimestamp) public onlyOwner returns(bool) {
        endTime = endTimeUnixTimestamp;
    }
    
    function changeStartDate(uint256 startTimeUnixTimestamp) public onlyOwner returns(bool) {
        startTime = startTimeUnixTimestamp;
    }
    
    function setPriceRate(uint256 newPrice) public onlyOwner returns (bool) {
        ratePerWei = newPrice;
    }
    
    function changeMinimumContribution(uint256 minContribution) public onlyOwner returns (bool) {
        minimumContribution = minContribution.mul(10 ** 15);
    }
      
     
    function pauseCrowdsale() public onlyOwner returns(bool) {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner returns (bool) {
        isCrowdsalePaused = false;
    }
    
      
      
      
     function remainingTokensForSale() public constant returns (uint) {
         return maxTokensToSale.sub(TOKENS_SOLD);
     }
     
     function showMyTokenBalance() public constant returns (uint) {
         return token.balanceOf(msg.sender);
     }
     
     function pullTokensBack() public onlyOwner {
        token.transfer(owner,token.balanceOf(address(this))); 
     }
     
     function sendTokensToBuyers() public onlyOwner {
         require(hasEnded());
         for (uint i=0;i<tokenBuyers.length;i++)
         {
             token.transfer(tokenBuyers[i].buyerAddress,tokenBuyers[i].tokenAmount);
         }
     }
}