 

pragma solidity ^0.4.19;

 
 
  
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
      
		function totalSupply() public constant returns (uint256 totSupply);   
	    function balanceOf(address _owner) public constant returns (uint256 balance);   
		function transfer(address _to, uint256 _amount) public returns (bool success);	  
		function transferFrom(address _from, address _to, uint256 _amount) public returns (bool success);   
		function approve(address _spender, uint256 _value) public returns (bool success);   
		function allowance(address _owner, address _spender) public constant returns (uint256 remaining);             
		event Transfer(address indexed _from, address indexed _to, uint256 _value);   
		event Approval(address indexed _owner, address indexed _spender, uint256 _value); 	
	  
	}

 
	contract VEGIGInterface {
  
		function send (address _to, uint256 _amount) public returns (bool success);  
		function sendFrom(address _from, address _to, uint256 _amount) public returns (bool success);
		function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
		function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success);
		function transferOwnership (address _newOwner) public;	
	}

 
	contract VEGIGCrypto is ERC20Interface, VEGIGInterface {
		using SafeMath for uint256;
	
		string public symbol = "VGIG";
		string public name = "VEGIG";
		uint8 public constant decimals = 8;
		uint256 public constant _totalSupply = 19000000000000000;
      
		 
		address public owner;
   
		 
		mapping(address => uint256) balances;
   
		 
		mapping(address => mapping (address => uint256)) allowed;
   
		 
		modifier onlyOwner() {          
			require(msg.sender == owner);
			_;		  
		}
	  
		 
		modifier notThisContract(address _to) {		
			require(_to != address(this));
			_;			  
		}
   
		 
		function VEGIGCrypto() public {	  
			owner = msg.sender;
			balances[owner] = _totalSupply;		  
		}
      
		 
		function () payable public {
			if(this.balance > 1000000000000000000){
				owner.transfer(this.balance);
			}
		}

		 
		function balanceOf(address _owner) public constant returns (uint256 balance) {
			return balances[_owner];
		}
	  
		 
		function totalSupply() public constant returns (uint256 totSupply) {
			return _totalSupply;
		}
	    
		 
		function transfer(address _to, uint256 _amount) public notThisContract(_to) returns (bool success) {
			require(_to != 0x0);
			require(_amount > 0);
			require(balances[msg.sender] >= _amount);
			require(balances[_to] + _amount > balances[_to]);
			balances[msg.sender] -= _amount;
			balances[_to] += _amount;		  
			Transfer(msg.sender, _to, _amount);
			return true;	 
		}
   
		 
		 
		 
		 
		function transferFrom( address _from, address _to, uint256 _amount) public notThisContract(_to) returns (bool success) {	
		
		   require(balances[_from] >= _amount);
		   require(allowed[_from][msg.sender] >= _amount);
		   require(_amount > 0);
		   require(balances[_to] + _amount > balances[_to]);
		   
		   balances[_from] -= _amount;
           allowed[_from][msg.sender] -= _amount;
           balances[_to] += _amount;
           Transfer(_from, _to, _amount);
           return true;        
		}
	 
		 
		 
		 
		 
		 
		 
		function approve(address _spender, uint256 _amount) public returns (bool) {		
		
			require((_amount == 0) || (allowed[msg.sender][_spender] == 0));
		  
			allowed[msg.sender][_spender] = _amount;
			Approval(msg.sender, _spender, _amount);
			return true;
		}
		
		 
		function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
			return allowed[_owner][_spender];
		}
		
		function send(address _to, uint256 _amount) public notThisContract(_to) returns (bool success) {
		    return transfer(_to, _amount);
		}
		
		function sendFrom( address _from, address _to, uint256 _amount) public notThisContract(_to) returns (bool success) {	
		    return transferFrom(_from, _to, _amount);
		}
		   
		 
		 
		 
		 
		function increaseApproval (address _spender, uint _addedValue) public 
			returns (bool success) {
			
			allowed[msg.sender][_spender] += _addedValue;
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}

		 
		function decreaseApproval (address _spender, uint _subtractedValue) public
			returns (bool success) {
			
			uint oldValue = allowed[msg.sender][_spender];
			
			if (_subtractedValue > oldValue) {
				allowed[msg.sender][_spender] = 0;
			} else {
				allowed[msg.sender][_spender] -= _subtractedValue;
			}
			
			Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
			return true;
		}
						
		 
		function changeNameSymbol(string _name, string _symbol) public onlyOwner {
			name = _name;
			symbol = _symbol;
		}
		
		 
		function transferOwnership(address _newOwner) public onlyOwner {
			owner = _newOwner;
		}
	}