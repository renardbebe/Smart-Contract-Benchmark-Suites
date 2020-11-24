 

pragma solidity ^0.4.13;

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(
        address indexed _from,
        address indexed _to
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract DataeumToken is Owned, ERC20Interface {
     
    using SafeMath for uint256;

     
    mapping(address => uint256) balances;

     
    mapping(address => mapping(address => uint256)) allowed;

     
    mapping(address => bool) public freezeBypassing;

     
    mapping(address => uint256) public lockupExpirations;

     
    string public constant symbol = "XDT";

     
    string public constant name = "Dataeum Token";

     
    uint8 public constant decimals = 18;

     
    uint256 public circulatingSupply = 0;

     
    bool public tradingLive = false;

     
    uint256 public totalSupply;

     
    event LockupApplied(
        address indexed owner,
        uint256 until
    );

     
    constructor(uint256 _totalSupply) public {
        totalSupply = _totalSupply;
    }

     
    function distribute(
        address to,
        uint256 tokens
    )
        public onlyOwner
    {
        uint newCirculatingSupply = circulatingSupply.add(tokens);
        require(newCirculatingSupply <= totalSupply);
        circulatingSupply = newCirculatingSupply;
        balances[to] = balances[to].add(tokens);

        emit Transfer(address(this), to, tokens);
    }

     
    function lockup(
        address wallet,
        uint256 duration
    )
        public onlyOwner
    {
        uint256 lockupExpiration = duration.add(now);
        lockupExpirations[wallet] = lockupExpiration;
        emit LockupApplied(wallet, lockupExpiration);
    }

     
    function setBypassStatus(
        address to,
        bool status
    )
        public onlyOwner
    {
        freezeBypassing[to] = status;
    }

     
    function setTradingLive() public onlyOwner {
        tradingLive = true;
    }

     
    modifier tradable(address from) {
        require(
            (tradingLive || freezeBypassing[from]) &&  
            (lockupExpirations[from] <= now)
        );
        _;
    }

     
    function totalSupply() public view returns (uint256 supply) {
        return totalSupply;
    }

     
    function balanceOf(
        address owner
    )
        public view returns (uint256 balance)
    {
        return balances[owner];
    }

     
    function transfer(
        address destination,
        uint256 amount
    )
        public tradable(msg.sender) returns (bool success)
    {
        balances[msg.sender] = balances[msg.sender].sub(amount);
        balances[destination] = balances[destination].add(amount);
        emit Transfer(msg.sender, destination, amount);
        return true;
    }

     
    function transferFrom(
        address from,
        address to,
        uint256 tokenAmount
    )
        public tradable(from) returns (bool success)
    {
        balances[from] = balances[from].sub(tokenAmount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokenAmount);
        balances[to] = balances[to].add(tokenAmount);
        emit Transfer(from, to, tokenAmount);
        return true;
    }

     
    function approve(
        address spender,
        uint256 tokenAmount
    )
        public returns (bool success)
    {
        allowed[msg.sender][spender] = tokenAmount;
        emit Approval(msg.sender, spender, tokenAmount);
        return true;
    }

     
    function allowance(
        address tokenOwner,
        address spender
    )
        public view returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

     
    function approveAndCall(
        address spender,
        uint256 tokenAmount,
        bytes data
    )
        public tradable(spender) returns (bool success)
    {
        allowed[msg.sender][spender] = tokenAmount;
        emit Approval(msg.sender, spender, tokenAmount);

        ApproveAndCallFallBack(spender)
            .receiveApproval(msg.sender, tokenAmount, this, data);

        return true;
    }

     
    function withdrawERC20Token(
        address tokenAddress,
        uint256 tokenAmount
    )
        public onlyOwner returns (bool success)
    {
        return ERC20Interface(tokenAddress).transfer(owner, tokenAmount);
    }
}

library SafeMath {
     
    function add(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256 c)
    {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function sub(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256)
    {
        assert(b <= a);
        return a - b;
    }


     
    function mul(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(
        uint256 a,
        uint256 b
    )
        internal pure returns (uint256)
    {
         
         
         
        return a / b;
    }
}