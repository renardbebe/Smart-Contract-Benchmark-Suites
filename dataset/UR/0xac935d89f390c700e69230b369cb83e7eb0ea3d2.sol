 

pragma solidity ^0.4.18;
 
 
 
contract LifetimeLottery {
   
    uint internal constant MIN_SEND_VAL = 5000000000000000;  
    uint internal constant JACKPOT_INC = 2000000000000000;  
    uint internal constant JACKPOT_CHANCE = 2;  
   
    uint internal nonce;
    uint internal random;  
    uint internal jackpot;  
    uint internal jackpotNumber;  
   
    address[] internal lotteryList;  
    address internal lastWinner;
    address internal lastJackpotWinner;
   
    mapping(address => bool) addressMapping;  
    event LotteryLog(address adrs, string message);
   
    function LifetimeLottery() public {
        nonce = (uint(msg.sender) + block.timestamp) % 100;
    }
     
    function () public payable {
        LotteryLog(msg.sender, "Received new funds...");
        if(msg.value >= MIN_SEND_VAL) {
            if(addressMapping[msg.sender] == false) {  
                addressMapping[msg.sender] = true;
                lotteryList.push(msg.sender);
                nonce++;
                random = uint(keccak256(block.timestamp + block.number + uint(msg.sender) + nonce)) % lotteryList.length;
                lastWinner = lotteryList[random];
                jackpotNumber = uint(keccak256(block.timestamp + block.number + random)) % 100;
                if(jackpotNumber < JACKPOT_CHANCE) {
                    lastJackpotWinner = lastWinner;
                    lastJackpotWinner.transfer(msg.value + jackpot);
                    jackpot = 0;
                    LotteryLog(lastJackpotWinner, "Jackpot is hit!");
                } else {
                    jackpot += JACKPOT_INC;
                    lastWinner.transfer(msg.value - JACKPOT_INC);
                    LotteryLog(lastWinner, "We have a Winner!");
                }
            } else {
                msg.sender.transfer(msg.value);
                LotteryLog(msg.sender, "Failed: already joined! Sending back received ether...");
            }
        } else {
            msg.sender.transfer(msg.value);
            LotteryLog(msg.sender, "Failed: not enough Ether sent! Sending back received ether...");
        }
    }
   
    function amountOfRegisters() public constant returns(uint) {
        return lotteryList.length;
    }
   
    function currentJackpotInWei() public constant returns(uint) {
        return jackpot;
    }
   
    function ourLastWinner() public constant returns(address) {
        return lastWinner;
    }
   
    function ourLastJackpotWinner() public constant returns(address) {
        return lastJackpotWinner;
    }
   
 
}