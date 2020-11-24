 

pragma solidity ^0.4.18;

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 
contract Owned is IOwned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address indexed _prevOwner, address indexed _newOwner);

     
    function Owned() public {
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
        newOwner = address(0);
    }
}

 
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

 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _depositAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _connectorBalance, uint32 _connectorWeight, uint256 _sellAmount) public view returns (uint256);
    function calculateCrossConnectorReturn(uint256 _connector1Balance, uint32 _connector1Weight, uint256 _connector2Balance, uint32 _connector2Weight, uint256 _amount) public view returns (uint256);
}

 
contract IBancorGasPriceLimit {
    function gasPrice() public view returns (uint256) {}
    function validateGasPrice(uint256) public view;
}

 
contract IBancorQuickConverter {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
    function convertForPrioritized(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, uint256 _block, uint256 _nonce, uint8 _v, bytes32 _r, bytes32 _s) public payable returns (uint256);
}

 
contract IBancorConverterExtensions {
    function formula() public view returns (IBancorFormula) {}
    function gasPriceLimit() public view returns (IBancorGasPriceLimit) {}
    function quickConverter() public view returns (IBancorQuickConverter) {}
}

 
contract IBancorConverterFactory {
    function createConverter(ISmartToken _token, IBancorConverterExtensions _extensions, uint32 _maxConversionFee, IERC20Token _connectorToken, uint32 _connectorWeight) public returns (address);
}

 
contract IBancorConverter is IOwned {
    function token() public view returns (ISmartToken) {}
    function extensions() public view returns (IBancorConverterExtensions) {}
    function quickBuyPath(uint256 _index) public view returns (IERC20Token) {}
    function maxConversionFee() public view returns (uint32) {}
    function conversionFee() public view returns (uint32) {}
    function connectorTokenCount() public view returns (uint16);
    function reserveTokenCount() public view returns (uint16);
    function connectorTokens(uint256 _index) public view returns (IERC20Token) {}
    function reserveTokens(uint256 _index) public view returns (IERC20Token) {}
    function setExtensions(IBancorConverterExtensions _extensions) public view;
    function getQuickBuyPathLength() public view returns (uint256);
    function transferTokenOwnership(address _newOwner) public view;
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public view;
    function acceptTokenOwnership() public view;
    function transferManagement(address _newManager) public view;
    function acceptManagement() public;
    function setConversionFee(uint32 _conversionFee) public view;
    function setQuickBuyPath(IERC20Token[] _path) public view;
    function addConnector(IERC20Token _token, uint32 _weight, bool _enableVirtualBalance) public view;
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function getReserveBalance(IERC20Token _reserveToken) public view returns (uint256);
    function connectors(address _address) public view returns (
        uint256 virtualBalance, 
        uint32 weight, 
        bool isVirtualBalanceEnabled, 
        bool isPurchaseEnabled, 
        bool isSet
    );
    function reserves(address _address) public view returns (
        uint256 virtualBalance, 
        uint32 weight, 
        bool isVirtualBalanceEnabled, 
        bool isPurchaseEnabled, 
        bool isSet
    );
}

 
contract BancorConverterUpgrader is Owned {
    IBancorConverterFactory public bancorConverterFactory;   

     
    event ConverterOwned(address indexed _converter, address indexed _owner);
     
    event ConverterUpgrade(address indexed _oldConverter, address indexed _newConverter);

     
    function BancorConverterUpgrader(IBancorConverterFactory _bancorConverterFactory)
        public
    {
        bancorConverterFactory = _bancorConverterFactory;
    }

     
    function setBancorConverterFactory(IBancorConverterFactory _bancorConverterFactory) public ownerOnly
    {
        bancorConverterFactory = _bancorConverterFactory;
    }

     
    function upgrade(IBancorConverter _oldConverter, bytes32 _version) public {
        bool formerVersions = false;
        if (_version == "0.4")
            formerVersions = true;
        acceptConverterOwnership(_oldConverter);
        IBancorConverter toConverter = createConverter(_oldConverter);
        copyConnectors(_oldConverter, toConverter, formerVersions);
        copyConversionFee(_oldConverter, toConverter);
        copyQuickBuyPath(_oldConverter, toConverter);
        transferConnectorsBalances(_oldConverter, toConverter, formerVersions);
        _oldConverter.transferTokenOwnership(toConverter);
        toConverter.acceptTokenOwnership();
        _oldConverter.transferOwnership(msg.sender);
        toConverter.transferOwnership(msg.sender);
        toConverter.transferManagement(msg.sender);

        ConverterUpgrade(address(_oldConverter), address(toConverter));
    }

     
    function acceptConverterOwnership(IBancorConverter _oldConverter) private {
        require(msg.sender == _oldConverter.owner());
        _oldConverter.acceptOwnership();
        ConverterOwned(_oldConverter, this);
    }

     
    function createConverter(IBancorConverter _oldConverter) private returns(IBancorConverter) {
        ISmartToken token = _oldConverter.token();
        IBancorConverterExtensions extensions = _oldConverter.extensions();
        uint32 maxConversionFee = _oldConverter.maxConversionFee();

        address converterAdderess  = bancorConverterFactory.createConverter(
            token,
            extensions,
            maxConversionFee,
            IERC20Token(address(0)),
            0
        );

        IBancorConverter converter = IBancorConverter(converterAdderess);
        converter.acceptOwnership();
        converter.acceptManagement();

        return converter;
    }

     
    function copyConnectors(IBancorConverter _oldConverter, IBancorConverter _newConverter, bool _isLegacyVersion)
        private
    {
        uint256 virtualBalance;
        uint32 weight;
        bool isVirtualBalanceEnabled;
        bool isPurchaseEnabled;
        bool isSet;
        uint16 connectorTokenCount = _isLegacyVersion ? _oldConverter.reserveTokenCount() : _oldConverter.connectorTokenCount();

        for (uint16 i = 0; i < connectorTokenCount; i++) {
            address connectorAddress = _isLegacyVersion ? _oldConverter.reserveTokens(i) : _oldConverter.connectorTokens(i);
            (virtualBalance, weight, isVirtualBalanceEnabled, isPurchaseEnabled, isSet) = readConnector(
                _oldConverter,
                connectorAddress,
                _isLegacyVersion
            );

            IERC20Token connectorToken = IERC20Token(connectorAddress);
            _newConverter.addConnector(connectorToken, weight, isVirtualBalanceEnabled);
        }
    }

     
    function copyConversionFee(IBancorConverter _oldConverter, IBancorConverter _newConverter) private {
        uint32 conversionFee = _oldConverter.conversionFee();
        _newConverter.setConversionFee(conversionFee);
    }

     
    function copyQuickBuyPath(IBancorConverter _oldConverter, IBancorConverter _newConverter) private {
        uint256 quickBuyPathLength = _oldConverter.getQuickBuyPathLength();
        if (quickBuyPathLength <= 0)
            return;

        IERC20Token[] memory path = new IERC20Token[](quickBuyPathLength);
        for (uint256 i = 0; i < quickBuyPathLength; i++) {
            path[i] = _oldConverter.quickBuyPath(i);
        }

        _newConverter.setQuickBuyPath(path);
    }

     
    function transferConnectorsBalances(IBancorConverter _oldConverter, IBancorConverter _newConverter, bool _isLegacyVersion)
        private
    {
        uint256 connectorBalance;
        uint16 connectorTokenCount = _isLegacyVersion ? _oldConverter.reserveTokenCount() : _oldConverter.connectorTokenCount();

        for (uint16 i = 0; i < connectorTokenCount; i++) {
            address connectorAddress = _isLegacyVersion ? _oldConverter.reserveTokens(i) : _oldConverter.connectorTokens(i);
            IERC20Token connector = IERC20Token(connectorAddress);
            connectorBalance = _isLegacyVersion ? _oldConverter.getReserveBalance(connector) : _oldConverter.getConnectorBalance(connector);
            _oldConverter.withdrawTokens(connector, address(_newConverter), connectorBalance);
        }
    }

     
    function readConnector(IBancorConverter _converter, address _address, bool _isLegacyVersion) 
        private
        view
        returns(uint256 virtualBalance, uint32 weight, bool isVirtualBalanceEnabled, bool isPurchaseEnabled, bool isSet)
    {
        return _isLegacyVersion ? _converter.reserves(_address) : _converter.connectors(_address);
    }
}