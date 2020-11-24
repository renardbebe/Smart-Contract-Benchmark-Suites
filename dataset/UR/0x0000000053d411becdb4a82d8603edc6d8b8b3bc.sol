 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface IGST2 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);
}

 
contract LibConstants {

     

     

     
     
     

     
     
    bytes constant public ZRX_ASSET_DATA = "\xf4\x72\x61\xb0\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\xe4\x1d\x24\x89\x57\x1d\x32\x21\x89\x24\x6d\xaf\xa5\xeb\xde\x1f\x46\x99\xf4\x98";
}
 

contract LibFillResults
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
}

contract LibOrder
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

contract IAssetProxyDispatcher {

     
     
     
    function registerAssetProxy(address assetProxy)
        external;

     
     
     
    function getAssetProxy(bytes4 assetProxyId)
        external
        view
        returns (address);
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

 
contract IZrxExchange is
    IExchangeCore,
    IMatchOrders,
    IAssetProxyDispatcher,
    IWrapperFunctions
{}



library ExternalCall {
     
     
     
    function externalCall(address destination, uint value, bytes memory data, uint dataOffset, uint dataLength) internal returns(bool result) {
         
        assembly {
            let x := mload(0x40)    
            let d := add(data, 32)  
            result := call(
                sub(gas, 34710),    
                                    
                                    
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


 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
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



contract IWETH is IERC20 {

    function deposit() external payable;

    function withdraw(uint256 amount) external;
}



contract TokenSpender is Ownable {

    using SafeERC20 for IERC20;

    function claimTokens(IERC20 token, address who, address dest, uint256 amount) external onlyOwner {
        token.safeTransferFrom(who, dest, amount);
    }

}




contract AggregatedTokenSwap {

    using SafeERC20 for IERC20;
    using SafeMath for uint;
    using ExternalCall for address;

    address constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    TokenSpender public spender;
    IGST2 gasToken;
    address payable owner;
    uint fee;  

    event OneInchFeePaid(
        IERC20 indexed toToken,
        address indexed referrer,
        uint256 fee
    );

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    constructor(
        address payable _owner,
        IGST2 _gasToken,
        uint _fee
    )
    public
    {
        spender = new TokenSpender();
        owner = _owner;
        gasToken = _gasToken;
        fee = _fee;
    }

    function setFee(uint _fee) public onlyOwner {

        require(_fee <= 20, "Fee should not exceed 0.2%");  
        fee = _fee;
    }

    function aggregate(
        IERC20 fromToken,
        IERC20 toToken,
        uint tokensAmount,
        address[] memory callAddresses,
        bytes memory callDataConcat,
        uint[] memory starts,
        uint[] memory values,
        uint mintGasPrice,
        uint minTokensAmount,
        address payable referrer
    )
    public
    payable
    returns (uint returnAmount)
    {
        returnAmount = gasleft();
        uint gasTokenBalance = gasToken.balanceOf(address(this));

        require(callAddresses.length + 1 == starts.length);

        if (address(fromToken) != ETH_ADDRESS) {

            spender.claimTokens(fromToken, msg.sender, address(this), tokensAmount);
        }

        for (uint i = 0; i < starts.length - 1; i++) {

            if (starts[i + 1] - starts[i] > 0) {

                require(
                    callDataConcat[starts[i] + 0] != spender.claimTokens.selector[0] ||
                    callDataConcat[starts[i] + 1] != spender.claimTokens.selector[1] ||
                    callDataConcat[starts[i] + 2] != spender.claimTokens.selector[2] ||
                    callDataConcat[starts[i] + 3] != spender.claimTokens.selector[3]
                );
                require(callAddresses[i].externalCall(values[i], callDataConcat, starts[i], starts[i + 1] - starts[i]));
            }
        }

        require(_balanceOf(toToken, address(this)) >= minTokensAmount);

         

        require(gasTokenBalance == gasToken.balanceOf(address(this)));
        if (mintGasPrice > 0) {
            audoRefundGas(returnAmount, mintGasPrice);
        }

         

        returnAmount = _balanceOf(toToken, address(this)) * fee / 10000;
        if (referrer != address(0)) {
            returnAmount /= 2;
            if (!_transfer(toToken, referrer, returnAmount, true)) {
                returnAmount *= 2;
                emit OneInchFeePaid(toToken, address(0), returnAmount);
            } else {
                emit OneInchFeePaid(toToken, referrer, returnAmount / 2);
            }
        }

        _transfer(toToken, owner, returnAmount, false);

        returnAmount = _balanceOf(toToken, address(this));
        _transfer(toToken, msg.sender, returnAmount, false);
    }

    function infiniteApproveIfNeeded(IERC20 token, address to) external {
        if (
            address(token) != ETH_ADDRESS &&
            token.allowance(address(this), to) == 0
        ) {
            token.safeApprove(to, uint256(-1));
        }
    }

    function withdrawAllToken(IWETH token) external {
        uint256 amount = token.balanceOf(address(this));
        token.withdraw(amount);
    }

    function marketSellOrders(
        IERC20 token,
        IZrxExchange zrxExchange,
        LibOrder.Order[] calldata orders,
        bytes[] calldata signatures,
        uint256 mul,
        uint256 div
    )
    external
    {
        uint256 amount = token.balanceOf(address(this)).mul(mul).div(div);
        zrxExchange.marketSellOrders(orders, amount, signatures);
    }

    function _balanceOf(IERC20 token, address who) internal view returns(uint256) {
        if (address(token) == ETH_ADDRESS || token == IERC20(0)) {
            return who.balance;
        } else {
            return token.balanceOf(who);
        }
    }

    function _transfer(IERC20 token, address payable to, uint256 amount, bool allowFail) internal returns(bool) {
        if (address(token) == ETH_ADDRESS || token == IERC20(0)) {
            if (allowFail) {
                return to.send(amount);
            } else {
                to.transfer(amount);
                return true;
            }
        } else {
            token.safeTransfer(to, amount);
            return true;
        }
    }

    function audoRefundGas(
        uint startGas,
        uint mintGasPrice
    )
    private
    returns (uint freed)
    {
        uint MINT_BASE = 32254;
        uint MINT_TOKEN = 36543;
        uint FREE_BASE = 14154;
        uint FREE_TOKEN = 6870;
        uint REIMBURSE = 24000;

        uint tokensAmount = ((startGas - gasleft()) + FREE_BASE) / (2 * REIMBURSE - FREE_TOKEN);
        uint maxReimburse = tokensAmount * REIMBURSE;

        uint mintCost = MINT_BASE + (tokensAmount * MINT_TOKEN);
        uint freeCost = FREE_BASE + (tokensAmount * FREE_TOKEN);

        uint efficiency = (maxReimburse * 100 * tx.gasprice) / (mintCost * mintGasPrice + freeCost * tx.gasprice);

        if (efficiency > 100) {

            return refundGas(
                tokensAmount
            );
        } else {

            return 0;
        }
    }

    function refundGas(
        uint tokensAmount
    )
    private
    returns (uint freed)
    {

        if (tokensAmount > 0) {

            uint safeNumTokens = 0;
            uint gas = gasleft();

            if (gas >= 27710) {
                safeNumTokens = (gas - 27710) / (1148 + 5722 + 150);
            }

            if (tokensAmount > safeNumTokens) {
                tokensAmount = safeNumTokens;
            }

            uint gasTokenBalance = IERC20(address(gasToken)).balanceOf(address(this));

            if (tokensAmount > 0 && gasTokenBalance >= tokensAmount) {

                return gasToken.freeUpTo(tokensAmount);
            } else {

                return 0;
            }
        } else {

            return 0;
        }
    }

    function() external payable {

        if (msg.value == 0 && msg.sender == owner) {

            IERC20 _gasToken = IERC20(address(gasToken));

            owner.transfer(address(this).balance);
            _gasToken.safeTransfer(owner, _gasToken.balanceOf(address(this)));
        }
    }
}