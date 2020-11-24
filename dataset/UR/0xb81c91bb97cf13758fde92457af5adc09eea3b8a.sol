 

pragma solidity ^0.4.18;

 
 
 
 
 
 
 
 
 
 

contract IEFBR14Contract {
   address public owner;        
   address[] public users;      
   address[] public sponsors;   
   
   event IEF403I(address submitter);
   event IEF404I(address submitter);
   event S222(address operator);
   event IEE504I(address sponsor, uint value);

   function IEFBR14Contract() public payable{
       owner = msg.sender;
   }

   function IEFBR14()  public{
        
       IEF403I(msg.sender);
       users.push(msg.sender);
       IEF404I(msg.sender);       
   }

   function Cancel() public{
        
       require(msg.sender == owner);
       selfdestruct(owner);
       S222(msg.sender);
   }

   function Sponsor() payable public{
        
       IEE504I(msg.sender, msg.value);
       sponsors.push(msg.sender);
       owner.transfer(msg.value);
   }
}