 

pragma solidity 0.4.25;

library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns(uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns(uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns(uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0);
        return a % b;
    }
}

library ExtendedMath {
    function limitLessThan(uint a, uint b) internal pure returns(uint c) {
        if (a > b) return b;
        return a;
    }
}

contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

contract InterfaceContracts is Ownable {
    InterfaceContracts public _internalMod;
    
    function setModifierContract (address _t) onlyOwner public {
        _internalMod = InterfaceContracts(_t);
    }

    modifier onlyMiningContract() {
      require(msg.sender == _internalMod._contract_miner(), "Wrong sender");
          _;
      }

    modifier onlyTokenContract() {
      require(msg.sender == _internalMod._contract_token(), "Wrong sender");
      _;
    }
    
    modifier onlyMasternodeContract() {
      require(msg.sender == _internalMod._contract_masternode(), "Wrong sender");
      _;
    }
    
    modifier onlyVotingOrOwner() {
      require(msg.sender == _internalMod._contract_voting() || msg.sender == owner, "Wrong sender");
      _;
    }
    
    modifier onlyVotingContract() {
      require(msg.sender == _internalMod._contract_voting() || msg.sender == owner, "Wrong sender");
      _;
    }
      
    function _contract_voting () public view returns (address) {
        return _internalMod._contract_voting();
    }
    
    function _contract_masternode () public view returns (address) {
        return _internalMod._contract_masternode();
    }
    
    function _contract_token () public view returns (address) {
        return _internalMod._contract_token();
    }
    
    function _contract_miner () public view returns (address) {
        return _internalMod._contract_miner();
    }
}

interface ICaelumMasternode {
    function _externalArrangeFlow() external;
    function rewardsProofOfWork() external returns (uint) ;
    function rewardsMasternode() external returns (uint) ;
    function masternodeIDcounter() external returns (uint) ;
    function masternodeCandidate() external returns (uint) ;
    function getUserFromID(uint) external view returns  (address) ;
    function contractProgress() external view returns (uint, uint, uint, uint, uint, uint, uint, uint);
}

interface ICaelumToken {
    function rewardExternal(address, uint) external;
    function balanceOf(address) external view returns (uint);
}

interface EIP918Interface  {

     
  	function mint(uint256 nonce, bytes32 challenge_digest) external returns (bool success);


	 
    function getChallengeNumber() external view returns (bytes32);

     
    function getMiningDifficulty() external view returns (uint);

     
    function getMiningTarget() external view returns (uint);

     
    function getMiningReward() external view returns (uint);

     
    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);

}

contract AbstractERC918 is EIP918Interface {

     
    bytes32 public challengeNumber;

     
    uint public difficulty;

     
    uint public tokensMinted;

     
    struct Statistics {
        address lastRewardTo;
        uint lastRewardAmount;
        uint lastRewardEthBlockNumber;
        uint lastRewardTimestamp;
    }

    Statistics public statistics;

     
    function mint(uint256 nonce, bytes32 challenge_digest) public returns (bool success);


     
    function _hash(uint256 nonce, bytes32 challenge_digest) internal returns (bytes32 digest);

     
    function _reward() internal returns (uint);

     
    function _newEpoch(uint256 nonce) internal returns (uint);

     
    function _adjustDifficulty() internal returns (uint);

}

contract CaelumAbstractMiner is InterfaceContracts, AbstractERC918 {
     

    using SafeMath for uint;
    using ExtendedMath for uint;

    uint256 public totalSupply = 2100000000000000;

    uint public latestDifficultyPeriodStarted;
    uint public epochCount;
    uint public baseMiningReward = 50;
    uint public blocksPerReadjustment = 512;
    uint public _MINIMUM_TARGET = 2 ** 16;
    uint public _MAXIMUM_TARGET = 2 ** 234;
    uint public rewardEra = 0;

    uint public maxSupplyForEra;
    uint public MAX_REWARD_ERA = 39;
    uint public MINING_RATE_FACTOR = 60;  

    uint public MAX_ADJUSTMENT_PERCENT = 100;
    uint public TARGET_DIVISOR = 2000;
    uint public QUOTIENT_LIMIT = TARGET_DIVISOR.div(2);
    mapping(bytes32 => bytes32) solutionForChallenge;
    mapping(address => mapping(address => uint)) allowed;

    bytes32 public challengeNumber;
    uint public difficulty;
    uint public tokensMinted;

    Statistics public statistics;

    event Mint(address indexed from, uint reward_amount, uint epochCount, bytes32 newChallengeNumber);
    event RewardMasternode(address candidate, uint amount);

    constructor() public {
        tokensMinted = 0;
        maxSupplyForEra = totalSupply.div(2);
        difficulty = _MAXIMUM_TARGET;
        latestDifficultyPeriodStarted = block.number;
        _newEpoch(0);
    }

    function _newEpoch(uint256 nonce) internal returns(uint) {
        if (tokensMinted.add(getMiningReward()) > maxSupplyForEra && rewardEra < MAX_REWARD_ERA) {
            rewardEra = rewardEra + 1;
        }
        maxSupplyForEra = totalSupply - totalSupply.div(2 ** (rewardEra + 1));
        epochCount = epochCount.add(1);
        challengeNumber = blockhash(block.number - 1);
        return (epochCount);
    }

    function mint(uint256 nonce, bytes32 challenge_digest) public returns(bool success);

    function _hash(uint256 nonce, bytes32 challenge_digest) internal returns(bytes32 digest) {
        digest = keccak256(challengeNumber, msg.sender, nonce);
        if (digest != challenge_digest) revert();
        if (uint256(digest) > difficulty) revert();
        bytes32 solution = solutionForChallenge[challengeNumber];
        solutionForChallenge[challengeNumber] = digest;
        if (solution != 0x0) revert();  
    }

    function _reward() internal returns(uint);

    function _reward_masternode() internal returns(uint);

    function _adjustDifficulty() internal returns(uint) {
         
        if (epochCount % blocksPerReadjustment != 0) {
            return difficulty;
        }

        uint ethBlocksSinceLastDifficultyPeriod = block.number - latestDifficultyPeriodStarted;
         
         
        uint epochsMined = blocksPerReadjustment;
        uint targetEthBlocksPerDiffPeriod = epochsMined * MINING_RATE_FACTOR;
         
        if (ethBlocksSinceLastDifficultyPeriod < targetEthBlocksPerDiffPeriod) {
            uint excess_block_pct = (targetEthBlocksPerDiffPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div(ethBlocksSinceLastDifficultyPeriod);
            uint excess_block_pct_extra = excess_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT);
             
             
            difficulty = difficulty.sub(difficulty.div(TARGET_DIVISOR).mul(excess_block_pct_extra));  
        } else {
            uint shortage_block_pct = (ethBlocksSinceLastDifficultyPeriod.mul(MAX_ADJUSTMENT_PERCENT)).div(targetEthBlocksPerDiffPeriod);
            uint shortage_block_pct_extra = shortage_block_pct.sub(100).limitLessThan(QUOTIENT_LIMIT);  
             
            difficulty = difficulty.add(difficulty.div(TARGET_DIVISOR).mul(shortage_block_pct_extra));  
        }
        latestDifficultyPeriodStarted = block.number;
        if (difficulty < _MINIMUM_TARGET)  
        {
            difficulty = _MINIMUM_TARGET;
        }
        if (difficulty > _MAXIMUM_TARGET)  
        {
            difficulty = _MAXIMUM_TARGET;
        }
    }

    function getChallengeNumber() public view returns(bytes32) {
        return challengeNumber;
    }

    function getMiningDifficulty() public view returns(uint) {
        return _MAXIMUM_TARGET.div(difficulty);
    }

    function getMiningTarget() public view returns(uint) {
        return difficulty;
    }

    function getMiningReward() public view returns(uint) {
        return (baseMiningReward * 1e8).div(2 ** rewardEra);
    }

    function getMintDigest(
        uint256 nonce,
        bytes32 challenge_digest,
        bytes32 challenge_number
    )
    public view returns(bytes32 digesttest) {
        bytes32 digest = keccak256(challenge_number, msg.sender, nonce);
        return digest;
    }

    function checkMintSolution(
        uint256 nonce,
        bytes32 challenge_digest,
        bytes32 challenge_number,
        uint testTarget
    )
    public view returns(bool success) {
        bytes32 digest = keccak256(challenge_number, msg.sender, nonce);
        if (uint256(digest) > testTarget) revert();
        return (digest == challenge_digest);
    }
}

contract CaelumMiner is CaelumAbstractMiner {

    ICaelumToken public tokenInterface;
    ICaelumMasternode public masternodeInterface;
    bool public ACTIVE_STATE = false;
    uint swapStartedBlock = now;
    uint public gasPriceLimit = 999;

     

    modifier checkGasPrice(uint txnGasPrice) {
        require(txnGasPrice <= gasPriceLimit * 1000000000, "Gas above gwei limit!");
        _;
    }

    event GasPriceSet(uint8 _gasPrice);

    function setGasPriceLimit(uint8 _gasPrice) onlyOwner public {
        require(_gasPrice > 0);
        gasPriceLimit = _gasPrice;

        emit GasPriceSet(_gasPrice);  
    }

    function setTokenContract() internal {
        tokenInterface = ICaelumToken(_contract_token());
    }

    function setMasternodeContract() internal {
        masternodeInterface = ICaelumMasternode(_contract_masternode());
    }

     
    function setModifierContract (address _contract) onlyOwner public {
        require (now <= swapStartedBlock + 10 days);
        _internalMod = InterfaceContracts(_contract);
        setMasternodeContract();
        setTokenContract();
    }

     
    function VoteModifierContract (address _contract) onlyVotingContract external {
         
        _internalMod = InterfaceContracts(_contract);
        setMasternodeContract();
        setTokenContract();
    }

    function mint(uint256 nonce, bytes32 challenge_digest) checkGasPrice(tx.gasprice) public returns(bool success) {
        require(ACTIVE_STATE);

        _hash(nonce, challenge_digest);

        masternodeInterface._externalArrangeFlow();

        uint rewardAmount = _reward();
        uint rewardMasternode = _reward_masternode();

        tokensMinted += rewardAmount.add(rewardMasternode);

        uint epochCounter = _newEpoch(nonce);

        _adjustDifficulty();

        statistics = Statistics(msg.sender, rewardAmount, block.number, now);

        emit Mint(msg.sender, rewardAmount, epochCounter, challengeNumber);

        return true;
    }

    function _reward() internal returns(uint) {

        uint _pow = masternodeInterface.rewardsProofOfWork();

        tokenInterface.rewardExternal(msg.sender, _pow);

        return _pow;
    }

    function _reward_masternode() internal returns(uint) {

        uint _mnReward = masternodeInterface.rewardsMasternode();
        if (masternodeInterface.masternodeIDcounter() == 0) return 0;

        address _mnCandidate = masternodeInterface.getUserFromID(masternodeInterface.masternodeCandidate());  
        if (_mnCandidate == 0x0) return 0;

        tokenInterface.rewardExternal(_mnCandidate, _mnReward);

        emit RewardMasternode(_mnCandidate, _mnReward);

        return _mnReward;
    }

     
    function getMiningRewardForPool() public view returns(uint) {
        return masternodeInterface.rewardsProofOfWork();
    }

    function getMiningReward() public view returns(uint) {
        return (baseMiningReward * 1e8).div(2 ** rewardEra);
    }

    function contractProgress() public view returns
        (
            uint epoch,
            uint candidate,
            uint round,
            uint miningepoch,
            uint globalreward,
            uint powreward,
            uint masternodereward,
            uint usercounter
        ) {
            return ICaelumMasternode(_contract_masternode()).contractProgress();

        }

     

    function getDataFromContract(address _previous_contract) onlyOwner public {
        require(ACTIVE_STATE == false);
        require(_contract_token() != 0);
        require(_contract_masternode() != 0);

        CaelumAbstractMiner prev = CaelumAbstractMiner(_previous_contract);
        difficulty = prev.difficulty();
        rewardEra = prev.rewardEra();
        MINING_RATE_FACTOR = prev.MINING_RATE_FACTOR();
        maxSupplyForEra = prev.maxSupplyForEra();
        tokensMinted = prev.tokensMinted();
        epochCount = prev.epochCount();

        ACTIVE_STATE = true;
    }
    
    function balanceOf(address _owner) public view returns(uint256) {
        return tokenInterface.balanceOf(_owner);
    }
}