 

pragma solidity ^0.4.16; 

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
}



contract VRCoinCrowdsale {
     
    struct Period
    {
         uint start;
         uint end;
         uint priceInWei;
         uint tokenToDistibute;
    }



     
    uint public constant VRCOIN_DECIMALS = 9;
    uint public constant TOTAL_TOKENS_TO_DISTRIBUTE = 750000 * (10 ** VRCOIN_DECIMALS);  
    
    uint public exchangeRate = 610;
    
    address public owner;  
    bool public hasStarted;  
    Period public sale;  
    ERC20Interface public tokenWallet;  

     
    uint coinToTokenFactor = 10 ** VRCOIN_DECIMALS;
    
     
    event Transfer(address to, uint amount);

     
    event Start(uint timestamp);

     
    event Contribution(address indexed from, uint weiContributed, uint tokensReceived);

    function VRCoinCrowdsale(address walletAddress)
    {
          
         owner = msg.sender;
         tokenWallet = ERC20Interface(walletAddress);

          
         require(tokenWallet.totalSupply() >= TOTAL_TOKENS_TO_DISTRIBUTE);

          
         require(tokenWallet.balanceOf(owner) >= TOTAL_TOKENS_TO_DISTRIBUTE);

          
         hasStarted = false;
                 
         sale.start = 1521234001;  
         sale.end = 1525122001;  
         sale.priceInWei = (1 ether) / (exchangeRate * coinToTokenFactor);  
         sale.tokenToDistibute = TOTAL_TOKENS_TO_DISTRIBUTE;
    }
    
    function updatePrice() {
          
         require(msg.sender == owner);
        
          
         sale.priceInWei = (1 ether) / (exchangeRate * coinToTokenFactor);
    }
    
    function setExchangeRate(uint256 _rate) {
          
         require(msg.sender == owner);        
        
          
         exchangeRate = _rate;
    }

     
    function startSale()
    {
          
         require(msg.sender == owner);
         
          
         require(hasStarted == false);

          
          
         if (!tokenWallet.transferFrom(owner, this, sale.tokenToDistibute))
         {
             
             
            revert();
         }else{
            Transfer(this, sale.tokenToDistibute);
         }

          
         require(tokenWallet.balanceOf(this) >= sale.tokenToDistibute);

          
         hasStarted = true;

          
         Start(block.timestamp);
    }

     
    function changeOwner(address newOwner) public
    {
          
         require(msg.sender == owner);

          
         owner = newOwner;
    }

     
     
    function changeTokenForSale(uint newAmount) public
    {
          
         require(msg.sender == owner);
         
          
         require(hasStarted == false);
         
          
         require(tokenWallet.totalSupply() >= newAmount);

          
         require(tokenWallet.balanceOf(owner) >= newAmount);


          
         sale.tokenToDistibute = newAmount;
    }

     
     
    function changePeriodTime(uint start, uint end) public
    {
          
         require(msg.sender == owner);

          
         require(hasStarted == false);

          
         require(start < end);

          
         sale.start = start;
         sale.end = end;
    }

     
     
    function withdrawTokensRemaining() public
         returns (bool)
    {
          
         require(msg.sender == owner);

          
         uint crowdsaleEnd = sale.end;

          
         require(block.timestamp > crowdsaleEnd);

          
         uint tokensRemaining = getTokensRemaining();

          
         return tokenWallet.transfer(owner, tokensRemaining);
    }

     
     
    function withdrawEtherRemaining() public
         returns (bool)
    {
          
         require(msg.sender == owner);

          
         owner.transfer(this.balance);

         return true;
    }

     
    function getTokensRemaining() public constant
         returns (uint256)
    {
         return tokenWallet.balanceOf(this);
    }

     
    function getTokensForContribution(uint weiContribution) public constant 
         returns(uint tokenAmount, uint weiRemainder)
    {
          
         uint256 bonus = 0;
         
          
         uint crowdsaleEnd = sale.end;
        
          
         require(block.timestamp <= crowdsaleEnd);

          
         uint periodPriceInWei = sale.priceInWei;

          
         
         tokenAmount = weiContribution / periodPriceInWei;
         
	 	
            if (block.timestamp < 1522270801) {
                 
                bonus = tokenAmount * 20 / 100;
            } else if (block.timestamp < 1523739601) {
                 
                bonus = tokenAmount * 15 / 100;
            } else {
                 
                bonus = tokenAmount * 10 / 100;
            }
		 

            
        tokenAmount = tokenAmount + bonus;
        
          
         weiRemainder = weiContribution % periodPriceInWei;
    }
    
     
    function contribute() public payable
    {
          
         require(hasStarted == true);

          
         var (tokenAmount, weiRemainder) = getTokensForContribution(msg.value);

          
         require(tokenAmount > 0);
         
          
         require(weiRemainder <= msg.value);

          
         uint tokensRemaining = getTokensRemaining();
         require(tokensRemaining >= tokenAmount);

          
          
         if (!tokenWallet.transfer(msg.sender, tokenAmount))
         {
             
            revert();
         }

          
         msg.sender.transfer(weiRemainder);

          
          
         uint actualContribution = msg.value - weiRemainder;

          
         Contribution(msg.sender, actualContribution, tokenAmount);
    }
    
    function() payable
    {
        contribute();
    } 
}