 

 

pragma solidity ^0.4.24;


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

 

 

pragma solidity ^0.4.24;



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

 

 

pragma solidity ^0.4.24;


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

 

 

pragma solidity ^0.4.24;



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

 

 

pragma solidity ^0.4.24;



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

 

 

pragma solidity 0.4.24;
pragma experimental ABIEncoderV2;


contract IExchangeCore {

     
     
     
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        external;

     
     
     
     
     
    function fillOrder(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        payable
        returns (LibFillResults.FillResults memory fillResults);

     
     
    function cancelOrder(LibOrder.Order memory order)
        public;

     
     
     
     
    function getOrderInfo(LibOrder.Order memory order)
        public
        view
        returns (LibOrder.OrderInfo memory orderInfo);

     
     
     
     
    function updateOrder(
        bytes32 newOrderHash,
        uint256 newOfferAmount,
        LibOrder.Order memory orderToBeCanceled
    )
        public
        payable;
}

 

 

pragma solidity 0.4.24;


contract MExchangeCore is
    IExchangeCore
{
     
    event Fill(
        address indexed makerAddress,          
        address indexed feeRecipientAddress,   
        address takerAddress,                  
        address senderAddress,                 
        uint256 makerAssetFilledAmount,        
        uint256 takerAssetFilledAmount,        
        uint256 makerFeePaid,                  
        uint256 takerFeePaid,                  
        bytes32 indexed orderHash,             
        bytes makerAssetData,                  
        bytes takerAssetData                   
    );

     
    event Cancel(
        address indexed makerAddress,          
        address indexed feeRecipientAddress,   
        address senderAddress,                 
        bytes32 indexed orderHash,             
        bytes makerAssetData,                  
        bytes takerAssetData                   
    );

     
    event CancelUpTo(
        address indexed makerAddress,          
        address indexed senderAddress,         
        uint256 orderEpoch                     
    );

     
    event Transfer(
        address indexed toAddress,
        uint256 indexed amount
    );

     
     
     
     
     
    function fillOrderInternal(
        LibOrder.Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        internal
        returns (LibFillResults.FillResults memory fillResults);

     
     
    function cancelOrderInternal(LibOrder.Order memory order)
        internal
        returns (LibOrder.OrderInfo);

     
     
     
     
     
    function updateFilledState(
        LibOrder.Order memory order,
        address takerAddress,
        bytes32 orderHash,
        uint256 orderTakerAssetFilledAmount,
        LibFillResults.FillResults memory fillResults
    )
        internal;

     
     
     
     
     
    function updateCancelledState(
        LibOrder.Order memory order,
        bytes32 orderHash
    )
        internal;
    
     
     
     
     
     
    function assertFillableOrder(
        LibOrder.Order memory order,
        LibOrder.OrderInfo memory orderInfo,
        address takerAddress,
        bytes memory signature
    )
        internal
        view;
    
     
     
     
     
     
     
    function assertValidFill(
        LibOrder.Order memory order,
        LibOrder.OrderInfo memory orderInfo,
        uint256 takerAssetFillAmount,
        uint256 takerAssetFilledAmount,
        uint256 makerAssetFilledAmount
    )
        internal
        view;

     
     
     
    function assertValidCancel(
        LibOrder.Order memory order,
        LibOrder.OrderInfo memory orderInfo
    )
        internal
        view;

     
     
     
     
    function calculateFillResults(
        LibOrder.Order memory order,
        uint256 takerAssetFilledAmount
    )
        internal
        pure
        returns (LibFillResults.FillResults memory fillResults);

}

 

 

pragma solidity 0.4.24;


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

 

 

pragma solidity 0.4.24;


contract MSignatureValidator is
    ISignatureValidator
{
    event SignatureValidatorApproval(
        address indexed signerAddress,      
        address indexed validatorAddress,   
        bool approved                       
    );

     
    enum SignatureType {
        Illegal,          
        Invalid,          
        EIP712,           
        EthSign,          
        Wallet,           
        Validator,        
        PreSigned,        
        NSignatureTypes   
    }

     
     
     
     
     
     
    function isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes signature
    )
        internal
        view
        returns (bool isValid);

     
     
     
     
     
     
    function isValidValidatorSignature(
        address validatorAddress,
        bytes32 hash,
        address signerAddress,
        bytes signature
    )
        internal
        view
        returns (bool isValid);
}

 

 

pragma solidity 0.4.24;


contract ITransactions {

     
     
     
     
     
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes data,
        bytes signature
    )
        external;
}

 

 

pragma solidity 0.4.24;


contract MTransactions is
    ITransactions
{
     
    bytes32 constant internal EIP712_ZEROEX_TRANSACTION_SCHEMA_HASH = keccak256(abi.encodePacked(
        "ZeroExTransaction(",
        "uint256 salt,",
        "address signerAddress,",
        "bytes data",
        ")"
    ));

     
     
     
     
     
    function hashZeroExTransaction(
        uint256 salt,
        address signerAddress,
        bytes memory data
    )
        internal
        pure
        returns (bytes32 result);

     
     
     
     
     
    function getCurrentContextAddress()
        internal
        view
        returns (address);
}

 

 

pragma solidity 0.4.24;


contract IAssetProxyDispatcher {

     
     
     
    function registerAssetProxy(address assetProxy)
        external;

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
}

 

 

pragma solidity 0.4.24;


contract MAssetProxyDispatcher is
    IAssetProxyDispatcher
{
     
    event AssetProxyRegistered(
        bytes4 id,               
        address assetProxy       
    );

     
     
     
     
     
    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal;
}

 

 

pragma solidity ^0.4.24;


contract ReentrancyGuard {

     
    bool private locked = false;

     
     
    modifier nonReentrant() {
         
        require(
            !locked,
            "REENTRANCY_ILLEGAL"
        );

         
        locked = true;

         
        _;

         
        locked = false;
    }
}

 

 

pragma solidity 0.4.24;


contract Operational
{
    address public owner;
    address[] public withdrawOperators;  
    mapping (address => bool) public isWithdrawOperator;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event WithdrawOperatorAdded(
        address indexed target,
        address indexed caller
    );

    event WithdrawOperatorRemoved(
        address indexed target,
        address indexed caller
    );

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

    modifier withdrawable(address toAddress) {
        require(
            isWithdrawOperator[msg.sender] || toAddress == msg.sender,
            "SENDER_IS_NOT_WITHDRAWABLE"
        );
        _;
    }

    function transferOwnership(address newOwner)
        public
        onlyOwner
    {
        require(
            newOwner != address(0),
            "INVALID_OWNER"
        );
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function addWithdrawOperator(address target)
        external
        onlyOwner
    {
        require(
            !isWithdrawOperator[target],
            "TARGET_IS_ALREADY_WITHDRAW_OPERATOR"
        );

        isWithdrawOperator[target] = true;
        withdrawOperators.push(target);
        emit WithdrawOperatorAdded(target, msg.sender);
    }

    function removeWithdrawOperator(address target)
        external
        onlyOwner
    {
        require(
            isWithdrawOperator[target],
            "TARGET_IS_NOT_WITHDRAW_OPERATOR"
        );

        delete isWithdrawOperator[target];
        for (uint256 i = 0; i < withdrawOperators.length; i++) {
            if (withdrawOperators[i] == target) {
                withdrawOperators[i] = withdrawOperators[withdrawOperators.length - 1];
                withdrawOperators.length -= 1;
                break;
            }
        }
        emit WithdrawOperatorRemoved(target, msg.sender);
    }
}

 

 

pragma solidity 0.4.24;


contract DepositManager is
    Operational,
    ReentrancyGuard,
    SafeMath
{
     
    mapping (address => uint256) public depositAmount;
     
    mapping (bytes32 => mapping (address => uint256)) public orderToDepositAmount;

     
    event Deposit(
        bytes32 indexed orderHash,
        address indexed senderAddress,
        uint256 amount
    );

     
    event DepositChanged(
        bytes32 indexed newOrderHash,
        uint256 newAmount,
        bytes32 indexed oldOrderHash,
        uint256 oldAmount,
        address indexed senderAddress
    );

     
    event Withdraw(
        bytes32 indexed orderHash,
        address indexed toAddress,
        uint256 amount
    );

     
     
    function deposit(bytes32 orderHash)
        public
        payable
        nonReentrant
    {
        depositInternal(orderHash, msg.sender, msg.value);
    }

     
     
     
    function withdraw(bytes32 orderHash, address toAddress)
        public
        nonReentrant
        withdrawable(toAddress)
    {
        withdrawInternal(orderHash, toAddress);
    }

    function depositInternal(bytes32 orderHash, address sender, uint256 amount)
        internal
    {
        depositAmount[sender] = safeAdd(depositAmount[sender], amount);
        orderToDepositAmount[orderHash][sender] = safeAdd(orderToDepositAmount[orderHash][sender], amount);
        emit Deposit(orderHash, sender, amount);
    }

    function withdrawInternal(bytes32 orderHash, address toAddress)
        internal
    {
        if (orderToDepositAmount[orderHash][toAddress] > 0) {
            uint256 amount = orderToDepositAmount[orderHash][toAddress];
            depositAmount[toAddress] = safeSub(depositAmount[toAddress], amount);
            delete orderToDepositAmount[orderHash][toAddress];
            toAddress.transfer(amount);
            emit Withdraw(orderHash, toAddress, amount);
        }
    }

    function changeDeposit(
        bytes32 newOrderHash,
        uint256 newOfferAmount,
        bytes32 oldOrderHash,
        uint256 oldOfferAmount,
        address sender
    )
        internal
    {
        if (msg.value > 0) {
            depositAmount[sender] = safeAdd(depositAmount[sender], msg.value);
            orderToDepositAmount[newOrderHash][sender] = safeAdd(orderToDepositAmount[newOrderHash][sender], msg.value);
        }
        uint256 oldOrderToDepositAmount = orderToDepositAmount[oldOrderHash][sender];
        moveDeposit(oldOrderHash, newOrderHash, sender);
        if (oldOrderToDepositAmount > newOfferAmount) {
            uint256 refundAmount = safeSub(orderToDepositAmount[newOrderHash][sender], newOfferAmount);
            orderToDepositAmount[newOrderHash][sender] = safeSub(orderToDepositAmount[newOrderHash][sender], refundAmount);
            depositAmount[sender] = safeSub(depositAmount[sender], refundAmount);
            sender.transfer(refundAmount);
        }
        emit DepositChanged(newOrderHash, newOfferAmount, oldOrderHash, oldOfferAmount, sender);
    }

    function moveDeposit(
        bytes32 fromOrderHash,
        bytes32 toOrderHash,
        address sender
    )
        internal
    {
        uint256 amount = orderToDepositAmount[fromOrderHash][sender];
        delete orderToDepositAmount[fromOrderHash][sender];
        orderToDepositAmount[toOrderHash][sender] = safeAdd(orderToDepositAmount[toOrderHash][sender], amount);
    }

    function deductOrderToDepositAmount(
        bytes32 orderHash,
        address target,
        uint256 amount
    )
        internal
    {
        orderToDepositAmount[orderHash][target] = safeSub(orderToDepositAmount[orderHash][target], amount);
    }
}

 

 

pragma solidity 0.4.24;


 
contract LibConstants {
     
     
     
    bytes constant public ETH_ASSET_DATA = "\xf4\x72\x61\xb0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00";
    bytes32 constant public KECCAK256_ETH_ASSET_DATA = keccak256(ETH_ASSET_DATA);
    uint256 constant public TRANSFER_GAS_LIMIT = 300000;  
}
 

 

 

pragma solidity 0.4.24;


contract MixinExchangeCore is
    DepositManager,
    LibConstants,
    LibMath,
    LibOrder,
    LibFillResults,
    MAssetProxyDispatcher,
    MExchangeCore,
    MSignatureValidator,
    MTransactions
{
     
    mapping (bytes32 => uint256) public filled;

     
    mapping (bytes32 => bool) public cancelled;

     
     
    mapping (address => mapping (address => uint256)) public orderEpoch;

     
     
     
    function cancelOrdersUpTo(uint256 targetOrderEpoch)
        external
        nonReentrant
    {
        address makerAddress = getCurrentContextAddress();
         
         
        address senderAddress = makerAddress == msg.sender ? address(0) : msg.sender;

         
        uint256 newOrderEpoch = targetOrderEpoch + 1;
        uint256 oldOrderEpoch = orderEpoch[makerAddress][senderAddress];

         
        require(
            newOrderEpoch > oldOrderEpoch,
            "INVALID_NEW_ORDER_EPOCH"
        );

         
        orderEpoch[makerAddress][senderAddress] = newOrderEpoch;
        emit CancelUpTo(
            makerAddress,
            senderAddress,
            newOrderEpoch
        );
    }

     
     
     
     
     
    function fillOrder(
        Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        payable
        nonReentrant
        returns (FillResults memory fillResults)
    {
        fillResults = fillOrderInternal(
            order,
            takerAssetFillAmount,
            signature
        );
        return fillResults;
    }

     
     
     
    function cancelOrder(Order memory order)
        public
        nonReentrant
    {
        OrderInfo memory orderInfo = cancelOrderInternal(order);
        withdrawInternal(orderInfo.orderHash, msg.sender);
    }

     
     
     
     
    function getOrderInfo(Order memory order)
        public
        view
        returns (OrderInfo memory orderInfo)
    {
         
        orderInfo.orderHash = getOrderHash(order);

         
        orderInfo.orderTakerAssetFilledAmount = filled[orderInfo.orderHash];

         
         
         
         
        if (order.makerAssetAmount == 0) {
            orderInfo.orderStatus = uint8(OrderStatus.INVALID_MAKER_ASSET_AMOUNT);
            return orderInfo;
        }

         
         
         
         
        if (order.takerAssetAmount == 0) {
            orderInfo.orderStatus = uint8(OrderStatus.INVALID_TAKER_ASSET_AMOUNT);
            return orderInfo;
        }

         
        if (orderInfo.orderTakerAssetFilledAmount >= order.takerAssetAmount) {
            orderInfo.orderStatus = uint8(OrderStatus.FULLY_FILLED);
            return orderInfo;
        }

         
         
        if (block.timestamp >= order.expirationTimeSeconds) {
            orderInfo.orderStatus = uint8(OrderStatus.EXPIRED);
            return orderInfo;
        }

         
        if (cancelled[orderInfo.orderHash]) {
            orderInfo.orderStatus = uint8(OrderStatus.CANCELLED);
            return orderInfo;
        }
        if (orderEpoch[order.makerAddress][order.senderAddress] > order.salt) {
            orderInfo.orderStatus = uint8(OrderStatus.CANCELLED);
            return orderInfo;
        }

         
        orderInfo.orderStatus = uint8(OrderStatus.FILLABLE);
        return orderInfo;
    }

     
     
     
     
    function updateOrder(
        bytes32 newOrderHash,
        uint256 newOfferAmount,
        Order memory orderToBeCanceled
    )
        public
        payable
        nonReentrant
    {
        OrderInfo memory orderInfo = cancelOrderInternal(orderToBeCanceled);
        uint256 oldOfferAmount = safeAdd(orderToBeCanceled.makerAssetAmount, orderToBeCanceled.makerFee);
        changeDeposit(newOrderHash, newOfferAmount, orderInfo.orderHash, oldOfferAmount, msg.sender);
    }

     
     
     
     
     
    function fillOrderInternal(
        Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        internal
        returns (FillResults memory fillResults)
    {
         
        OrderInfo memory orderInfo = getOrderInfo(order);

         
        address takerAddress = getCurrentContextAddress();

         
         
        if (msg.value > 0) {
            depositInternal(orderInfo.orderHash, takerAddress, msg.value);
        }

         
        assertFillableOrder(
            order,
            orderInfo,
            takerAddress,
            signature
        );

         
        uint256 remainingTakerAssetAmount = safeSub(order.takerAssetAmount, orderInfo.orderTakerAssetFilledAmount);
        uint256 takerAssetFilledAmount = min256(takerAssetFillAmount, remainingTakerAssetAmount);

         
        fillResults = calculateFillResults(order, takerAssetFilledAmount);

         
        assertValidFill(
            order,
            orderInfo,
            takerAssetFillAmount,
            takerAssetFilledAmount,
            fillResults.makerAssetFilledAmount
        );

         
        updateFilledState(
            order,
            takerAddress,
            orderInfo.orderHash,
            orderInfo.orderTakerAssetFilledAmount,
            fillResults
        );

         
        settleOrder(
            order,
            takerAddress,
            fillResults
        );

         
        if (keccak256(order.makerAssetData) == KECCAK256_ETH_ASSET_DATA) {
            deductOrderToDepositAmount(
                orderInfo.orderHash,
                order.makerAddress,
                safeAdd(fillResults.makerAssetFilledAmount, fillResults.makerFeePaid)
            );
        }
        if (keccak256(order.takerAssetData) == KECCAK256_ETH_ASSET_DATA) {
            deductOrderToDepositAmount(
                orderInfo.orderHash,
                takerAddress,
                safeAdd(fillResults.takerAssetFilledAmount, fillResults.takerFeePaid)
            );
        }

        return fillResults;
    }

     
     
     
     
    function cancelOrderInternal(Order memory order)
        internal
        returns (OrderInfo)
    {
         
        OrderInfo memory orderInfo = getOrderInfo(order);

         
        assertValidCancel(order, orderInfo);

         
        updateCancelledState(order, orderInfo.orderHash);

        return orderInfo;
    }

     
     
     
     
    function updateFilledState(
        Order memory order,
        address takerAddress,
        bytes32 orderHash,
        uint256 orderTakerAssetFilledAmount,
        FillResults memory fillResults
    )
        internal
    {
         
        filled[orderHash] = safeAdd(orderTakerAssetFilledAmount, fillResults.takerAssetFilledAmount);

         
        emit Fill(
            order.makerAddress,
            order.feeRecipientAddress,
            takerAddress,
            msg.sender,
            fillResults.makerAssetFilledAmount,
            fillResults.takerAssetFilledAmount,
            fillResults.makerFeePaid,
            fillResults.takerFeePaid,
            orderHash,
            order.makerAssetData,
            order.takerAssetData
        );
    }

     
     
     
     
     
    function updateCancelledState(
        Order memory order,
        bytes32 orderHash
    )
        internal
    {
         
        cancelled[orderHash] = true;

         
        emit Cancel(
            order.makerAddress,
            order.feeRecipientAddress,
            msg.sender,
            orderHash,
            order.makerAssetData,
            order.takerAssetData
        );
    }

     
     
     
     
     
    function assertFillableOrder(
        Order memory order,
        OrderInfo memory orderInfo,
        address takerAddress,
        bytes memory signature
    )
        internal
        view
    {
         
        require(
            orderInfo.orderStatus == uint8(OrderStatus.FILLABLE),
            "ORDER_UNFILLABLE"
        );

         
        if (order.senderAddress != address(0)) {
            require(
                order.senderAddress == msg.sender,
                "INVALID_SENDER"
            );
        }

         
        if (order.takerAddress != address(0)) {
            require(
                order.takerAddress == takerAddress,
                "INVALID_TAKER"
            );
        }

         
        if (orderInfo.orderTakerAssetFilledAmount == 0) {
            require(
                isValidSignature(
                    orderInfo.orderHash,
                    order.makerAddress,
                    signature
                ),
                "INVALID_ORDER_SIGNATURE"
            );
        }
    }

     
     
     
     
     
     
    function assertValidFill(
        Order memory order,
        OrderInfo memory orderInfo,
        uint256 takerAssetFillAmount,   
        uint256 takerAssetFilledAmount,
        uint256 makerAssetFilledAmount
    )
        internal
        view
    {
         
         
        require(
            takerAssetFillAmount != 0,
            "INVALID_TAKER_AMOUNT"
        );

         
         
         
        require(
            takerAssetFilledAmount <= takerAssetFillAmount,
            "TAKER_OVERPAY"
        );

         
         
         
        require(
            safeAdd(orderInfo.orderTakerAssetFilledAmount, takerAssetFilledAmount) <= order.takerAssetAmount,
            "ORDER_OVERFILL"
        );

         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
         
        require(
            safeMul(makerAssetFilledAmount, order.takerAssetAmount)
            <=
            safeMul(order.makerAssetAmount, takerAssetFilledAmount),
            "INVALID_FILL_PRICE"
        );
    }

     
     
     
    function assertValidCancel(
        Order memory order,
        OrderInfo memory orderInfo
    )
        internal
        view
    {
         
         
        require(
            orderInfo.orderStatus == uint8(OrderStatus.FILLABLE),
            "ORDER_UNFILLABLE"
        );

         
        if (order.senderAddress != address(0)) {
            require(
                order.senderAddress == msg.sender,
                "INVALID_SENDER"
            );
        }

         
        address makerAddress = getCurrentContextAddress();
        require(
            order.makerAddress == makerAddress,
            "INVALID_MAKER"
        );
    }

     
     
     
     
    function calculateFillResults(
        Order memory order,
        uint256 takerAssetFilledAmount
    )
        internal
        pure
        returns (FillResults memory fillResults)
    {
         
        fillResults.takerAssetFilledAmount = takerAssetFilledAmount;
        fillResults.makerAssetFilledAmount = safeGetPartialAmountFloor(
            takerAssetFilledAmount,
            order.takerAssetAmount,
            order.makerAssetAmount
        );
        fillResults.makerFeePaid = safeGetPartialAmountFloor(
            fillResults.makerAssetFilledAmount,
            order.makerAssetAmount,
            order.makerFee
        );
        fillResults.takerFeePaid = safeGetPartialAmountFloor(
            takerAssetFilledAmount,
            order.takerAssetAmount,
            order.takerFee
        );

        return fillResults;
    }

     
     
     
     
    function settleOrder(
        LibOrder.Order memory order,
        address takerAddress,
        LibFillResults.FillResults memory fillResults
    )
        private
    {
        bytes memory ethAssetData = ETH_ASSET_DATA;
        dispatchTransferFrom(
            order.makerAssetData,
            order.makerAddress,
            takerAddress,
            fillResults.makerAssetFilledAmount
        );
        dispatchTransferFrom(
            order.takerAssetData,
            takerAddress,
            order.makerAddress,
            fillResults.takerAssetFilledAmount
        );
        dispatchTransferFrom(
            ethAssetData,
            order.makerAddress,
            order.feeRecipientAddress,
            fillResults.makerFeePaid
        );
        dispatchTransferFrom(
            ethAssetData,
            takerAddress,
            order.feeRecipientAddress,
            fillResults.takerFeePaid
        );
    }
}

 

 

pragma solidity ^0.4.24;


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

 

 

pragma solidity 0.4.24;


contract IWallet {

     
     
     
     
    function isValidSignature(
        bytes32 hash,
        bytes signature
    )
        external
        view
        returns (bool isValid);
}

 

 

pragma solidity 0.4.24;


contract IValidator {

     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes signature
    )
        external
        view
        returns (bool isValid);
}

 

 

pragma solidity 0.4.24;


contract MixinSignatureValidator is
    ReentrancyGuard,
    MSignatureValidator,
    MTransactions
{
    using LibBytes for bytes;

     
    mapping (bytes32 => mapping (address => bool)) public preSigned;

     
    mapping (address => mapping (address => bool)) public allowedValidators;

     
     
     
     
    function preSign(
        bytes32 hash,
        address signerAddress,
        bytes signature
    )
        external
    {
        if (signerAddress != msg.sender) {
            require(
                isValidSignature(
                    hash,
                    signerAddress,
                    signature
                ),
                "INVALID_SIGNATURE"
            );
        }
        preSigned[hash][signerAddress] = true;
    }

     
     
     
    function setSignatureValidatorApproval(
        address validatorAddress,
        bool approval
    )
        external
        nonReentrant
    {
        address signerAddress = getCurrentContextAddress();
        allowedValidators[signerAddress][validatorAddress] = approval;
        emit SignatureValidatorApproval(
            signerAddress,
            validatorAddress,
            approval
        );
    }

     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    )
        public
        view
        returns (bool isValid)
    {
        require(
            signature.length > 0,
            "LENGTH_GREATER_THAN_0_REQUIRED"
        );

         
        uint8 signatureTypeRaw = uint8(signature.popLastByte());

         
        require(
            signatureTypeRaw < uint8(SignatureType.NSignatureTypes),
            "SIGNATURE_UNSUPPORTED"
        );

        SignatureType signatureType = SignatureType(signatureTypeRaw);

         
        uint8 v;
        bytes32 r;
        bytes32 s;
        address recovered;

         
         
         
         
         
        if (signatureType == SignatureType.Illegal) {
            revert("SIGNATURE_ILLEGAL");

         
         
         
         
        } else if (signatureType == SignatureType.Invalid) {
            require(
                signature.length == 0,
                "LENGTH_0_REQUIRED"
            );
            isValid = false;
            return isValid;

         
        } else if (signatureType == SignatureType.EIP712) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(
                hash,
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;
            return isValid;

         
        } else if (signatureType == SignatureType.EthSign) {
            require(
                signature.length == 65,
                "LENGTH_65_REQUIRED"
            );
            v = uint8(signature[0]);
            r = signature.readBytes32(1);
            s = signature.readBytes32(33);
            recovered = ecrecover(
                keccak256(abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    hash
                )),
                v,
                r,
                s
            );
            isValid = signerAddress == recovered;
            return isValid;

         
         
        } else if (signatureType == SignatureType.Wallet) {
            isValid = isValidWalletSignature(
                hash,
                signerAddress,
                signature
            );
            return isValid;

         
         
         
         
         
         
         
        } else if (signatureType == SignatureType.Validator) {
             
            address validatorAddress = signature.popLast20Bytes();

             
            if (!allowedValidators[signerAddress][validatorAddress]) {
                return false;
            }
            isValid = isValidValidatorSignature(
                validatorAddress,
                hash,
                signerAddress,
                signature
            );
            return isValid;

         
        } else if (signatureType == SignatureType.PreSigned) {
            isValid = preSigned[hash][signerAddress];
            return isValid;
        }

         
         
         
         
         
        revert("SIGNATURE_UNSUPPORTED");
    }

     
     
     
     
     
     
    function isValidWalletSignature(
        bytes32 hash,
        address walletAddress,
        bytes signature
    )
        internal
        view
        returns (bool isValid)
    {
        bytes memory calldata = abi.encodeWithSelector(
            IWallet(walletAddress).isValidSignature.selector,
            hash,
            signature
        );
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidWalletSignature(bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(walletAddress)) {
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(calldata, 32)
            let success := staticcall(
                gas,               
                walletAddress,     
                cdStart,           
                mload(calldata),   
                cdStart,           
                32                 
            )

            if iszero(eq(returndatasize(), 32)) {
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000c57414c4c45545f4552524f5200000000000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                 
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }

     
     
     
     
     
     
    function isValidValidatorSignature(
        address validatorAddress,
        bytes32 hash,
        address signerAddress,
        bytes signature
    )
        internal
        view
        returns (bool isValid)
    {
        bytes memory calldata = abi.encodeWithSelector(
            IValidator(signerAddress).isValidSignature.selector,
            hash,
            signerAddress,
            signature
        );
        bytes32 magic_salt = bytes32(bytes4(keccak256("isValidValidatorSignature(address,bytes32,address,bytes)")));
        assembly {
            if iszero(extcodesize(validatorAddress)) {
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f56414c494441544f525f4552524f5200000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            let cdStart := add(calldata, 32)
            let success := staticcall(
                gas,                
                validatorAddress,   
                cdStart,            
                mload(calldata),    
                cdStart,            
                32                  
            )

            if iszero(eq(returndatasize(), 32)) {
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f56414c494441544f525f4552524f5200000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }

            switch success
            case 0 {
                 
                mstore(0, 0x08c379a000000000000000000000000000000000000000000000000000000000)
                mstore(32, 0x0000002000000000000000000000000000000000000000000000000000000000)
                mstore(64, 0x0000000f56414c494441544f525f4552524f5200000000000000000000000000)
                mstore(96, 0)
                revert(0, 100)
            }
            case 1 {
                 
                isValid := eq(
                    and(mload(cdStart), 0xffffffff00000000000000000000000000000000000000000000000000000000),
                    and(magic_salt, 0xffffffff00000000000000000000000000000000000000000000000000000000)
                )
            }
        }
        return isValid;
    }
}

 

 

pragma solidity 0.4.24;


contract MixinWrapperFunctions is
    ReentrancyGuard,
    LibMath,
    MExchangeCore
{
     
     
    function batchCancelOrders(LibOrder.Order[] memory orders)
        public
        nonReentrant
    {
        uint256 ordersLength = orders.length;
        for (uint256 i = 0; i != ordersLength; i++) {
            cancelOrderInternal(orders[i]);
        }
    }

     
     
     
    function getOrdersInfo(LibOrder.Order[] memory orders)
        public
        view
        returns (LibOrder.OrderInfo[] memory)
    {
        uint256 ordersLength = orders.length;
        LibOrder.OrderInfo[] memory ordersInfo = new LibOrder.OrderInfo[](ordersLength);
        for (uint256 i = 0; i != ordersLength; i++) {
            ordersInfo[i] = getOrderInfo(orders[i]);
        }
        return ordersInfo;
    }

}

 

pragma solidity ^0.4.24;


contract IOwnable {

    function transferOwnership(address newOwner)
        public;
}

 

 

pragma solidity ^0.4.24;



contract IAuthorizable is
    IOwnable
{
     
     
    function addAuthorizedAddress(address target)
        external;

     
     
    function removeAuthorizedAddress(address target)
        external;

     
     
     
    function removeAuthorizedAddressAtIndex(
        address target,
        uint256 index
    )
        external;
    
     
     
    function getAuthorizedAddresses()
        external
        view
        returns (address[] memory);
}

 

 

pragma solidity ^0.4.24;



contract IAssetProxy is
    IAuthorizable
{
     
     
     
     
     
    function transferFrom(
        bytes assetData,
        address from,
        address to,
        uint256 amount
    )
        external;
    
     
     
    function getProxyId()
        external
        pure
        returns (bytes4);
}

 

 

pragma solidity 0.4.24;


contract MixinAssetProxyDispatcher is
    DepositManager,
    LibConstants,
    MAssetProxyDispatcher
{
     
    mapping (bytes4 => IAssetProxy) public assetProxies;

     
     
     
    function registerAssetProxy(address assetProxy)
        external
        onlyOwner
    {
        IAssetProxy assetProxyContract = IAssetProxy(assetProxy);

         
        bytes4 assetProxyId = assetProxyContract.getProxyId();
        address currentAssetProxy = assetProxies[assetProxyId];
        require(
            currentAssetProxy == address(0),
            "ASSET_PROXY_ALREADY_EXISTS"
        );

         
        assetProxies[assetProxyId] = assetProxyContract;
        emit AssetProxyRegistered(
            assetProxyId,
            assetProxy
        );
    }

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address)
    {
        return assetProxies[assetProxyId];
    }

     
     
     
     
     
    function dispatchTransferFrom(
        bytes memory assetData,
        address from,
        address to,
        uint256 amount
    )
        internal
    {
         
        if (amount > 0 && from != to) {
             
            require(
                assetData.length > 3,
                "LENGTH_GREATER_THAN_3_REQUIRED"
            );

             
            if (keccak256(assetData) == KECCAK256_ETH_ASSET_DATA) {
                require(
                    depositAmount[from] >= amount,
                    "DEPOSIT_AMOUNT_IS_INSUFFICIENT"
                );
                uint256 afterBalance = safeSub(depositAmount[from], amount);
                depositAmount[from] = afterBalance;
                if (to != address(this)) {
                    if (!to.call.gas(TRANSFER_GAS_LIMIT).value(amount)()) {
                        revert("ETH_SENDING_FAILED");
                    }
                }
                return;
            }

             
            bytes4 assetProxyId;
            assembly {
                assetProxyId := and(mload(
                    add(assetData, 32)),
                    0xFFFFFFFF00000000000000000000000000000000000000000000000000000000
                )
            }
            address assetProxy = assetProxies[assetProxyId];

             
            require(
                assetProxy != address(0),
                "ASSET_PROXY_DOES_NOT_EXIST"
            );
            
             
             
             
             
             
             
             
             
             
             
             
             
             
             

            assembly {
                 
                 
                let cdStart := mload(64)
                 
                 
                 
                let dataAreaLength := and(add(mload(assetData), 63), 0xFFFFFFFFFFFE0)
                 
                let cdEnd := add(cdStart, add(132, dataAreaLength))

                
                 
                 
                 
                mstore(cdStart, 0xa85e59e400000000000000000000000000000000000000000000000000000000)
                
                 
                 
                 
                 
                 
                mstore(add(cdStart, 4), 128)
                mstore(add(cdStart, 36), and(from, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 68), and(to, 0xffffffffffffffffffffffffffffffffffffffff))
                mstore(add(cdStart, 100), amount)
                
                 
                 
                let dataArea := add(cdStart, 132)
                 
                for {} lt(dataArea, cdEnd) {} {
                    mstore(dataArea, mload(assetData))
                    dataArea := add(dataArea, 32)
                    assetData := add(assetData, 32)
                }

                 
                let success := call(
                    gas,                     
                    assetProxy,              
                    0,                       
                    cdStart,                 
                    sub(cdEnd, cdStart),     
                    cdStart,                 
                    512                      
                )
                if iszero(success) {
                    revert(cdStart, returndatasize())
                }
            }
        }
    }
}

 

 

 
pragma solidity ^0.4.24;


 
 
contract LibExchangeErrors {

     
    string constant ORDER_UNFILLABLE = "ORDER_UNFILLABLE";                               
    string constant INVALID_MAKER = "INVALID_MAKER";                                     
    string constant INVALID_TAKER = "INVALID_TAKER";                                     
    string constant INVALID_SENDER = "INVALID_SENDER";                                   
    string constant INVALID_ORDER_SIGNATURE = "INVALID_ORDER_SIGNATURE";                 
    
     
    string constant INVALID_TAKER_AMOUNT = "INVALID_TAKER_AMOUNT";                       
    string constant ROUNDING_ERROR = "ROUNDING_ERROR";                                   
    
     
    string constant INVALID_SIGNATURE = "INVALID_SIGNATURE";                             
    string constant SIGNATURE_ILLEGAL = "SIGNATURE_ILLEGAL";                             
    string constant SIGNATURE_UNSUPPORTED = "SIGNATURE_UNSUPPORTED";                     
    
     
    string constant INVALID_NEW_ORDER_EPOCH = "INVALID_NEW_ORDER_EPOCH";                 

     
    string constant COMPLETE_FILL_FAILED = "COMPLETE_FILL_FAILED";                       

     
    string constant NEGATIVE_SPREAD_REQUIRED = "NEGATIVE_SPREAD_REQUIRED";               

     
    string constant REENTRANCY_ILLEGAL = "REENTRANCY_ILLEGAL";                           
    string constant INVALID_TX_HASH = "INVALID_TX_HASH";                                 
    string constant INVALID_TX_SIGNATURE = "INVALID_TX_SIGNATURE";                       
    string constant FAILED_EXECUTION = "FAILED_EXECUTION";                               
    
     
    string constant ASSET_PROXY_ALREADY_EXISTS = "ASSET_PROXY_ALREADY_EXISTS";           

     
    string constant ASSET_PROXY_DOES_NOT_EXIST = "ASSET_PROXY_DOES_NOT_EXIST";           
    string constant TRANSFER_FAILED = "TRANSFER_FAILED";                                 

     
    string constant LENGTH_GREATER_THAN_0_REQUIRED = "LENGTH_GREATER_THAN_0_REQUIRED";   
    string constant LENGTH_GREATER_THAN_3_REQUIRED = "LENGTH_GREATER_THAN_3_REQUIRED";   
    string constant LENGTH_0_REQUIRED = "LENGTH_0_REQUIRED";                             
    string constant LENGTH_65_REQUIRED = "LENGTH_65_REQUIRED";                           
}

 

 

pragma solidity 0.4.24;


contract MixinTransactions is
    LibEIP712,
    MSignatureValidator,
    MTransactions
{
     
     
    mapping (bytes32 => bool) public transactions;

     
    address public currentContextAddress;

     
     
     
     
     
    function executeTransaction(
        uint256 salt,
        address signerAddress,
        bytes data,
        bytes signature
    )
        external
    {
         
        require(
            currentContextAddress == address(0),
            "REENTRANCY_ILLEGAL"
        );

        bytes32 transactionHash = hashEIP712Message(hashZeroExTransaction(
            salt,
            signerAddress,
            data
        ));

         
        require(
            !transactions[transactionHash],
            "INVALID_TX_HASH"
        );

         
        if (signerAddress != msg.sender) {
             
            require(
                isValidSignature(
                    transactionHash,
                    signerAddress,
                    signature
                ),
                "INVALID_TX_SIGNATURE"
            );

             
            currentContextAddress = signerAddress;
        }

         
        transactions[transactionHash] = true;
        require(
            address(this).delegatecall(data),
            "FAILED_EXECUTION"
        );

         
        if (signerAddress != msg.sender) {
            currentContextAddress = address(0);
        }
    }

     
     
     
     
     
    function hashZeroExTransaction(
        uint256 salt,
        address signerAddress,
        bytes memory data
    )
        internal
        pure
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
        return result;
    }

     
     
     
     
     
    function getCurrentContextAddress()
        internal
        view
        returns (address)
    {
        address currentContextAddress_ = currentContextAddress;
        address contextAddress = currentContextAddress_ == address(0) ? msg.sender : currentContextAddress_;
        return contextAddress;
    }
}

 

 

pragma solidity 0.4.24;


 
contract Exchange is
    MixinExchangeCore,
    MixinSignatureValidator,
    MixinTransactions,
    MixinWrapperFunctions,
    MixinAssetProxyDispatcher
{
    string constant public VERSION = "2.0.1-alpha-miime";

     
    constructor ()
        public
        MixinExchangeCore()
        MixinSignatureValidator()
        MixinTransactions()
        MixinAssetProxyDispatcher()
        MixinWrapperFunctions()
    {}
}