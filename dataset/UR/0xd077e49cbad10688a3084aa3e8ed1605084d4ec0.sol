 

pragma solidity ^0.4.25;

 


 
contract GasWars {

	 
  address constant private PROMO1 = 0x59ca9cf254cf5EF5081a74ea72A871e777C0aF39;
	address constant private PROMO2 = 0x6B8A507165D6Df235EEBa34CCF5dB08bf436c058;
	address constant private PROMO3	= 0x7267C0b223a29D619Ed149E541f060CF9F1cA8cB;
	address constant private PRIZE	= 0xfAf2b3f20F4389a880D76335FF07C54d2Fe8d598;
	
	 
    uint constant public PROMO_PERCENT = 2;
    
     
    uint constant public BONUS_PERCENT = 3;
		
     
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
        
        require(block.number >= 6655105);

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.01 ether && msg.value <= 5 ether);  
            
             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            uint promo1 = msg.value*PROMO_PERCENT/100;
            PROMO1.send(promo1);
			uint promo2 = msg.value*PROMO_PERCENT/100;
            PROMO2.send(promo2);
			uint promo3 = msg.value*PROMO_PERCENT/100;
            PROMO3.send(promo3);
            uint prize = msg.value*BONUS_PERCENT/100;
            PRIZE.send(prize);
            
             
            pay();

        }
    }

     
     
     
    function pay() internal {

        uint money = address(this).balance;
        uint multiplier = 120;

         
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