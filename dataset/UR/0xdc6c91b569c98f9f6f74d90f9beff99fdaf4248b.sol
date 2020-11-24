 

 

 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract IExchange {
  function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes calldata data,
        bytes calldata signature
  ) external;
}

 

 




contract LibEIP712 {

     
    string constant internal EIP191_HEADER = "\x19\x01";

     
    string constant internal EIP712_DOMAIN_NAME = "0x Protocol";

     
    string constant internal EIP712_DOMAIN_VERSION = "2";

     
    bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH = keccak256(abi.encodePacked(
        "EIP712Domain(",
        "string name,",
        "string version,",
        "address verifyingContract",
        ")"
    ));

     
     
    bytes32 public EIP712_DOMAIN_HASH;

    constructor ()
        public
    {
        EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
            EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
            keccak256(bytes(EIP712_DOMAIN_NAME)),
            keccak256(bytes(EIP712_DOMAIN_VERSION)),
            bytes12(0),
            address(this)
        ));
    }

     
     
     
    function hashEIP712Message(bytes32 hashStruct)
        internal
        view
        returns (bytes32 result)
    {
        bytes32 eip712DomainHash = EIP712_DOMAIN_HASH;

         
         
         
         
         
         

        assembly {
             
            let memPtr := mload(64)

            mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)   
            mstore(add(memPtr, 2), eip712DomainHash)                                             
            mstore(add(memPtr, 34), hashStruct)                                                  

             
            result := keccak256(memPtr, 66)
        }
        return result;
    }
}

 

 





contract LibOrder is
    LibEIP712
{
     
    bytes32 constant internal EIP712_ORDER_SCHEMA_HASH = keccak256(abi.encodePacked(
        "Order(",
        "address makerAddress,",
        "address takerAddress,",
        "address feeRecipientAddress,",
        "address senderAddress,",
        "uint256 makerAssetAmount,",
        "uint256 takerAssetAmount,",
        "uint256 makerFee,",
        "uint256 takerFee,",
        "uint256 expirationTimeSeconds,",
        "uint256 salt,",
        "bytes makerAssetData,",
        "bytes takerAssetData",
        ")"
    ));

     
     
    enum OrderStatus {
        INVALID,                      
        INVALID_MAKER_ASSET_AMOUNT,   
        INVALID_TAKER_ASSET_AMOUNT,   
        FILLABLE,                     
        EXPIRED,                      
        FULLY_FILLED,                 
        CANCELLED                     
    }

     
    struct Order {
        address makerAddress;            
        address takerAddress;            
        address feeRecipientAddress;     
        address senderAddress;           
        uint256 makerAssetAmount;        
        uint256 takerAssetAmount;        
        uint256 makerFee;                
        uint256 takerFee;                
        uint256 expirationTimeSeconds;   
        uint256 salt;                    
        bytes makerAssetData;            
        bytes takerAssetData;            
    }
     

    struct OrderInfo {
        uint8 orderStatus;                     
        bytes32 orderHash;                     
        uint256 orderTakerAssetFilledAmount;   
    }

     
     
     
    function getOrderHash(Order memory order)
        internal
        view
        returns (bytes32 orderHash)
    {
        orderHash = hashEIP712Message(hashOrder(order));
        return orderHash;
    }

     
     
     
    function hashOrder(Order memory order)
        internal
        pure
        returns (bytes32 result)
    {
        bytes32 schemaHash = EIP712_ORDER_SCHEMA_HASH;
        bytes32 makerAssetDataHash = keccak256(order.makerAssetData);
        bytes32 takerAssetDataHash = keccak256(order.takerAssetData);

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

        assembly {
             
            let pos1 := sub(order, 32)
            let pos2 := add(order, 320)
            let pos3 := add(order, 352)

             
            let temp1 := mload(pos1)
            let temp2 := mload(pos2)
            let temp3 := mload(pos3)
            
             
            mstore(pos1, schemaHash)
            mstore(pos2, makerAssetDataHash)
            mstore(pos3, takerAssetDataHash)
            result := keccak256(pos1, 416)
            
             
            mstore(pos1, temp1)
            mstore(pos2, temp2)
            mstore(pos3, temp3)
        }
        return result;
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
            result.length
        );
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
        result = uint256(readBytes32(b, index));
        return result;
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

         
        index += 32;

         
        assembly {
            result := mload(add(b, index))
             
             
            result := and(result, 0xFFFFFFFF00000000000000000000000000000000000000000000000000000000)
        }
        return result;
    }

    function readBytes2(
        bytes memory b,
        uint256 index
    )
        internal
        pure
        returns (bytes2 result)
    {
        require(
            b.length >= index + 2,
            "GREATER_OR_EQUAL_TO_2_LENGTH_REQUIRED"
        );

         
        index += 32;

         
        assembly {
            result := mload(add(b, index))
             
             
            result := and(result, 0xFFFF000000000000000000000000000000000000000000000000000000000000)
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

 




contract LibDecoder {
    using LibBytes for bytes;

    function decodeFillOrder(bytes memory data) internal pure returns(LibOrder.Order memory order, uint256 takerFillAmount, bytes memory mmSignature) {
        require(
            data.length > 800,
            "LENGTH_LESS_800"
        );

         
         
        require(
            data.readBytes4(0) == 0x64a3bc15,
            "WRONG_METHOD_ID"
        );
        
        bytes memory dataSlice;
        assembly {
            dataSlice := add(data, 4)
        }
         
        return abi.decode(dataSlice, (LibOrder.Order, uint256, bytes));

    }

    function decodeMmSignatureWithoutSign(bytes memory signature) internal pure returns(address user, uint16 feeFactor) {
        require(
            signature.length == 87 || signature.length == 88,
            "LENGTH_87_REQUIRED"
        );

        user = signature.readAddress(65);
        feeFactor = uint16(signature.readBytes2(85));
        
        require(
            feeFactor < 10000,
            "FEE_FACTOR_MORE_THEN_10000"
        );

        return (user, feeFactor);
    }

    function decodeMmSignature(bytes memory signature) internal pure returns(uint8 v, bytes32 r, bytes32 s, address user, uint16 feeFactor) {
        (user, feeFactor) = decodeMmSignatureWithoutSign(signature);

        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s, user, feeFactor);
    }

    function decodeUserSignatureWithoutSign(bytes memory signature) internal pure returns(address receiver) {
        require(
            signature.length == 85 || signature.length == 86,
            "LENGTH_85_REQUIRED"
        );
        receiver = signature.readAddress(65);

        return receiver;
    }

    function decodeUserSignature(bytes memory signature) internal pure returns(uint8 v, bytes32 r, bytes32 s, address receiver) {
        receiver = decodeUserSignatureWithoutSign(signature);

        v = uint8(signature[0]);
        r = signature.readBytes32(1);
        s = signature.readBytes32(33);

        return (v, r, s, receiver);
    }

    function decodeERC20Asset(bytes memory assetData) internal pure returns(address) {
        require(
            assetData.length == 36,
            "LENGTH_65_REQUIRED"
        );

        return assetData.readAddress(16);
    }
}

 




contract LibEncoder is
    LibEIP712
{
     
    bytes32 constant internal EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH = keccak256(
        abi.encodePacked(
        "ZeroExTransaction(",
        "uint256 salt,",
        "address signerAddress,",
        "bytes data",
        ")"
    ));

    function encodeTransactionHash(
        uint256 salt,
        address signerAddress,
        bytes memory data
    )
        internal
        view 
        returns (bytes32 result)
    {
        bytes32 schemaHash = EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH;
        bytes32 dataHash = keccak256(data);

         
         
         
         
         
         
         

        assembly {
             
            let memPtr := mload(64)

            mstore(memPtr, schemaHash)                                                                
            mstore(add(memPtr, 32), salt)                                                             
            mstore(add(memPtr, 64), and(signerAddress, 0xffffffffffffffffffffffffffffffffffffffff))   
            mstore(add(memPtr, 96), dataHash)                                                         

             
            result := keccak256(memPtr, 128)
        }
        result = hashEIP712Message(result);
        return result;
    }
}

 



contract IOwnable {
  function transferOwnership(address newOwner) public;

  function setOperator(address newOwner) public;
}

 





contract Ownable is
  IOwnable
{
  address public owner;
  address public operator;

  constructor ()
    public
  {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(
      msg.sender == owner,
      "ONLY_CONTRACT_OWNER"
    );
    _;
  }

  modifier onlyOperator() {
    require(
      msg.sender == operator,
      "ONLY_CONTRACT_OPERATOR"
    );
    _;
  }

  function transferOwnership(address newOwner)
    public
    onlyOwner
  {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

  function setOperator(address newOperator)
    public
    onlyOwner 
  {
    operator = newOperator;
  }
}

 



contract IUserProxy {
    function receiveToken(address tokenAddr, address userAddr, uint256 amount) external;

    function sendToken(address tokenAddr, address userAddr, uint256 amount) external;

    function receiveETH(address wethAddr) payable external;

    function sendETH(address wethAddr, address payable userAddr, uint256 amount) external;
}

 



 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 



contract TokenlonExchange is 
    Ownable,
    LibDecoder,
    LibEncoder
{
    string public version = "0.0.3";

    IExchange internal ZX_EXCHANGE;
    IUserProxy internal USER_PROXY; 
    address internal WETH_ADDR;

     
    bool public isEnabled = false;

     
    mapping(address=>bool) public isMarketMakerProxy;

     
    mapping(bytes32=>address) public transactions;

    constructor () public {
        owner = msg.sender;
        operator = msg.sender;
    }

     
    event FillOrder(
        bytes32 indexed executeTxHash,
        address indexed userAddr,
        address receiverAddr,
        uint256 filledAmount, 
        uint256 acutalMakerAssetAmount
    );

     
     
     
    function fillOrderWithToken(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    )
        public
    {
        require(isEnabled, "EXCHANGE_DISABLED");

         
        (LibOrder.Order memory order,
        address user,
        address receiver,
        uint16 feeFactor,
        address makerAssetAddr,
        address takerAssetAddr,
        bytes32 transactionHash) = assertTransaction(userSalt, data, userSignature);

         
        transactions[transactionHash] = user;

         
        USER_PROXY.receiveToken(takerAssetAddr, user, order.takerAssetAmount);

         
        ZX_EXCHANGE.executeTransaction(
            userSalt,
            address(USER_PROXY),
            data,
            userSignature
        );

         
        uint256 acutalMakerAssetAmount = settle(receiver, makerAssetAddr, order.makerAssetAmount, feeFactor);

        emit FillOrder(transactionHash, user, receiver, order.takerAssetAmount, acutalMakerAssetAmount);
    }

    function fillOrderWithETH(
        uint256 userSalt,
        bytes memory data,
        bytes memory userSignature
    )
        public
        payable
    {
        require(isEnabled, "EXCHANGE_DISABLED");

         
        (LibOrder.Order memory order,
        address user,
        address receiver,
        uint16 feeFactor,
        address makerAssetAddr,
        address takerAssetAddr,
        bytes32 transactionHash) = assertTransaction(userSalt, data, userSignature);

        require(
            msg.sender == user,
            "SENDER_IS_NOT_USER"
        );

        require(
            WETH_ADDR == takerAssetAddr,
            "USER_ASSET_NOT_WETH"
        );

        require(
            msg.value == order.takerAssetAmount,
            "ETH_NOT_ENOUGH"
        );

         
        transactions[transactionHash] = user;

         
        USER_PROXY.receiveETH.value(msg.value)(WETH_ADDR);

         
        ZX_EXCHANGE.executeTransaction(
            userSalt,
            address(USER_PROXY),
            data,
            userSignature
        );

         
        uint256 acutalMakerAssetAmount = settle(receiver, makerAssetAddr, order.makerAssetAmount, feeFactor);

        emit FillOrder(transactionHash, user, receiver, order.takerAssetAmount, acutalMakerAssetAmount);
    }

     
    function assertTransaction(uint256 userSalt, bytes memory data, bytes memory userSignature)
    public view returns(
        LibOrder.Order memory order,
        address user,
        address receiver,
        uint16 feeFactor,
        address makerAssetAddr,
        address takerAssetAddr,
        bytes32 transactionHash
    ){
         
        uint256 takerFillAmount;
        bytes memory mmSignature;
        (order, takerFillAmount, mmSignature) = decodeFillOrder(data);

        require(
            this.isMarketMakerProxy(order.makerAddress),
            "MAKER_ADDRESS_ERROR"
        );

        require(
            order.takerAddress == address(USER_PROXY),
            "TAKER_ADDRESS_ERROR"
        );
        require(
            order.takerAssetAmount == takerFillAmount,
            "FIll_AMOUNT_ERROR"
        );

         
        transactionHash = encodeTransactionHash(
            userSalt,
            address(USER_PROXY),
            data
        );

        require(
            transactions[transactionHash] == address(0),
            "EXECUTED_TX_HASH"
        );

         
        (user, feeFactor) = decodeMmSignatureWithoutSign(mmSignature);

        require(
            feeFactor < 10000,
            "FEE_FACTOR_MORE_THEN_10000"
        );

         
        receiver = decodeUserSignatureWithoutSign(userSignature);

        require(
            receiver != address(0),
            "INVALID_RECIVER"
        );

         
         
        makerAssetAddr = decodeERC20Asset(order.makerAssetData);
        takerAssetAddr = decodeERC20Asset(order.takerAssetData);

        return (
            order,
            user,
            receiver,
            feeFactor,
            makerAssetAddr,
            takerAssetAddr,
            transactionHash
        );        
    }

     
    function settle(address receiver, address makerAssetAddr, uint256 makerAssetAmount, uint16 feeFactor) internal returns(uint256) {
        uint256 settleAmount = deductFee(makerAssetAmount, feeFactor);

        if (makerAssetAddr == WETH_ADDR){
            USER_PROXY.sendETH(WETH_ADDR, address(uint160(receiver)), settleAmount);
        } else {
            USER_PROXY.sendToken(makerAssetAddr, receiver, settleAmount);
        }

        return settleAmount;
    }

     
    function deductFee(uint256 makerAssetAmount, uint16 feeFactor) internal pure returns (uint256) {
        if(feeFactor == 0) {
            return makerAssetAmount;
        }

        uint256 fee = SafeMath.div(SafeMath.mul(makerAssetAmount, feeFactor), 10000);
        return SafeMath.sub(makerAssetAmount, fee);
    }

     
    function registerMMP(address _marketMakerProxy, bool _add) public onlyOperator {
        isMarketMakerProxy[_marketMakerProxy] = _add;
    }

    function setProxy(IExchange _exchange, IUserProxy _userProxy, address _weth) public onlyOperator {
        ZX_EXCHANGE = _exchange;
        USER_PROXY = _userProxy;
        WETH_ADDR = _weth;

         
         
        EIP712_DOMAIN_HASH = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
                keccak256(bytes(EIP712_DOMAIN_NAME)),
                keccak256(bytes(EIP712_DOMAIN_VERSION)),
                bytes12(0),
                address(ZX_EXCHANGE)
            )
        );
    }

    function setEnabled(bool _enable) public onlyOperator {
        isEnabled = _enable;
    }

}