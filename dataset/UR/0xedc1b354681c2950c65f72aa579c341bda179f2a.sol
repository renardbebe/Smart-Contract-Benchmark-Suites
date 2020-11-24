 

pragma solidity ^0.5.7;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    return a / b;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    function mint(address account, uint256 amount) public returns(bool);
    function burn(address account, uint256 amount) public;

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
contract KryptoinETFTokenStakeRewards is Ownable {
    using SafeMath for uint256;

    enum Status { INACTIVE, ACTIVE }

    ERC20Interface public token;  

     
    struct Stake {
        uint256 amount;          
        address user;            
        uint256 timeAtStake;     
        Status stakeStatus;    
        uint256 reward;
    }

    uint256[] public stakesList;                             
    mapping(uint256 => Stake) private stakes;                 
    mapping(address => uint256[]) public userToStakeIDs;     
    mapping(address => uint256) private rewards;              

    uint256 public stakesCount = 0;              
    uint256 tokenDecimals = 18;                  

    uint256 minimumNoOfDaysForStake;

    uint256 INVALID_INDEX = 999999999999;  

    uint256 public poolOne_percent = 6;
    uint256 public poolTwo_percent = 8;
    uint256 public poolThree_percent = 10;
    uint256 public poolFour_percent = 12;
    uint256 public poolFive_percent = 15;

    uint256 public poolOne_rate = 164;
    uint256 public poolTwo_rate = 219;
    uint256 public poolThree_rate = 273;
    uint256 public poolFour_rate = 328;
    uint256 public poolFive_rate = 410;

     
    constructor(ERC20Interface _token) public {
        token = _token;
        minimumNoOfDaysForStake = 10;
    }

     
    event TokenStaked(address user, uint256 amount, uint256 timeAtStake, uint256 stakeID);

     
    function stakeTokens(uint256 tokensAmount) public {
        require(tokensAmount > 0, "tokens must be greater than zero.");

         
        token.burn(msg.sender, tokensAmount);

         
        Stake memory newStake = Stake(tokensAmount, msg.sender, now, Status.INACTIVE, 0);

        stakesCount = stakesCount + 1;
        uint256 stakeID = stakesCount;

         
        stakes[stakeID] = newStake;

         
        stakesList.push(stakeID);

         
        userToStakeIDs[msg.sender].push(stakeID);

        emit TokenStaked(msg.sender, tokensAmount, now, stakeID);
    }

     
    event RewardSet(uint256 from, uint256 to);

     
    function setReward(uint256 from, uint256 to) public onlyOwner {
        
        for(uint256 i = from; i < to; i++) {
            Stake storage stake = stakes[stakesList[i]];
            
            if(stake.stakeStatus == Status.INACTIVE){
                 
                if((stake.timeAtStake + minimumNoOfDaysForStake * 1 days) <= now) {
                     
                    uint256 reward = calculateReward(stake.amount).mul(10);

                     
                    rewards[stake.user] = rewards[stake.user].add(reward);
                    stake.reward = stake.reward.add(reward);
                    
                    stake.stakeStatus = Status.ACTIVE;

                }
            } else if(stake.stakeStatus == Status.ACTIVE){
                 
                uint256 reward = calculateReward(stake.amount);

                 
                rewards[stake.user] = rewards[stake.user].add(reward);
                stake.reward = stake.reward.add(reward);
            }
        }

        emit RewardSet(from, to);
    }

     
    event TokensUnstaked(address user, uint256 amount, uint256 stakeID);

     
    function unstakeTokens(uint256 stakeID) public {
        require(stakeID > 0, "please provide a valid stakeID");

        Stake memory stake_to_unstake = stakes[stakeID];
        address user = stake_to_unstake.user;
        uint256 tokenAmount = stake_to_unstake.amount;

        require(msg.sender == user, "sender is not the valid staker");

         
        uint256 stakeIndexInStakesList = findStakeIndexInStakesList(stakeID);
        if(stakeIndexInStakesList != INVALID_INDEX) {
            stakesList[stakeIndexInStakesList] = stakesList[stakesList.length - 1];
            stakesList.pop();
        }
        
         
        uint256[] storage userStakes = userToStakeIDs[msg.sender];
        uint256 stakeIndexInUserToStakeIDs = findStakeIndexInUserToStakeIDs(msg.sender, stakeID);
        if(stakeIndexInUserToStakeIDs != INVALID_INDEX) {
            userStakes[stakeIndexInUserToStakeIDs] = userStakes[userStakes.length - 1];
            userStakes.pop();
        }

         
        require(token.mint(user, tokenAmount), "unstake mint failed");
        emit TokensUnstaked(msg.sender, tokenAmount, stakeID);
    }

     
    event RewardWithdrawn(address withdrawer, uint256 amount);

     
    function withdrawReward() public {
        require(rewards[msg.sender] > 0, "sender has zero reward");
        
        uint256 reward = rewards[msg.sender];
        rewards[msg.sender] = 0;

         
        require(token.mint(msg.sender, reward), "unstake mint failed");
        emit RewardWithdrawn(msg.sender, reward);
    }

     
    event MinimumNumberOfDaysOfStakeChanged(uint256 min_days);

     
    function changeMinimumNumberOfDaysOfStake(uint256 min_days) public onlyOwner {
        require(min_days > 0, "min_days should be greater than zero");
        minimumNoOfDaysForStake = min_days;

        emit MinimumNumberOfDaysOfStakeChanged(minimumNoOfDaysForStake);
    }

    event PoolsNewRates(uint256 one, uint256 two, uint256 three, uint256 four, uint256 five);

    function changeDailyRewardRateOfPools(uint256 one, uint256 two, uint256 three, uint256 four, uint256 five) public onlyOwner {
        poolOne_rate = one;
        poolTwo_rate = two;
        poolThree_rate = three;
        poolFour_rate = four;
        poolFive_rate = five;

        emit PoolsNewRates(one, two, three, four, five);
    }

    event PoolsNewPerAnnumPercents(uint256 one, uint256 two, uint256 three, uint256 four, uint256 five);

    function changePerAnnumPercentOfPools(uint256 one, uint256 two, uint256 three, uint256 four, uint256 five) public onlyOwner {
        poolOne_percent = one;
        poolTwo_percent = two;
        poolThree_percent = three;
        poolFour_percent = four;
        poolFive_percent = five;

        emit PoolsNewPerAnnumPercents(one, two, three, four, five);
    }

     
    function getAllStakes() public view returns(uint256[] memory) {
        return stakesList;
    }

     
    function getStakeIDsByUser(address user) public view returns(uint256[] memory) {
        return userToStakeIDs[user];
    }

     
    function percentageOfRewardPerAnnum(uint256 tokens_without_decimals) public view returns(uint256) {
        uint256 tokens = tokens_without_decimals;
        uint256 reward_percent;

        if(tokens >= 1000 && tokens <= 9999) {  
            reward_percent = poolOne_percent;
        } else if(tokens >= 10000 && tokens <= 99999) {  
            reward_percent = poolTwo_percent;
        } else if(tokens >= 100000 && tokens <= 999999) {  
            reward_percent = poolThree_percent;
        } else if(tokens >= 1000000 && tokens <= 9999999) {  
            reward_percent = poolFour_percent;
        } else if(tokens >= 10000000) {  
            reward_percent = poolFive_percent;
        }

        return reward_percent;
    }

    function getRewardByUser(address user) public view returns(uint256 reward) {
        reward = rewards[user];
    }

    function stakeIDInfo(uint256 stakeID) public view returns(uint256 amount_staked, address user, uint256 timeOfStake, uint256 reward) {
        Stake memory stake = stakes[stakeID];
        amount_staked = stake.amount;
        user = stake.user;
        timeOfStake = stake.timeAtStake;
        reward = stake.reward;
    }


     
    function calculateReward(uint256 amount) private view returns(uint256) {
        uint256 tokens = amount;
        uint256 reward;

         
        if(tokens >= 1000 * (10 ** tokenDecimals) && tokens <= 9999 * (10 ** tokenDecimals)) {  
            reward = tokens.mul(poolOne_rate).div(1000000);  
        } else if(tokens >= 10000 * (10 ** tokenDecimals) && tokens <= 99999 * (10 ** tokenDecimals)) {  
            reward = tokens.mul(poolTwo_rate).div(1000000);  
        } else if(tokens >= 100000 * (10 ** tokenDecimals) && tokens <= 999999 * (10 ** tokenDecimals)) {  
            reward = tokens.mul(poolThree_rate).div(1000000);  
        } else if(tokens >= 1000000 * (10 ** tokenDecimals) && tokens <= 9999999 * (10 ** tokenDecimals)) {  
            reward = tokens.mul(poolFour_rate).div(1000000);  
        } else if(tokens >= 10000000 * (10 ** tokenDecimals)) {  
            reward = tokens.mul(poolFive_rate).div(1000000);  
        }

        return reward;
    }

      
    function findStakeIndexInStakesList(uint256 stakeID) private view returns(uint256) {
        for(uint256 i = 0; i < stakesList.length; i++) {
            if(stakesList[i] == stakeID) {
                return i;
            }
        }
        return INVALID_INDEX;
    }

     
    function findStakeIndexInUserToStakeIDs(address user, uint256 stakeID) private view returns(uint256) {
        uint256[] memory userStakes = userToStakeIDs[user];

        for(uint256 i = 0; i < userStakes.length; i++) {
            if(userStakes[i] == stakeID) {
                return i;
            }
        }
        return INVALID_INDEX;
    }

}