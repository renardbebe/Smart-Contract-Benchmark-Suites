 

pragma solidity ^0.4.19;

contract BitOpterations {
            
         
         
         
        
        function set512(bytes32[2] storage allocator,uint16 pos,uint8 value) internal returns( bytes32[2] storage) {
            
            bytes32 valueBits = (bytes32)(value);
        
            uint8 posOffset = uint8(pos%255);
        
            bytes32 one = 1;
            bytes32 clearBit = (bytes32)(~(one << posOffset));
            
            uint8 bytesIndex = pos>255?1:0;
            
            allocator[bytesIndex] = (allocator[bytesIndex] & clearBit) | (valueBits << posOffset);
            
            return allocator;
            
        }
            
        function get512(bytes32[2] allocator,uint16 pos) internal pure returns(uint8){
            
            uint8 posOffset = uint8(pos%255);
            uint8 bytesIndex = pos>255?1:0;
            
            return (((allocator[bytesIndex] >> posOffset) & 1) == 1)?1:0;   
        }    
        
        function clear512(bytes32[2] storage allocator) internal {
            allocator[0] = 0x0;
            allocator[1] = 0x0;
        }
        
        function set32(bytes4 allocator,uint8 pos, uint8 value) internal pure returns(bytes4) {
            
            bytes4 valueBits = (bytes4)(value);
        
            bytes4 one = 1;
            bytes4 clearBit = (bytes4)(~(one << pos));
            allocator = (allocator & clearBit) | (valueBits << pos);
            
            return allocator;
        }
        
        function get32(bytes4 allocator,uint8 pos) internal pure returns(uint8){
           return (((allocator >> pos) & 1) == 1)?1:0;
        }
}

contract Random32BigInteger is BitOpterations {
    
    uint256[10] public randomBlockStart;
    bytes4[10] private numberAllocator;
    bool[10] internal generated;
    
    uint256 private generationNumber = 0;
    
    function generate(uint8 lotteryId) internal returns(bool) {
        
         
         
        uint8 startOffset = uint8((generationNumber++) % 10); 
        
        if (randomBlockStart[lotteryId] == 0) {
             
             
             randomBlockStart[lotteryId] = block.number + startOffset;
        } else {
            uint256 blockDiffNumber = block.number - randomBlockStart[lotteryId];
            
             
            require(blockDiffNumber >= 32);
            
             
             
             
            if (blockDiffNumber > 256) {
                randomBlockStart[lotteryId] = block.number + startOffset;
            } else {
                for (uint8 i = 0; i < 32; i++) {
                    
                     
                    uint256 blockHash = uint256(block.blockhash(randomBlockStart[lotteryId]+i));
                    
                     
                    numberAllocator[lotteryId] = set32(numberAllocator[lotteryId],i,uint8(blockHash));
                }
                generated[lotteryId] = true;
                randomBlockStart[lotteryId] = 0;
            }
        }
        return generated[lotteryId];
    }
    
    function clearNumber(uint8 lotteryId) internal {
        randomBlockStart[lotteryId] = 0;
        generated[lotteryId] = false;
    }
    
    function getNumberValue(uint8 lotteryId) internal constant returns(uint32) {
        require(generated[lotteryId]);
        return uint32(numberAllocator[lotteryId]);
    }
}

contract EthereumJackpot is Random32BigInteger {
    
    address private owner;
    
    event WinnerPicked(uint8 indexed roomId,address winner,uint16 number);
    event TicketsBought(uint8 indexed roomId,address owner,uint16[] ticketNumbers);
    event LostPayment(address dest,uint256 amount);
    
    struct Winner {
        uint256 prize;
        uint256 timestamp;
        address addr;
        
        uint16 number;
        uint8 percent;
    }
    
    mapping (address => address) public affiliates;
    
    Winner[] private winners;
    
    uint32 public winnersCount;
    
    modifier ownerOnly {
        require(msg.sender == owner);
        _;
    }
    
    uint8 public affiliatePercent = 1;
    uint8 public maxPercentPerPlayer = 49;
    uint8 public ownerComission = 20;
    
     
    uint256[10] public started;
    
     
    uint256[10] public lastTicketBought;
    
     
    uint256[10] public ticketPrice;
    
     
    uint16[10] public maxTickets;
    
     
    uint256[10] public lifetime;
    
    address[][10] ticketsAllocator;
    
    struct Player {
        uint256 changedOn;
        uint16 ticketsCount;
    }
    
    mapping(address => Player)[10] private playerInfoMappings;
    
    bytes32[2][10] bitMaskForPlayFields;
    
    enum State {Uninitialized,Running,Paused,Finished,Refund}
    
    State[10] public state; 
    
     
    bool[10] private requestPause; 
    
     
    uint16[10] public ticketsSold;
    
     
    function pauseLottery(uint8 lotteryId) public ownerOnly {
        requestPause[lotteryId] = true;
    }
    
    function setOwner(address newOwner) public ownerOnly {
        owner = newOwner;
    }
    
    function getTickets(uint8 lotteryId) public view returns(uint8[]) {
        uint8[] memory result = new uint8[](maxTickets[lotteryId]);
        
        for (uint16 i = 0; i < maxTickets[lotteryId]; i++) {
            result[i] = get512(bitMaskForPlayFields[lotteryId],i);
        }
        return result;
    }
    
    function setLotteryOptions(uint8 lotteryId,uint256 price,uint16 tickets,uint256 timeToRefund) public ownerOnly {
        
        require(lotteryId >= 0 && lotteryId < 10);
         
        require(state[lotteryId] == State.Paused || state[lotteryId] == State.Uninitialized || ticketsSold[lotteryId] == 0);
        require(price > 0);
        require(tickets > 0 && tickets <= 500);
        require(timeToRefund >= 86400);  
        
        ticketPrice[lotteryId] = price;
        maxTickets[lotteryId] = tickets;
        lifetime[lotteryId] = timeToRefund;
        
        ticketsAllocator[lotteryId].length = tickets;
        
        clearState(lotteryId);
    }
    
     
     
    function clearState(uint8 lotteryId) private {
        
        if (!requestPause[lotteryId]) {
            
             
            state[lotteryId] = State.Running;
            
             
            clearNumber(lotteryId);
        
             
            started[lotteryId]  = block.timestamp;
            
             
            lastTicketBought[lotteryId] = 0;
            
             
            ticketsSold[lotteryId] = 0;
           
             
            clear512(bitMaskForPlayFields[lotteryId]);
            
        } else {
             
            state[lotteryId] = State.Paused;
            requestPause[lotteryId] = false;
        }
    }
    function isInList(address element,address[] memory list) private pure returns (bool) {
        for (uint16 i =0; i < list.length; i++) {
            if (list[i] == element) {
                return true;
            }
        }
        
        return false;
    }
    function getPlayers(uint8 lotteryId) external view returns (uint16,address[],uint16[]) {
        
        if (ticketsSold[lotteryId] == 0) {
            return;
        }
        
        uint16 currentUser = 0;
        address[] memory resultAddr = new address[](maxTickets[lotteryId]);
        uint16[] memory resultCount = new uint16[](maxTickets[lotteryId]);
        
        for (uint16 t = 0; t < maxTickets[lotteryId]; t++) {
            uint8 ticketBoughtHere = get512(bitMaskForPlayFields[lotteryId],t);
            
            if (ticketBoughtHere != 0) {
                
                address currentAddr = ticketsAllocator[lotteryId][t];
                
                if (!isInList(currentAddr,resultAddr)) {
                
                    Player storage pInfo = playerInfoMappings[lotteryId][currentAddr];
                    
                    resultAddr[currentUser] = currentAddr;
                    resultCount[currentUser] = pInfo.ticketsCount;
                    ++currentUser;
                }
            }
        }
        
        return (currentUser,resultAddr,resultCount);
    }
    
     
     
     
     
        
     
     
     
     
        
     
     
        
     
        
     
        
     
     
     
        
     
            
     
            
     
     
                    
     
     
     
     
     
     
     
        
     
     
     
     
        
     
     
     
    
     
    function getWinner(uint8 lotteryId) private view returns(uint16,address) {
        
        require(state[lotteryId] == State.Finished);
      
         
         
        uint16 winningTicket = uint16(getNumberValue(lotteryId)) % maxTickets[lotteryId];
        
        return (winningTicket,ticketsAllocator[lotteryId][winningTicket]);
    }
    
     
     
     
     
    function finalizeRoom(uint8 lotteryId) public {
        
         
        require(state[lotteryId] == State.Running);
        
         
        if (ticketsSold[lotteryId] == maxTickets[lotteryId]) {
            
             
            if (generate(lotteryId)) {
                
                 
                 
                 
                state[lotteryId] = State.Finished;
                
                var (winNumber, winner) = getWinner(lotteryId);
                
                uint256 prizeTotal = ticketsSold[lotteryId]*ticketPrice[lotteryId];
                
                 
                uint256 ownerComValue = ((prizeTotal*ownerComission)/100);
                
                 
                uint256 prize = prizeTotal - ownerComValue;
                
                address affiliate = affiliates[winner];
                if (affiliate != address(0)) {
                    uint256 affiliatePrize = (prizeTotal*affiliatePercent)/100;
                    
                    bool afPResult = affiliate.send(affiliatePrize);
                    
                    if (!afPResult) {
                        LostPayment(affiliate,affiliatePrize);
                    } else {
                         
                        ownerComValue -= affiliatePrize;
                    }
                }
                
                 
                
                bool prizeSendResult = winner.send(prize);
                if (!prizeSendResult) {
                    LostPayment(winner,prize);
                    ownerComValue += prize;
                }
                
                 
                uint8 winPercent = uint8(((playerInfoMappings[lotteryId][winner].ticketsCount*100)/maxTickets[lotteryId]));
                
                addWinner(prize,winner,winNumber,winPercent);
                WinnerPicked(lotteryId,winner,winNumber);
                
                 
                owner.send(ownerComValue);
                
                clearState(lotteryId);
            }
        }
    }
         
    function buyTicket(uint8 lotteryId,uint16[] tickets,address referer) payable public {
        
         
        require(state[lotteryId] == State.Running);
        
         
        require(maxTickets[lotteryId] > ticketsSold[lotteryId]);
        
        if (referer != address(0)) {
            setReferer(referer);
        }
        
        uint16 ticketsToBuy = uint16(tickets.length);
        
         
        uint256 valueRequired = ticketsToBuy*ticketPrice[lotteryId];
        require(valueRequired <= msg.value);
        
         
        require((maxTickets[lotteryId] - ticketsSold[lotteryId]) >= ticketsToBuy); 
        
        Player storage pInfo = playerInfoMappings[lotteryId][msg.sender];
        if (pInfo.changedOn < started[lotteryId]) {
            pInfo.changedOn = block.timestamp;
            pInfo.ticketsCount = 0;
        }
        
         
        require ((pInfo.ticketsCount+ticketsToBuy) <= ((maxTickets[lotteryId]*maxPercentPerPlayer)/100));
        
        for (uint16 i; i < ticketsToBuy; i++) {
            
            require((tickets[i] - 1) >= 0);
            
             
            require (get512(bitMaskForPlayFields[lotteryId],tickets[i]-1) == 0);
            set512(bitMaskForPlayFields[lotteryId],tickets[i]-1,1);
            ticketsAllocator[lotteryId][tickets[i]-1] = msg.sender;
        }
            
        pInfo.ticketsCount += ticketsToBuy;

         
        lastTicketBought[lotteryId] = block.timestamp;
        
         
        ticketsSold[lotteryId] +=  ticketsToBuy;
        
         
        if (ticketsSold[lotteryId] == maxTickets[lotteryId]) {
            finalizeRoom(lotteryId);
        }
        
         
        TicketsBought(lotteryId,msg.sender,tickets);
    }
    
    function roomNeedsFinalization(uint8 lotteryId) internal view  returns (bool){
          return (state[lotteryId] == State.Running && (ticketsSold[lotteryId] >= maxTickets[lotteryId]) && ((randomBlockStart[lotteryId] == 0) || ((randomBlockStart[lotteryId] > 0) && (block.number - randomBlockStart[lotteryId]) >= 32)));
    }
    
    function EthereumJackpot(address ownerAddress) public {
        
        require(ownerAddress != address(0));
            
        owner = ownerAddress;
        
        winners.length = 5;
        winnersCount = 0;
        
    }
    
    function addWinner(uint256 prize,address winner,uint16 number,uint8 percent) private {
        
         
        if (winners.length == winnersCount) {
            winners.length += 10;
        }
        
        winners[winnersCount++] =  Winner(prize,block.timestamp,winner,number,percent);
    }
    
    function setReferer(address a) private {
        if (a != msg.sender) {
            address addr = affiliates[msg.sender];
            if (addr == address(0)) {
                affiliates[msg.sender] = a;
            }
        }
    }
    
     
    function getWinners(uint256 page) public view returns(uint256[],address[],uint256[],uint16[],uint8[]) {
        
        int256 start = winnersCount - int256(10*(page+1));
        int256 end = start+10;
        
        if (start < 0) {
            start = 0;
        }
        
        if (end <= 0) {
            return;
        }
         
        address[] memory addr = new address[](uint256(end- start));
        uint256[] memory sum = new uint256[](uint256(end- start));
        uint256[] memory time = new uint256[](uint256(end- start));
        uint16[] memory number = new uint16[](uint256(end- start));
        uint8[] memory percent = new uint8[](uint256(end- start));
        
        for (uint256 i = uint256(start); i < uint256(end); i++) {
            
            Winner storage winner = winners[i];
            addr[i - uint256(start)] = winner.addr;
            sum[i - uint256(start)] = winner.prize;
            time[i - uint256(start)] = winner.timestamp;
            number[i - uint256(start)] = winner.number;
            percent[i - uint256(start)] = winner.percent;
        }
        
        return (sum,addr,time,number,percent);
    }
    
    
    function getRomms() public view returns(bool[] active,uint256[] price,uint16[] tickets,uint16[] ticketsBought,uint256[] prize,uint256[] lastActivity,uint8[] comission) {
        
        uint8 roomsCount = 10;
        
        price = new uint256[](roomsCount);
        tickets = new uint16[](roomsCount);
        lastActivity = new uint256[](roomsCount);
        prize = new uint256[](roomsCount);
        comission = new uint8[](roomsCount);
        active = new bool[](roomsCount);
        ticketsBought = new uint16[](roomsCount);
        
        for (uint8 i = 0; i < roomsCount; i++) {
            price[i] = ticketPrice[i];
            ticketsBought[i] = ticketsSold[i];
            tickets[i] = maxTickets[i];
            prize[i] = maxTickets[i]*ticketPrice[i];
            lastActivity[i]  = lastTicketBought[i];
            comission[i] = ownerComission;
            active[i] = state[i] != State.Paused && state[i] != State.Uninitialized;
        }
        
        return (active,price,tickets,ticketsBought,prize,lastActivity,comission);
    }
    
     
    function destroy() public ownerOnly {
        
        for (uint8 i = 0; i < 10; i++) {
             
            require(state[i] == State.Paused || state[i] == State.Uninitialized);
        }
        
        selfdestruct(owner);
    }
    
     
    function needsFinalization() public view returns(bool) {
        for (uint8 i = 0; i < 10; i++) {
            if (roomNeedsFinalization(i)) {
                return true;
            }
        }
        return false;
    }
    
    function finalize() public {
        for (uint8 i = 0; i < 10; i++) {
            if (roomNeedsFinalization(i)) {
                finalizeRoom(i);
            }
        }
        
    }
}