 

pragma solidity >=0.4.22 <0.6.0;
pragma experimental ABIEncoderV2;

 
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

    function getPartialAmount(
        uint256 numerator,
        uint256 denominator,
        uint256 target
    )
        internal
        pure
        returns (uint256 partialAmount)
    {
        partialAmount = numerator.mul(target).div(denominator);
    }

    function getFeeAmount(
        uint256 numerator,
        uint256 target
    )
        internal
        pure
        returns (uint256 feeAmount)
    {
        feeAmount = numerator.mul(target).div(1 ether);  
    }
}




contract LibOrder {

    struct Order {
        uint256 makerSellAmount;
        uint256 makerBuyAmount;
        uint256 takerSellAmount;
        uint256 salt;
        uint256 expiration;
        address taker;
        address maker;
        address makerSellToken;
        address makerBuyToken;
    }

    struct OrderInfo {
        uint256 filledAmount;
        bytes32 hash;
        uint8 status;
    }

    struct OrderFill {
        uint256 makerFillAmount;
        uint256 takerFillAmount;
        uint256 takerFeePaid;
        uint256 exchangeFeeReceived;
        uint256 referralFeeReceived;
        uint256 makerFeeReceived;
    }

    enum OrderStatus {
        INVALID_SIGNER,
        INVALID_TAKER_AMOUNT,
        INVALID_MAKER_AMOUNT,
        FILLABLE,
        EXPIRED,
        FULLY_FILLED,
        CANCELLED
    }

    function getHash(Order memory order)
        public
        pure
        returns (bytes32)
    {
        return keccak256(
            abi.encodePacked(
                order.maker,
                order.makerSellToken,
                order.makerSellAmount,
                order.makerBuyToken,
                order.makerBuyAmount,
                order.salt,
                order.expiration
            )
        );
    }

    function getPrefixedHash(Order memory order)
        public
        pure
        returns (bytes32)
    {
        bytes32 orderHash = getHash(order);
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash));
    }
}




contract LibSignatureValidator   {

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

         
        if (signature.length != 65) {
            return (address(0));
        }

         
         
         
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

         
        if (v < 27) {
            v += 27;
        }

         
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
             
            return ecrecover(hash, v, r, s);
        }
    }
}




contract IKyberNetworkProxy {
    function getExpectedRate(address src, address dest, uint srcQty) public view
        returns (uint expectedRate, uint slippageRate);

    function trade(
        address src,
        uint srcAmount,
        address dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    ) public payable returns(uint256);
}




contract LibKyberData {

    struct KyberData {
        uint256 rate;
        uint256 value;
        address givenToken;
        address receivedToken;
    }
}




 
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
        require(isOwner(), "Ownable: caller is not the owner");
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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}




contract IExchangeUpgradability {

    uint8 public VERSION;

    event FundsMigrated(address indexed user, address indexed newExchange);
    
    function allowOrRestrictMigrations() external;

    function migrateFunds(address[] calldata tokens) external;

    function migrateEthers() private;

    function migrateTokens(address[] memory tokens) private;

    function importEthers(address user) external payable;

    function importTokens(address tokenAddress, uint256 tokenAmount, address user) external;

}




contract LibCrowdsale {

    using SafeMath for uint256;

    struct Crowdsale {
        uint256 startBlock;
        uint256 endBlock;
        uint256 hardCap;
        uint256 leftAmount;
        uint256 tokenRatio;
        uint256 minContribution;
        uint256 maxContribution;
        uint256 weiRaised;
        address wallet;
    }

    enum ContributionStatus {
        CROWDSALE_NOT_OPEN,
        MIN_CONTRIBUTION,
        MAX_CONTRIBUTION,
        HARDCAP_REACHED,
        VALID
    }

    enum CrowdsaleStatus {
        INVALID_START_BLOCK,
        INVALID_END_BLOCK,
        INVALID_TOKEN_RATIO,
        INVALID_LEFT_AMOUNT,
        VALID
    }

    function getCrowdsaleStatus(Crowdsale memory crowdsale)
        public
        view
        returns (CrowdsaleStatus)
    {

        if(crowdsale.startBlock < block.number) {
            return CrowdsaleStatus.INVALID_START_BLOCK;
        }

        if(crowdsale.endBlock < crowdsale.startBlock) {
            return CrowdsaleStatus.INVALID_END_BLOCK;
        }

        if(crowdsale.tokenRatio == 0) {
            return CrowdsaleStatus.INVALID_TOKEN_RATIO;
        }

        uint256 tokenForSale = crowdsale.hardCap.mul(crowdsale.tokenRatio);

        if(tokenForSale != crowdsale.leftAmount) {
            return CrowdsaleStatus.INVALID_LEFT_AMOUNT;
        }

        return CrowdsaleStatus.VALID;
    }

    function isOpened(uint256 startBlock, uint256 endBlock)
        internal
        view
        returns (bool)
    {
        return (block.number >= startBlock && block.number <= endBlock);
    }


    function isFinished(uint256 endBlock)
        internal
        view
        returns (bool)
    {
        return block.number > endBlock;
    }
}




 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function decimals() external view returns (uint8);

     
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




contract ExchangeStorage is Ownable {

     
    uint256 constant internal minMakerFeeRate = 200000000000000000;

     
    uint256 constant internal maxMakerFeeRate = 900000000000000000;

     
    uint256 constant internal minTakerFeeRate = 1000000000000000;

     
    uint256 constant internal maxTakerFeeRate = 10000000000000000;

     
    uint256 constant internal referralFeeRate = 100000000000000000;

     
    uint256 public makerFeeRate;

     
    uint256 public takerFeeRate;

     
    mapping(address => mapping(address => uint256)) internal balances;

     
    mapping(bytes32 => uint256) internal filled;

     
    mapping(bytes32 => bool) internal cancelled;

     
    mapping(address => address) internal referrals;

     
    address public feeAccount;

     
    function getBalance(
        address user,
        address token
    )
        public
        view
        returns (uint256)
    {
        return balances[token][user];
    }

     
    function getBalances(
        address user,
        address[] memory token
    )
        public
        view
        returns(uint256[] memory balanceArray)
    {
        balanceArray = new uint256[](token.length);

        for(uint256 index = 0; index < token.length; index++) {
            balanceArray[index] = balances[token[index]][user];
        }
    }

     
    function getFill(
        bytes32 orderHash
    )
        public
        view
        returns (uint256)
    {
        return filled[orderHash];
    }

     
    function getFills(
        bytes32[] memory orderHash
    )
        public
        view
        returns (uint256[] memory filledArray)
    {
        filledArray = new uint256[](orderHash.length);

        for(uint256 index = 0; index < orderHash.length; index++) {
            filledArray[index] = filled[orderHash[index]];
        }
    }

     
    function getCancel(
        bytes32 orderHash
    )
        public
        view
        returns (bool)
    {
        return cancelled[orderHash];
    }

     
    function getCancels(
        bytes32[] memory orderHash
    )
        public
        view
        returns (bool[]memory cancelledArray)
    {
        cancelledArray = new bool[](orderHash.length);

        for(uint256 index = 0; index < orderHash.length; index++) {
            cancelledArray[index] = cancelled[orderHash[index]];
        }
    }

     
    function getReferral(
        address user
    )
        public
        view
        returns (address)
    {
        return referrals[user];
    }

     
    function setMakerFeeRate(
        uint256 newMakerFeeRate
    )
        external
        onlyOwner
    {
        require(
            newMakerFeeRate >= minMakerFeeRate &&
            newMakerFeeRate <= maxMakerFeeRate,
            "INVALID_MAKER_FEE_RATE"
        );
        makerFeeRate = newMakerFeeRate;
    }

     
    function setTakerFeeRate(
        uint256 newTakerFeeRate
    )
        external
        onlyOwner
    {
        require(
            newTakerFeeRate >= minTakerFeeRate &&
            newTakerFeeRate <= maxTakerFeeRate,
            "INVALID_TAKER_FEE_RATE"
        );

        takerFeeRate = newTakerFeeRate;
    }

     
    function setFeeAccount(
        address newFeeAccount
    )
        external
        onlyOwner
    {
        feeAccount = newFeeAccount;
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




contract Exchange is LibMath, LibOrder, LibSignatureValidator, ExchangeStorage {

    using SafeMath for uint256;

     
    event Trade(
        address indexed makerAddress,         
        address indexed takerAddress,         
        bytes32 indexed orderHash,            
        address makerFilledAsset,             
        address takerFilledAsset,             
        uint256 makerFilledAmount,            
        uint256 takerFilledAmount,            
        uint256 takerFeePaid,                 
        uint256 makerFeeReceived,             
        uint256 referralFeeReceived           
    );

     
    event Cancel(
        address indexed makerBuyToken,         
        address makerSellToken,                
        address indexed maker,                 
        bytes32 indexed orderHash              
    );

     
    function getOrderInfo(
        uint256 partialAmount,
        Order memory order
    )
        public
        view
        returns (OrderInfo memory orderInfo)
    {
         
        orderInfo.hash = getPrefixedHash(order);

         
        orderInfo.filledAmount = filled[orderInfo.hash];

         
        if(balances[order.makerBuyToken][order.taker] < order.takerSellAmount) {
            orderInfo.status = uint8(OrderStatus.INVALID_TAKER_AMOUNT);
            return orderInfo;
        }

         
        if(balances[order.makerSellToken][order.maker] < partialAmount) {
            orderInfo.status = uint8(OrderStatus.INVALID_MAKER_AMOUNT);
            return orderInfo;
        }

         
        if (orderInfo.filledAmount.add(order.takerSellAmount) > order.makerBuyAmount) {
            orderInfo.status = uint8(OrderStatus.FULLY_FILLED);
            return orderInfo;
        }

         
        if (block.number >= order.expiration) {
            orderInfo.status = uint8(OrderStatus.EXPIRED);
            return orderInfo;
        }

         
        if (cancelled[orderInfo.hash]) {
            orderInfo.status = uint8(OrderStatus.CANCELLED);
            return orderInfo;
        }

        orderInfo.status = uint8(OrderStatus.FILLABLE);
        return orderInfo;
    }

     
    function trade(
        Order memory order,
        bytes memory signature
    )
        public
    {
        bool result = _trade(order, signature);
        require(result, "INVALID_TRADE");
    }

     
    function _trade(
        Order memory order,
        bytes memory signature
    )
        internal
        returns(bool)
    {
        order.taker = msg.sender;

        uint256 takerReceivedAmount = getPartialAmount(
            order.makerSellAmount,
            order.makerBuyAmount,
            order.takerSellAmount
        );

        OrderInfo memory orderInfo = getOrderInfo(takerReceivedAmount, order);

        uint8 status = assertTakeOrder(orderInfo.hash, orderInfo.status, order.maker, signature);

        if(status != uint8(OrderStatus.FILLABLE)) {
            return false;
        }

        OrderFill memory orderFill = getOrderFillResult(takerReceivedAmount, order);

        executeTrade(order, orderFill);

        filled[orderInfo.hash] = filled[orderInfo.hash].add(order.takerSellAmount);

        emit Trade(
            order.maker,
            order.taker,
            orderInfo.hash,
            order.makerBuyToken,
            order.makerSellToken,
            orderFill.makerFillAmount,
            orderFill.takerFillAmount,
            orderFill.takerFeePaid,
            orderFill.makerFeeReceived,
            orderFill.referralFeeReceived
        );

        return true;
    }

     
    function cancelSingleOrder(
        Order memory order,
        bytes memory signature
    )
        public
    {
        bytes32 orderHash = getPrefixedHash(order);

        require(
            recover(orderHash, signature) == msg.sender,
            "INVALID_SIGNER"
        );

        require(
            cancelled[orderHash] == false,
            "ALREADY_CANCELLED"
        );

        cancelled[orderHash] = true;

        emit Cancel(
            order.makerBuyToken,
            order.makerSellToken,
            msg.sender,
            orderHash
        );
    }

     
    function getOrderFillResult(
        uint256 takerReceivedAmount,
        Order memory order
    )
        internal
        view
        returns (OrderFill memory orderFill)
    {
        orderFill.takerFillAmount = takerReceivedAmount;

        orderFill.makerFillAmount = order.takerSellAmount;

         
        orderFill.takerFeePaid = getFeeAmount(
            takerReceivedAmount,
            takerFeeRate
        );

         
        orderFill.makerFeeReceived = getFeeAmount(
            orderFill.takerFeePaid,
            makerFeeRate
        );

         
        orderFill.referralFeeReceived = getFeeAmount(
            orderFill.takerFeePaid,
            referralFeeRate
        );

         
        orderFill.exchangeFeeReceived = orderFill.takerFeePaid.sub(
            orderFill.makerFeeReceived).sub(
                orderFill.referralFeeReceived);

    }

     
    function assertTakeOrder(
        bytes32 orderHash,
        uint8 status,
        address signer,
        bytes memory signature
    )
        internal
        pure
        returns(uint8)
    {
        uint8 result = uint8(OrderStatus.FILLABLE);

        if(recover(orderHash, signature) != signer) {
            result = uint8(OrderStatus.INVALID_SIGNER);
        }

        if(status != uint8(OrderStatus.FILLABLE)) {
            result = status;
        }

        return status;
    }

     
    function executeTrade(
        Order memory order,
        OrderFill memory orderFill
    )
        private
    {
        uint256 makerGiveAmount = orderFill.takerFillAmount.sub(orderFill.makerFeeReceived);
        uint256 takerFillAmount = orderFill.takerFillAmount.sub(orderFill.takerFeePaid);

        address referrer = referrals[order.taker];
        address feeAddress = feeAccount;

        balances[order.makerSellToken][referrer] = balances[order.makerSellToken][referrer].add(orderFill.referralFeeReceived);
        balances[order.makerSellToken][feeAddress] = balances[order.makerSellToken][feeAddress].add(orderFill.exchangeFeeReceived);

        balances[order.makerBuyToken][order.taker] = balances[order.makerBuyToken][order.taker].sub(orderFill.makerFillAmount);
        balances[order.makerBuyToken][order.maker] = balances[order.makerBuyToken][order.maker].add(orderFill.makerFillAmount);

        balances[order.makerSellToken][order.taker] = balances[order.makerSellToken][order.taker].add(takerFillAmount);
        balances[order.makerSellToken][order.maker] = balances[order.makerSellToken][order.maker].sub(makerGiveAmount);
    }
}




contract ExchangeKyberProxy is Exchange, LibKyberData {
    using SafeERC20 for IERC20;

     
    uint256 constant internal PRECISION = 1000000000000000000;

     
    uint256 constant internal MAX_DECIMALS = 18;

     
    uint256 constant internal ETH_DECIMALS = 18;

     
    address constant internal KYBER_ETH_TOKEN_ADDRESS =
        address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    uint256 constant internal MAX_DEST_AMOUNT = 2**256 - 1;

     
    IKyberNetworkProxy constant internal kyberNetworkContract =
        IKyberNetworkProxy(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

     
    function kyberSwap(
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        bytes32 hash
    )
        public
        payable
    {
        address taker = msg.sender;

        KyberData memory kyberData = getSwapInfo(
            givenAmount,
            givenToken,
            receivedToken,
            taker
        );

        uint256 convertedAmount = kyberNetworkContract.trade.value(kyberData.value)(
            kyberData.givenToken,
            givenAmount,
            kyberData.receivedToken,
            taker,
            MAX_DEST_AMOUNT,
            kyberData.rate,
            feeAccount
        );

        emit Trade(
            address(kyberNetworkContract),
            taker,
            hash,
            givenToken,
            receivedToken,
            givenAmount,
            convertedAmount,
            0,
            0,
            0
        );
    }

     
    function kyberTrade(
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        bytes32 hash
    )
        public
    {
        address taker = msg.sender;

        KyberData memory kyberData = getTradeInfo(
            givenAmount,
            givenToken,
            receivedToken
        );

        balances[givenToken][taker] = balances[givenToken][taker].sub(givenAmount);

        uint256 convertedAmount = kyberNetworkContract.trade.value(kyberData.value)(
            kyberData.givenToken,
            givenAmount,
            kyberData.receivedToken,
            address(this),
            MAX_DEST_AMOUNT,
            kyberData.rate,
            feeAccount
        );

        balances[receivedToken][taker] = balances[receivedToken][taker].add(convertedAmount);

        emit Trade(
            address(kyberNetworkContract),
            taker,
            hash,
            givenToken,
            receivedToken,
            givenAmount,
            convertedAmount,
            0,
            0,
            0
        );
    }

     
    function getSwapInfo(
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        address taker
    )
        private
        returns(KyberData memory)
    {
        KyberData memory kyberData;
        uint256 givenTokenDecimals;
        uint256 receivedTokenDecimals;

        if(givenToken == address(0x0)) {
            require(msg.value == givenAmount, "INVALID_ETH_VALUE");

            kyberData.givenToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.receivedToken = receivedToken;
            kyberData.value = givenAmount;

            givenTokenDecimals = ETH_DECIMALS;
            receivedTokenDecimals = IERC20(receivedToken).decimals();
        } else if(receivedToken == address(0x0)) {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = ETH_DECIMALS;

            IERC20(givenToken).safeTransferFrom(taker, address(this), givenAmount);
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        } else {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = receivedToken;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = IERC20(receivedToken).decimals();

            IERC20(givenToken).safeTransferFrom(taker, address(this), givenAmount);
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        }

        (kyberData.rate, ) = kyberNetworkContract.getExpectedRate(
            kyberData.givenToken,
            kyberData.receivedToken,
            givenAmount
        );

        return kyberData;
    }

     
    function getTradeInfo(
        uint256 givenAmount,
        address givenToken,
        address receivedToken
    )
        private
        returns(KyberData memory)
    {
        KyberData memory kyberData;
        uint256 givenTokenDecimals;
        uint256 receivedTokenDecimals;

        if(givenToken == address(0x0)) {
            kyberData.givenToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.receivedToken = receivedToken;
            kyberData.value = givenAmount;

            givenTokenDecimals = ETH_DECIMALS;
            receivedTokenDecimals = IERC20(receivedToken).decimals();
        } else if(receivedToken == address(0x0)) {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = KYBER_ETH_TOKEN_ADDRESS;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = ETH_DECIMALS;
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        } else {
            kyberData.givenToken = givenToken;
            kyberData.receivedToken = receivedToken;
            kyberData.value = 0;

            givenTokenDecimals = IERC20(givenToken).decimals();
            receivedTokenDecimals = IERC20(receivedToken).decimals();
            IERC20(givenToken).safeApprove(address(kyberNetworkContract), givenAmount);
        }

        (kyberData.rate, ) = kyberNetworkContract.getExpectedRate(
            kyberData.givenToken,
            kyberData.receivedToken,
            givenAmount
        );

        return kyberData;
    }

    function getExpectedRateBatch(
        address[] memory givenTokens,
        address[] memory receivedTokens,
        uint256[] memory givenAmounts
    )
        public
        view
        returns(uint256[] memory, uint256[] memory)
    {
        uint256 size = givenTokens.length;
        uint256[] memory expectedRates = new uint256[](size);
        uint256[] memory slippageRates = new uint256[](size);

        for(uint256 index = 0; index < size; index++) {
            (expectedRates[index], slippageRates[index]) = kyberNetworkContract.getExpectedRate(
                givenTokens[index],
                receivedTokens[index],
                givenAmounts[index]
            );
        }

       return (expectedRates, slippageRates);
    }
}




contract ExchangeBatchTrade is Exchange {

     
    function cancelMultipleOrders(
        Order[] memory orders,
        bytes[] memory signatures
    )
        public
    {
        for (uint256 index = 0; index < orders.length; index++) {
            cancelSingleOrder(
                orders[index],
                signatures[index]
            );
        }
    }

     
    function takeAllOrRevert(
        Order[] memory orders,
        bytes[] memory signatures
    )
        public
    {
        for (uint256 index = 0; index < orders.length; index++) {
            bool result = _trade(orders[index], signatures[index]);
            require(result, "INVALID_TAKEALL");
        }
    }

     
    function takeAllPossible(
        Order[] memory orders,
        bytes[] memory signatures
    )
        public
    {
        for (uint256 index = 0; index < orders.length; index++) {
            _trade(orders[index], signatures[index]);
        }
    }
}




contract ExchangeMovements is ExchangeStorage {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

     
    event Deposit(
        address indexed token,
        address indexed user,
        address indexed referral,
        address beneficiary,
        uint256 amount,
        uint256 balance
    );

     
    event Withdraw(
        address indexed token,
        address indexed user,
        uint256 amount,
        uint256 balance
    );

     
    event Transfer(
        address indexed token,
        address indexed user,
        address indexed beneficiary,
        uint256 amount,
        uint256 userBalance,
        uint256 beneficiaryBalance
    );

     
    function deposit(
        address token,
        uint256 amount,
        address beneficiary,
        address referral
    )
        public
        payable
    {
        uint256 value = amount;
        address user = msg.sender;

        if(token == address(0x0)) {
            value = msg.value;
        } else {
            IERC20(token).safeTransferFrom(user, address(this), value);
        }

        balances[token][beneficiary] = balances[token][beneficiary].add(value);

        if(referrals[user] == address(0x0)) {
            referrals[user] = referral;
        }

        emit Deposit(
            token,
            user,
            referrals[user],
            beneficiary,
            value,
            balances[token][beneficiary]
        );
    }

     
    function withdraw(
        address token,
        uint amount
    )
        public
    {
        address payable user = msg.sender;

        require(
            balances[token][user] >= amount,
            "INVALID_WITHDRAW"
        );

        balances[token][user] = balances[token][user].sub(amount);

        if (token == address(0x0)) {
            user.transfer(amount);
        } else {
            IERC20(token).safeTransfer(user, amount);
        }

        emit Withdraw(
            token,
            user,
            amount,
            balances[token][user]
        );
    }

     
    function transfer(
        address token,
        address to,
        uint256 amount
    )
        external
        payable
    {
        address user = msg.sender;

        require(
            balances[token][user] >= amount,
            "INVALID_TRANSFER"
        );

        balances[token][user] = balances[token][user].sub(amount);

        balances[token][to] = balances[token][to].add(amount);

        emit Transfer(
            token,
            user,
            to,
            amount,
            balances[token][user],
            balances[token][to]
        );
    }
}




contract ExchangeUpgradability is Ownable, ExchangeStorage {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

     
    uint8 constant public VERSION = 1;

     
    address public newExchange;

     
    bool public migrationAllowed;

     
    event FundsMigrated(address indexed user, address indexed newExchange);

     
    function setNewExchangeAddress(address exchange)
        external
        onlyOwner
    {
        newExchange = exchange;
    }

     
    function allowOrRestrictMigrations()
        external
        onlyOwner
    {
        migrationAllowed = !migrationAllowed;
    }

     
    function migrateFunds(address[] calldata tokens) external {

        require(
            false != migrationAllowed,
            "MIGRATIONS_DISALLOWED"
        );

        require(
            IExchangeUpgradability(newExchange).VERSION() > VERSION,
            "INVALID_VERSION"
        );

        migrateEthers();

        migrateTokens(tokens);

        emit FundsMigrated(msg.sender, newExchange);
    }

     
    function migrateEthers() private {
        address user = msg.sender;
        uint256 etherAmount = balances[address(0x0)][user];
        if (etherAmount > 0) {
            balances[address(0x0)][user] = 0;
            IExchangeUpgradability(newExchange).importEthers.value(etherAmount)(user);
        }
    }

     
    function migrateTokens(address[] memory tokens) private {
        address user = msg.sender;
        address exchange = newExchange;
        for (uint256 index = 0; index < tokens.length; index++) {

            address tokenAddress = tokens[index];

            uint256 tokenAmount = balances[tokenAddress][user];

            if (0 == tokenAmount) {
                continue;
            }

            IERC20(tokenAddress).safeApprove(exchange, tokenAmount);

            balances[tokenAddress][user] = 0;

            IExchangeUpgradability(exchange).importTokens(tokenAddress, tokenAmount, user);
        }
    }

     
    function importEthers(address user)
        external
        payable
    {
        require(
            false != migrationAllowed,
            "MIGRATION_DISALLOWED"
        );

        require(
            user != address(0x0),
            "INVALID_USER"
        );

        require(
            msg.value > 0,
            "INVALID_AMOUNT"
        );

        require(
            IExchangeUpgradability(msg.sender).VERSION() < VERSION,
            "INVALID_VERSION"
        );

        balances[address(0x0)][user] = balances[address(0x0)][user].add(msg.value);  
    }
    
     
    function importTokens(
        address token,
        uint256 amount,
        address user
    )
        external
    {
        require(
            false != migrationAllowed,
            "MIGRATION_DISALLOWED"
        );

        require(
            token != address(0x0),
            "INVALID_TOKEN"
        );

        require(
            user != address(0x0),
            "INVALID_USER"
        );

        require(
            amount > 0,
            "INVALID_AMOUNT"
        );

        require(
            IExchangeUpgradability(msg.sender).VERSION() < VERSION,
            "INVALID_VERSION"
        );

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        balances[token][user] = balances[token][user].add(amount);
    }
}




contract ExchangeOffering is ExchangeStorage, LibCrowdsale {

    address constant internal BURN_ADDRESS = address(0x000000000000000000000000000000000000dEaD);
    address constant internal ETH_ADDRESS = address(0x0);

    using SafeERC20 for IERC20;

    using SafeMath for uint256;

    mapping(address => Crowdsale) public crowdsales;

    mapping(address => mapping(address => uint256)) public contributions;

    event TokenPurchase(
        address indexed token,
        address indexed user,
        uint256 tokenAmount,
        uint256 weiAmount
    );

    event TokenBurned(
        address indexed token,
        uint256 tokenAmount
    );

    function registerCrowdsale(
        Crowdsale memory crowdsale,
        address token
    )
        public
        onlyOwner
    {
        require(
            CrowdsaleStatus.VALID == getCrowdsaleStatus(crowdsale),
            "INVALID_CROWDSALE"
        );

        require(
            crowdsales[token].wallet == address(0),
            "CROWDSALE_ALREADY_EXISTS"
        );

        uint256 tokenForSale = crowdsale.hardCap.mul(crowdsale.tokenRatio);

        IERC20(token).safeTransferFrom(crowdsale.wallet, address(this), tokenForSale);

        crowdsales[token] = crowdsale;
    }

    function buyTokens(address token)
       public
       payable
    {
        require(msg.value != 0, "INVALID_MSG_VALUE");

        uint256 weiAmount = msg.value;

        address user = msg.sender;

        Crowdsale memory crowdsale = crowdsales[token];

        require(
            ContributionStatus.VALID == validContribution(weiAmount, crowdsale, user, token),
            "INVALID_CONTRIBUTION"
        );

        uint256 purchasedTokens = weiAmount.mul(crowdsale.tokenRatio);

        crowdsale.leftAmount = crowdsale.leftAmount.sub(purchasedTokens);

        crowdsale.weiRaised = crowdsale.weiRaised.add(weiAmount);

        balances[ETH_ADDRESS][crowdsale.wallet] = balances[ETH_ADDRESS][crowdsale.wallet].add(weiAmount);

        balances[token][user] = balances[token][user].add(purchasedTokens);

        contributions[token][user] = contributions[token][user].add(weiAmount);

        crowdsales[token] = crowdsale;

        emit TokenPurchase(token, user, purchasedTokens, weiAmount);
    }

    function burnTokensWhenFinished(address token) public
    {
        require(
            isFinished(crowdsales[token].endBlock),
            "CROWDSALE_NOT_FINISHED_YET"
        );

        uint256 leftAmount = crowdsales[token].leftAmount;

        crowdsales[token].leftAmount = 0;

        IERC20(token).safeTransfer(BURN_ADDRESS, leftAmount);

        emit TokenBurned(token, leftAmount);
    }

    function validContribution(
        uint256 weiAmount,
        Crowdsale memory crowdsale,
        address user,
        address token
    )
        public
        view
        returns(ContributionStatus)
    {
        if (!isOpened(crowdsale.startBlock, crowdsale.endBlock)) {
            return ContributionStatus.CROWDSALE_NOT_OPEN;
        }

        if(weiAmount < crowdsale.minContribution) {
            return ContributionStatus.MIN_CONTRIBUTION;
        }

        if (contributions[token][user].add(weiAmount) > crowdsale.maxContribution) {
            return ContributionStatus.MAX_CONTRIBUTION;
        }

        if (crowdsale.hardCap < crowdsale.weiRaised.add(weiAmount)) {
            return ContributionStatus.HARDCAP_REACHED;
        }

        return ContributionStatus.VALID;
    }
}




contract ExchangeSwap is Exchange, ExchangeMovements  {

     
    function swapFill(
        Order[] memory orders,
        bytes[] memory signatures,
        uint256 givenAmount,
        address givenToken,
        address receivedToken,
        address referral
    )
        public
        payable
    {
        address taker = msg.sender;

        uint256 balanceGivenBefore = balances[givenToken][taker];
        uint256 balanceReceivedBefore = balances[receivedToken][taker];

        deposit(givenToken, givenAmount, taker, referral);

        for (uint256 index = 0; index < orders.length; index++) {
            require(orders[index].makerBuyToken == givenToken, "GIVEN_TOKEN");
            require(orders[index].makerSellToken == receivedToken, "RECEIVED_TOKEN");

            _trade(orders[index], signatures[index]);
        }

        uint256 balanceGivenAfter = balances[givenToken][taker];
        uint256 balanceReceivedAfter = balances[receivedToken][taker];

        uint256 balanceGivenDelta = balanceGivenAfter.sub(balanceGivenBefore);
        uint256 balanceReceivedDelta = balanceReceivedAfter.sub(balanceReceivedBefore);

        if(balanceGivenDelta > 0) {
            withdraw(givenToken, balanceGivenDelta);
        }

        if(balanceReceivedDelta > 0) {
            withdraw(receivedToken, balanceReceivedDelta);
        }
    }
}




contract WeiDex is
    Exchange,
    ExchangeKyberProxy,
    ExchangeBatchTrade,
    ExchangeMovements,
    ExchangeUpgradability,
    ExchangeOffering,
    ExchangeSwap
{
    function () external payable { }
}