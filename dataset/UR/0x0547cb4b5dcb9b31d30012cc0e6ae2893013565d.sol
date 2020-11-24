 

pragma solidity ^0.4.18;


contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner); _;}

     
     
    function transferOwnership(address _newOwnerCandidate) external onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        emit OwnershipRequested(msg.sender, newOwnerCandidate);
    }

     
    function acceptOwnership() external {
        if (msg.sender == newOwnerCandidate) {
            owner = newOwnerCandidate;
            newOwnerCandidate = address(0);

            emit OwnershipTransferred(owner, newOwnerCandidate);
        }
    }
}


contract Serverable is Ownable {
    address public server;

    modifier onlyServer() { require(msg.sender == server); _;}

    function setServerAddress(address _newServerAddress) external onlyOwner {
        server = _newServerAddress;
    }
}


contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);
  
  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  
  event Transfer(address indexed from, address indexed to, uint value);
}

contract BalanceManager is Serverable {
     
    mapping(uint32 => uint64) public balances;
     
    mapping(uint32 => uint64) public blockedBalances;
     
    mapping(address => uint64) public walletBalances;
     
    mapping(address => uint32) public userIds;

     
    address public dispatcher;
     
    uint serviceReward;
     
    uint sentBonuses;
     
    ERC223 public gameToken;

    modifier onlyDispatcher() {require(msg.sender == dispatcher);
        _;}

    event Withdraw(address _user, uint64 _amount);
    event Deposit(address _user, uint64 _amount);

    constructor(address _gameTokenAddress) public {
        gameToken = ERC223(_gameTokenAddress);
    }

    function setDispatcherAddress(address _newDispatcherAddress) external onlyOwner {
        dispatcher = _newDispatcherAddress;
    }

     
    function tokenFallback(address _from, uint256 _amount, bytes _data) public {
        if (userIds[_from] > 0) {
            balances[userIds[_from]] += uint64(_amount);
        } else {
            walletBalances[_from] += uint64(_amount);
        }

        emit Deposit(_from, uint64(_amount));
    }

     
    function registerUserWallet(address _user, uint32 _id) external onlyServer {
        require(userIds[_user] == 0);
        require(_user != owner);

        userIds[_user] = _id;
        if (walletBalances[_user] > 0) {
            balances[_id] += walletBalances[_user];
            walletBalances[_user] = 0;
        }
    }

     
    function sendTo(address _user, uint64 _amount) external {
        require(walletBalances[msg.sender] >= _amount);
        walletBalances[msg.sender] -= _amount;
        if (userIds[_user] > 0) {
            balances[userIds[_user]] += _amount;
        } else {
            walletBalances[_user] += _amount;
        }
        emit Deposit(_user, _amount);
    }

     
    function withdraw(uint64 _amount) external {
        uint32 userId = userIds[msg.sender];
        if (userId > 0) {
            require(balances[userId] - blockedBalances[userId] >= _amount);
            if (gameToken.transfer(msg.sender, _amount)) {
                balances[userId] -= _amount;
                emit Withdraw(msg.sender, _amount);
            }
        } else {
            require(walletBalances[msg.sender] >= _amount);
            if (gameToken.transfer(msg.sender, _amount)) {
                walletBalances[msg.sender] -= _amount;
                emit Withdraw(msg.sender, _amount);
            }
        }
    }

     
    function systemWithdraw(address _user, uint64 _amount) external onlyServer {
        uint32 userId = userIds[_user];
        require(balances[userId] - blockedBalances[userId] >= _amount);

        if (gameToken.transfer(_user, _amount)) {
            balances[userId] -= _amount;
            emit Withdraw(_user, _amount);
        }
    }

     
    function addUserBalance(uint32 _userId, uint64 _amount) external onlyDispatcher {
        balances[_userId] += _amount;
    }

     
    function spendUserBalance(uint32 _userId, uint64 _amount) external onlyDispatcher {
        require(balances[_userId] >= _amount);
        balances[_userId] -= _amount;
        if (blockedBalances[_userId] > 0) {
            if (blockedBalances[_userId] <= _amount)
                blockedBalances[_userId] = 0;
            else
                blockedBalances[_userId] -= _amount;
        }
    }

     
    function addBonus(uint32[] _userIds, uint64[] _amounts) external onlyServer {
        require(_userIds.length == _amounts.length);

        uint64 sum = 0;
        for (uint32 i = 0; i < _amounts.length; i++)
            sum += _amounts[i];

        require(walletBalances[owner] >= sum);
        for (i = 0; i < _userIds.length; i++) {
            balances[_userIds[i]] += _amounts[i];
            blockedBalances[_userIds[i]] += _amounts[i];
        }

        sentBonuses += sum;
        walletBalances[owner] -= sum;
    }

     
    function addServiceReward(uint _amount) external onlyDispatcher {
        serviceReward += _amount;
    }

     
    function serviceFeeWithdraw() external onlyOwner {
        require(serviceReward > 0);
        if (gameToken.transfer(msg.sender, serviceReward))
            serviceReward = 0;
    }

    function viewSentBonuses() public view returns (uint) {
        require(msg.sender == owner || msg.sender == server);
        return sentBonuses;
    }

    function viewServiceReward() public view returns (uint) {
        require(msg.sender == owner || msg.sender == server);
        return serviceReward;
    }
}


contract BrokerManager is Ownable {

	struct InvestTerm {
		uint64 amount;
		uint16 userFee;
	}
	 
	address public server;
	 
	mapping (uint32 => mapping (uint32 => InvestTerm)) public investTerms;

	modifier onlyServer() {require(msg.sender == server); _;}

	function setServerAddress(address _newServerAddress) external onlyOwner {
		server = _newServerAddress;
	}

	 
	function invest(uint32 _playerId, uint32 _investorId, uint64 _amount, uint16 _userFee) external onlyServer {
		require(_amount > 0 && _userFee > 0);
		investTerms[_investorId][_playerId] = InvestTerm(_amount, _userFee);
	}

	 
	function deleteInvest(uint32 _playerId, uint32 _investorId) external onlyServer {
		delete investTerms[_investorId][_playerId];
	}
}


contract Dispatcher is BrokerManager {

    enum GameState {Initialized, Started, Finished, Cancelled}

    struct GameTeam {
        uint32 userId;
        uint32 sponsorId;
        uint64 prizeSum;
        uint16 userFee;
    }

    struct Game {
        GameState state;
        uint64 entryFee;
        uint32 serviceFee;
        uint32 registrationDueDate;

        bytes32 teamsHash;
        bytes32 statsHash;

        uint32 teamsNumber;
        uint64 awardSent;
    }

     
    BalanceManager public balanceManager;
     
    mapping(uint32 => mapping(uint48 => GameTeam)) public teams;
     
    mapping(uint32 => Game) public games;

    constructor(address _balanceManagerAddress) public {
        balanceManager = BalanceManager(_balanceManagerAddress);
    }

     
    function createGame(
        uint32 _gameId,
        uint64 _entryFee,
        uint32 _serviceFee,
        uint32 _registrationDueDate
    )
    external
    onlyServer
    {
        require(
            games[_gameId].entryFee == 0
            && _gameId > 0
            && _entryFee > 0
            && _registrationDueDate > 0
        );
        games[_gameId] = Game(GameState.Initialized, _entryFee, _serviceFee, _registrationDueDate, 0x0, 0x0, 0, 0);
    }

     
    function participateGame(
        uint32 _gameId,
        uint32 _teamId,
        uint32 _userId,
        uint32 _sponsorId
    )
    external
    onlyServer
    {
        Game storage game = games[_gameId];
        require(
            _gameId > 0
            && game.state == GameState.Initialized
            && _teamId > 0
            && _userId > 0
            && teams[_gameId][_teamId].userId == 0
            && game.registrationDueDate > uint32(now)
        );

        uint16 userFee = 0;
        if (_sponsorId > 0) {
            require(balanceManager.balances(_sponsorId) >= game.entryFee && investTerms[_sponsorId][_userId].amount > game.entryFee);
            balanceManager.spendUserBalance(_sponsorId, game.entryFee);
            investTerms[_sponsorId][_userId].amount -= game.entryFee;
            userFee = investTerms[_sponsorId][_userId].userFee;
        }
        else {
            require(balanceManager.balances(_userId) >= game.entryFee);
            balanceManager.spendUserBalance(_userId, game.entryFee);
        }

        teams[_gameId][_teamId] = GameTeam(_userId, _sponsorId, 0, userFee);
        game.teamsNumber++;
    }

     
    function startGame(uint32 _gameId, bytes32 _hash) external onlyServer {
        Game storage game = games[_gameId];
        require(
            game.state == GameState.Initialized
            && _gameId > 0
        && _hash != 0x0
        );

        game.teamsHash = _hash;
        game.state = GameState.Started;
    }

     
    function cancelGame(uint32 _gameId) external onlyServer {
        Game storage game = games[_gameId];
        require(
            _gameId > 0
            && game.state < GameState.Finished
        );
        game.state = GameState.Cancelled;
    }

     
    function finishGame(uint32 _gameId, bytes32 _hash) external onlyServer {
        Game storage game = games[_gameId];
        require(
            _gameId > 0
            && game.state < GameState.Finished
        && _hash != 0x0
        );
        game.statsHash = _hash;
        game.state = GameState.Finished;
    }

     
    function winners(uint32 _gameId, uint32[] _teamIds, uint64[] _teamPrizes) external onlyServer {
        Game storage game = games[_gameId];
        require(game.state == GameState.Finished);

        uint64 sumPrize = 0;
        for (uint32 i = 0; i < _teamPrizes.length; i++)
            sumPrize += _teamPrizes[i];

        require(uint(sumPrize + game.awardSent) <= uint(game.entryFee * game.teamsNumber));

        for (i = 0; i < _teamIds.length; i++) {
            uint32 teamId = _teamIds[i];
            GameTeam storage team = teams[_gameId][teamId];
            uint32 userId = team.userId;

            if (team.prizeSum == 0) {
                if (team.sponsorId > 0) {
                    uint64 userFee = team.userFee * _teamPrizes[i] / 100;
                    balanceManager.addUserBalance(team.sponsorId, userFee);
                    balanceManager.addUserBalance(userId, _teamPrizes[i] - userFee);
                    team.prizeSum = _teamPrizes[i];
                } else {
                    balanceManager.addUserBalance(userId, _teamPrizes[i]);
                    team.prizeSum = _teamPrizes[i];
                }
            }
        }
    }

     
    function refundCancelledGame(uint32 _gameId, uint32[] _teamIds) external onlyServer {
        Game storage game = games[_gameId];
        require(game.state == GameState.Cancelled);

        for (uint32 i = 0; i < _teamIds.length; i++) {
            uint32 teamId = _teamIds[i];
            GameTeam storage team = teams[_gameId][teamId];

            require(teams[_gameId][teamId].prizeSum == 0);

            if (team.prizeSum == 0) {
                if (team.sponsorId > 0) {
                    balanceManager.addUserBalance(team.sponsorId, game.entryFee);
                } else {
                    balanceManager.addUserBalance(team.userId, game.entryFee);
                }
                team.prizeSum = game.entryFee;
            }
        }
    }
}