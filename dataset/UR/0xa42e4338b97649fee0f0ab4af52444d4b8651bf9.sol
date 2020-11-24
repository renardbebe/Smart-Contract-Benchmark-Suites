 

pragma solidity ^0.4.18;

contract MultiSigERC20Token
{
    uint constant public MAX_OWNER_COUNT = 50;
	
     
    string public name;
    string public symbol;
    uint8 public decimals = 8;
    uint256 public totalSupply;
	address[] public owners;
	address[] public admins;
	
	 
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
    event AdminAddition(address indexed admin);
    event AdminRemoval(address indexed admin);
    event RequirementChange(uint required);
	
	 
    mapping (uint => MetaTransaction) public transactions;
    mapping (address => uint256) public withdrawalLimit;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
	mapping (address => bool) public frozenAccount;
	mapping (address => bool) public isAdmin;
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
    
    modifier adminDoesNotExist(address admin) {
        require (!isAdmin[admin]);
        _;
    }

    modifier ownerExists(address owner) {
        require (isOwner[owner]);
        _;
    }
    
    modifier adminExists(address admin) {
        require (isAdmin[admin] || isOwner[admin]);
        _;
    }

    modifier transactionExists(uint transactionId) {
        require (transactions[transactionId].operation != 0);
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
            Deposit(msg.sender, msg.value);
        }
    }

     
    function MultiSigERC20Token(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);   
        balanceOf[this] = totalSupply;                       
        name = tokenName;                                    
        symbol = tokenSymbol;                                
		isOwner[msg.sender] = true;                          
		isAdmin[msg.sender] = true;
		required = 1;
		owners.push(msg.sender);
		admins.push(msg.sender);
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
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }
	
	
     
     
     
    function freezeAccount(address target, bool freeze) internal {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }
	
     
     
    function addOwner(address owner)
        internal
        ownerDoesNotExist(owner)
        notNull(owner)
    {
        isOwner[owner] = true;
        owners.push(owner);
        required = required + 1;
        OwnerAddition(owner);
    }
    
     
     
    function addAdmin(address admin)
        internal
        adminDoesNotExist(admin)
        notNull(admin)
    {
        isAdmin[admin] = true;
        admins.push(admin);
        AdminAddition(admin);
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
        OwnerRemoval(owner);
    }
    
    
     
     
    function removeAdmin(address admin)
        internal
        adminExists(admin)
    {
        isAdmin[admin] = false;
        for (uint i=0; i<admins.length - 1; i++)
            if (admins[i] == admin) {
                admins[i] = admins[admins.length - 1];
                break;
            }
        admins.length -= 1;
        AdminRemoval(admin);
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
        OwnerRemoval(owner);
        OwnerAddition(newOwner);
    }

     
     
    function changeRequirement(uint256 _required)
        internal
    {
        required = _required;
        RequirementChange(_required);
    }
    
    function requestAddOwner(address newOwner, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(newOwner,newOwner,0,1,reason);
    }

    function requestRemoveOwner(address oldOwner, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(oldOwner,oldOwner,0,2,reason);
    }
    
    function requestReplaceOwner(address oldOwner,address newOwner, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(oldOwner,newOwner,0,3,reason);
    }
    
    function requestFreezeAccount(address account, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(account,account,0,4,reason);
    }
    
    function requestUnFreezeAccount(address account, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(account,account,0,5,reason);
    }
    
    function requestChangeRequirement(uint _requirement, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(msg.sender,msg.sender,_requirement,6,reason);
    }
    
    function requestTokenIssue(address account, uint256 amount, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(account,account,amount,7,reason);
    }
    
    function requestAdminTokenTransfer(address source,address destination, uint256 amount, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(source, destination, amount,8,reason);
    }
    
    function requestSetWithdrawalLimit(address owner,uint256 amount, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(owner, owner, amount,9,reason);
    }
    
    function requestWithdrawalFromLimit(uint256 amount, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(msg.sender, msg.sender, amount,10,reason);
    }
    
    function requestWithdrawal(address account,uint256 amount, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(account, account, amount,11,reason);
    }
    
    function requestAddAdmin(address account, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(account, account, 0,12,reason);
    }
    
    function requestRemoveAdmin(address account, string reason) public adminExists(msg.sender) returns (uint transactionId)
    {
        transactionId = submitTransaction(account, account, 0,13,reason);
    }
    
     
     
     
     
    function submitTransaction(address source, address destination, uint256 value, uint operation, string reason)
        internal
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
            Submission(transactionId,"Add Owner", source, destination, value, reason);
        }
        else if(operation == 2)  
        {
            Submission(transactionId,"Remove Owner", source, destination, value, reason);
        }
        else if(operation == 3)  
        {
            Submission(transactionId,"Replace Owner", source, destination, value, reason);
        }
        else if(operation == 4)  
        {
            Submission(transactionId,"Freeze Account", source, destination, value, reason);
        }
        else if(operation == 5)  
        {
            Submission(transactionId,"UnFreeze Account", source, destination, value, reason);
        }
        else if(operation == 6)  
        {
            Submission(transactionId,"Change Requirement", source, destination, value, reason);
        }
        else if(operation == 7)  
        {
            Submission(transactionId,"Issue Tokens", source, destination, value, reason);
        }
        else if(operation == 8)  
        {
            Submission(transactionId,"Admin Transfer Tokens", source, destination, value, reason);
        }
        else if(operation == 9)  
        {
            Submission(transactionId,"Set Unsigned Ethereum Withdrawal Limit", source, destination, value, reason);
        }
        else if(operation == 10)  
        {
            require(isOwner[destination]);
            require(withdrawalLimit[destination] > value);
            
            Submission(transactionId,"Unsigned Ethereum Withdrawal", source, destination, value, reason);
            
            var newValue = withdrawalLimit[destination] - value;
            withdrawalLimit[destination] = newValue;
            
            destination.transfer(value);
            transactions[transactionId].executed = true;
            Execution(transactionId);
        }
        else if(operation == 11)  
        {
            Submission(transactionId,"Withdraw Ethereum", source, destination, value, reason);
        }
        else if(operation == 12)  
        {
            Submission(transactionId,"Add Admin", source, destination, value, reason);
        }
        else if(operation == 13)  
        {
            Submission(transactionId,"Remove Admin", source, destination, value, reason);
        }
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
    
     
     
     
    function confirmMultipleTransactions(uint startTransactionId, uint endTransactionId)
        public
        ownerExists(msg.sender)
        transactionExists(endTransactionId)
    {
        for(var i=startTransactionId;i<=endTransactionId;i++)
        {
            require(transactions[i].operation != 0);
            require(!confirmations[i][msg.sender]);
            confirmations[i][msg.sender] = true;
            Confirmation(msg.sender, i);
            executeTransaction(i);
        }
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
        internal
        notExecuted(transactionId)
    {
        if (isConfirmed(transactionId)) {
            var transaction = transactions[transactionId];

            if(transaction.operation == 1)  
            {
                addOwner(transaction.destination);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 2)  
            {
                removeOwner(transaction.destination);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 3)  
            {
                replaceOwner(transaction.source,transaction.destination);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 4)  
            {
                freezeAccount(transaction.destination,true);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 5)  
            {
                freezeAccount(transaction.destination, false);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 6)  
            {
                changeRequirement(transaction.value);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 7)  
            {
                _transfer(this,transaction.destination,transaction.value);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 8)  
            {
                _transfer(transaction.source,transaction.destination,transaction.value);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 9)  
            {
                require(isOwner[transaction.destination]);
                withdrawalLimit[transaction.destination] = transaction.value;
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 11)  
            {
                require(isOwner[transaction.destination]);
                
                transaction.destination.transfer(transaction.value);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 12)  
            {
                addAdmin(transaction.destination);
                
                transaction.executed = true;
                Execution(transactionId);
            }
            else if(transaction.operation == 13)  
            {
                removeAdmin(transaction.destination);
                
                transaction.executed = true;
                Execution(transactionId);
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