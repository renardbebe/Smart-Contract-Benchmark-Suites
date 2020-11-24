 

pragma solidity ^0.4.24;

 
interface Module {

     
    function init(BaseWallet _wallet) external;

     
    function addModule(BaseWallet _wallet, Module _module) external;

     
    function recoverToken(address _token) external;
}

 
contract BaseModule is Module {

     
    ModuleRegistry internal registry;

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, bytes32 _name) public {
        registry = _registry;
        emit ModuleCreated(_name);
    }

     
    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }

     
    modifier onlyOwner(BaseWallet _wallet) {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be an owner for the wallet");
        _;
    }

     
    modifier strictOnlyOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }

     
    function init(BaseWallet _wallet) external onlyWallet(_wallet) {
        emit ModuleInitialised(_wallet);
    }

     
    function addModule(BaseWallet _wallet, Module _module) external strictOnlyOwner(_wallet) {
        require(registry.isRegisteredModule(_module), "BM: module is not registered");
        _wallet.authoriseModule(_module, true);
    }

     
    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(address(registry), total);
    }

     
    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }
}

 
contract RelayerModule is Module {

    uint256 constant internal BLOCKBOUND = 10000;

    mapping (address => RelayerConfig) public relayer; 

    struct RelayerConfig {
        uint256 nonce;
        mapping (bytes32 => bool) executedTx;
    }

    event TransactionExecuted(address indexed wallet, bool indexed success, bytes32 signedHash);

     
    modifier onlyExecute {
        require(msg.sender == address(this), "RM: must be called via execute()");
        _;
    }

     

     
    function getRequiredSignatures(BaseWallet _wallet, bytes _data) internal view returns (uint256);

     
    function validateSignatures(BaseWallet _wallet, bytes _data, bytes32 _signHash, bytes _signatures) internal view returns (bool);

     

     
    function execute(
        BaseWallet _wallet,
        bytes _data, 
        uint256 _nonce, 
        bytes _signatures, 
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        external
        returns (bool success)
    {
        uint startGas = gasleft();
        bytes32 signHash = getSignHash(address(this), _wallet, 0, _data, _nonce, _gasPrice, _gasLimit);
        require(checkAndUpdateUniqueness(_wallet, _nonce, signHash), "RM: Duplicate request");
        require(verifyData(address(_wallet), _data), "RM: the wallet authorized is different then the target of the relayed data");
        uint256 requiredSignatures = getRequiredSignatures(_wallet, _data);
        if((requiredSignatures * 65) == _signatures.length) {
            if(verifyRefund(_wallet, _gasLimit, _gasPrice, requiredSignatures)) {
                if(requiredSignatures == 0 || validateSignatures(_wallet, _data, signHash, _signatures)) {
                     
                    success = address(this).call(_data);
                    refund(_wallet, startGas - gasleft(), _gasPrice, _gasLimit, requiredSignatures, msg.sender);
                }
            }
        }
        emit TransactionExecuted(_wallet, success, signHash); 
    }

     
    function getNonce(BaseWallet _wallet) external view returns (uint256 nonce) {
        return relayer[_wallet].nonce;
    }

     
    function getSignHash(
        address _from,
        address _to, 
        uint256 _value, 
        bytes _data, 
        uint256 _nonce,
        uint256 _gasPrice,
        uint256 _gasLimit
    ) 
        internal 
        pure
        returns (bytes32) 
    {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                keccak256(abi.encodePacked(byte(0x19), byte(0), _from, _to, _value, _data, _nonce, _gasPrice, _gasLimit))
        ));
    }

     
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        if(relayer[_wallet].executedTx[_signHash] == true) {
            return false;
        }
        relayer[_wallet].executedTx[_signHash] = true;
        return true;
    }

     
    function checkAndUpdateNonce(BaseWallet _wallet, uint256 _nonce) internal returns (bool) {
        if(_nonce <= relayer[_wallet].nonce) {
            return false;
        }   
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if(nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[_wallet].nonce = _nonce;
        return true;    
    }

     
    function recoverSigner(bytes32 _signedHash, bytes _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
         
         
         
         
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28); 
        return ecrecover(_signedHash, v, r, s);
    }

     
    function refund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _gasLimit, uint _signatures, address _relayer) internal {
        uint256 amount = 29292 + _gasUsed;  
         
        if(_gasPrice > 0 && _signatures > 1 && amount <= _gasLimit) {
            if(_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            }
            else {
                amount = amount * _gasPrice;
            }
            _wallet.invoke(_relayer, amount, "");
        }
    }

     
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0 
            && _signatures > 1 
            && (address(_wallet).balance < _gasUsed * _gasPrice || _wallet.authorised(this) == false)) {
            return false;
        }
        return true;
    }

     
    function verifyData(address _wallet, bytes _data) private pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet;
         
        assembly {
             
            dataWallet := mload(add(_data, 0x24))
        }
        return dataWallet == _wallet;
    }

     
    function functionPrefix(bytes _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
         
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
}

 
contract LimitManager is BaseModule {

     
    uint128 constant internal LIMIT_DISABLED = uint128(-1);  

    using SafeMath for uint256;

    struct LimitManagerConfig {
         
        Limit limit;
         
        DailySpent dailySpent;
    } 

    struct Limit {
         
        uint128 current;
         
        uint128 pending;
         
        uint64 changeAfter;
    }

    struct DailySpent {
         
        uint128 alreadySpent;
         
        uint64 periodEnd;
    }

     
    mapping (address => LimitManagerConfig) internal limits;
     
    uint256 public defaultLimit;

     

    event LimitChanged(address indexed wallet, uint indexed newLimit, uint64 indexed startAfter);

     

    constructor(uint256 _defaultLimit) public {
        defaultLimit = _defaultLimit;
    }

     

     
    function init(BaseWallet _wallet) external onlyWallet(_wallet) {
        Limit storage limit = limits[_wallet].limit;
        if(limit.current == 0 && limit.changeAfter == 0) {
            limit.current = uint128(defaultLimit);
        }
    }

     
    function changeLimit(BaseWallet _wallet, uint256 _newLimit, uint256 _securityPeriod) internal {
        Limit storage limit = limits[_wallet].limit;
         
        uint128 currentLimit = (limit.changeAfter > 0 && limit.changeAfter < now) ? limit.pending : limit.current;
        limit.current = currentLimit;
        limit.pending = uint128(_newLimit);
         
        limit.changeAfter = uint64(now.add(_securityPeriod));
         
        emit LimitChanged(_wallet, _newLimit, uint64(now.add(_securityPeriod)));
    }

     

     
    function getCurrentLimit(BaseWallet _wallet) public view returns (uint256 _currentLimit) {
        Limit storage limit = limits[_wallet].limit;
        _currentLimit = uint256(currentLimit(limit.current, limit.pending, limit.changeAfter));
    }

     
    function getPendingLimit(BaseWallet _wallet) external view returns (uint256 _pendingLimit, uint64 _changeAfter) {
        Limit storage limit = limits[_wallet].limit;
         
        return ((now < limit.changeAfter)? (uint256(limit.pending), limit.changeAfter) : (0,0));
    }

     
    function getDailyUnspent(BaseWallet _wallet) external view returns (uint256 _unspent, uint64 _periodEnd) {
        uint256 globalLimit = getCurrentLimit(_wallet);
        DailySpent storage expense = limits[_wallet].dailySpent;
         
        if(now > expense.periodEnd) {
            _unspent = globalLimit;
            _periodEnd = uint64(now + 24 hours);
        }
        else {
            _unspent = globalLimit - expense.alreadySpent;
            _periodEnd = expense.periodEnd;
        }
    }

     
    function checkAndUpdateDailySpent(BaseWallet _wallet, uint _amount) internal returns (bool) {
        Limit storage limit = limits[_wallet].limit;
        uint128 current = currentLimit(limit.current, limit.pending, limit.changeAfter);
        if(isWithinDailyLimit(_wallet, current, _amount)) {
            updateDailySpent(_wallet, current, _amount);
            return true;
        }
        return false;
    }

     
    function updateDailySpent(BaseWallet _wallet, uint128 _limit, uint _amount) internal {
        if(_limit != LIMIT_DISABLED) {
            DailySpent storage expense = limits[_wallet].dailySpent;
            if (expense.periodEnd < now) {
                expense.periodEnd = uint64(now + 24 hours);
                expense.alreadySpent = uint128(_amount);
            }
            else {
                expense.alreadySpent += uint128(_amount);
            }
        }
    }

     
    function isWithinDailyLimit(BaseWallet _wallet, uint _limit, uint _amount) internal view returns (bool)  {
        DailySpent storage expense = limits[_wallet].dailySpent;
        if(_limit == LIMIT_DISABLED) {
            return true;
        }
        else if (expense.periodEnd < now) {
            return (_amount <= _limit);
        } else {
            return (expense.alreadySpent + _amount <= _limit && expense.alreadySpent + _amount >= expense.alreadySpent);
        }
    }

     
    function currentLimit(uint128 _current, uint128 _pending, uint64 _changeAfter) internal view returns (uint128) {
        if(_changeAfter > 0 && _changeAfter < now) {
            return _pending;
        }
        return _current;
    }
}

 
contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
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

     
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if(a % b == 0) {
            return c;
        }
        else {
            return c + 1;
        }
    }
}

 
contract Owned {

     
    address public owner;

    event OwnerChanged(address indexed _newOwner);

     
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

 
contract ModuleRegistry is Owned {

    mapping (address => Info) internal modules;
    mapping (address => Info) internal upgraders;

    event ModuleRegistered(address indexed module, bytes32 name);
    event ModuleDeRegistered(address module);
    event UpgraderRegistered(address indexed upgrader, bytes32 name);
    event UpgraderDeRegistered(address upgrader);

    struct Info {
        bool exists;
        bytes32 name;
    }

     
    function registerModule(address _module, bytes32 _name) external onlyOwner {
        require(!modules[_module].exists, "MR: module already exists");
        modules[_module] = Info({exists: true, name: _name});
        emit ModuleRegistered(_module, _name);
    }

     
    function deregisterModule(address _module) external onlyOwner {
        require(modules[_module].exists, "MR: module does not exists");
        delete modules[_module];
        emit ModuleDeRegistered(_module);
    }

         
    function registerUpgrader(address _upgrader, bytes32 _name) external onlyOwner {
        require(!upgraders[_upgrader].exists, "MR: upgrader already exists");
        upgraders[_upgrader] = Info({exists: true, name: _name});
        emit UpgraderRegistered(_upgrader, _name);
    }

     
    function deregisterUpgrader(address _upgrader) external onlyOwner {
        require(upgraders[_upgrader].exists, "MR: upgrader does not exists");
        delete upgraders[_upgrader];
        emit UpgraderDeRegistered(_upgrader);
    }

     
    function recoverToken(address _token) external onlyOwner {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(msg.sender, total);
    } 

     
    function moduleInfo(address _module) external view returns (bytes32) {
        return modules[_module].name;
    }

     
    function upgraderInfo(address _upgrader) external view returns (bytes32) {
        return upgraders[_upgrader].name;
    }

     
    function isRegisteredModule(address _module) external view returns (bool) {
        return modules[_module].exists;
    }

     
    function isRegisteredModule(address[] _modules) external view returns (bool) {
        for(uint i = 0; i < _modules.length; i++) {
            if (!modules[_modules[i]].exists) {
                return false;
            }
        }
        return true;
    }  

     
    function isRegisteredUpgrader(address _upgrader) external view returns (bool) {
        return upgraders[_upgrader].exists;
    } 
}

 
contract BaseWallet {

     
    address public implementation;
     
    address public owner;
     
    mapping (address => bool) public authorised;
     
    mapping (bytes4 => address) public enabled;
     
    uint public modules;
    
    event AuthorisedModule(address indexed module, bool value);
    event EnabledStaticCall(address indexed module, bytes4 indexed method);
    event Invoked(address indexed module, address indexed target, uint indexed value, bytes data);
    event Received(uint indexed value, address indexed sender, bytes data);
    event OwnerChanged(address owner);
    
     
    modifier moduleOnly {
        require(authorised[msg.sender], "BW: msg.sender not an authorized module");
        _;
    }

     
    function init(address _owner, address[] _modules) external {
        require(owner == address(0) && modules == 0, "BW: wallet already initialised");
        require(_modules.length > 0, "BW: construction requires at least 1 module");
        owner = _owner;
        modules = _modules.length;
        for(uint256 i = 0; i < _modules.length; i++) {
            require(authorised[_modules[i]] == false, "BW: module is already added");
            authorised[_modules[i]] = true;
            Module(_modules[i]).init(this);
            emit AuthorisedModule(_modules[i], true);
        }
    }
    
     
    function authoriseModule(address _module, bool _value) external moduleOnly {
        if (authorised[_module] != _value) {
            if(_value == true) {
                modules += 1;
                authorised[_module] = true;
                Module(_module).init(this);
            }
            else {
                modules -= 1;
                require(modules > 0, "BW: wallet must have at least one module");
                delete authorised[_module];
            }
            emit AuthorisedModule(_module, _value);
        }
    }

     
    function enableStaticCall(address _module, bytes4 _method) external moduleOnly {
        require(authorised[_module], "BW: must be an authorised module for static call");
        enabled[_method] = _module;
        emit EnabledStaticCall(_module, _method);
    }

     
    function setOwner(address _newOwner) external moduleOnly {
        require(_newOwner != address(0), "BW: address cannot be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
    
     
    function invoke(address _target, uint _value, bytes _data) external moduleOnly {
         
        require(_target.call.value(_value)(_data), "BW: call to target failed");
        emit Invoked(msg.sender, _target, _value, _data);
    }

     
    function() public payable {
        if(msg.data.length > 0) { 
            address module = enabled[msg.sig];
            if(module == address(0)) {
                emit Received(msg.value, msg.sender, msg.data);
            } 
            else {
                require(authorised[module], "BW: must be an authorised module for static call");
                 
                assembly {
                    calldatacopy(0, 0, calldatasize())
                    let result := staticcall(gas, module, 0, calldatasize(), 0, 0)
                    returndatacopy(0, 0, returndatasize())
                    switch result 
                    case 0 {revert(0, returndatasize())} 
                    default {return (0, returndatasize())}
                }
            }
        }
    }
}

contract TokenPriceProvider {

    using SafeMath for uint256;

     
    address constant internal ETH_TOKEN_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
     
    address constant internal KYBER_NETWORK_ADDRESS = 0x818E6FECD516Ecc3849DAf6845e3EC868087B755;

    mapping(address => uint256) public cachedPrices;

    function syncPrice(ERC20 token) public {
        uint256 expectedRate;
        (expectedRate,) = kyberNetwork().getExpectedRate(token, ERC20(ETH_TOKEN_ADDRESS), 10000);
        cachedPrices[token] = expectedRate;
    }

     
     
     

    function syncPriceForTokenList(ERC20[] tokens) public {
        for(uint16 i = 0; i < tokens.length; i++) {
            syncPrice(tokens[i]);
        }
    }

     
    function getEtherValue(uint256 _amount, address _token) public view returns (uint256) {
        uint256 decimals = ERC20(_token).decimals();
        uint256 price = cachedPrices[_token];
        return price.mul(_amount).div(10**decimals);
    }

     
     
     

    function kyberNetwork() internal view returns (KyberNetwork) {
        return KyberNetwork(KYBER_NETWORK_ADDRESS);
    }
}

contract KyberNetwork {

    function getExpectedRate(
        ERC20 src,
        ERC20 dest,
        uint srcQty
    )
        public
        view
        returns (uint expectedRate, uint slippageRate);

    function trade(
        ERC20 src,
        uint srcAmount,
        ERC20 dest,
        address destAddress,
        uint maxDestAmount,
        uint minConversionRate,
        address walletId
    )
        public
        payable
        returns(uint);
}

 
contract Storage {

     
    modifier onlyModule(BaseWallet _wallet) {
        require(_wallet.authorised(msg.sender), "TS: must be an authorized module to call this method");
        _;
    }
}

 
contract GuardianStorage is Storage {

    struct GuardianStorageConfig {
         
        address[] guardians;
         
        mapping (address => GuardianInfo) info;
         
        uint256 lock; 
         
        address locker;
    }

    struct GuardianInfo {
        bool exists;
        uint128 index;
    }

     
    mapping (address => GuardianStorageConfig) internal configs;

     

     
    function addGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[_wallet];
        config.info[_guardian].exists = true;
        config.info[_guardian].index = uint128(config.guardians.push(_guardian) - 1);
    }

     
    function revokeGuardian(BaseWallet _wallet, address _guardian) external onlyModule(_wallet) {
        GuardianStorageConfig storage config = configs[_wallet];
        address lastGuardian = config.guardians[config.guardians.length - 1];
        if (_guardian != lastGuardian) {
            uint128 targetIndex = config.info[_guardian].index;
            config.guardians[targetIndex] = lastGuardian;
            config.info[lastGuardian].index = targetIndex;
        }
        config.guardians.length--;
        delete config.info[_guardian];
    }

     
    function guardianCount(BaseWallet _wallet) external view returns (uint256) {
        return configs[_wallet].guardians.length;
    }
    
     
    function getGuardians(BaseWallet _wallet) external view returns (address[]) {
        GuardianStorageConfig storage config = configs[_wallet];
        address[] memory guardians = new address[](config.guardians.length);
        for (uint256 i = 0; i < config.guardians.length; i++) {
            guardians[i] = config.guardians[i];
        }
        return guardians;
    }

     
    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool) {
        return configs[_wallet].info[_guardian].exists;
    }

     
    function setLock(BaseWallet _wallet, uint256 _releaseAfter) external onlyModule(_wallet) {
        configs[_wallet].lock = _releaseAfter;
        if(_releaseAfter != 0 && msg.sender != configs[_wallet].locker) {
            configs[_wallet].locker = msg.sender;
        }
    }

     
    function isLocked(BaseWallet _wallet) external view returns (bool) {
        return configs[_wallet].lock > now;
    }

     
    function getLock(BaseWallet _wallet) external view returns (uint256) {
        return configs[_wallet].lock;
    }

     
    function getLocker(BaseWallet _wallet) external view returns (address) {
        return configs[_wallet].locker;
    }
}

 
contract TransferStorage is Storage {

     
    mapping (address => mapping (address => uint256)) internal whitelist;

     

     
    function setWhitelist(BaseWallet _wallet, address _target, uint256 _value) external onlyModule(_wallet) {
        whitelist[_wallet][_target] = _value;
    }

     
    function getWhitelist(BaseWallet _wallet, address _target) external view returns (uint256) {
        return whitelist[_wallet][_target];
    }
}

 
contract TokenTransfer is BaseModule, RelayerModule, LimitManager {

    bytes32 constant NAME = "TokenTransfer";

    bytes4 constant internal EXECUTE_PENDING_PREFIX = bytes4(keccak256("executePendingTransfer(address,address,address,uint256,bytes,uint256)"));

    bytes constant internal EMPTY_BYTES = "";

    using SafeMath for uint256;

     
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
     
    uint128 constant internal LIMIT_DISABLED = uint128(-1);  

    struct TokenTransferConfig {
         
        mapping (bytes32 => uint256) pendingTransfers;
    }

     
    mapping (address => TokenTransferConfig) internal configs;

     
    uint256 public securityPeriod;
     
    uint256 public securityWindow;
     
    GuardianStorage public guardianStorage;
     
    TransferStorage public transferStorage;
     
    TokenPriceProvider public priceProvider;

     

    event Transfer(address indexed wallet, address indexed token, uint256 indexed amount, address to, bytes data);    
    event AddedToWhitelist(address indexed wallet, address indexed target, uint64 whitelistAfter);
    event RemovedFromWhitelist(address indexed wallet, address indexed target);
    event PendingTransferCreated(address indexed wallet, bytes32 indexed id, uint256 indexed executeAfter, address token, address to, uint256 amount, bytes data);
    event PendingTransferExecuted(address indexed wallet, bytes32 indexed id);
    event PendingTransferCanceled(address indexed wallet, bytes32 indexed id);

     

     
    modifier onlyOwnerOrModule(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender) || _wallet.authorised(msg.sender), "TT: must be wallet owner or module");
        _;
    }

     
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
         
        require(!guardianStorage.isLocked(_wallet), "TT: wallet must be unlocked");
        _;
    }

     

    constructor(
        ModuleRegistry _registry,
        TransferStorage _transferStorage, 
        GuardianStorage _guardianStorage, 
        address _priceProvider,
        uint256 _securityPeriod,
        uint256 _securityWindow, 
        uint256 _defaultLimit
    ) 
        BaseModule(_registry, NAME)
        LimitManager(_defaultLimit)
        public 
    {
        transferStorage = _transferStorage;
        guardianStorage = _guardianStorage;
        priceProvider = TokenPriceProvider(_priceProvider);
        securityPeriod = _securityPeriod;
        securityWindow = _securityWindow;
    }

     

     
    function transferToken(
        BaseWallet _wallet, 
        address _token, 
        address _to, 
        uint256 _amount, 
        bytes _data
    ) 
        external 
        onlyOwnerOrModule(_wallet) 
        onlyWhenUnlocked(_wallet)
    {
        if(isWhitelisted(_wallet, _to)) {
             
            if(_token == ETH_TOKEN) {
                transferETH(_wallet, _to, _amount, _data);
            }
             
            else {
                transferERC20(_wallet, _token, _to, _amount, _data);
            }
        }
        else {
            if(_token == ETH_TOKEN) {
                 
                if (checkAndUpdateDailySpent(_wallet, _amount)) {
                    transferETH(_wallet, _to, _amount, _data);
                }
                 
                else {
                    addPendingTransfer(_wallet, ETH_TOKEN, _to, _amount, _data); 
                }
            }
            else {
                uint256 etherAmount = priceProvider.getEtherValue(_amount, _token);
                 
                if (checkAndUpdateDailySpent(_wallet, etherAmount)) {
                    transferERC20(_wallet, _token, _to, _amount, _data);
                }
                 
                else {
                    addPendingTransfer(_wallet, _token, _to, _amount, _data); 
                }
            }
        }
    }

     
    function addToWhitelist(
        BaseWallet _wallet, 
        address _target
    ) 
        external 
        onlyOwner(_wallet) 
        onlyWhenUnlocked(_wallet)
    {
        require(!isWhitelisted(_wallet, _target), "TT: target already whitelisted");
         
        uint256 whitelistAfter = now.add(securityPeriod);
        transferStorage.setWhitelist(_wallet, _target, whitelistAfter);
        emit AddedToWhitelist(_wallet, _target, uint64(whitelistAfter));
    }

     
    function removeFromWhitelist(
        BaseWallet _wallet, 
        address _target
    ) 
        external 
        onlyOwner(_wallet) 
        onlyWhenUnlocked(_wallet)
    {
        require(isWhitelisted(_wallet, _target), "TT: target not whitelisted");
        transferStorage.setWhitelist(_wallet, _target, 0);
        emit RemovedFromWhitelist(_wallet, _target);
    }

     
    function executePendingTransfer(
        BaseWallet _wallet,
        address _token, 
        address _to, 
        uint _amount, 
        bytes _data,
        uint _block 
    ) 
        public 
        onlyWhenUnlocked(_wallet)
    {
        bytes32 id = keccak256(abi.encodePacked(_token, _to, _amount, _data, _block));
        uint executeAfter = configs[_wallet].pendingTransfers[id];
        uint executeBefore = executeAfter.add(securityWindow);
        require(executeAfter <= now && now <= executeBefore, "TT: outside of the execution window");
        removePendingTransfer(_wallet, id);
        if(_token == ETH_TOKEN) {
            transferETH(_wallet, _to, _amount, _data);
        }
        else {
            transferERC20(_wallet, _token, _to, _amount, _data);
        }
        emit PendingTransferExecuted(_wallet, id);
    }

     
    function cancelPendingTransfer(
        BaseWallet _wallet, 
        bytes32 _id
    ) 
        public 
        onlyOwner(_wallet) 
        onlyWhenUnlocked(_wallet) 
    {
        require(configs[_wallet].pendingTransfers[_id] > 0, "TT: unknown pending transfer");
        removePendingTransfer(_wallet, _id);
        emit PendingTransferCanceled(_wallet, _id);
    }

     
    function changeLimit(BaseWallet _wallet, uint256 _newLimit) public onlyOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, _newLimit, securityPeriod);
    }

     
    function disableLimit(BaseWallet _wallet) external onlyOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, LIMIT_DISABLED, securityPeriod);
    }

     
    function isWhitelisted(BaseWallet _wallet, address _target) public view returns (bool _isWhitelisted) {
        uint whitelistAfter = transferStorage.getWhitelist(_wallet, _target);
         
        return whitelistAfter > 0 && whitelistAfter < now;
    }

     
    function getPendingTransfer(BaseWallet _wallet, bytes32 _id) external view returns (uint64 _executeAfter) {
        _executeAfter = uint64(configs[_wallet].pendingTransfers[_id]);
    }

     

     
    function transferETH(BaseWallet _wallet, address _to, uint256 _value, bytes _data) internal {
        _wallet.invoke(_to, _value, EMPTY_BYTES);
        emit Transfer(_wallet, ETH_TOKEN, _value, _to, _data);
    }

     
    function transferERC20(BaseWallet _wallet, address _token, address _to, uint256 _value, bytes _data) internal {
        bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
        _wallet.invoke(_token, 0, methodData);
        emit Transfer(_wallet, _token, _value, _to, _data);
    }

     
    function addPendingTransfer(BaseWallet _wallet, address _token, address _to, uint _amount, bytes _data) internal returns (bytes32) {
        bytes32 id = keccak256(abi.encodePacked(_token, _to, _amount, _data, block.number));
        uint executeAfter = now.add(securityPeriod);
        configs[_wallet].pendingTransfers[id] = executeAfter;
        emit PendingTransferCreated(_wallet, id, executeAfter, _token, _to, _amount, _data);
    }

     
    function removePendingTransfer(BaseWallet _wallet, bytes32 _id) internal {
        delete configs[_wallet].pendingTransfers[_id];
    }

     

     
    function refund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _gasLimit, uint _signatures, address _relayer) internal {
         
        uint256 amount = 36616 + _gasUsed; 
        if(_gasPrice > 0 && _signatures > 0 && amount <= _gasLimit) {
            if(_gasPrice > tx.gasprice) {
                amount = amount * tx.gasprice;
            }
            else {
                amount = amount * _gasPrice;
            }
            updateDailySpent(_wallet, uint128(getCurrentLimit(_wallet)), amount);
            _wallet.invoke(_relayer, amount, "");
        }
    }

     
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0 && _signatures > 0 && (
            address(_wallet).balance < _gasUsed * _gasPrice 
            || isWithinDailyLimit(_wallet, getCurrentLimit(_wallet), _gasUsed * _gasPrice) == false
            || _wallet.authorised(this) == false
        ))
        {
            return false;
        }
        return true;
    }

     
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32 _signHash) internal returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function validateSignatures(BaseWallet _wallet, bytes _data, bytes32 _signHash, bytes _signatures) internal view returns (bool) {
        address signer = recoverSigner(_signHash, _signatures, 0);
        return isOwner(_wallet, signer);  
    }

    function getRequiredSignatures(BaseWallet _wallet, bytes _data) internal view returns (uint256) {
        bytes4 methodId = functionPrefix(_data);
        if (methodId == EXECUTE_PENDING_PREFIX) {
            return 0;
        }
        return 1;
    }
}