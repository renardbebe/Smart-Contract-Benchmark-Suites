 

pragma solidity >= 0.5.0;

contract WinyDice {
    address payable private OWNER;

     
     
     
    uint public constant HOUSE_EDGE_OF_TEN_THOUSAND = 98;
    uint public constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

     
     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 216;

     
     
     
     
     
     
     
     
     
    uint constant MAX_MASK_MODULO = 216;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
    uint public MAX_PROFIT;
    uint public MAX_PROFIT_PERCENT = 10;
    bool public KILLED;

     
     
    uint128 public LOCKED_IN_BETS;

    uint256 public JACKPOT_BALANCE = 0;

    bool public PAYOUT_PAUSED; 
    bool public GAME_PAUSED;

     
    uint256 public constant MIN_JACKPOT_BET = 0.1 ether;
    uint256 public JACKPOT_CHANCE = 1000;    
    uint256 public constant JACKPOT_FEE = 0.001 ether;

    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_BET = 300000 ether;

      
     
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;
    uint constant MASK40 = 0xFFFFFFFFFF;
    uint constant MASK_MODULO_40 = 40;

     
    struct Bet {
         
        uint80 Amount; 
         
        uint8 Modulo; 
         
         
        uint8 RollUnder; 
         
        address payable Player; 
         
        uint216 Mask; 
        uint40 PlaceBlockNumber;
    }

     
    mapping(uint => Bet) bets;
     
    address private CROUPIER;

     
    event FailedPayment(address indexed playerAddress,uint indexed betId, uint amount,uint dice);
    event Payment(address indexed playerAddress,uint indexed betId, uint amount,uint dice);
    event JackpotPayment(address indexed playerAddress,uint indexed betId, uint amount);    
     
    event BetPlaced(uint indexed betId, uint source);
    event LogTransferEther(address indexed SentToAddress, uint256 AmountTransferred);

    constructor (address payable _owner,address _croupier) public payable {
        OWNER = _owner;                
        CROUPIER = _croupier;
        KILLED = false;
    }

    modifier onlyOwner() {
        require(msg.sender == OWNER,"only owner can call this function.");
        _;
    }

     
    modifier onlyCroupier {
        require(msg.sender == CROUPIER, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    modifier payoutsAreActive {
        if(PAYOUT_PAUSED == true) revert("payouts are currently paused.");
        _;
    } 

    modifier gameIsActive {
        if(GAME_PAUSED == true) revert("game is not active right now.");
        _;
    } 


    function GetChoiceCountForLargeModulo(uint inputMask, uint n) private pure returns (uint choiceCount) {
        choiceCount += (((inputMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        for (uint i = 1; i < n; i++) {
            inputMask = inputMask >> MASK_MODULO_40;
            choiceCount += (((inputMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        }
        return choiceCount;
    }

    function GetChoiceCount(uint inputMask ,uint modulo) private pure returns (uint choiceCount,uint mask) {

        if (modulo <= MASK_MODULO_40) {
             
             
             
             
            choiceCount = ((inputMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = inputMask;
        } else if (modulo <= MASK_MODULO_40 * 2) {
            choiceCount = GetChoiceCountForLargeModulo(inputMask, 2);
            mask = inputMask;
        } else if (modulo == 100) {
            require(inputMask > 0 && inputMask <= modulo, "High modulo range, betMask larger than modulo.");
            choiceCount = inputMask;
        } else if (modulo <= MASK_MODULO_40 * 3) {
            choiceCount = GetChoiceCountForLargeModulo(inputMask, 3);
            mask = inputMask;
        } else if (modulo <= MASK_MODULO_40 * 4) {
            choiceCount = GetChoiceCountForLargeModulo(inputMask, 4);
            mask = inputMask;
        } else if (modulo <= MASK_MODULO_40 * 5) {
            choiceCount = GetChoiceCountForLargeModulo(inputMask, 5);
            mask = inputMask;
        } else if (modulo <= MAX_MASK_MODULO) {
            choiceCount = GetChoiceCountForLargeModulo(inputMask, 6);
            mask = inputMask;
        } else {
             
             
            require(inputMask > 0 && inputMask <= modulo, "High modulo range, betMask larger than modulo.");
            choiceCount = inputMask;
        }        
    }

     
    function GetDiceWinAmount(uint amount, uint modulo, uint choiceCount) private pure returns (uint winAmount, uint jackpotFee) {
        require(0 < choiceCount && choiceCount <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_OF_TEN_THOUSAND / 10000;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require(houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");

        winAmount = (amount - houseEdge - jackpotFee) * modulo / choiceCount;
    }    

     

     
     
     
     
    
    function PlaceBet(uint mask, uint modulo, uint betId , uint source) public payable gameIsActive {        
        if(KILLED == true) revert ("Contract Killed");
         
        MAX_PROFIT = (address(this).balance + msg.value - LOCKED_IN_BETS - JACKPOT_BALANCE) * MAX_PROFIT_PERCENT / 100;
        Bet storage bet = bets[betId];
        if(bet.Player != address(0)) revert("Bet should be in a 'clean' state.");

         
        if(modulo < 2 && modulo > MAX_MODULO) revert("Modulo should be within range.");
        if(msg.value < MIN_BET && msg.value > MAX_BET) revert("Amount should be within range.");
        if(mask < 0 && mask > MAX_BET_MASK) revert("Mask should be within range.");

        uint choiceCount;
        uint finalMask;
        (choiceCount,finalMask) = GetChoiceCount(mask,modulo);        

         
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = GetDiceWinAmount(msg.value, modulo, choiceCount);

         
        if(possibleWinAmount > MAX_PROFIT) revert("maxProfit limit violation.");

         
        LOCKED_IN_BETS += uint128(possibleWinAmount);
        JACKPOT_BALANCE += uint128(jackpotFee);

         
        if((JACKPOT_BALANCE + LOCKED_IN_BETS) > address(this).balance) revert( "Cannot afford to lose this bet.");        

         
        emit BetPlaced(betId, source);

         
        bet.Amount = uint80(msg.value);
        bet.Modulo = uint8(modulo);
        bet.RollUnder = uint8(choiceCount);
        bet.Mask = uint216(mask);
        bet.Player = msg.sender;
        bet.PlaceBlockNumber = uint40(block.number);
    }

     
    function SendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint betId,uint dice) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary,betId, successLogAmount,dice);
            MAX_PROFIT = (address(this).balance - amount - JACKPOT_BALANCE - LOCKED_IN_BETS) * MAX_PROFIT_PERCENT / 100;
        } else {
            emit FailedPayment(beneficiary,betId,amount,dice);
        }
        
    }

     
     
     
     
    function RefundBet(uint betId) external onlyOwner {
         
        Bet storage bet = bets[betId];
        uint amount = bet.Amount;

        if(amount == 0) revert("Bet should be in an 'active' state");

         
        bet.Amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = GetDiceWinAmount(amount, bet.Modulo, bet.RollUnder);

        LOCKED_IN_BETS -= uint128(diceWinAmount);
        if (JACKPOT_BALANCE >= jackpotFee) {
            JACKPOT_BALANCE -= uint128(jackpotFee);
        }       

         
        SendFunds(bet.Player, amount, amount, betId,0);
        MAX_PROFIT = (address(this).balance - LOCKED_IN_BETS - JACKPOT_BALANCE - diceWinAmount) * MAX_PROFIT_PERCENT / 100;
        delete bets[betId];
    }

      
    function SettleBet(string memory betString,bytes32 blockHash) public onlyCroupier {
        uint betId = uint(keccak256(abi.encodePacked(betString)));

        Bet storage bet = bets[betId];

         uint placeBlockNumber = bet.PlaceBlockNumber;

        if(block.number <= placeBlockNumber) revert("settleBet in the same block as placeBet, or before.");
        if(blockhash(placeBlockNumber) != blockHash) revert("Invalid BlockHash");        
        
        SettleBetCommon(bet,betId,blockHash);
    }

     
    function SettleBetCommon(Bet storage bet, uint betId,bytes32 blockHash) private {
        uint amount = bet.Amount;
        uint modulo = bet.Modulo;
        uint rollUnder = bet.RollUnder;
        address payable player = bet.Player;

         
        if(amount == 0) revert("Bet should be in an 'active' state");

         
        bet.Amount = 0;

         
        bytes32 entropy = keccak256(abi.encodePacked(betId, blockHash));
        
         
        uint dice = uint(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = GetDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

         
        if ((modulo != 100) && (modulo <= MAX_MASK_MODULO)) {
             
            if ((2 ** dice) & bet.Mask != 0) {
                diceWin = diceWinAmount;
            }
        } else {
             
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }
        }

         
        LOCKED_IN_BETS -= uint128(diceWinAmount);

         
        if (amount >= MIN_JACKPOT_BET) {
             
             
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_CHANCE;

             
            if (jackpotRng == 0) {
                jackpotWin = JACKPOT_BALANCE;
                JACKPOT_BALANCE = 0;
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(player,betId,jackpotWin);
        }        

         
        SendFunds(player, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin, betId,dice);
        MAX_PROFIT = (address(this).balance - LOCKED_IN_BETS - JACKPOT_BALANCE - diceWin) * MAX_PROFIT_PERCENT / 100;
        delete bets[betId];
    }

    function GetBetInfoByBetString(string memory betString) public view onlyOwner returns (uint _betId, uint amount, uint8 modulo, uint8 rollUnder, uint betId, uint mask, address player) {
        _betId = uint(keccak256(abi.encodePacked(betString)));
        (amount, modulo, rollUnder, betId, mask, player) = GetBetInfo(_betId);
    }

    function GetBetInfo(uint _betId) public view returns (uint amount, uint8 modulo, uint8 rollUnder, uint betId, uint mask, address player) {
        Bet storage bet = bets[_betId];
        amount = bet.Amount;
        modulo = bet.Modulo;
        rollUnder = bet.RollUnder;
        betId = _betId;
        mask = bet.Mask;
        player = bet.Player;
    }

     
    function ownerPauseGame(bool newStatus) public onlyOwner {
        GAME_PAUSED = newStatus;
    }

     
    function ownerPausePayouts(bool newPayoutStatus) public onlyOwner {
        PAYOUT_PAUSED = newPayoutStatus;
    }   

     
    function ownerSetMaxProfit(uint _maxProfit) public onlyOwner {
        MAX_PROFIT = _maxProfit;
        MAX_PROFIT = (address(this).balance - LOCKED_IN_BETS - JACKPOT_BALANCE) * MAX_PROFIT_PERCENT / 100;
    }

      
    function ownerSetMaxProfitPercent(uint _maxProfitPercent) public onlyOwner {
        MAX_PROFIT_PERCENT = _maxProfitPercent;
        MAX_PROFIT = (address(this).balance - LOCKED_IN_BETS - JACKPOT_BALANCE) * MAX_PROFIT_PERCENT / 100;
    }    

     
    function TransferEther(address payable sendTo, uint amount) public onlyOwner {        
                       
        if(!sendTo.send(amount)) 
            revert("owner transfer ether failed.");
        if(KILLED == false)
        {
            MAX_PROFIT = (address(this).balance - LOCKED_IN_BETS - JACKPOT_BALANCE) * MAX_PROFIT_PERCENT / 100;            
        }
        emit LogTransferEther(sendTo, amount); 
    }

     
    function ChargeContract () external payable onlyOwner {
          
        MAX_PROFIT = (address(this).balance - LOCKED_IN_BETS - JACKPOT_BALANCE) * MAX_PROFIT_PERCENT / 100;       
    }

     
     
    function kill() external onlyOwner {
        require(LOCKED_IN_BETS == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        KILLED = true;
        JACKPOT_BALANCE = 0;        
    }

     function ownerSetNewOwner(address payable newOwner) external onlyOwner {
        OWNER = newOwner;       
    }

    function ownerSetNewCroupier(address newCroupier) external onlyOwner {
        CROUPIER =  newCroupier  ; 
    }
}