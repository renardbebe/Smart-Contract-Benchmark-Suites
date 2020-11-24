 

pragma solidity ^0.4.14;

 

contract ERC20Interface {
   
  function transfer(address _to, uint256 _value) returns (bool success);
   
  function balanceOf(address _owner) constant returns (uint256 balance);
}

 
contract Forwarder {
   
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

  event TokensFlushed(
    address tokenContractAddress,  
    uint value  
  );

   
  function Forwarder() {
    parentAddress = msg.sender;
  }

   
  modifier onlyParent {
    if (msg.sender != parentAddress) {
      throw;
    }
    _;
  }

   
  function() payable {
    if (!parentAddress.call.value(msg.value)(msg.data))
      throw;
     
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

   
  function flushTokens(address tokenContractAddress) onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      throw;
    }
    TokensFlushed(tokenContractAddress, forwarderBalance);
  }

   
  function flush() {
    if (!parentAddress.call.value(this.balance)())
      throw;
  }
}

 
contract WalletSimple {
   
  event Deposited(address from, uint value, bytes data);
  event SafeModeActivated(address msgSender);
  event Transacted(
    address msgSender,  
    address otherSigner,  
    bytes32 operation,  
    address toAddress,  
    uint value,  
    bytes data  
  );
  event TokenTransacted(
    address msgSender,  
    address otherSigner,  
    bytes32 operation,  
    address toAddress,  
    uint value,  
    address tokenContractAddress  
  );

   
  address[] public signers;  
  bool public safeMode = false;  

   
  uint constant SEQUENCE_ID_WINDOW_SIZE = 10;
  uint[10] recentSequenceIds;

   
  modifier onlysigner {
    if (!isSigner(msg.sender)) {
      throw;
    }
    _;
  }

   
  function WalletSimple(address[] allowedSigners) {
    if (allowedSigners.length != 3) {
       
      throw;
    }
    signers = allowedSigners;
  }
  
    function init(address[] allowedSigners) {
    if (allowedSigners.length != 3) {
       
      throw;
    }
    signers = allowedSigners;
  }

   
  function() payable {
    if (msg.value > 0) {
       
      Deposited(msg.sender, msg.value, msg.data);
    }
  }

   
  function createForwarder() onlysigner returns (address) {
    return new Forwarder();
  }

   
  function sendMultiSig(address toAddress, uint value, bytes data, uint expireTime, uint sequenceId, bytes signature) onlysigner {
     
    var operationHash = sha3("ETHER", toAddress, value, data, expireTime, sequenceId);
    
    var otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);

     
    if (!(toAddress.call.value(value)(data))) {
       
      throw;
    }
    Transacted(msg.sender, otherSigner, operationHash, toAddress, value, data);
  }
  
   
  function sendMultiSigToken(address toAddress, uint value, address tokenContractAddress, uint expireTime, uint sequenceId, bytes signature) onlysigner {
     
    var operationHash = sha3("ERC20", toAddress, value, tokenContractAddress, expireTime, sequenceId);
    
    var otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
    
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    if (!instance.transfer(toAddress, value)) {
        throw;
    }
    TokenTransacted(msg.sender, otherSigner, operationHash, toAddress, value, tokenContractAddress);
  }

   
  function flushForwarderTokens(address forwarderAddress, address tokenContractAddress) onlysigner {    
    Forwarder forwarder = Forwarder(forwarderAddress);
    forwarder.flushTokens(tokenContractAddress);
  }  
  
   
  function verifyMultiSig(address toAddress, bytes32 operationHash, bytes signature, uint expireTime, uint sequenceId) private returns (address) {

    var otherSigner = recoverAddressFromSignature(operationHash, signature);

     
    if (safeMode && !isSigner(toAddress)) {
       
      throw;
    }
     
    if (expireTime < block.timestamp) {
       
      throw;
    }

     
    tryInsertSequenceId(sequenceId);

    if (!isSigner(otherSigner)) {
       
      throw;
    }
    if (otherSigner == msg.sender) {
       
      throw;
    }

    return otherSigner;
  }

   
  function activateSafeMode() onlysigner {
    safeMode = true;
    SafeModeActivated(msg.sender);
  }

   
  function isSigner(address signer) returns (bool) {
     
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }

   
  function recoverAddressFromSignature(bytes32 operationHash, bytes signature) private returns (address) {
    if (signature.length != 65) {
      throw;
    }
     
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
      r := mload(add(signature, 32))
      s := mload(add(signature, 64))
      v := and(mload(add(signature, 65)), 255)
    }
    if (v < 27) {
      v += 27;  
    }
    return ecrecover(operationHash, v, r, s);
  }

   
  function tryInsertSequenceId(uint sequenceId) onlysigner private {
     
    uint lowestValueIndex = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] == sequenceId) {
         
        throw;
      }
      if (recentSequenceIds[i] < recentSequenceIds[lowestValueIndex]) {
        lowestValueIndex = i;
      }
    }
    if (sequenceId < recentSequenceIds[lowestValueIndex]) {
       
       
      throw;
    }
    if (sequenceId > (recentSequenceIds[lowestValueIndex] + 10000)) {
       
       
      throw;
    }
    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

   
  function getNextSequenceId() returns (uint) {
    uint highestSequenceId = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] > highestSequenceId) {
        highestSequenceId = recentSequenceIds[i];
      }
    }
    return highestSequenceId + 1;
  }
}