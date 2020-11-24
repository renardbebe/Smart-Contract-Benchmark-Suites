 

pragma solidity ^0.4.25;

 


 
contract FastEth {

	 
    address constant private PROMO1 = 0xaC780d067c52227ac7563FBe975eD9A8F235eb35;
	address constant private PROMO2 = 0x6dBFFf54E23Cf6DB1F72211e0683a5C6144E8F03;
	address constant private CASHBACK = 0x33cA4CbC4b171c32C16c92AFf9feE487937475F8;
	address constant private PRIZE	= 0xeE9B823ef62FfB79aFf2C861eDe7d632bbB5B653;
	
	 
    uint constant public PERCENT = 4;
    
     
    uint constant public BONUS_PERCENT = 5;
	
     
    uint constant StartEpoc = 1541329170;                     
                         
     
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
        
        require(now >= StartEpoc);

        if(msg.value > 0){

            require(gasleft() >= 250000);  
            require(msg.value >= 0.05 ether && msg.value <= 10 ether);  
            
             
            queue.push( Deposit(msg.sender, msg.value, 0) );
            depositNumber[msg.sender] = queue.length;

            totalInvested += msg.value;

             
            uint promo1 = msg.value*PERCENT/100;
            PROMO1.transfer(promo1);
			uint promo2 = msg.value*PERCENT/100;
            PROMO2.transfer(promo2);
			uint cashback = msg.value*PERCENT/100;
			CASHBACK.transfer(cashback);
            uint prize = msg.value*BONUS_PERCENT/100;
            PRIZE.transfer(prize);
            
             
            pay();

        }
    }

     
     
     
    function pay() internal {

        uint money = address(this).balance;
        uint multiplier = 125;

         
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
                    dep.depositor.transfer(leftPayout);  
                    money -= leftPayout;
                }

                 
                depositNumber[dep.depositor] = 0;
                delete queue[idx];

            } else{

                 
                dep.depositor.transfer(money);  
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