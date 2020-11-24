 

 
 
pragma solidity 0.4.24;


 
contract ReentrancyGuard {

   
   
  uint private constant REENTRANCY_GUARD_FREE = 1;

   
  uint private constant REENTRANCY_GUARD_LOCKED = 2;

   
  uint private reentrancyLock = REENTRANCY_GUARD_FREE;

   
  modifier nonReentrant() {
    require(reentrancyLock == REENTRANCY_GUARD_FREE);
    reentrancyLock = REENTRANCY_GUARD_LOCKED;
    _;
    reentrancyLock = REENTRANCY_GUARD_FREE;
  }

}

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract GasTracker {
    uint internal gasUsed;

    modifier tracksGas() {
         
        gasUsed = gasleft() + 21000;

        _;  

        gasUsed = 0;  
    }
}

contract BZxEvents {

    event LogLoanAdded (
        bytes32 indexed loanOrderHash,
        address adder,
        address indexed maker,
        address indexed feeRecipientAddress,
        uint lenderRelayFee,
        uint traderRelayFee,
        uint maxDuration,
        uint makerRole
    );

    event LogLoanTaken (
        address indexed lender,
        address indexed trader,
        address collateralTokenAddressFilled,
        address positionTokenAddressFilled,
        uint loanTokenAmountFilled,
        uint collateralTokenAmountFilled,
        uint positionTokenAmountFilled,
        uint loanStartUnixTimestampSec,
        bool active,
        bytes32 indexed loanOrderHash
    );

    event LogLoanCancelled(
        address indexed maker,
        uint cancelLoanTokenAmount,
        uint remainingLoanTokenAmount,
        bytes32 indexed loanOrderHash
    );

    event LogLoanClosed(
        address indexed lender,
        address indexed trader,
        address loanCloser,
        bool isLiquidation,
        bytes32 indexed loanOrderHash
    );

    event LogPositionTraded(
        bytes32 indexed loanOrderHash,
        address indexed trader,
        address sourceTokenAddress,
        address destTokenAddress,
        uint sourceTokenAmount,
        uint destTokenAmount
    );

    event LogMarginLevels(
        bytes32 indexed loanOrderHash,
        address indexed trader,
        uint initialMarginAmount,
        uint maintenanceMarginAmount,
        uint currentMarginAmount
    );

    event LogWithdrawProfit(
        bytes32 indexed loanOrderHash,
        address indexed trader,
        uint profitWithdrawn,
        uint remainingPosition
    );

    event LogPayInterestForOrder(
        bytes32 indexed loanOrderHash,
        address indexed lender,
        uint amountPaid,
        uint totalAccrued,
        uint loanCount
    );

    event LogPayInterestForPosition(
        bytes32 indexed loanOrderHash,
        address indexed lender,
        address indexed trader,
        uint amountPaid,
        uint totalAccrued
    );

    event LogChangeTraderOwnership(
        bytes32 indexed loanOrderHash,
        address indexed oldOwner,
        address indexed newOwner
    );

    event LogChangeLenderOwnership(
        bytes32 indexed loanOrderHash,
        address indexed oldOwner,
        address indexed newOwner
    );

    event LogIncreasedLoanableAmount(
        bytes32 indexed loanOrderHash,
        address indexed lender,
        uint loanTokenAmountAdded,
        uint loanTokenAmountFillable
    );
}

contract BZxObjects {

    struct ListIndex {
        uint index;
        bool isSet;
    }

    struct LoanOrder {
        address loanTokenAddress;
        address interestTokenAddress;
        address collateralTokenAddress;
        address oracleAddress;
        uint loanTokenAmount;
        uint interestAmount;
        uint initialMarginAmount;
        uint maintenanceMarginAmount;
        uint maxDurationUnixTimestampSec;
        bytes32 loanOrderHash;
    }

    struct LoanOrderAux {
        address maker;
        address feeRecipientAddress;
        uint lenderRelayFee;
        uint traderRelayFee;
        uint makerRole;
        uint expirationUnixTimestampSec;
    }

    struct LoanPosition {
        address trader;
        address collateralTokenAddressFilled;
        address positionTokenAddressFilled;
        uint loanTokenAmountFilled;
        uint loanTokenAmountUsed;
        uint collateralTokenAmountFilled;
        uint positionTokenAmountFilled;
        uint loanStartUnixTimestampSec;
        uint loanEndUnixTimestampSec;
        bool active;
    }

    struct PositionRef {
        bytes32 loanOrderHash;
        uint positionId;
    }

    struct InterestData {
        address lender;
        address interestTokenAddress;
        uint interestTotalAccrued;
        uint interestPaidSoFar;
    }

}

contract BZxStorage is BZxObjects, BZxEvents, ReentrancyGuard, Ownable, GasTracker {
    uint internal constant MAX_UINT = 2**256 - 1;

    address public bZRxTokenContract;
    address public vaultContract;
    address public oracleRegistryContract;
    address public bZxTo0xContract;
    address public bZxTo0xV2Contract;
    bool public DEBUG_MODE = false;

     
    mapping (bytes32 => LoanOrder) public orders;  
    mapping (bytes32 => LoanOrderAux) public orderAux;  
    mapping (bytes32 => uint) public orderFilledAmounts;  
    mapping (bytes32 => uint) public orderCancelledAmounts;  
    mapping (bytes32 => address) public orderLender;  

     
    mapping (uint => LoanPosition) public loanPositions;  
    mapping (bytes32 => mapping (address => uint)) public loanPositionsIds;  

     
    mapping (address => bytes32[]) public orderList;  
    mapping (bytes32 => mapping (address => ListIndex)) public orderListIndex;  

    mapping (bytes32 => uint[]) public orderPositionList;  

    PositionRef[] public positionList;  
    mapping (uint => ListIndex) public positionListIndex;  

     
    mapping (bytes32 => mapping (uint => uint)) public interestPaid;  
    mapping (address => address) public oracleAddresses;  
    mapping (bytes32 => mapping (address => bool)) public preSigned;  
    mapping (address => mapping (address => bool)) public allowedValidators;  
}

contract BZxProxiable {
    mapping (bytes4 => address) public targets;

    mapping (bytes4 => bool) public targetIsPaused;

    function initialize(address _target) public;
}

contract BZxProxy is BZxStorage, BZxProxiable {
    
    constructor(
        address _settings) 
        public
    {
        require(_settings.delegatecall(bytes4(keccak256("initialize(address)")), _settings), "BZxProxy::constructor: failed");
    }
    
    function() 
        payable 
        public
    {
        require(!targetIsPaused[msg.sig], "BZxProxy::Function temporarily paused");

        address target = targets[msg.sig];
        require(target != address(0), "BZxProxy::Target not found");

        bytes memory data = msg.data;
        assembly {
            let result := delegatecall(gas, target, add(data, 0x20), mload(data), 0, 0)
            let size := returndatasize
            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)
            switch result
            case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function initialize(
        address)
        public
    {
        revert();
    }
}