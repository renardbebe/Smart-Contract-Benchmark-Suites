 

 
pragma solidity ^0.5.11;


 
 
 
 
 
 
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