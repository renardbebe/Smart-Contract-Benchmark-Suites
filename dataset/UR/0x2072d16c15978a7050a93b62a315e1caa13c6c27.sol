 

pragma solidity ^0.4.23;

 
 
interface IRegistry {
    function owner() external view returns (address _addr);
    function addressOf(bytes32 _name) external view returns (address _addr);
}

contract UsingRegistry {
    IRegistry private registry;

    modifier fromOwner(){
        require(msg.sender == getOwner());
        _;
    }

    constructor(address _registry)
        public
    {
        require(_registry != 0);
        registry = IRegistry(_registry);
    }

    function addressOf(bytes32 _name)
        internal
        view
        returns(address _addr)
    {
        return registry.addressOf(_name);
    }

    function getOwner()
        public
        view
        returns (address _addr)
    {
        return registry.owner();
    }

    function getRegistry()
        public
        view
        returns (IRegistry _addr)
    {
        return registry;
    }
}

 
contract UsingAdmin is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromAdmin(){
        require(msg.sender == getAdmin());
        _;
    }
    
    function getAdmin()
        public
        constant
        returns (address _addr)
    {
        return addressOf("ADMIN");
    }
}


 
 
interface IMonarchyController {
    function refreshGames() external returns (uint _numGamesEnded, uint _feesSent);
    function startDefinedGame(uint _index) external payable returns (address _game);
    function getFirstStartableIndex() external view returns (uint _index);
    function getNumEndableGames() external view returns (uint _count);
    function getAvailableFees() external view returns (uint _feesAvailable);
    function getInitialPrize(uint _index) external view returns (uint);
    function getIsStartable(uint _index) external view returns (bool);
}

contract UsingMonarchyController is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromMonarchyController(){
        require(msg.sender == address(getMonarchyController()));
        _;
    }

    function getMonarchyController()
        public
        view
        returns (IMonarchyController)
    {
        return IMonarchyController(addressOf("MONARCHY_CONTROLLER"));
    }
}


 
 
interface ITreasury {
    function issueDividend() external returns (uint _profits);
    function profitsSendable() external view returns (uint _profits);
}

contract UsingTreasury is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromTreasury(){
        require(msg.sender == address(getTreasury()));
        _;
    }
    
    function getTreasury()
        public
        view
        returns (ITreasury)
    {
        return ITreasury(addressOf("TREASURY"));
    }
}

 
contract HasDailyLimit {
     
    struct DailyLimitVars {
        uint112 dailyLimit;  
        uint112 usedToday;   
        uint32 lastDay;      
    }
    DailyLimitVars private vars;
    uint constant MAX_ALLOWED = 2**112 - 1;

    constructor(uint _limit) public {
        _setDailyLimit(_limit);
    }

     
    function _setDailyLimit(uint _limit) internal {
        require(_limit <= MAX_ALLOWED);
        vars.dailyLimit = uint112(_limit);
    }

     
     
    function _useFromDailyLimit(uint _amount) internal {
        uint _remaining = updateAndGetRemaining();
        require(_amount <= _remaining);
        vars.usedToday += uint112(_amount);
    }

     
     
    function updateAndGetRemaining() private returns (uint _amtRemaining) {
        if (today() > vars.lastDay) {
            vars.usedToday = 0;
            vars.lastDay = today();
        }
        uint112 _usedToday = vars.usedToday;
        uint112 _dailyLimit = vars.dailyLimit;
         
        return uint(_usedToday >= _dailyLimit ? 0 : _dailyLimit - _usedToday);
    }

     
    function today() private view returns (uint32) {
        return uint32(block.timestamp / 1 days);
    }


     
     
     

    function getDailyLimit() public view returns (uint) {
        return uint(vars.dailyLimit);
    }
    function getDailyLimitUsed() public view returns (uint) {
        return uint(today() > vars.lastDay ? 0 : vars.usedToday);
    }
    function getDailyLimitRemaining() public view returns (uint) {
        uint _used = getDailyLimitUsed();
        return uint(_used >= vars.dailyLimit ? 0 : vars.dailyLimit - _used);
    }
}


 
contract AddressSet {
    
    struct Entry {   
        bool exists;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

     
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


     
     
     

    function add(address _address)
        fromOwner
        public
        returns (bool _didCreate)
    {
         
        if (_address == address(0)) return;
        Entry storage entry = entries[_address];
         
        if (entry.exists) return;
        else entry.exists = true;

         
         
         
         
        Entry storage HEAD = entries[0x0];
        entry.next = HEAD.next;
        entries[HEAD.next].prev = _address;
        HEAD.next = _address;
        return true;
    }

    function remove(address _address)
        fromOwner
        public
        returns (bool _didExist)
    {
         
        if (_address == address(0)) return;
        Entry storage entry = entries[_address];
         
        if (!entry.exists) return;

         
         
         
         
        entries[entry.prev].next = entry.next;
        entries[entry.next].prev = entry.prev;
        delete entries[_address];
        return true;
    }


     
     
     

    function size()
        public
        view
        returns (uint _size)
    {
         
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function has(address _address)
        public
        view
        returns (bool _exists)
    {
        return entries[_address].exists;
    }

    function addresses()
        public
        view
        returns (address[] _addresses)
    {
         
        uint _size = size();
        _addresses = new address[](_size);
         
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return _addresses;
    }
}

 
contract Ledger {
    uint public total;       

    struct Entry {           
        uint balance;
        address next;
        address prev;
    }
    mapping (address => Entry) public entries;

    address public owner;
    modifier fromOwner() { require(msg.sender==owner); _; }

     
    constructor(address _owner)
        public
    {
        owner = _owner;
    }


     
     
     

    function add(address _address, uint _amt)
        fromOwner
        public
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

         
        if (entry.balance == 0) {
            entry.next = entries[0x0].next;
            entries[entries[0x0].next].prev = _address;
            entries[0x0].next = _address;
        }
         
        total += _amt;
        entry.balance += _amt;
    }

    function subtract(address _address, uint _amt)
        fromOwner
        public
        returns (uint _amtRemoved)
    {
        if (_address == address(0) || _amt == 0) return;
        Entry storage entry = entries[_address];

        uint _maxAmt = entry.balance;
        if (_maxAmt == 0) return;
        
        if (_amt >= _maxAmt) {
             
            total -= _maxAmt;
            entries[entry.prev].next = entry.next;
            entries[entry.next].prev = entry.prev;
            delete entries[_address];
            return _maxAmt;
        } else {
             
            total -= _amt;
            entry.balance -= _amt;
            return _amt;
        }
    }


     
     
     

    function size()
        public
        view
        returns (uint _size)
    {
         
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _curEntry = entries[_curEntry.next];
            _size++;
        }
        return _size;
    }

    function balanceOf(address _address)
        public
        view
        returns (uint _balance)
    {
        return entries[_address].balance;
    }

    function balances()
        public
        view
        returns (address[] _addresses, uint[] _balances)
    {
         
        uint _size = size();
        _addresses = new address[](_size);
        _balances = new uint[](_size);
        uint _i = 0;
        Entry memory _curEntry = entries[0x0];
        while (_curEntry.next > 0) {
            _addresses[_i] = _curEntry.next;
            _balances[_i] = entries[_curEntry.next].balance;
            _curEntry = entries[_curEntry.next];
            _i++;
        }
        return (_addresses, _balances);
    }
}

 
contract Bankrollable is
    UsingTreasury
{   
     
    uint public profitsSent;
     
    Ledger public ledger;
     
    uint public bankroll;
     
    AddressSet public whitelist;

    modifier fromWhitelistOwner(){
        require(msg.sender == getWhitelistOwner());
        _;
    }

    event BankrollAdded(uint time, address indexed bankroller, uint amount, uint bankroll);
    event BankrollRemoved(uint time, address indexed bankroller, uint amount, uint bankroll);
    event ProfitsSent(uint time, address indexed treasury, uint amount);
    event AddedToWhitelist(uint time, address indexed addr, address indexed wlOwner);
    event RemovedFromWhitelist(uint time, address indexed addr, address indexed wlOwner);

     
    constructor(address _registry)
        UsingTreasury(_registry)
        public
    {
        ledger = new Ledger(this);
        whitelist = new AddressSet(this);
    }


     
     
         

    function addToWhitelist(address _addr)
        fromWhitelistOwner
        public
    {
        bool _didAdd = whitelist.add(_addr);
        if (_didAdd) emit AddedToWhitelist(now, _addr, msg.sender);
    }

    function removeFromWhitelist(address _addr)
        fromWhitelistOwner
        public
    {
        bool _didRemove = whitelist.remove(_addr);
        if (_didRemove) emit RemovedFromWhitelist(now, _addr, msg.sender);
    }

     
     
     

     
    function () public payable {}

     
    function addBankroll()
        public
        payable 
    {
        require(whitelist.size()==0 || whitelist.has(msg.sender));
        ledger.add(msg.sender, msg.value);
        bankroll = ledger.total();
        emit BankrollAdded(now, msg.sender, msg.value, bankroll);
    }

     
    function removeBankroll(uint _amount, string _callbackFn)
        public
        returns (uint _recalled)
    {
         
        address _bankroller = msg.sender;
        uint _collateral = getCollateral();
        uint _balance = address(this).balance;
        uint _available = _balance > _collateral ? _balance - _collateral : 0;
        if (_amount > _available) _amount = _available;

         
        _amount = ledger.subtract(_bankroller, _amount);
        bankroll = ledger.total();
        if (_amount == 0) return;

        bytes4 _sig = bytes4(keccak256(_callbackFn));
        require(_bankroller.call.value(_amount)(_sig));
        emit BankrollRemoved(now, _bankroller, _amount, bankroll);
        return _amount;
    }

     
    function sendProfits()
        public
        returns (uint _profits)
    {
        int _p = profits();
        if (_p <= 0) return;
        _profits = uint(_p);
        profitsSent += _profits;
         
        address _tr = getTreasury();
        require(_tr.call.value(_profits)());
        emit ProfitsSent(now, _tr, _profits);
    }


     
     
     

     
    function getCollateral()
        public
        view
        returns (uint _amount);

     
    function getWhitelistOwner()
        public
        view
        returns (address _addr);

     
    function profits()
        public
        view
        returns (int _profits)
    {
        int _balance = int(address(this).balance);
        int _threshold = int(bankroll + getCollateral());
        return _balance - _threshold;
    }

     
    function profitsTotal()
        public
        view
        returns (int _profits)
    {
        return int(profitsSent) + profits();
    }

     
     
     
     
    function bankrollAvailable()
        public
        view
        returns (uint _amount)
    {
        uint _balance = address(this).balance;
        uint _bankroll = bankroll;
        uint _collat = getCollateral();
         
        if (_balance <= _collat) return 0;
         
        else if (_balance < _collat + _bankroll) return _balance - _collat;
         
        else return _bankroll;
    }

    function bankrolledBy(address _addr)
        public
        view
        returns (uint _amount)
    {
        return ledger.balanceOf(_addr);
    }

    function bankrollerTable()
        public
        view
        returns (address[], uint[])
    {
        return ledger.balances();
    }
}

 
interface _IBankrollable {
    function sendProfits() external returns (uint _profits);
    function profits() external view returns (int _profits);
}
contract TaskManager is
    HasDailyLimit,
    Bankrollable,
    UsingAdmin,
    UsingMonarchyController
{
    uint constant public version = 1;
    uint public totalRewarded;

     
     
    uint public issueDividendRewardBips;
     
     
    uint public sendProfitsRewardBips;
     
     
    uint public monarchyStartReward;
    uint public monarchyEndReward;
    
    event Created(uint time);
    event DailyLimitChanged(uint time, address indexed owner, uint newValue);
     
    event IssueDividendRewardChanged(uint time, address indexed admin, uint newValue);
    event SendProfitsRewardChanged(uint time, address indexed admin, uint newValue);
    event MonarchyRewardsChanged(uint time, address indexed admin, uint startReward, uint endReward);
     
    event TaskError(uint time, address indexed caller, string msg);
    event RewardSuccess(uint time, address indexed caller, uint reward);
    event RewardFailure(uint time, address indexed caller, uint reward, string msg);
     
    event IssueDividendSuccess(uint time, address indexed treasury, uint profitsSent);
    event SendProfitsSuccess(uint time, address indexed bankrollable, uint profitsSent);
    event MonarchyGameStarted(uint time, address indexed addr, uint initialPrize);
    event MonarchyGamesRefreshed(uint time, uint numEnded, uint feesCollected);

     
    constructor(address _registry)
        public
        HasDailyLimit(1 ether)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        UsingMonarchyController(_registry)
    {
        emit Created(now);
    }


     
     
     

    function setDailyLimit(uint _amount)
        public
        fromOwner
    {
        _setDailyLimit(_amount);
        emit DailyLimitChanged(now, msg.sender, _amount);
    }


     
     
     

    function setIssueDividendReward(uint _bips)
        public
        fromAdmin
    {
        require(_bips <= 10);
        issueDividendRewardBips = _bips;
        emit IssueDividendRewardChanged(now, msg.sender, _bips);
    }

    function setSendProfitsReward(uint _bips)
        public
        fromAdmin
    {
        require(_bips <= 100);
        sendProfitsRewardBips = _bips;
        emit SendProfitsRewardChanged(now, msg.sender, _bips);
    }

    function setMonarchyRewards(uint _startReward, uint _endReward)
        public
        fromAdmin
    {
        require(_startReward <= 1 ether);
        require(_endReward <= 1 ether);
        monarchyStartReward = _startReward;
        monarchyEndReward = _endReward;
        emit MonarchyRewardsChanged(now, msg.sender, _startReward, _endReward);
    }


     
     
     

    function doIssueDividend()
        public
        returns (uint _reward, uint _profits)
    {
         
        ITreasury _tr = getTreasury();
        _profits = _tr.profitsSendable();
         
        if (_profits == 0) {
            _taskError("No profits to send.");
            return;
        }
         
        _profits = _tr.issueDividend();
        if (_profits == 0) {
            _taskError("No profits were sent.");
            return;
        } else {
            emit IssueDividendSuccess(now, address(_tr), _profits);
        }
         
        _reward = (_profits * issueDividendRewardBips) / 10000;
        _sendReward(_reward);
    }

     
    function issueDividendReward()
        public
        view
        returns (uint _reward, uint _profits)
    {
        _profits = getTreasury().profitsSendable();
        _reward = _cappedReward((_profits * issueDividendRewardBips) / 10000);
    }


     
     
     

    function doSendProfits(address _bankrollable)
        public
        returns (uint _reward, uint _profits)
    {
         
        ITreasury _tr = getTreasury();
        uint _oldTrBalance = address(_tr).balance;
        _IBankrollable(_bankrollable).sendProfits();
        uint _newTrBalance = address(_tr).balance;

         
        if (_newTrBalance <= _oldTrBalance) {
            _taskError("No profits were sent.");
            return;
        } else {
            _profits = _newTrBalance - _oldTrBalance;
            emit SendProfitsSuccess(now, _bankrollable, _profits);
        }
        
         
        _reward = (_profits * sendProfitsRewardBips) / 10000;
        _sendReward(_reward);
    }

     
    function sendProfitsReward(address _bankrollable)
        public
        view
        returns (uint _reward, uint _profits)
    {
        int _p = _IBankrollable(_bankrollable).profits();
        if (_p <= 0) return;
        _profits = uint(_p);
        _reward = _cappedReward((_profits * sendProfitsRewardBips) / 10000);
    }


     
     
     

     
    function startMonarchyGame(uint _index)
        public
    {
         
        IMonarchyController _mc = getMonarchyController();
        if (!_mc.getIsStartable(_index)){
            _taskError("Game is not currently startable.");
            return;
        }

         
        address _game = _mc.startDefinedGame(_index);
        if (_game == address(0)) {
            _taskError("MonarchyConroller.startDefinedGame() failed.");
            return;
        } else {
            emit MonarchyGameStarted(now, _game, _mc.getInitialPrize(_index));   
        }

         
        _sendReward(monarchyStartReward);
    }

     
    function startMonarchyGameReward()
        public
        view
        returns (uint _reward, uint _index)
    {
        IMonarchyController _mc = getMonarchyController();
        _index = _mc.getFirstStartableIndex();
        if (_index > 0) _reward = _cappedReward(monarchyStartReward);
    }


     
    function refreshMonarchyGames()
        public
    {
         
        uint _numGamesEnded;
        uint _feesCollected;
        (_numGamesEnded, _feesCollected) = getMonarchyController().refreshGames();
        emit MonarchyGamesRefreshed(now, _numGamesEnded, _feesCollected);

        if (_numGamesEnded == 0) {
            _taskError("No games ended.");
        } else {
            _sendReward(_numGamesEnded * monarchyEndReward);   
        }
    }
    
     
    function refreshMonarchyGamesReward()
        public
        view
        returns (uint _reward, uint _numEndable)
    {
        IMonarchyController _mc = getMonarchyController();
        _numEndable = _mc.getNumEndableGames();
        _reward = _cappedReward(_numEndable * monarchyEndReward);
    }


     
     
     

     
    function _taskError(string _msg) private {
        emit TaskError(now, msg.sender, _msg);
    }

     
    function _sendReward(uint _reward) private {
         
        uint _amount = _cappedReward(_reward);
        if (_reward > 0 && _amount == 0) {
            emit RewardFailure(now, msg.sender, _amount, "Not enough funds, or daily limit reached.");
            return;
        }

         
        if (msg.sender.call.value(_amount)()) {
            _useFromDailyLimit(_amount);
            totalRewarded += _amount;
            emit RewardSuccess(now, msg.sender, _amount);
        } else {
            emit RewardFailure(now, msg.sender, _amount, "Reward rejected by recipient (out of gas, or revert).");
        }
    }

     
    function _cappedReward(uint _reward) private view returns (uint) {
        uint _balance = address(this).balance;
        uint _remaining = getDailyLimitRemaining();
        if (_reward > _balance) _reward = _balance;
        if (_reward > _remaining) _reward = _remaining;
        return _reward;
    }

     
    function getCollateral() public view returns (uint) {}
    function getWhitelistOwner() public view returns (address){ return getAdmin(); }
}