 

pragma solidity ^0.4.25;

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0);  
    uint256 c = _a / _b;
     

    return c;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

contract DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

 
interface ERC20 {
  function totalSupply() public view returns (uint256);

  function balanceOf(address _who) public view returns (uint256);

  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transfer(address _to, uint256 _value) public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 
contract ERC20WithFields is ERC20 {
    string public symbol;
    string public name;
    uint8 public decimals;
}


 
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
        public
        view
        returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Approval(_from, msg.sender, allowed[_from][msg.sender]);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
        public
        returns (bool)
    {
        allowed[msg.sender][_spender] = (allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
        public
        returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0);
        totalSupply_ = totalSupply_.add(_amount);
        balances[_account] = balances[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

     
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0);
        require(_amount <= balances[_account]);

        totalSupply_ = totalSupply_.sub(_amount);
        balances[_account] = balances[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

     
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed[_account][msg.sender]);
        allowed[_account][msg.sender] = allowed[_account][msg.sender].sub(_amount);
        emit Approval(_account, msg.sender, allowed[_account][msg.sender]);
        _burn(_account, _amount);
    }
}


contract PreminedToken is StandardToken {
    string public symbol;
    string public  name;
    uint8 public decimals;

    constructor(string _symbol, uint8 _decimals, string _name) public {
        symbol = _symbol;
        decimals = _decimals;
        name = _name;
        totalSupply_ = 1000000 * 10**uint(decimals);
        balances[msg.sender] = totalSupply_;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }
}


 
contract BurnableToken is PreminedToken {
    constructor(string _symbol, uint8 _decimals, string _name)
        public
        PreminedToken(_symbol, _decimals, _name)
    {}

    function burn(uint _amount) public {
        _burn(msg.sender, _amount);
    }
    
    function burnFrom(address from, uint256 value) public {
        _burnFrom(from, value);
    }
}


 
interface PriceSourceInterface {
    event PriceUpdate(address[] token, uint[] price);

    function getQuoteAsset() external view returns (address);
    function getLastUpdate() external view returns (uint);

     
    function hasValidPrice(address) public view returns (bool);
    function hasValidPrices(address[]) public view returns (bool);

     
    function getPrice(address _asset) public view returns (uint price, uint timestamp);
    function getPrices(address[] _assets) public view returns (uint[] prices, uint[] timestamps);

     
    function getPriceInfo(address _asset) view returns (uint price, uint decimals);
    function getInvertedPriceInfo(address ofAsset) view returns (uint price, uint decimals);

    function getReferencePriceInfo(address _base, address _quote) public view returns (uint referencePrice, uint decimal);
    function getOrderPriceInfo(address sellAsset, address buyAsset, uint sellQuantity, uint buyQuantity) public view returns (uint orderPrice);
    function existsPriceOnAssetPair(address sellAsset, address buyAsset) public view returns (bool isExistent);
    function convertQuantity(
        uint fromAssetQuantity,
        address fromAsset,
        address toAsset
    ) public view returns (uint);
}


contract DSAuthority {
    function canCall(
        address src, address dst, bytes4 sig
    ) public view returns (bool);
}

contract DSAuthEvents {
    event LogSetAuthority (address indexed authority);
    event LogSetOwner     (address indexed owner);
}

contract DSAuth is DSAuthEvents {
    DSAuthority  public  authority;
    address      public  owner;

    constructor() public {
        owner = msg.sender;
        emit LogSetOwner(msg.sender);
    }

    function setOwner(address owner_)
        public
        auth
    {
        owner = owner_;
        emit LogSetOwner(owner);
    }

    function setAuthority(DSAuthority authority_)
        public
        auth
    {
        authority = authority_;
        emit LogSetAuthority(address(authority));
    }

    modifier auth {
        require(isAuthorized(msg.sender, msg.sig), "ds-auth-unauthorized");
        _;
    }

    function isAuthorized(address src, bytes4 sig) internal view returns (bool) {
        if (src == address(this)) {
            return true;
        } else if (src == owner) {
            return true;
        } else if (authority == DSAuthority(0)) {
            return false;
        } else {
            return authority.canCall(src, address(this), sig);
        }
    }
}

contract DSGuardEvents {
    event LogPermit(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );

    event LogForbid(
        bytes32 indexed src,
        bytes32 indexed dst,
        bytes32 indexed sig
    );
}

contract DSGuard is DSAuth, DSAuthority, DSGuardEvents {
    bytes32 constant public ANY = bytes32(uint(-1));

    mapping (bytes32 => mapping (bytes32 => mapping (bytes32 => bool))) acl;

    function canCall(
        address src_, address dst_, bytes4 sig
    ) public view returns (bool) {
        bytes32 src = bytes32(bytes20(src_));
        bytes32 dst = bytes32(bytes20(dst_));

        return acl[src][dst][sig]
            || acl[src][dst][ANY]
            || acl[src][ANY][sig]
            || acl[src][ANY][ANY]
            || acl[ANY][dst][sig]
            || acl[ANY][dst][ANY]
            || acl[ANY][ANY][sig]
            || acl[ANY][ANY][ANY];
    }

    function permit(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = true;
        emit LogPermit(src, dst, sig);
    }

    function forbid(bytes32 src, bytes32 dst, bytes32 sig) public auth {
        acl[src][dst][sig] = false;
        emit LogForbid(src, dst, sig);
    }

    function permit(address src, address dst, bytes32 sig) public {
        permit(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }
    function forbid(address src, address dst, bytes32 sig) public {
        forbid(bytes32(bytes20(src)), bytes32(bytes20(dst)), sig);
    }

}

contract DSGuardFactory {
    mapping (address => bool)  public  isGuard;

    function newGuard() public returns (DSGuard guard) {
        guard = new DSGuard();
        guard.setOwner(msg.sender);
        isGuard[address(guard)] = true;
    }
}

 
contract Spoke is DSAuth {
    Hub public hub;
    Hub.Routes public routes;
    bool public initialized;

    modifier onlyInitialized() {
        require(initialized, "Component not yet initialized");
        _;
    }

    modifier notShutDown() {
        require(!hub.isShutDown(), "Hub is shut down");
        _;
    }

    constructor(address _hub) {
        hub = Hub(_hub);
        setAuthority(hub);
        setOwner(hub);  
    }

    function initialize(address[12] _spokes) external auth {
        require(msg.sender == address(hub));
        require(!initialized, "Already initialized");
        routes = Hub.Routes(
            _spokes[0],
            _spokes[1],
            _spokes[2],
            _spokes[3],
            _spokes[4],
            _spokes[5],
            _spokes[6],
            _spokes[7],
            _spokes[8],
            _spokes[9],
            _spokes[10],
            _spokes[11]
        );
        initialized = true;
        setOwner(address(0));
    }

    function engine() public view returns (address) { return routes.engine; }
    function mlnToken() public view returns (address) { return routes.mlnToken; }
    function priceSource() public view returns (address) { return routes.priceSource; }
    function version() public view returns (address) { return routes.version; }
    function registry() public view returns (address) { return routes.registry; }
}


 
 
contract Hub is DSGuard {

    event FundShutDown();

    struct Routes {
        address accounting;
        address feeManager;
        address participation;
        address policyManager;
        address shares;
        address trading;
        address vault;
        address priceSource;
        address registry;
        address version;
        address engine;
        address mlnToken;
    }

    Routes public routes;
    address public manager;
    address public creator;
    string public name;
    bool public isShutDown;
    bool public spokesSet;
    bool public routingSet;
    bool public permissionsSet;
    uint public creationTime;
    mapping (address => bool) public isSpoke;

    constructor(address _manager, string _name) {
        creator = msg.sender;
        manager = _manager;
        name = _name;
        creationTime = block.timestamp;
    }

    modifier onlyCreator() {
        require(msg.sender == creator, "Only creator can do this");
        _;
    }

    function shutDownFund() external {
        require(msg.sender == routes.version);
        isShutDown = true;
        emit FundShutDown();
    }

    function setSpokes(address[12] _spokes) external onlyCreator {
        require(!spokesSet, "Spokes already set");
        for (uint i = 0; i < _spokes.length; i++) {
            isSpoke[_spokes[i]] = true;
        }
        routes.accounting = _spokes[0];
        routes.feeManager = _spokes[1];
        routes.participation = _spokes[2];
        routes.policyManager = _spokes[3];
        routes.shares = _spokes[4];
        routes.trading = _spokes[5];
        routes.vault = _spokes[6];
        routes.priceSource = _spokes[7];
        routes.registry = _spokes[8];
        routes.version = _spokes[9];
        routes.engine = _spokes[10];
        routes.mlnToken = _spokes[11];
        spokesSet = true;
    }

    function setRouting() external onlyCreator {
        require(spokesSet, "Spokes must be set");
        require(!routingSet, "Routing already set");
        address[12] memory spokes = [
            routes.accounting, routes.feeManager, routes.participation,
            routes.policyManager, routes.shares, routes.trading,
            routes.vault, routes.priceSource, routes.registry,
            routes.version, routes.engine, routes.mlnToken
        ];
        Spoke(routes.accounting).initialize(spokes);
        Spoke(routes.feeManager).initialize(spokes);
        Spoke(routes.participation).initialize(spokes);
        Spoke(routes.policyManager).initialize(spokes);
        Spoke(routes.shares).initialize(spokes);
        Spoke(routes.trading).initialize(spokes);
        Spoke(routes.vault).initialize(spokes);
        routingSet = true;
    }

    function setPermissions() external onlyCreator {
        require(spokesSet, "Spokes must be set");
        require(routingSet, "Routing must be set");
        require(!permissionsSet, "Permissioning already set");
        permit(routes.participation, routes.vault, bytes4(keccak256('withdraw(address,uint256)')));
        permit(routes.trading, routes.vault, bytes4(keccak256('withdraw(address,uint256)')));
        permit(routes.participation, routes.shares, bytes4(keccak256('createFor(address,uint256)')));
        permit(routes.participation, routes.shares, bytes4(keccak256('destroyFor(address,uint256)')));
        permit(routes.feeManager, routes.shares, bytes4(keccak256('createFor(address,uint256)')));
        permit(routes.participation, routes.accounting, bytes4(keccak256('addAssetToOwnedAssets(address)')));
        permit(routes.trading, routes.accounting, bytes4(keccak256('addAssetToOwnedAssets(address)')));
        permit(routes.trading, routes.accounting, bytes4(keccak256('removeFromOwnedAssets(address)')));
        permit(routes.accounting, routes.feeManager, bytes4(keccak256('rewardAllFees()')));
        permit(manager, routes.policyManager, bytes4(keccak256('register(bytes4,address)')));
        permit(manager, routes.policyManager, bytes4(keccak256('batchRegister(bytes4[],address[])')));
        permit(manager, routes.participation, bytes4(keccak256('enableInvestment(address[])')));
        permit(manager, routes.participation, bytes4(keccak256('disableInvestment(address[])')));
        permissionsSet = true;
    }

    function vault() external view returns (address) { return routes.vault; }
    function accounting() external view returns (address) { return routes.accounting; }
    function priceSource() external view returns (address) { return routes.priceSource; }
    function participation() external view returns (address) { return routes.participation; }
    function trading() external view returns (address) { return routes.trading; }
    function shares() external view returns (address) { return routes.shares; }
    function registry() external view returns (address) { return routes.registry; }
    function policyManager() external view returns (address) { return routes.policyManager; }
}




contract Registry is DSAuth {

     
    event AssetUpsert (
        address indexed asset,
        string name,
        string symbol,
        uint decimals,
        string url,
        uint reserveMin,
        uint[] standards,
        bytes4[] sigs
    );

    event ExchangeAdapterUpsert (
        address indexed exchange,
        address indexed adapter,
        bool takesCustody,
        bytes4[] sigs
    );

    event AssetRemoval (address indexed asset);
    event EfxWrapperRegistryChange(address indexed registry);
    event EngineChange(address indexed engine);
    event ExchangeAdapterRemoval (address indexed exchange);
    event IncentiveChange(uint incentiveAmount);
    event MGMChange(address indexed MGM);
    event MlnTokenChange(address indexed mlnToken);
    event NativeAssetChange(address indexed nativeAsset);
    event PriceSourceChange(address indexed priceSource);
    event VersionRegistration(address indexed version);

     
    struct Asset {
        bool exists;
        string name;
        string symbol;
        uint decimals;
        string url;
        uint reserveMin;
        uint[] standards;
        bytes4[] sigs;
    }

    struct Exchange {
        bool exists;
        address exchangeAddress;
        bool takesCustody;
        bytes4[] sigs;
    }

    struct Version {
        bool exists;
        bytes32 name;
    }

     
    uint public constant MAX_REGISTERED_ENTITIES = 20;
    uint public constant MAX_FUND_NAME_BYTES = 66;

     
    mapping (address => Asset) public assetInformation;
    address[] public registeredAssets;

     
    mapping (address => Exchange) public exchangeInformation;
    address[] public registeredExchangeAdapters;

    mapping (address => Version) public versionInformation;
    address[] public registeredVersions;

    mapping (address => bool) public isFeeRegistered;

    mapping (address => address) public fundsToVersions;
    mapping (bytes32 => bool) public versionNameExists;
    mapping (bytes32 => address) public fundNameHashToOwner;


    uint public incentive = 10 finney;
    address public priceSource;
    address public mlnToken;
    address public nativeAsset;
    address public engine;
    address public ethfinexWrapperRegistry;
    address public MGM;

    modifier onlyVersion() {
        require(
            versionInformation[msg.sender].exists,
            "Only a Version can do this"
        );
        _;
    }

     

    constructor(address _postDeployOwner) {
        setOwner(_postDeployOwner);
    }

     

     
    function isValidFundName(string _name) public view returns (bool) {
        bytes memory b = bytes(_name);
        if (b.length > MAX_FUND_NAME_BYTES) return false;
        for (uint i; i < b.length; i++){
            bytes1 char = b[i];
            if(
                !(char >= 0x30 && char <= 0x39) &&  
                !(char >= 0x41 && char <= 0x5A) &&  
                !(char >= 0x61 && char <= 0x7A) &&  
                !(char == 0x20 || char == 0x2D) &&  
                !(char == 0x2E || char == 0x5F) &&  
                !(char == 0x2A)  
            ) {
                return false;
            }
        }
        return true;
    }

     
    function canUseFundName(address _user, string _name) public view returns (bool) {
        bytes32 nameHash = keccak256(_name);
        return (
            isValidFundName(_name) &&
            (
                fundNameHashToOwner[nameHash] == address(0) ||
                fundNameHashToOwner[nameHash] == _user
            )
        );
    }

    function reserveFundName(address _owner, string _name)
        external
        onlyVersion
    {
        require(canUseFundName(_owner, _name), "Fund name cannot be used");
        fundNameHashToOwner[keccak256(_name)] = _owner;
    }

    function registerFund(address _fund, address _owner, string _name)
        external
        onlyVersion
    {
        require(canUseFundName(_owner, _name), "Fund name cannot be used");
        fundsToVersions[_fund] = msg.sender;
    }

     
     
     
     
     
     
     
     
     
    function registerAsset(
        address _asset,
        string _name,
        string _symbol,
        string _url,
        uint _reserveMin,
        uint[] _standards,
        bytes4[] _sigs
    ) external auth {
        require(registeredAssets.length < MAX_REGISTERED_ENTITIES);
        require(!assetInformation[_asset].exists);
        assetInformation[_asset].exists = true;
        registeredAssets.push(_asset);
        updateAsset(
            _asset,
            _name,
            _symbol,
            _url,
            _reserveMin,
            _standards,
            _sigs
        );
    }

     
     
     
     
     
     
     
     
    function registerExchangeAdapter(
        address _exchange,
        address _adapter,
        bool _takesCustody,
        bytes4[] _sigs
    ) external auth {
        require(!exchangeInformation[_adapter].exists, "Adapter already exists");
        exchangeInformation[_adapter].exists = true;
        require(registeredExchangeAdapters.length < MAX_REGISTERED_ENTITIES, "Exchange limit reached");
        registeredExchangeAdapters.push(_adapter);
        updateExchangeAdapter(
            _exchange,
            _adapter,
            _takesCustody,
            _sigs
        );
    }

     
     
     
    function registerVersion(
        address _version,
        bytes32 _name
    ) external auth {
        require(!versionInformation[_version].exists, "Version already exists");
        require(!versionNameExists[_name], "Version name already exists");
        versionInformation[_version].exists = true;
        versionNameExists[_name] = true;
        versionInformation[_version].name = _name;
        registeredVersions.push(_version);
        emit VersionRegistration(_version);
    }

    function setIncentive(uint _weiAmount) external auth {
        incentive = _weiAmount;
        emit IncentiveChange(_weiAmount);
    }

    function setPriceSource(address _priceSource) external auth {
        priceSource = _priceSource;
        emit PriceSourceChange(_priceSource);
    }

    function setMlnToken(address _mlnToken) external auth {
        mlnToken = _mlnToken;
        emit MlnTokenChange(_mlnToken);
    }

    function setNativeAsset(address _nativeAsset) external auth {
        nativeAsset = _nativeAsset;
        emit NativeAssetChange(_nativeAsset);
    }

    function setEngine(address _engine) external auth {
        engine = _engine;
        emit EngineChange(_engine);
    }

    function setMGM(address _MGM) external auth {
        MGM = _MGM;
        emit MGMChange(_MGM);
    }

    function setEthfinexWrapperRegistry(address _registry) external auth {
        ethfinexWrapperRegistry = _registry;
        emit EfxWrapperRegistryChange(_registry);
    }

     
     
     
     
     
     
     
    function updateAsset(
        address _asset,
        string _name,
        string _symbol,
        string _url,
        uint _reserveMin,
        uint[] _standards,
        bytes4[] _sigs
    ) public auth {
        require(assetInformation[_asset].exists);
        Asset asset = assetInformation[_asset];
        asset.name = _name;
        asset.symbol = _symbol;
        asset.decimals = ERC20WithFields(_asset).decimals();
        asset.url = _url;
        asset.reserveMin = _reserveMin;
        asset.standards = _standards;
        asset.sigs = _sigs;
        emit AssetUpsert(
            _asset,
            _name,
            _symbol,
            asset.decimals,
            _url,
            _reserveMin,
            _standards,
            _sigs
        );
    }

    function updateExchangeAdapter(
        address _exchange,
        address _adapter,
        bool _takesCustody,
        bytes4[] _sigs
    ) public auth {
        require(exchangeInformation[_adapter].exists, "Exchange with adapter doesn't exist");
        Exchange exchange = exchangeInformation[_adapter];
        exchange.exchangeAddress = _exchange;
        exchange.takesCustody = _takesCustody;
        exchange.sigs = _sigs;
        emit ExchangeAdapterUpsert(
            _exchange,
            _adapter,
            _takesCustody,
            _sigs
        );
    }

     
     
     
    function removeAsset(
        address _asset,
        uint _assetIndex
    ) external auth {
        require(assetInformation[_asset].exists);
        require(registeredAssets[_assetIndex] == _asset);
        delete assetInformation[_asset];
        delete registeredAssets[_assetIndex];
        for (uint i = _assetIndex; i < registeredAssets.length-1; i++) {
            registeredAssets[i] = registeredAssets[i+1];
        }
        registeredAssets.length--;
        emit AssetRemoval(_asset);
    }

     
     
     
     
    function removeExchangeAdapter(
        address _adapter,
        uint _adapterIndex
    ) external auth {
        require(exchangeInformation[_adapter].exists, "Exchange with adapter doesn't exist");
        require(registeredExchangeAdapters[_adapterIndex] == _adapter, "Incorrect adapter index");
        delete exchangeInformation[_adapter];
        delete registeredExchangeAdapters[_adapterIndex];
        for (uint i = _adapterIndex; i < registeredExchangeAdapters.length-1; i++) {
            registeredExchangeAdapters[i] = registeredExchangeAdapters[i+1];
        }
        registeredExchangeAdapters.length--;
        emit ExchangeAdapterRemoval(_adapter);
    }

    function registerFees(address[] _fees) external auth {
        for (uint i; i < _fees.length; i++) {
            isFeeRegistered[_fees[i]] = true;
        }
    }

    function deregisterFees(address[] _fees) external auth {
        for (uint i; i < _fees.length; i++) {
            delete isFeeRegistered[_fees[i]];
        }
    }

     

     
    function getName(address _asset) external view returns (string) {
        return assetInformation[_asset].name;
    }
    function getSymbol(address _asset) external view returns (string) {
        return assetInformation[_asset].symbol;
    }
    function getDecimals(address _asset) external view returns (uint) {
        return assetInformation[_asset].decimals;
    }
    function getReserveMin(address _asset) external view returns (uint) {
        return assetInformation[_asset].reserveMin;
    }
    function assetIsRegistered(address _asset) external view returns (bool) {
        return assetInformation[_asset].exists;
    }
    function getRegisteredAssets() external view returns (address[]) {
        return registeredAssets;
    }
    function assetMethodIsAllowed(address _asset, bytes4 _sig)
        external
        view
        returns (bool)
    {
        bytes4[] memory signatures = assetInformation[_asset].sigs;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == _sig) {
                return true;
            }
        }
        return false;
    }

     
    function exchangeAdapterIsRegistered(address _adapter) external view returns (bool) {
        return exchangeInformation[_adapter].exists;
    }
    function getRegisteredExchangeAdapters() external view returns (address[]) {
        return registeredExchangeAdapters;
    }
    function getExchangeInformation(address _adapter)
        public
        view
        returns (address, bool)
    {
        Exchange exchange = exchangeInformation[_adapter];
        return (
            exchange.exchangeAddress,
            exchange.takesCustody
        );
    }
    function exchangeForAdapter(address _adapter) external view returns (address) {
        Exchange exchange = exchangeInformation[_adapter];
        return exchange.exchangeAddress;
    }
    function getAdapterFunctionSignatures(address _adapter)
        public
        view
        returns (bytes4[])
    {
        return exchangeInformation[_adapter].sigs;
    }
    function adapterMethodIsAllowed(
        address _adapter, bytes4 _sig
    )
        external
        view
        returns (bool)
    {
        bytes4[] memory signatures = exchangeInformation[_adapter].sigs;
        for (uint i = 0; i < signatures.length; i++) {
            if (signatures[i] == _sig) {
                return true;
            }
        }
        return false;
    }

     
    function getRegisteredVersions() external view returns (address[]) {
        return registeredVersions;
    }

    function isFund(address _who) external view returns (bool) {
        if (fundsToVersions[_who] != address(0)) {
            return true;  
        } else {
            address hub = Hub(Spoke(_who).hub());
            require(
                Hub(hub).isSpoke(_who),
                "Call from either a spoke or hub"
            );
            return fundsToVersions[hub] != address(0);
        }
    }

    function isFundFactory(address _who) external view returns (bool) {
        return versionInformation[_who].exists;
    }
}


 
contract Engine is DSMath {

    event RegistryChange(address registry);
    event SetAmguPrice(uint amguPrice);
    event AmguPaid(uint amount);
    event Thaw(uint amount);
    event Burn(uint amount);

    uint public constant MLN_DECIMALS = 18;

    Registry public registry;
    uint public amguPrice;
    uint public frozenEther;
    uint public liquidEther;
    uint public lastThaw;
    uint public thawingDelay;
    uint public totalEtherConsumed;
    uint public totalAmguConsumed;
    uint public totalMlnBurned;

    constructor(uint _delay, address _registry) {
        lastThaw = block.timestamp;
        thawingDelay = _delay;
        _setRegistry(_registry);
    }

    modifier onlyMGM() {
        require(
            msg.sender == registry.MGM(),
            "Only MGM can call this"
        );
        _;
    }

     
    modifier onlyMTC() {
        require(
            msg.sender == registry.owner(),
            "Only MTC can call this"
        );
        _;
    }

    function _setRegistry(address _registry) internal {
        registry = Registry(_registry);
        emit RegistryChange(registry);
    }

     
    function setRegistry(address _registry)
        external
        onlyMTC
    {
        _setRegistry(_registry);
    }

     
     
    function setAmguPrice(uint _price)
        external
        onlyMGM
    {
        amguPrice = _price;
        emit SetAmguPrice(_price);
    }

    function getAmguPrice() public view returns (uint) { return amguPrice; }

    function premiumPercent() public view returns (uint) {
        if (liquidEther < 1 ether) {
            return 0;
        } else if (liquidEther >= 1 ether && liquidEther < 5 ether) {
            return 5;
        } else if (liquidEther >= 5 ether && liquidEther < 10 ether) {
            return 10;
        } else if (liquidEther >= 10 ether) {
            return 15;
        }
    }

    function payAmguInEther() external payable {
        require(
            registry.isFundFactory(msg.sender) ||
            registry.isFund(msg.sender),
            "Sender must be a fund or the factory"
        );
        uint mlnPerAmgu = getAmguPrice();
        uint ethPerMln;
        (ethPerMln,) = priceSource().getPrice(address(mlnToken()));
        uint amguConsumed;
        if (mlnPerAmgu > 0 && ethPerMln > 0) {
            amguConsumed = (mul(msg.value, 10 ** uint(MLN_DECIMALS))) / (mul(ethPerMln, mlnPerAmgu));
        } else {
            amguConsumed = 0;
        }
        totalEtherConsumed = add(totalEtherConsumed, msg.value);
        totalAmguConsumed = add(totalAmguConsumed, amguConsumed);
        frozenEther = add(frozenEther, msg.value);
        emit AmguPaid(amguConsumed);
    }

     
     
    function thaw() external {
        require(
            block.timestamp >= add(lastThaw, thawingDelay),
            "Thawing delay has not passed"
        );
        require(frozenEther > 0, "No frozen ether to thaw");
        lastThaw = block.timestamp;
        liquidEther = add(liquidEther, frozenEther);
        emit Thaw(frozenEther);
        frozenEther = 0;
    }

     
    function enginePrice() public view returns (uint) {
        uint ethPerMln;
        (ethPerMln, ) = priceSource().getPrice(address(mlnToken()));
        uint premium = (mul(ethPerMln, premiumPercent()) / 100);
        return add(ethPerMln, premium);
    }

    function ethPayoutForMlnAmount(uint mlnAmount) public view returns (uint) {
        return mul(mlnAmount, enginePrice()) / 10 ** uint(MLN_DECIMALS);
    }

     
    function sellAndBurnMln(uint mlnAmount) external {
        require(registry.isFund(msg.sender), "Only funds can use the engine");
        require(
            mlnToken().transferFrom(msg.sender, address(this), mlnAmount),
            "MLN transferFrom failed"
        );
        uint ethToSend = ethPayoutForMlnAmount(mlnAmount);
        require(ethToSend > 0, "No ether to pay out");
        require(liquidEther >= ethToSend, "Not enough liquid ether to send");
        liquidEther = sub(liquidEther, ethToSend);
        totalMlnBurned = add(totalMlnBurned, mlnAmount);
        msg.sender.transfer(ethToSend);
        mlnToken().burn(mlnAmount);
        emit Burn(mlnAmount);
    }

     
    function mlnToken()
        public
        view
        returns (BurnableToken)
    {
        return BurnableToken(registry.mlnToken());
    }

     
    function priceSource()
        public
        view
        returns (PriceSourceInterface)
    {
        return PriceSourceInterface(registry.priceSource());
    }
}