 

 

pragma solidity 0.5.10;

 
library SafeMath {
     
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
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly {size := extcodesize(account)}
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
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0));
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
         
         

         
         
         
         

        require(address(token).isContract());

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success);

        if (returndata.length > 0) { 
            require(abi.decode(returndata, (bool)));
        }
    }
}

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract AssetsValue {
     
    using SafeMath for uint256;

     
    using SafeERC20 for IERC20;

     
     
    address internal _ethAssetIdentificator = address(0);

     
    struct OrderDetails {
         
        bool created;
         
        address asset;
         
        uint256 amount;
         
        bool withdrawn;
         
        uint256 initTimestamp;
    }

     
    struct User {
         
        bool exist;
         
        uint256 index;
         
        mapping(uint256 => uint256) orderIdByIndex;
         
        mapping(uint256 => OrderDetails) orders;
    }

     
    mapping(address => User) private _users;

    modifier orderIdNotExist(
        uint256 orderId,
        address user
    ) {
        require(_users[user].orders[orderId].created == false, "orderIdIsNotDeposited: user already deposit this orderId");
        _;
    }

     
    event AssetDeposited(uint256 orderId, address indexed user, address indexed asset, uint256 amount);
    event AssetWithdrawal(uint256 orderId, address indexed user, address indexed asset, uint256 amount);

     
     
     

    function deposit(
        uint256 orderId
    ) public orderIdNotExist(orderId, msg.sender) payable {
        require(msg.value != 0, "deposit: user needs to transfer ETH for calling this method");

        _deposit(orderId, msg.sender, _ethAssetIdentificator, msg.value);
    }

    function deposit(
        uint256 orderId,
        uint256 amount,
        address token
    ) public orderIdNotExist(orderId, msg.sender) {
        require(token != address(0), "deposit: invalid token address");
        require(amount != 0, "deposit: user needs to fill transferable tokens amount for calling this method");

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        _deposit(orderId, msg.sender, token, amount);
    }

    function withdraw(
        uint256 orderId
    ) external {
         
        require(_doesUserExist(msg.sender) == true, "withdraw: the user is not active");

         
        OrderDetails memory order = _getDepositedOrderDetails(orderId, msg.sender);
        address asset = order.asset;
        uint256 amount = order.amount;

         
        require(order.withdrawn == false, "withdraw: this order Id has been already withdrawn or waiting for the swap");

        _withdrawOrderBalance(orderId, msg.sender);

        if (asset == _ethAssetIdentificator) {
            msg.sender.transfer(amount);
        } else {
            IERC20(asset).safeTransfer(msg.sender, amount);
        }

        emit AssetWithdrawal(orderId, msg.sender, asset, amount);
    }

     
     
     

    function _deposit(
        uint256 orderId,
        address sender,
        address asset,
        uint256 amount
    ) internal {
        _activateIfUserIsNew(sender);
        _depositOrderBalance(orderId, sender, asset, amount);

        _users[sender].index += 1;

        emit AssetDeposited(orderId, sender, asset, amount);
    }

    function _doesUserExist(
        address user
    ) internal view returns (bool) {
        return _users[user].exist;
    }

    function _activateIfUserIsNew(
        address user
    ) internal returns (bool) {
        if (_doesUserExist(user) == false) {
            _users[user].exist = true;
        }
        return true;
    }

    function _getDepositedOrderDetails(
        uint256 orderId,
        address user
    ) internal view returns (OrderDetails memory order) {
        return _users[user].orders[orderId];
    }

    function _depositOrderBalance(
        uint256 orderId,
        address user,
        address asset,
        uint256 amount
    ) internal returns (bool) {
        _users[user].orderIdByIndex[_users[user].index] = orderId;
        _users[user].orders[orderId] = OrderDetails(true, asset, amount, false, block.timestamp);
        return true;
    }

    function _withdrawOrderBalance(
        uint256 orderId,
        address user
    ) internal returns (bool) {
        _users[user].orders[orderId].withdrawn = true;
        return true;
    }

     
     
     

    function doesUserExist(
        address user
    ) external view returns (bool) {
        return _doesUserExist(user);
    }

    function getUserFilledDeposits(
        address user
    ) external view returns (
        uint256[] memory orderIds,
        uint256[] memory amounts,
        uint256[] memory initTimestamps
    ) {
         
        uint256 depositsLength = _users[user].index;

         
        orderIds = new uint256[](depositsLength);
        amounts = new uint256[](depositsLength);
        initTimestamps = new uint256[](depositsLength);

        uint256 j = 0;
        for (uint256 i = 0; i <= depositsLength; i++) {
            uint256 orderId = _users[user].orderIdByIndex[i];
            if (_users[user].orders[orderId].created) {
                orderIds[j] = orderId;

                OrderDetails memory order = _users[user].orders[orderId];
                amounts[j] = order.amount;
                initTimestamps[j] = order.initTimestamp;
                j++;
            }
        }

        return (
        orderIds,
        amounts,
        initTimestamps
        );
    }

    function getUserDepositsAmount(
        address user
    ) external view returns (
        uint256
    ) {
        return _users[user].index;
    }

    function getDepositedOrderDetails(
        uint256 orderId,
        address user
    ) external view returns (
        bool created,
        address asset,
        uint256 amount,
        bool withdrawn
    ) {
        OrderDetails memory order = _getDepositedOrderDetails(orderId, user);
        return (
        order.created,
        order.asset,
        order.amount,
        order.withdrawn
        );
    }
}

 
contract CrossBlockchainSwap is AssetsValue, Ownable {
     
    enum State {Empty, Filled, Redeemed, Refunded}

     
    enum SwapType {ETH, Token}

     
    struct Swap {
        uint256 initTimestamp;
        uint256 refundTimestamp;
        bytes32 secretHash;
        bytes32 secret;
        address initiator;
        address recipient;
        address asset;
        uint256 amount;
        uint256 orderId;
        State state;
    }

    struct Initiator {
         
        uint256 index;
         
        uint256 filledSwaps;
         
        mapping(uint256 => bytes32) swaps;
    }

     
    mapping(bytes32 => Swap) private _swaps;

     
    mapping(address => Initiator) private _initiators;

     
     
    struct SwapTimeLimits {
        uint256 min;
        uint256 max;
    }

     
     
    SwapTimeLimits private _swapTimeLimits = SwapTimeLimits(10 minutes, 180 days);

     
     
     

    event Initiated(
        uint256 orderId,
        bytes32 secretHash,
        address indexed initiator,
        address indexed recipient,
        uint256 initTimestamp,
        uint256 refundTimestamp,
        address indexed asset,
        uint256 amount
    );

    event Redeemed(
        bytes32 secretHash,
        uint256 redeemTimestamp,
        bytes32 secret,
        address indexed redeemer
    );

    event Refunded(
        uint256 orderId,
        bytes32 secretHash,
        uint256 refundTime,
        address indexed refunder
    );

     
     
     

    modifier isNotInitiated(bytes32 secretHash) {
        require(_swaps[secretHash].state == State.Empty, "isNotInitiated: this secret hash was already used, please use another one");
        _;
    }

    modifier isRedeemable(bytes32 secret) {
        bytes32 secretHash = _hashTheSecret(secret);
        require(_swaps[secretHash].state == State.Filled, "isRedeemable: the swap with this secretHash does not exist or has been finished");
        uint256 refundTimestamp = _swaps[secretHash].refundTimestamp;
        require(refundTimestamp > block.timestamp, "isRedeemable: the redeem is closed for this swap");
        _;
    }

    modifier isRefundable(bytes32 secretHash, address refunder) {
        require(_swaps[secretHash].state == State.Filled, "isRefundable: the swap with this secretHash does not exist or has been finished");
        require(_swaps[secretHash].initiator == refunder, "isRefundable: only the initiator of the swap can call this method");
        uint256 refundTimestamp = _swaps[secretHash].refundTimestamp;
        require(block.timestamp >= refundTimestamp, "isRefundable: the refund is not available now");
        _;
    }

     
     
     

    function() external payable {
         
        revert();
    }

     
     
     

     
    function initiate(
        uint256 orderId,
        bytes32 secretHash,
        address recipient,
        uint256 refundTimestamp
    ) public isNotInitiated(secretHash) {
         
        _validateRefundTimestamp(refundTimestamp * 1 minutes);

        OrderDetails memory order = _getDepositedOrderDetails(orderId, msg.sender);

         
        require(order.created == true, "initiate: this order Id has not been created and deposited yet");
        require(order.withdrawn == false, "initiate: this order deposit has been withdrawn");
        require(order.amount != 0, "initiate: this order Id has been withdrawn, finished or waiting for the redeem");

         
        _withdrawOrderBalance(orderId, msg.sender);

         
        _swaps[secretHash].asset = order.asset;
        _swaps[secretHash].amount = order.amount;

         
        _swaps[secretHash].state = State.Filled;

         
        _swaps[secretHash].initiator = msg.sender;
        _swaps[secretHash].recipient = recipient;
        _swaps[secretHash].secretHash = secretHash;
        _swaps[secretHash].orderId = orderId;

         
        _swaps[secretHash].initTimestamp = block.timestamp;
        _swaps[secretHash].refundTimestamp = block.timestamp + (refundTimestamp * 1 minutes);

         
        Initiator storage initiator = _initiators[msg.sender];
        initiator.swaps[initiator.index] = secretHash;
        initiator.index++;
        initiator.filledSwaps++;

        emit Initiated(
            orderId,
            secretHash,
            msg.sender,
            recipient,
            block.timestamp,
            refundTimestamp,
            order.asset,
            order.amount
        );
    }

     
    function redeem(
        bytes32 secret
    ) external isRedeemable(secret) {
         
        bytes32 secretHash = _hashTheSecret(secret);

         
        _swaps[secretHash].state = State.Redeemed;

         
        address recipient = _swaps[secretHash].recipient;

        if (_getSwapType(secretHash) == SwapType.ETH) {
             
            address payable payableReceiver = address(uint160(recipient));
             
            payableReceiver.transfer(_swaps[secretHash].amount);
        } else {
             
            IERC20(_swaps[secretHash].asset).safeTransfer(recipient, _swaps[secretHash].amount);
        }

         
        _swaps[secretHash].secret = secret;

         
        _initiators[_swaps[secretHash].initiator].filledSwaps--;

        emit Redeemed(
            secretHash,
            block.timestamp,
            secret,
            recipient
        );
    }

     
    function refund(
        bytes32 secretHash
    ) public isRefundable(secretHash, msg.sender) {
        _swaps[secretHash].state = State.Refunded;
        _depositOrderBalance(_swaps[secretHash].orderId, msg.sender, _swaps[secretHash].asset, _swaps[secretHash].amount);

         
        _initiators[msg.sender].filledSwaps--;

        emit Refunded(
            _swaps[secretHash].orderId,
            secretHash,
            block.timestamp,
            msg.sender
        );
    }

     
    function changeSwapLifetimeLimits(
        uint256 newMin,
        uint256 newMax
    ) external onlyOwner {
        require(newMin != 0, "changeSwapLifetimeLimits: newMin and newMax should be bigger then 0");
        require(newMax >= newMin, "changeSwapLifetimeLimits: the newMax should be bigger then newMax");

        _swapTimeLimits = SwapTimeLimits(newMin * 1 minutes, newMax * 1 minutes);
    }

     
     
     

     
    function _validateRefundTimestamp(
        uint256 refundTimestamp
    ) private view {
        require(refundTimestamp >= _swapTimeLimits.min, "_validateRefundTimestamp: the timestamp should be bigger than min swap lifetime");
        require(_swapTimeLimits.max >= refundTimestamp, "_validateRefundTimestamp: the timestamp should be smaller than max swap lifetime");
    }

    function _hashTheSecret(
        bytes32 secret
    ) private pure returns (bytes32) {
        return sha256(abi.encodePacked(secret));
    }

    function _getSwapType(
        bytes32 secretHash
    ) private view returns (SwapType tp) {
        if (_swaps[secretHash].asset == _ethAssetIdentificator) {
            return SwapType.ETH;
        } else {
            return SwapType.Token;
        }
    }

     
     
     

     
    function getUserFilledOrders(address user) external view returns (
        uint256[] memory amounts,
        uint256[] memory orderIds,
        uint256[] memory initTimestamps
    ) {
        uint256 swapsLength = _initiators[user].index;
        uint256 filledSwaps = _initiators[user].filledSwaps;

        orderIds = new uint256[](filledSwaps);
        amounts = new uint256[](filledSwaps);
        initTimestamps = new uint256[](filledSwaps);

        uint256 j = 0;
        for (uint256 i = 0; i <= swapsLength; i++) {
            Swap memory swap = _swaps[_initiators[user].swaps[i]];
            if (swap.state == State.Filled) {
                amounts[j] = swap.amount;
                orderIds[j] = swap.orderId;
                initTimestamps[j] = swap.initTimestamp;
                j++;
            }
        }

        return (
        orderIds,
        amounts,
        initTimestamps
        );
    }

     
    function getSwapLifetimeLimits() public view returns (uint256, uint256) {
        return (
        _swapTimeLimits.min,
        _swapTimeLimits.max
        );
    }

     
    function getSwapType(
        bytes32 secretHash
    ) public view returns (SwapType tp) {
        return _getSwapType(secretHash);
    }

     
    function getSwapData(
        bytes32 secretHash
    ) external view returns (
        uint256,
        uint256,
        bytes32,
        bytes32,
        address,
        address,
        address,
        uint256,
        State state
    ) {
        Swap memory swap = _swaps[secretHash];
        return (
        swap.initTimestamp,
        swap.refundTimestamp,
        swap.secretHash,
        swap.secret,
        swap.initiator,
        swap.recipient,
        swap.asset,
        swap.amount,
        swap.state
        );
    }

}