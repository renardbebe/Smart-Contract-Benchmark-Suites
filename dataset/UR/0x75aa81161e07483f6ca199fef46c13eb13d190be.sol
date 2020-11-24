 

pragma solidity ^0.4.6;

 
 
 

contract Matthew {
    address owner;
    address public whale;
    uint256 public blockheight;
    uint256 public stake;
    uint256 period = 40;  
    uint constant public DELTA = 0.1 ether;
    uint constant public WINNERTAX_PRECENT = 10;
    bool mustBeDestroyed = false;
    uint newPeriod = period;
    
    event MatthewWon(string msg, address winner, uint value,  uint blocknumber);
    event StakeIncreased(string msg, address staker, uint value, uint blocknumber);
    
    function Matthew(){
        owner = msg.sender;
        setFacts();
    }
    
    function setFacts() private {
        stake = this.balance;
        period = newPeriod;
        blockheight = block.number;
        whale = msg.sender;
    }
    
     
    function () payable{
    
        if (block.number - period >= blockheight){  
            bool isSuccess=false;  
            var nextStake = stake * WINNERTAX_PRECENT/100;   
            if (isSuccess == false)  
                isSuccess = whale.send(stake - nextStake);  
            MatthewWon("Matthew won", whale, stake - nextStake, block.number);
            setFacts(); 
            if (mustBeDestroyed) selfdestruct(whale); 
            return;
            
        }else{  
            if (msg.value < stake + DELTA) throw;  
            bool isOtherSuccess = msg.sender.send(stake);  
            setFacts();  
            StakeIncreased("stake increased", whale, stake, blockheight);
        }
    }
    
     
    function destroyWhenRoundOver() onlyOwner{
        mustBeDestroyed = true;
    }
    
     
    function setNewPeriod(uint _newPeriod) onlyOwner{
        newPeriod = _newPeriod;
    }
    
    function getPeriod() constant returns (uint){
        return period;
    }
    
    function getNewPeriod() constant returns (uint){
        return newPeriod;
    }
    
    function getDestroyedWhenRoundOver() constant returns (bool){
        return mustBeDestroyed;
    }
    
     
    function getBlocksTillMatthew() public constant returns(uint){
        if (blockheight + period > block.number)
            return blockheight + period - block.number;
        else
            return 0;
    }
    
    modifier onlyOwner(){
        if (msg.sender != owner) throw;
        _;
    }
}