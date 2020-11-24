 

pragma solidity 0.5.11;

 
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

 
contract PayableOwnable {
    address payable internal _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address payable) {
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

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 
 
 
 
 
 
 
 
 
 
 
 
contract TopUpPullPayment is PayableOwnable {
    using SafeMath for uint256;

     
     
     
    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogSmartContractActorFunded(string actorRole, address payable actor, uint256 timestamp);

    event LogPaymentRegistered(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID
    );
    event LogPaymentCancelled(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID
    );
    event LogPullPaymentExecuted(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        uint256 amountInPMA,
        uint256 conversionRate
    );

    event LogTotalLimitUpdated(
        address customerAddress,
        bytes32 paymentID,
        uint256 oldLimit,
        uint256 newLimit
    );

     
     
     
    uint256 constant internal RATE_CALCULATION_NUMBER = 10 ** 26;     
    uint256 constant internal OVERFLOW_LIMITER_NUMBER = 10 ** 20;     

    uint256 constant internal FUNDING_AMOUNT = 0.5 ether;                            
    uint256 constant internal MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS = 0.15 ether;      
    bytes32 constant internal EMPTY_BYTES32 = "";

     
     
     
    IERC20 public token;
    mapping(address => bool) public executors;
    mapping(bytes32 => TopUpPayment) public pullPayments;

    struct TopUpPayment {
        bytes32[2] paymentIDs;                   
        string currency;                         
        address customerAddress;                 
        address treasuryAddress;                 
        address executorAddress;                 
        uint256 initialConversionRate;           
        uint256 initialPaymentAmountInCents;     
        uint256 topUpAmountInCents;              
        uint256 startTimestamp;                  
        uint256 lastPaymentTimestamp;            
        uint256 cancelTimestamp;                 
        uint256 totalLimit;                      
        uint256 totalSpent;                      
    }

     
     
     
    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address - ZERO_ADDRESS provided.");
        _;
    }
    modifier isValidString(string memory _string) {
        require(bytes(_string).length > 0, "Invalid string - is empty.");
        _;
    }
    modifier isValidNumber(uint256 _number) {
        require(_number > 0, "Invalid number - Must be higher than zero.");
        require(_number <= OVERFLOW_LIMITER_NUMBER, "Invalid number - Must be lower than the overflow limit.");
        _;
    }
    modifier isValidByte32(bytes32 _text) {
        require(_text != EMPTY_BYTES32, "Invalid byte32 value.");
        _;
    }
    modifier isValidNewTotalLimit(bytes32 _paymentID, uint256 _newAmount) {
        require(_newAmount >= pullPayments[_paymentID].totalSpent, "New total amount is less than the amount spent.");
        _;
    }
    modifier isExecutor() {
        require(executors[msg.sender], "msg.sender not an executor.");
        _;
    }
    modifier executorExists(address _executor) {
        require(executors[_executor], "Executor does not exists.");
        _;
    }
    modifier executorDoesNotExists(address _executor) {
        require(!executors[_executor], "Executor already exists.");
        _;
    }
    modifier isPullPaymentExecutor(bytes32 _paymentID) {
        require(pullPayments[_paymentID].executorAddress == msg.sender, "msg.sender not allowed to execute this payment.");
        _;
    }
    modifier isCustomer(bytes32 _paymentID) {
        require(pullPayments[_paymentID].customerAddress == msg.sender, "msg.sender not allowed to update this payment.");
        _;
    }
    modifier paymentExists(bytes32 _paymentID) {
        require(pullPayments[_paymentID].paymentIDs[0] != "", "Pull Payment does not exists.");
        _;
    }
    modifier paymentDoesNotExist(bytes32 _paymentID) {
        require(pullPayments[_paymentID].paymentIDs[0] == "", "Pull Payment exists already.");
        _;
    }
    modifier paymentNotCancelled(bytes32 _paymentID) {
        require(pullPayments[_paymentID].cancelTimestamp == 0, "Payment is cancelled");
        _;
    }
    modifier isWithinTheTotalLimits(bytes32 _paymentID) {
        require(pullPayments[_paymentID].totalSpent.add(pullPayments[_paymentID].topUpAmountInCents) <= pullPayments[_paymentID].totalLimit, "Total limit reached.");
        _;
    }

     
     
     
     
     
    constructor(address _token)
    public {
        require(_token != address(0), "Invalid address for token - ZERO_ADDRESS provided.");
        token = IERC20(_token);
    }
     
    function() external payable {
    }

     
     
     
     
     
     
     
    function addExecutor(address payable _executor)
    external
    onlyOwner
    isValidAddress(_executor)
    executorDoesNotExists(_executor)
    {
        executors[_executor] = true;
        if (isFundingNeeded(_executor)) {
            _executor.transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("executor", _executor, now);
        }

        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("owner", owner(), now);
        }
        emit LogExecutorAdded(_executor);
    }
     
     
     
    function removeExecutor(address payable _executor)
    external
    onlyOwner
    isValidAddress(_executor)
    executorExists(_executor)
    {
        executors[_executor] = false;
        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("owner", owner(), now);
        }
        emit LogExecutorRemoved(_executor);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function registerTopUpPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[2] calldata _paymentIDs,
        address[3] calldata _addresses,
        uint256[5] calldata _numbers,
        string calldata _currency
    )
    external
    isExecutor()
    paymentDoesNotExist(_paymentIDs[0])
    isValidString(_currency)
    {
        require(_paymentIDs[0] != EMPTY_BYTES32, "PaymentID - Invalid byte32 value.");
        require(_paymentIDs[1] != EMPTY_BYTES32, "BusinessID - Invalid byte32 value.");

        require(_addresses[0] != address(0), "Invalid customer address - ZERO_ADDRESS provided.");
        require(_addresses[1] != address(0), "Invalid pull payment executor address - ZERO_ADDRESS provided.");
        require(_addresses[2] != address(0), "Invalid treasury address - ZERO_ADDRESS provided.");

        require(_numbers[0] > 0, "Invalid initial conversion rate number - Must be higher than zero.");
        require(_numbers[1] > 0, "Invalid initial payment amount in cents number - Must be higher than zero.");
        require(_numbers[2] > 0, "Invalid top up amount in cents number - Must be higher than zero.");
        require(_numbers[3] > 0, "Invalid start timestamp number - Must be higher than zero.");
        require(_numbers[4] > 0, "Invalid total limit number - Must be higher than zero.");

        require(_numbers[0] <= OVERFLOW_LIMITER_NUMBER, "Invalid initial conversion rate number - Must be lower than the overflow limit.");
        require(_numbers[1] <= OVERFLOW_LIMITER_NUMBER, "Invalid initial payment amount in cents number - Must be lower than the overflow limit.");
        require(_numbers[2] <= OVERFLOW_LIMITER_NUMBER, "Invalid top up amount in cents number - Must be lower than the overflow limit.");
        require(_numbers[3] <= OVERFLOW_LIMITER_NUMBER, "Invalid start timestamp number - Must be lower than the overflow limit.");
        require(_numbers[4] <= OVERFLOW_LIMITER_NUMBER, "Invalid total limit number - Must be lower than the overflow limit.");

        pullPayments[_paymentIDs[0]].paymentIDs[0] = _paymentIDs[0];
        pullPayments[_paymentIDs[0]].paymentIDs[1] = _paymentIDs[1];
        pullPayments[_paymentIDs[0]].currency = _currency;
        pullPayments[_paymentIDs[0]].customerAddress = _addresses[0];
        pullPayments[_paymentIDs[0]].executorAddress = _addresses[1];
        pullPayments[_paymentIDs[0]].treasuryAddress = _addresses[2];

        pullPayments[_paymentIDs[0]].initialConversionRate = _numbers[0];
        pullPayments[_paymentIDs[0]].initialPaymentAmountInCents = _numbers[1];
        pullPayments[_paymentIDs[0]].topUpAmountInCents = _numbers[2];
        pullPayments[_paymentIDs[0]].startTimestamp = _numbers[3];
        pullPayments[_paymentIDs[0]].totalLimit = _numbers[4];

        require(isValidRegistration(
                v,
                r,
                s,
                pullPayments[_paymentIDs[0]]
            ),
            "Invalid pull payment registration - ECRECOVER_FAILED."
        );

        executePullPaymentOnRegistration(
            [_paymentIDs[0], _paymentIDs[1]],
            [_addresses[0], _addresses[2]],
            [_numbers[1], _numbers[0]]
        );

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }

        emit LogPaymentRegistered(_addresses[0], _paymentIDs[0], _paymentIDs[1]);
    }

     
     
     
     
     
     
     
     
     
     
    function executeTopUpPayment(bytes32 _paymentID, uint256 _conversionRate)
    external
    paymentExists(_paymentID)
    paymentNotCancelled(_paymentID)
    isPullPaymentExecutor(_paymentID)
    isValidNumber(_conversionRate)
    isWithinTheTotalLimits(_paymentID)
    returns (bool)
    {
        TopUpPayment storage payment = pullPayments[_paymentID];

        uint256 conversionRate = _conversionRate;
        uint256 amountInPMA = calculatePMAFromFiat(payment.topUpAmountInCents, conversionRate);

        payment.lastPaymentTimestamp = now;
        payment.totalSpent += payment.topUpAmountInCents;

        require(token.transferFrom(payment.customerAddress, payment.treasuryAddress, amountInPMA));

        emit LogPullPaymentExecuted(
            payment.customerAddress,
            payment.paymentIDs[0],
            payment.paymentIDs[1],
            amountInPMA,
            conversionRate
        );
        return true;
    }

     
     
     
     
     
     
     
     
     
     
    function cancelTopUpPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID
    )
    external
    isExecutor()
    paymentExists(_paymentID)
    paymentNotCancelled(_paymentID)
    {
        require(isValidCancellation(v, r, s, _paymentID), "Invalid cancellation - ECRECOVER_FAILED.");
        pullPayments[_paymentID].cancelTimestamp = now;
        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }
        emit LogPaymentCancelled(
            pullPayments[_paymentID].customerAddress,
            _paymentID,
            pullPayments[_paymentID].paymentIDs[1]
        );
    }

     
     
     
    function updateTotalLimit(bytes32 _paymentID, uint256 _newLimit)
    external
    isCustomer(_paymentID)
    isValidNumber(_newLimit)
    isValidNewTotalLimit(_paymentID, _newLimit)
    {
        uint256 oldLimit = pullPayments[_paymentID].totalLimit;
        pullPayments[_paymentID].totalLimit = _newLimit;

        emit LogTotalLimitUpdated(msg.sender, _paymentID, oldLimit, _newLimit);
    }

     
     
    function retrieveLimits(bytes32 _paymentID)
    external
    view
    returns (uint256 totalLimit, uint256 totalSpent)
    {
        return (pullPayments[_paymentID].totalLimit, pullPayments[_paymentID].totalSpent);
    }

     
     
     
     
     
     
     
     
     
    function executePullPaymentOnRegistration(
        bytes32[2] memory _paymentIDs,
        address[2] memory _addresses,
        uint256[2] memory _paymentAmounts
    )
    internal
    {
        TopUpPayment storage payment = pullPayments[_paymentIDs[0]];
        uint256 amountInPMA = calculatePMAFromFiat(_paymentAmounts[0], _paymentAmounts[1]);

        payment.lastPaymentTimestamp = now;

        require(token.transferFrom(_addresses[0], _addresses[1], amountInPMA));

        emit LogPullPaymentExecuted(
            _addresses[0],
            _paymentIDs[0],
            _paymentIDs[1],
            amountInPMA,
            _paymentAmounts[1]
        );
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function calculatePMAFromFiat(uint256 _topUpAmountInCents, uint256 _conversionRate)
    internal
    pure
    returns (uint256) {
        return RATE_CALCULATION_NUMBER.mul(_topUpAmountInCents).div(_conversionRate);
    }

     
     
     
     
     
     
     
    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        TopUpPayment memory _pullPayment
    )
    internal
    pure
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _pullPayment.paymentIDs[0],
                    _pullPayment.paymentIDs[1],
                    _pullPayment.currency,
                    _pullPayment.treasuryAddress,
                    _pullPayment.initialConversionRate,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.topUpAmountInCents,
                    _pullPayment.startTimestamp,
                    _pullPayment.totalLimit
                )
            ),
            v, r, s) == _pullPayment.customerAddress;
    }

     
     
     
     
     
     
     
    function isValidCancellation(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID
    )
    internal
    view
    returns (bool){
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    pullPayments[_paymentID].paymentIDs[0],
                    pullPayments[_paymentID].paymentIDs[1]
                )
            ),
            v, r, s) == pullPayments[_paymentID].customerAddress;
    }

     
     
     
     
    function isFundingNeeded(address _address)
    internal
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS;
    }
}