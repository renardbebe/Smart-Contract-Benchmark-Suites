 

pragma solidity ^0.4.25;

 


 
contract Multy {

	 
    address constant private PROMO = 0xa3093FdE89050b3EAF6A9705f343757b4DfDCc4d;
	address constant private PRIZE = 0x86C1185CE646e549B13A6675C7a1DF073f3E3c0A;
	
	 
    uint constant public PROMO_PERCENT = 6;
    
     
    uint constant public BONUS_PERCENT = 4;
		
     
    struct Deposit {
        address depositor;  
        uint deposit;    
        uint payout;  
    }

    Deposit[] public queue;   
    mapping (address => uint) public depositNumber;  
    uint public currentReceiverIndex;  
    uint public totalInvested;  

     
     
    function () public payable {
        
        require(block.number >= 6655835);

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.05 ether && msg.value <= 10 ether);  
            
             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            uint promo = msg.value*PROMO_PERCENT/100;
            PROMO.send(promo);
            uint prize = msg.value*BONUS_PERCENT/100;
            PRIZE.send(prize);
            
             
            pay();

        }
    }

     
     
     
    function pay() internal {

        uint money = address(this).balance;
        uint multiplier = 150;

         
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
    
     
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<queue.length; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

     
    function getQueueLength() public view returns (uint) {
        return queue.length - currentReceiverIndex;
    }

}