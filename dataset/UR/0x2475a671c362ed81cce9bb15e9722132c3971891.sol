 

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

 
contract ERC20DividendCheckpointStorage {
     
    mapping(uint256 => address) public dividendTokens;

}

 
contract DividendCheckpointStorage {

     
    address payable public wallet;
    uint256 public EXCLUDED_ADDRESS_LIMIT = 150;

    struct Dividend {
        uint256 checkpointId;
        uint256 created;  
        uint256 maturity;  
        uint256 expiry;   
                          
        uint256 amount;  
        uint256 claimedAmount;  
        uint256 totalSupply;  
        bool reclaimed;   
        uint256 totalWithheld;
        uint256 totalWithheldWithdrawn;
        mapping (address => bool) claimed;  
        mapping (address => bool) dividendExcluded;  
        mapping (address => uint256) withheld;  
        bytes32 name;  
    }

     
    Dividend[] public dividends;

     
    address[] public excluded;

     
    mapping (address => uint256) public withholdingTax;

     
    mapping(address => uint256) public investorWithheld;

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

 
contract ERC20DividendCheckpointProxy is ERC20DividendCheckpointStorage, DividendCheckpointStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {
     
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
    }

}

 
contract EtherDividendCheckpointProxy is DividendCheckpointStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {
     
    constructor (
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
    }

}

contract PLCRVotingCheckpointStorage {

    enum Stage { PREP, COMMIT, REVEAL, RESOLVED }

    struct Ballot {
        uint256 checkpointId;  
        uint256 quorum;        
        uint64 commitDuration;  
        uint64 revealDuration;  
        uint64 startTime;        
        uint24 totalProposals;   
        uint32 totalVoters;      
        bool isActive;           
        mapping(uint256 => uint256) proposalToVotes;  
        mapping(address => Vote) investorToProposal;  
        mapping(address => bool) exemptedVoters;  
    }

    struct Vote {
        uint256 voteOption;
        bytes32 secretVote;
    }

    Ballot[] ballots;
}

contract VotingCheckpointStorage {

    mapping(address => uint256) defaultExemptIndex;
    address[] defaultExemptedVoters;

}

 
contract PLCRVotingCheckpointProxy is PLCRVotingCheckpointStorage, VotingCheckpointStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {
     
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
    }

}

contract WeightedVoteCheckpointStorage {

    struct Ballot {
        uint256 checkpointId;  
        uint256 quorum;        
        uint64 startTime;       
        uint64 endTime;          
        uint64 totalProposals;   
        uint56 totalVoters;      
        bool isActive;           
        mapping(uint256 => uint256) proposalToVotes;   
        mapping(address => uint256) investorToProposal;  
        mapping(address => bool) exemptedVoters;  
    }

    Ballot[] ballots;
}

 
contract WeightedVoteCheckpointProxy is WeightedVoteCheckpointStorage, VotingCheckpointStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {
     
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
    }

}

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 
contract GeneralPermissionManagerStorage {

     
    mapping (address => mapping (address => mapping (bytes32 => bool))) public perms;
     
    mapping (address => bytes32) public delegateDetails;
     
    address[] public allDelegates;

}

 
contract GeneralPermissionManagerProxy is GeneralPermissionManagerStorage, ModuleStorage, Pausable, ReentrancyGuard, OwnedUpgradeabilityProxy {

     
    constructor (
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 

contract STOStorage {
    bytes32 internal constant INVESTORFLAGS = "INVESTORFLAGS";

    mapping (uint8 => bool) public fundRaiseTypes;
    mapping (uint8 => uint256) public fundsRaised;

     
    uint256 public startTime;
     
    uint256 public endTime;
     
    uint256 public pausedTime;
     
    uint256 public investorCount;
     
    address payable public wallet;
     
    uint256 public totalTokensSold;

}

 
contract CappedSTOStorage {

     
    bool public allowBeneficialInvestments = false;
     
     
    uint256 public rate;
     
     
    uint256 public cap;

    mapping (address => uint256) public investors;

}

 
contract CappedSTOProxy is CappedSTOStorage, STOStorage, ModuleStorage, Pausable, ReentrancyGuard, OwnedUpgradeabilityProxy {

     
    constructor(
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract PreSaleSTOStorage {

    mapping (address => uint256) public investors;

}

 
contract PreSaleSTOProxy is PreSaleSTOStorage, STOStorage, ModuleStorage, Pausable, ReentrancyGuard, OwnedUpgradeabilityProxy {

     
    constructor (string memory _version, address _securityToken, address _polyAddress, address _implementation)
    public
    ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract USDTieredSTOStorage {

    bytes32 internal constant INVESTORSKEY = 0xdf3a8dd24acdd05addfc6aeffef7574d2de3f844535ec91e8e0f3e45dba96731;  
    
     
     
     
    struct Tier {
         
         
        uint256 rate;
         
        uint256 rateDiscountPoly;
         
        uint256 tokenTotal;
         
        uint256 tokensDiscountPoly;
         
        uint256 mintedTotal;
         
        mapping(uint8 => uint256) minted;
         
        uint256 mintedDiscountPoly;
    }

    mapping(address => uint256) public nonAccreditedLimitUSDOverride;

    mapping(bytes32 => mapping(bytes32 => string)) oracleKeys;

     
    bool public allowBeneficialInvestments;

     
    bool public isFinalized;

     
    address public treasuryWallet;

     
    IERC20[] internal usdTokens;

     
    uint256 public currentTier;

     
    uint256 public fundsRaisedUSD;

     
    mapping (address => uint256) public stableCoinsRaised;

     
    mapping(address => uint256) public investorInvestedUSD;

     
    mapping(address => mapping(uint8 => uint256)) public investorInvested;

     
    mapping (address => bool) internal usdTokenEnabled;

     
    uint256 public nonAccreditedLimitUSD;

     
    uint256 public minimumInvestmentUSD;

     
    uint256 public finalAmountReturned;

     
    Tier[] public tiers;

     
    mapping(bytes32 => mapping(bytes32 => address)) customOracles;
}

 
contract USDTieredSTOProxy is USDTieredSTOStorage, STOStorage, ModuleStorage, Pausable, ReentrancyGuard, OwnedUpgradeabilityProxy {
     
    constructor (string memory _version, address _securityToken, address _polyAddress, address _implementation) public ModuleStorage(_securityToken, _polyAddress) {
        require(_implementation != address(0), "Implementation address should not be 0x");
        _upgradeTo(_version, _implementation);
    }

}

 
contract BlacklistTransferManagerStorage {

    struct BlacklistsDetails {
        uint256 startTime;
        uint256 endTime;
        uint256 repeatPeriodTime;
    }

     
    mapping(bytes32 => BlacklistsDetails) public blacklists;

     
    mapping(address => bytes32[]) investorToBlacklist;

     
    mapping(bytes32 => address[]) blacklistToInvestor;

     
    mapping(address => mapping(bytes32 => uint256)) investorToIndex;

     
    mapping(bytes32 => mapping(address => uint256)) blacklistToIndex;

    bytes32[] allBlacklists;

}

 
contract BlacklistTransferManagerProxy is BlacklistTransferManagerStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {

     
    constructor (
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract CountTransferManagerStorage {

     
    uint256 public maxHolderCount;

}

 
contract CountTransferManagerProxy is CountTransferManagerStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {

     
    constructor (
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
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

 
contract LockUpTransferManagerStorage {

     
    struct LockUp {
        uint256 lockupAmount;  
        uint256 startTime;  
        uint256 lockUpPeriodSeconds;  
        uint256 releaseFrequencySeconds;  
    }

     
    mapping (bytes32 => LockUp) public lockups;
     
    mapping (address => bytes32[]) internal userToLockups;
     
    mapping (bytes32 => address[]) internal lockupToUsers;
     
    mapping (address => mapping(bytes32 => uint256)) internal userToLockupIndex;
     
    mapping (bytes32 => mapping(address => uint256)) internal lockupToUserIndex;

    bytes32[] lockupArray;

}

 
contract LockUpTransferManagerProxy is LockUpTransferManagerStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {

     
    constructor (
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract ManualApprovalTransferManagerStorage {

     
    struct ManualApproval {
        address from;
        address to;
        uint256 allowance;
        uint256 expiryTime;
        bytes32 description;
    }

    mapping (address => mapping (address => uint256)) public approvalIndex;

     
     
     
    ManualApproval[] public approvals;

}

 
contract ManualApprovalTransferManagerProxy is ManualApprovalTransferManagerStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {

     
    constructor (
        string memory _version,
        address _securityToken,
        address _polyAddress,
        address _implementation
    )
        public
        ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract PercentageTransferManagerStorage {

     
    uint256 public maxHolderPercentage;

     
    bool public allowPrimaryIssuance = true;

     
    mapping (address => bool) public whitelist;

}

 
contract PercentageTransferManagerProxy is PercentageTransferManagerStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {

     
    constructor (string memory _version, address _securityToken, address _polyAddress, address _implementation)
    public
    ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract VolumeRestrictionTMStorage {

    enum RestrictionType { Fixed, Percentage }

    enum TypeOfPeriod { MultipleDays, OneDay, Both }

     
    mapping(address => TypeOfPeriod) holderToRestrictionType;

    struct VolumeRestriction {
         
         
         
        uint256 allowedTokens;
        uint256 startTime;
        uint256 rollingPeriodInDays;
        uint256 endTime;
        RestrictionType typeOfRestriction;
    }

    struct IndividualRestrictions {
         
        mapping(address => VolumeRestriction) individualRestriction;
         
        mapping(address => VolumeRestriction) individualDailyRestriction;
    }

     
    IndividualRestrictions individualRestrictions;

    struct GlobalRestrictions {
       
      VolumeRestriction defaultRestriction;
       
      VolumeRestriction defaultDailyRestriction;
    }

     
    GlobalRestrictions globalRestrictions;

    struct BucketDetails {
        uint256 lastTradedDayTime;
        uint256 sumOfLastPeriod;    
        uint256 daysCovered;     
        uint256 dailyLastTradedDayTime;
        uint256 lastTradedTimestamp;  
    }

    struct BucketData {
         
        mapping(address => mapping(uint256 => uint256)) bucket;
         
        mapping(address => mapping(uint256 => uint256)) defaultBucket;
         
        mapping(address => BucketDetails) userToBucket;
         
        mapping(address => BucketDetails) defaultUserToBucket;
    }

    BucketData bucketData;

     
    struct Exemptions {
        mapping(address => uint256) exemptIndex;
        address[] exemptAddresses;
    }

    Exemptions exemptions;

}

 
contract VolumeRestrictionTMProxy is VolumeRestrictionTMStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {

     
    constructor (string memory _version, address _securityToken, address _polyAddress, address _implementation)
    public
    ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }

}

 
contract VestingEscrowWalletStorage {

    struct Schedule {
         
        bytes32 templateName;
         
        uint256 claimedTokens;
         
        uint256 startTime;
    }

    struct Template {
         
        uint256 numberOfTokens;
         
        uint256 duration;
         
        uint256 frequency;
         
        uint256 index;
    }

     
    uint256 public unassignedTokens;
     
    address public treasuryWallet;
     
    address[] public beneficiaries;
     
    mapping(address => bool) internal beneficiaryAdded;

     
    mapping(address => Schedule[]) public schedules;
     
    mapping(address => bytes32[]) internal userToTemplates;
     
     
    mapping(address => mapping(bytes32 => uint256)) internal userToTemplateIndex;
     
    mapping(bytes32 => address[]) internal templateToUsers;
     
     
    mapping(bytes32 => mapping(address => uint256)) internal templateToUserIndex;
     
    mapping(bytes32 => Template) templates;

     
    bytes32[] public templateNames;
}

 
contract VestingEscrowWalletProxy is VestingEscrowWalletStorage, ModuleStorage, Pausable, OwnedUpgradeabilityProxy {
      
    constructor (string memory _version, address _securityToken, address _polyAddress, address _implementation)
    public
    ModuleStorage(_securityToken, _polyAddress)
    {
        require(
            _implementation != address(0),
            "Implementation address should not be 0x"
        );
        _upgradeTo(_version, _implementation);
    }
 }