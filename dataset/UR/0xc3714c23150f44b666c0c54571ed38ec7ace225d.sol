 

pragma solidity ^0.4.24;

 
  
  function setBuyPrice(uint256 _dollar) public onlyOwner {
    dollarPrice = _dollar;
    buyPrice = (1e18/dollarPrice);  
  }
  
  function setBackEndAddress(address newBackEndOperator) public onlyOwner {
    backEndOperator = newBackEndOperator;
  }
  function setPercentTypeTwo(uint256 newPercent) public onlyOwner {
    percentBuyBackTypeTwo = newPercent;
  }
  
  function setstartBuyBackOne(uint256 newstartBuyBackOne) public onlyOwner {
    startBuyBackOne = newstartBuyBackOne;
  }
  
  function setstartBuyBackTwo(uint256 newstartBuyBackTwo) public onlyOwner {
    startBuyBackTwo = newstartBuyBackTwo;
  }
 
   
  function setInvestTypeOne(address _investor) public backEnd{
      require(_investor != address(0x0));
      require(!isInvestTypeOne(_investor));
      require(!isInvestTypeTwo(_investor));
      investTypeOne[_investor] = true;
  }
  
   
  function setInvestTypeTwo(address _investor) public backEnd{
      require(_investor != address(0x0));
      require(!isInvestTypeOne(_investor));
      require(!isInvestTypeTwo(_investor));
      investTypeTwo[_investor] = true;
  }
  
   function setPreSaleAddres(address _tokenPreSale) public onlyOwner{
      tokenPreSale = _tokenPreSale;
   }
      
   
   
   function isInvestTypeOne(address _investor) internal view returns(bool) {
    return investTypeOne[_investor];
  }
 
  function isInvestTypeTwo(address _investor) internal view returns(bool) {
    return investTypeTwo[_investor];
  }
     
   function isBuyBackOne() public constant returns(bool) {
    return now >= startBuyBackOne;
  }
  
   function isBuyBackTwo() public constant returns(bool) {
    return now >= startBuyBackTwo;
  }
  
   
  
   function buyTokenICO(address _investor, uint256 _value) onlyICO public returns (bool) {
      balancesICOToken[_investor] = balancesICOToken[_investor].add(_value);
      return true;
    }
     
    
   
  function () public payable {
    totalFundsAvailable = totalFundsAvailable.add(msg.value);
  }


   
  function buybackTypeOne() public {
        uint256 allowanceToken = token.allowance(msg.sender,this);
        require(allowanceToken != uint256(0));
        require(isInvestTypeOne(msg.sender));
        require(isBuyBackOne());
        require(balancesICOToken[msg.sender] >= allowanceToken);
        
        uint256 forTransfer = allowanceToken.mul(buyPrice).div(1e18).mul(3);  
        require(totalFundsAvailable >= forTransfer);
        msg.sender.transfer(forTransfer);
        totalFundsAvailable = totalFundsAvailable.sub(forTransfer);
        
        balancesICOToken[msg.sender] = balancesICOToken[msg.sender].sub(allowanceToken);
        token.transferFrom(msg.sender, this, allowanceToken);
   }
   
    
  function buybackTypeTwo() public {
        uint256 allowanceToken = token.allowance(msg.sender,this);
        require(allowanceToken != uint256(0));
        require(isInvestTypeTwo(msg.sender));
        require(isBuyBackTwo());
        require(balancesICOToken[msg.sender] >= allowanceToken);
        
        uint256 accumulated = percentBuyBackTypeTwo.mul(allowanceToken).div(100).mul(5).add(allowanceToken);  
        uint256 forTransfer = accumulated.mul(buyPrice).div(1e18);  
        require(totalFundsAvailable >= forTransfer);
        msg.sender.transfer(forTransfer);
        totalFundsAvailable = totalFundsAvailable.sub(forTransfer);
        
        balancesICOToken[msg.sender] = balancesICOToken[msg.sender].sub(allowanceToken);
        token.transferFrom(msg.sender, this, allowanceToken);
   }
   
}