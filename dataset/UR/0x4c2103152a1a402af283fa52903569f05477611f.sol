 

 

pragma solidity ^0.5.11;


contract ERC20 {
    function totalSupply()
        public
        view
        returns (uint);

    function balanceOf(
        address who
        )
        public
        view
        returns (uint);

    function allowance(
        address owner,
        address spender
        )
        public
        view
        returns (uint);

    function transfer(
        address to,
        uint value
        )
        public
        returns (bool);

    function transferFrom(
        address from,
        address to,
        uint    value
        )
        public
        returns (bool);

    function approve(
        address spender,
        uint    value
        )
        public
        returns (bool);
}

contract BurnableERC20 is ERC20
{
    function burn(
        uint value
        )
        public
        returns (bool);

    function burnFrom(
        address from,
        uint value
        )
        public
        returns (bool);
}

contract Proxy {
  
  function implementation() public view returns (address);

  
  function () payable external {
    address _impl = implementation();
    require(_impl != address(0));

    assembly {
      let ptr := mload(0x40)
      calldatacopy(ptr, 0, calldatasize)
      let result := delegatecall(gas, _impl, ptr, calldatasize, 0, 0)
      let size := returndatasize
      returndatacopy(ptr, 0, size)

      switch result
      case 0 { revert(ptr, size) }
      default { return(ptr, size) }
    }
  }
}

contract SimpleProxy is Proxy
{
    bytes32 private constant implementationPosition = keccak256(
        "org.loopring.protocol.simple.proxy"
    );

    constructor(address _implementation)
        public
    {
        bytes32 position = implementationPosition;
        assembly {sstore(position, _implementation) }
    }

    function implementation()
        public
        view
        returns (address impl)
    {
        bytes32 position = implementationPosition;
        assembly { impl := sload(position) }
    }
}

library Cloneable {
    function clone(address a)
        external
        returns (address)
    {

    
        address retval;
        assembly{
            mstore(0x0, or (0x5880730000000000000000000000000000000000000000803b80938091923cF3 ,mul(a,0x1000000000000000000)))
            retval := create(0,0, 32)
        }
        return retval;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    
    
    constructor()
        public
    {
        owner = msg.sender;
    }

    
    modifier onlyOwner()
    {
        require(msg.sender == owner, "UNAUTHORIZED");
        _;
    }

    
    
    
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0), "ZERO_ADDRESS");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function renounceOwnership()
        public
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }
}

contract Claimable is Ownable
{
    address public pendingOwner;

    
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner, "UNAUTHORIZED");
        _;
    }

    
    
    function transferOwnership(
        address newOwner
        )
        public
        onlyOwner
    {
        require(newOwner != address(0) && newOwner != owner, "INVALID_ADDRESS");
        pendingOwner = newOwner;
    }

    
    function claimOwnership()
        public
        onlyPendingOwner
    {
        emit OwnershipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
    }
}

contract ReentrancyGuard {
    
    uint private _guardValue;

    
    modifier nonReentrant()
    {
        
        require(_guardValue == 0, "REENTRANCY");

        
        _guardValue = 1;

        
        _;

        
        _guardValue = 0;
    }
}

contract IExchange is Claimable, ReentrancyGuard
{
    string constant public version = ""; 

    event Cloned (address indexed clone);

    
    
    function clone()
        external
        nonReentrant
        returns (address cloneAddress)
    {
        address origin = address(this);
        cloneAddress = Cloneable.clone(origin);

        assert(cloneAddress != origin);
        assert(cloneAddress != address(0));

        emit Cloned(cloneAddress);
    }
}

contract ILoopring is Claimable, ReentrancyGuard
{
    string  constant public version = ""; 

    uint    public exchangeCreationCostLRC;
    address public universalRegistry;
    address public lrcAddress;

    event ExchangeInitialized(
        uint    indexed exchangeId,
        address indexed exchangeAddress,
        address indexed owner,
        address         operator,
        bool            onchainDataAvailability
    );

    
    
    
    
    
    
    
    
    
    
    function initializeExchange(
        address exchangeAddress,
        uint    exchangeId,
        address owner,
        address payable operator,
        bool    onchainDataAvailability
        )
        external;
}

contract IUniversalRegistry is Claimable, ReentrancyGuard
{
    enum ForgeMode {
        AUTO_UPGRADABLE,
        MANUAL_UPGRADABLE,
        PROXIED,
        NATIVE
    }

    

    event ProtocolRegistered (
        address indexed protocol,
        address indexed implementationManager,
        string          version
    );

    event ProtocolEnabled (
        address indexed protocol
    );

    event ProtocolDisabled (
        address indexed protocol
    );

    event DefaultProtocolChanged (
        address indexed oldDefault,
        address indexed newDefault
    );

    event ExchangeForged (
        address indexed protocol,
        address indexed implementation,
        address indexed exchangeAddress,
        address         owner,
        ForgeMode       forgeMode,
        bool            onchainDataAvailability,
        uint            exchangeId,
        uint            amountLRCBurned
    );

    

    address   public lrcAddress;
    address[] public exchanges;
    address[] public protocols;

    
    mapping (string => address) public versionMap;

    

    
    
    
    
    function registerProtocol(
        address protocol,
        address implementation
        )
        external
        returns (address implManager);

    
    
    function setDefaultProtocol(
        address protocol
        )
        external;

    
    
    function enableProtocol(
        address protocol
        )
        external;

    
    
    function disableProtocol(
        address protocol
        )
        external;

    
    
    
    
    
    
    
    
    function forgeExchange(
        ForgeMode forgeMode,
        bool      onchainDataAvailability,
        address   protocol,
        address   implementation
        )
        external
        returns (
            address exchangeAddress,
            uint    exchangeId
        );

    
    
    
    
    
    function defaultProtocol()
        public
        view
        returns (
            address protocol,
            address versionmanager,
            address defaultImpl,
            string  memory protocolVersion,
            string  memory defaultImplVersion
        );

    
    
    
    function isProtocolRegistered(
        address protocol
        )
        public
        view
        returns (bool registered);

    
    
    
    function isProtocolEnabled(
        address protocol
        )
        public
        view
        returns (bool enabled);

    
    
    function isExchangeRegistered(
        address exchange
        )
        public
        view
        returns (bool registered);

    
    
    
    
    function isProtocolAndImplementationEnabled(
        address protocol,
        address implementation
        )
        public
        view
        returns (bool enabled);

    
    
    
    
    
    function getExchangeProtocol(
        address exchangeAddress
        )
        public
        view
        returns (
            address protocol,
            address implementation
        );
}

contract IImplementationManager is Claimable, ReentrancyGuard
{
    

    event DefaultChanged (
        address indexed oldDefault,
        address indexed newDefault
    );

    event Registered (
        address indexed implementation,
        string          version
    );

    event Enabled (
        address indexed implementation
    );

    event Disabled (
        address indexed implementation
    );

    

    address   public protocol;
    address   public defaultImpl;
    address[] public implementations;

    
    mapping (string => address) public versionMap;

    

    
    
    function register(
        address implementation
        )
        external;

    
    
    function setDefault(
        address implementation
        )
        external;

    
    
    function enable(
        address implementation
        )
        external;

    
    
    function disable(
        address implementation
        )
        external;

    
    
    
    function version()
        public
        view
        returns (
            string  memory protocolVersion,
            string  memory defaultImplVersion
        );

    
    
    function latest()
        public
        view
        returns (address implementation);

    
    
    function isRegistered(
        address implementation
        )
        public
        view
        returns (bool registered);

    
    
    function isEnabled(
        address implementation
        )
        public
        view
        returns (bool enabled);
}

contract IExchangeProxy is Proxy
{
    bytes32 private constant registryPosition = keccak256(
        "org.loopring.protocol.v3.registry"
    );

    constructor(address _registry)
        public
    {
        setRegistry(_registry);
    }

    
    function registry()
        public
        view
        returns (address registryAddress)
    {
        bytes32 position = registryPosition;
        assembly { registryAddress := sload(position) }
    }

    
    function protocol()
        public
        view
        returns (address protocolAddress)
    {
        IUniversalRegistry r = IUniversalRegistry(registry());
        (protocolAddress, ) = r.getExchangeProtocol(address(this));
    }

    function setRegistry(address _registry)
        private
    {
        require(_registry != address(0), "ZERO_ADDRESS");
        bytes32 position = registryPosition;
        assembly { sstore(position, _registry) }
    }
}

contract AutoUpgradabilityProxy is IExchangeProxy
{
    constructor(address _registry) public IExchangeProxy(_registry) {}

    function implementation()
        public
        view
        returns (address)
    {
        IUniversalRegistry r = IUniversalRegistry(registry());
        (, address managerAddr) = r.getExchangeProtocol(address(this));
        return IImplementationManager(managerAddr).defaultImpl();
    }
}

contract ManualUpgradabilityProxy is IExchangeProxy
{
    event Upgraded(address indexed implementation);

    bytes32 private constant implementationPosition = keccak256(
        "org.loopring.protocol.v3.implementation"
    );

    modifier onlyUnderlyingOwner()
    {
        address underlyingOwner = Ownable(address(this)).owner();
        require(underlyingOwner != address(0), "NO_OWNER");
        require(underlyingOwner == msg.sender, "UNAUTHORIZED");
        _;
    }

    constructor(
        address _registry,
        address _implementation
        )
        public
        IExchangeProxy(_registry)
    {
        setImplementation(_implementation);
    }

    function implementation()
        public
        view
        returns (address impl)
    {
        bytes32 position = implementationPosition;
        assembly { impl := sload(position) }
    }

    function upgradeTo(
        address newImplementation
        )
        external
        onlyUnderlyingOwner
    {
        require(implementation() != newImplementation, "SAME_IMPLEMENTATION");

        IUniversalRegistry r = IUniversalRegistry(registry());
        require(
            r.isProtocolAndImplementationEnabled(protocol(), newImplementation),
            "INVALID_PROTOCOL_OR_IMPLEMENTATION"
        );

        setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    function setImplementation(
        address newImplementation
        )
        private
    {
        bytes32 position = implementationPosition;
        assembly {sstore(position, newImplementation) }
    }
}

contract ImplementationManager is IImplementationManager
{
    struct Status
    {
        bool registered;
        bool enabled;
    }

    
    mapping (address => Status) private statusMap;

    constructor(
        address _owner,
        address _protocol,
        address _implementation
        )
        public
    {
        require(_owner != address(0), "ZERO_ADDRESS");
        require(_protocol != address(0), "ZERO_PROTOCOL");

        owner = _owner;
        protocol = _protocol;
        defaultImpl = _implementation;

        registerInternal(_implementation);
    }

    

    function register(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        registerInternal(implementation);
    }

    function setDefault(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        require(implementation != defaultImpl, "SAME_IMPLEMENTATION");
        require(isEnabled(implementation), "INVALID_IMPLEMENTATION");

        address oldDefault = defaultImpl;
        defaultImpl = implementation;

        emit DefaultChanged(
            oldDefault,
            implementation
        );
    }

    function enable(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        Status storage status = statusMap[implementation];
        require(status.registered && !status.enabled, "INVALID_IMPLEMENTATION");

        status.enabled = true;
        emit Enabled(implementation);
    }

    function disable(
        address implementation
        )
        external
        nonReentrant
        onlyOwner
    {
        require(implementation != defaultImpl, "FORBIDDEN");
        require(isEnabled(implementation), "INVALID_IMPLEMENTATION");

        statusMap[implementation].enabled = false;
        emit Disabled(implementation);
    }

    function version()
        public
        view
        returns (
            string  memory protocolVersion,
            string  memory defaultImplVersion
        )
    {
        protocolVersion = ILoopring(protocol).version();
        defaultImplVersion = IExchange(defaultImpl).version();
    }

    function latest()
        public
        view
        returns (address)
    {
        return implementations[implementations.length - 1];
    }

    function isRegistered(
        address implementation
        )
        public
        view
        returns (bool)
    {
        return statusMap[implementation].registered;
    }

    function isEnabled(
        address implementation
        )
        public
        view
        returns (bool)
    {
        return statusMap[implementation].enabled;
    }

    function registerInternal(
        address implementation
        )
        internal
    {
        require(implementation != address(0), "INVALID_IMPLEMENTATION");

        string memory _version = IExchange(implementation).version();
        require(bytes(_version).length >= 3, "INVALID_VERSION");
        require(versionMap[_version] == address(0), "VERSION_USED");
        require(!statusMap[implementation].registered, "ALREADY_REGISTERED");

        implementations.push(implementation);
        statusMap[implementation] = Status(true, true);
        versionMap[_version] = implementation;

        emit Registered(implementation, _version);
    }
}

contract UniversalRegistry is IUniversalRegistry {
    struct Protocol
    {
        address protocol;
        bool    registered;
        bool    enabled;
        address manager;
        string  version;
    }

    
    mapping (address => address) private exchangeMap;
     
    mapping (address => Protocol) private protocolMap;

    address private defaultProtocolAddress;

    
    constructor(
        address _lrcAddress
        )
        Claimable()
        public
    {
        require(_lrcAddress != address(0), "ZERO_ADDRESS");
        lrcAddress = _lrcAddress;
    }

    function registerProtocol(
        address protocol,
        address implementation
        )
        external
        nonReentrant
        onlyOwner
        returns (address manager)
    {
        require(!protocolMap[protocol].registered, "PROTOCOL_REGISTERED");

        ILoopring loopring = ILoopring(protocol);
        require(loopring.universalRegistry() == address(this), "REGISTRY_MISMATCH");
        require(loopring.owner() == owner, "OWNER_MISMATCH");
        require(loopring.lrcAddress() == lrcAddress, "LRC_ADDRESS_MISMATCH");

        IImplementationManager m = new ImplementationManager(owner, protocol, implementation);
        manager = address(m);

        string memory version = loopring.version();
        require(versionMap[version] == address(0), "VERSION_REGISTERED");
        require(!protocolMap[protocol].registered, "PROTOCOL_REGISTERED");

        protocols.push(protocol);
        versionMap[version] = protocol;
        protocolMap[protocol] = Protocol(protocol, true, true, manager, version);

        if (defaultProtocolAddress == address(0)) {
            defaultProtocolAddress = protocol;
        }

        emit ProtocolRegistered(protocol, manager, version);
    }

    function setDefaultProtocol(
        address protocol
        )
        external
        nonReentrant
        onlyOwner
    {
        require(protocol != defaultProtocolAddress, "SAME_PROTOCOL");
        require(protocolMap[protocol].registered, "NOT_REGISTERED");
        require(protocolMap[protocol].enabled, "PROTOCOL_DISABLED");
        address oldDefault = defaultProtocolAddress;
        defaultProtocolAddress = protocol;
        emit DefaultProtocolChanged(oldDefault, defaultProtocolAddress);
    }

    function enableProtocol(
        address protocol
        )
        external
        nonReentrant
        onlyOwner
    {
        require(protocolMap[protocol].registered, "NOT_REGISTERED");
        require(!protocolMap[protocol].enabled, "ALREADY_ENABLED");

        protocolMap[protocol].enabled = true;
        emit ProtocolEnabled(protocol);
    }

    function disableProtocol(
        address protocol
        )
        external
        nonReentrant
        onlyOwner
    {
        require(protocolMap[protocol].enabled, "ALREADY_DISABLED");

        protocolMap[protocol].enabled = false;
        emit ProtocolDisabled(protocol);
    }

    function forgeExchange(
        ForgeMode forgeMode,
        bool      onchainDataAvailability,
        address   protocol,
        address   implementation
        )
        external
        nonReentrant
        returns (
            address exchangeAddress,
            uint    exchangeId
        )
    {
        (address _protocol, address _implementation) = getProtocolAndImplementationToUse(
            protocol,
            implementation
        );

        ILoopring loopring = ILoopring(_protocol);
        uint exchangeCreationCostLRC = loopring.exchangeCreationCostLRC();

        if (exchangeCreationCostLRC > 0) {
            require(
                BurnableERC20(lrcAddress).burnFrom(msg.sender, exchangeCreationCostLRC),
                "BURN_FAILURE"
            );
        }

        exchangeAddress = forgeInternal(forgeMode, _implementation);
        assert(exchangeMap[exchangeAddress] == address(0));

        exchangeMap[exchangeAddress] = _protocol;
        exchanges.push(exchangeAddress);
        exchangeId = exchanges.length;

        loopring.initializeExchange(
            exchangeAddress,
            exchangeId,
            msg.sender,  
            msg.sender,  
            onchainDataAvailability
        );

        emit ExchangeForged(
            _protocol,
            _implementation,
            exchangeAddress,
            msg.sender,
            forgeMode,
            onchainDataAvailability,
            exchangeId,
            exchangeCreationCostLRC
        );
    }

    function defaultProtocol()
        public
        view
        returns (
            address protocol,
            address manager,
            address defaultImpl,
            string  memory protocolVersion,
            string  memory defaultImplVersion
        )
    {
        protocol = defaultProtocolAddress;
        Protocol storage p = protocolMap[protocol];
        manager = p.manager;

        IImplementationManager m = IImplementationManager(manager);
        defaultImpl = m.defaultImpl();
        (protocolVersion, defaultImplVersion) = m.version();
    }

    function isProtocolRegistered(
        address protocol
        )
        public
        view
        returns (bool)
    {
        return protocolMap[protocol].registered;
    }

    function isProtocolEnabled(
        address protocol
        )
        public
        view
        returns (bool)
    {
        return protocolMap[protocol].enabled;
    }

    function isExchangeRegistered(
        address exchange
        )
        public
        view
        returns (bool)
    {
        return exchangeMap[exchange] != address(0);
    }

    function isProtocolAndImplementationEnabled(
        address protocol,
        address implementation
        )
        public
        view
        returns (bool enabled)
    {
        if (!isProtocolEnabled(protocol)) {
            return false;
        }

        address managerAddr = protocolMap[protocol].manager;
        IImplementationManager m = IImplementationManager(managerAddr);
        return m.isEnabled(implementation);
    }

    function getExchangeProtocol(
        address exchangeAddress
        )
        public
        view
        returns (
            address protocol,
            address manager
        )
    {
        require(exchangeAddress != address(0), "ZERO_ADDRESS");
        protocol = exchangeMap[exchangeAddress];
        require(protocol != address(0), "INVALID_EXCHANGE");
        manager = protocolMap[protocol].manager;
    }

    

    function getProtocolAndImplementationToUse(
        address protocol,
        address implementation
        )
        private
        view
        returns (
            address protocolToUse,
            address implementationToUse
        )
    {
        protocolToUse = protocol;
        if (protocolToUse == address(0)) {
            protocolToUse = defaultProtocolAddress;
        } else {
            require(isProtocolEnabled(protocolToUse), "INVALID_PROTOCOL");
        }

        implementationToUse = implementation;
        IImplementationManager m = IImplementationManager(protocolMap[protocolToUse].manager);
        if (implementationToUse == address(0)) {
            implementationToUse = m.defaultImpl();
        } else {
            require(m.isEnabled(implementationToUse), "INVALID_IMPLEMENTATION");
        }
    }

    function forgeInternal(
        ForgeMode forgeMode,
        address   implementation
        )
        private
        returns (address)
    {
        if (forgeMode == ForgeMode.AUTO_UPGRADABLE) {
            return address(new AutoUpgradabilityProxy(address(this)));
        } else if (forgeMode == ForgeMode.MANUAL_UPGRADABLE) {
            return address(new ManualUpgradabilityProxy(address(this), implementation));
        } else if (forgeMode == ForgeMode.PROXIED) {
            return address(new SimpleProxy(implementation));
        } else if (forgeMode == ForgeMode.NATIVE) {
            return IExchange(implementation).clone();
        } else {
            revert("INVALID_FORGE_MODE");
        }
    }
}