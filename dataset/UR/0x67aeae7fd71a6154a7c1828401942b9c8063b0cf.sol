 
contract GameChannel is GameChannelConflict {
     
    constructor(
        address _serverAddress,
        uint128 _minStake,
        uint128 _maxStake,
        address _conflictResAddress,
        address payable _houseAddress,
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
        bytes memory _serverSig
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
        address payable _userAddress,
        bytes memory _userSig
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
        bytes memory _serverSig
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
        bytes memory _serverSig
    )
        private view
    {
        address contractAddress = address(this);
        bytes32 hash = keccak256(abi.encodePacked(
            contractAddress, _userAddress, _previousGameId, _createBefore, _serverEndHash
        ));

        verify(hash, _serverSig, serverAddress);
    }

     
    function regularEndGame(
        address payable _userAddress,
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
