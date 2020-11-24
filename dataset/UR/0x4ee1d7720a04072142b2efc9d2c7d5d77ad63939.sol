 

pragma solidity ^0.4.13;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

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

contract ERC20Interface is owned, safeMath {
  function balanceOf(address _owner) constant returns (uint256 balance);
  function transfer(address _to, uint256 _value) returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
  function approve(address _spender, uint256 _value) returns (bool success);
  function increaseApproval (address _spender, uint _addedValue) returns (bool success);
  function decreaseApproval (address _spender, uint _subtractedValue) returns (bool success);
  function allowance(address _owner, address _spender) constant returns (uint256 remaining);
  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract ARXpresale is owned, safeMath {
   
  address         public admin                   = owner;      
  ERC20Interface  public tokenReward;                          

   
  address public foundationWallet;                             
  address public beneficiaryWallet;                            
  uint256 public tokensPerEthPrice;                            

   
  uint256 public amountRaisedInWei;                            
  uint256 public fundingMinCapInWei;                           
  uint256 public fundingMaxCapInWei;                           
  uint256 public fundingRemainingAvailableInEth;               

   
  string  public currentStatus                   = "";         
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  bool    public isPresaleClosed                 = false;      
  bool    public isPresaleSetup                  = false;      

  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  event Refund(address indexed _refunder, uint256 _value);
  event Burn(address _from, uint256 _value);

  mapping(address => uint256) balances;
  mapping(address => uint256) fundValue;

   
  function ARXpresale() onlyOwner {
    admin = msg.sender;
    currentStatus = "presale deployed to chain";
  }

   
  function Setuppresale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
      if ((msg.sender == admin)
      && (!(isPresaleSetup))
      && (!(beneficiaryWallet > 0))){
           
          tokenReward                             = ERC20Interface(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);    
          beneficiaryWallet                       = 0xd93333f8cb765397A5D0d0e0ba53A2899B48511f;                    
          foundationWallet                        = 0x70A0bE1a5d8A9F39afED536Ec7b55d87067371aA;                    
          tokensPerEthPrice                       = 8000;                                                          

           
          fundingMinCapInWei                      = 100000000000000000000;                                         
          fundingMaxCapInWei                      = 1000000000000000000000;                                        

           
          amountRaisedInWei                       = 0;                                                             
          fundingRemainingAvailableInEth          = safeDiv(fundingMaxCapInWei,1 ether);

          fundingStartBlock                       = _fundingStartBlock;
          fundingEndBlock                         = _fundingEndBlock;

           
          isPresaleSetup                          = true;
          isPresaleClosed                         = false;
          currentStatus                           = "presale is setup";

           
          setPrice();
          return "presale is setup";
      } else if (msg.sender != admin) {
          return "not authorized";
      } else  {
          return "campaign cannot be changed";
      }
    }

    function setPrice() {
       
       
       
       
       

      if (block.number >= fundingStartBlock && block.number <= fundingStartBlock+3600) {  
        tokensPerEthPrice=8000;
      } else if (block.number >= fundingStartBlock+3601 && block.number <= fundingStartBlock+10800) {  
        tokensPerEthPrice=7250;
      } else if (block.number >= fundingStartBlock+10801 && block.number <= fundingStartBlock+18000) {  
        tokensPerEthPrice=6750;
      } else if (block.number >= fundingStartBlock+18001 && block.number <= fundingEndBlock) {  
        tokensPerEthPrice=6250;
      } else {
        tokensPerEthPrice=6250;  
      }
    }

     
    function () payable {
      require(msg.data.length == 0);
      BuyARXtokens();
    }

    function BuyARXtokens() payable {
       
      require(!(msg.value == 0)
      && (isPresaleSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && !(safeAdd(amountRaisedInWei,msg.value) > fundingMaxCapInWei));

       
      uint256 rewardTransferAmount    = 0;

       
      setPrice();
      amountRaisedInWei               = safeAdd(amountRaisedInWei,msg.value);
      rewardTransferAmount            = safeMul(msg.value,tokensPerEthPrice);
      fundingRemainingAvailableInEth  = safeDiv(safeSub(fundingMaxCapInWei,amountRaisedInWei),1 ether);

       
      tokenReward.transfer(msg.sender, rewardTransferAmount);
      fundValue[msg.sender]           = safeAdd(fundValue[msg.sender], msg.value);

       
      Transfer(this, msg.sender, msg.value);
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      require(amountRaisedInWei >= fundingMinCapInWei);
      beneficiaryWallet.transfer(_amount);
    }

    function checkGoalandPrice() onlyOwner returns (bytes32 response) {
       
      require (isPresaleSetup);
      if ((amountRaisedInWei < fundingMinCapInWei) && (block.number <= fundingEndBlock && block.number >= fundingStartBlock)) {  
        currentStatus = "In progress (Eth < Softcap)";
        return "In progress (Eth < Softcap)";
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number < fundingStartBlock)) {  
        currentStatus = "presale is setup";
        return "presale is setup";
      } else if ((amountRaisedInWei < fundingMinCapInWei) && (block.number > fundingEndBlock)) {  
        currentStatus = "Unsuccessful (Eth < Softcap)";
        return "Unsuccessful (Eth < Softcap)";
      } else if (amountRaisedInWei >= fundingMaxCapInWei) {   
          currentStatus = "Successful (ARX >= Hardcap)!";
          return "Successful (ARX >= Hardcap)!";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number > fundingEndBlock)) {  
          currentStatus = "Successful (Eth >= Softcap)!";
          return "Successful (Eth >= Softcap)!";
      } else if ((amountRaisedInWei >= fundingMinCapInWei) && (block.number <= fundingEndBlock)) {  
        currentStatus = "In progress (Eth >= Softcap)!";
        return "In progress (Eth >= Softcap)!";
      }
      setPrice();
    }

    function refund() {  
       
      require ((amountRaisedInWei < fundingMinCapInWei)
      && (isPresaleClosed)
      && (block.number > fundingEndBlock)
      && (fundValue[msg.sender] > 0));

       
      uint256 ethRefund = fundValue[msg.sender];
      balances[msg.sender] = 0;
      fundValue[msg.sender] = 0;
      Burn(msg.sender, ethRefund);

       
      msg.sender.transfer(ethRefund);
      Refund(msg.sender, ethRefund);
    }

    function withdrawRemainingTokens(uint256 _amountToPull) onlyOwner {
      require(block.number >= fundingEndBlock);
      tokenReward.transfer(msg.sender, _amountToPull);
    }

    function updateStatus() onlyOwner {
      require((block.number >= fundingEndBlock) || (amountRaisedInWei >= fundingMaxCapInWei));
      isPresaleClosed = true;
      currentStatus = "packagesale is closed";
    }
  }