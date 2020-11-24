 

pragma solidity ^0.4.24;

 
library SafeMath {
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		uint256 c = a / b;
		 
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
	 
	string public name;
	string public symbol;
	uint8 public decimals = 18;
	 
	uint256 public totalSupply;

	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	 
	event Burn(address indexed from, uint256 value);

	 
	constructor(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);   
		balanceOf[msg.sender] = totalSupply;                 
		name = tokenName;                                    
		symbol = tokenSymbol;                                
	}

	 
	function _transfer(address _from, address _to, uint _value) internal {
		 
		require(_to != 0x0);
		 
		require(balanceOf[_from] >= _value);
		 
		require(balanceOf[_to] + _value > balanceOf[_to]);
		 
		uint previousBalances = balanceOf[_from] + balanceOf[_to];
		 
		balanceOf[_from] -= _value;
		 
		balanceOf[_to] += _value;
		emit Transfer(_from, _to, _value);
		 
		assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);      
		allowance[_from][msg.sender] -= _value;
		_transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
		public
		returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	 
	function burn(uint256 _value) public returns (bool success) {
		require(balanceOf[msg.sender] >= _value);    
		balanceOf[msg.sender] -= _value;             
		totalSupply -= _value;                       
		emit Burn(msg.sender, _value);
		return true;
	}

	 
	function burnFrom(address _from, uint256 _value) public returns (bool success) {
		require(balanceOf[_from] >= _value);                 
		require(_value <= allowance[_from][msg.sender]);     
		balanceOf[_from] -= _value;                          
		allowance[_from][msg.sender] -= _value;              
		totalSupply -= _value;                               
		emit Burn(_from, _value);
		return true;
	}
}

contract developed {
	address public developer;

	 
	constructor() public {
		developer = msg.sender;
	}

	 
	modifier onlyDeveloper {
		require(msg.sender == developer);
		_;
	}

	 
	function changeDeveloper(address _developer) public onlyDeveloper {
		developer = _developer;
	}

	 
	function withdrawToken(address tokenContractAddress) public onlyDeveloper {
		TokenERC20 _token = TokenERC20(tokenContractAddress);
		if (_token.balanceOf(this) > 0) {
			_token.transfer(developer, _token.balanceOf(this));
		}
	}
}

contract MyAdvancedToken is developed, TokenERC20 {

	uint256 public sellPrice;
	uint256 public buyPrice;

	mapping (address => bool) public frozenAccount;

	 
	event FrozenFunds(address target, bool frozen);

	 
	constructor (
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

	 
	function _transfer(address _from, address _to, uint _value) internal {
		require (_to != 0x0);                                
		require (balanceOf[_from] >= _value);                
		require (balanceOf[_to] + _value >= balanceOf[_to]);  
		require(!frozenAccount[_from]);                      
		require(!frozenAccount[_to]);                        
		balanceOf[_from] -= _value;                          
		balanceOf[_to] += _value;                            
		emit Transfer(_from, _to, _value);
	}

	 
	 
	 
	function mintToken(address target, uint256 mintedAmount) onlyDeveloper public {
		balanceOf[target] += mintedAmount;
		totalSupply += mintedAmount;
		emit Transfer(0, this, mintedAmount);
		emit Transfer(this, target, mintedAmount);
	}

	 
	 
	 
	function freezeAccount(address target, bool freeze) onlyDeveloper public {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	 
	 
	 
	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyDeveloper public {
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}

	 
	function buy() payable public {
		uint amount = msg.value / buyPrice;                
		_transfer(this, msg.sender, amount);               
	}

	 
	 
	function sell(uint256 amount) public {
		address myAddress = this;
		require(myAddress.balance >= amount * sellPrice);       
		_transfer(msg.sender, this, amount);               
		msg.sender.transfer(amount * sellPrice);           
	}
}

 
contract SpinToken is MyAdvancedToken {
	using SafeMath for uint256;

	bool public paused;

	mapping (address => bool) public allowMintTransfer;
	mapping (address => bool) public allowBurn;

	event Mint(address indexed account, uint256 value);

	 
	modifier onlyMintTransferBy(address account) {
		require(allowMintTransfer[account] == true || account == developer);
		_;
	}

	 
	modifier onlyBurnBy(address account) {
		require(allowBurn[account] == true || account == developer);
		_;
	}

	 
	modifier contractIsActive {
		require(paused == false);
		_;
	}

	 
	constructor(
		uint256 initialSupply,
		string tokenName,
		string tokenSymbol
	) MyAdvancedToken(initialSupply, tokenName, tokenSymbol) public {}

	 
	 
	 
	 
	function setPaused(bool _paused) public onlyDeveloper {
		paused = _paused;
	}

	 
	function setAllowMintTransfer(address _account, bool _allowed) public onlyDeveloper {
		allowMintTransfer[_account] = _allowed;
	}

	 
	function setAllowBurn(address _account, bool _allowed) public onlyDeveloper {
		allowBurn[_account] = _allowed;
	}

	 
	 
	 

	 
	function getTotalSupply() public constant returns (uint256) {
		return totalSupply;
	}

	 
	function getBalanceOf(address account) public constant returns (uint256) {
		return balanceOf[account];
	}

	 
	function transfer(address _to, uint256 _value) public contractIsActive returns (bool success) {
		_transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function transferFrom(address _from, address _to, uint256 _value) public contractIsActive returns (bool success) {
		require(_value <= allowance[_from][msg.sender]);      
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);
		_transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public contractIsActive returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes _extraData)
		public
		contractIsActive
		returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, this, _extraData);
			return true;
		}
	}

	 
	function burn(uint256 _value) public contractIsActive returns (bool success) {
		require(balanceOf[msg.sender] >= _value);						 
		balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);		 
		totalSupply = totalSupply.sub(_value);							 
		emit Burn(msg.sender, _value);
		return true;
	}

	 
	function burnFrom(address _from, uint256 _value) public contractIsActive returns (bool success) {
		require(balanceOf[_from] >= _value);									 
		require(_value <= allowance[_from][msg.sender]);						 
		balanceOf[_from] = balanceOf[_from].sub(_value);						 
		allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value); 
		totalSupply = totalSupply.sub(_value);									 
		emit Burn(_from, _value);
		return true;
	}

	 
	function buy() payable public contractIsActive {
		uint amount = msg.value.div(buyPrice);				 
		_transfer(this, msg.sender, amount);				 
	}

	 
	 
	function sell(uint256 amount) public contractIsActive {
		address myAddress = this;
		require(myAddress.balance >= amount.mul(sellPrice));	 
		_transfer(msg.sender, this, amount);					 
		msg.sender.transfer(amount.mul(sellPrice));				 
	}

	 
	function mintTransfer(address _to, uint _value) public contractIsActive
		onlyMintTransferBy(msg.sender)
		returns (bool) {
		require(_value > 0);
		totalSupply = totalSupply.add(_value);
		 
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Mint(msg.sender, _value);
		emit Transfer(msg.sender, _to, _value);
		return true;
	}

	 
	function burnAt(address _at, uint _value) public contractIsActive
		onlyBurnBy(msg.sender)
		returns (bool) {
		balanceOf[_at] = balanceOf[_at].sub(_value);
		totalSupply = totalSupply.sub(_value);
		emit Burn(_at, _value);
		return true;
	}

	 
	 
	 

	 
	function _transfer(address _from, address _to, uint256 _value) internal contractIsActive {
		 
		require(_to != 0x0);
		 
		require(balanceOf[_from] >= _value);
		require(!frozenAccount[_from]);                      
		require(!frozenAccount[_to]);                        
		 
		uint previousBalances = balanceOf[_from].add(balanceOf[_to]);
		 
		balanceOf[_from] = balanceOf[_from].sub(_value);
		 
		balanceOf[_to] = balanceOf[_to].add(_value);
		emit Transfer(_from, _to, _value);
		 
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}
}