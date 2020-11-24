 

pragma solidity ^0.4.21;

contract TwoXJackpot {
  using SafeMath for uint256;
  address public contractOwner;   

   
   
  struct BuyIn {
    uint256 value;
    address owner;
  }

   
  struct Game {
    BuyIn[] buyIns;             
    address[] winners;          
    uint256[] winnerPayouts;    
    uint256 gameTotalInvested;  
    uint256 gameTotalPaidOut;   
    uint256 gameTotalBacklog;   
    uint256 index;              

    mapping (address => uint256) totalInvested;  
    mapping (address => uint256) totalValue;     
    mapping (address => uint256) totalPaidOut;   
  }

  mapping (uint256 => Game) public games;   
  uint256 public gameIndex;     

   

   
  uint256 public jackpotBalance;         
  address public jackpotLastQualified;   
  address public jackpotLastWinner;      
  uint256 public jackpotLastPayout;      
  uint256 public jackpotCount;           


   
  uint256 public gameStartTime;      
  uint256 public roundStartTime;     
  uint256 public lastAction;         
  uint256 public timeBetweenGames = 24 hours;        
  uint256 public timeBeforeJackpot = 30 minutes;     
  uint256 public timeBeforeJackpotReset = timeBeforeJackpot;  
  uint256 public timeIncreasePerTx = 1 minutes;      
  uint256 public timeBetweenRounds = 5 minutes;   


   
  uint256 public buyFee = 90;        
  uint256 public minBuy = 50;        
  uint256 public maxBuy = 2;         
  uint256 public minMinBuyETH = 0.02 ether;  
  uint256 public minMaxBuyETH = 0.5 ether;  
  uint256[] public gameReseeds = [90, 80, 60, 20];  


  modifier onlyContractOwner() {
    require(msg.sender == contractOwner);
    _;
  }

  modifier isStarted() {
      require(now >= gameStartTime);  
      require(now >= roundStartTime);  
      _;
  }


   
  event Purchase(uint256 amount, address depositer);
  event Seed(uint256 amount, address seeder);

  function TwoXJackpot() public {
    contractOwner = msg.sender;
    gameStartTime = now + timeBetweenGames;
    lastAction = gameStartTime;
  }

   
   
   

   
  function changeStartTime(uint256 _time) public onlyContractOwner {
    require(now < _time);  
    gameStartTime = _time;
    lastAction = gameStartTime;  
  }

   
  function updateTimeBetweenGames(uint256 _time) public onlyContractOwner {
    timeBetweenGames = _time;  
  }

   
   
   

   
   
  function seed() public payable {
    jackpotBalance += msg.value;  
     
    emit Seed(msg.value, msg.sender);
  }

  function purchase() public payable isStarted  {
     
    if (now > lastAction + timeBeforeJackpot &&
      jackpotLastQualified != 0x0) {
      claim();
       
      if (msg.value > 0) {
        msg.sender.transfer(msg.value);
      }
      return;
    }

     
     
    if (jackpotBalance <= 1 ether) {
      require(msg.value >= minMinBuyETH);  
      require(msg.value <= minMaxBuyETH);  
    } else {
      uint256 purchaseMin = SafeMath.mul(msg.value, minBuy);
      uint256 purchaseMax = SafeMath.mul(msg.value, maxBuy);
      require(purchaseMin >= jackpotBalance);
      require(purchaseMax <= jackpotBalance);
    }

    uint256 valueAfterTax = SafeMath.div(SafeMath.mul(msg.value, buyFee), 100);      
    uint256 potFee = SafeMath.sub(msg.value, valueAfterTax);                         


    jackpotBalance += potFee;            
    jackpotLastQualified = msg.sender;   
    lastAction = now;                    
    timeBeforeJackpot += timeIncreasePerTx;                 
    uint256 valueMultiplied = SafeMath.mul(msg.value, 2);   

     
    games[gameIndex].gameTotalInvested += msg.value;
    games[gameIndex].gameTotalBacklog += valueMultiplied;

     
    games[gameIndex].totalInvested[msg.sender] += msg.value;
    games[gameIndex].totalValue[msg.sender] += valueMultiplied;

     
    games[gameIndex].buyIns.push(BuyIn({
      value: valueMultiplied,
      owner: msg.sender
    }));
     
    emit Purchase(msg.value, msg.sender);

    while (games[gameIndex].index < games[gameIndex].buyIns.length
            && valueAfterTax > 0) {

      BuyIn storage buyIn = games[gameIndex].buyIns[games[gameIndex].index];

      if (valueAfterTax < buyIn.value) {
        buyIn.owner.transfer(valueAfterTax);

         
        games[gameIndex].gameTotalBacklog -= valueAfterTax;
        games[gameIndex].gameTotalPaidOut += valueAfterTax;

         
        games[gameIndex].totalPaidOut[buyIn.owner] += valueAfterTax;
        games[gameIndex].totalValue[buyIn.owner] -= valueAfterTax;
        buyIn.value -= valueAfterTax;
        valueAfterTax = 0;
      } else {
        buyIn.owner.transfer(buyIn.value);

         
        games[gameIndex].gameTotalBacklog -= buyIn.value;
        games[gameIndex].gameTotalPaidOut += buyIn.value;

         
        games[gameIndex].totalPaidOut[buyIn.owner] += buyIn.value;
        games[gameIndex].totalValue[buyIn.owner] -= buyIn.value;
        valueAfterTax -= buyIn.value;
        buyIn.value = 0;
        games[gameIndex].index++;
      }
    }
  }


   
  function claim() public payable isStarted {
    require(now > lastAction + timeBeforeJackpot);
    require(jackpotLastQualified != 0x0);  

     
     
    uint256 reseed = SafeMath.div(SafeMath.mul(jackpotBalance, gameReseeds[jackpotCount]), 100);
    uint256 payout = jackpotBalance - reseed;


    jackpotLastQualified.transfer(payout);  
    jackpotBalance = reseed;
    jackpotLastWinner = jackpotLastQualified;
    jackpotLastPayout = payout;

     
    games[gameIndex].winners.push(jackpotLastQualified);
    games[gameIndex].winnerPayouts.push(payout);

     
    timeBeforeJackpot = timeBeforeJackpotReset;  
    jackpotLastQualified = 0x0;  

    if(jackpotCount == gameReseeds.length - 1){
       
      gameStartTime = now + timeBetweenGames;     
      lastAction = gameStartTime;  
      gameIndex += 1;  
      jackpotCount = 0;   

    } else {
      lastAction = now + timeBetweenRounds;
      roundStartTime = lastAction;
      jackpotCount += 1;
    }
  }

   
  function () public payable {
    purchase();
  }

   
   
   
   
  function getJackpotInfo() public view returns (uint256, address, address, uint256, uint256, uint256, uint256, uint256, uint256) {
    return (
        jackpotBalance,
        jackpotLastQualified,
        jackpotLastWinner,
        jackpotLastPayout,
        jackpotCount,
        gameIndex,
        gameStartTime,
        lastAction + timeBeforeJackpot,
        roundStartTime
      );
  }

   
   
  function getPlayerGameInfo(uint256 _gameIndex, address _player) public view returns (uint256, uint256, uint256) {
    return (
        games[_gameIndex].totalInvested[_player],
        games[_gameIndex].totalValue[_player],
        games[_gameIndex].totalPaidOut[_player]
      );
  }

   
  function getMyGameInfo() public view returns (uint256, uint256, uint256) {
    return getPlayerGameInfo(gameIndex, msg.sender);
  }

   
  function getGameConstants() public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256[]) {
    return (
        timeBetweenGames,
        timeBeforeJackpot,
        minMinBuyETH,
        minMaxBuyETH,
        minBuy,
        maxBuy,
        gameReseeds
      );
  }

   
  function getGameInfo(uint256 _gameIndex) public view returns (uint256, uint256, uint256, address[], uint256[]) {
    return (
        games[_gameIndex].gameTotalInvested,
        games[_gameIndex].gameTotalPaidOut,
        games[_gameIndex].gameTotalBacklog,
        games[_gameIndex].winners,
        games[_gameIndex].winnerPayouts
      );
  }

   
  function getCurrentGameInfo() public view returns (uint256, uint256, uint256, address[], uint256[]) {
    return getGameInfo(gameIndex);
  }

   
  function getGameStartTime() public view returns (uint256) {
    return gameStartTime;
  }

   
  function getJackpotRoundEndTime() public view returns (uint256) {
    return lastAction + timeBeforeJackpot;
  }
}


 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
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
}