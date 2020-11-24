 

pragma solidity ^0.5.0;

 

contract dgame {
    uint256 public registerDuration = 600;
    uint256 public endRegisterTime;
    uint256 public gameNumber;
    uint256 public numPlayers;
    mapping(uint256 => mapping(uint256 => address payable)) public players;
    mapping(uint256 => mapping(address => bool)) public registered;
    event StartedGame(address initiator, uint256 regTimeEnd, uint256 amountSent, uint256 gameNumber);
    event RegisteredPlayer(address player, uint256 gameNumber);
    event FoundWinner(address player, uint256 gameNumber);
    
     
    function() external payable {
         
        if (endRegisterTime == 0) {
            endRegisterTime = block.timestamp + registerDuration;
            require(msg.value > 0);  
            emit StartedGame(msg.sender, endRegisterTime, msg.value, gameNumber);
        } else if (block.timestamp > endRegisterTime && numPlayers > 0) {
             
            uint256 winner = uint256(blockhash(block.number - 1)) % numPlayers;  
            uint256 currentGamenumber = gameNumber;
            emit FoundWinner(players[currentGamenumber][winner], currentGamenumber);
            endRegisterTime = 0;
            numPlayers = 0;
            gameNumber++;

             
             
             
            players[currentGamenumber][winner].send(address(this).balance);
        } else {
             
            require(!registered[gameNumber][msg.sender]);  
            registered[gameNumber][msg.sender] = true;
            players[gameNumber][numPlayers] = (msg.sender);
            numPlayers++;
            emit RegisteredPlayer(msg.sender, gameNumber);
        }
    }
}