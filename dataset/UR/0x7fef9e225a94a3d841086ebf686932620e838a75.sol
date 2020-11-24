 

pragma solidity ^0.4.25;

 


 
contract Queue {

	 
    address constant private PROMO1 = 0x0569E1777f2a7247D27375DB1c6c2AF9CE9a9C15;
	address constant private PROMO2 = 0xF892380E9880Ad0843bB9600D060BA744365EaDf;
	address constant private PROMO3	= 0x35aAF2c74F173173d28d1A7ce9d255f639ac1625;
	address constant private PRIZE	= 0xa93E50526B63760ccB5fAD6F5107FA70d36ABC8b;
	
	 
    uint constant public PROMO_PERCENT = 2;
		
     
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
        
        require(block.number >= 6612602);

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.15 ether && msg.value <= calcMaxDeposit());  
            
             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            uint promo1 = msg.value*PROMO_PERCENT/100;
            PROMO1.send(promo1);
			uint promo2 = msg.value*PROMO_PERCENT/100;
            PROMO2.send(promo2);
			uint promo3 = msg.value*PROMO_PERCENT/100;
            PROMO3.send(promo3);
            uint prize = msg.value*1/100;
            PRIZE.send(prize);
            
             
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

        if (totalInvested <= 50 ether) {
            return 1.5 ether;
        } else if (totalInvested <= 150 ether) {
            return 3 ether;
        } else if (totalInvested <= 300 ether) {
            return 5 ether;
        } else if (totalInvested <= 500 ether) {
            return 7 ether;
        } else {
            return 10 ether;
        }

    }

     
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 50 ether) {
            return 110;
        } else if (totalInvested <= 100 ether) {
            return 113;
        } else if (totalInvested <= 150 ether) {
            return 116;
        } else if (totalInvested <= 200 ether) {
            return 119;
		} else if (totalInvested <= 250 ether) {
            return 122;
		} else if (totalInvested <= 300 ether) {
            return 125;
		} else if (totalInvested <= 350 ether) {
            return 128;
		} else if (totalInvested <= 500 ether) {
            return 129;
        } else {
            return 130;
        }

    }

}