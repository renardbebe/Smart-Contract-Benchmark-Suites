 

pragma solidity ^0.4.25;

 

contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a, "unable to safe add");
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a, "unable to safe subtract");
        c = a - b;
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
    event Burn(address indexed from, uint256 value);
}

 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor () public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "sender is not owner");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner, "sender is not new owner");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

 
contract Green is ERC20Interface, Owned, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    constructor () public {
        symbol = "Green";
        name = "Green Token";
        decimals = 8;
        _totalSupply = 0;
        balances[0x6143FBb9Bd929eCdD8bd5fa632c4C31cad2b110A] = _totalSupply;
        emit Transfer(address(0), 0x6143FBb9Bd929eCdD8bd5fa632c4C31cad2b110A, _totalSupply);
    }

     
    function totalSupply() public view returns (uint) {
        return _totalSupply - balances[address(0)];
    }

     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
    function transfer(address to, uint tokens) public returns (bool success) {
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
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
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
        revert("ETH not accepted");
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
    function burn(uint256 _value) public returns (bool success) {
        require(balances[msg.sender] >= _value, "insufficient sender balance");
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        _totalSupply = safeSub(_totalSupply, _value);
        emit Burn(msg.sender, _value);
        return true;
    }

     
    function distributeMinting(address[] distAddresses, uint[] distValues) public onlyOwner returns (bool success) {
        require(msg.sender == owner, "sender is not owner");
        require(distAddresses.length == distValues.length, "address listed and values listed are not equal lengths");
        for (uint i = 0; i < distAddresses.length; i++) {
            mintToken(distAddresses[i], distValues[i]);
        }
        return true;
    }

     
    function mintToken(address target, uint mintAmount) internal {
        balances[target] = safeAdd(balances[target], mintAmount);
        _totalSupply = safeAdd(_totalSupply, mintAmount);
        emit Transfer(owner, target, mintAmount);
    }
}