 

contract BCFBaseCompetition {
    address public owner;
    address public referee;

    bool public paused = false;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyReferee() {
        require(msg.sender == referee);
        _;
    }

    function setOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

    function setReferee(address newReferee) public onlyOwner {
        require(newReferee != address(0));
        referee = newReferee;
    }
    
    modifier whenNotPaused() {
        require(!paused);
        _;
    }
    
    modifier whenPaused() {
        require(paused);
        _;
    }
    
    function pause() onlyOwner whenNotPaused public {
        paused = true;
    }
    
    function unpause() onlyOwner whenPaused public {
        paused = false;
    }
}

contract BCFMain {
    function isOwnerOfAllPlayerCards(uint256[], address) public pure returns (bool) {}
    function implementsERC721() public pure returns (bool) {}
    function getPlayerForCard(uint) 
        external
        pure
        returns (
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        bytes,
        string,
        uint8
    ) {}
}

 
 
 
 
 
 
 
 
contract BCFLeague is BCFBaseCompetition {
    
    struct Team {
        address manager;
        bytes name;
        uint[] cardIds;
        uint gkCardId;
        uint8 wins;
        uint8 losses;
        uint8 draws;
        uint16 goalsFor;
        uint16 goalsAgainst;
    }

    struct Match {
        uint8 homeTeamId;
        uint8 awayTeamId;
        uint[] homeScorerIds;
        uint[] awayScorerIds;
        bool isFinished;
    }

     
    uint public TEAMS_TOTAL;
    uint public ENTRY_FEE;
    uint public SQUAD_SIZE;
    uint public TOTAL_ROUNDS;
    uint public MATCHES_PER_ROUND;
    uint public SECONDS_BETWEEN_ROUNDS;

     
    enum CompetitionStatuses { Upcoming, OpenForEntry, PendingStart, Started, Finished, Settled }
    CompetitionStatuses public competitionStatus;
    uint public startedAt;
    uint public nextRoundStartsAt;
    int public currentRoundId = -1;  

     
    Team[] public teams;
    mapping(address => uint) internal managerToTeamId;
    mapping(uint => bool) internal cardIdToEntryStatus;
    mapping(uint => Match[]) internal roundIdToMatches;

     
    BCFMain public mainContract;

     
    uint public constant PRIZE_POT_PERCENTAGE_MAX = 10000;  
    uint public prizePool;  
    uint[] public prizeBreakdown;  
    address[] public winners;  

    function BCFLeague(address dataStoreAddress, uint teamsTotal, uint entryFee, uint squadSize, uint roundTimeSecs) public {
        require(teamsTotal % 2 == 0);  
        require(teamsTotal > 0);
        require(roundTimeSecs > 30 seconds && roundTimeSecs < 60 minutes);
        require(entryFee >= 0);
        require(squadSize > 0);
        
         
        owner = msg.sender;
        referee = msg.sender;
        
         
        TEAMS_TOTAL = teamsTotal;
        ENTRY_FEE = entryFee;
        SQUAD_SIZE = squadSize;
        TOTAL_ROUNDS = TEAMS_TOTAL - 1;
        MATCHES_PER_ROUND = TEAMS_TOTAL / 2;
        SECONDS_BETWEEN_ROUNDS = roundTimeSecs;

         
        competitionStatus = CompetitionStatuses.Upcoming;

         
        BCFMain candidateDataStoreContract = BCFMain(dataStoreAddress);
        require(candidateDataStoreContract.implementsERC721());
        mainContract = candidateDataStoreContract;
    }

     
     
    function generateFixtures() external onlyOwner {
        require(competitionStatus == CompetitionStatuses.Upcoming);

         
        for (uint round = 0; round < TOTAL_ROUNDS; round++) {
            for (uint matchIndex = 0; matchIndex < MATCHES_PER_ROUND; matchIndex++) {
                uint home = (round + matchIndex) % (TEAMS_TOTAL - 1);
                uint away = (TEAMS_TOTAL - 1 - matchIndex + round) % (TEAMS_TOTAL - 1);

                if (matchIndex == 0) {
                    away = TEAMS_TOTAL - 1;
                }

                 Match memory _match;
                 _match.homeTeamId = uint8(home);
                 _match.awayTeamId = uint8(away);

                roundIdToMatches[round].push(_match);
            }
        }
    }

    function createPrizePool(uint[] prizeStructure) external payable onlyOwner {
        require(competitionStatus == CompetitionStatuses.Upcoming);
        require(msg.value > 0 && msg.value <= 2 ether);  
        require(prizeStructure.length > 0);  

        uint allocationTotal = 0;
        for (uint i = 0; i < prizeStructure.length; i++) {
            allocationTotal += prizeStructure[i];
        }

        require(allocationTotal > 0 && allocationTotal <= PRIZE_POT_PERCENTAGE_MAX);  
        prizePool += msg.value;
        prizeBreakdown = prizeStructure;
    }

    function openCompetition() external onlyOwner whenNotPaused {
        competitionStatus = CompetitionStatuses.OpenForEntry;
    }

    function startCompetition() external onlyReferee whenNotPaused {
        require(competitionStatus == CompetitionStatuses.PendingStart);

         
        competitionStatus = CompetitionStatuses.Started;
        
         
        startedAt = now;
        nextRoundStartsAt = now + 60 seconds;
    }

    function calculateMatchOutcomesForRoundId(int roundId) external onlyReferee whenNotPaused {
        require(competitionStatus == CompetitionStatuses.Started);
        require(nextRoundStartsAt > 0);
        require(roundId == currentRoundId + 1);  
        require(now > nextRoundStartsAt);

         
         
         
        currentRoundId++;

         
         
        if (TOTAL_ROUNDS == uint(currentRoundId + 1)) {
            competitionStatus = CompetitionStatuses.Finished;
        } else {
            nextRoundStartsAt = now + SECONDS_BETWEEN_ROUNDS;
        }

         
        Match[] memory matches = roundIdToMatches[uint(roundId)];
        for (uint i = 0; i < matches.length; i++) {
            Match memory _match = matches[i];
            var (homeScorers, awayScorers) = calculateScorersForTeamIds(_match.homeTeamId, _match.awayTeamId);

             
            updateTeamsTableAttributes(_match.homeTeamId, homeScorers.length, _match.awayTeamId, awayScorers.length);

             
            roundIdToMatches[uint(roundId)][i].isFinished = true;
            roundIdToMatches[uint(roundId)][i].homeScorerIds = homeScorers;
            roundIdToMatches[uint(roundId)][i].awayScorerIds = awayScorers;
        }
    }

    function updateTeamsTableAttributes(uint homeTeamId, uint homeGoals, uint awayTeamId, uint awayGoals) internal {

         
        teams[homeTeamId].goalsFor += uint16(homeGoals);
        teams[awayTeamId].goalsFor += uint16(awayGoals);

         
        teams[homeTeamId].goalsAgainst += uint16(awayGoals);
        teams[awayTeamId].goalsAgainst += uint16(homeGoals);

         
        if (homeGoals == awayGoals) {            
            teams[homeTeamId].draws++;
            teams[awayTeamId].draws++;
        } else if (homeGoals > awayGoals) {
            teams[homeTeamId].wins++;
            teams[awayTeamId].losses++;
        } else {
            teams[awayTeamId].wins++;
            teams[homeTeamId].losses++;
        }
    }

    function getAllMatchesForRoundId(uint roundId) public view returns (uint[], uint[], bool[]) {
        Match[] memory matches = roundIdToMatches[roundId];
        
        uint[] memory _homeTeamIds = new uint[](matches.length);
        uint[] memory _awayTeamIds = new uint[](matches.length);
        bool[] memory matchStates = new bool[](matches.length);

        for (uint i = 0; i < matches.length; i++) {
            _homeTeamIds[i] = matches[i].homeTeamId;
            _awayTeamIds[i] = matches[i].awayTeamId;
            matchStates[i] = matches[i].isFinished;
        }

        return (_homeTeamIds, _awayTeamIds, matchStates);
    }

    function getMatchAtRoundIdAtIndex(uint roundId, uint index) public view returns (uint, uint, uint[], uint[], bool) {
        Match[] memory matches = roundIdToMatches[roundId];
        Match memory _match = matches[index];
        return (_match.homeTeamId, _match.awayTeamId, _match.homeScorerIds, _match.awayScorerIds, _match.isFinished);
    }

    function getPlayerCardIdsForTeam(uint teamId) public view returns (uint[]) {
        Team memory _team = teams[teamId];
        return _team.cardIds;
    }

    function enterLeague(uint[] cardIds, uint gkCardId, bytes teamName) public payable whenNotPaused {
        require(mainContract != address(0));  
        require(competitionStatus == CompetitionStatuses.OpenForEntry);  
        require(cardIds.length == SQUAD_SIZE);  
        require(teamName.length > 3 && teamName.length < 18);  
        require(!hasEntered(msg.sender));  
        require(!hasPreviouslyEnteredCardIds(cardIds));  
        require(mainContract.isOwnerOfAllPlayerCards(cardIds, msg.sender));  
        require(teams.length < TEAMS_TOTAL);  
        require(msg.value >= ENTRY_FEE);  

         
        Team memory _team;
        _team.name = teamName;
        _team.manager = msg.sender;
        _team.cardIds = cardIds;
        _team.gkCardId = gkCardId;
        uint teamId = teams.push(_team) - 1;

         
        managerToTeamId[msg.sender] = teamId;

         
        for (uint i = 0; i < cardIds.length; i++) {
            cardIdToEntryStatus[cardIds[i]] = true;
        }

         
        if (teams.length == TEAMS_TOTAL) {
            competitionStatus = CompetitionStatuses.PendingStart;
        }
    }

    function hasPreviouslyEnteredCardIds(uint[] cardIds) view internal returns (bool) {
        if (teams.length == 0) {
            return false;
        }

         
        for (uint i = 0; i < cardIds.length; i++) {
            uint cardId = cardIds[i];
            bool hasEnteredCardPreviously = cardIdToEntryStatus[cardId];
            if (hasEnteredCardPreviously) {
                return true;
            }
        }

        return false;
    }

    function hasEntered(address manager) view internal returns (bool) {
        if (teams.length == 0) {
            return false;
        }

         
         
         
        uint teamIndex = managerToTeamId[manager];
        Team memory team = teams[teamIndex];
        if (team.manager == manager) {
            return true;
        }

        return false;
    }

    function setMainContract(address _address) external onlyOwner {
        BCFMain candidateContract = BCFMain(_address);
        require(candidateContract.implementsERC721());
        mainContract = candidateContract;
    }

     
    function calculateScorersForTeamIds(uint homeTeamId, uint awayTeamId) internal view returns (uint[], uint[]) {
        
        var (homeTotals, homeCardsShootingAttributes) = calculateAttributeTotals(homeTeamId);
        var (awayTotals, awayCardsShootingAttributes) = calculateAttributeTotals(awayTeamId); 
        
        uint startSeed = now;
        var (homeGoals, awayGoals) = calculateGoalsFromAttributeTotals(homeTeamId, awayTeamId, homeTotals, awayTotals, startSeed);

        uint[] memory homeScorers = new uint[](homeGoals);
        uint[] memory awayScorers = new uint[](awayGoals);

         
        for (uint i = 0; i < homeScorers.length; i++) {
            homeScorers[i] = determineGoalScoringCardIds(teams[homeTeamId].cardIds, homeCardsShootingAttributes, i);
        }

         
        for (i = 0; i < awayScorers.length; i++) {
            awayScorers[i] = determineGoalScoringCardIds(teams[awayTeamId].cardIds, awayCardsShootingAttributes, i);
        }

        return (homeScorers, awayScorers);
    }

    function calculateGoalsFromAttributeTotals(uint homeTeamId, uint awayTeamId, uint[] homeTotals, uint[] awayTotals, uint startSeed) internal view returns (uint _homeGoals, uint _awayGoals) {

        uint[] memory atkAttributes = new uint[](3);  
        uint[] memory defAttributes = new uint[](3);  

        uint attackingTeamId = 0;
        uint defendingTeamId = 0;
        uint outcome = 0;
        uint seed = startSeed * homeTotals[0] * awayTotals[0];

        for (uint i = 0; i < 45; i++) {
            
            attackingTeamId = determineAttackingOrDefendingOutcomeForAttributes(homeTeamId, awayTeamId, homeTotals[0], awayTotals[0], seed+now);
            seed++;

            if (attackingTeamId == homeTeamId) {
                defendingTeamId = awayTeamId;
                atkAttributes[0] = homeTotals[3];  
                atkAttributes[1] = homeTotals[4];  
                atkAttributes[2] = homeTotals[2];  
                defAttributes[0] = awayTotals[1];  
                defAttributes[1] = awayTotals[6];  
                defAttributes[2] = awayTotals[5];  
            } else {
                defendingTeamId = homeTeamId;
                atkAttributes[0] = awayTotals[3];  
                atkAttributes[1] = awayTotals[4];  
                atkAttributes[2] = awayTotals[2];  
                defAttributes[0] = homeTotals[1];  
                defAttributes[1] = homeTotals[6];  
                defAttributes[2] = homeTotals[5];  
            }

            outcome = determineAttackingOrDefendingOutcomeForAttributes(attackingTeamId, defendingTeamId, atkAttributes[0], defAttributes[0], seed);
			if (outcome == defendingTeamId) {
                 
				continue;
			}
            seed++;

            outcome = determineAttackingOrDefendingOutcomeForAttributes(attackingTeamId, defendingTeamId, atkAttributes[1], defAttributes[1], seed);
			if (outcome == defendingTeamId) {
                 
				continue;
			}
            seed++;

            outcome = determineAttackingOrDefendingOutcomeForAttributes(attackingTeamId, defendingTeamId, atkAttributes[2], defAttributes[2], seed);
			if (outcome == defendingTeamId) {
                 
				continue;
			}

             
            if (attackingTeamId == homeTeamId) {
                 
                _homeGoals += 1;
            } else {
                 
                _awayGoals += 1;
            }
        }
    }

    function calculateAttributeTotals(uint teamId) internal view returns (uint[], uint[]) {
        
         
         
         
        uint[] memory totals = new uint[](7);
        uint[] memory cardsShootingAttributes = new uint[](SQUAD_SIZE);
        Team memory _team = teams[teamId];
        
        for (uint i = 0; i < SQUAD_SIZE; i++) {
            var (overall,pace,shooting,passing,dribbling,defending,physical,,,,) = mainContract.getPlayerForCard(_team.cardIds[i]);

             
            if (_team.cardIds[i] == _team.gkCardId && _team.gkCardId > 0) {
                totals[5] += (overall * 5);
                totals[6] += overall;
                cardsShootingAttributes[i] = 1;  
            } else {
                totals[0] += overall;
                totals[1] += pace;
                totals[2] += shooting;
                totals[3] += passing;
                totals[4] += dribbling;
                totals[5] += defending;
                totals[6] += physical;

                cardsShootingAttributes[i] = shooting + dribbling;  
            }
        }

        return (totals, cardsShootingAttributes);
    }

    function determineAttackingOrDefendingOutcomeForAttributes(uint attackingTeamId, uint defendingTeamId, uint atkAttributeTotal, uint defAttributeTotal, uint seed) internal view returns (uint) {
        
        uint max = atkAttributeTotal + defAttributeTotal;
        uint randValue = uint(keccak256(block.blockhash(block.number-1), seed))%max;

        if (randValue <= atkAttributeTotal) {
		    return attackingTeamId;
	    }

	    return defendingTeamId;
    }

    function determineGoalScoringCardIds(uint[] cardIds, uint[] shootingAttributes, uint seed) internal view returns(uint) {

        uint max = 0;
        uint min = 0;
        for (uint i = 0; i < shootingAttributes.length; i++) {
            max += shootingAttributes[i];
        }

        bytes32 randHash = keccak256(seed, now, block.blockhash(block.number - 1));
        uint randValue = uint(randHash) % max + min;

        for (i = 0; i < cardIds.length; i++) {
            uint cardId = cardIds[i];
            randValue -= shootingAttributes[i];

             
            if (randValue <= 0 || randValue >= max) {
                return cardId;
            }
        }

        return cardIds[0];
    }

     
    function calculateWinningEntries() external onlyReferee {
        require(competitionStatus == CompetitionStatuses.Finished);

        address[] memory winningAddresses = new address[](prizeBreakdown.length);
        uint[] memory winningTeamIds = new uint[](prizeBreakdown.length);
        uint[] memory winningTeamPoints = new uint[](prizeBreakdown.length);

         
         
         
         
         
         

         
        bool isReplacementWinner = false;
        for (uint i = 0; i < teams.length; i++) {
            Team memory _team = teams[i];

             
            uint currPoints = (_team.wins * 3) + _team.draws;

             
            for (uint x = 0; x < winningTeamPoints.length; x++) {
                
                 
                isReplacementWinner = false;
                if (currPoints > winningTeamPoints[x]) {
                    isReplacementWinner = true;
                 
                } else if (currPoints == winningTeamPoints[x]) {
                    
                     
                    Team memory _comparisonTeam = teams[winningTeamIds[x]];

                    int gdTeam = _team.goalsFor - _team.goalsAgainst;
                    int gdComparedTeam = _comparisonTeam.goalsFor - _comparisonTeam.goalsAgainst;

                     
                    if (gdTeam > gdComparedTeam) {
                        isReplacementWinner = true;
                    } else if (gdTeam == gdComparedTeam) {

                         
                        if (_team.goalsFor > _comparisonTeam.goalsFor) {
                            isReplacementWinner = true;
                        } else if (_team.goalsFor == _comparisonTeam.goalsFor) {

                             
                            if (_team.wins > _comparisonTeam.wins) {
                                isReplacementWinner = true;
                            } else if (_team.wins == _comparisonTeam.wins) {

                                 
                                if (i < winningTeamIds[x]) {
                                    isReplacementWinner = true;
                                }
                            }
                        }
                    }
                }

                 
                if (isReplacementWinner) {
                    
                     
                    for (uint y = winningAddresses.length - 1; y > x; y--) {
                        winningAddresses[y] = winningAddresses[y-1];
                        winningTeamPoints[y] = winningTeamPoints[y-1];
                        winningTeamIds[y] = winningTeamIds[y-1];
                    }
                    
                     
                    winningAddresses[x] = _team.manager;
                    winningTeamPoints[x] = currPoints;
                    winningTeamIds[x] = i;
                    break;  
                }
            }
        }

         
        winners = winningAddresses;
    }

    function settleLeague() external onlyOwner {
        require(competitionStatus == CompetitionStatuses.Finished);
        require(winners.length > 0);
        require(prizeBreakdown.length == winners.length);
        require(prizePool >= this.balance);

         
        competitionStatus = CompetitionStatuses.Settled;
        
         
        for (uint i = 0; i < winners.length; i++) {
            address winner = winners[i];
            uint percentageCut = prizeBreakdown[i];  

            uint winningAmount = calculateWinnerCut(prizePool, percentageCut);
            winner.transfer(winningAmount);
        }
    }

    function calculateWinnerCut(uint totalPot, uint cut) internal pure returns (uint256) {
         
        uint finalCut = totalPot * cut / PRIZE_POT_PERCENTAGE_MAX;
        return finalCut;
    }  

    function withdrawBalance() external onlyOwner {
        owner.transfer(this.balance);
    }

     
    function hasStarted() external view returns (bool) {
        if (competitionStatus == CompetitionStatuses.Upcoming || competitionStatus == CompetitionStatuses.OpenForEntry || competitionStatus == CompetitionStatuses.PendingStart) {
            return false;
        }

        return true;
    }

    function winningTeamId() external view returns (uint) {
        require(competitionStatus == CompetitionStatuses.Finished || competitionStatus == CompetitionStatuses.Settled);

        uint winningTeamId = 0;
        for (uint i = 0; i < teams.length; i++) {
            if (teams[i].manager == winners[0]) {
                winningTeamId = i;
                break;
            }
        }

        return winningTeamId;
    }
}