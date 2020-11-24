 

pragma solidity ^0.5.10;

 
contract SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    assert(b > 0);
    uint256 c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c>=a && c>=b);
    return c;
  }
}
contract RyTest is SafeMath {
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

     
    constructor (
        uint256 initialSupply,
        string memory tokenName,
        uint8 decimalUnits,
        string memory tokenSymbol
        ) public {
        totalSupply = initialSupply * 10 ** uint256(decimalUnits);                         
        balanceOf[msg.sender] = totalSupply;               
        name = tokenName;                                    
        symbol = tokenSymbol;                                
        decimals = decimalUnits;                             
		owner = msg.sender;
    }

     
    function transfer(address _to, uint256 _value) public {                                
        require(_to != address(0x0) && _value > 0);
        if (balanceOf[msg.sender] < _value) assert(false);            
        if (balanceOf[_to] + _value < balanceOf[_to]) assert(false);  
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                 
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);                               
        emit Transfer(msg.sender, _to, _value);                    
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
		require(_value > 0);
        allowance[msg.sender][_spender] = _value;
        return true;
    }
       

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_to != address(0x0) && _value > 0);
        if (balanceOf[_from] < _value) assert(false);                  
        if (balanceOf[_to] + _value < balanceOf[_to]) assert(false);   
        if (_value > allowance[_from][msg.sender]) assert(false);      
        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value);                           
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);                               
        allowance[_from][msg.sender] = SafeMath.sub(allowance[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function burn(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) assert(false);                               
		if (_value <= 0) assert(false); 
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);             
        totalSupply = SafeMath.sub(totalSupply,_value);                                  
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
        if (balanceOf[msg.sender] < _value) assert(false);                                           
		if (_value <= 0) assert(false); 
        balanceOf[msg.sender] = SafeMath.sub(balanceOf[msg.sender], _value);                         
        freezeOf[msg.sender] = SafeMath.add(freezeOf[msg.sender], _value);                           
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
        if (freezeOf[msg.sender] < _value) assert(false);             
		if (_value <= 0) assert(false); 
        freezeOf[msg.sender] = SafeMath.sub(freezeOf[msg.sender], _value);
		balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], _value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
	
	 
	function withdrawEther(uint256 amount) public {
		require(msg.sender == owner);
		address(this).transfer(amount);
	}
	
	 
	function() external payable {
    }
}