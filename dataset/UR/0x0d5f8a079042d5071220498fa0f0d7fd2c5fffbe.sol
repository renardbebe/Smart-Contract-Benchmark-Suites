 

pragma solidity ^0.4.18;

 

contract ERC20Interface {
   
  function transfer(address _to, uint256 _value) public returns (bool success);
   
  function balanceOf(address _owner) public constant returns (uint256 balance);
}

 
contract Forwarder {
   
  address public parentAddress;
  event ForwarderDeposited(address from, uint value, bytes data);

   
  function Forwarder() public {
    parentAddress = msg.sender;
  }

   
  modifier onlyParent {
    if (msg.sender != parentAddress) {
      revert();
    }
    _;
  }

   
  function() public payable {
     
    parentAddress.transfer(msg.value);
     
    ForwarderDeposited(msg.sender, msg.value, msg.data);
  }

   
  function flushTokens(address tokenContractAddress) public onlyParent {
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    var forwarderAddress = address(this);
    var forwarderBalance = instance.balanceOf(forwarderAddress);
    if (forwarderBalance == 0) {
      return;
    }
    if (!instance.transfer(parentAddress, forwarderBalance)) {
      revert();
    }
  }

   
  function flush() public {
     
    parentAddress.transfer(this.balance);
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

   
  address[] public signers;  
  bool public safeMode = false;  

   
  uint constant SEQUENCE_ID_WINDOW_SIZE = 10;
  uint[10] recentSequenceIds;

   
  function WalletSimple(address[] allowedSigners) public {
    if (allowedSigners.length != 3) {
       
      revert();
    }
    signers = allowedSigners;
  }

   
  function isSigner(address signer) public view returns (bool) {
     
    for (uint i = 0; i < signers.length; i++) {
      if (signers[i] == signer) {
        return true;
      }
    }
    return false;
  }

   
  modifier onlySigner {
    if (!isSigner(msg.sender)) {
      revert();
    }
    _;
  }

   
  function() public payable {
    if (msg.value > 0) {
       
      Deposited(msg.sender, msg.value, msg.data);
    }
  }

   
  function createForwarder() public returns (address) {
    return new Forwarder();
  }

   
  function sendMultiSig(
      address toAddress,
      uint value,
      bytes data,
      uint expireTime,
      uint sequenceId,
      bytes signature
  ) public onlySigner {
     
    var operationHash = keccak256("ETHER", toAddress, value, data, expireTime, sequenceId);
    
    var otherSigner = verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);

     
    if (!(toAddress.call.value(value)(data))) {
       
      revert();
    }
    Transacted(msg.sender, otherSigner, operationHash, toAddress, value, data);
  }
  
   
  function sendMultiSigToken(
      address toAddress,
      uint value,
      address tokenContractAddress,
      uint expireTime,
      uint sequenceId,
      bytes signature
  ) public onlySigner {
     
    var operationHash = keccak256("ERC20", toAddress, value, tokenContractAddress, expireTime, sequenceId);
    
    verifyMultiSig(toAddress, operationHash, signature, expireTime, sequenceId);
    
    ERC20Interface instance = ERC20Interface(tokenContractAddress);
    if (!instance.transfer(toAddress, value)) {
        revert();
    }
  }
  
   
  function flushForwarderTokens(
    address forwarderAddress, 
    address tokenContractAddress
  ) public onlySigner {
    Forwarder forwarder = Forwarder(forwarderAddress);
    forwarder.flushTokens(tokenContractAddress);
  }

   
  function verifyMultiSig(
      address toAddress,
      bytes32 operationHash,
      bytes signature,
      uint expireTime,
      uint sequenceId
  ) private returns (address) {

    var otherSigner = recoverAddressFromSignature(operationHash, signature);

     
    if (safeMode && !isSigner(toAddress)) {
       
      revert();
    }
     
    if (expireTime < block.timestamp) {
       
      revert();
    }

     
    tryInsertSequenceId(sequenceId);

    if (!isSigner(otherSigner)) {
       
      revert();
    }
    if (otherSigner == msg.sender) {
       
      revert();
    }

    return otherSigner;
  }

   
  function activateSafeMode() public onlySigner {
    safeMode = true;
    SafeModeActivated(msg.sender);
  }

   
  function recoverAddressFromSignature(
    bytes32 operationHash,
    bytes signature
  ) private pure returns (address) {
    if (signature.length != 65) {
      revert();
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

   
  function tryInsertSequenceId(uint sequenceId) private onlySigner {
     
    uint lowestValueIndex = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] == sequenceId) {
         
        revert();
      }
      if (recentSequenceIds[i] < recentSequenceIds[lowestValueIndex]) {
        lowestValueIndex = i;
      }
    }
    if (sequenceId < recentSequenceIds[lowestValueIndex]) {
       
       
      revert();
    }
    if (sequenceId > (recentSequenceIds[lowestValueIndex] + 10000)) {
       
       
      revert();
    }
    recentSequenceIds[lowestValueIndex] = sequenceId;
  }

   
  function getNextSequenceId() public view returns (uint) {
    uint highestSequenceId = 0;
    for (uint i = 0; i < SEQUENCE_ID_WINDOW_SIZE; i++) {
      if (recentSequenceIds[i] > highestSequenceId) {
        highestSequenceId = recentSequenceIds[i];
      }
    }
    return highestSequenceId + 1;
  }
}