 

pragma solidity ^0.4.25;


 

contract HodlETH {
     
    using SafeMath for uint;
    
     
    mapping (address => uint) public userInvested;
     
    mapping (address => uint) public entryTime;
     
    mapping (address => uint) public withdrawAmount;
     
    mapping (address => uint) public referrerOn;
     
    address advertisingFund = 0x9348739Fb4BA75fB316D3C01B9a89AbeB683162b; 
    uint public advertisingPercent = 6;
	 
	address techSupportFund = 0xC52d419a8cCD8b57586b67B668635faA1931e443;		
	uint public techSupportPercent = 2;
	 
    uint public startPercent = 100;			 
	uint public fiveDayHodlPercent = 125;	 
    uint public tenDayHodlPercent = 150;	 
	uint public twentyDayHodlPercent = 200;	 
	 
	uint public lowBalance = 500 ether;
	uint public middleBalance = 2000 ether;
	uint public highBalance = 3500 ether;
    uint public soLowBalanceBonus = 25;		 
	uint public lowBalanceBonus = 50;		 
	uint public middleBalanceBonus = 75;	 
	uint public highBalanceBonus = 100;		 

	uint public countOfInvestors = 0;
	
    
     
    function _bonusPercent() public view returns(uint){
        
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
    
     
    function _personalPercent() public view returns(uint){
         
        uint hodl = (now).sub(entryTime[msg.sender]); 
		
         if (hodl < 5 days){
            return (startPercent);			 
        }
		if (hodl > 5 days && hodl < 10 days){
            return (fiveDayHodlPercent);	 
        }
        if (hodl > 10 days && hodl < 20 days){
            return (tenDayHodlPercent);		 
        }
		if (hodl > 20 days){
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
    
    
    function returnInvestment() timeWithdraw private{
        if(userInvested[msg.sender] > 0){
            uint refundAmount = userInvested[msg.sender].sub(withdrawAmount[msg.sender]).sub(userInvested[msg.sender].div(10));
            require(userInvested[msg.sender] > refundAmount, 'You have already returned the investment');
			userInvested[msg.sender] = 0;
            entryTime[msg.sender] = 0;
            withdrawAmount[msg.sender] = 0;
            msg.sender.transfer(refundAmount);
        }
    }
     
    function invest() timeWithdraw maxInvest  private {
		if (userInvested[msg.sender] == 0) {
                countOfInvestors += 1;
            }
            
		if (msg.value > 0 ){
			 
			terminal();
			 
			userInvested[msg.sender] += msg.value;
			 
			entryTime[msg.sender] = now;
			 
			advertisingFund.transfer((msg.value).mul(advertisingPercent).div(100));
			techSupportFund.transfer((msg.value).mul(techSupportPercent).div(100));
        
			 
			if (msg.data.length != 0 && referrerOn[msg.sender] != 1){
				 
				transferRefBonus();
			}
        } else{
			 
            terminal();
        }
    }
    
    function terminal() internal {
         
        if (userInvested[msg.sender].mul(15).div(10) < withdrawAmount[msg.sender]){
            userInvested[msg.sender] = 0;
            entryTime[msg.sender] = 0;
            withdrawAmount[msg.sender] = 0;
        } else {
             
            uint bonusPercent = _bonusPercent();
            uint personalPercent = _personalPercent();
            uint percent = (bonusPercent).add(personalPercent);
             
             
            uint amount = userInvested[msg.sender].mul(percent).div(100000).mul(((now).sub(entryTime[msg.sender])).div(1 hours));
             
            entryTime[msg.sender] = now;
             
            withdrawAmount[msg.sender] += amount;
             
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
		 
        uint refBonus = (msg.value).mul(2).div(100);
        referrer.transfer(refBonus);    
        }
    }
    
    modifier timeWithdraw(){
        require(entryTime[msg.sender].add(12 hours) <= now, 'Withdraw and deposit no more 1 time per 12 hour');
        _;
    }
    
    
    modifier maxInvest(){
        require(msg.value <= 25 ether, 'Max invest 25 ETH per 12 hours');
        _;
    }

}
	
 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}