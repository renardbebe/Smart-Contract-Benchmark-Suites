 

pragma solidity ^0.4.21;

 
library SafeMath {

	function mul(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a * b;
		require(a == 0 || c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal constant returns (uint256) {
		require(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal constant returns (uint256) {
		uint256 c = a + b;
		require(c>=a && c>=b);
		return c;
	}
}

contract UNBInterface {

	 
	uint256 public totalSupply;

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success);

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	 
	 
	function balanceOf(address _owner) public view returns (uint256 balance);

	 
	 
	 
	 
	function approve(address _spender, uint256 _value) public returns (bool success);

	 
	 
	 
	function allowance(address _owner, address _spender) public view returns (uint256 remaining);

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	event Approval(address indexed _owner, address indexed _spender, uint256 _value);
	
	 
    event Burn(address indexed from, uint256 value);
	
	 
    event Freeze(address indexed from, uint256 value);
	
	 
    event Unfreeze(address indexed from, uint256 value);
}

contract UNB is UNBInterface {

	using SafeMath for uint256;

    uint256 constant private MAX_UINT256 = 2**256 - 1;
    
    mapping (address => uint256) public balances;
	
	mapping (address => uint256) public freezes;
    
    mapping (address => mapping (address => uint256)) public allowed;

     
    string public name;                    
    uint8 public decimals;                 
    string public symbol;                  

    function UNB (
        uint256 _initialAmount,
        string _tokenName,
        uint8 _decimalUnits,
        string _tokenSymbol
    ) public {
        balances[msg.sender] = _initialAmount;                
        totalSupply = _initialAmount;                         
        name = _tokenName;                                    
        decimals = _decimalUnits;                             
        symbol = _tokenSymbol;                                
    }

     
     
     
     
    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != 0x0);
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);  
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value && balances[_to] + _value >= balances[_to]);
        require(_to != 0x0);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);  
        return true;
    }

     
     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);  
        return true;
    }

     
     
     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
	
	function burn(uint256 _value) public returns (bool success) {
		require(_value > 0); 
        require(balances[msg.sender] >= _value);             
        balances[msg.sender] = balances[msg.sender].sub(_value);                       
        totalSupply = totalSupply.sub(_value);                                 
        emit Burn(msg.sender, _value);
        return true;
    }
	
	function freeze(uint256 _value) public returns (bool success) {
		require(_value > 0); 
        require(balances[msg.sender] >= _value);             
        balances[msg.sender] = balances[msg.sender].sub(_value);                       
        freezes[msg.sender] = freezes[msg.sender].add(_value);                                 
        emit Freeze(msg.sender, _value);
        return true;
    }
	
	function unfreeze(uint256 _value) public returns (bool success) {
		require(_value > 0); 
		require(freezes[msg.sender] >= _value); 
        freezes[msg.sender] = freezes[msg.sender].sub(_value);                       
		balances[msg.sender] = balances[msg.sender].add(_value);
        emit Unfreeze(msg.sender, _value);
        return true;
    }
}