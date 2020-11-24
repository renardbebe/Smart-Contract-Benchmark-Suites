 

pragma solidity ^0.4.25;

 
contract EasyInvest5 {

     
    mapping (address => uint) public invested;
     
    mapping (address => uint) public dates;

     
    uint public totalInvested;
     
    uint public canInvest = 50 ether;
     
    uint public refreshTime = now + 24 hours;

     
    function () external payable {
         
        if (invested[msg.sender] != 0) {
             
             
            uint amount = invested[msg.sender] * 5 * (now - dates[msg.sender]) / 100 / 24 hours;

             
            if (amount > address(this).balance) {
                amount = address(this).balance;
            }

             
            msg.sender.transfer(amount);
        }

         
        dates[msg.sender] = now;

         
        if (refreshTime <= now) {
             
            canInvest += totalInvested / 10;
            refreshTime += 24 hours;
        }

        if (msg.value > 0) {
             
            require(msg.value <= canInvest);
             
            invested[msg.sender] += msg.value;
             
            canInvest -= msg.value;
            totalInvested += msg.value;
        }
    }
}