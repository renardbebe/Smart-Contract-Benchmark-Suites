 

pragma solidity ^0.4.18;
 
 
 
contract useqgretOracle{
    
    address private owner;

    function useqgretOracle() 
        payable 
    {
        owner = msg.sender;
    }
    
    function updateUSeqgret() 
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