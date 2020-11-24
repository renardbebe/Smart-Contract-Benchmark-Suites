 

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

 

interface IKnowsVoterStakes {
    function getVoterStakes(address voter, uint asOfBlock) public view returns (uint);
}

 

interface IScoreOracle {
    function getSquareWins(uint home, uint away) public view returns (uint numSquareWins, uint totalWins);
    function isFinalized() public view returns (bool);
}

 

 

library Math {
  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
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

 

contract Squares is KnowsConstants, KnowsTime, KnowsSquares, IKnowsVoterStakes {
    using SafeMath for uint;

    function Squares(IScoreOracle _oracle, address _developer) public {
        oracle = _oracle;
        developer = _developer;
    }

     
    IScoreOracle public oracle;

     
    address public developer;

     
    mapping(address => uint[10][10]) public totalSquareStakesByUser;

     
    uint[10][10] public totalSquareStakes;

     
    mapping(address => uint) public totalUserStakes;

     
    uint public totalStakes;

    event LogBet(address indexed better, uint indexed home, uint indexed away, uint stake);

    function bet(uint home, uint away) public payable isValidSquare(home, away) {
        require(msg.value > 0);
        require(currentTime() < GAME_START_TIME);

         
        uint stake = msg.value;

         
        totalStakes = totalStakes.add(stake);

         
        totalUserStakes[msg.sender] = totalUserStakes[msg.sender].add(stake);

         
        totalSquareStakesByUser[msg.sender][home][away] = totalSquareStakesByUser[msg.sender][home][away].add(stake);

         
        totalSquareStakes[home][away] = totalSquareStakes[home][away].add(stake);

        LogBet(msg.sender, home, away, stake);
    }

    event LogPayout(address indexed winner, uint payout, uint donation);

     
    function getWinnings(address user, uint home, uint away) public view returns (uint winnings) {
         
         
        var (numSquareWins, totalWins) = oracle.getSquareWins(home, away);

        return totalSquareStakesByUser[user][home][away]
            .mul(totalStakes)
            .mul(numSquareWins)
            .div(totalWins)
            .div(totalSquareStakes[home][away]);
    }

     
    function collectWinnings(uint home, uint away, uint donationPercentage) public isValidSquare(home, away) {
         
        require(oracle.isFinalized());

         
        require(donationPercentage <= 100);

         
         
         
         
        uint winnings = Math.min256(this.balance, getWinnings(msg.sender, home, away));

        require(winnings > 0);

         
        uint donation = winnings.mul(donationPercentage).div(100);

        uint payout = winnings.sub(donation);

         
        totalSquareStakesByUser[msg.sender][home][away] = 0;

        msg.sender.transfer(payout);
        developer.transfer(donation);

        LogPayout(msg.sender, payout, donation);
    }

    function getVoterStakes(address voter, uint asOfBlock) public view returns (uint) {
        return totalUserStakes[voter];
    }
}