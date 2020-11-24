 

pragma solidity ^0.4.11;

 
contract E4RowEscrow {

event StatEvent(string msg);
event StatEventI(string msg, uint val);
event StatEventA(string msg, address addr);

        uint constant MAX_PLAYERS = 5;

        enum EndReason  {erWinner, erTimeOut, erCancel}
        enum SettingStateValue  {debug, release, lockedRelease}

        struct gameInstance {
                bool active;            
                bool allocd;            
                EndReason reasonEnded;  
                uint8 numPlayers;
                uint128 totalPot;       
                uint128[5] playerPots;  
                address[5] players;     
                uint lastMoved;         
        }

        struct arbiter {
                mapping (uint => uint)  gameIndexes;  
                bool registered; 
                bool locked;
                uint8 numPlayers;
                uint16 arbToken;          
                uint16 escFeePctX10;      
                uint16 arbFeePctX10;      
                uint32 gameSlots;         
                uint128 feeCap;           
                uint128 arbHoldover;      
        }


        address public  owner;   
        address public  tokenPartner;    
        uint public numArbiters;         

        int numGamesStarted;     

        uint public numGamesCompleted;  
        uint public numGamesCanceled;    
        uint public numGamesTimedOut;    
        uint public houseFeeHoldover;    
        uint public lastPayoutTime;      

         
        uint public gameTimeOut;
        uint public registrationFee;
        uint public houseFeeThreshold;
        uint public payoutInterval;

        uint acctCallGas;   
        uint tokCallGas;    
        uint public startGameGas;  
        uint public winnerDecidedGas;  

        SettingStateValue public settingsState = SettingStateValue.debug; 


        mapping (address => arbiter)  arbiters;
        mapping (uint => address)  arbiterTokens;
        mapping (uint => address)  arbiterIndexes;
        mapping (uint => gameInstance)  games;


        function E4RowEscrow() public
        {
                owner = msg.sender;
        }


        function applySettings(SettingStateValue _state, uint _fee, uint _threshold, uint _timeout, uint _interval, uint _startGameGas, uint _winnerDecidedGas)
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

                 
                acctCallGas = 21000; 
                tokCallGas = 360000;

                 
                startGameGas = _startGameGas;
                winnerDecidedGas = _winnerDecidedGas;
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
                StatEvent("thanks!");
                houseFeeHoldover += msg.value;
        }
        function blackHole() payable  {
                StatEvent("thanks!#2");
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


         
         
         
        function registerArbiter(uint _numPlayers, uint _arbToken, uint _escFeePctX10, uint _arbFeePctX10, uint _feeCap) public payable 
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

                if (_escFeePctX10 < 20) {
                        throw;  
                }

                if (_arbFeePctX10 > 10) {
                        throw;  
                }

                arbiters[msg.sender].locked = false;
                arbiters[msg.sender].numPlayers = uint8(_numPlayers);
                arbiters[msg.sender].escFeePctX10 = uint8(_escFeePctX10);
                arbiters[msg.sender].arbFeePctX10 = uint8(_arbFeePctX10);
                arbiters[msg.sender].arbToken = uint16(_arbToken & 0xffff);
                arbiters[msg.sender].feeCap = uint128(_feeCap);
                arbiters[msg.sender].registered = true;

                arbiterTokens[(_arbToken & 0xffff)] = msg.sender;
                arbiterIndexes[numArbiters++] = msg.sender;

                if (tokenPartner != address(0)) {
                        if (!tokenPartner.call.gas(tokCallGas).value(msg.value)()) {
                                 
                                throw;
                        }
                } else {
                        houseFeeHoldover += msg.value;
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

                gameInstance xgame = games[_hGame];
                if (xgame.active) {
                         
                        abortGame(_hGame, EndReason.erCancel);

                } else if (_hkMax > 0) {
                        houseKeep(_hkMax, ntok); 
                }

                if (!xgame.allocd) {
                        xgame.allocd = true;
                        xarb.gameIndexes[xarb.gameSlots++] = _hGame;
                } 
                numGamesStarted++;  

                xgame.active = true;
                xgame.lastMoved = now;
                xgame.totalPot = 0;
                xgame.numPlayers = xarb.numPlayers;
                for (uint i = 0; i < _players.length; i++) {
                        xgame.players[i] = _players[i];
                        xgame.playerPots[i] = 0;
                }
                 
        }

         
         
         
         
        function abortGame(uint  _hGame, EndReason _reason) private returns(bool _success)
        {
                gameInstance xgame = games[_hGame];
             
                 
                if (xgame.active) {
                        _success = true;
                        for (uint i = 0; i < xgame.numPlayers; i++) {
                                if (xgame.playerPots[i] > 0) {
                                        address a = xgame.players[i];
                                        uint nsend = xgame.playerPots[i];
                                        xgame.playerPots[i] = 0;
                                        if (!a.call.gas(acctCallGas).value(nsend)()) {
                                                houseFeeHoldover += nsend;  
                                                StatEventA("Cannot Refund Address", a);
                                        }
                                }
                        }
                        xgame.active = false;
                        xgame.reasonEnded = _reason;
                        if (_reason == EndReason.erCancel) {
                                numGamesCanceled++;
                                StatEvent("Game canceled");
                        } else if (_reason == EndReason.erTimeOut) {
                                numGamesTimedOut++;
                                StatEvent("Game timed out");
                        } else 
                                StatEvent("Game aborted");
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

                if (xgame.playerPots[pidx] < _winnerBal) {
                    abortGame(_hGame, EndReason.erCancel);
                    return;
                }

                xgame.active = false;
                xgame.reasonEnded = EndReason.erWinner;
                numGamesCompleted++;

                if (xgame.totalPot > 0) {
                         
                        uint _escrowFee = (xgame.totalPot * xarb.escFeePctX10) / 1000;
                        uint _arbiterFee = (xgame.totalPot * xarb.arbFeePctX10) / 1000;
                        if ((_escrowFee + _arbiterFee) > xarb.feeCap) {
                                _escrowFee = xarb.feeCap * xarb.escFeePctX10 / (xarb.escFeePctX10 + xarb.arbFeePctX10);
                                _arbiterFee = xarb.feeCap * xarb.arbFeePctX10 / (xarb.escFeePctX10 + xarb.arbFeePctX10);
                        }
                        uint _payout = xgame.totalPot - (_escrowFee + _arbiterFee);
                        uint _gasCost = tx.gasprice * (startGameGas + winnerDecidedGas);
                        if (_gasCost > _payout)
                                _gasCost = _payout;
                        _payout -= _gasCost;

                         
                        xarb.arbHoldover += uint128(_arbiterFee + _gasCost);
                        houseFeeHoldover += _escrowFee;

                        if ((houseFeeHoldover > houseFeeThreshold)
                            && (now > (lastPayoutTime + payoutInterval))) {
                                uint ntmpho = houseFeeHoldover;
                                houseFeeHoldover = 0;
                                lastPayoutTime = now;  
                                if (!tokenPartner.call.gas(tokCallGas).value(ntmpho)()) {
                                        houseFeeHoldover = ntmpho;  
                                        StatEvent("House-Fee Error1");
                                } 
                        }

                        if (_payout > 0) {
                                if (!_winner.call.gas(acctCallGas).value(uint(_payout))()) {
                                         
                                         
                                         
                                         
                                        houseFeeHoldover += _payout;
                                        StatEventI("Payout Error!", _hGame);
                                } else {
                                         
                                }
                        }
                }
        }


         
         
         
         
        function handleBet(uint _hGame) public payable 
        {
                address _arbAddr = arbiterTokens[ArbTokFromHGame(_hGame)];
                if (_arbAddr == address(0)) {
                        throw;  
                }

                var (valid, pidx) = validPlayer(_hGame, msg.sender);
                if (!valid) {
                        throw;  
                }

                gameInstance xgame = games[_hGame];
                xgame.playerPots[pidx] += uint128(msg.value);
                xgame.totalPot += uint128(msg.value);
                 
        }


         
         
         
        function arbTokenExists(uint _tok) constant returns (bool _exists)
        {
                _exists = false;
                if ((_tok > 0)
                        && (arbiterTokens[_tok] != address(0))
                        && arbiters[arbiterTokens[_tok]].registered)
                        _exists = true;

        }


         
         
         
        function getArbInfo(uint _tok) constant  returns (address _addr, uint _escFeePctX10, uint _arbFeePctX10, uint _feeCap, uint _holdOver) 
        {
                 
                        _addr = arbiterTokens[_tok]; 
                         arbiter xarb = arbiters[arbiterTokens[_tok]];
                        _escFeePctX10 = xarb.escFeePctX10;
                        _arbFeePctX10 = xarb.arbFeePctX10;
                        _feeCap = xarb.feeCap;
                        _holdOver = xarb.arbHoldover; 
                 
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
                                        abortGame(xarb.gameIndexes[gi], EndReason.erTimeOut);
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
                                        abortGame(xarb.gameIndexes[gi], EndReason.erTimeOut);
                                        ++aborted;
                                }
                            }

                        }
                }
        }


         
         
         
        function getGameInfo(uint _hGame)  constant  returns (EndReason _reason, uint _players, uint _totalPot, bool _active)
        {
                gameInstance xgame = games[_hGame];
                _active = xgame.active;
                _players = xgame.numPlayers;
                _totalPot = xgame.totalPot;
                _reason = xgame.reasonEnded;

        }

         
         
         
        function checkHGame(uint _hGame) constant returns(uint _arbTok, uint _lowWords)
        {
                _arbTok = ArbTokFromHGame(_hGame);
                _lowWords = _hGame & 0xffffffffffff;

        }

         
         
         
        function getOpGas() constant returns (uint _ag, uint _tg) 
        {
                _ag = acctCallGas;  
                _tg = tokCallGas;      
        }


         
         
         
        function setOpGas(uint _ag, uint _tg) 
        {
                if (msg.sender != owner)
                        throw;

                acctCallGas = _ag;
                tokCallGas = _tg;
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
                        if (!tokenPartner.call.gas(tokCallGas).value(ntmpho)()) {
                                houseFeeHoldover = ntmpho;  
                                StatEvent("House-Fee Error2"); 
                        } else {
                                lastPayoutTime = now;
                                StatEvent("House-Fee Paid");
                        }
                }
        }


         
         
         
        function withdrawArbFunds() public
        {
                if (!validArb2(msg.sender)) {
                        StatEvent("invalid arbiter");
                } else {
                        arbiter xarb = arbiters[msg.sender];
                        if (xarb.arbHoldover == 0) { 
                                StatEvent("0 Balance");
                                return;
                        } else {
                                uint _amount = xarb.arbHoldover; 
                                xarb.arbHoldover = 0; 
                                if (!msg.sender.call.gas(acctCallGas).value(_amount)())
                                        throw;
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