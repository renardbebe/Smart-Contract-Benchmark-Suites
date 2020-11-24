 

pragma solidity ^0.4.18;

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