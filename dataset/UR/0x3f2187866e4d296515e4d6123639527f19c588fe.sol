 

pragma solidity >=0.5.4 <0.6.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }


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


interface INameFactory {
	function nonces(address _nameId) external view returns (uint256);
	function incrementNonce(address _nameId) external returns (uint256);
	function ethAddressToNameId(address _ethAddress) external view returns (address);
	function setNameNewAddress(address _id, address _newAddress) external returns (bool);
	function nameIdToEthAddress(address _nameId) external view returns (address);
}


interface ITAOCurrencyTreasury {
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









 
contract TAOCurrency is TheAO {
	using SafeMath for uint256;

	 
	string public name;
	string public symbol;
	uint8 public decimals;

	 
	uint256 public powerOfTen;

	uint256 public totalSupply;

	 
	 
	mapping (address => uint256) public balanceOf;

	 
	 
	event Transfer(address indexed from, address indexed to, uint256 value);

	 
	 
	event Burn(address indexed from, uint256 value);

	 
	constructor (string memory _name, string memory _symbol, address _nameTAOPositionAddress) public {
		name = _name;		 
		symbol = _symbol;	 

		powerOfTen = 0;
		decimals = 0;

		setNameTAOPositionAddress(_nameTAOPositionAddress);
	}

	 
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	 
	modifier isNameOrTAO(address _id) {
		require (AOLibrary.isName(_id) || AOLibrary.isTAO(_id));
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

	 
	 
	function transferFrom(address _from, address _to, uint256 _value) public inWhitelist isNameOrTAO(_from) isNameOrTAO(_to) returns (bool) {
		_transfer(_from, _to, _value);
		return true;
	}

	 
	function mint(address target, uint256 mintedAmount) public inWhitelist isNameOrTAO(target) returns (bool) {
		_mint(target, mintedAmount);
		return true;
	}

	 
	function whitelistBurnFrom(address _from, uint256 _value) public inWhitelist isNameOrTAO(_from) returns (bool success) {
		require(balanceOf[_from] >= _value);                 
		balanceOf[_from] = balanceOf[_from].sub(_value);     
		totalSupply = totalSupply.sub(_value);               
		emit Burn(_from, _value);
		return true;
	}

	 
	 
	function _transfer(address _from, address _to, uint256 _value) internal {
		require (_to != address(0));							 
		require (balanceOf[_from] >= _value);					 
		require (balanceOf[_to].add(_value) >= balanceOf[_to]);  
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



 
contract TAOCurrencyTreasury is TheAO, ITAOCurrencyTreasury {
	using SafeMath for uint256;

	uint256 public totalDenominations;
	uint256 public totalDenominationExchanges;

	address public nameFactoryAddress;

	INameFactory internal _nameFactory;

	struct Denomination {
		bytes8 name;
		address denominationAddress;
	}

	struct DenominationExchange {
		bytes32 exchangeId;
		address nameId;			 
		address fromDenominationAddress;	 
		address toDenominationAddress;		 
		uint256 amount;
	}

	 
	 
	 
	mapping (uint256 => Denomination) internal denominations;

	 
	mapping (bytes8 => uint256) internal denominationIndex;

	 
	mapping (uint256 => DenominationExchange) internal denominationExchanges;
	mapping (bytes32 => uint256) internal denominationExchangeIdLookup;

	 
	event ExchangeDenomination(address indexed nameId, bytes32 indexed exchangeId, uint256 amount, address fromDenominationAddress, string fromDenominationSymbol, address toDenominationAddress, string toDenominationSymbol);

	 
	constructor(address _nameFactoryAddress, address _nameTAOPositionAddress) public {
		setNameFactoryAddress(_nameFactoryAddress);
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

	 
	function setNameFactoryAddress(address _nameFactoryAddress) public onlyTheAO {
		require (_nameFactoryAddress != address(0));
		nameFactoryAddress = _nameFactoryAddress;
		_nameFactory = INameFactory(_nameFactoryAddress);
	}

	 
	function addDenomination(bytes8 denominationName, address denominationAddress) public onlyTheAO returns (bool) {
		require (denominationName.length > 0);
		require (denominationName[0] != 0);
		require (denominationAddress != address(0));
		require (denominationIndex[denominationName] == 0);
		totalDenominations++;
		 
		if (totalDenominations > 1) {
			TAOCurrency _lastDenominationTAOCurrency = TAOCurrency(denominations[totalDenominations - 1].denominationAddress);
			TAOCurrency _newDenominationTAOCurrency = TAOCurrency(denominationAddress);
			require (_newDenominationTAOCurrency.powerOfTen() > _lastDenominationTAOCurrency.powerOfTen());
		}
		denominations[totalDenominations].name = denominationName;
		denominations[totalDenominations].denominationAddress = denominationAddress;
		denominationIndex[denominationName] = totalDenominations;
		return true;
	}

	 
	function updateDenomination(bytes8 denominationName, address denominationAddress) public onlyTheAO isValidDenomination(denominationName) returns (bool) {
		require (denominationAddress != address(0));
		uint256 _denominationNameIndex = denominationIndex[denominationName];
		TAOCurrency _newDenominationTAOCurrency = TAOCurrency(denominationAddress);
		if (_denominationNameIndex > 1) {
			TAOCurrency _prevDenominationTAOCurrency = TAOCurrency(denominations[_denominationNameIndex - 1].denominationAddress);
			require (_newDenominationTAOCurrency.powerOfTen() > _prevDenominationTAOCurrency.powerOfTen());
		}
		if (_denominationNameIndex < totalDenominations) {
			TAOCurrency _lastDenominationTAOCurrency = TAOCurrency(denominations[totalDenominations].denominationAddress);
			require (_newDenominationTAOCurrency.powerOfTen() < _lastDenominationTAOCurrency.powerOfTen());
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
		TAOCurrency _tc = TAOCurrency(denominations[denominationIndex[denominationName]].denominationAddress);
		return (
			denominations[denominationIndex[denominationName]].name,
			denominations[denominationIndex[denominationName]].denominationAddress,
			_tc.name(),
			_tc.symbol(),
			_tc.decimals(),
			_tc.powerOfTen()
		);
	}

	 
	function getDenominationByIndex(uint256 index) public view returns (bytes8, address, string memory, string memory, uint8, uint256) {
		require (index > 0 && index <= totalDenominations);
		require (denominations[index].denominationAddress != address(0));
		TAOCurrency _tc = TAOCurrency(denominations[index].denominationAddress);
		return (
			denominations[index].name,
			denominations[index].denominationAddress,
			_tc.name(),
			_tc.symbol(),
			_tc.decimals(),
			_tc.powerOfTen()
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
			TAOCurrency _denominationTAOCurrency = TAOCurrency(_denomination.denominationAddress);
			uint8 fractionNumDigits = AOLibrary.numDigits(_fractionAmount);
			require (fractionNumDigits <= _denominationTAOCurrency.decimals());
			uint256 baseInteger = integerAmount.mul(10 ** _denominationTAOCurrency.powerOfTen());
			if (_denominationTAOCurrency.decimals() == 0) {
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
			TAOCurrency _denominationTAOCurrency = TAOCurrency(_denomination.denominationAddress);
			uint256 denominationInteger = integerAmount.div(10 ** _denominationTAOCurrency.powerOfTen());
			uint256 denominationFraction = integerAmount.sub(denominationInteger.mul(10 ** _denominationTAOCurrency.powerOfTen()));
			return (denominationInteger, denominationFraction);
		} else {
			return (0, 0);
		}
	}

	 
	function exchangeDenomination(uint256 amount, bytes8 fromDenominationName, bytes8 toDenominationName) public isValidDenomination(fromDenominationName) isValidDenomination(toDenominationName) {
		address _nameId = _nameFactory.ethAddressToNameId(msg.sender);
		require (_nameId != address(0));
		require (amount > 0);
		Denomination memory _fromDenomination = denominations[denominationIndex[fromDenominationName]];
		Denomination memory _toDenomination = denominations[denominationIndex[toDenominationName]];
		TAOCurrency _fromDenominationCurrency = TAOCurrency(_fromDenomination.denominationAddress);
		TAOCurrency _toDenominationCurrency = TAOCurrency(_toDenomination.denominationAddress);
		require (_fromDenominationCurrency.whitelistBurnFrom(_nameId, amount));
		require (_toDenominationCurrency.mint(_nameId, amount));

		 
		totalDenominationExchanges++;
		bytes32 _exchangeId = keccak256(abi.encodePacked(this, _nameId, totalDenominationExchanges));
		denominationExchangeIdLookup[_exchangeId] = totalDenominationExchanges;

		DenominationExchange storage _denominationExchange = denominationExchanges[totalDenominationExchanges];
		_denominationExchange.exchangeId = _exchangeId;
		_denominationExchange.nameId = _nameId;
		_denominationExchange.fromDenominationAddress = _fromDenomination.denominationAddress;
		_denominationExchange.toDenominationAddress = _toDenomination.denominationAddress;
		_denominationExchange.amount = amount;

		emit ExchangeDenomination(_nameId, _exchangeId, amount, _fromDenomination.denominationAddress, TAOCurrency(_fromDenomination.denominationAddress).symbol(), _toDenomination.denominationAddress, TAOCurrency(_toDenomination.denominationAddress).symbol());
	}

	 
	function getDenominationExchangeById(bytes32 _exchangeId) public view returns (address, address, address, string memory, string memory, uint256) {
		require (denominationExchangeIdLookup[_exchangeId] > 0);
		DenominationExchange memory _denominationExchange = denominationExchanges[denominationExchangeIdLookup[_exchangeId]];
		return (
			_denominationExchange.nameId,
			_denominationExchange.fromDenominationAddress,
			_denominationExchange.toDenominationAddress,
			TAOCurrency(_denominationExchange.fromDenominationAddress).symbol(),
			TAOCurrency(_denominationExchange.toDenominationAddress).symbol(),
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
		TAOCurrency _tc = TAOCurrency(denominations[index].denominationAddress);
		return (
			denominations[index].name,
			denominations[index].denominationAddress,
			integerAmount,
			fractionAmount,
			_tc.name(),
			_tc.symbol(),
			_tc.decimals(),
			_tc.powerOfTen()
		);
	}
}


 
contract PathosTreasury is TAOCurrencyTreasury {
	 
	constructor(address _nameFactoryAddress, address _nameTAOPositionAddress)
		TAOCurrencyTreasury(_nameFactoryAddress, _nameTAOPositionAddress) public {}
}