 

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




 
contract AOSettingAttribute is TheAO, IAOSettingAttribute {
	INameTAOPosition internal _nameTAOPosition;

	struct SettingData {
		uint256 settingId;				 
		address creatorNameId;			 
		address creatorTAOId;		 
		address associatedTAOId;	 
		string settingName;				 
		bool pendingCreate;				 
		bool locked;					 
		bool rejected;					 
		string settingDataJSON;			 
	}

	struct SettingState {
		uint256 settingId;				 
		bool pendingUpdate;				 
		address updateAdvocateNameId;	 

		 
		address proposalTAOId;

		 
		address lastUpdateTAOId;

		string settingStateJSON;		 
	}

	struct SettingDeprecation {
		uint256 settingId;				 
		address creatorNameId;			 
		address creatorTAOId;		 
		address associatedTAOId;	 
		bool pendingDeprecated;			 
		bool locked;					 
		bool rejected;					 
		bool migrated;					 

		 
		uint256 pendingNewSettingId;

		 
		uint256 newSettingId;

		 
		address pendingNewSettingContractAddress;

		 
		address newSettingContractAddress;
	}

	struct AssociatedTAOSetting {
		bytes32 associatedTAOSettingId;		 
		address associatedTAOId;			 
		uint256 settingId;						 
	}

	struct CreatorTAOSetting {
		bytes32 creatorTAOSettingId;		 
		address creatorTAOId;				 
		uint256 settingId;						 
	}

	struct AssociatedTAOSettingDeprecation {
		bytes32 associatedTAOSettingDeprecationId;		 
		address associatedTAOId;						 
		uint256 settingId;									 
	}

	struct CreatorTAOSettingDeprecation {
		bytes32 creatorTAOSettingDeprecationId;			 
		address creatorTAOId;							 
		uint256 settingId;									 
	}

	 
	mapping (uint256 => SettingData) internal settingDatas;

	 
	mapping (uint256 => SettingState) internal settingStates;

	 
	mapping (uint256 => SettingDeprecation) internal settingDeprecations;

	 
	mapping (bytes32 => AssociatedTAOSetting) internal associatedTAOSettings;

	 
	mapping (bytes32 => CreatorTAOSetting) internal creatorTAOSettings;

	 
	mapping (bytes32 => AssociatedTAOSettingDeprecation) internal associatedTAOSettingDeprecations;

	 
	mapping (bytes32 => CreatorTAOSettingDeprecation) internal creatorTAOSettingDeprecations;

	 
	constructor(address _nameTAOPositionAddress) public {
		setNameTAOPositionAddress(_nameTAOPositionAddress);
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
		_nameTAOPosition = INameTAOPosition(_nameTAOPositionAddress);
	}

	 
	 
	function add(uint256 _settingId, address _creatorNameId, string calldata _settingName, address _creatorTAOId, address _associatedTAOId, string calldata _extraData) external inWhitelist returns (bytes32, bytes32) {
		 
		require (_storeSettingDataState(_settingId, _creatorNameId, _settingName, _creatorTAOId, _associatedTAOId, _extraData));

		 
		return (
			_storeAssociatedTAOSetting(_associatedTAOId, _settingId),
			_storeCreatorTAOSetting(_creatorTAOId, _settingId)
		);
	}

	 
	function getSettingData(uint256 _settingId) external view returns (uint256, address, address, address, string memory, bool, bool, bool, string memory) {
		SettingData memory _settingData = settingDatas[_settingId];
		return (
			_settingData.settingId,
			_settingData.creatorNameId,
			_settingData.creatorTAOId,
			_settingData.associatedTAOId,
			_settingData.settingName,
			_settingData.pendingCreate,
			_settingData.locked,
			_settingData.rejected,
			_settingData.settingDataJSON
		);
	}

	 
	function getAssociatedTAOSetting(bytes32 _associatedTAOSettingId) public view returns (bytes32, address, uint256) {
		AssociatedTAOSetting memory _associatedTAOSetting = associatedTAOSettings[_associatedTAOSettingId];
		return (
			_associatedTAOSetting.associatedTAOSettingId,
			_associatedTAOSetting.associatedTAOId,
			_associatedTAOSetting.settingId
		);
	}

	 
	function getCreatorTAOSetting(bytes32 _creatorTAOSettingId) public view returns (bytes32, address, uint256) {
		CreatorTAOSetting memory _creatorTAOSetting = creatorTAOSettings[_creatorTAOSettingId];
		return (
			_creatorTAOSetting.creatorTAOSettingId,
			_creatorTAOSetting.creatorTAOId,
			_creatorTAOSetting.settingId
		);
	}

	 
	function approveAdd(uint256 _settingId, address _associatedTAOAdvocate, bool _approved) external inWhitelist returns (bool) {
		 
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == true &&
			_settingData.locked == true &&
			_settingData.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.associatedTAOId)
		);

		if (_approved) {
			 
			_settingData.locked = false;
		} else {
			 
			_settingData.pendingCreate = false;
			_settingData.rejected = true;
		}

		return true;
	}

	 
	function finalizeAdd(uint256 _settingId, address _creatorTAOAdvocate) external inWhitelist returns (bool) {
		 
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == true &&
			_settingData.locked == false &&
			_settingData.rejected == false &&
			_creatorTAOAdvocate != address(0) &&
			_creatorTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.creatorTAOId)
		);

		 
		_settingData.pendingCreate = false;
		_settingData.locked = true;

		return true;
	}

	 
	function update(uint256 _settingId, address _associatedTAOAdvocate, address _proposalTAOId, string calldata _extraData) external inWhitelist returns (bool) {
		 
		SettingData memory _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == false &&
			_settingData.locked == true &&
			_settingData.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.associatedTAOId)
		);

		 
		SettingState storage _settingState = settingStates[_settingId];
		require (_settingState.pendingUpdate == false);

		 
		SettingDeprecation memory _settingDeprecation = settingDeprecations[_settingId];
		if (_settingDeprecation.settingId == _settingId) {
			require (_settingDeprecation.migrated == false);
		}

		 
		_settingState.pendingUpdate = true;
		_settingState.updateAdvocateNameId = _associatedTAOAdvocate;
		_settingState.proposalTAOId = _proposalTAOId;
		_settingState.settingStateJSON = _extraData;

		return true;
	}

	 
	function getSettingState(uint256 _settingId) external view returns (uint256, bool, address, address, address, string memory) {
		SettingState memory _settingState = settingStates[_settingId];
		return (
			_settingState.settingId,
			_settingState.pendingUpdate,
			_settingState.updateAdvocateNameId,
			_settingState.proposalTAOId,
			_settingState.lastUpdateTAOId,
			_settingState.settingStateJSON
		);
	}

	 
	function approveUpdate(uint256 _settingId, address _proposalTAOAdvocate, bool _approved) external inWhitelist returns (bool) {
		 
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId && _settingData.pendingCreate == false && _settingData.locked == true && _settingData.rejected == false);

		 
		SettingState storage _settingState = settingStates[_settingId];
		require (_settingState.settingId == _settingId &&
			_settingState.pendingUpdate == true &&
			_proposalTAOAdvocate != address(0) &&
			_proposalTAOAdvocate == _nameTAOPosition.getAdvocate(_settingState.proposalTAOId)
		);

		if (_approved) {
			 
			_settingData.locked = false;
		} else {
			 
			_settingState.pendingUpdate = false;
			_settingState.proposalTAOId = address(0);
		}
		return true;
	}

	 
	function finalizeUpdate(uint256 _settingId, address _associatedTAOAdvocate) external inWhitelist returns (bool) {
		 
		SettingData storage _settingData = settingDatas[_settingId];
		require (_settingData.settingId == _settingId &&
			_settingData.pendingCreate == false &&
			_settingData.locked == false &&
			_settingData.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingData.associatedTAOId)
		);

		 
		SettingState storage _settingState = settingStates[_settingId];
		require (_settingState.settingId == _settingId && _settingState.pendingUpdate == true && _settingState.proposalTAOId != address(0));

		 
		_settingData.locked = true;

		 
		_settingState.pendingUpdate = false;
		_settingState.updateAdvocateNameId = _associatedTAOAdvocate;
		address _proposalTAOId = _settingState.proposalTAOId;
		_settingState.proposalTAOId = address(0);
		_settingState.lastUpdateTAOId = _proposalTAOId;

		return true;
	}

	 
	function addDeprecation(uint256 _settingId, address _creatorNameId, address _creatorTAOId, address _associatedTAOId, uint256 _newSettingId, address _newSettingContractAddress) external inWhitelist returns (bytes32, bytes32) {
		require (_storeSettingDeprecation(_settingId, _creatorNameId, _creatorTAOId, _associatedTAOId, _newSettingId, _newSettingContractAddress));

		 
		bytes32 _associatedTAOSettingDeprecationId = keccak256(abi.encodePacked(this, _associatedTAOId, _settingId));
		AssociatedTAOSettingDeprecation storage _associatedTAOSettingDeprecation = associatedTAOSettingDeprecations[_associatedTAOSettingDeprecationId];
		_associatedTAOSettingDeprecation.associatedTAOSettingDeprecationId = _associatedTAOSettingDeprecationId;
		_associatedTAOSettingDeprecation.associatedTAOId = _associatedTAOId;
		_associatedTAOSettingDeprecation.settingId = _settingId;

		 
		bytes32 _creatorTAOSettingDeprecationId = keccak256(abi.encodePacked(this, _creatorTAOId, _settingId));
		CreatorTAOSettingDeprecation storage _creatorTAOSettingDeprecation = creatorTAOSettingDeprecations[_creatorTAOSettingDeprecationId];
		_creatorTAOSettingDeprecation.creatorTAOSettingDeprecationId = _creatorTAOSettingDeprecationId;
		_creatorTAOSettingDeprecation.creatorTAOId = _creatorTAOId;
		_creatorTAOSettingDeprecation.settingId = _settingId;

		return (_associatedTAOSettingDeprecationId, _creatorTAOSettingDeprecationId);
	}

	 
	function getSettingDeprecation(uint256 _settingId) external view returns (uint256, address, address, address, bool, bool, bool, bool, uint256, uint256, address, address) {
		SettingDeprecation memory _settingDeprecation = settingDeprecations[_settingId];
		return (
			_settingDeprecation.settingId,
			_settingDeprecation.creatorNameId,
			_settingDeprecation.creatorTAOId,
			_settingDeprecation.associatedTAOId,
			_settingDeprecation.pendingDeprecated,
			_settingDeprecation.locked,
			_settingDeprecation.rejected,
			_settingDeprecation.migrated,
			_settingDeprecation.pendingNewSettingId,
			_settingDeprecation.newSettingId,
			_settingDeprecation.pendingNewSettingContractAddress,
			_settingDeprecation.newSettingContractAddress
		);
	}

	 
	function getAssociatedTAOSettingDeprecation(bytes32 _associatedTAOSettingDeprecationId) external view returns (bytes32, address, uint256) {
		AssociatedTAOSettingDeprecation memory _associatedTAOSettingDeprecation = associatedTAOSettingDeprecations[_associatedTAOSettingDeprecationId];
		return (
			_associatedTAOSettingDeprecation.associatedTAOSettingDeprecationId,
			_associatedTAOSettingDeprecation.associatedTAOId,
			_associatedTAOSettingDeprecation.settingId
		);
	}

	 
	function getCreatorTAOSettingDeprecation(bytes32 _creatorTAOSettingDeprecationId) public view returns (bytes32, address, uint256) {
		CreatorTAOSettingDeprecation memory _creatorTAOSettingDeprecation = creatorTAOSettingDeprecations[_creatorTAOSettingDeprecationId];
		return (
			_creatorTAOSettingDeprecation.creatorTAOSettingDeprecationId,
			_creatorTAOSettingDeprecation.creatorTAOId,
			_creatorTAOSettingDeprecation.settingId
		);
	}

	 
	function approveDeprecation(uint256 _settingId, address _associatedTAOAdvocate, bool _approved) external inWhitelist returns (bool) {
		 
		SettingDeprecation storage _settingDeprecation = settingDeprecations[_settingId];
		require (_settingDeprecation.settingId == _settingId &&
			_settingDeprecation.migrated == false &&
			_settingDeprecation.pendingDeprecated == true &&
			_settingDeprecation.locked == true &&
			_settingDeprecation.rejected == false &&
			_associatedTAOAdvocate != address(0) &&
			_associatedTAOAdvocate == _nameTAOPosition.getAdvocate(_settingDeprecation.associatedTAOId)
		);

		if (_approved) {
			 
			_settingDeprecation.locked = false;
		} else {
			 
			_settingDeprecation.pendingDeprecated = false;
			_settingDeprecation.rejected = true;
		}
		return true;
	}

	 
	function finalizeDeprecation(uint256 _settingId, address _creatorTAOAdvocate) external inWhitelist returns (bool) {
		 
		SettingDeprecation storage _settingDeprecation = settingDeprecations[_settingId];
		require (_settingDeprecation.settingId == _settingId &&
			_settingDeprecation.migrated == false &&
			_settingDeprecation.pendingDeprecated == true &&
			_settingDeprecation.locked == false &&
			_settingDeprecation.rejected == false &&
			_creatorTAOAdvocate != address(0) &&
			_creatorTAOAdvocate == _nameTAOPosition.getAdvocate(_settingDeprecation.creatorTAOId)
		);

		 
		_settingDeprecation.pendingDeprecated = false;
		_settingDeprecation.locked = true;
		_settingDeprecation.migrated = true;
		uint256 _newSettingId = _settingDeprecation.pendingNewSettingId;
		_settingDeprecation.pendingNewSettingId = 0;
		_settingDeprecation.newSettingId = _newSettingId;

		address _newSettingContractAddress = _settingDeprecation.pendingNewSettingContractAddress;
		_settingDeprecation.pendingNewSettingContractAddress = address(0);
		_settingDeprecation.newSettingContractAddress = _newSettingContractAddress;
		return true;
	}

	 
	function settingExist(uint256 _settingId) external view returns (bool) {
		SettingData memory _settingData = settingDatas[_settingId];
		return (_settingData.settingId == _settingId && _settingData.rejected == false);
	}

	 
	function getLatestSettingId(uint256 _settingId) external view returns (uint256) {
		uint256 _latestSettingId = _settingId;
		(,,,,,,, bool _migrated,, uint256 _newSettingId,,) = this.getSettingDeprecation(_latestSettingId);
		while (_migrated && _newSettingId > 0) {
			_latestSettingId = _newSettingId;
			(,,,,,,, _migrated,, _newSettingId,,) = this.getSettingDeprecation(_latestSettingId);
		}
		return _latestSettingId;
	}

	 
	 
	function _storeSettingDataState(uint256 _settingId, address _creatorNameId, string memory _settingName, address _creatorTAOId, address _associatedTAOId, string memory _extraData) internal returns (bool) {
		 
		SettingData storage _settingData = settingDatas[_settingId];
		_settingData.settingId = _settingId;
		_settingData.creatorNameId = _creatorNameId;
		_settingData.creatorTAOId = _creatorTAOId;
		_settingData.associatedTAOId = _associatedTAOId;
		_settingData.settingName = _settingName;
		_settingData.pendingCreate = true;
		_settingData.locked = true;
		_settingData.settingDataJSON = _extraData;

		 
		SettingState storage _settingState = settingStates[_settingId];
		_settingState.settingId = _settingId;
		return true;
	}

	 
	function _storeSettingDeprecation(uint256 _settingId, address _creatorNameId, address _creatorTAOId, address _associatedTAOId, uint256 _newSettingId, address _newSettingContractAddress) internal returns (bool) {
		 
		require (settingDatas[_settingId].creatorNameId != address(0) && settingDatas[_settingId].rejected == false && settingDatas[_settingId].pendingCreate == false);

		 
		require (settingDeprecations[_settingId].creatorNameId == address(0));

		 
		require (settingDatas[_newSettingId].creatorNameId != address(0) && settingDatas[_newSettingId].rejected == false && settingDatas[_newSettingId].pendingCreate == false);

		 
		SettingDeprecation storage _settingDeprecation = settingDeprecations[_settingId];
		_settingDeprecation.settingId = _settingId;
		_settingDeprecation.creatorNameId = _creatorNameId;
		_settingDeprecation.creatorTAOId = _creatorTAOId;
		_settingDeprecation.associatedTAOId = _associatedTAOId;
		_settingDeprecation.pendingDeprecated = true;
		_settingDeprecation.locked = true;
		_settingDeprecation.pendingNewSettingId = _newSettingId;
		_settingDeprecation.pendingNewSettingContractAddress = _newSettingContractAddress;
		return true;
	}

	 
	function _storeAssociatedTAOSetting(address _associatedTAOId, uint256 _settingId) internal returns (bytes32) {
		 
		bytes32 _associatedTAOSettingId = keccak256(abi.encodePacked(this, _associatedTAOId, _settingId));
		AssociatedTAOSetting storage _associatedTAOSetting = associatedTAOSettings[_associatedTAOSettingId];
		_associatedTAOSetting.associatedTAOSettingId = _associatedTAOSettingId;
		_associatedTAOSetting.associatedTAOId = _associatedTAOId;
		_associatedTAOSetting.settingId = _settingId;
		return _associatedTAOSettingId;
	}

	 
	function _storeCreatorTAOSetting(address _creatorTAOId, uint256 _settingId) internal returns (bytes32) {
		 
		bytes32 _creatorTAOSettingId = keccak256(abi.encodePacked(this, _creatorTAOId, _settingId));
		CreatorTAOSetting storage _creatorTAOSetting = creatorTAOSettings[_creatorTAOSettingId];
		_creatorTAOSetting.creatorTAOSettingId = _creatorTAOSettingId;
		_creatorTAOSetting.creatorTAOId = _creatorTAOId;
		_creatorTAOSetting.settingId = _settingId;
		return _creatorTAOSettingId;
	}
}