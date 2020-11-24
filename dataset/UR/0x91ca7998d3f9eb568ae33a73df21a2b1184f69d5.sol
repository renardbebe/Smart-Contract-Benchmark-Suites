 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract CryptoBank {
     
    mapping (address => uint) invested;
    mapping (address => uint) dates;
    
     
    address constant public techSupport = 0x93aF2363A905Ec2fF6A2AC6d3AcF69A4c8370044;
    uint constant public techSupportPercent = 10;
   


     
    function () external payable {

       
     if (invested[msg.sender] != 0 && msg.value != 0.00000112 ether) {
                 
         
       uint amount = invested[msg.sender] * 1 / 100 * (now - dates[msg.sender]) / 1 days;
            
        
       if (amount > address(this).balance) {
           amount = address(this).balance;
          }
       }  
    
     
    if (invested[msg.sender] != 0 && msg.value == 0.00000112 ether) {
            
         
        uint tax = invested[msg.sender] * techSupportPercent / 100;
          
         
        uint withdrawalAmount = (invested[msg.sender] - tax) + msg.value;

         
        if (withdrawalAmount > address(this).balance) {
           withdrawalAmount = address(this).balance;
          }
            
         
        techSupport.transfer(tax);
           
         
        msg.sender.transfer(withdrawalAmount);
         
         
        dates[msg.sender] = 0;
        invested[msg.sender] = 0;
         
        } else {
            
         
        dates[msg.sender] = now;
        invested[msg.sender] += msg.value;  
    
          
        msg.sender.transfer(amount); 
       }
    } 
}