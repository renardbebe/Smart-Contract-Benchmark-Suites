 

pragma solidity ^0.4.18;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) public pure returns(uint);

    function maxBalance() public pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) public pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        view
        returns(int);

    function serverForceGameEnd(
        uint8 gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        returns(int);

    function playerForceGameEnd(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        uint _endInitiatedTime
    )
        public
        view
        returns(int);
}

library MathUtil {
     
    function abs(int _val) internal pure returns(uint) {
        if (_val < 0) {
            return uint(-_val);
        } else {
            return uint(_val);
        }
    }

     
    function max(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 >= _val2 ? _val1 : _val2;
    }

     
    function min(uint _val1, uint _val2) internal pure returns(uint) {
        return _val1 <= _val2 ? _val1 : _val2;
    }
}

contract Ownable {
    address public owner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    function Ownable() public {
        owner = msg.sender;
    }

     
    function setOwner(address _newOwner) public onlyOwner {
        require(_newOwner != address(0));
        LogOwnerShipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

contract ConflictResolutionManager is Ownable {
     
    ConflictResolutionInterface public conflictRes;

     
    address public newConflictRes = 0;

     
    uint public updateTime = 0;

     
    uint public constant MIN_TIMEOUT = 3 days;

     
    uint public constant MAX_TIMEOUT = 6 days;

     
    event LogUpdatingConflictResolution(address newConflictResolutionAddress);

     
    event LogUpdatedConflictResolution(address newConflictResolutionAddress);

     
    function ConflictResolutionManager(address _conflictResAddress) public {
        conflictRes = ConflictResolutionInterface(_conflictResAddress);
    }

     
    function updateConflictResolution(address _newConflictResAddress) public onlyOwner {
        newConflictRes = _newConflictResAddress;
        updateTime = block.timestamp;

        LogUpdatingConflictResolution(_newConflictResAddress);
    }

     
    function activateConflictResolution() public onlyOwner {
        require(newConflictRes != 0);
        require(updateTime != 0);
        require(updateTime + MIN_TIMEOUT <= block.timestamp && block.timestamp <= updateTime + MAX_TIMEOUT);

        conflictRes = ConflictResolutionInterface(newConflictRes);
        newConflictRes = 0;
        updateTime = 0;

        LogUpdatedConflictResolution(newConflictRes);
    }
}

contract Pausable is Ownable {
     
    bool public paused = false;

     
    uint public timePaused = 0;

     
    modifier onlyNotPaused() {
        require(!paused);
        _;
    }

     
    modifier onlyPaused() {
        require(paused);
        _;
    }

     
    modifier onlyPausedSince(uint timeSpan) {
        require(paused && timePaused + timeSpan <= block.timestamp);
        _;
    }

     
    event LogPause();

     
    event LogUnpause();

     
    function pause() public onlyOwner onlyNotPaused {
        paused = true;
        timePaused = block.timestamp;
        LogPause();
    }

     
    function unpause() public onlyOwner onlyPaused {
        paused = false;
        timePaused = 0;
        LogUnpause();
    }
}

contract Destroyable is Pausable {
     
    uint public constant TIMEOUT_DESTROY = 20 days;

     
    function destroy() public onlyOwner onlyPausedSince(TIMEOUT_DESTROY) {
        selfdestruct(owner);
    }
}

contract GameChannelBase is Destroyable, ConflictResolutionManager {
     
    enum GameStatus {
        ENDED,  
        ACTIVE,  
        WAITING_FOR_SERVER,  
        PLAYER_INITIATED_END,  
        SERVER_INITIATED_END  
    }

     
    enum ReasonEnded {
        REGULAR_ENDED,  
        END_FORCED_BY_SERVER,  
        END_FORCED_BY_PLAYER,  
        REJECTED_BY_SERVER,  
        CANCELLED_BY_PLAYER  
    }

    struct Game {
         
        GameStatus status;

         
        ReasonEnded reasonEnded;

         
        uint stake;

         
         
        uint8 gameType;
        uint32 roundId;
        uint16 betNum;
        uint betValue;
        int balance;
        bytes32 playerSeed;
        bytes32 serverSeed;
        uint endInitiatedTime;
    }

     
    uint public constant MIN_TRANSFER_TIMESPAN = 1 days;

     
    uint public constant MAX_TRANSFER_TIMSPAN = 6 * 30 days;

     
    uint public activeGames = 0;

     
     
    uint public gameIdCntr;

     
    address public serverAddress;

     
    address public houseAddress;

     
    uint public houseStake = 0;

     
    int public houseProfit = 0;

     
    uint public minStake;

     
    uint public maxStake;

     
    uint public profitTransferTimeSpan = 14 days;

     
    uint public lastProfitTransferTimestamp;

    bytes32 public typeHash;

     
    mapping (uint => Game) public gameIdGame;

     
    mapping (address => uint) public playerGameId;

     
    mapping (address => uint) public pendingReturns;

     
    modifier onlyValidHouseStake(uint _activeGames) {
        uint minHouseStake = conflictRes.minHouseStake(_activeGames);
        require(houseStake >= minHouseStake);
        _;
    }

     
    modifier onlyValidValue() {
        require(minStake <= msg.value && msg.value <= maxStake);
        _;
    }

     
    modifier onlyServer() {
        require(msg.sender == serverAddress);
        _;
    }

     
    modifier onlyValidTransferTimeSpan(uint transferTimeout) {
        require(transferTimeout >= MIN_TRANSFER_TIMESPAN
                && transferTimeout <= MAX_TRANSFER_TIMSPAN);
        _;
    }

     
    event LogGameCreated(address indexed player, uint indexed gameId, uint stake, bytes32 endHash);

     
    event LogGameRejected(address indexed player, uint indexed gameId);

     
    event LogGameAccepted(address indexed player, uint indexed gameId, bytes32 endHash);

     
    event LogPlayerRequestedEnd(address indexed player, uint indexed gameId);

     
    event LogServerRequestedEnd(address indexed player, uint indexed gameId);

     
    event LogGameEnded(address indexed player, uint indexed gameId, ReasonEnded reason);

     
    event LogStakeLimitsModified(uint minStake, uint maxStake);

     
    function GameChannelBase(
        address _serverAddress,
        uint _minStake,
        uint _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCntr
    )
        public
        ConflictResolutionManager(_conflictResAddress)
    {
        require(_minStake > 0 && _minStake <= _maxStake);
        require(_gameIdCntr > 0);

        gameIdCntr = _gameIdCntr;
        serverAddress = _serverAddress;
        houseAddress = _houseAddress;
        lastProfitTransferTimestamp = block.timestamp;
        minStake = _minStake;
        maxStake = _maxStake;

        typeHash = keccak256(
            "uint32 Round Id",
            "uint8 Game Type",
            "uint16 Number",
            "uint Value (Wei)",
            "int Current Balance (Wei)",
            "bytes32 Server Hash",
            "bytes32 Player Hash",
            "uint Game Id",
            "address Contract Address"
        );
    }

     
    function withdraw() public {
        uint toTransfer = pendingReturns[msg.sender];
        require(toTransfer > 0);

        pendingReturns[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
    }

     
    function transferProfitToHouse() public {
        require(lastProfitTransferTimestamp + profitTransferTimeSpan <= block.timestamp);

        if (houseProfit <= 0) {
             
            lastProfitTransferTimestamp = block.timestamp;
            return;
        }

         
        uint toTransfer = uint(houseProfit);
        assert(houseStake >= toTransfer);

        houseProfit = 0;
        lastProfitTransferTimestamp = block.timestamp;
        houseStake = houseStake - toTransfer;

        houseAddress.transfer(toTransfer);
    }

     
    function setProfitTransferTimeSpan(uint _profitTransferTimeSpan)
        public
        onlyOwner
        onlyValidTransferTimeSpan(_profitTransferTimeSpan)
    {
        profitTransferTimeSpan = _profitTransferTimeSpan;
    }

     
    function addHouseStake() public payable onlyOwner {
        houseStake += msg.value;
    }

     
    function withdrawHouseStake(uint value) public onlyOwner {
        uint minHouseStake = conflictRes.minHouseStake(activeGames);

        require(value <= houseStake && houseStake - value >= minHouseStake);
        require(houseProfit <= 0 || uint(houseProfit) <= houseStake - value);

        houseStake = houseStake - value;
        owner.transfer(value);
    }

     
    function withdrawAll() public onlyOwner onlyPausedSince(3 days) {
        houseProfit = 0;
        uint toTransfer = houseStake;
        houseStake = 0;
        owner.transfer(toTransfer);
    }

     
    function setHouseAddress(address _houseAddress) public onlyOwner {
        houseAddress = _houseAddress;
    }

     
    function setStakeRequirements(uint _minStake, uint _maxStake) public onlyOwner {
        require(_minStake > 0 && _minStake <= _maxStake);
        minStake = _minStake;
        maxStake = _maxStake;
        LogStakeLimitsModified(minStake, maxStake);
    }

     
    function closeGame(
        Game storage _game,
        uint _gameId,
        address _playerAddress,
        ReasonEnded _reason,
        int _balance
    )
        internal
    {
        _game.status = GameStatus.ENDED;
        _game.reasonEnded = _reason;
        _game.balance = _balance;

        assert(activeGames > 0);
        activeGames = activeGames - 1;

        LogGameEnded(_playerAddress, _gameId, _reason);
    }

     
    function payOut(Game storage _game, address _playerAddress) internal {
        assert(_game.balance <= conflictRes.maxBalance());
        assert(_game.status == GameStatus.ENDED);
        assert(_game.stake <= maxStake);
        assert((int(_game.stake) + _game.balance) >= 0);

        uint valuePlayer = uint(int(_game.stake) + _game.balance);

        if (_game.balance > 0 && int(houseStake) < _game.balance) {
             
             
             
            valuePlayer = houseStake;
        }

        houseProfit = houseProfit - _game.balance;

        int newHouseStake = int(houseStake) - _game.balance;
        assert(newHouseStake >= 0);
        houseStake = uint(newHouseStake);

        pendingReturns[_playerAddress] += valuePlayer;
        if (pendingReturns[_playerAddress] > 0) {
            safeSend(_playerAddress);
        }
    }

     
    function safeSend(address _address) internal {
        uint valueToSend = pendingReturns[_address];
        assert(valueToSend > 0);

        pendingReturns[_address] = 0;
        if (_address.send(valueToSend) == false) {
            pendingReturns[_address] = valueToSend;
        }
    }

     
    function verifySig(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _sig,
        address _address
    )
        internal
        view
    {
         
        address contractAddress = this;
        require(_contractAddress == contractAddress);

        bytes32 roundHash = calcHash(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress
        );

        verify(
                roundHash,
                _sig,
                _address
        );
    }

     
    function calcHash(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress
    )
        private
        view
        returns(bytes32)
    {
        bytes32 dataHash = keccak256(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _playerHash,
            _gameId,
            _contractAddress
        );

        return keccak256(typeHash, dataHash);
    }

      
    function verify(
        bytes32 _hash,
        bytes _sig,
        address _address
    )
        private
        pure
    {
        var (r, s, v) = signatureSplit(_sig);
        address addressRecover = ecrecover(_hash, v, r, s);
        require(addressRecover == _address);
    }

     
    function signatureSplit(bytes _signature)
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(_signature.length == 65);

        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := and(mload(add(_signature, 65)), 0xff)
        }
        if (v < 2) {
            v = v + 27;
        }
    }
}

contract GameChannelConflict is GameChannelBase {
     
    function GameChannelConflict(
        address _serverAddress,
        uint _minStake,
        uint _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCtr
    )
        public
        GameChannelBase(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _gameIdCtr)
    {
         
    }

     
    function serverEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _playerSig,
        address _playerAddress,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress,
                _playerSig,
                _playerAddress
        );

        serverEndGameConflictImpl(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _serverSeed,
                _playerSeed,
                _gameId,
                _playerAddress
        );
    }

     
    function playerEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig,
        bytes32 _playerSeed
    )
        public
    {
        verifySig(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _playerHash,
            _gameId,
            _contractAddress,
            _serverSig,
            serverAddress
        );

        playerEndGameConflictImpl(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _playerHash,
            _playerSeed,
            _gameId,
            msg.sender
        );
    }

     
    function playerCancelActiveGame(uint _gameId) public {
        address playerAddress = msg.sender;
        uint gameId = playerGameId[playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.PLAYER_INITIATED_END;

            LogPlayerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == 0) {
            closeGame(game, gameId, playerAddress, ReasonEnded.REGULAR_ENDED, 0);
            payOut(game, playerAddress);
        } else {
            revert();
        }
    }

     
    function serverCancelActiveGame(address _playerAddress, uint _gameId) public onlyServer {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.SERVER_INITIATED_END;

            LogServerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId == 0) {
            closeGame(game, gameId, _playerAddress, ReasonEnded.REGULAR_ENDED, 0);
            payOut(game, _playerAddress);
        } else {
            revert();
        }
    }

     
    function serverForceGameEnd(address _playerAddress, uint _gameId) public onlyServer {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);
        require(game.status == GameStatus.SERVER_INITIATED_END);

         
         
        int newBalance = conflictRes.serverForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, _playerAddress, ReasonEnded.END_FORCED_BY_SERVER, newBalance);
        payOut(game, _playerAddress);
    }

     
    function playerForceGameEnd(uint _gameId) public {
        address playerAddress = msg.sender;
        uint gameId = playerGameId[playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);
        require(game.status == GameStatus.PLAYER_INITIATED_END);

        int newBalance = conflictRes.playerForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, playerAddress, ReasonEnded.END_FORCED_BY_PLAYER, newBalance);
        payOut(game, playerAddress);
    }

     
    function playerEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _playerHash,
        bytes32 _playerSeed,
        uint _gameId,
        address _playerAddress
    )
        private
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();

        require(gameId == _gameId);
        require(_roundId > 0);
        require(keccak256(_playerSeed) == _playerHash);
        require(_value <= game.stake);
        require(-int(game.stake) <= _balance && _balance <= maxBalance);  
        require(int(game.stake) + _balance - int(_value) >= 0);  
        require(conflictRes.isValidBet(_gameType, _num, _value));

        if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == _roundId) {
            game.playerSeed = _playerSeed;
            endGameConflict(game, gameId, _playerAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.SERVER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.PLAYER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.playerSeed = _playerSeed;
            game.serverSeed = bytes32(0);

            LogPlayerRequestedEnd(msg.sender, gameId);
        } else {
            revert();
        }
    }

     
    function serverEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        bytes32 _serverSeed,
        bytes32 _playerSeed,
        uint _gameId,
        address _playerAddress
    )
        private
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();

        require(gameId == _gameId);
        require(_roundId > 0);
        require(keccak256(_serverSeed) == _serverHash);
        require(keccak256(_playerSeed) == _playerHash);
        require(_value <= game.stake);
        require(-int(game.stake) <= _balance && _balance <= maxBalance);  
        require(int(game.stake) + _balance - int(_value) >= 0);  
        require(conflictRes.isValidBet(_gameType, _num, _value));


        if (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId == _roundId) {
            game.serverSeed = _serverSeed;
            endGameConflict(game, gameId, _playerAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.SERVER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.serverSeed = _serverSeed;
            game.playerSeed = _playerSeed;

            LogServerRequestedEnd(_playerAddress, gameId);
        } else {
            revert();
        }
    }

     
    function endGameConflict(Game storage _game, uint _gameId, address _playerAddress) private {
        int newBalance = conflictRes.endGameConflict(
            _game.gameType,
            _game.betNum,
            _game.betValue,
            _game.balance,
            _game.stake,
            _game.serverSeed,
            _game.playerSeed
        );

        closeGame(_game, _gameId, _playerAddress, ReasonEnded.REGULAR_ENDED, newBalance);
        payOut(_game, _playerAddress);
    }
}

contract GameChannel is GameChannelConflict {
     
    function GameChannel(
        address _serverAddress,
        uint _minStake,
        uint _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCntr
    )
        public
        GameChannelConflict(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _gameIdCntr)
    {
         
    }

     
    function createGame(bytes32 _endHash)
        public
        payable
        onlyValidValue
        onlyValidHouseStake(activeGames + 1)
        onlyNotPaused
    {
        address playerAddress = msg.sender;
        uint previousGameId = playerGameId[playerAddress];
        Game storage game = gameIdGame[previousGameId];

        require(game.status == GameStatus.ENDED);

        uint gameId = gameIdCntr++;
        playerGameId[playerAddress] = gameId;
        Game storage newGame = gameIdGame[gameId];

        newGame.stake = msg.value;
        newGame.status = GameStatus.WAITING_FOR_SERVER;

        activeGames = activeGames + 1;

        LogGameCreated(playerAddress, gameId, msg.value, _endHash);
    }

     
    function cancelGame(uint _gameId) public {
        address playerAddress = msg.sender;
        uint gameId = playerGameId[playerAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId);
        require(game.status == GameStatus.WAITING_FOR_SERVER);

        closeGame(game, gameId, playerAddress, ReasonEnded.CANCELLED_BY_PLAYER, 0);
        payOut(game, playerAddress);
    }

     
    function rejectGame(address _playerAddress, uint _gameId) public onlyServer {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];

        require(_gameId == gameId);
        require(game.status == GameStatus.WAITING_FOR_SERVER);

        closeGame(game, gameId, _playerAddress, ReasonEnded.REJECTED_BY_SERVER, 0);
        payOut(game, _playerAddress);

        LogGameRejected(_playerAddress, gameId);
    }

     
    function acceptGame(address _playerAddress, uint _gameId, bytes32 _endHash)
        public
        onlyServer
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];

        require(_gameId == gameId);
        require(game.status == GameStatus.WAITING_FOR_SERVER);

        game.status = GameStatus.ACTIVE;

        LogGameAccepted(_playerAddress, gameId, _endHash);
    }

     
    function serverEndGame(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        address _playerAddress,
        bytes _playerSig
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress,
                _playerSig,
                _playerAddress
        );

        regularEndGame(_playerAddress, _roundId, _gameType, _num, _value, _balance, _gameId, _contractAddress);
    }

     
    function playerEndGame(
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _playerHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig
    )
        public
    {
        verifySig(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _playerHash,
                _gameId,
                _contractAddress,
                _serverSig,
                serverAddress
        );

        regularEndGame(msg.sender, _roundId, _gameType, _num, _value, _balance, _gameId, _contractAddress);
    }

     
    function regularEndGame(
        address _playerAddress,
        uint32 _roundId,
        uint8 _gameType,
        uint16 _num,
        uint _value,
        int _balance,
        uint _gameId,
        address _contractAddress
    )
        private
    {
        uint gameId = playerGameId[_playerAddress];
        Game storage game = gameIdGame[gameId];
        address contractAddress = this;
        int maxBalance = conflictRes.maxBalance();

        require(_gameId == gameId);
        require(_roundId > 0);
         
        require(-int(game.stake) <= _balance && _balance <= maxBalance);
        require((_gameType == 0) && (_num == 0) && (_value == 0));
        require(_contractAddress == contractAddress);
        require(game.status == GameStatus.ACTIVE);

        closeGame(game, gameId, _playerAddress, ReasonEnded.REGULAR_ENDED, _balance);
        payOut(game, _playerAddress);
    }
}