 

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

 

library BlockNumbUintsLib {
     
     
     
    struct Entry {
        uint256 blockNumber;
        uint256 value;
    }

    struct BlockNumbUints {
        Entry[] entries;
    }

     
     
     
    function currentValue(BlockNumbUints storage self)
    internal
    view
    returns (uint256)
    {
        return valueAt(self, block.number);
    }

    function currentEntry(BlockNumbUints storage self)
    internal
    view
    returns (Entry memory)
    {
        return entryAt(self, block.number);
    }

    function valueAt(BlockNumbUints storage self, uint256 _blockNumber)
    internal
    view
    returns (uint256)
    {
        return entryAt(self, _blockNumber).value;
    }

    function entryAt(BlockNumbUints storage self, uint256 _blockNumber)
    internal
    view
    returns (Entry memory)
    {
        return self.entries[indexByBlockNumber(self, _blockNumber)];
    }

    function addEntry(BlockNumbUints storage self, uint256 blockNumber, uint256 value)
    internal
    {
        require(
            0 == self.entries.length ||
        blockNumber > self.entries[self.entries.length - 1].blockNumber,
            "Later entry found [BlockNumbUintsLib.sol:62]"
        );

        self.entries.push(Entry(blockNumber, value));
    }

    function count(BlockNumbUints storage self)
    internal
    view
    returns (uint256)
    {
        return self.entries.length;
    }

    function entries(BlockNumbUints storage self)
    internal
    view
    returns (Entry[] memory)
    {
        return self.entries;
    }

    function indexByBlockNumber(BlockNumbUints storage self, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        require(0 < self.entries.length, "No entries found [BlockNumbUintsLib.sol:92]");
        for (uint256 i = self.entries.length - 1; i >= 0; i--)
            if (blockNumber >= self.entries[i].blockNumber)
                return i;
        revert();
    }
}

 

library BlockNumbIntsLib {
     
     
     
    struct Entry {
        uint256 blockNumber;
        int256 value;
    }

    struct BlockNumbInts {
        Entry[] entries;
    }

     
     
     
    function currentValue(BlockNumbInts storage self)
    internal
    view
    returns (int256)
    {
        return valueAt(self, block.number);
    }

    function currentEntry(BlockNumbInts storage self)
    internal
    view
    returns (Entry memory)
    {
        return entryAt(self, block.number);
    }

    function valueAt(BlockNumbInts storage self, uint256 _blockNumber)
    internal
    view
    returns (int256)
    {
        return entryAt(self, _blockNumber).value;
    }

    function entryAt(BlockNumbInts storage self, uint256 _blockNumber)
    internal
    view
    returns (Entry memory)
    {
        return self.entries[indexByBlockNumber(self, _blockNumber)];
    }

    function addEntry(BlockNumbInts storage self, uint256 blockNumber, int256 value)
    internal
    {
        require(
            0 == self.entries.length ||
        blockNumber > self.entries[self.entries.length - 1].blockNumber,
            "Later entry found [BlockNumbIntsLib.sol:62]"
        );

        self.entries.push(Entry(blockNumber, value));
    }

    function count(BlockNumbInts storage self)
    internal
    view
    returns (uint256)
    {
        return self.entries.length;
    }

    function entries(BlockNumbInts storage self)
    internal
    view
    returns (Entry[] memory)
    {
        return self.entries;
    }

    function indexByBlockNumber(BlockNumbInts storage self, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        require(0 < self.entries.length, "No entries found [BlockNumbIntsLib.sol:92]");
        for (uint256 i = self.entries.length - 1; i >= 0; i--)
            if (blockNumber >= self.entries[i].blockNumber)
                return i;
        revert();
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

 

library BlockNumbDisdIntsLib {
    using SafeMathIntLib for int256;

     
     
     
    struct Discount {
        int256 tier;
        int256 value;
    }

    struct Entry {
        uint256 blockNumber;
        int256 nominal;
        Discount[] discounts;
    }

    struct BlockNumbDisdInts {
        Entry[] entries;
    }

     
     
     
    function currentNominalValue(BlockNumbDisdInts storage self)
    internal
    view
    returns (int256)
    {
        return nominalValueAt(self, block.number);
    }

    function currentDiscountedValue(BlockNumbDisdInts storage self, int256 tier)
    internal
    view
    returns (int256)
    {
        return discountedValueAt(self, block.number, tier);
    }

    function currentEntry(BlockNumbDisdInts storage self)
    internal
    view
    returns (Entry memory)
    {
        return entryAt(self, block.number);
    }

    function nominalValueAt(BlockNumbDisdInts storage self, uint256 _blockNumber)
    internal
    view
    returns (int256)
    {
        return entryAt(self, _blockNumber).nominal;
    }

    function discountedValueAt(BlockNumbDisdInts storage self, uint256 _blockNumber, int256 tier)
    internal
    view
    returns (int256)
    {
        Entry memory entry = entryAt(self, _blockNumber);
        if (0 < entry.discounts.length) {
            uint256 index = indexByTier(entry.discounts, tier);
            if (0 < index)
                return entry.nominal.mul(
                    ConstantsLib.PARTS_PER().sub(entry.discounts[index - 1].value)
                ).div(
                    ConstantsLib.PARTS_PER()
                );
            else
                return entry.nominal;
        } else
            return entry.nominal;
    }

    function entryAt(BlockNumbDisdInts storage self, uint256 _blockNumber)
    internal
    view
    returns (Entry memory)
    {
        return self.entries[indexByBlockNumber(self, _blockNumber)];
    }

    function addNominalEntry(BlockNumbDisdInts storage self, uint256 blockNumber, int256 nominal)
    internal
    {
        require(
            0 == self.entries.length ||
        blockNumber > self.entries[self.entries.length - 1].blockNumber,
            "Later entry found [BlockNumbDisdIntsLib.sol:101]"
        );

        self.entries.length++;
        Entry storage entry = self.entries[self.entries.length - 1];

        entry.blockNumber = blockNumber;
        entry.nominal = nominal;
    }

    function addDiscountedEntry(BlockNumbDisdInts storage self, uint256 blockNumber, int256 nominal,
        int256[] memory discountTiers, int256[] memory discountValues)
    internal
    {
        require(discountTiers.length == discountValues.length, "Parameter array lengths mismatch [BlockNumbDisdIntsLib.sol:118]");

        addNominalEntry(self, blockNumber, nominal);

        Entry storage entry = self.entries[self.entries.length - 1];
        for (uint256 i = 0; i < discountTiers.length; i++)
            entry.discounts.push(Discount(discountTiers[i], discountValues[i]));
    }

    function count(BlockNumbDisdInts storage self)
    internal
    view
    returns (uint256)
    {
        return self.entries.length;
    }

    function entries(BlockNumbDisdInts storage self)
    internal
    view
    returns (Entry[] memory)
    {
        return self.entries;
    }

    function indexByBlockNumber(BlockNumbDisdInts storage self, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        require(0 < self.entries.length, "No entries found [BlockNumbDisdIntsLib.sol:148]");
        for (uint256 i = self.entries.length - 1; i >= 0; i--)
            if (blockNumber >= self.entries[i].blockNumber)
                return i;
        revert();
    }

     
    function indexByTier(Discount[] memory discounts, int256 tier)
    internal
    pure
    returns (uint256)
    {
        require(0 < discounts.length, "No discounts found [BlockNumbDisdIntsLib.sol:161]");
        for (uint256 i = discounts.length; i > 0; i--)
            if (tier >= discounts[i - 1].tier)
                return i;
        return 0;
    }
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

 

library BlockNumbReferenceCurrenciesLib {
     
     
     
    struct Entry {
        uint256 blockNumber;
        MonetaryTypesLib.Currency currency;
    }

    struct BlockNumbReferenceCurrencies {
        mapping(address => mapping(uint256 => Entry[])) entriesByCurrency;
    }

     
     
     
    function currentCurrency(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency)
    internal
    view
    returns (MonetaryTypesLib.Currency storage)
    {
        return currencyAt(self, referenceCurrency, block.number);
    }

    function currentEntry(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency)
    internal
    view
    returns (Entry storage)
    {
        return entryAt(self, referenceCurrency, block.number);
    }

    function currencyAt(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency,
        uint256 _blockNumber)
    internal
    view
    returns (MonetaryTypesLib.Currency storage)
    {
        return entryAt(self, referenceCurrency, _blockNumber).currency;
    }

    function entryAt(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency,
        uint256 _blockNumber)
    internal
    view
    returns (Entry storage)
    {
        return self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id][indexByBlockNumber(self, referenceCurrency, _blockNumber)];
    }

    function addEntry(BlockNumbReferenceCurrencies storage self, uint256 blockNumber,
        MonetaryTypesLib.Currency memory referenceCurrency, MonetaryTypesLib.Currency memory currency)
    internal
    {
        require(
            0 == self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id].length ||
        blockNumber > self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id][self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id].length - 1].blockNumber,
            "Later entry found for currency [BlockNumbReferenceCurrenciesLib.sol:67]"
        );

        self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id].push(Entry(blockNumber, currency));
    }

    function count(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency)
    internal
    view
    returns (uint256)
    {
        return self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id].length;
    }

    function entriesByCurrency(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency)
    internal
    view
    returns (Entry[] storage)
    {
        return self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id];
    }

    function indexByBlockNumber(BlockNumbReferenceCurrencies storage self, MonetaryTypesLib.Currency memory referenceCurrency, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        require(0 < self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id].length, "No entries found for currency [BlockNumbReferenceCurrenciesLib.sol:97]");
        for (uint256 i = self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id].length - 1; i >= 0; i--)
            if (blockNumber >= self.entriesByCurrency[referenceCurrency.ct][referenceCurrency.id][i].blockNumber)
                return i;
        revert();
    }
}

 

library BlockNumbFiguresLib {
     
     
     
    struct Entry {
        uint256 blockNumber;
        MonetaryTypesLib.Figure value;
    }

    struct BlockNumbFigures {
        Entry[] entries;
    }

     
     
     
    function currentValue(BlockNumbFigures storage self)
    internal
    view
    returns (MonetaryTypesLib.Figure storage)
    {
        return valueAt(self, block.number);
    }

    function currentEntry(BlockNumbFigures storage self)
    internal
    view
    returns (Entry storage)
    {
        return entryAt(self, block.number);
    }

    function valueAt(BlockNumbFigures storage self, uint256 _blockNumber)
    internal
    view
    returns (MonetaryTypesLib.Figure storage)
    {
        return entryAt(self, _blockNumber).value;
    }

    function entryAt(BlockNumbFigures storage self, uint256 _blockNumber)
    internal
    view
    returns (Entry storage)
    {
        return self.entries[indexByBlockNumber(self, _blockNumber)];
    }

    function addEntry(BlockNumbFigures storage self, uint256 blockNumber, MonetaryTypesLib.Figure memory value)
    internal
    {
        require(
            0 == self.entries.length ||
        blockNumber > self.entries[self.entries.length - 1].blockNumber,
            "Later entry found [BlockNumbFiguresLib.sol:65]"
        );

        self.entries.push(Entry(blockNumber, value));
    }

    function count(BlockNumbFigures storage self)
    internal
    view
    returns (uint256)
    {
        return self.entries.length;
    }

    function entries(BlockNumbFigures storage self)
    internal
    view
    returns (Entry[] storage)
    {
        return self.entries;
    }

    function indexByBlockNumber(BlockNumbFigures storage self, uint256 blockNumber)
    internal
    view
    returns (uint256)
    {
        require(0 < self.entries.length, "No entries found [BlockNumbFiguresLib.sol:95]");
        for (uint256 i = self.entries.length - 1; i >= 0; i--)
            if (blockNumber >= self.entries[i].blockNumber)
                return i;
        revert();
    }
}

 

 
contract Configuration is Modifiable, Ownable, Servable {
    using SafeMathIntLib for int256;
    using BlockNumbUintsLib for BlockNumbUintsLib.BlockNumbUints;
    using BlockNumbIntsLib for BlockNumbIntsLib.BlockNumbInts;
    using BlockNumbDisdIntsLib for BlockNumbDisdIntsLib.BlockNumbDisdInts;
    using BlockNumbReferenceCurrenciesLib for BlockNumbReferenceCurrenciesLib.BlockNumbReferenceCurrencies;
    using BlockNumbFiguresLib for BlockNumbFiguresLib.BlockNumbFigures;

     
     
     
    string constant public OPERATIONAL_MODE_ACTION = "operational_mode";

     
     
     
    enum OperationalMode {Normal, Exit}

     
     
     
    OperationalMode public operationalMode = OperationalMode.Normal;

    BlockNumbUintsLib.BlockNumbUints private updateDelayBlocksByBlockNumber;
    BlockNumbUintsLib.BlockNumbUints private confirmationBlocksByBlockNumber;

    BlockNumbDisdIntsLib.BlockNumbDisdInts private tradeMakerFeeByBlockNumber;
    BlockNumbDisdIntsLib.BlockNumbDisdInts private tradeTakerFeeByBlockNumber;
    BlockNumbDisdIntsLib.BlockNumbDisdInts private paymentFeeByBlockNumber;
    mapping(address => mapping(uint256 => BlockNumbDisdIntsLib.BlockNumbDisdInts)) private currencyPaymentFeeByBlockNumber;

    BlockNumbIntsLib.BlockNumbInts private tradeMakerMinimumFeeByBlockNumber;
    BlockNumbIntsLib.BlockNumbInts private tradeTakerMinimumFeeByBlockNumber;
    BlockNumbIntsLib.BlockNumbInts private paymentMinimumFeeByBlockNumber;
    mapping(address => mapping(uint256 => BlockNumbIntsLib.BlockNumbInts)) private currencyPaymentMinimumFeeByBlockNumber;

    BlockNumbReferenceCurrenciesLib.BlockNumbReferenceCurrencies private feeCurrencyByCurrencyBlockNumber;

    BlockNumbUintsLib.BlockNumbUints private walletLockTimeoutByBlockNumber;
    BlockNumbUintsLib.BlockNumbUints private cancelOrderChallengeTimeoutByBlockNumber;
    BlockNumbUintsLib.BlockNumbUints private settlementChallengeTimeoutByBlockNumber;

    BlockNumbUintsLib.BlockNumbUints private fraudStakeFractionByBlockNumber;
    BlockNumbUintsLib.BlockNumbUints private walletSettlementStakeFractionByBlockNumber;
    BlockNumbUintsLib.BlockNumbUints private operatorSettlementStakeFractionByBlockNumber;

    BlockNumbFiguresLib.BlockNumbFigures private operatorSettlementStakeByBlockNumber;

    uint256 public earliestSettlementBlockNumber;
    bool public earliestSettlementBlockNumberUpdateDisabled;

     
     
     
    event SetOperationalModeExitEvent();
    event SetUpdateDelayBlocksEvent(uint256 fromBlockNumber, uint256 newBlocks);
    event SetConfirmationBlocksEvent(uint256 fromBlockNumber, uint256 newBlocks);
    event SetTradeMakerFeeEvent(uint256 fromBlockNumber, int256 nominal, int256[] discountTiers, int256[] discountValues);
    event SetTradeTakerFeeEvent(uint256 fromBlockNumber, int256 nominal, int256[] discountTiers, int256[] discountValues);
    event SetPaymentFeeEvent(uint256 fromBlockNumber, int256 nominal, int256[] discountTiers, int256[] discountValues);
    event SetCurrencyPaymentFeeEvent(uint256 fromBlockNumber, address currencyCt, uint256 currencyId, int256 nominal,
        int256[] discountTiers, int256[] discountValues);
    event SetTradeMakerMinimumFeeEvent(uint256 fromBlockNumber, int256 nominal);
    event SetTradeTakerMinimumFeeEvent(uint256 fromBlockNumber, int256 nominal);
    event SetPaymentMinimumFeeEvent(uint256 fromBlockNumber, int256 nominal);
    event SetCurrencyPaymentMinimumFeeEvent(uint256 fromBlockNumber, address currencyCt, uint256 currencyId, int256 nominal);
    event SetFeeCurrencyEvent(uint256 fromBlockNumber, address referenceCurrencyCt, uint256 referenceCurrencyId,
        address feeCurrencyCt, uint256 feeCurrencyId);
    event SetWalletLockTimeoutEvent(uint256 fromBlockNumber, uint256 timeoutInSeconds);
    event SetCancelOrderChallengeTimeoutEvent(uint256 fromBlockNumber, uint256 timeoutInSeconds);
    event SetSettlementChallengeTimeoutEvent(uint256 fromBlockNumber, uint256 timeoutInSeconds);
    event SetWalletSettlementStakeFractionEvent(uint256 fromBlockNumber, uint256 stakeFraction);
    event SetOperatorSettlementStakeFractionEvent(uint256 fromBlockNumber, uint256 stakeFraction);
    event SetOperatorSettlementStakeEvent(uint256 fromBlockNumber, int256 stakeAmount, address stakeCurrencyCt,
        uint256 stakeCurrencyId);
    event SetFraudStakeFractionEvent(uint256 fromBlockNumber, uint256 stakeFraction);
    event SetEarliestSettlementBlockNumberEvent(uint256 earliestSettlementBlockNumber);
    event DisableEarliestSettlementBlockNumberUpdateEvent();

     
     
     
    constructor(address deployer) Ownable(deployer) public {
        updateDelayBlocksByBlockNumber.addEntry(block.number, 0);
    }

     
     
     
     
     
    function setOperationalModeExit()
    public
    onlyEnabledServiceAction(OPERATIONAL_MODE_ACTION)
    {
        operationalMode = OperationalMode.Exit;
        emit SetOperationalModeExitEvent();
    }

     
    function isOperationalModeNormal()
    public
    view
    returns (bool)
    {
        return OperationalMode.Normal == operationalMode;
    }

     
    function isOperationalModeExit()
    public
    view
    returns (bool)
    {
        return OperationalMode.Exit == operationalMode;
    }

     
     
    function updateDelayBlocks()
    public
    view
    returns (uint256)
    {
        return updateDelayBlocksByBlockNumber.currentValue();
    }

     
     
    function updateDelayBlocksCount()
    public
    view
    returns (uint256)
    {
        return updateDelayBlocksByBlockNumber.count();
    }

     
     
     
    function setUpdateDelayBlocks(uint256 fromBlockNumber, uint256 newUpdateDelayBlocks)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        updateDelayBlocksByBlockNumber.addEntry(fromBlockNumber, newUpdateDelayBlocks);
        emit SetUpdateDelayBlocksEvent(fromBlockNumber, newUpdateDelayBlocks);
    }

     
     
    function confirmationBlocks()
    public
    view
    returns (uint256)
    {
        return confirmationBlocksByBlockNumber.currentValue();
    }

     
     
    function confirmationBlocksCount()
    public
    view
    returns (uint256)
    {
        return confirmationBlocksByBlockNumber.count();
    }

     
     
     
    function setConfirmationBlocks(uint256 fromBlockNumber, uint256 newConfirmationBlocks)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        confirmationBlocksByBlockNumber.addEntry(fromBlockNumber, newConfirmationBlocks);
        emit SetConfirmationBlocksEvent(fromBlockNumber, newConfirmationBlocks);
    }

     
    function tradeMakerFeesCount()
    public
    view
    returns (uint256)
    {
        return tradeMakerFeeByBlockNumber.count();
    }

     
     
     
    function tradeMakerFee(uint256 blockNumber, int256 discountTier)
    public
    view
    returns (int256)
    {
        return tradeMakerFeeByBlockNumber.discountedValueAt(blockNumber, discountTier);
    }

     
     
     
     
     
    function setTradeMakerFee(uint256 fromBlockNumber, int256 nominal, int256[] memory discountTiers, int256[] memory discountValues)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        tradeMakerFeeByBlockNumber.addDiscountedEntry(fromBlockNumber, nominal, discountTiers, discountValues);
        emit SetTradeMakerFeeEvent(fromBlockNumber, nominal, discountTiers, discountValues);
    }

     
    function tradeTakerFeesCount()
    public
    view
    returns (uint256)
    {
        return tradeTakerFeeByBlockNumber.count();
    }

     
     
     
    function tradeTakerFee(uint256 blockNumber, int256 discountTier)
    public
    view
    returns (int256)
    {
        return tradeTakerFeeByBlockNumber.discountedValueAt(blockNumber, discountTier);
    }

     
     
     
     
     
    function setTradeTakerFee(uint256 fromBlockNumber, int256 nominal, int256[] memory discountTiers, int256[] memory discountValues)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        tradeTakerFeeByBlockNumber.addDiscountedEntry(fromBlockNumber, nominal, discountTiers, discountValues);
        emit SetTradeTakerFeeEvent(fromBlockNumber, nominal, discountTiers, discountValues);
    }

     
    function paymentFeesCount()
    public
    view
    returns (uint256)
    {
        return paymentFeeByBlockNumber.count();
    }

     
     
     
    function paymentFee(uint256 blockNumber, int256 discountTier)
    public
    view
    returns (int256)
    {
        return paymentFeeByBlockNumber.discountedValueAt(blockNumber, discountTier);
    }

     
     
     
     
     
    function setPaymentFee(uint256 fromBlockNumber, int256 nominal, int256[] memory discountTiers, int256[] memory discountValues)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        paymentFeeByBlockNumber.addDiscountedEntry(fromBlockNumber, nominal, discountTiers, discountValues);
        emit SetPaymentFeeEvent(fromBlockNumber, nominal, discountTiers, discountValues);
    }

     
     
     
    function currencyPaymentFeesCount(address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return currencyPaymentFeeByBlockNumber[currencyCt][currencyId].count();
    }

     
     
     
     
     
     
    function currencyPaymentFee(uint256 blockNumber, address currencyCt, uint256 currencyId, int256 discountTier)
    public
    view
    returns (int256)
    {
        if (0 < currencyPaymentFeeByBlockNumber[currencyCt][currencyId].count())
            return currencyPaymentFeeByBlockNumber[currencyCt][currencyId].discountedValueAt(
                blockNumber, discountTier
            );
        else
            return paymentFee(blockNumber, discountTier);
    }

     
     
     
     
     
     
     
     
    function setCurrencyPaymentFee(uint256 fromBlockNumber, address currencyCt, uint256 currencyId, int256 nominal,
        int256[] memory discountTiers, int256[] memory discountValues)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        currencyPaymentFeeByBlockNumber[currencyCt][currencyId].addDiscountedEntry(
            fromBlockNumber, nominal, discountTiers, discountValues
        );
        emit SetCurrencyPaymentFeeEvent(
            fromBlockNumber, currencyCt, currencyId, nominal, discountTiers, discountValues
        );
    }

     
    function tradeMakerMinimumFeesCount()
    public
    view
    returns (uint256)
    {
        return tradeMakerMinimumFeeByBlockNumber.count();
    }

     
     
    function tradeMakerMinimumFee(uint256 blockNumber)
    public
    view
    returns (int256)
    {
        return tradeMakerMinimumFeeByBlockNumber.valueAt(blockNumber);
    }

     
     
     
    function setTradeMakerMinimumFee(uint256 fromBlockNumber, int256 nominal)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        tradeMakerMinimumFeeByBlockNumber.addEntry(fromBlockNumber, nominal);
        emit SetTradeMakerMinimumFeeEvent(fromBlockNumber, nominal);
    }

     
    function tradeTakerMinimumFeesCount()
    public
    view
    returns (uint256)
    {
        return tradeTakerMinimumFeeByBlockNumber.count();
    }

     
     
    function tradeTakerMinimumFee(uint256 blockNumber)
    public
    view
    returns (int256)
    {
        return tradeTakerMinimumFeeByBlockNumber.valueAt(blockNumber);
    }

     
     
     
    function setTradeTakerMinimumFee(uint256 fromBlockNumber, int256 nominal)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        tradeTakerMinimumFeeByBlockNumber.addEntry(fromBlockNumber, nominal);
        emit SetTradeTakerMinimumFeeEvent(fromBlockNumber, nominal);
    }

     
    function paymentMinimumFeesCount()
    public
    view
    returns (uint256)
    {
        return paymentMinimumFeeByBlockNumber.count();
    }

     
     
    function paymentMinimumFee(uint256 blockNumber)
    public
    view
    returns (int256)
    {
        return paymentMinimumFeeByBlockNumber.valueAt(blockNumber);
    }

     
     
     
    function setPaymentMinimumFee(uint256 fromBlockNumber, int256 nominal)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        paymentMinimumFeeByBlockNumber.addEntry(fromBlockNumber, nominal);
        emit SetPaymentMinimumFeeEvent(fromBlockNumber, nominal);
    }

     
     
     
    function currencyPaymentMinimumFeesCount(address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return currencyPaymentMinimumFeeByBlockNumber[currencyCt][currencyId].count();
    }

     
     
     
     
    function currencyPaymentMinimumFee(uint256 blockNumber, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        if (0 < currencyPaymentMinimumFeeByBlockNumber[currencyCt][currencyId].count())
            return currencyPaymentMinimumFeeByBlockNumber[currencyCt][currencyId].valueAt(blockNumber);
        else
            return paymentMinimumFee(blockNumber);
    }

     
     
     
     
     
    function setCurrencyPaymentMinimumFee(uint256 fromBlockNumber, address currencyCt, uint256 currencyId, int256 nominal)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        currencyPaymentMinimumFeeByBlockNumber[currencyCt][currencyId].addEntry(fromBlockNumber, nominal);
        emit SetCurrencyPaymentMinimumFeeEvent(fromBlockNumber, currencyCt, currencyId, nominal);
    }

     
     
     
    function feeCurrenciesCount(address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return feeCurrencyByCurrencyBlockNumber.count(MonetaryTypesLib.Currency(currencyCt, currencyId));
    }

     
     
     
     
    function feeCurrency(uint256 blockNumber, address currencyCt, uint256 currencyId)
    public
    view
    returns (address ct, uint256 id)
    {
        MonetaryTypesLib.Currency storage _feeCurrency = feeCurrencyByCurrencyBlockNumber.currencyAt(
            MonetaryTypesLib.Currency(currencyCt, currencyId), blockNumber
        );
        ct = _feeCurrency.ct;
        id = _feeCurrency.id;
    }

     
     
     
     
     
     
    function setFeeCurrency(uint256 fromBlockNumber, address referenceCurrencyCt, uint256 referenceCurrencyId,
        address feeCurrencyCt, uint256 feeCurrencyId)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        feeCurrencyByCurrencyBlockNumber.addEntry(
            fromBlockNumber,
            MonetaryTypesLib.Currency(referenceCurrencyCt, referenceCurrencyId),
            MonetaryTypesLib.Currency(feeCurrencyCt, feeCurrencyId)
        );
        emit SetFeeCurrencyEvent(fromBlockNumber, referenceCurrencyCt, referenceCurrencyId,
            feeCurrencyCt, feeCurrencyId);
    }

     
     
    function walletLockTimeout()
    public
    view
    returns (uint256)
    {
        return walletLockTimeoutByBlockNumber.currentValue();
    }

     
     
     
    function setWalletLockTimeout(uint256 fromBlockNumber, uint256 timeoutInSeconds)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        walletLockTimeoutByBlockNumber.addEntry(fromBlockNumber, timeoutInSeconds);
        emit SetWalletLockTimeoutEvent(fromBlockNumber, timeoutInSeconds);
    }

     
     
    function cancelOrderChallengeTimeout()
    public
    view
    returns (uint256)
    {
        return cancelOrderChallengeTimeoutByBlockNumber.currentValue();
    }

     
     
     
    function setCancelOrderChallengeTimeout(uint256 fromBlockNumber, uint256 timeoutInSeconds)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        cancelOrderChallengeTimeoutByBlockNumber.addEntry(fromBlockNumber, timeoutInSeconds);
        emit SetCancelOrderChallengeTimeoutEvent(fromBlockNumber, timeoutInSeconds);
    }

     
     
    function settlementChallengeTimeout()
    public
    view
    returns (uint256)
    {
        return settlementChallengeTimeoutByBlockNumber.currentValue();
    }

     
     
     
    function setSettlementChallengeTimeout(uint256 fromBlockNumber, uint256 timeoutInSeconds)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        settlementChallengeTimeoutByBlockNumber.addEntry(fromBlockNumber, timeoutInSeconds);
        emit SetSettlementChallengeTimeoutEvent(fromBlockNumber, timeoutInSeconds);
    }

     
     
    function fraudStakeFraction()
    public
    view
    returns (uint256)
    {
        return fraudStakeFractionByBlockNumber.currentValue();
    }

     
     
     
     
    function setFraudStakeFraction(uint256 fromBlockNumber, uint256 stakeFraction)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        fraudStakeFractionByBlockNumber.addEntry(fromBlockNumber, stakeFraction);
        emit SetFraudStakeFractionEvent(fromBlockNumber, stakeFraction);
    }

     
     
    function walletSettlementStakeFraction()
    public
    view
    returns (uint256)
    {
        return walletSettlementStakeFractionByBlockNumber.currentValue();
    }

     
     
     
     
    function setWalletSettlementStakeFraction(uint256 fromBlockNumber, uint256 stakeFraction)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        walletSettlementStakeFractionByBlockNumber.addEntry(fromBlockNumber, stakeFraction);
        emit SetWalletSettlementStakeFractionEvent(fromBlockNumber, stakeFraction);
    }

     
     
    function operatorSettlementStakeFraction()
    public
    view
    returns (uint256)
    {
        return operatorSettlementStakeFractionByBlockNumber.currentValue();
    }

     
     
     
     
    function setOperatorSettlementStakeFraction(uint256 fromBlockNumber, uint256 stakeFraction)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        operatorSettlementStakeFractionByBlockNumber.addEntry(fromBlockNumber, stakeFraction);
        emit SetOperatorSettlementStakeFractionEvent(fromBlockNumber, stakeFraction);
    }

     
     
    function operatorSettlementStake()
    public
    view
    returns (int256 amount, address currencyCt, uint256 currencyId)
    {
        MonetaryTypesLib.Figure storage stake = operatorSettlementStakeByBlockNumber.currentValue();
        amount = stake.amount;
        currencyCt = stake.currency.ct;
        currencyId = stake.currency.id;
    }

     
     
     
     
     
     
    function setOperatorSettlementStake(uint256 fromBlockNumber, int256 stakeAmount,
        address stakeCurrencyCt, uint256 stakeCurrencyId)
    public
    onlyOperator
    onlyDelayedBlockNumber(fromBlockNumber)
    {
        MonetaryTypesLib.Figure memory stake = MonetaryTypesLib.Figure(stakeAmount, MonetaryTypesLib.Currency(stakeCurrencyCt, stakeCurrencyId));
        operatorSettlementStakeByBlockNumber.addEntry(fromBlockNumber, stake);
        emit SetOperatorSettlementStakeEvent(fromBlockNumber, stakeAmount, stakeCurrencyCt, stakeCurrencyId);
    }

     
     
    function setEarliestSettlementBlockNumber(uint256 _earliestSettlementBlockNumber)
    public
    onlyOperator
    {
        require(!earliestSettlementBlockNumberUpdateDisabled, "Earliest settlement block number update disabled [Configuration.sol:715]");

        earliestSettlementBlockNumber = _earliestSettlementBlockNumber;
        emit SetEarliestSettlementBlockNumberEvent(earliestSettlementBlockNumber);
    }

     
     
    function disableEarliestSettlementBlockNumberUpdate()
    public
    onlyOperator
    {
        earliestSettlementBlockNumberUpdateDisabled = true;
        emit DisableEarliestSettlementBlockNumberUpdateEvent();
    }

     
     
     
    modifier onlyDelayedBlockNumber(uint256 blockNumber) {
        require(
            0 == updateDelayBlocksByBlockNumber.count() ||
        blockNumber >= block.number + updateDelayBlocksByBlockNumber.currentValue(),
            "Block number not sufficiently delayed [Configuration.sol:735]"
        );
        _;
    }
}

 

 
contract Configurable is Ownable {
     
     
     
    Configuration public configuration;

     
     
     
    event SetConfigurationEvent(Configuration oldConfiguration, Configuration newConfiguration);

     
     
     
     
     
    function setConfiguration(Configuration newConfiguration)
    public
    onlyDeployer
    notNullAddress(address(newConfiguration))
    notSameAddresses(address(newConfiguration), address(configuration))
    {
         
        Configuration oldConfiguration = configuration;
        configuration = newConfiguration;

         
        emit SetConfigurationEvent(oldConfiguration, newConfiguration);
    }

     
     
     
    modifier configurationInitialized() {
        require(address(configuration) != address(0), "Configuration not initialized [Configurable.sol:52]");
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

 

 
library PaymentTypesLib {
     
     
     
    enum PaymentPartyRole {Sender, Recipient}

     
     
     
    struct PaymentSenderParty {
        uint256 nonce;
        address wallet;

        NahmiiTypesLib.CurrentPreviousInt256 balances;

        NahmiiTypesLib.SingleFigureTotalOriginFigures fees;

        string data;
    }

    struct PaymentRecipientParty {
        uint256 nonce;
        address wallet;

        NahmiiTypesLib.CurrentPreviousInt256 balances;

        NahmiiTypesLib.TotalOriginFigures fees;
    }

    struct Operator {
        uint256 id;
        string data;
    }

    struct Payment {
        int256 amount;
        MonetaryTypesLib.Currency currency;

        PaymentSenderParty sender;
        PaymentRecipientParty recipient;

         
        NahmiiTypesLib.SingleTotalInt256 transfers;

        NahmiiTypesLib.WalletOperatorSeal seals;
        uint256 blockNumber;

        Operator operator;
    }

     
     
     
    function PAYMENT_KIND()
    public
    pure
    returns (string memory)
    {
        return "payment";
    }
}

 

 
contract PaymentHasher is Ownable {
     
     
     
    constructor(address deployer) Ownable(deployer) public {
    }

     
     
     
    function hashPaymentAsWallet(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bytes32)
    {
        bytes32 amountCurrencyHash = hashPaymentAmountCurrency(payment);
        bytes32 senderHash = hashPaymentSenderPartyAsWallet(payment.sender);
        bytes32 recipientHash = hashAddress(payment.recipient.wallet);

        return keccak256(abi.encodePacked(amountCurrencyHash, senderHash, recipientHash));
    }

    function hashPaymentAsOperator(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bytes32)
    {
        bytes32 walletSignatureHash = hashSignature(payment.seals.wallet.signature);
        bytes32 senderHash = hashPaymentSenderPartyAsOperator(payment.sender);
        bytes32 recipientHash = hashPaymentRecipientPartyAsOperator(payment.recipient);
        bytes32 transfersHash = hashSingleTotalInt256(payment.transfers);
        bytes32 operatorHash = hashString(payment.operator.data);

        return keccak256(abi.encodePacked(
                walletSignatureHash, senderHash, recipientHash, transfersHash, operatorHash
            ));
    }

    function hashPaymentAmountCurrency(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                payment.amount,
                payment.currency.ct,
                payment.currency.id
            ));
    }

    function hashPaymentSenderPartyAsWallet(
        PaymentTypesLib.PaymentSenderParty memory paymentSenderParty)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                paymentSenderParty.wallet,
                paymentSenderParty.data
            ));
    }

    function hashPaymentSenderPartyAsOperator(
        PaymentTypesLib.PaymentSenderParty memory paymentSenderParty)
    public
    pure
    returns (bytes32)
    {
        bytes32 rootHash = hashUint256(paymentSenderParty.nonce);
        bytes32 balancesHash = hashCurrentPreviousInt256(paymentSenderParty.balances);
        bytes32 singleFeeHash = hashFigure(paymentSenderParty.fees.single);
        bytes32 totalFeesHash = hashOriginFigures(paymentSenderParty.fees.total);

        return keccak256(abi.encodePacked(
                rootHash, balancesHash, singleFeeHash, totalFeesHash
            ));
    }

    function hashPaymentRecipientPartyAsOperator(
        PaymentTypesLib.PaymentRecipientParty memory paymentRecipientParty)
    public
    pure
    returns (bytes32)
    {
        bytes32 rootHash = hashUint256(paymentRecipientParty.nonce);
        bytes32 balancesHash = hashCurrentPreviousInt256(paymentRecipientParty.balances);
        bytes32 totalFeesHash = hashOriginFigures(paymentRecipientParty.fees.total);

        return keccak256(abi.encodePacked(
                rootHash, balancesHash, totalFeesHash
            ));
    }

    function hashCurrentPreviousInt256(
        NahmiiTypesLib.CurrentPreviousInt256 memory currentPreviousInt256)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                currentPreviousInt256.current,
                currentPreviousInt256.previous
            ));
    }

    function hashSingleTotalInt256(
        NahmiiTypesLib.SingleTotalInt256 memory singleTotalInt256)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                singleTotalInt256.single,
                singleTotalInt256.total
            ));
    }

    function hashFigure(MonetaryTypesLib.Figure memory figure)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                figure.amount,
                figure.currency.ct,
                figure.currency.id
            ));
    }

    function hashOriginFigures(NahmiiTypesLib.OriginFigure[] memory originFigures)
    public
    pure
    returns (bytes32)
    {
        bytes32 hash;
        for (uint256 i = 0; i < originFigures.length; i++) {
            hash = keccak256(abi.encodePacked(
                    hash,
                    originFigures[i].originId,
                    originFigures[i].figure.amount,
                    originFigures[i].figure.currency.ct,
                    originFigures[i].figure.currency.id
                )
            );
        }
        return hash;
    }

    function hashUint256(uint256 _uint256)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_uint256));
    }

    function hashString(string memory _string)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_string));
    }

    function hashAddress(address _address)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(_address));
    }

    function hashSignature(NahmiiTypesLib.Signature memory signature)
    public
    pure
    returns (bytes32)
    {
        return keccak256(abi.encodePacked(
                signature.v,
                signature.r,
                signature.s
            ));
    }
}

 

 
contract PaymentHashable is Ownable {
     
     
     
    PaymentHasher public paymentHasher;

     
     
     
    event SetPaymentHasherEvent(PaymentHasher oldPaymentHasher, PaymentHasher newPaymentHasher);

     
     
     
     
     
    function setPaymentHasher(PaymentHasher newPaymentHasher)
    public
    onlyDeployer
    notNullAddress(address(newPaymentHasher))
    notSameAddresses(address(newPaymentHasher), address(paymentHasher))
    {
         
        PaymentHasher oldPaymentHasher = paymentHasher;
        paymentHasher = newPaymentHasher;

         
        emit SetPaymentHasherEvent(oldPaymentHasher, newPaymentHasher);
    }

     
     
     
    modifier paymentHasherInitialized() {
        require(address(paymentHasher) != address(0), "Payment hasher not initialized [PaymentHashable.sol:52]");
        _;
    }
}

 

 
contract SignerManager is Ownable {
    using SafeMathUintLib for uint256;

     
     
     
    mapping(address => uint256) public signerIndicesMap;  
    address[] public signers;

     
     
     
    event RegisterSignerEvent(address signer);

     
     
     
    constructor(address deployer) Ownable(deployer) public {
        registerSigner(deployer);
    }

     
     
     
     
     
     
    function isSigner(address _address)
    public
    view
    returns (bool)
    {
        return 0 < signerIndicesMap[_address];
    }

     
     
    function signersCount()
    public
    view
    returns (uint256)
    {
        return signers.length;
    }

     
     
     
    function signerIndex(address _address)
    public
    view
    returns (uint256)
    {
        require(isSigner(_address), "Address not signer [SignerManager.sol:71]");
        return signerIndicesMap[_address] - 1;
    }

     
     
    function registerSigner(address newSigner)
    public
    onlyOperator
    notNullOrThisAddress(newSigner)
    {
        if (0 == signerIndicesMap[newSigner]) {
             
            signers.push(newSigner);
            signerIndicesMap[newSigner] = signers.length;

             
            emit RegisterSignerEvent(newSigner);
        }
    }

     
     
     
     
    function signersByIndices(uint256 low, uint256 up)
    public
    view
    returns (address[] memory)
    {
        require(0 < signers.length, "No signers found [SignerManager.sol:101]");
        require(low <= up, "Bounds parameters mismatch [SignerManager.sol:102]");

        up = up.clampMax(signers.length - 1);
        address[] memory _signers = new address[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _signers[i - low] = signers[i];

        return _signers;
    }
}

 

 
contract SignerManageable is Ownable {
     
     
     
    SignerManager public signerManager;

     
     
     
    event SetSignerManagerEvent(address oldSignerManager, address newSignerManager);

     
     
     
    constructor(address manager) public notNullAddress(manager) {
        signerManager = SignerManager(manager);
    }

     
     
     
     
     
    function setSignerManager(address newSignerManager)
    public
    onlyDeployer
    notNullOrThisAddress(newSignerManager)
    {
        if (newSignerManager != address(signerManager)) {
             
            address oldSignerManager = address(signerManager);
            signerManager = SignerManager(newSignerManager);

             
            emit SetSignerManagerEvent(oldSignerManager, newSignerManager);
        }
    }

     
     
     
     
     
     
    function ethrecover(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    public
    pure
    returns (address)
    {
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s);
    }

     
     
     
     
     
     
    function isSignedByRegisteredSigner(bytes32 hash, uint8 v, bytes32 r, bytes32 s)
    public
    view
    returns (bool)
    {
        return signerManager.isSigner(ethrecover(hash, v, r, s));
    }

     
     
     
     
     
     
     
    function isSignedBy(bytes32 hash, uint8 v, bytes32 r, bytes32 s, address signer)
    public
    pure
    returns (bool)
    {
        return signer == ethrecover(hash, v, r, s);
    }

     
     
    modifier signerManagerInitialized() {
        require(address(signerManager) != address(0), "Signer manager not initialized [SignerManageable.sol:105]");
        _;
    }
}

 

 
contract Validator is Ownable, SignerManageable, Configurable, PaymentHashable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;

     
     
     
    constructor(address deployer, address signerManager) Ownable(deployer) SignerManageable(signerManager) public {
    }

     
     
     
    function isGenuineOperatorSignature(bytes32 hash, NahmiiTypesLib.Signature memory signature)
    public
    view
    returns (bool)
    {
        return isSignedByRegisteredSigner(hash, signature.v, signature.r, signature.s);
    }

    function isGenuineWalletSignature(bytes32 hash, NahmiiTypesLib.Signature memory signature, address wallet)
    public
    pure
    returns (bool)
    {
        return isSignedBy(hash, signature.v, signature.r, signature.s, wallet);
    }

    function isGenuinePaymentWalletHash(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return paymentHasher.hashPaymentAsWallet(payment) == payment.seals.wallet.hash;
    }

    function isGenuinePaymentOperatorHash(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return paymentHasher.hashPaymentAsOperator(payment) == payment.seals.operator.hash;
    }

    function isGenuinePaymentWalletSeal(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return isGenuinePaymentWalletHash(payment)
        && isGenuineWalletSignature(payment.seals.wallet.hash, payment.seals.wallet.signature, payment.sender.wallet);
    }

    function isGenuinePaymentOperatorSeal(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return isGenuinePaymentOperatorHash(payment)
        && isGenuineOperatorSignature(payment.seals.operator.hash, payment.seals.operator.signature);
    }

    function isGenuinePaymentSeals(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return isGenuinePaymentWalletSeal(payment) && isGenuinePaymentOperatorSeal(payment);
    }

     
    function isGenuinePaymentFeeOfFungible(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        int256 feePartsPer = int256(ConstantsLib.PARTS_PER());

        int256 feeAmount = payment.amount
        .mul(
            configuration.currencyPaymentFee(
                payment.blockNumber, payment.currency.ct, payment.currency.id, payment.amount
            )
        ).div(feePartsPer);

        if (1 > feeAmount)
            feeAmount = 1;

        return (payment.sender.fees.single.amount == feeAmount);
    }

     
    function isGenuinePaymentFeeOfNonFungible(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        (address feeCurrencyCt, uint256 feeCurrencyId) = configuration.feeCurrency(
            payment.blockNumber, payment.currency.ct, payment.currency.id
        );

        return feeCurrencyCt == payment.sender.fees.single.currency.ct
        && feeCurrencyId == payment.sender.fees.single.currency.id;
    }

     
    function isGenuinePaymentSenderOfFungible(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return (payment.sender.wallet != payment.recipient.wallet)
        && (!signerManager.isSigner(payment.sender.wallet))
        && (payment.sender.balances.current == payment.sender.balances.previous.sub(payment.transfers.single).sub(payment.sender.fees.single.amount));
    }

     
    function isGenuinePaymentRecipientOfFungible(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bool)
    {
        return (payment.sender.wallet != payment.recipient.wallet)
        && (payment.recipient.balances.current == payment.recipient.balances.previous.add(payment.transfers.single));
    }

     
    function isGenuinePaymentSenderOfNonFungible(PaymentTypesLib.Payment memory payment)
    public
    view
    returns (bool)
    {
        return (payment.sender.wallet != payment.recipient.wallet)
        && (!signerManager.isSigner(payment.sender.wallet));
    }

     
    function isGenuinePaymentRecipientOfNonFungible(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bool)
    {
        return (payment.sender.wallet != payment.recipient.wallet);
    }

    function isSuccessivePaymentsPartyNonces(
        PaymentTypesLib.Payment memory firstPayment,
        PaymentTypesLib.PaymentPartyRole firstPaymentPartyRole,
        PaymentTypesLib.Payment memory lastPayment,
        PaymentTypesLib.PaymentPartyRole lastPaymentPartyRole
    )
    public
    pure
    returns (bool)
    {
        uint256 firstNonce = (PaymentTypesLib.PaymentPartyRole.Sender == firstPaymentPartyRole ? firstPayment.sender.nonce : firstPayment.recipient.nonce);
        uint256 lastNonce = (PaymentTypesLib.PaymentPartyRole.Sender == lastPaymentPartyRole ? lastPayment.sender.nonce : lastPayment.recipient.nonce);
        return lastNonce == firstNonce.add(1);
    }

    function isGenuineSuccessivePaymentsBalances(
        PaymentTypesLib.Payment memory firstPayment,
        PaymentTypesLib.PaymentPartyRole firstPaymentPartyRole,
        PaymentTypesLib.Payment memory lastPayment,
        PaymentTypesLib.PaymentPartyRole lastPaymentPartyRole,
        int256 delta
    )
    public
    pure
    returns (bool)
    {
        NahmiiTypesLib.CurrentPreviousInt256 memory firstCurrentPreviousBalances = (PaymentTypesLib.PaymentPartyRole.Sender == firstPaymentPartyRole ? firstPayment.sender.balances : firstPayment.recipient.balances);
        NahmiiTypesLib.CurrentPreviousInt256 memory lastCurrentPreviousBalances = (PaymentTypesLib.PaymentPartyRole.Sender == lastPaymentPartyRole ? lastPayment.sender.balances : lastPayment.recipient.balances);

        return lastCurrentPreviousBalances.previous == firstCurrentPreviousBalances.current.add(delta);
    }

    function isGenuineSuccessivePaymentsTotalFees(
        PaymentTypesLib.Payment memory firstPayment,
        PaymentTypesLib.Payment memory lastPayment
    )
    public
    pure
    returns (bool)
    {
        MonetaryTypesLib.Figure memory firstTotalFee = getProtocolFigureByCurrency(firstPayment.sender.fees.total, lastPayment.sender.fees.single.currency);
        MonetaryTypesLib.Figure memory lastTotalFee = getProtocolFigureByCurrency(lastPayment.sender.fees.total, lastPayment.sender.fees.single.currency);
        return lastTotalFee.amount == firstTotalFee.amount.add(lastPayment.sender.fees.single.amount);
    }

    function isPaymentParty(PaymentTypesLib.Payment memory payment, address wallet)
    public
    pure
    returns (bool)
    {
        return wallet == payment.sender.wallet || wallet == payment.recipient.wallet;
    }

    function isPaymentSender(PaymentTypesLib.Payment memory payment, address wallet)
    public
    pure
    returns (bool)
    {
        return wallet == payment.sender.wallet;
    }

    function isPaymentRecipient(PaymentTypesLib.Payment memory payment, address wallet)
    public
    pure
    returns (bool)
    {
        return wallet == payment.recipient.wallet;
    }

    function isPaymentCurrency(PaymentTypesLib.Payment memory payment, MonetaryTypesLib.Currency memory currency)
    public
    pure
    returns (bool)
    {
        return currency.ct == payment.currency.ct && currency.id == payment.currency.id;
    }

    function isPaymentCurrencyNonFungible(PaymentTypesLib.Payment memory payment)
    public
    pure
    returns (bool)
    {
        return payment.currency.ct != payment.sender.fees.single.currency.ct
        || payment.currency.id != payment.sender.fees.single.currency.id;
    }

     
     
     
    function getProtocolFigureByCurrency(NahmiiTypesLib.OriginFigure[] memory originFigures, MonetaryTypesLib.Currency memory currency)
    private
    pure
    returns (MonetaryTypesLib.Figure memory) {
        for (uint256 i = 0; i < originFigures.length; i++)
            if (originFigures[i].figure.currency.ct == currency.ct && originFigures[i].figure.currency.id == currency.id
            && originFigures[i].originId == 0)
                return originFigures[i].figure;
        return MonetaryTypesLib.Figure(0, currency);
    }
}

 

 
library TradeTypesLib {
     
     
     
    enum CurrencyRole {Intended, Conjugate}
    enum LiquidityRole {Maker, Taker}
    enum Intention {Buy, Sell}
    enum TradePartyRole {Buyer, Seller}

     
     
     
    struct OrderPlacement {
        Intention intention;

        int256 amount;
        NahmiiTypesLib.IntendedConjugateCurrency currencies;
        int256 rate;

        NahmiiTypesLib.CurrentPreviousInt256 residuals;
    }

    struct Order {
        uint256 nonce;
        address wallet;

        OrderPlacement placement;

        NahmiiTypesLib.WalletOperatorSeal seals;
        uint256 blockNumber;
        uint256 operatorId;
    }

    struct TradeOrder {
        int256 amount;
        NahmiiTypesLib.WalletOperatorHashes hashes;
        NahmiiTypesLib.CurrentPreviousInt256 residuals;
    }

    struct TradeParty {
        uint256 nonce;
        address wallet;

        uint256 rollingVolume;

        LiquidityRole liquidityRole;

        TradeOrder order;

        NahmiiTypesLib.IntendedConjugateCurrentPreviousInt256 balances;

        NahmiiTypesLib.SingleFigureTotalOriginFigures fees;
    }

    struct Trade {
        uint256 nonce;

        int256 amount;
        NahmiiTypesLib.IntendedConjugateCurrency currencies;
        int256 rate;

        TradeParty buyer;
        TradeParty seller;

         
         
        NahmiiTypesLib.IntendedConjugateSingleTotalInt256 transfers;

        NahmiiTypesLib.Seal seal;
        uint256 blockNumber;
        uint256 operatorId;
    }

     
     
     
    function TRADE_KIND()
    public
    pure
    returns (string memory)
    {
        return "trade";
    }

    function ORDER_KIND()
    public
    pure
    returns (string memory)
    {
        return "order";
    }
}

 

 
contract Validatable is Ownable {
     
     
     
    Validator public validator;

     
     
     
    event SetValidatorEvent(Validator oldValidator, Validator newValidator);

     
     
     
     
     
    function setValidator(Validator newValidator)
    public
    onlyDeployer
    notNullAddress(address(newValidator))
    notSameAddresses(address(newValidator), address(validator))
    {
         
        Validator oldValidator = validator;
        validator = newValidator;

         
        emit SetValidatorEvent(oldValidator, newValidator);
    }

     
     
     
    modifier validatorInitialized() {
        require(address(validator) != address(0), "Validator not initialized [Validatable.sol:55]");
        _;
    }

    modifier onlyOperatorSealedPayment(PaymentTypesLib.Payment memory payment) {
        require(validator.isGenuinePaymentOperatorSeal(payment), "Payment operator seal not genuine [Validatable.sol:60]");
        _;
    }

    modifier onlySealedPayment(PaymentTypesLib.Payment memory payment) {
        require(validator.isGenuinePaymentSeals(payment), "Payment seals not genuine [Validatable.sol:65]");
        _;
    }

    modifier onlyPaymentParty(PaymentTypesLib.Payment memory payment, address wallet) {
        require(validator.isPaymentParty(payment, wallet), "Wallet not payment party [Validatable.sol:70]");
        _;
    }

    modifier onlyPaymentSender(PaymentTypesLib.Payment memory payment, address wallet) {
        require(validator.isPaymentSender(payment, wallet), "Wallet not payment sender [Validatable.sol:75]");
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

 

 
contract AuthorizableServable is Servable {
     
     
     
    bool public initialServiceAuthorizationDisabled;

    mapping(address => bool) public initialServiceAuthorizedMap;
    mapping(address => mapping(address => bool)) public initialServiceWalletUnauthorizedMap;

    mapping(address => mapping(address => bool)) public serviceWalletAuthorizedMap;

    mapping(address => mapping(bytes32 => mapping(address => bool))) public serviceActionWalletAuthorizedMap;
    mapping(address => mapping(bytes32 => mapping(address => bool))) public serviceActionWalletTouchedMap;
    mapping(address => mapping(address => bytes32[])) public serviceWalletActionList;

     
     
     
    event AuthorizeInitialServiceEvent(address wallet, address service);
    event AuthorizeRegisteredServiceEvent(address wallet, address service);
    event AuthorizeRegisteredServiceActionEvent(address wallet, address service, string action);
    event UnauthorizeRegisteredServiceEvent(address wallet, address service);
    event UnauthorizeRegisteredServiceActionEvent(address wallet, address service, string action);

     
     
     
     
     
     
    function authorizeInitialService(address service)
    public
    onlyDeployer
    notNullOrThisAddress(service)
    {
        require(!initialServiceAuthorizationDisabled);
        require(msg.sender != service);

         
        require(registeredServicesMap[service].registered);

         
        initialServiceAuthorizedMap[service] = true;

         
        emit AuthorizeInitialServiceEvent(msg.sender, service);
    }

     
     
    function disableInitialServiceAuthorization()
    public
    onlyDeployer
    {
        initialServiceAuthorizationDisabled = true;
    }

     
     
     
    function authorizeRegisteredService(address service)
    public
    notNullOrThisAddress(service)
    {
        require(msg.sender != service);

         
        require(registeredServicesMap[service].registered);

         
        require(!initialServiceAuthorizedMap[service]);

         
        serviceWalletAuthorizedMap[service][msg.sender] = true;

         
        emit AuthorizeRegisteredServiceEvent(msg.sender, service);
    }

     
     
     
    function unauthorizeRegisteredService(address service)
    public
    notNullOrThisAddress(service)
    {
        require(msg.sender != service);

         
        require(registeredServicesMap[service].registered);

         
        if (initialServiceAuthorizedMap[service])
            initialServiceWalletUnauthorizedMap[service][msg.sender] = true;

         
        else {
            serviceWalletAuthorizedMap[service][msg.sender] = false;
            for (uint256 i = 0; i < serviceWalletActionList[service][msg.sender].length; i++)
                serviceActionWalletAuthorizedMap[service][serviceWalletActionList[service][msg.sender][i]][msg.sender] = true;
        }

         
        emit UnauthorizeRegisteredServiceEvent(msg.sender, service);
    }

     
     
     
     
    function isAuthorizedRegisteredService(address service, address wallet)
    public
    view
    returns (bool)
    {
        return isRegisteredActiveService(service) &&
        (isInitialServiceAuthorizedForWallet(service, wallet) || serviceWalletAuthorizedMap[service][wallet]);
    }

     
     
     
     
    function authorizeRegisteredServiceAction(address service, string memory action)
    public
    notNullOrThisAddress(service)
    {
        require(msg.sender != service);

        bytes32 actionHash = hashString(action);

         
        require(registeredServicesMap[service].registered && registeredServicesMap[service].actionsEnabledMap[actionHash]);

         
        require(!initialServiceAuthorizedMap[service]);

         
        serviceWalletAuthorizedMap[service][msg.sender] = false;
        serviceActionWalletAuthorizedMap[service][actionHash][msg.sender] = true;
        if (!serviceActionWalletTouchedMap[service][actionHash][msg.sender]) {
            serviceActionWalletTouchedMap[service][actionHash][msg.sender] = true;
            serviceWalletActionList[service][msg.sender].push(actionHash);
        }

         
        emit AuthorizeRegisteredServiceActionEvent(msg.sender, service, action);
    }

     
     
     
     
    function unauthorizeRegisteredServiceAction(address service, string memory action)
    public
    notNullOrThisAddress(service)
    {
        require(msg.sender != service);

        bytes32 actionHash = hashString(action);

         
        require(registeredServicesMap[service].registered && registeredServicesMap[service].actionsEnabledMap[actionHash]);

         
        require(!initialServiceAuthorizedMap[service]);

         
        serviceActionWalletAuthorizedMap[service][actionHash][msg.sender] = false;

         
        emit UnauthorizeRegisteredServiceActionEvent(msg.sender, service, action);
    }

     
     
     
     
     
    function isAuthorizedRegisteredServiceAction(address service, string memory action, address wallet)
    public
    view
    returns (bool)
    {
        bytes32 actionHash = hashString(action);

        return isEnabledServiceAction(service, action) &&
        (
        isInitialServiceAuthorizedForWallet(service, wallet) ||
        serviceWalletAuthorizedMap[service][wallet] ||
        serviceActionWalletAuthorizedMap[service][actionHash][wallet]
        );
    }

    function isInitialServiceAuthorizedForWallet(address service, address wallet)
    private
    view
    returns (bool)
    {
        return initialServiceAuthorizedMap[service] ? !initialServiceWalletUnauthorizedMap[service][wallet] : false;
    }

     
     
     
    modifier onlyAuthorizedService(address wallet) {
        require(isAuthorizedRegisteredService(msg.sender, wallet));
        _;
    }

    modifier onlyAuthorizedServiceAction(string memory action, address wallet) {
        require(isAuthorizedRegisteredServiceAction(msg.sender, action, wallet));
        _;
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

    function add(Balance storage self, int256 amount, address currencyCt, uint256 currencyId)
    internal
    {
        self.amountByCurrency[currencyCt][currencyId] = self.amountByCurrency[currencyCt][currencyId].add(amount);

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.amountByCurrency[currencyCt][currencyId], block.number)
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

 

library NonFungibleBalanceLib {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using CurrenciesLib for CurrenciesLib.Currencies;

     
     
     
    struct Record {
        int256[] ids;
        uint256 blockNumber;
    }

    struct Balance {
        mapping(address => mapping(uint256 => int256[])) idsByCurrency;
        mapping(address => mapping(uint256 => mapping(int256 => uint256))) idIndexById;
        mapping(address => mapping(uint256 => Record[])) recordsByCurrency;

        CurrenciesLib.Currencies inUseCurrencies;
        CurrenciesLib.Currencies everUsedCurrencies;
    }

     
     
     
    function get(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256[] memory)
    {
        return self.idsByCurrency[currencyCt][currencyId];
    }

    function getByIndices(Balance storage self, address currencyCt, uint256 currencyId, uint256 indexLow, uint256 indexUp)
    internal
    view
    returns (int256[] memory)
    {
        if (0 == self.idsByCurrency[currencyCt][currencyId].length)
            return new int256[](0);

        indexUp = indexUp.clampMax(self.idsByCurrency[currencyCt][currencyId].length - 1);

        int256[] memory idsByCurrency = new int256[](indexUp - indexLow + 1);
        for (uint256 i = indexLow; i < indexUp; i++)
            idsByCurrency[i - indexLow] = self.idsByCurrency[currencyCt][currencyId][i];

        return idsByCurrency;
    }

    function idsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.idsByCurrency[currencyCt][currencyId].length;
    }

    function hasId(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    view
    returns (bool)
    {
        return 0 < self.idIndexById[currencyCt][currencyId][id];
    }

    function recordByBlockNumber(Balance storage self, address currencyCt, uint256 currencyId, uint256 blockNumber)
    internal
    view
    returns (int256[] memory, uint256)
    {
        uint256 index = indexByBlockNumber(self, currencyCt, currencyId, blockNumber);
        return 0 < index ? recordByIndex(self, currencyCt, currencyId, index - 1) : (new int256[](0), 0);
    }

    function recordByIndex(Balance storage self, address currencyCt, uint256 currencyId, uint256 index)
    internal
    view
    returns (int256[] memory, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (new int256[](0), 0);

        index = index.clampMax(self.recordsByCurrency[currencyCt][currencyId].length - 1);
        Record storage record = self.recordsByCurrency[currencyCt][currencyId][index];
        return (record.ids, record.blockNumber);
    }

    function lastRecord(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (int256[] memory, uint256)
    {
        if (0 == self.recordsByCurrency[currencyCt][currencyId].length)
            return (new int256[](0), 0);

        Record storage record = self.recordsByCurrency[currencyCt][currencyId][self.recordsByCurrency[currencyCt][currencyId].length - 1];
        return (record.ids, record.blockNumber);
    }

    function recordsCount(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    view
    returns (uint256)
    {
        return self.recordsByCurrency[currencyCt][currencyId].length;
    }

    function set(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    {
        int256[] memory ids = new int256[](1);
        ids[0] = id;
        set(self, ids, currencyCt, currencyId);
    }

    function set(Balance storage self, int256[] memory ids, address currencyCt, uint256 currencyId)
    internal
    {
        uint256 i;
        for (i = 0; i < self.idsByCurrency[currencyCt][currencyId].length; i++)
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][i]] = 0;

        self.idsByCurrency[currencyCt][currencyId] = ids;

        for (i = 0; i < self.idsByCurrency[currencyCt][currencyId].length; i++)
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][i]] = i + 1;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);
    }

    function reset(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        for (uint256 i = 0; i < self.idsByCurrency[currencyCt][currencyId].length; i++)
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][i]] = 0;

        self.idsByCurrency[currencyCt][currencyId].length = 0;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);
    }

    function add(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    returns (bool)
    {
        if (0 < self.idIndexById[currencyCt][currencyId][id])
            return false;

        self.idsByCurrency[currencyCt][currencyId].push(id);

        self.idIndexById[currencyCt][currencyId][id] = self.idsByCurrency[currencyCt][currencyId].length;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);

        return true;
    }

    function sub(Balance storage self, int256 id, address currencyCt, uint256 currencyId)
    internal
    returns (bool)
    {
        uint256 index = self.idIndexById[currencyCt][currencyId][id];

        if (0 == index)
            return false;

        if (index < self.idsByCurrency[currencyCt][currencyId].length) {
            self.idsByCurrency[currencyCt][currencyId][index - 1] = self.idsByCurrency[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId].length - 1];
            self.idIndexById[currencyCt][currencyId][self.idsByCurrency[currencyCt][currencyId][index - 1]] = index;
        }
        self.idsByCurrency[currencyCt][currencyId].length--;
        self.idIndexById[currencyCt][currencyId][id] = 0;

        self.recordsByCurrency[currencyCt][currencyId].push(
            Record(self.idsByCurrency[currencyCt][currencyId], block.number)
        );

        updateInUseCurrencies(self, currencyCt, currencyId);

        return true;
    }

    function transfer(Balance storage _from, Balance storage _to, int256 id,
        address currencyCt, uint256 currencyId)
    internal
    returns (bool)
    {
        return sub(_from, id, currencyCt, currencyId) && add(_to, id, currencyCt, currencyId);
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

    function updateInUseCurrencies(Balance storage self, address currencyCt, uint256 currencyId)
    internal
    {
        if (0 == self.idsByCurrency[currencyCt][currencyId].length && self.inUseCurrencies.has(currencyCt, currencyId))
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

 

 
contract BalanceTracker is Ownable, Servable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using NonFungibleBalanceLib for NonFungibleBalanceLib.Balance;

     
     
     
    string constant public DEPOSITED_BALANCE_TYPE = "deposited";
    string constant public SETTLED_BALANCE_TYPE = "settled";
    string constant public STAGED_BALANCE_TYPE = "staged";

     
     
     
    struct Wallet {
        mapping(bytes32 => FungibleBalanceLib.Balance) fungibleBalanceByType;
        mapping(bytes32 => NonFungibleBalanceLib.Balance) nonFungibleBalanceByType;
    }

     
     
     
    bytes32 public depositedBalanceType;
    bytes32 public settledBalanceType;
    bytes32 public stagedBalanceType;

    bytes32[] public _allBalanceTypes;
    bytes32[] public _activeBalanceTypes;

    bytes32[] public trackedBalanceTypes;
    mapping(bytes32 => bool) public trackedBalanceTypeMap;

    mapping(address => Wallet) private walletMap;

    address[] public trackedWallets;
    mapping(address => uint256) public trackedWalletIndexByWallet;

     
     
     
    constructor(address deployer) Ownable(deployer)
    public
    {
        depositedBalanceType = keccak256(abi.encodePacked(DEPOSITED_BALANCE_TYPE));
        settledBalanceType = keccak256(abi.encodePacked(SETTLED_BALANCE_TYPE));
        stagedBalanceType = keccak256(abi.encodePacked(STAGED_BALANCE_TYPE));

        _allBalanceTypes.push(settledBalanceType);
        _allBalanceTypes.push(depositedBalanceType);
        _allBalanceTypes.push(stagedBalanceType);

        _activeBalanceTypes.push(settledBalanceType);
        _activeBalanceTypes.push(depositedBalanceType);
    }

     
     
     
     
     
     
     
     
     
    function get(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].get(currencyCt, currencyId);
    }

     
     
     
     
     
     
     
     
    function getByIndices(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 indexLow, uint256 indexUp)
    public
    view
    returns (int256[] memory)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].getByIndices(
            currencyCt, currencyId, indexLow, indexUp
        );
    }

     
     
     
     
     
     
    function getAll(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256[] memory)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].get(
            currencyCt, currencyId
        );
    }

     
     
     
     
     
     
    function idsCount(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].idsCount(
            currencyCt, currencyId
        );
    }

     
     
     
     
     
     
     
    function hasId(address wallet, bytes32 _type, int256 id, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].hasId(
            id, currencyCt, currencyId
        );
    }

     
     
     
     
     
     
     
    function set(address wallet, bytes32 _type, int256 value, address currencyCt, uint256 currencyId, bool fungible)
    public
    onlyActiveService
    {
         
        if (fungible)
            walletMap[wallet].fungibleBalanceByType[_type].set(
                value, currencyCt, currencyId
            );

        else
            walletMap[wallet].nonFungibleBalanceByType[_type].set(
                value, currencyCt, currencyId
            );

         
        _updateTrackedBalanceTypes(_type);

         
        _updateTrackedWallets(wallet);
    }

     
     
     
     
     
     
    function setIds(address wallet, bytes32 _type, int256[] memory ids, address currencyCt, uint256 currencyId)
    public
    onlyActiveService
    {
         
        walletMap[wallet].nonFungibleBalanceByType[_type].set(
            ids, currencyCt, currencyId
        );

         
        _updateTrackedBalanceTypes(_type);

         
        _updateTrackedWallets(wallet);
    }

     
     
     
     
     
     
     
    function add(address wallet, bytes32 _type, int256 value, address currencyCt, uint256 currencyId,
        bool fungible)
    public
    onlyActiveService
    {
         
        if (fungible)
            walletMap[wallet].fungibleBalanceByType[_type].add(
                value, currencyCt, currencyId
            );
        else
            walletMap[wallet].nonFungibleBalanceByType[_type].add(
                value, currencyCt, currencyId
            );

         
        _updateTrackedBalanceTypes(_type);

         
        _updateTrackedWallets(wallet);
    }

     
     
     
     
     
     
     
    function sub(address wallet, bytes32 _type, int256 value, address currencyCt, uint256 currencyId,
        bool fungible)
    public
    onlyActiveService
    {
         
        if (fungible)
            walletMap[wallet].fungibleBalanceByType[_type].sub(
                value, currencyCt, currencyId
            );
        else
            walletMap[wallet].nonFungibleBalanceByType[_type].sub(
                value, currencyCt, currencyId
            );

         
        _updateTrackedWallets(wallet);
    }

     
     
     
     
     
     
    function hasInUseCurrency(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].hasInUseCurrency(currencyCt, currencyId)
        || walletMap[wallet].nonFungibleBalanceByType[_type].hasInUseCurrency(currencyCt, currencyId);
    }

     
     
     
     
     
     
    function hasEverUsedCurrency(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].hasEverUsedCurrency(currencyCt, currencyId)
        || walletMap[wallet].nonFungibleBalanceByType[_type].hasEverUsedCurrency(currencyCt, currencyId);
    }

     
     
     
     
     
     
    function fungibleRecordsCount(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].recordsCount(currencyCt, currencyId);
    }

     
     
     
     
     
     
     
     
    function fungibleRecordByIndex(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 index)
    public
    view
    returns (int256 amount, uint256 blockNumber)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].recordByIndex(currencyCt, currencyId, index);
    }

     
     
     
     
     
     
     
     
    function fungibleRecordByBlockNumber(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 _blockNumber)
    public
    view
    returns (int256 amount, uint256 blockNumber)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].recordByBlockNumber(currencyCt, currencyId, _blockNumber);
    }

     
     
     
     
     
     
    function lastFungibleRecord(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256 amount, uint256 blockNumber)
    {
        return walletMap[wallet].fungibleBalanceByType[_type].lastRecord(currencyCt, currencyId);
    }

     
     
     
     
     
     
    function nonFungibleRecordsCount(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].recordsCount(currencyCt, currencyId);
    }

     
     
     
     
     
     
     
     
    function nonFungibleRecordByIndex(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 index)
    public
    view
    returns (int256[] memory ids, uint256 blockNumber)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].recordByIndex(currencyCt, currencyId, index);
    }

     
     
     
     
     
     
     
     
    function nonFungibleRecordByBlockNumber(address wallet, bytes32 _type, address currencyCt, uint256 currencyId,
        uint256 _blockNumber)
    public
    view
    returns (int256[] memory ids, uint256 blockNumber)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].recordByBlockNumber(currencyCt, currencyId, _blockNumber);
    }

     
     
     
     
     
     
    function lastNonFungibleRecord(address wallet, bytes32 _type, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256[] memory ids, uint256 blockNumber)
    {
        return walletMap[wallet].nonFungibleBalanceByType[_type].lastRecord(currencyCt, currencyId);
    }

     
     
    function trackedBalanceTypesCount()
    public
    view
    returns (uint256)
    {
        return trackedBalanceTypes.length;
    }

     
     
    function trackedWalletsCount()
    public
    view
    returns (uint256)
    {
        return trackedWallets.length;
    }

     
     
    function allBalanceTypes()
    public
    view
    returns (bytes32[] memory)
    {
        return _allBalanceTypes;
    }

     
     
    function activeBalanceTypes()
    public
    view
    returns (bytes32[] memory)
    {
        return _activeBalanceTypes;
    }

     
     
     
     
    function trackedWalletsByIndices(uint256 low, uint256 up)
    public
    view
    returns (address[] memory)
    {
        require(0 < trackedWallets.length, "No tracked wallets found [BalanceTracker.sol:473]");
        require(low <= up, "Bounds parameters mismatch [BalanceTracker.sol:474]");

        up = up.clampMax(trackedWallets.length - 1);
        address[] memory _trackedWallets = new address[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _trackedWallets[i - low] = trackedWallets[i];

        return _trackedWallets;
    }

     
     
     
    function _updateTrackedBalanceTypes(bytes32 _type)
    private
    {
        if (!trackedBalanceTypeMap[_type]) {
            trackedBalanceTypeMap[_type] = true;
            trackedBalanceTypes.push(_type);
        }
    }

    function _updateTrackedWallets(address wallet)
    private
    {
        if (0 == trackedWalletIndexByWallet[wallet]) {
            trackedWallets.push(wallet);
            trackedWalletIndexByWallet[wallet] = trackedWallets.length;
        }
    }
}

 

 
contract BalanceTrackable is Ownable {
     
     
     
    BalanceTracker public balanceTracker;
    bool public balanceTrackerFrozen;

     
     
     
    event SetBalanceTrackerEvent(BalanceTracker oldBalanceTracker, BalanceTracker newBalanceTracker);
    event FreezeBalanceTrackerEvent();

     
     
     
     
     
    function setBalanceTracker(BalanceTracker newBalanceTracker)
    public
    onlyDeployer
    notNullAddress(address(newBalanceTracker))
    notSameAddresses(address(newBalanceTracker), address(balanceTracker))
    {
         
        require(!balanceTrackerFrozen, "Balance tracker frozen [BalanceTrackable.sol:43]");

         
        BalanceTracker oldBalanceTracker = balanceTracker;
        balanceTracker = newBalanceTracker;

         
        emit SetBalanceTrackerEvent(oldBalanceTracker, newBalanceTracker);
    }

     
     
    function freezeBalanceTracker()
    public
    onlyDeployer
    {
        balanceTrackerFrozen = true;

         
        emit FreezeBalanceTrackerEvent();
    }

     
     
     
    modifier balanceTrackerInitialized() {
        require(address(balanceTracker) != address(0), "Balance tracker not initialized [BalanceTrackable.sol:69]");
        _;
    }
}

 

 
contract TransactionTracker is Ownable, Servable {

     
     
     
    struct TransactionRecord {
        int256 value;
        uint256 blockNumber;
        address currencyCt;
        uint256 currencyId;
    }

    struct TransactionLog {
        TransactionRecord[] records;
        mapping(address => mapping(uint256 => uint256[])) recordIndicesByCurrency;
    }

     
     
     
    string constant public DEPOSIT_TRANSACTION_TYPE = "deposit";
    string constant public WITHDRAWAL_TRANSACTION_TYPE = "withdrawal";

     
     
     
    bytes32 public depositTransactionType;
    bytes32 public withdrawalTransactionType;

    mapping(address => mapping(bytes32 => TransactionLog)) private transactionLogByWalletType;

     
     
     
    constructor(address deployer) Ownable(deployer)
    public
    {
        depositTransactionType = keccak256(abi.encodePacked(DEPOSIT_TRANSACTION_TYPE));
        withdrawalTransactionType = keccak256(abi.encodePacked(WITHDRAWAL_TRANSACTION_TYPE));
    }

     
     
     
     
     
     
     
     
     
    function add(address wallet, bytes32 _type, int256 value, address currencyCt,
        uint256 currencyId)
    public
    onlyActiveService
    {
        transactionLogByWalletType[wallet][_type].records.length++;

        uint256 index = transactionLogByWalletType[wallet][_type].records.length - 1;

        transactionLogByWalletType[wallet][_type].records[index].value = value;
        transactionLogByWalletType[wallet][_type].records[index].blockNumber = block.number;
        transactionLogByWalletType[wallet][_type].records[index].currencyCt = currencyCt;
        transactionLogByWalletType[wallet][_type].records[index].currencyId = currencyId;

        transactionLogByWalletType[wallet][_type].recordIndicesByCurrency[currencyCt][currencyId].push(index);
    }

     
     
     
     
    function count(address wallet, bytes32 _type)
    public
    view
    returns (uint256)
    {
        return transactionLogByWalletType[wallet][_type].records.length;
    }

     
     
     
     
     
    function getByIndex(address wallet, bytes32 _type, uint256 index)
    public
    view
    returns (int256 value, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        TransactionRecord storage entry = transactionLogByWalletType[wallet][_type].records[index];
        value = entry.value;
        blockNumber = entry.blockNumber;
        currencyCt = entry.currencyCt;
        currencyId = entry.currencyId;
    }

     
     
     
     
     
    function getByBlockNumber(address wallet, bytes32 _type, uint256 _blockNumber)
    public
    view
    returns (int256 value, uint256 blockNumber, address currencyCt, uint256 currencyId)
    {
        return getByIndex(wallet, _type, _indexByBlockNumber(wallet, _type, _blockNumber));
    }

     
     
     
     
     
     
    function countByCurrency(address wallet, bytes32 _type, address currencyCt,
        uint256 currencyId)
    public
    view
    returns (uint256)
    {
        return transactionLogByWalletType[wallet][_type].recordIndicesByCurrency[currencyCt][currencyId].length;
    }

     
     
     
     
     
    function getByCurrencyIndex(address wallet, bytes32 _type, address currencyCt,
        uint256 currencyId, uint256 index)
    public
    view
    returns (int256 value, uint256 blockNumber)
    {
        uint256 entryIndex = transactionLogByWalletType[wallet][_type].recordIndicesByCurrency[currencyCt][currencyId][index];

        TransactionRecord storage entry = transactionLogByWalletType[wallet][_type].records[entryIndex];
        value = entry.value;
        blockNumber = entry.blockNumber;
    }

     
     
     
     
     
    function getByCurrencyBlockNumber(address wallet, bytes32 _type, address currencyCt,
        uint256 currencyId, uint256 _blockNumber)
    public
    view
    returns (int256 value, uint256 blockNumber)
    {
        return getByCurrencyIndex(
            wallet, _type, currencyCt, currencyId,
            _indexByCurrencyBlockNumber(
                wallet, _type, currencyCt, currencyId, _blockNumber
            )
        );
    }

     
     
     
    function _indexByBlockNumber(address wallet, bytes32 _type, uint256 blockNumber)
    private
    view
    returns (uint256)
    {
        require(
            0 < transactionLogByWalletType[wallet][_type].records.length,
            "No transactions found for wallet and type [TransactionTracker.sol:187]"
        );
        for (uint256 i = transactionLogByWalletType[wallet][_type].records.length - 1; i >= 0; i--)
            if (blockNumber >= transactionLogByWalletType[wallet][_type].records[i].blockNumber)
                return i;
        revert();
    }

    function _indexByCurrencyBlockNumber(address wallet, bytes32 _type, address currencyCt,
        uint256 currencyId, uint256 blockNumber)
    private
    view
    returns (uint256)
    {
        require(
            0 < transactionLogByWalletType[wallet][_type].recordIndicesByCurrency[currencyCt][currencyId].length,
            "No transactions found for wallet, type and currency [TransactionTracker.sol:203]"
        );
        for (uint256 i = transactionLogByWalletType[wallet][_type].recordIndicesByCurrency[currencyCt][currencyId].length - 1; i >= 0; i--) {
            uint256 j = transactionLogByWalletType[wallet][_type].recordIndicesByCurrency[currencyCt][currencyId][i];
            if (blockNumber >= transactionLogByWalletType[wallet][_type].records[j].blockNumber)
                return j;
        }
        revert();
    }
}

 

 
contract TransactionTrackable is Ownable {
     
     
     
    TransactionTracker public transactionTracker;
    bool public transactionTrackerFrozen;

     
     
     
    event SetTransactionTrackerEvent(TransactionTracker oldTransactionTracker, TransactionTracker newTransactionTracker);
    event FreezeTransactionTrackerEvent();

     
     
     
     
     
    function setTransactionTracker(TransactionTracker newTransactionTracker)
    public
    onlyDeployer
    notNullAddress(address(newTransactionTracker))
    notSameAddresses(address(newTransactionTracker), address(transactionTracker))
    {
         
        require(!transactionTrackerFrozen, "Transaction tracker frozen [TransactionTrackable.sol:43]");

         
        TransactionTracker oldTransactionTracker = transactionTracker;
        transactionTracker = newTransactionTracker;

         
        emit SetTransactionTrackerEvent(oldTransactionTracker, newTransactionTracker);
    }

     
     
    function freezeTransactionTracker()
    public
    onlyDeployer
    {
        transactionTrackerFrozen = true;

         
        emit FreezeTransactionTrackerEvent();
    }

     
     
     
    modifier transactionTrackerInitialized() {
        require(address(transactionTracker) != address(0), "Transaction track not initialized [TransactionTrackable.sol:69]");
        _;
    }
}

 

 
contract WalletLocker is Ownable, Configurable, AuthorizableServable {
    using SafeMathUintLib for uint256;

     
     
     
    struct FungibleLock {
        address locker;
        address currencyCt;
        uint256 currencyId;
        int256 amount;
        uint256 visibleTime;
        uint256 unlockTime;
    }

    struct NonFungibleLock {
        address locker;
        address currencyCt;
        uint256 currencyId;
        int256[] ids;
        uint256 visibleTime;
        uint256 unlockTime;
    }

     
     
     
    mapping(address => FungibleLock[]) public walletFungibleLocks;
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256)))) public lockedCurrencyLockerFungibleLockIndex;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public walletCurrencyFungibleLockCount;

    mapping(address => NonFungibleLock[]) public walletNonFungibleLocks;
    mapping(address => mapping(address => mapping(uint256 => mapping(address => uint256)))) public lockedCurrencyLockerNonFungibleLockIndex;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public walletCurrencyNonFungibleLockCount;

     
     
     
    event LockFungibleByProxyEvent(address lockedWallet, address lockerWallet, int256 amount,
        address currencyCt, uint256 currencyId, uint256 visibleTimeoutInSeconds);
    event LockNonFungibleByProxyEvent(address lockedWallet, address lockerWallet, int256[] ids,
        address currencyCt, uint256 currencyId, uint256 visibleTimeoutInSeconds);
    event UnlockFungibleEvent(address lockedWallet, address lockerWallet, int256 amount, address currencyCt,
        uint256 currencyId);
    event UnlockFungibleByProxyEvent(address lockedWallet, address lockerWallet, int256 amount, address currencyCt,
        uint256 currencyId);
    event UnlockNonFungibleEvent(address lockedWallet, address lockerWallet, int256[] ids, address currencyCt,
        uint256 currencyId);
    event UnlockNonFungibleByProxyEvent(address lockedWallet, address lockerWallet, int256[] ids, address currencyCt,
        uint256 currencyId);

     
     
     
    constructor(address deployer) Ownable(deployer)
    public
    {
    }

     
     
     

     
     
     
     
     
     
     
    function lockFungibleByProxy(address lockedWallet, address lockerWallet, int256 amount,
        address currencyCt, uint256 currencyId, uint256 visibleTimeoutInSeconds)
    public
    onlyAuthorizedService(lockedWallet)
    {
         
        require(lockedWallet != lockerWallet);

         
        uint256 lockIndex = lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockedWallet];

         
        require(
            (0 == lockIndex) ||
            (block.timestamp >= walletFungibleLocks[lockedWallet][lockIndex - 1].unlockTime)
        );

         
        if (0 == lockIndex) {
            lockIndex = ++(walletFungibleLocks[lockedWallet].length);
            lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet] = lockIndex;
            walletCurrencyFungibleLockCount[lockedWallet][currencyCt][currencyId]++;
        }

         
        walletFungibleLocks[lockedWallet][lockIndex - 1].locker = lockerWallet;
        walletFungibleLocks[lockedWallet][lockIndex - 1].amount = amount;
        walletFungibleLocks[lockedWallet][lockIndex - 1].currencyCt = currencyCt;
        walletFungibleLocks[lockedWallet][lockIndex - 1].currencyId = currencyId;
        walletFungibleLocks[lockedWallet][lockIndex - 1].visibleTime =
        block.timestamp.add(visibleTimeoutInSeconds);
        walletFungibleLocks[lockedWallet][lockIndex - 1].unlockTime =
        block.timestamp.add(configuration.walletLockTimeout());

         
        emit LockFungibleByProxyEvent(lockedWallet, lockerWallet, amount, currencyCt, currencyId, visibleTimeoutInSeconds);
    }

     
     
     
     
     
     
     
    function lockNonFungibleByProxy(address lockedWallet, address lockerWallet, int256[] memory ids,
        address currencyCt, uint256 currencyId, uint256 visibleTimeoutInSeconds)
    public
    onlyAuthorizedService(lockedWallet)
    {
         
        require(lockedWallet != lockerWallet);

         
        uint256 lockIndex = lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockedWallet];

         
        require(
            (0 == lockIndex) ||
            (block.timestamp >= walletNonFungibleLocks[lockedWallet][lockIndex - 1].unlockTime)
        );

         
        if (0 == lockIndex) {
            lockIndex = ++(walletNonFungibleLocks[lockedWallet].length);
            lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet] = lockIndex;
            walletCurrencyNonFungibleLockCount[lockedWallet][currencyCt][currencyId]++;
        }

         
        walletNonFungibleLocks[lockedWallet][lockIndex - 1].locker = lockerWallet;
        walletNonFungibleLocks[lockedWallet][lockIndex - 1].ids = ids;
        walletNonFungibleLocks[lockedWallet][lockIndex - 1].currencyCt = currencyCt;
        walletNonFungibleLocks[lockedWallet][lockIndex - 1].currencyId = currencyId;
        walletNonFungibleLocks[lockedWallet][lockIndex - 1].visibleTime =
        block.timestamp.add(visibleTimeoutInSeconds);
        walletNonFungibleLocks[lockedWallet][lockIndex - 1].unlockTime =
        block.timestamp.add(configuration.walletLockTimeout());

         
        emit LockNonFungibleByProxyEvent(lockedWallet, lockerWallet, ids, currencyCt, currencyId, visibleTimeoutInSeconds);
    }

     
     
     
     
     
     
    function unlockFungible(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    {
         
        uint256 lockIndex = lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

         
        if (0 == lockIndex)
            return;

         
        require(
            block.timestamp >= walletFungibleLocks[lockedWallet][lockIndex - 1].unlockTime
        );

         
        int256 amount = _unlockFungible(lockedWallet, lockerWallet, currencyCt, currencyId, lockIndex);

         
        emit UnlockFungibleEvent(lockedWallet, lockerWallet, amount, currencyCt, currencyId);
    }

     
     
     
     
     
     
    function unlockFungibleByProxy(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    onlyAuthorizedService(lockedWallet)
    {
         
        uint256 lockIndex = lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

         
        if (0 == lockIndex)
            return;

         
        int256 amount = _unlockFungible(lockedWallet, lockerWallet, currencyCt, currencyId, lockIndex);

         
        emit UnlockFungibleByProxyEvent(lockedWallet, lockerWallet, amount, currencyCt, currencyId);
    }

     
     
     
     
     
     
    function unlockNonFungible(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    {
         
        uint256 lockIndex = lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

         
        if (0 == lockIndex)
            return;

         
        require(
            block.timestamp >= walletNonFungibleLocks[lockedWallet][lockIndex - 1].unlockTime
        );

         
        int256[] memory ids = _unlockNonFungible(lockedWallet, lockerWallet, currencyCt, currencyId, lockIndex);

         
        emit UnlockNonFungibleEvent(lockedWallet, lockerWallet, ids, currencyCt, currencyId);
    }

     
     
     
     
     
     
    function unlockNonFungibleByProxy(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    onlyAuthorizedService(lockedWallet)
    {
         
        uint256 lockIndex = lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

         
        if (0 == lockIndex)
            return;

         
        int256[] memory ids = _unlockNonFungible(lockedWallet, lockerWallet, currencyCt, currencyId, lockIndex);

         
        emit UnlockNonFungibleByProxyEvent(lockedWallet, lockerWallet, ids, currencyCt, currencyId);
    }

     
     
     
    function fungibleLocksCount(address wallet)
    public
    view
    returns (uint256)
    {
        return walletFungibleLocks[wallet].length;
    }

     
     
     
    function nonFungibleLocksCount(address wallet)
    public
    view
    returns (uint256)
    {
        return walletNonFungibleLocks[wallet].length;
    }

     
     
     
     
     
     
    function lockedAmount(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        uint256 lockIndex = lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

        if (0 == lockIndex || block.timestamp < walletFungibleLocks[lockedWallet][lockIndex - 1].visibleTime)
            return 0;

        return walletFungibleLocks[lockedWallet][lockIndex - 1].amount;
    }

     
     
     
     
     
     
    function lockedIdsCount(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (uint256)
    {
        uint256 lockIndex = lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

        if (0 == lockIndex || block.timestamp < walletNonFungibleLocks[lockedWallet][lockIndex - 1].visibleTime)
            return 0;

        return walletNonFungibleLocks[lockedWallet][lockIndex - 1].ids.length;
    }

     
     
     
     
     
     
     
     
    function lockedIdsByIndices(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId,
        uint256 low, uint256 up)
    public
    view
    returns (int256[] memory)
    {
        uint256 lockIndex = lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];

        if (0 == lockIndex || block.timestamp < walletNonFungibleLocks[lockedWallet][lockIndex - 1].visibleTime)
            return new int256[](0);

        NonFungibleLock storage lock = walletNonFungibleLocks[lockedWallet][lockIndex - 1];

        if (0 == lock.ids.length)
            return new int256[](0);

        up = up.clampMax(lock.ids.length - 1);
        int256[] memory _ids = new int256[](up - low + 1);
        for (uint256 i = low; i <= up; i++)
            _ids[i - low] = lock.ids[i];

        return _ids;
    }

     
     
     
    function isLocked(address wallet)
    public
    view
    returns (bool)
    {
        return 0 < walletFungibleLocks[wallet].length ||
        0 < walletNonFungibleLocks[wallet].length;
    }

     
     
     
     
     
    function isLocked(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return 0 < walletCurrencyFungibleLockCount[wallet][currencyCt][currencyId] ||
        0 < walletCurrencyNonFungibleLockCount[wallet][currencyCt][currencyId];
    }

     
     
     
     
    function isLocked(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (bool)
    {
        return 0 < lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet] ||
        0 < lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet];
    }

     
     
     
     
    function _unlockFungible(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId, uint256 lockIndex)
    private
    returns (int256)
    {
        int256 amount = walletFungibleLocks[lockedWallet][lockIndex - 1].amount;

        if (lockIndex < walletFungibleLocks[lockedWallet].length) {
            walletFungibleLocks[lockedWallet][lockIndex - 1] =
            walletFungibleLocks[lockedWallet][walletFungibleLocks[lockedWallet].length - 1];

            lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][walletFungibleLocks[lockedWallet][lockIndex - 1].locker] = lockIndex;
        }
        walletFungibleLocks[lockedWallet].length--;

        lockedCurrencyLockerFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet] = 0;

        walletCurrencyFungibleLockCount[lockedWallet][currencyCt][currencyId]--;

        return amount;
    }

    function _unlockNonFungible(address lockedWallet, address lockerWallet, address currencyCt, uint256 currencyId, uint256 lockIndex)
    private
    returns (int256[] memory)
    {
        int256[] memory ids = walletNonFungibleLocks[lockedWallet][lockIndex - 1].ids;

        if (lockIndex < walletNonFungibleLocks[lockedWallet].length) {
            walletNonFungibleLocks[lockedWallet][lockIndex - 1] =
            walletNonFungibleLocks[lockedWallet][walletNonFungibleLocks[lockedWallet].length - 1];

            lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][walletNonFungibleLocks[lockedWallet][lockIndex - 1].locker] = lockIndex;
        }
        walletNonFungibleLocks[lockedWallet].length--;

        lockedCurrencyLockerNonFungibleLockIndex[lockedWallet][currencyCt][currencyId][lockerWallet] = 0;

        walletCurrencyNonFungibleLockCount[lockedWallet][currencyCt][currencyId]--;

        return ids;
    }
}

 

 
contract WalletLockable is Ownable {
     
     
     
    WalletLocker public walletLocker;
    bool public walletLockerFrozen;

     
     
     
    event SetWalletLockerEvent(WalletLocker oldWalletLocker, WalletLocker newWalletLocker);
    event FreezeWalletLockerEvent();

     
     
     
     
     
    function setWalletLocker(WalletLocker newWalletLocker)
    public
    onlyDeployer
    notNullAddress(address(newWalletLocker))
    notSameAddresses(address(newWalletLocker), address(walletLocker))
    {
         
        require(!walletLockerFrozen, "Wallet locker frozen [WalletLockable.sol:43]");

         
        WalletLocker oldWalletLocker = walletLocker;
        walletLocker = newWalletLocker;

         
        emit SetWalletLockerEvent(oldWalletLocker, newWalletLocker);
    }

     
     
    function freezeWalletLocker()
    public
    onlyDeployer
    {
        walletLockerFrozen = true;

         
        emit FreezeWalletLockerEvent();
    }

     
     
     
    modifier walletLockerInitialized() {
        require(address(walletLocker) != address(0), "Wallet locker not initialized [WalletLockable.sol:69]");
        _;
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

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

     
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

     
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

     
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
        return true;
    }

     
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
        return true;
    }

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }

     
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

      
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

 
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract MinterRole {
    using Roles for Roles.Role;

    event MinterAdded(address indexed account);
    event MinterRemoved(address indexed account);

    Roles.Role private _minters;

    constructor () internal {
        _addMinter(msg.sender);
    }

    modifier onlyMinter() {
        require(isMinter(msg.sender), "MinterRole: caller does not have the Minter role");
        _;
    }

    function isMinter(address account) public view returns (bool) {
        return _minters.has(account);
    }

    function addMinter(address account) public onlyMinter {
        _addMinter(account);
    }

    function renounceMinter() public {
        _removeMinter(msg.sender);
    }

    function _addMinter(address account) internal {
        _minters.add(account);
        emit MinterAdded(account);
    }

    function _removeMinter(address account) internal {
        _minters.remove(account);
        emit MinterRemoved(account);
    }
}

 
contract ERC20Mintable is ERC20, MinterRole {
     
    function mint(address account, uint256 amount) public onlyMinter returns (bool) {
        _mint(account, amount);
        return true;
    }
}

 

 
contract RevenueToken is ERC20Mintable {
    using SafeMath for uint256;

    bool public mintingDisabled;

    address[] public holders;

    mapping(address => bool) public holdersMap;

    mapping(address => uint256[]) public balances;

    mapping(address => uint256[]) public balanceBlocks;

    mapping(address => uint256[]) public balanceBlockNumbers;

    event DisableMinting();

     
    function disableMinting()
    public
    onlyMinter
    {
        mintingDisabled = true;

        emit DisableMinting();
    }

     
    function mint(address to, uint256 value)
    public
    onlyMinter
    returns (bool)
    {
        require(!mintingDisabled, "Minting disabled [RevenueToken.sol:60]");

         
        bool minted = super.mint(to, value);

        if (minted) {
             
            addBalanceBlocks(to);

             
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return minted;
    }

     
    function transfer(address to, uint256 value)
    public
    returns (bool)
    {
         
        bool transferred = super.transfer(to, value);

        if (transferred) {
             
            addBalanceBlocks(msg.sender);
            addBalanceBlocks(to);

             
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return transferred;
    }

     
    function approve(address spender, uint256 value)
    public
    returns (bool)
    {
         
        require(
            0 == value || 0 == allowance(msg.sender, spender),
            "Value or allowance non-zero [RevenueToken.sol:121]"
        );

         
        return super.approve(spender, value);
    }

     
    function transferFrom(address from, address to, uint256 value)
    public
    returns (bool)
    {
         
        bool transferred = super.transferFrom(from, to, value);

        if (transferred) {
             
            addBalanceBlocks(from);
            addBalanceBlocks(to);

             
            if (!holdersMap[to]) {
                holdersMap[to] = true;
                holders.push(to);
            }
        }

        return transferred;
    }

     
    function balanceBlocksIn(address account, uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        require(startBlock < endBlock, "Bounds parameters mismatch [RevenueToken.sol:173]");
        require(account != address(0), "Account is null address [RevenueToken.sol:174]");

        if (balanceBlockNumbers[account].length == 0 || endBlock < balanceBlockNumbers[account][0])
            return 0;

        uint256 i = 0;
        while (i < balanceBlockNumbers[account].length && balanceBlockNumbers[account][i] < startBlock)
            i++;

        uint256 r;
        if (i >= balanceBlockNumbers[account].length)
            r = balances[account][balanceBlockNumbers[account].length - 1].mul(endBlock.sub(startBlock));

        else {
            uint256 l = (i == 0) ? startBlock : balanceBlockNumbers[account][i - 1];

            uint256 h = balanceBlockNumbers[account][i];
            if (h > endBlock)
                h = endBlock;

            h = h.sub(startBlock);
            r = (h == 0) ? 0 : balanceBlocks[account][i].mul(h).div(balanceBlockNumbers[account][i].sub(l));
            i++;

            while (i < balanceBlockNumbers[account].length && balanceBlockNumbers[account][i] < endBlock) {
                r = r.add(balanceBlocks[account][i]);
                i++;
            }

            if (i >= balanceBlockNumbers[account].length)
                r = r.add(
                    balances[account][balanceBlockNumbers[account].length - 1].mul(
                        endBlock.sub(balanceBlockNumbers[account][balanceBlockNumbers[account].length - 1])
                    )
                );

            else if (balanceBlockNumbers[account][i - 1] < endBlock)
                r = r.add(
                    balanceBlocks[account][i].mul(
                        endBlock.sub(balanceBlockNumbers[account][i - 1])
                    ).div(
                        balanceBlockNumbers[account][i].sub(balanceBlockNumbers[account][i - 1])
                    )
                );
        }

        return r;
    }

     
    function balanceUpdatesCount(address account)
    public
    view
    returns (uint256)
    {
        return balanceBlocks[account].length;
    }

     
    function holdersCount()
    public
    view
    returns (uint256)
    {
        return holders.length;
    }

     
    function holdersByIndices(uint256 low, uint256 up, bool posOnly)
    public
    view
    returns (address[] memory)
    {
        require(low <= up, "Bounds parameters mismatch [RevenueToken.sol:259]");

        up = up > holders.length - 1 ? holders.length - 1 : up;

        uint256 length = 0;
        if (posOnly) {
            for (uint256 i = low; i <= up; i++)
                if (0 < balanceOf(holders[i]))
                    length++;
        } else
            length = up - low + 1;

        address[] memory _holders = new address[](length);

        uint256 j = 0;
        for (uint256 i = low; i <= up; i++)
            if (!posOnly || 0 < balanceOf(holders[i]))
                _holders[j++] = holders[i];

        return _holders;
    }

    function addBalanceBlocks(address account)
    private
    {
        uint256 length = balanceBlockNumbers[account].length;
        balances[account].push(balanceOf(account));
        if (0 < length)
            balanceBlocks[account].push(
                balances[account][length - 1].mul(
                    block.number.sub(balanceBlockNumbers[account][length - 1])
                )
            );
        else
            balanceBlocks[account].push(0);
        balanceBlockNumbers[account].push(block.number);
    }
}

 
library Address {
     
    function isContract(address account) internal view returns (bool) {
         
         
         

        uint256 size;
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

 
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
         
         
         
         
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

     
    function callOptionalReturn(IERC20 token, bytes memory data) private {
         
         

         
         
         
         
         
        require(address(token).isContract(), "SafeERC20: call to non-contract");

         
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {  
             
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

 

 
contract TokenMultiTimelock is Ownable {
    using SafeERC20 for IERC20;

     
     
     
    struct Release {
        uint256 earliestReleaseTime;
        uint256 amount;
        uint256 blockNumber;
        bool done;
    }

     
     
     
    IERC20 public token;
    address public beneficiary;

    Release[] public releases;
    uint256 public totalLockedAmount;
    uint256 public executedReleasesCount;

     
     
     
    event SetTokenEvent(IERC20 token);
    event SetBeneficiaryEvent(address beneficiary);
    event DefineReleaseEvent(uint256 earliestReleaseTime, uint256 amount, uint256 blockNumber);
    event SetReleaseBlockNumberEvent(uint256 index, uint256 blockNumber);
    event ReleaseEvent(uint256 index, uint256 blockNumber, uint256 earliestReleaseTime,
        uint256 actualReleaseTime, uint256 amount);

     
     
     
    constructor(address deployer)
    Ownable(deployer)
    public
    {
    }

     
     
     
     
     
    function setToken(IERC20 _token)
    public
    onlyOperator
    notNullOrThisAddress(address(_token))
    {
         
        require(address(token) == address(0), "Token previously set [TokenMultiTimelock.sol:73]");

         
        token = _token;

         
        emit SetTokenEvent(token);
    }

     
     
    function setBeneficiary(address _beneficiary)
    public
    onlyOperator
    notNullAddress(_beneficiary)
    {
         
        beneficiary = _beneficiary;

         
        emit SetBeneficiaryEvent(beneficiary);
    }

     
     
     
     
     
    function defineReleases(uint256[] memory earliestReleaseTimes, uint256[] memory amounts, uint256[] memory releaseBlockNumbers)
    onlyOperator
    public
    {
        require(
            earliestReleaseTimes.length == amounts.length,
            "Earliest release times and amounts lengths mismatch [TokenMultiTimelock.sol:105]"
        );
        require(
            earliestReleaseTimes.length >= releaseBlockNumbers.length,
            "Earliest release times and release block numbers lengths mismatch [TokenMultiTimelock.sol:109]"
        );

         
        require(address(token) != address(0), "Token not initialized [TokenMultiTimelock.sol:115]");

        for (uint256 i = 0; i < earliestReleaseTimes.length; i++) {
             
            totalLockedAmount += amounts[i];

             
             
            require(token.balanceOf(address(this)) >= totalLockedAmount, "Total locked amount overrun [TokenMultiTimelock.sol:123]");

             
            uint256 blockNumber = i < releaseBlockNumbers.length ? releaseBlockNumbers[i] : 0;

             
            releases.push(Release(earliestReleaseTimes[i], amounts[i], blockNumber, false));

             
            emit DefineReleaseEvent(earliestReleaseTimes[i], amounts[i], blockNumber);
        }
    }

     
     
    function releasesCount()
    public
    view
    returns (uint256)
    {
        return releases.length;
    }

     
     
     
    function setReleaseBlockNumber(uint256 index, uint256 blockNumber)
    public
    onlyBeneficiary
    {
         
        require(!releases[index].done, "Release previously done [TokenMultiTimelock.sol:154]");

         
        releases[index].blockNumber = blockNumber;

         
        emit SetReleaseBlockNumberEvent(index, blockNumber);
    }

     
     
    function release(uint256 index)
    public
    onlyBeneficiary
    {
         
        Release storage _release = releases[index];

         
        require(0 < _release.amount, "Release amount not strictly positive [TokenMultiTimelock.sol:173]");

         
        require(!_release.done, "Release previously done [TokenMultiTimelock.sol:176]");

         
        require(block.timestamp >= _release.earliestReleaseTime, "Block time stamp less than earliest release time [TokenMultiTimelock.sol:179]");

         
        _release.done = true;

         
        if (0 == _release.blockNumber)
            _release.blockNumber = block.number;

         
        executedReleasesCount++;

         
        totalLockedAmount -= _release.amount;

         
        token.safeTransfer(beneficiary, _release.amount);

         
        emit ReleaseEvent(index, _release.blockNumber, _release.earliestReleaseTime, block.timestamp, _release.amount);
    }

     
     
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Message sender not beneficiary [TokenMultiTimelock.sol:204]");
        _;
    }
}

 

contract RevenueTokenManager is TokenMultiTimelock {
    using SafeMathUintLib for uint256;

     
     
     
    uint256[] public totalReleasedAmounts;
    uint256[] public totalReleasedAmountBlocks;

     
     
     
    constructor(address deployer)
    public
    TokenMultiTimelock(deployer)
    {
    }

     
     
     
     
     
     
    function release(uint256 index)
    public
    onlyBeneficiary
    {
         
        super.release(index);

         
        _addAmountBlocks(index);
    }

     
     
     
     
     
    function releasedAmountBlocksIn(uint256 startBlock, uint256 endBlock)
    public
    view
    returns (uint256)
    {
        require(startBlock < endBlock, "Bounds parameters mismatch [RevenueTokenManager.sol:60]");

        if (executedReleasesCount == 0 || endBlock < releases[0].blockNumber)
            return 0;

        uint256 i = 0;
        while (i < executedReleasesCount && releases[i].blockNumber < startBlock)
            i++;

        uint256 r;
        if (i >= executedReleasesCount)
            r = totalReleasedAmounts[executedReleasesCount - 1].mul(endBlock.sub(startBlock));

        else {
            uint256 l = (i == 0) ? startBlock : releases[i - 1].blockNumber;

            uint256 h = releases[i].blockNumber;
            if (h > endBlock)
                h = endBlock;

            h = h.sub(startBlock);
            r = (h == 0) ? 0 : totalReleasedAmountBlocks[i].mul(h).div(releases[i].blockNumber.sub(l));
            i++;

            while (i < executedReleasesCount && releases[i].blockNumber < endBlock) {
                r = r.add(totalReleasedAmountBlocks[i]);
                i++;
            }

            if (i >= executedReleasesCount)
                r = r.add(
                    totalReleasedAmounts[executedReleasesCount - 1].mul(
                        endBlock.sub(releases[executedReleasesCount - 1].blockNumber)
                    )
                );

            else if (releases[i - 1].blockNumber < endBlock)
                r = r.add(
                    totalReleasedAmountBlocks[i].mul(
                        endBlock.sub(releases[i - 1].blockNumber)
                    ).div(
                        releases[i].blockNumber.sub(releases[i - 1].blockNumber)
                    )
                );
        }

        return r;
    }

     
     
     
    function releaseBlockNumbers(uint256 index)
    public
    view
    returns (uint256)
    {
        return releases[index].blockNumber;
    }

     
     
     
    function _addAmountBlocks(uint256 index)
    private
    {
         
        if (0 < index) {
            totalReleasedAmounts.push(
                totalReleasedAmounts[index - 1] + releases[index].amount
            );
            totalReleasedAmountBlocks.push(
                totalReleasedAmounts[index - 1].mul(
                    releases[index].blockNumber.sub(releases[index - 1].blockNumber)
                )
            );

        } else {
            totalReleasedAmounts.push(releases[index].amount);
            totalReleasedAmountBlocks.push(0);
        }
    }
}

 

 
contract TokenHolderRevenueFund is Ownable, AccrualBeneficiary, Servable, TransferControllerManageable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;
    using FungibleBalanceLib for FungibleBalanceLib.Balance;
    using TxHistoryLib for TxHistoryLib.TxHistory;
    using CurrenciesLib for CurrenciesLib.Currencies;

     
     
     
    string constant public CLOSE_ACCRUAL_PERIOD_ACTION = "close_accrual_period";

     
     
     
    RevenueTokenManager public revenueTokenManager;

    FungibleBalanceLib.Balance private periodAccrual;
    CurrenciesLib.Currencies private periodCurrencies;

    FungibleBalanceLib.Balance private aggregateAccrual;
    CurrenciesLib.Currencies private aggregateCurrencies;

    TxHistoryLib.TxHistory private txHistory;

    mapping(address => mapping(address => mapping(uint256 => uint256[]))) public claimedAccrualBlockNumbersByWalletCurrency;

    mapping(address => mapping(uint256 => uint256[])) public accrualBlockNumbersByCurrency;
    mapping(address => mapping(uint256 => mapping(uint256 => int256))) public aggregateAccrualAmountByCurrencyBlockNumber;

    mapping(address => FungibleBalanceLib.Balance) private stagedByWallet;

     
     
     
    event SetRevenueTokenManagerEvent(RevenueTokenManager oldRevenueTokenManager,
        RevenueTokenManager newRevenueTokenManager);
    event ReceiveEvent(address wallet, int256 amount, address currencyCt,
        uint256 currencyId);
    event WithdrawEvent(address to, int256 amount, address currencyCt, uint256 currencyId);
    event CloseAccrualPeriodEvent(int256 periodAmount, int256 aggregateAmount, address currencyCt,
        uint256 currencyId);
    event ClaimAndTransferToBeneficiaryEvent(address wallet, string balanceType, int256 amount,
        address currencyCt, uint256 currencyId, string standard);
    event ClaimAndTransferToBeneficiaryByProxyEvent(address wallet, string balanceType, int256 amount,
        address currencyCt, uint256 currencyId, string standard);
    event ClaimAndStageEvent(address from, int256 amount, address currencyCt, uint256 currencyId);
    event WithdrawEvent(address from, int256 amount, address currencyCt, uint256 currencyId,
        string standard);

     
     
     
    constructor(address deployer) Ownable(deployer) public {
    }

     
     
     
     
     
    function setRevenueTokenManager(RevenueTokenManager newRevenueTokenManager)
    public
    onlyDeployer
    notNullAddress(address(newRevenueTokenManager))
    {
        if (newRevenueTokenManager != revenueTokenManager) {
             
            RevenueTokenManager oldRevenueTokenManager = revenueTokenManager;
            revenueTokenManager = newRevenueTokenManager;

             
            emit SetRevenueTokenManagerEvent(oldRevenueTokenManager, newRevenueTokenManager);
        }
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

     
     
     
     
     
    function receiveTokens(string memory, int256 amount, address currencyCt, uint256 currencyId,
        string memory standard)
    public
    {
        receiveTokensTo(msg.sender, "", amount, currencyCt, currencyId, standard);
    }

     
     
     
     
     
     
    function receiveTokensTo(address wallet, string memory, int256 amount, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        require(amount.isNonZeroPositiveInt256(), "Amount not strictly positive [TokenHolderRevenueFund.sol:157]");

         
        TransferController controller = transferController(currencyCt, standard);
        (bool success,) = address(controller).delegatecall(
            abi.encodeWithSelector(
                controller.getReceiveSignature(), msg.sender, this, uint256(amount), currencyCt, currencyId
            )
        );
        require(success, "Reception by controller failed [TokenHolderRevenueFund.sol:166]");

         
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

     
     
     
     
     
    function stagedBalance(address wallet, address currencyCt, uint256 currencyId)
    public
    view
    returns (int256)
    {
        return stagedByWallet[wallet].get(currencyCt, currencyId);
    }

     
     
    function closeAccrualPeriod(MonetaryTypesLib.Currency[] memory currencies)
    public
    onlyEnabledServiceAction(CLOSE_ACCRUAL_PERIOD_ACTION)
    {
         
        for (uint256 i = 0; i < currencies.length; i++) {
            MonetaryTypesLib.Currency memory currency = currencies[i];

             
            int256 periodAmount = periodAccrual.get(currency.ct, currency.id);

             
            accrualBlockNumbersByCurrency[currency.ct][currency.id].push(block.number);

             
            aggregateAccrualAmountByCurrencyBlockNumber[currency.ct][currency.id][block.number] = aggregateAccrualBalance(
                currency.ct, currency.id
            );

            if (periodAmount > 0) {
                 
                periodAccrual.set(0, currency.ct, currency.id);

                 
                periodCurrencies.removeByCurrency(currency.ct, currency.id);
            }

             
            emit CloseAccrualPeriodEvent(
                periodAmount,
                aggregateAccrualAmountByCurrencyBlockNumber[currency.ct][currency.id][block.number],
                currency.ct, currency.id
            );
        }
    }

     
     
     
     
     
     
     
    function claimAndTransferToBeneficiary(Beneficiary beneficiary, address destWallet, string memory balanceType,
        address currencyCt, uint256 currencyId, string memory standard)
    public
    {
         
        int256 claimedAmount = _claim(msg.sender, currencyCt, currencyId);

         
        if (address(0) == currencyCt && 0 == currencyId)
            beneficiary.receiveEthersTo.value(uint256(claimedAmount))(destWallet, balanceType);

        else {
             
            TransferController controller = transferController(currencyCt, standard);
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getApproveSignature(), address(beneficiary), uint256(claimedAmount), currencyCt, currencyId
                )
            );
            require(success, "Approval by controller failed [TokenHolderRevenueFund.sol:349]");

             
            beneficiary.receiveTokensTo(destWallet, balanceType, claimedAmount, currencyCt, currencyId, standard);
        }

         
        emit ClaimAndTransferToBeneficiaryEvent(msg.sender, balanceType, claimedAmount, currencyCt, currencyId, standard);
    }

     
     
     
    function claimAndStage(address currencyCt, uint256 currencyId)
    public
    {
         
        int256 claimedAmount = _claim(msg.sender, currencyCt, currencyId);

         
        stagedByWallet[msg.sender].add(claimedAmount, currencyCt, currencyId);

         
        emit ClaimAndStageEvent(msg.sender, claimedAmount, currencyCt, currencyId);
    }

     
     
     
     
     
    function withdraw(int256 amount, address currencyCt, uint256 currencyId, string memory standard)
    public
    {
         
        require(amount.isNonZeroPositiveInt256(), "Amount not strictly positive [TokenHolderRevenueFund.sol:384]");

         
        amount = amount.clampMax(stagedByWallet[msg.sender].get(currencyCt, currencyId));

         
        stagedByWallet[msg.sender].sub(amount, currencyCt, currencyId);

         
        if (address(0) == currencyCt && 0 == currencyId)
            msg.sender.transfer(uint256(amount));

        else {
            TransferController controller = transferController(currencyCt, standard);
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getDispatchSignature(), address(this), msg.sender, uint256(amount), currencyCt, currencyId
                )
            );
            require(success, "Dispatch by controller failed [TokenHolderRevenueFund.sol:403]");
        }

         
        emit WithdrawEvent(msg.sender, amount, currencyCt, currencyId, standard);
    }

     
     
     
    function _claim(address wallet, address currencyCt, uint256 currencyId)
    private
    returns (int256)
    {
         
        require(0 < accrualBlockNumbersByCurrency[currencyCt][currencyId].length, "No terminated accrual period found [TokenHolderRevenueFund.sol:418]");

         
        uint256[] storage claimedAccrualBlockNumbers = claimedAccrualBlockNumbersByWalletCurrency[wallet][currencyCt][currencyId];
        uint256 bnLow = (0 == claimedAccrualBlockNumbers.length ? 0 : claimedAccrualBlockNumbers[claimedAccrualBlockNumbers.length - 1]);

         
        uint256 bnUp = accrualBlockNumbersByCurrency[currencyCt][currencyId][accrualBlockNumbersByCurrency[currencyCt][currencyId].length - 1];

         
        require(bnLow < bnUp, "Bounds parameters mismatch [TokenHolderRevenueFund.sol:428]");

         
        int256 claimableAmount = aggregateAccrualAmountByCurrencyBlockNumber[currencyCt][currencyId][bnUp]
        - (0 == bnLow ? 0 : aggregateAccrualAmountByCurrencyBlockNumber[currencyCt][currencyId][bnLow]);

         
        require(claimableAmount.isNonZeroPositiveInt256(), "Claimable amount not strictly positive [TokenHolderRevenueFund.sol:435]");

         
        int256 walletBalanceBlocks = int256(
            RevenueToken(address(revenueTokenManager.token())).balanceBlocksIn(wallet, bnLow, bnUp)
        );

         
        int256 releasedAmountBlocks = int256(
            revenueTokenManager.releasedAmountBlocksIn(bnLow, bnUp)
        );

         
        int256 claimedAmount = walletBalanceBlocks.mul_nn(claimableAmount).mul_nn(1e18).div_nn(releasedAmountBlocks.mul_nn(1e18));

         
        claimedAccrualBlockNumbers.push(bnUp);

         
        return claimedAmount;
    }
}

 

 
contract ClientFund is Ownable, Beneficiary, Benefactor, AuthorizableServable, TransferControllerManageable,
BalanceTrackable, TransactionTrackable, WalletLockable {
    using SafeMathIntLib for int256;

    address[] public seizedWallets;
    mapping(address => bool) public seizedByWallet;

    TokenHolderRevenueFund public tokenHolderRevenueFund;

     
     
     
    event SetTokenHolderRevenueFundEvent(TokenHolderRevenueFund oldTokenHolderRevenueFund,
        TokenHolderRevenueFund newTokenHolderRevenueFund);
    event ReceiveEvent(address wallet, string balanceType, int256 value, address currencyCt,
        uint256 currencyId, string standard);
    event WithdrawEvent(address wallet, int256 value, address currencyCt, uint256 currencyId,
        string standard);
    event StageEvent(address wallet, int256 value, address currencyCt, uint256 currencyId,
        string standard);
    event UnstageEvent(address wallet, int256 value, address currencyCt, uint256 currencyId,
        string standard);
    event UpdateSettledBalanceEvent(address wallet, int256 value, address currencyCt,
        uint256 currencyId);
    event StageToBeneficiaryEvent(address sourceWallet, Beneficiary beneficiary, int256 value,
        address currencyCt, uint256 currencyId, string standard);
    event TransferToBeneficiaryEvent(address wallet, Beneficiary beneficiary, int256 value,
        address currencyCt, uint256 currencyId, string standard);
    event SeizeBalancesEvent(address seizedWallet, address seizerWallet, int256 value,
        address currencyCt, uint256 currencyId);
    event ClaimRevenueEvent(address claimer, string balanceType, address currencyCt,
        uint256 currencyId, string standard);

     
     
     
    constructor(address deployer) Ownable(deployer) Beneficiary() Benefactor()
    public
    {
        serviceActivationTimeout = 1 weeks;
    }

     
     
     
     
     
    function setTokenHolderRevenueFund(TokenHolderRevenueFund newTokenHolderRevenueFund)
    public
    onlyDeployer
    notNullAddress(address(newTokenHolderRevenueFund))
    notSameAddresses(address(newTokenHolderRevenueFund), address(tokenHolderRevenueFund))
    {
         
        TokenHolderRevenueFund oldTokenHolderRevenueFund = tokenHolderRevenueFund;
        tokenHolderRevenueFund = newTokenHolderRevenueFund;

         
        emit SetTokenHolderRevenueFundEvent(oldTokenHolderRevenueFund, newTokenHolderRevenueFund);
    }

     
    function()
    external
    payable
    {
        receiveEthersTo(msg.sender, balanceTracker.DEPOSITED_BALANCE_TYPE());
    }

     
     
     
    function receiveEthersTo(address wallet, string memory balanceType)
    public
    payable
    {
        int256 value = SafeMathIntLib.toNonZeroInt256(msg.value);

         
        _receiveTo(wallet, balanceType, value, address(0), 0, true);

         
        emit ReceiveEvent(wallet, balanceType, value, address(0), 0, "");
    }

     
     
     
     
     
     
     
    function receiveTokens(string memory balanceType, int256 value, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        receiveTokensTo(msg.sender, balanceType, value, currencyCt, currencyId, standard);
    }

     
     
     
     
     
     
     
    function receiveTokensTo(address wallet, string memory balanceType, int256 value, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    {
        require(value.isNonZeroPositiveInt256());

         
        TransferController controller = transferController(currencyCt, standard);

         
        (bool success,) = address(controller).delegatecall(
            abi.encodeWithSelector(
                controller.getReceiveSignature(), msg.sender, this, uint256(value), currencyCt, currencyId
            )
        );
        require(success);

         
        _receiveTo(wallet, balanceType, value, currencyCt, currencyId, controller.isFungible());

         
        emit ReceiveEvent(wallet, balanceType, value, currencyCt, currencyId, standard);
    }

     
     
     
     
     
     
     
     
    function updateSettledBalance(address wallet, int256 value, address currencyCt, uint256 currencyId,
        string memory standard, uint256 blockNumber)
    public
    onlyAuthorizedService(wallet)
    notNullAddress(wallet)
    {
        require(value.isPositiveInt256());

        if (_isFungible(currencyCt, currencyId, standard)) {
            (int256 depositedValue,) = balanceTracker.fungibleRecordByBlockNumber(
                wallet, balanceTracker.depositedBalanceType(), currencyCt, currencyId, blockNumber
            );
            balanceTracker.set(
                wallet, balanceTracker.settledBalanceType(), value.sub(depositedValue),
                currencyCt, currencyId, true
            );

        } else {
            balanceTracker.sub(
                wallet, balanceTracker.depositedBalanceType(), value, currencyCt, currencyId, false
            );
            balanceTracker.add(
                wallet, balanceTracker.settledBalanceType(), value, currencyCt, currencyId, false
            );
        }

         
        emit UpdateSettledBalanceEvent(wallet, value, currencyCt, currencyId);
    }

     
     
     
     
     
     
    function stage(address wallet, int256 value, address currencyCt, uint256 currencyId,
        string memory standard)
    public
    onlyAuthorizedService(wallet)
    {
        require(value.isNonZeroPositiveInt256());

         
        bool fungible = _isFungible(currencyCt, currencyId, standard);

         
        value = _subtractSequentially(wallet, balanceTracker.activeBalanceTypes(), value, currencyCt, currencyId, fungible);

         
        balanceTracker.add(
            wallet, balanceTracker.stagedBalanceType(), value, currencyCt, currencyId, fungible
        );

         
        emit StageEvent(wallet, value, currencyCt, currencyId, standard);
    }

     
     
     
     
     
    function unstage(int256 value, address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        require(value.isNonZeroPositiveInt256());

         
        bool fungible = _isFungible(currencyCt, currencyId, standard);

         
        value = _subtractFromStaged(msg.sender, value, currencyCt, currencyId, fungible);

         
        balanceTracker.add(
            msg.sender, balanceTracker.depositedBalanceType(), value, currencyCt, currencyId, fungible
        );

         
        emit UnstageEvent(msg.sender, value, currencyCt, currencyId, standard);
    }

     
     
     
     
     
     
     
    function stageToBeneficiary(address wallet, Beneficiary beneficiary, int256 value,
        address currencyCt, uint256 currencyId, string memory standard)
    public
    onlyAuthorizedService(wallet)
    {
         
        bool fungible = _isFungible(currencyCt, currencyId, standard);

         
        value = _subtractSequentially(wallet, balanceTracker.activeBalanceTypes(), value, currencyCt, currencyId, fungible);

         
        _transferToBeneficiary(wallet, beneficiary, value, currencyCt, currencyId, standard);

         
        emit StageToBeneficiaryEvent(wallet, beneficiary, value, currencyCt, currencyId, standard);
    }

     
     
     
     
     
     
     
    function transferToBeneficiary(address wallet, Beneficiary beneficiary, int256 value,
        address currencyCt, uint256 currencyId, string memory standard)
    public
    onlyAuthorizedService(wallet)
    {
         
        _transferToBeneficiary(wallet, beneficiary, value, currencyCt, currencyId, standard);

         
        emit TransferToBeneficiaryEvent(wallet, beneficiary, value, currencyCt, currencyId, standard);
    }

     
     
     
     
     
     
    function seizeBalances(address wallet, address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        if (_isFungible(currencyCt, currencyId, standard))
            _seizeFungibleBalances(wallet, msg.sender, currencyCt, currencyId);

        else
            _seizeNonFungibleBalances(wallet, msg.sender, currencyCt, currencyId);

         
        if (!seizedByWallet[wallet]) {
            seizedByWallet[wallet] = true;
            seizedWallets.push(wallet);
        }
    }

     
     
     
     
     
    function withdraw(int256 value, address currencyCt, uint256 currencyId, string memory standard)
    public
    {
        require(value.isNonZeroPositiveInt256());

         
        require(!walletLocker.isLocked(msg.sender, currencyCt, currencyId));

         
        bool fungible = _isFungible(currencyCt, currencyId, standard);

         
        value = _subtractFromStaged(msg.sender, value, currencyCt, currencyId, fungible);

         
        transactionTracker.add(
            msg.sender, transactionTracker.withdrawalTransactionType(), value, currencyCt, currencyId
        );

         
        _transferToWallet(msg.sender, value, currencyCt, currencyId, standard);

         
        emit WithdrawEvent(msg.sender, value, currencyCt, currencyId, standard);
    }

     
     
     
    function isSeizedWallet(address wallet)
    public
    view
    returns (bool)
    {
        return seizedByWallet[wallet];
    }

     
     
    function seizedWalletsCount()
    public
    view
    returns (uint256)
    {
        return seizedWallets.length;
    }

     
     
     
     
     
     
     
    function claimRevenue(address claimer, string memory balanceType, address currencyCt,
        uint256 currencyId, string memory standard)
    public
    onlyOperator
    {
        tokenHolderRevenueFund.claimAndTransferToBeneficiary(
            this, claimer, balanceType,
            currencyCt, currencyId, standard
        );

        emit ClaimRevenueEvent(claimer, balanceType, currencyCt, currencyId, standard);
    }

     
     
     
    function _receiveTo(address wallet, string memory balanceType, int256 value, address currencyCt,
        uint256 currencyId, bool fungible)
    private
    {
        bytes32 balanceHash = 0 < bytes(balanceType).length ?
        keccak256(abi.encodePacked(balanceType)) :
        balanceTracker.depositedBalanceType();

         
        if (balanceTracker.stagedBalanceType() == balanceHash)
            balanceTracker.add(
                wallet, balanceTracker.stagedBalanceType(), value, currencyCt, currencyId, fungible
            );

         
        else if (balanceTracker.depositedBalanceType() == balanceHash) {
            balanceTracker.add(
                wallet, balanceTracker.depositedBalanceType(), value, currencyCt, currencyId, fungible
            );

             
            transactionTracker.add(
                wallet, transactionTracker.depositTransactionType(), value, currencyCt, currencyId
            );
        }

        else
            revert();
    }

    function _subtractSequentially(address wallet, bytes32[] memory balanceTypes, int256 value, address currencyCt,
        uint256 currencyId, bool fungible)
    private
    returns (int256)
    {
        if (fungible)
            return _subtractFungibleSequentially(wallet, balanceTypes, value, currencyCt, currencyId);
        else
            return _subtractNonFungibleSequentially(wallet, balanceTypes, value, currencyCt, currencyId);
    }

    function _subtractFungibleSequentially(address wallet, bytes32[] memory balanceTypes, int256 amount, address currencyCt, uint256 currencyId)
    private
    returns (int256)
    {
         
        require(0 <= amount);

        uint256 i;
        int256 totalBalanceAmount = 0;
        for (i = 0; i < balanceTypes.length; i++)
            totalBalanceAmount = totalBalanceAmount.add(
                balanceTracker.get(
                    wallet, balanceTypes[i], currencyCt, currencyId
                )
            );

         
        amount = amount.clampMax(totalBalanceAmount);

        int256 _amount = amount;
        for (i = 0; i < balanceTypes.length; i++) {
            int256 typeAmount = balanceTracker.get(
                wallet, balanceTypes[i], currencyCt, currencyId
            );

            if (typeAmount >= _amount) {
                balanceTracker.sub(
                    wallet, balanceTypes[i], _amount, currencyCt, currencyId, true
                );
                break;

            } else {
                balanceTracker.set(
                    wallet, balanceTypes[i], 0, currencyCt, currencyId, true
                );
                _amount = _amount.sub(typeAmount);
            }
        }

        return amount;
    }

    function _subtractNonFungibleSequentially(address wallet, bytes32[] memory balanceTypes, int256 id, address currencyCt, uint256 currencyId)
    private
    returns (int256)
    {
        for (uint256 i = 0; i < balanceTypes.length; i++)
            if (balanceTracker.hasId(wallet, balanceTypes[i], id, currencyCt, currencyId)) {
                balanceTracker.sub(wallet, balanceTypes[i], id, currencyCt, currencyId, false);
                break;
            }

        return id;
    }

    function _subtractFromStaged(address wallet, int256 value, address currencyCt, uint256 currencyId, bool fungible)
    private
    returns (int256)
    {
        if (fungible) {
             
            value = value.clampMax(
                balanceTracker.get(wallet, balanceTracker.stagedBalanceType(), currencyCt, currencyId)
            );

             
            require(0 <= value);

        } else {
             
            require(balanceTracker.hasId(wallet, balanceTracker.stagedBalanceType(), value, currencyCt, currencyId));
        }

         
        balanceTracker.sub(wallet, balanceTracker.stagedBalanceType(), value, currencyCt, currencyId, fungible);

        return value;
    }

    function _transferToBeneficiary(address destWallet, Beneficiary beneficiary,
        int256 value, address currencyCt, uint256 currencyId, string memory standard)
    private
    {
        require(value.isNonZeroPositiveInt256());
        require(isRegisteredBeneficiary(beneficiary));

         
        if (address(0) == currencyCt && 0 == currencyId)
            beneficiary.receiveEthersTo.value(uint256(value))(destWallet, "");

        else {
             
            TransferController controller = transferController(currencyCt, standard);

             
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getApproveSignature(), address(beneficiary), uint256(value), currencyCt, currencyId
                )
            );
            require(success);

             
            beneficiary.receiveTokensTo(destWallet, "", value, currencyCt, currencyId, controller.standard());
        }
    }

    function _transferToWallet(address payable wallet,
        int256 value, address currencyCt, uint256 currencyId, string memory standard)
    private
    {
         
        if (address(0) == currencyCt && 0 == currencyId)
            wallet.transfer(uint256(value));

        else {
             
            TransferController controller = transferController(currencyCt, standard);

             
            (bool success,) = address(controller).delegatecall(
                abi.encodeWithSelector(
                    controller.getDispatchSignature(), address(this), wallet, uint256(value), currencyCt, currencyId
                )
            );
            require(success);
        }
    }

    function _seizeFungibleBalances(address lockedWallet, address lockerWallet, address currencyCt,
        uint256 currencyId)
    private
    {
         
        int256 amount = walletLocker.lockedAmount(lockedWallet, lockerWallet, currencyCt, currencyId);

         
        require(amount > 0);

         
        _subtractFungibleSequentially(lockedWallet, balanceTracker.allBalanceTypes(), amount, currencyCt, currencyId);

         
        balanceTracker.add(
            lockerWallet, balanceTracker.stagedBalanceType(), amount, currencyCt, currencyId, true
        );

         
        emit SeizeBalancesEvent(lockedWallet, lockerWallet, amount, currencyCt, currencyId);
    }

    function _seizeNonFungibleBalances(address lockedWallet, address lockerWallet, address currencyCt,
        uint256 currencyId)
    private
    {
         
        uint256 lockedIdsCount = walletLocker.lockedIdsCount(lockedWallet, lockerWallet, currencyCt, currencyId);
        require(0 < lockedIdsCount);

         
        int256[] memory ids = walletLocker.lockedIdsByIndices(
            lockedWallet, lockerWallet, currencyCt, currencyId, 0, lockedIdsCount - 1
        );

        for (uint256 i = 0; i < ids.length; i++) {
             
            _subtractNonFungibleSequentially(lockedWallet, balanceTracker.allBalanceTypes(), ids[i], currencyCt, currencyId);

             
            balanceTracker.add(
                lockerWallet, balanceTracker.stagedBalanceType(), ids[i], currencyCt, currencyId, false
            );

             
            emit SeizeBalancesEvent(lockedWallet, lockerWallet, ids[i], currencyCt, currencyId);
        }
    }

    function _isFungible(address currencyCt, uint256 currencyId, string memory standard)
    private
    view
    returns (bool)
    {
        return (address(0) == currencyCt && 0 == currencyId) || transferController(currencyCt, standard).isFungible();
    }
}

 

 
contract ClientFundable is Ownable {
     
     
     
    ClientFund public clientFund;

     
     
     
    event SetClientFundEvent(ClientFund oldClientFund, ClientFund newClientFund);

     
     
     
     
     
    function setClientFund(ClientFund newClientFund) public
    onlyDeployer
    notNullAddress(address(newClientFund))
    notSameAddresses(address(newClientFund), address(clientFund))
    {
         
        ClientFund oldClientFund = clientFund;
        clientFund = newClientFund;

         
        emit SetClientFundEvent(oldClientFund, newClientFund);
    }

     
     
     
    modifier clientFundInitialized() {
        require(address(clientFund) != address(0), "Client fund not initialized [ClientFundable.sol:51]");
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

 

 
contract FraudChallenge is Ownable, Servable {
     
     
     
    string constant public ADD_SEIZED_WALLET_ACTION = "add_seized_wallet";
    string constant public ADD_DOUBLE_SPENDER_WALLET_ACTION = "add_double_spender_wallet";
    string constant public ADD_FRAUDULENT_ORDER_ACTION = "add_fraudulent_order";
    string constant public ADD_FRAUDULENT_TRADE_ACTION = "add_fraudulent_trade";
    string constant public ADD_FRAUDULENT_PAYMENT_ACTION = "add_fraudulent_payment";

     
     
     
    address[] public doubleSpenderWallets;
    mapping(address => bool) public doubleSpenderByWallet;

    bytes32[] public fraudulentOrderHashes;
    mapping(bytes32 => bool) public fraudulentByOrderHash;

    bytes32[] public fraudulentTradeHashes;
    mapping(bytes32 => bool) public fraudulentByTradeHash;

    bytes32[] public fraudulentPaymentHashes;
    mapping(bytes32 => bool) public fraudulentByPaymentHash;

     
     
     
    event AddDoubleSpenderWalletEvent(address wallet);
    event AddFraudulentOrderHashEvent(bytes32 hash);
    event AddFraudulentTradeHashEvent(bytes32 hash);
    event AddFraudulentPaymentHashEvent(bytes32 hash);

     
     
     
    constructor(address deployer) Ownable(deployer) public {
    }

     
     
     
     
     
     
    function isDoubleSpenderWallet(address wallet)
    public
    view
    returns (bool)
    {
        return doubleSpenderByWallet[wallet];
    }

     
     
    function doubleSpenderWalletsCount()
    public
    view
    returns (uint256)
    {
        return doubleSpenderWallets.length;
    }

     
     
    function addDoubleSpenderWallet(address wallet)
    public
    onlyEnabledServiceAction(ADD_DOUBLE_SPENDER_WALLET_ACTION) {
        if (!doubleSpenderByWallet[wallet]) {
            doubleSpenderWallets.push(wallet);
            doubleSpenderByWallet[wallet] = true;
            emit AddDoubleSpenderWalletEvent(wallet);
        }
    }

     
    function fraudulentOrderHashesCount()
    public
    view
    returns (uint256)
    {
        return fraudulentOrderHashes.length;
    }

     
     
    function isFraudulentOrderHash(bytes32 hash)
    public
    view returns (bool) {
        return fraudulentByOrderHash[hash];
    }

     
    function addFraudulentOrderHash(bytes32 hash)
    public
    onlyEnabledServiceAction(ADD_FRAUDULENT_ORDER_ACTION)
    {
        if (!fraudulentByOrderHash[hash]) {
            fraudulentByOrderHash[hash] = true;
            fraudulentOrderHashes.push(hash);
            emit AddFraudulentOrderHashEvent(hash);
        }
    }

     
    function fraudulentTradeHashesCount()
    public
    view
    returns (uint256)
    {
        return fraudulentTradeHashes.length;
    }

     
     
     
    function isFraudulentTradeHash(bytes32 hash)
    public
    view
    returns (bool)
    {
        return fraudulentByTradeHash[hash];
    }

     
    function addFraudulentTradeHash(bytes32 hash)
    public
    onlyEnabledServiceAction(ADD_FRAUDULENT_TRADE_ACTION)
    {
        if (!fraudulentByTradeHash[hash]) {
            fraudulentByTradeHash[hash] = true;
            fraudulentTradeHashes.push(hash);
            emit AddFraudulentTradeHashEvent(hash);
        }
    }

     
    function fraudulentPaymentHashesCount()
    public
    view
    returns (uint256)
    {
        return fraudulentPaymentHashes.length;
    }

     
     
     
    function isFraudulentPaymentHash(bytes32 hash)
    public
    view
    returns (bool)
    {
        return fraudulentByPaymentHash[hash];
    }

     
    function addFraudulentPaymentHash(bytes32 hash)
    public
    onlyEnabledServiceAction(ADD_FRAUDULENT_PAYMENT_ACTION)
    {
        if (!fraudulentByPaymentHash[hash]) {
            fraudulentByPaymentHash[hash] = true;
            fraudulentPaymentHashes.push(hash);
            emit AddFraudulentPaymentHashEvent(hash);
        }
    }
}

 

 
contract FraudChallengable is Ownable {
     
     
     
    FraudChallenge public fraudChallenge;

     
     
     
    event SetFraudChallengeEvent(FraudChallenge oldFraudChallenge, FraudChallenge newFraudChallenge);

     
     
     
     
     
    function setFraudChallenge(FraudChallenge newFraudChallenge)
    public
    onlyDeployer
    notNullAddress(address(newFraudChallenge))
    notSameAddresses(address(newFraudChallenge), address(fraudChallenge))
    {
         
        FraudChallenge oldFraudChallenge = fraudChallenge;
        fraudChallenge = newFraudChallenge;

         
        emit SetFraudChallengeEvent(oldFraudChallenge, newFraudChallenge);
    }

     
     
     
    modifier fraudChallengeInitialized() {
        require(address(fraudChallenge) != address(0), "Fraud challenge not initialized [FraudChallengable.sol:52]");
        _;
    }
}

 

 
contract PartnerBenefactor is Ownable, Benefactor {
     
     
     
    constructor(address deployer) Ownable(deployer) Benefactor()
    public
    {
    }
}

 

 
contract PartnerBenefactorable is Ownable {
     
     
     
    PartnerBenefactor public partnerBenefactor;

     
     
     
    event SetPartnerBenefactorEvent(PartnerBenefactor oldPartnerBenefactor, PartnerBenefactor newPartnerBenefactor);

     
     
     
     
     
    function setPartnerBenefactor(PartnerBenefactor newPartnerBenefactor)
    public
    onlyDeployer
    notNullAddress(address(newPartnerBenefactor))
    notSameAddresses(address(newPartnerBenefactor), address(partnerBenefactor))
    {
         
        PartnerBenefactor oldPartnerBenefactor = partnerBenefactor;
        partnerBenefactor = newPartnerBenefactor;

         
        emit SetPartnerBenefactorEvent(oldPartnerBenefactor, newPartnerBenefactor);
    }

     
     
     
    modifier partnerBenefactorInitialized() {
        require(address(partnerBenefactor) != address(0), "Partner benefactor not initialized [PartnerBenefactorable.sol:52]");
        _;
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

 

 
library SettlementChallengeTypesLib {
     
     
     
    enum Status {Qualified, Disqualified}

    struct Proposal {
        address wallet;
        uint256 nonce;
        uint256 referenceBlockNumber;
        uint256 definitionBlockNumber;

        uint256 expirationTime;

         
        Status status;

         
        Amounts amounts;

         
        MonetaryTypesLib.Currency currency;

         
        Driip challenged;

         
        bool walletInitiated;

         
        bool terminated;

         
        Disqualification disqualification;
    }

    struct Amounts {
         
        int256 cumulativeTransfer;

         
        int256 stage;

         
        int256 targetBalance;
    }

    struct Driip {
         
        string kind;

         
        bytes32 hash;
    }

    struct Disqualification {
         
        address challenger;
        uint256 nonce;
        uint256 blockNumber;

         
        Driip candidate;
    }
}

 

 
contract DriipSettlementChallengeState is Ownable, Servable, Configurable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;

     
     
     
    string constant public INITIATE_PROPOSAL_ACTION = "initiate_proposal";
    string constant public TERMINATE_PROPOSAL_ACTION = "terminate_proposal";
    string constant public REMOVE_PROPOSAL_ACTION = "remove_proposal";
    string constant public DISQUALIFY_PROPOSAL_ACTION = "disqualify_proposal";
    string constant public QUALIFY_PROPOSAL_ACTION = "qualify_proposal";

     
     
     
    SettlementChallengeTypesLib.Proposal[] public proposals;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public proposalIndexByWalletCurrency;
    mapping(address => mapping(uint256 => mapping(address => mapping(uint256 => uint256)))) public proposalIndexByWalletNonceCurrency;

     
     
     
    event InitiateProposalEvent(address wallet, uint256 nonce, int256 cumulativeTransferAmount, int256 stageAmount,
        int256 targetBalanceAmount, MonetaryTypesLib.Currency currency, uint256 blockNumber, bool walletInitiated,
        bytes32 challengedHash, string challengedKind);
    event TerminateProposalEvent(address wallet, uint256 nonce, int256 cumulativeTransferAmount, int256 stageAmount,
        int256 targetBalanceAmount, MonetaryTypesLib.Currency currency, uint256 blockNumber, bool walletInitiated,
        bytes32 challengedHash, string challengedKind);
    event RemoveProposalEvent(address wallet, uint256 nonce, int256 cumulativeTransferAmount, int256 stageAmount,
        int256 targetBalanceAmount, MonetaryTypesLib.Currency currency, uint256 blockNumber, bool walletInitiated,
        bytes32 challengedHash, string challengedKind);
    event DisqualifyProposalEvent(address challengedWallet, uint256 challengedNonce, int256 cumulativeTransferAmount,
        int256 stageAmount, int256 targetBalanceAmount, MonetaryTypesLib.Currency currency, uint256 blockNumber,
        bool walletInitiated, address challengerWallet, uint256 candidateNonce, bytes32 candidateHash,
        string candidateKind);
    event QualifyProposalEvent(address challengedWallet, uint256 challengedNonce, int256 cumulativeTransferAmount,
        int256 stageAmount, int256 targetBalanceAmount, MonetaryTypesLib.Currency currency, uint256 blockNumber,
        bool walletInitiated, address challengerWallet, uint256 candidateNonce, bytes32 candidateHash,
        string candidateKind);

     
     
     
    constructor(address deployer) Ownable(deployer) public {
    }

     
     
     
     
     
    function proposalsCount()
    public
    view
    returns (uint256)
    {
        return proposals.length;
    }

     
     
     
     
     
     
     
     
     
     
     
    function initiateProposal(address wallet, uint256 nonce, int256 cumulativeTransferAmount, int256 stageAmount,
        int256 targetBalanceAmount, MonetaryTypesLib.Currency memory currency, uint256 blockNumber, bool walletInitiated,
        bytes32 challengedHash, string memory challengedKind)
    public
    onlyEnabledServiceAction(INITIATE_PROPOSAL_ACTION)
    {
         
        _initiateProposal(
            wallet, nonce, cumulativeTransferAmount, stageAmount, targetBalanceAmount,
            currency, blockNumber, walletInitiated, challengedHash, challengedKind
        );

         
        emit InitiateProposalEvent(
            wallet, nonce, cumulativeTransferAmount, stageAmount, targetBalanceAmount, currency,
            blockNumber, walletInitiated, challengedHash, challengedKind
        );
    }

     
     
     
    function terminateProposal(address wallet, MonetaryTypesLib.Currency memory currency, bool clearNonce)
    public
    onlyEnabledServiceAction(TERMINATE_PROPOSAL_ACTION)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];

         
        if (0 == index)
            return;

         
        if (clearNonce)
            proposalIndexByWalletNonceCurrency[wallet][proposals[index - 1].nonce][currency.ct][currency.id] = 0;

         
        proposals[index - 1].terminated = true;

         
        emit TerminateProposalEvent(
            wallet, proposals[index - 1].nonce, proposals[index - 1].amounts.cumulativeTransfer,
            proposals[index - 1].amounts.stage, proposals[index - 1].amounts.targetBalance, currency,
            proposals[index - 1].referenceBlockNumber, proposals[index - 1].walletInitiated,
            proposals[index - 1].challenged.hash, proposals[index - 1].challenged.kind
        );
    }

     
     
     
     
     
    function terminateProposal(address wallet, MonetaryTypesLib.Currency memory currency, bool clearNonce,
        bool walletTerminated)
    public
    onlyEnabledServiceAction(TERMINATE_PROPOSAL_ACTION)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];

         
        if (0 == index)
            return;

         
        require(walletTerminated == proposals[index - 1].walletInitiated, "Wallet initiation and termination mismatch [DriipSettlementChallengeState.sol:163]");

         
        if (clearNonce)
            proposalIndexByWalletNonceCurrency[wallet][proposals[index - 1].nonce][currency.ct][currency.id] = 0;

         
        proposals[index - 1].terminated = true;

         
        emit TerminateProposalEvent(
            wallet, proposals[index - 1].nonce, proposals[index - 1].amounts.cumulativeTransfer,
            proposals[index - 1].amounts.stage, proposals[index - 1].amounts.targetBalance, currency,
            proposals[index - 1].referenceBlockNumber, proposals[index - 1].walletInitiated,
            proposals[index - 1].challenged.hash, proposals[index - 1].challenged.kind
        );
    }

     
     
     
    function removeProposal(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    onlyEnabledServiceAction(REMOVE_PROPOSAL_ACTION)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];

         
        if (0 == index)
            return;

         
        emit RemoveProposalEvent(
            wallet, proposals[index - 1].nonce, proposals[index - 1].amounts.cumulativeTransfer,
            proposals[index - 1].amounts.stage, proposals[index - 1].amounts.targetBalance, currency,
            proposals[index - 1].referenceBlockNumber, proposals[index - 1].walletInitiated,
            proposals[index - 1].challenged.hash, proposals[index - 1].challenged.kind
        );

         
        _removeProposal(index);
    }

     
     
     
     
    function removeProposal(address wallet, MonetaryTypesLib.Currency memory currency, bool walletTerminated)
    public
    onlyEnabledServiceAction(REMOVE_PROPOSAL_ACTION)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];

         
        if (0 == index)
            return;

         
        require(walletTerminated == proposals[index - 1].walletInitiated, "Wallet initiation and termination mismatch [DriipSettlementChallengeState.sol:223]");

         
        emit RemoveProposalEvent(
            wallet, proposals[index - 1].nonce, proposals[index - 1].amounts.cumulativeTransfer,
            proposals[index - 1].amounts.stage, proposals[index - 1].amounts.targetBalance, currency,
            proposals[index - 1].referenceBlockNumber, proposals[index - 1].walletInitiated,
            proposals[index - 1].challenged.hash, proposals[index - 1].challenged.kind
        );

         
        _removeProposal(index);
    }

     
     
     
     
     
     
     
     
     
    function disqualifyProposal(address challengedWallet, MonetaryTypesLib.Currency memory currency, address challengerWallet,
        uint256 blockNumber, uint256 candidateNonce, bytes32 candidateHash, string memory candidateKind)
    public
    onlyEnabledServiceAction(DISQUALIFY_PROPOSAL_ACTION)
    {
         
        uint256 index = proposalIndexByWalletCurrency[challengedWallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:253]");

         
        proposals[index - 1].status = SettlementChallengeTypesLib.Status.Disqualified;
        proposals[index - 1].expirationTime = block.timestamp.add(configuration.settlementChallengeTimeout());
        proposals[index - 1].disqualification.challenger = challengerWallet;
        proposals[index - 1].disqualification.nonce = candidateNonce;
        proposals[index - 1].disqualification.blockNumber = blockNumber;
        proposals[index - 1].disqualification.candidate.hash = candidateHash;
        proposals[index - 1].disqualification.candidate.kind = candidateKind;

         
        emit DisqualifyProposalEvent(
            challengedWallet, proposals[index - 1].nonce, proposals[index - 1].amounts.cumulativeTransfer,
            proposals[index - 1].amounts.stage, proposals[index - 1].amounts.targetBalance,
            currency, proposals[index - 1].referenceBlockNumber, proposals[index - 1].walletInitiated,
            challengerWallet, candidateNonce, candidateHash, candidateKind
        );
    }

     
     
     
    function qualifyProposal(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    onlyEnabledServiceAction(QUALIFY_PROPOSAL_ACTION)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:282]");

         
        emit QualifyProposalEvent(
            wallet, proposals[index - 1].nonce, proposals[index - 1].amounts.cumulativeTransfer,
            proposals[index - 1].amounts.stage, proposals[index - 1].amounts.targetBalance, currency,
            proposals[index - 1].referenceBlockNumber, proposals[index - 1].walletInitiated,
            proposals[index - 1].disqualification.challenger,
            proposals[index - 1].disqualification.nonce,
            proposals[index - 1].disqualification.candidate.hash,
            proposals[index - 1].disqualification.candidate.kind
        );

         
        proposals[index - 1].status = SettlementChallengeTypesLib.Status.Qualified;
        proposals[index - 1].expirationTime = block.timestamp.add(configuration.settlementChallengeTimeout());
        delete proposals[index - 1].disqualification;
    }

     
     
     
     
     
     
    function hasProposal(address wallet, uint256 nonce, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bool)
    {
         
        return 0 != proposalIndexByWalletNonceCurrency[wallet][nonce][currency.ct][currency.id];
    }

     
     
     
     
    function hasProposal(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bool)
    {
         
        return 0 != proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
    }

     
     
     
     
    function hasProposalTerminated(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bool)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:340]");
        return proposals[index - 1].terminated;
    }

     
     
     
     
    function hasProposalExpired(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bool)
    {
         
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:355]");
        return block.timestamp >= proposals[index - 1].expirationTime;
    }

     
     
     
     
    function proposalNonce(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:369]");
        return proposals[index - 1].nonce;
    }

     
     
     
     
    function proposalReferenceBlockNumber(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:383]");
        return proposals[index - 1].referenceBlockNumber;
    }

     
     
     
     
    function proposalDefinitionBlockNumber(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:397]");
        return proposals[index - 1].definitionBlockNumber;
    }

     
     
     
     
    function proposalExpirationTime(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:411]");
        return proposals[index - 1].expirationTime;
    }

     
     
     
     
    function proposalStatus(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (SettlementChallengeTypesLib.Status)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:425]");
        return proposals[index - 1].status;
    }

     
     
     
     
    function proposalCumulativeTransferAmount(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (int256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:439]");
        return proposals[index - 1].amounts.cumulativeTransfer;
    }

     
     
     
     
    function proposalStageAmount(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (int256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:453]");
        return proposals[index - 1].amounts.stage;
    }

     
     
     
     
    function proposalTargetBalanceAmount(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (int256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:467]");
        return proposals[index - 1].amounts.targetBalance;
    }

     
     
     
     
    function proposalChallengedHash(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bytes32)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:481]");
        return proposals[index - 1].challenged.hash;
    }

     
     
     
     
    function proposalChallengedKind(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (string memory)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:495]");
        return proposals[index - 1].challenged.kind;
    }

     
     
     
     
    function proposalWalletInitiated(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bool)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:509]");
        return proposals[index - 1].walletInitiated;
    }

     
     
     
     
    function proposalDisqualificationChallenger(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (address)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:523]");
        return proposals[index - 1].disqualification.challenger;
    }

     
     
     
     
    function proposalDisqualificationNonce(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:537]");
        return proposals[index - 1].disqualification.nonce;
    }

     
     
     
     
    function proposalDisqualificationBlockNumber(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (uint256)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:551]");
        return proposals[index - 1].disqualification.blockNumber;
    }

     
     
     
     
    function proposalDisqualificationCandidateHash(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (bytes32)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:565]");
        return proposals[index - 1].disqualification.candidate.hash;
    }

     
     
     
     
    function proposalDisqualificationCandidateKind(address wallet, MonetaryTypesLib.Currency memory currency)
    public
    view
    returns (string memory)
    {
        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];
        require(0 != index, "No proposal found for wallet and currency [DriipSettlementChallengeState.sol:579]");
        return proposals[index - 1].disqualification.candidate.kind;
    }

     
     
     
    function _initiateProposal(address wallet, uint256 nonce, int256 cumulativeTransferAmount, int256 stageAmount,
        int256 targetBalanceAmount, MonetaryTypesLib.Currency memory currency, uint256 referenceBlockNumber, bool walletInitiated,
        bytes32 challengedHash, string memory challengedKind)
    private
    {
         
        require(
            0 == proposalIndexByWalletNonceCurrency[wallet][nonce][currency.ct][currency.id],
            "Existing proposal found for wallet, nonce and currency [DriipSettlementChallengeState.sol:592]"
        );

         
        require(stageAmount.isPositiveInt256(), "Stage amount not positive [DriipSettlementChallengeState.sol:598]");
        require(targetBalanceAmount.isPositiveInt256(), "Target balance amount not positive [DriipSettlementChallengeState.sol:599]");

        uint256 index = proposalIndexByWalletCurrency[wallet][currency.ct][currency.id];

         
        if (0 == index) {
            index = ++(proposals.length);
            proposalIndexByWalletCurrency[wallet][currency.ct][currency.id] = index;
        }

         
        proposals[index - 1].wallet = wallet;
        proposals[index - 1].nonce = nonce;
        proposals[index - 1].referenceBlockNumber = referenceBlockNumber;
        proposals[index - 1].definitionBlockNumber = block.number;
        proposals[index - 1].expirationTime = block.timestamp.add(configuration.settlementChallengeTimeout());
        proposals[index - 1].status = SettlementChallengeTypesLib.Status.Qualified;
        proposals[index - 1].currency = currency;
        proposals[index - 1].amounts.cumulativeTransfer = cumulativeTransferAmount;
        proposals[index - 1].amounts.stage = stageAmount;
        proposals[index - 1].amounts.targetBalance = targetBalanceAmount;
        proposals[index - 1].walletInitiated = walletInitiated;
        proposals[index - 1].terminated = false;
        proposals[index - 1].challenged.hash = challengedHash;
        proposals[index - 1].challenged.kind = challengedKind;

         
        proposalIndexByWalletNonceCurrency[wallet][nonce][currency.ct][currency.id] = index;
    }

    function _removeProposal(uint256 index)
    private
    {
         
        proposalIndexByWalletCurrency[proposals[index - 1].wallet][proposals[index - 1].currency.ct][proposals[index - 1].currency.id] = 0;
        proposalIndexByWalletNonceCurrency[proposals[index - 1].wallet][proposals[index - 1].nonce][proposals[index - 1].currency.ct][proposals[index - 1].currency.id] = 0;
        if (index < proposals.length) {
            proposals[index - 1] = proposals[proposals.length - 1];
            proposalIndexByWalletCurrency[proposals[index - 1].wallet][proposals[index - 1].currency.ct][proposals[index - 1].currency.id] = index;
            proposalIndexByWalletNonceCurrency[proposals[index - 1].wallet][proposals[index - 1].nonce][proposals[index - 1].currency.ct][proposals[index - 1].currency.id] = index;
        }
        proposals.length--;
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

 

 
library DriipSettlementTypesLib {
     
     
     
    enum SettlementRole {Origin, Target}

    struct SettlementParty {
        uint256 nonce;
        address wallet;
        bool done;
        uint256 doneBlockNumber;
    }

    struct Settlement {
        string settledKind;
        bytes32 settledHash;
        SettlementParty origin;
        SettlementParty target;
    }
}

 

 
contract DriipSettlementState is Ownable, Servable, CommunityVotable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;

     
     
     
    string constant public INIT_SETTLEMENT_ACTION = "init_settlement";
    string constant public SET_SETTLEMENT_ROLE_DONE_ACTION = "set_settlement_role_done";
    string constant public SET_MAX_NONCE_ACTION = "set_max_nonce";
    string constant public SET_FEE_TOTAL_ACTION = "set_fee_total";

     
     
     
    uint256 public maxDriipNonce;

    DriipSettlementTypesLib.Settlement[] public settlements;
    mapping(address => uint256[]) public walletSettlementIndices;
    mapping(address => mapping(uint256 => uint256)) public walletNonceSettlementIndex;
    mapping(address => mapping(address => mapping(uint256 => uint256))) public walletCurrencyMaxNonce;

    mapping(address => mapping(address => mapping(address => mapping(address => mapping(uint256 => MonetaryTypesLib.NoncedAmount))))) public totalFeesMap;

    bool public upgradesFrozen;

     
     
     
    event InitSettlementEvent(DriipSettlementTypesLib.Settlement settlement);
    event CompleteSettlementPartyEvent(address wallet, uint256 nonce, DriipSettlementTypesLib.SettlementRole settlementRole,
        bool done, uint256 doneBlockNumber);
    event SetMaxNonceByWalletAndCurrencyEvent(address wallet, MonetaryTypesLib.Currency currency,
        uint256 maxNonce);
    event SetMaxDriipNonceEvent(uint256 maxDriipNonce);
    event UpdateMaxDriipNonceFromCommunityVoteEvent(uint256 maxDriipNonce);
    event SetTotalFeeEvent(address wallet, Beneficiary beneficiary, address destination,
        MonetaryTypesLib.Currency currency, MonetaryTypesLib.NoncedAmount totalFee);
    event FreezeUpgradesEvent();
    event UpgradeSettlementEvent(DriipSettlementTypesLib.Settlement settlement);

     
     
     
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
        require(walletSettlementIndices[wallet].length > index, "Index out of bounds [DriipSettlementState.sol:107]");
        return settlements[walletSettlementIndices[wallet][index] - 1];
    }

     
     
     
     
    function settlementByWalletAndNonce(address wallet, uint256 nonce)
    public
    view
    returns (DriipSettlementTypesLib.Settlement memory)
    {
        require(0 != walletNonceSettlementIndex[wallet][nonce], "No settlement found for wallet and nonce [DriipSettlementState.sol:120]");
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

     
     
     
     
     
    function completeSettlementParty(address wallet, uint256 nonce,
        DriipSettlementTypesLib.SettlementRole settlementRole, bool done)
    public
    onlyEnabledServiceAction(SET_SETTLEMENT_ROLE_DONE_ACTION)
    {
         
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

         
        require(0 != index, "No settlement found for wallet and nonce [DriipSettlementState.sol:181]");

         
        DriipSettlementTypesLib.SettlementParty storage party =
        DriipSettlementTypesLib.SettlementRole.Origin == settlementRole ?
        settlements[index - 1].origin :
        settlements[index - 1].target;

         
        party.done = done;
        party.doneBlockNumber = done ? block.number : 0;

         
        emit CompleteSettlementPartyEvent(wallet, nonce, settlementRole, done, party.doneBlockNumber);
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
        settlements[index - 1].origin.done :
        settlements[index - 1].target.done
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

         
        require(wallet == settlementParty.wallet, "Wallet has wrong settlement role [DriipSettlementState.sol:246]");

         
        return settlementParty.done;
    }

     
     
     
     
    function settlementPartyDoneBlockNumber(address wallet, uint256 nonce)
    public
    view
    returns (uint256)
    {
         
        uint256 index = walletNonceSettlementIndex[wallet][nonce];

         
        require(0 != index, "No settlement found for wallet and nonce [DriipSettlementState.sol:265]");

         
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

         
        require(0 != index, "No settlement found for wallet and nonce [DriipSettlementState.sol:290]");

         
        DriipSettlementTypesLib.SettlementParty storage settlementParty =
        DriipSettlementTypesLib.SettlementRole.Origin == settlementRole ?
        settlements[index - 1].origin : settlements[index - 1].target;

         
        require(wallet == settlementParty.wallet, "Wallet has wrong settlement role [DriipSettlementState.sol:298]");

         
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
    onlyEnabledServiceAction(SET_FEE_TOTAL_ACTION)
    {
         
        totalFeesMap[wallet][address(beneficiary)][destination][currency.ct][currency.id] = _totalFee;

         
        emit SetTotalFeeEvent(wallet, beneficiary, destination, currency, _totalFee);
    }

     
     
    function freezeUpgrades()
    public
    onlyDeployer
    {
         
        upgradesFrozen = true;

         
        emit FreezeUpgradesEvent();
    }

     
    function upgradeSettlement(string memory settledKind, bytes32 settledHash,
        address originWallet, uint256 originNonce, bool originDone, uint256 originDoneBlockNumber,
        address targetWallet, uint256 targetNonce, bool targetDone, uint256 targetDoneBlockNumber)
    public
    onlyDeployer
    {
         
        require(!upgradesFrozen, "Upgrades have been frozen [DriipSettlementState.sol:413]");

         
        require(0 == walletNonceSettlementIndex[originWallet][originNonce], "Settlement exists for origin wallet and nonce [DriipSettlementState.sol:416]");
        require(0 == walletNonceSettlementIndex[targetWallet][targetNonce], "Settlement exists for target wallet and nonce [DriipSettlementState.sol:417]");

         
        settlements.length++;

         
        uint256 index = settlements.length - 1;

         
        settlements[index].settledKind = settledKind;
        settlements[index].settledHash = settledHash;
        settlements[index].origin.nonce = originNonce;
        settlements[index].origin.wallet = originWallet;
        settlements[index].origin.done = originDone;
        settlements[index].origin.doneBlockNumber = originDoneBlockNumber;
        settlements[index].target.nonce = targetNonce;
        settlements[index].target.wallet = targetWallet;
        settlements[index].target.done = targetDone;
        settlements[index].target.doneBlockNumber = targetDoneBlockNumber;

         
        emit UpgradeSettlementEvent(settlements[index]);

         
        index++;
        walletSettlementIndices[originWallet].push(index);
        walletSettlementIndices[targetWallet].push(index);
        walletNonceSettlementIndex[originWallet][originNonce] = index;
        walletNonceSettlementIndex[targetWallet][targetNonce] = index;
    }
}

 

 
contract DriipSettlementByPayment is Ownable, Configurable, Validatable, ClientFundable, CommunityVotable,
FraudChallengable, WalletLockable, PartnerBenefactorable {
    using SafeMathIntLib for int256;
    using SafeMathUintLib for uint256;

     
     
     
    DriipSettlementChallengeState public driipSettlementChallengeState;
    DriipSettlementState public driipSettlementState;
    RevenueFund public revenueFund;

     
     
     
    event SettlePaymentEvent(address wallet, PaymentTypesLib.Payment payment, string standard);
    event SettlePaymentByProxyEvent(address proxy, address wallet, PaymentTypesLib.Payment payment, string standard);
    event SetDriipSettlementChallengeStateEvent(DriipSettlementChallengeState oldDriipSettlementChallengeState,
        DriipSettlementChallengeState newDriipSettlementChallengeState);
    event SetDriipSettlementStateEvent(DriipSettlementState oldDriipSettlementState,
        DriipSettlementState newDriipSettlementState);
    event SetRevenueFundEvent(RevenueFund oldRevenueFund, RevenueFund newRevenueFund);
    event StageFeesEvent(address wallet, int256 deltaAmount, int256 cumulativeAmount,
        address currencyCt, uint256 currencyId);

     
     
     
    constructor(address deployer) Ownable(deployer) public {
    }

     
     
     
     
     
    function setDriipSettlementChallengeState(DriipSettlementChallengeState newDriipSettlementChallengeState)
    public
    onlyDeployer
    notNullAddress(address(newDriipSettlementChallengeState))
    {
        DriipSettlementChallengeState oldDriipSettlementChallengeState = driipSettlementChallengeState;
        driipSettlementChallengeState = newDriipSettlementChallengeState;
        emit SetDriipSettlementChallengeStateEvent(oldDriipSettlementChallengeState, driipSettlementChallengeState);
    }

     
     
    function setDriipSettlementState(DriipSettlementState newDriipSettlementState)
    public
    onlyDeployer
    notNullAddress(address(newDriipSettlementState))
    {
        DriipSettlementState oldDriipSettlementState = driipSettlementState;
        driipSettlementState = newDriipSettlementState;
        emit SetDriipSettlementStateEvent(oldDriipSettlementState, driipSettlementState);
    }

     
     
    function setRevenueFund(RevenueFund newRevenueFund)
    public
    onlyDeployer
    notNullAddress(address(newRevenueFund))
    {
        RevenueFund oldRevenueFund = revenueFund;
        revenueFund = newRevenueFund;
        emit SetRevenueFundEvent(oldRevenueFund, revenueFund);
    }

     
    function settlementsCount()
    public
    view
    returns (uint256)
    {
        return driipSettlementState.settlementsCount();
    }

     
     
     
    function settlementsCountByWallet(address wallet)
    public
    view
    returns (uint256)
    {
        return driipSettlementState.settlementsCountByWallet(wallet);
    }

     
     
     
     
    function settlementByWalletAndIndex(address wallet, uint256 index)
    public
    view
    returns (DriipSettlementTypesLib.Settlement memory)
    {
        return driipSettlementState.settlementByWalletAndIndex(wallet, index);
    }

     
     
     
     
    function settlementByWalletAndNonce(address wallet, uint256 nonce)
    public
    view
    returns (DriipSettlementTypesLib.Settlement memory)
    {
        return driipSettlementState.settlementByWalletAndNonce(wallet, nonce);
    }

     
     
     
    function settlePayment(PaymentTypesLib.Payment memory payment, string memory standard)
    public
    {
         
        _settlePayment(msg.sender, payment, standard);

         
        emit SettlePaymentEvent(msg.sender, payment, standard);
    }

     
     
     
     
    function settlePaymentByProxy(address wallet, PaymentTypesLib.Payment memory payment, string memory standard)
    public
    onlyOperator
    {
         
        _settlePayment(wallet, payment, standard);

         
        emit SettlePaymentByProxyEvent(msg.sender, wallet, payment, standard);
    }

     
     
     
    function _settlePayment(address wallet, PaymentTypesLib.Payment memory payment, string memory standard)
    private
    onlySealedPayment(payment)
    onlyPaymentParty(payment, wallet)
    {
        require(!fraudChallenge.isFraudulentPaymentHash(payment.seals.operator.hash), "Payment deemed fraudulent [DriipSettlementByPayment.sol:186]");
        require(!communityVote.isDoubleSpenderWallet(wallet), "Wallet deemed double spender [DriipSettlementByPayment.sol:187]");

         
        require(!walletLocker.isLocked(wallet), "Wallet found locked [DriipSettlementByPayment.sol:190]");

         
        require(payment.seals.operator.hash == driipSettlementChallengeState.proposalChallengedHash(
            wallet, payment.currency
        ), "Payment not challenged [DriipSettlementByPayment.sol:193]");

         
        (
        DriipSettlementTypesLib.SettlementRole settlementRole, uint256 nonce,
        NahmiiTypesLib.OriginFigure[] memory totalFees, int256 currentBalance
        ) = _getRoleProperties(payment, wallet);

         
        require(driipSettlementChallengeState.hasProposal(wallet, nonce, payment.currency), "No proposal found [DriipSettlementByPayment.sol:204]");

         
        require(!driipSettlementChallengeState.hasProposalTerminated(wallet, payment.currency), "Proposal found terminated [DriipSettlementByPayment.sol:207]");

         
        require(driipSettlementChallengeState.hasProposalExpired(wallet, payment.currency), "Proposal found not expired [DriipSettlementByPayment.sol:210]");

         
        require(SettlementChallengeTypesLib.Status.Qualified == driipSettlementChallengeState.proposalStatus(
            wallet, payment.currency
        ), "Proposal found not qualified [DriipSettlementByPayment.sol:213]");

         
        require(configuration.isOperationalModeNormal(), "Not normal operational mode [DriipSettlementByPayment.sol:218]");
        require(communityVote.isDataAvailable(), "Data not available [DriipSettlementByPayment.sol:219]");

         
        driipSettlementState.initSettlement(
            PaymentTypesLib.PAYMENT_KIND(), payment.seals.operator.hash,
            payment.sender.wallet, payment.sender.nonce,
            payment.recipient.wallet, payment.recipient.nonce
        );

         
        require(!driipSettlementState.isSettlementPartyDone(
            wallet, nonce, settlementRole
        ), "Settlement party already done [DriipSettlementByPayment.sol:229]");

         
        driipSettlementState.completeSettlementParty(
            wallet, nonce, settlementRole, true
        );

         
         
        if (driipSettlementState.maxNonceByWalletAndCurrency(wallet, payment.currency) < nonce) {
             
            driipSettlementState.setMaxNonceByWalletAndCurrency(wallet, payment.currency, nonce);

             
            clientFund.updateSettledBalance(
                wallet, currentBalance, payment.currency.ct, payment.currency.id, standard, payment.blockNumber
            );

             
            clientFund.stage(
                wallet, driipSettlementChallengeState.proposalStageAmount(wallet, payment.currency),
                payment.currency.ct, payment.currency.id, standard
            );

             
            if (address(0) != address(revenueFund))
                _stageFees(wallet, totalFees, revenueFund, nonce, standard);
        }

         
        driipSettlementChallengeState.terminateProposal(wallet, payment.currency, false);
    }

    function _getRoleProperties(PaymentTypesLib.Payment memory payment, address wallet)
    private
    view
    returns (
        DriipSettlementTypesLib.SettlementRole settlementRole, uint256 walletNonce,
        NahmiiTypesLib.OriginFigure[] memory totalFees, int256 currentBalance
    )
    {
        if (validator.isPaymentSender(payment, wallet)) {
            settlementRole = DriipSettlementTypesLib.SettlementRole.Origin;
            walletNonce = payment.sender.nonce;
            totalFees = payment.sender.fees.total;
            currentBalance = payment.sender.balances.current;

        } else {
            settlementRole = DriipSettlementTypesLib.SettlementRole.Target;
            walletNonce = payment.recipient.nonce;
            totalFees = payment.recipient.fees.total;
            currentBalance = payment.recipient.balances.current;
        }
    }

    function _stageFees(address wallet, NahmiiTypesLib.OriginFigure[] memory fees,
        Beneficiary protocolBeneficiary, uint256 nonce, string memory standard)
    private
    {
         
        for (uint256 i = 0; i < fees.length; i++) {
             
            Beneficiary beneficiary;
            if (0 == fees[i].originId)
                beneficiary = protocolBeneficiary;
            else if (
                0 < partnerBenefactor.registeredBeneficiariesCount() &&
                fees[i].originId <= partnerBenefactor.registeredBeneficiariesCount()
            )
                beneficiary = partnerBenefactor.beneficiaries(fees[i].originId - 1);

             
            if (address(0) == address(beneficiary))
                continue;

             
            address destination = address(fees[i].originId);

            if (driipSettlementState.totalFee(wallet, beneficiary, destination, fees[i].figure.currency).nonce < nonce) {
                 
                int256 deltaAmount = fees[i].figure.amount - driipSettlementState.totalFee(wallet, beneficiary, destination, fees[i].figure.currency).amount;

                 
                driipSettlementState.setTotalFee(wallet, beneficiary, destination, fees[i].figure.currency, MonetaryTypesLib.NoncedAmount(nonce, fees[i].figure.amount));

                 
                clientFund.transferToBeneficiary(
                    wallet, beneficiary, deltaAmount, fees[i].figure.currency.ct, fees[i].figure.currency.id, standard
                );

                 
                emit StageFeesEvent(
                    wallet, deltaAmount, fees[i].figure.amount, fees[i].figure.currency.ct, fees[i].figure.currency.id
                );
            }
        }
    }
}