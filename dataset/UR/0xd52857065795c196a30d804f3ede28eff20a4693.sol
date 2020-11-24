 

pragma solidity ^0.4.24;

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

contract Ownable {
    address public owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

     
    function transferTo(address _to) external onlyOwner returns (bool) {
        require(_to != address(0), "Can't transfer to address 0x0");
        owner = _to;
        return true;
    }
}


 
contract Oracle is Ownable {
    uint256 public constant VERSION = 4;

    event NewSymbol(bytes32 _currency);

    mapping(bytes32 => bool) public supported;
    bytes32[] public currencies;

     
    function url() public view returns (string);

     
    function getRate(bytes32 symbol, bytes data) external returns (uint256 rate, uint256 decimals);

     
    function addCurrency(string ticker) public onlyOwner returns (bool) {
        bytes32 currency = encodeCurrency(ticker);
        emit NewSymbol(currency);
        supported[currency] = true;
        currencies.push(currency);
        return true;
    }

     
    function encodeCurrency(string currency) public pure returns (bytes32 o) {
        require(bytes(currency).length <= 32, "Currency too long");
        assembly {
            o := mload(add(currency, 32))
        }
    }
    
     
    function decodeCurrency(bytes32 b) public pure returns (string o) {
        uint256 ns = 256;
        while (true) { if (ns == 0 || (b<<ns-8) != 0) break; ns -= 8; }
        assembly {
            ns := div(ns, 8)
            o := mload(0x40)
            mstore(0x40, add(o, and(add(add(ns, 0x20), 0x1f), not(0x1f))))
            mstore(o, ns)
            mstore(add(o, 32), b)
        }
    }
}

contract Engine {
    uint256 public VERSION;
    string public VERSION_NAME;

    enum Status { initial, lent, paid, destroyed }
    struct Approbation {
        bool approved;
        bytes data;
        bytes32 checksum;
    }

    function getTotalLoans() public view returns (uint256);
    function getOracle(uint index) public view returns (Oracle);
    function getBorrower(uint index) public view returns (address);
    function getCosigner(uint index) public view returns (address);
    function ownerOf(uint256) public view returns (address owner);
    function getCreator(uint index) public view returns (address);
    function getAmount(uint index) public view returns (uint256);
    function getPaid(uint index) public view returns (uint256);
    function getDueTime(uint index) public view returns (uint256);
    function getApprobation(uint index, address _address) public view returns (bool);
    function getStatus(uint index) public view returns (Status);
    function isApproved(uint index) public view returns (bool);
    function getPendingAmount(uint index) public returns (uint256);
    function getCurrency(uint index) public view returns (bytes32);
    function cosign(uint index, uint256 cost) external returns (bool);
    function approveLoan(uint index) public returns (bool);
    function transfer(address to, uint256 index) public returns (bool);
    function takeOwnership(uint256 index) public returns (bool);
    function withdrawal(uint index, address to, uint256 amount) public returns (bool);
    function identifierToIndex(bytes32 signature) public view returns (uint256);
}


 
contract Cosigner {
    uint256 public constant VERSION = 2;
    
     
    function url() public view returns (string);
    
     
    function cost(address engine, uint256 index, bytes data, bytes oracleData) public view returns (uint256);
    
     
    function requestCosign(Engine engine, uint256 index, bytes data, bytes oracleData) public returns (bool);
    
     
    function claim(address engine, uint256 index, bytes oracleData) public returns (bool);
}


contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}


contract TokenConverterOracle2 is Oracle {
    address public delegate;
    address public ogToken;

    mapping(bytes32 => Currency) public sources;
    mapping(bytes32 => Cache) public cache;
    
    event DelegatedCall(address _requester, address _to);
    event CacheHit(address _requester, bytes32 _currency, uint256 _rate, uint256 _decimals);
    event DeliveredRate(address _requester, bytes32 _currency, uint256 _rate, uint256 _decimals);
    event SetSource(bytes32 _currency, address _converter, address _token, uint128 _sample, bool _cached);
    event SetDelegate(address _prev, address _new);
    event SetOgToken(address _prev, address _new);

    struct Cache {
        uint64 decimals;
        uint64 blockNumber;
        uint128 rate;
    }

    struct Currency {
        bool cached;
        uint8 decimals;
        address converter;
        address token;
    }

    function setDelegate(
        address _delegate
    ) external onlyOwner {
        emit SetDelegate(delegate, _delegate);
        delegate = _delegate;
    }

    function setOgToken(
        address _ogToken
    ) external onlyOwner {
        emit SetOgToken(ogToken, _ogToken);
        ogToken = _ogToken;
    }

    function setCurrency(
        string code,
        address converter,
        address token,
        uint8 decimals,
        bool cached
    ) external onlyOwner returns (bool) {
         
        bytes32 currency = encodeCurrency(code);
        if (!supported[currency]) {
            emit NewSymbol(currency);
            supported[currency] = true;
            currencies.push(currency);
        }

         
        sources[currency] = Currency({
            cached: cached,
            converter: converter,
            token: token,
            decimals: decimals
        });

        emit SetSource(currency, converter, token, decimals, cached);
        return true;
    }

    function url() public view returns (string) {
        return "";
    }

    function getRate(
        bytes32 _symbol,
        bytes _data
    ) external returns (uint256 rate, uint256 decimals) {
        if (delegate != address(0)) {
            emit DelegatedCall(msg.sender, delegate);
            return Oracle(delegate).getRate(_symbol, _data);
        }

        Currency memory currency = sources[_symbol];

        if (currency.cached) {
            Cache memory _cache = cache[_symbol];
            if (_cache.blockNumber == block.number) {
                emit CacheHit(msg.sender, _symbol, _cache.rate, _cache.decimals);
                return (_cache.rate, _cache.decimals);
            }
        }
        
        require(currency.converter != address(0), "Currency not supported");
        decimals = currency.decimals;
        rate = TokenConverter(currency.converter).getReturn(Token(currency.token), Token(ogToken), 10 ** decimals);
        emit DeliveredRate(msg.sender, _symbol, rate, decimals);

         
        if (currency.cached && rate < 340282366920938463463374607431768211456) {
            cache[_symbol] = Cache({
                decimals: currency.decimals,
                blockNumber: uint64(block.number),
                rate: uint128(rate)
            });
        }
    }
}