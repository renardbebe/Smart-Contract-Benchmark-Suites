 

pragma solidity ^0.4.2;
contract owned {
	address public owner;
	function owned() {
		owner = msg.sender;
	}
	function changeOwner(address newOwner) onlyowner {
		owner = newOwner;
	}
	modifier onlyowner() {
		if (msg.sender==owner) _;
	}
}
contract tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData); }
contract CSToken is owned {
	 
	string public standard = 'Token 0.1';
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;
	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;
	 
	event Transfer(address indexed from, address indexed to, uint256 value);
	 
	function CSToken(
	uint256 initialSupply,
	string tokenName,
	uint8 decimalUnits,
	string tokenSymbol
	) {
		owner = msg.sender;
		balanceOf[msg.sender] = initialSupply;               
		totalSupply = initialSupply;                         
		name = tokenName;                                    
		symbol = tokenSymbol;                                
		decimals = decimalUnits;                             
	}
	 
	function transfer(address _to, uint256 _value) {
		if (balanceOf[msg.sender] < _value) throw;            
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
		balanceOf[msg.sender] -= _value;                      
		balanceOf[_to] += _value;                             
		Transfer(msg.sender, _to, _value);                    
	}
	function mintToken(address target, uint256 mintedAmount) onlyowner {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, owner, mintedAmount);
		Transfer(owner, target, mintedAmount);
	}
	 
	function approve(address _spender, uint256 _value)
	returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}
	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
	returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}
	 
	function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		if (balanceOf[_from] < _value) throw;                  
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;   
		if (_value > allowance[_from][msg.sender]) throw;    
		balanceOf[_from] -= _value;                           
		balanceOf[_to] += _value;                             
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}
	 
	function () {
		throw;      
	}
}