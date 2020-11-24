 

contract JackPot {
    address public host;
	uint minAmount;
    uint[] public contributions;
    address[] public contributors;
	uint public numPlayers = 0;
	uint public nextDraw;
	bytes32 seedHash;
	bytes32 random;	

    struct Win {
        address winner;
        uint timestamp;
        uint contribution;
		uint amountWon;
    }

    Win[] public recentWins;
    uint recentWinsCount;
	
	function insert_contribution(address addr, uint value) internal {
		 
		if(numPlayers == contributions.length) {
			 
			contributions.length += 1;
			contributors.length += 1;
		}
		contributions[numPlayers] = value;
		contributors[numPlayers++] = addr;
	}
	
	function getContributions(address addr) constant returns (uint) {
        uint i;
        for (i=0; i < numPlayers; i++) {
			if (contributors[i] == addr) {  
				break;
			}
		}
		
		if(i == numPlayers) {  
            return 0;
        } else {
			return contributions[i];
		}
    }
	
	function JackPot() {

        host = msg.sender;
		seedHash = sha3(1111);
		minAmount = 10 * 1 finney;
        recentWinsCount = 10;
		nextDraw = 1234;  
    }

    function() {
        addToContribution();
    }

    function addToContribution() {
        addValueToContribution(msg.value);
    }

    function addValueToContribution(uint value) internal {
         
        if(value < minAmount) throw;
	    uint i;
        for (i=0; i < numPlayers; i++) {
			if (contributors[i] == msg.sender) {  
				break;
			}
		}
		
		if(i == numPlayers) {  
			insert_contribution(msg.sender, value);
        } else {
			contributions[i]+= value;  
		}
		
		random = sha3(random, block.blockhash(block.number - 1));		
    }
	
	 
	function drawPot(bytes32 seed, bytes32 newSeed) {
		if(msg.sender != host) throw;
		
		 
		if (sha3(seed) == seedHash) {
			seedHash = sha3(newSeed);
			 
            uint winner_index = selectWinner(seed);

             
            host.send(this.balance / 100);
			
			uint amountWon = this.balance; 
			
             
            contributors[winner_index].send(this.balance);
			
			 
            recordWin(winner_index, amountWon);

            reset();
			nextDraw = now + 7 days;	
		}
	}

	function setDrawDate(uint _newDraw) {
		if(msg.sender != host) throw;
		nextDraw = _newDraw;
	}
	
	
    function selectWinner(bytes32 seed) internal returns (uint winner_index) {

        uint semirandom = uint(sha3(random, seed)) % this.balance;
        for(uint i = 0; i < numPlayers; ++i) {
            if(semirandom < contributions[i]) return i;
            semirandom -= contributions[i];
        }
    }

    function recordWin(uint winner_index, uint amount) internal {
        if(recentWins.length < recentWinsCount) {
            recentWins.length++;
        } else {
             
             
            for(uint i = 0; i < recentWinsCount - 1; ++i) {
                recentWins[i] = recentWins[i + 1];
            }
        }

        recentWins[recentWins.length - 1] = Win(contributors[winner_index], block.timestamp, contributions[winner_index], amount);
    }

    function reset() internal {
         
		numPlayers = 0;
    }


     
    function destroy() {
        if(msg.sender != host) throw;

         
        for(uint i = 0; i < numPlayers; ++i) {
            contributors[i].send(contributions[i]);
        }

		reset();
        selfdestruct(host);
    }
}