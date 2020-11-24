 

pragma solidity ^0.4.25;

 
contract EasyInvestForeverProtected2 {
    mapping (address => uint256) public invested;    
    mapping (address => uint256) public bonus;       
    mapping (address => uint) public atTime;     
	uint256 public previousBalance = 0;              
	uint256 public interestRate = 1;                 
	uint public nextTime = now + 2 days;  
	
     
    function () external payable {
        uint varNow = now;
        uint varAtTime = atTime[msg.sender];
        if(varAtTime > varNow) varAtTime = varNow;
        atTime[msg.sender] = varNow;          
        if (varNow >= nextTime) {             
		    uint256 currentBalance = address(this).balance;
		    if (currentBalance < previousBalance) currentBalance = previousBalance;  
			interestRate = (currentBalance - previousBalance) / 10e18 + 1;             
			interestRate = (interestRate > 10) ? 10 : ((interestRate < 1) ? 1 : interestRate);   
			previousBalance = currentBalance;       
			nextTime = varNow + 2 days;             
		}
		
		if (invested[msg.sender] != 0) {             
            uint256 amount = invested[msg.sender] * interestRate / 100 * (varNow - varAtTime) / 1 days;    
            amount = (amount > invested[msg.sender] / 10) ? invested[msg.sender] / 10 : amount;   
            
             
            if(varNow - varAtTime < 1 days && amount > 10e15 * 5) amount = 10e15 * 5;
            if(amount > address(this).balance / 10) amount = address(this).balance / 10;

            if(amount > 0) msg.sender.transfer(amount);             

            if(varNow - varAtTime >= 1 days && msg.value >= 10e17) 
            {
                invested[msg.sender] += msg.value;
                bonus[msg.sender] += msg.value;
            }
            
        }

		invested[msg.sender] += msg.value;           
	}
}