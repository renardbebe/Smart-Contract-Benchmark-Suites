 

pragma solidity ^0.4.24;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Interface {
    
    using SafeMath for uint256;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint public totalSupply;

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function approve(address spender, uint tokens) public returns (bool success);

    function transfer(address to, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract Owned {
 
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _; 
    }
 
	 
    address public owner;
 
	 
    constructor() public {
        owner = msg.sender;
    }
	 
    address newOwner=0x0;
 
	 
    event OwnerUpdate(address _prevOwner, address _newOwner);
 
     
    function changeOwner(address _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }
 
     
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}

 
contract Controlled is Owned{
 
	 
    constructor() public {
       setExclude(msg.sender,true);
    }
 
     
    bool public transferEnabled = true;
 
     
    bool lockFlag=true;
	 
    mapping(address => bool) locked;
	 
    mapping(address => bool) exclude;
 
	 
    function enableTransfer(bool _enable) public onlyOwner returns (bool success){
        transferEnabled=_enable;
		return true;
    }
 
	 
    function disableLock(bool _enable) public onlyOwner returns (bool success){
        lockFlag=_enable;
        return true;
    }
 
	 
    function addLock(address _addr) public onlyOwner returns (bool success){
        require(_addr!=msg.sender);
        locked[_addr]=true;
        return true;
    }
 
	 
    function setExclude(address _addr,bool _enable) public onlyOwner returns (bool success){
        exclude[_addr]=_enable;
        return true;
    }
 
	 
    function removeLock(address _addr) public onlyOwner returns (bool success){
        locked[_addr]=false;
        return true;
    }
	 
    modifier transferAllowed(address _addr) {
        if (!exclude[_addr]) {
            require(transferEnabled,"transfer is not enabeled now!");
            if(lockFlag){
                require(!locked[_addr],"you are locked!");
            }
        }
        _;
    }
 
}

contract EpilogueToken is ERC20Interface,Controlled {
    
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) allowed;
    
    constructor() public {
        name = 'Epilogue';   
        symbol = 'EP';  
        decimals = 18;  
        totalSupply = 100000000 * 10 ** uint256(decimals);  
        balanceOf[msg.sender] = totalSupply;  
    }
    
    function transfer(address to, uint256 tokens) public returns (bool success) {
        
        require(to != address(0));
        require(balanceOf[msg.sender] >= tokens);
        require(balanceOf[to] + tokens >= balanceOf[to]);
        
        balanceOf[msg.sender] -= tokens;
        balanceOf[to] += tokens;
        
        emit Transfer(msg.sender, to, tokens);
        
        return true;
    }
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        
        require(to != address(0));
        require(allowed[from][msg.sender] >= tokens);
        require(balanceOf[from] >= tokens);
        require(balanceOf[to] + tokens >= balanceOf[to]);
        
        balanceOf[from] -= tokens;
        balanceOf[to] += tokens;
        
        allowed[from][msg.sender] -= tokens;
        
        emit Transfer(from, to, tokens);
        
        return true;
    }
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        
        return true;
    }
    
}