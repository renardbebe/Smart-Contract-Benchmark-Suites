 

 

pragma solidity ^0.4.25;

library SafeMath {

	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		require(c / a == b, "the SafeMath multiplication check failed");
		return c;
	}

	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b > 0, "the SafeMath division check failed");
		uint256 c = a / b;
		return c;
	}

	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b <= a, "the SafeMath subtraction check failed");
		return a - b;
	}

	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		require(c >= a, "the SafeMath addition check failed");
		return c;
	}

	function mod(uint256 a, uint256 b) internal pure returns (uint256) {
		require(b != 0, "the SafeMath modulo check failed");
		return a % b;
	}
}

contract OneHundredthMonkey {

	using SafeMath for uint256;

	 
	 
	 

	 
	uint256 public adminBalance;
	uint256 public foundationBalance;
	address public adminBank;
	address public foundationFund;
	address[] public admins;
	mapping (address => bool) public isAdmin;

	 
	bool public gameActive = false;
	bool public earlyResolveACalled = false;
	bool public earlyResolveBCalled = false;
	uint256 public activationTime = 1541869200;  
	uint256 public miniGamesPerRound = 100; 
	uint256 public miniGamesPerCycle = 1000; 
	uint256 public miniGamePotRate = 25;  
	uint256 public progressivePotRate = 25;  
	uint256 public roundDivRate = 20;  
	uint256 public miniGameDivRate = 10;  
	uint256 public referralRate = 10;  
	uint256 public miniGameAirdropRate = 5;  
	uint256 public adminFeeRate = 5;  
	uint256 public roundPotRate = 48;  
	uint256 internal precisionFactor = 18; 
	uint256 public seedAreward = 25000000000000000; 
	uint256 public seedBreward = 25000000000000000; 
	mapping (uint256 => bool) public miniGameSeedAawarded;
	mapping (uint256 => bool) public miniGameSeedBawarded;
	
	 
	uint256 internal RNGblockDelay = 1;
	uint256 internal salt = 0; 
	bytes32 internal hashA; 
	bytes32 internal hashB; 

	 
	bool public miniGameProcessing;
	uint256 public miniGameCount;
	uint256 public miniGameProcessingBegun;
	mapping (uint256 => bool) public miniGamePrizeClaimed;
	mapping (uint256 => bool) public miniGameAirdropClaimed;
	mapping (uint256 => uint256) public miniGameStartTime;
	mapping (uint256 => uint256) public miniGameEndTime;
	mapping (uint256 => uint256) public miniGameTokens;
	mapping (uint256 => uint256) public miniGameTokensLeft;
	mapping (uint256 => uint256) public miniGameTokensActive;
	mapping (uint256 => uint256) public miniGameTokenRangeMin;
	mapping (uint256 => uint256) public miniGameTokenRangeMax;
	mapping (uint256 => uint256) public miniGamePrizeNumber;
	mapping (uint256 => uint256) public miniGameAirdropNumber;
	mapping (uint256 => uint256) public miniGamePrizePot;
	mapping (uint256 => uint256) public miniGameAirdropPot;
	mapping (uint256 => uint256) public miniGameDivs;
	mapping (uint256 => uint256) public miniGameDivsClaimed;
	mapping (uint256 => address) public miniGamePrizeWinner;
	mapping (uint256 => address) public miniGameAirdropWinner;

	 
	uint256 public roundCount;
	mapping (uint256 => bool) public roundPrizeClaimed;
	mapping (uint256 => bool) public roundPrizeTokenRangeIdentified;
	mapping (uint256 => uint256) public roundStartTime;
	mapping (uint256 => uint256) public roundEndTime;
	mapping (uint256 => uint256) public roundTokens;
	mapping (uint256 => uint256) public roundTokensActive;
	mapping (uint256 => uint256) public roundTokenRangeMin;
	mapping (uint256 => uint256) public roundTokenRangeMax;
	mapping (uint256 => uint256) public roundPrizeNumber;
	mapping (uint256 => uint256) public roundPrizePot;
	mapping (uint256 => uint256) public roundDivs;
	mapping (uint256 => uint256) public roundDivsClaimed;
	mapping (uint256 => uint256) public roundPrizeInMinigame;
	mapping (uint256 => address) public roundPrizeWinner;

	 
	bool public cycleOver = false;
	bool public cylcePrizeClaimed;
	bool public cyclePrizeTokenRangeIdentified;
	uint256 public totalVolume;
	uint256 public totalBuys;
	uint256 public tokenSupply;
	uint256 public cycleActiveTokens;
	uint256 public cycleCount;
	uint256 public cycleEnded;
	uint256 public cycleProgressivePot;
	uint256 public cyclePrizeWinningNumber;
	uint256 public cyclePrizeInMinigame;
	uint256 public cyclePrizeInRound;
	uint256 public cycleStartTime;
	address public cyclePrizeWinner;

	 
	uint256 public tokenPrice = 0.001 ether; 
	uint256 public tokenPriceIncrement = 0.0005 ether; 
	uint256 public minTokensPerMiniGame = 10000;  

	 
	address[] public uniqueAddress;
	mapping (address => bool) public knownUsers;
	mapping (address => uint256) public userTokens;
	mapping (address => uint256) public userBalance;
	mapping (address => mapping (uint256 => uint256)) public userMiniGameTokens;
	mapping (address => mapping (uint256 => uint256)) public userRoundTokens;
	mapping (address => mapping (uint256 => uint256[])) public userMiniGameTokensMin;
	mapping (address => mapping (uint256 => uint256[])) public userMiniGameTokensMax;

	 
	mapping (address => bool) internal userCycleChecked;
	mapping (address => uint256) internal userLastMiniGameInteractedWith;
	mapping (address => uint256) internal userLastRoundInteractedWith;
	mapping (address => uint256) internal userLastMiniGameChecked;
	mapping (address => uint256) internal userLastRoundChecked;
	mapping (address => mapping (uint256 => uint256)) internal userShareMiniGame;
	mapping (address => mapping (uint256 => uint256)) internal userDivsMiniGameTotal;
	mapping (address => mapping (uint256 => uint256)) internal userDivsMiniGameClaimed;
	mapping (address => mapping (uint256 => uint256)) internal userDivsMiniGameUnclaimed;
	mapping (address => mapping (uint256 => uint256)) internal userShareRound;
	mapping (address => mapping (uint256 => uint256)) internal userDivsRoundTotal;
	mapping (address => mapping (uint256 => uint256)) internal userDivsRoundClaimed;
	mapping (address => mapping (uint256 => uint256)) internal userDivsRoundUnclaimed;

	
	 
	 
	 

	constructor(address _adminBank, address _foundationFund, address _adminTwo, address _adminThree, address _adminFour) public {
		 
		adminBank = _adminBank;
		foundationFund = _foundationFund;
		admins.push(msg.sender);
		isAdmin[msg.sender] = true;
		admins.push(_adminTwo);
		isAdmin[_adminTwo] = true; 
		admins.push(_adminThree);
		isAdmin[_adminThree] = true; 
		admins.push(_adminFour);
		isAdmin[_adminFour] = true; 
	}

	
	 
	 
	 

	modifier onlyAdmins() {
		require (isAdmin[msg.sender] == true, "you must be an admin");
		_;
	}

	modifier onlyHumans() { 
	    require (msg.sender == tx.origin, "only approved contracts allowed"); 
	    _; 
	  }

	modifier gameOpen() {
		require (gameActive == true || now >= activationTime, "the game must be open");
	  	if (miniGameProcessing == true) {
	  		require (block.number > miniGameProcessingBegun + RNGblockDelay, "the round is still processing. try again soon");
	  	}
	  	_;
	}
    
    
     
	 
	 

	event adminWithdrew(
		uint256 _amount,
		address indexed _caller,
		string _message 
	);

	event cycleStarted(
		address indexed _caller,
		string _message
	);

	event adminAdded(
		address indexed _caller,
		address indexed _newAdmin,
		string _message
	);

	event resolvedEarly(
		address indexed _caller,
		uint256 _pot,
		string _message
	);

	event processingRestarted(
		address indexed _caller,
		string _message
	);

	event contractDestroyed(
		address indexed _caller,
		uint256 _balance,
		string _message
	);

	event userBought(
		address indexed _user,
		uint256 _tokensBought,
		uint256 indexed _miniGameID,
		string _message
	);

	event userReinvested(
		address indexed _user,
		uint256 _amount,
		string _message
	);

	event userWithdrew(
		address indexed _user,
		uint256 _amount,
		string _message
	);

	event processingStarted(
		address indexed _caller,
		uint256 indexed _miniGameID,
		uint256 _blockNumber,
		string _message
	);

	event processingFinished(
		address indexed _caller,
		uint256 indexed _miniGameID,
		uint256 _blockNumber,
		string _message
	);

	event newMinigameStarted(
		uint256 indexed _miniGameID,
		uint256 _newTokens,
		string _message
	);

	event miniGamePrizeAwarded(
		uint256 indexed _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event miniGameAirdropAwarded(
		uint256 indexed _miniGameID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event roundPrizeAwarded(
		uint256 indexed _roundID,
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);

	event cyclePrizeAwarded(
		uint256 _winningNumber,
		uint256 _prize,
		string _message
	);


	 
	 
	 

	function adminWithdraw() external {
		require (isAdmin[msg.sender] == true || msg.sender == adminBank);
		require (adminBalance > 0, "there must be a balance");
		uint256 balance = adminBalance;
		adminBalance = 0;
		adminBank.call.value(balance).gas(100000)();

		emit adminWithdrew(balance, msg.sender, "an admin just withdrew to the admin bank");
	}

	function foundationWithdraw() external {
		require (isAdmin[msg.sender] == true || msg.sender == foundationFund);
		require (adminBalance > 0, "there must be a balance");
		uint256 balance = foundationBalance;
		foundationBalance = 0;
		foundationFund.call.value(balance).gas(100000)();

		emit adminWithdrew(balance, msg.sender, "an admin just withdrew to the foundation fund");
	}

	 
	 
	 
	function earlyResolveA() external onlyAdmins() onlyHumans() gameOpen() {
		require (now > miniGameStartTime[miniGameCount] + 604800 && miniGameProcessing == false, "earlyResolveA cannot be called yet");  
		require (miniGamePrizePot[miniGameCount].sub(seedAreward).sub(seedBreward) >= 0);
		
		gameActive = false;
		earlyResolveACalled = true;
		generateSeedA();
	}

	 
	function earlyResolveB() external onlyAdmins() onlyHumans() {
		require (earlyResolveACalled == true && earlyResolveBCalled == false && miniGameProcessing == true && block.number > miniGameProcessingBegun + RNGblockDelay, "earlyResolveB cannot be called yet"); 
		
		earlyResolveBCalled = true;
		resolveCycle();

		emit resolvedEarly(msg.sender, cycleProgressivePot, "the cycle was resolved early"); 
	}

	 
	function restartMiniGame() external onlyAdmins() onlyHumans() {
		require (miniGameProcessing == true && block.number > miniGameProcessingBegun + 256, "restartMiniGame cannot be called yet");
		
		generateSeedA();

		emit processingRestarted(msg.sender, "mini-game processing was restarted");
	}

	 
	 
	function zeroOut() external onlyAdmins() onlyHumans() {
	    require (now >= cycleEnded + 30 days && cycleOver == true, "too early to close the contract"); 
	    
	  	 
	    emit contractDestroyed(msg.sender, address(this).balance, "contract destroyed"); 

	    selfdestruct(foundationFund);
	}


	 
	 
	 

	function () external payable onlyHumans() gameOpen() {
		 
		 
		buyInternal(msg.value, 0x0);
	}

	function buy(address _referral) public payable onlyHumans() gameOpen() {
		buyInternal(msg.value, _referral);
	}
	
	function reinvest(uint256 _amount, address _referral) external onlyHumans() gameOpen() {
		 
		updateUserBalance(msg.sender);

		require (_amount <= userBalance[msg.sender], "insufficient balance");
		require (_amount >= tokenPrice, "you must buy at least one token");

		 
		userBalance[msg.sender] = userBalance[msg.sender].sub(_amount);
		
		buyInternal(_amount, _referral);

		emit userReinvested(msg.sender, _amount, "a user reinvested");
	}

	function withdraw() external onlyHumans() {
		 
		updateUserBalance(msg.sender);

		require (userBalance[msg.sender] > 0, "no balance to withdraw");
		require (userBalance[msg.sender] <= address(this).balance, "you cannot withdraw more than the contract holds");

		 
		uint256 toTransfer = userBalance[msg.sender];
		userBalance[msg.sender] = 0;
		msg.sender.transfer(toTransfer);

		emit userWithdrew(msg.sender, toTransfer, "a user withdrew");
	}


	 
	 
	 

	 
	function getValueOfRemainingTokens() public view returns(uint256 _tokenValue){
		return miniGameTokensLeft[miniGameCount].mul(tokenPrice);
	}

	 
	function getCurrentMinigamePrizePot() public view returns(uint256 _mgPrize){
	    return miniGamePrizePot[miniGameCount];
	}

	 
	function getCurrentRoundPrizePot() public view returns(uint256 _rndPrize){
	    return roundPrizePot[roundCount];
	}

	 
	function contractBalance() external view returns(uint256 _contractBalance) {
	    return address(this).balance;
	}

	 
	function checkUserDivsAvailable(address _user) external view returns(uint256 _userDivsAvailable) {
		return userBalance[_user] + checkDivsMgView(_user) + checkDivsRndView(_user) + checkPrizesView(_user);
	}

	 
	function userOddsMiniGame(address _user) external view returns(uint256) {
		 
		return userMiniGameTokens[_user][miniGameCount].mul(10 ** 5).div(miniGameTokensActive[miniGameCount]).add(5).div(10);
	}

	 
	function userOddsRound(address _user) external view returns(uint256) {
		 
		return userRoundTokens[_user][roundCount].mul(10 ** 5).div(roundTokensActive[roundCount]).add(5).div(10);
	}

	 
	function userOddsCycle(address _user) external view returns(uint256) {
		 
		return userTokens[_user].mul(10 ** 5).div(cycleActiveTokens).add(5).div(10);
	}

	 
	function miniGameInfo() external view returns(
		uint256 _id,
		uint256 _miniGameTokens,
		uint256 _miniGameTokensLeft,
		uint256 _miniGamePrizePot,
		uint256 _miniGameAirdropPot,
		uint256 _miniGameStartTime
		) {

		return (
			miniGameCount,
			miniGameTokens[miniGameCount],
			miniGameTokensLeft[miniGameCount],
			miniGamePrizePot[miniGameCount],
			miniGameAirdropPot[miniGameCount],
			miniGameStartTime[miniGameCount]
		);
	}

	 
	function roundInfo() external view returns(
		uint256 _id,
		uint256 _roundPrize,
		uint256 _roundStart
		) {

		return (
			roundCount,
			cycleProgressivePot / 2,
			roundStartTime[roundCount]
		);
	}

	 
	function contractInfo() external view returns(
		uint256 _balance,
		uint256 _volume,
		uint256 _totalBuys,
		uint256 _totalUsers,
		uint256 _tokenSupply,
		uint256 _tokenPrice
		) {

		return (
			address(this).balance,
			totalVolume,
			totalBuys,
			uniqueAddress.length,
			tokenSupply,
			tokenPrice
		);
	}

	 
	function cycleInfo() external view returns(
		bool _cycleComplete,
		uint256 _currentRound,
		uint256 _currentMinigame,
		uint256 _tokenSupply,
		uint256 _progressivePot,
		bool _prizeClaimed,
		uint256 _winningNumber
		) {
		bool isActive;
		if (miniGameCount < 1000) {
			isActive = true;
			} else {
				isActive = false;
			}
		
		return (
			isActive,
			roundCount,
			miniGameCount,
			tokenSupply,
			cycleProgressivePot,
			cylcePrizeClaimed,
			cyclePrizeWinningNumber
		);
	}


	 
	 
	 

	function startCycle() internal {
		require (gameActive == false && cycleCount == 0, "the cycle has already been started");
		
		gameActive = true;
		cycleStart();
		roundStart();
		miniGameStart();

		emit cycleStarted(msg.sender, "a new cycle just started"); 
	}

	function buyInternal(uint256 _amount, address _referral) internal {
		require (_amount >= tokenPrice, "you must buy at least one token");
		require (userMiniGameTokensMin[msg.sender][miniGameCount].length < 10, "you are buying too often in this round");  

		 
		if (gameActive == false && now >= activationTime) {
			startCycle();
		}

		 
		if (userLastRoundInteractedWith[msg.sender] < roundCount || userLastMiniGameInteractedWith[msg.sender] < miniGameCount) {
			updateUserBalance(msg.sender);
		}

		 
		if (miniGameProcessing == true && block.number > miniGameProcessingBegun + RNGblockDelay) {
			generateSeedB();
		}

		 
		if (knownUsers[msg.sender] == false) {
			uniqueAddress.push(msg.sender);
			knownUsers[msg.sender] = true;
		}

		 
		uint256 tokensPurchased;
		uint256 ethSpent = _amount;
		uint256 valueOfRemainingTokens = miniGameTokensLeft[miniGameCount].mul(tokenPrice);

		 
		if (ethSpent >= valueOfRemainingTokens) {
			uint256 incomingValue = ethSpent;
			ethSpent = valueOfRemainingTokens;
			tokensPurchased = miniGameTokensLeft[miniGameCount];
			miniGameTokensLeft[miniGameCount] = 0;
			uint256 ethCredit = incomingValue.sub(ethSpent);
			userBalance[msg.sender] += ethCredit;
			generateSeedA();
		} else {
			tokensPurchased = ethSpent.div(tokenPrice);
		}

		 
		userTokens[msg.sender] += tokensPurchased;
		userMiniGameTokens[msg.sender][miniGameCount] += tokensPurchased;
		userRoundTokens[msg.sender][roundCount] += tokensPurchased;
		 
		userMiniGameTokensMin[msg.sender][miniGameCount].push(cycleActiveTokens + 1);
		userMiniGameTokensMax[msg.sender][miniGameCount].push(cycleActiveTokens + tokensPurchased);
		 
		userLastMiniGameInteractedWith[msg.sender] = miniGameCount;
		userLastRoundInteractedWith[msg.sender] = roundCount;	

		uint256 referralShare = (ethSpent.mul(referralRate)).div(100);
		 
			if (_referral != 0x0000000000000000000000000000000000000000 && _referral != msg.sender) {
	       
	      userBalance[_referral] += referralShare;
	   	} else if (_referral == 0x0000000000000000000000000000000000000000 || _referral == msg.sender){
	   		 
	   		cycleProgressivePot += referralShare;
	   	}

		 
		uint256 adminShare = (ethSpent.mul(adminFeeRate)).div(100);
		adminBalance += adminShare;

		uint256 mgDivs = (ethSpent.mul(miniGameDivRate)).div(100);
		miniGameDivs[miniGameCount] += mgDivs;

		uint256 roundDivShare = ethSpent.mul(roundDivRate).div(100);
		roundDivs[roundCount] += roundDivShare;

		uint256 miniGamePrize = ethSpent.mul(miniGamePotRate).div(100);
		miniGamePrizePot[miniGameCount] += miniGamePrize;

		uint256 miniGameAirdrop = ethSpent.mul(miniGameAirdropRate).div(100);
		miniGameAirdropPot[miniGameCount] += miniGameAirdrop;

		uint256 cyclePot = ethSpent.mul(progressivePotRate).div(100);
		cycleProgressivePot += cyclePot;

     	 
     	if (miniGameTokensLeft[miniGameCount] > 0) {
			miniGameTokensLeft[miniGameCount] = miniGameTokensLeft[miniGameCount].sub(tokensPurchased);
		}
		cycleActiveTokens += tokensPurchased;
		roundTokensActive[roundCount] += tokensPurchased;
		miniGameTokensActive[miniGameCount] += tokensPurchased;
		totalVolume += ethSpent;
		totalBuys++;

         
		updateUserBalance(msg.sender);

		emit userBought(msg.sender, tokensPurchased, miniGameCount, "a user just bought tokens");
	}

	function checkDivs(address _user) internal {
		 
		uint256 _mg = userLastMiniGameInteractedWith[_user];
		uint256 _rnd = userLastRoundInteractedWith[_user];

		 
		userShareMiniGame[_user][_mg] = userMiniGameTokens[_user][_mg].mul(10 ** (precisionFactor + 1)).div(miniGameTokens[_mg] + 5).div(10);
	    userDivsMiniGameTotal[_user][_mg] = miniGameDivs[_mg].mul(userShareMiniGame[_user][_mg]).div(10 ** precisionFactor);
	    userDivsMiniGameUnclaimed[_user][_mg] = userDivsMiniGameTotal[_user][_mg].sub(userDivsMiniGameClaimed[_user][_mg]);
	     
	    if (userDivsMiniGameUnclaimed[_user][_mg] > 0) {
			 
			assert(userDivsMiniGameUnclaimed[_user][_mg] <= miniGameDivs[_mg]);
			assert(userDivsMiniGameUnclaimed[_user][_mg] <= address(this).balance);
			 
			userDivsMiniGameClaimed[_user][_mg] = userDivsMiniGameTotal[_user][_mg];
			uint256 shareTempMg = userDivsMiniGameUnclaimed[_user][_mg];
			userDivsMiniGameUnclaimed[_user][_mg] = 0;
			userBalance[_user] += shareTempMg;
			miniGameDivsClaimed[_mg] += shareTempMg;
		    }
	     
		userShareRound[_user][_rnd] = userRoundTokens[_user][_rnd].mul(10 ** (precisionFactor + 1)).div(roundTokensActive[_rnd] + 5).div(10);
	    userDivsRoundTotal[_user][_rnd] = roundDivs[_rnd].mul(userShareRound[_user][_rnd]).div(10 ** precisionFactor);
	    userDivsRoundUnclaimed[_user][_rnd] = userDivsRoundTotal[_user][_rnd].sub(userDivsRoundClaimed[_user][_rnd]);
	     
	    if (userDivsRoundUnclaimed[_user][_rnd] > 0) {
			 
			assert(userDivsRoundUnclaimed[_user][_rnd] <= roundDivs[_rnd]);
			assert(userDivsRoundUnclaimed[_user][_rnd] <= address(this).balance);
			 
			userDivsRoundClaimed[_user][_rnd] = userDivsRoundTotal[_user][_rnd];
			uint256 shareTempRnd = userDivsRoundUnclaimed[_user][_rnd];
			userDivsRoundUnclaimed[_user][_rnd] = 0;
			userBalance[_user] += shareTempRnd;
			roundDivsClaimed[_rnd] += shareTempRnd;
	    }	
	}

	function checkPrizes(address _user) internal {
		 
		if (cycleOver == true && userCycleChecked[_user] == false) {
			 
			uint256 mg = cyclePrizeInMinigame;
			 
			if (cylcePrizeClaimed == false && userMiniGameTokensMax[_user][mg].length > 0) {
				 
				 
	  			for (uint256 i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
	  				if (cyclePrizeWinningNumber >= userMiniGameTokensMin[_user][mg][i] && cyclePrizeWinningNumber <= userMiniGameTokensMax[_user][mg][i]) {
	  					userBalance[_user] += cycleProgressivePot;
	  					cylcePrizeClaimed = true;
						cyclePrizeWinner = msg.sender;				
	  					break;
	  				}
	  			}
			}
			userCycleChecked[_user] = true;
		}
		 
		if (roundPrizeClaimed[userLastRoundInteractedWith[_user]] == false && roundPrizeTokenRangeIdentified[userLastRoundInteractedWith[_user]]) {
			 
			uint256 rnd = userLastRoundInteractedWith[_user];
			uint256 mgp = roundPrizeInMinigame[rnd];
			 
			for (i = 0; i < userMiniGameTokensMin[_user][mgp].length; i++) {
				if (roundPrizeNumber[rnd] >= userMiniGameTokensMin[_user][mgp][i] && roundPrizeNumber[rnd] <= userMiniGameTokensMax[_user][mgp][i]) {
					userBalance[_user] += roundPrizePot[mgp];
					roundPrizeClaimed[rnd] = true;
					roundPrizeWinner[rnd] = msg.sender;		
					break;
				}
			}
			userLastRoundChecked[_user] = userLastRoundInteractedWith[_user];
		}
		 
		if (userLastMiniGameChecked[_user] < userLastMiniGameInteractedWith[_user] && miniGameCount > userLastMiniGameInteractedWith[_user]) {
			 
			mg = userLastMiniGameInteractedWith[_user];
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGamePrizeNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGamePrizeNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					userBalance[_user] += miniGamePrizePot[mg];
					miniGamePrizeClaimed[mg] = true;
					miniGamePrizeWinner[mg] = msg.sender;			
					break;
				}
			}
			 
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGameAirdropNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGameAirdropNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					userBalance[_user] += miniGameAirdropPot[mg];
					miniGameAirdropClaimed[mg] = true;
					miniGameAirdropWinner[mg] = msg.sender;
					break;
				}
			}
			 
			userLastMiniGameChecked[_user] = userLastMiniGameInteractedWith[_user];
		}
	}

	function updateUserBalance(address _user) internal {
		checkDivs(_user);
		checkPrizes(_user);
	}

	function miniGameStart() internal {
		require (cycleOver == false, "the cycle cannot be over");
		
		miniGameCount++;
		miniGameStartTime[miniGameCount] = now;
		 
		if (tokenSupply != 0) {
			miniGameTokenRangeMin[miniGameCount] = tokenSupply + 1;
		} else {
			miniGameTokenRangeMin[miniGameCount] = 0;
		}
		 
		miniGameTokens[miniGameCount] = generateTokens();
		miniGameTokensLeft[miniGameCount] = miniGameTokens[miniGameCount];
		miniGameTokenRangeMax[miniGameCount] = tokenSupply;
		 
		if (miniGameCount > 1) {
			tokenPrice += tokenPriceIncrement;
		}
		 
		if (miniGameCount % miniGamesPerRound == 0 && miniGameCount > 1) {
			awardRoundPrize();
			roundStart();
			tokenPrice = 0.001 ether + 0.0005 ether * roundCount.sub(1);
		}
		 
		if (miniGameCount % (miniGamesPerCycle + 1) == 0 && miniGameCount > 1) {
			awardCyclePrize();
		}

		emit newMinigameStarted(miniGameCount, miniGameTokens[miniGameCount], "new minigame started");
	}

	function roundStart() internal {
		require (cycleOver == false, "the cycle cannot be over");

		roundCount++;
		roundStartTime[roundCount] = now;
		 
		if (tokenSupply != 0) {
			roundTokenRangeMin[roundCount] = miniGameTokenRangeMax[miniGameCount.sub(1)] + 1;
		} else {
			roundTokenRangeMin[roundCount] = 0;
		}
		 
		if (roundCount >= 2) {
			roundTokenRangeMax[roundCount.sub(1)] = miniGameTokenRangeMax[miniGameCount.sub(1)];
			roundTokens[roundCount.sub(1)] = tokenSupply.sub(roundTokenRangeMin[roundCount.sub(1)]);
		}
	}

	function cycleStart() internal {
		require (cycleOver == false, "the cycle cannot be over");

		cycleCount++;
		cycleStartTime = now;
	}

	function generateTokens() internal returns(uint256 _tokens) {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 randTokens = uint256(hash).mod(minTokensPerMiniGame);
    	uint256 newMinGameTokens = randTokens + minTokensPerMiniGame;
		tokenSupply += newMinGameTokens;
		salt++;

		return newMinGameTokens;
	}

	function generateSeedA() internal {
		require (miniGameProcessing == false || miniGameProcessing == true && block.number > miniGameProcessingBegun + 256, "seed A cannot be regenerated right now");
		require (miniGameTokensLeft[miniGameCount] == 0 || earlyResolveACalled == true, "active tokens remain in this minigame");
		
		miniGameProcessing = true;
		miniGameProcessingBegun = block.number;
		 
		hashA = blockhash(miniGameProcessingBegun - 1);
		 
		if (miniGameCount > 1) {
			miniGameEndTime[miniGameCount] = now;
		}
		if (miniGameCount % miniGamesPerRound == 0) {
			roundEndTime[roundCount] = now;
		}
		 
		if (miniGameSeedAawarded[miniGameCount] == false) {
			userBalance[msg.sender] += seedAreward;
			miniGameSeedAawarded[miniGameCount] = true;
		}
		salt++;

		emit processingStarted(msg.sender, miniGameCount, block.number, "processing started");
	}

	function generateSeedB() internal {
		 
		hashB = blockhash(miniGameProcessingBegun + RNGblockDelay);
		 
		awardMiniGamePrize();
		awardMiniGameAirdrop();
		 
		if (miniGameSeedBawarded[miniGameCount] == false) {
			userBalance[msg.sender] += seedBreward;
			miniGameSeedBawarded[miniGameCount] = true;
		}
		 
		miniGameStart();
		miniGameProcessing = false;
		salt++;

		emit processingFinished(msg.sender, miniGameCount, block.number, "processing finished");
	}

	function awardMiniGamePrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
	    uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount].sub(miniGameTokensLeft[miniGameCount]));
	    miniGamePrizeNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
	    miniGamePrizePot[miniGameCount] = miniGamePrizePot[miniGameCount].sub(seedAreward).sub(seedBreward);
	    salt++;

	    emit miniGamePrizeAwarded(miniGameCount, winningNumber, miniGamePrizePot[miniGameCount], "minigame prize awarded");
	}

	function awardMiniGameAirdrop() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
	    uint256 winningNumber = uint256(hash).mod(miniGameTokens[miniGameCount].sub(miniGameTokensLeft[miniGameCount]));
	    miniGameAirdropNumber[miniGameCount] = winningNumber + miniGameTokenRangeMin[miniGameCount];
	    salt++;

	    emit miniGameAirdropAwarded(miniGameCount, winningNumber, miniGameAirdropPot[miniGameCount], "minigame airdrop awarded");
	}

	function awardRoundPrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
		uint256 currentRoundTokens;
		if (miniGameCount > 1) {
			currentRoundTokens = miniGameTokenRangeMax[miniGameCount.sub(1)].sub(roundTokenRangeMin[roundCount]);
		 
		} else if (miniGameCount == 1) {
			currentRoundTokens = miniGameTokensActive[1];
		}
	    uint256 winningNumber = uint256(hash).mod(currentRoundTokens);
	    roundPrizeNumber[roundCount] = winningNumber + roundTokenRangeMin[roundCount];
	     
	    uint256 roundPrize = cycleProgressivePot.mul(roundPotRate).div(100);
		uint256 adminShare = cycleProgressivePot.mul(4).div(100);
		foundationBalance += adminShare;
	    roundPrizePot[roundCount] = roundPrize;
	    cycleProgressivePot = roundPrize;
	    narrowRoundPrize(roundCount);
	    salt++;

		emit roundPrizeAwarded(roundCount, winningNumber, roundPrize, "round prize awarded");
	}

	function awardCyclePrize() internal {
		bytes32 hash = keccak256(abi.encodePacked(salt, hashA, hashB));
	    uint256 winningNumber;
	    if (miniGameCount > 1) {
	    	winningNumber = uint256(hash).mod(miniGameTokenRangeMax[miniGameCount - 1]);
	     
	    } else if (miniGameCount == 1) {
	    	winningNumber = uint256(hash).mod(miniGameTokensActive[1]);
	    }
	    cyclePrizeWinningNumber = winningNumber;
	    gameActive = false;
	    cycleEnded = now;
	    cycleOver = true;
	    narrowCyclePrize();
	    salt++;

		emit cyclePrizeAwarded(winningNumber, cycleProgressivePot, "cycle prize awarded");
	}

	function resolveCycle() internal {
		 
		hashB = blockhash(miniGameProcessingBegun + RNGblockDelay);
		 
		awardMiniGamePrize();
		awardMiniGameAirdrop();
		awardRoundPrize();
		awardCyclePrize();
		 
		miniGameProcessing = false;
		gameActive = false;
	}

	 
	 
	function narrowRoundPrize(uint256 _ID) internal returns(uint256 _miniGameID) {
		 
		uint256 miniGameRangeMin; 
		uint256 miniGameRangeMax;
		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMax = miniGamesPerRound;
		} else if (_ID >= 2) {
			miniGameRangeMin = _ID.mul(miniGamesPerRound);
			miniGameRangeMax = miniGameRangeMin + miniGamesPerRound - 1;
		}	
		 
		 
	    for (uint256 i = miniGameRangeMin; i <= miniGameRangeMax; i++) {
		    if (roundPrizeNumber[_ID] >= miniGameTokenRangeMin[i] && roundPrizeNumber[_ID] <= miniGameTokenRangeMax[i]) {
	        roundPrizeInMinigame[_ID] = i;
	        roundPrizeTokenRangeIdentified[_ID] = true;
	        return roundPrizeInMinigame[_ID];
	        break;
		    }
	    }	
	}

	 
	 
	function narrowCyclePrize() internal returns(uint256 _miniGameID) {
		 
	    for (uint256 i = 1; i <= roundCount; i++) {
	      if (cyclePrizeWinningNumber >= roundTokenRangeMin[i] && cyclePrizeWinningNumber <= roundTokenRangeMax[i]) {
	        cyclePrizeInRound = i;
	        break;
	      }
	    }
	     
	    uint256 miniGameRangeMin; 
		uint256 miniGameRangeMax;
		uint256 _ID = cyclePrizeInRound;
		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMax = miniGamesPerRound;
		} else if (_ID >= 2) {
			miniGameRangeMin = _ID.mul(miniGamesPerRound);
			miniGameRangeMax = miniGameRangeMin + miniGamesPerRound - 1;
		}	
		 
		 
	    for (i = miniGameRangeMin; i <= miniGameRangeMax; i++) {
			if (cyclePrizeWinningNumber >= miniGameTokenRangeMin[i] && cyclePrizeWinningNumber <= miniGameTokenRangeMax[i]) {
				cyclePrizeInMinigame = i;
				cyclePrizeTokenRangeIdentified = true;
				return cyclePrizeInMinigame;
				break;
			}
	    }	
	}

	 
	function checkDivsMgView(address _user) internal view returns(uint256 _divs) {
		 
		uint256 _mg = userLastMiniGameChecked[_user];
		uint256 mgShare = userShareMiniGame[_user][_mg];
		uint256 mgTotal = userDivsMiniGameTotal[_user][_mg];
		uint256 mgUnclaimed = userDivsMiniGameUnclaimed[_user][_mg];
		 
		mgShare = userMiniGameTokens[_user][_mg].mul(10 ** (precisionFactor + 1)).div(miniGameTokens[_mg] + 5).div(10);
	    mgTotal = miniGameDivs[_mg].mul(mgShare).div(10 ** precisionFactor);
	    mgUnclaimed = mgTotal.sub(userDivsMiniGameClaimed[_user][_mg]);

	    return mgUnclaimed;
	}
	
	 
	function checkDivsRndView(address _user) internal view returns(uint256 _divs) {
		 
		uint256 _rnd = userLastRoundChecked[_user];
		uint256 rndShare = userShareRound[_user][_rnd];
		uint256 rndTotal = userDivsRoundTotal[_user][_rnd];
		uint256 rndUnclaimed = userDivsRoundUnclaimed[_user][_rnd];
         
		rndShare = userRoundTokens[_user][_rnd].mul(10 ** (precisionFactor + 1)).div(roundTokensActive[_rnd] + 5).div(10);
	    rndTotal = roundDivs[_rnd].mul(rndShare).div(10 ** precisionFactor);
	    rndUnclaimed = rndTotal.sub(userDivsRoundClaimed[_user][_rnd]);

	    return rndUnclaimed;
	}

	 
	function checkPrizesView(address _user) internal view returns(uint256 _prizes) {
		 
		uint256 prizeValue;
		 
		if (cycleOver == true && userCycleChecked[_user] == false) {
			 
			uint256 mg;
			if (cyclePrizeTokenRangeIdentified == true) {
				mg = cyclePrizeInMinigame;
			} else {
				narrowCyclePrizeView();
				mg = cyclePrizeInMinigame;
			}
			 
			if (cylcePrizeClaimed == false && userMiniGameTokensMax[_user][mg].length > 0) {
				 
				 
				for (uint256 i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
					if (cyclePrizeWinningNumber >= userMiniGameTokensMin[_user][mg][i] && cyclePrizeWinningNumber <= userMiniGameTokensMax[_user][mg][i]) {
						prizeValue += cycleProgressivePot;			
						break;
					}
				}
			}
		}
		 
		if (userLastRoundChecked[_user] < userLastRoundInteractedWith[_user] && roundCount > userLastRoundInteractedWith[_user]) {
			 
			uint256 mgp;
			uint256 _ID = userLastRoundChecked[_user];
			if (roundPrizeTokenRangeIdentified[_ID] == true) {
				mgp = roundPrizeInMinigame[_ID];
			} else {
				narrowRoundPrizeView(_ID);
				mgp = roundPrizeInMinigame[_ID];
			}
			 
			for (i = 0; i < userMiniGameTokensMin[_user][mgp].length; i++) {
				if (roundPrizeNumber[_ID] >= userMiniGameTokensMin[_user][mgp][i] && roundPrizeNumber[_ID] <= userMiniGameTokensMax[_user][mgp][i]) {
					prizeValue += roundPrizePot[mgp];	
					break;
				}
			}
		}
		 
		if (userLastMiniGameChecked[_user] < userLastMiniGameInteractedWith[_user] && miniGameCount > userLastMiniGameInteractedWith[_user]) {
			 
			mg = userLastMiniGameInteractedWith[_user];
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGamePrizeNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGamePrizeNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					prizeValue += miniGamePrizePot[mg];			
					break;
				}
			}
			 
			for (i = 0; i < userMiniGameTokensMin[_user][mg].length; i++) {
				if (miniGameAirdropNumber[mg] >= userMiniGameTokensMin[_user][mg][i] && miniGameAirdropNumber[mg] <= userMiniGameTokensMax[_user][mg][i]) {
					prizeValue += miniGameAirdropPot[mg];
					break;
				}
			}
		}
		return prizeValue;
	}

	 
	function narrowRoundPrizeView(uint256 _ID) internal view returns(uint256 _miniGameID) {
		 
		uint256 winningNumber = roundPrizeNumber[_ID];
		uint256 miniGameRangeMin; 
		uint256 miniGameRangeMax;
		if (_ID == 1) {
			miniGameRangeMin = 1;
			miniGameRangeMax = miniGamesPerRound;
		} else if (_ID >= 2) {
			miniGameRangeMin = _ID.mul(miniGamesPerRound);
			miniGameRangeMax = miniGameRangeMin + miniGamesPerRound - 1;
		}	
		 
		 
	    for (uint256 i = miniGameRangeMin; i <= miniGameRangeMax; i++) {
			if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
				return i;
				break;
			}
	    }		
	}

	 
	function narrowCyclePrizeView() internal view returns(uint256 _miniGameID) {
		 
		uint256 winningNumber = cyclePrizeWinningNumber;
		uint256 rnd;
		 
	    for (uint256 i = 1; i <= roundCount; i++) {
			if (winningNumber >= roundTokenRangeMin[i] && winningNumber <= roundTokenRangeMax[i]) {
				rnd = i;
				break;
			}
	    }
	     
	    uint256 miniGameRangeMin; 
			uint256 miniGameRangeMax;
			uint256 _ID = rnd;
			if (_ID == 1) {
				miniGameRangeMin = 1;
				miniGameRangeMax = miniGamesPerRound;
			} else if (_ID >= 2) {
				miniGameRangeMin = _ID.mul(miniGamesPerRound);
				miniGameRangeMax = miniGameRangeMin + miniGamesPerRound - 1;
			}	
			 
			 
	    for (i = miniGameRangeMin; i <= miniGameRangeMax; i++) {
			if (winningNumber >= miniGameTokenRangeMin[i] && winningNumber <= miniGameTokenRangeMax[i]) {
				return i;
				break;
			}
	    }			
	}
}