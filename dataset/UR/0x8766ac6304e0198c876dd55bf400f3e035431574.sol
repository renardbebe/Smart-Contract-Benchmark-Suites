 

pragma solidity ^0.4.16;

contract Ownable {
    
	address public owner; 
    
	function Ownable() public {  
    	owner = msg.sender;
	}
 
	modifier onlyOwner() {  
    	require(msg.sender == owner);
    	_;
	}
 
	function transferOwnership(address _owner) public onlyOwner {  
    	owner = _owner;
	}
    
}

contract KVCoin is Ownable{

  string public name;  
  string public symbol;  
  uint8 public decimals;  
	 
  uint256 public tokenTotalSupply; 

  function totalSupply() constant returns (uint256 _totalSupply){  
  	return tokenTotalSupply;
	}
   
  mapping (address => uint256) public balances;  
  mapping (address => mapping (address => uint256)) public allowed;  

  function balanceOf(address _owner) public constant returns (uint balance) {  
  	return balances[_owner];
  }

  event Transfer(address indexed _from, address indexed _to, uint256 _value);  
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);  
  event Mint(address indexed _to, uint256 _amount);  
  event Burn(address indexed _from, uint256 _value);  

  function KVCoin () {
	name = "KVCoin";  
	symbol = "KVC";  
	decimals = 0;  
   	 
	tokenTotalSupply = 0;  
	}

  function _transfer(address _from, address _to, uint256 _value) internal returns (bool){  
	require (_to != 0x0);  
	require(balances[_from] >= _value);  
	require(balances[_to] + _value >= balances[_to]);  

	balances[_from] -= _value;  
	balances[_to] += _value;  

	Transfer(_from, _to, _value);
	if (_to == address(this)){  
  	return burn();
	}
	return true;
  }

  function serviceTransfer(address _from, address _to, uint256 _value) {  
	require((msg.sender == owner)||(msg.sender == saleAgent));  
	_transfer(_from, _to, _value);        	 
  }

    
  function transfer(address _to, uint256 _value) returns (bool success) {  
	return _transfer(msg.sender, _to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {  
	require(_value <= allowed[_from][_to]); 
	allowed[_from][_to] -= _value;  
	return _transfer(_from, _to, _value); 
  }
 
  function approve(address _spender, uint256 _value) returns (bool success){  
	allowed[msg.sender][_spender] += _value;
	Approval(msg.sender, _spender, _value);
	return true;
  }

  address public saleAgent;  
 
	function setSaleAgent(address newSaleAgnet) public {  
  	require(msg.sender == saleAgent || msg.sender == owner);
  	saleAgent = newSaleAgnet;
	}
    
    
  function mint(address _to, uint256 _amount) public returns (bool) {  
	require(msg.sender == saleAgent);
	tokenTotalSupply += _amount;
	balances[_to] += _amount;
	Mint(_to, _amount);
	if (_to == address(this)){  
  	return burn();
	}
	return true;
  }
 
  function() external payable {
	owner.transfer(msg.value);
  }

  function burn() internal returns (bool success) {  
	uint256 burningTokensAmmount = balances[address(this)];  
	tokenTotalSupply -= burningTokensAmmount;  
	balances[address(this)] = 0;                  	 
    
	Burn(msg.sender, burningTokensAmmount);
	return true;
  }

  function allowance(address _owner, address _spender) constant returns (uint256 remaining){  
	return allowed[_owner][_spender];
  }
    
}