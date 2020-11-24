 

pragma solidity 0.4.24;
pragma experimental "v0.5.0";

interface RTCoinInterface {
    

     
    function transfer(address _recipient, uint256 _amount) external returns (bool);

    function transferFrom(address _owner, address _recipient, uint256 _amount) external returns (bool);

    function approve(address _spender, uint256 _amount) external returns (bool approved);

     
    function totalSupply() external view returns (uint256);

    function balanceOf(address _holder) external view returns (uint256);

    function allowance(address _owner, address _spender) external view returns (uint256);

     
    function mint(address _recipient, uint256 _amount) external returns (bool);

    function stakeContractAddress() external view returns (address);

    function mergedMinerValidatorAddress() external view returns (address);
    
     
    function freezeTransfers() external returns (bool);

    function thawTransfers() external returns (bool);
}

 
interface ERC20Interface {
    function owner() external view returns (address);
    function decimals() external view returns (uint8);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _amount) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address _owner) external view returns (uint256);
    function allowance(address _owner, address _spender) external view returns (uint256);
}

library SafeMath {

   
   
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


 
 
 
contract Stake {

    using SafeMath for uint256;

     
     
    uint256 constant private MINSTAKE = 1000000000000000000;
     
    uint256 constant private MULTIPLIER = 100000000000000000;
     
    uint256 constant private BLOCKHOLDPERIOD = 2103840;
     
     
     
    uint256 constant private BLOCKSEC = 15;
    string  constant public VERSION = "production";
     
    address  constant public TOKENADDRESS = 0xecc043b92834c1ebDE65F2181B59597a6588D616;
     
    RTCoinInterface   constant public RTI = RTCoinInterface(TOKENADDRESS);

     
    uint256 public activeStakes;
     
    address public admin;
     
    bool public newStakesAllowed;

     
    enum StakeStateEnum { nil, staking, staked }

    struct StakeStruct {
         
        uint256 initialStake;
         
        uint256 blockLocked;
         
        uint256 blockUnlocked;
         
        uint256 releaseDate;
         
        uint256 totalCoinsToMint;
         
        uint256 coinsMinted;
         
        uint256 rewardPerBlock;
         
        uint256 lastBlockWithdrawn;
         
        StakeStateEnum    state;
    }

    event StakesDisabled();
    event StakesEnabled();
    event StakeDeposited(address indexed _staker, uint256 indexed _stakeNum, uint256 _coinsToMint, uint256 _releaseDate, uint256 _releaseBlock);
    event StakeRewardWithdrawn(address indexed _staker, uint256 indexed _stakeNum, uint256 _reward);
    event InitialStakeWithdrawn(address indexed _staker, uint256 indexed _stakeNumber, uint256 _amount);
    event ForeignTokenTransfer(address indexed _sender, address indexed _recipient, uint256 _amount);

     
    mapping (address => mapping (uint256 => StakeStruct)) public stakes;
     
    mapping (address => uint256) public numberOfStakes;
     
    mapping (address => uint256) public internalRTCBalances;

    modifier validInitialStakeRelease(uint256 _stakeNum) {
         
        require(stakes[msg.sender][_stakeNum].state == StakeStateEnum.staking, "stake is not active");
        require(
             
             
            now >= stakes[msg.sender][_stakeNum].releaseDate && block.number >= stakes[msg.sender][_stakeNum].blockUnlocked, 
            "attempting to withdraw initial stake before unlock block and date"
        );
        require(internalRTCBalances[msg.sender] >= stakes[msg.sender][_stakeNum].initialStake, "invalid internal rtc balance");
        _;
    }

    modifier validMint(uint256 _stakeNumber) {
         
        require(
            stakes[msg.sender][_stakeNumber].state == StakeStateEnum.staking || stakes[msg.sender][_stakeNumber].state == StakeStateEnum.staked, 
            "stake must be active or inactive in order to mint tokens"
        );
         
        require(
            stakes[msg.sender][_stakeNumber].coinsMinted < stakes[msg.sender][_stakeNumber].totalCoinsToMint, 
            "current coins minted must be less than total"
        );
        uint256 currentBlock = block.number;
        uint256 lastBlockWithdrawn = stakes[msg.sender][_stakeNumber].lastBlockWithdrawn;
         
        require(currentBlock > lastBlockWithdrawn, "current block must be one higher than last withdrawal");
        _;
    }

    modifier stakingEnabled(uint256 _numRTC) {
         
        require(canMint(), "staking contract is unable to mint tokens");
         
        require(newStakesAllowed, "new stakes are not allowed");
         
        require(_numRTC >= MINSTAKE, "specified stake is lower than minimum amount");
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "sender is not admin");
        _;
    }

    constructor(address _admin) public {
        require(TOKENADDRESS != address(0), "token address not set");
        admin = _admin;
    }

     
    function disableNewStakes() public onlyAdmin returns (bool) {
        newStakesAllowed = false;
        return true;
    }

     
    function allowNewStakes() public onlyAdmin returns (bool) {
        newStakesAllowed = true;
        require(RTI.stakeContractAddress() == address(this), "rtc token contract is not set to use this contract as the staking contract");
        return true;
    }

     
    function mint(uint256 _stakeNumber) public validMint(_stakeNumber) returns (bool) {
         
        uint256 mintAmount = calculateMint(_stakeNumber);
         
        stakes[msg.sender][_stakeNumber].coinsMinted = stakes[msg.sender][_stakeNumber].coinsMinted.add(mintAmount);
         
        stakes[msg.sender][_stakeNumber].lastBlockWithdrawn = block.number;
         
        emit StakeRewardWithdrawn(msg.sender, _stakeNumber, mintAmount);
         
        require(RTI.mint(msg.sender, mintAmount), "token minting failed");
        return true;
    }

     
    function withdrawInitialStake(uint256 _stakeNumber) public validInitialStakeRelease(_stakeNumber) returns (bool) {
         
        uint256 initialStake = stakes[msg.sender][_stakeNumber].initialStake;
         
        stakes[msg.sender][_stakeNumber].state = StakeStateEnum.staked;
         
        activeStakes = activeStakes.sub(1);
         
        internalRTCBalances[msg.sender] = internalRTCBalances[msg.sender].sub(initialStake);
         
        emit InitialStakeWithdrawn(msg.sender, _stakeNumber, initialStake);
         
        require(RTI.transfer(msg.sender, initialStake), "unable to transfer tokens likely due to incorrect balance");
        return true;
    }

     
    function depositStake(uint256 _numRTC) public stakingEnabled(_numRTC) returns (bool) {
        uint256 stakeCount = getStakeCount(msg.sender);

         
        (uint256 blockLocked, 
        uint256 blockReleased, 
        uint256 releaseDate, 
        uint256 totalCoinsMinted,
        uint256 rewardPerBlock) = calculateStake(_numRTC);

         
        StakeStruct memory ss = StakeStruct({
            initialStake: _numRTC,
            blockLocked: blockLocked,
            blockUnlocked: blockReleased,
            releaseDate: releaseDate,
            totalCoinsToMint: totalCoinsMinted,
            coinsMinted: 0,
            rewardPerBlock: rewardPerBlock,
            lastBlockWithdrawn: blockLocked,
            state: StakeStateEnum.staking
        });

         
        stakes[msg.sender][stakeCount] = ss;
         
        numberOfStakes[msg.sender] = numberOfStakes[msg.sender].add(1);
         
        internalRTCBalances[msg.sender] = internalRTCBalances[msg.sender].add(_numRTC);
         
        activeStakes = activeStakes.add(1);
         
        emit StakeDeposited(msg.sender, stakeCount, totalCoinsMinted, releaseDate, blockReleased);
         
        require(RTI.transferFrom(msg.sender, address(this), _numRTC), "transfer from failed, likely needs approval");
        return true;
    }


     

     
    function calculateStake(uint256 _numRTC) 
        internal
        view
        returns (
            uint256 blockLocked, 
            uint256 blockReleased, 
            uint256 releaseDate, 
            uint256 totalCoinsMinted,
            uint256 rewardPerBlock
        ) 
    {
         
        blockLocked = block.number;
         
        blockReleased = blockLocked.add(BLOCKHOLDPERIOD);
         
         
         
        releaseDate = now.add(BLOCKHOLDPERIOD.mul(BLOCKSEC));
         
        totalCoinsMinted = _numRTC.mul(MULTIPLIER);
         
        totalCoinsMinted = totalCoinsMinted.div(1 ether);
         
        rewardPerBlock = totalCoinsMinted.div(BLOCKHOLDPERIOD);
    }

     
    function calculateMint(uint256 _stakeNumber)
        internal
        view
        returns (uint256 reward)
    {
         
        uint256 currentBlock = calculateCurrentBlock(_stakeNumber);
         
        uint256 lastBlockWithdrawn = stakes[msg.sender][_stakeNumber].lastBlockWithdrawn;
         
        uint256 blocksToReward = currentBlock.sub(lastBlockWithdrawn);
         
        reward = blocksToReward.mul(stakes[msg.sender][_stakeNumber].rewardPerBlock);
         
        uint256 totalToMint = stakes[msg.sender][_stakeNumber].totalCoinsToMint;
         
        uint256 currentCoinsMinted = stakes[msg.sender][_stakeNumber].coinsMinted;
         
        uint256 newCoinsMinted = currentCoinsMinted.add(reward);
         
        if (newCoinsMinted > totalToMint) {
            reward = newCoinsMinted.sub(totalToMint);
        }
    }

     
    function transferForeignToken(
        address _tokenAddress,
        address _recipient,
        uint256 _amount)
        public
        onlyAdmin
        returns (bool)
    {
        require(_recipient != address(0), "recipient address can't be empty");
         
        require(_tokenAddress != TOKENADDRESS, "token can't be RTC");
        ERC20Interface eI = ERC20Interface(_tokenAddress);
        require(eI.transfer(_recipient, _amount), "token transfer failed");
        emit ForeignTokenTransfer(msg.sender, _recipient, _amount);
        return true;
    }

     
    function calculateCurrentBlock(uint256 _stakeNumber) internal view returns (uint256 currentBlock) {
        currentBlock = block.number;
         
         
        if (currentBlock >= stakes[msg.sender][_stakeNumber].blockUnlocked) {
            currentBlock = stakes[msg.sender][_stakeNumber].blockUnlocked;
        }
    }
    
     
    function getStakeCount(address _staker) internal view returns (uint256) {
        return numberOfStakes[_staker];
    }

     
    function canMint() public view returns (bool) {
        require(RTI.stakeContractAddress() == address(this), "rtc token contract is not set to use this contract as the staking contract");
        return true;
    }
}