 

pragma solidity ^0.4.24;

 
 
contract ERC20 {
    function totalSupply() public view returns (uint supply);
    function balanceOf(address who) public view returns (uint value);
    function allowance(address owner, address spender ) public view returns (uint _allowance);

    function transfer(address to, uint value) public returns (bool ok);
    function transferFrom(address from, address to, uint value) public returns (bool ok);
    function approve(address spender, uint value ) public returns (bool ok);

    event Transfer( address indexed from, address indexed to, uint value);
    event Approval( address indexed owner, address indexed spender, uint value);
}

contract Lockable {
    bool public tokenTransfer;
    address public owner;
    mapping( address => bool ) public unlockaddress;
    mapping( address => bool ) public lockaddress;

    event Locked(address lockaddress, bool status);
    event Unlocked(address unlockedaddress, bool status);

     
    modifier isTokenTransfer {
         
        if(!tokenTransfer) {
            require(unlockaddress[msg.sender]);
        }
        _;
    }

     
     
     
    modifier checkLock {
        if (lockaddress[msg.sender]) {
            revert();
        }
        _;
    }

    modifier isOwner {
        require(owner == msg.sender);
        _;
    }

    constructor () public {
        tokenTransfer = false;
        owner = msg.sender;
    }

     
    function lockAddress(address target, bool status)
    external
    isOwner
    {
        require(owner != target);
        lockaddress[target] = status;
        emit Locked(target, status);
    }

     
    function unlockAddress(address target, bool status)
    external
    isOwner
    {
        unlockaddress[target] = status;
        emit Unlocked(target, status);
    }
}

library SafeMath {
    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
         
        uint c = a / b;
         
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

contract TPCToken is ERC20, Lockable {
    using SafeMath for uint;

    mapping( address => uint ) _balances;
    mapping( address => mapping( address => uint ) ) _approvals;
    uint _supply;
    string public constant name = "TPC Token";
    string public constant symbol = "TPC";
    uint8 public constant decimals = 18;   

    event TokenBurned(address burnAddress, uint amountOfTokens);
    event TokenTransfer();

    constructor () public {
        uint initial_balance = 2 * 10 ** 28;  
        _balances[msg.sender] = initial_balance;
        _supply = initial_balance;
    }

    function totalSupply() view public returns (uint supply) {
        return _supply;
    }

    function balanceOf(address who) view public returns (uint value) {
        return _balances[who];
    }

    function allowance(address owner, address spender) view public returns (uint _allowance) {
        return _approvals[owner][spender];
    }

    function transfer(address to, uint value) public 
    isTokenTransfer
    checkLock
    returns (bool success) {
        require(_balances[msg.sender] >= value);
        _balances[msg.sender] = _balances[msg.sender].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) public 
    isTokenTransfer
    checkLock
    returns (bool success) {
         
        require(_balances[from] >= value);
         
        require(_approvals[from][msg.sender] >= value);
         
        _approvals[from][msg.sender] = _approvals[from][msg.sender].sub(value);
        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
        return true;
    }

    function approve(address spender, uint value) public 
    isTokenTransfer
    checkLock
    returns (bool success) {
        _approvals[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function burnTokens(uint tokensAmount)
    isTokenTransfer
    external
    {
        require(_balances[msg.sender] >= tokensAmount);
        _balances[msg.sender] = _balances[msg.sender].sub(tokensAmount);
        _supply = _supply.sub(tokensAmount);
        emit TokenBurned(msg.sender, tokensAmount);
    }

    function enableTokenTransfer()
    external
    isOwner {
        tokenTransfer = true;
        emit TokenTransfer();
    }

    function disableTokenTransfer()
    external
    isOwner {
        tokenTransfer = false;
        emit TokenTransfer();
    }
}