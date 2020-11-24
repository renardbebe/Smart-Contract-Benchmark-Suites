 

pragma solidity ^0.4.23;

 
 
contract MonsterAccessControl {
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;
    address ceoBackupAddress;

     
    bool public paused = false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress || msg.sender == ceoBackupAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress ||
            msg.sender == ceoBackupAddress
        );
        _;
    }

     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));

        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));

        cooAddress = _newCOO;
    }

     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}

interface SaleClockAuction {
    function isSaleClockAuction() external view returns (bool);
    function createAuction(uint, uint, uint, uint, address) external;
    function withdrawBalance() external;
}
interface SiringClockAuction {
    function isSiringClockAuction() external view returns (bool);
    function createAuction(uint, uint, uint, uint, address) external;
    function withdrawBalance() external;
    function getCurrentPrice(uint256) external view returns (uint256);
    function bid(uint256) external payable;
}
interface MonsterBattles {
    function isBattleContract() external view returns (bool);
    function prepareForBattle(address, uint, uint, uint) external payable returns(uint);
    function withdrawFromBattle(address, uint, uint, uint) external returns(uint);
    function finishBattle(address, uint, uint, uint) external returns(uint, uint, uint);
    function withdrawBalance() external;
}
interface MonsterFood {
    function isMonsterFood() external view returns (bool);
    function feedMonster(address, uint, uint, uint, uint) external payable  returns(uint, uint, uint);
    function withdrawBalance() external;
}
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
    
 
interface MonsterConstants {
    function isMonsterConstants() external view returns (bool);
    function actionCooldowns(uint) external view returns (uint32);
    function actionCooldownsLength() external view returns(uint);
    
    function growCooldowns(uint) external view returns (uint32);
    function genToGrowCdIndex(uint) external view returns (uint8);
    function genToGrowCdIndexLength() external view returns(uint);
    
}
contract MonsterGeneticsInterface {
     
    function isMonsterGenetics() public pure returns (bool);

     
     
     
     
    function mixGenes(uint256 genesMatron, uint256 genesSire, uint256 targetBlock) public view returns (uint256 _result);
    
    function mixBattleGenes(uint256 genesMatron, uint256 genesSire, uint256 targetBlock) public view returns (uint256 _result);
}

library MonsterLib {
    
     
    uint constant UINT_MAX = uint(2) ** 256 - 1;
    
    function getBits(uint256 source, uint offset, uint count) public pure returns(uint256 bits_)
    {
        uint256 mask = (uint(2) ** count - 1) * uint(2) ** offset;
        return (source & mask) / uint(2) ** offset;
    }
    
    function setBits(uint target, uint bits, uint size, uint offset) public pure returns(uint)
    {
         
        uint256 truncateMask = uint(2) ** size - 1;
        bits = bits & truncateMask;
        
         
        bits = bits * uint(2) ** offset;
        
        uint clearMask = ((uint(2) ** size - 1) * (uint(2) ** offset)) ^ UINT_MAX;
        target = target & clearMask;
        target = target | bits;
        return target;
        
    }
    
     
     
     
     
     
    struct Monster {
         
         
        uint256 genes;
        
         
        uint64 birthTime;
        
         
         
         
         
         
        uint16 generation;
        
         
         
         
        uint64 cooldownEndTimestamp;
        
         
         
         
         
         
         
        uint32 matronId;
        uint32 sireId;
        
         
         
         
         
        uint32 siringWithId;
        
         
         
         
         
         
        uint16 cooldownIndex;
        
         
        uint64 battleGenes;
        
        uint8 activeGrowCooldownIndex;
        uint8 activeRestCooldownIndex;
        
        uint8 level;
        
        uint8 potionEffect;
        uint64 potionExpire;
        
        uint64 cooldownStartTimestamp;
        
        uint8 battleCounter;
    }
    

    function encodeMonsterBits(Monster mon) internal pure returns(uint p1, uint p2, uint p3)
    {
        p1 = mon.genes;
        
        p2 = 0;
        p2 = setBits(p2, mon.cooldownEndTimestamp, 64, 0);
        p2 = setBits(p2, mon.potionExpire, 64, 64);
        p2 = setBits(p2, mon.cooldownStartTimestamp, 64, 128);
        p2 = setBits(p2, mon.birthTime, 64, 192);
        
        p3 = 0;
        p3 = setBits(p3, mon.generation, 16, 0);
        p3 = setBits(p3, mon.matronId, 32, 16);
        p3 = setBits(p3, mon.sireId, 32, 48);
        p3 = setBits(p3, mon.siringWithId, 32, 80);
        p3 = setBits(p3, mon.cooldownIndex, 16, 112);
        p3 = setBits(p3, mon.battleGenes, 64, 128);
        p3 = setBits(p3, mon.activeGrowCooldownIndex, 8, 192);
        p3 = setBits(p3, mon.activeRestCooldownIndex, 8, 200);
        p3 = setBits(p3, mon.level, 8, 208);
        p3 = setBits(p3, mon.potionEffect, 8, 216);
        p3 = setBits(p3, mon.battleCounter, 8, 224);
    }
    
    function decodeMonsterBits(uint p1, uint p2, uint p3) internal pure returns(Monster mon)
    {
        mon = MonsterLib.Monster({
            genes: 0,
            birthTime: 0,
            cooldownEndTimestamp: 0,
            matronId: 0,
            sireId: 0,
            siringWithId: 0,
            cooldownIndex: 0,
            generation: 0,
            battleGenes: 0,
            level: 0,
            activeGrowCooldownIndex: 0,
            activeRestCooldownIndex: 0,
            potionEffect: 0,
            potionExpire: 0,
            cooldownStartTimestamp: 0,
            battleCounter: 0
        });
        
        mon.genes = p1;
        
        mon.cooldownEndTimestamp = uint64(getBits(p2, 0, 64));
        mon.potionExpire = uint64(getBits(p2, 64, 64));
        mon.cooldownStartTimestamp = uint64(getBits(p2, 128, 64));
        mon.birthTime = uint64(getBits(p2, 192, 64));
        mon.generation = uint16(getBits(p3, 0, 16));
        mon.matronId = uint32(getBits(p3, 16, 32));
        mon.sireId = uint32(getBits(p3, 48, 32));
        mon.siringWithId = uint32(getBits(p3, 80, 32));
        mon.cooldownIndex = uint16(getBits(p3, 112, 16));
        mon.battleGenes = uint64(getBits(p3, 128, 64));
        mon.activeGrowCooldownIndex = uint8(getBits(p3, 192, 8));
        mon.activeRestCooldownIndex = uint8(getBits(p3, 200, 8));
        mon.level = uint8(getBits(p3, 208, 8));
        mon.potionEffect = uint8(getBits(p3, 216, 8));
        mon.battleCounter = uint8(getBits(p3, 224, 8));
    }
}

 
contract Ownable {
  address public owner;


   
  constructor() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}


contract MonsterStorage is Ownable
{
    ERC721 public nonFungibleContract;
    
    bool public isMonsterStorage = true;
    
    constructor(address _nftAddress) public
    {
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
        MonsterLib.Monster memory mon = MonsterLib.decodeMonsterBits(uint(-1), 0, 0);
        _createMonster(mon);
        monsterIndexToOwner[0] = address(0);
    }
    
    function setTokenContract(address _nftAddress) external onlyOwner
    {
        ERC721 candidateContract = ERC721(_nftAddress);
        nonFungibleContract = candidateContract;
    }
    
    modifier onlyCore() {
        require(msg.sender != address(0) && msg.sender == address(nonFungibleContract));
        _;
    }
    
     

     
     
     
     
     
    MonsterLib.Monster[] monsters;
    
    uint256 public pregnantMonsters;
    
    function setPregnantMonsters(uint newValue) onlyCore public
    {
        pregnantMonsters = newValue;
    }
    
    function getMonstersCount() public view returns(uint) 
    {
        return monsters.length;
    }
    
    
     
     
    mapping (uint256 => address) public monsterIndexToOwner;
    
    function setMonsterIndexToOwner(uint index, address owner) onlyCore public
    {
        monsterIndexToOwner[index] = owner;
    }

     
     
    mapping (address => uint256) public ownershipTokenCount;
    
    function setOwnershipTokenCount(address owner, uint count) onlyCore public
    {
        ownershipTokenCount[owner] = count;
    }

     
     
     
    mapping (uint256 => address) public monsterIndexToApproved;
    
    function setMonsterIndexToApproved(uint index, address approved) onlyCore public
    {
        if(approved == address(0))
        {
            delete monsterIndexToApproved[index];
        }
        else
        {
            monsterIndexToApproved[index] = approved;
        }
    }
    
     
     
     
    mapping (uint256 => address) public sireAllowedToAddress;
    
    function setSireAllowedToAddress(uint index, address allowed) onlyCore public
    {
        if(allowed == address(0))
        {
            delete sireAllowedToAddress[index];
        }
        else 
        {
            sireAllowedToAddress[index] = allowed;
        }
    }
    
     
     
     
     

    function createMonster(uint p1, uint p2, uint p3)
        onlyCore
        public
        returns (uint)
    {

        MonsterLib.Monster memory mon = MonsterLib.decodeMonsterBits(p1, p2, p3);


        uint256 newMonsterId = _createMonster(mon);

         
         
        require(newMonsterId == uint256(uint32(newMonsterId)));

        return newMonsterId;
    }
    
    function _createMonster(MonsterLib.Monster mon) internal returns(uint)
    {
        uint256 newMonsterId = monsters.push(mon) - 1;
        
        return newMonsterId;
    }
    
    function setLevel(uint monsterId, uint level) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.level = uint8(level);
    }
    
    function setPotion(uint monsterId, uint potionEffect, uint potionExpire) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.potionEffect = uint8(potionEffect);
        mon.potionExpire = uint64(potionExpire);
    }
    

    function setBattleCounter(uint monsterId, uint battleCounter) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.battleCounter = uint8(battleCounter);
    }
    
    function setActionCooldown(uint monsterId, 
    uint cooldownIndex, 
    uint cooldownEndTimestamp, 
    uint cooldownStartTimestamp,
    uint activeGrowCooldownIndex, 
    uint activeRestCooldownIndex) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        mon.cooldownIndex = uint16(cooldownIndex);
        mon.cooldownEndTimestamp = uint64(cooldownEndTimestamp);
        mon.cooldownStartTimestamp = uint64(cooldownStartTimestamp);
        mon.activeRestCooldownIndex = uint8(activeRestCooldownIndex);
        mon.activeGrowCooldownIndex = uint8(activeGrowCooldownIndex);
    }
    
    function setSiringWith(uint monsterId, uint siringWithId) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        if(siringWithId == 0)
        {
            delete mon.siringWithId;
        }
        else
        {
            mon.siringWithId = uint32(siringWithId);
        }
    }
    
    
    function getMonsterBits(uint monsterId) public view returns(uint p1, uint p2, uint p3)
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        (p1, p2, p3) = MonsterLib.encodeMonsterBits(mon);
    }
    
    function setMonsterBits(uint monsterId, uint p1, uint p2, uint p3) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        MonsterLib.Monster memory mon2 = MonsterLib.decodeMonsterBits(p1, p2, p3);
        mon.cooldownIndex = mon2.cooldownIndex;
        mon.siringWithId = mon2.siringWithId;
        mon.activeGrowCooldownIndex = mon2.activeGrowCooldownIndex;
        mon.activeRestCooldownIndex = mon2.activeRestCooldownIndex;
        mon.level = mon2.level;
        mon.potionEffect = mon2.potionEffect;
        mon.cooldownEndTimestamp = mon2.cooldownEndTimestamp;
        mon.potionExpire = mon2.potionExpire;
        mon.cooldownStartTimestamp = mon2.cooldownStartTimestamp;
        mon.battleCounter = mon2.battleCounter;
        
    }
    
    function setMonsterBitsFull(uint monsterId, uint p1, uint p2, uint p3) onlyCore public
    {
        MonsterLib.Monster storage mon = monsters[monsterId];
        MonsterLib.Monster memory mon2 = MonsterLib.decodeMonsterBits(p1, p2, p3);
        mon.birthTime = mon2.birthTime;
        mon.generation = mon2.generation;
        mon.genes = mon2.genes;
        mon.battleGenes = mon2.battleGenes;
        mon.cooldownIndex = mon2.cooldownIndex;
        mon.matronId = mon2.matronId;
        mon.sireId = mon2.sireId;
        mon.siringWithId = mon2.siringWithId;
        mon.activeGrowCooldownIndex = mon2.activeGrowCooldownIndex;
        mon.activeRestCooldownIndex = mon2.activeRestCooldownIndex;
        mon.level = mon2.level;
        mon.potionEffect = mon2.potionEffect;
        mon.cooldownEndTimestamp = mon2.cooldownEndTimestamp;
        mon.potionExpire = mon2.potionExpire;
        mon.cooldownStartTimestamp = mon2.cooldownStartTimestamp;
        mon.battleCounter = mon2.battleCounter;
        
    }
}


 
 
contract MonsterBase is MonsterAccessControl {
     

     
     
     
    event Birth(address owner, uint256 monsterId, uint256 genes);

     
     
    event Transfer(address from, address to, uint256 tokenId);


     
     
     
    SaleClockAuction public saleAuction;
    SiringClockAuction public siringAuction;
    MonsterBattles public battlesContract;
    MonsterFood public monsterFood;
    MonsterStorage public monsterStorage;
    MonsterConstants public monsterConstants;
    
     
     
    MonsterGeneticsInterface public geneScience;
    
    function setMonsterStorageAddress(address _address) external onlyCEO {
        MonsterStorage candidateContract = MonsterStorage(_address);

         
        require(candidateContract.isMonsterStorage());

         
        monsterStorage = candidateContract;
    }
    
    function setMonsterConstantsAddress(address _address) external onlyCEO {
        MonsterConstants candidateContract = MonsterConstants(_address);

         
        require(candidateContract.isMonsterConstants());

         
        monsterConstants = candidateContract;
    }
    
     
     
    function setBattlesAddress(address _address) external onlyCEO {
        MonsterBattles candidateContract = MonsterBattles(_address);

         
        require(candidateContract.isBattleContract());

         
        battlesContract = candidateContract;
    }


     
    function _transfer(address _from, address _to, uint256 _tokenId) internal {
         
        uint count = monsterStorage.ownershipTokenCount(_to);
        monsterStorage.setOwnershipTokenCount(_to, count + 1);
        
         
        monsterStorage.setMonsterIndexToOwner(_tokenId, _to);
         
        if (_from != address(0)) {
            count =  monsterStorage.ownershipTokenCount(_from);
            monsterStorage.setOwnershipTokenCount(_from, count - 1);
             
            monsterStorage.setMonsterIndexToApproved(_tokenId, address(0));
        }
        
        if(_from == address(saleAuction))
        {
            MonsterLib.Monster memory monster = readMonster(_tokenId);
            if(monster.level == 0)
            {
                monsterStorage.setActionCooldown(_tokenId, 
                    monster.cooldownIndex, 
                    uint64(now + monsterConstants.growCooldowns(monster.activeGrowCooldownIndex)), 
                    now,
                    monster.activeGrowCooldownIndex, 
                    monster.activeRestCooldownIndex);
            }
        }
         
        emit Transfer(_from, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function _createMonster(
        uint256 _matronId,
        uint256 _sireId,
        uint256 _generation,
        uint256 _genes,
        uint256 _battleGenes,
        uint256 _level,
        address _owner
    )
        internal
        returns (uint)
    {
        require(_matronId == uint256(uint32(_matronId)));
        require(_sireId == uint256(uint32(_sireId)));
        require(_generation == uint256(uint16(_generation)));
        
        
        
        MonsterLib.Monster memory _monster = MonsterLib.Monster({
            genes: _genes,
            birthTime: uint64(now),
            cooldownEndTimestamp: 0,
            matronId: uint32(_matronId),
            sireId: uint32(_sireId),
            siringWithId: uint32(0),
            cooldownIndex: uint16(0),
            generation: uint16(_generation),
            battleGenes: uint64(_battleGenes),
            level: uint8(_level),
            activeGrowCooldownIndex: uint8(0),
            activeRestCooldownIndex: uint8(0),
            potionEffect: uint8(0),
            potionExpire: uint64(0),
            cooldownStartTimestamp: 0,
            battleCounter: uint8(0)
        });
        
        
        setMonsterGrow(_monster);
        (uint p1, uint p2, uint p3) = MonsterLib.encodeMonsterBits(_monster);
        
        uint monsterId = monsterStorage.createMonster(p1, p2, p3);

         
        emit Birth(
            _owner,
            monsterId,
            _genes
        );

         
         
        _transfer(0, _owner, monsterId);

        return monsterId;
    }
    
    function setMonsterGrow(MonsterLib.Monster monster) internal view
    {
          
        uint16 cooldownIndex = uint16(monster.generation / 2);
        if (cooldownIndex > 13) {
            cooldownIndex = 13;
        }
        
        monster.cooldownIndex = uint16(cooldownIndex);
        
        if(monster.level == 0)
        {
            uint gen = monster.generation;
            if(gen > monsterConstants.genToGrowCdIndexLength())
            {
                gen = monsterConstants.genToGrowCdIndexLength();
            }
            
            monster.activeGrowCooldownIndex = monsterConstants.genToGrowCdIndex(gen);
            monster.cooldownEndTimestamp = uint64(now + monsterConstants.growCooldowns(monster.activeGrowCooldownIndex));
            monster.cooldownStartTimestamp = uint64(now);
        }
    }
    
    function readMonster(uint monsterId) internal view returns(MonsterLib.Monster)
    {
        (uint p1, uint p2, uint p3) = monsterStorage.getMonsterBits(monsterId);
       
        MonsterLib.Monster memory mon = MonsterLib.decodeMonsterBits(p1, p2, p3);
         
        return mon;
    }
}


 
 
contract ERC721 {
     
    function totalSupply() public view returns (uint256 total);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function ownerOf(uint256 _tokenId) external view returns (address owner);
    function approve(address _to, uint256 _tokenId) external;
    function transfer(address _to, uint256 _tokenId) external;
    function transferFrom(address _from, address _to, uint256 _tokenId) external;

     
    event Transfer(address from, address to, uint256 tokenId);
    event Approval(address owner, address approved, uint256 tokenId);
}

 
 
 
contract MonsterOwnership is MonsterBase, ERC721 {

     
    string public constant name = "MonsterBit";
    string public constant symbol = "MB";

     
     
     
    function _owns(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterStorage.monsterIndexToOwner(_tokenId) == _claimant;
    }

     
     
     
    function _approvedFor(address _claimant, uint256 _tokenId) internal view returns (bool) {
        return monsterStorage.monsterIndexToApproved(_tokenId) == _claimant;
    }

     
     
     
     
     
    function _approve(uint256 _tokenId, address _approved) internal {
        monsterStorage.setMonsterIndexToApproved(_tokenId, _approved);
    }

     
     
     
    function balanceOf(address _owner) public view returns (uint256 count) {
        return monsterStorage.ownershipTokenCount(_owner);
    }

     
     
     
     
     
     
    function transfer(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
         
         
        require(_to != address(saleAuction));

         
        require(_owns(msg.sender, _tokenId));

         
        _transfer(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
    function approve(
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_owns(msg.sender, _tokenId));

         
        _approve(_tokenId, _to);

         
        emit Approval(msg.sender, _to, _tokenId);
    }

     
     
     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    )
        external
        whenNotPaused
    {
         
        require(_to != address(0));
         
         
         
        require(_to != address(this));
         
        require(_approvedFor(msg.sender, _tokenId));
        require(_owns(_from, _tokenId));

         
        _transfer(_from, _to, _tokenId);
    }

     
     
    function totalSupply() public view returns (uint) {
        return monsterStorage.getMonstersCount() - 1;
    }

     
     
    function ownerOf(uint256 _tokenId)
        external
        view
        returns (address owner)
    {
        owner = monsterStorage.monsterIndexToOwner(_tokenId);

        require(owner != address(0));
    }

     
     
     
     
     
     
    function tokensOfOwner(address _owner) external view returns(uint256[] ownerTokens) {
        uint256 tokenCount = balanceOf(_owner);

        if (tokenCount == 0) {
             
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 totalMonsters = totalSupply();
            uint256 resultIndex = 0;

             
             
            uint256 monsterId;

            for (monsterId = 1; monsterId <= totalMonsters; monsterId++) {
                if (monsterStorage.monsterIndexToOwner(monsterId) == _owner) {
                    result[resultIndex] = monsterId;
                    resultIndex++;
                }
            }

            return result;
        }
    }
}

 
contract MonsterBreeding is MonsterOwnership {

     
     
    event Pregnant(address owner, uint256 matronId, uint256 sireId, uint256 cooldownEndTimestamp);

     
     
     
    uint256 public autoBirthFee = 2 finney;
    uint256 public birthCommission = 5 finney;
    
    

    

     
     
    function setGeneScienceAddress(address _address) external onlyCEO {
        MonsterGeneticsInterface candidateContract = MonsterGeneticsInterface(_address);

         
        require(candidateContract.isMonsterGenetics());

         
        geneScience = candidateContract;
    }
    
    function setSiringAuctionAddress(address _address) external onlyCEO {
        SiringClockAuction candidateContract = SiringClockAuction(_address);

         
        require(candidateContract.isSiringClockAuction());

         
        siringAuction = candidateContract;
    }

     
     
     
    function _isReadyToBreed(MonsterLib.Monster _monster) internal view returns (bool) {
         
         
         
        return (_monster.siringWithId == 0) && (_monster.cooldownEndTimestamp <= uint64(now) && (_monster.level >= 1));
    }

     
     
     
    function _isSiringPermitted(uint256 _sireId, uint256 _matronId) internal view returns (bool) {
        address matronOwner = monsterStorage.monsterIndexToOwner(_matronId);
        address sireOwner = monsterStorage.monsterIndexToOwner(_sireId);

         
         
        return (matronOwner == sireOwner || monsterStorage.sireAllowedToAddress(_sireId) == matronOwner);
    }

     
     
     
    function _triggerCooldown(uint monsterId, MonsterLib.Monster _monster, uint increaseIndex) internal {

        uint activeRestCooldownIndex = _monster.cooldownIndex;
        uint cooldownEndTimestamp = uint64(monsterConstants.actionCooldowns(activeRestCooldownIndex) + now);
        uint newCooldownIndex = _monster.cooldownIndex;
         
         
         
        if(increaseIndex > 0)
        {
            if (newCooldownIndex + 1 < monsterConstants.actionCooldownsLength()) {
                newCooldownIndex += 1;
            }
        }
        
        monsterStorage.setActionCooldown(monsterId, newCooldownIndex, cooldownEndTimestamp, now, 0, activeRestCooldownIndex);
    }
    
    

     
     
     
     
    function approveSiring(address _addr, uint256 _sireId)
        external
        whenNotPaused
    {
        require(_owns(msg.sender, _sireId));
        monsterStorage.setSireAllowedToAddress(_sireId, _addr);
    }

     
     
     
    function setAutoBirthFee(uint256 val) external onlyCOO {
        autoBirthFee = val;
    }
    
    function setBirthCommission(uint val) external onlyCOO{
        birthCommission = val;
    }

     
     
    function _isReadyToGiveBirth(MonsterLib.Monster _matron) private view returns (bool) {
        return (_matron.siringWithId != 0) && (_matron.cooldownEndTimestamp <= now);
    }

     
     
     
    function isReadyToBreed(uint256 _monsterId)
        public
        view
        returns (bool)
    {
        require(_monsterId > 0);
        MonsterLib.Monster memory monster = readMonster(_monsterId);
        return _isReadyToBreed(monster);
    }
    
     
     
     
     
     
     
    function _isValidMatingPair(
        MonsterLib.Monster _matron,
        uint256 _matronId,
        MonsterLib.Monster _sire,
        uint256 _sireId
    )
        internal
        pure
        returns(bool)
    {
         
        if (_matronId == _sireId) {
            return false;
        }

         
        if (_matron.matronId == _sireId || _matron.sireId == _sireId) {
            return false;
        }
        if (_sire.matronId == _matronId || _sire.sireId == _matronId) {
            return false;
        }

         
         
        if (_sire.matronId == 0 || _matron.matronId == 0) {
            return true;
        }

         
        if (_sire.matronId == _matron.matronId || _sire.matronId == _matron.sireId) {
            return false;
        }
        if (_sire.sireId == _matron.matronId || _sire.sireId == _matron.sireId) {
            return false;
        }

         
        return true;
    }

     
     
    function isPregnant(uint256 _monsterId)
        public
        view
        returns (bool)
    {
        require(_monsterId > 0);
         
        MonsterLib.Monster memory monster = readMonster(_monsterId);
        return monster.siringWithId != 0;
    }

    

     
     
    function _canBreedWithViaAuction(uint256 _matronId, uint256 _sireId)
        internal
        view
        returns (bool)
    {
        MonsterLib.Monster memory matron = readMonster(_matronId);
        MonsterLib.Monster memory sire = readMonster(_sireId);
        return _isValidMatingPair(matron, _matronId, sire, _sireId);
    }

     
     
     
     
     
    function canBreedWith(uint256 _matronId, uint256 _sireId)
        external
        view
        returns(bool)
    {
        require(_matronId > 0);
        require(_sireId > 0);
        MonsterLib.Monster memory matron = readMonster(_matronId);
        MonsterLib.Monster memory sire = readMonster(_sireId);
        return _isValidMatingPair(matron, _matronId, sire, _sireId) &&
            _isSiringPermitted(_sireId, _matronId);
    }

     
     
    function _breedWith(uint256 _matronId, uint256 _sireId) internal {
         
        MonsterLib.Monster memory sire = readMonster(_sireId);
        MonsterLib.Monster memory matron = readMonster(_matronId);

         
        monsterStorage.setSiringWith(_matronId, _sireId);
        

         
        _triggerCooldown(_sireId, sire, 1);
        _triggerCooldown(_matronId, matron, 1);

         
         
        monsterStorage.setSireAllowedToAddress(_matronId, address(0));
        monsterStorage.setSireAllowedToAddress(_sireId, address(0));

        uint pregnantMonsters = monsterStorage.pregnantMonsters();
        monsterStorage.setPregnantMonsters(pregnantMonsters + 1);

         
        emit Pregnant(monsterStorage.monsterIndexToOwner(_matronId), _matronId, _sireId, matron.cooldownEndTimestamp);
    }

     
     
     
     
     
    function breedWithAuto(uint256 _matronId, uint256 _sireId)
        external
        payable
        whenNotPaused
    {
         
        require(msg.value >= autoBirthFee + birthCommission);

         
        require(_owns(msg.sender, _matronId));

         
         
         
         
         
         
         
         
         
         

         
         
         
        require(_isSiringPermitted(_sireId, _matronId));

         
        MonsterLib.Monster memory matron = readMonster(_matronId);

         
        require(_isReadyToBreed(matron));

         
        MonsterLib.Monster memory sire = readMonster(_sireId);

         
        require(_isReadyToBreed(sire));

         
        require(_isValidMatingPair(
            matron,
            _matronId,
            sire,
            _sireId
        ));

         
        _breedWith(_matronId, _sireId);
    }

     
     
     
     
     
     
     
     
    function giveBirth(uint256 _matronId)
        external
        whenNotPaused
        returns(uint256)
    {
         
        MonsterLib.Monster memory matron = readMonster(_matronId);

         
        require(matron.birthTime != 0);

         
        require(_isReadyToGiveBirth(matron));

         
        uint256 sireId = matron.siringWithId;
        MonsterLib.Monster memory sire = readMonster(sireId);

         
        uint16 parentGen = matron.generation;
        if (sire.generation > matron.generation) {
            parentGen = sire.generation;
        }

         
        uint256 childGenes = geneScience.mixGenes(matron.genes, sire.genes, block.number - 1);
        uint256 childBattleGenes = geneScience.mixBattleGenes(matron.battleGenes, sire.battleGenes, block.number - 1);

         
        address owner = monsterStorage.monsterIndexToOwner(_matronId);
        uint256 monsterId = _createMonster(_matronId, matron.siringWithId, parentGen + 1, childGenes, childBattleGenes, 0, owner);

         
         
        monsterStorage.setSiringWith(_matronId, 0);

        uint pregnantMonsters = monsterStorage.pregnantMonsters();
        monsterStorage.setPregnantMonsters(pregnantMonsters - 1);

        
         
        msg.sender.transfer(autoBirthFee);

         
        return monsterId;
    }
}


contract MonsterFeeding is MonsterBreeding {
    
    event MonsterFed(uint monsterId, uint growScore);
    
    
    function setMonsterFoodAddress(address _address) external onlyCEO {
        MonsterFood candidateContract = MonsterFood(_address);

         
        require(candidateContract.isMonsterFood());

         
        monsterFood = candidateContract;
    }
    
    function feedMonster(uint _monsterId, uint _foodCode) external payable{

        (uint p1, uint p2, uint p3) = monsterStorage.getMonsterBits(_monsterId);
        
        (p1, p2, p3) = monsterFood.feedMonster.value(msg.value)( msg.sender, _foodCode, p1, p2, p3);
        
        monsterStorage.setMonsterBits(_monsterId, p1, p2, p3);

        emit MonsterFed(_monsterId, 0);
        
    }
}

 
contract MonsterFighting is MonsterFeeding {
    
    
      function prepareForBattle(uint _param1, uint _param2, uint _param3) external payable returns(uint){
        require(_param1 > 0);
        require(_param2 > 0);
        require(_param3 > 0);
        
        for(uint i = 0; i < 5; i++){
            uint monsterId = MonsterLib.getBits(_param1, uint8(i * 32), uint8(32));
            require(_owns(msg.sender, monsterId));
            _approve(monsterId, address(battlesContract));
        }
        
        return battlesContract.prepareForBattle.value(msg.value)(msg.sender, _param1, _param2, _param3);
    }
    
    function withdrawFromBattle(uint _param1, uint _param2, uint _param3) external returns(uint){
        return battlesContract.withdrawFromBattle(msg.sender, _param1, _param2, _param3);
    }
    
    function finishBattle(uint _param1, uint _param2, uint _param3) external returns(uint) {
        (uint return1, uint return2, uint return3) = battlesContract.finishBattle(msg.sender, _param1, _param2, _param3);
        uint[10] memory monsterIds;
        uint i;
        uint monsterId;
        
        require(return3>=0);
        
        for(i = 0; i < 8; i++){
            monsterId = MonsterLib.getBits(return1, uint8(i * 32), uint8(32));
            monsterIds[i] = monsterId;
        }
        
        for(i = 0; i < 2; i++){
            monsterId = MonsterLib.getBits(return2, uint8(i * 32), uint8(32));
            monsterIds[i+8] = monsterId;
        }
        
        for(i = 0; i < 10; i++){
            monsterId = monsterIds[i];
            MonsterLib.Monster memory monster = readMonster(monsterId);
            uint bc = monster.battleCounter + 1;
            uint increaseIndex = 0;
            if(bc >= 10)
            {
                bc = 0;
                increaseIndex = 1;
            }
            monster.battleCounter = uint8(bc);
            _triggerCooldown(monsterId, monster, increaseIndex);
        }
        
        
    }
}

 
 
 
contract MonsterAuction is MonsterFighting {

     
     
     
     

     
     
    function setSaleAuctionAddress(address _address) external onlyCEO {
        SaleClockAuction candidateContract = SaleClockAuction(_address);

         
        require(candidateContract.isSaleClockAuction());

         
        saleAuction = candidateContract;
    }


     
     
    function createSaleAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _monsterId));
         
         
         
        require(!isPregnant(_monsterId));
        _approve(_monsterId, saleAuction);
         
         
        saleAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
    
     
     
     
    function createSiringAuction(
        uint256 _monsterId,
        uint256 _startingPrice,
        uint256 _endingPrice,
        uint256 _duration
    )
        external
        whenNotPaused
    {
         
         
         
        require(_owns(msg.sender, _monsterId));
        require(isReadyToBreed(_monsterId));
        _approve(_monsterId, siringAuction);
         
         
        siringAuction.createAuction(
            _monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            msg.sender
        );
    }
    
     
     
     
     
    function bidOnSiringAuction(
        uint256 _sireId,
        uint256 _matronId
    )
        external
        payable
        whenNotPaused
    {
         
        require(_owns(msg.sender, _matronId));
        require(isReadyToBreed(_matronId));
        require(_canBreedWithViaAuction(_matronId, _sireId));

         
        uint256 currentPrice = siringAuction.getCurrentPrice(_sireId);
        require(msg.value >= currentPrice + autoBirthFee);

         
        siringAuction.bid.value(msg.value - autoBirthFee)(_sireId);
        _breedWith(uint32(_matronId), uint32(_sireId));
    }


    
}

 
contract MonsterMinting is MonsterAuction {

     
    uint256 public constant PROMO_CREATION_LIMIT = 1000;
    uint256 public constant GEN0_CREATION_LIMIT = 45000;

    uint256 public constant GEN0_STARTING_PRICE = 1 ether;
    uint256 public constant GEN0_ENDING_PRICE = 0.1 ether;
    uint256 public constant GEN0_AUCTION_DURATION = 30 days;


     
    uint256 public promoCreatedCount;
    uint256 public gen0CreatedCount;


     
     
     
    function createPromoMonster(uint256 _genes, uint256 _battleGenes, uint256 _level, address _owner) external onlyCOO {
        address monsterOwner = _owner;
        if (monsterOwner == address(0)) {
             monsterOwner = cooAddress;
        }
        require(promoCreatedCount < PROMO_CREATION_LIMIT);

        promoCreatedCount++;
        _createMonster(0, 0, 0, _genes, _battleGenes, _level, monsterOwner);
    }
    
     
     
    function createGen0AuctionCustom(uint _genes, uint _battleGenes, uint _level, uint _startingPrice, uint _endingPrice, uint _duration) external onlyCOO {
        require(gen0CreatedCount < GEN0_CREATION_LIMIT);

        uint256 monsterId = _createMonster(0, 0, 0, _genes, _battleGenes, _level, address(this));
        _approve(monsterId, saleAuction);

        saleAuction.createAuction(
            monsterId,
            _startingPrice,
            _endingPrice,
            _duration,
            address(this)
        );

        gen0CreatedCount++;
    }
}

 
 
contract MonsterCore is MonsterMinting {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    address public newContractAddress;

     
    constructor(address _ceoBackupAddress) public {
        require(_ceoBackupAddress != address(0));
         
        paused = true;

         
        ceoAddress = msg.sender;
        ceoBackupAddress = _ceoBackupAddress;

         
        cooAddress = msg.sender;
    }

     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
         
        newContractAddress = _v2Address;
        emit ContractUpgrade(_v2Address);
    }

     
     
     
    function() external payable {
        require(
            msg.sender == address(saleAuction)
            ||
            msg.sender == address(siringAuction)
            ||
            msg.sender == address(battlesContract)
            ||
            msg.sender == address(monsterFood)
        );
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
        require(saleAuction != address(0));
        require(siringAuction != address(0));
        require(monsterFood != address(0));
        require(battlesContract != address(0));
        require(geneScience != address(0));
        require(monsterStorage != address(0));
        require(monsterConstants != address(0));
        require(newContractAddress == address(0));

         
        super.unpause();
    }

     
    function withdrawBalance() external onlyCFO {
        uint256 balance = address(this).balance;
        
        uint256 subtractFees = (monsterStorage.pregnantMonsters() + 1) * autoBirthFee;

        if (balance > subtractFees) {
            cfoAddress.transfer(balance - subtractFees);
        }

    }
    
     
     
     
    function withdrawDependentBalances() external onlyCLevel {
        saleAuction.withdrawBalance();
        siringAuction.withdrawBalance();
        battlesContract.withdrawBalance();
        monsterFood.withdrawBalance();
    }
}