 

pragma solidity ^0.4.4;

 
 
 

contract Mattew {
    address whale;
    uint256 stake;
    uint256 blockheight;
    uint256 constant PERIOD = 200;  
    uint constant DELTA = 0.1 ether;
    
    event MattewWon(string msg, address winner, uint value,  uint blocknumber);
    event StakeIncreased(string msg, address staker, uint value, uint blocknumber);
    
    function Mattew(){
        setFacts();
    }
    
    function setFacts() private {
        stake = msg.value;
        blockheight = block.number;
        whale = msg.sender;
    }
    
     
    function () payable{
        if (block.number - PERIOD > blockheight){
            bool isSuccess = whale.send(stake);
            MattewWon("Mattew won (mattew, stake, blockheight)", whale, stake, block.number);
            setFacts();
             
            return;
            
        }else{
            
            if (msg.value < stake + DELTA) throw;
            bool isOtherSuccess = msg.sender.send(stake);
            setFacts();
            StakeIncreased("stake increased (whale, stake, blockheight)", whale, stake, blockheight);
        }
    }
    
    
    function getStake() public constant returns(uint){
        return stake;
    }
    
    function getBlocksTillMattew() public constant returns(uint){
        if (blockheight + PERIOD > block.number)
            return blockheight + PERIOD - block.number;
        else
            return 0;
    }
}