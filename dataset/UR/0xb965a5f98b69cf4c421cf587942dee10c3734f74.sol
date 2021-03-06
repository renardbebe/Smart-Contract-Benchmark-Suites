 

 

pragma solidity ^0.4.11;

 
 
 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant internal returns (uint256);
  function transfer(address to, uint256 value) internal returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) tokenBalances;

   
  function transfer(address _to, uint256 _value) internal returns (bool) {
    require(tokenBalances[msg.sender]>=_value);
    tokenBalances[msg.sender] = tokenBalances[msg.sender].sub(_value);
    tokenBalances[_to] = tokenBalances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant internal returns (uint256 balance) {
    return tokenBalances[_owner];
  }

}
contract EtheeraToken is BasicToken,Ownable {

   using SafeMath for uint256;
   
    
   string public constant name = "ETHEERA";
   string public constant symbol = "ETA";
   uint256 public constant decimals = 18;

   uint256 public constant INITIAL_SUPPLY = 300000000;
   event Debug(string message, address addr, uint256 number);
    
    function EtheeraToken(address wallet) public {
        owner = msg.sender;
        totalSupply = INITIAL_SUPPLY;
        tokenBalances[wallet] = INITIAL_SUPPLY * 10 ** 18;    
    }

    function mint(address wallet, address buyer, uint256 tokenAmount) public onlyOwner {
      require(tokenBalances[wallet] >= tokenAmount);                
      tokenBalances[buyer] = tokenBalances[buyer].add(tokenAmount);                   
      tokenBalances[wallet] = tokenBalances[wallet].sub(tokenAmount);                         
      Transfer(wallet, buyer, tokenAmount); 
    }
    
    function showMyTokenBalance(address addr) public view onlyOwner returns (uint tokenBalance) {
        tokenBalance = tokenBalances[addr];
        return tokenBalance;
    }
    
    function showMyEtherBalance(address addr) public view onlyOwner returns (uint etherBalance) {
        etherBalance = addr.balance;
    }
}
contract Crowdsale {
  using SafeMath for uint256;
 
   
  EtheeraToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
   
  address public wallet;

   
  uint256 public ratePerWei = 2000;

   
  uint256 public weiRaised;

   
  bool public isSoftCapReached = false;
  bool public isHardCapReached = false;
    
   
  bool public refundToBuyers = false;
    
   
  uint256 public softCap = 6000;
    
   
  uint256 public hardCap = 100000;
  
   
  uint256 tokens_sold = 0;

   
  uint maxTokensForSale = 210000000;
  
   
  uint256 tokensForReservedFund = 0;
  uint256 tokensForAdvisors = 0;
  uint256 tokensForFoundersAndTeam = 0;
  uint256 tokensForMarketing = 0;
  uint256 tokensForTournament = 0;

  bool ethersSentForRefund = false;
  uint256 public amountForRefundIfSoftCapNotReached = 0;
   
  mapping(address=>bool) whiteListedAddresses;

   
  mapping(address=>uint) usersThatBoughtETA;
 
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, address _wallet) public {
    
    require(_startTime >= now);
    startTime = _startTime;
    endTime = startTime + 60 days;
    
    require(endTime >= startTime);
    require(_wallet != 0x0);

    wallet = _wallet;
    token = createTokenContract(wallet);
  }

  function createTokenContract(address wall) internal returns (EtheeraToken) {
    return new EtheeraToken(wall);
  }

   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function determineBonus(uint tokens) internal view returns (uint256 bonus) {
    
    uint256 timeElapsed = now - startTime;
    uint256 timeElapsedInWeeks = timeElapsed.div(7 days);
    
    if (timeElapsedInWeeks <=1)
    {
         
         
         
        if (tokens>30000 * 10 ** 18)
        {
             
            bonus = tokens.mul(33);
            bonus = bonus.div(100);
        }
         
        else if (tokens>10000 *10 ** 18 && tokens<= 30000 * 10 ** 18)
        {
             
            bonus = tokens.mul(26);
            bonus = bonus.div(100);
        }
         
        else if (tokens>3000 *10 ** 18 && tokens<= 10000 * 10 ** 18)
        {
             
            bonus = tokens.mul(23);
            bonus = bonus.div(100);
        }
        
         
        else if (tokens>=75 *10 ** 18 && tokens<= 3000 * 10 ** 18)
        {
             
            bonus = tokens.mul(20);
            bonus = bonus.div(100);
        }
    }
    else if (timeElapsedInWeeks>1 && timeElapsedInWeeks <=6)
    {
         
         
         
        if (tokens>30000 * 10 ** 18)
        {
             
            bonus = tokens.mul(15);
            bonus = bonus.div(100);
        }
         
        else if (tokens>10000 *10 ** 18 && tokens<= 30000 * 10 ** 18)
        {
             
            bonus = tokens.mul(10);
            bonus = bonus.div(100);
        }
         
        else if (tokens>3000 *10 ** 18 && tokens<= 10000 * 10 ** 18)
        {
             
            bonus = tokens.mul(5);
            bonus = bonus.div(100);
        }
        
         
        else if (tokens>=75 *10 ** 18 && tokens<= 3000 * 10 ** 18)
        {
             
            bonus = tokens.mul(3);
            bonus = bonus.div(100);
        }
    }
    else if (timeElapsedInWeeks>6)
    {
         
        bonus = 0;
    }
  }

   
   
  
  function buyTokens(address beneficiary) public payable {
    
   
  require(beneficiary != 0x0);
  
  bool hasICOended = hasEnded();
  
  if(hasICOended && weiRaised < softCap * 10 ** 18)
      refundToBuyers = true;
        
  if(hasICOended && weiRaised < hardCap * 10 ** 18)
  {
      burnRemainingTokens();
      beneficiary.transfer(msg.value);
  }
  else
  {
  
     
    require(validPurchase());
  
     
    require(isHardCapReached == false);
    
     
    uint256 weiAmount = msg.value;
    
     
    uint256 tokens = weiAmount.mul(ratePerWei);
  
     
    uint bonus = determineBonus(tokens);
    tokens = tokens.add(bonus);

    require (tokens>=75 * 10 ** 18);
  
     
    require(tokens_sold + tokens <= maxTokensForSale * 10 ** 18);
  
     
    updateTokensForEtheeraTeam(tokens);
  
     
    require(weiRaised.add(weiAmount) <= hardCap * 10 ** 18);

    weiRaised = weiRaised.add(weiAmount);
    amountForRefundIfSoftCapNotReached = amountForRefundIfSoftCapNotReached.add(weiAmount);
    
    if (weiRaised >= softCap * 10 ** 18)
    {
      isSoftCapReached = true;
      amountForRefundIfSoftCapNotReached = 0;
    }
  
    if (weiRaised == hardCap * 10 ** 18)
      isHardCapReached = true;
    
    token.mint(wallet, beneficiary, tokens); 
    usersThatBoughtETA[beneficiary] = weiAmount;
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    
    tokens_sold = tokens_sold.add(tokens);
    
    forwardFunds();
  }
 }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
  }
  
   function showMyTokenBalance() public constant returns (uint256 tokenBalance) {
        tokenBalance = token.showMyTokenBalance(msg.sender);
    }
    
    function showMyEtherBalance() public constant returns (uint256 etherBalance) {
        etherBalance = token.showMyEtherBalance(msg.sender);
    }
    
    function burnRemainingTokens() internal
    {
         
        uint balance = token.showMyTokenBalance(wallet);
        uint tokensIssued = tokensForReservedFund + tokensForFoundersAndTeam + tokensForAdvisors +tokensForMarketing + tokensForTournament;
        uint tokensToBurn = balance.sub(tokensIssued);
        require (balance >=tokensToBurn);
        address burnAddress = 0x0;
        token.mint(wallet,burnAddress,tokensToBurn);
    }
    
    function addAddressToWhiteList(address whitelistaddress) public 
    {
        require(msg.sender == wallet);
        whiteListedAddresses[whitelistaddress] = true;
    } 
    
    function getRefund() public 
    {
        require(refundToBuyers == true && ethersSentForRefund == true);
        require(usersThatBoughtETA[msg.sender]>0);
        uint256 ethersSent = usersThatBoughtETA[msg.sender];
        require (wallet.balance >= ethersSent);
        msg.sender.transfer(ethersSent);
    }
    
    function debitAmountToRefund() public payable {
        require(hasEnded()==true);
        require(msg.sender == wallet);
        require(msg.value >=amountForRefundIfSoftCapNotReached);
        ethersSentForRefund = true;
    }
    
    function updateTokensForEtheeraTeam(uint256 tokens) internal {
        
        uint256 reservedFundTokens;
        uint256 foundersAndTeamTokens;
        uint256 advisorsTokens;
        uint256 marketingTokens;
        uint256 tournamentTokens;
        
         
        reservedFundTokens = tokens.mul(10);
        reservedFundTokens = reservedFundTokens.div(100);
        tokensForReservedFund = tokensForReservedFund.add(reservedFundTokens);
    
         
        foundersAndTeamTokens=tokens.mul(15);
        foundersAndTeamTokens= foundersAndTeamTokens.div(100);
        tokensForFoundersAndTeam = tokensForFoundersAndTeam.add(foundersAndTeamTokens);
    
         
        advisorsTokens=tokens.mul(3);
        advisorsTokens= advisorsTokens.div(100);
        tokensForAdvisors= tokensForAdvisors.add(advisorsTokens);
    
         
        marketingTokens = tokens.mul(1);
        marketingTokens= marketingTokens.div(100);
        tokensForMarketing= tokensForMarketing.add(marketingTokens);
        
         
        tournamentTokens=tokens.mul(1);
        tournamentTokens= tournamentTokens.div(100);
        tokensForTournament= tokensForTournament.add(tournamentTokens);
    }
    
    function withdrawTokensForEtheeraTeam(uint256 whoseTokensToWithdraw,address[] whereToSendTokens) public {
         
        require(msg.sender == wallet);
        require(now>=endTime);
        uint256 lockPeriod = 0;
        uint256 timePassed = now - endTime;
        uint256 tokensToSend = 0;
        uint256 i = 0;
        if (whoseTokensToWithdraw == 1)
        {
           
          lockPeriod = 15 days * 30;
          require(timePassed >= lockPeriod);
           
          tokensToSend = tokensForReservedFund.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForReservedFund = 0;
        }
        else if (whoseTokensToWithdraw == 2)
        {
           
          lockPeriod = 10 days * 30;
          require(timePassed >= lockPeriod);
           
          tokensToSend = tokensForFoundersAndTeam.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }            
          tokensForFoundersAndTeam = 0;
        }
        else if (whoseTokensToWithdraw == 3)
        {
           
          tokensToSend = tokensForAdvisors.div(whereToSendTokens.length);        
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForAdvisors = 0;
        }
        else if (whoseTokensToWithdraw == 4)
        {
           
          tokensToSend = tokensForMarketing.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForMarketing = 0;
        }
        else if (whoseTokensToWithdraw == 5)
        {
           
          tokensToSend = tokensForTournament.div(whereToSendTokens.length);
                
          for (i=0;i<whereToSendTokens.length;i++)
          {
            token.mint(wallet,whereToSendTokens[i],tokensToSend);
          }
          tokensForTournament = 0;
        }
        else 
        {
           
          require (1!=1);
        }
    }
    
      
    function setPriceRate(uint256 newPrice) public returns (bool) {
        ratePerWei = newPrice;
    }
}