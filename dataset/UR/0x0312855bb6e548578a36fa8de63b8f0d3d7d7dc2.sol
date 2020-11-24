 

 

contract BetOnHashV84 {
  struct Player {
    address addr;
    byte bet;
  }
  
  Player[] public players;
  bool public active;
  uint public betAmount;
  uint public playersPerRound;
  uint public round;
  uint public winPool;
  byte public betByte;

  uint lastPlayersBlockNumber;
  address owner;
  
  modifier onlyowner { if (msg.sender == owner) _ }
  
  function BetOnHashV84() {
    owner = msg.sender;
    betAmount = 1 ether;
    round = 1;
    playersPerRound = 6;
    active = true;
    winPool = 0;
  }
  
  function finishRound() internal {
     
    bytes32 betHash = block.blockhash(lastPlayersBlockNumber);
    betByte = byte(betHash);
    byte bet;
    uint8 ix; 
    
     
    address[] memory winners = new address[](playersPerRound);
    uint8 numWinners=0;
    for(ix=0; ix < players.length; ix++) {
      Player p = players[ix];
      if(p.bet < 0x80 && betByte < 0x80 || p.bet >= 0x80 && betByte >= 0x80) {
         
        winners[numWinners++] = p.addr;
      } 
      else winPool += betAmount;
    }
    
     
    if(numWinners > 0) {
      uint winAmount = (winPool / numWinners) * 99 / 100;
      for(ix = 0; ix < numWinners; ix++) {
        if(!winners[ix].send(betAmount + winAmount)) throw;
      }
      winPool = 0;
    }
    
     
    round++;
    delete players;
  }
  
  function reject() internal {
    msg.sender.send(msg.value);
  }
  
  function join() internal {
     
    if(players.length >= playersPerRound) { 
      if(block.number > lastPlayersBlockNumber) finishRound(); 
      else {reject(); return;}   
    }

     
    if(msg.value < betAmount) {
      winPool += msg.value; 
      return;
    }
    
     
    if(msg.data.length < 1) {reject();return;}
    
     
    for(uint8 i = 0; i < players.length; i++)
      if(msg.sender == players[i].addr) {reject(); return;}
    
     
    if(msg.value > betAmount) {
      msg.sender.send(msg.value - betAmount);
    }
    
     
    players.push( Player(msg.sender, msg.data[0]) );
    lastPlayersBlockNumber = block.number;
  }
  
  function () {
    if(active) join();
    else throw;
  }
  
  function paybackLast() onlyowner returns (bool) {
    if(players.length == 0) return true;
    if (players[players.length - 1].addr.send(betAmount)) {
      players.length--;
      return true;
    }
    return false;
  }
  
   
  function paybackAll() onlyowner returns (bool) {
    while(players.length > 0) {if(!paybackLast()) return false;}
    return true;
  }
  
  function collectFees() onlyowner {
    uint playersEther = winPool;
    uint8 ix;
    for(ix=0; ix < players.length; ix++) playersEther += betAmount;
    uint fees = this.balance - playersEther;
    if(fees > 0) owner.send(fees);
  }
  
  function changeOwner(address _owner) onlyowner {
    owner = _owner;
  }
  
  function setPlayersPerRound(uint num) onlyowner {
    if(players.length > 0) finishRound();
    playersPerRound = num;
  }
  
  function stop() onlyowner {
    active = false;
    paybackAll();
  }
  
  function numberOfPlayersInCurrentRound() constant returns (uint count) {
    count = players.length;
  }

   
  function kill() onlyowner {
    if(!active && paybackAll()) 
      selfdestruct(owner);
  }
}