 

pragma solidity ^0.4.18;
 
 
 
contract ethusdOracle{
    
    address private owner;

    function ethusdOracle() 
        payable 
    {
        owner = msg.sender;
    }
    
    function updateETH() 
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