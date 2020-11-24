 

 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



 
contract Ownable {
  address public owner;

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

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 
contract Destructible is Ownable {
   
  function destroy() public onlyOwner {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) public onlyOwner {
    selfdestruct(_recipient);
  }
}

 

contract DragonKingConfig is Ownable {

  struct PurchaseRequirement {
    address[] tokens;
    uint256[] amounts;
  }

   
  ERC20 public giftToken;
   
  uint256 public giftTokenAmount;
   
  PurchaseRequirement[30] purchaseRequirements; 
   
  uint128[] public costs;
   
  uint128[] public values;
   
  uint8 fee;
   
  uint16 public maxCharacters;
   
  uint256 public eruptionThreshold;
   
  uint256 public castleLootDistributionThreshold;
   
  uint8 public percentageToKill;
   
  uint256 public constant CooldownThreshold = 1 days;
   
  uint8 public fightFactor;

   
  uint256 public teleportPrice;
   
  uint256 public protectionPrice;
   
  uint256 public luckThreshold;

  function hasEnoughTokensToPurchase(address buyer, uint8 characterType) external returns (bool canBuy) {
    for (uint256 i = 0; i < purchaseRequirements[characterType].tokens.length; i++) {
      if (ERC20(purchaseRequirements[characterType].tokens[i]).balanceOf(buyer) < purchaseRequirements[characterType].amounts[i]) {
        return false;
      }
    }
    return true;
  }


  function getPurchaseRequirements(uint8 characterType) view external returns (address[] tokens, uint256[] amounts) {
    tokens = purchaseRequirements[characterType].tokens;
    amounts = purchaseRequirements[characterType].amounts;
  }


}


contract DragonKing is Destructible {

   
  modifier onlyUser() {
    require(msg.sender == tx.origin, 
            "contracts cannot execute this method"
           );
    _;
  }


  struct Character {
    uint8 characterType;
    uint128 value;
    address owner;
    uint64 purchaseTimestamp;
    uint8 fightCount;
  }

  DragonKingConfig public config;

   
  ERC20 neverdieToken;
   
  ERC20 teleportToken;
   
  ERC20 luckToken;
   
  ERC20 sklToken;
   
  ERC20 xperToken;
  

   
  uint32[] public ids;
   
  uint32 public nextId;
   
  uint16 public constant INVALID_CHARACTER_INDEX = ~uint16(0);

   
  uint128 public castleTreasury;
   
  uint8 public luckRounds = 2;
   
  uint32 public oldest;
   
  mapping(uint32 => Character) characters;
   
  mapping(uint32 => bool) teleported;

   
  uint32 constant public noKing = ~uint32(0);

   
  uint16 public numCharacters;
   
  mapping(uint8 => uint16) public numCharactersXType;

   
  uint256 public lastEruptionTimestamp;
   
  mapping(uint32 => uint256) public lastCastleLootDistributionTimestamp;

   
  uint8 public constant DRAGON_MIN_TYPE = 0;
  uint8 public constant DRAGON_MAX_TYPE = 5;

  uint8 public constant KNIGHT_MIN_TYPE = 6;
  uint8 public constant KNIGHT_MAX_TYPE = 11;

  uint8 public constant BALLOON_MIN_TYPE = 12;
  uint8 public constant BALLOON_MAX_TYPE = 14;

  uint8 public constant WIZARD_MIN_TYPE = 15;
  uint8 public constant WIZARD_MAX_TYPE = 20;

  uint8 public constant ARCHER_MIN_TYPE = 21;
  uint8 public constant ARCHER_MAX_TYPE = 26;

  uint8 public constant NUMBER_OF_LEVELS = 6;

  uint8 public constant INVALID_CHARACTER_TYPE = 27;

     
  mapping(uint32 => uint) public cooldown;

     
  mapping(uint32 => uint8) public protection;

   

   
  event NewPurchase(address player, uint8 characterType, uint16 amount, uint32 startId);
   
  event NewExit(address player, uint256 totalBalance, uint32[] removedCharacters);
   
  event NewEruption(uint32[] hitCharacters, uint128 value, uint128 gasCost);
   
  event NewSell(uint32 characterId, address player, uint256 value);
   
  event NewFight(uint32 winnerID, uint32 loserID, uint256 value, uint16 probability, uint16 dice);
   
  event NewTeleport(uint32 characterId);
   
  event NewProtection(uint32 characterId, uint8 lifes);
   
  event NewDistributionCastleLoot(uint128 castleLoot, uint32 characterId, uint128 luckFactor);

   
  constructor(address tptAddress, address ndcAddress, address sklAddress, address xperAddress, address luckAddress, address _configAddress) public {
    nextId = 1;
    teleportToken = ERC20(tptAddress);
    neverdieToken = ERC20(ndcAddress);
    sklToken = ERC20(sklAddress);
    xperToken = ERC20(xperAddress);
    luckToken = ERC20(luckAddress);
    config = DragonKingConfig(_configAddress);
  }

   
  function giftCharacter(address receiver, uint8 characterType) payable public onlyUser {
    _addCharacters(receiver, characterType);
    assert(config.giftToken().transfer(receiver, config.giftTokenAmount()));
  }

   
  function addCharacters(uint8 characterType) payable public onlyUser {
    _addCharacters(msg.sender, characterType);
  }

  function _addCharacters(address receiver, uint8 characterType) internal {
    uint16 amount = uint16(msg.value / config.costs(characterType));
    require(
      amount > 0,
      "insufficient amount of ether to purchase a given type of character");
    uint16 nchars = numCharacters;
    require(
      config.hasEnoughTokensToPurchase(receiver, characterType),
      "insufficinet amount of tokens to purchase a given type of character"
    );
    if (characterType >= INVALID_CHARACTER_TYPE || msg.value < config.costs(characterType) || nchars + amount > config.maxCharacters()) revert();
    uint32 nid = nextId;
     
    if (characterType <= DRAGON_MAX_TYPE) {
       
      if (oldest == 0 || oldest == noKing)
        oldest = nid;
      for (uint8 i = 0; i < amount; i++) {
        addCharacter(nid + i, nchars + i);
        characters[nid + i] = Character(characterType, config.values(characterType), receiver, uint64(now), 0);
      }
      numCharactersXType[characterType] += amount;
      numCharacters += amount;
    }
    else {
       
      for (uint8 j = 0; j < amount; j++) {
        characters[nid + j] = Character(characterType, config.values(characterType), receiver, uint64(now), 0);
      }
    }
    nextId = nid + amount;
    emit NewPurchase(receiver, characterType, amount, nid);
  }



   
  function addCharacter(uint32 nId, uint16 nchars) internal {
    if (nchars < ids.length)
      ids[nchars] = nId;
    else
      ids.push(nId);
  }

   
  function exit() public {
    uint32[] memory removed = new uint32[](50);
    uint8 count;
    uint32 lastId;
    uint playerBalance;
    uint16 nchars = numCharacters;
    for (uint16 i = 0; i < nchars; i++) {
      if (characters[ids[i]].owner == msg.sender 
          && characters[ids[i]].purchaseTimestamp + 1 days < now
          && (characters[ids[i]].characterType < BALLOON_MIN_TYPE || characters[ids[i]].characterType > BALLOON_MAX_TYPE)) {
         
        while (nchars > 0 
            && characters[ids[nchars - 1]].owner == msg.sender 
            && characters[ids[nchars - 1]].purchaseTimestamp + 1 days < now
            && (characters[ids[i]].characterType < BALLOON_MIN_TYPE || characters[ids[i]].characterType > BALLOON_MAX_TYPE)) {
          nchars--;
          lastId = ids[nchars];
          numCharactersXType[characters[lastId].characterType]--;
          playerBalance += characters[lastId].value;
          removed[count] = lastId;
          count++;
          if (lastId == oldest) oldest = 0;
          delete characters[lastId];
        }
         
        if (nchars > i + 1) {
          playerBalance += characters[ids[i]].value;
          removed[count] = ids[i];
          count++;
          nchars--;
          replaceCharacter(i, nchars);
        }
      }
    }
    numCharacters = nchars;
    emit NewExit(msg.sender, playerBalance, removed);  
    msg.sender.transfer(playerBalance);
    if (oldest == 0)
      findOldest();
  }

   
  function replaceCharacter(uint16 index, uint16 nchars) internal {
    uint32 characterId = ids[index];
    numCharactersXType[characters[characterId].characterType]--;
    if (characterId == oldest) oldest = 0;
    delete characters[characterId];
    ids[index] = ids[nchars];
    delete ids[nchars];
  }

   

  function triggerVolcanoEruption() public onlyUser {
    require(now >= lastEruptionTimestamp + config.eruptionThreshold(),
           "not enough time passed since last eruption");
    require(numCharacters > 0,
           "there are no characters in the game");
    lastEruptionTimestamp = now;
    uint128 pot;
    uint128 value;
    uint16 random;
    uint32 nextHitId;
    uint16 nchars = numCharacters;
    uint32 howmany = nchars * config.percentageToKill() / 100;
    uint128 neededGas = 80000 + 10000 * uint32(nchars);
    if(howmany == 0) howmany = 1; 
    uint32[] memory hitCharacters = new uint32[](howmany);
    bool[] memory alreadyHit = new bool[](nextId);
    uint16 i = 0;
    uint16 j = 0;
    while (i < howmany) {
      j++;
      random = uint16(generateRandomNumber(lastEruptionTimestamp + j) % nchars);
      nextHitId = ids[random];
      if (!alreadyHit[nextHitId]) {
        alreadyHit[nextHitId] = true;
        hitCharacters[i] = nextHitId;
        value = hitCharacter(random, nchars, 0);
        if (value > 0) {
          nchars--;
        }
        pot += value;
        i++;
      }
    }
    uint128 gasCost = uint128(neededGas * tx.gasprice);
    numCharacters = nchars;
    if (pot > gasCost){
      distribute(pot - gasCost);  
      emit NewEruption(hitCharacters, pot - gasCost, gasCost);
    }
    else
      emit NewEruption(hitCharacters, 0, gasCost);
  }

   
  function fight(uint32 characterID, uint16 characterIndex) public onlyUser {
    if (characterIndex >= numCharacters || characterID != ids[characterIndex])
      characterIndex = getCharacterIndex(characterID);
    Character storage character = characters[characterID];
    require(cooldown[characterID] + config.CooldownThreshold() <= now,
            "not enough time passed since the last fight of this character");
    require(character.owner == msg.sender,
            "only owner can initiate a fight for this character");

    uint8 ctype = character.characterType;
    require(ctype < BALLOON_MIN_TYPE || ctype > BALLOON_MAX_TYPE,
            "balloons cannot fight");

    uint16 adversaryIndex = getRandomAdversary(characterID, ctype);
    require(adversaryIndex != INVALID_CHARACTER_INDEX);
    uint32 adversaryID = ids[adversaryIndex];

    Character storage adversary = characters[adversaryID];
    uint128 value;
    uint16 base_probability;
    uint16 dice = uint16(generateRandomNumber(characterID) % 100);
    if (luckToken.balanceOf(msg.sender) >= config.luckThreshold()) {
      base_probability = uint16(generateRandomNumber(dice) % 100);
      if (base_probability < dice) {
        dice = base_probability;
      }
      base_probability = 0;
    }
    uint256 characterPower = sklToken.balanceOf(character.owner) / 10**15 + xperToken.balanceOf(character.owner);
    uint256 adversaryPower = sklToken.balanceOf(adversary.owner) / 10**15 + xperToken.balanceOf(adversary.owner);
    
    if (character.value == adversary.value) {
        base_probability = 50;
      if (characterPower > adversaryPower) {
        base_probability += uint16(100 / config.fightFactor());
      } else if (adversaryPower > characterPower) {
        base_probability -= uint16(100 / config.fightFactor());
      }
    } else if (character.value > adversary.value) {
      base_probability = 100;
      if (adversaryPower > characterPower) {
        base_probability -= uint16((100 * adversary.value) / character.value / config.fightFactor());
      }
    } else if (characterPower > adversaryPower) {
        base_probability += uint16((100 * character.value) / adversary.value / config.fightFactor());
    }
    
    if (characters[characterID].fightCount < 3) {
      characters[characterID].fightCount++;
    }
    
    if (dice >= base_probability) {
       
      if (adversary.characterType < BALLOON_MIN_TYPE || adversary.characterType > BALLOON_MAX_TYPE) {
        value = hitCharacter(characterIndex, numCharacters, adversary.characterType);
        if (value > 0) {
          numCharacters--;
        } else {
          cooldown[characterID] = now;
        }
        if (adversary.characterType >= ARCHER_MIN_TYPE && adversary.characterType <= ARCHER_MAX_TYPE) {
          castleTreasury += value;
        } else {
          adversary.value += value;
        }
        emit NewFight(adversaryID, characterID, value, base_probability, dice);
      } else {
        emit NewFight(adversaryID, characterID, 0, base_probability, dice);  
      }
    } else {
       
      cooldown[characterID] = now;
      value = hitCharacter(adversaryIndex, numCharacters, character.characterType);
      if (value > 0) {
        numCharacters--;
      }
      if (character.characterType >= ARCHER_MIN_TYPE && character.characterType <= ARCHER_MAX_TYPE) {
        castleTreasury += value;
      } else {
        character.value += value;
      }
      if (oldest == 0) findOldest();
      emit NewFight(characterID, adversaryID, value, base_probability, dice);
    }
  }

  
   
  function isValidAdversary(uint8 characterType, uint8 adversaryType) pure returns (bool) {
    if (characterType >= KNIGHT_MIN_TYPE && characterType <= KNIGHT_MAX_TYPE) {  
      return (adversaryType <= DRAGON_MAX_TYPE);
    } else if (characterType >= WIZARD_MIN_TYPE && characterType <= WIZARD_MAX_TYPE) {  
      return (adversaryType < BALLOON_MIN_TYPE || adversaryType > BALLOON_MAX_TYPE);
    } else if (characterType >= DRAGON_MIN_TYPE && characterType <= DRAGON_MAX_TYPE) {  
      return (adversaryType >= WIZARD_MIN_TYPE);
    } else if (characterType >= ARCHER_MIN_TYPE && characterType <= ARCHER_MAX_TYPE) {  
      return ((adversaryType >= BALLOON_MIN_TYPE && adversaryType <= BALLOON_MAX_TYPE)
             || (adversaryType >= KNIGHT_MIN_TYPE && adversaryType <= KNIGHT_MAX_TYPE));
 
    }
    return false;
  }

   
  function getRandomAdversary(uint256 nonce, uint8 characterType) internal view returns(uint16) {
    uint16 randomIndex = uint16(generateRandomNumber(nonce) % numCharacters);
     
    uint16 stepSize = numCharacters % 7 == 0 ? (numCharacters % 11 == 0 ? 13 : 11) : 7;
    uint16 i = randomIndex;
     
     
    do {
      if (isValidAdversary(characterType, characters[ids[i]].characterType) && characters[ids[i]].owner != msg.sender) {
        return i;
      }
      i = (i + stepSize) % numCharacters;
    } while (i != randomIndex);

    return INVALID_CHARACTER_INDEX;
  }


   
  function generateRandomNumber(uint256 nonce) internal view returns(uint) {
    return uint(keccak256(block.blockhash(block.number - 1), now, numCharacters, nonce));
  }

	 
  function hitCharacter(uint16 index, uint16 nchars, uint8 characterType) internal returns(uint128 characterValue) {
    uint32 id = ids[index];
    uint8 knockOffProtections = 1;
    if (characterType >= WIZARD_MIN_TYPE && characterType <= WIZARD_MAX_TYPE) {
      knockOffProtections = 2;
    }
    if (protection[id] >= knockOffProtections) {
      protection[id] = protection[id] - knockOffProtections;
      return 0;
    }
    characterValue = characters[ids[index]].value;
    nchars--;
    replaceCharacter(index, nchars);
  }

   
  function findOldest() public {
    uint32 newOldest = noKing;
    for (uint16 i = 0; i < numCharacters; i++) {
      if (ids[i] < newOldest && characters[ids[i]].characterType <= DRAGON_MAX_TYPE)
        newOldest = ids[i];
    }
    oldest = newOldest;
  }

   
  function distribute(uint128 totalAmount) internal {
    uint128 amount;
    castleTreasury += totalAmount / 20;  
    if (oldest == 0)
      findOldest();
    if (oldest != noKing) {
       
      characters[oldest].value += totalAmount / 10;
      amount  = totalAmount / 100 * 85;
    } else {
      amount  = totalAmount / 100 * 95;
    }
     
    uint128 valueSum;
    uint8 size = ARCHER_MAX_TYPE + 1;
    uint128[] memory shares = new uint128[](size);
    for (uint8 v = 0; v < size; v++) {
      if ((v < BALLOON_MIN_TYPE || v > BALLOON_MAX_TYPE) && numCharactersXType[v] > 0) {
           valueSum += config.values(v);
      }
    }
    for (uint8 m = 0; m < size; m++) {
      if ((v < BALLOON_MIN_TYPE || v > BALLOON_MAX_TYPE) && numCharactersXType[m] > 0) {
        shares[m] = amount * config.values(m) / valueSum / numCharactersXType[m];
      }
    }
    uint8 cType;
    for (uint16 i = 0; i < numCharacters; i++) {
      cType = characters[ids[i]].characterType;
      if (cType < BALLOON_MIN_TYPE || cType > BALLOON_MAX_TYPE)
        characters[ids[i]].value += shares[characters[ids[i]].characterType];
    }
  }

   
  function collectFees(uint128 amount) public onlyOwner {
    uint collectedFees = getFees();
    if (amount + 100 finney < collectedFees) {
      owner.transfer(amount);
    }
  }

   
  function withdraw() public onlyOwner {
    uint256 ndcBalance = neverdieToken.balanceOf(this);
    if(ndcBalance > 0)
      assert(neverdieToken.transfer(owner, ndcBalance));
    uint256 tptBalance = teleportToken.balanceOf(this);
    if(tptBalance > 0)
      assert(teleportToken.transfer(owner, tptBalance));
  }

   
  function payOut() public onlyOwner {
    for (uint16 i = 0; i < numCharacters; i++) {
      characters[ids[i]].owner.transfer(characters[ids[i]].value);
      delete characters[ids[i]];
    }
    delete ids;
    numCharacters = 0;
  }

   
  function stop() public onlyOwner {
    withdraw();
    payOut();
    destroy();
  }

  function generateLuckFactor(uint128 nonce) internal view returns(uint128 luckFactor) {
    uint128 f;
    luckFactor = 50;
    for(uint8 i = 0; i < luckRounds; i++){
      f = roll(uint128(generateRandomNumber(nonce+i*7)%1000));
      if(f < luckFactor) luckFactor = f;
    }
  }
  
  function roll(uint128 nonce) internal view returns(uint128) {
    uint128 sum = 0;
    uint128 inc = 1;
    for (uint128 i = 45; i >= 3; i--) {
      if (sum > nonce) {
          return i;
      }
      sum += inc;
      if (i != 35) {
          inc += 1;
      }
    }
    return 3;
  }
  
  function distributeCastleLootMulti(uint32[] characterIds) external onlyUser {
    require(characterIds.length <= 50);
    for(uint i = 0; i < characterIds.length; i++){
      distributeCastleLoot(characterIds[i]);
    }
  }

   
  function distributeCastleLoot(uint32 characterId) public onlyUser {
    require(castleTreasury > 0, "empty treasury");
    Character archer = characters[characterId];
    require(archer.characterType >= ARCHER_MIN_TYPE && archer.characterType <= ARCHER_MAX_TYPE, "only archers can access the castle treasury");
    if(lastCastleLootDistributionTimestamp[characterId] == 0) 
      require(now - archer.purchaseTimestamp >= config.castleLootDistributionThreshold(), 
            "not enough time has passed since the purchase");
    else 
      require(now >= lastCastleLootDistributionTimestamp[characterId] + config.castleLootDistributionThreshold(),
            "not enough time passed since the last castle loot distribution");
    require(archer.fightCount >= 3, "need to fight 3 times");
    lastCastleLootDistributionTimestamp[characterId] = now;
    archer.fightCount = 0;
    
    uint128 luckFactor = generateLuckFactor(uint128(generateRandomNumber(characterId) % 1000));
    if (luckFactor < 3) {
      luckFactor = 3;
    }
    assert(luckFactor <= 50);
    uint128 amount = castleTreasury * luckFactor / 100; 
    archer.value += amount;
    castleTreasury -= amount;
    emit NewDistributionCastleLoot(amount, characterId, luckFactor);

  }

   
  function sellCharacter(uint32 characterId, uint16 characterIndex) public onlyUser {
    if (characterIndex >= numCharacters || characterId != ids[characterIndex])
      characterIndex = getCharacterIndex(characterId);
    Character storage char = characters[characterId];
    require(msg.sender == char.owner,
            "only owners can sell their characters");
    require(char.characterType < BALLOON_MIN_TYPE || char.characterType > BALLOON_MAX_TYPE,
            "balloons are not sellable");
    require(char.purchaseTimestamp + 1 days < now,
            "character can be sold only 1 day after the purchase");
    uint128 val = char.value;
    numCharacters--;
    replaceCharacter(characterIndex, numCharacters);
    msg.sender.transfer(val);
    if (oldest == 0)
      findOldest();
    emit NewSell(characterId, msg.sender, val);
  }

   
  function receiveApproval(address sender, uint256 value, address tokenContract, bytes callData) public {
    require(tokenContract == address(teleportToken), "everything is paid with teleport tokens");
    bool forProtection = secondToUint32(callData) == 1 ? true : false;
    uint32 id;
    uint256 price;
    if (!forProtection) {
      id = toUint32(callData);
      price = config.teleportPrice();
      if (characters[id].characterType >= BALLOON_MIN_TYPE && characters[id].characterType <= WIZARD_MAX_TYPE) {
        price *= 2;
      }
      require(value >= price,
              "insufficinet amount of tokens to teleport this character");
      assert(teleportToken.transferFrom(sender, this, price));
      teleportCharacter(id);
    } else {
      id = toUint32(callData);
       
       
      uint8 cType = characters[id].characterType;
      require(characters[id].value == config.values(cType),
              "protection could be bought only before the first fight and before the first volcano eruption");

       
       

      uint256 lifePrice;
      uint8 max;
      if(cType <= KNIGHT_MAX_TYPE ){
        lifePrice = ((cType % NUMBER_OF_LEVELS) + 1) * config.protectionPrice();
        max = 3;
      } else if (cType >= BALLOON_MIN_TYPE && cType <= BALLOON_MAX_TYPE) {
        lifePrice = (((cType+3) % NUMBER_OF_LEVELS) + 1) * config.protectionPrice() * 2;
        max = 6;
      } else if (cType >= WIZARD_MIN_TYPE && cType <= WIZARD_MAX_TYPE) {
        lifePrice = (((cType+3) % NUMBER_OF_LEVELS) + 1) * config.protectionPrice() * 2;
        max = 3;
      } else if (cType >= ARCHER_MIN_TYPE && cType <= ARCHER_MAX_TYPE) {
        lifePrice = (((cType+3) % NUMBER_OF_LEVELS) + 1) * config.protectionPrice();
        max = 3;
      }

      price = 0;
      uint8 i = protection[id];
      for (i; i < max && value >= price + lifePrice * (i + 1); i++) {
        price += lifePrice * (i + 1);
      }
      assert(teleportToken.transferFrom(sender, this, price));
      protectCharacter(id, i);
    } 
  }

   
  function teleportCharacter(uint32 id) internal {
     
    require(teleported[id] == false,
           "already teleported");
    teleported[id] = true;
    Character storage character = characters[id];
    require(character.characterType > DRAGON_MAX_TYPE,
           "dragons do not need to be teleported");  
    addCharacter(id, numCharacters);
    numCharacters++;
    numCharactersXType[character.characterType]++;
    emit NewTeleport(id);
  }

   
  function protectCharacter(uint32 id, uint8 lifes) internal {
    protection[id] = lifes;
    emit NewProtection(id, lifes);
  }
  
   
  function setLuckRound(uint8 rounds) public onlyOwner{
    require(rounds >= 1 && rounds <= 100);
    luckRounds = rounds;
  }


   

   
  function getCharacter(uint32 characterId) public view returns(uint8, uint128, address) {
    return (characters[characterId].characterType, characters[characterId].value, characters[characterId].owner);
  }

   
  function getCharacterIndex(uint32 characterId) constant public returns(uint16) {
    for (uint16 i = 0; i < ids.length; i++) {
      if (ids[i] == characterId) {
        return i;
      }
    }
    revert();
  }

   
  function get10Characters(uint16 startIndex) constant public returns(uint32[10] characterIds, uint8[10] types, uint128[10] values, address[10] owners) {
    uint32 endIndex = startIndex + 10 > numCharacters ? numCharacters : startIndex + 10;
    uint8 j = 0;
    uint32 id;
    for (uint16 i = startIndex; i < endIndex; i++) {
      id = ids[i];
      characterIds[j] = id;
      types[j] = characters[id].characterType;
      values[j] = characters[id].value;
      owners[j] = characters[id].owner;
      j++;
    }

  }

   
  function getNumDragons() constant public returns(uint16 numDragons) {
    for (uint8 i = DRAGON_MIN_TYPE; i <= DRAGON_MAX_TYPE; i++)
      numDragons += numCharactersXType[i];
  }

   
  function getNumWizards() constant public returns(uint16 numWizards) {
    for (uint8 i = WIZARD_MIN_TYPE; i <= WIZARD_MAX_TYPE; i++)
      numWizards += numCharactersXType[i];
  }
   
  function getNumArchers() constant public returns(uint16 numArchers) {
    for (uint8 i = ARCHER_MIN_TYPE; i <= ARCHER_MAX_TYPE; i++)
      numArchers += numCharactersXType[i];
  }

   
  function getNumKnights() constant public returns(uint16 numKnights) {
    for (uint8 i = KNIGHT_MIN_TYPE; i <= KNIGHT_MAX_TYPE; i++)
      numKnights += numCharactersXType[i];
  }

   
  function getFees() constant public returns(uint) {
    uint reserved = castleTreasury;
    for (uint16 j = 0; j < numCharacters; j++)
      reserved += characters[ids[j]].value;
    return address(this).balance - reserved;
  }


   

   
  function toUint32(bytes b) internal pure returns(uint32) {
    bytes32 newB;
    assembly {
      newB: = mload(0xa0)
    }
    return uint32(newB);
  }
  
  function secondToUint32(bytes b) internal pure returns(uint32){
    bytes32 newB;
    assembly {
      newB: = mload(0xc0)
    }
    return uint32(newB);
  }
}