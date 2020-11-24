 

 

pragma solidity ^0.5.0;

 
library Math {
     
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

     
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

     
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
         
        return (a / 2) + (b / 2) + ((a % 2 + b % 2) / 2);
    }
}

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
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

 

pragma solidity ^0.5.5;

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

         
         
         
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
         
        assembly { codehash := extcodehash(account) }
        return (codehash != 0x0 && codehash != accountHash);
    }

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }

     
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

         
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

 

pragma solidity ^0.5.0;




 
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
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
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

 

pragma solidity ^0.5.0;






interface InteractiveTaker {
    function interact(
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256 takingAmount,
        uint256 expectedAmount
    ) external;
}


library LimitOrder {
    struct Data {
        address makerAddress;
        address takerAddress;
        IERC20 makerAsset;
        IERC20 takerAsset;
        uint256 makerAmount;
        uint256 takerAmount;
        uint256 expiration;
    }

    function hash(Data memory order, address contractAddress) internal pure returns(bytes32) {
        return keccak256(abi.encodePacked(
            contractAddress,
            order.makerAddress,
            order.takerAddress,
            order.makerAsset,
            order.takerAsset,
            order.makerAmount,
            order.takerAmount,
            order.expiration
        ));
    }
}

library ArrayHelper {
    function one(uint256 elem) internal pure returns(uint256[] memory arr) {
        arr = new uint256[](1);
        arr[0] = elem;
    }

    function one(address elem) internal pure returns(address[] memory arr) {
        arr = new address[](1);
        arr[0] = elem;
    }
}


contract Depositor {

    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    modifier deposit(bytes4 sig) {
        if (msg.value > 0 && sig == msg.sig) {
            _deposit();
        }
        _;
    }

    modifier depositAndWithdraw(bytes4 sig) {
        uint256 prevBalance = balanceOf(msg.sender);
        if (msg.value > 0 && sig == msg.sig) {
            _deposit();
        }
        _;
        if (balanceOf(msg.sender) > prevBalance) {
            _withdraw(balanceOf(msg.sender).sub(prevBalance));
        }
    }

    function balanceOf(address user) public view returns(uint256) {
        return _balances[user];
    }

    function _deposit() internal {
        _mint(msg.sender, msg.value);
    }

    function _withdraw(uint256 amount) internal {
        _burn(msg.sender, amount);
        msg.sender.transfer(amount);
    }

    function _mint(address user, uint256 amount) internal {
        _balances[user] = _balances[user].add(amount);
    }

    function _burn(address user, uint256 amount) internal {
        _balances[user] = _balances[user].sub(amount);
    }
}


contract LimitSwap is Depositor {

    using SafeERC20 for IERC20;
    using LimitOrder for LimitOrder.Data;

    mapping(bytes32 => uint256) public remainings;

    event LimitOrderUpdated(
        address indexed makerAddress,
        address takerAddress,
        IERC20 indexed makerAsset,
        IERC20 indexed takerAsset,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 expiration,
        uint256 remaining
    );

    function available(
        address[] memory makerAddresses,
        address[] memory takerAddresses,
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256[] memory makerAmounts,
        uint256[] memory takerAmounts,
        uint256[] memory expirations
    )
        public
        view
        returns(uint256 makerFilledAmount)
    {
        uint256[] memory userAvailable = new uint256[](makerAddresses.length);

        for (uint i = 0; i < makerAddresses.length; i++) {
            if (expirations[i] < now) {
                continue;
            }

            if (makerAsset == IERC20(0)) {
                makerFilledAmount = makerFilledAmount.add(makerAmounts[i]);
                continue;
            }

            LimitOrder.Data memory order = LimitOrder.Data({
                makerAddress: makerAddresses[i],
                takerAddress: takerAddresses[i],
                makerAsset: makerAsset,
                takerAsset: takerAsset,
                makerAmount: makerAmounts[i],
                takerAmount: takerAmounts[i],
                expiration: expirations[i]
            });

            bool found = false;
            for (uint j = 0; j < i; j++) {
                if (makerAddresses[j] == makerAddresses[i]) {
                    found = true;
                    if (userAvailable[j] > makerAmounts[i]) {
                        userAvailable[j] = userAvailable[j].sub(makerAmounts[i]);
                        makerFilledAmount = makerFilledAmount.add(makerAmounts[i]);
                    } else {
                        makerFilledAmount = makerFilledAmount.add(userAvailable[j]);
                        userAvailable[j] = 0;
                    }
                    break;
                }
            }

            if (!found) {
                userAvailable[i] = Math.min(
                    makerAsset.balanceOf(makerAddresses[i]),
                    makerAsset.allowance(makerAddresses[i], address(this))
                );
                uint256 maxOrderSize = Math.min(
                    remainings[order.hash(address(this))],
                    userAvailable[i]
                );
                userAvailable[i] = userAvailable[i].sub(maxOrderSize);
                makerFilledAmount = makerFilledAmount.add(maxOrderSize);
            }
        }
    }

    function makeOrder(
        address takerAddress,
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 expiration
    )
        public
        payable
        deposit(this.makeOrder.selector)
    {
        LimitOrder.Data memory order = LimitOrder.Data({
            makerAddress: msg.sender,
            takerAddress: takerAddress,
            makerAsset: makerAsset,
            takerAsset: takerAsset,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: expiration
        });

        bytes32 orderHash = order.hash(address(this));
        require(remainings[orderHash] == 0, "LimitSwap: existing order");

        if (makerAsset == IERC20(0)) {
            require(makerAmount == msg.value, "LimitSwap: for ETH makerAmount should be equal to msg.value");
        } else {
            require(msg.value == 0, "LimitSwap: msg.value should be 0 when makerAsset in not ETH");
        }

        remainings[orderHash] = makerAmount;
        _updateOrder(order, orderHash);
    }

    function cancelOrder(
        address takerAddress,
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 expiration
    )
        public
    {
        LimitOrder.Data memory order = LimitOrder.Data({
            makerAddress: msg.sender,
            takerAddress: takerAddress,
            makerAsset: makerAsset,
            takerAsset: takerAsset,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: expiration
        });

        bytes32 orderHash = order.hash(address(this));
        require(remainings[orderHash] != 0, "LimitSwap: not existing or already filled order");

        if (makerAsset == IERC20(0)) {
            _withdraw(remainings[orderHash]);
        }

        remainings[orderHash] = 0;
        _updateOrder(order, orderHash);
    }

    function takeOrdersAvailable(
        address payable[] memory makerAddresses,
        address[] memory takerAddresses,
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256[] memory makerAmounts,
        uint256[] memory takerAmounts,
        uint256[] memory expirations,
        uint256 takingAmount
    )
        public
        payable
        depositAndWithdraw(this.takeOrdersAvailable.selector)
        returns(uint256 takerVolume)
    {
        for (uint i = 0; takingAmount > takerVolume && i < makerAddresses.length; i++) {
            takerVolume = takerVolume.sub(
                takeOrderAvailable(
                    makerAddresses[i],
                    takerAddresses[i],
                    makerAsset,
                    takerAsset,
                    makerAmounts[i],
                    takerAmounts[i],
                    expirations[i],
                    takingAmount.sub(takerVolume),
                    false
                )
            );
        }
    }

    function takeOrderAvailable(
        address payable makerAddress,
        address takerAddress,
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 expiration,
        uint256 takingAmount,
        bool interactive
    )
        public
        payable
        depositAndWithdraw(this.takeOrderAvailable.selector)
        returns(uint256 takerVolume)
    {
        takerVolume = Math.min(
            takingAmount,
            available(
                ArrayHelper.one(makerAddress),
                ArrayHelper.one(takerAddress),
                makerAsset,
                takerAsset,
                ArrayHelper.one(makerAmount),
                ArrayHelper.one(takerAmount),
                ArrayHelper.one(expiration)
            )
        );
        takeOrder(
            makerAddress,
            takerAddress,
            makerAsset,
            takerAsset,
            makerAmount,
            takerAmount,
            expiration,
            takerVolume,
            interactive
        );
    }

    function takeOrder(
        address payable makerAddress,
        address takerAddress,
        IERC20 makerAsset,
        IERC20 takerAsset,
        uint256 makerAmount,
        uint256 takerAmount,
        uint256 expiration,
        uint256 takingAmount,
        bool interactive
    )
        public
        payable
        depositAndWithdraw(this.takeOrder.selector)
    {
        require(block.timestamp <= expiration, "LimitSwap: order already expired");
        require(takerAddress == address(0) || takerAddress == msg.sender, "LimitSwap: access denied to this order");

        LimitOrder.Data memory order = LimitOrder.Data({
            makerAddress: makerAddress,
            takerAddress: takerAddress,
            makerAsset: makerAsset,
            takerAsset: takerAsset,
            makerAmount: makerAmount,
            takerAmount: takerAmount,
            expiration: expiration
        });

        bytes32 orderHash = order.hash(address(this));
        remainings[orderHash] = remainings[orderHash].sub(takingAmount, "LimitSwap: remaining amount is less than taking amount");
        _updateOrder(order, orderHash);

         
        if (makerAsset == IERC20(0)) {
            _burn(makerAddress, takingAmount);
            msg.sender.transfer(takingAmount);
        } else {
            makerAsset.safeTransferFrom(makerAddress, msg.sender, takingAmount);
        }

         
        uint256 expectedAmount = takingAmount.mul(makerAmount).div(takerAmount);
        if (interactive) {
            InteractiveTaker(msg.sender).interact(makerAsset, takerAsset, takingAmount, expectedAmount);
        }

         
        if (takerAsset == IERC20(0)) {
            _burn(msg.sender, expectedAmount);
            makerAddress.transfer(expectedAmount);
        } else {
            require(msg.value == 0, "LimitSwap: msg.value should be 0 when takerAsset in not ETH");
            takerAsset.safeTransferFrom(msg.sender, makerAddress, expectedAmount);
        }
    }

    function _updateOrder(
        LimitOrder.Data memory order,
        bytes32 orderHash
    )
        internal
    {
        emit LimitOrderUpdated(
            order.makerAddress,
            order.takerAddress,
            order.makerAsset,
            order.takerAsset,
            order.makerAmount,
            order.takerAmount,
            order.expiration,
            remainings[orderHash]
        );
    }
}