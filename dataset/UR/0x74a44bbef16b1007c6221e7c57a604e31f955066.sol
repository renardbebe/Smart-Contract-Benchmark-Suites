 
contract CommTokenVesting is Ownable {
     
     
     
     
     

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

     
    address private _beneficiary;

     
    uint256 private _cliff;
    uint256 private _shiftStart;
    uint256 private _start;
    uint256 private _duration;
    bool private _revocable;

     
    uint256 private _immedReleasedRatio;
    uint256 private _dailyReleasedRatio;
    uint256 private _isNLReleasable;
    uint256 private _dailyReleasedNLAmount;
    uint256 private _durationInDays;

    mapping (address => uint256) private _released;
    mapping (address => bool) private _revoked;

    uint256 constant oneHundredMillion = 100000000;
    uint256 constant secondsPerDay = 86400;

    event TokensReleased(address token, uint256 amount);
    event TokenVestingRevoked(address token);

     
    constructor (address beneficiary, uint256 shiftStart, uint256 cliffDuration, uint256 duration, uint256 immedReleasedRatio, uint256 dailyReleasedRatio, bool revocable) public {
        require(beneficiary != address(0), "TokenVesting: beneficiary is the zero address");
        require(cliffDuration <= duration, "TokenVesting: cliff is longer than duration");
        require(shiftStart.add(duration) > 0, "TokenVesting: final time is before current time");
        require(duration >= secondsPerDay, "TokenVesting: duration must be over a day at least.");

        _beneficiary = beneficiary;
        _revocable = revocable;
        _duration = duration;
        _shiftStart = shiftStart;
        _start = shiftStart.add(block.timestamp);
        _cliff = _start.add(cliffDuration);
        _durationInDays = duration.div(secondsPerDay);

        require(immedReleasedRatio <= oneHundredMillion, "TokenVesting: immedReleasedRatio is larger than 100000000.");
        require(dailyReleasedRatio.mul(_durationInDays) <= oneHundredMillion, "TokenVesting: dailyReleasedRatio*_durationInDays is larger than 100000000.");

        _immedReleasedRatio = immedReleasedRatio;
        _dailyReleasedRatio = dailyReleasedRatio;
        _isNLReleasable = oneHundredMillion.sub(_immedReleasedRatio).sub(_durationInDays.mul(_dailyReleasedRatio));
        _dailyReleasedNLAmount = _isNLReleasable.div(_durationInDays.mul(_durationInDays).mul(_durationInDays));
    }

     
    function beneficiary() external view returns (address) {
        return _beneficiary;
    }

     
    function cliff() external view returns (uint256) {
        return _cliff;
    }

     
    function shiftStart() external view returns (uint256) {
        return _shiftStart;
    }
    
     
    function start() external view returns (uint256) {
        return _start;
    }

     
    function duration() external view returns (uint256) {
        return _duration;
    }

     
    function immedReleasedRatio() external view returns (uint256) {
        return _immedReleasedRatio;
    }

     
    function dailyReleasedRatio() external view returns (uint256) {
        return _dailyReleasedRatio;
    }

     
    function isNLReleasable() external view returns (uint256) {
        return _isNLReleasable;
    }

     
    function dailyReleasedNLAmount() external view returns (uint256) {
        return _dailyReleasedNLAmount;
    }

     
    function revocable() external view returns (bool) {
        return _revocable;
    }

     
    function released(address token) external view returns (uint256) {
        return _released[token];
    }

     
    function revoked(address token) external view returns (bool) {
        return _revoked[token];
    }

     
    function release(IERC20 token) public {
        uint256 unreleased = _releasableAmount(token);

        require(unreleased > 0, "TokenVesting: no tokens are due");

        _released[address(token)] = _released[address(token)].add(unreleased);

        token.safeTransfer(_beneficiary, unreleased);

        emit TokensReleased(address(token), unreleased);
    }

     
    function revoke(IERC20 token) public onlyOwner {
        require(_revocable, "TokenVesting: cannot revoke");
        require(!_revoked[address(token)], "TokenVesting: token already revoked");

        uint256 balance = token.balanceOf(address(this));

        uint256 unreleased = _releasableAmount(token);
        uint256 refund = balance.sub(unreleased);

        _revoked[address(token)] = true;

        token.safeTransfer(owner(), refund);

        emit TokenVestingRevoked(address(token));
    }

     
    function _releasableAmount(IERC20 token) private view returns (uint256) {
        return _vestedAmount(token).sub(_released[address(token)]);
    }

     
    function _vestedAmount(IERC20 token) private view returns (uint256) {
        uint256 currentBalance = token.balanceOf(address(this));
        uint256 totalBalance = currentBalance.add(_released[address(token)]);

        if (block.timestamp < _cliff) {
            return 0;
        } else if (block.timestamp >= _start.add(_duration) || _revoked[address(token)]) {
            return totalBalance;
        } else if (_immedReleasedRatio == 0 && _dailyReleasedRatio == 0) {
            return totalBalance.mul(block.timestamp.sub(_start)).div(_duration);
        } else {
            uint256 daysPassed = block.timestamp.sub(_start).div(secondsPerDay);
            uint256 amount0 = totalBalance.mul(_immedReleasedRatio).div(oneHundredMillion);
            uint256 amount1 = totalBalance.mul(_dailyReleasedRatio).mul(daysPassed).div(oneHundredMillion);
            uint256 amount2 = totalBalance.mul(_dailyReleasedNLAmount.mul(daysPassed.mul(daysPassed).mul(daysPassed))).div(oneHundredMillion);
            uint256 vestedAmount = amount0.add(amount1).add(amount2);
            return totalBalance < vestedAmount ? totalBalance : vestedAmount;
        }
    }
}