 

pragma solidity 0.5.12;

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

 
 
 
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

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
	
	function returnOwner() public view returns(address){
		return owner;
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

 
 
 
 
contract Trust_Coin is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol = "TRUST";
    string public  name = "Trust Coin";
    uint8 public decimals = 18;
    uint public _totalSupply = 3000000000000000000000000000;
    uint256 public extras = 100;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
     
     
     
    constructor(address _owner) public {
        owner = address(_owner);
        balances[address(owner)] =  _totalSupply;
        emit Transfer(address(0),address(owner), _totalSupply * 10**uint(decimals));
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
        require(balances[msg.sender] >= tokens );
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        require(balances[to] + tokens >= balances[to]);
        
         
        balances[to] = balances[to].add(tokens);
        
         
        emit Transfer(msg.sender,to,tokens);
        
        return true;
    }
    
    
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(tokens <= allowed[from][msg.sender]);  
        require(balances[from] >= tokens);  
        
        balances[from] = balances[from].sub(tokens);
        
        
        require(balances[to] + tokens >= balances[to]);
         
        balances[to] = balances[to].add(tokens);
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        emit Transfer(from,to,tokens);
        
        return true;
    }
    
     
    function createTokens(uint256 tokens) public onlyOwner{
        require(tokens >= 0 );
        balances[msg.sender] = balances[msg.sender].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
    }
    
      
    function deleteTokens(uint256 tokens) public onlyOwner{
        require(tokens >= 0);
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
    }
    
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success){
        require(allowed[msg.sender][spender] == 0 || tokens == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
}