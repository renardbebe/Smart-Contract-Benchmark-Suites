 

pragma solidity ^0.5.12;

contract HEX {
    function xfLobbyEnter(address referrerAddr)
    external
    payable;

    function xfLobbyExit(uint256 enterDay, uint256 count)
    external;

    function xfLobbyPendingDays(address memberAddr)
    external
    view
    returns (uint256[2] memory words);

    function balanceOf (address account)
    external
    view
    returns (uint256);

    function transfer (address recipient, uint256 amount)
    external
    returns (bool);

    function currentDay ()
    external
    view
    returns (uint256);
}  

contract AutoLobby {

    event UserJoined(
        uint40 timestamp,
        address indexed memberAddress,
        uint256 amount
    );

    event LobbyJoined(
        uint40 timestamp,
        uint16 day,
        uint256 amount
    );

    event LobbyLeft(
        uint40 timestamp,
        uint16 day,
        uint256 hearts
    );

    event MissedLobby(
        uint40 timestamp,
        uint16 day
    );

    struct UserState {
        uint16 firstDayJoined;
        uint16 nextPendingDay;
        uint256 todayAmount;
        uint256 nextDayAmount;
    }

    struct ContractStateCache {
        uint256 currentDay;
        uint256 lastDayJoined;
        uint256 nextPendingDay;
        uint256 todayAmount;
    }

    struct ContractState {
        uint16 _lastDayJoined;
        uint16 _nextPendingDay;
        uint256 _todayAmount;
        uint256 _nextDayAmount;
    }

    struct ParticipationState {
        uint256 poolSize;
        uint256 heartsReceived;
    }

    HEX internal hx = HEX(0x2b591e99afE9f32eAA6214f7B7629768c40Eeb39);

    uint16 internal constant LAUNCH_PHASE_DAYS = 350;
    uint16 internal constant LAUNCH_PHASE_END_DAY = 351;
    uint256 internal constant XF_LOBBY_DAY_WORDS = (LAUNCH_PHASE_END_DAY + 255) >> 8;

    uint256 public HEX_LAUNCH_TIME = 1575331200;

    address payable internal constant REF_ADDRESS = 0xD30BC4859A79852157211E6db19dE159673a67E2;

    ContractState public state;

    mapping(address => UserState) public userData;
    address[] public users;

    mapping(uint256 => ParticipationState) public dailyData;

    constructor ()
    public
    {
        state._nextPendingDay = 1;
    }

    function nudge ()
    external
    {
        ContractStateCache memory currentState;
        ContractStateCache memory snapshot;
        _loadState(currentState, snapshot);

        _nudge(currentState);

        _syncState(currentState, snapshot);
    }

    function _nudge (ContractStateCache memory currentState)
    internal
    {
        if(currentState.lastDayJoined < currentState.currentDay){
            _joinLobby(currentState);
        }
    }

    function depositEth ()
    public
    payable
    returns (uint256)
    {
        require(msg.value > 0, "Deposited ETH must be greater than 0");

        ContractStateCache memory currentState;
        ContractStateCache memory snapshot;
        _loadState(currentState, snapshot);

        require(currentState.currentDay < LAUNCH_PHASE_END_DAY, "Launch phase is over");
        _nudge(currentState);
        uint256 catchUpHearts = _handleWithdrawal(currentState, currentState.currentDay);
        _handleDeposit(currentState);

        emit UserJoined(
            uint40(block.timestamp),
            msg.sender,
            msg.value
        );

        _syncState(currentState, snapshot);

        return catchUpHearts;
    }

    function withdrawHex (uint256 beforeDay)
    external
    returns (uint256)
    {
        ContractStateCache memory currentState;
        ContractStateCache memory snapshot;
        _loadState(currentState, snapshot);

        _nudge(currentState);
        uint256 _beforeDay = beforeDay;
        if(beforeDay == 0 || beforeDay > currentState.currentDay){
            _beforeDay = currentState.currentDay;
        }

       uint256 amount = _handleWithdrawal(currentState, _beforeDay);

        _syncState(currentState, snapshot);

        return amount;
    }

    function ()
    external
    payable
    {
        depositEth();
    }

    function flush ()
    external
    {
        require((LAUNCH_PHASE_END_DAY + 90) < _getHexContractDay(), "Flush is only allowed after 90 days post launch phase");
        if(address(this).balance != 0){
            REF_ADDRESS.transfer(address(this).balance);
        }
        uint256 hexBalance = hx.balanceOf(address(this));
        if(hexBalance > 0){
            hx.transfer(REF_ADDRESS, hexBalance);
        }
    }

    function getHexContractDay()
    public
    view
    returns (uint256)
    {
        return _getHexContractDay();
    }

    function getUsers()
    public
    view
    returns(uint256) {
        return users.length;
    }

    function getUserId(uint256 idx)
    public
    view
    returns(address) {
        return users[idx];
    }

    function getUserData(address addr)
    public
    view
    returns(uint16,
        uint16,
        uint256,
        uint256) {
        return (userData[addr].firstDayJoined,
        userData[addr].nextPendingDay,
        userData[addr].todayAmount,
        userData[addr].nextDayAmount);
    }

    function _joinLobby (ContractStateCache memory currentState)
    private
    {
        if(currentState.lastDayJoined < currentState.currentDay){
            uint256 budget = currentState.todayAmount;
            if(budget > 0){
                uint256 remainingFraction = _calcDailyFractionRemaining(budget, currentState.currentDay);
                uint256 contribution = budget - remainingFraction;
                require(contribution > 0, "daily contribution must be greater than 0");
                hx.xfLobbyEnter.value(contribution)(REF_ADDRESS);
                currentState.lastDayJoined = currentState.currentDay;
                dailyData[currentState.currentDay] = ParticipationState(budget, 0);
                currentState.todayAmount -= contribution;
                emit LobbyJoined(
                    uint40(block.timestamp),
                    uint16(currentState.currentDay),
                    contribution);
            }
        }
    }

    function _handleWithdrawal(ContractStateCache memory currentState, uint256 beforeDay)
    private
    returns (uint256)
    {
        _leaveLobbies(currentState, beforeDay);
        return _distributeShare(beforeDay);
    }

    function _handleDeposit(ContractStateCache memory currentState)
    private
    {
        UserState storage user = userData[msg.sender];
         
        if(user.firstDayJoined == 0){
            uint16 nextDay = uint16(currentState.currentDay + 1);
            user.firstDayJoined = nextDay;
            user.nextPendingDay = nextDay;
            user.todayAmount += msg.value;
            users.push(msg.sender) -1;
        } else {
            user.nextDayAmount += msg.value;
        }

        currentState.todayAmount += msg.value;
    }

    function _leaveLobbies(ContractStateCache memory currentState, uint256 beforeDay)
    private
    {
        uint256 newBalance = hx.balanceOf(address(this));
        uint256 oldBalance;
        if(currentState.nextPendingDay < beforeDay){
            uint256[XF_LOBBY_DAY_WORDS] memory joinedDays = hx.xfLobbyPendingDays(address(this));
            while(currentState.nextPendingDay < beforeDay){
                if( (joinedDays[currentState.nextPendingDay >> 8] & (1 << (currentState.nextPendingDay & 255))) >>
                    (currentState.nextPendingDay & 255) == 1){
                    hx.xfLobbyExit(currentState.nextPendingDay, 0);
                    oldBalance = newBalance;
                    newBalance = hx.balanceOf(address(this));
                    dailyData[currentState.nextPendingDay].heartsReceived = newBalance - oldBalance;
                    require(dailyData[currentState.nextPendingDay].heartsReceived > 0, "Hearts received for a lobby is 0");
                    emit LobbyLeft(uint40(block.timestamp),
                        uint16(currentState.nextPendingDay),
                        dailyData[currentState.nextPendingDay].heartsReceived);
                } else {
                    emit MissedLobby(uint40(block.timestamp),
                     uint16(currentState.nextPendingDay));
                }
                currentState.nextPendingDay++;
            }
        }
    }

    function _distributeShare(uint256 endDay)
    private
    returns (uint256)
    {
        uint256 totalShare = 0;

        UserState storage user = userData[msg.sender];

        if(user.firstDayJoined > 0 && user.firstDayJoined < endDay){
            if(user.nextPendingDay < user.firstDayJoined){
                user.nextPendingDay = user.firstDayJoined;
            }
            uint256 userContribution;
            while(user.nextPendingDay < endDay){
                if(dailyData[user.nextPendingDay].poolSize > 0 && dailyData[user.nextPendingDay].heartsReceived > 0){
                    require(dailyData[user.nextPendingDay].heartsReceived > 0, "Hearts received must be > 0, leave lobby for day");

                    userContribution = user.todayAmount - _calcDailyFractionRemaining(user.todayAmount, user.nextPendingDay);
                    totalShare += user.todayAmount *
                        dailyData[user.nextPendingDay].heartsReceived /
                        dailyData[user.nextPendingDay].poolSize;
                    user.todayAmount -= userContribution;
                    if(user.nextDayAmount > 0){
                        user.todayAmount += user.nextDayAmount;
                        user.nextDayAmount = 0;
                    }
                }
                user.nextPendingDay++;
            }
            if(totalShare > 0){
                require(hx.transfer(msg.sender, totalShare), strConcat("Failed to transfer ",uint2str(totalShare),", insufficient balance"));
            }
        }

        return totalShare;
    }

    function _getHexContractDay()
    private
    view
    returns (uint256)
    {
        require(HEX_LAUNCH_TIME < block.timestamp, "AutoLobby: Launch time not before current block");
        return (block.timestamp - HEX_LAUNCH_TIME) / 1 days;
    }

    function _calcDailyFractionRemaining(uint256 amount, uint256 day)
    private
    pure
    returns (uint256)
    {
        if(day >= LAUNCH_PHASE_DAYS){
            return 0;
        }
        return amount * (LAUNCH_PHASE_END_DAY - day - 1) / (LAUNCH_PHASE_END_DAY - day);
    }

    function _calcDailyFractionRemainingAgg(uint256 amount, uint256 day)
    private
    pure
    returns (uint256)
    {
        if(day >= LAUNCH_PHASE_DAYS){
            return 0;
        } else if( amount >= (LAUNCH_PHASE_END_DAY - day)) {
            return amount * (LAUNCH_PHASE_END_DAY - day - 1) / (LAUNCH_PHASE_END_DAY - day);
        } else {
            return amount / (LAUNCH_PHASE_END_DAY - day) * (LAUNCH_PHASE_END_DAY - day - 1) ;
        }
    }

    function _loadState(ContractStateCache memory c, ContractStateCache memory snapshot)
    internal
    view
    {
        c.currentDay = _getHexContractDay();
        c.lastDayJoined = state._lastDayJoined;
        c.nextPendingDay = state._nextPendingDay;
        c.todayAmount = state._todayAmount;
        _takeSnapshot(c, snapshot);
    }

    function _takeSnapshot(ContractStateCache memory c, ContractStateCache memory snapshot)
    internal
    pure
    {
        snapshot.currentDay = c.currentDay;
        snapshot.lastDayJoined = c.lastDayJoined;
        snapshot.nextPendingDay = c.nextPendingDay;
        snapshot.todayAmount = c.todayAmount;
    }

    function _syncState(ContractStateCache memory c, ContractStateCache memory snapshot)
    internal
    {
        if(snapshot.currentDay != c.currentDay ||
        snapshot.lastDayJoined != c.lastDayJoined ||
        snapshot.nextPendingDay != c.nextPendingDay ||
        snapshot.todayAmount != c.todayAmount)
        {
            _saveState(c);
        }
    }

    function _saveState(ContractStateCache memory c)
    internal
    {
        state._lastDayJoined = uint16(c.lastDayJoined);
        state._nextPendingDay = uint16(c.nextPendingDay);
        state._todayAmount = c.todayAmount;
    }

    function uint2str(uint i)
    internal
    pure returns (string memory _uintAsString)
    {
        uint _i = i;
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function strConcat(string memory _a, string memory _b, string memory _c
    , string memory _d, string memory _e)
    private
    pure
    returns (string memory){
    bytes memory _ba = bytes(_a);
    bytes memory _bb = bytes(_b);
    bytes memory _bc = bytes(_c);
    bytes memory _bd = bytes(_d);
    bytes memory _be = bytes(_e);
    string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
    bytes memory babcde = bytes(abcde);
    uint k = 0;
    for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
    for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
    for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
    for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
    for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
    return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d)
    private
    pure
    returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c)
    private
    pure
    returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b)
    private
    pure
    returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }
}