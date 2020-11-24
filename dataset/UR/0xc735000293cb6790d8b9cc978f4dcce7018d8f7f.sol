 

pragma solidity 0.5.0;

 

 
 
interface HourglassInterface {
     
    function buy(address _playerAddress) external payable returns(uint256);
     
    function withdraw() external;
     
    function dividendsOf(address _playerAddress) external view returns(uint256);
     
    function balanceOf(address _playerAddress) external view returns(uint256);
}


contract Countdown3D {

     
    HourglassInterface internal hourglass;

     
     
    event OnBuy(address indexed _playerAddress, uint indexed _roundId, uint _tickets, uint _value);
     
    event OnRoundCap(uint _roundId);
     
    event OnRoundStart(uint _roundId);

     
     
    uint256 constant public COOLDOWN = 7 days;

     
    uint256 constant public COST = 0.01 ether;

     
    uint256 constant public EXPIRATION = 5;

     
    uint256 constant public QUORUM = 21;

     
    uint256 constant public TICKET_MAX = 101;

     
    uint256 public currentRoundId;

     
    address private dev1;
    address private dev2;

     
    struct Round {
         
        uint256 balance;
         
        uint256 blockCap;
         
        uint256 claimed;
         
        uint256 pot;
         
        uint256 random;
         
        uint256 startTime;
         
        uint256 tickets;
         
        mapping (uint256 => uint256) caste;
         
        mapping (address => uint256) reward;
    }

    struct Account {
         
        uint256[] roundsActive;
         
        uint256[] rewards;
         
        mapping(uint256 => TicketSet[]) ticketSets;
         
        uint256 tickets;
    }

     
    struct TicketSet {
         
        uint256 start;
         
        uint256 end;
    }

     
    mapping (uint256 => Round) internal rounds;
     
    mapping (address => Account) internal accounts;

     
    constructor(address hourglassAddress, address dev1Address, address dev2Address) public {
         
        rounds[0].startTime = now + 7 days;
         
        hourglass = HourglassInterface(hourglassAddress);
         
        dev1 = dev1Address;
         
        dev2 = dev2Address;
    }
     

     
    function ()
        external
        payable
    {
         
        if (msg.sender != address(hourglass)) {
            donateToPot();
        }
    }

     
    function buy()
        public
        payable
    {
         
        (Round storage round, uint256 roundId) = getRoundInProgress();

         
        (uint256 tickets, uint256 change) = processTickets();

         
        round.pot = round.pot + change;

         
        if (tickets > 0) {
             
            pushTicketSetToAccount(roundId, tickets);
             
            round.tickets = round.tickets + tickets;
        }
         
        emit OnBuy(msg.sender, roundId, tickets, msg.value);
    }

     
    function donateToDivs()
        public
        payable
    {
         
        hourglass.buy.value(msg.value)(msg.sender);
    }

     
    function donateToPot()
        public
        payable
    {
        if (msg.value > 0) {
             
            (Round storage round,) = getRoundInProgress();
            round.pot = round.pot + msg.value;
        }
    }

     
    function validate()
        public
    {
         
        Round storage round = rounds[currentRoundId];

         
        require(round.random == 0);

         
        require(round.tickets >= QUORUM);

         
        require(round.startTime + COOLDOWN <= now);

         
        if (round.blockCap == 0) {
            allocateToPot(round);
            allocateFromPot(round);

             
            round.blockCap = block.number;
            emit OnRoundCap(currentRoundId);
        } else {
             
            require(block.number > round.blockCap);

             
            uint32 blockhash_ = uint32(bytes4(blockhash(round.blockCap)));

             
            if (blockhash_ != 0) {
                closeTheRound(round, blockhash_);
            } else {
                 
                round.blockCap = block.number;
                emit OnRoundCap(currentRoundId);
            }
        }
    }

     
    function withdraw()
        public
    {
         
        uint256 total;
         
        bool withholdRounds;
         
        Account storage account = accounts[msg.sender];
         
        uint256 accountRoundsActiveLength = account.roundsActive.length;

         
        for (uint256 i = 0; i < accountRoundsActiveLength; i++) {
            uint256 roundId = account.roundsActive[i];

             
            if (roundId < currentRoundId) {
                 
                (uint256 amount, uint256 totalTickets) = getRoundWinnings(msg.sender, roundId);

                 
                account.tickets = account.tickets - totalTickets;

                 
                delete account.ticketSets[roundId];

                 
                if (amount > 0) {
                     
                    rounds[roundId].claimed = rounds[roundId].claimed + amount;
                     
                    total = total + amount;
                }
            } else {
                 
                withholdRounds = true;
            }
        }

         
        sweepRoundsActive(withholdRounds);

         
        if (total > 0) {
            msg.sender.transfer(total);
        }
    }

     
    function claimRewards()
        public
    {
         
        uint256 total;
         
        Account storage account = accounts[msg.sender];
         
        uint256 accountRewardsLength = account.rewards.length;

         
        for (uint256 i = 0; i < accountRewardsLength; i++) {
             
            uint256 roundId = account.rewards[i];
             
            uint256 amount = getRewardWinnings(msg.sender, roundId);
             
            delete rounds[roundId].reward[msg.sender];

             
            if (amount > 0) {
                 
                rounds[roundId].claimed = rounds[roundId].claimed + amount;
                 
                total = total + amount;
            }
        }

         
        delete accounts[msg.sender].rewards;

         
        if (total > 0) {
            msg.sender.transfer(total);
        }
    }

     
     
    function getConfig()
        public
        pure
        returns(uint256 cooldown, uint256 cost, uint256 expiration, uint256 quorum, uint256 ticketMax)
    {
        return(COOLDOWN, COST, EXPIRATION, QUORUM, TICKET_MAX);
    }

     
    function getRound(uint256 roundId)
        public
        view
        returns(
            uint256 balance, 
            uint256 blockCap, 
            uint256 claimed, 
            uint256 pot, 
            uint256 random, 
            uint256 startTime, 
            uint256 tickets)
    {
        Round storage round = rounds[roundId];

        return(round.balance, round.blockCap, round.claimed, round.pot, round.random, round.startTime, round.tickets);
    }

     
    function getTotalTickets(address accountAddress)
        public
        view
        returns(uint256 tickets)
    {
        return accounts[accountAddress].tickets;
    }

     
    function getRoundCasteValues(uint256 roundId)
        public
        view
        returns(uint256 caste0, uint256 caste1, uint256 caste2)
    {
        return(rounds[roundId].caste[0], rounds[roundId].caste[1], rounds[roundId].caste[2]);
    }

     
    function getRoundsActive(address accountAddress)
        public
        view
        returns(uint256[] memory)
    {
        return accounts[accountAddress].roundsActive;
    }

     
    function getRewards(address accountAddress)
        public
        view
        returns(uint256[] memory)
    {
        return accounts[accountAddress].rewards;
    }

     
    function getTotalTicketSetsForRound(address accountAddress, uint256 roundId)
        public
        view
        returns(uint256 ticketSets)
    {
        return accounts[accountAddress].ticketSets[roundId].length;
    }

     
    function getTicketSet(address accountAddress, uint256 roundId, uint256 index)
        public
        view
        returns(uint256 start, uint256 end)
    {
        TicketSet storage ticketSet = accounts[accountAddress].ticketSets[roundId][index];

         
        return (ticketSet.start, ticketSet.end);
    }

     
    function getTicketValue(uint256 roundId, uint256 ticketIndex)
        public
        view
        returns(uint256 ticketValue)
    {
         
        if (currentRoundId > roundId && (currentRoundId - roundId) >= EXPIRATION) {
            return 0;
        }

        Round storage round = rounds[roundId];
         
        uint256 tier = getTier(roundId, ticketIndex);

         
        if (tier == 5) {
            return 0;
        } else if (tier == 4) {
            return COST / 2;
        } else if (tier == 3) {
            return COST;
        } else {
            return round.caste[tier];
        }
    }

     
    function getTier(uint256 roundId, uint256 ticketIndex)
        public
        view
        returns(uint256 tier)
    {
        Round storage round = rounds[roundId];
         
        uint256 distance = Math.distance(round.random, ticketIndex, round.tickets);
         
        uint256 ticketTier = Caste.tier(distance, round.tickets - 1);

        return ticketTier;
    }

     
    function getRoundWinnings(address accountAddress, uint256 roundId)
        public
        view
        returns(uint256 totalWinnings, uint256 totalTickets)
    {
         
        Account storage account = accounts[accountAddress];
         
        TicketSet[] storage ticketSets = account.ticketSets[roundId];

         
        uint256 total;
         
        uint256 ticketSetLength = ticketSets.length;
         
        uint256 totalTicketsInRound;

         
        if (currentRoundId > roundId && (currentRoundId - roundId) >= EXPIRATION) {
             
             
            for (uint256 i = 0; i < ticketSetLength; i++) {
                 
                uint256 totalTicketsInSet = (ticketSets[i].end - ticketSets[i].start) + 1;
                 
                totalTicketsInRound = totalTicketsInRound + totalTicketsInSet;
            }

             
            return (total, totalTicketsInRound);
        }

         
        for (uint256 i = 0; i < ticketSetLength; i++) {
             
            uint256 startIndex = ticketSets[i].start - 1;
            uint256 endIndex = ticketSets[i].end - 1;
             
            for (uint256 j = startIndex; j <= endIndex; j++) {
                 
                total = total + getTicketWinnings(roundId, j);
            }
             
            uint256 totalTicketsInSet = (ticketSets[i].end - ticketSets[i].start) + 1;
             
            totalTicketsInRound = totalTicketsInRound + totalTicketsInSet;
        }
         
        return (total, totalTicketsInRound);
    }

     
    function getRewardWinnings(address accountAddress, uint256 roundId)
        public
        view
        returns(uint256 reward)
    {
         
        if (currentRoundId > roundId && (currentRoundId - roundId) >= EXPIRATION) {
             
            return 0;
        }
         
        return rounds[roundId].reward[accountAddress];
    }

     
    function getDividends()
        public
        view
        returns(uint256 dividends)
    {
        return hourglass.dividendsOf(address(this));
    }

     
    function getHourglassBalance()
        public
        view
        returns(uint256 hourglassBalance)
    {
        return hourglass.balanceOf(address(this));
    }

     
     
    function allocateFromPot(Round storage round)
        private
    {
         
        (round.caste[0], round.caste[1], round.caste[2]) = Caste.values((round.tickets - 1), round.pot, COST);

         
        rounds[currentRoundId + 1].pot = (round.pot * 15) / 100;

         
        uint256 percent2 = (round.pot * 2) / 100;
        round.reward[dev1] = percent2;
        round.reward[dev2] = percent2;

         
        if (accounts[dev1].rewards.length == TICKET_MAX) {
            delete accounts[dev1].rewards;
        }
        if (accounts[dev2].rewards.length == TICKET_MAX) {
            delete accounts[dev2].rewards;
        }
         
        accounts[dev1].rewards.push(currentRoundId);
        accounts[dev2].rewards.push(currentRoundId);

         
        hourglass.buy.value((round.pot * 5) / 100)(msg.sender);

         
        round.claimed = (round.pot * 20) / 100;
    }

     
    function allocateToPot(Round storage round)
        private
    {
         
        round.balance = round.pot + (round.tickets * COST);

         
        round.pot = round.pot + Caste.pool(round.tickets - 1, COST);

         
        uint256 dividends = getDividends();
         
        if (dividends > 0) {
             
            hourglass.withdraw();
             
            round.pot = round.pot + dividends;
        }
    }

     
    function closeTheRound(Round storage round, uint32 blockhash_)
        private
    {
         
        require(round.reward[msg.sender] == 0);
         
        round.reward[msg.sender] = round.pot / 100;
         
        if (accounts[msg.sender].rewards.length == TICKET_MAX) {
            delete accounts[msg.sender].rewards;
        }

         
        accounts[msg.sender].rewards.push(currentRoundId);

         
        round.random = Math.random(blockhash_, round.tickets);

         
        currentRoundId = currentRoundId + 1;

         
        Round storage newRound = rounds[currentRoundId];

         
        newRound.startTime = now;

         
        if (currentRoundId >= EXPIRATION) {
             
            Round storage expired = rounds[currentRoundId - EXPIRATION];
             
            if (expired.balance > expired.claimed) {
                 
                newRound.pot = newRound.pot + (expired.balance - expired.claimed);
            }
        }

         
        emit OnRoundStart(currentRoundId);
    }

     
    function getRoundInProgress()
        private
        view
        returns(Round storage, uint256 roundId)
    {
         
        if (rounds[currentRoundId].blockCap == 0) {
            return (rounds[currentRoundId], currentRoundId);
        }
         
        return (rounds[currentRoundId + 1], currentRoundId + 1);
    }

     
    function getTicketWinnings(uint256 roundId, uint256 index)
        private
        view
        returns(uint256 ticketValue)
    {
        Round storage round = rounds[roundId];
         
        uint256 tier = getTier(roundId, index);

         
        if (tier == 5) {
            return 0;
        } else if (tier == 4) {
            return COST / 2;
        } else if (tier == 3) {
            return COST;
        } else {
            return round.caste[tier];
        }
    }

     
    function processTickets()
        private
        view
        returns(uint256 totalTickets, uint256 totalRemainder)
    {
         
        uint256 tickets = Math.divide(msg.value, COST);
         
        uint256 remainder = Math.remainder(msg.value, COST);

        return (tickets, remainder);
    }

     
    function pushTicketSetToAccount(uint256 roundId, uint256 tickets)
        private
    {
         
        Account storage account = accounts[msg.sender];
         
        Round storage round = rounds[roundId];

         
        if (account.ticketSets[roundId].length == 0) {
            account.roundsActive.push(roundId);
        }

         
         
        require((account.tickets + tickets) < TICKET_MAX);
        account.tickets = account.tickets + tickets;

         
        account.ticketSets[roundId].push(TicketSet(round.tickets + 1, round.tickets + tickets));
    }

     
    function sweepRoundsActive(bool withholdRounds)
        private
    {
         
        if (withholdRounds != true) {
             
            delete accounts[msg.sender].roundsActive;
        } else {
            bool current;
            bool next;
             
            uint256 roundActiveLength = accounts[msg.sender].roundsActive.length;

             
            for (uint256 i = 0; i < roundActiveLength; i++) {
                uint256 roundId = accounts[msg.sender].roundsActive[i];

                 
                if (roundId == currentRoundId) {
                    current = true;
                }
                 
                if (roundId > currentRoundId) {
                    next = true;
                }
            }

             
            delete accounts[msg.sender].roundsActive;

             
            if (current == true) {
                accounts[msg.sender].roundsActive.push(currentRoundId);
            }
             
            if (next == true) {
                accounts[msg.sender].roundsActive.push(currentRoundId + 1);
            }
        }
    }
}


 
library Math {
     
    function distance(uint256 start, uint256 finish, uint256 total)
        internal
        pure
        returns(uint256)
    {
        if (start < finish) {
            return finish - start;
        }
        if (start > finish) {
            return (total - start) + finish;
        }
        if (start == finish) {
            return 0;
        }
    }

     
    function divide(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
         
        return numerator / denominator;
    }

     
    function random(uint32 blockhash_, uint256 max)
        internal
        pure
        returns(uint256)
    {
         
        uint256 encodedBlockhash = uint256(keccak256(abi.encodePacked(blockhash_)));
         
        return (encodedBlockhash % max);
    }

     
    function remainder(uint256 numerator, uint256 denominator)
        internal
        pure
        returns (uint256)
    {
         
        return numerator % denominator;
    }
}


 
library Caste {

     
    function pool(uint256 total, uint256 cost)
        internal
        pure
        returns(uint256)
    {
        uint256 tier4 = ((total * 70) / 100) - ((total * 45) / 100);
        uint256 tier5 = total - ((total * 70) / 100);

        return (tier5 * cost) + ((tier4 * cost) / 2);
    }

     
    function tier(uint256 distance, uint256 total)
        internal
        pure
        returns(uint256)
    {
        uint256 percent = (distance * (10**18)) / total;

        if (percent > 700000000000000000) {
            return 5;
        }
        if (percent > 450000000000000000) {
            return 4;
        }
        if (percent > 250000000000000000) {
            return 3;
        }
        if (percent > 100000000000000000) {
            return 2;
        }
        if (percent > 0) {
            return 1;
        }
        if (distance == 0) {
            return 0;
        } else {
            return 1;
        }
    }

     
    function values(uint256 total, uint256 pot, uint256 cost)
        internal
        pure
        returns(uint256, uint256, uint256)
    {
        uint256 percent10 = (total * 10) / 100;
        uint256 percent25 = (total * 25) / 100;
        uint256 caste0 = (pot * 25) / 100;
        uint256 caste1 = cost + (caste0 / percent10);
        uint256 caste2 = cost + (caste0 / (percent25 - percent10));

        return (caste0 + cost, caste1, caste2);
    }
}