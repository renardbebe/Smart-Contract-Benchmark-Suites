 

pragma solidity ^0.5.2;
pragma experimental ABIEncoderV2;


contract EIP712 {
    string internal constant DOMAIN_NAME = "Mai Protocol";

    
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked("EIP712Domain(string name)")
    );

    bytes32 public DOMAIN_SEPARATOR;

    constructor () public {
        DOMAIN_SEPARATOR = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME))
            )
        );
    }

    
    function hashEIP712Message(bytes32 eip712hash) internal view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, eip712hash));
    }
}

contract LibSignature {

    enum SignatureMethod {
        EthSign,
        EIP712
    }

    
    struct OrderSignature {
        
        bytes32 config;
        bytes32 r;
        bytes32 s;
    }

    
    function isValidSignature(bytes32 hash, address signerAddress, OrderSignature memory signature)
        internal
        pure
        returns (bool)
    {
        uint8 method = uint8(signature.config[1]);
        address recovered;
        uint8 v = uint8(signature.config[0]);

        if (method == uint8(SignatureMethod.EthSign)) {
            recovered = ecrecover(
                keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),
                v,
                signature.r,
                signature.s
            );
        } else if (method == uint8(SignatureMethod.EIP712)) {
            recovered = ecrecover(hash, v, signature.r, signature.s);
        } else {
            revert("INVALID_SIGN_METHOD");
        }

        return signerAddress == recovered;
    }
}

library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        
        
        
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        

        return c;
    }

    
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract LibMath {
    using SafeMath for uint256;

    
    function isRoundingError(uint256 numerator, uint256 denominator, uint256 multiple)
        internal
        pure
        returns (bool)
    {
        return numerator.mul(multiple).mod(denominator).mul(1000) >= numerator.mul(multiple);
    }

    
    
    
    function getPartialAmountFloor(uint256 numerator, uint256 denominator, uint256 multiple)
        internal
        pure
        returns (uint256)
    {
        require(!isRoundingError(numerator, denominator, multiple), "ROUNDING_ERROR");
        return numerator.mul(multiple).div(denominator);
    }

    
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract LibOrder is EIP712, LibSignature, LibMath {

    uint256 public constant REBATE_RATE_BASE = 100;

    struct Order {
        address trader;
        address relayer;
        address marketContractAddress;
        uint256 amount;
        uint256 price;
        uint256 gasTokenAmount;

        
        bytes32 data;
    }

    enum OrderStatus {
        EXPIRED,
        CANCELLED,
        FILLABLE,
        FULLY_FILLED
    }

    enum FillAction {
        INVALID,
        BUY,
        SELL,
        MINT,
        REDEEM
    }

    bytes32 public constant EIP712_ORDER_TYPE = keccak256(
        abi.encodePacked(
            "Order(address trader,address relayer,address marketContractAddress,uint256 amount,uint256 price,uint256 gasTokenAmount,bytes32 data)"
        )
    );

    
    function getOrderHash(Order memory order) internal view returns (bytes32 orderHash) {
        orderHash = hashEIP712Message(hashOrder(order));
        return orderHash;
    }

    
    function hashOrder(Order memory order) internal pure returns (bytes32 result) {
        
        bytes32 orderType = EIP712_ORDER_TYPE;

        assembly {
            let start := sub(order, 32)
            let tmp := mload(start)

            
            
            
            
            mstore(start, orderType)
            result := keccak256(start, 256)

            mstore(start, tmp)
        }

        return result;
    }

    

    function getOrderVersion(bytes32 data) internal pure returns (uint256) {
        return uint256(uint8(byte(data)));
    }

    function getExpiredAtFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(uint40(bytes5(data << (8*3))));
    }

    function isSell(bytes32 data) internal pure returns (bool) {
        return uint8(data[1]) == 1;
    }

    function isMarketOrder(bytes32 data) internal pure returns (bool) {
        return uint8(data[2]) == 1;
    }

    function isMakerOnly(bytes32 data) internal pure returns (bool) {
        return uint8(data[22]) == 1;
    }

    function isMarketBuy(bytes32 data) internal pure returns (bool) {
        return !isSell(data) && isMarketOrder(data);
    }

    function getAsMakerFeeRateFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(uint16(bytes2(data << (8*8))));
    }

    function getAsTakerFeeRateFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(uint16(bytes2(data << (8*10))));
    }

    function getMakerRebateRateFromOrderData(bytes32 data) internal pure returns (uint256) {
        uint256 makerRebate = uint256(uint16(bytes2(data << (8*12))));

        
        return min(makerRebate, REBATE_RATE_BASE);
    }
}

contract LibOwnable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    
    function owner() public view returns(address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(isOwner(), "NOT_OWNER");
        _;
    }

    
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

    
    
    
    
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    
    
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "INVALID_OWNER");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract LibRelayer {

    
    mapping (address => mapping (address => bool)) public relayerDelegates;

    
    mapping (address => bool) hasExited;

    event RelayerApproveDelegate(address indexed relayer, address indexed delegate);
    event RelayerRevokeDelegate(address indexed relayer, address indexed delegate);

    event RelayerExit(address indexed relayer);
    event RelayerJoin(address indexed relayer);

    
    function approveDelegate(address delegate) external {
        relayerDelegates[msg.sender][delegate] = true;
        emit RelayerApproveDelegate(msg.sender, delegate);
    }

    
    function revokeDelegate(address delegate) external {
        relayerDelegates[msg.sender][delegate] = false;
        emit RelayerRevokeDelegate(msg.sender, delegate);
    }

    
    function canMatchMarketContractOrdersFrom(address relayer) public view returns(bool) {
        return msg.sender == relayer || relayerDelegates[relayer][msg.sender] == true;
    }

    
    function joinIncentiveSystem() external {
        delete hasExited[msg.sender];
        emit RelayerJoin(msg.sender);
    }

    
    function exitIncentiveSystem() external {
        hasExited[msg.sender] = true;
        emit RelayerExit(msg.sender);
    }

    
    function isParticipant(address relayer) public view returns(bool) {
        return !hasExited[relayer];
    }
}

contract LibExchangeErrors {
    string constant INVALID_TRADER = "INVALID_TRADER";
    string constant INVALID_SENDER = "INVALID_SENDER";
    
    string constant INVALID_MATCH = "INVALID_MATCH";
    string constant REDEEM_PRICE_NOT_MET = "REDEEM_PRICE_NOT_MET";
    string constant MINT_PRICE_NOT_MET = "MINT_PRICE_NOT_MET";
    string constant INVALID_SIDE = "INVALID_SIDE";
    
    string constant INVALID_ORDER_SIGNATURE = "INVALID_ORDER_SIGNATURE";
    
    string constant ORDER_IS_NOT_FILLABLE = "ORDER_IS_NOT_FILLABLE";
    string constant MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER = "MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER";
    string constant TRANSFER_FROM_FAILED = "TRANSFER_FROM_FAILED";
    string constant MAKER_ORDER_OVER_MATCH = "MAKER_ORDER_OVER_MATCH";
    string constant TAKER_ORDER_OVER_MATCH = "TAKER_ORDER_OVER_MATCH";
    string constant ORDER_VERSION_NOT_SUPPORTED = "ORDER_VERSION_NOT_SUPPORTED";
    string constant MAKER_ONLY_ORDER_CANNOT_BE_TAKER = "MAKER_ONLY_ORDER_CANNOT_BE_TAKER";
    string constant TRANSFER_FAILED = "TRANSFER_FAILED";
    string constant MINT_POSITION_TOKENS_FAILED = "MINT_FAILED";
    string constant REDEEM_POSITION_TOKENS_FAILED = "REDEEM_FAILED";
    string constant UNEXPECTED_MATCH = "UNEXPECTED_MATCH";
    string constant INSUFFICIENT_FEE = "INSUFFICIENT_FEE";
    string constant INVALID_MARKET_CONTRACT = "INVALID_MARKET_CONTRACT";
    string constant UNMATCHED_FILL = "UNMATCHED_FILL";
    string constant LOW_MARGIN = "LOW_MARGIN";
    string constant INVALID_AMOUNT = "LOW_MARGIN";
    string constant MAKER_CAN_NOT_BE_SAME_WITH_TAKER = "MAKER_CANNOT_BE_TAKER";
}

interface IMarketContract {
    
    function CONTRACT_NAME()
        external
        view
        returns (string memory);
    function COLLATERAL_TOKEN_ADDRESS()
        external
        view
        returns (address);
    function COLLATERAL_POOL_ADDRESS()
        external
        view
        returns (address);
    function PRICE_CAP()
        external
        view
        returns (uint);
    function PRICE_FLOOR()
        external
        view
        returns (uint);
    function PRICE_DECIMAL_PLACES()
        external
        view
        returns (uint);
    function QTY_MULTIPLIER()
        external
        view
        returns (uint);
    function COLLATERAL_PER_UNIT()
        external
        view
        returns (uint);
    function COLLATERAL_TOKEN_FEE_PER_UNIT()
        external
        view
        returns (uint);
    function MKT_TOKEN_FEE_PER_UNIT()
        external
        view
        returns (uint);
    function EXPIRATION()
        external
        view
        returns (uint);
    function SETTLEMENT_DELAY()
        external
        view
        returns (uint);
    function LONG_POSITION_TOKEN()
        external
        view
        returns (address);
    function SHORT_POSITION_TOKEN()
        external
        view
        returns (address);

    
    function lastPrice()
        external
        view
        returns (uint);
    function settlementPrice()
        external
        view
        returns (uint);
    function settlementTimeStamp()
        external
        view
        returns (uint);
    function isSettled()
        external
        view
        returns (bool);

    
    function isPostSettlementDelay()
        external
        view
        returns (bool);
}

contract IMarketContractPool {
    function mintPositionTokens(
        address marketContractAddress,
        uint qtyToMint,
        bool isAttemptToPayInMKT
    ) external;
    function redeemPositionTokens(
        address marketContractAddress,
        uint qtyToRedeem
    ) external;
    function mktToken() external view returns (address);
}

contract IMarketContractRegistry {
    function addAddressToWhiteList(address contractAddress) external;
    function isAddressWhiteListed(address contractAddress) external view returns (bool);
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    
    function balanceOf(address account) external view returns (uint256);

    
    function transfer(address recipient, uint256 amount) external returns (bool);

    
    function allowance(address owner, address spender) external view returns (uint256);

    
    function approve(address spender, uint256 amount) external returns (bool);

    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        
        
        
        
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    
    function callOptionalReturn(IERC20 token, bytes memory data) private {
        
        

        
        
        
        
        
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { 
            
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract MaiProtocol is LibMath, LibOrder, LibRelayer, LibExchangeErrors, LibOwnable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    uint256 public constant MAX_MATCHES = 3;
    uint256 public constant LONG = 0;
    uint256 public constant SHORT = 1;
    uint256 public constant FEE_RATE_BASE = 100000;

    
    uint256 public constant SUPPORTED_ORDER_VERSION = 1;

    
    address public marketRegistryAddress;

    
    address public mintingPoolAddress;

    
    mapping (bytes32 => uint256) public filled;

    
    mapping (bytes32 => bool) public cancelled;

    
    struct OrderParam {
        address trader;
        uint256 amount;
        uint256 price;
        uint256 gasTokenAmount;
        bytes32 data;
        OrderSignature signature;
    }

    
    struct OrderInfo {
        bytes32 orderHash;
        uint256 filledAmount;
        uint256[2] margins;     
        uint256[2] balances;    
    }

    struct OrderAddressSet {
        address marketContractAddress;
        address relayer;
    }

    struct OrderContext {
        IMarketContract marketContract;         
        IMarketContractPool marketContractPool; 
        IERC20 collateral;                      
        IERC20[2] positions;                    
        uint256 takerSide;                      
    }

    struct MatchResult {
        address maker;
        address taker;
        uint256 makerFee;                   
        uint256 takerFee;                   
        uint256 makerGasFee;
        uint256 takerGasFee;
        uint256 posFilledAmount;            
        uint256 ctkFilledAmount;            
        FillAction fillAction;
    }


    event Match(
        OrderAddressSet addressSet,
        MatchResult result
    );
    event Cancel(bytes32 indexed orderHash);
    event Withdraw(address indexed tokenAddress, address indexed to, uint256 amount);
    event Approval(address indexed tokenAddress, address indexed spender, uint256 amount);

    
    function setMarketRegistryAddress(address _marketRegistryAddress)
        external
        onlyOwner
    {
        marketRegistryAddress = _marketRegistryAddress;
    }


    function setMintingPool(address _mintingPoolAddress)
        external
        onlyOwner
    {
        mintingPoolAddress = _mintingPoolAddress;
    }

    function approveERC20(address token, address spender, uint256 amount)
        external
        onlyOwner
    {
        IERC20(token).safeApprove(spender, amount);
        emit Approval(token, spender, amount);
    }

    function withdrawERC20(address token, uint256 amount)
        external
        onlyOwner
    {
        require(amount > 0, INVALID_AMOUNT);
        IERC20(token).safeTransfer(msg.sender, amount);

        emit Withdraw(token, msg.sender, amount);
    }


    
    function matchMarketContractOrders(
        OrderParam memory takerOrderParam,
        OrderParam[] memory makerOrderParams,
        uint256[] memory posFilledAmounts,
        OrderAddressSet memory orderAddressSet
    )
        public
    {
        require(canMatchMarketContractOrdersFrom(orderAddressSet.relayer), INVALID_SENDER);
        require(!isMakerOnly(takerOrderParam.data), MAKER_ONLY_ORDER_CANNOT_BE_TAKER);

        validateMarketContract(orderAddressSet.marketContractAddress);
        OrderContext memory orderContext = getOrderContext(orderAddressSet, takerOrderParam);
        matchAndSettle(
            takerOrderParam,
            makerOrderParams,
            posFilledAmounts,
            orderAddressSet,
            orderContext
        );
    }

    
    function getOrderContext(
        OrderAddressSet memory orderAddressSet,
        OrderParam memory takerOrderParam
    )
        internal
        view
        returns (OrderContext memory orderContext)
    {
        orderContext.marketContract = IMarketContract(orderAddressSet.marketContractAddress);
        orderContext.marketContractPool = IMarketContractPool(
            orderContext.marketContract.COLLATERAL_POOL_ADDRESS()
        );
        orderContext.collateral = IERC20(orderContext.marketContract.COLLATERAL_TOKEN_ADDRESS());
        orderContext.positions[LONG] = IERC20(orderContext.marketContract.LONG_POSITION_TOKEN());
        orderContext.positions[SHORT] = IERC20(orderContext.marketContract.SHORT_POSITION_TOKEN());
        orderContext.takerSide = isSell(takerOrderParam.data) ? SHORT : LONG;

        return orderContext;
    }

    
    function matchAndSettle(
        OrderParam memory takerOrderParam,
        OrderParam[] memory makerOrderParams,
        uint256[] memory posFilledAmounts,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        OrderInfo memory takerOrderInfo = getOrderInfo(
            takerOrderParam,
            orderAddressSet,
            orderContext
        );
        for (uint256 i = 0; i < makerOrderParams.length; i++) {
            require(!isMarketOrder(makerOrderParams[i].data), MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER);
            require(isSell(takerOrderParam.data) != isSell(makerOrderParams[i].data), INVALID_SIDE);
            require(
                takerOrderParam.trader != makerOrderParams[i].trader,
                MAKER_CAN_NOT_BE_SAME_WITH_TAKER
            );
            OrderInfo memory makerOrderInfo = getOrderInfo(
                makerOrderParams[i],
                orderAddressSet,
                orderContext
            );
            validatePrice(
                takerOrderParam,
                makerOrderParams[i]
            );
            uint256 toFillAmount = posFilledAmounts[i];
            for (uint256 j = 0; j < MAX_MATCHES && toFillAmount > 0; j++) {
                MatchResult memory result;
                uint256 filledAmount;
                (result, filledAmount) = getMatchResult(
                    takerOrderParam,
                    takerOrderInfo,
                    makerOrderParams[i],
                    makerOrderInfo,
                    orderContext,
                    toFillAmount
                );
                toFillAmount = toFillAmount.sub(filledAmount);
                settleResult(result, orderAddressSet, orderContext);
            }
            
            
            require(toFillAmount == 0, UNMATCHED_FILL);
            filled[makerOrderInfo.orderHash] = makerOrderInfo.filledAmount;
        }
        filled[takerOrderInfo.orderHash] = takerOrderInfo.filledAmount;
    }

    
    function validateMarketContract(address marketContractAddress) internal view {
        if (marketRegistryAddress == address(0x0)) {
            return;
        }
        IMarketContractRegistry registry = IMarketContractRegistry(marketRegistryAddress);
        require(
            registry.isAddressWhiteListed(marketContractAddress),
            INVALID_MARKET_CONTRACT
        );
    }

    
    function calculateMiddleCollateralPerUnit(OrderContext memory orderContext)
        internal
        view
        returns (uint256)
    {
        return orderContext.marketContract.PRICE_CAP()
            .add(orderContext.marketContract.PRICE_FLOOR())
            .mul(orderContext.marketContract.QTY_MULTIPLIER())
            .div(2);
    }

    
    function calculateLongMargin(OrderContext memory orderContext, OrderParam memory orderParam)
        internal
        view
        returns (uint256)
    {
        return orderParam.price
            .sub(orderContext.marketContract.PRICE_FLOOR())
            .mul(orderContext.marketContract.QTY_MULTIPLIER());
    }

    
    function calculateShortMargin(OrderContext memory orderContext, OrderParam memory orderParam)
        internal
        view
        returns (uint256)
    {
        return orderContext.marketContract.PRICE_CAP()
            .sub(orderParam.price)
            .mul(orderContext.marketContract.QTY_MULTIPLIER());
    }

    
    function validatePrice(
        OrderParam memory takerOrderParam,
        OrderParam memory makerOrderParam
    )
        internal
        pure
    {
        if (isMarketOrder(takerOrderParam.data)) {
            return;
        }
        if (isSell(takerOrderParam.data)) {
            require(takerOrderParam.price <= makerOrderParam.price, INVALID_MATCH);
        } else {
            require(takerOrderParam.price >= makerOrderParam.price, INVALID_MATCH);
        }
    }

    
    function getMatchResult(
        OrderParam memory takerOrderParam,
        OrderInfo memory takerOrderInfo,
        OrderParam memory makerOrderParam,
        OrderInfo memory makerOrderInfo,
        OrderContext memory orderContext,
        uint256 posFilledAmount
    )
        internal
        view
        returns (MatchResult memory result, uint256 filledAmount)
    {
        require(makerOrderInfo.filledAmount <= makerOrderParam.amount, MAKER_ORDER_OVER_MATCH);
        require(takerOrderInfo.filledAmount <= takerOrderParam.amount, TAKER_ORDER_OVER_MATCH);

        
        if (takerOrderInfo.filledAmount == 0) {
            result.takerGasFee = takerOrderParam.gasTokenAmount;
        }
        if (makerOrderInfo.filledAmount == 0) {
            result.makerGasFee = makerOrderParam.gasTokenAmount;
        }

        
        filledAmount = fillMatchResult(
            result,
            takerOrderParam,
            takerOrderInfo,
            makerOrderParam,
            makerOrderInfo,
            orderContext,
            posFilledAmount
        );
        result.posFilledAmount = filledAmount;

        
        result.makerFee = filledAmount.mul(getMakerFeeBase(orderContext, makerOrderParam));
        result.takerFee = filledAmount.mul(getTakerFeeBase(orderContext, takerOrderParam));
        result.taker = takerOrderParam.trader;
        result.maker = makerOrderParam.trader;

        return (result, filledAmount);
    }

    
    function getMakerFeeBase(
        OrderContext memory orderContext,
        OrderParam memory orderParam
    )
        internal
        view
        returns (uint256)
    {
        uint256 middleCollateralPerUnit = calculateMiddleCollateralPerUnit(orderContext);
        return middleCollateralPerUnit
            .mul(getAsMakerFeeRateFromOrderData(orderParam.data))
            .div(FEE_RATE_BASE);
    }

    
    function getTakerFeeBase(
        OrderContext memory orderContext,
        OrderParam memory orderParam
    )
        internal
        view
        returns (uint256)
    {
        uint256 middleCollateralPerUnit = calculateMiddleCollateralPerUnit(orderContext);
        return middleCollateralPerUnit
            .mul(getAsTakerFeeRateFromOrderData(orderParam.data))
            .div(FEE_RATE_BASE);
    }

    
    function fillMatchResult(
        MatchResult memory result,
        OrderParam memory takerOrderParam,
        OrderInfo memory takerOrderInfo,
        OrderParam memory makerOrderParam,
        OrderInfo memory makerOrderInfo,
        OrderContext memory orderContext,
        uint256 posFilledAmount
    )
        internal
        pure
        returns (uint256 filledAmount)
    {
        uint256 side = orderContext.takerSide;
        uint256 opposite = oppositeSide(side);

        if (takerOrderInfo.balances[opposite] > 0 && makerOrderInfo.balances[side] > 0) {
            
            filledAmount = min(
                min(takerOrderInfo.balances[opposite], posFilledAmount),
                makerOrderInfo.balances[side]
            );
            
            takerOrderInfo.balances[opposite] = takerOrderInfo.balances[opposite]
                .sub(filledAmount);
            makerOrderInfo.balances[side] = makerOrderInfo.balances[side].sub(filledAmount);

            result.fillAction = FillAction.REDEEM;
            result.ctkFilledAmount = makerOrderInfo.margins[side].mul(filledAmount);

       } else if (takerOrderInfo.balances[opposite] > 0 && makerOrderInfo.balances[side] == 0) {
            
            filledAmount = min(takerOrderInfo.balances[opposite], posFilledAmount);
            takerOrderInfo.balances[opposite] = takerOrderInfo.balances[opposite]
                .sub(filledAmount);
            makerOrderInfo.balances[opposite] = makerOrderInfo.balances[opposite]
                .add(filledAmount);

            result.fillAction = FillAction.SELL;
            result.ctkFilledAmount = makerOrderInfo.margins[opposite].mul(filledAmount);

       } else if (takerOrderInfo.balances[opposite] == 0 && makerOrderInfo.balances[side] > 0) {
            
            filledAmount = min(makerOrderInfo.balances[side], posFilledAmount);
            takerOrderInfo.balances[side] = takerOrderInfo.balances[side].add(filledAmount);
            makerOrderInfo.balances[side] = makerOrderInfo.balances[side].sub(filledAmount);

            result.fillAction = FillAction.BUY;
            result.ctkFilledAmount = makerOrderInfo.margins[side].mul(filledAmount);

       } else if (takerOrderInfo.balances[opposite] == 0 && makerOrderInfo.balances[side] == 0) {
            
            filledAmount = posFilledAmount;
            
            takerOrderInfo.balances[side] = takerOrderInfo.balances[side].add(filledAmount);
            makerOrderInfo.balances[opposite] = makerOrderInfo.balances[opposite].add(filledAmount);

            result.fillAction = FillAction.MINT;
            result.ctkFilledAmount = makerOrderInfo.margins[opposite].mul(filledAmount);

        } else {
           revert(UNEXPECTED_MATCH);
        }

        
        takerOrderInfo.filledAmount = takerOrderInfo.filledAmount.add(filledAmount);
        makerOrderInfo.filledAmount = makerOrderInfo.filledAmount.add(filledAmount);

        require(takerOrderInfo.filledAmount <= takerOrderParam.amount, TAKER_ORDER_OVER_MATCH);
        require(makerOrderInfo.filledAmount <= makerOrderParam.amount, MAKER_ORDER_OVER_MATCH);

        result.posFilledAmount = filledAmount;

        return filledAmount;
    }

    
    function cancelOrder(Order memory order) public {
        require(msg.sender == order.trader || msg.sender == order.relayer, INVALID_TRADER);

        bytes32 orderHash = getOrderHash(order);
        cancelled[orderHash] = true;

        emit Cancel(orderHash);
    }

    
    function getOrderInfo(
        OrderParam memory orderParam,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
        view
        returns (OrderInfo memory orderInfo)
    {
        require(
            getOrderVersion(orderParam.data) == SUPPORTED_ORDER_VERSION,
            ORDER_VERSION_NOT_SUPPORTED
        );

        Order memory order = getOrderFromOrderParam(orderParam, orderAddressSet);
        orderInfo.orderHash = getOrderHash(order);
        orderInfo.filledAmount = filled[orderInfo.orderHash];
        uint8 status = uint8(OrderStatus.FILLABLE);

        if (orderInfo.filledAmount >= order.amount) {
            status = uint8(OrderStatus.FULLY_FILLED);
        } else if (block.timestamp >= getExpiredAtFromOrderData(order.data)) {
            status = uint8(OrderStatus.EXPIRED);
        } else if (cancelled[orderInfo.orderHash]) {
            status = uint8(OrderStatus.CANCELLED);
        }

        require(status == uint8(OrderStatus.FILLABLE), ORDER_IS_NOT_FILLABLE);
        require(
            isValidSignature(orderInfo.orderHash, orderParam.trader, orderParam.signature),
            INVALID_ORDER_SIGNATURE
        );

        
        if (!isMarketOrder(orderParam.data)) {
            
            
            orderInfo.margins[LONG] = calculateLongMargin(orderContext, orderParam);
            orderInfo.margins[SHORT] = calculateShortMargin(orderContext, orderParam);
        }
        orderInfo.balances[LONG] = IERC20(orderContext.positions[LONG]).balanceOf(orderParam.trader);
        orderInfo.balances[SHORT] = IERC20(orderContext.positions[SHORT]).balanceOf(orderParam.trader);

        return orderInfo;
    }

    
    function getOrderFromOrderParam(
        OrderParam memory orderParam,
        OrderAddressSet memory orderAddressSet
    )
        internal
        pure
        returns (Order memory order)
    {
        order.trader = orderParam.trader;
        order.relayer = orderAddressSet.relayer;
        order.marketContractAddress = orderAddressSet.marketContractAddress;
        order.amount = orderParam.amount;
        order.price = orderParam.price;
        order.gasTokenAmount = orderParam.gasTokenAmount;
        order.data = orderParam.data;
    }

    
    function settleResult(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        if (result.fillAction == FillAction.REDEEM) {
            doRedeem(result, orderAddressSet, orderContext);
        } else if (result.fillAction == FillAction.SELL) {
            doSell(result, orderAddressSet, orderContext);
        } else if (result.fillAction == FillAction.BUY) {
            doBuy(result, orderAddressSet, orderContext);
        } else if (result.fillAction == FillAction.MINT) {
            doMint(result, orderAddressSet, orderContext);
        } else {
            revert("UNEXPECTED_FILLACTION");
        }
        emit Match(orderAddressSet, result);
    }

    function doSell(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        uint256 takerTotalFee = result.takerFee.add(result.takerGasFee);
        uint256 makerTotalFee = result.makerFee.add(result.makerGasFee);
        
        orderContext.positions[oppositeSide(orderContext.takerSide)]
            .safeTransferFrom(
                result.taker,
                result.maker,
                result.posFilledAmount
            );
        
        
        orderContext.collateral.safeTransferFrom(
            result.maker,
            orderAddressSet.relayer,
            result.ctkFilledAmount.add(makerTotalFee)
        );
        if (result.ctkFilledAmount > takerTotalFee) {
            
            orderContext.collateral.safeTransferFrom(
                orderAddressSet.relayer,
                result.taker,
                result.ctkFilledAmount.sub(takerTotalFee)
            );
        } else if (result.ctkFilledAmount < takerTotalFee) {
            
            orderContext.collateral.safeTransferFrom(
                result.taker,
                orderAddressSet.relayer,
                takerTotalFee.sub(result.ctkFilledAmount)
            );
        }

        
        
        
        
        
        
        
        
        
        
        
        
        
    }

    
    function doBuy(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        uint256 makerTotalFee = result.makerFee.add(result.makerGasFee);
        uint256 takerTotalFee = result.takerFee.add(result.takerGasFee);
        
        orderContext.positions[orderContext.takerSide]
            .safeTransferFrom(
                result.maker,
                result.taker,
                result.posFilledAmount
            );
        
        if (result.ctkFilledAmount > makerTotalFee) {
            
            orderContext.collateral.safeTransferFrom(
                result.taker,
                result.maker,
                result.ctkFilledAmount.sub(makerTotalFee)
            );
        } else if (result.ctkFilledAmount < makerTotalFee) {
            
            orderContext.collateral.safeTransferFrom(
                result.maker,
                result.taker,
                makerTotalFee.sub(result.ctkFilledAmount)
            );
        }
        
        orderContext.collateral.safeTransferFrom(
            result.taker,
            orderAddressSet.relayer,
            takerTotalFee.add(makerTotalFee)
        );

        
        
        
        
        
        
        
        
        
        
        
        
        
        
    }

    function oppositeSide(uint256 side) internal pure returns (uint256) {
        return side == LONG ? SHORT : LONG;
    }

    
    function doRedeem(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        uint256 makerTotalFee = result.makerFee.add(result.makerGasFee);
        uint256 takerTotalFee = result.takerFee.add(result.takerGasFee);
        uint256 collateralToTaker = orderContext.marketContract.COLLATERAL_PER_UNIT()
            .mul(result.posFilledAmount)
            .sub(result.ctkFilledAmount);

        
        
        orderContext.positions[oppositeSide(orderContext.takerSide)]
            .safeTransferFrom(
                result.taker,
                address(this),
                result.posFilledAmount
            );
        
        orderContext.positions[orderContext.takerSide]
            .safeTransferFrom(
                result.maker,
                address(this),
                result.posFilledAmount
            );
        
        redeemPositionTokens(orderContext, result.posFilledAmount);
        
        
        if (result.ctkFilledAmount > makerTotalFee) {
            
            orderContext.collateral.safeTransfer(
                result.maker,
                result.ctkFilledAmount.sub(makerTotalFee)
            );
        } else if (result.ctkFilledAmount < makerTotalFee) {
            
            orderContext.collateral.safeTransferFrom(
                result.maker,
                address(this),
                makerTotalFee.sub(result.ctkFilledAmount)
            );
        }
        
        if (collateralToTaker > takerTotalFee) {
            
            orderContext.collateral.safeTransfer(
                result.taker,
                collateralToTaker.sub(takerTotalFee)
            );
        } else if (collateralToTaker < takerTotalFee) {
            
            orderContext.collateral.safeTransferFrom(
                result.taker,
                address(this),
                collateralToTaker.sub(takerTotalFee)
            );
        }
        
        orderContext.collateral.safeTransfer(
            orderAddressSet.relayer,
            makerTotalFee.add(takerTotalFee)
        );
    }

    
    function doMint(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        
        uint256 neededCollateral = result.posFilledAmount
            .mul(orderContext.marketContract.COLLATERAL_PER_UNIT());
        uint256 neededCollateralTokenFee = result.posFilledAmount
            .mul(orderContext.marketContract.COLLATERAL_TOKEN_FEE_PER_UNIT());
        uint256 mintFee = result.takerFee.add(result.makerFee);
        uint256 feeToRelayer = result.takerGasFee.add(result.makerGasFee);
        
        if (neededCollateralTokenFee > mintFee) {
            orderContext.collateral.safeTransferFrom(
                orderAddressSet.relayer,
                address(this),
                neededCollateralTokenFee.sub(mintFee)
            );
        } else if (neededCollateralTokenFee < mintFee) {
            feeToRelayer = feeToRelayer.add(mintFee).sub(neededCollateralTokenFee);
        }
        
        
        orderContext.collateral.safeTransferFrom(
            result.maker,
            address(this),
            result.ctkFilledAmount
                .add(result.makerFee)
                .add(result.makerGasFee)
        );
        
        orderContext.collateral.safeTransferFrom(
            result.taker,
            address(this),
            neededCollateral
                .sub(result.ctkFilledAmount)
                .add(result.takerFee)
                .add(result.takerGasFee)
        );
        
        mintPositionTokens(orderContext, result.posFilledAmount);
        
        
        orderContext.positions[orderContext.takerSide]
            .safeTransfer(
                result.taker,
                result.posFilledAmount
            );
        
        orderContext.positions[oppositeSide(orderContext.takerSide)]
            .safeTransfer(
                result.maker,
                result.posFilledAmount
            );
        
        orderContext.collateral.safeTransfer(
            orderAddressSet.relayer,
            feeToRelayer
        );
    }

    
    
    
    function mintPositionTokens(OrderContext memory orderContext, uint256 qtyToMint)
        internal
    {
        IMarketContractPool collateralPool;
        if (mintingPoolAddress != address(0x0)) {
            collateralPool = IMarketContractPool(mintingPoolAddress);
        } else {
            collateralPool = orderContext.marketContractPool;
        }
        collateralPool.mintPositionTokens(address(orderContext.marketContract), qtyToMint, false);
    }

    
    
    
    function redeemPositionTokens(OrderContext memory orderContext, uint256 qtyToRedeem)
        internal
    {
        IMarketContractPool collateralPool;
        if (mintingPoolAddress != address(0x0)) {
            collateralPool = IMarketContractPool(mintingPoolAddress);
        } else {
            collateralPool = orderContext.marketContractPool;
        }
        collateralPool.redeemPositionTokens(address(orderContext.marketContract), qtyToRedeem);
    }
}