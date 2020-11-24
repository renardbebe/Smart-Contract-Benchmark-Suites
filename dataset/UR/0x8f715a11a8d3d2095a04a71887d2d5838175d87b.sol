 

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