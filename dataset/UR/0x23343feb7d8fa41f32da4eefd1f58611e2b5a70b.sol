 

pragma solidity ^0.4.11;

 
contract Owned {
     
    address public contractOwner;

     
    address public pendingContractOwner;

    function Owned() {
        contractOwner = msg.sender;
    }

     
    modifier onlyContractOwner() {
        if (contractOwner == msg.sender) {
            _;
        }
    }

     
    function destroy() onlyContractOwner {
        suicide(msg.sender);
    }

     
    function changeContractOwnership(address _to) onlyContractOwner() returns(bool) {
        if (_to  == 0x0) {
            return false;
        }

        pendingContractOwner = _to;
        return true;
    }

     
    function claimContractOwnership() returns(bool) {
        if (pendingContractOwner != msg.sender) {
            return false;
        }

        contractOwner = pendingContractOwner;
        delete pendingContractOwner;

        return true;
    }
}

contract ERC20Interface {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}

 
contract Object is Owned {
     
    uint constant OK = 1;
    uint constant OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER = 8;

    function withdrawnTokens(address[] tokens, address _to) onlyContractOwner returns(uint) {
        for(uint i=0;i<tokens.length;i++) {
            address token = tokens[i];
            uint balance = ERC20Interface(token).balanceOf(this);
            if(balance != 0)
                ERC20Interface(token).transfer(_to,balance);
        }
        return OK;
    }

    function checkOnlyContractOwner() internal constant returns(uint) {
        if (contractOwner == msg.sender) {
            return OK;
        }

        return OWNED_ACCESS_DENIED_ONLY_CONTRACT_OWNER;
    }
}

 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
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

contract OracleContractAdapter is Object {

    event OracleAdded(address _oracle);
    event OracleRemoved(address _oracle);

    mapping(address => bool) public oracles;

     
    modifier onlyOracle {
        if (oracles[msg.sender]) {
            _;
        }
    }

    modifier onlyOracleOrOwner {
        if (oracles[msg.sender] || msg.sender == contractOwner) {
            _;
        }
    }

     
     
     
    function addOracles(address[] _whitelist) 
    onlyContractOwner 
    external 
    returns (uint) 
    {
        for (uint _idx = 0; _idx < _whitelist.length; ++_idx) {
            address _oracle = _whitelist[_idx];
            if (_oracle != 0x0 && !oracles[_oracle]) {
                oracles[_oracle] = true;
                _emitOracleAdded(_oracle);
            }
        }
        return OK;
    }

     
     
     
    function removeOracles(address[] _blacklist) 
    onlyContractOwner 
    external 
    returns (uint) 
    {
        for (uint _idx = 0; _idx < _blacklist.length; ++_idx) {
            address _oracle = _blacklist[_idx];
            if (_oracle != 0x0 && oracles[_oracle]) {
                delete oracles[_oracle];
                _emitOracleRemoved(_oracle);
            }
        }
        return OK;
    }

    function _emitOracleAdded(address _oracle) internal {
        OracleAdded(_oracle);
    }

    function _emitOracleRemoved(address _oracle) internal {
        OracleRemoved(_oracle);
    }
}

 
 
 
contract ServiceAllowance {
    function isTransferAllowed(address _from, address _to, address _sender, address _token, uint _value) public view returns (bool);
}

 
 
 
contract DepositWalletInterface {
    function deposit(address _asset, address _from, uint256 amount) public returns (uint);
    function withdraw(address _asset, address _to, uint256 amount) public returns (uint);
}

contract ProfiteroleEmitter {

    event DepositPendingAdded(uint amount, address from, uint timestamp);
    event BonusesWithdrawn(bytes32 userKey, uint amount, uint timestamp);

    event Error(uint errorCode);

    function _emitError(uint _errorCode) internal returns (uint) {
        Error(_errorCode);
        return _errorCode;
    }
}

contract TreasuryEmitter {
    event TreasuryDeposited(bytes32 userKey, uint value, uint lockupDate);
    event TreasuryWithdrawn(bytes32 userKey, uint value);
}

contract ERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed from, address indexed spender, uint256 value);
    string public symbol;

    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
}




 
 
 
 
 
contract Treasury is OracleContractAdapter, ServiceAllowance, TreasuryEmitter {

     

    uint constant PERCENT_PRECISION = 10000;

    uint constant TREASURY_ERROR_SCOPE = 108000;
    uint constant TREASURY_ERROR_TOKEN_NOT_SET_ALLOWANCE = TREASURY_ERROR_SCOPE + 1;

    using SafeMath for uint;

    struct LockedDeposits {
        uint counter;
        mapping(uint => uint) index2Date;
        mapping(uint => uint) date2deposit;
    }

    struct Period {
        uint transfersCount;
        uint totalBmcDays;
        uint bmcDaysPerDay;
        uint startDate;
        mapping(bytes32 => uint) user2bmcDays;
        mapping(bytes32 => uint) user2lastTransferIdx;
        mapping(bytes32 => uint) user2balance;
        mapping(uint => uint) transfer2date;
    }

     

    address token;
    address profiterole;
    uint periodsCount;

    mapping(uint => Period) periods;
    mapping(uint => uint) periodDate2periodIdx;
    mapping(bytes32 => uint) user2lastPeriodParticipated;
    mapping(bytes32 => LockedDeposits) user2lockedDeposits;

     

     
    modifier onlyProfiterole {
        require(profiterole == msg.sender);
        _;
    }

     
    
    function Treasury(address _token) public {
        require(address(_token) != 0x0);
        token = _token;
        periodsCount = 1;
    }

    function init(address _profiterole) public onlyContractOwner returns (uint) {
        require(_profiterole != 0x0);
        profiterole = _profiterole;
        return OK;
    }

     
    function() payable public {
        revert();
    }

     

     
     
     
     
     
     
     
     
     
     
    function deposit(bytes32 _userKey, uint _value, uint _feeAmount, address _feeAddress, uint _lockupDate) external onlyOracle returns (uint) {
        require(_userKey != bytes32(0));
        require(_value != 0);
        require(_feeAmount < _value);

        ERC20 _token = ERC20(token);
        if (_token.allowance(msg.sender, address(this)) < _value) {
            return TREASURY_ERROR_TOKEN_NOT_SET_ALLOWANCE;
        }

        uint _depositedAmount = _value - _feeAmount;
        _makeDepositForPeriod(_userKey, _depositedAmount, _lockupDate);

        uint _periodsCount = periodsCount;
        user2lastPeriodParticipated[_userKey] = _periodsCount;
        delete periods[_periodsCount].startDate;

        if (!_token.transferFrom(msg.sender, address(this), _value)) {
            revert();
        }

        if (!(_feeAddress == 0x0 || _feeAmount == 0 || _token.transfer(_feeAddress, _feeAmount))) {
            revert();
        }

        TreasuryDeposited(_userKey, _depositedAmount, _lockupDate);
        return OK;
    }

     
     
     
     
     
     
     
     
     
     
    function withdraw(bytes32 _userKey, uint _value, address _withdrawAddress, uint _feeAmount, address _feeAddress) external onlyOracle returns (uint) {
        require(_userKey != bytes32(0));
        require(_value != 0);
        require(_feeAmount < _value);

        _makeWithdrawForPeriod(_userKey, _value);
        uint _periodsCount = periodsCount;
        user2lastPeriodParticipated[_userKey] = periodsCount;
        delete periods[_periodsCount].startDate;

        ERC20 _token = ERC20(token);
        if (!(_feeAddress == 0x0 || _feeAmount == 0 || _token.transfer(_feeAddress, _feeAmount))) {
            revert();
        }

        uint _withdrawnAmount = _value - _feeAmount;
        if (!_token.transfer(_withdrawAddress, _withdrawnAmount)) {
            revert();
        }

        TreasuryWithdrawn(_userKey, _withdrawnAmount);
        return OK;
    }

     
     
     
     
     
     
     
    function getSharesPercentForPeriod(bytes32 _userKey, uint _date) public view returns (uint) {
        uint _periodIdx = periodDate2periodIdx[_date];
        if (_date != 0 && _periodIdx == 0) {
            return 0;
        }

        if (_date == 0) {
            _date = now;
            _periodIdx = periodsCount;
        }

        uint _bmcDays = _getBmcDaysAmountForUser(_userKey, _date, _periodIdx);
        uint _totalBmcDeposit = _getTotalBmcDaysAmount(_date, _periodIdx);
        return _totalBmcDeposit != 0 ? _bmcDays * PERCENT_PRECISION / _totalBmcDeposit : 0;
    }

     
     
     
    function getUserBalance(bytes32 _userKey) public view returns (uint) {
        uint _lastPeriodForUser = user2lastPeriodParticipated[_userKey];
        if (_lastPeriodForUser == 0) {
            return 0;
        }

        if (_lastPeriodForUser <= periodsCount.sub(1)) {
            return periods[_lastPeriodForUser].user2balance[_userKey];
        }

        return periods[periodsCount].user2balance[_userKey];
    }

     
     
     
    function getLockedUserBalance(bytes32 _userKey) public returns (uint) {
        return _syncLockedDepositsAmount(_userKey);
    }

     
     
     
     
     
     
    function getLockedUserDeposits(bytes32 _userKey) public view returns (uint[] _lockupDates, uint[] _deposits) {
        LockedDeposits storage _lockedDeposits = user2lockedDeposits[_userKey];
        uint _lockedDepositsCounter = _lockedDeposits.counter;
        _lockupDates = new uint[](_lockedDepositsCounter);
        _deposits = new uint[](_lockedDepositsCounter);

        uint _pointer = 0;
        for (uint _idx = 1; _idx < _lockedDepositsCounter; ++_idx) {
            uint _lockDate = _lockedDeposits.index2Date[_idx];

            if (_lockDate > now) {
                _lockupDates[_pointer] = _lockDate;
                _deposits[_pointer] = _lockedDeposits.date2deposit[_lockDate];
                ++_pointer;
            }
        }
    }

     
     
     
    function getTotalBmcDaysAmount(uint _date) public view returns (uint) {
        return _getTotalBmcDaysAmount(_date, periodsCount);
    }

     
     
    function addDistributionPeriod() public onlyProfiterole returns (uint) {
        uint _periodsCount = periodsCount;
        uint _nextPeriod = _periodsCount.add(1);
        periodDate2periodIdx[now] = _periodsCount;

        Period storage _previousPeriod = periods[_periodsCount];
        uint _totalBmcDeposit = _getTotalBmcDaysAmount(now, _periodsCount);
        periods[_nextPeriod].startDate = now;
        periods[_nextPeriod].bmcDaysPerDay = _previousPeriod.bmcDaysPerDay;
        periods[_nextPeriod].totalBmcDays = _totalBmcDeposit;
        periodsCount = _nextPeriod;

        return OK;
    }

    function isTransferAllowed(address, address, address, address, uint) public view returns (bool) {
        return true;
    }

     

    function _makeDepositForPeriod(bytes32 _userKey, uint _value, uint _lockupDate) internal {
        Period storage _transferPeriod = periods[periodsCount];

        _transferPeriod.user2bmcDays[_userKey] = _getBmcDaysAmountForUser(_userKey, now, periodsCount);
        _transferPeriod.totalBmcDays = _getTotalBmcDaysAmount(now, periodsCount);
        _transferPeriod.bmcDaysPerDay = _transferPeriod.bmcDaysPerDay.add(_value);

        uint _userBalance = getUserBalance(_userKey);
        uint _updatedTransfersCount = _transferPeriod.transfersCount.add(1);
        _transferPeriod.transfersCount = _updatedTransfersCount;
        _transferPeriod.transfer2date[_transferPeriod.transfersCount] = now;
        _transferPeriod.user2balance[_userKey] = _userBalance.add(_value);
        _transferPeriod.user2lastTransferIdx[_userKey] = _updatedTransfersCount;

        _registerLockedDeposits(_userKey, _value, _lockupDate);
    }

    function _makeWithdrawForPeriod(bytes32 _userKey, uint _value) internal {
        uint _userBalance = getUserBalance(_userKey);
        uint _lockedBalance = _syncLockedDepositsAmount(_userKey);
        require(_userBalance.sub(_lockedBalance) >= _value);

        uint _periodsCount = periodsCount;
        Period storage _transferPeriod = periods[_periodsCount];

        _transferPeriod.user2bmcDays[_userKey] = _getBmcDaysAmountForUser(_userKey, now, _periodsCount);
        uint _totalBmcDeposit = _getTotalBmcDaysAmount(now, _periodsCount);
        _transferPeriod.totalBmcDays = _totalBmcDeposit;
        _transferPeriod.bmcDaysPerDay = _transferPeriod.bmcDaysPerDay.sub(_value);

        uint _updatedTransferCount = _transferPeriod.transfersCount.add(1);
        _transferPeriod.transfer2date[_updatedTransferCount] = now;
        _transferPeriod.user2lastTransferIdx[_userKey] = _updatedTransferCount;
        _transferPeriod.user2balance[_userKey] = _userBalance.sub(_value);
        _transferPeriod.transfersCount = _updatedTransferCount;
    }

    function _registerLockedDeposits(bytes32 _userKey, uint _amount, uint _lockupDate) internal {
        if (_lockupDate <= now) {
            return;
        }

        LockedDeposits storage _lockedDeposits = user2lockedDeposits[_userKey];
        uint _lockedBalance = _lockedDeposits.date2deposit[_lockupDate];

        if (_lockedBalance == 0) {
            uint _lockedDepositsCounter = _lockedDeposits.counter.add(1);
            _lockedDeposits.counter = _lockedDepositsCounter;
            _lockedDeposits.index2Date[_lockedDepositsCounter] = _lockupDate;
        }
        _lockedDeposits.date2deposit[_lockupDate] = _lockedBalance.add(_amount);
    }

    function _syncLockedDepositsAmount(bytes32 _userKey) internal returns (uint _lockedSum) {
        LockedDeposits storage _lockedDeposits = user2lockedDeposits[_userKey];
        uint _lockedDepositsCounter = _lockedDeposits.counter;

        for (uint _idx = 1; _idx <= _lockedDepositsCounter; ++_idx) {
            uint _lockDate = _lockedDeposits.index2Date[_idx];

            if (_lockDate <= now) {
                _lockedDeposits.index2Date[_idx] = _lockedDeposits.index2Date[_lockedDepositsCounter];

                delete _lockedDeposits.index2Date[_lockedDepositsCounter];
                delete _lockedDeposits.date2deposit[_lockDate];

                _lockedDepositsCounter = _lockedDepositsCounter.sub(1);
                continue;
            }

            _lockedSum = _lockedSum.add(_lockedDeposits.date2deposit[_lockDate]);
        }

        _lockedDeposits.counter = _lockedDepositsCounter;
    }

    function _getBmcDaysAmountForUser(bytes32 _userKey, uint _date, uint _periodIdx) internal view returns (uint) {
        uint _lastPeriodForUserIdx = user2lastPeriodParticipated[_userKey];
        if (_lastPeriodForUserIdx == 0) {
            return 0;
        }

        Period storage _transferPeriod = _lastPeriodForUserIdx <= _periodIdx ? periods[_lastPeriodForUserIdx] : periods[_periodIdx];
        uint _lastTransferDate = _transferPeriod.transfer2date[_transferPeriod.user2lastTransferIdx[_userKey]];
         
        uint _daysLong = (_date / 1 days) - (_lastTransferDate / 1 days);
        uint _bmcDays = _transferPeriod.user2bmcDays[_userKey];
        return _bmcDays.add(_transferPeriod.user2balance[_userKey] * _daysLong);
    }

     

    function _getTotalBmcDaysAmount(uint _date, uint _periodIdx) private view returns (uint) {
        Period storage _depositPeriod = periods[_periodIdx];
        uint _transfersCount = _depositPeriod.transfersCount;
        uint _lastRecordedDate = _transfersCount != 0 ? _depositPeriod.transfer2date[_transfersCount] : _depositPeriod.startDate;

        if (_lastRecordedDate == 0) {
            return 0;
        }

         
        uint _daysLong = (_date / 1 days).sub((_lastRecordedDate / 1 days));
        uint _totalBmcDeposit = _depositPeriod.totalBmcDays.add(_depositPeriod.bmcDaysPerDay.mul(_daysLong));
        return _totalBmcDeposit;
    }
}

 
 
 
 
 
contract Profiterole is OracleContractAdapter, ServiceAllowance, ProfiteroleEmitter {

    uint constant PERCENT_PRECISION = 10000;

    uint constant PROFITEROLE_ERROR_SCOPE = 102000;
    uint constant PROFITEROLE_ERROR_INSUFFICIENT_DISTRIBUTION_BALANCE = PROFITEROLE_ERROR_SCOPE + 1;
    uint constant PROFITEROLE_ERROR_INSUFFICIENT_BONUS_BALANCE = PROFITEROLE_ERROR_SCOPE + 2;
    uint constant PROFITEROLE_ERROR_TRANSFER_ERROR = PROFITEROLE_ERROR_SCOPE + 3;

    using SafeMath for uint;

    struct Balance {
        uint left;
        bool initialized;
    }

    struct Deposit {
        uint balance;
        uint left;
        uint nextDepositDate;
        mapping(bytes32 => Balance) leftToWithdraw;
    }

    struct UserBalance {
        uint lastWithdrawDate;
    }

    mapping(address => bool) distributionSourcesList;
    mapping(bytes32 => UserBalance) bonusBalances;
    mapping(uint => Deposit) public distributionDeposits;

    uint public firstDepositDate;
    uint public lastDepositDate;

    address public bonusToken;
    address public treasury;
    address public wallet;

     
    modifier onlyDistributionSource {
        if (!distributionSourcesList[msg.sender]) {
            revert();
        }
        _;
    }

    function Profiterole(address _bonusToken, address _treasury, address _wallet) public {
        require(_bonusToken != 0x0);
        require(_treasury != 0x0);
        require(_wallet != 0x0);

        bonusToken = _bonusToken;
        treasury = _treasury;
        wallet = _wallet;
    }

    function() payable public {
        revert();
    }

     

     
     
    function updateTreasury(address _treasury) external onlyContractOwner returns (uint) {
        require(_treasury != 0x0);
        treasury = _treasury;
        return OK;
    }

     
     
    function updateWallet(address _wallet) external onlyContractOwner returns (uint) {
        require(_wallet != 0x0);
        wallet = _wallet;
        return OK;
    }

     
     
     
    function addDistributionSources(address[] _whitelist) external onlyContractOwner returns (uint) {
        for (uint _idx = 0; _idx < _whitelist.length; ++_idx) {
            distributionSourcesList[_whitelist[_idx]] = true;
        }
        return OK;
    }

     
     
     
     
    function removeDistributionSources(address[] _blacklist) external onlyContractOwner returns (uint) {
        for (uint _idx = 0; _idx < _blacklist.length; ++_idx) {
            delete distributionSourcesList[_blacklist[_idx]];
        }
        return OK;
    }

     
     
     
     
     
     
     
     
     
     
     
    function withdrawBonuses(bytes32 _userKey, uint _value, address _withdrawAddress, uint _feeAmount, address _feeAddress) external onlyOracle returns (uint) {
        require(_userKey != bytes32(0));
        require(_value != 0);
        require(_feeAmount < _value);
        require(_withdrawAddress != 0x0);

        DepositWalletInterface _wallet = DepositWalletInterface(wallet);
        ERC20Interface _bonusToken = ERC20Interface(bonusToken);
        if (_bonusToken.balanceOf(_wallet) < _value) {
            return _emitError(PROFITEROLE_ERROR_INSUFFICIENT_BONUS_BALANCE);
        }

        if (OK != _withdrawBonuses(_userKey, _value)) {
            revert();
        }

        if (!(_feeAddress == 0x0 || _feeAmount == 0 || OK == _wallet.withdraw(_bonusToken, _feeAddress, _feeAmount))) {
            revert();
        }

        if (OK != _wallet.withdraw(_bonusToken, _withdrawAddress, _value - _feeAmount)) {
            revert();
        }

        BonusesWithdrawn(_userKey, _value, now);
        return OK;
    }

     

     
     
     
    function getTotalBonusesAmountAvailable(bytes32 _userKey) public view returns (uint _sum) {
        uint _startDate = _getCalculationStartDate(_userKey);
        Treasury _treasury = Treasury(treasury);

        for (
            uint _endDate = lastDepositDate;
            _startDate <= _endDate && _startDate != 0;
            _startDate = distributionDeposits[_startDate].nextDepositDate
        ) {
            Deposit storage _pendingDeposit = distributionDeposits[_startDate];
            Balance storage _userBalance = _pendingDeposit.leftToWithdraw[_userKey];

            if (_userBalance.initialized) {
                _sum = _sum.add(_userBalance.left);
            } else {
                uint _sharesPercent = _treasury.getSharesPercentForPeriod(_userKey, _startDate);
                _sum = _sum.add(_pendingDeposit.balance.mul(_sharesPercent).div(PERCENT_PRECISION));
            }
        }
    }

     
     
     
     
    function getBonusesAmountAvailable(bytes32 _userKey, uint _distributionDate) public view returns (uint) {
        Deposit storage _deposit = distributionDeposits[_distributionDate];
        if (_deposit.leftToWithdraw[_userKey].initialized) {
            return _deposit.leftToWithdraw[_userKey].left;
        }

        uint _sharesPercent = Treasury(treasury).getSharesPercentForPeriod(_userKey, _distributionDate);
        return _deposit.balance.mul(_sharesPercent).div(PERCENT_PRECISION);
    }

     
     
    function getTotalDepositsAmountLeft() public view returns (uint _amount) {
        uint _lastDepositDate = lastDepositDate;
        for (
            uint _startDate = firstDepositDate;
            _startDate <= _lastDepositDate || _startDate != 0;
            _startDate = distributionDeposits[_startDate].nextDepositDate
        ) {
            _amount = _amount.add(distributionDeposits[_startDate].left);
        }
    }

     
     
     
    function getDepositsAmountLeft(uint _distributionDate) public view returns (uint _amount) {
        return distributionDeposits[_distributionDate].left;
    }

     
     
     
     
     
     
     
     
     
     
    function distributeBonuses(uint _amount) public onlyDistributionSource returns (uint) {

        ERC20Interface _bonusToken = ERC20Interface(bonusToken);

        if (_bonusToken.allowance(msg.sender, address(this)) < _amount) {
            return _emitError(PROFITEROLE_ERROR_INSUFFICIENT_DISTRIBUTION_BALANCE);
        }

        if (!_bonusToken.transferFrom(msg.sender, wallet, _amount)) {
            return _emitError(PROFITEROLE_ERROR_TRANSFER_ERROR);
        }

        if (firstDepositDate == 0) {
            firstDepositDate = now;
        }

        uint _lastDepositDate = lastDepositDate;
        if (_lastDepositDate != 0) {
            distributionDeposits[_lastDepositDate].nextDepositDate = now;
        }

        lastDepositDate = now;
        distributionDeposits[now] = Deposit(_amount, _amount, 0);

        Treasury(treasury).addDistributionPeriod();

        DepositPendingAdded(_amount, msg.sender, now);
        return OK;
    }

    function isTransferAllowed(address, address, address, address, uint) public view returns (bool) {
        return false;
    }

     

    function _getCalculationStartDate(bytes32 _userKey) private view returns (uint _startDate) {
        _startDate = bonusBalances[_userKey].lastWithdrawDate;
        return _startDate != 0 ? _startDate : firstDepositDate;
    }

    function _withdrawBonuses(bytes32 _userKey, uint _value) private returns (uint) {
        uint _startDate = _getCalculationStartDate(_userKey);
        uint _lastWithdrawDate = _startDate;
        Treasury _treasury = Treasury(treasury);

        for (
            uint _endDate = lastDepositDate;
            _startDate <= _endDate && _startDate != 0 && _value > 0;
            _startDate = distributionDeposits[_startDate].nextDepositDate
        ) {
            uint _balanceToWithdraw = _withdrawBonusesFromDeposit(_userKey, _startDate, _value, _treasury);
            _value = _value.sub(_balanceToWithdraw);
        }

        if (_lastWithdrawDate != _startDate) {
            bonusBalances[_userKey].lastWithdrawDate = _lastWithdrawDate;
        }

        if (_value > 0) {
            revert();
        }

        return OK;
    }

    function _withdrawBonusesFromDeposit(bytes32 _userKey, uint _periodDate, uint _value, Treasury _treasury) private returns (uint) {
        Deposit storage _pendingDeposit = distributionDeposits[_periodDate];
        Balance storage _userBalance = _pendingDeposit.leftToWithdraw[_userKey];

        uint _balanceToWithdraw;
        if (_userBalance.initialized) {
            _balanceToWithdraw = _userBalance.left;
        } else {
            uint _sharesPercent = _treasury.getSharesPercentForPeriod(_userKey, _periodDate);
            _balanceToWithdraw = _pendingDeposit.balance.mul(_sharesPercent).div(PERCENT_PRECISION);
            _userBalance.initialized = true;
        }

        if (_balanceToWithdraw > _value) {
            _userBalance.left = _balanceToWithdraw - _value;
            _balanceToWithdraw = _value;
        } else {
            delete _userBalance.left;
        }

        _pendingDeposit.left = _pendingDeposit.left.sub(_balanceToWithdraw);
        return _balanceToWithdraw;
    }
}

 
 
 
contract EmissionProviderEmitter {

    event Error(uint errorCode);
    event Emission(bytes32 smbl, address to, uint value);
    event HardcapFinishedManually();
    event Destruction();

    function _emitError(uint _errorCode) internal returns (uint) {
        Error(_errorCode);
        return _errorCode;
    }

    function _emitEmission(bytes32 _smbl, address _to, uint _value) internal {
        Emission(_smbl, _to, _value);
    }

    function _emitHardcapFinishedManually() internal {
        HardcapFinishedManually();
    }

    function _emitDestruction() internal {
        Destruction();
    }
}

contract Token is ERC20 {
    
    bytes32 public smbl;
    address public platform;

    function __transferWithReference(address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __transferFromWithReference(address _from, address _to, uint _value, string _reference, address _sender) public returns (bool);
    function __approve(address _spender, uint _value, address _sender) public returns (bool);
    function getLatestVersion() public returns (address);
    function init(address _bmcPlatform, string _symbol, string _name) public;
    function proposeUpgrade(address _newVersion) public;
}

contract Platform {
    mapping(bytes32 => address) public proxies;
    function name(bytes32 _symbol) public view returns (string);
    function setProxy(address _address, bytes32 _symbol) public returns (uint errorCode);
    function isOwner(address _owner, bytes32 _symbol) public view returns (bool);
    function totalSupply(bytes32 _symbol) public view returns (uint);
    function balanceOf(address _holder, bytes32 _symbol) public view returns (uint);
    function allowance(address _from, address _spender, bytes32 _symbol) public view returns (uint);
    function baseUnit(bytes32 _symbol) public view returns (uint8);
    function proxyTransferWithReference(address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns (uint errorCode);
    function proxyTransferFromWithReference(address _from, address _to, uint _value, bytes32 _symbol, string _reference, address _sender) public returns (uint errorCode);
    function proxyApprove(address _spender, uint _value, bytes32 _symbol, address _sender) public returns (uint errorCode);
    function issueAsset(bytes32 _symbol, uint _value, string _name, string _description, uint8 _baseUnit, bool _isReissuable) public returns (uint errorCode);
    function reissueAsset(bytes32 _symbol, uint _value) public returns (uint errorCode);
    function revokeAsset(bytes32 _symbol, uint _value) public returns (uint errorCode);
    function isReissuable(bytes32 _symbol) public view returns (bool);
    function changeOwnership(bytes32 _symbol, address _newOwner) public returns (uint errorCode);
}


 
 
 
 
 
contract EmissionProvider is OracleContractAdapter, ServiceAllowance, EmissionProviderEmitter {

    uint constant EMISSION_PROVIDER_ERROR_SCOPE = 107000;
    uint constant EMISSION_PROVIDER_ERROR_WRONG_STATE = EMISSION_PROVIDER_ERROR_SCOPE + 1;
    uint constant EMISSION_PROVIDER_ERROR_INSUFFICIENT_BMC = EMISSION_PROVIDER_ERROR_SCOPE + 2;
    uint constant EMISSION_PROVIDER_ERROR_INTERNAL = EMISSION_PROVIDER_ERROR_SCOPE + 3;

    using SafeMath for uint;

    enum State {
        Init, Waiting, Sale, Reached, Destructed
    }

    uint public startDate;
    uint public endDate;

    uint public tokenSoftcapIssued;
    uint public tokenSoftcap;

    uint tokenHardcapIssuedValue;
    uint tokenHardcapValue;

    address public token;
    address public bonusToken;
    address public profiterole;

    mapping(address => bool) public whitelist;

    bool public destructed;
    bool finishedHardcap;
    bool needInitialization;

     
    modifier onlySale {
        var (hardcapState, softcapState) = getState();
        if (!(State.Sale == hardcapState || State.Sale == softcapState)) {
            _emitError(EMISSION_PROVIDER_ERROR_WRONG_STATE);
            assembly {
                mstore(0, 107001)  
                return (0, 32)
            }
        }
        _;
    }

     
    modifier onlySaleFinished {
        var (hardcapState, softcapState) = getState();
        if (hardcapState < State.Reached || softcapState < State.Reached) {
            _emitError(EMISSION_PROVIDER_ERROR_WRONG_STATE);
            assembly {
                mstore(0, 107001)  
                return (0, 32)
            }
        }
        _;
    }
     
    modifier notHardcapReached {
        var (state,) = getState();
        if (state >= State.Reached) {
            _emitError(EMISSION_PROVIDER_ERROR_WRONG_STATE);
            assembly {
                mstore(0, 107001)  
                return (0, 32)
            }
        }
        _;
    }

     
    modifier notSoftcapReached {
        var (, state) = getState();
        if (state >= State.Reached) {
            _emitError(EMISSION_PROVIDER_ERROR_WRONG_STATE);
            assembly {
                mstore(0, 107001)  
                return (0, 32)
            }
        }
        _;
    }

     
    modifier notDestructed {
        if (destructed) {
            _emitError(EMISSION_PROVIDER_ERROR_WRONG_STATE);
            assembly {
                mstore(0, 107001)  
                return (0, 32)
            }
        }
        _;
    }

     
    modifier onlyInit {
        var (state,) = getState();
        if (state != State.Init) {
            _emitError(EMISSION_PROVIDER_ERROR_WRONG_STATE);
            assembly {
                mstore(0, 107001)  
                return (0, 32)
            }
        }
        _;
    }

     
    modifier onlyAllowed(address _account) {
        if (whitelist[_account]) {
            _;
        }
    }

     
     
     
     
     
     
     
     
    function EmissionProvider(
        address _token,
        address _bonusToken,
        address _profiterole,
        uint _startDate,
        uint _endDate,
        uint _tokenSoftcap,
        uint _tokenHardcap
    )
    public
    {
        require(_token != 0x0);
        require(_bonusToken != 0x0);

        require(_profiterole != 0x0);

        require(_startDate != 0);
        require(_endDate > _startDate);

        require(_tokenSoftcap != 0);
        require(_tokenHardcap >= _tokenSoftcap);

        require(Profiterole(_profiterole).bonusToken() == _bonusToken);

        token = _token;
        bonusToken = _bonusToken;
        profiterole = _profiterole;
        startDate = _startDate;
        endDate = _endDate;
        tokenSoftcap = _tokenSoftcap;
        tokenHardcapValue = _tokenHardcap - _tokenSoftcap;
        needInitialization = true;
    }

     
    function() public payable {
        revert();
    }

     
     
    function init() public onlyContractOwner onlyInit returns (uint) {
        needInitialization = false;
        bytes32 _symbol = Token(token).smbl();
        if (OK != Platform(Token(token).platform()).reissueAsset(_symbol, tokenSoftcap)) {
            revert();
        }
        return OK;
    }

     
     
    function tokenHardcap() public view returns (uint) {
        return tokenSoftcap + tokenHardcapValue;
    }

     
     
    function tokenHardcapIssued() public view returns (uint) {
        return tokenSoftcap + tokenHardcapIssuedValue;
    }

     
     
    function getState() public view returns (State, State) {
        if (needInitialization) {
            return (State.Init, State.Init);
        }

        if (destructed) {
            return (State.Destructed, State.Destructed);
        }

        if (now < startDate) {
            return (State.Waiting, State.Waiting);
        }

        State _hardcapState = (finishedHardcap || (tokenHardcapIssuedValue == tokenHardcapValue) || (now > endDate))
        ? State.Reached
        : State.Sale;

        State _softcapState = (tokenSoftcapIssued == tokenSoftcap)
        ? State.Reached
        : State.Sale;

        return (_hardcapState, _softcapState);
    }

     
     
    function addUsers(address[] _whitelist) public onlyOracleOrOwner onlySale returns (uint) {
        for (uint _idx = 0; _idx < _whitelist.length; ++_idx) {
            whitelist[_whitelist[_idx]] = true;
        }
        return OK;
    }

     
     
    function removeUsers(address[] _blacklist) public onlyOracleOrOwner onlySale returns (uint) {
        for (uint _idx = 0; _idx < _blacklist.length; ++_idx) {
            delete whitelist[_blacklist[_idx]];
        }
        return OK;
    }

     
     
     
     
     
     
    function issueHardcapToken(
        address _token, 
        address _for, 
        uint _value
    ) 
    onlyOracle 
    onlyAllowed(_for) 
    onlySale 
    notHardcapReached 
    public
    returns (uint) 
    {
        require(_token == token);
        require(_value != 0);

        uint _tokenHardcap = tokenHardcapValue;
        uint _issued = tokenHardcapIssuedValue;
        if (_issued.add(_value) > _tokenHardcap) {
            _value = _tokenHardcap.sub(_issued);
        }

        tokenHardcapIssuedValue = _issued.add(_value);

        bytes32 _symbol = Token(_token).smbl();
        if (OK != Platform(Token(_token).platform()).reissueAsset(_symbol, _value)) {
            revert();
        }

        if (!Token(_token).transfer(_for, _value)) {
            revert();
        }

        _emitEmission(_symbol, _for, _value);
        return OK;
    }

     
     
     
     
     
     
    function issueSoftcapToken(
        address _token, 
        address _for, 
        uint _value
    ) 
    onlyOracle
    onlyAllowed(_for)
    onlySale
    notSoftcapReached
    public
    returns (uint)
    {
        require(_token == token);
        require(_value != 0);

        uint _tokenSoftcap = tokenSoftcap;
        uint _issued = tokenSoftcapIssued;
        if (_issued.add(_value) > _tokenSoftcap) {
            _value = _tokenSoftcap.sub(_issued);
        }

        tokenSoftcapIssued = _issued.add(_value);

        if (!Token(_token).transfer(_for, _value)) {
            revert();
        }

        _emitEmission(Token(_token).smbl(), _for, _value);
        return OK;
    }

     
     
    function finishHardcap() public onlyContractOwner onlySale notHardcapReached returns (uint) {
        finishedHardcap = true;
        _emitHardcapFinishedManually();
        return OK;
    }

     
     
    function distributeBonuses() public onlyOracleOrOwner onlySaleFinished notDestructed returns (uint) {
        ERC20Interface _token = ERC20Interface(bonusToken);
        uint _balance = _token.balanceOf(address(this));

        if (_balance == 0) {
            return _emitError(EMISSION_PROVIDER_ERROR_INSUFFICIENT_BMC);
        }

        Profiterole _profiterole = Profiterole(profiterole);
        if (!_token.approve(address(_profiterole), _balance)) {
            return _emitError(EMISSION_PROVIDER_ERROR_INTERNAL);
        }

        if (OK != _profiterole.distributeBonuses(_balance)) {
            revert();
        }

        return OK;
    }

     
     
    function activateDestruction() public onlyContractOwner onlySaleFinished notDestructed returns (uint) {
        destructed = true;
        _emitDestruction();
        return OK;
    }

     

     
     
     
    function isTransferAllowed(address _from, address _to, address, address _token, uint) public view returns (bool) {
        if (_token == token &&
            ((oracles[_from] && _to == address(this)) ||
            (_from == address(this) && whitelist[_to]))
        ) {
            return true;
        }
    }

    function tokenFallback(address _sender, uint, bytes) external {
        require(msg.sender == Token(token).getLatestVersion());
        require(oracles[_sender]);
    }
}