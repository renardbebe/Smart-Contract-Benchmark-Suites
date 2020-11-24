 

pragma solidity ^0.4.25;

 

contract BestMultiplierNew {
     
    address constant private Reclame = 0x0646682283188b2867f61CE0BD5259E7d68748d5;
     
    uint constant public Reclame_PERCENT = 3; 
     
    address constant private Admin = 0xC7FCc602088b49c816b1A36848f62c35516F0F8B;
     
    uint constant public Admin_PERCENT = 1;
     
    address constant private BMG = 0xDe67C0Bc07a16f120dFB7E660359c1e10A548d53;
     
    uint constant public BMG_PERCENT = 2;
     
    uint constant public Refferal_PERCENT = 10;
     
     
    uint constant public MULTIPLIER = 121;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

    Deposit[] private queue;   
    uint public currentReceiverIndex = 0;  

     
     
    function () public payable {
        require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value <= 10 ether);  

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

             
            uint promo = msg.value*Reclame_PERCENT/100;
            Reclame.send(promo);
            uint admin = msg.value*Admin_PERCENT/100;
            Admin.send(admin);
            uint bmg = msg.value*BMG_PERCENT/100;
            BMG.send(bmg);

             
            pay();
        }
    
    }
        function refferal (address REF) public payable {
        require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value <= 10 ether);  

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/100)));

             
            uint promo = msg.value*Reclame_PERCENT/100;
            Reclame.send(promo);
            uint admin = msg.value*Admin_PERCENT/100;
            Admin.send(admin);
            uint bmg = msg.value*BMG_PERCENT/100;
            BMG.send(bmg);
            require(REF != 0x0000000000000000000000000000000000000000 && REF != msg.sender, "You need another refferal!");  
            uint ref = msg.value*Refferal_PERCENT/100;
            REF.send(ref);
             
            pay();
        }
    
    }
     
     
     
    function pay() private {
         
        uint128 money = uint128(address(this).balance);

         
        for(uint i=0; i<queue.length; i++){

            uint idx = currentReceiverIndex + i;   

            Deposit storage dep = queue[idx];  

            if(money >= dep.expect){   
                dep.depositor.send(dep.expect);  
                money -= dep.expect;             

                 
                delete queue[idx];
            }else{
                 
                dep.depositor.send(money);  
                dep.expect -= money;        
                break;                      
            }

            if(gasleft() <= 50000)          
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