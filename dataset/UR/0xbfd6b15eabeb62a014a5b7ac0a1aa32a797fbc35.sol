 

pragma solidity ^0.4.24;



 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


contract ReportStorage is Ownable{

    event Entry(
        bytes32 indexed ID,
        bytes32 indexed report_hash,
        string unindexed_ID,
        string unindexed_hash
    );

    function stringToBytes32(string memory source)  returns (bytes32 result) {
    bytes memory res = bytes(source);
    if (res.length == 0) {
        return 0x0;
    }

    assembly {
        result := mload(add(source, 32))
    }
}

    function addEntry(string _ID,string _report_hash) onlyOwner{

        bytes32 convertedID = stringToBytes32(_ID);
        bytes32 convertedHash = stringToBytes32(_report_hash);

        emit Entry(convertedID,convertedHash,_ID,_report_hash);
    }

}