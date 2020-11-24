 

 
 

 
 

 
 
 

 
 
 
 

 
 

pragma solidity ^ 0.4.10;
contract BurnableOpenPaymentFactory {
	event NewBOP(address indexed newBOPAddress, address payer, uint serviceDeposit, uint autoreleaseTime, string title, string initialStatement);

	 
	address[]public BOPs;

	function getBOPCount()
	public
	constant
	returns(uint) {
		return BOPs.length;
	}

	function newBurnableOpenPayment(address payer, uint serviceDeposit, uint autoreleaseInterval, string title, string initialStatement)
	public
	payable
	returns(address) {
		 
		address newBOPAddr = (new BurnableOpenPayment).value(msg.value)(payer, serviceDeposit, autoreleaseInterval, title, initialStatement);
		NewBOP(newBOPAddr, payer, serviceDeposit, autoreleaseInterval, title, initialStatement);

		 
		BOPs.push(newBOPAddr);

		return newBOPAddr;
	}
}

contract BurnableOpenPayment {
     
    string public title;
    
	 
	address public payer;
	address public worker;
	address constant burnAddress = 0x0;
	
	 
	bool recovered = false;

	 
	uint public amountDeposited;
	uint public amountBurned;
	uint public amountReleased;

	 
	uint public serviceDeposit;

	 
	uint public autoreleaseInterval;

	 
	 
	 
	uint public autoreleaseTime;

	 
	enum State {
		Open,
		Committed,
		Closed
	}
	State public state;
	 
	 

	modifier inState(State s) {
		require(s == state);
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

	event Created(address indexed contractAddress, address payer, uint serviceDeposit, uint autoreleaseInterval, string title);
	event FundsAdded(address from, uint amount);  
	event PayerStatement(string statement);
	event WorkerStatement(string statement);
	event FundsRecovered();
	event Committed(address worker);
	event FundsBurned(uint amount);
	event FundsReleased(uint amount);
	event Closed();
	event Unclosed();
	event AutoreleaseDelayed();
	event AutoreleaseTriggered();

	function BurnableOpenPayment(address _payer, uint _serviceDeposit, uint _autoreleaseInterval, string _title, string initialStatement)
	public
	payable {
		Created(this, _payer, _serviceDeposit, _autoreleaseInterval, _title);

		if (msg.value > 0) {
		     
			FundsAdded(tx.origin, msg.value);
			amountDeposited += msg.value;
		}
		
		title = _title;

		state = State.Open;
		payer = _payer;

		serviceDeposit = _serviceDeposit;

		autoreleaseInterval = _autoreleaseInterval;

		if (bytes(initialStatement).length > 0)
		    PayerStatement(initialStatement);
	}

	function getFullState()
	public
	constant
	returns(address, string, State, address, uint, uint, uint, uint, uint, uint, uint) {
		return (payer, title, state, worker, this.balance, serviceDeposit, amountDeposited, amountBurned, amountReleased, autoreleaseInterval, autoreleaseTime);
	}

	function addFunds()
	public
	payable {
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
	onlyPayer()
	inState(State.Open) {
	    recovered = true;
		FundsRecovered();
		selfdestruct(payer);
	}

	function commit()
	public
	inState(State.Open)
	payable{
		require(msg.value == serviceDeposit);

		if (msg.value > 0) {
			FundsAdded(msg.sender, msg.value);
			amountDeposited += msg.value;
		}

		worker = msg.sender;
		state = State.Committed;
		Committed(worker);

		autoreleaseTime = now + autoreleaseInterval;
	}

	function internalBurn(uint amount)
	private
	inState(State.Committed) {
		burnAddress.transfer(amount);

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
	onlyPayer() {
		internalBurn(amount);
	}

	function internalRelease(uint amount)
	private
	inState(State.Committed) {
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
	onlyPayer() {
		internalRelease(amount);
	}

	function logPayerStatement(string statement)
	public
	onlyPayer() {
	    PayerStatement(statement);
	}

	function logWorkerStatement(string statement)
	public
	onlyWorker() {
		WorkerStatement(statement);
	}

	function delayAutorelease()
	public
	onlyPayer()
	inState(State.Committed) {
		autoreleaseTime = now + autoreleaseInterval;
		AutoreleaseDelayed();
	}

	function triggerAutorelease()
	public
	onlyWorker()
	inState(State.Committed) {
		require(now >= autoreleaseTime);

        AutoreleaseTriggered();
		internalRelease(this.balance);
	}
}