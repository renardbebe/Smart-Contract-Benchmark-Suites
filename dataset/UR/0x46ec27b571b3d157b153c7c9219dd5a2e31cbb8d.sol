 

pragma solidity ^0.4.25;

 

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

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
contract CryptoMiningWarInterface {
    uint256 public roundNumber;
    uint256 public deadline; 
    function addHashrate( address  , uint256   ) external pure {}
    function subCrystal( address  , uint256   ) external pure {}
    function addCrystal( address  , uint256   ) external pure {}
    function isMiningWarContract() external pure returns(bool);
}
interface CryptoEngineerInterface {
    function addVirus(address  , uint256  ) external pure;
    function subVirus(address  , uint256  ) external pure;

    function isContractMiniGame() external pure returns( bool  );
    function isEngineerContract() external pure returns(bool);
    function calCurrentVirus(address  ) external view returns(uint256  );
    function calCurrentCrystals(address  ) external pure returns(uint256  );
}
interface CryptoProgramFactoryInterface {
    function isContractMiniGame() external pure returns( bool   );
    function isProgramFactoryContract() external pure returns(bool);

    function subPrograms(address  , uint256[]  ) external;
    function getData(address _addr) external pure returns(uint256  , uint256  , uint256[]  );
    function getProgramsValue() external pure returns(uint256[]);
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool   );
    function fallback() external payable;
}
interface MemoryArenaInterface {
    function setVirusDef(address  , uint256  ) external pure;
    function setNextTimeAtk(address  , uint256  ) external pure;
    function setEndTimeUnequalledDef(address  , uint256  ) external pure;
    function setNextTimeArenaBonus(address  , uint256  ) external pure;
    function setBonusPoint(address  , uint256  ) external pure;

    function getData(address _addr) external view returns(uint256  , uint256  , uint256  , uint256  , uint256  );
    function isMemoryArenaContract() external pure returns(bool);
}
contract CryptoArena {
	using SafeMath for uint256;

	address public administrator;

    uint256 private VIRUS_NORMAL = 0;
    uint256 private HALF_TIME_ATK= 60 * 15;  
    uint256 private CRTSTAL_MINING_PERIOD = 86400;
    uint256 private VIRUS_MINING_PERIOD   = 86400;
    uint256 private ROUND_TIME_MINING_WAR = 86400 * 7;
    uint256 private TIME_DAY = 24 hours;

    CryptoMiningWarInterface      public MiningWar;
    CryptoEngineerInterface       public Engineer;
    CryptoProgramFactoryInterface public Factory;
    MemoryArenaInterface          public MemoryArena;

     
    mapping(uint256 => Virus)   public viruses;
      
    mapping(address => bool)    public miniGames; 

    mapping(uint256 => uint256) public arenaBonus; 
   
    struct Virus {
        uint256 atk;
        uint256 def;
    }
    modifier isAdministrator()
    {
        require(msg.sender == administrator);
        _;
    }
    modifier onlyContractsMiniGame() 
    {
        require(miniGames[msg.sender] == true);
        _;
    }
    event Attack(address atkAddress, address defAddress, bool victory, uint256 reward, uint256 virusAtkDead, uint256 virusDefDead, uint256 atk, uint256 def, uint256 round);  
    event Programs(uint256 programLv1, uint256 programLv2, uint256 programLv3, uint256 programLv4);
    event ArenaBonus(address player, uint256 bonus);

    constructor() public {
        administrator = msg.sender;
         
        setMiningWarInterface(0x1b002cd1ba79dfad65e8abfbb3a97826e4960fe5);
        setEngineerInterface(0xd7afbf5141a7f1d6b0473175f7a6b0a7954ed3d2);
        setFactoryInterface(0x0498e54b6598e96b7a42ade3d238378dc57b5bb2);
        setMemoryArenaInterface(0x5fafca56f6860dceeb6e7495a74a806545802895);

          
        viruses[VIRUS_NORMAL] = Virus(1,1);
         
        initArenaBonus();
    }
    function initArenaBonus() private 
    {
        arenaBonus[0] = 15000;
        arenaBonus[1] = 50000;
        arenaBonus[2] = 100000;
        arenaBonus[3] = 200000;
        arenaBonus[4] = 350000;
        arenaBonus[5] = 500000;
        arenaBonus[6] = 1500000;
    }
    function () public payable
    {
        
    }
     
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }
    function isArenaContract() public pure returns(bool)
    {
        return true;
    }
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
     
    function setupMiniGame( uint256  , uint256   ) public pure
    {

    }
     
     
     
    function setArenaBonus(uint256 idx, uint256 _value) public isAdministrator
    {
        arenaBonus[idx] = _value;
    }
     
     
     
    function setContractsMiniGame( address _addr ) public isAdministrator 
    {
        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        if( MiniGame.isContractMiniGame() == false ) revert(); 

        miniGames[_addr] = true;
    }
     
    function removeContractMiniGame(address _addr) public isAdministrator
    {
        miniGames[_addr] = false;
    }
     
     
     
    
    function setMiningWarInterface(address _addr) public isAdministrator
    {
        CryptoMiningWarInterface miningWarInterface = CryptoMiningWarInterface(_addr);

        require(miningWarInterface.isMiningWarContract() == true);
                
        MiningWar = miningWarInterface;
    }
    function setEngineerInterface(address _addr) public isAdministrator
    {
        CryptoEngineerInterface engineerInterface = CryptoEngineerInterface(_addr);
        
        require(engineerInterface.isEngineerContract() == true);

        Engineer = engineerInterface;
    }
    
    function setFactoryInterface(address _addr) public isAdministrator
    {
        CryptoProgramFactoryInterface factoryInterface = CryptoProgramFactoryInterface(_addr);
        
         

        Factory = factoryInterface;
    }
    function setMemoryArenaInterface(address _addr) public isAdministrator
    {
        MemoryArenaInterface memoryArenaInterface = MemoryArenaInterface(_addr);
        
        require(memoryArenaInterface.isMemoryArenaContract() == true);

        MemoryArena = memoryArenaInterface;
    }

     
     
     
     
    function setVirusDef(address _addr, uint256 _value) public isAdministrator
    {
        MemoryArena.setVirusDef(_addr, SafeMath.mul(_value, VIRUS_MINING_PERIOD));
    }
    function setAtkNowForPlayer(address _addr) public onlyContractsMiniGame
    {
        MemoryArena.setNextTimeAtk(_addr, now);
    }
    function setPlayerVirusDef(address _addr, uint256 _value) public onlyContractsMiniGame
    {     
        MemoryArena.setVirusDef(_addr, SafeMath.mul(_value, VIRUS_MINING_PERIOD));
    } 
    function addVirusDef(address _addr, uint256 _virus) public
    {
        require(miniGames[msg.sender] == true || msg.sender == _addr);

        Engineer.subVirus(_addr, _virus);
        
        uint256 virusDef;
        (virusDef, , , ,) = MemoryArena.getData(_addr);
        virusDef += SafeMath.mul(_virus, VIRUS_MINING_PERIOD);

        MemoryArena.setVirusDef(_addr, virusDef);
    }
    function subVirusDef(address _addr, uint256 _virus) public onlyContractsMiniGame
    {        
        _virus = SafeMath.mul(_virus, VIRUS_MINING_PERIOD);
        uint256 virusDef;
        (virusDef, , , ,) = MemoryArena.getData(_addr);

        if (virusDef < _virus) revert();

        virusDef -= _virus;
        MemoryArena.setVirusDef(_addr, virusDef);
    }
    function addTimeUnequalledDefence(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        uint256 endTimeUnequalledDef;
        (,,endTimeUnequalledDef,,) = MemoryArena.getData(_addr);
        if (endTimeUnequalledDef < now) endTimeUnequalledDef = now;
        
        MemoryArena.setEndTimeUnequalledDef(_addr, SafeMath.add(endTimeUnequalledDef, _value));
    }
     
     
     
    function setVirusInfo(uint256 _atk, uint256 _def) public isAdministrator
    {
        Virus storage v = viruses[VIRUS_NORMAL];
        v.atk = _atk;
        v.def = _def;
    }

     
    function attack(address _defAddress, uint256 _virus, uint256[] _programs) public
    {
        require(validateAttack(msg.sender, _defAddress) == true);
        require(_programs.length == 4);
        require(validatePrograms(_programs) == true);

        Factory.subPrograms(msg.sender, _programs);

        MemoryArena.setNextTimeAtk(msg.sender, now + HALF_TIME_ATK);
        uint256 virusDef;  
        (virusDef, , , ,) = MemoryArena.getData(_defAddress);
        if (virusDef == 0) return endAttack(_defAddress, true, 0, 0, SafeMath.mul(_virus, VIRUS_MINING_PERIOD), 0, 1, _programs);

        Engineer.subVirus(msg.sender, _virus);

        uint256[] memory programsValue = Factory.getProgramsValue(); 

        firstAttack(_defAddress, SafeMath.mul(_virus, VIRUS_MINING_PERIOD), _programs, programsValue, virusDef);
    }
    function firstAttack(address _defAddress, uint256 _virus, uint256[] _programs, uint256[] programsValue, uint256 virusDef) 
    private 
    {
        uint256 atk;
        uint256 def;
        uint256 virusAtkDead;
        uint256 virusDefDead;
        bool victory;
        
        (atk, def, virusAtkDead, virusDefDead, victory) = getResultAtk(msg.sender, _defAddress, _virus, _programs, programsValue, virusDef, true);

        if (_virus > virusAtkDead)
            Engineer.addVirus(msg.sender, SafeMath.div(SafeMath.sub(_virus, virusAtkDead), VIRUS_MINING_PERIOD));
        
        endAttack(_defAddress, victory, SafeMath.div(virusAtkDead, VIRUS_MINING_PERIOD), SafeMath.div(virusDefDead, VIRUS_MINING_PERIOD), atk, def, 1, _programs);

        if (victory == false && _programs[1] == 1)
            againAttack(_defAddress, SafeMath.div(SafeMath.mul(SafeMath.mul(_virus, VIRUS_MINING_PERIOD), programsValue[1]), 100), programsValue);  
    }
    function againAttack(address _defAddress, uint256 _virus, uint256[] programsValue) private returns(bool victory)
    {
        uint256 virusDef;  
        (virusDef, , , ,) = MemoryArena.getData(_defAddress);
        uint256[] memory programs;
        
        uint256 atk;
        uint256 def;
        uint256 virusDefDead;
        
        (atk, def, , virusDefDead, victory) = getResultAtk(msg.sender, _defAddress, _virus, programs, programsValue, virusDef, false);

        endAttack(_defAddress, victory, 0,  SafeMath.div(virusDefDead, VIRUS_MINING_PERIOD), atk, def, 2, programs);
    }
    function getResultAtk(address atkAddress, address defAddress, uint256 _virus, uint256[] _programs, uint256[] programsValue, uint256 virusDef, bool isFirstAttack)
    private  
    returns(
        uint256 atk,
        uint256 def,
        uint256 virusAtkDead,
        uint256 virusDefDead,
        bool victory
    ){
        atk             = _virus; 
        uint256 rateAtk = 50 + randomNumber(atkAddress, 1, 101);
        uint256 rateDef = 50 + randomNumber(defAddress, rateAtk, 101);
        
        if (_programs[0] == 1 && isFirstAttack == true)  
            atk += SafeMath.div(SafeMath.mul(atk, programsValue[0]), 100); 
        if (_programs[3] == 1 && isFirstAttack == true) { 
            virusDef = SafeMath.sub(virusDef, SafeMath.div(SafeMath.mul(virusDef, programsValue[3]), 100)); 
            MemoryArena.setVirusDef(defAddress, virusDef); 
        }    
        atk = SafeMath.div(SafeMath.mul(SafeMath.mul(atk, viruses[VIRUS_NORMAL].atk), rateAtk), 100);
        def = SafeMath.div(SafeMath.mul(SafeMath.mul(virusDef, viruses[VIRUS_NORMAL].def), rateDef), 100);

        if (_programs[2] == 1 && isFirstAttack == true)   
            atk += SafeMath.div(SafeMath.mul(atk, programsValue[2]), 100);

        if (atk >= def) {
            virusAtkDead = SafeMath.min(_virus, SafeMath.div(SafeMath.mul(def, 100), SafeMath.mul(viruses[VIRUS_NORMAL].atk, rateAtk)));
            virusDefDead = virusDef;
            victory      = true;
        } else {
            virusAtkDead = _virus;
            virusDefDead = SafeMath.min(virusDef, SafeMath.div(SafeMath.mul(atk, 100), SafeMath.mul(viruses[VIRUS_NORMAL].def, rateDef)));
        }

        MemoryArena.setVirusDef(defAddress, SafeMath.sub(virusDef, virusDefDead));
    }
    function endAttack(address _defAddress, bool victory, uint256 virusAtkDead, uint256 virusDefDead, uint256 atk, uint256 def, uint256 round, uint256[] programs) private 
    {
        uint256 reward = 0;
        if (victory == true) {
            uint256 pDefCrystals = Engineer.calCurrentCrystals(_defAddress);
             
            uint256 rate = 10 + randomNumber(_defAddress, pDefCrystals, 41);
            reward = SafeMath.div(SafeMath.mul(pDefCrystals, rate),100);

            if (reward > 0) {
                MiningWar.subCrystal(_defAddress, reward);    
                MiningWar.addCrystal(msg.sender, reward);
            }
            updateBonusPoint(msg.sender);
        }
        emit Attack(msg.sender, _defAddress, victory, reward, virusAtkDead, virusDefDead, atk, def, round);
        if (round == 1) emit Programs( programs[0], programs[1], programs[2], programs[3]);
    }
    function updateBonusPoint(address _addr) private
    {
        uint256 nextTimeArenaBonus;
        uint256 bonusPoint;
        (,,,nextTimeArenaBonus, bonusPoint) = MemoryArena.getData(_addr);

        if (now >= nextTimeArenaBonus) {
            bonusPoint += 1;
        }
        if (bonusPoint == 3) {
            bonusPoint = 0;
            nextTimeArenaBonus = now + TIME_DAY;
            uint256 noDayStartMiningWar = getNoDayStartMiningWar();
            MiningWar.addCrystal(_addr, arenaBonus[noDayStartMiningWar - 1]);

            emit ArenaBonus(_addr, arenaBonus[noDayStartMiningWar - 1]);
        }
        MemoryArena.setNextTimeArenaBonus(_addr, nextTimeArenaBonus);
        MemoryArena.setBonusPoint(_addr, bonusPoint);
    }
    function validateAttack(address _atkAddress, address _defAddress) private view returns(bool _status) 
    {
        uint256 nextTimeAtk;
        (,nextTimeAtk,,,) = MemoryArena.getData(_atkAddress); 
        if (
            _atkAddress != _defAddress &&
            nextTimeAtk <= now &&
            canAttack(_defAddress) == true
            ) {
            _status = true;
        }
    } 
    function validatePrograms(uint256[] _programs) private pure returns(bool _status)
    {
        _status = true;
        for(uint256 idx = 0; idx < _programs.length; idx++) {
            if (_programs[idx] != 0 && _programs[idx] != 1) _status = false;
        }
    }
    function canAttack(address _addr) private view returns(bool _canAtk)
    {
        uint256 endTimeUnequalledDef;
        (,,endTimeUnequalledDef,,) = MemoryArena.getData(_addr); 
        if ( 
            endTimeUnequalledDef < now &&
            Engineer.calCurrentCrystals(_addr) >= 5000
            ) {
            _canAtk = true;
        }
    }
     
     
     
    function getData(address _addr) 
    public
    view
    returns(
        uint256 _virusDef,
        uint256 _nextTimeAtk,
        uint256 _endTimeUnequalledDef,
        bool    _canAtk,
         
        uint256 _currentVirus, 
         
        uint256 _currentCrystals
    ) {
        (_virusDef, _nextTimeAtk, _endTimeUnequalledDef, ,) = MemoryArena.getData(_addr);
        _virusDef            = SafeMath.div(_virusDef, VIRUS_MINING_PERIOD);
        _currentVirus        = SafeMath.div(Engineer.calCurrentVirus(_addr), VIRUS_MINING_PERIOD);
        _currentCrystals     = Engineer.calCurrentCrystals(_addr);
        _canAtk              = canAttack(_addr);
    }
    function getDataForUI(address _addr) 
    public
    view
    returns(
        uint256 _virusDef,
        uint256 _nextTimeAtk,
        uint256 _endTimeUnequalledDef,
        uint256 _nextTimeArenaBonus,
        uint256 _bonusPoint,
        bool    _canAtk,
         
        uint256 _currentVirus, 
         
        uint256 _currentCrystals
    ) {
        (_virusDef, _nextTimeAtk, _endTimeUnequalledDef, _nextTimeArenaBonus, _bonusPoint) = MemoryArena.getData(_addr);
        _virusDef            = SafeMath.div(_virusDef, VIRUS_MINING_PERIOD);
        _currentVirus        = SafeMath.div(Engineer.calCurrentVirus(_addr), VIRUS_MINING_PERIOD);
        _currentCrystals     = Engineer.calCurrentCrystals(_addr);
        _canAtk              = canAttack(_addr);
    }
     
     
     
    function randomNumber(address _addr, uint256 randNonce, uint256 _maxNumber) private view returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(now, _addr, randNonce))) % _maxNumber;
    }
    function getNoDayStartMiningWar() public view returns(uint256)
    {
        uint256 deadline = MiningWar.deadline();
        if (deadline < now) return 7;
        uint256 timeEndMiningWar  = deadline - now;
        uint256 noDayEndMiningWar = SafeMath.div(timeEndMiningWar, TIME_DAY);
        return SafeMath.sub(7, noDayEndMiningWar);
    }
}