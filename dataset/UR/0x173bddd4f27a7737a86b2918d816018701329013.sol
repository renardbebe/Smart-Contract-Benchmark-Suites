 

pragma solidity ^0.4.11;




contract kkICOTest77 {
    
    string public name;
    string public symbol;
    
    uint256 public decimals;
    uint256 public INITIAL_SUPPLY;
    uint256 public totalSupply;
    
    uint256 public rate;
  
    address public owner;						     
	uint256 public tokens;							 
	
	uint256 public amount;
	
	
	function kkICOTest77() {			 
        name = "kkTEST77";
        symbol = "kkTST77";
        
        decimals = 0;
        INITIAL_SUPPLY = 30000000;
        
        rate = 5000;
		
		owner = msg.sender;			     
		tokens = INITIAL_SUPPLY;
		totalSupply = INITIAL_SUPPLY;
	}
	
	
	 
	 
	function () payable {
	    
	    uint256 tryAmount = div((mul(msg.value, rate)), 1 ether);            
	    
		if (msg.value == 0 || msg.value < 0 || tokens < tryAmount) {		 
			throw;
		}
		
		buyTokens(msg.value);		 

	}
	
	
	 
	 
	function buyTokens(uint256 etherSent) payable {	                 
	    amount = 0;									                 
		amount = div((mul(etherSent, rate)), 1 ether);		 
		balances[msg.sender] += amount;                              
		tokens -= amount;		  					                 
		amount = 0;									                 
		
		
		owner.transfer(msg.value);					 

	}
	
	
	
	
	
	
	
  
  event Transfer(address indexed from, address indexed to, uint256 value);
  
  event Approval(address indexed owner, address indexed spender, uint256 value);
  
  
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
  
  mapping (address => mapping (address => uint256)) allowed;



  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    var _allowance = allowed[_from][msg.sender];


    balances[_to] = add(balances[_to], _value);
    balances[_from] = sub(balances[_from], _value);
    allowed[_from][msg.sender] = sub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }


  function approve(address _spender, uint256 _value) returns (bool) {

    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }


  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
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