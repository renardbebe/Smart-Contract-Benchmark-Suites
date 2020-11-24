 

pragma solidity 0.4.25;

 

 
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

 

 
contract Adminable is Claimable {
    address[] public adminArray;

    struct AdminInfo {
        bool valid;
        uint256 index;
    }

    mapping(address => AdminInfo) public adminTable;

    event AdminAccepted(address indexed _admin);
    event AdminRejected(address indexed _admin);

     
    modifier onlyAdmin() {
        require(adminTable[msg.sender].valid, "caller is illegal");
        _;
    }

     
    function accept(address _admin) external onlyOwner {
        require(_admin != address(0), "administrator is illegal");
        AdminInfo storage adminInfo = adminTable[_admin];
        require(!adminInfo.valid, "administrator is already accepted");
        adminInfo.valid = true;
        adminInfo.index = adminArray.length;
        adminArray.push(_admin);
        emit AdminAccepted(_admin);
    }

     
    function reject(address _admin) external onlyOwner {
        AdminInfo storage adminInfo = adminTable[_admin];
        require(adminArray.length > adminInfo.index, "administrator is already rejected");
        require(_admin == adminArray[adminInfo.index], "administrator is already rejected");
         
        address lastAdmin = adminArray[adminArray.length - 1];  
        adminTable[lastAdmin].index = adminInfo.index;
        adminArray[adminInfo.index] = lastAdmin;
        adminArray.length -= 1;  
        delete adminTable[_admin];
        emit AdminRejected(_admin);
    }

     
    function getAdminArray() external view returns (address[] memory) {
        return adminArray;
    }

     
    function getAdminCount() external view returns (uint256) {
        return adminArray.length;
    }
}

 

 
interface ITransactionLimiter {
     
    function resetTotal() external;

     
    function incTotalBuy(uint256 _amount) external;

     
    function incTotalSell(uint256 _amount) external;
}

 

 
interface IETHConverter {
     
    function toSdrAmount(uint256 _ethAmount) external view returns (uint256);

     
    function toEthAmount(uint256 _sdrAmount) external view returns (uint256);

     
    function fromEthAmount(uint256 _ethAmount) external view returns (uint256);
}

 

 
interface IRateApprover {
     
    function approveRate(uint256 _highRateN, uint256 _highRateD, uint256 _lowRateN, uint256 _lowRateD) external view  returns (bool, string);
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

 

 

 
contract ETHConverter is IETHConverter, ContractAddressLocatorHolder, Adminable {
    string public constant VERSION = "1.0.0";

    using SafeMath for uint256;

     
    uint256 public constant MAX_RESOLUTION = 0x10000000000000000;

    uint256 public sequenceNum = 0;
    uint256 public highPriceN = 0;
    uint256 public highPriceD = 0;
    uint256 public lowPriceN = 0;
    uint256 public lowPriceD = 0;

    event PriceSaved(uint256 _highPriceN, uint256 _highPriceD, uint256 _lowPriceN, uint256 _lowPriceD);
    event PriceNotSaved(uint256 _highPriceN, uint256 _highPriceD, uint256 _lowPriceN, uint256 _lowPriceD);

     
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

     
    function getTransactionLimiter() public view returns (ITransactionLimiter) {
        return ITransactionLimiter(getContractAddress(_ITransactionLimiter_));
    }

     
    function getRateApprover() public view returns (IRateApprover) {
        return IRateApprover(getContractAddress(_IRateApprover_));
    }

     
    modifier onlyIfHighPriceSet() {
        assert(highPriceN > 0 && highPriceD > 0);
        _;
    }

     
    modifier onlyIfLowPriceSet() {
        assert(lowPriceN > 0 && lowPriceD > 0);
        _;
    }

     
    function setPrice(uint256 _sequenceNum, uint256 _highPriceN, uint256 _highPriceD, uint256 _lowPriceN, uint256 _lowPriceD) external onlyAdmin  {
        require(1 <= _highPriceN && _highPriceN <= MAX_RESOLUTION, "high price numerator is out of range");
        require(1 <= _highPriceD && _highPriceD <= MAX_RESOLUTION, "high price denominator is out of range");
        require(1 <= _lowPriceN && _lowPriceN <= MAX_RESOLUTION, "low price numerator is out of range");
        require(1 <= _lowPriceD && _lowPriceD <= MAX_RESOLUTION, "low price denominator is out of range");
        require(_highPriceN * _lowPriceD >= _highPriceD * _lowPriceN, "high price is smaller than low price"); 

        (bool success, string memory reason) = getRateApprover().approveRate(_highPriceN, _highPriceD, _lowPriceN, _lowPriceD);
        require(success, reason);

        if (sequenceNum < _sequenceNum) {
            sequenceNum = _sequenceNum;
            highPriceN = _highPriceN;
            highPriceD = _highPriceD;
            lowPriceN = _lowPriceN;
            lowPriceD = _lowPriceD;
            getTransactionLimiter().resetTotal();
            emit PriceSaved(_highPriceN, _highPriceD, _lowPriceN, _lowPriceD);
        }
        else {
            emit PriceNotSaved(_highPriceN, _highPriceD, _lowPriceN, _lowPriceD);
        }
    }

     
    function toSdrAmount(uint256 _ethAmount) external view onlyIfLowPriceSet returns (uint256) {
        return _ethAmount.mul(lowPriceN) / lowPriceD;
    }

     
    function toEthAmount(uint256 _sdrAmount) external view onlyIfHighPriceSet returns (uint256) {
        return _sdrAmount.mul(highPriceD) / highPriceN;
    }

     
    function fromEthAmount(uint256 _ethAmount) external view onlyIfHighPriceSet returns (uint256) {
        return _ethAmount.mul(highPriceN) / highPriceD;
    }
}