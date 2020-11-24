 

pragma solidity ^0.4.18;

 
 
 


 


contract Splitter {
    address public owner;    
    address public payee = 0xAc71D3aC1fd7a56f731fb28E5F582cC6042cB61B;    
    uint    public percent = 10;  
    
     
     
    function Splitter() public {
        owner   = msg.sender;
    }
    
     
     
    function Withdraw() external {
        require(msg.sender == owner);
        owner.transfer(this.balance);
    }
    
     
     
    function() external payable {
        owner.transfer(msg.value * percent / 100);
        payee.transfer(msg.value * (100 - percent) / 100);
    }
}