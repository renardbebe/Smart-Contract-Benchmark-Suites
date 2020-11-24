 

 

pragma solidity 0.4.24;


 
 
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

    modifier transactionExists(uint transactionId) {
        require(transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
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

    modifier validRequirement(uint ownerCount, uint _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

     
    function()
        public
        payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

     
     
     
     
    constructor(address[] _owners, uint _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
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
        emit OwnerAddition(owner);
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
        emit OwnerRemoval(owner);
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
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
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
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
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
            if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                txn.executed = false;
            }
        }
    }

     
     
    function external_call(address destination, uint value, uint dataLength, bytes data) internal returns (bool) {
        bool result;
        assembly {
            let x := mload(0x40)    
            let d := add(data, 32)  
            result := call(
                sub(gas, 34710),    
                                    
                                    
                destination,
                value,
                d,
                dataLength,         
                x,
                0                   
            )
        }
        return result;
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
        emit Submission(transactionId);
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

contract MultiSigWalletWithCustomTimeLocks is MultiSigWallet {

    event ConfirmationTimeSet(uint indexed transactionId, uint confirmationTime);
    event TimeLockDefaultChange(uint secondsTimeLockedDefault);
    event TimeLockCustomChange(string funcHeader, uint secondsTimeLockedCustom);
    event TimeLockCustomRemove(string funcHeader);

    struct CustomTimeLock {
        uint secondsTimeLocked;
        bool isSet;
    }
    
    uint public secondsTimeLockedDefault;  
    mapping (bytes4 => CustomTimeLock) public customTimeLocks;  
    string[] public customTimeLockFunctions;  

    mapping (uint => uint) public confirmationTimes;

    modifier notFullyConfirmed(uint transactionId) {
        require(!isConfirmed(transactionId));
        _;
    }

    modifier fullyConfirmed(uint transactionId) {
        require(isConfirmed(transactionId));
        _;
    }

    modifier pastTimeLock(uint transactionId) {
        uint timelock = getSecondsTimeLockedByTx(transactionId);
        require(timelock == 0 || block.timestamp >= confirmationTimes[transactionId] + timelock);
        _;
    }

     

     
     
     
     
    constructor(address[] _owners, uint _required, uint _secondsTimeLockedDefault)
        public
        MultiSigWallet(_owners, _required)
    {
        secondsTimeLockedDefault = _secondsTimeLockedDefault;

        customTimeLockFunctions.push("transferOwnership(address)");
        customTimeLocks[bytes4(keccak256("transferOwnership(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("transferOwnership(address)"))].secondsTimeLocked = 2419200;  

        customTimeLockFunctions.push("transferBZxOwnership(address)");
        customTimeLocks[bytes4(keccak256("transferBZxOwnership(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("transferBZxOwnership(address)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("replaceContract(address)");
        customTimeLocks[bytes4(keccak256("replaceContract(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("replaceContract(address)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("setTarget(string,address)");
        customTimeLocks[bytes4(keccak256("setTarget(string,address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("setTarget(string,address)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("setBZxAddresses(address,address,address,address,address)");
        customTimeLocks[bytes4(keccak256("setBZxAddresses(address,address,address,address,address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("setBZxAddresses(address,address,address,address,address)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("setVault(address)");
        customTimeLocks[bytes4(keccak256("setVault(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("setVault(address)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("changeDefaultTimeLock(uint256)");
        customTimeLocks[bytes4(keccak256("changeDefaultTimeLock(uint256)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("changeDefaultTimeLock(uint256)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("changeCustomTimeLock(string,uint256)");
        customTimeLocks[bytes4(keccak256("changeCustomTimeLock(string,uint256)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("changeCustomTimeLock(string,uint256)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("removeCustomTimeLock(string)");
        customTimeLocks[bytes4(keccak256("removeCustomTimeLock(string)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("removeCustomTimeLock(string)"))].secondsTimeLocked = 2419200;

        customTimeLockFunctions.push("toggleTargetPause(string,bool)");
        customTimeLocks[bytes4(keccak256("toggleTargetPause(string,bool)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("toggleTargetPause(string,bool)"))].secondsTimeLocked = 0;

        customTimeLockFunctions.push("toggleDebug(bool)");
        customTimeLocks[bytes4(keccak256("toggleDebug(bool)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("toggleDebug(bool)"))].secondsTimeLocked = 0;
    }

     
     
    function changeDefaultTimeLock(uint _secondsTimeLockedDefault)
        public
        onlyWallet
    {
        secondsTimeLockedDefault = _secondsTimeLockedDefault;
        emit TimeLockDefaultChange(_secondsTimeLockedDefault);
    }

     
     
     
    function changeCustomTimeLock(string _funcId, uint _secondsTimeLockedCustom)
        public
        onlyWallet
    {
        bytes4 f = bytes4(keccak256(abi.encodePacked(_funcId)));
        if (!customTimeLocks[f].isSet) {
            customTimeLocks[f].isSet = true;
            customTimeLockFunctions.push(_funcId);
        }
        customTimeLocks[f].secondsTimeLocked = _secondsTimeLockedCustom;
        emit TimeLockCustomChange(_funcId, _secondsTimeLockedCustom);
    }

     
     
    function removeCustomTimeLock(string _funcId)
        public
        onlyWallet
    {
        bytes4 f = bytes4(keccak256(abi.encodePacked(_funcId)));
        if (!customTimeLocks[f].isSet)
            revert();

        for (uint i=0; i < customTimeLockFunctions.length; i++) {
            if (keccak256(bytes(customTimeLockFunctions[i])) == keccak256(bytes(_funcId))) {
                if (i < customTimeLockFunctions.length - 1)
                    customTimeLockFunctions[i] = customTimeLockFunctions[customTimeLockFunctions.length - 1];
                customTimeLockFunctions.length--;

                customTimeLocks[f].secondsTimeLocked = 0;
                customTimeLocks[f].isSet = false;

                emit TimeLockCustomRemove(_funcId);

                break;
            }
        }
    }

     
     
    function confirmTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        if (getSecondsTimeLockedByTx(transactionId) > 0 && isConfirmed(transactionId)) {
            setConfirmationTime(transactionId, block.timestamp);
        }
    }

     
     
    function revokeConfirmation(uint transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint transactionId)
        public
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        pastTimeLock(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;
        if (external_call(txn.destination, txn.value, txn.data.length, txn.data))
            emit Execution(transactionId);
        else {
            emit ExecutionFailure(transactionId);
            txn.executed = false;
        }
    }

     
     
     
    function getSecondsTimeLocked(bytes4 _funcId)
        public
        view
        returns (uint)
    {
        if (customTimeLocks[_funcId].isSet)
            return customTimeLocks[_funcId].secondsTimeLocked;
        else
            return secondsTimeLockedDefault;
    }

     
     
     
    function getSecondsTimeLockedByString(string _funcId)
        public
        view
        returns (uint)
    {
        return (getSecondsTimeLocked(bytes4(keccak256(abi.encodePacked(_funcId)))));
    }

     
     
     
    function getSecondsTimeLockedByTx(uint transactionId)
        public
        view
        returns (uint)
    {
        Transaction memory txn = transactions[transactionId];
        bytes memory data = txn.data;
        bytes4 funcId;
        assembly {
            funcId := mload(add(data, 32))
        }
        return (getSecondsTimeLocked(funcId));
    }

     
     
     
    function getTimeLockSecondsRemaining(uint transactionId)
        public
        view
        returns (uint)
    {
        uint timelock = getSecondsTimeLockedByTx(transactionId);
        if (timelock > 0 && confirmationTimes[transactionId] > 0) {
            uint timelockEnding = confirmationTimes[transactionId] + timelock;
            if (timelockEnding > block.timestamp)
                return timelockEnding - block.timestamp;
        }
        return 0;
    }

     

     
    function setConfirmationTime(uint transactionId, uint confirmationTime)
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}