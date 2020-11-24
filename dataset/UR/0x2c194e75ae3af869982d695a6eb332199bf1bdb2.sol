 

pragma solidity 0.5.8;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner, "Called by unknown account");
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract GameGuess is Ownable {
    event Status(address indexed user, uint number, uint wins, uint loses, int profit);

    struct GameStats {
        uint wins;
        uint loses;
        int profit;
    }

    mapping(address => GameStats) public userGameStats;

    function play(uint8 chance, bool sign) external payable notContract {
        if (msg.sender == owner) return;
        uint16 number = chance;
        if (sign) number = 100 - chance;
        uint multiplier = getMultiplier(chance);
        require(msg.value > 0 && address(this).balance > (multiplier * msg.value) / 10000, "Incorrect bet");
        require(number >= 1 && number < 100, "Invalid number");
        uint16 randomNumber = random();
        bool result = false;
        if (sign) result = randomNumber > (number * 10);
        else result = randomNumber < (number * 10);
        if (result) {
            uint prize = (msg.value * multiplier) / 10000;
            userGameStats[msg.sender].wins++;
            userGameStats[msg.sender].profit += int(prize);
            msg.sender.transfer(prize);
        } else {
            userGameStats[msg.sender].loses++;
            userGameStats[msg.sender].profit -= int(msg.value);
        }
        emit Status(msg.sender,
            randomNumber,
            userGameStats[msg.sender].wins,
            userGameStats[msg.sender].loses,
            userGameStats[msg.sender].profit
        );
    }

     
    function withdraw(uint amount) external onlyOwner {
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }

    function getMultiplier(uint number) public pure returns (uint) {
        uint multiplier = (99 * 100000) / number;
        if (multiplier % 10 >= 5) multiplier += 10;
        multiplier = multiplier / 10;

        return multiplier;
    }

    function random() private view returns (uint16) {
        uint totalGames = userGameStats[msg.sender].wins + userGameStats[msg.sender].loses;
        return uint16(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, totalGames))) % 1000) + 1;
    }

    modifier notContract {
        uint size;
        address addr = msg.sender;
        assembly {size := extcodesize(addr)}
        require(size <= 0 && tx.origin == addr, "Called by contract");
        _;
    }
}