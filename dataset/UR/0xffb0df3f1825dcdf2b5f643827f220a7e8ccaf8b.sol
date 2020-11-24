 

pragma solidity ^0.5.0;

 
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

contract GasToken is ERC20Interface {
     
    string public constant name = "Gas";
    string public constant symbol = "GAS";
    uint8 public constant decimals = 18;
    
    uint256 public _totalSupply;

    mapping (address => uint256) balances;
    
     
    mapping(address => mapping (address => uint256)) allowed;

    constructor() public {
        _totalSupply = 0;
    }
    
     
     
     
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

     
     
     
    function buy() public payable returns (uint tokens) {
        tokens = msg.value / tx.gasprice;
        balances[msg.sender] += tokens;
        _totalSupply += tokens;
        return tokens;
    }
    
     
     
     
    function sell(uint tokens) public returns (uint revenue) {
        require(balances[msg.sender] >= tokens);            
        balances[msg.sender] -= tokens;        
        _totalSupply -= tokens;
        revenue = tokens * tx.gasprice;
        msg.sender.transfer(revenue);
        return revenue;
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);            
        require(balances[to] + tokens >= balances[to]);   
        balances[msg.sender] -= tokens;                     
        balances[to] += tokens;                            
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(balances[msg.sender] >= tokens);
        require(allowed[from][msg.sender] >= tokens);
        balances[from] -= tokens;
        allowed[from][msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(from, to, tokens);
        return true;
    }
 
     
     
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
     
     
     
    function () external payable {
        revert();
    }
}