 

pragma solidity ^0.4.25;

 
contract EasyInvestIdeal {
     
    uint public createdAtBlock;
     
    uint public raised;
    
     
    mapping (address => uint) public invested;
     
    mapping (address => uint) public atBlock;
     
    mapping (address => uint) public percentages;
     
    mapping (address => bool) public premium;

    constructor () public {
        createdAtBlock = block.number;
    }
    
    function isFirstWeek() internal view returns (bool) {
        return block.number < createdAtBlock + 5900 * 7;
    }

     
    function () external payable {
         
        if (!isFirstWeek() && invested[msg.sender] != 0) {
             
             
             
            uint amount = invested[msg.sender] * percentages[msg.sender] / 100 * (block.number - atBlock[msg.sender]) / 5900;

            if (premium[msg.sender]) {
                amount = amount * 3 / 2;
            }
            uint max = raised * 9 / 10;
            if (amount > max) {
                amount = max;
            }

             
            msg.sender.transfer(amount);
            raised -= amount;
        }
        
         
        if (msg.value >= 1 ether) {
            percentages[msg.sender] = 16;
        } else if (percentages[msg.sender] > 2) {
            if (!isFirstWeek()) {
                percentages[msg.sender]--;
            }
        } else {
            percentages[msg.sender] = 2;
        }

         
        if (!isFirstWeek() || atBlock[msg.sender] == 0) {
            atBlock[msg.sender] = block.number;
        }
        invested[msg.sender] += msg.value;
        
        if (msg.value > 0) {
             
            if (isFirstWeek() && msg.value >= 100 finney) {
                premium[msg.sender] = true;
            }
             
            uint fee = msg.value / 20;
            address(0x107C80190872022f39593D6BCe069687C78C7A7C).transfer(fee);
            raised += msg.value - fee;
        }
    }
}