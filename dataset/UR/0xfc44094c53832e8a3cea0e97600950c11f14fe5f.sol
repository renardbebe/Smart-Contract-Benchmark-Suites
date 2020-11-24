 

 
pragma solidity ^0.4.17;

contract owned {
  address public owner;
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function owned() public{
    owner = msg.sender;
  }

  function changeOwner(address newOwner) onlyOwner public {
    owner = newOwner;
  }
}

contract mortal is owned {
  function close() onlyOwner public{
    selfdestruct(owner);
  }
}

contract casino is mortal{
   
  uint public minimumBet;
   
  uint public maximumBet;
   
  mapping(address => bool) public authorized;
  
   
  function casino(uint minBet, uint maxBet) public{
    minimumBet = minBet;
    maximumBet = maxBet;
  }

   
  function setMinimumBet(uint newMin) onlyOwner public{
    minimumBet = newMin;
  }

   
  function setMaximumBet(uint newMax) onlyOwner public{
    maximumBet = newMax;
  }

  
   
  function authorize(address addr) onlyOwner public{
    authorized[addr] = true;
  }
  
   
  function deauthorize(address addr) onlyOwner public{
    authorized[addr] = false;
  }
  
  
   
  modifier onlyAuthorized{
    require(authorized[msg.sender]);
    _;
  }
}

contract blackjack is casino {

   
  uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];
   
  mapping(bytes32 => bool) public over;
   
  mapping(bytes32 => uint) bets;
    
  mapping(bytes32 => uint8[]) splits;
   
  mapping(bytes32 => mapping(uint8 => bool)) doubled;
  
   
  event NewGame(bytes32 indexed id, bytes32 deck, bytes32 cSeed, address player, uint bet);
   
  event Result(bytes32 indexed id, address player, uint value, bool isWin);
   
  event Double(bytes32 indexed id, uint8 hand);
   
  event Split(bytes32 indexed id, uint8 hand);

   
  function blackjack(uint minBet, uint maxBet) casino(minBet, maxBet) public{

  }

   
  function initGame(address player, uint value, bytes32 deck, bytes32 srvSeed, bytes32 cSeed) onlyAuthorized  public{
     
    assert(value >= minimumBet && value <= maximumBet);
    assert(!over[srvSeed]&&bets[srvSeed]==0); 
    bets[srvSeed] = value;
    assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player, value, false));
    NewGame(srvSeed, deck, cSeed, player, value);
  }

   
  function double(address player, bytes32 id, uint8 hand, uint value) onlyAuthorized public {
    require(!over[id]);
    require(checkBet(id, value)); 
    require(hand <= splits[id].length && !doubled[id][hand]); 
    doubled[id][hand] = true;
    bets[id] += value;
    assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player, value, false));
    Double(id, hand);
  }

   
  function split(address player, bytes32 id, uint8 hand, uint value) onlyAuthorized public  {
    require(!over[id]);
    require(checkBet(id, value)); 
    require(splits[id].length < 3);
    splits[id].push(hand);
    bets[id] += value;
    assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player, value, false));
    Split(id,hand);
  }
  
   
  function surrender(address player, bytes32 seed, uint bet) onlyAuthorized public {
    var id = keccak256(seed);
    require(!over[id]);
    over[id] = true;
    if(bets[id]>0){
      assert(bets[id]==bet);
      assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player,bet / 2, true));
      Result(id, player, bet / 2, true);
    }
    else{
      assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player,bet / 2, false));
      Result(id, player, bet / 2, false);
    }
  }

   
  function stand(address player, uint8[] deck, bytes32 seed, uint8[] numCards, uint8[] splits, bool[] doubled,uint bet, bytes32 deckHash, bytes32 cSeed) onlyAuthorized public {
    bytes32 gameId;
    gameId = keccak256(seed);
    assert(!over[gameId]);
    assert(splits.length == numCards.length - 1);
    over[gameId] = true;
    assert(checkDeck(deck, seed, deckHash)); 
    
    var (win,loss) = determineOutcome(deck, numCards, splits, doubled, bet);
    
    if(bets[gameId] > 0){ 
      assert(checkBet(gameId, bet));
      win += bets[gameId]; 
    }
    else
      NewGame(gameId, deckHash, cSeed, player, bet);
    
    if (win > loss){
      assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player, win-loss, true));
      Result(gameId, player, win-loss, true); 
    }  
    else if(loss > win){ 
      assert(msg.sender.call(bytes4(keccak256("shift(address,uint256,bool)")),player, loss-win, false));
      Result(gameId, player, loss-win, false); 
    }
    else
      Result(gameId, player, 0, false);
     
  }

   
  function checkDeck(uint8[] deck, bytes32 seed, bytes32 deckHash) constant public returns(bool correct) {
    if (keccak256(convertToBytes(deck), seed) != deckHash) return false;
    return true;
  }

   
  function convertToBytes(uint8[] byteArray) internal constant returns(bytes b) {
    b = new bytes(byteArray.length);
    for (uint8 i = 0; i < byteArray.length; i++)
      b[i] = byte(byteArray[i]);
  }
  
   
  function checkBet(bytes32 gameId, uint bet) internal constant returns (bool correct){
    uint factor = splits[gameId].length + 1;
    for(uint8 i = 0; i < splits[gameId].length+1; i++){
      if(doubled[gameId][i]) factor++;
    }
    return bets[gameId] == bet * factor;
  }

   
  function determineOutcome(uint8[] cards, uint8[] numCards, uint8[] splits, bool[] doubled, uint bet) constant public returns(uint totalWin, uint totalLoss) {

    var playerValues = getPlayerValues(cards, numCards, splits);
    var (dealerValue, dealerBJ) = getDealerValue(cards, sum(numCards));
    uint win;
    uint loss;
    for (uint8 h = 0; h < numCards.length; h++) {
      uint8 playerValue = playerValues[h];
       
      if (playerValue > 21){
        win = 0;
        loss = bet;
      } 
       
      else if (numCards.length == 1 && playerValue == 21 && numCards[h] == 2 && !dealerBJ) {
        win = bet * 3 / 2;  
        loss = 0;
      }
       
      else if (playerValue > dealerValue || dealerValue > 21){
        win = bet;
        loss = 0;
      }
       
      else if (playerValue == dealerValue){
        win = 0;
        loss = 0;
      }
       
      else{
        win = 0;
        loss = bet;
      }

      if (doubled[h]){
        win *= 2;
        loss *= 2;
      } 
      totalWin += win;
      totalLoss += loss;
    }
  }

   
  function getPlayerValues(uint8[] cards, uint8[] numCards, uint8[] pSplits) constant internal returns(uint8[5] playerValues) {
    uint8 cardIndex;
    uint8 splitIndex;
    (cardIndex, splitIndex, playerValues) = playHand(0, 0, 0, playerValues, cards, numCards, pSplits);
  }

   
  function playHand(uint8 hIndex, uint8 cIndex, uint8 sIndex, uint8[5] playerValues, uint8[] cards, uint8[] numCards, uint8[] pSplits) constant internal returns(uint8, uint8, uint8[5]) {
    playerValues[hIndex] = cardValues[cards[cIndex] % 13];
    cIndex = cIndex < 4 ? cIndex + 2 : cIndex + 1;
    while (sIndex < pSplits.length && pSplits[sIndex] == hIndex) {
      sIndex++;
      (cIndex, sIndex, playerValues) = playHand(sIndex, cIndex, sIndex, playerValues, cards, numCards, pSplits);
    }
    uint8 numAces = playerValues[hIndex] == 11 ? 1 : 0;
    uint8 card;
    for (uint8 i = 1; i < numCards[hIndex]; i++) {
      card = cards[cIndex] % 13;
      playerValues[hIndex] += cardValues[card];
      if (card == 0) numAces++;
      cIndex = cIndex < 4 ? cIndex + 2 : cIndex + 1;
    }
    while (numAces > 0 && playerValues[hIndex] > 21) {
      playerValues[hIndex] -= 10;
      numAces--;
    }
    return (cIndex, sIndex, playerValues);
  }



   
  function getDealerValue(uint8[] cards, uint8 numCards) constant internal returns(uint8 dealerValue, bool bj) {

     
    uint8 card = cards[1] % 13;
    uint8 card2 = cards[3] % 13;
    dealerValue = cardValues[card] + cardValues[card2];
    uint8 numAces;
    if (card == 0) numAces++;
    if (card2 == 0) numAces++;
    if (dealerValue > 21) {  
      dealerValue -= 10;
      numAces--;
    } else if (dealerValue == 21) {
      return (21, true);
    }
     
    uint8 i;
    while (dealerValue < 17) {
      card = cards[numCards + i + 2] % 13;
      dealerValue += cardValues[card];
      if (card == 0) numAces++;
      if (dealerValue > 21 && numAces > 0) {
        dealerValue -= 10;
        numAces--;
      }
      i++;
    }
  }

   
  function sum(uint8[] numbers) constant internal returns(uint8 s) {
    for (uint i = 0; i < numbers.length; i++) {
      s += numbers[i];
    }
  }

}