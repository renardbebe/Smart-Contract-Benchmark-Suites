 

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

 
contract GeneralTransferManagerStorage {

    bytes32 public constant WHITELIST = "WHITELIST";
    bytes32 public constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731;  
    bytes32 public constant INVESTORFLAGS = "INVESTORFLAGS";
    uint256 internal constant ONE = uint256(1);

    enum TransferType { GENERAL, ISSUANCE, REDEMPTION }

     
    address public issuanceAddress;

     
    struct Defaults {
        uint64 canSendAfter;
        uint64 canReceiveAfter;
    }

     
    Defaults public defaults;

     
    mapping(address => mapping(uint256 => bool)) public nonceMap;

    struct TransferRequirements {
        bool fromValidKYC;
        bool toValidKYC;
        bool fromRestricted;
        bool toRestricted;
    }

    mapping(uint8 => TransferRequirements) public transferRequirements;
     
}

 
contract Pausable {
    event Pause(address account);
    event Unpause(address account);

    bool public paused = false;

     
    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Contract is not paused");
        _;
    }

     
    function _pause() internal whenNotPaused {
        paused = true;
         
        emit Pause(msg.sender);
    }

     
    function _unpause() internal whenPaused {
        paused = false;
         
        emit Unpause(msg.sender);
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

 
contract ModuleStorage {
    address public factory;

    ISecurityToken public securityToken;

     
    bytes32 public constant ADMIN = "ADMIN";
    bytes32 public constant OPERATOR = "OPERATOR";

    bytes32 internal constant TREASURY = 0xaae8817359f3dcb67d050f44f3e49f982e0359d90ca4b5f18569926304aaece6;  

    IERC20 public polyToken;

     
    constructor(address _securityToken, address _polyAddress) public {
        securityToken = ISecurityToken(_securityToken);
        factory = msg.sender;
        polyToken = IERC20(_polyAddress);
    }

}

 
contract GeneralTransferManagerProxy is GeneralTransferManagerStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {
     
    constructor(
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(_implementation != address(0), "Implementation address should not be 0x");
        _upgradeTo(_version, _implementation);
        transferRequirements[uint8(TransferType.GENERAL)] = TransferRequirements(true, true, true, true);
        transferRequirements[uint8(TransferType.ISSUANCE)] = TransferRequirements(false, true, false, false);
        transferRequirements[uint8(TransferType.REDEMPTION)] = TransferRequirements(true, false, false, false);
    }

}

 

library VersionUtils {

    function lessThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] < _new[i]) return true;
            if (_current[i] > _new[i]) return false;
        }
        return true;
    }

    function greaterThanOrEqual(uint8[] memory _current, uint8[] memory _new) internal pure returns(bool) {
        require(_current.length == 3);
        require(_new.length == 3);
        uint8 i = 0;
        for (i = 0; i < _current.length; i++) {
            if (_current[i] == _new[i]) continue;
            if (_current[i] > _new[i]) return true;
            if (_current[i] < _new[i]) return false;
        }
        return true;
    }

     
    function pack(uint8 _major, uint8 _minor, uint8 _patch) internal pure returns(uint24) {
        return (uint24(_major) << 16) | (uint24(_minor) << 8) | uint24(_patch);
    }

     
    function unpack(uint24 _packedVersion) internal pure returns(uint8[] memory) {
        uint8[] memory _unpackVersion = new uint8[](3);
        _unpackVersion[0] = uint8(_packedVersion >> 16);
        _unpackVersion[1] = uint8(_packedVersion >> 8);
        _unpackVersion[2] = uint8(_packedVersion);
        return _unpackVersion;
    }


     
    function packKYC(uint64 _a, uint64 _b, uint64 _c, uint8 _d) internal pure returns(uint256) {
         
         
         
         
        return (uint256(_a) << 136) | (uint256(_b) << 72) | (uint256(_c) << 8) | uint256(_d);
    }

     
    function unpackKYC(uint256 _packedVersion) internal pure returns(uint64 canSendAfter, uint64 canReceiveAfter, uint64 expiryTime, uint8 added) {
        canSendAfter = uint64(_packedVersion >> 136);
        canReceiveAfter = uint64(_packedVersion >> 72);
        expiryTime = uint64(_packedVersion >> 8);
        added = uint8(_packedVersion);
    }
}

 
library Util {
     
    function upper(string memory _base) internal pure returns(string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            bytes1 b1 = _baseBytes[i];
            if (b1 >= 0x61 && b1 <= 0x7A) {
                b1 = bytes1(uint8(b1) - 32);
            }
            _baseBytes[i] = b1;
        }
        return string(_baseBytes);
    }

     
     
    function stringToBytes32(string memory _source) internal pure returns(bytes32) {
        return bytesToBytes32(bytes(_source), 0);
    }

     
     
    function bytesToBytes32(bytes memory _b, uint _offset) internal pure returns(bytes32) {
        bytes32 result;

        for (uint i = 0; i < _b.length; i++) {
            result |= bytes32(_b[_offset + i] & 0xFF) >> (i * 8);
        }
        return result;
    }

     
    function bytes32ToString(bytes32 _source) internal pure returns(string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        uint j = 0;
        for (j = 0; j < 32; j++) {
            byte char = byte(bytes32(uint(_source) * 2 ** (8 * j)));
            if (char != 0) {
                bytesString[charCount] = char;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

     
    function getSig(bytes memory _data) internal pure returns(bytes4 sig) {
        uint len = _data.length < 4 ? _data.length : 4;
        for (uint256 i = 0; i < len; i++) {
          sig |= bytes4(_data[i] & 0xFF) >> (i * 8);
        }
        return sig;
    }
}

 
interface IModule {
     
    function getInitFunction() external pure returns(bytes4 initFunction);

     
    function getPermissions() external view returns(bytes32[] memory permissions);

}

interface IOracle {
     
    function getCurrencyAddress() external view returns(address currency);

     
    function getCurrencySymbol() external view returns(bytes32 symbol);

     
    function getCurrencyDenominated() external view returns(bytes32 denominatedCurrency);

     
    function getPrice() external returns(uint256 price);

}

interface IPolymathRegistry {

    event ChangeAddress(string _nameKey, address indexed _oldAddress, address indexed _newAddress);
    
     
    function getAddress(string calldata _nameKey) external view returns(address registryAddress);

     
    function changeAddress(string calldata _nameKey, address _newAddress) external;

}

 
interface IModuleFactory {
    event ChangeSetupCost(uint256 _oldSetupCost, uint256 _newSetupCost);
    event ChangeCostType(bool _isOldCostInPoly, bool _isNewCostInPoly);
    event GenerateModuleFromFactory(
        address _module,
        bytes32 indexed _moduleName,
        address indexed _moduleFactory,
        address _creator,
        uint256 _setupCost,
        uint256 _setupCostInPoly
    );
    event ChangeSTVersionBound(string _boundType, uint8 _major, uint8 _minor, uint8 _patch);

     
    function deploy(bytes calldata _data) external returns(address moduleAddress);

     
    function version() external view returns(string memory moduleVersion);

     
    function name() external view returns(bytes32 moduleName);

     
    function title() external view returns(string memory moduleTitle);

     
    function description() external view returns(string memory moduleDescription);

     
    function setupCost() external returns(uint256 usdSetupCost);

     
    function getTypes() external view returns(uint8[] memory moduleTypes);

     
    function getTags() external view returns(bytes32[] memory moduleTags);

     
    function changeSetupCost(uint256 _newSetupCost) external;

     
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) external;

     
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external;

     
    function setupCostInPoly() external returns (uint256 polySetupCost);

     
    function getLowerSTVersionBounds() external view returns(uint8[] memory lowerBounds);

     
    function getUpperSTVersionBounds() external view returns(uint8[] memory upperBounds);

     
    function changeTags(bytes32[] calldata _tagsData) external;

     
    function changeName(bytes32 _name) external;

     
    function changeDescription(string calldata _description) external;

     
    function changeTitle(string calldata _title) external;

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

library DecimalMath {
    using SafeMath for uint256;

    uint256 internal constant e18 = uint256(10) ** uint256(18);

     
    function mul(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, y), (e18) / 2) / (e18);
    }

     
    function div(uint256 x, uint256 y) internal pure returns(uint256 z) {
        z = SafeMath.add(SafeMath.mul(x, (e18)), y / 2) / y;
    }

}

 
contract ModuleFactory is IModuleFactory, Ownable {

    IPolymathRegistry public polymathRegistry;

    string initialVersion;
    bytes32 public name;
    string public title;
    string public description;

    uint8[] typesData;
    bytes32[] tagsData;

    bool public isCostInPoly;
    uint256 public setupCost;

    string constant POLY_ORACLE = "StablePolyUsdOracle";

     
     
     
     
     
    mapping(string => uint24) compatibleSTVersionRange;

     
    constructor(uint256 _setupCost, address _polymathRegistry, bool _isCostInPoly) public {
        setupCost = _setupCost;
        polymathRegistry = IPolymathRegistry(_polymathRegistry);
        isCostInPoly = _isCostInPoly;
    }

     
    function getTypes() external view returns(uint8[] memory) {
        return typesData;
    }

     
    function getTags() external view returns(bytes32[] memory) {
        return tagsData;
    }

     
    function version() external view returns(string memory) {
        return initialVersion;
    }

     
    function changeSetupCost(uint256 _setupCost) public onlyOwner {
        emit ChangeSetupCost(setupCost, _setupCost);
        setupCost = _setupCost;
    }

     
    function changeCostAndType(uint256 _setupCost, bool _isCostInPoly) public onlyOwner {
        emit ChangeSetupCost(setupCost, _setupCost);
        emit ChangeCostType(isCostInPoly, _isCostInPoly);
        setupCost = _setupCost;
        isCostInPoly = _isCostInPoly;
    }

     
    function changeTitle(string memory _title) public onlyOwner {
        require(bytes(_title).length > 0, "Invalid text");
        title = _title;
    }

     
    function changeDescription(string memory _description) public onlyOwner {
        require(bytes(_description).length > 0, "Invalid text");
        description = _description;
    }

     
    function changeName(bytes32 _name) public onlyOwner {
        require(_name != bytes32(0), "Invalid text");
        name = _name;
    }

     
    function changeTags(bytes32[] memory _tagsData) public onlyOwner {
        require(_tagsData.length > 0, "Invalid text");
        tagsData = _tagsData;
    }

     
    function changeSTVersionBounds(string calldata _boundType, uint8[] calldata _newVersion) external onlyOwner {
        require(
            keccak256(abi.encodePacked(_boundType)) == keccak256(abi.encodePacked("lowerBound")) || keccak256(
                abi.encodePacked(_boundType)
            ) == keccak256(abi.encodePacked("upperBound")),
            "Invalid bound type"
        );
        require(_newVersion.length == 3, "Invalid version");
        if (compatibleSTVersionRange[_boundType] != uint24(0)) {
            uint8[] memory _currentVersion = VersionUtils.unpack(compatibleSTVersionRange[_boundType]);
            if (keccak256(abi.encodePacked(_boundType)) == keccak256(abi.encodePacked("lowerBound"))) {
                require(VersionUtils.lessThanOrEqual(_newVersion, _currentVersion), "Invalid version");
            } else {
                require(VersionUtils.greaterThanOrEqual(_newVersion, _currentVersion), "Invalid version");
            }
        }
        compatibleSTVersionRange[_boundType] = VersionUtils.pack(_newVersion[0], _newVersion[1], _newVersion[2]);
        emit ChangeSTVersionBound(_boundType, _newVersion[0], _newVersion[1], _newVersion[2]);
    }

     
    function getLowerSTVersionBounds() external view returns(uint8[] memory) {
        return VersionUtils.unpack(compatibleSTVersionRange["lowerBound"]);
    }

     
    function getUpperSTVersionBounds() external view returns(uint8[] memory) {
        return VersionUtils.unpack(compatibleSTVersionRange["upperBound"]);
    }

     
    function setupCostInPoly() public returns (uint256) {
        if (isCostInPoly)
            return setupCost;
        uint256 polyRate = IOracle(polymathRegistry.getAddress(POLY_ORACLE)).getPrice();
        return DecimalMath.div(setupCost, polyRate);
    }

     
    function _takeFee() internal returns(uint256) {
        uint256 polySetupCost = setupCostInPoly();
        address polyToken = polymathRegistry.getAddress("PolyToken");
        if (polySetupCost > 0) {
            require(IERC20(polyToken).transferFrom(msg.sender, owner(), polySetupCost), "Insufficient allowance for module fee");
        }
        return polySetupCost;
    }

     
    function _initializeModule(address _module, bytes memory _data) internal {
        uint256 polySetupCost = _takeFee();
        bytes4 initFunction = IModule(_module).getInitFunction();
        if (initFunction != bytes4(0)) {
            require(Util.getSig(_data) == initFunction, "Provided data is not valid");
             
            (bool success, ) = _module.call(_data);
            require(success, "Unsuccessful initialization");
        }
         
        emit GenerateModuleFromFactory(_module, name, address(this), msg.sender, setupCost, polySetupCost);
    }

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

 
contract UpgradableModuleFactory is ModuleFactory {

    event LogicContractSet(string _version, uint256 _upgrade, address _logicContract, bytes _upgradeData);

    event ModuleUpgraded(
        address indexed _module,
        address indexed _securityToken,
        uint256 indexed _version
    );

    struct LogicContract {
        string version;
        address logicContract;
        bytes upgradeData;
    }

     
    mapping (uint256 => LogicContract) public logicContracts;

     
    mapping (address => mapping (address => uint256)) public modules;

     
    mapping (address => address) public moduleToSecurityToken;

     
    uint256 public latestUpgrade;

     
    constructor(
        string memory _version,
        uint256 _setupCost,
        address _logicContract,
        address _polymathRegistry,
        bool _isCostInPoly
    )
        public ModuleFactory(_setupCost, _polymathRegistry, _isCostInPoly)
    {
        require(_logicContract != address(0), "Invalid address");
        logicContracts[latestUpgrade].logicContract = _logicContract;
        logicContracts[latestUpgrade].version = _version;
    }

     
    function setLogicContract(string calldata _version, address _logicContract, bytes calldata _upgradeData) external onlyOwner {
        require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[latestUpgrade].version)), "Same version");
        require(_logicContract != logicContracts[latestUpgrade].logicContract, "Same version");
        require(_logicContract != address(0), "Invalid address");
        latestUpgrade++;
        _modifyLogicContract(latestUpgrade, _version, _logicContract, _upgradeData);
    }

     
    function updateLogicContract(uint256 _upgrade, string calldata _version, address _logicContract, bytes calldata _upgradeData) external onlyOwner {
        require(_upgrade <= latestUpgrade, "Invalid upgrade");
         
        if (_upgrade > 0) {
          require(keccak256(abi.encodePacked(_version)) != keccak256(abi.encodePacked(logicContracts[_upgrade - 1].version)), "Same version");
          require(_logicContract != logicContracts[_upgrade - 1].logicContract, "Same version");
        }
        require(_logicContract != address(0), "Invalid address");
        require(_upgradeData.length > 4, "Invalid Upgrade");
        _modifyLogicContract(_upgrade, _version, _logicContract, _upgradeData);
    }

    function _modifyLogicContract(uint256 _upgrade, string memory _version, address _logicContract, bytes memory _upgradeData) internal {
        logicContracts[_upgrade].version = _version;
        logicContracts[_upgrade].logicContract = _logicContract;
        logicContracts[_upgrade].upgradeData = _upgradeData;
        IModuleRegistry moduleRegistry = IModuleRegistry(polymathRegistry.getAddress("ModuleRegistry"));
        moduleRegistry.unverifyModule(address(this));
        emit LogicContractSet(_version, _upgrade, _logicContract, _upgradeData);
    }

     
    function upgrade(address _module) external {
         
        require(moduleToSecurityToken[_module] == msg.sender, "Incorrect caller");
         
        uint256 newVersion = modules[msg.sender][_module] + 1;
        require(newVersion <= latestUpgrade, "Incorrect version");
        OwnedUpgradeabilityProxy(address(uint160(_module))).upgradeToAndCall(logicContracts[newVersion].version, logicContracts[newVersion].logicContract, logicContracts[newVersion].upgradeData);
        modules[msg.sender][_module] = newVersion;
        emit ModuleUpgraded(
            _module,
            msg.sender,
            newVersion
        );
    }

     
    function _initializeModule(address _module, bytes memory _data) internal {
        super._initializeModule(_module, _data);
        moduleToSecurityToken[_module] = msg.sender;
        modules[msg.sender][_module] = latestUpgrade;
    }

     
    function version() external view returns(string memory) {
        return logicContracts[latestUpgrade].version;
    }

}

 
contract GeneralTransferManagerFactory is UpgradableModuleFactory {

     
    constructor (
        uint256 _setupCost,
        address _logicContract,
        address _polymathRegistry,
        bool _isCostInPoly
    )
        public
        UpgradableModuleFactory("3.0.0", _setupCost, _logicContract, _polymathRegistry, _isCostInPoly)
    {
        name = "GeneralTransferManager";
        title = "General Transfer Manager";
        description = "Manage transfers using a time based whitelist";
        typesData.push(2);
        typesData.push(6);
        tagsData.push("General");
        tagsData.push("Transfer Restriction");
        compatibleSTVersionRange["lowerBound"] = VersionUtils.pack(uint8(3), uint8(0), uint8(0));
        compatibleSTVersionRange["upperBound"] = VersionUtils.pack(uint8(3), uint8(0), uint8(0));
    }

     
    function deploy(
        bytes calldata _data
    )
        external
        returns(address)
    {
        address generalTransferManager = address(new GeneralTransferManagerProxy(logicContracts[latestUpgrade].version, msg.sender, polymathRegistry.getAddress("PolyToken"), logicContracts[latestUpgrade].logicContract));
        _initializeModule(generalTransferManager, _data);
        return generalTransferManager;
    }

}