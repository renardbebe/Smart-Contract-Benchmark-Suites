 

pragma solidity ^0.4.25;

 


 
contract BestMultiplierV2 {

     
    struct Deposit {
        address depositor;  
        uint deposit;    
        uint payout;  
    }

    Deposit[] public queue;   
    mapping (address => uint) public depositNumber;  
    uint public currentReceiverIndex;  
    uint public totalInvested;  

    address public support = msg.sender;
    uint public amountForSupport;

     
     
    function () public payable {

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.01 ether && msg.value <= calcMaxDeposit());  
            require(depositNumber[msg.sender] == 0);  

             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            if (amountForSupport < 5 ether) {
                amountForSupport += msg.value / 10;
                support.transfer(msg.value / 10);
            }

             
            pay();

        }
    }

     
     
     
    function pay() internal {

        uint money = address(this).balance;
        uint multiplier = calcMultiplier();

         
        for (uint i = 0; i < queue.length; i++){

            uint idx = currentReceiverIndex + i;   

            Deposit storage dep = queue[idx];  

            uint totalPayout = dep.deposit * multiplier / 100;
            uint leftPayout;

            if (totalPayout > dep.payout) {
                leftPayout = totalPayout - dep.payout;
            }

            if (money >= leftPayout) {  

                if (leftPayout > 0) {
                    dep.depositor.send(leftPayout);  
                    money -= leftPayout;
                }

                 
                depositNumber[dep.depositor] = 0;
                delete queue[idx];

            } else{

                 
                dep.depositor.send(money);  
                dep.payout += money;        
                break;                      

            }

            if (gasleft() <= 55000) {          
                break;                        
            }
        }

        currentReceiverIndex += i;  
    }

     
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
    }

     
    function calcMaxDeposit() public view returns (uint) {

        if (totalInvested <= 100 ether) {
            return 2.5 ether;
        } else if (totalInvested <= 250 ether) {
            return 5 ether;
        } else if (totalInvested <= 500 ether) {
            return 10 ether;
        } else if (totalInvested <= 1000 ether) {
            return 15 ether;
        } else {
            return 20 ether;
        }

    }

     
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 100 ether) {
            return 130;
        } else if (totalInvested <= 250 ether) {
            return 125;
        } else if (totalInvested <= 500 ether) {
            return 120;
        } else if (totalInvested <= 1000 ether) {
            return 110;
        } else {
            return 105;
        }

    }

}