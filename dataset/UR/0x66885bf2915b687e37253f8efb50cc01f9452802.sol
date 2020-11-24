 

pragma solidity ^0.4.24;

 
 
contract MultiSigWallet {

     
    event Confirmation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerChange(address indexed oldOwner, address indexed newOwner);

     
    uint constant public REQUIRED = 3;

     
    mapping (uint => Transaction) public transactions;
    
    mapping (uint => mapping (address => bool)) public confirmations;
    
    mapping (address => bool) public isOwner;
    address[] public owners;

    address public delayedOwner;
     
    mapping (uint => uint) public delayedConfirmations;

    uint public transactionCount;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
    }

     
    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner] && owner != delayedOwner);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner] || owner == delayedOwner);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

 
    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner] || (owner == delayedOwner && delayedConfirmations[transactionId] < now));
        _;
    }

    modifier notExecuted(uint transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

     
    function() public
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

     
     
     
     
    constructor(address[] _owners, address _delayedOwner)
        public
    {
        uint _length = _owners.length;
        require(_length == REQUIRED);
        delayedOwner = _delayedOwner;
        
        for (uint i = 0; i < _length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
    }

     
     
     
    function replaceOwner(address owner, address newOwner)
        public
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerChange(owner, newOwner);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data)
        public
        ownerExists(msg.sender)
        returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
    {
        if (msg.sender == delayedOwner)
        {
            delayedConfirmations[transactionId] = now + 2 weeks;
            emit Confirmation(msg.sender, transactionId);
        }
        else
        {
            confirmations[transactionId][msg.sender] = true;
            emit Confirmation(msg.sender, transactionId);
            executeTransaction(transactionId);
        }
    }

     
     
    function executeTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            if (txn.destination.call.value(txn.value)(txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

     
     
     
    function isConfirmed(uint transactionId)
        public
        constant
        returns (bool)
    {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == REQUIRED)
                return true;
        }
        if (delayedConfirmations[transactionId] > 0 && delayedConfirmations[transactionId] < now)
        {
            count += 1;
            if (count == REQUIRED)
                return true;
        }
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data)
        internal
        notNull(destination)
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: data,
            executed: false
        });
        transactionCount += 1;
        emit Submission(transactionId);
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed)
        public
        constant
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}