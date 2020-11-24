 

pragma solidity 0.4.15;

 
 
 
contract Ownable {

   

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   

   
  function Ownable() {
    owner = msg.sender;
  }

   
   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

   

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   

  address public owner;
}

 
 
contract ERC20 {

   

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);

   

  function transfer(address _to, uint256 _value) public returns (bool);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  function balanceOf(address _owner) public constant returns (uint256);
  function allowance(address _owner, address _spender) public constant returns (uint256);

   

  uint256 public totalSupply;
}

contract WithToken {
    ERC20 public token;
}

contract SSPTypeAware {
    enum SSPType { Gate, Direct }
}

contract SSPRegistry is SSPTypeAware{
     
    function register(address key, SSPType sspType, uint16 publisherFee, address recordOwner);

     
    function updatePublisherFee(address key, uint16 newFee, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

     
    function unregister(address key, address sender);

     
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

     
    function isRegistered(address key) constant returns(bool);

    function getSSP(address key) constant returns(address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner);

    function getAllSSP() constant returns(address[] addresses, SSPType[] sspTypes, uint16[] publisherFees, uint256[2][] karmas, address[] recordOwners);

    function kill();
}

contract PublisherRegistry {
     
    function register(address key, bytes32[5] url, address recordOwner);

     
    function updateUrl(address key, bytes32[5] url, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

     
    function unregister(address key, address sender);

     
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

     
    function isRegistered(address key) constant returns(bool);

    function getPublisher(address key) constant returns(address publisherAddress, bytes32[5] url, uint256[2] karma, address recordOwner);

     
     
    function getAllPublishers() constant returns(address[] addresses, bytes32[5][] urls, uint256[2][] karmas, address[] recordOwners);

    function kill();
}

contract DSPTypeAware {
    enum DSPType { Gate, Direct }
}

contract DSPRegistry is DSPTypeAware{
     
    function register(address key, DSPType dspType, bytes32[5] url, address recordOwner);

     
    function updateUrl(address key, bytes32[5] url, address sender);

    function applyKarmaDiff(address key, uint256[2] diff);

     
    function unregister(address key, address sender);

     
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

     
    function isRegistered(address key) constant returns(bool);

    function getDSP(address key) constant returns(address dspAddress, DSPType dspType, bytes32[5] url, uint256[2] karma, address recordOwner);

     
     
    function getAllDSP() constant returns(address[] addresses, DSPType[] dspTypes, bytes32[5][] urls, uint256[2][] karmas, address[] recordOwners) ;

    function kill();
}

contract DepositRegistry {
     
    function register(address key, uint256 amount, address depositOwner);

     
    function unregister(address key);

    function transfer(address key, address newOwner, address sender);

    function spend(address key, uint256 amount);

    function refill(address key, uint256 amount);

     
    function isRegistered(address key) constant returns(bool);

    function getDepositOwner(address key) constant returns(address);

    function getDeposit(address key) constant returns(uint256 amount);

    function getDepositRecord(address key) constant returns(address owner, uint time, uint256 amount, address depositOwner);

    function hasEnough(address key, uint256 amount) constant returns(bool);

    function kill();
}

contract AuditorRegistry {
     
    function register(address key, address recordOwner);

    function applyKarmaDiff(address key, uint256[2] diff);

     
    function unregister(address key, address sender);

     
    function transfer(address key, address newOwner, address sender);

    function getOwner(address key) constant returns(address);

     
    function isRegistered(address key) constant returns(bool);

    function getAuditor(address key) constant returns(address auditorAddress, uint256[2] karma, address recordOwner);

     
     
    function getAllAuditors() constant returns(address[] addresses, uint256[2][] karmas, address[] recordOwners);

    function kill();
}

contract DepositAware is WithToken{
    function returnDeposit(address depositAccount, DepositRegistry depositRegistry) internal {
        if (depositRegistry.isRegistered(depositAccount)) {
            uint256 amount = depositRegistry.getDeposit(depositAccount);
            address depositOwner = depositRegistry.getDepositOwner(depositAccount);
            if (amount > 0) {
                token.transfer(depositOwner, amount);
                depositRegistry.unregister(depositAccount);
            }
        }
    }
}

contract SecurityDepositAware is DepositAware{
    uint256 constant SECURITY_DEPOSIT_SIZE = 10;

    DepositRegistry public securityDepositRegistry;

    function receiveSecurityDeposit(address depositAccount) internal {
        token.transferFrom(msg.sender, this, SECURITY_DEPOSIT_SIZE);
        securityDepositRegistry.register(depositAccount, SECURITY_DEPOSIT_SIZE, msg.sender);
    }

    function transferSecurityDeposit(address depositAccount, address newOwner) {
        securityDepositRegistry.transfer(depositAccount, newOwner, msg.sender);
    }
}

contract AuditorRegistrar is SecurityDepositAware{
    AuditorRegistry public auditorRegistry;

    event AuditorRegistered(address auditorAddress);
    event AuditorUnregistered(address auditorAddress);

     
     
    function findAuditor(address addr) constant returns(address auditorAddress, uint256[2] karma, address recordOwner) {
        return auditorRegistry.getAuditor(addr);
    }

     
    function isAuditorRegistered(address key) constant returns(bool) {
        return auditorRegistry.isRegistered(key);
    }

     
     
    function registerAuditor(address auditorAddress) {
        receiveSecurityDeposit(auditorAddress);
        auditorRegistry.register(auditorAddress, msg.sender);
        AuditorRegistered(auditorAddress);
    }

     
     
    function unregisterAuditor(address auditorAddress) {
        returnDeposit(auditorAddress, securityDepositRegistry);
        auditorRegistry.unregister(auditorAddress, msg.sender);
        AuditorUnregistered(auditorAddress);
    }

     
     
     
    function transferAuditorRecord(address key, address newOwner) {
        auditorRegistry.transfer(key, newOwner, msg.sender);
    }
}

contract DSPRegistrar is DSPTypeAware, SecurityDepositAware {
    DSPRegistry public dspRegistry;

    event DSPRegistered(address dspAddress);
    event DSPUnregistered(address dspAddress);
    event DSPParametersChanged(address dspAddress);

     
     
    function findDsp(address addr) constant returns(address dspAddress, DSPType dspType, bytes32[5] url, uint256[2] karma, address recordOwner) {
        return dspRegistry.getDSP(addr);
    }

     
     
    function registerDsp(address dspAddress, DSPType dspType, bytes32[5] url) {
        receiveSecurityDeposit(dspAddress);
        dspRegistry.register(dspAddress, dspType, url, msg.sender);
        DSPRegistered(dspAddress);
    }

     
    function isDspRegistered(address key) constant returns(bool) {
        return dspRegistry.isRegistered(key);
    }

     
     
    function unregisterDsp(address dspAddress) {
        returnDeposit(dspAddress, securityDepositRegistry);
        dspRegistry.unregister(dspAddress, msg.sender);
        DSPUnregistered(dspAddress);
    }

     
     
     
    function updateUrl(address key, bytes32[5] url) {
        dspRegistry.updateUrl(key, url, msg.sender);
        DSPParametersChanged(key);
    }

     
     
     
    function transferDSPRecord(address key, address newOwner) {
        dspRegistry.transfer(key, newOwner, msg.sender);
    }
}

contract PublisherRegistrar is SecurityDepositAware{
    PublisherRegistry public publisherRegistry;

    event PublisherRegistered(address publisherAddress);
    event PublisherUnregistered(address publisherAddress);
    event PublisherParametersChanged(address publisherAddress);

     
     
    function findPublisher(address addr) constant returns(address publisherAddress, bytes32[5] url, uint256[2] karma, address recordOwner) {
        return publisherRegistry.getPublisher(addr);
    }

    function isPublisherRegistered(address key) constant returns(bool) {
        return publisherRegistry.isRegistered(key);
    }

     
     
    function registerPublisher(address publisherAddress, bytes32[5] url) {
        receiveSecurityDeposit(publisherAddress);
        publisherRegistry.register(publisherAddress, url, msg.sender);
        PublisherRegistered(publisherAddress);
    }

     
     
    function unregisterPublisher(address publisherAddress) {
        returnDeposit(publisherAddress, securityDepositRegistry);
        publisherRegistry.unregister(publisherAddress, msg.sender);
        PublisherUnregistered(publisherAddress);
    }

     
     
     
    function transferPublisherRecord(address key, address newOwner) {
        publisherRegistry.transfer(key, newOwner, msg.sender);
    }
}

contract SSPRegistrar is SSPTypeAware, SecurityDepositAware{
    SSPRegistry public sspRegistry;

    event SSPRegistered(address sspAddress);
    event SSPUnregistered(address sspAddress);
    event SSPParametersChanged(address sspAddress);

     
     
    function findSsp(address sspAddr) constant returns(address sspAddress, SSPType sspType, uint16 publisherFee, uint256[2] karma, address recordOwner) {
        return sspRegistry.getSSP(sspAddr);
    }

     
     
    function registerSsp(address sspAddress, SSPType sspType, uint16 publisherFee) {
        receiveSecurityDeposit(sspAddress);
        sspRegistry.register(sspAddress, sspType, publisherFee, msg.sender);
        SSPRegistered(sspAddress);
    }

     
    function isSspRegistered(address key) constant returns(bool) {
        return sspRegistry.isRegistered(key);
    }

     
     
    function unregisterSsp(address sspAddress) {
        returnDeposit(sspAddress, securityDepositRegistry);
        sspRegistry.unregister(sspAddress, msg.sender);
        SSPUnregistered(sspAddress);
    }

     
     
     
    function updatePublisherFee(address key, uint16 newFee) {
        sspRegistry.updatePublisherFee(key, newFee, msg.sender);
        SSPParametersChanged(key);
    }

     
     
     
    function transferSSPRecord(address key, address newOwner) {
        sspRegistry.transfer(key, newOwner, msg.sender);
    }
}

contract ChannelApi {
    function applyRuntimeUpdate(address from, address to, uint impressionsCount, uint fraudCount);

    function applyAuditorsCheckUpdate(address from, address to, uint fraudCountDelta);
}

contract RegistryProvider {
    function replaceSSPRegistry(SSPRegistry newRegistry);

    function replaceDSPRegistry(DSPRegistry newRegistry);

    function replacePublisherRegistry(PublisherRegistry newRegistry) ;

    function replaceAuditorRegistry(AuditorRegistry newRegistry);

    function replaceSecurityDepositRegistry(DepositRegistry newRegistry);

    function getSSPRegistry() internal constant returns (SSPRegistry);

    function getDSPRegistry() internal constant returns (DSPRegistry);

    function getPublisherRegistry() internal constant returns (PublisherRegistry);

    function getAuditorRegistry() internal constant returns (AuditorRegistry);

    function getSecurityDepositRegistry() internal constant returns (DepositRegistry);
}

contract StateChannelListener is RegistryProvider, ChannelApi {
    address channelContractAddress;

    event ChannelContractAddressChanged(address indexed previousAddress, address indexed newAddress);

    function applyRuntimeUpdate(address from, address to, uint impressionsCount, uint fraudCount) onlyChannelContract {
        uint256[2] storage karmaDiff;
        karmaDiff[0] = impressionsCount;
        karmaDiff[1] = 0;
        if (getDSPRegistry().isRegistered(from)) {
            getDSPRegistry().applyKarmaDiff(from, karmaDiff);
        } else if (getSSPRegistry().isRegistered(from)) {
            getSSPRegistry().applyKarmaDiff(from, karmaDiff);
        }

        karmaDiff[1] = fraudCount;
        if (getSSPRegistry().isRegistered(to)) {
            karmaDiff[0] = 0;
            getSSPRegistry().applyKarmaDiff(to, karmaDiff);
        } else if (getPublisherRegistry().isRegistered(to)) {
            karmaDiff[0] = impressionsCount;
            getPublisherRegistry().applyKarmaDiff(to, karmaDiff);
        }
    }

    function applyAuditorsCheckUpdate(address from, address to, uint fraudCountDelta) onlyChannelContract {
         
    }

    modifier onlyChannelContract() {
        require(msg.sender == channelContractAddress);
        _;
    }
}

contract PapyrusDAO is WithToken,
                       RegistryProvider,
                       StateChannelListener,
                       SSPRegistrar,
                       DSPRegistrar,
                       PublisherRegistrar,
                       AuditorRegistrar,
                       Ownable {

    function PapyrusDAO(ERC20 papyrusToken,
                        SSPRegistry _sspRegistry,
                        DSPRegistry _dspRegistry,
                        PublisherRegistry _publisherRegistry,
                        AuditorRegistry _auditorRegistry,
                        DepositRegistry _securityDepositRegistry
    ) {
        token = papyrusToken;
        sspRegistry = _sspRegistry;
        dspRegistry = _dspRegistry;
        publisherRegistry = _publisherRegistry;
        auditorRegistry = _auditorRegistry;
        securityDepositRegistry = _securityDepositRegistry;
    }

    event DepositsTransferred(address newDao, uint256 sum);
    event SSPRegistryReplaced(address from, address to);
    event DSPRegistryReplaced(address from, address to);
    event PublisherRegistryReplaced(address from, address to);
    event AuditorRegistryReplaced(address from, address to);
    event SecurityDepositRegistryReplaced(address from, address to);

    function replaceSSPRegistry(SSPRegistry newRegistry) onlyOwner {
        address old = sspRegistry;
        sspRegistry = newRegistry;
        SSPRegistryReplaced(old, newRegistry);
    }

    function replaceDSPRegistry(DSPRegistry newRegistry) onlyOwner {
        address old = dspRegistry;
        dspRegistry = newRegistry;
        DSPRegistryReplaced(old, newRegistry);
    }

    function replacePublisherRegistry(PublisherRegistry newRegistry) onlyOwner {
        address old = publisherRegistry;
        publisherRegistry = newRegistry;
        PublisherRegistryReplaced(old, publisherRegistry);
    }

    function replaceAuditorRegistry(AuditorRegistry newRegistry) onlyOwner {
        address old = auditorRegistry;
        auditorRegistry = newRegistry;
        AuditorRegistryReplaced(old, auditorRegistry);
    }

    function replaceSecurityDepositRegistry(DepositRegistry newRegistry) onlyOwner {
        address old = securityDepositRegistry;
        securityDepositRegistry = newRegistry;
        SecurityDepositRegistryReplaced(old, securityDepositRegistry);
    }

    function replaceChannelContractAddress(address newChannelContract) onlyOwner public {
        require(newChannelContract != address(0));
        ChannelContractAddressChanged(channelContractAddress, newChannelContract);
        channelContractAddress = newChannelContract;
    }

    function getSSPRegistry() internal constant returns (SSPRegistry) {
        return sspRegistry;
    }

    function getDSPRegistry() internal constant returns (DSPRegistry) {
        return dspRegistry;
    }

    function getPublisherRegistry() internal constant returns (PublisherRegistry) {
        return publisherRegistry;
    }

    function getAuditorRegistry() internal constant returns (AuditorRegistry) {
        return auditorRegistry;
    }

    function getSecurityDepositRegistry() internal constant returns (DepositRegistry) {
        return securityDepositRegistry;
    }

    function transferDepositsToNewDao(address newDao) onlyOwner {
        uint256 depositSum = token.balanceOf(this);
        token.transfer(newDao, depositSum);
        DepositsTransferred(newDao, depositSum);
    }

    function kill() onlyOwner {
        selfdestruct(owner);
    }
}