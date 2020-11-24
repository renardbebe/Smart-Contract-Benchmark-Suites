 

pragma solidity ^0.5.4;

 
contract ERC20 {
    function totalSupply() public view returns (uint);
    function decimals() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

 
interface Module {
    function init(BaseWallet _wallet) external;
    function addModule(BaseWallet _wallet, Module _module) external;
    function recoverToken(address _token) external;
}

 
contract BaseWallet {
    address public implementation;
    address public owner;
    mapping (address => bool) public authorised;
    mapping (bytes4 => address) public enabled;
    uint public modules;
    function init(address _owner, address[] calldata _modules) external;
    function authoriseModule(address _module, bool _value) external;
    function enableStaticCall(address _module, bytes4 _method) external;
    function setOwner(address _newOwner) external;
    function invoke(address _target, uint _value, bytes calldata _data) external returns (bytes memory _result);
    function() external payable;
}

 
contract ModuleRegistry {
    function registerModule(address _module, bytes32 _name) external;
    function deregisterModule(address _module) external;
    function registerUpgrader(address _upgrader, bytes32 _name) external;
    function deregisterUpgrader(address _upgrader) external;
    function recoverToken(address _token) external;
    function moduleInfo(address _module) external view returns (bytes32);
    function upgraderInfo(address _upgrader) external view returns (bytes32);
    function isRegisteredModule(address _module) external view returns (bool);
    function isRegisteredModule(address[] calldata _modules) external view returns (bool);
    function isRegisteredUpgrader(address _upgrader) external view returns (bool);
}

contract TokenPriceProvider {
    mapping(address => uint256) public cachedPrices;
    function getEtherValue(uint256 _amount, address _token) external view returns (uint256);
}

 
contract GuardianStorage {
    function addGuardian(BaseWallet _wallet, address _guardian) external;
    function revokeGuardian(BaseWallet _wallet, address _guardian) external;
    function guardianCount(BaseWallet _wallet) external view returns (uint256);
    function getGuardians(BaseWallet _wallet) external view returns (address[] memory);
    function isGuardian(BaseWallet _wallet, address _guardian) external view returns (bool);
    function setLock(BaseWallet _wallet, uint256 _releaseAfter) external;
    function isLocked(BaseWallet _wallet) external view returns (bool);
    function getLock(BaseWallet _wallet) external view returns (uint256);
    function getLocker(BaseWallet _wallet) external view returns (address);
}

 
contract TransferStorage {
    function setWhitelist(BaseWallet _wallet, address _target, uint256 _value) external;
    function getWhitelist(BaseWallet _wallet, address _target) external view returns (uint256);
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

 
contract BaseModule is Module {

     
    bytes constant internal EMPTY_BYTES = "";

     
    ModuleRegistry internal registry;
     
    GuardianStorage internal guardianStorage;

     
    modifier onlyWhenUnlocked(BaseWallet _wallet) {
         
        require(!guardianStorage.isLocked(_wallet), "BM: wallet must be unlocked");
        _;
    }

    event ModuleCreated(bytes32 name);
    event ModuleInitialised(address wallet);

    constructor(ModuleRegistry _registry, GuardianStorage _guardianStorage, bytes32 _name) public {
        registry = _registry;
        guardianStorage = _guardianStorage;
        emit ModuleCreated(_name);
    }

     
    modifier onlyWallet(BaseWallet _wallet) {
        require(msg.sender == address(_wallet), "BM: caller must be wallet");
        _;
    }

     
    modifier onlyWalletOwner(BaseWallet _wallet) {
        require(msg.sender == address(this) || isOwner(_wallet, msg.sender), "BM: must be an owner for the wallet");
        _;
    }

     
    modifier strictOnlyWalletOwner(BaseWallet _wallet) {
        require(isOwner(_wallet, msg.sender), "BM: msg.sender must be an owner for the wallet");
        _;
    }

     
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        emit ModuleInitialised(address(_wallet));
    }

     
    function addModule(BaseWallet _wallet, Module _module) external strictOnlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }

     
    function recoverToken(address _token) external {
        uint total = ERC20(_token).balanceOf(address(this));
        ERC20(_token).transfer(address(registry), total);
    }

     
    function isOwner(BaseWallet _wallet, address _addr) internal view returns (bool) {
        return _wallet.owner() == _addr;
    }

     
    function invokeWallet(address _wallet, address _to, uint256 _value, bytes memory _data) internal returns (bytes memory _res) {
        bool success;
         
        (success, _res) = _wallet.call(abi.encodeWithSignature("invoke(address,uint256,bytes)", _to, _value, _data));
        if(success && _res.length > 0) {  
            (_res) = abi.decode(_res, (bytes));
        } else if (_res.length > 0) {
             
            assembly {
                returndatacopy(0, 0, returndatasize)
                revert(0, returndatasize)
            }
        } else if(!success) {
            revert("BM: wallet invoke reverted");
        }
    }
}

 
contract RelayerModule is BaseModule {

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

     

     
    function getRequiredSignatures(BaseWallet _wallet, bytes memory _data) internal view returns (uint256);

     
    function validateSignatures(BaseWallet _wallet, bytes memory _data, bytes32 _signHash, bytes memory _signatures) internal view returns (bool);

     

     
    function execute(
        BaseWallet _wallet,
        bytes calldata _data,
        uint256 _nonce,
        bytes calldata _signatures,
        uint256 _gasPrice,
        uint256 _gasLimit
    )
        external
        returns (bool success)
    {
        uint startGas = gasleft();
        bytes32 signHash = getSignHash(address(this), address(_wallet), 0, _data, _nonce, _gasPrice, _gasLimit);
        require(checkAndUpdateUniqueness(_wallet, _nonce, signHash), "RM: Duplicate request");
        require(verifyData(address(_wallet), _data), "RM: the wallet authorized is different then the target of the relayed data");
        uint256 requiredSignatures = getRequiredSignatures(_wallet, _data);
        if((requiredSignatures * 65) == _signatures.length) {
            if(verifyRefund(_wallet, _gasLimit, _gasPrice, requiredSignatures)) {
                if(requiredSignatures == 0 || validateSignatures(_wallet, _data, signHash, _signatures)) {
                     
                    (success,) = address(this).call(_data);
                    refund(_wallet, startGas - gasleft(), _gasPrice, _gasLimit, requiredSignatures, msg.sender);
                }
            }
        }
        emit TransactionExecuted(address(_wallet), success, signHash);
    }

     
    function getNonce(BaseWallet _wallet) external view returns (uint256 nonce) {
        return relayer[address(_wallet)].nonce;
    }

     
    function getSignHash(
        address _from,
        address _to,
        uint256 _value,
        bytes memory _data,
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
        if(relayer[address(_wallet)].executedTx[_signHash] == true) {
            return false;
        }
        relayer[address(_wallet)].executedTx[_signHash] = true;
        return true;
    }

     
    function checkAndUpdateNonce(BaseWallet _wallet, uint256 _nonce) internal returns (bool) {
        if(_nonce <= relayer[address(_wallet)].nonce) {
            return false;
        }
        uint256 nonceBlock = (_nonce & 0xffffffffffffffffffffffffffffffff00000000000000000000000000000000) >> 128;
        if(nonceBlock > block.number + BLOCKBOUND) {
            return false;
        }
        relayer[address(_wallet)].nonce = _nonce;
        return true;
    }

     
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
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
            invokeWallet(address(_wallet), _relayer, amount, EMPTY_BYTES);
        }
    }

     
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0
            && _signatures > 1
            && (address(_wallet).balance < _gasUsed * _gasPrice || _wallet.authorised(address(this)) == false)) {
            return false;
        }
        return true;
    }

     
    function verifyData(address _wallet, bytes memory _data) private pure returns (bool) {
        require(_data.length >= 36, "RM: Invalid dataWallet");
        address dataWallet;
         
        assembly {
             
            dataWallet := mload(add(_data, 0x24))
        }
        return dataWallet == _wallet;
    }

     
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
         
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }
}

 
contract OnlyOwnerModule is BaseModule, RelayerModule {

     

    
    function isOnlyOwnerModule() external pure returns (bytes4) {
         
        return this.isOnlyOwnerModule.selector;
    }

     
    function addModule(BaseWallet _wallet, Module _module) external onlyWalletOwner(_wallet) {
        require(registry.isRegisteredModule(address(_module)), "BM: module is not registered");
        _wallet.authoriseModule(address(_module), true);
    }

     

     
    function checkAndUpdateUniqueness(BaseWallet _wallet, uint256 _nonce, bytes32  ) internal returns (bool) {
        return checkAndUpdateNonce(_wallet, _nonce);
    }

    function validateSignatures(
        BaseWallet _wallet,
        bytes memory  ,
        bytes32 _signHash,
        bytes memory _signatures
    )
        internal
        view
        returns (bool)
    {
        address signer = recoverSigner(_signHash, _signatures, 0);
        return isOwner(_wallet, signer);  
    }

    function getRequiredSignatures(BaseWallet  , bytes memory  ) internal view returns (uint256) {
        return 1;
    }
}

 
contract LimitManager is BaseModule {

     
    uint128 constant private LIMIT_DISABLED = uint128(-1);  

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

     

     
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {
        Limit storage limit = limits[address(_wallet)].limit;
        if(limit.current == 0 && limit.changeAfter == 0) {
            limit.current = uint128(defaultLimit);
        }
    }

     

     
    function changeLimit(BaseWallet _wallet, uint256 _newLimit, uint256 _securityPeriod) internal {
        Limit storage limit = limits[address(_wallet)].limit;
         
        uint128 current = (limit.changeAfter > 0 && limit.changeAfter < now) ? limit.pending : limit.current;
        limit.current = current;
        limit.pending = uint128(_newLimit);
         
        limit.changeAfter = uint64(now.add(_securityPeriod));
         
        emit LimitChanged(address(_wallet), _newLimit, uint64(now.add(_securityPeriod)));
    }

      
    function disableLimit(BaseWallet _wallet, uint256 _securityPeriod) internal {
        changeLimit(_wallet, LIMIT_DISABLED, _securityPeriod);
    }

     
    function getCurrentLimit(BaseWallet _wallet) public view returns (uint256 _currentLimit) {
        Limit storage limit = limits[address(_wallet)].limit;
        _currentLimit = uint256(currentLimit(limit.current, limit.pending, limit.changeAfter));
    }

     
    function isLimitDisabled(BaseWallet _wallet) public view returns (bool _limitDisabled) {
        uint256 currentLimit = getCurrentLimit(_wallet);
        _limitDisabled = currentLimit == LIMIT_DISABLED;
    }

     
    function getPendingLimit(BaseWallet _wallet) external view returns (uint256 _pendingLimit, uint64 _changeAfter) {
        Limit storage limit = limits[address(_wallet)].limit;
         
        return ((now < limit.changeAfter)? (uint256(limit.pending), limit.changeAfter) : (0,0));
    }

     
    function getDailyUnspent(BaseWallet _wallet) external view returns (uint256 _unspent, uint64 _periodEnd) {
        uint256 limit = getCurrentLimit(_wallet);
        DailySpent storage expense = limits[address(_wallet)].dailySpent;
         
        if(now > expense.periodEnd) {
            _unspent = limit;
             
            _periodEnd = uint64(now + 24 hours);
        }
        else {
            _periodEnd = expense.periodEnd;
            if(expense.alreadySpent < limit) {
                _unspent = limit - expense.alreadySpent;
            }
        }
    }

     
    function checkAndUpdateDailySpent(BaseWallet _wallet, uint _amount) internal returns (bool) {
        if(_amount == 0) return true;
        Limit storage limit = limits[address(_wallet)].limit;
        uint128 current = currentLimit(limit.current, limit.pending, limit.changeAfter);
        if(isWithinDailyLimit(_wallet, current, _amount)) {
            updateDailySpent(_wallet, current, _amount);
            return true;
        }
        return false;
    }

     
    function updateDailySpent(BaseWallet _wallet, uint128 _limit, uint _amount) internal {
        if(_limit != LIMIT_DISABLED) {
            DailySpent storage expense = limits[address(_wallet)].dailySpent;
             
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
        if(_limit == LIMIT_DISABLED) {
            return true;
        }
        DailySpent storage expense = limits[address(_wallet)].dailySpent;
         
        if (expense.periodEnd < now) {
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

 
contract BaseTransfer is BaseModule {

     
    address constant internal ETH_TOKEN = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     

    event Transfer(address indexed wallet, address indexed token, uint256 indexed amount, address to, bytes data);
    event Approved(address indexed wallet, address indexed token, uint256 amount, address spender);
    event CalledContract(address indexed wallet, address indexed to, uint256 amount, bytes data);

     

     
    function doTransfer(BaseWallet _wallet, address _token, address _to, uint256 _value, bytes memory _data) internal {
        if(_token == ETH_TOKEN) {
            invokeWallet(address(_wallet), _to, _value, EMPTY_BYTES);
        }
        else {
            bytes memory methodData = abi.encodeWithSignature("transfer(address,uint256)", _to, _value);
            invokeWallet(address(_wallet), _token, 0, methodData);
        }
        emit Transfer(address(_wallet), _token, _value, _to, _data);
    }

     
    function doApproveToken(BaseWallet _wallet, address _token, address _spender, uint256 _value) internal {
        bytes memory methodData = abi.encodeWithSignature("approve(address,uint256)", _spender, _value);
        invokeWallet(address(_wallet), _token, 0, methodData);
        emit Approved(address(_wallet), _token, _value, _spender);
    }

     
    function doCallContract(BaseWallet _wallet, address _contract, uint256 _value, bytes memory _data) internal {
        invokeWallet(address(_wallet), _contract, _value, _data);
        emit CalledContract(address(_wallet), _contract, _value, _data);
    }
}

 
contract TransferManager is BaseModule, RelayerModule, OnlyOwnerModule, BaseTransfer, LimitManager {

    bytes32 constant NAME = "TransferManager";

    bytes4 private constant ERC721_ISVALIDSIGNATURE_BYTES = bytes4(keccak256("isValidSignature(bytes,bytes)"));
    bytes4 private constant ERC721_ISVALIDSIGNATURE_BYTES32 = bytes4(keccak256("isValidSignature(bytes32,bytes)"));

    enum ActionType { Transfer }

    using SafeMath for uint256;

    struct TokenManagerConfig {
         
        mapping (bytes32 => uint256) pendingActions;
    }

     
    mapping (address => TokenManagerConfig) internal configs;

     
    uint256 public securityPeriod;
     
    uint256 public securityWindow;
     
    TransferStorage public transferStorage;
     
    TokenPriceProvider public priceProvider;
     
    LimitManager public oldLimitManager;

     

    event AddedToWhitelist(address indexed wallet, address indexed target, uint64 whitelistAfter);
    event RemovedFromWhitelist(address indexed wallet, address indexed target);
    event PendingTransferCreated(address indexed wallet, bytes32 indexed id, uint256 indexed executeAfter,
        address token, address to, uint256 amount, bytes data);
    event PendingTransferExecuted(address indexed wallet, bytes32 indexed id);
    event PendingTransferCanceled(address indexed wallet, bytes32 indexed id);

     

    constructor(
        ModuleRegistry _registry,
        TransferStorage _transferStorage,
        GuardianStorage _guardianStorage,
        address _priceProvider,
        uint256 _securityPeriod,
        uint256 _securityWindow,
        uint256 _defaultLimit,
        LimitManager _oldLimitManager
    )
        BaseModule(_registry, _guardianStorage, NAME)
        LimitManager(_defaultLimit)
        public
    {
        transferStorage = _transferStorage;
        priceProvider = TokenPriceProvider(_priceProvider);
        securityPeriod = _securityPeriod;
        securityWindow = _securityWindow;
        oldLimitManager = _oldLimitManager;
    }

     
    function init(BaseWallet _wallet) public onlyWallet(_wallet) {

         
        _wallet.enableStaticCall(address(this), ERC721_ISVALIDSIGNATURE_BYTES);
        _wallet.enableStaticCall(address(this), ERC721_ISVALIDSIGNATURE_BYTES32);

         
        if(address(oldLimitManager) == address(0)) {
            super.init(_wallet);
            return;
        }
         
        uint256 current = oldLimitManager.getCurrentLimit(_wallet);
        (uint256 pending, uint64 changeAfter) = oldLimitManager.getPendingLimit(_wallet);
         
        if(current == 0 && changeAfter == 0) {
            super.init(_wallet);
            return;
        }
         
        if(current == pending) {
            limits[address(_wallet)].limit.current = uint128(current);
        }
        else {
            limits[address(_wallet)].limit = Limit(uint128(current), uint128(pending), changeAfter);
        }
         
        (uint256 unspent, uint64 periodEnd) = oldLimitManager.getDailyUnspent(_wallet);
         
        if(periodEnd > now) {
            limits[address(_wallet)].dailySpent = DailySpent(uint128(current.sub(unspent)), periodEnd);
        }
    }

     

     
    function transferToken(
        BaseWallet _wallet,
        address _token,
        address _to,
        uint256 _amount,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        if(isWhitelisted(_wallet, _to)) {
             
            doTransfer(_wallet, _token, _to, _amount, _data);
        }
        else {
            uint256 etherAmount = (_token == ETH_TOKEN) ? _amount : priceProvider.getEtherValue(_amount, _token);
            if (checkAndUpdateDailySpent(_wallet, etherAmount)) {
                 
                doTransfer(_wallet, _token, _to, _amount, _data);
            }
            else {
                 
                (bytes32 id, uint256 executeAfter) = addPendingAction(ActionType.Transfer, _wallet, _token, _to, _amount, _data);
                emit PendingTransferCreated(address(_wallet), id, executeAfter, _token, _to, _amount, _data);
            }
        }
    }

     
    function approveToken(
        BaseWallet _wallet,
        address _token,
        address _spender,
        uint256 _amount
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        if(isWhitelisted(_wallet, _spender)) {
             
            doApproveToken(_wallet, _token, _spender, _amount);
        }
        else {
             
            uint256 currentAllowance = ERC20(_token).allowance(address(_wallet), _spender);
            if(_amount <= currentAllowance) {
                 
                doApproveToken(_wallet, _token, _spender, _amount);
            }
            else {
                 
                uint delta = _amount - currentAllowance;
                uint256 deltaInEth = priceProvider.getEtherValue(delta, _token);
                require(checkAndUpdateDailySpent(_wallet, deltaInEth), "TM: Approve above daily limit");
                 
                doApproveToken(_wallet, _token, _spender, _amount);
            }
        }
    }

     
    function callContract(
        BaseWallet _wallet,
        address _contract,
        uint256 _value,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
         
        authoriseContractCall(_wallet, _contract);

        if(isWhitelisted(_wallet, _contract)) {
             
            doCallContract(_wallet, _contract, _value, _data);
        }
        else {
            require(checkAndUpdateDailySpent(_wallet, _value), "TM: Call contract above daily limit");
             
            doCallContract(_wallet, _contract, _value, _data);
        }
    }

     
    function approveTokenAndCallContract(
        BaseWallet _wallet,
        address _token,
        address _contract,
        uint256 _amount,
        bytes calldata _data
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
         
        authoriseContractCall(_wallet, _contract);

        if(isWhitelisted(_wallet, _contract)) {
            doApproveToken(_wallet, _token, _contract, _amount);
            doCallContract(_wallet, _contract, 0, _data);
        }
        else {
             
            uint256 currentAllowance = ERC20(_token).allowance(address(_wallet), _contract);
            if(_amount <= currentAllowance) {
                 
                doCallContract(_wallet, _contract, 0, _data);
            }
            else {
                 
                uint delta = _amount - currentAllowance;
                uint256 deltaInEth = priceProvider.getEtherValue(delta, _token);
                require(checkAndUpdateDailySpent(_wallet, deltaInEth), "TM: Approve above daily limit");
                 
                doApproveToken(_wallet, _token, _contract, _amount);
                doCallContract(_wallet, _contract, 0, _data);
            }
        }
    }

     
    function addToWhitelist(
        BaseWallet _wallet,
        address _target
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(!isWhitelisted(_wallet, _target), "TT: target already whitelisted");
         
        uint256 whitelistAfter = now.add(securityPeriod);
        transferStorage.setWhitelist(_wallet, _target, whitelistAfter);
        emit AddedToWhitelist(address(_wallet), _target, uint64(whitelistAfter));
    }

     
    function removeFromWhitelist(
        BaseWallet _wallet,
        address _target
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(isWhitelisted(_wallet, _target), "TT: target not whitelisted");
        transferStorage.setWhitelist(_wallet, _target, 0);
        emit RemovedFromWhitelist(address(_wallet), _target);
    }

     
    function executePendingTransfer(
        BaseWallet _wallet,
        address _token,
        address _to,
        uint _amount,
        bytes calldata _data,
        uint _block
    )
        external
        onlyWhenUnlocked(_wallet)
    {
        bytes32 id = keccak256(abi.encodePacked(ActionType.Transfer, _token, _to, _amount, _data, _block));
        uint executeAfter = configs[address(_wallet)].pendingActions[id];
        require(executeAfter > 0, "TT: unknown pending transfer");
        uint executeBefore = executeAfter.add(securityWindow);
         
        require(executeAfter <= now && now <= executeBefore, "TT: transfer outside of the execution window");
        delete configs[address(_wallet)].pendingActions[id];
        doTransfer(_wallet, _token, _to, _amount, _data);
        emit PendingTransferExecuted(address(_wallet), id);
    }

    function cancelPendingTransfer(
        BaseWallet _wallet,
        bytes32 _id
    )
        external
        onlyWalletOwner(_wallet)
        onlyWhenUnlocked(_wallet)
    {
        require(configs[address(_wallet)].pendingActions[_id] > 0, "TT: unknown pending action");
        delete configs[address(_wallet)].pendingActions[_id];
        emit PendingTransferCanceled(address(_wallet), _id);
    }

     
    function changeLimit(BaseWallet _wallet, uint256 _newLimit) external onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        changeLimit(_wallet, _newLimit, securityPeriod);
    }

     
    function disableLimit(BaseWallet _wallet) external onlyWalletOwner(_wallet) onlyWhenUnlocked(_wallet) {
        disableLimit(_wallet, securityPeriod);
    }

     
    function isWhitelisted(BaseWallet _wallet, address _target) public view returns (bool _isWhitelisted) {
        uint whitelistAfter = transferStorage.getWhitelist(_wallet, _target);
         
        return whitelistAfter > 0 && whitelistAfter < now;
    }

     
    function getPendingTransfer(BaseWallet _wallet, bytes32 _id) external view returns (uint64 _executeAfter) {
        _executeAfter = uint64(configs[address(_wallet)].pendingActions[_id]);
    }

     
    function isValidSignature(bytes calldata _data, bytes calldata _signature) external view returns (bytes4) {
        bytes32 msgHash = keccak256(abi.encodePacked(_data));
        isValidSignature(msgHash, _signature);
        return ERC721_ISVALIDSIGNATURE_BYTES;
    }

     
    function isValidSignature(bytes32 _msgHash, bytes memory _signature) public view returns (bytes4) {
        require(_signature.length == 65, "TM: invalid signature length");
        address signer = recoverSigner(_msgHash, _signature, 0);
        require(isOwner(BaseWallet(msg.sender), signer), "TM: Invalid signer");
        return ERC721_ISVALIDSIGNATURE_BYTES32;
    }

     

     
    function addPendingAction(
        ActionType _action,
        BaseWallet _wallet,
        address _token,
        address _to,
        uint _amount,
        bytes memory _data
    )
        internal
        returns (bytes32 id, uint256 executeAfter)
    {
        id = keccak256(abi.encodePacked(_action, _token, _to, _amount, _data, block.number));
        require(configs[address(_wallet)].pendingActions[id] == 0, "TM: duplicate pending action");
         
        executeAfter = now.add(securityPeriod);
        configs[address(_wallet)].pendingActions[id] = executeAfter;
    }

     
    function authoriseContractCall(BaseWallet _wallet, address _contract) internal view {
        require(
            _contract != address(_wallet) &&  
            !_wallet.authorised(_contract) &&  
            (priceProvider.cachedPrices(_contract) == 0 || isLimitDisabled(_wallet)),  
            "TM: Forbidden contract");
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
            checkAndUpdateDailySpent(_wallet, amount);
            invokeWallet(address(_wallet), _relayer, amount, EMPTY_BYTES);
        }
    }

     
    function verifyRefund(BaseWallet _wallet, uint _gasUsed, uint _gasPrice, uint _signatures) internal view returns (bool) {
        if(_gasPrice > 0 && _signatures > 0 && (
            address(_wallet).balance < _gasUsed * _gasPrice ||
            isWithinDailyLimit(_wallet, getCurrentLimit(_wallet), _gasUsed * _gasPrice) == false ||
            _wallet.authorised(address(this)) == false
        ))
        {
            return false;
        }
        return true;
    }
}