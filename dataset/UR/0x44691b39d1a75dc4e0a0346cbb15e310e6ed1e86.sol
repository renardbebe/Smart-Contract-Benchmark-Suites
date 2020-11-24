 

 
 
 

pragma solidity ^0.4.1;

contract Owned {
  modifier only_owner {
    if (msg.sender != owner) return;
    _;
  }

  event NewOwner(address indexed old, address indexed current);

  function setOwner(address _new) only_owner { NewOwner(owner, _new); owner = _new; }

  address public owner = msg.sender;
}

contract SignatureReg is Owned {
   
  mapping (bytes4 => string) public entries;

   
  uint public totalSignatures = 0;

   
  modifier when_unregistered(bytes4 _signature) {
    if (bytes(entries[_signature]).length != 0) return;
    _;
  }

   
  event Registered(address indexed creator, bytes4 indexed signature, string method);

   
  function SignatureReg() {
    register('register(string)');
  }

   
  function register(string _method) returns (bool) {
    return _register(bytes4(sha3(_method)), _method);
  }

   
  function _register(bytes4 _signature, string _method) internal when_unregistered(_signature) returns (bool) {
    entries[_signature] = _method;
    totalSignatures = totalSignatures + 1;
    Registered(msg.sender, _signature, _method);
    return true;
  }

   
  function drain() only_owner {
    if (!msg.sender.send(this.balance)) {
      throw;
    }
  }
}