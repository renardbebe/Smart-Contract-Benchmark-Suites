 

pragma solidity ^0.4.18;

 
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

 
 
 
 

contract BallotSB52 {
  using SafeMath for uint;
  uint public phiWon;
  uint public neWon;
  Superbowl52 bettingContract;
  mapping (address => bool) voted;
  mapping (address => uint) votes;
  uint public constant votingPeriod = 7 days;
  uint public votingStart;
  uint public votingEnd;
  uint public validResult;
  bool public closed;
  uint public totalVoters;
   
  uint public threshold;
  uint public votingReward;
  mapping (address => uint) stake;
  uint public majorityReward;
  bool public tie;
  mapping (address => bool) claimed;

  function BallotSB52(uint th) public payable {
    validResult = 0;
    closed = false;
    votingStart = now;
    votingEnd = now + 7 days;
    bettingContract = Superbowl52(msg.sender);
    totalVoters = 0;
    threshold = th;
    tie = false;
    votingReward = 0;
  }

   
  function voteResult(uint team) public payable {
    require(votingStart <= now && votingEnd >= now);
    require(voted[msg.sender] == false);
    require(msg.value == 50 finney);
    require(!closed);
    if(team == 1) {
      phiWon += 1;
    }
    else if (team == 2) {
      neWon += 1;
    } else revert();
    voted[msg.sender] = true;
    votes[msg.sender] = team;
    totalVoters += 1;
    stake[msg.sender] = msg.value;
  }

  function closeBallot() public returns (uint) {
    require(!closed);
    require(now > votingEnd);
    if((phiWon.mul(100000).div(totalVoters) == neWon.mul(100000).div(totalVoters)) && (threshold == 50000)) {
      validResult = 9;
      closed = true;
      tie = true;
      return validResult;
    } else if(phiWon.mul(100000).div(totalVoters) >= threshold) {
      validResult = 1;
      votingReward = bettingContract.getLosersOnePercent(2);
      majorityReward = (neWon * 50 finney).add(votingReward).div(phiWon);
    } else if (neWon.mul(100000).div(totalVoters) >= threshold) {
      validResult = 2;
      votingReward = bettingContract.getLosersOnePercent(3);
      majorityReward = (phiWon * 50 finney).add(votingReward).div(neWon);
    } else {
      if (neWon.mul(100000).div(totalVoters) > 50000) majorityReward = (phiWon * 50 finney).div(neWon);
      else if (phiWon.mul(100000).div(totalVoters) > 50000) majorityReward = (neWon * 50 finney).div(phiWon);
      else {
        tie = true;
        majorityReward = 0;
      }
      validResult = 0;
    }
    closed = true;
    return validResult;
  }

   
  function getReward(address voter) public {
    require(closed);
    require(voted[voter]);
    require(claimed[voter] == false);
    if(tie) {
      voter.transfer(stake[voter]);
    }
     
    if(votes[voter] == validResult) {
      voter.transfer(stake[voter] + majorityReward);
    }  
    claimed[voter] = true;
  }

  function hasClaimed(address voter) public constant returns (bool) {
    return claimed[voter];
  }

  function () public payable {}
}

 
 
 
 

contract Superbowl52 {
  using SafeMath for uint;
  uint public constant GAME_START_TIME = 1517787000;
  bool public resultConfirmed = false;
  address public owner;

  mapping(address => betting) public bets;
  uint public totalBets;
  uint public philadelphiaBets;
  uint public newEnglandBets;
  uint public result;
  uint public betters;
  bool public votingOpen;
  bool public withdrawalOpen;
  uint public threshold;
  uint public winningPot;
  mapping(address => uint) public wins;

  BallotSB52 public ballot;

  struct betting {
    uint philadelphiaBets;
    uint newEnglandBets;
    bool claimed;
  }

  function Superbowl52() public {
    require(now<GAME_START_TIME);
    owner = msg.sender;
    result = 0;
    votingOpen = false;
    withdrawalOpen = false;
     
    threshold = 90000;
    winningPot = 0;
  }

   
   
   
  function bet(uint team) public payable {
    require(team == 1 || team == 2);
    require(now <= GAME_START_TIME);
    require(msg.value > 0);
    if(!hasBet(msg.sender)) betters += 1;
    if(team == 1) {
      bets[msg.sender].philadelphiaBets += msg.value;
      philadelphiaBets += msg.value;
    } else if (team == 2) {
      bets[msg.sender].newEnglandBets += msg.value;
      newEnglandBets += msg.value;
    }
    totalBets += msg.value;
  }

  function () public payable {
    revert();
  }

  function getPhiladelphiaBets(address better) public constant returns (uint) {
    return bets[better].philadelphiaBets;
  }

  function getNewEnglandBets(address better) public constant returns (uint) {
    return bets[better].newEnglandBets;
  }

  function hasClaimed(address better) public constant returns (bool) {
    return bets[better].claimed;
  }

  function startVoting() public {
    require(votingOpen == false);
    require(withdrawalOpen == false);
    require(now >= GAME_START_TIME + 8 hours);
    votingOpen = true;
    ballot = new BallotSB52(threshold);
  }

  function hasBet(address better) public constant returns (bool) {
    return (bets[better].philadelphiaBets + bets[better].newEnglandBets) > 0;
  }

  function endVoting() public {
    require(votingOpen);
    result = ballot.closeBallot();
     
    if (result == 1 || result == 2) {
      withdrawalOpen = true;
      votingOpen = false;
    } else if (result == 9) {
      votingOpen = false;
      withdrawalOpen = false;
    } else {
      threshold = threshold - 5000;
      ballot = new BallotSB52(threshold);
    }
    if(result == 1) winningPot = totalBets.sub(newEnglandBets.div(100));
    if(result == 2) winningPot = totalBets.sub(philadelphiaBets.div(100));
  }

  function getLosersOnePercent(uint loser) public returns (uint) {
    require(votingOpen);
    require(msg.sender == address(ballot));
    if(loser==1) {
      ballot.transfer(philadelphiaBets.div(100));
      return philadelphiaBets.div(100);
    }
    else if (loser==2) {
      ballot.transfer(newEnglandBets.div(100));
      return newEnglandBets.div(100);
    }
    else {
      return 0;
    }
  }

   
  function breakTie(uint team) {
    require(result == 9);
    require(msg.sender == owner);
    result = team;
    withdrawalOpen = true;
  }

  function getWinnings(uint donation) public {
    require(donation<=100);
    require(withdrawalOpen);
    require(bets[msg.sender].claimed == false);
    uint winnings = 0;
    if (result == 1) winnings = (getPhiladelphiaBets(msg.sender).mul(winningPot)).div(philadelphiaBets);
    else if (result == 2) winnings = (getNewEnglandBets(msg.sender).mul(winningPot)).div(newEnglandBets);
    else revert();
    wins[msg.sender] = winnings;
    uint donated = winnings.mul(donation).div(100);
    bets[msg.sender].claimed = true;
    owner.transfer(donated);
    msg.sender.transfer(winnings-donated);
  }

}