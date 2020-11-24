 

pragma solidity ^0.4.25;

 

contract Multipliers {
     
    address constant private FATHER = 0x7CDfA222f37f5C4CCe49b3bBFC415E8C911D1cD8;
     
    address constant private TECH = 0xDb058D036768Cfa9a94963f99161e3c94aD6f5dA;
     
    address constant private PROMO = 0xdA149b17C154e964456553C749B7B4998c152c9E;
     
    uint constant public FATHER_PERCENT = 1;
    uint constant public TECH_PERCENT = 2;
    uint constant public PROMO_PERCENT = 2;
    uint constant public PRIZE_PERCENT = 2;
    uint constant public MAX_INVESTMENT = 10 ether;
    uint constant public MIN_INVESTMENT_FOR_PRIZE = 0.05 ether;
    uint constant public MAX_IDLE_TIME = 20 minutes;  

     
     
     
    uint8[] MULTIPLIERS = [
        111,  
        113,  
        117,  
        121,  
        125,  
        130,  
        135,  
        141   
    ];

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

    struct DepositCount {
        int128 stage;
        uint128 count;
    }

    struct LastDepositInfo {
        uint128 index;
        uint128 time;
    }

    Deposit[] private queue;   
    uint public currentReceiverIndex = 0;  
    LastDepositInfo public lastDepositInfo;  

    uint public prizeAmount = 0;  
    int public stage = 0;  
    mapping(address => DepositCount) public depositsMade;  

     
     
    function () public payable {
         
         
        if(msg.value > 0 && msg.sender != FATHER){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value <= MAX_INVESTMENT, "The investment is too much!");  

            checkAndUpdateStage();

            addDeposit(msg.sender, msg.value);

             
            pay();
        }else if(msg.value == 0){
            withdrawPrize();
        }
    }

     
     
     
    function pay() private {
         
        uint balance = address(this).balance;
        uint128 money = 0;
        if(balance > prizeAmount)  
            money = uint128(balance - prizeAmount);

         
        for(uint i=currentReceiverIndex; i<queue.length; i++){

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
         
        DepositCount storage c = depositsMade[depositor];
        if(c.stage != stage){
            c.stage = int128(stage);
            c.count = 0;
        }

         
         
        if(value >= MIN_INVESTMENT_FOR_PRIZE)
            lastDepositInfo = LastDepositInfo(uint128(queue.length), uint128(now));

         
        uint multiplier = getDepositorMultiplier(depositor);
         
        queue.push(Deposit(depositor, uint128(value), uint128(value*multiplier/100)));

         
        c.count++;

         
        prizeAmount += value*(FATHER_PERCENT + PRIZE_PERCENT)/100;

         
        uint support = value*TECH_PERCENT/100;
        TECH.send(support);
        uint adv = value*PROMO_PERCENT/100;
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
         
         
        stage = _stage;
        delete queue;
        currentReceiverIndex = 0;
        delete lastDepositInfo;
    }

    function withdrawPrize() private {
         
        require(lastDepositInfo.time > 0 && lastDepositInfo.time <= now - MAX_IDLE_TIME, "The last depositor is not confirmed yet");
         
        require(currentReceiverIndex <= lastDepositInfo.index, "The last depositor should still be in queue");

        uint balance = address(this).balance;
        if(prizeAmount > balance)  
            prizeAmount = balance;

         
         
        uint donation = prizeAmount*FATHER_PERCENT/(FATHER_PERCENT + PRIZE_PERCENT);
        require(FATHER.call.value(donation).gas(gasleft())());

        uint prize = prizeAmount - donation;
        queue[lastDepositInfo.index].depositor.send(prize);

        prizeAmount = 0;
        proceedToNewStage(stage + 1);
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

     
    function getDepositorMultiplier(address depositor) public view returns (uint) {
        DepositCount storage c = depositsMade[depositor];
        uint count = 0;
        if(c.stage == getCurrentStageByTime())
            count = c.count;
        if(count < MULTIPLIERS.length)
            return MULTIPLIERS[count];

        return MULTIPLIERS[MULTIPLIERS.length - 1];
    }

    function getCurrentStageByTime() public view returns (int) {
        return int(now - 17 hours) / 1 days - 17835;  
    }

    function getStageStartTime(int _stage) public pure returns (int) {
        return 17 hours + (_stage + 17835)*1 days;
    }

    function getCurrentCandidateForPrize() public view returns (address addr, int timeLeft){
        Deposit storage d = queue[lastDepositInfo.index];
        addr = d.depositor;
        timeLeft = int(lastDepositInfo.time + MAX_IDLE_TIME) - int(now);
    }

}