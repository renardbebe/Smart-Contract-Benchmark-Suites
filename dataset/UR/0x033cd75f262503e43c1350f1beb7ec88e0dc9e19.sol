 

 

pragma solidity ^0.4.23;

contract Ownable {
address owner;
constructor() public {
owner = msg.sender;
}

modifier onlyOwner {
require(msg.sender == owner);
_;
}
}

contract Mortal is Ownable {
function kill() public onlyOwner {
selfdestruct(owner);
}
}

contract FIREBET is Mortal{
uint minBet = 1000000000;
uint houseEdge = 1;  

event Won(bool _status, uint _number, uint _amount);

constructor() payable public {}

function() public {  
revert();
}

function bet(uint _number) payable public {
require(_number > 0 && _number <= 10);
require(msg.value >= minBet);
uint256 winningNumber = block.number % 10 + 1;
if (_number == winningNumber) {
uint amountWon = msg.value * (100 - houseEdge)/10;
if(!msg.sender.send(amountWon)) revert();
emit Won(true, winningNumber, amountWon);
} else {
emit Won(false, winningNumber, 0);
}
}

function checkContractBalance() public view returns(uint) {
return address(this).balance;
}

 
function collect(uint _amount) public onlyOwner {
require(address(this).balance > _amount);
owner.transfer(_amount);
}
}