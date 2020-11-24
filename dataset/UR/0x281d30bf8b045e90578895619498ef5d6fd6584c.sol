 

pragma solidity ^0.4.18;

 
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

 
 
 
contract ServiceAllowance {
    function isTransferAllowed(address _from, address _to, address _sender, address _token, uint _value) public view returns (bool);
}

 
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