 

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;
 

 



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

 

 




contract LibConstants {

    bytes4 constant internal ERC20_DATA_ID = bytes4(keccak256("ERC20Token(address)"));
    bytes4 constant internal ERC721_DATA_ID = bytes4(keccak256("ERC721Token(address,uint256)"));
    bytes4 constant internal BALANCE_THRESHOLD_DATA_ID = bytes4(keccak256("BalanceThreshold(address,uint256)"));
    bytes4 constant internal OWNERSHIP_DATA_ID = bytes4(keccak256("Ownership(address,uint256)"));
    bytes4 constant internal FILLED_TIMES_DATA_ID = bytes4(keccak256("FilledTimes(uint256)"));
    uint256 constant internal MAX_UINT = 2**256 - 1;
 
     
    IExchange internal EXCHANGE;
     

    constructor (address exchange)
        public
    {
        EXCHANGE = IExchange(exchange);
    }
}

 

 




contract MExchangeCalldata {

     
     
     
     
    function exchangeCalldataload(uint256 offset)
        internal pure
        returns (bytes32 value);

     
     
     
    function loadTakerAssetDataFromOrder()
        internal pure
        returns (uint256 takerAssetAmount, bytes memory takerAssetData);

     
     
     
    function loadSignatureFromExchangeCalldata()
        internal pure
        returns (bytes memory signature);
}

 

 





contract MixinExchangeCalldata
    is MExchangeCalldata
{

     
     
     
     
    function exchangeCalldataload(uint256 offset)
        internal pure
        returns (bytes32 value)
    {
        assembly {
             
             
             
            let exchangeTxPtr := calldataload(0x44)

             
             
             
             
            let exchangeCalldataOffset := add(exchangeTxPtr, add(0x24, offset))
            value := calldataload(exchangeCalldataOffset)
        }
        return value;
    }

     
     
     
    function loadTakerAssetDataFromOrder()
        internal pure
        returns (uint256 takerAssetAmount, bytes memory takerAssetData)
    {
        assembly {
            takerAssetData := mload(0x40)
             
             
             
            let exchangeCalldataOffset := add(0x28, calldataload(0x44))
             
            let orderOffset := add(exchangeCalldataOffset, calldataload(exchangeCalldataOffset))
             
            takerAssetAmount := calldataload(add(orderOffset, 160))
            let takerAssetDataOffset := add(orderOffset, calldataload(add(orderOffset, 352)))
            let takerAssetDataLength := calldataload(takerAssetDataOffset)
             
            mstore(0x40, add(takerAssetData, and(add(add(takerAssetDataLength, 0x20), 0x1f), not(0x1f))))
            mstore(takerAssetData, takerAssetDataLength)
             
            calldatacopy(add(takerAssetData, 32), add(takerAssetDataOffset, 32), takerAssetDataLength)
        }

        return (takerAssetAmount, takerAssetData);
    }

     
     
     
    function loadSignatureFromExchangeCalldata()
        internal pure
        returns (bytes memory signature)
    {
        assembly {
            signature := mload(0x40)
             
             
             
            let exchangeCalldataOffset := add(0x28, calldataload(0x44))
             
             
            let signatureOffset := add(exchangeCalldataOffset, calldataload(add(exchangeCalldataOffset, 0x40)))
            let signatureLength := calldataload(signatureOffset)
             
            mstore(0x40, add(signature, and(add(add(signatureLength, 0x20), 0x1f), not(0x1f))))
            mstore(signature, signatureLength)
             
            calldatacopy(add(signature, 32), add(signatureOffset, 32), signatureLength)
        }

        return signature;
    }
}

 

contract MixinFakeERC20Token is
    LibConstants
{
     
     
     
     
     
    function transferFrom(address from, address to, uint256 amount)
        external returns (bool)
    {
        require(
            amount == 1,
            "INVALID_TAKER_ASSET_FILL_AMOUNT"
        );
        return true;
    }

     
     
     
     
    function allowance(address owner, address spender)
        external pure returns (uint256)
    {
        return MAX_UINT;
    }
}

 

 



contract IRequiredAsset {

     
     
     
    function balanceOf(address owner)
        external
        view
        returns (uint256);

     
     
     
    function ownerOf(uint256 tokenId)
        external
        view
        returns (address);
}

 

contract IRequirementFilterCore {

     
     
     
     
     
     
     
     
     
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes signedExchangeTransaction,
        bytes signature
    ) 
        external
        returns (bool success);

     
     
     
     
     
    function getRequirementsAchieved(
        bytes memory takerAssetData,
        address signerAddress
    )
        public view
        returns (bool[] memory requirementsAchieved);
}

 

contract MRequirementFilterCore is
    IRequirementFilterCore
{
    mapping(bytes32 => mapping(address => uint256)) internal filledTimes;

     
     
     
     
    function assertValidFilledTimes(bytes memory takerAssetData, bytes memory embeddedSignature, address signerAddress)
        internal
        returns (bool);

     
     
     
    function assertRequirementsAchieved(bytes memory takerAssetData, address signerAddress)
        internal view
        returns (bool);
}

 

 



contract LibExchangeSelectors {

     
     
    bytes4 constant public ALLOWED_VALIDATORS_SELECTOR = 0x7b8e3514;
    bytes4 constant public ALLOWED_VALIDATORS_SELECTOR_GENERATOR = bytes4(keccak256("allowedValidators(address,address)"));

     
    bytes4 constant public ASSET_PROXIES_SELECTOR = 0x3fd3c997;
    bytes4 constant public ASSET_PROXIES_SELECTOR_GENERATOR = bytes4(keccak256("assetProxies(bytes4)"));

     
    bytes4 constant public BATCH_CANCEL_ORDERS_SELECTOR = 0x4ac14782;
    bytes4 constant public BATCH_CANCEL_ORDERS_SELECTOR_GENERATOR = bytes4(keccak256("batchCancelOrders((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[])"));

     
    bytes4 constant public BATCH_FILL_OR_KILL_ORDERS_SELECTOR = 0x4d0ae546;
    bytes4 constant public BATCH_FILL_OR_KILL_ORDERS_SELECTOR_GENERATOR = bytes4(keccak256("batchFillOrKillOrders((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256[],bytes[])"));

     
    bytes4 constant public BATCH_FILL_ORDERS_SELECTOR = 0x297bb70b;
    bytes4 constant public BATCH_FILL_ORDERS_SELECTOR_GENERATOR = bytes4(keccak256("batchFillOrders((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256[],bytes[])"));

     
    bytes4 constant public BATCH_FILL_ORDERS_NO_THROW_SELECTOR = 0x50dde190;
    bytes4 constant public BATCH_FILL_ORDERS_NO_THROW_SELECTOR_GENERATOR = bytes4(keccak256("batchFillOrdersNoThrow((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256[],bytes[])"));

     
    bytes4 constant public CANCEL_ORDER_SELECTOR = 0xd46b02c3;
    bytes4 constant public CANCEL_ORDER_SELECTOR_GENERATOR = bytes4(keccak256("cancelOrder((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes))"));

     
    bytes4 constant public CANCEL_ORDERS_UP_TO_SELECTOR = 0x4f9559b1;
    bytes4 constant public CANCEL_ORDERS_UP_TO_SELECTOR_GENERATOR = bytes4(keccak256("cancelOrdersUpTo(uint256)"));

     
    bytes4 constant public CANCELLED_SELECTOR = 0x2ac12622;
    bytes4 constant public CANCELLED_SELECTOR_GENERATOR = bytes4(keccak256("cancelled(bytes32)"));

     
    bytes4 constant public CURRENT_CONTEXT_ADDRESS_SELECTOR = 0xeea086ba;
    bytes4 constant public CURRENT_CONTEXT_ADDRESS_SELECTOR_GENERATOR = bytes4(keccak256("currentContextAddress()"));

     
    bytes4 constant public EXECUTE_TRANSACTION_SELECTOR = 0xbfc8bfce;
    bytes4 constant public EXECUTE_TRANSACTION_SELECTOR_GENERATOR = bytes4(keccak256("executeTransaction(uint256,address,bytes,bytes)"));

     
    bytes4 constant public FILL_OR_KILL_ORDER_SELECTOR = 0x64a3bc15;
    bytes4 constant public FILL_OR_KILL_ORDER_SELECTOR_GENERATOR = bytes4(keccak256("fillOrKillOrder((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes),uint256,bytes)"));

     
    bytes4 constant public FILL_ORDER_SELECTOR = 0xb4be83d5;
    bytes4 constant public FILL_ORDER_SELECTOR_GENERATOR = bytes4(keccak256("fillOrder((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes),uint256,bytes)"));

     
    bytes4 constant public FILL_ORDER_NO_THROW_SELECTOR = 0x3e228bae;
    bytes4 constant public FILL_ORDER_NO_THROW_SELECTOR_GENERATOR = bytes4(keccak256("fillOrderNoThrow((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes),uint256,bytes)"));

     
    bytes4 constant public FILLED_SELECTOR = 0x288cdc91;
    bytes4 constant public FILLED_SELECTOR_GENERATOR = bytes4(keccak256("filled(bytes32)"));

     
    bytes4 constant public GET_ASSET_PROXY_SELECTOR = 0x60704108;
    bytes4 constant public GET_ASSET_PROXY_SELECTOR_GENERATOR = bytes4(keccak256("getAssetProxy(bytes4)"));

     
    bytes4 constant public GET_ORDER_INFO_SELECTOR = 0xc75e0a81;
    bytes4 constant public GET_ORDER_INFO_SELECTOR_GENERATOR = bytes4(keccak256("getOrderInfo((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes))"));

     
    bytes4 constant public GET_ORDERS_INFO_SELECTOR = 0x7e9d74dc;
    bytes4 constant public GET_ORDERS_INFO_SELECTOR_GENERATOR = bytes4(keccak256("getOrdersInfo((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[])"));

     
    bytes4 constant public IS_VALID_SIGNATURE_SELECTOR = 0x93634702;
    bytes4 constant public IS_VALID_SIGNATURE_SELECTOR_GENERATOR = bytes4(keccak256("isValidSignature(bytes32,address,bytes)"));

     
    bytes4 constant public MARKET_BUY_ORDERS_SELECTOR = 0xe5fa431b;
    bytes4 constant public MARKET_BUY_ORDERS_SELECTOR_GENERATOR = bytes4(keccak256("marketBuyOrders((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256,bytes[])"));

     
    bytes4 constant public MARKET_BUY_ORDERS_NO_THROW_SELECTOR = 0xa3e20380;
    bytes4 constant public MARKET_BUY_ORDERS_NO_THROW_SELECTOR_GENERATOR = bytes4(keccak256("marketBuyOrdersNoThrow((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256,bytes[])"));

     
    bytes4 constant public MARKET_SELL_ORDERS_SELECTOR = 0x7e1d9808;
    bytes4 constant public MARKET_SELL_ORDERS_SELECTOR_GENERATOR = bytes4(keccak256("marketSellOrders((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256,bytes[])"));

     
    bytes4 constant public MARKET_SELL_ORDERS_NO_THROW_SELECTOR = 0xdd1c7d18;
    bytes4 constant public MARKET_SELL_ORDERS_NO_THROW_SELECTOR_GENERATOR = bytes4(keccak256("marketSellOrdersNoThrow((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes)[],uint256,bytes[])"));

     
    bytes4 constant public MATCH_ORDERS_SELECTOR = 0x3c28d861;
    bytes4 constant public MATCH_ORDERS_SELECTOR_GENERATOR = bytes4(keccak256("matchOrders((address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes),(address,address,address,address,uint256,uint256,uint256,uint256,uint256,uint256,bytes,bytes),bytes,bytes)"));

     
    bytes4 constant public ORDER_EPOCH_SELECTOR = 0xd9bfa73e;
    bytes4 constant public ORDER_EPOCH_SELECTOR_GENERATOR = bytes4(keccak256("orderEpoch(address,address)"));

     
    bytes4 constant public OWNER_SELECTOR = 0x8da5cb5b;
    bytes4 constant public OWNER_SELECTOR_GENERATOR = bytes4(keccak256("owner()"));

     
    bytes4 constant public PRE_SIGN_SELECTOR = 0x3683ef8e;
    bytes4 constant public PRE_SIGN_SELECTOR_GENERATOR = bytes4(keccak256("preSign(bytes32,address,bytes)"));

     
    bytes4 constant public PRE_SIGNED_SELECTOR = 0x82c174d0;
    bytes4 constant public PRE_SIGNED_SELECTOR_GENERATOR = bytes4(keccak256("preSigned(bytes32,address)"));

     
    bytes4 constant public REGISTER_ASSET_PROXY_SELECTOR = 0xc585bb93;
    bytes4 constant public REGISTER_ASSET_PROXY_SELECTOR_GENERATOR = bytes4(keccak256("registerAssetProxy(address)"));

     
    bytes4 constant public SET_SIGNATURE_VALIDATOR_APPROVAL_SELECTOR = 0x77fcce68;
    bytes4 constant public SET_SIGNATURE_VALIDATOR_APPROVAL_SELECTOR_GENERATOR = bytes4(keccak256("setSignatureValidatorApproval(address,bool)"));

     
    bytes4 constant public TRANSACTIONS_SELECTOR = 0x642f2eaf;
    bytes4 constant public TRANSACTIONS_SELECTOR_GENERATOR = bytes4(keccak256("transactions(bytes32)"));

     
    bytes4 constant public TRANSFER_OWNERSHIP_SELECTOR = 0xf2fde38b;
    bytes4 constant public TRANSFER_OWNERSHIP_SELECTOR_GENERATOR = bytes4(keccak256("transferOwnership(address)"));
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

 

contract MixinRequirementFilterCore is
    LibConstants,
    LibExchangeSelectors,
    MExchangeCalldata,
    MRequirementFilterCore
{
    using LibBytes for bytes;

     
     
     
     
     
     
     
     
     
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes signedExchangeTransaction,
        bytes signature
    ) 
        external
        returns (bool success)
    {
        bytes4 exchangeCalldataSelector = bytes4(exchangeCalldataload(0));

        require(
            exchangeCalldataSelector == LibExchangeSelectors.FILL_ORDER_SELECTOR,
            "INVALID_EXCHANGE_SELECTOR"
        );

        (uint256 takerAssetAmount, bytes memory takerAssetData) = loadTakerAssetDataFromOrder();
        bytes memory embeddedSignature = loadSignatureFromExchangeCalldata();

         
        if (takerAssetAmount > 1) {
            assertValidFilledTimes(takerAssetData, embeddedSignature, signerAddress);
        }
         
        assertRequirementsAchieved(takerAssetData, signerAddress);

         
        EXCHANGE.executeTransaction(
            salt,
            signerAddress,
            signedExchangeTransaction,
            signature
        );

        return true;
    }

     
     
     
     
     
    function getRequirementsAchieved(bytes memory takerAssetData, address signerAddress)
        public view
        returns (bool[] memory requirementsAchieved)
    {
        uint256 index;
        bytes4 proxyId = takerAssetData.readBytes4(0);

        if (proxyId == ERC20_DATA_ID) {
            index = 36;
        } else if (proxyId == ERC721_DATA_ID) {
            index = 68;
        } else {
            revert("UNSUPPORTED_ASSET_PROXY");
        }

        uint256 requirementsNumber = 0;
        uint256 takerAssetDataLength = takerAssetData.length;
        requirementsAchieved = new bool[]((takerAssetDataLength - index) / 68);

        while (index < takerAssetDataLength) {
            bytes4 dataId = takerAssetData.readBytes4(index);
            address tokenAddress = takerAssetData.readAddress(index + 16);
            IRequiredAsset requiredToken = IRequiredAsset(tokenAddress);

            if (dataId == BALANCE_THRESHOLD_DATA_ID) {
                uint256 balanceThreshold = takerAssetData.readUint256(index + 36);
                requirementsAchieved[requirementsNumber] = requiredToken.balanceOf(signerAddress) >= balanceThreshold;
                requirementsNumber += 1;
                index += 68;
            } else if (dataId == OWNERSHIP_DATA_ID) {
                uint256 tokenId = takerAssetData.readUint256(index + 36);
                requirementsAchieved[requirementsNumber] = requiredToken.ownerOf(tokenId) == signerAddress;
                requirementsNumber += 1;
                index += 68;
            } else if (dataId == FILLED_TIMES_DATA_ID) {
                index += 36;
            } else {
                revert("UNSUPPORTED_METHOD");
            }
        }

        return requirementsAchieved;
    }

     
     
     
     
    function assertValidFilledTimes(bytes memory takerAssetData, bytes memory embeddedSignature, address signerAddress)
        internal
        returns (bool)
    {
        uint256 takerAssetDataLength = takerAssetData.length;
        bytes32 signatureHash = keccak256(embeddedSignature);
        uint256 filledTimesLimit = 1;

        if (takerAssetData.readBytes4(takerAssetDataLength - 36) == FILLED_TIMES_DATA_ID) {
            filledTimesLimit = takerAssetData.readUint256(takerAssetDataLength - 32);
        }

        require(
            filledTimes[signatureHash][signerAddress] < filledTimesLimit,
            "FILLED_TIMES_EXCEEDED"
        );

        filledTimes[signatureHash][signerAddress] += 1;

        return true;
    }

     
     
     
    function assertRequirementsAchieved(bytes memory takerAssetData, address signerAddress)
        internal view
        returns (bool)
    {
        bool[] memory requirementsAchieved = getRequirementsAchieved(takerAssetData, signerAddress);
        uint256 requirementsAchievedLength = requirementsAchieved.length;

        for (uint256 i = 0; i < requirementsAchievedLength; i += 1) {
            require(
                requirementsAchieved[i],
                "AT_LEAST_ONE_REQUIREMENT_NOT_ACHIEVED"
            );
        }

        return true;
    }
}

 

contract RequirementFilter is
    LibConstants,
    MixinExchangeCalldata,
    MixinFakeERC20Token,
    MixinRequirementFilterCore
{
    constructor (address exchange)
        public
        LibConstants(exchange)
    {}
}