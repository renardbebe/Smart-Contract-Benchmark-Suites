 

 

pragma solidity ^0.5.7;

 
 
library LibBytes {

    using LibBytes for bytes;

     
     
     
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
        if (from > to || to > b.length) {
            return "";
        }

         
        result = new bytes(to - from);
        memCopy(
            result.contentAddress(),
            b.contentAddress() + from,
            result.length
        );
        return result;
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
}

 

pragma solidity ^0.5.7;

contract LibMath {
     
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }

     
     
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

        partialAmount = div(
            mul(numerator, target),
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

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
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

        partialAmount = div(
            mul(numerator, target),
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

        partialAmount = div(
            add(
                mul(numerator, target),
                sub(denominator, 1)
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
        isError = mul(1000, remainder) >= mul(numerator, target);
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
        remainder = sub(denominator, remainder) % denominator;
        isError = mul(1000, remainder) >= mul(numerator, target);
        return isError;
    }
}

 

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

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

pragma solidity ^0.5.7;

 
interface IBank {

     
     
     
    function authorize(address target, bool allowed) external;

     
     
     
    function userApprove(address target, bool allowed) external;

     
     
     
    function batchUserApprove(address[] calldata targetList, bool[] calldata allowedList) external;

     
     
    function getAuthorizedAddresses() external view returns (address[] memory);

     
     
    function getUserApprovedAddresses() external view returns (address[] memory);

     
     
     
     
     
     
    function hasDeposit(address token, address user, uint256 amount, bytes calldata data) external view returns (bool);

     
     
     
     
     
    function getAvailable(address token, address user, bytes calldata data) external view returns (uint256);

     
     
     
     
    function balanceOf(address token, address user) external view returns (uint256);

     
     
     
     
     
    function deposit(address token, address user, uint256 amount, bytes calldata data) external payable;

     
     
     
     
    function withdraw(address token, uint256 amount, bytes calldata data) external;

     
     
     
     
     
     
     
     
     
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount,
        bytes calldata data,
        bool fromDeposit,
        bool toDeposit
    )
    external;
}

 

pragma solidity ^0.5.7;

contract Common {
    struct Order {
        address maker;
        address taker;
        address makerToken;
        address takerToken;
        address makerTokenBank;
        address takerTokenBank;
        address reseller;
        address verifier;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 expires;
        uint256 nonce;
        uint256 minimumTakerAmount;
        bytes makerData;
        bytes takerData;
        bytes signature;
    }

    struct OrderInfo {
        uint8 orderStatus;
        bytes32 orderHash;
        uint256 filledTakerAmount;
    }

    struct FillResults {
        uint256 makerFilledAmount;
        uint256 makerFeeExchange;
        uint256 makerFeeReseller;
        uint256 takerFilledAmount;
        uint256 takerFeeExchange;
        uint256 takerFeeReseller;
    }

    struct MatchedFillResults {
        FillResults left;
        FillResults right;
        uint256 spreadAmount;
    }
}

 

pragma solidity ^0.5.7;


 
contract Verifier is Common {

     
     
     
     
     
    function verify(
        Order memory order,
        uint256 takerAmountToFill,
        address taker
    )
    public
    view
    returns (bool);

     
     
     
    function verifyUser(address user)
    external
    view
    returns (bool);
}

 

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;








 
contract EverbloomExchange is Ownable, ReentrancyGuard, LibMath {

    using LibBytes for bytes;

     
    uint256 public constant MAX_FEE_PERCENTAGE = 0.005 * 10 ** 18;  

     
    address public feeAccount;

     
     
     
     
     
     
     
     
     
    mapping(address => uint256[4]) public fees;

     
     
    mapping(bytes32 => uint256) filled;

     
     
    mapping(bytes32 => bool) cancelled;

     
     
    mapping(uint8 => mapping(address => bool)) whitelists;

    enum WhitelistType {
        BANK,
        FEE_EXEMPT_BANK,  
        RESELLER,
        VERIFIER
    }

    enum OrderStatus {
        INVALID,
        INVALID_SIGNATURE,
        INVALID_MAKER_AMOUNT,
        INVALID_TAKER_AMOUNT,
        FILLABLE,
        EXPIRED,
        FULLY_FILLED,
        CANCELLED
    }

    event SetFeeAccount(address feeAccount);
    event SetFee(address reseller, uint256 makerFee, uint256 takerFee);
    event SetWhitelist(uint8 wlType, address addr, bool allowed);
    event CancelOrder(
        bytes32 indexed orderHash,
        address indexed maker,
        address makerToken,
        address takerToken,
        address indexed reseller,
        uint256 makerAmount,
        uint256 takerAmount,
        bytes makerData,
        bytes takerData
    );
    event FillOrder(
        bytes32 indexed orderHash,
        address indexed maker,
        address taker,
        address makerToken,
        address takerToken,
        address indexed reseller,
        uint256 makerFilledAmount,
        uint256 makerFeeExchange,
        uint256 makerFeeReseller,
        uint256 takerFilledAmount,
        uint256 takerFeeExchange,
        uint256 takerFeeReseller,
        bytes makerData,
        bytes takerData
    );

     
     
    function setFeeAccount(
        address _feeAccount
    )
    public
    onlyOwner
    {
        feeAccount = _feeAccount;
        emit SetFeeAccount(_feeAccount);
    }

     
     
     
     
    function setFee(
        address reseller,
        uint256[4] calldata _fees
    )
    external
    onlyOwner
    {
        if (reseller == address(0)) {
             
            require(_fees[1] == 0 && _fees[3] == 0, "INVALID_NULL_RESELLER_FEE");
        }
        uint256 makerFee = add(_fees[0], _fees[1]);
        uint256 takerFee = add(_fees[2], _fees[3]);
         
        require(add(makerFee, takerFee) <= MAX_FEE_PERCENTAGE, "FEE_TOO_HIGH");
        fees[reseller] = _fees;
        emit SetFee(reseller, makerFee, takerFee);
    }

     
     
     
     
    function setWhitelist(
        WhitelistType wlType,
        address addr,
        bool allowed
    )
    external
    onlyOwner
    {
        whitelists[uint8(wlType)][addr] = allowed;
        emit SetWhitelist(uint8(wlType), addr, allowed);
    }

     
     
    function cancelOrder(
        Common.Order memory order
    )
    public
    nonReentrant
    {
        cancelOrderInternal(order);
    }

     
     
    function cancelOrders(
        Common.Order[] memory orderList
    )
    public
    nonReentrant
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            cancelOrderInternal(orderList[i]);
        }
    }

     
     
     
     
     
    function fillOrder(
        Common.Order memory order,
        uint256 takerAmountToFill,
        bool allowInsufficient
    )
    public
    nonReentrant
    returns (Common.FillResults memory results)
    {
        results = fillOrderInternal(
            order,
            takerAmountToFill,
            allowInsufficient
        );
        return results;
    }

     
     
     
     
     
    function fillOrderNoThrow(
        Common.Order memory order,
        uint256 takerAmountToFill,
        bool allowInsufficient
    )
    public
    returns (Common.FillResults memory results)
    {
        bytes memory callData = abi.encodeWithSelector(
            this.fillOrder.selector,
            order,
            takerAmountToFill,
            allowInsufficient
        );
        assembly {
             
            let success := delegatecall(
                gas,                 
                address,             
                add(callData, 32),   
                mload(callData),     
                callData,            
                192                  
            )
             
            if success {
                mstore(results, mload(callData))
                mstore(add(results, 32), mload(add(callData, 32)))
                mstore(add(results, 64), mload(add(callData, 64)))
                mstore(add(results, 96), mload(add(callData, 96)))
                mstore(add(results, 128), mload(add(callData, 128)))
                mstore(add(results, 160), mload(add(callData, 160)))
            }
        }
        return results;
    }

     
     
     
     
    function fillOrders(
        Common.Order[] memory orderList,
        uint256[] memory takerAmountToFillList,
        bool[] memory allowInsufficientList
    )
    public
    nonReentrant
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            fillOrderInternal(
                orderList[i],
                takerAmountToFillList[i],
                allowInsufficientList[i]
            );
        }
    }

     
     
     
     
    function fillOrdersNoThrow(
        Common.Order[] memory orderList,
        uint256[] memory takerAmountToFillList,
        bool[] memory allowInsufficientList
    )
    public
    nonReentrant
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            fillOrderNoThrow(
                orderList[i],
                takerAmountToFillList[i],
                allowInsufficientList[i]
            );
        }
    }

     
     
     
     
     
     
     
    function matchOrders(
        Common.Order memory leftOrder,
        Common.Order memory rightOrder,
        address spreadReceiver
    )
    public
    nonReentrant
    returns (Common.MatchedFillResults memory results)
    {
         
        require(
            leftOrder.makerToken == rightOrder.takerToken &&
            leftOrder.takerToken == rightOrder.makerToken &&
            mul(leftOrder.makerAmount, rightOrder.makerAmount) >= mul(leftOrder.takerAmount, rightOrder.takerAmount),
            "UNMATCHED_ORDERS"
        );
        Common.OrderInfo memory leftOrderInfo = getOrderInfo(leftOrder);
        Common.OrderInfo memory rightOrderInfo = getOrderInfo(rightOrder);
        results = calculateMatchedFillResults(
            leftOrder,
            rightOrder,
            leftOrderInfo.filledTakerAmount,
            rightOrderInfo.filledTakerAmount
        );
        assertFillableOrder(
            leftOrder,
            leftOrderInfo,
            msg.sender,
            results.left.takerFilledAmount
        );
        assertFillableOrder(
            rightOrder,
            rightOrderInfo,
            msg.sender,
            results.right.takerFilledAmount
        );
        settleMatchedOrders(leftOrder, rightOrder, results, spreadReceiver);
        filled[leftOrderInfo.orderHash] = add(leftOrderInfo.filledTakerAmount, results.left.takerFilledAmount);
        filled[rightOrderInfo.orderHash] = add(rightOrderInfo.filledTakerAmount, results.right.takerFilledAmount);
        emitFillOrderEvent(leftOrderInfo.orderHash, leftOrder, results.left);
        emitFillOrderEvent(rightOrderInfo.orderHash, rightOrder, results.right);
        return results;
    }

     
     
     
     
     
    function marketTakerOrders(
        Common.Order[] memory orderList,
        uint256 totalTakerAmountToFill
    )
    public
    returns (Common.FillResults memory totalFillResults)
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            Common.FillResults memory singleFillResults = fillOrderNoThrow(
                orderList[i],
                sub(totalTakerAmountToFill, totalFillResults.takerFilledAmount),
                true
            );
            addFillResults(totalFillResults, singleFillResults);
            if (totalFillResults.takerFilledAmount >= totalTakerAmountToFill) {
                break;
            }
        }
        return totalFillResults;
    }

     
     
     
     
     
    function marketMakerOrders(
        Common.Order[] memory orderList,
        uint256 totalMakerAmountToFill
    )
    public
    returns (Common.FillResults memory totalFillResults)
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            Common.FillResults memory singleFillResults = fillOrderNoThrow(
                orderList[i],
                getPartialAmountFloor(
                    orderList[i].takerAmount, orderList[i].makerAmount,
                    sub(totalMakerAmountToFill, totalFillResults.makerFilledAmount)
                ),
                true
            );
            addFillResults(totalFillResults, singleFillResults);
            if (totalFillResults.makerFilledAmount >= totalMakerAmountToFill) {
                break;
            }
        }
        return totalFillResults;
    }

     
     
     
    function getOrderInfo(Common.Order memory order)
    public
    view
    returns (Common.OrderInfo memory orderInfo)
    {
        orderInfo.orderHash = getOrderHash(order);
        orderInfo.filledTakerAmount = filled[orderInfo.orderHash];
        if (
            !whitelists[uint8(WhitelistType.RESELLER)][order.reseller] ||
            !whitelists[uint8(WhitelistType.VERIFIER)][order.verifier] ||
            !whitelists[uint8(WhitelistType.BANK)][order.makerTokenBank] ||
            !whitelists[uint8(WhitelistType.BANK)][order.takerTokenBank]
        ) {
            orderInfo.orderStatus = uint8(OrderStatus.INVALID);
            return orderInfo;
        }

        if (!isValidSignature(orderInfo.orderHash, order.maker, order.signature)) {
            orderInfo.orderStatus = uint8(OrderStatus.INVALID_SIGNATURE);
            return orderInfo;
        }

        if (order.makerAmount == 0) {
            orderInfo.orderStatus = uint8(OrderStatus.INVALID_MAKER_AMOUNT);
            return orderInfo;
        }
        if (order.takerAmount == 0) {
            orderInfo.orderStatus = uint8(OrderStatus.INVALID_TAKER_AMOUNT);
            return orderInfo;
        }
        if (orderInfo.filledTakerAmount >= order.takerAmount) {
            orderInfo.orderStatus = uint8(OrderStatus.FULLY_FILLED);
            return orderInfo;
        }
         
        if (block.timestamp >= order.expires) {
            orderInfo.orderStatus = uint8(OrderStatus.EXPIRED);
            return orderInfo;
        }
        if (cancelled[orderInfo.orderHash]) {
            orderInfo.orderStatus = uint8(OrderStatus.CANCELLED);
            return orderInfo;
        }
        orderInfo.orderStatus = uint8(OrderStatus.FILLABLE);
        return orderInfo;
    }

     
     
     
    function getOrderHash(Common.Order memory order)
    public
    view
    returns (bytes32)
    {
        bytes memory part1 = abi.encodePacked(
            address(this),
            order.maker,
            order.taker,
            order.makerToken,
            order.takerToken,
            order.makerTokenBank,
            order.takerTokenBank,
            order.reseller,
            order.verifier
        );
        bytes memory part2 = abi.encodePacked(
            order.makerAmount,
            order.takerAmount,
            order.expires,
            order.nonce,
            order.minimumTakerAmount,
            order.makerData,
            order.takerData
        );
        return keccak256(abi.encodePacked(part1, part2));
    }

     
     
    function cancelOrderInternal(
        Common.Order memory order
    )
    internal
    {
        Common.OrderInfo memory orderInfo = getOrderInfo(order);
        require(orderInfo.orderStatus == uint8(OrderStatus.FILLABLE), "ORDER_UNFILLABLE");
        require(order.maker == msg.sender, "INVALID_MAKER");
        cancelled[orderInfo.orderHash] = true;
        emit CancelOrder(
            orderInfo.orderHash,
            order.maker,
            order.makerToken,
            order.takerToken,
            order.reseller,
            order.makerAmount,
            order.takerAmount,
            order.makerData,
            order.takerData
        );
    }

     
     
     
     
     
    function fillOrderInternal(
        Common.Order memory order,
        uint256 takerAmountToFill,
        bool allowInsufficient
    )
    internal
    returns (Common.FillResults memory results)
    {
        require(takerAmountToFill > 0, "INVALID_TAKER_AMOUNT");
        Common.OrderInfo memory orderInfo = getOrderInfo(order);
        uint256 remainingTakerAmount = sub(order.takerAmount, orderInfo.filledTakerAmount);
        if (allowInsufficient) {
            takerAmountToFill = min(takerAmountToFill, remainingTakerAmount);
        } else {
            require(takerAmountToFill <= remainingTakerAmount, "INSUFFICIENT_ORDER_REMAINING");
        }
        assertFillableOrder(
            order,
            orderInfo,
            msg.sender,
            takerAmountToFill
        );
        results = settleOrder(order, takerAmountToFill);
        filled[orderInfo.orderHash] = add(orderInfo.filledTakerAmount, results.takerFilledAmount);
        emitFillOrderEvent(orderInfo.orderHash, order, results);
        return results;
    }

     
     
     
     
    function emitFillOrderEvent(
        bytes32 orderHash,
        Common.Order memory order,
        Common.FillResults memory results
    )
    internal
    {
        emit FillOrder(
            orderHash,
            order.maker,
            msg.sender,
            order.makerToken,
            order.takerToken,
            order.reseller,
            results.makerFilledAmount,
            results.makerFeeExchange,
            results.makerFeeReseller,
            results.takerFilledAmount,
            results.takerFeeExchange,
            results.takerFeeReseller,
            order.makerData,
            order.takerData
        );
    }

     
     
     
     
     
    function assertFillableOrder(
        Common.Order memory order,
        Common.OrderInfo memory orderInfo,
        address taker,
        uint256 takerAmountToFill
    )
    view
    internal
    {
         
        require(orderInfo.orderStatus == uint8(OrderStatus.FILLABLE), "ORDER_UNFILLABLE");

         
        if (order.taker != address(0)) {
            require(order.taker == taker, "INVALID_TAKER");
        }

         
        if (order.minimumTakerAmount > 0) {
            require(takerAmountToFill >= order.minimumTakerAmount, "ORDER_MINIMUM_UNREACHED");
        }

         
        if (order.verifier != address(0)) {
            require(Verifier(order.verifier).verify(order, takerAmountToFill, msg.sender), "FAILED_VALIDATION");
        }
    }

     
     
     
     
     
    function isValidSignature(
        bytes32 hash,
        address signer,
        bytes memory signature
    )
    internal
    pure
    returns (bool)
    {
        uint8 v = uint8(signature[0]);
        bytes32 r = signature.readBytes32(1);
        bytes32 s = signature.readBytes32(33);
        return signer == ecrecover(
            keccak256(abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )),
            v,
            r,
            s
        );
    }

     
     
     
    function addFillResults(
        Common.FillResults memory totalFillResults,
        Common.FillResults memory singleFillResults
    )
    internal
    pure
    {
        totalFillResults.makerFilledAmount = add(totalFillResults.makerFilledAmount, singleFillResults.makerFilledAmount);
        totalFillResults.makerFeeExchange = add(totalFillResults.makerFeeExchange, singleFillResults.makerFeeExchange);
        totalFillResults.makerFeeReseller = add(totalFillResults.makerFeeReseller, singleFillResults.makerFeeReseller);
        totalFillResults.takerFilledAmount = add(totalFillResults.takerFilledAmount, singleFillResults.takerFilledAmount);
        totalFillResults.takerFeeExchange = add(totalFillResults.takerFeeExchange, singleFillResults.takerFeeExchange);
        totalFillResults.takerFeeReseller = add(totalFillResults.takerFeeReseller, singleFillResults.takerFeeReseller);
    }

     
     
     
     
    function settleOrder(
        Common.Order memory order,
        uint256 takerAmountToFill
    )
    internal
    returns (Common.FillResults memory results)
    {
        results.takerFilledAmount = takerAmountToFill;
        results.makerFilledAmount = safeGetPartialAmountFloor(order.makerAmount, order.takerAmount, results.takerFilledAmount);
         
        if (!whitelists[uint8(WhitelistType.FEE_EXEMPT_BANK)][order.makerTokenBank]) {
            if (fees[order.reseller][0] > 0) {
                results.makerFeeExchange = mul(results.makerFilledAmount, fees[order.reseller][0]) / (1 ether);
            }
            if (fees[order.reseller][1] > 0) {
                results.makerFeeReseller = mul(results.makerFilledAmount, fees[order.reseller][1]) / (1 ether);
            }
        }
         
        if (!whitelists[uint8(WhitelistType.FEE_EXEMPT_BANK)][order.takerTokenBank]) {
            if (fees[order.reseller][2] > 0) {
                results.takerFeeExchange = mul(results.takerFilledAmount, fees[order.reseller][2]) / (1 ether);
            }
            if (fees[order.reseller][3] > 0) {
                results.takerFeeReseller = mul(results.takerFilledAmount, fees[order.reseller][3]) / (1 ether);
            }
        }
        if (results.makerFeeExchange > 0) {
             
            IBank(order.makerTokenBank).transferFrom(
                order.makerToken,
                order.maker,
                feeAccount,
                results.makerFeeExchange,
                order.makerData,
                true,
                false
            );
        }
        if (results.makerFeeReseller > 0) {
             
            IBank(order.makerTokenBank).transferFrom(
                order.makerToken,
                order.maker,
                order.reseller,
                results.makerFeeReseller,
                order.makerData,
                true,
                false
            );
        }
        if (results.takerFeeExchange > 0) {
             
            IBank(order.takerTokenBank).transferFrom(
                order.takerToken,
                msg.sender,
                feeAccount,
                results.takerFeeExchange,
                order.takerData,
                true,
                false
            );
        }
        if (results.takerFeeReseller > 0) {
             
            IBank(order.takerTokenBank).transferFrom(
                order.takerToken,
                msg.sender,
                order.reseller,
                results.takerFeeReseller,
                order.takerData,
                true,
                false
            );
        }
         
        IBank(order.makerTokenBank).transferFrom(
            order.makerToken,
            order.maker,
            msg.sender,
            results.makerFilledAmount,
            order.makerData,
            true,
            true
        );
         
        IBank(order.takerTokenBank).transferFrom(
            order.takerToken,
            msg.sender,
            order.maker,
            results.takerFilledAmount,
            order.takerData,
            true,
            true
        );
    }

     
     
     
     
     
     
     
     
    function calculateMatchedFillResults(
        Common.Order memory leftOrder,
        Common.Order memory rightOrder,
        uint256 leftFilledTakerAmount,
        uint256 rightFilledTakerAmount
    )
    internal
    view
    returns (Common.MatchedFillResults memory results)
    {
        uint256 leftRemainingTakerAmount = sub(leftOrder.takerAmount, leftFilledTakerAmount);
        uint256 leftRemainingMakerAmount = safeGetPartialAmountFloor(
            leftOrder.makerAmount,
            leftOrder.takerAmount,
            leftRemainingTakerAmount
        );
        uint256 rightRemainingTakerAmount = sub(rightOrder.takerAmount, rightFilledTakerAmount);
        uint256 rightRemainingMakerAmount = safeGetPartialAmountFloor(
            rightOrder.makerAmount,
            rightOrder.takerAmount,
            rightRemainingTakerAmount
        );

        if (leftRemainingTakerAmount >= rightRemainingMakerAmount) {
             
            results.right.makerFilledAmount = rightRemainingMakerAmount;
            results.right.takerFilledAmount = rightRemainingTakerAmount;
            results.left.takerFilledAmount = results.right.makerFilledAmount;
             
             
            results.left.makerFilledAmount = safeGetPartialAmountFloor(
                leftOrder.makerAmount,
                leftOrder.takerAmount,
                results.left.takerFilledAmount
            );
        } else {
             
            results.left.makerFilledAmount = leftRemainingMakerAmount;
            results.left.takerFilledAmount = leftRemainingTakerAmount;
            results.right.makerFilledAmount = results.left.takerFilledAmount;
             
             
            results.right.takerFilledAmount = safeGetPartialAmountCeil(
                rightOrder.takerAmount,
                rightOrder.makerAmount,
                results.right.makerFilledAmount
            );
        }
        results.spreadAmount = sub(
            results.left.makerFilledAmount,
            results.right.takerFilledAmount
        );
        if (!whitelists[uint8(WhitelistType.FEE_EXEMPT_BANK)][leftOrder.makerTokenBank]) {
            if (fees[leftOrder.reseller][0] > 0) {
                results.left.makerFeeExchange = mul(results.left.makerFilledAmount, fees[leftOrder.reseller][0]) / (1 ether);
            }
            if (fees[leftOrder.reseller][1] > 0) {
                results.left.makerFeeReseller = mul(results.left.makerFilledAmount, fees[leftOrder.reseller][1]) / (1 ether);
            }
        }
        if (!whitelists[uint8(WhitelistType.FEE_EXEMPT_BANK)][rightOrder.makerTokenBank]) {
            if (fees[rightOrder.reseller][2] > 0) {
                results.right.makerFeeExchange = mul(results.right.makerFilledAmount, fees[rightOrder.reseller][2]) / (1 ether);
            }
            if (fees[rightOrder.reseller][3] > 0) {
                results.right.makerFeeReseller = mul(results.right.makerFilledAmount, fees[rightOrder.reseller][3]) / (1 ether);
            }
        }
        return results;
    }

     
     
     
     
     
    function settleMatchedOrders(
        Common.Order memory leftOrder,
        Common.Order memory rightOrder,
        Common.MatchedFillResults memory results,
        address spreadReceiver
    )
    internal
    {
        if (results.left.makerFeeExchange > 0) {
             
            IBank(leftOrder.makerTokenBank).transferFrom(
                leftOrder.makerToken,
                leftOrder.maker,
                feeAccount,
                results.left.makerFeeExchange,
                leftOrder.makerData,
                true,
                false
            );
        }
        if (results.left.makerFeeReseller > 0) {
             
            IBank(leftOrder.makerTokenBank).transferFrom(
                leftOrder.makerToken,
                leftOrder.maker,
                leftOrder.reseller,
                results.left.makerFeeReseller,
                leftOrder.makerData,
                true,
                false
            );
        }
        if (results.right.makerFeeExchange > 0) {
             
            IBank(rightOrder.makerTokenBank).transferFrom(
                rightOrder.makerToken,
                rightOrder.maker,
                feeAccount,
                results.right.makerFeeExchange,
                rightOrder.makerData,
                true,
                false
            );
        }
        if (results.right.makerFeeReseller > 0) {
             
            IBank(rightOrder.makerTokenBank).transferFrom(
                rightOrder.makerToken,
                rightOrder.maker,
                rightOrder.reseller,
                results.right.makerFeeReseller,
                rightOrder.makerData,
                true,
                false
            );
        }
         

         
        IBank(leftOrder.makerTokenBank).transferFrom(
            leftOrder.makerToken,
            leftOrder.maker,
            rightOrder.maker,
            results.right.takerFilledAmount,
            leftOrder.makerData,
            true,
            true
        );
         
        IBank(rightOrder.makerTokenBank).transferFrom(
            rightOrder.makerToken,
            rightOrder.maker,
            leftOrder.maker,
            results.left.takerFilledAmount,
            rightOrder.makerData,
            true,
            true
        );
        if (results.spreadAmount > 0) {
             
            IBank(leftOrder.makerTokenBank).transferFrom(
                leftOrder.makerToken,
                leftOrder.maker,
                spreadReceiver,
                results.spreadAmount,
                leftOrder.makerData,
                true,
                false
            );
        }
    }
}