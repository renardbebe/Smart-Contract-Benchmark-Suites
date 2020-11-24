 

pragma solidity 0.4.23;


 
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

interface TokenInterface {
     function totalSupply() external constant returns (uint);
     function balanceOf(address tokenOwner) external constant returns (uint balance);
     function allowance(address tokenOwner, address spender) external constant returns (uint remaining);
     function transfer(address to, uint tokens) external returns (bool success);
     function approve(address spender, uint tokens) external returns (bool success);
     function transferFrom(address from, address to, uint tokens) external returns (bool success);
     function burn(uint256 _value) external; 
     event Transfer(address indexed from, address indexed to, uint tokens);
     event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
     event Burn(address indexed burner, uint256 value);
}

 contract URUNCrowdsale is Ownable{
  using SafeMath for uint256;
 
   
  TokenInterface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWei = 800;

   
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 public minimumContributionPresalePhase1 = uint(2).mul(10 ** 18);  
  uint256 public minimumContributionPresalePhase2 = uint(1).mul(10 ** 18);  
  
  uint256 public maxTokensToSaleInClosedPreSale;
  
  uint256 public bonusInPreSalePhase1;
  uint256 public bonusInPreSalePhase2;
  
  bool public isCrowdsalePaused = false;
  
  uint256 public totalDurationInDays = 31 days;
  
  mapping(address=>bool) isAddressWhiteListed;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    
    require(_wallet != 0x0);
    require(_startTime >=now);
    startTime = _startTime;  
    
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSaleInClosedPreSale = 60000000 * 10 ** 18;
    bonusInPreSalePhase1 = 50;
    bonusInPreSalePhase2 = 40;
    token = TokenInterface(_tokenAddress);
  }
  
  
    
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function determineBonus(uint tokens) internal view returns (uint256 bonus) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        
         
        if (timeElapsedInDays <15)
        {
            bonus = tokens.mul(bonusInPreSalePhase1); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInClosedPreSale);
        }
         
        else if (timeElapsedInDays >=15 && timeElapsedInDays <31)
        {
            bonus = tokens.mul(bonusInPreSalePhase2); 
            bonus = bonus.div(100);
            require (TOKENS_SOLD.add(tokens.add(bonus)) <= maxTokensToSaleInClosedPreSale);
        }
        else 
        {
            bonus = 0;
        }
    }

   
  
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(isCrowdsalePaused == false);
    require(isAddressWhiteListed[beneficiary]);
    require(validPurchase());
    
    require(isWithinContributionRange());
    
    require(TOKENS_SOLD<maxTokensToSaleInClosedPreSale);
   
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(ratePerWei);
    uint256 bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);
    
     
    weiRaised = weiRaised.add(weiAmount);
    
    token.transfer(beneficiary,tokens);
    emit TokenPurchase(owner, beneficiary, weiAmount, tokens);
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
  
     
    function changeStartAndEndDate (uint256 startTimeUnixTimestamp, uint256 endTimeUnixTimestamp) public onlyOwner
    {
        require (startTimeUnixTimestamp!=0 && endTimeUnixTimestamp!=0);
        require(endTimeUnixTimestamp>startTimeUnixTimestamp);
        require(endTimeUnixTimestamp.sub(startTimeUnixTimestamp) >=totalDurationInDays);
        startTime = startTimeUnixTimestamp;
        endTime = endTimeUnixTimestamp;
    }
    
     
    function setPriceRate(uint256 newPrice) public onlyOwner {
        ratePerWei = newPrice;
    }
    
      
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
    
      
    function isWithinContributionRange() internal constant returns (bool)
    {
        uint timePassed = now.sub(startTime);
        timePassed = timePassed.div(1 days);

        if (timePassed<15)
            require(msg.value>=minimumContributionPresalePhase1);
        else if (timePassed>=15 && timePassed<31)
            require(msg.value>=minimumContributionPresalePhase2);
        else
            revert();    
            
        return true;
     }
     
       
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
     
       
     function manualTokenTransfer(address receiver, uint value) public onlyOwner
     {
         token.transfer(receiver,value);
         TOKENS_SOLD = TOKENS_SOLD.add(value);
     }
     
       
     function addSingleAddressToWhitelist(address whitelistedAddr) public onlyOwner
     {
         isAddressWhiteListed[whitelistedAddr] = true;
     }
     
       
     function addMultipleAddressesToWhitelist(address[] whitelistedAddr) public onlyOwner
     {
         for (uint i=0;i<whitelistedAddr.length;i++)
         {
            isAddressWhiteListed[whitelistedAddr[i]] = true;
         }
     }
     
       
     function removeSingleAddressFromWhitelist(address whitelistedAddr) public onlyOwner
     {
         isAddressWhiteListed[whitelistedAddr] = false;
     }
     
       
     function removeMultipleAddressesFromWhitelist(address[] whitelistedAddr) public onlyOwner
     {
        for (uint i=0;i<whitelistedAddr.length;i++)
         {
            isAddressWhiteListed[whitelistedAddr[i]] = false;
         }
     }
     
       
     function checkIfAddressIsWhiteListed(address whitelistedAddr) public view returns (bool)
     {
         return isAddressWhiteListed[whitelistedAddr];
     }
}