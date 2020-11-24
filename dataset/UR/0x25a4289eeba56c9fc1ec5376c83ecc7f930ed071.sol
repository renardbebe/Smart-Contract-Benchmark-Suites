 

pragma solidity ^0.4.11;


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract owned {
    address public owner;
  
	
    function owned() {
        owner = msg.sender;
        
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) onlyOwner {
        owner = newOwner;
    }
}

contract safeMath {
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    safeAssert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    safeAssert(b > 0);
    uint256 c = a / b;
    safeAssert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    safeAssert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    safeAssert(c>=a && c>=b);
    return c;
  }

  function safeAssert(bool assertion) internal {
    if (!assertion) revert();
  }
}

contract StandardToken is owned, safeMath {
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BetstreakICO is owned, safeMath {
    
   
  address        public admin = owner;       
  StandardToken  public tokenReward;         
  

   
  uint256 public initialSupply;

  uint256 public tokensRemaining;

   
  address public beneficiaryWallet;
   
  
  
  uint256 public tokensPerEthPrice;                            

   
  uint256 public amountRaisedInWei;                            
  uint256 public fundingMinCapInWei;                           

   
  string  public CurrentStatus                   = "";         
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  bool    public isCrowdSaleClosed               = false;      
  bool    public areFundsReleasedToBeneficiary   = false;      
  bool    public isCrowdSaleSetup                = false;      

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _BST);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) fundValue;

   
  function BetstreakICO() onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Crowdsale deployed to chain";
  }

   
  function initialBSTSupply() constant returns (uint256 tokenTotalSupply) {
      tokenTotalSupply = safeDiv(initialSupply,100); 
  }

   
  function remainingSupply() constant returns (uint256 tokensLeft) {
      tokensLeft = tokensRemaining;
  }

   
  function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
      
      if ((msg.sender == admin)
      && (!(isCrowdSaleSetup))  
      && (!(beneficiaryWallet > 0))){
      
           
          tokenReward                             = StandardToken(0xA7F40CCD6833a65dD514088F4d419Afd9F0B0B52);  
          
          
          
          beneficiaryWallet                       = 0x361e14cC5b3CfBa5D197D8a9F02caf71B3dca6Fd;
          
         
          tokensPerEthPrice                       = 1300;                                         
           

           
          fundingMinCapInWei                      = 1000000000000000000000;                          
           
           


           
          amountRaisedInWei                       = 0;
          initialSupply                           = 20000000000;                                      
           
           
          
          tokensRemaining                         = safeDiv(initialSupply,100);

          fundingStartBlock                       = _fundingStartBlock;
          fundingEndBlock                         = _fundingEndBlock;

           
          isCrowdSaleSetup                        = true;
          isCrowdSaleClosed                       = false;
          CurrentStatus                           = "Crowdsale is setup";

           
          setPrice();
          return "Crowdsale is setup";
          
      } else if (msg.sender != admin) {
          return "not authorized";
          
      } else  {
          return "campaign cannot be changed";
      }
    }


    function setPrice() {
        
         
         
         
         
         
         
        
      if (block.number >= fundingStartBlock && block.number <= fundingStartBlock+25200) { 
           
          
        tokensPerEthPrice=1300;
        
      } else if (block.number >= fundingStartBlock+25201 && block.number <= fundingStartBlock+50400) { 
           
          
        tokensPerEthPrice=1200;
        
      } else if (block.number >= fundingStartBlock+50401 && block.number <= fundingStartBlock+75600) { 
           
          
        tokensPerEthPrice=1100;
        
      } else if (block.number >= fundingStartBlock+75601 && block.number <= fundingStartBlock+100800) { 
           
          
        tokensPerEthPrice=1050;
        
      } else if (block.number >= fundingStartBlock+100801 && block.number <= fundingEndBlock) { 
           
          
        tokensPerEthPrice=1000;
      }
    }

     
    function () payable {
      require(msg.data.length == 0);
      BuyBSTtokens();
    }

    function BuyBSTtokens() payable {
        
       
       
      require(!(msg.value == 0)
      && (isCrowdSaleSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && (tokensRemaining > 0));

       
      uint256 rewardTransferAmount    = 0;

       
      setPrice();
      amountRaisedInWei               = safeAdd(amountRaisedInWei,msg.value);
      rewardTransferAmount            = safeDiv(safeMul(msg.value,tokensPerEthPrice),10000000000000000);

       
      tokensRemaining                 = safeSub(tokensRemaining, safeDiv(rewardTransferAmount,100));  
       
      tokenReward.transfer(msg.sender, rewardTransferAmount);

       
      fundValue[msg.sender]           = safeAdd(fundValue[msg.sender], msg.value);
      Transfer(this, msg.sender, msg.value);
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }
    

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
      beneficiaryWallet.transfer(_amount);
    }

    function checkGoalReached() onlyOwner returns (bytes32 response) {
        
         
         
      require (isCrowdSaleSetup);
      
      if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) { 
         
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = false;
        CurrentStatus = "In progress (Eth < Softcap)";
        return "In progress (Eth < Softcap)";
        
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) {  
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = false;
        CurrentStatus = "Presale is setup";
        return "Presale is setup";
        
        
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) {  
        areFundsReleasedToBeneficiary = false;
        isCrowdSaleClosed = true;
        CurrentStatus = "Unsuccessful (Eth < Softcap)";
        return "Unsuccessful (Eth < Softcap)";
        
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) {  
          areFundsReleasedToBeneficiary = true;
          isCrowdSaleClosed = true;
          CurrentStatus = "Successful (BST >= Hardcap)!";
          return "Successful (BST >= Hardcap)!";
          
          
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock) && (tokensRemaining > 0)) { 
          
           
          areFundsReleasedToBeneficiary = true;
          isCrowdSaleClosed = true;
          CurrentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
          
          
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.number <= fundingEndBlock)) { 
          
           
        areFundsReleasedToBeneficiary = true;
        isCrowdSaleClosed = false;
        CurrentStatus = "In progress (Eth >= Softcap)!";
        return "In progress (Eth >= Softcap)!";
      }
      
      setPrice();
    }

    function refund() { 
        
         
         
         
        
      require ((amountRaisedInWei < fundingMinCapInWei)
      && (isCrowdSaleClosed)
      && (block.number > fundingEndBlock)
      && (fundValue[msg.sender] > 0));

       
      uint256 ethRefund = fundValue[msg.sender];
      balancesArray[msg.sender] = 0;
      fundValue[msg.sender] = 0;
      Burn(msg.sender, ethRefund);

       
      msg.sender.transfer(ethRefund);
      Refund(msg.sender, ethRefund);
    }
}