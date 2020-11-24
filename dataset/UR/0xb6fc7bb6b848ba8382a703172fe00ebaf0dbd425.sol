 

pragma solidity >=0.5.4 <0.6.0;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }


 
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


interface INameAccountRecovery {
	function isCompromised(address _id) external view returns (bool);
}


interface IAOSettingValue {
	function setPendingValue(uint256 _settingId, address _addressValue, bool _boolValue, bytes32 _bytesValue, string calldata _stringValue, uint256 _uintValue) external returns (bool);

	function movePendingToSetting(uint256 _settingId) external returns (bool);

	function settingValue(uint256 _settingId) external view returns (address, bool, bytes32, string memory, uint256);
}


interface IAOSettingAttribute {
	function add(uint256 _settingId, address _creatorNameId, string calldata _settingName, address _creatorTAOId, address _associatedTAOId, string calldata _extraData) external returns (bytes32, bytes32);

	function getSettingData(uint256 _settingId) external view returns (uint256, address, address, address, string memory, bool, bool, bool, string memory);

	function approveAdd(uint256 _settingId, address _associatedTAOAdvocate, bool _approved) external returns (bool);

	function finalizeAdd(uint256 _settingId, address _creatorTAOAdvocate) external returns (bool);

	function update(uint256 _settingId, address _associatedTAOAdvocate, address _proposalTAOId, string calldata _extraData) external returns (bool);

	function getSettingState(uint256 _settingId) external view returns (uint256, bool, address, address, address, string memory);

	function approveUpdate(uint256 _settingId, address _proposalTAOAdvocate, bool _approved) external returns (bool);

	function finalizeUpdate(uint256 _settingId, address _associatedTAOAdvocate) external returns (bool);

	function addDeprecation(uint256 _settingId, address _creatorNameId, address _creatorTAOId, address _associatedTAOId, uint256 _newSettingId, address _newSettingContractAddress) external returns (bytes32, bytes32);

	function getSettingDeprecation(uint256 _settingId) external view returns (uint256, address, address, address, bool, bool, bool, bool, uint256, uint256, address, address);

	function approveDeprecation(uint256 _settingId, address _associatedTAOAdvocate, bool _approved) external returns (bool);

	function finalizeDeprecation(uint256 _settingId, address _creatorTAOAdvocate) external returns (bool);

	function settingExist(uint256 _settingId) external view returns (bool);

	function getLatestSettingId(uint256 _settingId) external view returns (uint256);
}


interface INameFactory {
	function nonces(address _nameId) external view returns (uint256);
	function incrementNonce(address _nameId) external returns (uint256);
	function ethAddressToNameId(address _ethAddress) external view returns (address);
	function setNameNewAddress(address _id, address _newAddress) external returns (bool);
	function nameIdToEthAddress(address _nameId) external view returns (address);
}


interface IAOSetting {
	function getSettingValuesByTAOName(address _taoId, string calldata _settingName) external view returns (uint256, bool, address, bytes32, string memory);
	function getSettingTypes() external view returns (uint8, uint8, uint8, uint8, uint8);

	function settingTypeLookup(uint256 _settingId) external view returns (uint8);
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








 
contract AOSettingUpdate is TheAO {
	address public nameFactoryAddress;
	address public nameAccountRecoveryAddress;
	address public aoSettingAttributeAddress;
	address public aoSettingValueAddress;
	address public aoSettingAddress;

	INameFactory internal _nameFactory;
	INameTAOPosition internal _nameTAOPosition;
	INameAccountRecovery internal _nameAccountRecovery;
	IAOSettingAttribute internal _aoSettingAttribute;
	IAOSettingValue internal _aoSettingValue;
	IAOSetting internal _aoSetting;

	struct UpdateSignature {
		uint8 signatureV;
		bytes32 signatureR;
		bytes32 signatureS;
	}

	 
	mapping (uint256 => UpdateSignature) public updateSignatures;

	 
	mapping (bytes32 => uint256) public updateHashLookup;

	 
	event SettingUpdate(uint256 indexed settingId, address indexed updateAdvocateNameId, address proposalTAOId);

	 
	event ApproveSettingUpdate(uint256 indexed settingId, address proposalTAOId, address proposalTAOAdvocate, bool approved);

	 
	event FinalizeSettingUpdate(uint256 indexed settingId, address associatedTAOId, address associatedTAOAdvocate);

	 
	constructor(address _nameFactoryAddress,
		address _nameTAOPositionAddress,
		address _nameAccountRecoveryAddress,
		address _aoSettingAttributeAddress,
		address _aoSettingValueAddress,
		address _aoSettingAddress
		) public {
		setNameFactoryAddress(_nameFactoryAddress);
		setNameTAOPositionAddress(_nameTAOPositionAddress);
		setNameAccountRecoveryAddress(_nameAccountRecoveryAddress);
		setAOSettingAttributeAddress(_aoSettingAttributeAddress);
		setAOSettingValueAddress(_aoSettingValueAddress);
		setAOSettingAddress(_aoSettingAddress);
	}

	 
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
		_;
	}

	 
	 modifier senderIsName() {
		require (_nameFactory.ethAddressToNameId(msg.sender) != address(0));
		_;
	 }

	 
	modifier senderNameNotCompromised() {
		require (!_nameAccountRecovery.isCompromised(_nameFactory.ethAddressToNameId(msg.sender)));
		_;
	}

	 
	modifier canUpdate(address _proposalTAOId) {
		require (
			AOLibrary.isTAO(_proposalTAOId) &&
			_nameFactory.ethAddressToNameId(msg.sender) != address(0) &&
			!_nameAccountRecovery.isCompromised(_nameFactory.ethAddressToNameId(msg.sender))
		);
		_;
	}

	 
	modifier isAddressSetting(uint256 _settingId) {
		(uint8 ADDRESS_SETTING_TYPE,,,,) = _aoSetting.getSettingTypes();
		 
		require (_aoSetting.settingTypeLookup(_settingId) == ADDRESS_SETTING_TYPE);
		_;
	}

	 
	modifier isBoolSetting(uint256 _settingId) {
		(, uint8 BOOL_SETTING_TYPE,,,) = _aoSetting.getSettingTypes();
		 
		require (_aoSetting.settingTypeLookup(_settingId) == BOOL_SETTING_TYPE);
		_;
	}

	 
	modifier isBytesSetting(uint256 _settingId) {
		(,, uint8 BYTES_SETTING_TYPE,,) = _aoSetting.getSettingTypes();
		 
		require (_aoSetting.settingTypeLookup(_settingId) == BYTES_SETTING_TYPE);
		_;
	}

	 
	modifier isStringSetting(uint256 _settingId) {
		(,,, uint8 STRING_SETTING_TYPE,) = _aoSetting.getSettingTypes();
		 
		require (_aoSetting.settingTypeLookup(_settingId) == STRING_SETTING_TYPE);
		_;
	}

	 
	modifier isUintSetting(uint256 _settingId) {
		(,,,, uint8 UINT_SETTING_TYPE) = _aoSetting.getSettingTypes();
		 
		require (_aoSetting.settingTypeLookup(_settingId) == UINT_SETTING_TYPE);
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

	 
	function setAOSettingAttributeAddress(address _aoSettingAttributeAddress) public onlyTheAO {
		require (_aoSettingAttributeAddress != address(0));
		aoSettingAttributeAddress = _aoSettingAttributeAddress;
		_aoSettingAttribute = IAOSettingAttribute(_aoSettingAttributeAddress);
	}

	 
	function setAOSettingValueAddress(address _aoSettingValueAddress) public onlyTheAO {
		require (_aoSettingValueAddress != address(0));
		aoSettingValueAddress = _aoSettingValueAddress;
		_aoSettingValue = IAOSettingValue(_aoSettingValueAddress);
	}

	 
	function setAOSettingAddress(address _aoSettingAddress) public onlyTheAO {
		require (_aoSettingAddress != address(0));
		aoSettingAddress = _aoSettingAddress;
		_aoSetting = IAOSetting(_aoSettingAddress);
	}

	 
	 
	function updateAddressSetting(
		uint256 _settingId,
		address _newValue,
		address _proposalTAOId,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS,
		string memory _extraData)
		public
		canUpdate(_proposalTAOId)
		isAddressSetting(_settingId) {

		 
		require (_verifyAndStoreUpdateAddressSignature(_settingId, _newValue, _proposalTAOId, _signatureV, _signatureR, _signatureS));

		 
		require (_aoSettingAttribute.update(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _extraData));

		 
		_aoSettingValue.setPendingValue(_settingId, _newValue, false, '', '', 0);

		 
		_storeUpdateAddressHashLookup(_settingId, _newValue, _proposalTAOId, _extraData);

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	 
	function updateBoolSetting(
		uint256 _settingId,
		bool _newValue,
		address _proposalTAOId,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS,
		string memory _extraData)
		public
		canUpdate(_proposalTAOId)
		isBoolSetting(_settingId) {

		 
		require (_verifyAndStoreUpdateBoolSignature(_settingId, _newValue, _proposalTAOId, _signatureV, _signatureR, _signatureS));

		 
		require (_aoSettingAttribute.update(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _extraData));

		 
		_aoSettingValue.setPendingValue(_settingId, address(0), _newValue, '', '', 0);

		 
		_storeUpdateBoolHashLookup(_settingId, _newValue, _proposalTAOId, _extraData);

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	 
	function updateBytesSetting(
		uint256 _settingId,
		bytes32 _newValue,
		address _proposalTAOId,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS,
		string memory _extraData)
		public
		canUpdate(_proposalTAOId)
		isBytesSetting(_settingId) {

		 
		require (_verifyAndStoreUpdateBytesSignature(_settingId, _newValue, _proposalTAOId, _signatureV, _signatureR, _signatureS));

		 
		require (_aoSettingAttribute.update(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _extraData));

		 
		_aoSettingValue.setPendingValue(_settingId, address(0), false, _newValue, '', 0);

		 
		_storeUpdateBytesHashLookup(_settingId, _newValue, _proposalTAOId, _extraData);

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	 
	function updateStringSetting(
		uint256 _settingId,
		string memory _newValue,
		address _proposalTAOId,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS,
		string memory _extraData)
		public
		canUpdate(_proposalTAOId)
		isStringSetting(_settingId) {

		 
		require (_verifyAndStoreUpdateStringSignature(_settingId, _newValue, _proposalTAOId, _signatureV, _signatureR, _signatureS));

		 
		require (_aoSettingAttribute.update(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _extraData));

		 
		_aoSettingValue.setPendingValue(_settingId, address(0), false, '', _newValue, 0);

		 
		_storeUpdateStringHashLookup(_settingId, _newValue, _proposalTAOId, _extraData);

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	 
	function updateUintSetting(
		uint256 _settingId,
		uint256 _newValue,
		address _proposalTAOId,
		uint8 _signatureV,
		bytes32 _signatureR,
		bytes32 _signatureS,
		string memory _extraData)
		public
		canUpdate(_proposalTAOId)
		isUintSetting(_settingId) {

		 
		require (_verifyAndStoreUpdateUintSignature(_settingId, _newValue, _proposalTAOId, _signatureV, _signatureR, _signatureS));

		 
		require (_aoSettingAttribute.update(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId, _extraData));

		 
		_aoSettingValue.setPendingValue(_settingId, address(0), false, '', '', _newValue);

		 
		_storeUpdateUintHashLookup(_settingId, _newValue, _proposalTAOId, _extraData);

		emit SettingUpdate(_settingId, _nameFactory.ethAddressToNameId(msg.sender), _proposalTAOId);
	}

	 
	function approveSettingUpdate(uint256 _settingId, bool _approved) public senderIsName senderNameNotCompromised {
		 
		require (_aoSetting.settingTypeLookup(_settingId) > 0);

		address _proposalTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		(,,, address _proposalTAOId,,) = _aoSettingAttribute.getSettingState(_settingId);

		require (_aoSettingAttribute.approveUpdate(_settingId, _proposalTAOAdvocate, _approved));

		emit ApproveSettingUpdate(_settingId, _proposalTAOId, _proposalTAOAdvocate, _approved);
	}

	 
	function finalizeSettingUpdate(uint256 _settingId) public senderIsName senderNameNotCompromised {
		 
		require (_aoSetting.settingTypeLookup(_settingId) > 0);

		address _associatedTAOAdvocate = _nameFactory.ethAddressToNameId(msg.sender);
		require (_aoSettingAttribute.finalizeUpdate(_settingId, _associatedTAOAdvocate));

		(,,, address _associatedTAOId,,,,,) = _aoSettingAttribute.getSettingData(_settingId);

		require (_aoSettingValue.movePendingToSetting(_settingId));

		emit FinalizeSettingUpdate(_settingId, _associatedTAOId, _associatedTAOAdvocate);
	}

	 
	 
	function _verifyAndStoreUpdateAddressSignature(
		uint256 _settingId,
		address _newValue,
		address _proposalTAOId,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
		) internal returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked(address(this), _settingId, _proposalTAOId, _newValue, _nameFactory.ethAddressToNameId(msg.sender)));
		if (ecrecover(_hash, _v, _r, _s) != msg.sender) {
			return false;
		}
		_storeUpdateSignature(_settingId, _v, _r, _s);
		return true;
	}

	 
	function _verifyAndStoreUpdateBoolSignature(
		uint256 _settingId,
		bool _newValue,
		address _proposalTAOId,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
		) internal returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked(address(this), _settingId, _proposalTAOId, _newValue, _nameFactory.ethAddressToNameId(msg.sender)));
		if (ecrecover(_hash, _v, _r, _s) != msg.sender) {
			return false;
		}
		_storeUpdateSignature(_settingId, _v, _r, _s);
		return true;
	}

	 
	function _verifyAndStoreUpdateBytesSignature(
		uint256 _settingId,
		bytes32 _newValue,
		address _proposalTAOId,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
		) internal returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked(address(this), _settingId, _proposalTAOId, _newValue, _nameFactory.ethAddressToNameId(msg.sender)));
		if (ecrecover(_hash, _v, _r, _s) != msg.sender) {
			return false;
		}
		_storeUpdateSignature(_settingId, _v, _r, _s);
		return true;
	}

	 
	function _verifyAndStoreUpdateStringSignature(
		uint256 _settingId,
		string memory _newValue,
		address _proposalTAOId,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
		) internal returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked(address(this), _settingId, _proposalTAOId, _newValue, _nameFactory.ethAddressToNameId(msg.sender)));
		if (ecrecover(_hash, _v, _r, _s) != msg.sender) {
			return false;
		}
		_storeUpdateSignature(_settingId, _v, _r, _s);
		return true;
	}

	 
	function _verifyAndStoreUpdateUintSignature(
		uint256 _settingId,
		uint256 _newValue,
		address _proposalTAOId,
		uint8 _v,
		bytes32 _r,
		bytes32 _s
		) public returns (bool) {
		bytes32 _hash = keccak256(abi.encodePacked(address(this), _settingId, _proposalTAOId, _newValue, _nameFactory.ethAddressToNameId(msg.sender)));
		if (ecrecover(_hash, _v, _r, _s) != msg.sender) {
			return false;
		}
		_storeUpdateSignature(_settingId, _v, _r, _s);
		return true;
	}

	 
	function _storeUpdateAddressHashLookup(
		uint256 _settingId,
		address _newValue,
		address _proposalTAOId,
		string memory _extraData)
		internal {
		 
		(address _addressValue,,,,) = _aoSettingValue.settingValue(_settingId);
		updateHashLookup[keccak256(abi.encodePacked(address(this), _proposalTAOId, _addressValue, _newValue, _extraData, _settingId))] = _settingId;
	}

	 
	function _storeUpdateBoolHashLookup(
		uint256 _settingId,
		bool _newValue,
		address _proposalTAOId,
		string memory _extraData)
		internal {
		 
		(, bool _boolValue,,,) = _aoSettingValue.settingValue(_settingId);
		updateHashLookup[keccak256(abi.encodePacked(address(this), _proposalTAOId, _boolValue, _newValue, _extraData, _settingId))] = _settingId;
	}

	 
	function _storeUpdateBytesHashLookup(
		uint256 _settingId,
		bytes32 _newValue,
		address _proposalTAOId,
		string memory _extraData)
		internal {
		 
		(,, bytes32 _bytesValue,,) = _aoSettingValue.settingValue(_settingId);
		updateHashLookup[keccak256(abi.encodePacked(address(this), _proposalTAOId, _bytesValue, _newValue, _extraData, _settingId))] = _settingId;
	}

	 
	function _storeUpdateStringHashLookup(
		uint256 _settingId,
		string memory _newValue,
		address _proposalTAOId,
		string memory _extraData)
		internal {
		 
		(,,, string memory _stringValue,) = _aoSettingValue.settingValue(_settingId);
		updateHashLookup[keccak256(abi.encodePacked(address(this), _proposalTAOId, _stringValue, _newValue, _extraData, _settingId))] = _settingId;
	}

	 
	function _storeUpdateUintHashLookup(
		uint256 _settingId,
		uint256 _newValue,
		address _proposalTAOId,
		string memory _extraData)
		internal {
		 
		(,,,, uint256 _uintValue) = _aoSettingValue.settingValue(_settingId);
		updateHashLookup[keccak256(abi.encodePacked(address(this), _proposalTAOId, _uintValue, _newValue, _extraData, _settingId))] = _settingId;
	}

	 
	function _storeUpdateSignature(uint256 _settingId, uint8 _v, bytes32 _r, bytes32 _s) internal {
		UpdateSignature storage _updateSignature = updateSignatures[_settingId];
		_updateSignature.signatureV = _v;
		_updateSignature.signatureR = _r;
		_updateSignature.signatureS = _s;
	}
}