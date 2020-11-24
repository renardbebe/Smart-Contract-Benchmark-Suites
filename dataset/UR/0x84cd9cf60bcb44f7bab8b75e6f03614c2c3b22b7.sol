 

pragma solidity ^0.4.25;

 

contract ESmart {
    uint constant public INVESTMENT = 0.05 ether;
    uint constant private START_TIME = 1541435400;  

     
    address constant private TECH = 0x9A5B6966379a61388068bb765c518E5bC4D9B509;
     
    address constant private PROMO = 0xD6104cEca65db37925541A800870aEe09C8Fd78D;
     
    address constant private LAST_FUND = 0x357b9046f99eEC7E705980F328F00BAab4b3b6Be;
     
    uint constant public JACKPOT_PERCENT = 1;
    uint constant public TECH_PERCENT = 7;  
    uint constant public PROMO_PERCENT = 13;  
    uint constant public LAST_FUND_PERCENT = 10;
    uint constant public MAX_IDLE_TIME = 10 minutes;  
    uint constant public NEXT_ROUND_TIME = 30 minutes;  

     
    uint constant public MULTIPLIER = 120;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

    struct LastDepositInfo {
        uint128 index;
        uint128 time;
    }

    struct MaxDepositInfo {
        address depositor;
        uint count;
    }

    Deposit[] private queue;   
    uint public currentReceiverIndex = 0;  
    uint public currentQueueSize = 0;  
    LastDepositInfo public lastDepositInfo;  
    MaxDepositInfo public maxDepositInfo;  
    uint private startTime = START_TIME;
    mapping(address => uint) public depCount;  

    uint public jackpotAmount = 0;  
    int public stage = 0;  

     
     
    function () public payable {
         
         
        if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value >= INVESTMENT, "The investment is too small!");
            require(stage < 5);  

            checkAndUpdateStage();

             
            require(getStartTime() <= now, "Deposits are not accepted before time");

            addDeposit(msg.sender, msg.value);

             
            pay();
        }else if(msg.value == 0){
            withdrawPrize();
        }
    }

     
     
     
    function pay() private {
         
        uint balance = address(this).balance;
        uint128 money = 0;
        if(balance > (jackpotAmount))  
            money = uint128(balance - jackpotAmount);

         
        for(uint i=currentReceiverIndex; i<currentQueueSize; i++){

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

    function addDeposit(address depositor, uint value) private {
        require(stage < 5);  
         
         
        if(value > INVESTMENT){  
            depositor.transfer(value - INVESTMENT);
            value = INVESTMENT;
        }

        lastDepositInfo.index = uint128(currentQueueSize);
        lastDepositInfo.time = uint128(now);

         
        push(depositor, value, value*MULTIPLIER/100);

        depCount[depositor]++;

         
        uint count = depCount[depositor];
        if(maxDepositInfo.count < count){
            maxDepositInfo.count = count;
            maxDepositInfo.depositor = depositor;
        }

         
        jackpotAmount += value*(JACKPOT_PERCENT)/100;

        uint lastFund = value*LAST_FUND_PERCENT/100;
        LAST_FUND.send(lastFund);
         
        uint support = value*TECH_PERCENT/1000;
        TECH.send(support);
        uint adv = value*PROMO_PERCENT/1000;
        PROMO.send(adv);

    }

    function checkAndUpdateStage() private{
        int _stage = getCurrentStageByTime();

        require(_stage >= stage, "We should only go forward in time");

        if(_stage != stage){
            proceedToNewStage(_stage);
        }
    }

    function proceedToNewStage(int _stage) private {
         
         
        startTime = getStageStartTime(_stage);
        assert(startTime > 0);
        stage = _stage;
        currentQueueSize = 0;  
        currentReceiverIndex = 0;
        delete lastDepositInfo;
    }

    function withdrawPrize() private {
        require(getCurrentStageByTime() >= 5);  
        require(maxDepositInfo.count > 0, "The max depositor is not confirmed yet");

        uint balance = address(this).balance;
        if(jackpotAmount > balance)  
            jackpotAmount = balance;

        maxDepositInfo.depositor.send(jackpotAmount);

        selfdestruct(TECH);  
    }

     
    function push(address depositor, uint deposit, uint expect) private {
         
        Deposit memory dep = Deposit(depositor, uint128(deposit), uint128(expect));
        assert(currentQueueSize <= queue.length);  
        if(queue.length == currentQueueSize)
            queue.push(dep);
        else
            queue[currentQueueSize] = dep;

        currentQueueSize++;
    }

     
     
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

     
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
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
            for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
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
        return currentQueueSize - currentReceiverIndex;
    }

    function getCurrentStageByTime() public view returns (int) {
        if(lastDepositInfo.time > 0 && lastDepositInfo.time + MAX_IDLE_TIME <= now){
            return stage + 1;  
        }
        return stage;
    }

    function getStageStartTime(int _stage) public view returns (uint) {
        if(_stage >= 5)
            return 0;
        if(_stage == stage)
            return startTime;
        if(lastDepositInfo.time == 0)
            return 0;
        if(_stage == stage + 1)
            return lastDepositInfo.time + NEXT_ROUND_TIME;
        return 0;
    }

    function getStartTime() public view returns (uint) {
        return getStageStartTime(getCurrentStageByTime());
    }

}