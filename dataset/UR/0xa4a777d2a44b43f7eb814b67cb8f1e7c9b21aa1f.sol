 

pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

 
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
pragma solidity ^0.4.24;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns(address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

     
    function isOwner() public view returns(bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
pragma solidity ^0.4.24;

interface EtherHiLoRandomNumberRequester {

    function incomingRandomNumber(address player, uint8 randomNumber) external;

    function incomingRandomNumberError(address player) external;

}

interface EtherHiLoRandomNumberGenerator {

    function generateRandomNumber(address player, uint8 max) payable external returns (bool);

}

 
 
contract EtherHiLo is Ownable, EtherHiLoRandomNumberRequester {

    uint8 constant NUM_DICE_SIDES = 13;

    uint public minBet;
    uint public maxBetThresholdPct;
    bool public gameRunning;
    uint public balanceInPlay;

    EtherHiLoRandomNumberGenerator private random;
    mapping(address => Game) private gamesInProgress;

    event GameFinished(address indexed player, uint indexed playerGameNumber, uint bet, uint8 firstRoll, uint8 finalRoll, uint winnings, uint payout);
    event GameError(address indexed player, uint indexed playerGameNumber);

    enum BetDirection {
        None,
        Low,
        High
    }

    enum GameState {
        None,
        WaitingForFirstCard,
        WaitingForDirection,
        WaitingForFinalCard,
        Finished
    }

     
    struct Game {
        address player;
        GameState state;
        uint id;
        BetDirection direction;
        uint bet;
        uint8 firstRoll;
        uint8 finalRoll;
        uint winnings;
    }

     
    constructor() public {
        setMinBet(100 finney);
        setGameRunning(true);
        setMaxBetThresholdPct(75);
    }

     
    function() external payable {

    }


     
     

     
    function beginGame() public payable {
        address player = msg.sender;
        uint bet = msg.value;

        require(player != address(0));
        require(gamesInProgress[player].state == GameState.None || gamesInProgress[player].state == GameState.Finished);
        require(gameRunning);
        require(bet >= minBet && bet <= getMaxBet());

        Game memory game = Game({
                id:         uint(keccak256(block.number, player, bet)),
                player:     player,
                state:      GameState.WaitingForFirstCard,
                bet:        bet,
                firstRoll:  0,
                finalRoll:  0,
                winnings:   0,
                direction:  BetDirection.None
            });

        if (!random.generateRandomNumber(player, NUM_DICE_SIDES)) {
            player.transfer(msg.value);
            return;
        }

        balanceInPlay = balanceInPlay + game.bet;
        gamesInProgress[player] = game;
    }

     
    function finishGame(BetDirection direction) public {
        address player = msg.sender;

        require(player != address(0));
        require(gamesInProgress[player].state != GameState.None && gamesInProgress[player].state != GameState.Finished);

        if (!random.generateRandomNumber(player, NUM_DICE_SIDES)) {
            return;
        }

        Game storage game = gamesInProgress[player];
        game.direction = direction;
        game.state = GameState.WaitingForFinalCard;
        gamesInProgress[player] = game;
    }

     
    function getGameState(address player) public view returns
            (GameState, uint, BetDirection, uint, uint8, uint8, uint) {
        return (
            gamesInProgress[player].state,
            gamesInProgress[player].id,
            gamesInProgress[player].direction,
            gamesInProgress[player].bet,
            gamesInProgress[player].firstRoll,
            gamesInProgress[player].finalRoll,
            gamesInProgress[player].winnings
        );
    }

     
    function getMinBet() public view returns (uint) {
        return minBet;
    }

     
    function getMaxBet() public view returns (uint) {
        return SafeMath.div(SafeMath.div(SafeMath.mul(this.balance - balanceInPlay, maxBetThresholdPct), 100), 12);
    }

     
    function calculateWinnings(uint bet, uint percent) public pure returns (uint) {
        return SafeMath.div(SafeMath.mul(bet, percent), 100);
    }

     
    function getLowWinPercent(uint number) public pure returns (uint) {
        require(number >= 2 && number <= NUM_DICE_SIDES);
        if (number == 2) {
            return 1200;
        } else if (number == 3) {
            return 500;
        } else if (number == 4) {
            return 300;
        } else if (number == 5) {
            return 300;
        } else if (number == 6) {
            return 200;
        } else if (number == 7) {
            return 180;
        } else if (number == 8) {
            return 150;
        } else if (number == 9) {
            return 140;
        } else if (number == 10) {
            return 130;
        } else if (number == 11) {
            return 120;
        } else if (number == 12) {
            return 110;
        } else if (number == 13) {
            return 100;
        }
    }

     
    function getHighWinPercent(uint number) public pure returns (uint) {
        require(number >= 1 && number < NUM_DICE_SIDES);
        if (number == 1) {
            return 100;
        } else if (number == 2) {
            return 110;
        } else if (number == 3) {
            return 120;
        } else if (number == 4) {
            return 130;
        } else if (number == 5) {
            return 140;
        } else if (number == 6) {
            return 150;
        } else if (number == 7) {
            return 180;
        } else if (number == 8) {
            return 200;
        } else if (number == 9) {
            return 300;
        } else if (number == 10) {
            return 300;
        } else if (number == 11) {
            return 500;
        } else if (number == 12) {
            return 1200;
        }
    }


     
     

    function incomingRandomNumberError(address player) public {
        require(msg.sender == address(random));

        Game storage game = gamesInProgress[player];
        if (game.bet > 0) {
            game.player.transfer(game.bet);
        }

        delete gamesInProgress[player];
        GameError(player, game.id);
    }

    function incomingRandomNumber(address player, uint8 randomNumber) public {
        require(msg.sender == address(random));

        Game storage game = gamesInProgress[player];

        if (game.firstRoll == 0) {

            game.firstRoll = randomNumber;
            game.state = GameState.WaitingForDirection;
            gamesInProgress[player] = game;

            return;
        }

        uint8 finalRoll = randomNumber;
        uint winnings = 0;

        if (game.direction == BetDirection.High && finalRoll > game.firstRoll) {
            winnings = calculateWinnings(game.bet, getHighWinPercent(game.firstRoll));
        } else if (game.direction == BetDirection.Low && finalRoll < game.firstRoll) {
            winnings = calculateWinnings(game.bet, getLowWinPercent(game.firstRoll));
        }

         
         
         
         
         
         
         
         
         
         
        uint transferAmount = winnings;
        if (transferAmount > this.balance) {
            if (game.bet < this.balance) {
                transferAmount = game.bet;
            } else {
                transferAmount = SafeMath.div(SafeMath.mul(this.balance, 90), 100);
            }
        }

        balanceInPlay = balanceInPlay - game.bet;

        if (transferAmount > 0) {
            game.player.transfer(transferAmount);
        }

        game.finalRoll = finalRoll;
        game.winnings = winnings;
        game.state = GameState.Finished;
        gamesInProgress[player] = game;

        GameFinished(player, game.id, game.bet, game.firstRoll, finalRoll, winnings, transferAmount);
    }


     

     
    function transferBalance(address to, uint amount) public onlyOwner {
        to.transfer(amount);
    }

     
     
    function cleanupAbandonedGame(address player) public onlyOwner {
        require(player != address(0));

        Game storage game = gamesInProgress[player];
        require(game.player != address(0));

        game.player.transfer(game.bet);
        delete gamesInProgress[game.player];
    }

    function setRandomAddress(address _address) public onlyOwner {
        random = EtherHiLoRandomNumberGenerator(_address);
    }

     
    function setMinBet(uint bet) public onlyOwner {
        minBet = bet;
    }

     
    function setGameRunning(bool v) public onlyOwner {
        gameRunning = v;
    }

     
    function setMaxBetThresholdPct(uint v) public onlyOwner {
        maxBetThresholdPct = v;
    }

     
    function destroyAndSend(address _recipient) public onlyOwner {
        selfdestruct(_recipient);
    }

}