 

pragma solidity ^0.4.18;

 
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
library ContractHelpers {
  function isContract(address addr) internal view returns (bool) {
      uint size;
      assembly { size := extcodesize(addr) }
      return size > 0;
    }
}

contract BetWinner is Ownable {
  address owner;

   
  struct Team {
    string name;
    uint256 bets;
    address[] bettors;
    mapping(address => uint256) bettorAmount;
  }

  Team[] teams;
  uint8 public winningTeamIndex = 255;  

   
  mapping(address => uint256) public payOuts;

  bool public inited;

   
  uint32 public bettingStart;
  uint32 public bettingEnd;
  uint32 public winnerAnnounced;

  uint8 public feePercentage;
  uint public minimumBet;
  uint public totalFee;

   
  event BetPlaced(address indexed _from, uint8 indexed _teamId, uint _value);
  event Withdraw(address indexed _to, uint _value);
  event Started(uint bettingStartTime, uint numberOfTeams);
  event WinnerAnnounced(uint8 indexed teamIndex);

   
  function BetWinner() public Ownable() {
    feePercentage = 2;
    minimumBet = 100 szabo;
  }

   
  function betInfo() public view returns (uint32, uint32, uint32, uint8, uint) {
    return (bettingStart, bettingEnd, winnerAnnounced, winningTeamIndex, teams.length);
  }
  function bettingStarted() private view returns (bool) {
    return now >= bettingStart;
  }
  function bettingEnded() private view returns (bool) {
    return now >= bettingEnd;
  }

   
  function addTeam(string _name) public onlyOwner {
    require(!inited);
    Team memory t = Team({
      name: _name,
      bets: 0,
      bettors: new address[](0)
    });
    teams.push(t);
  }
  
   
  function startBetting(uint32 _bettingStart, uint32 _bettingEnd) public onlyOwner {
    require(!inited);

    bettingStart = _bettingStart;
    bettingEnd = _bettingEnd;

    inited = true;

    Started(bettingStart, teams.length - 1);
  }

   
  function getBetAmount(uint8 teamIndex) view public returns (uint) {
    return teams[teamIndex].bettorAmount[msg.sender];
  }

   
  function getTeam(uint8 teamIndex) view public returns (string, uint, uint) {
    Team memory t = teams[teamIndex];
    return (t.name, t.bets, t.bettors.length);
  }

   
  function totalBets() view public returns (uint) {
    uint total = 0;
    for (uint i = 0; i < teams.length; i++) {
      total += teams[i].bets;
    }
    return total;
  }

   
  function bet(uint8 teamIndex) payable public {
     
    require(bettingStarted() && !bettingEnded() && winningTeamIndex == 255);
     
    require(msg.value >= minimumBet);
     
    require(!ContractHelpers.isContract(msg.sender));
     
    require(teamIndex < teams.length);

     
    Team storage team = teams[teamIndex];
     
    team.bets += msg.value;

     
    if (team.bettorAmount[msg.sender] == 0) {
      team.bettors.push(msg.sender);
    }

     
    BetPlaced(msg.sender, teamIndex, msg.value);
     
    team.bettorAmount[msg.sender] += msg.value;
  }

   
  function removeFeeAmount(uint totalPot, uint winnersPot) private returns(uint) {
    uint remaining = SafeMath.sub(totalPot, winnersPot);
     
    if (remaining == 0) {
      return 0;
    }

     
    uint feeAmount = SafeMath.div(remaining, 100);
    feeAmount = feeAmount * feePercentage;

    totalFee = feeAmount;
     
    return remaining - feeAmount;
  }

   
  function announceWinner(uint8 teamIndex) public onlyOwner {
     
    require(teamIndex < teams.length);
     
    require(bettingEnded() && winningTeamIndex == 255);
    winningTeamIndex = teamIndex;
    winnerAnnounced = uint32(now);

    WinnerAnnounced(teamIndex);
     
    calculatePayouts();
  }

   
  function calculatePayouts() private {
    uint totalAmount = totalBets();
    Team storage wt = teams[winningTeamIndex];
    uint winTeamAmount = wt.bets;
     
    if (winTeamAmount == 0) {
      return;
    }

     
    uint winnings = removeFeeAmount(totalAmount, winTeamAmount);

     
    for (uint i = 0; i < wt.bettors.length; i++) {
       
      uint betSize = wt.bettorAmount[wt.bettors[i]];
       
      uint percentage = SafeMath.div((betSize*100), winTeamAmount);
       
      uint payOut = winnings * percentage;
       
      payOuts[wt.bettors[i]] = SafeMath.div(payOut, 100) + betSize;
    }
  }

   
  function withdraw() public {
     
    require(winnerAnnounced > 0 && uint32(now) > winnerAnnounced);
     
    require(payOuts[msg.sender] > 0);

     
    uint po = payOuts[msg.sender];
    payOuts[msg.sender] = 0;

    Withdraw(msg.sender, po);
     
    msg.sender.transfer(po);
  }

   
  function withdrawFee() public onlyOwner {
    require(totalFee > 0);
     
    require(winnerAnnounced > 0 && now > winnerAnnounced);
     
    msg.sender.transfer(totalFee);
     
    totalFee = 0;
  }

   
  function cancel() public onlyOwner {
    require (winningTeamIndex == 255);
    winningTeamIndex = 254;
    winnerAnnounced = uint32(now);

    Team storage t = teams[0];
    for (uint i = 0; i < t.bettors.length; i++) {
      payOuts[t.bettors[i]] += t.bettorAmount[t.bettors[i]];
    }
    Team storage t2 = teams[1];
    for (i = 0; i < t2.bettors.length; i++) {
      payOuts[t2.bettors[i]] += t2.bettorAmount[t2.bettors[i]];
    }
  }

   
  function kill() public onlyOwner {
     
    require(winnerAnnounced > 0 && uint32(now) > (winnerAnnounced + 8 weeks));
    selfdestruct(msg.sender);
  }

   
  function () public payable {
    revert();
  }
}