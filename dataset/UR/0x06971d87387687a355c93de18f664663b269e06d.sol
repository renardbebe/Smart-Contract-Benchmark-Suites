 

pragma solidity 0.4.24;


 
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

 contract EzeCrowdsale is Ownable{
  using SafeMath for uint256;
 
   
  TokenInterface public token;

   
  uint256 public startTime;
  uint256 public endTime;


   
  uint256 public ratePerWeiInSelfDrop = 60000;
  uint256 public ratePerWeiInPrivateSale = 30000;
  uint256 public ratePerWeiInPreICO = 20000;
  uint256 public ratePerWeiInMainICO = 15000;

   
  uint256 public weiRaised;

  uint256 public TOKENS_SOLD;
  
  uint256 maxTokensToSale;
  
  uint256 bonusInSelfDrop = 20;
  uint256 bonusInPrivateSale = 10;
  uint256 bonusInPreICO = 5;
  uint256 bonusInMainICO = 2;
  
  bool isCrowdsalePaused = false;
  
  uint256 totalDurationInDays = 213 days;
  
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  constructor(uint256 _startTime, address _wallet, address _tokenAddress) public 
  {
    require(_startTime >=now);
    require(_wallet != 0x0);

    startTime = _startTime;  
    endTime = startTime + totalDurationInDays;
    require(endTime >= startTime);
   
    owner = _wallet;
    
    maxTokensToSale = uint(15000000000).mul( 10 ** uint256(18));
   
    token = TokenInterface(_tokenAddress);
  }
  
  
    
   function () public  payable {
     buyTokens(msg.sender);
    }
    
    function calculateTokens(uint value) internal view returns (uint256 tokens) 
    {
        uint256 timeElapsed = now - startTime;
        uint256 timeElapsedInDays = timeElapsed.div(1 days);
        uint256 bonus = 0;
         
        if (timeElapsedInDays <30)
        {
            tokens = value.mul(ratePerWeiInSelfDrop);
            bonus = tokens.mul(bonusInSelfDrop); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
         
        else if (timeElapsedInDays >=30 && timeElapsedInDays <61)
        {
            tokens = value.mul(ratePerWeiInPrivateSale);
            bonus = tokens.mul(bonusInPrivateSale); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
       
         
        else if (timeElapsedInDays >=61 && timeElapsedInDays <91)
        {
            tokens = value.mul(ratePerWeiInPreICO);
            bonus = tokens.mul(bonusInPreICO); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
        }
        
         
        else if (timeElapsedInDays >=91 && timeElapsedInDays <213)
        {
            tokens = value.mul(ratePerWeiInMainICO);
            bonus = tokens.mul(bonusInMainICO); 
            bonus = bonus.div(100);
            tokens = tokens.add(bonus);
            require (TOKENS_SOLD.add(tokens) <= maxTokensToSale);
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

    
    require(TOKENS_SOLD<maxTokensToSale);
   
    uint256 weiAmount = msg.value;
    
    uint256 tokens = calculateTokens(weiAmount);
    
     
    weiRaised = weiRaised.add(msg.value);
    
    token.transfer(beneficiary,tokens);
    emit TokenPurchase(owner, beneficiary, msg.value, tokens);
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
  
    
    function changeEndDate(uint256 endTimeUnixTimestamp) public onlyOwner{
        endTime = endTimeUnixTimestamp;
    }
    
     
    
    function changeStartDate(uint256 startTimeUnixTimestamp) public onlyOwner{
        startTime = startTimeUnixTimestamp;
    }
    
      
     
    function pauseCrowdsale() public onlyOwner {
        isCrowdsalePaused = true;
    }

      
    function resumeCrowdsale() public onlyOwner {
        isCrowdsalePaused = false;
    }
     
     function takeTokensBack() public onlyOwner
     {
         uint remainingTokensInTheContract = token.balanceOf(address(this));
         token.transfer(owner,remainingTokensInTheContract);
     }
}