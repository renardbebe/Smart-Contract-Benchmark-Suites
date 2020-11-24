 

contract MultiSigERC20Token
{
    uint constant public MAX_OWNER_COUNT = 50;
	
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
	address[] public owners;
	
	 
	uint256 public required;
    uint public transactionCount;

     
    event Transfer(address indexed from, address indexed to, uint256 value);
    event FrozenFunds(address target, bool frozen);
	event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId,string operation, address source, address destination, uint256 value, string reason);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
	
	 
    mapping (uint => MetaTransaction) public transactions;
    mapping (address => uint256) public withdrawalLimit;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
	mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public balanceOf;

     
    struct MetaTransaction {
        address source;
        address destination;
        uint value;
        bool executed;
        uint operation;
        string reason;
    }

     

    modifier ownerDoesNotExist(address owner) {
        require (!isOwner[owner]);
        _;
    }

    modifier ownerExists(address owner) {
        require (isOwner[owner]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require (transactions[transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint transactionId, address owner) {
        require (confirmations[transactionId][owner]);
        _;
    }

    modifier notConfirmed(uint transactionId, address owner) {
        require (!confirmations[transactionId][owner]);
        _;
    }

    modifier notExecuted(uint transactionId) {
        require (!transactions[transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require (_address != 0);
        _;
    }

     
    function() payable public
    {
        if (msg.value > 0)
        {
            emit Deposit(msg.sender, msg.value);
        }
    }

     
   constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[this] = totalSupply;                       
        name = tokenName;                                    
        symbol = tokenSymbol;                                
		isOwner[msg.sender] = true;                          
		required = 1;
		owners.push(msg.sender);
    }

     
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != 0x0);
         
        require(balanceOf[_from] >= _value);
         
        require(!frozenAccount[_from]);
         
        require(!frozenAccount[_to]);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
         
        balanceOf[_from] -= _value;
         
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
	
	
     
     
     
    function freezeAccount(address target, bool freeze) internal {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }
	
     
     
    function addOwner(address owner)
        internal
        ownerDoesNotExist(owner)
        notNull(owner)
    {
        isOwner[owner] = true;
        owners.push(owner);
        required = required + 1;
        emit OwnerAddition(owner);
    }

     
     
    function removeOwner(address owner)
        internal
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
        internal
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

     
     
    function changeRequirement(uint256 _required)
        internal
    {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
    function submitTransaction(address source, address destination, uint256 value, uint operation, string reason)
        public
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = MetaTransaction({
            source: source,
            destination: destination,
            value: value,
            operation: operation,
            executed: false,
            reason: reason
        });
        
        transactionCount += 1;
        
        if(operation == 1)  
        {
            emit Submission(transactionId,"Add Owner", source, destination, value, reason);
        }
        else if(operation == 2)  
        {
            emit Submission(transactionId,"Remove Owner", source, destination, value, reason);
        }
        else if(operation == 3)  
        {
            emit Submission(transactionId,"Replace Owner", source, destination, value, reason);
        }
        else if(operation == 4)  
        {
            emit Submission(transactionId,"Freeze Account", source, destination, value, reason);
        }
        else if(operation == 5)  
        {
            emit Submission(transactionId,"UnFreeze Account", source, destination, value, reason);
        }
        else if(operation == 6)  
        {
            emit Submission(transactionId,"Change Requirement", source, destination, value, reason);
        }
        else if(operation == 7)  
        {
            emit Submission(transactionId,"Issue Tokens", source, destination, value, reason);
        }
        else if(operation == 8)  
        {
            emit Submission(transactionId,"Admin Transfer Tokens", source, destination, value, reason);
        }
        else if(operation == 9)  
        {
            emit Submission(transactionId,"Set Unsigned Ethereum Withdrawal Limit", source, destination, value, reason);
        }
        else if(operation == 10)  
        {
            emit Submission(transactionId,"Unsigned Ethereum Withdrawal", source, destination, value, reason);
        }
        else if(operation == 11)  
        {
            emit Submission(transactionId,"Withdraw Ethereum", source, destination, value, reason);
        }
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
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            MetaTransaction storage transaction = transactions[transactionId];

            if(transaction.operation == 1)  
            {
                addOwner(transaction.destination);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 2)  
            {
                removeOwner(transaction.destination);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 3)  
            {
                replaceOwner(transaction.source,transaction.destination);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 4)  
            {
                freezeAccount(transaction.destination,true);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 5)  
            {
                freezeAccount(transaction.destination, false);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 6)  
            {
                changeRequirement(transaction.value);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 7)  
            {
                _transfer(this,transaction.destination,transaction.value);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 8)  
            {
                _transfer(transaction.source,transaction.destination,transaction.value);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 9)  
            {
                require(isOwner[transaction.destination]);
                withdrawalLimit[transaction.destination] = transaction.value;
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
            else if(transaction.operation == 11)  
            {
                require(isOwner[transaction.destination]);
                
                transaction.destination.transfer(transaction.value);
                
                transaction.executed = true;
                emit Execution(transactionId);
            }
        }
        else if(transaction.operation == 10)  
        {
            require(isOwner[transaction.destination]);
            require(withdrawalLimit[transaction.destination] <= transaction.value);
            
            withdrawalLimit[transaction.destination] -= transaction.value;
            
            assert(withdrawalLimit[transaction.destination] > 0);
            
            transaction.destination.transfer(transaction.value);
            transaction.executed = true;
            emit Execution(transactionId);
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