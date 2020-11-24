 

pragma solidity ^0.4.25;

 


contract SmartLotto {
    using SafeMath for uint256;

    uint256 constant public TICKET_PRICE = 0.1 ether;         
    uint256 constant public MAX_TICKETS_PER_TX = 250;         

    uint256 constant public JACKPOT_WINNER = 1;               
    uint256 constant public FIRST_PRIZE_WINNERS = 5;          
    uint256 constant public SECOND_PRIZE_WINNERS_PERC = 10;   

    uint256 constant public JACKPOT_PRIZE = 10;               
    uint256 constant public FIRST_PRIZE_POOL = 5;             
    uint256 constant public SECOND_PRIZE_POOL = 35;           

    uint256 constant public REFERRAL_COMMISSION = 5;          
    uint256 constant public MARKETING_COMMISSION = 10;        
    uint256 constant public WINNINGS_COMMISSION = 20;         

    uint256 constant public PERCENTS_DIVIDER = 100;           

    uint256 constant public CLOSE_TICKET_SALES = 1546297200;  
    uint256 constant public LOTTERY_DRAW_START = 1546300800;  
    uint256 constant public PAYMENTS_END_TIME = 1554076800;   

    uint256 public playersCount = 0;                          
    uint256 public ticketsCount = 0;                          

    uint256 public jackpotPrize = 0;                          
    uint256 public firstPrize = 0;                            
    uint256 public secondPrize = 0;                           
    uint256 public secondPrizeWonTickets = 0;                 
    uint256 public wonTicketsAmount = 0;                      
    uint256 public participantsMoneyPool = 0;                 
    uint256 public participantsTicketPrize = 0;               

    uint256 public ticketsCalculated = 0;                     

    uint256 public salt = 0;                                  

    bool public calculationsDone;                             

    address constant public MARKETING_ADDRESS = 0xFD527958E10C546f8b484135CC51fa9f0d3A8C5f;
    address constant public COMMISSION_ADDRESS = 0x53434676E12A4eE34a4eC7CaBEBE9320e8b836e1;


    struct Player {
        uint256 ticketsCount;
        uint256[] ticketsPacksBuyed;
        uint256 winnings;
        uint256 wonTicketsCount;
        uint256 payed;
    }

    struct TicketsBuy {
        address player;
        uint256 ticketsAmount;
    }

	struct TicketsWon {
		uint256 won;
    }

    mapping (address => Player) public players;
    mapping (uint256 => TicketsBuy) public ticketsBuys;
	mapping (uint256 => TicketsWon) public ticketsWons;


    function() public payable {
        if (msg.value >= TICKET_PRICE) {
            buyTickets();
        } else {
            if (!calculationsDone) {
                makeCalculations(50);
            } else {
                payPlayers();
            }
        }
    }


    function buyTickets() private {
         
        require(now <= CLOSE_TICKET_SALES);

         
        uint256 msgValue = msg.value;

         
        Player storage player = players[msg.sender];

         
        if (player.ticketsCount == 0) {
            playersCount++;
        }

         
        uint256 ticketsAmount = msgValue.div(TICKET_PRICE);

         
        if (ticketsAmount > MAX_TICKETS_PER_TX) {
             
            ticketsAmount = MAX_TICKETS_PER_TX;
        }

		 
		uint256 overPayed = msgValue.sub(ticketsAmount.mul(TICKET_PRICE));

		 
		if (overPayed > 0) {
			 
			msgValue = msgValue.sub(overPayed);

			 
			msg.sender.send(overPayed);
		}

         
        player.ticketsPacksBuyed.push(ticketsCount);

         
         
         
        ticketsBuys[ticketsCount] = TicketsBuy({
            player : msg.sender,
            ticketsAmount : ticketsAmount
        });

		 
        player.ticketsCount = player.ticketsCount.add(ticketsAmount);
         
        ticketsCount = ticketsCount.add(ticketsAmount);

         
        address referrerAddress = bytesToAddress(msg.data);

         
        if (referrerAddress != address(0) && referrerAddress != msg.sender) {
             
            uint256 referralAmount = msgValue.mul(REFERRAL_COMMISSION).div(PERCENTS_DIVIDER);
             
            referrerAddress.send(referralAmount);
        }

         
        uint256 marketingAmount = msgValue.mul(MARKETING_COMMISSION).div(PERCENTS_DIVIDER);
         
        MARKETING_ADDRESS.send(marketingAmount);
    }

    function makeCalculations(uint256 count) public {
         
        require(!calculationsDone);
         
        require(now >= LOTTERY_DRAW_START);

         
        if (salt == 0) {
             
            salt = uint256(keccak256(abi.encodePacked(ticketsCount, uint256(blockhash(block.number-1)), playersCount)));

             
            uint256 contractBalance = address(this).balance;

             
            jackpotPrize = contractBalance.mul(JACKPOT_PRIZE).div(PERCENTS_DIVIDER).div(JACKPOT_WINNER);
             
            firstPrize = contractBalance.mul(FIRST_PRIZE_POOL).div(PERCENTS_DIVIDER).div(FIRST_PRIZE_WINNERS);

             
            secondPrizeWonTickets = ticketsCount.mul(SECOND_PRIZE_WINNERS_PERC).div(PERCENTS_DIVIDER);
             
            secondPrize = contractBalance.mul(SECOND_PRIZE_POOL).div(PERCENTS_DIVIDER).div(secondPrizeWonTickets);

             
            wonTicketsAmount = secondPrizeWonTickets.add(JACKPOT_WINNER).add(FIRST_PRIZE_WINNERS);

             
            participantsMoneyPool = contractBalance.mul(PERCENTS_DIVIDER.sub(JACKPOT_PRIZE).sub(FIRST_PRIZE_POOL).sub(SECOND_PRIZE_POOL)).div(PERCENTS_DIVIDER);
             
            participantsTicketPrize = participantsMoneyPool.div(ticketsCount.sub(wonTicketsAmount));

             
            calculateWonTickets(JACKPOT_WINNER, jackpotPrize);
             
            calculateWonTickets(FIRST_PRIZE_WINNERS, firstPrize);

             
            ticketsCalculated = ticketsCalculated.add(JACKPOT_WINNER).add(FIRST_PRIZE_WINNERS);
         
        } else {
             
            if (ticketsCalculated < wonTicketsAmount) {
                 
                uint256 ticketsForCalculation = wonTicketsAmount.sub(ticketsCalculated);

                 
                 
                if (count == 0 && ticketsForCalculation > 50) {
                    ticketsForCalculation = 50;
                }

                 
                 
                if (count > 0 && count <= ticketsForCalculation) {
                    ticketsForCalculation = count;
                }

                 
                calculateWonTickets(ticketsForCalculation, secondPrize);

                 
                ticketsCalculated = ticketsCalculated.add(ticketsForCalculation);
            }

             
            if (ticketsCalculated == wonTicketsAmount) {
                calculationsDone = true;
            }
        }
    }

    function calculateWonTickets(uint256 numbers, uint256 prize) private {
         
        for (uint256 n = 0; n < numbers; n++) {
             
            uint256 wonTicketNumber = random(n);

			 
			if (ticketsWons[wonTicketNumber].won == 1) {
				 
				numbers = numbers.add(1);
			 
			} else {
				 
				ticketsWons[wonTicketNumber].won = 1;

				 
				for (uint256 i = 0; i < MAX_TICKETS_PER_TX; i++) {
					 
					uint256 wonTicketIdSearch = wonTicketNumber - i;

					 
					if (ticketsBuys[wonTicketIdSearch].ticketsAmount > 0) {
						 
						Player storage player = players[ticketsBuys[wonTicketIdSearch].player];

						 
						player.winnings = player.winnings.add(prize);
						 
						player.wonTicketsCount++;

						 
						break;
					}
				}
			}
        }

         
        salt = salt.add(numbers);
    }

    function payPlayers() private {
         
        require(calculationsDone);

         
        if (now <= PAYMENTS_END_TIME) {
             
            Player storage player = players[msg.sender];

             
            if (player.winnings > 0 && player.payed == 0) {
                 
                uint256 winCommission = player.winnings.mul(WINNINGS_COMMISSION).div(PERCENTS_DIVIDER);

                 
                uint256 notWonTickets = player.ticketsCount.sub(player.wonTicketsCount);
                 
                uint256 notWonAmount = notWonTickets.mul(participantsTicketPrize);

                 
                player.payed = player.winnings.add(notWonAmount);

                 
                msg.sender.send(player.winnings.sub(winCommission).add(notWonAmount).add(msg.value));

                 
                COMMISSION_ADDRESS.send(winCommission);
            }

             
            if (player.winnings == 0 && player.payed == 0) {
                 
                uint256 returnAmount = player.ticketsCount.mul(participantsTicketPrize);

                 
                player.payed = returnAmount;

                 
                msg.sender.send(returnAmount.add(msg.value));
            }
         
        } else {
             
            uint256 contractBalance = address(this).balance;

             
            if (contractBalance > 0) {
                 
                COMMISSION_ADDRESS.send(contractBalance);
            }
        }
    }

    function random(uint256 nonce) private view returns (uint256) {
         
        uint256 number = uint256(keccak256(abi.encodePacked(salt.add(nonce)))).mod(ticketsCount);
        return number;
    }

    function playerBuyedTicketsPacks(address player) public view returns (uint256[]) {
        return players[player].ticketsPacksBuyed;
    }

    function bytesToAddress(bytes data) private pure returns (address addr) {
        assembly {
            addr := mload(add(data, 0x14))
        }
    }
}


 
library SafeMath {
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}