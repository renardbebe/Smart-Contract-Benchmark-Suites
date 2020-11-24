 

pragma solidity ^0.4.25;

 


contract EthmoonV3 {
     
    address constant private PROMO = 0xa4Db4f62314Db6539B60F0e1CBE2377b918953Bd;
    address constant private SMARTCONTRACT = 0xa4Db4f62314Db6539B60F0e1CBE2377b918953Bd;
    address constant private STARTER = 0x5dfE1AfD8B7Ae0c8067dB962166a4e2D318AA241;
     
    uint constant public PROMO_PERCENT = 5;
    uint constant public SMARTCONTRACT_PERCENT = 5;
     
    uint constant public START_MULTIPLIER = 115;
     
    uint constant public MIN_DEPOSIT = 0.21 ether;
    uint constant public MAX_DEPOSIT = 5 ether;
    bool public started = false;
     
    mapping(address => uint) public participation;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

    Deposit[] private queue;   
    uint public currentReceiverIndex = 0;  

     
     
    function () public payable {
        require(gasleft() >= 250000, "We require more gas!");  
        require(msg.sender != SMARTCONTRACT);
        require((msg.sender == STARTER) || (started));
        
        if (msg.sender != STARTER) {
            require((msg.value >= MIN_DEPOSIT) && (msg.value <= MAX_DEPOSIT));  
            uint multiplier = percentRate(msg.sender);
             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value * multiplier/100)));
            participation[msg.sender] = participation[msg.sender] + 1;
            
             
            uint smartcontract = msg.value*SMARTCONTRACT_PERCENT/100;
            require(SMARTCONTRACT.call.value(smartcontract).gas(gasleft())());
            
             
            uint promo = msg.value * PROMO_PERCENT/100;
            PROMO.transfer(promo);
    
             
            pay();
        } else {
            started = true;
        }
    }

     
     
     
    function pay() private {
         
        uint128 money = uint128(address(this).balance);

         
        for (uint i=0; i<queue.length; i++) {
            uint idx = currentReceiverIndex + i;   

            Deposit storage dep = queue[idx];  

            if (money >= dep.expect) {   
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
        for (uint i=currentReceiverIndex; i<queue.length; ++i) {
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

        if (c > 0) {
            uint j = 0;
            for (uint i=currentReceiverIndex; i<queue.length; ++i) {
                Deposit storage dep = queue[i];
                if (dep.depositor == depositor) {
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
    
     
    function percentRate(address depositor) public view returns(uint) {
        uint persent = START_MULTIPLIER;
        if (participation[depositor] > 0) {
            persent = persent + participation[depositor] * 5;
        }
        if (persent > 120) {
            persent = 120;
        } 
        return persent;
    }
}