 

pragma solidity ^0.4.18;


 
contract SafeMath {
    function Add(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function Sub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function Mul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function Div(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


 
contract ERC20 {
    function approve(address spender, uint tokens) public returns (bool success);
    function allowance(address fromAddress, address recipientAddress) public constant returns (uint remaining);
    function totalSupply() public constant returns (uint);
    function transfer(address recipientAddress, uint tokens) public returns (bool success);
    function transferFrom(address fromAddress, address recipientAddress, uint tokens) public returns (bool success);
    function balanceOf(address userAddress) public constant returns (uint balance);
    
    event Transfer(address indexed from, address indexed recipient, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract Owned {
    address public Owner;
    address public newOwner;

    event OwnershipAltered(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == Owner);
        _;
    }
    
     
    function Owned() public {
        Owner = msg.sender;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipAltered(Owner, newOwner);
        Owner = newOwner;
        newOwner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    
}

 
contract BEAT is ERC20, Owned, SafeMath {
    string public  name;
    string public symbol;
    uint public _totalSupply;
    uint8 public decimals;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;


     
    function BEAT() public {
        symbol = "BEAT";
        name = "BEAT";
        decimals = 8;
        _totalSupply = 100000000000000000;
        Owner = msg.sender;
        balances[msg.sender] = _totalSupply;

    }

     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }

     
    function balanceOf(address userAddress) public constant returns (uint balance) {
        return balances[userAddress];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = Sub(balances[msg.sender], tokens);
        balances[to] = Add(balances[to], tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = Sub(balances[from], tokens);
        allowed[from][msg.sender] = Sub(allowed[from][msg.sender], tokens);
        balances[to] = Add(balances[to], tokens);
        Transfer(from, to, tokens);
        return true;
    }
    
     
    function redeemContractSentTokens(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20(tokenAddress).transfer(Owner, tokens);
    }

     
    function airdrop(address[] addresses, uint256 _value) onlyOwner public {
         for (uint j = 0; j < addresses.length; j++) {
             balances[Owner] -= _value;
             balances[addresses[j]] += _value;
             emit Transfer(Owner, addresses[j], _value);
         }
    }

     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }

}