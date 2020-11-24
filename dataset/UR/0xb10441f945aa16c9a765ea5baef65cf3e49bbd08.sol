 

pragma solidity ^0.4.8;


library BobbySafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}


contract BobbyERC20Base {

    address public ceoAddress;
    address public cfoAddress;

     
    bool public paused = false;

    constructor(address cfoAddr) public {
        ceoAddress = msg.sender;
        cfoAddress = cfoAddr;
    }

    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

    function setCEO(address _newCEO) public onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    modifier whenPaused {
        require(paused);
        _;
    }

    function pause() external onlyCEO whenNotPaused {
        paused = true;
    }

    function unpause() public onlyCEO whenPaused {
        paused = false;
    }
}

contract ERC20Interface {

     
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);

     
    event Grant(address indexed src, address indexed dst, uint wad);     
    event Unlock(address indexed user, uint wad);                        

    function name() public view returns (string n);
    function symbol() public view returns (string s);
    function decimals() public view returns (uint8 d);
    function totalSupply() public view returns (uint256 t);
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
}

 
contract ERC20 is ERC20Interface, BobbyERC20Base {
    using BobbySafeMath for uint256;

    uint private _Thousand = 1000;
    uint private _Billion = _Thousand * _Thousand * _Thousand;

     
    string private _name = "BOBBY";      
    string private _symbol = "BOBBY";    
    uint8 private _decimals = 9;         
    uint256 private _totalSupply = 10 * _Billion * (10 ** uint256(_decimals));

    struct LockedToken {
        uint256 total;           
        uint256 duration;        
        uint256 periods;         

        uint256 balance;          
        uint256 unlockLast;       
    }

     
    struct UserToken {
        uint index;                      
        address addr;                    
        uint256 tokens;                  
        LockedToken[] lockedTokens;      
    }

    mapping(address=>UserToken) private _userMap;            
    address[] private _userArray;                            

    uint32 private actionTransfer = 0;
    uint32 private actionGrant = 1;
    uint32 private actionUnlock = 2;

    struct LogEntry {
        uint256 time;
        uint32  action;        
        address from;
        address to;
        uint256 v1;
        uint256 v2;
        uint256 v3;
    }

    LogEntry[] private _logs;

    function _addUser(address addrUser) private returns (UserToken storage) {
        _userMap[addrUser].index = _userArray.length;
        _userMap[addrUser].addr = addrUser;
        _userMap[addrUser].tokens = 0;
        _userArray.push(addrUser);
        return _userMap[addrUser];
    }

     
    constructor(address cfoAddr) BobbyERC20Base(cfoAddr) public {

         
        _userArray.push(address(0));

        UserToken storage userCFO = _addUser(cfoAddr);
        userCFO.tokens = _totalSupply;
    }

     
    function name() public view returns (string n){
        n = _name;
    }

     
    function symbol() public view returns (string s){
        s = _symbol;
    }

     
    function decimals() public view returns (uint8 d){
        d = _decimals;
    }

     
    function totalSupply() public view returns (uint256 t){
        t = _totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance){
        UserToken storage user = _userMap[_owner];
        if (0 == user.index) {
            balance = 0;
            return;
        }

        balance = user.tokens;
        for (uint index = 0; index < user.lockedTokens.length; index++) {
            balance = balance.add((user.lockedTokens[index]).balance);
        }
    }

    function _checkUnlock(address addrUser) private {
        UserToken storage user = _userMap[addrUser];
        if (0 == user.index) {
            return;
        }

        for (uint index = 0; index < user.lockedTokens.length; index++) {
            LockedToken storage locked = user.lockedTokens[index];
            if(locked.balance <= 0){
                continue;
            }

            uint256 diff = now.sub(locked.unlockLast);
            uint256 unlockUnit = locked.total.div(locked.periods);
            uint256 periodDuration = locked.duration.div(locked.periods);
            uint256 unlockedPeriods = locked.total.sub(locked.balance).div(unlockUnit);
            uint256 periodsToUnlock = diff.div(periodDuration);

            if(periodsToUnlock > 0) {
                uint256 tokenToUnlock = 0;
                if(unlockedPeriods + periodsToUnlock >= locked.periods) {
                    tokenToUnlock = locked.balance;
                }else{
                    tokenToUnlock = unlockUnit.mul(periodsToUnlock);
                }

                if (tokenToUnlock >= locked.balance) {
                    tokenToUnlock = locked.balance;
                }

                locked.balance = locked.balance.sub(tokenToUnlock);
                user.tokens = user.tokens.add(tokenToUnlock);
                locked.unlockLast = locked.unlockLast.add(periodDuration.mul(periodsToUnlock));

                emit Unlock(addrUser, tokenToUnlock);
                log(actionUnlock, addrUser, 0, tokenToUnlock, 0, 0);
            }
        }
    }   

     
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success){
        require(msg.sender != _to);

         
        _checkUnlock(msg.sender);

        require(_userMap[msg.sender].tokens >= _value);
        _userMap[msg.sender].tokens = _userMap[msg.sender].tokens.sub(_value);

        UserToken storage userTo = _userMap[_to];
        if(0 == userTo.index){
            userTo = _addUser(_to);
        }
        userTo.tokens = userTo.tokens.add(_value);

        emit Transfer(msg.sender, _to, _value);
        log(actionTransfer, msg.sender, _to, _value, 0, 0);

        success = true;
    }

    function transferFrom(address, address, uint256) public whenNotPaused returns (bool success){
        success = true;
    }

    function approve(address, uint256) public whenNotPaused returns (bool success){
        success = true;
    }

    function allowance(address, address) public view returns (uint256 remaining){
        remaining = 0;
    }

    function grant(address _to, uint256 _value, uint256 _duration, uint256 _periods) public whenNotPaused returns (bool success){
        require(msg.sender != _to);

         
        _checkUnlock(msg.sender);

        require(_userMap[msg.sender].tokens >= _value);
        _userMap[msg.sender].tokens = _userMap[msg.sender].tokens.sub(_value);
        
        UserToken storage userTo = _userMap[_to];
        if(0 == userTo.index){
            userTo = _addUser(_to);
        }

        LockedToken memory locked;
        locked.total = _value;
        locked.duration = _duration.mul(30 days);
         
        locked.periods = _periods;
        locked.balance = _value;
        locked.unlockLast = now;
        userTo.lockedTokens.push(locked);

        emit Grant(msg.sender, _to, _value);
        log(actionGrant, msg.sender, _to, _value, _duration, _periods);

        success = true;
    }

    function getUserAddr(uint256 _index) public view returns(address addr){
        require(_index < _userArray.length);
        addr = _userArray[_index];
    }

    function getUserSize() public view returns(uint256 size){
        size = _userArray.length;
    }


    function getLockSize(address addr) public view returns (uint256 len) {
        UserToken storage user = _userMap[addr];
        len = user.lockedTokens.length;
    }

    function getLock(address addr, uint256 index) public view returns (uint256 total, uint256 duration, uint256 periods, uint256 balance, uint256 unlockLast) {
        UserToken storage user = _userMap[addr];
        require(index < user.lockedTokens.length);
        total = user.lockedTokens[index].total;
        duration = user.lockedTokens[index].duration;
        periods = user.lockedTokens[index].periods;
        balance = user.lockedTokens[index].balance;
        unlockLast = user.lockedTokens[index].unlockLast;
    }

    function getLockInfo(address addr) public view returns (uint256[] totals, uint256[] durations, uint256[] periodses, uint256[] balances, uint256[] unlockLasts) {
        UserToken storage user = _userMap[addr];
        uint256 len = user.lockedTokens.length;
        totals = new uint256[](len);
        durations = new uint256[](len);
        periodses = new uint256[](len);
        balances = new uint256[](len);
        unlockLasts = new uint256[](len);
        for (uint index = 0; index < user.lockedTokens.length; index++) {
            totals[index] = user.lockedTokens[index].total;
            durations[index] = user.lockedTokens[index].duration;
            periodses[index] = user.lockedTokens[index].periods;
            balances[index] = user.lockedTokens[index].balance;
            unlockLasts[index] = user.lockedTokens[index].unlockLast;
        }
    }

    function log(uint32 action, address from, address to, uint256 _v1, uint256 _v2, uint256 _v3) private {
        LogEntry memory entry;
        entry.action = action;
        entry.time = now;
        entry.from = from;
        entry.to = to;
        entry.v1 = _v1;
        entry.v2 = _v2;
        entry.v3 = _v3;
        _logs.push(entry);
    }

    function getLogSize() public view returns(uint256 size){
        size = _logs.length;
    }

    function getLog(uint256 _index) public view returns(uint time, uint32 action, address from, address to, uint256 _v1, uint256 _v2, uint256 _v3){
        require(_index < _logs.length);
        require(_index >= 0);
        LogEntry storage entry = _logs[_index];
        action = entry.action;
        time = entry.time;
        from = entry.from;
        to = entry.to;
        _v1 = entry.v1;
        _v2 = entry.v2;
        _v3 = entry.v3;
    }
}