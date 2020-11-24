 

pragma solidity ^0.4.21;
contract ibaMultisig {

     
    struct Transaction {
        uint id;
        address destination;
        uint value;
        bytes data;
        TxnStatus status;
        address[] confirmed;
        address creator;
    }

    struct Wallet {
        bytes32 name;
        address creator;
        uint id;
        uint allowance;
        address[] owners;
        Log[] logs;
        Transaction[] transactions;
        uint appovalsreq;
    }
    
    struct Log {
        uint amount;
        address sender;
    }
    
    enum TxnStatus { Unconfirmed, Pending, Executed }
    
     
    modifier onlyOwner ( address creator, uint walletId ) {
        bool found;
        for (uint i = 0;i<wallets[creator][walletId].owners.length;i++){
            if (wallets[creator][walletId].owners[i] == msg.sender){
                found = true;
            }
        }
        if (found){
            _;
        }
    }
    
     
    event WalletCreated(uint id);
    event TxnSumbitted(uint id);
    event TxnConfirmed(uint id);
    event topUpBalance(uint value);

     
    mapping (address => Wallet[]) public wallets;
    
     
    function ibaMultisig() public{

    }

     
    function getWalletId(address creator, bytes32 name) external view returns (uint, bool){
        for (uint i = 0;i<wallets[creator].length;i++){
            if (wallets[creator][i].name == name){
                return (i, true);
            }
        }
    }

    function getOwners(address creator, uint id) external view returns (address[]){
        return wallets[creator][id].owners;
    }
    
    function getTxnNum(address creator, uint id) external view returns (uint){
        require(wallets[creator][id].owners.length > 0);
        return wallets[creator][id].transactions.length;
    }
    
    function getTxn(address creator, uint walletId, uint id) external view returns (uint, address, uint, bytes, TxnStatus, address[], address){
        Transaction storage txn = wallets[creator][walletId].transactions[id];
        return (txn.id, txn.destination, txn.value, txn.data, txn.status, txn.confirmed, txn.creator);
    }
    
    function getLogsNum(address creator, uint id) external view returns (uint){
        return wallets[creator][id].logs.length;
    }
    
    function getLog(address creator, uint id, uint logId) external view returns (address, uint){
        return(wallets[creator][id].logs[logId].sender, wallets[creator][id].logs[logId].amount);
    }
    
     
    
    function createWallet(uint approvals, address[] owners, bytes32 name) external payable{

         
        require(name.length != 0);
        
         
        require(approvals <= owners.length);
        
         
        bool found;
        for (uint i = 0; i<wallets[msg.sender].length;i++){
            if (wallets[msg.sender][i].name == name){
                found = true;
            }
        }
        require (found == false);
        
         
        uint currentLen = wallets[msg.sender].length++;
        wallets[msg.sender][currentLen].name = name;
        wallets[msg.sender][currentLen].creator = msg.sender;
        wallets[msg.sender][currentLen].id = currentLen;
        wallets[msg.sender][currentLen].allowance = msg.value;
        wallets[msg.sender][currentLen].owners = owners;
        wallets[msg.sender][currentLen].appovalsreq = approvals;
        emit WalletCreated(currentLen);
    }

    function topBalance(address creator, uint id) external payable {
        require (msg.value > 0 wei);
        wallets[creator][id].allowance += msg.value;
        
         
        uint loglen = wallets[creator][id].logs.length++;
        wallets[creator][id].logs[loglen].amount = msg.value;
        wallets[creator][id].logs[loglen].sender = msg.sender;
        emit topUpBalance(msg.value);
    }
    
    function submitTransaction(address creator, address destination, uint walletId, uint value, bytes data) onlyOwner (creator,walletId) external returns (bool) {
        uint newTxId = wallets[creator][walletId].transactions.length++;
        wallets[creator][walletId].transactions[newTxId].id = newTxId;
        wallets[creator][walletId].transactions[newTxId].destination = destination;
        wallets[creator][walletId].transactions[newTxId].value = value;
        wallets[creator][walletId].transactions[newTxId].data = data;
        wallets[creator][walletId].transactions[newTxId].creator = msg.sender;
        emit TxnSumbitted(newTxId);
        return true;
    }

    function confirmTransaction(address creator, uint walletId, uint txId) onlyOwner(creator, walletId) external returns (bool){
        Wallet storage wallet = wallets[creator][walletId];
        Transaction storage txn = wallet.transactions[txId];

         
        bool f;
        for (uint8 i = 0; i<txn.confirmed.length;i++){
            if (txn.confirmed[i] == msg.sender){
                f = true;
            }
        }
         
        require(!f);
        txn.confirmed.push(msg.sender);
        
        if (txn.confirmed.length == wallet.appovalsreq){
            txn.status = TxnStatus.Pending;
        }
        
         
        emit TxnConfirmed(txId);
        
        return true;
    }
    
    function executeTxn(address creator, uint walletId, uint txId) onlyOwner(creator, walletId) external returns (bool){
        Wallet storage wallet = wallets[creator][walletId];
        
        Transaction storage txn = wallet.transactions[txId];
        
         
        require(txn.status == TxnStatus.Pending);
        
         
        require(wallet.allowance >= txn.value);
        
         
        address dest = txn.destination;
        uint val = txn.value;
        bytes memory dat = txn.data;
        assert(dest.call.value(val)(dat));
            
         
        txn.status = TxnStatus.Executed;

         
        wallet.allowance = wallet.allowance - txn.value;

        return true;
        
    }
}