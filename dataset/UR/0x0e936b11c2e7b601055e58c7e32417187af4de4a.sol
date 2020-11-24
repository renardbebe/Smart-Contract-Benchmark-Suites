 

pragma solidity 0.4.26;

 

 
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

 

 
contract IBancorNetwork {
    function convert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvert2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);

    function convertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

    function claimAndConvertFor2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public returns (uint256);

    function convertForPrioritized4(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256[] memory _signature,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) public payable returns (uint256);

     
    function convert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public payable returns (uint256);

     
    function claimAndConvert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public returns (uint256);

     
    function convertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public payable returns (uint256);

     
    function claimAndConvertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public returns (uint256);

     
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

 

 
contract IWhitelist {
    function isWhitelisted(address _address) public view returns (bool);
}

 

 
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256, uint256);
    function convert2(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public returns (uint256);
    function quickConvert2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public payable returns (uint256);
    function conversionWhitelist() public view returns (IWhitelist) {}
    function conversionFee() public view returns (uint32) {}
    function reserves(address _address) public view returns (uint256, uint32, bool, bool, bool) { _address; }
    function getReserveBalance(IERC20Token _reserveToken) public view returns (uint256);
     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
    function connectors(address _address) public view returns (uint256, uint32, bool, bool, bool);
    function getConnectorBalance(IERC20Token _connectorToken) public view returns (uint256);
}

 

 
contract IBancorFormula {
    function calculatePurchaseReturn(uint256 _supply, uint256 _reserveBalance, uint32 _reserveRatio, uint256 _depositAmount) public view returns (uint256);
    function calculateSaleReturn(uint256 _supply, uint256 _reserveBalance, uint32 _reserveRatio, uint256 _sellAmount) public view returns (uint256);
    function calculateCrossReserveReturn(uint256 _fromReserveBalance, uint32 _fromReserveRatio, uint256 _toReserveBalance, uint32 _toReserveRatio, uint256 _amount) public view returns (uint256);
     
    function calculateCrossConnectorReturn(uint256 _fromConnectorBalance, uint32 _fromConnectorWeight, uint256 _toConnectorBalance, uint32 _toConnectorWeight, uint256 _amount) public view returns (uint256);
}

 

 
contract IBancorGasPriceLimit {
    function gasPrice() public view returns (uint256) {}
    function validateGasPrice(uint256) public view;
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

 

contract IBancorX {
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) public;
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256);
}

 

 
contract BancorNetwork is IBancorNetwork, TokenHolder, ContractIds, FeatureIds {
    using SafeMath for uint256;

    uint256 private constant CONVERSION_FEE_RESOLUTION = 1000000;
    uint256 private constant AFFILIATE_FEE_RESOLUTION = 1000000;

    uint256 public maxAffiliateFee = 30000;      
    address public signerAddress = 0x0;          
    IContractRegistry public registry;           

    mapping (address => bool) public etherTokens;        
    mapping (bytes32 => bool) public conversionHashes;   

     
    constructor(IContractRegistry _registry) public validAddress(_registry) {
        registry = _registry;
    }

     
    function setMaxAffiliateFee(uint256 _maxAffiliateFee)
        public
        ownerOnly
    {
        require(_maxAffiliateFee <= AFFILIATE_FEE_RESOLUTION);
        maxAffiliateFee = _maxAffiliateFee;
    }

     
    function setRegistry(IContractRegistry _registry)
        public
        ownerOnly
        validAddress(_registry)
        notThis(_registry)
    {
        registry = _registry;
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

     
    function verifyTrustedSender(IERC20Token[] _path, address _addr, uint256[] memory _signature) private {
        uint256 blockNumber = _signature[1];

         
        require(block.number <= blockNumber);

         
        bytes32 hash = keccak256(abi.encodePacked(blockNumber, tx.gasprice, _addr, msg.sender, _signature[0], _path));

         
        require(!conversionHashes[hash]);

         
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
        require(ecrecover(prefixedHash, uint8(_signature[2]), bytes32(_signature[3]), bytes32(_signature[4])) == signerAddress);

         
        conversionHashes[hash] = true;
    }

     
    function convertFor2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, address _affiliateAccount, uint256 _affiliateFee) public payable returns (uint256) {
        return convertForPrioritized4(_path, _amount, _minReturn, _for, getSignature(0x0, 0x0, 0x0, 0x0, 0x0), _affiliateAccount, _affiliateFee);
    }

     
    function convertForPrioritized4(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256[] memory _signature,
        address _affiliateAccount,
        uint256 _affiliateFee
    )
        public
        payable
        returns (uint256)
    {
         
        verifyConversionParams(_path, _for, _for, _signature);

         
        handleValue(_path[0], _amount, false);

         
        uint256 amount = convertByPath(_path, _amount, _minReturn, _affiliateAccount, _affiliateFee);

         
         
         
        IERC20Token toToken = _path[_path.length - 1];
        if (etherTokens[toToken])
            IEtherToken(toToken).withdrawTo(_for, amount);
        else
            ensureTransfer(toToken, _for, amount);

        return amount;
    }

     
    function xConvert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        bytes32 _toBlockchain,
        bytes32 _to,
        uint256 _conversionId
    )
        public
        payable
        returns (uint256)
    {
        return xConvertPrioritized2(_path, _amount, _minReturn, _toBlockchain, _to, _conversionId, getSignature(0x0, 0x0, 0x0, 0x0, 0x0));
    }

     
    function xConvertPrioritized2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        bytes32 _toBlockchain,
        bytes32 _to,
        uint256 _conversionId,
        uint256[] memory _signature
    )
        public
        payable
        returns (uint256)
    {
         
        require(_signature.length == 0 || _signature[0] == _amount);

         
        verifyConversionParams(_path, msg.sender, this, _signature);

         
        require(_path[_path.length - 1] == registry.addressOf(ContractIds.BNT_TOKEN));

         
        handleValue(_path[0], _amount, true);

         
        uint256 amount = convertByPath(_path, _amount, _minReturn, address(0), 0);

         
        IBancorX(registry.addressOf(ContractIds.BANCOR_X)).xTransfer(_toBlockchain, _to, amount, _conversionId);

        return amount;
    }

     
    function convertByPath(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _affiliateAccount,
        uint256 _affiliateFee
    ) private returns (uint256) {
        uint256 amount = _amount;
        uint256 lastIndex = _path.length - 1;

        address bntToken;
        if (address(_affiliateAccount) == 0) {
            require(_affiliateFee == 0);
            bntToken = address(0);
        }
        else {
            require(0 < _affiliateFee && _affiliateFee <= maxAffiliateFee);
            bntToken = registry.addressOf(ContractIds.BNT_TOKEN);
        }

         
        for (uint256 i = 2; i <= lastIndex; i += 2) {
            IBancorConverter converter = IBancorConverter(ISmartToken(_path[i - 1]).owner());

             
            if (_path[i - 1] != _path[i - 2])
                ensureAllowance(_path[i - 2], converter, amount);

             
            amount = converter.change(_path[i - 2], _path[i], amount, i == lastIndex ? _minReturn : 1);

             
            if (address(_path[i]) == bntToken) {
                uint256 affiliateAmount = amount.mul(_affiliateFee).div(AFFILIATE_FEE_RESOLUTION);
                require(_path[i].transfer(_affiliateAccount, affiliateAmount));
                amount -= affiliateAmount;
                bntToken = address(0);
            }
        }

        return amount;
    }

    bytes4 private constant GET_RETURN_FUNC_SELECTOR = bytes4(uint256(keccak256("getReturn(address,address,uint256)") >> (256 - 4 * 8)));

    function getReturn(address _dest, address _fromToken, address _toToken, uint256 _amount) internal view returns (uint256, uint256) {
        uint256[2] memory ret;
        bytes memory data = abi.encodeWithSelector(GET_RETURN_FUNC_SELECTOR, _fromToken, _toToken, _amount);

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

        return (ret[0], ret[1]);
    }

     
    function getReturnByPath(IERC20Token[] _path, uint256 _amount) public view returns (uint256, uint256) {
        uint256 amount;
        uint256 fee;
        uint256 supply;
        uint256 balance;
        uint32 ratio;
        IBancorConverter converter;
        IBancorFormula formula = IBancorFormula(registry.addressOf(ContractIds.BANCOR_FORMULA));

        amount = _amount;

         
        require(_path.length > 2 && _path.length % 2 == 1);

         
        for (uint256 i = 2; i < _path.length; i += 2) {
            IERC20Token fromToken = _path[i - 2];
            IERC20Token smartToken = _path[i - 1];
            IERC20Token toToken = _path[i];

            if (toToken == smartToken) {  
                 
                if (i < 3 || smartToken != _path[i - 3]) {
                    supply = smartToken.totalSupply();
                    converter = IBancorConverter(ISmartToken(smartToken).owner());
                }

                 
                require(getReserveSaleEnabled(converter, fromToken));

                 
                balance = converter.getConnectorBalance(fromToken);
                (, ratio, , , ) = converter.connectors(fromToken);
                amount = formula.calculatePurchaseReturn(supply, balance, ratio, amount);
                fee = amount.mul(converter.conversionFee()).div(CONVERSION_FEE_RESOLUTION);
                amount -= fee;

                 
                supply += amount;
            }
            else if (fromToken == smartToken) {  
                 
                if (i < 3 || smartToken != _path[i - 3]) {
                    supply = smartToken.totalSupply();
                    converter = IBancorConverter(ISmartToken(smartToken).owner());
                }

                 
                balance = converter.getConnectorBalance(toToken);
                (, ratio, , , ) = converter.connectors(toToken);
                amount = formula.calculateSaleReturn(supply, balance, ratio, amount);
                fee = amount.mul(converter.conversionFee()).div(CONVERSION_FEE_RESOLUTION);
                amount -= fee;

                 
                supply -= amount;
            }
            else {  
                 
                if (i < 3 || smartToken != _path[i - 3]) {
                    converter = IBancorConverter(ISmartToken(smartToken).owner());
                }

                (amount, fee) = getReturn(converter, fromToken, toToken, amount);
            }
        }

        return (amount, fee);
    }

     
    function claimAndConvertFor2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _for, address _affiliateAccount, uint256 _affiliateFee) public returns (uint256) {
         
         
         
        IERC20Token fromToken = _path[0];
        ensureTransferFrom(fromToken, msg.sender, this, _amount);
        return convertFor2(_path, _amount, _minReturn, _for, _affiliateAccount, _affiliateFee);
    }

     
    function convert2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public payable returns (uint256) {
        return convertFor2(_path, _amount, _minReturn, msg.sender, _affiliateAccount, _affiliateFee);
    }

     
    function claimAndConvert2(IERC20Token[] _path, uint256 _amount, uint256 _minReturn, address _affiliateAccount, uint256 _affiliateFee) public returns (uint256) {
        return claimAndConvertFor2(_path, _amount, _minReturn, msg.sender, _affiliateAccount, _affiliateFee);
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

     
    function ensureAllowance(IERC20Token _token, address _spender, uint256 _value) private {
         
        if (_token.allowance(this, _spender) >= _value)
            return;

         
        if (_token.allowance(this, _spender) != 0)
            INonStandardERC20(_token).approve(_spender, 0);

         
        INonStandardERC20(_token).approve(_spender, _value);
    }

     
    function getReserveSaleEnabled(IBancorConverter _converter, IERC20Token _reserve)
        private
        view
        returns(bool)
    {
        bool isSaleEnabled;
        (, , , isSaleEnabled, ) = _converter.connectors(_reserve);
        return isSaleEnabled;
    }

    function getSignature(
        uint256 _customVal,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (uint256[] memory) {
        if (_v == 0x0 && _r == 0x0 && _s == 0x0)
            return new uint256[](0);
        uint256[] memory signature = new uint256[](5);
        signature[0] = _customVal;
        signature[1] = _block;
        signature[2] = uint256(_v);
        signature[3] = uint256(_r);
        signature[4] = uint256(_s);
        return signature;
    }

    function verifyConversionParams(
        IERC20Token[] _path,
        address _sender,
        address _receiver,
        uint256[] memory _signature
    )
        private
    {
         
        require(_path.length > 2 && _path.length <= (1 + 2 * 10) && _path.length % 2 == 1);

         
        IContractFeatures features = IContractFeatures(registry.addressOf(ContractIds.CONTRACT_FEATURES));
        for (uint256 i = 1; i < _path.length; i += 2) {
            IBancorConverter converter = IBancorConverter(ISmartToken(_path[i]).owner());
            if (features.isSupported(converter, FeatureIds.CONVERTER_CONVERSION_WHITELIST)) {
                IWhitelist whitelist = converter.conversionWhitelist();
                require (whitelist == address(0) || whitelist.isWhitelisted(_receiver));
            }
        }

        if (_signature.length >= 5) {
             
            verifyTrustedSender(_path, _sender, _signature);
        }
        else {
             
            IBancorGasPriceLimit gasPriceLimit = IBancorGasPriceLimit(registry.addressOf(ContractIds.BANCOR_GAS_PRICE_LIMIT));
            gasPriceLimit.validateGasPrice(tx.gasprice);
        }
    }

    function handleValue(IERC20Token _token, uint256 _amount, bool _claim) private {
         
        if (msg.value > 0) {
            require(_amount == msg.value && etherTokens[_token]);
            IEtherToken(_token).deposit.value(msg.value)();
        }
         
        else if (_claim) {
            ensureTransferFrom(_token, msg.sender, this, _amount);
        }
    }

     
    function convert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public payable returns (uint256)
    {
        return convert2(_path, _amount, _minReturn, address(0), 0);
    }

     
    function claimAndConvert(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public returns (uint256)
    {
        return claimAndConvert2(_path, _amount, _minReturn, address(0), 0);
    }

     
    function convertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public payable returns (uint256)
    {
        return convertFor2(_path, _amount, _minReturn, _for, address(0), 0);
    }

     
    function claimAndConvertFor(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public returns (uint256)
    {
        return claimAndConvertFor2(_path, _amount, _minReturn, _for, address(0), 0);
    }

     
    function xConvertPrioritized(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        bytes32 _toBlockchain,
        bytes32 _to,
        uint256 _conversionId,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        payable
        returns (uint256)
    {
         
        uint256[] memory signature = getSignature(_amount, _block, _v, _r, _s);
        return xConvertPrioritized2(_path, _amount, _minReturn, _toBlockchain, _to, _conversionId, signature);
         
    }

     
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
    )
        public
        payable
        returns (uint256)
    {
        return convertForPrioritized4(_path, _amount, _minReturn, _for, getSignature(_customVal, _block, _v, _r, _s), address(0), 0);
    }

     
    function convertForPrioritized2(
        IERC20Token[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for,
        uint256 _block,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    )
        public
        payable
        returns (uint256)
    {
        return convertForPrioritized4(_path, _amount, _minReturn, _for, getSignature(_amount, _block, _v, _r, _s), address(0), 0);
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
        _nonce;
        return convertForPrioritized4(_path, _amount, _minReturn, _for, getSignature(_amount, _block, _v, _r, _s), address(0), 0);
    }
}