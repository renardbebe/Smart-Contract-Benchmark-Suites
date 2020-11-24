 

 

pragma solidity 0.5.10;

 
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

 

pragma solidity 0.5.10;

 
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

 

pragma solidity 0.5.10;




 
 
 
 
 
contract PumaPayPullPaymentV2 is PayableOwnable {
    using SafeMath for uint256;
     
     
     
    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogSmartContractActorFunded(string actorRole, address payable actor, uint256 timestamp);
    event LogPaymentRegistered(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        bytes32 uniqueReferenceID
    );
    event LogPaymentCancelled(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        bytes32 uniqueReferenceID
    );
    event LogPullPaymentExecuted(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        bytes32 uniqueReferenceID,
        uint256 amountInPMA,
        uint256 conversionRate
    );
     
     
     
    uint256 constant private RATE_CALCULATION_NUMBER = 10 ** 26;     
    uint256 constant private OVERFLOW_LIMITER_NUMBER = 10 ** 20;    
     
     
     
     
    uint256 constant private ONE_ETHER = 1 ether;                                   
    uint256 constant private FUNDING_AMOUNT = 0.5 ether;                            
    uint256 constant private MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS = 0.15 ether;      
    bytes32 constant private TYPE_SINGLE_PULL_PAYMENT = "2";
    bytes32 constant private TYPE_RECURRING_PULL_PAYMENT = "3";
    bytes32 constant private TYPE_RECURRING_PULL_PAYMENT_WITH_INITIAL = "4";
    bytes32 constant private TYPE_PULL_PAYMENT_WITH_FREE_TRIAL = "5";
    bytes32 constant private TYPE_PULL_PAYMENT_WITH_PAID_TRIAL = "6";
    bytes32 constant private TYPE_SINGLE_DYNAMIC_PULL_PAYMENT = "7";
    bytes32 constant private EMPTY_BYTES32 = "";
     
     
     
    IERC20 public token;
    mapping(address => bool) public executors;
    mapping(address => mapping(address => PullPayment)) public pullPayments;

    struct PullPayment {
        bytes32[3] paymentIds;                   
        bytes32 paymentType;                     
        string currency;                         
        uint256 initialConversionRate;           
        uint256 initialPaymentAmountInCents;     
        uint256 fiatAmountInCents;               
        uint256 frequency;                       
        uint256 numberOfPayments;                
        uint256 startTimestamp;                  
        uint256 trialPeriod;                     
        uint256 nextPaymentTimestamp;            
        uint256 lastPaymentTimestamp;            
        uint256 cancelTimestamp;                 
        address treasuryAddress;                 
    }
     
     
     
    modifier isExecutor() {
        require(executors[msg.sender], "msg.sender not an executor");
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
    modifier paymentExists(address _customerAddress, address _pullPaymentExecutor) {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].paymentIds[0] != "", "Pull Payment does not exists.");
        _;
    }
    modifier paymentNotCancelled(address _customerAddress, address _pullPaymentExecutor) {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp == 0, "Pull Payment is cancelled");
        _;
    }
    modifier isValidPullPaymentExecutionRequest(
        address _customerAddress,
        address _pullPaymentExecutor,
        bytes32 _paymentID,
        uint256 _paymentNumber) {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments == _paymentNumber,
            "Invalid pull payment execution request - Pull payment number of payment is invalid");
        require((pullPayments[_customerAddress][_pullPaymentExecutor].initialPaymentAmountInCents > 0 ||
        (now >= pullPayments[_customerAddress][_pullPaymentExecutor].startTimestamp &&
        now >= pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp)
            ), "Invalid pull payment execution request - Time of execution is invalid."
        );
        require(pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments > 0,
            "Invalid pull payment execution request - Number of payments is zero.");
        require(
            (pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp == 0 ||
        pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp >
        pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp),
            "Invalid pull payment execution request - Pull payment is cancelled");
        require(keccak256(
            abi.encodePacked(pullPayments[_customerAddress][_pullPaymentExecutor].paymentIds[0])
        ) == keccak256(abi.encodePacked(_paymentID)),
            "Invalid pull payment execution request - Payment ID not matching.");
        _;
    }
    modifier isValidDeletionRequest(bytes32 _paymentID, address _customerAddress, address _pullPaymentExecutor) {
        require(_paymentID != EMPTY_BYTES32, "Invalid deletion request - Payment ID is empty.");
        require(_customerAddress != address(0), "Invalid deletion request - Client address is ZERO_ADDRESS.");
        require(_pullPaymentExecutor != address(0), "Invalid deletion request - Beneficiary address is ZERO_ADDRESS.");
        _;
    }
    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address - ZERO_ADDRESS provided");
        _;
    }
    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "Invalid amount - Must be higher than zero");
        require(_amount <= OVERFLOW_LIMITER_NUMBER, "Invalid amount - Must be lower than the overflow limit.");
        _;
    }
     
     
     
     
     
    constructor(address _token)
    public {
        require(_token != address(0), "Invalid address for token - ZERO_ADDRESS provided");
        token = IERC20(_token);
    }
     
    function() external payable {
    }
     
     
     
     
     
     
     
    function addExecutor(address payable _executor)
    public
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
    public
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
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function registerPullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[4] memory _paymentDetails,  
        address[3] memory _addresses,  
        uint256[3] memory _paymentAmounts,  
        uint256[4] memory _paymentTimestamps,  
        string memory _currency
    )
    public
    isExecutor()
    {
        require(pullPayments[_addresses[0]][_addresses[1]].paymentIds[0] == "", "Pull Payment already exists.");
        require(_paymentDetails[0] != EMPTY_BYTES32, "Payment ID is empty.");
        require(_paymentDetails[1] != EMPTY_BYTES32, "Business ID is empty.");
        require(_paymentDetails[2] != EMPTY_BYTES32, "Unique Reference ID is empty.");
        require(_paymentDetails[3] != EMPTY_BYTES32, "Payment Type is empty.");
        require(_addresses[0] != address(0), "Customer Address is ZERO_ADDRESS.");
        require(_addresses[1] != address(0), "Pull Payment Executor Address is ZERO_ADDRESS.");
        require(_addresses[2] != address(0), "Treasury Address is ZERO_ADDRESS.");
        require(_paymentAmounts[0] > 0, "Initial conversion rate is zero.");
        require(_paymentAmounts[1] > 0, "Payment amount in fiat is zero.");
        require(_paymentAmounts[2] >= 0, "Initial payment amount in fiat is less than zero.");
        require(_paymentTimestamps[0] > 0, "Payment frequency is zero.");
        require(_paymentTimestamps[1] > 0, "Payment number of payments is zero.");
        require(_paymentTimestamps[2] > 0, "Payment start time is zero.");
        require(_paymentTimestamps[3] >= 0, "Payment trial period is less than zero.");
        require(_paymentAmounts[0] <= OVERFLOW_LIMITER_NUMBER, "Initial conversion rate is higher thant the overflow limit.");
        require(_paymentAmounts[1] <= OVERFLOW_LIMITER_NUMBER, "Payment amount in fiat is higher thant the overflow limit.");
        require(_paymentAmounts[2] <= OVERFLOW_LIMITER_NUMBER, "Payment initial amount in fiat is higher thant the overflow limit.");
        require(_paymentTimestamps[0] <= OVERFLOW_LIMITER_NUMBER, "Payment frequency is higher thant the overflow limit.");
        require(_paymentTimestamps[1] <= OVERFLOW_LIMITER_NUMBER, "Payment number of payments is higher thant the overflow limit.");
        require(_paymentTimestamps[2] <= OVERFLOW_LIMITER_NUMBER, "Payment start time is higher thant the overflow limit.");
        require(_paymentTimestamps[3] <= OVERFLOW_LIMITER_NUMBER, "Payment trial period is higher thant the overflow limit.");
        require(bytes(_currency).length > 0, "Currency is empty");
        pullPayments[_addresses[0]][_addresses[1]].paymentIds[0] = _paymentDetails[0];
        pullPayments[_addresses[0]][_addresses[1]].paymentType = _paymentDetails[3];
        pullPayments[_addresses[0]][_addresses[1]].treasuryAddress = _addresses[2];
        pullPayments[_addresses[0]][_addresses[1]].initialConversionRate = _paymentAmounts[0];
        pullPayments[_addresses[0]][_addresses[1]].fiatAmountInCents = _paymentAmounts[1];
        pullPayments[_addresses[0]][_addresses[1]].initialPaymentAmountInCents = _paymentAmounts[2];
        pullPayments[_addresses[0]][_addresses[1]].frequency = _paymentTimestamps[0];
        pullPayments[_addresses[0]][_addresses[1]].numberOfPayments = _paymentTimestamps[1];
        pullPayments[_addresses[0]][_addresses[1]].startTimestamp = _paymentTimestamps[2];
        pullPayments[_addresses[0]][_addresses[1]].trialPeriod = _paymentTimestamps[3];
        pullPayments[_addresses[0]][_addresses[1]].currency = _currency;
        require(isValidRegistration(
                v,
                r,
                s,
                _addresses[0],
                _addresses[1],
                pullPayments[_addresses[0]][_addresses[1]]),
            "Invalid pull payment registration - ECRECOVER_FAILED"
        );
        pullPayments[_addresses[0]][_addresses[1]].paymentIds[1] = _paymentDetails[1];
        pullPayments[_addresses[0]][_addresses[1]].paymentIds[2] = _paymentDetails[2];
        pullPayments[_addresses[0]][_addresses[1]].cancelTimestamp = 0;
         
         
         
        if (_paymentDetails[3] == TYPE_PULL_PAYMENT_WITH_FREE_TRIAL) {
            pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _paymentTimestamps[2] + _paymentTimestamps[3];
            pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = 0;
             
             
             
             
             
        } else if (_paymentDetails[3] == TYPE_RECURRING_PULL_PAYMENT_WITH_INITIAL) {
            executePullPaymentOnRegistration(
                [_paymentDetails[0], _paymentDetails[1], _paymentDetails[2]],  
                [_addresses[0], _addresses[2]],  
                [_paymentAmounts[2], _paymentAmounts[0]]  
            );
            pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = now;
            pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _paymentTimestamps[2] + _paymentTimestamps[0];
             
             
             
             
        } else if (_paymentDetails[3] == TYPE_PULL_PAYMENT_WITH_PAID_TRIAL) {
            executePullPaymentOnRegistration(
                [_paymentDetails[0], _paymentDetails[1], _paymentDetails[2]],  
                [_addresses[0], _addresses[2]],  
                [_paymentAmounts[2], _paymentAmounts[0]]  
            );
            pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = now;
            pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _paymentTimestamps[2] + _paymentTimestamps[3];
             
             
             
             
             
        } else {
            executePullPaymentOnRegistration(
                [_paymentDetails[0], _paymentDetails[1], _paymentDetails[2]],  
                [_addresses[0], _addresses[2]],  
                [_paymentAmounts[1], _paymentAmounts[0]]  
            );
            pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = now;
            pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _paymentTimestamps[2] + _paymentTimestamps[0];
            pullPayments[_addresses[0]][_addresses[1]].numberOfPayments = _paymentTimestamps[1] - 1;
        }
        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }
        emit LogPaymentRegistered(_addresses[0], _paymentDetails[0], _paymentDetails[1], _paymentDetails[2]);
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
    function deletePullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID,
        address _customerAddress,
        address _pullPaymentExecutor
    )
    public
    isExecutor()
    paymentExists(_customerAddress, _pullPaymentExecutor)
    paymentNotCancelled(_customerAddress, _pullPaymentExecutor)
    isValidDeletionRequest(_paymentID, _customerAddress, _pullPaymentExecutor)
    {
        require(isValidDeletion(v, r, s, _paymentID, _customerAddress, _pullPaymentExecutor), "Invalid deletion - ECRECOVER_FAILED.");
        pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp = now;
        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);
            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }
        emit LogPaymentCancelled(
            _customerAddress,
            _paymentID,
            pullPayments[_customerAddress][_pullPaymentExecutor].paymentIds[1],
            pullPayments[_customerAddress][_pullPaymentExecutor].paymentIds[2]
        );
    }
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function executePullPayment(address _customerAddress, bytes32 _paymentID, uint256[2] memory _paymentDetails)
    public
    paymentExists(_customerAddress, msg.sender)
    isValidPullPaymentExecutionRequest(_customerAddress, msg.sender, _paymentID, _paymentDetails[1])
    validAmount(_paymentDetails[0])
    returns (bool)
    {
        uint256 conversionRate = _paymentDetails[0];
        address customerAddress = _customerAddress;
        bytes32[3] memory paymentIds = pullPayments[customerAddress][msg.sender].paymentIds;
        address treasury = pullPayments[customerAddress][msg.sender].treasuryAddress;
        uint256 amountInPMA = calculatePMAFromFiat(pullPayments[customerAddress][msg.sender].fiatAmountInCents, conversionRate);

        pullPayments[customerAddress][msg.sender].nextPaymentTimestamp =
        pullPayments[customerAddress][msg.sender].nextPaymentTimestamp + pullPayments[customerAddress][msg.sender].frequency;
        pullPayments[customerAddress][msg.sender].numberOfPayments = pullPayments[customerAddress][msg.sender].numberOfPayments - 1;
        pullPayments[customerAddress][msg.sender].lastPaymentTimestamp = now;
        token.transferFrom(
            customerAddress,
            treasury,
            amountInPMA
        );
        emit LogPullPaymentExecuted(
            customerAddress,
            paymentIds[0],
            paymentIds[1],
            paymentIds[2],
            amountInPMA,
            conversionRate
        );
        return true;
    }

     
     
     
     
     
    function executePullPaymentOnRegistration(
        bytes32[3] memory _paymentDetails,  
        address[2] memory _addresses,  
        uint256[2] memory _paymentAmounts  
    )
    internal
    returns (bool) {
        uint256 amountInPMA = calculatePMAFromFiat(_paymentAmounts[0], _paymentAmounts[1]);
        token.transferFrom(_addresses[0], _addresses[1], amountInPMA);
        emit LogPullPaymentExecuted(
            _addresses[0],
            _paymentDetails[0],
            _paymentDetails[1],
            _paymentDetails[2],
            amountInPMA,
            _paymentAmounts[1]
        );
        return true;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function calculatePMAFromFiat(uint256 _fiatAmountInCents, uint256 _conversionRate)
    internal
    pure
    validAmount(_fiatAmountInCents)
    validAmount(_conversionRate)
    returns (uint256) {
        return RATE_CALCULATION_NUMBER.mul(_fiatAmountInCents).div(_conversionRate);
    }
     
     
     
     
     
     
     
     
     
    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        address _customerAddress,
        address _pullPaymentExecutor,
        PullPayment memory _pullPayment
    )
    internal
    pure
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _pullPaymentExecutor,
                    _pullPayment.paymentIds[0],
                    _pullPayment.paymentType,
                    _pullPayment.treasuryAddress,
                    _pullPayment.currency,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.fiatAmountInCents,
                    _pullPayment.frequency,
                    _pullPayment.numberOfPayments,
                    _pullPayment.startTimestamp,
                    _pullPayment.trialPeriod
                )
            ),
            v, r, s) == _customerAddress;
    }
     
     
     
     
     
     
     
     
     
    function isValidDeletion(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32 _paymentID,
        address _customerAddress,
        address _pullPaymentExecutor
    )
    internal
    view
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _paymentID,
                    _pullPaymentExecutor
                )
            ), v, r, s) == _customerAddress
        && keccak256(
            abi.encodePacked(pullPayments[_customerAddress][_pullPaymentExecutor].paymentIds[0])
        ) == keccak256(abi.encodePacked(_paymentID)
        );
    }
     
     
     
     
    function isFundingNeeded(address _address)
    private
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS;
    }
}