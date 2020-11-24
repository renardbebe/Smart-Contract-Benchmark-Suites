 

pragma solidity ^0.4.22;

contract Roulette {
  
  uint betAmount;
  uint necessaryBalance;
  uint nextRoundTimestamp;
  address creator;
  uint256 maxAmountAllowedInTheBank;
  mapping (address => uint256) winnings;
  uint8[] payouts;
  uint8[] numberRange;
  
   
  
  struct Bet {
    address player;
    uint8 betType;
    uint8 number;
  }
  Bet[] public bets;
  
  constructor() public payable {
    creator = msg.sender;
    necessaryBalance = 0;
    nextRoundTimestamp = now;
    payouts = [2,3,3,2,2,36];
    numberRange = [1,2,2,1,1,36];
    betAmount = 50000000000000000;  
    maxAmountAllowedInTheBank = 10000000000000000000;  
  }

  event RandomNumber(uint256 number);
  
  function getStatus() public view returns(uint, uint, uint, uint, uint) {
    return (
      bets.length,              
      bets.length * betAmount,  
      nextRoundTimestamp,       
      address(this).balance,    
      winnings[msg.sender]      
    ); 
  }
    
  function addEther() payable public {}

  function bet(uint8 number, uint8 betType) payable public {
     
    require(msg.value == betAmount);                                
    require(betType >= 0 && betType <= 5);                          
    require(number >= 0 && number <= numberRange[betType]);         
    uint payoutForThisBet = payouts[betType] * msg.value;
    uint provisionalBalance = necessaryBalance + payoutForThisBet;
    require(provisionalBalance < address(this).balance);            
     
    necessaryBalance += payoutForThisBet;
    bets.push(Bet({
      betType: betType,
      player: msg.sender,
      number: number
    }));
  }

  function spinWheel() public {
     
    require(bets.length > 0);
     
    require(now > nextRoundTimestamp);
     
    nextRoundTimestamp = now;
     
    uint diff = block.difficulty;
    bytes32 hash = blockhash(block.number-1);
    Bet memory lb = bets[bets.length-1];
    uint number = uint(keccak256(abi.encodePacked(now, diff, hash, lb.betType, lb.player, lb.number))) % 37;
     
    for (uint i = 0; i < bets.length; i++) {
      bool won = false;
      Bet memory b = bets[i];
      if (number == 0) {
        won = (b.betType == 5 && b.number == 0);                    
      } else {
        if (b.betType == 5) { 
          won = (b.number == number);                               
        } else if (b.betType == 4) {
          if (b.number == 0) won = (number % 2 == 0);               
          if (b.number == 1) won = (number % 2 == 1);               
        } else if (b.betType == 3) {            
          if (b.number == 0) won = (number <= 18);                  
          if (b.number == 1) won = (number >= 19);                  
        } else if (b.betType == 2) {                               
          if (b.number == 0) won = (number <= 12);                  
          if (b.number == 1) won = (number > 12 && number <= 24);   
          if (b.number == 2) won = (number > 24);                   
        } else if (b.betType == 1) {               
          if (b.number == 0) won = (number % 3 == 1);               
          if (b.number == 1) won = (number % 3 == 2);               
          if (b.number == 2) won = (number % 3 == 0);               
        } else if (b.betType == 0) {
          if (b.number == 0) {                                      
            if (number <= 10 || (number >= 20 && number <= 28)) {
              won = (number % 2 == 0);
            } else {
              won = (number % 2 == 1);
            }
          } else {                                                  
            if (number <= 10 || (number >= 20 && number <= 28)) {
              won = (number % 2 == 1);
            } else {
              won = (number % 2 == 0);
            }
          }
        }
      }
       
      if (won) {
        winnings[b.player] += betAmount * payouts[b.betType];
      }
    }
     
    bets.length = 0;
     
    necessaryBalance = 0;
     
    if (address(this).balance > maxAmountAllowedInTheBank) takeProfits();
     
    emit RandomNumber(number);
  }
  
  function cashOut() public {
    address player = msg.sender;
    uint256 amount = winnings[player];
    require(amount > 0);
    require(amount <= address(this).balance);
    winnings[player] = 0;
    player.transfer(amount);
  }
  
  function takeProfits() internal {
    uint amount = address(this).balance - maxAmountAllowedInTheBank;
    if (amount > 0) creator.transfer(amount);
  }
  
  function creatorKill() public {
    require(msg.sender == creator);
    selfdestruct(creator);
  }
 
}