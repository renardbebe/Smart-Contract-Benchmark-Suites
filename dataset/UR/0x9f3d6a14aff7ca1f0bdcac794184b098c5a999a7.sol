 

pragma solidity ^0.4.23;

contract RouletteRules {
    function getTotalBetAmount(bytes32 first16, bytes32 second16) public pure returns(uint totalBetAmount);
    function getBetResult(bytes32 betTypes, bytes32 first16, bytes32 second16, uint wheelResult) public view returns(uint wonAmount);
}

contract OracleRoulette {

     
     
     

    RouletteRules rouletteRules;
    address developer;
    address operator;
     
     
    bool shouldGateGuard;
     
    uint sinceGateGuarded;

    constructor(address _rouletteRules) public payable {
        rouletteRules = RouletteRules(_rouletteRules);
        developer = msg.sender;
        operator = msg.sender;
        shouldGateGuard = false;
         
        sinceGateGuarded = ~uint(0);
    }

    modifier onlyDeveloper() {
        require(msg.sender == developer);
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator);
        _;
    }

    modifier onlyDeveloperOrOperator() {
        require(msg.sender == developer || msg.sender == operator);
        _;
    }

    modifier shouldGateGuardForEffectiveTime() {
         
         
         
         
         
        require(shouldGateGuard == true && (sinceGateGuarded - now) > 10 minutes);
        _;
    }

    function changeDeveloper(address newDeveloper) external onlyDeveloper {
        developer = newDeveloper;
    }

    function changeOperator(address newOperator) external onlyDeveloper {
        operator = newOperator;
    }

    function setShouldGateGuard(bool flag) external onlyDeveloperOrOperator {
        if (flag) sinceGateGuarded = now;
        shouldGateGuard = flag;
    }

    function setRouletteRules(address _newRouletteRules) external onlyDeveloperOrOperator shouldGateGuardForEffectiveTime {
        rouletteRules = RouletteRules(_newRouletteRules);
    }

     
    function destroyContract() external onlyDeveloper shouldGateGuardForEffectiveTime {
        selfdestruct(developer);
    }

     
    function withdrawFund(uint amount) external onlyDeveloper shouldGateGuardForEffectiveTime {
        require(address(this).balance >= amount);
        msg.sender.transfer(amount);
    }

     
     
    function () external payable {}

     
     
     

    uint BET_UNIT = 0.0002 ether;
    uint BLOCK_TARGET_DELAY = 0;
     
    uint constant MAXIMUM_DISTANCE_FROM_BLOCK_TARGET_DELAY = 250;
    uint MAX_BET = 1 ether;
    uint MAX_GAME_PER_BLOCK = 10;

    function setBetUnit(uint newBetUnitInWei) external onlyDeveloperOrOperator shouldGateGuardForEffectiveTime {
        require(newBetUnitInWei > 0);
        BET_UNIT = newBetUnitInWei;
    }

    function setBlockTargetDelay(uint newTargetDelay) external onlyDeveloperOrOperator {
        require(newTargetDelay >= 0);
        BLOCK_TARGET_DELAY = newTargetDelay;
    }

    function setMaxBet(uint newMaxBet) external onlyDeveloperOrOperator {
        MAX_BET = newMaxBet;
    }

    function setMaxGamePerBlock(uint newMaxGamePerBlock) external onlyDeveloperOrOperator {
        MAX_GAME_PER_BLOCK = newMaxGamePerBlock;
    }

     
     
     

    event GameError(address player, string message);
    event GameStarted(address player, uint gameId, uint targetBlock);
    event GameEnded(address player, uint wheelResult, uint wonAmount);

    function placeBet(bytes32 betTypes, bytes32 first16, bytes32 second16) external payable {
         
        if (shouldGateGuard == true) {
            emit GameError(msg.sender, "Entrance not allowed!");
            revert();
        }

         
        uint betAmount = rouletteRules.getTotalBetAmount(first16, second16) * BET_UNIT;
         
        if (betAmount == 0 || msg.value != betAmount || msg.value > MAX_BET) {
            emit GameError(msg.sender, "Wrong bet amount!");
            revert();
        }

         
         
        uint targetBlock = block.number + BLOCK_TARGET_DELAY;

         
        uint historyLength = gameHistory.length;
        if (historyLength > 0) {
            uint counter;
            for (uint i = historyLength - 1; i >= 0; i--) {
                if (gameHistory[i].targetBlock == targetBlock) {
                    counter++;
                    if (counter > MAX_GAME_PER_BLOCK) {
                        emit GameError(msg.sender, "Reached max game per block!");
                        revert();
                    }
                } else break;
            }
        }

         
         
        Game memory newGame = Game(uint8(GameStatus.PENDING), 100, msg.sender, targetBlock, betTypes, first16, second16);
        uint gameId = gameHistory.push(newGame) - 1;
        emit GameStarted(msg.sender, gameId, targetBlock);
    }

    function resolveBet(uint gameId) external {
         
        Game storage game = gameHistory[gameId];

         
        if (game.status != uint(GameStatus.PENDING)) {
            emit GameError(game.player, "Game is not pending!");
            revert();
        }

         
         
        if (block.number <= game.targetBlock) {
            emit GameError(game.player, "Too early to resolve bet!");
            revert();
        }
         
        if (block.number - game.targetBlock > MAXIMUM_DISTANCE_FROM_BLOCK_TARGET_DELAY) {
             
            game.status = uint8(GameStatus.REJECTED);
            emit GameError(game.player, "Too late to resolve bet!");
            revert();
        }

         
        bytes32 blockHash = blockhash(game.targetBlock);
         
        if (blockHash == 0) {
             
            game.status = uint8(GameStatus.REJECTED);
            emit GameError(game.player, "blockhash() returned zero!");
            revert();
        }

         
         
        game.wheelResult = uint8(keccak256(blockHash, game.player, address(this))) % 37;

         
        uint wonAmount = rouletteRules.getBetResult(game.betTypes, game.first16, game.second16, game.wheelResult) * BET_UNIT;
         
        game.status = uint8(GameStatus.RESOLVED);
         
        if (wonAmount > 0) {
            game.player.transfer(wonAmount);
        }
        emit GameEnded(game.player, game.wheelResult, wonAmount);
    }

     
     
     

    Game[] private gameHistory;

    enum GameStatus {
        INITIAL,
        PENDING,
        RESOLVED,
        REJECTED
    }

    struct Game {
        uint8 status;
        uint8 wheelResult;
        address player;
        uint256 targetBlock;
         
        bytes32 betTypes;
         
        bytes32 first16;
        bytes32 second16;
    }

     
     
     

    function queryGameStatus(uint gameId) external view returns(uint8) {
        Game memory game = gameHistory[gameId];
        return uint8(game.status);
    }

    function queryBetUnit() external view returns(uint) {
        return BET_UNIT;
    }

    function queryGameHistory(uint gameId) external view returns(
        address player, uint256 targetBlock, uint8 status, uint8 wheelResult,
        bytes32 betTypes, bytes32 first16, bytes32 second16
    ) {
        Game memory g = gameHistory[gameId];
        player = g.player;
        targetBlock = g.targetBlock;
        status = g.status;
        wheelResult = g.wheelResult;
        betTypes = g.betTypes;
        first16 = g.first16;
        second16 = g.second16;
    }

    function queryGameHistoryLength() external view returns(uint length) {
        return gameHistory.length;
    }
}