 

pragma solidity ^0.5.0;

 

contract OracleIDDescriptions {

     
    mapping(uint=>bytes32) tellorIDtoBytesID;
    mapping(bytes32 => uint) bytesIDtoTellorID;
    mapping(uint => int) tellorCodeToStatusCode;
    mapping(int => uint) statusCodeToTellorCode;
    address public owner;

     
    event TellorIdMappedToBytes(uint _requestID, bytes32 _id);
    event StatusMapped(uint _tellorStatus, int _status);
    

     
    constructor() public{
        owner =msg.sender;
    }

     
    function transferOwnership(address payable newOwner) external {
        require(msg.sender == owner, "Sender is not owner");
        owner = newOwner;
    }

     
    function defineTellorCodeToStatusCode(uint _tellorStatus, int _status) external{
        require(msg.sender == owner, "Sender is not owner");
        tellorCodeToStatusCode[_tellorStatus] = _status;
        statusCodeToTellorCode[_status] = _tellorStatus;
        emit StatusMapped(_tellorStatus, _status);
    }

      
    function defineTellorIdToBytesID(uint _requestID, bytes32 _id) external{
        require(msg.sender == owner, "Sender is not owner");
        tellorIDtoBytesID[_requestID] = _id;
        bytesIDtoTellorID[_id] = _requestID;
        emit TellorIdMappedToBytes(_requestID,_id);
    }

      
    function getTellorStatusFromStatus(int _status) public view returns(uint _tellorStatus){
        return statusCodeToTellorCode[_status];
    }

      
    function getStatusFromTellorStatus (uint _tellorStatus) public view returns(int _status) {
        return tellorCodeToStatusCode[_tellorStatus];
    }
    
      
    function getTellorIdFromBytes(bytes32 _id) public view  returns(uint _requestId)  {
       return bytesIDtoTellorID[_id];
    }

      
    function getBytesFromTellorID(uint _requestId) public view returns(bytes32 _id) {
        return tellorIDtoBytesID[_requestId];
    }

}