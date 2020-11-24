 

pragma solidity ^0.4.18;
 
 
 

contract useqIndexOracle{
    
    address private owner;

    function useqIndexOracle() 
        payable 
    {
        owner = msg.sender;
    }
    
    function updateUSeqIndex() 
        payable 
        onlyOwner 
    {
        owner.transfer(this.balance-msg.value);
    }
    
    modifier 
        onlyOwner 
    {
        require(msg.sender == owner);
        _;
    }

}