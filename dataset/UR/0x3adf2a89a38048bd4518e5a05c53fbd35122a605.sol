 

pragma solidity ^0.4.18;
 
 
 
 
 
 

 
 
 
 

contract owned {
    address public owner;

    function owned() public {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
}

contract safeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    safeAssert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    safeAssert(b > 0);
    uint256 c = a / b;
    safeAssert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    safeAssert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    safeAssert(c>=a && c>=b);
    return c;
  }

  function safeAssert(bool assertion) internal pure {
    if (!assertion) revert();
  }
}

contract StandardToken is owned, safeMath {
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract POWTokenOpenDistribution is owned, safeMath {
   
  address        public admin = owner;       
  StandardToken  public tokenContract;      

   
  uint256 public initialSupply;
  uint256 public tokensRemaining;

   
  address public budgetWallet;       
  uint256 public tokensPerEthPrice;       
    
   
  uint256 public amountRaised;                           
  uint256 public fundingCap;                          

   
  string  public CurrentStatus = "";                           
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  bool    public isOpenDistributionClosed = false;             
  bool    public areFundsReleasedToBudget= false;              
  bool    public isOpenDistributionSetup = false;              

  event Transfer(address indexed from, address indexed to, uint256 value); 
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _MOY);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) fundValue;

   
  function POWTokenOpenDistribution() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Tokens Released, Open Distribution deployed to chain";
  }

   
  function initialMoySupply() public constant returns (uint256 tokenTotalSupply) {
      tokenTotalSupply = safeDiv(initialSupply,1000000000000000000);
  }

   
  function remainingSupply() public constant returns (uint256 tokensLeft) {
      tokensLeft = tokensRemaining;
  }

   
  function setupOpenDistribution(uint256 _fundingStartBlock, uint256 _fundingEndBlock, address _tokenContract, address _budgetWallet) public onlyOwner returns (bytes32 response) {
      if ((msg.sender == admin)
      && (!(isOpenDistributionSetup))
      && (!(budgetWallet > 0))){
           
          tokenContract = StandardToken(_tokenContract);                              
          budgetWallet = _budgetWallet;                  
          tokensPerEthPrice = 1000;                                                   
          
          fundingCap = 3;                                        

           
          amountRaised = 0;
          initialSupply = 30000000;                                      
          tokensRemaining = safeDiv(initialSupply,1);

          fundingStartBlock = _fundingStartBlock;
          fundingEndBlock = _fundingEndBlock;

           
          isOpenDistributionSetup = true;
          isOpenDistributionClosed = false;
          CurrentStatus = "OpenDistribution is setup";

           
          setPrice();
          return "OpenDistribution is setup";
      } else if (msg.sender != admin) {
          return "Not Authorized";
      } else  {
          return "Campaign cannot be changed.";
      }
    }

    function setPrice() public {   

       
       
        if (block.number >= fundingStartBlock && block.number <= fundingStartBlock+11520) {  
        tokensPerEthPrice = 3000; 
      } else if (block.number >= fundingStartBlock+11521 && block.number <= fundingStartBlock+46080) {  
        tokensPerEthPrice = 2000;  
      } else if (block.number >= fundingStartBlock+46081 && block.number <= fundingStartBlock+86400) {  
        tokensPerEthPrice = 2000;  
      } else if (block.number >= fundingStartBlock+86401 && block.number <= fundingEndBlock) {  
        tokensPerEthPrice = 1000;  
      }  
         }

     
    function () public payable {
      require(msg.data.length == 0);
      BuyMOYTokens();
    }

    function BuyMOYTokens() public payable {
       
      require(!(msg.value == 0)
      && (isOpenDistributionSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && (tokensRemaining > 0));

       
      uint256 rewardTransferAmount = 0;

       
      setPrice();
      amountRaised = safeAdd(amountRaised,msg.value);
      rewardTransferAmount = safeDiv(safeMul(msg.value,tokensPerEthPrice),1);

       
      tokensRemaining = safeSub(tokensRemaining, safeDiv(rewardTransferAmount,1));   
      tokenContract.transfer(msg.sender, rewardTransferAmount);

       
      fundValue[msg.sender] = safeAdd(fundValue[msg.sender], msg.value);
      Transfer(this, msg.sender, msg.value); 
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function budgetMultiSigWithdraw(uint256 _amount) public onlyOwner {
      require(areFundsReleasedToBudget && (amountRaised >= fundingCap));
      budgetWallet.transfer(_amount);
    }

    function checkGoalReached() public onlyOwner returns (bytes32 response) {  
       
      require (isOpenDistributionSetup);
      if ((amountRaised < fundingCap) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) {  
        areFundsReleasedToBudget = false;
        isOpenDistributionClosed = false;
        CurrentStatus = "OpenDistribution in progress, waiting to reach goal.";
        return "OpenDistribution in progress.";
      } else if ((amountRaised < fundingCap) && (block.number < fundingStartBlock)) {  
        areFundsReleasedToBudget = false;
        isOpenDistributionClosed = false;
        CurrentStatus = "OpenDistribution is setup";
        return "OpenDistribution is setup";
      } else if ((amountRaised < fundingCap) && (block.number > fundingEndBlock)) {  
        areFundsReleasedToBudget = false;
        isOpenDistributionClosed = true;
        CurrentStatus = "OpenDistribution is Over.";
        return "OpenDistribution is Over";
      } else if ((amountRaised >= fundingCap) && (tokensRemaining == 0)) {  
          areFundsReleasedToBudget = true;
          isOpenDistributionClosed = true;
          CurrentStatus = "Successful OpenDistribution.";
          return "Successful OpenDistribution.";
      } else if ((amountRaised >= fundingCap) && (block.number > fundingEndBlock) && (tokensRemaining > 0)) {  
          areFundsReleasedToBudget = true;
          isOpenDistributionClosed = true;
          CurrentStatus = "Successful OpenDistribution.";
          return "Successful OpenDistribution";
      } else if ((amountRaised >= fundingCap) && (tokensRemaining > 0) && (block.number <= fundingEndBlock)) {  
        areFundsReleasedToBudget = true;
        isOpenDistributionClosed = false;
        CurrentStatus = "OpenDistribution in Progress, Goal Achieved.";
        return "Goal Achieved.";
      }
      setPrice();
    }
}