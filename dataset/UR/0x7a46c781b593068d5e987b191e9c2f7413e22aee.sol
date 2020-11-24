 

pragma solidity 0.4.19;

interface token {
    function transfer(address _to, uint256 _value) public;
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
    event EthDailyLimitChange(uint limit);
    event MtcDailyLimitChange(uint limit);
    event TokenChange(address _token);
     
    uint constant public MAX_OWNER_COUNT = 10;
     
    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    mapping(address => bool) public isOwner;
    address[] public owners;
    uint public required;
    uint public transactionCount;
    uint public ethDailyLimit;
    uint public mtcDailyLimit;
    uint public dailySpent;
    uint public mtcDailySpent;
    uint public lastDay;
    uint public mtcLastDay;
    token public MTC;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        string description;
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
    modifier validDailyEthLimit(uint _limit) {
        require(_limit >= 0);
        _;
    }
    modifier validDailyMTCLimit(uint _limit) {
        require(_limit >= 0);
        _;
    }
     
    function()
    payable public
    {
        if (msg.value > 0)
            Deposit(msg.sender, msg.value);
    }
     
     
     
     
    function MultiSigWallet(address[] _owners, uint _required, uint _ethDailyLimit, uint _mtcDailyLimit)
    public
    validRequirement(_owners.length, _required)
    {
        for (uint i = 0; i < _owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        ethDailyLimit = _ethDailyLimit * 1 ether;
        mtcDailyLimit = _mtcDailyLimit * 1 ether;
        lastDay = toDays(now);
        mtcLastDay = toDays(now);
    }

    function toDays(uint _time) pure internal returns (uint) {
        return _time / (60 * 60 * 24);
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
        for (uint i = 0; i < owners.length - 1; i++)
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
        for (uint i = 0; i < owners.length; i++)
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

     
     
    function changeEthDailyLimit(uint _limit)
    public
    onlyWallet
    validDailyEthLimit(_limit)
    {
        ethDailyLimit = _limit;
        EthDailyLimitChange(_limit);
    }

     
     
    function changeMtcDailyLimit(uint _limit)
    public
    onlyWallet
    validDailyMTCLimit(_limit)
    {
        mtcDailyLimit = _limit;
        MtcDailyLimitChange(_limit);
    }

     
     
    function setToken(address _token)
    public
    onlyWallet
    {
        MTC = token(_token);
        TokenChange(_token);
    }

     
     
     
     
     
     
    function submitTransaction(address destination, uint value, string description, bytes data)
    public
    returns (uint transactionId)
    {
        transactionId = addTransaction(destination, value, description, data);
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
     
     
     
    function softEthTransfer(address _to, uint _value)
    public
    ownerExists(msg.sender)
    {
        require(_value > 0);
        _value *= 1 finney;
        if (lastDay != toDays(now)) {
            dailySpent = 0;
            lastDay = toDays(now);
        }
        require((dailySpent + _value) <= ethDailyLimit);
        if (_to.send(_value)) {
            dailySpent += _value;
        } else {
            revert();
        }
    }

     
     
     
    function softMtcTransfer(address _to, uint _value)
    public
    ownerExists(msg.sender)
    {
        require(_value > 0);
        _value *= 1 ether;
        if (mtcLastDay != toDays(now)) {
            mtcDailySpent = 0;
            mtcLastDay = toDays(now);
        }
        require((mtcDailySpent + _value) <= mtcDailyLimit);
        MTC.transfer(_to, _value);
        mtcDailySpent += _value;

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
                Execution(transactionId);
            else {
                ExecutionFailure(transactionId);
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
            if (count == required)
                return true;
        }
    }
     
     
     
     
     
     
     
    function addTransaction(address destination, uint value, string description, bytes data)
    internal
    notNull(destination)
    returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination : destination,
            value : value,
            description : description,
            data : data,
            executed : false
            });
        transactionCount += 1;
        Submission(transactionId);
    }
     
     
     
     
    function getTransactionDescription(uint transactionId)
    public
    constant
    returns (string description)
    {
        Transaction storage txn = transactions[transactionId];
        return txn.description;
    }
     
     
     
    function getConfirmationCount(uint transactionId)
    public
    constant
    returns (uint count)
    {
        for (uint i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]])
                count += 1;
    }
     
     
     
     
    function getTransactionCount(bool pending, bool executed)
    public
    constant
    returns (uint count)
    {
        for (uint i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
                count += 1;
    }
     
     
     
    function getConfirmations(uint transactionId)
    public
    constant
    returns (address[] _confirmations)
    {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i = 0; i < owners.length; i++)
            if (confirmations[transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i = 0; i < count; i++)
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
        for (i = 0; i < transactionCount; i++)
            if (pending && !transactions[i].executed
            || executed && transactions[i].executed)
            {
                transactionIdsTemp[count] = i;
                count += 1;
            }
        _transactionIds = new uint[](to - from);
        for (i = from; i < to; i++)
            _transactionIds[i - from] = transactionIdsTemp[i];
    }
}