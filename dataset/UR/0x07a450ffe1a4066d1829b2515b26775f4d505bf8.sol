 

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

 
 
 
contract IMCUnlockRecord is Owned{

     
    event UnlockRecordAdd(uint _date, bytes32 _hash, string _data, string _fileFormat, uint _stripLen);

     
    struct RecordInfo {
        uint date;   
        bytes32 hash;   
        string data;  
        string fileFormat;  
        uint stripLen;  
    }
    
     
    mapping(uint => RecordInfo) public unlockRecord;
    
    constructor() public{

    }
    
     
     
    function unlockRecordAdd(uint _date, bytes32 _hash, string _data, string _fileFormat, uint _stripLen) public onlyOwner returns (bool) {
        
         
        require(!(unlockRecord[_date].date > 0));

         
        unlockRecord[_date] = RecordInfo(_date, _hash, _data, _fileFormat, _stripLen);

         
        emit UnlockRecordAdd(_date, _hash, _data, _fileFormat, _stripLen);
        
        return true;
        
    }

}