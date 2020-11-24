 

contract euroteambet {

	struct team {
		string teamName;
		mapping(address => uint) bet;
		uint totalBet;
	}

	team[] public euroTeams;

	bool winningTeamDefined;
	uint winningTeam;

	 
	uint startCompetitionTime;

	 
	uint public globalBet;

	 
	address creator;
	uint feeCollected;

	 
	function euroteambet() {
		 
		team memory toCreate;
		 
		toCreate.teamName = '';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Albania';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Austria';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Belgium';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Croatia';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Czech Republic';
		euroTeams.push(toCreate);
		toCreate.teamName = 'England';
		euroTeams.push(toCreate);
		toCreate.teamName = 'France';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Germany';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Hungary';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Iceland';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Italy';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Nothern Ireland';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Poland';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Portugal';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Republic of Ireland';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Romania';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Russia';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Slovakia';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Spain';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Sweden';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Switzerland';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Turkey';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Ukraine';
		euroTeams.push(toCreate);
		toCreate.teamName = 'Wales';
		euroTeams.push(toCreate);

		creator = msg.sender;

		winningTeamDefined = false;

		 
		startCompetitionTime = block.timestamp + (60 * 60 * 24) * 4;

	}


	event BetFromTransaction(address indexed from, uint value);
	event CollectFromTransaction(address indexed from, uint value);	
	event BetClosedNoWinningTeam(address indexed from, uint value);	
	 
	function () {
		if (startCompetitionTime >= block.timestamp) {
			if (msg.value >= 100 finney) {
				BetFromTransaction(msg.sender, msg.value);
				betOnATeam((msg.value % 100 finney) / 1000000000000000);
			} else {
				msg.sender.send(msg.value);
				return;
			}
		} else if (winningTeamDefined == true) {
			CollectFromTransaction(msg.sender, msg.value);
			collectEarnings();
		} else {
			BetClosedNoWinningTeam(msg.sender, msg.value);
			if(msg.value > 0){
				msg.sender.send(msg.value);
			}
			return;
		}
	}

	 
	function setWinner(uint teamWinningID) {
		 
		if (msg.sender == creator) {
			winningTeam = teamWinningID;
			winningTeamDefined = true;
		} else {
			if(msg.value > 0){
				msg.sender.send(msg.value);
			}
			return;
		}
	}


	event BetOnATeam(address indexed from, uint indexed id, uint value);
	 
	function betOnATeam(uint id) {
		if (startCompetitionTime >= block.timestamp && msg.value >= 100 finney && id >= 1 && id <= 24) {

			uint amount = msg.value;

			 
			feeCollected += (amount * 3 / 100);
			amount -= (amount * 3 / 100);

			BetOnATeam(msg.sender, id, amount);

			euroTeams[id].bet[msg.sender] += amount;
			euroTeams[id].totalBet += amount;
			globalBet += amount;
		} else {
			if(msg.value > 0){
				msg.sender.send(msg.value);
			}
			return;
		}
	}

	 
	function checkEarnings(address toCheck) returns (uint) {
		if(msg.value > 0){
			msg.sender.send(msg.value);
		}

		if (winningTeamDefined == true) {
			return (globalBet * (euroTeams[winningTeam].bet[toCheck] / euroTeams[winningTeam].totalBet));
		} else {
			return 0;
		}
	}

	 
	function collectEarnings() {
		if(msg.value > 0){
			msg.sender.send(msg.value);
		}
		if (winningTeamDefined == true) {
			uint earnings = (globalBet * (euroTeams[winningTeam].bet[msg.sender] / euroTeams[winningTeam].totalBet));
			msg.sender.send(earnings);
			euroTeams[winningTeam].bet[msg.sender] = 0;
		} else {
			return;
		}
	}

	 
	function sendEarnings(address toSend) {
		if(msg.value > 0){
			msg.sender.send(msg.value);
		}
		if (msg.sender == creator && winningTeamDefined == true) {
			uint earnings = (globalBet * (euroTeams[winningTeam].bet[toSend] / euroTeams[winningTeam].totalBet));
			toSend.send(earnings);
			euroTeams[winningTeam].bet[toSend] = 0;
		} else {
			return;
		}
	}

	 
	function collectFee() {
		msg.sender.send(msg.value);
		if (msg.sender == creator) {
			creator.send(feeCollected);
			feeCollected = 0;
		} else {
			return;
		}
	}

}