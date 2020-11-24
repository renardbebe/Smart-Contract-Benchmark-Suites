 

 
 

 
 

 
 
 

 
 

 

pragma solidity ^0.4.10;

contract BurnableOpenPayment {
     
    address public payer;
    address public recipient;
    address constant burnAddress = 0x0;
    
     
    uint public amountDeposited;
    uint public amountBurned;
    uint public amountReleased;
    
     
     
     
    string public payerString;
    string public recipientString;
    
     
    uint public commitThreshold;
    
     
     
    enum DefaultAction {None, Release, Burn}
    DefaultAction public defaultAction;
    
     
    uint public defaultTimeoutLength;
    
     
     
    uint public defaultTriggerTime;
    
     
    enum State {Open, Committed, Expended}
    State public state;
     
     
    
    modifier inState(State s) { require(s == state); _; }
    modifier onlyPayer() { require(msg.sender == payer); _; }
    modifier onlyRecipient() { require(msg.sender == recipient); _; }
    modifier onlyPayerOrRecipient() { require((msg.sender == payer) || (msg.sender == recipient)); _; }
    
    event Created(address payer, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength, string initialPayerString);
    event FundsAdded(uint amount); 
    event PayerStringUpdated(string newPayerString);
    event RecipientStringUpdated(string newRecipientString);
    event FundsRecovered();
    event Committed(address recipient);
    event FundsBurned(uint amount);
    event FundsReleased(uint amount);
    event Expended();
    event Unexpended();
    event DefaultActionDelayed();
    event DefaultActionCalled();
    
    function BurnableOpenPayment(address _payer, uint _commitThreshold, DefaultAction _defaultAction, uint _defaultTimeoutLength, string _payerString)
    public
    payable {
        Created(_payer, _commitThreshold, _defaultAction, _defaultTimeoutLength, _payerString);
        
        if (msg.value > 0) {
            FundsAdded(msg.value);
            amountDeposited += msg.value;
        }
            
        state = State.Open;
        payer = _payer;
        
        commitThreshold = _commitThreshold;
        
        defaultAction = _defaultAction;
        if (defaultAction != DefaultAction.None) 
            defaultTimeoutLength = _defaultTimeoutLength;
        
        payerString = _payerString;
    }
    
    function getFullState()
    public
    constant
    returns (State, address, string, address, string, uint, uint, uint, uint, uint, DefaultAction, uint, uint) {
        return (state, payer, payerString, recipient, recipientString, this.balance, commitThreshold, amountDeposited, amountBurned, amountReleased, defaultAction, defaultTimeoutLength, defaultTriggerTime);
    }
    
    function addFunds()
    public
    onlyPayer()
    payable {
        require(msg.value > 0);
        
        FundsAdded(msg.value);
        amountDeposited += msg.value;
        if (state == State.Expended) {
            state = State.Committed;
            Unexpended();
        }
    }
    
    function recoverFunds()
    public
    onlyPayer()
    inState(State.Open)
    {
        FundsRecovered();
        selfdestruct(payer);
    }
    
    function commit()
    public
    inState(State.Open)
    payable
    {
        require(msg.value >= commitThreshold);
        
        if (msg.value > 0) {
            FundsAdded(msg.value);
            amountDeposited += msg.value;
        }
        
        recipient = msg.sender;
        state = State.Committed;
        Committed(recipient);
        
        if (defaultAction != DefaultAction.None) {
            defaultTriggerTime = now + defaultTimeoutLength;
        }
    }
    
    function internalBurn(uint amount)
    private
    inState(State.Committed)
    {
        burnAddress.transfer(amount);
        
        amountBurned += amount;
        FundsBurned(amount);
        
        if (this.balance == 0) {
            state = State.Expended;
            Expended();
        }
    }
    
    function burn(uint amount)
    public
    inState(State.Committed)
    onlyPayer()
    {
        internalBurn(amount);
    }
    
    function internalRelease(uint amount)
    private
    inState(State.Committed)
    {
        recipient.transfer(amount);
        
        amountReleased += amount;
        FundsReleased(amount);
        
        if (this.balance == 0) {
            state = State.Expended;
            Expended();
        }
    }
    
    function release(uint amount)
    public
    inState(State.Committed)
    onlyPayer()
    {
        internalRelease(amount);
    }
    
    function setPayerString(string _string)
    public
    onlyPayer()
    {
        payerString = _string;
        PayerStringUpdated(payerString);
    }
    
    function setRecipientString(string _string)
    public
    onlyRecipient()
    {
        recipientString = _string;
        RecipientStringUpdated(recipientString);
    }
    
    function delayDefaultAction()
    public
    onlyPayerOrRecipient()
    inState(State.Committed)
    {
        require(defaultAction != DefaultAction.None);
        
        defaultTriggerTime = now + defaultTimeoutLength;
        DefaultActionDelayed();
    }
    
    function callDefaultAction()
    public
    onlyPayerOrRecipient()
    inState(State.Committed)
    {
        require(defaultAction != DefaultAction.None);
        require(now >= defaultTriggerTime);
        
        if (defaultAction == DefaultAction.Burn) {
            internalBurn(this.balance);
        }
        else if (defaultAction == DefaultAction.Release) {
            internalRelease(this.balance);
        }
        DefaultActionCalled();
    }
}

contract BurnableOpenPaymentFactory {
    event NewBOP(address newBOPAddress, address payer, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength, string initialPayerString);
    
    function newBurnableOpenPayment(address payer, uint commitThreshold, BurnableOpenPayment.DefaultAction defaultAction, uint defaultTimeoutLength, string initialPayerString)
    public
    payable
    returns (address) {
         
        address newBOPAddr = (new BurnableOpenPayment).value(msg.value)(payer, commitThreshold, defaultAction, defaultTimeoutLength, initialPayerString);
        NewBOP(newBOPAddr, payer, commitThreshold, defaultAction, defaultTimeoutLength, initialPayerString);
        return newBOPAddr;
    }
}