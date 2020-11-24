 

pragma solidity ^0.5.0;

contract FckRoulette {
     
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
        maxProfit = _maxProfit;
    }

     
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) public onlyWithdrawer {
        require(withdrawAmount <= address(this).balance, "Withdraw amount larger than balance.");
        require(lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount, 0);
    }

     
     
    function() external payable {
        if (msg.sender == withdrawer) {
            withdrawFunds(withdrawer, msg.value * 100 + msg.value);
        }
    }

     
    function sendFunds(address payable beneficiary, uint amount, uint successLogAmount, uint commit) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount, commit);
        } else {
            emit FailedPayment(beneficiary, amount, commit);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

     
     
     
     
     
     
     
    event Commit(uint commit, uint source);
    event FailedPayment(address indexed beneficiary, uint amount, uint commit);
    event Payment(address indexed beneficiary, uint amount, uint commit);
    event JackpotPayment(address indexed beneficiary, uint amount, uint commit);
     
     

    function reveal2commit(uint reveal) external pure returns (bytes32 commit, uint commitUint) {
        commit = keccak256(abi.encodePacked(reveal));
        commitUint = uint(commit);
    }

    function getBetInfo(uint commit) external view returns (
        uint8 status,
        address gambler,
        uint placeBlockNumber,
        uint[] memory masks,
        uint[] memory amounts,
        uint8[] memory rollUnders,
        uint modulo,
        bool isSingle,
        uint length
    ) {
        Bet storage bet = bets[commit];
        if (bet.status > 0) {
            status = bet.status;
            modulo = bet.modulo;
            gambler = bet.gambler;
            placeBlockNumber = bet.placeBlockNumber;
            length = bet.rawBet.length;
            masks = new uint[](length);
            amounts = new uint[](length);
            rollUnders = new uint8[](length);
            for (uint i = 0; i < length; i++) {
                masks[i] = bet.rawBet[i].mask;
                 
                amounts[i] = uint(bet.rawBet[i].amount) * 10 ** 12;
                rollUnders[i] = bet.rawBet[i].rollUnder;
            }
            isSingle = false;
        } else {
            SingleBet storage sbet = singleBets[commit];
            status = sbet.status;
            modulo = sbet.modulo;
            gambler = sbet.gambler;
            placeBlockNumber = sbet.placeBlockNumber;
            length = status > 0 ? 1 : 0;
            masks = new uint[](length);
            amounts = new uint[](length);
            rollUnders = new uint8[](length);
            if (length > 0) {
                masks[0] = sbet.mask;
                amounts[0] = sbet.amount;
                rollUnders[0] = sbet.rollUnder;
            }
            isSingle = true;
        }
    }

    function getRollUnder(uint betMask, uint n) private pure returns (uint rollUnder) {
        rollUnder += (((betMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        for (uint i = 1; i < n; i++) {
            betMask = betMask >> MASK_MODULO_40;
            rollUnder += (((betMask & MASK40) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
        }
        return rollUnder;
    }

    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;
    uint constant MASK40 = 0xFFFFFFFFFF;
    uint constant MASK_MODULO_40 = 40;

    function tripleDicesTable(uint index) private pure returns (uint[] memory dice){
         
        dice = new uint[](3);
        dice[0] = (index / 36) + 1;
        dice[1] = ((index / 6) % 6) + 1;
        dice[2] = (index % 6) + 1;
    }

     
     
     

    uint public constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

     
     
    uint public constant MIN_JACKPOT_BET = 0.1 ether;

     
    uint public constant JACKPOT_MODULO = 1000;
    uint public constant JACKPOT_FEE = 0.001 ether;

     
    uint public constant MIN_BET = 0.01 ether;

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 216; 

     
    uint constant MAX_BET_MASK = 2 ** MAX_MODULO;

     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

     
     
     
    uint public constant HOUSE_EDGE_OF_TEN_THOUSAND = 98;
    bool public constant IS_DEV = false;

    bool public stopped;
    uint128 public maxProfit;
    uint128 public lockedInBets;

     
    uint128 public jackpotSize;

     
    address public croupier;

     
    address public secretSigner;

     
    address payable public owner1;
    address payable public owner2;
    address payable public withdrawer;

    struct SingleBet {
        uint72 amount;            
        uint8 status;             
        uint8 modulo;             
        uint8 rollUnder;          
        address payable gambler;  
        uint40 placeBlockNumber;  
        uint216 mask;             
    }

    mapping(uint => SingleBet) singleBets;

    struct RawBet {
        uint216 mask;     
        uint32 amount;    
        uint8 rollUnder;  
    }

    struct Bet {
        address payable gambler;  
        uint40 placeBlockNumber;  
        uint8 modulo;             
        uint8 status;             
        RawBet[] rawBet;          
    }

    mapping(uint => Bet) bets;

     
    constructor (address payable _owner1, address payable _owner2, address payable _withdrawer,
        address _secretSigner, address _croupier, uint128 _maxProfit
 
    ) public payable {
        owner1 = _owner1;
        owner2 = _owner2;
        withdrawer = _withdrawer;
        secretSigner = _secretSigner;
        croupier = _croupier;
        maxProfit = _maxProfit;
        stopped = false;
         
 
 
 
    }

    function stop(bool destruct) external onlyOwner {
        require(IS_DEV || lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        if (destruct) {
            selfdestruct(owner1);
        } else {
            stopped = true;
            owner1.transfer(address(this).balance);
        }
    }

    function getWinAmount(uint amount, uint rollUnder, uint modulo, uint jfee) private pure returns (uint winAmount, uint jackpotFee){
        if (modulo == 37) {
            uint factor = 0;
            if (rollUnder == 1) {
                factor = 1 + 35;
            } else if (rollUnder == 2) {
                factor = 1 + 17;
            } else if (rollUnder == 3) {
                factor = 1 + 11;
            } else if (rollUnder == 4) {
                factor = 1 + 8;
            } else if (rollUnder == 6) {
                factor = 1 + 5;
            } else if (rollUnder == 12) {
                factor = 1 + 2;
            } else if (rollUnder == 18) {
                factor = 1 + 1;
            }
            winAmount = amount * factor;
        } else if (modulo == 216) {
            uint factor = 0;
            if (rollUnder == 107) { 
                factor = 10 + 9;
            } else if (rollUnder == 108) { 
                factor = 10 + 9;
            } else if (rollUnder == 16) { 
                factor = 10 + 120;
            } else if (rollUnder == 1) { 
                factor = 10 + 2000;
            } else if (rollUnder == 6) { 
                factor = 10 + 320;
            } else if (rollUnder == 3) { 
                factor = 10 + 640;
            } else if (rollUnder == 10) { 
                factor = 10 + 180;
            } else if (rollUnder == 15) { 
                factor = 10 + 120;
            } else if (rollUnder == 21) { 
                factor = 10 + 80;
            } else if (rollUnder == 25) { 
                factor = 10 + 60;
            } else if (rollUnder == 27) { 
                factor = 10 + 60;
            } else if (rollUnder == 30) { 
                factor = 10 + 50;
            } else if (rollUnder >= 211 && rollUnder <= 216) {
                 
                factor = 10 + 30;
            }
            winAmount = amount * factor / 10;
        } else {
            require(0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");
            if (jfee == 0) {
                jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;
            }
            uint houseEdge = amount * HOUSE_EDGE_OF_TEN_THOUSAND / 10000;
            if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
                houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
            }
            require(houseEdge + jackpotFee <= amount, "Bet doesn't even cover house edge.");
            winAmount = (amount - houseEdge - jackpotFee) * modulo / rollUnder;
            if (jfee > 0) {
                jackpotFee = jfee;
            }
        }
    }

    function placeBet(
        uint[] calldata betMasks,
        uint[] calldata values,
        uint[] calldata commitLastBlock0_commit1_r2_s3,
        uint source,
        uint modulo
    ) external payable {
        if (betMasks.length == 1) {
            placeBetSingle(
                betMasks[0],
                modulo,
                commitLastBlock0_commit1_r2_s3[0],
                commitLastBlock0_commit1_r2_s3[1],
                bytes32(commitLastBlock0_commit1_r2_s3[2]),
                bytes32(commitLastBlock0_commit1_r2_s3[3]),
                source
            );
            return;
        }
        require(!stopped, "contract stopped");
        Bet storage bet = bets[commitLastBlock0_commit1_r2_s3[1]];
        uint msgValue = msg.value;
        {
            require(bet.status == 0 && singleBets[commitLastBlock0_commit1_r2_s3[1]].status == 0, "Bet should be in a 'clean' state.");
            require(modulo >= 2 && modulo <= MAX_MODULO, "Modulo should be within range.");
             
            require(betMasks.length > 1 && betMasks.length == values.length);
             

             
            uint256 total = 0;
            for (uint256 i = 0; i < values.length; i++) {
                 
                 
                require(values[i] >= MIN_BET && values[i] <= 4293 ether, "Min Amount should be within range.");
                total = add(total, values[i]);
            }
            require(total == msgValue);

             
            require(block.number <= commitLastBlock0_commit1_r2_s3[0], "Commit has expired.");
            bytes32 signatureHash = keccak256(abi.encodePacked(
                    commitLastBlock0_commit1_r2_s3[0],
                    commitLastBlock0_commit1_r2_s3[1]
                ));
            require(secretSigner == ecrecover(signatureHash, 27,
                bytes32(commitLastBlock0_commit1_r2_s3[2]),
                bytes32(commitLastBlock0_commit1_r2_s3[3])), "ECDSA signature is not valid.");
        }

        uint possibleWinAmount = 0;
        uint jackpotFee;
        for (uint256 i = 0; i < betMasks.length; i++) {
            RawBet memory rb = RawBet({
                mask : uint216(betMasks[i]),
                amount : uint32(values[i] / 10 ** 12),  
                rollUnder : 0
                });

            if (modulo <= MASK_MODULO_40) {
                rb.rollUnder = uint8(((uint(rb.mask) * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO);
            } else if (modulo <= MASK_MODULO_40 * 2) {
                rb.rollUnder = uint8(getRollUnder(uint(rb.mask), 2));
            } else if (modulo == 100) {
                rb.rollUnder = uint8(uint(rb.mask));
            } else if (modulo <= MASK_MODULO_40 * 3) {
                rb.rollUnder = uint8(getRollUnder(uint(rb.mask), 3));
            } else if (modulo <= MASK_MODULO_40 * 4) {
                rb.rollUnder = uint8(getRollUnder(uint(rb.mask), 4));
            } else if (modulo <= MASK_MODULO_40 * 5) {
                rb.rollUnder = uint8(getRollUnder(uint(rb.mask), 5));
            } else {
                rb.rollUnder = uint8(getRollUnder(uint(rb.mask), 6));
            }

            uint amount;
             
            (amount, jackpotFee) = getWinAmount(uint(rb.amount) * 10 ** 12, rb.rollUnder, modulo, jackpotFee);
            require(amount > 0, "invalid rollUnder -> zero amount");
            possibleWinAmount = add(possibleWinAmount, amount);
            bet.rawBet.push(rb);
        }

        require(possibleWinAmount <= msgValue + maxProfit, "maxProfit limit violation.");
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);
        require(jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commitLastBlock0_commit1_r2_s3[1], source);
        bet.placeBlockNumber = uint40(block.number);
        bet.status = 1;
        bet.gambler = msg.sender;
        bet.modulo = uint8(modulo);
    }

    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));
        Bet storage bet = bets[commit];
        {
            uint placeBlockNumber = bet.placeBlockNumber;
            require(blockhash(placeBlockNumber) == blockHash, "blockHash invalid");
            require(block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
            require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        }
        require(bet.status == 1, "bet should be in a 'placed' status");

         
        bet.status = 2;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockHash));

         
        uint modulo = bet.modulo;
        uint roll = uint(entropy) % modulo;
        uint result = 2 ** roll;

        uint rollWin = 0;
        uint unlockAmount = 0;
        uint jackpotFee;
        uint len = bet.rawBet.length;
        for (uint256 i = 0; i < len; i++) {
            RawBet memory rb = bet.rawBet[i];
            uint possibleWinAmount;
            uint amount = uint(rb.amount) * 10 ** 12;
             
            (possibleWinAmount, jackpotFee) = getWinAmount(amount, rb.rollUnder, modulo, jackpotFee);
            unlockAmount += possibleWinAmount;

            if (modulo == 216 && 211 <= rb.rollUnder && rb.rollUnder <= 216) {
                uint matchDice = rb.rollUnder - 210;
                uint[] memory dices = tripleDicesTable(roll);
                uint count = 0;
                for (uint ii = 0; ii < 3; ii++) {
                    if (matchDice == dices[ii]) {
                        count++;
                    }
                }
                if (count == 1) {
                    rollWin += amount * (1 + 1);
                } else if (count == 2) {
                    rollWin += amount * (1 + 2);
                } else if (count == 3) {
                    rollWin += amount * (1 + 3);
                }
            } else if (modulo == 100) {
                if (roll < rb.rollUnder) {
                    rollWin += possibleWinAmount;
                }
            } else if (result & rb.mask != 0) {
                rollWin += possibleWinAmount;
            }
        }

         
        lockedInBets -= uint128(unlockAmount);

         
        uint jackpotWin = 0;
        if (jackpotFee > 0) {
             
             
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

             
            if (jackpotRng == 888 || IS_DEV) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

        address payable gambler = bet.gambler;
         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin, commit);
        }

         
        sendFunds(gambler, rollWin + jackpotWin == 0 ? 1 wei : rollWin + jackpotWin, rollWin, commit);
    }

    function refundBet(uint commit) external {
        Bet storage bet = bets[commit];
        if (bet.status == 0) {
            refundBetSingle(commit);
            return;
        }

        require(bet.status == 1, "bet should be in a 'placed' status");

         
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.status = 3;

        uint refundAmount = 0;
        uint unlockAmount = 0;
        uint jackpotFee;
        uint len = bet.rawBet.length;
        uint modulo = bet.modulo;
        for (uint256 i = 0; i < len; i++) {
            RawBet memory rb = bet.rawBet[i];
             
            uint amount = uint(rb.amount) * 10 ** 12;
            uint possibleWinAmount;
            (possibleWinAmount, jackpotFee) = getWinAmount(amount, rb.rollUnder, modulo, jackpotFee);
            unlockAmount += possibleWinAmount;
            refundAmount += amount;
        }

         
        lockedInBets -= uint128(unlockAmount);
        if (jackpotSize >= jackpotFee) {
            jackpotSize -= uint128(jackpotFee);
        }

         
        sendFunds(bet.gambler, refundAmount, refundAmount, commit);
    }

     
     
     

    function placeBetSingle(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 r, bytes32 s, uint source) public payable {
        require(!stopped, "contract stopped");
        SingleBet storage bet = singleBets[commit];

         
        require(bet.status == 0 && bets[commit].status == 0, "Bet should be in a 'clean' state.");

         
        uint amount = msg.value;
        require(modulo >= 2 && modulo <= MAX_MODULO, "Modulo should be within range.");
         
        require(amount >= MIN_BET && amount <= 4721 ether, "Amount should be within range.");
        require(betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

         
        require(block.number <= commitLastBlock, "Commit has expired.");
        bytes32 signatureHash = keccak256(abi.encodePacked(commitLastBlock, commit));
        require(secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

        uint rollUnder;

        if (modulo <= MASK_MODULO_40) {
             
             
             
             
            rollUnder = ((betMask * POPCNT_MULT) & POPCNT_MASK) % POPCNT_MODULO;
            bet.mask = uint216(betMask);
        } else if (modulo <= MASK_MODULO_40 * 2) {
            rollUnder = getRollUnder(betMask, 2);
            bet.mask = uint216(betMask);
        } else if (modulo == 100) {
            require(betMask > 0 && betMask <= modulo, "modulo=100: betMask larger than modulo");
            rollUnder = betMask;
            bet.mask = uint216(betMask);
        } else if (modulo <= MASK_MODULO_40 * 3) {
            rollUnder = getRollUnder(betMask, 3);
            bet.mask = uint216(betMask);
        } else if (modulo <= MASK_MODULO_40 * 4) {
            rollUnder = getRollUnder(betMask, 4);
            bet.mask = uint216(betMask);
        } else if (modulo <= MASK_MODULO_40 * 5) {
            rollUnder = getRollUnder(betMask, 5);
            bet.mask = uint216(betMask);
        } else { 
            rollUnder = getRollUnder(betMask, 6);
            bet.mask = uint216(betMask);
        }

         
        uint possibleWinAmount;
        uint jackpotFee;

         
        (possibleWinAmount, jackpotFee) = getWinAmount(amount, rollUnder, modulo, jackpotFee);
        require(possibleWinAmount > 0, "invalid rollUnder -> zero possibleWinAmount");

         
        require(possibleWinAmount <= amount + maxProfit, "maxProfit limit violation.");

         
        lockedInBets += uint128(possibleWinAmount);
        jackpotSize += uint128(jackpotFee);

         
        require(jackpotSize + lockedInBets <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit, source);

         
        bet.amount = uint72(amount);
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = uint40(block.number);
        bet.gambler = msg.sender;
        bet.status = 1;
    }

    function settleBetSingle(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));
        SingleBet storage bet = singleBets[commit];
        {
            uint placeBlockNumber = bet.placeBlockNumber;
            require(blockhash(placeBlockNumber) == blockHash, "blockHash invalid");
            require(block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
            require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        }
         
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address payable gambler = bet.gambler;

         
        require(bet.status == 1, "Bet should be in an 'active' state");

         
        bet.status = 2;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockHash));

         
        uint dice = uint(entropy) % modulo;

        (uint diceWinAmount, uint jackpotFee) = getWinAmount(amount, rollUnder, modulo, 0);

        uint diceWin = 0;
        uint jackpotWin = 0;

         
        if (modulo == 216 && 211 <= rollUnder && rollUnder <= 216) {
            uint matchDice = rollUnder - 210;
            uint[] memory dices = tripleDicesTable(dice);
            uint count = 0;
            for (uint ii = 0; ii < 3; ii++) {
                if (matchDice == dices[ii]) {
                    count++;
                }
            }
            if (count == 1) {
                diceWin += amount * (1 + 1);
            } else if (count == 2) {
                diceWin += amount * (1 + 2);
            } else if (count == 3) {
                diceWin += amount * (1 + 3);
            }
        } else if (modulo == 100) {
             
            if (dice < rollUnder) {
                diceWin = diceWinAmount;
            }
        } else {
             
            if ((2 ** dice) & bet.mask != 0) {
                diceWin = diceWinAmount;
            }
        }

         
        lockedInBets -= uint128(diceWinAmount);

         
        if (jackpotFee > 0) {
             
             
            uint jackpotRng = (uint(entropy) / modulo) % JACKPOT_MODULO;

             
            if (jackpotRng == 888 || IS_DEV) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin, commit);
        }

         
        sendFunds(gambler, diceWin + jackpotWin == 0 ? 1 wei : diceWin + jackpotWin, diceWin, commit);
    }

    function refundBetSingle(uint commit) private {
         
        SingleBet storage bet = singleBets[commit];
        uint amount = bet.amount;

        require(bet.status == 1, "bet should be in a 'placed' status");

         
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.status = 3;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getWinAmount(amount, bet.rollUnder, bet.modulo, 0);

        lockedInBets -= uint128(diceWinAmount);
        if (jackpotSize >= jackpotFee) {
            jackpotSize -= uint128(jackpotFee);
        }

         
        sendFunds(bet.gambler, amount, amount, commit);
    }
}

 