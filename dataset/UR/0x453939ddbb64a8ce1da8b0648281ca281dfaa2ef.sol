 

pragma solidity ^0.4.24;

 
interface SpinWinInterface {
	function refundPendingBets() external returns (bool);
}


 
interface AdvertisingInterface {
	function incrementBetCounter() external returns (bool);
}


contract SpinWinLibraryInterface {
	function calculateWinningReward(uint256 betValue, uint256 playerNumber, uint256 houseEdge) external pure returns (uint256);
	function calculateTokenReward(address settingAddress, uint256 betValue, uint256 playerNumber, uint256 houseEdge) external constant returns (uint256);
	function generateRandomNumber(address settingAddress, uint256 betBlockNumber, uint256 extraData, uint256 divisor) external constant returns (uint256);
	function calculateClearBetBlocksReward(address settingAddress, address lotteryAddress) external constant returns (uint256);
	function calculateLotteryContribution(address settingAddress, address lotteryAddress, uint256 betValue) external constant returns (uint256);
	function calculateExchangeTokenValue(address settingAddress, uint256 tokenAmount) external constant returns (uint256, uint256, uint256, uint256);
}


 
interface LotteryInterface {
	function claimReward(address playerAddress, uint256 tokenAmount) external returns (bool);
	function calculateLotteryContributionPercentage() external constant returns (uint256);
	function getNumLottery() external constant returns (uint256);
	function isActive() external constant returns (bool);
	function getCurrentTicketMultiplierHonor() external constant returns (uint256);
	function getCurrentLotteryTargetBalance() external constant returns (uint256, uint256);
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



interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

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








 
contract SpinWin is developed, SpinWinInterface {
	using SafeMath for uint256;

	address public tokenAddress;
	address public settingAddress;
	address public lotteryAddress;

	TokenInterface internal _spintoken;
	SettingInterface internal _setting;
	LotteryInterface internal _lottery;
	SpinWinLibraryInterface internal _lib;
	AdvertisingInterface internal _advertising;

	 
	struct Bet {
		address playerAddress;
		bytes32 betId;
		uint256 betValue;
		uint256 diceResult;
		uint256 playerNumber;
		uint256 houseEdge;
		uint256 rewardValue;
		uint256 tokenRewardValue;
		uint256 blockNumber;
		bool processed;
	}
	struct TokenExchange {
		address playerAddress;
		bytes32 exchangeId;
		bool processed;
	}

	mapping (uint256 => Bet) internal bets;
	mapping (bytes32 => uint256) internal betIdLookup;
	mapping (address => uint256) public playerPendingWithdrawals;
	mapping (address => uint256) public playerPendingTokenWithdrawals;
	mapping (address => address) public referees;
	mapping (bytes32 => TokenExchange) public tokenExchanges;
	mapping (address => uint256) public lotteryBlocksAmount;

	uint256 constant public TWO_DECIMALS = 100;
	uint256 constant public PERCENTAGE_DIVISOR = 10 ** 6;    
	uint256 constant public CURRENCY_DIVISOR = 10**18;

	uint256 public totalPendingBets;

	 
	event LogBet(bytes32 indexed betId, address indexed playerAddress, uint256 playerNumber, uint256 betValue, uint256 houseEdge, uint256 rewardValue, uint256 tokenRewardValue);

	 
	event LogResult(bytes32 indexed betId, address indexed playerAddress, uint256 playerNumber, uint256 diceResult, uint256 betValue, uint256 houseEdge, uint256 rewardValue, uint256 tokenRewardValue, int256 status);

	 
	event LogLotteryContribution(bytes32 indexed betId, address indexed playerAddress, uint256 weiValue);

	 
	event LogRewardLotteryBlocks(address indexed receiver, bytes32 indexed betId, uint256 lottoBlocksAmount, uint256 rewardType, uint256 status);

	 
	event LogClearBets(address indexed playerAddress);

	 
	event LogClaimLotteryBlocks(address indexed playerAddress, uint256 numLottery, uint256 claimAmount, uint256 claimStatus);

	 
	event LogTokenExchange(bytes32 indexed exchangeId, address indexed playerAddress, uint256 tokenValue, uint256 tokenToWeiExchangeRate, uint256 weiValue, uint256 receivedWeiValue, uint256 remainderTokenValue, uint256 status);

	 
	event LogPlayerWithdrawBalance(address indexed playerAddress, uint256 withdrawAmount, uint256 status);

	 
	event LogPlayerWithdrawTokenBalance(address indexed playerAddress, uint256 withdrawAmount, uint256 status);

	 
	event LogBetNotFound(bytes32 indexed betId);

	 
	event LogDeveloperCancelBet(bytes32 indexed betId, address indexed playerAddress);

	 
	constructor(address _tokenAddress, address _settingAddress, address _libraryAddress) public {
		tokenAddress = _tokenAddress;
		settingAddress = _settingAddress;
		_spintoken = TokenInterface(_tokenAddress);
		_setting = SettingInterface(_settingAddress);
		_lib = SpinWinLibraryInterface(_libraryAddress);
	}

	 
	modifier isActive {
		require(_setting.isActive() == true);
		_;
	}

	 
	modifier canBet(uint256 _betValue, uint256 _playerNumber, uint256 _houseEdge) {
		require(_setting.canBet(_lib.calculateWinningReward(_betValue, _playerNumber, _houseEdge), _betValue, _playerNumber, _houseEdge) == true);
		_;
	}

	 
	modifier betExist(bytes32 betId, address playerAddress) {
		require(betIdLookup[betId] > 0 && bets[betIdLookup[betId]].betId == betId && bets[betIdLookup[betId]].playerAddress == playerAddress);
		_;
	}

	 
	modifier isExchangeAllowed(address playerAddress, uint256 tokenAmount) {
		require(_setting.isExchangeAllowed(playerAddress, tokenAmount) == true);
		_;
	}

	 
	 
	 
	 
	function devSetLotteryAddress(address _lotteryAddress) public onlyDeveloper {
		require (_lotteryAddress != address(0));
		lotteryAddress = _lotteryAddress;
		_lottery = LotteryInterface(_lotteryAddress);
	}

	 
	function devSetAdvertisingAddress(address _advertisingAddress) public onlyDeveloper {
		require (_advertisingAddress != address(0));
		_advertising = AdvertisingInterface(_advertisingAddress);
	}

	 
	function devGetBetInternalId(bytes32 betId) public onlyDeveloper constant returns (uint256) {
		return (betIdLookup[betId]);
	}

	 
	function devGetBet(uint256 betInternalId) public
		onlyDeveloper
		constant returns (address, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool) {
		Bet memory _bet = bets[betInternalId];
		return (_bet.playerAddress, _bet.betValue, _bet.diceResult, _bet.playerNumber, _bet.houseEdge, _bet.rewardValue, _bet.tokenRewardValue, _bet.blockNumber, _bet.processed);
	}

	 
	function devRefundBet(bytes32 betId) public onlyDeveloper returns (bool) {
		require (betIdLookup[betId] > 0);

		Bet storage _bet = bets[betIdLookup[betId]];

		require(_bet.processed == false);

		_bet.processed = true;
		uint256 betValue = _bet.betValue;
		_bet.betValue = 0;
		_bet.rewardValue = 0;
		_bet.tokenRewardValue = 0;

		_refundPlayer(betIdLookup[betId], betValue);
		return true;
	}

	 
	function () public payable isActive {
		_setting.spinwinAddFunds(msg.value);
	}

	 
	 
	 
	 
	function refundPendingBets() public returns (bool) {
		require (msg.sender == settingAddress);
		uint256 totalBets = _setting.uintSettings('totalBets');
		if (totalBets > 0) {
			for (uint256 i = 1; i <= totalBets; i++) {
				Bet storage _bet = bets[i];
				if (_bet.processed == false) {
					uint256 _betValue = _bet.betValue;
					_bet.processed = true;
					_bet.betValue = 0;
					playerPendingWithdrawals[_bet.playerAddress] = playerPendingWithdrawals[_bet.playerAddress].add(_betValue);
					emit LogResult(_bet.betId, _bet.playerAddress, _bet.playerNumber, 0, _betValue, _bet.houseEdge, 0, 0, 4);
				}
			}
		}
		return true;
	}

	 
	 
	 
	 
	function rollDice(uint256 playerNumber, uint256 houseEdge, bytes32 clearBetId, address referreeAddress) public
		payable
		canBet(msg.value, playerNumber, houseEdge)
		returns (bool) {
		uint256 betInternalId = _storeBet(msg.value, msg.sender, playerNumber, houseEdge);

		 
		if (clearBetId != '') {
			_clearSingleBet(msg.sender, clearBetId, _setting.uintSettings('blockSecurityCount'));
		}

		 
		_rewardReferree(referreeAddress, betInternalId);

		_advertising.incrementBetCounter();

		return true;
	}

	 
	function clearBets(bytes32[] betIds) public isActive {
		require (betIds.length > 0 && betIds.length <= _setting.uintSettings('maxNumClearBets'));
		bool canClear = false;
		uint256 blockSecurityCount = _setting.uintSettings('blockSecurityCount');
		for (uint256 i = 0; i < betIds.length; i++) {
			Bet memory _bet = bets[betIdLookup[betIds[i]]];
			if (_bet.processed == false && _setting.uintSettings('contractBalance') >= _bet.rewardValue && (block.number.sub(_bet.blockNumber)) >= blockSecurityCount) {
				canClear = true;
				break;
			}
		}
		require(canClear == true);

		 
		for (i = 0; i < betIds.length; i++) {
			_clearSingleBet(msg.sender, betIds[i], blockSecurityCount);
		}
		emit LogClearBets(msg.sender);
	}

	 
	function claimLotteryBlocks() public isActive {
		require (_lottery.isActive() == true);
		require (lotteryBlocksAmount[msg.sender] > 0);
		uint256 claimAmount = lotteryBlocksAmount[msg.sender];
		lotteryBlocksAmount[msg.sender] = 0;
		uint256 claimStatus = 1;
		if (!_lottery.claimReward(msg.sender, claimAmount)) {
			claimStatus = 0;
			lotteryBlocksAmount[msg.sender] = claimAmount;
		}
		emit LogClaimLotteryBlocks(msg.sender, _lottery.getNumLottery(), claimAmount, claimStatus);
	}

	 
	function exchangeToken(uint256 tokenAmount) public
		isExchangeAllowed(msg.sender, tokenAmount) {
		(uint256 weiValue, uint256 sendWei, uint256 tokenRemainder, uint256 burnToken) = _lib.calculateExchangeTokenValue(settingAddress, tokenAmount);

		_setting.spinwinIncrementUintSetting('totalTokenExchanges');

		 
		bytes32 _exchangeId = keccak256(abi.encodePacked(this, msg.sender, _setting.uintSettings('totalTokenExchanges')));
		TokenExchange storage _tokenExchange = tokenExchanges[_exchangeId];

		 
		require (_tokenExchange.processed == false);

		 
		_setting.spinwinUpdateExchangeMetric(sendWei);

		 
		_tokenExchange.playerAddress = msg.sender;
		_tokenExchange.exchangeId = _exchangeId;
		_tokenExchange.processed = true;

		 
		if (!_spintoken.burnAt(_tokenExchange.playerAddress, burnToken)) {
			uint256 exchangeStatus = 2;  

		} else {
			if (!_tokenExchange.playerAddress.send(sendWei)) {
				exchangeStatus = 0;  

				 
				playerPendingWithdrawals[_tokenExchange.playerAddress] = playerPendingWithdrawals[_tokenExchange.playerAddress].add(sendWei);
			} else {
				exchangeStatus = 1;  
			}
		}
		 
		_setting.spinwinUpdateTokenToWeiExchangeRate();

		emit LogTokenExchange(_tokenExchange.exchangeId, _tokenExchange.playerAddress, tokenAmount, _setting.uintSettings('tokenToWeiExchangeRateHonor'), weiValue, sendWei, tokenRemainder, exchangeStatus);
	}

	 
	function calculateWinningReward(uint256 betValue, uint256 playerNumber, uint256 houseEdge) public view returns (uint256) {
		return _lib.calculateWinningReward(betValue, playerNumber, houseEdge);
	}

	 
	function calculateTokenReward(uint256 betValue, uint256 playerNumber, uint256 houseEdge) public constant returns (uint256) {
		return _lib.calculateTokenReward(settingAddress, betValue, playerNumber, houseEdge);
	}

	 
	function playerWithdrawPendingTransactions() public {
		require(playerPendingWithdrawals[msg.sender] > 0);
		uint256 withdrawAmount = playerPendingWithdrawals[msg.sender];
		playerPendingWithdrawals[msg.sender] = 0;

		 
		uint256 status = 1;  
		if (!msg.sender.send(withdrawAmount)) {
			status = 0;  

			 
			playerPendingWithdrawals[msg.sender] = withdrawAmount;
		}
		emit LogPlayerWithdrawBalance(msg.sender, withdrawAmount, status);
	}

	 
	function playerWithdrawPendingTokenTransactions() public {
		require(playerPendingTokenWithdrawals[msg.sender] > 0);
		uint256 withdrawAmount = playerPendingTokenWithdrawals[msg.sender];
		playerPendingTokenWithdrawals[msg.sender] = 0;

		 
		uint256 status = 1;  
		if (!_spintoken.mintTransfer(msg.sender, withdrawAmount)) {
			status = 0;  
			 
			playerPendingTokenWithdrawals[msg.sender] = withdrawAmount;
		}
		emit LogPlayerWithdrawTokenBalance(msg.sender, withdrawAmount, status);
	}

	 
	function playerGetBet(bytes32 betId) public
		constant returns (uint256, uint256, uint256, uint256, uint256, uint256, bool) {
		require(betIdLookup[betId] > 0 && bets[betIdLookup[betId]].betId == betId);
		Bet memory _bet = bets[betIdLookup[betId]];
		return (_bet.betValue, _bet.diceResult, _bet.playerNumber, _bet.houseEdge, _bet.rewardValue, _bet.tokenRewardValue, _bet.processed);
	}

	 
	function playerGetPendingBetIds() public constant returns (bytes32[]) {
		bytes32[] memory pendingBetIds = new bytes32[](totalPendingBets);
		if (totalPendingBets > 0) {
			uint256 counter = 0;
			for (uint256 i = 1; i <= _setting.uintSettings('totalBets'); i++) {
				Bet memory _bet = bets[i];
				if (_bet.processed == false) {
					pendingBetIds[counter] = _bet.betId;
					counter++;
				}
				if (counter == totalPendingBets) {
					break;
				}
			}
		}
		return pendingBetIds;
	}

	 
	function playerGetPendingBet(bytes32 betId) public
		constant returns (address, uint256, uint256, uint256, uint256) {
		require(betIdLookup[betId] > 0 && bets[betIdLookup[betId]].betId == betId);
		Bet memory _bet = bets[betIdLookup[betId]];
		return (_bet.playerAddress, _bet.playerNumber, _bet.betValue, _bet.houseEdge, _bet.blockNumber);
	}

	 
	function calculateClearBetBlocksReward() public constant returns (uint256) {
		return _lib.calculateClearBetBlocksReward(settingAddress, lotteryAddress);
	}


	 
	 
	 

	 
	function _storeBet (uint256 betValue, address playerAddress, uint256 playerNumber, uint256 houseEdge) internal returns (uint256) {
		 
		_setting.spinwinRollDice(betValue);

		uint256 betInternalId = _setting.uintSettings('totalBets');

		 
		bytes32 betId = keccak256(abi.encodePacked(this, playerAddress, betInternalId));

		Bet storage _bet = bets[betInternalId];

		 
		require (_bet.processed == false);

		 
		betIdLookup[betId] = betInternalId;
		_bet.playerAddress = playerAddress;
		_bet.betId = betId;
		_bet.betValue = betValue;
		_bet.playerNumber = playerNumber;
		_bet.houseEdge = houseEdge;

		 
		_bet.rewardValue = calculateWinningReward(betValue, playerNumber, houseEdge);

		 
		_bet.tokenRewardValue = calculateTokenReward(betValue, playerNumber, houseEdge);
		_bet.blockNumber = block.number;

		 
		totalPendingBets++;

		emit LogBet(_bet.betId, _bet.playerAddress, _bet.playerNumber, _bet.betValue, _bet.houseEdge, _bet.rewardValue, _bet.tokenRewardValue);
		return betInternalId;
	}

	 
	function _clearSingleBet(address playerAddress, bytes32 betId, uint256 blockSecurityCount) internal returns (bool) {
		if (betIdLookup[betId] > 0) {
			Bet memory _bet = bets[betIdLookup[betId]];

			 
			if (_bet.processed == false && _setting.uintSettings('contractBalance') >= _bet.rewardValue && (block.number.sub(_bet.blockNumber)) >= blockSecurityCount) {
				_processBet(playerAddress, betIdLookup[betId], true);
			} else {
				emit LogRewardLotteryBlocks(playerAddress, _bet.betId, 0, 2, 0);
			}
			return true;
		} else {
			emit LogBetNotFound(betId);
			return false;
		}
	}

	 
	function _processBet(address triggerAddress, uint256 betInternalId, bool isClearMultiple) internal returns (bool) {
		Bet storage _bet =  bets[betInternalId];
		uint256 _betValue = _bet.betValue;
		uint256 _rewardValue = _bet.rewardValue;
		uint256 _tokenRewardValue = _bet.tokenRewardValue;

		 
		_bet.processed = true;
		_bet.betValue = 0;
		_bet.rewardValue = 0;
		_bet.tokenRewardValue = 0;

		 
		_bet.diceResult = _lib.generateRandomNumber(settingAddress, _bet.blockNumber, _setting.uintSettings('totalBets').add(_setting.uintSettings('totalWeiWagered')), 100);

		if (_bet.diceResult == 0) {
			 
			_refundPlayer(betInternalId, _betValue);
		} else if (_bet.diceResult < _bet.playerNumber) {
			 
			_payWinner(betInternalId, _betValue, _rewardValue);
		} else {
			 
			_payLoser(betInternalId, _betValue, _tokenRewardValue);
		}
		 
		totalPendingBets--;

		 
		_setting.spinwinUpdateTokenToWeiExchangeRate();

		 
		uint256 lotteryBlocksReward = calculateClearBetBlocksReward();

		 
		if (isClearMultiple == false) {
			uint256 multiplier = _setting.uintSettings('clearSingleBetMultiplier');
		} else {
			multiplier = _setting.uintSettings('clearMultipleBetsMultiplier');
		}
		lotteryBlocksReward = (lotteryBlocksReward.mul(multiplier)).div(TWO_DECIMALS);

		lotteryBlocksAmount[triggerAddress] = lotteryBlocksAmount[triggerAddress].add(lotteryBlocksReward);
		emit LogRewardLotteryBlocks(triggerAddress, _bet.betId, lotteryBlocksReward, 2, 1);
		return true;
	}

	 
	function _refundPlayer(uint256 betInternalId, uint256 refundAmount) internal {
		Bet memory _bet =  bets[betInternalId];
		 
		int256 betStatus = 3;  
		if (!_bet.playerAddress.send(refundAmount)) {
			betStatus = 4;  

			 
			playerPendingWithdrawals[_bet.playerAddress] = playerPendingWithdrawals[_bet.playerAddress].add(refundAmount);
		}
		emit LogResult(_bet.betId, _bet.playerAddress, _bet.playerNumber, _bet.diceResult, refundAmount, _bet.houseEdge, 0, 0, betStatus);
	}

	 
	function _payWinner(uint256 betInternalId, uint256 betValue, uint256 playerProfit) internal {
		Bet memory _bet =  bets[betInternalId];
		 
		_setting.spinwinUpdateWinMetric(playerProfit);

		 
		playerProfit = playerProfit.add(betValue);

		 
		int256 betStatus = 1;  
		if (!_bet.playerAddress.send(playerProfit)) {
			betStatus = 2;  

			 
			playerPendingWithdrawals[_bet.playerAddress] = playerPendingWithdrawals[_bet.playerAddress].add(playerProfit);
		}
		emit LogResult(_bet.betId, _bet.playerAddress, _bet.playerNumber, _bet.diceResult, betValue, _bet.houseEdge, playerProfit, 0, betStatus);
	}

	 
	function _payLoser(uint256 betInternalId, uint256 betValue, uint256 tokenRewardValue) internal {
		Bet memory _bet =  bets[betInternalId];
		 
		_setting.spinwinUpdateLoseMetric(betValue, tokenRewardValue);

		int256 betStatus;  

		 
		if (!_bet.playerAddress.send(1)) {
			betStatus = -1;  

			 
			playerPendingWithdrawals[_bet.playerAddress] = playerPendingWithdrawals[_bet.playerAddress].add(1);
		}

		 
		if (tokenRewardValue > 0) {
			if (!_spintoken.mintTransfer(_bet.playerAddress, tokenRewardValue)) {
				betStatus = -2;  

				 
				playerPendingTokenWithdrawals[_bet.playerAddress] = playerPendingTokenWithdrawals[_bet.playerAddress].add(tokenRewardValue);
			}
		}
		emit LogResult(_bet.betId, _bet.playerAddress, _bet.playerNumber, _bet.diceResult, betValue, _bet.houseEdge, 1, tokenRewardValue, betStatus);
		_sendLotteryContribution(betInternalId, betValue);
	}

	 
	function _sendLotteryContribution(uint256 betInternalId, uint256 betValue) internal returns (bool) {
		 
		uint256 contractBalance = _setting.uintSettings('contractBalance');
		if (contractBalance >= _setting.uintSettings('minBankroll')) {
			Bet memory _bet =  bets[betInternalId];
			uint256 lotteryContribution = _lib.calculateLotteryContribution(settingAddress, lotteryAddress, betValue);

			if (lotteryContribution > 0 && contractBalance >= lotteryContribution) {
				 
				_setting.spinwinUpdateLotteryContributionMetric(lotteryContribution);

				emit LogLotteryContribution(_bet.betId, _bet.playerAddress, lotteryContribution);

				 
				if (!lotteryAddress.call.gas(_setting.uintSettings('gasForLottery')).value(lotteryContribution)()) {
					return false;
				}
			}
		}
		return true;
	}

	 
	function _rewardReferree(address referreeAddress, uint256 betInternalId) internal {
		Bet memory _bet = bets[betInternalId];

		 
		if (referees[_bet.playerAddress] != address(0)) {
			referreeAddress = referees[_bet.playerAddress];
		}
		if (referreeAddress != address(0) && referreeAddress != _bet.playerAddress) {
			referees[_bet.playerAddress] = referreeAddress;
			uint256 _tokenForLotto = _bet.tokenRewardValue.mul(_setting.uintSettings('referralPercent')).div(PERCENTAGE_DIVISOR);
			lotteryBlocksAmount[referreeAddress] = lotteryBlocksAmount[referreeAddress].add(_tokenForLotto);
			emit LogRewardLotteryBlocks(referreeAddress, _bet.betId, _tokenForLotto, 1, 1);
		}
	}
}