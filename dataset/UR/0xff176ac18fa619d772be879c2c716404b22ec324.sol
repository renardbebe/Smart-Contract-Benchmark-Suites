 

pragma solidity 0.4.25;

 

 
interface IPaymentQueue {
     
    function getNumOfPayments() external view returns (uint256);

     
    function getPaymentsSum() external view returns (uint256);

     
    function getPayment(uint256 _index) external view returns (address, uint256);

     
    function addPayment(address _wallet, uint256 _amount) external;

     
    function updatePayment(uint256 _amount) external;

     
    function removePayment() external;
}

 

 
interface IPaymentManager {
     
    function getNumOfPayments() external view returns (uint256);

     
    function getPaymentsSum() external view returns (uint256);

     
    function computeDifferPayment(uint256 _ethAmount, uint256 _ethBalance) external view returns (uint256);

     
    function registerDifferPayment(address _wallet, uint256 _ethAmount) external;
}

 

 
interface IPaymentHandler {
     
    function getEthBalance() external view returns (uint256);

     
    function transferEthToSgaHolder(address _to, uint256 _value) external;
}

 

 
interface IETHConverter {
     
    function toSdrAmount(uint256 _ethAmount) external view returns (uint256);

     
    function toEthAmount(uint256 _sdrAmount) external view returns (uint256);

     
    function fromEthAmount(uint256 _ethAmount) external view returns (uint256);
}

 

 
interface ISGAAuthorizationManager {
     
    function isAuthorizedToBuy(address _sender) external view returns (bool);

     
    function isAuthorizedToSell(address _sender) external view returns (bool);

     
    function isAuthorizedToTransfer(address _sender, address _target) external view returns (bool);

     
    function isAuthorizedToTransferFrom(address _sender, address _source, address _target) external view returns (bool);

     
    function isAuthorizedForPublicOperation(address _sender) external view returns (bool);
}

 

 
interface IContractAddressLocator {
     
    function getContractAddress(bytes32 _identifier) external view returns (address);

     
    function isContractAddressRelates(address _contractAddress, bytes32[] _identifiers) external view returns (bool);
}

 

 
contract ContractAddressLocatorHolder {
    bytes32 internal constant _IAuthorizationDataSource_ = "IAuthorizationDataSource";
    bytes32 internal constant _ISGNConversionManager_    = "ISGNConversionManager"      ;
    bytes32 internal constant _IModelDataSource_         = "IModelDataSource"        ;
    bytes32 internal constant _IPaymentHandler_          = "IPaymentHandler"            ;
    bytes32 internal constant _IPaymentManager_          = "IPaymentManager"            ;
    bytes32 internal constant _IPaymentQueue_            = "IPaymentQueue"              ;
    bytes32 internal constant _IReconciliationAdjuster_  = "IReconciliationAdjuster"      ;
    bytes32 internal constant _IIntervalIterator_        = "IIntervalIterator"       ;
    bytes32 internal constant _IMintHandler_             = "IMintHandler"            ;
    bytes32 internal constant _IMintListener_            = "IMintListener"           ;
    bytes32 internal constant _IMintManager_             = "IMintManager"            ;
    bytes32 internal constant _IPriceBandCalculator_     = "IPriceBandCalculator"       ;
    bytes32 internal constant _IModelCalculator_         = "IModelCalculator"        ;
    bytes32 internal constant _IRedButton_               = "IRedButton"              ;
    bytes32 internal constant _IReserveManager_          = "IReserveManager"         ;
    bytes32 internal constant _ISagaExchanger_           = "ISagaExchanger"          ;
    bytes32 internal constant _IMonetaryModel_               = "IMonetaryModel"              ;
    bytes32 internal constant _IMonetaryModelState_          = "IMonetaryModelState"         ;
    bytes32 internal constant _ISGAAuthorizationManager_ = "ISGAAuthorizationManager";
    bytes32 internal constant _ISGAToken_                = "ISGAToken"               ;
    bytes32 internal constant _ISGATokenManager_         = "ISGATokenManager"        ;
    bytes32 internal constant _ISGNAuthorizationManager_ = "ISGNAuthorizationManager";
    bytes32 internal constant _ISGNToken_                = "ISGNToken"               ;
    bytes32 internal constant _ISGNTokenManager_         = "ISGNTokenManager"        ;
    bytes32 internal constant _IMintingPointTimersManager_             = "IMintingPointTimersManager"            ;
    bytes32 internal constant _ITradingClasses_          = "ITradingClasses"         ;
    bytes32 internal constant _IWalletsTradingLimiterValueConverter_        = "IWalletsTLValueConverter"       ;
    bytes32 internal constant _IWalletsTradingDataSource_       = "IWalletsTradingDataSource"      ;
    bytes32 internal constant _WalletsTradingLimiter_SGNTokenManager_          = "WalletsTLSGNTokenManager"         ;
    bytes32 internal constant _WalletsTradingLimiter_SGATokenManager_          = "WalletsTLSGATokenManager"         ;
    bytes32 internal constant _IETHConverter_             = "IETHConverter"   ;
    bytes32 internal constant _ITransactionLimiter_      = "ITransactionLimiter"     ;
    bytes32 internal constant _ITransactionManager_      = "ITransactionManager"     ;
    bytes32 internal constant _IRateApprover_      = "IRateApprover"     ;

    IContractAddressLocator private contractAddressLocator;

     
    constructor(IContractAddressLocator _contractAddressLocator) internal {
        require(_contractAddressLocator != address(0), "locator is illegal");
        contractAddressLocator = _contractAddressLocator;
    }

     
    function getContractAddressLocator() external view returns (IContractAddressLocator) {
        return contractAddressLocator;
    }

     
    function getContractAddress(bytes32 _identifier) internal view returns (address) {
        return contractAddressLocator.getContractAddress(_identifier);
    }



     
    function isSenderAddressRelates(bytes32[] _identifiers) internal view returns (bool) {
        return contractAddressLocator.isContractAddressRelates(msg.sender, _identifiers);
    }

     
    modifier only(bytes32 _identifier) {
        require(msg.sender == getContractAddress(_identifier), "caller is illegal");
        _;
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

 

 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(owner, pendingOwner);
    owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

 
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

 

 

 
contract PaymentManager is IPaymentManager, ContractAddressLocatorHolder, Claimable {
    string public constant VERSION = "1.0.0";

    using Math for uint256;

    uint256 public maxNumOfPaymentsLimit = 30;

    event PaymentRegistered(address indexed _user, uint256 _input, uint256 _output);
    event PaymentSettled(address indexed _user, uint256 _input, uint256 _output);
    event PaymentPartialSettled(address indexed _user, uint256 _input, uint256 _output);

     
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

     
    function getSGAAuthorizationManager() public view returns (ISGAAuthorizationManager) {
        return ISGAAuthorizationManager(getContractAddress(_ISGAAuthorizationManager_));
    }

     
    function getETHConverter() public view returns (IETHConverter) {
        return IETHConverter(getContractAddress(_IETHConverter_));
    }

     
    function getPaymentHandler() public view returns (IPaymentHandler) {
        return IPaymentHandler(getContractAddress(_IPaymentHandler_));
    }

     
    function getPaymentQueue() public view returns (IPaymentQueue) {
        return IPaymentQueue(getContractAddress(_IPaymentQueue_));
    }

     
    function setMaxNumOfPaymentsLimit(uint256 _maxNumOfPaymentsLimit) external onlyOwner {
        require(_maxNumOfPaymentsLimit > 0, "invalid _maxNumOfPaymentsLimit");
        maxNumOfPaymentsLimit = _maxNumOfPaymentsLimit;
    }

     
    function getNumOfPayments() external view returns (uint256) {
        return getPaymentQueue().getNumOfPayments();
    }

     
    function getPaymentsSum() external view returns (uint256) {
        return getPaymentQueue().getPaymentsSum();
    }

     
    function computeDifferPayment(uint256 _ethAmount, uint256 _ethBalance) external view returns (uint256) {
        if (getPaymentQueue().getNumOfPayments() > 0)
            return _ethAmount;
        else if (_ethAmount > _ethBalance)
            return _ethAmount - _ethBalance;  
        else
            return 0;
    }

     
    function registerDifferPayment(address _wallet, uint256 _ethAmount) external only(_ISGATokenManager_) {
        uint256 sdrAmount = getETHConverter().fromEthAmount(_ethAmount);
        getPaymentQueue().addPayment(_wallet, sdrAmount);
        emit PaymentRegistered(_wallet, _ethAmount, sdrAmount);
    }

     
    function settlePayments(uint256 _maxNumOfPayments) external {
        require(getSGAAuthorizationManager().isAuthorizedForPublicOperation(msg.sender), "settle payments is not authorized");
        IETHConverter ethConverter = getETHConverter();
        IPaymentHandler paymentHandler = getPaymentHandler();
        IPaymentQueue paymentQueue = getPaymentQueue();

        uint256 numOfPayments = paymentQueue.getNumOfPayments();
        numOfPayments =  numOfPayments.min(_maxNumOfPayments).min(maxNumOfPaymentsLimit);

        for (uint256 i = 0; i < numOfPayments; i++) {
            (address wallet, uint256 sdrAmount) = paymentQueue.getPayment(0);
            uint256 ethAmount = ethConverter.toEthAmount(sdrAmount);
            uint256 ethBalance = paymentHandler.getEthBalance();
            if (ethAmount > ethBalance) {
                paymentQueue.updatePayment(ethConverter.fromEthAmount(ethAmount - ethBalance));  
                paymentHandler.transferEthToSgaHolder(wallet, ethBalance);
                emit PaymentPartialSettled(wallet, sdrAmount, ethBalance);
                break;
            }
            paymentQueue.removePayment();
            paymentHandler.transferEthToSgaHolder(wallet, ethAmount);
            emit PaymentSettled(wallet, sdrAmount, ethAmount);
        }
    }
}