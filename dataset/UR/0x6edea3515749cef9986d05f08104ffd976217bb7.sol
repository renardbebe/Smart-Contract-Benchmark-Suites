 

pragma solidity ^0.4.25;

 


 
contract BestMultiplierV3 {

     
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
        require(block.number >= 6611804);

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.01 ether && msg.value <= calcMaxDeposit());  
            require(depositNumber[msg.sender] == 0);  

             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            if (amountForSupport < 10 ether) {
                uint fee = msg.value / 5;
                amountForSupport += fee;
                support.transfer(fee);
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

        if (totalInvested <= 20 ether) {
            return 1 ether;
        } else if (totalInvested <= 50 ether) {
            return 1.2 ether;
        } else if (totalInvested <= 100 ether) {
            return 1.4 ether;
        } else if (totalInvested <= 200 ether) {
            return 1.7 ether;
        } else {
            return 2 ether;
        }

    }

     
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 20 ether) {
            return 120;
        } else if (totalInvested <= 50 ether) {
            return 117;
        } else if (totalInvested <= 100 ether) {
            return 115;
        } else if (totalInvested <= 200 ether) {
            return 113;
        } else {
            return 110;
        }

    }

}