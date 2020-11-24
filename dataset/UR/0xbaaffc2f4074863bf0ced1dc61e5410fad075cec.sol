 

 
 
 
 
 
 

pragma solidity ^0.4.19;

 
 
 
 
 
 


contract sendlimiter{
 function () public payable {
     require(this.balance + msg.value < 100000000);}
}