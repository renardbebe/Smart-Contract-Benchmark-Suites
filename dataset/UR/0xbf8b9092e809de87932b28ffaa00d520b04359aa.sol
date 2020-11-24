 

pragma solidity ^0.4.24;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) external pure returns(uint);

    function maxBalance() external pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) external pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _playerSeed
    )
        external
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
        external
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
        external
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
    address public pendingOwner;

    event LogOwnerShipTransferred(address indexed previousOwner, address indexed newOwner);
    event LogOwnerShipTransferInitiated(address indexed previousOwner, address indexed newOwner);

     
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

     
    modifier onlyPendingOwner() {
        require(msg.sender == pendingOwner);
        _;
    }

     
    constructor() public {
        owner = msg.sender;
        pendingOwner = address(0);
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        pendingOwner = _newOwner;
        emit LogOwnerShipTransferInitiated(owner, _newOwner);
    }

     
    function claimOwnership() public onlyPendingOwner {
        emit LogOwnerShipTransferred(owner, pendingOwner);
        owner = pendingOwner;
        pendingOwner = address(0);
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

     
    constructor(address _conflictResAddress) public {
        conflictRes = ConflictResolutionInterface(_conflictResAddress);
    }

     
    function updateConflictResolution(address _newConflictResAddress) public onlyOwner {
        newConflictRes = _newConflictResAddress;
        updateTime = block.timestamp;

        emit LogUpdatingConflictResolution(_newConflictResAddress);
    }

     
    function activateConflictResolution() public onlyOwner {
        require(newConflictRes != 0);
        require(updateTime != 0);
        require(updateTime + MIN_TIMEOUT <= block.timestamp && block.timestamp <= updateTime + MAX_TIMEOUT);

        conflictRes = ConflictResolutionInterface(newConflictRes);
        newConflictRes = 0;
        updateTime = 0;

        emit LogUpdatedConflictResolution(newConflictRes);
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
        emit LogPause();
    }

     
    function unpause() public onlyOwner onlyPaused {
        paused = false;
        timePaused = 0;
        emit LogUnpause();
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
        PLAYER_INITIATED_END,  
        SERVER_INITIATED_END  
    }

     
    enum ReasonEnded {
        REGULAR_ENDED,  
        END_FORCED_BY_SERVER,  
        END_FORCED_BY_PLAYER  
    }

    struct Game {
         
        GameStatus status;

         
        uint128 stake;

         
         
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

    bytes32 public constant TYPE_HASH = keccak256(abi.encodePacked(
        "uint32 Round Id",
        "uint8 Game Type",
        "uint16 Number",
        "uint Value (Wei)",
        "int Current Balance (Wei)",
        "bytes32 Server Hash",
        "bytes32 Player Hash",
        "uint Game Id",
        "address Contract Address"
     ));

     
    uint public activeGames = 0;

     
     
    uint public gameIdCntr;

     
    address public serverAddress;

     
    address public houseAddress;

     
    uint public houseStake = 0;

     
    int public houseProfit = 0;

     
    uint128 public minStake;

     
    uint128 public maxStake;

     
    uint public profitTransferTimeSpan = 14 days;

     
    uint public lastProfitTransferTimestamp;

     
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

     
    event LogGameCreated(address indexed player, uint indexed gameId, uint128 stake, bytes32 indexed serverEndHash, bytes32 playerEndHash);

     
    event LogPlayerRequestedEnd(address indexed player, uint indexed gameId);

     
    event LogServerRequestedEnd(address indexed player, uint indexed gameId);

     
    event LogGameEnded(address indexed player, uint indexed gameId, uint32 roundId, int balance, ReasonEnded reason);

     
    event LogStakeLimitsModified(uint minStake, uint maxStake);

     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
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
    }

     
    function withdraw() public {
        uint toTransfer = pendingReturns[msg.sender];
        require(toTransfer > 0);

        pendingReturns[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
    }

     
    function transferProfitToHouse() public {
        require(lastProfitTransferTimestamp + profitTransferTimeSpan <= block.timestamp);

         
        lastProfitTransferTimestamp = block.timestamp;

        if (houseProfit <= 0) {
             
            return;
        }

         
        uint toTransfer = uint(houseProfit);
        assert(houseStake >= toTransfer);

        houseProfit = 0;
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

     
    function setStakeRequirements(uint128 _minStake, uint128 _maxStake) public onlyOwner {
        require(_minStake > 0 && _minStake <= _maxStake);
        minStake = _minStake;
        maxStake = _maxStake;
        emit LogStakeLimitsModified(minStake, maxStake);
    }

     
    function closeGame(
        Game storage _game,
        uint _gameId,
        uint32 _roundId,
        address _playerAddress,
        ReasonEnded _reason,
        int _balance
    )
        internal
    {
        _game.status = GameStatus.ENDED;

        assert(activeGames > 0);
        activeGames = activeGames - 1;

        payOut(_playerAddress, _game.stake, _balance);

        emit LogGameEnded(_playerAddress, _gameId, _roundId, _balance, _reason);
    }

     
    function payOut(address _playerAddress, uint128 _stake, int _balance) internal {
        assert(_balance <= conflictRes.maxBalance());
        assert((int(_stake) + _balance) >= 0);  

        uint valuePlayer = uint(int(_stake) + _balance);  

        if (_balance > 0 && int(houseStake) < _balance) {  
             
             
             
            valuePlayer = houseStake;
        }

        houseProfit = houseProfit - _balance;

        int newHouseStake = int(houseStake) - _balance;  
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

      
    function verify(
        bytes32 _hash,
        bytes _sig,
        address _address
    )
        internal
        pure
    {
        bytes32 r;
        bytes32 s;
        uint8 v;

        (r, s, v) = signatureSplit(_sig);
        address addressRecover = ecrecover(_hash, v, r, s);
        require(addressRecover == _address);
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
        pure
        returns(bytes32)
    {
        bytes32 dataHash = keccak256(abi.encodePacked(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _playerHash,
            _gameId,
            _contractAddress
        ));

        return keccak256(abi.encodePacked(
            TYPE_HASH,
            dataHash
        ));
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
     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
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

            emit LogPlayerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == 0) {
            closeGame(game, gameId, 0, playerAddress, ReasonEnded.REGULAR_ENDED, 0);
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

            emit LogServerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.PLAYER_INITIATED_END && game.roundId == 0) {
            closeGame(game, gameId, 0, _playerAddress, ReasonEnded.REGULAR_ENDED, 0);
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

        closeGame(game, gameId, game.roundId, _playerAddress, ReasonEnded.END_FORCED_BY_SERVER, newBalance);
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

        closeGame(game, gameId, game.roundId, playerAddress, ReasonEnded.END_FORCED_BY_PLAYER, newBalance);
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
        require(keccak256(abi.encodePacked(_playerSeed)) == _playerHash);
        require(-int(game.stake) <= _balance && _balance <= maxBalance);  
        require(conflictRes.isValidBet(_gameType, _num, _value));
        require(int(game.stake) + _balance - int(_value) >= 0);  

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

            emit LogPlayerRequestedEnd(msg.sender, gameId);
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
        require(keccak256(abi.encodePacked(_serverSeed)) == _serverHash);
        require(keccak256(abi.encodePacked(_playerSeed)) == _playerHash);
        require(-int(game.stake) <= _balance && _balance <= maxBalance);  
        require(conflictRes.isValidBet(_gameType, _num, _value));
        require(int(game.stake) + _balance - int(_value) >= 0);  

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

            emit LogServerRequestedEnd(_playerAddress, gameId);
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

        closeGame(_game, _gameId, _game.roundId, _playerAddress, ReasonEnded.REGULAR_ENDED, newBalance);
    }
}

contract GameChannel is GameChannelConflict {
     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _gameIdCntr
    )
        public
        GameChannelConflict(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _gameIdCntr)
    {
         
    }

     
    function createGame(
        bytes32 _playerEndHash,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        public
        payable
        onlyValidValue
        onlyValidHouseStake(activeGames + 1)
        onlyNotPaused
    {
        uint previousGameId = playerGameId[msg.sender];
        Game storage game = gameIdGame[previousGameId];

        require(game.status == GameStatus.ENDED);
        require(previousGameId == _previousGameId);
        require(block.timestamp < _createBefore);

        verifyCreateSig(msg.sender, _previousGameId, _createBefore, _serverEndHash, _serverSig);

        uint gameId = gameIdCntr++;
        playerGameId[msg.sender] = gameId;
        Game storage newGame = gameIdGame[gameId];

        newGame.stake = uint128(msg.value);  
        newGame.status = GameStatus.ACTIVE;

        activeGames = activeGames + 1;

         
        emit LogGameCreated(msg.sender, gameId, uint128(msg.value), _serverEndHash,  _playerEndHash);
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

     
    function verifyCreateSig(
        address _playerAddress,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        private view
    {
        address contractAddress = this;
        bytes32 hash = keccak256(abi.encodePacked(
            contractAddress, _playerAddress, _previousGameId, _createBefore, _serverEndHash
        ));

        verify(hash, _serverSig, serverAddress);
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
        require(game.status == GameStatus.ACTIVE);

        assert(_contractAddress == contractAddress);

        closeGame(game, gameId, _roundId, _playerAddress, ReasonEnded.REGULAR_ENDED, _balance);
    }
}