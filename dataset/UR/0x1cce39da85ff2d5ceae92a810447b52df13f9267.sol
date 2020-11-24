 

 
pragma solidity ^0.4.10;

contract owned {
  address public owner; 
  modifier onlyOwner {
      if (msg.sender != owner)
          throw;
      _;
  }
  function owned() { owner = msg.sender; }
  function changeOwner(address newOwner) onlyOwner{
    owner = newOwner;
  }
}

contract mortal is owned{
  function close() onlyOwner {
        selfdestruct(owner);
    }
}
contract blackjack is mortal {
  struct Game {
     
    uint id;
     
    bytes32 deck;
     
    bytes32 seed;
     
    address player;
     
    uint bet;
     
    uint start;
  }

   
  uint8[13] cardValues = [11, 2, 3, 4, 5, 6, 7, 8, 9, 10, 10, 10, 10];

   
  mapping(uint => Game) games;
   
  uint public minimumBet;
   
  uint public maximumBet;
   
  address public signer;
  
   
  event NewGame(uint indexed id, bytes32 deck, bytes32 srvSeed, bytes32 cSeed, address player, uint bet);
   
  event Result(uint indexed id, address player, uint win);
   
  event Error(uint errorCode);

   
  function blackjack(uint minBet, uint maxBet, address signerAddress) payable{
    minimumBet = minBet;
    maximumBet = maxBet;
    signer = signerAddress;
  }

   
  function initGame(uint id, bytes32 deck, bytes32 srvSeed, bytes32 cSeed) payable {
     
    if (msg.value < minimumBet || msg.value > maximumBet) throw;
     
    if (msg.value * 3 > address(this).balance) throw;
    _initGame(id, deck, srvSeed, cSeed, msg.value);
  }

   
  function stand(uint gameId, uint8[] deck, bytes32 seed, uint8 numCards, uint8 v, bytes32 r, bytes32 s) {
    uint win = _stand(gameId,deck,seed,numCards,v,r,s, true);
  }
  
   
  function standAndRebet(uint oldGameId, uint8[] oldDeck, bytes32 oldSeed, uint8 numCards, uint8 v, bytes32 r, bytes32 s, uint newGameId, bytes32 newDeck, bytes32 newSrvSeed, bytes32 newCSeed){
    uint win = _stand(oldGameId,oldDeck,oldSeed,numCards,v,r,s, false);
    uint bet = games[oldGameId].bet;
    if(win >= bet){
      _initGame(newGameId, newDeck, newSrvSeed, newCSeed, bet);
      win-=bet;
    }
    if(win>0 && !msg.sender.send(win)){ 
      throw;
    }
  }
  
   
  function _initGame(uint id, bytes32 deck, bytes32 srvSeed, bytes32 cSeed, uint bet) internal{
     
    if (games[id].player != 0x0) throw;
    games[id] = Game(id, deck, srvSeed, msg.sender, bet, now);
    NewGame(id, deck, srvSeed, cSeed, msg.sender, bet);
  }
  
   
  function _stand(uint gameId, uint8[] deck, bytes32 seed, uint8 numCards, uint8 v, bytes32 r, bytes32 s, bool payout) internal returns(uint win){
    Game game = games[gameId];
    uint start = game.start;
    game.start = 0;  
    if(msg.sender!=game.player){
      Error(1);
      return 0;
    }
    if(!checkDeck(gameId, deck, seed)){
      Error(2);
      return 0;
    }
    if(!checkNumCards(gameId, numCards, v, r, s)){
      Error(3);
      return 0;
    }
    if(start + 1 hours < now){
      Error(4);
      return 0;
    }
    
    win = determineOutcome(gameId, deck, numCards);
    if (payout && win > 0 && !msg.sender.send(win)){
      Error(5);
      game.start = start;
      return 0;
    }
    Result(gameId, msg.sender, win);
  }
  
   
  function checkDeck(uint gameId, uint8[] deck, bytes32 seed) constant returns (bool correct){
    if(sha3(seed) != games[gameId].seed) return false;
    if(sha3(convertToBytes(deck), seed) != games[gameId].deck) return false;
    return true;
  }
  
  function convertToBytes(uint8[] byteArray) returns (bytes b){
    b = new bytes(byteArray.length);
    for(uint8 i = 0; i < byteArray.length; i++)
      b[i] = byte(byteArray[i]);
  }
  
   
  function checkNumCards(uint gameId, uint8 numCards, uint8 v, bytes32 r, bytes32 s) constant returns (bool correct){
    bytes32 msgHash = sha3(gameId,numCards);
    return ecrecover(msgHash, v, r, s) == signer;
  }

   
  function determineOutcome(uint gameId, uint8[] cards, uint8 numCards) constant returns(uint win) {
    uint8 playerValue = getPlayerValue(cards, numCards);
     
    if (playerValue > 21) return 0;

    var (dealerValue, dealerBJ) = getDealerValue(cards, numCards);

     
    if (playerValue == 21 && numCards == 2 && !dealerBJ){  
      if(isSuited(cards[0], cards[2]))
        return games[gameId].bet * 3;  
      else
        return games[gameId].bet * 5 / 2; 
    }
    else if(playerValue == 21 && numCards == 5)  
      return games[gameId].bet * 2;
    else if (playerValue > dealerValue || dealerValue > 21)
      return games[gameId].bet * 2;
     
    else if (playerValue == dealerValue)
      return games[gameId].bet;
     
    else
      return 0;

  }

   
  function getPlayerValue(uint8[] cards, uint8 numCards) constant internal returns(uint8 playerValue) {
     
     
    uint8 numAces;
    uint8 card;
    for (uint8 i = 0; i < numCards + 2; i++) {
      if (i != 1 && i != 3) {  
        card = cards[i] %13;
        playerValue += cardValues[card];
        if (card == 0) numAces++;
      }

    }
    while (numAces > 0 && playerValue > 21) {
      playerValue -= 10;
      numAces--;
    }
  }


   
  function getDealerValue(uint8[] cards, uint8 numCards) constant internal returns(uint8 dealerValue, bool bj) {
    
     
    uint8 card  = cards[1] % 13;
    uint8 card2 = cards[3] % 13;
    dealerValue = cardValues[card] + cardValues[card2];
    uint8 numAces;
    if (card == 0) numAces++;
    if (card2 == 0) numAces++;
    if (dealerValue > 21) {  
      dealerValue -= 10;
      numAces--;
    }
    else if(dealerValue==21){
      return (21, true);
    }
     
    uint8 i;
    while (dealerValue < 17) {
      card = cards[numCards + i + 2] % 13 ;
      dealerValue += cardValues[card];
      if (card == 0) numAces++;
      if (dealerValue > 21 && numAces > 0) {
        dealerValue -= 10;
        numAces--;
      }
      i++;
    }
  }
  
   
  function isSuited(uint8 card1, uint8 card2) internal returns(bool){
    return card1/13 == card2/13;
  }
  
   
  function() payable onlyOwner{
  }
  
   
  function withdraw(uint amount) onlyOwner{
    if(amount < address(this).balance)
      if(!owner.send(amount))
        Error(6);
  }
  
   
  function setSigner(address signerAddress) onlyOwner{
    signer = signerAddress;
  }
  
   
  function setMinimumBet(uint newMin) onlyOwner{
    minimumBet = newMin;
  }
  
   
  function setMaximumBet(uint newMax) onlyOwner{
    minimumBet = newMax;
  }
}