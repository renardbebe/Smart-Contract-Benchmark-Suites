 

pragma solidity ^0.4.11;




contract kkICOTest80 {
    
    string public name;
    string public symbol;
    
    uint256 public decimals;
    uint256 public INITIAL_SUPPLY;
    
    uint256 public rate;
  
    address public owner;						     
	
	uint256 public amount;
	
	
	function kkICOTest80() {
        name = "kkTEST80";
        symbol = "kkTST80";
        
        decimals = 0;
        INITIAL_SUPPLY = 30000000;                   
        
        rate = 5000;                                 
		
		owner = msg.sender;			                 
		
		balances[msg.sender] = INITIAL_SUPPLY;		 
	}
	
	
	 
	 
	function () payable {
	    
	    uint256 tryAmount = div((mul(msg.value, rate)), 1 ether);                    
	    
		if (msg.value == 0 || msg.value < 0 || balanceOf(owner) < tryAmount) {		 
			throw;
		}
		
	    amount = 0;									                 
		amount = div((mul(msg.value, rate)), 1 ether);				 
		transferFrom(owner, msg.sender, amount);                     
		amount = 0;									                 
		
		
		owner.transfer(msg.value);					                 

	}	
	
	
	
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  
  mapping(address => uint256) balances;


  function transfer(address _to, uint256 _value) returns (bool) {
    balances[msg.sender] = sub(balances[msg.sender], _value);
    balances[_to] = add(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }



  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }



  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    balances[_to] = add(balances[_to], _value);
    balances[_from] = sub(balances[_from], _value);
    Transfer(_from, _to, _value);
    return true;
  }

	
	

	
	
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
	
	
	
}