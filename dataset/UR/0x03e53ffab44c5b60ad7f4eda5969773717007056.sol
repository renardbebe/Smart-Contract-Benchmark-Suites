 

pragma solidity ^0.4.18;
 
 
 
 
contract useqvolOracle{
    
    address private owner;

    function useqvolOracle() 
        payable 
    {
        owner = msg.sender;
    }
    
    function updateUSeqvol()
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