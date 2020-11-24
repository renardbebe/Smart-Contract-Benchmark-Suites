 

 
 
 
 
 
 

 

 
 
 
 
 
pragma solidity ^0.4.22;

 
contract IToken {
    
    address public whitelist;

    function executeSettingsChange(
        uint amount, 
        uint minimalContribution, 
        uint partContributor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partContributorIncreasePerStage,
        uint maxStages
    );
}


contract MultiSigWallet {

    uint constant public MAX_OWNER_COUNT = 50;
    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isOwner;
    address[] public owners;
    address owner;  
    uint public required;
    uint public transactionCount;

    event Confirmation(address indexed sender, uint indexed transactionId);
    event Revocation(address indexed sender, uint indexed transactionId);
    event Submission(uint indexed transactionId);
    event Execution(uint indexed transactionId);
    event ExecutionFailure(uint indexed transactionId);
    event Deposit(address indexed sender, uint value);
    event OwnerAddition(address indexed owner);
    event OwnerRemoval(address indexed owner);
    event RequirementChange(uint required);
   
    IToken public token;

    struct SettingsRequest {
        uint amount;
        uint minimalContribution;
        uint partContributor;
        uint partProject;
        uint partFounders;
        uint blocksPerStage;
        uint partContributorIncreasePerStage;
        uint maxStages;
        bool executed;
        mapping(address => bool) confirmations;
    }

    uint settingsRequestsCount = 0;
    mapping(uint => SettingsRequest) settingsRequests;

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

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    modifier ownerDoesNotExist(address _owner) {
        require(!isOwner[_owner]);
        _;
    }
    
    modifier ownerExists(address _owner) {
        require(isOwner[_owner]);
        _;
    }

    modifier transactionExists(uint _transactionId) {
        require(transactions[_transactionId].destination != 0);
        _;
    }

    modifier confirmed(uint _transactionId, address _owner) {
        require(confirmations[_transactionId][_owner]);
        _;
    }

    modifier notConfirmed(uint _transactionId, address _owner) {
        require(!confirmations[_transactionId][_owner]);
        _;
    }

    modifier notExecuted(uint _transactionId) {
        require(!transactions[_transactionId].executed);
        _;
    }

    modifier notNull(address _address) {
        require(_address != 0);
        _;
    }

    modifier validRequirement(uint _ownerCount, uint _required) {
        require(_ownerCount < MAX_OWNER_COUNT
            && _required <= _ownerCount
            && _required != 0
            && _ownerCount != 0);
        _;
    }

     
     
     
    constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
        for (uint i=0; i<_owners.length; i++) {
            require(!isOwner[_owners[i]] && _owners[i] != 0);
            isOwner[_owners[i]] = true;
        }
        owners = _owners;
        required = _required;
        owner = msg.sender;
    }

     
    function() public payable {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    function setToken(address _token) public onlyOwner {
        require(token == address(0));
        token = IToken(_token);
    }

     
     
     
    function tgrSettingsChangeRequest(
        uint amount, 
        uint minimalContribution,
        uint partContributor,
        uint partProject, 
        uint partFounders, 
        uint blocksPerStage, 
        uint partContributorIncreasePerStage,
        uint maxStages
    ) 
    public
    ownerExists(msg.sender)
    returns (uint _txIndex) 
    {
        assert(amount*partContributor*partProject*blocksPerStage*partContributorIncreasePerStage*maxStages != 0);  
        assert(amount >= 1 ether);
        _txIndex = settingsRequestsCount;
        settingsRequests[_txIndex] = SettingsRequest({
            amount: amount,
            minimalContribution: minimalContribution,
            partContributor: partContributor,
            partProject: partProject,
            partFounders: partFounders,
            blocksPerStage: blocksPerStage,
            partContributorIncreasePerStage: partContributorIncreasePerStage,
            maxStages: maxStages,
            executed: false
        });
        settingsRequestsCount++;
        confirmSettingsChange(_txIndex);
        return _txIndex;
    }

     
     
    function confirmSettingsChange(uint _txIndex) public ownerExists(msg.sender) returns(bool success) {
        require(settingsRequests[_txIndex].executed == false);
        settingsRequests[_txIndex].confirmations[msg.sender] = true;
        if(isConfirmedSettingsRequest(_txIndex)){
            SettingsRequest storage request = settingsRequests[_txIndex];
            request.executed = true;
            IToken(token).executeSettingsChange(
                request.amount, 
                request.minimalContribution, 
                request.partContributor,
                request.partProject,
                request.partFounders,
                request.blocksPerStage,
                request.partContributorIncreasePerStage,
                request.maxStages
            );
            return true;
        } else {
            return false;
        }
    }

    function setFinishedTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"ce5e6393");
        confirmTransaction(transactionId);
    }

    function setLiveTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"29745306");
        confirmTransaction(transactionId);
    }

    function setFreezeTx() public ownerExists(msg.sender) returns(uint transactionId) {
        transactionId = addTransaction(token, 0, hex"2c8cbe40");
        confirmTransaction(transactionId);
    }

    function transferTx(address _to, uint _value) public ownerExists(msg.sender) returns(uint transactionId) {
         
        bytes memory calldata = new bytes(68); 
        calldata[0] = byte(hex"a9");
        calldata[1] = byte(hex"05");
        calldata[2] = byte(hex"9c");
        calldata[3] = byte(hex"bb");
         
        bytes32 val = bytes32(_value);
        bytes32 dest = bytes32(_to);
         
        for(uint j=0; j<32; j++) {
            calldata[j+4]=dest[j];
        }
         
        for(uint i=0; i<32; i++) {
            calldata[i+36]=val[i];
        }
         
        transactionId = addTransaction(token, 0, calldata);
        confirmTransaction(transactionId);
         
         
    }

    function setWhitelistTx(address _whitelist) public ownerExists(msg.sender) returns(uint transactionId) {
        bytes memory calldata = new bytes(36);
        calldata[0] = byte(hex"85");
        calldata[1] = byte(hex"4c");
        calldata[2] = byte(hex"ff");
        calldata[3] = byte(hex"2f");
        bytes32 dest = bytes32(_whitelist);
        for(uint j=0; j<32; j++) {
            calldata[j+4]=dest[j];
        }
        transactionId = addTransaction(token, 0, calldata);
        confirmTransaction(transactionId);
    }

     
    function whitelistTx(address _address) public ownerExists(msg.sender) returns(uint transactionId) {
        bytes memory calldata = new bytes(36);
        calldata[0] = byte(hex"0a");
        calldata[1] = byte(hex"3b");
        calldata[2] = byte(hex"0a");
        calldata[3] = byte(hex"4f");
        bytes32 dest = bytes32(_address);
        for(uint j=0; j<32; j++) {
            calldata[j+4]=dest[j];
        }
        transactionId = addTransaction(token.whitelist(), 0, calldata);
        confirmTransaction(transactionId);

    }

 

     
     
    function addOwner(address _owner) public onlyWallet ownerDoesNotExist(_owner) notNull(_owner) validRequirement(owners.length + 1, required) {
        isOwner[_owner] = true;
        owners.push(_owner);
        emit OwnerAddition(_owner);
    }
     
     
    function removeOwner(address _owner) public onlyWallet ownerExists(_owner) {
        isOwner[_owner] = false;
        for (uint i=0; i<owners.length - 1; i++)
            if (owners[i] == _owner) {
                owners[i] = owners[owners.length - 1];
                break;
            }
        owners.length -= 1;
        if (required > owners.length)
            changeRequirement(owners.length);
        emit OwnerRemoval(_owner);
    }

     
     
     
    function replaceOwner(address _owner, address _newOwner) public onlyWallet ownerExists(_owner) ownerDoesNotExist(_newOwner) {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == _owner) {
                owners[i] = _newOwner;
                break;
            }
        isOwner[_owner] = false;
        isOwner[_newOwner] = true;
        emit OwnerRemoval(_owner);
        emit OwnerAddition(_newOwner);
    }

     
     
    function changeRequirement(uint _required) public onlyWallet validRequirement(owners.length, _required) {
        required = _required;
        emit RequirementChange(_required);
    }

     
     
     
     
     
    function submitTransaction(address destination, uint value, bytes data) public ownerExists(msg.sender) notNull(destination) returns (uint transactionId) {
        transactionId = addTransaction(destination, value, data);
        confirmTransaction(transactionId);
    }

     
     
     
     
     
    function addTransaction(address destination, uint value, bytes data) internal returns (uint transactionId) {
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

     
     
    function confirmTransaction(uint _transactionId) public ownerExists(msg.sender) transactionExists(_transactionId) notConfirmed(_transactionId, msg.sender) {
        confirmations[_transactionId][msg.sender] = true;
        emit Confirmation(msg.sender, _transactionId);
        executeTransaction(_transactionId);
    }

     
     
     
    function executeTransaction(uint _transactionId) public notExecuted(_transactionId) {
        if (isConfirmed(_transactionId)) {
            Transaction storage trx = transactions[_transactionId];
            trx.executed = true;
             
			bytes memory data = trx.data;
            bytes memory calldata;
            if (trx.data.length >= 4) {
                bytes4 signature;
                assembly {
                    signature := mload(add(data, 32))
                }
                calldata = new bytes(trx.data.length-4);
                for (uint i = 0; i<calldata.length; i++) {
                    calldata[i] = trx.data[i+4];
                }
            }
            else {
                calldata = new bytes(0);
            }
            if (trx.destination.call.value(trx.value)(signature, calldata))
                emit Execution(_transactionId);
            else {
                emit ExecutionFailure(_transactionId);
                trx.executed = false;
            }
        }
    }

     
     
    function revokeConfirmation(uint _transactionId) public ownerExists(msg.sender) confirmed(_transactionId, msg.sender) notExecuted(_transactionId) {
        confirmations[_transactionId][msg.sender] = false;
        emit Revocation(msg.sender, _transactionId);
    }

     
     
     
    function isConfirmed(uint _transactionId) public view returns (bool) {
        uint count = 0;
        for (uint i=0; i<owners.length; i++) {
            if (confirmations[_transactionId][owners[i]])
                count += 1;
            if (count == required)
                return true;
        }
        return false;
    }

	function isConfirmedSettingsRequest(uint _transactionId) public view returns (bool) {
		uint count = 0;
		for (uint i = 0; i < owners.length; i++) {
			if (settingsRequests[_transactionId].confirmations[owners[i]])
				count += 1;
			if (count == required)
				return true;
		}
		return false;
    }

     
    function viewSettingsChange(uint _txIndex) public constant 
    returns (uint amount, uint minimalContribution, uint partContributor, uint partProject, uint partFounders, uint blocksPerStage, uint partContributorIncreasePerStage, uint maxStages) {
        SettingsRequest memory request = settingsRequests[_txIndex];
        return (
            request.amount,
            request.minimalContribution,
            request.partContributor, 
            request.partProject,
            request.partFounders,
            request.blocksPerStage,
            request.partContributorIncreasePerStage,
            request.maxStages
        );
    }

     
     
     
    function getConfirmationCount(uint _transactionId) public view returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (confirmations[_transactionId][owners[i]])
                count += 1;
    }

    function getSettingsChangeConfirmationCount(uint _txIndex) public view returns (uint count) {
        for (uint i=0; i<owners.length; i++)
            if (settingsRequests[_txIndex].confirmations[owners[i]])
                count += 1;
    }

     
     
     
     
    function getTransactionCount(bool pending, bool executed) public view returns (uint count) {
        for (uint i=0; i<transactionCount; i++)
            if (   pending && !transactions[i].executed
                || executed && transactions[i].executed)
                count += 1;
    }

     
     
    function getOwners() public view returns (address[]) {
        return owners;
    }

     
     
     
    function getConfirmations(uint _transactionId) public view returns (address[] _confirmations) {
        address[] memory confirmationsTemp = new address[](owners.length);
        uint count = 0;
        uint i;
        for (i=0; i<owners.length; i++)
            if (confirmations[_transactionId][owners[i]]) {
                confirmationsTemp[count] = owners[i];
                count += 1;
            }
        _confirmations = new address[](count);
        for (i=0; i<count; i++)
            _confirmations[i] = confirmationsTemp[i];
    }

     
     
     
     
     
     
    function getTransactionIds(uint from, uint to, bool pending, bool executed) public view returns (uint[] _transactionIds) {
        uint[] memory transactionIdsTemp = new uint[](transactionCount);
        uint count = 0;
        uint i;
        for (i=from; i<transactionCount; i++)
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