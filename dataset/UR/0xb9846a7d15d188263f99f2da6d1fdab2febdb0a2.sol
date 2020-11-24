 

import "./EthexJackpot.sol";
import "./EthexHouse.sol";
import "./EthexSuperprize.sol";
import "./DeliverFunds.sol";

contract EthexLoto {
    struct Bet {
        uint256 blockNumber;
        uint256 amount;
        bytes16 id;
        bytes6 bet;
        address payable gamer;
    }
    
    struct Transaction {
        uint256 amount;
        address payable gamer;
    }
    
    struct Superprize {
        uint256 amount;
        bytes16 id;
    }
    
    mapping(uint256 => uint256) public blockNumberQueue;
    mapping(uint256 => uint256) public amountQueue;
    mapping(uint256 => bytes16) public idQueue;
    mapping(uint256 => bytes6) public betQueue;
    mapping(uint256 => address payable) public gamerQueue;
    uint256 public first = 2;
    uint256 public last = 1;
    uint256 public holdBalance;
    
    address payable public jackpotAddress;
    address payable public houseAddress;
    address payable public superprizeAddress;
    address payable private owner;

    event PayoutBet (
        uint256 amount,
        bytes16 id,
        address gamer
    );
    
    event RefundBet (
        uint256 amount,
        bytes16 id,
        address gamer
    );
    
    uint256 constant MIN_BET = 0.01 ether;
    uint256 constant PRECISION = 1 ether;
    uint256 constant JACKPOT_PERCENT = 10;
    uint256 constant HOUSE_EDGE = 10;
    
    constructor(address payable jackpot, address payable house, address payable superprize) public payable {
        owner = msg.sender;
        jackpotAddress = jackpot;
        houseAddress = house;
        superprizeAddress = superprize;
    }
    
    function() external payable { }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function placeBet(bytes22 params) external payable {
        require(tx.origin == msg.sender);
        require(msg.value >= MIN_BET, "Bet amount should be greater or equal than minimal amount");
        require(bytes16(params) != 0, "Id should not be 0");
        
        bytes16 id = bytes16(params);
        bytes6 bet = bytes6(params << 128);
        
        uint256 coefficient;
        uint8 markedCount;
        uint256 holdAmount;
        uint256 jackpotFee = msg.value * JACKPOT_PERCENT * PRECISION / 100 / PRECISION;
        uint256 houseEdgeFee = msg.value * HOUSE_EDGE * PRECISION / 100 / PRECISION;
        uint256 betAmount = msg.value - jackpotFee - houseEdgeFee;
        
        (coefficient, markedCount, holdAmount) = getHold(betAmount, bet);
        
        require(msg.value * (100 - JACKPOT_PERCENT - HOUSE_EDGE) * (coefficient * 8 - 15 * markedCount) <= 9000 ether * markedCount);
        
        require(
            msg.value * (800 * coefficient - (JACKPOT_PERCENT + HOUSE_EDGE) * (coefficient * 8 + 15 * markedCount)) <= 1500 * markedCount * (address(this).balance - holdBalance));
        
        holdBalance += holdAmount;
        
        enqueue(block.number, betAmount, id, bet, msg.sender);
        
        if (markedCount > 1)
            EthexJackpot(jackpotAddress).registerTicket(id, msg.sender);
        
        EthexHouse(houseAddress).payIn.value(houseEdgeFee)();
        EthexJackpot(jackpotAddress).payIn.value(jackpotFee)();
    }
    
    function settleBets() external {
        if (first > last)
            return;
        uint256 i = 0;
        uint256 length = last - first + 1;
        length = length > 10 ? 10 : length;
        Transaction[] memory transactions = new Transaction[](length);
        Superprize[] memory superprizes = new Superprize[](length);
        uint256 balance = address(this).balance - holdBalance;
        
        for(; i < length; i++) {
            if (blockNumberQueue[first] >= block.number) {
                length = i;
                break;
            }
            else {
                Bet memory bet = dequeue();
                uint256 coefficient = 0;
                uint8 markedCount = 0;
                uint256 holdAmount = 0;
                (coefficient, markedCount, holdAmount) = getHold(bet.amount, bet.bet);
                holdBalance -= holdAmount;
                balance += holdAmount;
                if (bet.blockNumber < block.number - 256) {
                    transactions[i] = Transaction(bet.amount, bet.gamer);
                    emit RefundBet(bet.amount, bet.id, bet.gamer);
                    balance -= bet.amount;
                }
                else {
                    bytes32 blockHash = blockhash(bet.blockNumber);
                    coefficient = 0;
                    uint8 matchesCount;
                    bool isSuperPrize = true;
                    for (uint8 j = 0; j < bet.bet.length; j++) {
                        if (bet.bet[j] > 0x13) {
                            isSuperPrize = false;
                            continue;
                        }
                        byte field;
                        if (j % 2 == 0)
                            field = blockHash[29 + j / 2] >> 4;
                        else
                            field = blockHash[29 + j / 2] & 0x0F;
                        if (bet.bet[j] < 0x10) {
                            if (field == bet.bet[j]) {
                                matchesCount++;
                                coefficient += 30;
                            }
                            else
                                isSuperPrize = false;
                            continue;
                        }
                        else
                            isSuperPrize = false;
                        if (bet.bet[j] == 0x10) {
                            if (field > 0x09 && field < 0x10) {
                                matchesCount++;
                                coefficient += 5;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x11) {
                            if (field < 0x0A) {
                                matchesCount++;
                                coefficient += 3;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x12) {
                            if (field < 0x0A && field & 0x01 == 0x01) {
                                matchesCount++;
                                coefficient += 6;
                            }
                            continue;
                        }
                        if (bet.bet[j] == 0x13) {
                            if (field < 0x0A && field & 0x01 == 0x0) {
                                matchesCount++;
                                coefficient += 6;
                            }
                            continue;
                        }
                    }
                
                    coefficient *= PRECISION * 8;
                        
                    uint256 payoutAmount = bet.amount * coefficient / (PRECISION * 15 * markedCount);
                    transactions[i] = Transaction(payoutAmount, bet.gamer);
                    emit PayoutBet(payoutAmount, bet.id, bet.gamer);
                    balance -= payoutAmount;
                    
                    if (isSuperPrize == true) {
                        superprizes[i].amount = balance;
                        superprizes[i].id = bet.id;
                        balance = 0;
                    }
                }
            }
        }
        
        for (i = 0; i < length; i++) {
            if (transactions[i].amount > 0 && !transactions[i].gamer.send(transactions[i].amount))
                (new DeliverFunds).value(transactions[i].amount)(transactions[i].gamer);
            if (superprizes[i].id != 0) {
                EthexSuperprize(superprizeAddress).initSuperprize(transactions[i].gamer, superprizes[i].id);
                EthexJackpot(jackpotAddress).paySuperPrize(transactions[i].gamer);
                if (superprizes[i].amount > 0 && !transactions[i].gamer.send(superprizes[i].amount))
                    (new DeliverFunds).value(superprizes[i].amount)(transactions[i].gamer);
            }
        }
    }
    
    function migrate(address payable newContract) external onlyOwner {
        newContract.transfer(address(this).balance);
    }

    function setJackpot(address payable jackpot) external onlyOwner {
        jackpotAddress = jackpot;
    }
    
    function setSuperprize(address payable superprize) external onlyOwner {
        superprizeAddress = superprize;
    }
    
    function length() public view returns (uint256) {
        return 1 + last - first;
    }
    
    function enqueue(uint256 blockNumber, uint256 amount, bytes16 id, bytes6 bet, address payable gamer) internal {
        last += 1;
        blockNumberQueue[last] = blockNumber;
        amountQueue[last] = amount;
        idQueue[last] = id;
        betQueue[last] = bet;
        gamerQueue[last] = gamer;
    }

    function dequeue() internal returns (Bet memory bet) {
        require(last >= first);

        bet = Bet(blockNumberQueue[first], amountQueue[first], idQueue[first], betQueue[first], gamerQueue[first]);

        delete blockNumberQueue[first];
        delete amountQueue[first];
        delete idQueue[first];
        delete betQueue[first];
        delete gamerQueue[first];
        
        if (first == last) {
            first = 2;
            last = 1;
        }
        else
            first += 1;
    }
    
    function getHold(uint256 amount, bytes6 bet) internal pure returns (uint256 coefficient, uint8 markedCount, uint256 holdAmount) {
        for (uint8 i = 0; i < bet.length; i++) {
            if (bet[i] > 0x13)
                continue;
            markedCount++;
            if (bet[i] < 0x10) {
                coefficient += 30;
                continue;
            }
            if (bet[i] == 0x10) {
                coefficient += 5;
                continue;
            }
            if (bet[i] == 0x11) {
                coefficient += 3;
                continue;
            }
            if (bet[i] == 0x12) {
                coefficient += 6;
                continue;
            }
            if (bet[i] == 0x13) {
                coefficient += 6;
                continue;
            }
        }
        holdAmount = amount * coefficient * 2 / 375 / markedCount;
    }
}
