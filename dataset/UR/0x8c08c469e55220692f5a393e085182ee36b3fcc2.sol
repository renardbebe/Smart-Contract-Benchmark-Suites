 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}


 
contract IRelayRecipient {
     
    function getHubAddr() public view returns (address);

    function acceptRelayedCall(
        address relay,
        address from,
        bytes calldata encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes calldata approvalData,
        uint256 maxPossibleCharge
    )
        external
        view
        returns (uint256, bytes memory);

    function preRelayedCall(bytes calldata context) external returns (bytes32);

    function postRelayedCall(bytes calldata context, bool success, uint actualCharge, bytes32 preRetVal) external;
}


 
contract GSNContext is Context {
    address internal _relayHub = 0xD216153c06E857cD7f72665E0aF1d7D82172F494;

    event RelayHubChanged(address indexed oldRelayHub, address indexed newRelayHub);

    constructor() internal {
         
    }

    function _upgradeRelayHub(address newRelayHub) internal {
        address currentRelayHub = _relayHub;
        require(newRelayHub != address(0), "GSNContext: new RelayHub is the zero address");
        require(newRelayHub != currentRelayHub, "GSNContext: new RelayHub is the current one");

        emit RelayHubChanged(currentRelayHub, newRelayHub);

        _relayHub = newRelayHub;
    }

     
     
     
     

    function _msgSender() internal view returns (address) {
        if (msg.sender != _relayHub) {
            return msg.sender;
        } else {
            return _getRelayedCallSender();
        }
    }

    function _msgData() internal view returns (bytes memory) {
        if (msg.sender != _relayHub) {
            return msg.data;
        } else {
            return _getRelayedCallData();
        }
    }

    function _getRelayedCallSender() private pure returns (address result) {
         
         
         
         
         

         
         

         
        bytes memory array = msg.data;
        uint256 index = msg.data.length;

         
        assembly {
             
            result := and(mload(add(array, index)), 0xffffffffffffffffffffffffffffffffffffffff)
        }
        return result;
    }

    function _getRelayedCallData() private pure returns (bytes memory) {
         
         

        uint256 actualDataLength = msg.data.length - 20;
        bytes memory actualData = new bytes(actualDataLength);

        for (uint256 i = 0; i < actualDataLength; ++i) {
            actualData[i] = msg.data[i];
        }

        return actualData;
    }
}


 
contract GSNBouncerBase is IRelayRecipient {
    uint256 constant private RELAYED_CALL_ACCEPTED = 0;
    uint256 constant private RELAYED_CALL_REJECTED = 11;

     
    uint256 constant internal POST_RELAYED_CALL_MAX_GAS = 100000;

     
     

     
    function preRelayedCall(bytes calldata context) external returns (bytes32) {
        require(msg.sender == getHubAddr(), "GSNBouncerBase: caller is not RelayHub");
        return _preRelayedCall(context);
    }

     
    function postRelayedCall(bytes calldata context, bool success, uint256 actualCharge, bytes32 preRetVal) external {
        require(msg.sender == getHubAddr(), "GSNBouncerBase: caller is not RelayHub");
        _postRelayedCall(context, success, actualCharge, preRetVal);
    }

     
    function _approveRelayedCall() internal pure returns (uint256, bytes memory) {
        return _approveRelayedCall("");
    }

     
    function _approveRelayedCall(bytes memory context) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_ACCEPTED, context);
    }

     
    function _rejectRelayedCall(uint256 errorCode) internal pure returns (uint256, bytes memory) {
        return (RELAYED_CALL_REJECTED + errorCode, "");
    }

     

    function _preRelayedCall(bytes memory) internal returns (bytes32) {
         
    }

    function _postRelayedCall(bytes memory, bool, uint256, bytes32) internal {
         
    }

     
    function _computeCharge(uint256 gas, uint256 gasPrice, uint256 serviceFee) internal pure returns (uint256) {
         
         
        return (gas * gasPrice * (100 + serviceFee)) / 100;
    }
}


contract IRelayHub {
     

     
     
     
     
     
     
     
    function stake(address relayaddr, uint256 unstakeDelay) external payable;

     
    event Staked(address indexed relay, uint256 stake, uint256 unstakeDelay);

     
     
     
     
     
    function registerRelay(uint256 transactionFee, string memory url) public;

     
     
    event RelayAdded(address indexed relay, address indexed owner, uint256 transactionFee, uint256 stake, uint256 unstakeDelay, string url);

     
     
     
    function removeRelayByOwner(address relay) public;

     
    event RelayRemoved(address indexed relay, uint256 unstakeTime);

     
     
     
    function unstake(address relay) public;

     
    event Unstaked(address indexed relay, uint256 stake);

     
    enum RelayState {
        Unknown,  
        Staked,  
        Registered,  
        Removed     
    }

     
    function getRelay(address relay) external view returns (uint256 totalStake, uint256 unstakeDelay, uint256 unstakeTime, address payable owner, RelayState state);

     

     
     
     
    function depositFor(address target) public payable;

     
    event Deposited(address indexed recipient, address indexed from, uint256 amount);

     
    function balanceOf(address target) external view returns (uint256);

     
     
     
    function withdraw(uint256 amount, address payable dest) public;

     
    event Withdrawn(address indexed account, address indexed dest, uint256 amount);

     

     
     
     
     
     
     
    function canRelay(
        address relay,
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public view returns (uint256 status, bytes memory recipientContext);

     
    enum PreconditionCheck {
        OK,                          
        WrongSignature,              
        WrongNonce,                  
        AcceptRelayedCallReverted,   
        InvalidRecipientStatusCode   
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function relayCall(
        address from,
        address to,
        bytes memory encodedFunction,
        uint256 transactionFee,
        uint256 gasPrice,
        uint256 gasLimit,
        uint256 nonce,
        bytes memory signature,
        bytes memory approvalData
    ) public;

     
     
     
     
    event CanRelayFailed(address indexed relay, address indexed from, address indexed to, bytes4 selector, uint256 reason);

     
     
     
     
    event TransactionRelayed(address indexed relay, address indexed from, address indexed to, bytes4 selector, RelayCallStatus status, uint256 charge);

     
    enum RelayCallStatus {
        OK,                       
        RelayedCallFailed,        
        PreRelayedFailed,         
        PostRelayedFailed,        
        RecipientBalanceChanged   
    }

     
     
    function requiredGas(uint256 relayedCallStipend) public view returns (uint256);

     
    function maxPossibleCharge(uint256 relayedCallStipend, uint256 gasPrice, uint256 transactionFee) public view returns (uint256);

     
     
     

     
     
     
    function penalizeRepeatedNonce(bytes memory unsignedTx1, bytes memory signature1, bytes memory unsignedTx2, bytes memory signature2) public;

     
    function penalizeIllegalTransaction(bytes memory unsignedTx, bytes memory signature) public;

    event Penalized(address indexed relay, address sender, uint256 amount);

    function getNonce(address from) external view returns (uint256);
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
}


contract IGasToken is IERC20 {
    function freeUpTo(uint256 value) external returns (uint256 freed);
}


contract IFulcrum is IERC20 {
    function tokenPrice() external view returns (uint256 price);
    function mint(address receiver, uint256 amount) external returns (uint256 minted);
    function burn(address receiver, uint256 amount) external returns (uint256 burned);
}




 
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(_msgSender(), spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(value, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
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
        return _msgSender() == _owner;
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





 
contract GSNRecipient is IRelayRecipient, GSNContext, GSNBouncerBase {
     
    function getHubAddr() public view returns (address) {
        return _relayHub;
    }

     
     
     
    function relayHubVersion() public view returns (string memory) {
        this;  
        return "1.0.0";
    }

     
    function _withdrawDeposits(uint256 amount, address payable payee) internal {
        IRelayHub(_relayHub).withdraw(amount, payee);
    }
}


 
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

     
    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

     
    function name() public view returns (string memory) {
        return _name;
    }

     
    function symbol() public view returns (string memory) {
        return _symbol;
    }

     
    function decimals() public view returns (uint8) {
        return _decimals;
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


contract GasDiscounter {
    IGasToken public constant gasToken = IGasToken(0x0000000000b3F879cb30FE243b4Dfee438691c04);

    modifier gasDiscount() {
        uint256 initialGasLeft = gasleft();
        _;
        _makeGasDiscount(initialGasLeft - gasleft());
    }

    function _makeGasDiscount(uint256 gasSpent) internal {
        uint256 tokens = (gasSpent + 14154) / 41130;
        gasToken.freeUpTo(tokens);
    }
}



contract EarnedInterestERC20 is ERC20 {

    using SafeMath for uint256;

    IFulcrum private fulcrum = IFulcrum(0x14094949152EDDBFcd073717200DA82fEd8dC960);
    mapping(address => uint256) private priceOf;

    function earnedInterest(address user) public view returns (uint256) {

        if (priceOf[user] == 0) {

            return 0;
        }
        
        if (balanceOf(user) < 1e18) {

            return priceOf[user];
        }

        return balanceOf(user).mul(fulcrum.tokenPrice().sub(priceOf[user])).div(1e18);
    }

    function _setEarnedInteres(address user, uint256 interest) internal {

        if (balanceOf(user) < 1e18) {

            priceOf[user] = interest;
        }

        priceOf[user] = fulcrum.tokenPrice().sub(
            interest.mul(1e18).div(balanceOf(user))
        );
    }
}


interface IKyber {
    function getExpectedRate(IERC20 src, IERC20 dest, uint srcQty) external view
    returns (uint expectedRate, uint slippageRate);

    function tradeWithHint(
        IERC20 src,
        uint srcAmount,
        IERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId,
        bytes calldata hint
    ) external payable returns (uint);
}








contract gDAI is Ownable, EarnedInterestERC20, ERC20Detailed, GasDiscounter, GSNRecipient {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for IGasToken;

    address feeReceiver;

    IERC20 public eth = IERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
    IERC20 public dai = IERC20(0x89d24A6b4CcB1B6fAA2625fE562bDD9a23260359);
    IFulcrum public fulcrum = IFulcrum(0x14094949152EDDBFcd073717200DA82fEd8dC960);
    IKyber public kyber = IKyber(0x818E6FECD516Ecc3849DAf6845e3EC868087B755);

    modifier compensateGas {
        uint256 gasProvided = gasleft();
        _;
        if (_msgSender() == msg.sender && tx.origin == msg.sender) {
            _makeGasDiscount(gasProvided.sub(gasleft()));
        }
    }

    constructor(
        address _feeReceiver
    ) public ERC20Detailed("Gasless DAI", "gDAI", 18) {

        feeReceiver = _feeReceiver;
        dai.approve(address(fulcrum), uint256(- 1));
    }

    function setFeeReceiver(address _feeReceiver) public onlyOwner {

        feeReceiver = _feeReceiver;
    }

    function() external payable {

         
        require(msg.sender != tx.origin);
    }

    function preRelayedCall(bytes calldata  ) external returns (bytes32) {

        return "";
    }

    function postRelayedCall(
        bytes calldata  ,
        bool  ,
        uint actualCharge,
        bytes32  
    ) external {

        (uint256 ethPrice,) = kyber.getExpectedRate(eth, dai, actualCharge);
        uint256 daiNeeded = actualCharge.mul(1e18).div(ethPrice);

        uint256 daiExtracted = _getFromFulcrum(daiNeeded);
        uint256 interest = earnedInterest(_msgSender());

        if (daiExtracted < interest) {

            _setEarnedInteres(_msgSender(), interest.sub(daiExtracted));
        } else {

            _setEarnedInteres(_msgSender(), 0);
            _burn(_msgSender(), daiExtracted.sub(interest));
        }

        kyber.tradeWithHint(
            dai,
            daiExtracted,
            eth,
            address(this),
            1 << 255,
            1,
            feeReceiver,
            ""
        );

        IRelayHub(getHubAddr()).depositFor.value(address(this).balance)(address(this));
    }

    function deposit(uint256 amount) public compensateGas {

        uint256 earned = earnedInterest(_msgSender());

        _mint(_msgSender(), amount);
        dai.safeTransferFrom(_msgSender(), address(this), amount);
        _putToFulcrum();

        _setEarnedInteres(_msgSender(), earned);
    }

    function withdraw(uint256 amount) public compensateGas {

        uint256 earned = earnedInterest(_msgSender());

        _burn(_msgSender(), amount);
        _getFromFulcrum(amount);  
        dai.safeTransfer(_msgSender(), amount);
        _putToFulcrum();  

        _setEarnedInteres(_msgSender(), earned);
    }

    function transfer(address to, uint256 amount) public compensateGas returns (bool) {

        uint256 earnedFrom = earnedInterest(_msgSender());
        uint256 earnedTo = earnedInterest(to);

        bool res = super.transfer(to, amount);
        _setEarnedInteres(_msgSender(), earnedFrom);
        _setEarnedInteres(to, earnedTo);

        return res;
    }

    function transferFrom(address from, address to, uint256 amount) public compensateGas returns (bool) {

        uint256 earnedFrom = earnedInterest(from);
        uint256 earnedTo = earnedInterest(to);

        bool res = super.transferFrom(from, to, amount);

        _setEarnedInteres(from, earnedFrom);
        _setEarnedInteres(to, earnedTo);

        return res;
    }

    function approve(address to, uint256 amount) public compensateGas returns (bool) {

        return super.approve(to, amount);
    }

     
    function acceptRelayedCall(
        address  ,
        address from,
        bytes calldata encodedFunction,
        uint256  ,
        uint256  ,
        uint256  ,
        uint256  ,
        bytes calldata  ,
        uint256 maxPossibleCharge
    )
    external
    view
    returns (uint256, bytes memory)
    {

        address sender = from;
         
        (uint256 ethPrice,) = kyber.getExpectedRate(eth, dai, maxPossibleCharge);

        if (balanceOf(sender).add(earnedInterest(sender)) < maxPossibleCharge.mul(1e18).div(ethPrice)) {

            return (1, "Not enough gDAI to pay for Tx");
        }

        if (!compareBytesWithSelector(encodedFunction, this.transfer.selector) &&
        !compareBytesWithSelector(encodedFunction, this.transferFrom.selector) &&
        !compareBytesWithSelector(encodedFunction, this.approve.selector) &&
        !compareBytesWithSelector(encodedFunction, this.deposit.selector) &&
        !compareBytesWithSelector(encodedFunction, this.withdraw.selector))
        {
            return (2, "This gDAI function can't ba called via GSN");
        }

        return (0, "");
    }

    function withdrawFromRelayHub(uint256 amount) public onlyOwner {

        _withdrawDeposits(amount, msg.sender);
    }

    function withdrawGasToken(uint256 amount) public onlyOwner {

        gasToken.safeTransfer(msg.sender, amount);
    }

    function compareBytesWithSelector(bytes memory data, bytes4 sel) internal pure returns (bool) {

        return data[0] == sel[0]
        && data[1] == sel[1]
        && data[2] == sel[2]
        && data[3] == sel[3];
    }

    function _putToFulcrum() internal {

        fulcrum.mint(address(this), dai.balanceOf(address(this)));
    }

    function _getFromFulcrum(uint256 amount) internal returns (uint256 actualAmount) {

        uint256 iDAIAmount = amount.add(1e16).mul(fulcrum.tokenPrice()).div(1e18);
        return fulcrum.burn(address(this), iDAIAmount);
    }
}