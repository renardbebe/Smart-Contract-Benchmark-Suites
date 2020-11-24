 

pragma solidity ^0.4.18;


 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}



 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}




 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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


 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}



contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  event Burn(address sender,uint256 tokencount);

  bool public mintingFinished = false ;
  bool public transferAllowed = false ;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }
 
  
   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  
  function resumeMinting() onlyOwner public returns (bool) {
    mintingFinished = false;
    return true;
  }

  function burn(address _from) external onlyOwner returns (bool success) {
	require(balances[_from] != 0);
    uint256 tokencount = balances[_from];
	 
	balances[_from] = 0;
    totalSupply_ = totalSupply_.sub(tokencount);
    Burn(_from, tokencount);
    return true;
  }


function startTransfer() external onlyOwner
  {
  transferAllowed = true ;
  }
  
  
  function endTransfer() external onlyOwner
  {
  transferAllowed = false ;
  }


function transfer(address _to, uint256 _value) public returns (bool) {
require(transferAllowed);
super.transfer(_to,_value);
return true;
}

function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
require(transferAllowed);
super.transferFrom(_from,_to,_value);
return true;
}


}


  
contract ZebiCoin is MintableToken {
  string public constant name = "Zebi Coin";
  string public constant symbol = "ZCO";
  uint64 public constant decimals = 8;
}




 
contract ZCrowdsale is Ownable{
  using SafeMath for uint256;

   
   MintableToken public token;
   
  uint64 public tokenDecimals;

   
  uint256 public startTime;
  uint256 public endTime;
  uint256 public minTransAmount;
  uint256 public mintedTokensCap;  
  
    
  mapping(address => uint256) contribution;
  
   
  mapping(address => bool) cancelledList;

   
  address public wallet;

  bool public withinRefundPeriod; 
  
   
  uint256 public ETHtoZCOrate;

   
  uint256 public weiRaised;
  
  bool public stopped;
  
   modifier stopInEmergency {
    require (!stopped);
    _;
  }
  
  
  
  modifier inCancelledList {
    require(cancelledList[msg.sender]);
    _;
  }
  
  modifier inRefundPeriod {
  require(withinRefundPeriod);
  _;
 }  

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  
  event TakeEth(address sender,uint256 value);
  
  event Withdraw(uint256 _value);
  
  event SetParticipantStatus(address _participant);
   
  event Refund(address sender,uint256 refundBalance);


  function ZCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _ETHtoZCOrate, address _wallet,uint256 _minTransAmount,uint256 _mintedTokensCap) public {
  
	require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_ETHtoZCOrate > 0);
    require(_wallet != address(0));
	
	token = new ZebiCoin();
	 
    startTime = _startTime;
    endTime = _endTime;
    ETHtoZCOrate = _ETHtoZCOrate;
    wallet = _wallet;
    minTransAmount = _minTransAmount;
	tokenDecimals = 8;
    mintedTokensCap = _mintedTokensCap.mul(10**tokenDecimals);             
	
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }
  
    function finishMint() onlyOwner public returns (bool) {
    token.finishMinting();
    return true;
  }
  
  function resumeMint() onlyOwner public returns (bool) {
    token.resumeMinting();
    return true;
  }
 
 
  function startTransfer() external onlyOwner
  {
  token.startTransfer() ;
  }
  
  
   function endTransfer() external onlyOwner
  {
  token.endTransfer() ;
  }
  
  function transferTokenOwnership(address owner) external onlyOwner
  {
    
	token.transferOwnership(owner);
  }
  
   
  function viewCancelledList(address participant) public view returns(bool){
  return cancelledList[participant];
  
  }  

   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = getTokenAmount(weiAmount);
   
     
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
	contribution[beneficiary] = contribution[beneficiary].add(weiAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

  
   
   
   
   
   

   
   
  function getTokenAmount(uint256 weiAmount) public view returns(uint256) {                      
  
	uint256 ETHtoZweiRate = ETHtoZCOrate.mul(10**tokenDecimals);
    return  SafeMath.div((weiAmount.mul(ETHtoZweiRate)),(1 ether));
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  
  function enableRefundPeriod() external onlyOwner{
  withinRefundPeriod = true;
  }
  
  function disableRefundPeriod() external onlyOwner{
  withinRefundPeriod = false;
  }
  
  
    
  function emergencyStop() external onlyOwner {
    stopped = true;
  }

   
  function release() external onlyOwner {
    stopped = false;
  }

  function viewContribution(address participant) public view returns(uint256){
  return contribution[participant];
  }  
  
  
   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
	 
     
	bool validAmount = msg.value >= minTransAmount;
	bool withinmintedTokensCap = mintedTokensCap >= (token.totalSupply() + getTokenAmount(msg.value));
    return withinPeriod && validAmount && withinmintedTokensCap;
  }
  
   function refund() external inCancelledList inRefundPeriod {                                                    
        require((contribution[msg.sender] > 0) && token.balanceOf(msg.sender)>0);
       uint256 refundBalance = contribution[msg.sender];	   
       contribution[msg.sender] = 0;
		token.burn(msg.sender);
        msg.sender.transfer(refundBalance); 
		Refund(msg.sender,refundBalance);
    } 
	
	function forcedRefund(address _from) external onlyOwner {
	   require(cancelledList[_from]);
	   require((contribution[_from] > 0) && token.balanceOf(_from)>0);
       uint256 refundBalance = contribution[_from];	  
       contribution[_from] = 0;
		token.burn(_from);
        _from.transfer(refundBalance); 
		Refund(_from,refundBalance);
	
	}
	
	
	
	 
    function takeEth() external payable {
		TakeEth(msg.sender,msg.value);
    }
	
	 
     function withdraw(uint256 _value) public onlyOwner {
        wallet.transfer(_value);
		Withdraw(_value);
    }
	 function addCancellation (address _participant) external onlyOwner returns (bool success) {
           cancelledList[_participant] = true;
		   return true;
   } 
}



contract ZebiCoinCrowdsale is ZCrowdsale {

  function ZebiCoinCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet,uint256 _minTransAmount,uint256 _mintedTokensCap)
  ZCrowdsale(_startTime, _endTime, _rate, _wallet , _minTransAmount,_mintedTokensCap){
  }

  
  
  
  
}

contract ZebiCoinTempMgr is Ownable{
  using SafeMath for uint256;

   
  address public wallet;
  
   
  ZebiCoinCrowdsale public preSaleCSSC;
  
   
  ZebiCoin public tsc;
   
   
  uint64 tokenDecimals;
   
   
  mapping(address => bool) preSaleCancelledList;

   
  mapping(address => uint256) noncsAllocations;
  
   
  bool public withinRefundPeriod; 
  
   
  mapping(address => uint256)  preSaleRefunds;
  
  
  
  modifier inPreSaleCancelledList {
    require(preSaleCancelledList[msg.sender]);
    _;
  }
  
  modifier inRefundPeriod {
  require(withinRefundPeriod);
  _;
 }
 
 
  event TakeEth(address sender,uint256 value);
  event Withdraw(uint256 _value);
  event PreSaleRefund(address sender,uint256 refundBalance);
  event AllocatenonCSTokens(address indexed beneficiary,uint256 amount);

  
  function ZebiCoinTempMgr(address presaleCrowdsale, address tokenAddress, address _wallet) public {
 
    wallet = _wallet;
    preSaleCSSC = ZebiCoinCrowdsale(presaleCrowdsale);
	tsc = ZebiCoin(tokenAddress);
    tokenDecimals = tsc.decimals();
  }
  
  function finishMint() onlyOwner public returns (bool) {
    tsc.finishMinting();
    return true;
  }
  
  function resumeMint() onlyOwner public returns (bool) {
    tsc.resumeMinting();
    return true;
  }
 
 
  function startTransfer() external onlyOwner{
    tsc.startTransfer() ;
  }
  
  function endTransfer() external onlyOwner{
    tsc.endTransfer() ;
  }
  
  function transferTokenOwnership(address owner) external onlyOwner{
    tsc.transferOwnership(owner);
  }
  
  function allocatenonCSTokens(address beneficiary,uint256 tokens) external onlyOwner
  {
	require(beneficiary != address(0));
	uint256 Zweitokens = tokens.mul(10**(tokenDecimals ));
	noncsAllocations[beneficiary]= Zweitokens.add(noncsAllocations[beneficiary]);
	tsc.mint(beneficiary, Zweitokens);
	AllocatenonCSTokens(beneficiary,Zweitokens);
  }
	
  function revertNoncsallocation(address beneficiary) external onlyOwner
  {
	require(noncsAllocations[beneficiary]!=0);
	noncsAllocations[beneficiary]=0;
	tsc.burn(beneficiary);
  }
 
  function viewNoncsallocations(address participant) public view returns(uint256){
    return noncsAllocations[participant];
  }
  
  function viewPreSaleCancelledList(address participant) public view returns(bool){
    return preSaleCancelledList[participant];
  } 
  
  function viewPreSaleRefunds(address participant) public view returns(uint256){
    return preSaleRefunds[participant];
  } 
  
  function enableRefundPeriod() external onlyOwner{
    withinRefundPeriod = true;
  }
  
  function disableRefundPeriod() external onlyOwner{
    withinRefundPeriod = false;
  }
  
  function refund() external inPreSaleCancelledList inRefundPeriod {                                                    
    require((preSaleCSSC.viewContribution(msg.sender) > 0) && tsc.balanceOf(msg.sender)>0);
    uint256 refundBalance = preSaleCSSC.viewContribution(msg.sender);	   
    preSaleRefunds[msg.sender] = refundBalance;
    tsc.burn(msg.sender);
    msg.sender.transfer(refundBalance); 
	PreSaleRefund(msg.sender,refundBalance);
  } 
	
  function forcedRefund(address _from) external onlyOwner {
	require(preSaleCancelledList[_from]);
	require((preSaleCSSC.viewContribution(_from) > 0) && tsc.balanceOf(_from)>0);
    uint256 refundBalance = preSaleCSSC.viewContribution(_from);	  
    preSaleRefunds[_from] = refundBalance;
	tsc.burn(_from);
    _from.transfer(refundBalance); 
	PreSaleRefund(_from,refundBalance);
  }
  
   
  function takeEth() external payable {
	TakeEth(msg.sender,msg.value);
  }
	
   
  function withdraw(uint256 _value) public onlyOwner {
    wallet.transfer(_value);
	Withdraw(_value);
  }
	
  function addCancellation (address _participant) external onlyOwner returns (bool success) {
    preSaleCancelledList[_participant] = true;
	return true;
  }
  
}



 
contract ZebiMainCrowdsale is Ownable{
 
  using SafeMath for uint256;

   
  ZebiCoin public token;
  
   
   
  
   
  uint256 currentYearMinted;
  
   
  uint256 calenderYearMintCap;
   
  uint256 calenderYearStart;
  
   
  uint256 calenderYearEnd;
  
   
  uint256 vestedMintStartTime;
  
  
   
   
  
   
  uint256 zebiZCOShare;
   
  uint256 crowdsaleZCOCap;
  
   
  uint256 transStartTime;
  
   
  ZebiCoinCrowdsale public zcc;
  
   
  ZebiCoinTempMgr public tempMngr;
   
   
  uint64 public tokenDecimals;

   
  uint256 public startTime;
  uint256 public endTime;
   
  uint256 public goldListPeriod;
  
   
  uint256 public postGoldPeriod;
  
   
  uint256 public minTransAmount;
  
   
  uint256 public ethCap; 
  
   
  mapping(address => uint256) mainContribution;
    
   
  mapping(address => bool) mainCancelledList;
  
   
  uint256 goldPeriodCap;
  
   
  bool goldListPeriodFlag;
  
   
  mapping(address=>uint256) goldListContribution;
   
  mapping(address => bool) goldList;
   
   
  
   
  mapping(address => bool) kycAcceptedList;
   
  address public wallet;

  bool public withinRefundPeriod; 
  
   
  mapping(address => uint256)  preSaleRefundsInMainSale;
  
  
  uint256 public tokens;
  
   
  uint256 public weiAmount;
  
   
  uint256 public ETHtoZWeirate;

   
  uint256 public mainWeiRaised;  
  
   
  
  modifier inCancelledList {
    require(mainCancelledList[msg.sender]);
    _;
  }
  
  modifier inRefundPeriod {
  require(withinRefundPeriod);
  _;
  }  


  event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
  
  event TakeEth(address sender,uint256 value);
  
  event Withdraw(uint256 _value);
  
  event SetParticipantStatus(address _participant);
   
  event Refund(address sender,uint256 refundBalance);


  function ZebiMainCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _ETHtoZWeirate, address _wallet,uint256 _minTransAmount,uint256 _ethCap, address tokenAddress, address presaleAddress,address tempMngrAddress,uint256 _goldListPeriod,uint256 _postGoldPeriod,uint256 _goldPeriodCap,uint256 _vestedMintStartTime,uint256 _calenderYearStart) public {
  
	require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_ETHtoZWeirate > 0);
    require(_wallet != address(0));
	
	token = ZebiCoin(tokenAddress);	
	zcc = ZebiCoinCrowdsale(presaleAddress);
    startTime = _startTime;
    endTime = _endTime;
    ETHtoZWeirate = _ETHtoZWeirate;
    wallet = _wallet;
    minTransAmount = _minTransAmount;
	tokenDecimals = token.decimals();
    ethCap = _ethCap;       
	tempMngr=ZebiCoinTempMgr(tempMngrAddress);
	goldListPeriod=_goldListPeriod;
	postGoldPeriod=_postGoldPeriod;
	zebiZCOShare=SafeMath.mul(500000000,(10**tokenDecimals));
	crowdsaleZCOCap=zebiZCOShare;
	goldPeriodCap=_goldPeriodCap;
	calenderYearMintCap = SafeMath.div((zebiZCOShare.mul(2)),8);
	 
	 
	vestedMintStartTime=_vestedMintStartTime;
	 
	calenderYearStart=_calenderYearStart;
	 
	calenderYearEnd=(calenderYearStart+1 years )- 1;
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }
  
  function finishMint() onlyOwner public returns (bool) {
    token.finishMinting();
    return true;
  }
  
  function resumeMint() onlyOwner public returns (bool) {
    token.resumeMinting();
    return true;
  }
 
  function startTransfer() external onlyOwner{
    token.startTransfer() ;
  }
  
  function endTransfer() external onlyOwner{
    token.endTransfer() ;
  }
  
  function transferTokenOwnership(address owner) external onlyOwner{
    token.transferOwnership(owner);
  }
  
  function viewCancelledList(address participant) public view returns(bool){
    return mainCancelledList[participant];
  } 
  
  function viewGoldList(address participant) public view returns(bool){
    return goldList[participant];
  }
  function addToGoldList (address _participant) external onlyOwner returns (bool ) {
    goldList[_participant] = true;
	return true;
  }
  function removeFromGoldList(address _participant) external onlyOwner returns(bool ){
      goldList[_participant]=false;
      return true;
  }
  function viewKYCAccepted(address participant) public view returns(bool){
    return kycAcceptedList[participant];
  }
  function addToKYCList (address _participant) external onlyOwner returns (bool ) {
    kycAcceptedList[_participant] = true;
	return true;
  }
  function removeFromKYCList (address _participant) external onlyOwner returns (bool){
      kycAcceptedList[_participant]=false;
  }
  function viewPreSaleRefundsInMainSale(address participant) public view returns(uint256){
    return preSaleRefundsInMainSale[participant];
  }
   

   
  function buyTokens(address beneficiary) public payable {
    transStartTime=now;
    require(goldList[beneficiary]||kycAcceptedList[beneficiary]);
    goldListPeriodFlag=false;
	require(beneficiary != address(0));
    require(validPurchase());
    uint256 extraEth=0;
    weiAmount = msg.value;
    
    
     
    if((msg.value>ethCap.sub(mainWeiRaised)) && !goldListPeriodFlag){
		weiAmount=ethCap.sub(mainWeiRaised);
		extraEth=(msg.value).sub(weiAmount);
	 }
	 
     
     tokens = getTokenAmount(weiAmount);
   
     
    mainWeiRaised = mainWeiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
	mainContribution[beneficiary] = mainContribution[beneficiary].add(weiAmount);
	if(goldListPeriodFlag){
	    goldListContribution[beneficiary] = goldListContribution[beneficiary].add(weiAmount);
	}
	
     
    TokenPurchase(beneficiary, weiAmount, tokens);

    forwardFunds();
    if(extraEth>0){
        beneficiary.transfer(extraEth);
    }
    
 
  }


   
  
  function getTokenAmount(uint256 weiAmount1) public view returns(uint256) {                      
    
	 
    uint256 number = SafeMath.div((weiAmount1.mul(ETHtoZWeirate)),(1 ether));
	uint256 volumeBonus;
	uint256 timeBonus;
	if(number >= 400000000000000)
	{
	volumeBonus = SafeMath.div((number.mul(25)),100);
	}
	else if(number>= 150000000000000) {
	volumeBonus = SafeMath.div((number.mul(20)),100);
	    }
	else if(number>= 80000000000000) {
	volumeBonus = SafeMath.div((number.mul(15)),100);
	    }
	else if(number>= 40000000000000) {
	volumeBonus = SafeMath.div((number.mul(10)),100);
	    }
	else if(number>= 7500000000000) {
	volumeBonus = SafeMath.div((number.mul(5)),100);
	    }
	 else{
	     volumeBonus=0;
	 }
	 
	if(goldListPeriodFlag){
	    timeBonus = SafeMath.div((number.mul(15)),100);
	}
	else if(transStartTime <= startTime + postGoldPeriod){
	    timeBonus = SafeMath.div((number.mul(10)),100);
	}
	else{
	    timeBonus=0;
	}
    number=number+timeBonus+volumeBonus;
    return number; 
	
  }
	
	
	
   
  function forwardFunds() internal {
    wallet.transfer(weiAmount);
  }

  
  function enableRefundPeriod() external onlyOwner{
    withinRefundPeriod = true;
  }
  
  function disableRefundPeriod() external onlyOwner{
    withinRefundPeriod = false;
  }
 
  function viewContribution(address participant) public view returns(uint256){
    return mainContribution[participant];
  }  
  
  
   
  
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = transStartTime >= startTime && transStartTime <= endTime;
	bool validAmount = msg.value >= minTransAmount;
	 
	bool withinEthCap = ((ethCap.sub(mainWeiRaised))>0);
	bool goldPeriodValid=true;
	if(transStartTime <= (startTime + goldListPeriod)){
	    goldPeriodValid=(goldList[msg.sender])&&(goldListContribution[msg.sender]+msg.value <= goldPeriodCap);
	    goldListPeriodFlag=true;
	    
	}
    return withinPeriod && validAmount && withinEthCap && goldPeriodValid;
  }
  
   
  function mintAndAllocateZCO(address partnerAddress,uint256 amountInZWei) external onlyOwner returns(bool){
      require((crowdsaleZCOCap.sub(token.totalSupply()))>=amountInZWei);
      require(partnerAddress!=address(0));
       
       
      token.mint(partnerAddress,amountInZWei);
      return true;
  }
  
  function mintvestedTokens (address partnerAddress,uint256 zweitokens) external onlyOwner returns(bool){
      require(zweitokens<=zebiZCOShare && zweitokens>0);
      
      require(partnerAddress!=address(0));
      require(now>=vestedMintStartTime);
       
      uint256 currentYearCounter=SafeMath.div((SafeMath.sub(now,calenderYearStart)),1 years);
       
      if(now>calenderYearEnd && currentYearCounter>=1){
           
          currentYearMinted=0;
          calenderYearStart=calenderYearEnd+((currentYearCounter-1)*1 years) +1;
          calenderYearEnd=(calenderYearStart+ 1 years )- 1;
      }
      
      require(currentYearMinted+zweitokens<=calenderYearMintCap);
      currentYearMinted=currentYearMinted+zweitokens;
      token.mint(partnerAddress,zweitokens);
      zebiZCOShare=zebiZCOShare.sub(zweitokens);
  }
  
  
  
  function refund() external inCancelledList inRefundPeriod {  
    require(mainCancelledList[msg.sender]);  
    require((mainContribution[msg.sender] > 0) && token.balanceOf(msg.sender)>0);
	uint256 presaleContribution = zcc.viewContribution(msg.sender);
    uint256 refundBalance = (mainContribution[msg.sender]).add(presaleContribution) ;
    uint256 preSaleRefundTemp= tempMngr.viewPreSaleRefunds(msg.sender);
    uint256 preSaleRefundMain=presaleContribution.sub(preSaleRefundTemp);
    refundBalance=refundBalance.sub(preSaleRefundTemp);
    refundBalance=refundBalance.sub(preSaleRefundsInMainSale[msg.sender]);
    preSaleRefundsInMainSale[msg.sender]=preSaleRefundMain;
    
    mainContribution[msg.sender] = 0;
	token.burn(msg.sender);
    msg.sender.transfer(refundBalance); 
	Refund(msg.sender,refundBalance);
  } 
	
  function forcedRefund(address _from) external onlyOwner {
	require(mainCancelledList[_from]);
	require((mainContribution[_from] > 0) && token.balanceOf(_from)>0);
	uint256 presaleContribution = zcc.viewContribution(_from);
    uint256 refundBalance = (mainContribution[_from]).add(presaleContribution) ;
    uint256 preSaleRefundTemp= tempMngr.viewPreSaleRefunds(_from);
    uint256 preSaleRefundMain=presaleContribution.sub(preSaleRefundTemp);
    refundBalance=refundBalance.sub(preSaleRefundTemp);
    refundBalance=refundBalance.sub(preSaleRefundsInMainSale[_from]);
    preSaleRefundsInMainSale[_from]=preSaleRefundMain;
    mainContribution[_from] = 0;
	token.burn(_from);
    _from.transfer(refundBalance); 
	Refund(_from,refundBalance);
  }
	
	
   
  function takeEth() external payable {
	TakeEth(msg.sender,msg.value);
  }
	
   
  function withdraw(uint256 _value) public onlyOwner {
    wallet.transfer(_value);
	Withdraw(_value);
  }
	
   
  function addCancellation (address _participant) external onlyOwner returns (bool success) {
    mainCancelledList[_participant] = true;
	return true;
  } 

  }