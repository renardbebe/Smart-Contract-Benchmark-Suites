 

pragma solidity ^0.4.18;

 

 
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract Certification is Ownable {

  struct Certifier {
    bool valid;
    string id;
  }

  mapping (address => Certifier) public certifiers;

  event Certificate(bytes32 indexed certHash, bytes32 innerHash, address indexed certifier);
  event Revocation(bytes32 indexed certHash, bool invalid);

  function setCertifierStatus(address certifier, bool valid)
  onlyOwner public {
    certifiers[certifier].valid = valid;
  }

  function setCertifierId(address certifier, string id)
  onlyOwner public {
    certifiers[certifier].id = id;
  }

  function computeCertHash(address certifier, bytes32 innerHash)
  pure public returns (bytes32) {
    return keccak256(certifier, innerHash);
  }

  function _certify(bytes32 innerHash) internal {
    emit Certificate(
      computeCertHash(msg.sender, innerHash),
      innerHash, msg.sender
    );
  }

  function certify(bytes32 innerHash) public {
    require(certifiers[msg.sender].valid);
    _certify(innerHash);
  }

  function certifyMany(bytes32[] innerHashes) public {
    require(certifiers[msg.sender].valid);
    for(uint i = 0; i < innerHashes.length; i++) {
      _certify(innerHashes[i]);
    }
  }

  function revoke(bytes32 innerHash, address certifier, bool invalid) public {
    require(msg.sender == owner
      || (certifiers[msg.sender].valid && msg.sender == certifier && invalid)
    );
    emit Revocation(computeCertHash(certifier, innerHash), invalid);
  }

}