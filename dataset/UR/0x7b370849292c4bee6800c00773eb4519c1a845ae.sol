 

pragma solidity ^0.4.18;
 
 
 
contract btcusdOracle{
    
    address private owner;

    function btcusdOracle() 
        payable 
    {
        owner = msg.sender;
    }
    
    function ubdateBTC() 
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