 

pragma solidity ^0.4.24;

 
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





 
contract SpinLottery is developed, escaped, LotteryInterface {
	using SafeMath for uint256;

	 
	address public owner;
	address public spinwinAddress;

	bool public contractKilled;
	bool public gamePaused;

	uint256 public numLottery;
	uint256 public lotteryTarget;
	uint256 public totalBankroll;
	uint256 public totalBuyTickets;
	uint256 public totalTokenWagered;
	uint256 public lotteryTargetIncreasePercentage;
	uint256 public lastBlockNumber;
	uint256 public lastLotteryTotalBlocks;

	uint256 public currentTicketMultiplier;
	uint256 public currentTicketMultiplierHonor;
	uint256 public currentTicketMultiplierBlockNumber;

	uint256 public maxBlockSecurityCount;
	uint256 public blockSecurityCount;
	uint256 public currentTicketMultiplierBlockSecurityCount;

	uint256 public ticketMultiplierModifier;

	uint256 public avgLotteryHours;  
	uint256 public totalLotteryHours;  
	uint256 public minBankrollDecreaseRate;  
	uint256 public minBankrollIncreaseRate;  
	uint256 public lotteryContributionPercentageModifier;  
	uint256 public rateConfidenceModifier;  
	uint256 public currentLotteryPaceModifier;  
	uint256 public maxLotteryContributionPercentage;  

	uint256 constant public PERCENTAGE_DIVISOR = 1000000;
	uint256 constant public TWO_DECIMALS = 100;  
	uint256 constant public CURRENCY_DIVISOR = 10 ** 18;

	uint256 public startLotteryRewardPercentage;  
	uint256 internal lotteryContribution;
	uint256 internal carryOverContribution;
	uint256 public minRewardBlocksAmount;

	TokenInterface internal _spintoken;
	SettingInterface internal _setting;

	struct Lottery {
		uint256 lotteryTarget;
		uint256 bankroll;
		uint256 tokenWagered;
		uint256 lotteryResult;
		uint256 totalBlocks;
		uint256 totalBlocksRewarded;
		uint256 startTimestamp;
		uint256 endTimestamp;
		address winnerPlayerAddress;
		bool ended;
		bool cashedOut;
	}

	struct Ticket {
		bytes32 ticketId;
		uint256 numLottery;
		address playerAddress;
		uint256 minNumber;
		uint256 maxNumber;
		bool claimed;
	}
	mapping (uint256 => Lottery) public lotteries;
	mapping (bytes32 => Ticket) public tickets;
	mapping (uint256 => mapping (address => uint256)) public playerTokenWagered;
	mapping (address => uint256) public playerPendingWithdrawals;
	mapping (uint256 => mapping (address => uint256)) public playerTotalBlocks;
	mapping (uint256 => mapping (address => uint256)) public playerTotalBlocksRewarded;

	 
	event LogCreateLottery(uint256 indexed numLottery, uint256 lotteryBankrollGoal);

	 
	event LogEndLottery(uint256 indexed numLottery, uint256 lotteryResult);

	 
	event LogAddBankRoll(uint256 indexed numLottery, uint256 amount);

	 
	event LogBuyTicket(uint256 indexed numLottery, bytes32 indexed ticketId, address indexed playerAddress, uint256 tokenAmount, uint256 ticketMultiplier, uint256 minNumber, uint256 maxNumber, uint256 ticketType);

	 
	event LogClaimTicket(uint256 indexed numLottery, bytes32 indexed ticketId, address indexed playerAddress, uint256 lotteryResult, uint256 playerMinNumber, uint256 playerMaxNumber, uint256 winningReward, uint256 status);

	 
	event LogPlayerWithdrawBalance(address indexed playerAddress, uint256 withdrawAmount, uint256 status);

	 
	event LogUpdateCurrentTicketMultiplier(uint256 currentTicketMultiplier, uint256 currentTicketMultiplierBlockNumber);

	 
	event LogEscapeHatch();

	 
	constructor(address _settingAddress, address _tokenAddress, address _spinwinAddress) public {
		_setting = SettingInterface(_settingAddress);
		_spintoken = TokenInterface(_tokenAddress);
		spinwinAddress = _spinwinAddress;
		lastLotteryTotalBlocks = 100 * CURRENCY_DIVISOR;                 
		devSetLotteryTargetIncreasePercentage(150000);                   
		devSetMaxBlockSecurityCount(256);                                
		devSetBlockSecurityCount(3);                                     
		devSetCurrentTicketMultiplierBlockSecurityCount(3);              
		devSetTicketMultiplierModifier(300);                             
		devSetMinBankrollDecreaseRate(80);                               
		devSetMinBankrollIncreaseRate(170);                              
		devSetLotteryContributionPercentageModifier(10);                 
		devSetRateConfidenceModifier(200);                               
		devSetCurrentLotteryPaceModifier(200);                           
		devSetStartLotteryRewardPercentage(10000);                       
		devSetMinRewardBlocksAmount(1);                                  
		devSetMaxLotteryContributionPercentage(100);                     
		_createNewLottery();                                             
	}

	 
	modifier contractIsAlive {
		require(contractKilled == false);
		_;
	}

	 
	modifier gameIsActive {
		require(gamePaused == false);
		_;
	}

	 
	modifier onlySpinwin {
		require(msg.sender == spinwinAddress);
		_;
	}

	 
	 
	 

	 
	function devSetLotteryTarget(uint256 _lotteryTarget) public onlyDeveloper {
		require (_lotteryTarget >= 0);
		lotteryTarget = _lotteryTarget;
		Lottery storage _lottery = lotteries[numLottery];
		_lottery.lotteryTarget = lotteryTarget;
	}

	 
	function devSetLotteryTargetIncreasePercentage(uint256 _lotteryTargetIncreasePercentage) public onlyDeveloper {
		lotteryTargetIncreasePercentage = _lotteryTargetIncreasePercentage;
	}

	 
	function devSetBlockSecurityCount(uint256 _blockSecurityCount) public onlyDeveloper {
		require (_blockSecurityCount > 0);
		blockSecurityCount = _blockSecurityCount;
	}

	 
	function devSetMaxBlockSecurityCount(uint256 _maxBlockSecurityCount) public onlyDeveloper {
		require (_maxBlockSecurityCount > 0);
		maxBlockSecurityCount = _maxBlockSecurityCount;
	}

	 
	function devSetCurrentTicketMultiplierBlockSecurityCount(uint256 _currentTicketMultiplierBlockSecurityCount) public onlyDeveloper {
		require (_currentTicketMultiplierBlockSecurityCount > 0);
		currentTicketMultiplierBlockSecurityCount = _currentTicketMultiplierBlockSecurityCount;
	}

	 
	function devSetTicketMultiplierModifier(uint256 _ticketMultiplierModifier) public onlyDeveloper {
		require (_ticketMultiplierModifier > 0);
		ticketMultiplierModifier = _ticketMultiplierModifier;
	}

	 
	function devSetMinBankrollDecreaseRate(uint256 _minBankrollDecreaseRate) public onlyDeveloper {
		require (_minBankrollDecreaseRate >= 0);
		minBankrollDecreaseRate = _minBankrollDecreaseRate;
	}

	 
	function devSetMinBankrollIncreaseRate(uint256 _minBankrollIncreaseRate) public onlyDeveloper {
		require (_minBankrollIncreaseRate > minBankrollDecreaseRate);
		minBankrollIncreaseRate = _minBankrollIncreaseRate;
	}

	 
	function devSetLotteryContributionPercentageModifier(uint256 _lotteryContributionPercentageModifier) public onlyDeveloper {
		lotteryContributionPercentageModifier = _lotteryContributionPercentageModifier;
	}

	 
	function devSetRateConfidenceModifier(uint256 _rateConfidenceModifier) public onlyDeveloper {
		rateConfidenceModifier = _rateConfidenceModifier;
	}

	 
	function devSetCurrentLotteryPaceModifier(uint256 _currentLotteryPaceModifier) public onlyDeveloper {
		currentLotteryPaceModifier = _currentLotteryPaceModifier;
	}

	 
	function devPauseGame(bool paused) public onlyDeveloper {
		gamePaused = paused;
	}

	 
	function devStartLottery() public onlyDeveloper returns (bool) {
		Lottery memory _currentLottery = lotteries[numLottery];
		require (_currentLottery.ended == true);
		_createNewLottery();
		return true;
	}

	 
	function devEndLottery(bool _startNextLottery) public onlyDeveloper returns (bool) {
		_endLottery();
		if (_startNextLottery) {
			_createNewLottery();
		}
		return true;
	}

	 
	function devSetStartLotteryRewardPercentage(uint256 _startLotteryRewardPercentage) public onlyDeveloper {
		startLotteryRewardPercentage = _startLotteryRewardPercentage;
	}

	 
	function devSetMinRewardBlocksAmount(uint256 _minRewardBlocksAmount) public onlyDeveloper {
		minRewardBlocksAmount = _minRewardBlocksAmount;
	}

	 
	function devSetMaxLotteryContributionPercentage(uint256 _maxLotteryContributionPercentage) public onlyDeveloper {
		maxLotteryContributionPercentage = _maxLotteryContributionPercentage;
	}

	 
	 
	 

	 
	function escapeHatch() public
		onlyEscapeActivator
		contractIsAlive
		returns (bool) {
		contractKilled = true;
		_endLottery();
		emit LogEscapeHatch();
		return true;
	}

	 
	 
	 
	 
	function claimReward(address playerAddress, uint256 tokenAmount) public
		contractIsAlive
		gameIsActive
		onlySpinwin
		returns (bool) {
		return _buyTicket(playerAddress, tokenAmount, 2);
	}

	 
	 
	 
	 
	function () payable public
		contractIsAlive
		gameIsActive {
		 
		lastBlockNumber = block.number;

		Lottery storage _currentLottery = lotteries[numLottery];
		if (_currentLottery.bankroll.add(msg.value) > lotteryTarget) {
			lotteryContribution = lotteryTarget.sub(_currentLottery.bankroll);
			carryOverContribution = carryOverContribution.add(msg.value.sub(lotteryContribution));
		} else {
			lotteryContribution = msg.value;
		}

		 
		if (lotteryContribution > 0) {
			_currentLottery.bankroll = _currentLottery.bankroll.add(lotteryContribution);
			totalBankroll = totalBankroll.add(lotteryContribution);
			emit LogAddBankRoll(numLottery, lotteryContribution);
		}
	}

	 
	function buyTicket(uint tokenAmount) public
		contractIsAlive
		gameIsActive
		returns (bool) {
		require (_spintoken.burnAt(msg.sender, tokenAmount));
		return _buyTicket(msg.sender, tokenAmount, 1);
	}

	 
	function claimTicket(bytes32 ticketId) public
		gameIsActive
		returns (bool) {
		Ticket storage _ticket = tickets[ticketId];
		require(_ticket.claimed == false && _ticket.playerAddress == msg.sender);

		Lottery storage _lottery = lotteries[_ticket.numLottery];
		require(_lottery.ended == true && _lottery.cashedOut == false && _lottery.bankroll > 0 && _lottery.totalBlocks.add(_lottery.totalBlocksRewarded) > 0 && _lottery.lotteryResult > 0);

		 
		_ticket.claimed = true;
		uint256 status = 0;  
		if (_lottery.lotteryResult >= _ticket.minNumber && _lottery.lotteryResult <= _ticket.maxNumber) {
			uint256 lotteryReward = _lottery.bankroll;

			 
			require(totalBankroll >= lotteryReward);

			 
			totalBankroll = totalBankroll.sub(lotteryReward);

			_lottery.bankroll = 0;
			_lottery.winnerPlayerAddress = msg.sender;
			_lottery.cashedOut = true;


			if (!msg.sender.send(lotteryReward)) {
				status = 2;  
				 
				playerPendingWithdrawals[msg.sender] = playerPendingWithdrawals[msg.sender].add(lotteryReward);
			} else {
				status = 1;  
			}
		}
		emit LogClaimTicket(_ticket.numLottery, ticketId, msg.sender, _lottery.lotteryResult, _ticket.minNumber, _ticket.maxNumber, lotteryReward, status);
		return true;
	}

	 
	function playerWithdrawPendingTransactions() public
		gameIsActive {
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

	 
	function calculateNumBlocks(uint256 tokenAmount) public constant returns (uint256 ticketMultiplier, uint256 numBlocks) {
		return (currentTicketMultiplierHonor, currentTicketMultiplierHonor.mul(tokenAmount).div(TWO_DECIMALS));
	}

	 
	function getNumLottery() public constant returns (uint256) {
		return numLottery;
	}

	 
	function isActive() public constant returns (bool) {
		if (gamePaused == true || contractKilled == true) {
			return false;
		} else {
			return true;
		}
	}

	 
	function calculateLotteryContributionPercentage() public
		contractIsAlive
		gameIsActive
		constant returns (uint256) {
		Lottery memory _currentLottery = lotteries[numLottery];
		uint256 currentTotalLotteryHours = _getHoursBetween(_currentLottery.startTimestamp, now);

		uint256 currentWeiToLotteryRate = 0;
		 
		if (currentTotalLotteryHours > 0) {
			 
			currentWeiToLotteryRate = (_currentLottery.bankroll.mul(TWO_DECIMALS)).div(currentTotalLotteryHours);
		}

		uint256 predictedCurrentLotteryHours = currentTotalLotteryHours;
		 
		if (currentWeiToLotteryRate > 0) {
			 
			uint256 temp = (lotteryTarget.sub(_currentLottery.bankroll)).mul(TWO_DECIMALS).mul(TWO_DECIMALS).div(currentWeiToLotteryRate);
			predictedCurrentLotteryHours = currentTotalLotteryHours.add(temp.div(TWO_DECIMALS));
		}

		uint256 currentLotteryPace = 0;
		 
		if (avgLotteryHours > 0) {
			 
			currentLotteryPace = (predictedCurrentLotteryHours.mul(TWO_DECIMALS).mul(TWO_DECIMALS)).div(avgLotteryHours);
		}

		uint256 percentageOverTarget = 0;
		 
		if (_setting.uintSettings('minBankroll') > 0) {
			 
			percentageOverTarget = (_setting.uintSettings('contractBalance').mul(TWO_DECIMALS)).div(_setting.uintSettings('minBankroll'));
		}

		currentTotalLotteryHours = currentTotalLotteryHours.mul(TWO_DECIMALS);  
		uint256 rateConfidence = 0;
		 
		if (avgLotteryHours.add(currentTotalLotteryHours) > 0) {
			 
			rateConfidence = currentTotalLotteryHours.mul(TWO_DECIMALS).div(avgLotteryHours.add(currentTotalLotteryHours));
		}

		 
		uint256 lotteryContributionPercentage = lotteryContributionPercentageModifier;

		 
		 
		if (percentageOverTarget > 0) {
			lotteryContributionPercentage = lotteryContributionPercentage.add(TWO_DECIMALS.sub((TWO_DECIMALS.mul(TWO_DECIMALS)).div(percentageOverTarget)));
		} else {
			lotteryContributionPercentage = lotteryContributionPercentage.add(TWO_DECIMALS);
		}

		 
		 
		if (currentLotteryPace.add(currentLotteryPaceModifier) > 0) {
			lotteryContributionPercentage = lotteryContributionPercentage.add((rateConfidence.mul(rateConfidenceModifier).mul(currentLotteryPace)).div(TWO_DECIMALS.mul(currentLotteryPace.add(currentLotteryPaceModifier))));
		}
		if (lotteryContributionPercentage > maxLotteryContributionPercentage) {
			lotteryContributionPercentage = maxLotteryContributionPercentage;
		}
		return lotteryContributionPercentage;
	}

	 
	function startNextLottery() public
		contractIsAlive
		gameIsActive {
		Lottery storage _currentLottery = lotteries[numLottery];
		require (_currentLottery.bankroll >= lotteryTarget && _currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded) > 0);
		uint256 startLotteryRewardBlocks = calculateStartLotteryRewardBlocks();
		_endLottery();
		_createNewLottery();

		 
		 
		if (carryOverContribution > 0) {
			_currentLottery = lotteries[numLottery];
			if (_currentLottery.bankroll.add(carryOverContribution) > lotteryTarget) {
				lotteryContribution = lotteryTarget.sub(_currentLottery.bankroll);
				carryOverContribution = carryOverContribution.sub(lotteryContribution);
			} else {
				lotteryContribution = carryOverContribution;
				carryOverContribution = 0;
			}

			 
			_currentLottery.bankroll = _currentLottery.bankroll.add(lotteryContribution);
			totalBankroll = totalBankroll.add(lotteryContribution);
			emit LogAddBankRoll(numLottery, lotteryContribution);
		}
		_buyTicket(msg.sender, startLotteryRewardBlocks, 3);
	}

	 
	function calculateStartLotteryRewardBlocks() public constant returns (uint256) {
		uint256 totalRewardBlocks = lastLotteryTotalBlocks.mul(startLotteryRewardPercentage).div(PERCENTAGE_DIVISOR);
		if (totalRewardBlocks == 0) {
			totalRewardBlocks = minRewardBlocksAmount;
		}
		return totalRewardBlocks;
	}

	 
	function getCurrentTicketMultiplierHonor() public constant returns (uint256) {
		return currentTicketMultiplierHonor;
	}

	 
	function getCurrentLotteryTargetBalance() public constant returns (uint256, uint256) {
		Lottery memory _lottery = lotteries[numLottery];
		return (_lottery.lotteryTarget, _lottery.bankroll);
	}

	 
	 
	 

	 
	function _createNewLottery() internal returns (bool) {
		numLottery++;
		lotteryTarget = _setting.uintSettings('minBankroll').add(_setting.uintSettings('minBankroll').mul(lotteryTargetIncreasePercentage).div(PERCENTAGE_DIVISOR));
		Lottery storage _lottery = lotteries[numLottery];
		_lottery.lotteryTarget = lotteryTarget;
		_lottery.startTimestamp = now;
		_updateCurrentTicketMultiplier();
		emit LogCreateLottery(numLottery, lotteryTarget);
		return true;
	}

	 
	function _endLottery() internal returns (bool) {
		Lottery storage _currentLottery = lotteries[numLottery];
		require (_currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded) > 0);

		uint256 blockNumberDifference = block.number - lastBlockNumber;
		uint256 targetBlockNumber = 0;
		if (blockNumberDifference < maxBlockSecurityCount.sub(blockSecurityCount)) {
			targetBlockNumber = lastBlockNumber.add(blockSecurityCount);
		} else {
			targetBlockNumber = lastBlockNumber.add(maxBlockSecurityCount.mul(blockNumberDifference.div(maxBlockSecurityCount))).add(blockSecurityCount);
		}
		_currentLottery.lotteryResult = _generateRandomNumber(_currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded), targetBlockNumber);

		 
		 
		if (contractKilled == true && carryOverContribution > 0) {
			lotteryTarget = lotteryTarget.add(carryOverContribution);
			_currentLottery.lotteryTarget = lotteryTarget;
			_currentLottery.bankroll = _currentLottery.bankroll.add(carryOverContribution);
			totalBankroll = totalBankroll.add(carryOverContribution);
			emit LogAddBankRoll(numLottery, carryOverContribution);
		}
		_currentLottery.endTimestamp = now;
		_currentLottery.ended = true;
		uint256 endingLotteryHours = _getHoursBetween(_currentLottery.startTimestamp, now);
		totalLotteryHours = totalLotteryHours.add(endingLotteryHours);

		 
		avgLotteryHours = totalLotteryHours.mul(TWO_DECIMALS).div(numLottery);
		lastLotteryTotalBlocks = _currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded);

		 
		if (_setting.boolSettings('contractKilled') == false && _setting.boolSettings('gamePaused') == false) {
			uint256 lotteryPace = 0;
			if (endingLotteryHours > 0) {
				 
				lotteryPace = avgLotteryHours.mul(TWO_DECIMALS).div(endingLotteryHours).div(TWO_DECIMALS);
			}

			uint256 newMinBankroll = 0;
			if (lotteryPace <= minBankrollDecreaseRate) {
				 
				newMinBankroll = _setting.uintSettings('minBankroll').mul(minBankrollDecreaseRate).div(TWO_DECIMALS);
			} else if (lotteryPace <= minBankrollIncreaseRate) {
				 
				newMinBankroll = _setting.uintSettings('minBankroll').mul(minBankrollIncreaseRate).div(TWO_DECIMALS);
			} else {
				 
				newMinBankroll = _setting.uintSettings('minBankroll').mul(lotteryPace).div(TWO_DECIMALS);
			}
			_setting.spinlotterySetMinBankroll(newMinBankroll);
		}

		emit LogEndLottery(numLottery, _currentLottery.lotteryResult);
	}

	 
	function _buyTicket(address _playerAddress, uint256 _tokenAmount, uint256 _ticketType) internal returns (bool) {
		require (_ticketType >=1 && _ticketType <= 3);
		totalBuyTickets++;
		Lottery storage _currentLottery = lotteries[numLottery];

		if (_ticketType > 1) {
			uint256 _ticketMultiplier = TWO_DECIMALS;  
			uint256 _numBlocks = _tokenAmount;
			_tokenAmount = 0;   
		} else {
			_currentLottery.tokenWagered = _currentLottery.tokenWagered.add(_tokenAmount);
			totalTokenWagered = totalTokenWagered.add(_tokenAmount);
			(_ticketMultiplier, _numBlocks) = calculateNumBlocks(_tokenAmount);
		}

		 
		bytes32 _ticketId = keccak256(abi.encodePacked(this, _playerAddress, numLottery, totalBuyTickets));
		Ticket storage _ticket = tickets[_ticketId];
		_ticket.ticketId = _ticketId;
		_ticket.numLottery = numLottery;
		_ticket.playerAddress = _playerAddress;
		_ticket.minNumber = _currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded).add(1);
		_ticket.maxNumber = _currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded).add(_numBlocks);

		playerTokenWagered[numLottery][_playerAddress] = playerTokenWagered[numLottery][_playerAddress].add(_tokenAmount);
		if (_ticketType > 1) {
			_currentLottery.totalBlocksRewarded = _currentLottery.totalBlocksRewarded.add(_numBlocks);
			playerTotalBlocksRewarded[numLottery][_playerAddress] = playerTotalBlocksRewarded[numLottery][_playerAddress].add(_numBlocks);
		} else {
			_currentLottery.totalBlocks = _currentLottery.totalBlocks.add(_numBlocks);
			playerTotalBlocks[numLottery][_playerAddress] = playerTotalBlocks[numLottery][_playerAddress].add(_numBlocks);
		}

		emit LogBuyTicket(numLottery, _ticket.ticketId, _ticket.playerAddress, _tokenAmount, _ticketMultiplier, _ticket.minNumber, _ticket.maxNumber, _ticketType);

		 
		_updateCurrentTicketMultiplier();

		 
		_setting.spinlotteryUpdateTokenToWeiExchangeRate();
		return true;
	}

	 
	function _updateCurrentTicketMultiplier() internal returns (bool) {
		 
		Lottery memory _currentLottery = lotteries[numLottery];
		if (lastLotteryTotalBlocks > _currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded)) {
			 
			uint256 temp = (lastLotteryTotalBlocks.sub(_currentLottery.totalBlocks.add(_currentLottery.totalBlocksRewarded))).mul(TWO_DECIMALS).div(lastLotteryTotalBlocks);
			currentTicketMultiplier = TWO_DECIMALS.add(ticketMultiplierModifier.mul(temp).div(TWO_DECIMALS));
		} else {
			currentTicketMultiplier = TWO_DECIMALS;
		}
		if (block.number > currentTicketMultiplierBlockNumber.add(currentTicketMultiplierBlockSecurityCount) || _currentLottery.tokenWagered == 0) {
			currentTicketMultiplierHonor = currentTicketMultiplier;
			currentTicketMultiplierBlockNumber = block.number;
			emit LogUpdateCurrentTicketMultiplier(currentTicketMultiplierHonor, currentTicketMultiplierBlockNumber);
		}
		return true;
	}

	 
	function _generateRandomNumber(uint256 maxNumber, uint256 targetBlockNumber) internal constant returns (uint256) {
		uint256 randomNumber = 0;
		for (uint256 i = 1; i < blockSecurityCount; i++) {
			randomNumber = ((uint256(keccak256(abi.encodePacked(randomNumber, blockhash(targetBlockNumber-i), numLottery + totalBuyTickets + totalTokenWagered))) % maxNumber)+1);
		}
		return randomNumber;
	}

	 
	function _getHoursBetween(uint256 _startTimestamp, uint256 _endTimestamp) internal pure returns (uint256) {
		uint256 _timestampDiff = _endTimestamp.sub(_startTimestamp);

		uint256 _hours = 0;
		while(_timestampDiff >= 3600) {
			_timestampDiff -= 3600;
			_hours++;
		}
		return _hours;
	}
}