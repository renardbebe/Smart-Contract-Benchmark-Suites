 

pragma solidity ^0.4.25;

 

contract MMMultiplierX {

     
    uint constant public MULTIPLIER = 200;
    uint totalIn;
    uint public maxDep = (100000000000000000000+totalIn)/100;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

    Deposit[] private queue;   
    uint  currentReceiverIndex = 0;  

     
     
    function () public payable {
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value <= maxDep);  

            totalIn += msg.value;

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

             
            pay();
        }
    }

     
     
     
    function pay() private {
         
        uint128 money = uint128(address(this).balance);

         
        for(uint i=0; i<queue.length; i++){

            uint idx = currentReceiverIndex + i;   

            Deposit storage dep = queue[idx];  

            if(money >= dep.expect){   
                dep.depositor.send(dep.expect);  
                money -= dep.expect;             

                 
                delete queue[idx];
            }else{
                 
                dep.depositor.send(money);  
                dep.expect -= money;        
                break;                      
            }

            if(gasleft() <= 50000)          
                break;                      
        }

        currentReceiverIndex += i;  
    }


}