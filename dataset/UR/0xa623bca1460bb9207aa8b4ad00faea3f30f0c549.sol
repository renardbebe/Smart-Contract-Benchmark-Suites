 

contract CSGOBets {

        struct Bets {
                address etherAddress;
                uint amount;
        }

        Bets[] public voteA;
        Bets[] public voteB;
        uint public balanceA = 0;  
        uint public balanceB = 0;  
        uint8 public house_edge = 6;  
        uint public betLockTime = 0;  
        uint public lastTransactionRec = 0;  
        address public owner;

        modifier onlyowner {
                if (msg.sender == owner) _
        }

        function CSGOBets() {
                owner = msg.sender;
                lastTransactionRec = block.number;
        }

        function() {
                enter();
        }

        function enter() {
                 
                 
                if (msg.value < 250 finney ||
                        (block.number >= betLockTime && betLockTime != 0 && block.number < betLockTime + 161280)) {
                        msg.sender.send(msg.value);
                        return;
                }

                uint amount;
                 
                if (msg.value > 100 ether) {
                        msg.sender.send(msg.value - 100 ether);
                        amount = 100 ether;
                } else {
                        amount = msg.value;
                }

                if (lastTransactionRec + 161280 < block.number) {  
                        returnAll();
                        betLockTime = block.number;
                        lastTransactionRec = block.number;
                        msg.sender.send(msg.value);
                        return;
                }
                lastTransactionRec = block.number;

                uint cidx;
                 
                if ((amount / 1000000000000000) % 2 == 0) {
                        balanceA += amount;
                        cidx = voteA.length;
                        voteA.length += 1;
                        voteA[cidx].etherAddress = msg.sender;
                        voteA[cidx].amount = amount;
                } else {
                        balanceB += amount;
                        cidx = voteB.length;
                        voteB.length += 1;
                        voteB[cidx].etherAddress = msg.sender;
                        voteB[cidx].amount = amount;
                }
        }

         
        function lockBet(uint blocknumber) onlyowner {
                betLockTime = blocknumber;
        }

         
        function payout(uint winner) onlyowner {
                var winPot = (winner == 0) ? balanceA : balanceB;
                var losePot_ = (winner == 0) ? balanceB : balanceA;
                uint losePot = losePot_ * (100 - house_edge) / 100;  
                uint collectedFees = losePot_ * house_edge / 100;
                var winners = (winner == 0) ? voteA : voteB;
                for (uint idx = 0; idx < winners.length; idx += 1) {
                        uint winAmount = winners[idx].amount + (winners[idx].amount * losePot / winPot);
                        winners[idx].etherAddress.send(winAmount);
                }

                 
                if (collectedFees != 0) {
                        owner.send(collectedFees);
                }
                clear();
        }

         
         
        function returnAll() onlyowner {
                for (uint idx = 0; idx < voteA.length; idx += 1) {
                        voteA[idx].etherAddress.send(voteA[idx].amount);
                }
                for (uint idxB = 0; idxB < voteB.length; idxB += 1) {
                        voteB[idxB].etherAddress.send(voteB[idxB].amount);
                }
                clear();
        }

        function clear() private {
                balanceA = 0;
                balanceB = 0;
                betLockTime = 0;
                lastTransactionRec = block.number;
                delete voteA;
                delete voteB;
        }

        function changeHouseedge(uint8 cut) onlyowner {
                 
                if (cut <= 20 && cut > 0)
                        house_edge = cut;
        }

        function setOwner(address _owner) onlyowner {
                owner = _owner;
        }

}