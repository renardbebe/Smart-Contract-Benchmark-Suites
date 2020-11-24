 

pragma solidity 0.4.25;

 

 
interface IPaymentHandler {
     
    function getEthBalance() external view returns (uint256);

     
    function transferEthToSgaHolder(address _to, uint256 _value) external;
}

 

 
interface IMintListener {
     
    function mintSgaForSgnHolders(uint256 _value) external;
}

 

 
interface ISGATokenManager {
     
    function exchangeEthForSga(address _sender, uint256 _ethAmount) external returns (uint256);

     
    function exchangeSgaForEth(address _sender, uint256 _sgaAmount) external returns (uint256);

     
    function uponTransfer(address _sender, address _to, uint256 _value) external;

     
    function uponTransferFrom(address _sender, address _from, address _to, uint256 _value) external;

     
    function uponDeposit(address _sender, uint256 _balance, uint256 _amount) external returns (address, uint256);

     
    function uponWithdraw(address _sender, uint256 _balance) external returns (address, uint256);

     
    function uponMintSgaForSgnHolders(uint256 _value) external;

     
    function uponTransferSgaToSgnHolder(address _to, uint256 _value) external;

     
    function postTransferEthToSgaHolder(address _to, uint256 _value, bool _status) external;

     
    function getDepositParams() external view returns (address, uint256);

     
    function getWithdrawParams() external view returns (address, uint256);
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

 

 
interface ISagaExchanger {
     
    function transferSgaToSgnHolder(address _to, uint256 _value) external;
}

 

 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
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

 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
}

 

 

 
contract SGAToken is ERC20, ContractAddressLocatorHolder, IMintListener, ISagaExchanger, IPaymentHandler {
    string public constant VERSION = "1.0.0";

    string public constant name = "Saga";
    string public constant symbol = "SGA";
    uint8  public constant decimals = 18;

     
    address public constant SGA_MINTED_FOR_SGN_HOLDERS = address(keccak256("SGA_MINTED_FOR_SGN_HOLDERS"));

     
    constructor(IContractAddressLocator _contractAddressLocator) ContractAddressLocatorHolder(_contractAddressLocator) public {}

     
    function getSGATokenManager() public view returns (ISGATokenManager) {
        return ISGATokenManager(getContractAddress(_ISGATokenManager_));
    }

     
    function() external payable {
        uint256 amount = getSGATokenManager().exchangeEthForSga(msg.sender, msg.value);
        _mint(msg.sender, amount);
    }

     
    function exchange() external payable {
        uint256 amount = getSGATokenManager().exchangeEthForSga(msg.sender, msg.value);
        _mint(msg.sender, amount);
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        if (_to == address(this)) {
            uint256 amount = getSGATokenManager().exchangeSgaForEth(msg.sender, _value);
            _burn(msg.sender, _value);
            msg.sender.transfer(amount);
            return true;
        }
        getSGATokenManager().uponTransfer(msg.sender, _to, _value);
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(this), "custodian-transfer of SGA into this contract is illegal");
        getSGATokenManager().uponTransferFrom(msg.sender, _from, _to, _value);
        return super.transferFrom(_from, _to, _value);
    }

     
    function deposit() external payable {
        getSGATokenManager().uponDeposit(msg.sender, address(this).balance, msg.value);
    }

     
    function withdraw() external {
        (address wallet, uint256 amount) = getSGATokenManager().uponWithdraw(msg.sender, address(this).balance);
        wallet.transfer(amount);
    }

     
    function mintSgaForSgnHolders(uint256 _value) external only(_IMintManager_) {
        getSGATokenManager().uponMintSgaForSgnHolders(_value);
        _mint(SGA_MINTED_FOR_SGN_HOLDERS, _value);
    }

     
    function transferSgaToSgnHolder(address _to, uint256 _value) external only(_ISGNToken_) {
        getSGATokenManager().uponTransferSgaToSgnHolder(_to, _value);
        _transfer(SGA_MINTED_FOR_SGN_HOLDERS, _to, _value);
    }

     
    function transferEthToSgaHolder(address _to, uint256 _value) external only(_IPaymentManager_) {
        bool status = _to.send(_value);
        getSGATokenManager().postTransferEthToSgaHolder(_to, _value, status);
    }

     
    function getEthBalance() external view returns (uint256) {
        return address(this).balance;
    }

     
    function getDepositParams() external view returns (address, uint256) {
        return getSGATokenManager().getDepositParams();
    }

     
    function getWithdrawParams() external view returns (address, uint256) {
        return getSGATokenManager().getWithdrawParams();
    }
}