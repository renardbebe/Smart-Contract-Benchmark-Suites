 

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
contract PullPayment {
  using SafeMath for uint256;

  mapping(address => uint256) public payments;
  uint256 public totalPayments;

   
  function withdrawPayments() public {
    address payee = msg.sender;
    uint256 payment = payments[payee];

    require(payment != 0);
    require(address(this).balance >= payment);

    totalPayments = totalPayments.sub(payment);
    payments[payee] = 0;

    payee.transfer(payment);
  }

   
  function asyncSend(address dest, uint256 amount) internal {
    payments[dest] = payments[dest].add(amount);
    totalPayments = totalPayments.add(amount);
  }
}
interface CryptoMiningWarInterface {
    function calCurrentCrystals(address  ) external view returns(uint256  );
    function subCrystal( address  , uint256   ) external pure;
    function fallback() external payable;
    function isMiningWarContract() external pure returns(bool);
}
interface MiniGameInterface {
    function isContractMiniGame() external pure returns( bool _isContractMiniGame );
    function fallback() external payable;
}
contract CryptoEngineer is PullPayment{
     
	address public administrator;
    uint256 public prizePool = 0;
    uint256 public numberOfEngineer = 8;
    uint256 public numberOfBoosts = 5;
    address public gameSponsor;
    uint256 public gameSponsorPrice = 0.32 ether;
    uint256 public VIRUS_MINING_PERIOD = 86400; 
    
     
    uint256 public CRTSTAL_MINING_PERIOD = 86400;
    uint256 public BASE_PRICE = 0.01 ether;

    address public miningWarAddress; 
    CryptoMiningWarInterface   public MiningWar;
    
     
    mapping(address => Player) public players;
     
    mapping(uint256 => BoostData) public boostData;
     
    mapping(uint256 => EngineerData) public engineers;
    
     
    mapping(address => bool) public miniGames; 
    
    struct Player {
        mapping(uint256 => uint256) engineersCount;
        uint256 virusNumber;
        uint256 research;
        uint256 lastUpdateTime;
        bool endLoadOldData;
    }
    struct BoostData {
        address owner;
        uint256 boostRate;
        uint256 basePrice;
    }
    struct EngineerData {
        uint256 basePrice;
        uint256 baseETH;
        uint256 baseResearch;
        uint256 limit;
    }
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
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

    event BuyEngineer(address _addr, uint256[8] engineerNumbers, uint256 _crytalsPrice, uint256 _ethPrice, uint256 _researchBuy);
    event BuyBooster(address _addr, uint256 _boostIdx, address beneficiary);
    event ChangeVirus(address _addr, uint256 _virus, uint256 _type);  
    event BecomeGameSponsor(address _addr, uint256 _price);
    event UpdateResearch(address _addr, uint256 _currentResearch);

     
     
     
    constructor() public {
        administrator = msg.sender;

        initBoostData();
        initEngineer();
         
        setMiningWarInterface(0x65c347702b66ff8f1a28cf9a9768487fbe97765f);        
    }
    function initEngineer() private
    {
         
        engineers[0] = EngineerData(10,               BASE_PRICE * 0,   10,       10   );    
        engineers[1] = EngineerData(50,               BASE_PRICE * 1,   3356,     2    );    
        engineers[2] = EngineerData(200,              BASE_PRICE * 2,   8390,     4    );    
        engineers[3] = EngineerData(800,              BASE_PRICE * 4,   20972,    8    );    
        engineers[4] = EngineerData(3200,             BASE_PRICE * 8,   52430,    16   );    
        engineers[5] = EngineerData(12800,            BASE_PRICE * 16,  131072,   32   );    
        engineers[6] = EngineerData(102400,           BASE_PRICE * 32,  327680,   64   );    
        engineers[7] = EngineerData(819200,           BASE_PRICE * 64,  819200,   65536);    
    }
    function initBoostData() private 
    {
        boostData[0] = BoostData(0x0, 150, BASE_PRICE * 1);
        boostData[1] = BoostData(0x0, 175, BASE_PRICE * 2);
        boostData[2] = BoostData(0x0, 200, BASE_PRICE * 4);
        boostData[3] = BoostData(0x0, 225, BASE_PRICE * 8);
        boostData[4] = BoostData(0x0, 250, BASE_PRICE * 16);
    }
     
    function isContractMiniGame() public pure returns(bool _isContractMiniGame)
    {
    	_isContractMiniGame = true;
    }
    function isEngineerContract() public pure returns(bool)
    {
        return true;
    }
    function () public payable
    {
        addPrizePool(msg.value);
    }
     
    function setupMiniGame( uint256  , uint256   ) public
    {
        require(msg.sender == miningWarAddress);
        MiningWar.fallback.value(SafeMath.div(SafeMath.mul(prizePool, 5), 100))();
        prizePool = SafeMath.sub(prizePool, SafeMath.div(SafeMath.mul(prizePool, 5), 100));
    }
     
     
     
    function setMiningWarInterface(address _addr) public isAdministrator
    {
        CryptoMiningWarInterface miningWarInterface = CryptoMiningWarInterface(_addr);

        require(miningWarInterface.isMiningWarContract() == true);
        
        miningWarAddress = _addr;
        
        MiningWar = miningWarInterface;
    }
    function setContractsMiniGame( address _addr ) public isAdministrator 
    {
        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        
        if( MiniGame.isContractMiniGame() == false ) { revert(); }

        miniGames[_addr] = true;
    }
     
    function removeContractMiniGame(address _addr) public isAdministrator
    {
        miniGames[_addr] = false;
    }
     
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
    }
     
     
     
    function buyBooster(uint256 idx) public payable 
    {
        require(idx < numberOfBoosts);
        BoostData storage b = boostData[idx];

        if (msg.value < b.basePrice || msg.sender == b.owner) revert();
        
        address beneficiary = b.owner;
        uint256 devFeePrize = devFee(b.basePrice);
        
        distributedToOwner(devFeePrize);
        addMiningWarPrizePool(devFeePrize);
        addPrizePool(SafeMath.sub(msg.value, SafeMath.mul(devFeePrize,3)));
        
        updateVirus(msg.sender);

        if ( beneficiary != 0x0 ) updateVirus(beneficiary);
        
         
        b.owner = msg.sender;

        emit BuyBooster(msg.sender, idx, beneficiary );
    }
    function getBoosterData(uint256 idx) public view returns (address _owner,uint256 _boostRate, uint256 _basePrice)
    {
        require(idx < numberOfBoosts);
        BoostData memory b = boostData[idx];
        _owner = b.owner;
        _boostRate = b.boostRate; 
        _basePrice = b.basePrice;
    }
    function hasBooster(address addr) public view returns (uint256 _boostIdx)
    {         
        _boostIdx = 999;
        for(uint256 i = 0; i < numberOfBoosts; i++){
            uint256 revert_i = numberOfBoosts - i - 1;
            if(boostData[revert_i].owner == addr){
                _boostIdx = revert_i;
                break;
            }
        }
    }
     
     
     
     
    function becomeGameSponsor() public payable disableContract
    {
        uint256 gameSponsorPriceFee = SafeMath.div(SafeMath.mul(gameSponsorPrice, 150), 100);
        require(msg.value >= gameSponsorPriceFee);
        require(msg.sender != gameSponsor);
         
        uint256 repayPrice = SafeMath.div(SafeMath.mul(gameSponsorPrice, 110), 100);
        gameSponsor.transfer(repayPrice);
        
         
        addPrizePool(SafeMath.sub(msg.value, repayPrice));
         
        gameSponsor = msg.sender;
        gameSponsorPrice = gameSponsorPriceFee;

        emit BecomeGameSponsor(msg.sender, msg.value);
    }


    function addEngineer(address _addr, uint256 idx, uint256 _value) public isAdministrator
    {
        require(idx < numberOfEngineer);
        require(_value != 0);

        Player storage p = players[_addr];
        EngineerData memory e = engineers[idx];

        if (SafeMath.add(p.engineersCount[idx], _value) > e.limit) revert();

        updateVirus(_addr);

        p.engineersCount[idx] = SafeMath.add(p.engineersCount[idx], _value);

        updateResearch(_addr, SafeMath.mul(_value, e.baseResearch));
    }

     
     
     
    function setBoostData(uint256 idx, address owner, uint256 boostRate, uint256 basePrice)  public onlyContractsMiniGame
    {
        require(owner != 0x0);
        BoostData storage b = boostData[idx];
        b.owner     = owner;
        b.boostRate = boostRate;
        b.basePrice = basePrice;
    }
    function setGameSponsorInfo(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        gameSponsor      = _addr;
        gameSponsorPrice = _value;
    }
    function setPlayerLastUpdateTime(address _addr) public onlyContractsMiniGame
    {
        require(players[_addr].endLoadOldData == false);
        players[_addr].lastUpdateTime = now;
        players[_addr].endLoadOldData = true;
    }
    function setPlayerEngineersCount( address _addr, uint256 idx, uint256 _value) public onlyContractsMiniGame
    {
         players[_addr].engineersCount[idx] = _value;
    }
    function setPlayerResearch(address _addr, uint256 _value) public onlyContractsMiniGame
    {        
        players[_addr].research = _value;
    }
    function setPlayerVirusNumber(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        players[_addr].virusNumber = _value;
    }
    function addResearch(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);

        Player storage p = players[_addr];

        p.research = SafeMath.add(p.research, _value);

        emit UpdateResearch(_addr, p.research);
    }
    function subResearch(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);

        Player storage p = players[_addr];
        
        if (p.research < _value) revert();
        
        p.research = SafeMath.sub(p.research, _value);

        emit UpdateResearch(_addr, p.research);
    }
     
    function addVirus(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        Player storage p = players[_addr];

        uint256 additionalVirus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);
        
        p.virusNumber = SafeMath.add(p.virusNumber, additionalVirus);

        emit ChangeVirus(_addr, _value, 1);
    }
     
    function subVirus(address _addr, uint256 _value) public onlyContractsMiniGame
    {
        updateVirus(_addr);

        Player storage p = players[_addr];
        
        uint256 subtractVirus = SafeMath.mul(_value,VIRUS_MINING_PERIOD);
        
        if ( p.virusNumber < subtractVirus ) { revert(); }

        p.virusNumber = SafeMath.sub(p.virusNumber, subtractVirus);

        emit ChangeVirus(_addr, _value, 2);
    }
     
    function claimPrizePool(address _addr, uint256 _value) public onlyContractsMiniGame 
    {
        require(prizePool > _value);

        prizePool = SafeMath.sub(prizePool, _value);

        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        
        MiniGame.fallback.value(_value)();
    }
     
     
     
     
    function buyEngineer(uint256[8] engineerNumbers) public payable disableContract
    {        
        updateVirus(msg.sender);

        Player storage p = players[msg.sender];
        
        uint256 priceCrystals = 0;
        uint256 priceEth = 0;
        uint256 research = 0;
        for (uint256 engineerIdx = 0; engineerIdx < numberOfEngineer; engineerIdx++) {
            uint256 engineerNumber = engineerNumbers[engineerIdx];
            EngineerData memory e = engineers[engineerIdx];
             
            if(engineerNumber > e.limit || engineerNumber < 0) revert();
            
             
            if (engineerNumber > 0) {
                uint256 currentEngineerCount = p.engineersCount[engineerIdx];
                 
                p.engineersCount[engineerIdx] = SafeMath.min(e.limit, SafeMath.add(p.engineersCount[engineerIdx], engineerNumber));
                 
                research = SafeMath.add(research, SafeMath.mul(SafeMath.sub(p.engineersCount[engineerIdx],currentEngineerCount), e.baseResearch));
                 
                priceCrystals = SafeMath.add(priceCrystals, SafeMath.mul(e.basePrice, engineerNumber));
                priceEth = SafeMath.add(priceEth, SafeMath.mul(e.baseETH, engineerNumber));
            }
        }
         
        if (priceEth < msg.value) revert();

        uint256 devFeePrize = devFee(priceEth);
        distributedToOwner(devFeePrize);
        addMiningWarPrizePool(devFeePrize);
        addPrizePool(SafeMath.sub(msg.value, SafeMath.mul(devFeePrize,3)));        

         
        MiningWar.subCrystal(msg.sender, priceCrystals);
        updateResearch(msg.sender, research);

        emit BuyEngineer(msg.sender, engineerNumbers, priceCrystals, priceEth, research);
    }
      
    function updateVirus(address _addr) private
    {
        Player storage p = players[_addr]; 
        p.virusNumber = calCurrentVirus(_addr);
        p.lastUpdateTime = now;
    }
    function calCurrentVirus(address _addr) public view returns(uint256 _currentVirus)
    {
        Player memory p = players[_addr]; 
        uint256 secondsPassed = SafeMath.sub(now, p.lastUpdateTime);
        uint256 researchPerDay = getResearchPerDay(_addr);   
        _currentVirus = p.virusNumber;
        if (researchPerDay > 0) {
            _currentVirus = SafeMath.add(_currentVirus, SafeMath.mul(researchPerDay, secondsPassed));
        }   
    }
     
    function updateResearch(address _addr, uint256 _research) private 
    {
        Player storage p = players[_addr];
        p.research = SafeMath.add(p.research, _research);

        emit UpdateResearch(_addr, p.research);
    }
    function getResearchPerDay(address _addr) public view returns( uint256 _researchPerDay)
    {
        Player memory p = players[_addr];
        _researchPerDay =  p.research;
        uint256 boosterIdx = hasBooster(_addr);
        if (boosterIdx != 999) {
            BoostData memory b = boostData[boosterIdx];
            _researchPerDay = SafeMath.div(SafeMath.mul(_researchPerDay, b.boostRate), 100);
        } 
    }
     
    function getPlayerData(address _addr) 
    public 
    view 
    returns(
        uint256 _virusNumber, 
        uint256 _currentVirus,
        uint256 _research, 
        uint256 _researchPerDay, 
        uint256 _lastUpdateTime, 
        uint256[8] _engineersCount
    )
    {
        Player storage p = players[_addr];
        for ( uint256 idx = 0; idx < numberOfEngineer; idx++ ) {
            _engineersCount[idx] = p.engineersCount[idx];
        }
        _currentVirus= SafeMath.div(calCurrentVirus(_addr), VIRUS_MINING_PERIOD);
        _virusNumber = SafeMath.div(p.virusNumber, VIRUS_MINING_PERIOD);
        _lastUpdateTime = p.lastUpdateTime;
        _research = p.research;
        _researchPerDay = getResearchPerDay(_addr);
    }
     
     
     
    function addPrizePool(uint256 _value) private 
    {
        prizePool = SafeMath.add(prizePool, _value);
    }
     
    function addMiningWarPrizePool(uint256 _value) private
    {
        MiningWar.fallback.value(_value)();
    }
     
    function calCurrentCrystals(address _addr) public view returns(uint256 _currentCrystals)
    {
        _currentCrystals = SafeMath.div(MiningWar.calCurrentCrystals(_addr), CRTSTAL_MINING_PERIOD);
    }
    function devFee(uint256 _amount) private pure returns(uint256)
    {
        return SafeMath.div(SafeMath.mul(_amount, 5), 100);
    }
     
    function distributedToOwner(uint256 _value) private
    {
        gameSponsor.transfer(_value);
        administrator.transfer(_value);
    }
}