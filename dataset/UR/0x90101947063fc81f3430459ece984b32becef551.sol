 

pragma solidity ^0.4.25;

 
 

contract Multiplier3 {
     
    address constant private TECH = 0x2392169A23B989C053ECED808E4899c65473E4af;
     
    address constant private PROMO_AND_PRIZE = 0xdA149b17C154e964456553C749B7B4998c152c9E;
     
    uint constant public TECH_PERCENT = 1;
    uint constant public PROMO_AND_PRIZE_PERCENT = 6;
    uint constant public MAX_INVESTMENT = 10 ether;

     
    uint constant public MULTIPLIER = 117;

     
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
            require(msg.value <= MAX_INVESTMENT);  

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

             
            uint adv = msg.value*PROMO_AND_PRIZE_PERCENT/100;
            PROMO_AND_PRIZE.send(adv);
             
            uint support = msg.value*TECH_PERCENT/100;
            TECH.send(support);

             
            pay();
        }
    }

     
     
     
    function pay() private {
         
        uint128 money = uint128(address(this).balance);

         
        for(uint i=currentReceiverIndex; i<queue.length; i++){

            Deposit storage dep = queue[i];  

            if(money >= dep.expect){   
                dep.depositor.send(dep.expect);  
                money -= dep.expect;             

                 
                delete queue[i];
            }else{
                 
                dep.depositor.send(money);  
                dep.expect -= money;        
                break;                      
            }

            if(gasleft() <= 50000)          
                break;                      
        }

        currentReceiverIndex = i;  
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