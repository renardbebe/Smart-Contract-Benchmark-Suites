 

pragma solidity ^0.4.6;

 
 
 

contract Matthew {
    address owner;
    address whale;
    uint256 blockheight;
    uint256 period = 18;  
    uint constant DELTA = 0.1 ether;
    uint constant WINNERTAX_PRECENT = 10;
    bool mustBeDestroyed = false;
    uint newPeriod = 5;
    
    event MatthewWon(string msg, address winner, uint value,  uint blocknumber);
    event StakeIncreased(string msg, address staker, uint value, uint blocknumber);
    
    function Matthew(){
        owner = msg.sender;
        setFacts();
    }
    
    function setFacts() private {
        period = newPeriod;
        blockheight = block.number;
        whale = msg.sender;
    }
    
     
    function () payable{
    
        if (block.number - period >= blockheight){  
            bool isSuccess=false;  
            var nextStake = this.balance * WINNERTAX_PRECENT/100;   
            if (isSuccess == false)  
                isSuccess = whale.send(this.balance - nextStake);  
            MatthewWon("Matthew won", whale, this.balance, block.number);
            setFacts(); 
            if (mustBeDestroyed) selfdestruct(whale); 
            return;
            
        }else{  
            if (msg.value < this.balance + DELTA) throw;  
            bool isOtherSuccess = msg.sender.send(this.balance);  
            setFacts();  
            StakeIncreased("stake increased", whale, this.balance, blockheight);
        }
    }
    
     
    function destroyWhenRoundOver() onlyOwner{
        mustBeDestroyed = true;
    }
    
     
    function setNewPeriod(uint _newPeriod) onlyOwner{
        newPeriod = _newPeriod;
    }
    
    function getPeriod() constant returns (uint){
        period;
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