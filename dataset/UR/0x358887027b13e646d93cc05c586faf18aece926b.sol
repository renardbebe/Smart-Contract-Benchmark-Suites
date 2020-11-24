 

pragma solidity ^0.4.18;

 
contract SafeMath {
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
    require (assertion);
  }
}
contract REL is SafeMath{
    uint previousBalances;
    uint currentBalance;
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

     
    function REL(
        uint256 initialSupply,
        string tokenName,
        uint8 decimalUnits,
        string tokenSymbol
        ) {
        balanceOf[msg.sender] = initialSupply;               
        totalSupply = initialSupply;                         
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
		owner = msg.sender;
    }
	
	 
	function changeowner(
        address _newowner
    )
    public
    returns (bool)  {
        require(msg.sender == owner);
        require(_newowner != address(0));
        owner = _newowner;
        return true;
    }

     
    function transfer(address _to, uint256 _value) {
        require (_to != 0x0) ;                                
		require (_value >= 0); 
        require (balanceOf[msg.sender] >= _value);            
        require (balanceOf[_to] + _value >= balanceOf[_to]) ;  
        previousBalances=safeAdd(balanceOf[msg.sender],balanceOf[_to]);
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                      
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                             
        currentBalance=safeAdd(balanceOf[msg.sender],balanceOf[_to]);
        require(previousBalances==currentBalance);
        Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value)
        returns (bool success) {
		require (_value >= 0) ; 
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
        require (_to != 0x0) ;                                 
		require (_value >= 0) ; 
        require (balanceOf[_from] >= _value) ;                  
        require (balanceOf[_to] + _value >= balanceOf[_to])  ;   
        require (allowance[_from][msg.sender]>=_value) ;      
        previousBalances=safeAdd(balanceOf[_from],balanceOf[_to]);
        balanceOf[_from] = SafeMath.safeSub(balanceOf[_from], _value);                            
        balanceOf[_to] = SafeMath.safeAdd(balanceOf[_to], _value);                              
        currentBalance=safeAdd(balanceOf[_from],balanceOf[_to]);
        require(previousBalances==currentBalance);
        allowance[_from][msg.sender] = SafeMath.safeSub(allowance[_from][msg.sender], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require (balanceOf[msg.sender] >= _value) ;             
		require (_value >= 0) ; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        totalSupply = SafeMath.safeSub(totalSupply,_value);                                 
        Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require (balanceOf[msg.sender] >= _value) ;             
		require (_value >= 0) ; 
        balanceOf[msg.sender] = SafeMath.safeSub(balanceOf[msg.sender], _value);                       
        freezeOf[msg.sender] = SafeMath.safeAdd(freezeOf[msg.sender], _value);                                 
        Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) returns (bool success) {
        require(msg.sender == owner);
        require (freezeOf[msg.sender] >= _value) ;             
		require (_value >= 0) ; 
        freezeOf[msg.sender] = SafeMath.safeSub(freezeOf[msg.sender], _value);                       
		balanceOf[msg.sender] = SafeMath.safeAdd(balanceOf[msg.sender], _value);
        Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function withdrawEther(uint256 amount) {
		require(msg.sender == owner);
		owner.transfer(amount);
	}
	
	 
	function() payable {
    }
}