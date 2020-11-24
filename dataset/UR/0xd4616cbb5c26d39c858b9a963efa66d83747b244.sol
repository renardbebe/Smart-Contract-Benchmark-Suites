 

pragma solidity 0.4.25;

 

 
contract BMEvents {

    event onGameCreated(
        uint256 indexed gameID,
        uint256 timestamp
    );

    event onGameActivated(
        uint256 indexed gameID,
        uint256 startTime,
        uint256 timestamp
    );

    event onGamePaused(
        uint256 indexed gameID,
        bool paused,
        uint256 timestamp
    );

    event onChangeCloseTime(
        uint256 indexed gameID,
        uint256 closeTimestamp,
        uint256 timestamp
    );

    event onPurchase(
        uint256 indexed gameID,
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 teamID,
        uint256 ethIn,
        uint256 keysBought,
        uint256 timestamp
    );

    event onWithdraw(
        uint256 indexed gameID,
        uint256 indexed playerID,
        address playerAddress,
        bytes32 playerName,
        uint256 ethOut,
        uint256 timestamp
    );

    event onGameEnded(
        uint256 indexed gameID,
        uint256 winningTeamID,
        string comment,
        uint256 timestamp
    );

    event onGameCancelled(
        uint256 indexed gameID,
        string comment,
        uint256 timestamp
    );

    event onFundCleared(
        uint256 indexed gameID,
        uint256 fundCleared,
        uint256 timestamp
    );
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
        uint256 z = ((add(x, 1)) / 2);
        y = x;
        while (z < y) {
            y = z;
            z = ((add((x / z), z)) / 2);
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
        if (x == 0) {
            return (0);
        } else if (y == 0) {
            return (1);
        } else {
            uint256 z = x;
            for (uint256 i = 1; i < y; i++) {
                z = mul(z,x);
            }
            return (z);
        }
    }
}

 

 
library BMKeyCalc {
    using SafeMath for *;
    
     
     
     
     
    function keysRec(uint256 _curEth, uint256 _newEth)
        internal
        pure
        returns (uint256)
    {
        return(keys((_curEth).add(_newEth)).sub(keys(_curEth)));
    }


     
     
     
     
    function ethRec(uint256 _curKeys, uint256 _sellKeys)
        internal
        pure
        returns (uint256)
    {
        return((eth(_curKeys)).sub(eth(_curKeys.sub(_sellKeys))));
    }

     
     
     
    function keys(uint256 _eth) 
        internal
        pure
        returns(uint256)
    {
        return ((((((_eth).mul(1000000000000000000)).mul(3125000000000000000000000000)).add(562498828125610351562500000000000000000000000000000000000000000000)).sqrt()).sub(749999218750000000000000000000000)) / (1562500000);
    }
    
     
     
     
    function eth(uint256 _keys) 
        internal
        pure
        returns(uint256)
    {
        return ((781250000).mul(_keys.sq()).add(((1499998437500000).mul(_keys.mul(1000000000000000000))) / (2))) / ((1000000000000000000).sq());
    }
}

 

 
library BMDatasets {

    struct Game {
        string name;                      
        uint256 numberOfTeams;            
        uint256 gameStartTime;            

        bool paused;                      
        bool ended;                       
        bool canceled;                    
        uint256 winnerTeam;               
        uint256 withdrawDeadline;         
        string gameEndComment;            
        uint256 closeTime;                
    }

    struct GameStatus {
        uint256 totalEth;                 
        uint256 totalWithdrawn;           
        uint256 winningVaultInst;         
        uint256 winningVaultFinal;        
        bool fundCleared;                 
    }

    struct Team {
        bytes32 name;        
        uint256 keys;        
        uint256 eth;         
        uint256 mask;        
        uint256 dust;        
    }

    struct Player {
        uint256 eth;         
        bool withdrawn;      
    }

    struct PlayerTeam {
        uint256 keys;        
        uint256 eth;         
        uint256 mask;        
    }
}

 

 
contract Ownable {
    address public owner;
    address public dev;

     
    constructor() public {
        owner = msg.sender;
    }


     
    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

     
    modifier onlyDev() {
        require(msg.sender == dev, "only dev");
        _;
    }

     
    modifier onlyDevOrOwner() {
        require(msg.sender == owner || msg.sender == dev, "only owner or dev");
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

     
    function setDev(address newDev) onlyOwner public {
        if (newDev != address(0)) {
            dev = newDev;
        }
    }
}

 

interface BMForwarderInterface {
    function deposit() external payable;
}

 

interface BMPlayerBookInterface {
    function pIDxAddr_(address _addr) external returns (uint256);
    function pIDxName_(bytes32 _name) external returns (uint256);

    function getPlayerID(address _addr) external returns (uint256);
    function getPlayerName(uint256 _pID) external view returns (bytes32);
    function getPlayerLAff(uint256 _pID) external view returns (uint256);
    function setPlayerLAff(uint256 _pID, uint256 _lAff) external;
    function getPlayerAffT2(uint256 _pID) external view returns (uint256);
    function getPlayerAddr(uint256 _pID) external view returns (address);
    function getPlayerHasAff(uint256 _pID) external view returns (bool);
    function getNameFee() external view returns (uint256);
    function getAffiliateFee() external view returns (uint256);
    function depositAffiliate(uint256 _pID) external payable;
}

 

 
 
 
 
 
 
 
contract BMSport is BMEvents, Ownable {
    using BMKeyCalc for *;
    using SafeMath for *;

     
    BMForwarderInterface  private Banker_Address;
    BMPlayerBookInterface private BMBook;

    string constant public name_ = "BMSport";
    uint256 public gameIDIndex_;
    
     
    mapping(uint256 => BMDatasets.Game) public game_;

     
    mapping(uint256 => BMDatasets.GameStatus) public gameStatus_;

     
    mapping(uint256 => mapping(uint256 => BMDatasets.Team)) public teams_;

     
    mapping(uint256 => mapping(uint256 => BMDatasets.Player)) public players_;

     
    mapping(uint256 => mapping(uint256 => mapping(uint256 => BMDatasets.PlayerTeam))) public playerTeams_;


    constructor(BMPlayerBookInterface book_addr) public {
        require(book_addr != address(0), "need a playerbook address");
        BMBook = book_addr;
        gameIDIndex_ = 1;
    }


     
     
     
     
     
     
    function createGame(string _name, bytes32[] _teamNames)
        external
        isHuman()
        onlyDevOrOwner()
        returns(uint256)
    {
        uint256 _gameID = gameIDIndex_;
        gameIDIndex_++;

         
        game_[_gameID].name = _name;

         
        uint256 _nt = _teamNames.length;
        require(_nt > 0, "number of teams must be larger than 0");

        game_[_gameID].numberOfTeams = _nt;
        for (uint256 i = 0; i < _nt; i++) {
            teams_[_gameID][i] = BMDatasets.Team(_teamNames[i], 0, 0, 0, 0);
        }

        emit onGameCreated(_gameID, now);

        return _gameID;
    }


     
     
     
     
     
    function activate(uint256 _gameID, uint256 _startTime)
        external
        isHuman()
        onlyDevOrOwner()
    {
        require(_gameID < gameIDIndex_, "incorrect game id");
        require(game_[_gameID].gameStartTime == 0, "already activated");
        
         
        game_[_gameID].gameStartTime = _startTime;

        emit onGameActivated(_gameID, _startTime, now);
    }


     
     
     
     
     
     
     
     
     
    function buysXid(uint256 _gameID, uint256[] memory _teamEth)
        public
        payable
        isActivated(_gameID)
        isOngoing(_gameID)
        isNotPaused(_gameID)
        isNotClosed(_gameID)
        isHuman()
        isWithinLimits(msg.value)
    {
         
        uint256 _pID = BMBook.getPlayerID(msg.sender);
        
         
        buysCore(_gameID, _pID, _teamEth);
    }


     
     
     
     
     
    function pauseGame(uint256 _gameID, bool _paused)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        onlyDevOrOwner()
    {
        game_[_gameID].paused = _paused;

        emit onGamePaused(_gameID, _paused, now);
    }


     
     
     
     
     
    function setCloseTime(uint256 _gameID, uint256 _closeTime)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        onlyDevOrOwner()
    {
        game_[_gameID].closeTime = _closeTime;

        emit onChangeCloseTime(_gameID, _closeTime, now);
    }


     
     
     
     
     
     
     
     
    function settleGame(uint256 _gameID, uint256 _team, string _comment, uint256 _deadline)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        isValidTeam(_gameID, _team)
        onlyDevOrOwner()
    {
         
        require(_deadline >= now + 86400, "deadline must be more than one day later.");

        game_[_gameID].ended = true;
        game_[_gameID].winnerTeam = _team;
        game_[_gameID].gameEndComment = _comment;
        game_[_gameID].withdrawDeadline = _deadline;

        if (teams_[_gameID][_team].keys == 0) {
             
            uint256 _totalPot = (gameStatus_[_gameID].winningVaultInst).add(gameStatus_[_gameID].winningVaultFinal);
            gameStatus_[_gameID].totalWithdrawn = _totalPot;
            if (_totalPot > 0) {
                Banker_Address.deposit.value(_totalPot)();
            }
        }

        emit BMEvents.onGameEnded(_gameID, _team, _comment, now);
    }


     
     
     
     
     
     
     
    function cancelGame(uint256 _gameID, string _comment, uint256 _deadline)
        external
        isActivated(_gameID)
        isOngoing(_gameID)
        onlyDevOrOwner()
    {
         
        require(_deadline >= now + 86400, "deadline must be more than one day later.");

        game_[_gameID].ended = true;
        game_[_gameID].canceled = true;
        game_[_gameID].gameEndComment = _comment;
        game_[_gameID].withdrawDeadline = _deadline;

        emit BMEvents.onGameCancelled(_gameID, _comment, now);
    }


     
     
     
     
    function withdraw(uint256 _gameID)
        external
        isHuman()
        isActivated(_gameID)
        isEnded(_gameID)
    {
        require(now < game_[_gameID].withdrawDeadline, "withdraw deadline already passed");
        require(gameStatus_[_gameID].fundCleared == false, "fund already cleared");

        uint256 _pID = BMBook.pIDxAddr_(msg.sender);

        require(_pID != 0, "player has not played this game");
        require(players_[_pID][_gameID].withdrawn == false, "player already cashed out");

        players_[_pID][_gameID].withdrawn = true;

        if (game_[_gameID].canceled) {
             
             
            uint256 _totalInvestment = players_[_pID][_gameID].eth.mul(95) / 100;
            if (_totalInvestment > 0) {
                 
                BMBook.getPlayerAddr(_pID).transfer(_totalInvestment);
                gameStatus_[_gameID].totalWithdrawn = _totalInvestment.add(gameStatus_[_gameID].totalWithdrawn);
            }

            emit BMEvents.onWithdraw(_gameID, _pID, msg.sender, BMBook.getPlayerName(_pID), _totalInvestment, now);
        } else {
            uint256 _totalWinnings = getPlayerInstWinning(_gameID, _pID, game_[_gameID].winnerTeam).add(getPlayerPotWinning(_gameID, _pID, game_[_gameID].winnerTeam));
            if (_totalWinnings > 0) {
                 
                BMBook.getPlayerAddr(_pID).transfer(_totalWinnings);
                gameStatus_[_gameID].totalWithdrawn = _totalWinnings.add(gameStatus_[_gameID].totalWithdrawn);
            }

            emit BMEvents.onWithdraw(_gameID, _pID, msg.sender, BMBook.getPlayerName(_pID), _totalWinnings, now);
        }
    }


     
     
     
     
    function clearFund(uint256 _gameID)
        external
        isHuman()
        isEnded(_gameID)
        onlyDevOrOwner()
    {
        require(now >= game_[_gameID].withdrawDeadline, "withdraw deadline not passed yet");
        require(gameStatus_[_gameID].fundCleared == false, "fund already cleared");

        gameStatus_[_gameID].fundCleared = true;

         
        uint256 _totalPot = (gameStatus_[_gameID].winningVaultInst).add(gameStatus_[_gameID].winningVaultFinal);
        uint256 _amount = _totalPot.sub(gameStatus_[_gameID].totalWithdrawn);
        if (_amount > 0) {
            Banker_Address.deposit.value(_amount)();
        }

        emit onFundCleared(_gameID, _amount, now);
    }


     
     
     
     
     
    function getPlayerInstWinning(uint256 _gameID, uint256 _pID, uint256 _team)
        public
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {
        return ((((teams_[_gameID][_team].mask).mul(playerTeams_[_pID][_gameID][_team].keys)) / (1000000000000000000)).sub(playerTeams_[_pID][_gameID][_team].mask));
    }


     
     
     
     
     
    function getPlayerPotWinning(uint256 _gameID, uint256 _pID, uint256 _team)
        public
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {
        if (teams_[_gameID][_team].keys > 0) {
            return gameStatus_[_gameID].winningVaultFinal.mul(playerTeams_[_pID][_gameID][_team].keys) / teams_[_gameID][_team].keys;
        } else {
            return 0;
        }
    }


     
     
     
    function getGameStatus(uint256 _gameID)
        public
        view
        isActivated(_gameID)
        returns(uint256, bytes32[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 _nt = game_[_gameID].numberOfTeams;
        bytes32[] memory _names = new bytes32[](_nt);
        uint256[] memory _keys = new uint256[](_nt);
        uint256[] memory _eth = new uint256[](_nt);
        uint256[] memory _keyPrice = new uint256[](_nt);
        uint256 i;

        for (i = 0; i < _nt; i++) {
            _names[i] = teams_[_gameID][i].name;
            _keys[i] = teams_[_gameID][i].keys;
            _eth[i] = teams_[_gameID][i].eth;
            _keyPrice[i] = getBuyPrice(_gameID, i, 1000000000000000000);
        }

        return (_nt, _names, _keys, _eth, _keyPrice);
    }


     
     
     
     
    function getPlayerStatus(uint256 _gameID, uint256 _pID)
        public
        view
        isActivated(_gameID)
        returns(bytes32, uint256[] memory, uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _eth = new uint256[](_nt);
        uint256[] memory _keys = new uint256[](_nt);
        uint256[] memory _instWin = new uint256[](_nt);
        uint256[] memory _potWin = new uint256[](_nt);
        uint256 i;

        for (i = 0; i < _nt; i++) {
            _eth[i] = playerTeams_[_pID][_gameID][i].eth;
            _keys[i] = playerTeams_[_pID][_gameID][i].keys;
            _instWin[i] = getPlayerInstWinning(_gameID, _pID, i);
            _potWin[i] = getPlayerPotWinning(_gameID, _pID, i);
        }
        
        return (BMBook.getPlayerName(_pID), _eth, _keys, _instWin, _potWin);
    }


     
     
     
     
     
    function getBuyPrice(uint256 _gameID, uint256 _team, uint256 _keys)
        public 
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {                  
        return ((teams_[_gameID][_team].keys.add(_keys)).ethRec(_keys));
    }


     
     
     
     
    function getBuyPrices(uint256 _gameID, uint256[] memory _keys)
        public
        view
        isActivated(_gameID)
        returns(uint256, uint256[])
    {
        uint256 _totalEth = 0;
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _eth = new uint256[](_nt);
        uint256 i;

        require(_nt == _keys.length, "Incorrect number of teams");

        for (i = 0; i < _nt; i++) {
            if (_keys[i] > 0) {
                _eth[i] = getBuyPrice(_gameID, i, _keys[i]);
                _totalEth = _totalEth.add(_eth[i]);
            }
        }

        return (_totalEth, _eth);
    }
    

     
     
     
     
     
    function getKeysfromETH(uint256 _gameID, uint256 _team, uint256 _eth)
        public 
        view
        isActivated(_gameID)
        isValidTeam(_gameID, _team)
        returns(uint256)
    {                  
        return (teams_[_gameID][_team].eth).keysRec(_eth);
    }


     
     
     
     
    function getKeysFromETHs(uint256 _gameID, uint256[] memory _eths)
        public
        view
        isActivated(_gameID)
        returns(uint256, uint256[])
    {
        uint256 _totalKeys = 0;
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _keys = new uint256[](_nt);
        uint256 i;

        require(_nt == _eths.length, "Incorrect number of teams");

        for (i = 0; i < _nt; i++) {
            if (_eths[i] > 0) {
                _keys[i] = getKeysfromETH(_gameID, i, _eths[i]);
                _totalKeys = _totalKeys.add(_keys[i]);
            }
        }

        return (_totalKeys, _keys);
    }

     
     
     
     
    function buysCore(uint256 _gameID, uint256 _pID, uint256[] memory _teamEth)
        private
    {
        uint256 _nt = game_[_gameID].numberOfTeams;
        uint256[] memory _keys = new uint256[](_nt);
        bytes32 _name = BMBook.getPlayerName(_pID);
        uint256 _totalEth = 0;
        uint256 i;

        require(_teamEth.length == _nt, "Number of teams is not correct");

         
        for (i = 0; i < _nt; i++) {
            if (_teamEth[i] > 0) {
                 
                _totalEth = _totalEth.add(_teamEth[i]);

                 
                _keys[i] = (teams_[_gameID][i].eth).keysRec(_teamEth[i]);

                 
                playerTeams_[_pID][_gameID][i].eth = _teamEth[i].add(playerTeams_[_pID][_gameID][i].eth);
                playerTeams_[_pID][_gameID][i].keys = _keys[i].add(playerTeams_[_pID][_gameID][i].keys);

                 
                teams_[_gameID][i].eth = _teamEth[i].add(teams_[_gameID][i].eth);
                teams_[_gameID][i].keys = _keys[i].add(teams_[_gameID][i].keys);

                emit BMEvents.onPurchase(_gameID, _pID, msg.sender, _name, i, _teamEth[i], _keys[i], now);
            }
        }

         
        require(_totalEth == msg.value, "Total ETH is not the same as msg.value");        
            
         
        gameStatus_[_gameID].totalEth = _totalEth.add(gameStatus_[_gameID].totalEth);
        players_[_pID][_gameID].eth = _totalEth.add(players_[_pID][_gameID].eth);

        distributeAll(_gameID, _pID, _totalEth, _keys);
    }


     
     
     
     
     
    function distributeAll(uint256 _gameID, uint256 _pID, uint256 _totalEth, uint256[] memory _keys)
        private
    {
         
        uint256 _com = _totalEth / 20;

         
        uint256 _instPot = _totalEth.mul(15) / 100;

         
        uint256 _pot = _totalEth.mul(80) / 100;

         

        Banker_Address.deposit.value(_com)();

        gameStatus_[_gameID].winningVaultInst = _instPot.add(gameStatus_[_gameID].winningVaultInst);
        gameStatus_[_gameID].winningVaultFinal = _pot.add(gameStatus_[_gameID].winningVaultFinal);

         
        uint256 _nt = _keys.length;
        for (uint256 i = 0; i < _nt; i++) {
            uint256 _newPot = _instPot.add(teams_[_gameID][i].dust);
            uint256 _dust = updateMasks(_gameID, _pID, i, _newPot, _keys[i]);
            teams_[_gameID][i].dust = _dust;
        }
    }


     
     
     
     
     
     
     
    function updateMasks(uint256 _gameID, uint256 _pID, uint256 _team, uint256 _gen, uint256 _keys)
        private
        returns(uint256)
    {
         
        
         
        if (teams_[_gameID][_team].keys > 0) {
            uint256 _ppt = (_gen.mul(1000000000000000000)) / (teams_[_gameID][_team].keys);
            teams_[_gameID][_team].mask = _ppt.add(teams_[_gameID][_team].mask);

            updatePlayerMask(_gameID, _pID, _team, _ppt, _keys);

             
            return(_gen.sub((_ppt.mul(teams_[_gameID][_team].keys)) / (1000000000000000000)));
        } else {
            return _gen;
        }
    }


     
     
     
     
     
     
     
    function updatePlayerMask(uint256 _gameID, uint256 _pID, uint256 _team, uint256 _ppt, uint256 _keys)
        private
    {
        if (_keys > 0) {
             
             
            uint256 _pearn = (_ppt.mul(_keys)) / (1000000000000000000);
            playerTeams_[_pID][_gameID][_team].mask = (((teams_[_gameID][_team].mask.mul(_keys)) / (1000000000000000000)).sub(_pearn)).add(playerTeams_[_pID][_gameID][_team].mask);
        }
    }

     
    function transferBanker(BMForwarderInterface banker) 
    public
    onlyOwner()
    {
        if (banker != address(0)) {
            Banker_Address = banker;
        }
    }


     
     
    modifier isActivated(uint256 _gameID) {
        require(game_[_gameID].gameStartTime > 0, "Not activated yet");
        require(game_[_gameID].gameStartTime <= now, "game not started yet");
        _;
    }


     
     
    modifier isNotPaused(uint256 _gameID) {
        require(game_[_gameID].paused == false, "game is paused");
        _;
    }


     
     
    modifier isNotClosed(uint256 _gameID) {
        require(game_[_gameID].closeTime == 0 || game_[_gameID].closeTime > now, "game is closed");
        _;
    }


     
     
    modifier isOngoing(uint256 _gameID) {
        require(game_[_gameID].ended == false, "game is ended");
        _;
    }


     
     
    modifier isEnded(uint256 _gameID) {
        require(game_[_gameID].ended == true, "game is not ended");
        _;
    }


     
    modifier isHuman() {
        address _addr = msg.sender;
        require (_addr == tx.origin, "Human only");

        uint256 _codeLength;
        assembly { _codeLength := extcodesize(_addr) }
        require(_codeLength == 0, "Human only");
        _;
    }


     
     
     
    modifier isWithinLimits(uint256 _eth) {
        require(_eth >= 1000000000, "too little money");
        require(_eth <= 100000000000000000000000, "too much money");
        _;    
    }


     
     
     
    modifier isValidTeam(uint256 _gameID, uint256 _team) {
        require(_team < game_[_gameID].numberOfTeams, "there is no such team");
        _;
    }
}