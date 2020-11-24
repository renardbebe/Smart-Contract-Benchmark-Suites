 

pragma solidity ^0.5.2;


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

contract LibWhitelist is LibOwnable {
    mapping (address => bool) public whitelist;
    address[] public allAddresses;

    event AddressAdded(address indexed adr);
    event AddressRemoved(address indexed adr);

    
    modifier onlyAddressInWhitelist {
        require(whitelist[msg.sender], "SENDER_NOT_IN_WHITELIST_ERROR");
        _;
    }

    
    
    function addAddress(address adr) external onlyOwner {
        emit AddressAdded(adr);
        whitelist[adr] = true;
        allAddresses.push(adr);
    }

    
    
    function removeAddress(address adr) external onlyOwner {
        emit AddressRemoved(adr);
        delete whitelist[adr];
        for(uint i = 0; i < allAddresses.length; i++){
            if(allAddresses[i] == adr) {
                allAddresses[i] = allAddresses[allAddresses.length - 1];
                allAddresses.length -= 1;
                break;
            }
        }
    }

    
    function getAllAddresses() external view returns (address[] memory) {
        return allAddresses;
    }
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

contract Proxy is LibOwnable, LibWhitelist {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    
    address public collateralPoolAddress;

    event Withdraw(address indexed contractAddress, address indexed to, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 value);

    
    function setCollateralPoolAddress(address _collateralPoolAddress) public onlyOwner {
        collateralPoolAddress = _collateralPoolAddress;
    }

    
    
    
    function approveCollateralPool(address contractAddress, address spender, uint256 amount)
        public
        onlyOwner
    {
        IMarketContract marketContract = IMarketContract(contractAddress);
        
        IERC20 collateralToken = IERC20(marketContract.COLLATERAL_TOKEN_ADDRESS());
        if (collateralToken.allowance(address(this), spender) == 0 || amount == 0) {
            collateralToken.safeApprove(spender, amount);
        }
        IERC20 longPositionToken = IERC20(marketContract.LONG_POSITION_TOKEN());
        if (longPositionToken.allowance(address(this), spender) == 0 || amount == 0) {
            longPositionToken.safeApprove(spender, amount);
        }
        IERC20 shortPositionToken = IERC20(marketContract.SHORT_POSITION_TOKEN());
        if (shortPositionToken.allowance(address(this), spender) == 0 || amount == 0) {
            shortPositionToken.safeApprove(spender, amount);
        }
    }

    function withdrawCollateral(address contractAddress, uint256 amount)
        public
        onlyOwner
    {
        IMarketContract marketContract = IMarketContract(contractAddress);
        IERC20(marketContract.COLLATERAL_TOKEN_ADDRESS()).safeTransfer(msg.sender, amount);

        emit Withdraw(contractAddress, msg.sender, amount);
    }

    
    
    
    
    function transfer(address token, address to, uint256 value)
        external
        onlyAddressInWhitelist
    {
        IERC20(token).safeTransfer(to, value);
    }

    
    
    
    
    
    function transferFrom(address token, address from, address to, uint256 value)
        external
        onlyAddressInWhitelist
    {
        IERC20(token).safeTransferFrom(from, to, value);
    }

    
    
    
    function mintPositionTokens(
        address contractAddress,
        uint256 qtyToMint
    )
        external
        onlyAddressInWhitelist
    {
        IMarketContractPool marketContractPool;
        bool isAttemptToPayInMKT;
        if (collateralPoolAddress != address(0x0)) {
            marketContractPool = IMarketContractPool(collateralPoolAddress);
            isAttemptToPayInMKT = true;
        } else {
            IMarketContract marketContract = IMarketContract(contractAddress);
            marketContractPool = IMarketContractPool(marketContract.COLLATERAL_POOL_ADDRESS());
            isAttemptToPayInMKT = false;
        }
        marketContractPool.mintPositionTokens(contractAddress, qtyToMint, isAttemptToPayInMKT);
    }

    
    
    
    function redeemPositionTokens(
        address contractAddress,
        uint256 qtyToRedeem
    )
        external
        onlyAddressInWhitelist
    {
        IMarketContractPool marketContractPool;
        if (collateralPoolAddress != address(0x0)) {
            marketContractPool = IMarketContractPool(collateralPoolAddress);
        } else {
            IMarketContract marketContract = IMarketContract(contractAddress);
            marketContractPool = IMarketContractPool(marketContract.COLLATERAL_POOL_ADDRESS());
        }
        marketContractPool.redeemPositionTokens(contractAddress, qtyToRedeem);
    }
}