 

pragma solidity ^0.4.19;

pragma solidity ^0.4.19;

 
library SafeMath {
     
    uint constant private DIV_PRECISION = 3;

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function percent(uint numerator, uint denominator, uint precision)
    internal
    pure
    returns (uint quotient) {
         
        uint _numerator = mul(numerator, 10 ** (precision + 1));

         
        uint _quotient = add((_numerator / denominator), 5) / 10;
        return (_quotient);
    }
}

contract HotPotato {
    using SafeMath for uint;

    event GameStarted(uint indexed gameId, address hotPotatoOwner, uint gameStart);
    event GameEnded(uint indexed gameId);
    event HotPotatoPassed(uint indexed gameId, address receiver);
    event PlayerJoined(uint indexed gameId, address player, uint stake, uint totalStake, uint players);
    event PlayerWithdrew(address indexed player);
    event NewMaxTimeHolder(uint indexed gameId, address maxTimeHolder);
    event AddressHeldFor(uint indexed gameId, address player, uint timeHeld);

    struct Game {
         
        bool running;

         
        bool finished;

         
        address hotPotatoOwner;

         
        uint gameStart;

         
        mapping(address => uint) stakes;

         
        uint totalStake;

         
        uint players;

         
        mapping(address => bool) withdrawals;

         
        mapping(address => uint) holdTimes;

         
        uint blockCreated;

         
        uint hotPotatoReceiveTime;

         
        address maxTimeHolder;
    }

     
    uint constant private FEE_TAKE = 0.02 ether;

     
    uint constant private DIV_DEGREE_PRECISION = 3;

     
    uint constant public MIN_STAKE = 0.01 ether;

     
    uint constant public MIN_PLAYERS = 3;

     
    uint constant public GAME_DURATION = 600;

     
    address private contractOwner;

     
    uint public feesTaken;

     
    uint public currentGameId;

     
    mapping(uint => Game) public games;

    modifier gameRunning(uint gameId) {
        require(games[gameId].running);

        _;
    }

    modifier gameStopped(uint gameId) {
        require(!games[gameId].running);

        _;
    }

    modifier gameFinished(uint gameId) {
        require(games[gameId].finished);

        _;
    }

    modifier hasValue(uint amount) {
        require(msg.value >= amount);

        _;
    }

    modifier notInGame(uint gameId, address player) {
        require(games[gameId].stakes[player] == 0);

        _;
    }

    modifier inGame(uint gameId, address player) {
        require(games[gameId].stakes[player] > 0);

        _;
    }

    modifier enoughPlayers(uint gameId) {
        require(games[gameId].players >= MIN_PLAYERS);

        _;
    }

    modifier hasHotPotato(uint gameId, address player) {
        require(games[gameId].hotPotatoOwner == player);

        _;
    }

    modifier notLost(uint gameId, address player) {
        require(games[gameId].hotPotatoOwner != player && games[gameId].maxTimeHolder != player);

        _;
    }

    modifier gameTerminable(uint gameId) {
        require(block.timestamp.sub(games[gameId].gameStart) >= GAME_DURATION);

        _;
    }

    modifier notWithdrew(uint gameId) {
        require(!games[gameId].withdrawals[msg.sender]);

        _;
    }

    modifier onlyContractOwner() {
        require(msg.sender == contractOwner);

        _;
    }

    function HotPotato()
    public
    payable {
        contractOwner = msg.sender;
        games[0].blockCreated = block.number;
    }

    function enterGame()
    public
    payable
    gameStopped(currentGameId)
    hasValue(MIN_STAKE)
    notInGame(currentGameId, msg.sender) {
        Game storage game = games[currentGameId];

        uint feeTake = msg.value.mul(FEE_TAKE) / (1 ether);

        feesTaken = feesTaken.add(feeTake);

        game.stakes[msg.sender] = msg.value.sub(feeTake);
        game.totalStake = game.totalStake.add(msg.value.sub(feeTake));
        game.players = game.players.add(1);

        PlayerJoined(currentGameId, msg.sender, msg.value.sub(feeTake),
            game.totalStake, game.players);
    }

    function startGame(address receiver)
    public
    payable
    gameStopped(currentGameId)
    inGame(currentGameId, msg.sender)
    inGame(currentGameId, receiver)
    enoughPlayers(currentGameId) {
        Game storage game = games[currentGameId];

        game.running = true;
        game.hotPotatoOwner = receiver;
        game.hotPotatoReceiveTime = block.timestamp;
        game.gameStart = block.timestamp;
        game.maxTimeHolder = receiver;

        GameStarted(currentGameId, game.hotPotatoOwner, game.gameStart);
    }

    function passHotPotato(address receiver)
    public
    payable
    gameRunning(currentGameId)
    hasHotPotato(currentGameId, msg.sender)
    inGame(currentGameId, receiver) {
        Game storage game = games[currentGameId];

        game.hotPotatoOwner = receiver;

        uint timeHeld = block.timestamp.sub(game.hotPotatoReceiveTime);
        game.holdTimes[msg.sender] = game.holdTimes[msg.sender].add(timeHeld);
        AddressHeldFor(currentGameId, msg.sender, game.holdTimes[msg.sender]);

        if (game.holdTimes[msg.sender] > game.holdTimes[game.maxTimeHolder]) {
            game.maxTimeHolder = msg.sender;
            NewMaxTimeHolder(currentGameId, game.maxTimeHolder);
        }

        game.hotPotatoReceiveTime = block.timestamp;

        HotPotatoPassed(currentGameId, receiver);
    }

    function endGame()
    public
    payable
    gameRunning(currentGameId)
    inGame(currentGameId, msg.sender)
    gameTerminable(currentGameId) {
        Game storage game = games[currentGameId];

        game.running = false;
        game.finished = true;

        uint timeHeld = block.timestamp.sub(game.hotPotatoReceiveTime);
        game.holdTimes[game.hotPotatoOwner] = game.holdTimes[game.hotPotatoOwner].add(timeHeld);
        AddressHeldFor(currentGameId, game.hotPotatoOwner, game.holdTimes[msg.sender]);

        if (game.holdTimes[game.hotPotatoOwner] > game.holdTimes[game.maxTimeHolder]) {
            game.maxTimeHolder = game.hotPotatoOwner;
            NewMaxTimeHolder(currentGameId, game.maxTimeHolder);
        }

        GameEnded(currentGameId);

        currentGameId = currentGameId.add(1);
        games[currentGameId].blockCreated = block.number;
    }

    function withdraw(uint gameId)
    public
    payable
    gameFinished(gameId)
    inGame(gameId, msg.sender)
    notLost(gameId, msg.sender)
    notWithdrew(gameId) {
        Game storage game = games[gameId];

        uint banishedStake = 0;

        if (game.hotPotatoOwner == game.maxTimeHolder) {
            banishedStake = game.stakes[game.hotPotatoOwner];
        } else {
            banishedStake = game.stakes[game.hotPotatoOwner].add(game.stakes[game.maxTimeHolder]);
        }

        uint collectiveStake = game.totalStake.sub(banishedStake);

        uint stake = game.stakes[msg.sender];

        uint percentageClaim = SafeMath.percent(stake, collectiveStake, DIV_DEGREE_PRECISION);

        uint claim = stake.add(banishedStake.mul(percentageClaim) / (10 ** DIV_DEGREE_PRECISION));

        game.withdrawals[msg.sender] = true;

        msg.sender.transfer(claim);

        PlayerWithdrew(msg.sender);
    }

    function withdrawFees()
    public
    payable
    onlyContractOwner {
        uint feesToTake = feesTaken;
        feesTaken = 0;
        contractOwner.transfer(feesToTake);
    }

     
    function getGame(uint gameId)
    public
    constant
    returns (bool, bool, address, uint, uint, uint, uint, address, uint) {
        Game storage game = games[gameId];
        return (
        game.running,
        game.finished,
        game.hotPotatoOwner,
        game.gameStart,
        game.totalStake,
        game.players,
        game.blockCreated,
        game.maxTimeHolder,
        currentGameId);
    }
}