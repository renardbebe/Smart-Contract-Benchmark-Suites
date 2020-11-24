 

pragma solidity ^0.5.0;

contract HalfRouletteEvents {
    event Commit(uint commit);  
    event Payment(address indexed gambler, uint amount, uint8 betMask, uint8 l, uint8 r, uint betAmount);  
    event Refund(address indexed gambler, uint amount);  
    event JackpotPayment(address indexed gambler, uint amount);  
    event VIPBenefit(address indexed gambler, uint amount);  
    event InviterBenefit(address indexed inviter, address gambler, uint betAmount, uint amount);  
    event LuckyCoinBenefit(address indexed gambler, uint amount, uint32 result);  
    event TodaysRankingPayment(address indexed gambler, uint amount);  
}

contract HalfRouletteOwner {
    address payable owner;  
    address payable nextOwner;
    address secretSigner = 0xcb91F80fC3dcC6D51b10b1a6E6D77C28DAf7ffE2;  
    mapping(address => bool) public croupierMap;  

    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

    modifier onlyCroupier {
        bool isCroupier = croupierMap[msg.sender];
        require(isCroupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

    constructor() public {
        owner = msg.sender;
        croupierMap[msg.sender] = true;
    }

    function approveNextOwner(address payable _nextOwner) external onlyOwner {
        require(_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require(msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

    function addCroupier(address newCroupier) external onlyOwner {
        bool isCroupier = croupierMap[newCroupier];
        if (isCroupier == false) {
            croupierMap[newCroupier] = true;
        }
    }

    function deleteCroupier(address newCroupier) external onlyOwner {
        bool isCroupier = croupierMap[newCroupier];
        if (isCroupier == true) {
            croupierMap[newCroupier] = false;
        }
    }

}

contract HalfRouletteStruct {
    struct Bet {
        uint amount;  
        uint8 betMask;  
        uint40 placeBlockNumber;  
        address payable gambler;  
    }

    struct LuckyCoin {
        bool coin;  
        uint16 result;  
        uint64 amount;  
        uint64 timestamp;  
    }

    struct DailyRankingPrize {
        uint128 prizeSize;  
        uint64 timestamp;  
        uint8 cnt;  
    }
}

contract HalfRouletteConstant {
     
     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

    uint constant JACKPOT_FEE_PERCENT = 1;  
    uint constant HOUSE_EDGE_PERCENT = 1;  
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0004 ether;  

    uint constant RANK_FUNDS_PERCENT = 12;  
    uint constant INVITER_BENEFIT_PERCENT = 9;  

    uint constant MAX_LUCKY_COIN_BENEFIT = 1.65 ether;  
    uint constant MIN_BET = 0.01 ether;  
    uint constant MAX_BET = 300000 ether;  
    uint constant MIN_JACKPOT_BET = 0.1 ether;
    uint constant RECEIVE_LUCKY_COIN_BET = 0.05 ether;

    uint constant BASE_WIN_RATE = 100000;

    uint constant TODAY_RANKING_PRIZE_MODULUS = 10000;
     
    uint16[10] TODAY_RANKING_PRIZE_RATE = [5000, 2500, 1200, 600, 300, 200, 100, 50, 35, 15];
}

contract HalfRoulettePure is HalfRouletteConstant {

    function verifyBetMask(uint betMask) public pure {
        bool verify;
        assembly {
            switch betMask
            case 1  {verify := 1}
            case 2  {verify := 1}
            case 4  {verify := 1}
            case 8  {verify := 1}
            case 5  {verify := 1}
            case 9  {verify := 1}
            case 6  {verify := 1}
            case 10  {verify := 1}
            case 16  {verify := 1}
        }
        require(verify, "invalid betMask");
    }

    function getRecoverSigner(uint40 commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) public pure returns (address) {
        bytes32 messageHash = keccak256(abi.encodePacked(commitLastBlock, commit));
        return ecrecover(messageHash, v, r, s);
    }

    function getWinRate(uint betMask) public pure returns (uint rate) {
         
        uint ODD_EVEN_RATE = 50000;
        uint LEFT_RIGHT_RATE = 45833;
        uint MIX_RATE = 22916;
        uint EQUAL_RATE = 8333;
        assembly {
            switch betMask
            case 1  {rate := ODD_EVEN_RATE}
            case 2  {rate := ODD_EVEN_RATE}
            case 4  {rate := LEFT_RIGHT_RATE}
            case 8  {rate := LEFT_RIGHT_RATE}
            case 5  {rate := MIX_RATE}
            case 9  {rate := MIX_RATE}
            case 6  {rate := MIX_RATE}
            case 10  {rate := MIX_RATE}
            case 16  {rate := EQUAL_RATE}
        }
    }

    function calcHouseEdge(uint amount) public pure returns (uint houseEdge) {
         
        houseEdge = amount * HOUSE_EDGE_PERCENT / 100;
        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }
    }

    function calcJackpotFee(uint amount) public pure returns (uint jackpotFee) {
         
        jackpotFee = amount * JACKPOT_FEE_PERCENT / 1000;
    }

    function calcRankFundsFee(uint houseEdge) public pure returns (uint rankFundsFee) {
         
        rankFundsFee = houseEdge * RANK_FUNDS_PERCENT / 100;
    }

    function calcInviterBenefit(uint houseEdge) public pure returns (uint invitationFee) {
         
        invitationFee = houseEdge * INVITER_BENEFIT_PERCENT / 100;
    }

    function calcVIPBenefit(uint amount, uint totalAmount) public pure returns (uint vipBenefit) {
         
        uint rate;
        if (totalAmount < 25 ether) {
            return rate;
        } else if (totalAmount < 125 ether) {
            rate = 1;
        } else if (totalAmount < 250 ether) {
            rate = 2;
        } else if (totalAmount < 1250 ether) {
            rate = 3;
        } else if (totalAmount < 2500 ether) {
            rate = 4;
        } else if (totalAmount < 12500 ether) {
            rate = 5;
        } else if (totalAmount < 25000 ether) {
            rate = 7;
        } else if (totalAmount < 125000 ether) {
            rate = 9;
        } else if (totalAmount < 250000 ether) {
            rate = 11;
        } else if (totalAmount < 1250000 ether) {
            rate = 13;
        } else {
            rate = 15;
        }
        vipBenefit = amount * rate / 10000;
    }

    function calcLuckyCoinBenefit(uint num) public pure returns (uint luckCoinBenefit) {
         
        if (num < 9886) {
            return 0.000015 ether;
        } else if (num < 9986) {
            return 0.00015 ether;
        } else if (num < 9994) {
            return 0.0015 ether;
        } else if (num < 9998) {
            return 0.015 ether;
        } else if (num < 10000) {
            return 0.15 ether;
        } else {
            return 1.65 ether;
        }
    }

    function getWinAmount(uint betMask, uint amount) public pure returns (uint) {
        uint houseEdge = calcHouseEdge(amount);
        uint jackpotFee = calcJackpotFee(amount);
        uint betAmount = amount - houseEdge - jackpotFee;
        uint rate = getWinRate(betMask);
        return betAmount * BASE_WIN_RATE / rate;
    }

    function calcBetResult(uint betMask, bytes32 entropy) public pure returns (bool isWin, uint l, uint r)  {
        uint v = uint(entropy);
        l = (v % 12) + 1;
        r = ((v >> 4) % 12) + 1;
        uint mask = getResultMask(l, r);
        isWin = (betMask & mask) == betMask;
    }

    function getResultMask(uint l, uint r) public pure returns (uint mask) {
        uint v1 = (l + r) % 2;
        uint v2 = l - r;
        if (v1 == 0) {
            mask = mask | 2;
        } else {
            mask = mask | 1;
        }

        if (v2 == 0) {
            mask = mask | 16;
        } else if (v2 > 0) {
            mask = mask | 4;
        } else {
            mask = mask | 8;
        }
        return mask;
    }

    function isJackpot(bytes32 entropy, uint amount) public pure returns (bool jackpot) {
        return amount >= MIN_JACKPOT_BET && (uint(entropy) % 1000) == 0;
    }

    function verifyCommit(address signer, uint40 commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) internal pure {
        address recoverSigner = getRecoverSigner(commitLastBlock, commit, v, r, s);
        require(recoverSigner == signer, "failed different signer");
    }

    function startOfDay(uint timestamp) internal pure returns (uint64) {
        return uint64(timestamp - (timestamp % 1 days));
    }

}

contract HalfRoulette is HalfRouletteEvents, HalfRouletteOwner, HalfRouletteStruct, HalfRouletteConstant, HalfRoulettePure {
    uint128 public lockedInBets;
    uint128 public jackpotSize;  
    uint128 public rankFunds;  
    DailyRankingPrize dailyRankingPrize;

     
    uint public maxProfit = 10 ether;

     
    mapping(uint => Bet) public bets;
    mapping(address => LuckyCoin) public luckyCoins;
    mapping(address => address payable) public inviterMap;
    mapping(address => uint) public accuBetAmount;

    function() external payable {}

    function kill() external onlyOwner {
        require(lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(address(owner));
    }

    function setMaxProfit(uint _maxProfit) external onlyOwner {
        require(_maxProfit < MAX_BET, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

    function placeBet(uint8 betMask, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s) public payable {
        Bet storage bet = bets[commit];
        require(bet.gambler == address(0), "Bet should be in a 'clean' state.");

         
        uint amount = msg.value;
        require(amount >= MIN_BET, 'failed amount >= MIN_BET');
        require(amount <= MAX_BET, "failed amount <= MAX_BET");
         
        verifyBetMask(betMask);
         
        verifyCommit(secretSigner, uint40(commitLastBlock), commit, v, r, s);

         
        uint winAmount = getWinAmount(betMask, amount);
        require(winAmount <= amount + maxProfit, "maxProfit limit violation.");
        lockedInBets += uint128(winAmount);
        require(lockedInBets + jackpotSize + rankFunds + dailyRankingPrize.prizeSize <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);
        bet.gambler = msg.sender;
        bet.amount = amount;
        bet.betMask = betMask;
        bet.placeBlockNumber = uint40(block.number);

         
        incLuckyCoin(msg.sender, amount);
    }

    function placeBetWithInviter(uint8 betMask, uint commitLastBlock, uint commit, uint8 v, bytes32 r, bytes32 s, address payable inviter) external payable {
        require(inviter != address(0), "inviter != address (0)");
        address preInviter = inviterMap[msg.sender];
        if (preInviter == address(0)) {
            inviterMap[msg.sender] = inviter;
        }
        placeBet(betMask, commitLastBlock, commit, v, r, s);
    }

     
    function incLuckyCoin(address gambler, uint amount) internal {
        LuckyCoin storage luckyCoin = luckyCoins[gambler];

        uint64 today = startOfDay(block.timestamp);
        uint beforeAmount;

        if (today == luckyCoin.timestamp) {
            beforeAmount = uint(luckyCoin.amount);
        } else {
            luckyCoin.timestamp = today;
            if (luckyCoin.coin) luckyCoin.coin = false;
        }

        if (beforeAmount == RECEIVE_LUCKY_COIN_BET) return;

        uint totalAmount = beforeAmount + amount;

        if (totalAmount >= RECEIVE_LUCKY_COIN_BET) {
            luckyCoin.amount = uint64(RECEIVE_LUCKY_COIN_BET);
            if (!luckyCoin.coin) {
                luckyCoin.coin = true;
            }
        } else {
            luckyCoin.amount = uint64(totalAmount);
        }
    }

    function revertLuckyCoin(address gambler) private {
        LuckyCoin storage luckyCoin = luckyCoins[gambler];
        if (!luckyCoin.coin) return;
        if (startOfDay(block.timestamp) == luckyCoin.timestamp) {
            luckyCoin.coin = false;
        }
    }

    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];
        uint placeBlockNumber = bet.placeBlockNumber;

         
        require(block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require(block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");
        require(blockhash(placeBlockNumber) == blockHash);

         
        settleBetCommon(bet, reveal, blockHash);
    }

     
     
     
     
     
    function settleBetUncleMerkleProof(uint reveal, uint40 canonicalBlockNumber) external onlyCroupier {
         
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];

         
        require(block.number <= canonicalBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        requireCorrectReceipt(4 + 32 + 32 + 4);

         
        bytes32 canonicalHash;
        bytes32 uncleHash;
        (canonicalHash, uncleHash) = verifyMerkleProof(commit, 4 + 32 + 32);
        require(blockhash(canonicalBlockNumber) == canonicalHash);

         
        settleBetCommon(bet, reveal, uncleHash);
    }

     
     
    function requireCorrectReceipt(uint offset) view private {
        uint leafHeaderByte;
        assembly {leafHeaderByte := byte(0, calldataload(offset))}

        require(leafHeaderByte >= 0xf7, "Receipt leaf longer than 55 bytes.");
        offset += leafHeaderByte - 0xf6;

        uint pathHeaderByte;
        assembly {pathHeaderByte := byte(0, calldataload(offset))}

        if (pathHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require(pathHeaderByte >= 0x80 && pathHeaderByte <= 0xb7, "Path is an RLP string.");
            offset += pathHeaderByte - 0x7f;
        }

        uint receiptStringHeaderByte;
        assembly {receiptStringHeaderByte := byte(0, calldataload(offset))}
        require(receiptStringHeaderByte == 0xb9, "Receipt string is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint receiptHeaderByte;
        assembly {receiptHeaderByte := byte(0, calldataload(offset))}
        require(receiptHeaderByte == 0xf9, "Receipt is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint statusByte;
        assembly {statusByte := byte(0, calldataload(offset))}
        require(statusByte == 0x1, "Status should be success.");
        offset += 1;

        uint cumGasHeaderByte;
        assembly {cumGasHeaderByte := byte(0, calldataload(offset))}
        if (cumGasHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require(cumGasHeaderByte >= 0x80 && cumGasHeaderByte <= 0xb7, "Cumulative gas is an RLP string.");
            offset += cumGasHeaderByte - 0x7f;
        }

        uint bloomHeaderByte;
        assembly {bloomHeaderByte := byte(0, calldataload(offset))}
        require(bloomHeaderByte == 0xb9, "Bloom filter is always 256 bytes long.");
        offset += 256 + 3;

        uint logsListHeaderByte;
        assembly {logsListHeaderByte := byte(0, calldataload(offset))}
        require(logsListHeaderByte == 0xf8, "Logs list is less than 256 bytes long.");
        offset += 2;

        uint logEntryHeaderByte;
        assembly {logEntryHeaderByte := byte(0, calldataload(offset))}
        require(logEntryHeaderByte == 0xf8, "Log entry is less than 256 bytes long.");
        offset += 2;

        uint addressHeaderByte;
        assembly {addressHeaderByte := byte(0, calldataload(offset))}
        require(addressHeaderByte == 0x94, "Address is 20 bytes long.");

        uint logAddress;
        assembly {logAddress := and(calldataload(sub(offset, 11)), 0xffffffffffffffffffffffffffffffffffffffff)}
        require(logAddress == uint(address(this)));
    }
     
    function verifyMerkleProof(uint seedHash, uint offset) pure private returns (bytes32 blockHash, bytes32 uncleHash) {
         
        uint scratchBuf1;
        assembly {scratchBuf1 := mload(0x40)}

        uint uncleHeaderLength;
        uint blobLength;
        uint shift;
        uint hashSlot;

         
         
         
         
        for (;; offset += blobLength) {
            assembly {blobLength := and(calldataload(sub(offset, 30)), 0xffff)}
            if (blobLength == 0) {
                 
                break;
            }

            assembly {shift := and(calldataload(sub(offset, 28)), 0xffff)}
            require(shift + 32 <= blobLength, "Shift bounds check.");

            offset += 4;
            assembly {hashSlot := calldataload(add(offset, shift))}
            require(hashSlot == 0, "Non-empty hash slot.");

            assembly {
                calldatacopy(scratchBuf1, offset, blobLength)
                mstore(add(scratchBuf1, shift), seedHash)
                seedHash := keccak256(scratchBuf1, blobLength)
                uncleHeaderLength := blobLength
            }
        }

         
        uncleHash = bytes32(seedHash);

         
        uint scratchBuf2 = scratchBuf1 + uncleHeaderLength;
        uint unclesLength;
        assembly {unclesLength := and(calldataload(sub(offset, 28)), 0xffff)}
        uint unclesShift;
        assembly {unclesShift := and(calldataload(sub(offset, 26)), 0xffff)}
        require(unclesShift + uncleHeaderLength <= unclesLength, "Shift bounds check.");

        offset += 6;
        assembly {calldatacopy(scratchBuf2, offset, unclesLength)}
        memcpy(scratchBuf2 + unclesShift, scratchBuf1, uncleHeaderLength);

        assembly {seedHash := keccak256(scratchBuf2, unclesLength)}

        offset += unclesLength;

         
        assembly {
            blobLength := and(calldataload(sub(offset, 30)), 0xffff)
            shift := and(calldataload(sub(offset, 28)), 0xffff)
        }
        require(shift + 32 <= blobLength, "Shift bounds check.");

        offset += 4;
        assembly {hashSlot := calldataload(add(offset, shift))}
        require(hashSlot == 0, "Non-empty hash slot.");

        assembly {
            calldatacopy(scratchBuf1, offset, blobLength)
            mstore(add(scratchBuf1, shift), seedHash)

         
            blockHash := keccak256(scratchBuf1, blobLength)
        }
    }
     
    function memcpy(uint dest, uint src, uint len) pure private {
         
        for (; len >= 32; len -= 32) {
            assembly {mstore(dest, mload(src))}
            dest += 32;
            src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    function processVIPBenefit(address gambler, uint amount) internal returns (uint benefitAmount) {
        uint totalAmount = accuBetAmount[gambler];
        accuBetAmount[gambler] += amount;
        benefitAmount = calcVIPBenefit(amount, totalAmount);
    }

    function processJackpot(address gambler, bytes32 entropy, uint amount) internal returns (uint benefitAmount) {
        if (isJackpot(entropy, amount)) {
            benefitAmount = jackpotSize;
            jackpotSize -= jackpotSize;
            emit JackpotPayment(gambler, benefitAmount);
        }
    }

    function processRoulette(address gambler, uint betMask, bytes32 entropy, uint amount) internal returns (uint benefitAmount) {
        uint houseEdge = calcHouseEdge(amount);
        uint jackpotFee = calcJackpotFee(amount);
        uint rankFundFee = calcRankFundsFee(houseEdge);
        uint rate = getWinRate(betMask);
        uint winAmount = (amount - houseEdge - jackpotFee) * BASE_WIN_RATE / rate;

        lockedInBets -= uint128(winAmount);
        rankFunds += uint128(rankFundFee);
        jackpotSize += uint128(jackpotFee);

        (bool isWin, uint l, uint r) = calcBetResult(betMask, entropy);
        benefitAmount = isWin ? winAmount : 0;

        emit Payment(gambler, benefitAmount, uint8(betMask), uint8(l), uint8(r), amount);
    }

    function processInviterBenefit(address gambler, uint amount) internal {
        address payable inviter = inviterMap[gambler];
        if (inviter != address(0)) {
            uint houseEdge = calcHouseEdge(amount);
            uint inviterBenefit = calcInviterBenefit(houseEdge);
            inviter.transfer(inviterBenefit);
            emit InviterBenefit(inviter, gambler, inviterBenefit, amount);
        }
    }

    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) internal {
        uint amount = bet.amount;

         
        require(amount != 0, "Bet should be in an 'active' state");
        bet.amount = 0;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

        uint payout = 0;
        payout += processVIPBenefit(bet.gambler, amount);
        payout += processJackpot(bet.gambler, entropy, amount);
        payout += processRoulette(bet.gambler, bet.betMask, entropy, amount);

        processInviterBenefit(bet.gambler, amount);

        bet.gambler.transfer(payout);
    }

     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require(amount != 0, "Bet should be in an 'active' state");

         
        require(block.number > bet.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;

        uint winAmount = getWinAmount(bet.betMask, amount);
        lockedInBets -= uint128(winAmount);

        revertLuckyCoin(bet.gambler);

         
        bet.gambler.transfer(amount);

        emit Refund(bet.gambler, amount);
    }

    function useLuckyCoin(address payable gambler, uint reveal) external onlyCroupier {
        LuckyCoin storage luckyCoin = luckyCoins[gambler];
        require(luckyCoin.coin == true, "luckyCoin.coin == true");

        uint64 today = startOfDay(block.timestamp);
        require(luckyCoin.timestamp == today, "luckyCoin.timestamp == today");
        luckyCoin.coin = false;

        bytes32 entropy = keccak256(abi.encodePacked(reveal, blockhash(block.number)));

        luckyCoin.result = uint16((uint(entropy) % 10000) + 1);
        uint benefit = calcLuckyCoinBenefit(luckyCoin.result);

        if (gambler.send(benefit)) {
            emit LuckyCoinBenefit(gambler, benefit, luckyCoin.result);
        }
    }

    function payTodayReward(address payable gambler) external onlyCroupier {
        uint64 today = startOfDay(block.timestamp);
        if (dailyRankingPrize.timestamp != today) {
            dailyRankingPrize.timestamp = today;
            dailyRankingPrize.prizeSize = rankFunds;
            dailyRankingPrize.cnt = 0;
            rankFunds = 0;
        }

        require(dailyRankingPrize.cnt < TODAY_RANKING_PRIZE_RATE.length, "cnt < length");

        uint prize = dailyRankingPrize.prizeSize * TODAY_RANKING_PRIZE_RATE[dailyRankingPrize.cnt] / TODAY_RANKING_PRIZE_MODULUS;

        dailyRankingPrize.cnt += 1;

        if (gambler.send(prize)) {
            emit TodaysRankingPayment(gambler, prize);
        }
    }

     
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require(increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + increaseAmount + dailyRankingPrize.prizeSize <= address(this).balance, "Not enough funds.");
        jackpotSize += uint128(increaseAmount);
    }

     
    function withdrawFunds(address payable beneficiary, uint withdrawAmount) external onlyOwner {
        require(withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require(jackpotSize + lockedInBets + withdrawAmount + rankFunds + dailyRankingPrize.prizeSize <= address(this).balance, "Not enough funds.");
        beneficiary.transfer(withdrawAmount);
    }

}