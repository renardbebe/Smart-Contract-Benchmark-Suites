 

pragma solidity ^0.4.24;

 
 
 
contract PassiveForwarder {
   
   
  address public recipient;

  event Received(address indexed sender, uint256 value);

  constructor(address _recipient) public {
    recipient = _recipient;
  }

  function () public payable {
    require(msg.value > 0);
    emit Received(msg.sender, msg.value);
  }

  function sweep() public {
    recipient.transfer(address(this).balance);
  }

   
   
  function externalCall(address destination, uint256 value, bytes data) public returns (bool) {
    require(msg.sender == recipient, "Sender must be the recipient.");
    uint256 dataLength = data.length;
    bool result;
    assembly {
      let x := mload(0x40)    
      let d := add(data, 32)  
      result := call(
        sub(gas, 34710),      
                              
                              
        destination,
        value,
        d,
        dataLength,           
        x,
        0                     
      )
    }
    return result;
  }
}


 
 
contract PassiveForwarderFactory {

  address public owner;

   
   
  mapping(address => address[]) public recipients;

  event Created(address indexed recipient, address indexed newContract);

  constructor(address _owner) public {
    owner = _owner;
  }

  function create(address recipient) public returns (address){
    require(msg.sender == owner, "Sender must be the owner.");

    PassiveForwarder pf = new PassiveForwarder(recipient);
    recipients[recipient].push(pf);
    emit Created(recipient, pf);
    return pf;
  }

   
  function getNumberOfContracts(address recipient) public view returns (uint256) {
    return recipients[recipient].length;
  }
}