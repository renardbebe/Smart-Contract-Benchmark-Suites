 

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;

contract IERC20Token {

     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 _value
    );

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

     
     
     
     
    function transfer(address _to, uint256 _value)
        external
        returns (bool);

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        external
        returns (bool);

     
     
     
     
    function approve(address _spender, uint256 _value)
        external
        returns (bool);

     
     
    function totalSupply()
        external
        view
        returns (uint256);

     
     
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

     
     
     
    function allowance(address _owner, address _spender)
        external
        view
        returns (uint256);
}


contract SafeMath {

    function safeMul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(
            c / a == b,
            "UINT256_OVERFLOW"
        );
        return c;
    }

    function safeDiv(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a / b;
        return c;
    }

    function safeSub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(
            b <= a,
            "UINT256_UNDERFLOW"
        );
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        uint256 c = a + b;
        require(
            c >= a,
            "UINT256_OVERFLOW"
        );
        return c;
    }

    function max64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        return a < b ? a : b;
    }
}

 


contract LibMath is
    SafeMath
{
     
     
     
     
     
     
    function safeGetPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorFloor(
                numerator,
                denominator,
                target
            ),
            "ROUNDING_ERROR"
        );

        partialAmount = safeDiv(
            safeMul(numerator, target),
            denominator
        );
        return partialAmount;
    }

     
     
     
     
     
     
    function safeGetPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        require(
            !isRoundingErrorCeil(
                numerator,
                denominator,
                target
            ),
            "ROUNDING_ERROR"
        );

         
         
         
        partialAmount = safeDiv(
            safeAdd(
                safeMul(numerator, target),
                safeSub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }

     
     
     
     
     
    function getPartialAmountFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

        partialAmount = safeDiv(
            safeMul(numerator, target),
            denominator
        );
        return partialAmount;
    }

     
     
     
     
     
    function getPartialAmountCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

         
         
         
        partialAmount = safeDiv(
            safeAdd(
                safeMul(numerator, target),
                safeSub(denominator, 1)
            ),
            denominator
        );
        return partialAmount;
    }

     
     
     
     
     
    function isRoundingErrorFloor(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

         
         
         
         
         
         
         
         
         
         
         
         
         
        if (target == 0 || numerator == 0) {
            return false;
        }

         
         
         
         
         
         
         
         
         
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        isError = safeMul(1000, remainder) >= safeMul(numerator, target);
        return isError;
    }

     
     
     
     
     
    function isRoundingErrorCeil(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (bool isError)
    {
        require(
            denominator > 0,
            "DIVISION_BY_ZERO"
        );

         
        if (target == 0 || numerator == 0) {
             
             
             
            return false;
        }
         
        uint256 remainder = mulmod(
            target,
            numerator,
            denominator
        );
        remainder = safeSub(denominator, remainder) % denominator;
        isError = safeMul(1000, remainder) >= safeMul(numerator, target);
        return isError;
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
            bytes32(address(this))
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

 


contract LibFillResults is
    SafeMath
{
    struct FillResults {
        uint256 makerAssetFilledAmount;   
        uint256 takerAssetFilledAmount;   
        uint256 makerFeePaid;             
        uint256 takerFeePaid;             
    }

    struct MatchedFillResults {
        FillResults left;                     
        FillResults right;                    
        uint256 leftMakerAssetSpreadAmount;   
    }

     
     
     
     
    function addFillResults(FillResults memory totalFillResults, FillResults memory singleFillResults)
        internal
        pure
    {
        totalFillResults.makerAssetFilledAmount = safeAdd(totalFillResults.makerAssetFilledAmount, singleFillResults.makerAssetFilledAmount);
        totalFillResults.takerAssetFilledAmount = safeAdd(totalFillResults.takerAssetFilledAmount, singleFillResults.takerAssetFilledAmount);
        totalFillResults.makerFeePaid = safeAdd(totalFillResults.makerFeePaid, singleFillResults.makerFeePaid);
        totalFillResults.takerFeePaid = safeAdd(totalFillResults.takerFeePaid, singleFillResults.takerFeePaid);
    }
}

 


contract IExchangeCore {

     
     
     
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        external;

     
     
     
     
     
    function fillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);

     
     
    function cancelOrder(LibOrder.Order memory order)
        public;

     
     
     
     
    function getOrderInfo(LibOrder.Order memory order)
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo);
}

 


contract IMatchOrders {

     
     
     
     
     
     
     
     
     
    function matchOrders(
        LibOrder.Order memory leftOrder,
        LibOrder.Order memory rightOrder,
        bytes memory leftSignature,
        bytes memory rightSignature
    )
        public
        returns (LibFillResults.MatchedFillResults memory matchedFillResults);
}

 



contract ISignatureValidator {

     
     
     
     
    function preSign(
        bytes32 hash,
        address signerAddress,
        bytes signature
    )
        external;

     
     
     
    function setSignatureValidatorApproval(
        address validatorAddress,
        bool approval
    )
        external;

     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid);
}

 


contract ITransactions {

     
     
     
     
     
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes data,
        bytes signature
    )
        external;
}

 


contract IAssetProxyDispatcher {

     
     
     
    function registerAssetProxy(address assetProxy)
        external;

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
}

 


contract IWrapperFunctions {

     
     
     
     
    function fillOrKillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);

     
     
     
     
     
     
    function fillOrderNoThrow(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (LibFillResults.FillResults memory fillResults);

     
     
     
     
     
    function batchFillOrders(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
    function batchFillOrKillOrders(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
     
    function batchFillOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256[] memory takerAssetFillAmounts,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
    function marketSellOrders(
        LibOrder.Order[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
     
    function marketSellOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256 takerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
    function marketBuyOrders(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
     
    function marketBuyOrdersNoThrow(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        public
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
    function batchCancelOrders(LibOrder.Order[] memory orders)
        public;

     
     
     
    function getOrdersInfo(LibOrder.Order[] memory orders)
        public
        view
        returns (LibOrder.OrderInfo[] memory);
}

 


 
contract IExchange is
    IExchangeCore,
    IMatchOrders,
    ISignatureValidator,
    ITransactions,
    IAssetProxyDispatcher,
    IWrapperFunctions
{}

 


 


contract IEtherToken is
    IERC20Token
{
    function deposit()
        public
        payable;

    function withdraw(uint256 amount)
        public;
}

 



 



contract LibConstants {

    using LibBytes for bytes;

    bytes4 constant internal ERC20_DATA_ID = bytes4(keccak256("ERC20Token(address)"));
    bytes4 constant internal ERC721_DATA_ID = bytes4(keccak256("ERC721Token(address,uint256)"));
    uint256 constant internal MAX_UINT = 2**256 - 1;
    uint256 constant internal PERCENTAGE_DENOMINATOR = 10**18;
    uint256 constant internal MAX_FEE_PERCENTAGE = 5 * PERCENTAGE_DENOMINATOR / 100;          
    uint256 constant internal MAX_WETH_FILL_PERCENTAGE = 95 * PERCENTAGE_DENOMINATOR / 100;   

      
    IExchange internal EXCHANGE;
    IEtherToken internal ETHER_TOKEN;
    IERC20Token internal ZRX_TOKEN;
    bytes internal ZRX_ASSET_DATA;
    bytes internal WETH_ASSET_DATA;
     

    constructor (
        address _exchange,
        bytes memory _zrxAssetData,
        bytes memory _wethAssetData
    )
        public
    {
        EXCHANGE = IExchange(_exchange);
        ZRX_ASSET_DATA = _zrxAssetData;
        WETH_ASSET_DATA = _wethAssetData;

        address etherToken = _wethAssetData.readAddress(16);
        address zrxToken = _zrxAssetData.readAddress(16);
        ETHER_TOKEN = IEtherToken(etherToken);
        ZRX_TOKEN = IERC20Token(zrxToken);
    }
}

 


contract MWeth {

     
    function convertEthToWeth()
        internal;

     
     
     
     
     
     
    function transferEthFeeAndRefund(
        uint256 wethSoldExcludingFeeOrders,
        uint256 wethSoldForZrx,
        uint256 feePercentage,
        address feeRecipient
    )
        internal;
}

 


contract MixinWeth is
    LibMath,
    LibConstants,
    MWeth
{
     
    function ()
        public
        payable
    {
        require(
            msg.sender == address(ETHER_TOKEN),
            "DEFAULT_FUNCTION_WETH_CONTRACT_ONLY"
        );
    }

     
    function convertEthToWeth()
        internal
    {
        require(
            msg.value > 0,
            "INVALID_MSG_VALUE"
        );
        ETHER_TOKEN.deposit.value(msg.value)();
    }

     
     
     
     
     
     
    function transferEthFeeAndRefund(
        uint256 wethSoldExcludingFeeOrders,
        uint256 wethSoldForZrx,
        uint256 feePercentage,
        address feeRecipient
    )
        internal
    {
         
        require(
            feePercentage <= MAX_FEE_PERCENTAGE,
            "FEE_PERCENTAGE_TOO_LARGE"
        );

         
        uint256 wethSold = safeAdd(wethSoldExcludingFeeOrders, wethSoldForZrx);
        require(
            wethSold <= msg.value,
            "OVERSOLD_WETH"
        );

         
        uint256 wethRemaining = safeSub(msg.value, wethSold);

         
        uint256 ethFee = getPartialAmountFloor(
            feePercentage,
            PERCENTAGE_DENOMINATOR,
            wethSoldExcludingFeeOrders
        );

         
        require(
            ethFee <= wethRemaining,
            "INSUFFICIENT_ETH_REMAINING"
        );

         
        if (wethRemaining > 0) {
             
            ETHER_TOKEN.withdraw(wethRemaining);

             
            if (ethFee > 0) {
                feeRecipient.transfer(ethFee);
            }

             
            uint256 ethRefund = safeSub(wethRemaining, ethFee);
            if (ethRefund > 0) {
                msg.sender.transfer(ethRefund);
            }
        }
    }
}

 



contract IAssets {

     
     
     
     
     
    function withdrawAsset(
        bytes assetData,
        uint256 amount
    )
        external;
}

 



contract MAssets is
    IAssets
{
     
     
     
    function transferAssetToSender(
        bytes memory assetData,
        uint256 amount
    )
        internal;

     
     
     
    function transferERC20Token(
        bytes memory assetData,
        uint256 amount
    )
        internal;

     
     
     
    function transferERC721Token(
        bytes memory assetData,
        uint256 amount
    )
        internal;
}

 


contract MExchangeWrapper {

     
     
     
     
     
     
    function fillOrderNoThrow(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        internal
        returns (LibFillResults.FillResults memory fillResults);

     
     
     
     
     
     
    function marketSellWeth(
        LibOrder.Order[] memory orders,
        uint256 wethSellAmount,
        bytes[] memory signatures
    )
        internal
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
     
     
    function marketBuyExactAmountWithWeth(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        internal
        returns (LibFillResults.FillResults memory totalFillResults);

     
     
     
     
     
     
     
     
     
    function marketBuyExactZrxWithWeth(
        LibOrder.Order[] memory orders,
        uint256 zrxBuyAmount,
        bytes[] memory signatures
    )
        internal
        returns (LibFillResults.FillResults memory totalFillResults);
}

 


contract IForwarderCore {

     
     
     
     
     
     
     
     
     
     
     
    function marketSellOrdersWithEth(
        LibOrder.Order[] memory orders,
        bytes[] memory signatures,
        LibOrder.Order[] memory feeOrders,
        bytes[] memory feeSignatures,
        uint256  feePercentage,
        address feeRecipient
    )
        public
        payable
        returns (
            LibFillResults.FillResults memory orderFillResults,
            LibFillResults.FillResults memory feeOrderFillResults
        );

     
     
     
     
     
     
     
     
     
     
     
    function marketBuyOrdersWithEth(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures,
        LibOrder.Order[] memory feeOrders,
        bytes[] memory feeSignatures,
        uint256  feePercentage,
        address feeRecipient
    )
        public
        payable
        returns (
            LibFillResults.FillResults memory orderFillResults,
            LibFillResults.FillResults memory feeOrderFillResults
        );
}

 


contract MixinForwarderCore is
    LibFillResults,
    LibMath,
    LibConstants,
    MWeth,
    MAssets,
    MExchangeWrapper,
    IForwarderCore
{
    using LibBytes for bytes;

     
    constructor ()
        public
    {
        address proxyAddress = EXCHANGE.getAssetProxy(ERC20_DATA_ID);
        require(
            proxyAddress != address(0),
            "UNREGISTERED_ASSET_PROXY"
        );
        ETHER_TOKEN.approve(proxyAddress, MAX_UINT);
        ZRX_TOKEN.approve(proxyAddress, MAX_UINT);
    }

     
     
     
     
     
     
     
     
     
     
     
    function marketSellOrdersWithEth(
        LibOrder.Order[] memory orders,
        bytes[] memory signatures,
        LibOrder.Order[] memory feeOrders,
        bytes[] memory feeSignatures,
        uint256  feePercentage,
        address feeRecipient
    )
        public
        payable
        returns (
            FillResults memory orderFillResults,
            FillResults memory feeOrderFillResults
        )
    {
         
        convertEthToWeth();

        uint256 wethSellAmount;
        uint256 zrxBuyAmount;
        uint256 makerAssetAmountPurchased;
        if (orders[0].makerAssetData.equals(ZRX_ASSET_DATA)) {
             
            wethSellAmount = getPartialAmountFloor(
                PERCENTAGE_DENOMINATOR,
                safeAdd(PERCENTAGE_DENOMINATOR, feePercentage),
                msg.value
            );
             
             
            orderFillResults = marketSellWeth(
                orders,
                wethSellAmount,
                signatures
            );
             
            makerAssetAmountPurchased = safeSub(orderFillResults.makerAssetFilledAmount, orderFillResults.takerFeePaid);
        } else {
             
            wethSellAmount = getPartialAmountFloor(
                MAX_WETH_FILL_PERCENTAGE,
                PERCENTAGE_DENOMINATOR,
                msg.value
            );
             
             
            orderFillResults = marketSellWeth(
                orders,
                wethSellAmount,
                signatures
            );
             
            zrxBuyAmount = orderFillResults.takerFeePaid;
            feeOrderFillResults = marketBuyExactZrxWithWeth(
                feeOrders,
                zrxBuyAmount,
                feeSignatures
            );
            makerAssetAmountPurchased = orderFillResults.makerAssetFilledAmount;
        }

         
         
        transferEthFeeAndRefund(
            orderFillResults.takerAssetFilledAmount,
            feeOrderFillResults.takerAssetFilledAmount,
            feePercentage,
            feeRecipient
        );

         
        transferAssetToSender(orders[0].makerAssetData, makerAssetAmountPurchased);
    }

     
     
     
     
     
     
     
     
     
     
     
    function marketBuyOrdersWithEth(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures,
        LibOrder.Order[] memory feeOrders,
        bytes[] memory feeSignatures,
        uint256  feePercentage,
        address feeRecipient
    )
        public
        payable
        returns (
            FillResults memory orderFillResults,
            FillResults memory feeOrderFillResults
        )
    {
         
        convertEthToWeth();

        uint256 zrxBuyAmount;
        uint256 makerAssetAmountPurchased;
        if (orders[0].makerAssetData.equals(ZRX_ASSET_DATA)) {
             
             
            orderFillResults = marketBuyExactZrxWithWeth(
                orders,
                makerAssetFillAmount,
                signatures
            );
             
            makerAssetAmountPurchased = safeSub(orderFillResults.makerAssetFilledAmount, orderFillResults.takerFeePaid);
        } else {
             
             
            orderFillResults = marketBuyExactAmountWithWeth(
                orders,
                makerAssetFillAmount,
                signatures
            );
             
            zrxBuyAmount = orderFillResults.takerFeePaid;
            feeOrderFillResults = marketBuyExactZrxWithWeth(
                feeOrders,
                zrxBuyAmount,
                feeSignatures
            );
            makerAssetAmountPurchased = orderFillResults.makerAssetFilledAmount;
        }

         
         
        transferEthFeeAndRefund(
            orderFillResults.takerAssetFilledAmount,
            feeOrderFillResults.takerAssetFilledAmount,
            feePercentage,
            feeRecipient
        );

         
        transferAssetToSender(orders[0].makerAssetData, makerAssetAmountPurchased);
    }
}


contract IOwnable {

    function transferOwnership(address newOwner)
        public;
}


contract Ownable is
    IOwnable
{
    address public owner;

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

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 


contract IERC721Token {

     
     
     
     
     
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

     
     
     
     
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

     
     
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

     
     
     
     
     
     
     
     
     
     
     
     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    )
        external;

     
     
     
     
     
     
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external;

     
     
     
     
     
     
    function approve(address _approved, uint256 _tokenId)
        external;

     
     
     
     
     
     
    function setApprovalForAll(address _operator, bool _approved)
        external;

     
     
     
     
     
    function balanceOf(address _owner)
        external
        view
        returns (uint256);

     
     
     
     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        public;

     
     
     
     
     
    function ownerOf(uint256 _tokenId)
        public
        view
        returns (address);

     
     
     
     
    function getApproved(uint256 _tokenId)
        public
        view
        returns (address);

     
     
     
     
    function isApprovedForAll(address _owner, address _operator)
        public
        view
        returns (bool);
}

 



contract MixinAssets is
    Ownable,
    LibConstants,
    MAssets
{
    using LibBytes for bytes;

    bytes4 constant internal ERC20_TRANSFER_SELECTOR = bytes4(keccak256("transfer(address,uint256)"));

     
     
     
     
     
    function withdrawAsset(
        bytes assetData,
        uint256 amount
    )
        external
        onlyOwner
    {
        transferAssetToSender(assetData, amount);
    }

     
     
     
    function transferAssetToSender(
        bytes memory assetData,
        uint256 amount
    )
        internal
    {
        bytes4 proxyId = assetData.readBytes4(0);

        if (proxyId == ERC20_DATA_ID) {
            transferERC20Token(assetData, amount);
        } else if (proxyId == ERC721_DATA_ID) {
            transferERC721Token(assetData, amount);
        } else {
            revert("UNSUPPORTED_ASSET_PROXY");
        }
    }

     
     
     
    function transferERC20Token(
        bytes memory assetData,
        uint256 amount
    )
        internal
    {
        address token = assetData.readAddress(16);

         
         
         
        bool success = token.call(abi.encodeWithSelector(
            ERC20_TRANSFER_SELECTOR,
            msg.sender,
            amount
        ));
        require(
            success,
            "TRANSFER_FAILED"
        );

         
         
         
         
         
         
        assembly {
            if returndatasize {
                success := 0
                if eq(returndatasize, 32) {
                     
                    returndatacopy(0, 0, 32)
                    success := mload(0)
                }
            }
        }
        require(
            success,
            "TRANSFER_FAILED"
        );
    }

     
     
     
    function transferERC721Token(
        bytes memory assetData,
        uint256 amount
    )
        internal
    {
        require(
            amount == 1,
            "INVALID_AMOUNT"
        );
         
        address token = assetData.readAddress(16);
        uint256 tokenId = assetData.readUint256(36);

         
        IERC721Token(token).transferFrom(
            address(this),
            msg.sender,
            tokenId
        );
    }
}

 



 



contract LibAbiEncoder {

     
     
     
     
     
    function abiEncodeFillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        internal
        pure
        returns (bytes memory fillOrderCalldata)
    {
         
         
         

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         

         
         
         

         

         

        assembly {

             
             
             
             
             
             
             
             

             
             
            fillOrderCalldata := mload(0x40)
             
             
             
            mstore(add(fillOrderCalldata, 0x20), 0xb4be83d500000000000000000000000000000000000000000000000000000000)
            let headerAreaEnd := add(fillOrderCalldata, 0x24)

             
             
             
            let paramsAreaStart := headerAreaEnd
            let paramsAreaEnd := add(paramsAreaStart, 0x60)
            let paramsAreaOffset := paramsAreaStart

             
            let dataAreaStart := paramsAreaEnd
            let dataAreaEnd := dataAreaStart

             
            let sourceOffset := order
             
            let arrayLenBytes := 0
            let arrayLenWords := 0

             
             
             
            mstore(paramsAreaOffset, sub(dataAreaEnd, paramsAreaStart))
            paramsAreaOffset := add(paramsAreaOffset, 0x20)

             
             
             
            mstore(dataAreaEnd, mload(sourceOffset))                             
            mstore(add(dataAreaEnd, 0x20), mload(add(sourceOffset, 0x20)))       
            mstore(add(dataAreaEnd, 0x40), mload(add(sourceOffset, 0x40)))       
            mstore(add(dataAreaEnd, 0x60), mload(add(sourceOffset, 0x60)))       
            mstore(add(dataAreaEnd, 0x80), mload(add(sourceOffset, 0x80)))       
            mstore(add(dataAreaEnd, 0xA0), mload(add(sourceOffset, 0xA0)))       
            mstore(add(dataAreaEnd, 0xC0), mload(add(sourceOffset, 0xC0)))       
            mstore(add(dataAreaEnd, 0xE0), mload(add(sourceOffset, 0xE0)))       
            mstore(add(dataAreaEnd, 0x100), mload(add(sourceOffset, 0x100)))     
            mstore(add(dataAreaEnd, 0x120), mload(add(sourceOffset, 0x120)))     
            mstore(add(dataAreaEnd, 0x140), mload(add(sourceOffset, 0x140)))     
            mstore(add(dataAreaEnd, 0x160), mload(add(sourceOffset, 0x160)))     
            dataAreaEnd := add(dataAreaEnd, 0x180)
            sourceOffset := add(sourceOffset, 0x180)

             
            mstore(add(dataAreaStart, mul(10, 0x20)), sub(dataAreaEnd, dataAreaStart))

             
            sourceOffset := mload(add(order, 0x140))  
            arrayLenBytes := mload(sourceOffset)
            sourceOffset := add(sourceOffset, 0x20)
            arrayLenWords := div(add(arrayLenBytes, 0x1F), 0x20)

             
            mstore(dataAreaEnd, arrayLenBytes)
            dataAreaEnd := add(dataAreaEnd, 0x20)

             
            for {let i := 0} lt(i, arrayLenWords) {i := add(i, 1)} {
                mstore(dataAreaEnd, mload(sourceOffset))
                dataAreaEnd := add(dataAreaEnd, 0x20)
                sourceOffset := add(sourceOffset, 0x20)
            }

             
            mstore(add(dataAreaStart, mul(11, 0x20)), sub(dataAreaEnd, dataAreaStart))

             
            sourceOffset := mload(add(order, 0x160))  
            arrayLenBytes := mload(sourceOffset)
            sourceOffset := add(sourceOffset, 0x20)
            arrayLenWords := div(add(arrayLenBytes, 0x1F), 0x20)

             
            mstore(dataAreaEnd, arrayLenBytes)
            dataAreaEnd := add(dataAreaEnd, 0x20)

             
            for {let i := 0} lt(i, arrayLenWords) {i := add(i, 1)} {
                mstore(dataAreaEnd, mload(sourceOffset))
                dataAreaEnd := add(dataAreaEnd, 0x20)
                sourceOffset := add(sourceOffset, 0x20)
            }

             
            mstore(paramsAreaOffset, takerAssetFillAmount)
            paramsAreaOffset := add(paramsAreaOffset, 0x20)

             
             
            mstore(paramsAreaOffset, sub(dataAreaEnd, paramsAreaStart))

             
            sourceOffset := signature
            arrayLenBytes := mload(sourceOffset)
            sourceOffset := add(sourceOffset, 0x20)
            arrayLenWords := div(add(arrayLenBytes, 0x1F), 0x20)

             
            mstore(dataAreaEnd, arrayLenBytes)
            dataAreaEnd := add(dataAreaEnd, 0x20)

             
            for {let i := 0} lt(i, arrayLenWords) {i := add(i, 1)} {
                mstore(dataAreaEnd, mload(sourceOffset))
                dataAreaEnd := add(dataAreaEnd, 0x20)
                sourceOffset := add(sourceOffset, 0x20)
            }

             
            mstore(fillOrderCalldata, sub(dataAreaEnd, add(fillOrderCalldata, 0x20)))

             
            mstore(0x40, dataAreaEnd)
        }

        return fillOrderCalldata;
    }
}

 


contract MixinExchangeWrapper is
    LibAbiEncoder,
    LibFillResults,
    LibMath,
    LibConstants,
    MExchangeWrapper
{
     
     
     
     
     
     
    function fillOrderNoThrow(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        internal
        returns (FillResults memory fillResults)
    {
         
        bytes memory fillOrderCalldata = abiEncodeFillOrder(
            order,
            takerAssetFillAmount,
            signature
        );

        address exchange = address(EXCHANGE);

         
        assembly {
            let success := call(
                gas,                                 
                exchange,                            
                0,                                   
                add(fillOrderCalldata, 32),          
                mload(fillOrderCalldata),            
                fillOrderCalldata,                   
                128                                  
            )
            if success {
                mstore(fillResults, mload(fillOrderCalldata))
                mstore(add(fillResults, 32), mload(add(fillOrderCalldata, 32)))
                mstore(add(fillResults, 64), mload(add(fillOrderCalldata, 64)))
                mstore(add(fillResults, 96), mload(add(fillOrderCalldata, 96)))
            }
        }
         
        return fillResults;
    }

     
     
     
     
     
     
    function marketSellWeth(
        LibOrder.Order[] memory orders,
        uint256 wethSellAmount,
        bytes[] memory signatures
    )
        internal
        returns (FillResults memory totalFillResults)
    {
        bytes memory makerAssetData = orders[0].makerAssetData;
        bytes memory wethAssetData = WETH_ASSET_DATA;

        uint256 ordersLength = orders.length;
        for (uint256 i = 0; i != ordersLength; i++) {

             
             
            orders[i].makerAssetData = makerAssetData;
            orders[i].takerAssetData = wethAssetData;

             
            uint256 remainingTakerAssetFillAmount = safeSub(wethSellAmount, totalFillResults.takerAssetFilledAmount);

             
            FillResults memory singleFillResults = fillOrderNoThrow(
                orders[i],
                remainingTakerAssetFillAmount,
                signatures[i]
            );

             
            addFillResults(totalFillResults, singleFillResults);

             
            if (totalFillResults.takerAssetFilledAmount >= wethSellAmount) {
                break;
            }
        }
        return totalFillResults;
    }

     
     
     
     
     
     
     
    function marketBuyExactAmountWithWeth(
        LibOrder.Order[] memory orders,
        uint256 makerAssetFillAmount,
        bytes[] memory signatures
    )
        internal
        returns (FillResults memory totalFillResults)
    {
        bytes memory makerAssetData = orders[0].makerAssetData;
        bytes memory wethAssetData = WETH_ASSET_DATA;

        uint256 ordersLength = orders.length;
        for (uint256 i = 0; i != ordersLength; i++) {

             
             
            orders[i].makerAssetData = makerAssetData;
            orders[i].takerAssetData = wethAssetData;

             
            uint256 remainingMakerAssetFillAmount = safeSub(makerAssetFillAmount, totalFillResults.makerAssetFilledAmount);

             
             
             
             
            uint256 remainingTakerAssetFillAmount = getPartialAmountCeil(
                orders[i].takerAssetAmount,
                orders[i].makerAssetAmount,
                remainingMakerAssetFillAmount
            );

             
            FillResults memory singleFillResults = fillOrderNoThrow(
                orders[i],
                remainingTakerAssetFillAmount,
                signatures[i]
            );

             
            addFillResults(totalFillResults, singleFillResults);

             
            uint256 makerAssetFilledAmount = totalFillResults.makerAssetFilledAmount;
            if (makerAssetFilledAmount >= makerAssetFillAmount) {
                break;
            }
        }

        require(
            makerAssetFilledAmount >= makerAssetFillAmount,
            "COMPLETE_FILL_FAILED"
        );
        return totalFillResults;
    }

     
     
     
     
     
     
     
     
     
    function marketBuyExactZrxWithWeth(
        LibOrder.Order[] memory orders,
        uint256 zrxBuyAmount,
        bytes[] memory signatures
    )
        internal
        returns (FillResults memory totalFillResults)
    {
         
        if (zrxBuyAmount == 0) {
            return totalFillResults;
        }

        bytes memory zrxAssetData = ZRX_ASSET_DATA;
        bytes memory wethAssetData = WETH_ASSET_DATA;
        uint256 zrxPurchased = 0;

        uint256 ordersLength = orders.length;
        for (uint256 i = 0; i != ordersLength; i++) {

             
            orders[i].makerAssetData = zrxAssetData;
            orders[i].takerAssetData = wethAssetData;

             
            uint256 remainingZrxBuyAmount = safeSub(zrxBuyAmount, zrxPurchased);

             
             
             
             
            uint256 remainingWethSellAmount = getPartialAmountCeil(
                orders[i].takerAssetAmount,
                safeSub(orders[i].makerAssetAmount, orders[i].takerFee),   
                remainingZrxBuyAmount
            );

             
            FillResults memory singleFillResult = fillOrderNoThrow(
                orders[i],
                remainingWethSellAmount,
                signatures[i]
            );

             
            addFillResults(totalFillResults, singleFillResult);
            zrxPurchased = safeSub(totalFillResults.makerAssetFilledAmount, totalFillResults.takerFeePaid);

             
            if (zrxPurchased >= zrxBuyAmount) {
                break;
            }
        }

        require(
            zrxPurchased >= zrxBuyAmount,
            "COMPLETE_FILL_FAILED"
        );
        return totalFillResults;
    }
}

 



 
contract Forwarder is
    LibConstants,
    MixinWeth,
    MixinAssets,
    MixinExchangeWrapper,
    MixinForwarderCore
{
    constructor (
        address _exchange,
        bytes memory _zrxAssetData,
        bytes memory _wethAssetData
    )
        public
        LibConstants(
            _exchange,
            _zrxAssetData,
            _wethAssetData
        )
        MixinForwarderCore()
    {}
}