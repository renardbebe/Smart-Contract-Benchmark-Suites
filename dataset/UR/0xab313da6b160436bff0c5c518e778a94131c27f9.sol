 

pragma solidity 0.4.25;

 
contract Ownable {
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
   
 function Ownable() {
    owner = msg.sender;
  }
   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}
 
contract Blueprint is Ownable {
   
    struct BlueprintInfo {
        bytes32 details;
        address creator;
        uint256 createTime;
    }
     
    mapping(string => BlueprintInfo) private  _bluePrint;
    
     

    function createExchange(string _id,string _details) public onlyOwner
          
    returns (bool)
   
    {
         BlueprintInfo memory info;
         info.details=sha256(_details);
         info.creator=msg.sender;
         info.createTime=block.timestamp;
         _bluePrint[_id] = info;
         return true;
         
    }
    
     
  function getBluePrint(string _id) public view returns (bytes32,address,uint256) {
    return (_bluePrint[_id].details,_bluePrint[_id].creator,_bluePrint[_id].createTime);
  }
    
}