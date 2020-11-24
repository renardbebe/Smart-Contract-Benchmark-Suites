 

pragma solidity ^0.4.18;

 
 
 
 

 

contract MultiSigWallet {

    event Confirmation(address sender, bytes32 transactionId);
    event Revocation(address sender, bytes32 transactionId);
    event Submission(bytes32 transactionId);
    event Execution(bytes32 transactionId);
    event Deposit(address sender, uint value);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event RequirementChange(uint required);
    event CoinCreation(address coin);

    mapping (bytes32 => Transaction) public transactions;
    mapping (bytes32 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] owners;
    bytes32[] transactionList;
    uint public required;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        uint nonce;
        bool executed;
    }

    modifier onlyWallet() {
        require(msg.sender == address(this));
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier confirmed(bytes32 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(bytes32 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(bytes32 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address destination) {
        require(destination != 0);
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(   _required <= _ownerCount
                && _required > 0 );
        _;
    }
    
     
     
     
    function MultiSigWallet(address[] _owners, uint _required)
        validRequirement(_owners.length, _required)
        public {
        for (uint i=0; i<_owners.length; i++) {
             
            if (isOwner[_owners[i]] || _owners[i] == 0){
                revert();
            }
             
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
    }

     
    function()
        public
        payable {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }

     
     
    function addOwner(address owner)
        public
        onlyWallet
        ownerDoesNotExist(owner) {
        isOwner[owner] = true;
        owners.push(owner);
        OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        public
        onlyWallet
        ownerExists(owner) {
         
        require(owners.length > 1);
        
        isOwner[owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        OwnerRemoval(owner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required) {
        required = _required;
        RequirementChange(_required);
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data, uint nonce)
        private
        notNull(destination)
        returns (bytes32 transactionId) {
         
        transactionId = keccak256(destination, value, data, nonce);
        if (transactions[transactionId].destination == 0) {
            transactions[transactionId] = Transaction({
                destination: destination,
                value: value,
                data: data,
                nonce: nonce,
                executed: false
            });
            transactionList.push(transactionId);
            Submission(transactionId);
        }
    }

     
     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data, uint nonce)
        external
        ownerExists(msg.sender)
        returns (bytes32 transactionId) {
        transactionId = addTransaction(destination, value, data, nonce);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(bytes32 transactionId)
        public
        ownerExists(msg.sender)
        notConfirmed(transactionId, msg.sender) {
        confirmations[transactionId][msg.sender] = true;
        Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

    
     
     
    function executeTransaction(bytes32 transactionId)
        public
        notExecuted(transactionId) {
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId]; 
            txn.executed = true;
            if (!txn.destination.call.value(txn.value)(txn.data))
                revert();
            Execution(transactionId);
        }
    }

     
     
    function revokeConfirmation(bytes32 transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId) {
        confirmations[transactionId][msg.sender] = false;
        Revocation(msg.sender, transactionId);
    }

     
     
     
    function isConfirmed(bytes32 transactionId)
        public
        constant
        returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
    }

     
     
     
     
    function confirmationCount(bytes32 transactionId)
        external
        constant
        returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
    function filterTransactions(bool isPending)
        private
        constant
        returns (bytes32[] _transactionList) {
        bytes32[] memory _transactionListTemp = new bytes32[](transactionList.length);
        uint count = 0;
        for (uint i=0; i<transactionList.length; i++)
            if (transactions[transactionList[i]].executed != isPending)
            {
                _transactionListTemp[count] = transactionList[i];
                count += 1;
            }
        _transactionList = new bytes32[](count);
        for (i=0; i<count; i++)
            if (_transactionListTemp[i] > 0)
                _transactionList[i] = _transactionListTemp[i];
    }

     
    function getPendingTransactions()
        external
        constant
        returns (bytes32[]) {
        return filterTransactions(true);
    }

     
    function getExecutedTransactions()
        external
        constant
        returns (bytes32[]) {
        return filterTransactions(false);
    }
}