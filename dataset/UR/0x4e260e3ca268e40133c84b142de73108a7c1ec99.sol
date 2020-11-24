 

pragma solidity ^0.4.14;


 


contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}




contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);
  function allowance(address owner, address spender) constant returns (uint);

  function transfer(address to, uint value) returns (bool ok);
  function transferFrom(address from, address to, uint value) returns (bool ok);
  function approve(address spender, uint value) returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}




contract StandardToken is ERC20, SafeMath {

   
  event Minted(address receiver, uint amount);

   
  mapping(address => uint) balances;

   
  mapping (address => mapping (address => uint)) allowed;

   
  function isToken() public constant returns (bool weAre) {
    return true;
  }

  function transfer(address _to, uint _value) returns (bool success) {
      
      if (_value < 1) {
          revert();
      }
      
    balances[msg.sender] = safeSub(balances[msg.sender], _value);
    balances[_to] = safeAdd(balances[_to], _value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
      
      if (_value < 1) {
          revert();
      }
      
    uint _allowance = allowed[_from][msg.sender];

    balances[_to] = safeAdd(balances[_to], _value);
    balances[_from] = safeSub(balances[_from], _value);
    allowed[_from][msg.sender] = safeSub(_allowance, _value);
    Transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) returns (bool success) {

     
     
     
     
    if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

}





 

contract YoshiCoin is StandardToken {
  
    
    uint256 public rate = 50;				 
    address public owner = msg.sender;		 
	uint256 public tokenAmount;
  
    function name() constant returns (string) { return "YoshiCoin"; }
    function symbol() constant returns (string) { return "YC"; }
    function decimals() constant returns (uint8) { return 0; }
	


  function mint(address receiver, uint amount) public {
      
     tokenAmount = ((msg.value*rate)/(1 ether));		 
      
    if (totalSupply > 371) {         
        revert();
    }
    
    if (balances[msg.sender] > 4) {              
        revert();
    }
    
    if (balances[msg.sender]+tokenAmount > 5) {     
        revert();
    }
    
    if (tokenAmount > 5) {           
        revert();
    }
    
	if ((tokenAmount+totalSupply) > 372) {       
        revert();
    }

      if (amount != ((msg.value*rate)/1 ether)) {        
          revert();
      }
      
      if (msg.value <= 0) {                  
          revert();
      }
      
      if (amount < 1) {                      
          revert();
      }

    totalSupply = safeAdd(totalSupply, amount);
    balances[receiver] = safeAdd(balances[receiver], amount);

     
     
    Transfer(0, receiver, amount);
  }

  
  
	 
	 
function () payable {
    
    if (balances[msg.sender] > 4) {      
        revert();
    }
    
    if (totalSupply > 371) {         
        revert();
    }
    

	if (msg.value <= 0) {		 
		revert();
	}
	

	tokenAmount = 0;								 
	tokenAmount = ((msg.value*rate)/(1 ether));		 
	
    if (balances[msg.sender]+tokenAmount > 5) {      
        revert();
    }
	
    if (tokenAmount > 5) {           
        revert();
    }
	
	if (tokenAmount < 1) {
        revert();
    }
    
	if ((tokenAmount+totalSupply) > 372) {       
        revert();
    }
      
	mint(msg.sender, tokenAmount);
	tokenAmount = 0;							 
		
		
	owner.transfer(msg.value);					 

}  
  
  
  
}