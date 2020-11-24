 

pragma solidity ^0.4.25;
pragma experimental ABIEncoderV2;

contract LibSignatureValidation {

  using LibBytes for bytes;

  function isValidSignature(bytes32 hash, address signerAddress, bytes memory signature) internal pure returns (bool) {
    require(signature.length == 65, "LENGTH_65_REQUIRED");
    uint8 v = uint8(signature[64]);
    bytes32 r = signature.readBytes32(0);
    bytes32 s = signature.readBytes32(32);
    address recovered = ecrecover(hash, v, r, s);
    return signerAddress == recovered;
  }
}

contract LibTransferRequest {

   
  string constant internal EIP191_HEADER = "\x19\x01";
   
  string constant internal EIP712_DOMAIN_NAME = "Dola Core";
   
  string constant internal EIP712_DOMAIN_VERSION = "1";
   
  bytes32 public constant EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
    "EIP712Domain(",
    "string name,",
    "string version,",
    "address verifyingContract",
    ")"
  ));

   
  bytes32 public EIP712_DOMAIN_HASH;

  bytes32 constant internal EIP712_TRANSFER_REQUEST_TYPE_HASH = keccak256(abi.encodePacked(
    "TransferRequest(",
    "address senderAddress,",
    "address receiverAddress,",
    "uint256 value,",
    "address relayerAddress,",
    "uint256 relayerFee,",
    "uint256 salt,",
    ")"
  ));

  struct TransferRequest {
    address senderAddress;
    address receiverAddress;
    uint256 value;
    address relayerAddress;
    uint256 relayerFee;
    uint256 salt;
  }

  constructor() public {
    EIP712_DOMAIN_HASH = keccak256(abi.encode(
        EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        keccak256(bytes(EIP712_DOMAIN_NAME)),
        keccak256(bytes(EIP712_DOMAIN_VERSION)),
        address(this)
      ));
  }

  function hashTransferRequest(TransferRequest memory request) internal view returns (bytes32) {
    bytes32 typeHash = EIP712_TRANSFER_REQUEST_TYPE_HASH;
    bytes32 hashStruct;

     
     
     
     
     
     
     
     
     
    assembly {
       
      let temp1 := mload(sub(request, 32))

      mstore(sub(request, 32), typeHash)
      hashStruct := keccak256(sub(request, 32), 224)

      mstore(sub(request, 32), temp1)
    }
    return keccak256(abi.encodePacked(EIP191_HEADER, EIP712_DOMAIN_HASH, hashStruct));
  }



}

contract DolaCore is LibTransferRequest, LibSignatureValidation {

  using LibBytes for bytes;

  address public TOKEN_ADDRESS;
  mapping (address => mapping (address => uint256)) public requestEpoch;

  event TransferRequestFilled(address indexed from, address indexed to);

  constructor (address _tokenAddress) public LibTransferRequest() {
    TOKEN_ADDRESS = _tokenAddress;
  }

  function executeTransfer(TransferRequest memory request, bytes memory signature) public {
     
    require(requestEpoch[request.senderAddress][request.relayerAddress] <= request.salt, "REQUEST_INVALID");
     
    require(request.relayerAddress == msg.sender, "REQUEST_INVALID");
     
    bytes32 requestHash = hashTransferRequest(request);
    require(isValidSignature(requestHash, request.senderAddress, signature), "INVALID_REQUEST_SIGNATURE");

    address tokenAddress = TOKEN_ADDRESS;
    assembly {
      mstore(32, 0x23b872dd00000000000000000000000000000000000000000000000000000000)
      calldatacopy(36, 4, 96)
      let success := call(
        gas,             
        tokenAddress,    
        0,               
        32,               
        100,             
        0,             
        32               
      )
      success := and(success, or(
          iszero(returndatasize),
          and(
            eq(returndatasize, 32),
            gt(mload(0), 0)
          )
        ))
      if iszero(success) {
        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
        mstore(96, 0)
        revert(0, 100)
      }
      calldatacopy(68, 100, 64)
      success := call(
        gas,             
        tokenAddress,    
        0,               
        32,               
        100,             
        0,             
        32               
      )
      success := and(success, or(
          iszero(returndatasize),
          and(
            eq(returndatasize, 32),
            gt(mload(0), 0)
          )
        ))
      if iszero(success) {
        mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
        mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
        mstore(64, 0x0000000f5452414e534645525f4641494c454400000000000000000000000000)
        mstore(96, 0)
        revert(0, 100)
      }
    }

    requestEpoch[request.senderAddress][request.relayerAddress] = request.salt + 1;
  }
}

library LibBytes {

    using LibBytes for bytes;

     
     
     
     
     
    function rawAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := input
        }
        return memoryAddress;
    }

     
     
     
    function contentAddress(bytes memory input)
        internal
        pure
        returns (uint256 memoryAddress)
    {
        assembly {
            memoryAddress := add(input, 32)
        }
        return memoryAddress;
    }

     
     
     
     
    function memCopy(
        uint256 dest,
        uint256 source,
        uint256 length
    )
        internal
        pure
    {
        if (length < 32) {
             
             
             
            assembly {
                let mask := sub(exp(256, sub(32, length)), 1)
                let s := and(mload(source), not(mask))
                let d := and(mload(dest), mask)
                mstore(dest, or(s, d))
            }
        } else {
             
            if (source == dest) {
                return;
            }

             
             
             
             
             
             
             
             
             
             
             
             
             
             
             
            if (source > dest) {
                assembly {
                     
                     
                     
                     
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                     
                     
                     
                     
                    let last := mload(sEnd)

                     
                     
                     
                     
                    for {} lt(source, sEnd) {} {
                        mstore(dest, mload(source))
                        source := add(source, 32)
                        dest := add(dest, 32)
                    }

                     
                    mstore(dEnd, last)
                }
            } else {
                assembly {
                     
                     
                    length := sub(length, 32)
                    let sEnd := add(source, length)
                    let dEnd := add(dest, length)

                     
                     
                     
                     
                    let first := mload(source)

                     
                     
                     
                     
                     
                     
                     
                     
                    for {} slt(dest, dEnd) {} {
                        mstore(dEnd, mload(sEnd))
                        sEnd := sub(sEnd, 32)
                        dEnd := sub(dEnd, 32)
                    }

                     
                    mstore(dest, first)
                }
            }
        }
    }

     
     
     
     
     
    function slice(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        require(
            from <= to,
            "FROM_LESS_THAN_TO_REQUIRED"
        );
        require(
            to < b.length,
            "TO_LESS_THAN_LENGTH_REQUIRED"
        );

         
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length);
        return result;
    }

     
     
     
     
     
     
    function sliceDestructive(
        bytes memory b,
        uint256 from,
        uint256 to
    )
        internal
        pure
        returns (bytes memory result)
    {
        require(
            from <= to,
            "FROM_LESS_THAN_TO_REQUIRED"
        );
        require(
            to < b.length,
            "TO_LESS_THAN_LENGTH_REQUIRED"
        );

         
        assembly {
            result := add(b, from)
            mstore(result, sub(to, from))
        }
        return result;
    }

     
     
     
    function popLastByte(bytes memory b)
        internal
        pure
        returns (bytes1 result)
    {
        require(
            b.length > 0,
            "GREATER_THAN_ZERO_LENGTH_REQUIRED"
        );

         
        result = b[b.length - 1];

        assembly {
             
            let newLen := sub(mload(b), 1)
            mstore(b, newLen)
        }
        return result;
    }

     
     
     
    function popLast20Bytes(bytes memory b)
        internal
        pure
        returns (address result)
    {
        require(
            b.length >= 20,
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

         
        result = readAddress(b, b.length - 20);

        assembly {
             
            let newLen := sub(mload(b), 20)
            mstore(b, newLen)
        }
        return result;
    }

     
     
     
     
    function equals(
        bytes memory lhs,
        bytes memory rhs
    )
        internal
        pure
        returns (bool equal)
    {
         
         
         
        return lhs.length == rhs.length && keccak256(lhs) == keccak256(rhs);
    }

     
     
     
     
    function readAddress(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (address result)
    {
        require(
            b.length >= index + 20,   
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

         
         
         
        index += 20;

         
        assembly {
             
             
             
            result := and(mload(add(b, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

     
     
     
     
    function writeAddress(
        bytes memory b,
        uint256 index,
        address input
    )
        internal
        pure
    {
        require(
            b.length >= index + 20,   
            "GREATER_OR_EQUAL_TO_20_LENGTH_REQUIRED"
        );

         
         
         
        index += 20;

         
        assembly {
             
             
             
             

             
             
             
            let neighbors := and(
                mload(add(b, index)),
                0xffffffffffffffffffffffff0000000000000000000000000000000000000000
            )

             
             
            input := and(input, 0xffffffffffffffffffffffffffffffffffffffff)

             
            mstore(add(b, index), xor(input, neighbors))
        }
    }

     
     
     
     
    function readBytes32(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes32 result)
    {
        require(
            b.length >= index + 32,
            "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
        );

         
        index += 32;

         
        assembly {
            result := mload(add(b, index))
        }
        return result;
    }

     
     
     
     
    function writeBytes32(
        bytes memory b,
        uint256 index,
        bytes32 input
    )
        internal
        pure
    {
        require(
            b.length >= index + 32,
            "GREATER_OR_EQUAL_TO_32_LENGTH_REQUIRED"
        );

         
        index += 32;

         
        assembly {
            mstore(add(b, index), input)
        }
    }

     
     
     
     
    function readUint256(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (uint256 result)
    {
        return uint256(readBytes32(b, index));
    }

     
     
     
     
    function writeUint256(
        bytes memory b,
        uint256 index,
        uint256 input
    )
        internal
        pure
    {
        writeBytes32(b, index, bytes32(input));
    }

     
     
     
     
    function readBytes4(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes4 result)
    {
        require(
            b.length >= index + 4,
            "GREATER_OR_EQUAL_TO_4_LENGTH_REQUIRED"
        );
        assembly {
            result := mload(add(b, 32))
             
             
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

     
     
     
     
     
     
    function readBytesWithLength(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes memory result)
    {
         
        uint256 nestedBytesLength = readUint256(b, index);
        index += 32;

         
         
        require(
            b.length >= index + nestedBytesLength,
            "GREATER_OR_EQUAL_TO_NESTED_BYTES_LENGTH_REQUIRED"
        );

         
        assembly {
            result := add(b, index)
        }
        return result;
    }

     
     
     
     
    function writeBytesWithLength(
        bytes memory b,
        uint256 index,
        bytes memory input
    )
        internal
        pure
    {
         
         
        require(
            b.length >= index + 32 + input.length,   
            "GREATER_OR_EQUAL_TO_NESTED_BYTES_LENGTH_REQUIRED"
        );

         
        memCopy(
            b.contentAddress() + index,
            input.rawAddress(),  
            input.length + 32    
        );
    }

     
     
     
    function deepCopyBytes(
        bytes memory dest,
        bytes memory source
    )
        internal
        pure
    {
        uint256 sourceLen = source.length;
         
        require(
            dest.length >= sourceLen,
            "GREATER_OR_EQUAL_TO_SOURCE_BYTES_LENGTH_REQUIRED"
        );
        memCopy(
            dest.contentAddress(),
            source.contentAddress(),
            sourceLen
        );
    }
}