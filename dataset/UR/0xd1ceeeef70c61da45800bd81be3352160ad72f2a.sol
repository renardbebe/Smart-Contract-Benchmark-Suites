 

pragma solidity ^0.4.23;

contract Dice2Win {

     

     
    uint256 constant JACKPOT_MODULO = 1000;

     
    uint256 constant HOUSE_EDGE_PERCENT = 2;
    uint256 constant JACKPOT_FEE_PERCENT = 50;

     
     
    uint256 constant MIN_BET = 0.02 ether;

     
    uint256 constant MIN_JACKPOT_BET = 0.1 ether;

     
     
    uint256 constant BLOCK_DELAY = 2;

     
     
     
     
    uint256 constant BET_EXPIRATION_BLOCKS = 100;

     

     
    address public owner;
    address public nextOwner;

     
     
    uint256 public maxBetCoinDice;
    uint256 public maxBetDoubleDice;

     
    uint128 public jackpotSize;

     
     
    uint128 public lockedInBets;

     

    enum GameId {
        CoinFlip,
        SingleDice,
        DoubleDice,

        MaxGameId
    }

    uint256 constant MAX_BLOCK_NUMBER = 2 ** 56;
    uint256 constant MAX_BET_MASK = 2 ** 64;
    uint256 constant MAX_AMOUNT = 2 ** 128;

     
     
    struct ActiveBet {
         
        GameId gameId;
         
        uint56 placeBlockNumber;
         
         
         
        uint64 mask;
         
        uint128 amount;
    }

    mapping (address => ActiveBet) activeBets;

     
    event FailedPayment(address indexed _beneficiary, uint256 amount);
    event Payment(address indexed _beneficiary, uint256 amount);
    event JackpotPayment(address indexed _beneficiary, uint256 amount);

     

    constructor () public {
        owner = msg.sender;
         
    }

    modifier onlyOwner {
        require (msg.sender == owner);
        _;
    }

     

    function approveNextOwner(address _nextOwner) public onlyOwner {
        require (_nextOwner != owner);
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() public {
        require (msg.sender == nextOwner);
        owner = nextOwner;
    }

     
     

    function kill() public onlyOwner {
        require (lockedInBets == 0);
        selfdestruct(owner);
    }

     
     
    function () public payable {
    }

     
    function changeMaxBetCoinDice(uint256 newMaxBetCoinDice) public onlyOwner {
        maxBetCoinDice = newMaxBetCoinDice;
    }

    function changeMaxBetDoubleDice(uint256 newMaxBetDoubleDice) public onlyOwner {
        maxBetDoubleDice = newMaxBetDoubleDice;
    }

     
    function increaseJackpot(uint256 increaseAmount) public onlyOwner {
        require (increaseAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + increaseAmount <= address(this).balance);
        jackpotSize += uint128(increaseAmount);
    }

     
    function withdrawFunds(address beneficiary, uint256 withdrawAmount) public onlyOwner {
        require (withdrawAmount <= address(this).balance);
        require (jackpotSize + lockedInBets + withdrawAmount <= address(this).balance);
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

     

     
     
    function placeBet(GameId gameId, uint256 betMask) public payable {
         
         
        ActiveBet storage bet = activeBets[msg.sender];
        require (bet.amount == 0);

         
        require (gameId < GameId.MaxGameId);
        require (msg.value >= MIN_BET && msg.value <= getMaxBet(gameId));
        require (betMask < MAX_BET_MASK);

         
        uint256 rollModulo = getRollModulo(gameId);
        uint256 rollUnder = getRollUnder(rollModulo, betMask);

         
        uint256 reservedAmount = getDiceWinAmount(msg.value, rollModulo, rollUnder);
        uint256 jackpotFee = getJackpotFee(msg.value);
        require (jackpotSize + lockedInBets + reservedAmount + jackpotFee <= address(this).balance);

         
        lockedInBets += uint128(reservedAmount);
        jackpotSize += uint128(jackpotFee);

         
        bet.gameId = gameId;
        bet.placeBlockNumber = uint56(block.number);
        bet.mask = uint64(betMask);
        bet.amount = uint128(msg.value);
    }

     
     
     
     
    function settleBet(address gambler) public {
         
        ActiveBet storage bet = activeBets[gambler];
        require (bet.amount != 0);

         
        require (block.number > bet.placeBlockNumber + BLOCK_DELAY);
        require (block.number <= bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

         
         
         
        bytes32 entropy = keccak256(gambler, blockhash(bet.placeBlockNumber + BLOCK_DELAY));

        uint256 diceWin = 0;
        uint256 jackpotWin = 0;

         
        uint256 rollModulo = getRollModulo(bet.gameId);
        uint256 dice = uint256(entropy) % rollModulo;

        uint256 rollUnder = getRollUnder(rollModulo, bet.mask);
        uint256 diceWinAmount = getDiceWinAmount(bet.amount, rollModulo, rollUnder);

         
        if ((2 ** dice) & bet.mask != 0) {
            diceWin = diceWinAmount;
        }

         
        lockedInBets -= uint128(diceWinAmount);

         
        if (bet.amount >= MIN_JACKPOT_BET) {
             
             
            uint256 jackpotRng = (uint256(entropy) / rollModulo) % JACKPOT_MODULO;

             
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

         
        delete activeBets[gambler];

         
        uint256 totalWin = diceWin + jackpotWin;

        if (totalWin == 0) {
            totalWin = 1 wei;
        }

        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

         
        sendFunds(gambler, totalWin, diceWin);
    }

     
     
     
     
     
     
    function refundBet(address gambler) public {
         
        ActiveBet storage bet = activeBets[gambler];
        require (bet.amount != 0);

         
        require (block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS);

         
        uint256 rollModulo = getRollModulo(bet.gameId);
        uint256 rollUnder = getRollUnder(rollModulo, bet.mask);

        lockedInBets -= uint128(getDiceWinAmount(bet.amount, rollModulo, rollUnder));

         
        uint256 refundAmount = bet.amount;
        delete activeBets[gambler];

         
        sendFunds(gambler, refundAmount, refundAmount);
    }

     

     
    function getRollModulo(GameId gameId) pure private returns (uint256) {
        if (gameId == GameId.CoinFlip) {
             
            return 2;

        } else if (gameId == GameId.SingleDice) {
             
            return 6;

        } else if (gameId == GameId.DoubleDice) {
             
            return 36;

        }
    }

     
    function getMaxBet(GameId gameId) view private returns (uint256) {
        if (gameId == GameId.CoinFlip) {
            return maxBetCoinDice;

        } else if (gameId == GameId.SingleDice) {
            return maxBetCoinDice;

        } else if (gameId == GameId.DoubleDice) {
            return maxBetDoubleDice;

        }
    }

     
    function getRollUnder(uint256 rollModulo, uint256 betMask) pure private returns (uint256) {
        uint256 rollUnder = 0;
        uint256 singleBitMask = 1;
        for (uint256 shift = 0; shift < rollModulo; shift++) {
            if (betMask & singleBitMask != 0) {
                rollUnder++;
            }

            singleBitMask *= 2;
        }

        return rollUnder;
    }

     
    function getDiceWinAmount(uint256 amount, uint256 rollModulo, uint256 rollUnder) pure private
      returns (uint256) {
        require (0 < rollUnder && rollUnder <= rollModulo);
        return amount * rollModulo / rollUnder * (100 - HOUSE_EDGE_PERCENT) / 100;
    }

     
    function getJackpotFee(uint256 amount) pure private returns (uint256) {
        return amount * HOUSE_EDGE_PERCENT / 100 * JACKPOT_FEE_PERCENT / 100;
    }

     
    function sendFunds(address beneficiary, uint256 amount, uint256 successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

}