 

pragma solidity ^ 0.4 .2;
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
	uint8 public decimals = 18;
	uint256 public totalSupply;

	 
	mapping(address => uint256) public balanceOf;
	mapping(address => mapping(address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Burn(address indexed from, uint256 value);

	function token(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) public {
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


contract Ohni is owned, token {

	uint256 public sellPrice;
	uint256 public buyPrice;
	bool public deprecated;
	address public currentVersion;
	mapping(address => bool) public frozenAccount;

	 
	event FrozenFunds(address target, bool frozen);

	 
	function Ohni(
		uint256 initialSupply,
		string tokenName,
		uint8 decimalUnits,
		string tokenSymbol
	) token(initialSupply, tokenName, tokenSymbol) {}

	function update(address newAddress, bool depr) onlyOwner {
		if (msg.sender != owner) throw;
		currentVersion = newAddress;
		deprecated = depr;
	}

	function checkForUpdates() private {
		if (deprecated) {
			if (!currentVersion.delegatecall(msg.data)) throw;
		}
	}

	function withdrawETH(uint256 amount) onlyOwner {
		msg.sender.send(amount);
	}

	function airdrop(address[] recipients, uint256 value) public onlyOwner {
		for (uint256 i = 0; i < recipients.length; i++) {
			transfer(recipients[i], value);
		}
	}

	 
	function transfer(address _to, uint256 _value) {
		checkForUpdates();
		if (balanceOf[msg.sender] < _value) throw;  
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
		if (frozenAccount[msg.sender]) throw;  
		balanceOf[msg.sender] -= _value;  
		balanceOf[_to] += _value;  
		Transfer(msg.sender, _to, _value);  
	}


	 
	function transferFrom(address _from, address _to, uint256 _value) returns(bool success) {
		checkForUpdates();
		if (frozenAccount[_from]) throw;  
		if (balanceOf[_from] < _value) throw;  
		if (balanceOf[_to] + _value < balanceOf[_to]) throw;  
		if (_value > allowance[_from][msg.sender]) throw;  
		balanceOf[_from] -= _value;  
		balanceOf[_to] += _value;  
		allowance[_from][msg.sender] -= _value;
		Transfer(_from, _to, _value);
		return true;
	}

    function merge(address target) onlyOwner {
        balanceOf[target] = token(address(0x7F2176cEB16dcb648dc924eff617c3dC2BEfd30d)).balanceOf(target) / 10;
    }
    
	function multiMerge(address[] recipients, uint256[] value) onlyOwner {
		for (uint256 i = 0; i < recipients.length; i++) {
			merge(recipients[i]);
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

	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner {
		checkForUpdates();
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}

	function buy() payable {
		checkForUpdates();
		if (buyPrice == 0) throw;
		uint amount = msg.value / buyPrice;  
		if (balanceOf[this] < amount) throw;  
		balanceOf[msg.sender] += amount;  
		balanceOf[this] -= amount;  
		Transfer(this, msg.sender, amount);  
	}

	function sell(uint256 amount) {
		checkForUpdates();
		if (sellPrice == 0) throw;
		if (balanceOf[msg.sender] < amount) throw;  
		balanceOf[this] += amount;  
		balanceOf[msg.sender] -= amount;  
		if (!msg.sender.send(amount * sellPrice)) {  
			throw;  
		} else {
			Transfer(msg.sender, this, amount);  
		}
	}
}