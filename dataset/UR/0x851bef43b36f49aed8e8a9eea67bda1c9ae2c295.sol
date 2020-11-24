 

pragma solidity ^0.5.0;

 
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


 
contract ERC20 is IERC20 {
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
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
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

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
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
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}


interface NativeTokenMigrationInterface {
     
     
     
    function transferToNativeTargetAddress(uint256 amount, string calldata FETAddress) external;
    function transferToNativeFromKey(uint256 amount) external;
    function refund(uint256 id) external;
    function requestRefund(uint256 id) external;

     
     
     
     
    function setDelegate(address _address, bool isDelegate) external;
     
    function setUpperTransferLimit(uint256 newLimit) external;
     
    function setLowerTransferLimit(uint256 newLimit) external;
     
    function withdrawToFoundation(uint256 _amount) external;
     
    function deleteContract(address payable payoutAddress) external;

     
     
     
     
    function reject(address sender, uint256 id, uint256 expirationBlock, string calldata reason) external;
     
    function batchReject(
        address[] calldata senders,
        uint256[] calldata _ids,
        uint256[] calldata expirationBlocks,
        string calldata reason) external;
     
    function pauseTransferToNativeTargetAddress(bool isPaused) external;
     
    function pauseTransferToNativeFromKey(bool isPaused) external;
}


contract NativeTokenMigration is Ownable, NativeTokenMigrationInterface {
    using SafeMath for uint256;

     
     
    uint256 constant DELETE_PERIOD = 10 days;
    uint256 constant FET_TOTAL_SUPPLY = 1152997575 * 10**18;
    uint256 constant DECIMAL_DIFFERENTIATOR = 10**8;

    enum Status {Empty, Initialised, Rejected}

    struct Swap {
        address sender;
        uint256 amount;
        Status status;
        uint256 fee;
    }

    uint256 public globalSwapID;
     
     
     
    mapping(uint256 => Swap) public swaps;
     

    ERC20 public token;

    mapping(address => bool) public delegates;
    uint256 public _transferFee;
    uint256 public _upperTransferLimit;
    uint256 public _lowerTransferLimit;
    uint256 public _completedAmount;
    bool public _pausedTransferToNativeTargetAddress;
    bool public _pausedTransferToNativeFromKey;
    uint256 public _earliestDelete;

    modifier belowEqualValue(uint256 amount, uint256 threshold) {
        require(amount <= threshold, "Value too high");
        _;
    }

    modifier aboveEqualValue(uint256 amount, uint256 threshold) {
        require(amount >= threshold, "Value too low");
        _;
    }

     
    modifier isFetchAddress(string memory _address) {
        require(bytes(_address).length > 47, "Address too short");
        require(bytes(_address).length < 52, "Address too long");
        _;
    }

    modifier onlySender(uint256 id) {
        require(swaps[id].sender == msg.sender, "Not the sender");
        _;
    }

     
    modifier onlyDelegate() {
        require(isOwner() || delegates[msg.sender], "Caller is neither owner nor delegate");
        _;
    }

    modifier isEqual(uint256 a, uint256 b) {
        require(a == b, "Different values");
        _;
    }

    modifier whenNotPaused(bool pauseIndicator) {
        require(!pauseIndicator, "Transfers are paused");
        _;
    }

    modifier isRejected(uint256 id) {
        require(swaps[id].status == Status.Rejected, "The swap has not been rejected");
        _;
    }

    modifier isInitialised(uint256 id){
        require(swaps[id].status == Status.Initialised, "The swap has not been initialised");
        _;
    }

    event SwapInitialised(address indexed sender, uint256 indexed id, string FETAddress, uint256 amount, uint256 fee);
    event Rejected(address indexed sender, uint256 indexed id, string reason);
    event Refund(address indexed sender, uint256 indexed id);
    event RefundRequested(address indexed sender, uint256 indexed id, uint256 amount);
    event PauseTransferToNativeTargetAddress(bool isPaused);
    event PauseTransferToNativeFromKey(bool isPaused);
    event ChangeDelegate(address delegate, bool isDelegate);
    event ChangeUpperTransferLimit(uint256 newLimit);
    event ChangeLowerTransferLimit(uint256 newLimit);
    event ChangeTransferFee(uint256 newFee);
    event DeleteContract();
    event WithdrawalToFoundation(uint256 amount);

     
     
    constructor(address ERC20Address) public {
        token = ERC20(ERC20Address);
        _upperTransferLimit = FET_TOTAL_SUPPLY;
        _lowerTransferLimit = 0;
        _transferFee = 0;
        _pausedTransferToNativeTargetAddress = false;
        _pausedTransferToNativeFromKey = false;
    }

     
    function _toNativeFET(uint256 amount)
    internal
    pure
    returns (uint256 amountInt)
    {
        return amount.sub(amount.mod(DECIMAL_DIFFERENTIATOR));
    }

     
    function _initSwap(uint256 amount, string memory FETAddress)
    internal
    belowEqualValue(amount, _upperTransferLimit)
    aboveEqualValue(amount, _lowerTransferLimit)
    aboveEqualValue(amount, _transferFee)
    {
        uint256 id = globalSwapID;
        globalSwapID = globalSwapID.add(1);

        uint256 amountInt = _toNativeFET(amount.sub(_transferFee));

        swaps[id].sender = msg.sender;
        swaps[id].amount = amountInt;
        swaps[id].status = Status.Initialised;
        swaps[id].fee = _transferFee;

        _completedAmount = _completedAmount.add(amountInt).add(_transferFee);
        _earliestDelete = block.timestamp.add(DELETE_PERIOD);

        require(token.transferFrom(msg.sender, address(this), amountInt.add(_transferFee)));

        emit SwapInitialised(msg.sender, id, FETAddress, amountInt, _transferFee);
    }

     
    function transferToNativeTargetAddress(uint256 amount, string calldata FETAddress)
    external
    isFetchAddress(FETAddress)
    whenNotPaused(_pausedTransferToNativeTargetAddress)
    {
        _initSwap(amount, FETAddress);
    }

     
    function transferToNativeFromKey(uint256 amount)
    external
    whenNotPaused(_pausedTransferToNativeFromKey)
    {
        _initSwap(amount, "");
    }

     
    function refund(uint256 id)
    external
    isRejected(id)
    onlySender(id)
    {
        uint256 amount = swaps[id].amount.add(swaps[id].fee);
        emit Refund(msg.sender, id);
        delete swaps[id];
        require(token.transfer(msg.sender, amount));
    }

     
    function requestRefund(uint256 id)
    external
    isInitialised(id)
    onlySender(id)
    {
        emit RefundRequested(msg.sender, id, swaps[id].amount);
    }

     
     
    function pauseTransferToNativeTargetAddress(bool isPaused)
    external
    onlyDelegate()
    {
        _pausedTransferToNativeTargetAddress = isPaused;
        emit PauseTransferToNativeTargetAddress(isPaused);
    }

     
    function pauseTransferToNativeFromKey(bool isPaused)
    external
    onlyDelegate()
    {
        _pausedTransferToNativeFromKey = isPaused;
        emit PauseTransferToNativeFromKey(isPaused);
    }

     
    function setDelegate(address _address, bool isDelegate)
    external
    onlyOwner()
    {
        delegates[_address] = isDelegate;
        emit ChangeDelegate(_address, isDelegate);
    }

     
    function setUpperTransferLimit(uint256 newLimit)
    external
    onlyOwner()
    belowEqualValue(newLimit, FET_TOTAL_SUPPLY)
    aboveEqualValue(newLimit, _lowerTransferLimit)
    {
        _upperTransferLimit = newLimit;
        emit ChangeUpperTransferLimit(newLimit);
    }

     
    function setLowerTransferLimit(uint256 newLimit)
    external
    onlyOwner()
    belowEqualValue(newLimit, _upperTransferLimit)
    {
        _lowerTransferLimit = newLimit;
        emit ChangeLowerTransferLimit(newLimit);
    }

     
    function setTransferFee(uint256 newFee)
    external
    onlyOwner()
    {
        _transferFee = newFee;
        emit ChangeTransferFee(newFee);
    }

    function _reject(address sender, uint256 id, uint256 expirationBlock, string memory reason)
    internal
    isInitialised(id)
    belowEqualValue(block.number, expirationBlock)
    {
        emit Rejected(sender, id, reason);
        swaps[id].status = Status.Rejected;
        _completedAmount = _completedAmount.sub(swaps[id].amount).sub(swaps[id].fee);
    }

     
    function reject(address sender, uint256 id, uint256 expirationBlock, string calldata reason)
    external
    onlyDelegate()
    {
        _reject(sender, id, expirationBlock, reason);
    }

     
    function batchReject(address[] calldata senders,
        uint256[] calldata _ids,
        uint256[] calldata expirationBlocks,
        string calldata reason)
    external
    onlyDelegate()
    isEqual(senders.length, _ids.length)
    isEqual(senders.length, expirationBlocks.length)
    {
        for (uint256 i = 0; i < senders.length; i++) {
            _reject(senders[i], _ids[i], expirationBlocks[i], reason);
        }
    }

     
    function withdrawToFoundation(uint256 _amount)
    external
    onlyOwner()
    belowEqualValue(_amount, _completedAmount)
    {
        uint256 amount;
        if (_amount == 0) {
            amount = _completedAmount;
        } else {
            amount = _amount;
        }
        _completedAmount = _completedAmount.sub(amount);
        require(token.transfer(owner(), amount));
        emit WithdrawalToFoundation(amount);
    }

     
    function topupCompletedAmount(uint256 amount)
    external
    {
        _completedAmount = _completedAmount.add(amount);
        require(token.transferFrom(msg.sender, address(this), amount));
    }

     
    function deleteContract(address payable payoutAddress)
    external
    onlyOwner()
    {
        require(block.timestamp >= _earliestDelete, "earliestDelete not reached");
        uint256 contractBalance = token.balanceOf(address(this));
        require(token.transfer(payoutAddress, contractBalance));
        emit DeleteContract();
        selfdestruct(payoutAddress);
    }

}