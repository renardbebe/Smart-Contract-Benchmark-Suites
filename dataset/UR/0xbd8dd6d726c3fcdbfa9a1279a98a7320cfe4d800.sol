 

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

contract ChampionSimple is Ownable {
  using SafeMath for uint;

  event LogDistributeReward(address addr, uint reward);
  event LogParticipant(address addr, uint choice, uint betAmount);
  event LogModifyChoice(address addr, uint oldChoice, uint newChoice);
  event LogRefund(address addr, uint betAmount);
  event LogWithdraw(address addr, uint amount);
  event LogWinChoice(uint choice, uint reward);

  uint public minimumBet = 5 * 10 ** 16;
  uint public deposit = 0;
  uint public totalBetAmount = 0;
  uint public startTime;
  uint public winChoice;
  uint public winReward;
  uint public numberOfBet;
  bool public betClosed = false;

  struct Player {
    uint betAmount;
    uint choice;
  }

  address [] public players;
  mapping(address => Player) public playerInfo;
  mapping(uint => uint) public numberOfChoice;
  mapping(uint => mapping(address => bool)) public addressOfChoice;
  mapping(address => bool) public withdrawRecord;
 
  modifier beforeTimestamp(uint timestamp) {
    require(now < timestamp);
    _;
  }

  modifier afterTimestamp(uint timestamp) {
    require(now >= timestamp);
    _;
  }

   
  function ChampionSimple(uint _startTime, uint _minimumBet) payable public {
    require(_startTime > now);
    deposit = msg.value;
    startTime = _startTime;
    minimumBet = _minimumBet;
  }

   
  function checkPlayerExists(address player) public view returns (bool) {
    if (playerInfo[player].choice == 0) {
      return false;
    }
    return true;
  }

   
  function placeBet(uint choice) payable beforeTimestamp(startTime) public {
    require(choice > 0);
    require(!checkPlayerExists(msg.sender));
    require(msg.value >= minimumBet);

    playerInfo[msg.sender].betAmount = msg.value;
    playerInfo[msg.sender].choice = choice;
    totalBetAmount = totalBetAmount.add(msg.value);
    numberOfBet = numberOfBet.add(1);
    players.push(msg.sender);
    numberOfChoice[choice] = numberOfChoice[choice].add(1);
    addressOfChoice[choice][msg.sender] = true;
    LogParticipant(msg.sender, choice, msg.value);
  }

   
  function modifyChoice(uint choice) beforeTimestamp(startTime) public {
    require(choice > 0);
    require(checkPlayerExists(msg.sender));

    uint oldChoice = playerInfo[msg.sender].choice;
    numberOfChoice[oldChoice] = numberOfChoice[oldChoice].sub(1);
    numberOfChoice[choice] = numberOfChoice[choice].add(1);
    playerInfo[msg.sender].choice = choice;

    addressOfChoice[oldChoice][msg.sender] = false;
    addressOfChoice[choice][msg.sender] = true;
    LogModifyChoice(msg.sender, oldChoice, choice);
  }

   
  function saveResult(uint teamId) onlyOwner public {
    winChoice = teamId;
    betClosed = true;
    winReward = deposit.add(totalBetAmount).div(numberOfChoice[winChoice]);
    LogWinChoice(winChoice, winReward);
  }

   
  function withdrawReward() public {
    require(betClosed);
    require(!withdrawRecord[msg.sender]);
    require(winChoice > 0);
    require(winReward > 0);
    require(addressOfChoice[winChoice][msg.sender]);

    msg.sender.transfer(winReward);
    withdrawRecord[msg.sender] = true;
    LogDistributeReward(msg.sender, winReward);
  }

   
  function rechargeDeposit() payable public {
    deposit = deposit.add(msg.value);
  }

   
  function getPlayerBetInfo(address addr) view public returns (uint, uint) {
    return (playerInfo[addr].choice, playerInfo[addr].betAmount);
  }

   
  function getNumberByChoice(uint choice) view public returns (uint) {
    return numberOfChoice[choice];
  }

   
  function refund() onlyOwner public {
    for (uint i = 0; i < players.length; i++) {
      players[i].transfer(playerInfo[players[i]].betAmount);
      LogRefund(players[i], playerInfo[players[i]].betAmount);
    }
  }

   
  function getPlayers() view public returns (address[]) {
    return players;
  }

   
  function withdraw() onlyOwner public {
    uint _balance = address(this).balance;
    owner.transfer(_balance);
    LogWithdraw(owner, _balance);
  }
}