 

 
 

 
 

 
 

 

pragma solidity ^0.4.1;

contract BurnableOpenPayment {
    address public payer;
    address public recipient;
    address public burnAddress = 0xdead;
    uint public commitThreshold;
    
    modifier onlyPayer() {
        if (msg.sender != payer) throw;
        _;
    }
    
    modifier onlyWithRecipient() {
        if (recipient == address(0x0)) throw;
        _;
    }
    
     
     
     
     
    function () payable onlyPayer { }
    
    function BurnableOpenPayment(address _payer, uint _commitThreshold) payable {
        payer = _payer;
        commitThreshold = _commitThreshold;
    }
    
    function getPayer() returns (address) {
        return payer;
    }
    
    function getRecipient() returns (address) {
        return recipient;
    }
    
    function getCommitThreshold() returns (uint) {
        return commitThreshold;
    }
    
    function commit()
    payable
    {
        if (recipient != address(0x0)) throw;
        if (msg.value < commitThreshold) throw;
        recipient = msg.sender;
    }
    
    function burn(uint amount)
    onlyPayer()
    onlyWithRecipient()
    returns (bool)
    {
        return burnAddress.send(amount);
    }
    
    function release(uint amount)
    onlyPayer()
    onlyWithRecipient()
    returns (bool)
    {
        return recipient.send(amount);
    }
}

contract BurnableOpenPaymentFactory {
    function newBurnableOpenPayment(address payer, uint commitThreshold) payable returns (address) {
         
        return (new BurnableOpenPayment).value(msg.value)(payer, commitThreshold);
    }
}