 

pragma solidity ^0.4.24;

 
  
  function authorize(address wlCandidate) public backEnd  {
    require(wlCandidate != address(0x0));
    require(!isWhitelisted(wlCandidate));
    whitelist[wlCandidate] = true;
    investors++;
    emit Authorized(wlCandidate, now);
  }
  
  function revoke(address wlCandidate) public  onlyOwner {
    whitelist[wlCandidate] = false;
    investors--;
    emit Revoked(wlCandidate, now);
  }
  
  function isWhitelisted(address wlCandidate) internal view returns(bool) {
    return whitelist[wlCandidate];
  }
  
   
  
  function isPreSale() public constant returns(bool) {
    return now >= startPreSale && now <= endPreSale;
  }
  
  
  function () public payable {
    require(isWhitelisted(msg.sender));
    require(isPreSale());
    preSale(msg.sender, msg.value);
    require(soldTokensPreSale<=hardCapPreSale);
    investedEther[msg.sender] = investedEther[msg.sender].add(msg.value);
  }
  
  
  function preSale(address _investor, uint256 _value) internal {
    uint256 tokens = _value.mul(1e18).div(buyPrice);
    uint256 tokensByDate = tokens.mul(bonusDate()).div(100);
    tokens = tokens.add(tokensByDate);
    token.mintFromICO(_investor, tokens);
	
    BuyBackContract.buyTokenICO(_investor, tokens); 
	
    soldTokensPreSale = soldTokensPreSale.add(tokens);  
    
    uint256 tokensTeam = tokens.mul(5).div(44);  
    token.mintFromICO(team, tokensTeam);
    
    uint256 tokensBoynty = tokens.div(44);  
    token.mintFromICO(bounty, tokensBoynty);
    
    weisRaised = weisRaised.add(_value);
  }
  
  
  function bonusDate() private view returns (uint256){
    if (now > startPreSale && now < stage1Sale) {   
      return 72;
    }
    else if (now > stage1Sale && now < stage2Sale) {  
      return 60;
    }
    else if (now > stage2Sale && now < stage3Sale) {  
      return 50;
    }
    else if (now > stage3Sale && now < endPreSale) {  
      return 40;
    }
    
    else {
      return 0;
    }
  }
  
  function mintManual(address receiver, uint256 _tokens) public backEnd {
    token.mintFromICO(receiver, _tokens);
    soldTokensPreSale = soldTokensPreSale.add(_tokens);
    BuyBackContract.buyTokenICO(receiver, _tokens); 
     
    uint256 tokensTeam = _tokens.mul(5).div(44);  
    token.mintFromICO(team, tokensTeam);
    
    uint256 tokensBoynty = _tokens.div(44);  
    token.mintFromICO(bounty, tokensBoynty);
  }
  
  
  function transferEthFromContract(address _to, uint256 amount) public onlyOwner {
    _to.transfer(amount);
  }
  
  
  function refundPreSale() public {
    require(soldTokensPreSale < softcapPreSale && now > endPreSale);
    uint256 rate = investedEther[msg.sender];
    require(investedEther[msg.sender] >= 0);
    investedEther[msg.sender] = 0;
    msg.sender.transfer(rate);
    weisRaised = weisRaised.sub(rate);
    emit Refund(rate, msg.sender);
  }
}