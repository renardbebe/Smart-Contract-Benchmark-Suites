 

pragma solidity 0.5.11;

 
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

 
 
 
 
 
 
contract SinglePullPayment is PayableOwnable {

    using SafeMath for uint256;
     
     
     

    event LogExecutorAdded(address executor);
    event LogExecutorRemoved(address executor);

    event LogPullPaymentExecuted(
        address customerAddress,
        address receiverAddress,
        uint256 amountInPMA,
        bytes32 paymentID,
        bytes32 businessID,
        string uniqueReferenceID
    );

     
     
     
    bytes32 constant private EMPTY_BYTES32 = "";

     
     
     
    IERC20 public token;
    mapping(address => bool) public executors;
    mapping(bytes32 => PullPayment) public pullPayments;

    struct PullPayment {
        bytes32[2] paymentDetails;               
        uint256 paymentAmount;                   
        address customerAddress;                 
        address receiverAddress;                 
        string uniqueReferenceID;
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
    modifier isValidAddress(address _address) {
        require(_address != address(0), "Invalid address - ZERO_ADDRESS provided");
        _;
    }
    modifier isValidNumber(uint256 _amount) {
        require(_amount > 0, "Invalid amount - Must be higher than zero");
        _;
    }
    modifier isValidByte32(bytes32 _text) {
        require(_text != EMPTY_BYTES32, "Invalid byte32 value.");
        _;
    }
    modifier pullPaymentDoesNotExists(address _customerAddress, bytes32 _paymentID) {
        require(pullPayments[_paymentID].paymentDetails[0] == EMPTY_BYTES32, "Pull payment already exists - Payment ID");
        require(pullPayments[_paymentID].paymentDetails[1] == EMPTY_BYTES32, "Pull payment already exists - Business ID");
        require(pullPayments[_paymentID].paymentAmount == 0, "Pull payment already exists - Payment Amount");
        require(pullPayments[_paymentID].receiverAddress == address(0), "Pull payment already exists - Receiver Address");
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

        emit LogExecutorAdded(_executor);
    }

     
     
    function removeExecutor(address payable _executor)
    public
    onlyOwner
    isValidAddress(_executor)
    executorExists(_executor)
    {
        executors[_executor] = false;

        emit LogExecutorRemoved(_executor);
    }

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
    function registerPullPayment(
        uint8 v,
        bytes32 r,
        bytes32 s,
        bytes32[2] memory _paymentDetails,  
        address[2] memory _addresses,  
        uint256 _paymentAmount,
        string memory _uniqueReferenceID
    )
    public
    isExecutor()
    isValidByte32(_paymentDetails[0])
    isValidByte32(_paymentDetails[1])
    isValidNumber(_paymentAmount)
    isValidAddress(_addresses[0])
    isValidAddress(_addresses[1])
    pullPaymentDoesNotExists(_addresses[0], _paymentDetails[0])
    {
        bytes32[2] memory paymentDetails = _paymentDetails;

        pullPayments[paymentDetails[0]].paymentDetails = _paymentDetails;
        pullPayments[paymentDetails[0]].paymentAmount = _paymentAmount;
        pullPayments[paymentDetails[0]].customerAddress = _addresses[0];
        pullPayments[paymentDetails[0]].receiverAddress = _addresses[1];
        pullPayments[paymentDetails[0]].uniqueReferenceID = _uniqueReferenceID;

        require(isValidRegistration(
                v,
                r,
                s,
                pullPayments[paymentDetails[0]]),
            "Invalid pull payment registration - ECRECOVER_FAILED"
        );

        token.transferFrom(
            _addresses[0],
            _addresses[1],
            _paymentAmount
        );

        emit LogPullPaymentExecuted(
            _addresses[0],
            _addresses[1],
            _paymentAmount,
            paymentDetails[0],
            paymentDetails[1],
            _uniqueReferenceID
        );
    }

     
     
     

     
     
     
     
     
     
     
    function isValidRegistration(
        uint8 v,
        bytes32 r,
        bytes32 s,
        PullPayment memory _pullPayment
    )
    internal
    pure
    returns (bool)
    {
        return ecrecover(
            keccak256(
                abi.encodePacked(
                    _pullPayment.paymentDetails[0],
                    _pullPayment.paymentDetails[1],
                    _pullPayment.paymentAmount,
                    _pullPayment.customerAddress,
                    _pullPayment.receiverAddress,
                    _pullPayment.uniqueReferenceID
                )
            ),
            v, r, s) == _pullPayment.customerAddress;
    }
}