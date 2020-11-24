 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;


library ExternalCall {
     
     
     
    function externalCall(address destination, uint value, bytes memory data, uint dataOffset, uint dataLength, uint gasLimit) internal returns(bool result) {
         
        if (gasLimit == 0) {
            gasLimit = gasleft() - 40000;
        }
        assembly {
            let x := mload(0x40)    
            let d := add(data, 32)  
            result := call(
                gasLimit,
                destination,
                value,
                add(d, dataOffset),
                dataLength,         
                x,
                0                   
            )
        }
    }
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

contract IZrxExchange {

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

    struct FillResults {
        uint256 makerAssetFilledAmount;   
        uint256 takerAssetFilledAmount;   
        uint256 makerFeePaid;             
        uint256 takerFeePaid;             
    }

    function getOrderInfo(Order memory order)
        public
        view
        returns (OrderInfo memory orderInfo);

    function getOrdersInfo(Order[] memory orders)
        public
        view
        returns (OrderInfo[] memory ordersInfo);

    function fillOrder(
        Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (FillResults memory fillResults);

    function fillOrderNoThrow(
        Order memory order,
        uint256 takerAssetFillAmount,
        bytes memory signature
    )
        public
        returns (FillResults memory fillResults);
}


contract IGST2 is IERC20 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);
}


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}



contract IWETH is IERC20 {

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}



contract Shutdownable is Ownable {

    bool public isShutdown;

    event Shutdown();

    modifier notShutdown {
        require(!isShutdown, "Smart contract is shut down.");
        _;
    }

    function shutdown() public onlyOwner {
        isShutdown = true;
        emit Shutdown();
    }
}

contract IERC20NonView {
     
    function balanceOf(address user) public returns(uint256);
    function allowance(address from, address to) public returns(uint256);
}

contract ZrxMarketOrder {

    using SafeMath for uint256;

    function marketSellOrdersProportion(
        IERC20 tokenSell,
        address tokenBuy,
        address zrxExchange,
        address zrxTokenProxy,
        IZrxExchange.Order[] calldata orders,
        bytes[] calldata signatures,
        uint256 mul,
        uint256 div
    )
        external
    {
        uint256 amount = tokenSell.balanceOf(msg.sender).mul(mul).div(div);
        this.marketSellOrders(tokenBuy, zrxExchange, zrxTokenProxy, amount, orders, signatures);
    }

    function marketSellOrders(
        address makerAsset,
        address zrxExchange,
        address zrxTokenProxy,
        uint256 takerAssetFillAmount,
        IZrxExchange.Order[] calldata orders,
        bytes[] calldata signatures
    )
        external
        returns (IZrxExchange.FillResults memory totalFillResults)
    {
        for (uint i = 0; i < orders.length; i++) {

             
            if (totalFillResults.takerAssetFilledAmount >= takerAssetFillAmount) {
                break;
            }

             
            uint256 remainingTakerAmount = takerAssetFillAmount.sub(totalFillResults.takerAssetFilledAmount);

            IZrxExchange.OrderInfo memory orderInfo = IZrxExchange(zrxExchange).getOrderInfo(orders[i]);
            uint256 orderRemainingTakerAmount = orders[i].takerAssetAmount.sub(orderInfo.orderTakerAssetFilledAmount);

             
            {
                uint256 balance = IERC20NonView(makerAsset).balanceOf(orders[i].makerAddress);
                uint256 allowance = IERC20NonView(makerAsset).allowance(orders[i].makerAddress, zrxTokenProxy);
                uint256 availableMakerAmount = (allowance < balance) ? allowance : balance;
                uint256 availableTakerAmount = availableMakerAmount.mul(orders[i].takerAssetAmount).div(orders[i].makerAssetAmount);

                if (availableTakerAmount < orderRemainingTakerAmount) {
                    orderRemainingTakerAmount = availableTakerAmount;
                }
            }

            uint256 takerAmount = (orderRemainingTakerAmount < remainingTakerAmount) ? orderRemainingTakerAmount : remainingTakerAmount;

            IZrxExchange.FillResults memory fillResults = IZrxExchange(zrxExchange).fillOrderNoThrow(
                orders[i],
                takerAmount,
                signatures[i]
            );

            _addFillResults(totalFillResults, fillResults);
        }

        return totalFillResults;
    }

    function _addFillResults(
        IZrxExchange.FillResults memory totalFillResults,
        IZrxExchange.FillResults memory singleFillResults
    )
        internal
        pure
    {
        totalFillResults.makerAssetFilledAmount = totalFillResults.makerAssetFilledAmount.add(singleFillResults.makerAssetFilledAmount);
        totalFillResults.takerAssetFilledAmount = totalFillResults.takerAssetFilledAmount.add(singleFillResults.takerAssetFilledAmount);
        totalFillResults.makerFeePaid = totalFillResults.makerFeePaid.add(singleFillResults.makerFeePaid);
        totalFillResults.takerFeePaid = totalFillResults.takerFeePaid.add(singleFillResults.takerFeePaid);
    }

    function getOrdersInfoRespectingBalancesAndAllowances(
        IERC20 token,
        IZrxExchange zrx,
        address zrxTokenProxy,
        IZrxExchange.Order[] memory orders
    )
        public
        view
        returns (IZrxExchange.OrderInfo[] memory ordersInfo)
    {
        ordersInfo = zrx.getOrdersInfo(orders);

        for (uint i = 0; i < ordersInfo.length; i++) {

            uint256 balance = token.balanceOf(orders[i].makerAddress);
            uint256 allowance = token.allowance(orders[i].makerAddress, zrxTokenProxy);
            uint256 availableMakerAmount = (allowance < balance) ? allowance : balance;
            uint256 availableTakerAmount = availableMakerAmount.mul(orders[i].takerAssetAmount).div(orders[i].makerAssetAmount);

            for (uint j = 0; j < i; j++) {

                if (orders[j].makerAddress == orders[i].makerAddress) {

                    uint256 orderTakerAssetRemainigAmount = orders[j].takerAssetAmount.sub(
                        ordersInfo[j].orderTakerAssetFilledAmount
                    );

                    if (availableTakerAmount > orderTakerAssetRemainigAmount) {

                        availableTakerAmount = availableTakerAmount.sub(orderTakerAssetRemainigAmount);
                    } else {

                        availableTakerAmount = 0;
                        break;
                    }
                }
            }

            uint256 remainingTakerAmount = orders[i].takerAssetAmount.sub(
                ordersInfo[i].orderTakerAssetFilledAmount
            );

            if (availableTakerAmount < remainingTakerAmount) {

                ordersInfo[i].orderTakerAssetFilledAmount = orders[i].takerAssetAmount.sub(availableTakerAmount);
            }
        }
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





library UniversalERC20 {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 private constant ZERO_ADDRESS = IERC20(0x0000000000000000000000000000000000000000);
    IERC20 private constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    function universalTransfer(IERC20 token, address to, uint256 amount) internal {
        universalTransfer(token, to, amount, false);
    }

    function universalTransfer(IERC20 token, address to, uint256 amount, bool mayFail) internal returns(bool) {
        if (amount == 0) {
            return true;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            if (mayFail) {
                return address(uint160(to)).send(amount);
            } else {
                address(uint160(to)).transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function universalApprove(IERC20 token, address to, uint256 amount) internal {
        if (token != ZERO_ADDRESS && token != ETH_ADDRESS) {
            token.safeApprove(to, amount);
        }
    }

    function universalTransferFrom(IERC20 token, address from, address to, uint256 amount) internal {
        if (amount == 0) {
            return;
        }

        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            require(from == msg.sender && msg.value >= amount, "msg.value is zero");
            if (to != address(this)) {
                address(uint160(to)).transfer(amount);
            }
            if (msg.value > amount) {
                msg.sender.transfer(msg.value.sub(amount));
            }
        } else {
            token.safeTransferFrom(from, to, amount);
        }
    }

    function universalBalanceOf(IERC20 token, address who) internal view returns (uint256) {
        if (token == ZERO_ADDRESS || token == ETH_ADDRESS) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }
}



contract TokenSpender {

    using SafeERC20 for IERC20;

    address public owner;
    IGST2 public gasToken;
    address public gasTokenOwner;

    constructor(IGST2 _gasToken, address _gasTokenOwner) public {
        owner = msg.sender;
        gasToken = _gasToken;
        gasTokenOwner = _gasTokenOwner;
    }

    function claimTokens(IERC20 token, address who, address dest, uint256 amount) external {
        require(msg.sender == owner, "Access restricted");
        token.safeTransferFrom(who, dest, amount);
    }

    function burnGasToken(uint gasSpent) external {
        require(msg.sender == owner, "Access restricted");
        uint256 tokens = (gasSpent + 14154) / 41130;
        gasToken.freeUpTo(tokens);
    }

    function() external {
        if (msg.sender == gasTokenOwner) {
            gasToken.transfer(msg.sender, gasToken.balanceOf(address(this)));
        }
    }
}

contract OneInchExchange is Shutdownable, ZrxMarketOrder {

    using SafeMath for uint256;
    using UniversalERC20 for IERC20;
    using ExternalCall for address;

    IERC20 constant ETH_ADDRESS = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

    TokenSpender public spender;
    uint fee;  

    event History(
        address indexed sender,
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromAmount,
        uint256 toAmount
    );

    event Swapped(
        IERC20 indexed fromToken,
        IERC20 indexed toToken,
        address indexed referrer,
        uint256 fromAmount,
        uint256 toAmount,
        uint256 referrerFee,
        uint256 fee
    );

    constructor(address _owner, IGST2 _gasToken, uint _fee) public {
        spender = new TokenSpender(
            _gasToken,
            _owner
        );

        _transferOwnership(_owner);
        fee = _fee;
    }

    function() external payable notShutdown {
        require(msg.sender != tx.origin);
    }

    function swap(
        IERC20 fromToken,
        IERC20 toToken,
        uint256 fromTokenAmount,
        uint256 minReturnAmount,
        uint256 guaranteedAmount,
        address payable referrer,
        address[] memory callAddresses,
        bytes memory callDataConcat,
        uint256[] memory starts,
        uint256[] memory gasLimitsAndValues
    )
    public
    payable
    notShutdown
    returns (uint256 returnAmount)
    {
        uint256 gasProvided = gasleft();

        require(minReturnAmount > 0, "Min return should be bigger then 0.");
        require(callAddresses.length > 0, "Call data should exists.");

        if (fromToken != ETH_ADDRESS) {
            spender.claimTokens(fromToken, msg.sender, address(this), fromTokenAmount);
        }

        for (uint i = 0; i < callAddresses.length; i++) {
            require(callAddresses[i] != address(spender), "Access denied");
            require(callAddresses[i].externalCall(
                gasLimitsAndValues[i] & ((1 << 128) - 1),
                callDataConcat,
                starts[i],
                starts[i + 1] - starts[i],
                gasLimitsAndValues[i] >> 128
            ));
        }

         
        fromToken.universalTransfer(msg.sender, fromToken.universalBalanceOf(address(this)));

        returnAmount = toToken.universalBalanceOf(address(this));
        (uint256 toTokenAmount, uint256 referrerFee) = _handleFees(toToken, referrer, returnAmount, guaranteedAmount);

        require(toTokenAmount >= minReturnAmount, "Return amount is not enough");
        toToken.universalTransfer(msg.sender, toTokenAmount);

        emit History(
            msg.sender,
            fromToken,
            toToken,
            fromTokenAmount,
            toTokenAmount
        );

        emit Swapped(
            fromToken,
            toToken,
            referrer,
            fromTokenAmount,
            toTokenAmount,
            referrerFee,
            returnAmount.sub(toTokenAmount)
        );

        spender.burnGasToken(gasProvided.sub(gasleft()));
    }

    function _handleFees(
        IERC20 toToken,
        address referrer,
        uint256 returnAmount,
        uint256 guaranteedAmount
    )
    internal
    returns (
        uint256 toTokenAmount,
        uint256 referrerFee
    )
    {
        if (returnAmount <= guaranteedAmount) {
            return (returnAmount, 0);
        }

        uint256 feeAmount = returnAmount.sub(guaranteedAmount).mul(fee).div(10000);

        if (referrer != address(0) && referrer != msg.sender && referrer != tx.origin) {
            referrerFee = feeAmount.div(10);
            if (toToken.universalTransfer(referrer, referrerFee, true)) {
                returnAmount = returnAmount.sub(referrerFee);
                feeAmount = feeAmount.sub(referrerFee);
            } else {
                referrerFee = 0;
            }
        }

        if (toToken.universalTransfer(owner(), feeAmount, true)) {
            returnAmount = returnAmount.sub(feeAmount);
        }

        return (returnAmount, referrerFee);
    }

    function infiniteApproveIfNeeded(IERC20 token, address to) external notShutdown {
        if (token != ETH_ADDRESS) {
            if ((token.allowance(address(this), to) >> 255) == 0) {
                token.universalApprove(to, uint256(- 1));
            }
        }
    }

    function withdrawAllToken(IWETH token) external notShutdown {
        uint256 amount = token.balanceOf(address(this));
        token.withdraw(amount);
    }
}