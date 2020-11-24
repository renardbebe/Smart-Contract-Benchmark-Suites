 

pragma solidity 0.4.24;


 
library SafeMath {
	function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
		if (_a == 0) {
			return 0;
		}
		uint256 c = _a * _b;
		assert(c / _a == _b);
		return c;
	}

	function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
		return _a / _b;
	}

	function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
		assert(_b <= _a);
		return _a - _b;
	}

	function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
		uint256 c = _a + _b;
		assert(c >= _a);
		return c;
	}
}

 
contract Ownable {
	 
	mapping(address => bool) public owners;
	
	 
	constructor() public {
		owners[msg.sender] = true;
	}

	 
	modifier onlyOwners() {
		require(owners[msg.sender], 'Owner message sender required.');
		_;
	}

	 
	function setOwner(address _owner, bool _isAllowed) public onlyOwners {
		require(_owner != address(0), 'Non-zero owner-address required.');
		owners[_owner] = _isAllowed;
	}
}

 
contract Destroyable is Ownable {

	constructor() public payable {}

	 
	function destroy() public onlyOwners {
		selfdestruct(msg.sender);
	}

	 
	function destroyAndSend(address _recipient) public onlyOwners {
		require(_recipient != address(0), 'Non-zero recipient address required.');
		selfdestruct(_recipient);
	}
}

 
contract BotOperated is Ownable {
	 
	mapping(address => bool) public bots;

	 
	modifier onlyBotsOrOwners() {
		require(bots[msg.sender] || owners[msg.sender], 'Bot or owner message sender required.');
		_;
	}

	 
	modifier onlyBots() {
		require(bots[msg.sender], 'Bot message sender required.');
		_;
	}

	 
	constructor() public {
		bots[msg.sender] = true;
	}

	 
	function setBot(address _bot, bool _isAllowed) public onlyOwners {
		require(_bot != address(0), 'Non-zero bot-address required.');
		bots[_bot] = _isAllowed;
	}
}

 
contract Pausable is BotOperated {
	event Pause();
	event Unpause();

	bool public paused = true;

	 
	modifier whenNotPaused() {
		require(!paused, 'Unpaused contract required.');
		_;
	}

	 
	function pause() public onlyBotsOrOwners {
		paused = true;
		emit Pause();
	}

	 
	function unpause() public onlyBotsOrOwners {
		paused = false;
		emit Unpause();
	}
}

interface EternalDataStorage {
	function balances(address _owner) external view returns (uint256);

	function setBalance(address _owner, uint256 _value) external;

	function allowed(address _owner, address _spender) external view returns (uint256);

	function setAllowance(address _owner, address _spender, uint256 _amount) external;

	function totalSupply() external view returns (uint256);

	function setTotalSupply(uint256 _value) external;

	function frozenAccounts(address _target) external view returns (bool isFrozen);

	function setFrozenAccount(address _target, bool _isFrozen) external;

	function increaseAllowance(address _owner,  address _spender, uint256 _increase) external;

	function decreaseAllowance(address _owner,  address _spender, uint256 _decrease) external;
}

interface Ledger {
	function addTransaction(address _from, address _to, uint _tokens) external;
}

interface WhitelistData {
	function kycId(address _customer) external view returns (bytes32);
}


 
contract ERC20Standard {
	
	using SafeMath for uint256;

	EternalDataStorage internal dataStorage;

	Ledger internal ledger;

	WhitelistData internal whitelist;

	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	modifier isWhitelisted(address _customer) {
		require(whitelist.kycId(_customer) != 0x0, 'Whitelisted customer required.');
		_;
	}

	 
	constructor(address _dataStorage, address _ledger, address _whitelist) public {
		require(_dataStorage != address(0), 'Non-zero data storage address required.');
		require(_ledger != address(0), 'Non-zero ledger address required.');
		require(_whitelist != address(0), 'Non-zero whitelist address required.');

		dataStorage = EternalDataStorage(_dataStorage);
		ledger = Ledger(_ledger);
		whitelist = WhitelistData(_whitelist);
	}

	 
	function totalSupply() public view returns (uint256 totalSupplyAmount) {
		return dataStorage.totalSupply();
	}

	 
	function balanceOf(address _owner) public view returns (uint256 balance) {
		return dataStorage.balances(_owner);
	}

	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		return _transfer(msg.sender, _to, _value);
	}

	     
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		uint256 allowed = dataStorage.allowed(_from, msg.sender);
		require(allowed >= _value, 'From account has insufficient balance');

		allowed = allowed.sub(_value);
		dataStorage.setAllowance(_from, msg.sender, allowed);

		return _transfer(_from, _to, _value);
	}

	 
	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		require
		(
			_value == 0 || dataStorage.allowed(msg.sender, _spender) == 0,
			'Approve value is required to be zero or account has already been approved.'
		);
		
		dataStorage.setAllowance(msg.sender, _spender, _value);
		
		emit Approval(msg.sender, _spender, _value);
		
		return true;
	}

	 
	function increaseApproval(address _spender, uint256 _addedValue) public {
		dataStorage.increaseAllowance(msg.sender, _spender, _addedValue);
		
		emit Approval(msg.sender, _spender, dataStorage.allowed(msg.sender, _spender));
	}

	 
	function decreaseApproval(address _spender, uint256 _subtractedValue) public {		
		dataStorage.decreaseAllowance(msg.sender, _spender, _subtractedValue);
		
		emit Approval(msg.sender, _spender, dataStorage.allowed(msg.sender, _spender));
	}

	 
	function allowance(address _owner, address _spender) public view returns (uint256) {
		return dataStorage.allowed(_owner, _spender);
	}

	 
	function _transfer(address _from, address _to, uint256 _value) internal returns (bool success) {
		require(_to != address(0), 'Non-zero to-address required.');
		uint256 fromBalance = dataStorage.balances(_from);
		require(fromBalance >= _value, 'From-address has insufficient balance.');

		fromBalance = fromBalance.sub(_value);

		uint256 toBalance = dataStorage.balances(_to);
		toBalance = toBalance.add(_value);

		dataStorage.setBalance(_from, fromBalance);
		dataStorage.setBalance(_to, toBalance);

		ledger.addTransaction(_from, _to, _value);

		emit Transfer(_from, _to, _value);

		return true;
	}
}

 
contract MintableToken is ERC20Standard, Ownable {

	 
	uint104 public constant MINTING_HARDCAP = 1e30;

	 
	bool public mintingFinished = false;

	event Mint(address indexed _to, uint256 _amount);
	
	event MintFinished();

	modifier canMint() {
		require(!mintingFinished, 'Uninished minting required.');
		_;
	}

	 
	function mint(address _to, uint256 _amount) public onlyOwners canMint() {
		uint256 totalSupply = dataStorage.totalSupply();
		totalSupply = totalSupply.add(_amount);
		
		require(totalSupply <= MINTING_HARDCAP, 'Total supply of token in circulation must be below hardcap.');
		
		dataStorage.setTotalSupply(totalSupply);

		uint256 toBalance = dataStorage.balances(_to);
		toBalance = toBalance.add(_amount);
		dataStorage.setBalance(_to, toBalance);

		ledger.addTransaction(address(0), _to, _amount);

		emit Transfer(address(0), _to, _amount);

		emit Mint(_to, _amount);
	}

	 
	function finishMinting() public onlyOwners {
		mintingFinished = true;
		emit MintFinished();
	}
}

 
contract BurnableToken is ERC20Standard {

	event Burn(address indexed _burner, uint256 _value);
	
	 
	function burn(uint256 _value) public {
		uint256 senderBalance = dataStorage.balances(msg.sender);
		require(senderBalance >= _value, 'Burn value less than account balance required.');
		senderBalance = senderBalance.sub(_value);
		dataStorage.setBalance(msg.sender, senderBalance);

		uint256 totalSupply = dataStorage.totalSupply();
		totalSupply = totalSupply.sub(_value);
		dataStorage.setTotalSupply(totalSupply);

		emit Burn(msg.sender, _value);

		emit Transfer(msg.sender, address(0), _value);
	}

	 
	function burnFrom(address _from, uint256 _value) public {
		uint256 fromBalance = dataStorage.balances(_from);
		require(fromBalance >= _value, 'Burn value less than from-account balance required.');

		uint256 allowed = dataStorage.allowed(_from, msg.sender);
		require(allowed >= _value, 'Burn value less than account allowance required.');

		fromBalance = fromBalance.sub(_value);
		dataStorage.setBalance(_from, fromBalance);

		allowed = allowed.sub(_value);
		dataStorage.setAllowance(_from, msg.sender, allowed);

		uint256 totalSupply = dataStorage.totalSupply();
		totalSupply = totalSupply.sub(_value);
		dataStorage.setTotalSupply(totalSupply);

		emit Burn(_from, _value);

		emit Transfer(_from, address(0), _value);
	}
}

 
contract PausableToken is ERC20Standard, Pausable {
	
	function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
		return super.transfer(_to, _value);
	}

	function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
		return super.transferFrom(_from, _to, _value);
	}

	function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
		return super.approve(_spender, _value);
	}
}

 
contract FreezableToken is ERC20Standard, Ownable {

	event FrozenFunds(address indexed _target, bool _isFrozen);

	  
	function freezeAccount(address _target, bool _isFrozen) public onlyOwners {
		require(_target != address(0), 'Non-zero to-be-frozen-account address required.');
		dataStorage.setFrozenAccount(_target, _isFrozen);
		emit FrozenFunds(_target, _isFrozen);
	}

	 
	function isAccountFrozen(address _target) public view returns (bool isFrozen) {
		return dataStorage.frozenAccounts(_target);
	}

	 
	function _transfer(address _from, address _to, uint256 _value) internal returns (bool success) {
		assert(!dataStorage.frozenAccounts(_from));

		assert(!dataStorage.frozenAccounts(_to));
		
		return super._transfer(_from, _to, _value);
	}
}

 
contract ERC20Extended is FreezableToken, PausableToken, BurnableToken, MintableToken, Destroyable {
	 
	string public constant name = 'ORBISE10';

	 
	string public constant symbol = 'ORBT';

	 
	uint8 public constant decimals = 18;

	 
	uint72 public constant MINIMUM_BUY_AMOUNT = 200e18;

	 
	uint256 public sellPrice;

	 
	uint256 public buyPrice;

	 
	address public wallet;

	 
	constructor
	(
		address _dataStorage,
		address _ledger,
		address _whitelist
	)
		ERC20Standard(_dataStorage, _ledger, _whitelist)
		public 
	{
	}

	 
	function() public payable { }

	 
	function setPrices(uint256 _sellPrice, uint256 _buyPrice) public onlyBotsOrOwners {
		sellPrice = _sellPrice;
		buyPrice = _buyPrice;
	}

	 
	function setWallet(address _walletAddress) public onlyOwners {
		require(_walletAddress != address(0), 'Non-zero wallet address required.');
		wallet = _walletAddress;
	}

	 
	function buy() public payable whenNotPaused isWhitelisted(msg.sender) {
		uint256 amount = msg.value.mul(1e18);
		
		amount = amount.div(sellPrice);

		require(amount >= MINIMUM_BUY_AMOUNT, "Buy amount too small");
		
		_transfer(this, msg.sender, amount);
	}
	
	 
	function sell(uint256 _amount) public whenNotPaused {
		uint256 toBeTransferred = _amount.mul(buyPrice);

		require(toBeTransferred >= 1e18, "Sell amount too small");

		toBeTransferred = toBeTransferred.div(1e18);

		require(address(this).balance >= toBeTransferred, 'Contract has insufficient balance.');
		_transfer(msg.sender, this, _amount);
		
		msg.sender.transfer(toBeTransferred);
	}

	 
	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}

	 
	function withdraw(uint256 _amount) public onlyOwners {
		require(address(this).balance >= _amount, 'Unable to withdraw specified amount.');
		require(wallet != address(0), 'Non-zero wallet address required.');
		wallet.transfer(_amount);
	}

	 
	function nonEtherPurchaseTransfer(address _to, uint256 _value) public isWhitelisted(_to) onlyBots whenNotPaused returns (bool success) {
		return _transfer(msg.sender, _to, _value);
	}
}