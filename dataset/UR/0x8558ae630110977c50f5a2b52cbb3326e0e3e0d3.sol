 

pragma solidity ^0.4.18;


contract ERC20Interface {
  
    
    function totalSupply() public constant returns (uint total);

     
    function balanceOf(address _owner) public constant returns (uint balance);

     
    function transfer(address _to, uint256 _value) public  returns (bool success);

     
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);

     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success);

     
    function allowance(address _owner, address _spender) public constant returns (uint remaining);

     
    event Transfer(address indexed _from, address indexed _to, uint _value);

     
    event Approval(address indexed _owner, address indexed _spender, uint _value);
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
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract TreatzCoin is ERC20Interface, Owned {
    using SafeMath for uint;

    string public symbol;
    string public name;
    uint8 public decimals;
    uint public _totalSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;
 
     
     
     
    function TreatzCoin() public {
        symbol ="TRTZ";
        name = "Treatz Coin";
        decimals = 2;
        _totalSupply = 20000000 * 10**uint(decimals);

        balances[owner] = _totalSupply;
        Transfer(address(0), owner, _totalSupply);
    }
    
     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply  - balances[address(0)];
    }


     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(msg.sender, to, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        Approval(msg.sender, spender, tokens);
        return true;
    }


     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }


     
     
     
     
    function transferFromWithFee(
    address from,
    address to,
    uint256 tokens,
    uint256 fee
    ) public returns (bool success) {
        balances[from] = balances[from].sub(tokens + fee);
        if (msg.sender != owner)
            allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens + fee);
        balances[to] = balances[to].add(tokens);
        Transfer(from, to, tokens);

        balances[owner] = balances[owner].add(fee);
        Transfer(from, owner, fee);
        return true;
    }

     
     
     
    function () public payable {
        revert();
    }
}