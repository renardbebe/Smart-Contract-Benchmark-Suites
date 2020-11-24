 

pragma solidity ^0.5.8;
 
pragma experimental ABIEncoderV2;

 
contract RegistrationEvent {
	 
    event Registration(bytes32 indexed hash, string description, address indexed authority);

     
    function register(bytes32[] memory _hashList, string[] memory _descList) public {
        require(_hashList.length == _descList.length, "Hash list and description list must have equal length");
        for(uint i = 0; i < _hashList.length; i++) {
            emit Registration(_hashList[i], _descList[i], msg.sender);
        }
    }
}