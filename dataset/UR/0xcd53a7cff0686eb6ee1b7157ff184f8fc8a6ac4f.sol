 

pragma solidity 0.4.25;

 

 
interface IReserveManager {
     
    function getDepositParams(uint256 _balance) external view returns (address, uint256);

     
    function getWithdrawParams(uint256 _balance) external view returns (address, uint256);
}

 

 
interface IPaymentManager {
     
    function getNumOfPayments() external view returns (uint256);

     
    function getPaymentsSum() external view returns (uint256);

     
    function computeDifferPayment(uint256 _ethAmount, uint256 _ethBalance) external view returns (uint256);

     
    function registerDifferPayment(address _wallet, uint256 _ethAmount) external;
}

 

 
interface IETHConverter {
     
    function toSdrAmount(uint256 _ethAmount) external view returns (uint256);

     
    function toEthAmount(uint256 _sdrAmount) external view returns (uint256);

     
    function fromEthAmount(uint256 _ethAmount) external view returns (uint256);
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

 

 

 
contract ReserveManager is IReserveManager, ContractAddressLocatorHolder, Claimable {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

    struct Wallets {
        address deposit;
        address withdraw;
    }

    struct Thresholds {
        uint256 min;
        uint256 max;
        uint256 mid;
    }

    Wallets public wallets;

    Thresholds public thresholds;

    uint256 public walletsSequenceNum = 0;
    uint256 public thresholdsSequenceNum = 0;

    event ReserveWalletsSaved(address _deposit, address _withdraw);
    event ReserveWalletsNotSaved(address _deposit, address _withdraw);
    event ReserveThresholdsSaved(uint256 _min, uint256 _max, uint256 _mid);
    event ReserveThresholdsNotSaved(uint256 _min, uint256 _max, uint256 _mid);

     
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

     
    function getETHConverter() public view returns (IETHConverter) {
        return IETHConverter(getContractAddress(_IETHConverter_));
    }

     
    function getPaymentManager() public view returns (IPaymentManager) {
        return IPaymentManager(getContractAddress(_IPaymentManager_));
    }

     
    function setWallets(uint256 _walletsSequenceNum, address _deposit, address _withdraw) external onlyOwner {
        require(_deposit != address(0), "deposit-wallet is illegal");
        require(_withdraw != address(0), "withdraw-wallet is illegal");

        if (walletsSequenceNum < _walletsSequenceNum) {
            walletsSequenceNum = _walletsSequenceNum;
            wallets.deposit = _deposit;
            wallets.withdraw = _withdraw;

            emit ReserveWalletsSaved(_deposit, _withdraw);
        }
        else {
            emit ReserveWalletsNotSaved(_deposit, _withdraw);
        }
    }

     
    function setThresholds(uint256 _thresholdsSequenceNum, uint256 _min, uint256 _max, uint256 _mid) external onlyOwner {
        require(_min <= _mid, "min-threshold is greater than mid-threshold");
        require(_max >= _mid, "max-threshold is smaller than mid-threshold");

        if (thresholdsSequenceNum < _thresholdsSequenceNum) {
            thresholdsSequenceNum = _thresholdsSequenceNum;
            thresholds.min = _min;
            thresholds.max = _max;
            thresholds.mid = _mid;

            emit ReserveThresholdsSaved(_min, _max, _mid);
        }
        else {
            emit ReserveThresholdsNotSaved(_min, _max, _mid);
        }
    }

     
    function getDepositParams(uint256 _balance) external view returns (address, uint256) {
        uint256 depositRecommendation = 0;
        uint256 sdrPaymentsSum = getPaymentManager().getPaymentsSum();
        uint256 ethPaymentsSum = getETHConverter().toEthAmount(sdrPaymentsSum);
        if (ethPaymentsSum >= _balance || (_balance - ethPaymentsSum) <= thresholds.min){ 
             
            depositRecommendation = (thresholds.mid).add(ethPaymentsSum) - _balance; 
        }
        return (wallets.deposit, depositRecommendation);
    }

     
    function getWithdrawParams(uint256 _balance) external view returns (address, uint256) {
        uint256 withdrawRecommendationAmount = 0;
        if (_balance >= thresholds.max && getPaymentManager().getNumOfPayments() == 0){ 
            withdrawRecommendationAmount = _balance - thresholds.mid;  
        }

        return (wallets.withdraw, withdrawRecommendationAmount);
    }
}