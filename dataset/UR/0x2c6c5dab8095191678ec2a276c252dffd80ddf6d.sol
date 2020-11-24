 

pragma solidity ^0.4.25;

 

contract GradualPro {
     
    address constant private FIRST_SUPPORT = 0xf8F04b23dACE12841343ecf0E06124354515cc42;

     
    address constant private TECH_SUPPORT = 0x988f1a2fb17414c95f45E2DAaaA40509F5C9088c;

     
    uint constant public FIRST_PERCENT = 4;

     
    uint constant public TECH_PERCENT = 1;
    
     
    uint constant public MULTIPLIER = 121;

     
    uint constant public MAX_LIMIT = 2 ether;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

     
    Deposit[] private queue;

     
    uint public currentReceiverIndex = 0;

     
    function () public payable {
         
        if(msg.value > 0){
             
            require(gasleft() >= 220000, "We require more gas!");

             
            require(msg.value <= MAX_LIMIT, "Deposit is too big");

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value * MULTIPLIER / 100)));

             
            uint ads = msg.value * FIRST_PERCENT / 100;
            FIRST_SUPPORT.transfer(ads);

             
            uint tech = msg.value * TECH_PERCENT / 100;
            TECH_SUPPORT.transfer(tech);

             
            pay();
        }
    }

     
     
     
    function pay() private {
         
        uint128 money = uint128(address(this).balance);

         
        for(uint i = 0; i < queue.length; i++) {

            uint idx = currentReceiverIndex + i;   

            Deposit storage dep = queue[idx];  

            if(money >= dep.expect) {   
                dep.depositor.transfer(dep.expect);  
                money -= dep.expect;  

                 
                delete queue[idx];
            } else {
                 
                dep.depositor.transfer(money);  
                dep.expect -= money;        
                break;                      
            }

            if (gasleft() <= 50000)          
                break;                      
        }

        currentReceiverIndex += i;  
    }

     
     
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

     
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

     
    function getDeposits(address depositor) public view returns (uint[] idxs, uint128[] deposits, uint128[] expects) {
        uint c = getDepositsCount(depositor);

        idxs = new uint[](c);
        deposits = new uint128[](c);
        expects = new uint128[](c);

        if(c > 0) {
            uint j = 0;
            for(uint i=currentReceiverIndex; i<queue.length; ++i){
                Deposit storage dep = queue[i];
                if(dep.depositor == depositor){
                    idxs[j] = i;
                    deposits[j] = dep.deposit;
                    expects[j] = dep.expect;
                    j++;
                }
            }
        }
    }
    
     
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
    }

}