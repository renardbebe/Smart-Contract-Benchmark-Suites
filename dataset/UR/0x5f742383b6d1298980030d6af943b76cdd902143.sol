 

 
pragma solidity 0.4.4;

contract CompetitionStore {
	
 
	
	 
	struct Submission{
		uint32 score; 
		uint32 durationRoundedDown;  
		uint32 version;  
		uint64 seed;  
		uint64 submitBlockNumber;  
		bytes32 proofHash; 
	}
	
	 
	struct Start{
		uint8 competitionIndex;  
		uint32 version;   
		uint64 seed;  
		uint64 time;  
	}
	
	 
	struct Competition{
		uint8 numPastBlocks; 
		uint8 houseDivider;  
		uint16 lag;  
		uint32 verificationWaitTime; 
		uint32 numPlayers; 
		uint32 version;  
		uint32 previousVersion;  
		uint64 versionChangeBlockNumber; 
		uint64 switchBlockNumber;  
		uint64 endTime; 
		uint88 price;   
		uint128 jackpot;  
		uint32[] rewardsDistribution;  
		mapping (address => Submission) submissions;   
		address[] players;  
	}
		
	struct Game{
		mapping (address => Start) starts;  
		Competition[2] competitions;  
		uint8 currentCompetitionIndex;  
	}

	mapping (string => Game) games;
	
	address organiser;  
	address depositAccount;	  

 



 

	 
	event VersionChange(
		string indexed gameID,
		uint32 indexed version,
		bytes32 codeHash  
	);

 




 
	
	 
	function computeSeed(uint64 blockNumber, address player) internal constant returns(uint64 seed){ 
		return uint64(sha3(block.blockhash(blockNumber),block.blockhash(blockNumber-1),block.blockhash(blockNumber-2),block.blockhash(blockNumber-3),block.blockhash(blockNumber-4),block.blockhash(blockNumber-5),player)); 
	}
	
	 
	function getSeedAndState(string gameID, address player) constant returns(uint64 seed, uint64 blockNumber, uint8 competitionIndex, uint32 version, uint64 endTime, uint88 price, uint32 myBestScore, uint64 competitionBlockNumber, uint64 registeredSeed){
		var game = games[gameID];

		competitionIndex = game.currentCompetitionIndex;
		var competition = game.competitions[competitionIndex];

		blockNumber = uint64(block.number-1);
		seed = computeSeed(blockNumber, player);
		version = competition.version;
		endTime = competition.endTime;
		price = competition.price;
		competitionBlockNumber = competition.switchBlockNumber;
		
		if (competition.submissions[player].submitBlockNumber >= competition.switchBlockNumber){
			myBestScore = competition.submissions[player].score;
		}else{
			myBestScore = 0;
		}
		
		registeredSeed = game.starts[player].seed;
	}
	
	
		
	function start(string gameID, uint64 blockNumber,uint8 competitionIndex, uint32 version) payable {
		var game = games[gameID];
		var competition = game.competitions[competitionIndex];

		if(msg.value != competition.price){
			throw;
		}

		if(
			competition.endTime <= now ||  
			competitionIndex != game.currentCompetitionIndex ||  
			version != competition.version && (version != competition.previousVersion || block.number > competition.versionChangeBlockNumber) ||  
			block.number >= competition.numPastBlocks && block.number - competition.numPastBlocks > blockNumber  
			){
				 
				if(msg.value != 0 && !msg.sender.send(msg.value)){
					throw;
				}
				return;
		}
		
		competition.jackpot += uint128(msg.value);  
		
		 
		game.starts[msg.sender] = Start({
			seed: computeSeed(blockNumber,msg.sender)
			, time : uint64(now)
			, competitionIndex : competitionIndex
			, version : version
		}); 
	}
		
	function submit(string gameID, uint64 seed, uint32 score, uint32 durationRoundedDown, bytes32 proofHash){ 
		var game = games[gameID];

		var gameStart = game.starts[msg.sender];
			
		 
		if(gameStart.seed != seed){
			return;
		}
		
		var competition = game.competitions[gameStart.competitionIndex];
		
		 
		if(now - gameStart.time > durationRoundedDown + competition.lag){ 
			return;
		}

		if(now >= competition.endTime + competition.verificationWaitTime){
			return;  
		}
		
		var submission = competition.submissions[msg.sender];
		if(submission.submitBlockNumber < competition.switchBlockNumber){
			if(competition.numPlayers >= 4294967295){  
				return;
			}
		}else if (score <= submission.score){
			return;
		}
		
		var players = competition.players;
		 
		if(submission.submitBlockNumber < competition.switchBlockNumber){
			var currentNumPlayer = competition.numPlayers;
			if(currentNumPlayer >= players.length){
				players.push(msg.sender);
			}else{
				players[currentNumPlayer] = msg.sender;
			}
			competition.numPlayers = currentNumPlayer + 1;
		}
		
		competition.submissions[msg.sender] = Submission({
			proofHash:proofHash,
			seed:gameStart.seed,
			score:score,
			durationRoundedDown:durationRoundedDown,
			submitBlockNumber:uint64(block.number),
			version:gameStart.version
		});
		
	}
	
	 
	function increaseJackpot(string gameID) payable{
		var game = games[gameID];
		game.competitions[game.currentCompetitionIndex].jackpot += uint128(msg.value);  
	}

 

	
 
		
	function CompetitionStore(){
		organiser = msg.sender;
		depositAccount = msg.sender;
	}

	
	 
	function _startNextCompetition(string gameID, uint32 version, uint88 price, uint8 numPastBlocks, uint8 houseDivider, uint16 lag, uint64 duration, uint32 verificationWaitTime, bytes32 codeHash, uint32[] rewardsDistribution) payable{
		if(msg.sender != organiser){
			throw;
		}
		var game = games[gameID];
		var newCompetition = game.competitions[1 - game.currentCompetitionIndex]; 
		var currentCompetition = game.competitions[game.currentCompetitionIndex];
		 
		if(currentCompetition.endTime >= now){
			throw;
		}

		 
		if(newCompetition.numPlayers > 0){
			throw;
		}
		
		if(houseDivider == 0){ 
			throw;
		}
		
		if(numPastBlocks < 1){
			throw;
		}
		
		if(rewardsDistribution.length == 0 || rewardsDistribution.length > 64){  
			throw;
		}
		 
		uint32 prev = 0;
		for(uint8 i = 0; i < rewardsDistribution.length; i++){
			if(rewardsDistribution[i] == 0 ||  (prev != 0 && rewardsDistribution[i] > prev)){
				throw;
			}
			prev = rewardsDistribution[i];
		}

		if(version != currentCompetition.version){
			VersionChange(gameID,version,codeHash); 
		}
		
		game.currentCompetitionIndex = 1 - game.currentCompetitionIndex;
		
		newCompetition.switchBlockNumber = uint64(block.number);
		newCompetition.previousVersion = 0;
		newCompetition.versionChangeBlockNumber = 0;
		newCompetition.version = version;
		newCompetition.price = price; 
		newCompetition.numPastBlocks = numPastBlocks;
		newCompetition.rewardsDistribution = rewardsDistribution;
		newCompetition.houseDivider = houseDivider;
		newCompetition.lag = lag;
		newCompetition.jackpot += uint128(msg.value);  
		newCompetition.endTime = uint64(now) + duration;
		newCompetition.verificationWaitTime = verificationWaitTime;
	}
	
	
	
	function _setBugFixVersion(string gameID, uint32 version, bytes32 codeHash, uint32 numBlockAllowedForPastVersion){
		if(msg.sender != organiser){
			throw;
		}

		var game = games[gameID];
		var competition = game.competitions[game.currentCompetitionIndex];
		
		if(version <= competition.version){  
			throw;
		}
		
		if(competition.endTime <= now){  
			return;
		}
		
		competition.previousVersion = competition.version;
		competition.versionChangeBlockNumber = uint64(block.number + numBlockAllowedForPastVersion);
		competition.version = version;
		VersionChange(gameID,version,codeHash);
	}

	function _setLagParams(string gameID, uint16 lag, uint8 numPastBlocks){
		if(msg.sender != organiser){
			throw;
		}
		
		if(numPastBlocks < 1){
			throw;
		}

		var game = games[gameID];
		var competition = game.competitions[game.currentCompetitionIndex];
		competition.numPastBlocks = numPastBlocks;
		competition.lag = lag;
	}

	function _rewardWinners(string gameID, uint8 competitionIndex, address[] winners){
		if(msg.sender != organiser){
			throw;
		}
		
		var competition = games[gameID].competitions[competitionIndex];

		 
		 
		if(int(now) - competition.endTime < competition.verificationWaitTime){
			throw;
		}

		
		if( competition.jackpot > 0){  

			
			var rewardsDistribution = competition.rewardsDistribution;

			uint8 numWinners = uint8(rewardsDistribution.length);

			if(numWinners > uint8(winners.length)){
				numWinners = uint8(winners.length);
			}

			uint128 forHouse = competition.jackpot;
			if(numWinners > 0 && competition.houseDivider > 1){  
				forHouse = forHouse / competition.houseDivider;
				uint128 forWinners = competition.jackpot - forHouse;

				uint64 total = 0;
				for(uint8 i=0; i<numWinners; i++){  
					total += rewardsDistribution[i];
				}
				for(uint8 j=0; j<numWinners; j++){
					uint128 value = (forWinners * rewardsDistribution[j]) / total;
					if(!winners[j].send(value)){  
						forHouse = forHouse + value;
					}
				}
			}
			
			if(!depositAccount.send(forHouse)){
				 
				var nextCompetition = games[gameID].competitions[1 - competitionIndex];
				nextCompetition.jackpot = nextCompetition.jackpot + forHouse;	
			}

			
			competition.jackpot = 0;
		}
		
		
		competition.numPlayers = 0;
	}

	
	 
	function _setDepositAccount(address newDepositAccount){
		if(depositAccount != msg.sender){
			throw;
		}
		depositAccount = newDepositAccount;
	}
	
	 
	function _setOrganiser(address newOrganiser){
		if(organiser != msg.sender){
			throw;
		}
		organiser = newOrganiser;
	}
	
	
 

 

	function getPlayerSubmissionFromCompetition(string gameID, uint8 competitionIndex, address playerAddress) constant returns(uint32 score, uint64 seed, uint32 duration, bytes32 proofHash, uint32 version, uint64 submitBlockNumber){
		var submission = games[gameID].competitions[competitionIndex].submissions[playerAddress];
		score = submission.score;
		seed = submission.seed;		
		duration = submission.durationRoundedDown;
		proofHash = submission.proofHash;
		version = submission.version;
		submitBlockNumber =submission.submitBlockNumber;
	}
	
	function getPlayersFromCompetition(string gameID, uint8 competitionIndex) constant returns(address[] playerAddresses, uint32 num){
		var competition = games[gameID].competitions[competitionIndex];
		playerAddresses = competition.players;
		num = competition.numPlayers;
	}

	function getCompetitionValues(string gameID, uint8 competitionIndex) constant returns (
		uint128 jackpot,
		uint88 price,
		uint32 version,
		uint8 numPastBlocks,
		uint64 switchBlockNumber,
		uint32 numPlayers,
		uint32[] rewardsDistribution,
		uint8 houseDivider,
		uint16 lag,
		uint64 endTime,
		uint32 verificationWaitTime,
		uint8 _competitionIndex
	){
		var competition = games[gameID].competitions[competitionIndex];
		jackpot = competition.jackpot;
		price = competition.price;
		version = competition.version;
		numPastBlocks = competition.numPastBlocks;
		switchBlockNumber = competition.switchBlockNumber;
		numPlayers = competition.numPlayers;
		rewardsDistribution = competition.rewardsDistribution;
		houseDivider = competition.houseDivider;
		lag = competition.lag;
		endTime = competition.endTime;
		verificationWaitTime = competition.verificationWaitTime;
		_competitionIndex = competitionIndex;
	}
	
	function getCurrentCompetitionValues(string gameID) constant returns (
		uint128 jackpot,
		uint88 price,
		uint32 version,
		uint8 numPastBlocks,
		uint64 switchBlockNumber,
		uint32 numPlayers,
		uint32[] rewardsDistribution,
		uint8 houseDivider,
		uint16 lag,
		uint64 endTime,
		uint32 verificationWaitTime,
		uint8 _competitionIndex
	)
	{
		return getCompetitionValues(gameID,games[gameID].currentCompetitionIndex);
	}
}