 

pragma solidity ^0.4.25;

 


 
contract EternalMultiplier {

     
    struct Deposit {
        address depositor;  
        uint deposit;    
        uint payout;  
    }

    uint public roundDuration = 256;
    
    mapping (uint => Deposit[]) public queue;   
    mapping (uint => mapping (address => uint)) public depositNumber;  
    mapping (uint => uint) public currentReceiverIndex;  
    mapping (uint => uint) public totalInvested;  

    address public support = msg.sender;
    mapping (uint => uint) public amountForSupport;

     
     
    function () public payable {
        require(block.number >= 6617925);
        require(block.number % roundDuration < roundDuration - 20);
        uint stage = block.number / roundDuration;

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.1 ether && msg.value <= calcMaxDeposit(stage));  
            require(depositNumber[stage][msg.sender] == 0);  

             
            queue[stage].push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[stage][msg.sender] = queue[stage].length;

            totalInvested[stage] += msg.value;

             
            if (amountForSupport[stage] < 5 ether) {
                uint fee = msg.value / 5;
                amountForSupport[stage] += fee;
                support.transfer(fee);
            }

             
            pay(stage);

        }
    }

     
     
     
    function pay(uint stage) internal {

        uint money = address(this).balance;
        uint multiplier = calcMultiplier(stage);

         
        for (uint i = 0; i < queue[stage].length; i++){

            uint idx = currentReceiverIndex[stage] + i;   

            Deposit storage dep = queue[stage][idx];  

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

                 
                depositNumber[stage][dep.depositor] = 0;
                delete queue[stage][idx];

            } else{

                 
                dep.depositor.send(money);  
                dep.payout += money;        
                break;                      

            }

            if (gasleft() <= 55000) {          
                break;                        
            }
        }

        currentReceiverIndex[stage] += i;  
    }

     
    function getQueueLength() public view returns (uint) {
        uint stage = block.number / roundDuration;
        return queue[stage].length - currentReceiverIndex[stage];
    }

     
    function calcMaxDeposit(uint stage) public view returns (uint) {

        if (totalInvested[stage] <= 20 ether) {
            return 0.5 ether;
        } else if (totalInvested[stage] <= 50 ether) {
            return 0.7 ether;
        } else if (totalInvested[stage] <= 100 ether) {
            return 1 ether;
        } else if (totalInvested[stage] <= 200 ether) {
            return 1.5 ether;
        } else {
            return 2 ether;
        }

    }

     
    function calcMultiplier(uint stage) public view returns (uint) {

        if (totalInvested[stage] <= 20 ether) {
            return 130;
        } else if (totalInvested[stage] <= 50 ether) {
            return 120;
        } else if (totalInvested[stage] <= 100 ether) {
            return 115;
        } else if (totalInvested[stage] <= 200 ether) {
            return 112;
        } else {
            return 110;
        }

    }

}