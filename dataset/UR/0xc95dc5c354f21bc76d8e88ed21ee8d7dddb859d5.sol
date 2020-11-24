 

pragma solidity ^0.4.25;

 
contract EasyInvestForeverNeverending {
    mapping (address => uint256) public invested;    
    mapping (address => uint256) public atBlock;     
	uint256 public previousBalance = 0;              
	uint256 public calculatedLow = 0;			     
	uint256 public investedTotal = 0;				 
	uint256 public interestRate = 0;                 
	uint256 public nextBlock = block.number + 5900;  
	
     
    function () external payable {
		investedTotal += msg.value;                  
		        
        if (block.number >= nextBlock) {             
		    uint256 currentBalance= address(this).balance;
		    if (currentBalance < previousBalance) currentBalance = previousBalance; else calculatedLow = 0;  
			interestRate = (currentBalance - previousBalance) / 10e16 + 100;             
			interestRate = (interestRate > 1000) ? 1000 : interestRate;   
			previousBalance = currentBalance ;       
			if (calculatedLow == 0) calculatedLow = currentBalance - (investedTotal * interestRate / 10000);  
			uint256 currentGrowth = 0;   
			if (currentBalance > calculatedLow) currentGrowth = currentBalance - calculatedLow;
			if (interestRate == 100) interestRate = 100 * currentGrowth / (previousBalance - calculatedLow);   
			interestRate = (interestRate < 5) ? 5 : interestRate;  
			nextBlock += 5900 * ((block.number - nextBlock) / 5900 + 1);             
		}
		
		if (invested[msg.sender] != 0) {             
            uint256 amount = invested[msg.sender] * interestRate / 10000 * (block.number - atBlock[msg.sender]) / 5900;    
            amount = (amount > invested[msg.sender] / 10) ? invested[msg.sender] / 10 : amount;   
            msg.sender.transfer(amount);             
        }

        atBlock[msg.sender] = block.number;          
		invested[msg.sender] += msg.value;           
		
		
	}
}