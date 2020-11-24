 

pragma solidity ^0.4.24;

 

 
contract IBancorXUpgrader {
    function upgrade(uint16 _version, address[] _reporters) public;
}

 

contract IBancorX {
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) public;
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256);
}

 

 
contract ContractIds {
     
    bytes32 public constant CONTRACT_FEATURES = "ContractFeatures";
    bytes32 public constant CONTRACT_REGISTRY = "ContractRegistry";

     
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

 

 
contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);

     
    function getAddress(bytes32 _contractName) public view returns (address);
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
        assert(_token.transfer(_to, _amount));
    }
}

 

 
contract ISmartToken is IOwned, IERC20Token {
    function disableTransfers(bool _disable) public;
    function issue(address _to, uint256 _amount) public;
    function destroy(address _from, uint256 _amount) public;
}

 

 
contract BancorX is IBancorX, Owned, TokenHolder, ContractIds {
    using SafeMath for uint256;

     
    struct Transaction {
        uint256 amount;
        bytes32 fromBlockchain;
        address to;
        uint8 numOfReports;
        bool completed;
    }

    uint16 public version = 2;

    uint256 public maxLockLimit;             
    uint256 public maxReleaseLimit;          
    uint256 public minLimit;                 
    uint256 public prevLockLimit;            
    uint256 public prevReleaseLimit;         
    uint256 public limitIncPerBlock;         
    uint256 public prevLockBlockNumber;      
    uint256 public prevReleaseBlockNumber;   
    uint256 public minRequiredReports;       
    
    IContractRegistry public registry;       
    IContractRegistry public prevRegistry;   
    IBancorConverter public bntConverter;    
    ISmartToken public bntToken;             

    bool public xTransfersEnabled = true;    
    bool public reportingEnabled = true;     
    bool public allowRegistryUpdate = true;  

     
    mapping (uint256 => Transaction) public transactions;

     
    mapping (uint256 => uint256) public transactionIds;

     
    mapping (uint256 => mapping (address => bool)) public reportedTxs;

     
    mapping (address => bool) public reporters;

     
    event TokensLock(
        address indexed _from,
        uint256 _amount
    );

     
    event TokensRelease(
        address indexed _to,
        uint256 _amount
    );

     
    event XTransfer(
        address indexed _from,
        bytes32 _toBlockchain,
        bytes32 indexed _to,
        uint256 _amount,
        uint256 _id
    );

     
    event TxReport(
        address indexed _reporter,
        bytes32 _fromBlockchain,
        uint256 _txId,
        address _to,
        uint256 _amount,
        uint256 _xTransferId
    );

     
    event XTransferComplete(
        address _to,
        uint256 _id
    );

     
    constructor(
        uint256 _maxLockLimit,
        uint256 _maxReleaseLimit,
        uint256 _minLimit,
        uint256 _limitIncPerBlock,
        uint256 _minRequiredReports,
        address _registry
    )
        public
    {
         
        maxLockLimit = _maxLockLimit;
        maxReleaseLimit = _maxReleaseLimit;
        minLimit = _minLimit;
        limitIncPerBlock = _limitIncPerBlock;
        minRequiredReports = _minRequiredReports;

         
        prevLockLimit = _maxLockLimit;
        prevReleaseLimit = _maxReleaseLimit;
        prevLockBlockNumber = block.number;
        prevReleaseBlockNumber = block.number;

        registry = IContractRegistry(_registry);
        prevRegistry = IContractRegistry(_registry);
        bntToken = ISmartToken(registry.addressOf(ContractIds.BNT_TOKEN));
        bntConverter = IBancorConverter(registry.addressOf(ContractIds.BNT_CONVERTER));
    }

     
    modifier isReporter {
        require(reporters[msg.sender]);
        _;
    }

     
    modifier whenXTransfersEnabled {
        require(xTransfersEnabled);
        _;
    }

     
    modifier whenReportingEnabled {
        require(reportingEnabled);
        _;
    }

     
    function setMaxLockLimit(uint256 _maxLockLimit) public ownerOnly {
        maxLockLimit = _maxLockLimit;
    }
    
     
    function setMaxReleaseLimit(uint256 _maxReleaseLimit) public ownerOnly {
        maxReleaseLimit = _maxReleaseLimit;
    }
    
     
    function setMinLimit(uint256 _minLimit) public ownerOnly {
        minLimit = _minLimit;
    }

     
    function setLimitIncPerBlock(uint256 _limitIncPerBlock) public ownerOnly {
        limitIncPerBlock = _limitIncPerBlock;
    }

     
    function setMinRequiredReports(uint256 _minRequiredReports) public ownerOnly {
        minRequiredReports = _minRequiredReports;
    }

     
    function setReporter(address _reporter, bool _active) public ownerOnly {
        reporters[_reporter] = _active;
    }

     
    function enableXTransfers(bool _enable) public ownerOnly {
        xTransfersEnabled = _enable;
    }

     
    function enableReporting(bool _enable) public ownerOnly {
        reportingEnabled = _enable;
    }

     
    function disableRegistryUpdate(bool _disable) public ownerOnly {
        allowRegistryUpdate = !_disable;
    }

     
    function setBNTConverterAddress() public ownerOnly {
        bntConverter = IBancorConverter(registry.addressOf(ContractIds.BNT_CONVERTER));
    }

     
    function updateRegistry() public {
         
        require(allowRegistryUpdate || msg.sender == owner);

         
        address newRegistry = registry.addressOf(ContractIds.CONTRACT_REGISTRY);

         
        require(newRegistry != address(registry) && newRegistry != address(0));

         
        prevRegistry = registry;
        registry = IContractRegistry(newRegistry);
    }

     
    function restoreRegistry() public ownerOnly {
         
        registry = prevRegistry;

         
        allowRegistryUpdate = false;
    }

     
    function upgrade(address[] _reporters) public ownerOnly {
        IBancorXUpgrader bancorXUpgrader = IBancorXUpgrader(registry.addressOf(ContractIds.BANCOR_X_UPGRADER));

        transferOwnership(bancorXUpgrader);
        bancorXUpgrader.upgrade(version, _reporters);
        acceptOwnership();
    }

     
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount) public whenXTransfersEnabled {
         
        uint256 currentLockLimit = getCurrentLockLimit();

         
        require(_amount >= minLimit && _amount <= currentLockLimit);
        
        lockTokens(_amount);

         
        prevLockLimit = currentLockLimit.sub(_amount);
        prevLockBlockNumber = block.number;

         
        emit XTransfer(msg.sender, _toBlockchain, _to, _amount, 0);
    }

     
    function xTransfer(bytes32 _toBlockchain, bytes32 _to, uint256 _amount, uint256 _id) public whenXTransfersEnabled {
         
        uint256 currentLockLimit = getCurrentLockLimit();

         
        require(_amount >= minLimit && _amount <= currentLockLimit);
        
        lockTokens(_amount);

         
        prevLockLimit = currentLockLimit.sub(_amount);
        prevLockBlockNumber = block.number;

         
        emit XTransfer(msg.sender, _toBlockchain, _to, _amount, _id);
    }

     
    function reportTx(
        bytes32 _fromBlockchain,
        uint256 _txId,
        address _to,
        uint256 _amount,
        uint256 _xTransferId 
    )
        public
        isReporter
        whenReportingEnabled
    {
         
        require(!reportedTxs[_txId][msg.sender]);

         
        reportedTxs[_txId][msg.sender] = true;

        Transaction storage txn = transactions[_txId];

         
        if (txn.numOfReports == 0) {
            txn.to = _to;
            txn.amount = _amount;
            txn.fromBlockchain = _fromBlockchain;

            if (_xTransferId != 0) {
                 
                require(transactionIds[_xTransferId] == 0);
                transactionIds[_xTransferId] = _txId;
            }
        } else {
             
            require(txn.to == _to && txn.amount == _amount && txn.fromBlockchain == _fromBlockchain);
            
            if (_xTransferId != 0) {
                require(transactionIds[_xTransferId] == _txId);
            }
        }
        
         
        txn.numOfReports++;

        emit TxReport(msg.sender, _fromBlockchain, _txId, _to, _amount, _xTransferId);

         
        if (txn.numOfReports >= minRequiredReports) {
            require(!transactions[_txId].completed);

             
            transactions[_txId].completed = true;

            emit XTransferComplete(_to, _xTransferId);

            releaseTokens(_to, _amount);
        }
    }

     
    function getXTransferAmount(uint256 _xTransferId, address _for) public view returns (uint256) {
         
        Transaction storage transaction = transactions[transactionIds[_xTransferId]];

         
        require(transaction.to == _for);

        return transaction.amount;
    }

     
    function getCurrentLockLimit() public view returns (uint256) {
         
        uint256 currentLockLimit = prevLockLimit.add(((block.number).sub(prevLockBlockNumber)).mul(limitIncPerBlock));
        if (currentLockLimit > maxLockLimit)
            return maxLockLimit;
        return currentLockLimit;
    }
 
     
    function getCurrentReleaseLimit() public view returns (uint256) {
         
        uint256 currentReleaseLimit = prevReleaseLimit.add(((block.number).sub(prevReleaseBlockNumber)).mul(limitIncPerBlock));
        if (currentReleaseLimit > maxReleaseLimit)
            return maxReleaseLimit;
        return currentReleaseLimit;
    }

     
    function lockTokens(uint256 _amount) private {
         
        bntConverter.claimTokens(msg.sender, _amount);

        emit TokensLock(msg.sender, _amount);
    }

     
    function releaseTokens(address _to, uint256 _amount) private {
         
        uint256 currentReleaseLimit = getCurrentReleaseLimit();

        require(_amount >= minLimit && _amount <= currentReleaseLimit);
        
         
        prevReleaseLimit = currentReleaseLimit.sub(_amount);
        prevReleaseBlockNumber = block.number;

         
        bntToken.transfer(_to, _amount);

        emit TokensRelease(_to, _amount);
    }
}