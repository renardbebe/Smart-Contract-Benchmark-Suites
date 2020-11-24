 

pragma solidity ^0.4.25;

 

contract GET111 {
    address constant private ADMIN = 0x411647BA6480bF5FDec2145f858FD37AeCBfC03B;
    uint constant public ADMIN_FEE = 5;
    uint constant public PROFIT = 111;

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
            require(msg.value <= 2 ether);  

             
            queue.push(Deposit(msg.sender, uint128(msg.value), uint128(msg.value*PROFIT/100)));

             
            uint admin = msg.value*ADMIN_FEE/100;
            ADMIN.send(admin);

             
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