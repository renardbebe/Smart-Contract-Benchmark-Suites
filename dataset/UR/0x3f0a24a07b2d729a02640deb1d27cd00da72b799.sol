 

pragma solidity ^0.4.18;

contract ZipperWithdrawalRight
{
    address realzipper;

    function ZipperWithdrawalRight(address _realzipper) public
    {
        realzipper = _realzipper;
    }
    
    function withdraw(MultiSigWallet _wallet, uint _value) public
    {
        require (_wallet.isOwner(msg.sender));
        require (_wallet.isOwner(this));
        
        _wallet.submitTransaction(msg.sender, _value, "");
    }

    function changeRealZipper(address _newRealZipper) public
    {
        require(msg.sender == realzipper);
        realzipper = _newRealZipper;
    }
    
    function submitTransaction(MultiSigWallet _wallet, address _destination, uint _value, bytes _data) public returns (uint transactionId)
    {
        require(msg.sender == realzipper);
        return _wallet.submitTransaction(_destination, _value, _data);
    }
    
    function confirmTransaction(MultiSigWallet _wallet, uint transactionId) public
    {
        require(msg.sender == realzipper);
        _wallet.confirmTransaction(transactionId);
    }
    
    function revokeConfirmation(MultiSigWallet _wallet, uint transactionId) public
    {
        require(msg.sender == realzipper);
        _wallet.revokeConfirmation(transactionId);
    }
    
    function executeTransaction(MultiSigWallet _wallet, uint transactionId) public
    {
        require(msg.sender == realzipper);
        _wallet.confirmTransaction(transactionId);
    }
}

contract ZipperMultisigFactory
{
    address zipper;
    
    function ZipperMultisigFactory(address _zipper) public
    {
        zipper = _zipper;
    }

    function createMultisig() public returns (address _multisig)
    {
        address[] memory addys = new address[](2);
        addys[0] = zipper;
        addys[1] = msg.sender;
        
        MultiSigWallet a = new MultiSigWallet(addys, 2);
        
        MultisigCreated(address(a), msg.sender, zipper);
        
        return address(a);
    }
    
    function changeZipper(address _newZipper) public
    {
        require(msg.sender == zipper);
        zipper = _newZipper;
    }

    event MultisigCreated(address _multisig, address indexed _sender, address indexed _zipper);
}


     
    
     
     
    contract MultiSigWallet {
    
         
        event Confirmation(address indexed sender, uint indexed transactionId);
        event Revocation(address indexed sender, uint indexed transactionId);
        event Submission(uint indexed transactionId);
        event Execution(uint indexed transactionId);
        event ExecutionFailure(uint indexed transactionId);
        event Deposit(address indexed sender, uint value);
        event OwnerAddition(address indexed owner);
        event OwnerRemoval(address indexed owner);
        event RequirementChange(uint required);
    
         
        uint constant public MAX_OWNER_COUNT = 50;
    
         
        mapping (uint => Transaction) public transactions;
        mapping (uint => mapping (address => bool)) public confirmations;
        mapping (address => bool) public isOwner;
        address[] public owners;
        uint public required;
        uint public transactionCount;
    
        struct Transaction {
            address destination;
            uint value;
            bytes data;
            bool executed;
        }
    
         
        modifier onlyWallet() {
            if (msg.sender != address(this))
                throw;
            _;
        }
    
        modifier ownerDoesNotExist(address owner) {
            if (isOwner[owner])
                throw;
            _;
        }
    
        modifier ownerExists(address owner) {
            if (!isOwner[owner])
                throw;
            _;
        }
    
        modifier transactionExists(uint transactionId) {
            if (transactions[transactionId].destination == 0)
                throw;
            _;
        }
    
        modifier confirmed(uint transactionId, address owner) {
            if (!confirmations[transactionId][owner])
                throw;
            _;
        }
    
        modifier notConfirmed(uint transactionId, address owner) {
            if (confirmations[transactionId][owner])
                throw;
            _;
        }
    
        modifier notExecuted(uint transactionId) {
            if (transactions[transactionId].executed)
                throw;
            _;
        }
    
        modifier notNull(address _address) {
            if (_address == 0)
                throw;
            _;
        }
    
        modifier validRequirement(uint ownerCount, uint _required) {
            if (   ownerCount > MAX_OWNER_COUNT
                || _required > ownerCount
                || _required == 0
                || ownerCount == 0)
                throw;
            _;
        }
    
         
        function()
            payable
        {
            if (msg.value > 0)
                Deposit(msg.sender, msg.value);
        }
    
         
         
         
         
        function MultiSigWallet(address[] _owners, uint _required)
            public
            validRequirement(_owners.length, _required)
        {
            for (uint i=0; i<_owners.length; i++) {
                if (isOwner[_owners[i]] || _owners[i] == 0)
                    throw;
                isOwner[_owners[i]] = true;
            }
            owners = _owners;
            required = _required;
        }
    
         
         
        function addOwner(address owner)
            public
            onlyWallet
            ownerDoesNotExist(owner)
            notNull(owner)
            validRequirement(owners.length + 1, required)
        {
            isOwner[owner] = true;
            owners.push(owner);
            OwnerAddition(owner);
        }
    
         
         
        function removeOwner(address owner)
            public
            onlyWallet
            ownerExists(owner)
        {
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
            OwnerRemoval(owner);
            OwnerAddition(newOwner);
        }
    
         
         
        function changeRequirement(uint _required)
            public
            onlyWallet
            validRequirement(owners.length, _required)
        {
            required = _required;
            RequirementChange(_required);
        }
    
         
         
         
         
         
        function submitTransaction(address destination, uint value, bytes data)
            public
            returns (uint transactionId)
        {
            transactionId = addTransaction(destination, value, data);
            confirmTransaction(transactionId);
        }
    
         
         
        function confirmTransaction(uint transactionId)
            public
            ownerExists(msg.sender)
            transactionExists(transactionId)
            notConfirmed(transactionId, msg.sender)
        {
            confirmations[transactionId][msg.sender] = true;
            Confirmation(msg.sender, transactionId);
            executeTransaction(transactionId);
        }
    
         
         
        function revokeConfirmation(uint transactionId)
            public
            ownerExists(msg.sender)
            confirmed(transactionId, msg.sender)
            notExecuted(transactionId)
        {
            confirmations[transactionId][msg.sender] = false;
            Revocation(msg.sender, transactionId);
        }
    
         
         
        function executeTransaction(uint transactionId)
            public
            ownerExists(msg.sender)
            confirmed(transactionId, msg.sender)
            notExecuted(transactionId)
        {
            if (isConfirmed(transactionId)) {
                Transaction tx = transactions[transactionId];
                tx.executed = true;
                if (tx.destination.call.value(tx.value)(tx.data))
                    Execution(transactionId);
                else {
                    ExecutionFailure(transactionId);
                    tx.executed = false;
                }
            }
        }
    
         
         
         
        function isConfirmed(uint transactionId)
            public
            constant
            returns (bool)
        {
            uint count = 0;
            for (uint i=0; i<owners.length; i++) {
                if (confirmations[transactionId][owners[i]])
                    count += 1;
                if (count == required)
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
            Submission(transactionId);
        }
    
         
         
         
         
        function getConfirmationCount(uint transactionId)
            public
            constant
            returns (uint count)
        {
            for (uint i=0; i<owners.length; i++)
                if (confirmations[transactionId][owners[i]])
                    count += 1;
        }
    
         
         
         
         
        function getTransactionCount(bool pending, bool executed)
            public
            constant
            returns (uint count)
        {
            for (uint i=0; i<transactionCount; i++)
                if (   pending && !transactions[i].executed
                    || executed && transactions[i].executed)
                    count += 1;
        }
    
         
         
        function getOwners()
            public
            constant
            returns (address[])
        {
            return owners;
        }
    
         
         
         
        function getConfirmations(uint transactionId)
            public
            constant
            returns (address[] _confirmations)
        {
            address[] memory confirmationsTemp = new address[](owners.length);
            uint count = 0;
            uint i;
            for (i=0; i<owners.length; i++)
                if (confirmations[transactionId][owners[i]]) {
                    confirmationsTemp[count] = owners[i];
                    count += 1;
                }
            _confirmations = new address[](count);
            for (i=0; i<count; i++)
                _confirmations[i] = confirmationsTemp[i];
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