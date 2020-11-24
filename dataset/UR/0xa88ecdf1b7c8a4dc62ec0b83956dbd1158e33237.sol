 

pragma solidity 0.5.4;   

 
 
 
 
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
    address payable public owner;
    
     constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable newOwner) onlyOwner public {
        owner = newOwner;
    }
}


interface TokenRecipient { function transfer(address _to, uint256 _value) external; }

contract IPUXcrowdsale is owned {
    
     
    

     
    address public tokenAddress;
    uint256 public tokenDecimal;
    using SafeMath for uint256;
    TokenRecipient tokenContract = TokenRecipient(tokenAddress);
    
     
    uint256 public icoPeriod1start  = 1547510400;    
    uint256 public icoPeriod1end    = 1550361600;    
    uint256 public icoPeriod2start  = 1551398400;    
    uint256 public icoPeriod2end    = 1553990400;    
    uint256 public icoPeriod3start  = 1555286400;    
    uint256 public icoPeriod3end    = 1556582400;    
    uint256 public softcap          = 70000 ether;
    uint256 public hardcap          = 400000 ether;
    uint256 public fundRaised       = 0;
    uint256 public exchangeRate     = 500;            
    


     
    
     
    constructor () public { }
    
     
    function updateToken(address _tokenAddress, uint256 _tokenDecimal) public onlyOwner {
        require(_tokenAddress != address(0), 'Address is invalid');
        tokenAddress = _tokenAddress;
        tokenDecimal = _tokenDecimal;
    }
    
     
    function () payable external {
         
        require(fundRaised < hardcap, 'hard cap is reached');
         
		if((icoPeriod1start < now && icoPeriod1end > now) || (icoPeriod2start < now && icoPeriod2end > now) || icoPeriod3start < now && icoPeriod3end > now){
         
		uint256 token = msg.value.mul(exchangeRate);                    
		 
		uint256 finalTokens = token.add(calculatePurchaseBonus(token));
         
		tokenContract.transfer(msg.sender, finalTokens);
		}
		fundRaised += msg.value;
		 
		owner.transfer(msg.value);                                           
	}

     
    function calculatePurchaseBonus(uint256 token) internal view returns(uint256){
	    if(icoPeriod1start < now && icoPeriod1end > now){
	        return token.mul(30).div(100);   
	    }
	    else if(icoPeriod2start < now && icoPeriod2end > now){
	        return token.mul(20).div(100);   
	    }
	    else{
	        return 0;                        
	    }
	}
      
     
    function manualWithdrawEther()onlyOwner public{
        address(owner).transfer(address(this).balance);
    }
    
    function manualWithdrawTokens(uint256 tokenAmount) public onlyOwner{
         
         
        tokenContract.transfer(owner, tokenAmount);
    }
    
}