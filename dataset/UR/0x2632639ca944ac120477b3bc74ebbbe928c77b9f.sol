 

pragma solidity ^0.4.19;



contract SATToken{     

    uint public totalSupply = 10000000000*10**4;
    uint8 constant public decimals = 4;
    string constant public name = "smartx";
    string constant public symbol = "SAT";

    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

}


contract MultiSigWallet{
    
    
    SATToken public RCCC = SATToken(0x1f0f468ee03a6d99cd8a09dd071494a83dc1c0e5);
  
    function getbalance() public payable returns(uint)
    {
        return RCCC.totalSupply();
    } 
    
    
    
    address private owner;
    mapping (address => uint8) private managers;
    
    modifier isOwner{
        require(owner == msg.sender);
        _;
    }
    
    modifier isManager{
        require(
            msg.sender == owner || managers[msg.sender] == 1);
        _;
    }
    
    uint constant MIN_SIGNATURES = 2;
    uint public transactionIdx;
    uint public manger_num=0;
    
     struct Transaction  {
        address from;
        address to;
        uint amount;
        uint8 signatureCount;
        mapping (address => uint8) signatures;
    }
    
    mapping (uint => Transaction) public transactions;
    uint[] public pendingTransactions;
    
    function MultiSigWallet () public{
        owner = msg.sender;
    }
    
    event DepositFunds(address from, uint amount);
    event TransferFunds(address to, uint amount);
    event TransactionCreated(
        address from,
        address to,
        uint amount,
        uint transactionId
        );
    
    function addManager(address manager) public isOwner{
        managers[manager] = 1;
        manger_num=manger_num+1;
    }
    
    function removeManager(address manager) public isOwner{
        managers[manager] = 0;
        manger_num=manger_num-1;
        
    }

    function withdraw(uint amount) isManager public{
        transferTo(msg.sender, amount);
    }
    function transferTo(address to,  uint amount) isManager public{
        require(RCCC.balanceOf(this) >= amount);
        uint transactionId = transactionIdx++;
        
        Transaction memory transaction;
        transaction.from = msg.sender;
        transaction.to = to;
        transaction.amount = amount;
        transaction.signatureCount = 0;
        transactions[transactionId] = transaction;
        pendingTransactions.push(transactionId);
    }
    
    function getPendingTransactions() public isManager view returns(uint[]){
        return pendingTransactions;
    }
    
    function signTransaction(uint transactionId) public isManager{
        Transaction storage transaction = transactions[transactionId];
        require(0x0 != transaction.from);
        require(transaction.signatures[msg.sender]!=1);
        transaction.signatures[msg.sender] = 1;
        transaction.signatureCount++;
        
        if(transaction.signatureCount >= MIN_SIGNATURES){
            require(RCCC.balanceOf(this)  >= transaction.amount);
            RCCC.transfer(transaction.to, transaction.amount);
            deleteTransactions(transactionId);
        }
    }
    
    function deleteTransactions(uint transacionId) public isManager{
        uint8 replace = 0;
        for(uint i = 0; i< pendingTransactions.length; i++){
            if(1==replace){
                pendingTransactions[i-1] = pendingTransactions[i];
            }else if(transacionId == pendingTransactions[i]){
                replace = 1;
            }
        } 
        delete pendingTransactions[pendingTransactions.length - 1];
        pendingTransactions.length--;
        delete transactions[transacionId];
    }
    
    function walletBalance() public isManager view returns(uint){
        return RCCC.balanceOf(this);
    }
}