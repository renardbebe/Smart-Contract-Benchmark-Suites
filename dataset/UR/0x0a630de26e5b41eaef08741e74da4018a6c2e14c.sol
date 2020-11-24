 

pragma solidity ^0.4.10;

 

contract dgame {
    uint public registerDuration;
    uint public endRegisterTime;
    uint public gameNumber;
    uint public numPlayers;
    mapping(uint => mapping(uint => address)) public players;
    mapping(uint => mapping(address => bool)) public registered;
    event StartedGame(address initiator, uint regTimeEnd, uint amountSent, uint gameNumber);
    event RegisteredPlayer(address player, uint gameNumber);
    event FoundWinner(address player, uint gameNumber);
    
     
    function dgame() {
        registerDuration = 600;
    }
    
     
    function() payable {
         
        if (endRegisterTime == 0) {
            endRegisterTime = now + registerDuration;
            if (msg.value == 0)
                throw;   
            StartedGame(msg.sender, endRegisterTime, msg.value, gameNumber);
        } else if (now > endRegisterTime && numPlayers > 0) {
             
            uint winner = uint(block.blockhash(block.number - 1)) % numPlayers;  
            uint currentGamenumber = gameNumber;
            FoundWinner(players[currentGamenumber][winner], currentGamenumber);
            endRegisterTime = 0;
            numPlayers = 0;
            gameNumber++;

             
             
             
            players[currentGamenumber][winner].send(this.balance);
        } else {
             
            if (registered[gameNumber][msg.sender])
                throw;   
            registered[gameNumber][msg.sender] = true;
            players[gameNumber][numPlayers] = (msg.sender);
            numPlayers++;
            RegisteredPlayer(msg.sender, gameNumber);
        }
    }
}