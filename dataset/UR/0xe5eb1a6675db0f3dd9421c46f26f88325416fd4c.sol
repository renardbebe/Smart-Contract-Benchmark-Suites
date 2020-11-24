 

 
pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 


 
 
 
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
    event Mint(uint256 amount, address indexed to);
}


 
 
 
 
 
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


 
 
 
contract Owned {
    address public owner;

    function Owned() public {
        owner = 0x27695Bd50e39904acDDb26653d13Ca13BD0d0064;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


 
 
 
 
contract Allysian is ERC20Interface, Owned {
    using SafeMath for uint256;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _maxSupply;
    uint public _circulatingSupply;
    mapping (address => uint256) public balances;
    mapping (address => mapping (address => uint256)) public allowed;


     
     
     
    function Allysian() public {
        symbol = "ALN";
        name = "Allysian Token";
        decimals = 8;
        _maxSupply = 1000000000 * 10**uint(decimals);  
        _circulatingSupply = 10000000 * 10**uint(decimals);  
        balances[owner] = _circulatingSupply;
        emit Transfer(address(0), owner, _circulatingSupply);
    }

     
     
     
    function totalSupply() public constant returns (uint) {
        return _circulatingSupply  - balances[address(0)];
    }

     
     
     
    function maxSupply() public constant returns (uint) {
        return _maxSupply  - balances[address(0)];
    }

    function mint(address _to, uint256 amount) public onlyOwner returns (bool) {
        require( _circulatingSupply.add(amount) <= _maxSupply && _to != address(0));
        _circulatingSupply = _circulatingSupply.add(amount);
        balances[_to] = balances[_to].add(amount);
        emit Mint(amount, _to);
        return true;
    }

     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }


     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
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
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }


     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
    function () public payable {
        revert();
    }

     
     
     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }
}