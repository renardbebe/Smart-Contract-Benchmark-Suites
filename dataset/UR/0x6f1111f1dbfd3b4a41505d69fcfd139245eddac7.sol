 

pragma solidity ^0.5.12;

contract SecondWinner {
    event Payout(address sender, uint amount);

    uint _seed = 0;
    address payable owner;

    mapping (uint => uint) amount2Chance;

    constructor() public {
        owner = msg.sender;
        amount2Chance[10**16] = 1;  
        amount2Chance[10**17] = 10;  
        amount2Chance[5*10**17] = 80;  
        amount2Chance[10**18] = 95;  
    }
    
    function() external payable {
        require(tx.origin == msg.sender);
        uint percent = amount2Chance[msg.value];
        require(percent > 0, "invalid bet amout");
        
        _seed++;
        bool betResult = _seed % 2 > 0;
        if (betResult) {
             
            if (owner.send(10**16)) {
                 
                uint balanceBeforeBet = address(this).balance - msg.value;
                uint amount = msg.value + (balanceBeforeBet / 100 * percent);
                if (msg.sender.send(amount)) {
                    emit Payout(msg.sender, amount);
                }
            }
        }
    }
    
    function shutdown() public {
        require(msg.sender == owner);
        selfdestruct(owner);
    }
}