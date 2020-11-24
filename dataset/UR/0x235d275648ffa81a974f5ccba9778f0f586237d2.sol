 

pragma solidity ^0.4.11;


contract owned {

    address public owner;
	
    function owned() payable { owner = msg.sender; }
    
    modifier onlyOwner { require(owner == msg.sender); _; }

 }


	
contract ARCEON is owned {

    using SafeMath for uint256;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;
	address public owner;
	

     
    mapping (address => uint256) public balanceOf;  
	mapping (address => uint256) public freezeOf;  
    mapping (address => mapping (address => uint256)) public allowance;  

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Burn(address indexed from, uint256 value);
	
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);
	

     
	
    function ArCoin (
    
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        
        
        ) onlyOwner {
		
		

		
		owner = msg.sender;  
		name = tokenName;  
        symbol = tokenSymbol;  
        decimals = decimalUnits;  
		
        balanceOf[owner] = initialSupply.safeDiv(2);  
		balanceOf[this]  = initialSupply.safeDiv(2);  
        totalSupply = initialSupply;  
		Transfer(this, owner, balanceOf[owner]);  
		
		
        
		
    }  
	

     
    function transfer(address _to, uint256 _value) {
	    
        require (_to != 0x0);  
		require (_value > 0); 
        require (balanceOf[msg.sender] > _value);  
        require (balanceOf[_to] + _value > balanceOf[_to]);  
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); 
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value); 
        Transfer(msg.sender, _to, _value); 
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		
		require (_value > 0); 
        allowance[msg.sender][_spender] = _value;
        return true;
    }   

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
	    
        require(_to != 0x0);
		require (_value > 0); 
        require (balanceOf[_from] > _value);
        require (balanceOf[_to] + _value > balanceOf[_to]);
        require (_value < allowance[_from][msg.sender]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

	 
    function burn(uint256 _value) onlyOwner returns (bool success) {
	    
        require (balanceOf[msg.sender] > _value);  
		require (_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value); 
        totalSupply = SafeMath.safeSub(totalSupply,_value); 
        Burn(msg.sender, _value); 
        return true;
    
    }
	
	  
	function freeze(uint256 _value) onlyOwner returns (bool success)   {
	    
        require (balanceOf[msg.sender] > _value);  
		require (_value > 0); 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);  
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);  
        Freeze(msg.sender, _value);
        return true;
    }
	
	 
	function unfreeze(uint256 _value) onlyOwner returns (bool success) {
	   
        require(freezeOf[msg.sender] > _value);
		require (_value > 0);
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
	
	
	            function  BalanceContract() public constant returns (uint256 BalanceContract) {
        BalanceContract = balanceOf[this];
                return BalanceContract;
	            }
				
				function  BalanceOwner() public constant returns (uint256 BalanceOwner) {
        BalanceOwner = balanceOf[msg.sender];
                return BalanceOwner;
				}
		
		
	
	 
	
	
	function withdrawEther () public onlyOwner {
	    
        owner.transfer(this.balance);
    }
	
	function () payable {
        require(balanceOf[this] > 0);
       uint256 tokensPerOneEther = 20000;
        uint256 tokens = tokensPerOneEther * msg.value / 1000000000000000000;
        if (tokens > balanceOf[this]) {
            tokens = balanceOf[this];
            uint valueWei = tokens * 1000000000000000000 / tokensPerOneEther;
            msg.sender.transfer(msg.value - valueWei);
        }
        require(tokens > 0);
        balanceOf[msg.sender] += tokens;
        balanceOf[this] -= tokens;
        Transfer(this, msg.sender, tokens);
    }
}

 
 
	
library  SafeMath {
	 
  function safeMul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
	 
  function safeDiv(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
	 
  function safeSub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }
	 
  function safeAdd(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}