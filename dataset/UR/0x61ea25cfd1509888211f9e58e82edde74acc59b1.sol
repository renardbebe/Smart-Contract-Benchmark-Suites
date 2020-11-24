 

 

pragma solidity ^0.4.21;

contract ProofOfLongHodl {
    using SafeMath for uint256;

    event Deposit(address user, uint amount);
    event Withdraw(address user, uint amount);
    event Claim(address user, uint dividends);
    event Reinvest(address user, uint dividends);

    address owner;
    mapping(address => bool) preauthorized;
    bool gameStarted;

    uint constant depositTaxDivisor = 5;		 
    uint constant withdrawalTaxDivisor = 5;	 
    uint constant lotteryFee = 20; 				 

    mapping(address => uint) public investment;

    mapping(address => uint) public stake;
    uint public totalStake;
    uint stakeValue;

    mapping(address => uint) dividendCredit;
    mapping(address => uint) dividendDebit;

    function ProofOfLongHodl() public {
        owner = msg.sender;
        preauthorized[owner] = true;
    }

    function preauthorize(address _user) public {
        require(msg.sender == owner);
        preauthorized[_user] = true;
    }

    function startGame() public {
        require(msg.sender == owner);
        gameStarted = true;
    }

    function depositHelper(uint _amount) private {
    	require(_amount > 0);
        uint _tax = _amount.div(depositTaxDivisor);
        uint _lotteryPool = _amount.div(lotteryFee);
        uint _amountAfterTax = _amount.sub(_tax).sub(_lotteryPool);

         
        uint weeklyPoolFee = _lotteryPool.div(5);
        uint dailyPoolFee = _lotteryPool.sub(weeklyPoolFee);

        uint tickets = _amount.div(TICKET_PRICE);

        weeklyPool = weeklyPool.add(weeklyPoolFee);
        dailyPool = dailyPool.add(dailyPoolFee);

         
        dailyTicketPurchases storage dailyPurchases = dailyTicketsBoughtByPlayer[msg.sender];

         
        if (dailyPurchases.lotteryId != dailyLotteryRound) {
            dailyPurchases.numPurchases = 0;
            dailyPurchases.ticketsPurchased = 0;
            dailyPurchases.lotteryId = dailyLotteryRound;
            dailyLotteryPlayers[dailyLotteryRound].push(msg.sender);  
        }

         
        if (dailyPurchases.numPurchases == dailyPurchases.ticketsBought.length) {
            dailyPurchases.ticketsBought.length += 1;
        }
        dailyPurchases.ticketsBought[dailyPurchases.numPurchases++] = dailyTicketPurchase(dailyTicketsBought, dailyTicketsBought + (tickets - 1));  
        
         
        dailyPurchases.ticketsPurchased += tickets;
        dailyTicketsBought += tickets;

         
		weeklyTicketPurchases storage weeklyPurchases = weeklyTicketsBoughtByPlayer[msg.sender];

		 
		if (weeklyPurchases.lotteryId != weeklyLotteryRound) {
		    weeklyPurchases.numPurchases = 0;
		    weeklyPurchases.ticketsPurchased = 0;
		    weeklyPurchases.lotteryId = weeklyLotteryRound;
		    weeklyLotteryPlayers[weeklyLotteryRound].push(msg.sender);  
		}

		 
		if (weeklyPurchases.numPurchases == weeklyPurchases.ticketsBought.length) {
		    weeklyPurchases.ticketsBought.length += 1;
		}
		weeklyPurchases.ticketsBought[weeklyPurchases.numPurchases++] = weeklyTicketPurchase(weeklyTicketsBought, weeklyTicketsBought + (tickets - 1));  

		 
		weeklyPurchases.ticketsPurchased += tickets;
		weeklyTicketsBought += tickets;

        if (totalStake > 0)
            stakeValue = stakeValue.add(_tax.div(totalStake));
        uint _stakeIncrement = sqrt(totalStake.mul(totalStake).add(_amountAfterTax)).sub(totalStake);
        investment[msg.sender] = investment[msg.sender].add(_amountAfterTax);
        stake[msg.sender] = stake[msg.sender].add(_stakeIncrement);
        totalStake = totalStake.add(_stakeIncrement);
        dividendDebit[msg.sender] = dividendDebit[msg.sender].add(_stakeIncrement.mul(stakeValue));
    }

    function deposit() public payable {
        require(preauthorized[msg.sender] || gameStarted);
        depositHelper(msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint _amount) public {
        require(_amount > 0);
        require(_amount <= investment[msg.sender]);
        uint _tax = _amount.div(withdrawalTaxDivisor);
        uint _lotteryPool = _amount.div(lotteryFee);
        uint _amountAfterTax = _amount.sub(_tax).sub(_lotteryPool);

         
        uint weeklyPoolFee = _lotteryPool.div(20);
        uint dailyPoolFee = _lotteryPool.sub(weeklyPoolFee);

        weeklyPool = weeklyPool.add(weeklyPoolFee);
        dailyPool = dailyPool.add(dailyPoolFee);

        uint _stakeDecrement = stake[msg.sender].mul(_amount).div(investment[msg.sender]);
        uint _dividendCredit = _stakeDecrement.mul(stakeValue);
        investment[msg.sender] = investment[msg.sender].sub(_amount);
        stake[msg.sender] = stake[msg.sender].sub(_stakeDecrement);
        totalStake = totalStake.sub(_stakeDecrement);
        if (totalStake > 0)
            stakeValue = stakeValue.add(_tax.div(totalStake));
        dividendCredit[msg.sender] = dividendCredit[msg.sender].add(_dividendCredit);
        uint _creditDebitCancellation = min(dividendCredit[msg.sender], dividendDebit[msg.sender]);
        dividendCredit[msg.sender] = dividendCredit[msg.sender].sub(_creditDebitCancellation);
        dividendDebit[msg.sender] = dividendDebit[msg.sender].sub(_creditDebitCancellation);

        msg.sender.transfer(_amountAfterTax);
        emit Withdraw(msg.sender, _amount);
    }

    function claimHelper() private returns(uint) {
        uint _dividendsForStake = stake[msg.sender].mul(stakeValue);
        uint _dividends = _dividendsForStake.add(dividendCredit[msg.sender]).sub(dividendDebit[msg.sender]);
        dividendCredit[msg.sender] = 0;
        dividendDebit[msg.sender] = _dividendsForStake;

        return _dividends;
    }

    function claim() public {
        uint _dividends = claimHelper();
        msg.sender.transfer(_dividends);

        emit Claim(msg.sender, _dividends);
    }

    function reinvest() public {
        uint _dividends = claimHelper();
        depositHelper(_dividends);

        emit Reinvest(msg.sender, _dividends);
    }

    function dividendsForUser(address _user) public view returns (uint) {
        return stake[_user].mul(stakeValue).add(dividendCredit[_user]).sub(dividendDebit[_user]);
    }

    function min(uint x, uint y) private pure returns (uint) {
        return x <= y ? x : y;
    }

    function sqrt(uint x) private pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

     
     
    uint private dailyPool = 0;
    uint private dailyLotteryRound = 1;
    uint private dailyTicketsBought = 0;
    uint private dailyTicketThatWon;
    address[] public dailyWinners;
    uint256[] public dailyPots;

     
    uint private weeklyPool = 0;
    uint private weeklyLotteryRound = 1;
    uint private weeklyTicketsBought = 0;
    uint private weeklyTicketThatWon;
    address[] public weeklyWinners;
    uint256[] public weeklyPots;

    uint public TICKET_PRICE = 0.01 ether;
    uint public DAILY_LIMIT = 0.15 ether;
    bool private dailyTicketSelected;
    bool private weeklyTicketSelected;

     
     
    struct dailyTicketPurchases {
        dailyTicketPurchase[] ticketsBought;
        uint256 numPurchases;  
        uint256 lotteryId;
        uint256 ticketsPurchased;
    }

     
    struct dailyTicketPurchase {
        uint256 startId;
        uint256 endId;
    }

    mapping(address => dailyTicketPurchases) private dailyTicketsBoughtByPlayer;
    mapping(uint256 => address[]) private dailyLotteryPlayers;

     
    struct weeklyTicketPurchases {
        weeklyTicketPurchase[] ticketsBought;
        uint256 numPurchases;  
        uint256 lotteryId;
        uint256 ticketsPurchased;
    }

     
    struct weeklyTicketPurchase {
        uint256 startId;
        uint256 endId;
    }

    mapping(address => weeklyTicketPurchases) private weeklyTicketsBoughtByPlayer;
    mapping(uint256 => address[]) private weeklyLotteryPlayers;

     
    function drawDailyWinner() public {
        require(msg.sender == owner);
        require(!dailyTicketSelected);
       
        uint256 seed = dailyTicketsBought + block.timestamp;
        dailyTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, dailyTicketsBought);
        dailyTicketSelected = true;
    }

    function drawWeeklyWinner() public {
        require(msg.sender == owner);
        require(!weeklyTicketSelected);
       
        uint256 seed = weeklyTicketsBought + block.timestamp;
        weeklyTicketThatWon = addmod(uint256(block.blockhash(block.number-1)), seed, weeklyTicketsBought);
        weeklyTicketSelected = true;
    }

    function awardDailyLottery(address checkWinner, uint256 checkIndex) external {
		require(msg.sender == owner);
	    
	    if (!dailyTicketSelected) {
	    	drawDailyWinner();  
	    }
	        
	     
	    if (checkWinner != 0) {
	        dailyTicketPurchases storage tickets = dailyTicketsBoughtByPlayer[checkWinner];
	        if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.lotteryId == dailyLotteryRound) {
	            dailyTicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
	            if (dailyTicketThatWon >= checkTicket.startId && dailyTicketThatWon <= checkTicket.endId) {
	                if ( dailyPool >= DAILY_LIMIT) {
	            		checkWinner.transfer(DAILY_LIMIT);
	            		dailyPots.push(DAILY_LIMIT);
	            		dailyPool = dailyPool.sub(DAILY_LIMIT);		
	        		} else {
	        			checkWinner.transfer(dailyPool);
	        			dailyPots.push(dailyPool);
	        			dailyPool = 0;
	        		}

	        		dailyWinners.push(checkWinner);
            		dailyLotteryRound = dailyLotteryRound.add(1);
            		dailyTicketsBought = 0;
            		dailyTicketSelected = false;
	                return;
	            }
	        }
	    }
	    
	     
	    for (uint256 i = 0; i < dailyLotteryPlayers[dailyLotteryRound].length; i++) {
	        address player = dailyLotteryPlayers[dailyLotteryRound][i];
	        dailyTicketPurchases storage playersTickets = dailyTicketsBoughtByPlayer[player];
	        
	        uint256 endIndex = playersTickets.numPurchases - 1;
	         
	        if (dailyTicketThatWon >= playersTickets.ticketsBought[0].startId && dailyTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
	            for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
	                dailyTicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
	                if (dailyTicketThatWon >= playerTicket.startId && dailyTicketThatWon <= playerTicket.endId) {
	                	if ( dailyPool >= DAILY_LIMIT) {
	                		player.transfer(DAILY_LIMIT);
	                		dailyPots.push(DAILY_LIMIT);
	                		dailyPool = dailyPool.sub(DAILY_LIMIT);
	            		} else {
	            			player.transfer(dailyPool);
	            			dailyPots.push(dailyPool);
	            			dailyPool = 0;
	            		}

	            		dailyWinners.push(player);
	            		dailyLotteryRound = dailyLotteryRound.add(1);
	            		dailyTicketsBought = 0;
	            		dailyTicketSelected = false;

	                    return;
	                }
	            }
	        }
	    }
	}

	function awardWeeklyLottery(address checkWinner, uint256 checkIndex) external {
		require(msg.sender == owner);
	    
	    if (!weeklyTicketSelected) {
	    	drawWeeklyWinner();  
	    }
	       
	     
	    if (checkWinner != 0) {
	        weeklyTicketPurchases storage tickets = weeklyTicketsBoughtByPlayer[checkWinner];
	        if (tickets.numPurchases > 0 && checkIndex < tickets.numPurchases && tickets.lotteryId == weeklyLotteryRound) {
	            weeklyTicketPurchase storage checkTicket = tickets.ticketsBought[checkIndex];
	            if (weeklyTicketThatWon >= checkTicket.startId && weeklyTicketThatWon <= checkTicket.endId) {
	        		checkWinner.transfer(weeklyPool);

	        		weeklyPots.push(weeklyPool);
	        		weeklyPool = 0;
	            	weeklyWinners.push(player);
	            	weeklyLotteryRound = weeklyLotteryRound.add(1);
	            	weeklyTicketsBought = 0;
	            	weeklyTicketSelected = false;
	                return;
	            }
	        }
	    }
	    
	     
	    for (uint256 i = 0; i < weeklyLotteryPlayers[weeklyLotteryRound].length; i++) {
	        address player = weeklyLotteryPlayers[weeklyLotteryRound][i];
	        weeklyTicketPurchases storage playersTickets = weeklyTicketsBoughtByPlayer[player];
	        
	        uint256 endIndex = playersTickets.numPurchases - 1;
	         
	        if (weeklyTicketThatWon >= playersTickets.ticketsBought[0].startId && weeklyTicketThatWon <= playersTickets.ticketsBought[endIndex].endId) {
	            for (uint256 j = 0; j < playersTickets.numPurchases; j++) {
	                weeklyTicketPurchase storage playerTicket = playersTickets.ticketsBought[j];
	                if (weeklyTicketThatWon >= playerTicket.startId && weeklyTicketThatWon <= playerTicket.endId) {
	            		player.transfer(weeklyPool);  

	            		weeklyPots.push(weeklyPool);
	            		weeklyPool = 0;
	            		weeklyWinners.push(player);
	            		weeklyLotteryRound = weeklyLotteryRound.add(1);
	            		weeklyTicketsBought = 0;  
	            		weeklyTicketSelected = false;            
	                    return;
	                }
	            }
	        }
	    }
	}

    function getLotteryData() public view returns( uint256, uint256, uint256, uint256, uint256, uint256) {
    	return (dailyPool, weeklyPool, dailyLotteryRound, weeklyLotteryRound, dailyTicketsBought, weeklyTicketsBought);
    }

    function getDailyLotteryParticipants(uint256 _round) public view returns(address[]) {
    	return dailyLotteryPlayers[_round];
    }

    function getWeeklyLotteryParticipants(uint256 _round) public view returns(address[]) {
    	return weeklyLotteryPlayers[_round];
    }

    function getLotteryWinners() public view returns(uint256, uint256) {
    	return (dailyWinners.length, weeklyWinners.length);
    }

    function editDailyLimit(uint _price) public payable {
    	require(msg.sender == owner);
    	DAILY_LIMIT = _price;
    }

    function editTicketPrice(uint _price) public payable {
    	require(msg.sender == owner);
    	TICKET_PRICE = _price;
    }

    function getDailyTickets(address _player) public view returns(uint256) {
    	dailyTicketPurchases storage dailyPurchases = dailyTicketsBoughtByPlayer[_player];

    	if (dailyPurchases.lotteryId != dailyLotteryRound) {
    		return 0;
    	}

    	return dailyPurchases.ticketsPurchased;
    }

    function getWeeklyTickets(address _player) public view returns(uint256) {
    	weeklyTicketPurchases storage weeklyPurchases = weeklyTicketsBoughtByPlayer[_player];

    	if (weeklyPurchases.lotteryId != weeklyLotteryRound) {
    		return 0;
    	}

    	return weeklyPurchases.ticketsPurchased;	
    }

     
    function addToPool() public payable {
    	require(msg.value > 0);
    	uint _lotteryPool = msg.value;

    	 
        uint weeklyPoolFee = _lotteryPool.div(5);
        uint dailyPoolFee = _lotteryPool.sub(weeklyPoolFee);

        weeklyPool = weeklyPool.add(weeklyPoolFee);
        dailyPool = dailyPool.add(dailyPoolFee);
    }

    function winningTickets() public view returns(uint256, uint256) {
    	return (dailyTicketThatWon, weeklyTicketThatWon);
    }
    
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;                                                                                                                                                                                       
        }
        uint256 c = a * b;                                                                                                                                                                                  
        assert(c / a == b);                                                                                                                                                                                 
        return c;                                                                                                                                                                                           
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;                                                                                                                                                                                       
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);                                                                                                                                                                                     
        return a - b;                                                                                                                                                                                       
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;                                                                                                                                                                                  
        assert(c >= a);                                                                                                                                                                                     
        return c;                                                                                                                                                                                           
    }
}