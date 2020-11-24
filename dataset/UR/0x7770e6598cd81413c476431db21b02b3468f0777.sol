 

pragma solidity ^0.5.4;

 

contract Multipliers {
    uint constant public TECH_PERCENT = 5;
    uint constant public PROMO_PERCENT = 5;
    uint constant public PRIZE_PERCENT = 5;

    uint public MAX_INVESTMENT = 10 ether;
    uint public MIN_INVESTMENT = 0.01 ether;
    uint public MIN_INVESTMENT_FOR_PRIZE = 0.03 ether;  
    uint public MAX_IDLE_TIME = 30 minutes;  
    uint public maxGasPrice = 1 ether;  

    event Dep(int stage, uint sum, address addr);
    event Refund(int stage, uint sum, address addr);
    event Prize(int stage, uint sum, address addr);

     
     
     
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
        address payable depositor;  
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
     
    address payable private tech;
     
    address payable private promo;

    uint public currentReceiverIndex = 0;  
    uint public currentQueueSize = 0;  
    LastDepositInfo public lastDepositInfo;  

    uint public prizeAmount = 0;  
    uint public startTime = 0;  
    int public stage = 0;  
    mapping(address => DepositCount) public depositsMade;  

    constructor(address payable _tech, address payable _promo) public {
         
         
        queue.push(Deposit(address(0x1),0,1));
        tech = _tech;
        promo = _promo;
    }

     
     
    function () external payable {
        deposit();
    }

     
     
    function deposit() public payable {
         
        require(tx.gasprice <= maxGasPrice, "Gas price is too high! Do not cheat!");
        require(startTime > 0 && now >= startTime, "The race has not begun yet!");

        if(msg.value > 0 && lastDepositInfo.time > 0 && now > lastDepositInfo.time + MAX_IDLE_TIME){
             
            msg.sender.transfer(msg.value);
            withdrawPrize();
        }else if(msg.value > 0){
            require(gasleft() >= 220000, "We require more gas!");  
            require(msg.value >= MIN_INVESTMENT, "The investment is too small!");
            require(msg.value <= MAX_INVESTMENT, "The investment is too large!");  

            addDeposit(msg.sender, msg.value);

             
            pay();
        }else if(msg.value == 0){
            withdrawPrize();
        }
    }

     
     
     
    function pay() private {
         
        uint balance = address(this).balance;
        uint money = 0;
        if(balance > prizeAmount)  
            money = balance - prizeAmount;

         
        uint i=currentReceiverIndex;
        for(; i<currentQueueSize; i++){

            Deposit storage dep = queue[i];  

            if(money >= dep.expect){   
                dep.depositor.send(dep.expect);  
                money -= dep.expect;             

                emit Refund(stage, dep.expect, dep.depositor);

                 
                delete queue[i];
            }else{
                 
                dep.depositor.send(money);  
                dep.expect -= uint128(money);        

                emit Refund(stage, money, dep.depositor);
                break;                      
            }

            if(gasleft() <= 50000)          
                break;                      
        }

        currentReceiverIndex = i;  
    }

    function addDeposit(address payable depositor, uint value) private {
         
        DepositCount storage c = depositsMade[depositor];
        if(c.stage != stage){
            c.stage = int128(stage);
            c.count = 0;
        }

         
         
        if(value >= getCurrentPrizeMinimalDeposit())
            lastDepositInfo = LastDepositInfo(uint128(currentQueueSize), uint128(now));

         
        uint multiplier = getDepositorMultiplier(depositor);
         
        push(depositor, value, value*multiplier/100);

         
        c.count++;

         
        prizeAmount += value*(PRIZE_PERCENT)/100;

         
        uint support = value*TECH_PERCENT/100;
        tech.send(support);
        uint adv = value*PROMO_PERCENT/100;
        promo.send(adv);

        emit Dep(stage, msg.value, msg.sender);
    }

    function proceedToNewStage(int _stage) private {
         
         
        stage = _stage;
        startTime = 0;
        currentQueueSize = 0;  
        currentReceiverIndex = 0;
        delete lastDepositInfo;
    }

    function withdrawPrize() private {
         
        require(lastDepositInfo.time > 0 && lastDepositInfo.time <= now - MAX_IDLE_TIME, "The last depositor is not confirmed yet");
         
        require(currentReceiverIndex <= lastDepositInfo.index, "The last depositor should still be in queue");

        uint balance = address(this).balance;
        uint prize = prizeAmount;
        if(balance > prize){
             
            pay();
        }
        if(balance > prize){
            return;  
        }
        if(prize > balance)  
            prize = balance;

        queue[lastDepositInfo.index].depositor.send(prize);

        emit Prize(stage, prize, queue[lastDepositInfo.index].depositor);

        prizeAmount = 0;
        proceedToNewStage(stage + 1);
    }

     
    function push(address payable depositor, uint dep, uint expect) private {
         
        Deposit memory d = Deposit(depositor, uint128(dep), uint128(expect));
        assert(currentQueueSize <= queue.length);  
        if(queue.length == currentQueueSize)
            queue.push(d);
        else
            queue[currentQueueSize] = d;

        currentQueueSize++;
    }

     
     
    function getDeposit(uint idx) public view returns (address depositor, uint dep, uint expect){
        Deposit storage d = queue[idx];
        return (d.depositor, d.deposit, d.expect);
    }

    function getCurrentPrizeMinimalDeposit() public view returns(uint) {
        uint st = startTime;
        if(st == 0 || now < st)
            return MIN_INVESTMENT_FOR_PRIZE;
        uint dep = MIN_INVESTMENT_FOR_PRIZE + ((now - st)/1 hours)*MIN_INVESTMENT_FOR_PRIZE;
        if(dep > MAX_INVESTMENT)
            dep = MAX_INVESTMENT;
        return dep;
    }

     
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
            if(queue[i].depositor == depositor)
                c++;
        }
        return c;
    }

     
    function getDeposits(address depositor) public view returns (uint16[] memory idxs, uint128[] memory deposits, uint128[] memory expects) {
        uint c = getDepositsCount(depositor);

        idxs = new uint16[](c);
        deposits = new uint128[](c);
        expects = new uint128[](c);

        if(c > 0) {
            uint j = 0;
            for(uint i=currentReceiverIndex; i<currentQueueSize; ++i){
                Deposit storage dep = queue[i];
                if(dep.depositor == depositor){
                    idxs[j] = uint16(i - currentReceiverIndex);
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

     
    function getDepositorMultiplier(address depositor) public view returns (uint) {
        DepositCount storage c = depositsMade[depositor];
        uint count = 0;
        if(c.stage == stage)
            count = c.count;
        if(count < MULTIPLIERS.length)
            return MULTIPLIERS[count];

        return MULTIPLIERS[MULTIPLIERS.length - 1];
    }

    modifier onlyAuthorityAndStopped() {
        require(startTime == 0 || now < startTime, "You can set time only in stopped state");
        require(msg.sender == tech || msg.sender == promo, "You are not authorized");
        _;
    }

    function setStartTimeAndMaxGasPrice(uint time, uint _gasprice) public onlyAuthorityAndStopped {
        require(time == 0 || time >= now, "Wrong start time");
        startTime = time;
        if(_gasprice > 0)
            maxGasPrice = _gasprice;
    }

    function setParameters(uint min, uint max, uint prize, uint idle) public onlyAuthorityAndStopped {
        if(min > 0)
            MIN_INVESTMENT = min;
        if(max > 0)
            MAX_INVESTMENT = max;
        if(prize > 0)
            MIN_INVESTMENT_FOR_PRIZE = prize;
        if(idle > 0)
            MAX_IDLE_TIME = idle;
    }

    function getCurrentCandidateForPrize() public view returns (address addr, uint prize, uint timeMade, int timeLeft){
         
        if(currentReceiverIndex <= lastDepositInfo.index && lastDepositInfo.index < currentQueueSize){
            Deposit storage d = queue[lastDepositInfo.index];
            addr = d.depositor;
            prize = prizeAmount;
            timeMade = lastDepositInfo.time;
            timeLeft = int(timeMade + MAX_IDLE_TIME) - int(now);
        }
    }

}