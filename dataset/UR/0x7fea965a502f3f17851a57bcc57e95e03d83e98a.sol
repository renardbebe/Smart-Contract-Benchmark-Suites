 

pragma solidity >=0.5.4 <0.6.0;

interface IAOSetting {
	function getSettingValuesByTAOName(address _taoId, string calldata _settingName) external view returns (uint256, bool, address, bytes32, string memory);
	function getSettingTypes() external view returns (uint8, uint8, uint8, uint8, uint8);

	function settingTypeLookup(uint256 _settingId) external view returns (uint8);
}


interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external; }


interface IAOIonLot {
	function createPrimordialLot(address _account, uint256 _primordialAmount, uint256 _multiplier, uint256 _networkBonusAmount) external returns (bytes32);

	function createWeightedMultiplierLot(address _account, uint256 _amount, uint256 _weightedMultiplier) external returns (bytes32);

	function lotById(bytes32 _lotId) external view returns (bytes32, address, uint256, uint256);

	function totalLotsByAddress(address _lotOwner) external view returns (uint256);

	function createBurnLot(address _account, uint256 _amount, uint256 _multiplierAfterBurn) external returns (bool);

	function createConvertLot(address _account, uint256 _amount, uint256 _multiplierAfterConversion) external returns (bool);
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





















 
contract AOIon is AOIonInterface {
	using SafeMath for uint256;

	address public aoIonLotAddress;
	address public settingTAOId;
	address public aoSettingAddress;
	address public aoethAddress;

	 
	address public aoDevTeam1 = 0x146CbD9821e6A42c8ff6DC903fe91CB69625A105;
	address public aoDevTeam2 = 0x4810aF1dA3aC827259eEa72ef845F4206C703E8D;

	IAOIonLot internal _aoIonLot;
	IAOSetting internal _aoSetting;
	AOETH internal _aoeth;

	 
	uint256 public primordialTotalSupply;
	uint256 public primordialTotalBought;
	uint256 public primordialSellPrice;
	uint256 public primordialBuyPrice;
	uint256 public totalEthForPrimordial;	 
	uint256 public totalRedeemedAOETH;		 

	 
	uint256 constant public TOTAL_PRIMORDIAL_FOR_SALE = 3377699720527872;

	mapping (address => uint256) public primordialBalanceOf;
	mapping (address => mapping (address => uint256)) public primordialAllowance;

	 
	mapping (address => mapping (uint256 => uint256)) public primordialStakedBalance;

	event PrimordialTransfer(address indexed from, address indexed to, uint256 value);
	event PrimordialApproval(address indexed _owner, address indexed _spender, uint256 _value);
	event PrimordialBurn(address indexed from, uint256 value);
	event PrimordialStake(address indexed from, uint256 value, uint256 weightedMultiplier);
	event PrimordialUnstake(address indexed from, uint256 value, uint256 weightedMultiplier);

	event NetworkExchangeEnded();

	bool public networkExchangeEnded;

	 
	mapping (address => uint256) internal ownerWeightedMultiplier;

	 
	mapping (address => uint256) internal ownerMaxMultiplier;

	 
	 
	 
	event BuyPrimordial(address indexed lotOwner, bytes32 indexed lotId, uint8 payWith, uint256 sentAmount, uint256 refundedAmount);

	 
	constructor(string memory _name, string memory _symbol, address _settingTAOId, address _aoSettingAddress, address _nameTAOPositionAddress, address _namePublicKeyAddress, address _nameAccountRecoveryAddress)
		AOIonInterface(_name, _symbol, _nameTAOPositionAddress, _namePublicKeyAddress, _nameAccountRecoveryAddress) public {
		setSettingTAOId(_settingTAOId);
		setAOSettingAddress(_aoSettingAddress);

		powerOfTen = 0;
		decimals = 0;
		setPrimordialPrices(0, 10 ** 8);  
	}

	 
	modifier canBuyPrimordial(uint256 _sentAmount, bool _withETH) {
		require (networkExchangeEnded == false &&
			primordialTotalBought < TOTAL_PRIMORDIAL_FOR_SALE &&
			primordialBuyPrice > 0 &&
			_sentAmount > 0 &&
			availablePrimordialForSaleInETH() > 0 &&
			(
				(_withETH && availableETH() > 0) ||
				(!_withETH && totalRedeemedAOETH < _aoeth.totalSupply())
			)
		);
		_;
	}

	 
	 
	function setAOIonLotAddress(address _aoIonLotAddress) public onlyTheAO {
		require (_aoIonLotAddress != address(0));
		aoIonLotAddress = _aoIonLotAddress;
		_aoIonLot = IAOIonLot(_aoIonLotAddress);
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

	 
	function setAODevTeamAddresses(address _aoDevTeam1, address _aoDevTeam2) public onlyTheAO {
		aoDevTeam1 = _aoDevTeam1;
		aoDevTeam2 = _aoDevTeam2;
	}

	 
	function setAOETHAddress(address _aoethAddress) public onlyTheAO {
		require (_aoethAddress != address(0));
		aoethAddress = _aoethAddress;
		_aoeth = AOETH(_aoethAddress);
	}

	 
	 
	function setPrimordialPrices(uint256 newPrimordialSellPrice, uint256 newPrimordialBuyPrice) public onlyTheAO {
		primordialSellPrice = newPrimordialSellPrice;
		primordialBuyPrice = newPrimordialBuyPrice;
	}

	 
	function endNetworkExchange() public onlyTheAO {
		require (!networkExchangeEnded);
		networkExchangeEnded = true;
		emit NetworkExchangeEnded();
	}

	 
	 
	function stakePrimordialFrom(address _from, uint256 _value, uint256 _weightedMultiplier) public inWhitelist returns (bool) {
		 
		require (primordialBalanceOf[_from] >= _value);
		 
		require (_weightedMultiplier == ownerWeightedMultiplier[_from]);
		 
		primordialBalanceOf[_from] = primordialBalanceOf[_from].sub(_value);
		 
		primordialStakedBalance[_from][_weightedMultiplier] = primordialStakedBalance[_from][_weightedMultiplier].add(_value);
		emit PrimordialStake(_from, _value, _weightedMultiplier);
		return true;
	}

	 
	function unstakePrimordialFrom(address _from, uint256 _value, uint256 _weightedMultiplier) public inWhitelist returns (bool) {
		 
		require (primordialStakedBalance[_from][_weightedMultiplier] >= _value);
		 
		primordialStakedBalance[_from][_weightedMultiplier] = primordialStakedBalance[_from][_weightedMultiplier].sub(_value);
		 
		primordialBalanceOf[_from] = primordialBalanceOf[_from].add(_value);
		emit PrimordialUnstake(_from, _value, _weightedMultiplier);
		return true;
	}

	 
	function whitelistTransferPrimordialFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool) {
		return _createLotAndTransferPrimordial(_from, _to, _value);
	}

	 
	 
	 
	function buyPrimordial() public payable canBuyPrimordial(msg.value, true) {
		(uint256 amount, uint256 remainderBudget, bool shouldEndNetworkExchange) = _calculateAmountAndRemainderBudget(msg.value, true);
		require (amount > 0);

		 
		if (shouldEndNetworkExchange) {
			networkExchangeEnded = true;
			emit NetworkExchangeEnded();
		}

		 
		totalEthForPrimordial = totalEthForPrimordial.add(msg.value.sub(remainderBudget));

		 
		bytes32 _lotId = _sendPrimordialAndRewardDev(amount, msg.sender);

		emit BuyPrimordial(msg.sender, _lotId, 1, msg.value, remainderBudget);

		 
		if (remainderBudget > 0) {
			msg.sender.transfer(remainderBudget);
		}
	}

	 
	function buyPrimordialWithAOETH(uint256 _aoethAmount) public canBuyPrimordial(_aoethAmount, false) {
		(uint256 amount, uint256 remainderBudget, bool shouldEndNetworkExchange) = _calculateAmountAndRemainderBudget(_aoethAmount, false);
		require (amount > 0);

		 
		if (shouldEndNetworkExchange) {
			networkExchangeEnded = true;
			emit NetworkExchangeEnded();
		}

		 
		uint256 actualCharge = _aoethAmount.sub(remainderBudget);

		 
		totalRedeemedAOETH = totalRedeemedAOETH.add(actualCharge);

		 
		require (_aoeth.whitelistTransferFrom(msg.sender, address(this), actualCharge));

		 
		bytes32 _lotId = _sendPrimordialAndRewardDev(amount, msg.sender);

		emit BuyPrimordial(msg.sender, _lotId, 2, _aoethAmount, remainderBudget);
	}

	 
	function transferPrimordial(address _to, uint256 _value) public returns (bool) {
		return _createLotAndTransferPrimordial(msg.sender, _to, _value);
	}

	 
	function transferPrimordialFrom(address _from, address _to, uint256 _value) public returns (bool) {
		require (_value <= primordialAllowance[_from][msg.sender]);
		primordialAllowance[_from][msg.sender] = primordialAllowance[_from][msg.sender].sub(_value);

		return _createLotAndTransferPrimordial(_from, _to, _value);
	}

	 
	function transferPrimordialBetweenPublicKeys(address _nameId, address _from, address _to, uint256 _value) public returns (bool) {
		require (AOLibrary.isName(_nameId));
		require (_nameTAOPosition.senderIsAdvocate(msg.sender, _nameId));
		require (!_nameAccountRecovery.isCompromised(_nameId));
		 
		require (_namePublicKey.isKeyExist(_nameId, _from));
		 
		require (_namePublicKey.isKeyExist(_nameId, _to));
		return _createLotAndTransferPrimordial(_from, _to, _value);
	}

	 
	function approvePrimordial(address _spender, uint256 _value) public returns (bool) {
		primordialAllowance[msg.sender][_spender] = _value;
		emit PrimordialApproval(msg.sender, _spender, _value);
		return true;
	}

	 
	function approvePrimordialAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool) {
		tokenRecipient spender = tokenRecipient(_spender);
		if (approvePrimordial(_spender, _value)) {
			spender.receiveApproval(msg.sender, _value, address(this), _extraData);
			return true;
		}
	}

	 
	function burnPrimordial(uint256 _value) public returns (bool) {
		require (primordialBalanceOf[msg.sender] >= _value);
		require (calculateMaximumBurnAmount(msg.sender) >= _value);

		 
		ownerWeightedMultiplier[msg.sender] = calculateMultiplierAfterBurn(msg.sender, _value);
		primordialBalanceOf[msg.sender] = primordialBalanceOf[msg.sender].sub(_value);
		primordialTotalSupply = primordialTotalSupply.sub(_value);

		 
		require (_aoIonLot.createBurnLot(msg.sender, _value, ownerWeightedMultiplier[msg.sender]));
		emit PrimordialBurn(msg.sender, _value);
		return true;
	}

	 
	function burnPrimordialFrom(address _from, uint256 _value) public returns (bool) {
		require (primordialBalanceOf[_from] >= _value);
		require (primordialAllowance[_from][msg.sender] >= _value);
		require (calculateMaximumBurnAmount(_from) >= _value);

		 
		ownerWeightedMultiplier[_from] = calculateMultiplierAfterBurn(_from, _value);
		primordialBalanceOf[_from] = primordialBalanceOf[_from].sub(_value);
		primordialAllowance[_from][msg.sender] = primordialAllowance[_from][msg.sender].sub(_value);
		primordialTotalSupply = primordialTotalSupply.sub(_value);

		 
		require (_aoIonLot.createBurnLot(_from, _value, ownerWeightedMultiplier[_from]));
		emit PrimordialBurn(_from, _value);
		return true;
	}

	 
	function weightedMultiplierByAddress(address _lotOwner) public view returns (uint256) {
		return ownerWeightedMultiplier[_lotOwner];
	}

	 
	function maxMultiplierByAddress(address _target) public view returns (uint256) {
		return (_aoIonLot.totalLotsByAddress(_target) > 0) ? ownerMaxMultiplier[_target] : 0;
	}

	 
	function calculateMultiplierAndBonus(uint256 _purchaseAmount) public view returns (uint256, uint256, uint256) {
		(uint256 startingPrimordialMultiplier, uint256 endingPrimordialMultiplier, uint256 startingNetworkBonusMultiplier, uint256 endingNetworkBonusMultiplier) = _getSettingVariables();
		return (
			AOLibrary.calculatePrimordialMultiplier(_purchaseAmount, TOTAL_PRIMORDIAL_FOR_SALE, primordialTotalBought, startingPrimordialMultiplier, endingPrimordialMultiplier),
			AOLibrary.calculateNetworkBonusPercentage(_purchaseAmount, TOTAL_PRIMORDIAL_FOR_SALE, primordialTotalBought, startingNetworkBonusMultiplier, endingNetworkBonusMultiplier),
			AOLibrary.calculateNetworkBonusAmount(_purchaseAmount, TOTAL_PRIMORDIAL_FOR_SALE, primordialTotalBought, startingNetworkBonusMultiplier, endingNetworkBonusMultiplier)
		);
	}

	 
	function calculateMaximumBurnAmount(address _account) public view returns (uint256) {
		return AOLibrary.calculateMaximumBurnAmount(primordialBalanceOf[_account], ownerWeightedMultiplier[_account], ownerMaxMultiplier[_account]);
	}

	 
	function calculateMultiplierAfterBurn(address _account, uint256 _amountToBurn) public view returns (uint256) {
		require (calculateMaximumBurnAmount(_account) >= _amountToBurn);
		return AOLibrary.calculateMultiplierAfterBurn(primordialBalanceOf[_account], ownerWeightedMultiplier[_account], _amountToBurn);
	}

	 
	function calculateMultiplierAfterConversion(address _account, uint256 _amountToConvert) public view returns (uint256) {
		return AOLibrary.calculateMultiplierAfterConversion(primordialBalanceOf[_account], ownerWeightedMultiplier[_account], _amountToConvert);
	}

	 
	function convertToPrimordial(uint256 _value) public returns (bool) {
		require (balanceOf[msg.sender] >= _value);

		 
		ownerWeightedMultiplier[msg.sender] = calculateMultiplierAfterConversion(msg.sender, _value);
		 
		burn(_value);
		 
		_mintPrimordial(msg.sender, _value);

		require (_aoIonLot.createConvertLot(msg.sender, _value, ownerWeightedMultiplier[msg.sender]));
		return true;
	}

	 
	function availablePrimordialForSale() public view returns (uint256) {
		return TOTAL_PRIMORDIAL_FOR_SALE.sub(primordialTotalBought);
	}

	 
	function availablePrimordialForSaleInETH() public view returns (uint256) {
		return availablePrimordialForSale().mul(primordialBuyPrice);
	}

	 
	function availableETH() public view returns (uint256) {
		if (availablePrimordialForSaleInETH() > 0) {
			uint256 _availableETH = availablePrimordialForSaleInETH().sub(_aoeth.totalSupply().sub(totalRedeemedAOETH));
			if (availablePrimordialForSale() == 1 && _availableETH < primordialBuyPrice) {
				return primordialBuyPrice;
			} else {
				return _availableETH;
			}
		} else {
			return 0;
		}
	}

	 
	 
	 
	function _calculateAmountAndRemainderBudget(uint256 _budget, bool _withETH) internal view returns (uint256, uint256, bool) {
		 
		uint256 amount = _budget.div(primordialBuyPrice);

		 
		 
		uint256 remainderEth = _budget.sub(amount.mul(primordialBuyPrice));

		uint256 _availableETH = availableETH();
		 
		if (_withETH && _budget > availableETH()) {
			 
			amount = _availableETH.div(primordialBuyPrice);
			remainderEth = _budget.sub(amount.mul(primordialBuyPrice));
		}

		 
		bool shouldEndNetworkExchange = false;
		if (primordialTotalBought.add(amount) >= TOTAL_PRIMORDIAL_FOR_SALE) {
			amount = TOTAL_PRIMORDIAL_FOR_SALE.sub(primordialTotalBought);
			shouldEndNetworkExchange = true;
			remainderEth = _budget.sub(amount.mul(primordialBuyPrice));
		}
		return (amount, remainderEth, shouldEndNetworkExchange);
	}

	 
	function _sendPrimordialAndRewardDev(uint256 amount, address to) internal returns (bytes32) {
		(uint256 startingPrimordialMultiplier,, uint256 startingNetworkBonusMultiplier, uint256 endingNetworkBonusMultiplier) = _getSettingVariables();

		 
		(uint256 multiplier, uint256 networkBonusPercentage, uint256 networkBonusAmount) = calculateMultiplierAndBonus(amount);
		primordialTotalBought = primordialTotalBought.add(amount);
		bytes32 _lotId = _createPrimordialLot(to, amount, multiplier, networkBonusAmount);

		 
		uint256 inverseMultiplier = startingPrimordialMultiplier.sub(multiplier);  
		uint256 theAONetworkBonusAmount = (startingNetworkBonusMultiplier.sub(networkBonusPercentage).add(endingNetworkBonusMultiplier)).mul(amount).div(AOLibrary.PERCENTAGE_DIVISOR());
		if (aoDevTeam1 != address(0)) {
			_createPrimordialLot(aoDevTeam1, amount.div(2), inverseMultiplier, theAONetworkBonusAmount.div(2));
		}
		if (aoDevTeam2 != address(0)) {
			_createPrimordialLot(aoDevTeam2, amount.div(2), inverseMultiplier, theAONetworkBonusAmount.div(2));
		}
		_mint(theAO, theAONetworkBonusAmount);
		return _lotId;
	}

	 
	function _createPrimordialLot(address _account, uint256 _primordialAmount, uint256 _multiplier, uint256 _networkBonusAmount) internal returns (bytes32) {
		bytes32 lotId = _aoIonLot.createPrimordialLot(_account, _primordialAmount, _multiplier, _networkBonusAmount);

		ownerWeightedMultiplier[_account] = AOLibrary.calculateWeightedMultiplier(ownerWeightedMultiplier[_account], primordialBalanceOf[_account], _multiplier, _primordialAmount);

		 
		if (_aoIonLot.totalLotsByAddress(_account) == 1) {
			ownerMaxMultiplier[_account] = _multiplier;
		}
		_mintPrimordial(_account, _primordialAmount);
		_mint(_account, _networkBonusAmount);

		return lotId;
	}

	 
	function _mintPrimordial(address target, uint256 mintedAmount) internal {
		primordialBalanceOf[target] = primordialBalanceOf[target].add(mintedAmount);
		primordialTotalSupply = primordialTotalSupply.add(mintedAmount);
		emit PrimordialTransfer(address(0), address(this), mintedAmount);
		emit PrimordialTransfer(address(this), target, mintedAmount);
	}

	 
	function _createWeightedMultiplierLot(address _account, uint256 _amount, uint256 _weightedMultiplier) internal returns (bytes32) {
		require (_account != address(0));
		require (_amount > 0);

		bytes32 lotId = _aoIonLot.createWeightedMultiplierLot(_account, _amount, _weightedMultiplier);
		 
		if (_aoIonLot.totalLotsByAddress(_account) == 1) {
			ownerMaxMultiplier[_account] = _weightedMultiplier;
		}
		return lotId;
	}

	 
	function _createLotAndTransferPrimordial(address _from, address _to, uint256 _value) internal returns (bool) {
		bytes32 _createdLotId = _createWeightedMultiplierLot(_to, _value, ownerWeightedMultiplier[_from]);
		(, address _lotOwner,,) = _aoIonLot.lotById(_createdLotId);

		 
		require (_lotOwner == _to);

		 
		ownerWeightedMultiplier[_to] = AOLibrary.calculateWeightedMultiplier(ownerWeightedMultiplier[_to], primordialBalanceOf[_to], ownerWeightedMultiplier[_from], _value);

		 
		require (_transferPrimordial(_from, _to, _value));
		return true;
	}

	 
	function _transferPrimordial(address _from, address _to, uint256 _value) internal returns (bool) {
		require (_to != address(0));									 
		require (primordialBalanceOf[_from] >= _value);						 
		require (primordialBalanceOf[_to].add(_value) >= primordialBalanceOf[_to]);	 
		require (!frozenAccount[_from]);								 
		require (!frozenAccount[_to]);									 
		uint256 previousBalances = primordialBalanceOf[_from].add(primordialBalanceOf[_to]);
		primordialBalanceOf[_from] = primordialBalanceOf[_from].sub(_value);			 
		primordialBalanceOf[_to] = primordialBalanceOf[_to].add(_value);				 
		emit PrimordialTransfer(_from, _to, _value);
		assert(primordialBalanceOf[_from].add(primordialBalanceOf[_to]) == previousBalances);
		return true;
	}

	 
	function _getSettingVariables() internal view returns (uint256, uint256, uint256, uint256) {
		(uint256 startingPrimordialMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, 'startingPrimordialMultiplier');
		(uint256 endingPrimordialMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, 'endingPrimordialMultiplier');

		(uint256 startingNetworkBonusMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, 'startingNetworkBonusMultiplier');
		(uint256 endingNetworkBonusMultiplier,,,,) = _aoSetting.getSettingValuesByTAOName(settingTAOId, 'endingNetworkBonusMultiplier');

		return (startingPrimordialMultiplier, endingPrimordialMultiplier, startingNetworkBonusMultiplier, endingNetworkBonusMultiplier);
	}
}


 
contract AOETH is TheAO, TokenERC20, tokenRecipient {
	using SafeMath for uint256;

	address public aoIonAddress;

	AOIon internal _aoIon;

	uint256 public totalERC20Tokens;
	uint256 public totalTokenExchanges;

	struct ERC20Token {
		address tokenAddress;
		uint256 price;			 
		uint256 maxQuantity;	 
		uint256 exchangedQuantity;	 
		bool active;
	}

	struct TokenExchange {
		bytes32 exchangeId;
		address buyer;			 
		address tokenAddress;	 
		uint256 price;			 
		uint256 sentAmount;		 
		uint256 receivedAmount;	 
		bytes extraData;  
	}

	 
	mapping (uint256 => ERC20Token) internal erc20Tokens;
	mapping (address => uint256) internal erc20TokenIdLookup;

	 
	mapping (uint256 => TokenExchange) internal tokenExchanges;
	mapping (bytes32 => uint256) internal tokenExchangeIdLookup;
	mapping (address => uint256) public totalAddressTokenExchanges;

	 
	event AddERC20Token(address indexed tokenAddress, uint256 price, uint256 maxQuantity);

	 
	event SetPrice(address indexed tokenAddress, uint256 price);

	 
	event SetMaxQuantity(address indexed tokenAddress, uint256 maxQuantity);

	 
	event SetActive(address indexed tokenAddress, bool active);

	 
	event ExchangeToken(bytes32 indexed exchangeId, address indexed from, address tokenAddress, string tokenName, string tokenSymbol, uint256 sentTokenAmount, uint256 receivedAOETHAmount, bytes extraData);

	 
	constructor(uint256 initialSupply, string memory tokenName, string memory tokenSymbol, address _aoIonAddress, address _nameTAOPositionAddress)
		TokenERC20(initialSupply, tokenName, tokenSymbol) public {
		setAOIonAddress(_aoIonAddress);
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

	 
	function setAOIonAddress(address _aoIonAddress) public onlyTheAO {
		require (_aoIonAddress != address(0));
		aoIonAddress = _aoIonAddress;
		_aoIon = AOIon(_aoIonAddress);
	}

	 
	function setNameTAOPositionAddress(address _nameTAOPositionAddress) public onlyTheAO {
		require (_nameTAOPositionAddress != address(0));
		nameTAOPositionAddress = _nameTAOPositionAddress;
	}

	 
	function transferERC20(address _erc20TokenAddress, address _recipient, uint256 _amount) public onlyTheAO {
		TokenERC20 _erc20 = TokenERC20(_erc20TokenAddress);
		require (_erc20.transfer(_recipient, _amount));
	}

	 
	function addERC20Token(address _tokenAddress, uint256 _price, uint256 _maxQuantity) public onlyTheAO {
		require (_tokenAddress != address(0) && _price > 0 && _maxQuantity > 0);
		require (AOLibrary.isValidERC20TokenAddress(_tokenAddress));
		require (erc20TokenIdLookup[_tokenAddress] == 0);

		totalERC20Tokens++;
		erc20TokenIdLookup[_tokenAddress] = totalERC20Tokens;
		ERC20Token storage _erc20Token = erc20Tokens[totalERC20Tokens];
		_erc20Token.tokenAddress = _tokenAddress;
		_erc20Token.price = _price;
		_erc20Token.maxQuantity = _maxQuantity;
		_erc20Token.active = true;
		emit AddERC20Token(_erc20Token.tokenAddress, _erc20Token.price, _erc20Token.maxQuantity);
	}

	 
	function setPrice(address _tokenAddress, uint256 _price) public onlyTheAO {
		require (erc20TokenIdLookup[_tokenAddress] > 0);
		require (_price > 0);

		ERC20Token storage _erc20Token = erc20Tokens[erc20TokenIdLookup[_tokenAddress]];
		_erc20Token.price = _price;
		emit SetPrice(_erc20Token.tokenAddress, _erc20Token.price);
	}

	 
	function setMaxQuantity(address _tokenAddress, uint256 _maxQuantity) public onlyTheAO {
		require (erc20TokenIdLookup[_tokenAddress] > 0);

		ERC20Token storage _erc20Token = erc20Tokens[erc20TokenIdLookup[_tokenAddress]];
		require (_maxQuantity > _erc20Token.exchangedQuantity);
		_erc20Token.maxQuantity = _maxQuantity;
		emit SetMaxQuantity(_erc20Token.tokenAddress, _erc20Token.maxQuantity);
	}

	 
	function setActive(address _tokenAddress, bool _active) public onlyTheAO {
		require (erc20TokenIdLookup[_tokenAddress] > 0);

		ERC20Token storage _erc20Token = erc20Tokens[erc20TokenIdLookup[_tokenAddress]];
		_erc20Token.active = _active;
		emit SetActive(_erc20Token.tokenAddress, _erc20Token.active);
	}

	 
	function whitelistTransferFrom(address _from, address _to, uint256 _value) public inWhitelist returns (bool success) {
		_transfer(_from, _to, _value);
		return true;
	}

	 
	 
	function getById(uint256 _id) public view returns (address, string memory, string memory, uint256, uint256, uint256, bool) {
		require (erc20Tokens[_id].tokenAddress != address(0));
		ERC20Token memory _erc20Token = erc20Tokens[_id];
		return (
			_erc20Token.tokenAddress,
			TokenERC20(_erc20Token.tokenAddress).name(),
			TokenERC20(_erc20Token.tokenAddress).symbol(),
			_erc20Token.price,
			_erc20Token.maxQuantity,
			_erc20Token.exchangedQuantity,
			_erc20Token.active
		);
	}

	 
	function getByAddress(address _tokenAddress) public view returns (address, string memory, string memory, uint256, uint256, uint256, bool) {
		require (erc20TokenIdLookup[_tokenAddress] > 0);
		return getById(erc20TokenIdLookup[_tokenAddress]);
	}

	 
	function receiveApproval(address _from, uint256 _value, address _token, bytes calldata _extraData) external {
		require (_from != address(0));
		require (AOLibrary.isValidERC20TokenAddress(_token));

		 
		require (erc20TokenIdLookup[_token] > 0);
		ERC20Token storage _erc20Token = erc20Tokens[erc20TokenIdLookup[_token]];
		require (_erc20Token.active && _erc20Token.price > 0 && _erc20Token.exchangedQuantity < _erc20Token.maxQuantity);

		uint256 amountToTransfer = _value.div(_erc20Token.price);
		require (_erc20Token.maxQuantity.sub(_erc20Token.exchangedQuantity) >= amountToTransfer);
		require (_aoIon.availableETH() >= amountToTransfer);

		 
		require (TokenERC20(_token).transferFrom(_from, address(this), _value));

		_erc20Token.exchangedQuantity = _erc20Token.exchangedQuantity.add(amountToTransfer);
		balanceOf[_from] = balanceOf[_from].add(amountToTransfer);
		totalSupply = totalSupply.add(amountToTransfer);

		 
		totalTokenExchanges++;
		totalAddressTokenExchanges[_from]++;
		bytes32 _exchangeId = keccak256(abi.encodePacked(this, _from, totalTokenExchanges));
		tokenExchangeIdLookup[_exchangeId] = totalTokenExchanges;

		TokenExchange storage _tokenExchange = tokenExchanges[totalTokenExchanges];
		_tokenExchange.exchangeId = _exchangeId;
		_tokenExchange.buyer = _from;
		_tokenExchange.tokenAddress = _token;
		_tokenExchange.price = _erc20Token.price;
		_tokenExchange.sentAmount = _value;
		_tokenExchange.receivedAmount = amountToTransfer;
		_tokenExchange.extraData = _extraData;

		emit ExchangeToken(_tokenExchange.exchangeId, _tokenExchange.buyer, _tokenExchange.tokenAddress, TokenERC20(_token).name(), TokenERC20(_token).symbol(), _tokenExchange.sentAmount, _tokenExchange.receivedAmount, _tokenExchange.extraData);
	}

	 
	function getTokenExchangeById(bytes32 _exchangeId) public view returns (address, address, string memory, string memory, uint256, uint256,  uint256, bytes memory) {
		require (tokenExchangeIdLookup[_exchangeId] > 0);
		TokenExchange memory _tokenExchange = tokenExchanges[tokenExchangeIdLookup[_exchangeId]];
		return (
			_tokenExchange.buyer,
			_tokenExchange.tokenAddress,
			TokenERC20(_tokenExchange.tokenAddress).name(),
			TokenERC20(_tokenExchange.tokenAddress).symbol(),
			_tokenExchange.price,
			_tokenExchange.sentAmount,
			_tokenExchange.receivedAmount,
			_tokenExchange.extraData
		);
	}
}