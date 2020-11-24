 

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


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }





 
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


interface INameAccountRecovery {
	function isCompromised(address _id) external view returns (bool);
}


interface INameFactory {
	function nonces(address _nameId) external view returns (uint256);
	function incrementNonce(address _nameId) external returns (uint256);
	function ethAddressToNameId(address _ethAddress) external view returns (address);
	function setNameNewAddress(address _id, address _newAddress) external returns (bool);
	function nameIdToEthAddress(address _nameId) external view returns (address);
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


interface ITAOFactory {
	function nonces(address _taoId) external view returns (uint256);
	function incrementNonce(address _taoId) external returns (uint256);
}


interface ITAOPool {
	function createPool(address _taoId, bool _ethosCapStatus, uint256 _ethosCapAmount) external returns (bool);
}













 
contract Name is TAO {
	 
	constructor (string memory _name, address _originId, string memory _datHash, string memory _database, string memory _keyValue, bytes32 _contentId, address _vaultAddress)
		TAO (_name, _originId, _datHash, _database, _keyValue, _contentId, _vaultAddress) public {
		 
		typeId = 1;
	}
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





 
contract TAOController is TheAO {
	address public nameFactoryAddress;
	address public nameAccountRecoveryAddress;

	INameFactory internal _nameFactory;
	INameTAOPosition internal _nameTAOPosition;
	INameAccountRecovery internal _nameAccountRecovery;

	 
	constructor(address _nameFactoryAddress) public {
		setNameFactoryAddress(_nameFactoryAddress);
	}

	 
	modifier onlyTheAO {
		require (AOLibrary.isTheAO(msg.sender, theAO, nameTAOPositionAddress));
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
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _id));
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



 
contract TAOPool is TAOController, ITAOPool {
	using SafeMath for uint256;

	address public taoFactoryAddress;
	address public pathosAddress;
	address public ethosAddress;
	address public logosAddress;

	ITAOFactory internal _taoFactory;
	TAOCurrency internal _pathos;
	TAOCurrency internal _ethos;
	Logos internal _logos;

	struct Pool {
		address taoId;
		 
		bool ethosCapStatus;
		uint256 ethosCapAmount;	 

		 
		bool status;
	}

	struct EthosLot {
		bytes32 ethosLotId;					 
		address nameId;						 
		uint256 lotQuantity;				 
		address taoId;						 
		uint256 poolPreStakeSnapshot;		 
		uint256 poolStakeLotSnapshot;		 
		uint256 lotValueInLogos;
		uint256 logosWithdrawn;				 
		uint256 timestamp;
	}

	uint256 public contractTotalEthosLot;		 
	uint256 public contractTotalPathosStake;	 
	uint256 public contractTotalEthos;			 
	uint256 public contractTotalPathos;			 
	uint256 public contractTotalLogosWithdrawn;		 

	 
	mapping (address => Pool) public pools;

	 
	mapping (bytes32 => EthosLot) public ethosLots;

	 
	mapping (address => uint256) public poolTotalEthosLot;

	 
	mapping (address => uint256) public poolTotalLogosWithdrawn;

	 
	mapping (address => bytes32[]) internal ownerEthosLots;

	 
	mapping (address => uint256) public totalEthosStaked;

	 
	mapping (address => uint256) public totalPathosStaked;

	 
	mapping (address => uint256) public totalLogosWithdrawn;

	 
	mapping (address => mapping (address => uint256)) public namePoolEthosStaked;

	 
	mapping (address => mapping (address => uint256)) public namePoolPathosStaked;

	 
	mapping (address => mapping (address => uint256)) public namePoolLogosWithdrawn;

	 
	event CreatePool(address indexed taoId, bool ethosCapStatus, uint256 ethosCapAmount, bool status);

	 
	 
	 
	event UpdatePoolStatus(address indexed taoId, bool status, uint256 nonce);

	 
	event UpdatePoolEthosCap(address indexed taoId, bool ethosCapStatus, uint256 ethosCapAmount, uint256 nonce);

	 
	event StakeEthos(address indexed taoId, bytes32 indexed ethosLotId, address indexed nameId, uint256 lotQuantity, uint256 poolPreStakeSnapshot, uint256 poolStakeLotSnapshot, uint256 lotValueInLogos, uint256 timestamp);

	 
	event StakePathos(address indexed taoId, bytes32 indexed stakeId, address indexed nameId, uint256 stakeQuantity, uint256 currentPoolTotalStakedPathos, uint256 timestamp);

	 
	event WithdrawLogos(address indexed nameId, bytes32 indexed ethosLotId, address indexed taoId, uint256 withdrawnAmount, uint256 currentLotValueInLogos, uint256 currentLotLogosWithdrawn, uint256 timestamp);

	 
	constructor(address _nameFactoryAddress, address _taoFactoryAddress, address _nameTAOPositionAddress, address _pathosAddress, address _ethosAddress, address _logosAddress)
		TAOController(_nameFactoryAddress) public {
		setTAOFactoryAddress(_taoFactoryAddress);
		setNameTAOPositionAddress(_nameTAOPositionAddress);
		setPathosAddress(_pathosAddress);
		setEthosAddress(_ethosAddress);
		setLogosAddress(_logosAddress);
	}

	 
	modifier onlyTAOFactory {
		require (msg.sender == taoFactoryAddress);
		_;
	}

	 
	 
	function setTAOFactoryAddress(address _taoFactoryAddress) public onlyTheAO {
		require (_taoFactoryAddress != address(0));
		taoFactoryAddress = _taoFactoryAddress;
		_taoFactory = ITAOFactory(_taoFactoryAddress);
	}

	 
	function setPathosAddress(address _pathosAddress) public onlyTheAO {
		require (_pathosAddress != address(0));
		pathosAddress = _pathosAddress;
		_pathos = TAOCurrency(_pathosAddress);
	}

	 
	function setEthosAddress(address _ethosAddress) public onlyTheAO {
		require (_ethosAddress != address(0));
		ethosAddress = _ethosAddress;
		_ethos = TAOCurrency(_ethosAddress);
	}

	 
	function setLogosAddress(address _logosAddress) public onlyTheAO {
		require (_logosAddress != address(0));
		logosAddress = _logosAddress;
		_logos = Logos(_logosAddress);
	}

	 
	 
	function isExist(address _id) public view returns (bool) {
		return pools[_id].taoId != address(0);
	}

	 
	function createPool(
		address _taoId,
		bool _ethosCapStatus,
		uint256 _ethosCapAmount
	) external isTAO(_taoId) onlyTAOFactory returns (bool) {
		 
		if (_ethosCapStatus) {
			require (_ethosCapAmount > 0);
		}
		 
		require (pools[_taoId].taoId == address(0));

		Pool storage _pool = pools[_taoId];
		_pool.taoId = _taoId;
		_pool.status = true;
		_pool.ethosCapStatus = _ethosCapStatus;
		if (_ethosCapStatus) {
			_pool.ethosCapAmount = _ethosCapAmount;
		}

		emit CreatePool(_pool.taoId, _pool.ethosCapStatus, _pool.ethosCapAmount, _pool.status);
		return true;
	}

	 
	function updatePoolStatus(address _taoId, bool _status) public isTAO(_taoId) onlyAdvocate(_taoId) senderNameNotCompromised {
		require (pools[_taoId].taoId != address(0));
		pools[_taoId].status = _status;

		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);

		emit UpdatePoolStatus(_taoId, _status, _nonce);
	}

	 
	function updatePoolEthosCap(address _taoId, bool _ethosCapStatus, uint256 _ethosCapAmount) public isTAO(_taoId) onlyAdvocate(_taoId) senderNameNotCompromised {
		require (pools[_taoId].taoId != address(0));
		 
		if (_ethosCapStatus) {
			require (_ethosCapAmount > 0 && _ethosCapAmount > _pathos.balanceOf(_taoId));
		}

		pools[_taoId].ethosCapStatus = _ethosCapStatus;
		if (_ethosCapStatus) {
			pools[_taoId].ethosCapAmount = _ethosCapAmount;
		}

		uint256 _nonce = _taoFactory.incrementNonce(_taoId);
		require (_nonce > 0);

		emit UpdatePoolEthosCap(_taoId, _ethosCapStatus, _ethosCapAmount, _nonce);
	}

	 
	function stakeEthos(address _taoId, uint256 _quantity) public isTAO(_taoId) senderIsName senderNameNotCompromised {
		Pool memory _pool = pools[_taoId];
		address _nameId = _nameFactory.ethAddressToNameId(msg.sender);
		require (_pool.status == true && _quantity > 0 && _ethos.balanceOf(_nameId) >= _quantity);

		 
		if (_pool.ethosCapStatus) {
			require (_ethos.balanceOf(_taoId).add(_quantity) <= _pool.ethosCapAmount);
		}

		 
		contractTotalEthosLot++;
		poolTotalEthosLot[_taoId]++;

		 
		bytes32 _ethosLotId = keccak256(abi.encodePacked(this, msg.sender, contractTotalEthosLot));

		EthosLot storage _ethosLot = ethosLots[_ethosLotId];
		_ethosLot.ethosLotId = _ethosLotId;
		_ethosLot.nameId = _nameId;
		_ethosLot.lotQuantity = _quantity;
		_ethosLot.taoId = _taoId;
		_ethosLot.poolPreStakeSnapshot = _ethos.balanceOf(_taoId);
		_ethosLot.poolStakeLotSnapshot = _ethos.balanceOf(_taoId).add(_quantity);
		_ethosLot.lotValueInLogos = _quantity;
		_ethosLot.timestamp = now;

		ownerEthosLots[_nameId].push(_ethosLotId);

		 
		totalEthosStaked[_nameId] = totalEthosStaked[_nameId].add(_quantity);
		namePoolEthosStaked[_nameId][_taoId] = namePoolEthosStaked[_nameId][_taoId].add(_quantity);
		contractTotalEthos = contractTotalEthos.add(_quantity);

		require (_ethos.transferFrom(_nameId, _taoId, _quantity));

		emit StakeEthos(_ethosLot.taoId, _ethosLot.ethosLotId, _ethosLot.nameId, _ethosLot.lotQuantity, _ethosLot.poolPreStakeSnapshot, _ethosLot.poolStakeLotSnapshot, _ethosLot.lotValueInLogos, _ethosLot.timestamp);
	}

	 
	function ownerTotalEthosLot(address _nameId) public view returns (uint256) {
		return ownerEthosLots[_nameId].length;
	}

	 
	function ownerEthosLotIds(address _nameId, uint256 _from, uint256 _to) public view returns (bytes32[] memory) {
		require (_from >= 0 && _to >= _from && ownerEthosLots[_nameId].length > _to);
		bytes32[] memory _ethosLotIds = new bytes32[](_to.sub(_from).add(1));
		for (uint256 i = _from; i <= _to; i++) {
			_ethosLotIds[i.sub(_from)] = ownerEthosLots[_nameId][i];
		}
		return _ethosLotIds;
	}

	 
	function availablePathosToStake(address _taoId) public isTAO(_taoId) view returns (uint256) {
		if (pools[_taoId].status == true) {
			return _ethos.balanceOf(_taoId).sub(_pathos.balanceOf(_taoId));
		} else {
			return 0;
		}
	}

	 
	function stakePathos(address _taoId, uint256 _quantity) public isTAO(_taoId) senderIsName senderNameNotCompromised {
		Pool memory _pool = pools[_taoId];
		address _nameId = _nameFactory.ethAddressToNameId(msg.sender);
		require (_pool.status == true && _quantity > 0 && _pathos.balanceOf(_nameId) >= _quantity && _quantity <= availablePathosToStake(_taoId));

		 
		contractTotalPathosStake++;
		totalPathosStaked[_nameId] = totalPathosStaked[_nameId].add(_quantity);
		namePoolPathosStaked[_nameId][_taoId] = namePoolPathosStaked[_nameId][_taoId].add(_quantity);
		contractTotalPathos = contractTotalPathos.add(_quantity);

		 
		bytes32 _stakeId = keccak256(abi.encodePacked(this, msg.sender, contractTotalPathosStake));

		require (_pathos.transferFrom(_nameId, _taoId, _quantity));

		 
		require (_logos.addAdvocatedTAOLogos(_taoId, _quantity));

		emit StakePathos(_taoId, _stakeId, _nameId, _quantity, _pathos.balanceOf(_taoId), now);
	}

	 
	function withdrawLogos(bytes32 _ethosLotId) public senderIsName senderNameNotCompromised {
		EthosLot storage _ethosLot = ethosLots[_ethosLotId];
		address _nameId = _nameFactory.ethAddressToNameId(msg.sender);
		require (_ethosLot.nameId == _nameId && _ethosLot.lotValueInLogos > 0);

		uint256 logosAvailableToWithdraw = lotLogosAvailableToWithdraw(_ethosLotId);

		require (logosAvailableToWithdraw > 0 && logosAvailableToWithdraw <= _ethosLot.lotValueInLogos);

		 
		_ethosLot.logosWithdrawn = _ethosLot.logosWithdrawn.add(logosAvailableToWithdraw);
		_ethosLot.lotValueInLogos = _ethosLot.lotValueInLogos.sub(logosAvailableToWithdraw);

		 
		contractTotalLogosWithdrawn = contractTotalLogosWithdrawn.add(logosAvailableToWithdraw);
		poolTotalLogosWithdrawn[_ethosLot.taoId] = poolTotalLogosWithdrawn[_ethosLot.taoId].add(logosAvailableToWithdraw);
		totalLogosWithdrawn[_ethosLot.nameId] = totalLogosWithdrawn[_ethosLot.nameId].add(logosAvailableToWithdraw);
		namePoolLogosWithdrawn[_ethosLot.nameId][_ethosLot.taoId] = namePoolLogosWithdrawn[_ethosLot.nameId][_ethosLot.taoId].add(logosAvailableToWithdraw);

		 
		require (_logos.mint(_nameId, logosAvailableToWithdraw));

		emit WithdrawLogos(_ethosLot.nameId, _ethosLot.ethosLotId, _ethosLot.taoId, logosAvailableToWithdraw, _ethosLot.lotValueInLogos, _ethosLot.logosWithdrawn, now);
	}

	 
	function lotLogosAvailableToWithdraw(bytes32 _ethosLotId) public view returns (uint256) {
		EthosLot memory _ethosLot = ethosLots[_ethosLotId];
		require (_ethosLot.nameId != address(0));

		uint256 logosAvailableToWithdraw = 0;

		if (_pathos.balanceOf(_ethosLot.taoId) > _ethosLot.poolPreStakeSnapshot && _ethosLot.lotValueInLogos > 0) {
			logosAvailableToWithdraw = (_pathos.balanceOf(_ethosLot.taoId) >= _ethosLot.poolStakeLotSnapshot) ? _ethosLot.lotQuantity : _pathos.balanceOf(_ethosLot.taoId).sub(_ethosLot.poolPreStakeSnapshot);
			if (logosAvailableToWithdraw > 0) {
				logosAvailableToWithdraw = logosAvailableToWithdraw.sub(_ethosLot.logosWithdrawn);
			}
		}
		return logosAvailableToWithdraw;
	}
}