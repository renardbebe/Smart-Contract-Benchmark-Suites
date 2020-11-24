 

pragma solidity 0.4.24;

 

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

 

interface BaseExchangeableTokenInterface {

     
     
     

     
     

     
    event Exchange(address _from, address _targetContract, uint _amount);

     
    event ExchangeSpent(address _from, address _targetContract, address _to, uint _amount);

     
    function exchangeToken(address _targetContract, uint _amount) external returns (bool success, uint creditedAmount);

    function exchangeAndSpend(address _targetContract, uint _amount, address _to) external returns (bool success);

    function __exchangerCallback(address _targetContract, address _exchanger, uint _amount) external returns (bool success);

     
    function __targetExchangeCallback(uint _amount) external returns (bool success);

    function __targetExchangeAndSpendCallback(address _to, uint _amount) external returns (bool success);
}

 

 
contract Ownable {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 

 
contract Lockable is Ownable {
    event Lock();
    event Unlock();

    bool public locked = false;

     
    modifier whenNotLocked() {
        require(!locked);
        _;
    }

     
    modifier whenLocked() {
        require(locked);
        _;
    }

     
    function lock() public onlyOwner whenNotLocked {
        locked = true;
        emit Lock();
    }

     
    function unlock() public onlyOwner whenLocked {
        locked = false;
        emit Unlock();
    }
}

 

contract BaseFixedERC20Token is Lockable {
    using SafeMath for uint;

     
    uint public totalSupply;

    mapping(address => uint) public balances;

    mapping(address => mapping(address => uint)) private allowed;

     
    event Transfer(address indexed from, address indexed to, uint value);

     
    event Approval(address indexed owner, address indexed spender, uint value);

     
    function balanceOf(address owner_) public view returns (uint balance) {
        return balances[owner_];
    }

     
    function transfer(address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[msg.sender]);
         
        balances[msg.sender] = balances[msg.sender].sub(value_);
        balances[to_] = balances[to_].add(value_);
        emit Transfer(msg.sender, to_, value_);
        return true;
    }

     
    function transferFrom(address from_, address to_, uint value_) public whenNotLocked returns (bool) {
        require(to_ != address(0) && value_ <= balances[from_] && value_ <= allowed[from_][msg.sender]);
        balances[from_] = balances[from_].sub(value_);
        balances[to_] = balances[to_].add(value_);
        allowed[from_][msg.sender] = allowed[from_][msg.sender].sub(value_);
        emit Transfer(from_, to_, value_);
        return true;
    }

     
    function approve(address spender_, uint value_) public whenNotLocked returns (bool) {
        if (value_ != 0 && allowed[msg.sender][spender_] != 0) {
            revert();
        }
        allowed[msg.sender][spender_] = value_;
        emit Approval(msg.sender, spender_, value_);
        return true;
    }

     
    function allowance(address owner_, address spender_) public view returns (uint) {
        return allowed[owner_][spender_];
    }
}

 

interface BaseTokenExchangeInterface {
     
     

     
    event Exchange(address _from, address _by, uint _value, address _target);

     
    event ExchangeAndSpent(address _from, address _by, uint _value, address _target, address _to);

    function registerToken(address _token) external returns (bool success);

    function exchangeToken(address _targetContract, uint _amount) external returns (bool success, uint creditedAmount);

    function exchangeAndSpend(address _targetContract, uint _amount, address _to) external returns (bool success);
}

 

 
contract BaseExchangeableToken is BaseExchangeableTokenInterface, BaseFixedERC20Token {
    using SafeMath for uint;

    BaseTokenExchangeInterface public exchange;

     
    event ExchangeChanged(address _exchange);

     
    modifier whenConfigured() {
        require(exchange != address(0));
        _;
    }

     
    modifier onlyExchange() {
        require(msg.sender == address(exchange));
        _;
    }

     
     
    mapping(address => uint) private exchangedWith;

     
    mapping(address => uint) private exchangedBy;

     
     
    mapping(address => uint) private exchangesReceived;

     
    function changeExchange(address _exchange) public onlyOwner {
        require(_exchange != address(0));
        exchange = BaseTokenExchangeInterface(_exchange);
        emit ExchangeChanged(_exchange);
    }

     
     
    function exchangeToken(address _targetContract, uint _amount) public whenConfigured returns (bool success, uint creditedAmount) {
        require(_targetContract != address(0) && _amount <= balances[msg.sender]);
        (success, creditedAmount) = exchange.exchangeToken(_targetContract, _amount);
        if (!success) {
            revert();
        }
        emit Exchange(msg.sender, _targetContract, _amount);
        return (success, creditedAmount);
    }

     
    function exchangeAndSpend(address _targetContract, uint _amount, address _to) public whenConfigured returns (bool success) {
        require(_targetContract != address(0) && _to != address(0) && _amount <= balances[msg.sender]);
        success = exchange.exchangeAndSpend(_targetContract, _amount, _to);
        if (!success) {
            revert();
        }
        emit ExchangeSpent(msg.sender, _targetContract, _to, _amount);
        return success;
    }

     
    function __exchangerCallback(address _targetContract, address _exchanger, uint _amount) public whenConfigured onlyExchange returns (bool success) {
        require(_targetContract != address(0));
        if (_amount > balances[_exchanger]) {
            return false;
        }
        balances[_exchanger] = balances[_exchanger].sub(_amount);
        exchangedWith[_targetContract] = exchangedWith[_targetContract].add(_amount);
        exchangedBy[_exchanger] = exchangedBy[_exchanger].add(_amount);
        return true;
    }

     
     
    function __targetExchangeCallback(uint _amount) public whenConfigured onlyExchange returns (bool success) {
        balances[tx.origin] = balances[tx.origin].add(_amount);
        exchangesReceived[tx.origin] = exchangesReceived[tx.origin].add(_amount);
        emit Exchange(tx.origin, this, _amount);
        return true;
    }

     
    function __targetExchangeAndSpendCallback(address _to, uint _amount) public whenConfigured onlyExchange returns (bool success) {
        balances[_to] = balances[_to].add(_amount);
        exchangesReceived[_to] = exchangesReceived[_to].add(_amount);
        emit ExchangeSpent(tx.origin, this, _to, _amount);
        return true;
    }
}

 

 
contract BitoxToken is BaseExchangeableToken {
    using SafeMath for uint;

    string public constant name = "BitoxTokens";

    string public constant symbol = "BITOX";

    uint8 public constant decimals = 18;

    uint internal constant ONE_TOKEN = 1e18;

    constructor(uint totalSupplyTokens_) public {
        locked = false;
        totalSupply = totalSupplyTokens_ * ONE_TOKEN;
        address creator = msg.sender;
        balances[creator] = totalSupply;

        emit Transfer(0, this, totalSupply);
        emit Transfer(this, creator, balances[creator]);
    }

     
    function() external payable {
        revert();
    }

}