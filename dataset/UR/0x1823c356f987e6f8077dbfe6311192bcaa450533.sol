 

pragma solidity >=0.4.25 <0.6.0;
pragma experimental ABIEncoderV2;


contract Modifiable {
    
    
    
    modifier notNullAddress(address _address) {
        require(_address != address(0));
        _;
    }

    modifier notThisAddress(address _address) {
        require(_address != address(this));
        _;
    }

    modifier notNullOrThisAddress(address _address) {
        require(_address != address(0));
        require(_address != address(this));
        _;
    }

    modifier notSameAddresses(address _address1, address _address2) {
        if (_address1 != _address2)
            _;
    }
}

contract SelfDestructible {
    
    
    
    bool public selfDestructionDisabled;

    
    
    
    event SelfDestructionDisabledEvent(address wallet);
    event TriggerSelfDestructionEvent(address wallet);

    
    
    
    
    function destructor()
    public
    view
    returns (address);

    
    
    function disableSelfDestruction()
    public
    {
        
        require(destructor() == msg.sender);

        
        selfDestructionDisabled = true;

        
        emit SelfDestructionDisabledEvent(msg.sender);
    }

    
    function triggerSelfDestruction()
    public
    {
        
        require(destructor() == msg.sender);

        
        require(!selfDestructionDisabled);

        
        emit TriggerSelfDestructionEvent(msg.sender);

        
        selfdestruct(msg.sender);
    }
}

contract Ownable is Modifiable, SelfDestructible {
    
    
    
    address public deployer;
    address public operator;

    
    
    
    event SetDeployerEvent(address oldDeployer, address newDeployer);
    event SetOperatorEvent(address oldOperator, address newOperator);

    
    
    
    constructor(address _deployer) internal notNullOrThisAddress(_deployer) {
        deployer = _deployer;
        operator = _deployer;
    }

    
    
    
    
    function destructor()
    public
    view
    returns (address)
    {
        return deployer;
    }

    
    
    function setDeployer(address newDeployer)
    public
    onlyDeployer
    notNullOrThisAddress(newDeployer)
    {
        if (newDeployer != deployer) {
            
            address oldDeployer = deployer;
            deployer = newDeployer;

            
            emit SetDeployerEvent(oldDeployer, newDeployer);
        }
    }

    
    
    function setOperator(address newOperator)
    public
    onlyOperator
    notNullOrThisAddress(newOperator)
    {
        if (newOperator != operator) {
            
            address oldOperator = operator;
            operator = newOperator;

            
            emit SetOperatorEvent(oldOperator, newOperator);
        }
    }

    
    
    function isDeployer()
    internal
    view
    returns (bool)
    {
        return msg.sender == deployer;
    }

    
    
    function isOperator()
    internal
    view
    returns (bool)
    {
        return msg.sender == operator;
    }

    
    
    
    function isDeployerOrOperator()
    internal
    view
    returns (bool)
    {
        return isDeployer() || isOperator();
    }

    
    
    modifier onlyDeployer() {
        require(isDeployer());
        _;
    }

    modifier notDeployer() {
        require(!isDeployer());
        _;
    }

    modifier onlyOperator() {
        require(isOperator());
        _;
    }

    modifier notOperator() {
        require(!isOperator());
        _;
    }

    modifier onlyDeployerOrOperator() {
        require(isDeployerOrOperator());
        _;
    }

    modifier notDeployerOrOperator() {
        require(!isDeployerOrOperator());
        _;
    }
}

contract Servable is Ownable {
    
    
    
    struct ServiceInfo {
        bool registered;
        uint256 activationTimestamp;
        mapping(bytes32 => bool) actionsEnabledMap;
        bytes32[] actionsList;
    }

    
    
    
    mapping(address => ServiceInfo) internal registeredServicesMap;
    uint256 public serviceActivationTimeout;

    
    
    
    event ServiceActivationTimeoutEvent(uint256 timeoutInSeconds);
    event RegisterServiceEvent(address service);
    event RegisterServiceDeferredEvent(address service, uint256 timeout);
    event DeregisterServiceEvent(address service);
    event EnableServiceActionEvent(address service, string action);
    event DisableServiceActionEvent(address service, string action);

    
    
    
    
    
    function setServiceActivationTimeout(uint256 timeoutInSeconds)
    public
    onlyDeployer
    {
        serviceActivationTimeout = timeoutInSeconds;

        
        emit ServiceActivationTimeoutEvent(timeoutInSeconds);
    }

    
    
    function registerService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        _registerService(service, 0);

        
        emit RegisterServiceEvent(service);
    }

    
    
    function registerServiceDeferred(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        _registerService(service, serviceActivationTimeout);

        
        emit RegisterServiceDeferredEvent(service, serviceActivationTimeout);
    }

    
    
    function deregisterService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(registeredServicesMap[service].registered);

        registeredServicesMap[service].registered = false;

        
        emit DeregisterServiceEvent(service);
    }

    
    
    
    function enableServiceAction(address service, string memory action)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(registeredServicesMap[service].registered);

        bytes32 actionHash = hashString(action);

        require(!registeredServicesMap[service].actionsEnabledMap[actionHash]);

        registeredServicesMap[service].actionsEnabledMap[actionHash] = true;
        registeredServicesMap[service].actionsList.push(actionHash);

        
        emit EnableServiceActionEvent(service, action);
    }

    
    
    
    function disableServiceAction(address service, string memory action)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        bytes32 actionHash = hashString(action);

        require(registeredServicesMap[service].actionsEnabledMap[actionHash]);

        registeredServicesMap[service].actionsEnabledMap[actionHash] = false;

        
        emit DisableServiceActionEvent(service, action);
    }

    
    
    
    function isRegisteredService(address service)
    public
    view
    returns (bool)
    {
        return registeredServicesMap[service].registered;
    }

    
    
    
    function isRegisteredActiveService(address service)
    public
    view
    returns (bool)
    {
        return isRegisteredService(service) && block.timestamp >= registeredServicesMap[service].activationTimestamp;
    }

    
    
    
    function isEnabledServiceAction(address service, string memory action)
    public
    view
    returns (bool)
    {
        bytes32 actionHash = hashString(action);
        return isRegisteredActiveService(service) && registeredServicesMap[service].actionsEnabledMap[actionHash];
    }

    
    
    
    function hashString(string memory _string)
    internal
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_string));
    }

    
    
    
    function _registerService(address service, uint256 timeout)
    private
    {
        if (!registeredServicesMap[service].registered) {
            registeredServicesMap[service].registered = true;
            registeredServicesMap[service].activationTimestamp = block.timestamp + timeout;
        }
    }

    
    
    
    modifier onlyActiveService() {
        require(isRegisteredActiveService(msg.sender));
        _;
    }

    modifier onlyEnabledServiceAction(string memory action) {
        require(isEnabledServiceAction(msg.sender, action));
        _;
    }
}

contract CommunityVote is Ownable {
    
    
    
    mapping(address => bool) doubleSpenderByWallet;
    uint256 maxDriipNonce;
    uint256 maxNullNonce;
    bool dataAvailable;

    
    
    
    constructor(address deployer) Ownable(deployer) public {
        dataAvailable = true;
    }

    
    
    
    
    
    
    function isDoubleSpenderWallet(address wallet)
    public
    view
    returns (bool)
    {
        return doubleSpenderByWallet[wallet];
    }

    
    
    function getMaxDriipNonce()
    public
    view
    returns (uint256)
    {
        return maxDriipNonce;
    }

    
    
    function getMaxNullNonce()
    public
    view
    returns (uint256)
    {
        return maxNullNonce;
    }

    
    
    function isDataAvailable()
    public
    view
    returns (bool)
    {
        return dataAvailable;
    }
}

contract CommunityVotable is Ownable {
    
    
    
    CommunityVote public communityVote;
    bool public communityVoteFrozen;

    
    
    
    event SetCommunityVoteEvent(CommunityVote oldCommunityVote, CommunityVote newCommunityVote);
    event FreezeCommunityVoteEvent();

    
    
    
    
    
    function setCommunityVote(CommunityVote newCommunityVote) 
    public 
    onlyDeployer
    notNullAddress(address(newCommunityVote))
    notSameAddresses(address(newCommunityVote), address(communityVote))
    {
        require(!communityVoteFrozen, "Community vote frozen [CommunityVotable.sol:41]");

        
        CommunityVote oldCommunityVote = communityVote;
        communityVote = newCommunityVote;

        
        emit SetCommunityVoteEvent(oldCommunityVote, newCommunityVote);
    }

    
    
    function freezeCommunityVote()
    public
    onlyDeployer
    {
        communityVoteFrozen = true;

        
        emit FreezeCommunityVoteEvent();
    }

    
    
    
    modifier communityVoteInitialized() {
        require(address(communityVote) != address(0), "Community vote not initialized [CommunityVotable.sol:67]");
        _;
    }
}

contract Upgradable {
    
    
    
    address public upgradeAgent;
    bool public upgradesFrozen;

    
    
    
    event SetUpgradeAgentEvent(address upgradeAgent);
    event FreezeUpgradesEvent();

    
    
    
    
    
    function setUpgradeAgent(address _upgradeAgent)
    public
    onlyWhenUpgradable
    {
        require(address(0) == upgradeAgent, "Upgrade agent has already been set [Upgradable.sol:37]");

        
        upgradeAgent = _upgradeAgent;

        
        emit SetUpgradeAgentEvent(upgradeAgent);
    }

    
    
    function freezeUpgrades()
    public
    onlyWhenUpgrading
    {
        
        upgradesFrozen = true;

        
        emit FreezeUpgradesEvent();
    }

    
    
    
    modifier onlyWhenUpgrading() {
        require(msg.sender == upgradeAgent, "Caller is not upgrade agent [Upgradable.sol:63]");
        require(!upgradesFrozen, "Upgrades have been frozen [Upgradable.sol:64]");
        _;
    }

    modifier onlyWhenUpgradable() {
        require(!upgradesFrozen, "Upgrades have been frozen [Upgradable.sol:69]");
        _;
    }
}

contract Beneficiary {
    
    
    
    function receiveEthersTo(address wallet, string memory balanceType)
    public
    payable;

    
    
    
    
    
    
    
    
    function receiveTokensTo(address wallet, string memory balanceType, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public;
}

library MonetaryTypesLib {
    
    
    
    struct Currency {
        address ct;
        uint256 id;
    }

    struct Figure {
        int256 amount;
        Currency currency;
    }

    struct NoncedAmount {
        uint256 nonce;
        int256 amount;
    }
}

contract AccrualBeneficiary is Beneficiary {
    
    
    
    event CloseAccrualPeriodEvent();

    
    
    
    function closeAccrualPeriod(MonetaryTypesLib.Currency[] memory)
    public
    {
        emit CloseAccrualPeriodEvent();
    }
}

contract Benefactor is Ownable {
    
    
    
    Beneficiary[] public beneficiaries;
    mapping(address => uint256) public beneficiaryIndexByAddress;

    
    
    
    event RegisterBeneficiaryEvent(Beneficiary beneficiary);
    event DeregisterBeneficiaryEvent(Beneficiary beneficiary);

    
    
    
    
    
    function registerBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        address _beneficiary = address(beneficiary);

        if (beneficiaryIndexByAddress[_beneficiary] > 0)
            return false;

        beneficiaries.push(beneficiary);
        beneficiaryIndexByAddress[_beneficiary] = beneficiaries.length;

        
        emit RegisterBeneficiaryEvent(beneficiary);

        return true;
    }

    
    
    function deregisterBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        address _beneficiary = address(beneficiary);

        if (beneficiaryIndexByAddress[_beneficiary] == 0)
            return false;

        uint256 idx = beneficiaryIndexByAddress[_beneficiary] - 1;
        if (idx < beneficiaries.length - 1) {
            
            beneficiaries[idx] = beneficiaries[beneficiaries.length - 1];
            beneficiaryIndexByAddress[address(beneficiaries[idx])] = idx + 1;
        }
        beneficiaries.length--;
        beneficiaryIndexByAddress[_beneficiary] = 0;

        
        emit DeregisterBeneficiaryEvent(beneficiary);

        return true;
    }

    
    
    
    function isRegisteredBeneficiary(Beneficiary beneficiary)
    public
    view
    returns (bool)
    {
        return beneficiaryIndexByAddress[address(beneficiary)] > 0;
    }

    
    
    function registeredBeneficiariesCount()
    public
    view
    returns (uint256)
    {
        return beneficiaries.length;
    }
}

library SafeMathIntLib {
    int256 constant INT256_MIN = int256((uint256(1) << 255));
    int256 constant INT256_MAX = int256(~((uint256(1) << 255)));

    
    
    
    function div(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a != INT256_MIN || b != - 1);
        return a / b;
    }

    function mul(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a != - 1 || b != INT256_MIN);
        
        require(b != - 1 || a != INT256_MIN);
        
        int256 c = a * b;
        require((b == 0) || (c / b == a));
        return c;
    }

    function sub(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require((b >= 0 && a - b <= a) || (b < 0 && a - b > a));
        return a - b;
    }

    function add(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    
    
    
    function div_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b > 0);
        return a / b;
    }

    function mul_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0);
        int256 c = a * b;
        require(a == 0 || c / a == b);
        require(c >= 0);
        return c;
    }

    function sub_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0 && b <= a);
        return a - b;
    }

    function add_nn(int256 a, int256 b)
    internal
    pure
    returns (int256)
    {
        require(a >= 0 && b >= 0);
        int256 c = a + b;
        require(c >= a);
        return c;
    }

    
    
    
    function abs(int256 a)
    public
    pure
    returns (int256)
    {
        return a < 0 ? neg(a) : a;
    }

    function neg(int256 a)
    public
    pure
    returns (int256)
    {
        return mul(a, - 1);
    }

    function toNonZeroInt256(uint256 a)
    public
    pure
    returns (int256)
    {
        require(a > 0 && a < (uint256(1) << 255));
        return int256(a);
    }

    function toInt256(uint256 a)
    public
    pure
    returns (int256)
    {
        require(a >= 0 && a < (uint256(1) << 255));
        return int256(a);
    }

    function toUInt256(int256 a)
    public
    pure
    returns (uint256)
    {
        require(a >= 0);
        return uint256(a);
    }

    function isNonZeroPositiveInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a > 0);
    }

    function isPositiveInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a >= 0);
    }

    function isNonZeroNegativeInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a < 0);
    }

    function isNegativeInt256(int256 a)
    public
    pure
    returns (bool)
    {
        return (a <= 0);
    }

    
    
    
    function clamp(int256 a, int256 min, int256 max)
    public
    pure
    returns (int256)
    {
        if (a < min)
            return min;
        return (a > max) ? max : a;
    }

    function clampMin(int256 a, int256 min)
    public
    pure
    returns (int256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(int256 a, int256 max)
    public
    pure
    returns (int256)
    {
        return (a > max) ? max : a;
    }
}

library ConstantsLib {
    
    function PARTS_PER()
    public
    pure
    returns (int256)
    {
        return 1e18;
    }
}

contract AccrualBenefactor is Benefactor {
    using SafeMathIntLib for int256;

    
    
    
    mapping(address => int256) private _beneficiaryFractionMap;
    int256 public totalBeneficiaryFraction;

    
    
    
    event RegisterAccrualBeneficiaryEvent(Beneficiary beneficiary, int256 fraction);
    event DeregisterAccrualBeneficiaryEvent(Beneficiary beneficiary);

    
    
    
    
    
    function registerBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        return registerFractionalBeneficiary(AccrualBeneficiary(address(beneficiary)), ConstantsLib.PARTS_PER());
    }

    
    
    
    function registerFractionalBeneficiary(AccrualBeneficiary beneficiary, int256 fraction)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        require(fraction > 0, "Fraction not strictly positive [AccrualBenefactor.sol:59]");
        require(
            totalBeneficiaryFraction.add(fraction) <= ConstantsLib.PARTS_PER(),
            "Total beneficiary fraction out of bounds [AccrualBenefactor.sol:60]"
        );

        if (!super.registerBeneficiary(beneficiary))
            return false;

        _beneficiaryFractionMap[address(beneficiary)] = fraction;
        totalBeneficiaryFraction = totalBeneficiaryFraction.add(fraction);

        
        emit RegisterAccrualBeneficiaryEvent(beneficiary, fraction);

        return true;
    }

    
    
    function deregisterBeneficiary(Beneficiary beneficiary)
    public
    onlyDeployer
    notNullAddress(address(beneficiary))
    returns (bool)
    {
        if (!super.deregisterBeneficiary(beneficiary))
            return false;

        address _beneficiary = address(beneficiary);

        totalBeneficiaryFraction = totalBeneficiaryFraction.sub(_beneficiaryFractionMap[_beneficiary]);
        _beneficiaryFractionMap[_beneficiary] = 0;

        
        emit DeregisterAccrualBeneficiaryEvent(beneficiary);

        return true;
    }

    
    
    
    function beneficiaryFraction(AccrualBeneficiary beneficiary)
    public
    view
    returns (int256)
    {
        return _beneficiaryFractionMap[address(beneficiary)];
    }
}

contract TransferController {
    
    
    
    event CurrencyTransferred(address from, address to, uint256 value,
        address currencyCt, uint256 currencyId);

    
    
    
    function isFungible()
    public
    view
    returns (bool);

    function standard()
    public
    view
    returns (string memory);

    
    function receive(address from, address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    
    function approve(address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    
    function dispatch(address from, address to, uint256 value, address currencyCt, uint256 currencyId)
    public;

    

    function getReceiveSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("receive(address,address,uint256,address,uint256)"));
    }

    function getApproveSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("approve(address,uint256,address,uint256)"));
    }

    function getDispatchSignature()
    public
    pure
    returns (bytes4)
    {
        return bytes4(keccak256("dispatch(address,address,uint256,address,uint256)"));
    }
}

contract TransferControllerManager is Ownable {
    
    
    
    struct CurrencyInfo {
        bytes32 standard;
        bool blacklisted;
    }

    
    
    
    mapping(bytes32 => address) public registeredTransferControllers;
    mapping(address => CurrencyInfo) public registeredCurrencies;

    
    
    
    event RegisterTransferControllerEvent(string standard, address controller);
    event ReassociateTransferControllerEvent(string oldStandard, string newStandard, address controller);

    event RegisterCurrencyEvent(address currencyCt, string standard);
    event DeregisterCurrencyEvent(address currencyCt);
    event BlacklistCurrencyEvent(address currencyCt);
    event WhitelistCurrencyEvent(address currencyCt);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    function registerTransferController(string calldata standard, address controller)
    external
    onlyDeployer
    notNullAddress(controller)
    {
        require(bytes(standard).length > 0, "Empty standard not supported [TransferControllerManager.sol:58]");
        bytes32 standardHash = keccak256(abi.encodePacked(standard));

        registeredTransferControllers[standardHash] = controller;

        
        emit RegisterTransferControllerEvent(standard, controller);
    }

    function reassociateTransferController(string calldata oldStandard, string calldata newStandard, address controller)
    external
    onlyDeployer
    notNullAddress(controller)
    {
        require(bytes(newStandard).length > 0, "Empty new standard not supported [TransferControllerManager.sol:72]");
        bytes32 oldStandardHash = keccak256(abi.encodePacked(oldStandard));
        bytes32 newStandardHash = keccak256(abi.encodePacked(newStandard));

        require(registeredTransferControllers[oldStandardHash] != address(0), "Old standard not registered [TransferControllerManager.sol:76]");
        require(registeredTransferControllers[newStandardHash] == address(0), "New standard previously registered [TransferControllerManager.sol:77]");

        registeredTransferControllers[newStandardHash] = registeredTransferControllers[oldStandardHash];
        registeredTransferControllers[oldStandardHash] = address(0);

        
        emit ReassociateTransferControllerEvent(oldStandard, newStandard, controller);
    }

    function registerCurrency(address currencyCt, string calldata standard)
    external
    onlyOperator
    notNullAddress(currencyCt)
    {
        require(bytes(standard).length > 0, "Empty standard not supported [TransferControllerManager.sol:91]");
        bytes32 standardHash = keccak256(abi.encodePacked(standard));

        require(registeredCurrencies[currencyCt].standard == bytes32(0), "Currency previously registered [TransferControllerManager.sol:94]");

        registeredCurrencies[currencyCt].standard = standardHash;

        
        emit RegisterCurrencyEvent(currencyCt, standard);
    }

    function deregisterCurrency(address currencyCt)
    external
    onlyOperator
    {
        require(registeredCurrencies[currencyCt].standard != 0, "Currency not registered [TransferControllerManager.sol:106]");

        registeredCurrencies[currencyCt].standard = bytes32(0);
        registeredCurrencies[currencyCt].blacklisted = false;

        
        emit DeregisterCurrencyEvent(currencyCt);
    }

    function blacklistCurrency(address currencyCt)
    external
    onlyOperator
    {
        require(registeredCurrencies[currencyCt].standard != bytes32(0), "Currency not registered [TransferControllerManager.sol:119]");

        registeredCurrencies[currencyCt].blacklisted = true;

        
        emit BlacklistCurrencyEvent(currencyCt);
    }

    function whitelistCurrency(address currencyCt)
    external
    onlyOperator
    {
        require(registeredCurrencies[currencyCt].standard != bytes32(0), "Currency not registered [TransferControllerManager.sol:131]");

        registeredCurrencies[currencyCt].blacklisted = false;

        
        emit WhitelistCurrencyEvent(currencyCt);
    }

    
    function transferController(address currencyCt, string memory standard)
    public
    view
    returns (TransferController)
    {
        if (bytes(standard).length > 0) {
            bytes32 standardHash = keccak256(abi.encodePacked(standard));

            require(registeredTransferControllers[standardHash] != address(0), "Standard not registered [TransferControllerManager.sol:150]");
            return TransferController(registeredTransferControllers[standardHash]);
        }

        require(registeredCurrencies[currencyCt].standard != bytes32(0), "Currency not registered [TransferControllerManager.sol:154]");
        require(!registeredCurrencies[currencyCt].blacklisted, "Currency blacklisted [TransferControllerManager.sol:155]");

        address controllerAddress = registeredTransferControllers[registeredCurrencies[currencyCt].standard];
        require(controllerAddress != address(0), "No matching transfer controller [TransferControllerManager.sol:158]");

        return TransferController(controllerAddress);
    }
}

contract TransferControllerManageable is Ownable {
    
    
    
    TransferControllerManager public transferControllerManager;

    
    
    
    event SetTransferControllerManagerEvent(TransferControllerManager oldTransferControllerManager,
        TransferControllerManager newTransferControllerManager);

    
    
    
    
    
    function setTransferControllerManager(TransferControllerManager newTransferControllerManager)
    public
    onlyDeployer
    notNullAddress(address(newTransferControllerManager))
    notSameAddresses(address(newTransferControllerManager), address(transferControllerManager))
    {
        
        TransferControllerManager oldTransferControllerManager = transferControllerManager;
        transferControllerManager = newTransferControllerManager;

        
        emit SetTransferControllerManagerEvent(oldTransferControllerManager, newTransferControllerManager);
    }

    
    function transferController(address currencyCt, string memory standard)
    internal
    view
    returns (TransferController)
    {
        return transferControllerManager.transferController(currencyCt, standard);
    }

    
    
    
    modifier transferControllerManagerInitialized() {
        require(address(transferControllerManager) != address(0), "Transfer controller manager not initialized [TransferControllerManageable.sol:63]");
        _;
    }
}

library SafeMathUintLib {
    function mul(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        
        uint256 c = a / b;
        
        return c;
    }

    function sub(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b)
    internal
    pure
    returns (uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    
    
    
    function clamp(uint256 a, uint256 min, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : ((a < min) ? min : a);
    }

    function clampMin(uint256 a, uint256 min)
    public
    pure
    returns (uint256)
    {
        return (a < min) ? min : a;
    }

    function clampMax(uint256 a, uint256 max)
    public
    pure
    returns (uint256)
    {
        return (a > max) ? max : a;
    }
}

library CurrenciesLib {
    using SafeMathUintLib for uint256;

    
    
    
    struct Currencies {
        MonetaryTypesLib.Currency[] currencies;
        mapping(address => mapping(uint256 => uint256)) indexByCurrency;
    }

    
    
    
    function add(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    {
        
        if (0 == self.indexByCurrency[currencyCt][currencyId]) {
            self.currencies.push(MonetaryTypesLib.Currency(currencyCt, currencyId));
            self.indexByCurrency[currencyCt][currencyId] = self.currencies.length;
        }
    }

    function removeByCurrency(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    {
        
        uint256 index = self.indexByCurrency[currencyCt][currencyId];
        if (0 < index)
            removeByIndex(self, index - 1);
    }

    function removeByIndex(Currencies storage self, uint256 index)
    internal
    {
        require(index < self.currencies.length, "Index out of bounds [CurrenciesLib.sol:51]");

        address currencyCt = self.currencies[index].ct;
        uint256 currencyId = self.currencies[index].id;

        if (index < self.currencies.length - 1) {
            self.currencies[index] = self.currencies[self.currencies.length - 1];
            self.indexByCurrency[self.currencies[index].ct][self.currencies[index].id] = index + 1;
        }
        self.currencies.length--;
        self.indexByCurrency[currencyCt][currencyId] = 0;
    }

    function count(Currencies storage self)
    internal
    view
    returns (uint256)
    {
        return self.currencies.length;
    }

    function has(Currencies storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return 0 != self.indexByCurrency[currencyCt][currencyId];
    }

    function getByIndex(Currencies storage self, uint256 index)
    internal
    view
    returns (MonetaryTypesLib.Currency memory)
    {
        require(index < self.currencies.length, "Index out of bounds [CurrenciesLib.sol:85]");
        return self.currencies[index];
    }

    function getByIndices(Currencies storage self, uint256 low, uint256 up)
    internal
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        require(0 < self.currencies.length, "No currencies found [CurrenciesLib.sol:94]");
        require(low <= up, "Bounds parameters mismatch [CurrenciesLib.sol:95]");

        up = up.clampMax(self.currencies.length - 1);
        MonetaryTypesLib.Currency[] memory _currencies = new MonetaryTypesLib.Currency[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _currencies[i - low] = self.currencies[i];

        return _currencies;
    }
}

library FungibleBalanceLib {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

    
    
    
    struct Record {
        int256 amount;
        uint256 blockNumber;
    }

    struct Balance {
        mapping(address => mapping(uint256 => int256)) amountByCurrency;
        mapping(address => mapping(uint256 => Record[])) recordsByCurrency;

        CurrenciesLib.Currencies inUseCurrencies;
        CurrenciesLib.Currencies everUsedCurrencies;
    }

    
    
    
    function get(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256)
    {
        return self.amountByCurrency[currencyCt][currencyId];
    }

    function getByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256)
    {
        (int256 amount,) = recordByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return amount;
    }

    function set(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = amount;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function setByBlockNumber(Balance storage self, int256 amount, address currencyCt, uint256 currencyId,
        uint256 blockNumber)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = amount;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], blockNumber)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function add(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function addByBlockNumber(Balance storage self, int256 amount, address currencyCt, uint256 currencyId,
        uint256 blockNumber)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], blockNumber)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function sub(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function subByBlockNumber(Balance storage self, int256 amount, address currencyCt, uint256 currencyId,
        uint256 blockNumber)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], blockNumber)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function transfer(Balance storage _from, Balance storage _to, int256 amount,
        address currencyCt, uint256 currencyId)
    internal
    {
        sub(_from, amount, currencyCt, currencyId);
        add(_to, amount, currencyCt, currencyId);
    }

    function add_nn(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add_nn(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function sub_nn(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].sub_nn(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
        );

        updateCurrencies(self, currencyCt, currencyId);
    }

    function transfer_nn(Balance storage _from, Balance storage _to, int256 amount,
        address currencyCt, uint256 currencyId)
    internal
    {
        sub_nn(_from, amount, currencyCt, currencyId);
        add_nn(_to, amount, currencyCt, currencyId);
    }

    function recordsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.recordsByCurrency[currencyCt][currencyId].length;
    }

    function recordByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256, uint256)
    {
        uint256 index = indexByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return 0 < index ? recordByIndex(self, currencyCt, currencyId, index - 1) : (0, 0);
    }

    function recordByIndex(Balance storage self, address currencyCt, uint256 currencyId, uint256 index)
    internal
    view
    returns (int256, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (0, 0);

        index = index.clampMax(self.recordsByCurrency[currencyCt][currencyId].length - 1);
        Record storage record = self.recordsByCurrency[currencyCt][currencyId][index];
        return (record.amount, record.blockNumber);
    }

    function lastRecord(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (0, 0);

        Record storage record = self.recordsByCurrency[currencyCt][currencyId][self.recordsByCurrency[currencyCt][currencyId].length - 1];
        return (record.amount, record.blockNumber);
    }

    function hasInUseCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.inUseCurrencies.has(currencyCt, currencyId);
    }

    function hasEverUsedCurrency(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return self.everUsedCurrencies.has(currencyCt, currencyId);
    }

    function updateCurrencies(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        if (0 == self.amountByCurrency[currencyCt][currencyId] && self.inUseCurrencies.has(currencyCt, currencyId))
            self.inUseCurrencies.removeByCurrency(currencyCt, currencyId);
        else if (!self.inUseCurrencies.has(currencyCt, currencyId)) {
            self.inUseCurrencies.add(currencyCt, currencyId);
            self.everUsedCurrencies.add(currencyCt, currencyId);
        }
    }

    function indexByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return 0;
        for (uint256 i = self.recordsByCurrency[currencyCt][currencyId].length; i > 0; i--)
            if (self.recordsByCurrency[currencyCt][currencyId][i - 1].blockNumber <= blockNumber)
                return i;
        return 0;
    }
}

library TxHistoryLib {
    
    
    
    struct AssetEntry {
        int256 amount;
        uint256 blockNumber;
        address currencyCt;      
        uint256 currencyId;
    }

    struct TxHistory {
        AssetEntry[] deposits;
        mapping(address => mapping(uint256 => AssetEntry[])) currencyDeposits;

        AssetEntry[] withdrawals;
        mapping(address => mapping(uint256 => AssetEntry[])) currencyWithdrawals;
    }

    
    
    
    function addDeposit(TxHistory storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        AssetEntry memory deposit = AssetEntry(amount, block.number, currencyCt, currencyId);
        self.deposits.push(deposit);
        self.currencyDeposits[currencyCt][currencyId].push(deposit);
    }

    function addWithdrawal(TxHistory storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        AssetEntry memory withdrawal = AssetEntry(amount, block.number, currencyCt, currencyId);
        self.withdrawals.push(withdrawal);
        self.currencyWithdrawals[currencyCt][currencyId].push(withdrawal);
    }

    

    function deposit(TxHistory storage self, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        require(index < self.deposits.length, "Index ouf of bounds [TxHistoryLib.sol:56]");

        amount = self.deposits[index].amount;
        blockNumber = self.deposits[index].blockNumber;
        currencyCt = self.deposits[index].currencyCt;
        currencyId = self.deposits[index].currencyId;
    }

    function depositsCount(TxHistory storage self)
    internal
    view
    returns (uint256)
    {
        return self.deposits.length;
    }

    function currencyDeposit(TxHistory storage self, address currencyCt, uint256 currencyId, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber)
    {
        require(index < self.currencyDeposits[currencyCt][currencyId].length, "Index out of bounds [TxHistoryLib.sol:77]");

        amount = self.currencyDeposits[currencyCt][currencyId][index].amount;
        blockNumber = self.currencyDeposits[currencyCt][currencyId][index].blockNumber;
    }

    function currencyDepositsCount(TxHistory storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.currencyDeposits[currencyCt][currencyId].length;
    }

    

    function withdrawal(TxHistory storage self, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        require(index < self.withdrawals.length, "Index out of bounds [TxHistoryLib.sol:98]");

        amount = self.withdrawals[index].amount;
        blockNumber = self.withdrawals[index].blockNumber;
        currencyCt = self.withdrawals[index].currencyCt;
        currencyId = self.withdrawals[index].currencyId;
    }

    function withdrawalsCount(TxHistory storage self)
    internal
    view
    returns (uint256)
    {
        return self.withdrawals.length;
    }

    function currencyWithdrawal(TxHistory storage self, address currencyCt, uint256 currencyId, uint index)
    internal
    view
    returns (int256 amount, uint256 blockNumber)
    {
        require(index < self.currencyWithdrawals[currencyCt][currencyId].length, "Index out of bounds [TxHistoryLib.sol:119]");

        amount = self.currencyWithdrawals[currencyCt][currencyId][index].amount;
        blockNumber = self.currencyWithdrawals[currencyCt][currencyId][index].blockNumber;
    }

    function currencyWithdrawalsCount(TxHistory storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.currencyWithdrawals[currencyCt][currencyId].length;
    }
}

contract RevenueFund is Ownable, AccrualBeneficiary, AccrualBenefactor, TransferControllerManageable {
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using TxHistoryLib for TxHistoryLib.TxHistory;
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

    
    
    
    FungibleBalanceLib.Balance periodAccrual;
    CurrenciesLib.Currencies periodCurrencies;

    FungibleBalanceLib.Balance aggregateAccrual;
    CurrenciesLib.Currencies aggregateCurrencies;

    TxHistoryLib.TxHistory private txHistory;

    
    
    
    event ReceiveEvent(address from, int256 amount, address currencyCt, uint256 currencyId);
    event CloseAccrualPeriodEvent();
    event RegisterServiceEvent(address service);
    event DeregisterServiceEvent(address service);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    
    function() external payable {
        receiveEthersTo(msg.sender, "");
    }

    
    
    function receiveEthersTo(address wallet, string memory)
    public
    payable
    {
        int256 amount = SafeMathIntLib.toNonZeroInt256(msg.value);

        
        periodAccrual.add(amount, address(0), 0);
        aggregateAccrual.add(amount, address(0), 0);

        
        periodCurrencies.add(address(0), 0);
        aggregateCurrencies.add(address(0), 0);

        
        txHistory.addDeposit(amount, address(0), 0);

        
        emit ReceiveEvent(wallet, amount, address(0), 0);
    }

    
    
    
    
    
    function receiveTokens(string memory balanceType, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        receiveTokensTo(msg.sender, balanceType, amount, currencyCt, currencyId, standard);
    }

    
    
    
    
    
    
    function receiveTokensTo(address wallet, string memory, int256 amount,
        address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        require(amount.isNonZeroPositiveInt256(), "Amount not strictly positive [RevenueFund.sol:115]");

        
        TransferController controller = transferController(currencyCt, standard);
        (bool success,) = address(controller).delegatecall(
            abi.encodeWithSelector(
                controller.getReceiveSignature(), msg.sender, this, uint256(amount), currencyCt, currencyId
            )
        );
        require(success, "Reception by controller failed [RevenueFund.sol:124]");

        
        periodAccrual.add(amount, currencyCt, currencyId);
        aggregateAccrual.add(amount, currencyCt, currencyId);

        
        periodCurrencies.add(currencyCt, currencyId);
        aggregateCurrencies.add(currencyCt, currencyId);

        
        txHistory.addDeposit(amount, currencyCt, currencyId);

        
        emit ReceiveEvent(wallet, amount, currencyCt, currencyId);
    }

    
    
    
    
    function periodAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return periodAccrual.get(currencyCt, currencyId);
    }

    
    
    
    
    
    function aggregateAccrualBalance(address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return aggregateAccrual.get(currencyCt, currencyId);
    }

    
    
    function periodCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return periodCurrencies.count();
    }

    
    
    
    
    function periodCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        return periodCurrencies.getByIndices(low, up);
    }

    
    
    function aggregateCurrenciesCount()
    public
    view
    returns (uint256)
    {
        return aggregateCurrencies.count();
    }

    
    
    
    
    function aggregateCurrenciesByIndices(uint256 low, uint256 up)
    public
    view
    returns (MonetaryTypesLib.Currency[] memory)
    {
        return aggregateCurrencies.getByIndices(low, up);
    }

    
    
    function depositsCount()
    public
    view
    returns (uint256)
    {
        return txHistory.depositsCount();
    }

    
    
    function deposit(uint index)
    public
    view
    returns (int256 amount, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        return txHistory.deposit(index);
    }

    
    
    function closeAccrualPeriod(MonetaryTypesLib.Currency[] memory currencies)
    public
    onlyOperator
    {
        require(
            ConstantsLib.PARTS_PER() == totalBeneficiaryFraction,
            "Total beneficiary fraction out of bounds [RevenueFund.sol:236]"
        );

        
        for (uint256 i = 0; i < currencies.length; i++) {
            MonetaryTypesLib.Currency memory currency = currencies[i];

            int256 remaining = periodAccrual.get(currency.ct, currency.id);

            if (0 >= remaining)
                continue;

            for (uint256 j = 0; j < beneficiaries.length; j++) {
                AccrualBeneficiary beneficiary = AccrualBeneficiary(address(beneficiaries[j]));

                if (beneficiaryFraction(beneficiary) > 0) {
                    int256 transferable = periodAccrual.get(currency.ct, currency.id)
                    .mul(beneficiaryFraction(beneficiary))
                    .div(ConstantsLib.PARTS_PER());

                    if (transferable > remaining)
                        transferable = remaining;

                    if (transferable > 0) {
                        
                        if (currency.ct == address(0))
                            beneficiary.receiveEthersTo.value(uint256(transferable))(address(0), "");

                        
                        else {
                            TransferController controller = transferController(currency.ct, "");
                            (bool success,) = address(controller).delegatecall(
                                abi.encodeWithSelector(
                                    controller.getApproveSignature(), address(beneficiary), uint256(transferable), currency.ct, currency.id
                                )
                            );
                            require(success, "Approval by controller failed [RevenueFund.sol:274]");

                            beneficiary.receiveTokensTo(address(0), "", transferable, currency.ct, currency.id, "");
                        }

                        remaining = remaining.sub(transferable);
                    }
                }
            }

            
            periodAccrual.set(remaining, currency.ct, currency.id);
        }

        
        for (uint256 j = 0; j < beneficiaries.length; j++) {
            AccrualBeneficiary beneficiary = AccrualBeneficiary(address(beneficiaries[j]));

            
            if (0 >= beneficiaryFraction(beneficiary))
                continue;

            
            beneficiary.closeAccrualPeriod(currencies);
        }

        
        emit CloseAccrualPeriodEvent();
    }
}

library Strings {

    
    function concat(string memory _base, string memory _value)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length > 0);

        string memory _tmpValue = new string(_baseBytes.length +
            _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for (i = 0; i < _baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for (i = 0; i < _valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

    
    function indexOf(string memory _base, string memory _value)
        internal
        pure
        returns (int) {
        return _indexOf(_base, _value, 0);
    }

    
    function _indexOf(string memory _base, string memory _value, uint _offset)
        internal
        pure
        returns (int) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        assert(_valueBytes.length == 1);

        for (uint i = _offset; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == _valueBytes[0]) {
                return int(i);
            }
        }

        return -1;
    }

    
    function length(string memory _base)
        internal
        pure
        returns (uint) {
        bytes memory _baseBytes = bytes(_base);
        return _baseBytes.length;
    }

    
    function substring(string memory _base, int _length)
        internal
        pure
        returns (string memory) {
        return _substring(_base, _length, 0);
    }

    
    function _substring(string memory _base, int _length, int _offset)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);

        assert(uint(_offset + _length) <= _baseBytes.length);

        string memory _tmp = new string(uint(_length));
        bytes memory _tmpBytes = bytes(_tmp);

        uint j = 0;
        for (uint i = uint(_offset); i < uint(_offset + _length); i++) {
            _tmpBytes[j++] = _baseBytes[i];
        }

        return string(_tmpBytes);
    }

    
    function split(string memory _base, string memory _value)
        internal
        pure
        returns (string[] memory splitArr) {
        bytes memory _baseBytes = bytes(_base);

        uint _offset = 0;
        uint _splitsCount = 1;
        while (_offset < _baseBytes.length - 1) {
            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == -1)
                break;
            else {
                _splitsCount++;
                _offset = uint(_limit) + 1;
            }
        }

        splitArr = new string[](_splitsCount);

        _offset = 0;
        _splitsCount = 0;
        while (_offset < _baseBytes.length - 1) {

            int _limit = _indexOf(_base, _value, _offset);
            if (_limit == - 1) {
                _limit = int(_baseBytes.length);
            }

            string memory _tmp = new string(uint(_limit) - _offset);
            bytes memory _tmpBytes = bytes(_tmp);

            uint j = 0;
            for (uint i = _offset; i < uint(_limit); i++) {
                _tmpBytes[j++] = _baseBytes[i];
            }
            _offset = uint(_limit) + 1;
            splitArr[_splitsCount++] = string(_tmpBytes);
        }
        return splitArr;
    }

    
    function compareTo(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i]) {
                return false;
            }
        }

        return true;
    }

    
    function compareToIgnoreCase(string memory _base, string memory _value)
        internal
        pure
        returns (bool) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        if (_baseBytes.length != _valueBytes.length) {
            return false;
        }

        for (uint i = 0; i < _baseBytes.length; i++) {
            if (_baseBytes[i] != _valueBytes[i] &&
            _upper(_baseBytes[i]) != _upper(_valueBytes[i])) {
                return false;
            }
        }

        return true;
    }

    
    function upper(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _upper(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    
    function lower(string memory _base)
        internal
        pure
        returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        for (uint i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);
        }
        return string(_baseBytes);
    }

    
    function _upper(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x61 && _b1 <= 0x7A) {
            return bytes1(uint8(_b1) - 32);
        }

        return _b1;
    }

    
    function _lower(bytes1 _b1)
        private
        pure
        returns (bytes1) {

        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

contract PartnerFund is Ownable, Beneficiary, TransferControllerManageable {
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using TxHistoryLib for TxHistoryLib.TxHistory;
    using SafeMathIntLib for int256;
    using Strings for string;

    
    
    
    struct Partner {
        bytes32 nameHash;

        uint256 fee;
        address wallet;
        uint256 index;

        bool operatorCanUpdate;
        bool partnerCanUpdate;

        FungibleBalanceLib.Balance active;
        FungibleBalanceLib.Balance staged;

        TxHistoryLib.TxHistory txHistory;
        FullBalanceHistory[] fullBalanceHistory;
    }

    struct FullBalanceHistory {
        uint256 listIndex;
        int256 balance;
        uint256 blockNumber;
    }

    
    
    
    Partner[] private partners;

    mapping(bytes32 => uint256) private _indexByNameHash;
    mapping(address => uint256) private _indexByWallet;

    
    
    
    event ReceiveEvent(address from, int256 amount, address currencyCt, uint256 currencyId);
    event RegisterPartnerByNameEvent(string name, uint256 fee, address wallet);
    event RegisterPartnerByNameHashEvent(bytes32 nameHash, uint256 fee, address wallet);
    event SetFeeByIndexEvent(uint256 index, uint256 oldFee, uint256 newFee);
    event SetFeeByNameEvent(string name, uint256 oldFee, uint256 newFee);
    event SetFeeByNameHashEvent(bytes32 nameHash, uint256 oldFee, uint256 newFee);
    event SetFeeByWalletEvent(address wallet, uint256 oldFee, uint256 newFee);
    event SetPartnerWalletByIndexEvent(uint256 index, address oldWallet, address newWallet);
    event SetPartnerWalletByNameEvent(string name, address oldWallet, address newWallet);
    event SetPartnerWalletByNameHashEvent(bytes32 nameHash, address oldWallet, address newWallet);
    event SetPartnerWalletByWalletEvent(address oldWallet, address newWallet);
    event StageEvent(address from, int256 amount, address currencyCt, uint256 currencyId);
    event WithdrawEvent(address to, int256 amount, address currencyCt, uint256 currencyId);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    
    function() external payable {
        _receiveEthersTo(
            indexByWallet(msg.sender) - 1, SafeMathIntLib.toNonZeroInt256(msg.value)
        );
    }

    
    
    function receiveEthersTo(address tag, string memory)
    public
    payable
    {
        _receiveEthersTo(
            uint256(tag) - 1, SafeMathIntLib.toNonZeroInt256(msg.value)
        );
    }

    
    
    
    
    
    function receiveTokens(string memory, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        _receiveTokensTo(
            indexByWallet(msg.sender) - 1, amount, currencyCt, currencyId, standard
        );
    }

    
    
    
    
    
    
    function receiveTokensTo(address tag, string memory, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        _receiveTokensTo(
            uint256(tag) - 1, amount, currencyCt, currencyId, standard
        );
    }

    
    
    
    function hashName(string memory name)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(name.upper()));
    }

    
    
    
    
    function depositByIndices(uint256 partnerIndex, uint256 depositIndex)
    public
    view
    returns (int256 balance, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        
        require(0 < partnerIndex && partnerIndex <= partners.length, "Some error message when require fails [PartnerFund.sol:160]");

        return _depositByIndices(partnerIndex - 1, depositIndex);
    }

    
    
    
    
    function depositByName(string memory name, uint depositIndex)
    public
    view
    returns (int256 balance, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        
        return _depositByIndices(indexByName(name) - 1, depositIndex);
    }

    
    
    
    
    function depositByNameHash(bytes32 nameHash, uint depositIndex)
    public
    view
    returns (int256 balance, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        
        return _depositByIndices(indexByNameHash(nameHash) - 1, depositIndex);
    }

    
    
    
    
    function depositByWallet(address wallet, uint depositIndex)
    public
    view
    returns (int256 balance, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        
        return _depositByIndices(indexByWallet(wallet) - 1, depositIndex);
    }

    
    
    
    function depositsCountByIndex(uint256 index)
    public
    view
    returns (uint256)
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:213]");

        return _depositsCountByIndex(index - 1);
    }

    
    
    
    function depositsCountByName(string memory name)
    public
    view
    returns (uint256)
    {
        
        return _depositsCountByIndex(indexByName(name) - 1);
    }

    
    
    
    function depositsCountByNameHash(bytes32 nameHash)
    public
    view
    returns (uint256)
    {
        
        return _depositsCountByIndex(indexByNameHash(nameHash) - 1);
    }

    
    
    
    function depositsCountByWallet(address wallet)
    public
    view
    returns (uint256)
    {
        
        return _depositsCountByIndex(indexByWallet(wallet) - 1);
    }

    
    
    
    
    
    function activeBalanceByIndex(uint256 index, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:265]");

        return _activeBalanceByIndex(index - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function activeBalanceByName(string memory name, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        return _activeBalanceByIndex(indexByName(name) - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function activeBalanceByNameHash(bytes32 nameHash, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        return _activeBalanceByIndex(indexByNameHash(nameHash) - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function activeBalanceByWallet(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        return _activeBalanceByIndex(indexByWallet(wallet) - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function stagedBalanceByIndex(uint256 index, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:323]");

        return _stagedBalanceByIndex(index - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function stagedBalanceByName(string memory name, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        return _stagedBalanceByIndex(indexByName(name) - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function stagedBalanceByNameHash(bytes32 nameHash, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        return _stagedBalanceByIndex(indexByNameHash(nameHash) - 1, currencyCt, currencyId);
    }

    
    
    
    
    
    function stagedBalanceByWallet(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        
        return _stagedBalanceByIndex(indexByWallet(wallet) - 1, currencyCt, currencyId);
    }

    
    
    function partnersCount()
    public
    view
    returns (uint256)
    {
        return partners.length;
    }

    
    
    
    
    
    
    function registerByName(string memory name, uint256 fee, address wallet,
        bool partnerCanUpdate, bool operatorCanUpdate)
    public
    onlyOperator
    {
        
        require(bytes(name).length > 0, "Some error message when require fails [PartnerFund.sol:392]");

        
        bytes32 nameHash = hashName(name);

        
        _registerPartnerByNameHash(nameHash, fee, wallet, partnerCanUpdate, operatorCanUpdate);

        
        emit RegisterPartnerByNameEvent(name, fee, wallet);
    }

    
    
    
    
    
    
    function registerByNameHash(bytes32 nameHash, uint256 fee, address wallet,
        bool partnerCanUpdate, bool operatorCanUpdate)
    public
    onlyOperator
    {
        
        _registerPartnerByNameHash(nameHash, fee, wallet, partnerCanUpdate, operatorCanUpdate);

        
        emit RegisterPartnerByNameHashEvent(nameHash, fee, wallet);
    }

    
    
    
    function indexByNameHash(bytes32 nameHash)
    public
    view
    returns (uint256)
    {
        uint256 index = _indexByNameHash[nameHash];
        require(0 < index, "Some error message when require fails [PartnerFund.sol:431]");
        return index;
    }

    
    
    
    function indexByName(string memory name)
    public
    view
    returns (uint256)
    {
        return indexByNameHash(hashName(name));
    }

    
    
    
    function indexByWallet(address wallet)
    public
    view
    returns (uint256)
    {
        uint256 index = _indexByWallet[wallet];
        require(0 < index, "Some error message when require fails [PartnerFund.sol:455]");
        return index;
    }

    
    
    
    function isRegisteredByName(string memory name)
    public
    view
    returns (bool)
    {
        return (0 < _indexByNameHash[hashName(name)]);
    }

    
    
    
    function isRegisteredByNameHash(bytes32 nameHash)
    public
    view
    returns (bool)
    {
        return (0 < _indexByNameHash[nameHash]);
    }

    
    
    
    function isRegisteredByWallet(address wallet)
    public
    view
    returns (bool)
    {
        return (0 < _indexByWallet[wallet]);
    }

    
    
    
    function feeByIndex(uint256 index)
    public
    view
    returns (uint256)
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:501]");

        return _partnerFeeByIndex(index - 1);
    }

    
    
    
    function feeByName(string memory name)
    public
    view
    returns (uint256)
    {
        
        return _partnerFeeByIndex(indexByName(name) - 1);
    }

    
    
    
    function feeByNameHash(bytes32 nameHash)
    public
    view
    returns (uint256)
    {
        
        return _partnerFeeByIndex(indexByNameHash(nameHash) - 1);
    }

    
    
    
    function feeByWallet(address wallet)
    public
    view
    returns (uint256)
    {
        
        return _partnerFeeByIndex(indexByWallet(wallet) - 1);
    }

    
    
    
    function setFeeByIndex(uint256 index, uint256 newFee)
    public
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:549]");

        
        uint256 oldFee = _setPartnerFeeByIndex(index - 1, newFee);

        
        emit SetFeeByIndexEvent(index, oldFee, newFee);
    }

    
    
    
    function setFeeByName(string memory name, uint256 newFee)
    public
    {
        
        uint256 oldFee = _setPartnerFeeByIndex(indexByName(name) - 1, newFee);

        
        emit SetFeeByNameEvent(name, oldFee, newFee);
    }

    
    
    
    function setFeeByNameHash(bytes32 nameHash, uint256 newFee)
    public
    {
        
        uint256 oldFee = _setPartnerFeeByIndex(indexByNameHash(nameHash) - 1, newFee);

        
        emit SetFeeByNameHashEvent(nameHash, oldFee, newFee);
    }

    
    
    
    function setFeeByWallet(address wallet, uint256 newFee)
    public
    {
        
        uint256 oldFee = _setPartnerFeeByIndex(indexByWallet(wallet) - 1, newFee);

        
        emit SetFeeByWalletEvent(wallet, oldFee, newFee);
    }

    
    
    
    function walletByIndex(uint256 index)
    public
    view
    returns (address)
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:606]");

        return partners[index - 1].wallet;
    }

    
    
    
    function walletByName(string memory name)
    public
    view
    returns (address)
    {
        
        return partners[indexByName(name) - 1].wallet;
    }

    
    
    
    function walletByNameHash(bytes32 nameHash)
    public
    view
    returns (address)
    {
        
        return partners[indexByNameHash(nameHash) - 1].wallet;
    }

    
    
    
    function setWalletByIndex(uint256 index, address newWallet)
    public
    {
        
        require(0 < index && index <= partners.length, "Some error message when require fails [PartnerFund.sol:642]");

        
        address oldWallet = _setPartnerWalletByIndex(index - 1, newWallet);

        
        emit SetPartnerWalletByIndexEvent(index, oldWallet, newWallet);
    }

    
    
    
    function setWalletByName(string memory name, address newWallet)
    public
    {
        
        address oldWallet = _setPartnerWalletByIndex(indexByName(name) - 1, newWallet);

        
        emit SetPartnerWalletByNameEvent(name, oldWallet, newWallet);
    }

    
    
    
    function setWalletByNameHash(bytes32 nameHash, address newWallet)
    public
    {
        
        address oldWallet = _setPartnerWalletByIndex(indexByNameHash(nameHash) - 1, newWallet);

        
        emit SetPartnerWalletByNameHashEvent(nameHash, oldWallet, newWallet);
    }

    
    
    
    function setWalletByWallet(address oldWallet, address newWallet)
    public
    {
        
        _setPartnerWalletByIndex(indexByWallet(oldWallet) - 1, newWallet);

        
        emit SetPartnerWalletByWalletEvent(oldWallet, newWallet);
    }

    
    
    
    
    function stage(int256 amount, address currencyCt, uint256 currencyId)
    public
    {
        
        uint256 index = indexByWallet(msg.sender);

        
        require(amount.isPositiveInt256(), "Some error message when require fails [PartnerFund.sol:701]");

        
        amount = amount.clampMax(partners[index - 1].active.get(currencyCt, currencyId));

        partners[index - 1].active.sub(amount, currencyCt, currencyId);
        partners[index - 1].staged.add(amount, currencyCt, currencyId);

        partners[index - 1].txHistory.addDeposit(amount, currencyCt, currencyId);

        
        partners[index - 1].fullBalanceHistory.push(
            FullBalanceHistory(
                partners[index - 1].txHistory.depositsCount() - 1,
                partners[index - 1].active.get(currencyCt, currencyId),
                block.number
            )
        );

        
        emit StageEvent(msg.sender, amount, currencyCt, currencyId);
    }

    
    
    
    
    
    function withdraw(int256 amount, address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        
        uint256 index = indexByWallet(msg.sender);

        
        require(amount.isPositiveInt256(), "Some error message when require fails [PartnerFund.sol:736]");

        
        amount = amount.clampMax(partners[index - 1].staged.get(currencyCt, currencyId));

        partners[index - 1].staged.sub(amount, currencyCt, currencyId);

        
        if (address(0) == currencyCt && 0 == currencyId)
            msg.sender.transfer(uint256(amount));

        else {
            TransferController controller = transferController(currencyCt, standard);
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getDispatchSignature(), address(this), msg.sender, uint256(amount), currencyCt, currencyId
                )
            );
            require(success, "Some error message when require fails [PartnerFund.sol:754]");
        }

        
        emit WithdrawEvent(msg.sender, amount, currencyCt, currencyId);
    }

    
    
    
    
    function _receiveEthersTo(uint256 index, int256 amount)
    private
    {
        
        require(index < partners.length, "Some error message when require fails [PartnerFund.sol:769]");

        
        partners[index].active.add(amount, address(0), 0);
        partners[index].txHistory.addDeposit(amount, address(0), 0);

        
        partners[index].fullBalanceHistory.push(
            FullBalanceHistory(
                partners[index].txHistory.depositsCount() - 1,
                partners[index].active.get(address(0), 0),
                block.number
            )
        );

        
        emit ReceiveEvent(msg.sender, amount, address(0), 0);
    }

    
    function _receiveTokensTo(uint256 index, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    private
    {
        
        require(index < partners.length, "Some error message when require fails [PartnerFund.sol:794]");

        require(amount.isNonZeroPositiveInt256(), "Some error message when require fails [PartnerFund.sol:796]");

        
        TransferController controller = transferController(currencyCt, standard);
        (bool success,) = address(controller).delegatecall(
            abi.encodeWithSelector(
                controller.getReceiveSignature(), msg.sender, this, uint256(amount), currencyCt, currencyId
            )
        );
        require(success, "Some error message when require fails [PartnerFund.sol:805]");

        
        partners[index].active.add(amount, currencyCt, currencyId);
        partners[index].txHistory.addDeposit(amount, currencyCt, currencyId);

        
        partners[index].fullBalanceHistory.push(
            FullBalanceHistory(
                partners[index].txHistory.depositsCount() - 1,
                partners[index].active.get(currencyCt, currencyId),
                block.number
            )
        );

        
        emit ReceiveEvent(msg.sender, amount, currencyCt, currencyId);
    }

    
    function _depositByIndices(uint256 partnerIndex, uint256 depositIndex)
    private
    view
    returns (int256 balance, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        require(depositIndex < partners[partnerIndex].fullBalanceHistory.length, "Some error message when require fails [PartnerFund.sol:830]");

        FullBalanceHistory storage entry = partners[partnerIndex].fullBalanceHistory[depositIndex];
        (,, currencyCt, currencyId) = partners[partnerIndex].txHistory.deposit(entry.listIndex);

        balance = entry.balance;
        blockNumber = entry.blockNumber;
    }

    
    function _depositsCountByIndex(uint256 index)
    private
    view
    returns (uint256)
    {
        return partners[index].fullBalanceHistory.length;
    }

    
    function _activeBalanceByIndex(uint256 index, address currencyCt, uint256 currencyId)
    private
    view
    returns (int256)
    {
        return partners[index].active.get(currencyCt, currencyId);
    }

    
    function _stagedBalanceByIndex(uint256 index, address currencyCt, uint256 currencyId)
    private
    view
    returns (int256)
    {
        return partners[index].staged.get(currencyCt, currencyId);
    }

    function _registerPartnerByNameHash(bytes32 nameHash, uint256 fee, address wallet,
        bool partnerCanUpdate, bool operatorCanUpdate)
    private
    {
        
        require(0 == _indexByNameHash[nameHash], "Some error message when require fails [PartnerFund.sol:871]");

        
        require(partnerCanUpdate || operatorCanUpdate, "Some error message when require fails [PartnerFund.sol:874]");

        
        partners.length++;

        
        uint256 index = partners.length;

        
        partners[index - 1].nameHash = nameHash;
        partners[index - 1].fee = fee;
        partners[index - 1].wallet = wallet;
        partners[index - 1].partnerCanUpdate = partnerCanUpdate;
        partners[index - 1].operatorCanUpdate = operatorCanUpdate;
        partners[index - 1].index = index;

        
        _indexByNameHash[nameHash] = index;

        
        _indexByWallet[wallet] = index;
    }

    
    function _setPartnerFeeByIndex(uint256 index, uint256 fee)
    private
    returns (uint256)
    {
        uint256 oldFee = partners[index].fee;

        
        if (isOperator())
            require(partners[index].operatorCanUpdate, "Some error message when require fails [PartnerFund.sol:906]");

        else {
            
            require(msg.sender == partners[index].wallet, "Some error message when require fails [PartnerFund.sol:910]");

            
            require(partners[index].partnerCanUpdate, "Some error message when require fails [PartnerFund.sol:913]");
        }

        
        partners[index].fee = fee;

        return oldFee;
    }

    
    function _setPartnerWalletByIndex(uint256 index, address newWallet)
    private
    returns (address)
    {
        address oldWallet = partners[index].wallet;

        
        if (oldWallet == address(0))
            require(isOperator(), "Some error message when require fails [PartnerFund.sol:931]");

        
        else if (isOperator())
            require(partners[index].operatorCanUpdate, "Some error message when require fails [PartnerFund.sol:935]");

        else {
            
            require(msg.sender == oldWallet, "Some error message when require fails [PartnerFund.sol:939]");

            
            require(partners[index].partnerCanUpdate, "Some error message when require fails [PartnerFund.sol:942]");

            
            require(partners[index].operatorCanUpdate || newWallet != address(0), "Some error message when require fails [PartnerFund.sol:945]");
        }

        
        partners[index].wallet = newWallet;

        
        if (oldWallet != address(0))
            _indexByWallet[oldWallet] = 0;
        if (newWallet != address(0))
            _indexByWallet[newWallet] = index;

        return oldWallet;
    }

    
    function _partnerFeeByIndex(uint256 index)
    private
    view
    returns (uint256)
    {
        return partners[index].fee;
    }
}

library NahmiiTypesLib {
    
    
    
    enum ChallengePhase {Dispute, Closed}

    
    
    
    struct OriginFigure {
        uint256 originId;
        MonetaryTypesLib.Figure figure;
    }

    struct IntendedConjugateCurrency {
        MonetaryTypesLib.Currency intended;
        MonetaryTypesLib.Currency conjugate;
    }

    struct SingleFigureTotalOriginFigures {
        MonetaryTypesLib.Figure single;
        OriginFigure[] total;
    }

    struct TotalOriginFigures {
        OriginFigure[] total;
    }

    struct CurrentPreviousInt256 {
        int256 current;
        int256 previous;
    }

    struct SingleTotalInt256 {
        int256 single;
        int256 total;
    }

    struct IntendedConjugateCurrentPreviousInt256 {
        CurrentPreviousInt256 intended;
        CurrentPreviousInt256 conjugate;
    }

    struct IntendedConjugateSingleTotalInt256 {
        SingleTotalInt256 intended;
        SingleTotalInt256 conjugate;
    }

    struct WalletOperatorHashes {
        bytes32 wallet;
        bytes32 operator;
    }

    struct Signature {
        bytes32 r;
        bytes32 s;
        uint8 v;
    }

    struct Seal {
        bytes32 hash;
        Signature signature;
    }

    struct WalletOperatorSeal {
        Seal wallet;
        Seal operator;
    }
}

library DriipSettlementTypesLib {
    
    
    
    enum SettlementRole {Origin, Target}

    struct SettlementParty {
        uint256 nonce;
        address wallet;
        uint256 doneBlockNumber;
    }

    struct Settlement {
        string settledKind;
        bytes32 settledHash;
        SettlementParty origin;
        SettlementParty target;
    }
}

contract DriipSettlementState is Ownable, Servable, CommunityVotable, Upgradable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;

    
    
    
    string constant public INIT_SETTLEMENT_ACTION = "init_settlement";
    string constant public COMPLETE_SETTLEMENT_ACTION = "complete_settlement";
    string constant public SET_MAX_NONCE_ACTION = "set_max_nonce";
    string constant public ADD_SETTLED_AMOUNT_ACTION = "add_settled_amount";
    string constant public SET_TOTAL_FEE_ACTION = "set_total_fee";

    
    
    
    uint256 public maxDriipNonce;

    DriipSettlementTypesLib.Settlement[] public settlements;
    mapping(address => uint256[]) public walletSettlementIndices;
    mapping(address => mapping(uint256 => uint256)) public walletNonceSettlementIndex;

    mapping(address => mapping(address => mapping(uint256 => uint256))) public walletCurrencyMaxNonce;

    mapping(address => mapping(address => mapping(uint256 => mapping(uint256 => int256)))) public walletCurrencyBlockNumberSettledAmount;
    mapping(address => mapping(address => mapping(uint256 => uint256[]))) public walletCurrencySettledBlockNumbers;

    mapping(address => mapping(address => mapping(address => mapping(address => mapping(uint256 => MonetaryTypesLib.NoncedAmount))))) public totalFeesMap;

    
    
    
    event InitSettlementEvent(DriipSettlementTypesLib.Settlement settlement);
    event CompleteSettlementPartyEvent(address wallet, uint256 nonce, DriipSettlementTypesLib.SettlementRole settlementRole,
        uint256 doneBlockNumber);
    event SetMaxDriipNonceEvent(uint256 maxDriipNonce);
    event UpdateMaxDriipNonceFromCommunityVoteEvent(uint256 maxDriipNonce);
    event SetMaxNonceByWalletAndCurrencyEvent(address wallet, MonetaryTypesLib.Currency currency,
        uint256 maxNonce);
    event AddSettledAmountEvent(address wallet, int256 amount, MonetaryTypesLib.Currency currency,
        uint256 blockNumber);
    event SetTotalFeeEvent(address wallet, Beneficiary beneficiary, address destination,
        MonetaryTypesLib.Currency currency, MonetaryTypesLib.NoncedAmount totalFee);
    event UpgradeSettlementEvent(DriipSettlementTypesLib.Settlement settlement);
    event UpgradeSettledAmountEvent(address wallet, int256 amount, MonetaryTypesLib.Currency currency,
        uint256 blockNumber);

    
    
    
    constructor(address deployer) Ownable(deployer) public {
    }

    
    
    
    
    function settlementsCount()
    public
    view
    returns (uint256)
    {
        return settlements.length;
    }

    
    
    
    function settlementsCountByWallet(address wallet)
    public
    view
    returns (uint256)
    {
        return walletSettlementIndices[wallet].length;
    }

    
    
    
    
    function settlementByWalletAndIndex(address wallet, uint256 index)
    public
    view
    returns (DriipSettlementTypesLib.Settlement memory)
    {
        require(walletSettlementIndices[wallet].length > index, "Index out of bounds [DriipSettlementState.sol:114]");
        return settlements[walletSettlementIndices[wallet][index] - 1];
    }

    
    
    
    
    function settlementByWalletAndNonce(address wallet, uint256 nonce)
    public
    view
    returns (DriipSettlementTypesLib.Settlement memory)
    {
        require(0 != walletNonceSettlementIndex[wallet][nonce], "No settlement found for wallet and nonce [DriipSettlementState.sol:127]");
        return settlements[walletNonceSettlementIndex[wallet][nonce] - 1];
    }

    
    
    
    
    
    
    
    
    function initSettlement(string memory settledKind, bytes32 settledHash, address originWallet,
        uint256 originNonce, address targetWallet, uint256 targetNonce)
    public
    onlyEnabledServiceAction(INIT_SETTLEMENT_ACTION)
    {
        if (
            0 == walletNonceSettlementIndex[originWallet][originNonce] &&
            0 == walletNonceSettlementIndex[targetWallet][targetNonce]
        ) {
            
            settlements.length++;

            
            uint256 index = settlements.length - 1;

            
            settlements[index].settledKind = settledKind;
            settlements[index].settledHash = settledHash;
            settlements[index].origin.nonce = originNonce;
            settlements[index].origin.wallet = originWallet;
            settlements[index].target.nonce = targetNonce;
            settlements[index].target.wallet = targetWallet;

            
            emit InitSettlementEvent(settlements[index]);

            
            index++;
            walletSettlementIndices[originWallet].push(index);
            walletSettlementIndices[targetWallet].push(index);
            walletNonceSettlementIndex[originWallet][originNonce] = index;
            walletNonceSettlementIndex[targetWallet][targetNonce] = index;
        }
    }

    
    
    
    
    
    function completeSettlement(address wallet, uint256 nonce,
        DriipSettlementTypesLib.SettlementRole settlementRole, bool done)
    public
    onlyEnabledServiceAction(COMPLETE_SETTLEMENT_ACTION)
    {
        
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

        
        require(0 != index, "No settlement found for wallet and nonce [DriipSettlementState.sol:188]");

        
        DriipSettlementTypesLib.SettlementParty storage party =
        DriipSettlementTypesLib.SettlementRole.Origin == settlementRole ?
        settlements[index - 1].origin :
        settlements[index - 1].target;

        
        party.doneBlockNumber = done ? block.number : 0;

        
        emit CompleteSettlementPartyEvent(wallet, nonce, settlementRole, party.doneBlockNumber);
    }

    
    
    
    
    function isSettlementPartyDone(address wallet, uint256 nonce)
    public
    view
    returns (bool)
    {
        
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

        
        if (0 == index)
            return false;

        
        return (
        wallet == settlements[index - 1].origin.wallet ?
        0 != settlements[index - 1].origin.doneBlockNumber :
        0 != settlements[index - 1].target.doneBlockNumber
        );
    }

    
    
    
    
    
    
    function isSettlementPartyDone(address wallet, uint256 nonce,
        DriipSettlementTypesLib.SettlementRole settlementRole)
    public
    view
    returns (bool)
    {
        
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

        
        if (0 == index)
            return false;

        
        DriipSettlementTypesLib.SettlementParty storage settlementParty =
        DriipSettlementTypesLib.SettlementRole.Origin == settlementRole ?
        settlements[index - 1].origin : settlements[index - 1].target;

        
        require(wallet == settlementParty.wallet, "Wallet has wrong settlement role [DriipSettlementState.sol:252]");

        
        return 0 != settlementParty.doneBlockNumber;
    }

    
    
    
    
    function settlementPartyDoneBlockNumber(address wallet, uint256 nonce)
    public
    view
    returns (uint256)
    {
        
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

        
        require(0 != index, "No settlement found for wallet and nonce [DriipSettlementState.sol:271]");

        
        return (
        wallet == settlements[index - 1].origin.wallet ?
        settlements[index - 1].origin.doneBlockNumber :
        settlements[index - 1].target.doneBlockNumber
        );
    }

    
    
    
    
    
    function settlementPartyDoneBlockNumber(address wallet, uint256 nonce,
        DriipSettlementTypesLib.SettlementRole settlementRole)
    public
    view
    returns (uint256)
    {
        
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

        
        require(0 != index, "No settlement found for wallet and nonce [DriipSettlementState.sol:296]");

        
        DriipSettlementTypesLib.SettlementParty storage settlementParty =
        DriipSettlementTypesLib.SettlementRole.Origin == settlementRole ?
        settlements[index - 1].origin : settlements[index - 1].target;

        
        require(wallet == settlementParty.wallet, "Wallet has wrong settlement role [DriipSettlementState.sol:304]");

        
        return settlementParty.doneBlockNumber;
    }

    
    
    function setMaxDriipNonce(uint256 _maxDriipNonce)
    public
    onlyEnabledServiceAction(SET_MAX_NONCE_ACTION)
    {
        maxDriipNonce = _maxDriipNonce;

        
        emit SetMaxDriipNonceEvent(maxDriipNonce);
    }

    
    function updateMaxDriipNonceFromCommunityVote()
    public
    {
        uint256 _maxDriipNonce = communityVote.getMaxDriipNonce();
        if (0 == _maxDriipNonce)
            return;

        maxDriipNonce = _maxDriipNonce;

        
        emit UpdateMaxDriipNonceFromCommunityVoteEvent(maxDriipNonce);
    }

    
    
    
    
    function maxNonceByWalletAndCurrency(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        return walletCurrencyMaxNonce[wallet][currency.ct][currency.id];
    }

    
    
    
    
    function setMaxNonceByWalletAndCurrency(address wallet, MonetaryTypesLib.Currency memory currency,
        uint256 maxNonce)
    public
    onlyEnabledServiceAction(SET_MAX_NONCE_ACTION)
    {
        
        walletCurrencyMaxNonce[wallet][currency.ct][currency.id] = maxNonce;

        
        emit SetMaxNonceByWalletAndCurrencyEvent(wallet, currency, maxNonce);
    }

    
    
    
    
    function settledAmountByBlockNumber(address wallet, MonetaryTypesLib.Currency memory currency,
        uint256 blockNumber)
    public
    view
    returns (int256)
    {
        uint256 settledBlockNumber = _walletSettledBlockNumber(wallet, currency, blockNumber);
        return walletCurrencyBlockNumberSettledAmount[wallet][currency.ct][currency.id][settledBlockNumber];
    }

    
    
    
    
    
    function addSettledAmountByBlockNumber(address wallet, int256 amount, MonetaryTypesLib.Currency memory currency,
        uint256 blockNumber)
    public
    onlyEnabledServiceAction(ADD_SETTLED_AMOUNT_ACTION)
    {
        
        uint256 settledBlockNumber = _walletSettledBlockNumber(wallet, currency, blockNumber);

        
        walletCurrencyBlockNumberSettledAmount[wallet][currency.ct][currency.id][settledBlockNumber] =
        walletCurrencyBlockNumberSettledAmount[wallet][currency.ct][currency.id][settledBlockNumber].add(amount);

        
        walletCurrencySettledBlockNumbers[wallet][currency.ct][currency.id].push(block.number);

        
        emit AddSettledAmountEvent(wallet, amount, currency, blockNumber);
    }

    
    
    
    
    
    
    
    function totalFee(address wallet, Beneficiary beneficiary, address destination,
        MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (MonetaryTypesLib.NoncedAmount memory)
    {
        return totalFeesMap[wallet][address(beneficiary)][destination][currency.ct][currency.id];
    }

    
    
    
    
    
    
    function setTotalFee(address wallet, Beneficiary beneficiary, address destination,
        MonetaryTypesLib.Currency memory currency, MonetaryTypesLib.NoncedAmount memory _totalFee)
    public
    onlyEnabledServiceAction(SET_TOTAL_FEE_ACTION)
    {
        
        totalFeesMap[wallet][address(beneficiary)][destination][currency.ct][currency.id] = _totalFee;

        
        emit SetTotalFeeEvent(wallet, beneficiary, destination, currency, _totalFee);
    }

    
    
    function upgradeSettlement(DriipSettlementTypesLib.Settlement memory settlement)
    public
    onlyWhenUpgrading
    {
        
        require(
            0 == walletNonceSettlementIndex[settlement.origin.wallet][settlement.origin.nonce],
            "Settlement exists for origin wallet and nonce [DriipSettlementState.sol:443]"
        );
        require(
            0 == walletNonceSettlementIndex[settlement.target.wallet][settlement.target.nonce],
            "Settlement exists for target wallet and nonce [DriipSettlementState.sol:447]"
        );

        
        settlements.push(settlement);

        
        uint256 index = settlements.length;

        
        walletSettlementIndices[settlement.origin.wallet].push(index);
        walletSettlementIndices[settlement.target.wallet].push(index);
        walletNonceSettlementIndex[settlement.origin.wallet][settlement.origin.nonce] = index;
        walletNonceSettlementIndex[settlement.target.wallet][settlement.target.nonce] = index;

        
        emit UpgradeSettlementEvent(settlement);
    }

    
    
    
    
    
    function upgradeSettledAmount(address wallet, int256 amount, MonetaryTypesLib.Currency memory currency,
        uint256 blockNumber)
    public
    onlyWhenUpgrading
    {
        
        require(0 == walletCurrencyBlockNumberSettledAmount[wallet][currency.ct][currency.id][blockNumber], "[DriipSettlementState.sol:479]");

        
        walletCurrencyBlockNumberSettledAmount[wallet][currency.ct][currency.id][blockNumber] = amount;

        
        walletCurrencySettledBlockNumbers[wallet][currency.ct][currency.id].push(blockNumber);

        
        emit UpgradeSettledAmountEvent(wallet, amount, currency, blockNumber);
    }

    
    
    
    function _walletSettledBlockNumber(address wallet, MonetaryTypesLib.Currency memory currency,
        uint256 blockNumber)
    private
    view
    returns (uint256)
    {
        for (uint256 i = walletCurrencySettledBlockNumbers[wallet][currency.ct][currency.id].length; i > 0; i--)
            if (walletCurrencySettledBlockNumbers[wallet][currency.ct][currency.id][i - 1] <= blockNumber)
                return walletCurrencySettledBlockNumbers[wallet][currency.ct][currency.id][i - 1];
        return 0;
    }
}