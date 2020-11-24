 

pragma solidity ^0.4.18;

 
contract Token {
	function SetupToken(string tokenName, string tokenSymbol, uint256 tokenSupply) public;
    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _amount) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);
    function approve(address _spender, uint256 _amount) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
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


 
 
 
contract WinkIfYouLikeIt {
  using SafeMath for uint256;

  Token token;
  address public owner;
  
   
  uint256 public cap;
  
   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  
  
   
  uint256 public tierTotal;
  
   
  uint256 public tierNum = 0;
  
   
  uint256[5] fundingRate = [24000, 24000, 24000, 24000, 24000];  
  uint256[5] fundingLimit = [180000000, 180000000, 180000000, 180000000, 180000000];  

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FailedTransfer(address indexed to, uint256 value);
  event initialCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _cap, uint256 cap, uint256 _rate, uint256 rate, address _wallet);

  function WinkIfYouLikeIt(uint256 _startTime, uint256 _endTime, uint256 _cap, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_cap > 0);
    require(_wallet != address(0));
    
    owner = msg.sender;
    address _tokenAddr = 0x29fA00dCF17689c8654d07780F9E222311D6Bf0c;  
    token = Token(_tokenAddr);
      
    startTime = _startTime;
    endTime = _endTime;
    rate =  fundingRate[tierNum];  
    cap = _cap.mul(1 ether);  
    wallet = _wallet;
    
    initialCrowdsale(_startTime, _endTime, _cap, cap, fundingRate[tierNum], rate, _wallet);

  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);
    tierTotal = tierTotal.add(weiAmount);

     
    token.transfer(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    
    forwardFunds();
    
     
    rateUpgrade(tierTotal);
  }

   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    bool timeLimit = now > endTime;
    return capReached || timeLimit;
  }


   
  function rateUpgrade(uint256 tierAmount) internal {
    uint256 tierEthLimit  = fundingLimit[tierNum].div(fundingRate[tierNum]);
    uint256 tierWeiLimit  = tierEthLimit.mul(1 ether);
    if(tierAmount >= tierWeiLimit) {
        tierNum = tierNum.add(1);  
        rate = fundingRate[tierNum];  
        tierTotal = 0;  
    }
 }
   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
        return weiAmount.mul(rate);
  }

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && withinCap && nonZeroPurchase;
  }
  
  function tokensAvailable() public onlyOwner constant returns (uint256) {
    return token.balanceOf(this);
  }
  
  
  function getRate() public onlyOwner constant returns(uint256) {
    return rate;
  }

  function getWallet() public onlyOwner constant returns(address) {
    return wallet;
  }
  
  function destroy() public onlyOwner payable {
    uint256 balance = tokensAvailable();
    if(balance > 0) {
    token.transfer(owner, balance);
    }
    selfdestruct(owner);
  }
  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}