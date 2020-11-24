 

pragma solidity ^0.4.5;

contract PPBC_API {

    

    
    

     
    address paddyAdmin;           
    uint256 public gamesPlayed;   
    
    mapping ( address => bool ) alreadyPlayed;  
                                                
                                                

     
     
     
    function GetMinimumBet_Ether() constant returns (uint256){ return 1;   }
    function GetMaximumBet_Ether() constant returns (uint256){ return GetMaximumBet() / 1000000000000000000;  } 
    function GetMinimumBet() returns (uint256) { return 1 ether; }    
    function GetMaximumBet() returns (uint256) { return this.balance/10; }    

     
     
    
    function _api_PlaceBet () payable {
     
         
         
         
         
         
         
        
         
        if (msg.value < GetMinimumBet() || (msg.value + 1) > GetMaximumBet() ) throw; 
        
         
        uint256 cntBlockUsed = blockUsed[block.number];  
        if (cntBlockUsed > maxGamesPerBlock) throw; 
        blockUsed[block.number] = cntBlockUsed + 1; 
          
        gamesPlayed++;             
        lastPlayer = msg.sender;   
         
        
         
        uint winnerOdds = 3;   
        uint totalPartition  = 5;  
        
        if (alreadyPlayed[msg.sender]){   
            winnerOdds = 2; 
        }
        
        alreadyPlayed[msg.sender] = true;  
        
         
        winnerOdds = winnerOdds * 20;   
        totalPartition = totalPartition * 20;     
         
        
         
        uint256 random = createRandomNumber(totalPartition);  

         
        if (random <= winnerOdds ){
            if (!msg.sender.send(msg.value * 2))  
                throw;  
        }
         
    }


       
      
     

    address lastPlayer;
    uint256 private seed1;
    uint256 private seed2;
    uint256 private seed3;
    uint256 private seed4;
    uint256 private seed5;
    uint256 private lastBlock;
    uint256 private lastRandom;
    uint256 private lastGas;
    uint256 private customSeed;
    
    function createRandomNumber(uint maxnum) payable returns (uint256) {
        uint cnt;
        for (cnt = 0; cnt < lastRandom % 5; cnt++){lastBlock = lastBlock - block.timestamp;}  
        uint256 random = 
                  block.difficulty + block.gaslimit + 
                  block.timestamp + msg.gas + 
                  msg.value + tx.gasprice + 
                  seed1 + seed2 + seed3 + seed4 + seed5;
        random = random + uint256(block.blockhash(block.number - (lastRandom+1))[cnt]) +
                  (gamesPlayed*1234567890) * lastBlock + customSeed;
        random = random + uint256(lastPlayer) +  uint256(sha3(msg.sender)[cnt]);
        lastBlock = block.number;
        seed5 = seed4; seed4 = seed3; seed3 = seed2;
        seed2 = seed1; seed1 = (random / 43) + lastRandom; 
        bytes32 randomsha = sha3(random);
        lastRandom = (uint256(randomsha[cnt]) * maxnum) / 256;
        
        return lastRandom ;
        
    }
    
    
     
     
     
    uint256 public maxGamesPerBlock;   
    mapping ( uint256 => uint256 ) blockUsed;   
                                                
    
    function PPBC_API()  {  
         
        gamesPlayed = 0;
        paddyAdmin = msg.sender;
        lastPlayer = msg.sender;
        seed1 = 2; seed2 = 3; seed3 = 5; seed4 = 7; seed5 = 11;
        lastBlock = 0;
        customSeed = block.number;
        maxGamesPerBlock = 3;
    }
    
    modifier onlyOwner {
        if (msg.sender != paddyAdmin) throw;
        _;
    }

    function _maint_withdrawFromPool (uint256 amt) onlyOwner{  
            if (!paddyAdmin.send(amt)) throw;
    }
    
    function () payable onlyOwner {  
    }
    
    function _maint_EndPromo () onlyOwner {
         selfdestruct(paddyAdmin); 
    }

    function _maint_setBlockLimit (uint256 n_limit) onlyOwner {
         maxGamesPerBlock = n_limit;
    }
    
    function _maint_setCustomSeed(uint256 newSeed) onlyOwner {
        customSeed = newSeed;
    }
    
    function _maint_updateOwner (address newOwner) onlyOwner {
        paddyAdmin = newOwner;
    }
    
}