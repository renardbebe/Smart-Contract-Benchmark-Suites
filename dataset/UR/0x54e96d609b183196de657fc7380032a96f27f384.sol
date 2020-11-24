 

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
contract CryptoEngineerInterface {
    uint256 public prizePool = 0;

    function calculateCurrentVirus(address  ) public pure returns(uint256  ) {}
    function subVirus(address  , uint256  ) public {}
    function claimPrizePool(address  , uint256  ) public {} 
    function fallback() public payable {}
}
interface CryptoMiningWarInterface {
    function addCrystal( address  , uint256   ) external;
    function subCrystal( address  , uint256   ) external;
}
contract CryptoBossWannaCry is PullPayment{
    bool init = false;
	address public administrator;
    uint256 public bossRoundNumber;
    uint256 private randNonce;
    uint256 public BOSS_HP_DEFAULT = 10000000; 
    uint256 public HALF_TIME_ATK_BOSS = 0;
     
    uint256 constant public VIRUS_MINING_PERIOD = 86400; 
    uint256 public BOSS_DEF_DEFFAULT = 0;
    CryptoEngineerInterface public EngineerContract;
    CryptoMiningWarInterface public MiningwarContract;
    
     
    mapping(address => PlayerData) public players;
     
    mapping(uint256 => BossData) public bossData;
        
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
        uint256 timeAtk,
        bool isLastHit,
        uint256 crystalsReward
    );
    event eventEndAtkBoss(
        uint256 bossRoundNumber,
        address playerWin,
        uint256 ethBonus
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
         
        EngineerContract = CryptoEngineerInterface(0x69fd0e5d0a93bf8bac02c154d343a8e3709adabf);
        MiningwarContract = CryptoMiningWarInterface(0xf84c61bb982041c030b8580d1634f00fffb89059);
    }
    function () public payable
    {
        
    }
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }

     
    function setupMiniGame( uint256  , uint256   ) public
    {
    
    }
      
    function upgrade(address addr) public 
    {
        require(msg.sender == administrator);
        selfdestruct(addr);
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
         
        uint256 engineerPrizePool = getEngineerPrizePool();
        uint256 prizePool = SafeMath.div(SafeMath.mul(engineerPrizePool, 5),100);
        EngineerContract.claimPrizePool(address(this), prizePool); 

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
        }

        emit eventEndAtkBoss(bossRoundNumber, b.playerLastAtk, ethBonus);
        startNewBoss();
    }
     
    function atkBoss(uint256 _value) public disableContract
    {
        require(bossData[bossRoundNumber].ended == false);
        require(bossData[bossRoundNumber].totalDame < bossData[bossRoundNumber].bossHp);
        require(players[msg.sender].nextTimeAtk <= now);

        uint256 currentVirus = getEngineerCurrentVirus(msg.sender);        
        if (_value > currentVirus) { revert(); }
        EngineerContract.subVirus(msg.sender, _value);
        
        uint256 rate = 50 + randomNumber(msg.sender, 60);  
        
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
        MiningwarContract.addCrystal(msg.sender, crystalsBonus);
         
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
        
         
        emit eventAttackBoss(b.bossRoundNumber, msg.sender, _value, dame, now, isLastHit, crystalsBonus);
    }
 
    function updateShareETH(address _addr) private
    {
        PlayerData storage p = players[_addr];
        
        if ( 
            bossData[p.currentBossRoundNumber].ended == true &&
            p.lastBossRoundNumber < p.currentBossRoundNumber
            ) {
            p.share = SafeMath.add(p.share, calculateShareETH(msg.sender, p.currentBossRoundNumber));
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
            _share = SafeMath.div(SafeMath.mul(SafeMath.mul(b.prizePool, 95), p.dame), SafeMath.mul(b.totalDame, 100));  
        } 
        if (b.ended == false) {
            _share = 0;
        }
    }

    function withdrawReward() public disableContract
    {
        updateShareETH(msg.sender);
        PlayerData storage p = players[msg.sender];
        
        uint256 reward = SafeMath.add(p.share, p.win);
        msg.sender.send(reward);
         
        p.win = 0;
        p.share = 0;
    }
     
     
     
    function devFee(uint256 _amount) private pure returns(uint256)
    {
        return SafeMath.div(SafeMath.mul(_amount, 5), 100);
    }
    function randomNumber(address _addr, uint256 _maxNumber) private returns(uint256)
    {
        randNonce = randNonce + 1;
        return uint256(keccak256(abi.encodePacked(now, _addr, randNonce))) % _maxNumber;
    }
    function getEngineerPrizePool() private view returns(uint256 _prizePool)
    {
        _prizePool = EngineerContract.prizePool();
    }
    function getEngineerCurrentVirus(address _addr) private view returns(uint256 _currentVirus)
    {
        _currentVirus = EngineerContract.calculateCurrentVirus(_addr);
        _currentVirus = SafeMath.div(_currentVirus, VIRUS_MINING_PERIOD);
    }
}