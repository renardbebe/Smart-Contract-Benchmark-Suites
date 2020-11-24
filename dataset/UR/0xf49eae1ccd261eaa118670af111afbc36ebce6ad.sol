 
contract TokenTimelock is Ownable {
    using SafeMath for uint256;

     
    IERC20 private _token;

    struct FreezeParams {
        uint256 releaseTime;
        uint256 initValue;
        uint256 monthlyUnlockPercent;
        uint256 currentBalance;
    }

    mapping (address => FreezeParams) public frozenTokens;
    mapping (address => bool) private _admins;
    uint256 public totalReserved;

    modifier onlyAdmin() {
        require(isAdmin(), " caller is not the admin");
        _;
    }

    function isAdmin() public view returns (bool) {
        return _admins[msg.sender];
    }

    function addAdmin(address admin) external onlyOwner {
        _admins[admin] = true;
    }

    function renounceAdmin(address admin) external onlyOwner {
        _admins[admin] = false;
    }

    constructor (IERC20 token) public {
        _token = token;
        _admins[msg.sender] = true;
    }
     
    function token() public view returns (IERC20) {
        return _token;
    }

    function totalHeld() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    event TokensHeld(address indexed _beneficiary, uint256 _value);

    function holdTokens(
        address _beneficiary,
        uint256 _value,
        uint256 _releaseTime,
        uint256 _monthlyUnlockPercent) onlyAdmin external
    {
         
        require(_monthlyUnlockPercent <= 100, "_monthlyUnlockPercent shoulbe <= 100");
        require(_releaseTime.sub(now) <= 365 days, "freeze period is too long");
        require(frozenTokens[_beneficiary].currentBalance == 0, "there are unspended tokens");
        require(totalHeld().sub(totalReserved) >= _value, "not enough tokens");
        frozenTokens[_beneficiary] = FreezeParams(_releaseTime,
            _value,
            _monthlyUnlockPercent,
            _value);
        totalReserved = totalReserved.add(_value);
        emit TokensHeld(_beneficiary, _value);
    }

    function freezeOf(address _beneficiary) public view returns (uint256) {
        FreezeParams memory freezeData = frozenTokens[_beneficiary];
        if (freezeData.releaseTime <= now){
            if (freezeData.monthlyUnlockPercent != 0){
                uint256  monthsPassed;
                monthsPassed = now.sub(freezeData.releaseTime).div(30 days);
                uint256 unlockedValue = freezeData.initValue.mul(monthsPassed).mul(freezeData.monthlyUnlockPercent).div(100);
                if (freezeData.initValue < unlockedValue){
                    return 0;
                }
                else {
                    return freezeData.initValue.sub(unlockedValue);
                }
            }
            else {
                return 0;
            }
        }
        else
        {
            return freezeData.initValue;
        }
    }

     
    function availableBalance(address _beneficiary) public view returns (uint256) {
        return frozenTokens[_beneficiary].currentBalance.sub(freezeOf(_beneficiary));
    }


    function release(address _beneficiary) external {
        uint256 value = availableBalance(_beneficiary);
        require(value > 0, "TokenTimelock: no tokens to release");
        require(_token.balanceOf(address(this)) >= value, "insuficient funds");
        totalReserved = totalReserved.sub(value);
        frozenTokens[_beneficiary].currentBalance = frozenTokens[_beneficiary].currentBalance.sub(value);
        _token.transfer(_beneficiary, value);
    }

    function unfreeze(address _to, uint256 _value) external onlyAdmin {
        require(totalHeld().sub(totalReserved) >= _value, "not enough available tokens");
        _token.transfer(_to, _value);
    }
}
