 

pragma solidity ^0.4.24;
 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}
contract ERCInterface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Burn(address indexed from, uint256 value);
    event FrozenFunds(address target, bool frozen);
}
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

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

contract MDZAToken is ERCInterface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint _totalSupply;
    bool transactionLock;

     
    mapping(address => uint) balances;

    mapping(address => mapping(address => uint)) allowed;

    mapping (address => bool) public frozenAccount;

     
    constructor() public {
        symbol = "MDZA";
        name = "MEDOOZA Ecosystem v1.1";
        decimals = 10;
        _totalSupply = 1200000000 * 10**uint(decimals);
        balances[owner] = _totalSupply;
        transactionLock = false;
        emit Transfer(address(0), owner, _totalSupply);
    }

     
    function totalSupply() public view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != 0x0);  
        require(!transactionLock);   
        require(!frozenAccount[to]); 
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != 0x0);  
        require(!transactionLock);          
        require(!frozenAccount[from]);      
        require(!frozenAccount[to]);        
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
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

     
    function transferAnyERCToken(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERCInterface(tokenAddress).transfer(owner, tokens);
    }

     
    function burn(uint256 tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Burn(msg.sender, tokens);
        return true;
    }

     
    function burnFrom(address from, uint256 tokens) public  returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit Burn(from, tokens);
        return true;
    }

     
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

     
    function freezeAccountStatus(address target) onlyOwner public view returns (bool response){
        return frozenAccount[target];
    }

     
    function lockTransactions(bool lock) public onlyOwner returns (bool response){
        transactionLock = lock;
        return lock;
    }

     
    function transactionLockStatus() public onlyOwner view returns (bool response){
        return transactionLock;
    }
}