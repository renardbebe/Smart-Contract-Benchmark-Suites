 

 

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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

 


pragma solidity ^0.5.1;

library ECDSA {
     
    function recoverAddress(bytes32 _fingerprint, bytes memory _signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        require(_signature.length == 65, "Invalid signature");

         
        assembly {
          r := mload(add(_signature, 0x20))
          s := mload(add(_signature, 0x40))
          v := byte(0, mload(add(_signature, 0x60)))
        }

         
        if (v < 27) {
          v += 27;
        }
        
        require(v == 27 || v == 28, "Invalid signature");
        return ecrecover(toEthSignedMessageHash(_fingerprint), v, r, s);
    }
    
     
    function toEthSignedMessageHash(bytes32 _fingerprint) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", _fingerprint)
        );
    } 
}

 

 

pragma solidity 0.5.1;



contract Certifications is Ownable {
    using ECDSA for bytes32;
    
    mapping(bytes32 => Certificate) public fingerprints; 
    
    struct Certificate {
        address owner;
        mapping(address => bytes) signatures;
        uint issued;
        uint expires;
        bool exists;
    }
    
    constructor() public {}
    
     
    function addCertificate(
        bytes32 _fingerprint,
        address _owner,
        uint _issued,
        uint _expires
    ) onlyOwner() public returns(bool) {
        require(_issued < _expires, "Issuing date can not be less than expiring date");
        require(_expires > now, "This certificate has already expired");
        require(!fingerprints[_fingerprint].exists, "File has already been certified");
        fingerprints[_fingerprint].owner = _owner;
        fingerprints[_fingerprint].issued = _issued;
        fingerprints[_fingerprint].expires = _expires;
        fingerprints[_fingerprint].exists = true;
        return true;
    }
    
     
    function addSignatureToCertificate(address _signer, bytes32 _fingerprint, bytes memory _signature) onlyOwner() public returns(bool) {
       address signer = _fingerprint.recoverAddress(_signature);
       require(fingerprints[_fingerprint].exists, "Certificate does not exists");
       require(_signer == signer, "Signature does not corresponds to signer");
       fingerprints[_fingerprint].signatures[_signer] = _signature;
       return true;
    }
    
     
    function getSignature(address _signer, bytes32 _fingerprint) public view returns(bytes memory) {
        return fingerprints[_fingerprint].signatures[_signer];
    }
}