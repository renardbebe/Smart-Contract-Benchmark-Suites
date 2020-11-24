 

pragma solidity ^0.4.19;


contract SafeMath {

	function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a && c >= b);
		return c;
	}

	function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a * b;
		assert(a == 0 || c / a == b);
		return c;
	}

	function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b > 0);
		uint256 c = a / b;
		assert(a == b * c + a % b);
		return c;
	}
}


contract ERC20Token {

	 
	 
	 

	 
	 
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	 
	 
	 

	 
	function totalSupply() public constant returns (uint256 _totalSupply);

	 
	 
	 
	function balanceOf(address _owner) public constant returns (uint256 balance);

	 
	 
	 
	function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

	 
	 
	 

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success);

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

	 
	 
	 
	 
	 
	function approve(address _spender, uint256 _value) public returns (bool success);
}


contract SecureERC20Token is ERC20Token {

	 

	 
	mapping (address => uint256) private balances;

	 
	mapping (address => bool) private lockedAccounts;

	  
	mapping (address => mapping(address => uint256)) private allowed;

	 
	string public name;

	 
	string public symbol;

	 
	uint8 public decimals;

	 
	uint256 public totalSupply;

	 
	uint8 public version = 1;

	 
	address public admin;

	 
	address public minter;

	 
	uint256 public creationBlock;

	 
	 
	bool public isTransferEnabled;

	event AdminOwnershipTransferred(address indexed previousAdmin, address indexed newAdmin);
	event MinterOwnershipTransferred(address indexed previousMinter, address indexed newMinter);
	event TransferStatus(address indexed sender, bool status);

	 
	function SecureERC20Token(
		uint256 initialSupply,
		string _name,
		string _symbol,
		uint8 _decimals,
		bool _isTransferEnabled
	) public {
		 
		balances[msg.sender] = initialSupply;

		totalSupply = initialSupply;  
		name = _name;				  
		decimals = _decimals;		  
		symbol = _symbol;			  
		isTransferEnabled = _isTransferEnabled;
		creationBlock = block.number;
		minter = msg.sender;		 
		admin = msg.sender;			 
	}

	 
	 
	 

	 
	function totalSupply() public constant returns (uint256 _totalSupply) {
		return totalSupply;
	}

	 
	 
	 
	function balanceOf(address _owner) public constant returns (uint256 balance) {
		return balances[_owner];
	}

	 
	 
	 
	 
	function transfer(address _to, uint256 _value) public returns (bool success) {
		 
		require(isTransferEnabled);

		 
		return doTransfer(msg.sender, _to, _value);
	}

	 
	 
	 
	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
		 
		require(isTransferEnabled);

		 
		if (allowed[_from][msg.sender] < _value) revert();

		 
		allowed[_from][msg.sender] -= _value;

		 
		return doTransfer(_from, _to, _value);
	}

	 
	 
	 
	 
	function approve(address _spender, uint256 _value)
	public
	is_not_locked(_spender)
	returns (bool success) {
		 
		require(isTransferEnabled);

		 
		 
		 
		 
		if(_value != 0 && allowed[msg.sender][_spender] != 0) revert();

		if (
			 
			balances[msg.sender] < _value
		) {
			 
			return false;
		}

		 
		allowed[msg.sender][_spender] = _value;

		 
		Approval(msg.sender, _spender, _value);

		 
		return true;
	}

	 
	 
	 
	function allowance(address _owner, address _spender)
	public
	constant
	returns (uint256 remaining) {
		return allowed[_owner][_spender];
	}

	 
	 
	 

	 

	 
	 
	function lockAccount(address _owner)
	public
	is_not_locked(_owner)
	validate_address(_owner)
	onlyAdmin {
		lockedAccounts[_owner] = true;
	}

	 
	 
	function unlockAccount(address _owner)
	public
	is_locked(_owner)
	validate_address(_owner)
	onlyAdmin {
		lockedAccounts[_owner] = false;
	}

	 
	 
	function burnUserTokens(address _owner)
	public
	validate_address(_owner)
	onlyAdmin {
		 
		if (balances[_owner] == 0) revert();

		 
		if (balances[_owner] > totalSupply) revert();

		 
		totalSupply -= balances[_owner];

		 
		balances[_owner] = 0;
	}

	 
	 
	function changeMinter(address newMinter)
	public
	validate_address(newMinter)
	onlyAdmin {
		if (minter == newMinter) revert();
		MinterOwnershipTransferred(minter, newMinter);
		minter = newMinter;
	}

	 
	 
	function changeAdmin(address newAdmin)
	public
	validate_address(newAdmin)
	onlyAdmin {
		if (admin == newAdmin) revert();
		AdminOwnershipTransferred(admin, newAdmin);
		admin = newAdmin;
	}

	 
	 
	 
	function mint(address _owner, uint256 _amount)
	public
	onlyMinter
	validate_address(_owner)
	returns (bool success) {
		 
		if (totalSupply + _amount < totalSupply) revert();

		 
		if (balances[_owner] + _amount < balances[_owner]) revert();

		 
		totalSupply += _amount;

		 
		balances[_owner] += _amount;

		 
		Transfer(0x0, msg.sender, _amount);

		 
		Transfer(msg.sender, _owner, _amount);

		return true;
	}

	 
	 
	 
	 
	function enableTransfers(bool _isTransferEnabled) public onlyAdmin {
		isTransferEnabled = _isTransferEnabled;
		TransferStatus(msg.sender, isTransferEnabled);
	}

	 

	 
	 
	 
	 
	 
	function doTransfer(address _from, address _to, uint256 _value)
	validate_address(_to)
	is_not_locked(_from)
	internal
	returns (bool success) {
		if (
			 
			_value <= 0 ||
			 
			balances[_from] < _value ||
			 
			balances[_to] + _value < balances[_to]
		) {
			 
			return false;
		}

		 
		balances[_from] -= _value;

		 
		balances[_to] += _value;

		 
		Transfer(_from, _to, _value);

		 
		return true;
	}

	 
	 
	 
	modifier onlyMinter() {
		 
		if (msg.sender != minter) revert();
		 
		_;
	}

	modifier onlyAdmin() {
		 
		if (msg.sender != admin) revert();
		 
		_;
	}

	modifier validate_address(address _address) {
		if (_address == address(0)) revert();
		_;
	}

	modifier is_not_locked(address _address) {
		if (lockedAccounts[_address] == true) revert();
		_;
	}

	modifier is_locked(address _address) {
		if (lockedAccounts[_address] != true) revert();
		_;
	}
}


contract GilgameshToken is SecureERC20Token {
	 
	function GilgameshToken()
	public
	SecureERC20Token(
		0,  
		"Gilgamesh Token",  
		"GIL",  
		18,  
		false  
	) {}

}


 
contract GilgameshTokenSale is SafeMath{

	 
	uint256 public creationBlock;

	 
	uint256 public startBlock;

	 
	 
	uint256 public endBlock;

	 
	uint256 public totalRaised = 0;

	 
	bool public saleStopped = false;

	 
	bool public saleFinalized = false;

	 
	uint256 constant public minimumInvestment = 100 finney;

	 
	uint256 public hardCap = 50000 ether;

	 
	uint256 public tokenCap = 60000000 * 10**18;

	 
	uint256 public minimumCap = 1250 ether;

	 

	 
	address public fundOwnerWallet;

	 
	address public tokenOwnerWallet;

	 
	address public owner;

	 
	 
	uint[] public stageBonusPercentage;

	 
	uint256 public totalParticipants;

	 
	mapping(uint256 => uint256) public paymentsByUserId;

	 
	mapping(address => uint256) public paymentsByAddress;

	 
	uint8 public totalStages;

	 
	uint8 public stageMaxBonusPercentage;

	 
	uint256 public tokenPrice;

	 
	uint8 public teamTokenRatio = 3;

	 
	GilgameshToken public token;

	 
	bool public isCapReached = false;

	 
	event LogTokenSaleInitialized(
		address indexed owner,
		address indexed fundOwnerWallet,
		uint256 startBlock,
		uint256 endBlock,
		uint256 creationBlock
	);

	 
	event LogContribution(
		address indexed contributorAddress,
		address indexed invokerAddress,
		uint256 amount,
		uint256 totalRaised,
		uint256 userAssignedTokens,
		uint256 indexed userId
	);

	 
	event LogFinalized(address owner, uint256 teamTokens);

	 
	function GilgameshTokenSale(
		uint256 _startBlock,  
		uint256 _endBlock,  
		address _fundOwnerWallet,  
		address _tokenOwnerWallet,  
		uint8 _totalStages,  
		uint8 _stageMaxBonusPercentage,  
		uint256 _tokenPrice,  
		address _gilgameshToken,  
		uint256 _minimumCap,  
		uint256 _tokenCap  
	)
	public
	validate_address(_fundOwnerWallet) {

		if (
			_gilgameshToken == 0x0 ||
			_tokenOwnerWallet == 0x0 ||
			 
			_startBlock < getBlockNumber()  ||
			 
			_startBlock >= _endBlock  ||
			 
			_totalStages < 2 ||
			 
			_stageMaxBonusPercentage < 0  ||
			_stageMaxBonusPercentage > 100 ||
			 
			_stageMaxBonusPercentage % (_totalStages - 1) != 0 ||
			 
			(_endBlock - _startBlock) % _totalStages != 0
		) revert();

		owner = msg.sender;  
		token = GilgameshToken(_gilgameshToken);
		endBlock = _endBlock;
		startBlock = _startBlock;
		creationBlock = getBlockNumber();
		fundOwnerWallet = _fundOwnerWallet;
		tokenOwnerWallet = _tokenOwnerWallet;
		tokenPrice = _tokenPrice;
		totalStages = _totalStages;
		minimumCap = _minimumCap;
		stageMaxBonusPercentage = _stageMaxBonusPercentage;
		totalRaised = 0;  
		tokenCap = _tokenCap;

		 
		uint spread = stageMaxBonusPercentage / (totalStages - 1);

		 
		for (uint stageNumber = totalStages; stageNumber > 0; stageNumber--) {
			stageBonusPercentage.push((stageNumber - 1) * spread);
		}

		LogTokenSaleInitialized(
			owner,
			fundOwnerWallet,
			startBlock,
			endBlock,
			creationBlock
		);
	}

	 
	 
	 

	 
	 
	function emergencyStopSale()
	public
	only_sale_active
	onlyOwner {
		saleStopped = true;
	}

	 
	 
	 
	function restartSale()
	public
	only_during_sale_period
	only_sale_stopped
	onlyOwner {
		 
		if (saleFinalized) revert();
		saleStopped = false;
	}

	 
	 
	function changeFundOwnerWalletAddress(address _fundOwnerWallet)
	public
	validate_address(_fundOwnerWallet)
	onlyOwner {
		fundOwnerWallet = _fundOwnerWallet;
	}

	 
	 
	function changeTokenOwnerWalletAddress(address _tokenOwnerWallet)
	public
	validate_address(_tokenOwnerWallet)
	onlyOwner {
		tokenOwnerWallet = _tokenOwnerWallet;
	}

	 
	 
	function finalizeSale()
	public
	onlyOwner {
		doFinalizeSale();
	}

	 
	function changeCap(uint256 _cap)
	public
	onlyOwner {
		if (_cap < minimumCap) revert();
		if (_cap <= totalRaised) revert();

		hardCap = _cap;

		if (totalRaised + minimumInvestment >= hardCap) {
			isCapReached = true;
			doFinalizeSale();
		}
	}

	 
	function changeMinimumCap(uint256 _cap)
	public
	onlyOwner {
		if (minimumCap < _cap) revert();
		minimumCap = _cap;
	}

	 
	 
	 
	function removeContract()
	public
	onlyOwner {
		if (!saleFinalized) revert();
		selfdestruct(msg.sender);
	}

	 
	 
	function changeOwner(address _newOwner)
	public
	validate_address(_newOwner)
	onlyOwner {
		require(_newOwner != owner);
		owner = _newOwner;
	}

	 
	 
	 
	 
	 

	 
	 
	function depositForMySelf(uint256 userId)
	public
	only_sale_active
	minimum_contribution()
	payable {
		deposit(userId, msg.sender);
	}

	 
	 
	function deposit(uint256 userId, address userAddress)
	public
	payable
	only_sale_active
	minimum_contribution()
	validate_address(userAddress) {
		 
		if (totalRaised + msg.value > hardCap) revert();

		uint256 userAssignedTokens = calculateTokens(msg.value);

		 
		if (userAssignedTokens <= 0) revert();

		 
		if (token.totalSupply() + userAssignedTokens > tokenCap) revert();

		 
		if (!fundOwnerWallet.send(msg.value)) revert();

		 
		if (!token.mint(userAddress, userAssignedTokens)) revert();

		 
		totalRaised = safeAdd(totalRaised, msg.value);

		 
		if (totalRaised >= hardCap) {
			isCapReached = true;
		}

		 
		if (token.totalSupply() >= tokenCap) {
			isCapReached = true;
		}

		 
		if (paymentsByUserId[userId] == 0) {
			totalParticipants++;
		}

		 
		paymentsByUserId[userId] += msg.value;

		 
		paymentsByAddress[userAddress] += msg.value;

		 
		LogContribution(
			userAddress,
			msg.sender,
			msg.value,
			totalRaised,
			userAssignedTokens,
			userId
		);
	}

	 
	 
	function calculateTokens(uint256 amount)
	public
	view
	returns (uint256) {
		 
		if (!isDuringSalePeriod(getBlockNumber())) return 0;

		 
		uint8 currentStage = getStageByBlockNumber(getBlockNumber());

		 
		if (currentStage > totalStages) return 0;

		 
		uint256 purchasedTokens = safeMul(amount, tokenPrice);
		 
		uint256 rewardedTokens = calculateRewardTokens(purchasedTokens, currentStage);
		 
		return safeAdd(purchasedTokens, rewardedTokens);
	}

	 
	 
	 
	function calculateRewardTokens(uint256 amount, uint8 stageNumber)
	public
	view
	returns (uint256 rewardAmount) {
		 
		if (
			stageNumber < 1 ||
			stageNumber > totalStages
		) revert();

		 
		uint8 stageIndex = stageNumber - 1;

		 
		return safeDiv(safeMul(amount, stageBonusPercentage[stageIndex]), 100);
	}

	 
	 
	function getStageByBlockNumber(uint256 _blockNumber)
	public
	view
	returns (uint8) {
		 
		if (!isDuringSalePeriod(_blockNumber)) revert();

		uint256 totalBlocks = safeSub(endBlock, startBlock);
		uint256 numOfBlockPassed = safeSub(_blockNumber, startBlock);

		 
		return uint8(safeDiv(safeMul(totalStages, numOfBlockPassed), totalBlocks) + 1);
	}

	 
	 
	 

	 
	 
	function isDuringSalePeriod(uint256 _blockNumber)
	view
	internal
	returns (bool) {
		return (_blockNumber >= startBlock && _blockNumber < endBlock);
	}

	 
	 
	function doFinalizeSale()
	internal
	onlyOwner {

		if (saleFinalized) revert();

		 
		uint256 teamTokens = safeMul(token.totalSupply(), teamTokenRatio);

		if (teamTokens > 0){
			 
			if (!token.mint(tokenOwnerWallet, teamTokens)) revert();
		}

		 
		if(this.balance > 0) {
			 
			if (!fundOwnerWallet.send(this.balance)) revert();
		}

		 
		saleFinalized = true;

		 
		saleStopped = true;

		 
		LogFinalized(tokenOwnerWallet, teamTokens);
	}

	 
	function getBlockNumber() constant internal returns (uint) {
		return block.number;
	}

	 
	 
	 

	 
	modifier only_sale_stopped {
		if (!saleStopped) revert();
		_;
	}


	 
	modifier validate_address(address _address) {
		if (_address == 0x0) revert();
		_;
	}

	 
	modifier only_during_sale_period {
		 
		if (getBlockNumber() < startBlock) revert();
		 
		if (getBlockNumber() >= endBlock) revert();
		 
		_;
	}

	 
	modifier only_sale_active {
		 
		if (saleFinalized) revert();
		 
		if (saleStopped) revert();
		 
		if (isCapReached) revert();
		 
		if (getBlockNumber() < startBlock) revert();
		 
		if (getBlockNumber() >= endBlock) revert();
		 
		_;
	}

	 
	modifier minimum_contribution() {
		if (msg.value < minimumInvestment) revert();
		_;
	}

	 
	modifier onlyOwner() {
		if (msg.sender != owner) revert();
		_;
	}
}