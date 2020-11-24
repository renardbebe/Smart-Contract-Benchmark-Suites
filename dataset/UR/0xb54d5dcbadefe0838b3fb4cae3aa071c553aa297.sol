 

pragma solidity ^0.4.23;

 
contract Ownable {
    address public owner;


    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


contract Notary is Ownable {

    struct Record {
        bytes notarisedData;
        uint256 timestamp;
    }

    mapping(bytes32 => Record) public records;
    uint256 public notarisationFee;

     
    constructor (address _owner) public {
        owner = _owner;
    }

     
    modifier callHasNotarisationCost() {
        require(msg.value >= notarisationFee);
        _;
    }

     
    function setNotarisationFee(uint256 _fee) public onlyOwner {
        notarisationFee = _fee;
    }

     
    function record(bytes _notarisedData) public constant returns(bytes, uint256) {
        Record memory r = records[keccak256(_notarisedData)];
        return (r.notarisedData, r.timestamp);
    }

     
    function notarize(bytes _record)
        public
        payable
        callHasNotarisationCost
    {

         
        bytes32 recordHash = keccak256(_record);

         
        require(records[recordHash].timestamp == 0);

         
        if (owner != address(0)){
            owner.transfer(address(this).balance);
        }

         
        records[recordHash] = Record({
            notarisedData: _record,
            timestamp: now
        });

    }

}

contract NotaryMulti {

    Notary public notary;

    constructor(Notary _notary) public {
        notary = _notary;
    }

    function notaryFee() public constant returns (uint256) {
        return 2 * notary.notarisationFee();
    }

     
    function notarizeTwo(bytes _firstRecord, bytes _secondRecord) payable public {
        notary.notarize(_firstRecord);
        notary.notarize(_secondRecord);
    }

}