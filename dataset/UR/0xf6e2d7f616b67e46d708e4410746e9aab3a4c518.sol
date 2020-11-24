 

 

pragma solidity 0.4.26;

 
contract IOwned {
     
    function owner() public view returns (address) {this;}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
}

 

pragma solidity 0.4.26;


 
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

 

pragma solidity 0.4.26;

 
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

 

pragma solidity 0.4.26;

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

     
    function getAddress(bytes32 _contractName) public view returns (address);
}

 

pragma solidity 0.4.26;




 
contract ContractRegistryClient is Owned, Utils {
    bytes32 internal constant CONTRACT_FEATURES = "ContractFeatures";
    bytes32 internal constant CONTRACT_REGISTRY = "ContractRegistry";
    bytes32 internal constant NON_STANDARD_TOKEN_REGISTRY = "NonStandardTokenRegistry";
    bytes32 internal constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 internal constant BANCOR_FORMULA = "BancorFormula";
    bytes32 internal constant BANCOR_GAS_PRICE_LIMIT = "BancorGasPriceLimit";
    bytes32 internal constant BANCOR_CONVERTER_FACTORY = "BancorConverterFactory";
    bytes32 internal constant BANCOR_CONVERTER_UPGRADER = "BancorConverterUpgrader";
    bytes32 internal constant BANCOR_CONVERTER_REGISTRY = "BancorConverterRegistry";
    bytes32 internal constant BANCOR_CONVERTER_REGISTRY_DATA = "BancorConverterRegistryData";
    bytes32 internal constant BNT_TOKEN = "BNTToken";
    bytes32 internal constant BANCOR_X = "BancorX";
    bytes32 internal constant BANCOR_X_UPGRADER = "BancorXUpgrader";

    IContractRegistry public registry;       
    IContractRegistry public prevRegistry;   
    bool public adminOnly;                   

     
    modifier only(bytes32 _contractName) {
        require(msg.sender == addressOf(_contractName));
        _;
    }

     
    constructor(IContractRegistry _registry) internal validAddress(_registry) {
        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
    }

     
    function updateRegistry() public {
         
        require(!adminOnly || isAdmin());

         
        address newRegistry = addressOf(CONTRACT_REGISTRY);

         
        require(newRegistry != address(registry) && newRegistry != address(0));

         
        require(IContractRegistry(newRegistry).addressOf(CONTRACT_REGISTRY) != address(0));

         
        prevRegistry = registry;

         
        registry = IContractRegistry(newRegistry);
    }

     
    function restoreRegistry() public {
         
        require(isAdmin());

         
        registry = prevRegistry;
    }

     
    function restrictRegistryUpdate(bool _adminOnly) public {
         
        require(adminOnly != _adminOnly && isAdmin());

         
        adminOnly = _adminOnly;
    }

     
    function isAdmin() internal view returns (bool) {
        return msg.sender == owner;
    }

     
    function addressOf(bytes32 _contractName) internal view returns (address) {
        return registry.addressOf(_contractName);
    }
}

 

pragma solidity 0.4.26;

 
contract IERC20Token {
     
    function name() public view returns (string) {this;}
    function symbol() public view returns (string) {this;}
    function decimals() public view returns (uint8) {this;}
    function totalSupply() public view returns (uint256) {this;}
    function balanceOf(address _owner) public view returns (uint256) {_owner; this;}
    function allowance(address _owner, address _spender) public view returns (uint256) {_owner; _spender; this;}

    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
}

 

pragma solidity 0.4.26;

 
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

 

pragma solidity 0.4.26;



 
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256, uint256);
    function convert2(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public returns (uint256);
    function quickConvert2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public payable returns (uint256);
    function conversionsEnabled() public view returns (bool) {this;}
    function conversionWhitelist() public view returns (IWhitelist) {this;}
    function conversionFee() public view returns (uint32) {this;}
    function reserves(address _address) public view returns (uint256, uint32, bool, bool, bool) {_address; this;}
    function getReserveBalance(IERC20Token _reserveToken) public view returns (uint256);
    function reserveTokens(uint256 _index) public view returns (IERC20Token) {_index; this;}
     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
    function connectorTokens(uint256 _index) public view returns (IERC20Token);
    function connectorTokenCount() public view returns (uint16);
}

 

pragma solidity 0.4.26;


interface IBancorConverterRegistry {
    function addConverter(IBancorConverter _converter) external;
    function removeConverter(IBancorConverter _converter) external;
    function getSmartTokenCount() external view returns (uint);
    function getSmartTokens() external view returns (address[]);
    function getSmartToken(uint _index) external view returns (address);
    function isSmartToken(address _value) external view returns (bool);
    function getLiquidityPoolCount() external view returns (uint);
    function getLiquidityPools() external view returns (address[]);
    function getLiquidityPool(uint _index) external view returns (address);
    function isLiquidityPool(address _value) external view returns (bool);
    function getConvertibleTokenCount() external view returns (uint);
    function getConvertibleTokens() external view returns (address[]);
    function getConvertibleToken(uint _index) external view returns (address);
    function isConvertibleToken(address _value) external view returns (bool);
    function getConvertibleTokenSmartTokenCount(address _convertibleToken) external view returns (uint);
    function getConvertibleTokenSmartTokens(address _convertibleToken) external view returns (address[]);
    function getConvertibleTokenSmartToken(address _convertibleToken, uint _index) external view returns (address);
    function isConvertibleTokenSmartToken(address _convertibleToken, address _value) external view returns (bool);
}

 

pragma solidity 0.4.26;

interface IBancorConverterRegistryData {
    function addSmartToken(address _smartToken) external;
    function removeSmartToken(address _smartToken) external;
    function addLiquidityPool(address _liquidityPool) external;
    function removeLiquidityPool(address _liquidityPool) external;
    function addConvertibleToken(address _convertibleToken, address _smartToken) external;
    function removeConvertibleToken(address _convertibleToken, address _smartToken) external;
    function getSmartTokenCount() external view returns (uint);
    function getSmartTokens() external view returns (address[]);
    function getSmartToken(uint _index) external view returns (address);
    function isSmartToken(address _value) external view returns (bool);
    function getLiquidityPoolCount() external view returns (uint);
    function getLiquidityPools() external view returns (address[]);
    function getLiquidityPool(uint _index) external view returns (address);
    function isLiquidityPool(address _value) external view returns (bool);
    function getConvertibleTokenCount() external view returns (uint);
    function getConvertibleTokens() external view returns (address[]);
    function getConvertibleToken(uint _index) external view returns (address);
    function isConvertibleToken(address _value) external view returns (bool);
    function getConvertibleTokenSmartTokenCount(address _convertibleToken) external view returns (uint);
    function getConvertibleTokenSmartTokens(address _convertibleToken) external view returns (address[]);
    function getConvertibleTokenSmartToken(address _convertibleToken, uint _index) external view returns (address);
    function isConvertibleTokenSmartToken(address _convertibleToken, address _value) external view returns (bool);
}

 

pragma solidity 0.4.26;



 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 

pragma solidity 0.4.26;


 
contract ISmartTokenController {
    function claimTokens(address _from, uint256 _amount) public;
    function token() public view returns (ISmartToken) {this;}
}

 

pragma solidity 0.4.26;






 
contract BancorConverterRegistry is IBancorConverterRegistry, ContractRegistryClient {
     
    event SmartTokenAdded(address indexed _smartToken);

     
    event SmartTokenRemoved(address indexed _smartToken);

     
    event LiquidityPoolAdded(address indexed _liquidityPool);

     
    event LiquidityPoolRemoved(address indexed _liquidityPool);

     
    event ConvertibleTokenAdded(address indexed _convertibleToken, address indexed _smartToken);

     
    event ConvertibleTokenRemoved(address indexed _convertibleToken, address indexed _smartToken);

     
    constructor(IContractRegistry _registry) ContractRegistryClient(_registry) public {
    }

     
    function addConverter(IBancorConverter _converter) external {
         
        require(isConverterValid(_converter));

        IBancorConverterRegistryData converterRegistryData = IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA));
        ISmartToken token = ISmartTokenController(_converter).token();
        uint reserveTokenCount = _converter.connectorTokenCount();

         
        addSmartToken(converterRegistryData, token);
        if (reserveTokenCount > 1)
            addLiquidityPool(converterRegistryData, token);
        else
            addConvertibleToken(converterRegistryData, token, token);

         
        for (uint i = 0; i < reserveTokenCount; i++)
            addConvertibleToken(converterRegistryData, _converter.connectorTokens(i), token);
    }

     
    function removeConverter(IBancorConverter _converter) external {
       
        require(msg.sender == owner || !isConverterValid(_converter));

        IBancorConverterRegistryData converterRegistryData = IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA));
        ISmartToken token = ISmartTokenController(_converter).token();
        uint reserveTokenCount = _converter.connectorTokenCount();

         
        removeSmartToken(converterRegistryData, token);
        if (reserveTokenCount > 1)
            removeLiquidityPool(converterRegistryData, token);
        else
            removeConvertibleToken(converterRegistryData, token, token);

         
        for (uint i = 0; i < reserveTokenCount; i++)
            removeConvertibleToken(converterRegistryData, _converter.connectorTokens(i), token);
    }

     
    function getSmartTokenCount() external view returns (uint) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getSmartTokenCount();
    }

     
    function getSmartTokens() external view returns (address[]) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getSmartTokens();
    }

     
    function getSmartToken(uint _index) external view returns (address) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getSmartToken(_index);
    }

     
    function isSmartToken(address _value) external view returns (bool) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).isSmartToken(_value);
    }

     
    function getLiquidityPoolCount() external view returns (uint) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getLiquidityPoolCount();
    }

     
    function getLiquidityPools() external view returns (address[]) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getLiquidityPools();
    }

     
    function getLiquidityPool(uint _index) external view returns (address) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getLiquidityPool(_index);
    }

     
    function isLiquidityPool(address _value) external view returns (bool) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).isLiquidityPool(_value);
    }

     
    function getConvertibleTokenCount() external view returns (uint) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getConvertibleTokenCount();
    }

     
    function getConvertibleTokens() external view returns (address[]) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getConvertibleTokens();
    }

     
    function getConvertibleToken(uint _index) external view returns (address) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getConvertibleToken(_index);
    }

     
    function isConvertibleToken(address _value) external view returns (bool) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).isConvertibleToken(_value);
    }

     
    function getConvertibleTokenSmartTokenCount(address _convertibleToken) external view returns (uint) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartTokenCount(_convertibleToken);
    }

     
    function getConvertibleTokenSmartTokens(address _convertibleToken) external view returns (address[]) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartTokens(_convertibleToken);
    }

     
    function getConvertibleTokenSmartToken(address _convertibleToken, uint _index) external view returns (address) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).getConvertibleTokenSmartToken(_convertibleToken, _index);
    }

     
    function isConvertibleTokenSmartToken(address _convertibleToken, address _value) external view returns (bool) {
        return IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA)).isConvertibleTokenSmartToken(_convertibleToken, _value);
    }

     
    function getConvertersBySmartTokens(address[] _smartTokens) external view returns (address[]) {
        address[] memory converters = new address[](_smartTokens.length);

        for (uint i = 0; i < _smartTokens.length; i++)
            converters[i] = ISmartToken(_smartTokens[i]).owner();

        return converters;
    }

     
    function isConverterValid(IBancorConverter _converter) public view returns (bool) {
        ISmartToken token = ISmartTokenController(_converter).token();

         
        if (token.totalSupply() == 0 || token.owner() != address(_converter) || !_converter.conversionsEnabled())
            return false;

        uint reserveTokenCount = _converter.connectorTokenCount();
        address[] memory reserveTokens = new address[](reserveTokenCount);
        uint[] memory reserveRatios = new uint[](reserveTokenCount);

         
        for (uint i = 0; i < reserveTokenCount; i++) {
            IERC20Token reserveToken = _converter.connectorTokens(i);
            if (reserveToken.balanceOf(_converter) == 0)
                return false;
            reserveTokens[i] = reserveToken;
            reserveRatios[i] = connectors(_converter, reserveToken);
        }

        return getLiquidityPoolByReserveConfig(reserveTokens, reserveRatios) == IBancorConverter(0);
    }

     
    function getLiquidityPoolByReserveConfig(address[] memory _reserveTokens, uint[] memory _reserveRatios) public view returns (IBancorConverter) {
         
        if (_reserveTokens.length == _reserveRatios.length && _reserveTokens.length > 1) {

             
            address[] memory convertibleTokenSmartTokens = getLeastFrequentTokenSmartTokens(_reserveTokens);
            for (uint i = 0; i < convertibleTokenSmartTokens.length; i++) {
                ISmartToken smartToken = ISmartToken(convertibleTokenSmartTokens[i]);
                IBancorConverter converter = IBancorConverter(smartToken.owner());

                 
                uint reserveTokenCount = converter.connectorTokenCount();
                if (reserveTokenCount == _reserveTokens.length) {
                    bool identical = true;
                    for (uint j = 0; j < reserveTokenCount; j++) {
                        IERC20Token reserveToken = converter.connectorTokens(j);
                        if (reserveToken != _reserveTokens[j]) {
                            identical = false;
                            break;
                        }
                        uint256 ratio = connectors(converter, reserveToken);
                        if (ratio != _reserveRatios[j]) {
                            identical = false;
                            break;
                        }
                    }
                    if (identical)
                        return converter;
                }
            }
        }

        return IBancorConverter(0);
    }

     
    function addSmartToken(IBancorConverterRegistryData _converterRegistryData, address _smartToken) internal {
        _converterRegistryData.addSmartToken(_smartToken);
        emit SmartTokenAdded(_smartToken);
    }

     
    function removeSmartToken(IBancorConverterRegistryData _converterRegistryData, address _smartToken) internal {
        _converterRegistryData.removeSmartToken(_smartToken);
        emit SmartTokenRemoved(_smartToken);
    }

     
    function addLiquidityPool(IBancorConverterRegistryData _converterRegistryData, address _liquidityPool) internal {
        _converterRegistryData.addLiquidityPool(_liquidityPool);
        emit LiquidityPoolAdded(_liquidityPool);
    }

     
    function removeLiquidityPool(IBancorConverterRegistryData _converterRegistryData, address _liquidityPool) internal {
        _converterRegistryData.removeLiquidityPool(_liquidityPool);
        emit LiquidityPoolRemoved(_liquidityPool);
    }

     
    function addConvertibleToken(IBancorConverterRegistryData _converterRegistryData, address _convertibleToken, address _smartToken) internal {
        _converterRegistryData.addConvertibleToken(_convertibleToken, _smartToken);
        emit ConvertibleTokenAdded(_convertibleToken, _smartToken);
    }

     
    function removeConvertibleToken(IBancorConverterRegistryData _converterRegistryData, address _convertibleToken, address _smartToken) internal {
        _converterRegistryData.removeConvertibleToken(_convertibleToken, _smartToken);
        emit ConvertibleTokenRemoved(_convertibleToken, _smartToken);
    }

    function getLeastFrequentTokenSmartTokens(address[] memory _tokens) private view returns (address[] memory) {
        IBancorConverterRegistryData bancorConverterRegistryData = IBancorConverterRegistryData(addressOf(BANCOR_CONVERTER_REGISTRY_DATA));

         
        uint minSmartTokenCount = bancorConverterRegistryData.getConvertibleTokenSmartTokenCount(_tokens[0]);
        address[] memory smartTokens = bancorConverterRegistryData.getConvertibleTokenSmartTokens(_tokens[0]);
        for (uint i = 1; i < _tokens.length; i++) {
            uint convertibleTokenSmartTokenCount = bancorConverterRegistryData.getConvertibleTokenSmartTokenCount(_tokens[i]);
            if (minSmartTokenCount > convertibleTokenSmartTokenCount) {
                minSmartTokenCount = convertibleTokenSmartTokenCount;
                smartTokens = bancorConverterRegistryData.getConvertibleTokenSmartTokens(_tokens[i]);
            }
        }
        return smartTokens;
    }

    bytes4 private constant CONNECTORS_FUNC_SELECTOR = bytes4(uint256(keccak256("connectors(address)") >> (256 - 4 * 8)));

    function connectors(address _dest, address _address) private view returns (uint256) {
        uint256[2] memory ret;
        bytes memory data = abi.encodeWithSelector(CONNECTORS_FUNC_SELECTOR, _address);

        assembly {
            let success := staticcall(
                gas,            
                _dest,          
                add(data, 32),  
                mload(data),    
                ret,            
                64              
            )
            if iszero(success) {
                revert(0, 0)
            }
        }

        return ret[1];
    }
}