 

contract EtherDOGEICO {
    
    function name() constant returns (string) { return "EtherDOGE"; }
    function symbol() constant returns (string) { return "eDOGE"; }
    function decimals() constant returns (uint8) { return 4; }
	

    uint256 public INITIAL_SUPPLY;
	uint256 public totalSupply;
	
	uint256 public totalContrib;
    
    uint256 public rate;
  
    address public owner;						     
	
	uint256 public amount;
	
	
	function EtherDOGEICO() {
        INITIAL_SUPPLY = 210000000000;               
		totalSupply = 0;
		
		totalContrib = 0;
        
        rate = 210000000;                            
		
		owner = msg.sender;			                 
		
		balances[msg.sender] = INITIAL_SUPPLY;		 
	}
	
	
	 
	 
	function () payable {
	    
	    uint256 tryAmount = div((mul(msg.value, rate)), 1 ether);                    
	    
		if (msg.value == 0 || msg.value < 0 || balanceOf(owner) < tryAmount) {		 
			revert();
		}
		
	    amount = 0;									                 
		amount = div((mul(msg.value, rate)), 1 ether);				 
		transferFrom(owner, msg.sender, amount);                     
		totalSupply += amount;										 
		totalContrib = (totalContrib + msg.value);
		amount = 0;									                 
		
		
		owner.transfer(msg.value);					                 

	}	
	
	
	
  
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  
  mapping(address => uint256) balances;


    function transfer(address _to, uint256 _value) returns (bool success) {

        if (_value == 0) { return false; }

        uint256 fromBalance = balances[msg.sender];

        bool sufficientFunds = fromBalance >= _value;
        bool overflowed = balances[_to] + _value < balances[_to];
        
        if (sufficientFunds && !overflowed) {
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }



    function balanceOf(address _owner) constant returns (uint256) { return balances[_owner]; }



    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {

        if (_value == 0) { return false; }
        
        uint256 fromBalance = balances[owner];

        bool sufficientFunds = fromBalance >= _value;

        if (sufficientFunds) {
            balances[_to] += _value;
            balances[_from] -= _value;
            
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

	
    function getStats() constant returns (uint256, uint256) {
        return (totalSupply, totalContrib);
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