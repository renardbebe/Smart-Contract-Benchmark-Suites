 

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

 
 
interface IMonarchyFactory {
    function lastCreatedGame() external view returns (address _game);
    function getCollector() external view returns (address _collector);
}

contract UsingMonarchyFactory is
    UsingRegistry
{
    constructor(address _registry)
        UsingRegistry(_registry)
        public
    {}

    modifier fromMonarchyFactory(){ 
        require(msg.sender == address(getMonarchyFactory()));
        _;
    }

    function getMonarchyFactory()
        public
        view
        returns (IMonarchyFactory)
    {
        return IMonarchyFactory(addressOf("MONARCHY_FACTORY"));
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

 
interface IMonarchyGame {
    function sendPrize(uint _gasLimit) external returns (bool _success, uint _prizeSent);
    function sendFees() external returns (uint _feesSent);
    function prize() external view returns(uint);
    function numOverthrows() external view returns(uint);
    function fees() external view returns (uint _fees);
    function monarch() external view returns (address _addr);
    function isEnded() external view returns (bool _bool);
    function isPaid() external view returns (bool _bool);
}

 
contract MonarchyController is
    HasDailyLimit,
    Bankrollable,
    UsingAdmin,
    UsingMonarchyFactory
{
    uint constant public version = 1;

     
    uint public totalFees;
    uint public totalPrizes;
    uint public totalOverthrows;
    IMonarchyGame[] public endedGames;

     
     
    uint public numDefinedGames;
    mapping (uint => DefinedGame) public definedGames;
    struct DefinedGame {
        IMonarchyGame game;      
        bool isEnabled;          
        string summary;          
        uint initialPrize;       
        uint fee;                
        int prizeIncr;           
        uint reignBlocks;        
        uint initialBlocks;      
    }

    event Created(uint time);
    event DailyLimitChanged(uint time, address indexed owner, uint newValue);
    event Error(uint time, string msg);
    event DefinedGameEdited(uint time, uint index);
    event DefinedGameEnabled(uint time, uint index, bool isEnabled);
    event DefinedGameFailedCreation(uint time, uint index);
    event GameStarted(uint time, uint indexed index, address indexed addr, uint initialPrize);
    event GameEnded(uint time, uint indexed index, address indexed addr, address indexed winner);
    event FeesCollected(uint time, uint amount);


    constructor(address _registry) 
        HasDailyLimit(10 ether)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        UsingMonarchyFactory(_registry)
        public
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


     
     
     

     
    function editDefinedGame(
        uint _index,
        string _summary,
        uint _initialPrize,
        uint _fee,
        int _prizeIncr,
        uint _reignBlocks,
        uint _initialBlocks
    )
        public
        fromAdmin
        returns (bool _success)
    {
        if (_index-1 > numDefinedGames || _index > 20) {
            emit Error(now, "Index out of bounds.");
            return;
        }

        if (_index-1 == numDefinedGames) numDefinedGames++;
        definedGames[_index].summary = _summary;
        definedGames[_index].initialPrize = _initialPrize;
        definedGames[_index].fee = _fee;
        definedGames[_index].prizeIncr = _prizeIncr;
        definedGames[_index].reignBlocks = _reignBlocks;
        definedGames[_index].initialBlocks = _initialBlocks;
        emit DefinedGameEdited(now, _index);
        return true;
    }

    function enableDefinedGame(uint _index, bool _bool)
        public
        fromAdmin
        returns (bool _success)
    {
        if (_index-1 >= numDefinedGames) {
            emit Error(now, "Index out of bounds.");
            return;
        }
        definedGames[_index].isEnabled = _bool;
        emit DefinedGameEnabled(now, _index, _bool);
        return true;
    }


     
     
     

    function () public payable {
         totalFees += msg.value;
    }

     
     
     
     
     
     
     
     
     
    function startDefinedGame(uint _index)
        public
        returns (address _game)
    {
        DefinedGame memory dGame = definedGames[_index];
        if (_index-1 >= numDefinedGames) {
            _error("Index out of bounds.");
            return;
        }
        if (dGame.isEnabled == false) {
            _error("DefinedGame is not enabled.");
            return;
        }
        if (dGame.game != IMonarchyGame(0)) {
            _error("Game is already started.");
            return;
        }
        if (address(this).balance < dGame.initialPrize) {
            _error("Not enough funds to start this game.");
            return;
        }
        if (getDailyLimitRemaining() < dGame.initialPrize) {
            _error("Starting game would exceed daily limit.");
            return;
        }

         
        IMonarchyFactory _mf = getMonarchyFactory();
        if (_mf.getCollector() != address(this)){
            _error("MonarchyFactory.getCollector() points to a different contract.");
            return;
        }

         
        bool _success = address(_mf).call.value(dGame.initialPrize)(
            bytes4(keccak256("createGame(uint256,uint256,int256,uint256,uint256)")),
            dGame.initialPrize,
            dGame.fee,
            dGame.prizeIncr,
            dGame.reignBlocks,
            dGame.initialBlocks
        );
        if (!_success) {
            emit DefinedGameFailedCreation(now, _index);
            _error("MonarchyFactory could not create game (invalid params?)");
            return;
        }

         
        _useFromDailyLimit(dGame.initialPrize);
        _game = _mf.lastCreatedGame();
        definedGames[_index].game = IMonarchyGame(_game);
        emit GameStarted(now, _index, _game, dGame.initialPrize);
        return _game;
    }
         
        function _error(string _msg)
            private
        {
            emit Error(now, _msg);
        }

    function startDefinedGameManually(uint _index)
        public
        payable
        returns (address _game)
    {
         
        DefinedGame memory dGame = definedGames[_index];
        if (msg.value != dGame.initialPrize) {
            _error("Value sent does not match initialPrize.");
            require(msg.sender.call.value(msg.value)());
            return;
        }

         
        _game = startDefinedGame(_index);
        if (_game == address(0)) {
            require(msg.sender.call.value(msg.value)());
        }
    }

     
     
     
    function refreshGames()
        public
        returns (uint _numGamesEnded, uint _feesCollected)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            IMonarchyGame _game = definedGames[_i].game;
            if (_game == IMonarchyGame(0)) continue;

             
            uint _fees = _game.sendFees();
            _feesCollected += _fees;

             
            if (_game.isEnded()) {
                 
                 
                if (!_game.isPaid()) _game.sendPrize(2300);
                
                 
                totalPrizes += _game.prize();
                totalOverthrows += _game.numOverthrows();

                 
                definedGames[_i].game = IMonarchyGame(0);
                endedGames.push(_game);
                _numGamesEnded++;

                emit GameEnded(now, _i, address(_game), _game.monarch());
            }
        }
        if (_feesCollected > 0) emit FeesCollected(now, _feesCollected);
        return (_numGamesEnded, _feesCollected);
    }


     
     
     
     
    function getCollateral() public view returns (uint) { return 0; }
    function getWhitelistOwner() public view returns (address){ return getAdmin(); }

    function numEndedGames()
        public
        view
        returns (uint)
    {
        return endedGames.length;
    }

    function numActiveGames()
        public
        view
        returns (uint _count)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            if (definedGames[_i].game != IMonarchyGame(0)) _count++;
        }
    }

    function getNumEndableGames()
        public
        view
        returns (uint _count)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            IMonarchyGame _game = definedGames[_i].game;
            if (_game == IMonarchyGame(0)) continue;
            if (_game.isEnded()) _count++;
        }
        return _count;
    }

    function getFirstStartableIndex()
        public
        view
        returns (uint _index)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            if (getIsStartable(_i)) return _i;
        }
    }

     
    function getAvailableFees()
        public
        view
        returns (uint _feesAvailable)
    {
        for (uint _i = 1; _i <= numDefinedGames; _i++) {
            if (definedGames[_i].game == IMonarchyGame(0)) continue;
            _feesAvailable += definedGames[_i].game.fees();
        }
        return _feesAvailable;
    }

    function recentlyEndedGames(uint _num)
        public
        view
        returns (address[] _addresses)
    {
         
        uint _len = endedGames.length;
        if (_num > _len) _num = _len;
        _addresses = new address[](_num);

         
        uint _i = 1;
        while (_i <= _num) {
            _addresses[_i - 1] = endedGames[_len - _i];
            _i++;
        }
    }

     
    function getGame(uint _index)
        public
        view
        returns (address)
    {
        return address(definedGames[_index].game);
    }

    function getIsEnabled(uint _index)
        public
        view
        returns (bool)
    {
        return definedGames[_index].isEnabled;
    }

    function getInitialPrize(uint _index)
        public
        view
        returns (uint)
    {
        return definedGames[_index].initialPrize;
    }

    function getIsStartable(uint _index)
        public
        view
        returns (bool _isStartable)
    {
        DefinedGame memory dGame = definedGames[_index];
        if (_index >= numDefinedGames) return;
        if (dGame.isEnabled == false) return;
        if (dGame.game != IMonarchyGame(0)) return;
        if (dGame.initialPrize > address(this).balance) return;
        if (dGame.initialPrize > getDailyLimitRemaining()) return;
        return true;
    }
     
}