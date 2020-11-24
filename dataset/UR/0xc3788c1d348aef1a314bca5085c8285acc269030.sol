 

 
contract SafeMath {
   
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
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

  function assert(bool assertion) internal {
    if (!assertion) throw;
  }
}

 
contract Token {

     
    function totalSupply() constant returns (uint256 supply) {}

     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {}

     
     
     
     
    function transfer(address _to, uint256 _value) returns (bool success) {}

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}

     
     
     
     
    function approve(address _spender, uint256 _value) returns (bool success) {}

     
     
     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

}

 
contract StandardToken is Token {

     
    function transfer(address _to, uint256 _value) returns (bool success) {
         
         
         
        if (balances[msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[msg.sender] -= _value;
            balances[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else { return false; }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
         
        if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to]) {
         
            balances[_to] += _value;
            balances[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else { return false; }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) allowed;

    uint256 public totalSupply;
}

contract NapoleonXToken is StandardToken, SafeMath {
     
    string public constant name = "NapoleonX Token";
    string public constant symbol = "NPX";
     
    uint8 public decimals = 2;
    uint public INITIAL_SUPPLY = 95000000;
    
     
    address napoleonXAdministrator;
    
     
    uint public endTime;
    
    event TokenAllocated(address investor, uint tokenAmount);
     
    modifier only_napoleonXAdministrator {
        require(msg.sender == napoleonXAdministrator);
        _;
    }

    modifier is_not_earlier_than(uint x) {
        require(now >= x);
        _;
    }
    modifier is_earlier_than(uint x) {
        require(now < x);
        _;
    }
    function isEqualLength(address[] x, uint[] y) internal returns (bool) { return x.length == y.length; }
    modifier onlySameLengthArray(address[] x, uint[] y) {
        require(isEqualLength(x,y));
        _;
    }
	
    function NapoleonXToken(uint setEndTime) {
        napoleonXAdministrator = msg.sender;
        endTime = setEndTime;
    }
	
     
    function populateWhitelisted(address[] whitelisted, uint[] tokenAmount) only_napoleonXAdministrator onlySameLengthArray(whitelisted, tokenAmount) is_earlier_than(endTime) {
        for (uint i = 0; i < whitelisted.length; i++) {
			uint previousAmount = balances[whitelisted[i]];
			balances[whitelisted[i]] = tokenAmount[i];
			totalSupply = totalSupply-previousAmount+tokenAmount[i];
            TokenAllocated(whitelisted[i], tokenAmount[i]);
        }
    }
    
    function changeFounder(address newAdministrator) only_napoleonXAdministrator {
        napoleonXAdministrator = newAdministrator;
    }
 
    function getICOStage() public constant returns(string) {
         if (now < endTime){
            return "Presale ended, standard ICO running";
         }
         if (now >= endTime){
            return "ICO finished";
         }
    }
}