 

 
 
 
 
 
 
 
 
 
 
 

 
 
 
 
 

 
 

 
 
 
 
 
 
 

 
 
 

pragma solidity ^ 0.4.2;

contract BurnablePaymentFactory {
    
     
    address[]public BPs;

    event NewBurnablePayment(
        address indexed bpAddress, 
        bool payerOpened, 
        address creator, 
        uint deposited, 
        uint commitThreshold, 
        uint autoreleaseInterval, 
        string title, 
        string initialStatement
    );  

    function newBP(bool payerOpened, address creator, uint commitThreshold, uint autoreleaseInterval, string title, string initialStatement)
    public
    payable
    returns (address newBPAddr) 
    {
         
        newBPAddr = (new BurnablePayment).value(msg.value)(payerOpened, creator, commitThreshold, autoreleaseInterval, title, initialStatement);
        NewBurnablePayment(newBPAddr, payerOpened, creator, msg.value, commitThreshold, autoreleaseInterval, title, initialStatement);

        BPs.push(newBPAddr);

        return newBPAddr;
    }

    function getBPCount()
    public
    constant
    returns(uint) 
    {
        return BPs.length;
    }
}

contract BurnablePayment {
     
    string public title;
    
     
    address public payer;
    address public worker;
    address constant BURN_ADDRESS = 0x0;
    
     
    bool recovered = false;

     
    uint public amountDeposited;
    uint public amountBurned;
    uint public amountReleased;

     
    uint public commitThreshold;

     
    uint public autoreleaseInterval;

     
     
     
    uint public autoreleaseTime;

     
    enum State {
        PayerOpened,
        WorkerOpened,
        Committed,
        Closed
    }

     
     
    State public state;

    modifier inState(State s) {
        require(s == state);
        _;
    }
    modifier inOpenState() {
        require(state == State.PayerOpened || state == State.WorkerOpened);
        _;
    }
    modifier onlyPayer() {
        require(msg.sender == payer);
        _;
    }
    modifier onlyWorker() {
        require(msg.sender == worker);
        _;
    }
    modifier onlyPayerOrWorker() {
        require((msg.sender == payer) || (msg.sender == worker));
        _;
    }
    modifier onlyCreatorWhileOpen() {
        if (state == State.PayerOpened) {
            require(msg.sender == payer);
        } else if (state == State.WorkerOpened) {
            require(msg.sender == worker);
        } else {
            revert();        
        }
        _;
    }

    event Created(address indexed contractAddress, bool payerOpened, address creator, uint commitThreshold, uint autoreleaseInterval, string title);
    event FundsAdded(address from, uint amount);  
    event PayerStatement(string statement);
    event WorkerStatement(string statement);
    event FundsRecovered();
    event Committed(address committer);
    event FundsBurned(uint amount);
    event FundsReleased(uint amount);
    event Closed();
    event Unclosed();
    event AutoreleaseDelayed();
    event AutoreleaseTriggered();

    function BurnablePayment(bool payerIsOpening, address creator, uint _commitThreshold, uint _autoreleaseInterval, string _title, string initialStatement)
    public
    payable 
    {
        Created(this, payerIsOpening, creator, _commitThreshold, autoreleaseInterval, title);

        if (msg.value > 0) {
             
            FundsAdded(tx.origin, msg.value);
            amountDeposited += msg.value;
        }
        
        title = _title;

        if (payerIsOpening) {
            state = State.PayerOpened;
            payer = creator;
        } else {
            state = State.WorkerOpened;
            worker = creator;
        }

        commitThreshold = _commitThreshold;
        autoreleaseInterval = _autoreleaseInterval;

        if (bytes(initialStatement).length > 0) {
            if (payerIsOpening) {
                PayerStatement(initialStatement);
            } else {
                WorkerStatement(initialStatement);              
            }
        }
    }

    function addFunds()
    public
    payable
    onlyPayerOrWorker()
    {
        require(msg.value > 0);

        FundsAdded(msg.sender, msg.value);
        amountDeposited += msg.value;
        if (state == State.Closed) {
            state = State.Committed;
            Unclosed();
        }
    }

    function recoverFunds()
    public
    onlyCreatorWhileOpen()
    {
        recovered = true;
        FundsRecovered();
        
        if (state == State.PayerOpened)
            selfdestruct(payer);
        else if (state == State.WorkerOpened)
            selfdestruct(worker);
    }

    function commit()
    public
    inOpenState()
    payable 
    {
        require(msg.value == commitThreshold);

        if (msg.value > 0) {
            FundsAdded(msg.sender, msg.value);
            amountDeposited += msg.value;
        }

        if (state == State.PayerOpened)
            worker = msg.sender;
        else
            payer = msg.sender;
        state = State.Committed;
        
        Committed(msg.sender);

        autoreleaseTime = now + autoreleaseInterval;
    }

    function internalBurn(uint amount)
    private 
    {
        BURN_ADDRESS.transfer(amount);

        amountBurned += amount;
        FundsBurned(amount);

        if (this.balance == 0) {
            state = State.Closed;
            Closed();
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
    {
        worker.transfer(amount);

        amountReleased += amount;
        FundsReleased(amount);

        if (this.balance == 0) {
            state = State.Closed;
            Closed();
        }
    }

    function release(uint amount)
    public
    inState(State.Committed)
    onlyPayer() 
    {
        internalRelease(amount);
    }

    function logPayerStatement(string statement)
    public
    onlyPayer() 
    {
        PayerStatement(statement);
    }

    function logWorkerStatement(string statement)
    public
    onlyWorker() 
    {
        WorkerStatement(statement);
    }

    function delayAutorelease()
    public
    onlyPayer()
    inState(State.Committed) 
    {
        autoreleaseTime = now + autoreleaseInterval;
        AutoreleaseDelayed();
    }

    function triggerAutorelease()
    public
    onlyWorker()
    inState(State.Committed) 
    {
        require(now >= autoreleaseTime);

        AutoreleaseTriggered();
        internalRelease(this.balance);
    }
    
    function getFullState()
    public
    constant
    returns(State, address, address, string, uint, uint, uint, uint, uint, uint, uint) {
        return (state, payer, worker, title, this.balance, commitThreshold, amountDeposited, amountBurned, amountReleased, autoreleaseInterval, autoreleaseTime);
    }
}