 

 


 

pragma solidity 0.5.4;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

pragma solidity 0.5.4;

 
contract Messages {
    struct AcceptGame {
        uint256 bet;
        bool isHost;
        address opponentAddress;
        bytes32 hashOfMySecret;
        bytes32 hashOfOpponentSecret;
    }
    
    struct SecretData {
        bytes32 salt;
        uint8 secret;
    }

     
    bytes32 public constant EIP712_DOMAIN_TYPEHASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

     
    bytes32 private constant ACCEPTGAME_TYPEHASH = 0x5ceee84403c984fbd9fb4ebf11b09c4f28f87290116c8b7f24a3e2a89d26588f;

     
    bytes32 public DOMAIN_SEPARATOR;

     
    function _hash(AcceptGame memory _acceptGame) internal pure returns (bytes32) {
        return keccak256(abi.encode(
            ACCEPTGAME_TYPEHASH,
            _acceptGame.bet,
            _acceptGame.isHost,
            _acceptGame.opponentAddress,
            _acceptGame.hashOfMySecret,
            _acceptGame.hashOfOpponentSecret
        ));
    }

     
    function _hashOfSecret(bytes32 _salt, uint8 _secret) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(_salt, _secret));
    }

     
    function _recoverAddress(
        bytes32 messageHash,
        bytes memory signature
    )
        internal
        view
        returns (address) 
    {
        bytes32 r;
        bytes32 s;
        bytes1 v;
         
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := mload(add(signature, 0x60))
        }
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            messageHash
        ));
        return ecrecover(digest, uint8(v), r, s);
    }

     
    function _getSignerAddress(
        uint256 _value,
        bool _isHost,
        address _opponentAddress,
        bytes32 _hashOfMySecret,
        bytes32 _hashOfOpponentSecret,
        bytes memory signature
    ) 
        internal
        view
        returns (address playerAddress) 
    {   
        AcceptGame memory message = AcceptGame({
            bet: _value,
            isHost: _isHost,
            opponentAddress: _opponentAddress,
            hashOfMySecret: _hashOfMySecret,
            hashOfOpponentSecret: _hashOfOpponentSecret
        });
        bytes32 messageHash = _hash(message);
        playerAddress = _recoverAddress(messageHash, signature);
    }
}

 

pragma solidity 0.5.4;

 
contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "not owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity 0.5.4;


 
contract Claimable is Ownable {
  address public pendingOwner;

   
  modifier onlyPendingOwner() {
    require(msg.sender == pendingOwner, "not pending owner");
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    pendingOwner = newOwner;
  }

   
  function claimOwnership() public onlyPendingOwner {
    emit OwnershipTransferred(_owner, pendingOwner);
    _owner = pendingOwner;
    pendingOwner = address(0);
  }
}

 

pragma solidity 0.5.4;

 
contract ERC20Basic {
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
}

 

pragma solidity 0.5.4;





 
contract FindTheRabbit is Messages, Claimable {
    using SafeMath for uint256;
    enum GameState { 
        Invalid,  
        HostBetted,  
        JoinBetted,  
        Filled,  
        DisputeOpenedByHost,  
        DisputeOpenedByJoin,  
        DisputeWonOnTimeoutByHost,  
        DisputeWonOnTimeoutByJoin,  
        CanceledByHost,  
        CanceledByJoin,  
        WonByHost,  
        WonByJoin  
    }
     
    event GameCreated(
        address indexed host, 
        address indexed join, 
        uint256 indexed bet, 
        bytes32 gameId, 
        GameState state
    );
     
    event GameOpened(bytes32 gameId, address indexed player);
     
    event GameCanceled(bytes32 gameId, address indexed player, address indexed opponent);
     
    event DisputeOpened(bytes32 gameId, address indexed disputeOpener, address indexed defendant);
     
    event DisputeResolved(bytes32 gameId, address indexed player);
     
    event DisputeClosedOnTimeout(bytes32 gameId, address indexed player);
     
    event WinnerReward(address indexed winner, uint256 amount);
     
    event JackpotReward(bytes32 gameId, address player, uint256 amount);
     
    event CurrentJackpotGame(bytes32 gameId);
     
    event ReferredReward(address referrer, uint256 amount);
     
    event ClaimedTokens(address token, address owner, uint256 amount);
    
     
     
    address public verifyingContract = address(this);
     
     
    bytes32 public salt;

     
    address payable public teamWallet;
    
     
    uint256 public commissionPercent;
    
     
     
     
     
     
    uint256 public referralPercent;

     
    uint256 public maxReferralPercent = 100;
    
     
    uint256 public minBet = 0.01 ether; 
    
     
    uint256 public jackpotPercent;
    
     
    uint256 public jackpotDrawTime;
    
     
    uint256 public jackpotValue;
    
     
    bytes32 public jackpotGameId;
    
     
    uint256 public jackpotGameTimerAddition;
    
     
    uint256 public jackpotAccumulationTimer;
    
     
    uint256 public revealTimer;
    
     
    uint256 public maxRevealTimer;
    
     
    uint256 public minRevealTimer;
    
     
     
    uint256 public disputeTimer; 
    
     
    uint256 public maxDisputeTimer;
    
     
    uint256 public minDisputeTimer; 

     
     
     
    uint256 public waitingBetTimer;
    
     
    uint256 public maxWaitingBetTimer;
    
     
    uint256 public minWaitingBetTimer;
    
     
    uint256 public gameDurationForJackpot;

    uint256 public chainId;

     
    mapping(bytes32 => Game) public games;
     
    mapping(bytes32 => Dispute) public disputes;
     
    mapping(address => Statistics) public players;

    struct Game {
        uint256 bet;  
        address payable host;  
        address payable join;  
        uint256 creationTime;  
        GameState state;  
        bytes hostSignature;  
        bytes joinSignature;  
        bytes32 gameId;  
    }

    struct Dispute {
        address payable disputeOpener;  
        uint256 creationTime;  
        bytes32 opponentHash;  
        uint256 secret;  
        bytes32 salt;  
        bool isHost;  
    }

    struct Statistics {
        uint256 totalGames;  
        uint256 totalUnrevealedGames;  
        uint256 totalNotFundedGames;  
        uint256 totalOpenedDisputes;  
        uint256 avgBetAmount;  
    }

     
    modifier isFilled(bytes32 _gameId) {
        require(games[_gameId].state == GameState.Filled, "game state is not Filled");
        _;
    }

     
    modifier verifyGameState(bytes32 _gameId) {
        require(
            games[_gameId].state == GameState.DisputeOpenedByHost ||
            games[_gameId].state == GameState.DisputeOpenedByJoin || 
            games[_gameId].state == GameState.Filled,
            "game state are not Filled or OpenedDispute"
        );
        _;
    }

     
    modifier isOpen(bytes32 _gameId) {
        require(
            games[_gameId].state == GameState.HostBetted ||
            games[_gameId].state == GameState.JoinBetted,
            "game state is not Open");
        _;
    }

     
    modifier onlyParticipant(bytes32 _gameId) {
        require(
            games[_gameId].host == msg.sender || games[_gameId].join == msg.sender,
            "you are not a participant of this game"
        );
        _;
    }

     
    constructor (
        uint256 _chainId, 
        address payable _teamWallet,
        uint256 _commissionPercent,
        uint256 _jackpotPercent,
        uint256 _referralPercent,
        uint256 _jackpotGameTimerAddition,
        uint256 _jackpotAccumulationTimer,
        uint256 _revealTimer,
        uint256 _disputeTimer,
        uint256 _waitingBetTimer,
        uint256 _gameDurationForJackpot,
        bytes32 _salt,
        uint256 _maxValueOfTimer
    ) public {
        teamWallet = _teamWallet;
        jackpotDrawTime = getTime().add(_jackpotAccumulationTimer);
        jackpotAccumulationTimer = _jackpotAccumulationTimer;
        commissionPercent = _commissionPercent;
        jackpotPercent = _jackpotPercent;
        referralPercent = _referralPercent;
        jackpotGameTimerAddition = _jackpotGameTimerAddition;
        revealTimer = _revealTimer;
        minRevealTimer = _revealTimer;
        maxRevealTimer = _maxValueOfTimer;
        disputeTimer = _disputeTimer;
        minDisputeTimer = _disputeTimer;
        maxDisputeTimer = _maxValueOfTimer;
        waitingBetTimer = _waitingBetTimer;
        minWaitingBetTimer = _waitingBetTimer;
        maxWaitingBetTimer = _maxValueOfTimer;
        gameDurationForJackpot = _gameDurationForJackpot;
        salt = _salt;
        chainId = _chainId;
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712_DOMAIN_TYPEHASH,
            keccak256("Find The Rabbit"),
            keccak256("0.1"),
            _chainId,
            verifyingContract,
            salt
        ));
    }

     
    function setWaitingBetTimerValue(uint256 _waitingBetTimer) external onlyOwner {
        require(_waitingBetTimer >= minWaitingBetTimer, "must be more than minWaitingBetTimer");
        require(_waitingBetTimer <= maxWaitingBetTimer, "must be less than maxWaitingBetTimer");
        waitingBetTimer = _waitingBetTimer;
    }

     
    function setDisputeTimerValue(uint256 _disputeTimer) external onlyOwner {
        require(_disputeTimer >= minDisputeTimer, "must be more than minDisputeTimer");
        require(_disputeTimer <= maxDisputeTimer, "must be less than maxDisputeTimer");
        disputeTimer = _disputeTimer;
    }

     
    function setRevealTimerValue(uint256 _revealTimer) external onlyOwner {
        require(_revealTimer >= minRevealTimer, "must be more than minRevealTimer");
        require(_revealTimer <= maxRevealTimer, "must be less than maxRevealTimer");
        revealTimer = _revealTimer;
    }

     
    function setMinBetValue(uint256 _newValue) external onlyOwner {
        require(_newValue != 0, "must be greater than 0");
        minBet = _newValue;
    }

     
    function setJackpotGameTimerAddition(uint256 _jackpotGameTimerAddition) external onlyOwner {
        if (chainId == 1) {
             
            require(jackpotValue <= 1 ether);
        }
        if (chainId == 99) {
             
            require(jackpotValue <= 4500 ether);
        }
        require(_jackpotGameTimerAddition >= 2 minutes, "must be more than 2 minutes");
        require(_jackpotGameTimerAddition <= 1 hours, "must be less than 1 hour");
        jackpotGameTimerAddition = _jackpotGameTimerAddition;
    }

     
    function setReferralPercentValue(uint256 _newValue) external onlyOwner {
        require(_newValue <= maxReferralPercent, "must be less than maxReferralPercent");
        referralPercent = _newValue;
    }

     
    function setCommissionPercent(uint256 _newValue) external onlyOwner {
        require(_newValue <= 20, "must be less than 20");
        commissionPercent = _newValue;
    }

     
    function setTeamWalletAddress(address payable _newTeamWallet) external onlyOwner {
        require(_newTeamWallet != address(0));
        teamWallet = _newTeamWallet;
    }

     
    function getJackpotInfo() 
        external 
        view 
        returns (
            uint256 _jackpotDrawTime, 
            uint256 _jackpotValue, 
            bytes32 _jackpotGameId
        ) 
    {
        _jackpotDrawTime = jackpotDrawTime;
        _jackpotValue = jackpotValue;
        _jackpotGameId = jackpotGameId;
    }

     
    function getTimers() 
        external
        view 
        returns (
            uint256 _revealTimer,
            uint256 _disputeTimer, 
            uint256 _waitingBetTimer, 
            uint256 _jackpotAccumulationTimer 
        )
    {
        _revealTimer = revealTimer;
        _disputeTimer = disputeTimer;
        _waitingBetTimer = waitingBetTimer;
        _jackpotAccumulationTimer = jackpotAccumulationTimer;
    }

     
    function claimTokens(address _token) public onlyOwner {
        ERC20Basic erc20token = ERC20Basic(_token);
        uint256 balance = erc20token.balanceOf(address(this));
        erc20token.transfer(owner(), balance);
        emit ClaimedTokens(_token, owner(), balance);
    }

     
    function createGame(
        bool _isHost,
        bytes32 _hashOfMySecret,
        bytes32 _hashOfOpponentSecret,
        bytes memory _hostSignature,
        bytes memory _joinSignature
    )
        public 
        payable
    {       
        require(msg.value >= minBet, "must be greater than the minimum value");
        bytes32 gameId = getGameId(_hostSignature, _joinSignature);
        address opponent = _getSignerAddress(
            msg.value,
            !_isHost, 
            msg.sender,
            _hashOfOpponentSecret, 
            _hashOfMySecret,
            _isHost ? _joinSignature : _hostSignature);
        require(opponent != msg.sender, "send your opponent's signature");
        Game storage game = games[gameId];
        if (game.gameId == 0){
            _recordGameInfo(msg.value, _isHost, gameId, opponent, _hostSignature, _joinSignature);
            emit GameOpened(game.gameId, msg.sender);
        } else {
            require(game.host == msg.sender || game.join == msg.sender, "you are not paticipant in this game");
            require(game.state == GameState.HostBetted || game.state == GameState.JoinBetted, "the game is not Opened");
            if (_isHost) {
                require(game.host == msg.sender, "you are not the host in this game");
                require(game.join == opponent, "invalid join signature");
                require(game.state == GameState.JoinBetted, "you have already made a bet");
            } else {
                require(game.join == msg.sender, "you are not the join in this game.");
                require(game.host == opponent, "invalid host signature");
                require(game.state == GameState.HostBetted, "you have already made a bet");
            }
            game.creationTime = getTime();
            game.state = GameState.Filled;
            emit GameCreated(game.host, game.join, game.bet, game.gameId, game.state);
        }
    }

     
    function win(
        bytes32 _gameId,
        uint8 _hostSecret,
        bytes32 _hostSalt,
        uint8 _joinSecret,
        bytes32 _joinSalt,
        address payable _referrer
    ) 
        public
        verifyGameState(_gameId)
        onlyParticipant(_gameId)
    {
        Game storage game = games[_gameId];
        bytes32 hashOfHostSecret = _hashOfSecret(_hostSalt, _hostSecret);
        bytes32 hashOfJoinSecret = _hashOfSecret(_joinSalt, _joinSecret);

        address host = _getSignerAddress(
            game.bet,
            true, 
            game.join,
            hashOfHostSecret,
            hashOfJoinSecret, 
            game.hostSignature
        );
        address join = _getSignerAddress(
            game.bet,
            false, 
            game.host,
            hashOfJoinSecret,
            hashOfHostSecret,
            game.joinSignature
        );
        require(host == game.host && join == game.join, "invalid reveals");
        address payable winner;
        if (_hostSecret == _joinSecret){
            winner = game.join;
            game.state = GameState.WonByJoin;
        } else {
            winner = game.host;
            game.state = GameState.WonByHost;
        }
        if (isPlayerExist(_referrer) && _referrer != msg.sender) {
            _processPayments(game.bet, winner, _referrer);
        }
        else {
            _processPayments(game.bet, winner, address(0));
        }
        _jackpotPayoutProcessing(_gameId); 
        _recordStatisticInfo(game.host, game.join, game.bet);
    }

     
    function openDispute(
        bytes32 _gameId,
        uint8 _secret,
        bytes32 _salt,
        bool _isHost,
        bytes32 _hashOfOpponentSecret
    )
        public
        onlyParticipant(_gameId)
    {
        require(timeUntilOpenDispute(_gameId) == 0, "the waiting time for revealing is not over yet");
        Game storage game = games[_gameId];
        require(isSecretDataValid(
            _gameId,
            _secret,
            _salt,
            _isHost,
            _hashOfOpponentSecret
        ), "invalid salt or secret");
        _recordDisputeInfo(_gameId, msg.sender, _hashOfOpponentSecret, _secret, _salt, _isHost);
        game.state = _isHost ? GameState.DisputeOpenedByHost : GameState.DisputeOpenedByJoin;
        address defendant = _isHost ? game.join : game.host;
        players[msg.sender].totalOpenedDisputes = (players[msg.sender].totalOpenedDisputes).add(1);
        players[defendant].totalUnrevealedGames = (players[defendant].totalUnrevealedGames).add(1);
        emit DisputeOpened(_gameId, msg.sender, defendant);
    }

     
    function resolveDispute(
        bytes32 _gameId,
        uint8 _secret,
        bytes32 _salt,
        bool _isHost,
        bytes32 _hashOfOpponentSecret
    ) 
        public
        returns(address payable winner)
    {
        require(isDisputeOpened(_gameId), "there is no dispute");
        Game storage game = games[_gameId];
        Dispute memory dispute = disputes[_gameId];
        require(msg.sender != dispute.disputeOpener, "only for the opponent");
        require(isSecretDataValid(
            _gameId,
            _secret,
            _salt,
            _isHost,
            _hashOfOpponentSecret
        ), "invalid salt or secret");
        if (_secret == dispute.secret) {
            winner = game.join;
            game.state = GameState.WonByJoin;
        } else {
            winner = game.host;
            game.state = GameState.WonByHost;
        }
        _processPayments(game.bet, winner, address(0));
        _jackpotPayoutProcessing(_gameId);
        _recordStatisticInfo(game.host, game.join, game.bet);
        emit DisputeResolved(_gameId, msg.sender);
    }

     
    function closeDisputeOnTimeout(bytes32 _gameId) public returns (address payable winner) {
        Game storage game = games[_gameId];
        Dispute memory dispute = disputes[_gameId];
        require(timeUntilCloseDispute(_gameId) == 0, "the time has not yet come out");
        winner = dispute.disputeOpener;
        game.state = (winner == game.host) ? GameState.DisputeWonOnTimeoutByHost : GameState.DisputeWonOnTimeoutByJoin;
        _processPayments(game.bet, winner, address(0));
        _jackpotPayoutProcessing(_gameId);
        _recordStatisticInfo(game.host, game.join, game.bet);
        emit DisputeClosedOnTimeout(_gameId, msg.sender);
    }

     
    function cancelGame(
        bytes32 _gameId
    ) 
        public
        onlyParticipant(_gameId) 
    {
        require(timeUntilCancel(_gameId) == 0, "the waiting time for the second player's bet is not over yet");
        Game storage game = games[_gameId];
        address payable recipient;
        recipient = game.state == GameState.HostBetted ? game.host : game.join;
        address defendant = game.state == GameState.HostBetted ? game.join : game.host;
        game.state = (recipient == game.host) ? GameState.CanceledByHost : GameState.CanceledByJoin;
        recipient.transfer(game.bet);
        players[defendant].totalNotFundedGames = (players[defendant].totalNotFundedGames).add(1);
        emit GameCanceled(_gameId, msg.sender, defendant);
    }

     
    function drawJackpot() public {
        require(isJackpotAvailable(), "is not avaliable yet");
        require(jackpotGameId != 0, "no game to claim on the jackpot");
        require(jackpotValue != 0, "jackpot's empty");
        _payoutJackpot();
    }

     
    function isDisputeOpened(bytes32 _gameId) public view returns(bool) {
        return (
            games[_gameId].state == GameState.DisputeOpenedByHost ||
            games[_gameId].state == GameState.DisputeOpenedByJoin
        );
    }
    
     
    function isPlayerExist(address _player) public view returns (bool) {
        return players[_player].totalGames != 0;
    }

     
    function timeUntilCancel(
        bytes32 _gameId
    )
        public
        view 
        isOpen(_gameId) 
        returns (uint256 remainingTime) 
    {
        uint256 timePassed = getTime().sub(games[_gameId].creationTime);
        if (waitingBetTimer > timePassed) {
            return waitingBetTimer.sub(timePassed);
        } else {
            return 0;
        }
    }

     
    function timeUntilOpenDispute(
        bytes32 _gameId
    )
        public
        view 
        isFilled(_gameId) 
        returns (uint256 remainingTime) 
    {
        uint256 timePassed = getTime().sub(games[_gameId].creationTime);
        if (revealTimer > timePassed) {
            return revealTimer.sub(timePassed);
        } else {
            return 0;
        }
    }

     
    function timeUntilCloseDispute(
        bytes32 _gameId
    )
        public
        view 
        returns (uint256 remainingTime) 
    {
        require(isDisputeOpened(_gameId), "there is no open dispute");
        uint256 timePassed = getTime().sub(disputes[_gameId].creationTime);
        if (disputeTimer > timePassed) {
            return disputeTimer.sub(timePassed);
        } else {
            return 0;
        }
    }

     
    function getTime() public view returns(uint) {
        return block.timestamp;
    }

     
    function getGameState(bytes32 _gameId) public view returns(GameState) {
        return games[_gameId].state;
    }

     
    function isSecretDataValid(
        bytes32 _gameId,
        uint8 _secret,
        bytes32 _salt,
        bool _isHost,
        bytes32 _hashOfOpponentSecret
    )
        public
        view
        returns (bool)
    {
        Game memory game = games[_gameId];
        bytes32 hashOfPlayerSecret = _hashOfSecret(_salt, _secret);
        address player = _getSignerAddress(
            game.bet,
            _isHost, 
            _isHost ? game.join : game.host,
            hashOfPlayerSecret,
            _hashOfOpponentSecret, 
            _isHost ? game.hostSignature : game.joinSignature
        );
        require(msg.sender == player, "the received address does not match with msg.sender");
        if (_isHost) {
            return player == game.host;
        } else {
            return player == game.join;
        }
    }

     
    function isJackpotAvailable() public view returns (bool) {
        return getTime() >= jackpotDrawTime;
    }

    function isGameAllowedForJackpot(bytes32 _gameId) public view returns (bool) {
        return getTime() - games[_gameId].creationTime < gameDurationForJackpot;
    }

     
    function getGamesStates(bytes32[] memory _games) public view returns(GameState[] memory) {
        GameState[] memory _states = new GameState[](_games.length);
        for (uint i=0; i<_games.length; i++) {
            Game storage game = games[_games[i]];
            _states[i] = game.state;
        }
        return _states;
    }

     
    function getPlayersStatistic(address[] memory _players) public view returns(uint[] memory) {
        uint[] memory _statistics = new uint[](_players.length * 5);
        for (uint i=0; i<_players.length; i++) {
            Statistics storage player = players[_players[i]];
            _statistics[5*i + 0] = player.totalGames;
            _statistics[5*i + 1] = player.totalUnrevealedGames;
            _statistics[5*i + 2] = player.totalNotFundedGames;
            _statistics[5*i + 3] = player.totalOpenedDisputes;
            _statistics[5*i + 4] = player.avgBetAmount;
        }
        return _statistics;
    }

     
    function getGameId(bytes memory _signatureHost, bytes memory _signatureJoin) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_signatureHost, _signatureJoin));
    }

     
    function _payoutJackpot() internal {
        Game storage jackpotGame = games[jackpotGameId];
        uint256 reward = jackpotValue.div(2);
        jackpotValue = 0;
        jackpotGameId = 0;
        jackpotDrawTime = (getTime()).add(jackpotAccumulationTimer);
        if (jackpotGame.host.send(reward)) {
            emit JackpotReward(jackpotGame.gameId, jackpotGame.host, reward.mul(2));
        }
        if (jackpotGame.join.send(reward)) {
            emit JackpotReward(jackpotGame.gameId, jackpotGame.join, reward.mul(2));
        }
    }
      
    function _addGameToJackpot(bytes32 _gameId) internal {
        jackpotDrawTime = jackpotDrawTime.add(jackpotGameTimerAddition);
        jackpotGameId = _gameId;
        emit CurrentJackpotGame(_gameId);
    }

      
    function _jackpotPayoutProcessing(bytes32 _gameId) internal {
        if (isJackpotAvailable()) {
            if (jackpotGameId != 0 && jackpotValue != 0) {
                _payoutJackpot();
            }
            else {
                jackpotDrawTime = (getTime()).add(jackpotAccumulationTimer);
            }
        }
        if (isGameAllowedForJackpot(_gameId)) {
            _addGameToJackpot(_gameId);
        }
    }
    
      
    function _processPayments(uint256 _bet, address payable _winner, address payable _referrer) internal {
        uint256 doubleBet = (_bet).mul(2);
        uint256 commission = (doubleBet.mul(commissionPercent)).div(100);        
        uint256 jackpotPart = (doubleBet.mul(jackpotPercent)).div(100);
        uint256 winnerStake;
        if (_referrer != address(0) && referralPercent != 0 ) {
            uint256 referrerPart = (doubleBet.mul(referralPercent)).div(1000);
            winnerStake = doubleBet.sub(commission).sub(jackpotPart).sub(referrerPart);
            if (_referrer.send(referrerPart)) {
                emit ReferredReward(_referrer, referrerPart);
            }
        }
        else {
            winnerStake = doubleBet.sub(commission).sub(jackpotPart);
        }
        jackpotValue = jackpotValue.add(jackpotPart);
        _winner.transfer(winnerStake);
        teamWallet.transfer(commission);
        emit WinnerReward(_winner, winnerStake);
    }

      
    function _recordGameInfo(
        uint256 _value,
        bool _isHost, 
        bytes32 _gameId, 
        address _opponent,
        bytes memory _hostSignature,
        bytes memory _joinSignature
    ) internal {
        Game memory _game = Game({
            bet: _value,
            host: _isHost ? msg.sender : address(uint160(_opponent)),
            join: _isHost ? address(uint160(_opponent)) : msg.sender,
            creationTime: getTime(),
            state: _isHost ? GameState.HostBetted : GameState.JoinBetted ,
            gameId: _gameId,
            hostSignature: _hostSignature,
            joinSignature: _joinSignature
        });
        games[_gameId] = _game;  
    }

      
    function _recordDisputeInfo(
        bytes32 _gameId,
        address payable _disputeOpener,
        bytes32 _hashOfOpponentSecret,
        uint8 _secret,
        bytes32 _salt,
        bool _isHost 
    ) internal {
        Dispute memory _dispute = Dispute({
            disputeOpener: _disputeOpener,
            creationTime: getTime(),
            opponentHash: _hashOfOpponentSecret,
            secret: _secret,
            salt: _salt,
            isHost: _isHost
        });
        disputes[_gameId] = _dispute;
    }

      
    function _recordStatisticInfo(address _host, address _join, uint256 _bet) internal {
        Statistics storage statHost = players[_host];
        Statistics storage statJoin = players[_join];
        statHost.avgBetAmount = _calculateAvgBet(_host, _bet);
        statJoin.avgBetAmount = _calculateAvgBet(_join, _bet);
        statHost.totalGames = (statHost.totalGames).add(1);
        statJoin.totalGames = (statJoin.totalGames).add(1);
    }

      
    function _calculateAvgBet(address _player, uint256 _bet) internal view returns (uint256 newAvgBetValue){
        Statistics storage statistics = players[_player];
        uint256 totalBets = (statistics.avgBetAmount).mul(statistics.totalGames).add(_bet);
        newAvgBetValue = totalBets.div(statistics.totalGames.add(1));
    }

}