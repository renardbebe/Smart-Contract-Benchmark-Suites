 

pragma solidity ^0.4.18;


 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


contract AddressWarsBeta {

   
   


   
  address public dev;
  uint256 constant devTax = 2;  

   
   
   
   
  uint256 constant enlistingFee = 0;
  uint256 constant wageringFee = 0;

   

   
   
   
   
   
   
  uint256 constant CLAIM_LIMIT = 10;

   
   
   
   
   
   
   
   
   
  uint256 constant MAX_UNIQUE_CARDS_PER_ADDRESS = 8;


   
   


   
   
   
  uint256 private _seed;

   
   
   
   
   
   
   
  enum TYPE { NORMAL, FIRE, WATER, NATURE }
  uint256[] private typeChances = [ 6, 7, 7, 7 ];
  uint256 constant typeSum = 27;

   
   
   
   
   
   
   
   
   
   
   
   
   
  enum MODIFIER {
    NONE,
    ALL_ATT, ALL_DEF, ALL_ATT_DEF,
    V_ATT, V_DEF,
    V_SWAP,
    R_V,
    A_I
  }
  uint256[] private modifierChances = [
    55,
    5, 6, 1,
    12, 14,
    3,
    7,
    4
  ];
  uint256 constant modifierSum = 107;

   
   
   
   
   
   
   
   
   
   
   
   
  uint256 constant cardBonusMinimum = 1;
  uint256[] private modifierAttBonusChances = [ 2, 5, 8, 7, 3, 2, 1, 1 ];  
  uint256 constant modifierAttBonusSum = 29;
  uint256[] private modifierDefBonusChances = [ 2, 3, 6, 8, 6, 5, 3, 2, 1, 1 ];   
  uint256 constant modifierDefBonusSum = 37;

   
   
   
   
   
   
  uint256 constant cardAttackMinimum = 10;
  uint256[] private cardAttackChances = [ 2, 2, 3, 5, 8, 9, 15, 17, 13, 11, 6, 5, 3, 2, 1, 1 ];  
  uint256 constant cardAttackSum = 103;
  uint256 constant cardDefenceMinimum = 5;
  uint256[] private cardDefenceChances = [ 1, 1, 2, 3, 5, 6, 11, 15, 19, 14, 12, 11, 9, 8, 7, 6, 5, 4, 3, 2, 2, 2, 2, 1, 1, 1 ];  
  uint256 constant cardDefenceSum = 153;


   
   


   
  mapping (address => bool) _exists;
  mapping (address => uint256) _indexOf;
  mapping (address => address[]) _ownersOf;
  mapping (address => uint256[]) _ownersClaimPriceOf;
  struct AddressCard {
      address _cardAddress;
      uint8 _cardType;
      uint8 _cardModifier;
      uint8 _modifierPrimarayVal;
      uint8 _modifierSecondaryVal;
      uint8 _attack;
      uint8 _defence;
      uint8 _claimed;
      uint8 _forClaim;
      uint256 _lowestPrice;
      address _claimContender;
  }
  AddressCard[] private _addressCards;

   
  mapping (address => uint256) _balanceOf;
  mapping (address => address[]) _cardsOf;


   
   


  event AddressDidEnlist(
    address enlistedAddress);
  event AddressCardWasWagered(
    address addressCard, 
    address owner, 
    uint256 wagerAmount);
  event AddressCardWagerWasCancelled(
    address addressCard, 
    address owner);
  event AddressCardWasTransferred(
    address addressCard, 
    address fromAddress, 
    address toAddress);
  event ClaimAttempt(
    bool wasSuccessful, 
    address addressCard, 
    address claimer, 
    address claimContender, 
    address[3] claimerChoices, 
    address[3] claimContenderChoices, 
    uint256[3][2] allFinalAttackValues,
    uint256[3][2] allFinalDefenceValues);


   
   


   
  function AddressWarsBeta() public {

     
    dev = msg.sender;
     
    shuffleSeed(uint256(dev));

  }

   
   
   
   
   
   
   
  function enlist() public payable {

    require(cardAddressExists(msg.sender) == false);
    require(msg.value == enlistingFee);
    require(msg.sender == tx.origin);  
     

     
    uint256 tmpSeed = tmpShuffleSeed(_seed, uint256(msg.sender));
    uint256 tmpModulus;
     
     
     
     

     
     
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, typeSum);
    uint256 cardType = cumulativeIndexOf(typeChances, tmpModulus);

     
     
    uint256 adjustedModifierSum = modifierSum;
    if (cardType == uint256(TYPE.NORMAL)) {
       
      adjustedModifierSum -= modifierChances[modifierChances.length - 1];
       
      adjustedModifierSum -= modifierChances[modifierChances.length - 2];
    }
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, adjustedModifierSum);
    uint256 cardModifier = cumulativeIndexOf(modifierChances, tmpModulus);

     
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, cardAttackSum);
    uint256 cardAttack = cardAttackMinimum + cumulativeIndexOf(cardAttackChances, tmpModulus);
    (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, cardDefenceSum);
    uint256 cardDefence = cardDefenceMinimum + cumulativeIndexOf(cardDefenceChances, tmpModulus);

     
    uint256 primaryModifierVal = 0;
    uint256 secondaryModifierVal = 0;
    uint256 bonusAttackPenalty = 0;
    uint256 bonusDefencePenalty = 0;
     
    if (cardModifier == uint256(MODIFIER.ALL_ATT)) {  

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      primaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      bonusAttackPenalty = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
       
      bonusAttackPenalty *= 2;

    } else if (cardModifier == uint256(MODIFIER.ALL_DEF)) {  

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      primaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      bonusDefencePenalty = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
       
      bonusDefencePenalty *= 2;

    } else if (cardModifier == uint256(MODIFIER.ALL_ATT_DEF)) {  

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      primaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      bonusAttackPenalty = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
       
      bonusAttackPenalty *= 2;

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      secondaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      bonusDefencePenalty = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
       
      bonusDefencePenalty *= 2;

    } else if (cardModifier == uint256(MODIFIER.V_ATT)) {  

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, typeSum);
      primaryModifierVal = cumulativeIndexOf(typeChances, tmpModulus);

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      secondaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);
       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierAttBonusSum);
      bonusAttackPenalty = cardBonusMinimum + cumulativeIndexOf(modifierAttBonusChances, tmpModulus);

    } else if (cardModifier == uint256(MODIFIER.V_DEF)) {  

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, typeSum);
      primaryModifierVal = cumulativeIndexOf(typeChances, tmpModulus);

       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      secondaryModifierVal = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);
       
      (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, modifierDefBonusSum);
      bonusDefencePenalty = cardBonusMinimum + cumulativeIndexOf(modifierDefBonusChances, tmpModulus);

    }

     
    if (bonusAttackPenalty >= cardAttack) {
      cardAttack = 0;
    } else {
      cardAttack -= bonusAttackPenalty;
    }
    if (bonusDefencePenalty >= cardDefence) {
      cardDefence = 0;
    } else {
      cardDefence -= bonusDefencePenalty;
    }


     
    _exists[msg.sender] = true;
    _indexOf[msg.sender] = uint256(_addressCards.length);
    _ownersOf[msg.sender] = [ msg.sender ];
    _ownersClaimPriceOf[msg.sender] = [ uint256(0) ];
    _addressCards.push(AddressCard({
      _cardAddress: msg.sender,
      _cardType: uint8(cardType),
      _cardModifier: uint8(cardModifier),
      _modifierPrimarayVal: uint8(primaryModifierVal),
      _modifierSecondaryVal: uint8(secondaryModifierVal),
      _attack: uint8(cardAttack),
      _defence: uint8(cardDefence),
      _claimed: uint8(0),
      _forClaim: uint8(0),
      _lowestPrice: uint256(0),
      _claimContender: address(0)
    }));

     
    _cardsOf[msg.sender] = [ msg.sender ];

     
    _balanceOf[dev] = SafeMath.add(_balanceOf[dev], enlistingFee);

     
     
    _seed = tmpSeed;

     
    AddressDidEnlist(msg.sender);

  }

   
   
   
   
   
   
   
   
   
   
   
   
   
   
   
  function wagerCardForAmount(address cardAddress, uint256 amount) public payable {

    require(amount > 0);

    require(cardAddressExists(msg.sender));
    require(msg.value == wageringFee);

    uint256 firstMatchedIndex;
    bool isAlreadyWagered;
    (firstMatchedIndex, isAlreadyWagered, , , ) = getOwnerOfCardsCheapestWager(msg.sender, cardAddress);
     
     
     
    require(isAlreadyWagered == false);
     
    require(msg.sender == _ownersOf[cardAddress][firstMatchedIndex]);

    AddressCard memory addressCardForWager = _addressCards[_indexOf[cardAddress]];
    if (msg.sender == cardAddress) {
       
      require(addressCardForWager._claimed < CLAIM_LIMIT);
    }

     
    _ownersClaimPriceOf[cardAddress][firstMatchedIndex] = amount;

     
    updateCardStatistics(cardAddress);

     
    _balanceOf[dev] = SafeMath.add(_balanceOf[dev], wageringFee);

     
    AddressCardWasWagered(cardAddress, msg.sender, amount);

  }

  function cancelWagerOfCard(address cardAddress) public {

    require(cardAddressExists(msg.sender));

    uint256 firstMatchedIndex;
    bool isAlreadyWagered;
    (firstMatchedIndex, isAlreadyWagered, , , ) = getOwnerOfCardsCheapestWager(msg.sender, cardAddress);
     
     
     
    require(isAlreadyWagered);
     
    require(msg.sender == _ownersOf[cardAddress][firstMatchedIndex]);

     
    _ownersClaimPriceOf[cardAddress][firstMatchedIndex] = 0;

     
    updateCardStatistics(cardAddress);

     
    AddressCardWagerWasCancelled(cardAddress, msg.sender);

  }

   
   
   
   
   
   
   
   
  function attemptToClaimCard(address cardAddress, address[3] choices) public payable {

     
     

     
     
    address claimContender;
    uint256 claimContenderIndex;
    (claimContender, claimContenderIndex) = ownerCanClaimCard(msg.sender, cardAddress, choices, msg.value);

    address[3] memory opponentCardChoices = generateCardsFromClaimForOpponent(cardAddress, claimContender);

    uint256[3][2] memory allFinalAttackFigures;
    uint256[3][2] memory allFinalDefenceFigures;
    (allFinalAttackFigures, allFinalDefenceFigures) = calculateAdjustedFiguresForBattle(choices, opponentCardChoices);
     
     
     
     
     
     
     
     
     
     
    uint256[2] memory totalHits = [ uint256(0), uint256(0) ];
    for (uint256 i = 0; i < 3; i++) {
       
      totalHits[0] += (allFinalAttackFigures[1][i] > allFinalDefenceFigures[0][i] ? allFinalAttackFigures[1][i] - allFinalDefenceFigures[0][i] : 0);
       
      totalHits[1] += (allFinalAttackFigures[0][i] > allFinalDefenceFigures[1][i] ? allFinalAttackFigures[0][i] - allFinalDefenceFigures[1][i] : 0);
    }

     
     
     
     
    ClaimAttempt(
      totalHits[0] < totalHits[1],  
      cardAddress,
      msg.sender,
      claimContender,
      choices,
      opponentCardChoices,
      allFinalAttackFigures,
      allFinalDefenceFigures
      );

     
    uint256 tmpAmount;
    if (totalHits[0] == totalHits[1]) {  

       
      tmpAmount = SafeMath.div(SafeMath.mul(msg.value, devTax), 100);  
      _balanceOf[dev] = SafeMath.add(_balanceOf[dev], tmpAmount);
       
      _balanceOf[msg.sender] = SafeMath.add(_balanceOf[msg.sender], SafeMath.sub(msg.value, tmpAmount));  

    } else if (totalHits[0] > totalHits[1]) {  

       
      tmpAmount = SafeMath.div(SafeMath.mul(msg.value, devTax), 100);  
      _balanceOf[dev] = SafeMath.add(_balanceOf[dev], tmpAmount);
       
      _balanceOf[claimContender] = SafeMath.add(_balanceOf[claimContender], SafeMath.sub(msg.value, tmpAmount));  

    } else {  

       
      tmpAmount = SafeMath.div(SafeMath.mul(msg.value, devTax), 100);  
      _balanceOf[dev] = SafeMath.add(_balanceOf[dev], tmpAmount);
       
      _balanceOf[msg.sender] = SafeMath.add(_balanceOf[msg.sender], SafeMath.div(msg.value, 2));  
       
      _balanceOf[claimContender] = SafeMath.add(_balanceOf[claimContender], SafeMath.sub(SafeMath.div(msg.value, 2), tmpAmount));  

       
       
      _ownersClaimPriceOf[cardAddress][claimContenderIndex] = 0;
      transferCard(cardAddress, claimContender, msg.sender);

       
      updateCardStatistics(cardAddress);

    }

  }

  function transferCardTo(address cardAddress, address toAddress) public {

     
     
     
     
     
    transferCard(cardAddress, msg.sender, toAddress);

  }


   
   


  function withdrawAmount(uint256 amount) public {

    require(amount > 0);

    address sender = msg.sender;
    uint256 balance = _balanceOf[sender];
    
    require(amount <= balance);
     
    _balanceOf[sender] = SafeMath.sub(_balanceOf[sender], amount);
    sender.transfer(amount);

  }

  function withdrawAll() public {

    address sender = msg.sender;
    uint256 balance = _balanceOf[sender];

    require(balance > 0);
     
    _balanceOf[sender] = 0;
    sender.transfer(balance);

  }

  function getBalanceOfSender() public view returns (uint256) {
    return _balanceOf[msg.sender];
  }


   
   


  function tmpShuffleSeed(uint256 tmpSeed, uint256 mix) public view returns (uint256) {

     
    uint256 newTmpSeed = tmpSeed;
    uint256 currentTime = now;
    uint256 timeMix = currentTime + mix;
     
     
    newTmpSeed *= newTmpSeed;
     
    newTmpSeed += timeMix;
     
    newTmpSeed *= currentTime;
     
    newTmpSeed += mix;
     
    newTmpSeed *= timeMix;

    return newTmpSeed;

  }

  function shuffleSeed(uint256 mix) private {

     
    _seed = tmpShuffleSeed(_seed, mix);
  
  }

  function tmpQuerySeed(uint256 tmpSeed, uint256 modulus) public view returns (uint256 tmpShuffledSeed, uint256 result) {

    require(modulus > 0);

     
    uint256 response = tmpSeed % modulus;

     
    uint256 mix = response + 1;  
    mix *= modulus;
    mix += response;
    mix *= modulus;

     
    return (tmpShuffleSeed(tmpSeed, mix), response);

  }

  function querySeed(uint256 modulus) private returns (uint256) {

    require(modulus > 0);

    uint256 tmpSeed;
    uint256 response;
    (tmpSeed, response) = tmpQuerySeed(_seed, modulus);

     
    _seed = tmpSeed;

     
    return response;

  }

  function cumulativeIndexOf(uint256[] array, uint256 target) private pure returns (uint256) {

    bool hasFound = false;
    uint256 index;
    uint256 cumulativeTotal = 0;
    for (uint256 i = 0; i < array.length; i++) {
      cumulativeTotal += array[i];
      if (cumulativeTotal > target) {
        hasFound = true;
        index = i;
        break;
      }
    }

    require(hasFound);
    return index;

  }

  function cardAddressExists(address cardAddress) public view returns (bool) {
    return _exists[cardAddress];
  }

  function indexOfCardAddress(address cardAddress) public view returns (uint256) {
    require(cardAddressExists(cardAddress));
    return _indexOf[cardAddress];
  }

  function ownerCountOfCard(address owner, address cardAddress) public view returns (uint256) {

     
    require(cardAddressExists(owner));
    require(cardAddressExists(cardAddress));

     
    if (owner == cardAddress) {
      return 0;
    }

    uint256 ownerCount = 0;
    address[] memory owners = _ownersOf[cardAddress];
    for (uint256 i = 0; i < owners.length; i++) {
      if (owner == owners[i]) {
        ownerCount++;
      }
    }

    return ownerCount;

  }

  function ownerHasCard(address owner, address cardAddress) public view returns (bool doesOwn, uint256[] indexes) {

     
    require(cardAddressExists(owner));
    require(cardAddressExists(cardAddress));

    uint256[] memory ownerIndexes = new uint256[](ownerCountOfCard(owner, cardAddress));
     
    if (owner == cardAddress) {
      return (true, ownerIndexes);
    }

    if (ownerIndexes.length > 0) {
      uint256 currentIndex = 0;
      address[] memory owners = _ownersOf[cardAddress];
      for (uint256 i = 0; i < owners.length; i++) {
        if (owner == owners[i]) {
          ownerIndexes[currentIndex] = i;
          currentIndex++;
        }
      }
    }

     
     
    return (ownerIndexes.length > 0, ownerIndexes);

  }

  function ownerHasCardSimple(address owner, address cardAddress) private view returns (bool) {

    bool doesOwn;
    (doesOwn, ) = ownerHasCard(owner, cardAddress);
    return doesOwn;

  }

  function ownerCanClaimCard(address owner, address cardAddress, address[3] choices, uint256 amount) private view returns (address currentClaimContender, uint256 claimContenderIndex) {

     
    require(owner != cardAddress);
    require(cardAddressExists(owner));
    require(ownerHasCardSimple(owner, cardAddress) || _cardsOf[owner].length < MAX_UNIQUE_CARDS_PER_ADDRESS);


    uint256 cheapestIndex;
    bool canClaim;
    address claimContender;
    uint256 lowestClaimPrice;
    (cheapestIndex, canClaim, claimContender, lowestClaimPrice, ) = getCheapestCardWager(cardAddress);
     
    require(canClaim);
    require(amount == lowestClaimPrice);
     
    require(owner != claimContender);

     
    for (uint256 i = 0; i < choices.length; i++) {
      require(ownerHasCardSimple(owner, choices[i]));  
    }

     
     
    return (claimContender, cheapestIndex);

  }

  function generateCardsFromClaimForOpponent(address cardAddress, address opponentAddress) private returns (address[3]) {

    require(cardAddressExists(cardAddress));
    require(cardAddressExists(opponentAddress));
    require(ownerHasCardSimple(opponentAddress, cardAddress));

     
     
     
    address[] memory cardsOfOpponent = _cardsOf[opponentAddress];
    address[3] memory opponentCardChoices;
    uint256 tmpSeed = tmpShuffleSeed(_seed, uint256(opponentAddress));
    uint256 tmpModulus;
    uint256 indexOfClaimableCard;
    (tmpSeed, indexOfClaimableCard) = tmpQuerySeed(tmpSeed, 3);  
    for (uint256 i = 0; i < 3; i++) {
      if (i == indexOfClaimableCard) {
        opponentCardChoices[i] = cardAddress;
      } else {
        (tmpSeed, tmpModulus) = tmpQuerySeed(tmpSeed, cardsOfOpponent.length);
        opponentCardChoices[i] = cardsOfOpponent[tmpModulus];        
      }
    }

     
     
    _seed = tmpSeed;

    return opponentCardChoices;

  }

  function updateCardStatistics(address cardAddress) private {

    AddressCard storage addressCardClaimed = _addressCards[_indexOf[cardAddress]];
    address claimContender;
    uint256 lowestClaimPrice;
    uint256 wagerCount;
    ( , , claimContender, lowestClaimPrice, wagerCount) = getCheapestCardWager(cardAddress);
    addressCardClaimed._forClaim = uint8(wagerCount);
    addressCardClaimed._lowestPrice = lowestClaimPrice;
    addressCardClaimed._claimContender = claimContender;

  }

  function transferCard(address cardAddress, address fromAddress, address toAddress) private {

    require(toAddress != fromAddress);
    require(cardAddressExists(cardAddress));
    require(cardAddressExists(fromAddress));
    uint256 firstMatchedIndex;
    bool isWagered;
    (firstMatchedIndex, isWagered, , , ) = getOwnerOfCardsCheapestWager(fromAddress, cardAddress);
    require(isWagered == false);  

    require(cardAddressExists(toAddress));
    require(toAddress != cardAddress);  
    require(ownerHasCardSimple(toAddress, cardAddress) || _cardsOf[toAddress].length < MAX_UNIQUE_CARDS_PER_ADDRESS);

     
    if (!ownerHasCardSimple(toAddress, cardAddress)) {
      _cardsOf[toAddress].push(cardAddress);
    } 

     
     
     
    if (fromAddress == cardAddress) {  

      AddressCard storage addressCardClaimed = _addressCards[_indexOf[cardAddress]];
      require(addressCardClaimed._claimed < CLAIM_LIMIT);

       
      _ownersOf[cardAddress].push(toAddress);
      _ownersClaimPriceOf[cardAddress].push(uint256(0));

       
      addressCardClaimed._claimed = uint8(_ownersOf[cardAddress].length - 1);  

    } else {

       
      uint256 cardIndexOfSender = getCardIndexOfOwner(cardAddress, fromAddress);

       
      _ownersOf[cardAddress][firstMatchedIndex] = toAddress;

       
      if (!ownerHasCardSimple(fromAddress, cardAddress)) {

         
        for (uint256 i = cardIndexOfSender; i < _cardsOf[fromAddress].length - 1; i++) {
           
          _cardsOf[fromAddress][i] = _cardsOf[fromAddress][i + 1];
        }
         
        _cardsOf[fromAddress].length--;

      }

    }

     
    AddressCardWasTransferred(cardAddress, fromAddress, toAddress);

  }

  function calculateAdjustedFiguresForBattle(address[3] yourChoices, address[3] opponentsChoices) private view returns (uint256[3][2] allAdjustedAttackFigures, uint256[3][2] allAdjustedDefenceFigures) {

     
    AddressCard[3][2] memory allCards;
    uint256[3][2] memory allAttackFigures;
    uint256[3][2] memory allDefenceFigures;
    bool[2] memory allOfSameType = [ true, true ];
    uint256[2] memory cumulativeAttackBonuses = [ uint256(0), uint256(0) ];
    uint256[2] memory cumulativeDefenceBonuses = [ uint256(0), uint256(0) ];

    for (uint256 i = 0; i < 3; i++) {
       
      require(_exists[yourChoices[i]]);
      allCards[0][i] = _addressCards[_indexOf[yourChoices[i]]];
      allAttackFigures[0][i] = allCards[0][i]._attack;
      allDefenceFigures[0][i] = allCards[0][i]._defence;

       
      require(_exists[opponentsChoices[i]]);
      allCards[1][i] = _addressCards[_indexOf[opponentsChoices[i]]];
      allAttackFigures[1][i] = allCards[1][i]._attack;
      allDefenceFigures[1][i] = allCards[1][i]._defence;
    }

     
     
     

     
     
     
     
     
     
     
    for (i = 0; i < 3; i++) {

       
       
      if (i > 0 && allCards[0][i]._cardType != allCards[0][i - 1]._cardType) {
        allOfSameType[0] = false;
      }
       
      if (allCards[0][i]._cardModifier == uint256(MODIFIER.ALL_ATT)) {  
         
         
        cumulativeAttackBonuses[0] += allCards[0][i]._modifierPrimarayVal;
      } else if (allCards[0][i]._cardModifier == uint256(MODIFIER.ALL_DEF)) {  
         
         
        cumulativeDefenceBonuses[0] += allCards[0][i]._modifierPrimarayVal;
      } else if (allCards[0][i]._cardModifier == uint256(MODIFIER.ALL_ATT_DEF)) {  
         
         
         
        cumulativeAttackBonuses[0] += allCards[0][i]._modifierPrimarayVal;
        cumulativeDefenceBonuses[0] += allCards[0][i]._modifierSecondaryVal;
      }
      
       
      if (i > 0 && allCards[1][i]._cardType != allCards[1][i - 1]._cardType) {
        allOfSameType[1] = false;
      }
      if (allCards[1][i]._cardModifier == uint256(MODIFIER.ALL_ATT)) {
        cumulativeAttackBonuses[1] += allCards[1][i]._modifierPrimarayVal;
      } else if (allCards[1][i]._cardModifier == uint256(MODIFIER.ALL_DEF)) {
        cumulativeDefenceBonuses[1] += allCards[1][i]._modifierPrimarayVal;
      } else if (allCards[1][i]._cardModifier == uint256(MODIFIER.ALL_ATT_DEF)) {
        cumulativeAttackBonuses[1] += allCards[1][i]._modifierPrimarayVal;
        cumulativeDefenceBonuses[1] += allCards[1][i]._modifierSecondaryVal;
      }

    }
     
    if (!allOfSameType[0]) {
      cumulativeAttackBonuses[0] = 0;
      cumulativeDefenceBonuses[0] = 0;
    }
    if (!allOfSameType[1]) {
      cumulativeAttackBonuses[1] = 0;
      cumulativeDefenceBonuses[1] = 0;
    }
     
     
     
    for (i = 0; i < 3; i++) {
       
      allAttackFigures[0][i] += cumulativeAttackBonuses[0];
      allDefenceFigures[0][i] += cumulativeDefenceBonuses[0];

       
      allAttackFigures[1][i] += cumulativeAttackBonuses[1];
      allDefenceFigures[1][i] += cumulativeDefenceBonuses[1]; 
    }

     
     
     
     
     
     
    for (i = 0; i < 3; i++) {

       
      if (allCards[0][i]._cardModifier == uint256(MODIFIER.V_ATT)) {  
         
        if (allCards[1][i]._cardType == allCards[0][i]._modifierPrimarayVal) {
           
          allAttackFigures[0][i] += allCards[0][i]._modifierSecondaryVal;
        }
      } else if (allCards[0][i]._cardModifier == uint256(MODIFIER.V_DEF)) {  
         
        if (allCards[1][i]._cardType == allCards[0][i]._modifierPrimarayVal) {
           
          allDefenceFigures[0][i] += allCards[0][i]._modifierSecondaryVal;
        }
      }

       
      if (allCards[1][i]._cardModifier == uint256(MODIFIER.V_ATT)) {
        if (allCards[0][i]._cardType == allCards[1][i]._modifierPrimarayVal) {
          allAttackFigures[1][i] += allCards[1][i]._modifierSecondaryVal;
        }
      } else if (allCards[1][i]._cardModifier == uint256(MODIFIER.V_DEF)) {
        if (allCards[0][i]._cardType == allCards[1][i]._modifierPrimarayVal) {
          allDefenceFigures[1][i] += allCards[1][i]._modifierSecondaryVal;
        }
      }

    }

     
     
     
     
    for (i = 0; i < 3; i++) {

       
       
      if (allCards[1][i]._cardModifier != uint256(MODIFIER.R_V)) {
         
        if (
           
          (allCards[0][i]._cardType == uint256(TYPE.FIRE) && allCards[1][i]._cardType == uint256(TYPE.NATURE)) ||
           
          (allCards[0][i]._cardType == uint256(TYPE.WATER) && allCards[1][i]._cardType == uint256(TYPE.FIRE)) ||
           
          (allCards[0][i]._cardType == uint256(TYPE.NATURE) && allCards[1][i]._cardType == uint256(TYPE.WATER))
          ) {

           
          if (allCards[0][i]._cardModifier == uint256(MODIFIER.A_I)) {
            allAttackFigures[0][i] = SafeMath.div(SafeMath.mul(allAttackFigures[0][i], 3), 2);  
            allDefenceFigures[0][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[0][i], 3), 2);  
          } else {
            allAttackFigures[0][i] = SafeMath.div(SafeMath.mul(allAttackFigures[0][i], 5), 4);  
            allDefenceFigures[0][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[0][i], 5), 4);  
          }
        }
      }

       
      if (allCards[0][i]._cardModifier != uint256(MODIFIER.R_V)) {
        if (
          (allCards[1][i]._cardType == uint256(TYPE.FIRE) && allCards[0][i]._cardType == uint256(TYPE.NATURE)) ||
          (allCards[1][i]._cardType == uint256(TYPE.WATER) && allCards[0][i]._cardType == uint256(TYPE.FIRE)) ||
          (allCards[1][i]._cardType == uint256(TYPE.NATURE) && allCards[0][i]._cardType == uint256(TYPE.WATER))
          ) {
          if (allCards[1][i]._cardModifier == uint256(MODIFIER.A_I)) {
            allAttackFigures[1][i] = SafeMath.div(SafeMath.mul(allAttackFigures[1][i], 3), 2);  
            allDefenceFigures[1][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[1][i], 3), 2);  
          } else {
            allAttackFigures[1][i] = SafeMath.div(SafeMath.mul(allAttackFigures[1][i], 5), 4);  
            allDefenceFigures[1][i] = SafeMath.div(SafeMath.mul(allDefenceFigures[1][i], 5), 4);  
          }
        }
      }

    }

     
     
     
     
    uint256 tmp;
    for (i = 0; i < 3; i++) {

       
       
      if (allCards[1][i]._cardModifier == uint256(MODIFIER.V_SWAP)) {
        tmp = allAttackFigures[0][i];
        allAttackFigures[0][i] = allDefenceFigures[0][i];
        allDefenceFigures[0][i] = tmp;
      }
       
      if (allCards[0][i]._cardModifier == uint256(MODIFIER.V_SWAP)) {
        tmp = allAttackFigures[1][i];
        allAttackFigures[1][i] = allDefenceFigures[1][i];
        allDefenceFigures[1][i] = tmp;
      }

    }

     
    return (allAttackFigures, allDefenceFigures);

  }


   
   


  function getCard(address cardAddress) public view returns (uint256 cardIndex, uint256 cardType, uint256 cardModifier, uint256 cardModifierPrimaryVal, uint256 cardModifierSecondaryVal, uint256 attack, uint256 defence, uint256 claimed, uint256 forClaim, uint256 lowestPrice, address claimContender) {

    require(cardAddressExists(cardAddress));

    uint256 index = _indexOf[cardAddress];
    AddressCard memory addressCard = _addressCards[index];
    return (
        index,
        uint256(addressCard._cardType),
        uint256(addressCard._cardModifier),
        uint256(addressCard._modifierPrimarayVal),
        uint256(addressCard._modifierSecondaryVal),
        uint256(addressCard._attack),
        uint256(addressCard._defence),
        uint256(addressCard._claimed),
        uint256(addressCard._forClaim),
        uint256(addressCard._lowestPrice),
        address(addressCard._claimContender)
      );

  }

  function getCheapestCardWager(address cardAddress) public view returns (uint256 cheapestIndex, bool isClaimable, address claimContender, uint256 claimPrice, uint256 wagerCount) {

    require(cardAddressExists(cardAddress));

    uint256 cheapestSale = 0;
    uint256 indexOfCheapestSale = 0;
    uint256 totalWagers = 0;
    uint256[] memory allOwnersClaimPrice = _ownersClaimPriceOf[cardAddress];
    for (uint256 i = 0; i < allOwnersClaimPrice.length; i++) {
      uint256 priceAtIndex = allOwnersClaimPrice[i];
      if (priceAtIndex != 0) {
        totalWagers++;
        if (cheapestSale == 0 || priceAtIndex < cheapestSale) {
          cheapestSale = priceAtIndex;
          indexOfCheapestSale = i;
        }
      }
    }

    return (
        indexOfCheapestSale,
        (cheapestSale > 0),
        (cheapestSale > 0 ? _ownersOf[cardAddress][indexOfCheapestSale] : address(0)),
        cheapestSale,
        totalWagers
      );

  }

  function getOwnerOfCardsCheapestWager(address owner, address cardAddress) public view returns (uint256 cheapestIndex, bool isSelling, uint256 claimPrice, uint256 priceRank, uint256 outOf) {

    bool doesOwn;
    uint256[] memory indexes;
    (doesOwn, indexes) = ownerHasCard(owner, cardAddress);
    require(doesOwn);

    uint256[] memory allOwnersClaimPrice = _ownersClaimPriceOf[cardAddress];
    uint256 cheapestSale = 0;
    uint256 indexOfCheapestSale = 0;  
    if (indexes.length > 0) {
      indexOfCheapestSale = indexes[0];  
    } else {  
      cheapestSale = allOwnersClaimPrice[0];
    }

    for (uint256 i = 0; i < indexes.length; i++) {
      if (allOwnersClaimPrice[indexes[i]] != 0 && (cheapestSale == 0 || allOwnersClaimPrice[indexes[i]] < cheapestSale)) {
        cheapestSale = allOwnersClaimPrice[indexes[i]];
        indexOfCheapestSale = indexes[i];
      }
    }

    uint256 saleRank = 0;
    uint256 totalWagers = 0;
    if (cheapestSale > 0) {
      saleRank = 1;
      for (i = 0; i < allOwnersClaimPrice.length; i++) {
        if (allOwnersClaimPrice[i] != 0) {
          totalWagers++;
          if (allOwnersClaimPrice[i] < cheapestSale) {
            saleRank++;
          }
        }
      }
    }

    return (
        indexOfCheapestSale,
        (cheapestSale > 0),
        cheapestSale,
        saleRank,
        totalWagers
      );

  }

  function getCardIndexOfOwner(address cardAddress, address owner) public view returns (uint256) {

    require(cardAddressExists(cardAddress));
    require(cardAddressExists(owner));
    require(ownerHasCardSimple(owner, cardAddress));

    uint256 matchedIndex;
    address[] memory cardsOfOwner = _cardsOf[owner];
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      if (cardsOfOwner[i] == cardAddress) {
        matchedIndex = i;
        break;
      }
    }

    return matchedIndex;

  }
  
  function getTotalUniqueCards() public view returns (uint256) {
    return _addressCards.length;
  }
  
  function getAllCardsAddress() public view returns (bytes20[]) {

    bytes20[] memory allCardsAddress = new bytes20[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsAddress[i] = bytes20(addressCard._cardAddress);
    }
    return allCardsAddress;

  }

  function getAllCardsType() public view returns (bytes1[]) {

    bytes1[] memory allCardsType = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsType[i] = bytes1(addressCard._cardType);
    }
    return allCardsType;

  }

  function getAllCardsModifier() public view returns (bytes1[]) {

    bytes1[] memory allCardsModifier = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsModifier[i] = bytes1(addressCard._cardModifier);
    }
    return allCardsModifier;

  }

  function getAllCardsModifierPrimaryVal() public view returns (bytes1[]) {

    bytes1[] memory allCardsModifierPrimaryVal = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsModifierPrimaryVal[i] = bytes1(addressCard._modifierPrimarayVal);
    }
    return allCardsModifierPrimaryVal;

  }

  function getAllCardsModifierSecondaryVal() public view returns (bytes1[]) {

    bytes1[] memory allCardsModifierSecondaryVal = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsModifierSecondaryVal[i] = bytes1(addressCard._modifierSecondaryVal);
    }
    return allCardsModifierSecondaryVal;

  }

  function getAllCardsAttack() public view returns (bytes1[]) {

    bytes1[] memory allCardsAttack = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsAttack[i] = bytes1(addressCard._attack);
    }
    return allCardsAttack;

  }

  function getAllCardsDefence() public view returns (bytes1[]) {

    bytes1[] memory allCardsDefence = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsDefence[i] = bytes1(addressCard._defence);
    }
    return allCardsDefence;

  }

  function getAllCardsClaimed() public view returns (bytes1[]) {

    bytes1[] memory allCardsClaimed = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsClaimed[i] = bytes1(addressCard._claimed);
    }
    return allCardsClaimed;

  }

  function getAllCardsForClaim() public view returns (bytes1[]) {

    bytes1[] memory allCardsForClaim = new bytes1[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsForClaim[i] = bytes1(addressCard._forClaim);
    }
    return allCardsForClaim;

  }

  function getAllCardsLowestPrice() public view returns (bytes32[]) {

    bytes32[] memory allCardsLowestPrice = new bytes32[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsLowestPrice[i] = bytes32(addressCard._lowestPrice);
    }
    return allCardsLowestPrice;

  }

  function getAllCardsClaimContender() public view returns (bytes4[]) {

     
    bytes4[] memory allCardsClaimContender = new bytes4[](_addressCards.length);
    for (uint256 i = 0; i < _addressCards.length; i++) {
      AddressCard memory addressCard = _addressCards[i];
      allCardsClaimContender[i] = bytes4(_indexOf[addressCard._claimContender]);
    }
    return allCardsClaimContender;

  }

  function getAllOwnersOfCard(address cardAddress) public view returns (bytes4[]) {
    
    require(cardAddressExists(cardAddress));

     
    address[] memory ownersOfCardAddress = _ownersOf[cardAddress];
    bytes4[] memory allOwners = new bytes4[](ownersOfCardAddress.length);
    for (uint256 i = 0; i < ownersOfCardAddress.length; i++) {
      allOwners[i] = bytes4(_indexOf[ownersOfCardAddress[i]]);
    }
    return allOwners;

  }

  function getAllOwnersClaimPriceOfCard(address cardAddress) public view returns (bytes32[]) {
    
    require(cardAddressExists(cardAddress));

    uint256[] memory ownersClaimPriceOfCardAddress = _ownersClaimPriceOf[cardAddress];
    bytes32[] memory allOwnersClaimPrice = new bytes32[](ownersClaimPriceOfCardAddress.length);
    for (uint256 i = 0; i < ownersClaimPriceOfCardAddress.length; i++) {
      allOwnersClaimPrice[i] = bytes32(ownersClaimPriceOfCardAddress[i]);
    }
    return allOwnersClaimPrice;

  }

  function getAllCardAddressesOfOwner(address owner) public view returns (bytes4[]) {
    
    require(cardAddressExists(owner));

     
    address[] memory cardsOfOwner = _cardsOf[owner];
    bytes4[] memory allCardAddresses = new bytes4[](cardsOfOwner.length);
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      allCardAddresses[i] = bytes4(_indexOf[cardsOfOwner[i]]);
    }
    return allCardAddresses;

  }

  function getAllCardAddressesCountOfOwner(address owner) public view returns (bytes1[]) {
    
    require(cardAddressExists(owner));

    address[] memory cardsOfOwner = _cardsOf[owner];
    bytes1[] memory allCardAddressesCount = new bytes1[](cardsOfOwner.length);
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      allCardAddressesCount[i] = bytes1(ownerCountOfCard(owner, cardsOfOwner[i]));
    }
    return allCardAddressesCount;

  }

  function getAllCardAddressesPriceOfOwner(address owner) public view returns (bytes32[]) {
    
    require(cardAddressExists(owner));

    address[] memory cardsOfOwner = _cardsOf[owner];
    bytes32[] memory allCardAddressesPrice = new bytes32[](cardsOfOwner.length);
    for (uint256 i = 0; i < cardsOfOwner.length; i++) {
      uint256 price;
      ( , , price, , ) = getOwnerOfCardsCheapestWager(owner, cardsOfOwner[i]);
      allCardAddressesPrice[i] = bytes32(price);
    }
    return allCardAddressesPrice;

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