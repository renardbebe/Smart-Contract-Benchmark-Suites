 

pragma solidity ^0.4.24;

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
contract IMCLedgerRecord is Owned{

     
    event LedgerRecordAdd(uint _date, bytes32 _hash, uint _depth, string _fileFormat, uint _stripLen, bytes32 _balanceHash, uint _balanceDepth);

     
    struct RecordInfo {
        uint date;   
        bytes32 hash;   
        uint depth;  
        string fileFormat;  
        uint stripLen;  
        bytes32 balanceHash;   
        uint balanceDepth;   
    }

     
    address public executorAddress;
    
     
    mapping(uint => RecordInfo) public ledgerRecord;
    
    constructor() public{
         
        executorAddress = msg.sender;
    }
    
     
    function modifyExecutorAddr(address _addr) public onlyOwner {
        executorAddress = _addr;
    }
    
     
     
    function ledgerRecordAdd(uint _date, bytes32 _hash, uint _depth, string _fileFormat, uint _stripLen, bytes32 _balanceHash, uint _balanceDepth) public returns (bool) {
         
        require(msg.sender == executorAddress);
         
        require(ledgerRecord[_date].date != _date);

         
        ledgerRecord[_date] = RecordInfo(_date, _hash, _depth, _fileFormat, _stripLen, _balanceHash, _balanceDepth);

         
        emit LedgerRecordAdd(_date, _hash, _depth, _fileFormat, _stripLen, _balanceHash, _balanceDepth);
        
        return true;
        
    }

}