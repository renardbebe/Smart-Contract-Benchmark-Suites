 

pragma solidity ^0.4.11;

contract Freewatch {
	string public name;
	string public symbol;
	uint8 public decimals;
	
     
    mapping (address => uint256) public balanceOf;
	
	event Transfer(address indexed from, address indexed to, uint256 value);
	
	 
	function Freewatch (
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
		) {
		balanceOf[msg.sender] = initialSupply;               
		name = tokenName;                                    
		symbol = tokenSymbol;                                
		decimals = decimalUnits;                             
}
	
	 
	function transfer(address _to, uint256 _value) {
		if(msg.data.length < (2 * 32) + 4) { revert(); }
		 
		if (balanceOf[msg.sender] < _value || balanceOf[_to] + _value < balanceOf[_to])
			revert();
		 
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
			 
		Transfer(msg.sender, _to, _value);
		}
}