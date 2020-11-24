 

pragma solidity ^0.4.23;


contract LetsBreakThings {
    
    address public creator;
    address public creatorproxy;
    

     
    function deposit() public payable {

    }
    
     
    constructor(address _proxy) public {
        creator = msg.sender;
        creatorproxy = _proxy;
    }

    
     
    event txSenderDetails(address sender, address origin);
    event gasDetails(uint remainingGas, uint txGasPrice, uint blockGasLimit);
    event balanceLog(address balanceHolder, uint256 balance);
    event blockDetails(address coinbase, uint difficulty, uint blockNumber, uint timestamp);
    

     
    function getBlockHash(uint _blockNumber) public view returns (bytes32 _hash) {
         
        logBlockDetails();
        logGasDetails();
        logGasDetails();
        logSenderDetails();
        return block.blockhash(_blockNumber);
    }
    
     
     
    function logSenderDetails() public view {
        emit txSenderDetails(msg.sender, tx.origin);
    }
    
     
    function logGasDetails() public view {
        emit gasDetails(msg.gas, tx.gasprice, block.gaslimit);
         
    }
    
     
    function logBlockDetails() public view { 
        emit blockDetails(block.coinbase, block.difficulty, block.number, block.timestamp);
    }
    
     
    function checkBalanceSendEth(address _recipient) public {
        
        require(creator == msg.sender, "unauthorized");

         
        checkBalance(_recipient);
        

         
         
        _recipient.transfer(1);

         
        checkBalance(_recipient);

         
        _recipient.send(1);

         
        checkBalance(_recipient);
        
         
        logBlockDetails();
        logGasDetails();
        logGasDetails();
        logSenderDetails();
        
        
    
    }
    
     
    function checkBalance(address _target) internal returns (uint256) {
        uint256 balance = address(_target).balance;
        emit balanceLog(_target, balance);
        return balance;
    }
    
    
     
    function verifyBlockHash(string memory _hash, uint _blockNumber) public returns (bytes32, bytes32) {
        bytes32 hash1 = keccak256(_hash);
        bytes32 hash2 = getBlockHash(_blockNumber);
        return(hash1, hash2) ;
    }
    
}

 

 
 
contract creatorProxy {
    function proxyCall(address _target, address _contract) public {
        LetsBreakThings(_contract).checkBalanceSendEth(_target);
    }
}