 

pragma solidity ^0.4.8;                   
 

contract Josephtoken {                      
    
    address owner;                        
    mapping (address => uint) balances;   
    
    function Josephtoken() public {
        owner = msg.sender;               
                                          
        balances[owner] = 1000;           
    }
    
    function transfer(uint amount, address recipient) public {       
        require(balances[msg.sender] >= amount);
        require(balances[msg.sender] - amount <= balances[msg.sender]);
        require(balances[recipient] + amount >= balances[recipient]);
        balances[msg.sender] -= amount;
        balances[recipient] += amount;
         
    }
}