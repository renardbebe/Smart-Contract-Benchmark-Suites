 

 

pragma solidity 0.4.25;
pragma experimental "v0.5.0";

interface Authority {

     
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

interface VaultEventful {

     
    event BuyVault(address indexed vault, address indexed from, address indexed to, uint256 amount, uint256 revenue, bytes name, bytes symbol);
    event SellVault(address indexed vault, address indexed from, address indexed to, uint256 amount, uint256 revenue, bytes name, bytes symbol);
    event NewRatio(address indexed vault, address indexed from, uint256 newRatio);
    event NewFee(address indexed vault, address indexed from, address indexed to, uint256 fee);
    event NewCollector(address indexed vault, address indexed from, address indexed to, address collector);
    event VaultDao(address indexed vault, address indexed from, address indexed to, address vaultDao);
    event VaultCreated(address indexed vault, address indexed group, address indexed owner, uint256 vaultId, string name, string symbol);

     
    function buyVault(address _who, address _targetVault, uint256 _value, uint256 _amount, bytes _name, bytes _symbol) external returns (bool success);
    function sellVault(address _who, address _targetVault, uint256 _amount, uint256 _revenue, bytes _name, bytes _symbol) external returns(bool success);
    function changeRatio(address _who, address _targetVault, uint256 _ratio) external returns(bool success);
    function setTransactionFee(address _who, address _targetVault, uint256 _transactionFee) external returns(bool success);
    function changeFeeCollector(address _who, address _targetVault, address _feeCollector) external returns(bool success);
    function changeVaultDao(address _who, address _targetVault, address _vaultDao) external returns(bool success);
    function createVault(address _who, address _newVault, string _name, string _symbol, uint256 _vaultId) external returns(bool success);
}

interface Token {

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);
    function approve(address _spender, uint256 _value) external returns (bool success);

    function balanceOf(address _who) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

contract ReentrancyGuard {

     
    bool private locked = false;

     
     
    modifier nonReentrant() {
         
        require(
            !locked,
            "REENTRANCY_ILLEGAL"
        );

         
        locked = true;

         
        _;

         
        locked = false;
    }
}

contract Owned {

    address public owner;

    event NewOwner(address indexed old, address indexed current);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _new) public onlyOwner {
        require(_new != address(0));
        owner = _new;
        emit  NewOwner(owner, _new);
    }
}

contract SafeMath {

    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b > 0);
        uint256 c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c>=a && c>=b);
        return c;
    }
}

interface VaultFace {

     
    function buyVault() external payable returns (bool success);
    function buyVaultOnBehalf(address _hodler) external payable returns (bool success);
    function sellVault(uint256 amount) external returns (bool success);
    function changeRatio(uint256 _ratio) external;
    function setTransactionFee(uint256 _transactionFee) external;
    function changeFeeCollector(address _feeCollector) external;
    function changeVaultDao(address _vaultDao) external;
    function updatePrice() external;
    function changeMinPeriod(uint32 _minPeriod) external;
    function depositToken(address _token, uint256 _value, uint8 _forTime) external returns (bool success);
    function depositTokenOnBehalf(address _token, address _hodler, uint256 _value, uint8 _forTime) external returns (bool success);
    function withdrawToken(address _token, uint256 _value) external returns (bool success);

     
    function balanceOf(address _who) external view returns (uint256);
    function tokenBalanceOf(address _token, address _owner) external view returns (uint256);
    function timeToUnlock(address _token, address _user) external view returns (uint256);
    function tokensInVault(address _token) external view returns (uint256);
    function getEventful() external view returns (address);
    function getData() external view returns (string name, string symbol, uint256 sellPrice, uint256 buyPrice);
    function calcSharePrice() external view returns (uint256);
    function getAdminData() external view returns (address, address feeCollector, address vaultDao, uint256 ratio, uint256 transactionFee, uint32 minPeriod);
    function totalSupply() external view returns (uint256);
}

 
 
 
contract Vault is Owned, SafeMath, ReentrancyGuard, VaultFace {

    string constant VERSION = 'VC 0.5.2';
    uint256 constant BASE = 1000000;  

    VaultData data;
    Admin admin;

    mapping (address => Account) accounts;

    mapping (address => uint256) totalTokens;
    mapping (address => mapping (address => uint256)) public depositLock;
    mapping (address => mapping (address => uint256)) public tokenBalances;

    struct Receipt {
        uint32 activation;
    }

    struct Account {
        uint256 balance;
        Receipt receipt;
    }

    struct VaultData {
        string name;
        string symbol;
        uint256 vaultId;
        uint256 totalSupply;
        uint256 price;
        uint256 transactionFee;  
        uint32 minPeriod;
        uint128 validatorIndex;
    }

    struct Admin {
        address authority;
        address vaultDao;
        address feeCollector;
        uint256 minOrder;  
        uint256 ratio;  
    }

    modifier onlyVaultDao {
        require(msg.sender == admin.vaultDao);
        _;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier minimumStake(uint256 _amount) {
        require(_amount >= admin.minOrder);
        _;
    }

    modifier hasEnough(uint256 _amount) {
        require(accounts[msg.sender].balance >= _amount);
        _;
    }

    modifier positiveAmount(uint256 _amount) {
        require(accounts[msg.sender].balance + _amount > accounts[msg.sender].balance);
        _;
    }

    modifier minimumPeriodPast {
        require(now >= accounts[msg.sender].receipt.activation);
        _;
    }

    constructor(
        string _vaultName,
        string _vaultSymbol,
        uint256 _vaultId,
        address _owner,
        address _authority)
        public
    {
        data.name = _vaultName;
        data.symbol = _vaultSymbol;
        data.vaultId = _vaultId;
        data.price = 1 ether;  
        owner = _owner;
        admin.authority = _authority;
        admin.vaultDao = msg.sender;
        admin.minOrder = 1 finney;
        admin.feeCollector = _owner;
        admin.ratio = 80;
    }

     
     
     
    function buyVault()
        external
        payable
        minimumStake(msg.value)
        returns (bool success)
    {
        require(buyVaultInternal(msg.sender, msg.value));
        return true;
    }

     
     
     
    function buyVaultOnBehalf(address _hodler)
        external
        payable
        minimumStake(msg.value)
        returns (bool success)
    {
        require(buyVaultInternal(_hodler, msg.value));
        return true;
    }

     
     
     
    function sellVault(uint256 _amount)
        external
        nonReentrant
        hasEnough(_amount)
        positiveAmount(_amount)
        minimumPeriodPast
        returns (bool success)
    {
        updatePriceInternal();
        uint256 feeVault;
        uint256 feeVaultDao;
        uint256 netAmount;
        uint256 netRevenue;
        (feeVault, feeVaultDao, netAmount, netRevenue) = getSaleAmounts(_amount);
        addSaleLog(_amount, netRevenue);
        allocateSaleTokens(msg.sender, _amount, feeVault, feeVaultDao);
        data.totalSupply = safeSub(data.totalSupply, netAmount);
        msg.sender.transfer(netRevenue);
        return true;
    }

     
     
    function changeRatio(uint256 _ratio)
        external
        onlyVaultDao
    {
        Authority auth = Authority(admin.authority);
        VaultEventful events = VaultEventful(auth.getVaultEventful());
        require(events.changeRatio(msg.sender, this, _ratio));
        admin.ratio = _ratio;
    }

     
     
    function setTransactionFee(uint256 _transactionFee)
        external
        onlyOwner
    {
        require(_transactionFee <= 100);  
        Authority auth = Authority(admin.authority);
        VaultEventful events = VaultEventful(auth.getVaultEventful());
        require(events.setTransactionFee(msg.sender, this, _transactionFee));
        data.transactionFee = _transactionFee;
    }

     
     
    function changeFeeCollector(address _feeCollector)
        external
        onlyOwner
    {
        Authority auth = Authority(admin.authority);
        VaultEventful events = VaultEventful(auth.getVaultEventful());
        require(events.changeFeeCollector(msg.sender, this, _feeCollector));
        admin.feeCollector = _feeCollector;
    }

     
     
    function changeVaultDao(address _vaultDao)
        external
        onlyVaultDao
    {
        Authority auth = Authority(admin.authority);
        VaultEventful events = VaultEventful(auth.getVaultEventful());
        require(events.changeVaultDao(msg.sender, this, _vaultDao));
        admin.vaultDao = _vaultDao;
    }

     
     
     
    function updatePrice()
        external
        nonReentrant
    {
        updatePriceInternal();
    }

     
     
    function changeMinPeriod(uint32 _minPeriod)
        external
        onlyVaultDao
    {
        data.minPeriod = _minPeriod;
    }

     
     
     
     
     
    function depositToken(
        address _token,
        uint256 _value,
        uint8 _forTime)
        external
        nonReentrant
        returns (bool success)
    {
        require(depositTokenInternal(_token, msg.sender, _value, _forTime));
        return true;
    }

     
     
     
     
     
    function depositTokenOnBehalf(
        address _token,
        address _hodler,
        uint256 _value,
        uint8 _forTime)
        external
        returns (bool success)
    {
        require(depositTokenInternal(_token, _hodler, _value, _forTime));
        return true;
    }

     
     
     
     
    function withdrawToken(
        address _token,
        uint256 _value)
        external
        nonReentrant
        returns
        (bool success)
    {
        require(tokenBalances[_token][msg.sender] >= _value);
        require(uint32(now) > depositLock[_token][msg.sender]);
        tokenBalances[_token][msg.sender] = safeSub(tokenBalances[_token][msg.sender], _value);
        totalTokens[_token] = safeSub(totalTokens[_token], _value);
        require(Token(_token).transfer(msg.sender, _value));
        return true;
    }

     
     
     
     
    function balanceOf(address _from)
        external
        view
        returns (uint256)
    {
        return accounts[_from].balance;
    }

     
     
     
     
    function tokenBalanceOf(
        address _token,
        address _owner)
        external
        view
        returns (uint256)
    {
        return tokenBalances[_token][_owner];
    }

     
     
     
     
    function timeToUnlock(
        address _token,
        address _user)
        external
        view
        returns (uint256)
    {
        return depositLock[_token][_user];
    }

     
     
     
    function tokensInVault(address _token)
        external
        view
        returns (uint256)
    {
        return totalTokens[_token];
    }

     
     
    function getEventful()
        external
        view
        returns (address)
    {
        Authority auth = Authority(admin.authority);
        return auth.getVaultEventful();
    }

     
     
     
     
     
    function getData()
        external
        view
        returns (
            string name,
            string symbol,
            uint256 sellPrice,
            uint256 buyPrice
        )
    {
        return(
            name = data.name,
            symbol = data.symbol,
            sellPrice = getNav(),
            buyPrice = getNav()
        );
    }

     
     
    function calcSharePrice()
        external
        view
        returns (uint256)
    {
        return getNav();
    }

     
     
     
     
     
     
    function getAdminData()
        external
        view
        returns (
            address,
            address feeCollector,
            address vaultDao,
            uint256 ratio,
            uint256 transactionFee,
            uint32 minPeriod
        )
    {
        return (
            owner,
            admin.feeCollector,
            admin.vaultDao,
            admin.ratio,
            data.transactionFee,
            data.minPeriod
        );
    }

     
     
    function totalSupply()
        external
        view
        returns (uint256)
    {
        return data.totalSupply;
    }

     
     
     
     
    function buyVaultInternal(
        address _hodler,
        uint256 _totalEth)
        internal
        returns (bool success)
    {
        updatePriceInternal();
        uint256 grossAmount;
        uint256 feeVault;
        uint256 feeVaultDao;
        uint256 amount;
        (grossAmount, feeVault, feeVaultDao, amount) = getPurchaseAmounts(_totalEth);
        addPurchaseLog(amount);
        allocatePurchaseTokens(_hodler, amount, feeVault, feeVaultDao);
        data.totalSupply = safeAdd(data.totalSupply, grossAmount);
        return true;
    }

     
    function updatePriceInternal()
        internal
    {
        if (address(this).balance > 0) {
            data.price = getNav();
        }
    }

     
     
     
     
     
    function allocatePurchaseTokens(
        address _hodler,
        uint256 _amount,
        uint256 _feeVault,
        uint256 _feeVaultDao)
        internal
    {
        accounts[_hodler].balance = safeAdd(accounts[_hodler].balance, _amount);
        accounts[admin.feeCollector].balance = safeAdd(accounts[admin.feeCollector].balance, _feeVault);
        accounts[admin.vaultDao].balance = safeAdd(accounts[admin.vaultDao].balance, _feeVaultDao);
        accounts[_hodler].receipt.activation = uint32(now) + data.minPeriod;
    }

     
     
     
     
     
    function allocateSaleTokens(
        address _hodler,
        uint256 _amount,
        uint256 _feeVault,
        uint256 _feeVaultDao)
        internal
    {
        accounts[_hodler].balance = safeSub(accounts[_hodler].balance, _amount);
        accounts[admin.feeCollector].balance = safeAdd(accounts[admin.feeCollector].balance, _feeVault);
        accounts[admin.vaultDao].balance = safeAdd(accounts[admin.vaultDao].balance, _feeVaultDao);
    }

     
     
    function addPurchaseLog(uint256 _amount)
        internal
    {
        bytes memory name = bytes(data.name);
        bytes memory symbol = bytes(data.symbol);
        Authority auth = Authority(admin.authority);
        VaultEventful events = VaultEventful(auth.getVaultEventful());
        require(events.buyVault(msg.sender, this, msg.value, _amount, name, symbol));
    }

     
     
     
    function addSaleLog(
        uint256 _amount,
        uint256 _netRevenue)
        internal
    {
        bytes memory name = bytes(data.name);
        bytes memory symbol = bytes(data.symbol);
        Authority auth = Authority(admin.authority);
        VaultEventful events = VaultEventful(auth.getVaultEventful());
        require(events.sellVault(msg.sender, this, _amount, _netRevenue, name, symbol));
    }
    
     
     
     
     
     
     
    function depositTokenInternal(
        address _token,
        address _hodler,
        uint256 _value,
        uint8 _forTime)
        internal
        returns (bool success)
    {
        require(now + _forTime >= depositLock[_token][_hodler]);
        require(Token(_token).approve(address(this), _value));
        require(Token(_token).transferFrom(msg.sender, address(this), _value));
        tokenBalances[_token][_hodler] = safeAdd(tokenBalances[_token][_hodler], _value);
        totalTokens[_token] = safeAdd(totalTokens[_token], _value);
        depositLock[_token][_hodler] = safeAdd(uint(now), _forTime);
        return true;
    }

     
     
     
     
     
    function getPurchaseAmounts(uint256 _totalEth)
        internal
        view
        returns (
            uint256 grossAmount,
            uint256 feeVault,
            uint256 feeVaultDao,
            uint256 amount
        )
    {
        grossAmount = safeDiv(_totalEth * BASE, data.price);
        uint256 fee = safeMul(grossAmount, data.transactionFee) / 10000;  
        return (
            grossAmount,
            feeVault = safeMul(fee , admin.ratio) / 100,
            feeVaultDao = safeSub(fee, feeVault),
            amount = safeSub(grossAmount, fee)
        );
    }

     
     
     
     
     
    function getSaleAmounts(uint256 _amount)
        internal
        view
        returns (
            uint256 feeVault,
            uint256 feeVaultDao,
            uint256 netAmount,
            uint256 netRevenue
        )
    {
        uint256 fee = safeMul(_amount, data.transactionFee) / 10000;  
        return (
            feeVault = safeMul(fee, admin.ratio) / 100,
            feeVaultDao = safeSub(fee, feeVaultDao),
            netAmount = safeSub(_amount, fee),
            netRevenue = (safeMul(netAmount, data.price) / BASE)
        );
    }

     
     
    function getNav()
        internal
        view
        returns (uint256)
    {
        uint256 aum = address(this).balance - msg.value;
        return (data.totalSupply == 0 ? data.price : safeDiv(aum * BASE, data.totalSupply));
    }
}