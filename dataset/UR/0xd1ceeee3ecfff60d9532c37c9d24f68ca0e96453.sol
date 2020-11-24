 

pragma solidity ^0.4.23;

 
 
 
 
 
 

contract Dice2Win {
     

     
    uint constant JACKPOT_MODULO = 1000;

     
    uint constant HOUSE_EDGE_PERCENT = 2;
    uint constant JACKPOT_FEE_PERCENT = 50;

     
     
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

     
    uint constant MIN_JACKPOT_BET = 0.1 ether;

     
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 100;

     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MASK_MODULO = 40;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

     
     
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    address public owner;
    address private nextOwner;

     
    uint public maxProfit;

     
    address public secretSigner;

     
    uint128 public jackpotSize;

     
     
    uint128 public lockedInBets;

     
    struct Bet {
         
        uint amount;
         
        uint8 modulo;
         
         
        uint8 rollUnder;
         
        uint40 placeBlockNumber;
         
        uint40 mask;
         
        address gambler;
    }

     
    mapping (uint => Bet) bets;

     
    event FailedPayment(address indexed _beneficiary, uint amount);
    event Payment(address indexed _beneficiary, uint amount);
    event JackpotPayment(address indexed _beneficiary, uint amount);

     
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
    }

     
    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

     
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner);
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner);
        owner = nextOwner;
    }

     
     
    function () public payable {
    }

     
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

     
    function setMaxProfit(uint newMaxProfit) public onlyOwner {
        require (newMaxProfit < MAX_AMOUNT);
        maxProfit = newMaxProfit;
    }

     
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance);
        jackpotSize += uint128(increaseAmount);
    }

     
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance);
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

     
     
    function kill() external onlyOwner {
        require (lockedInBets == 0);
        selfdestruct(owner);
    }

     

     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function placeBet(uint betMask, uint modulo,
                      uint commitLastBlock, uint commit, bytes32 r, bytes32 s) external payable {
         
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0));

         
        uint amount = msg.value;
        require (modulo > 1 && modulo <= MAX_MODULO);
        require (amount >= MIN_BET && amount <= MAX_AMOUNT);
        require (betMask > 0 && betMask < MAX_BET_MASK);

         
        require (block.number <= commitLastBlock);
        bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
        require (secretSigner == ecrecover(signatureHash, 27, r, s));

        uint rollUnder;
        uint mask;

        if (modulo <= MAX_MASK_MODULO) {
             
             
             
             
             
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else {
             
             
            require (betMask > 0 && betMask <= modulo);
            rollUnder = betMask;
        }

         
        uint possibleWinAmount = getDiceWinAmount(amount, modulo, rollUnder);
        uint jackpotFee = getJackpotFee(amount);

         
        require (possibleWinAmount <= amount + maxProfit);

         
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

         
        require (jackpotSize + lockedInBets <= address(this).balance);

         
        bet.amount = amount;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint40(mask);
        bet.gambler = msg.sender;
    }

     
     
     
     
     
    function settleBet(uint reveal, uint clean_commit) external {
         
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        uint placeBlockNumber = bet.placeBlockNumber;
        address gambler = bet.gambler;

         
        require (amount != 0);

         
        require (block.number > placeBlockNumber);
        require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS);

         
        bet.amount = 0;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockhash(placeBlockNumber)));

         
        uint dice = uint(entropy) % modulo;
        uint diceWinAmount = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

         
        if (modulo <= MAX_MASK_MODULO) {
             
            if ((2 ** dice) & bet.mask != 0) {
                diceWin = diceWinAmount;
            }

        } else {
             
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }

        }

         
        lockedInBets -= uint128(diceWinAmount);

         
        if (amount >= MIN_JACKPOT_BET) {
             
             
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

             
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

         
        uint totalWin = diceWin + jackpotWin;

        if (totalWin == 0) {
            totalWin = 1 wei;
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

         
        sendFunds(gambler, totalWin, diceWin);

         
        if (clean_commit == 0) {
            return;
        }

        clearProcessedBet(clean_commit);
    }

     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0);

         
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

         
        bet.amount = 0;
        lockedInBets -= uint128(getDiceWinAmount(amount, bet.modulo, bet.rollUnder));

         
        sendFunds(bet.gambler, amount, amount);
    }

     
    function clearStorage(uint[] clean_commits) external {
        uint length = clean_commits.length;

        for (uint i = 0; i < length; i++) {
            clearProcessedBet(clean_commits[i]);
        }
    }

     
    function clearProcessedBet(uint commit) private {
        Bet storage bet = bets[commit];

         
         
        if (bet.amount != 0 || block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS) {
            return;
        }

         
         
        bet.modulo = 0;
        bet.rollUnder = 0;
        bet.placeBlockNumber = 0;
        bet.mask = 0;
        bet.gambler = address(0);
    }

     
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) pure private returns (uint) {
        require (0 < rollUnder && rollUnder <= modulo);
        return amount * modulo / rollUnder * (100 - HOUSE_EDGE_PERCENT) / 100;
    }

     
    function getJackpotFee(uint amount) pure private returns (uint) {
        return amount * HOUSE_EDGE_PERCENT / 100 * JACKPOT_FEE_PERCENT / 100;
    }

     
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

     
     
    uint constant POPCNT_MULT = 1 + 2**41 + 2**(41*2) + 2**(41*3) + 2**(41*4) + 2**(41*5);
    uint constant POPCNT_MASK = 1 + 2**(6*1) + 2**(6*2) + 2**(6*3) + 2**(6*4) + 2**(6*5)
        + 2**(6*6) + 2**(6*7) + 2**(6*8) + 2**(6*9) + 2**(6*10) + 2**(6*11) + 2**(6*12)
        + 2**(6*13) + 2**(6*14) + 2**(6*15) + 2**(6*16) + 2**(6*17) + 2**(6*18) + 2**(6*19)
        + 2**(6*20) + 2**(6*21) + 2**(6*22) + 2**(6*23) + 2**(6*24) + 2**(6*25) + 2**(6*26)
        + 2**(6*27) + 2**(6*28) + 2**(6*29) + 2**(6*30) + 2**(6*31) + 2**(6*32) + 2**(6*33)
        + 2**(6*34) + 2**(6*35) + 2**(6*36) + 2**(6*37) + 2**(6*38) + 2**(6*39) + 2**(6*40);

    uint constant POPCNT_MODULO = 2**6 - 1;

}