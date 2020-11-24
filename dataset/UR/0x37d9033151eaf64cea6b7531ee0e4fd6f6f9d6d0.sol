 

pragma solidity ^0.4.25;

contract EthCrystal
{

     
    using SafeMath for *;

     
    struct TowersInfoList {
        string name;  
        uint256 timeLimit;  
        uint256 warriorToTime;  
        uint256 currentRoundID;  
        uint256 growthCoefficient;  
        uint256 winnerShare;  
        uint256 nextRound;  
        uint256 dividendShare;  

        mapping (uint256 => TowersInfo) RoundList;  
    }
    
     
    struct TowersInfo {
        uint256 roundID;  
        uint256 towerBalance;  
        uint256 totalBalance;  
        uint256 totalWarriors;  
        uint256 timeToFinish;  
        uint256 timeLimit;  
        uint256 warriorToTime;  
        uint256 bonusPot;  
        address lastPlayer;  
    }

     
    struct PlayerInfo {
        uint256 playerID;  
        address playerAddress;  
        address referralAddress;  
        string nickname;  
        mapping (uint256 => TowersRoundInfo) TowersList;
    }

    
    struct TowersRoundInfo {
        uint256 _TowerType;
        mapping (uint256 => PlayerRoundInfo) RoundList;
    }
    
     
    struct PlayerRoundInfo {
        uint256 warriors;
        uint256 cashedOut;  
    }
    
     
    struct ReferralInfo {
        uint256 balance;
    }

    uint256 public playerID_counter = 1;  

    uint256 public devShare = 5;  
    uint256 public affShare = 10;  

    mapping (address => PlayerInfo) public players;  
    mapping (uint256 => PlayerInfo) public playersByID;  

    mapping (address => ReferralInfo) public aff;  

    mapping (uint256 => TowersInfoList) public GameRounds;  

    address public ownerAddress;  
    
    event BuyEvent(address player, uint256 TowerID, uint256 RoundID, uint256 TotalWarriors, uint256 WarriorPrice, uint256 TimeLeft);

    constructor() public {
        ownerAddress = msg.sender;  

         
        GameRounds[0] = TowersInfoList("Crystal Tower", 60*60*3,  60*3, 0,      10000000000000,     35, 15, 50);
        GameRounds[1] = TowersInfoList("Red Tower",     60*60*3,  60*3, 0,      20000000000000,     25,  5, 70);
        GameRounds[2] = TowersInfoList("Gold Tower",    60*60*3,  60*3, 0,     250000000000000,     40, 10, 50);
        GameRounds[3] = TowersInfoList("Purple Tower",  60*60*6,  60*3, 0,    5000000000000000,     30, 10, 60);
        GameRounds[4] = TowersInfoList("Silver Tower",  60*60*6,  60*3, 0,    1000000000000000,     35, 15, 50);
        GameRounds[5] = TowersInfoList("Black Tower",   60*60*6,  60*3, 0,    1000000000000000,     65, 10, 25);
        GameRounds[6] = TowersInfoList("Toxic Tower",   60*60*6,  60*3, 0,    2000000000000000,     65, 10, 25);

         
        newRound(0);
        newRound(1);
        newRound(2);
        newRound(3);
        newRound(4);
        newRound(5);
        newRound(6);
    }

     
    function newRound (uint256 _TowerType) private {
        GameRounds[_TowerType].currentRoundID++;
        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID] = TowersInfo(GameRounds[_TowerType].currentRoundID, 0, 0, 0, now+GameRounds[_TowerType].timeLimit, GameRounds[_TowerType].timeLimit, GameRounds[_TowerType].warriorToTime,
        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID-1].towerBalance*GameRounds[_TowerType].nextRound/100,  
        0x0);  
    }
    
    
     
    function buyWarriors (uint256 _TowerType, uint _WarriorsAmount, uint256 _referralID) public payable {
        require (msg.value > 10000000);  
        require (_WarriorsAmount >= 1 && _WarriorsAmount < 1000000000);  
        require (GameRounds[_TowerType].timeLimit > 0);  

        if (players[msg.sender].playerID == 0){  
            if (_referralID > 0 && _referralID != players[msg.sender].playerID && _referralID == playersByID[_referralID].playerID){
                setNickname("", playersByID[_referralID].playerAddress);   
            }else{
                setNickname("", ownerAddress);
            }
        }

        if (GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeToFinish < now){
             

             
            aff[GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].lastPlayer].balance += GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].towerBalance*GameRounds[_TowerType].winnerShare/100;

             
            aff[GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].lastPlayer].balance += GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].bonusPot;

            newRound(_TowerType);
             
             
        }

         
        uint256 _totalWarriors = GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].totalWarriors;
        uint256 _warriorPrice = (_totalWarriors+1)*GameRounds[_TowerType].growthCoefficient;  

        uint256 _value = (_WarriorsAmount*_warriorPrice)+(((_WarriorsAmount-1)*(_WarriorsAmount-1)+_WarriorsAmount-1)/2)*GameRounds[_TowerType].growthCoefficient;

        require (msg.value >= _value);  

        uint256 _ethToTake = affShare+devShare;  


        players[msg.sender].TowersList[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].warriors += _WarriorsAmount;

        if (players[players[msg.sender].referralAddress].playerID > 0 && players[msg.sender].referralAddress != ownerAddress){
             
            aff[players[msg.sender].referralAddress].balance += _value*affShare/100;  
            aff[ownerAddress].balance += _value*devShare/100;  
        } else {
             
            _ethToTake = affShare;
            aff[ownerAddress].balance += _value*_ethToTake/100;  
        }

        if (msg.value-_value > 0){
            aff[msg.sender].balance += msg.value-_value;  
        }

        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].towerBalance += _value*(100-_ethToTake)/100;  
        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].totalBalance += _value;
        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].totalWarriors += _WarriorsAmount;
        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].lastPlayer = msg.sender;

         
        GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeToFinish += (_WarriorsAmount).mul(GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].warriorToTime);

         
        if (GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeToFinish > now+GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeLimit){
            GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeToFinish = now+GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeLimit;
        }
        
        uint256 TotalWarriors = GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].totalWarriors;
        uint256 TimeLeft = GameRounds[_TowerType].RoundList[GameRounds[_TowerType].currentRoundID].timeToFinish;
        
         
        emit BuyEvent(msg.sender,
        _TowerType,
        GameRounds[_TowerType].currentRoundID,
        TotalWarriors,
        (TotalWarriors+1)*GameRounds[_TowerType].growthCoefficient,
        TimeLeft);
        
        return;
    }

     
    function dividendCashout (uint256 _TowerType, uint256 _RoundID) public {
        require (GameRounds[_TowerType].timeLimit > 0);

        uint256 _warriors = players[msg.sender].TowersList[_TowerType].RoundList[_RoundID].warriors;
        require (_warriors > 0);
        uint256 _totalEarned = _warriors*GameRounds[_TowerType].RoundList[_RoundID].towerBalance*GameRounds[_TowerType].dividendShare/GameRounds[_TowerType].RoundList[_RoundID].totalWarriors/100;
        uint256 _alreadyCashedOut = players[msg.sender].TowersList[_TowerType].RoundList[_RoundID].cashedOut;
        uint256 _earnedNow = _totalEarned-_alreadyCashedOut;
        require (_earnedNow > 0);  

        players[msg.sender].TowersList[_TowerType].RoundList[_RoundID].cashedOut = _totalEarned;

        if (!msg.sender.send(_earnedNow)){
            players[msg.sender].TowersList[_TowerType].RoundList[_RoundID].cashedOut = _alreadyCashedOut;
        }
        return;
    }

     
    function referralCashout () public {
        require (aff[msg.sender].balance > 0);

        uint256 _balance = aff[msg.sender].balance;

        aff[msg.sender].balance = 0;

        if (!msg.sender.send(_balance)){
            aff[msg.sender].balance = _balance;
        }
    }

     
    function setNickname (string nickname, address _referralAddress)
    public {
        if (players[msg.sender].playerID == 0){
            players[msg.sender] = PlayerInfo (playerID_counter, msg.sender, _referralAddress, nickname);
            playersByID[playerID_counter] = PlayerInfo (playerID_counter, msg.sender, _referralAddress, nickname);
            playerID_counter++;
        }else{
            players[msg.sender].nickname = nickname;
            playersByID[players[msg.sender].playerID].nickname = nickname;
        }
    }


     
     
    function _playerRoundsInfo (address _playerAddress, uint256 _TowerType, uint256 _RoundID)
    public
    view
    returns (uint256, uint256, uint256, uint256, bool, address) {
        uint256 _warriors = players[_playerAddress].TowersList[_TowerType].RoundList[_RoundID].warriors;
        TowersInfo memory r = GameRounds[_TowerType].RoundList[_RoundID];
        bool isFinished = true;
        if (r.timeToFinish > now){
            isFinished = false;
        }
        return (
        r.towerBalance*GameRounds[_TowerType].winnerShare/100,
        _currentPlayerAmountUnclaimed(_playerAddress, _TowerType, _RoundID),
        _warriors,
        r.totalWarriors,
        isFinished,
        r.lastPlayer);
    }


    function _currentPlayerAmountUnclaimed (address _playerAddress, uint256 _TowerType, uint256 _RoundID)
    public
    view
    returns (uint256) {
        if (_RoundID == 0){
            _RoundID = GameRounds[_TowerType].currentRoundID;
        }
        uint256 _warriors = players[_playerAddress].TowersList[_TowerType].RoundList[_RoundID].warriors;
        uint256 _totalForCashOut = (_warriors*GameRounds[_TowerType].RoundList[_RoundID].towerBalance*GameRounds[_TowerType].dividendShare/GameRounds[_TowerType].RoundList[_RoundID].totalWarriors/100);
        uint256 _unclaimedAmount = _totalForCashOut-players[_playerAddress].TowersList[_TowerType].RoundList[_RoundID].cashedOut;
        return (_unclaimedAmount);
    }
    
    function _playerInfo (uint256 _playerID)
    public
    view
    returns (uint256, address, string, uint256) {
        return (playersByID[_playerID].playerID,
        playersByID[_playerID].playerAddress,
        playersByID[_playerID].nickname,
        aff[playersByID[_playerID].playerAddress].balance);
    }

    function _playerBalance (address _playerAddress)
    public
    view
    returns (uint256) {
        return aff[_playerAddress].balance;
    }

    function _TowerRoundDetails (uint256 _TowerType, uint256 _RoundID)
    public
    view
    returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, address) {
        TowersInfo memory r = GameRounds[_TowerType].RoundList[_RoundID];
        return (
        r.roundID,
        r.towerBalance,
        r.totalBalance,
        r.totalWarriors,
        r.timeToFinish,
        r.timeLimit,
        r.warriorToTime,
        r.bonusPot,
        r.lastPlayer
        );
    }
}

library SafeMath {

     
    function mul(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b, "SafeMath mul failed");
        return c;
    }

     
    function sub(uint256 a, uint256 b)
        internal
        pure
        returns (uint256)
    {
        require(b <= a, "SafeMath sub failed");
        return a - b;
    }

     
    function add(uint256 a, uint256 b)
        internal
        pure
        returns (uint256 c)
    {
        c = a + b;
        require(c >= a, "SafeMath add failed");
        return c;
    }

     
    function sqrt(uint256 x)
        internal
        pure
        returns (uint256 y)
    {
        uint256 z = ((add(x,1)) / 2);
        y = x;
        while (z < y)
        {
            y = z;
            z = ((add((x / z),z)) / 2);
        }
    }

     
    function sq(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return (mul(x,x));
    }

     
    function pwr(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        if (x==0)
            return (0);
        else if (y==0)
            return (1);
        else
        {
            uint256 z = x;
            for (uint256 i=1; i < y; i++)
                z = mul(z,x);
            return (z);
        }
    }
}