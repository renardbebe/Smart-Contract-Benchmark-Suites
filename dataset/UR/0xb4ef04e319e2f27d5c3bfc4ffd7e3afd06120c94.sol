 

pragma solidity >=0.4.23 <0.6.0;

contract MoneyBox {
    
    uint public duration = 5 minutes;
    uint public maxWithdraw = 100 ether;
    
    address public owner;
    uint public lastWithdraw;
    
    constructor() public payable {
        owner = msg.sender;
    }
     
    function() external payable {
        
    }
    
    function withdraw(uint amount) public {
        require(msg.sender == owner, "Only owner");
        require(now > lastWithdraw + duration, "Exceed withdraw duration");
        require(amount <= maxWithdraw, "Exceed withdraw amount");
        require (address(this).balance > 0, "Contract balance is zero");
        
        if (amount == 0) {
          amount = maxWithdraw;
        }

        lastWithdraw = now;

        if (address(this).balance < amount) {
            return msg.sender.transfer(address(this).balance);
        }
        
        msg.sender.transfer(amount);
    } 
}