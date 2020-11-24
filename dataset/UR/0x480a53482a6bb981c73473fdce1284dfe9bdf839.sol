 

 
 

 
 

 
 

 
 

 

pragma solidity ^0.4.1;

contract BurnableOpenPayment {
    address public payer;
    address public recipient;
    address public burnAddress = 0xdead;
    string public payerString;
    string public recipientString;
    uint public commitThreshold;
    
    modifier onlyPayer() {
        if (msg.sender != payer) throw;
        _;
    }
    
    modifier onlyRecipient() {
        if (msg.sender != recipient) throw;
        _;
    }
    
    modifier onlyWithRecipient() {
        if (recipient == address(0x0)) throw;
        _;
    }
    
    modifier onlyWithoutRecipient() {
        if (recipient != address(0x0)) throw;
        _;
    }
    
    function () payable {}
    
    function BurnableOpenPayment(address _payer, uint _commitThreshold)
    public
    payable {
        payer = _payer;
        commitThreshold = _commitThreshold;
    }
    
    function getPayer()
    public returns (address) { return payer; }
    
    function getRecipient()
    public returns (address) { return recipient; }
    
    function getCommitThreshold()
    public returns (uint) { return commitThreshold; }
    
    function getPayerString()
    public returns (string) { return payerString; }
    
    function getRecipientString()
    public returns (string) { return recipientString; }
    
    function commit()
    public
    onlyWithoutRecipient()
    payable
    {
        if (msg.value < commitThreshold) throw;
        recipient = msg.sender;
    }
    
    function burn(uint amount)
    public
    onlyPayer()
    onlyWithRecipient()
    returns (bool)
    {
        return burnAddress.send(amount);
    }
    
    function release(uint amount)
    public
    onlyPayer()
    onlyWithRecipient()
    returns (bool)
    {
        return recipient.send(amount);
    }
    
    function setPayerString(string _string)
    public
    onlyPayer()
    {
        payerString = _string;
    }
    
    function setRecipientString(string _string)
    public
    onlyRecipient()
    {
        recipientString = _string;
    }
}

contract BurnableOpenPaymentFactory {
    function newBurnableOpenPayment(address payer, uint commitThreshold)
    public
    payable
    returns (address) {
         
        return (new BurnableOpenPayment).value(msg.value)(payer, commitThreshold);
    }
}