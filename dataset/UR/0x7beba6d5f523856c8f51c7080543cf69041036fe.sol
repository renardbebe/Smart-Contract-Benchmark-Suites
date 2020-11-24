 

import "./DeliverFunds.sol";
import "./Ownable.sol";

contract EthexJackpot is Ownable {
    mapping(uint256 => address payable) public tickets;
    mapping(uint256 => Segment[4]) public prevJackpots;
    uint256[4] public amounts;
    uint256[4] public starts;
    uint256[4] public ends;
    uint256[4] public numberStarts;
    uint256 public numberEnd;
    uint256 public firstNumber;
    uint256 public dailyAmount;
    uint256 public weeklyAmount;
    uint256 public monthlyAmount;
    uint256 public seasonalAmount;
    bool public dailyProcessed;
    bool public weeklyProcessed;
    bool public monthlyProcessed;
    bool public seasonalProcessed;
    address public lotoAddress;
    address payable public newVersionAddress;
    EthexJackpot public previousContract;
    uint256 public dailyNumberStartPrev;
    uint256 public weeklyNumberStartPrev;
    uint256 public monthlyNumberStartPrev;
    uint256 public seasonalNumberStartPrev;
    uint256 public dailyStart;
    uint256 public weeklyStart;
    uint256 public monthlyStart;
    uint256 public seasonalStart;
    uint256 public dailyEnd;
    uint256 public weeklyEnd;
    uint256 public monthlyEnd;
    uint256 public seasonalEnd;
    uint256 public dailyNumberStart;
    uint256 public weeklyNumberStart;
    uint256 public monthlyNumberStart;
    uint256 public seasonalNumberStart;
    uint256 public dailyNumberEndPrev;
    uint256 public weeklyNumberEndPrev;
    uint256 public monthlyNumberEndPrev;
    uint256 public seasonalNumberEndPrev;
    
    struct Segment {
        uint256 start;
        uint256 end;
        bool processed;
    }
    
    event Jackpot (
        uint256 number,
        uint256 count,
        uint256 amount,
        byte jackpotType
    );
    
    event Ticket (
        uint256 number
    );
    
    event Superprize (
        uint256 amount,
        address winner
    );
    
    uint256[4] internal LENGTH = [5000, 35000, 150000, 450000];
    uint256[4] internal PARTS = [84, 12, 3, 1];
    uint256 internal constant PRECISION = 1 ether;
    
    modifier onlyLoto {
        require(msg.sender == lotoAddress, "Loto only");
        _;
    }
    
    function() external payable { }
    
    function migrate() external {
        require(msg.sender == owner || msg.sender == newVersionAddress);
        newVersionAddress.transfer(address(this).balance);
    }

    function registerTicket(address payable gamer) external onlyLoto {
        uint256 number = numberEnd + 1;
        for (uint8 i = 0; i < 4; i++) {
            if (block.number >= ends[i]) {
                setJackpot(i);
                numberStarts[i] = number;
            }
            else
                if (numberStarts[i] == prevJackpots[starts[i]][i].start)
                    numberStarts[i] = number;
        }
        numberEnd = number;
        tickets[number] = gamer;
        emit Ticket(number);
    }
    
    function setLoto(address loto) external onlyOwner {
        lotoAddress = loto;
    }
    
    function setNewVersion(address payable newVersion) external onlyOwner {
        newVersionAddress = newVersion;
    }
    
    function payIn() external payable {
        uint256 distributedAmount = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        if (distributedAmount < address(this).balance) {
            uint256 amount = (address(this).balance - distributedAmount) / 4;
            amounts[0] += amount;
            amounts[1] += amount;
            amounts[2] += amount;
            amounts[3] += amount;
        }
    }

    function processJackpots(bytes32 hash, uint256[4] memory blockHeights) private {
        uint48 modulo = uint48(bytes6(hash << 29));
        
        uint256[4] memory payAmounts;
        uint256[4] memory wins;
        for (uint8 i = 0; i < 4; i++) {
            if (prevJackpots[blockHeights[i]][i].processed == false && prevJackpots[blockHeights[i]][i].start != 0) {
                payAmounts[i] = amounts[i] * PRECISION / PARTS[i] / PRECISION;
                amounts[i] -= payAmounts[i];
                prevJackpots[blockHeights[i]][i].processed = true;
                wins[i] = getNumber(prevJackpots[blockHeights[i]][i].start, prevJackpots[blockHeights[i]][i].end, modulo);
                emit Jackpot(wins[i], prevJackpots[blockHeights[i]][i].end - prevJackpots[blockHeights[i]][i].start + 1, payAmounts[i], byte(uint8(1) << i));
            }
        }
        
        for (uint8 i = 0; i < 4; i++)
            if (payAmounts[i] > 0 && !getAddress(wins[i]).send(payAmounts[i]))
                (new DeliverFunds).value(payAmounts[i])(getAddress(wins[i]));
    }
    
    function settleJackpot() external {
        for (uint8 i = 0; i < 4; i++)
            if (block.number >= ends[i])
                setJackpot(i);
        
        if (block.number == starts[0] || (starts[0] < block.number - 256))
            return;
        
        processJackpots(blockhash(starts[0]), starts);
    }

    function settleMissedJackpot(bytes32 hash, uint256 blockHeight) external onlyOwner {
        for (uint8 i = 0; i < 4; i++)
            if (block.number >= ends[i])
                setJackpot(i);
        
        if (blockHeight < block.number - 256)
            processJackpots(hash, [blockHeight, blockHeight, blockHeight, blockHeight]);
    }
    
    function paySuperprize(address payable winner) external onlyLoto {
        uint256 superprizeAmount = amounts[0] + amounts[1] + amounts[2] + amounts[3];
        amounts[0] = 0;
        amounts[1] = 0;
        amounts[2] = 0;
        amounts[3] = 0;
        emit Superprize(superprizeAmount, winner);
        if (superprizeAmount > 0 && !winner.send(superprizeAmount))
            (new DeliverFunds).value(superprizeAmount)(winner);
    }
    
    function setOldVersion(address payable oldAddress) external onlyOwner {
        previousContract = EthexJackpot(oldAddress);
        starts[0] = previousContract.dailyStart();
        ends[0] = previousContract.dailyEnd();
        prevJackpots[starts[0]][0].processed = previousContract.dailyProcessed();
        starts[1] = previousContract.weeklyStart();
        ends[1] = previousContract.weeklyEnd();
        prevJackpots[starts[1]][1].processed = previousContract.weeklyProcessed();
        starts[2] = previousContract.monthlyStart();
        ends[2] = previousContract.monthlyEnd();
        prevJackpots[starts[2]][2].processed = previousContract.monthlyProcessed();
        starts[3] = previousContract.seasonalStart();
        ends[3] = previousContract.seasonalEnd();
        prevJackpots[starts[3]][3].processed = previousContract.seasonalProcessed();
        prevJackpots[starts[0]][0].start = previousContract.dailyNumberStartPrev();
        prevJackpots[starts[1]][1].start = previousContract.weeklyNumberStartPrev();
        prevJackpots[starts[2]][2].start = previousContract.monthlyNumberStartPrev();
        prevJackpots[starts[3]][3].start = previousContract.seasonalNumberStartPrev();
        numberStarts[0] = previousContract.dailyNumberStart();
        numberStarts[1] = previousContract.weeklyNumberStart();
        numberStarts[2] = previousContract.monthlyNumberStart();
        numberStarts[3] = previousContract.seasonalNumberStart();
        prevJackpots[starts[0]][0].end = previousContract.dailyNumberEndPrev();
        prevJackpots[starts[1]][1].end = previousContract.weeklyNumberEndPrev();
        prevJackpots[starts[2]][2].end = previousContract.monthlyNumberEndPrev();
        prevJackpots[starts[3]][3].end = previousContract.seasonalNumberEndPrev();
        numberEnd = previousContract.numberEnd();        
        amounts[0] = previousContract.dailyAmount();
        amounts[1] = previousContract.weeklyAmount();
        amounts[2] = previousContract.monthlyAmount();
        amounts[3] = previousContract.seasonalAmount();
        firstNumber = numberEnd;
        previousContract.migrate();
    }
    
    function getAddress(uint256 number) public returns (address payable) {
        if (number <= firstNumber)
            return previousContract.getAddress(number);
        return tickets[number];
    }
    
    function setJackpot(uint8 jackpotType) private {
        prevJackpots[ends[jackpotType]][jackpotType].processed = prevJackpots[starts[jackpotType]][jackpotType].end == numberEnd;
        starts[jackpotType] = ends[jackpotType];
        ends[jackpotType] = starts[jackpotType] + LENGTH[jackpotType];
        prevJackpots[starts[jackpotType]][jackpotType].start = numberStarts[jackpotType];
        prevJackpots[starts[jackpotType]][jackpotType].end = numberEnd;
    }
    
    function getNumber(uint256 startNumber, uint256 endNumber, uint48 modulo) private pure returns (uint256) {
        return startNumber + modulo % (endNumber - startNumber + 1);
    }
}