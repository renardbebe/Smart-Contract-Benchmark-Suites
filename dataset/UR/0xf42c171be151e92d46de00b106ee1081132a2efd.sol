 

pragma solidity 0.4.24;

interface tokenInterface {
    function transfer(address reciever, uint amount) external;
    function balanceOf(address owner) external returns (uint256);
}

contract dapMultisig {

     
    struct Transaction {
        uint id;
        address destination;
        uint value;
        bytes data;
        TxnStatus status;
        address[] confirmed;
        address creator;
    }
    
    struct tokenTransaction {
        uint id;
        tokenInterface token;
        address reciever;
        uint value;
        address[] confirmed;
        TxnStatus status;
        address creator;
    }
    
    struct Log {
        uint amount;
        address sender;
    }
    
    enum TxnStatus { Unconfirmed, Pending, Executed }
    
     
    modifier onlyOwner () {
        bool found;
        for (uint i = 0;i<owners.length;i++){
            if (owners[i] == msg.sender){
                found = true;
            }
        }
        if (found){
            _;
        }
    }
    
     
    event WalletCreated(address creator, address[] owners);
    event TxnSumbitted(uint id);
    event TxnConfirmed(uint id);
    event topUpBalance(uint value);
    event tokenTxnConfirmed(uint id, address owner);
    event tokenTxnExecuted(address token, uint256 value, address reciever);
     
    bytes32 public name;
    address public creator;
    uint public allowance;
    address[] public owners;
    Log[] logs;
    Transaction[] transactions;
    tokenTransaction[] tokenTransactions;
    uint public approvalsreq;
    
     
    constructor (uint _approvals, address[] _owners, bytes32 _name) public payable{
         
        require(_name.length != 0);
        
         
        require(_approvals <= _owners.length);
        
        name = _name;
        creator = msg.sender;
        allowance = msg.value;
        owners = _owners;
        approvalsreq = _approvals;
        emit WalletCreated(msg.sender, _owners);
    }

     
    function () external payable {
        allowance += msg.value;
    }
    
     

    function getOwners() external view returns (address[]){
        return owners;
    }
    
    function getTxnNum() external view returns (uint){
        return transactions.length;
    }
    
    function getTxn(uint _id) external view returns (uint, address, uint, bytes, TxnStatus, address[], address){
        Transaction storage txn = transactions[_id];
        return (txn.id, txn.destination, txn.value, txn.data, txn.status, txn.confirmed, txn.creator);
    }
    
    function getLogsNum() external view returns (uint){
        return logs.length;
    }
    
    function getLog(uint logId) external view returns (address, uint){
        return(logs[logId].sender, logs[logId].amount);
    }
    
    function getTokenTxnNum() external view returns (uint){
        return tokenTransactions.length;
    }
    
    function getTokenTxn(uint _id) external view returns(uint, address, address, uint256, address[], TxnStatus, address){
        tokenTransaction storage txn = tokenTransactions[_id];
        return (txn.id, txn.token, txn.reciever, txn.value, txn.confirmed, txn.status, txn.creator);
    }
    
     

    function topBalance() external payable {
        require (msg.value > 0 wei);
        allowance += msg.value;
        
         
        uint loglen = logs.length++;
        logs[loglen].amount = msg.value;
        logs[loglen].sender = msg.sender;
        emit topUpBalance(msg.value);
    }
    
    function submitTransaction(address _destination, uint _value, bytes _data) onlyOwner () external returns (bool) {
        uint newTxId = transactions.length++;
        transactions[newTxId].id = newTxId;
        transactions[newTxId].destination = _destination;
        transactions[newTxId].value = _value;
        transactions[newTxId].data = _data;
        transactions[newTxId].creator = msg.sender;
        transactions[newTxId].confirmed.push(msg.sender);
        if (transactions[newTxId].confirmed.length == approvalsreq){
            transactions[newTxId].status = TxnStatus.Pending;
        }
        emit TxnSumbitted(newTxId);
        return true;
    }

    function confirmTransaction(uint txId) onlyOwner() external returns (bool){
        Transaction storage txn = transactions[txId];

         
        bool f;
        for (uint8 i = 0; i<txn.confirmed.length;i++){
            if (txn.confirmed[i] == msg.sender){
                f = true;
            }
        }
         
        require(!f);
        txn.confirmed.push(msg.sender);
        
        if (txn.confirmed.length == approvalsreq){
            txn.status = TxnStatus.Pending;
        }
        
         
        emit TxnConfirmed(txId);
        
        return true;
    }
    
    function executeTxn(uint txId) onlyOwner() external returns (bool){
        
        Transaction storage txn = transactions[txId];
        
         
        require(txn.status == TxnStatus.Pending);
        
         
        require(allowance >= txn.value);
        
         
        address dest = txn.destination;
        uint val = txn.value;
        bytes memory dat = txn.data;
        assert(dest.call.value(val)(dat));
            
         
        txn.status = TxnStatus.Executed;

         
        allowance = allowance - txn.value;

        return true;
        
    }
    
    function submitTokenTransaction(address _tokenAddress, address _receiever, uint _value) onlyOwner() external returns (bool) {
        uint newTxId = tokenTransactions.length++;
        tokenTransactions[newTxId].id = newTxId;
        tokenTransactions[newTxId].token = tokenInterface(_tokenAddress);
        tokenTransactions[newTxId].reciever = _receiever;
        tokenTransactions[newTxId].value = _value;
        tokenTransactions[newTxId].confirmed.push(msg.sender);
        if (tokenTransactions[newTxId].confirmed.length == approvalsreq){
            tokenTransactions[newTxId].status = TxnStatus.Pending;
        }
        emit TxnSumbitted(newTxId);
        return true;
    }
    
    function confirmTokenTransaction(uint txId) onlyOwner() external returns (bool){
        tokenTransaction storage txn = tokenTransactions[txId];

         
        bool f;
        for (uint8 i = 0; i<txn.confirmed.length;i++){
            if (txn.confirmed[i] == msg.sender){
                f = true;
            }
        }
         
        require(!f);
        txn.confirmed.push(msg.sender);
        
        if (txn.confirmed.length == approvalsreq){
            txn.status = TxnStatus.Pending;
        }
        
         
        emit tokenTxnConfirmed(txId, msg.sender);
        
        return true;
    }
    
    function executeTokenTxn(uint txId) onlyOwner() external returns (bool){
        
        tokenTransaction storage txn = tokenTransactions[txId];
        
         
        require(txn.status == TxnStatus.Pending);
        
         
        uint256 balance = txn.token.balanceOf(address(this));
        require (txn.value <= balance);
        
         
        txn.token.transfer(txn.reciever, txn.value);
        
         
        txn.status = TxnStatus.Executed;
        
         
        emit tokenTxnExecuted(address(txn.token), txn.value, txn.reciever);
       
        return true;
    }
}