 

pragma solidity 0.4.24;


 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}


 
contract BethsHouse is Ownable {
   
  event HouseCutPercentageChanged(uint newHouseCutPercentage);

   
  uint public houseCutPercentage = 10;

   
  function changeHouseCutPercentage(uint newHouseCutPercentage) external onlyOwner {
     
    if (newHouseCutPercentage >= 0 && newHouseCutPercentage < 20) {
      houseCutPercentage = newHouseCutPercentage;
      emit HouseCutPercentageChanged(newHouseCutPercentage);
    }
  }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}


 
contract BethsGame is BethsHouse {
   
  using SafeMath for uint256;

   
  event GameHasOpened(uint gameId, string teamA, string teamB, string description, uint frozenTimestamp);

   
  event GameHasFrozen(uint gameId);

   
  event GameHasClosed(uint gameId, GameResults result);

   
  enum GameStates { Open, Frozen, Closed }

   
  enum GameResults { NotYet, TeamA, Draw, TeamB }

   
  struct Game {
    string teamA;
    uint amountToTeamA;
    string teamB;
    uint amountToTeamB;
    uint amountToDraw;
    string description;
    uint frozenTimestamp;
    uint bettorsCount;
    GameResults result;
    GameStates state;
    bool isHouseCutWithdrawn;
  }

   
  Game[] public games;

   
  function createNewGame(
    string teamA,
    string teamB,
    string description,
    uint frozenTimestamp
  ) external onlyOwner {
     
    uint gameId = games.push(Game(
      teamA, 0, teamB, 0, 0, description, frozenTimestamp, 0, GameResults.NotYet, GameStates.Open, false
    )) - 1;

    emit GameHasOpened(gameId, teamA, teamB, description, frozenTimestamp);
  }

   
  function freezeGame(uint gameId) external onlyOwner whenGameIsOpen(gameId) {
    games[gameId].state = GameStates.Frozen;

    emit GameHasFrozen(gameId);
  }

   
  function closeGame(uint gameId, GameResults result) external onlyOwner whenGameIsFrozen(gameId) {
    games[gameId].state = GameStates.Closed;
    games[gameId].result = result;

    emit GameHasClosed(gameId, result);
  }

   
  function getGameInfo(uint gameId) public view returns (
    string,
    string,
    string
  ) {
    return (
      games[gameId].teamA,
      games[gameId].teamB,
      games[gameId].description
    );
  }

   
  function getGameAmounts(uint gameId) public view returns (
    uint,
    uint,
    uint,
    uint,
    uint
  ) {
    return (
      games[gameId].amountToTeamA,
      games[gameId].amountToDraw,
      games[gameId].amountToTeamB,
      games[gameId].bettorsCount,
      games[gameId].frozenTimestamp
    );
  }

   
  function getGameState(uint gameId) public view returns (GameStates) {
    return games[gameId].state;
  }

   
  function getGameResult(uint gameId) public view returns (GameResults) {
    return games[gameId].result;
  }

   
  function getTotalGames() public view returns (uint) {
    return games.length;
  }

   
  function compareStrings(string a, string b) internal pure returns (bool) {
    return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
  }

   
  modifier whenGameIsOpen(uint gameId) {
    require(games[gameId].state == GameStates.Open);
    _;
  }

   
  modifier whenGameIsFrozen(uint gameId) {
    require(games[gameId].state == GameStates.Frozen);
    _;
  }

   
  modifier whenGameIsClosed(uint gameId) {
    require(games[gameId].state == GameStates.Closed);
    _;
  }
}


 
contract BethsBet is BethsGame {
   
  event NewBetPlaced(uint gameId, GameResults result, uint amount);

   
  uint public minimumBetAmount = 1000000000;

   
  struct Bet {
    uint gameId;
    GameResults result;
    uint amount;
    bool isPayoutWithdrawn;
  }

   
  Bet[] public bets;

   
  mapping (uint => address) public betToAddress;

   
  mapping (address => uint[]) public addressToBets;

   
  function changeMinimumBetAmount(uint newMinimumBetAmount) external onlyOwner {
    if (newMinimumBetAmount > 0) {
      minimumBetAmount = newMinimumBetAmount;
    }
  }

   
  function placeNewBet(uint gameId, GameResults result) public whenGameIsOpen(gameId) payable {
     
    if (msg.value >= minimumBetAmount) {
       
      uint betId = bets.push(Bet(gameId, result, msg.value, false)) - 1;

       
      betToAddress[betId] = msg.sender;

       
      addressToBets[msg.sender].push(betId);

       
      games[gameId].bettorsCount = games[gameId].bettorsCount.add(1);

       
      if (result == GameResults.TeamA) {
        games[gameId].amountToTeamA = games[gameId].amountToTeamA.add(msg.value);
      } else if (result == GameResults.Draw) {
        games[gameId].amountToDraw = games[gameId].amountToDraw.add(msg.value);
      } else if (result == GameResults.TeamB) {
        games[gameId].amountToTeamB = games[gameId].amountToTeamB.add(msg.value);
      }

       
      emit NewBetPlaced(gameId, result, msg.value);
    }
  }

   
  function getBetsFromAddress(address bettorAddress) public view returns (uint[]) {
    return addressToBets[bettorAddress];
  }

   
  function getBetInfo(uint betId) public view returns (uint, GameResults, uint, bool) {
    return (bets[betId].gameId, bets[betId].result, bets[betId].amount, bets[betId].isPayoutWithdrawn);
  }
}


 
contract BethsPayout is BethsBet {
   
  function withdrawHouseCutFromGame(uint gameId) external onlyOwner whenGameIsClosed(gameId) {
     
    if (!games[gameId].isHouseCutWithdrawn) {
      games[gameId].isHouseCutWithdrawn = true;
      uint houseCutAmount = calculateHouseCutAmount(gameId);
      owner.transfer(houseCutAmount);
    }
  }

   
  function withdrawPayoutFromBet(uint betId) external whenGameIsClosed(bets[betId].gameId) {
     
    require(games[bets[betId].gameId].result == bets[betId].result);

     
    if (!bets[betId].isPayoutWithdrawn) {
       
      uint payout = calculatePotentialPayout(betId);

       
      bets[betId].isPayoutWithdrawn = true;

      address bettorAddress = betToAddress[betId];

       
      bettorAddress.transfer(payout);
    }
  }

   
  function calculateRawPoolAmount(uint gameId) internal view returns (uint) {
    return games[gameId].amountToDraw.add(games[gameId].amountToTeamA.add(games[gameId].amountToTeamB));
  }

   
  function calculateHouseCutAmount(uint gameId) internal view returns (uint) {
    uint rawPoolAmount = calculateRawPoolAmount(gameId);
    return houseCutPercentage.mul(rawPoolAmount.div(100));
  }

   
  function calculatePoolAmount(uint gameId) internal view returns (uint) {
    uint rawPoolAmount = calculateRawPoolAmount(gameId);
    uint houseCutAmount = calculateHouseCutAmount(gameId);

    return rawPoolAmount.sub(houseCutAmount);
  }

   
  function calculatePotentialPayout(uint betId) internal view returns (uint) {
    uint betAmount = bets[betId].amount;

    uint poolAmount = calculatePoolAmount(bets[betId].gameId);

    uint temp = betAmount.mul(poolAmount);

    uint betAmountToWinningTeam = 0;

    if (games[bets[betId].gameId].result == GameResults.TeamA) {
      betAmountToWinningTeam = games[bets[betId].gameId].amountToTeamA;
    } else if (games[bets[betId].gameId].result == GameResults.TeamB) {
      betAmountToWinningTeam = games[bets[betId].gameId].amountToTeamB;
    } else if (games[bets[betId].gameId].result == GameResults.Draw) {
      betAmountToWinningTeam = games[bets[betId].gameId].amountToDraw;
    }

    return temp.div(betAmountToWinningTeam);
  }
}