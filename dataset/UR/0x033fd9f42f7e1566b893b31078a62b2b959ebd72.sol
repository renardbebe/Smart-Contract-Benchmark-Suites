 

pragma solidity ^0.4.20; 

contract ERC20Interface {
    function totalSupply() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public constant returns (uint256);
}

 
 
 
 
 

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token) external;
}

contract TRLCoinSale is ApproveAndCallFallBack {
     
    struct Period {
        uint start;
        uint end;
        uint priceInWei;
        uint tokens;
    }

     
    struct PaymentContribution {
        uint weiContributed;
        uint timeContribution;
        uint receiveTokens;
    }

    struct TotalContribution {
         
         
        uint totalReceiveTokens;
         
         
        PaymentContribution[] paymentHistory; 
    }

     
    uint public constant TRLCOIN_DECIMALS = 0;
    uint public constant TOTAL_TOKENS_TO_DISTRIBUTE = 800000000 * (10 ** TRLCOIN_DECIMALS);  
    uint public constant TOTAL_TOKENS_AVAILABLE = 1000000000 * (10 ** TRLCOIN_DECIMALS);     

     
    ERC20Interface private tokenWallet;  
    
    address private owner;   
    
    uint private smallBonus;  
    uint private largeBonus;  
    uint private largeBonusStopTime;  

    uint private tokensRemainingForSale;  
    uint private tokensAwardedForSale;    

    uint private distributionTime;  
    
    Period private preSale;  
    Period private sale;     
    
    
     
    mapping(address => TotalContribution) public payments;  
    address[] public paymentAddresses;

    bool private hasStarted;  
    
     
    event Transfer(address indexed to, uint amount);

     
    event Start(uint timestamp);

     
    event Contribute(address indexed from, uint weiContributed, uint tokensReceived);

     
    event Distribute( address indexed to, uint tokensSend );

    function addContribution(address from, uint weiContributed, uint tokensReceived) private returns(bool) {
         
        require(weiContributed > 0);
        require(tokensReceived > 0);
        require(tokensRemainingForSale >= tokensReceived);
        
        PaymentContribution memory newContribution;
        newContribution.timeContribution = block.timestamp;
        newContribution.weiContributed = weiContributed;
        newContribution.receiveTokens = tokensReceived;

         
         
        if (payments[from].totalReceiveTokens == 0) {
             
            payments[from].totalReceiveTokens = tokensReceived;
            payments[from].paymentHistory.push(newContribution);
            
              
            paymentAddresses.push(from);
        } else {
            payments[from].totalReceiveTokens += tokensReceived;
            payments[from].paymentHistory.push(newContribution);
        }
        tokensRemainingForSale -= tokensReceived;
        tokensAwardedForSale += tokensReceived;
        return true;
    }

     
    function getOwner() public view returns (address) { return owner; }
    function getHasStartedState() public view  returns(bool) { return hasStarted; }
    function getPresale() public view returns(uint, uint, uint, uint) { 
        return (preSale.start, preSale.end, preSale.priceInWei, preSale.tokens);
    }
    function getSale() public view returns(uint, uint, uint, uint) { 
        return (sale.start, sale.end, sale.priceInWei, sale.tokens);
    }
    function getDistributionTime() public view returns(uint) { return distributionTime; }
    
    function getSmallBonus() public view returns(uint) { return smallBonus; }
    function getLargeBonus() public view returns(uint) { return largeBonus; }
    function getLargeBonusStopTime() public view returns(uint) { return  largeBonusStopTime; }
    function getTokenRemaining() public view returns(uint) { return tokensRemainingForSale; }
    function getTokenAwarded() public view returns(uint) { return tokensAwardedForSale; }

     
     
     
     
    function receiveApproval(address from, uint256 tokens, address token) external {
         
        require(hasStarted == false);
        
         
        require(token == address(tokenWallet)); 
        
        tokensRemainingForSale += tokens;
        bool result = tokenWallet.transferFrom(from, this, tokens);
         
        require(result == true);
        
        Transfer(address(this), tokens);
    }

     
    function TRLCoinSale(address walletAddress) public {
         
        owner = msg.sender;
        tokenWallet = ERC20Interface(walletAddress);

         
        require(tokenWallet.totalSupply() == TOTAL_TOKENS_AVAILABLE);

         
        require(tokenWallet.balanceOf(owner) >= TOTAL_TOKENS_TO_DISTRIBUTE);

         
        uint coinToTokenFactor = 10 ** TRLCOIN_DECIMALS;

        preSale.start = 1520812800;  
        preSale.end = 1523491199;  
        preSale.priceInWei = (1 ether) / (20000 * coinToTokenFactor);  
        preSale.tokens = TOTAL_TOKENS_TO_DISTRIBUTE / 2;
       
        smallBonus = 10;
        largeBonus = 20;
        largeBonusStopTime = 1521504000;
    
        sale.start = 1523491200;  
        sale.end = 1531378799;  
        sale.priceInWei = (1 ether) / (10000 * coinToTokenFactor);  
        sale.tokens = TOTAL_TOKENS_TO_DISTRIBUTE / 2;
        
        distributionTime = 1531378800;  

        tokensRemainingForSale = 0;
        tokensAwardedForSale = 0;
    }

     
    function setPresaleDates(uint startDate, uint stopDate) public {
         
        require(msg.sender == owner); 
         
        require(hasStarted == false);
         
        require(startDate < stopDate && stopDate < sale.start);
        
        preSale.start = startDate;
        preSale.end = stopDate;
    }
    
     
    function setlargeBonusStopTime(uint bonusStopTime) public {
         
        require(msg.sender == owner); 
         
        require(hasStarted == false);
         
        require(preSale.start <= bonusStopTime && bonusStopTime <= preSale.end);
        
        largeBonusStopTime = bonusStopTime;
    }
    
     
    function setSale(uint startDate, uint stopDate) public {
         
        require(msg.sender == owner); 
         
        require(hasStarted == false);
         
        require(startDate < stopDate && startDate > preSale.end);
         
        require(sale.end < distributionTime);
        
        sale.start = startDate;
        sale.end = stopDate;
    }

     
    function setDistributionTime(uint timeOfDistribution) public {
         
        require(msg.sender == owner); 
         
        require(hasStarted == false);
         
        require(sale.end < timeOfDistribution);
        
        distributionTime = timeOfDistribution;
    }

     
     
    function addContributorManually( address who, uint contributionWei, uint tokens) public returns(bool) {
         
        require(msg.sender == owner);   
         
        require(hasStarted == false);
         
        require(block.timestamp < preSale.start);
         
        require((tokensRemainingForSale + tokensAwardedForSale) == TOTAL_TOKENS_TO_DISTRIBUTE);
        
         
        preSale.tokens -= tokens;

        addContribution(who, contributionWei, tokens);
        Contribute(who, contributionWei, tokens);
        return true;
    }

     
    function startSale() public {
         
        require(msg.sender == owner); 
         
        require(hasStarted == false);
         
        require(preSale.end > preSale.start);
        require(sale.end > sale.start);
        require(sale.start > preSale.end);
        require(distributionTime > sale.end);

         
        require(tokenWallet.balanceOf(address(this)) == TOTAL_TOKENS_TO_DISTRIBUTE);
        require((tokensRemainingForSale + tokensAwardedForSale) == TOTAL_TOKENS_TO_DISTRIBUTE);

         
        require((preSale.tokens + sale.tokens) == tokensRemainingForSale);          

         
        hasStarted = true;

         
        Start(block.timestamp);
    }    

     
    function changeOwner(address newOwner) public {
         
        require(msg.sender == owner);

         
        owner = newOwner;
    }

    function preSaleFinishedProcess( uint timeOfRequest) private returns(bool) {
         
        require(timeOfRequest >= sale.start && timeOfRequest <= sale.end);
        if (preSale.tokens != 0) {
            uint savePreSaleTomens = preSale.tokens;
            preSale.tokens = 0;
            sale.tokens += savePreSaleTomens;
        }
        return true;
    }
    
     
    function getTokensForContribution(uint weiContribution) private returns(uint timeOfRequest, uint tokenAmount, uint weiRemainder, uint bonus) { 
         
        timeOfRequest = block.timestamp;
         
        bonus = 0;
                 
         
        if (timeOfRequest <= preSale.end) {
             
             
            tokenAmount = weiContribution / preSale.priceInWei;
            weiRemainder = weiContribution % preSale.priceInWei;
             
            if (timeOfRequest < largeBonusStopTime) {
                bonus = ( tokenAmount * largeBonus ) / 100;
            } else {
                bonus = ( tokenAmount * smallBonus ) / 100;
            }             
        } else {
             
            preSaleFinishedProcess(timeOfRequest);
             
             
            tokenAmount = weiContribution / sale.priceInWei;
            weiRemainder = weiContribution % sale.priceInWei;
        } 
        return(timeOfRequest, tokenAmount, weiRemainder, bonus);
    }
    
    function()public payable {
         
        require(hasStarted == true);
         
        require((block.timestamp >= preSale.start && block.timestamp <= preSale.end)
            || (block.timestamp >= sale.start && block.timestamp <= sale.end)
        ); 

         
        require(msg.value >= 100 finney);
        
        uint timeOfRequest;
        uint tokenAmount;
        uint weiRemainder;
        uint bonus;
         
        (timeOfRequest, tokenAmount, weiRemainder, bonus) = getTokensForContribution(msg.value);

         
        require(tokensRemainingForSale >= tokenAmount + bonus);
        
         
        require(tokenAmount > 0);
        
         
        require(weiRemainder <= msg.value);

         
        if (timeOfRequest <= preSale.end) {
            require(tokenAmount <= preSale.tokens);
            require(bonus <= sale.tokens);
            preSale.tokens -= tokenAmount;
            sale.tokens -= bonus;
        } else {
            require(tokenAmount <= sale.tokens);
             
            require(bonus == 0); 
            sale.tokens -= tokenAmount;
        }

         
        addContribution(msg.sender, msg.value - weiRemainder, tokenAmount + bonus);

         
        owner.transfer(msg.value - weiRemainder);
         
        msg.sender.transfer(weiRemainder);

         
         
        
         
        Contribute(msg.sender, msg.value - weiRemainder, tokenAmount + bonus);
    } 

    
     
     
    function withdrawTokensRemaining() public returns (bool) {
         
        require(msg.sender == owner);
         
        require(block.timestamp > sale.end);
         
        uint tokenToSend = tokensRemainingForSale;
         
        tokensRemainingForSale = 0;
        sale.tokens = 0;
         
        bool result = tokenWallet.transfer(owner, tokenToSend);
         
        require(result == true);
        Distribute(owner, tokenToSend);
        return true;
    }

     
     
    function withdrawEtherRemaining() public returns (bool) {
         
        require(msg.sender == owner);
         
        require(block.timestamp > sale.end);

         
        owner.transfer(this.balance);
        return true;
    }

     
    function transferTokensToContributor(uint idx) private returns (bool) {
        if (payments[paymentAddresses[idx]].totalReceiveTokens > 0) {
             
            uint tokenToSend = payments[paymentAddresses[idx]].totalReceiveTokens;
            payments[paymentAddresses[idx]].totalReceiveTokens = 0;
            
             
            require(tokensAwardedForSale >= tokenToSend);
            tokensAwardedForSale -= tokenToSend;
             
            bool result = tokenWallet.transfer(paymentAddresses[idx], tokenToSend);
             
            require(result == true);
            Distribute(paymentAddresses[idx], tokenToSend);
        }
        return true;

    }
    
     
    function getNumberOfContributors( ) public view returns (uint) {
        return paymentAddresses.length;
    }
    
     
    function distributeTokensToContributorByIndex( uint indexVal) public returns (bool) {
         
        require(msg.sender == owner);
        require(block.timestamp >= distributionTime);
        require(indexVal < paymentAddresses.length);
        
        transferTokensToContributor(indexVal);                    
        return true;        
    }

    function distributeTokensToContributor( uint startIndex, uint numberOfContributors )public returns (bool) {
         
        require(msg.sender == owner);
        require(block.timestamp >= distributionTime);
        require(startIndex < paymentAddresses.length);
        
        uint len = paymentAddresses.length < startIndex + numberOfContributors? paymentAddresses.length : startIndex + numberOfContributors;
        for (uint i = startIndex; i < len; i++) {
            transferTokensToContributor(i);                    
        }
        return true;        
    }

    function distributeAllTokensToContributor( )public returns (bool) {
         
        require(msg.sender == owner);
        require(block.timestamp >= distributionTime);
        
        for (uint i = 0; i < paymentAddresses.length; i++) {
            transferTokensToContributor(i); 
        }
        return true;        
    }
    
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public returns (bool) {
        require(msg.sender == owner);
        require(tokenAddress != address(tokenWallet));
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}