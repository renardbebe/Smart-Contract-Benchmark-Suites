 

pragma solidity 0.4.18;

 

contract KnowsConstants {
     
    uint public constant GAME_START_TIME = 1517787000;
}

 

 
contract KnowsSquares {
    modifier isValidSquare(uint home, uint away) {
        require(home >= 0 && home < 10);
        require(away >= 0 && away < 10);
        _;
    }
}

 

interface IKnowsTime {
    function currentTime() public view returns (uint);
}

 

 
contract KnowsTime is IKnowsTime {
    function currentTime() public view returns (uint) {
        return now;
    }
}

 

interface IScoreOracle {
    function getSquareWins(uint home, uint away) public view returns (uint numSquareWins, uint totalWins);
    function isFinalized() public view returns (bool);
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


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 

contract OwnedScoreOracle is KnowsConstants, KnowsSquares, KnowsTime, Ownable, IScoreOracle {
    using SafeMath for uint;

     
    uint public constant SCORE_REPORT_START_TIME = GAME_START_TIME + 1 days;

     
    uint public constant TOTAL_WINS = 4;

     
    uint public winsReported = 0;

     
    uint[10][10] public squareWins;

     
    bool public finalized;

    event LogSquareWinsUpdated(uint home, uint away, uint wins);

    function setSquareWins(uint home, uint away, uint wins) public onlyOwner isValidSquare(home, away) {
        require(currentTime() >= SCORE_REPORT_START_TIME);
        require(wins <= TOTAL_WINS);
        require(!finalized);

        uint currentSquareWins = squareWins[home][away];

         
        if (currentSquareWins > wins) {
            winsReported = winsReported.sub(currentSquareWins.sub(wins));
        } else if (currentSquareWins < wins) {
            winsReported = winsReported.add(wins.sub(currentSquareWins));
        }

         
        squareWins[home][away] = wins;

        LogSquareWinsUpdated(home, away, wins);
    }

    event LogFinalized(uint time);

     
    function finalize() public onlyOwner {
        require(winsReported == TOTAL_WINS);
        require(!finalized);

        finalized = true;

        LogFinalized(currentTime());
    }

    function getSquareWins(uint home, uint away) public view returns (uint numSquareWins, uint totalWins) {
        return (squareWins[home][away], TOTAL_WINS);
    }

    function isFinalized() public view returns (bool) {
        return finalized;
    }
}

 

interface IKnowsVoterStakes {
    function getVoterStakes(address voter, uint asOfBlock) public view returns (uint);
}

 

contract AcceptedScoreOracle is OwnedScoreOracle {
    using SafeMath for uint;

     
    uint public constant VOTING_PERIOD_DURATION = 1 weeks;

     
    uint public votingPeriodStartTime;
     
    uint public votingPeriodBlockNumber;

     
    bool public accepted;

    uint public affirmations;
    uint public totalVotes;

    struct Vote {
        bool affirmed;
        bool counted;
    }

     
    mapping(uint => mapping(address => Vote)) votes;

    IKnowsVoterStakes public voterStakes;

     
    function setVoterStakesContract(IKnowsVoterStakes _voterStakes) public onlyOwner {
        require(address(voterStakes) == address(0));
        voterStakes = _voterStakes;
    }

     
    function finalize() public onlyOwner {
        super.finalize();

         
        affirmations = 0;
        totalVotes = 0;
        votingPeriodStartTime = currentTime();
        votingPeriodBlockNumber = block.number;
    }

    event LogAccepted(uint time);

     
    function accept() public {
         
        require(finalized);

         
        require(currentTime() >= votingPeriodStartTime + VOTING_PERIOD_DURATION);

         
        require(!accepted);

         
        require(affirmations.mul(100000).div(totalVotes) >= 66666);

         
        accepted = true;

        LogAccepted(currentTime());
    }

    event LogUnfinalized(uint time);

     
    function unfinalize() public {
         
        require(finalized);

         
        require(!accepted);

         
        require(currentTime() >= votingPeriodStartTime + VOTING_PERIOD_DURATION);

         
        require(affirmations.mul(10000).div(totalVotes) < 6666);

         
        finalized = false;

        LogUnfinalized(currentTime());
    }

    event LogVote(address indexed voter, bool indexed affirm, uint stake);

     
    function vote(bool affirm) public {
         
        require(votingPeriodStartTime != 0);

         
        require(finalized);

         
        require(!accepted);

        uint stake = voterStakes.getVoterStakes(msg.sender, votingPeriodBlockNumber);

         
        require(stake > 0);

        Vote storage userVote = votes[votingPeriodBlockNumber][msg.sender];

         
        if (!userVote.counted) {
            userVote.counted = true;
            userVote.affirmed = affirm;

            totalVotes = totalVotes.add(stake);
            if (affirm) {
                affirmations = affirmations.add(stake);
            }
        } else {
             
            if (affirm && !userVote.affirmed) {
                affirmations = affirmations.add(stake);
            } else if (!affirm && userVote.affirmed) {
                 
                affirmations = affirmations.sub(stake);
            }
            userVote.affirmed = affirm;
        }

        LogVote(msg.sender, affirm, stake);
    }

    function isFinalized() public view returns (bool) {
        return super.isFinalized() && accepted;
    }
}