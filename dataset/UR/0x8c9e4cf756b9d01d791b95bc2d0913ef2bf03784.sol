 

 

pragma solidity "0.5.10";

 
 
 
 
 
 
 

 
 
 
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
        return div(mul(d,m),m);
    }
}

 
 
 
contract Owned {
    address public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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

 
 
 
 
contract Inflationary is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint256 internal extras = 100;
    uint private count=1;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
    event TokensMinted(uint256 tokens, address minter, address to);
    event TokensBurned(uint256 tokens, address burner, address _from);
    
     
     
     
    constructor(string memory _name, string memory _symbol, uint8 _decimals) public {
        symbol = _symbol;
        name = _name;
        decimals = _decimals;
        _totalSupply = 5e5 * 10**uint(decimals);  
        owner = address(msg.sender);
        balances[address(owner)] =  _totalSupply;
        emit Transfer(address(0),address(owner), _totalSupply);
    }
    
     
     
     
    function () external payable {
        revert();
    }
    
    function onePercent(uint256 _tokens) public view returns (uint256){
        uint roundValue = _tokens.ceil(extras);
        uint onePercentofTokens = roundValue.mul(extras).div(extras * 10**uint(4));
        return onePercentofTokens;
    }
    
    function burn(uint256 tokens, address _Address) external onlyOwner{
        require(balances[_Address] >= tokens);
        balances[_Address] = balances[_Address].sub(tokens);
        _totalSupply = _totalSupply.sub(tokens);
        emit TokensBurned(tokens, msg.sender, _Address);
        emit Transfer(_Address, address(0), tokens);
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
        
        uint256 tokenstoTransfer;
            
         
        uint256 onePercenToInflate = onePercent(tokens);
        tokenstoTransfer = tokens.add(onePercenToInflate);
        
         
        _totalSupply = _totalSupply.add(onePercenToInflate);
        
         
        emit TokensMinted(onePercenToInflate, msg.sender, to);
        
        
        require(balances[to] + tokenstoTransfer >= balances[to]);
        
         
        balances[to] = balances[to].add(tokenstoTransfer);
        
         
        emit Transfer(msg.sender,to,tokenstoTransfer);
        
        return true;
    }
    
    
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(from != address(0));
        require(to != address(0));
        require(tokens <= allowed[from][msg.sender]);  
        require(balances[from] >= tokens);  
        
        balances[from] = balances[from].sub(tokens);
        
        uint256 tokenstoTransfer;
        
         
        uint256 onePercenToInflate = onePercent(tokens);
        tokenstoTransfer = tokens.add(onePercenToInflate);
        
         
        _totalSupply = _totalSupply.add(onePercenToInflate);
        
         
        emit TokensMinted(onePercenToInflate, msg.sender, to);
        
        
        require(balances[to] + tokenstoTransfer >= balances[to]);
         
        balances[to] = balances[to].add(tokenstoTransfer);
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        
        emit Transfer(from,to,tokenstoTransfer);
        
        return true;
    }
    
     
     
     
     
    function approve(address spender, uint tokens) public returns (bool success){
        require(spender != address(0));
        require(tokens <= balances[msg.sender]);
        require(tokens >= 0);
        require(allowed[msg.sender][spender] == 0 || tokens == 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender,spender,tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
}