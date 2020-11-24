 

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

 
contract InstaDice is
    Bankrollable,
    UsingAdmin
{
    struct User {
        uint32 id;
        uint32 r_id;
        uint32 r_block;
        uint8 r_number;
        uint72 r_payout;
    }

     
    struct Stats {
        uint32 numUsers;
        uint32 numRolls;
        uint96 totalWagered;
        uint96 totalWon;
    }
    
     
    struct Settings {
        uint64 minBet;     
        uint64 maxBet;     
        uint8 minNumber;   
        uint8 maxNumber;   
        uint16 feeBips;    
    }

    mapping (address => User) public users;
    Stats stats;
    Settings settings;
    uint8 constant public version = 1;
    
     
    event Created(uint time);
    event SettingsChanged(uint time, address indexed admin);

     
    event RollWagered(uint time, uint32 indexed id, address indexed user, uint bet, uint8 number, uint payout);
    event RollRefunded(uint time, address indexed user, string msg, uint bet, uint8 number);
    event RollFinalized(uint time, uint32 indexed id, address indexed user, uint8 result, uint payout);
    event PayoutError(uint time, string msg);

    constructor(address _registry)
        Bankrollable(_registry)
        UsingAdmin(_registry)
        public
    {
        stats.totalWagered = 1;   
        settings.maxBet = .3 ether;
        settings.minBet = .001 ether;
        settings.minNumber = 5;
        settings.maxNumber = 98;
        settings.feeBips = 100;
        emit Created(now);
    }


     
     
     

     
    function changeSettings(
        uint64 _minBet,
        uint64 _maxBet,
        uint8 _minNumber,
        uint8 _maxNumber,
        uint16 _feeBips
    )
        public
        fromAdmin
    {
        require(_minBet <= _maxBet);     
        require(_maxBet <= .625 ether);  
        require(_minNumber >= 1);        
        require(_maxNumber <= 99);       
        require(_feeBips <= 500);        
        settings.minBet = _minBet;
        settings.maxBet = _maxBet;
        settings.minNumber = _minNumber;
        settings.maxNumber = _maxNumber;
        settings.feeBips = _feeBips;
        emit SettingsChanged(now, msg.sender);
    }
    

     
     
     

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
    function roll(uint8 _number)
        public
        payable
        returns (bool _success)
    {
         
        if (!_validateBetOrRefund(_number)) return;

         
        User memory _user = users[msg.sender];
        if (_user.r_block == uint32(block.number)){
            _errorAndRefund("Only one bet per block allowed.", msg.value, _number);
            return false;
        }
         
        Stats memory _stats = stats;
        if (_user.r_block != 0) _finalizePreviousRoll(_user, _stats);

         
        _stats.numUsers = _user.id == 0 ? _stats.numUsers + 1 : _stats.numUsers;
        _stats.numRolls = stats.numRolls + 1;
        _stats.totalWagered = stats.totalWagered + uint96(msg.value);
        stats = _stats;

         
        _user.id = _user.id == 0 ? _stats.numUsers : _user.id;
        _user.r_id = _stats.numRolls;
        _user.r_block = uint32(block.number);
        _user.r_number = _number;
        _user.r_payout = computePayout(msg.value, _number);
        users[msg.sender] = _user;

         
        emit RollWagered(now, _user.r_id, msg.sender, msg.value, _user.r_number, _user.r_payout);
        return true;
    }

     
     
     
     
     
     
     
     
     
    function payoutPreviousRoll()
        public
        returns (bool _success)
    {
         
        User storage _user = users[msg.sender];
         
        if (_user.r_block == uint32(block.number)){
            emit PayoutError(now, "Cannot payout roll on the same block");
            return false;
        }
         
        if (_user.r_block == 0){
            emit PayoutError(now, "No roll to pay out.");
            return false;
        }

         
        Stats memory _stats = stats;
        _finalizePreviousRoll(_user, _stats);

         
        _user.r_id = 0;
        _user.r_block = 0;
        _user.r_number = 0;
        _user.r_payout = 0;
        stats.totalWon = _stats.totalWon;
        return true;
    }


     
     
     

     
    function _validateBetOrRefund(uint8 _number)
        private
        returns (bool _isValid)
    {
        Settings memory _settings = settings;
        if (_number < _settings.minNumber) {
            _errorAndRefund("Roll number too small.", msg.value, _number);
            return false;
        }
        if (_number > _settings.maxNumber){
            _errorAndRefund("Roll number too large.", msg.value, _number);
            return false;
        }
        if (msg.value < _settings.minBet){
            _errorAndRefund("Bet too small.", msg.value, _number);
            return false;
        }
        if (msg.value > _settings.maxBet){
            _errorAndRefund("Bet too large.", msg.value, _number);
            return false;
        }
        if (msg.value > curMaxBet()){
            _errorAndRefund("May be unable to payout on a win.", msg.value, _number);
            return false;
        }
        return true;
    }

     
     
     
    function _finalizePreviousRoll(User memory _user, Stats memory _stats)
        private
    {
        assert(_user.r_block != uint32(block.number));
        assert(_user.r_block != 0);
        
         
        uint8 _result = computeResult(_user.r_block, _user.r_id);
        bool _isWinner = _result <= _user.r_number;
        if (_isWinner) {
            require(msg.sender.call.value(_user.r_payout)());
            _stats.totalWon += _user.r_payout;
        }
         
        emit RollFinalized(now, _user.r_id, msg.sender, _result, _isWinner ? _user.r_payout : 0);
    }

     
     
    function _errorAndRefund(string _msg, uint _bet, uint8 _number)
        private
    {
        require(msg.sender.call.value(msg.value)());
        emit RollRefunded(now, msg.sender, _msg, _bet, _number);
    }


     
     
     

     
     
    function getCollateral() public view returns (uint _amount) {
        return 0;
    }

     
     
    function getWhitelistOwner() public view returns (address _wlOwner)
    {
        return getAdmin();
    }

     
     
     
    function curMaxBet() public view returns (uint _amount) {
         
        uint _maxPayout = 10 * 100 / uint(settings.minNumber);
        return bankrollAvailable() / _maxPayout;
    }

     
    function effectiveMaxBet() public view returns (uint _amount) {
        uint _curMax = curMaxBet();
        return _curMax > settings.maxBet ? settings.maxBet : _curMax;
    }

     
    function computePayout(uint _bet, uint _number)
        public
        view
        returns (uint72 _wei)
    {
        uint _feeBips = settings.feeBips;    
        uint _bigBet = _bet * 1e32;          
        uint _bigPayout = (_bigBet * 100) / _number;
        uint _bigFee = (_bigPayout * _feeBips) / 10000;
        return uint72( (_bigPayout - _bigFee) / 1e32 );
    }

     
     
    function computeResult(uint32 _blockNumber, uint32 _id)
        public
        view
        returns (uint8 _result)
    {
        bytes32 _blockHash = blockhash(_blockNumber);
        if (_blockHash == 0) { return 101; }
        return uint8(uint(keccak256(_blockHash, _id)) % 100 + 1);
    }

     
    function numUsers() public view returns (uint32) {
        return stats.numUsers;
    }
    function numRolls() public view returns (uint32) {
        return stats.numRolls;
    }
    function totalWagered() public view returns (uint) {
        return stats.totalWagered;
    }
    function totalWon() public view returns (uint) {
        return stats.totalWon;
    }
     

     
    function minBet() public view returns (uint) {
        return settings.minBet;
    }
    function maxBet() public view returns (uint) {
        return settings.maxBet;
    }
    function minNumber() public view returns (uint8) {
        return settings.minNumber;
    }
    function maxNumber() public view returns (uint8) {
        return settings.maxNumber;
    }
    function feeBips() public view returns (uint16) {
        return settings.feeBips;
    }
     

}