 

pragma solidity ^0.4.24;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
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

contract BTR is owned{
    
    using SafeMath for uint;
    
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

     
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);

     
    constructor(string tokenName,string tokenSymbol,address tokenOwner) public {           
        decimals = 18;  
        totalSupply = 10000000000 * 10 ** uint(decimals);  
        balanceOf[tokenOwner] = totalSupply; 
        name = tokenName;                                    
        symbol = tokenSymbol;                                
		owner = tokenOwner;
    }

     
    function transfer(address _to, uint256 _value) public {
        require (_to != address(0));                                
		require (_value > 0); 
        require (balanceOf[msg.sender] >= _value);            
        require (balanceOf[_to] + _value >= balanceOf[_to]);  
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                      
        balanceOf[_to] = balanceOf[_to].add(_value);                             
        emit Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
		require (_value > 0);
		require (balanceOf[msg.sender] >= _value);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require (_to != address(0));                                 
		require (_value > 0); 
        require (balanceOf[_from] >= _value);                  
        require (balanceOf[_to] + _value >= balanceOf[_to]);   
        require (_value <= allowance[_from][msg.sender]);      
        balanceOf[_from] = balanceOf[_from].sub(_value);                            
        balanceOf[_to] = balanceOf[_to].add(_value);                              
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value);             
		require (_value > 0); 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                       
        totalSupply = totalSupply.sub(_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        require (balanceOf[msg.sender] >= _value);             
		require (_value > 0); 
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);                       
        freezeOf[msg.sender] = freezeOf[msg.sender].add(_value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        require (freezeOf[msg.sender] >= _value);             
		require (_value > 0); 
        freezeOf[msg.sender] = freezeOf[msg.sender].sub(_value);                       
		balanceOf[msg.sender] = balanceOf[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function withdrawEther(uint256 amount) onlyOwner public {
	    msg.sender.transfer(amount);
	}
	
	 
	function() external payable {
    }
}