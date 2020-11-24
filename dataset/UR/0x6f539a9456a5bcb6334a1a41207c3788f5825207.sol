 

pragma solidity ^ 0.4.2;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}


contract owned {
	address public owner;

	function owned() public {
		owner = msg.sender;
	}

	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}

	function transferOwnership(address newAdmin) onlyOwner public {
		owner = newAdmin;
	}
}

contract tokenRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) public;
}

contract token {
	 
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	 
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Burn(address indexed from, uint256 value);

	function token(uint256 initialSupply, string tokenName,	uint8 decimalCount, string tokenSymbol) public {
	    decimals = decimalCount;
		totalSupply = initialSupply * 10 ** uint256(decimals);  
		balanceOf[msg.sender] = totalSupply;  
		name = tokenName;  
		symbol = tokenSymbol;  
	}

	 
	function transfer(address _to, uint256 _value) {
		if (balanceOf[msg.sender] < _value) throw;  
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
		balanceOf[msg.sender] -= _value;  
		balanceOf[_to] += _value;  
		Transfer(msg.sender, _to, _value);  
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		if (balanceOf[_from] < _value) throw;  
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
		if (_value > allowance[_from][msg.sender]) throw;  
		balanceOf[_from] -= _value;  
		balanceOf[_to] += _value;  
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public
	returns(bool success) {
		allowance[msg.sender][_spender] = _value;
		return true;
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns(bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	 
	function burn(uint256 _value) public returns(bool success) {
		require(balanceOf[msg.sender] >= _value);  
		balanceOf[msg.sender] -= _value;  
		totalSupply -= _value;  
		Burn(msg.sender, _value);
		return true;
	}

	 
	function burnFrom(address _from, uint256 _value) public returns(bool success) {
		require(balanceOf[_from] >= _value);  
		require(_value <= allowance[_from][msg.sender]);  
		balanceOf[_from] -= _value;  
		allowance[_from][msg.sender] -= _value;  
		totalSupply -= _value;  
		Burn(_from, _value);
		return true;
	}
}

contract OldToken {
  function totalSupply() constant returns (uint256 supply) {}
  function balanceOf(address _owner) constant returns (uint256 balance) {}
  function transfer(address _to, uint256 _value) returns (bool success) {}
  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {}
  function approve(address _spender, uint256 _value) returns (bool success) {}
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  uint public decimals;
  string public name;
}

contract Ohni is owned, token {
	OldToken ohniOld = OldToken(0x7f2176ceb16dcb648dc924eff617c3dc2befd30d);  
    using SafeMath for uint256;  
	uint256 public sellPrice;
	uint256 public buyPrice;
	bool public deprecated;
	address public currentVersion;
	mapping(address => bool) public frozenAccount;

	 
	event FrozenFunds(address target, bool frozen);
	event ChangedTokens(address changedTarget, uint256 amountToChanged);
	 
	function Ohni(uint256 initialSupply, string tokenName, uint8 decimalUnits, string tokenSymbol) token(initialSupply, tokenName, decimalUnits, tokenSymbol) {}

	function update(address newAddress, bool depr) onlyOwner {
		if (msg.sender != owner) throw;
		currentVersion = newAddress;
		deprecated = depr;
	}

	function checkForUpdates() internal {
		if (deprecated) {
			if (!currentVersion.delegatecall(msg.data)) throw;
		}
	}

	function withdrawETH(uint256 amount) onlyOwner {
		msg.sender.send(amount);
	}

	function airdrop(address[] recipients, uint256 value) onlyOwner {
		for (uint256 i = 0; i < recipients.length; i++) {
			transfer(recipients[i], value);
		}
	}

  	function merge() public {
		checkForUpdates();
		uint256 amountChanged = ohniOld.allowance(msg.sender, this);
		require(amountChanged > 0);
		require(amountChanged < 100000000);
		require(ohniOld.balanceOf(msg.sender) < 100000000);
   		require(msg.sender != address(0xa36e7c76da888237a3fb8a035d971ae179b45fad));
		if (!ohniOld.transferFrom(msg.sender, owner, amountChanged)) throw;
		amountChanged = (amountChanged * 10 ** uint256(decimals)) / 10;
		balanceOf[owner] = balanceOf[address(owner)].sub(amountChanged);
    	balanceOf[msg.sender] = balanceOf[msg.sender].add(amountChanged);
		Transfer(address(owner), msg.sender, amountChanged);
		ChangedTokens(msg.sender,amountChanged);
  	}
    
	function multiMerge(address[] recipients) onlyOwner {
		checkForUpdates();
    	for (uint256 i = 0; i < recipients.length; i++) {	
    		uint256 amountChanged = ohniOld.allowance(msg.sender, owner);
    		require(amountChanged > 0);
    		require(amountChanged < 100000000);
    		require(ohniOld.balanceOf(msg.sender) < 100000000);
       		require(msg.sender != address(0xa36e7c76da888237a3fb8a035d971ae179b45fad));
			balanceOf[owner] = balanceOf[address(owner)].sub(amountChanged);
			balanceOf[msg.sender] = balanceOf[msg.sender].add(amountChanged);
			Transfer(address(owner), msg.sender, amountChanged);
		}
	}

	function mintToken(address target, uint256 mintedAmount) onlyOwner {
		checkForUpdates();
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		Transfer(0, this, mintedAmount);
		Transfer(this, target, mintedAmount);
	}

	function freezeAccount(address target, bool freeze) onlyOwner {
		checkForUpdates();
		frozenAccount[target] = freeze;
		FrozenFunds(target, freeze);
	}
}