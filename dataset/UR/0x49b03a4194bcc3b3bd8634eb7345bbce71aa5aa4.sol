 

pragma solidity ^0.4.25;


 
 
 
contract EthFastDotHost {

    uint constant MINIMAL_DEPOSIT = 0.01 ether;  
    uint constant MAX_DEPOSIT = 7 ether;  

    uint constant JACKPOT_MINIMAL_DEPOSIT = 0.05 ether;  
    uint constant JACKPOT_DURATION = 20 minutes;  

    uint constant JACKPOT_PERCENTAGE = 500;  
    uint constant PROMOTION_PERCENTAGE = 325;  
    uint constant PAYROLL_PERCENTAGE = 175;  

    uint constant MAX_GAS_PRICE = 50;  

     
    address constant MANAGER = 0x490429e7C4C343B3B069c30625404888Bcc8Eb7b;

     
    address constant SUPPORT_AND_PROMOTION_FUND = 0x490429e7C4C343B3B069c30625404888Bcc8Eb7b;

    struct Deposit {
        address member;
        uint amount;
    }

    struct Jackpot {
        address lastMember;
        uint time;
        uint amount;
    }

    Deposit[] public deposits;  
    Jackpot public jackpot;  

    uint public totalInvested;  
    uint public currentIndex;  
    uint public startBlockNumber;  

     
    function () public payable {

         
        require(isRunning());

         
        require(tx.gasprice <= MAX_GAS_PRICE * 1000000000);

        address member = msg.sender;  
        uint amount = msg.value;  

         
        if (now - jackpot.time >= JACKPOT_DURATION && jackpot.time > 0) {

            send(member, amount);  

            if (!payouts()) {  
                return;
            }

            send(jackpot.lastMember, jackpot.amount);  
            startBlockNumber = 0;  
            return;
        }

         
        require(amount >= MINIMAL_DEPOSIT && amount <= MAX_DEPOSIT);

         
        if (amount >= JACKPOT_MINIMAL_DEPOSIT) {
            jackpot.lastMember = member;
            jackpot.time = now;
        }

         
        deposits.push( Deposit(member, amount * calcMultiplier() / 100) );
        totalInvested += amount;
        jackpot.amount += amount * JACKPOT_PERCENTAGE / 10000;

         
        send(SUPPORT_AND_PROMOTION_FUND, amount * (PROMOTION_PERCENTAGE + PAYROLL_PERCENTAGE) / 10000);

         
        payouts();

    }

     
     
    function payouts() internal returns(bool complete) {

        uint balance = address(this).balance;

         
        balance = balance >= jackpot.amount ? balance - jackpot.amount : 0;

        uint countPayouts;

        for (uint i = currentIndex; i < deposits.length; i++) {

            Deposit storage deposit = deposits[currentIndex];

            if (balance >= deposit.amount) {

                send(deposit.member, deposit.amount);
                balance -= deposit.amount;
                delete deposits[currentIndex];
                currentIndex++;
                countPayouts++;

                 
                 
                if (countPayouts >= 15) {
                    break;
                }

            } else {

                send(deposit.member, balance);
                deposit.amount -= balance;
                complete = true;
                break;

            }
        }

    }

     
    function send(address _receiver, uint _amount) internal {

        if (_amount > 0 && address(_receiver) != 0) {
            _receiver.transfer(msg.value);
        }

    }

     
     
    function restart(uint _blockNumber) public {

        require(MANAGER == msg.sender);
        require(!isRunning());
        require(_blockNumber >= block.number);

        currentIndex = deposits.length;  
        startBlockNumber = _blockNumber;  
        totalInvested = 0;

        delete jackpot;

    }

     
    function isStopped() public view returns(bool) {
        return startBlockNumber == 0;
    }

     
    function isWaiting() public view returns(bool) {
        return startBlockNumber > block.number;
    }

     
    function isRunning() public view returns(bool) {
        return !isWaiting() && !isStopped();
    }

     
    function calcMultiplier() public view returns (uint) {

        if (totalInvested <= 75 ether) return 120;
        if (totalInvested <= 200 ether) return 130;
        if (totalInvested <= 350 ether) return 135;

        return 140;  
    }

     
    function depositsOfMember(address _member) public view returns(uint[] amounts, uint[] places) {

        uint count;
        for (uint i = currentIndex; i < deposits.length; i++) {
            if (deposits[i].member == _member) {
                count++;
            }
        }

        amounts = new uint[](count);
        places = new uint[](count);

        uint id;
        for (i = currentIndex; i < deposits.length; i++) {

            if (deposits[i].member == _member) {
                amounts[id] = deposits[i].amount;
                places[id] = i - currentIndex + 1;
                id++;
            }

        }

    }

     
    function stats() public view returns(
        string status,
        uint timestamp,
        uint blockStart,
        uint timeJackpot,
        uint queueLength,
        uint invested,
        uint multiplier,
        uint jackpotAmount,
        address jackpotMember
    ) {

        if (isStopped()) {
            status = "stopped";
        } else if (isWaiting()) {
            status = "waiting";
        } else {
            status = "running";
        }

        if (isWaiting()) {
            blockStart = startBlockNumber - block.number;
        }

        if (now - jackpot.time < JACKPOT_DURATION) {
            timeJackpot = JACKPOT_DURATION - (now - jackpot.time);
        }

        timestamp = now;
        queueLength = deposits.length - currentIndex;
        invested = totalInvested;
        jackpotAmount = jackpot.amount;
        jackpotMember = jackpot.lastMember;
        multiplier = calcMultiplier();

    }

}