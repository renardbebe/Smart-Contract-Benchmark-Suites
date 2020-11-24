 

pragma solidity ^0.4.17;

contract BitrngDice {
   
  address public owner;
  address private nextOwner;

   
  address public secretSigner;

   
  uint constant MIN_AMOUNT = 0.01 ether;
  uint constant MAX_AMOUNT_BIG_SMALL = 1 ether;
  uint constant MAX_AMOUNT_SAME = 0.05 ether;
  uint constant MAX_AMOUNT_NUMBER = 0.1 ether;

   
   
   
   
   
   
  uint constant BET_EXPIRATION_BLOCKS = 250;

   
  uint8 constant MAX_BET = 5;

   
  uint8 constant BET_MASK_COUNT = 22;

   
  uint24 constant BET_BIG = uint24(1 << 21);
  uint24 constant BET_SMALL = uint24(1 << 20);
  uint24 constant BET_SAME_1 = uint24(1 << 19);
  uint24 constant BET_SAME_2 = uint24(1 << 18);
  uint24 constant BET_SAME_3 = uint24(1 << 17);
  uint24 constant BET_SAME_4 = uint24(1 << 16);
  uint24 constant BET_SAME_5 = uint24(1 << 15);
  uint24 constant BET_SAME_6 = uint24(1 << 14);
  uint24 constant BET_4 = uint24(1 << 13);
  uint24 constant BET_5 = uint24(1 << 12);
  uint24 constant BET_6 = uint24(1 << 11);
  uint24 constant BET_7 = uint24(1 << 10);
  uint24 constant BET_8 = uint24(1 << 9);
  uint24 constant BET_9 = uint24(1 << 8);
  uint24 constant BET_10 = uint24(1 << 7);
  uint24 constant BET_11 = uint24(1 << 6);
  uint24 constant BET_12 = uint24(1 << 5);
  uint24 constant BET_13 = uint24(1 << 4);
  uint24 constant BET_14 = uint24(1 << 3);
  uint24 constant BET_15 = uint24(1 << 2);
  uint24 constant BET_16 = uint24(1 << 1);
  uint24 constant BET_17 = uint24(1);

   
   
  uint public lockedInBets;

   
  bool public enabled = true;

   
   
  address constant DUMMY_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

   
  struct Game{
    address gambler;
    uint40 placeBlockNumber;  
    uint bet1Amount;
    uint bet2Amount;
    uint bet3Amount;
    uint bet4Amount;
    uint bet5Amount;
    uint24 mask;  
  }

   
  mapping (uint => Game) games;

   
  mapping (uint24 => uint8) odds;

   
  mapping (uint24 => uint8) betNumberResults;

   
  mapping (uint24 => uint8) betSameResults;

   
  event FailedPayment(address indexed beneficiary, uint amount);
  event Payment(address indexed beneficiary, uint amount);

  constructor () public {
    owner = msg.sender;
    secretSigner = DUMMY_ADDRESS;

     
    odds[BET_SMALL] = 2;
    odds[BET_BIG] = 2;

    odds[BET_SAME_1] = 150;
    odds[BET_SAME_2] = 150;
    odds[BET_SAME_3] = 150;
    odds[BET_SAME_4] = 150;
    odds[BET_SAME_5] = 150;
    odds[BET_SAME_6] = 150;

    odds[BET_9] = 6;
    odds[BET_10] = 6;
    odds[BET_11] = 6;
    odds[BET_12] = 6;

    odds[BET_8] = 8;
    odds[BET_13] = 8;

    odds[BET_7] = 12;
    odds[BET_14] = 12;

    odds[BET_6] = 14;
    odds[BET_15] = 14;

    odds[BET_5] = 18;
    odds[BET_16] = 18;

    odds[BET_4] = 50;
    odds[BET_17] = 50;

     
    betNumberResults[BET_9] = 9;
    betNumberResults[BET_10] = 10;
    betNumberResults[BET_11] = 11;
    betNumberResults[BET_12] = 12;

    betNumberResults[BET_8] = 8;
    betNumberResults[BET_13] = 13;

    betNumberResults[BET_7] = 7;
    betNumberResults[BET_14] = 14;

    betNumberResults[BET_6] = 6;
    betNumberResults[BET_15] = 15;

    betNumberResults[BET_5] = 5;
    betNumberResults[BET_16] = 16;

    betNumberResults[BET_4] = 4;
    betNumberResults[BET_17] = 17;

    betSameResults[BET_SAME_1] = 1;
    betSameResults[BET_SAME_2] = 2;
    betSameResults[BET_SAME_3] = 3;
    betSameResults[BET_SAME_4] = 4;
    betSameResults[BET_SAME_5] = 5;
    betSameResults[BET_SAME_6] = 6;

  }

   
   
   
   
   
   
   
   
   
   
   
   
   
  function placeGame(
    uint24 betMask,
    uint bet1Amount,
    uint bet2Amount,
    uint bet3Amount,
    uint bet4Amount,
    uint bet5Amount,
    uint commitLastBlock,
    uint commit,
    bytes32 r,
    bytes32 s
  ) external payable
  {
     
    require (enabled, "Game is closed");
     
    require (bet1Amount + bet2Amount + bet3Amount + bet4Amount + bet5Amount == msg.value,
      "Place amount and payment should be equal.");

     
    Game storage game = games[commit];
    require (game.gambler == address(0),
      "Game should be in a 'clean' state.");

     
     
     
     
    require (block.number <= commitLastBlock, "Commit has expired.");
    bytes32 signatureHash = keccak256(abi.encodePacked(uint40(commitLastBlock), commit));
    require (secretSigner == ecrecover(signatureHash, 27, r, s), "ECDSA signature is not valid.");

     
    _lockOrUnlockAmount(
      betMask,
      bet1Amount,
      bet2Amount,
      bet3Amount,
      bet4Amount,
      bet5Amount,
      1
    );

     
    game.placeBlockNumber = uint40(block.number);
    game.mask = uint24(betMask);
    game.gambler = msg.sender;
    game.bet1Amount = bet1Amount;
    game.bet2Amount = bet2Amount;
    game.bet3Amount = bet3Amount;
    game.bet4Amount = bet4Amount;
    game.bet5Amount = bet5Amount;
  }

  function settleGame(uint reveal, uint cleanCommit) external {
     
    uint commit = uint(keccak256(abi.encodePacked(reveal)));
     
    Game storage game = games[commit];
    uint bet1Amount = game.bet1Amount;
    uint bet2Amount = game.bet2Amount;
    uint bet3Amount = game.bet3Amount;
    uint bet4Amount = game.bet4Amount;
    uint bet5Amount = game.bet5Amount;
    uint placeBlockNumber = game.placeBlockNumber;
    address gambler = game.gambler;
    uint24 betMask = game.mask;

     
    require (
      bet1Amount != 0 ||
      bet2Amount != 0 ||
      bet3Amount != 0 ||
      bet4Amount != 0 ||
      bet5Amount != 0,
      "Bet should be in an 'active' state");

     
    require (block.number > placeBlockNumber, "settleBet in the same block as placeBet, or before.");
    require (block.number <= placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

     
    game.bet1Amount = 0;
    game.bet2Amount = 0;
    game.bet3Amount = 0;
    game.bet4Amount = 0;
    game.bet5Amount = 0;

     
     
     
     
    uint entropy = uint(
      keccak256(abi.encodePacked(reveal, blockhash(placeBlockNumber)))
    );

    uint winAmount = _getWinAmount(
      uint8((entropy % 6) + 1),
      uint8(((entropy >> 10) % 6) + 1),
      uint8(((entropy >> 20) % 6) + 1),
      betMask,
      bet1Amount,
      bet2Amount,
      bet3Amount,
      bet4Amount,
      bet5Amount
    );

     
    _lockOrUnlockAmount(
      betMask,
      bet1Amount,
      bet2Amount,
      bet3Amount,
      bet4Amount,
      bet5Amount,
      0
    );

     
    if(winAmount > 0){
      sendFunds(gambler, winAmount);
    }else{
      sendFunds(gambler, 1 wei);
    }

     
    if (cleanCommit == 0) {
        return;
    }
    clearProcessedBet(cleanCommit);
  }

   
   
   
   
   
  function refundBet(uint commit) external {
     
    Game storage game = games[commit];
    uint bet1Amount = game.bet1Amount;
    uint bet2Amount = game.bet2Amount;
    uint bet3Amount = game.bet3Amount;
    uint bet4Amount = game.bet4Amount;
    uint bet5Amount = game.bet5Amount;

     
    require (
      bet1Amount != 0 ||
      bet2Amount != 0 ||
      bet3Amount != 0 ||
      bet4Amount != 0 ||
      bet5Amount != 0,
      "Bet should be in an 'active' state");

     
    require (block.number > game.placeBlockNumber + BET_EXPIRATION_BLOCKS, "Blockhash can't be queried by EVM.");

     
    game.bet1Amount = 0;
    game.bet2Amount = 0;
    game.bet3Amount = 0;
    game.bet4Amount = 0;
    game.bet5Amount = 0;

     
    _lockOrUnlockAmount(
      game.mask,
      bet1Amount,
      bet2Amount,
      bet3Amount,
      bet4Amount,
      bet5Amount,
      0
    );

     
    sendFunds(game.gambler, bet1Amount + bet2Amount + bet3Amount + bet4Amount + bet5Amount);
  }

   
  function clearProcessedBet(uint commit) private {
      Game storage game = games[commit];

       
       
      if (
        game.bet1Amount != 0 ||
        game.bet2Amount != 0 ||
        game.bet3Amount != 0 ||
        game.bet4Amount != 0 ||
        game.bet5Amount != 0 ||
        block.number <= game.placeBlockNumber + BET_EXPIRATION_BLOCKS
      ) {
          return;
      }

       
       
      game.placeBlockNumber = 0;
      game.mask = 0;
      game.gambler = address(0);
  }

   
  function clearStorage(uint[] cleanCommits) external {
      uint length = cleanCommits.length;

      for (uint i = 0; i < length; i++) {
          clearProcessedBet(cleanCommits[i]);
      }
  }

   
  function sendFunds(address beneficiary, uint amount) private {
    if (beneficiary.send(amount)) {
      emit Payment(beneficiary, amount);
    } else {
      emit FailedPayment(beneficiary, amount);
    }
  }

   
   
  function _getWinAmount(
    uint8 dice1,
    uint8 dice2,
    uint8 dice3,
    uint24 betMask,
    uint bet1Amount,
    uint bet2Amount,
    uint bet3Amount,
    uint bet4Amount,
    uint bet5Amount
  )
  private view returns (uint winAmount)
  {
    uint8 betCount = 0;
    uint24 flag = 0;
    uint8 sum = dice1 + dice2 + dice3;
    uint8 i = 0;

    for (i = 0; i < BET_MASK_COUNT; i++) {
      flag = uint24(1) << i;
      if(uint24(betMask & flag) == 0){
        continue;
      }else{
        betCount += 1;
      }
      if(i < 14){
        if(sum == betNumberResults[flag]){
          winAmount += odds[flag] * _nextAmount(
            betCount,
            bet1Amount,
            bet2Amount,
            bet3Amount,
            bet4Amount,
            bet5Amount
          );
        }
        continue;
      }
      if(i >= 14 && i < 20){
        if(dice1 == betSameResults[flag] && dice1 == dice2 && dice1 == dice3){
          winAmount += odds[flag] * _nextAmount(
            betCount,
            bet1Amount,
            bet2Amount,
            bet3Amount,
            bet4Amount,
            bet5Amount
          );
        }
        continue;
      }
      if(
        i == 20 &&
        (sum >= 4 && sum <= 10)  &&
        (dice1 != dice2 || dice1 != dice3 || dice2 != dice3)
      ){
        winAmount += odds[flag] * _nextAmount(
          betCount,
          bet1Amount,
          bet2Amount,
          bet3Amount,
          bet4Amount,
          bet5Amount
        );
      }
      if(
        i == 21 &&
        (sum >= 11 && sum <= 17)  &&
        (dice1 != dice2 || dice1 != dice3 || dice2 != dice3)
      ){
        winAmount += odds[flag] * _nextAmount(
          betCount,
          bet1Amount,
          bet2Amount,
          bet3Amount,
          bet4Amount,
          bet5Amount
        );
      }
      if(betCount == MAX_BET){
        break;
      }
    }
  }

   
  function _nextAmount(
    uint8 betCount,
    uint bet1Amount,
    uint bet2Amount,
    uint bet3Amount,
    uint bet4Amount,
    uint bet5Amount
  )
  private pure returns (uint amount)
  {
    if(betCount == 1){
      return bet1Amount;
    }
    if(betCount == 2){
      return bet2Amount;
    }
    if(betCount == 3){
      return bet3Amount;
    }
    if(betCount == 4){
      return bet4Amount;
    }
    if(betCount == 5){
      return bet5Amount;
    }
  }


   
   
  function _lockOrUnlockAmount(
    uint24 betMask,
    uint bet1Amount,
    uint bet2Amount,
    uint bet3Amount,
    uint bet4Amount,
    uint bet5Amount,
    uint8 lock
  )
  private
  {
    uint8 betCount;
    uint possibleWinAmount;
    uint betBigSmallWinAmount = 0;
    uint betNumberWinAmount = 0;
    uint betSameWinAmount = 0;
    uint24 flag = 0;
    for (uint8 i = 0; i < BET_MASK_COUNT; i++) {
      flag = uint24(1) << i;
      if(uint24(betMask & flag) == 0){
        continue;
      }else{
        betCount += 1;
      }
      if(i < 14 ){
        betNumberWinAmount = _assertAmount(
          betCount,
          bet1Amount,
          bet2Amount,
          bet3Amount,
          bet4Amount,
          bet5Amount,
          MAX_AMOUNT_NUMBER,
          odds[flag],
          betNumberWinAmount
        );
        continue;
      }
      if(i >= 14 && i < 20){
        betSameWinAmount = _assertAmount(
          betCount,
          bet1Amount,
          bet2Amount,
          bet3Amount,
          bet4Amount,
          bet5Amount,
          MAX_AMOUNT_SAME,
          odds[flag],
          betSameWinAmount
        );
        continue;
      }
      if(i >= 20){
         betBigSmallWinAmount = _assertAmount(
          betCount,
          bet1Amount,
          bet2Amount,
          bet3Amount,
          bet4Amount,
          bet5Amount,
          MAX_AMOUNT_BIG_SMALL,
          odds[flag],
          betBigSmallWinAmount
        );
        continue;
      }
      if(betCount == MAX_BET){
        break;
      }
    }
    if(betSameWinAmount >= betBigSmallWinAmount){
      possibleWinAmount += betSameWinAmount;
    }else{
      possibleWinAmount += betBigSmallWinAmount;
    }
    possibleWinAmount += betNumberWinAmount;

     
    require (betCount > 0 && betCount <= MAX_BET,
      "Place bet count should be within range.");

    if(lock == 1){
       
      lockedInBets += possibleWinAmount;
       
      require (lockedInBets <= address(this).balance,
        "Cannot afford to lose this bet.");
    }else{
       
      lockedInBets -= possibleWinAmount;
      require (lockedInBets >= 0,
        "Not enough locked in amount.");
    }
  }

  function _max(uint amount, uint8 odd, uint possibleWinAmount)
  private pure returns (uint newAmount)
  {
    uint winAmount = amount * odd;
    if( winAmount > possibleWinAmount){
      return winAmount;
    }else{
      return possibleWinAmount;
    }
  }

  function _assertAmount(
    uint8 betCount,
    uint amount1,
    uint amount2,
    uint amount3,
    uint amount4,
    uint amount5,
    uint maxAmount,
    uint8 odd,
    uint possibleWinAmount
  )
  private pure returns (uint amount)
  {
    string memory warnMsg = "Place bet amount should be within range.";
    if(betCount == 1){
      require (amount1 >= MIN_AMOUNT && amount1 <= maxAmount, warnMsg);
      return _max(amount1, odd, possibleWinAmount);
    }
    if(betCount == 2){
      require (amount2 >= MIN_AMOUNT && amount2 <= maxAmount, warnMsg);
      return _max(amount2, odd, possibleWinAmount);
    }
    if(betCount == 3){
      require (amount3 >= MIN_AMOUNT && amount3 <= maxAmount, warnMsg);
      return _max(amount3, odd, possibleWinAmount);
    }
    if(betCount == 4){
      require (amount4 >= MIN_AMOUNT && amount4 <= maxAmount, warnMsg);
      return _max(amount4, odd, possibleWinAmount);
    }
    if(betCount == 5){
      require (amount5 >= MIN_AMOUNT && amount5 <= maxAmount, warnMsg);
      return _max(amount5, odd, possibleWinAmount);
    }
  }

   
  modifier onlyOwner {
      require (msg.sender == owner, "OnlyOwner methods called by non-owner.");
      _;
  }

   
  function approveNextOwner(address _nextOwner) external onlyOwner {
    require (_nextOwner != owner, "Cannot approve current owner.");
    nextOwner = _nextOwner;
  }

  function acceptNextOwner() external {
    require (msg.sender == nextOwner, "Can only accept preapproved new owner.");
    owner = nextOwner;
  }

   
   
  function () public payable {
  }

   
  function setSecretSigner(address newSecretSigner) external onlyOwner {
    secretSigner = newSecretSigner;
  }

   
  function withdrawFunds(address beneficiary, uint withdrawAmount) external onlyOwner {
    require (withdrawAmount <= address(this).balance, "Increase amount larger than balance.");
    require (lockedInBets + withdrawAmount <= address(this).balance, "Not enough funds.");
    sendFunds(beneficiary, withdrawAmount);
  }

   
   
  function kill() external onlyOwner {
      require (lockedInBets == 0, "All bets should be processed (settled or refunded) before self-destruct.");
      selfdestruct(owner);
  }

   
  function enable(bool _enabled) external onlyOwner{
    enabled = _enabled;
  }

}