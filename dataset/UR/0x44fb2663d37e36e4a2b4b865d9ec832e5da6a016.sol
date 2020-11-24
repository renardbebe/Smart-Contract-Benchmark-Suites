 

pragma solidity 0.4.8;

contract tokenSpender { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }

contract XDRAC { 
	
	
	 
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public initialSupply;
	

	 
	mapping (address => uint) public balanceOf;
	mapping (address => mapping (address => uint)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint value);
	event Approval(address indexed from, address indexed spender, uint value);

	
	
	 
	function XDRAC() {
		initialSupply = 10000000000000;
		balanceOf[msg.sender] = initialSupply;              
		name = 'DracShares';                                  
		symbol = 'XDRAC';                               	  
		decimals = 6;                           		  
		
	}
	
	function totalSupply() returns(uint){
		return initialSupply ;
	}

	 
	function transfer(address _to, uint256 _value) 
	returns (bool success) {
		if (balanceOf[msg.sender] >= _value && _value > 0) {
			balanceOf[msg.sender] -= _value;
			balanceOf[_to] += _value;
			Transfer(msg.sender, _to, _value);
			return true;
		} else return false; 
	}

	 

	
	
	function approveAndCall(address _spender,
							uint256 _value,
							bytes _extraData)
	returns (bool success) {
		allowance[msg.sender][_spender] = _value;     
		tokenSpender spender = tokenSpender(_spender);
		spender.receiveApproval(msg.sender, _value, this, _extraData);
		Approval(msg.sender, _spender, _value);
		return true;
	}
	
	
	 
	function approve(address _spender, uint256 _value) returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
}

	
	
	 
	function transferFrom(address _from,
						  address _to,
						  uint256 _value)
	returns (bool success) {
		if (balanceOf[_from] >= _value && allowance[_from][msg.sender] >= _value && _value > 0) {
			balanceOf[_to] += _value;
			Transfer(_from, _to, _value);
			balanceOf[_from] -= _value;
			allowance[_from][msg.sender] -= _value;
			return true;
		} else return false; 
	}

	
	
	 
	function () {
		throw;      
	}        
}