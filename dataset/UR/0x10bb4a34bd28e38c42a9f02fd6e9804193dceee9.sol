 

pragma solidity ^0.4.24;

 

contract ZeroBTCInterface {
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
}

contract ZeroBTCWorldCup {
    using SafeMath for uint;

     

    address internal constant administrator = 0x4F4eBF556CFDc21c3424F85ff6572C77c514Fcae;
    address internal constant givethAddress = 0x5ADF43DD006c6C36506e2b2DFA352E60002d22Dc;
    address internal constant BTCTKNADDR    = 0xB6eD7644C69416d67B522e20bC294A9a9B405B31;
    ZeroBTCInterface public BTCTKN;

    string name   = "0xBTCWorldCup";
    string symbol = "0xBTCWC";
    uint    internal constant entryFee      = 2018e15;
    uint    internal constant ninetyPercent = 18162e14;
    uint    internal constant fivePercent   = 1009e14;
    uint    internal constant tenPercent    = 2018e14;

     

    mapping (string =>  int8)                     worldCupGameID;
    mapping (int8   =>  bool)                     gameFinished;
     
    mapping (int8   =>  uint)                     gameLocked;
     
     
    mapping (int8   =>  string)                   gameResult;
    int8 internal                                 latestGameFinished;
    uint internal                                 prizePool;
    uint internal                                 givethPool;
    uint internal                                 adminPool;
    int                                           registeredPlayers;

    mapping (address => bool)                     playerRegistered;
    mapping (address => mapping (int8 => bool))   playerMadePrediction;
    mapping (address => mapping (int8 => string)) playerPredictions;
    mapping (address => int8[64])                 playerPointArray;
    mapping (address => int8)                     playerGamesScored;
    mapping (address => uint)                     playerStreak;
    address[]                                     playerList;

     

    event Registration(
        address _player
    );

    event PlayerLoggedPrediction(
        address _player,
        int     _gameID,
        string  _prediction
    );

    event PlayerUpdatedScore(
        address _player,
        int     _lastGamePlayed
    );

    event Comparison(
        address _player,
        uint    _gameID,
        string  _myGuess,
        string  _result,
        bool    _correct
    );

    event StartAutoScoring(
        address _player
    );

    event StartScoring(
        address _player,
        uint    _gameID
    );

    event DidNotPredict(
        address _player,
        uint    _gameID
    );

    event RipcordRefund(
        address _player
    );

     

    constructor ()
        public
    {
         

         
        worldCupGameID["RU-SA"] = 1;    
        gameLocked[1]           = 1528993800;

         
        worldCupGameID["EG-UY"] = 2;    
        worldCupGameID["MA-IR"] = 3;    
        worldCupGameID["PT-ES"] = 4;    
        gameLocked[2]           = 1529064000;
        gameLocked[3]           = 1529074800;
        gameLocked[4]           = 1529085600;

         
        worldCupGameID["FR-AU"] = 5;    
        worldCupGameID["AR-IS"] = 6;    
        worldCupGameID["PE-DK"] = 7;    
        worldCupGameID["HR-NG"] = 8;    
        gameLocked[5]           = 1529143200;
        gameLocked[6]           = 1529154000;
        gameLocked[7]           = 1529164800;
        gameLocked[8]           = 1529175600;

         
        worldCupGameID["CR-CS"] = 9;    
        worldCupGameID["DE-MX"] = 10;   
        worldCupGameID["BR-CH"] = 11;   
        gameLocked[9]           = 1529236800;
        gameLocked[10]          = 1529247600;
        gameLocked[11]          = 1529258400;

         
        worldCupGameID["SE-KR"] = 12;   
        worldCupGameID["BE-PA"] = 13;   
        worldCupGameID["TN-EN"] = 14;   
        gameLocked[12]          = 1529323200;
        gameLocked[13]          = 1529334000;
        gameLocked[14]          = 1529344800;

         
        worldCupGameID["CO-JP"] = 15;   
        worldCupGameID["PL-SN"] = 16;   
        worldCupGameID["RU-EG"] = 17;   
        gameLocked[15]          = 1529409600;
        gameLocked[16]          = 1529420400;
        gameLocked[17]          = 1529431200;

         
        worldCupGameID["PT-MA"] = 18;   
        worldCupGameID["UR-SA"] = 19;   
        worldCupGameID["IR-ES"] = 20;   
        gameLocked[18]          = 1529496000;
        gameLocked[19]          = 1529506800;
        gameLocked[20]          = 1529517600;

         
        worldCupGameID["DK-AU"] = 21;   
        worldCupGameID["FR-PE"] = 22;   
        worldCupGameID["AR-HR"] = 23;   
        gameLocked[21]          = 1529582400;
        gameLocked[22]          = 1529593200;
        gameLocked[23]          = 1529604000;

         
        worldCupGameID["BR-CR"] = 24;   
        worldCupGameID["NG-IS"] = 25;   
        worldCupGameID["CS-CH"] = 26;   
        gameLocked[24]          = 1529668800;
        gameLocked[25]          = 1529679600;
        gameLocked[26]          = 1529690400;

         
        worldCupGameID["BE-TN"] = 27;   
        worldCupGameID["KR-MX"] = 28;   
        worldCupGameID["DE-SE"] = 29;   
        gameLocked[27]          = 1529755200;
        gameLocked[28]          = 1529766000;
        gameLocked[29]          = 1529776800;

         
        worldCupGameID["EN-PA"] = 30;   
        worldCupGameID["JP-SN"] = 31;   
        worldCupGameID["PL-CO"] = 32;   
        gameLocked[30]          = 1529841600;
        gameLocked[31]          = 1529852400;
        gameLocked[32]          = 1529863200;

         
        worldCupGameID["UR-RU"] = 33;   
        worldCupGameID["SA-EG"] = 34;   
        worldCupGameID["ES-MA"] = 35;   
        worldCupGameID["IR-PT"] = 36;   
        gameLocked[33]          = 1529935200;
        gameLocked[34]          = 1529935200;
        gameLocked[35]          = 1529949600;
        gameLocked[36]          = 1529949600;

         
        worldCupGameID["AU-PE"] = 37;   
        worldCupGameID["DK-FR"] = 38;   
        worldCupGameID["NG-AR"] = 39;   
        worldCupGameID["IS-HR"] = 40;   
        gameLocked[37]          = 1530021600;
        gameLocked[38]          = 1530021600;
        gameLocked[39]          = 1530036000;
        gameLocked[40]          = 1530036000;

         
        worldCupGameID["KR-DE"] = 41;   
        worldCupGameID["MX-SE"] = 42;   
        worldCupGameID["CS-BR"] = 43;   
        worldCupGameID["CH-CR"] = 44;   
        gameLocked[41]          = 1530108000;
        gameLocked[42]          = 1530108000;
        gameLocked[43]          = 1530122400;
        gameLocked[44]          = 1530122400;

         
        worldCupGameID["JP-PL"] = 45;   
        worldCupGameID["SN-CO"] = 46;   
        worldCupGameID["PA-TN"] = 47;   
        worldCupGameID["EN-BE"] = 48;   
        gameLocked[45]          = 1530194400;
        gameLocked[46]          = 1530194400;
        gameLocked[47]          = 1530208800;
        gameLocked[48]          = 1530208800;

         
         
         

         
         
        worldCupGameID["1C-2D"]   = 49;   
        worldCupGameID["1A-2B"]   = 50;   
        gameLocked[49]            = 1530367200;
        gameLocked[50]            = 1530381600;

         
        worldCupGameID["1B-2A"]   = 51;   
        worldCupGameID["1D-2C"]   = 52;   
        gameLocked[51]            = 1530453600;
        gameLocked[52]            = 1530468000;

         
        worldCupGameID["1E-2F"]   = 53;   
        worldCupGameID["1G-2H"]   = 54;   
        gameLocked[53]            = 1530540000;
        gameLocked[54]            = 1530554400;

         
        worldCupGameID["1F-2E"]   = 55;   
        worldCupGameID["1H-2G"]   = 56;   
        gameLocked[55]            = 1530626400;
        gameLocked[56]            = 1530640800;

         
         
        worldCupGameID["W49-W50"] = 57;  
        worldCupGameID["W53-W54"] = 58;  
        gameLocked[57]            = 1530885600;
        gameLocked[58]            = 1530900000;

         
        worldCupGameID["W55-W56"] = 59;  
        worldCupGameID["W51-W52"] = 60;  
        gameLocked[59]            = 1530972000;
        gameLocked[60]            = 1530986400;

         
         
        worldCupGameID["W57-W58"] = 61;  
        gameLocked[61]            = 1531245600;

         
        worldCupGameID["W59-W60"] = 62;  
        gameLocked[62]            = 1531332000;

         
         
        worldCupGameID["L61-L62"] = 63;  
        gameLocked[63]            = 1531576800;

         
         
        worldCupGameID["W61-W62"] = 64;  
        gameLocked[64]            = 1531666800;

         
        latestGameFinished = 0;

    }

     
    
     
     
     
    function register()
        public
    {
        address _customerAddress = msg.sender;
        require(!playerRegistered[_customerAddress]);
         
        BTCTKN.transferFrom(_customerAddress, address(this), entryFee);
        
        registeredPlayers = SafeMath.addint256(registeredPlayers, 1);
        playerRegistered[_customerAddress] = true;
        playerGamesScored[_customerAddress] = 0;
        playerList.push(_customerAddress);
        require(playerRegistered[_customerAddress]);
        prizePool  = prizePool.add(ninetyPercent);
        givethPool = givethPool.add(fivePercent);
        adminPool  = adminPool.add(fivePercent);
        emit Registration(_customerAddress);
    }

     
     
     
     
    function makePrediction(int8 _gameID, string _prediction)
        public {
        address _customerAddress             = msg.sender;
        uint    predictionTime               = now;
        require(playerRegistered[_customerAddress]
                && !gameFinished[_gameID]
                && predictionTime < gameLocked[_gameID]);
         
        if (_gameID > 48 && equalStrings(_prediction, "DRAW")) {
            revert();
        } else {
            playerPredictions[_customerAddress][_gameID]    = _prediction;
            playerMadePrediction[_customerAddress][_gameID] = true;
            emit PlayerLoggedPrediction(_customerAddress, _gameID, _prediction);
        }
    }

     
    function showPlayerScores(address _participant)
        view
        public
        returns (int8[64])
    {
        return playerPointArray[_participant];
    }

    function seekApproval()
        public
        returns (bool)
    {
        BTCTKN.approve(address(this), entryFee);
    }
    
     
    function gameResultsLogged()
        view
        public
        returns (int)
    {
        return latestGameFinished;
    }

     
    function calculateScore(address _participant)
        view
        public
        returns (int16)
    {
        int16 finalScore = 0;
        for (int8 i = 0; i < latestGameFinished; i++) {
            uint j = uint(i);
            int16 gameScore = playerPointArray[_participant][j];
            finalScore = SafeMath.addint16(finalScore, gameScore);
        }
        return finalScore;
    }

     
    function countParticipants()
        public
        view
        returns (int)
    {
        return registeredPlayers;
    }

     
     
    function updateScore(address _participant)
        public
    {
        int8                     lastPlayed     = latestGameFinished;
        require(lastPlayed > 0);
         
        int8                     lastScored     = playerGamesScored[_participant];
         
        mapping (int8 => bool)   madePrediction = playerMadePrediction[_participant];
        mapping (int8 => string) playerGuesses  = playerPredictions[_participant];
        for (int8 i = lastScored; i < lastPlayed; i++) {
            uint j = uint(i);
            uint k = j.add(1);
            uint streak = playerStreak[_participant];
            emit StartScoring(_participant, k);
            if (!madePrediction[int8(k)]) {
                playerPointArray[_participant][j] = 0;
                playerStreak[_participant]        = 0;
                emit DidNotPredict(_participant, k);
            } else {
                string storage playerResult = playerGuesses[int8(k)];
                string storage actualResult = gameResult[int8(k)];
                bool correctGuess = equalStrings(playerResult, actualResult);
                emit Comparison(_participant, k, playerResult, actualResult, correctGuess);
                 if (!correctGuess) {
                      
                     playerPointArray[_participant][j] = 0;
                     playerStreak[_participant]        = 0;
                 } else {
                      
                     streak = streak.add(1);
                     playerStreak[_participant] = streak;
                     if (streak >= 5) {
                          
                        playerPointArray[_participant][j] = 4;
                     } else {
                         if (streak >= 3) {
                             
                            playerPointArray[_participant][j] = 2;
              }
                          
                         else { playerPointArray[_participant][j] = 1; }
                     }
                 }
            }
        }
        playerGamesScored[_participant] = lastPlayed;
    }

     
     
     
     
     
     
     
    function updateAllScores()
        public
    {
        uint allPlayers = playerList.length;
        for (uint i = 0; i < allPlayers; i++) {
            address _toScore = playerList[i];
            emit StartAutoScoring(_toScore);
            updateScore(_toScore);
        }
    }

     
     
    function playerLastScoredGame(address _player)
        public
        view
        returns (int8)
    {
        return playerGamesScored[_player];
    }

     
    function playerIsRegistered(address _player)
        public
        view
        returns (bool)
    {
        return playerRegistered[_player];
    }

     
    function correctResult(int8 _gameID)
        public
        view
        returns (string)
    {
        return gameResult[_gameID];
    }

     
    function playerGuess(int8 _gameID)
        public
        view
        returns (string)
    {
        return playerPredictions[msg.sender][_gameID];
    }

     
     
    function viewScore(address _participant)
        public
        view
        returns (uint)
    {
        int8                     lastPlayed     = latestGameFinished;
         
        mapping (int8 => bool)   madePrediction = playerMadePrediction[_participant];
        mapping (int8 => string) playerGuesses  = playerPredictions[_participant];
        uint internalResult = 0;
        uint internalStreak = 0;
        for (int8 i = 0; i < lastPlayed; i++) {
            uint j = uint(i);
            uint k = j.add(1);
            uint streak = internalStreak;

            if (!madePrediction[int8(k)]) {
                internalStreak = 0;
            } else {
                string storage playerResult = playerGuesses[int8(k)];
                string storage actualResult = gameResult[int8(k)];
                bool correctGuess = equalStrings(playerResult, actualResult);
                 if (!correctGuess) {
                    internalStreak = 0;
                 } else {
                      
                     internalStreak++;
                     streak++;
                     if (streak >= 5) {
                          
                        internalResult += 4;
                     } else {
                         if (streak >= 3) {
                             
                            internalResult += 2;
              }
                          
                         else { internalResult += 1; }
                     }
                 }
            }
        }
        return internalResult;
    }

     

    modifier isAdministrator() {
        address _sender = msg.sender;
        if (_sender == administrator) {
            _;
        } else {
            revert();
        }
    }

    function _btcToken(address _tokenContract) private pure returns (bool) {
        return _tokenContract == BTCTKNADDR;  
    }
    
     
    function addNewGame(string _opponents, int8 _gameID)
        isAdministrator
        public {
            worldCupGameID[_opponents] = _gameID;
    }

     
    function logResult(int8 _gameID, string _winner)
        isAdministrator
        public {
        require((int8(0) < _gameID) && (_gameID <= 64)
             && _gameID == latestGameFinished + 1);
         
        if (_gameID > 48 && equalStrings(_winner, "DRAW")) {
            revert();
        } else {
            require(!gameFinished[_gameID]);
            gameFinished [_gameID] = true;
            gameResult   [_gameID] = _winner;
            latestGameFinished     = _gameID;
            assert(gameFinished[_gameID]);
        }
    }

     
    function concludeTournament(address _first    
                              , address _second   
                              , address _third    
                              , address _fourth)  
        isAdministrator
        public
    {
         
        require(gameFinished[64]
             && playerIsRegistered(_first)
             && playerIsRegistered(_second)
             && playerIsRegistered(_third)
             && playerIsRegistered(_fourth));
         
        uint tenth       = prizePool.div(10);
         
        uint firstPrize  = tenth.mul(4);
        uint secondPrize = tenth.mul(3);
        uint thirdPrize  = tenth.mul(2);
         
        BTCTKN.approve(_first, firstPrize);
        BTCTKN.transferFrom(address(this), _first, firstPrize);
        BTCTKN.approve(_second, secondPrize);
        BTCTKN.transferFrom(address(this), _second, secondPrize);
        BTCTKN.approve(_third, thirdPrize);
        BTCTKN.transferFrom(address(this), _third, thirdPrize);
         
        BTCTKN.approve(givethAddress, givethPool);
        BTCTKN.transferFrom(address(this), givethAddress, givethPool);
         
        BTCTKN.approve(administrator, adminPool);
        BTCTKN.transferFrom(address(this), administrator, adminPool);
         
        uint fourthPrize = ((prizePool.sub(firstPrize)).sub(secondPrize)).sub(thirdPrize);
        BTCTKN.approve(_fourth, fourthPrize);
        BTCTKN.transferFrom(address(this), _fourth, fourthPrize);
        selfdestruct(administrator);
    }

     
     
     
     
     
    function pullRipCord()
        isAdministrator
        public
    {
        uint totalPool = (prizePool.add(givethPool)).add(adminPool);
        BTCTKN.transferFrom(address(this), administrator, totalPool);
        selfdestruct(administrator);
    }

    

     
    function _isCorrectBuyin(uint _buyin)
        private
        pure
        returns (bool) {
        return _buyin == entryFee;
    }

     
    function compare(string _a, string _b)
        private
        pure
        returns (int)
    {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }

     
    function equalStrings(string _a, string _b) pure private returns (bool) {
        return compare(_a, _b) == 0;
    }

}

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

    function addint16(int16 a, int16 b) internal pure returns (int16) {
        int16 c = a + b;
        assert(c >= a);
        return c;
    }

    function addint256(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        assert(c >= a);
        return c;
    }
}