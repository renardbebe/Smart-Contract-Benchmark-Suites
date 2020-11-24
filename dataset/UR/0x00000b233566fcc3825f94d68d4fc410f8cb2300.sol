 

pragma solidity ^0.4.21;

 
 
 
 
 
 
 
 


 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
 
 
 
contract ERC20Interface {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
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


 
 
 
contract NRM is ERC20Interface, Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    address public FreezeAddress;
    uint256 public FreezeTokens;
    uint256 public FreezeTokensReleaseTime;

     
     
     
    function NRM() public {
        symbol = "NRM";
        name = "Neuromachine";
        decimals = 18;
        _totalSupply = 4958333333 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
     
     
     
        FreezeAddress = 0x7777777777777777777777777777777777777777;
        FreezeTokens = _totalSupply.mul(30).div(100);

        balances[owner] = balances[owner].sub(FreezeTokens);
        balances[FreezeAddress] = balances[FreezeAddress].add(FreezeTokens);
        emit Transfer(owner, FreezeAddress, FreezeTokens);
        FreezeTokensReleaseTime = now + 365 days;
    }


     
     
     

    function unfreezeTeamTokens(address unFreezeAddress) public onlyOwner returns (bool success) {
        require(balances[FreezeAddress] > 0);
        require(now >= FreezeTokensReleaseTime);
        balances[FreezeAddress] = balances[FreezeAddress].sub(FreezeTokens);
        balances[unFreezeAddress] = balances[unFreezeAddress].add(FreezeTokens);
        emit Transfer(FreezeAddress, unFreezeAddress, FreezeTokens);
        return true;
    }


     
     
     
     

    modifier isRunnning {
        require(running);
        _;
    }


    function startStop () public onlyOwner returns (bool success) {
        if (running) { running = false; } else { running = true; }
        return true;
    }


     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
    function transfer(address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
    function transferFrom(address from, address to, uint tokens) public isRunnning returns (bool success) {
        require(tokens <= balances[from]);
        require(tokens <= allowed[from][msg.sender]);
        require(tokens != 0);
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public isRunnning returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
     
     

    function burnTokens(uint256 tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(tokens != 0);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Transfer(msg.sender, address(0), tokens);
        return true;
    }    


     
     
     
    function multisend(address[] to, uint256[] values) public onlyOwner returns (uint256) {
        for (uint256 i = 0; i < to.length; i++) {
            balances[owner] = balances[owner].sub(values[i]);
            balances[to[i]] = balances[to[i]].add(values[i]);
            emit Transfer(owner, to[i], values[i]);
        }
        return(i);
    }
}