 

contract ShinySquirrels {

 
uint private minDeposit = 10 finney;
uint private maxDeposit = 5 ether;
uint private baseFee = 5;
uint private baseMultiplier = 100;
uint private maxMultiplier = 160;
uint private currentPosition = 0;
uint private balance = 0;
uint private feeBalance = 0;
uint private totalDeposits = 0;
uint private totalPaid = 0;
uint private totalSquirrels = 0;
uint private totalShinyThings = 0;
uint private totalSprockets = 0;
uint private totalStars = 0;
uint private totalHearts = 0;
uint private totalSkips = 0;
address private owner = msg.sender;
 
struct PlayerEntry {
    address addr;
    uint deposit;
    uint paid;
    uint multiplier;
    uint fee;
    uint skip;
    uint squirrels;
    uint shinyThings;
    uint sprockets;
    uint stars;
    uint hearts;
}
 
struct PlayerStat {
    address addr;
    uint entries;
    uint deposits;
    uint paid;
    uint skips;
    uint squirrels;
    uint shinyThings;
    uint sprockets;
    uint stars;
    uint hearts;
}

 
PlayerEntry[] private players;

 
uint[] theLine;

 
mapping(address => PlayerStat) private playerStats;

 
function ShinySquirrels() {
    owner = msg.sender;
}
 
function totals() constant returns(uint playerCount, uint currentPlaceInLine, uint playersWaiting, uint totalDepositsInFinneys, uint totalPaidOutInFinneys, uint squirrelFriends, uint shinyThingsFound, uint sprocketsCollected, uint starsWon, uint heartsEarned, uint balanceInFinneys, uint feeBalanceInFinneys) {
    playerCount             = players.length;
    currentPlaceInLine      = currentPosition;
    playersWaiting          = waitingForPayout();
    totalDepositsInFinneys  = totalDeposits / 1 finney;
    totalPaidOutInFinneys   = totalPaid / 1 finney;
    squirrelFriends         = totalSquirrels;
    shinyThingsFound        = totalShinyThings;
    sprocketsCollected      = totalSprockets;
    starsWon                = totalStars;
    heartsEarned            = totalHearts;
    balanceInFinneys        = balance / 1 finney;
    feeBalanceInFinneys     = feeBalance / 1 finney;
}

function settings() constant returns(uint minimumDepositInFinneys, uint maximumDepositInFinneys) {
    minimumDepositInFinneys = minDeposit / 1 finney;
    maximumDepositInFinneys = maxDeposit / 1 finney;
}

function playerByAddress(address addr) constant returns(uint entries, uint depositedInFinney, uint paidOutInFinney, uint skippedAhead, uint squirrels, uint shinyThings, uint sprockets, uint stars, uint hearts) {
    entries          = playerStats[addr].entries;
    depositedInFinney = playerStats[addr].deposits / 1 finney;
    paidOutInFinney  = playerStats[addr].paid / 1 finney;
    skippedAhead     = playerStats[addr].skips;
    squirrels        = playerStats[addr].squirrels;
    shinyThings      = playerStats[addr].shinyThings;
    sprockets        = playerStats[addr].sprockets;
    stars            = playerStats[addr].stars;
    hearts           = playerStats[addr].hearts;
}

 
function waitingForPayout() constant private returns(uint waiting) {
    waiting = players.length - currentPosition;
}

 
function entryPayout(uint index) constant private returns(uint payout) {
    payout = players[theLine[index]].deposit * players[theLine[index]].multiplier / 100;
}

 
function entryPayoutDue(uint index) constant private returns(uint payoutDue) {
     
    payoutDue = entryPayout(index) - players[theLine[index]].paid;
}
 
 
function lineOfPlayers(uint index) constant returns (address addr, uint orderJoined, uint depositInFinney, uint payoutInFinney, uint multiplierPercent, uint paid, uint skippedAhead, uint squirrels, uint shinyThings, uint sprockets, uint stars, uint hearts) {
    PlayerEntry player = players[theLine[index]];
    addr              = player.addr;
    orderJoined       = theLine[index];
    depositInFinney   = player.deposit / 1 finney;
    payoutInFinney    = depositInFinney * player.multiplier / 100;
    multiplierPercent = player.multiplier;
    paid              = player.paid / 1 finney;
    skippedAhead      = player.skip;
    squirrels         = player.squirrels;
    shinyThings       = player.shinyThings;
    sprockets         = player.sprockets;
    stars             = player.stars;
    hearts            = player.hearts;
}

function () {
    play();
}
 
function play() {
    uint deposit = msg.value;  
     
     
    if(deposit < minDeposit || deposit > maxDeposit) {
        msg.sender.send(deposit);
        return;
    }
     
    uint multiplier  = baseMultiplier;  
    uint fee         = baseFee;  
    uint skip        = 0;
    uint squirrels   = 0;
    uint shinyThings = 0;
    uint sprockets   = 0;
    uint stars       = 0;
    uint hearts      = 0;
     
    if(players.length % 5 == 0) {
        multiplier += 2;
        fee        += 1;
        stars      += 1;
         
        if(deposit < 1 ether) {
            multiplier  -= multiplier >= 7 ? 7 : multiplier;
            fee         -= fee        >= 1 ? 1 : 0;
            shinyThings += 1;
        }
        if(deposit >= 1 && waitingForPayout() >= 10) {
             
            skip += 4;
            fee  += 3;
        }
        if(deposit >= 2 ether && deposit <= 3 ether) {
            multiplier += 3;
            fee        += 2;
            hearts     += 1;
        }
        if(deposit >= 3 ether) {
            stars += 1;
        }

    } else if (players.length % 5 == 1) {
        multiplier += 4;
        fee        += 2;
        squirrels  += 1;

        if(deposit < 1 ether) {
            multiplier += 6;
            fee        += 3;
            squirrels  += 1;
        }
        if(deposit >= 2 ether) {
            if(waitingForPayout() >= 20) {
                 
                skip        += waitingForPayout() / 2;  
                fee         += 2;
                shinyThings += 1;
            } 

            multiplier += 4;
            fee        += 4;
            hearts     += 1;
        }
        if(deposit >= 4 ether) {
            multiplier += 1;
            fee       -= fee >= 1 ? 1 : 0;
            skip      += 1;
            hearts    += 1;
            stars     += 1;
        }

    } else if (players.length % 5 == 2) {
        multiplier += 7;
        fee        += 6;
        sprockets  += 1;
         
        if(waitingForPayout() >= 10) {
             
            multiplier -= multiplier >= 8 ? 8 : multiplier;
            fee        -= fee >= 1 ? 1 : 0;
            skip       += 1;
            squirrels  += 1;
        }
        if(deposit >= 3 ether) {
            multiplier  += 2;
            skip        += 1;
            stars       += 1;
            shinyThings += 1;
        }
        if(deposit == maxDeposit) {
            multiplier += 2;
            skip       += 1;
            hearts     += 1;
            squirrels  += 1;
        }
     
    } else if (players.length % 5 == 3) {
        multiplier  -= multiplier >= 5 ? 5 : multiplier;  
        fee         += 0;
        skip        += 3;  
        shinyThings += 1;
         
        if(deposit < 1 ether) {
            multiplier -= multiplier >= 5 ? 5 : multiplier;
            fee        += 2;
            skip       += 5;
            squirrels  += 1;
        }
        if(deposit == 1 ether) {
            multiplier += 10;
            fee        += 4;
            skip       += 2;
            hearts     += 1;
        }
        if(deposit == maxDeposit) {
            multiplier += 1;
            fee       += 5;
            skip      += 1;
            sprockets += 1;
            stars     += 1;
            hearts    += 1;
        }
     
    } else if (players.length % 5 == 4) {
        multiplier += 2;
        fee        -= fee >= 1 ? 1 : fee;
        squirrels  += 1;
         
        if(deposit < 1 ether) {
            multiplier += 3;
            fee        += 2;
            skip       += 3;
        }
        if(deposit >= 2 ether) {
            multiplier += 2;
            fee        += 2;
            skip       += 1;
            stars      += 1;
        }
        if(deposit == maxDeposit/2) {
            multiplier  += 2;
            fee         += 5;
            skip        += 3;
            shinyThings += 1;
            sprockets   += 1;
        }
        if(deposit >= 3 ether) {
            multiplier += 1;
            fee        += 1;
            skip       += 1;
            sprockets  += 1;
            hearts     += 1;
        }
    }

     
    playerStats[msg.sender].hearts      += hearts;
    playerStats[msg.sender].stars       += stars;
    playerStats[msg.sender].squirrels   += squirrels;
    playerStats[msg.sender].shinyThings += shinyThings;
    playerStats[msg.sender].sprockets   += sprockets;
    
     
    totalHearts      += hearts;
    totalStars       += stars;
    totalSquirrels   += squirrels;
    totalShinyThings += shinyThings;
    totalSprockets   += sprockets;

     
    skip += playerStats[msg.sender].squirrels;
     
     
    playerStats[msg.sender].squirrels -= playerStats[msg.sender].squirrels >= 1 ? 1 : 0;
     
     
    multiplier += playerStats[msg.sender].stars * 2;
     
     
    fee -= playerStats[msg.sender].hearts;
     
     
    multiplier += playerStats[msg.sender].sprockets;
    fee        -= fee > playerStats[msg.sender].sprockets ? playerStats[msg.sender].sprockets : fee;
     
     
    if(playerStats[msg.sender].shinyThings >= 1) {
        skip += 1;
        fee  -= fee >= 1 ? 1 : 0;
    }
     
     
    if(playerStats[msg.sender].hearts >= 1 && playerStats[msg.sender].stars >= 1 && playerStats[msg.sender].squirrels >= 1 && playerStats[msg.sender].shinyThings >= 1 && playerStats[msg.sender].sprockets >= 1) {
        multiplier += 30;
    }
     
     
    if(playerStats[msg.sender].hearts >= 1 && playerStats[msg.sender].stars >= 1) {
        multiplier                     += 15;
        playerStats[msg.sender].hearts -= 1;
        playerStats[msg.sender].stars  -= 1;
    }
     
     
    if(playerStats[msg.sender].sprockets >= 1 && playerStats[msg.sender].shinyThings >= 1) {
        playerStats[msg.sender].squirrels   += 5;
        playerStats[msg.sender].sprockets   -= 1;
        playerStats[msg.sender].shinyThings -= 1;
    }

     
    if(multiplier > maxMultiplier) {
        multiplier == maxMultiplier;
    }
    
     
    if(waitingForPayout() > 15 && skip > waitingForPayout()/2) {
         
        skip = waitingForPayout() / 2;
    }

     
    feeBalance += deposit * fee / 100;
    balance    += deposit - deposit * fee / 100;
    totalDeposits += deposit;

     
    uint playerIndex = players.length;
    players.length += 1;

     
    uint lineIndex = theLine.length;
    theLine.length += 1;

     
    (skip, lineIndex) = skipInLine(skip, lineIndex);

     
    players[playerIndex].addr        = msg.sender;
    players[playerIndex].deposit     = deposit;
    players[playerIndex].multiplier  = multiplier;
    players[playerIndex].fee         = fee;
    players[playerIndex].squirrels   = squirrels;
    players[playerIndex].shinyThings = shinyThings;
    players[playerIndex].sprockets   = sprockets;
    players[playerIndex].stars       = stars;
    players[playerIndex].hearts      = hearts;
    players[playerIndex].skip        = skip;
    
     
    theLine[lineIndex] = playerIndex;

     
    playerStats[msg.sender].entries  += 1;
    playerStats[msg.sender].deposits += deposit;
    playerStats[msg.sender].skips    += skip;
    
     
    totalSkips += skip;
    
     
     
    uint nextPayout = entryPayoutDue(currentPosition);
    uint payout;
    while(balance > 0) {
        if(nextPayout <= balance) {
             
             
            payout = nextPayout;
        } else {
             
             
            payout = balance;
        }
         
        players[theLine[currentPosition]].addr.send(payout);
         
        players[theLine[currentPosition]].paid += payout;
         
        playerStats[players[theLine[currentPosition]].addr].paid += payout;
        balance    -= payout;
        totalPaid  += payout;
         
        if(balance > 0) {
            currentPosition++;
            nextPayout = entryPayoutDue(currentPosition);
        }
    }
}
 
 
 
 
function skipInLine(uint skip, uint currentLineIndex) private returns (uint skipped, uint newLineIndex) {
     
    if(skip > 0 && waitingForPayout() > 2) {
         
        if(skip > waitingForPayout()-2) {
            skip = waitingForPayout()-2;
        }

         
        uint i = 0;
        while(i < skip) {
            theLine[currentLineIndex-i] = theLine[currentLineIndex-1-i];
            i++;
        }
        
         
        delete(theLine[currentLineIndex-i]);
        
         
        newLineIndex = currentLineIndex-i;
    } else {
         
        newLineIndex = currentLineIndex;
        skip = 0;
    }
    skipped = skip;
}

function DynamicPyramid() {
     
    playerStats[msg.sender].squirrels    = 0;
    playerStats[msg.sender].shinyThings  = 0;
    playerStats[msg.sender].sprockets    = 0;
    playerStats[msg.sender].stars        = 0;
    playerStats[msg.sender].hearts       = 0;
}
 
function collectFees() {
    if(msg.sender != owner) {
        throw;
    }
     
    if(address(this).balance > balance + feeBalance) {
         
        feeBalance = address(this).balance - balance;
    }
    owner.send(feeBalance);
    feeBalance = 0;
}

function updateSettings(uint newMultiplier, uint newMaxMultiplier, uint newFee, uint newMinDeposit, uint newMaxDeposit, bool collect) {
     
    if(msg.sender != owner) throw;
    if(newMultiplier < 80 || newMultiplier > 120) throw;
    if(maxMultiplier < 125 || maxMultiplier > 200) throw;
    if(newFee < 0 || newFee > 15) throw;
    if(minDeposit < 1 finney || minDeposit > 1 ether) throw;
    if(maxDeposit < 1 finney || maxDeposit > 25 ether) throw;
    if(collect) collectFees();
    baseMultiplier = newMultiplier;
    maxMultiplier = newMaxMultiplier;
    baseFee = newFee;
    minDeposit = newMinDeposit;
    maxDeposit = newMaxDeposit;
}


}