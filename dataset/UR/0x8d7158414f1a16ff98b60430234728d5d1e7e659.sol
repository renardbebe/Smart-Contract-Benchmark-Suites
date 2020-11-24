 

import "./EthexJackpot.sol";
import "./EthexHouse.sol";

contract EthexLoto {
    struct Bet {
        uint256 blockNumber;
        uint256 amount;
        bytes16 id;
        bytes6 bet;
        address payable gamer;
    }
    
    struct Payout {
        uint256 amount;
        bytes32 blockHash;
        bytes16 id;
        address payable gamer;
    }
    
    Bet[] betArray;
    
    address payable public jackpotAddress;
    address payable public houseAddress;
    address payable private owner;

    event Result (
        uint256 amount,
        bytes32 blockHash,
        bytes16 indexed id,
        address indexed gamer
    );
    
    uint8 constant N = 16;
    uint256 constant MIN_BET = 0.01 ether;
    uint256 constant MAX_BET = 100 ether;
    uint256 constant PRECISION = 1 ether;
    uint256 constant JACKPOT_PERCENT = 10;
    uint256 constant HOUSE_EDGE = 10;
    
    constructor(address payable jackpot, address payable house) public payable {
        owner = msg.sender;
        jackpotAddress = jackpot;
        houseAddress = house;
    }
    
    function() external payable { }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function placeBet(bytes22 params) external payable {
        require(msg.value >= MIN_BET, "Bet amount should be greater or equal than minimal amount");
        require(msg.value <= MAX_BET, "Bet amount should be lesser or equal than maximal amount");
        require(bytes16(params) != 0, "Id should not be 0");
        
        bytes16 id = bytes16(params);
        bytes6 bet = bytes6(params << 128);
        
        uint256 jackpotFee = msg.value * JACKPOT_PERCENT * PRECISION / 100 / PRECISION;
        uint256 houseEdgeFee = msg.value * HOUSE_EDGE * PRECISION / 100 / PRECISION;
        betArray.push(Bet(block.number, msg.value - jackpotFee - houseEdgeFee, id, bet, msg.sender));
        
        uint8 markedCount;
        for (uint i = 0; i < bet.length; i++) {
            if (bet[i] > 0x13)
                continue;
            markedCount++;
        }
        if (markedCount > 1)
            EthexJackpot(jackpotAddress).registerTicket(id, msg.sender);
        
        EthexJackpot(jackpotAddress).payIn.value(jackpotFee)();
        EthexHouse(houseAddress).payIn.value(houseEdgeFee)();
    }
    
    function settleBets() external {
        if (betArray.length == 0)
            return;

        Payout[] memory payouts = new Payout[](betArray.length);
        Bet[] memory missedBets = new Bet[](betArray.length);
        uint256 totalPayout;
        uint i = betArray.length;
        do {
            i--;
            if(betArray[i].blockNumber >= block.number || betArray[i].blockNumber < block.number - 256)
                missedBets[i] = betArray[i];
            else {
                bytes32 blockHash = blockhash(betArray[i].blockNumber);
                uint256 coefficient = PRECISION;
                uint8 markedCount;
                uint8 matchesCount;
                uint256 divider = 1;
                for (uint8 j = 0; j < betArray[i].bet.length; j++) {
                    if (betArray[i].bet[j] > 0x13)
                        continue;
                    markedCount++;
                    byte field;
                    if (j % 2 == 0)
                        field = blockHash[29 + j / 2] >> 4;
                    else
                        field = blockHash[29 + j / 2] & 0x0F;
                    if (betArray[i].bet[j] < 0x10) {
                        if (field == betArray[i].bet[j])
                            matchesCount++;
                        else
                            divider *= 15 * N;
                        continue;
                    }
                    if (betArray[i].bet[j] == 0x10) {
                        if (field > 0x09 && field < 0x10) {
                            matchesCount++;
                            divider *= 6;
                        } else
                            divider *= 10 * N;
                        continue;
                    }
                    if (betArray[i].bet[j] == 0x11) {
                        if (field < 0x0A) {
                            matchesCount++;
                            divider *= 10;
                        } else
                            divider *= 6 * N;
                        continue;
                    }
                    if (betArray[i].bet[j] == 0x12) {
                        if (field < 0x0A && field & 0x01 == 0x01) {
                            matchesCount++;
                            divider *= 5;
                        } else
                            divider *= 11 * N;
                        continue;
                    }
                    if (betArray[i].bet[j] == 0x13) {
                        if (field < 0x0A && field & 0x01 == 0x0) {
                            matchesCount++;
                            divider *= 5;
                        } else
                            divider *= 11 * N;
                        continue;
                    }
                }
            
                if (matchesCount == 0) 
                    coefficient = 0;
                else                    
                    coefficient = coefficient * 16**uint256(markedCount) / divider;
                
                uint payoutAmount = betArray[i].amount * coefficient / PRECISION;
                if (payoutAmount == 0 && matchesCount > 0)
                    payoutAmount = matchesCount;
                payouts[i] = Payout(payoutAmount, blockHash, betArray[i].id, betArray[i].gamer);
                totalPayout += payoutAmount;
            }
            betArray.pop();
        } while (i > 0);
        
        i = missedBets.length;
        do {
            i--;
            if (missedBets[i].id != 0)
                betArray.push(missedBets[i]);
        } while (i > 0);
        
        uint balance = address(this).balance;
        for (i = 0; i < payouts.length; i++) {
            if (payouts[i].id > 0) {
                if (totalPayout > balance)
                    emit Result(balance * payouts[i].amount * PRECISION / totalPayout / PRECISION, payouts[i].blockHash, payouts[i].id, payouts[i].gamer);
                else
                    emit Result(payouts[i].amount, payouts[i].blockHash, payouts[i].id, payouts[i].gamer);
            }
        }
        for (i = 0; i < payouts.length; i++) {
            if (payouts[i].amount > 0) {
                if (totalPayout > balance)
                    payouts[i].gamer.transfer(balance * payouts[i].amount * PRECISION / totalPayout / PRECISION);
                else
                    payouts[i].gamer.transfer(payouts[i].amount);
            }
        }
    }
    
    function migrate(address payable newContract) external onlyOwner {
        newContract.transfer(address(this).balance);
    }
}