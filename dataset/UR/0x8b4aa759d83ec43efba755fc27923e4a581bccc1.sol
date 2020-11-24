 

contract BlockChainChallenge {
    
  address admin;
  address leader;
  bytes32 leaderHash;
  bytes32 difficulty;
  bytes32 difficultyWorldRecord;
  uint fallenLeaders;
  uint startingTime;
  uint gameLength;
  string leaderMessage;
  string defaultLeaderMessage;
  mapping (address => uint) winners;
  
  event Begin(string log);
  event Leader(string log, address newLeader, bytes32 newHash);
  event GameOver(string log);
  event Winner (string log, address winner);
  event NoWinner (string log);
  event WorldRecord (string log, bytes32 DifficultyRecord, address RecordHolder);
  
  function BlockChainChallenge(){ 
      
     
    admin = msg.sender;

     
    startingTime = block.timestamp;
    
     
    gameLength = 1 weeks;

     
    leaderHash = sha3("09F911029D74E35BD84156C5635688C0");

     
    leader = msg.sender;

     
    defaultLeaderMessage = "If you're this weeks leader, you own this field. Write a message here.";
    leaderMessage = defaultLeaderMessage;
    
     
    difficulty = leaderHash;
    
     
    difficultyWorldRecord = leaderHash;
    
     
    fallenLeaders = 0;

    Begin("Collide the most bits of the leader's hash to replace the leader. Leader will win any bounty at the end of the week.");

  }
  
  function reset() private{
      
       
      leaderHash = sha3(block.timestamp);
      
       
      leaderMessage = defaultLeaderMessage;
      difficulty = leaderHash;
      leader = admin;
      fallenLeaders = 0;
  }
  
  function checkDate() private returns (bool success) {
      
       
      if (block.timestamp > (startingTime + gameLength)) {
          
           
          if(leader != admin){
            Winner("Victory! Game will be reset to end in 1 week (in block time).", leader);
            leader.send(this.balance);
          }else NoWinner("No winner! Game will be reset to end in 1 week (in block time).");

          startingTime = block.timestamp;

           
          reset();
          return true;
      }
      return false;
  }

  function overthrow(string challengeData) returns (bool success){
        
         
        var challengeHash = sha3(challengeData);

         
        if(checkDate())
            return false;
        
         
        if(challengeHash == leaderHash)
            return false;

         
        if((challengeHash ^ leaderHash) > difficulty)
          return false;

         
         
        difficulty = (challengeHash ^ leaderHash);
        
         
        challengeWorldRecord(difficulty);
        
         
        leader = msg.sender;
        
         
        leaderHash = challengeHash;
        
         
        Leader("New leader! This is their address, and the new hash to collide.", leader, leaderHash);
        
         
        winners[msg.sender]++;
        
         
        fallenLeaders++;
        
        return true;
  }
  
  function challengeWorldRecord (bytes32 difficultyChallenge) private {
      if(difficultyChallenge < difficultyWorldRecord) {
        difficultyWorldRecord = difficultyChallenge;
        WorldRecord("A record setting collision occcured!", difficultyWorldRecord, msg.sender);
      }
  }
  
  function changeLeaderMessage(string newMessage){
         
        if(msg.sender == leader)
            leaderMessage = newMessage;
  }
  
   
  function currentLeader() constant returns (address CurrentLeaderAddress){
      return leader;
  }
  function Difficulty() constant returns (bytes32 XorMustBeLessThan){
      return difficulty;
  }
  function TargetHash() constant returns (bytes32 leadingHash){
      return leaderHash;
  }
  function LeaderMessage() constant returns (string MessageOfTheDay){
      return leaderMessage;
  }
  function FallenLeaders() constant returns (uint Victors){
      return fallenLeaders;
  }
  function GameEnds() constant returns (uint EndingTime){
      return startingTime + gameLength;
  }
  function getWins(address check) constant returns (uint wins){
      return winners[check];
  }

  function kill(){
      if (msg.sender == admin){
        GameOver("The challenge has ended.");
        selfdestruct(admin);
      }
  }
}