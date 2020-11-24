 

pragma solidity ^0.4.24;

 

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }


 
interface SpinWinInterface {
	function refundPendingBets() external returns (bool);
}


 
interface SettingInterface {
	function uintSettings(bytes32 name) external constant returns (uint256);
	function boolSettings(bytes32 name) external constant returns (bool);
	function isActive() external constant returns (bool);
	function canBet(uint256 rewardValue, uint256 betValue, uint256 playerNumber, uint256 houseEdge) external constant returns (bool);
	function isExchangeAllowed(address playerAddress, uint256 tokenAmount) external constant returns (bool);

	 
	 
	 
	function spinwinSetUintSetting(bytes32 name, uint256 value) external;
	function spinwinIncrementUintSetting(bytes32 name) external;
	function spinwinSetBoolSetting(bytes32 name, bool value) external;
	function spinwinAddFunds(uint256 amount) external;
	function spinwinUpdateTokenToWeiExchangeRate() external;
	function spinwinRollDice(uint256 betValue) external;
	function spinwinUpdateWinMetric(uint256 playerProfit) external;
	function spinwinUpdateLoseMetric(uint256 betValue, uint256 tokenRewardValue) external;
	function spinwinUpdateLotteryContributionMetric(uint256 lotteryContribution) external;
	function spinwinUpdateExchangeMetric(uint256 exchangeAmount) external;

	 
	 
	 
	function spinlotterySetUintSetting(bytes32 name, uint256 value) external;
	function spinlotteryIncrementUintSetting(bytes32 name) external;
	function spinlotterySetBoolSetting(bytes32 name, bool value) external;
	function spinlotteryUpdateTokenToWeiExchangeRate() external;
	function spinlotterySetMinBankroll(uint256 _minBankroll) external returns (bool);
}


 
interface TokenInterface {
	function getTotalSupply() external constant returns (uint256);
	function getBalanceOf(address account) external constant returns (uint256);
	function transfer(address _to, uint256 _value) external returns (bool);
	function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
	function approve(address _spender, uint256 _value) external returns (bool success);
	function approveAndCall(address _spender, uint256 _value, bytes _extraData) external returns (bool success);
	function burn(uint256 _value) external returns (bool success);
	function burnFrom(address _from, uint256 _value) external returns (bool success);
	function mintTransfer(address _to, uint _value) external returns (bool);
	function burnAt(address _at, uint _value) external returns (bool);
}




 

 
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



contract escaped {
	address public escapeActivator;

	 
	constructor() public {
		escapeActivator = 0xB15C54b4B9819925Cd2A7eE3079544402Ac33cEe;
	}

	 
	modifier onlyEscapeActivator {
		require(msg.sender == escapeActivator);
		_;
	}

	 
	function changeAddress(address _escapeActivator) public onlyEscapeActivator {
		escapeActivator = _escapeActivator;
	}
}





 
contract GameSetting is developed, escaped, SettingInterface {
	using SafeMath for uint256;

	address public spinwinAddress;
	address public spinlotteryAddress;

	mapping(bytes32 => uint256) internal _uintSettings;     
	mapping(bytes32 => bool) internal _boolSettings;        

	uint256 constant public PERCENTAGE_DIVISOR = 10 ** 6;    
	uint256 constant public HOUSE_EDGE_DIVISOR = 1000;
	uint256 constant public CURRENCY_DIVISOR = 10**18;
	uint256 constant public TWO_DECIMALS = 100;
	uint256 constant public MAX_NUMBER = 99;
	uint256 constant public MIN_NUMBER = 2;
	uint256 constant public MAX_HOUSE_EDGE = 1000;           
	uint256 constant public MIN_HOUSE_EDGE = 0;              

	TokenInterface internal _spintoken;
	SpinWinInterface internal _spinwin;

	 
	event LogSetUintSetting(address indexed who, bytes32 indexed name, uint256 value);

	 
	event LogSetBoolSetting(address indexed who, bytes32 indexed name, bool value);

	 
	event LogAddBankRoll(uint256 amount);

	 
	event LogUpdateTokenToWeiExchangeRate(uint256 exchangeRate, uint256 exchangeRateBlockNumber);

	 
	event LogSpinwinEscapeHatch();

	 
	constructor(address _spintokenAddress) public {
		_spintoken = TokenInterface(_spintokenAddress);
		devSetUintSetting('minBet', CURRENCY_DIVISOR.div(100));			 
		devSetUintSetting('maxProfitAsPercentOfHouse', 200000);          
		devSetUintSetting('minBankroll', CURRENCY_DIVISOR.mul(20));      
		devSetTokenExchangeMinBankrollPercent(900000);                   
		devSetUintSetting('referralPercent', 10000);                     
		devSetUintSetting('gasForLottery', 250000);                      
		devSetUintSetting('maxBlockSecurityCount', 256);                 
		devSetUintSetting('blockSecurityCount', 3);                      
		devSetUintSetting('tokenExchangeBlockSecurityCount', 3);         
		devSetUintSetting('maxProfitBlockSecurityCount', 3);             
		devSetUintSetting('spinEdgeModifier', 80);                       
		devSetUintSetting('spinBankModifier', 50);                       
		devSetUintSetting('spinNumberModifier', 5);                      
		devSetUintSetting('maxMinBankroll', CURRENCY_DIVISOR.mul(5000));    
		devSetUintSetting('lastProcessedBetInternalId', 1);              
		devSetUintSetting('exchangeAmountDivisor', 2);                   
		devSetUintSetting('tokenExchangeRatio', 10);                     
		devSetUintSetting('spinToWeiRate', CURRENCY_DIVISOR);            
		devSetUintSetting('blockToSpinRate', CURRENCY_DIVISOR);          
		devSetUintSetting('blockToWeiRate', CURRENCY_DIVISOR);           
		devSetUintSetting('gasForClearingBet', 320000);                  
		devSetUintSetting('gasPrice', 40000000000);                      
		devSetUintSetting('clearSingleBetMultiplier', 200);              
		devSetUintSetting('clearMultipleBetsMultiplier', 100);           
		devSetUintSetting('maxNumClearBets', 4);                         
		devSetUintSetting('lotteryTargetMultiplier', 200);               
		_setMaxProfit(true);
	}

	 
	modifier onlySpinwin {
		require(msg.sender == spinwinAddress);
		_;
	}

	 
	modifier onlySpinlottery {
		require(msg.sender == spinlotteryAddress);
		_;
	}

	 
	 
	 

	 
	function devSetSpinwinAddress(address _address) public onlyDeveloper {
		require (_address != address(0));
		spinwinAddress = _address;
		_spinwin = SpinWinInterface(spinwinAddress);
	}

	 
	function devSetSpinlotteryAddress(address _address) public onlyDeveloper {
		require (_address != address(0));
		spinlotteryAddress = _address;
	}

	 
	function devSetUintSetting(bytes32 name, uint256 value) public onlyDeveloper {
		_uintSettings[name] = value;
		emit LogSetUintSetting(developer, name, value);
	}

	 
	function devSetBoolSetting(bytes32 name, bool value) public onlyDeveloper {
		_boolSettings[name] = value;
		emit LogSetBoolSetting(developer, name, value);
	}

	 
	function devSetMinBankroll(uint256 minBankroll) public onlyDeveloper {
		_uintSettings['minBankroll'] = minBankroll;
		_uintSettings['tokenExchangeMinBankroll'] = _uintSettings['minBankroll'].mul(_uintSettings['tokenExchangeMinBankrollPercent']).div(PERCENTAGE_DIVISOR);
	}

	 
	function devSetTokenExchangeMinBankrollPercent(uint256 tokenExchangeMinBankrollPercent) public onlyDeveloper {
		_uintSettings['tokenExchangeMinBankrollPercent'] = tokenExchangeMinBankrollPercent;
		_uintSettings['tokenExchangeMinBankroll'] = _uintSettings['minBankroll'].mul(_uintSettings['tokenExchangeMinBankrollPercent']).div(PERCENTAGE_DIVISOR);
	}

	 
	 
	 

	 
	function spinwinEscapeHatch() public onlyEscapeActivator {
		_spinwin.refundPendingBets();
		_boolSettings['contractKilled'] = true;
		_uintSettings['contractBalanceHonor'] = _uintSettings['contractBalance'];
		_uintSettings['tokenExchangeMinBankroll'] = 0;
		_uintSettings['tokenExchangeMinBankrollHonor'] = 0;
		 
		_uintSettings['tokenToWeiExchangeRate'] = _spintoken.getTotalSupply() > 0 ? _uintSettings['contractBalance'].mul(CURRENCY_DIVISOR).mul(CURRENCY_DIVISOR).div(_spintoken.getTotalSupply()) : 0;
		_uintSettings['tokenToWeiExchangeRateHonor'] = _uintSettings['tokenToWeiExchangeRate'];
		_uintSettings['tokenToWeiExchangeRateBlockNum'] = block.number;
		emit LogUpdateTokenToWeiExchangeRate(_uintSettings['tokenToWeiExchangeRateHonor'], _uintSettings['tokenToWeiExchangeRateBlockNum']);
		emit LogSpinwinEscapeHatch();
	}

	 
	 
	 
	 
	function spinwinSetUintSetting(bytes32 name, uint256 value) public onlySpinwin {
		_uintSettings[name] = value;
		emit LogSetUintSetting(spinwinAddress, name, value);
	}

	 
	function spinwinIncrementUintSetting(bytes32 name) public onlySpinwin {
		_uintSettings[name] = _uintSettings[name].add(1);
		emit LogSetUintSetting(spinwinAddress, name, _uintSettings[name]);
	}

	 
	function spinwinSetBoolSetting(bytes32 name, bool value) public onlySpinwin {
		_boolSettings[name] = value;
		emit LogSetBoolSetting(spinwinAddress, name, value);
	}

	 
	function spinwinAddFunds(uint256 amount) public onlySpinwin {
		 
		_uintSettings['contractBalance'] = _uintSettings['contractBalance'].add(amount);

		 
		_setMaxProfit(false);

		emit LogAddBankRoll(amount);
	}

	 
	function spinwinUpdateTokenToWeiExchangeRate() public onlySpinwin {
		_updateTokenToWeiExchangeRate();
	}

	 
	function spinwinRollDice(uint256 betValue) public onlySpinwin {
		_uintSettings['totalBets']++;
		_uintSettings['totalWeiWagered'] = _uintSettings['totalWeiWagered'].add(betValue);
	}

	 
	function spinwinUpdateWinMetric(uint256 playerProfit) public onlySpinwin {
		_uintSettings['contractBalance'] = _uintSettings['contractBalance'].sub(playerProfit);
		_uintSettings['totalWeiWon'] = _uintSettings['totalWeiWon'].add(playerProfit);
		_setMaxProfit(false);
	}

	 
	function spinwinUpdateLoseMetric(uint256 betValue, uint256 tokenRewardValue) public onlySpinwin {
		_uintSettings['contractBalance'] = _uintSettings['contractBalance'].add(betValue).sub(1);
		_uintSettings['totalWeiWon'] = _uintSettings['totalWeiWon'].add(1);
		_uintSettings['totalWeiLost'] = _uintSettings['totalWeiLost'].add(betValue).sub(1);
		_uintSettings['totalTokenPayouts'] = _uintSettings['totalTokenPayouts'].add(tokenRewardValue);
		_setMaxProfit(false);
	}

	 
	function spinwinUpdateLotteryContributionMetric(uint256 lotteryContribution) public onlySpinwin {
		_uintSettings['contractBalance'] = _uintSettings['contractBalance'].sub(lotteryContribution);
		_setMaxProfit(true);
	}

	 
	function spinwinUpdateExchangeMetric(uint256 exchangeAmount) public onlySpinwin {
		_uintSettings['contractBalance'] = _uintSettings['contractBalance'].sub(exchangeAmount);
		_setMaxProfit(false);
	}


	 
	 
	 
	 
	function spinlotterySetUintSetting(bytes32 name, uint256 value) public onlySpinlottery {
		_uintSettings[name] = value;
		emit LogSetUintSetting(spinlotteryAddress, name, value);
	}

	 
	function spinlotteryIncrementUintSetting(bytes32 name) public onlySpinlottery {
		_uintSettings[name] = _uintSettings[name].add(1);
		emit LogSetUintSetting(spinwinAddress, name, _uintSettings[name]);
	}

	 
	function spinlotterySetBoolSetting(bytes32 name, bool value) public onlySpinlottery {
		_boolSettings[name] = value;
		emit LogSetBoolSetting(spinlotteryAddress, name, value);
	}

	 
	function spinlotteryUpdateTokenToWeiExchangeRate() public onlySpinlottery {
		_updateTokenToWeiExchangeRate();
	}

	 
	function spinlotterySetMinBankroll(uint256 _minBankroll) public onlySpinlottery returns (bool) {
		if (_minBankroll > _uintSettings['maxMinBankroll']) {
			_minBankroll = _uintSettings['maxMinBankroll'];
		} else if (_minBankroll < _uintSettings['contractBalance']) {
			_minBankroll = _uintSettings['contractBalance'];
		}
		_uintSettings['minBankroll'] = _minBankroll;
		_uintSettings['tokenExchangeMinBankroll'] = _uintSettings['minBankroll'].mul(_uintSettings['tokenExchangeMinBankrollPercent']).div(PERCENTAGE_DIVISOR);

		 
		_setMaxProfit(false);

		return true;
	}

	 
	 
	 
	 
	function uintSettings(bytes32 name) public constant returns (uint256) {
		return _uintSettings[name];
	}

	 
	function boolSettings(bytes32 name) public constant returns (bool) {
		return _boolSettings[name];
	}

	 
	function isActive() public constant returns (bool) {
		if (_boolSettings['contractKilled'] == false && _boolSettings['gamePaused'] == false) {
			return true;
		} else {
			return false;
		}
	}

	 
	function canBet(uint256 rewardValue, uint256 betValue, uint256 playerNumber, uint256 houseEdge) public constant returns (bool) {
		if (_boolSettings['contractKilled'] == false && _boolSettings['gamePaused'] == false && rewardValue <= _uintSettings['maxProfitHonor'] && betValue >= _uintSettings['minBet'] && houseEdge >= MIN_HOUSE_EDGE && houseEdge <= MAX_HOUSE_EDGE && playerNumber >= MIN_NUMBER && playerNumber <= MAX_NUMBER) {
			return true;
		} else {
			return false;
		}
	}

	 
	function isExchangeAllowed(address playerAddress, uint256 tokenAmount) public constant returns (bool) {
		if (_boolSettings['gamePaused'] == false && _boolSettings['tokenExchangePaused'] == false && _uintSettings['contractBalanceHonor'] >= _uintSettings['tokenExchangeMinBankrollHonor'] && _uintSettings['tokenToWeiExchangeRateHonor'] > 0 && _spintoken.getBalanceOf(playerAddress) >= tokenAmount) {
			return true;
		} else {
			return false;
		}
	}

	 
	 
	 

	 
	function _setMaxProfit(bool force) internal {
		_uintSettings['maxProfit'] = _uintSettings['contractBalance'].mul(_uintSettings['maxProfitAsPercentOfHouse']).div(PERCENTAGE_DIVISOR);
		if (force || block.number > _uintSettings['maxProfitBlockNum'].add(_uintSettings['maxProfitBlockSecurityCount'])) {
			if (_uintSettings['contractBalance'] < 10 ether) {
				_uintSettings['maxProfitAsPercentOfHouse'] = 200000;  
			} else if (_uintSettings['contractBalance'] >= 10 ether && _uintSettings['contractBalance'] < 100 ether) {
				_uintSettings['maxProfitAsPercentOfHouse'] = 100000;  
			} else if (_uintSettings['contractBalance'] >= 100 ether && _uintSettings['contractBalance'] < 1000 ether) {
				_uintSettings['maxProfitAsPercentOfHouse'] = 50000;  
			} else {
				_uintSettings['maxProfitAsPercentOfHouse'] = 10000;  
			}
			_uintSettings['maxProfitHonor'] = _uintSettings['maxProfit'];
			_uintSettings['contractBalanceHonor'] = _uintSettings['contractBalance'];
			_uintSettings['minBankrollHonor'] = _uintSettings['minBankroll'];
			_uintSettings['tokenExchangeMinBankrollHonor'] = _uintSettings['tokenExchangeMinBankroll'];
			_uintSettings['totalWeiLostHonor'] = _uintSettings['totalWeiLost'];
			_uintSettings['maxProfitBlockNum'] = block.number;
		}
	}

	 
	function _updateTokenToWeiExchangeRate() internal {
		if (!_boolSettings['contractKilled']) {
			if (_uintSettings['contractBalance'] >= _uintSettings['tokenExchangeMinBankroll'] && _spintoken.getTotalSupply() > 0) {
				 
				_uintSettings['tokenToWeiExchangeRate'] = ((_uintSettings['contractBalance'].sub(_uintSettings['tokenExchangeMinBankroll'])).mul(CURRENCY_DIVISOR).mul(CURRENCY_DIVISOR).div(_uintSettings['exchangeAmountDivisor'])).div(_spintoken.getTotalSupply().mul(_uintSettings['tokenExchangeRatio']).div(TWO_DECIMALS));
			} else {
				_uintSettings['tokenToWeiExchangeRate'] = 0;
			}

			if (block.number > _uintSettings['tokenToWeiExchangeRateBlockNum'].add(_uintSettings['tokenExchangeBlockSecurityCount'])) {
				_uintSettings['tokenToWeiExchangeRateHonor'] = _uintSettings['tokenToWeiExchangeRate'];
				_uintSettings['tokenToWeiExchangeRateBlockNum'] = block.number;
				emit LogUpdateTokenToWeiExchangeRate(_uintSettings['tokenToWeiExchangeRateHonor'], _uintSettings['tokenToWeiExchangeRateBlockNum']);
			}
		}
	}
}