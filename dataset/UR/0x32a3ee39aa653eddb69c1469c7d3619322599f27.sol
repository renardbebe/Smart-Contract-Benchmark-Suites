 

pragma solidity ^0.4.18;
 
 
 
 
 
 
 
 
 

 
 
 
 
interface ERC20I {
    function transfer(address _recipient, uint256 _amount) public returns (bool);
    function balanceOf(address _holder) public view returns (uint256);
}

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
  StandardToken  public tokenContract;                         

   

  string  public CurrentStatus = "";                           
  uint256 public fundingStartBlock;                            
  uint256 public fundingEndBlock;                              
  uint256 public successAtBlock;                               
  uint256 public amountRaisedInUsd;                            
  uint256 public tokensPerEthAtRegularPrice;                   
  bool public successfulFunding;                               
         
  

  event Transfer(address indexed from, address indexed to, uint256 value); 
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Buy(address indexed _sender, uint256 _eth, uint256 _MOY);
  mapping(address => uint256) balancesArray;
  mapping(address => uint256) fundValue;

   
  function MoyTokenStorage() public onlyOwner {
    admin = msg.sender;
    CurrentStatus = "In-Platform POW Tokens Storage Released";
  }

  
   
  function setupFunding(uint256 _fundingStartBlock, uint256 _fundingEndBlock, address _tokenContract) public onlyOwner returns (bytes32 response) {
      
      if (msg.sender == admin)
      {
          tokenContract = StandardToken(_tokenContract);                               
          tokensPerEthAtRegularPrice = 1000;                                          
          amountRaisedInUsd = 0;

          fundingStartBlock = _fundingStartBlock;
          fundingEndBlock = _fundingEndBlock;
                
          CurrentStatus = "Fundind of Proyect in Process";
           
          
          return "PreSale is setup.";

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
          successfulFunding = true;       
          CurrentStatus = "Funding Successful, in-platform tokens ready to use.";

          
          return "All in-platform tokens backed.";
      } else if (msg.sender != admin) {
          return "Not Authorized";
      } else {
          return "Setup cannot be changed.";
      }
    }

    function transferTokens(address _tokenAddress, address _recipient) public onlyOwner returns (bool) { 
       ERC20I e = ERC20I(_tokenAddress);
       require(e.transfer(_recipient, e.balanceOf(this)));
       return true;
   }

     
     
    function () public payable {
      require(msg.sender == admin);
      Transfer(this, msg.sender, msg.value); 
    }
}