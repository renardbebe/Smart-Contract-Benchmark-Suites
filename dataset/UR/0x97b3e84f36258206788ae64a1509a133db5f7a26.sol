 

pragma solidity ^0.5.10;

contract DenshiJitsuin {
     
    bytes4 SIGN_METHOD_HASH = 0x60f91998;
    
    struct Signature {
        bool isSigned;
        bytes32 hash;
    }

     
    mapping(uint256 => mapping(address => Signature)) private _signatures; 
     
    mapping(uint256 => mapping(uint256 => address)) private _documentSigners;
     
    mapping(uint256 => uint256) private _documentSignerCount;

    constructor() public {}

     
     
     
     
     
     
     
    function sign(uint256 _documentId, bytes32 _documentHash, address _signer, bytes calldata _sig) external returns (bool) {
        if(_signatures[_documentId][_signer].isSigned) {
            return true;
        } else {
            address signer = msg.sender == _signer ? msg.sender : recover(keccak256(abi.encodePacked(SIGN_METHOD_HASH, _documentId, _documentHash)), _sig);
            require(signer == _signer);
            _signatures[_documentId][_signer] = Signature(true, _documentHash);
            _documentSigners[_documentId][_documentSignerCount[_documentId]] = _signer;
            _documentSignerCount[_documentId]++;
            return true;
        }
    }
    
     
     
     
     
     
    function getSignature(uint256 _documentId, address _signer) external view returns (bool, bytes32) {
        Signature memory _signature = _signatures[_documentId][_signer];
        return (_signature.isSigned, _signature.hash);
    }
    
     
     
     
     
    function getSigner(uint256 _documentId, uint256 _index) external view returns (address) {
        return _documentSigners[_documentId][_index];
    }
    
     
     
     
    function getSignerCount(uint256 _documentId) external view returns (uint256) {
        return _documentSignerCount[_documentId];
    }

    function recover(bytes32 _hash, bytes memory _sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
         
        if (_sig.length != 65) {
            return (address(0));
        }

         
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(_hash, v, r, s);
        }
    }
}