 

pragma solidity ^0.4.21;

 
contract IOwned {
     
    function owner() public view returns (address) {}

    function transferOwnership(address _newOwner) public;
    function acceptOwnership() public;
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

 
contract IContractRegistry {
    function getAddress(bytes32 _contractName) public view returns (address);
}

 
contract IContractFeatures {
    function isSupported(address _contract, uint256 _features) public view returns (bool);
    function enableFeatures(uint256 _features, bool _enable) public;
}

 
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

 
contract ITokenHolder is IOwned {
    function withdrawTokens(IERC20Token _token, address _to, uint256 _amount) public;
}

 
contract IEtherToken is ITokenHolder, IERC20Token {
    function deposit() public payable;
    function withdraw(uint256 _amount) public;
    function withdrawTo(address _to, uint256 _amount) public;
}

 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 
contract IBancorGasPriceLimit {
    function gasPrice() public view returns (uint256) {}
    function validateGasPrice(uint256) public view;
}

 
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function conversionWhitelist() public view returns (IWhitelist) {}
     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
}

 
contract IBancorNetwork {
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256);
    function convertForPrioritized2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);

     
    function convertForPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256);
}

 
contract Utils {
     
    function Utils() public {
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

     

     
    function safeAdd(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

     
    function safeSub(uint256 _x, uint256 _y) internal pure returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

     
    function safeMul(uint256 _x, uint256 _y) internal pure returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
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
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract ContractIds {
    bytes32 public constant BANCOR_NETWORK = "BancorNetwork";
    bytes32 public constant BANCOR_FORMULA = "BancorFormula";
    bytes32 public constant CONTRACT_FEATURES = "ContractFeatures";
}

 
contract FeatureIds {
     
    uint256 public constant CONVERTER_CONVERSION_WHITELIST = 1 << 0;
}

 
contract TokenHolder is ITokenHolder, Owned, Utils {
     
    function TokenHolder() public {
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

 
contract BancorNetwork is IBancorNetwork, TokenHolder, ContractIds, FeatureIds {
    address public signerAddress = 0x0;          
    IContractRegistry public registry;           
    IBancorGasPriceLimit public gasPriceLimit;   

    mapping (address => bool) public etherTokens;        
    mapping (bytes32 => bool) public conversionHashes;   

     
    function BancorNetwork(IContractRegistry _registry) public validAddress(_registry) {
        registry = _registry;
    }

     
    modifier validConversionPath(IERC20Token[] _path) {
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);
        _;
    }

     
    function setContractRegistry(IContractRegistry _registry)
        public
        ownerOnly
        validAddress(_registry)
        notThis(_registry)
    {
        registry = _registry;
    }

     
    function setGasPriceLimit(IBancorGasPriceLimit _gasPriceLimit)
        public
        ownerOnly
        validAddress(_gasPriceLimit)
        notThis(_gasPriceLimit)
    {
        gasPriceLimit = _gasPriceLimit;
    }

     
    function setSignerAddress(address _signerAddress)
        public
        ownerOnly
        validAddress(_signerAddress)
        notThis(_signerAddress)
    {
        signerAddress = _signerAddress;
    }

     
    function registerEtherToken(IEtherToken _token, bool _register)
        public
        ownerOnly
        validAddress(_token)
        notThis(_token)
    {
        etherTokens[_token] = _register;
    }

     
    function verifyTrustedSender(IERC20Token[] _path, uint256 _amount, uint256 _block, address _addr, uint8 _v, bytes32 _r, bytes32 _s) private returns(bool) {
        bytes32 hash = keccak256(_block, tx.gasprice, _addr, msg.sender, _amount, _path);

         
         
         
        require(!conversionHashes[hash] && block.number <= _block);

         
         
        bytes32 prefixedHash = keccak256("\x19Ethereum Signed Message:\n32", hash);
        bool verified = ecrecover(prefixedHash, _v, _r, _s) == signerAddress;

         
         
        if (verified)
            conversionHashes[hash] = true;
        return verified;
    }

     
    function convertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public payable returns (uint256) {
        return convertForPrioritized2(_path, _amount, _minReturn, _for, 0x0, 0x0, 0x0, 0x0);
    }

     
    function convertForPrioritized2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, uint256 _block, uint8 _v, bytes32 _r, bytes32 _s)
        public
        payable
        validConversionPath(_path)
        returns (uint256)
    {
         
        IERC20Token fromToken = _path[0];
        require(msg.value == 0 || (_amount == msg.value && etherTokens[fromToken]));

         
         
        if (msg.value > 0)
            IEtherToken(fromToken).deposit.value(msg.value)();

        return convertForInternal(_path, _amount, _minReturn, _for, _block, _v, _r, _s);
    }

     
    function convertForMultiple(IERC20Token[] _paths, uint256[] _pathStartIndex, uint256[] _amounts, uint256[] _minReturns, address _for)
        public
        payable
        returns (uint256[])
    {
         
        uint256 convertedValue = 0;
        uint256 pathEndIndex;
        
         
        for (uint256 i = 0; i < _pathStartIndex.length; i += 1) {
            pathEndIndex = i == (_pathStartIndex.length - 1) ? _paths.length : _pathStartIndex[i + 1];

             
            IERC20Token[] memory path = new IERC20Token[](pathEndIndex - _pathStartIndex[i]);
            for (uint256 j = _pathStartIndex[i]; j < pathEndIndex; j += 1) {
                path[j - _pathStartIndex[i]] = _paths[j];
            }

             
             
             
            IERC20Token fromToken = path[0];
            require(msg.value == 0 || (_amounts[i] <= msg.value && etherTokens[fromToken]) || !etherTokens[fromToken]);

             
             
            if (msg.value > 0 && etherTokens[fromToken]) {
                IEtherToken(fromToken).deposit.value(_amounts[i])();
                convertedValue += _amounts[i];
            }
            _amounts[i] = convertForInternal(path, _amounts[i], _minReturns[i], _for, 0x0, 0x0, 0x0, 0x0);
        }

         
        require(convertedValue == msg.value);

        return _amounts;
    }

     
    function convertForInternal(
        IERC20Token[] _path, 
        uint256 _amount, 
        uint256 _minReturn, 
        address _for, 
        uint256 _block, 
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s
    )
        private
        validConversionPath(_path)
        returns (uint256)
    {
        if (_v == 0x0 && _r == 0x0 && _s == 0x0)
            gasPriceLimit.validateGasPrice(tx.gasprice);
        else
            require(verifyTrustedSender(_path, _amount, _block, _for, _v, _r, _s));

         
        IERC20Token fromToken = _path[0];

        IERC20Token toToken;
        
        (toToken, _amount) = convertByPath(_path, _amount, _minReturn, fromToken, _for);

         
         
         
        if (etherTokens[toToken])
            IEtherToken(toToken).withdrawTo(_for, _amount);
        else
            assert(toToken.transfer(_for, _amount));

        return _amount;
    }

     
    function convertByPath(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        IERC20Token _fromToken,
        address _for
    ) private returns (IERC20Token, uint256) {
        ISmartToken smartToken;
        IERC20Token toToken;
        IBancorConverter converter;

         
        IContractFeatures features = IContractFeatures(registry.getAddress(ContractIds.CONTRACT_FEATURES));

         
        uint256 pathLength = _path.length;
        for (uint256 i = 1; i < pathLength; i += 2) {
            smartToken = ISmartToken(_path[i]);
            toToken = _path[i + 1];
            converter = IBancorConverter(smartToken.owner());
            checkWhitelist(converter, _for, features);

             
            if (smartToken != _fromToken)
                ensureAllowance(_fromToken, converter, _amount);

             
            _amount = converter.change(_fromToken, toToken, _amount, i == pathLength - 2 ? _minReturn : 1);
            _fromToken = toToken;
        }
        return (toToken, _amount);
    }

     
    function checkWhitelist(IBancorConverter _converter, address _for, IContractFeatures _features) private view {
        IWhitelist whitelist;

         
        if (!_features.isSupported(_converter, FeatureIds.CONVERTER_CONVERSION_WHITELIST))
            return;

         
        whitelist = _converter.conversionWhitelist();
        if (whitelist == address(0))
            return;

         
        require(whitelist.isWhitelisted(_for));
    }

     
    function claimAndConvertFor(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for) public returns (uint256) {
         
         
         
        IERC20Token fromToken = _path[0];
        assert(fromToken.transferFrom(msg.sender, this, _amount));
        return convertFor(_path, _amount, _minReturn, _for);
    }

     
    function convert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256) {
        return convertFor(_path, _amount, _minReturn, msg.sender);
    }

     
    function claimAndConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public returns (uint256) {
        return claimAndConvertFor(_path, _amount, _minReturn, msg.sender);
    }

     
    function ensureAllowance(IERC20Token _token, address _spender, uint256 _value) private {
         
        if (_token.allowance(this, _spender) >= _value)
            return;

         
        if (_token.allowance(this, _spender) != 0)
            assert(_token.approve(_spender, 0));

         
        assert(_token.approve(_spender, _value));
    }

     
    function convertForPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint256 _nonce,
        uint8 _v,
        bytes32 _r,
        bytes32 _s)
        public payable returns (uint256)
    {
        convertForPrioritized2(_path, _amount, _minReturn, _for, _block, _v, _r, _s);
    }
}