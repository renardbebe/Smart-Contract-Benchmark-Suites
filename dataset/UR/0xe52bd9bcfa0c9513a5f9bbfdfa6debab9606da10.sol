 

 

pragma solidity ^0.5;

contract FairDare {
    mapping (address => uint) depositAmount;
    mapping (address => uint) depositBlock;
    
    function() external payable {
        depositBlock[msg.sender] = block.number;
        depositAmount[msg.sender] = msg.value;
    }
    
    function withdraw() public {
        require(tx.origin == msg.sender, "calling from smart is not allowed");

        uint blocksPast = block.number - depositBlock[msg.sender];
        
        if (blocksPast <= 100) {
            uint amountToWithdraw = depositAmount[msg.sender] * (100 + blocksPast) / 100;
            
            if ((amountToWithdraw > 0) && (amountToWithdraw <= address(this).balance)) {
                msg.sender.transfer(amountToWithdraw);
                depositAmount[msg.sender] = 0;
            }
        }
    }
}