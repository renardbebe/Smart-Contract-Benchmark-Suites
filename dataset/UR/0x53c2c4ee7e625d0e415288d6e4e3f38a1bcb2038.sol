 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

contract lucky9io {
     
    uint public house_edge = 0;
    uint public jackpot = 0;
    address public last_winner;
    uint public last_win_wei = 0;
    uint public total_wins_wei = 0;
    uint public total_wins_count = 0;

     
    bool private game_alive = true;
    address private owner = 0x5Bf066c70C2B5e02F1C6723E72e82478Fec41201;
    uint private entry_number = 0;
    uint private value = 0;

    modifier onlyOwner() {
     require(msg.sender == owner, "Sender not authorized.");
     _;
    }

    function () public payable {
         
        require(game_alive == true);

         
        require(msg.value / 1000000000000000 == 9);

         
        jackpot = jackpot + (msg.value * 98 / 100);
        house_edge = house_edge + (msg.value / 100);

         
        if(msg.sender == owner) return;

         
        entry_number = entry_number + 1;

         
        if(entry_number % 999 == 0) {
             

             
            uint win_amount_999 = jackpot * 80 / 100;
            jackpot = jackpot - win_amount_999;

             
            last_winner = msg.sender;
            last_win_wei = win_amount;
            total_wins_count = total_wins_count + 1;
            total_wins_wei = total_wins_wei + win_amount_999;

             
            msg.sender.transfer(win_amount_999);
            return;
        } else {
             
            uint lucky_number = uint(keccak256(abi.encodePacked((entry_number+block.number), blockhash(block.number))));

            if(lucky_number % 3 == 0) {
                 

                 
                uint win_amount = jackpot * 50 / 100;
                if(address(this).balance - house_edge < win_amount) {
                    win_amount = (address(this).balance-house_edge) * 50 / 100;
                }

                jackpot = jackpot - win_amount;

                 
                last_winner = msg.sender;
                last_win_wei = win_amount;
                total_wins_count = total_wins_count + 1;
                total_wins_wei = total_wins_wei + win_amount;

                 
                msg.sender.transfer(win_amount);
            }

            return;
        }
    }

    function getBalance() constant public returns (uint256) {
        return address(this).balance;
    }

    function getTotalTickets() constant public returns (uint256) {
        return entry_number;
    }

    function getLastWin() constant public returns (uint256) {
        return last_win_wei;
    }

    function getLastWinner() constant public returns (address) {
        return last_winner;
    }

    function getTotalWins() constant public returns (uint256) {
        return total_wins_wei;
    }

    function getTotalWinsCount() constant public returns (uint256) {
        return total_wins_count;
    }

     
    function stopGame() public onlyOwner {
        game_alive = false;
        return;
    }

    function startGame() public onlyOwner {
        game_alive = true;
        return;
    }

    function transferHouseEdge(uint amount) public onlyOwner payable {
        require(amount <= house_edge);
        require((address(this).balance - amount) > 0);

        owner.transfer(amount);
        house_edge = house_edge - amount;
    }
}