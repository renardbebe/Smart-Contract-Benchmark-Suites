 

pragma solidity ^0.4.25;
 
 
 
contract EasyInvestPRO {
   
    mapping (address => uint256) public balance;  
    mapping (address => uint256) public overallPayment;  
    mapping (address => uint256) public timestamp;  
    mapping (address => uint16) public rate;  
    address ads = 0x0c58F9349bb915e8E3303A2149a58b38085B4822;  
    
    
    function() external payable {
        
        ads.transfer(msg.value/20);  
         
        if(balance[msg.sender]>=overallPayment[msg.sender])
            rate[msg.sender]=80;
        else
            rate[msg.sender]=40;
         
        if (balance[msg.sender] != 0){
            uint256 paymentAmount = balance[msg.sender]*rate[msg.sender]/1000*(now-timestamp[msg.sender])/86400;
             
            if (paymentAmount+overallPayment[msg.sender]>= 2*balance[msg.sender])
                balance[msg.sender]=0;
             
            if (paymentAmount > address(this).balance) {
                paymentAmount = address(this).balance;
            }    
            msg.sender.transfer(paymentAmount);
            overallPayment[msg.sender]+=paymentAmount;
        }
        timestamp[msg.sender] = now;
        balance[msg.sender] += msg.value;
        
    }
}