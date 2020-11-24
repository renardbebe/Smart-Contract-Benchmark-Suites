 

pragma solidity 0.4.25;

 
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

contract BMRoll {
  using SafeMath for uint256;
   
  modifier betIsValid(uint _betSize, uint _playerNumber) {
    require(_betSize >= minBet && _playerNumber >= minNumber && _playerNumber <= maxNumber && (((((_betSize * (100-(_playerNumber.sub(1)))) / (_playerNumber.sub(1))+_betSize))*houseEdge/houseEdgeDivisor)-_betSize <= maxProfit));
    _;
  }
  
   
  modifier gameIsActive {
    require(gamePaused == false);
    _;
  }
  
   
  modifier payoutsAreActive {
    require(payoutsPaused == false);
    _;
  }
   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
  
   
  modifier onlyTreasury {
    require (msg.sender == treasury);
    _;
  }
  
   
  uint constant public maxProfitDivisor = 1000000;
  uint constant public houseEdgeDivisor = 1000;
  uint constant public maxNumber = 99;
  uint constant public minNumber = 2;
  bool public gamePaused;
  address public owner;
  address public server;
  bool public payoutsPaused;
  address public treasury;
  uint public contractBalance;
  uint public houseEdge;
  uint public maxProfit;
  uint public maxProfitAsPercentOfHouse;
  uint public minBet;
  
  uint public totalBets = 0;
  uint public totalSunWon = 0;
  uint public totalSunWagered = 0;
  
  address[100] lastUser;
  
   
  mapping (uint => address) playerAddress;
  mapping (uint => address) playerTempAddress;
  mapping (uint => uint) playerBetValue;
  mapping (uint => uint) playerTempBetValue;
  mapping (uint => uint) playerDieResult;
  mapping (uint => uint) playerNumber;
  mapping (address => uint) playerPendingWithdrawals;
  mapping (uint => uint) playerProfit;
  mapping (uint => uint) playerTempReward;
  
   
   
   
  event LogResult(uint indexed BetID, address indexed PlayerAddress, uint PlayerNumber, uint DiceResult, uint ProfitValue, uint BetValue, int Status);
   
  event LogOwnerTransfer(address indexed SentToAddress, uint indexed AmountTransferred);
  
   
  constructor() public {
    
    owner = msg.sender;
    treasury = msg.sender;
     
    ownerSetHouseEdge(980);
     
    ownerSetMaxProfitAsPercentOfHouse(50000);
     
    ownerSetMinBet(100000000000000000);   
  }
  
   
  function playerRollDice(uint rollUnder) public
  payable
  gameIsActive
  betIsValid(msg.value, rollUnder)
  {
     
    
    lastUser[totalBets % 100] = msg.sender;
    totalBets += 1;
    
     
    playerNumber[totalBets] = rollUnder;
     
    playerBetValue[totalBets] = msg.value;
     
    playerAddress[totalBets] = msg.sender;
     
    playerProfit[totalBets] = ((((msg.value * (100-(rollUnder.sub(1)))) / (rollUnder.sub(1))+msg.value))*houseEdge/houseEdgeDivisor)-msg.value;
    
     
    uint256 random1 = uint256(blockhash(block.number-1));
    uint256 random2 = uint256(lastUser[random1 % 100]);
    uint256 random3 = uint256(block.coinbase) + random2;
    uint256 result = uint256(keccak256(abi.encodePacked(random1 + random2 + random3 + now + totalBets))) % 100 + 1;  
    
     
    playerDieResult[totalBets] = result;
     
    playerTempAddress[totalBets] = playerAddress[totalBets];
     
    delete playerAddress[totalBets];
    
     
    playerTempReward[totalBets] = playerProfit[totalBets];
     
    playerProfit[totalBets] = 0;
    
     
    playerTempBetValue[totalBets] = playerBetValue[totalBets];
     
    playerBetValue[totalBets] = 0;
    
     
    totalSunWagered += playerTempBetValue[totalBets];
    
     
    if(playerDieResult[totalBets] < playerNumber[totalBets]){
      
       
      contractBalance = contractBalance.sub(playerTempReward[totalBets]);
      
       
      totalSunWon = totalSunWon.add(playerTempReward[totalBets]);
      
       
      playerTempReward[totalBets] = playerTempReward[totalBets].add(playerTempBetValue[totalBets]);
      
      emit LogResult(totalBets, playerTempAddress[totalBets], playerNumber[totalBets], playerDieResult[totalBets], playerTempReward[totalBets], playerTempBetValue[totalBets],1);
      
       
      setMaxProfit();
      
       
      if(!playerTempAddress[totalBets].send(playerTempReward[totalBets])){
        emit LogResult(totalBets, playerTempAddress[totalBets], playerNumber[totalBets], playerDieResult[totalBets], playerTempReward[totalBets], playerTempBetValue[totalBets], 2);
         
        playerPendingWithdrawals[playerTempAddress[totalBets]] = playerPendingWithdrawals[playerTempAddress[totalBets]].add(playerTempReward[totalBets]);
      }
      
      return;
      
    }
    
     
    if(playerDieResult[totalBets] >= playerNumber[totalBets]){
      
      emit LogResult(totalBets, playerTempAddress[totalBets], playerNumber[totalBets], playerDieResult[totalBets], 0, playerTempBetValue[totalBets], 0);
      
       
      contractBalance = contractBalance.add((playerTempBetValue[totalBets]-1));
      
       
      setMaxProfit();
      
       
      if(!playerTempAddress[totalBets].send(1)){
         
        playerPendingWithdrawals[playerTempAddress[totalBets]] = playerPendingWithdrawals[playerTempAddress[totalBets]].add(1);
      }
      
      return;
      
    }
  }
  
   
  function playerWithdrawPendingTransactions() public
  payoutsAreActive
  returns (bool)
  {
    uint withdrawAmount = playerPendingWithdrawals[msg.sender];
    playerPendingWithdrawals[msg.sender] = 0;
     
    if (msg.sender.call.value(withdrawAmount)()) {
      return true;
      } else {
         
         
        playerPendingWithdrawals[msg.sender] = withdrawAmount;
        return false;
      }
    }
    
     
    function playerGetPendingTxByAddress(address addressToCheck) public view returns (uint) {
      return playerPendingWithdrawals[addressToCheck];
    }
    
     
    function getGameStatus() public view returns(uint, uint, uint, uint, uint, uint) {
      return (minBet, minNumber, maxNumber, houseEdge, houseEdgeDivisor, maxProfit);
    }
    
     
    function setMaxProfit() internal {
      maxProfit = (contractBalance*maxProfitAsPercentOfHouse)/maxProfitDivisor;
    }
    
     
    function ()
        payable public
        onlyTreasury
    {
       
      contractBalance = contractBalance.add(msg.value);
       
      setMaxProfit();
    }
    
     
    function ownerUpdateContractBalance(uint newContractBalanceInSun) public
    onlyOwner
    {
      contractBalance = newContractBalanceInSun;
    }
    
     
    function ownerSetHouseEdge(uint newHouseEdge) public
    onlyOwner
    {
      houseEdge = newHouseEdge;
    }
    
     
    function ownerSetMaxProfitAsPercentOfHouse(uint newMaxProfitAsPercent) public
    onlyOwner
    {
       
      require(newMaxProfitAsPercent <= 50000);
      maxProfitAsPercentOfHouse = newMaxProfitAsPercent;
      setMaxProfit();
    }
    
     
    function ownerSetMinBet(uint newMinimumBet) public
    onlyOwner
    {
      minBet = newMinimumBet;
    }
    
     
    function ownerTransferEth(address sendTo, uint amount) public
    onlyOwner
    {
       
      contractBalance = contractBalance.sub(amount);
       
      setMaxProfit();
      if(!sendTo.send(amount)) revert();
      emit LogOwnerTransfer(sendTo, amount);
    }
    
    
     
    function ownerPauseGame(bool newStatus) public
    onlyOwner
    {
      gamePaused = newStatus;
    }
    
     
    function ownerPausePayouts(bool newPayoutStatus) public
    onlyOwner
    {
      payoutsPaused = newPayoutStatus;
    }
    
     
    function ownerSetTreasury(address newTreasury) public
    onlyOwner
    {
      treasury = newTreasury;
    }
    
     
    function ownerChangeOwner(address newOwner) public
    onlyOwner
    {
      require(newOwner != 0);
      owner = newOwner;
    }
    
     
    function ownerkill() public
    onlyOwner
    {
      selfdestruct(owner);
    }
    
    
  }