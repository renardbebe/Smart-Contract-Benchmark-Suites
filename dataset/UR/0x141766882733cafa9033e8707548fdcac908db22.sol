 

pragma solidity ^0.4.19;

 
contract Ownable {

  address public owner;

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract EjectableOwnable is Ownable {

     
    function removeOwnership() onlyOwner public {
        owner = 0x0;
    }

}

 
contract JointOwnable is Ownable {

  event AnotherOwnerAssigned(address indexed anotherOwner);

  address public anotherOwner1;
  address public anotherOwner2;

   
  modifier eitherOwner() {
    require(msg.sender == owner || msg.sender == anotherOwner1 || msg.sender == anotherOwner2);
    _;
  }

   
  function assignAnotherOwner1(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner1 = _anotherOwner;
  }

   
  function assignAnotherOwner2(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner2 = _anotherOwner;
  }

}

 
contract Pausable is Ownable {

  event Pause();
  event Unpause();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

   
  modifier whenPaused() {
    require(paused);
    _;
  }

   
  function pause() onlyOwner whenNotPaused public {
    paused = true;
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }

}

 
contract Destructible is Ownable {

  function Destructible() public payable { }

   
  function destroy() onlyOwner public {
    selfdestruct(owner);
  }

  function destroyAndSend(address _recipient) onlyOwner public {
    selfdestruct(_recipient);
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

 
contract PullPayment {

  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(this.balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    assert(payee.send(payment));
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }

}

 
contract ERC721 {

     
    event Transfer(address indexed from, address indexed to, uint tokenId);

     
     
     
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);

     
    function ownerOf(uint _tokenId) external view returns (address);
    function transfer(address _to, uint _tokenId) external;

}

contract DungeonStructs {

     
    struct Dungeon {

         

         
        uint32 creationTime;

         
         
        uint8 status;

         
         
         
         
         
        uint8 difficulty;

         
         
         
         
        uint16 capacity;

         
         
         
        uint32 floorNumber;

         
        uint32 floorCreationTime;

         
        uint128 rewards;

         
         
         
         
        uint seedGenes;

         
         
         
        uint floorGenes;

    }

     
    struct Hero {

         

         
        uint64 creationTime;

         
        uint64 cooldownStartTime;

         
        uint32 cooldownIndex;

         
         
         
        uint genes;

    }

}

 
contract DungeonToken is ERC721, DungeonStructs, Pausable, JointOwnable {

     
    uint public constant DUNGEON_CREATION_LIMIT = 1024;

     
    event Mint(address indexed owner, uint newTokenId, uint difficulty, uint capacity, uint seedGenes);

     
    event NewDungeonFloor(uint timestamp, uint indexed dungeonId, uint32 newFloorNumber, uint128 newRewards , uint newFloorGenes);

     
    event Transfer(address indexed from, address indexed to, uint tokenId);

     
    string public constant name = "Dungeon";

     
    string public constant symbol = "DUNG";

     
    Dungeon[] public dungeons;

     
    mapping(uint => address) tokenIndexToOwner;

     
    mapping(address => uint) ownershipTokenCount;

     
    mapping(address => uint[]) public ownerTokens;

     
    function totalSupply() public view returns (uint) {
        return dungeons.length;
    }

     
    function balanceOf(address _owner) public view returns (uint) {
        return ownershipTokenCount[_owner];
    }

     
    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }

     
    function ownerOf(uint _tokenId) external view returns (address) {
        require(tokenIndexToOwner[_tokenId] != address(0));

        return tokenIndexToOwner[_tokenId];
    }

     
    function _transfer(address _from, address _to, uint _tokenId) internal {
         
        ownershipTokenCount[_to]++;

         
        tokenIndexToOwner[_tokenId] = _to;

         
        ownerTokens[_to].push(_tokenId);

         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;

             
            uint[] storage fromTokens = ownerTokens[_from];
            bool iFound = false;

            for (uint i = 0; i < fromTokens.length - 1; i++) {
                if (iFound) {
                    fromTokens[i] = fromTokens[i + 1];
                } else if (fromTokens[i] == _tokenId) {
                    iFound = true;
                    fromTokens[i] = fromTokens[i + 1];
                }
            }

            fromTokens.length--;
        }

         
        Transfer(_from, _to, _tokenId);
    }

     
    function transfer(address _to, uint _tokenId) whenNotPaused external {
         
        require(_to != address(0));

         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
    function getOwnerTokens(address _owner) external view returns(uint[]) {
        return ownerTokens[_owner];
    }

     
    function createDungeon(uint _difficulty, uint _capacity, uint _seedGenes, uint _firstFloorGenes, address _owner) eitherOwner external returns (uint) {
         
        require(totalSupply() < DUNGEON_CREATION_LIMIT);

         
         
        dungeons.push(Dungeon(uint32(now), 0, uint8(_difficulty), uint16(_capacity), 0, 0, 0, _seedGenes, 0));

         
        uint newTokenId = dungeons.length - 1;

         
        Mint(_owner, newTokenId, _difficulty, _capacity, _seedGenes);

         
        addDungeonNewFloor(newTokenId, 0, _firstFloorGenes);

         
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }

     
    function setDungeonStatus(uint _id, uint _newStatus) eitherOwner tokenExists(_id) external {
        dungeons[_id].status = uint8(_newStatus);
    }

     
    function addDungeonRewards(uint _id, uint _additinalRewards) eitherOwner tokenExists(_id) external {
        dungeons[_id].rewards += uint128(_additinalRewards);
    }

     
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) eitherOwner tokenExists(_id) public {
        Dungeon storage dungeon = dungeons[_id];

        dungeon.floorNumber++;
        dungeon.floorCreationTime = uint32(now);
        dungeon.rewards = uint128(_newRewards);
        dungeon.floorGenes = _newFloorGenes;

         
        NewDungeonFloor(now, _id, dungeon.floorNumber, dungeon.rewards, dungeon.floorGenes);
    }


     

     
    modifier tokenExists(uint _tokenId) {
        require(_tokenId < totalSupply());
        _;
    }

}

 
contract HeroToken is ERC721, DungeonStructs, Pausable, JointOwnable {

     
    event Mint(address indexed owner, uint newTokenId, uint _genes);

     
    event Transfer(address indexed from, address indexed to, uint tokenId);

     
    string public constant name = "Hero";

     
    string public constant symbol = "HERO";

     
    Hero[] public heroes;

     
    mapping(uint => address) tokenIndexToOwner;

     
    mapping(address => uint) ownershipTokenCount;

     
    mapping(address => uint[]) public ownerTokens;

     
    function totalSupply() public view returns (uint) {
        return heroes.length;
    }

     
    function balanceOf(address _owner) public view returns (uint) {
        return ownershipTokenCount[_owner];
    }

     
    function _owns(address _claimant, uint _tokenId) internal view returns (bool) {
        return tokenIndexToOwner[_tokenId] == _claimant;
    }

     
    function ownerOf(uint _tokenId) external view returns (address) {
        require(tokenIndexToOwner[_tokenId] != address(0));

        return tokenIndexToOwner[_tokenId];
    }

     
    function _transfer(address _from, address _to, uint _tokenId) internal {
         
        ownershipTokenCount[_to]++;

         
        tokenIndexToOwner[_tokenId] = _to;

         
        ownerTokens[_to].push(_tokenId);

         
        if (_from != address(0)) {
            ownershipTokenCount[_from]--;

             
            uint[] storage fromTokens = ownerTokens[_from];
            bool iFound = false;

            for (uint i = 0; i < fromTokens.length - 1; i++) {
                if (iFound) {
                    fromTokens[i] = fromTokens[i + 1];
                } else if (fromTokens[i] == _tokenId) {
                    iFound = true;
                    fromTokens[i] = fromTokens[i + 1];
                }
            }

            fromTokens.length--;
        }

         
        Transfer(_from, _to, _tokenId);
    }

     
    function transfer(address _to, uint _tokenId) whenNotPaused external {
         
        require(_to != address(0));

         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
    function getOwnerTokens(address _owner) external view returns(uint[]) {
        return ownerTokens[_owner];
    }

     
    function createHero(uint _genes, address _owner) eitherOwner external returns (uint) {
         
         
        heroes.push(Hero(uint64(now), 0, 0, _genes));

         
        uint newTokenId = heroes.length - 1;

         
        Mint(_owner, newTokenId, _genes);

         
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }

     
    function setHeroGenes(uint _id, uint _newGenes) eitherOwner tokenExists(_id) external {
        heroes[_id].genes = _newGenes;
    }

     
    function triggerCooldown(uint _id) eitherOwner tokenExists(_id) external {
        Hero storage hero = heroes[_id];

        hero.cooldownStartTime = uint64(now);
        hero.cooldownIndex++;
    }


     

     
    modifier tokenExists(uint _tokenId) {
        require(_tokenId < totalSupply());
        _;
    }

}

 
contract ChallengeScienceInterface {

     
    function mixGenes(uint _floorGenes, uint _seedGenes) external returns (uint);

}

 
contract TrainingScienceInterface {

     
    function mixGenes(uint _heroGenes, uint _floorGenes, uint _equipmentId) external returns (uint);

}

 
contract DungeonBase is EjectableOwnable, Pausable, PullPayment, DungeonStructs {

     

     
    DungeonToken public dungeonTokenContract;

     
    HeroToken public heroTokenContract;


     

     
    ChallengeScienceInterface challengeScienceContract;

     
    TrainingScienceInterface trainingScienceContract;


     

    uint16[32] EQUIPMENT_POWERS = [
        1, 2, 4, 5, 16, 17, 18, 19, 0, 0, 0, 0, 0, 0, 0, 0,
        4, 16, 32, 33, 0, 0, 0, 0, 32, 64, 0, 0, 128, 0, 0, 0
    ];

    uint SUPER_HERO_MULTIPLIER = 32;

     

     
    function setDungeonTokenContract(address _newDungeonTokenContract) onlyOwner external {
        dungeonTokenContract = DungeonToken(_newDungeonTokenContract);
    }

     
    function setHeroTokenContract(address _newHeroTokenContract) onlyOwner external {
        heroTokenContract = HeroToken(_newHeroTokenContract);
    }

     
    function setChallengeScienceContract(address _newChallengeScienceAddress) onlyOwner external {
        challengeScienceContract = ChallengeScienceInterface(_newChallengeScienceAddress);
    }

     
    function setTrainingScienceContract(address _newTrainingScienceAddress) onlyOwner external {
        trainingScienceContract = TrainingScienceInterface(_newTrainingScienceAddress);
    }


     

     
    modifier dungeonExists(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        _;
    }


     

     
    function _getTop5HeroesPower(address _address, uint _dungeonId) internal view returns (uint) {
        uint heroCount = heroTokenContract.balanceOf(_address);

        if (heroCount == 0) {
            return 0;
        }

         
        uint[] memory heroPowers = new uint[](heroCount);

        for (uint i = 0; i < heroCount; i++) {
            uint heroId = heroTokenContract.ownerTokens(_address, i);
            uint genes;
            (,,, genes) = heroTokenContract.heroes(heroId);
             
            heroPowers[i] = _getHeroPower(genes, _dungeonId);
        }

         
        uint result;
        uint curMax;
        uint curMaxIndex;

        for (uint j; j < 5; j++){
            for (uint k = 0; k < heroPowers.length; k++) {
                if (heroPowers[k] > curMax) {
                    curMax = heroPowers[k];
                    curMaxIndex = k;
                }
            }

            result += curMax;
            heroPowers[curMaxIndex] = 0;
            curMax = 0;
            curMaxIndex = 0;
        }

        return result;
    }

     
    function _getHeroPower(uint _genes, uint _dungeonId) internal view returns (uint) {
        uint difficulty;
        (,, difficulty,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint statsPower;

        for (uint i = 0; i < 4; i++) {
            statsPower += _genes % 32 + 1;
            _genes /= 32 ** 4;
        }

         
        uint equipmentPower;
        uint superRank = _genes % 32;

        for (uint j = 4; j < 12; j++) {
            uint curGene = _genes % 32;
            equipmentPower += EQUIPMENT_POWERS[curGene];
            _genes /= 32 ** 4;

            if (superRank != curGene) {
                superRank = 0;
            }
        }

         
        bool isSuper = superRank >= 16;
        uint superBoost;

        if (isSuper) {
            superBoost = (difficulty - 1) * SUPER_HERO_MULTIPLIER;
        }

        return statsPower + equipmentPower + superBoost;
    }

     
    function _getDungeonPower(uint _genes) internal view returns (uint) {
         
        uint dungeonPower;

        for (uint j = 0; j < 12; j++) {
            dungeonPower += EQUIPMENT_POWERS[_genes % 32];
            _genes /= 32 ** 4;
        }

        return dungeonPower;
    }

}

contract DungeonTransportation is DungeonBase {

     
    event PlayerTransported(uint timestamp, address indexed playerAddress, uint indexed originDungeonId, uint indexed destinationDungeonId);


     

     
    uint public transportationFeeMultiplier = 500 szabo;


     


     
    mapping(address => uint) public playerToDungeonID;

     
    mapping(uint => uint) public dungeonPlayerCount;

     
    function transport(uint _destinationDungeonId) whenNotPaused dungeonCanTransport(_destinationDungeonId) external payable {
        uint originDungeonId = playerToDungeonID[msg.sender];

         
        require(_destinationDungeonId != originDungeonId);

         
        uint difficulty;
        uint capacity;
        (,, difficulty, capacity,,,,,) = dungeonTokenContract.dungeons(_destinationDungeonId);

         
        uint top5HeroesPower = _getTop5HeroesPower(msg.sender, _destinationDungeonId);
        require(top5HeroesPower >= difficulty * 12);

         
        uint baseFee = difficulty * transportationFeeMultiplier;
        uint additionalFee = top5HeroesPower / 48 * transportationFeeMultiplier;
        uint requiredFee = baseFee + additionalFee;
        require(msg.value >= requiredFee);

         
         
        dungeonTokenContract.addDungeonRewards(originDungeonId, requiredFee);

         
        asyncSend(msg.sender, msg.value - requiredFee);

        _transport(originDungeonId, _destinationDungeonId);
    }

     
    function _transport(uint _originDungeonId, uint _destinationDungeonId) private {
         
        if (heroTokenContract.balanceOf(msg.sender) == 0) {
            claimHero();
        }

         
         
        dungeonPlayerCount[_originDungeonId]--;
        dungeonPlayerCount[_destinationDungeonId]++;

         
         
        playerToDungeonID[msg.sender] = _destinationDungeonId;

         
        PlayerTransported(now, msg.sender, _originDungeonId, _destinationDungeonId);
    }


     

     
    function _getHeroGenesOrClaimFirstHero(uint _heroId) internal returns (uint heroId, uint heroGenes) {
        heroId = _heroId;

         
        if (heroTokenContract.balanceOf(msg.sender) == 0) {
            heroId = claimHero();
        }

        (,,,heroGenes) = heroTokenContract.heroes(heroId);
    }

     
    function claimHero() public returns (uint) {
         
         
        if (playerToDungeonID[msg.sender] == 0 && heroTokenContract.balanceOf(msg.sender) == 0) {
            dungeonPlayerCount[0]++;
        }

        return heroTokenContract.createHero(0, msg.sender);
    }


     

     
    function setTransportationFeeMultiplier(uint _newTransportationFeeMultiplier) onlyOwner external {
        transportationFeeMultiplier = _newTransportationFeeMultiplier;
    }


     

     
    modifier dungeonCanTransport(uint _destinationDungeonId) {
        require(_destinationDungeonId < dungeonTokenContract.totalSupply());
        uint status;
        uint capacity;
        (,status,,capacity,,,,,) = dungeonTokenContract.dungeons(_destinationDungeonId);
        require(status == 0 || status == 1);

         
         
        require(capacity == 0 || dungeonPlayerCount[_destinationDungeonId] < capacity);
        _;
    }

}

contract DungeonChallenge is DungeonTransportation {

     
    event DungeonChallenged(uint timestamp, address indexed playerAddress, uint indexed dungeonId, uint indexed heroId, uint heroGenes, uint floorNumber, uint floorGenes, bool success, uint newFloorGenes, uint successRewards, uint masterRewards);


     

     
    uint public challengeFeeMultiplier = 1 finney;

     
    uint public challengeRewardsPercent = 64;

     
    uint public masterRewardsPercent = 8;

     
    uint public challengeCooldownTime = 3 minutes;

     
    uint public dungeonPreparationTime = 60 minutes;

     
    uint public rushTimeChallengeRewardsPercent = 30;

     
    uint public rushTimeFloorCount = 30;

     
    function challenge(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanChallenge(_dungeonId) heroAllowedToChallenge(_heroId) external payable {
         
        uint difficulty;
        uint seedGenes;
        (,, difficulty,,,,, seedGenes,) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint requiredFee = difficulty * challengeFeeMultiplier;
        require(msg.value >= requiredFee);

         
         
        dungeonTokenContract.addDungeonRewards(_dungeonId, requiredFee);

         
        asyncSend(msg.sender, msg.value - requiredFee);

         
        _challengePart2(_dungeonId, _heroId);
    }

     
    function _challengePart2(uint _dungeonId, uint _heroId) private {
        uint floorNumber;
        uint rewards;
        uint floorGenes;
        (,,,, floorNumber,, rewards,, floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint heroGenes;
        (_heroId, heroGenes) = _getHeroGenesOrClaimFirstHero(_heroId);

        bool success = _getChallengeSuccess(heroGenes, _dungeonId, floorGenes);

        uint newFloorGenes;
        uint masterRewards;
        uint successRewards;
        uint newRewards;

         
        if (success) {
            newFloorGenes = _getNewFloorGene(_dungeonId);

            masterRewards = rewards * masterRewardsPercent / 100;

            if (floorNumber < rushTimeFloorCount) {  
                successRewards = rewards * rushTimeChallengeRewardsPercent / 100;

                 
                newRewards = rewards * (100 - rushTimeChallengeRewardsPercent - masterRewardsPercent) / 100;
            } else {
                successRewards = rewards * challengeRewardsPercent / 100;
                newRewards = rewards * (100 - challengeRewardsPercent - masterRewardsPercent) / 100;
            }

             
            require(successRewards + masterRewards + newRewards <= rewards);

             
             
            dungeonTokenContract.addDungeonNewFloor(_dungeonId, newRewards, newFloorGenes);

             
            asyncSend(msg.sender, successRewards);

             
            asyncSend(dungeonTokenContract.ownerOf(_dungeonId), masterRewards);
        }

         
         
        heroTokenContract.triggerCooldown(_heroId);

         
        DungeonChallenged(now, msg.sender, _dungeonId, _heroId, heroGenes, floorNumber, floorGenes, success, newFloorGenes, successRewards, masterRewards);
    }

     
    function _getChallengeSuccess(uint _heroGenes, uint _dungeonId, uint _floorGenes) private view returns (bool) {
         
        uint heroPower = _getHeroPower(_heroGenes, _dungeonId);
        uint floorPower = _getDungeonPower(_floorGenes);

        return heroPower > floorPower;
    }

     
    function _getNewFloorGene(uint _dungeonId) private returns (uint) {
        uint seedGenes;
        uint floorGenes;
        (,,,,,, seedGenes, floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint floorPower = _getDungeonPower(floorGenes);

         
        uint newFloorGenes = challengeScienceContract.mixGenes(floorGenes, seedGenes);

        uint newFloorPower = _getDungeonPower(newFloorGenes);

         
        if (newFloorPower < floorPower) {
            newFloorGenes = floorGenes;
        }

        return newFloorGenes;
    }


     

     
    function setChallengeFeeMultiplier(uint _newChallengeFeeMultiplier) onlyOwner external {
        challengeFeeMultiplier = _newChallengeFeeMultiplier;
    }

     
    function setChallengeRewardsPercent(uint _newChallengeRewardsPercent) onlyOwner external {
        challengeRewardsPercent = _newChallengeRewardsPercent;
    }

     
    function setMasterRewardsPercent(uint _newMasterRewardsPercent) onlyOwner external {
        masterRewardsPercent = _newMasterRewardsPercent;
    }

     
    function setChallengeCooldownTime(uint _newChallengeCooldownTime) onlyOwner external {
        challengeCooldownTime = _newChallengeCooldownTime;
    }

     
    function setDungeonPreparationTime(uint _newDungeonPreparationTime) onlyOwner external {
        dungeonPreparationTime = _newDungeonPreparationTime;
    }

     
    function setRushTimeChallengeRewardsPercent(uint _newRushTimeChallengeRewardsPercent) onlyOwner external {
        rushTimeChallengeRewardsPercent = _newRushTimeChallengeRewardsPercent;
    }

     
    function setRushTimeFloorCount(uint _newRushTimeFloorCount) onlyOwner external {
        rushTimeFloorCount = _newRushTimeFloorCount;
    }


     

     
    modifier dungeonCanChallenge(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        uint creationTime;
        uint status;
        (creationTime, status,,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        require(status == 0 || status == 2);

         
        require(playerToDungeonID[msg.sender] == _dungeonId);

         
        require(creationTime + dungeonPreparationTime <= now);
        _;
    }

     
    modifier heroAllowedToChallenge(uint _heroId) {
        if (heroTokenContract.balanceOf(msg.sender) > 0) {
             
            require(heroTokenContract.ownerOf(_heroId) == msg.sender);

            uint cooldownStartTime;
            (, cooldownStartTime,,) = heroTokenContract.heroes(_heroId);
            require(cooldownStartTime + challengeCooldownTime <= now);
        }
        _;
    }

}

contract DungeonTraining is DungeonChallenge {

     
    event HeroTrained(uint timestamp, address indexed playerAddress, uint indexed dungeonId, uint indexed heroId, uint heroGenes, uint floorNumber, uint floorGenes, bool success, uint newHeroGenes);


     

     
    uint public trainingFeeMultiplier = 2 finney;

     
    uint public preparationPeriodTrainingFeeMultiplier = 1800 szabo;

     
    uint public equipmentTrainingFeeMultiplier = 500 szabo;

     
    function train1(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        _train(_dungeonId, _heroId, 0, 1);
    }

    function train2(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        _train(_dungeonId, _heroId, 0, 2);
    }

    function train3(uint _dungeonId, uint _heroId) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        _train(_dungeonId, _heroId, 0, 3);
    }

     
    function trainEquipment(uint _dungeonId, uint _heroId, uint _equipmentIndex) whenNotPaused dungeonCanTrain(_dungeonId) heroAllowedToTrain(_heroId) external payable {
        require(_equipmentIndex <= 8);

        _train(_dungeonId, _heroId, _equipmentIndex, 1);
    }

     
    function _train(uint _dungeonId, uint _heroId, uint _equipmentIndex, uint _trainingTimes) private {
         
        uint creationTime;
        uint difficulty;
        uint floorNumber;
        uint rewards;
        uint seedGenes;
        uint floorGenes;
        (creationTime,,difficulty,,floorNumber,,rewards,seedGenes,floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        require(_trainingTimes < 10);

         
        uint requiredFee;

        if (_equipmentIndex > 0) {  
            requiredFee = difficulty * equipmentTrainingFeeMultiplier * _trainingTimes;
        } else if (now < creationTime + dungeonPreparationTime) {  
            requiredFee = difficulty * preparationPeriodTrainingFeeMultiplier * _trainingTimes;
        } else {  
            requiredFee = difficulty * trainingFeeMultiplier * _trainingTimes;
        }

        require(msg.value >= requiredFee);

         
        uint heroGenes;
        (_heroId, heroGenes) = _getHeroGenesOrClaimFirstHero(_heroId);

         
         
        dungeonTokenContract.addDungeonRewards(_dungeonId, requiredFee);

         
        asyncSend(msg.sender, msg.value - requiredFee);

         
        _trainPart2(_dungeonId, _heroId, heroGenes, _equipmentIndex, _trainingTimes);
    }

     
    function _trainPart2(uint _dungeonId, uint _heroId, uint _heroGenes, uint _equipmentIndex, uint _trainingTimes) private {
         
        uint floorNumber;
        uint floorGenes;
        (,,,, floorNumber,,,, floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint heroPower = _getHeroPower(_heroGenes, _dungeonId);

        uint newHeroGenes = _heroGenes;
        uint newHeroPower = heroPower;

         
         
        for (uint i = 0; i < _trainingTimes; i++) {
             
            uint tmpHeroGenes = trainingScienceContract.mixGenes(newHeroGenes, floorGenes, _equipmentIndex);

            uint tmpHeroPower = _getHeroPower(tmpHeroGenes, _dungeonId);

            if (tmpHeroPower > newHeroPower) {
                newHeroGenes = tmpHeroGenes;
                newHeroPower = tmpHeroPower;
            }
        }

         
        if (newHeroPower > heroPower) {
             
             
            heroTokenContract.setHeroGenes(_heroId, newHeroGenes);
        }

         
        HeroTrained(now, msg.sender, _dungeonId, _heroId, _heroGenes, floorNumber, floorGenes, newHeroPower > heroPower, newHeroGenes);
    }


     

     
    function setTrainingFeeMultiplier(uint _newTrainingFeeMultiplier) onlyOwner external {
        trainingFeeMultiplier = _newTrainingFeeMultiplier;
    }

     
    function setPreparationPeriodTrainingFeeMultiplier(uint _newPreparationPeriodTrainingFeeMultiplier) onlyOwner external {
        preparationPeriodTrainingFeeMultiplier = _newPreparationPeriodTrainingFeeMultiplier;
    }

     
    function setEquipmentTrainingFeeMultiplier(uint _newEquipmentTrainingFeeMultiplier) onlyOwner external {
        equipmentTrainingFeeMultiplier = _newEquipmentTrainingFeeMultiplier;
    }


     

     
    modifier dungeonCanTrain(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        uint status;
        (,status,,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        require(status == 0 || status == 3);

         
        require(playerToDungeonID[msg.sender] == _dungeonId);
        _;
    }

     
    modifier heroAllowedToTrain(uint _heroId) {
        if (heroTokenContract.balanceOf(msg.sender) > 0) {
             
            require(heroTokenContract.ownerOf(_heroId) == msg.sender);
        }
        _;
    }


}

 
contract DungeonCoreBeta is Destructible, DungeonTraining {

     
    function DungeonCoreBeta(
        address _dungeonTokenAddress,
        address _heroTokenAddress,
        address _challengeScienceAddress,
        address _trainingScienceAddress
    ) public {
        dungeonTokenContract = DungeonToken(_dungeonTokenAddress);
        heroTokenContract = HeroToken(_heroTokenAddress);
        challengeScienceContract = ChallengeScienceInterface(_challengeScienceAddress);
        trainingScienceContract = TrainingScienceInterface(_trainingScienceAddress);
    }

     
    function getDungeonDetails(uint _id) external view returns (uint creationTime, uint status, uint difficulty, uint capacity, bool isReady, uint playerCount) {
        require(_id < dungeonTokenContract.totalSupply());

         
        (creationTime, status, difficulty, capacity,,,,,) = dungeonTokenContract.dungeons(_id);

         
        isReady = creationTime + dungeonPreparationTime <= now;
        playerCount = dungeonPlayerCount[_id];
    }

     
    function getDungeonFloorDetails(uint _id) external view returns (uint floorNumber, uint floorCreationTime, uint rewards, uint seedGenes, uint floorGenes) {
        require(_id < dungeonTokenContract.totalSupply());

         
        (,,,, floorNumber, floorCreationTime, rewards, seedGenes, floorGenes) = dungeonTokenContract.dungeons(_id);
    }

     
    function getHeroDetails(uint _id) external view returns (uint creationTime, uint cooldownStartTime, uint cooldownIndex, uint genes, bool isReady) {
        require(_id < heroTokenContract.totalSupply());

        (creationTime, cooldownStartTime, cooldownIndex, genes) = heroTokenContract.heroes(_id);

         
        isReady = cooldownStartTime + challengeCooldownTime <= now;
    }

     
    function getPlayerDetails(address _address) external view returns (uint dungeonId, uint payment) {
        dungeonId = playerToDungeonID[_address];
        payment = payments[_address];
    }

}