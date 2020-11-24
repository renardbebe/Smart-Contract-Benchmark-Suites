 

pragma solidity ^0.4.24;


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
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
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Owned {
    address public owner;
     

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
     
     

     
     
     
     
     
     
}


contract VXV is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public name;
    uint8 public decimals;
    uint public totalSupply;
    uint public rate;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor() public {
        symbol = "VXV";
        name = "VectorspaceAI";
        decimals = 18;
        totalSupply = 50000000 * 10 ** uint256(decimals);
        rate = 203;
        balances[owner] = totalSupply;
        emit Transfer(address(0), owner, totalSupply);
    }

    function changeRate(uint newRate) public onlyOwner {
        require(newRate > 0);
        rate = newRate;
    }

    function totalSupply() public view returns (uint) {
        return totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    modifier validTo(address to) {
        require(to != address(0));
        require(to != address(this));
        _;
    }

    function transferInternal(address from, address to, uint tokens) internal {
        balances[from] = safeSub(balances[from], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

    function transfer(address to, uint tokens) public validTo(to) returns (bool success) {
        transferInternal(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public validTo(to) returns (bool success) {
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        transferInternal(from, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        if (approve(spender, tokens)) {
            ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
            return true;
        }
    }

    function () public payable {
        uint tokens;
        tokens = safeMul(msg.value, rate);

        balances[owner] = safeSub(balances[owner], tokens);
        balances[msg.sender] = safeAdd(balances[msg.sender], tokens);

        emit Transfer(address(0), msg.sender, tokens);
        owner.transfer(msg.value);
    }

     
     
     
     
     
     
}