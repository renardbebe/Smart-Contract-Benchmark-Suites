 

pragma solidity 0.5.8;

 
contract Proxy {
     
    function _implementation() internal view returns(address);

     
    function _fallback() internal {
        _delegate(_implementation());
    }

     
    function _delegate(address implementation) internal {
         
        assembly {
             
             
             
            calldatacopy(0, 0, calldatasize)
             
             
            let result := delegatecall(gas, implementation, 0, calldatasize, 0, 0)
             
            returndatacopy(0, 0, returndatasize)
            switch result
             
            case 0 { revert(0, returndatasize) }
            default { return(0, returndatasize) }
        }
    }

    function() external payable {
        _fallback();
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
contract UpgradeabilityProxy is Proxy {
     
    string internal __version;

     
    address internal __implementation;

     
    event Upgraded(string _newVersion, address indexed _newImplementation);

     
    function _upgradeTo(string memory _newVersion, address _newImplementation) internal {
        require(
            __implementation != _newImplementation && _newImplementation != address(0),
            "Old address is not allowed and implementation address should not be 0x"
        );
        require(Address.isContract(_newImplementation), "Cannot set a proxy implementation to a non-contract address");
        require(bytes(_newVersion).length > 0, "Version should not be empty string");
        require(keccak256(abi.encodePacked(__version)) != keccak256(abi.encodePacked(_newVersion)), "New version equals to current");
        __version = _newVersion;
        __implementation = _newImplementation;
        emit Upgraded(_newVersion, _newImplementation);
    }

}

 
contract OwnedUpgradeabilityProxy is UpgradeabilityProxy {
     
    address private __upgradeabilityOwner;

     
    event ProxyOwnershipTransferred(address _previousOwner, address _newOwner);

     
    modifier ifOwner() {
        if (msg.sender == _upgradeabilityOwner()) {
            _;
        } else {
            _fallback();
        }
    }

     
    constructor() public {
        _setUpgradeabilityOwner(msg.sender);
    }

     
    function _upgradeabilityOwner() internal view returns(address) {
        return __upgradeabilityOwner;
    }

     
    function _setUpgradeabilityOwner(address _newUpgradeabilityOwner) internal {
        require(_newUpgradeabilityOwner != address(0), "Address should not be 0x");
        __upgradeabilityOwner = _newUpgradeabilityOwner;
    }

     
    function _implementation() internal view returns(address) {
        return __implementation;
    }

     
    function proxyOwner() external ifOwner returns(address) {
        return _upgradeabilityOwner();
    }

     
    function version() external ifOwner returns(string memory) {
        return __version;
    }

     
    function implementation() external ifOwner returns(address) {
        return _implementation();
    }

     
    function transferProxyOwnership(address _newOwner) external ifOwner {
        require(_newOwner != address(0), "Address should not be 0x");
        emit ProxyOwnershipTransferred(_upgradeabilityOwner(), _newOwner);
        _setUpgradeabilityOwner(_newOwner);
    }

     
    function upgradeTo(string calldata _newVersion, address _newImplementation) external ifOwner {
        _upgradeTo(_newVersion, _newImplementation);
    }

     
    function upgradeToAndCall(string calldata _newVersion, address _newImplementation, bytes calldata _data) external payable ifOwner {
        _upgradeToAndCall(_newVersion, _newImplementation, _data);
    }

    function _upgradeToAndCall(string memory _newVersion, address _newImplementation, bytes memory _data) internal {
        _upgradeTo(_newVersion, _newImplementation);
        bool success;
         
        (success, ) = address(this).call.value(msg.value)(_data);
        require(success, "Fail in executing the function of implementation contract");
    }

}

 

contract OZStorage {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply;

     
    uint256 private _guardCounter;

    function totalSupply() internal view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _investor) internal view returns(uint256) {
        return _balances[_investor];
    }

    function _allowance(address owner, address spender) internal view returns(uint256) {
        return _allowed[owner][spender];
    }

}

interface IDataStore {
     
    function setSecurityToken(address _securityToken) external;

     
    function setUint256(bytes32 _key, uint256 _data) external;

    function setBytes32(bytes32 _key, bytes32 _data) external;

    function setAddress(bytes32 _key, address _data) external;

    function setString(bytes32 _key, string calldata _data) external;

    function setBytes(bytes32 _key, bytes calldata _data) external;

    function setBool(bytes32 _key, bool _data) external;

     
    function setUint256Array(bytes32 _key, uint256[] calldata _data) external;

    function setBytes32Array(bytes32 _key, bytes32[] calldata _data) external ;

    function setAddressArray(bytes32 _key, address[] calldata _data) external;

    function setBoolArray(bytes32 _key, bool[] calldata _data) external;

     
    function insertUint256(bytes32 _key, uint256 _data) external;

    function insertBytes32(bytes32 _key, bytes32 _data) external;

    function insertAddress(bytes32 _key, address _data) external;

    function insertBool(bytes32 _key, bool _data) external;

     
    function deleteUint256(bytes32 _key, uint256 _index) external;

    function deleteBytes32(bytes32 _key, uint256 _index) external;

    function deleteAddress(bytes32 _key, uint256 _index) external;

    function deleteBool(bytes32 _key, uint256 _index) external;

     
    function setUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function setBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function setAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function setBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

     
    function insertUint256Multi(bytes32[] calldata _keys, uint256[] calldata _data) external;

    function insertBytes32Multi(bytes32[] calldata _keys, bytes32[] calldata _data) external;

    function insertAddressMulti(bytes32[] calldata _keys, address[] calldata _data) external;

    function insertBoolMulti(bytes32[] calldata _keys, bool[] calldata _data) external;

    function getUint256(bytes32 _key) external view returns(uint256);

    function getBytes32(bytes32 _key) external view returns(bytes32);

    function getAddress(bytes32 _key) external view returns(address);

    function getString(bytes32 _key) external view returns(string memory);

    function getBytes(bytes32 _key) external view returns(bytes memory);

    function getBool(bytes32 _key) external view returns(bool);

    function getUint256Array(bytes32 _key) external view returns(uint256[] memory);

    function getBytes32Array(bytes32 _key) external view returns(bytes32[] memory);

    function getAddressArray(bytes32 _key) external view returns(address[] memory);

    function getBoolArray(bytes32 _key) external view returns(bool[] memory);

    function getUint256ArrayLength(bytes32 _key) external view returns(uint256);

    function getBytes32ArrayLength(bytes32 _key) external view returns(uint256);

    function getAddressArrayLength(bytes32 _key) external view returns(uint256);

    function getBoolArrayLength(bytes32 _key) external view returns(uint256);

    function getUint256ArrayElement(bytes32 _key, uint256 _index) external view returns(uint256);

    function getBytes32ArrayElement(bytes32 _key, uint256 _index) external view returns(bytes32);

    function getAddressArrayElement(bytes32 _key, uint256 _index) external view returns(address);

    function getBoolArrayElement(bytes32 _key, uint256 _index) external view returns(bool);

    function getUint256ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(uint256[] memory);

    function getBytes32ArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bytes32[] memory);

    function getAddressArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(address[] memory);

    function getBoolArrayElements(bytes32 _key, uint256 _startIndex, uint256 _endIndex) external view returns(bool[] memory);
}

 
interface IModuleRegistry {

     
     
     

     
    event Pause(address account);
     
    event Unpause(address account);
     
    event ModuleUsed(address indexed _moduleFactory, address indexed _securityToken);
     
    event ModuleRegistered(address indexed _moduleFactory, address indexed _owner);
     
    event ModuleVerified(address indexed _moduleFactory);
     
    event ModuleUnverified(address indexed _moduleFactory);
     
    event ModuleRemoved(address indexed _moduleFactory, address indexed _decisionMaker);
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function useModule(address _moduleFactory) external;

     
    function useModule(address _moduleFactory, bool _isUpgrade) external;

     
    function registerModule(address _moduleFactory) external;

     
    function removeModule(address _moduleFactory) external;

     
    function isCompatibleModule(address _moduleFactory, address _securityToken) external view returns(bool isCompatible);

     
    function verifyModule(address _moduleFactory) external;

     
    function unverifyModule(address _moduleFactory) external;

     
    function getFactoryDetails(address _factoryAddress) external view returns(bool isVerified, address factoryOwner, address[] memory usingTokens);

     
    function getTagsByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(bytes32[] memory tags, address[] memory factories);

     
    function getTagsByType(uint8 _moduleType) external view returns(bytes32[] memory tags, address[] memory factories);

     
    function getAllModulesByType(uint8 _moduleType) external view returns(address[] memory factories);
     
    function getModulesByType(uint8 _moduleType) external view returns(address[] memory factories);

     
    function getModulesByTypeAndToken(uint8 _moduleType, address _securityToken) external view returns(address[] memory factories);

     
    function updateFromRegistry() external;

     
    function owner() external view returns(address ownerAddress);

     
    function isPaused() external view returns(bool paused);

     
    function reclaimERC20(address _tokenContract) external;

     
    function pause() external;

     
    function unpause() external;

     
    function transferOwnership(address _newOwner) external;

}

interface IPolymathRegistry {

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);
    
     
    function getAddress(string calldata _nameKey) external view returns(address registryAddress);

     
    function changeAddress(string calldata _nameKey, address _newAddress) external;

}

 
interface ISecurityTokenRegistry {

     
    event Pause(address account);
     
    event Unpause(address account);
     
    event TickerRemoved(string _ticker, address _removedBy);
     
    event ChangeExpiryLimit(uint256 _oldExpiry, uint256 _newExpiry);
     
    event ChangeSecurityLaunchFee(uint256 _oldFee, uint256 _newFee);
     
    event ChangeTickerRegistrationFee(uint256 _oldFee, uint256 _newFee);
     
    event ChangeFeeCurrency(bool _isFeeInPoly);
     
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
     
    event ChangeTickerOwnership(string _ticker, address indexed _oldOwner, address indexed _newOwner);
     
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _usdFee,
        uint256 _polyFee,
        uint256 _protocolVersion
    );
     
     
    event NewSecurityToken(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        bool _fromAdmin,
        uint256 _registrationFee
    );
     
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFeePoly,
        uint256 _registrationFeeUsd
    );
     
     
     
    event RegisterTicker(
        address indexed _owner,
        string _ticker,
        string _name,
        uint256 indexed _registrationDate,
        uint256 indexed _expiryDate,
        bool _fromAdmin,
        uint256 _registrationFee
    );
     
    event SecurityTokenRefreshed(
        string _ticker,
        string _name,
        address indexed _securityTokenAddress,
        address indexed _owner,
        uint256 _addedAt,
        address _registrant,
        uint256 _protocolVersion
    );
    event ProtocolFactorySet(address indexed _STFactory, uint8 _major, uint8 _minor, uint8 _patch);
    event LatestVersionSet(uint8 _major, uint8 _minor, uint8 _patch);
    event ProtocolFactoryRemoved(address indexed _STFactory, uint8 _major, uint8 _minor, uint8 _patch);

     
    function generateSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible
    )
        external;

     
    function generateNewSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible,
        address _treasuryWallet,
        uint256 _protocolVersion
    )
        external;

     
    function refreshSecurityToken(
        string calldata _name,
        string calldata _ticker,
        string calldata _tokenDetails,
        bool _divisible,
        address _treasuryWallet
    )
        external returns (address securityToken);

     
    function modifySecurityToken(
        string calldata _name,
        string calldata _ticker,
        address _owner,
        address _securityToken,
        string calldata _tokenDetails,
        uint256 _deployedAt
    )
    external;

     
    function modifyExistingSecurityToken(
        string calldata _ticker,
        address _owner,
        address _securityToken,
        string calldata _tokenDetails,
        uint256 _deployedAt
    )
        external;

     
    function modifyExistingTicker(
        address _owner,
        string calldata _ticker,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
        external;

     
    function registerTicker(address _owner, string calldata _ticker, string calldata _tokenName) external;

     
    function registerNewTicker(address _owner, string calldata _ticker) external;

     
    function isSecurityToken(address _securityToken) external view returns(bool isValid);

     
    function transferOwnership(address _newOwner) external;

     
    function getSecurityTokenAddress(string calldata _ticker) external view returns(address tokenAddress);

     
    function getSecurityTokenData(address _securityToken) external view returns (
        string memory tokenSymbol,
        address tokenAddress,
        string memory tokenDetails,
        uint256 tokenTime
    );

     
    function getSTFactoryAddress() external view returns(address stFactoryAddress);

     
    function getSTFactoryAddressOfVersion(uint256 _protocolVersion) external view returns(address stFactory);

     
    function getLatestProtocolVersion() external view returns(uint8[] memory protocolVersion);

     
    function getTickersByOwner(address _owner) external view returns(bytes32[] memory tickers);

     
    function getTokensByOwner(address _owner) external view returns(address[] memory tokens);

     
    function getTokens() external view returns(address[] memory tokens);

     
    function getTickerDetails(string calldata _ticker) external view returns(address tickerOwner, uint256 tickerRegistration, uint256 tickerExpiry, string memory tokenName, bool tickerStatus);

     
    function modifyTicker(
        address _owner,
        string calldata _ticker,
        string calldata _tokenName,
        uint256 _registrationDate,
        uint256 _expiryDate,
        bool _status
    )
    external;

     
    function removeTicker(string calldata _ticker) external;

     
    function transferTickerOwnership(address _newOwner, string calldata _ticker) external;

     
    function changeExpiryLimit(uint256 _newExpiry) external;

    
    function changeTickerRegistrationFee(uint256 _tickerRegFee) external;

     
    function changeSecurityLaunchFee(uint256 _stLaunchFee) external;

     
    function changeFeesAmountAndCurrency(uint256 _tickerRegFee, uint256 _stLaunchFee, bool _isFeeInPoly) external;

     
    function setProtocolFactory(address _STFactoryAddress, uint8 _major, uint8 _minor, uint8 _patch) external;

     
    function removeProtocolFactory(uint8 _major, uint8 _minor, uint8 _patch) external;

     
    function setLatestVersion(uint8 _major, uint8 _minor, uint8 _patch) external;

     
    function updatePolyTokenAddress(address _newAddress) external;

     
    function updateFromRegistry() external;

     
    function getSecurityTokenLaunchFee() external returns(uint256 fee);

     
    function getTickerRegistrationFee() external returns(uint256 fee);

     
    function setGetterRegistry(address _getterContract) external;

     
    function getFees(bytes32 _feeType) external returns (uint256 usdFee, uint256 polyFee);

     
    function getTokensByDelegate(address _delegate) external view returns(address[] memory tokens);

     
    function getExpiryLimit() external view returns(uint256 expiry);

     
    function getTickerStatus(string calldata _ticker) external view returns(bool status);

     
    function getIsFeeInPoly() external view returns(bool isInPoly);

     
    function getTickerOwner(string calldata _ticker) external view returns(address owner);

     
    function isPaused() external view returns(bool paused);

     
    function pause() external;

     
    function unpause() external;

     
    function reclaimERC20(address _tokenContract) external;

     
    function owner() external view returns(address ownerAddress);

     
    function tickerAvailable(string calldata _ticker) external view returns(bool);

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

contract SecurityTokenStorage {

    uint8 internal constant PERMISSION_KEY = 1;
    uint8 internal constant TRANSFER_KEY = 2;
    uint8 internal constant MINT_KEY = 3;
    uint8 internal constant CHECKPOINT_KEY = 4;
    uint8 internal constant BURN_KEY = 5;
    uint8 internal constant DATA_KEY = 6;
    uint8 internal constant WALLET_KEY = 7;

    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731;  
    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6;  
    bytes32 internal constant LOCKED = "LOCKED";
    bytes32 internal constant UNLOCKED = "UNLOCKED";

     
     
     

    struct Document {
        bytes32 docHash;  
        uint256 lastModified;  
        string uri;  
    }

     
    struct SemanticVersion {
        uint8 major;
        uint8 minor;
        uint8 patch;
    }

     
    struct ModuleData {
        bytes32 name;
        address module;
        address moduleFactory;
        bool isArchived;
        uint8[] moduleTypes;
        uint256[] moduleIndexes;
        uint256 nameIndex;
        bytes32 label;
    }

     
    struct Checkpoint {
        uint256 checkpointId;
        uint256 value;
    }

     
    address internal _owner;
    address public tokenFactory;
    bool public initialized;

     
    string public name;
    string public symbol;
    uint8 public decimals;

     
     
    address public controller;

    IPolymathRegistry public polymathRegistry;
    IModuleRegistry public moduleRegistry;
    ISecurityTokenRegistry public securityTokenRegistry;
    IERC20 public polyToken;
    address public getterDelegate;
     
    IDataStore public dataStore;

    uint256 public granularity;

     
    uint256 public currentCheckpointId;

     
    string public tokenDetails;

     
    bool public controllerDisabled = false;

     
    bool public transfersFrozen;

     
    uint256 public holderCount;

     
     
     
     
    bool internal issuance = true;

     
    bytes32[] _docNames;

     
    uint256[] checkpointTimes;

    SemanticVersion securityTokenVersion;

     
    mapping(uint8 => address[]) modules;

     
    mapping(address => ModuleData) modulesToData;

     
    mapping(bytes32 => address[]) names;

     
    mapping (uint256 => uint256) checkpointTotalSupply;

     
    mapping(address => Checkpoint[]) checkpointBalances;

     
    mapping(bytes32 => Document) internal _documents;
     
    mapping(bytes32 => uint256) internal _docIndexes;
     
    mapping (address => mapping (bytes32 => mapping (address => bool))) partitionApprovals;

}

 
contract SecurityTokenProxy is OZStorage, SecurityTokenStorage, OwnedUpgradeabilityProxy {

     
    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        uint256 _granularity,
        string memory _tokenDetails,
        address _polymathRegistry
    )
        public
    {
         
        require(_polymathRegistry != address(0), "Invalid Address");
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        polymathRegistry = IPolymathRegistry(_polymathRegistry);
        tokenDetails = _tokenDetails;
        granularity = _granularity;
        _owner = msg.sender;
    }

}

 
interface ISTFactory {

    event LogicContractSet(string _version, address _logicContract, bytes _upgradeData);
    event TokenUpgraded(
        address indexed _securityToken,
        uint256 indexed _version
    );
    event DefaultTransferManagerUpdated(address indexed _oldTransferManagerFactory, address indexed _newTransferManagerFactory);
    event DefaultDataStoreUpdated(address indexed _oldDataStoreFactory, address indexed _newDataStoreFactory);

     
    function deployToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        string calldata _tokenDetails,
        address _issuer,
        bool _divisible,
        address _treasuryWallet  
    )
    external
    returns(address tokenAddress);

     
    function setLogicContract(string calldata _version, address _logicContract, bytes calldata _initializationData, bytes calldata _upgradeData) external;

     
    function upgradeToken(uint8 _maxModuleType) external;

     
    function updateDefaultTransferManager(address _transferManagerFactory) external;

     
    function updateDefaultDataStore(address _dataStoreFactory) external;
}

 
interface ISecurityToken {
     
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns(uint8);
    function totalSupply() external view returns(uint256);
    function balanceOf(address owner) external view returns(uint256);
    function allowance(address owner, address spender) external view returns(uint256);
    function transfer(address to, uint256 value) external returns(bool);
    function transferFrom(address from, address to, uint256 value) external returns(bool);
    function approve(address spender, uint256 value) external returns(bool);
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

     
    function canTransfer(address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

     
    event ModuleAdded(
        uint8[] _types,
        bytes32 indexed _name,
        address indexed _moduleFactory,
        address _module,
        uint256 _moduleCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    );

     
    event UpdateTokenDetails(string _oldDetails, string _newDetails);
     
    event UpdateTokenName(string _oldName, string _newName);
     
    event GranularityChanged(uint256 _oldGranularity, uint256 _newGranularity);
     
    event FreezeIssuance();
     
    event FreezeTransfers(bool _status);
     
    event CheckpointCreated(uint256 indexed _checkpointId, uint256 _investorLength);
     
    event SetController(address indexed _oldController, address indexed _newController);
     
    event TreasuryWalletChanged(address _oldTreasuryWallet, address _newTreasuryWallet);
    event DisableController();
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event TokenUpgraded(uint8 _major, uint8 _minor, uint8 _patch);

     
    event ModuleArchived(uint8[] _types, address _module);  
     
    event ModuleUnarchived(uint8[] _types, address _module);  
     
    event ModuleRemoved(uint8[] _types, address _module);  
     
    event ModuleBudgetChanged(uint8[] _moduleTypes, address _module, uint256 _oldBudget, uint256 _budget);  

     
    event TransferByPartition(
        bytes32 indexed _fromPartition,
        address _operator,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

     
    event AuthorizedOperator(address indexed operator, address indexed tokenHolder);
    event RevokedOperator(address indexed operator, address indexed tokenHolder);
    event AuthorizedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);
    event RevokedOperatorByPartition(bytes32 indexed partition, address indexed operator, address indexed tokenHolder);

     
    event IssuedByPartition(bytes32 indexed partition, address indexed to, uint256 value, bytes data);
    event RedeemedByPartition(bytes32 indexed partition, address indexed operator, address indexed from, uint256 value, bytes data, bytes operatorData);

     
    event DocumentRemoved(bytes32 indexed _name, string _uri, bytes32 _documentHash);
    event DocumentUpdated(bytes32 indexed _name, string _uri, bytes32 _documentHash);

     
    event ControllerTransfer(
        address _controller,
        address indexed _from,
        address indexed _to,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

    event ControllerRedemption(
        address _controller,
        address indexed _tokenHolder,
        uint256 _value,
        bytes _data,
        bytes _operatorData
    );

     
    event Issued(address indexed _operator, address indexed _to, uint256 _value, bytes _data);
    event Redeemed(address indexed _operator, address indexed _from, uint256 _value, bytes _data);

     
    function initialize(address _getterDelegate) external;

     
    function canTransferByPartition(
        address _from,
        address _to,
        bytes32 _partition,
        uint256 _value,
        bytes calldata _data
    )
        external
        view
        returns (byte statusCode, bytes32 reasonCode, bytes32 partition);

     
    function canTransferFrom(address _from, address _to, uint256 _value, bytes calldata _data) external view returns (byte statusCode, bytes32 reasonCode);

     
    function setDocument(bytes32 _name, string calldata _uri, bytes32 _documentHash) external;

     
    function removeDocument(bytes32 _name) external;

     
    function getDocument(bytes32 _name) external view returns (string memory documentUri, bytes32 documentHash, uint256 documentTime);

     
    function getAllDocuments() external view returns (bytes32[] memory documentNames);

     
    function isControllable() external view returns (bool controlled);

     
    function isModule(address _module, uint8 _type) external view returns(bool isValid);

     
    function issue(address _tokenHolder, uint256 _value, bytes calldata _data) external;

     
    function issueMulti(address[] calldata _tokenHolders, uint256[] calldata _values) external;

     
    function issueByPartition(bytes32 _partition, address _tokenHolder, uint256 _value, bytes calldata _data) external;

     
    function redeemByPartition(bytes32 _partition, uint256 _value, bytes calldata _data) external;

     
    function redeem(uint256 _value, bytes calldata _data) external;

     
    function redeemFrom(address _tokenHolder, uint256 _value, bytes calldata _data) external;

     
    function operatorRedeemByPartition(
        bytes32 _partition,
        address _tokenHolder,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    ) external;

     
    function checkPermission(address _delegate, address _module, bytes32 _perm) external view returns(bool hasPermission);

     
    function getModule(address _module) external view returns (bytes32 moduleName, address moduleAddress, address factoryAddress, bool isArchived, uint8[] memory moduleTypes, bytes32 moduleLabel);

     
    function getModulesByName(bytes32 _name) external view returns(address[] memory modules);

     
    function getModulesByType(uint8 _type) external view returns(address[] memory modules);

     
    function getTreasuryWallet() external view returns(address treasuryWallet);

     
    function totalSupplyAt(uint256 _checkpointId) external view returns(uint256 supply);

     
    function balanceOfAt(address _investor, uint256 _checkpointId) external view returns(uint256 balance);

     
    function createCheckpoint() external returns(uint256 checkpointId);

     
    function getCheckpointTimes() external view returns(uint256[] memory checkpointTimes);

     
    function getInvestors() external view returns(address[] memory investors);

     
    function getInvestorsAt(uint256 _checkpointId) external view returns(address[] memory investors);

     
    function getInvestorsSubsetAt(uint256 _checkpointId, uint256 _start, uint256 _end) external view returns(address[] memory investors);

     
    function iterateInvestors(uint256 _start, uint256 _end) external view returns(address[] memory investors);

     
    function currentCheckpointId() external view returns(uint256 checkpointId);

     
    function isOperator(address _operator, address _tokenHolder) external view returns (bool isValid);

     
    function isOperatorForPartition(bytes32 _partition, address _operator, address _tokenHolder) external view returns (bool isValid);

     
    function partitionsOf(address _tokenHolder) external view returns (bytes32[] memory partitions);

     
    function dataStore() external view returns (address dataStoreAddress);

     
    function changeDataStore(address _dataStore) external;


     
    function changeTreasuryWallet(address _wallet) external;

     
    function withdrawERC20(address _tokenContract, uint256 _value) external;

     
    function changeModuleBudget(address _module, uint256 _change, bool _increase) external;

     
    function updateTokenDetails(string calldata _newTokenDetails) external;

     
    function changeName(string calldata _name) external;

     
    function changeGranularity(uint256 _granularity) external;

     
    function freezeTransfers() external;

     
    function unfreezeTransfers() external;

     
    function freezeIssuance(bytes calldata _signature) external;

     
    function addModuleWithLabel(
        address _moduleFactory,
        bytes calldata _data,
        uint256 _maxCost,
        uint256 _budget,
        bytes32 _label,
        bool _archived
    ) external;

     
    function addModule(address _moduleFactory, bytes calldata _data, uint256 _maxCost, uint256 _budget, bool _archived) external;

     
    function archiveModule(address _module) external;

     
    function unarchiveModule(address _module) external;

     
    function removeModule(address _module) external;

     
    function setController(address _controller) external;

     
    function controllerTransfer(address _from, address _to, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

     
    function controllerRedeem(address _tokenHolder, uint256 _value, bytes calldata _data, bytes calldata _operatorData) external;

     
    function disableController(bytes calldata _signature) external;

     
    function getVersion() external view returns(uint8[] memory version);

     
    function getInvestorCount() external view returns(uint256 investorCount);

     
    function holderCount() external view returns(uint256 count);

     
    function transferWithData(address _to, uint256 _value, bytes calldata _data) external;

     
    function transferFromWithData(address _from, address _to, uint256 _value, bytes calldata _data) external;

     
    function transferByPartition(bytes32 _partition, address _to, uint256 _value, bytes calldata _data) external returns (bytes32 partition);

     
    function balanceOfByPartition(bytes32 _partition, address _tokenHolder) external view returns(uint256 balance);

     
    function granularity() external view returns(uint256 granularityAmount);

     
    function polymathRegistry() external view returns(address registryAddress);

     
    function upgradeModule(address _module) external;

     
    function upgradeToken() external;

     
    function isIssuable() external view returns (bool issuable);

     
    function authorizeOperator(address _operator) external;

     
    function revokeOperator(address _operator) external;

     
    function authorizeOperatorByPartition(bytes32 _partition, address _operator) external;

     
    function revokeOperatorByPartition(bytes32 _partition, address _operator) external;

     
    function operatorTransferByPartition(
        bytes32 _partition,
        address _from,
        address _to,
        uint256 _value,
        bytes calldata _data,
        bytes calldata _operatorData
    )
        external
        returns (bytes32 partition);

     
    function transfersFrozen() external view returns (bool isFrozen);

     
    function transferOwnership(address newOwner) external;

     
    function isOwner() external view returns (bool);

     
    function owner() external view returns (address ownerAddress);

    function controller() external view returns(address controllerAddress);

    function moduleRegistry() external view returns(address moduleRegistryAddress);

    function securityTokenRegistry() external view returns(address securityTokenRegistryAddress);

    function polyToken() external view returns(address polyTokenAddress);

    function tokenFactory() external view returns(address tokenFactoryAddress);

    function getterDelegate() external view returns(address delegate);

    function controllerDisabled() external view returns(bool isDisabled);

    function initialized() external view returns(bool isInitialized);

    function tokenDetails() external view returns(string memory details);

    function updateFromRegistry() external;

}

 
interface IOwnable {
     
    function owner() external view returns(address ownerAddress);

     
    function renounceOwnership() external;

     
    function transferOwnership(address _newOwner) external;

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

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract DataStoreStorage {
     
    address internal __implementation;

    ISecurityToken public securityToken;

    mapping (bytes32 => uint256) internal uintData;
    mapping (bytes32 => bytes32) internal bytes32Data;
    mapping (bytes32 => address) internal addressData;
    mapping (bytes32 => string) internal stringData;
    mapping (bytes32 => bytes) internal bytesData;
    mapping (bytes32 => bool) internal boolData;
    mapping (bytes32 => uint256[]) internal uintArrayData;
    mapping (bytes32 => bytes32[]) internal bytes32ArrayData;
    mapping (bytes32 => address[]) internal addressArrayData;
    mapping (bytes32 => bool[]) internal boolArrayData;

    uint8 internal constant DATA_KEY = 6;
    bytes32 internal constant MANAGEDATA = "MANAGEDATA";
}

 
contract DataStoreProxy is DataStoreStorage, Proxy {

     
    constructor(
        address _securityToken,
        address _implementation
    )
        public
    {
        require(_implementation != address(0) && _securityToken != address(0),
            "Address should not be 0x"
        );
        securityToken = ISecurityToken(_securityToken);
        __implementation = _implementation;
    }

     
    function _implementation() internal view returns(address) {
        return __implementation;
    }

}

contract DataStoreFactory {

    address public implementation;

    constructor(address _implementation) public {
        require(_implementation != address(0), "Address should not be 0x");
        implementation = _implementation;
    }

    function generateDataStore(address _securityToken) public returns (address) {
        DataStoreProxy dsProxy = new DataStoreProxy(_securityToken, implementation);
        return address(dsProxy);
    }
}

 
contract STFactory is ISTFactory, Ownable {

    address public transferManagerFactory;
    DataStoreFactory public dataStoreFactory;
    IPolymathRegistry public polymathRegistry;

     
     
    mapping (address => uint256) tokenUpgrade;

    struct LogicContract {
        string version;
        address logicContract;
        bytes initializationData;  
        bytes upgradeData;  
    }

    mapping (uint256 => LogicContract) logicContracts;

    uint256 public latestUpgrade;

    event LogicContractSet(string _version, uint256 _upgrade, address _logicContract, bytes _initializationData, bytes _upgradeData);
    event TokenUpgraded(
        address indexed _securityToken,
        uint256 indexed _version
    );
    event DefaultTransferManagerUpdated(address indexed _oldTransferManagerFactory, address indexed _newTransferManagerFactory);
    event DefaultDataStoreUpdated(address indexed _oldDataStoreFactory, address indexed _newDataStoreFactory);

    constructor(
        address _polymathRegistry,
        address _transferManagerFactory,
        address _dataStoreFactory,
        string memory _version,
        address _logicContract,
        bytes memory _initializationData
    )
        public
    {
        require(_logicContract != address(0), "Invalid Address");
        require(_transferManagerFactory != address(0), "Invalid Address");
        require(_dataStoreFactory != address(0), "Invalid Address");
        require(_polymathRegistry != address(0), "Invalid Address");
        require(_initializationData.length > 4, "Invalid Initialization");
        transferManagerFactory = _transferManagerFactory;
        dataStoreFactory = DataStoreFactory(_dataStoreFactory);
        polymathRegistry = IPolymathRegistry(_polymathRegistry);

         
        latestUpgrade = 1;
        logicContracts[latestUpgrade].logicContract = _logicContract;
        logicContracts[latestUpgrade].initializationData = _initializationData;
        logicContracts[latestUpgrade].version = _version;
    }

     
    function deployToken(
        string calldata _name,
        string calldata _symbol,
        uint8 _decimals,
        string calldata _tokenDetails,
        address _issuer,
        bool _divisible,
        address _treasuryWallet
    )
        external
        returns(address)
    {
        address securityToken = _deploy(
            _name,
            _symbol,
            _decimals,
            _tokenDetails,
            _divisible
        );
         
        if (address(dataStoreFactory) != address(0)) {
            ISecurityToken(securityToken).changeDataStore(dataStoreFactory.generateDataStore(securityToken));
        }
        ISecurityToken(securityToken).changeTreasuryWallet(_treasuryWallet);
        if (transferManagerFactory != address(0)) {
            ISecurityToken(securityToken).addModule(transferManagerFactory, "", 0, 0, false);
        }
        IOwnable(securityToken).transferOwnership(_issuer);
        return securityToken;
    }

    function _deploy(
        string memory _name,
        string memory _symbol,
        uint8 _decimals,
        string memory _tokenDetails,
        bool _divisible
    ) internal returns(address) {
         
        SecurityTokenProxy proxy = new SecurityTokenProxy(
            _name,
            _symbol,
            _decimals,
            _divisible ? 1 : uint256(10) ** _decimals,
            _tokenDetails,
            address(polymathRegistry)
        );
         
        proxy.upgradeTo(logicContracts[latestUpgrade].version, logicContracts[latestUpgrade].logicContract);
         
         
        (bool success, ) = address(proxy).call(logicContracts[latestUpgrade].initializationData);
        require(success, "Unsuccessful initialization");
        tokenUpgrade[address(proxy)] = latestUpgrade;
        return address(proxy);
    }

     
    function setLogicContract(string calldata _version, address _logicContract, bytes calldata _initializationData, bytes calldata _upgradeData) external onlyOwner {
        require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[latestUpgrade].version)), "Same version");
        require(_logicContract != logicContracts[latestUpgrade].logicContract, "Same version");
        require(_logicContract != address(0), "Invalid address");
        require(_initializationData.length > 4, "Invalid Initialization");
        require(_upgradeData.length > 4, "Invalid Upgrade");
        latestUpgrade++;
        _modifyLogicContract(latestUpgrade, _version, _logicContract, _initializationData, _upgradeData);
    }

     
    function updateLogicContract(uint256 _upgrade, string calldata _version, address _logicContract, bytes calldata _initializationData, bytes calldata _upgradeData) external onlyOwner {
        require(_upgrade <= latestUpgrade, "Invalid upgrade");
        require(_upgrade > 0, "Invalid upgrade");
         
        if (_upgrade > 1) {
          require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[_upgrade - 1].version)), "Same version");
          require(_logicContract != logicContracts[_upgrade - 1].logicContract, "Same version");
        }
        require(_logicContract != address(0), "Invalid address");
        require(_initializationData.length > 4, "Invalid Initialization");
        require(_upgradeData.length > 4, "Invalid Upgrade");
        _modifyLogicContract(_upgrade, _version, _logicContract, _initializationData, _upgradeData);
    }

    function _modifyLogicContract(uint256 _upgrade, string memory _version, address _logicContract, bytes memory _initializationData, bytes memory _upgradeData) internal {
        logicContracts[_upgrade].version = _version;
        logicContracts[_upgrade].logicContract = _logicContract;
        logicContracts[_upgrade].upgradeData = _upgradeData;
        logicContracts[_upgrade].initializationData = _initializationData;
        emit LogicContractSet(_version, _upgrade, _logicContract, _initializationData, _upgradeData);
    }
     
    function upgradeToken(uint8 _maxModuleType) external {
         
        require(tokenUpgrade[msg.sender] != 0, "Invalid token");
        uint256 newVersion = tokenUpgrade[msg.sender] + 1;
        require(newVersion <= latestUpgrade, "Incorrect version");
        OwnedUpgradeabilityProxy(address(uint160(msg.sender))).upgradeToAndCall(logicContracts[newVersion].version, logicContracts[newVersion].logicContract, logicContracts[newVersion].upgradeData);
        tokenUpgrade[msg.sender] = newVersion;
         
        IModuleRegistry moduleRegistry = IModuleRegistry(polymathRegistry.getAddress("ModuleRegistry"));
        address moduleFactory;
        bool isArchived;
        for (uint8 i = 1; i < _maxModuleType; i++) {
            address[] memory modules = ISecurityToken(msg.sender).getModulesByType(i);
            for (uint256 j = 0; j < modules.length; j++) {
                (,, moduleFactory, isArchived,,) = ISecurityToken(msg.sender).getModule(modules[j]);
                if (!isArchived) {
                    require(moduleRegistry.isCompatibleModule(moduleFactory, msg.sender), "Incompatible Modules");
                }
            }
        }
        emit TokenUpgraded(msg.sender, newVersion);
    }

     
    function updateDefaultTransferManager(address _transferManagerFactory) external onlyOwner {
         
        emit DefaultTransferManagerUpdated(transferManagerFactory, _transferManagerFactory);
        transferManagerFactory = _transferManagerFactory;
    }

     
    function updateDefaultDataStore(address _dataStoreFactory) external onlyOwner {
         
        emit DefaultDataStoreUpdated(address(dataStoreFactory), address(_dataStoreFactory));
        dataStoreFactory = DataStoreFactory(_dataStoreFactory);
    }

}