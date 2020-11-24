 

 

pragma solidity ^0.4.18;

interface IFeed {
    function get(address base, address quote) external view returns (uint128 xrt, uint64 when);
}

 

pragma solidity 0.4.24;

 
 

library ECRecovery {
   
  function personalRecover(bytes32 hash, bytes sig) internal pure returns (address) {
    return recover(toEthSignedMessageHash(hash), sig);
  }

   
  function recover(bytes32 hash, bytes sig) internal pure returns (address) {
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

   
  function toEthSignedMessageHash(bytes32 hash)
    internal
    pure
    returns (bytes32)
  {
     
     
    return keccak256(abi.encodePacked(
      "\x19Ethereum Signed Message:\n32",
      hash
    ));
  }
}

 

pragma solidity ^0.4.24;


library Uint256Helpers {
    uint256 private constant MAX_UINT64 = uint64(-1);

    string private constant ERROR_NUMBER_TOO_BIG = "UINT64_NUMBER_TOO_BIG";

    function toUint64(uint256 a) internal pure returns (uint64) {
        require(a <= MAX_UINT64, ERROR_NUMBER_TOO_BIG);
        return uint64(a);
    }
}

 

 

pragma solidity ^0.4.24;



contract TimeHelpers {
    using Uint256Helpers for uint256;

     
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }

     
    function getBlockNumber64() internal view returns (uint64) {
        return getBlockNumber().toUint64();
    }

     
    function getTimestamp() internal view returns (uint256) {
        return block.timestamp;  
    }

     
    function getTimestamp64() internal view returns (uint64) {
        return getTimestamp().toUint64();
    }
}

 

pragma solidity 0.4.24;





contract PPF is IFeed, TimeHelpers {
    using ECRecovery for bytes32;

    uint256 constant public ONE = 10 ** 18;  
    bytes32 constant public PPF_v1_ID = 0x33a8ba7202230fa1cee2aac7bac322939edc7ba0a48b0989335a5f87a5770369;  

    string private constant ERROR_BAD_SIGNATURE = "PPF_BAD_SIGNATURE";
    string private constant ERROR_BAD_RATE_TIMESTAMP = "PPF_BAD_RATE_TIMESTAMP";
    string private constant ERROR_INVALID_RATE_VALUE = "PPF_INVALID_RATE_VALUE";
    string private constant ERROR_EQUAL_BASE_QUOTE_ADDRESSES = "PPF_EQUAL_BASE_QUOTE_ADDRESSES";
    string private constant ERROR_BASE_ADDRESSES_LENGTH_ZERO = "PPF_BASE_ADDRESSES_LEN_ZERO";
    string private constant ERROR_QUOTE_ADDRESSES_LENGTH_MISMATCH = "PPF_QUOTE_ADDRESSES_LEN_MISMATCH";
    string private constant ERROR_RATE_VALUES_LENGTH_MISMATCH = "PPF_RATE_VALUES_LEN_MISMATCH";
    string private constant ERROR_RATE_TIMESTAMPS_LENGTH_MISMATCH = "PPF_RATE_TIMESTAMPS_LEN_MISMATCH";
    string private constant ERROR_SIGNATURES_LENGTH_MISMATCH = "PPF_SIGNATURES_LEN_MISMATCH";
    string private constant ERROR_CAN_NOT_SET_OPERATOR = "PPF_CAN_NOT_SET_OPERATOR";
    string private constant ERROR_CAN_NOT_SET_OPERATOR_OWNER = "PPF_CAN_NOT_SET_OPERATOR_OWNER";
    string private constant ERROR_OPERATOR_ADDRESS_ZERO = "PPF_OPERATOR_ADDRESS_ZERO";
    string private constant ERROR_OPERATOR_OWNER_ADDRESS_ZERO = "PPF_OPERATOR_OWNER_ADDRESS_ZERO";

    struct Price {
        uint128 xrt;
        uint64 when;
    }

    mapping (bytes32 => Price) internal feed;
    address public operator;
    address public operatorOwner;

    event SetRate(address indexed base, address indexed quote, uint256 xrt, uint64 when);
    event SetOperator(address indexed operator);
    event SetOperatorOwner(address indexed operatorOwner);

     
    constructor (address _operator, address _operatorOwner) public {
        _setOperator(_operator);
        _setOperatorOwner(_operatorOwner);
    }

     
    function update(address base, address quote, uint128 xrt, uint64 when, bytes sig) public {
        bytes32 pair = pairId(base, quote);

         
        require(when > feed[pair].when && when <= getTimestamp(), ERROR_BAD_RATE_TIMESTAMP);
        require(xrt > 0, ERROR_INVALID_RATE_VALUE);  
        require(base != quote, ERROR_EQUAL_BASE_QUOTE_ADDRESSES);  

        bytes32 h = setHash(base, quote, xrt, when);
        require(h.personalRecover(sig) == operator, ERROR_BAD_SIGNATURE);  

        feed[pair] = Price(pairXRT(base, quote, xrt), when);

        emit SetRate(base, quote, xrt, when);
    }

     
    function updateMany(address[] bases, address[] quotes, uint128[] xrts, uint64[] whens, bytes sigs) public {
        require(bases.length != 0, ERROR_BASE_ADDRESSES_LENGTH_ZERO);
        require(bases.length == quotes.length, ERROR_QUOTE_ADDRESSES_LENGTH_MISMATCH);
        require(bases.length == xrts.length, ERROR_RATE_VALUES_LENGTH_MISMATCH);
        require(bases.length == whens.length, ERROR_RATE_TIMESTAMPS_LENGTH_MISMATCH);
        require(bases.length == sigs.length / 65, ERROR_SIGNATURES_LENGTH_MISMATCH);
        require(sigs.length % 65 == 0, ERROR_SIGNATURES_LENGTH_MISMATCH);

        for (uint256 i = 0; i < bases.length; i++) {
             
            bytes memory sig = new bytes(65);
            uint256 needle = 32 + 65 * i;  
            assembly {
                 
                mstore(add(sig, 0x20), mload(add(sigs, needle)))
                mstore(add(sig, 0x40), mload(add(sigs, add(needle, 0x20))))
                 
                mstore8(add(sig, 0x60), mload(add(sigs, add(needle, 0x21))))
            }

            update(bases[i], quotes[i], xrts[i], whens[i], sig);
        }
    }

     
    function get(address base, address quote) public view returns (uint128, uint64) {
        if (base == quote) {
            return (uint128(ONE), getTimestamp64());
        }

        Price storage price = feed[pairId(base, quote)];

         
        if (price.when == 0) {
            return (0, 0);
        }

        return (pairXRT(base, quote, price.xrt), price.when);
    }

     
    function setOperator(address _operator) external {
         
         
        require(msg.sender == operator || msg.sender == operatorOwner, ERROR_CAN_NOT_SET_OPERATOR);
        _setOperator(_operator);
    }

     
    function setOperatorOwner(address _operatorOwner) external {
        require(msg.sender == operatorOwner, ERROR_CAN_NOT_SET_OPERATOR_OWNER);
        _setOperatorOwner(_operatorOwner);
    }

    function _setOperator(address _operator) internal {
        require(_operator != address(0), ERROR_OPERATOR_ADDRESS_ZERO);
        operator = _operator;
        emit SetOperator(_operator);
    }

    function _setOperatorOwner(address _operatorOwner) internal {
        require(_operatorOwner != address(0), ERROR_OPERATOR_OWNER_ADDRESS_ZERO);
        operatorOwner = _operatorOwner;
        emit SetOperatorOwner(_operatorOwner);
    }

     
    function pairId(address base, address quote) internal pure returns (bytes32) {
        bool pairOrdered = isPairOrdered(base, quote);
        address orderedBase = pairOrdered ? base : quote;
        address orderedQuote = pairOrdered ? quote : base;

        return keccak256(abi.encodePacked(orderedBase, orderedQuote));
    }

     
    function pairXRT(address base, address quote, uint128 xrt) internal pure returns (uint128) {
        bool pairOrdered = isPairOrdered(base, quote);

        return pairOrdered ? xrt : uint128((ONE**2 / uint256(xrt)));  
    }

    function setHash(address base, address quote, uint128 xrt, uint64 when) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(PPF_v1_ID, base, quote, xrt, when));
    }

    function isPairOrdered(address base, address quote) private pure returns (bool) {
        return base < quote;
    }
}