 

pragma solidity ^0.4.11;

 
contract Utils {
     
    function Utils() {
    }

     
    modifier greaterThanZero(uint256 _amount) {
        require(_amount > 0);
        _;
    }

     
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

     
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

     

     
    function safeAdd(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

 
contract IOwned {
     
    function owner() public constant returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

     
    function Owned() {
        owner = msg.sender;
    }

     
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

     
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract Managed {
    address public manager;
    address public newManager;

    event ManagerUpdate(address _prevManager, address _newManager);

     
    function Managed() {
        manager = msg.sender;
    }

     
    modifier managerOnly {
        assert(msg.sender == manager);
        _;
    }

     
    function transferManagement(address _newManager) public managerOnly {
        require(_newManager != manager);
        newManager = _newManager;
    }

     
    function acceptManagement() public {
        require(msg.sender == newManager);
        ManagerUpdate(manager, newManager);
        manager = newManager;
        newManager = 0x0;
    }
}

 
contract IERC20Token {
     
    function name() public constant returns (string) {}
    function symbol() public constant returns (string) {}
    function decimals() public constant returns (uint8) {}
    function totalSupply() public constant returns (uint256) {}
    function balanceOf(address _owner) public constant returns (uint256) { _owner; }
    function allowance(address _owner, address _spender) public constant returns (uint256) { _owner; _spender; }

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 
contract ITokenConverter {
    function convertibleTokenCount() public constant returns (uint16);
    function convertibleToken(uint16 _tokenIndex) public constant returns (address);
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public constant returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public constant returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public constant returns (uint256);
}

 
contract IBancorGasPriceLimit {
    function gasPrice() public constant returns (uint256) {}
}

 
contract IBancorQuickConverter {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
}

 
contract IBancorConverterExtensions {
    function formula() public constant returns (IBancorFormula) {}
    function gasPriceLimit() public constant returns (IBancorGasPriceLimit) {}
    function quickConverter() public constant returns (IBancorQuickConverter) {}
}

 
contract TokenHolder is ITokenHolder, Owned, Utils {
     
    function TokenHolder() {
    }

     
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount)
        public
        ownerOnly
        validAddress(_token)
        validAddress(_to)
        notThis(_to)
    {
        assert(_token.transfer(_to, _amount));
    }
}

 
contract SmartTokenController is TokenHolder {
    ISmartToken public token;    

     
    function SmartTokenController(ISmartToken _token)
        validAddress(_token)
    {
        token = _token;
    }

     
    modifier active() {
        assert(token.owner() == address(this));
        _;
    }

     
    modifier inactive() {
        assert(token.owner() != address(this));
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

 
contract BancorConverter is ITokenConverter, SmartTokenController, Managed {
    uint32 private constant MAX_WEIGHT = 1000000;
    uint32 private constant MAX_CONVERSION_FEE = 1000000;

    struct Connector {
        uint256 virtualBalance;          
        uint32 weight;                   
        bool isVirtualBalanceEnabled;    
        bool isPurchaseEnabled;          
        bool isSet;                      
    }

    string public version = '0.5';
    string public converterType = 'bancor';

    IBancorConverterExtensions public extensions;        
    IERC20Token[] public connectorTokens;                
    IERC20Token[] public quickBuyPath;                   
    mapping (address => Connector) public connectors;    
    uint32 private totalConnectorWeight = 0;             
    uint32 public maxConversionFee = 0;                  
    uint32 public conversionFee = 0;                     
    bool public conversionsEnabled = true;               

     
    event Conversion(address indexed _fromToken, address indexed _toToken, address indexed _trader, uint256 _amount, uint256 _return,
                     uint256 _currentPriceN, uint256 _currentPriceD);

     
    function BancorConverter(ISmartToken _token, IBancorConverterExtensions _extensions, uint32 _maxConversionFee, IERC20Token _connectorToken, uint32 _connectorWeight)
        SmartTokenController(_token)
        validAddress(_extensions)
        validMaxConversionFee(_maxConversionFee)
    {
        extensions = _extensions;
        maxConversionFee = _maxConversionFee;

        if (address(_connectorToken) != 0x0)
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

     
    modifier validGasPrice() {
        assert(tx.gasprice <= extensions.gasPriceLimit().gasPrice());
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

     
    modifier conversionsAllowed {
        assert(conversionsEnabled);
        _;
    }

     
    function connectorTokenCount() public constant returns (uint16) {
        return uint16(connectorTokens.length);
    }

     
    function convertibleTokenCount() public constant returns (uint16) {
        return connectorTokenCount() + 1;
    }

     
    function convertibleToken(uint16 _tokenIndex) public constant returns (address) {
        if (_tokenIndex == 0)
            return token;
        return connectorTokens[_tokenIndex - 1];
    }

     
    function setExtensions(IBancorConverterExtensions _extensions)
        public
        ownerOnly
        validAddress(_extensions)
        notThis(_extensions)
    {
        extensions = _extensions;
    }

     
    function setQuickBuyPath(IERC20Token[] _path)
        public
        ownerOnly
        validConversionPath(_path)
    {
        quickBuyPath = _path;
    }

     
    function clearQuickBuyPath() public ownerOnly {
        quickBuyPath.length = 0;
    }

     
    function getQuickBuyPathLength() public constant returns (uint256) {
        return quickBuyPath.length;
    }

     
    function disableConversions(bool _disable) public managerOnly {
        conversionsEnabled = !_disable;
    }

     
    function setConversionFee(uint32 _conversionFee)
        public
        managerOnly
        validConversionFee(_conversionFee)
    {
        conversionFee = _conversionFee;
    }

     
    function getConversionFeeAmount(uint256 _amount) public constant returns (uint256) {
        return safeMul(_amount, conversionFee) / MAX_CONVERSION_FEE;
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
        connectors[_token].isPurchaseEnabled = true;
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

     
    function disableConnectorPurchases(IERC20Token _connectorToken, bool _disable)
        public
        ownerOnly
        validConnector(_connectorToken)
    {
        connectors[_connectorToken].isPurchaseEnabled = !_disable;
    }

     
    function getConnectorBalance(IERC20Token _connectorToken)
        public
        constant
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        return connector.isVirtualBalanceEnabled ? connector.virtualBalance : _connectorToken.balanceOf(this);
    }

     
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public constant returns (uint256) {
        require(_fromToken != _toToken);  

         
        if (_toToken == token)
            return getPurchaseReturn(_fromToken, _amount);
        else if (_fromToken == token)
            return getSaleReturn(_toToken, _amount);

         
        uint256 purchaseReturnAmount = getPurchaseReturn(_fromToken, _amount);
        return getSaleReturn(_toToken, purchaseReturnAmount, safeAdd(token.totalSupply(), purchaseReturnAmount));
    }

     
    function getPurchaseReturn(IERC20Token _connectorToken, uint256 _depositAmount)
        public
        constant
        active
        validConnector(_connectorToken)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        require(connector.isPurchaseEnabled);  

        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        uint256 amount = extensions.formula().calculatePurchaseReturn(tokenSupply, connectorBalance, connector.weight, _depositAmount);

         
        uint256 feeAmount = getConversionFeeAmount(amount);
        return safeSub(amount, feeAmount);
    }

     
    function getSaleReturn(IERC20Token _connectorToken, uint256 _sellAmount) public constant returns (uint256) {
        return getSaleReturn(_connectorToken, _sellAmount, token.totalSupply());
    }

     
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        require(_fromToken != _toToken);  

         
        if (_toToken == token)
            return buy(_fromToken, _amount, _minReturn);
        else if (_fromToken == token)
            return sell(_toToken, _amount, _minReturn);

         
        uint256 purchaseAmount = buy(_fromToken, _amount, 1);
        return sell(_toToken, purchaseAmount, _minReturn);
    }

     
    function buy(IERC20Token _connectorToken, uint256 _depositAmount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        uint256 amount = getPurchaseReturn(_connectorToken, _depositAmount);
        assert(amount != 0 && amount >= _minReturn);  

         
        Connector storage connector = connectors[_connectorToken];
        if (connector.isVirtualBalanceEnabled)
            connector.virtualBalance = safeAdd(connector.virtualBalance, _depositAmount);

         
        assert(_connectorToken.transferFrom(msg.sender, this, _depositAmount));
         
        token.issue(msg.sender, amount);

         
         
         
        uint256 connectorAmount = safeMul(getConnectorBalance(_connectorToken), MAX_WEIGHT);
        uint256 tokenAmount = safeMul(token.totalSupply(), connector.weight);
        Conversion(_connectorToken, token, msg.sender, _depositAmount, amount, connectorAmount, tokenAmount);
        return amount;
    }

     
    function sell(IERC20Token _connectorToken, uint256 _sellAmount, uint256 _minReturn)
        public
        conversionsAllowed
        validGasPrice
        greaterThanZero(_minReturn)
        returns (uint256)
    {
        require(_sellAmount <= token.balanceOf(msg.sender));  

        uint256 amount = getSaleReturn(_connectorToken, _sellAmount);
        assert(amount != 0 && amount >= _minReturn);  

        uint256 tokenSupply = token.totalSupply();
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
         
        assert(amount < connectorBalance || (amount == connectorBalance && _sellAmount == tokenSupply));

         
        Connector storage connector = connectors[_connectorToken];
        if (connector.isVirtualBalanceEnabled)
            connector.virtualBalance = safeSub(connector.virtualBalance, amount);

         
        token.destroy(msg.sender, _sellAmount);
         
         
        assert(_connectorToken.transfer(msg.sender, amount));

         
         
         
        uint256 connectorAmount = safeMul(getConnectorBalance(_connectorToken), MAX_WEIGHT);
        uint256 tokenAmount = safeMul(token.totalSupply(), connector.weight);
        Conversion(token, _connectorToken, msg.sender, _sellAmount, amount, tokenAmount, connectorAmount);
        return amount;
    }

     
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn)
        public
        payable
        validConversionPath(_path)
        returns (uint256)
    {
        IERC20Token fromToken = _path[0];
        IBancorQuickConverter quickConverter = extensions.quickConverter();

         
         
        if (msg.value == 0) {
             
             
            if (fromToken == token) {
                token.destroy(msg.sender, _amount);  
                token.issue(quickConverter, _amount);  
            }
            else {
                 
                assert(fromToken.transferFrom(msg.sender, quickConverter, _amount));
            }
        }

         
        return quickConverter.convertFor.value(msg.value)(_path, _amount, _minReturn, msg.sender);
    }

     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        return convert(_fromToken, _toToken, _amount, _minReturn);
    }

     
    function getSaleReturn(IERC20Token _connectorToken, uint256 _sellAmount, uint256 _totalSupply)
        private
        constant
        active
        validConnector(_connectorToken)
        greaterThanZero(_totalSupply)
        returns (uint256)
    {
        Connector storage connector = connectors[_connectorToken];
        uint256 connectorBalance = getConnectorBalance(_connectorToken);
        uint256 amount = extensions.formula().calculateSaleReturn(_totalSupply, connectorBalance, connector.weight, _sellAmount);

         
        uint256 feeAmount = getConversionFeeAmount(amount);
        return safeSub(amount, feeAmount);
    }

     
    function() payable {
        quickConvert(quickBuyPath, msg.value, 1);
    }
}