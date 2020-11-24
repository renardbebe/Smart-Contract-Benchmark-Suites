 

pragma solidity ^ 0.5 .1;

interface tokenRecipient {
	function receiveApproval(address from, uint256 value, address token, bytes calldata extraData) external;
}


contract ERC20Token {
	string private _name;

	function name() public view returns(string memory) {
		return _name;
	}
	string private _symbol;

	function symbol() public view returns(string memory) {
		return _symbol;
	}
	uint8 private _decimals = 18;

	function decimals() public view returns(uint8) {
		return _decimals;
	}
	 
	uint256 public _totalSupply;

	function totalSupply() public view returns(uint256) {
		return _totalSupply;
	}
	 
	 
	mapping(address => uint256) public _balanceOf;

	function balanceOf(address _owner) public view returns(uint256 balance) {
		return _balanceOf[_owner];
	}

	 
	mapping(address => mapping(address => uint256)) public _allowance;

	 
	 
	event Transfer(address indexed from, address indexed to, uint256 value);
	 
	 
	event Approval(address indexed owner, address indexed spender, uint256 value);
	 
	 
	event Burn(address indexed from, uint256 value);

	 
	constructor(
		uint256 initialSupply,
		string memory tokenName,
		string memory tokenSymbol
	) public {
		_totalSupply = initialSupply * 10 ** uint256(_decimals);  
		 
		_balanceOf[msg.sender] = _totalSupply;  
		_name = tokenName;  
		_symbol = tokenSymbol;  
	}

	 
	function _transfer(address from, address to, uint value) internal {
		 
		require(to != address(0x0));  
		 
		require(_balanceOf[from] >= value);  
		 
		require(_balanceOf[to] + value >= _balanceOf[to]);  
		 
		uint previousBalances = _balanceOf[from] + _balanceOf[to];  
		 
		_balanceOf[from] -= value;  
		 
		_balanceOf[to] += value;  
		 
		emit Transfer(from, to, value);
		 
		assert(_balanceOf[from] + _balanceOf[to] == previousBalances);  
	}


	 
	function transfer(address to, uint256 value) public returns(bool success) {
		_transfer(msg.sender, to, value);
		return true;
	}


	function transferFrom(address from, address to, uint256 value) public returns(bool success) {
		 
		require(value <= _allowance[from][msg.sender]);  
		 
		_allowance[from][msg.sender] -= value;
		 
		_transfer(from, to, value);
		return true;
	}


	function approve(address spender, uint256 value) public
	returns(bool success) {
		 
		_allowance[msg.sender][spender] = value;
		 
		emit Approval(msg.sender, spender, value);
		return true;
	}

	function approveAndCall(address spender, uint256 value, bytes memory extraData) public returns(bool success) {
		tokenRecipient _spender = tokenRecipient(spender);
		if (approve(spender, value)) {
			_spender.receiveApproval(msg.sender, value, address(this), extraData);
			return true;
		}
	}

	function burn(uint256 value) public returns(bool success) {
		require(_balanceOf[msg.sender] >= value);  
		_balanceOf[msg.sender] -= value;  
		_totalSupply -= value;  
		 
		emit Burn(msg.sender, value);
		return true;
	}

	function burnFrom(address from, uint256 value) public returns(bool success) {
		require(_balanceOf[from] >= value);  
		require(value <= _allowance[from][msg.sender]);  
		_balanceOf[from] -= value;  
		_allowance[from][msg.sender] -= value;  
		_totalSupply -= value;  
		 
		emit Burn(from, value);
		return true;
	}

}