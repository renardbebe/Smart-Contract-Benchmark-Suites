 

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

  address public anotherOwner;

   
  modifier eitherOwner() {
    require(msg.sender == owner || msg.sender == anotherOwner);
    _;
  }

   
  function assignAnotherOwner(address _anotherOwner) onlyOwner public {
    require(_anotherOwner != 0);
    AnotherOwnerAssigned(_anotherOwner);
    anotherOwner = _anotherOwner;
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

contract DungeonStructs {

     
    struct Dungeon {

         
        uint32 creationTime;

         
         
        uint16 status;

         
         
         
         
         
        uint16 difficulty;

         
         
         
        uint32 floorNumber;

         
        uint32 floorCreationTime;

         
        uint128 rewards;

         
         
         
         
        uint seedGenes;

         
         
         
        uint floorGenes;

    }

     
    struct Hero {

         
        uint64 creationTime;

         
         
         
        uint genes;

    }

}

 
contract ERC721 {

     
    event Transfer(address indexed from, address indexed to, uint tokenId);

     
     
     
    function totalSupply() public view returns (uint);
    function balanceOf(address _owner) public view returns (uint);

     
    function ownerOf(uint _tokenId) external view returns (address);
    function transfer(address _to, uint _tokenId) external;

}

 
contract DungeonToken is ERC721, DungeonStructs, Pausable, JointOwnable {

     
    uint public constant DUNGEON_CREATION_LIMIT = 1024;

     
    event Mint(address indexed owner, uint newTokenId, uint difficulty, uint seedGenes);

     
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
                }
            }
        }

         
        Transfer(_from, _to, _tokenId);
    }

     
    function transfer(address _to, uint _tokenId) whenNotPaused external {
         
        require(_to != address(0));

         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
    function createDungeon(uint _difficulty, uint _seedGenes, address _owner) eitherOwner external returns (uint) {
         
        require(totalSupply() < DUNGEON_CREATION_LIMIT);

         
         
        dungeons.push(Dungeon(uint32(now), 0, uint16(_difficulty), 0, 0, 0, _seedGenes, 0));

         
        uint newTokenId = dungeons.length - 1;

         
        Mint(_owner, newTokenId, _difficulty, _seedGenes);

         
        addDungeonNewFloor(newTokenId, 0, _seedGenes);

         
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }

     
    function setDungeonStatus(uint _id, uint _newStatus) eitherOwner external {
        require(_id < totalSupply());

        dungeons[_id].status = uint16(_newStatus);
    }

     
    function addDungeonRewards(uint _id, uint _additinalRewards) eitherOwner external {
        require(_id < totalSupply());

        dungeons[_id].rewards += uint64(_additinalRewards);
    }

     
    function addDungeonNewFloor(uint _id, uint _newRewards, uint _newFloorGenes) eitherOwner public {
        require(_id < totalSupply());

        Dungeon storage dungeon = dungeons[_id];

        dungeon.floorNumber++;
        dungeon.floorCreationTime = uint32(now);
        dungeon.rewards = uint128(_newRewards);
        dungeon.floorGenes = _newFloorGenes;

         
        NewDungeonFloor(now, _id, dungeon.floorNumber, dungeon.rewards, dungeon.floorGenes);
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
                }
            }
        }

         
        Transfer(_from, _to, _tokenId);
    }

     
    function transfer(address _to, uint _tokenId) whenNotPaused external {
         
        require(_to != address(0));

         
        require(_to != address(this));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
    function createHero(uint _genes, address _owner) external returns (uint) {
         
         
        heroes.push(Hero(uint64(now), _genes));

         
        uint newTokenId = heroes.length - 1;

         
        Mint(_owner, newTokenId, _genes);

         
        _transfer(0, _owner, newTokenId);

        return newTokenId;
    }

     
    function setHeroGenes(uint _id, uint _newGenes) eitherOwner external {
        require(_id < totalSupply());

        Hero storage hero = heroes[_id];

        hero.genes = _newGenes;
    }

}

 
contract ChallengeScienceInterface {

     
    function mixGenes(uint _floorGenes, uint _seedGenes) external pure returns (uint);

}

 
contract TrainingScienceInterface {

     
    function mixGenes(uint _heroGenes, uint _floorGenes) external pure returns (uint);

}

 
contract DungeonBase is EjectableOwnable, Pausable, PullPayment, DungeonStructs {

     

     
    DungeonToken public dungeonTokenContract;

     
    HeroToken public heroTokenContract;


     

     
    ChallengeScienceInterface challengeScienceContract;

     
    TrainingScienceInterface trainingScienceContract;


     

     
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

     
    modifier canChallenge(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        uint status;
        (,status,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        require(status == 0 || status == 1);
        _;
    }

     
    modifier canTrain(uint _dungeonId) {
        require(_dungeonId < dungeonTokenContract.totalSupply());
        uint status;
        (,status,,,,,,) = dungeonTokenContract.dungeons(_dungeonId);
        require(status == 0 || status == 2);
        _;
    }


     

     
    function _getGenesPower(uint _genes) internal pure returns (uint) {
         
        uint statsPower;

        for (uint i = 0; i < 4; i++) {
            statsPower += _genes % 32;
            _genes /= 32 ** 4;
        }

         
        uint equipmentPower;
        bool isSuper = true;

        for (uint j = 4; j < 12; j++) {
            uint curGene = _genes % 32;
            equipmentPower += curGene;
            _genes /= 32 ** 4;

            if (equipmentPower != curGene * (j - 3)) {
                isSuper = false;
            }
        }

         
        if (isSuper) {
            equipmentPower *= 2;
        }

        return statsPower + equipmentPower + 12;
    }

}

contract DungeonChallenge is DungeonBase {

     
    event DungeonChallenged(uint timestamp, address indexed playerAddress, uint indexed dungeonId, uint heroGenes, uint floorNumber, uint floorGenes, bool success, uint newFloorGenes, uint successRewards, uint masterRewards);

     
    uint256 public challengeFeeMultiplier = 1 finney;

     
    uint public challengeRewardsPercent = 64;

     
    uint public masterRewardsPercent = 8;

     
    function challenge(uint _dungeonId) external payable whenNotPaused canChallenge(_dungeonId) {
         
        uint difficulty;
        uint seedGenes;
        (,,difficulty,,,,seedGenes,) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint requiredFee = difficulty * challengeFeeMultiplier;
        require(msg.value >= requiredFee);

         
         
        dungeonTokenContract.addDungeonRewards(_dungeonId, requiredFee);

         
        asyncSend(msg.sender, msg.value - requiredFee);

         
        _challengePart2(_dungeonId, requiredFee);
    }

     
    function _challengePart2(uint _dungeonId, uint _requiredFee) private {
        uint floorNumber;
        uint rewards;
        uint floorGenes;
        (,,,floorNumber,,rewards,,floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint _addedRewards = rewards + uint128(_requiredFee);

         
         
        uint heroGenes = _getFirstHeroGenesAndInitialize(_dungeonId);

        bool success = _getChallengeSuccess(heroGenes, floorGenes);

        uint newFloorGenes;
        uint successRewards;
        uint masterRewards;

         
        if (success) {
            newFloorGenes = _getNewFloorGene(_dungeonId);
            successRewards = _addedRewards * challengeRewardsPercent / 100;
            masterRewards = _addedRewards * masterRewardsPercent / 100;

             
            uint newRewards = _addedRewards * (100 - challengeRewardsPercent - masterRewardsPercent) / 100;

             
             
            dungeonTokenContract.addDungeonNewFloor(_dungeonId, newRewards, newFloorGenes);

             
            asyncSend(msg.sender, _addedRewards * challengeRewardsPercent / 100);

             
            asyncSend(owner, _addedRewards * masterRewardsPercent / 100);
        }

         
        DungeonChallenged(now, msg.sender, _dungeonId, heroGenes, floorNumber, floorGenes, success, newFloorGenes, successRewards, masterRewards);
    }

     
    function _getFirstHeroGenesAndInitialize(uint _dungeonId) private returns (uint heroGenes) {
        uint seedGenes;
        (,,,,,,seedGenes,) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint heroId;

        if (heroTokenContract.balanceOf(msg.sender) == 0) {
             
            heroId = heroTokenContract.createHero(seedGenes, msg.sender);
        } else {
            heroId = heroTokenContract.ownerTokens(msg.sender, 0);
        }

         
        (,heroGenes) = heroTokenContract.heroes(heroId);
    }

     
    function _getChallengeSuccess(uint heroGenes, uint floorGenes) private pure returns (bool) {
         
        uint heroPower = _getGenesPower(heroGenes);
        uint floorPower = _getGenesPower(floorGenes);

        return heroPower > floorPower;
    }

     
    function _getNewFloorGene(uint _dungeonId) private view returns (uint) {
        uint seedGenes;
        uint floorGenes;
        (,,,,,seedGenes,floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        uint floorPower = _getGenesPower(floorGenes);
        uint newFloorGenes = challengeScienceContract.mixGenes(floorGenes, seedGenes);
        uint newFloorPower = _getGenesPower(newFloorGenes);

         
        if (newFloorPower < floorPower) {
            newFloorGenes = floorGenes;
        }

        return newFloorGenes;
    }


     

     
    function setChallengeFeeMultiplier(uint _newChallengeFeeMultiplier) external onlyOwner {
        challengeFeeMultiplier = _newChallengeFeeMultiplier;
    }

     
    function setChallengeRewardsPercent(uint _newChallengeRewardsPercent) onlyOwner external {
        challengeRewardsPercent = _newChallengeRewardsPercent;
    }

     
    function setMasterRewardsPercent(uint _newMasterRewardsPercent) onlyOwner external {
        masterRewardsPercent = _newMasterRewardsPercent;
    }

}

contract DungeonTraining is DungeonChallenge {

     
    event HeroTrained(uint timestamp, address indexed playerAddress, uint indexed dungeonId, uint heroGenes, uint floorNumber, uint floorGenes, bool success, uint newHeroGenes);

     
     
     
     
    uint256 public trainingFeeMultiplier = 2 finney;

     
    function setTrainingFeeMultiplier(uint _newTrainingFeeMultiplier) external onlyOwner {
        trainingFeeMultiplier = _newTrainingFeeMultiplier;
    }

     
     
     
    function train1(uint _dungeonId) external payable whenNotPaused canTrain(_dungeonId) {
        _train(_dungeonId, 1);
    }

    function train2(uint _dungeonId) external payable whenNotPaused canTrain(_dungeonId) {
        _train(_dungeonId, 2);
    }

    function train3(uint _dungeonId) external payable whenNotPaused canTrain(_dungeonId) {
        _train(_dungeonId, 3);
    }

     
     
     
    function _train(uint _dungeonId, uint _trainingTimes) private {
         
        uint difficulty;
        uint floorNumber;
        uint rewards;
        uint seedGenes;
        uint floorGenes;
        (,,difficulty,floorNumber,,rewards,seedGenes,floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

         
        require(_trainingTimes < 10);

         
        uint requiredFee = difficulty * trainingFeeMultiplier * _trainingTimes;
        require(msg.value >= requiredFee);

         
         
        uint heroId;

        if (heroTokenContract.balanceOf(msg.sender) == 0) {
             
            heroId = heroTokenContract.createHero(seedGenes, msg.sender);
        } else {
            heroId = heroTokenContract.ownerTokens(msg.sender, 0);
        }

         
         
        dungeonTokenContract.addDungeonRewards(_dungeonId, requiredFee);

         
        asyncSend(msg.sender, msg.value - requiredFee);

         
        _trainPart2(_dungeonId, _trainingTimes, heroId);
    }

     
    function _trainPart2(uint _dungeonId, uint _trainingTimes, uint _heroId) private {
         
        uint floorNumber;
        uint floorGenes;
        (,,,floorNumber,,,,floorGenes) = dungeonTokenContract.dungeons(_dungeonId);

        uint heroGenes;
        (,heroGenes) = heroTokenContract.heroes(_heroId);

         
        uint heroPower = _getGenesPower(heroGenes);

        uint newHeroGenes = heroGenes;
        uint newHeroPower = heroPower;

         
         
        for (uint i = 0; i < _trainingTimes; i++) {
            uint tmpHeroGenes = trainingScienceContract.mixGenes(newHeroGenes, floorGenes);
            uint tmpHeroPower = _getGenesPower(tmpHeroGenes);

            if (tmpHeroPower > newHeroPower) {
                newHeroGenes = tmpHeroGenes;
                newHeroPower = tmpHeroPower;
            }
        }

         
        bool success = newHeroPower > heroPower;

        if (success) {
             
             
            heroTokenContract.setHeroGenes(_heroId, newHeroGenes);
        }

         
        HeroTrained(now, msg.sender, _dungeonId, heroGenes, floorNumber, floorGenes, success, newHeroGenes);
    }

}

 
contract DungeonCoreAlpha is Destructible, DungeonTraining {

     
    function DungeonCoreAlpha(
        address _dungeonTokenAddress,
        address _heroTokenAddress,
        address _challengeScienceAddress,
        address _trainingScienceAddress
    ) public payable {
        dungeonTokenContract = DungeonToken(_dungeonTokenAddress);
        heroTokenContract = HeroToken(_heroTokenAddress);
        challengeScienceContract = ChallengeScienceInterface(_challengeScienceAddress);
        trainingScienceContract = TrainingScienceInterface(_trainingScienceAddress);
    }

     
    function getDungeonDetails(uint _id) external view returns (uint creationTime, uint status, uint difficulty, uint floorNumber, uint floorCreationTime, uint rewards, uint seedGenes, uint floorGenes) {
        require(_id < dungeonTokenContract.totalSupply());

        (creationTime, status, difficulty, floorNumber, floorCreationTime, rewards, seedGenes, floorGenes) = dungeonTokenContract.dungeons(_id);
    }

     
    function getHeroDetails(uint _id) external view returns (uint creationTime, uint genes) {
        require(_id < heroTokenContract.totalSupply());

        (creationTime, genes) = heroTokenContract.heroes(_id);
    }

}