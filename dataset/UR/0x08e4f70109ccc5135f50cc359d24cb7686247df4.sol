 

pragma solidity ^0.4.19;




 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}




 

library ECRecovery {

   
  function recover(bytes32 hash, bytes sig) public pure returns (address) {
    bytes32 r;
    bytes32 s;
    uint8 v;

     
    if (sig.length != 65) {
      return (address(0));
    }

     
    assembly {
      r := mload(add(sig, 32))
      s := mload(add(sig, 64))
      v := byte(0, mload(add(sig, 96)))
    }

     
    if (v < 27) {
      v += 27;
    }

     
    if (v != 27 && v != 28) {
      return (address(0));
    } else {
      return ecrecover(hash, v, r, s);
    }
  }

}



 
contract Unidirectional {
    using SafeMath for uint256;

    struct PaymentChannel {
        address sender;
        address receiver;
        uint256 value;  

        uint32 settlingPeriod;  
        uint256 settlingUntil;  
    }

    mapping (bytes32 => PaymentChannel) public channels;

    event DidOpen(bytes32 indexed channelId, address indexed sender, address indexed receiver, uint256 value);
    event DidDeposit(bytes32 indexed channelId, uint256 deposit);
    event DidClaim(bytes32 indexed channelId);
    event DidStartSettling(bytes32 indexed channelId);
    event DidSettle(bytes32 indexed channelId);

     

     
     
     
     
     
    function open(bytes32 channelId, address receiver, uint32 settlingPeriod) public payable {
        require(isAbsent(channelId));

        channels[channelId] = PaymentChannel({
            sender: msg.sender,
            receiver: receiver,
            value: msg.value,
            settlingPeriod: settlingPeriod,
            settlingUntil: 0
        });

        DidOpen(channelId, msg.sender, receiver, msg.value);
    }

     
     
     
     
    function canDeposit(bytes32 channelId, address origin) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isSender = channel.sender == origin;
        return isOpen(channelId) && isSender;
    }

     
     
    function deposit(bytes32 channelId) public payable {
        require(canDeposit(channelId, msg.sender));

        channels[channelId].value += msg.value;

        DidDeposit(channelId, msg.value);
    }

     
     
     
     
    function canStartSettling(bytes32 channelId, address origin) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isSender = channel.sender == origin;
        return isOpen(channelId) && isSender;
    }

     
     
     
    function startSettling(bytes32 channelId) public {
        require(canStartSettling(channelId, msg.sender));

        PaymentChannel storage channel = channels[channelId];
        channel.settlingUntil = block.number + channel.settlingPeriod;

        DidStartSettling(channelId);
    }

     
     
     
    function canSettle(bytes32 channelId) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isWaitingOver = isSettling(channelId) && block.number >= channel.settlingUntil;
        return isSettling(channelId) && isWaitingOver;
    }

     
     
     
    function settle(bytes32 channelId) public {
        require(canSettle(channelId));
        PaymentChannel storage channel = channels[channelId];
        channel.sender.transfer(channel.value);

        delete channels[channelId];
        DidSettle(channelId);
    }

     
     
     
     
     
     
    function canClaim(bytes32 channelId, uint256 payment, address origin, bytes signature) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        bool isReceiver = origin == channel.receiver;
        bytes32 hash = recoveryPaymentDigest(channelId, payment);
        bool isSigned = channel.sender == ECRecovery.recover(hash, signature);

        return isReceiver && isSigned;
    }

     
     
     
     
     
    function claim(bytes32 channelId, uint256 payment, bytes signature) public {
        require(canClaim(channelId, payment, msg.sender, signature));

        PaymentChannel memory channel = channels[channelId];

        if (payment >= channel.value) {
            channel.receiver.transfer(channel.value);
        } else {
            channel.receiver.transfer(payment);
            channel.sender.transfer(channel.value.sub(payment));
        }

        delete channels[channelId];

        DidClaim(channelId);
    }

     

     
     
    function isPresent(bytes32 channelId) public view returns(bool) {
        return !isAbsent(channelId);
    }

     
     
    function isAbsent(bytes32 channelId) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        return channel.sender == 0;
    }

     
     
     
    function isSettling(bytes32 channelId) public view returns(bool) {
        PaymentChannel memory channel = channels[channelId];
        return channel.settlingUntil != 0;
    }

     
     
    function isOpen(bytes32 channelId) public view returns(bool) {
        return isPresent(channelId) && !isSettling(channelId);
    }

     

     
     
     
    function paymentDigest(bytes32 channelId, uint256 payment) public view returns(bytes32) {
        return keccak256(address(this), channelId, payment);
    }

     
     
     
    function recoveryPaymentDigest(bytes32 channelId, uint256 payment) internal view returns(bytes32) {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        return keccak256(prefix, paymentDigest(channelId, payment));
    }
}