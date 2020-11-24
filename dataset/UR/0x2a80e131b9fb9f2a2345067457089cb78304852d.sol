 

pragma solidity ^0.4.25;

 
 
 
 
 
 
 
 
 


 
 
 
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "Sum should be greater then any one digit");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "Right side value should be less than left side");
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b, "Multiplied result should not be zero");
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0, "Divisible value should be greater than zero");
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
    event FrozenFunds(address indexed target, bool frozen);
    event Burn(address indexed from, uint256 value);
    event Debug(bool destroyed);

}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "You are not owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "You are not owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


 
 
 
 
contract BTCCToken is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint private _distributedTokenCount;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    mapping(address => bool) public frozenAccount;

     
     
     
    constructor() public {
        symbol = "BTCC";
        name = "BTCCREDIT Token";
        decimals = 18;
        _totalSupply = 300000000 * (10 ** uint(decimals));  
    }

    function distributeTokens(address _address,  uint _amount) public onlyOwner returns (bool) {
        
        uint total = safeAdd(_distributedTokenCount, _amount);
        require (total <= _totalSupply, "Distributed Tokens exceeded Total Suuply");
        balances[_address] = safeAdd(balances[_address], _amount);

        _distributedTokenCount = safeAdd(_distributedTokenCount, _amount);
        
        emit Transfer (address(0), _address, _amount);
        return true;
    }

     
     
     
    function distributedTokenCount() public view onlyOwner returns (uint) {
        return _distributedTokenCount;
    }

     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(!frozenAccount[msg.sender], "Account is frozen");  
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(!frozenAccount[from], "Sender account is frozen");  
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
     
     
     
     
     
     
     
    function mintToken(address _target, uint256 _mintedAmount) public onlyOwner {
        require(!frozenAccount[_target], "Account is frozen");
        balances[_target] = safeAdd(balances[_target], _mintedAmount);
        _totalSupply = safeAdd(_totalSupply, _mintedAmount);

        emit Transfer(0, this, _mintedAmount);
        emit Transfer(this, _target, _mintedAmount);
    }

    function freezeAccount(address _target, bool _freeze) public onlyOwner {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }


     
    function burn(uint256 _burnedAmount) public returns (bool success) {
        require(balances[msg.sender] >= _burnedAmount, "Not enough balance");
        balances[msg.sender] = safeSub(balances[msg.sender], _burnedAmount);
        _totalSupply = safeSub(_totalSupply, _burnedAmount);
        emit Burn(msg.sender, _burnedAmount);
        return true;
    }

    function burnFrom(address _from, uint256 _burnedAmount) public returns (bool success) {
        require(balances[_from] >= _burnedAmount, "Not enough balance");
        require(_burnedAmount <= allowed[_from][msg.sender], "Amount not allowed");

        balances[_from] = safeSub(balances[_from], _burnedAmount);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _burnedAmount);        
        _totalSupply = safeSub(_totalSupply, _burnedAmount);
        
        emit Burn(_from, _burnedAmount);
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
        revert("Reverted the wrongly deposited ETH");
    }


     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
    
    function destroyContract() public onlyOwner {
        emit Debug(true);
        selfdestruct(this);
    }
}