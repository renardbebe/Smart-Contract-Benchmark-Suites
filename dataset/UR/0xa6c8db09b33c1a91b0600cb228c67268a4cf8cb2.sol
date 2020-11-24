 

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