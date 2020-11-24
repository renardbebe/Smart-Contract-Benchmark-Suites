 

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

 
 
 
 
contract BBT is ERC20Interface, Owned {
    using SafeMath for uint;
    
    string public symbol = "BBT";
    string public  name = "Bit-Bet";
    uint8 public decimals = 18;
    uint internal _totalSupply;
    uint256 internal extras = 100;
    
    address public donation;
    address public distribution;
    
    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) public allowed;
    
     
     
     
    constructor(address _owner, address _donation, address _distribution) public {
        _mint(_owner, 10e6 * 10**uint(decimals));
        owner = _owner;
        distribution = _distribution;
        donation = _donation;
    }
    
     
     
     
    function () external payable {
        revert();
    }
    
     
     
     
    function onePercent(uint256 _tokens) internal view returns (uint256){
        uint roundValue = _tokens.ceil(extras);
        uint onePercentofTokens = roundValue.mul(extras).div(extras * 10**uint(2));
        return onePercentofTokens;
    }
     
     
     
     
     
     
     
     
     
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }
     
     
     
     
     
     
     
     
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        balances[account] = balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }
    
     
     
     
    function _transfer(address from, address to, uint256 amount) internal {
        balances[from] =  balances[from].sub(amount);
        balances[to] = balances[to].add(amount);
        emit Transfer(from, address(to), amount);
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
        
        __transfer(to, msg.sender, tokens);
        
        return true;
    }
    
     
     
     
    function __transfer(address to, address from, uint tokens) internal {
         
        uint256 onePercentofTokens = onePercent(tokens);
        
         
        _burn(from, onePercentofTokens);
        
         
        _transfer(from, donation, onePercentofTokens);
        
         
        _transfer(from, distribution, onePercentofTokens);
        
        balances[from] = balances[from].sub(tokens.sub(onePercentofTokens.mul(3)));
        
         
        require(balances[to] + tokens.sub(onePercentofTokens.mul(3)) >= balances[to]);
        
         
        balances[to] = balances[to].add(tokens.sub(onePercentofTokens.mul(3)));
        
         
        emit Transfer(from,to,tokens.sub(onePercentofTokens.mul(3)));
    }
    
    
     
     
     
     
     
     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success){
        require(from != address(0));
        require(to != address(0));
        require(tokens <= allowed[from][msg.sender]);  
        require(balances[from] >= tokens);  
        
        __transfer(to, from, tokens);
        
        
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
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