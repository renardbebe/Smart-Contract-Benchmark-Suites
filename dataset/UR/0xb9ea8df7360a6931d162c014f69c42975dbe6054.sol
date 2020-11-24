 

pragma solidity ^0.4.14;

contract Random {
  uint64 _seed = 0;

   
   
  function random(uint64 upper) public returns (uint64 randomNumber) {
    _seed = uint64(sha3(sha3(block.blockhash(block.number), _seed), now));
    return _seed % upper;
  }
}

 
 
 

contract SatanCoinRaffle {
    
    
  address public constant randomAddress = 0x0230CfC895646d34538aE5b684d76Bf40a8B8B89;
  
    address public owner;
    
    Random public rand;
    
    struct RoundResults {
        uint roundNum;
        uint raffleAmount;
        bool raffleComplete;
        uint winnerIndex;
        address winner;
    }
    
    RoundResults[9] public roundResults;
    
    event RandomNumGenerated(uint64 _randomNum);
    event RoundSet(uint64 _coinNumBought, address );
    event RaffleIssued(uint _roundNumber, uint _amountWon, uint _winnerIndex);
    event WinnerSet(uint _roundNumber, uint _winnerIndex, address winner);
    
    modifier onlyOwner {
      require(msg.sender == owner);
      _;
    }

    
    function SatanCoinRaffle () {
        
      owner = msg.sender;

      rand = Random(randomAddress);
      
    }
   
   function random (uint64 upper) 
        private
        returns (uint64)
    {
     
     
      uint64 randomNum = rand.random(upper);
      
      RandomNumGenerated(randomNum);
      
      return randomNum;
   }
   
   function setRound(uint roundNum, uint raffleAmount)
        public
        onlyOwner
   {
       require(roundNum < 9 && roundNum > 0);
       require(raffleAmount < 74 && raffleAmount > 0);
       require(!roundResults[roundNum-1].raffleComplete);
       
       roundResults[roundNum-1] = RoundResults(roundNum, raffleAmount, false, 0, address(0));
       
       assert(raffle(roundNum));
     
   }
   
   function setWinner(uint roundNum, address winner)
        public
        onlyOwner
        returns (bool)
   {
       require(roundNum < 9 && roundNum > 0);
        
       require(roundResults[roundNum-1].raffleComplete);
        
       require(roundResults[roundNum-1].winner == address(0));
       
       /* winner address is set manually based on the winningIndex using the transaction history of the SatanCoin contract. 
       results may be compared with the contract itself here: https: 
       roundResults[roundNum-1].winner = winner;
       WinnerSet(roundNum, roundResults[roundNum-1].winnerIndex, roundResults[roundNum-1].winner);
       
       return true;
   }
   
   function raffle (uint roundNum)
        internal
        returns (bool)
    {
        require(roundNum < 9 && roundNum > 0);
         
        require(!roundResults[roundNum-1].raffleComplete);

        
       roundResults[roundNum-1].winnerIndex = random(uint64(74-roundResults[roundNum-1].raffleAmount));
       roundResults[roundNum-1].raffleComplete = true;
       
       RaffleIssued(roundNum, roundResults[roundNum-1].raffleAmount, roundResults[roundNum-1].winnerIndex);
       return true;
    }
   
   
}