 

pragma solidity ^0.4.25;


 

contract HodlETH {
     
    mapping (address => uint) public userInvested;
     
    mapping (address => uint) public entryTime;
     
    mapping (address => uint) public withdrawnAmount;
     
    mapping (address => uint) public referrerOn;
     
    address public advertisingFund = 0x01429d58058B3e84F6f264D91254EA3a96E1d2B7; 
    uint public advertisingPercent = 6;
	 
	address techSupportFund = 0x0D5dB78b35ecbdD22ffeA91B46a6EC77dC09EA4a;		
	uint public techSupportPercent = 2;
	 
    uint public startPercent = 25;			 
	uint public fiveDayHodlPercent = 30;	 
    uint public tenDayHodlPercent = 35;		 
	uint public twentyDayHodlPercent = 45;	 
	 
	uint public lowBalance = 500 ether;
	uint public middleBalance = 2000 ether;
	uint public highBalance = 3500 ether;
    uint public soLowBalanceBonus = 5;		 
	uint public lowBalanceBonus = 10;		 
	uint public middleBalanceBonus = 15;	 
	uint public highBalanceBonus = 20;		 
	
	
    
     
    function bonusPercent() public view returns(uint){
        
        uint balance = address(this).balance;
        
        if (balance < lowBalance){
            return (soLowBalanceBonus);		 
        } 
        if (balance > lowBalance && balance < middleBalance){
            return (lowBalanceBonus); 		 
        } 
        if (balance > middleBalance && balance < highBalance){
            return (middleBalanceBonus); 	 
        }
        if (balance > highBalance){
            return (highBalanceBonus);		 
        }
        
    }
     
    function personalPercent() public view returns(uint){
        
        uint hodl = block.number - entryTime[msg.sender]; 
		 
         if (hodl < 30500){
            return (startPercent);			 
        }
		if (hodl > 30500 && hodl < 61000){
            return (fiveDayHodlPercent);	 
        }
        if (hodl > 61000 && hodl < 122000){
            return (tenDayHodlPercent);		 
        }
		if (hodl > 122000){
            return (twentyDayHodlPercent);	 
        }
        
        
    }
    
     
    function() external payable {
        if (msg.value == 0.00000911 ether) {
            returnInvestment();
        } 
		else {
            invest();
        }
    }    
    
    
    function returnInvestment() timeWithdrawn private{
        if(userInvested[msg.sender] > 0){
            uint refundAmount = userInvested[msg.sender] - withdrawnAmount[msg.sender] - (userInvested[msg.sender] / 10);
            require(userInvested[msg.sender] > refundAmount, 'You have already returned the investment');
			userInvested[msg.sender] = 0;
            entryTime[msg.sender] = 0;
            withdrawnAmount[msg.sender] = 0;
            msg.sender.transfer(refundAmount);
        }
    }
     
    function invest() timeWithdrawn maxInvested  private {
        if (msg.value > 0 ){
			 
			terminal();
			 
			userInvested[msg.sender] += msg.value;
			 
			advertisingFund.transfer(msg.value * advertisingPercent / 100);
			techSupportFund.transfer(msg.value * techSupportPercent / 100);
        
			 
			if (msg.data.length != 0 && referrerOn[msg.sender] != 1){
				 
				transferRefBonus();
			}
        } else{
			 
            terminal();
        }
    }
    
    function terminal() internal {
         
        if (userInvested[msg.sender] * 15 / 10 < withdrawnAmount[msg.sender]){
            userInvested[msg.sender] = 0;
            entryTime[msg.sender] = 0;
            withdrawnAmount[msg.sender] = 0;
            referrerOn[msg.sender] = 0; 
        } else {
             
            uint percent = bonusPercent() + personalPercent();
             
             
             
            uint amount = userInvested[msg.sender] * percent / 1000 * ((block.number - entryTime[msg.sender]) / 6100);
             
            entryTime[msg.sender] = block.number;
             
            withdrawnAmount[msg.sender] += amount;
             
            msg.sender.transfer(amount);
        }
        
    }
    
     
	function bytesToAddress(bytes bys) private pure returns (address addr) {
		assembly {
            addr := mload(add(bys, 20))
        }
	}
	 
    function transferRefBonus() private {        
        address referrer = bytesToAddress(msg.data);
        if (referrer != msg.sender && userInvested[referrer] != 0){
        referrerOn[msg.sender] = 1;
        uint refBonus = msg.value * 20 / 1000;
        referrer.transfer(refBonus);    
        }
    }
    
    modifier timeWithdrawn(){
        require(entryTime[msg.sender] + 3050 < block.number, 'Withdraw and deposit no more 1 time per 12 hour');
        _;
    }
    
    
    modifier maxInvested(){
        require(msg.value <= 25 ether, 'Max invested 25 ETH per 12 hours');
        _;
    }

}