 

pragma solidity ^0.4.23;

 

contract ERC20Interface {
    function transfer(address to, uint256 tokens) public returns (bool success);
}

contract POWH {
    function buy(address) public payable returns(uint256);
    function sell(uint256) public;
    function withdraw() public;
    function myTokens() public view returns(uint256);
    function myDividends(bool) public view returns(uint256);
}

contract CharityMiner {
    using SafeMath for uint256;
    
     
    modifier notP3d(address aContract) {
        require(aContract != address(p3d));
        _;
    }
    
     
    event Deposit(uint256 amount, address depositer, uint256 donation);
    event Withdraw(uint256 tokens, address depositer, uint256 tokenValue, uint256 donation);
    event Dividends(uint256 amount, address sender);
    event Paused(bool paused);
    
     
    bool public paused = false;
    address public charityAddress = 0x8f951903C9360345B4e1b536c7F5ae8f88A64e79;  
    address public owner;
    address public P3DAddress;
    address public largestDonor;
    address public lastDonor;
    uint public totalDonors;
    uint public totalDonated;
    uint public totalDonations;
    uint public largestDonation;
    uint public currentHolders;
    uint public totalDividends;
    
     
    mapping( address => bool ) public donor;
    mapping( address => uint256 ) public userTokens;
    mapping( address => uint256 ) public userDonations;
    
     
    POWH p3d;
	
	 
	constructor(address powh) public {
	    p3d = POWH(powh);
	    P3DAddress = powh;
	    owner = msg.sender;
	}
	
	 
	 
	 
	function pause() public {
	    require(msg.sender == owner && myTokens() == 0);
	    paused = !paused;
	    
	    emit Paused(paused);
	}
	
	 
	 
	function() payable public {
	    if(msg.sender != address(p3d)) {  
    	    uint8 feeDivisor = 4;  
    	    deposit(feeDivisor);
	    }
	}

	 
     
	 
	function deposit(uint8 feeDivisor) payable public {
	    require(msg.value > 100000 && !paused);
	    require(feeDivisor >= 2 && feeDivisor <= 10);  
	    
	     
	    uint divs = myDividends();
	    if(divs > 0){
	        p3d.withdraw();
	    }
	    
	     
	    uint fee = msg.value.div(feeDivisor);
	    uint purchase = msg.value.sub(fee);
	    uint donation = divs.add(fee);
	    
	     
	    charityAddress.transfer(donation);
	    
	     
	    uint tokens = myTokens();
	    p3d.buy.value(purchase)(msg.sender);
	    uint newTokens = myTokens().sub(tokens);
	    
	     
	    if(!donor[msg.sender]){
	        donor[msg.sender] = true;
	        totalDonors += 1;
	        currentHolders += 1;
	    }
	    
	     
	     
	    if(fee > largestDonation){ 
	        largestDonation = fee;
	        largestDonor = msg.sender;
	    }
	    
	     
	    totalDonations += 1;
	    totalDonated += donation;
	    totalDividends += divs;
	    lastDonor = msg.sender;
	    userDonations[msg.sender] = userDonations[msg.sender].add(fee); 
	    userTokens[msg.sender] = userTokens[msg.sender].add(newTokens);
	    
	     
	    emit Deposit(purchase, msg.sender, donation);
	}
	
	 
	 
	 
	function withdraw() public {
	    uint tokens = userTokens[msg.sender];
	    require(tokens > 0);
	    
	     
	    uint divs = myDividends();
	    uint balance = address(this).balance;
	    
	     
	    userTokens[msg.sender] = 0;
	    
	     
	    p3d.sell(tokens);
	    p3d.withdraw();
	    
	     
	    uint tokenValue = address(this).balance.sub(divs).sub(balance);
	    
	     
	    charityAddress.transfer(divs);
	    msg.sender.transfer(tokenValue);
	    
	     
	    totalDonated += divs;
	    totalDividends += divs;
	    totalDonations += 1;
	    currentHolders -= 1;
	    
	     
	    emit Withdraw(tokens, msg.sender, tokenValue, divs);
	}
	
	 
	 
	function sendDividends() public {
	    uint divs = myDividends();
	     
	    require(divs > 100000);
	    p3d.withdraw();
	    
	     
	    charityAddress.transfer(divs);
	    
	     
	    totalDonated += divs;
	    totalDividends += divs;
	    totalDonations += 1;
	    
	     
	    emit Dividends(divs, msg.sender);
	}
	
     
     
    function myTokens() public view returns(uint256) {
        return p3d.myTokens();
    }
    
	 
	 
	function myDividends() public view returns(uint256) {
        return p3d.myDividends(true);
    }
	
	 
	function transferAnyERC20Token(address tokenAddress, address tokenOwner, uint tokens) public notP3d(tokenAddress) returns (bool success) {
		require(msg.sender == owner);
		return ERC20Interface(tokenAddress).transfer(tokenOwner, tokens);
	}
    
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}