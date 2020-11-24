 

 

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

 
 
 
interface ExchangesAuthorityFace {

     
    event AuthoritySet(address indexed authority);
    event WhitelisterSet(address indexed whitelister);
    event WhitelistedAsset(address indexed asset, bool approved);
    event WhitelistedExchange(address indexed exchange, bool approved);
    event WhitelistedWrapper(address indexed wrapper, bool approved);
    event WhitelistedProxy(address indexed proxy, bool approved);
    event WhitelistedMethod(bytes4 indexed method, address indexed exchange, bool approved);
    event NewSigVerifier(address indexed sigVerifier);
    event NewExchangeEventful(address indexed exchangeEventful);
    event NewCasper(address indexed casper);

     
     
     
     
    function setAuthority(address _authority, bool _isWhitelisted)
        external;

     
     
     
    function setWhitelister(address _whitelister, bool _isWhitelisted)
        external;

     
     
     
    function whitelistAsset(address _asset, bool _isWhitelisted)
        external;

     
     
     
    function whitelistExchange(address _exchange, bool _isWhitelisted)
        external;

     
     
     
    function whitelistWrapper(address _wrapper, bool _isWhitelisted)
        external;

     
     
     
    function whitelistTokenTransferProxy(
        address _tokenTransferProxy, bool _isWhitelisted)
        external;

     
     
     
     
    function whitelistAssetOnExchange(
        address _asset,
        address _exchange,
        bool _isWhitelisted)
        external;

     
     
     
     
    function whitelistTokenOnWrapper(
        address _token,
        address _wrapper,
        bool _isWhitelisted)
        external;

     
     
     
    function whitelistMethod(
        bytes4 _method,
        address _adapter,
        bool _isWhitelisted)
        external;

     
     
    function setSignatureVerifier(address _sigVerifier)
        external;

     
     
    function setExchangeEventful(address _exchangeEventful)
        external;

     
     
     
    function setExchangeAdapter(address _exchange, address _adapter)
        external;

     
     
    function setCasper(address _casper)
        external;

     
     
     
     
    function isAuthority(address _authority)
        external view
        returns (bool);

     
     
     
    function isWhitelistedAsset(address _asset)
        external view
        returns (bool);

     
     
     
    function isWhitelistedExchange(address _exchange)
        external view
        returns (bool);

     
     
     
    function isWhitelistedWrapper(address _wrapper)
        external view
        returns (bool);

     
     
     
    function isWhitelistedProxy(address _tokenTransferProxy)
        external view
        returns (bool);

     
     
     
    function getExchangeAdapter(address _exchange)
        external view
        returns (address);

     
     
    function getSigVerifier()
        external view
        returns (address);

     
     
     
     
    function canTradeTokenOnExchange(address _token, address _exchange)
        external view
        returns (bool);

     
     
     
    function canWrapTokenOnWrapper(address _token, address _wrapper)
        external view
        returns (bool);

     
    function isMethodAllowed(bytes4 _method, address _exchange)
        external view
        returns (bool);

     
     
    function isCasperInitialized()
        external view
        returns (bool);

     
     
    function getCasper()
        external view
        returns (address);
}

 
 
 
contract ExchangesAuthority is Owned, ExchangesAuthorityFace {

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
        bool exchange;
        bool asset;
        bool authority;
        bool wrapper;
        bool proxy;
    }

    struct Account {
        address account;
        bool authorized;
        mapping (bool => Group) groups;  
    }

    struct BuildingBlocks {
        address exchangeEventful;
        address sigVerifier;
        address casper;
        mapping (address => bool) initialized;
        mapping (address => address) adapter;
         
        mapping (address => mapping (bytes4 => bool)) allowedMethods;
        mapping (address => mapping (address => bool)) allowedTokens;
        mapping (address => mapping (address => bool)) allowedWrappers;
    }

     
    event AuthoritySet(address indexed authority);
    event WhitelisterSet(address indexed whitelister);
    event WhitelistedAsset(address indexed asset, bool approved);
    event WhitelistedExchange(address indexed exchange, bool approved);
    event WhitelistedWrapper(address indexed wrapper, bool approved);
    event WhitelistedProxy(address indexed proxy, bool approved);
    event WhitelistedMethod(bytes4 indexed method, address indexed adapter, bool approved);
    event NewSigVerifier(address indexed sigVerifier);
    event NewExchangeEventful(address indexed exchangeEventful);
    event NewCasper(address indexed casper);

     
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

     
     
     
    function whitelistAsset(address _asset, bool _isWhitelisted)
        external
        onlyWhitelister
    {
        accounts[_asset].account = _asset;
        accounts[_asset].authorized = _isWhitelisted;
        accounts[_asset].groups[_isWhitelisted].asset = _isWhitelisted;
        types.list.push(List(_asset));
        emit WhitelistedAsset(_asset, _isWhitelisted);
    }

     
     
     
    function whitelistExchange(address _exchange, bool _isWhitelisted)
        external
        onlyWhitelister
    {
        accounts[_exchange].account = _exchange;
        accounts[_exchange].authorized = _isWhitelisted;
        accounts[_exchange].groups[_isWhitelisted].exchange = _isWhitelisted;
        types.list.push(List(_exchange));
        emit WhitelistedExchange(_exchange, _isWhitelisted);
    }

     
     
     
    function whitelistWrapper(address _wrapper, bool _isWhitelisted)
        external
        onlyWhitelister
    {
        accounts[_wrapper].account = _wrapper;
        accounts[_wrapper].authorized = _isWhitelisted;
        accounts[_wrapper].groups[_isWhitelisted].wrapper = _isWhitelisted;
        types.list.push(List(_wrapper));
        emit WhitelistedWrapper(_wrapper, _isWhitelisted);
    }

     
     
     
    function whitelistTokenTransferProxy(
        address _tokenTransferProxy,
        bool _isWhitelisted)
        external
        onlyWhitelister
    {
        accounts[_tokenTransferProxy].account = _tokenTransferProxy;
        accounts[_tokenTransferProxy].authorized = _isWhitelisted;
        accounts[_tokenTransferProxy].groups[_isWhitelisted].proxy = _isWhitelisted;
        types.list.push(List(_tokenTransferProxy));
        emit WhitelistedProxy(_tokenTransferProxy, _isWhitelisted);
    }

     
     
     
     
    function whitelistAssetOnExchange(
        address _asset,
        address _exchange,
        bool _isWhitelisted)
        external
        onlyAdmin
    {
        blocks.allowedTokens[_exchange][_asset] = _isWhitelisted;
        emit WhitelistedAsset(_asset, _isWhitelisted);
    }

     
     
     
     
    function whitelistTokenOnWrapper(address _token, address _wrapper, bool _isWhitelisted)
        external
        onlyAdmin
    {
        blocks.allowedWrappers[_wrapper][_token] = _isWhitelisted;
        emit WhitelistedAsset(_token, _isWhitelisted);
    }

     
     
     
    function whitelistMethod(
        bytes4 _method,
        address _adapter,
        bool _isWhitelisted)
        external
        onlyAdmin
    {
        blocks.allowedMethods[_adapter][_method] = _isWhitelisted;
        emit WhitelistedMethod(_method, _adapter, _isWhitelisted);
    }

     
     
    function setSignatureVerifier(address _sigVerifier)
        external
        onlyOwner
    {
        blocks.sigVerifier = _sigVerifier;
        emit NewSigVerifier(blocks.sigVerifier);
    }

     
     
    function setExchangeEventful(address _exchangeEventful)
        external
        onlyOwner
    {
        blocks.exchangeEventful = _exchangeEventful;
        emit NewExchangeEventful(blocks.exchangeEventful);
    }

     
     
     
    function setExchangeAdapter(address _exchange, address _adapter)
        external
        onlyOwner
    {
        require(_exchange != _adapter);
        blocks.adapter[_exchange] = _adapter;
    }

     
     
    function setCasper(address _casper)
        external
        onlyOwner
    {
        blocks.casper = _casper;
        blocks.initialized[_casper] = true;
        emit NewCasper(blocks.casper);
    }

     
     
     
     
    function isAuthority(address _authority)
        external view
        returns (bool)
    {
        return accounts[_authority].groups[true].authority;
    }

     
     
     
    function isWhitelistedAsset(address _asset)
        external view
        returns (bool)
    {
        return accounts[_asset].groups[true].asset;
    }

     
     
     
    function isWhitelistedExchange(address _exchange)
        external view
        returns (bool)
    {
        return accounts[_exchange].groups[true].exchange;
    }

     
     
     
    function isWhitelistedWrapper(address _wrapper)
        external view
        returns (bool)
    {
        return accounts[_wrapper].groups[true].wrapper;
    }

     
     
     
    function isWhitelistedProxy(address _tokenTransferProxy)
        external view
        returns (bool)
    {
        return accounts[_tokenTransferProxy].groups[true].proxy;
    }

     
     
     
    function getExchangeAdapter(address _exchange)
        external view
        returns (address)
    {
        return blocks.adapter[_exchange];
    }

     
     
    function getSigVerifier()
        external view
        returns (address)
    {
        return blocks.sigVerifier;
    }

     
     
     
     
    function canTradeTokenOnExchange(address _token, address _exchange)
        external view
        returns (bool)
    {
        return blocks.allowedTokens[_exchange][_token];
    }

     
     
     
     
    function canWrapTokenOnWrapper(address _token, address _wrapper)
        external view
        returns (bool)
    {
        return blocks.allowedWrappers[_wrapper][_token];
    }

     
     
     
     
    function isMethodAllowed(bytes4 _method, address _adapter)
        external view
        returns (bool)
    {
        return blocks.allowedMethods[_adapter][_method];
    }

     
     
    function isCasperInitialized()
        external view
        returns (bool)
    {
        address casper = blocks.casper;
        return blocks.initialized[casper];
    }

     
     
    function getCasper()
        external view
        returns (address)
    {
        return blocks.casper;
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