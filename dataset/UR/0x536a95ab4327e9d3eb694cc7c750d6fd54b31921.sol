 

pragma solidity >=0.5.0;

interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        require(c / a == b);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }
}

contract LitionPool {
    using SafeMath for uint256;
    
    event StakingStarted(address indexed staker, uint256 amount, uint8 lockupPeriod, bool compound);
    event StakingFinished(address indexed staker, uint256 amount);
    event StakerRemoved(address indexed staker, uint256 amount);
    event RewardSent(uint256 amount);
    event CompoundChanged(address indexed staker);
    event RewardsWithdrawn(address indexed staker, uint256 amount);

    address public owner;
    IERC20 litionToken;
    uint256 public lastRewardedBlock = 0;

    struct Stake {
        bool valid;
        uint256 amount;
        uint8 lockupPeriod;
        bool compound;
        uint256 timestamp;
        uint256 rewards;
    }

    address[] stakers;
    mapping (address => Stake) public stakesBySender;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor(IERC20 _litionToken) public {
        owner = msg.sender;
        litionToken = _litionToken;
    }
    
    function stakeTokens(uint8 _lockupPeriod, bool _compound, uint256 _amount) public {
        require(!stakesBySender[msg.sender].valid, "You can't increase your stake");
        require(_isValidLockupPeriod(_lockupPeriod), "The lockup period is invalid");
        require(_amount >= 5000000000000000000000, "You must stake at least 5000 LIT");

        require(IERC20(litionToken).transferFrom(msg.sender, address(this), _amount));
        
        stakesBySender[msg.sender].valid = true;
        stakesBySender[msg.sender].amount = _amount;
        stakesBySender[msg.sender].lockupPeriod = _lockupPeriod;
        stakesBySender[msg.sender].compound = _compound;
        stakesBySender[msg.sender].timestamp = now;
        
        stakers.push(msg.sender);
        
        emit StakingStarted(msg.sender, _amount, _lockupPeriod, _compound);
    }
    
    function rewardStakers(uint256 _rewardedBlock, uint256 _amount) public onlyOwner {
        lastRewardedBlock = _rewardedBlock;
        
        uint256 fees = _amount.mul(5) / 100;
        uint256 totalParts = _calculateParts();
        uint256 totalTransferred = 0;
        
        for (uint256 i = 0; i < stakers.length; i++) {
            Stake memory stake = stakesBySender[stakers[i]];
            
            if (!_isValidAndNotExpired(stakers[i])) {
                continue;
            }
            
            uint256 amountToTransfer = _getAmountToTransfer(totalParts, _amount.sub(fees), stake.lockupPeriod, stake.amount);
            totalTransferred = totalTransferred.add(amountToTransfer);
            
            if (stake.compound) {
                stakesBySender[stakers[i]].amount = stakesBySender[stakers[i]].amount.add(amountToTransfer);
            }
            else {
                stakesBySender[stakers[i]].rewards = stakesBySender[stakers[i]].rewards.add(amountToTransfer);
            }
        }
        
        require(IERC20(litionToken).transferFrom(msg.sender, address(this), totalTransferred));

        emit RewardSent(_amount);
    }
    
    function switchCompound() public {
        require(stakesBySender[msg.sender].valid, "You are not staking");
        stakesBySender[msg.sender].compound = !stakesBySender[msg.sender].compound;
        emit CompoundChanged(msg.sender);
    }
    
    function withdrawRewards() public {
        require(stakesBySender[msg.sender].valid, "You are not staking tokens");
        require(stakesBySender[msg.sender].rewards > 0, "You don't have rewards to claim");
        
        uint256 amount = stakesBySender[msg.sender].rewards;
        stakesBySender[msg.sender].rewards = 0;

        require(litionToken.transfer(msg.sender, amount));

        emit RewardsWithdrawn(msg.sender, amount);
    }
    
    function finishStaking() public {
        require(_isLockupPeriodFinished(stakesBySender[msg.sender].timestamp, stakesBySender[msg.sender].lockupPeriod), "The lockup period is not finished");

        uint256 total = _closeStake(msg.sender);
        
        emit StakingFinished(msg.sender, total);
    }
    
    function getTotalInStake() public view returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < stakers.length; i++) {
            Stake memory stake = stakesBySender[stakers[i]];
            total = total.add(stake.amount);
        }
        return total;
    }
    
    function getTotalStakers() public view returns (uint256) {
        return stakers.length;
    }
    
    function getLockupFinishTimestamp(address _staker) public view returns (uint256) {
        require(stakesBySender[_staker].valid, "The address is not staking tokens");

        Stake memory stake = stakesBySender[_staker];
        return stake.timestamp + stake.lockupPeriod * (30 days);
    }

    function _removeStaker(address _staker) public onlyOwner {
        uint256 total = _closeStake(_staker);

        emit StakerRemoved(_staker, total);
    }

    function _closeStake(address _staker) internal returns (uint256) {
        require(stakesBySender[_staker].valid, "This is not a valid staker");

        stakesBySender[_staker].valid = false;
        uint256 rewards = stakesBySender[_staker].rewards;
        uint256 total = stakesBySender[_staker].amount.add(rewards);
        stakesBySender[_staker].amount = 0;
        stakesBySender[_staker].rewards = 0;
        
        _removeByValue(_staker);
        
        require(litionToken.transfer(_staker, total));

        return total;
    }
    
    function _extractLitSentByMistake(address _to) public onlyOwner {
        require(stakers.length == 0, "There are still stakers in the contract");
        uint256 litBalance = litionToken.balanceOf(address(this));
        require(litionToken.transfer(_to, litBalance));
    }
        
    function _calculateParts() internal view returns (uint256) {
        uint256 divideInParts = 0;
        
        for (uint256 i = 0; i < stakers.length; i++) {
            Stake memory stake = stakesBySender[stakers[i]];
            
            if (!_isValidAndNotExpired(stakers[i])) {
                continue;
            }

            if (stake.lockupPeriod == 1) {
                divideInParts = divideInParts.add(stake.amount.mul(12));
            }
            else if (stake.lockupPeriod == 3) {
                divideInParts = divideInParts.add(stake.amount.mul(14));
            }
            else if (stake.lockupPeriod == 6) {
                divideInParts = divideInParts.add(stake.amount.mul(16));
            }
            else if (stake.lockupPeriod == 12) {
                divideInParts = divideInParts.add(stake.amount.mul(18));
            }
        }
        
        return divideInParts;
    }
    
    function _getAmountToTransfer(uint256 _totalParts, uint256 _rewards, uint8 _lockupPeriod, uint256 _amount) internal pure returns (uint256) {
        uint256 factor;
        
        if (_lockupPeriod == 1) {
            factor = 12;
        }
        else if (_lockupPeriod == 3) {
            factor = 14;
        }
        else if (_lockupPeriod == 6) {
            factor = 16;
        }
        else if (_lockupPeriod == 12) {
            factor = 18;
        }

        return _amount.mul(factor).mul(_rewards).div(_totalParts).div(10);
    }
    
    function _isValidLockupPeriod(uint8 n) internal pure returns (bool) {
        if (n == 1) {
            return true;
        }
        else if (n == 3) {
            return true;
        }
        else if (n == 6) {
            return true;
        }
        else if (n == 12) {
            return true;
        }
        return false;
    }
    
    function _isValidAndNotExpired(address _staker) internal view returns (bool) {
        if (!stakesBySender[_staker].valid) {
            return false;
        }
        if (_isLockupPeriodFinished(stakesBySender[_staker].timestamp, stakesBySender[_staker].lockupPeriod)) {
            return false;
        }
        return true;
    }
    
    function _isLockupPeriodFinished(uint256 _timestamp, uint8 _lockupPeriod) internal view returns (bool) {
        return now > _timestamp + _lockupPeriod * (30 days);
    }

    function _transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
    }
    
    function _find(address _value) internal view returns(uint) {
        uint i = 0;
        while (stakers[i] != _value) {
            i++;
        }
        return i;
    }

    function _removeByValue(address _value) internal {
        uint i = _find(_value);
        _removeByIndex(i);
    }

    function _removeByIndex(uint i) internal {
        while (i<stakers.length-1) {
            stakers[i] = stakers[i+1];
            i++;
        }
        stakers.length--;
    }
    
    function() external payable {
        revert();
    }
}