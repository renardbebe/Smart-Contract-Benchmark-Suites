 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
contract FairHouse {

    using SafeMath for uint256;
    using NameFilter for string;

     

     
     
     
    uint constant HOUSE_EDGE_PERCENT = 1;
    uint constant HOUSE_EDGE_MINIMUM_AMOUNT = 0.0003 ether;

     
     
     
    uint constant RECOMMENDER_PERCENT = 50;

     
     
    uint constant MIN_JACKPOT_BET = 0.1 ether;

     
    uint constant JACKPOT_MODULO = 1000;
    uint constant JACKPOT_FEE = 0.001 ether;

     
    uint constant MIN_BET = 0.01 ether;
    uint constant MAX_AMOUNT = 300000 ether;

     
     
     
     
     
     
     
     
     
    uint constant MAX_MODULO = 100;

     
     
     
     
     
     
     
     
     
     
    uint constant MAX_MASK_MODULO = 40;

     
    uint constant MAX_BET_MASK = 2 ** MAX_MASK_MODULO;

     
     
     
     
     
     
    uint constant BET_EXPIRATION_BLOCKS = 250;

     
     
    address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

     
    address public owner;
    address private nextOwner;

     
    uint public maxProfit;

     
    address public secretSigner;

     
    uint public jackpotSize;

     
     
    uint public lockedInBets;

     
    struct Bet {
         
        uint amount;
         
        uint8 modulo;
         
         
        uint8 rollUnder;
         
        uint placeBlockNumber;
         
        uint40 mask;
         
        address gambler;
    }

     
    mapping (uint => Bet) bets;

     
    address public croupier;

     
    uint constant REGISTRATION_FEE = 0.05 ether;

     
    uint playerId = 0;

    struct Player {
        address addr;
        bytes32 name;
        uint recPid;
    }

    mapping (address => uint256) pidXaddr;
    mapping (bytes32 => uint256) pidXname;
    mapping (uint256 => Player) playerXpid;

     
    event FailedPayment(address indexed beneficiary, uint amount);
    event Payment(address indexed beneficiary, uint amount);
    event RecommendPayment(address indexed beneficiary, uint amount);
    event JackpotPayment(address indexed beneficiary, uint amount);
    event OnRegisterName(uint indexed pid, bytes32 indexed pname, address indexed paddr, uint recPid, bytes32 recPname, address recPaddr, uint amountPaid, bool isNewPlayer, uint timeStamp);

     
    event Commit(uint commit);

     
    constructor () public {
        owner = msg.sender;
        secretSigner = DUMMY_ADDRESS;
        croupier = DUMMY_ADDRESS;
    }

     
    modifier onlyOwner {
        require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }

     
    modifier onlyCroupier {
        require (msg.sender == croupier, "OnlyCroupier methods called by non-croupier.");
        _;
    }

     
    function approveNextOwner(address _nextOwner) external onlyOwner {
        require (_nextOwner != owner, "Cannot approve current owner.");
        nextOwner = _nextOwner;
    }

    function acceptNextOwner() external {
        require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
        owner = nextOwner;
    }

     
     
    function () public payable {
    }

     
    function setSecretSigner(address newSecretSigner) external onlyOwner {
        secretSigner = newSecretSigner;
    }

     
    function setCroupier(address newCroupier) external onlyOwner {
        croupier = newCroupier;
    }

     
    function setMaxProfit(uint _maxProfit) public onlyOwner {
        require (_maxProfit < MAX_AMOUNT, "maxProfit should be a sane number.");
        maxProfit = _maxProfit;
    }

     
    function increaseJackpot(uint increaseAmount) external onlyOwner {
        require (increaseAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize.add(lockedInBets).add(increaseAmount) <= address(this).balance, "Not enough funds.");
        jackpotSize = jackpotSize.add(increaseAmount);
    }

     
    function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
        require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
        require (jackpotSize.add(lockedInBets).add(withdrawAmount) <= address(this).balance, "Not enough funds.");
        sendFunds(beneficiary, withdrawAmount, withdrawAmount);
    }

     
     
    function kill() external onlyOwner {
        require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
        selfdestruct(owner);
    }

     

     
     
     
     
     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function placeBet(uint betMask, uint modulo, uint commitLastBlock, uint commit, bytes32 recCode, bytes32 r, bytes32 s) external payable {
         
        Bet storage bet = bets[commit];
        require (bet.gambler == address(0), "Bet should be in a 'clean' state.");

         
        require (modulo > 1 && modulo <= MAX_MODULO, "Modulo should be within range.");
        require (msg.value >= MIN_BET && msg.value <= MAX_AMOUNT, "Amount should be within range.");
        require (betMask > 0 && betMask < MAX_BET_MASK, "Mask should be within range.");

         
        require (block.number <= commitLastBlock && commitLastBlock <= block.number.add(BET_EXPIRATION_BLOCKS), "Commit has expired.");
         
         
        require (secretSigner == ecrecover(keccak256(abi.encodePacked(uint40(commitLastBlock), commit)), 27, r, s), "ECDSA signature is not valid.");

        uint rollUnder;
         

        if (modulo <= MAX_MASK_MODULO) {
             
             
             
             
            rollUnder = ((betMask.mul(POPCNT_MULT)) & POPCNT_MASK).mod(POPCNT_MODULO);
             
            bet.mask = uint40(betMask);
        } else {
             
             
            require (betMask > 0 && betMask <= modulo, "High modulo range, betMask larger than modulo.");
            rollUnder = betMask;
        }

         
        uint possibleWinAmount;
        uint jackpotFee;

        (possibleWinAmount, jackpotFee) = getDiceWinAmount(msg.value, modulo, rollUnder);

         
        require (possibleWinAmount <= msg.value.add(maxProfit), "maxProfit limit violation.");

         
        lockedInBets = lockedInBets.add(possibleWinAmount);
        jackpotSize = jackpotSize.add(jackpotFee);

         
        require (jackpotSize.add(lockedInBets) <= address(this).balance, "Cannot afford to lose this bet.");

         
        emit Commit(commit);

         
        bet.amount = msg.value;
        bet.modulo = uint8(modulo);
        bet.rollUnder = uint8(rollUnder);
        bet.placeBlockNumber = block.number;
         
        bet.gambler = msg.sender;

         
        placeBetBindCore(msg.sender, recCode);
    }

     
     
     
     
    function settleBet(uint reveal, bytes32 blockHash) external onlyCroupier {
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];

         
        require (block.number > bet.placeBlockNumber, "settleBet in the same block as placeBet, or before.");
        require (block.number <= bet.placeBlockNumber.add(BET_EXPIRATION_BLOCKS), "Blockhash can't be queried by EVM.");
        require (blockhash(bet.placeBlockNumber) == blockHash);

         
        settleBetCommon(bet, reveal, blockHash);
    }

     
     
     
     
     
    function settleBetUncleMerkleProof(uint reveal, uint canonicalBlockNumber) external onlyCroupier {
         
        uint commit = uint(keccak256(abi.encodePacked(reveal)));

        Bet storage bet = bets[commit];

         
        require (block.number <= canonicalBlockNumber.add(BET_EXPIRATION_BLOCKS), "Blockhash can't be queried by EVM.");

         
        requireCorrectReceipt(4 + 32 + 32 + 4);

         
        bytes32 canonicalHash;
        bytes32 uncleHash;
        (canonicalHash, uncleHash) = verifyMerkleProof(commit, 4 + 32 + 32);
        require (blockhash(canonicalBlockNumber) == canonicalHash);

         
        settleBetCommon(bet, reveal, uncleHash);
    }

     
    function settleBetCommon(Bet storage bet, uint reveal, bytes32 entropyBlockHash) private {
         
        uint amount = bet.amount;
        uint modulo = bet.modulo;
        uint rollUnder = bet.rollUnder;
        address gambler = bet.gambler;

         
        require (amount != 0, "Bet should be in an 'active' state");

         
        bet.amount = 0;

         
         
         
         
        bytes32 entropy = keccak256(abi.encodePacked(reveal, entropyBlockHash));

         
        uint dice = uint(entropy).mod(modulo);

        uint diceWinAmount;
        uint _jackpotFee;
        (diceWinAmount, _jackpotFee) = getDiceWinAmount(amount, modulo, rollUnder);

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

         
        lockedInBets = lockedInBets.sub(diceWinAmount);

         
        if (amount >= MIN_JACKPOT_BET) {
             
             
            uint jackpotRng = (uint(entropy).div(modulo)).mod(JACKPOT_MODULO);

             
            if (jackpotRng == 0) {
                jackpotWin = jackpotSize;
                jackpotSize = 0;
            }
        }

         
        if (jackpotWin > 0) {
            emit JackpotPayment(gambler, jackpotWin);
        }

         
        settleToRecommender(gambler, amount);

         
        sendFunds(gambler, diceWin.add(jackpotWin) == 0 ? 1 wei : diceWin.add(jackpotWin), diceWin);
    }

     
     
     
     
     
    function refundBet(uint commit) external {
         
        Bet storage bet = bets[commit];
        uint amount = bet.amount;

        require (amount != 0, "Bet should be in an 'active' state");

         
        require (block.number > bet.placeBlockNumber.add(BET_EXPIRATION_BLOCKS), "Blockhash can't be queried by EVM.");

         
        bet.amount = 0;

        uint diceWinAmount;
        uint jackpotFee;
        (diceWinAmount, jackpotFee) = getDiceWinAmount(amount, bet.modulo, bet.rollUnder);

        lockedInBets = lockedInBets.sub(diceWinAmount);
        jackpotSize = jackpotSize.sub(jackpotFee);

         
        sendFunds(bet.gambler, amount, amount);
    }

     
    function settleToRecommender(address gambler, uint amount) private {
         
        uint pid = pidXaddr[gambler];
        Player storage _gambler = playerXpid[pid];
        if (_gambler.recPid > 0) {
            Player storage _recommender = playerXpid[_gambler.recPid];
             
            uint houseEdge = amount.mul(HOUSE_EDGE_PERCENT).div(100);

             
            if (houseEdge > HOUSE_EDGE_MINIMUM_AMOUNT) {

                uint recFee = houseEdge.mul(RECOMMENDER_PERCENT).div(100);

                 
                sendRecommendFunds(_recommender.addr, recFee);
            }
        }
    }

     
    function registerName(string nameStr, bytes32 recCode) external payable returns(bool, uint256) {
         
        require (msg.value >= REGISTRATION_FEE, "You have to pay the name fee");

         
        bytes32 name = NameFilter.nameFilter(nameStr);
        require(pidXname[name] == 0, "Sorry that name already taken");

         
        address addr = msg.sender;

         
        bool isNewPlayer = determinePid(addr);

         
        uint pid = pidXaddr[addr];
        pidXname[name] = pid;
        playerXpid[pid].name = name;

        uint recPid;

         
        if (isNewPlayer && recCode != "" && recCode != name) {
             
            recPid = pidXname[recCode];

            bindRecommender(pid, recPid);
        }

        Player storage recPlayer = playerXpid[recPid];
        emit OnRegisterName(pid, name, addr, recPid, recPlayer.name, recPlayer.addr, msg.value, isNewPlayer, now);

        return(isNewPlayer, recPid);
    }

    function getRegisterName(address addr) external view returns(bytes32) {
        return (playerXpid[pidXaddr[addr]].name);
    }

    function placeBetBindCore(address addr, bytes32 recCode) private {
        bool isNewPlayer = determinePid(addr);

         
        if (isNewPlayer && recCode != "") {
             
            uint pid = pidXaddr[addr];

             
            if (recCode != playerXpid[pid].name) {
                 
                uint recPid = pidXname[recCode];

                 
                bindRecommender(pid, recPid);
            }
        }
    }

     
    function getDiceWinAmount(uint amount, uint modulo, uint rollUnder) private pure returns (uint winAmount, uint jackpotFee) {
        require (0 < rollUnder && rollUnder <= modulo, "Win probability out of range.");

        jackpotFee = amount >= MIN_JACKPOT_BET ? JACKPOT_FEE : 0;

        uint houseEdge = amount.mul(HOUSE_EDGE_PERCENT).div(100);

        if (houseEdge < HOUSE_EDGE_MINIMUM_AMOUNT) {
            houseEdge = HOUSE_EDGE_MINIMUM_AMOUNT;
        }

        require (houseEdge.add(jackpotFee) <= amount, "Bet doesn't even cover house edge.");
        winAmount = amount.sub(houseEdge).sub(jackpotFee).mul(modulo).div(rollUnder);
    }

     
    function sendFunds(address beneficiary, uint amount, uint successLogAmount) private {
        if (beneficiary.send(amount)) {
            emit Payment(beneficiary, successLogAmount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    function sendRecommendFunds(address beneficiary, uint amount) private {
        if (beneficiary.send(amount)) {
            emit RecommendPayment(beneficiary, amount);
        } else {
            emit FailedPayment(beneficiary, amount);
        }
    }

    function determinePid(address addr) private returns (bool) {
        if (pidXaddr[addr] == 0) {
            playerId++;
            pidXaddr[addr] = playerId;
            playerXpid[playerId].addr = addr;

             
            return (true);
        } else {
            return (false);
        }
    }

    function bindRecommender(uint256 pid, uint256 recPid) private {
         
        if (recPid != 0 && playerXpid[pid].recPid == 0 && playerXpid[pid].recPid != recPid) {
            playerXpid[pid].recPid = recPid;
        }
    }

     
     
    uint constant POPCNT_MULT = 0x0000000000002000000000100000000008000000000400000000020000000001;
    uint constant POPCNT_MASK = 0x0001041041041041041041041041041041041041041041041041041041041041;
    uint constant POPCNT_MODULO = 0x3F;

     

     
     
     
     
     
     
     
     
     
     
     

     
     
    function verifyMerkleProof(uint seedHash, uint offset) pure private returns (bytes32 blockHash, bytes32 uncleHash) {
         
        uint scratchBuf1;  assembly { scratchBuf1 := mload(0x40) }

        uint uncleHeaderLength; uint blobLength; uint shift; uint hashSlot;

         
         
         
         
        for (;; offset += blobLength) {
            assembly { blobLength := and(calldataload(sub(offset, 30)), 0xffff) }
            if (blobLength == 0) {
                 
                break;
            }

            assembly { shift := and(calldataload(sub(offset, 28)), 0xffff) }
            require (shift + 32 <= blobLength, "Shift bounds check.");

            offset += 4;
            assembly { hashSlot := calldataload(add(offset, shift)) }
            require (hashSlot == 0, "Non-empty hash slot.");

            assembly {
                calldatacopy(scratchBuf1, offset, blobLength)
                mstore(add(scratchBuf1, shift), seedHash)
                seedHash := sha3(scratchBuf1, blobLength)
                uncleHeaderLength := blobLength
            }
        }

         
        uncleHash = bytes32(seedHash);

         
        uint scratchBuf2 = scratchBuf1 + uncleHeaderLength;
        uint unclesLength; assembly { unclesLength := and(calldataload(sub(offset, 28)), 0xffff) }
        uint unclesShift;  assembly { unclesShift := and(calldataload(sub(offset, 26)), 0xffff) }
        require (unclesShift + uncleHeaderLength <= unclesLength, "Shift bounds check.");

        offset += 6;
        assembly { calldatacopy(scratchBuf2, offset, unclesLength) }
        memcpy(scratchBuf2 + unclesShift, scratchBuf1, uncleHeaderLength);

        assembly { seedHash := sha3(scratchBuf2, unclesLength) }

        offset += unclesLength;

         
        assembly {
            blobLength := and(calldataload(sub(offset, 30)), 0xffff)
            shift := and(calldataload(sub(offset, 28)), 0xffff)
        }
        require (shift + 32 <= blobLength, "Shift bounds check.");

        offset += 4;
        assembly { hashSlot := calldataload(add(offset, shift)) }
        require (hashSlot == 0, "Non-empty hash slot.");

        assembly {
            calldatacopy(scratchBuf1, offset, blobLength)
            mstore(add(scratchBuf1, shift), seedHash)

         
            blockHash := sha3(scratchBuf1, blobLength)
        }
    }

     
     
    function requireCorrectReceipt(uint offset) view private {
        uint leafHeaderByte; assembly { leafHeaderByte := byte(0, calldataload(offset)) }

        require (leafHeaderByte >= 0xf7, "Receipt leaf longer than 55 bytes.");
        offset += leafHeaderByte - 0xf6;

        uint pathHeaderByte; assembly { pathHeaderByte := byte(0, calldataload(offset)) }

        if (pathHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (pathHeaderByte >= 0x80 && pathHeaderByte <= 0xb7, "Path is an RLP string.");
            offset += pathHeaderByte - 0x7f;
        }

        uint receiptStringHeaderByte; assembly { receiptStringHeaderByte := byte(0, calldataload(offset)) }
        require (receiptStringHeaderByte == 0xb9, "Receipt string is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint receiptHeaderByte; assembly { receiptHeaderByte := byte(0, calldataload(offset)) }
        require (receiptHeaderByte == 0xf9, "Receipt is always at least 256 bytes long, but less than 64k.");
        offset += 3;

        uint statusByte; assembly { statusByte := byte(0, calldataload(offset)) }
        require (statusByte == 0x1, "Status should be success.");
        offset += 1;

        uint cumGasHeaderByte; assembly { cumGasHeaderByte := byte(0, calldataload(offset)) }
        if (cumGasHeaderByte <= 0x7f) {
            offset += 1;

        } else {
            require (cumGasHeaderByte >= 0x80 && cumGasHeaderByte <= 0xb7, "Cumulative gas is an RLP string.");
            offset += cumGasHeaderByte - 0x7f;
        }

        uint bloomHeaderByte; assembly { bloomHeaderByte := byte(0, calldataload(offset)) }
        require (bloomHeaderByte == 0xb9, "Bloom filter is always 256 bytes long.");
        offset += 256 + 3;

        uint logsListHeaderByte; assembly { logsListHeaderByte := byte(0, calldataload(offset)) }
        require (logsListHeaderByte == 0xf8, "Logs list is less than 256 bytes long.");
        offset += 2;

        uint logEntryHeaderByte; assembly { logEntryHeaderByte := byte(0, calldataload(offset)) }
        require (logEntryHeaderByte == 0xf8, "Log entry is less than 256 bytes long.");
        offset += 2;

        uint addressHeaderByte; assembly { addressHeaderByte := byte(0, calldataload(offset)) }
        require (addressHeaderByte == 0x94, "Address is 20 bytes long.");

        uint logAddress; assembly { logAddress := and(calldataload(sub(offset, 11)), 0xffffffffffffffffffffffffffffffffffffffff) }
        require (logAddress == uint(address(this)));
    }

     
    function memcpy(uint dest, uint src, uint len) pure private {
         
        for(; len >= 32; len -= 32) {
            assembly { mstore(dest, mload(src)) }
            dest += 32; src += 32;
        }

         
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}

 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);  
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

library NameFilter {

     
    function nameFilter(string _input)
    internal
    pure
    returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

         
        require (_length <= 32 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

         
        bool _hasNonNumber;

         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint(_temp[i]) + 32);

                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                 
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}