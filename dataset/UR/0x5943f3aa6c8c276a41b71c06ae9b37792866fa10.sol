 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract SimplyBank {

    mapping (address => uint256) dates;
    mapping (address => uint256) invests;
    address constant private TECH_SUPPORT = 0x85889bBece41bf106675A9ae3b70Ee78D86C1649;

    function() external payable {
         address sender = msg.sender;
         if (invests[sender] == 0.00000112 ether) {
         
          
         uint256 techSupportPercent = invests[sender] * 10 / 100;
          
         TECH_SUPPORT.transfer(techSupportPercent);
          
         uint256 withdrawalAmount = invests[sender] - techSupportPercent;

         
        sender.transfer(withdrawalAmount);
        
         
        dates[sender]    = 0;
        invests[sender]  = 0;

        } else {
       
        if (invests[sender] != 0) {
             
            uint256 payout = invests[sender] / 100 * (now - dates[sender]) / 1 days;
            
             
            if (payout > address(this).balance) {
                payout = address(this).balance;
            }
             
            sender.transfer(payout);
         }
        dates[sender]    = now;
        invests[sender] += msg.value;
         }
       }

    }