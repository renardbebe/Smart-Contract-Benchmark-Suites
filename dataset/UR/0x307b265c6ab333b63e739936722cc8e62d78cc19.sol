 

 

 

pragma solidity 0.4.25;
pragma experimental "v0.5.0";

contract Owned {

    address public owner;

    event NewOwner(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    function setOwner(address _new)
        public
        onlyOwner
    {
        require(_new != address(0));
        owner = _new;
        emit NewOwner(owner, _new);
    }
}

 
 
 
interface AuthorityFace {

     
    event AuthoritySet(address indexed authority);
    event WhitelisterSet(address indexed whitelister);
    event WhitelistedUser(address indexed target, bool approved);
    event WhitelistedRegistry(address indexed registry, bool approved);
    event WhitelistedFactory(address indexed factory, bool approved);
    event WhitelistedVault(address indexed vault, bool approved);
    event WhitelistedDrago(address indexed drago, bool isWhitelisted);
    event NewDragoEventful(address indexed dragoEventful);
    event NewVaultEventful(address indexed vaultEventful);
    event NewNavVerifier(address indexed navVerifier);
    event NewExchangesAuthority(address indexed exchangesAuthority);

     
    function setAuthority(address _authority, bool _isWhitelisted) external;
    function setWhitelister(address _whitelister, bool _isWhitelisted) external;
    function whitelistUser(address _target, bool _isWhitelisted) external;
    function whitelistDrago(address _drago, bool _isWhitelisted) external;
    function whitelistVault(address _vault, bool _isWhitelisted) external;
    function whitelistRegistry(address _registry, bool _isWhitelisted) external;
    function whitelistFactory(address _factory, bool _isWhitelisted) external;
    function setDragoEventful(address _dragoEventful) external;
    function setVaultEventful(address _vaultEventful) external;
    function setNavVerifier(address _navVerifier) external;
    function setExchangesAuthority(address _exchangesAuthority) external;

     
    function isWhitelistedUser(address _target) external view returns (bool);
    function isAuthority(address _authority) external view returns (bool);
    function isWhitelistedRegistry(address _registry) external view returns (bool);
    function isWhitelistedDrago(address _drago) external view returns (bool);
    function isWhitelistedVault(address _vault) external view returns (bool);
    function isWhitelistedFactory(address _factory) external view returns (bool);
    function getDragoEventful() external view returns (address);
    function getVaultEventful() external view returns (address);
    function getNavVerifier() external view returns (address);
    function getExchangesAuthority() external view returns (address);
}


 
 
 
contract Authority is
    Owned,
    AuthorityFace
{
    BuildingBlocks public blocks;
    Type public types;

    mapping (address => Account) public accounts;

    struct List {
        address target;
    }

    struct Type {
        string types;
        List[] list;
    }

    struct Group {
        bool whitelister;
        bool drago;
        bool vault;
        bool user;
        bool registry;
        bool factory;
        bool authority;
    }

    struct Account {
        address account;
        bool authorized;
        mapping (bool => Group) groups;  
    }

    struct BuildingBlocks {
        address dragoEventful;
        address vaultEventful;
        address navVerifier;
        address exchangesAuthority;
        address casper;
        mapping (address => bool) initialized;
    }

     
    event AuthoritySet(address indexed authority);
    event WhitelisterSet(address indexed whitelister);
    event WhitelistedUser(address indexed target, bool approved);
    event WhitelistedRegistry(address indexed registry, bool approved);
    event WhitelistedFactory(address indexed factory, bool approved);
    event WhitelistedVault(address indexed vault, bool approved);
    event WhitelistedDrago(address indexed drago, bool isWhitelisted);
    event NewDragoEventful(address indexed dragoEventful);
    event NewVaultEventful(address indexed vaultEventful);
    event NewNavVerifier(address indexed navVerifier);
    event NewExchangesAuthority(address indexed exchangesAuthority);

     
    modifier onlyAdmin {
        require(msg.sender == owner || isWhitelister(msg.sender));
        _;
    }

    modifier onlyWhitelister {
        require(isWhitelister(msg.sender));
        _;
    }

     
     
     
     
    function setAuthority(address _authority, bool _isWhitelisted)
        external
        onlyOwner
    {
        setAuthorityInternal(_authority, _isWhitelisted);
    }

     
     
     
    function setWhitelister(address _whitelister, bool _isWhitelisted)
        external
        onlyOwner
    {
        setWhitelisterInternal(_whitelister, _isWhitelisted);
    }

     
     
     
    function whitelistUser(address _target, bool _isWhitelisted)
        external
        onlyWhitelister
    {
        accounts[_target].account = _target;
        accounts[_target].authorized = _isWhitelisted;
        accounts[_target].groups[_isWhitelisted].user = _isWhitelisted;
        types.list.push(List(_target));
        emit WhitelistedUser(_target, _isWhitelisted);
    }

     
     
     
    function whitelistDrago(address _drago, bool _isWhitelisted)
        external
        onlyAdmin
    {
        accounts[_drago].account = _drago;
        accounts[_drago].authorized = _isWhitelisted;
        accounts[_drago].groups[_isWhitelisted].drago = _isWhitelisted;
        types.list.push(List(_drago));
        emit WhitelistedDrago(_drago, _isWhitelisted);
    }

     
     
     
    function whitelistVault(address _vault, bool _isWhitelisted)
        external
        onlyAdmin
    {
        accounts[_vault].account = _vault;
        accounts[_vault].authorized = _isWhitelisted;
        accounts[_vault].groups[_isWhitelisted].vault = _isWhitelisted;
        types.list.push(List(_vault));
        emit WhitelistedVault(_vault, _isWhitelisted);
    }

     
     
     
    function whitelistRegistry(address _registry, bool _isWhitelisted)
        external
        onlyAdmin
    {
        accounts[_registry].account = _registry;
        accounts[_registry].authorized = _isWhitelisted;
        accounts[_registry].groups[_isWhitelisted].registry = _isWhitelisted;
        types.list.push(List(_registry));
        emit WhitelistedRegistry(_registry, _isWhitelisted);
    }

     
     
     
    function whitelistFactory(address _factory, bool _isWhitelisted)
        external
        onlyAdmin
    {
        accounts[_factory].account = _factory;
        accounts[_factory].authorized = _isWhitelisted;
        accounts[_factory].groups[_isWhitelisted].registry = _isWhitelisted;
        types.list.push(List(_factory));
        setAuthorityInternal(_factory, _isWhitelisted);
        emit WhitelistedFactory(_factory, _isWhitelisted);
    }

     
     
    function setDragoEventful(address _dragoEventful)
        external
        onlyOwner
    {
        blocks.dragoEventful = _dragoEventful;
        emit NewDragoEventful(blocks.dragoEventful);
    }

     
     
    function setVaultEventful(address _vaultEventful)
        external
        onlyOwner
    {
        blocks.vaultEventful = _vaultEventful;
        emit NewVaultEventful(blocks.vaultEventful);
    }

     
     
    function setNavVerifier(address _navVerifier)
        external
        onlyOwner
    {
        blocks.navVerifier = _navVerifier;
        emit NewNavVerifier(blocks.navVerifier);
    }

     
     
    function setExchangesAuthority(address _exchangesAuthority)
        external
        onlyOwner
    {
        blocks.exchangesAuthority = _exchangesAuthority;
        emit NewExchangesAuthority(blocks.exchangesAuthority);
    }

     
     
     
     
    function isWhitelistedUser(address _target)
        external view
        returns (bool)
    {
        return accounts[_target].groups[true].user;
    }

     
     
     
    function isAuthority(address _authority)
        external view
        returns (bool)
    {
        return accounts[_authority].groups[true].authority;
    }

     
     
     
    function isWhitelistedDrago(address _drago)
        external view
        returns (bool)
    {
        return accounts[_drago].groups[true].drago;
    }

     
     
     
    function isWhitelistedVault(address _vault)
        external view
        returns (bool)
    {
        return accounts[_vault].groups[true].vault;
    }

     
     
     
    function isWhitelistedRegistry(address _registry)
        external view
        returns (bool)
    {
        return accounts[_registry].groups[true].registry;
    }

     
     
     
    function isWhitelistedFactory(address _factory)
        external view
        returns (bool)
    {
        return accounts[_factory].groups[true].registry;
    }

     
     
    function getDragoEventful()
        external view
        returns (address)
    {
        return blocks.dragoEventful;
    }

     
     
    function getVaultEventful()
        external view
        returns (address)
    {
        return blocks.vaultEventful;
    }

     
     
    function getNavVerifier()
        external view
        returns (address)
    {
        return blocks.navVerifier;
    }

     
     
    function getExchangesAuthority()
        external view
        returns (address)
    {
        return blocks.exchangesAuthority;
    }

     
     
     
     
    function setAuthorityInternal(
        address _authority,
        bool _isWhitelisted)
        internal
    {
        accounts[_authority].account = _authority;
        accounts[_authority].authorized = _isWhitelisted;
        accounts[_authority].groups[_isWhitelisted].authority = _isWhitelisted;
        setWhitelisterInternal(_authority, _isWhitelisted);
        types.list.push(List(_authority));
        emit AuthoritySet(_authority);
    }

     
     
     
    function setWhitelisterInternal(
        address _whitelister,
        bool _isWhitelisted)
        internal
    {
        accounts[_whitelister].account = _whitelister;
        accounts[_whitelister].authorized = _isWhitelisted;
        accounts[_whitelister].groups[_isWhitelisted].whitelister = _isWhitelisted;
        types.list.push(List(_whitelister));
        emit WhitelisterSet(_whitelister);
    }

     
     
     
    function isWhitelister(address _whitelister)
        internal view
        returns (bool)
    {
        return accounts[_whitelister].groups[true].whitelister;
    }
}