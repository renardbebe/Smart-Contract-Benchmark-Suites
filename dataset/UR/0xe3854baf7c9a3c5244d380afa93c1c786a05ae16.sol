 

 
pragma solidity ^0.4.7;
contract Contest {
 
uint public id;
 
address owner;
 
address public referee;
 
address public c4c;
 
address[] public participants;
 
address[] public voters;
 
address[] public winners;
 
address[] public luckyVoters;
 
uint public totalPrize;
 
mapping(address=>bool) public participated;
 
mapping(address=>bool) public voted;
 
mapping(address=>uint) public numVotes;
 
mapping(address => bool) public disqualified;
 
uint public deadlineParticipation;
 
uint public deadlineVoting;
 
uint128 public participationFee;
 
uint128 public votingFee;
 
uint16 public c4cfee;
 
uint16 public prizeOwner;
uint16 public prizeReferee;
uint16[] public prizeWinners;
 
uint8 public nLuckyVoters;

 
event ContestClosed(uint prize, address[] winners, address[] votingWinners);

 
function Contest() payable{
c4c = 0x87b0de512502f3e86fd22654b72a640c8e0f59cc;
c4cfee = 1000;
owner = msg.sender;

deadlineParticipation=1494882780;
deadlineVoting=1496179080;
participationFee=50000000000000000;
votingFee=50000000000000000;
prizeOwner=200;
prizeReferee=0;
prizeWinners.push(6045);
nLuckyVoters=2;


uint16 sumPrizes = prizeOwner;
for(uint i = 0; i < prizeWinners.length; i++) {
sumPrizes += prizeWinners[i];
}
if(sumPrizes>10000)
throw;
else if(sumPrizes < 10000 && nLuckyVoters == 0) 
throw;
}

 
function participate() payable {
if(msg.value < participationFee)
throw;
else if (now >= deadlineParticipation)
throw;
else if (participated[msg.sender])
throw;
else if (msg.sender!=tx.origin)  
throw;
else {
participants.push(msg.sender);
participated[msg.sender]=true;
 
if(winners.length < prizeWinners.length) winners.push(msg.sender);
}
}

 
function vote(address candidate) payable{
if(msg.value < votingFee)
throw;
else if(now < deadlineParticipation || now >=deadlineVoting)
throw;
else if(voted[msg.sender]) 
throw;
else if (msg.sender!=tx.origin)  
throw;
else if(!participated[candidate])  
throw;
else{
voters.push(msg.sender);
voted[msg.sender] = true;
numVotes[candidate]++;

for(var i = 0; i < winners.length; i++){ 
if(winners[i]==candidate) break; 
if(numVotes[candidate]>numVotes[winners[i]]){ 
 
 
for(var j = getCandidatePosition(candidate, i+1); j>i; j--){
winners[j]=winners[j-1];
}
winners[i]=candidate;
break;
}
}
}
}

function getCandidatePosition(address candidate, uint startindex) internal returns (uint){
for(uint i = startindex; i < winners.length; i++){
if(winners[i]==candidate) return i;
}
return winners.length-1;
}

 
function disqualify(address candidate){
if(msg.sender==referee)
disqualified[candidate]=true;
}

 
function requalify(address candidate){
if(msg.sender==referee)
disqualified[candidate]=false;
}

 
function close(){
 
if(now>=deadlineVoting&&totalPrize==0){
determineLuckyVoters();
if(this.balance>10000) distributePrizes();  
ContestClosed(totalPrize, winners, luckyVoters);
}
}

 
function determineLuckyVoters() constant {
if(nLuckyVoters>=voters.length)
luckyVoters = voters;
else{
mapping (uint => bool) chosen;
uint nonce=1;

uint rand;
for(uint i = 0; i < nLuckyVoters; i++){
do{
rand = randomNumberGen(nonce, voters.length);
nonce++;
}while (chosen[rand]);

chosen[rand] = true;
luckyVoters.push(voters[rand]);
}
}
}

 
function randomNumberGen(uint nonce, uint range) internal constant returns(uint){
return uint(block.blockhash(block.number-nonce))%range;
}

 
function distributePrizes() internal{

if(!c4c.send(this.balance/10000*c4cfee)) throw;
totalPrize = this.balance;
if(prizeOwner!=0 && !owner.send(totalPrize/10000*prizeOwner)) throw;
if(prizeReferee!=0 && !referee.send(totalPrize/10000*prizeReferee)) throw;
for (uint8 i = 0; i < winners.length; i++)
if(prizeWinners[i]!=0 && !winners[i].send(totalPrize/10000*prizeWinners[i])) throw;
if (luckyVoters.length>0){ 
if(this.balance>luckyVoters.length){ 
uint amount = this.balance/luckyVoters.length;
for(uint8 j = 0; j < luckyVoters.length; j++)
if(!luckyVoters[j].send(amount)) throw;
}
}
else if(!owner.send(this.balance)) throw; 
}

 
function getTotalVotes() constant returns(uint){
return voters.length;
}
}