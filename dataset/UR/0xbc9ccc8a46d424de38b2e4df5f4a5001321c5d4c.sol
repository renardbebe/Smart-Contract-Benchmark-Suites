 

pragma solidity ^0.4.6;


contract iE4RowEscrow {
        function getNumGamesStarted() constant returns (int ngames);
}


contract E4RowEscrowU is iE4RowEscrow {

event StatEvent(string msg);
event StatEventI(string msg, uint val);
event StatEventA(string msg, address addr);

        uint constant MAX_PLAYERS = 5;

        enum EndReason  {erWinner, erTimeOut, erCheat}
        enum SettingStateValue  {debug, release, lockedRelease}

        struct gameInstance {
                address[5] players;
                uint[5] playerPots;
                uint numPlayers;

                bool active;  
                bool allocd;  
                uint started;  
                uint lastMoved;  
                uint payout;  
                address winner;  


                EndReason reasonEnded;  

        }

        struct arbiter {
                mapping (uint => uint)  gameIndexes;  

                uint arbToken;  
                uint gameSlots;  
                uint gamesStarted;  
                uint gamesCompleted;
                uint gamesCheated;
                uint gamesTimedout;
                uint numPlayers;
                bool registered; 
                bool locked;
        }


        address public  owner;   
        address public  tokenPartner;    
        uint public numArbiters;         

        int numGamesStarted;     

        uint public numGamesCompleted;  
        uint public numGamesCheated;     
        uint public numGamesTimedOut;    

        uint public houseFeeHoldover;  
        uint public lastPayoutTime;      


         
        uint public gameTimeOut;
        uint public registrationFee;
        uint public houseFeeThreshold;
        uint public payoutInterval;

        uint raGas;  
        uint sgGas; 
        uint wpGas;  
        uint rfGas;  
        uint feeGas;  

        SettingStateValue public settingsState = SettingStateValue.debug; 


        mapping (address => arbiter)  arbiters;
        mapping (uint => address)  arbiterTokens;
        mapping (uint => address)  arbiterIndexes;
        mapping (uint => gameInstance)  games;


        function E4RowEscrowU() public
        {
                owner = msg.sender;
        }


        function applySettings(SettingStateValue _state, uint _fee, uint _threshold, uint _timeout, uint _interval)
        {
                if (msg.sender != owner) 
                        throw;

                 
                 
                 
                houseFeeThreshold = _threshold;
                gameTimeOut = _timeout;
                payoutInterval = _interval;

                if (settingsState == SettingStateValue.lockedRelease) {
                        StatEvent("Settings Tweaked");
                        return;
                }

                settingsState = _state;
                registrationFee = _fee;

                 
                raGas = 150000; 
                sgGas = 110000;
                wpGas = 20000; 
                rfGas = 20000; 
                feeGas = 360000; 

                StatEvent("Settings Changed");


        }

         
         
         
        function ArbTokFromHGame(uint _hGame) returns (uint _tok)
        { 
                _tok =  (_hGame / (2 ** 48)) & 0xffff;
        }


         
         
         
        function HaraKiri()
        {
                if ((msg.sender == owner) && (settingsState != SettingStateValue.lockedRelease))
                          suicide(tokenPartner);
                else
                        StatEvent("Kill attempt failed");
        }




         
         
         
        function() payable  {
                throw;
        }

         
         
         
        function validPlayer(uint _hGame, address _addr)  internal returns( bool _valid, uint _pidx)
        {
                _valid = false;
                if (activeGame(_hGame)) {
                        for (uint i = 0; i < games[_hGame].numPlayers; i++) {
                                if (games[_hGame].players[i] == _addr) {
                                        _valid=true;
                                        _pidx = i;
                                        break;
                                }
                        }
                }
        }

         
         
         
        function validPlayer2(uint _hGame, address _addr) internal  returns( bool _valid, uint _pidx)
        {
                _valid = false;
                for (uint i = 0; i < games[_hGame].numPlayers; i++) {
                        if (games[_hGame].players[i] == _addr) {
                                _valid=true;
                                _pidx = i;
                                break;
                        }
                }
        }

         
         
         
        function validArb(address _addr, uint _tok) internal  returns( bool _valid)
        {
                _valid = false;

                if ((arbiters[_addr].registered)
                        && (arbiters[_addr].arbToken == _tok)) 
                        _valid = true;
        }

         
         
         
        function validArb2(address _addr) internal  returns( bool _valid)
        {
                _valid = false;
                if (arbiters[_addr].registered)
                        _valid = true;
        }

         
         
         
        function arbLocked(address _addr) internal  returns( bool _locked)
        {
                _locked = false;
                if (validArb2(_addr)) 
                        _locked = arbiters[_addr].locked;
        }

         
         
         
        function activeGame(uint _hGame) internal  returns( bool _valid)
        {
                _valid = false;
                if ((_hGame > 0)
                        && (games[_hGame].active))
                        _valid = true;
        }


         
         
         
        function registerArbiter(uint _numPlayers, uint _arbToken) public payable 
        {

                if (msg.value != registrationFee) {
                        throw;   
                }

                if (_arbToken == 0) {
                        throw;  
                }

                if (arbTokenExists(_arbToken & 0xffff)) {
                        throw;  
                }

                if (arbiters[msg.sender].registered) {
                        throw;  
                }

                if (_numPlayers > MAX_PLAYERS) {
                        throw;  
                }

                arbiters[msg.sender].gamesStarted = 0;
                arbiters[msg.sender].gamesCompleted = 0;
                arbiters[msg.sender].gamesCheated = 0;
                arbiters[msg.sender].gamesTimedout = 0;
                arbiters[msg.sender].locked = false;
                arbiters[msg.sender].arbToken = _arbToken & 0xffff;
                arbiters[msg.sender].numPlayers = _numPlayers;
                arbiters[msg.sender].registered = true;

                arbiterTokens[(_arbToken & 0xffff)] = msg.sender;
                arbiterIndexes[numArbiters++] = msg.sender;


                if (!tokenPartner.call.gas(raGas).value(msg.value)()) {
                         
                        throw;
                }
                StatEventI("Arb Added", _arbToken);
        }


         
         
         
        function startGame(uint _hGame, int _hkMax, address[] _players) public 
        {
                uint ntok = ArbTokFromHGame(_hGame);
                if (!validArb(msg.sender, ntok )) {
                        StatEvent("Invalid Arb");
                        return; 
                }


                if (arbLocked(msg.sender)) {
                        StatEvent("Arb Locked");
                        return; 
                }

                arbiter xarb = arbiters[msg.sender];
                if (_players.length != xarb.numPlayers) { 
                        StatEvent("Incorrect num players");
                        return; 
                }

                if (_hkMax > 0)
                        houseKeep(_hkMax, ntok); 

                if (!games[_hGame].allocd) {
                        games[_hGame].allocd = true;
                        xarb.gameIndexes[xarb.gameSlots++] = _hGame;
                } 
                numGamesStarted++;  
                xarb.gamesStarted++;

                games[_hGame].active = true;
                games[_hGame].started = now; 
                games[_hGame].lastMoved = now; 
                games[_hGame].payout = 0; 
                games[_hGame].winner = address(0);

                games[_hGame].numPlayers = _players.length;  
                for (uint i = 0; i< _players.length && i < MAX_PLAYERS; i++) {
                    games[_hGame].players[i] = _players[i];
                    games[_hGame].playerPots[i] = 0;
                }


                StatEventI("Game Added", _hGame);


        }

         
         
         
         
        function abortGame(address _arb, uint  _hGame, EndReason _reason) private returns(bool _success)
        {
             gameInstance nGame = games[_hGame];
             
                 
                if (nGame.active) {
                        _success = true;
                        for (uint i = 0; i < nGame.numPlayers; i++) {
                                if (nGame.playerPots[i] > 0) {
                                        address a = nGame.players[i];
                                        uint nsend = nGame.playerPots[i];
                                        nGame.playerPots[i] = 0;
                                        if (!a.call.gas(rfGas).value(nsend)()) {
                                                houseFeeHoldover += nsend;  
                                                StatEventA("Cannot Refund Address", a);
                                        }
                                }
                        }
                        nGame.active = false;
                        nGame.reasonEnded = _reason;
                        if (_reason == EndReason.erCheat) {
                                numGamesCheated++;
                                arbiters[_arb].gamesCheated++;
                                StatEvent("Game Aborted-Cheat");
                        } else if (_reason == EndReason.erTimeOut) {
                                numGamesTimedOut++;
                                arbiters[_arb].gamesTimedout++;
                                StatEvent("Game Aborted-TimeOut");
                        } else 
                                StatEvent("Game Aborted!");
                }
        }


         
         
         
        function winnerDecided(uint _hGame, address _winner, uint _winnerBal) public
        {

                if (!validArb(msg.sender, ArbTokFromHGame(_hGame))) {
                        StatEvent("Invalid Arb");
                        return;  
                }

                var (valid, pidx) = validPlayer(_hGame, _winner);
                if (!valid) {
                        StatEvent("Invalid Player");
                        return;
                }

                arbiter xarb = arbiters[msg.sender];
                gameInstance xgame = games[_hGame];

                uint totalPot = 0;

                if (xgame.playerPots[pidx] != _winnerBal) {
                    abortGame(msg.sender, _hGame, EndReason.erCheat);
                    return;
                }

                for (uint i = 0; i < xgame.numPlayers; i++) {
                        totalPot += xgame.playerPots[i];
                }

                uint nportion;
                uint nremnant;
                if (totalPot > 0) {
                        nportion = totalPot/50;  
                        nremnant = totalPot-nportion;
                } else {
                        nportion = 0;
                        nremnant = 0;
                }


                xgame.lastMoved = now;
                xgame.active = false;
                xgame.reasonEnded = EndReason.erWinner;
                xgame.winner = _winner;
                xgame.payout = nremnant;

                if (nportion > 0) {
                        houseFeeHoldover += nportion;
                        if ((houseFeeHoldover > houseFeeThreshold)
                                && (now > (lastPayoutTime + payoutInterval))) {
                                uint ntmpho = houseFeeHoldover;
                                houseFeeHoldover = 0;
                                lastPayoutTime = now;  
                                if (!tokenPartner.call.gas(feeGas).value(ntmpho)()) {
                                        houseFeeHoldover = ntmpho;  
                                        StatEvent("House-Fee Error1");
                                } 
                        }
                }

                for (i = 0; i < xgame.numPlayers; i++) {
                        xgame.playerPots[i] = 0;
                }

                xarb.gamesCompleted++;
                numGamesCompleted++;
                if (nremnant > 0) {
                        if (!_winner.call.gas(wpGas).value(uint(nremnant))()) {
                                 
                                throw;  
                        } else {
                                StatEventI("Winner Paid", _hGame);
                        }
                }
        }

         
         
         
         
        function handleBet(uint _hGame) public payable 
        {
                address narb = arbiterTokens[ArbTokFromHGame(_hGame)];
                if (narb == address(0)) {
                        StatEvent("Invalid hGame");
                        if (settingsState != SettingStateValue.debug)
                                throw;
                        else
                                return;
                }

                var (valid, pidx) = validPlayer(_hGame, msg.sender);
                if (!valid) {
                        StatEvent("Invalid Player");
                        if (settingsState != SettingStateValue.debug)
                                throw;
                        else
                                return;
                }

                games[_hGame].playerPots[pidx] += msg.value;
                games[_hGame].lastMoved = now;

                StatEventI("Bet Added", _hGame);

        }


         
         
         
        function arbTokenExists(uint _tok) constant returns (bool _exists)
        {
                _exists = false;
                if ((_tok > 0)
                        && (arbiterTokens[_tok] != address(0))
                        && arbiters[arbiterTokens[_tok]].registered)
                        _exists = true;

        }




         
         
         
        function getNumGamesStarted() constant returns (int _games) 
        {
                _games = numGamesStarted;
        }

         
         
         
        function getArbInfo(uint _idx) constant  returns (address _addr, uint _started, uint _completed, uint _cheated, uint _timedOut) 
        {
                if (_idx >= numArbiters) {
                        StatEvent("Invalid Arb");
                        return;
                }
                _addr = arbiterIndexes[_idx];
                if ((_addr == address(0))
                        || (!arbiters[_addr].registered)) {
                        StatEvent("Invalid Arb");
                        return;
                }
                arbiter xarb = arbiters[_addr];
                _started = xarb.gamesStarted;
                _completed = xarb.gamesCompleted;
                _timedOut = xarb.gamesTimedout;
                _cheated = xarb.gamesCheated;
        }


         
         
         
         
        function houseKeep(int _max, uint _arbToken) public
        {
                uint gi;
                address a;
                int aborted = 0;

                arbiter xarb = arbiters[msg.sender]; 
                
         
                if (msg.sender == owner) {
                        for (uint ar = 0; (ar < numArbiters) && (aborted < _max) ; ar++) {
                            a = arbiterIndexes[ar];
                            xarb = arbiters[a];    

                            for ( gi = 0; (gi < xarb.gameSlots) && (aborted < _max); gi++) {
                                gameInstance ngame0 = games[xarb.gameIndexes[gi]];
                                if ((ngame0.active)
                                    && ((now - ngame0.lastMoved) > gameTimeOut)) {
                                        abortGame(a, xarb.gameIndexes[gi], EndReason.erTimeOut);
                                        ++aborted;
                                }
                            }
                        }

                } else {
                        if (!validArb(msg.sender, _arbToken))
                                StatEvent("Housekeep invalid arbiter");
                        else {
                            a = msg.sender;
                            xarb = arbiters[a];    
                            for (gi = 0; (gi < xarb.gameSlots) && (aborted < _max); gi++) {
                                gameInstance ngame1 = games[xarb.gameIndexes[gi]];
                                if ((ngame1.active)
                                    && ((now - ngame1.lastMoved) > gameTimeOut)) {
                                        abortGame(a, xarb.gameIndexes[gi], EndReason.erTimeOut);
                                        ++aborted;
                                }
                            }

                        }
                }
        }


         
         
         
        function getGameInfo(uint _hGame)  constant  returns (EndReason _reason, uint _players, uint _payout, bool _active, address _winner )
        {
                gameInstance ngame = games[_hGame];
                _active = ngame.active;
                _players = ngame.numPlayers;
                _winner = ngame.winner;
                _payout = ngame.payout;
                _reason = ngame.reasonEnded;

        }

         
         
         
        function checkHGame(uint _hGame) constant returns(uint _arbTok, uint _lowWords)
        {
                _arbTok = ArbTokFromHGame(_hGame);
                _lowWords = _hGame & 0xffffffffffff;

        }

         
         
         
        function getOpGas() constant returns (uint _ra, uint _sg, uint _wp, uint _rf, uint _fg) 
        {
                _ra = raGas;  
                _sg = sgGas;  
                _wp = wpGas;  
                _rf = rfGas;  
                _fg = feeGas;  
        }


         
         
         
        function setOpGas(uint _ra, uint _sg, uint _wp, uint _rf, uint _fg) 
        {
                if (msg.sender != owner)
                        throw;

                raGas = _ra;
                sgGas = _sg;
                wpGas = _wp;
                rfGas = _rf;
                feeGas = _fg;
        }

         
         
         
        function setArbiterLocked(address _addr, bool _lock)  public 
        {
                if (owner != msg.sender)  {
                        throw; 
                } else if (!validArb2(_addr)) {
                        StatEvent("invalid arb");
                } else {
                        arbiters[_addr].locked = _lock;
                }

        }

         
         
         
         
         
        function flushHouseFees()
        {
                if (msg.sender != owner) {
                        StatEvent("only owner calls this function");
                } else if (houseFeeHoldover > 0) {
                        uint ntmpho = houseFeeHoldover;
                        houseFeeHoldover = 0;
                        if (!tokenPartner.call.gas(feeGas).value(ntmpho)()) {
                                houseFeeHoldover = ntmpho;  
                                StatEvent("House-Fee Error2"); 
                        } else {
                                lastPayoutTime = now;
                                StatEvent("House-Fee Paid");
                        }
                }

        }


         
         
         
        function setTokenPartner(address _addr) public
        {
                if (msg.sender != owner) {
                        throw;
                } 

                if ((settingsState == SettingStateValue.lockedRelease) 
                        && (tokenPartner == address(0))) {
                        tokenPartner = _addr;
                        StatEvent("Token Partner Final!");
                } else if (settingsState != SettingStateValue.lockedRelease) {
                        tokenPartner = _addr;
                        StatEvent("Token Partner Assigned!");
                }

        }

         
         
         
        function changeOwner(address _addr) 
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;

                owner = _addr;
        }



}