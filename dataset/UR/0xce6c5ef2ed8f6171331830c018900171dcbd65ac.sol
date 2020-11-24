 

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
    uint256 public deadline; 
    function subCrystal( address  , uint256   ) public pure {}
    function addCrystal( address  , uint256   ) public pure {}
}
interface CryptoEngineerInterface {
    function addVirus(address  , uint256  ) external pure;
    function subVirus(address  , uint256  ) external pure;

    function isContractMiniGame() external pure returns( bool  );
    function calculateCurrentVirus(address  ) external view returns(uint256  );
    function calCurrentCrystals(address  ) external pure returns(uint256  );
}
interface CryptoProgramFactoryInterface {
    function isContractMiniGame() external pure returns( bool   );

    function subPrograms(address  , uint256[]  ) external;
    function getData(address _addr) external pure returns(uint256  , uint256  , uint256[]  );
     function getProgramsValue() external pure returns(uint256[]);
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool   );
    function fallback() external payable;
}
contract CrryptoArena {
	using SafeMath for uint256;

	address public administrator;

    uint256 public VIRUS_NORMAL = 0;
    uint256 public HALF_TIME_ATK= 60 * 15;  
    uint256 public CRTSTAL_MINING_PERIOD = 86400;
    uint256 public VIRUS_MINING_PERIOD   = 86400;
   
    CryptoMiningWarInterface      public MiningWar;
    CryptoEngineerInterface       public Engineer;
    CryptoProgramFactoryInterface public Factory;

    uint256 miningWarDeadline;
     
     
    mapping(address => Player) public players;

    mapping(uint256 => Virus)  public viruses;
      
    mapping(address => bool)   public miniGames; 
   
    struct Player {
        uint256 virusDef;
        uint256 nextTimeAtk;
        uint256 endTimeUnequalledDef;
    }
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

    constructor() public {
        administrator = msg.sender;
         
        setMiningWarInterface(0xf84c61bb982041c030b8580d1634f00fffb89059);
        setEngineerInterface(0x69fd0e5d0a93bf8bac02c154d343a8e3709adabf);
        setFactoryInterface(0x6fa883afde9bc8d9bec0fc7bff25db3c71864402);

          
        viruses[VIRUS_NORMAL] = Virus(1,1);
    }
    function () public payable
    {
        
    }
     
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
     
    function setupMiniGame( uint256  , uint256 _miningWarDeadline ) public
    {
        miningWarDeadline = _miningWarDeadline;   
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
        MiningWar = CryptoMiningWarInterface(_addr);
    }
    function setEngineerInterface(address _addr) public isAdministrator
    {
        CryptoEngineerInterface engineerInterface = CryptoEngineerInterface(_addr);
        
        require(engineerInterface.isContractMiniGame() == true);

        Engineer = engineerInterface;
    }
    
    function setFactoryInterface(address _addr) public isAdministrator
    {
        CryptoProgramFactoryInterface factoryInterface = CryptoProgramFactoryInterface(_addr);
        
        require(factoryInterface.isContractMiniGame() == true);

        Factory = factoryInterface;
    }

     
     
     
     
    function setAtkNowForPlayer(address _addr) public onlyContractsMiniGame
    {
        Player storage p = players[_addr];
        p.nextTimeAtk = now;
    }
    function addVirusDef(address _addr, uint256 _virus) public
    {
        require(miniGames[msg.sender] == true || msg.sender == _addr);

        Engineer.subVirus(_addr, _virus);

        Player storage p = players[_addr];

        p.virusDef += SafeMath.mul(_virus, VIRUS_MINING_PERIOD);
    }
    function subVirusDef(address _addr, uint256 _virus) public onlyContractsMiniGame
    {        
        _virus = SafeMath.mul(_virus, VIRUS_MINING_PERIOD);
        require(players[_addr].virusDef >= _virus);

        Player storage p = players[_addr];

        p.virusDef -= _virus;
    }
    function addTimeUnequalledDefence(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        Player storage p = players[_addr];
        uint256 currentTimeUnequalled = p.endTimeUnequalledDef;
        if (currentTimeUnequalled < now) currentTimeUnequalled = now;
        
        p.endTimeUnequalledDef = SafeMath.add(currentTimeUnequalled, _value);
    }
     
     
     
    function setVirusInfo(uint256 _atk, uint256 _def) public isAdministrator
    {
        Virus storage v = viruses[VIRUS_NORMAL];
        v.atk = _atk;
        v.def = _def;
    }


     
    function startGame() public 
    {
        require(msg.sender == administrator);
        require(miningWarDeadline == 0);
        
        miningWarDeadline = MiningWar.deadline();
    }
     
    function attack(address _defAddress, uint256 _virus, uint256[] _programs) public
    {
        require(validateAttack(msg.sender, _defAddress) == true);
        require(_programs.length == 4);
        require(validatePrograms(_programs) == true);

        Factory.subPrograms(msg.sender, _programs);

        Engineer.subVirus(msg.sender, _virus);

        uint256[] memory programsValue = Factory.getProgramsValue(); 

        bool victory;
        uint256 atk;
        uint256 def;
        uint256 virusAtkDead;
        uint256 virusDefDead;   
        
        (victory, atk, def, virusAtkDead, virusDefDead) = firstAttack(_defAddress, SafeMath.mul(_virus, VIRUS_MINING_PERIOD), _programs, programsValue);

        endAttack(_defAddress, victory, SafeMath.div(virusAtkDead, VIRUS_MINING_PERIOD), SafeMath.div(virusDefDead, VIRUS_MINING_PERIOD), atk, def, 1, _programs);

        if (_programs[1] == 1 && victory == false)  
            againAttack(_defAddress, SafeMath.div(SafeMath.mul(SafeMath.mul(_virus, VIRUS_MINING_PERIOD), programsValue[1]), 100));  

        players[msg.sender].nextTimeAtk = now + HALF_TIME_ATK;
    }
    function firstAttack(address _defAddress, uint256 _virus, uint256[] _programs, uint256[] programsValue) 
    private 
    returns(
        bool victory,
        uint256 atk,
        uint256 def,
        uint256 virusAtkDead,
        uint256 virusDefDead        
        )
    {
        Player storage pDef = players[_defAddress];

        atk             = _virus; 
        uint256 rateAtk = 50 + randomNumber(msg.sender, 1, 101);
        uint256 rateDef = 50 + randomNumber(_defAddress, rateAtk, 101);

        if (_programs[0] == 1)  
            atk += SafeMath.div(SafeMath.mul(atk, programsValue[0]), 100); 
        if (_programs[3] == 1)  
            pDef.virusDef = SafeMath.sub(pDef.virusDef, SafeMath.div(SafeMath.mul(pDef.virusDef, programsValue[3]), 100)); 
            
        atk = SafeMath.div(SafeMath.mul(SafeMath.mul(atk, viruses[VIRUS_NORMAL].atk), rateAtk), 100);
        def = SafeMath.div(SafeMath.mul(SafeMath.mul(pDef.virusDef, viruses[VIRUS_NORMAL].def), rateDef), 100);

        if (_programs[2] == 1)   
            atk += SafeMath.div(SafeMath.mul(atk, programsValue[2]), 100);

        if (atk >= def) {
            virusAtkDead = SafeMath.min(_virus, SafeMath.div(SafeMath.mul(def, 100), SafeMath.mul(viruses[VIRUS_NORMAL].atk, rateAtk)));
            virusDefDead = pDef.virusDef;
            victory      = true;
        } else {
            virusAtkDead = _virus;
            virusDefDead = SafeMath.min(pDef.virusDef, SafeMath.div(SafeMath.mul(atk, 100), SafeMath.mul(viruses[VIRUS_NORMAL].def, rateDef)));
        }

        pDef.virusDef = SafeMath.sub(pDef.virusDef, virusDefDead);

        if (_virus > virusAtkDead) 
            Engineer.addVirus(msg.sender, SafeMath.div(SafeMath.sub(_virus, virusAtkDead), VIRUS_MINING_PERIOD));

    }
    function againAttack(address _defAddress, uint256 _virus) private returns(bool victory)
    {
        Player storage pDef = players[_defAddress];
         
        Virus memory v = viruses[VIRUS_NORMAL];

        uint256 rateAtk = 50 + randomNumber(msg.sender, 1, 101);
        uint256 rateDef = 50 + randomNumber(_defAddress, rateAtk, 101);

        uint256 atk = SafeMath.div(SafeMath.mul(SafeMath.mul(_virus, v.atk), rateAtk), 100);
        uint256 def = SafeMath.div(SafeMath.mul(SafeMath.mul(pDef.virusDef, v.def), rateDef), 100);
        uint256 virusDefDead = 0;
        uint256[] memory programs;
        if (atk >= def) {
            virusDefDead = pDef.virusDef;
            victory = true;
        } else {
            virusDefDead = SafeMath.min(pDef.virusDef, SafeMath.div(SafeMath.mul(atk, 100), SafeMath.mul(v.def, rateDef)));
        }

        pDef.virusDef = SafeMath.sub(pDef.virusDef, virusDefDead);

        endAttack(_defAddress, victory, 0,  SafeMath.div(virusDefDead, VIRUS_MINING_PERIOD), atk, def, 2, programs);
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
        }
        emit Attack(msg.sender, _defAddress, victory, reward, virusAtkDead, virusDefDead, atk, def, round);
        if (round == 1) emit Programs( programs[0], programs[1], programs[2], programs[3]);
    }
    function validateAttack(address _atkAddress, address _defAddress) private view returns(bool _status) 
    {
        if (
            _atkAddress != _defAddress &&
            players[_atkAddress].nextTimeAtk <= now &&
            canAttack(_defAddress) == true
            ) {
            _status = true;
        }
    } 
    function validatePrograms(uint256[] _programs) private view returns(bool _status)
    {
        _status = true;
        for(uint256 idx = 0; idx < _programs.length; idx++) {
            if (_programs[idx] != 0 && _programs[idx] != 1) _status = false;
        }
    }
    function canAttack(address _addr) private view returns(bool _canAtk)
    {
        if ( 
            players[_addr].endTimeUnequalledDef < now &&
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
        Player memory p      = players[_addr];
        _virusDef            = SafeMath.div(p.virusDef, VIRUS_MINING_PERIOD);
        _nextTimeAtk         = p.nextTimeAtk;
        _endTimeUnequalledDef= p.endTimeUnequalledDef;
        _currentVirus        = SafeMath.div(Engineer.calculateCurrentVirus(_addr), VIRUS_MINING_PERIOD);
        _currentCrystals     = Engineer.calCurrentCrystals(_addr);
        _canAtk              = canAttack(_addr);
    }
     
     
     
    function randomNumber(address _addr, uint256 randNonce, uint256 _maxNumber) private view returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(now, _addr, randNonce))) % _maxNumber;
    }
}