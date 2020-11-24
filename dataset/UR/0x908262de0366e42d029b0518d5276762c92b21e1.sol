 

pragma solidity 0.4.24;

 
library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract Ownable {
    address public owner;

    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

 
 
 
 
contract Orderbook  {
     
     
    enum OrderState {Undefined, Open, Confirmed, Canceled}

     
    function orderMatch(bytes32 _orderID) external view returns (bytes32);

     
     
    function orderTrader(bytes32 _orderID) external view returns (address);

     
    function orderState(bytes32 _orderID) external view returns (OrderState);

     
    function orderConfirmer(bytes32 _orderID) external view returns (address);
}


 
contract RenExTokens is Ownable {
    struct TokenDetails {
        address addr;
        uint8 decimals;
        bool registered;
    }

    mapping(uint32 => TokenDetails) public tokens;

     
     
     
     
     
     
     
     
     
     
    function registerToken(uint32 _tokenCode, address _tokenAddress, uint8 _tokenDecimals) public onlyOwner;

     
     
     
     
    function deregisterToken(uint32 _tokenCode) external onlyOwner;
}


 
contract RenExBalances {
    address public settlementContract;

     
     
    modifier onlyRenExSettlementContract() {
        require(msg.sender == address(settlementContract), "not authorized");
        _;
    }

     
     
     
     
     
     
     
     
     
     
     
    function transferBalanceWithFee(address _traderFrom, address _traderTo, address _token, uint256 _value, uint256 _fee, address _feePayee)
    external onlyRenExSettlementContract;
}


 
library SettlementUtils {

    struct OrderDetails {
        uint64 settlementID;
        uint64 tokens;
        uint256 price;
        uint256 volume;
        uint256 minimumVolume;
    }

     
     
     
     
    function hashOrder(bytes details, OrderDetails memory order) internal pure returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                details,
                order.settlementID,
                order.tokens,
                order.price,
                order.volume,
                order.minimumVolume
            )
        );
    }

     
     
     
     
     
     
     
     
     
    function verifyMatchDetails(OrderDetails memory _buy, OrderDetails memory _sell) internal pure returns (bool) {

         
        if (!verifyTokens(_buy.tokens, _sell.tokens)) {
            return false;
        }

         
        if (_buy.price < _sell.price) {
            return false;
        }

         
        if (_buy.volume < _sell.minimumVolume) {
            return false;
        }

         
        if (_sell.volume < _buy.minimumVolume) {
            return false;
        }

         
        if (_buy.settlementID != _sell.settlementID) {
            return false;
        }

        return true;
    }

     
     
     
     
    function verifyTokens(uint64 _buyTokens, uint64 _sellToken) internal pure returns (bool) {
        return ((
                uint32(_buyTokens) == uint32(_sellToken >> 32)) && (
                uint32(_sellToken) == uint32(_buyTokens >> 32)) && (
                uint32(_buyTokens >> 32) <= uint32(_buyTokens))
        );
    }
}

 
 
 
contract RenExSettlement is Ownable {
    using SafeMath for uint256;

    string public VERSION;  

     
    uint32 constant public RENEX_SETTLEMENT_ID = 1;
    uint32 constant public RENEX_ATOMIC_SETTLEMENT_ID = 2;

     
     
    uint256 constant public DARKNODE_FEES_NUMERATOR = 2;
    uint256 constant public DARKNODE_FEES_DENOMINATOR = 1000;

     
    int16 constant private PRICE_OFFSET = 12;
    int16 constant private VOLUME_OFFSET = 12;

     
    Orderbook public orderbookContract;
    RenExTokens public renExTokensContract;
    RenExBalances public renExBalancesContract;
    address public slasherAddress;
    uint256 public submissionGasPriceLimit;

    enum OrderStatus {None, Submitted, Settled, Slashed}

    struct TokenPair {
        RenExTokens.TokenDetails priorityToken;
        RenExTokens.TokenDetails secondaryToken;
    }

     
    struct ValueWithFees {
        uint256 value;
        uint256 fees;
    }

     
    struct Fraction {
        uint256 numerator;
        uint256 denominator;
    }

     
     
    struct SettlementDetails {
        uint256 leftVolume;
        uint256 rightVolume;
        uint256 leftTokenFee;
        uint256 rightTokenFee;
        address leftTokenAddress;
        address rightTokenAddress;
    }

     
    event LogOrderbookUpdated(Orderbook previousOrderbook, Orderbook nextOrderbook);
    event LogRenExTokensUpdated(RenExTokens previousRenExTokens, RenExTokens nextRenExTokens);
    event LogRenExBalancesUpdated(RenExBalances previousRenExBalances, RenExBalances nextRenExBalances);
    event LogSubmissionGasPriceLimitUpdated(uint256 previousSubmissionGasPriceLimit, uint256 nextSubmissionGasPriceLimit);
    event LogSlasherUpdated(address previousSlasher, address nextSlasher);

     
    mapping(bytes32 => SettlementUtils.OrderDetails) public orderDetails;
    mapping(bytes32 => address) public orderSubmitter;
    mapping(bytes32 => OrderStatus) public orderStatus;

     
    mapping(bytes32 => mapping(bytes32 => uint256)) public matchTimestamp;

     
     
     
     
    modifier withGasPriceLimit(uint256 _gasPriceLimit) {
        require(tx.gasprice <= _gasPriceLimit, "gas price too high");
        _;
    }

     
     
    modifier onlySlasher() {
        require(msg.sender == slasherAddress, "unauthorized");
        _;
    }

     
     
     
     
     
     
     
    constructor(
        string _VERSION,
        Orderbook _orderbookContract,
        RenExTokens _renExTokensContract,
        RenExBalances _renExBalancesContract,
        address _slasherAddress,
        uint256 _submissionGasPriceLimit
    ) public {
        VERSION = _VERSION;
        orderbookContract = _orderbookContract;
        renExTokensContract = _renExTokensContract;
        renExBalancesContract = _renExBalancesContract;
        slasherAddress = _slasherAddress;
        submissionGasPriceLimit = _submissionGasPriceLimit;
    }

     
     
    function updateOrderbook(Orderbook _newOrderbookContract) external onlyOwner {
        emit LogOrderbookUpdated(orderbookContract, _newOrderbookContract);
        orderbookContract = _newOrderbookContract;
    }

     
     
     
    function updateRenExTokens(RenExTokens _newRenExTokensContract) external onlyOwner {
        emit LogRenExTokensUpdated(renExTokensContract, _newRenExTokensContract);
        renExTokensContract = _newRenExTokensContract;
    }
    
     
     
     
    function updateRenExBalances(RenExBalances _newRenExBalancesContract) external onlyOwner {
        emit LogRenExBalancesUpdated(renExBalancesContract, _newRenExBalancesContract);
        renExBalancesContract = _newRenExBalancesContract;
    }

     
     
     
    function updateSubmissionGasPriceLimit(uint256 _newSubmissionGasPriceLimit) external onlyOwner {
        emit LogSubmissionGasPriceLimitUpdated(submissionGasPriceLimit, _newSubmissionGasPriceLimit);
        submissionGasPriceLimit = _newSubmissionGasPriceLimit;
    }

     
     
    function updateSlasher(address _newSlasherAddress) external onlyOwner {
        emit LogSlasherUpdated(slasherAddress, _newSlasherAddress);
        slasherAddress = _newSlasherAddress;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function submitOrder(
        bytes _prefix,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external withGasPriceLimit(submissionGasPriceLimit) {

        SettlementUtils.OrderDetails memory order = SettlementUtils.OrderDetails({
            settlementID: _settlementID,
            tokens: _tokens,
            price: _price,
            volume: _volume,
            minimumVolume: _minimumVolume
        });
        bytes32 orderID = SettlementUtils.hashOrder(_prefix, order);

        require(orderStatus[orderID] == OrderStatus.None, "order already submitted");
        require(orderbookContract.orderState(orderID) == Orderbook.OrderState.Confirmed, "unconfirmed order");

        orderSubmitter[orderID] = msg.sender;
        orderStatus[orderID] = OrderStatus.Submitted;
        orderDetails[orderID] = order;
    }

     
     
     
     
     
    function settle(bytes32 _buyID, bytes32 _sellID) external {
        require(orderStatus[_buyID] == OrderStatus.Submitted, "invalid buy status");
        require(orderStatus[_sellID] == OrderStatus.Submitted, "invalid sell status");

         
         
        require(
            orderDetails[_buyID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID ||
            orderDetails[_buyID].settlementID == RENEX_SETTLEMENT_ID,
            "invalid settlement id"
        );

         
        require(SettlementUtils.verifyMatchDetails(orderDetails[_buyID], orderDetails[_sellID]), "incompatible orders");

         
        require(orderbookContract.orderMatch(_buyID) == _sellID, "unconfirmed orders");

         
        TokenPair memory tokens = getTokenDetails(orderDetails[_buyID].tokens);

         
        require(tokens.priorityToken.registered, "unregistered priority token");
        require(tokens.secondaryToken.registered, "unregistered secondary token");

        address buyer = orderbookContract.orderTrader(_buyID);
        address seller = orderbookContract.orderTrader(_sellID);

        require(buyer != seller, "orders from same trader");

        execute(_buyID, _sellID, buyer, seller, tokens);

         
        matchTimestamp[_buyID][_sellID] = now;

         
        orderStatus[_buyID] = OrderStatus.Settled;
        orderStatus[_sellID] = OrderStatus.Settled;
    }

     
     
     
     
     
     
     
     
     
     
     
    function slash(bytes32 _guiltyOrderID) external onlySlasher {
        require(orderDetails[_guiltyOrderID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID, "slashing non-atomic trade");

        bytes32 innocentOrderID = orderbookContract.orderMatch(_guiltyOrderID);

        require(orderStatus[_guiltyOrderID] == OrderStatus.Settled, "invalid order status");
        require(orderStatus[innocentOrderID] == OrderStatus.Settled, "invalid order status");
        orderStatus[_guiltyOrderID] = OrderStatus.Slashed;

        (bytes32 buyID, bytes32 sellID) = isBuyOrder(_guiltyOrderID) ?
            (_guiltyOrderID, innocentOrderID) : (innocentOrderID, _guiltyOrderID);

        TokenPair memory tokens = getTokenDetails(orderDetails[buyID].tokens);

        SettlementDetails memory settlementDetails = calculateAtomicFees(buyID, sellID, tokens);

         
        renExBalancesContract.transferBalanceWithFee(
            orderbookContract.orderTrader(_guiltyOrderID),
            orderbookContract.orderTrader(innocentOrderID),
            settlementDetails.leftTokenAddress,
            settlementDetails.leftTokenFee,
            0,
            0x0
        );

         
        renExBalancesContract.transferBalanceWithFee(
            orderbookContract.orderTrader(_guiltyOrderID),
            slasherAddress,
            settlementDetails.leftTokenAddress,
            settlementDetails.leftTokenFee,
            0,
            0x0
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function getMatchDetails(bytes32 _orderID)
    external view returns (
        bool settled,
        bool orderIsBuy,
        bytes32 matchedID,
        uint256 priorityVolume,
        uint256 secondaryVolume,
        uint256 priorityFee,
        uint256 secondaryFee,
        uint32 priorityToken,
        uint32 secondaryToken
    ) {
        matchedID = orderbookContract.orderMatch(_orderID);

        orderIsBuy = isBuyOrder(_orderID);

        (bytes32 buyID, bytes32 sellID) = orderIsBuy ?
            (_orderID, matchedID) : (matchedID, _orderID);

        SettlementDetails memory settlementDetails = calculateSettlementDetails(
            buyID,
            sellID,
            getTokenDetails(orderDetails[buyID].tokens)
        );

        return (
            orderStatus[_orderID] == OrderStatus.Settled || orderStatus[_orderID] == OrderStatus.Slashed,
            orderIsBuy,
            matchedID,
            settlementDetails.leftVolume,
            settlementDetails.rightVolume,
            settlementDetails.leftTokenFee,
            settlementDetails.rightTokenFee,
            uint32(orderDetails[buyID].tokens >> 32),
            uint32(orderDetails[buyID].tokens)
        );
    }

     
     
     
     
     
    function hashOrder(
        bytes _prefix,
        uint64 _settlementID,
        uint64 _tokens,
        uint256 _price,
        uint256 _volume,
        uint256 _minimumVolume
    ) external pure returns (bytes32) {
        return SettlementUtils.hashOrder(_prefix, SettlementUtils.OrderDetails({
            settlementID: _settlementID,
            tokens: _tokens,
            price: _price,
            volume: _volume,
            minimumVolume: _minimumVolume
        }));
    }

     
     
     
     
     
     
     
     
    function execute(
        bytes32 _buyID,
        bytes32 _sellID,
        address _buyer,
        address _seller,
        TokenPair memory _tokens
    ) private {
         
         
        SettlementDetails memory settlementDetails = (orderDetails[_buyID].settlementID == RENEX_ATOMIC_SETTLEMENT_ID) ?
            settlementDetails = calculateAtomicFees(_buyID, _sellID, _tokens) :
            settlementDetails = calculateSettlementDetails(_buyID, _sellID, _tokens);

         
        renExBalancesContract.transferBalanceWithFee(
            _buyer,
            _seller,
            settlementDetails.leftTokenAddress,
            settlementDetails.leftVolume,
            settlementDetails.leftTokenFee,
            orderSubmitter[_buyID]
        );

         
        renExBalancesContract.transferBalanceWithFee(
            _seller,
            _buyer,
            settlementDetails.rightTokenAddress,
            settlementDetails.rightVolume,
            settlementDetails.rightTokenFee,
            orderSubmitter[_sellID]
        );
    }

     
     
     
     
     
     
    function calculateSettlementDetails(
        bytes32 _buyID,
        bytes32 _sellID,
        TokenPair memory _tokens
    ) private view returns (SettlementDetails memory) {

         
         
        Fraction memory midPrice = Fraction(orderDetails[_buyID].price + orderDetails[_sellID].price, 2);

         
        uint256 commonVolume = Math.min256(orderDetails[_buyID].volume, orderDetails[_sellID].volume);

        uint256 priorityTokenVolume = joinFraction(
            commonVolume.mul(midPrice.numerator),
            midPrice.denominator,
            int16(_tokens.priorityToken.decimals) - PRICE_OFFSET - VOLUME_OFFSET
        );
        uint256 secondaryTokenVolume = joinFraction(
            commonVolume,
            1,
            int16(_tokens.secondaryToken.decimals) - VOLUME_OFFSET
        );

         
        ValueWithFees memory priorityVwF = subtractDarknodeFee(priorityTokenVolume);
        ValueWithFees memory secondaryVwF = subtractDarknodeFee(secondaryTokenVolume);

        return SettlementDetails({
            leftVolume: priorityVwF.value,
            rightVolume: secondaryVwF.value,
            leftTokenFee: priorityVwF.fees,
            rightTokenFee: secondaryVwF.fees,
            leftTokenAddress: _tokens.priorityToken.addr,
            rightTokenAddress: _tokens.secondaryToken.addr
        });
    }

     
     
     
     
     
     
    function calculateAtomicFees(
        bytes32 _buyID,
        bytes32 _sellID,
        TokenPair memory _tokens
    ) private view returns (SettlementDetails memory) {

         
         
        Fraction memory midPrice = Fraction(orderDetails[_buyID].price + orderDetails[_sellID].price, 2);

         
        uint256 commonVolume = Math.min256(orderDetails[_buyID].volume, orderDetails[_sellID].volume);

        if (isEthereumBased(_tokens.secondaryToken.addr)) {
            uint256 secondaryTokenVolume = joinFraction(
                commonVolume,
                1,
                int16(_tokens.secondaryToken.decimals) - VOLUME_OFFSET
            );

             
            ValueWithFees memory secondaryVwF = subtractDarknodeFee(secondaryTokenVolume);

            return SettlementDetails({
                leftVolume: 0,
                rightVolume: 0,
                leftTokenFee: secondaryVwF.fees,
                rightTokenFee: secondaryVwF.fees,
                leftTokenAddress: _tokens.secondaryToken.addr,
                rightTokenAddress: _tokens.secondaryToken.addr
            });
        } else if (isEthereumBased(_tokens.priorityToken.addr)) {
            uint256 priorityTokenVolume = joinFraction(
                commonVolume.mul(midPrice.numerator),
                midPrice.denominator,
                int16(_tokens.priorityToken.decimals) - PRICE_OFFSET - VOLUME_OFFSET
            );

             
            ValueWithFees memory priorityVwF = subtractDarknodeFee(priorityTokenVolume);

            return SettlementDetails({
                leftVolume: 0,
                rightVolume: 0,
                leftTokenFee: priorityVwF.fees,
                rightTokenFee: priorityVwF.fees,
                leftTokenAddress: _tokens.priorityToken.addr,
                rightTokenAddress: _tokens.priorityToken.addr
            });
        } else {
             
             
            revert("non-eth atomic swaps are not supported");
        }
    }

     
     
     
    function isBuyOrder(bytes32 _orderID) private view returns (bool) {
        uint64 tokens = orderDetails[_orderID].tokens;
        uint32 firstToken = uint32(tokens >> 32);
        uint32 secondaryToken = uint32(tokens);
        return (firstToken < secondaryToken);
    }

     
    function subtractDarknodeFee(uint256 _value) private pure returns (ValueWithFees memory) {
        uint256 newValue = (_value * (DARKNODE_FEES_DENOMINATOR - DARKNODE_FEES_NUMERATOR)) / DARKNODE_FEES_DENOMINATOR;
        return ValueWithFees(newValue, _value - newValue);
    }

     
     
     
     
     
    function getTokenDetails(uint64 _tokens) private view returns (TokenPair memory) {
        (
            address priorityAddress,
            uint8 priorityDecimals,
            bool priorityRegistered
        ) = renExTokensContract.tokens(uint32(_tokens >> 32));

        (
            address secondaryAddress,
            uint8 secondaryDecimals,
            bool secondaryRegistered
        ) = renExTokensContract.tokens(uint32(_tokens));

        return TokenPair({
            priorityToken: RenExTokens.TokenDetails(priorityAddress, priorityDecimals, priorityRegistered),
            secondaryToken: RenExTokens.TokenDetails(secondaryAddress, secondaryDecimals, secondaryRegistered)
        });
    }

     
     
    function isEthereumBased(address _tokenAddress) private pure returns (bool) {
        return (_tokenAddress != address(0x0));
    }

     
    function joinFraction(uint256 _numerator, uint256 _denominator, int16 _scale) private pure returns (uint256) {
        if (_scale >= 0) {
             
            assert(_scale <= 77);  
            return _numerator.mul(10 ** uint256(_scale)) / _denominator;
        } else {
             
             
             
             
             
            return (_numerator / _denominator) / 10 ** uint256(-_scale);
        }
    }
}