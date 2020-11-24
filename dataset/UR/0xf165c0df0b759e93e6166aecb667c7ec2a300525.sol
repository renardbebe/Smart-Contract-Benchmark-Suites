 

pragma solidity ^0.4.13;
 
contract tokenGAT {
        
        uint256 public totalContribution = 0;
        uint256 public totalBonusTokensIssued = 0;
        uint256 public totalSupply = 0;
        function balanceOf(address _owner) constant returns (uint256 balance);
        function transfer(address _to, uint256 _value) returns (bool success);
        function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
        function approve(address _spender, uint256 _value) returns (bool success);
        function allowance(address _owner, address _spender) constant returns (uint256 remaining);
         
        event LogTransaction(address indexed _addres, uint256 value);
        event Transfer(address indexed _from, address indexed _to, uint256 _value);
        event Approval(address indexed _owner, address indexed _spender, uint256 _value);
        }

 
contract StandarTokentokenGAT is tokenGAT{
mapping (address => uint256) balances;  
mapping (address => uint256 ) weirecives;  
mapping (address => mapping (address => uint256)) allowed;  

	
function allowance(address _owner, address _spender) constant returns (uint256) {
    	return allowed[_owner][_spender];
}

function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
}
	
function transfer(address _to, uint256 _value) returns (bool success) { 
   	if(msg.data.length < (2 * 32) + 4) { revert();} 	 
    if (balances[msg.sender] >= _value && _value >= 0){ 
		balances[msg.sender] -= _value;  
		balances[_to] += _value;   
		Transfer(msg.sender, _to, _value);     
       	return true;
     }else
   		return false;
     }
	
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
     	if(msg.data.length < (3 * 32) + 4) { revert(); }  
       if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value >= 0){		
          
          balances[_to] += _value;
		    
        	balances[_from] -= _value;        	
        	allowed[_from][msg.sender] -= _value;
		    
        	Transfer(_from, _to, _value);
        	return true;
    	} else 
  			return false;
	}
 
 function approve(address _spender, uint256 _value) returns (bool success) {
    
	if (_value != 0 && allowed[msg.sender][_spender] != 0) { return false; }    	
   	allowed[msg.sender][_spender] = _value;    	
    	Approval(msg.sender, _spender, _value);
    	return true;
	}
}

contract TokenICOGAT is StandarTokentokenGAT{	
	
	address owner = msg.sender;
	
	 
	function name() constant returns (string) { return "General Advertising Token"; }
	function symbol() constant returns (string) { return "GAT"; }
	uint256 public constant decimals = 18;
	
     
	bool public purchasingAllowed = false;	
	address public ethFoundDeposit;       
	address public gatFoundDeposit;       
 	uint public deadline; 	 
 	uint public startline; 	 
	uint public refundDeadLine;	 
	uint public transactionCounter; 
 	uint public etherReceived;  
 	uint256 public constant gatFund = 250 * (10**6) * 10**decimals;    
 	uint256 public constant tokenExchangeRate = 9000;  
 	uint256 public constant tokenCreationCap =  1000 * (10**6) * 10**decimals;  
 	uint256 public constant tokenSellCap =  750 * (10**6) * 10**decimals;  
	uint256 public constant tokenSaleMin =  17 * (10**6) * 10**decimals;  
 
   
 function TokenICOGAT(){
  startline = now;
  deadline = startline + 45 * 1 days;
  refundDeadLine = deadline + 30 days;
  ethFoundDeposit = owner;
  gatFoundDeposit = owner;   	 
  balances[gatFoundDeposit] = gatFund;  
  LogTransaction(gatFoundDeposit,gatFund);  
 }
  
 function bonusCalculate(uint256 amount) internal returns(uint256){
 	uint256 amounttmp = 0;
	if (transactionCounter > 0 && transactionCounter <= 1000){
    	return  amount / 2   ;    
	}
	if (transactionCounter > 1000 && transactionCounter <= 2000){
    return	 amount / 5 ;    
	}
	if (transactionCounter > 2000 && transactionCounter <= 3000){
     return	amount / 10;    
	}
	if (transactionCounter > 3000 && transactionCounter <= 5000){
     return	amount / 20;    
	}
 	return amounttmp;
	}	  
	
	function enablePurchasing() {
   	if (msg.sender != owner) { revert(); }
		if(purchasingAllowed) {revert();}
		purchasingAllowed = true;	
   	}
	
	function disablePurchasing() {
    	if (msg.sender != owner) { revert(); }
	if(!purchasingAllowed) {revert();}		
    	purchasingAllowed = false;		
	}
	
    function getStats() constant returns (uint256, uint256, uint256, bool) {
    	return (totalContribution, totalSupply, totalBonusTokensIssued, purchasingAllowed);
	}
		
	 
	function() payable {
    	if (!purchasingAllowed) { revert(); }   
        if ((tokenCreationCap - (totalSupply + gatFund)) <= 0) { revert();}  
    	if (msg.value == 0) { return; }
	transactionCounter +=1;
    	totalContribution += msg.value;
    	uint256 bonusGiven = bonusCalculate(msg.value);
         
    	uint256 tokensIssued = (msg.value * tokenExchangeRate) + (bonusGiven * tokenExchangeRate);
    	totalBonusTokensIssued += bonusGiven;
    	totalSupply += tokensIssued;
    	balances[msg.sender] += tokensIssued;  
	weirecives[msg.sender] += msg.value;  
    	Transfer(address(this), msg.sender, tokensIssued);
   }
		
      
	 
	function sendSurplusTokens() {
    	if (purchasingAllowed) { revert(); } 	
     	if (msg.sender != owner) { revert();}
    	uint256 excess = tokenCreationCap - (totalSupply + gatFund);
	if(excess <= 0){revert();}
    	balances[gatFoundDeposit] += excess;  	
    	Transfer(address(this), gatFoundDeposit, excess);
   }
	
	function withdrawEtherHomeExternal() external{ 
		if(purchasingAllowed){revert();}
		if (msg.sender != owner) { revert();}
		ethFoundDeposit.transfer(this.balance);  
	}
	
	function withdrawEtherHomeLocal(address _ethHome) external{  
		if(purchasingAllowed){revert();}
		if (msg.sender != owner) { revert();}
		_ethHome.transfer(this.balance);  
	}
	
	 
	function refund() public {
	if(purchasingAllowed){revert();}  
	if(now >= refundDeadLine ){revert();}  
	if((totalSupply - totalBonusTokensIssued) >= tokenSaleMin){revert();}  
	if(msg.sender == ethFoundDeposit){revert();}	 
	uint256 gatVal= balances[msg.sender];  
	if(gatVal <=0) {revert();}  
	 
        uint256 ethVal = weirecives[msg.sender];  
	LogTransaction(msg.sender,ethVal); 
	msg.sender.transfer(ethVal); 
        totalContribution -= ethVal;
        weirecives[msg.sender] -= ethVal;  
	}
}