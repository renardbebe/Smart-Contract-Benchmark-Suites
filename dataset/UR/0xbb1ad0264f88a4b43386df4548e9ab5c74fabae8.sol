 

pragma solidity 0.4.19;


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


contract BetContract is Pausable{

 

 
 
 
 
 

 
 
 



uint minAmount;
uint feePercentage;
uint AteamAmount = 0;
uint BteamAmount = 0;

address Acontract;
address Bcontract;
address fundCollection;
uint public transperrun;

team[] public AteamBets;
team[] public BteamBets;

struct team{
address betOwner;
uint amount;
uint date;


}



function BetContract() public {

minAmount = 0.02 ether;
feePercentage = 9500;

fundCollection = owner;
transperrun = 25;
Acontract = new BetA(this,minAmount,"A");
Bcontract = new BetB(this,minAmount,"B");

}



function changeFundCollection(address _newFundCollection) public onlyOwner{
fundCollection = _newFundCollection;
}

function contractBalance () public view returns(uint balance){

return this.balance;

}


function contractFeeMinAmount () public view returns (uint _feePercentage, uint _minAmount){
return (feePercentage, minAmount);
}

function betALenght() public view returns(uint lengthA){
return AteamBets.length;
}

function betBLenght() public view returns(uint lengthB){
return BteamBets.length;
}

function teamAmounts() public view returns(uint A,uint B){
return(AteamAmount,BteamAmount);
}
function BetAnB() public view returns(address A, address B){
return (Acontract,Bcontract);
}

function setTransperRun(uint _transperrun) public onlyOwner{
transperrun = _transperrun;
}

function cancelBet() public onlyOwner returns(uint _balance){
require(this.balance > 0);
 
team memory tempteam;
uint p;


if (AteamBets.length < transperrun)
p = AteamBets.length;
else
p = transperrun;

 
while (p > 0){

tempteam = AteamBets[p-1];
AteamBets[p-1] = AteamBets[AteamBets.length -1];
delete AteamBets[AteamBets.length - 1 ];
AteamBets.length --;
p --;
 
AteamAmount = AteamAmount - tempteam.amount;
 
tempteam.betOwner.transfer(tempteam.amount);
tempteam.amount = 0;


}

if (BteamBets.length < transperrun)
p = BteamBets.length;
else
p = transperrun;
 
while (p > 0){

tempteam = BteamBets[p-1];
BteamBets[p-1] = BteamBets[BteamBets.length - 1];
delete BteamBets[BteamBets.length - 1];
BteamBets.length --;
p--;
 
BteamAmount = BteamAmount - tempteam.amount;
 
tempteam.betOwner.transfer(tempteam.amount);
tempteam.amount = 0;


}


return this.balance;



}

function result(uint _team) public onlyOwner returns (uint _balance){
require(this.balance > 0);
require(checkTeamValue(_team));

 
uint transferAmount = 0;
team memory tempteam;
uint p;

if(_team == 1){



if (AteamBets.length < transperrun)
p = AteamBets.length;
else
p = transperrun;

 
while (p > 0){
transferAmount = AteamBets[p-1].amount + (AteamBets[p-1].amount * BteamAmount / AteamAmount);
tempteam = AteamBets[p-1];

AteamBets[p-1] = AteamBets[AteamBets.length -1];
delete AteamBets[AteamBets.length - 1 ];
AteamBets.length --;
p --;
 

 

 
tempteam.betOwner.transfer(transferAmount * feePercentage/10000);
tempteam.amount = 0;
transferAmount = 0;

}


}else{

if (BteamBets.length < transperrun)
p = BteamBets.length;
else
p = transperrun;
 
while (p > 0){
transferAmount = BteamBets[p-1].amount + (BteamBets[p-1].amount * AteamAmount / BteamAmount);
tempteam = BteamBets[p-1];
BteamBets[p-1] = BteamBets[BteamBets.length - 1];
delete BteamBets[BteamBets.length - 1];
BteamBets.length --;
p--;
 
 
 
tempteam.betOwner.transfer(transferAmount * feePercentage/10000);
tempteam.amount = 0;
transferAmount = 0;

}


}



 
if (AteamBets.length == 0 || BteamBets.length == 0){
fundCollection.transfer(this.balance);
}

if(this.balance == 0){
delete AteamBets;
delete BteamBets;
AteamAmount = 0;
BteamAmount = 0;
}
return this.balance;



}

function checkTeamValue(uint _team) private pure returns (bool ct){
bool correctteam = false;
if (_team == 1){
correctteam = true;
}else{
if (_team == 2){
correctteam = true;
}
}
return correctteam;
}


function bet(uint _team,address _betOwner) payable public returns (bool success){
require(paused == false);
require(msg.value >= minAmount);


require(checkTeamValue(_team));

bool _success = false;


uint finalBetAmount = msg.value;

if (_team == 1){
AteamBets.push(team(_betOwner,finalBetAmount,now));
AteamAmount = AteamAmount + finalBetAmount;
_success = true;
}

if(_team == 2){
BteamBets.push(team(_betOwner,finalBetAmount,now));
BteamAmount = BteamAmount + finalBetAmount;
_success = true;
}

return _success;

}
}
contract TeamBet{
uint minAmount;

string teamName;


BetContract ownerContract;

function showTeam() public view returns(string team){
return teamName;
}

function showOwnerContract() public view returns(address _ownerContract) {

return ownerContract;
}


}
contract BetA is TeamBet{

function BetA(BetContract _BetContract,uint _minAmount, string _teamName) public{

ownerContract = _BetContract;
minAmount = _minAmount;
teamName = _teamName;
}


function() public payable {
 
require(ownerContract.bet.value(msg.value)(1,msg.sender));

}

}

contract BetB is TeamBet{

function BetB(BetContract _BetContract,uint _minAmount, string _teamName) public{

ownerContract = _BetContract;
minAmount = _minAmount;
teamName = _teamName;
}

function() public payable {
 
require(ownerContract.bet.value(msg.value)(2,msg.sender));

}
}