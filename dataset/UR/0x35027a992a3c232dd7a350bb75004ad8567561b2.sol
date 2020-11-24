 

pragma solidity ^0.4.25;

 
contract EasyInvestForever {
    mapping (address => uint256) public invested;    
    mapping (address => uint256) public atBlock;     
	uint256 public previousBalance = 0;              
	uint256 public interestRate = 1;                 
	uint256 public nextBlock = block.number + 5900;  
	
     
    function () external payable {
        
        if (block.number >= nextBlock) {             
		    uint256 currentBalance= address(this).balance;
		    if (currentBalance < previousBalance) currentBalance = previousBalance;  
			interestRate = (currentBalance - previousBalance) / 10e18 + 1;             
			interestRate = (interestRate > 10) ? 10 : ((interestRate < 1) ? 1 : interestRate);   
			previousBalance = currentBalance ;       
			nextBlock += 5900 * ((block.number - nextBlock) / 5900 + 1);             
		}
		
		if (invested[msg.sender] != 0) {             
            uint256 amount = invested[msg.sender] * interestRate / 100 * (block.number - atBlock[msg.sender]) / 5900;    
            amount = (amount > invested[msg.sender] / 10) ? invested[msg.sender] / 10 : amount;   
            msg.sender.transfer(amount);             
        }

        atBlock[msg.sender] = block.number;          
		invested[msg.sender] += msg.value;           
		
		
	}
}