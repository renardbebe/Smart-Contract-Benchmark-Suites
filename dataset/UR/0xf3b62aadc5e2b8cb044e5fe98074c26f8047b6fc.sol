 

pragma solidity ^0.4.19;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
contract TrezorMultiSig2of3 {

   
   
   
  mapping(address => bool) private owners;

   
   
  uint256 public spendNonce = 0;

   
  uint256 public unchainedMultisigVersionMajor = 1;
  uint256 public unchainedMultisigVersionMinor = 0;   
  
   
  event Funded(uint new_balance);
  
   
  event Spent(address to, uint transfer);

   
   
  function TrezorMultiSig2of3(address owner1, address owner2, address owner3) public {
    address zeroAddress = 0x0;
    
    require(owner1 != zeroAddress);
    require(owner2 != zeroAddress);
    require(owner3 != zeroAddress);

    require(owner1 != owner2);
    require(owner2 != owner3);
    require(owner1 != owner3);
    
    owners[owner1] = true;
    owners[owner2] = true;
    owners[owner3] = true;
  }

   
  function() public payable {
    Funded(this.balance);
  }

   
   
   
  function generateMessageToSign(address destination, uint256 value) public constant returns (bytes32) {
    require(destination != address(this));
    bytes32 message = keccak256(spendNonce, this, value, destination);
    return message;
  }
  
   
   
   
  function spend(address destination, uint256 value, uint8 v1, bytes32 r1, bytes32 s1, uint8 v2, bytes32 r2, bytes32 s2) public {
     
     
    require(this.balance >= value);
    require(_validSignature(destination, value, v1, r1, s1, v2, r2, s2));
    spendNonce = spendNonce + 1;
    destination.transfer(value);
    Spent(destination, value);
  }

   
   
   
  function _validSignature(address destination, uint256 value, uint8 v1, bytes32 r1, bytes32 s1, uint8 v2, bytes32 r2, bytes32 s2) private constant returns (bool) {
    bytes32 message = _messageToRecover(destination, value);
    address addr1   = ecrecover(message, v1+27, r1, s1);
    address addr2   = ecrecover(message, v2+27, r2, s2);
    require(_distinctOwners(addr1, addr2));
    return true;
  }

   
   
   
   
   
   
   
   
   
  function _messageToRecover(address destination, uint256 value) private constant returns (bytes32) {
    bytes32 hashedUnsignedMessage = generateMessageToSign(destination, value);
    bytes memory unsignedMessageBytes = _hashToAscii(hashedUnsignedMessage);
    bytes memory prefix = "\x19Ethereum Signed Message:\n";
    return keccak256(prefix,bytes1(unsignedMessageBytes.length),unsignedMessageBytes);
  }

  
   
  function _distinctOwners(address addr1, address addr2) private constant returns (bool) {
     
    require(addr1 != addr2);
     
    require(owners[addr1]);
    require(owners[addr2]);
    return true;
  }


   
   
   function _hashToAscii(bytes32 hash) private pure returns (bytes) {
    bytes memory s = new bytes(64);
    for (uint i = 0; i < 32; i++) {
      byte b  = hash[i];
      byte hi = byte(uint8(b) / 16);
      byte lo = byte(uint8(b) - 16 * uint8(hi));
      s[2*i]   = _char(hi);
      s[2*i+1] = _char(lo);            
    }
    return s;    
  }
  
   
   
  function _char(byte b) private pure returns (byte c) {
    if (b < 10) return byte(uint8(b) + 0x30);
    else return byte(uint8(b) + 0x57);
  }
}