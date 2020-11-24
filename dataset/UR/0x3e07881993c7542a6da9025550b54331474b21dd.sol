 

pragma solidity ^0.4.24;

interface ConflictResolutionInterface {
    function minHouseStake(uint activeGames) external pure returns(uint);

    function maxBalance() external pure returns(int);

    function conflictEndFine() external pure returns(int);

    function isValidBet(uint8 _gameType, uint _betNum, uint _betValue) external pure returns(bool);

    function endGameConflict(
        uint8 _gameType,
        uint _betNum,
        uint _betValue,
        int _balance,
        uint _stake,
        bytes32 _serverSeed,
        bytes32 _userSeed
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

    function userForceGameEnd(
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
        owner = pendingOwner;
        pendingOwner = address(0);
        emit LogOwnerShipTransferred(owner, pendingOwner);
    }
}

contract Activatable is Ownable {
    bool public activated = false;

     
    event LogActive();

     
    modifier onlyActivated() {
        require(activated);
        _;
    }

     
    modifier onlyNotActivated() {
        require(!activated);
        _;
    }

     
    function activate() public onlyOwner onlyNotActivated {
        activated = true;
        emit LogActive();
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

contract Pausable is Activatable {
    using SafeMath for uint;

     
    bool public paused = true;

     
    uint public timePaused = block.timestamp;

     
    modifier onlyNotPaused() {
        require(!paused, "paused");
        _;
    }

     
    modifier onlyPaused() {
        require(paused);
        _;
    }

     
    modifier onlyPausedSince(uint timeSpan) {
        require(paused && (timePaused.add(timeSpan) <= block.timestamp));
        _;
    }

     
    event LogPause();

     
    event LogUnpause();

     
    function pause() public onlyOwner onlyNotPaused {
        paused = true;
        timePaused = block.timestamp;
        emit LogPause();
    }

     
    function unpause() public onlyOwner onlyPaused onlyActivated {
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
    using SafeCast for int;
    using SafeCast for uint;
    using SafeMath for int;
    using SafeMath for uint;


     
    enum GameStatus {
        ENDED,  
        ACTIVE,  
        USER_INITIATED_END,  
        SERVER_INITIATED_END  
    }

     
    enum ReasonEnded {
        REGULAR_ENDED,  
        SERVER_FORCED_END,  
        USER_FORCED_END,  
        CONFLICT_ENDED  
    }

    struct Game {
         
        GameStatus status;

         
        uint128 stake;

         
         
        uint8 gameType;
        uint32 roundId;
        uint betNum;
        uint betValue;
        int balance;
        bytes32 userSeed;
        bytes32 serverSeed;
        uint endInitiatedTime;
    }

     
    uint public constant MIN_TRANSFER_TIMESPAN = 1 days;

     
    uint public constant MAX_TRANSFER_TIMSPAN = 6 * 30 days;

    bytes32 public constant EIP712DOMAIN_TYPEHASH = keccak256(
        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
    );

    bytes32 public constant BET_TYPEHASH = keccak256(
        "Bet(uint32 roundId,uint8 gameType,uint256 number,uint256 value,int256 balance,bytes32 serverHash,bytes32 userHash,uint256 gameId)"
    );

    bytes32 public DOMAIN_SEPERATOR;

     
    uint public activeGames = 0;

     
     
    uint public gameIdCntr = 1;

     
    address public serverAddress;

     
    address public houseAddress;

     
    uint public houseStake = 0;

     
    int public houseProfit = 0;

     
    uint128 public minStake;

     
    uint128 public maxStake;

     
    uint public profitTransferTimeSpan = 14 days;

     
    uint public lastProfitTransferTimestamp;

     
    mapping (uint => Game) public gameIdGame;

     
    mapping (address => uint) public userGameId;

     
    mapping (address => uint) public pendingReturns;

     
    modifier onlyValidHouseStake(uint _activeGames) {
        uint minHouseStake = conflictRes.minHouseStake(_activeGames);
        require(houseStake >= minHouseStake, "inv houseStake");
        _;
    }

     
    modifier onlyValidValue() {
        require(minStake <= msg.value && msg.value <= maxStake, "inv stake");
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

     
    event LogGameCreated(address indexed user, uint indexed gameId, uint128 stake, bytes32 indexed serverEndHash, bytes32 userEndHash);

     
    event LogUserRequestedEnd(address indexed user, uint indexed gameId);

     
    event LogServerRequestedEnd(address indexed user, uint indexed gameId);

     
    event LogGameEnded(address indexed user, uint indexed gameId, uint32 roundId, int balance, ReasonEnded reason);

     
    event LogStakeLimitsModified(uint minStake, uint maxStake);

     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _chainId
    )
        public
        ConflictResolutionManager(_conflictResAddress)
    {
        require(_minStake > 0 && _minStake <= _maxStake);

        serverAddress = _serverAddress;
        houseAddress = _houseAddress;
        lastProfitTransferTimestamp = block.timestamp;
        minStake = _minStake;
        maxStake = _maxStake;

        DOMAIN_SEPERATOR =  keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256("Dicether"),
            keccak256("2"),
            _chainId,
            address(this)
        ));
    }

     
    function setGameIdCntr(uint _gameIdCntr) public onlyOwner onlyNotActivated {
        require(gameIdCntr > 0);
        gameIdCntr = _gameIdCntr;
    }

     
    function withdraw() public {
        uint toTransfer = pendingReturns[msg.sender];
        require(toTransfer > 0);

        pendingReturns[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
    }

     
    function transferProfitToHouse() public {
        require(lastProfitTransferTimestamp.add(profitTransferTimeSpan) <= block.timestamp);

         
        lastProfitTransferTimestamp = block.timestamp;

        if (houseProfit <= 0) {
             
            return;
        }

        uint toTransfer = houseProfit.castToUint();

        houseProfit = 0;
        houseStake = houseStake.sub(toTransfer);

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
        houseStake = houseStake.add(msg.value);
    }

     
    function withdrawHouseStake(uint value) public onlyOwner {
        uint minHouseStake = conflictRes.minHouseStake(activeGames);

        require(value <= houseStake && houseStake.sub(value) >= minHouseStake);
        require(houseProfit <= 0 || houseProfit.castToUint() <= houseStake.sub(value));

        houseStake = houseStake.sub(value);
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
        address _userAddress,
        ReasonEnded _reason,
        int _balance
    )
        internal
    {
        _game.status = GameStatus.ENDED;

        activeGames = activeGames.sub(1);

        payOut(_userAddress, _game.stake, _balance);

        emit LogGameEnded(_userAddress, _gameId, _roundId, _balance, _reason);
    }

     
    function payOut(address _userAddress, uint128 _stake, int _balance) internal {
        int stakeInt = _stake;
        int houseStakeInt = houseStake.castToInt();

        assert(_balance <= conflictRes.maxBalance());
        assert((stakeInt.add(_balance)) >= 0);

        if (_balance > 0 && houseStakeInt < _balance) {
             
             
             
            _balance = houseStakeInt;
        }

        houseProfit = houseProfit.sub(_balance);

        int newHouseStake = houseStakeInt.sub(_balance);
        houseStake = newHouseStake.castToUint();

        uint valueUser = stakeInt.add(_balance).castToUint();
        pendingReturns[_userAddress] += valueUser;
        if (pendingReturns[_userAddress] > 0) {
            safeSend(_userAddress);
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
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _sig,
        address _address
    )
        internal
        view
    {
         
        address contractAddress = this;
        require(_contractAddress == contractAddress, "inv contractAddress");

        bytes32 roundHash = calcHash(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _userHash,
                _gameId
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
        (bytes32 r, bytes32 s, uint8 v) = signatureSplit(_sig);
        address addressRecover = ecrecover(_hash, v, r, s);
        require(addressRecover == _address, "inv sig");
    }

     
    function calcHash(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId
    )
        private
        view
        returns(bytes32)
    {
        bytes32 betHash = keccak256(abi.encode(
            BET_TYPEHASH,
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _serverHash,
            _userHash,
            _gameId
        ));

        return keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPERATOR,
            betHash
        ));
    }

     
    function signatureSplit(bytes _signature)
        private
        pure
        returns (bytes32 r, bytes32 s, uint8 v)
    {
        require(_signature.length == 65, "inv sig");

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
    using SafeCast for int;
    using SafeCast for uint;
    using SafeMath for int;
    using SafeMath for uint;

     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _chainId
    )
        public
        GameChannelBase(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _chainId)
    {
         
    }

     
    function serverEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _userSig,
        address _userAddress,
        bytes32 _serverSeed,
        bytes32 _userSeed
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
                _userHash,
                _gameId,
                _contractAddress,
                _userSig,
                _userAddress
        );

        serverEndGameConflictImpl(
                _roundId,
                _gameType,
                _num,
                _value,
                _balance,
                _serverHash,
                _userHash,
                _serverSeed,
                _userSeed,
                _gameId,
                _userAddress
        );
    }

     
    function userEndGameConflict(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig,
        bytes32 _userSeed
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
            _userHash,
            _gameId,
            _contractAddress,
            _serverSig,
            serverAddress
        );

        userEndGameConflictImpl(
            _roundId,
            _gameType,
            _num,
            _value,
            _balance,
            _userHash,
            _userSeed,
            _gameId,
            msg.sender
        );
    }

     
    function userCancelActiveGame(uint _gameId) public {
        address userAddress = msg.sender;
        uint gameId = userGameId[userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.USER_INITIATED_END;

            emit LogUserRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == 0) {
            cancelActiveGame(game, gameId, userAddress);
        } else {
            revert();
        }
    }

     
    function serverCancelActiveGame(address _userAddress, uint _gameId) public onlyServer {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");

        if (game.status == GameStatus.ACTIVE) {
            game.endInitiatedTime = block.timestamp;
            game.status = GameStatus.SERVER_INITIATED_END;

            emit LogServerRequestedEnd(msg.sender, gameId);
        } else if (game.status == GameStatus.USER_INITIATED_END && game.roundId == 0) {
            cancelActiveGame(game, gameId, _userAddress);
        } else {
            revert();
        }
    }

     
    function serverForceGameEnd(address _userAddress, uint _gameId) public onlyServer {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");
        require(game.status == GameStatus.SERVER_INITIATED_END, "inv status");

         
         
        int newBalance = conflictRes.serverForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, game.roundId, _userAddress, ReasonEnded.SERVER_FORCED_END, newBalance);
    }

     
    function userForceGameEnd(uint _gameId) public {
        address userAddress = msg.sender;
        uint gameId = userGameId[userAddress];
        Game storage game = gameIdGame[gameId];

        require(gameId == _gameId, "inv gameId");
        require(game.status == GameStatus.USER_INITIATED_END, "inv status");

        int newBalance = conflictRes.userForceGameEnd(
            game.gameType,
            game.betNum,
            game.betValue,
            game.balance,
            game.stake,
            game.endInitiatedTime
        );

        closeGame(game, gameId, game.roundId, userAddress, ReasonEnded.USER_FORCED_END, newBalance);
    }

     
    function userEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _userHash,
        bytes32 _userSeed,
        uint _gameId,
        address _userAddress
    )
        private
    {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();
        int gameStake = game.stake;

        require(gameId == _gameId, "inv gameId");
        require(_roundId > 0, "inv roundId");
        require(keccak256(abi.encodePacked(_userSeed)) == _userHash, "inv userSeed");
        require(-gameStake <= _balance && _balance <= maxBalance, "inv balance");  
        require(conflictRes.isValidBet(_gameType, _num, _value), "inv bet");
        require(gameStake.add(_balance).sub(_value.castToInt()) >= 0, "value too high");  

        if (game.status == GameStatus.SERVER_INITIATED_END && game.roundId == _roundId) {
            game.userSeed = _userSeed;
            endGameConflict(game, gameId, _userAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.SERVER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.USER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.userSeed = _userSeed;
            game.serverSeed = bytes32(0);

            emit LogUserRequestedEnd(msg.sender, gameId);
        } else {
            revert("inv state");
        }
    }

     
    function serverEndGameConflictImpl(
        uint32 _roundId,
        uint8 _gameType,
        uint _num,
        uint _value,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        bytes32 _serverSeed,
        bytes32 _userSeed,
        uint _gameId,
        address _userAddress
    )
        private
    {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();
        int gameStake = game.stake;

        require(gameId == _gameId, "inv gameId");
        require(_roundId > 0, "inv roundId");
        require(keccak256(abi.encodePacked(_serverSeed)) == _serverHash, "inv serverSeed");
        require(keccak256(abi.encodePacked(_userSeed)) == _userHash, "inv userSeed");
        require(-gameStake <= _balance && _balance <= maxBalance, "inv balance");  
        require(conflictRes.isValidBet(_gameType, _num, _value), "inv bet");
        require(gameStake.add(_balance).sub(_value.castToInt()) >= 0, "too high value");  

        if (game.status == GameStatus.USER_INITIATED_END && game.roundId == _roundId) {
            game.serverSeed = _serverSeed;
            endGameConflict(game, gameId, _userAddress);
        } else if (game.status == GameStatus.ACTIVE
                || (game.status == GameStatus.USER_INITIATED_END && game.roundId < _roundId)) {
            game.status = GameStatus.SERVER_INITIATED_END;
            game.endInitiatedTime = block.timestamp;
            game.roundId = _roundId;
            game.gameType = _gameType;
            game.betNum = _num;
            game.betValue = _value;
            game.balance = _balance;
            game.serverSeed = _serverSeed;
            game.userSeed = _userSeed;

            emit LogServerRequestedEnd(_userAddress, gameId);
        } else {
            revert("inv state");
        }
    }

     
    function cancelActiveGame(Game storage _game, uint _gameId, address _userAddress) private {
         
         
         
         
        int newBalance = -conflictRes.conflictEndFine();

         
        int stake = _game.stake;
        if (newBalance < -stake) {
            newBalance = -stake;
        }
        closeGame(_game, _gameId, 0, _userAddress, ReasonEnded.CONFLICT_ENDED, newBalance);
    }

     
    function endGameConflict(Game storage _game, uint _gameId, address _userAddress) private {
        int newBalance = conflictRes.endGameConflict(
            _game.gameType,
            _game.betNum,
            _game.betValue,
            _game.balance,
            _game.stake,
            _game.serverSeed,
            _game.userSeed
        );

        closeGame(_game, _gameId, _game.roundId, _userAddress, ReasonEnded.CONFLICT_ENDED, newBalance);
    }
}

contract GameChannel is GameChannelConflict {
     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address _houseAddress,
        uint _chainId
    )
        public
        GameChannelConflict(_serverAddress, _minStake, _maxStake, _conflictResAddress, _houseAddress, _chainId)
    {
         
    }

     
    function createGame(
        bytes32 _userEndHash,
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
        uint previousGameId = userGameId[msg.sender];
        Game storage game = gameIdGame[previousGameId];

        require(game.status == GameStatus.ENDED, "prev game not ended");
        require(previousGameId == _previousGameId, "inv gamePrevGameId");
        require(block.timestamp < _createBefore, "expired");

        verifyCreateSig(msg.sender, _previousGameId, _createBefore, _serverEndHash, _serverSig);

        uint gameId = gameIdCntr++;
        userGameId[msg.sender] = gameId;
        Game storage newGame = gameIdGame[gameId];

        newGame.stake = uint128(msg.value);  
        newGame.status = GameStatus.ACTIVE;

        activeGames = activeGames.add(1);

         
        emit LogGameCreated(msg.sender, gameId, uint128(msg.value), _serverEndHash,  _userEndHash);
    }


     
    function serverEndGame(
        uint32 _roundId,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        address _userAddress,
        bytes _userSig
    )
        public
        onlyServer
    {
        verifySig(
                _roundId,
                0,
                0,
                0,
                _balance,
                _serverHash,
                _userHash,
                _gameId,
                _contractAddress,
                _userSig,
                _userAddress
        );

        regularEndGame(_userAddress, _roundId, _balance, _gameId, _contractAddress);
    }

     
    function userEndGame(
        uint32 _roundId,
        int _balance,
        bytes32 _serverHash,
        bytes32 _userHash,
        uint _gameId,
        address _contractAddress,
        bytes _serverSig
    )
        public
    {
        verifySig(
                _roundId,
                0,
                0,
                0,
                _balance,
                _serverHash,
                _userHash,
                _gameId,
                _contractAddress,
                _serverSig,
                serverAddress
        );

        regularEndGame(msg.sender, _roundId, _balance, _gameId, _contractAddress);
    }

     
    function verifyCreateSig(
        address _userAddress,
        uint _previousGameId,
        uint _createBefore,
        bytes32 _serverEndHash,
        bytes _serverSig
    )
        private view
    {
        address contractAddress = this;
        bytes32 hash = keccak256(abi.encodePacked(
            contractAddress, _userAddress, _previousGameId, _createBefore, _serverEndHash
        ));

        verify(hash, _serverSig, serverAddress);
    }

     
    function regularEndGame(
        address _userAddress,
        uint32 _roundId,
        int _balance,
        uint _gameId,
        address _contractAddress
    )
        private
    {
        uint gameId = userGameId[_userAddress];
        Game storage game = gameIdGame[gameId];
        int maxBalance = conflictRes.maxBalance();
        int gameStake = game.stake;

        require(_gameId == gameId, "inv gameId");
        require(_roundId > 0, "inv roundId");
         
        require(-gameStake <= _balance && _balance <= maxBalance, "inv balance");
        require(game.status == GameStatus.ACTIVE, "inv status");

        assert(_contractAddress == address(this));

        closeGame(game, gameId, _roundId, _userAddress, ReasonEnded.REGULAR_ENDED, _balance);
    }
}

library SafeCast {
     
    function castToInt(uint a) internal pure returns(int) {
        assert(a < (1 << 255));
        return int(a);
    }

     
    function castToUint(int a) internal pure returns(uint) {
        assert(a >= 0);
        return uint(a);
    }
}

library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function mul(int256 a, int256 b) internal pure returns (int256) {
         
         
         
        if (a == 0) {
            return 0;
        }
        int256 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        return a / b;
    }

     
    function div(int256 a, int256 b) internal pure returns (int256) {
         
         
        int256 INT256_MIN = int256((uint256(1) << 255));
        assert(a != INT256_MIN || b != - 1);
        return a / b;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

     
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        assert((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

     
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        assert((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }
}