 

pragma solidity ^0.5.0;

 

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

contract ICertification {
  event Certificate(bytes32 indexed certHash, bytes32 innerHash, address indexed certifier);
  event Revocation(bytes32 indexed certHash, bool invalid);  
  address public newAddress;
  uint public genesis;
}

contract Certification is ICertification, Ownable {

  struct Certifier {
    bool valid;
    string id;
  }

  mapping (address => Certifier) public certifiers;  
  mapping (bytes32 => bool) public revoked;  

  constructor() public {
    genesis = block.number;
  }

  function setCertifierStatus(address certifier, bool valid)
  onlyOwner public {
    certifiers[certifier].valid = valid;
  }

  function setCertifierId(address certifier, string memory id)
  onlyOwner public {
    certifiers[certifier].id = id;
  }

  function computeCertHash(address certifier, bytes32 innerHash)
  pure public returns (bytes32) {
    return keccak256(abi.encodePacked(certifier, innerHash));
  }

  function _certify(bytes32 innerHash) internal {
    emit Certificate(
      computeCertHash(msg.sender, innerHash),
      innerHash, msg.sender
    );
  }

  function certifyMany(bytes32[] memory innerHashes) public {
    require(certifiers[msg.sender].valid);
    for(uint i = 0; i < innerHashes.length; i++) {
      _certify(innerHashes[i]);
    }
  }

  function revoke(bytes32 innerHash, address certifier, bool invalid) public {
    require(isOwner() || (certifiers[msg.sender].valid && msg.sender == certifier && invalid));
    bytes32 certHash = computeCertHash(certifier, innerHash);
    emit Revocation(certHash, invalid);
    revoked[certHash] = invalid;
  }

  function deprecate(address _newAddress) public onlyOwner {
    newAddress = _newAddress;
  }

}