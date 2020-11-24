 

 

pragma solidity 0.4.25;
pragma experimental ABIEncoderV2;

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

interface ExchangesAuthority {

     
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

interface SigVerifier {

     
     
     
     
    function isValidSignature(
        bytes32 hash,
        bytes signature
    )
        external
        view
        returns (bool isValid);
}

interface NavVerifier {

     
     
     
     
     
     
     
    function isValidNav(
        uint256 sellPrice,
        uint256 buyPrice,
        uint256 signaturevaliduntilBlock,
        bytes32 hash,
        bytes signedData)
        external
        view
        returns (bool isValid);
}

interface Kyc

{
    function isWhitelistedUser(address hodler) external view returns (bool);
}

interface DragoEventful {

     
    event BuyDrago(address indexed drago, address indexed from, address indexed to, uint256 amount, uint256 revenue, bytes name, bytes symbol);
    event SellDrago(address indexed drago, address indexed from, address indexed to, uint256 amount, uint256 revenue, bytes name, bytes symbol);
    event NewRatio(address indexed drago, address indexed from, uint256 newRatio);
    event NewNAV(address indexed drago, address indexed from, address indexed to, uint256 sellPrice, uint256 buyPrice);
    event NewFee(address indexed drago, address indexed group, address indexed who, uint256 transactionFee);
    event NewCollector( address indexed drago, address indexed group, address indexed who, address feeCollector);
    event DragoDao(address indexed drago, address indexed from, address indexed to, address dragoDao);
    event DepositExchange(address indexed drago, address indexed exchange, address indexed token, uint256 value, uint256 amount);
    event WithdrawExchange(address indexed drago, address indexed exchange, address indexed token, uint256 value, uint256 amount);
    event OrderExchange(address indexed drago, address indexed exchange, address indexed cfd, uint256 value, uint256 revenue);
    event TradeExchange(address indexed drago, address indexed exchange, address tokenGet, address tokenGive, uint256 amountGet, uint256 amountGive, address get);
    event CancelOrder(address indexed drago, address indexed exchange, address indexed cfd, uint256 value, uint256 id);
    event DealFinalized(address indexed drago, address indexed exchange, address indexed cfd, uint256 value, uint256 id);
    event CustomDragoLog(bytes4 indexed methodHash, bytes encodedParams);
    event CustomDragoLog2(bytes4 indexed methodHash,  bytes32 topic2, bytes32 topic3, bytes encodedParams);
    event DragoCreated(address indexed drago, address indexed group, address indexed owner, uint256 dragoId, string name, string symbol);

     
    function buyDrago(address _who, address _targetDrago, uint256 _value, uint256 _amount, bytes _name, bytes _symbol) external returns (bool success);
    function sellDrago(address _who, address _targetDrago, uint256 _amount, uint256 _revenue, bytes _name, bytes _symbol) external returns(bool success);
    function changeRatio(address _who, address _targetDrago, uint256 _ratio) external returns(bool success);
    function changeFeeCollector(address _who, address _targetDrago, address _feeCollector) external returns(bool success);
    function changeDragoDao(address _who, address _targetDrago, address _dragoDao) external returns(bool success);
    function setDragoPrice(address _who, address _targetDrago, uint256 _sellPrice, uint256 _buyPrice) external returns(bool success);
    function setTransactionFee(address _who, address _targetDrago, uint256 _transactionFee) external returns(bool success);
    function depositToExchange(address _who, address _targetDrago, address _exchange, address _token, uint256 _value) external returns(bool success);
    function withdrawFromExchange(address _who, address _targetDrago, address _exchange, address _token, uint256 _value) external returns(bool success);
    function customDragoLog(bytes4 _methodHash, bytes _encodedParams) external returns (bool success);
    function customDragoLog2(bytes4 _methodHash, bytes32 topic2, bytes32 topic3, bytes _encodedParams) external returns (bool success);
    function customExchangeLog(bytes4 _methodHash, bytes _encodedParams) external returns (bool success);
    function customExchangeLog2(bytes4 _methodHash, bytes32 topic2, bytes32 topic3,bytes _encodedParams) external returns (bool success);
    function createDrago(address _who, address _newDrago, string _name, string _symbol, uint256 _dragoId) external returns(bool success);
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

library LibFindMethod {

     
     
     
    function findMethod(bytes assembledData)
        internal
        pure
        returns (bytes4 method)
    {
         
        assembly {
             
            method := mload(0x00)
            let transaction := assembledData
            method := mload(add(transaction, 0x20))
        }
        return method;
    }
}

 
 
 
contract Drago is Owned, SafeMath, ReentrancyGuard {

    using LibFindMethod for *;

    string constant VERSION = 'HF 0.5.2';
    uint256 constant BASE = 1000000;  

    mapping (address => Account) accounts;

    DragoData data;
    Admin admin;

    struct Receipt {
        uint256 units;
        uint32 activation;
    }

    struct Account {
        uint256 balance;
        Receipt receipt;
        mapping(address => address[]) approvedAccount;
    }

    struct Transaction {
        bytes assembledData;
    }

    struct DragoData {
        string name;
        string symbol;
        uint256 dragoId;
        uint256 totalSupply;
        uint256 sellPrice;
        uint256 buyPrice;
        uint256 transactionFee;  
        uint32 minPeriod;
    }

    struct Admin {
        address authority;
        address dragoDao;
        address feeCollector;
        address kycProvider;
        bool kycEnforced;
        uint256 minOrder;  
        uint256 ratio;  
    }

    modifier onlyDragoDao() {
        require(msg.sender == admin.dragoDao);
        _;
    }

    modifier onlyOwnerOrAuthority() {
        Authority auth = Authority(admin.authority);
        require(auth.isAuthority(msg.sender) || msg.sender == owner);
        _;
    }

    modifier whenApprovedExchangeOrWrapper(address _target) {
        bool approvedExchange = ExchangesAuthority(getExchangesAuthority())
            .isWhitelistedExchange(_target);
        bool approvedWrapper = ExchangesAuthority(getExchangesAuthority())
            .isWhitelistedWrapper(_target);
        require(approvedWrapper || approvedExchange);
        _;
    }

    modifier whenApprovedProxy(address _proxy) {
        bool approved = ExchangesAuthority(getExchangesAuthority())
            .isWhitelistedProxy(_proxy);
        require(approved);
        _;
    }

    modifier minimumStake(uint256 amount) {
        require (amount >= admin.minOrder);
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

    modifier minimumPeriodPast() {
        require(block.timestamp >= accounts[msg.sender].receipt.activation);
        _;
    }

    modifier buyPriceHigherOrEqual(uint256 _sellPrice, uint256 _buyPrice) {
        require(_sellPrice <= _buyPrice);
        _;
    }

    modifier notPriceError(uint256 _sellPrice, uint256 _buyPrice) {
        if (_sellPrice <= data.sellPrice / 10 || _buyPrice >= data.buyPrice * 10) return;
        _;
    }

    constructor(
        string _dragoName,
        string _dragoSymbol,
        uint256 _dragoId,
        address _owner,
        address _authority)
        public
    {
        data.name = _dragoName;
        data.symbol = _dragoSymbol;
        data.dragoId = _dragoId;
        data.sellPrice = 1 ether;
        data.buyPrice = 1 ether;
        owner = _owner;
        admin.authority = _authority;
        admin.dragoDao = msg.sender;
        admin.minOrder = 1 finney;
        admin.feeCollector = _owner;
        admin.ratio = 80;
    }

     
     
     
    function()
        external
        payable
    {
        require(msg.value != 0);
    }

     
     
    function buyDrago()
        external
        payable
        minimumStake(msg.value)
        returns (bool success)
    {
        require(buyDragoInternal(msg.sender));
        return true;
    }

     
     
     
    function buyDragoOnBehalf(address _hodler)
        external
        payable
        minimumStake(msg.value)
        returns (bool success)
    {
        require(buyDragoInternal(_hodler));
        return true;
    }

     
     
     
    function sellDrago(uint256 _amount)
        external
        nonReentrant
        hasEnough(_amount)
        positiveAmount(_amount)
        minimumPeriodPast
        returns (bool success)
    {
        uint256 feeDrago;
        uint256 feeDragoDao;
        uint256 netAmount;
        uint256 netRevenue;
        (feeDrago, feeDragoDao, netAmount, netRevenue) = getSaleAmounts(_amount);
        addSaleLog(_amount, netRevenue);
        allocateSaleTokens(msg.sender, _amount, feeDrago, feeDragoDao);
        data.totalSupply = safeSub(data.totalSupply, netAmount);
        msg.sender.transfer(netRevenue);
        return true;
    }

     
     
     
     
     
     
    function setPrices(
        uint256 _newSellPrice,
        uint256 _newBuyPrice,
        uint256 _signaturevaliduntilBlock,
        bytes32 _hash,
        bytes _signedData)
        external
        nonReentrant
        onlyOwnerOrAuthority
        buyPriceHigherOrEqual(_newSellPrice, _newBuyPrice)
        notPriceError(_newSellPrice, _newBuyPrice)
    {
        require(
            isValidNav(
                _newSellPrice,
                _newBuyPrice,
                _signaturevaliduntilBlock,
                _hash,
                _signedData
            )
        );
        DragoEventful events = DragoEventful(getDragoEventful());
        require(events.setDragoPrice(msg.sender, this, _newSellPrice, _newBuyPrice));
        data.sellPrice = _newSellPrice;
        data.buyPrice = _newBuyPrice;
    }

     
     
    function changeRatio(uint256 _ratio)
        external
        onlyDragoDao
    {
        DragoEventful events = DragoEventful(getDragoEventful());
        require(events.changeRatio(msg.sender, this, _ratio));
        admin.ratio = _ratio;
    }

     
     
    function setTransactionFee(uint256 _transactionFee)
        external
        onlyOwner
    {
        require(_transactionFee <= 100);  
        DragoEventful events = DragoEventful(getDragoEventful());
        require(events.setTransactionFee(msg.sender, this, _transactionFee));
        data.transactionFee = _transactionFee;
    }

     
     
    function changeFeeCollector(address _feeCollector)
        external
        onlyOwner
    {
        DragoEventful events = DragoEventful(getDragoEventful());
        events.changeFeeCollector(msg.sender, this, _feeCollector);
        admin.feeCollector = _feeCollector;
    }

     
     
    function changeDragoDao(address _dragoDao)
        external
        onlyDragoDao
    {
        DragoEventful events = DragoEventful(getDragoEventful());
        require(events.changeDragoDao(msg.sender, this, _dragoDao));
        admin.dragoDao = _dragoDao;
    }

     
     
    function changeMinPeriod(uint32 _minPeriod)
        external
        onlyDragoDao
    {
        data.minPeriod = _minPeriod;
    }

    function enforceKyc(
        bool _enforced,
        address _kycProvider)
        external
        onlyOwner
    {
        admin.kycEnforced = _enforced;
        admin.kycProvider = _kycProvider;
    }

     
     
     
     
    function setAllowance(
        address _tokenTransferProxy,
        address _token,
        uint256 _amount)
        external
        onlyOwner
        whenApprovedProxy(_tokenTransferProxy)
    {
        require(setAllowancesInternal(_tokenTransferProxy, _token, _amount));
    }

     
     
     
     
    function setMultipleAllowances(
        address _tokenTransferProxy,
        address[] _tokens,
        uint256[] _amounts)
        external
    {
        for (uint256 i = 0; i < _tokens.length; i++) {
            if (!setAllowancesInternal(_tokenTransferProxy, _tokens[i], _amounts[i])) continue;
        }
    }

     
     
     
    function operateOnExchange(
        address _exchange,
        Transaction memory transaction)
        public
        onlyOwner
        nonReentrant
        whenApprovedExchangeOrWrapper(_exchange)
        returns (bool success)
    {
        address adapter = getExchangeAdapter(_exchange);
        bytes memory transactionData = transaction.assembledData;
        require(
            methodAllowedOnExchange(
                findMethod(transactionData),
                adapter
            )
        );

        bytes memory response;
        bool failed = true;

        assembly {

            let succeeded := delegatecall(
                sub(gas, 5000),
                adapter,
                add(transactionData, 0x20),
                mload(transactionData),
                0,
                32)  

             
            response := mload(0)
            failed := iszero(succeeded)

            switch failed
            case 1 {
                 
                revert(0, 0)
            }
        }

        return (success = true);
    }

     
     
     
     
    function batchOperateOnExchange(
        address _exchange,
        Transaction[] memory transactions)
        public
        onlyOwner
        nonReentrant
        whenApprovedExchangeOrWrapper(_exchange)
    {
        for (uint256 i = 0; i < transactions.length; i++) {
            if (!operateOnExchange(_exchange, transactions[i])) continue;
        }
    }

     
     
     
     
    function balanceOf(address _who)
        external
        view
        returns (uint256)
    {
        return accounts[_who].balance;
    }

     
     
    function getEventful()
        external
        view
        returns (address)
    {
        Authority auth = Authority(admin.authority);
        return auth.getDragoEventful();
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
        name = data.name;
        symbol = data.symbol;
        sellPrice = data.sellPrice;
        buyPrice = data.buyPrice;
    }

     
     
    function calcSharePrice()
        external
        view
        returns (uint256)
    {
        return data.sellPrice;
    }

     
     
     
     
     
     
    function getAdminData()
        external
        view
        returns (
            address,  
            address feeCollector,
            address dragoDao,
            uint256 ratio,
            uint256 transactionFee,
            uint32 minPeriod
        )
    {
        return (
            owner,
            admin.feeCollector,
            admin.dragoDao,
            admin.ratio,
            data.transactionFee,
            data.minPeriod
        );
    }

    function getKycProvider()
        external
        view
        returns (address)
    {
        if(admin.kycEnforced) {
            return admin.kycProvider;
        }
    }

     
     
     
     
    function isValidSignature(
        bytes32 hash,
        bytes signature
    )
        external
        view
        returns (bool isValid)
    {
        isValid = SigVerifier(getSigVerifier())
            .isValidSignature(hash, signature);
        return isValid;
    }

     
     
    function getExchangesAuth()
        external
        view
        returns (address)
    {
        return getExchangesAuthority();
    }

     
     
    function totalSupply()
        external view
        returns (uint256)
    {
        return data.totalSupply;
    }

     

     
     
     
    function buyDragoInternal(address _hodler)
        internal
        returns (bool success)
    {
        if (admin.kycProvider != 0x0) {
            require(Kyc(admin.kycProvider).isWhitelistedUser(_hodler));
        }
        uint256 grossAmount;
        uint256 feeDrago;
        uint256 feeDragoDao;
        uint256 amount;
        (grossAmount, feeDrago, feeDragoDao, amount) = getPurchaseAmounts();
        addPurchaseLog(amount);
        allocatePurchaseTokens(_hodler, amount, feeDrago, feeDragoDao);
        data.totalSupply = safeAdd(data.totalSupply, grossAmount);
        return true;
    }

     
     
     
     
     
    function allocatePurchaseTokens(
        address _hodler,
        uint256 _amount,
        uint256 _feeDrago,
        uint256 _feeDragoDao)
        internal
    {
        accounts[_hodler].balance = safeAdd(accounts[_hodler].balance, _amount);
        accounts[admin.feeCollector].balance = safeAdd(accounts[admin.feeCollector].balance, _feeDrago);
        accounts[admin.dragoDao].balance = safeAdd(accounts[admin.dragoDao].balance, _feeDragoDao);
        accounts[_hodler].receipt.activation = uint32(now) + data.minPeriod;
    }

     
     
     
     
     
    function allocateSaleTokens(
        address _hodler,
        uint256 _amount,
        uint256 _feeDrago,
        uint256 _feeDragoDao)
        internal
    {
        accounts[_hodler].balance = safeSub(accounts[_hodler].balance, _amount);
        accounts[admin.feeCollector].balance = safeAdd(accounts[admin.feeCollector].balance, _feeDrago);
        accounts[admin.dragoDao].balance = safeAdd(accounts[admin.dragoDao].balance, _feeDragoDao);
    }

     
     
    function addPurchaseLog(uint256 _amount)
        internal
    {
        bytes memory name = bytes(data.name);
        bytes memory symbol = bytes(data.symbol);
        Authority auth = Authority(admin.authority);
        DragoEventful events = DragoEventful(auth.getDragoEventful());
        require(events.buyDrago(msg.sender, this, msg.value, _amount, name, symbol));
    }

     
     
     
    function addSaleLog(uint256 _amount, uint256 _netRevenue)
        internal
    {
        bytes memory name = bytes(data.name);
        bytes memory symbol = bytes(data.symbol);
        Authority auth = Authority(admin.authority);
        DragoEventful events = DragoEventful(auth.getDragoEventful());
        require(events.sellDrago(msg.sender, this, _amount, _netRevenue, name, symbol));
    }

     
     
     
    function setAllowancesInternal(
        address _tokenTransferProxy,
        address _token,
        uint256 _amount)
        internal
        returns (bool)
    {
        require(Token(_token)
            .approve(_tokenTransferProxy, _amount));
        return true;
    }

     
     
     
     
     
    function getPurchaseAmounts()
        internal
        view
        returns (
            uint256 grossAmount,
            uint256 feeDrago,
            uint256 feeDragoDao,
            uint256 amount
        )
    {
        grossAmount = safeDiv(msg.value * BASE, data.buyPrice);
        uint256 fee = safeMul(grossAmount, data.transactionFee) / 10000;  
        return (
            grossAmount,
            feeDrago = safeMul(fee , admin.ratio) / 100,
            feeDragoDao = safeSub(fee, feeDrago),
            amount = safeSub(grossAmount, fee)
        );
    }

     
     
     
     
     
    function getSaleAmounts(uint256 _amount)
        internal
        view
        returns (
            uint256 feeDrago,
            uint256 feeDragoDao,
            uint256 netAmount,
            uint256 netRevenue
        )
    {
        uint256 fee = safeMul(_amount, data.transactionFee) / 10000;  
        return (
            feeDrago = safeMul(fee, admin.ratio) / 100,
            feeDragoDao = safeSub(fee, feeDragoDao),
            netAmount = safeSub(_amount, fee),
            netRevenue = (safeMul(netAmount, data.sellPrice) / BASE)
        );
    }

     
     
    function getDragoEventful()
        internal
        view
        returns (address)
    {
        Authority auth = Authority(admin.authority);
        return auth.getDragoEventful();
    }

     
     
    function getSigVerifier()
        internal
        view
        returns (address)
    {
        return ExchangesAuthority(
            Authority(admin.authority)
            .getExchangesAuthority())
            .getSigVerifier();
    }

     
     
    function getNavVerifier()
        internal
        view
        returns (address)
    {
        return Authority(admin.authority)
            .getNavVerifier();
    }

     
     
     
     
     
     
     
    function isValidNav(
        uint256 sellPrice,
        uint256 buyPrice,
        uint256 signaturevaliduntilBlock,
        bytes32 hash,
        bytes signedData)
        internal
        view
        returns (bool isValid)
    {
        isValid = NavVerifier(getNavVerifier()).isValidNav(
            sellPrice,
            buyPrice,
            signaturevaliduntilBlock,
            hash,
            signedData
        );
        return isValid;
    }

     
     
    function getExchangesAuthority()
        internal
        view
        returns (address)
    {
        return Authority(admin.authority).getExchangesAuthority();
    }

     
     
     
    function getExchangeAdapter(address _exchange)
        internal
        view
        returns (address)
    {
        return ExchangesAuthority(
            Authority(admin.authority)
            .getExchangesAuthority())
            .getExchangeAdapter(_exchange);
    }

     
     
     
    function findMethod(bytes assembledData)
        internal
        pure
        returns (bytes4 method)
    {
        return method = LibFindMethod.findMethod(assembledData);
    }

     
     
     
    function methodAllowedOnExchange(
        bytes4 _method,
        address _adapter)
        internal
        view
        returns (bool)
    {
        return ExchangesAuthority(
            Authority(admin.authority)
            .getExchangesAuthority())
            .isMethodAllowed(_method, _adapter);
    }
}