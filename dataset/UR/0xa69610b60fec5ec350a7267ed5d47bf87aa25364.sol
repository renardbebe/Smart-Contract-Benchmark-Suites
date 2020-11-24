 

pragma solidity ^0.4.22;

 
contract owned { 
    address owner;
    modifier onlyOwner()
    {
        require(msg.sender == owner);
        _;
    }
}

contract priced {
    modifier costs(uint256 price) {
        require(msg.value >= price);
        _;
    }
}

contract SplitStealContract is owned, priced {

     
    uint constant STEAL = 0;
    uint constant SPLIT = 1;
    mapping(address=>bool) suspended;
    mapping(address=>uint) totalGamesStarted;
    mapping(address=>uint) totalGamesParticipated;   
    uint256 contractEarnings = 0;
     
    uint256 REGISTRATION_COST = 10**14; 
    uint256 MINIMUM_COST_OF_BET = 10**17; 
    uint256 MAXIMUM_COST_OF_BET = 5 * 10**18; 
    uint256 STAGE_TIMEOUT = 60*60*24*7; 

     
    uint256 K = 25;  

     
    event RegisterationOpened(uint indexed _gameNumber);
    event RegisterationClosed(uint indexed _gameNumber);
    event RevealStart(uint indexed _gameNumber);
    event RevealStop(uint indexed _gameNumber);
    event Transferred(uint indexed _gameNumber,address _to, uint256 _amount);
    event ContractEarnings(uint indexed _gameNumber, uint256 _amount, string _reason);
    event Disqualified(uint indexed _gameNumber, address indexed _player, bytes32 _encryptedChoice, uint _actualChoice, bytes32 _encryptedActualChoice);
    event NewGameRules(uint _oldFees, uint _newFees, uint _oldMinBet, uint _newMinBet, uint _oldMaxBet, uint _newMaxBet, uint _oldStageTimeout, uint _newStageTimeout);
    event NewRewardMatrix(uint _n1, uint _n2, uint _n3, uint _d);
    event NewRewardPercentage(uint256 _oldK, uint256 _k);
    event Suspended(address indexed _player);
    event UnSuspended(address indexed _player);

     
    struct Bet {
        bytes32 encryptedChoice;
        uint256 betAmount;
        uint actualChoice;
    }

     
    struct Game {
        uint startTime;
        uint revealTime;
        uint finishTime;
        address player1; 
        address player2;
        uint256 registrationCost;
        uint256 k;
        uint stageTimeout;
        bool registerationOpen;
        bool revealing;
        bool lastGameFinished;
        mapping(address=>address) opponent;
        mapping(address=>bool) registered;
        mapping(address=>Bet) bets;
        mapping(address=>bool) revealed;
        mapping(address=>bool) disqualified;
        mapping(address=>bool) claimedReward;
        mapping(address=>uint256) reward;
    }
    
    Game[] games;

    constructor() public {
        owner = msg.sender;
    }   

    function fund() payable external {
        contractEarnings = contractEarnings + msg.value;
    }

     
    function isEven(uint num) private pure returns(bool _isEven) {
        uint halfNum = num / 2;
        return (halfNum * 2) == num;
    }
     

     
    function changeOwner(address _to) public onlyOwner {
        require(_to != address(0));
        owner = _to;
    }
     
    function transferEarningsToOwner() public onlyOwner {
        require(address(this).balance >= contractEarnings);
        uint256 _contractEarnings = contractEarnings;
        contractEarnings = 0;
         
         
         
         
        owner.transfer(_contractEarnings);
    }

    function suspend(address _player) public onlyOwner returns(bool _suspended){
        require(!suspended[_player]);
        require(_player != owner);
        suspended[_player] = true;
        emit Suspended(_player);
        return true;
    }

    function unSuspend(address _player) public onlyOwner returns(bool _unSuspended){
        require(suspended[_player]);
        suspended[_player] = false;
        emit UnSuspended(_player);
        return true;
    }

    function setRewardPercentageK(uint256 _k) public onlyOwner {
         
        require(_k <= 100);
        emit NewRewardPercentage(K, _k);
        K = _k;
    }

    function setGameRules(uint256 _fees, uint256 _minBet, uint256 _maxBet, uint256 _stageTimeout) public onlyOwner {
        require(_stageTimeout >= 60*60*24*7); 
        require((_fees * 100 ) < _minBet); 
        require(_minBet < _maxBet);
        emit NewGameRules(REGISTRATION_COST, _fees, MINIMUM_COST_OF_BET, _minBet, MAXIMUM_COST_OF_BET, _maxBet, STAGE_TIMEOUT, _stageTimeout);
        REGISTRATION_COST = _fees;
        MINIMUM_COST_OF_BET = _minBet;
        MAXIMUM_COST_OF_BET = _maxBet;
        STAGE_TIMEOUT = _stageTimeout;
    }
     

     
    function getOwner() public view returns(address _owner) {
        return owner;
    }

    function getContractBalance() public view returns(uint256 _balance) {
        return address(this).balance;
    }

    function getContractEarnings() public view returns(uint _earnings) {
        return contractEarnings;
    }

    function getRewardMatrix() public view returns(uint _k) {
        return (K);
    }

    function getGameRules() public view returns(uint256 _fees, uint256 _minBet, uint256 _maxBet, uint256 _stageTimeout) {
        return (REGISTRATION_COST, MINIMUM_COST_OF_BET, MAXIMUM_COST_OF_BET, STAGE_TIMEOUT);
    }

    function getGameState(uint gameNumber) public view returns(bool _registerationOpen, bool _revealing, bool _lastGameFinished, uint _startTime, uint _revealTime, uint _finishTime, uint _stageTimeout) {
        require(games.length >= gameNumber);    
        Game storage game = games[gameNumber - 1];    
        return (game.registerationOpen, game.revealing, game.lastGameFinished, game.startTime, game.revealTime, game.finishTime, game.stageTimeout);
    }

    function getPlayerState(uint gameNumber) public view returns(bool _suspended, bool _registered, bool _revealed, bool _disqualified, bool _claimedReward, uint256 _betAmount, uint256 _reward) {
        require(games.length >= gameNumber);
        uint index = gameNumber - 1;
        address player = msg.sender;
        uint256 betAmount = games[index].bets[player].betAmount;
        return (suspended[player], games[index].registered[player], games[index].revealed[player], games[index].disqualified[player], games[index].claimedReward[player], betAmount, games[index].reward[player] );
    }

    function getTotalGamesStarted() public view returns(uint _totalGames) {
        return totalGamesStarted[msg.sender];
    }

    function getTotalGamesParticipated() public view returns(uint _totalGames) {
        return totalGamesParticipated[msg.sender];
    }

    function getTotalGames() public view returns(uint _totalGames) {
        return games.length;
    }
     

     
    function startGame(uint256 _betAmount, bytes32 _encryptedChoice) public  payable costs(_betAmount) returns(uint _gameNumber) {
        address player = msg.sender;
        require(!suspended[player]);   
        require(_betAmount >= MINIMUM_COST_OF_BET);
        require(_betAmount <= MAXIMUM_COST_OF_BET);
        Game memory _game = Game(now, now, now, player, address(0), REGISTRATION_COST, K, STAGE_TIMEOUT, true, false, false);  
        games.push(_game); 
        Game storage game = games[games.length-1]; 
        game.registered[player] = true;
        game.bets[player] = Bet(_encryptedChoice, _betAmount, 0);                   
        totalGamesStarted[player] = totalGamesStarted[player] + 1;
        emit RegisterationOpened(games.length);
        return games.length;
    }

    function joinGame(uint _gameNumber, uint256 _betAmount, bytes32 _encryptedChoice) public  payable costs(_betAmount) {
        require(games.length >= _gameNumber);
        Game storage game = games[_gameNumber-1];
        address player = msg.sender;
        require(game.registerationOpen); 
        require(game.player1 != player);  
        require(!suspended[player]);   
        require(_betAmount >= MINIMUM_COST_OF_BET);
        require(_betAmount <= MAXIMUM_COST_OF_BET);
        require(game.player2 == address(0)); 
        game.player2 = player;
        game.registered[player] = true;
        game.bets[player] = Bet(_encryptedChoice, _betAmount, 0);    
        game.registerationOpen = false;
        game.revealing = true;  
        game.revealTime = now;  
        game.finishTime = now;  
        game.opponent[game.player1] = game.player2;    
        game.opponent[game.player2] = game.player1;
        totalGamesParticipated[player] = totalGamesParticipated[player] + 1;
        emit RegisterationClosed(_gameNumber);
        emit RevealStart(_gameNumber);
    }

    function reveal(uint _gameNumber, uint256 _choice) public {
        require(games.length >= _gameNumber);
        Game storage game = games[_gameNumber-1];
        require(game.revealing);
        address player = msg.sender;
        require(!suspended[player]);
        require(game.registered[player]);
        require(!game.revealed[player]);
        game.revealed[player] = true;
        game.bets[player].actualChoice = _choice;
        bytes32 encryptedChoice = game.bets[player].encryptedChoice;
        bytes32 encryptedActualChoice = keccak256(_choice);
        if( encryptedActualChoice != encryptedChoice) {
            game.disqualified[player] = true;
             
             
            game.claimedReward[player] = true;
            game.reward[player] = 0;
            if (game.disqualified[game.opponent[player]]) {
                uint256 gameEarnings = game.bets[player].betAmount + game.bets[game.opponent[player]].betAmount;
                contractEarnings = contractEarnings + gameEarnings;
                emit ContractEarnings(_gameNumber, gameEarnings, "BOTH_DISQUALIFIED");
            }
            emit Disqualified(_gameNumber, player, encryptedChoice, _choice, encryptedActualChoice);
        }
        if(game.revealed[game.player1] && game.revealed[game.player2]) {
            game.revealing = false;
            game.lastGameFinished = true;
            game.finishTime = now;  
            emit RevealStop(_gameNumber);
        }
    }
     


     
    function ethTransfer(uint gameNumber, address _to, uint256 _amount) private {
        require(!suspended[_to]);
        require(_to != address(0));
        if ( _amount > games[gameNumber-1].registrationCost) {
             
            uint256 amount = _amount - games[gameNumber-1].registrationCost;
            require(address(this).balance >= amount);
            _to.transfer(amount);
            emit Transferred(gameNumber, _to, amount);
        }
    }


    function claimRewardK(uint gameNumber) public returns(bool _claimedReward)  {
        require(games.length >= gameNumber);
        Game storage game = games[gameNumber-1];
        address player = msg.sender;
        require(!suspended[player]);
        require(!game.claimedReward[player]);
        uint commission = games[gameNumber-1].registrationCost;
        if (game.registerationOpen) {
            game.claimedReward[player] = true;
            game.registerationOpen = false;
            game.lastGameFinished = true;
            if ( now > (game.startTime + game.stageTimeout)) {
                 
                commission = 0;
            }
            game.reward[player] = game.bets[player].betAmount - commission;
            if (commission > 0) {
                contractEarnings = contractEarnings + commission;
                emit ContractEarnings(gameNumber, commission, "GAME_ABANDONED");
            }
             
             
            ethTransfer(gameNumber, player, game.bets[player].betAmount);
            return true;
        }
        require(game.lastGameFinished);
        require(!game.disqualified[player]);
        require(game.registered[player]);
        require(game.revealed[player]);
        require(!game.claimedReward[player]);
        game.claimedReward[player] = true;
        address opponent = game.opponent[player];
        uint256 reward = 0;
        uint256 gameReward = 0;
        uint256 totalBet = (game.bets[player].betAmount + game.bets[opponent].betAmount);
        if ( game.disqualified[opponent]) {
            gameReward = ((100 + game.k) * game.bets[player].betAmount) / 100;
            reward = gameReward < totalBet ? gameReward : totalBet;  
            game.reward[player] = reward - commission;
             
             
            contractEarnings = contractEarnings + (totalBet - game.reward[player]);
            emit ContractEarnings(gameNumber, (totalBet - game.reward[player]), "OPPONENT_DISQUALIFIED");
            ethTransfer(gameNumber, player, reward);
            return true;
        }
        if ( !isEven(game.bets[player].actualChoice) && !isEven(game.bets[opponent].actualChoice) ) {  
            reward = (game.bets[player].betAmount + game.bets[opponent].betAmount) / 2;
            game.reward[player] = reward - commission;
             
             
            if ( game.claimedReward[opponent] ) {
                uint256 gameEarnings = (totalBet - game.reward[player] - game.reward[opponent]);
                contractEarnings = contractEarnings + gameEarnings;
                emit ContractEarnings(gameNumber, gameEarnings, "SPLIT_SPLIT");
            }
            ethTransfer(gameNumber, player, reward);
            return true;
        }
        if ( !isEven(game.bets[player].actualChoice) && isEven(game.bets[opponent].actualChoice) ) {  
            game.reward[player] = 0;
            if ( game.claimedReward[opponent] ) {
                gameEarnings = (totalBet - game.reward[player] - game.reward[opponent]);
                contractEarnings = contractEarnings + gameEarnings;
                emit ContractEarnings(gameNumber, gameEarnings, "SPLIT_STEAL");
            }
            return true;
        }
        if ( isEven(game.bets[player].actualChoice) && !isEven(game.bets[opponent].actualChoice) ) {  
            gameReward = (((100 + game.k) * game.bets[player].betAmount)/100);
            reward = gameReward < totalBet ? gameReward : totalBet; 
            game.reward[player] = reward - commission;
             
             
            if ( game.claimedReward[opponent] ) {
                gameEarnings = (totalBet - game.reward[player] - game.reward[opponent]);
                contractEarnings = contractEarnings + gameEarnings;
                emit ContractEarnings(gameNumber, gameEarnings, "STEAL_SPLIT");
            }
            ethTransfer(gameNumber, player, reward);
            return true;
        }
        if ( isEven(game.bets[player].actualChoice) && isEven(game.bets[opponent].actualChoice) ) {  
            reward = 0;
            if( game.bets[player].betAmount > game.bets[opponent].betAmount) {
                 
                reward = ((100 - game.k) * (game.bets[player].betAmount - game.bets[opponent].betAmount) / 2) / 100;
            }
            if(reward > 0) {
                 
                game.reward[player] = reward > commission ? reward - commission : 0;
            }
            if ( game.claimedReward[opponent] ) {
                gameEarnings = (totalBet - game.reward[player] - game.reward[opponent]);
                contractEarnings = contractEarnings + gameEarnings;
                emit ContractEarnings(gameNumber, gameEarnings, "STEAL_STEAL");
            }
            ethTransfer(gameNumber, player, reward);
            return true;
        }
    }
     


     
     
    function ownerAbandonOverride(uint _gameNumber) private returns(bool _overriden) {
        Game storage game = games[_gameNumber-1];
        if (game.registerationOpen) {
            if (now > (game.startTime + game.stageTimeout)) {
                game.claimedReward[game.player1] = true;
                game.registerationOpen = false;
                game.lastGameFinished = true;
                game.reward[game.player1] = game.bets[game.player1].betAmount; 
                 
                 
                ethTransfer(_gameNumber, game.player1, game.bets[game.player1].betAmount);
                return true;
            }                  
        }      
        return false;
    }

     

    function ownerRevealOverride(uint _gameNumber) private returns(bool _overriden) {
        Game storage game = games[_gameNumber-1];
        if ( game.revealing) {
            if (now > (game.revealTime + game.stageTimeout)) {
                if(!game.revealed[game.player1] && !game.revealed[game.player1]) {
                     
                     
                     
                     
                     
                    game.revealed[game.player1] = true;
                    game.disqualified[game.player1] = true;
                    game.claimedReward[game.player1] = true;
                    game.reward[game.player1] = 0;
                    emit Disqualified(_gameNumber, game.player1, "", 0, "");
                    game.revealed[game.player2] = true;
                    game.disqualified[game.player2] = true;
                    game.claimedReward[game.player2] = true;
                    game.reward[game.player2] = 0;
                    emit Disqualified(_gameNumber, game.player2, "", 0, "");
                    game.finishTime = now;
                    uint256 gameEarnings = game.bets[game.player1].betAmount + game.bets[game.player2].betAmount;
                    contractEarnings = contractEarnings + gameEarnings;
                    emit ContractEarnings(_gameNumber, gameEarnings, "BOTH_NO_REVEAL");
                } else if (game.revealed[game.player1] && !game.revealed[game.player2]) {
                    game.revealed[game.player2] = true;
                    game.disqualified[game.player2] = true;
                    game.claimedReward[game.player2] = true;
                    game.reward[game.player2] = 0;
                    emit Disqualified(_gameNumber, game.player2, "", 0, "");
                    game.finishTime = now;
                } else if (!game.revealed[game.player1] && game.revealed[game.player2]) {           
                    game.revealed[game.player1] = true;
                    game.disqualified[game.player1] = true;
                    game.claimedReward[game.player1] = true;
                    game.reward[game.player1] = 0;
                    emit Disqualified(_gameNumber, game.player1, "", 0, "");
                    game.finishTime = now;
                }
                game.revealing = false;
                game.lastGameFinished = true;
                emit RevealStop(_gameNumber);
                return true;
            }
        }
        return false;
    }

     
    function ownerClaimOverride(uint _gameNumber) private returns(bool _overriden) {
        Game storage game = games[_gameNumber-1];
        if ( game.lastGameFinished) {
            if (now > (game.finishTime + game.stageTimeout)) {
                if(!game.claimedReward[game.player1] && !game.claimedReward[game.player1]) {
                    game.claimedReward[game.player1] = true;
                    game.reward[game.player1] = 0;
                    game.claimedReward[game.player2] = true;
                    game.reward[game.player2] = 0;
                } else if (game.claimedReward[game.player1] && !game.claimedReward[game.player2]) {
                    game.claimedReward[game.player2] = true;
                    game.reward[game.player2] = 0;
                } else if (!game.claimedReward[game.player1] && game.claimedReward[game.player2]) {           
                    game.claimedReward[game.player1] = true;
                    game.reward[game.player1] = 0;
                } else {
                     
                    return false;
                }
                uint256 totalBet = (game.bets[game.player1].betAmount + game.bets[game.player2].betAmount);
                uint gameEarnings = totalBet - game.reward[game.player1] - game.reward[game.player2];
                contractEarnings = contractEarnings + gameEarnings;
                emit ContractEarnings(_gameNumber, gameEarnings, "OWNER_CLAIM_OVERRIDE");
            }
        }
    }

    function ownerOverride(uint _gameNumber) public onlyOwner returns(bool _overriden){
        if (msg.sender == owner) {
            if( ownerAbandonOverride(_gameNumber) || ownerRevealOverride(_gameNumber) || ownerClaimOverride(_gameNumber) ) {
                return true;
            }
        }
        return false;
    }
     

}