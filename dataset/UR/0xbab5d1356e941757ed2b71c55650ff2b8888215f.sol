 

pragma solidity ^0.4.25;

 
contract Restarted {
     
    uint public percentage = 4;
     
    uint public period = 5900;
     
    uint public stage = 1;
     
    mapping (uint => mapping (address => uint256)) public invested;
     
    mapping (uint => mapping (address => uint256)) public atBlock;
     
    mapping (uint => uint) public maxFund;

     
    function () external payable {
         
        if (invested[stage][msg.sender] != 0) {
             
             
             
            uint256 amount = invested[stage][msg.sender] * percentage / 100 * (block.number - atBlock[stage][msg.sender]) / period;
            
            uint max = (address(this).balance - msg.value) * 9 / 10;
            if (amount > max) {
                amount = max;
            }

             
            msg.sender.transfer(amount);
        }
        
         
        address(0x4C15C3356c897043C2626D57e4A810D444a010a8).transfer(msg.value / 20);
        
        uint balance = address(this).balance;
        
        if (balance > maxFund[stage]) {
            maxFund[stage] = balance;
        }
        if (balance < maxFund[stage] / 100) {
            stage++;
        }
        
         
        atBlock[stage][msg.sender] = block.number;
        invested[stage][msg.sender] += msg.value;
    }
}