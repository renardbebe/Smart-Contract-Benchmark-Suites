 

 
pragma solidity ^0.4.15;


interface AbstractENS {
    function owner(bytes32 _node) constant returns (address);
    function resolver(bytes32 _node) constant returns (address);
    function ttl(bytes32 _node) constant returns (uint64);
    function setOwner(bytes32 _node, address _owner);
    function setSubnodeOwner(bytes32 _node, bytes32 label, address _owner);
    function setResolver(bytes32 _node, address _resolver);
    function setTTL(bytes32 _node, uint64 _ttl);

     
    event NewOwner(bytes32 indexed _node, bytes32 indexed _label, address _owner);

     
    event Transfer(bytes32 indexed _node, address _owner);

     
    event NewResolver(bytes32 indexed _node, address _resolver);

     
    event NewTTL(bytes32 indexed _node, uint64 _ttl);
}

 
pragma solidity ^0.4.0;



 
contract PublicResolver {
    bytes4 constant INTERFACE_META_ID = 0x01ffc9a7;
    bytes4 constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 constant CONTENT_INTERFACE_ID = 0xd8389dc5;
    bytes4 constant NAME_INTERFACE_ID = 0x691f3431;
    bytes4 constant ABI_INTERFACE_ID = 0x2203ab56;
    bytes4 constant PUBKEY_INTERFACE_ID = 0xc8690233;
    bytes4 constant TEXT_INTERFACE_ID = 0x59d1d43c;

    event AddrChanged(bytes32 indexed node, address a);
    event ContentChanged(bytes32 indexed node, bytes32 hash);
    event NameChanged(bytes32 indexed node, string name);
    event ABIChanged(bytes32 indexed node, uint256 indexed contentType);
    event PubkeyChanged(bytes32 indexed node, bytes32 x, bytes32 y);
    event TextChanged(bytes32 indexed node, string indexed indexedKey, string key);

    struct PublicKey {
        bytes32 x;
        bytes32 y;
    }

    struct Record {
        address addr;
        bytes32 content;
        string name;
        PublicKey pubkey;
        mapping(string=>string) text;
        mapping(uint256=>bytes) abis;
    }

    AbstractENS ens;
    mapping(bytes32=>Record) records;

    modifier only_owner(bytes32 node) {
        if (ens.owner(node) != msg.sender) throw;
        _;
    }

     
    function PublicResolver(AbstractENS ensAddr) {
        ens = ensAddr;
    }

     
    function supportsInterface(bytes4 interfaceID) constant returns (bool) {
        return interfaceID == ADDR_INTERFACE_ID ||
               interfaceID == CONTENT_INTERFACE_ID ||
               interfaceID == NAME_INTERFACE_ID ||
               interfaceID == ABI_INTERFACE_ID ||
               interfaceID == PUBKEY_INTERFACE_ID ||
               interfaceID == TEXT_INTERFACE_ID ||
               interfaceID == INTERFACE_META_ID;
    }

     
    function addr(bytes32 node) constant returns (address ret) {
        ret = records[node].addr;
    }

     
    function setAddr(bytes32 node, address addr) only_owner(node) {
        records[node].addr = addr;
        AddrChanged(node, addr);
    }

     
    function content(bytes32 node) constant returns (bytes32 ret) {
        ret = records[node].content;
    }

     
    function setContent(bytes32 node, bytes32 hash) only_owner(node) {
        records[node].content = hash;
        ContentChanged(node, hash);
    }

     
    function name(bytes32 node) constant returns (string ret) {
        ret = records[node].name;
    }

     
    function setName(bytes32 node, string name) only_owner(node) {
        records[node].name = name;
        NameChanged(node, name);
    }

     
    function ABI(bytes32 node, uint256 contentTypes) constant returns (uint256 contentType, bytes data) {
        var record = records[node];
        for(contentType = 1; contentType <= contentTypes; contentType <<= 1) {
            if ((contentType & contentTypes) != 0 && record.abis[contentType].length > 0) {
                data = record.abis[contentType];
                return;
            }
        }
        contentType = 0;
    }

     
    function setABI(bytes32 node, uint256 contentType, bytes data) only_owner(node) {
         
        if (((contentType - 1) & contentType) != 0) throw;

        records[node].abis[contentType] = data;
        ABIChanged(node, contentType);
    }

     
    function pubkey(bytes32 node) constant returns (bytes32 x, bytes32 y) {
        return (records[node].pubkey.x, records[node].pubkey.y);
    }

     
    function setPubkey(bytes32 node, bytes32 x, bytes32 y) only_owner(node) {
        records[node].pubkey = PublicKey(x, y);
        PubkeyChanged(node, x, y);
    }

     
    function text(bytes32 node, string key) constant returns (string ret) {
        ret = records[node].text[key];
    }

     
    function setText(bytes32 node, string key, string value) only_owner(node) {
        records[node].text[key] = value;
        TextChanged(node, key, key);
    }
}

 
pragma solidity ^0.4.18;


contract ENSConstants {
    bytes32 constant public ENS_ROOT = bytes32(0);
    bytes32 constant public ETH_TLD_LABEL = keccak256("eth");
    bytes32 constant public ETH_TLD_NODE = keccak256(ENS_ROOT, ETH_TLD_LABEL);
    bytes32 constant public PUBLIC_RESOLVER_LABEL = keccak256("resolver");
    bytes32 constant public PUBLIC_RESOLVER_NODE = keccak256(ETH_TLD_NODE, PUBLIC_RESOLVER_LABEL);
}

 
pragma solidity ^0.4.18;


interface IACL {
    function initialize(address permissionsCreator) public;
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

 
pragma solidity ^0.4.18;



interface IKernel {
    event SetApp(bytes32 indexed namespace, bytes32 indexed name, bytes32 indexed id, address app);

    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 name, address app) public returns (bytes32 id);
    function getApp(bytes32 id) public view returns (address);
}
 
pragma solidity ^0.4.18;




contract AppStorage {
    IKernel public kernel;
    bytes32 public appId;
    address internal pinnedCode;  
    uint256 internal initializationBlock;  
    uint256[95] private storageOffset;  
    uint256 private offset;
}

 
pragma solidity ^0.4.18;




contract Initializable is AppStorage {
    modifier onlyInit {
        require(initializationBlock == 0);
        _;
    }

     
    function getInitializationBlock() public view returns (uint256) {
        return initializationBlock;
    }

     
    function initialized() internal onlyInit {
        initializationBlock = getBlockNumber();
    }

     
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }
}

 
pragma solidity ^0.4.18;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
}

 
pragma solidity 0.4.18;


contract EVMScriptRegistryConstants {
    bytes32 constant public EVMSCRIPT_REGISTRY_APP_ID = keccak256("evmreg.aragonpm.eth");
    bytes32 constant public EVMSCRIPT_REGISTRY_APP = keccak256(keccak256("app"), EVMSCRIPT_REGISTRY_APP_ID);
}


interface IEVMScriptRegistry {
    function addScriptExecutor(address executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    function getScriptExecutor(bytes script) public view returns (address);
}
 
pragma solidity 0.4.18;


library ScriptHelpers {
     
     
     
     

    function abiEncode(bytes _a, bytes _b, address[] _c) public pure returns (bytes d) {
        return encode(_a, _b, _c);
    }

    function encode(bytes memory _a, bytes memory _b, address[] memory _c) internal pure returns (bytes memory d) {
         
        uint256 aPosition = 0x60;
        uint256 bPosition = aPosition + 32 * abiLength(_a);
        uint256 cPosition = bPosition + 32 * abiLength(_b);
        uint256 length = cPosition + 32 * abiLength(_c);

        d = new bytes(length);
        assembly {
             
            mstore(add(d, 0x20), aPosition)
            mstore(add(d, 0x40), bPosition)
            mstore(add(d, 0x60), cPosition)
        }

         
        copy(d, getPtr(_a), aPosition, _a.length);
        copy(d, getPtr(_b), bPosition, _b.length);
        copy(d, getPtr(_c), cPosition, _c.length * 32);  
    }

    function abiLength(bytes memory _a) internal pure returns (uint256) {
         
         
        return 1 + (_a.length / 32) + (_a.length % 32 > 0 ? 1 : 0);
    }

    function abiLength(address[] _a) internal pure returns (uint256) {
         
        return 1 + _a.length;
    }

    function copy(bytes _d, uint256 _src, uint256 _pos, uint256 _length) internal pure {
        uint dest;
        assembly {
            dest := add(add(_d, 0x20), _pos)
        }
        memcpy(dest, _src, _length + 32);
    }

    function getPtr(bytes memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getPtr(address[] memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getSpecId(bytes _script) internal pure returns (uint32) {
        return uint32At(_script, 0);
    }

    function uint256At(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(_data, add(0x20, _location)))
        }
    }

    function addressAt(bytes _data, uint256 _location) internal pure returns (address result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000),
            0x1000000000000000000000000)
        }
    }

    function uint32At(bytes _data, uint256 _location) internal pure returns (uint32 result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffff00000000000000000000000000000000000000000000000000000000),
            0x100000000000000000000000000000000000000000000000000000000)
        }
    }

    function locationOf(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := add(_data, add(0x20, _location))
        }
    }

    function toBytes(bytes4 _sig) internal pure returns (bytes) {
        bytes memory payload = new bytes(4);
        payload[0] = bytes1(_sig);
        payload[1] = bytes1(_sig << 8);
        payload[2] = bytes1(_sig << 16);
        payload[3] = bytes1(_sig << 24);
        return payload;
    }

    function memcpy(uint _dest, uint _src, uint _len) public pure {
        uint256 src = _src;
        uint256 dest = _dest;
        uint256 len = _len;

         
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}
 
pragma solidity ^0.4.18;








contract EVMScriptRunner is AppStorage, EVMScriptRegistryConstants {
    using ScriptHelpers for bytes;

    function runScript(bytes _script, bytes _input, address[] _blacklist) protectState internal returns (bytes output) {
         
        address executorAddr = getExecutor(_script);
        require(executorAddr != address(0));

        bytes memory calldataArgs = _script.encode(_input, _blacklist);
        bytes4 sig = IEVMScriptExecutor(0).execScript.selector;

        require(executorAddr.delegatecall(sig, calldataArgs));

        return returnedDataDecoded();
    }

    function getExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getExecutorRegistry().getScriptExecutor(_script));
    }

     
    function getExecutorRegistry() internal view returns (IEVMScriptRegistry) {
        address registryAddr = kernel.getApp(EVMSCRIPT_REGISTRY_APP);
        return IEVMScriptRegistry(registryAddr);
    }

     
    function returnedDataDecoded() internal view returns (bytes ret) {
        assembly {
            let size := returndatasize
            switch size
            case 0 {}
            default {
                ret := mload(0x40)  
                mstore(0x40, add(ret, add(size, 0x20)))  
                returndatacopy(ret, 0x20, sub(size, 0x20))  
            }
        }
        return ret;
    }

    modifier protectState {
        address preKernel = kernel;
        bytes32 preAppId = appId;
        _;  
        require(kernel == preKernel);
        require(appId == preAppId);
    }
}
 
pragma solidity 0.4.18;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[] r) {}

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

 
pragma solidity ^0.4.18;







contract AragonApp is AppStorage, Initializable, ACLSyntaxSugar, EVMScriptRunner {
    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)));
        _;
    }

    modifier authP(bytes32 _role, uint256[] params) {
        require(canPerform(msg.sender, _role, params));
        _;
    }

    function canPerform(address _sender, bytes32 _role, uint256[] params) public view returns (bool) {
        bytes memory how;  
        if (params.length > 0) {
            uint256 byteLength = params.length * 32;
            assembly {
                how := params  
                mstore(how, byteLength)
            }
        }
        return address(kernel) == 0 || kernel.hasPermission(_sender, address(this), _role, how);
    }
}

 
pragma solidity 0.4.18;








contract ENSSubdomainRegistrar is AragonApp, ENSConstants {
    bytes32 constant public CREATE_NAME_ROLE = bytes32(1);
    bytes32 constant public DELETE_NAME_ROLE = bytes32(2);
    bytes32 constant public POINT_ROOTNODE_ROLE = bytes32(3);

    AbstractENS public ens;
    bytes32 public rootNode;

    event NewName(bytes32 indexed node, bytes32 indexed label);
    event DeleteName(bytes32 indexed node, bytes32 indexed label);

    function initialize(AbstractENS _ens, bytes32 _rootNode) onlyInit public {
        initialized();

         
        require(_ens.owner(_rootNode) == address(this));

        ens = _ens;
        rootNode = _rootNode;
    }

    function createName(bytes32 _label, address _owner) auth(CREATE_NAME_ROLE) external returns (bytes32 node) {
        return _createName(_label, _owner);
    }

    function createNameAndPoint(bytes32 _label, address _target) auth(CREATE_NAME_ROLE) external returns (bytes32 node) {
        node = _createName(_label, this);
        _pointToResolverAndResolve(node, _target);
    }

    function deleteName(bytes32 _label) auth(DELETE_NAME_ROLE) external {
        bytes32 node = keccak256(rootNode, _label);

        address currentOwner = ens.owner(node);

        require(currentOwner != address(0));  

        if (currentOwner != address(this)) {  
            ens.setSubnodeOwner(rootNode, _label, this);
        }

        ens.setResolver(node, address(0));  
        ens.setOwner(node, address(0));

        DeleteName(node, _label);
    }

    function pointRootNode(address _target) auth(POINT_ROOTNODE_ROLE) external {
        _pointToResolverAndResolve(rootNode, _target);
    }

    function _createName(bytes32 _label, address _owner) internal returns (bytes32 node) {
        node = keccak256(rootNode, _label);
        require(ens.owner(node) == address(0));  

        ens.setSubnodeOwner(rootNode, _label, _owner);

        NewName(node, _label);
    }

    function _pointToResolverAndResolve(bytes32 _node, address _target) internal {
        address publicResolver = getAddr(PUBLIC_RESOLVER_NODE);
        ens.setResolver(_node, publicResolver);

        PublicResolver(publicResolver).setAddr(_node, _target);
    }

    function getAddr(bytes32 node) internal view returns (address) {
        address resolver = ens.resolver(node);
        return PublicResolver(resolver).addr(node);
    }
}

 
pragma solidity 0.4.18;

interface IAppProxy {
    function isUpgradeable() public pure returns (bool);
    function getCode() public view returns (address);
}

 
pragma solidity 0.4.18;


contract DelegateProxy {
     
    function delegatedFwd(address _dst, bytes _calldata) internal {
        require(isContract(_dst));
        assembly {
            let result := delegatecall(sub(gas, 10000), _dst, add(_calldata, 0x20), mload(_calldata), 0, 0)
            let size := returndatasize

            let ptr := mload(0x40)
            returndatacopy(ptr, 0, size)

             
             
            switch result case 0 { revert(ptr, size) }
            default { return(ptr, size) }
        }
    }

    function isContract(address _target) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }
}

 
pragma solidity 0.4.18;


contract KernelConstants {
    bytes32 constant public CORE_NAMESPACE = keccak256("core");
    bytes32 constant public APP_BASES_NAMESPACE = keccak256("base");
    bytes32 constant public APP_ADDR_NAMESPACE = keccak256("app");

    bytes32 constant public KERNEL_APP_ID = keccak256("kernel.aragonpm.eth");
    bytes32 constant public KERNEL_APP = keccak256(CORE_NAMESPACE, KERNEL_APP_ID);

    bytes32 constant public ACL_APP_ID = keccak256("acl.aragonpm.eth");
    bytes32 constant public ACL_APP = keccak256(APP_ADDR_NAMESPACE, ACL_APP_ID);
}


contract KernelStorage is KernelConstants {
    mapping (bytes32 => address) public apps;
}

 
pragma solidity 0.4.18;







contract AppProxyBase is IAppProxy, AppStorage, DelegateProxy, KernelConstants {
     
    function AppProxyBase(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public {
        kernel = _kernel;
        appId = _appId;

         
         
         
         
        address appCode = getAppBase(appId);

         
        if (_initializePayload.length > 0) {
            require(isContract(appCode));
             
             
            require(appCode.delegatecall(_initializePayload));
        }
    }

    function getAppBase(bytes32 _appId) internal view returns (address) {
        return kernel.getApp(keccak256(APP_BASES_NAMESPACE, _appId));
    }

    function () payable public {
        address target = getCode();
        require(target != 0);  
        delegatedFwd(target, msg.data);
    }
}
 
pragma solidity 0.4.18;




contract AppProxyUpgradeable is AppProxyBase {
    address public pinnedCode;

     
    function AppProxyUpgradeable(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
             AppProxyBase(_kernel, _appId, _initializePayload) public
    {

    }

    function getCode() public view returns (address) {
        return getAppBase(appId);
    }

    function isUpgradeable() public pure returns (bool) {
        return true;
    }
}

 
pragma solidity 0.4.18;




contract AppProxyPinned is AppProxyBase {
     
    function AppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload)
             AppProxyBase(_kernel, _appId, _initializePayload) public
    {
        pinnedCode = getAppBase(appId);
        require(pinnedCode != address(0));
    }

    function getCode() public view returns (address) {
        return pinnedCode;
    }

    function isUpgradeable() public pure returns (bool) {
        return false;
    }

    function () payable public {
        delegatedFwd(getCode(), msg.data);
    }
}
 
pragma solidity 0.4.18;





contract AppProxyFactory {
    event NewAppProxy(address proxy);

    function newAppProxy(IKernel _kernel, bytes32 _appId) public returns (AppProxyUpgradeable) {
        return newAppProxy(_kernel, _appId, new bytes(0));
    }

    function newAppProxy(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyUpgradeable) {
        AppProxyUpgradeable proxy = new AppProxyUpgradeable(_kernel, _appId, _initializePayload);
        NewAppProxy(address(proxy));
        return proxy;
    }

    function newAppProxyPinned(IKernel _kernel, bytes32 _appId) public returns (AppProxyPinned) {
        return newAppProxyPinned(_kernel, _appId, new bytes(0));
    }

    function newAppProxyPinned(IKernel _kernel, bytes32 _appId, bytes _initializePayload) public returns (AppProxyPinned) {
        AppProxyPinned proxy = new AppProxyPinned(_kernel, _appId, _initializePayload);
        NewAppProxy(address(proxy));
        return proxy;
    }
}

 
pragma solidity 0.4.18;






interface ACLOracle {
    function canPerform(address who, address where, bytes32 what) public view returns (bool);
}


contract ACL is IACL, AragonApp, ACLHelpers {
    bytes32 constant public CREATE_PERMISSIONS_ROLE = keccak256("CREATE_PERMISSIONS_ROLE");

     
    mapping (bytes32 => bytes32) permissions;  
    mapping (bytes32 => Param[]) public permissionParams;

     
    mapping (bytes32 => address) permissionManager;

    enum Op { NONE, EQ, NEQ, GT, LT, GTE, LTE, NOT, AND, OR, XOR, IF_ELSE, RET }  

    struct Param {
        uint8 id;
        uint8 op;
        uint240 value;  
         
         
    }

    uint8 constant BLOCK_NUMBER_PARAM_ID = 200;
    uint8 constant TIMESTAMP_PARAM_ID    = 201;
    uint8 constant SENDER_PARAM_ID       = 202;
    uint8 constant ORACLE_PARAM_ID       = 203;
    uint8 constant LOGIC_OP_PARAM_ID     = 204;
    uint8 constant PARAM_VALUE_PARAM_ID  = 205;
     

    bytes32 constant public EMPTY_PARAM_HASH = keccak256(uint256(0));
    address constant ANY_ENTITY = address(-1);

    modifier onlyPermissionManager(address _app, bytes32 _role) {
        require(msg.sender == getPermissionManager(_app, _role));
        _;
    }

    event SetPermission(address indexed entity, address indexed app, bytes32 indexed role, bool allowed);
    event ChangePermissionManager(address indexed app, bytes32 indexed role, address indexed manager);

     
    function initialize(address _permissionsCreator) onlyInit public {
        initialized();
        require(msg.sender == address(kernel));

        _createPermission(_permissionsCreator, this, CREATE_PERMISSIONS_ROLE, _permissionsCreator);
    }

     
    function createPermission(address _entity, address _app, bytes32 _role, address _manager) external {
        require(hasPermission(msg.sender, address(this), CREATE_PERMISSIONS_ROLE));

        _createPermission(_entity, _app, _role, _manager);
    }

     
    function grantPermission(address _entity, address _app, bytes32 _role)
        external
    {
        grantPermissionP(_entity, _app, _role, new uint256[](0));
    }

     
    function grantPermissionP(address _entity, address _app, bytes32 _role, uint256[] _params)
        onlyPermissionManager(_app, _role)
        public
    {
        require(!hasPermission(_entity, _app, _role));

        bytes32 paramsHash = _params.length > 0 ? _saveParams(_params) : EMPTY_PARAM_HASH;
        _setPermission(_entity, _app, _role, paramsHash);
    }

     
    function revokePermission(address _entity, address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        require(hasPermission(_entity, _app, _role));

        _setPermission(_entity, _app, _role, bytes32(0));
    }

     
    function setPermissionManager(address _newManager, address _app, bytes32 _role)
        onlyPermissionManager(_app, _role)
        external
    {
        _setPermissionManager(_newManager, _app, _role);
    }

     
    function getPermissionManager(address _app, bytes32 _role) public view returns (address) {
        return permissionManager[roleHash(_app, _role)];
    }

     
    function hasPermission(address _who, address _where, bytes32 _what, bytes memory _how) public view returns (bool) {
        uint256[] memory how;
        uint256 intsLength = _how.length / 32;
        assembly {
            how := _how  
            mstore(how, intsLength)
        }
         
        return hasPermission(_who, _where, _what, how);
    }

    function hasPermission(address _who, address _where, bytes32 _what, uint256[] memory _how) public view returns (bool) {
        bytes32 whoParams = permissions[permissionHash(_who, _where, _what)];
        if (whoParams != bytes32(0) && evalParams(whoParams, _who, _where, _what, _how)) {
            return true;
        }

        bytes32 anyParams = permissions[permissionHash(ANY_ENTITY, _where, _what)];
        if (anyParams != bytes32(0) && evalParams(anyParams, ANY_ENTITY, _where, _what, _how)) {
            return true;
        }

        return false;
    }

    function hasPermission(address _who, address _where, bytes32 _what) public view returns (bool) {
        uint256[] memory empty = new uint256[](0);
        return hasPermission(_who, _where, _what, empty);
    }

     
    function _createPermission(address _entity, address _app, bytes32 _role, address _manager) internal {
         
        require(getPermissionManager(_app, _role) == address(0));

        _setPermission(_entity, _app, _role, EMPTY_PARAM_HASH);
        _setPermissionManager(_manager, _app, _role);
    }

     
    function _setPermission(address _entity, address _app, bytes32 _role, bytes32 _paramsHash) internal {
        permissions[permissionHash(_entity, _app, _role)] = _paramsHash;

        SetPermission(_entity, _app, _role, _paramsHash != bytes32(0));
    }

    function _saveParams(uint256[] _encodedParams) internal returns (bytes32) {
        bytes32 paramHash = keccak256(_encodedParams);
        Param[] storage params = permissionParams[paramHash];

        if (params.length == 0) {  
            for (uint256 i = 0; i < _encodedParams.length; i++) {
                uint256 encodedParam = _encodedParams[i];
                Param memory param = Param(decodeParamId(encodedParam), decodeParamOp(encodedParam), uint240(encodedParam));
                params.push(param);
            }
        }

        return paramHash;
    }

    function evalParams(
        bytes32 _paramsHash,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) internal view returns (bool)
    {
        if (_paramsHash == EMPTY_PARAM_HASH) {
            return true;
        }

        return evalParam(_paramsHash, 0, _who, _where, _what, _how);
    }

    function evalParam(
        bytes32 _paramsHash,
        uint32 _paramId,
        address _who,
        address _where,
        bytes32 _what,
        uint256[] _how
    ) internal view returns (bool)
    {
        if (_paramId >= permissionParams[_paramsHash].length) {
            return false;  
        }

        Param memory param = permissionParams[_paramsHash][_paramId];

        if (param.id == LOGIC_OP_PARAM_ID) {
            return evalLogic(param, _paramsHash, _who, _where, _what, _how);
        }

        uint256 value;
        uint256 comparedTo = uint256(param.value);

         
        if (param.id == ORACLE_PARAM_ID) {
            value = ACLOracle(param.value).canPerform(_who, _where, _what) ? 1 : 0;
            comparedTo = 1;
        } else if (param.id == BLOCK_NUMBER_PARAM_ID) {
            value = blockN();
        } else if (param.id == TIMESTAMP_PARAM_ID) {
            value = time();
        } else if (param.id == SENDER_PARAM_ID) {
            value = uint256(msg.sender);
        } else if (param.id == PARAM_VALUE_PARAM_ID) {
            value = uint256(param.value);
        } else {
            if (param.id >= _how.length) {
                return false;
            }
            value = uint256(uint240(_how[param.id]));  
        }

        if (Op(param.op) == Op.RET) {
            return uint256(value) > 0;
        }

        return compare(value, Op(param.op), comparedTo);
    }

    function evalLogic(Param _param, bytes32 _paramsHash, address _who, address _where, bytes32 _what, uint256[] _how) internal view returns (bool) {
        if (Op(_param.op) == Op.IF_ELSE) {
            var (condition, success, failure) = decodeParamsList(uint256(_param.value));
            bool result = evalParam(_paramsHash, condition, _who, _where, _what, _how);

            return evalParam(_paramsHash, result ? success : failure, _who, _where, _what, _how);
        }

        var (v1, v2,) = decodeParamsList(uint256(_param.value));
        bool r1 = evalParam(_paramsHash, v1, _who, _where, _what, _how);

        if (Op(_param.op) == Op.NOT) {
            return !r1;
        }

        if (r1 && Op(_param.op) == Op.OR) {
            return true;
        }

        if (!r1 && Op(_param.op) == Op.AND) {
            return false;
        }

        bool r2 = evalParam(_paramsHash, v2, _who, _where, _what, _how);

        if (Op(_param.op) == Op.XOR) {
            return (r1 && !r2) || (!r1 && r2);
        }

        return r2;  
    }

    function compare(uint256 _a, Op _op, uint256 _b) internal pure returns (bool) {
        if (_op == Op.EQ)  return _a == _b;                               
        if (_op == Op.NEQ) return _a != _b;                               
        if (_op == Op.GT)  return _a > _b;                                
        if (_op == Op.LT)  return _a < _b;                                
        if (_op == Op.GTE) return _a >= _b;                               
        if (_op == Op.LTE) return _a <= _b;                               
        return false;
    }

     
    function _setPermissionManager(address _newManager, address _app, bytes32 _role) internal {
        permissionManager[roleHash(_app, _role)] = _newManager;
        ChangePermissionManager(_app, _role, _newManager);
    }

    function roleHash(address _where, bytes32 _what) pure internal returns (bytes32) {
        return keccak256(uint256(1), _where, _what);
    }

    function permissionHash(address _who, address _where, bytes32 _what) pure internal returns (bytes32) {
        return keccak256(uint256(2), _who, _where, _what);
    }

    function time() internal view returns (uint64) { return uint64(block.timestamp); }  

    function blockN() internal view returns (uint256) { return block.number; }
}

 
pragma solidity ^0.4.15;




contract Repo is AragonApp {
    struct Version {
        uint16[3] semanticVersion;
        address contractAddress;
        bytes contentURI;
    }

    Version[] versions;
    mapping (bytes32 => uint256) versionIdForSemantic;
    mapping (address => uint256) latestVersionIdForContract;

    bytes32 constant public CREATE_VERSION_ROLE = bytes32(1);

    event NewVersion(uint256 versionId, uint16[3] semanticVersion);

     
    function newVersion(
        uint16[3] _newSemanticVersion,
        address _contractAddress,
        bytes _contentURI
    ) auth(CREATE_VERSION_ROLE) public
    {
        address contractAddress = _contractAddress;
        if (versions.length > 0) {
            Version storage lastVersion = versions[versions.length - 1];
            require(isValidBump(lastVersion.semanticVersion, _newSemanticVersion));
            if (contractAddress == 0) {
                contractAddress = lastVersion.contractAddress;
            }
             
            require(lastVersion.contractAddress == contractAddress || _newSemanticVersion[0] > lastVersion.semanticVersion[0]);
        } else {
            versions.length += 1;
            uint16[3] memory zeroVersion;
            require(isValidBump(zeroVersion, _newSemanticVersion));
        }

        uint versionId = versions.push(Version(_newSemanticVersion, contractAddress, _contentURI)) - 1;
        versionIdForSemantic[semanticVersionHash(_newSemanticVersion)] = versionId;
        latestVersionIdForContract[contractAddress] = versionId;

        NewVersion(versionId, _newSemanticVersion);
    }

    function getLatest() public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(versions.length - 1);
    }

    function getLatestForContractAddress(address _contractAddress) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(latestVersionIdForContract[_contractAddress]);
    }

    function getBySemanticVersion(uint16[3] _semanticVersion) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(versionIdForSemantic[semanticVersionHash(_semanticVersion)]);
    }

    function getByVersionId(uint _versionId) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        require(_versionId > 0);
        Version storage version = versions[_versionId];
        return (version.semanticVersion, version.contractAddress, version.contentURI);
    }

    function getVersionsCount() public view returns (uint256) {
        uint256 len = versions.length;
        return len > 0 ? len - 1 : 0;
    }

    function isValidBump(uint16[3] _oldVersion, uint16[3] _newVersion) public pure returns (bool) {
        bool hasBumped;
        uint i = 0;
        while (i < 3) {
            if (hasBumped) {
                if (_newVersion[i] != 0) {
                    return false;
                }
            } else if (_newVersion[i] != _oldVersion[i]) {
                if (_oldVersion[i] > _newVersion[i] || _newVersion[i] - _oldVersion[i] != 1) {
                    return false;
                }
                hasBumped = true;
            }
            i++;
        }
        return hasBumped;
    }

    function semanticVersionHash(uint16[3] version) internal pure returns (bytes32) {
        return keccak256(version[0], version[1], version[2]);
    }
}

 
pragma solidity 0.4.18;









contract APMRegistryConstants {
     
     
    string constant public APM_APP_NAME = "apm-registry";
    string constant public REPO_APP_NAME = "apm-repo";
    string constant public ENS_SUB_APP_NAME = "apm-enssub";
}


contract APMRegistry is AragonApp, AppProxyFactory, APMRegistryConstants {
    AbstractENS ens;
    ENSSubdomainRegistrar public registrar;

    bytes32 constant public CREATE_REPO_ROLE = bytes32(1);

    event NewRepo(bytes32 id, string name, address repo);

     
    function initialize(ENSSubdomainRegistrar _registrar) onlyInit public {
        initialized();

        registrar = _registrar;
        ens = registrar.ens();

        registrar.pointRootNode(this);

         
        ACL acl = ACL(kernel.acl());
        require(acl.hasPermission(this, registrar, registrar.CREATE_NAME_ROLE()));
        require(acl.hasPermission(this, acl, acl.CREATE_PERMISSIONS_ROLE()));
    }

     
    function newRepo(string _name, address _dev) auth(CREATE_REPO_ROLE) public returns (Repo) {
        return _newRepo(_name, _dev);
    }

     
    function newRepoWithVersion(
        string _name,
        address _dev,
        uint16[3] _initialSemanticVersion,
        address _contractAddress,
        bytes _contentURI
    ) auth(CREATE_REPO_ROLE) public returns (Repo)
    {
        Repo repo = _newRepo(_name, this);  
        repo.newVersion(_initialSemanticVersion, _contractAddress, _contentURI);

         
        ACL acl = ACL(kernel.acl());
        acl.revokePermission(this, repo, repo.CREATE_VERSION_ROLE());
        acl.grantPermission(_dev, repo, repo.CREATE_VERSION_ROLE());
        acl.setPermissionManager(_dev, repo, repo.CREATE_VERSION_ROLE());
        return repo;
    }

    function _newRepo(string _name, address _dev) internal returns (Repo) {
        require(bytes(_name).length > 0);

        Repo repo = newClonedRepo();

        ACL(kernel.acl()).createPermission(_dev, repo, repo.CREATE_VERSION_ROLE(), _dev);

         
         
        bytes32 node = registrar.createNameAndPoint(keccak256(_name), repo);

        NewRepo(node, _name, repo);

        return repo;
    }

    function newClonedRepo() internal returns (Repo) {
        return Repo(newAppProxy(kernel, repoAppId()));
    }

    function repoAppId() internal view returns (bytes32) {
        return keccak256(registrar.rootNode(), keccak256(REPO_APP_NAME));
    }
}

 
pragma solidity 0.4.18;









contract Kernel is IKernel, KernelStorage, Initializable, AppProxyFactory, ACLSyntaxSugar {
    bytes32 constant public APP_MANAGER_ROLE = keccak256("APP_MANAGER_ROLE");

     
    function initialize(address _baseAcl, address _permissionsCreator) onlyInit public {
        initialized();

        IACL acl = IACL(newAppProxy(this, ACL_APP_ID));

        _setApp(APP_BASES_NAMESPACE, ACL_APP_ID, _baseAcl);
        _setApp(APP_ADDR_NAMESPACE, ACL_APP_ID, acl);

        acl.initialize(_permissionsCreator);
    }

     
    function newAppInstance(bytes32 _name, address _appBase) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (IAppProxy appProxy) {
        _setAppIfNew(APP_BASES_NAMESPACE, _name, _appBase);
        appProxy = newAppProxy(this, _name);
    }

     
    function newPinnedAppInstance(bytes32 _name, address _appBase) auth(APP_MANAGER_ROLE, arr(APP_BASES_NAMESPACE, _name)) public returns (IAppProxy appProxy) {
        _setAppIfNew(APP_BASES_NAMESPACE, _name, _appBase);
        appProxy = newAppProxyPinned(this, _name);
    }

     
    function setApp(bytes32 _namespace, bytes32 _name, address _app) auth(APP_MANAGER_ROLE, arr(_namespace, _name)) kernelIntegrity public returns (bytes32 id) {
        return _setApp(_namespace, _name, _app);
    }

     
    function getApp(bytes32 _id) public view returns (address) {
        return apps[_id];
    }

     
    function acl() public view returns (IACL) {
        return IACL(getApp(ACL_APP));
    }

     
    function hasPermission(address _who, address _where, bytes32 _what, bytes _how) public view returns (bool) {
        return acl().hasPermission(_who, _where, _what, _how);
    }

    function _setApp(bytes32 _namespace, bytes32 _name, address _app) internal returns (bytes32 id) {
        id = keccak256(_namespace, _name);
        apps[id] = _app;
        SetApp(_namespace, _name, id, _app);
    }

    function _setAppIfNew(bytes32 _namespace, bytes32 _name, address _app) internal returns (bytes32 id) {
        id = keccak256(_namespace, _name);

        if (_app != address(0)) {
            address app = getApp(id);
            if (app != address(0)) {
                require(app == _app);
            } else {
                apps[id] = _app;
                SetApp(_namespace, _name, id, _app);
            }
        }
    }

    modifier auth(bytes32 _role, uint256[] memory params) {
        bytes memory how;
        uint256 byteLength = params.length * 32;
        assembly {
            how := params  
            mstore(how, byteLength)
        }
         
        require(hasPermission(msg.sender, address(this), _role, how));
        _;
    }

    modifier kernelIntegrity {
        _;  
        address kernel = getApp(KERNEL_APP);
        uint256 size;
        assembly { size := extcodesize(kernel) }
        require(size > 0);
    }
}

 
pragma solidity 0.4.18;





contract KernelProxy is KernelStorage, DelegateProxy {
     
    function KernelProxy(address _kernelImpl) public {
        apps[keccak256(CORE_NAMESPACE, KERNEL_APP_ID)] = _kernelImpl;
    }

     
    function () payable public {
        delegatedFwd(apps[KERNEL_APP], msg.data);
    }
}
 
pragma solidity 0.4.18;








contract EVMScriptRegistry is IEVMScriptRegistry, EVMScriptRegistryConstants, AragonApp {
    using ScriptHelpers for bytes;

     
    bytes32 constant public REGISTRY_MANAGER_ROLE = bytes32(1);

    struct ExecutorEntry {
        address executor;
        bool enabled;
    }

    ExecutorEntry[] public executors;

    function initialize() onlyInit public {
        initialized();
         
        executors.push(ExecutorEntry(address(0), false));
    }

    function addScriptExecutor(address _executor) external auth(REGISTRY_MANAGER_ROLE) returns (uint id) {
        return executors.push(ExecutorEntry(_executor, true));
    }

    function disableScriptExecutor(uint256 _executorId) external auth(REGISTRY_MANAGER_ROLE) {
        executors[_executorId].enabled = false;
    }

    function getScriptExecutor(bytes _script) public view returns (address) {
        uint256 id = _script.getSpecId();

        if (id == 0 || id >= executors.length) {
            return address(0);
        }

        ExecutorEntry storage entry = executors[id];
        return entry.enabled ? entry.executor : address(0);
    }
}

 
pragma solidity ^0.4.18;

 





contract CallsScript is IEVMScriptExecutor {
    using ScriptHelpers for bytes;

    uint256 constant internal SCRIPT_START_LOCATION = 4;

    event LogScriptCall(address indexed sender, address indexed src, address indexed dst);

     
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        uint256 location = SCRIPT_START_LOCATION;  
        while (location < _script.length) {
            address contractAddress = _script.addressAt(location);
             
            for (uint i = 0; i < _blacklist.length; i++) {
                require(contractAddress != _blacklist[i]);
            }

             
             
            LogScriptCall(msg.sender, address(this), contractAddress);

            uint256 calldataLength = uint256(_script.uint32At(location + 0x14));
            uint256 calldataStart = _script.locationOf(location + 0x14 + 0x04);

            assembly {
                let success := call(sub(gas, 5000), contractAddress, 0, calldataStart, calldataLength, 0, 0)
                switch success case 0 { revert(0, 0) }
            }

            location += (0x14 + 0x04 + calldataLength);
        }
    }
}
 
pragma solidity 0.4.18;





interface DelegateScriptTarget {
    function exec() public;
}


contract DelegateScript is IEVMScriptExecutor {
    using ScriptHelpers for *;

    uint256 constant internal SCRIPT_START_LOCATION = 4;

     
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        require(_blacklist.length == 0);  

         
        require(_script.length == SCRIPT_START_LOCATION + 20);
        return delegate(_script.addressAt(SCRIPT_START_LOCATION), _input);
    }

     
    function delegate(address _addr, bytes memory _input) internal returns (bytes memory output) {
        require(isContract(_addr));
        require(_addr.delegatecall(_input.length > 0 ? _input : defaultInput()));
        return returnedData();
    }

    function isContract(address _target) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(_target) }
        return size > 0;
    }

    function defaultInput() internal pure returns (bytes) {
        return DelegateScriptTarget(0).exec.selector.toBytes();
    }

     
    function returnedData() internal view returns (bytes ret) {
        assembly {
            let size := returndatasize
            ret := mload(0x40)  
            mstore(0x40, add(ret, add(size, 0x20)))  
            mstore(ret, size)  
            returndatacopy(add(ret, 0x20), 0, size)  
        }
        return ret;
    }
}
 
pragma solidity 0.4.18;



 


contract DeployDelegateScript is DelegateScript {
    uint256 constant internal SCRIPT_START_LOCATION = 4;

    mapping (bytes32 => address) cache;

     
    function execScript(bytes _script, bytes _input, address[] _blacklist) external returns (bytes) {
        require(_blacklist.length == 0);  

        bytes32 id = keccak256(_script);
        address deployed = cache[id];
        if (deployed == address(0)) {
            deployed = deploy(_script);
            cache[id] = deployed;
        }

        return DelegateScript.delegate(deployed, _input);
    }

     
    function deploy(bytes _script) internal returns (address addr) {
        assembly {
             
             
            addr := create(0, add(_script, 0x24), sub(mload(_script), 0x04))
            switch iszero(extcodesize(addr))
            case 1 { revert(0, 0) }  
        }
    }
}
 
pragma solidity 0.4.18;












contract EVMScriptRegistryFactory is AppProxyFactory, EVMScriptRegistryConstants {
    address public baseReg;
    address public baseCalls;
    address public baseDel;
    address public baseDeployDel;

    function EVMScriptRegistryFactory() public {
        baseReg = address(new EVMScriptRegistry());
        baseCalls = address(new CallsScript());
        baseDel = address(new DelegateScript());
        baseDeployDel = address(new DeployDelegateScript());
    }

    function newEVMScriptRegistry(Kernel _dao, address _root) public returns (EVMScriptRegistry reg) {
        reg = EVMScriptRegistry(_dao.newPinnedAppInstance(EVMSCRIPT_REGISTRY_APP_ID, baseReg));
        reg.initialize();

        ACL acl = ACL(_dao.acl());

        _dao.setApp(_dao.APP_ADDR_NAMESPACE(), EVMSCRIPT_REGISTRY_APP_ID, reg);
        acl.createPermission(this, reg, reg.REGISTRY_MANAGER_ROLE(), this);

        reg.addScriptExecutor(baseCalls);      
        reg.addScriptExecutor(baseDel);        
        reg.addScriptExecutor(baseDeployDel);  

        acl.revokePermission(this, reg, reg.REGISTRY_MANAGER_ROLE());
        acl.setPermissionManager(_root, reg, reg.REGISTRY_MANAGER_ROLE());

        return reg;
    }
}

 
pragma solidity 0.4.18;









contract DAOFactory {
    address public baseKernel;
    address public baseACL;
    EVMScriptRegistryFactory public regFactory;

    event DeployDAO(address dao);
    event DeployEVMScriptRegistry(address reg);

    function DAOFactory(address _baseKernel, address _baseACL, address _regFactory) public {
         
        if (_regFactory != address(0)) {
            regFactory = EVMScriptRegistryFactory(_regFactory);
        }

        baseKernel = _baseKernel;
        baseACL = _baseACL;
    }

     
    function newDAO(address _root) public returns (Kernel dao) {
        dao = Kernel(new KernelProxy(baseKernel));

        address initialRoot = address(regFactory) != address(0) ? this : _root;
        dao.initialize(baseACL, initialRoot);

        ACL acl = ACL(dao.acl());

        if (address(regFactory) != address(0)) {
            bytes32 permRole = acl.CREATE_PERMISSIONS_ROLE();
            bytes32 appManagerRole = dao.APP_MANAGER_ROLE();

            acl.grantPermission(regFactory, acl, permRole);

            acl.createPermission(regFactory, dao, appManagerRole, this);

            EVMScriptRegistry reg = regFactory.newEVMScriptRegistry(dao, _root);
            DeployEVMScriptRegistry(address(reg));

            acl.revokePermission(regFactory, dao, appManagerRole);
            acl.grantPermission(_root, acl, permRole);

            acl.setPermissionManager(address(0), dao, appManagerRole);
            acl.setPermissionManager(_root, acl, permRole);
        }

        DeployDAO(dao);
    }
}

 
pragma solidity ^0.4.0;




 
contract ENS is AbstractENS {
    struct Record {
        address owner;
        address resolver;
        uint64 ttl;
    }

    mapping(bytes32=>Record) records;

     
    modifier only_owner(bytes32 node) {
        if (records[node].owner != msg.sender) throw;
        _;
    }

     
    function ENS() {
        records[0].owner = msg.sender;
    }

     
    function owner(bytes32 node) constant returns (address) {
        return records[node].owner;
    }

     
    function resolver(bytes32 node) constant returns (address) {
        return records[node].resolver;
    }

     
    function ttl(bytes32 node) constant returns (uint64) {
        return records[node].ttl;
    }

     
    function setOwner(bytes32 node, address owner) only_owner(node) {
        Transfer(node, owner);
        records[node].owner = owner;
    }

     
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) only_owner(node) {
        var subnode = keccak256(node, label);
        NewOwner(node, label, owner);
        records[subnode].owner = owner;
    }

     
    function setResolver(bytes32 node, address resolver) only_owner(node) {
        NewResolver(node, resolver);
        records[node].resolver = resolver;
    }

     
    function setTTL(bytes32 node, uint64 ttl) only_owner(node) {
        NewTTL(node, ttl);
        records[node].ttl = ttl;
    }
}

 
pragma solidity 0.4.18;






contract ENSFactory is ENSConstants {
    event DeployENS(address ens);

     
    function newENS(address _owner) public returns (ENS ens) {
        ens = new ENS();

         
        ens.setSubnodeOwner(ENS_ROOT, ETH_TLD_LABEL, this);

         
        PublicResolver resolver = new PublicResolver(ens);
        ens.setSubnodeOwner(ETH_TLD_NODE, PUBLIC_RESOLVER_LABEL, this);
        ens.setResolver(PUBLIC_RESOLVER_NODE, resolver);
        resolver.setAddr(PUBLIC_RESOLVER_NODE, resolver);

        ens.setOwner(ETH_TLD_NODE, _owner);
        ens.setOwner(ENS_ROOT, _owner);

        DeployENS(ens);
    }
}

 
pragma solidity 0.4.18;










contract APMRegistryFactory is APMRegistryConstants {
    DAOFactory public daoFactory;
    APMRegistry public registryBase;
    Repo public repoBase;
    ENSSubdomainRegistrar public ensSubdomainRegistrarBase;
    ENS public ens;

    event DeployAPM(bytes32 indexed node, address apm);

     
    function APMRegistryFactory(
        DAOFactory _daoFactory,
        APMRegistry _registryBase,
        Repo _repoBase,
        ENSSubdomainRegistrar _ensSubBase,
        ENS _ens,
        ENSFactory _ensFactory
    ) public  
    {
        daoFactory = _daoFactory;
        registryBase = _registryBase;
        repoBase = _repoBase;
        ensSubdomainRegistrarBase = _ensSubBase;

         
         
         
        ens = _ens != address(0) ? _ens : _ensFactory.newENS(this);
    }

    function newAPM(bytes32 _tld, bytes32 _label, address _root) public returns (APMRegistry) {
        bytes32 node = keccak256(_tld, _label);

         
        if (ens.owner(node) != address(this)) {
             
            ens.setSubnodeOwner(_tld, _label, this);
        }

        Kernel dao = daoFactory.newDAO(this);
        ACL acl = ACL(dao.acl());

        acl.createPermission(this, dao, dao.APP_MANAGER_ROLE(), this);

        bytes32 namespace = dao.APP_BASES_NAMESPACE();

         
        ENSSubdomainRegistrar ensSub = ENSSubdomainRegistrar(dao.newAppInstance(keccak256(node, keccak256(ENS_SUB_APP_NAME)), ensSubdomainRegistrarBase));
        APMRegistry apm = APMRegistry(dao.newAppInstance(keccak256(node, keccak256(APM_APP_NAME)), registryBase));

         
        dao.setApp(namespace, keccak256(node, keccak256(REPO_APP_NAME)), repoBase);

        DeployAPM(node, apm);

         
        acl.createPermission(apm, ensSub, ensSub.CREATE_NAME_ROLE(), _root);
        acl.createPermission(apm, ensSub, ensSub.POINT_ROOTNODE_ROLE(), _root);

         
        bytes32 permRole = acl.CREATE_PERMISSIONS_ROLE();

        acl.grantPermission(apm, acl, permRole);

         
        ens.setOwner(node, ensSub);
        ensSub.initialize(ens, node);
        apm.initialize(ensSub);

        uint16[3] memory firstVersion;
        firstVersion[0] = 1;

        acl.createPermission(this, apm, apm.CREATE_REPO_ROLE(), this);

        apm.newRepoWithVersion(APM_APP_NAME, _root, firstVersion, registryBase, b("ipfs:apm"));
        apm.newRepoWithVersion(ENS_SUB_APP_NAME, _root, firstVersion, ensSubdomainRegistrarBase, b("ipfs:enssub"));
        apm.newRepoWithVersion(REPO_APP_NAME, _root, firstVersion, repoBase, b("ipfs:repo"));

        configureAPMPermissions(acl, apm, _root);

         
        acl.setPermissionManager(_root, dao, dao.APP_MANAGER_ROLE());
        acl.revokePermission(this, acl, permRole);
        acl.grantPermission(_root, acl, permRole);
        acl.setPermissionManager(_root, acl, permRole);

        return apm;
    }

    function b(string memory x) internal pure returns (bytes memory y) {
        y = bytes(x);
    }

     
    function configureAPMPermissions(ACL _acl, APMRegistry _apm, address _root) internal {
        _acl.grantPermission(_root, _apm, _apm.CREATE_REPO_ROLE());
        _acl.setPermissionManager(_root, _apm, _apm.CREATE_REPO_ROLE());
    }
}