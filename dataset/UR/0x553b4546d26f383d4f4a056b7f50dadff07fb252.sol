 

 
pragma solidity ^0.4.15;

contract TokenEIP20 {

    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    
}

contract Timed {
    
    uint256 public startTime;            
    uint256 public endTime;              
    uint256 public avarageBlockTime;     

     
    function isInTime() constant returns (bool inTime) {
        return block.timestamp >= (startTime - avarageBlockTime) && !isTimeExpired();
    }

     
    function isTimeExpired() constant returns (bool timeExpired) {
        return block.timestamp + avarageBlockTime >= endTime;
    }

    modifier onlyIfInTime {
        require(block.timestamp >= startTime && block.timestamp <= endTime); _;
    }

    modifier onlyIfTimePassed {
        require(block.timestamp > endTime); _;
    }

    function Timed(uint256 _startTime, uint256 life, uint8 _avarageBlockTime) {
        startTime = _startTime;
        endTime = _startTime + life;
        avarageBlockTime = _avarageBlockTime;
    }
}

library SafeMathLib {

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    function add(uint x, uint y) internal returns (uint z) {
        require((z = x + y) >= x);
    }

    function sub(uint x, uint y) internal returns (uint z) {
        require((z = x - y) <= x);
    }

    function mul(uint x, uint y) internal returns (uint z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    function per(uint x, uint y) internal constant returns (uint z) {
        return mul((x / 100), y);
    }

    function min(uint x, uint y) internal returns (uint z) {
        return x <= y ? x : y;
    }

    function max(uint x, uint y) internal returns (uint z) {
        return x >= y ? x : y;
    }

    function imin(int x, int y) internal returns (int z) {
        return x <= y ? x : y;
    }

    function imax(int x, int y) internal returns (int z) {
        return x >= y ? x : y;
    }

    function wmul(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }

    function rmul(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }

    function wdiv(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }

    function rdiv(uint x, uint y) internal returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    function wper(uint x, uint y) internal constant returns (uint z) {
        return wmul(wdiv(x, 100), y);
    }

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function rpow(uint x, uint n) internal returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }

}

contract Owned {

    address owner;
    
    function Owned() { owner = msg.sender; }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}

contract Upgradable is Owned {

    string  public VERSION;
    bool    public deprecated;
    string  public newVersion;
    address public newAddress;

    function Upgradable(string _version) {
        VERSION = _version;
    }

    function setDeprecated(string _newVersion, address _newAddress) onlyOwner returns (bool success) {
        require(!deprecated);
        deprecated = true;
        newVersion = _newVersion;
        newAddress = _newAddress;
        return true;
    }
}

contract BattleOfThermopylae is Timed, Upgradable {
    using SafeMathLib for uint;
  
    uint    public constant MAX_PERSIANS            = 300000 * 10**18;   
    uint    public constant MAX_SPARTANS            = 300 * 10**18;      
    uint    public constant MAX_IMMORTALS           = 100;               
    uint    public constant MAX_ATHENIANS           = 100 * 10**18;      

    uint8   public constant BP_PERSIAN              = 1;                 
    uint8   public constant BP_IMMORTAL             = 100;               
    uint16  public constant BP_SPARTAN              = 1000;              
    uint8   public constant BP_ATHENIAN             = 100;               

    uint8   public constant BTL_PERSIAN              = 1;                
    uint16  public constant BTL_IMMORTAL             = 2000;             
    uint16  public constant BTL_SPARTAN              = 1000;             
    uint16  public constant BTL_ATHENIAN             = 2000;             

    uint    public constant WAD                     = 10**18;            
    uint8   public constant BATTLE_POINT_DECIMALS   = 18;                
    uint8   public constant BATTLE_CASUALTIES       = 10;                
    
    address public persians;                                             
    address public immortals;                                            
    address public spartans;                                             
    address public athenians;                                            
    address public battles;                                              
    address public battlesOwner;                                         

    mapping (address => mapping (address => uint))   public  warriorsByPlayer;                
    mapping (address => uint)                        public  warriorsOnTheBattlefield;        

    event WarriorsAssignedToBattlefield (address indexed _from, address _faction, uint _battlePointsIncrementForecast);
    event WarriorsBackToHome            (address indexed _to, address _faction, uint _survivedWarriors);

    function BattleOfThermopylae(uint _startTime, uint _life, uint8 _avarageBlockTime, address _persians, address _immortals, address _spartans, address _athenians) Timed(_startTime, _life, _avarageBlockTime) Upgradable("1.0.0") {
        persians = _persians;
        immortals = _immortals;
        spartans = _spartans;
        athenians = _athenians;
    }

    function setBattleTokenAddress(address _battleTokenAddress, address _battleTokenOwner) onlyOwner {
        battles = _battleTokenAddress;
        battlesOwner = _battleTokenOwner;
    }

    function assignPersiansToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, persians, _warriors, MAX_PERSIANS);
        sendBattleTokens(msg.sender, _warriors.mul(BTL_PERSIAN));
         
        WarriorsAssignedToBattlefield(msg.sender, persians, _warriors / WAD);
        return true;
    }

    function assignImmortalsToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, immortals, _warriors, MAX_IMMORTALS);
        sendBattleTokens(msg.sender, _warriors.mul(WAD).mul(BTL_IMMORTAL));
         
        WarriorsAssignedToBattlefield(msg.sender, immortals, _warriors.mul(BP_IMMORTAL));
        return true;
    }

    function assignSpartansToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, spartans, _warriors, MAX_SPARTANS);
        sendBattleTokens(msg.sender, _warriors.mul(BTL_SPARTAN));
         
        WarriorsAssignedToBattlefield(msg.sender, spartans, (_warriors / WAD).mul(BP_SPARTAN));
        return true;
    }

    function assignAtheniansToBattle(uint _warriors) onlyIfInTime external returns (bool success) {
        assignWarriorsToBattle(msg.sender, athenians, _warriors, MAX_ATHENIANS);
        sendBattleTokens(msg.sender, _warriors.mul(BTL_ATHENIAN));
         
        WarriorsAssignedToBattlefield(msg.sender, athenians, (_warriors / WAD).mul(BP_ATHENIAN));
        return true;
    }

    function redeemWarriors() onlyIfTimePassed external returns (bool success) {
        if (getPersiansBattlePoints() > getGreeksBattlePoints()) {
             
            uint spartanSlaves = computeSlaves(msg.sender, spartans);
            if (spartanSlaves > 0) {
                 
                sendWarriors(msg.sender, spartans, spartanSlaves);
            }
             
            retrieveWarriors(msg.sender, persians, BATTLE_CASUALTIES);
        } else if (getPersiansBattlePoints() < getGreeksBattlePoints()) {
             
            uint persianSlaves = computeSlaves(msg.sender, persians);
            if (persianSlaves > 0) {
                 
                sendWarriors(msg.sender, persians, persianSlaves);                
            }
             
            retrieveWarriors(msg.sender, spartans, BATTLE_CASUALTIES);
        } else {
             
            retrieveWarriors(msg.sender, persians, BATTLE_CASUALTIES);
            retrieveWarriors(msg.sender, spartans, BATTLE_CASUALTIES);
        }
         
        retrieveWarriors(msg.sender, immortals, 0);
         
        retrieveWarriors(msg.sender, athenians, 0);
        return true;
    }

    function assignWarriorsToBattle(address _player, address _faction, uint _warriors, uint _maxWarriors) private {
        require(warriorsOnTheBattlefield[_faction].add(_warriors) <= _maxWarriors);
        require(TokenEIP20(_faction).transferFrom(_player, address(this), _warriors));
        warriorsByPlayer[_player][_faction] = warriorsByPlayer[_player][_faction].add(_warriors);
        warriorsOnTheBattlefield[_faction] = warriorsOnTheBattlefield[_faction].add(_warriors);
    }

    function retrieveWarriors(address _player, address _faction, uint8 _deadPercentage) private {
        if (warriorsByPlayer[_player][_faction] > 0) {
            uint _warriors = warriorsByPlayer[_player][_faction];
            if (_deadPercentage > 0) {
                _warriors = _warriors.sub(_warriors.wper(_deadPercentage));
            }
            warriorsByPlayer[_player][_faction] = 0;
            sendWarriors(_player, _faction, _warriors);
            WarriorsBackToHome(_player, _faction, _warriors);
        }
    }

    function sendWarriors(address _player, address _faction, uint _warriors) private {
        require(TokenEIP20(_faction).transfer(_player, _warriors));
    }

    function sendBattleTokens(address _player, uint _value) private {
        require(TokenEIP20(battles).transferFrom(battlesOwner, _player, _value));
    }

    function getPersiansOnTheBattlefield(address _player) constant returns (uint persiansOnTheBattlefield) {
        return warriorsByPlayer[_player][persians];
    }

    function getImmortalsOnTheBattlefield(address _player) constant returns (uint immortalsOnTheBattlefield) {
        return warriorsByPlayer[_player][immortals];
    }

    function getSpartansOnTheBattlefield(address _player) constant returns (uint spartansOnTheBattlefield) {
        return warriorsByPlayer[_player][spartans];
    }

    function getAtheniansOnTheBattlefield(address _player) constant returns (uint atheniansOnTheBattlefield) {
        return warriorsByPlayer[_player][athenians];
    }

    function getPersiansBattlePoints() constant returns (uint persiansBattlePoints) {
        return (warriorsOnTheBattlefield[persians].mul(BP_PERSIAN) + warriorsOnTheBattlefield[immortals].mul(WAD).mul(BP_IMMORTAL));
    }

    function getGreeksBattlePoints() constant returns (uint greeksBattlePoints) {
        return (warriorsOnTheBattlefield[spartans].mul(BP_SPARTAN) + warriorsOnTheBattlefield[athenians].mul(BP_ATHENIAN));
    }

    function getPersiansBattlePointsBy(address _player) constant returns (uint playerBattlePoints) {
        return (getPersiansOnTheBattlefield(_player).mul(BP_PERSIAN) + getImmortalsOnTheBattlefield(_player).mul(WAD).mul(BP_IMMORTAL));
    }

    function getGreeksBattlePointsBy(address _player) constant returns (uint playerBattlePoints) {
        return (getSpartansOnTheBattlefield(_player).mul(BP_SPARTAN) + getAtheniansOnTheBattlefield(_player).mul(BP_ATHENIAN));
    }

    function computeSlaves(address _player, address _loosingMainTroops) constant returns (uint slaves) {
        if (_loosingMainTroops == spartans) {
            return getPersiansBattlePointsBy(_player).wdiv(getPersiansBattlePoints()).wmul(getTotalSlaves(spartans));
        } else {
            return getGreeksBattlePointsBy(_player).wdiv(getGreeksBattlePoints()).wmul(getTotalSlaves(persians));
        }
    }

    function getTotalSlaves(address _faction) constant returns (uint slaves) {
        return warriorsOnTheBattlefield[_faction].sub(warriorsOnTheBattlefield[_faction].wper(BATTLE_CASUALTIES));
    }

    function isInProgress() constant returns (bool inProgress) {
        return !isTimeExpired();
    }

    function isEnded() constant returns (bool ended) {
        return isTimeExpired();
    }

    function isDraw() constant returns (bool draw) {
        return (getPersiansBattlePoints() == getGreeksBattlePoints());
    }

    function getTemporaryWinningFaction() constant returns (string temporaryWinningFaction) {
        if (isDraw()) {
            return "It's currently a draw, but the battle is still in progress!";
        }
        return getPersiansBattlePoints() > getGreeksBattlePoints() ?
            "Persians are winning, but the battle is still in progress!" : "Greeks are winning, but the battle is still in progress!";
    }

    function getWinningFaction() constant returns (string winningFaction) {
        if (isInProgress()) {
            return "The battle is still in progress";
        }
        if (isDraw()) {
            return "The battle ended in a draw!";
        }
        return getPersiansBattlePoints() > getGreeksBattlePoints() ? "Persians" : "Greeks";
    }

}