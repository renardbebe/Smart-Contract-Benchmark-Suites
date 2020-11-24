 

pragma solidity ^0.4.18;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract owned {
  address public owner;

  function owned() internal {
    owner = msg.sender;
  }
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
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
  function balanceOf(address who) view public returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ARXCrowdsale is owned, safeMath {
   
  address        public admin                     = owner;     
  StandardToken  public tokenReward;                           

   
  uint256 private initialTokenSupply;
  uint256 private tokensRemaining;

   
  address private beneficiaryWallet;                            

   
  uint256 public amountRaisedInWei;                            
  uint256 public fundingMinCapInWei;                           
  uint256 public fundingMaxCapInWei;                           

   
  string  public CurrentStatus                    = "";         
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  bool    public isCrowdSaleClosed               = false;      
  bool    private areFundsReleasedToBeneficiary  = false;      
  bool    public isCrowdSaleSetup                = false;      

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) usersARXfundValue;

   
  function ARXCrowdsale() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "Crowdsale deployed to chain";
  }

   
  function initialARXSupply() public view returns (uint256 initialARXtokenCount) {
    return safeDiv(initialTokenSupply,1000000000000000000);  
  }

   
  function remainingARXSupply() public view returns (uint256 remainingARXtokenCount) {
    return safeDiv(tokensRemaining,1000000000000000000);  
  }

   
  function SetupCrowdsale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32 response) {
    if ((msg.sender == admin)
    && (!(isCrowdSaleSetup))
    && (!(beneficiaryWallet > 0))) {
       
      beneficiaryWallet                       = 0x98DE47A1F7F96500276900925B334E4e54b1caD5;
      tokenReward                             = StandardToken(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);

       
      fundingMinCapInWei                      = 30000000000000000000;                        
      initialTokenSupply                      = 277500000000000000000000000;                 

       
      amountRaisedInWei                       = 0;
      tokensRemaining                         = initialTokenSupply;
      fundingStartBlock                       = _fundingStartBlock;
      fundingEndBlock                         = _fundingEndBlock;
      fundingMaxCapInWei                      = 4500000000000000000000;

       
      isCrowdSaleSetup                        = true;
      isCrowdSaleClosed                       = false;
      CurrentStatus                           = "Crowdsale is setup";
      return "Crowdsale is setup";
    } else if (msg.sender != admin) {
      return "not authorised";
    } else  {
      return "campaign cannot be changed";
    }
  }

  function checkPrice() internal view returns (uint256 currentPriceValue) {
    if (block.number >= 5532293) {
      return (2250);
    } else if (block.number >= 5490292) {
      return (2500);
    } else if (block.number >= 5406291) {
      return (2750);
    } else if (block.number >= 5370290) {
      return (3000);
    } else if (block.number >= 5352289) {
      return (3250);
    } else if (block.number >= 5310289) {
      return (3500);
    } else if (block.number >= 5268288) {
      return (4000);
    } else if (block.number >= 5232287) {
      return (4500);
    } else if (block.number >= fundingStartBlock) {
      return (5000);
    }
  }

   
  function () public payable {
     
    require(!(msg.value == 0)
    && (msg.data.length == 0)
    && (block.number <= fundingEndBlock)
    && (block.number >= fundingStartBlock)
    && (tokensRemaining > 0));

     
    uint256 rewardTransferAmount    = 0;

     
    amountRaisedInWei               = safeAdd(amountRaisedInWei, msg.value);
    rewardTransferAmount            = (safeMul(msg.value, checkPrice()));

     
    tokensRemaining                 = safeSub(tokensRemaining, rewardTransferAmount);
    tokenReward.transfer(msg.sender, rewardTransferAmount);

     
    usersARXfundValue[msg.sender]   = safeAdd(usersARXfundValue[msg.sender], msg.value);
    Buy(msg.sender, msg.value, rewardTransferAmount);
  }

  function beneficiaryMultiSigWithdraw(uint256 _amount) public onlyOwner {
    require(areFundsReleasedToBeneficiary && (amountRaisedInWei >= fundingMinCapInWei));
    beneficiaryWallet.transfer(_amount);
    Transfer(this, beneficiaryWallet, _amount);
  }

  function checkGoalReached() public onlyOwner {  
     
    require (isCrowdSaleSetup);
    if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) {  
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = false;
      CurrentStatus = "In progress (Eth < Softcap)";
    } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) {  
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = false;
      CurrentStatus = "Crowdsale is setup";
    } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) {  
      areFundsReleasedToBeneficiary = false;
      isCrowdSaleClosed = true;
      CurrentStatus = "Unsuccessful (Eth < Softcap)";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining == 0)) {  
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = true;
      CurrentStatus = "Successful (ARX >= Hardcap)!";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock) && (tokensRemaining > 0)) {  
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = true;
      CurrentStatus = "Successful (Eth >= Softcap)!";
    } else if ((amountRaisedInWei >= fundingMinCapInWei) && (tokensRemaining > 0) && (block.number <= fundingEndBlock)) {  
      areFundsReleasedToBeneficiary = true;
      isCrowdSaleClosed = false;
      CurrentStatus = "In progress (Eth >= Softcap)!";
    }
  }

  function refund() public {  
     
    require ((amountRaisedInWei < fundingMinCapInWei)
    && (isCrowdSaleClosed)
    && (block.number > fundingEndBlock)
    && (usersARXfundValue[msg.sender] > 0));

     
    uint256 ethRefund = usersARXfundValue[msg.sender];
    balancesArray[msg.sender] = 0;
    usersARXfundValue[msg.sender] = 0;

     
    Burn(msg.sender, usersARXfundValue[msg.sender]);

     
    msg.sender.transfer(ethRefund);

     
    Refund(msg.sender, ethRefund);
  }
}