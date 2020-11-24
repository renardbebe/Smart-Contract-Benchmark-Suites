 

pragma solidity 0.5.10;

interface IERC20 {
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

contract LotteryTicket {
    address owner;
    string public constant name = "LotteryTicket";
    string public constant symbol = "✓";
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor() public {
        owner = msg.sender;
    }
    function emitEvent(address addr) public {
        require(msg.sender == owner);
        emit Transfer(msg.sender, addr, 1);
    }
}

contract WinnerTicket {
    address owner;
    string public constant name = "WinnerTicket";
    string public constant symbol = "✓";
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor() public {
        owner = msg.sender;
    }
    function emitEvent(address addr) public {
        require(msg.sender == owner);
        emit Transfer(msg.sender, addr, 1);
    }
}

contract Ownable {
    address public owner;
    event OwnershipRenounced(address indexed previousOwner);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function renounceOwnership() public onlyOwner {
        emit OwnershipRenounced(owner);
        owner = address(0);
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract Storage {
    address owner;

    mapping (address => uint256) public amount;
    mapping (uint256 => address[]) public level;
    uint256 public count;
    uint256 public maximum;

    constructor() public {
        owner = msg.sender;
    }

    function purchase(address addr) public {
        require(msg.sender == owner);

        amount[addr]++;
        if (amount[addr] > 1) {
            level[amount[addr]].push(addr);
            if (amount[addr] > 2) {
                for (uint256 i = 0; i < level[amount[addr] - 1].length; i++) {
                    if (level[amount[addr] - 1][i] == addr) {
                        delete level[amount[addr] - 1][i];
                        break;
                    }
                }
            } else if (amount[addr] == 2) {
                count++;
            }
            if (amount[addr] > maximum) {
                maximum = amount[addr];
            }
        }

    }

    function draw(uint256 goldenWinners) public view returns(address[] memory addresses) {

        addresses = new address[](goldenWinners);
        uint256 winnersCount;

        for (uint256 i = maximum; i >= 2; i--) {
            for (uint256 j = 0; j < level[i].length; j++) {
                if (level[i][j] != address(0)) {
                    addresses[winnersCount] = level[i][j];
                    winnersCount++;
                    if (winnersCount == goldenWinners) {
                        return addresses;
                    }
                }
            }
        }

    }

}

contract RefStorage is Ownable {

    IERC20 public token;

    mapping (address => bool) public contracts;

    uint256 public prize = 0.00005 ether;
    uint256 public interval = 100;

    mapping (address => Player) public players;
    struct Player {
        uint256 tickets;
        uint256 checkpoint;
        address referrer;
    }

    event ReferrerAdded(address player, address referrer);
    event BonusSent(address recipient, uint256 amount);

    modifier restricted() {
        require(contracts[msg.sender]);
        _;
    }

    constructor() public {
        token = IERC20(address(0x9f9EFDd09e915C1950C5CA7252fa5c4F65AB049B));
    }

    function changeContracts(address contractAddr) public onlyOwner {
        contracts[contractAddr] = true;
    }

    function changePrize(uint256 newPrize) public onlyOwner {
        prize = newPrize;
    }

    function changeInterval(uint256 newInterval) public onlyOwner {
        interval = newInterval;
    }

    function newTicket() external restricted {
        players[tx.origin].tickets++;
        if (players[tx.origin].referrer != address(0) && (players[tx.origin].tickets - players[tx.origin].checkpoint) % interval == 0) {
            if (token.balanceOf(address(this)) >= prize * 2) {
                token.transfer(tx.origin, prize);
                emit BonusSent(tx.origin, prize);
                token.transfer(players[tx.origin].referrer, prize);
                emit BonusSent(players[tx.origin].referrer, prize);
            }
        }
    }

    function addReferrer(address referrer) external restricted {
        if (players[tx.origin].referrer == address(0) && players[referrer].tickets >= interval && referrer != tx.origin) {
            players[tx.origin].referrer = referrer;
            players[tx.origin].checkpoint = players[tx.origin].tickets;

            emit ReferrerAdded(tx.origin, referrer);
        }
    }

    function sendBonus(address winner) external restricted {
        if (token.balanceOf(address(this)) >= prize) {
            token.transfer(winner, prize);

            emit BonusSent(winner, prize);
        }
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {
        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);
    }

    function ticketsOf(address player) public view returns(uint256) {
        return players[player].tickets;
    }

    function referrerOf(address player) public view returns(address) {
        return players[player].referrer;
    }
}

interface Drawer {
    function delegatecall(uint256 blocks) external returns(bool);
}

contract Lottery10ETH is Ownable {

    Storage public x;
    RefStorage public RS;
    LotteryTicket public LT;
    WinnerTicket public WT;

    uint256 constant public PRICE = 0.01 ether;

    address[] public players;

    uint256 public limit = 1000;

    uint256 public futureblock;

    uint256 public gameCount;

    bool public paused;

    address public drawer;

    bool public onDrawing;

    uint256[] silver    = [20,  0.1 ether];
    uint256[] gold      = [5,   0.2 ether];
    uint256[] brilliant = [1,   5   ether];

    event NewPlayer(address indexed addr, uint256 indexed gameCount);
    event SilverWinner(address indexed addr, uint256 prize, uint256 indexed gameCount);
    event GoldenWinner(address indexed addr, uint256 prize, uint256 indexed gameCount);
    event BrilliantWinner(address indexed addr, uint256 prize, uint256 indexed gameCount);
    event txCostRefunded(address indexed addr, uint256 amount);
    event FeePayed(address indexed owner, uint256 amount);
    event OnDrawing(uint256 time);

    modifier notOnPause() {
        require(!paused);
        _;
    }

    modifier notFromContract() {
        require(!isContract(msg.sender));
        _;
    }

    function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    constructor(address RS_Addr) public {
        x = new Storage();
        LT = new LotteryTicket();
        WT = new WinnerTicket();
        RS = RefStorage(RS_Addr);
        gameCount++;
    }

    function() external payable {

        if (onDrawing) {

            if (block.number < futureblock + 230) {
                drawing();
            } else {
                setFutureBlock();
                if (msg.value != 0) {
                    msg.sender.send(msg.value);
                }
                return;
            }

        }

        if (msg.data.length != 0) {
            RS.addReferrer(bytesToAddress(bytes(msg.data)));
        }

        if (msg.value >= PRICE && !paused && !onDrawing) {
            buyTicket();
        } else if (msg.value != 0) {
            msg.sender.send(msg.value);
        }

        if (players.length >= limit) {
            setFutureBlock();
        }

    }

    function buyTicket() internal notOnPause notFromContract {

        if (msg.value > PRICE) {
            msg.sender.send(msg.value - PRICE);
        }

        players.push(msg.sender);
        x.purchase(msg.sender);
        RS.newTicket();
        LT.emitEvent(msg.sender);
        emit NewPlayer(msg.sender, gameCount);

    }

    function setFutureBlock() internal {

        if (block.number >= futureblock + 230) {
            futureblock = block.number + 20;
        }

        if (!onDrawing) {
            onDrawing = true;
        }

        if (drawer != address(0)) {
            Drawer(drawer).delegatecall(21);
        }

        emit OnDrawing(block.timestamp);

    }

    function drawing() internal {

        require(block.number > futureblock, "Awaiting for a future block");

        if (drawer != address(0)) {
            require(msg.sender == drawer);
        } else {
            require(!isContract(msg.sender));
        }

        for (uint256 i = 0; i < silver[0]; i++) {
            address winner = players[uint((blockhash(futureblock - 1 - i))) % players.length];
            address(uint160(winner)).send(silver[1]);
            WT.emitEvent(winner);
            emit SilverWinner(winner, silver[1], gameCount);
        }

        uint256 goldenWinners = gold[0];
        uint256 goldenPrize = gold[1];
        if (x.count() < gold[0]) {
            goldenWinners = x.count();
            goldenPrize = gold[0] * gold[1] / x.count();
        }
        if (goldenWinners != 0) {
            address[] memory addresses = x.draw(goldenWinners);
            for (uint256 k = 0; k < addresses.length; k++) {
                address(uint160(addresses[k])).send(goldenPrize);
                RS.sendBonus(addresses[k]);
                WT.emitEvent(addresses[k]);
                emit GoldenWinner(addresses[k], goldenPrize, gameCount);
            }
        }

        uint256 laps = 10;
        uint256 winnerIdx;
        uint256 indexes = players.length * 1e18;
        for (uint256 j = 0; j < laps; j++) {
            uint256 change = (indexes) / (2 ** (j+1));
            if (uint256(keccak256(abi.encodePacked(blockhash(futureblock - j)))) % 2 == 0) {
                winnerIdx += change;
            }
        }
        winnerIdx = winnerIdx / 1e18;
        address(uint160(players[winnerIdx])).send(brilliant[1]);
        WT.emitEvent(players[winnerIdx]);
        emit BrilliantWinner(players[winnerIdx], brilliant[1], gameCount);

        delete players;
        futureblock = 0;
        x = new Storage();
        gameCount++;
        onDrawing = false;

        uint256 txCost = tx.gasprice * (750000);
        msg.sender.send(txCost);
        emit txCostRefunded(msg.sender, txCost);

        uint256 fee = address(this).balance - msg.value;
        address(uint160(owner)).send(fee);
        emit FeePayed(owner, fee);

    }

    function withdraw() public onlyOwner {

        address(uint160(owner)).send(address(this).balance);

        delete players;
        futureblock = 0;
        x = new Storage();
        gameCount++;
        onDrawing = false;
    }

    function pause() public onlyOwner {
        paused = true;
    }

    function unpause() public onlyOwner {
        paused = false;
    }

    function setDrawer(address account) public onlyOwner {
        drawer = account;
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {
        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);
    }

    function bytesToAddress(bytes memory source) internal pure returns(address parsedReferrer) {
        assembly {
            parsedReferrer := mload(add(source,0x14))
        }
        return parsedReferrer;
    }

    function amountOfPlayers() public view returns(uint) {
        return players.length;
    }

    function referrerOf(address player) external view returns(address) {
        return RS.referrerOf(player);
    }

    function ticketsOf(address player) external view returns(uint256) {
        return RS.ticketsOf(player);
    }

    function currTicketsOf(address player) external view returns(uint256) {
        uint256 index;
        for (uint256 i = 0; i < players.length; i++) {
            if (players[i] == player) {
                index++;
            }
        }
        return index;
    }

    function currGoldenLeaders() external view returns(address[] memory) {
        uint256 goldenWinners = gold[0];
        if (x.count() < gold[0]) {
            goldenWinners = x.count();
        }
        return x.draw(goldenWinners);
    }

}