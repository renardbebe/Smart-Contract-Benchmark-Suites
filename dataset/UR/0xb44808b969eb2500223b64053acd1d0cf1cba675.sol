 

pragma solidity ^0.4.18;

 
contract Countdown {
    
    uint public deadline;
    address owner;
    address public winner;
    uint public reward = 0;
    uint public tips = 0;
    uint public buttonClicks = 0;
    
    function Countdown() public payable {
        owner = msg.sender;
        deadline = now + 3 hours;
        winner = msg.sender;
        reward += msg.value;
    }
    
    function ClickButton() public payable {
         
        require(msg.value >= 0.001 ether);
        
         
         
        if (now > deadline) {
            revert();
        }
    
        reward += msg.value * 8 / 10;
         
        tips += msg.value * 2 / 10;
        winner = msg.sender;
        deadline = now + 30 minutes;
        buttonClicks += 1;
    }
    
     
     
    function Win() public {
        require(msg.sender == winner);
        require(now > deadline);
        uint pendingReward = reward;
        reward = 0;
        winner.transfer(pendingReward);
    }
    
    function withdrawTips() public {
         
        uint pendingTips = tips;
        tips = 0;
        owner.transfer(pendingTips);
    }
    
}