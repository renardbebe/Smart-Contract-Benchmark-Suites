 

pragma solidity ^0.4.18;

 
contract SafeMath {
  function safeMult(uint256 a, uint256 b) internal returns (uint256) {
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
}

contract TokenERC20 {
     function balanceOf(address _owner) constant returns (uint256  balance);
     function transfer(address _to, uint256  _value) returns (bool success);
     function transferFrom(address _from, address _to, uint256  _value) returns (bool success);
     function approve(address _spender, uint256  _value) returns (bool success);
     function allowance(address _owner, address _spender) constant returns (uint256 remaining);
     event Transfer(address indexed _from, address indexed _to, uint256  _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract BICToken is SafeMath, TokenERC20{ 
    string public name = "BIC";
    string public symbol = "BIC";
    uint8 public decimals = 18;
    uint256 public totalSupply;
	address public owner = 0x0;
	string  public version = "1.0";	
	
    bool public stopped = false;	
    bool public locked = false;	
    uint256 public currentSupply;           
    uint256 public tokenRaised = 0;    
    uint256 public tokenExchangeRate = 146700; 

     
    mapping (address => uint256) public balanceOf;
	mapping (address => uint256) public freezeOf;
    mapping (address => mapping (address => uint256)) public allowance;

     
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);

     
    function BICToken(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
        ) {
        totalSupply = formatDecimals(initialSupply);      			  
        balanceOf[msg.sender] = totalSupply;              			  
        name = tokenName;                                   		  
		currentSupply = totalSupply;
        symbol = tokenSymbol;                                         
		owner = msg.sender;
    }
	
	modifier onlyOwner()  { 
		require(msg.sender == owner); 
		_; 
	}
	
	modifier validAddress()  {
        require(address(0) != msg.sender);
        _;
    }	

    modifier isRunning() {
        assert (!stopped);
        _;
    }
	
    modifier unlocked() {
        require(!locked);
        _;
    }
	
    function formatDecimals(uint256 _value) internal returns (uint256 ) {
        return _value * 10 ** uint256(decimals);
    }
	
	function balanceOf(address _owner) constant returns (uint256 balance) {
        return balanceOf[_owner];
    }

     
    function approve(address _spender, uint256 _value) isRunning validAddress unlocked returns (bool success) {
        require(_value > 0);
        allowance[msg.sender][_spender] = _value;
		Approval(msg.sender, _spender, _value);
        return true;
    }
	
	 
	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowance[_owner][_spender];
	}

     
    function transfer(address _to, uint256 _value) isRunning validAddress unlocked returns (bool success) {	
        _transfer(msg.sender, _to, _value);
    }
	
	 
    function _transfer(address _from, address _to, uint _value) internal {
         
        require(_to != address(0));
        require(_value > 0);
         
        require(balanceOf[_from] >= _value);
         
        require(balanceOf[_to] + _value > balanceOf[_to]);
         
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);    
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);        
        Transfer(_from, _to, _value);
         
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) isRunning validAddress unlocked returns (bool success) {	
        require(_value <= allowance[_from][msg.sender]);     		 
        require(_value > 0);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        _transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) isRunning validAddress unlocked returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   							   
        require(_value > 0);   
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);   
        totalSupply = SafeMath.safeSub(totalSupply,_value);                        
        currentSupply = SafeMath.safeSub(currentSupply,_value);                    
        Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) isRunning validAddress unlocked returns (bool success) {	
        require(balanceOf[msg.sender] >= _value);   		 					  
        require(_value > 0);   
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);  
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);    
        Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) isRunning validAddress unlocked returns (bool success) {
        require(freezeOf[msg.sender] >= _value);   		 						    
        require(_value > 0);   
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);      
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);    
        Unfreeze(msg.sender, _value);
        return true;
    }
	
	function setTokenExchangeRate(uint256 _tokenExchangeRate) onlyOwner external {
        require(_tokenExchangeRate > 0);   
        require(_tokenExchangeRate != tokenExchangeRate);   
        tokenExchangeRate = _tokenExchangeRate;
    } 
	
    function setName(string _name) onlyOwner {
        name = _name;
    }
	
    function setSymbol(string _symbol) onlyOwner {
        symbol = _symbol;
    }
}