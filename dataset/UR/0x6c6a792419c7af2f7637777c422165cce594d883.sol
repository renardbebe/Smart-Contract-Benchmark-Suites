 

pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

interface IGST2 {

    function freeUpTo(uint256 value) external returns (uint256 freed);

    function freeFromUpTo(address from, uint256 value) external returns (uint256 freed);

    function balanceOf(address who) external view returns (uint256);
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



contract CompressedCaller {

    function compressedCall(
        address target,
        uint256 totalLength,
        bytes memory zipped
    )
        public
        payable
        returns (bytes memory result)
    {
        (bytes memory data, uint decompressedLength) = decompress(totalLength, zipped);
        require(decompressedLength == totalLength, "Uncompress error");

        bool success;
        (success, result) = target.call.value(msg.value)(data);
        require(success, "Decompressed call failed");
    }

    function decompress(
        uint256 totalLength,
        bytes memory zipped
    )
        public
        pure
        returns (
            bytes memory data,
            uint256 index
        )
    {
        data = new bytes(totalLength);

        for (uint i = 0; i < zipped.length; i++) {

            uint len = uint(uint8(zipped[i]) & 0x7F);

            if ((zipped[i] & 0x80) == 0) {
                memcpy(data, index, zipped, i + 1, len);
                i += len;
            }

            index += len;
        }
    }

     
     
     
     
    function memcpy(
        bytes memory destMem,
        uint dest,
        bytes memory srcMem,
        uint src,
        uint len
    )
        private
        pure
    {
        uint mask = 256 ** (32 - len % 32) - 1;

        assembly {
            dest := add(add(destMem, 32), dest)
            src := add(add(srcMem, 32), src)

             
            for { } gt(len, 31) { len := sub(len, 32) } {  
                mstore(dest, mload(src))
                dest := add(dest, 32)
                src := add(src, 32)
            }

             
            let srcPart := and(mload(src), not(mask))
            let destPart := and(mload(dest), mask)
            mstore(dest, or(destPart, srcPart))
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

contract IERC20NonView {
     
    function balanceOf(address user) public returns(uint256);
    function allowance(address from, address to) public returns(uint256);
}

contract ZrxMarketOrder {

    using SafeMath for uint256;

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

            remainingTakerAmount = remainingTakerAmount.sub(fillResults.takerAssetFilledAmount);
        }

        return totalFillResults;
    }

    function addFillResults(
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
}



contract AggregatedTokenSwap is CompressedCaller, ZrxMarketOrder {

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

        require(_fee <= 1000, "Fee should not exceed 10%");
        fee = _fee;
    }

    function aggregate(
        address payable msgSender,
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

            spender.claimTokens(fromToken, msgSender, address(this), tokensAmount);
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
        _transfer(toToken, msgSender, returnAmount, false);
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
        uint256 amount = tokenSell.balanceOf(address(this)).mul(mul).div(div);
        this.marketSellOrders(tokenBuy, zrxExchange, zrxTokenProxy, amount, orders, signatures);
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