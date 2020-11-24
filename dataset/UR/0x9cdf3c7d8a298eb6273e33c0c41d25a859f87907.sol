 

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

contract ARXPackageSale is owned, safeMath {
   
  address        public admin                       = owner;       
  ERC20Interface public tokenReward;                               

   
  uint256 public initialARXSupplyInWei;                            
  uint256 public CurrentARXSupplyInWei;                            
  uint256 public EthCapInWei;                                      
  uint256 public tokensPerEthPrice;                                

   
  address public beneficiaryMultisig;                              
  address public foundationMultisig;                               

   
  uint256 public amountRaisedInWei;                                

   
  string  public CurrentStatus                     = "";           
  uint256 public fundingStartBlock;                                
  uint256 public fundingEndBlock;                                  

  bool    public ispackagesaleSetup                = false;        
  bool    public ispackagesaleClosed               = false;        

  event Buy(address indexed _sender, uint256 _eth, uint256 _ARX);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
  mapping (address => uint256) balances;
  mapping (address => mapping (address => uint256)) allowed;

   
  function ARXPackageSale() onlyOwner {
    admin = msg.sender;
    CurrentStatus = "packagesale deployed to chain";
  }

   
  function initialARXtokenSupply() constant returns (uint256 initialARXtokenSupplyCount) {
      initialARXtokenSupplyCount = safeDiv(initialARXSupplyInWei,1 ether);
  }

   
  function currentARXtokenSupply() constant returns (uint256 currentARXtokenSupplyCount) {
      currentARXtokenSupplyCount = safeDiv(CurrentARXSupplyInWei,1 ether);
  }

   
  function Setuppackagesale(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner returns (bytes32 response) {
      if ((msg.sender == admin)
      && (!(ispackagesaleSetup))
      && (!(beneficiaryMultisig > 0))){
           
          tokenReward                             = ERC20Interface(0xb0D926c1BC3d78064F3e1075D5bD9A24F35Ae6C5);    
          beneficiaryMultisig                     = 0x5Ed4706A93b8a3239f97F7d2025cE1f9eaDcD9A4;                    
          foundationMultisig                      = 0x5Ed4706A93b8a3239f97F7d2025cE1f9eaDcD9A4;                    
          tokensPerEthPrice                       = 8500;                                                          

           
          initialARXSupplyInWei                   = 6500000000000000000000000;                                     
          CurrentARXSupplyInWei                   = initialARXSupplyInWei;
          EthCapInWei                             = 500000000000000000000;                                         
          amountRaisedInWei                       = 0;

           
          fundingStartBlock                       = _fundingStartBlock;
          fundingEndBlock                         = _fundingEndBlock;

           
          ispackagesaleSetup                      = true;
          ispackagesaleClosed                     = false;
          CurrentStatus                           = "packagesale is activated";

          return "packagesale is setup";
      } else if (msg.sender != admin) {
          return "not authorized";
      } else  {
          return "campaign cannot be changed";
      }
    }

     
    function () payable {
      require(msg.data.length == 0);
      BuyARXtokens();
    }

    function BuyARXtokens() payable {
       
      require(!(msg.value == 0)
      && (ispackagesaleSetup)
      && (block.number >= fundingStartBlock)
      && (block.number <= fundingEndBlock)
      && (amountRaisedInWei < EthCapInWei));

       
      uint256 rewardTransferAmount    = 0;

       
      if (msg.value==25000000000000000000) {  
        tokensPerEthPrice=8500;
      } else if (msg.value==50000000000000000000) {  
        tokensPerEthPrice=10500;
      } else if (msg.value==100000000000000000000) {  
        tokensPerEthPrice=12500;
      } else {
        revert();
      }

      amountRaisedInWei               = safeAdd(amountRaisedInWei,msg.value);
      rewardTransferAmount            = safeMul(msg.value,tokensPerEthPrice);
      CurrentARXSupplyInWei           = safeSub(CurrentARXSupplyInWei,rewardTransferAmount);

       
      tokenReward.transfer(msg.sender, rewardTransferAmount);

       
      Transfer(this, msg.sender, msg.value);
      Buy(msg.sender, msg.value, rewardTransferAmount);
    }

    function beneficiaryMultiSigWithdraw(uint256 _amount) onlyOwner {
      beneficiaryMultisig.transfer(_amount);
    }

    function updateStatus() onlyOwner {
      require((block.number >= fundingEndBlock) || (amountRaisedInWei >= EthCapInWei));
      CurrentStatus = "packagesale is closed";
    }

    function withdrawRemainingTokens(uint256 _amountToPull) onlyOwner {
      require(block.number >= fundingEndBlock);
      tokenReward.transfer(msg.sender, _amountToPull);
    }
}