 

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
    
    contract owned {
        address public owner;
    	using SafeMath for uint256;
    	
        constructor() public {
            owner = msg.sender;
        }
    
        modifier onlyOwner {
            require(msg.sender == owner);
            _;
        }
    
        function transferOwnership(address newOwner) onlyOwner public {
            owner = newOwner;
        }
    }
    
    
    interface token {
    function transfer(address receiver, uint amount) external;
    }
    
    contract ExTokeCrowdSale is owned {
         
        using SafeMath for uint256;
    	uint256 public startTime = 1530075600;  
    	uint256 public EndTime = 1532217540;    
		uint256 public ExchangeRate=0.000001 * (1 ether);
        token public tokenReward;
        
		 
        event Transfer(address indexed from, address indexed to, uint256 value);
        
        constructor (
        address addressOfTokenUsedAsReward
        ) public {
        tokenReward = token(addressOfTokenUsedAsReward);
        }
        function () payable public{
             require(EndTime > now);
             require (startTime < now);
            uint256 ethervalue=msg.value;
            uint256 tokenAmount=ethervalue.div(ExchangeRate);
            tokenReward.transfer(msg.sender, tokenAmount.mul(1 ether));			 
			owner.transfer(msg.value);	 
        }
        
        function withdrawEtherManually()onlyOwner public{
		    require(msg.sender == owner); 
			uint256 amount=address(this).balance;
			owner.transfer(amount);
		}
		
        function withdrawTokenManually(uint256 tokenAmount) onlyOwner public{
            require(msg.sender == owner);
            tokenReward.transfer(msg.sender,tokenAmount);
        }
        
        function setExchangeRate(uint256 NewExchangeRate) onlyOwner public {
            require(msg.sender == owner);
			ExchangeRate=NewExchangeRate;
        }
    }