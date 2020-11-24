 

pragma solidity ^0.4.16;

contract EtherGuess {

     
    bool private running;   
    bytes32 public pauseReason;
    uint public totalPayout;  
    int public numberOfGuesses;   
    uint public currentRound;
    uint public totalPayedOut;
    uint8 public adminPayout;    
    uint public lastFinish;
    uint public minimumValue;
    address public admin;
    address public bot;
    mapping (address => uint) public winners;
    mapping (int => GuessInfo) public guesses;
    mapping (uint8 => bool) public closedHour;

     
    uint constant NEGLECTGUESSTIMER = 5 days;
    uint constant NEGLECTOWNERTIMER = 30 days;
    uint constant ADMINPAYOUTDENOMINATOR = 100;

    function EtherGuess() public {
       
        minimumValue = 5 finney;
        admin = msg.sender;
        bot = msg.sender;
        adminPayout = 10;
        running = true;
        closedHour[23] = true;
        closedHour[0] = true;
        currentRound = 1;
        lastFinish = now;
    }

    struct GuessInfo {
        address owner;
        uint value;
        uint round;
    }

    function setOpenCloseHour(uint8 hour, bool closed) onlyAdmin public {
            closedHour[hour] = closed;
    }

    function setAdminPayout(uint8 newAdminPayout) onlyAdmin public {
        require(newAdminPayout <= 10);
        adminPayout = newAdminPayout;
    }

    function setBotAddress(address newBot) onlyAdmin public {
        bot = newBot;
    }
    
    event Withdraw(
        address indexed _payto,
        uint _value
    );

    event Winner(
        address indexed _payto,
        uint indexed _round,
        uint _value,
        int _price,
        string _priceInfo
    );

    event NoWinner(
        address indexed _admin,
        uint indexed _round,
        int _price,
        string _priceInfo
    );

    event Refund(
        address indexed _payto,
        uint indexed _round,
        uint _value,
        int _guess
    );

    event Neglect(
        address indexed _payto,
        uint indexed _round,
        uint _value,
        int _guess
    );

    event Guess(
        address  indexed _from,
        uint indexed _round,
        int _numberOfGuesses,
        int  _guess,
        uint _value
    );

    modifier onlyAdmin {
        require(msg.sender == admin);
        _;
    }

    modifier adminOrBot {
        require(msg.sender == bot || msg.sender == admin);
        _;
    }
    
    modifier isOpen {
      require(!closedHour[uint8((now / 60 / 60) % 24)] && running);
      _;
    }

    function () public payable {
          
    }


    function isGuessesOpen() public view returns (bool, bytes32) {
        bool open = true;
        bytes32 answer = "";
        
        if (closedHour[uint8((now / 60 / 60) % 24)]){
            open = false;
            answer = "Hours";
        }
        
        if (!running) {
            open = running;
            answer = pauseReason;
        }
        return (open, answer);
    }


    function getWinnings() public {
        require(winners[msg.sender]>0);
        uint value = winners[msg.sender];
        winners[msg.sender] = 0;
        totalPayout = subToZero(totalPayout,value);
        Withdraw(msg.sender,value);
        msg.sender.transfer(value);
    }

    function addGuess(int guess) public payable isOpen {
        uint oldRound = guesses[guess].round;
        uint oldValue = guesses[guess].value;
        uint testValue;
        if (oldRound < currentRound) {
            testValue = minimumValue;
        } else {
            testValue = oldValue + minimumValue;
        }
        require(testValue == msg.value);
        if (oldRound == currentRound) {
           totalPayout += oldValue;
           address oldOwner = guesses[guess].owner;
           winners[oldOwner] += oldValue;
           Refund(oldOwner, currentRound, oldValue, guess);
           guesses[guess].owner = msg.sender;
           guesses[guess].value = msg.value;
        } else {
            GuessInfo memory gi = GuessInfo(msg.sender, msg.value, currentRound);
            guesses[guess] = gi;
        }
        numberOfGuesses++;
        Guess(msg.sender, currentRound, numberOfGuesses, guess, msg.value);
        
    }
    
    function addGuessWithRefund(int guess) public payable isOpen {
        uint oldRound = guesses[guess].round;
        uint oldValue = guesses[guess].value;
        uint testValue;
        if (oldRound < currentRound) {
            testValue = minimumValue;
        } else {
            testValue = oldValue + minimumValue;
        }
        require(winners[msg.sender] >= testValue);
        if (oldRound == currentRound) {
           totalPayout += oldValue;
           address oldOwner = guesses[guess].owner;
           winners[oldOwner] += oldValue;
           Refund(oldOwner, currentRound, oldValue, guess);
           guesses[guess].owner = msg.sender;
           guesses[guess].value = testValue;
           winners[msg.sender] -= testValue;
        } else {
            GuessInfo memory gi = GuessInfo(msg.sender, testValue, currentRound);
            guesses[guess] = gi;
            winners[msg.sender] -= testValue;
        }
        numberOfGuesses++;
        Guess(msg.sender, currentRound, numberOfGuesses, guess, testValue);
        
    }
    
    function multiGuess(int[] multiGuesses) public payable isOpen {
        require(multiGuesses.length > 1 && multiGuesses.length <= 20);
        uint valueLeft = msg.value;
        for (uint i = 0; i < multiGuesses.length; i++) {
            if (valueLeft > 0) {
                uint newValue = minimumValue;
                if (guesses[multiGuesses[i]].round == currentRound) {
                    uint oldValue = guesses[multiGuesses[i]].value;
                    totalPayout += oldValue;
                    address oldOwner = guesses[multiGuesses[i]].owner;
                    winners[oldOwner] += oldValue;
                    Refund(oldOwner, currentRound, oldValue, multiGuesses[i]);
                    newValue = oldValue + minimumValue;
                }
                valueLeft = subToZero(valueLeft,newValue);
                GuessInfo memory gi = GuessInfo(msg.sender, newValue, currentRound);
                guesses[multiGuesses[i]] = gi;
                Guess(msg.sender, currentRound, ++numberOfGuesses, multiGuesses[i], newValue);
            }

        }
        if (valueLeft > 0) {
            Refund(msg.sender, currentRound, valueLeft, -1);
            winners[msg.sender] += valueLeft;
        }

    }

    function pauseResumeContract(bool state, bytes32 reason) public onlyAdmin {
        pauseReason = reason;
        running = state;
        lastFinish = now;
    }

    function subToZero(uint a, uint b) pure internal returns (uint) {
        if (b > a) {
            return 0;
        } else {
        return a - b;
        }
    }
    

    function finishUpRound(int price, string priceInfo) public adminOrBot {
        
        
            if (guesses[price].round == currentRound && guesses[price].value > 0) {
                
                uint finalTotalPayout = this.balance - totalPayout;
                uint finalAdminPayout = (finalTotalPayout * adminPayout) / ADMINPAYOUTDENOMINATOR;
                uint finalPlayerPayout = finalTotalPayout - finalAdminPayout;
                
                Winner(guesses[price].owner, currentRound, finalPlayerPayout, price, priceInfo);  
                
                totalPayout += finalTotalPayout;
                totalPayedOut += finalPlayerPayout;
                winners[guesses[price].owner] += finalPlayerPayout;
                winners[admin] += finalAdminPayout;
                numberOfGuesses = 0;
                currentRound++;

            } else {
                NoWinner(msg.sender, currentRound, price, priceInfo);
            }
        

        lastFinish = now;

    }

    function neglectGuess(int guess) public {
        require(lastFinish + NEGLECTGUESSTIMER < now);
        require(guesses[guess].owner == msg.sender && guesses[guess].round == currentRound);
        guesses[guess].round = 0;  
        numberOfGuesses -= 1;
        Neglect(msg.sender, currentRound, guesses[guess].value, guess);
        msg.sender.transfer(guesses[guess].value);

    }

    function neglectOwner() public {
        require(lastFinish + NEGLECTOWNERTIMER < now);
        lastFinish = now;
        admin = msg.sender;
        winners[msg.sender] += winners[admin];
        winners[admin] = 0;
    }

}