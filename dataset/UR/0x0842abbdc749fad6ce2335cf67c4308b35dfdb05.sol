 

pragma solidity ^0.4.24;

 
contract MarketplaceProxy {
    function calculatePlatformCommission(uint256 weiAmount) public view returns (uint256);
    function payPlatformIncomingTransactionCommission(address clientAddress) public payable;
    function payPlatformOutgoingTransactionCommission() public payable;
    function isUserBlockedByContract(address contractAddress) public view returns (bool);
}
 

 
 
contract Fund {

     
    event Confirmation(address sender, uint256 transactionId);
    event Revocation(address sender, uint256 transactionId);
    event Submission(uint256 transactionId);
    event Execution(uint256 transactionId);
    event ExecutionFailure(uint256 transactionId);
    event OwnerAddition(address owner);
    event OwnerRemoval(address owner);
    event RequirementChange(uint256 required);
    event MemberAdded(address member);
    event MemberBlocked(address member);
    event MemberUnblocked(address member);
    event FeeAmountChanged(uint256 feeAmount);
    event NextMemberPaymentAdded(address member, uint256 expectingAmount, uint256 platformCommission);
    event NextMemberPaymentUpdated(address member, uint256 expectingAmount, uint256 platformCommission);
    event IncomingPayment(address sender, uint256 value);
    event Claim(address to, uint256 value);
    event Transfer(address to, uint256 value);

     
    uint256 constant public MAX_OWNER_COUNT = 50;

     
    mapping (uint256 => Transaction) public transactions;
    mapping (uint256 => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    mapping (address => Member) public members;
    mapping (address => NextMemberPayment) public nextMemberPayments;
    address[] public owners;
    address public creator;
    uint256 public required;
    uint256 public transactionCount;
    uint256 public feeAmount;    
    struct Transaction {
        address destination;
        uint256 value;
        bytes data;
        bool executed;
    }
    struct Member {
        bool exists;
        bool blocked;
    }
    struct NextMemberPayment {
        bool exists;
        uint256 expectingValue;        
        uint256 platformCommission;    
    }

     
    MarketplaceProxy public mp;
    event PlatformIncomingTransactionCommission(uint256 amount, address clientAddress);
    event PlatformOutgoingTransactionCommission(uint256 amount);
    event Blocked();
     

     
    modifier ownerDoesNotExist(address owner) {
        require(!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require(isOwner[owner]);
        _;
    }

    modifier transactionExists(uint256 transactionId) {
        require(transactions[transactionId].destination != 0);
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
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint256 ownerCount, uint256 _required) {
        require(ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required != 0
            && ownerCount != 0);
        _;
    }

     
    modifier onlyCreator() {
        require(msg.sender == creator);
        _;
    }

     
    modifier memberExists(address member) {
        require(members[member].exists);
        _;
    }

     
    modifier memberDoesNotExist(address member) {
        require(!members[member].exists);
        _;
    }

     
    modifier nextMemberPaymentExists(address member) {
        require(nextMemberPayments[member].exists);
        _;
    }

     
    modifier nextMemberPaymentDoesNotExist(address member) {
        require(!nextMemberPayments[member].exists);
        _;
    }

     
    function()
        public
        payable
    {
        handleIncomingPayment(msg.sender);
    }

     
    function fromPaymentGateway(address member)
        public
        memberExists(member)
        nextMemberPaymentExists(member)
        payable
    {
        handleIncomingPayment(member);
    }

     
    function handleIncomingPayment(address member)
        private
    {
        if (nextMemberPayments[member].exists) {
            NextMemberPayment storage nextMemberPayment = nextMemberPayments[member];

            require(nextMemberPayment.expectingValue == msg.value);

             
             
            if (mp.isUserBlockedByContract(address(this))) {
                mp.payPlatformIncomingTransactionCommission.value(msg.value)(member);
                emit Blocked();
            } else {
                mp.payPlatformIncomingTransactionCommission.value(nextMemberPayment.platformCommission)(member);
                emit PlatformIncomingTransactionCommission(nextMemberPayment.platformCommission, member);
            }
             
        }

        emit IncomingPayment(member, msg.value);
    }

     
    function addEth()
        public
        onlyCreator
        payable
    {

    }

     
     
    constructor()
        public
    {
        required = 1;            
        creator = msg.sender;

         
         
        mp = MarketplaceProxy(0x7b71342582610452641989D599a684501922Cb57);
         

    }

     
     
    function addOwner(address owner)
        public
        onlyCreator
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
        onlyCreator
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
        onlyCreator
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
        onlyCreator
        validRequirement(owners.length, _required)
    {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
    function initTransaction(address destination, uint256 value)
        public
        onlyCreator
        returns (uint256 transactionId)
    {
        transactionId = addTransaction(destination, value);
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

     
     
    function external_call(address destination, uint256 value, uint256 dataLength, bytes data) private returns (bool) {
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

     
    function blockMember(address member)
        public
        onlyCreator
        memberExists(member)
    {
        members[member].blocked = true;
        emit MemberBlocked(member);
    }

     
    function unblockMember(address member)
        public
        onlyCreator
        memberExists(member)
    {
        members[member].blocked = false;
        emit MemberUnblocked(member);
    }

     
    function isMemberBlocked(address member)
        public
        view
        memberExists(member)
        returns (bool)
    {
        return members[member].blocked;
    }

     
    function addMember(address member)
        public
        onlyCreator
        notNull(member)
        memberDoesNotExist(member)
    {
        members[member] = Member(
            true,    
            false    
        );
        emit MemberAdded(member);
    }

     
    function setFeeAmount(uint256 _feeAmount)
        public
        onlyCreator
    {
        feeAmount = _feeAmount;
        emit FeeAmountChanged(_feeAmount);
    }

     
    function addNextMemberPayment(address member, uint256 expectingValue, uint256 platformCommission)
        public
        onlyCreator
        memberExists(member)
        nextMemberPaymentDoesNotExist(member)
    {
        nextMemberPayments[member] = NextMemberPayment(
            true,
            expectingValue,
            platformCommission
        );
        emit NextMemberPaymentAdded(member, expectingValue, platformCommission);
    }

     
    function updateNextMemberPayment(address member, uint256 _expectingValue, uint256 _platformCommission)
        public
        onlyCreator
        memberExists(member)
        nextMemberPaymentExists(member)
    {
        nextMemberPayments[member].expectingValue = _expectingValue;
        nextMemberPayments[member].platformCommission = _platformCommission;
        emit NextMemberPaymentUpdated(member, _expectingValue, _platformCommission);
    }

     
    function claim(address to, uint256 amount)
        public
        onlyCreator
        memberExists(to)
    {
         
         
        uint256 commission = mp.calculatePlatformCommission(amount);
        require(address(this).balance > (amount + commission));

         
        mp.payPlatformOutgoingTransactionCommission.value(commission)();
        emit PlatformOutgoingTransactionCommission(commission);
         

        to.transfer(amount);

        emit Claim(to, amount);
    }

     
    function transfer(address to, uint256 amount)
        public
        onlyCreator
        ownerExists(to)
    {
         
        require(address(this).balance > amount);
         

        to.transfer(amount);

        emit Transfer(to, amount);
    }

     
     
     
     
     
    function addTransaction(address destination, uint256 value)
        internal
        notNull(destination)
        returns (uint256 transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            data: "",
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
        returns (address[])
    {
        return owners;
    }

     
     
     
    function getConfirmations(uint256 transactionId)
        public
        view
        returns (address[] _confirmations)
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
        returns (uint[] _transactionIds)
    {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint256 count = 0;
        uint256 i;
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