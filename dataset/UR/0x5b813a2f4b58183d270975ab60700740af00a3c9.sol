 

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
contract CryptoMiningWarInterface {
	uint256 public roundNumber;
    uint256 public deadline; 
    function addCrystal( address _addr, uint256 _value ) public {}
}
contract CrystalAirdropGame {
	using SafeMath for uint256;

	address public administrator;
	 
    uint256 public MINI_GAME_TIME_DEFAULT = 60 * 5;
    uint256 public MINI_GAME_PRIZE_CRYSTAL = 100;
    uint256 public MINI_GAME_BETWEEN_TIME = 8 hours;
    uint256 public MINI_GAME_ADD_TIME_DEFAULT = 15;
    address public miningWarContractAddress;
    uint256 public miniGameId = 0;
    uint256 public noRoundMiniGame;
    CryptoMiningWarInterface public MiningWarContract;
     
    uint256 public MINI_GAME_BONUS = 100;
     
    mapping(uint256 => MiniGame) public minigames;
     
    mapping(address => PlayerData) public players;
   
    struct MiniGame {
        uint256 miningWarRoundNumber;
        bool ended; 
        uint256 prizeCrystal;
        uint256 startTime;
        uint256 endTime;
        address playerWin;
        uint256 totalPlayer;
    }
    struct PlayerData {
        uint256 currentMiniGameId;
        uint256 lastMiniGameId; 
        uint256 win;
        uint256 share;
        uint256 totalJoin;
        uint256 miningWarRoundNumber;
    }
    event eventEndMiniGame(
        address playerWin,
        uint256 crystalBonus
    );
    event eventJoinMiniGame(
        uint256 totalJoin
    );
    modifier disableContract()
    {
        require(tx.origin == msg.sender);
        _;
    }

    constructor() public {
        administrator = msg.sender;
         
        miningWarContractAddress = address(0xf84c61bb982041c030b8580d1634f00fffb89059);
        MiningWarContract = CryptoMiningWarInterface(miningWarContractAddress);
    }

     
    function isContractMiniGame() public pure returns( bool _isContractMiniGame )
    {
    	_isContractMiniGame = true;
    }

     
    function setDiscountBonus( uint256 _discountBonus ) public 
    {
        require( administrator == msg.sender );
        MINI_GAME_BONUS = _discountBonus;
    }

     
    function setupMiniGame( uint256 _miningWarRoundNumber, uint256 _miningWarDeadline ) public
    {
        require(minigames[ miniGameId ].miningWarRoundNumber < _miningWarRoundNumber && msg.sender == miningWarContractAddress);
         
        minigames[ miniGameId ] = MiniGame(0, true, 0, 0, 0, 0x0, 0);
        noRoundMiniGame = 0;         
        startMiniGame();	
    }

     
    function startMiniGame() private 
    {      
        uint256 miningWarRoundNumber = getMiningWarRoundNumber();

        require(minigames[ miniGameId ].ended == true);
         
        uint256 currentPrizeCrystal;
        if ( noRoundMiniGame == 0 ) {
            currentPrizeCrystal = SafeMath.div(SafeMath.mul(MINI_GAME_PRIZE_CRYSTAL, MINI_GAME_BONUS),100);
        } else {
            uint256 rate = 168 * MINI_GAME_BONUS;

            currentPrizeCrystal = SafeMath.div(SafeMath.mul(minigames[miniGameId].prizeCrystal, rate), 10000);  
        }

        uint256 startTime = now + MINI_GAME_BETWEEN_TIME;
        uint256 endTime = startTime + MINI_GAME_TIME_DEFAULT;
        noRoundMiniGame = noRoundMiniGame + 1;
         
        miniGameId = miniGameId + 1;
        minigames[ miniGameId ] = MiniGame(miningWarRoundNumber, false, currentPrizeCrystal, startTime, endTime, 0x0, 0);
    }

     
    function endMiniGame() private  
    {  
        require(minigames[ miniGameId ].ended == false && (minigames[ miniGameId ].endTime <= now ));
        
        uint256 crystalBonus = SafeMath.div( SafeMath.mul(minigames[ miniGameId ].prizeCrystal, 50), 100 );
         
        if (minigames[ miniGameId ].playerWin != 0x0) {
            PlayerData storage p = players[minigames[ miniGameId ].playerWin];
            p.win =  p.win + crystalBonus;
        }
         
        minigames[ miniGameId ].ended = true;
        emit eventEndMiniGame(minigames[ miniGameId ].playerWin, crystalBonus);
         
        startMiniGame();
    }

     
    function joinMiniGame() public disableContract
    {        
        require(now >= minigames[ miniGameId ].startTime && minigames[ miniGameId ].ended == false);
        
        PlayerData storage p = players[msg.sender];
        if (now <= minigames[ miniGameId ].endTime) {
             
            if (p.currentMiniGameId == miniGameId) {
                p.totalJoin = p.totalJoin + 1;
            } else {
                 
                updateShareCrystal();
                p.currentMiniGameId = miniGameId;
                p.totalJoin = 1;
                p.miningWarRoundNumber = minigames[ miniGameId ].miningWarRoundNumber;
            }
             
            if ( p.totalJoin <= 1 ) {  
                minigames[ miniGameId ].totalPlayer = minigames[ miniGameId ].totalPlayer + 1;
            }
            minigames[ miniGameId ].playerWin = msg.sender;
            minigames[ miniGameId ].endTime = minigames[ miniGameId ].endTime + MINI_GAME_ADD_TIME_DEFAULT;
            emit eventJoinMiniGame(p.totalJoin);
        } else {
             
            if (minigames[ miniGameId ].playerWin == 0x0) {
                updateShareCrystal();
                p.currentMiniGameId = miniGameId;
                p.lastMiniGameId = miniGameId;
                p.totalJoin = 1;
                p.miningWarRoundNumber = minigames[ miniGameId ].miningWarRoundNumber;

                minigames[ miniGameId ].playerWin = msg.sender;
            }
            endMiniGame();
        }
    }

     
    function updateShareCrystal() private
    {
        uint256 miningWarRoundNumber = getMiningWarRoundNumber();
        PlayerData storage p = players[msg.sender];
         
        if ( p.miningWarRoundNumber != miningWarRoundNumber) {
            p.share = 0;
            p.win = 0;
        } else if (minigames[ p.currentMiniGameId ].ended == true && p.lastMiniGameId < p.currentMiniGameId && minigames[ p.currentMiniGameId ].miningWarRoundNumber == miningWarRoundNumber) {
             
             
            p.share = SafeMath.add(p.share, calculateShareCrystal(p.currentMiniGameId));
            p.lastMiniGameId = p.currentMiniGameId;
        }
    }

     
    function claimCrystal() public
    {
         
        if ( minigames[miniGameId].endTime < now ) {
            endMiniGame();
        }
        updateShareCrystal(); 
         
        uint256 crystalBonus = players[msg.sender].win + players[msg.sender].share;
        MiningWarContract.addCrystal(msg.sender,crystalBonus); 
         
        PlayerData storage p = players[msg.sender];
        p.win = 0;
        p.share = 0;
    	
    }

     
    function calculateShareCrystal(uint256 _miniGameId) public view returns(uint256 _share)
    {
        PlayerData memory p = players[msg.sender];
        if ( p.lastMiniGameId >= p.currentMiniGameId && p.currentMiniGameId != 0) {
            _share = 0;
        } else {
            _share = SafeMath.div( SafeMath.div( SafeMath.mul(minigames[ _miniGameId ].prizeCrystal, 50), 100 ), minigames[ _miniGameId ].totalPlayer );
        }
    }

    function getMiningWarDealine () private view returns( uint256 _dealine )
    {
        _dealine = MiningWarContract.deadline();
    }

    function getMiningWarRoundNumber () private view returns( uint256 _roundNumber )
    {
        _roundNumber = MiningWarContract.roundNumber();
    }
}