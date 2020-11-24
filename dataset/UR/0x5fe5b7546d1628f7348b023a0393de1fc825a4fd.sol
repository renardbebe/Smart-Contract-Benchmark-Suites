 

contract Roulette {
    
     
    string sWelcome;
     
    uint privSeed; 
    struct Casino {
        address addr;
        uint balance;
        uint bettingLimitMin;
        uint bettingLimitMax;
    }
    Casino casino;

     
    function Roulette() {
        sWelcome = "\n-----------------------------\n     Welcome to Roulette \n Got coins? Then come on in! \n-----------------------------\n";
        privSeed = 1;
        casino.addr = msg.sender;
        casino.balance = 0;
        casino.bettingLimitMin = 1*10**18;
        casino.bettingLimitMax = 10*10**18;
    }
    
    function welcome() constant returns (string) {
        return sWelcome;
    }
    function casinoBalance() constant returns (uint) {
        return casino.balance;
    }
    function casinoDeposit() {
        if (msg.sender == casino.addr)
            casino.balance += msg.value;
        else 
            msg.sender.send(msg.value);
    }
    function casinoWithdraw(uint amount) {
        if (msg.sender == casino.addr && amount <= casino.balance) {
            casino.balance -= amount;
            casino.addr.send(amount);
        }
    }
    
     
    function betOnNumber(uint number) public returns (string) {
         
        address addr = msg.sender;
        uint betSize = msg.value;
        if (betSize < casino.bettingLimitMin || betSize > casino.bettingLimitMax) {
             
            if (betSize >= 1*10**18)
                addr.send(betSize);
            return "Please choose an amount within between 1 and 10 ETH";
        }
        if (betSize * 36 > casino.balance) {
             
            addr.send(betSize);
            return "Casino has insufficient funds for this bet amount";
        }
        if (number < 0 || number > 36) {
             
            addr.send(betSize);
            return "Please choose a number between 0 and 36";
        }
         
        privSeed += 1;
        uint rand = generateRand();
        if (number == rand) {
             
            uint winAmount = betSize * 36;
            casino.balance -= (winAmount - betSize);
            addr.send(winAmount);
            return "Winner winner chicken dinner!";
        }
        else {
            casino.balance += betSize;
            return "Wrong number.";
        }
    }
    
     
    function betOnColor(uint color) public returns (string) {
         
        address addr = msg.sender;
        uint betSize = msg.value;
        if (betSize < casino.bettingLimitMin || betSize > casino.bettingLimitMax) {
             
            if (betSize >= 1*10**18)
                addr.send(betSize);
            return "Please choose an amount within between 1 and 10 ETH";
        }
        if (betSize * 2 > casino.balance) {
             
            addr.send(betSize);
            return "Casino has insufficient funds for this bet amount";
        }
        if (color != 0 && color != 1) {
             
            addr.send(betSize);
            return "Please choose either '0' = red or '1' = black as a color";
        }
         
        privSeed += 1;
        uint rand = generateRand();
        uint randC = (rand + 1) % 2;
         
        if (rand != 0 && (randC == color)) {
            uint winAmount = betSize * 2;
            casino.balance -= (winAmount - betSize);
            addr.send(winAmount);
            return "Win! Good job.";
        }
        else {
            casino.balance += betSize;
            return "Wrong color.";           
        }
    }
    
     
    function generateRand() private returns (uint) { 
         
        privSeed = (privSeed*3 + 1) / 2;
        privSeed = privSeed % 10**9;
        uint number = block.number;  
        uint diff = block.difficulty;  
        uint time = block.timestamp;  
        uint gas = block.gaslimit;  
         
        uint total = privSeed + number + diff + time + gas;
        uint rand = total % 37;
        return rand;
    }

     
    function kill() {
        if (msg.sender == casino.addr) 
            suicide(casino.addr);
    }
}