 

 

pragma solidity 0.5.10;
pragma experimental ABIEncoderV2;

 


contract ResolverContenthashSignerENS {

     
    uint64 public constant CONTRACT_VERSION = (
        (4 << 32) +  
        (1 << 16) +  
        0  
    );

    bytes4 constant CONTENTHASH_INTERFACE_ID = 0xbc1c58d1;

    event ContenthashChanged(bytes hash);

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    struct Record {
        uint64 version;
        bytes contenthash;
    }

    address signer;  

    Record record;

     
    constructor(address signerAddr) public {
        signer = signerAddr;
    }

     
     

     
    function contenthash(bytes32 node) external view returns (bytes memory) {
        return record.contenthash;
    }

     
    function supportsInterface(bytes4 interfaceID) external pure returns (bool) {
        return interfaceID == CONTENTHASH_INTERFACE_ID;
    }

     
    function setContenthashBySignature (
        bytes memory hash,
        uint64 version,
        Signature memory signature
    ) public
    {
        require(
            signer == verify(
                keccak256(
                    abi.encodePacked(
                        hash,
                        version
                    )
                ),
                signature
            ),
            "Invalid signature"
        );

         
        if (version > record.version) {
            record.contenthash = hash;
            record.version = version;
            emit ContenthashChanged(hash);
        }
    }

     

    function verify(
        bytes32 _message,
        Signature memory signature
    ) internal pure returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(
            abi.encodePacked(
                prefix,
                _message
            )
        );
        return ecrecover(
            prefixedHash,
            signature.v,
            signature.r,
            signature.s
        );
    }

}