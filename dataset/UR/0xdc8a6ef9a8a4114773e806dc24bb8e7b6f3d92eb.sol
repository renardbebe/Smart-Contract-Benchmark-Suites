 

pragma solidity ^0.4.24;

 

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
contract CryptoEngineerInterface {
    uint256 public prizePool = 0;

    function subVirus(address  , uint256  ) public pure {}
    function claimPrizePool(address  , uint256  ) public pure {} 
    function fallback() public payable {}

    function isEngineerContract() external pure returns(bool) {}
}
interface CryptoMiningWarInterface {
    function addCrystal( address  , uint256   ) external pure;
    function subCrystal( address  , uint256   ) external pure;
    function isMiningWarContract() external pure returns(bool);
}
interface MiniGameInterface {
     function isContractMiniGame() external pure returns( bool _isContractMiniGame );
}
contract CryptoBossWannaCry is PullPayment{
    bool init = false;
	address public administrator;
    uint256 public bossRoundNumber;
    uint256 public BOSS_HP_DEFAULT = 10000000; 
    uint256 public HALF_TIME_ATK_BOSS = 0;
     
    uint256 constant public VIRUS_MINING_PERIOD = 86400; 
    uint256 public BOSS_DEF_DEFFAULT = 0;
    CryptoEngineerInterface public Engineer;
    CryptoMiningWarInterface public MiningWar;
    
     
    mapping(address => PlayerData) public players;
     
    mapping(uint256 => BossData) public bossData;

    mapping(address => bool)   public miniGames;
        
    struct PlayerData {
        uint256 currentBossRoundNumber;
        uint256 lastBossRoundNumber;
        uint256 win;
        uint256 share;
        uint256 dame;
        uint256 nextTimeAtk;
    }

    struct BossData {
        uint256 bossRoundNumber;
        uint256 bossHp;
        uint256 def;
        uint256 prizePool;
        address playerLastAtk;
        uint256 totalDame;
        bool ended;
    }
    event eventAttackBoss(
        uint256 bossRoundNumber,
        address playerAtk,
        uint256 virusAtk,
        uint256 dame,
        uint256 totalDame,
        uint256 timeAtk,
        bool isLastHit,
        uint256 crystalsReward
    );
    event eventEndAtkBoss(
        uint256 bossRoundNumber,
        address playerWin,
        uint256 ethBonus,
        uint256 bossHp,
        uint256 prizePool
    );
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

    constructor() public {
        administrator = msg.sender;
         
        setMiningWarInterface(0x65c347702b66ff8f1a28cf9a9768487fbe97765f);
        setEngineerInterface(0xb2d6000d4a7fe8b1358d54a9bc21f2badf91d849);
    }
    function () public payable
    {
        
    }
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }
    function isBossWannaCryContract() public pure returns(bool)
    {
        return true;
    }
     
    function setupMiniGame( uint256  , uint256   ) public
    {
    
    }
      
    function upgrade(address addr) public isAdministrator
    {
        selfdestruct(addr);
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
    function setContractsMiniGame( address _addr ) public isAdministrator 
    {
        MiniGameInterface MiniGame = MiniGameInterface( _addr );
        if( MiniGame.isContractMiniGame() == false ) { revert(); }

        miniGames[_addr] = true;
    }

    function setBossRoundNumber(uint256 _value) public isAdministrator
    {
        bossRoundNumber = _value;
    } 
     
    function removeContractMiniGame(address _addr) public isAdministrator
    {
        miniGames[_addr] = false;
    }

    function startGame() public isAdministrator
    {
        require(init == false);
        init = true;
        bossData[bossRoundNumber].ended = true;
    
        startNewBoss();
    }
     
    function setDefenceBoss(uint256 _value) public isAdministrator
    {
        BOSS_DEF_DEFFAULT = _value;  
    }
     
    function setBossHPDefault(uint256 _value) public isAdministrator
    {
        BOSS_HP_DEFAULT = _value;  
    }
    function setHalfTimeAtkBoss(uint256 _value) public isAdministrator
    {
        HALF_TIME_ATK_BOSS = _value;  
    }
    function startNewBoss() private
    {
        require(bossData[bossRoundNumber].ended == true);

        bossRoundNumber = bossRoundNumber + 1;

        uint256 bossHp = BOSS_HP_DEFAULT * bossRoundNumber;
         
        uint256 engineerPrizePool = Engineer.prizePool();
        uint256 prizePool = SafeMath.div(SafeMath.mul(engineerPrizePool, 5),100);
        Engineer.claimPrizePool(address(this), prizePool); 

        bossData[bossRoundNumber] = BossData(bossRoundNumber, bossHp, BOSS_DEF_DEFFAULT, prizePool, 0x0, 0, false);
    }
    function endAtkBoss() private 
    {
        require(bossData[bossRoundNumber].ended == false);
        require(bossData[bossRoundNumber].totalDame >= bossData[bossRoundNumber].bossHp);

        BossData storage b = bossData[bossRoundNumber];
        b.ended = true;
          
        uint256 ethBonus = SafeMath.div( SafeMath.mul(b.prizePool, 5), 100 );

        if (b.playerLastAtk != 0x0) {
            PlayerData storage p = players[b.playerLastAtk];
            p.win =  p.win + ethBonus;

            uint256 share = SafeMath.div(SafeMath.mul(SafeMath.mul(b.prizePool, 95), p.dame), SafeMath.mul(b.totalDame, 100));
            ethBonus += share;
        }

        emit eventEndAtkBoss(bossRoundNumber, b.playerLastAtk, ethBonus, b.bossHp, b.prizePool);
        startNewBoss();
    }
     
    function atkBoss(uint256 _value) public disableContract
    {
        require(bossData[bossRoundNumber].ended == false);
        require(bossData[bossRoundNumber].totalDame < bossData[bossRoundNumber].bossHp);
        require(players[msg.sender].nextTimeAtk <= now);

        Engineer.subVirus(msg.sender, _value);
        
        uint256 rate = 50 + randomNumber(msg.sender, now, 60);  
        
        uint256 atk = SafeMath.div(SafeMath.mul(_value, rate), 100);
        
        updateShareETH(msg.sender);

         
        BossData storage b = bossData[bossRoundNumber];
        
        uint256 currentTotalDame = b.totalDame;
        uint256 dame = 0;
        if (atk > b.def) {
            dame = SafeMath.sub(atk, b.def);
        }

        b.totalDame = SafeMath.min(SafeMath.add(currentTotalDame, dame), b.bossHp);
        b.playerLastAtk = msg.sender;

        dame = SafeMath.sub(b.totalDame, currentTotalDame);

         
        uint256 crystalsBonus = SafeMath.div(SafeMath.mul(dame, 5), 100);
        MiningWar.addCrystal(msg.sender, crystalsBonus);
         
        PlayerData storage p = players[msg.sender];

        p.nextTimeAtk = now + HALF_TIME_ATK_BOSS;

        if (p.currentBossRoundNumber == bossRoundNumber) {
            p.dame = SafeMath.add(p.dame, dame);
        } else {
            p.currentBossRoundNumber = bossRoundNumber;
            p.dame = dame;
        }

        bool isLastHit;
        if (b.totalDame >= b.bossHp) {
            isLastHit = true;
            endAtkBoss();
        }
        
         
        emit eventAttackBoss(b.bossRoundNumber, msg.sender, _value, dame, p.dame, now, isLastHit, crystalsBonus);
    }
 
    function updateShareETH(address _addr) private
    {
        PlayerData storage p = players[_addr];
        
        if ( 
            bossData[p.currentBossRoundNumber].ended == true &&
            p.lastBossRoundNumber < p.currentBossRoundNumber
            ) {
            p.share = SafeMath.add(p.share, calculateShareETH(_addr, p.currentBossRoundNumber));
            p.lastBossRoundNumber = p.currentBossRoundNumber;
        }
    }

     
    function calculateShareETH(address _addr, uint256 _bossRoundNumber) public view returns(uint256 _share)
    {
        PlayerData memory p = players[_addr];
        BossData memory b = bossData[_bossRoundNumber];
        if ( 
            p.lastBossRoundNumber >= p.currentBossRoundNumber && 
            p.currentBossRoundNumber != 0 
            ) {
            _share = 0;
        } else {
            if (b.totalDame == 0) return 0;
            _share = SafeMath.div(SafeMath.mul(SafeMath.mul(b.prizePool, 95), p.dame), SafeMath.mul(b.totalDame, 100));  
        } 
        if (b.ended == false)  _share = 0;
    }
    function getCurrentReward(address _addr) public view returns(uint256 _currentReward)
    {
        PlayerData memory p = players[_addr];
        _currentReward = SafeMath.add(p.win, p.share);
        _currentReward += calculateShareETH(_addr, p.currentBossRoundNumber);
    }

    function withdrawReward(address _addr) public 
    {
        updateShareETH(_addr);
        
        PlayerData storage p = players[_addr];
        
        uint256 reward = SafeMath.add(p.share, p.win);
        if (address(this).balance >= reward && reward > 0) {
            _addr.transfer(reward);
             
            p.win = 0;
            p.share = 0;
        }
    }
     
     
     
    function devFee(uint256 _amount) private pure returns(uint256)
    {
        return SafeMath.div(SafeMath.mul(_amount, 5), 100);
    }
    function randomNumber(address _addr, uint256 randNonce, uint256 _maxNumber) private returns(uint256)
    {
        return uint256(keccak256(abi.encodePacked(now, _addr, randNonce))) % _maxNumber;
    }
}