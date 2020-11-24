 

 
pragma solidity ^0.5.11;

 
 
 
 
 
contract Ownable
{
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


 
 
 
 
 
 
contract ReentrancyGuard
{
     
    uint private _guardValue;

     
    modifier nonReentrant()
    {
         
        require(_guardValue == 0, "REENTRANCY");

         
        _guardValue = 1;

         
        _;

         
        _guardValue = 0;
    }
}

contract ERC20
{
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

 
 
contract IExchange is Claimable, ReentrancyGuard
{
    string  constant public version          = "";  
    bytes32 constant public genesisBlockHash = 0;   

     
     
    function clone()
        external
        nonReentrant
        returns (address cloneAddress)
    {
        address origin = address(this);
        cloneAddress = Cloneable.clone(origin);

        assert(cloneAddress != origin);
        assert(cloneAddress != address(0));
    }
}

 
 
contract ILoopring is Claimable, ReentrancyGuard
{
    address public protocolRegistry;
    address public lrcAddress;
    uint    public exchangeCreationCostLRC;

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

 
 
contract IProtocolRegistry is Claimable, ReentrancyGuard
{
    address     public lrcAddress;
    address     public defaultProtocol;
    address[]   public exchanges;

    event ExchangeForged (
        address indexed loopring,
        address indexed exchangeAddress,
        address         owner,
        bool            supportUpgradability,
        bool            onchainDataAvailability,
        uint            exchangeId,
        uint            amountLRCBurned
    );

    event ProtocolRegistered (
        address indexed protocol,
        address indexed implementation
    );

    event ProtocolUpgraded (
        address indexed protocol,
        address indexed newImplementation,
        address         oldImplementation
    );

    event DefaultProtocolChanged(
        address indexed newDefault,
        address         oldDefault
    );

    event ProtocolDisabled(
        address indexed protocol
    );

    event ProtocolEnabled(
        address indexed protocol
    );

     
     
     
     
    function registerProtocol(
        address protocol,
        address implementation
        )
        external;

     
     
     
     
    function upgradeProtocol(
        address protocol,
        address newImplementation
        )
        external
        returns (address oldImplementation);

     
     
    function disableProtocol(
        address protocol
        )
        external;

     
     
    function enableProtocol(
        address protocol
        )
        external;

     
     
    function setDefaultProtocol(
        address protocol
        )
        external;

     
     
     
     
     
    function getDefaultProtocol()
        external
        view
        returns (
            address protocol,
            address implementation,
            bool    enabled
        );

     
     
     
     
    function getProtocol(
        address protocol
        )
        external
        view
        returns (
            address implementation,
            bool    enabled
        );

     
     
     
     
     
    function getExchangeProtocol(
        address exchangeAddress
        )
        external
        view
        returns (
            address protocol,
            address implementation,
            bool    enabled
        );

     
     
     
     
     
     
     
    function forgeExchange(
        bool supportUpgradability,
        bool onchainDataAvailability
        )
        external
        returns (
            address exchangeAddress,
            uint    exchangeId
        );

     
     
     
     
     
     
     
     
    function forgeExchange(
        address protocol,
        bool    supportUpgradability,
        bool    onchainDataAvailability
        )
        external
        returns (
            address exchangeAddress,
            uint    exchangeId
        );
}

 
 
 
 
contract ExchangeProxy is Proxy
{
    bytes32 private constant registryPosition = keccak256(
        "org.loopring.protocol.v3.registry"
    );

    constructor(address _registry)
        public
    {
        bytes32 position = registryPosition;
        assembly {
          sstore(position, _registry)
        }
    }

    function registry()
        public
        view
        returns (address _addr)
    {
        bytes32 position = registryPosition;
        assembly {
          _addr := sload(position)
        }
    }

    function protocol()
        public
        view
        returns (address _protocol)
    {
        IProtocolRegistry r = IProtocolRegistry(registry());
        (_protocol, , ) = r.getExchangeProtocol(address(this));
    }

    function implementation()
        public
        view
        returns (address impl)
    {
        IProtocolRegistry r = IProtocolRegistry(registry());
        (, impl, ) = r.getExchangeProtocol(address(this));
    }
}


 
 
contract ProtocolRegistry is IProtocolRegistry
{
    struct Protocol
    {
       address implementation;   
       bool    enabled;          
    }

    struct Implementation
    {
        address protocol;  
        string  version;   
    }

    mapping (address => Protocol)       private protocols;
    mapping (address => Implementation) private impls;
    mapping (string => address)         private versions;
    mapping (address => address)        private exchangeToProtocol;

    modifier addressNotZero(address addr)
    {
        require(addr != address(0), "ZERO_ADDRESS");
        _;
    }

    modifier protocolNotRegistered(address addr)
    {
        require(protocols[addr].implementation == address(0), "PROTOCOL_REGISTERED");
        _;
    }

    modifier protocolRegistered(address addr)
    {
        require(protocols[addr].implementation != address(0), "PROTOCOL_NOT_REGISTERED");
        _;
    }

    modifier protocolDisabled(address addr)
    {
        require(!protocols[addr].enabled, "PROTOCOL_ENABLED");
        _;
    }

    modifier protocolEnabled(address addr)
    {
        require(protocols[addr].enabled, "PROTOCOL_DISABLED");
        _;
    }

    modifier implNotRegistered(address addr)
    {
        require(impls[addr].protocol == address(0), "IMPL_REGISTERED");
        _;
    }

    modifier implRegistered(address addr)
    {
        require(impls[addr].protocol != address(0), "IMPL_NOT_REGISTERED");
        _;
    }

     
    constructor(
        address _lrcAddress
        )
        Claimable()
        public
        addressNotZero(_lrcAddress)
    {
        lrcAddress = _lrcAddress;
    }

    function registerProtocol(
        address protocol,
        address implementation
        )
        external
        nonReentrant
        onlyOwner
        addressNotZero(protocol)
        addressNotZero(implementation)
        protocolNotRegistered(protocol)
        implNotRegistered(implementation)
    {
        ILoopring loopring = ILoopring(protocol);
        require(loopring.owner() == owner, "INCONSISTENT_OWNER");
        require(loopring.protocolRegistry() == address(this), "INCONSISTENT_REGISTRY");
        require(loopring.lrcAddress() == lrcAddress, "INCONSISTENT_LRC_ADDRESS");

        string memory version = IExchange(implementation).version();
        require(versions[version] == address(0), "VERSION_USED");

         
        impls[implementation] = Implementation(protocol, version);
        versions[version] = implementation;

        protocols[protocol] = Protocol(implementation, true);
        emit ProtocolRegistered(protocol, implementation);
    }

    function upgradeProtocol(
        address protocol,
        address newImplementation
        )
        external
        nonReentrant
        onlyOwner
        addressNotZero(protocol)
        addressNotZero(newImplementation)
        protocolRegistered(protocol)
        returns (address oldImplementation)
    {
        require(protocols[protocol].implementation != newImplementation, "SAME_IMPLEMENTATION");

        oldImplementation = protocols[protocol].implementation;

        if (impls[newImplementation].protocol == address(0)) {
             
            string memory version = IExchange(newImplementation).version();
            require(versions[version] == address(0), "VERSION_USED");

            impls[newImplementation] = Implementation(protocol, version);
            versions[version] = newImplementation;
        } else {
            require(impls[newImplementation].protocol == protocol, "IMPLEMENTATION_BINDED");
        }

        protocols[protocol].implementation = newImplementation;
        emit ProtocolUpgraded(protocol, newImplementation, oldImplementation);
    }

    function disableProtocol(
        address protocol
        )
        external
        nonReentrant
        onlyOwner
        addressNotZero(protocol)
        protocolRegistered(protocol)
        protocolEnabled(protocol)
    {
        require(protocol != defaultProtocol, "FORBIDDEN");
        protocols[protocol].enabled = false;
        emit ProtocolDisabled(protocol);
    }

    function enableProtocol(
        address protocol
        )
        external
        nonReentrant
        onlyOwner
        addressNotZero(protocol)
        protocolRegistered(protocol)
        protocolDisabled(protocol)
    {
        protocols[protocol].enabled = true;
        emit ProtocolEnabled(protocol);
    }

    function setDefaultProtocol(
        address protocol
        )
        external
        nonReentrant
        onlyOwner
        addressNotZero(protocol)
        protocolRegistered(protocol)
        protocolEnabled(protocol)
    {
        address oldDefaultProtocol = defaultProtocol;
        defaultProtocol = protocol;
        emit DefaultProtocolChanged(protocol, oldDefaultProtocol);
    }

    function getDefaultProtocol()
        external
        view
        returns (
            address protocol,
            address implementation,
            bool    enabled
        )
    {
        require(defaultProtocol != address(0), "NO_DEFAULT_PROTOCOL");
        protocol = defaultProtocol;
        Protocol storage p = protocols[protocol];
        implementation = p.implementation;
        enabled = p.enabled;
    }

    function getProtocol(
        address protocol
        )
        external
        view
        addressNotZero(protocol)
        protocolRegistered(protocol)
        returns (
            address implementation,
            bool    enabled
        )
    {
        Protocol storage p = protocols[protocol];
        implementation = p.implementation;
        enabled = p.enabled;
    }

    function getExchangeProtocol(
        address exchangeAddress
        )
        external
        view
        addressNotZero(exchangeAddress)
        returns (
            address protocol,
            address implementation,
            bool    enabled
        )
    {
        protocol = exchangeToProtocol[exchangeAddress];
        require(protocol != address(0), "INVALID_EXCHANGE");

        Protocol storage p = protocols[protocol];
        implementation = p.implementation;
        enabled = p.enabled;
    }

    function forgeExchange(
        bool    supportUpgradability,
        bool    onchainDataAvailability
        )
        external
        nonReentrant
        returns (
            address exchangeAddress,
            uint    exchangeId
        )
    {
        return forgeExchangeInternal(
            defaultProtocol,
            supportUpgradability,
            onchainDataAvailability
        );
    }

    function forgeExchange(
        address protocol,
        bool    supportUpgradability,
        bool    onchainDataAvailability
        )
        external
        nonReentrant
        returns (
            address exchangeAddress,
            uint    exchangeId
        )
    {
        return forgeExchangeInternal(
            protocol,
            supportUpgradability,
            onchainDataAvailability
        );
    }

     

    function forgeExchangeInternal(
        address protocol,
        bool    supportUpgradability,
        bool    onchainDataAvailability
        )
        private
        protocolRegistered(protocol)
        protocolEnabled(protocol)
        returns (
            address exchangeAddress,
            uint    exchangeId
        )
    {
        ILoopring loopring = ILoopring(protocol);
        uint exchangeCreationCostLRC = loopring.exchangeCreationCostLRC();

        if (exchangeCreationCostLRC > 0) {
            require(
                BurnableERC20(lrcAddress).burnFrom(msg.sender, exchangeCreationCostLRC),
                "BURN_FAILURE"
            );
        }

        IExchange implementation = IExchange(protocols[protocol].implementation);
        if (supportUpgradability) {
             
            exchangeAddress = address(new ExchangeProxy(address(this)));
        } else {
             
            exchangeAddress = implementation.clone();
        }

        assert(exchangeToProtocol[exchangeAddress] == address(0));

        exchangeToProtocol[exchangeAddress] = protocol;
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
            protocol,
            exchangeAddress,
            msg.sender,
            supportUpgradability,
            onchainDataAvailability,
            exchangeId,
            exchangeCreationCostLRC
        );
    }
}