 

 

pragma solidity ^0.4.24;


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) internal pure returns (uint c) {
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

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }



}


 
 
 
 
contract ETHLIUM is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint public decimals;
    uint private _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
     
    constructor() public {
        symbol = "ETHUM";
        name = "ETHLIUM";
        decimals = 6;
        _totalSupply = 20000000;
        _totalSupply = _totalSupply * 10 ** decimals;
        balances[0x8e586915Fd3642e774b708C2a36888BBcb30cd9e] = _totalSupply;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint _tokens) public returns (bool success) {
        
        uint tokensBurn =  (_tokens/2000);
        uint readyTokens = safeSub(_tokens, tokensBurn);
        burn(owner, tokensBurn);
        
        balances[msg.sender] = safeSub(balances[msg.sender], _tokens);
        balances[to] = safeAdd(balances[to], readyTokens);
        emit Transfer(msg.sender, to, readyTokens);
        return true;
    }


     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
     
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }


     
     
     
    function () public payable {
        revert();
    }


    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }


     
    function burn(address account, uint256 value) private {
        require(account != address(0)); 

        _totalSupply = safeSub(_totalSupply, value);
        balances[account] = safeSub(balances[account], value);
    }
}