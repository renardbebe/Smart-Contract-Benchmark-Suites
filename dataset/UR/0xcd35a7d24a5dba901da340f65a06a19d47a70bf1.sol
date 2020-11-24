 

 

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

 
interface IExchangeHandler {

     
     
     
     
    function getAvailableToFill(
        bytes calldata data
    )
    external
    view
    returns (uint256 availableToFill, uint256 feePercentage);

     
     
     
     
     
    function fillOrder(
        bytes calldata data,
        uint256 takerAmountToFill
    )
    external
    payable
    returns (uint256 makerAmountReceived);
}

 

pragma solidity ^0.5.7;

contract RouterCommon {
    struct GeneralOrder {
        address handler;
        address makerToken;
        address takerToken;
        uint256 makerAmount;
        uint256 takerAmount;
        bytes data;
    }

    struct FillResults {
        uint256 makerAmountReceived;
        uint256 takerAmountSpentOnOrder;
        uint256 takerAmountSpentOnFee;
    }
}

 

pragma solidity ^0.5.7;
pragma experimental ABIEncoderV2;







 
interface IERC20 {
    function approve(address spender, uint256 value) external returns (bool);
}

 
contract ExchangeRouter is Ownable, ReentrancyGuard, LibMath {

    IBank public bank;
    mapping(address => bool) public handlerWhitelist;

    event Handler(address handler, bool allowed);
    event FillOrder(
        bytes orderData,
        uint256 makerAmountReceived,
        uint256 takerAmountSpentOnOrder,
        uint256 takerAmountSpentOnFee
    );

    constructor(
        address _bank
    )
    public
    {
        bank = IBank(_bank);
    }

     
    function() external payable {}

     
     
     
    function setHandler(
        address handler,
        bool allowed
    )
    external
    onlyOwner
    {
        handlerWhitelist[handler] = allowed;
        emit Handler(handler, allowed);
    }

     
     
     
     
     
    function fillOrder(
        RouterCommon.GeneralOrder memory order,
        uint256 takerAmountToFill,
        bool allowInsufficient
    )
    public
    nonReentrant
    returns (RouterCommon.FillResults memory results)
    {
        results = fillOrderInternal(
            order,
                takerAmountToFill,
            allowInsufficient
        );
    }

     
     
     
     
    function fillOrders(
        RouterCommon.GeneralOrder[] memory orderList,
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

     
     
     
     
     
    function marketTakerOrders(
        RouterCommon.GeneralOrder[] memory orderList,
        uint256 totalTakerAmountToFill
    )
    public
    returns (RouterCommon.FillResults memory totalFillResults)
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            RouterCommon.FillResults memory singleFillResults = fillOrderInternal(
                orderList[i],
                sub(totalTakerAmountToFill, totalFillResults.takerAmountSpentOnOrder),
                true
            );
            addFillResults(totalFillResults, singleFillResults);
            if (totalFillResults.takerAmountSpentOnOrder >= totalTakerAmountToFill) {
                break;
            }
        }
        return totalFillResults;
    }

     
     
     
     
     
    function marketMakerOrders(
        RouterCommon.GeneralOrder[] memory orderList,
        uint256 totalMakerAmountToFill
    )
    public
    returns (RouterCommon.FillResults memory totalFillResults)
    {
        for (uint256 i = 0; i < orderList.length; i++) {
            RouterCommon.FillResults memory singleFillResults = fillOrderInternal(
                orderList[i],
                getPartialAmountFloor(
                    orderList[i].takerAmount,
                    orderList[i].makerAmount,
                    sub(totalMakerAmountToFill, totalFillResults.makerAmountReceived)
                ),
                true
            );
            addFillResults(totalFillResults, singleFillResults);
            if (totalFillResults.makerAmountReceived >= totalMakerAmountToFill) {
                break;
            }
        }
        return totalFillResults;
    }

     
     
     
     
     
    function fillOrderInternal(
        RouterCommon.GeneralOrder memory order,
        uint256 takerAmountToFill,
        bool allowInsufficient
    )
    internal
    returns (RouterCommon.FillResults memory results)
    {
         
        require(handlerWhitelist[order.handler], "HANDLER_IN_WHITELIST_REQUIRED");
         
        (uint256 availableToFill, uint256 feePercentage) = IExchangeHandler(order.handler).getAvailableToFill(order.data);

        if (allowInsufficient) {
            results.takerAmountSpentOnOrder = min(takerAmountToFill, availableToFill);
        } else {
            require(takerAmountToFill <= availableToFill, "INSUFFICIENT_ORDER_REMAINING");
            results.takerAmountSpentOnOrder = takerAmountToFill;
        }
        results.takerAmountSpentOnFee = mul(results.takerAmountSpentOnOrder, feePercentage) / (1 ether);
        if (results.takerAmountSpentOnOrder > 0) {
             
            bank.transferFrom(
                order.takerToken,
                msg.sender,
                order.handler,
                add(results.takerAmountSpentOnOrder, results.takerAmountSpentOnFee),
                "",
                true,
                false
            );
             
            results.makerAmountReceived = IExchangeHandler(order.handler).fillOrder(
                order.data,
                results.takerAmountSpentOnOrder
            );
            if (results.makerAmountReceived > 0) {
                if (order.makerToken == address(0)) {
                    bank.deposit.value(results.makerAmountReceived)(
                        address(0),
                        msg.sender,
                        results.makerAmountReceived,
                        ""
                    );
                } else {
                    require(IERC20(order.makerToken).approve(address(bank), results.makerAmountReceived));
                    bank.deposit(
                        order.makerToken,
                        msg.sender,
                        results.makerAmountReceived,
                        ""
                    );
                }
            }
            emit FillOrder(
                order.data,
                results.makerAmountReceived,
                results.takerAmountSpentOnOrder,
                results.takerAmountSpentOnFee
            );
        }
    }

     
     
     
    function addFillResults(
        RouterCommon.FillResults memory totalFillResults,
        RouterCommon.FillResults memory singleFillResults
    )
    internal
    pure
    {
        totalFillResults.makerAmountReceived = add(totalFillResults.makerAmountReceived, singleFillResults.makerAmountReceived);
        totalFillResults.takerAmountSpentOnOrder = add(totalFillResults.takerAmountSpentOnOrder, singleFillResults.takerAmountSpentOnOrder);
        totalFillResults.takerAmountSpentOnFee = add(totalFillResults.takerAmountSpentOnFee, singleFillResults.takerAmountSpentOnFee);
    }
}