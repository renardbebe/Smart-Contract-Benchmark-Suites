 

pragma solidity 0.5.8;

 
 
 
 
 
 
 
 
 
 

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
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

 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes memory data) public;
}

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
 
 
contract NRM is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    address FreezeAddress = address(7);
    uint FreezeTokens;
    uint FreezeTokensReleaseTime = 1580169600;

     
     
     
    constructor() public {
        symbol = "NRM";
        name = "Neuromachine Eternal";
        decimals = 18;
        _totalSupply = 4958333333 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);

     
     
     
        FreezeTokens = _totalSupply.mul(30).div(100);
        balances[owner] = balances[owner].sub(FreezeTokens);
        balances[FreezeAddress] = balances[FreezeAddress].add(FreezeTokens);
        emit Transfer(owner, FreezeAddress, FreezeTokens);
    }

     
     
     
    function unfreezeTeamTokens(address unFreezeAddress) public onlyOwner returns (bool success) {
        require(now >= FreezeTokensReleaseTime);
        balances[FreezeAddress] = balances[FreezeAddress].sub(FreezeTokens);
        balances[unFreezeAddress] = balances[unFreezeAddress].add(FreezeTokens);
        emit Transfer(FreezeAddress, unFreezeAddress, FreezeTokens);
        return true;
    }

     
     
     
     
    modifier isRunning {
        require(running);
        _;
    }

    function startStop () public onlyOwner returns (bool success) {
        if (running) { running = false; } else { running = true; }
        return true;
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
    function transfer(address to, uint tokens) public isRunning returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public isRunning returns (bool success) {
        _approve(msg.sender, spender, tokens);
        return true;
    }

     
     
     
    function increaseAllowance(address spender, uint addedTokens) public isRunning returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedTokens));
        return true;
    }

     
     
     
    function decreaseAllowance(address spender, uint subtractedTokens) public isRunning returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedTokens));
        return true;
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes memory data) public isRunning returns (bool success) {
        _approve(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

     
     
     
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

     
     
     
    function transferFrom(address from, address to, uint tokens) public isRunning returns (bool success) {
        require(to != address(0));
        balances[from] = balances[from].sub(tokens);
        _approve(from, msg.sender, allowed[from][msg.sender].sub(tokens));
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     
     
    function burnTokens(uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }

     
     
     
    function multisend(address[] memory to, uint[] memory values) public onlyOwner returns (uint) {
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        balances[owner] = balances[owner].sub(sum);
        for (uint i; i < to.length; i++) {
            balances[to[i]] = balances[to[i]].add(values[i]);
            emit Transfer(owner, to[i], values[i]);
        }
        return(to.length);
    }
}