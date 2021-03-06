 

pragma solidity ^0.4.24;

 

 
contract IERC20Token {
     
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 

 
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

 

 
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256, uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function conversionWhitelist() public view returns (IWhitelist) {}
    function conversionFee() public view returns (uint32) {}
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool) { _address; }
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function claimTokens(address _from, uint256 _amount) public;
     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
}

 

 
contract IBancorConverterUpgrader {
    function upgrade(bytes32 _version) public;
    function upgrade(uint16 _version) public;
}

 

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256);
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256);
}

 

 
contract IBancorNetwork {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
    
    function convertForPrioritized3(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _customVal,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable returns (uint256);
    
     
    function convertForPrioritized2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable returns (uint256);

     
    function convertForPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public payable returns (uint256);
}

 

 
contract ContractIds {
     
    bytes32 public constant CONTRACT_FEATURES = "ContractFeatures";
    bytes32 public constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 public constant NON_STANDARD_TOKEN_REGISTRY = "NonStandardTokenRegistry";

     
    bytes32 public constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 public constant BANCOR_FORMULA = "BancorFormula";
    bytes32 public constant BANCOR_GAS_PRICE_LIMIT = "BancorGasPriceLimit";
    bytes32 public constant BANCOR_CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 public constant BANCOR_CONVERTER_FACTORY = "BancorConverterFactory";

     
    bytes32 public constant BNT_TOKEN = "BNTToken";
    bytes32 public constant BNT_CONVERTER = "BNTConverter";

     
    bytes32 public constant BANCOR_X = "BancorX";
    bytes32 public constant BANCOR_X_UPGRADER = "BancorXUpgrader";
}

 

 
contract FeatureIds {
     
    uint256 public constant CONVERTER_CONVERSION_WHITELIST = 1 << 0;
}

 

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

     
    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 

 
contract Managed is Owned {
    address public manager;
    address public newManager;

     
    event ManagerUpdate(address indexed _prevManager, address indexed _newManager);

     
    constructor() public {
        manager = msg.sender;
    }

     
    modifier managerOnly {
        assert(msg.sender == manager);
        _;
    }

     
    modifier ownerOrManagerOnly {
        require(msg.sender == owner || msg.sender == manager);
        _;
    }

     
    function transferManagement(address _newManager) public ownerOrManagerOnly {
        require(_newManager != manager);
        newManager = _newManager;
    }

     
    function acceptManagement() public {
        require(msg.sender == newManager);
        emit ManagerUpdate(manager, newManager);
        manager = newManager;
        newManager = address(0);
    }
}

 

 
contract Utils {
     
    constructor() public {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != address(0));
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

}

 

 
library SafeMath {
     
    function add(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        require(z >= _x);
        return z;
    }

     
    function sub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_x >= _y);
        return _x - _y;
    }

     
    function mul(uint256 _x, uint256 _y) internal pure returns (uint256) {
         
        if (_x == 0)
            return 0;

        uint256 z = _x * _y;
        require(z / _x == _y);
        return z;
    }

       
    function div(uint256 _x, uint256 _y) internal pure returns (uint256) {
        require(_y > 0);
        uint256 c = _x / _y;

        return c;
    }
}

 

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

     
    function getAddress(bytes32 _contractName) public view returns (address);
}

 

 
contract IContractFeatures {
    function isSupported(address _contract, uint256 _features) public view returns (bool);
    function enableFeatures(uint256 _features, bool _enable) public;
}

 

 
contract IAddressList {
    mapping (address => bool) public listedAddresses;
}

 

 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 

 
contract INonStandardERC20 {
     
    function name() public view returns (string) {}
    function symbol() public view returns (string) {}
    function decimals() public view returns (uint8) {}
    function totalSupply() public view returns (uint256) {}
    function balanceOf(address _owner) public view returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public view returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public;
    function transferFrom(address _from, address _to, uint256 _value) public;
    function approve(address _spender, uint256 _value) public;
}

 

 
contract TokenHolder is ITokenHolder, Owned, Utils {
     
    constructor() public {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        INonStandardERC20(_token).transfer(_to, _amount);
    }
}

 

 
contract SmartTokenController is TokenHolder {
    ISmartToken public token;    

     
    constructor(ISmartToken _token)
        public
        validAddress(_token)
    {
        token = _token;
    }

     
    modifier active() {
        require(token.owner() == address(this));
        _;
    }

     
    modifier inactive() {
        require(token.owner() != address(this));
        _;
    }

     
    function transferTokenOwnership(address _newOwner) public ownerOnly {
        token.transferOwnership(_newOwner);
    }

     
    function acceptTokenOwnership() public ownerOnly {
        token.acceptOwnership();
    }

     
    function disableTokenTransfers(bool _disable) public ownerOnly {
        token.disableTransfers(_disable);
    }

     
    function withdrawFromToken(IERC20Token _token, address _to, uint256 _amount) public ownerOnly {
        ITokenHolder(token).withdrawTokens(_token, _to, _amount);
    }
}

 

 
contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
    function withdrawTo(address _to, uint256 _amount) public;
}

 

contract IBancorX {
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) public;
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256);
}

 

 
contract BancorConverter is IBancorConverter, SmartTokenController, Managed, ContractIds, FeatureIds {
    using SafeMath for uint256;

    
    uint32 private constant MAX_WEIGHT = 1000000;
    uint64 private constant MAX_CONVERSION_FEE = 1000000;

    struct Connector {
        uint256 virtualBalance;          
        uint32 weight;                   
        bool isVirtualBalanceEnabled;    
        bool isSaleEnabled;              
        bool isSet;                      
    }

     
    uint16 public version = 14;
    string public converterType = 'bancor';

    bool public allowRegistryUpdate = true;              
    bool public claimTokensEnabled = false;              
    IContractRegistry public prevRegistry;               
    IContractRegistry public registry;                   
    IWhitelist public conversionWhitelist;               
    IERC20Token[] public connectorTokens;                
    mapping (address => Connector) public connectors;    
    uint32 private totalConnectorWeight = 0;             
    uint32 public maxConversionFee = 0;                  
                                                         
    uint32 public conversionFee = 0;                     
    bool public conversionsEnabled = true;               
    IERC20Token[] private convertPath;

     
    event Conversion(
        address indexed _fromToken,
        address indexed _toToken,
        address indexed _trader,
        uint256 _amount,
        uint256 _return,
        int256 _conversionFee
    );

     
    event PriceDataUpdate(
        address indexed _connectorToken,
        uint256 _tokenSupply,
        uint256 _connectorBalance,
        uint32 _connectorWeight
    );

     
    event ConversionFeeUpdate(uint32 _prevFee, uint32 _newFee);

     
    event ConversionsEnable(bool _conversionsEnabled);

     
    constructor(
        ISmartToken _token,
        IContractRegistry _registry,
        uint32 _maxConversionFee,
        IERC20Token _connectorToken,
        uint32 _connectorWeight
    )
        public
        SmartTokenController(_token)
        validAddress(_registry)
        validMaxConversionFee(_maxConversionFee)
    {
        registry = _registry;
        prevRegistry = _registry;
        IContractFeatures features = IContractFeatures(registry.addressOf(ContractIds.CONTRACT_FEATURES));

         
        if (features != address(0))
            features.enableFeatures(FeatureIds.CONVERTER_CONVERSION_WHITELIST, true);

        maxConversionFee = _maxConversionFee;

        if (_connectorToken != address(0))
            addConnector(_connectorToken, _connectorWeight, false);
    }

     
    modifier validConnector(IERC20Token _address) {
        require(connectors[_address].isSet);
        _;
    }

     
    modifier validToken(IERC20Token _address) {
        require(_address == token || connectors[_address].isSet);
        _;
    }

     
    modifier validMaxConversionFee(uint32 _conversionFee) {
        require(_conversionFee >= 0 && _conversionFee <= MAX_CONVERSION_FEE);
        _;
    }

     
    modifier validConversionFee(uint32 _conversionFee) {
        require(_conversionFee >= 0 && _conversionFee <= maxConversionFee);
        _;
    }

     
    modifier validConnectorWeight(uint32 _weight) {
        require(_weight > 0 && _weight <= MAX_WEIGHT);
        _;
    }

     
    modifier validConversionPath(IERC20Token[] _path) {
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);
        _;
    }

     
    modifier maxTotalWeightOnly() {
        require(totalConnectorWeight == MAX_WEIGHT);
        _;
    }

     
    modifier conversionsAllowed {
        assert(conversionsEnabled);
        _;
    }

     
    modifier bancorNetworkOnly {
        IBancorNetwork bancorNetwork = IBancorNetwork(registry.addressOf(ContractIds.BANCOR_NETWORK));
        require(msg.sender == address(bancorNetwork));
        _;
    }

     
    modifier converterUpgraderOnly {
        address converterUpgrader = registry.addressOf(ContractIds.BANCOR_CONVERTER_UPGRADER);
        require(owner == converterUpgrader);
        _;
    }

     
    modifier whenClaimTokensEnabled {
        require(claimTokensEnabled);
        _;
    }

     
    function updateRegistry() public {
         
        require(allowRegistryUpdate || msg.sender == owner);

         
        address newRegistry = registry.addressOf(ContractIds.CONTRACT_REGISTRY);

         
        require(newRegistry != address(registry) && newRegistry != address(0));

         
        prevRegistry = registry;
        registry = IContractRegistry(newRegistry);
    }

     
    function restoreRegistry() public ownerOrManagerOnly {
         
        registry = prevRegistry;

         
        allowRegistryUpdate = false;
    }

     
    function disableRegistryUpdate(bool _disable) public ownerOrManagerOnly {
        allowRegistryUpdate = !_disable;
    }

     
    function enableClaimTokens(bool _enable) public ownerOnly {
        claimTokensEnabled = _enable;
    }

     
    function connectorTokenCount() public view returns (uint16) {
        return uint16(connectorTokens.length);
    }

     
    function setConversionWhitelist(IWhitelist _whitelist)
        public
        ownerOnly
        notThis(_whitelist)
    {
        conversionWhitelist = _whitelist;
    }

     
    function disableConversions(bool _disable) public ownerOrManagerOnly {
        if (conversionsEnabled == _disable) {
            conversionsEnabled = !_disable;
            emit ConversionsEnable(conversionsEnabled);
        }
    }

     
    function transferTokenOwnership(address _newOwner)
        public
        ownerOnly
        converterUpgraderOnly
    {
        super.transferTokenOwnership(_newOwner);
    }

     
    function setConversionFee(uint32 _conversionFee)
        public
        ownerOrManagerOnly
        validConversionFee(_conversionFee)
    {
        emit ConversionFeeUpdate(conversionFee, _conversionFee);
        conversionFee = _conversionFee;
    }

     
    function getFinalAmount(uint256 _amount, uint8 _magnitude) public view returns (uint256) {
        return _amount.mul((MAX_CONVERSION_FEE - conversionFee) ** _magnitude).div(MAX_CONVERSION_FEE ** _magnitude);
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public {
        address converterUpgrader = registry.addressOf(ContractIds.BANCOR_CONVERTER_UPGRADER);

         
         
        require(!connectors[_token].isSet || token.owner() != address(this) || owner == converterUpgrader);
        super.withdrawTokens(_token, _to, _amount);
    }

     
    function claimTokens(address _from, uint256 _amount) public whenClaimTokensEnabled {
        address bancorX = registry.addressOf(ContractIds.BANCOR_X);

         
        require(msg.sender == bancorX);

         
        token.destroy(_from, _amount);
        token.issue(msg.sender, _amount);
    }

     
    function upgrade() public ownerOnly {
        IBancorConverterUpgrader converterUpgrader = IBancorConverterUpgrader(registry.addressOf(ContractIds.BANCOR_CONVERTER_UPGRADER));

        transferOwnership(converterUpgrader);
        converterUpgrader.upgrade(version);
        acceptOwnership();
    }

     
    function addConnector(IERC20Token _token, uint32 _weight, bool _enableVirtualBalance)
        public
        ownerOnly
        inactive
        validAddress(_token)
        notThis(_token)
        validConnectorWeight(_weight)
    {
        require(_token != token && !connectors[_token].isSet && totalConnectorWeight + _weight <= MAX_WEIGHT);  

        connectors[_token].virtualBalance = 0;
        connectors[_token].weight = _weight;
        connectors[_token].isVirtualBalanceEnabled = _enableVirtualBalance;
        connectors[_token].isSaleEnabled = true;
        connectors[_token].isSet = true;
        connectorTokens.push(_token);
        totalConnectorWeight += _weight;
    }

     
    function updateConnector(IERC20Token _connectorToken, uint32 _weight, bool _enableVirtualBalance, uint256 _virtualBalance)
        public
        ownerOnly
        validConnector(_connectorToken)
        validConnectorWeight(_weight)
    {
        Connector storage connector = connectors[_connectorToken];
        require(totalConnectorWeight - connector.weight + _weight <= MAX_WEIGHT);  

        totalConnectorWeight = totalConnectorWeight - connector.weight + _weight;
        connector.weight = _weight;
        connector.isVirtualBalanceEnabled = _enableVirtualBalance;
        connector.virtualBalance = _virtualBalance;
    }

     
    function disableConnectorSale(IERC20Token _connectorToken, bool _disable)
        public
        ownerOnly
        validConnector(_connectorToken)
    {
        connectors[_connectorToken].isSaleEnabled = !_disable;
    }

     
    function getConnectorBalance(IERC20Token _connectorToken)
        public
        view
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        return connector.isVirtualBalanceEnabled ? connector.virtualBalance : _connectorToken.balanceOf(this);
    }

     
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256, uint256) {
        require(_fromToken != _toToken);  

         
        if (_toToken == token)
            return getPurchaseReturn(_fromToken, _amount);
        else if (_fromToken == token)
            return getSaleReturn(_toToken, _amount);

         
        return getCrossConnectorReturn(_fromToken, _toToken, _amount);
    }

     
    function getPurchaseReturn(IERC20Token _connectorToken, uint256 _depositAmount)
        public
        view
        active
        validConnector(_connectorToken)
        returns (uint256, uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        require(connector.isSaleEnabled);  

        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculatePurchaseReturn(tokenSupply, connectorBalance, connector.weight, _depositAmount);
        uint256 finalAmount = getFinalAmount(amount, 1);

         
        return (finalAmount, amount - finalAmount);
    }

     
    function getSaleReturn(IERC20Token _connectorToken, uint256 _sellAmount)
        public
        view
        active
        validConnector(_connectorToken)
        returns (uint256, uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculateSaleReturn(tokenSupply, connectorBalance, connector.weight, _sellAmount);
        uint256 finalAmount = getFinalAmount(amount, 1);

         
        return (finalAmount, amount - finalAmount);
    }

     
    function getCrossConnectorReturn(IERC20Token _fromConnectorToken, IERC20Token _toConnectorToken, uint256 _sellAmount)
        public
        view
        active
        validConnector(_fromConnectorToken)
        validConnector(_toConnectorToken)
        returns (uint256, uint256)
    {
        Connector storage fromConnector = connectors[_fromConnectorToken];
        Connector storage toConnector = connectors[_toConnectorToken];
        require(fromConnector.isSaleEnabled);  

        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));
        uint256 amount = formula.calculateCrossConnectorReturn(
            getConnectorBalance(_fromConnectorToken), 
            fromConnector.weight, 
            getConnectorBalance(_toConnectorToken), 
            toConnector.weight, 
            _sellAmount);
        uint256 finalAmount = getFinalAmount(amount, 2);

         
         
        return (finalAmount, amount - finalAmount);
    }

     
    function convertInternal(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn)
        public
        bancorNetworkOnly
        conversionsAllowed
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(_fromToken != _toToken);  

         
        if (_toToken == token)
            return buy(_fromToken, _amount, _minReturn);
        else if (_fromToken == token)
            return sell(_toToken, _amount, _minReturn);

        uint256 amount;
        uint256 feeAmount;

         
        (amount, feeAmount) = getCrossConnectorReturn(_fromToken, _toToken, _amount);
         
        require(amount != 0 && amount >= _minReturn);

         
        Connector storage fromConnector = connectors[_fromToken];
        if (fromConnector.isVirtualBalanceEnabled)
            fromConnector.virtualBalance = fromConnector.virtualBalance.add(_amount);

         
        Connector storage toConnector = connectors[_toToken];
        if (toConnector.isVirtualBalanceEnabled)
            toConnector.virtualBalance = toConnector.virtualBalance.sub(amount);

         
        uint256 toConnectorBalance = getConnectorBalance(_toToken);
        assert(amount < toConnectorBalance);

         
        ensureTransferFrom(_fromToken, msg.sender, this, _amount);
         
         
        ensureTransfer(_toToken, msg.sender, amount);

         
         
        dispatchConversionEvent(_fromToken, _toToken, _amount, amount, feeAmount);

         
        emit PriceDataUpdate(_fromToken, token.totalSupply(), getConnectorBalance(_fromToken), fromConnector.weight);
        emit PriceDataUpdate(_toToken, token.totalSupply(), getConnectorBalance(_toToken), toConnector.weight);
        return amount;
    }

     
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        convertPath = [_fromToken, token, _toToken];
        return quickConvert(convertPath, _amount, _minReturn);
    }

     
    function buy(IERC20Token _connectorToken, uint256 _depositAmount, uint256 _minReturn) internal returns (uint256) {
        uint256 amount;
        uint256 feeAmount;
        (amount, feeAmount) = getPurchaseReturn(_connectorToken, _depositAmount);
         
        require(amount != 0 && amount >= _minReturn);

         
        Connector storage connector = connectors[_connectorToken];
        if (connector.isVirtualBalanceEnabled)
            connector.virtualBalance = connector.virtualBalance.add(_depositAmount);

         
        ensureTransferFrom(_connectorToken, msg.sender, this, _depositAmount);
         
        token.issue(msg.sender, amount);

         
        dispatchConversionEvent(_connectorToken, token, _depositAmount, amount, feeAmount);

         
        emit PriceDataUpdate(_connectorToken, token.totalSupply(), getConnectorBalance(_connectorToken), connector.weight);
        return amount;
    }

     
    function sell(IERC20Token _connectorToken, uint256 _sellAmount, uint256 _minReturn) internal returns (uint256) {
        require(_sellAmount <= token.balanceOf(msg.sender));  
        uint256 amount;
        uint256 feeAmount;
        (amount, feeAmount) = getSaleReturn(_connectorToken, _sellAmount);
         
        require(amount != 0 && amount >= _minReturn);

         
        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        assert(amount < connectorBalance || (amount == connectorBalance && _sellAmount == tokenSupply));

         
        Connector storage connector = connectors[_connectorToken];
        if (connector.isVirtualBalanceEnabled)
            connector.virtualBalance = connector.virtualBalance.sub(amount);

         
        token.destroy(msg.sender, _sellAmount);
         
         
        ensureTransfer(_connectorToken, msg.sender, amount);

         
        dispatchConversionEvent(token, _connectorToken, _sellAmount, amount, feeAmount);

         
        emit PriceDataUpdate(_connectorToken, token.totalSupply(), getConnectorBalance(_connectorToken), connector.weight);
        return amount;
    }

     
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        returns (uint256)
    {
        return quickConvertPrioritized(_path, _amount, _minReturn, 0x0, 0x0, 0x0, 0x0);
    }

     
    function quickConvertPrioritized(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, uint256 _block, uint8 _v, bytes32 _r, bytes32 _s)
        public
        payable
        returns (uint256)
    {
        IERC20Token fromToken = _path[0];
        IBancorNetwork bancorNetwork = IBancorNetwork(registry.addressOf(ContractIds.BANCOR_NETWORK));

         
         
        if (msg.value == 0) {
             
             
             
            if (fromToken == token) {
                token.destroy(msg.sender, _amount);  
                token.issue(bancorNetwork, _amount);  
            } else {
                 
                ensureTransferFrom(fromToken, msg.sender, bancorNetwork, _amount);
            }
        }

         
        return bancorNetwork.convertForPrioritized3.value(msg.value)(_path, _amount, _minReturn, msg.sender, _amount, _block, _v, _r, _s);
    }

     
    function completeXConversion(
        IERC20Token[] _path,
        uint256 _minReturn,
        uint256 _conversionId,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        returns (uint256)
    {
        IBancorX bancorX = IBancorX(registry.addressOf(ContractIds.BANCOR_X));
        IBancorNetwork bancorNetwork = IBancorNetwork(registry.addressOf(ContractIds.BANCOR_NETWORK));

         
        require(_path[0] == registry.addressOf(ContractIds.BNT_TOKEN));

         
        uint256 amount = bancorX.getXTransferAmount(_conversionId, msg.sender);

         
        token.destroy(msg.sender, amount);
        token.issue(bancorNetwork, amount);

        return bancorNetwork.convertForPrioritized3(_path, amount, _minReturn, msg.sender, _conversionId, _block, _v, _r, _s);
    }

     
    function ensureTransfer(IERC20Token _token, address _to, uint256 _amount) private {
        IAddressList addressList = IAddressList(registry.addressOf(ContractIds.NON_STANDARD_TOKEN_REGISTRY));

        if (addressList.listedAddresses(_token)) {
            uint256 prevBalance = _token.balanceOf(_to);
             
            INonStandardERC20(_token).transfer(_to, _amount);
            uint256 postBalance = _token.balanceOf(_to);
            assert(postBalance > prevBalance);
        } else {
             
            assert(_token.transfer(_to, _amount));
        }
    }

     
    function ensureTransferFrom(IERC20Token _token, address _from, address _to, uint256 _amount) private {
        IAddressList addressList = IAddressList(registry.addressOf(ContractIds.NON_STANDARD_TOKEN_REGISTRY));

        if (addressList.listedAddresses(_token)) {
            uint256 prevBalance = _token.balanceOf(_to);
             
            INonStandardERC20(_token).transferFrom(_from, _to, _amount);
            uint256 postBalance = _token.balanceOf(_to);
            assert(postBalance > prevBalance);
        } else {
             
            assert(_token.transferFrom(_from, _to, _amount));
        }
    }

     
    function fund(uint256 _amount)
        public
        maxTotalWeightOnly
        conversionsAllowed
    {
        uint256 supply = token.totalSupply();

         
         
        IERC20Token connectorToken;
        uint256 connectorBalance;
        uint256 connectorAmount;
        for (uint16 i = 0; i < connectorTokens.length; i++) {
            connectorToken = connectorTokens[i];
            connectorBalance = getConnectorBalance(connectorToken);
            connectorAmount = _amount.mul(connectorBalance).sub(1).div(supply).add(1);

             
            Connector storage connector = connectors[connectorToken];
            if (connector.isVirtualBalanceEnabled)
                connector.virtualBalance = connector.virtualBalance.add(connectorAmount);

             
            ensureTransferFrom(connectorToken, msg.sender, this, connectorAmount);

             
            emit PriceDataUpdate(connectorToken, supply + _amount, connectorBalance + connectorAmount, connector.weight);
        }

         
        token.issue(msg.sender, _amount);
    }

     
    function liquidate(uint256 _amount) public maxTotalWeightOnly {
        uint256 supply = token.totalSupply();

         
        token.destroy(msg.sender, _amount);

         
         
        IERC20Token connectorToken;
        uint256 connectorBalance;
        uint256 connectorAmount;
        for (uint16 i = 0; i < connectorTokens.length; i++) {
            connectorToken = connectorTokens[i];
            connectorBalance = getConnectorBalance(connectorToken);
            connectorAmount = _amount.mul(connectorBalance).div(supply);

             
            Connector storage connector = connectors[connectorToken];
            if (connector.isVirtualBalanceEnabled)
                connector.virtualBalance = connector.virtualBalance.sub(connectorAmount);

             
             
            ensureTransfer(connectorToken, msg.sender, connectorAmount);

             
            emit PriceDataUpdate(connectorToken, supply - _amount, connectorBalance - connectorAmount, connector.weight);
        }
    }

     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        return convertInternal(_fromToken, _toToken, _amount, _minReturn);
    }

     
    function dispatchConversionEvent(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _returnAmount, uint256 _feeAmount) private {
         
         
         
         
        assert(_feeAmount <= 2 ** 255);
        emit Conversion(_fromToken, _toToken, msg.sender, _amount, _returnAmount, int256(_feeAmount));
    }
}