 

 

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




 
 
contract PumaPayPullPayment is PayableOwnable {

    using SafeMath for uint256;

     
     
     

    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);
    event LogSetConversionRate(string currency, uint256 conversionRate);

    event LogSmartContractActorFunded(string actorRole, address payable actor, uint256 timestamp);

    event LogPaymentRegistered(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );
    event LogPaymentCancelled(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );
    event LogPullPaymentExecuted(
        address customerAddress,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID,
        uint256 amountInPMA,
        uint256 conversionRate
    );

     
     
     

    uint256 constant private RATE_CALCULATION_NUMBER = 10 ** 26;     
    uint256 constant private OVERFLOW_LIMITER_NUMBER = 10 ** 20;     

     
     
     
     

    uint256 constant private ONE_ETHER = 1 ether;                                
    uint256 constant private FUNDING_AMOUNT = 0.5 ether;                         
    uint256 constant private MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS = 0.15 ether;   

    bytes32 constant private EMPTY_BYTES32 = "";

     
     
     

    IERC20 public token;

    mapping(string => uint256) private conversionRates;
    mapping(address => bool) public executors;
    mapping(address => mapping(address => PullPayment)) public pullPayments;

    struct PullPayment {
        bytes32 paymentID;                       
        bytes32 businessID;                      
        string uniqueReferenceID;                
        string currency;                         
        uint256 initialPaymentAmountInCents;     
        uint256 fiatAmountInCents;               
        uint256 frequency;                       
        uint256 numberOfPayments;                
        uint256 startTimestamp;                  
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
        require(doesPaymentExist(_customerAddress, _pullPaymentExecutor), "Pull Payment does not exists");
        _;
    }

    modifier paymentNotCancelled(address _customerAddress, address _pullPaymentExecutor) {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp == 0, "Pull Payment is cancelled.");
        _;
    }

    modifier isValidPullPaymentExecutionRequest(address _customerAddress, address _pullPaymentExecutor, bytes32 _paymentID, uint256 _paymentNumber)
    {
        require(pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments == _paymentNumber,
            "Invalid pull payment execution request - Pull payment number of payment is invalid");

        require(
            (pullPayments[_customerAddress][_pullPaymentExecutor].initialPaymentAmountInCents > 0 ||
        (now >= pullPayments[_customerAddress][_pullPaymentExecutor].startTimestamp &&
        now >= pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp)
            ), "Invalid pull payment execution request - Time of execution is invalid."
        );
        require(pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments > 0,
            "Invalid pull payment execution request - Number of payments is zero.");

        require((pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp == 0 ||
        pullPayments[_customerAddress][_pullPaymentExecutor].cancelTimestamp > pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp),
            "Invalid pull payment execution request - Pull payment is cancelled");
        require(keccak256(
            abi.encodePacked(pullPayments[_customerAddress][_pullPaymentExecutor].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID)),
            "Invalid pull payment execution request - Payment ID not matching.");
        _;
    }

    modifier isValidDeletionRequest(bytes32 _paymentID, address _customerAddress, address _pullPaymentExecutor) {
        require(_customerAddress != address(0), "Invalid deletion request - Client address is ZERO_ADDRESS.");
        require(_pullPaymentExecutor != address(0), "Invalid deletion request - Beneficiary address is ZERO_ADDRESS.");
        require(_paymentID != EMPTY_BYTES32, "Invalid deletion request - Payment ID is empty.");
        _;
    }

    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address - ZERO_ADDRESS provided");
        _;
    }

    modifier validConversionRate(string memory _currency) {
        require(bytes(_currency).length != 0, "Invalid conversion rate - Currency is empty.");
        _;
    }

    modifier validAmount(uint256 _amount) {
        require(_amount > 0, "Invalid amount - Must be higher than zero");
        require(_amount <= OVERFLOW_LIMITER_NUMBER, "Invalid amount - Must be lower than the overflow limit.");
        _;
    }

     
     
     

     
     
    constructor (address _token)
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

     
     
     
     
     
    function setRate(string memory _currency, uint256 _rate)
    public
    onlyOwner
    validAmount(_rate)
    returns (bool) {
        require(bytes(_currency).length != 0, "Invalid conversion rate - Currency is empty.");
        conversionRates[_currency] = _rate;
        emit LogSetConversionRate(_currency, _rate);

        if (isFundingNeeded(owner())) {
            owner().transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("owner", owner(), now);
        }

        return true;
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function registerPullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[2] memory _ids,  
        address[3] memory _addresses,  
        string memory _currency,
        string memory _uniqueReferenceID,
        uint256 _initialPaymentAmountInCents,
        uint256 _fiatAmountInCents,
        uint256 _frequency,
        uint256 _numberOfPayments,
        uint256 _startTimestamp
    )
    public
    isExecutor()
    {
        require(!doesPaymentExist(_addresses[0], _addresses[1]), "Pull Payment already exists.");

        require(_ids[0] != EMPTY_BYTES32, "Payment ID is empty.");
        require(_ids[1] != EMPTY_BYTES32, "Business ID is empty.");
        require(bytes(_currency).length > 0, "Currency is empty.");
        require(bytes(_uniqueReferenceID).length > 0, "Unique Reference ID is empty.");

        require(_addresses[0] != address(0), "Customer Address is ZERO_ADDRESS.");
        require(_addresses[1] != address(0), "Beneficiary Address is ZERO_ADDRESS.");
        require(_addresses[2] != address(0), "Treasury Address is ZERO_ADDRESS.");

        require(_fiatAmountInCents > 0, "Payment amount in fiat is zero.");
        require(_frequency > 0, "Payment frequency is zero.");
        require(_numberOfPayments > 0, "Payment number of payments is zero.");
        require(_startTimestamp > 0, "Payment start time is zero.");

        require(_fiatAmountInCents <= OVERFLOW_LIMITER_NUMBER, "Payment amount is higher than the overflow limit.");
        require(_frequency <= OVERFLOW_LIMITER_NUMBER, "Payment frequency is higher than the overflow limit.");
        require(_numberOfPayments <= OVERFLOW_LIMITER_NUMBER, "Payment number of payments is higher than the overflow limit.");
        require(_startTimestamp <= OVERFLOW_LIMITER_NUMBER, "Payment start time is higher than the overflow limit.");

        pullPayments[_addresses[0]][_addresses[1]].currency = _currency;
        pullPayments[_addresses[0]][_addresses[1]].initialPaymentAmountInCents = _initialPaymentAmountInCents;
        pullPayments[_addresses[0]][_addresses[1]].fiatAmountInCents = _fiatAmountInCents;
        pullPayments[_addresses[0]][_addresses[1]].frequency = _frequency;
        pullPayments[_addresses[0]][_addresses[1]].startTimestamp = _startTimestamp;
        pullPayments[_addresses[0]][_addresses[1]].numberOfPayments = _numberOfPayments;
        pullPayments[_addresses[0]][_addresses[1]].paymentID = _ids[0];
        pullPayments[_addresses[0]][_addresses[1]].businessID = _ids[1];
        pullPayments[_addresses[0]][_addresses[1]].uniqueReferenceID = _uniqueReferenceID;
        pullPayments[_addresses[0]][_addresses[1]].treasuryAddress = _addresses[2];

        require(isValidRegistration(
                v,
                r,
                s,
                _addresses[0],
                _addresses[1],
                pullPayments[_addresses[0]][_addresses[1]]),
            "Invalid pull payment registration - ECRECOVER_FAILED"
        );

        pullPayments[_addresses[0]][_addresses[1]].nextPaymentTimestamp = _startTimestamp;
        pullPayments[_addresses[0]][_addresses[1]].lastPaymentTimestamp = 0;
        pullPayments[_addresses[0]][_addresses[1]].cancelTimestamp = 0;

        if (isFundingNeeded(msg.sender)) {
            msg.sender.transfer(FUNDING_AMOUNT);

            emit LogSmartContractActorFunded("executor", msg.sender, now);
        }

        emit LogPaymentRegistered(_addresses[0], _ids[0], _ids[1], _uniqueReferenceID);
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
            pullPayments[_customerAddress][_pullPaymentExecutor].businessID,
            pullPayments[_customerAddress][_pullPaymentExecutor].uniqueReferenceID
        );
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function executePullPayment(address _customerAddress, bytes32 _paymentID, uint256 _paymentNumber)
    public
    paymentExists(_customerAddress, msg.sender)
    isValidPullPaymentExecutionRequest(_customerAddress, msg.sender, _paymentID, _paymentNumber)
    {
        uint256 amountInPMA;
        address customerAddress = _customerAddress;
        uint256 initialAmountInCents = pullPayments[customerAddress][msg.sender].initialPaymentAmountInCents;
        string memory currency = pullPayments[customerAddress][msg.sender].currency;

        if (initialAmountInCents > 0) {
            amountInPMA = calculatePMAFromFiat(initialAmountInCents, currency);

            pullPayments[customerAddress][msg.sender].initialPaymentAmountInCents = 0;
        } else {
            amountInPMA = calculatePMAFromFiat(pullPayments[customerAddress][msg.sender].fiatAmountInCents, currency);

            pullPayments[customerAddress][msg.sender].nextPaymentTimestamp =
            pullPayments[customerAddress][msg.sender].nextPaymentTimestamp + pullPayments[customerAddress][msg.sender].frequency;
            pullPayments[customerAddress][msg.sender].numberOfPayments = pullPayments[customerAddress][msg.sender].numberOfPayments - 1;
        }

        pullPayments[customerAddress][msg.sender].lastPaymentTimestamp = now;
        token.transferFrom(
            customerAddress,
            pullPayments[customerAddress][msg.sender].treasuryAddress,
            amountInPMA
        );

        emit LogPullPaymentExecuted(
            customerAddress,
            pullPayments[customerAddress][msg.sender].paymentID,
            pullPayments[customerAddress][msg.sender].businessID,
            pullPayments[customerAddress][msg.sender].uniqueReferenceID,
            amountInPMA,
            conversionRates[currency]
        );
    }

    function getRate(string memory _currency) public view returns (uint256) {
        return conversionRates[_currency];
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function calculatePMAFromFiat(uint256 _fiatAmountInCents, string memory _currency)
    internal
    view
    validConversionRate(_currency)
    validAmount(_fiatAmountInCents)
    returns (uint256) {
        return RATE_CALCULATION_NUMBER.mul(_fiatAmountInCents).div(conversionRates[_currency]);
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
                    _pullPayment.paymentID,
                    _pullPayment.businessID,
                    _pullPayment.uniqueReferenceID,
                    _pullPayment.treasuryAddress,
                    _pullPayment.currency,
                    _pullPayment.initialPaymentAmountInCents,
                    _pullPayment.fiatAmountInCents,
                    _pullPayment.frequency,
                    _pullPayment.numberOfPayments,
                    _pullPayment.startTimestamp
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
            abi.encodePacked(pullPayments[_customerAddress][_pullPaymentExecutor].paymentID)
        ) == keccak256(abi.encodePacked(_paymentID)
        );
    }

     
     
     
     
    function doesPaymentExist(address _customerAddress, address _pullPaymentExecutor)
    internal
    view
    returns (bool) {
        return (
        bytes(pullPayments[_customerAddress][_pullPaymentExecutor].currency).length > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].fiatAmountInCents > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].frequency > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].startTimestamp > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].numberOfPayments > 0 &&
        pullPayments[_customerAddress][_pullPaymentExecutor].nextPaymentTimestamp > 0
        );
    }

     
     
     
     
    function isFundingNeeded(address _address)
    private
    view
    returns (bool) {
        return address(_address).balance <= MINIMUM_AMOUNT_OF_ETH_FOR_OPERATORS;
    }
}