 

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
    string constant MAKER_CAN_NOT_BE_SAME_WITH_TAKER = "MAKER_CANNOT_BE_TAKER";
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

contract MaiProtocol is LibMath, LibOrder, LibRelayer, LibExchangeErrors, LibOwnable {
    using SafeMath for uint256;

    uint256 public constant MAX_MATCHES = 3;
    uint256 public constant LONG = 0;
    uint256 public constant SHORT = 1;
    uint256 public constant FEE_RATE_BASE = 100000;

    
    uint256 public constant SUPPORTED_ORDER_VERSION = 1;

    
    address public proxyAddress;

    
    address public marketRegistryAddress;

    
    mapping (bytes32 => uint256) public filled;

    
    mapping (bytes32 => bool) public cancelled;

    event Cancel(bytes32 indexed orderHash);

    
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
        address ctkAddress;                     
        address[2] posAddresses;                
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

    constructor(address _proxyAddress) public {
        proxyAddress = _proxyAddress;
    }

    
    function setMarketRegistryAddress(address _marketRegistryAddress)
        external
        onlyOwner
    {
        marketRegistryAddress = _marketRegistryAddress;
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
        MatchResult[] memory results = getMatchPlan(
            takerOrderParam,
            makerOrderParams,
            posFilledAmounts,
            orderAddressSet,
            orderContext
        );
        settleResults(results, takerOrderParam, orderAddressSet, orderContext);
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
        orderContext.ctkAddress = orderContext.marketContract.COLLATERAL_TOKEN_ADDRESS();
        orderContext.posAddresses[LONG] = orderContext.marketContract.LONG_POSITION_TOKEN();
        orderContext.posAddresses[SHORT] = orderContext.marketContract.SHORT_POSITION_TOKEN();
        orderContext.takerSide = isSell(takerOrderParam.data) ? SHORT : LONG;

        return orderContext;
    }

    
    function getMatchPlan(
        OrderParam memory takerOrderParam,
        OrderParam[] memory makerOrderParams,
        uint256[] memory posFilledAmounts,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
        returns (MatchResult[] memory results)
    {
        OrderInfo memory takerOrderInfo = getOrderInfo(
            takerOrderParam,
            orderAddressSet,
            orderContext
        );

        uint256 resultIndex;
        
        
        results = new MatchResult[](makerOrderParams.length * MAX_MATCHES);
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
                makerOrderParams[i],
                orderContext
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
                results[resultIndex] = result;
                resultIndex++;
            }
            
            
            require(toFillAmount == 0, UNMATCHED_FILL);
            filled[makerOrderInfo.orderHash] = makerOrderInfo.filledAmount;
        }
        filled[takerOrderInfo.orderHash] = takerOrderInfo.filledAmount;

        return results;
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
        OrderParam memory makerOrderParam,
        OrderContext memory orderContext
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
        
        require(msg.sender == order.relayer, INVALID_TRADER);

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
            orderInfo.margins[0] = calculateLongMargin(orderContext, orderParam);
            orderInfo.margins[1] = calculateShortMargin(orderContext, orderParam);
        }
        orderInfo.balances[0] = getERC20Balance(orderContext.posAddresses[0], orderParam.trader);
        orderInfo.balances[1] = getERC20Balance(orderContext.posAddresses[1], orderParam.trader);

        return orderInfo;
    }

    
    function getERC20Balance(address tokenAddress, address account)
        internal
        view
        returns (uint256)
    {
        return IERC20(tokenAddress).balanceOf(account);
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

    
    function calculateTotalFee(MatchResult memory result)
        internal
        pure
        returns (uint256)
    {
        return result.takerFee
            .add(result.takerGasFee)
            .add(result.makerFee)
            .add(result.makerGasFee);
    }

    
    function settleResults(
        MatchResult[] memory results,
        OrderParam memory takerOrderParam,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
    {
        uint256 ctkFromProxyToTaker;
        uint256 ctkFromProxyToRelayer;
        uint256 ctkFromRelayerToTaker;
        uint256 ctkFromTakerToRelayer;

        for (uint256 i = 0; i < results.length; i++) {
            if (results[i].fillAction == FillAction.REDEEM) {
                
                ctkFromProxyToTaker = ctkFromProxyToTaker
                    .add(doRedeem(results[i], orderAddressSet, orderContext));
                ctkFromProxyToRelayer = ctkFromProxyToRelayer
                    .add(calculateTotalFee(results[i]));
            } else if (results[i].fillAction == FillAction.SELL) {
                
                ctkFromRelayerToTaker = ctkFromRelayerToTaker
                    .add(doSell(results[i], orderAddressSet, orderContext));
            } else if (results[i].fillAction == FillAction.BUY) {
                
                ctkFromTakerToRelayer = ctkFromTakerToRelayer
                    .add(doBuy(results[i], orderAddressSet, orderContext));
            } else if (results[i].fillAction == FillAction.MINT) {
                
                ctkFromProxyToRelayer = ctkFromProxyToRelayer
                    .add(doMint(results[i], orderAddressSet, orderContext));
            } else {
                break;
            }

            emit Match(orderAddressSet, results[i]);
        }

        if (ctkFromProxyToTaker > 0) {
            transfer(
                orderContext.ctkAddress,
                takerOrderParam.trader,
                ctkFromProxyToTaker
            );
        }
        if (ctkFromProxyToRelayer > 0) {
            transfer(
                orderContext.ctkAddress,
                orderAddressSet.relayer,
                ctkFromProxyToRelayer
            );
        }
        if (ctkFromRelayerToTaker > ctkFromTakerToRelayer) {
            transferFrom(
                orderContext.ctkAddress,
                orderAddressSet.relayer,
                takerOrderParam.trader,
                ctkFromRelayerToTaker.sub(ctkFromTakerToRelayer)
            );
        } else if (ctkFromRelayerToTaker < ctkFromTakerToRelayer) {
            transferFrom(
                orderContext.ctkAddress,
                takerOrderParam.trader,
                orderAddressSet.relayer,
                ctkFromTakerToRelayer.sub(ctkFromRelayerToTaker)
            );
        }
    }

    function doSell(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
        returns (uint256)
    {
        
        transferFrom(
            orderContext.posAddresses[oppositeSide(orderContext.takerSide)],
            result.taker,
            result.maker,
            result.posFilledAmount
        );
        
        transferFrom(
            orderContext.ctkAddress,
            result.maker,
            orderAddressSet.relayer,
            result.ctkFilledAmount
                .add(result.makerFee)
                .add(result.makerGasFee)
        );
        require(result.ctkFilledAmount >= result.takerFee.add(result.takerGasFee), LOW_MARGIN);
        
        return result.ctkFilledAmount
            .sub(result.takerFee)
            .sub(result.takerGasFee);
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
        returns (uint256)
    {
        
        transferFrom(
            orderContext.posAddresses[oppositeSide(orderContext.takerSide)],
            result.taker,
            proxyAddress,
            result.posFilledAmount
        );
        
        transferFrom(
            orderContext.posAddresses[orderContext.takerSide],
            result.maker,
            proxyAddress,
            result.posFilledAmount
        );
        
        redeemPositionTokens(orderAddressSet.marketContractAddress, result.posFilledAmount);
        
        transfer(
            orderContext.ctkAddress,
            result.maker,
            result.ctkFilledAmount
                .sub(result.makerFee)
                .sub(result.makerGasFee)
        );
        uint256 collateralToReturn = result.posFilledAmount
            .mul(orderContext.marketContract.COLLATERAL_PER_UNIT());
        
        return collateralToReturn
            .sub(result.ctkFilledAmount)
            .sub(result.takerFee)
            .sub(result.takerGasFee);
    }

    
    function doBuy(
        MatchResult memory result,
        OrderAddressSet memory,
        OrderContext memory orderContext
    )
        internal
        returns (uint256)
    {
        
        transferFrom(
            orderContext.posAddresses[orderContext.takerSide],
            result.maker,
            result.taker,
            result.posFilledAmount
        );
        require(result.ctkFilledAmount >= result.makerFee.add(result.makerGasFee), LOW_MARGIN);
        
        transferFrom(
            orderContext.ctkAddress,
            result.taker,
            result.maker,
            result.ctkFilledAmount
                .sub(result.makerFee)
                .sub(result.makerGasFee)
        );
        
        return result.takerFee
            .add(result.takerGasFee)
            .add(result.makerFee)
            .add(result.makerGasFee);
    }

    
    function doMint(
        MatchResult memory result,
        OrderAddressSet memory orderAddressSet,
        OrderContext memory orderContext
    )
        internal
        returns (uint256)
    {
        
        uint256 neededCollateral = result.posFilledAmount
            .mul(orderContext.marketContract.COLLATERAL_PER_UNIT());
        uint256 neededCollateralTokenFee = result.posFilledAmount
            .mul(orderContext.marketContract.COLLATERAL_TOKEN_FEE_PER_UNIT());
        uint256 totalFee = result.takerFee.add(result.makerFee);

        if (neededCollateralTokenFee > totalFee) {
            transferFrom(
                orderContext.ctkAddress,
                orderAddressSet.relayer,
                proxyAddress,
                neededCollateralTokenFee.sub(totalFee)
            );
        }
        
        transferFrom(
            orderContext.ctkAddress,
            result.maker,
            proxyAddress,
            result.ctkFilledAmount
                .add(result.makerFee)
                .add(result.makerGasFee)
        );
        
        transferFrom(
            orderContext.ctkAddress,
            result.taker,
            proxyAddress,
            neededCollateral
                .sub(result.ctkFilledAmount)
                .add(result.takerFee)
                .add(result.takerGasFee)
        );
        
        mintPositionTokens(orderAddressSet.marketContractAddress, result.posFilledAmount);
        
        transfer(
            orderContext.posAddresses[orderContext.takerSide],
            result.taker,
            result.posFilledAmount
        );
        
        transfer(
            orderContext.posAddresses[oppositeSide(orderContext.takerSide)],
            result.maker,
            result.posFilledAmount
        );
        if (neededCollateralTokenFee > totalFee) {
            return result.takerGasFee.add(result.makerGasFee);
        }
        
        return result.makerFee
            .add(result.takerFee)
            .add(result.takerGasFee)
            .add(result.makerGasFee)
            .sub(neededCollateralTokenFee);
    }

    
    function transfer(address token, address to, uint256 value) internal {
        if (value == 0) {
            return;
        }

        address proxy = proxyAddress;
        uint256 result;

        
        
        assembly {
            
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)
            let tmp4 := mload(68)

            
            mstore(0, 0xbeabacc800000000000000000000000000000000000000000000000000000000)
            mstore(4, token)
            mstore(36, to)
            mstore(68, value)

            
            result := call(
                gas,   
                proxy, 
                0,     
                0,     
                100,   
                0,     
                0      
            )

            
            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)
            mstore(68, tmp4)
        }

        if (result == 0) {
            revert(TRANSFER_FAILED);
        }
    }

    
    function transferFrom(address token, address from, address to, uint256 value) internal {
        if (value == 0) {
            return;
        }

        address proxy = proxyAddress;
        uint256 result;

        
        
        assembly {
            
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)
            let tmp4 := mload(68)
            let tmp5 := mload(100)

            
            mstore(0, 0x15dacbea00000000000000000000000000000000000000000000000000000000)
            mstore(4, token)
            mstore(36, from)
            mstore(68, to)
            mstore(100, value)

            
            result := call(
                gas,   
                proxy, 
                0,     
                0,     
                132,   
                0,     
                0      
            )

            
            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)
            mstore(68, tmp4)
            mstore(100, tmp5)
        }

        if (result == 0) {
            revert(TRANSFER_FROM_FAILED);
        }
    }

    function mintPositionTokens(address contractAddress, uint256 value) internal {
        if (value == 0) {
            return;
        }

        address proxy = proxyAddress;
        uint256 result;

        
        
        assembly {
            
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)

            
            mstore(0, 0x2bb0d30f00000000000000000000000000000000000000000000000000000000)
            mstore(4, contractAddress)
            mstore(36, value)

            
            result := call(
                gas,   
                proxy, 
                0,     
                0,     
                68,   
                0,     
                0      
            )

            
            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)
        }

        if (result == 0) {
            revert(MINT_POSITION_TOKENS_FAILED);
        }
    }

    function redeemPositionTokens(address contractAddress, uint256 value) internal {
        if (value == 0) {
            return;
        }

        address proxy = proxyAddress;
        uint256 result;

        
        
        assembly {
            
            let tmp1 := mload(0)
            let tmp2 := mload(4)
            let tmp3 := mload(36)

            
            mstore(0, 0xc1b2141100000000000000000000000000000000000000000000000000000000)
            mstore(4, contractAddress)
            mstore(36, value)

            
            result := call(
                gas,   
                proxy, 
                0,     
                0,     
                68,   
                0,     
                0      
            )

            
            mstore(0, tmp1)
            mstore(4, tmp2)
            mstore(36, tmp3)
        }

        if (result == 0) {
            revert(REDEEM_POSITION_TOKENS_FAILED);
        }
    }
}