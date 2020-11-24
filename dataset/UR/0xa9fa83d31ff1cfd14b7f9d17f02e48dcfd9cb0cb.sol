 

pragma solidity ^0.4.9;

 

contract ProtectTheCastle {
     
    address public jester;
     
    uint public lastReparation;
     
    uint public piggyBank;

     
    uint public collectedFee;

     
    address[] public citizensAddresses;
    uint[] public citizensAmounts;
    uint32 public totalCitizens;
    uint32 public lastCitizenPaid;
     
    address public bribedCitizen;
     
    uint32 public round;
     
    uint public amountAlreadyPaidBack;
     
    uint public amountInvested;

    uint constant SIX_HOURS = 60 * 60 * 6;

    function ProtectTheCastle() {
         
        bribedCitizen = msg.sender;
        jester = msg.sender;
        lastReparation = block.timestamp;
        amountAlreadyPaidBack = 0;
        amountInvested = 0;
        totalCitizens = 0;
    }

    function repairTheCastle() payable returns(bool) {
        uint amount = msg.value;
         
        if (amount < 10 finney) {
            msg.sender.send(msg.value);
            return false;
        }
         
        if (amount > 100 ether) {
            msg.sender.send(msg.value - 100 ether);
            amount = 100 ether;
        }

         
        if (lastReparation + SIX_HOURS < block.timestamp) {
             
             
            if (totalCitizens == 1) {
                 
                citizensAddresses[citizensAddresses.length - 1].send(piggyBank);
            } else if (totalCitizens == 2) {
                 
                citizensAddresses[citizensAddresses.length - 1].send(piggyBank * 65 / 100);
                citizensAddresses[citizensAddresses.length - 2].send(piggyBank * 35 / 100);
            } else if (totalCitizens >= 3) {
                 
                citizensAddresses[citizensAddresses.length - 1].send(piggyBank * 55 / 100);
                citizensAddresses[citizensAddresses.length - 2].send(piggyBank * 30 / 100);
                citizensAddresses[citizensAddresses.length - 3].send(piggyBank * 15 / 100);
            }

             
            piggyBank = 0;

             
            jester = msg.sender;
            lastReparation = block.timestamp;
            citizensAddresses.push(msg.sender);
            citizensAmounts.push(amount * 2);
            totalCitizens += 1;
            amountInvested += amount;

             
            piggyBank += amount;

             
            jester.send(amount * 3 / 100);

             
            collectedFee += amount * 3 / 100;

            round += 1;
        } else {
             
            lastReparation = block.timestamp;
            citizensAddresses.push(msg.sender);
            citizensAmounts.push(amount * 2);
            totalCitizens += 1;
            amountInvested += amount;

             
            piggyBank += (amount * 5 / 100);

             
            jester.send(amount * 3 / 100);

             
            collectedFee += amount * 3 / 100;

            while (citizensAmounts[lastCitizenPaid] < (address(this).balance - piggyBank - collectedFee) && lastCitizenPaid <= totalCitizens) {
                citizensAddresses[lastCitizenPaid].send(citizensAmounts[lastCitizenPaid]);
                amountAlreadyPaidBack += citizensAmounts[lastCitizenPaid];
                lastCitizenPaid += 1;
            }
        }
    }

     
    function() payable {
        repairTheCastle();
    }

     
    function newBribedCitizen(address newBribedCitizen) {
        if (msg.sender == bribedCitizen) {
            bribedCitizen = newBribedCitizen;
        }
    }

     
    function collectFee() payable {
        if (msg.sender == bribedCitizen) {
            bribedCitizen.send(collectedFee);
        }
    }

     
    function newJester(address newJester) {
        if (msg.sender == jester) {
            jester = newJester;
        }
    }       
}