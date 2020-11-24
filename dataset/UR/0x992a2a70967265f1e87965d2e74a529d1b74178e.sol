 

pragma solidity ^0.4.25;

 

contract Restarter {
     
    uint constant public FIRST_START_TIMESTAMP = 1541008800;

     
    uint constant public RESTART_INTERVAL = 24 hours;  

     
    address constant private ADS_SUPPORT = 0x79C188C8d8c7dEc9110c340140F46bE10854E754;

     
    address constant private TECH_SUPPORT = 0x988f1a2fb17414c95f45E2DAaaA40509F5C9088c;

     
    uint constant public ADS_PERCENT = 2;

     
    uint constant public TECH_PERCENT = 1;

     
    uint constant public JACKPOT_PERCENT = 3;

     
    uint constant public JACKPOT_WINNER_PERCENT = 25;
    
     
    uint constant public MULTIPLIER = 121;

     
    uint constant public MAX_LIMIT = 1 ether;

     
    uint constant public MIN_LIMIT = 0.01 ether;

     
    uint constant public MINIMAL_GAS_LIMIT = 250000;

     
    struct Deposit {
        address depositor;  
        uint128 deposit;    
        uint128 expect;     
    }

     
    event Restart(uint timestamp);

     
    Deposit[] private _queue;

     
    uint public currentReceiverIndex = 0;

     
    uint public jackpotAmount = 0;

     
    uint public lastStartTimestamp;

    uint public queueCurrentLength = 0;

     
    constructor() public {
         
        lastStartTimestamp = FIRST_START_TIMESTAMP;
    }

     
    function () public payable {
         
        require(now >= FIRST_START_TIMESTAMP, "Not started yet!");

         
        require(gasleft() >= MINIMAL_GAS_LIMIT, "We require more gas!");

         
        require(msg.value <= MAX_LIMIT, "Deposit is too big!");

         
        require(msg.value >= MIN_LIMIT, "Deposit is too small!");

         
        if (now >= lastStartTimestamp + RESTART_INTERVAL) {
             
            lastStartTimestamp += (now - lastStartTimestamp) / RESTART_INTERVAL * RESTART_INTERVAL;
             
            _payoutJackpot();
            _clearQueue();
             
            emit Restart(now);
        }

         
        _insertQueue(Deposit(msg.sender, uint128(msg.value), uint128(msg.value * MULTIPLIER / 100)));

         
        jackpotAmount += msg.value * JACKPOT_PERCENT / 100;

         
        uint ads = msg.value * ADS_PERCENT / 100;
        ADS_SUPPORT.transfer(ads);

         
        uint tech = msg.value * TECH_PERCENT / 100;
        TECH_SUPPORT.transfer(tech);

         
        _pay();
    }

     
     
     
    function _pay() private {
         
        uint128 money = uint128(address(this).balance) - uint128(jackpotAmount);

         
        for (uint i = 0; i < queueCurrentLength; i++) {

             
            uint idx = currentReceiverIndex + i;

             
            Deposit storage dep = _queue[idx];

             
            if(money >= dep.expect) {
                 
                dep.depositor.transfer(dep.expect);
                 
                money -= dep.expect;
            } else {
                 
                 
                dep.depositor.transfer(money);
                 
                dep.expect -= money;
                 
                break;
            }

             
            if (gasleft() <= 50000) {
                 
                break;
            }
        }

         
        currentReceiverIndex += i;
    }

    function _payoutJackpot() private {
         
        uint128 money = uint128(jackpotAmount);

         
        Deposit storage dep = _queue[queueCurrentLength - 1];

        dep.depositor.transfer(uint128(jackpotAmount * JACKPOT_WINNER_PERCENT / 100));
        money -= uint128(jackpotAmount * JACKPOT_WINNER_PERCENT / 100);

         
        for (uint i = queueCurrentLength - 2; i < queueCurrentLength && i >= currentReceiverIndex; i--) {
             
            dep = _queue[i];

             
            if(money >= dep.expect) {
                 
                dep.depositor.transfer(dep.expect);
                 
                money -= dep.expect;
            } else if (money > 0) {
                 
                 
                dep.depositor.transfer(money);
                 
                dep.expect -= money;
                money = 0;
            } else {
                break;
            }
        }

         
        jackpotAmount = 0;
         
        currentReceiverIndex = 0;
    }

    function _insertQueue(Deposit deposit) private {
        if (queueCurrentLength == _queue.length) {
            _queue.length += 1;
        }
        _queue[queueCurrentLength++] = deposit;
    }

    function _clearQueue() private {
        queueCurrentLength = 0;
    }

     
     
    function getDeposit(uint idx) public view returns (address depositor, uint deposit, uint expect){
        Deposit storage dep = _queue[idx];
        return (dep.depositor, dep.deposit, dep.expect);
    }

     
    function getDepositsCount(address depositor) public view returns (uint) {
        uint c = 0;
        for(uint i=currentReceiverIndex; i < queueCurrentLength; ++i){
            if(_queue[i].depositor == depositor)
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
            for(uint i = currentReceiverIndex; i < queueCurrentLength; ++i){
                Deposit storage dep = _queue[i];
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
        return queueCurrentLength - currentReceiverIndex;
    }

}