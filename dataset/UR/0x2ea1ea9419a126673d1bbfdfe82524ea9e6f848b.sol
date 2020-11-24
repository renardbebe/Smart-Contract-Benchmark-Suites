 

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

contract MoyTokenStorage is owned, safeMath {
   
  address        public admin = owner;    
  StandardToken  public tokenReward;      

   

  string  public CurrentStatus = "";                           
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  uint256 public successAtBlock;                               
  uint256 public amountRaisedInUsd;                            
  uint256 public tokensPerEthAtRegularPrice;       
  

  event Transfer(address indexed from, address indexed to, uint256 value); 
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _MOY);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) fundValue;

   
  function MoyTokenStorage() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "In-Platform POW Tokens Storage Released";
  }

  
   
  function setupStorage(uint256 _fundingStartBlock, uint256 _fundingEndBlock) public onlyOwner returns (bytes32 response) {
      
      if (msg.sender == admin)
      {
          tokenReward = StandardToken(0x2a47E3c69DeAAe8dbDc5ee272d1a3C0f9853DcBD);   
          tokensPerEthAtRegularPrice = 1000;                                         
          amountRaisedInUsd = 0;

          fundingStartBlock = _fundingStartBlock;
          fundingEndBlock = _fundingEndBlock;
                
          CurrentStatus = "Fundind of Proyect in Process";
           
          
          return "Storage is setup.";

      } else if (msg.sender != admin) {
          return "Not Authorized";
      } else  {
          return "Setup cannot be changed.";
      }
    }

   
  function FundingCompleted(uint256 _amountRaisedInUsd, uint256 _successAtBlock) public onlyOwner returns (bytes32 response) {
      if (msg.sender == admin)
      {
           
          amountRaisedInUsd = _amountRaisedInUsd;  
          successAtBlock = _successAtBlock;        
                 
          CurrentStatus = "Funding Successful, in-platform tokens ready to use.";
          
          return "All in-platform tokens backed.";
      } else if (msg.sender != admin) {
          return "Not Authorized";
      } else  {
          return "Setup cannot be changed.";
      }
    }

     
     
    function () public payable {
      require(msg.sender == admin);
      Transfer(this, msg.sender, msg.value); 
    }
}