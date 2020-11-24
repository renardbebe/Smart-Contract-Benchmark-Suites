 

pragma solidity ^0.4.23;

contract FireCasino {
address public owner;
 
uint256 public minimumBet = 1000000;

 
uint256 public totalBet;

 
uint256 public numberOfBets;

 
 
uint256 public maximumBetsNr = 2;

 
address[] public players;

 
uint public numberWinner;

 
struct Player {
uint256 amountBet;
uint256 numberSelected;
}

 
mapping(address => Player) public playerInfo;

 
event Won(bool _status, address _address, uint _amount);

modifier onlyOwner() {
require(msg.sender == owner);
_;
}

constructor() public payable {
owner = msg.sender;
minimumBet = 1000000;
}

 
function() public payable {}

function kill() public {
if (msg.sender == owner)
selfdestruct(owner);
}

 
function collect() external onlyOwner{
    owner.transfer(address(this).balance);
}

 
 
 
function checkPlayerExists(address player) public constant returns(bool) {
        for (uint256 i = 0; i < players.length; i++) {
        if (players[i] == player)
        return true;
    }
    return false;
}

 
 
function bet(uint256 numberSelected) public payable {
 
require(!checkPlayerExists(msg.sender));
 
require(numberSelected <= 10 && numberSelected >= 1);
 
require(msg.value >= minimumBet);

 
playerInfo[msg.sender].amountBet = msg.value;
playerInfo[msg.sender].numberSelected = numberSelected;
numberOfBets++;
players.push(msg.sender);
totalBet += msg.value;
if (numberOfBets >= maximumBetsNr)
generateNumberWinner();
 
}

 
 
function generateNumberWinner() public {
uint256 numberGenerated = block.number % 10 + 1;
numberWinner = numberGenerated;
distributePrizes(numberGenerated);
}

 
 
function distributePrizes(uint256 numberWin) public {
address[100] memory winners;
address[100] memory losers;
uint256 countWin = 0;
uint256 countLose = 0;

for (uint256 i = 0; i < players.length; i++) {
address playerAddress = players[i];
if (playerInfo[playerAddress].numberSelected == numberWin) {
winners[countWin] = playerAddress;
countWin++;
} else {
losers[countLose] = playerAddress;
countLose++;
}
delete playerInfo[playerAddress];
}

if (countWin != 0) {
uint256 winnerEtherAmount = totalBet/countWin;

for (uint256 j = 0; j < countWin; j++){
if (winners[j] != address(0)) {
winners[j].transfer(winnerEtherAmount);
emit Won(true, winners[j], winnerEtherAmount);
}
}
}

for (uint256 l = 0; l < losers.length; l++){
if (losers[l] != address(0))
emit Won(false, losers[l], 0);
}

resetData();
}

 
function resetData() public {
players.length = 0;
totalBet = 0;
numberOfBets = 0;
}
}