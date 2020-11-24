 

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
contract CryptoEngineerInterface {
    uint256 public prizePool = 0;
    address public gameSponsor;

    function subVirus(address  , uint256  ) public pure {}
    function claimPrizePool(address  , uint256  ) public pure {} 
    function isContractMiniGame() public pure returns( bool  ) {}
    function fallback() external payable {}
}
contract CryptoMiningWarInterface {
    uint256 public deadline; 
    function subCrystal( address  , uint256   ) public pure {}
}
contract MemoryFactoryInterface {
    uint256 public factoryTotal;

    function setFactoryToal(uint256  ) public {}
    function updateFactory(address  , uint256  , uint256  ) public {}
    function updateLevel(address  ) public {}
    function addProgram(address  , uint256  , uint256  ) public {}
    function subProgram(address  , uint256  , uint256  ) public {}

    function getPrograms(address  ) public view returns(uint256[]) {}
    function getLevel(address  ) public view returns(uint256  ) {}
    function getData(address  ) public view returns(uint256  , uint256  , uint256[]  ) {} 
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool _isContractMiniGame );
    function fallback() external payable;
}
contract CryptoProgramFactory {
	using SafeMath for uint256;

	address public administrator;

    uint256 private BASE_PRICE   = 0.1 ether; 
    uint256 private BASE_TIME    = 4 hours; 

    MemoryFactoryInterface   public Memory;
    CryptoMiningWarInterface public MiningWar;
    CryptoEngineerInterface  public Engineer;

    uint256 public miningWarDeadline;
     
    mapping(uint256 => Factory) public factories; 
     
    mapping(address => bool)    public miniGames; 
   
    struct Factory {
        uint256 level;
        uint256 crystals;
        uint256 programPriceByCrystals;
        uint256 programPriceByDarkCrystals;
        uint256 programValue;  
        uint256 eth;
        uint256 time;
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
    event UpdateFactory(address _addr, uint256 _crystals, uint256 _eth, uint256 _levelUp, uint256 _updateTime);
    event BuyProgarams(address _addr, uint256 _crystals, uint256 _darkCrystals, uint256[] _programs);
    constructor() public {
        administrator = msg.sender;
         
        setMiningWarInterface(0xf84c61bb982041c030b8580d1634f00fffb89059);
        setEngineerInterface(0x69fd0e5d0a93bf8bac02c154d343a8e3709adabf);
        setMemoryInterface(0xa2e6461e7a109ae070b9b064ca9448b301404784);
    }
    function initFactory() private 
    {       
         
        factories[0] = Factory(1, 100000,         10000,           0,                         10           ,BASE_PRICE * 0, BASE_TIME * 1);
        factories[1] = Factory(2, 500000,         20000,           0,                         15           ,BASE_PRICE * 1, BASE_TIME * 2);
        factories[2] = Factory(3, 1500000,        40000,           0,                         20           ,BASE_PRICE * 4, BASE_TIME * 3);
        factories[3] = Factory(4, 3000000,        80000,           0,                         5            ,BASE_PRICE * 5, BASE_TIME * 6);

        Memory.setFactoryToal(4);
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
     
     
     
    
    function setMemoryInterface(address _addr) public isAdministrator
    {
        Memory = MemoryFactoryInterface(_addr);
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
     
     
     
    function setContractMiniGame( address _contractAddress ) public isAdministrator 
    {
        MiniGameInterface MiniGame = MiniGameInterface( _contractAddress );
        if( MiniGame.isContractMiniGame() == false ) { revert(); }

        miniGames[_contractAddress] = true;
    }
    function removeContractMiniGame(address _contractAddress) public isAdministrator
    {
        miniGames[_contractAddress] = false;
    }
     
     
     
    function addFactory(
        uint256 _crystals, 
        uint256 _programPriceByCrystals,  
        uint256 _programPriceByDarkCrystals,  
        uint256 _programValue,  
        uint256 _eth, 
        uint256 _time
    ) public isAdministrator
    {
        uint256 factoryTotal = Memory.factoryTotal();
        factories[factoryTotal] = Factory(factoryTotal +1,_crystals,_programPriceByCrystals,_programPriceByDarkCrystals,_programValue,_eth,_time);
        factoryTotal += 1;
        Memory.setFactoryToal(factoryTotal);
    }
    function setProgramValue(uint256 _idx, uint256 _value) public isAdministrator
    {
        Factory storage f = factories[_idx]; 
        f.programValue = _value;
    }
    function setProgramPriceByCrystals(uint256 _idx, uint256 _value) public isAdministrator
    {
        Factory storage f = factories[_idx]; 
        f.programPriceByCrystals = _value;
    }
    function setProgramPriceByDarkCrystals(uint256 _idx, uint256 _value) public isAdministrator
    {
        Factory storage f = factories[_idx]; 
        f.programPriceByDarkCrystals = _value;
    }
     
     
     
     
    function startGame() public 
    {
        require(msg.sender == administrator);
        require(miningWarDeadline == 0);
        
        miningWarDeadline = MiningWar.deadline();

        initFactory();
    }
    function updateFactory() public payable 
    {
        require(miningWarDeadline > now);

        Memory.updateLevel(msg.sender);
        
        Factory memory f = factories[uint256(Memory.getLevel(msg.sender))]; 

        if (msg.value < f.eth) revert();

        MiningWar.subCrystal(msg.sender, f.crystals);

        uint256 updateTime = now + f.time;
        uint256 levelUp     = f.level;

        Memory.updateFactory(msg.sender, levelUp, updateTime);

        if (msg.value > 0) {
            uint256 fee = devFee(msg.value);
            address gameSponsor = Engineer.gameSponsor();
            gameSponsor.transfer(fee);
            administrator.transfer(fee);

            Engineer.fallback.value(SafeMath.sub(msg.value, 2 * fee));
        }

        emit UpdateFactory(msg.sender, f.crystals, msg.value, levelUp, updateTime);
    }

    function buyProgarams(uint256[] _programs) public
    {
        require(_programs.length <= Memory.factoryTotal());
        require(miningWarDeadline > now);

        Memory.updateLevel(msg.sender);

        uint256 factoryLevel = Memory.getLevel(msg.sender);
        uint256 crystals = 0;
        uint256 darkCrystals =0; 

        for (uint256 idx = 0; idx < _programs.length; idx ++) {
            Factory memory f = factories[idx];
            uint256 level = idx + 1;
            if (_programs[idx] > 0 && factoryLevel < level) revert();
            if (_programs[idx] > 0) {
                crystals     += SafeMath.mul(_programs[idx], f.programPriceByCrystals);
                darkCrystals += SafeMath.mul(_programs[idx], f.programPriceByDarkCrystals);
                Memory.addProgram(msg.sender, idx, _programs[idx]);
            }    
        }

        if (crystals > 0) MiningWar.subCrystal(msg.sender, crystals);
         
        emit BuyProgarams(msg.sender, crystals, darkCrystals, _programs);
    }
    function subPrograms(address _addr, uint256[] _programs) public onlyContractsMiniGame
    {
        uint256 factoryTotal = Memory.factoryTotal();
        require(_programs.length <= factoryTotal);

        for (uint256 idx = 0; idx < _programs.length; idx++) {
            if (_programs[idx] > 0) Memory.subProgram(_addr, idx, _programs[idx]);
        }
    }
    function getData(address _addr) 
    public
    view
    returns(
        uint256   _factoryTotal,
        uint256   _factoryLevel,
        uint256   _factoryTime,
        uint256[] _programs
    ) {
        _factoryTotal = Memory.factoryTotal();
        (_factoryLevel, _factoryTime, _programs) = Memory.getData(_addr);
    }
    function getProgramsValue() public view returns(uint256[]) {
        uint256 factoryTotal = Memory.factoryTotal();
        uint256[] memory _programsValue = new uint256[](factoryTotal);
        
        for(uint256 idx = 0; idx < factoryTotal; idx++) {
            Factory memory f    = factories[idx];
            _programsValue[idx] = f.programValue;
        }
        return _programsValue;
    }
     
     
    function devFee(uint256 _amount) private pure returns(uint256)
    {
        return SafeMath.div(SafeMath.mul(_amount, 5), 100);
    }
  
}