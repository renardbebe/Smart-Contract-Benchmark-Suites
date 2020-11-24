 

 

pragma solidity 0.5.8;
pragma experimental ABIEncoderV2;

contract MultiSigWalletWithTimelock {

    uint256 constant public MAX_OWNER_COUNT = 50;
    uint256 public lockSeconds = 259200;

    event Confirmation(address indexed sender, uint256 indexed transactionId);
    event Revocation(address indexed sender, uint256 indexed transactionId);
    event Submission(uint256 indexed transactionId);
    event Execution(uint256 indexed transactionId);
    event ExecutionFailure(uint256 indexed transactionId);
    event Deposit(address indexed sender, uint256 value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint256 required);
    event UnlockTimeSet(uint256 indexed transactionId, uint256 confirmationTime);
    event LockSecondsChange(uint256 lockSeconds);

    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    mapping (uint256 => uint256) public unlockTimes;

    address[] public owners;
    uint256 public required;
    uint256 public transactionCount;

    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }

    struct EmergencyCall {
        bytes32 selector;
        uint256 paramsBytesCount;
    }

     
    EmergencyCall[] public emergencyCalls;

    modifier onlyWallet() {
        if (msg.sender != address(this))
            revert("ONLY_WALLET_ERROR");
        _;
    }

    modifier ownerDoesNotExist(address owner) {
        if (isOwner[owner])
            revert("OWNER_DOES_NOT_EXIST_ERROR");
        _;
    }

    modifier ownerExists(address owner) {
        if (!isOwner[owner])
            revert("OWNER_EXISTS_ERROR");
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        if (transactions[transactionId].destination == address(0))
            revert("TRANSACTION_EXISTS_ERROR");
        _;
    }

    modifier confirmed(uint256 transactionId, address owner) {
        if (!confirmations[transactionId][owner])
            revert("CONFIRMED_ERROR");
        _;
    }

    modifier notConfirmed(uint256 transactionId, address owner) {
        if (confirmations[transactionId][owner])
            revert("NOT_CONFIRMED_ERROR");
        _;
    }

    modifier notExecuted(uint256 transactionId) {
        if (transactions[transactionId].executed)
            revert("NOT_EXECUTED_ERROR");
        _;
    }

    modifier notNull(address _address) {
        if (_address == address(0))
            revert("NOT_NULL_ERROR");
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        if (ownerCount > MAX_OWNER_COUNT || _required > ownerCount || _required == 0 || ownerCount == 0)
            revert("VALID_REQUIREMENT_ERROR");
        _;
    }

     
    function() external payable {
        if (msg.value > 0) {
            emit Deposit(msg.sender, msg.value);
        }
    }

     
    constructor(address[] memory _owners, uint256 _required)
        public
        validRequirement(_owners.length, _required)
    {
        for (uint256 i = 0; i < _owners.length; i++) {
            if (isOwner[_owners[i]] || _owners[i] == address(0)) {
                revert("OWNER_ERROR");
            }

            isOwner[_owners[i]] = true;
        }

        owners = _owners;
        required = _required;

         
        emergencyCalls.push(
            EmergencyCall({
                selector: keccak256(abi.encodePacked("setMarketBorrowUsability(uint16,bool)")),
                paramsBytesCount: 64
            })
        );
    }

    function getEmergencyCallsCount()
        external
        view
        returns (uint256 count)
    {
        return emergencyCalls.length;
    }

     
    function addOwner(address owner)
        external
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
        external
        onlyWallet
        ownerExists(owner)
    {
        isOwner[owner] = false;
        for (uint256 i = 0; i < owners.length - 1; i++) {
            if (owners[i] == owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        }

        owners.length -= 1;

        if (required > owners.length) {
            changeRequirement(owners.length);
        }

        emit OwnerRemoval(owner);
    }

     
    function replaceOwner(address owner, address newOwner)
        external
        onlyWallet
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
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

     
    function changeLockSeconds(uint256 _lockSeconds)
        external
        onlyWallet
    {
        lockSeconds = _lockSeconds;
        emit LockSecondsChange(_lockSeconds);
    }

     
    function submitTransaction(address destination, uint256 value, bytes calldata data)
        external
        ownerExists(msg.sender)
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

        if (isConfirmed(transactionId) && unlockTimes[transactionId] == 0 && !isEmergencyCall(transactionId)) {
            uint256 unlockTime = block.timestamp + lockSeconds;
            unlockTimes[transactionId] = unlockTime;
            emit UnlockTimeSet(transactionId, unlockTime);
        }
    }

    function isEmergencyCall(uint256 transactionId)
        internal
        view
        returns (bool)
    {
        bytes memory data = transactions[transactionId].data;

        for (uint256 i = 0; i < emergencyCalls.length; i++) {
            EmergencyCall memory emergencyCall = emergencyCalls[i];

            if (
                data.length == emergencyCall.paramsBytesCount + 4 &&
                data.length >= 4 &&
                emergencyCall.selector[0] == data[0] &&
                emergencyCall.selector[1] == data[1] &&
                emergencyCall.selector[2] == data[2] &&
                emergencyCall.selector[3] == data[3]
            ) {
                return true;
            }
        }

        return false;
    }

     
    function revokeConfirmation(uint256 transactionId)
        external
        ownerExists(msg.sender)
        confirmed(transactionId, msg.sender)
        notExecuted(transactionId)
    {
        confirmations[transactionId][msg.sender] = false;
        emit Revocation(msg.sender, transactionId);
    }

     
    function executeTransaction(uint256 transactionId)
        external
        ownerExists(msg.sender)
        notExecuted(transactionId)
    {
        require(
            block.timestamp >= unlockTimes[transactionId],
            "TRANSACTION_NEED_TO_UNLOCK"
        );

        if (isConfirmed(transactionId)) {
            Transaction storage transaction = transactions[transactionId];
            transaction.executed = true;
            (bool success, ) = transaction.destination.call.value(transaction.value)(transaction.data);
            if (success)
                emit Execution(transactionId);
            else {
                emit ExecutionFailure(transactionId);
                transaction.executed = false;
            }
        }
    }

     
    function isConfirmed(uint256 transactionId)
        public
        view
        returns (bool)
    {
        uint256 count = 0;

        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }

            if (count >= required) {
                return true;
            }
        }

        return false;
    }

     

     
    function getConfirmationCount(uint256 transactionId)
        external
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                count += 1;
            }
        }
    }

     
    function getTransactionCount(bool pending, bool executed)
        external
        view
        returns (uint256 count)
    {
        for (uint256 i = 0; i < transactionCount; i++) {
            if (pending && !transactions[i].executed || executed && transactions[i].executed) {
                count += 1;
            }
        }
    }

     
    function getOwners()
        external
        view
        returns (address[] memory)
    {
        return owners;
    }

     
    function getConfirmations(uint256 transactionId)
        external
        view
        returns (address[] memory _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint256 count = 0;
        uint256 i;

        for (i = 0; i < owners.length; i++) {
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        }

        _confirmations = new address[](count);

        for (i = 0; i < count; i++) {
            _confirmations[i] = confirmationsTemp[i];
        }
    }
}