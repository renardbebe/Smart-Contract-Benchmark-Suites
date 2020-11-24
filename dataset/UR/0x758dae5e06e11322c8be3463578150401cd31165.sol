 

 

pragma solidity 0.5.3;

 
 
contract MultiSigWallet {

     
    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);

     
    uint256 constant public MAX_OWNER_COUNT = 50;

     
    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
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

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != address(0));
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        require(confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        require(!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        require(!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0));
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

     
    function()
        external
        payable
    {
        if (msg.value != 0)
            emit Deposit(msg.sender, msg.value);
    }

     
     
     
     
    constructor(address[] memory _owners, uint256 _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint256 i=0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != address(0));
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
        for (uint256 i=0; i<owners.length - 1; i++)
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
        for (uint256 i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = false;
        isOwner[newOwner] = true;
        emit OwnerRemoval(owner);
        emit OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint256 _required)
        public
        onlyWallet
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint256 value, bytes memory data)
        public
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
    function confirmTransaction(uint256 transactionId)
        public
        ownerExists(msg.sender)
        transactionExists(transactionId)
        notConfirmed(transactionId, msg.sender)
    {
        confirmations[transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, transactionId);
        executeTransaction(transactionId);
    }

     
     
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint256 transactionId)
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

     
     
    function external_call(address destination, uint256 value, uint256 dataLength, bytes memory data) internal returns (bool) {
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

     
     
     
    function isConfirmed(uint256 transactionId)
        public
        view
        returns (bool)
    {
        uint256 count = 0;
        for (uint256 i=0; i<owners.length; i++) {
            if (confirmations[transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
    }

     
     
     
     
     
     
    function addTransaction(address destination, uint256 value, bytes memory data)
        internal
        notNull(destination)
        returns (uint256 transactionId)
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

     
     
     
     
    function getConfirmationCount(uint256 transactionId)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed)
        public
        view
        returns (uint256 count)
    {
        for (uint256 i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

     
     
    function getOwners()
        public
        view
        returns (address[] memory)
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint256 from, uint256 to, bool pending, bool executed)
        public
        view
        returns (uint256[] memory _transactionIds)
    {
        uint256[] memory transactionIdsTemp = new uint256[](transactionCount);
        uint256 count = 0;
        uint256 i;
        for (i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint256[](to - from);
        for (i=from; i<to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}

contract MultiSigWalletWithCustomTimeLocks is MultiSigWallet {

    event ConfirmationTimeSet(uint256 indexed transactionId, uint256 confirmationTime);
    event TimeLockDefaultChange(uint256 secondsTimeLockedDefault);
    event TimeLockCustomChange(string funcHeader, uint256 secondsTimeLockedCustom);
    event TimeLockCustomRemove(string funcHeader);

    struct CustomTimeLock {
        uint256 secondsTimeLocked;
        bool isSet;
    }

    uint256 public secondsTimeLockedDefault;  
    mapping (bytes4 => CustomTimeLock) public customTimeLocks;  
    string[] public customTimeLockFunctions;  

    mapping (uint256 => uint256) public confirmationTimes;

    modifier notFullyConfirmed(uint256 transactionId) {
        require(!isConfirmed(transactionId), "is confirmed");
        _;
    }

    modifier fullyConfirmed(uint256 transactionId) {
        require(isConfirmed(transactionId), "not confirmed");
        _;
    }

    modifier passedTimeLock(uint256 transactionId) {
        uint256 timelock = getSecondsTimeLockedByTx(transactionId);
        require(timelock == 0 || block.timestamp >= confirmationTimes[transactionId] + timelock, "not passed timelock");
        _;
    }

     

     
     
     
     
    constructor(address[] memory _owners, uint256 _required, uint256 _secondsTimeLockedDefault)
        public
        MultiSigWallet(_owners, _required)
    {
        secondsTimeLockedDefault = _secondsTimeLockedDefault;

        customTimeLockFunctions.push("transferOwnership(address)");
        customTimeLocks[bytes4(keccak256("transferOwnership(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("transferOwnership(address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("transferBZxOwnership(address)");
        customTimeLocks[bytes4(keccak256("transferBZxOwnership(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("transferBZxOwnership(address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("setBZxAddresses(address,address,address,address,address,address,address)");
        customTimeLocks[bytes4(keccak256("setBZxAddresses(address,address,address,address,address,address,address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("setBZxAddresses(address,address,address,address,address,address,address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("setVault(address)");
        customTimeLocks[bytes4(keccak256("setVault(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("setVault(address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("addOwner(address)");
        customTimeLocks[bytes4(keccak256("addOwner(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("addOwner(address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("removeOwner(address)");
        customTimeLocks[bytes4(keccak256("removeOwner(address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("removeOwner(address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("replaceOwner(address,address)");
        customTimeLocks[bytes4(keccak256("replaceOwner(address,address)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("replaceOwner(address,address)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("changeRequirement(uint256)");
        customTimeLocks[bytes4(keccak256("changeRequirement(uint256)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("changeRequirement(uint256)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("changeDefaultTimeLock(uint256)");
        customTimeLocks[bytes4(keccak256("changeDefaultTimeLock(uint256)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("changeDefaultTimeLock(uint256)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("changeCustomTimeLock(string,uint256)");
        customTimeLocks[bytes4(keccak256("changeCustomTimeLock(string,uint256)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("changeCustomTimeLock(string,uint256)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("removeCustomTimeLock(string)");
        customTimeLocks[bytes4(keccak256("removeCustomTimeLock(string)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("removeCustomTimeLock(string)"))].secondsTimeLocked = 172800;

        customTimeLockFunctions.push("toggleTargetPause(string,bool)");
        customTimeLocks[bytes4(keccak256("toggleTargetPause(string,bool)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("toggleTargetPause(string,bool)"))].secondsTimeLocked = 0;

        customTimeLockFunctions.push("toggleMintingPause(string,bool)");
        customTimeLocks[bytes4(keccak256("toggleMintingPause(string,bool)"))].isSet = true;
        customTimeLocks[bytes4(keccak256("toggleMintingPause(string,bool)"))].secondsTimeLocked = 0;
    }

     
     
    function changeDefaultTimeLock(uint256 _secondsTimeLockedDefault)
        public
        onlyWallet
    {
        secondsTimeLockedDefault = _secondsTimeLockedDefault;
        emit TimeLockDefaultChange(_secondsTimeLockedDefault);
    }

     
     
     
    function changeCustomTimeLock(string memory _funcId, uint256 _secondsTimeLockedCustom)
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

     
     
    function removeCustomTimeLock(string memory _funcId)
        public
        onlyWallet
    {
        bytes4 f = bytes4(keccak256(abi.encodePacked(_funcId)));
        if (!customTimeLocks[f].isSet)
            revert("not set");

        for (uint256 i=0; i < customTimeLockFunctions.length; i++) {
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

     
     
    function confirmTransaction(uint256 transactionId)
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

     
     
    function revokeConfirmation(uint256 transactionId)
        public
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
        notFullyConfirmed(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
     
    function executeTransaction(uint256 transactionId)
        public
        notExecuted(transactionId)
        fullyConfirmed(transactionId)
        passedTimeLock(transactionId)
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
        returns (uint256)
    {
        if (customTimeLocks[_funcId].isSet)
            return customTimeLocks[_funcId].secondsTimeLocked;
        else
            return secondsTimeLockedDefault;
    }

     
     
     
    function getSecondsTimeLockedByString(string memory _funcId)
        public
        view
        returns (uint256)
    {
        return (getSecondsTimeLocked(bytes4(keccak256(abi.encodePacked(_funcId)))));
    }

     
     
     
    function getSecondsTimeLockedByTx(uint256 transactionId)
        public
        view
        returns (uint256)
    {
        Transaction memory txn = transactions[transactionId];
        bytes memory data = txn.data;
        bytes4 funcId;
        assembly {
            funcId := mload(add(data, 32))
        }
        return (getSecondsTimeLocked(funcId));
    }

     
     
     
    function getTimeLockSecondsRemaining(uint256 transactionId)
        public
        view
        returns (uint256)
    {
        uint256 timelock = getSecondsTimeLockedByTx(transactionId);
        if (timelock > 0 && confirmationTimes[transactionId] > 0) {
            uint256 timelockEnding = confirmationTimes[transactionId] + timelock;
            if (timelockEnding > block.timestamp)
                return timelockEnding - block.timestamp;
        }
        return 0;
    }

     

     
    function setConfirmationTime(uint256 transactionId, uint256 confirmationTime)
        internal
    {
        confirmationTimes[transactionId] = confirmationTime;
        emit ConfirmationTimeSet(transactionId, confirmationTime);
    }
}