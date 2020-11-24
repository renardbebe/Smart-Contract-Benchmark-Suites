 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


contract EtherPiggyBank {
    
     
    mapping (address => uint256) public investedETH;
    mapping (address => uint256) public lastInvest;
    
     
    mapping (address => uint256) public affiliateCommision;
    uint256 REF_BONUS = 4;  
     
    uint256 DEV_TAX = 1;  
     
    
    uint256 BASE_PRICE = 0.125 ether;  
    uint256 INHERITANCE_TAX = 75;  
     
     
    uint256 DEV_TRANSFER_TAX = 5;
     
     
     
     
     
    struct InvestorPosition {
        address investor;
        uint256 startingLevel;
        uint256 startingTime;
        uint256 halfLife;
        uint256 percentageCut;
    }

    InvestorPosition[] investorPositions; 
    address dev;

     
    function EtherPiggyBank() public {
        
         
        dev = msg.sender;
        
         
        investorPositions.push(InvestorPosition({
            investor: dev,
            startingLevel: 5,  
            startingTime: now,
            halfLife: 7 days,  
            percentageCut: 5  
            }));

         
        investorPositions.push(InvestorPosition({
            investor: 0x6C0CF053076681CeCBE31E5E19Df8Fb97DeB5756,
            startingLevel: 4,  
            startingTime: now,
            halfLife: 5 days,  
            percentageCut: 3  
            }));

         
        investorPositions.push(InvestorPosition({
            investor: 0x66fE910c6a556173EA664A94F334d005dDc9cE9E,
            startingLevel: 3,  
            startingTime: now,
            halfLife: 3 days,  
            percentageCut: 1  
            }));
    }
    
    function investETH(address referral) public payable {
        
        require(msg.value >= 0.01 ether);
        
        if (getProfit(msg.sender) > 0) {
            uint256 profit = getProfit(msg.sender);
            lastInvest[msg.sender] = now;
            msg.sender.transfer(profit);
        }
        
        uint256 amount = msg.value;

         
        bool flaggedRef = (referral == msg.sender || referral == dev);  
        for(uint256 i = 0; i < investorPositions.length; i++) {
            
            InvestorPosition memory position = investorPositions[i];

             
            if (position.investor == referral) {
                flaggedRef = true;
            }
            
             
            if (position.investor != msg.sender) {
                uint256 commision = SafeMath.div(SafeMath.mul(amount, position.percentageCut), 100);
                affiliateCommision[position.investor] = SafeMath.add(affiliateCommision[position.investor], commision);
            }

        }

         
        if (!flaggedRef && referral != 0x0) {
            uint256 refBonus = SafeMath.div(SafeMath.mul(amount, REF_BONUS), 100);  
            affiliateCommision[referral] = SafeMath.add(affiliateCommision[referral], refBonus);
        }
        
         
        uint256 devTax = SafeMath.div(SafeMath.mul(amount, DEV_TAX), 100);  
        affiliateCommision[dev] = SafeMath.add(affiliateCommision[dev], devTax);

        
         
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], amount);
        lastInvest[msg.sender] = now;

    }
    
    function divestETH() public {

        uint256 profit = getProfit(msg.sender);
        
         
        uint256 capital = investedETH[msg.sender];
        uint256 fee = SafeMath.div(capital, 5);
        capital = SafeMath.sub(capital, fee);
        
        uint256 total = SafeMath.add(capital, profit);

        require(total > 0);
        investedETH[msg.sender] = 0;
        lastInvest[msg.sender] = now;
        msg.sender.transfer(total);

    }
    
    function withdraw() public{

        uint256 profit = getProfit(msg.sender);

        require(profit > 0);
        lastInvest[msg.sender] = now;
        msg.sender.transfer(profit);

    }

    function withdrawAffiliateCommision() public {

        require(affiliateCommision[msg.sender] > 0);
        uint256 commision = affiliateCommision[msg.sender];
        affiliateCommision[msg.sender] = 0;
        msg.sender.transfer(commision);

    }
    
    function reinvestProfit() public {

        uint256 profit = getProfit(msg.sender);

        require(profit > 0);
        lastInvest[msg.sender] = now;
        investedETH[msg.sender] = SafeMath.add(investedETH[msg.sender], profit);

    }

    function inheritInvestorPosition(uint256 index) public payable {

        require(investorPositions.length > index);
        require(msg.sender == tx.origin);

        InvestorPosition storage position = investorPositions[index];
        uint256 currentLevel = getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife);
        uint256 currentPrice = getCurrentPrice(currentLevel);

        require(msg.value >= currentPrice);
        uint256 purchaseExcess = SafeMath.sub(msg.value, currentPrice);
        position.startingLevel = currentLevel + 1;
        position.startingTime = now;

         
        uint256 inheritanceTax = SafeMath.div(SafeMath.mul(currentPrice, INHERITANCE_TAX), 100);  
        position.investor.transfer(inheritanceTax);
        position.investor = msg.sender;  

         
        uint256 devTransferTax = SafeMath.div(SafeMath.mul(currentPrice, DEV_TRANSFER_TAX), 100);  
        dev.transfer(devTransferTax);

         
        msg.sender.transfer(purchaseExcess);

         
         

    }

    function getInvestorPosition(uint256 index) public view returns(address investor, uint256 currentPrice, uint256 halfLife, uint256 percentageCut) {
        InvestorPosition memory position = investorPositions[index];
        return (position.investor, getCurrentPrice(getCurrentLevel(position.startingLevel, position.startingTime, position.halfLife)), position.halfLife, position.percentageCut);
    }

    function getCurrentPrice(uint256 currentLevel) internal view returns(uint256) {
        return BASE_PRICE * 2**currentLevel;  
    }

    function getCurrentLevel(uint256 startingLevel, uint256 startingTime, uint256 halfLife) internal view returns(uint256) {
        uint256 timePassed = SafeMath.sub(now, startingTime);
        uint256 levelsPassed = SafeMath.div(timePassed, halfLife);
        if (startingLevel < levelsPassed) {
            return 0;
        }
        return SafeMath.sub(startingLevel,levelsPassed);
    }

    function getProfitFromSender() public view returns(uint256){
        return getProfit(msg.sender);
    }

    function getProfit(address customer) public view returns(uint256){
        uint256 secondsPassed = SafeMath.sub(now, lastInvest[customer]);
        return SafeMath.div(SafeMath.mul(secondsPassed, investedETH[customer]), 5760000);  
    }
    
    function getAffiliateCommision() public view returns(uint256){
        return affiliateCommision[msg.sender];
    }
    
    function getInvested() public view returns(uint256){
        return investedETH[msg.sender];
    }
    
    function getBalance() public view returns(uint256){
        return this.balance;
    }

}

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