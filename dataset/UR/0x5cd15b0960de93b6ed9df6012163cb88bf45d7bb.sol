 

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

 
contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
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

 
contract DappRegistry is Owned {

     
    mapping (address => mapping (bytes4 => bool)) internal authorised;

    event Registered(address indexed _contract, bytes4[] _methods);
    event Deregistered(address indexed _contract, bytes4[] _methods);

     
    function register(address _contract, bytes4[] _methods) external onlyOwner {
        for(uint i = 0; i < _methods.length; i++) {
            authorised[_contract][_methods[i]] = true;
        }
        emit Registered(_contract, _methods);
    }

     
    function deregister(address _contract, bytes4[] _methods) external onlyOwner {
        for(uint i = 0; i < _methods.length; i++) {
            authorised[_contract][_methods[i]] = false;
        }
        emit Deregistered(_contract, _methods);
    }

     
    function isRegistered(address _contract, bytes4 _method) external view returns (bool) {
        return authorised[_contract][_method];
    }  

     
    function isRegistered(address _contract, bytes4[] _methods) external view returns (bool) {
        for(uint i = 0; i < _methods.length; i++) {
            if (!authorised[_contract][_methods[i]]) {
                return false;
            }
        }
        return true;
    }  
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

 
contract DappStorage is Storage {

     
    mapping (address => mapping (address => mapping (address => mapping (bytes4 => bool)))) internal whitelistedMethods;
    
     

     
    function setMethodAuthorization(
        BaseWallet _wallet, 
        address _dapp, 
        address _contract, 
        bytes4[] _signatures, 
        bool _authorized
    ) 
        external 
        onlyModule(_wallet) 
    {
        for(uint i = 0; i < _signatures.length; i++) {
            whitelistedMethods[_wallet][_dapp][_contract][_signatures[i]] = _authorized;
        }
    }

     
    function getMethodAuthorization(BaseWallet _wallet, address _dapp, address _contract, bytes4 _signature) external view returns (bool) {
        return whitelistedMethods[_wallet][_dapp][_contract][_signature];
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

 
contract DappManager is BaseModule, RelayerModule, LimitManager {

    bytes32 constant NAME = "DappManager";

    bytes4 constant internal CONFIRM_AUTHORISATION_PREFIX = bytes4(keccak256("confirmAuthorizeCall(address,address,address,bytes4[])"));
    bytes4 constant internal CALL_CONTRACT_PREFIX = bytes4(keccak256("callContract(address,address,address,uint256,bytes)"));

     
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    using SafeMath for uint256;

     
    GuardianStorage public guardianStorage;
     
    DappStorage public dappStorage;
     
    DappRegistry public dappRegistry;
     
    uint256 public securityPeriod;
     
    uint256 public securityWindow;

    struct DappManagerConfig {
         
        mapping (bytes32 => uint256) pending;
    }

     
    mapping (address => DappManagerConfig) internal configs;

     
  
    event Transfer(address indexed wallet, address indexed token, uint256 indexed amount, address to, bytes data);    
    event ContractCallAuthorizationRequested(address indexed _wallet, address indexed _dapp, address indexed _contract, bytes4[] _signatures);
    event ContractCallAuthorizationCanceled(address indexed _wallet, address indexed _dapp, address indexed _contract, bytes4[] _signatures);
    event ContractCallAuthorized(address indexed _wallet, address indexed _dapp, address indexed _contract, bytes4[] _signatures);
    event ContractCallDeauthorized(address indexed _wallet, address indexed _dapp, address indexed _contract, bytes4[] _signatures);

     

     
    modifier onlyExecuteOrDapp(address _dapp) {
        require(msg.sender == address(this) || msg.sender == _dapp, "DM: must be called by dapp or via execute()");
        _;
    }

     
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
         
        require(!guardianStorage.isLocked(_wallet), "DM: wallet must be unlocked");
        _;
    }

     

    constructor(
        ModuleRegistry _registry,
        DappRegistry _dappRegistry,
        DappStorage _dappStorage, 
        GuardianStorage _guardianStorage,
        uint256 _securityPeriod,
        uint256 _securityWindow,
        uint256 _defaultLimit
    ) 
        BaseModule(_registry, NAME)
        LimitManager(_defaultLimit)
        public 
    {
        dappStorage = _dappStorage;
        guardianStorage = _guardianStorage;
        dappRegistry = _dappRegistry;
        securityPeriod = _securityPeriod;
        securityWindow = _securityWindow;
    }

     

     
    function callContract(
        BaseWallet _wallet,
        address _dapp,
        address _to, 
        uint256 _amount, 
        bytes _data
    ) 
        external 
        onlyExecuteOrDapp(_dapp)
        onlyWhenUnlocked(_wallet)
    {
        require(isAuthorizedCall(_wallet, _dapp, _to, _data), "DM: Contract call not authorized");
        require(checkAndUpdateDailySpent(_wallet, _amount), "DM: Dapp limit exceeded");
        doCall(_wallet, _to, _amount, _data);
    }

     
    function authorizeCall(
        BaseWallet _wallet, 
        address _dapp,
        address _contract,
        bytes4[] _signatures
    ) 
        external 
        onlyOwner(_wallet) 
        onlyWhenUnlocked(_wallet)
    {
        require(_contract != address(0), "DM: Contract address cannot be null");
        if(dappRegistry.isRegistered(_contract, _signatures)) {
             
            dappStorage.setMethodAuthorization(_wallet, _dapp, _contract, _signatures, true);
            emit ContractCallAuthorized(_wallet, _dapp, _contract, _signatures);
        }
        else {
            bytes32 id = keccak256(abi.encodePacked(address(_wallet), _dapp, _contract, _signatures, true));
            configs[_wallet].pending[id] = now + securityPeriod;
            emit ContractCallAuthorizationRequested(_wallet, _dapp, _contract, _signatures);
        }
    }

     
    function deauthorizeCall(
        BaseWallet _wallet, 
        address _dapp,
        address _contract,
        bytes4[] _signatures
    ) 
        external 
        onlyOwner(_wallet) 
        onlyWhenUnlocked(_wallet)
    {
        dappStorage.setMethodAuthorization(_wallet, _dapp, _contract, _signatures, false);
        emit ContractCallDeauthorized(_wallet, _dapp, _contract, _signatures);
    }

     
    function confirmAuthorizeCall(
        BaseWallet _wallet, 
        address _dapp,
        address _contract,
        bytes4[] _signatures
    ) 
        external 
        onlyWhenUnlocked(_wallet)
    {
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _dapp, _contract, _signatures, true));
        DappManagerConfig storage config = configs[_wallet];
        require(config.pending[id] > 0, "DM: No pending authorisation for the target dapp");
        require(config.pending[id] < now, "DM: Too early to confirm pending authorisation");
        require(now < config.pending[id] + securityWindow, "GM: Too late to confirm pending authorisation");
        dappStorage.setMethodAuthorization(_wallet, _dapp, _contract, _signatures, true);
        delete config.pending[id];
        emit ContractCallAuthorized(_wallet, _dapp, _contract, _signatures);
    }

     
    function cancelAuthorizeCall(
        BaseWallet _wallet, 
        address _dapp,
        address _contract,
        bytes4[] _signatures
    )
        public 
        onlyOwner(_wallet) 
        onlyWhenUnlocked(_wallet) 
    {
        bytes32 id = keccak256(abi.encodePacked(address(_wallet), _dapp, _contract, _signatures, true));
        DappManagerConfig storage config = configs[_wallet];
        require(config.pending[id] > 0, "DM: No pending authorisation for the target dapp");
        delete config.pending[id];
        emit ContractCallAuthorizationCanceled(_wallet, _dapp, _contract, _signatures);
    }

     
    function isAuthorizedCall(BaseWallet _wallet, address _dapp, address _to, bytes _data) public view returns (bool _isAuthorized) {
        if(_data.length >= 4) {
            return dappStorage.getMethodAuthorization(_wallet, _dapp, _to, functionPrefix(_data));
        }
         
        return dappStorage.getMethodAuthorization(_wallet, _dapp, _to, "");
    }

     
    function changeLimit(BaseWallet _wallet, uint256 _newLimit) public onlyOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, _newLimit, securityPeriod);
    }

     
    function disableLimit(BaseWallet _wallet) external onlyOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, LIMIT_DISABLED, securityPeriod);
    }

     

    function doCall(BaseWallet _wallet, address _to, uint256 _value, bytes _data) internal {
        _wallet.invoke(_to, _value, _data);
        emit Transfer(_wallet, ETH_TOKEN, _value, _to, _data);
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
        if(functionPrefix(_data) == CALL_CONTRACT_PREFIX) {
             
            if(_data.length < 68) {
                return false;
            }
            address dapp;
             
            assembly {
                 
                dapp := mload(add(_data, 0x44))
            }
            return dapp == signer;  
        } else {
            return isOwner(_wallet, signer);  
        }
    }

    function getRequiredSignatures(BaseWallet _wallet, bytes _data) internal view returns (uint256) {
        bytes4 methodId = functionPrefix(_data);
        if (methodId == CONFIRM_AUTHORISATION_PREFIX) {
            return 0;
        }
        return 1;
    }
}