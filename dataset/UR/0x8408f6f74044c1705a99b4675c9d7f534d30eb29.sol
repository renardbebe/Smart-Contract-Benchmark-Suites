 

pragma solidity ^0.4.18;

contract Ownable {
    address public owner;

    function Ownable() public {
        owner = msg.sender;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Withdrawable {

    mapping (address => uint) public pendingWithdrawals;

    function withdraw() public {
        uint amount = pendingWithdrawals[msg.sender];
        
        require(amount > 0);
        require(this.balance >= amount);

        pendingWithdrawals[msg.sender] = 0;
        msg.sender.transfer(amount);
    }
}

 
contract EthLottery is Withdrawable, Ownable {

    event onTicketPurchase(uint32 lotteryId, address buyer, uint16[] tickets);
    event onLotteryCompleted(uint32 lotteryId);
    event onLotteryFinalized(uint32 lotteryId);
    event onLotteryInsurance(address claimer);

    uint32 public lotteryId;
    
    struct Lottery {        
        uint8 ownerCut;

        uint ticketPrice;
        uint16 numTickets;
        uint16 winningTicket;
        
        mapping (uint16 => address) tickets;
        mapping (address => uint16) ticketsPerAddress;
        
        address winner;
        
        uint16[] ticketsSold;
        address[] ticketOwners;

        bytes32 serverHash;
        bytes32 serverSalt;
        uint serverRoll; 

        uint lastSaleTimestamp;
    }

    mapping (uint32 => Lottery) lotteries;
    
     
    function initLottery(uint16 numTickets, uint ticketPrice, uint8 ownerCut, bytes32 serverHash) onlyOwner public {
        require(ownerCut < 100);
                
        lotteryId += 1;

        lotteries[lotteryId].ownerCut = ownerCut;
        lotteries[lotteryId].ticketPrice = ticketPrice;
        lotteries[lotteryId].numTickets = numTickets;
        lotteries[lotteryId].serverHash = serverHash;
    }

    function getLotteryDetails(uint16 lottId) public constant returns (
        uint8 ownerCut,
        uint ticketPrice,
         
        uint16 numTickets, 
        uint16 winningTicket,
         
        bytes32 serverHash,
        bytes32 serverSalt,
        uint serverRoll,
         
        uint lastSaleTimestamp,
         
        address winner,
        uint16[] ticketsSold, 
        address[] ticketOwners
    ) {
        ownerCut = lotteries[lottId].ownerCut;
        ticketPrice = lotteries[lottId].ticketPrice;
         
        numTickets = lotteries[lottId].numTickets;
        winningTicket = lotteries[lottId].winningTicket;
         
        serverHash = lotteries[lottId].serverHash;
        serverSalt = lotteries[lottId].serverSalt;
        serverRoll = lotteries[lottId].serverRoll; 
         
        lastSaleTimestamp = lotteries[lottId].lastSaleTimestamp;
         
        winner = lotteries[lottId].winner;
        ticketsSold = lotteries[lottId].ticketsSold;
        ticketOwners = lotteries[lottId].ticketOwners;
    }

    function purchaseTicket(uint16 lottId, uint16[] tickets) public payable {

         
        require(lotteries[lottId].winner == address(0));
        require(lotteries[lottId].ticketsSold.length < lotteries[lottId].numTickets);

         
        require(tickets.length > 0);
        require(tickets.length <= lotteries[lottId].numTickets);
        require(tickets.length * lotteries[lottId].ticketPrice == msg.value);

        for (uint16 i = 0; i < tickets.length; i++) {
            
            uint16 ticket = tickets[i];

             
            require(lotteries[lottId].numTickets > ticket);
            require(lotteries[lottId].tickets[ticket] == 0);
            
             
            lotteries[lottId].ticketsSold.push(ticket);
            lotteries[lottId].ticketOwners.push(msg.sender);

             
            lotteries[lottId].tickets[ticket] = msg.sender;
        }

         
        lotteries[lottId].ticketsPerAddress[msg.sender] += uint16(tickets.length);

         
        lotteries[lottId].lastSaleTimestamp = now;

        onTicketPurchase(lottId, msg.sender, tickets);

         
        if (lotteries[lottId].ticketsSold.length == lotteries[lottId].numTickets) {
            onLotteryCompleted(lottId);
        }
    }

    function finalizeLottery(uint16 lottId, bytes32 serverSalt, uint serverRoll) onlyOwner public {
        
         
        require(lotteries[lottId].winner == address(0));
        require(lotteries[lottId].ticketsSold.length == lotteries[lottId].numTickets);

         
        require((lotteries[lottId].lastSaleTimestamp + 2 hours) >= now);

         
        require(keccak256(serverSalt, serverRoll) == lotteries[lottId].serverHash);
        
         
        uint16 winningTicket = uint16(
            addmod(serverRoll, lotteries[lottId].lastSaleTimestamp, lotteries[lottId].numTickets)
        );
        address winner = lotteries[lottId].tickets[winningTicket];
        
        lotteries[lottId].winner = winner;
        lotteries[lottId].winningTicket = winningTicket;

         
        uint vol = lotteries[lottId].numTickets * lotteries[lottId].ticketPrice;

        pendingWithdrawals[owner] += (vol * lotteries[lottId].ownerCut) / 100;
        pendingWithdrawals[winner] += (vol * (100 - lotteries[lottId].ownerCut)) / 100;

        onLotteryFinalized(lottId);
    }

    function lotteryCloseInsurance(uint16 lottId) public {
        
         
        require(lotteries[lottId].winner == address(0));
        require(lotteries[lottId].ticketsSold.length == lotteries[lottId].numTickets);
        
         
        require((lotteries[lottId].lastSaleTimestamp + 2 hours) < now);
            
         
        require(lotteries[lottId].ticketsPerAddress[msg.sender] > 0);

        uint16 numTickets = lotteries[lottId].ticketsPerAddress[msg.sender];

         
        lotteries[lottId].ticketsPerAddress[msg.sender] = 0;
        pendingWithdrawals[msg.sender] += (lotteries[lottId].ticketPrice * numTickets);

        onLotteryInsurance(msg.sender);
    }
}