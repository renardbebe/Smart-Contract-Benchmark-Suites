 

pragma solidity ^0.4.0;

 
contract withOwners {
  uint public ownersCount = 0;
  uint public managersCount = 0;

   
  mapping (address => bool) public owners;
  mapping (address => bool) public managers;

  modifier onlyOwners {
    if (owners[msg.sender] != true) {
      throw;
    }
    _;
  }

  modifier onlyManagers {
    if (owners[msg.sender] != true && managers[msg.sender] != true) {
      throw;
    }
    _;
  }

  function addOwner(address _candidate) public onlyOwners {
    if (owners[_candidate] == true) {
      throw;  
    }

    owners[_candidate] = true;
    ++ownersCount;
  }

  function removeOwner(address _candidate) public onlyOwners {
     
    if (ownersCount <= 1 || owners[_candidate] == false) {
      throw;
    }

    owners[_candidate] = false;
    --ownersCount;
  }

  function addManager(address _candidate) public onlyOwners {
    if (managers[_candidate] == true) {
      throw;  
    }

    managers[_candidate] = true;
    ++managersCount;
  }

  function removeManager(address _candidate) public onlyOwners {
    if (managers[_candidate] == false) {
      throw;
    }

    managers[_candidate] = false;
    --managersCount;
  }
}


 
contract withAccounts is withOwners {
  uint defaultTimeoutPeriod = 2 days;  

  struct AccountTx {
    uint timeCreated;
    address user;
    uint amountHeld;
    uint amountSpent;
    uint8 state;  
  }

  uint public txCount = 0;
  mapping (uint => AccountTx) public accountTxs;
   

   
  uint public availableBalance = 0;
  uint public onholdBalance = 0;
  uint public spentBalance = 0;  

  mapping (address => uint) public availableBalances;
  mapping (address => uint) public onholdBalances;
  mapping (address => bool) public doNotAutoRefund;

  modifier handleDeposit {
    deposit(msg.sender, msg.value);
    _;
  }

 

   
  function depositFor(address _address) public payable {
    deposit(_address, msg.value);
  }

   
  function withdraw(uint _amount) public {
    if (_amount == 0) {
      _amount = availableBalances[msg.sender];
    }
    if (_amount > availableBalances[msg.sender]) {
      throw;
    }

    incrUserAvailBal(msg.sender, _amount, false);
    if (!msg.sender.call.value(_amount)()) {
      throw;
    }
  }

   
  function checkTimeout(uint _id) public {
    if (
      accountTxs[_id].state != 1 ||
      (now - accountTxs[_id].timeCreated) < defaultTimeoutPeriod
    ) {
      throw;
    }

    settle(_id, 0);  

     
     
  }

   
  function setDoNotAutoRefundTo(bool _option) public {
    doNotAutoRefund[msg.sender] = _option;
  }

   
  function updateDefaultTimeoutPeriod(uint _defaultTimeoutPeriod) public onlyOwners {
    if (_defaultTimeoutPeriod < 1 hours) {
      throw;
    }

    defaultTimeoutPeriod = _defaultTimeoutPeriod;
  }

   
  function collectRev() public onlyOwners {
    uint amount = spentBalance;
    spentBalance = 0;

    if (!msg.sender.call.value(amount)()) {
      throw;
    }
  }

   
  function returnFund(address _user, uint _amount) public onlyManagers {
    if (doNotAutoRefund[_user] || _amount > availableBalances[_user]) {
      throw;
    }
    if (_amount == 0) {
      _amount = availableBalances[_user];
    }

    incrUserAvailBal(_user, _amount, false);
    if (!_user.call.value(_amount)()) {
      throw;
    }
  }

 

   
  function deposit(address _user, uint _amount) internal {
    if (_amount > 0) {
      incrUserAvailBal(_user, _amount, true);
    }
  }

   
  function createTx(uint _id, address _user, uint _amount) internal {
    if (_amount > availableBalances[_user]) {
      throw;
    }

    accountTxs[_id] = AccountTx({
      timeCreated: now,
      user: _user,
      amountHeld: _amount,
      amountSpent: 0,
      state: 1  
    });

    incrUserAvailBal(_user, _amount, false);
    incrUserOnholdBal(_user, _amount, true);
  }

  function settle(uint _id, uint _amountSpent) internal {
    if (accountTxs[_id].state != 1 || _amountSpent > accountTxs[_id].amountHeld) {
      throw;
    }

     
     

    accountTxs[_id].amountSpent = _amountSpent;
    accountTxs[_id].state = 2;  

    spentBalance += _amountSpent;
    uint changeAmount = accountTxs[_id].amountHeld - _amountSpent;

    incrUserOnholdBal(accountTxs[_id].user, accountTxs[_id].amountHeld, false);
    incrUserAvailBal(accountTxs[_id].user, changeAmount, true);
  }

  function incrUserAvailBal(address _user, uint _by, bool _increase) internal {
    if (_increase) {
      availableBalances[_user] += _by;
      availableBalance += _by;
    } else {
      availableBalances[_user] -= _by;
      availableBalance -= _by;
    }
  }

  function incrUserOnholdBal(address _user, uint _by, bool _increase) internal {
    if (_increase) {
      onholdBalances[_user] += _by;
      onholdBalance += _by;
    } else {
      onholdBalances[_user] -= _by;
      onholdBalance -= _by;
    }
  }
}



contract Notifier is withOwners, withAccounts {
  string public xIPFSPublicKey;
  uint public minEthPerNotification = 0.02 ether;

  struct Task {
    address sender;
    uint8 state;  
                  
                  
                  
                  

    bool isxIPFS;   
  }

  struct Notification {
    uint8 transport;  
    string destination;
    string message;
  }

  mapping(uint => Task) public tasks;
  mapping(uint => Notification) public notifications;
  mapping(uint => string) public xnotifications;  
  uint public tasksCount = 0;

   
  event TaskUpdated(uint id, uint8 state);

  function Notifier(string _xIPFSPublicKey) public {
    xIPFSPublicKey = _xIPFSPublicKey;
    ownersCount++;
    owners[msg.sender] = true;
  }

 

   
  function notify(uint8 _transport, string _destination, string _message) public payable handleDeposit {
    if (_transport != 1 && _transport != 2) {
      throw;
    }

    uint id = tasksCount;
    uint8 state = 10;  

    createTx(id, msg.sender, minEthPerNotification);
    notifications[id] = Notification({
      transport: _transport,
      destination: _destination,
      message: _message
    });
    tasks[id] = Task({
      sender: msg.sender,
      state: state,
      isxIPFS: false  
    });

    TaskUpdated(id, state);
    ++tasksCount;
  }

 

  function xnotify(string _hash) public payable handleDeposit {
    uint id = tasksCount;
    uint8 state = 10;  

    createTx(id, msg.sender, minEthPerNotification);
    xnotifications[id] = _hash;
    tasks[id] = Task({
      sender: msg.sender,
      state: state,
      isxIPFS: true
    });

    TaskUpdated(id, state);
    ++tasksCount;
  }

 

  function updateMinEthPerNotification(uint _newMin) public onlyManagers {
    minEthPerNotification = _newMin;
  }

   
  function taskProcessedNoCosting(uint _id) public onlyManagers {
    updateState(_id, 20, 0);
  }

   
  function taskProcessedWithCosting(uint _id, uint _cost) public onlyManagers {
    updateState(_id, 50, _cost);
  }

   
  function taskRejected(uint _id, uint _cost) public onlyManagers {
    updateState(_id, 60, _cost);
  }

   
  function updateXIPFSPublicKey(string _publicKey) public onlyOwners {
    xIPFSPublicKey = _publicKey;
  }

  function updateState(uint _id, uint8 _state, uint _cost) internal {
    if (tasks[_id].state == 0 || tasks[_id].state >= 50) {
      throw;
    }

    tasks[_id].state = _state;

     
    if (_state >= 50) {
      settle(_id, _cost);
    }
    TaskUpdated(_id, _state);
  }

   
  function () payable handleDeposit {
  }
}