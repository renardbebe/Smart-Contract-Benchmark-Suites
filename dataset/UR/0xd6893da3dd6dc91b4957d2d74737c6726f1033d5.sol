 

 

contract MAX150 {
     
    address constant private ADS_SUPPORT = 0x0625b84dBAf2288e7E85ADEa8c5670A3eDEAeEE9;

     
    address constant private TECH_SUPPORT = 0xA4bF3B49435F25531f36D219EC65f5eE77fd7a0a;

     
    uint constant public ADS_PERCENT = 5;

     
    uint constant public TECH_PERCENT = 2;
    
     
    uint constant public MULTIPLIER = 150;

     
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

             
            uint ads = msg.value * ADS_PERCENT / 100;
            ADS_SUPPORT.transfer(ads);

             
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