 

pragma solidity ^0.5.0;

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract EthMadness is Ownable {
    
     
    struct Entrant {
         
        address submitter;
        
         
        uint48 entryIndex;
    }
    
     
    struct TopScore {
         
        uint48 entryIndex;

         
        uint32 score;

         
        uint64 difference;

         
        address submitter;
    }
    
     
    struct Result {
         
        bytes16 winners;

         
        uint8 scoreA;

         
        uint8 scoreB;

         
        bool isFinal;
    }
    
     
    enum ContestState {
         
        OPEN_FOR_ENTRIES,
        
         
        TOURNAMENT_IN_PROGRESS,
        
         
        WAITING_FOR_ORACLES,
        
         
        WAITING_FOR_WINNING_CLAIMS,
        
         
        COMPLETED
    }
    
     
    uint constant MAX_ENTRIES = 2**48;
    
     
    uint48 entryCount = 0;
    
     
    mapping (uint256 => Entrant) public entries;
    
     
    mapping (uint => uint) public transitionTimes;
    
     
    ContestState public currentState;
    
     
    mapping (address => Result) public oracleVotes;
    
     
    address[] public oracles;
    
     
    uint constant MAX_ORACLES = 10;
    
     
    Result public finalResult;
    
     
    TopScore[3] public topThree;
    
     
    address public prizeERC20TokenAddress;
    
     
    uint public prizeAmount;
    
     
    event EntrySubmitted(
         
        address indexed submitter,

         
        uint256 indexed entryCompressed,

         
        uint48 indexed entryIndex,

         
        string bracketName
    );

     
    constructor(uint[] memory times, address erc20Token, uint erc20Amount) public {
        
         
        oracles = [msg.sender];
        
         
        prizeERC20TokenAddress = erc20Token;
        prizeAmount = erc20Amount;
        
         
        require(times.length == 4);
        transitionTimes[uint(ContestState.TOURNAMENT_IN_PROGRESS)] = times[0];
        transitionTimes[uint(ContestState.WAITING_FOR_ORACLES)] = times[1];
        transitionTimes[uint(ContestState.WAITING_FOR_WINNING_CLAIMS)] = times[2];
        transitionTimes[uint(ContestState.COMPLETED)] = times[3];
        
         
        currentState = ContestState.OPEN_FOR_ENTRIES;
    }

     
    function getEntryCount() public view returns (uint256) {
        return entryCount;
    }
    
     
    function getOracleCount() public view returns(uint256) {
        return oracles.length;
    }
    
     
    function getTransitionTimes() public view returns (uint256, uint256, uint256, uint256) {
        return (
            transitionTimes[uint(ContestState.TOURNAMENT_IN_PROGRESS)],
            transitionTimes[uint(ContestState.WAITING_FOR_ORACLES)],
            transitionTimes[uint(ContestState.WAITING_FOR_WINNING_CLAIMS)],
            transitionTimes[uint(ContestState.COMPLETED)]
        );
    }
    
     
    function advanceState(ContestState nextState) private {
        require(uint(nextState) == uint(currentState) + 1, "Can only advance state by 1");
        require(now > transitionTimes[uint(nextState)], "Transition time hasn't happened yet");
        
        currentState = nextState;
    }

     
    function arePicksOrResultsValid(bytes16 picksOrResults) public pure returns (bool) {
         
        for (uint8 gameId = 0; gameId < 63; gameId++) {
            uint128 currentPick = extractResult(picksOrResults, gameId);
            if (currentPick != 2 && currentPick != 1) {
                return false;
            }
        }

        return true;
    }
    
     
    function submitEntry(bytes16 picks, uint64 scoreA, uint64 scoreB, string memory bracketName) public {
        require(currentState == ContestState.OPEN_FOR_ENTRIES, "Must be in the open for entries state");
        require(arePicksOrResultsValid(picks), "The supplied picks are not valid");

         
        uint256 scoreAShifted = uint256(scoreA) * (2 ** (24 * 8));
        uint256 scoreBShifted = uint256(scoreB) * (2 ** (16 * 8));
        uint256 picksAsNumber = uint128(picks);
        uint256 entryCompressed = scoreAShifted | scoreBShifted | picksAsNumber;

        require(entries[entryCompressed].submitter == address(0), "This exact bracket & score has already been submitted");
        
         
        emit EntrySubmitted(msg.sender, entryCompressed, entryCount, bracketName);
        Entrant memory entrant = Entrant(msg.sender, entryCount);
        entries[entryCompressed] = entrant;
        entryCount++;
    }

     
     
    function addOracle(address oracle) public onlyOwner {
        require(currentState == ContestState.OPEN_FOR_ENTRIES, "Must be accepting entries");
        require(oracles.length < MAX_ORACLES - 1, "Must be less than max number of oracles");
        oracles.push(oracle);
    }

     
     
    function refundRemaining(uint256 amount) public onlyOwner {
        require(currentState == ContestState.OPEN_FOR_ENTRIES || currentState == ContestState.COMPLETED, "Must be accepting entries");
        
        IERC20 erc20 = IERC20(prizeERC20TokenAddress);
        erc20.transfer(msg.sender, amount);
    }
    
     
    function submitOracleVote(uint oracleIndex, bytes16 winners, uint8 scoreA, uint8 scoreB) public {
        require(currentState == ContestState.WAITING_FOR_ORACLES, "Must be in waiting for oracles state");
        require(oracles[oracleIndex] == msg.sender, "Wrong oracle index");
        require(arePicksOrResultsValid(winners), "Results are not valid");
        oracleVotes[msg.sender] = Result(winners, scoreA, scoreB, true);
    }
    
     
     
    function closeOracleVoting(bytes16 winners, uint8 scoreA, uint8 scoreB) public {
        require(currentState == ContestState.WAITING_FOR_ORACLES);

         
        uint confirmingOracles = 0;
        for (uint i = 0; i < oracles.length; i++) {
            Result memory oracleVote = oracleVotes[oracles[i]];
            if (oracleVote.isFinal &&
                oracleVote.winners == winners &&
                oracleVote.scoreA == scoreA &&
                oracleVote.scoreB == scoreB) {

                confirmingOracles++;
            }
        }
        
         
        uint percentAggreement = (confirmingOracles * 100) / oracles.length;
        require(percentAggreement > 70, "To close oracle voting, > 70% of oracles must agree");
        
         
        advanceState(ContestState.WAITING_FOR_WINNING_CLAIMS);
        finalResult = Result(winners, scoreA, scoreB, true);
    }
    
     
    function markTournamentInProgress() public {
        advanceState(ContestState.TOURNAMENT_IN_PROGRESS);
        
        require(oracles.length > 0, "Must have at least 1 oracle registered");
        
         
        IERC20 erc20 = IERC20(prizeERC20TokenAddress);
        require(erc20.balanceOf(address(this)) >= prizeAmount, "Must have a balance in this contract");
    }
    
     
    function markTournamentFinished() public {
        advanceState(ContestState.WAITING_FOR_ORACLES);
    }
    
     
     
    function closeContestAndPayWinners() public {
        advanceState(ContestState.COMPLETED);
        require(topThree[0].submitter != address(0), "Not enough claims");
        require(topThree[1].submitter != address(0), "Not enough claims");
        require(topThree[2].submitter != address(0), "Not enough claims");
        
        uint firstPrize = (prizeAmount * 70) / 100;
        uint secondPrize = (prizeAmount * 20) / 100;
        uint thirdPrize = (prizeAmount * 10) / 100;
        IERC20 erc20 = IERC20(prizeERC20TokenAddress);
        erc20.transfer(topThree[0].submitter, firstPrize);
        erc20.transfer(topThree[1].submitter, secondPrize);
        erc20.transfer(topThree[2].submitter, thirdPrize);
    }
    
     
    function scoreAndSortEntry(uint256 entryCompressed, bytes16 results, uint64 scoreAActual, uint64 scoreBActual) private returns (uint32) {
        require(currentState == ContestState.WAITING_FOR_WINNING_CLAIMS, "Must be in the waiting for claims state");
        require(entries[entryCompressed].submitter != address(0), "The entry must have actually been submitted");

         
        bytes16 picks = bytes16(uint128((entryCompressed & uint256((2 ** 128) - 1))));
        uint256 shifted = entryCompressed / (2 ** 128);  
        uint64 scoreA = uint64((shifted & uint256((2 ** 64) - 1)));
        shifted = entryCompressed / (2 ** 192);
        uint64 scoreB = uint64((shifted & uint256((2 ** 64) - 1)));

         
        uint32 score = scoreEntry(picks, results);
        uint64 difference = computeFinalGameDifference(scoreA, scoreB, scoreAActual, scoreBActual);

         
        TopScore memory scoreResult = TopScore(entries[entryCompressed].entryIndex, score, difference, entries[entryCompressed].submitter);
        if (isScoreBetter(scoreResult, topThree[0])) {
            topThree[2] = topThree[1];
            topThree[1] = topThree[0];
            topThree[0] = scoreResult;
        } else if (isScoreBetter(scoreResult, topThree[1])) {
            topThree[2] = topThree[1];
            topThree[1] = scoreResult;
        } else if (isScoreBetter(scoreResult, topThree[2])) {
            topThree[2] = scoreResult;
        }
        
        return score;
    }
    
    function claimTopEntry(uint256 entryCompressed) public {
        require(currentState == ContestState.WAITING_FOR_WINNING_CLAIMS, "Must be in the waiting for winners state");
        require(finalResult.isFinal, "The final result must be marked as final");
        scoreAndSortEntry(entryCompressed, finalResult.winners, finalResult.scoreA, finalResult.scoreB);
    }
    
    function computeFinalGameDifference(
        uint64 scoreAGuess, uint64 scoreBGuess, uint64 scoreAActual, uint64 scoreBActual) private pure returns (uint64) {
        
         
        uint64 difference = 0;
        difference += ((scoreAActual > scoreAGuess) ? (scoreAActual - scoreAGuess) : (scoreAGuess - scoreAActual));
        difference += ((scoreBActual > scoreBGuess) ? (scoreBActual - scoreBGuess) : (scoreBGuess - scoreBActual));
        return difference;
    }
    
     
    function getBit16(bytes16 a, uint16 n) private pure returns (bool) {
        uint128 mask = uint128(2) ** n;
        return uint128(a) & mask != 0;
    }
    
     
    function setBit16(bytes16 a, uint16 n) private pure returns (bytes16) {
        uint128 mask = uint128(2) ** n;
        return a | bytes16(mask);
    }
    
     
    function clearBit16(bytes16 a, uint16 n) private pure returns (bytes16) {
        uint128 mask = uint128(2) ** n;
        mask = mask ^ uint128(-1);
        return a & bytes16(mask);
    }
    
     
    function extractResult(bytes16 a, uint8 n) private pure returns (uint128) {
        uint128 mask = uint128(0x00000000000000000000000000000003) * uint128(2) ** (n * 2);
        uint128 masked = uint128(a) & mask;
        
         
        return (masked / (uint128(2) ** (n * 2)));
    }
    
     
    function getRoundForGame(uint8 gameId) private pure returns (uint8) {
        if (gameId < 32) {
            return 0;
        } else if (gameId < 48) {
            return 1;
        } else if (gameId < 56) {
            return 2;
        } else if (gameId < 60) {
            return 3;
        } else if (gameId < 62) {
            return 4;
        } else {
            return 5;
        }
    }
    
     
    function getFirstGameIdOfRound(uint8 round) private pure returns (uint8) {
        if (round == 0) {
            return 0;
        } else if (round == 1) {
            return 32;
        } else if (round == 2) {
            return 48;
        } else if (round == 3) {
            return 56;
        } else if (round == 4) {
            return 60;
        } else {
            return 62;
        }
    }
    
     
    function isScoreBetter(TopScore memory newScore, TopScore memory oldScore) private pure returns (bool) {
        if (newScore.score > oldScore.score) {
            return true;
        }
        
        if (newScore.score < oldScore.score) {
            return false;
        }
        
         
        if (newScore.difference < oldScore.difference) {
            return true;
        }
        
        if (newScore.difference < oldScore.difference) {
            return false;
        }

        require(newScore.entryIndex != oldScore.entryIndex, "This entry has already claimed a prize");
        
         
        return newScore.entryIndex < oldScore.entryIndex;
    }
    
     
    function scoreEntry(bytes16 picks, bytes16 results) private pure returns (uint32) {
        uint32 score = 0;
        uint8 round = 0;
        bytes16 currentPicks = picks;
        for (uint8 gameId = 0; gameId < 63; gameId++) {
            
             
            round = getRoundForGame(gameId);
            
            uint128 currentPick = extractResult(currentPicks, gameId);
            if (currentPick == extractResult(results, gameId)) {
                score += (uint32(2) ** round);
            } else if (currentPick != 0) {  
                 
                uint16 currentPickId = (gameId * 2) + (currentPick == 2 ? 1 : 0);
                for (uint8 futureRound = round + 1; futureRound < 6; futureRound++) {
                    uint16 currentPickOffset = currentPickId - (getFirstGameIdOfRound(futureRound - 1) * 2);
                    currentPickId = (getFirstGameIdOfRound(futureRound) * 2) + (currentPickOffset / 2);
                    
                    bool pickedLoser = getBit16(currentPicks, currentPickId);
                    if (pickedLoser) {
                        currentPicks = clearBit16(currentPicks, currentPickId);
                    } else {
                        break;
                    }
                }
            }
        }
        
        return score;
    }
}