 

pragma solidity ^0.5.4;


 
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

     
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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


contract TrustlessOTC is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    mapping(address => uint256) public balanceTracker;
    mapping(address => uint256) public feeTracker;
    mapping(address => uint[]) public tradeTracker;

    event OfferCreated(uint indexed tradeID);
    event OfferCancelled(uint indexed tradeID);
    event OfferTaken(uint indexed tradeID);

    uint256 public feeBasisPoints;

    constructor (uint256 _feeBasisPoints) public {
      feeBasisPoints = _feeBasisPoints;
    }

    struct TradeOffer {
        address tokenFrom;
        address tokenTo;
        uint256 amountFrom;
        uint256 amountTo;
        address payable creator;
        address optionalTaker;
        bool active;
        bool completed;
        uint tradeID;
    }

    TradeOffer[] public offers;

    function initiateTrade(
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo,
        address _optionalTaker
        ) public payable returns (uint newTradeID) {
            if (_tokenFrom == address(0)) {
                require(msg.value == _amountFrom);
            } else {
                require(msg.value == 0);
                IERC20(_tokenFrom).safeTransferFrom(msg.sender, address(this), _amountFrom);
            }
            newTradeID = offers.length;
            offers.length++;
            TradeOffer storage o = offers[newTradeID];
            balanceTracker[_tokenFrom] = balanceTracker[_tokenFrom].add(_amountFrom);
            o.tokenFrom = _tokenFrom;
            o.tokenTo = _tokenTo;
            o.amountFrom = _amountFrom;
            o.amountTo = _amountTo;
            o.creator = msg.sender;
            o.optionalTaker = _optionalTaker;
            o.active = true;
            o.tradeID = newTradeID;
            tradeTracker[msg.sender].push(newTradeID);
            emit OfferCreated(newTradeID);
    }

    function cancelTrade(uint tradeID) public returns (bool) {
        TradeOffer storage o = offers[tradeID];
        require(msg.sender == o.creator);
        if (o.tokenFrom == address(0)) {
          msg.sender.transfer(o.amountFrom);
        } else {
          IERC20(o.tokenFrom).safeTransfer(o.creator, o.amountFrom);
        }
        balanceTracker[o.tokenFrom] -= o.amountFrom;
        o.active = false;
        emit OfferCancelled(tradeID);
        return true;
    }

    function take(uint tradeID) public payable returns (bool) {
        TradeOffer storage o = offers[tradeID];
        require(o.optionalTaker == msg.sender || o.optionalTaker == address(0));
        require(o.active == true);
        o.active = false;
        balanceTracker[o.tokenFrom] = balanceTracker[o.tokenFrom].sub(o.amountFrom);
        uint256 fee = o.amountFrom.mul(feeBasisPoints).div(10000);
        feeTracker[o.tokenFrom] = feeTracker[o.tokenFrom].add(fee);
        tradeTracker[msg.sender].push(tradeID);

        if (o.tokenFrom == address(0)) {
            msg.sender.transfer(o.amountFrom.sub(fee));
        } else {
          IERC20(o.tokenFrom).safeTransfer(msg.sender, o.amountFrom.sub(fee));
        }

        if (o.tokenTo == address(0)) {
            require(msg.value == o.amountTo);
            o.creator.transfer(msg.value);
        } else {
            require(msg.value == 0);
            IERC20(o.tokenTo).safeTransferFrom(msg.sender, o.creator, o.amountTo);
        }
        o.completed = true;
        emit OfferTaken(tradeID);
        return true;
    }

    function getOfferDetails(uint tradeID) external view returns (
        address _tokenFrom,
        address _tokenTo,
        uint256 _amountFrom,
        uint256 _amountTo,
        address _creator,
        uint256 _fee,
        bool _active,
        bool _completed
    ) {
        TradeOffer storage o = offers[tradeID];
        _tokenFrom = o.tokenFrom;
        _tokenTo = o.tokenTo;
        _amountFrom = o.amountFrom;
        _amountTo = o.amountTo;
        _creator = o.creator;
        _fee = o.amountFrom.mul(feeBasisPoints).div(10000);
        _active = o.active;
        _completed = o.completed;
    }

    function getUserTrades(address user) external view returns (uint[] memory){
      return tradeTracker[user];
    }

    function reclaimToken(IERC20 _token) external onlyOwner {
        uint256 balance = _token.balanceOf(address(this));
        uint256 excess = balance.sub(balanceTracker[address(_token)]);
        require(excess > 0);
        if (address(_token) == address(0)) {
            msg.sender.transfer(excess);
        } else {
            _token.safeTransfer(owner(), excess);
        }
    }

    function claimFees(IERC20 _token) external onlyOwner {
        uint256 feesToClaim = feeTracker[address(_token)];
        feeTracker[address(_token)] = 0;
        require(feesToClaim > 0);
        if (address(_token) == address(0)) {
            msg.sender.transfer(feesToClaim);
        } else {
            _token.safeTransfer(owner(), feesToClaim);
        }
    }

}