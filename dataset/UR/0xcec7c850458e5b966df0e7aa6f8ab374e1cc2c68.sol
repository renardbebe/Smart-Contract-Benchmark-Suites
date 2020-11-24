 

pragma solidity >=0.5.4 <0.6.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }


interface INameAccountRecovery {
	function isCompromised(address _id) external view returns (bool);
}


interface INamePublicKey {
	function initialize(address _id, address _defaultKey, address _writerKey) external returns (bool);

	function isKeyExist(address _id, address _key) external view returns (bool);

	function getDefaultKey(address _id) external view returns (address);

	function whitelistAddKey(address _id, address _key) external returns (bool);
}


interface INameTAOPosition {
	function senderIsAdvocate(address _sender, address _id) external view returns (bool);
	function senderIsListener(address _sender, address _id) external view returns (bool);
	function senderIsSpeaker(address _sender, address _id) external view returns (bool);
	function senderIsPosition(address _sender, address _id) external view returns (bool);
	function getAdvocate(address _id) external view returns (address);
	function nameIsAdvocate(address _nameId, address _id) external view returns (bool);
	function nameIsPosition(address _nameId, address _id) external view returns (bool);
	function initialize(address _id, address _advocateId, address _listenerId, address _speakerId) external returns (bool);
	function determinePosition(address _sender, address _id) external view returns (uint256);
}


contract TheAO {
	address public theAO;
	address public nameTAOPositionAddress;

	 
	 
	mapping (address => bool) public whitelist;

	constructor() public {
		theAO = msg.sender;
	}

	 
	modifier inWhitelist() {
		require (whitelist[msg.sender] == true);
		_;
	}

	 
	function transferOwnership(address _theAO) public {
		require (msg.sender == theAO);
		require (_theAO != address(0));
		theAO = _theAO;
	}

	 
	function setWhitelist(address _account, bool _whitelist) public {
		require (msg.sender == theAO);
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}
}


 
library SafeMath {

	 
	function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
		 
		 
		 
		if (a == 0) {
			return 0;
		}

		c = a * b;
		assert(c / a == b);
		return c;
	}

	 
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		 
		 
		 
		return a / b;
	}

	 
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(b <= a);
		return a - b;
	}

	 
	function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
		c = a + b;
		assert(c >= a);
		return c;
	}
}


interface IAOTreasury {
	function toBase(uint256 integerAmount, uint256 fractionAmount, bytes8 denominationName) external view returns (uint256);
	function isDenominationExist(bytes8 denominationName) external view returns (bool);
}













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

	 
	constructor (uint256 initialSupply, string memory tokenName, string memory tokenSymbol) public {
		totalSupply = initialSupply * 10 ** uint256(decimals);   
		balanceOf[msg.sender] = totalSupply;                 
		name = tokenName;                                    
		symbol = tokenSymbol;                                
	}

	 
	function _transfer(address _from, address _to, uint _value) internal {
		 
		require(_to != address(0));
		 
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

	 
	function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, address(this), _extraData);
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


 
contract TAO {
	using SafeMath for uint256;

	address public vaultAddress;
	string public name;				 
	address public originId;		 

	 
	string public datHash;
	string public database;
	string public keyValue;
	bytes32 public contentId;

	 
	uint8 public typeId;

	 
	constructor (string memory _name,
		address _originId,
		string memory _datHash,
		string memory _database,
		string memory _keyValue,
		bytes32 _contentId,
		address _vaultAddress
	) public {
		name = _name;
		originId = _originId;
		datHash = _datHash;
		database = _database;
		keyValue = _keyValue;
		contentId = _contentId;

		 
		typeId = 0;

		vaultAddress = _vaultAddress;
	}

	 
	modifier onlyVault {
		require (msg.sender == vaultAddress);
		_;
	}

	 
	function () external payable {
	}

	 
	function transferEth(address payable _recipient, uint256 _amount) public onlyVault returns (bool) {
		_recipient.transfer(_amount);
		return true;
	}

	 
	function transferERC20(address _erc20TokenAddress, address _recipient, uint256 _amount) public onlyVault returns (bool) {
		TokenERC20 _erc20 = TokenERC20(_erc20TokenAddress);
		_erc20.transfer(_recipient, _amount);
		return true;
	}
}




 
contract Name is TAO {
	 
	constructor (string memory _name, address _originId, string memory _datHash, string memory _database, string memory _keyValue, bytes32 _contentId, address _vaultAddress)
		TAO (_name, _originId, _datHash, _database, _keyValue, _contentId, _vaultAddress) public {
		 
		typeId = 1;
	}
}




 
library AOLibrary {
	using SafeMath for uint256;

	uint256 constant private _MULTIPLIER_DIVISOR = 10 ** 6;  
	uint256 constant private _PERCENTAGE_DIVISOR = 10 ** 6;  

	 
	function isTAO(address _taoId) public view returns (bool) {
		return (_taoId != address(0) && bytes(TAO(address(uint160(_taoId))).name()).length > 0 && TAO(address(uint160(_taoId))).originId() != address(0) && TAO(address(uint160(_taoId))).typeId() == 0);
	}

	 
	function isName(address _nameId) public view returns (bool) {
		return (_nameId != address(0) && bytes(TAO(address(uint160(_nameId))).name()).length > 0 && Name(address(uint160(_nameId))).originId() != address(0) && Name(address(uint160(_nameId))).typeId() == 1);
	}

	 
	function isValidERC20TokenAddress(address _tokenAddress) public view returns (bool) {
		if (_tokenAddress == address(0)) {
			return false;
		}
		TokenERC20 _erc20 = TokenERC20(_tokenAddress);
		return (_erc20.totalSupply() >= 0 && bytes(_erc20.name()).length > 0 && bytes(_erc20.symbol()).length > 0);
	}

	 
	function isTheAO(address _sender, address _theAO, address _nameTAOPositionAddress) public view returns (bool) {
		return (_sender == _theAO ||
			(
				(isTAO(_theAO) || isName(_theAO)) &&
				_nameTAOPositionAddress != address(0) &&
				INameTAOPosition(_nameTAOPositionAddress).senderIsAdvocate(_sender, _theAO)
			)
		);
	}

	 
	function PERCENTAGE_DIVISOR() public pure returns (uint256) {
		return _PERCENTAGE_DIVISOR;
	}

	 
	function MULTIPLIER_DIVISOR() public pure returns (uint256) {
		return _MULTIPLIER_DIVISOR;
	}

	 
	function deployTAO(string memory _name,
		address _originId,
		string memory _datHash,
		string memory _database,
		string memory _keyValue,
		bytes32 _contentId,
		address _nameTAOVaultAddress
		) public returns (TAO _tao) {
		_tao = new TAO(_name, _originId, _datHash, _database, _keyValue, _contentId, _nameTAOVaultAddress);
	}

	 
	function deployName(string memory _name,
		address _originId,
		string memory _datHash,
		string memory _database,
		string memory _keyValue,
		bytes32 _contentId,
		address _nameTAOVaultAddress
		) public returns (Name _myName) {
		_myName = new Name(_name, _originId, _datHash, _database, _keyValue, _contentId, _nameTAOVaultAddress);
	}

	 
	function calculateWeightedMultiplier(uint256 _currentWeightedMultiplier, uint256 _currentPrimordialBalance, uint256 _additionalWeightedMultiplier, uint256 _additionalPrimordialAmount) public pure returns (uint256) {
		if (_currentWeightedMultiplier > 0) {
			uint256 _totalWeightedIons = (_currentWeightedMultiplier.mul(_currentPrimordialBalance)).add(_additionalWeightedMultiplier.mul(_additionalPrimordialAmount));
			uint256 _totalIons = _currentPrimordialBalance.add(_additionalPrimordialAmount);
			return _totalWeightedIons.div(_totalIons);
		} else {
			return _additionalWeightedMultiplier;
		}
	}

	 
	function calculatePrimordialMultiplier(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		if (_purchaseAmount > 0 && _purchaseAmount <= _totalPrimordialMintable.sub(_totalPrimordialMinted)) {
			 
			uint256 temp = _totalPrimordialMinted.add(_purchaseAmount.div(2));

			 
			uint256 multiplier = (_MULTIPLIER_DIVISOR.sub(_MULTIPLIER_DIVISOR.mul(temp).div(_totalPrimordialMintable))).mul(_startingMultiplier.sub(_endingMultiplier));
			 
			return multiplier.div(_MULTIPLIER_DIVISOR);
		} else {
			return 0;
		}
	}

	 
	function calculateNetworkBonusPercentage(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		if (_purchaseAmount > 0 && _purchaseAmount <= _totalPrimordialMintable.sub(_totalPrimordialMinted)) {
			 
			uint256 temp = _totalPrimordialMinted.add(_purchaseAmount.div(2));

			 
			uint256 bonusPercentage = (_PERCENTAGE_DIVISOR.sub(_PERCENTAGE_DIVISOR.mul(temp).div(_totalPrimordialMintable))).mul(_startingMultiplier.sub(_endingMultiplier)).div(_PERCENTAGE_DIVISOR);
			return bonusPercentage;
		} else {
			return 0;
		}
	}

	 
	function calculateNetworkBonusAmount(uint256 _purchaseAmount, uint256 _totalPrimordialMintable, uint256 _totalPrimordialMinted, uint256 _startingMultiplier, uint256 _endingMultiplier) public pure returns (uint256) {
		uint256 bonusPercentage = calculateNetworkBonusPercentage(_purchaseAmount, _totalPrimordialMintable, _totalPrimordialMinted, _startingMultiplier, _endingMultiplier);
		 
		uint256 networkBonus = bonusPercentage.mul(_purchaseAmount).div(_PERCENTAGE_DIVISOR);
		return networkBonus;
	}

	 
	function calculateMaximumBurnAmount(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _maximumMultiplier) public pure returns (uint256) {
		return (_maximumMultiplier.mul(_primordialBalance).sub(_primordialBalance.mul(_currentWeightedMultiplier))).div(_maximumMultiplier);
	}

	 
	function calculateMultiplierAfterBurn(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _amountToBurn) public pure returns (uint256) {
		return _primordialBalance.mul(_currentWeightedMultiplier).div(_primordialBalance.sub(_amountToBurn));
	}

	 
	function calculateMultiplierAfterConversion(uint256 _primordialBalance, uint256 _currentWeightedMultiplier, uint256 _amountToConvert) public pure returns (uint256) {
		return _primordialBalance.mul(_currentWeightedMultiplier).div(_primordialBalance.add(_amountToConvert));
	}

	 
	function numDigits(uint256 number) public pure returns (uint8) {
		uint8 digits = 0;
		while(number != 0) {
			number = number.div(10);
			digits++;
		}
		return digits;
	}
}












interface ionRecipient {
	function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external;
}

 
contract AOIonInterface is TheAO {
	using SafeMath for uint256;

	address public namePublicKeyAddress;
	address public nameAccountRecoveryAddress;

	INameTAOPosition internal _nameTAOPosition;
	INamePublicKey internal _namePublicKey;
	INameAccountRecovery internal _nameAccountRecovery;

	 
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public totalSupply;

	 
	uint256 public powerOfTen;

	 
	uint256 public sellPrice;
	uint256 public buyPrice;

	 
	mapping (address => uint256) public balanceOf;
	mapping (address => mapping (address => uint256)) public allowance;
	mapping (address => bool) public frozenAccount;
	mapping (address => uint256) public stakedBalance;
	mapping (address => uint256) public escrowedBalance;

	 
	event FrozenFunds(address target, bool frozen);
	event Stake(address indexed from, uint256 value);
	event Unstake(address indexed from, uint256 value);
	event Escrow(address indexed from, address indexed to, uint256 value);
	event Unescrow(address indexed from, uint256 value);

	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	event Approval(address indexed _owner, address indexed _spender, uint256 _value);

	 
	event Burn(address indexed from, uint256 value);

	 
	constructor(string memory _name, string memory _symbol, address _nameTAOPositionAddress, address _namePublicKeyAddress, address _nameAccountRecoveryAddress) public {
		setNameTAOPositionAddress(_nameTAOPositionAddress);
		setNamePublicKeyAddress(_namePublicKeyAddress);
		setNameAccountRecoveryAddress(_nameAccountRecoveryAddress);
		name = _name;            
		symbol = _symbol;        
		powerOfTen = 0;
		decimals = 0;
	}

	 
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	 
	 
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	 
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	 
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
		_nameTAOPosition = INameTAOPosition(nameTAOPositionAddress);
	}

	 
	function setNamePublicKeyAddress(address _namePublicKeyAddress) public onlyTheAO {
		require (_namePublicKeyAddress != address(0));
		namePublicKeyAddress = _namePublicKeyAddress;
		_namePublicKey = INamePublicKey(namePublicKeyAddress);
	}

	 
	function setNameAccountRecoveryAddress(address _nameAccountRecoveryAddress) public onlyTheAO {
		require (_nameAccountRecoveryAddress != address(0));
		nameAccountRecoveryAddress = _nameAccountRecoveryAddress;
		_nameAccountRecovery = INameAccountRecovery(nameAccountRecoveryAddress);
	}

	 
	function transferEth(address payable _recipient, uint256 _amount) public onlyTheAO {
		require (_recipient != address(0));
		_recipient.transfer(_amount);
	}

	 
	function freezeAccount(address target, bool freeze) public onlyTheAO {
		frozenAccount[target] = freeze;
		emit FrozenFunds(target, freeze);
	}

	 
	function setPrices(uint256 newSellPrice, uint256 newBuyPrice) public onlyTheAO {
		sellPrice = newSellPrice;
		buyPrice = newBuyPrice;
	}

	 
	 
	function mint(address target, uint256 mintedAmount) public inWhitelist returns (bool) {
		_mint(target, mintedAmount);
		return true;
	}

	 
	function stakeFrom(address _from, uint256 _value) public inWhitelist returns (bool) {
		require (balanceOf[_from] >= _value);						 
		balanceOf[_from] = balanceOf[_from].sub(_value);			 
		stakedBalance[_from] = stakedBalance[_from].add(_value);	 
		emit Stake(_from, _value);
		return true;
	}

	 
	function unstakeFrom(address _from, uint256 _value) public inWhitelist returns (bool) {
		require (stakedBalance[_from] >= _value);					 
		stakedBalance[_from] = stakedBalance[_from].sub(_value);	 
		balanceOf[_from] = balanceOf[_from].add(_value);			 
		emit Unstake(_from, _value);
		return true;
	}

	 
	function escrowFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool) {
		require (balanceOf[_from] >= _value);						 
		balanceOf[_from] = balanceOf[_from].sub(_value);			 
		escrowedBalance[_to] = escrowedBalance[_to].add(_value);	 
		emit Escrow(_from, _to, _value);
		return true;
	}

	 
	function mintEscrow(address target, uint256 mintedAmount) public inWhitelist returns (bool) {
		escrowedBalance[target] = escrowedBalance[target].add(mintedAmount);
		totalSupply = totalSupply.add(mintedAmount);
		emit Escrow(address(this), target, mintedAmount);
		return true;
	}

	 
	function unescrowFrom(address _from, uint256 _value) public inWhitelist returns (bool) {
		require (escrowedBalance[_from] >= _value);						 
		escrowedBalance[_from] = escrowedBalance[_from].sub(_value);	 
		balanceOf[_from] = balanceOf[_from].add(_value);				 
		emit Unescrow(_from, _value);
		return true;
	}

	 
	function whitelistBurnFrom(address _from, uint256 _value) public inWhitelist returns (bool success) {
		require(balanceOf[_from] >= _value);                 
		balanceOf[_from] = balanceOf[_from].sub(_value);     
		totalSupply = totalSupply.sub(_value);               
		emit Burn(_from, _value);
		return true;
	}

	 
	function whitelistTransferFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool success) {
		_transfer(_from, _to, _value);
		return true;
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

	 
	function transferBetweenPublicKeys(address _nameId, address _from, address _to, uint256 _value) public returns (bool success) {
		require (AOLibrary.isName(_nameId));
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _nameId));
		require (!_nameAccountRecovery.isCompromised(_nameId));
		 
		require (_namePublicKey.isKeyExist(_nameId, _from));
		 
		require (_namePublicKey.isKeyExist(_nameId, _to));
		_transfer(_from, _to, _value);
		return true;
	}

	 
	function approve(address _spender, uint256 _value) public returns (bool success) {
		allowance[msg.sender][_spender] = _value;
		emit Approval(msg.sender, _spender, _value);
		return true;
	}

	 
	function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
		ionRecipient spender = ionRecipient(_spender);
		if (approve(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, address(this), _extraData);
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

	 
	function buy() public payable {
		require (buyPrice > 0);
		uint256 amount = msg.value.div(buyPrice);
		_transfer(address(this), msg.sender, amount);
	}

	 
	function sell(uint256 amount) public {
		require (sellPrice > 0);
		address myAddress = address(this);
		require (myAddress.balance >= amount.mul(sellPrice));
		_transfer(msg.sender, address(this), amount);
		msg.sender.transfer(amount.mul(sellPrice));
	}

	 
	 
	function _transfer(address _from, address _to, uint256 _value) internal {
		require (_to != address(0));							 
		require (balanceOf[_from] >= _value);					 
		require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
		require (!frozenAccount[_from]);						 
		require (!frozenAccount[_to]);							 
		uint256 previousBalances = balanceOf[_from].add(balanceOf[_to]);
		balanceOf[_from] = balanceOf[_from].sub(_value);         
		balanceOf[_to] = balanceOf[_to].add(_value);             
		emit Transfer(_from, _to, _value);
		assert(balanceOf[_from].add(balanceOf[_to]) == previousBalances);
	}

	 
	function _mint(address target, uint256 mintedAmount) internal {
		balanceOf[target] = balanceOf[target].add(mintedAmount);
		totalSupply = totalSupply.add(mintedAmount);
		emit Transfer(address(0), address(this), mintedAmount);
		emit Transfer(address(this), target, mintedAmount);
	}
}


 
contract AOTreasury is TheAO, IAOTreasury {
	using SafeMath for uint256;

	uint256 public totalDenominations;
	uint256 public totalDenominationExchanges;

	struct Denomination {
		bytes8 name;
		address denominationAddress;
	}

	struct DenominationExchange {
		bytes32 exchangeId;
		address sender;			 
		address fromDenominationAddress;	 
		address toDenominationAddress;		 
		uint256 amount;
	}

	 
	 
	 
	mapping (uint256 => Denomination) internal denominations;

	 
	mapping (bytes8 => uint256) internal denominationIndex;

	 
	mapping (uint256 => DenominationExchange) internal denominationExchanges;
	mapping (bytes32 => uint256) internal denominationExchangeIdLookup;

	 
	event ExchangeDenomination(address indexed account, bytes32 indexed exchangeId, uint256 amount, address fromDenominationAddress, string fromDenominationSymbol, address toDenominationAddress, string toDenominationSymbol);

	 
	constructor(address _nameTAOPositionAddress) public {
		setNameTAOPositionAddress(_nameTAOPositionAddress);
	}

	 
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	 
	modifier isValidDenomination(bytes8 denominationName) {
		require (this.isDenominationExist(denominationName));
		_;
	}

	 
	 
	function transferOwnership(address _theAO) public onlyTheAO {
		require (_theAO != address(0));
		theAO = _theAO;
	}

	 
	function setWhitelist(address _account, bool _whitelist) public onlyTheAO {
		require (_account != address(0));
		whitelist[_account] = _whitelist;
	}

	 
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	 
	function addDenomination(bytes8 denominationName, address denominationAddress) public onlyTheAO returns (bool) {
		require (denominationName.length > 0);
		require (denominationName[0] != 0);
		require (denominationAddress != address(0));
		require (denominationIndex[denominationName] == 0);
		totalDenominations++;
		 
		if (totalDenominations > 1) {
			AOIonInterface _lastDenominationIon = AOIonInterface(denominations[totalDenominations - 1].denominationAddress);
			AOIonInterface _newDenominationIon = AOIonInterface(denominationAddress);
			require (_newDenominationIon.powerOfTen() > _lastDenominationIon.powerOfTen());
		}
		denominations[totalDenominations].name = denominationName;
		denominations[totalDenominations].denominationAddress = denominationAddress;
		denominationIndex[denominationName] = totalDenominations;
		return true;
	}

	 
	function updateDenomination(bytes8 denominationName, address denominationAddress) public onlyTheAO isValidDenomination(denominationName) returns (bool) {
		require (denominationAddress != address(0));
		uint256 _denominationNameIndex = denominationIndex[denominationName];
		AOIonInterface _newDenominationIon = AOIonInterface(denominationAddress);
		if (_denominationNameIndex > 1) {
			AOIonInterface _prevDenominationIon = AOIonInterface(denominations[_denominationNameIndex - 1].denominationAddress);
			require (_newDenominationIon.powerOfTen() > _prevDenominationIon.powerOfTen());
		}
		if (_denominationNameIndex < totalDenominations) {
			AOIonInterface _lastDenominationIon = AOIonInterface(denominations[totalDenominations].denominationAddress);
			require (_newDenominationIon.powerOfTen() < _lastDenominationIon.powerOfTen());
		}
		denominations[denominationIndex[denominationName]].denominationAddress = denominationAddress;
		return true;
	}

	 
	 
	function isDenominationExist(bytes8 denominationName) external view returns (bool) {
		return (denominationName.length > 0 &&
			denominationName[0] != 0 &&
			denominationIndex[denominationName] > 0 &&
			denominations[denominationIndex[denominationName]].denominationAddress != address(0)
	   );
	}

	 
	function getDenominationByName(bytes8 denominationName) public isValidDenomination(denominationName) view returns (bytes8, address, string memory, string memory, uint8, uint256) {
		AOIonInterface _ao = AOIonInterface(denominations[denominationIndex[denominationName]].denominationAddress);
		return (
			denominations[denominationIndex[denominationName]].name,
			denominations[denominationIndex[denominationName]].denominationAddress,
			_ao.name(),
			_ao.symbol(),
			_ao.decimals(),
			_ao.powerOfTen()
		);
	}

	 
	function getDenominationByIndex(uint256 index) public view returns (bytes8, address, string memory, string memory, uint8, uint256) {
		require (index > 0 && index <= totalDenominations);
		require (denominations[index].denominationAddress != address(0));
		AOIonInterface _ao = AOIonInterface(denominations[index].denominationAddress);
		return (
			denominations[index].name,
			denominations[index].denominationAddress,
			_ao.name(),
			_ao.symbol(),
			_ao.decimals(),
			_ao.powerOfTen()
		);
	}

	 
	function getBaseDenomination() public view returns (bytes8, address, string memory, string memory, uint8, uint256) {
		require (totalDenominations > 0);
		return getDenominationByIndex(1);
	}

	 
	function toBase(uint256 integerAmount, uint256 fractionAmount, bytes8 denominationName) external view returns (uint256) {
		uint256 _fractionAmount = fractionAmount;
		if (this.isDenominationExist(denominationName) && (integerAmount > 0 || _fractionAmount > 0)) {
			Denomination memory _denomination = denominations[denominationIndex[denominationName]];
			AOIonInterface _denominationIon = AOIonInterface(_denomination.denominationAddress);
			uint8 fractionNumDigits = AOLibrary.numDigits(_fractionAmount);
			require (fractionNumDigits <= _denominationIon.decimals());
			uint256 baseInteger = integerAmount.mul(10 ** _denominationIon.powerOfTen());
			if (_denominationIon.decimals() == 0) {
				_fractionAmount = 0;
			}
			return baseInteger.add(_fractionAmount);
		} else {
			return 0;
		}
	}

	 
	function fromBase(uint256 integerAmount, bytes8 denominationName) public view returns (uint256, uint256) {
		if (this.isDenominationExist(denominationName)) {
			Denomination memory _denomination = denominations[denominationIndex[denominationName]];
			AOIonInterface _denominationIon = AOIonInterface(_denomination.denominationAddress);
			uint256 denominationInteger = integerAmount.div(10 ** _denominationIon.powerOfTen());
			uint256 denominationFraction = integerAmount.sub(denominationInteger.mul(10 ** _denominationIon.powerOfTen()));
			return (denominationInteger, denominationFraction);
		} else {
			return (0, 0);
		}
	}

	 
	function exchangeDenomination(uint256 amount, bytes8 fromDenominationName, bytes8 toDenominationName) public isValidDenomination(fromDenominationName) isValidDenomination(toDenominationName) {
		require (amount > 0);
		Denomination memory _fromDenomination = denominations[denominationIndex[fromDenominationName]];
		Denomination memory _toDenomination = denominations[denominationIndex[toDenominationName]];
		AOIonInterface _fromDenominationIon = AOIonInterface(_fromDenomination.denominationAddress);
		AOIonInterface _toDenominationIon = AOIonInterface(_toDenomination.denominationAddress);
		require (_fromDenominationIon.whitelistBurnFrom(msg.sender, amount));
		require (_toDenominationIon.mint(msg.sender, amount));

		 
		totalDenominationExchanges++;
		bytes32 _exchangeId = keccak256(abi.encodePacked(this, msg.sender, totalDenominationExchanges));
		denominationExchangeIdLookup[_exchangeId] = totalDenominationExchanges;

		DenominationExchange storage _denominationExchange = denominationExchanges[totalDenominationExchanges];
		_denominationExchange.exchangeId = _exchangeId;
		_denominationExchange.sender = msg.sender;
		_denominationExchange.fromDenominationAddress = _fromDenomination.denominationAddress;
		_denominationExchange.toDenominationAddress = _toDenomination.denominationAddress;
		_denominationExchange.amount = amount;

		emit ExchangeDenomination(msg.sender, _exchangeId, amount, _fromDenomination.denominationAddress, AOIonInterface(_fromDenomination.denominationAddress).symbol(), _toDenomination.denominationAddress, AOIonInterface(_toDenomination.denominationAddress).symbol());
	}

	 
	function getDenominationExchangeById(bytes32 _exchangeId) public view returns (address, address, address, string memory, string memory, uint256) {
		require (denominationExchangeIdLookup[_exchangeId] > 0);
		DenominationExchange memory _denominationExchange = denominationExchanges[denominationExchangeIdLookup[_exchangeId]];
		return (
			_denominationExchange.sender,
			_denominationExchange.fromDenominationAddress,
			_denominationExchange.toDenominationAddress,
			AOIonInterface(_denominationExchange.fromDenominationAddress).symbol(),
			AOIonInterface(_denominationExchange.toDenominationAddress).symbol(),
			_denominationExchange.amount
		);
	}

	 
	function toHighestDenomination(uint256 amount) public view returns (bytes8, address, uint256, uint256, string memory, string memory, uint8, uint256) {
		uint256 integerAmount;
		uint256 fractionAmount;
		uint256 index;
		for (uint256 i=totalDenominations; i>0; i--) {
			Denomination memory _denomination = denominations[i];
			(integerAmount, fractionAmount) = fromBase(amount, _denomination.name);
			if (integerAmount > 0) {
				index = i;
				break;
			}
		}
		require (index > 0 && index <= totalDenominations);
		require (integerAmount > 0 || fractionAmount > 0);
		require (denominations[index].denominationAddress != address(0));
		AOIonInterface _ao = AOIonInterface(denominations[index].denominationAddress);
		return (
			denominations[index].name,
			denominations[index].denominationAddress,
			integerAmount,
			fractionAmount,
			_ao.name(),
			_ao.symbol(),
			_ao.decimals(),
			_ao.powerOfTen()
		);
	}
}