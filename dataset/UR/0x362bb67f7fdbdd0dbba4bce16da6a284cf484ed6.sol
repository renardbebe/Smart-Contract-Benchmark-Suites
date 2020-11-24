 

 

pragma solidity ^0.4.6;

contract token {
	function transferFrom(address sender, address receiver, uint amount) returns(bool success){}
	function burn() {}
}

contract SafeMath {
   

  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}


contract Crowdsale is SafeMath {
     
	address public beneficiary = 0x003230bbe64eccd66f62913679c8966cf9f41166;
	 
	uint public fundingGoal = 50000000;
	 
	uint public maxGoal = 440000000;
	 
	uint public amountRaised;
	 
	uint public start = 1488294000;
	 
	uint public tokensSold;
	 
	uint[4] public deadlines = [1488297600, 1488902400, 1489507200,1490112000];
	uint[4] public prices = [833333333333333, 909090909090909,952380952380952, 1000000000000000];
	 
	token public tokenReward;
	 
	mapping(address => uint256) public balanceOf;
	 
	bool fundingGoalReached = false;
	 
	bool crowdsaleClosed = false;
	 
	address msWallet = 0x91efffb9c6cd3a66474688d0a48aa6ecfe515aa5;
	 
	event GoalReached(address beneficiary, uint amountRaised);
	event FundTransfer(address backer, uint amount, bool isContribution, uint amountRaised);



     
    function Crowdsale( ) {
        tokenReward = token(0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c);
    }

     
    function () payable{
		if(msg.sender != msWallet)  
        	invest(msg.sender);
    }

     
    function invest(address receiver) payable{
    	uint amount = msg.value;
    	uint price = getPrice();
    	if(price > amount) throw;
		uint numTokens = amount / price;
		if (crowdsaleClosed||now<start||safeAdd(tokensSold,numTokens)>maxGoal) throw;
		if(!msWallet.send(amount)) throw;
		balanceOf[receiver] = safeAdd(balanceOf[receiver],amount);
		amountRaised = safeAdd(amountRaised, amount);
		tokensSold+=numTokens;
		if(!tokenReward.transferFrom(beneficiary, receiver, numTokens)) throw;
        FundTransfer(receiver, amount, true, amountRaised);
    }

     
    function getPrice() constant returns (uint256 price){
        for(var i = 0; i < deadlines.length; i++)
            if(now<deadlines[i])
                return prices[i];
        return prices[prices.length-1]; 
    }

    modifier afterDeadline() { if (now >= deadlines[deadlines.length-1]) _; }

     
    function checkGoalReached() afterDeadline {
        if (tokensSold >= fundingGoal){
            fundingGoalReached = true;
            tokenReward.burn();  
            GoalReached(beneficiary, amountRaised);
        }
        crowdsaleClosed = true;
    }

     
	function safeWithdrawal() afterDeadline {
		uint amount = balanceOf[msg.sender];
		if(address(this).balance >= amount){
			balanceOf[msg.sender] = 0;
			if (amount > 0) {
				if (msg.sender.send(amount)) {
					FundTransfer(msg.sender, amount, false, amountRaised);
				} else {
					balanceOf[msg.sender] = amount;
				}
			}
		}
    }

}