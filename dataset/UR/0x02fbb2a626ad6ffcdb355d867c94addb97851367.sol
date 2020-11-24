 

pragma solidity ^0.4.11;
 
contract admined {
	address public admin;

	function admined() public{
		admin = msg.sender;  
	}

	modifier onlyAdmin(){  
		require(msg.sender == admin);
		_;
	}

	function transferAdminship(address newAdmin) onlyAdmin public {  
		admin = newAdmin;
	}

}

contract Token {

	mapping (address => uint256) public balanceOf;
	 
	string public name;
	string public symbol;  
	uint8 public decimals;  
	uint256 public totalSupply;  
	event Transfer(address indexed from, address indexed to, uint256 value);  


	function Token(uint256 initialSupply, string tokenName, string tokenSymbol, uint8 decimalUnits) public{  
		balanceOf[msg.sender] = initialSupply;  
		totalSupply = initialSupply;  
		decimals = decimalUnits;  
		symbol = tokenSymbol;  
		name = tokenName;  
	}

	function transfer(address _to, uint256 _value) public{  
		require(balanceOf[msg.sender] >= _value);  
		require(balanceOf[_to] + _value >= balanceOf[_to]);  
		balanceOf[msg.sender] -= _value;  
		balanceOf[_to] += _value;  
		Transfer(msg.sender, _to, _value);  
	}

}

contract EcoCrypto is admined, Token{  

	function EcoCrypto() public   
	  Token (10000000000000000000, "EcoCrypto", "ECO", 8 ){  
		
	}

	function transfer(address _to, uint256 _value) public{  
		require(balanceOf[msg.sender] > 0);
		require(balanceOf[msg.sender] >= _value);
		require(balanceOf[_to] + _value >= balanceOf[_to]);
		 
		balanceOf[msg.sender] -= _value;
		balanceOf[_to] += _value;
		Transfer(msg.sender, _to, _value);
	}

}