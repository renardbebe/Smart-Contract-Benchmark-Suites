 

pragma solidity 0.4.21;

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
  }

}


 
 
 
 
contract ERC20Interface {
  
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function burn(uint256 tokens) public returns (bool success);
    function freeze(uint256 tokens) public returns (bool success);
    function unfreeze(uint256 tokens) public returns (bool success);


     
    event Transfer(address indexed from, address indexed to, uint tokens);
    
     
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
     
    event Burn(address indexed from, uint256 tokens);
    
     
    event Freeze(address indexed from, uint256 tokens);
	
     
    event Unfreeze(address indexed from, uint256 tokens);
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
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}


 
 
 
 

contract WILLTOKEN is ERC20Interface, Owned {
    using SafeMath for uint;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public _totalSupply;
    address public owner;

     
    mapping (address => uint256) public balances;
    mapping(address => mapping(address => uint256)) allowed;
    mapping (address => uint256) public freezeOf;
    
 
     
    function WILLTOKEN (
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) public {
	
        decimals = decimalUnits;				 
        _totalSupply = initialSupply * 10**uint(decimals);       
        name = tokenName;                                        
        symbol = tokenSymbol;                                    
        owner = msg.sender;                                      
        balances[owner] = _totalSupply;                          
	
    }
    
     
     
     
    function totalSupply() public constant returns (uint) {
        return _totalSupply;
    }
    
     
     
     
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

     
     
     
     
    function transfer(address to, uint tokens) public returns (bool success) {
        require( tokens > 0 && to != 0x0 );
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

     
     
     
     
     
     
     
    function approve(address spender, uint tokens) public onlyOwner returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

     
     
     
     
     
     
     
     
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require( tokens > 0 && to != 0x0 && from != 0x0 );
        balances[from] = balances[from].sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

     
     
     
     
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
     
     
     
    function burn(uint256 tokens) public  onlyOwner returns (bool success) {
       require (balances[msg.sender] >= tokens) ;                         
       require (tokens > 0) ; 
       balances[msg.sender] = balances[msg.sender].sub(tokens);          
       _totalSupply = _totalSupply.sub(tokens);                          
       emit Burn(msg.sender, tokens);
       return true;
    }
	
     
     
     
    function freeze(uint256 tokens) public onlyOwner returns (bool success) {
       require (balances[msg.sender] >= tokens) ;                    
       require (tokens > 0) ; 
       balances[msg.sender] = balances[msg.sender].sub(tokens);     
       freezeOf[msg.sender] = freezeOf[msg.sender].add(tokens);      
       emit Freeze(msg.sender, tokens);
       return true;
    }
	
     
     
     
    function unfreeze(uint256 tokens) public onlyOwner returns (bool success) {
       require (freezeOf[msg.sender] >= tokens) ;                     
       require (tokens > 0) ; 
       freezeOf[msg.sender] = freezeOf[msg.sender].sub(tokens);     
       balances[msg.sender] = balances[msg.sender].add(tokens);
       emit Unfreeze(msg.sender, tokens);
       return true;
    }


    
    
    
   function () public payable {
      revert();
   }

}