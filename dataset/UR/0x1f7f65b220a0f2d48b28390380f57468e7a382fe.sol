 

pragma solidity >=0.5.4 <0.6.0;

 
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


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }




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


interface INameAccountRecovery {
	function isCompromised(address _id) external view returns (bool);
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


interface IAOSetting {
	function getSettingValuesByTAOName(address _taoId, string calldata _settingName) external view returns (uint256, bool, address, bytes32, string memory);
	function getSettingTypes() external view returns (uint8, uint8, uint8, uint8, uint8);

	function settingTypeLookup(uint256 _settingId) external view returns (uint8);
}


interface ITAOAncestry {
	function initialize(address _id, address _parentId, uint256 _childMinLogos) external returns (bool);

	function getAncestryById(address _id) external view returns (address, uint256, uint256);

	function addChild(address _taoId, address _childId) external returns (bool);

	function isChild(address _taoId, address _childId) external view returns (bool);
}


interface ITAOFactory {
	function nonces(address _taoId) external view returns (uint256);
	function incrementNonce(address _taoId) external returns (uint256);
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





contract Logos is TAOCurrency {
	address public nameFactoryAddress;
	address public nameAccountRecoveryAddress;

	INameFactory internal _nameFactory;
	INameTAOPosition internal _nameTAOPosition;
	INameAccountRecovery internal _nameAccountRecovery;

	 
	 
	mapping (address => uint256) public positionFromOthers;

	 
	mapping (address => mapping(address => uint256)) public positionOnOthers;

	 
	mapping (address => uint256) public totalPositionOnOthers;

	 
	mapping (address => mapping(address => uint256)) public advocatedTAOLogos;

	 
	mapping (address => uint256) public totalAdvocatedTAOLogos;

	 
	event PositionFrom(address indexed from, address indexed to, uint256 value);

	 
	event UnpositionFrom(address indexed from, address indexed to, uint256 value);

	 
	event AddAdvocatedTAOLogos(address indexed nameId, address indexed taoId, uint256 amount);

	 
	event TransferAdvocatedTAOLogos(address indexed fromNameId, address indexed toNameId, address indexed taoId, uint256 amount);

	 
	constructor(string memory _name, string memory _symbol, address _nameFactoryAddress, address _nameTAOPositionAddress)
		TAOCurrency(_name, _symbol, _nameTAOPositionAddress) public {
		setNameFactoryAddress(_nameFactoryAddress);
		setNameTAOPositionAddress(_nameTAOPositionAddress);
	}

	 
	modifier isTAO(address _taoId) {
		require (AOLibrary.isTAO(_taoId));
		_;
	}

	 
	modifier isName(address _nameId) {
		require (AOLibrary.isName(_nameId));
		_;
	}

	 
	modifier onlyAdvocate(address _id) {
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _id));
		_;
	}

	 
	modifier nameNotCompromised(address _id) {
		require (!_nameAccountRecovery.isCompromised(_id));
		_;
	}

	 
	modifier senderNameNotCompromised() {
		require (!_nameAccountRecovery.isCompromised(_nameFactory.ethAddressToNameId(msg.sender)));
		_;
	}

	 
	 
	function setNameFactoryAddress(address _nameFactoryAddress) public onlyTheAO {
		require (_nameFactoryAddress != address(0));
		nameFactoryAddress = _nameFactoryAddress;
		_nameFactory = INameFactory(_nameFactoryAddress);
	}

	 
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
		_nameTAOPosition = INameTAOPosition(_nameTAOPositionAddress);
	}

	 
	function setNameAccountRecoveryAddress(address _nameAccountRecoveryAddress) public onlyTheAO {
		require (_nameAccountRecoveryAddress != address(0));
		nameAccountRecoveryAddress = _nameAccountRecoveryAddress;
		_nameAccountRecovery = INameAccountRecovery(nameAccountRecoveryAddress);
	}

	 
	 
	function sumBalanceOf(address _target) public isName(_target) view returns (uint256) {
		return balanceOf[_target].add(positionFromOthers[_target]).add(totalAdvocatedTAOLogos[_target]);
	}

	 
	function availableToPositionAmount(address _sender) public isName(_sender) view returns (uint256) {
		return balanceOf[_sender].sub(totalPositionOnOthers[_sender]);
	}

	 
	function positionFrom(address _from, address _to, uint256 _value) public isName(_from) isName(_to) nameNotCompromised(_from) nameNotCompromised(_to) onlyAdvocate(_from) senderNameNotCompromised returns (bool) {
		require (_from != _to);	 
		require (availableToPositionAmount(_from) >= _value);  
		require (positionFromOthers[_to].add(_value) >= positionFromOthers[_to]);  

		positionOnOthers[_from][_to] = positionOnOthers[_from][_to].add(_value);
		totalPositionOnOthers[_from] = totalPositionOnOthers[_from].add(_value);
		positionFromOthers[_to] = positionFromOthers[_to].add(_value);

		emit PositionFrom(_from, _to, _value);
		return true;
	}

	 
	function unpositionFrom(address _from, address _to, uint256 _value) public isName(_from) isName(_to) nameNotCompromised(_from) nameNotCompromised(_to) onlyAdvocate(_from) senderNameNotCompromised returns (bool) {
		require (_from != _to);	 
		require (positionOnOthers[_from][_to] >= _value);

		positionOnOthers[_from][_to] = positionOnOthers[_from][_to].sub(_value);
		totalPositionOnOthers[_from] = totalPositionOnOthers[_from].sub(_value);
		positionFromOthers[_to] = positionFromOthers[_to].sub(_value);

		emit UnpositionFrom(_from, _to, _value);
		return true;
	}

	 
	function addAdvocatedTAOLogos(address _taoId, uint256 _amount) public inWhitelist isTAO(_taoId) returns (bool) {
		require (_amount > 0);
		address _nameId = _nameTAOPosition.getAdvocate(_taoId);

		advocatedTAOLogos[_nameId][_taoId] = advocatedTAOLogos[_nameId][_taoId].add(_amount);
		totalAdvocatedTAOLogos[_nameId] = totalAdvocatedTAOLogos[_nameId].add(_amount);

		emit AddAdvocatedTAOLogos(_nameId, _taoId, _amount);
		return true;
	}

	 
	function transferAdvocatedTAOLogos(address _fromNameId, address _taoId) public inWhitelist isName(_fromNameId) isTAO(_taoId) returns (bool) {
		address _toNameId = _nameTAOPosition.getAdvocate(_taoId);
		require (_fromNameId != _toNameId);
		require (totalAdvocatedTAOLogos[_fromNameId] >= advocatedTAOLogos[_fromNameId][_taoId]);

		uint256 _amount = advocatedTAOLogos[_fromNameId][_taoId];
		advocatedTAOLogos[_fromNameId][_taoId] = 0;
		totalAdvocatedTAOLogos[_fromNameId] = totalAdvocatedTAOLogos[_fromNameId].sub(_amount);
		advocatedTAOLogos[_toNameId][_taoId] = advocatedTAOLogos[_toNameId][_taoId].add(_amount);
		totalAdvocatedTAOLogos[_toNameId] = totalAdvocatedTAOLogos[_toNameId].add(_amount);

		emit TransferAdvocatedTAOLogos(_fromNameId, _toNameId, _taoId, _amount);
		return true;
	}
}



 
contract NameTAOPosition is TheAO, INameTAOPosition {
	using SafeMath for uint256;

	address public settingTAOId;
	address public nameFactoryAddress;
	address public nameAccountRecoveryAddress;
	address public taoFactoryAddress;
	address public aoSettingAddress;
	address public taoAncestryAddress;
	address public logosAddress;

	uint256 public totalTAOAdvocateChallenges;

	INameFactory internal _nameFactory;
	INameAccountRecovery internal _nameAccountRecovery;
	ITAOFactory internal _taoFactory;
	IAOSetting internal _aoSetting;
	ITAOAncestry internal _taoAncestry;
	Logos internal _logos;

	struct PositionDetail {
		address advocateId;
		address listenerId;
		address speakerId;
		bool created;
	}

	struct TAOAdvocateChallenge {
		bytes32 challengeId;
		address newAdvocateId;		 
		address taoId;				 
		bool completed;				 
		uint256 createdTimestamp;	 
		uint256 lockedUntilTimestamp;	 
		uint256 completeBeforeTimestamp;  
	}

	 
	mapping (address => PositionDetail) internal positionDetails;

	 
	mapping (bytes32 => TAOAdvocateChallenge) internal taoAdvocateChallenges;

	 
	event SetAdvocate(address indexed taoId, address oldAdvocateId, address newAdvocateId, uint256 nonce);

	 
	event SetListener(address indexed taoId, address oldListenerId, address newListenerId, uint256 nonce);

	 
	event SetSpeaker(address indexed taoId, address oldSpeakerId, address newSpeakerId, uint256 nonce);

	 
	event ChallengeTAOAdvocate(address indexed taoId, bytes32 indexed challengeId, address currentAdvocateId, address challengerAdvocateId, uint256 createdTimestamp, uint256 lockedUntilTimestamp, uint256 completeBeforeTimestamp);

	 
	event CompleteTAOAdvocateChallenge(address indexed taoId, bytes32 indexed challengeId);

	 
	constructor(address _nameFactoryAddress, address _taoFactoryAddress) public {
		setNameFactoryAddress(_nameFactoryAddress);
		setTAOFactoryAddress(_taoFactoryAddress);

		nameTAOPositionAddress = address(this);
	}

	 
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	 
	modifier onlyFactory {
		require (msg.sender == nameFactoryAddress || msg.sender == taoFactoryAddress);
		_;
	}

	 
	modifier isTAO(address _taoId) {
		require (AOLibrary.isTAO(_taoId));
		_;
	}

	 
	modifier isName(address _nameId) {
		require (AOLibrary.isName(_nameId));
		_;
	}

	 
	modifier isNameOrTAO(address _id) {
		require (AOLibrary.isName(_id) || AOLibrary.isTAO(_id));
		_;
	}

	 
	 modifier senderIsName() {
		require (_nameFactory.ethAddressToNameId(msg.sender) != address(0));
		_;
	 }

	 
	modifier onlyAdvocate(address _id) {
		require (this.senderIsAdvocate(msg.sender, _id));
		_;
	}

	 
	modifier senderNameNotCompromised() {
		require (!_nameAccountRecovery.isCompromised(_nameFactory.ethAddressToNameId(msg.sender)));
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

	 
	function setNameFactoryAddress(address _nameFactoryAddress) public onlyTheAO {
		require (_nameFactoryAddress != address(0));
		nameFactoryAddress = _nameFactoryAddress;
		_nameFactory = INameFactory(_nameFactoryAddress);
	}

	 
	function setNameAccountRecoveryAddress(address _nameAccountRecoveryAddress) public onlyTheAO {
		require (_nameAccountRecoveryAddress != address(0));
		nameAccountRecoveryAddress = _nameAccountRecoveryAddress;
		_nameAccountRecovery = INameAccountRecovery(nameAccountRecoveryAddress);
	}

	 
	function setTAOFactoryAddress(address _taoFactoryAddress) public onlyTheAO {
		require (_taoFactoryAddress != address(0));
		taoFactoryAddress = _taoFactoryAddress;
		_taoFactory = ITAOFactory(_taoFactoryAddress);
	}

	 
	function setSettingTAOId(address _settingTAOId) public onlyTheAO {
		require (AOLibrary.isTAO(_settingTAOId));
		settingTAOId = _settingTAOId;
	}

	 
	function setAOSettingAddress(address _aoSettingAddress) public onlyTheAO {
		require (_aoSettingAddress != address(0));
		aoSettingAddress = _aoSettingAddress;
		_aoSetting = IAOSetting(_aoSettingAddress);
	}

	 
	function setTAOAncestryAddress(address _taoAncestryAddress) public onlyTheAO {
		require (_taoAncestryAddress != address(0));
		taoAncestryAddress = _taoAncestryAddress;
		_taoAncestry = ITAOAncestry(taoAncestryAddress);
	}

	 
	function setLogosAddress(address _logosAddress) public onlyTheAO {
		require (_logosAddress != address(0));
		logosAddress = _logosAddress;
		_logos = Logos(_logosAddress);
	}

	 
	 
	function isExist(address _id) public view returns (bool) {
		return positionDetails[_id].created;
	}

	 
	function senderIsAdvocate(address _sender, address _id) external view returns (bool) {
		return (positionDetails[_id].created && positionDetails[_id].advocateId == _nameFactory.ethAddressToNameId(_sender));
	}

	 
	function senderIsListener(address _sender, address _id) external view returns (bool) {
		return (positionDetails[_id].created && positionDetails[_id].listenerId == _nameFactory.ethAddressToNameId(_sender));
	}

	 
	function senderIsSpeaker(address _sender, address _id) external view returns (bool) {
		return (positionDetails[_id].created && positionDetails[_id].speakerId == _nameFactory.ethAddressToNameId(_sender));
	}

	 
	function senderIsAdvocateOfParent(address _sender, address _id) public view returns (bool) {
		(address _parentId,,) = _taoAncestry.getAncestryById(_id);
		 return ((AOLibrary.isName(_parentId) || (AOLibrary.isTAO(_parentId) && _taoAncestry.isChild(_parentId, _id))) && this.senderIsAdvocate(_sender, _parentId));
	}

	 
	function senderIsPosition(address _sender, address _id) external view returns (bool) {
		address _nameId = _nameFactory.ethAddressToNameId(_sender);
		if (_nameId == address(0)) {
			return false;
		} else {
			return this.nameIsPosition(_nameId, _id);
		}
	}

	 
	function nameIsAdvocate(address _nameId, address _id) external view returns (bool) {
		return (positionDetails[_id].created && positionDetails[_id].advocateId == _nameId);
	}

	 
	function nameIsPosition(address _nameId, address _id) external view returns (bool) {
		return (positionDetails[_id].created &&
			(positionDetails[_id].advocateId == _nameId ||
			 positionDetails[_id].listenerId == _nameId ||
			 positionDetails[_id].speakerId == _nameId
			)
	   );
	}

	 
	function determinePosition(address _sender, address _id) external view returns (uint256) {
		require (this.senderIsPosition(_sender, _id));
		PositionDetail memory _positionDetail = positionDetails[_id];
		address _nameId = _nameFactory.ethAddressToNameId(_sender);
		if (_nameId == _positionDetail.advocateId) {
			return 1;
		} else if (_nameId == _positionDetail.listenerId) {
			return 2;
		} else {
			return 3;
		}
	}

	 
	function initialize(address _id, address _advocateId, address _listenerId, address _speakerId)
		external
		isNameOrTAO(_id)
		isName(_advocateId)
		isNameOrTAO(_listenerId)
		isNameOrTAO(_speakerId)
		onlyFactory returns (bool) {
		require (!isExist(_id));

		PositionDetail storage _positionDetail = positionDetails[_id];
		_positionDetail.advocateId = _advocateId;
		_positionDetail.listenerId = _listenerId;
		_positionDetail.speakerId = _speakerId;
		_positionDetail.created = true;
		return true;
	}

	 
	function getPositionById(address _id) public view returns (string memory, address, string memory, address, string memory, address) {
		require (isExist(_id));
		PositionDetail memory _positionDetail = positionDetails[_id];
		return (
			TAO(address(uint160(_positionDetail.advocateId))).name(),
			_positionDetail.advocateId,
			TAO(address(uint160(_positionDetail.listenerId))).name(),
			_positionDetail.listenerId,
			TAO(address(uint160(_positionDetail.speakerId))).name(),
			_positionDetail.speakerId
		);
	}

	 
	function getAdvocate(address _id) external view returns (address) {
		require (isExist(_id));
		PositionDetail memory _positionDetail = positionDetails[_id];
		return _positionDetail.advocateId;
	}

	 
	function getListener(address _id) public view returns (address) {
		require (isExist(_id));
		PositionDetail memory _positionDetail = positionDetails[_id];
		return _positionDetail.listenerId;
	}

	 
	function getSpeaker(address _id) public view returns (address) {
		require (isExist(_id));
		PositionDetail memory _positionDetail = positionDetails[_id];
		return _positionDetail.speakerId;
	}

	 
	function setAdvocate(address _taoId, address _newAdvocateId)
		public
		isTAO(_taoId)
		isName(_newAdvocateId)
		onlyAdvocate(_taoId)
		senderIsName
		senderNameNotCompromised {
		require (isExist(_taoId));
		 
		require (!_nameAccountRecovery.isCompromised(_newAdvocateId));
		_setAdvocate(_taoId, _newAdvocateId);
	}

	 
	function parentReplaceChildAdvocate(address _taoId)
		public
		isTAO(_taoId)
		senderIsName
		senderNameNotCompromised {
		require (isExist(_taoId));
		require (senderIsAdvocateOfParent(msg.sender, _taoId));
		address _parentNameId = _nameFactory.ethAddressToNameId(msg.sender);
		address _currentAdvocateId = this.getAdvocate(_taoId);

		 
		require (_parentNameId != _currentAdvocateId);

		 
		require (_logos.sumBalanceOf(_parentNameId) > _logos.sumBalanceOf(this.getAdvocate(_taoId)));

		_setAdvocate(_taoId, _parentNameId);
	}

	 
	function challengeTAOAdvocate(address _taoId)
		public
		isTAO(_taoId)
		senderIsName
		senderNameNotCompromised {
		require (isExist(_taoId));
		address _newAdvocateId = _nameFactory.ethAddressToNameId(msg.sender);
		address _currentAdvocateId = this.getAdvocate(_taoId);

		 
		require (_newAdvocateId != _currentAdvocateId);

		 
		require (_logos.sumBalanceOf(_newAdvocateId) > _logos.sumBalanceOf(_currentAdvocateId));

		(uint256 _lockDuration, uint256 _completeDuration) = _getSettingVariables();

		totalTAOAdvocateChallenges++;
		bytes32 _challengeId = keccak256(abi.encodePacked(this, _taoId, _newAdvocateId, totalTAOAdvocateChallenges));
		TAOAdvocateChallenge storage _taoAdvocateChallenge = taoAdvocateChallenges[_challengeId];
		_taoAdvocateChallenge.challengeId = _challengeId;
		_taoAdvocateChallenge.newAdvocateId = _newAdvocateId;
		_taoAdvocateChallenge.taoId = _taoId;
		_taoAdvocateChallenge.createdTimestamp = now;
		_taoAdvocateChallenge.lockedUntilTimestamp = _taoAdvocateChallenge.createdTimestamp.add(_lockDuration);
		_taoAdvocateChallenge.completeBeforeTimestamp = _taoAdvocateChallenge.lockedUntilTimestamp.add(_completeDuration);

		emit ChallengeTAOAdvocate(_taoId, _challengeId, _currentAdvocateId, _newAdvocateId, _taoAdvocateChallenge.createdTimestamp, _taoAdvocateChallenge.lockedUntilTimestamp, _taoAdvocateChallenge.completeBeforeTimestamp);
	}

	 
	function getChallengeStatus(bytes32 _challengeId, address _sender) public view returns (uint8) {
		address _challengerNameId = _nameFactory.ethAddressToNameId(_sender);
		TAOAdvocateChallenge storage _taoAdvocateChallenge = taoAdvocateChallenges[_challengeId];

		 
		if (_taoAdvocateChallenge.taoId == address(0)) {
			return 2;
		} else if (_challengerNameId != _taoAdvocateChallenge.newAdvocateId) {
			 
			return 3;
		} else if (now < _taoAdvocateChallenge.lockedUntilTimestamp) {
			 
			return 4;
		} else if (now > _taoAdvocateChallenge.completeBeforeTimestamp) {
			 
			return 5;
		} else if (_taoAdvocateChallenge.completed) {
			 
			return 6;
		} else if (_logos.sumBalanceOf(_challengerNameId) <= _logos.sumBalanceOf(this.getAdvocate(_taoAdvocateChallenge.taoId))) {
			 
			return 7;
		} else {
			 
			return 1;
		}
	}

	 
	function completeTAOAdvocateChallenge(bytes32 _challengeId)
		public
		senderIsName
		senderNameNotCompromised {
		TAOAdvocateChallenge storage _taoAdvocateChallenge = taoAdvocateChallenges[_challengeId];

		 
		require (getChallengeStatus(_challengeId, msg.sender) == 1);

		_taoAdvocateChallenge.completed = true;

		_setAdvocate(_taoAdvocateChallenge.taoId, _taoAdvocateChallenge.newAdvocateId);

		emit CompleteTAOAdvocateChallenge(_taoAdvocateChallenge.taoId, _challengeId);
	}

	 
	function getTAOAdvocateChallengeById(bytes32 _challengeId) public view returns (address, address, bool, uint256, uint256, uint256) {
		TAOAdvocateChallenge memory _taoAdvocateChallenge = taoAdvocateChallenges[_challengeId];
		require (_taoAdvocateChallenge.taoId != address(0));
		return (
			_taoAdvocateChallenge.newAdvocateId,
			_taoAdvocateChallenge.taoId,
			_taoAdvocateChallenge.completed,
			_taoAdvocateChallenge.createdTimestamp,
			_taoAdvocateChallenge.lockedUntilTimestamp,
			_taoAdvocateChallenge.completeBeforeTimestamp
		);
	}

	 
	function setListener(address _id, address _newListenerId)
		public
		isNameOrTAO(_id)
		isNameOrTAO(_newListenerId)
		senderIsName
		senderNameNotCompromised
		onlyAdvocate(_id) {
		require (isExist(_id));

		 
		 
		bool _isName = false;
		if (AOLibrary.isName(_id)) {
			_isName = true;
			require (AOLibrary.isName(_newListenerId));
			require (!_nameAccountRecovery.isCompromised(_id));
			require (!_nameAccountRecovery.isCompromised(_newListenerId));
		}

		PositionDetail storage _positionDetail = positionDetails[_id];
		address _currentListenerId = _positionDetail.listenerId;
		_positionDetail.listenerId = _newListenerId;

		uint256 _nonce;
		if (_isName) {
			_nonce = _nameFactory.incrementNonce(_id);
		} else {
			_nonce = _taoFactory.incrementNonce(_id);
		}
		emit SetListener(_id, _currentListenerId, _positionDetail.listenerId, _nonce);
	}

	 
	function setSpeaker(address _id, address _newSpeakerId)
		public
		isNameOrTAO(_id)
		isNameOrTAO(_newSpeakerId)
		senderIsName
		senderNameNotCompromised
		onlyAdvocate(_id) {
		require (isExist(_id));

		 
		 
		bool _isName = false;
		if (AOLibrary.isName(_id)) {
			_isName = true;
			require (AOLibrary.isName(_newSpeakerId));
			require (!_nameAccountRecovery.isCompromised(_id));
			require (!_nameAccountRecovery.isCompromised(_newSpeakerId));
		}

		PositionDetail storage _positionDetail = positionDetails[_id];
		address _currentSpeakerId = _positionDetail.speakerId;
		_positionDetail.speakerId = _newSpeakerId;

		uint256 _nonce;
		if (_isName) {
			_nonce = _nameFactory.incrementNonce(_id);
		} else {
			_nonce = _taoFactory.incrementNonce(_id);
		}
		emit SetSpeaker(_id, _currentSpeakerId, _positionDetail.speakerId, _nonce);
	}

	 
	 
	function _setAdvocate(address _taoId, address _newAdvocateId) internal {
		PositionDetail storage _positionDetail = positionDetails[_taoId];
		address _currentAdvocateId = _positionDetail.advocateId;
		_positionDetail.advocateId = _newAdvocateId;

		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);

		 
		require (_logos.transferAdvocatedTAOLogos(_currentAdvocateId, _taoId));

		emit SetAdvocate(_taoId, _currentAdvocateId, _positionDetail.advocateId, _nonce);
	}

	 
	function _getSettingVariables() internal view returns (uint256, uint256) {
		(uint256 challengeTAOAdvocateLockDuration,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, 'challengeTAOAdvocateLockDuration');
		(uint256 challengeTAOAdvocateCompleteDuration,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, 'challengeTAOAdvocateCompleteDuration');

		return (
			challengeTAOAdvocateLockDuration,
			challengeTAOAdvocateCompleteDuration
		);
	}
}