 

pragma solidity ^0.4.25;

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

     
    function getRate(bytes32 symbol, bytes data) public returns (uint256 rate, uint256 decimals);

     
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


 
contract IBancorConverter {
    function getReturn(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount) public view returns (uint256);
    function convert(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function conversionWhitelist() public view returns (IWhitelist) {}
     
    function change(IERC20Token _fromToken, IERC20Token _toToken, uint256 _amount, uint256 _minReturn) public returns (uint256);
    function token() external returns (IERC20Token);
    function quickConvert(IERC20Token[] _path, uint256 _amount, uint256 _minReturn) public payable returns (uint256);
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

contract BancorProxy is TokenConverter, Ownable {
    IBancorConverter converterEthBnt;

    mapping(address => mapping(address => IBancorConverter)) public converterOf;
    mapping(address => mapping(address => address)) public routerOf;
    mapping(address => mapping(address => IERC20Token[])) public pathCache;

    Token ethToken;

    constructor(
        Token _ethToken
    ) public {
        ethToken = _ethToken;
    }

    function setConverter(
        Token _token1,
        Token _token2,
        IBancorConverter _converter
    ) public onlyOwner returns (bool) {
        converterOf[_token1][_token2] = _converter;
        converterOf[_token2][_token1] = _converter;
        uint256 approve = uint256(0) - 1;
        require(_token1.approve(_converter, approve), "Error approving transfer token 1");
        require(_token2.approve(_converter, approve), "Error approving transfer token 2");
        clearCache(_token1, _token2);
        return true;
    }

    function setRouter(
        address _token1,
        address _token2,
        address _router
    ) external onlyOwner returns (bool) {
        routerOf[_token1][_token2] = _router;
        routerOf[_token2][_token1] = _router;
        return true;
    }

    function clearCache(
        Token from,
        Token to
    ) public onlyOwner returns (bool) {
        pathCache[from][to].length = 0;
        pathCache[to][from].length = 0;
        return true;
    }

    function getPath(
        IBancorConverter converter,
        Token from,
        Token to
    ) private returns (IERC20Token[]) {
        if (pathCache[from][to].length != 0) {
            return pathCache[from][to];
        } else {
            IERC20Token token = converter.token();
            pathCache[from][to] = [IERC20Token(from), token, IERC20Token(to)];
            return pathCache[from][to];
        }
    }

    function getReturn(Token from, Token to, uint256 sell) external view returns (uint256 amount){
        return _getReturn(from, to, sell);
    }

    function _getReturn(Token _from, Token _to, uint256 sell) internal view returns (uint256 amount){
        Token from = _from == ETH_ADDRESS ? Token(ethToken) : _from;
        Token to = _to == ETH_ADDRESS ? Token(ethToken) : _to;
        IBancorConverter converter = converterOf[from][to];
        if (converter != address(0)) {
            return converter.getReturn(IERC20Token(from), IERC20Token(to), sell);
        }

        Token router = Token(routerOf[from][to]);
        if (router != address(0)) {
            converter = converterOf[router][to];
            return converter.getReturn(
                IERC20Token(router),
                IERC20Token(to),
                _getReturn(from, router, sell)
            );
        }
        revert("No routing found - BancorProxy");
    }

    function convert(Token _from, Token _to, uint256 sell, uint256 minReturn) external payable returns (uint256 amount){
        Token from = _from == ETH_ADDRESS ? Token(ethToken) : _from;
        Token to = _to == ETH_ADDRESS ? Token(ethToken) : _to;

        if (from == ethToken) {
            require(msg.value == sell, "ETH not enought");
        } else {
            require(msg.value == 0, "ETH not required");
            require(from.transferFrom(msg.sender, this, sell), "Error pulling tokens");
        }

        amount = _convert(from, to, sell);
        require(amount > minReturn, "Return amount too low");

        if (to == ethToken) {
            msg.sender.transfer(amount);
        } else {
            require(to.transfer(msg.sender, amount), "Error sending tokens");
        }
    }

    function _convert(
        Token from,
        Token to,   
        uint256 sell
    ) internal returns (uint256) {
        IBancorConverter converter = converterOf[from][to];
        
        uint256 amount;
        if (converter != address(0)) {
            amount = converter.quickConvert
                .value(from == ethToken ? sell : 0)(
                getPath(converter, from, to),
                sell,
                1
            );
        } else {
            Token router = Token(routerOf[from][to]);
            if (router != address(0)) {
                uint256 routerAmount = _convert(from, router, sell);
                converter = converterOf[router][to];
                amount = converter.quickConvert
                    .value(router == ethToken ? routerAmount : 0)(
                    getPath(converter, router, to),
                    routerAmount,
                    1
                );
            }
        }

        return amount;
    } 

    function withdrawTokens(
        Token _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        return _token.transfer(_to, _amount);
    }

    function withdrawEther(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        
        _to.transfer(_amount);
    }

    function() external payable {}
}