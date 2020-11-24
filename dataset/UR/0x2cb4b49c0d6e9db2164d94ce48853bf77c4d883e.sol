 

 

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

 
 
 
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

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        uint256 c = a / b;
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        uint256 c = a - b;
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "MOD_ERROR");
        return a % b;
    }
}

 
contract EIP712 {
    string internal constant DOMAIN_NAME = "Hydro Protocol";
    string internal constant DOMAIN_VERSION = "1";

     
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = keccak256(
        abi.encodePacked("EIP712Domain(string name,string version,address verifyingContract)")
    );

    bytes32 public DOMAIN_SEPARATOR;

    constructor () public {
        DOMAIN_SEPARATOR = keccak256(
            abi.encodePacked(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(DOMAIN_NAME)),
                keccak256(bytes(DOMAIN_VERSION)),
                bytes32(address(this))
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

contract LibOrder is EIP712, LibSignature {
    struct Order {
        address trader;
        address relayer;
        address baseToken;
        address quoteToken;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 gasTokenAmount;

         
        bytes32 data;
    }

    enum OrderStatus {
        EXPIRED,
        CANCELLED,
        FILLABLE,
        FULLY_FILLED
    }

    bytes32 public constant EIP712_ORDER_TYPE = keccak256(
        abi.encodePacked(
            "Order(address trader,address relayer,address baseToken,address quoteToken,uint256 baseTokenAmount,uint256 quoteTokenAmount,uint256 gasTokenAmount,bytes32 data)"
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
            result := keccak256(start, 288)

            mstore(start, tmp)
        }

        return result;
    }

     

    function getExpiredAtFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(bytes5(data << (8*3)));
    }

    function isSell(bytes32 data) internal pure returns (bool) {
        return data[1] == 1;
    }

    function isMarketOrder(bytes32 data) internal pure returns (bool) {
        return data[2] == 1;
    }

    function isMarketBuy(bytes32 data) internal pure returns (bool) {
        return !isSell(data) && isMarketOrder(data);
    }

    function getAsMakerFeeRateFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(bytes2(data << (8*8)));
    }

    function getAsTakerFeeRateFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(bytes2(data << (8*10)));
    }

    function getMakerRebateRateFromOrderData(bytes32 data) internal pure returns (uint256) {
        return uint256(bytes2(data << (8*12)));
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

     
    function canMatchOrdersFrom(address relayer) public view returns(bool) {
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

 
contract LibDiscount is LibOwnable {
    using SafeMath for uint256;
    
     
    uint256 public constant DISCOUNT_RATE_BASE = 100;

    address public hotTokenAddress;

    constructor(address _hotTokenAddress) internal {
        hotTokenAddress = _hotTokenAddress;
    }

     
    function getHotBalance(address owner) internal view returns (uint256 result) {
        address hotToken = hotTokenAddress;

         

         
        assembly {
             
            let tmp1 := mload(0)
            let tmp2 := mload(4)

             
            mstore(0, 0x70a0823100000000000000000000000000000000000000000000000000000000)
            mstore(4, owner)

             
            result := call(
                gas,       
                hotToken,  
                0,         
                0,         
                36,        
                0,         
                32         
            )
            result := mload(0)

             
            mstore(0, tmp1)
            mstore(4, tmp2)
        }
    }

    bytes32 public discountConfig = 0x043c000027106400004e205a000075305000009c404600000000000000000000;

     
    function getDiscountedRate(address user) public view returns (uint256 result) {
        uint256 hotBalance = getHotBalance(user);

        if (hotBalance == 0) {
            return DISCOUNT_RATE_BASE;
        }

        bytes32 config = discountConfig;
        uint256 count = uint256(byte(config));
        uint256 bar;

         
        hotBalance = hotBalance.div(10**18);

        for (uint256 i = 0; i < count; i++) {
            bar = uint256(bytes4(config << (2 + i * 5) * 8));

            if (hotBalance < bar) {
                result = uint256(byte(config << (2 + i * 5 + 4) * 8));
                break;
            }
        }

         
        if (result == 0) {
            result = uint256(config[1]);
        }

         
        require(result <= DISCOUNT_RATE_BASE, "DISCOUNT_ERROR");
    }

     
    function changeDiscountConfig(bytes32 newConfig) external onlyOwner {
        discountConfig = newConfig;
    }
}

contract LibExchangeErrors {
    string constant INVALID_TRADER = "INVALID_TRADER";
    string constant INVALID_SENDER = "INVALID_SENDER";
     
    string constant INVALID_MATCH = "INVALID_MATCH";
    string constant INVALID_SIDE = "INVALID_SIDE";
     
    string constant INVALID_ORDER_SIGNATURE = "INVALID_ORDER_SIGNATURE";
     
    string constant INVALID_TAKER_ORDER = "INVALID_TAKER_ORDER";
    string constant ORDER_IS_NOT_FILLABLE = "ORDER_IS_NOT_FILLABLE";
    string constant MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER = "MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER";
    string constant COMPLETE_MATCH_FAILED = "COMPLETE_MATCH_FAILED";
     
    string constant TAKER_SELL_BASE_EXCEEDED = "TAKER_SELL_BASE_EXCEEDED";
     
    string constant TAKER_MARKET_BUY_QUOTE_EXCEEDED = "TAKER_MARKET_BUY_QUOTE_EXCEEDED";
     
    string constant TAKER_LIMIT_BUY_BASE_EXCEEDED = "TAKER_LIMIT_BUY_BASE_EXCEEDED";
    string constant TRANSFER_FROM_FAILED = "TRANSFER_FROM_FAILED";
    string constant RECORD_ADDRESSES_ERROR = "RECORD_ADDRESSES_ERROR";
    string constant PERIOD_NOT_COMPLETED_ERROR = "PERIOD_NOT_COMPLETED_ERROR";
    string constant CLAIM_HOT_TOKEN_ERROR = "CLAIM_HOT_TOKEN_ERROR";
    string constant INVALID_PERIOD = "INVALID_PERIOD";
}

contract HybridExchange is LibOrder, LibMath, LibRelayer, LibDiscount, LibExchangeErrors {
    using SafeMath for uint256;

    uint256 public constant FEE_RATE_BASE = 100000;

     
    address public proxyAddress;

     
    mapping (bytes32 => uint256) public filled;
     
    mapping (bytes32 => bool) public cancelled;

    event Cancel(bytes32 indexed orderHash);
    event Match(
        address baseToken,
        address quoteToken,
        address relayer,
        address maker,
        address taker,
        uint256 baseTokenAmount,
        uint256 quoteTokenAmount,
        uint256 makerFee,
        uint256 takerFee,
        uint256 makerGasFee,
        uint256 makerRebate,
        uint256 takerGasFee
    );

    struct TotalMatchResult {
        uint256 baseTokenFilledAmount;
        uint256 quoteTokenFilledAmount;
    }

    struct MatchResult {
        address maker;
        address taker;
        uint256 makerFee;
        uint256 makerRebate;
        uint256 takerFee;
        uint256 makerGasFee;
        uint256 takerGasFee;
        uint256 baseTokenFilledAmount;
        uint256 quoteTokenFilledAmount;
    }

     
    struct OrderParam {
        address trader;
        uint256 baseTokenAmount;
        uint256 quoteTokenAmount;
        uint256 gasTokenAmount;
        bytes32 data;
        OrderSignature signature;
    }

    struct OrderAddressSet {
        address baseToken;
        address quoteToken;
        address relayer;
    }

     
    struct OrderInfo {
        bytes32 orderHash;
        uint256 filledAmount;
    }

    constructor(address _proxyAddress, address hotTokenAddress)
        LibDiscount(hotTokenAddress)
        public
    {
        proxyAddress = _proxyAddress;
    }

     
    function matchOrders(
        OrderParam memory takerOrderParam,
        OrderParam[] memory makerOrderParams,
        OrderAddressSet memory orderAddressSet
    ) public {
        require(canMatchOrdersFrom(orderAddressSet.relayer), INVALID_SENDER);

        bool isParticipantRelayer = isParticipant(orderAddressSet.relayer);
        uint256 takerFeeRate = getTakerFeeRate(takerOrderParam, isParticipantRelayer);
        OrderInfo memory takerOrderInfo = getOrderInfo(takerOrderParam, orderAddressSet);

         
        MatchResult[] memory results = new MatchResult[](makerOrderParams.length);
        TotalMatchResult memory totalMatch;
        for (uint256 i = 0; i < makerOrderParams.length; i++) {
            require(!isMarketOrder(makerOrderParams[i].data), MAKER_ORDER_CAN_NOT_BE_MARKET_ORDER);
            require(isSell(takerOrderParam.data) != isSell(makerOrderParams[i].data), INVALID_SIDE);
            validatePrice(takerOrderParam, makerOrderParams[i]);

            OrderInfo memory makerOrderInfo = getOrderInfo(makerOrderParams[i], orderAddressSet);

            results[i] = getMatchResult(
                takerOrderParam,
                takerOrderInfo,
                makerOrderParams[i],
                makerOrderInfo,
                takerFeeRate,
                isParticipantRelayer
            );

             
            totalMatch.baseTokenFilledAmount = totalMatch.baseTokenFilledAmount.add(
                results[i].baseTokenFilledAmount
            );
            totalMatch.quoteTokenFilledAmount = totalMatch.quoteTokenFilledAmount.add(
                results[i].quoteTokenFilledAmount
            );

             
            filled[makerOrderInfo.orderHash] = makerOrderInfo.filledAmount.add(
                results[i].baseTokenFilledAmount
            );
        }

        validateMatchResult(takerOrderParam, totalMatch);
        settleResults(results, takerOrderParam, orderAddressSet);

         
        filled[takerOrderInfo.orderHash] = takerOrderInfo.filledAmount;
    }

     
    function cancelOrder(Order memory order) public {
        require(order.trader == msg.sender, INVALID_TRADER);

        bytes32 orderHash = getOrderHash(order);
        cancelled[orderHash] = true;

        emit Cancel(orderHash);
    }

     
    function getOrderInfo(OrderParam memory orderParam, OrderAddressSet memory orderAddressSet)
        internal
        view
        returns (OrderInfo memory orderInfo)
    {
        Order memory order = getOrderFromOrderParam(orderParam, orderAddressSet);
        orderInfo.orderHash = getOrderHash(order);
        orderInfo.filledAmount = filled[orderInfo.orderHash];
        uint8 status = uint8(OrderStatus.FILLABLE);

        if (!isMarketBuy(order.data) && orderInfo.filledAmount >= order.baseTokenAmount) {
            status = uint8(OrderStatus.FULLY_FILLED);
        } else if (isMarketBuy(order.data) && orderInfo.filledAmount >= order.quoteTokenAmount) {
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

        return orderInfo;
    }

     
    function getOrderFromOrderParam(OrderParam memory orderParam, OrderAddressSet memory orderAddressSet)
        internal
        pure
        returns (Order memory order)
    {
        order.trader = orderParam.trader;
        order.baseTokenAmount = orderParam.baseTokenAmount;
        order.quoteTokenAmount = orderParam.quoteTokenAmount;
        order.gasTokenAmount = orderParam.gasTokenAmount;
        order.data = orderParam.data;
        order.baseToken = orderAddressSet.baseToken;
        order.quoteToken = orderAddressSet.quoteToken;
        order.relayer = orderAddressSet.relayer;
    }

     
    function validatePrice(OrderParam memory takerOrderParam, OrderParam memory makerOrderParam)
        internal
        pure
    {
        uint256 left = takerOrderParam.quoteTokenAmount.mul(makerOrderParam.baseTokenAmount);
        uint256 right = takerOrderParam.baseTokenAmount.mul(makerOrderParam.quoteTokenAmount);
        require(isSell(takerOrderParam.data) ? left <= right : left >= right, INVALID_MATCH);
    }

     
    function getMatchResult(
        OrderParam memory takerOrderParam,
        OrderInfo memory takerOrderInfo,
        OrderParam memory makerOrderParam,
        OrderInfo memory makerOrderInfo,
        uint256 takerFeeRate,
        bool isParticipantRelayer
    )
        internal
        view
        returns (MatchResult memory result)
    {
         
         
         
        uint256 filledAmount;

         
         
         
        if(!isMarketBuy(takerOrderParam.data)) {
            filledAmount = min(
                takerOrderParam.baseTokenAmount.sub(takerOrderInfo.filledAmount),
                makerOrderParam.baseTokenAmount.sub(makerOrderInfo.filledAmount)
            );
            result.quoteTokenFilledAmount = convertBaseToQuote(makerOrderParam, filledAmount);
            result.baseTokenFilledAmount = filledAmount;
        } else {
             
             
             
            filledAmount = min(
                takerOrderParam.quoteTokenAmount.sub(takerOrderInfo.filledAmount),
                convertBaseToQuote(
                    makerOrderParam,
                    makerOrderParam.baseTokenAmount.sub(makerOrderInfo.filledAmount)
                )
            );
            result.baseTokenFilledAmount = convertQuoteToBase(makerOrderParam, filledAmount);
            result.quoteTokenFilledAmount = filledAmount;
        }

         
        if (takerOrderInfo.filledAmount == 0) {
            result.takerGasFee = takerOrderParam.gasTokenAmount;
        }

        if (makerOrderInfo.filledAmount == 0) {
            result.makerGasFee = makerOrderParam.gasTokenAmount;
        }

         
         
        takerOrderInfo.filledAmount = takerOrderInfo.filledAmount.add(filledAmount);

        result.maker = makerOrderParam.trader;
        result.taker = takerOrderParam.trader;

         
        uint256 rebateRate = getMakerRebateRateFromOrderData(makerOrderParam.data);
        uint256 makerRawFeeRate = getAsMakerFeeRateFromOrderData(makerOrderParam.data);

        if (rebateRate > makerRawFeeRate) {
             
            uint256 makerRebateRate = min(
                 
                 
                rebateRate.sub(makerRawFeeRate).mul(DISCOUNT_RATE_BASE),
                takerFeeRate
            );
            result.makerRebate = result.quoteTokenFilledAmount.mul(makerRebateRate).div(
                FEE_RATE_BASE.mul(DISCOUNT_RATE_BASE)
            );
             
            result.makerFee = 0;
        } else {
             
            uint256 makerFeeRate = getFinalFeeRate(
                makerOrderParam.trader,
                makerRawFeeRate.sub(rebateRate),
                isParticipantRelayer
            );
            result.makerFee = result.quoteTokenFilledAmount.mul(makerFeeRate).div(
                FEE_RATE_BASE.mul(DISCOUNT_RATE_BASE)
            );
            result.makerRebate = 0;
        }

        result.takerFee = result.quoteTokenFilledAmount.mul(takerFeeRate).div(
            FEE_RATE_BASE.mul(DISCOUNT_RATE_BASE)
        );
    }

     
    function getTakerFeeRate(OrderParam memory orderParam, bool isParticipantRelayer)
        internal
        view
        returns(uint256)
    {
        uint256 rawRate = getAsTakerFeeRateFromOrderData(orderParam.data);
        return getFinalFeeRate(orderParam.trader, rawRate, isParticipantRelayer);
    }

     
    function getFinalFeeRate(address trader, uint256 rate, bool isParticipantRelayer)
        internal
        view
        returns(uint256)
    {
        if (isParticipantRelayer) {
            return rate.mul(getDiscountedRate(trader));
        } else {
            return rate.mul(DISCOUNT_RATE_BASE);
        }
    }

     
    function convertBaseToQuote(OrderParam memory orderParam, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return getPartialAmountFloor(
            orderParam.quoteTokenAmount,
            orderParam.baseTokenAmount,
            amount
        );
    }

     
    function convertQuoteToBase(OrderParam memory orderParam, uint256 amount)
        internal
        pure
        returns (uint256)
    {
        return getPartialAmountFloor(
            orderParam.baseTokenAmount,
            orderParam.quoteTokenAmount,
            amount
        );
    }

     
    function validateMatchResult(OrderParam memory takerOrderParam, TotalMatchResult memory totalMatch)
        internal
        pure
    {
        if (isSell(takerOrderParam.data)) {
             
            require(
                totalMatch.baseTokenFilledAmount <= takerOrderParam.baseTokenAmount,
                TAKER_SELL_BASE_EXCEEDED
            );
        } else {
             
            require(
                totalMatch.quoteTokenFilledAmount <= takerOrderParam.quoteTokenAmount,
                TAKER_MARKET_BUY_QUOTE_EXCEEDED
            );

             
             
             
            if (!isMarketOrder(takerOrderParam.data)) {
                require(
                    totalMatch.baseTokenFilledAmount <= takerOrderParam.baseTokenAmount,
                    TAKER_LIMIT_BUY_BASE_EXCEEDED
                );
            }
        }
    }

     
    function settleResults(
        MatchResult[] memory results,
        OrderParam memory takerOrderParam,
        OrderAddressSet memory orderAddressSet
    )
        internal
    {
        if (isSell(takerOrderParam.data)) {
            settleTakerSell(results, orderAddressSet);
        } else {
            settleTakerBuy(results, orderAddressSet);
        }
    }

     
    function settleTakerSell(MatchResult[] memory results, OrderAddressSet memory orderAddressSet) internal {
        uint256 totalTakerBaseTokenFilledAmount = 0;

        for (uint256 i = 0; i < results.length; i++) {
            transferFrom(
                orderAddressSet.baseToken,
                results[i].taker,
                results[i].maker,
                results[i].baseTokenFilledAmount
            );

            transferFrom(
                orderAddressSet.quoteToken,
                results[i].maker,
                orderAddressSet.relayer,
                results[i].quoteTokenFilledAmount.
                    add(results[i].makerFee).
                    add(results[i].makerGasFee).
                    sub(results[i].makerRebate)
            );

            totalTakerBaseTokenFilledAmount = totalTakerBaseTokenFilledAmount.add(
                results[i].quoteTokenFilledAmount.sub(results[i].takerFee)
            );

            emitMatchEvent(results[i], orderAddressSet);
        }

        transferFrom(
            orderAddressSet.quoteToken,
            orderAddressSet.relayer,
            results[0].taker,
            totalTakerBaseTokenFilledAmount.sub(results[0].takerGasFee)
        );
    }

     
    function settleTakerBuy(MatchResult[] memory results, OrderAddressSet memory orderAddressSet) internal {
        uint256 totalFee = 0;

        for (uint256 i = 0; i < results.length; i++) {
            transferFrom(
                orderAddressSet.baseToken,
                results[i].maker,
                results[i].taker,
                results[i].baseTokenFilledAmount
            );

            transferFrom(
                orderAddressSet.quoteToken,
                results[i].taker,
                results[i].maker,
                results[i].quoteTokenFilledAmount.
                    sub(results[i].makerFee).
                    sub(results[i].makerGasFee).
                    add(results[i].makerRebate)
            );

            totalFee = totalFee.
                add(results[i].takerFee).
                add(results[i].makerFee).
                add(results[i].makerGasFee).
                add(results[i].takerGasFee).
                sub(results[i].makerRebate);

            emitMatchEvent(results[i], orderAddressSet);
        }

        transferFrom(
            orderAddressSet.quoteToken,
            results[0].taker,
            orderAddressSet.relayer,
            totalFee
        );
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

    function emitMatchEvent(MatchResult memory result, OrderAddressSet memory orderAddressSet) internal {
        emit Match(
            orderAddressSet.baseToken,
            orderAddressSet.quoteToken,
            orderAddressSet.relayer,
            result.maker,
            result.taker,
            result.baseTokenFilledAmount,
            result.quoteTokenFilledAmount,
            result.makerFee,
            result.takerFee,
            result.makerGasFee,
            result.makerRebate,
            result.takerGasFee
        );
    }
}