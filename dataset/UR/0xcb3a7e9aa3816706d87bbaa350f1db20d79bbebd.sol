 

pragma solidity 0.4.19;

 
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


 
contract EDCoreInterface {

     
    function getGameSettings() external view returns (
        uint _recruitHeroFee,
        uint _transportationFeeMultiplier,
        uint _noviceDungeonId,
        uint _consolationRewardsRequiredFaith,
        uint _challengeFeeMultiplier,
        uint _dungeonPreparationTime,
        uint _trainingFeeMultiplier,
        uint _equipmentTrainingFeeMultiplier,
        uint _preparationPeriodTrainingFeeMultiplier,
        uint _preparationPeriodEquipmentTrainingFeeMultiplier
    );

     
    function getPlayerDetails(address _address) external view returns (
        uint dungeonId,
        uint payment,
        uint dungeonCount,
        uint heroCount,
        uint faith,
        bool firstHeroRecruited
    );

     
    function getDungeonDetails(uint _id) external view returns (
        uint creationTime,
        uint status,
        uint difficulty,
        uint capacity,
        address owner,
        bool isReady,
        uint playerCount
    );

     
    function getDungeonFloorDetails(uint _id) external view returns (
        uint floorNumber,
        uint floorCreationTime,
        uint rewards,
        uint seedGenes,
        uint floorGenes
    );

     
    function getHeroDetails(uint _id) external view returns (
        uint creationTime,
        uint cooldownStartTime,
        uint cooldownIndex,
        uint genes,
        address owner,
        bool isReady,
        uint cooldownRemainingTime
    );

     
    function getHeroAttributes(uint _genes) public pure returns (uint[]);

     
    function getHeroPower(uint _genes, uint _dungeonDifficulty) public pure returns (
        uint totalPower,
        uint equipmentPower,
        uint statsPower,
        bool isSuper,
        uint superRank,
        uint superBoost
    );

     
    function getDungeonPower(uint _genes) public pure returns (uint);

     
    function calculateTop5HeroesPower(address _address, uint _dungeonId) public view returns (uint);

}


 
contract DungeonRunCore is Pausable, Destructible {

     

    struct Monster {
        uint64 creationTime;
        uint8 level;
        uint16 initialHealth;
        uint16 health;
    }


     

     
    EDCoreInterface public edCoreContract = EDCoreInterface(0xf7eD56c1AC4d038e367a987258b86FC883b960a1);


     

     
    uint8 public constant checkpointLevel = 5;

     
    uint8 public constant breakevenLevel = 10;

     
    uint8 public constant jackpotLevel = 12;

     
    uint public constant dungeonDifficulty = 3;

     
    uint16 public monsterHealth = 10;

     
    uint public monsterStrength = 4;

     
    uint64 public monsterFleeTime = 8 minutes;


     

     
    uint public entranceFee = 0.04 ether;

     
    uint public reviveFee = 0.02 ether;

     
    uint public jackpot = 0.16 ether;

     
    uint public entranceFeePool;

     
    uint _seed;


     

     
    mapping(uint => Monster) public heroIdToMonster;

     
    mapping(uint => uint) public heroIdToHealth;

     
    mapping(uint => uint) public heroIdToRefundedFee;


     

     
    event LogAttack(uint timestamp, address indexed player, uint indexed heroId, uint indexed monsterLevel, uint damageByHero, uint damageByMonster, bool isMonsterDefeated, uint rewards);

    function DungeonRunAlpha() public payable {}

     

     
    function getGameSettings() external view returns (
        uint _checkpointLevel,
        uint _breakevenLevel,
        uint _jackpotLevel,
        uint _dungeonDifficulty,
        uint _monsterHealth,
        uint _monsterStrength,
        uint _monsterFleeTime,
        uint _entranceFee,
        uint _reviveFee
    ) {
        _checkpointLevel = checkpointLevel;
        _breakevenLevel = breakevenLevel;
        _jackpotLevel = jackpotLevel;
        _dungeonDifficulty = dungeonDifficulty;
        _monsterHealth = monsterHealth;
        _monsterStrength = monsterStrength;
        _monsterFleeTime = monsterFleeTime;
        _entranceFee = entranceFee;
        _reviveFee = reviveFee;
    }

     
    function getRunDetails(uint _heroId) external view returns (
        uint _heroPower,
        uint _heroStrength,
        uint _heroInitialHealth,
        uint _heroHealth,
        uint _monsterCreationTime,
        uint _monsterLevel,
        uint _monsterInitialHealth,
        uint _monsterHealth,
        uint _gameState  
    ) {
        uint genes;
        address owner;
        (,,, genes, owner,,) = edCoreContract.getHeroDetails(_heroId);
        (_heroPower,,,,) = edCoreContract.getHeroPower(genes, dungeonDifficulty);
        _heroStrength = (genes / (32 ** 8)) % 32 + 1;
        _heroInitialHealth = (genes / (32 ** 12)) % 32 + 1;
        _heroHealth = heroIdToHealth[_heroId];

        Monster memory monster = heroIdToMonster[_heroId];
        _monsterCreationTime = monster.creationTime;

         
         
        bool _dungeonRunEnded = monster.level > 0 && (
            _heroHealth == 0 || 
            now > _monsterCreationTime + monsterFleeTime * 2 ||
            (monster.health == monster.initialHealth && now > monster.creationTime + monsterFleeTime)
        );

         
        if (monster.level == 0) {
             
            _heroHealth = _heroInitialHealth;
            _monsterLevel = 1;
            _monsterInitialHealth = monsterHealth;
            _monsterHealth = _monsterInitialHealth;
            _gameState = 0;
        } else if (_dungeonRunEnded) {
             
            _monsterLevel = monster.level;
            _monsterInitialHealth = monster.initialHealth;
            _monsterHealth = monster.health;
            _gameState = 3;
        } else if (now > _monsterCreationTime + monsterFleeTime) {
             
            if (monster.level + monsterStrength > _heroHealth) {
                _heroHealth = 0;
                _monsterLevel = monster.level;
                _monsterInitialHealth = monster.initialHealth;
                _monsterHealth = monster.health;
                _gameState = 2;
            } else {
                _heroHealth -= monster.level + monsterStrength;
                _monsterCreationTime += monsterFleeTime;
                _monsterLevel = monster.level + 1;
                _monsterInitialHealth = _monsterLevel * monsterHealth;
                _monsterHealth = _monsterInitialHealth;
                _gameState = 1;
            }
        } else {
             
            _monsterLevel = monster.level;
            _monsterInitialHealth = monster.initialHealth;
            _monsterHealth = monster.health;
            _gameState = 2;
        }
    }

     
    function attack(uint _heroId) whenNotPaused onlyHumanAddress external payable {
        uint genes;
        address owner;
        (,,, genes, owner,,) = edCoreContract.getHeroDetails(_heroId);

         
        require(msg.sender == owner);

         
        uint heroInitialHealth = (genes / (32 ** 12)) % 32 + 1;
        uint heroStrength = (genes / (32 ** 8)) % 32 + 1;

         
        Monster memory monster = heroIdToMonster[_heroId];
        uint currentLevel = monster.level;
        uint heroCurrentHealth = heroIdToHealth[_heroId];

         
        bool dungeonRunEnded;

         
        if (currentLevel == 0) {
             
            require(msg.value >= entranceFee);
            entranceFeePool += entranceFee;
            
             
            heroIdToMonster[_heroId] = Monster(uint64(now), 1, monsterHealth, monsterHealth);
            monster = heroIdToMonster[_heroId];

             
            heroIdToHealth[_heroId] = heroInitialHealth;
            heroCurrentHealth = heroInitialHealth;

             
            if (msg.value > entranceFee) {
                msg.sender.transfer(msg.value - entranceFee);
            }
        } else {
             
            require(heroCurrentHealth > 0);
    
             
             
            dungeonRunEnded = now > monster.creationTime + monsterFleeTime * 2 ||
                (monster.health == monster.initialHealth && now > monster.creationTime + monsterFleeTime);

            if (dungeonRunEnded) {
                 
                uint addToJackpot = entranceFee - heroIdToRefundedFee[_heroId];
            
                if (addToJackpot > 0) {
                    jackpot += addToJackpot;
                    entranceFeePool -= addToJackpot;
                    heroIdToRefundedFee[_heroId] += addToJackpot;
                }

                 
                assert(addToJackpot <= entranceFee);
            }
            
             
            msg.sender.transfer(msg.value);
        }

        if (!dungeonRunEnded) {
             
            _attack(_heroId, genes, heroStrength, heroCurrentHealth);
        }
    }
    
     
    function revive(uint _heroId) whenNotPaused external payable {
         
        require(msg.value >= reviveFee);
        
         
        jackpot += reviveFee;
        
         
        delete heroIdToHealth[_heroId];
        delete heroIdToMonster[_heroId];
        delete heroIdToRefundedFee[_heroId];
    
         
        if (msg.value > reviveFee) {
            msg.sender.transfer(msg.value - reviveFee);
        }
    }


     

    function setEdCoreContract(address _newEdCoreContract) onlyOwner external {
        edCoreContract = EDCoreInterface(_newEdCoreContract);
    }

    function setEntranceFee(uint _newEntranceFee) onlyOwner external {
        entranceFee = _newEntranceFee;
    }


     

     
    function _attack(uint _heroId, uint _genes, uint _heroStrength, uint _heroCurrentHealth) internal {
        Monster storage monster = heroIdToMonster[_heroId];
        uint8 currentLevel = monster.level;

         
        uint heroPower;
        (heroPower,,,,) = edCoreContract.getHeroPower(_genes, dungeonDifficulty);
        
        uint damageByMonster;
        uint damageByHero;

         
         
         
        damageByHero = (_heroStrength * 1e9 + heroPower * 1e9 / (10 * (1 + _getRandomNumber(5)))) / tx.gasprice;
        bool isMonsterDefeated = damageByHero >= monster.health;

        if (isMonsterDefeated) {
            uint rewards;

             
             
            uint8 newLevel = currentLevel + 1;
            heroIdToMonster[_heroId] = Monster(uint64(now), newLevel, newLevel * monsterHealth, newLevel * monsterHealth);
            monster = heroIdToMonster[_heroId];

             
            if (currentLevel == checkpointLevel) {
                 
                rewards = entranceFee / 2;
                heroIdToRefundedFee[_heroId] += rewards;
                entranceFeePool -= rewards;
            } else if (currentLevel == breakevenLevel) {
                 
                rewards = entranceFee / 2;
                heroIdToRefundedFee[_heroId] += rewards;
                entranceFeePool -= rewards;
            } else if (currentLevel == jackpotLevel) {
                 
                rewards = jackpot / 2;
                jackpot -= rewards;
            }

            msg.sender.transfer(rewards);
        } else {
             
            monster.health -= uint8(damageByHero);

             
             
            if (now > monster.creationTime + monsterFleeTime) {
                 
                 
                damageByMonster = currentLevel + monsterStrength;
            } else {
                 
                if (currentLevel >= 2) {
                    damageByMonster = _getRandomNumber(currentLevel / 2);
                }
            }
        }

         
        if (damageByMonster >= _heroCurrentHealth) {
             
            heroIdToHealth[_heroId] = 0;

             
            uint addToJackpot = entranceFee - heroIdToRefundedFee[_heroId];
            
            if (addToJackpot > 0) {
                jackpot += addToJackpot;
                entranceFeePool -= addToJackpot;
                heroIdToRefundedFee[_heroId] += addToJackpot;
            }

             
            assert(addToJackpot <= entranceFee);
        } else {
             
            if (damageByMonster > 0) {
                heroIdToHealth[_heroId] -= damageByMonster;
            }

             
            if (now > monster.creationTime + monsterFleeTime) {
                currentLevel++;
                heroIdToMonster[_heroId] = Monster(uint64(monster.creationTime + monsterFleeTime),
                    currentLevel, currentLevel * monsterHealth, currentLevel * monsterHealth);
                monster = heroIdToMonster[_heroId];
            }
        }

         
        LogAttack(now, msg.sender, _heroId, currentLevel, damageByHero, damageByMonster, isMonsterDefeated, rewards);
    }

     
    function _getRandomNumber(uint _upper) private returns (uint) {
        _seed = uint(keccak256(
            _seed,
            block.blockhash(block.number - 1),
            block.coinbase,
            block.difficulty
        ));

        return _seed % _upper;
    }


     
    
     
    modifier onlyHumanAddress() {
        address addr = msg.sender;
        uint size;
        assembly { size := extcodesize(addr) }
        require(size == 0);
        _;
    }

}