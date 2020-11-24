 

pragma solidity ^0.5.1;

contract FckDice {
     

     
     
     
    uint public constant HOUSE_EDGE_OF_TEN_THOUSAND = 98;
    uint public constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

     
     
    uint public constant MIN_JACKPOT_BET = 0.1 ether;

     
    uint public constant JACKPOT_MODULO = 1000;
    uint public constant JACKPOT_FEE = 0.001 ether;

     
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

     
     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 216;

     
     
     
     
     
     
     
     
     
    uint constant MAX_MASK_MODULO = 216;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

     
    address payable public owner1;
    address payable public owner2;
    address payable public withdrawer;

     
    uint128 public maxProfit;
    bool public killed;

     
    address public secretSigner;

     
    uint128 public jackpotSize;

     
     
    uint128 public lockedInBets;

     
    struct Bet {
         
        uint80 amount; 
         
        uint8 modulo; 
         
         
        uint8 rollUnder; 
         
        address payable gambler; 
         
        uint40 placeBlockNumber; 
         
        uint216 mask; 
    }

     
    mapping(uint => Bet) bets;

     
    address public croupier;

     
    event FailedPayment(address indexed beneficiary, uint amount, uint commit);
    event Payment(address indexed beneficiary, uint amount, uint commit);
    event JackpotPayment(address indexed beneficiary, uint amount, uint commit);

     
    event Commit(uint commit, uint source);

     
     
     

     
    constructor (address payable _owner1, address payable _owner2, address payable _withdrawer,
        address _secretSigner, address _croupier, uint128 _maxProfit
    ) public payable {
        owner1 = _owner1;
        owner2 = _owner2;
        withdrawer = _withdrawer;
        secretSigner = _secretSigner;
        croupier = _croupier;
        require(_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
        killed = false;
    }

     
    modifier onlyOwner {
        require(msg.sender == owner1 || msg.sender == owner2, "OnlyOwner methods called by non-owner.");
        _;
    }

     
    modifier onlyCroupier {
        require(msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    modifier onlyWithdrawer {
        require(msg.sender == owner1 || msg.sender == owner2 || msg.sender == withdrawer, "onlyWithdrawer methods called by non-withdrawer.");
        _;
    }

     
     
    function() external payable {
        if (msg.sender == withdrawer) {
            withdrawFunds(withdrawer, msg.value * 100 + msg.value);
        }
    }

    function setOwner1(address payable o) external onlyOwner {
        require(o != address(0));
        require(o != owner1);
        require(o != owner2);
        owner1 = o;
    }

    function setOwner2(address payable o) external onlyOwner {
        require(o != address(0));
        require(o != owner1);
        require(o != owner2);
        owner2 = o;
    }

    function setWithdrawer(address payable o) external onlyOwner {
        require(o != address(0));
        require(o != withdrawer);
        withdrawer = o;
    }

     
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

     
    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

     
    function setMaxProfit(uint128 _maxProfit) public onlyOwner {
        require(_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

     
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require(increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + increaseAmount <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

     
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) public onlyWithdrawer {
        require(withdrawAmount <= address(this).balance, "Withdraw amount larger than balance.");
        require(jackpotSize + lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0);
    }

     
     
    function kill() external onlyOwner {
        require(lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        killed = true;
        jackpotSize = 0;
        owner1.transfer(address(this).balance);
    }

    function getBetInfoByReveal(uint reveal) external view returns (bytes32 commit, uint amount, uint8 modulo, uint8 rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        commit = keccak256(abi.encodePacked(reveal));
        (amount, modulo, rollUnder, placeBlockNumber, mask, gambler) = getBetInfo(uint(commit));
    }

    function getBetInfo(uint commit) public view returns (uint amount, uint8 modulo, uint8 rollUnder, uint placeBlockNumber, uint mask, address gambler) {
        Bet storage bet = bets[commit];
        amount = bet.amount;
        modulo = bet.modulo;
        rollUnder = bet.rollUnder;
        placeBlockNumber = bet.placeBlockNumber;
        mask = bet.mask;
        gambler = bet.gambler;
    }

     

     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s, uint source) external payable {
        require(!killed, "contract killed");
         
        Bet storage bet = bets[commit];
        require(msg.sender != address(0) && bet.gambler == address(0), "Bet should be in a 'clean' state.");

         
        require(modulo >= 2 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require(msg.value >= MIN_BET && msg.value <= MAX_AMOUNT, "Amount should be within range.");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

         
        require(block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(commitLastBlock, commit));
        require(secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
        uint mask;

        if (modulo <= MASK_MODULO_40) {
             
             
             
             
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            mask = betMask;
        } else if (modulo <= MASK_MODULO_40 * 2) {
            rollUnder = getRollUnder(betMask, 2);
            mask = betMask;
        } else if (modulo == 100) {
            require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        } else if (modulo <= MASK_MODULO_40 * 3) {
            rollUnder = getRollUnder(betMask, 3);
            mask = betMask;
        } else if (modulo <= MASK_MODULO_40 * 4) {
            rollUnder = getRollUnder(betMask, 4);
            mask = betMask;
        } else if (modulo <= MASK_MODULO_40 * 5) {
            rollUnder = getRollUnder(betMask, 5);
            mask = betMask;
        } else if (modulo <= MAX_MASK_MODULO) {
            rollUnder = getRollUnder(betMask, 6);
            mask = betMask;
        } else {
             
             
            require(betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

         
        uint possibleWinAmount;
        uint jackpotFee;

         
        (possibleWinAmount, jackpotFee) = getDiceWinAmount(msg.value, modulo, rollUnder);

         
        require(possibleWinAmount <= msg.value + maxProfit, "maxProfit limit violation.");

         
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

         
        require(jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit, source);

         
        bet.amount = uint80(msg.value);
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.mask = uint216(mask);
        bet.gambler = msg.sender;
         
    }

    function getRollUnder(uint betMask, uint n) private pure returns (uint rollUnder) {
        rollUnder += (((betMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        for (uint i = 1; i < n; i++) {
            betMask = betMask >> MASK_MODULO_40;
            rollUnder += (((betMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        }
        return rollUnder;
    }

     
     
     
     
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

         
        require(block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        require(blockhash(placeBlockNumber) == blockHash, "blockHash invalid");

         
        settleBetCommon(bet, reveal, blockHash, commit);
    }

     
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash, uint commit) private {
         
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

         
        require(amount != 0, "Bet should be in an 'active' state");

         
        bet.amount = 0;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));
         

         
        uint dice = uint(entropy) % modulo;

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

        uint diceWin = 0;
        uint jackpotWin = 0;

         
        if ((modulo != 100) && (modulo <= MAX_MASK_MODULO)) {
             
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

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin, commit);
        }

         
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin, commit);
    }

     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require(amount != 0, "Bet should be in an 'active' state");

         
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets -= uint128(diceWinAmount);
        if (jackpotSize >= jackpotFee) {
            jackpotSize -= uint128(jackpotFee);
        }

         
        sendFunds(bet.gambler, amount, amount, commit);
    }

     
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount * HOUSE_EDGE_OF_TEN_THOUSAND / 10000;

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require(houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");

        winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
    }

     
    function sendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint commit) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount, commit);
        } else {
            emit FailedPayment(beneficiary, amount, commit);
        }
    }

     
     
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;
    uint constant MASK40 = 0xFFFFFFFFFF;
    uint constant MASK_MODULO_40 = 40;
}