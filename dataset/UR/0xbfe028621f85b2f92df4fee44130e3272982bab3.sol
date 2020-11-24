 

pragma solidity "0.5.1";

 
 
 
 
 
 
 
 
 

 
 
 
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
    
    function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
        uint256 c = add(a,m);
        uint256 d = sub(c,1);
        return mul(div(d,m),m);
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

 
 
 
 
contract DAppDivs is ERC20Interface {
    using SafeMath for uint;
    
    string public symbol = "DIVS";
    string public  name = "DAppDivs";
    uint8 public decimals = 18;
    uint public _totalSupply = 100000000 * (uint256(10) ** decimals);
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
     
     
     
    constructor(address _owner) public { 
        balances[address(_owner)] =  _totalSupply;
        emit Transfer(address(0), address(_owner), _totalSupply);
    }
    
     
     
     
    function () external payable {
        revert();
    }
    
     
    function totalSupply() public view returns (uint){
       return _totalSupply;
    }
     
     
     
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        require(balances[msg.sender] >= tokens);
        require(tokens >= 0);

        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        
         
        emit Transfer(msg.sender,to,tokens);
        return true;
    }
    
    
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(from != address(0));
        require(tokens <= allowed[from][msg.sender]);  
        require(balances[from] >= tokens);  

        balances[from] = balances[from].sub(tokens);
        
         
        balances[to] = balances[to].add(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        emit Transfer(from,to,tokens);
        
        return true;
    }
    
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success){
        require(allowed[msg.sender][spender] == 0);
        require(tokens <= balances[msg.sender]);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
}