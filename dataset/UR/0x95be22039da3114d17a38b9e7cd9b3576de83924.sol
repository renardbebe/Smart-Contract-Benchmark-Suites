 

pragma solidity ^0.4.19;

 
contract Ownable {
    
  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
contract Pausable is Ownable {
    
  event Pause();
  event Unpause();

  bool public paused = false;

   
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
  
}


 
contract ReentrancyGuard {

   
  bool private reentrancy_lock = false;

   
  modifier nonReentrant() {
    require(!reentrancy_lock);
    reentrancy_lock = true;
    _;
    reentrancy_lock = false;
  }

}


 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
  }
  
}


 
contract EDCoreInterface {

     
    function getGameSettings() external view returns (
        uint _recruitHeroFee,
        uint _transportationFeeMultiplier,
        uint _noviceDungeonId,
        uint _consolationRewardsRequiredFaith,
        uint _challengeFeeMultiplier,
        uint _dungeonPreparationTime,
        uint _trainingFeeMultiplier,
        uint _equipmentTrainingFeeMultiplier,
        uint _preparationPeriodTrainingFeeMultiplier,
        uint _preparationPeriodEquipmentTrainingFeeMultiplier
    );
    
     
    function getPlayerDetails(address _address) external view returns (
        uint dungeonId, 
        uint payment, 
        uint dungeonCount, 
        uint heroCount, 
        uint faith,
        bool firstHeroRecruited
    );
    
     
    function getDungeonDetails(uint _id) external view returns (
        uint creationTime, 
        uint status, 
        uint difficulty, 
        uint capacity, 
        address owner, 
        bool isReady, 
        uint playerCount
    );
    
     
    function getDungeonFloorDetails(uint _id) external view returns (
        uint floorNumber, 
        uint floorCreationTime, 
        uint rewards, 
        uint seedGenes, 
        uint floorGenes
    );

     
    function getHeroDetails(uint _id) external view returns (
        uint creationTime, 
        uint cooldownStartTime, 
        uint cooldownIndex, 
        uint genes, 
        address owner, 
        bool isReady, 
        uint cooldownRemainingTime
    );

     
    function getHeroAttributes(uint _genes) public pure returns (uint[]);
    
     
    function getHeroPower(uint _genes, uint _dungeonDifficulty) public pure returns (
        uint totalPower, 
        uint equipmentPower, 
        uint statsPower, 
        bool isSuper, 
        uint superRank,
        uint superBoost
    );
    
     
    function getDungeonPower(uint _genes) public pure returns (uint);
    
     
    function calculateTop5HeroesPower(address _address, uint _dungeonId) public view returns (uint);
    
}


 
contract EDColiseumAlpha is Pausable, ReentrancyGuard, Destructible {
    
    struct Participant {
        address player;
        uint heroId;
        uint heroPower;
    }
    
     
    EDCoreInterface public edCoreContract = EDCoreInterface(0xf7eD56c1AC4d038e367a987258b86FC883b960a1);
    
     
    uint _seed;
    
    
     

     
    uint public jackpotWinCount = 3;
    
     
    uint public jackpotWinPercent = 50;
    
     
    uint public winPercent = 55;
    
     
    uint public losePercent = 35;
    
     
    uint public dungeonDifficulty = 1;

     
    uint public participationFee = 0.02 ether;
    
     
    uint public constant maxParticipantCount = 8;
    
    
     
    
     
    uint public nextTournamentRound = 1;

     
    uint public tournamentRewards;

     
    uint public tournamentJackpot = 0.2 ether;
    
     
    Participant[] public participants;
    
     
    Participant[] public previousParticipants;
    
     
    uint[maxParticipantCount / 2] public firstRoundWinners;
    uint[maxParticipantCount / 4] public secondRoundWinners;
    uint[maxParticipantCount / 2] public firstRoundLosers;
    uint[maxParticipantCount / 4] public secondRoundLosers;
    uint public finalWinner;
    uint public finalLoser;
    
     
    mapping(uint => uint) public heroIdToLastRound;
    
     
    mapping(address => uint) public playerToWinCounts;

    
     
    
     
    event TournamentFinished(uint timestamp, uint tournamentRound, address finalWinner, address finalLoser, uint winnerRewards, uint loserRewards, uint winCount, uint jackpotRewards);
    
     
    function EDColiseum() public payable {}

    
     
    
     
    function getGameSettings() external view returns (
        uint _jackpotWinCount,
        uint _jackpotWinPercent,
        uint _winPercent,
        uint _losePercent,
        uint _dungeonDifficulty,
        uint _participationFee,
        uint _maxParticipantCount
    ) {
        _jackpotWinCount = jackpotWinCount;
        _jackpotWinPercent = jackpotWinPercent;
        _winPercent = winPercent;
        _losePercent = losePercent;
        _dungeonDifficulty = dungeonDifficulty;
        _participationFee = participationFee;
        _maxParticipantCount = maxParticipantCount;
    }
    
     
    function getNextTournamentData() external view returns (
        uint _nextTournamentRound,
        uint _tournamentRewards,
        uint _tournamentJackpot,
        uint _participantCount
    ) {
        _nextTournamentRound = nextTournamentRound;
        _tournamentRewards = tournamentRewards;
        _tournamentJackpot = tournamentJackpot;
        _participantCount = participants.length;
    }
    
     
    function joinTournament(uint _heroId) whenNotPaused nonReentrant external payable {
        uint genes;
        address owner;
        (,,, genes, owner,,) = edCoreContract.getHeroDetails(_heroId);
        
         
        require(msg.sender == owner);
        
         
        require(heroIdToLastRound[_heroId] != nextTournamentRound);
        
         
        require(participants.length < maxParticipantCount);
        
         
        require(msg.value >= participationFee);
        tournamentRewards += participationFee;

        if (msg.value > participationFee) {
            msg.sender.transfer(msg.value - participationFee);
        }
        
         
        heroIdToLastRound[_heroId] = nextTournamentRound;
        
         
        uint heroPower;
        (heroPower,,,,) = edCoreContract.getHeroPower(genes, dungeonDifficulty);
        
         
        require(heroPower > 12);
        
         
        participants.push(Participant(msg.sender, _heroId, heroPower));
    }
    
     
    function startTournament() onlyOwner nonReentrant external {
         
        require(participants.length == maxParticipantCount);
        
         
        _firstRoundFight();
        _secondRoundWinnersFight();
        _secondRoundLosersFight();
        _finalRoundWinnersFight();
        _finalRoundLosersFight();
        
         
        uint winnerRewards = tournamentRewards * winPercent / 100;
        uint loserRewards = tournamentRewards * losePercent / 100;
        uint addToJackpot = tournamentRewards - winnerRewards - loserRewards;
        
        address winner = participants[finalWinner].player;
        address loser = participants[finalLoser].player;
        winner.transfer(winnerRewards);
        loser.transfer(loserRewards);
        tournamentJackpot += addToJackpot;
        
         
        playerToWinCounts[winner]++;
        
         
        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i].player;
            
            if (participant != winner && playerToWinCounts[participant] != 0) {
                playerToWinCounts[participant] = 0;
            }
        }
        
         
        uint jackpotRewards;
        uint winCount = playerToWinCounts[winner];
        if (winCount == jackpotWinCount) {
             
            playerToWinCounts[winner] = 0;
            
            jackpotRewards = tournamentJackpot * jackpotWinPercent / 100;
            tournamentJackpot -= jackpotRewards;
            
            winner.transfer(jackpotRewards);
        }
        
         
        tournamentRewards = 0;
        previousParticipants = participants;
        participants.length = 0;
        nextTournamentRound++;
        
         
        TournamentFinished(now, nextTournamentRound - 1, winner, loser, winnerRewards, loserRewards, winCount, jackpotRewards);
    }
    
     
    function cancelTournament() onlyOwner nonReentrant external {
        for (uint i = 0; i < participants.length; i++) {
            address participant = participants[i].player;
            
            if (participant != 0x0) {
                participant.transfer(participationFee);
            }
        }
        
         
        tournamentRewards = 0;
        participants.length = 0;
        nextTournamentRound++;
    }
    
     
    function withdrawBalance() onlyOwner external {
         
        require(participants.length == 0);
        
        msg.sender.transfer(this.balance);
    }

     
    
    function setEdCoreContract(address _newEdCoreContract) onlyOwner external {
        edCoreContract = EDCoreInterface(_newEdCoreContract);
    }
    
    function setJackpotWinCount(uint _newJackpotWinCount) onlyOwner external {
        jackpotWinCount = _newJackpotWinCount;
    }
    
    function setJackpotWinPercent(uint _newJackpotWinPercent) onlyOwner external {
        jackpotWinPercent = _newJackpotWinPercent;
    }
    
    function setWinPercent(uint _newWinPercent) onlyOwner external {
        winPercent = _newWinPercent;
    }
    
    function setLosePercent(uint _newLosePercent) onlyOwner external {
        losePercent = _newLosePercent;
    }
    
    function setDungeonDifficulty(uint _newDungeonDifficulty) onlyOwner external {
        dungeonDifficulty = _newDungeonDifficulty;
    }
    
    function setParticipationFee(uint _newParticipationFee) onlyOwner external {
        participationFee = _newParticipationFee;
    }
    
     
    
     
    function _firstRoundFight() private {
         
        uint heroPower0 = participants[0].heroPower;
        uint heroPower1 = participants[1].heroPower;
        uint heroPower2 = participants[2].heroPower;
        uint heroPower3 = participants[3].heroPower;
        uint heroPower4 = participants[4].heroPower;
        uint heroPower5 = participants[5].heroPower;
        uint heroPower6 = participants[6].heroPower;
        uint heroPower7 = participants[7].heroPower;
        
         
        uint rand;
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            firstRoundWinners[0] = 0;
            firstRoundLosers[0] = 1;
        } else {
            firstRoundWinners[0] = 1;
            firstRoundLosers[0] = 0;
        }
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower2 > heroPower3 && rand < 60) || 
            (heroPower2 == heroPower3 && rand < 50) ||
            (heroPower2 < heroPower3 && rand < 40)
        ) {
            firstRoundWinners[1] = 2;
            firstRoundLosers[1] = 3;
        } else {
            firstRoundWinners[1] = 3;
            firstRoundLosers[1] = 2;
        }
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower4 > heroPower5 && rand < 60) || 
            (heroPower4 == heroPower5 && rand < 50) ||
            (heroPower4 < heroPower5 && rand < 40)
        ) {
            firstRoundWinners[2] = 4;
            firstRoundLosers[2] = 5;
        } else {
            firstRoundWinners[2] = 5;
            firstRoundLosers[2] = 4;
        }
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower6 > heroPower7 && rand < 60) || 
            (heroPower6 == heroPower7 && rand < 50) ||
            (heroPower6 < heroPower7 && rand < 40)
        ) {
            firstRoundWinners[3] = 6;
            firstRoundLosers[3] = 7;
        } else {
            firstRoundWinners[3] = 7;
            firstRoundLosers[3] = 6;
        }
    }
    
     
    function _secondRoundWinnersFight() private {
         
        uint winner0 = firstRoundWinners[0];
        uint winner1 = firstRoundWinners[1];
        uint winner2 = firstRoundWinners[2];
        uint winner3 = firstRoundWinners[3];
        uint heroPower0 = participants[winner0].heroPower;
        uint heroPower1 = participants[winner1].heroPower;
        uint heroPower2 = participants[winner2].heroPower;
        uint heroPower3 = participants[winner3].heroPower;
        
         
        uint rand;
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            secondRoundWinners[0] = winner0;
        } else {
            secondRoundWinners[0] = winner1;
        }
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower2 > heroPower3 && rand < 60) || 
            (heroPower2 == heroPower3 && rand < 50) ||
            (heroPower2 < heroPower3 && rand < 40)
        ) {
            secondRoundWinners[1] = winner2;
        } else {
            secondRoundWinners[1] = winner3;
        }
    }
    
     
    function _secondRoundLosersFight() private {
         
        uint loser0 = firstRoundLosers[0];
        uint loser1 = firstRoundLosers[1];
        uint loser2 = firstRoundLosers[2];
        uint loser3 = firstRoundLosers[3];
        uint heroPower0 = participants[loser0].heroPower;
        uint heroPower1 = participants[loser1].heroPower;
        uint heroPower2 = participants[loser2].heroPower;
        uint heroPower3 = participants[loser3].heroPower;
        
         
        uint rand;
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            secondRoundLosers[0] = loser1;
        } else {
            secondRoundLosers[0] = loser0;
        }
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower2 > heroPower3 && rand < 60) || 
            (heroPower2 == heroPower3 && rand < 50) ||
            (heroPower2 < heroPower3 && rand < 40)
        ) {
            secondRoundLosers[1] = loser3;
        } else {
            secondRoundLosers[1] = loser2;
        }
    }
    
     
    function _finalRoundWinnersFight() private {
         
        uint winner0 = secondRoundWinners[0];
        uint winner1 = secondRoundWinners[1];
        uint heroPower0 = participants[winner0].heroPower;
        uint heroPower1 = participants[winner1].heroPower;
        
         
        uint rand;
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            finalWinner = winner0;
        } else {
            finalWinner = winner1;
        }
    }
    
     
    function _finalRoundLosersFight() private {
         
        uint loser0 = secondRoundLosers[0];
        uint loser1 = secondRoundLosers[1];
        uint heroPower0 = participants[loser0].heroPower;
        uint heroPower1 = participants[loser1].heroPower;
        
         
        uint rand;
        
         
        rand = _getRandomNumber(100);
        if (
            (heroPower0 > heroPower1 && rand < 60) || 
            (heroPower0 == heroPower1 && rand < 50) ||
            (heroPower0 < heroPower1 && rand < 40)
        ) {
            finalLoser = loser1;
        } else {
            finalLoser = loser0;
        }
    }
    
     
    function _getRandomNumber(uint _upper) private returns (uint) {
        _seed = uint(keccak256(
            _seed,
            block.blockhash(block.number - 1),
            block.coinbase,
            block.difficulty
        ));
        
        return _seed % _upper;
    }

}