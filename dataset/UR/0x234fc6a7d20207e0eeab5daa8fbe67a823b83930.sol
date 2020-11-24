 

pragma solidity ^0.5;

 

contract Doubler {
    uint _totalBalance;
    address payable owner = msg.sender;
    
    function() external payable {
        require (tx.origin == msg.sender);
        
        uint withdrawAmount = msg.value * 2;
        
        if (_totalBalance >= withdrawAmount) {
            msg.sender.transfer(withdrawAmount);
            _totalBalance -= withdrawAmount;
        }
    }
    
    function deposit() public payable {
        _totalBalance += msg.value;
    }
    
    function kill() public {
        require (msg.sender == owner);
        selfdestruct(owner);
    }
}