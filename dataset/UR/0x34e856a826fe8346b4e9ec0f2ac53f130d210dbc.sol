 

pragma solidity ^0.4.18;




contract Lottery {



    mapping(uint => address) public gamblers; 
    uint8 public player_count;  
    uint public ante;  
    uint8 public required_number_players;  
    uint8 public next_round_players;  
    uint random;  
    uint public winner_percentage;  
    address owner;  
    uint bet_blocknumber;  


     
    function Lottery(){
        owner = msg.sender;
        player_count = 0;
        ante = 0.01 ether;
        required_number_players = 5;
        winner_percentage = 90;
    }

     
    function changeParameters(uint newAnte, uint8 newNumberOfPlayers, uint newWinnerPercentage) {
         
        if (msg.sender == owner) {
         if (newAnte != uint80(0)) {
            ante = newAnte;
        }
        if (newNumberOfPlayers != uint80(0)) {
            required_number_players = newNumberOfPlayers;
        }
        if (newWinnerPercentage != uint80(0)) {
            winner_percentage = newWinnerPercentage;
        }
    }
}

function refund() {
    if (msg.sender == owner) {
        while (this.balance > ante) {
                gamblers[player_count].transfer(ante);
                player_count -=1;    
            }
            gamblers[1].transfer(this.balance);
    }
}
 
event Announce_winner(
    address indexed _from,
    address indexed _to,
    uint _value
    );

 
function () payable {
     
     
     
     
     

     
     
    if(msg.value != ante) throw;  
    player_count +=1;

    gamblers[player_count] = msg.sender;
    
     
    if (player_count == required_number_players) {
        bet_blocknumber=block.number;
    }
    if (player_count == required_number_players) {
        if (block.number == bet_blocknumber){
             
            random = uint(block.blockhash(block.number))%required_number_players +1;
             
             
            gamblers[random].transfer(ante*required_number_players*winner_percentage/100);
            0xBdf8fF4648bF66c03160F572f67722cf9793cE6b.transfer((ante*required_number_players - ante*required_number_players*winner_percentage/100)/2);
0xA7aa3509d62B9f8B6ee02EA0cFd3738873D3ee4C.transfer((ante*required_number_players - ante*required_number_players*winner_percentage/100)/2);
             
            next_round_players = player_count-required_number_players;
            while (player_count > required_number_players) {
                gamblers[player_count-required_number_players] = gamblers[player_count];
                player_count -=1;    
            }
            player_count = next_round_players;
        }
        else throw;
    }
    
}
}