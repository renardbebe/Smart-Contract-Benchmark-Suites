 

pragma solidity ^0.4.17;

contract AccessControl {
    address public creatorAddress;
    uint16 public totalSeraphims = 0;
    mapping (address => bool) public seraphims;

    bool public isMaintenanceMode = true;
 
    modifier onlyCREATOR() {
        require(msg.sender == creatorAddress);
        _;
    }

    modifier onlySERAPHIM() {
        require(seraphims[msg.sender] == true);
        _;
    }
    
    modifier isContractActive {
        require(!isMaintenanceMode);
        _;
    }
    
     
    function AccessControl() public {
        creatorAddress = msg.sender;
    }
    

    function addSERAPHIM(address _newSeraphim) onlyCREATOR public {
        if (seraphims[_newSeraphim] == false) {
            seraphims[_newSeraphim] = true;
            totalSeraphims += 1;
        }
    }
    
    function removeSERAPHIM(address _oldSeraphim) onlyCREATOR public {
        if (seraphims[_oldSeraphim] == true) {
            seraphims[_oldSeraphim] = false;
            totalSeraphims -= 1;
        }
    }

    function updateMaintenanceMode(bool _isMaintaining) onlyCREATOR public {
        isMaintenanceMode = _isMaintaining;
    }

  
} 

contract SafeMath {
    function safeAdd(uint x, uint y) pure internal returns(uint) {
      uint z = x + y;
      assert((z >= x) && (z >= y));
      return z;
    }

    function safeSubtract(uint x, uint y) pure internal returns(uint) {
      assert(x >= y);
      uint z = x - y;
      return z;
    }

    function safeMult(uint x, uint y) pure internal returns(uint) {
      uint z = x * y;
      assert((x == 0)||(z/x == y));
      return z;
    }
    
     function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

    function getRandomNumber(uint16 maxRandom, uint8 min, address privateAddress) constant public returns(uint8) {
        uint256 genNum = uint256(block.blockhash(block.number-1)) + uint256(privateAddress);
        return uint8(genNum % (maxRandom - min + 1)+min);
    }
}

contract Enums {
    enum ResultCode {
        SUCCESS,
        ERROR_CLASS_NOT_FOUND,
        ERROR_LOW_BALANCE,
        ERROR_SEND_FAIL,
        ERROR_NOT_OWNER,
        ERROR_NOT_ENOUGH_MONEY,
        ERROR_INVALID_AMOUNT
    }

    enum AngelAura { 
        Blue, 
        Yellow, 
        Purple, 
        Orange, 
        Red, 
        Green 
    }
}

contract IAngelCardData is AccessControl, Enums {
    uint8 public totalAngelCardSeries;
    uint64 public totalAngels;

    
     
     
    function createAngelCardSeries(uint8 _angelCardSeriesId, uint _basePrice,  uint64 _maxTotal, uint8 _baseAura, uint16 _baseBattlePower, uint64 _liveTime) onlyCREATOR external returns(uint8);
    function updateAngelCardSeries(uint8 _angelCardSeriesId, uint64 _newPrice, uint64 _newMaxTotal) onlyCREATOR external;
    function setAngel(uint8 _angelCardSeriesId, address _owner, uint _price, uint16 _battlePower) onlySERAPHIM external returns(uint64);
    function addToAngelExperienceLevel(uint64 _angelId, uint _value) onlySERAPHIM external;
    function setAngelLastBattleTime(uint64 _angelId) onlySERAPHIM external;
    function setAngelLastVsBattleTime(uint64 _angelId) onlySERAPHIM external;
    function setLastBattleResult(uint64 _angelId, uint16 _value) onlySERAPHIM external;
    function addAngelIdMapping(address _owner, uint64 _angelId) private;
    function transferAngel(address _from, address _to, uint64 _angelId) onlySERAPHIM public returns(ResultCode);
    function ownerAngelTransfer (address _to, uint64 _angelId)  public;
    function updateAngelLock (uint64 _angelId, bool newValue) public;
    function removeCreator() onlyCREATOR external;

     
    function getAngelCardSeries(uint8 _angelCardSeriesId) constant public returns(uint8 angelCardSeriesId, uint64 currentAngelTotal, uint basePrice, uint64 maxAngelTotal, uint8 baseAura, uint baseBattlePower, uint64 lastSellTime, uint64 liveTime);
    function getAngel(uint64 _angelId) constant public returns(uint64 angelId, uint8 angelCardSeriesId, uint16 battlePower, uint8 aura, uint16 experience, uint price, uint64 createdTime, uint64 lastBattleTime, uint64 lastVsBattleTime, uint16 lastBattleResult, address owner);
    function getOwnerAngelCount(address _owner) constant public returns(uint);
    function getAngelByIndex(address _owner, uint _index) constant public returns(uint64);
    function getTotalAngelCardSeries() constant public returns (uint8);
    function getTotalAngels() constant public returns (uint64);
    function getAngelLockStatus(uint64 _angelId) constant public returns (bool);
}


contract IPetCardData is AccessControl, Enums {
    uint8 public totalPetCardSeries;    
    uint64 public totalPets;
    
     
    function createPetCardSeries(uint8 _petCardSeriesId, uint32 _maxTotal) onlyCREATOR public returns(uint8);
    function setPet(uint8 _petCardSeriesId, address _owner, string _name, uint8 _luck, uint16 _auraRed, uint16 _auraYellow, uint16 _auraBlue) onlySERAPHIM external returns(uint64);
    function setPetAuras(uint64 _petId, uint8 _auraRed, uint8 _auraBlue, uint8 _auraYellow) onlySERAPHIM external;
    function setPetLastTrainingTime(uint64 _petId) onlySERAPHIM external;
    function setPetLastBreedingTime(uint64 _petId) onlySERAPHIM external;
    function addPetIdMapping(address _owner, uint64 _petId) private;
    function transferPet(address _from, address _to, uint64 _petId) onlySERAPHIM public returns(ResultCode);
    function ownerPetTransfer (address _to, uint64 _petId)  public;
    function setPetName(string _name, uint64 _petId) public;

     
    function getPetCardSeries(uint8 _petCardSeriesId) constant public returns(uint8 petCardSeriesId, uint32 currentPetTotal, uint32 maxPetTotal);
    function getPet(uint _petId) constant public returns(uint petId, uint8 petCardSeriesId, string name, uint8 luck, uint16 auraRed, uint16 auraBlue, uint16 auraYellow, uint64 lastTrainingTime, uint64 lastBreedingTime, address owner);
    function getOwnerPetCount(address _owner) constant public returns(uint);
    function getPetByIndex(address _owner, uint _index) constant public returns(uint);
    function getTotalPetCardSeries() constant public returns (uint8);
    function getTotalPets() constant public returns (uint);
}




contract IBattleboardData is AccessControl  {

  

       
  
function createBattleboard(uint prize, uint8 restrictions) onlySERAPHIM external returns (uint16);
function killMonster(uint16 battleboardId, uint8 monsterId)  onlySERAPHIM external;
function createNullTile(uint16 _battleboardId) private ;
function createTile(uint16 _battleboardId, uint8 _tileType, uint8 _value, uint8 _position, uint32 _hp, uint16 _petPower, uint64 _angelId, uint64 _petId, address _owner, uint8 _team) onlySERAPHIM external  returns (uint8);
function killTile(uint16 battleboardId, uint8 tileId) onlySERAPHIM external ;
function addTeamtoBoard(uint16 battleboardId, address owner, uint8 team) onlySERAPHIM external;
function setTilePosition (uint16 battleboardId, uint8 tileId, uint8 _positionTo) onlySERAPHIM public ;
function setTileHp(uint16 battleboardId, uint8 tileId, uint32 _hp) onlySERAPHIM external ;
function addMedalBurned(uint16 battleboardId) onlySERAPHIM external ;
function setLastMoveTime(uint16 battleboardId) onlySERAPHIM external ;
function iterateTurn(uint16 battleboardId) onlySERAPHIM external ;
function killBoard(uint16 battleboardId) onlySERAPHIM external ;
function clearAngelsFromBoard(uint16 battleboardId) private;
 
     
function getTileHp(uint16 battleboardId, uint8 tileId) constant external returns (uint32) ;
function getMedalsBurned(uint16 battleboardId) constant external returns (uint8) ;
function getTeam(uint16 battleboardId, uint8 tileId) external returns (uint8) ;
function getMaxFreeTeams() constant public returns (uint8);
function getBarrierNum(uint16 battleboardId) public constant returns (uint8) ;
function getTileFromBattleboard(uint16 battleboardId, uint8 tileId) public constant returns (uint8 tileType, uint8 value, uint8 id, uint8 position, uint32 hp, uint16 petPower, uint64 angelId, uint64 petId, bool isLive, address owner)   ;
function getTileIDByOwner(uint16 battleboardId, address _owner) constant public returns (uint8) ;
function getPetbyTileId( uint16 battleboardId, uint8 tileId) constant public returns (uint64) ;
function getOwner (uint16 battleboardId, uint8 team,  uint8 ownerNumber) constant external returns (address);
function getTileIDbyPosition(uint16 battleboardId, uint8 position) public constant returns (uint8) ;
function getPositionFromBattleboard(uint16 battleboardId, uint8 _position) public constant returns (uint8 tileType, uint8 value, uint8 id, uint8 position, uint32 hp, uint32 petPower, uint64 angelId, uint64 petId, bool isLive)  ;
function getBattleboard(uint16 id) public constant returns (uint8 turn, bool isLive, uint prize, uint8 numTeams, uint8 numTiles, uint8 createdBarriers, uint8 restrictions, uint lastMoveTime, uint8 numTeams1, uint8 numTeams2, uint8 monster1, uint8 monster2) ;
function isBattleboardLive(uint16 battleboardId) constant public returns (bool);
function isTileLive(uint16 battleboardId, uint8 tileId) constant  external returns (bool) ;
function getLastMoveTime(uint16 battleboardId) constant public returns (uint) ;
function getNumTilesFromBoard (uint16 _battleboardId) constant public returns (uint8) ; 
function angelOnBattleboards(uint64 angelID) external constant returns (bool) ;
function getTurn(uint16 battleboardId) constant public returns (address) ;
function getNumTeams(uint16 battleboardId, uint8 team) public constant returns (uint8);
function getMonsters(uint16 BattleboardId) external constant returns (uint8 monster1, uint8 monster2) ;
function getTotalBattleboards() public constant returns (uint16) ;
  
        
 
   
}

contract IAccessoryData is AccessControl, Enums {
    uint8 public totalAccessorySeries;    
    uint32 public totalAccessories;
    
 
     
     
    function createAccessorySeries(uint8 _AccessorySeriesId, uint32 _maxTotal, uint _price) onlyCREATOR public returns(uint8) ;
	function setAccessory(uint8 _AccessorySeriesId, address _owner) onlySERAPHIM external returns(uint64);
   function addAccessoryIdMapping(address _owner, uint64 _accessoryId) private;
	function transferAccessory(address _from, address _to, uint64 __accessoryId) onlySERAPHIM public returns(ResultCode);
    function ownerAccessoryTransfer (address _to, uint64 __accessoryId)  public;
    function updateAccessoryLock (uint64 _accessoryId, bool newValue) public;
    function removeCreator() onlyCREATOR external;
    
     
    function getAccessorySeries(uint8 _accessorySeriesId) constant public returns(uint8 accessorySeriesId, uint32 currentTotal, uint32 maxTotal, uint price) ;
	function getAccessory(uint _accessoryId) constant public returns(uint accessoryID, uint8 AccessorySeriesID, address owner);
	function getOwnerAccessoryCount(address _owner) constant public returns(uint);
	function getAccessoryByIndex(address _owner, uint _index) constant public returns(uint) ;
    function getTotalAccessorySeries() constant public returns (uint8) ;
    function getTotalAccessories() constant public returns (uint);
    function getAccessoryLockStatus(uint64 _acessoryId) constant public returns (bool);

}

 
 

contract ManageBattleboards is AccessControl, SafeMath  {

     
    address public angelCardDataContract = 0x6D2E76213615925c5fc436565B5ee788Ee0E86DC;
    address public petCardDataContract = 0xB340686da996b8B3d486b4D27E38E38500A9E926;
    address public accessoryDataContract = 0x466c44812835f57b736ef9F63582b8a6693A14D0;
    address public battleboardDataContract = 0x33201831496217A779bF6169038DD9232771f179;

   
    
     
     
     
    uint public contractReservedBalance;
    
    
     
     
     
 
     
     
     
     
     
     
     
     
    
     
     
     
     
     
     
     
    
      
           
    function DataContacts(address _angelCardDataContract, address _petCardDataContract, address _accessoryDataContract, address _battleboardDataContract) onlyCREATOR external {
        angelCardDataContract = _angelCardDataContract;
        petCardDataContract = _petCardDataContract;
        accessoryDataContract = _accessoryDataContract;
        battleboardDataContract = _battleboardDataContract;

    }
    
    function checkExistsOwnedAngel (uint64 angelId) private constant returns (bool) {
        IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
       
        if ((angelId <= 0) || (angelId > angelCardData.getTotalAngels())) {return false;}
        address angelowner;
        (,,,,,,,,,,angelowner) = angelCardData.getAngel(angelId);
        if (angelowner == msg.sender) {return true;}
        
       else  return false;
}
  
    function checkExistsOwnedPet (uint64 petId) private constant returns (bool) {
          IPetCardData petCardData = IPetCardData(petCardDataContract);
       
        if ((petId <= 0) || (petId > petCardData.getTotalPets())) {return false;}
        address petowner;
         (,,,,,,,petowner) = petCardData.getPet(petId);
        if (petowner == msg.sender) {return true;}
        
       else  return false;
}

    function checkExistsOwnedAccessory (uint64 accessoryId) private constant returns (bool) {
          IAccessoryData accessoryData = IAccessoryData(accessoryDataContract);
       if (accessoryId == 0) {return true;}
        
        if ((accessoryId < 0) || (accessoryId > accessoryData.getTotalAccessories())) {return false;}
        address owner;
         (,,owner) = accessoryData.getAccessory(accessoryId);
        if (owner == msg.sender) {return true;}
        
       else  return false;
}


 function takePet(uint64 petId) private {
            
               IPetCardData PetCardData = IPetCardData(petCardDataContract);
                PetCardData.transferPet(msg.sender, address(this), petId);
        }
           
           
       function restrictionsAllow(uint64 angelId, uint8 restrictions) private constant returns (bool) {
        
        
        
        
       
        IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
        uint8 angelCardSeries;
        (,angelCardSeries,,,,,,,,,) = angelCardData.getAngel(angelId);
        
        if (angelCardSeries > restrictions) {return false;}
        if ((angelCardSeries == 2) && (restrictions < 19)) {return false;}  
        if ((angelCardSeries == 3) && (restrictions < 21)) {return false;}  
        return true;
       }
       
       
        
      
  
       function createBattleboard(uint8 restrictions) external payable returns (uint16) {
           if (restrictions <0) {revert();}
           IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
           return battleboardData.createBattleboard(msg.value, restrictions);
           
       }
       
        function closeBattleboard(uint16 battleboardId) external {
        
        IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
        address[] storage winners;
       if (battleboardData.isBattleboardLive(battleboardId) == false) {revert();}
       battleboardData.killBoard(battleboardId); 
        if ((battleboardData.getNumTeams(battleboardId,1) != 0) && (battleboardData.getNumTeams(battleboardId,2) != 0)) {revert();}
         
        uint8 id;
        uint64 petId;
        address owner;
        if ((battleboardData.getNumTeams(battleboardId,1) == 0) && (battleboardData.getNumTeams(battleboardId,2) == 0)) {
               
              IPetCardData PetCardData = IPetCardData(petCardDataContract);
              for (uint8 i =0; i<battleboardData.getMaxFreeTeams(); i++) {
                  owner = battleboardData.getOwner(battleboardId, 0, i);
                  id = battleboardData.getTileIDByOwner(battleboardId,owner);
                 petId = battleboardData.getPetbyTileId(battleboardId, id);
                 PetCardData.transferPet(address(this), owner, petId);
              }
        }
       if ((battleboardData.getNumTeams(battleboardId,1) != 0) && (battleboardData.getNumTeams(battleboardId,2) == 0)) {
        
       
        
        for (i =0; i<(safeDiv(battleboardData.getMaxFreeTeams(),2)); i++) {
                  owner = battleboardData.getOwner(battleboardId, 1, i);
                  id = battleboardData.getTileIDByOwner(battleboardId,owner);
                 petId = battleboardData.getPetbyTileId(battleboardId, id);
                 PetCardData.transferPet(address(this), owner, petId);
                winners.push(owner); 
              }
             
        for (i =0; i<(safeDiv(battleboardData.getMaxFreeTeams(),2)); i++) {
                  owner = battleboardData.getOwner(battleboardId, 2, i);
                  id = battleboardData.getTileIDByOwner(battleboardId,owner);
                 petId = battleboardData.getPetbyTileId(battleboardId, id);
                 PetCardData.transferPet(address(this), winners[i], petId);
              }    
       }
          if ((battleboardData.getNumTeams(battleboardId,1) == 0) && (battleboardData.getNumTeams(battleboardId,2) != 0)) {
        
       
        
        for (i =0; i<(safeDiv(battleboardData.getMaxFreeTeams(),2)); i++) {
                  owner = battleboardData.getOwner(battleboardId, 2, i);
                  id = battleboardData.getTileIDByOwner(battleboardId,owner);
                 petId = battleboardData.getPetbyTileId(battleboardId, id);
                 PetCardData.transferPet(address(this), owner, petId);
                winners.push(owner); 
              }
             
        for (i =0; i<(safeDiv(battleboardData.getMaxFreeTeams(),2)); i++) {
                  owner = battleboardData.getOwner(battleboardId, 1, i);
                  id = battleboardData.getTileIDByOwner(battleboardId,owner);
                 petId = battleboardData.getPetbyTileId(battleboardId, id);
                 PetCardData.transferPet(address(this), winners[i], petId);
              }    
       }
   }
       
   
        function getInitialHP (uint64 angelId, uint64 petId, uint64 accessoryId) public constant returns (uint32 hp, uint16 petAuraComposite) {
           IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
           
            
           uint16 temp;
           uint16 tempComposite;
           uint8 aura;
           (,,temp,aura,,,,,,,) = angelCardData.getAngel(angelId);
           if (aura == 3) {temp += 100;}  
           tempComposite = temp;
            
           (,,,,temp,,,,,,) = angelCardData.getAngel(angelId);
           tempComposite += temp;
            
            uint8 petAuraColor;
             (petAuraComposite, petAuraColor) = findAuraComposite (petId, accessoryId);
            hp = (aurasCompatible(angelId,petAuraColor)+ petAuraComposite + tempComposite);
            
            return;
        }
       
       function addTeam1(uint64 angelId, uint64 petId, uint64 accessoryId, uint16 battleboardId) external payable {
            
           checkTeamToAdd(angelId,petId,accessoryId);
            IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
             
           uint32 hp;
           uint16 petPower;
           uint16 speed = getSpeed(petId,accessoryId);
           (hp, petPower) = getInitialHP(angelId,petId, accessoryId);
           battleboardData.createTile(battleboardId, 1, uint8(speed), getNewTeamPositionAndCheck(battleboardId, 1, angelId), hp, petPower + speed,angelId, petId, msg.sender, 1);
           battleboardData.addTeamtoBoard(battleboardId, msg.sender,1);
            
           addRandomTile(battleboardId, 1);
           takePet(petId);
       }
       
          function addTeam2(uint64 angelId, uint64 petId, uint64 accessoryId, uint16 battleboardId) external payable {
           
           checkTeamToAdd(angelId,petId,accessoryId);
            IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
             
           uint32 hp;
           uint16 petPower;
           uint16 speed = getSpeed(petId,accessoryId);
           (hp, petPower) = getInitialHP(angelId,petId, accessoryId);
           battleboardData.createTile(battleboardId, 1, uint8(speed), getNewTeamPositionAndCheck(battleboardId, 2, angelId), hp, petPower + speed,angelId, petId, msg.sender, 2);
           battleboardData.addTeamtoBoard(battleboardId, msg.sender,2);
            
           addRandomTile(battleboardId, 1);
           takePet(petId);
       }
       
       function getSpeed(uint64 petId, uint64 accessoryId) private constant returns (uint16) {
            
           IAccessoryData accessoryData = IAccessoryData(accessoryDataContract);
           IPetCardData petCardData = IPetCardData(petCardDataContract);

       uint16 temp;
       uint8 accessorySeriesId;
         (,,,temp,,,,,,) = petCardData.getPet(petId);
          
           (,accessorySeriesId,) = accessoryData.getAccessory(accessoryId);
           if (accessorySeriesId == 5) {temp += 5;}
            if (accessorySeriesId == 6) {temp += 10;}
            return temp;
  
       }
          
        function getNewTeamPositionAndCheck (uint16 battleboardId,uint8 team, uint64 angelId) private constant returns (uint8) {
            IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
            uint8 numTeams1;
            uint8 numTeams2;
             uint8 position;
             uint8 restrictions;
            bool isLive;
        
            
             (,isLive,,,,,restrictions,, numTeams1,numTeams2,,) = battleboardData.getBattleboard(battleboardId);
               
             if (restrictionsAllow(angelId, restrictions) == false) {revert();} 
            if (isLive== true) {revert();}  
             if (team == 1) {
                if (numTeams1 == 0) {position = 10;}
               if (numTeams1 ==1) {position = 12;}
               if (numTeams1 == 2) {position = 14;}
               if (numTeams1 >=3) {revert();}
           }
               if (team == 2) {
               if (numTeams2 == 0) {position = 50;}
               if (numTeams2 == 1) {position = 52;}
               if (numTeams2 == 2) {position = 54;}
               if (numTeams2 >=3) {revert();}
           }
           return position;
        }  
          
          function checkTeamToAdd(uint64 angelId, uint64 petId, uint64 accessoryId) private constant {
               if ((checkExistsOwnedAngel(angelId) == false) || (checkExistsOwnedPet(petId)== false) || (checkExistsOwnedAccessory(accessoryId) == false)) {revert();}
          }
          
             
             function addRandomTile(uint16 _battleboardId, uint8 seed) private  {
             IBattleboardData battleboardData = IBattleboardData(battleboardDataContract);
    
           uint8 newTileType;
           uint8 newTilePower;
           
            
              
     
     
     
     
     
     
     
     
     
     
     
    
           
           uint8 chance = getRandomNumber(100,0,seed);
             
              if (chance <=30)  {
                 
                newTileType = getRandomNumber(5,3,seed);
                newTilePower = getRandomNumber(30,10,seed);
            }
                if ((chance >=30) && (chance <50)) {
                 
                newTileType = 7;
                newTilePower = getRandomNumber(45,15,seed);
            }
             if ((chance >=50) && (chance <60)) {
                 
                newTileType = 6;
                newTilePower = getRandomNumber(5,1,seed);
            }
            if ((chance >=60) && (chance <80)) {
                 
                newTileType = 9;
                newTilePower = getRandomNumber(64,1,seed);
            }
            if ((chance >=80) && (chance <90)) {
                 
                newTileType = 10;
                newTilePower = getRandomNumber(2,0,seed);
            }
            if (chance >=90) {
                 
                newTileType = 11;
                newTilePower = getRandomNumber(4,1,seed);
            }
            
                
         uint8 position = getRandomNumber(49,15,seed);
           
           
           
           if (battleboardData.getTileIDbyPosition(_battleboardId, position)!= 0) {
              
              position = getRandomNumber(49,15,msg.sender);
              if (battleboardData.getTileIDbyPosition(_battleboardId, position)!= 0) {
               position = getRandomNumber(49,15,msg.sender);
                if (battleboardData.getTileIDbyPosition(_battleboardId, position)!= 0) { 
                   position = getRandomNumber(49,15,msg.sender);
                if (battleboardData.getTileIDbyPosition(_battleboardId, position)!= 0) {revert();}
              }
           }
           }
         battleboardData.createTile(_battleboardId,newTileType, newTilePower, position, 0, 0, 0, 0, address(this),0);
       }
       
       function aurasCompatible(uint64 angel1ID, uint8  _petAuraColor ) private constant returns (uint8) {
            uint8 compatibility = 0;
            
        IAngelCardData angelCardData = IAngelCardData(angelCardDataContract);
          uint8 _angel1Aura;
         (,,,_angel1Aura,,,,,,,) = angelCardData.getAngel(angel1ID);
            if (_petAuraColor == 1) {
                if ((_angel1Aura == 2) || (_angel1Aura == 3) || (_angel1Aura == 4)) {compatibility++;}
            }
            if (_petAuraColor == 2) {
                if ((_angel1Aura == 0) || (_angel1Aura == 2) || (_angel1Aura == 5)) {compatibility++;}
            }
            if (_petAuraColor == 3) {
                if ((_angel1Aura == 1) || (_angel1Aura == 3) || (_angel1Aura == 5)) {compatibility++;}
            }
        return compatibility*12;
            
        }
        
        function findAuraComposite(uint64 pet1ID, uint64 accessoryId) private constant returns (uint16 composite, uint8 color) {
        IPetCardData petCardData = IPetCardData(petCardDataContract);
        
       uint16 pet1auraRed;
       uint16 pet1auraBlue;
       uint16 pet1auraYellow;
        (,,,,pet1auraRed,pet1auraBlue,pet1auraYellow,,,) = petCardData.getPet(pet1ID);
        
          IAccessoryData accessoryData = IAccessoryData(accessoryDataContract);
           
           uint8 accessorySeriesID;
           
           (,accessorySeriesID,) = accessoryData.getAccessory(accessoryId);
        
        if (accessorySeriesID == 7) {pet1auraRed += 6;}
        if (accessorySeriesID == 8) {pet1auraRed += 12;}
        if (accessorySeriesID == 9) {pet1auraYellow += 6;}
        if (accessorySeriesID == 10) {pet1auraYellow += 12;}
        if (accessorySeriesID == 11) {pet1auraBlue += 6;}
        if (accessorySeriesID == 12) {pet1auraBlue += 12;}
        
       
            color = 1;  
            if (((pet1auraBlue) > (pet1auraRed)) && ((pet1auraBlue) > (pet1auraYellow))) {color = 2;}
            if (((pet1auraYellow)> (pet1auraRed)) && ((pet1auraYellow)> (pet1auraBlue))) {color = 3;}
            composite = (pet1auraRed) + (pet1auraYellow) + (pet1auraBlue);
            return;
            }
        
          function kill() onlyCREATOR external {
        selfdestruct(creatorAddress);
    }
                function withdrawEther()  onlyCREATOR external {
    
    creatorAddress.transfer(this.balance);
}
          
}