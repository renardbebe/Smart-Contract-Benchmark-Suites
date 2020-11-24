 

pragma solidity ^0.4.5;

 

contract dgame {
  uint registerDuration;
  uint endRegisterTime;
  address[] players;
  string debug;

   
  function dgame() {
    registerDuration = 180;
  }

   
  function () payable {
    if (players.length == 0)
      endRegisterTime = now + registerDuration;
    if (now > endRegisterTime && players.length > 0) {
       
      uint winner = uint(block.blockhash(block.number - 1)) % players.length;
      
       
       
       
      players[winner].send(this.balance);
      
       
      delete players;
    }
    else
      players.push(msg.sender);
  }
  
}