 

pragma solidity ^0.4.23;
 
contract WinEtherPot10 {
 
     
    address public owner; 					 
    uint private latestBlockNumber;          
    bytes32 private cumulativeHash;			
    address[] private bets;					 
    mapping(address => uint256) winners;     
	
	uint256 ownerShare = 5;
	uint256 winnerShare = 95;
	bool splitAllowed = true;
	
	uint256 public minEntriesRequiredPerGame = 3;
	uint256 playerCount = 0;
	uint256 public potSize;
	
	bool autoDistributeWinning = true;    
	
	bool autoWithdrawWinner = true;    
		
	bool public isRunning = true;
	
	uint256 public minEntryInWei = (1/10) * 1e18;  
 	
    
	 
    event betPlaced(address thePersonWhoBet, uint moneyInWei, uint blockNumber );
    event betStarted(address thePersonWhoBet, uint moneyInWei );
    event betAccepted(address thePersonWhoBet, uint moneyInWei, uint blockNumber );
	event betNotPlaced(address thePersonWhoBet, uint moneyInWei, uint blockNumber );
      
	 
    event startWinnerDraw(uint256 randomInt, address winner, uint blockNumber , uint256 amountWonByThisWinner );	
	
	 
	event amountWonByOwner(address ownerWithdrawer,  uint256 amount);
	event amountWonByWinner(address winnerWithdrawer,  uint256 amount);
	
	 
    event startWithDraw(address withdrawer,  uint256 amount);
	event successWithDraw(address withdrawer,  uint256 amount);
	event rollbackWithDraw(address withdrawer,  uint256 amount);
	
    event showParticipants(address[] thePersons);
    event showBetNumber(uint256 betNumber, address better);
    
    event calledConstructor(uint block, address owner);
	
	event successDrawWinner(bool successFlag ); 
	event notReadyDrawWinner(bool errorFlag ); 
 
      
	constructor() public {
        owner = msg.sender;
        latestBlockNumber = block.number;
        cumulativeHash = bytes32(0);
        
        emit calledConstructor(latestBlockNumber, owner);
    }
 
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
 
     
    function placeBet() public payable returns (bool) {
        
		if( isRunning == true ) {
		
			uint _wei = msg.value;
				   
			emit betStarted(msg.sender , msg.value);
			 
			assert(_wei >= minEntryInWei);
			cumulativeHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber), cumulativeHash));
			
			emit betPlaced(msg.sender , msg.value , block.number);
			
			latestBlockNumber = block.number;
			bets.push(msg.sender);
			
			emit betAccepted(msg.sender , msg.value , block.number);
			
			potSize = potSize + msg.value;
		}else {
			
			emit betNotPlaced(msg.sender , msg.value , block.number);
		}
		
		if( autoWithdrawWinner == true ) {
			
			if( bets.length >= minEntriesRequiredPerGame ) {
				bool successDrawWinnerFlag = drawAutoWinner();
				emit successDrawWinner(successDrawWinnerFlag);
			}else {
			    emit notReadyDrawWinner(false);
			}
		}
        return true;
    }
 
    function drawAutoWinner() private returns (bool) {
        
		bool boolSuccessFlag = false;
		
		assert( bets.length >= minEntriesRequiredPerGame );
        
		latestBlockNumber = block.number;
        
		bytes32 _finalHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber-1), cumulativeHash));
        
		uint256 _randomInt = uint256(_finalHash) % bets.length;
        
		address _winner = bets[_randomInt];
		
		uint256 amountWon = potSize ;
        
		uint256 ownerAmt = amountWon * ownerShare /100 ;
		
		uint256 winnerAmt = amountWon * winnerShare / 100 ;
		
		
		
		
		if( splitAllowed == true ) {
		
		    emit startWinnerDraw(_randomInt, _winner, latestBlockNumber , winnerAmt );
			winners[_winner] = winnerAmt;
			owner.transfer(ownerAmt);
			emit amountWonByOwner(owner, ownerAmt);
			
			if( autoDistributeWinning == true ) {
			   
				winners[_winner] = 0;
				
				if( _winner.send(winnerAmt)) {
				   emit successWithDraw(_winner, winnerAmt);
				   emit amountWonByWinner(_winner, winnerAmt);
				   
				}
				else {
				  winners[_winner] = winnerAmt;
				  emit rollbackWithDraw(_winner, winnerAmt);
				  
				}
			}
			
			
		} else {
		
		    emit startWinnerDraw(_randomInt, _winner, latestBlockNumber , amountWon );
			winners[_winner] = amountWon;
			
			if( autoDistributeWinning == true ) {
			   
				winners[_winner] = 0;
				
				if( _winner.send(amountWon)) {
				   emit successWithDraw(_winner, amountWon);
				   emit amountWonByWinner(_winner, amountWon);
				}
				else {
				  winners[_winner] = amountWon;
				  emit rollbackWithDraw(_winner, amountWon);
				}
			}
		}
				
        cumulativeHash = bytes32(0);
        delete bets;
		
		potSize = 0;
		
		
		boolSuccessFlag = true;
		
        return boolSuccessFlag;
    }
	
	
	function drawWinner() public onlyOwner returns (address) {
        
		assert( bets.length >= minEntriesRequiredPerGame );
        
		latestBlockNumber = block.number;
        
		bytes32 _finalHash = keccak256(abi.encodePacked(blockhash(latestBlockNumber-1), cumulativeHash));
        
		uint256 _randomInt = uint256(_finalHash) % bets.length;
        
		address _winner = bets[_randomInt];
		
		uint256 amountWon = potSize ;
        
		uint256 ownerAmt = amountWon * ownerShare /100 ;
		
		uint256 winnerAmt = amountWon * winnerShare / 100 ;
		
		if( splitAllowed == true ) {
			winners[_winner] = winnerAmt;
			owner.transfer(ownerAmt);
			emit amountWonByOwner(owner, ownerAmt);
			
			if( autoDistributeWinning == true ) {
			   
				winners[_winner] = 0;
				
				if( _winner.send(winnerAmt)) {
				   emit successWithDraw(_winner, winnerAmt);
				   emit amountWonByWinner(_winner, winnerAmt);
				   
				}
				else {
				  winners[_winner] = winnerAmt;
				  emit rollbackWithDraw(_winner, winnerAmt);
				  
				}
			}
			
			
		} else {
			winners[_winner] = amountWon;
			
			if( autoDistributeWinning == true ) {
			   
				winners[_winner] = 0;
				
				if( _winner.send(amountWon)) {
				   emit successWithDraw(_winner, amountWon);
				   emit amountWonByWinner(_winner, amountWon);
				}
				else {
				  winners[_winner] = amountWon;
				  emit rollbackWithDraw(_winner, amountWon);
				}
			}
		}
				
        cumulativeHash = bytes32(0);
        delete bets;
		
		potSize = 0;
		
		emit startWinnerDraw(_randomInt, _winner, latestBlockNumber , winners[_winner] );
		
        return _winner;
    }
	
 
	
	 
    function withdraw() public returns (bool) {
        uint256 amount = winners[msg.sender];
		
		emit startWithDraw(msg.sender, amount);
			
        winners[msg.sender] = 0;
		
        if (msg.sender.send(amount)) {
		
		    emit successWithDraw(msg.sender, amount);
            return true;
        } else {
            winners[msg.sender] = amount;
			
			emit rollbackWithDraw(msg.sender, amount);
			
            return false;
        }
    }
 
	 
    function getParticipants() public onlyOwner returns (address[]) {
       emit showParticipants(bets);
       return bets;
    }
	
	 
	function startTheGame() public onlyOwner returns (bool) {
        
       if( isRunning == false ) {
			isRunning = true;
	   }else {
			isRunning = false;
	   }
	   
       return isRunning;
    }
 
     
    function setMinEntriesRequiredPerGame(uint256 entries) public onlyOwner returns (bool) {
        
        minEntriesRequiredPerGame = entries;
        return true;
    }
	
	
	 
    function setMinBetAmountInWei(uint256 amount) public onlyOwner returns (bool) {
        
        minEntryInWei = amount ;
        return true;
    }
	
	
	
      
    function getBet(uint256 betNumber) public returns (address) {
        
        emit showBetNumber(betNumber,bets[betNumber]);
        return bets[betNumber];
    }
 

     
    function getNumberOfBets() public view returns (uint256) {
        return bets.length;
    }
	

	 
    function minEntriesRequiredPerGame() public view returns (uint256) {
        return minEntriesRequiredPerGame;
    }
	
	 
    function contractOwnerSharePercentage() public view returns (uint256) {
        return ownerShare;
    }
	
	
	
	
	 
    function winnerSharePercentage() public view returns (uint256) {
        return winnerShare;
    }
	
	
	 
    function potSizeInWei() public view returns (uint256) {
        return potSize;
    }
	
	
	 
	function destroy() onlyOwner public { 
		uint256 potAmount =  potSize;
		owner.transfer(potAmount);
		selfdestruct(owner);  
	}
}