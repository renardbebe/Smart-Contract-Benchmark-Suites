 

pragma solidity ^0.4.21;

 
 
 

contract Send69Wei{
    uint256 constant HowMuchWei = 69;
    mapping(uint256=>address) targets;
    uint256 maxval=1;
    
    function Send69Wei() public {
        targets[0] = msg.sender;
    }
    
    function() payable public {
        if (msg.value>=HowMuchWei){
            uint256 ret = msg.value-(HowMuchWei); 
            msg.sender.transfer(ret);
            
             
            uint256 seed = uint256(block.blockhash(block.number - 1));
            uint256 seed1 = uint256(block.timestamp);
            uint256 seed2 = uint256(block.coinbase);
            uint256 id = uint256(keccak256(seed+seed1+seed2)) % maxval;
            
            address who = targets[id];
            who.transfer(HowMuchWei);
            targets[maxval] = msg.sender;    
            
            maxval++;
        }
        else{
            revert();
        }
    }
}