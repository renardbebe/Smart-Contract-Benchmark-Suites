 

pragma solidity ^0.4.25;

 

contract EthereumMultiplier {
     
    address constant private Reclame = 0x37Ef79eFAEb515EFC1fecCa00d998Ded73092141;
     
    uint constant public Reclame_PERCENT = 2; 
     
    address constant private Admin = 0x942Ee0aDa641749861c47E27E6d5c09244E4d7c8;
     
    uint constant public Admin_PERCENT = 2;
     
    address constant private BMG = 0x60d23A4F6642869C04994C818A2dDE5a1bf2c217;
     
    uint constant public BMG_PERCENT = 2;
     
    uint constant public Refferal_PERCENT = 10;
     
     
    uint constant public MULTIPLIER = 110;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

    Deposit[] private queue;   
    uint public currentReceiverIndex = 0;  

     
     
    function () public payable {
        require(tx.gasprice <= 50000000000 wei, "Gas price is too high! Do not cheat!");
        if(msg.value > 110){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value <= 5 ether);  

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/110)));

             
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
            require(msg.value <= 5 ether);  

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*MULTIPLIER/110)));

             
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