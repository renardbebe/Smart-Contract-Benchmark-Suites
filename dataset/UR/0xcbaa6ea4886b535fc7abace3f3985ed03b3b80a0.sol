 

pragma solidity 0.4.18;

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

     
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

 
library Math {
    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}

 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
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

library MathUtils {
    using SafeMath for uint256;

     
    uint256 public constant PERC_DIVISOR = 1000000;

     
    function validPerc(uint256 _amount) internal pure returns (bool) {
        return _amount <= PERC_DIVISOR;
    }

     
    function percOf(uint256 _amount, uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _amount.mul(percPoints(_fracNum, _fracDenom)).div(PERC_DIVISOR);
    }

     
    function percOf(uint256 _amount, uint256 _fracNum) internal pure returns (uint256) {
        return _amount.mul(_fracNum).div(PERC_DIVISOR);
    }

     
    function percPoints(uint256 _fracNum, uint256 _fracDenom) internal pure returns (uint256) {
        return _fracNum.mul(PERC_DIVISOR).div(_fracDenom);
    }
}

contract IController is Pausable {
    event SetContractInfo(bytes32 id, address contractAddress, bytes20 gitCommitHash);

    function setContractInfo(bytes32 _id, address _contractAddress, bytes20 _gitCommitHash) external;
    function updateController(bytes32 _id, address _controller) external;
    function getContract(bytes32 _id) public view returns (address);
}

contract IManager {
    event SetController(address controller);
    event ParameterUpdate(string param);

    function setController(address _controller) external;
}

contract Manager is IManager {
     
    IController public controller;

     
    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

     
    modifier onlyControllerOwner() {
        require(msg.sender == controller.owner());
        _;
    }

     
    modifier whenSystemNotPaused() {
        require(!controller.paused());
        _;
    }

     
    modifier whenSystemPaused() {
        require(controller.paused());
        _;
    }

    function Manager(address _controller) public {
        controller = IController(_controller);
    }

     
    function setController(address _controller) external onlyController {
        controller = IController(_controller);

        SetController(_controller);
    }
}

 
contract ManagerProxyTarget is Manager {
     
    bytes32 public targetContractId;
}

 
library SortedDoublyLL {
    using SafeMath for uint256;

     
    struct Node {
        uint256 key;                      
        address nextId;                   
        address prevId;                   
    }

     
    struct Data {
        address head;                         
        address tail;                         
        uint256 maxSize;                      
        uint256 size;                         
        mapping (address => Node) nodes;      
    }

     
    function setMaxSize(Data storage self, uint256 _size) public {
         
        require(_size > self.maxSize);

        self.maxSize = _size;
    }

     
    function insert(Data storage self, address _id, uint256 _key, address _prevId, address _nextId) public {
         
        require(!isFull(self));
         
        require(!contains(self, _id));
         
        require(_id != address(0));
         
        require(_key > 0);

        address prevId = _prevId;
        address nextId = _nextId;

        if (!validInsertPosition(self, _key, prevId, nextId)) {
             
             
            (prevId, nextId) = findInsertPosition(self, _key, prevId, nextId);
        }

        self.nodes[_id].key = _key;

        if (prevId == address(0) && nextId == address(0)) {
             
            self.head = _id;
            self.tail = _id;
        } else if (prevId == address(0)) {
             
            self.nodes[_id].nextId = self.head;
            self.nodes[self.head].prevId = _id;
            self.head = _id;
        } else if (nextId == address(0)) {
             
            self.nodes[_id].prevId = self.tail;
            self.nodes[self.tail].nextId = _id;
            self.tail = _id;
        } else {
             
            self.nodes[_id].nextId = nextId;
            self.nodes[_id].prevId = prevId;
            self.nodes[prevId].nextId = _id;
            self.nodes[nextId].prevId = _id;
        }

        self.size = self.size.add(1);
    }

     
    function remove(Data storage self, address _id) public {
         
        require(contains(self, _id));

        if (self.size > 1) {
             
            if (_id == self.head) {
                 
                 
                self.head = self.nodes[_id].nextId;
                 
                self.nodes[self.head].prevId = address(0);
            } else if (_id == self.tail) {
                 
                 
                self.tail = self.nodes[_id].prevId;
                 
                self.nodes[self.tail].nextId = address(0);
            } else {
                 
                 
                self.nodes[self.nodes[_id].prevId].nextId = self.nodes[_id].nextId;
                 
                self.nodes[self.nodes[_id].nextId].prevId = self.nodes[_id].prevId;
            }
        } else {
             
             
            self.head = address(0);
            self.tail = address(0);
        }

        delete self.nodes[_id];
        self.size = self.size.sub(1);
    }

     
    function updateKey(Data storage self, address _id, uint256 _newKey, address _prevId, address _nextId) public {
         
        require(contains(self, _id));

         
        remove(self, _id);

        if (_newKey > 0) {
             
            insert(self, _id, _newKey, _prevId, _nextId);
        }
    }

     
    function contains(Data storage self, address _id) public view returns (bool) {
         
        return self.nodes[_id].key > 0;
    }

     
    function isFull(Data storage self) public view returns (bool) {
        return self.size == self.maxSize;
    }

     
    function isEmpty(Data storage self) public view returns (bool) {
        return self.size == 0;
    }

     
    function getSize(Data storage self) public view returns (uint256) {
        return self.size;
    }

     
    function getMaxSize(Data storage self) public view returns (uint256) {
        return self.maxSize;
    }

     
    function getKey(Data storage self, address _id) public view returns (uint256) {
        return self.nodes[_id].key;
    }

     
    function getFirst(Data storage self) public view returns (address) {
        return self.head;
    }

     
    function getLast(Data storage self) public view returns (address) {
        return self.tail;
    }

     
    function getNext(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].nextId;
    }

     
    function getPrev(Data storage self, address _id) public view returns (address) {
        return self.nodes[_id].prevId;
    }

     
    function validInsertPosition(Data storage self, uint256 _key, address _prevId, address _nextId) public view returns (bool) {
        if (_prevId == address(0) && _nextId == address(0)) {
             
            return isEmpty(self);
        } else if (_prevId == address(0)) {
             
            return self.head == _nextId && _key >= self.nodes[_nextId].key;
        } else if (_nextId == address(0)) {
             
            return self.tail == _prevId && _key <= self.nodes[_prevId].key;
        } else {
             
            return self.nodes[_prevId].nextId == _nextId && self.nodes[_prevId].key >= _key && _key >= self.nodes[_nextId].key;
        }
    }

     
    function descendList(Data storage self, uint256 _key, address _startId) private view returns (address, address) {
         
        if (self.head == _startId && _key >= self.nodes[_startId].key) {
            return (address(0), _startId);
        }

        address prevId = _startId;
        address nextId = self.nodes[prevId].nextId;

         
        while (prevId != address(0) && !validInsertPosition(self, _key, prevId, nextId)) {
            prevId = self.nodes[prevId].nextId;
            nextId = self.nodes[prevId].nextId;
        }

        return (prevId, nextId);
    }

     
    function ascendList(Data storage self, uint256 _key, address _startId) private view returns (address, address) {
         
        if (self.tail == _startId && _key <= self.nodes[_startId].key) {
            return (_startId, address(0));
        }

        address nextId = _startId;
        address prevId = self.nodes[nextId].prevId;

         
        while (nextId != address(0) && !validInsertPosition(self, _key, prevId, nextId)) {
            nextId = self.nodes[nextId].prevId;
            prevId = self.nodes[nextId].prevId;
        }

        return (prevId, nextId);
    }

     
    function findInsertPosition(Data storage self, uint256 _key, address _prevId, address _nextId) private view returns (address, address) {
        address prevId = _prevId;
        address nextId = _nextId;

        if (prevId != address(0)) {
            if (!contains(self, prevId) || _key > self.nodes[prevId].key) {
                 
                prevId = address(0);
            }
        }

        if (nextId != address(0)) {
            if (!contains(self, nextId) || _key < self.nodes[nextId].key) {
                 
                nextId = address(0);
            }
        }

        if (prevId == address(0) && nextId == address(0)) {
             
            return descendList(self, _key, self.head);
        } else if (prevId == address(0)) {
             
            return ascendList(self, _key, nextId);
        } else if (nextId == address(0)) {
             
            return descendList(self, _key, prevId);
        } else {
             
            return descendList(self, _key, prevId);
        }
    }
}

 
library EarningsPool {
    using SafeMath for uint256;

     
     
     
     
     
    struct Data {
        uint256 rewardPool;                 
        uint256 feePool;                    
        uint256 totalStake;                 
        uint256 claimableStake;             
        uint256 transcoderRewardCut;        
        uint256 transcoderFeeShare;         
        uint256 transcoderRewardPool;       
        uint256 transcoderFeePool;          
        bool hasTranscoderRewardFeePool;    
    }

     
    function init(EarningsPool.Data storage earningsPool, uint256 _stake, uint256 _rewardCut, uint256 _feeShare) internal {
        earningsPool.totalStake = _stake;
        earningsPool.claimableStake = _stake;
        earningsPool.transcoderRewardCut = _rewardCut;
        earningsPool.transcoderFeeShare = _feeShare;
         
         
         
        earningsPool.hasTranscoderRewardFeePool = true;
    }

     
    function hasClaimableShares(EarningsPool.Data storage earningsPool) internal view returns (bool) {
        return earningsPool.claimableStake > 0;
    }

     
    function addToFeePool(EarningsPool.Data storage earningsPool, uint256 _fees) internal {
        if (earningsPool.hasTranscoderRewardFeePool) {
             
             
            uint256 delegatorFees = MathUtils.percOf(_fees, earningsPool.transcoderFeeShare);
            earningsPool.feePool = earningsPool.feePool.add(delegatorFees);
            earningsPool.transcoderFeePool = earningsPool.transcoderFeePool.add(_fees.sub(delegatorFees));
        } else {
             
            earningsPool.feePool = earningsPool.feePool.add(_fees);
        }
    }

     
    function addToRewardPool(EarningsPool.Data storage earningsPool, uint256 _rewards) internal {
        if (earningsPool.hasTranscoderRewardFeePool) {
             
             
            uint256 transcoderRewards = MathUtils.percOf(_rewards, earningsPool.transcoderRewardCut);
            earningsPool.rewardPool = earningsPool.rewardPool.add(_rewards.sub(transcoderRewards));
            earningsPool.transcoderRewardPool = earningsPool.transcoderRewardPool.add(transcoderRewards);
        } else {
             
            earningsPool.rewardPool = earningsPool.rewardPool.add(_rewards);
        }
    }

     
    function claimShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal returns (uint256, uint256) {
        uint256 totalFees = 0;
        uint256 totalRewards = 0;
        uint256 delegatorFees = 0;
        uint256 transcoderFees = 0;
        uint256 delegatorRewards = 0;
        uint256 transcoderRewards = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
             
             
            (delegatorFees, transcoderFees) = feePoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
            totalFees = delegatorFees.add(transcoderFees);
             
            (delegatorRewards, transcoderRewards) = rewardPoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
            totalRewards = delegatorRewards.add(transcoderRewards);

             
            earningsPool.feePool = earningsPool.feePool.sub(delegatorFees);
             
            earningsPool.rewardPool = earningsPool.rewardPool.sub(delegatorRewards);

            if (_isTranscoder) {
                 
                 
                earningsPool.transcoderFeePool = 0;
                 
                earningsPool.transcoderRewardPool = 0;
            }
        } else {
             
             
            (delegatorFees, transcoderFees) = feePoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
            totalFees = delegatorFees.add(transcoderFees);
             
            (delegatorRewards, transcoderRewards) = rewardPoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
            totalRewards = delegatorRewards.add(transcoderRewards);

             
            earningsPool.feePool = earningsPool.feePool.sub(totalFees);
             
            earningsPool.rewardPool = earningsPool.rewardPool.sub(totalRewards);
        }

         
        earningsPool.claimableStake = earningsPool.claimableStake.sub(_stake);

        return (totalFees, totalRewards);
    }

     
    function feePoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 delegatorFees = 0;
        uint256 transcoderFees = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
            (delegatorFees, transcoderFees) = feePoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        } else {
            (delegatorFees, transcoderFees) = feePoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        }

        return delegatorFees.add(transcoderFees);
    }

     
    function rewardPoolShare(EarningsPool.Data storage earningsPool, uint256 _stake, bool _isTranscoder) internal view returns (uint256) {
        uint256 delegatorRewards = 0;
        uint256 transcoderRewards = 0;

        if (earningsPool.hasTranscoderRewardFeePool) {
            (delegatorRewards, transcoderRewards) = rewardPoolShareWithTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        } else {
            (delegatorRewards, transcoderRewards) = rewardPoolShareNoTranscoderRewardFeePool(earningsPool, _stake, _isTranscoder);
        }

        return delegatorRewards.add(transcoderRewards);
    }

     
    function feePoolShareWithTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    ) 
        internal
        view
        returns (uint256, uint256)
    {
         
         
        uint256 delegatorFees = earningsPool.claimableStake > 0 ? MathUtils.percOf(earningsPool.feePool, _stake, earningsPool.claimableStake) : 0;

         
        return _isTranscoder ? (delegatorFees, earningsPool.transcoderFeePool) : (delegatorFees, 0);
    }

     
    function rewardPoolShareWithTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
         
         
        uint256 delegatorRewards = earningsPool.claimableStake > 0 ? MathUtils.percOf(earningsPool.rewardPool, _stake, earningsPool.claimableStake) : 0;

         
        return _isTranscoder ? (delegatorRewards, earningsPool.transcoderRewardPool) : (delegatorRewards, 0);
    }
   
     
    function feePoolShareNoTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    ) 
        internal
        view
        returns (uint256, uint256)
    {
        uint256 transcoderFees = 0;
        uint256 delegatorFees = 0;

        if (earningsPool.claimableStake > 0) {
            uint256 delegatorsFees = MathUtils.percOf(earningsPool.feePool, earningsPool.transcoderFeeShare);
            transcoderFees = earningsPool.feePool.sub(delegatorsFees);
            delegatorFees = MathUtils.percOf(delegatorsFees, _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return (delegatorFees, transcoderFees);
        } else {
            return (delegatorFees, 0);
        }
    }

     
    function rewardPoolShareNoTranscoderRewardFeePool(
        EarningsPool.Data storage earningsPool,
        uint256 _stake,
        bool _isTranscoder
    )
        internal
        view
        returns (uint256, uint256)
    {
        uint256 transcoderRewards = 0;
        uint256 delegatorRewards = 0;

        if (earningsPool.claimableStake > 0) {
            transcoderRewards = MathUtils.percOf(earningsPool.rewardPool, earningsPool.transcoderRewardCut);
            delegatorRewards = MathUtils.percOf(earningsPool.rewardPool.sub(transcoderRewards), _stake, earningsPool.claimableStake);
        }

        if (_isTranscoder) {
            return (delegatorRewards, transcoderRewards);
        } else {
            return (delegatorRewards, 0);
        }
    }
}

contract ILivepeerToken is ERC20, Ownable {
    function mint(address _to, uint256 _amount) public returns (bool);
    function burn(uint256 _amount) public;
}

 
contract IMinter {
     
    event SetCurrentRewardTokens(uint256 currentMintableTokens, uint256 currentInflation);

     
    function createReward(uint256 _fracNum, uint256 _fracDenom) external returns (uint256);
    function trustedTransferTokens(address _to, uint256 _amount) external;
    function trustedBurnTokens(uint256 _amount) external;
    function trustedWithdrawETH(address _to, uint256 _amount) external;
    function depositETH() external payable returns (bool);
    function setCurrentRewardTokens() external;

     
    function getController() public view returns (IController);
}

 
contract IRoundsManager {
     
    event NewRound(uint256 round);

     
    function initializeRound() external;

     
    function blockNum() public view returns (uint256);
    function blockHash(uint256 _block) public view returns (bytes32);
    function currentRound() public view returns (uint256);
    function currentRoundStartBlock() public view returns (uint256);
    function currentRoundInitialized() public view returns (bool);
    function currentRoundLocked() public view returns (bool);
}

 
contract IBondingManager {
    event TranscoderUpdate(address indexed transcoder, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment, bool registered);
    event TranscoderEvicted(address indexed transcoder);
    event TranscoderResigned(address indexed transcoder);
    event TranscoderSlashed(address indexed transcoder, address finder, uint256 penalty, uint256 finderReward);
    event Reward(address indexed transcoder, uint256 amount);
    event Bond(address indexed newDelegate, address indexed oldDelegate, address indexed delegator, uint256 additionalAmount, uint256 bondedAmount);
    event Unbond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event Rebond(address indexed delegate, address indexed delegator, uint256 unbondingLockId, uint256 amount);
    event WithdrawStake(address indexed delegator, uint256 unbondingLockId, uint256 amount, uint256 withdrawRound);
    event WithdrawFees(address indexed delegator);

     
    function setActiveTranscoders() external;
    function updateTranscoderWithFees(address _transcoder, uint256 _fees, uint256 _round) external;
    function slashTranscoder(address _transcoder, address _finder, uint256 _slashAmount, uint256 _finderFee) external;
    function electActiveTranscoder(uint256 _maxPricePerSegment, bytes32 _blockHash, uint256 _round) external view returns (address);

     
    function transcoderTotalStake(address _transcoder) public view returns (uint256);
    function activeTranscoderTotalStake(address _transcoder, uint256 _round) public view returns (uint256);
    function isRegisteredTranscoder(address _transcoder) public view returns (bool);
    function getTotalBonded() public view returns (uint256);
}

 
contract BondingManager is ManagerProxyTarget, IBondingManager {
    using SafeMath for uint256;
    using SortedDoublyLL for SortedDoublyLL.Data;
    using EarningsPool for EarningsPool.Data;

     
    uint64 public unbondingPeriod;
     
    uint256 public numActiveTranscoders;
     
    uint256 public maxEarningsClaimsRounds;

     
    struct Transcoder {
        uint256 lastRewardRound;                              
        uint256 rewardCut;                                    
        uint256 feeShare;                                     
        uint256 pricePerSegment;                              
        uint256 pendingRewardCut;                             
        uint256 pendingFeeShare;                              
        uint256 pendingPricePerSegment;                       
        mapping (uint256 => EarningsPool.Data) earningsPoolPerRound;   
    }

     
    enum TranscoderStatus { NotRegistered, Registered }

     
    struct Delegator {
        uint256 bondedAmount;                     
        uint256 fees;                             
        address delegateAddress;                  
        uint256 delegatedAmount;                  
        uint256 startRound;                       
        uint256 withdrawRoundDEPRECATED;          
        uint256 lastClaimRound;                   
        uint256 nextUnbondingLockId;              
        mapping (uint256 => UnbondingLock) unbondingLocks;  
    }

     
    enum DelegatorStatus { Pending, Bonded, Unbonded }

     
    struct UnbondingLock {
        uint256 amount;               
        uint256 withdrawRound;        
    }

     
    mapping (address => Delegator) private delegators;
    mapping (address => Transcoder) private transcoders;

     
     
     
    uint256 private totalBondedDEPRECATED;

     
    SortedDoublyLL.Data private transcoderPool;

     
    struct ActiveTranscoderSet {
        address[] transcoders;
        mapping (address => bool) isActive;
        uint256 totalStake;
    }

     
    mapping (uint256 => ActiveTranscoderSet) public activeTranscoderSet;

     
    modifier onlyJobsManager() {
        require(msg.sender == controller.getContract(keccak256("JobsManager")));
        _;
    }

     
    modifier onlyRoundsManager() {
        require(msg.sender == controller.getContract(keccak256("RoundsManager")));
        _;
    }

     
    modifier currentRoundInitialized() {
        require(roundsManager().currentRoundInitialized());
        _;
    }

     
    modifier autoClaimEarnings() {
        updateDelegatorWithEarnings(msg.sender, roundsManager().currentRound());
        _;
    }

     
    function BondingManager(address _controller) public Manager(_controller) {}

     
    function setUnbondingPeriod(uint64 _unbondingPeriod) external onlyControllerOwner {
        unbondingPeriod = _unbondingPeriod;

        ParameterUpdate("unbondingPeriod");
    }

     
    function setNumTranscoders(uint256 _numTranscoders) external onlyControllerOwner {
         
        require(_numTranscoders >= numActiveTranscoders);

        transcoderPool.setMaxSize(_numTranscoders);

        ParameterUpdate("numTranscoders");
    }

     
    function setNumActiveTranscoders(uint256 _numActiveTranscoders) external onlyControllerOwner {
         
        require(_numActiveTranscoders <= transcoderPool.getMaxSize());

        numActiveTranscoders = _numActiveTranscoders;

        ParameterUpdate("numActiveTranscoders");
    }

     
    function setMaxEarningsClaimsRounds(uint256 _maxEarningsClaimsRounds) external onlyControllerOwner {
        maxEarningsClaimsRounds = _maxEarningsClaimsRounds;

        ParameterUpdate("maxEarningsClaimsRounds");
    }

     
    function transcoder(uint256 _rewardCut, uint256 _feeShare, uint256 _pricePerSegment)
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Transcoder storage t = transcoders[msg.sender];
        Delegator storage del = delegators[msg.sender];

        if (roundsManager().currentRoundLocked()) {
             
             
             
             

             
            require(transcoderStatus(msg.sender) == TranscoderStatus.Registered);
             
             
            require(_rewardCut == t.pendingRewardCut);
             
             
            require(_feeShare == t.pendingFeeShare);

             
             
             
             
            address currentTranscoder = transcoderPool.getFirst();
            uint256 priceFloor = transcoders[currentTranscoder].pendingPricePerSegment;
            for (uint256 i = 0; i < transcoderPool.getSize(); i++) {
                if (transcoders[currentTranscoder].pendingPricePerSegment < priceFloor) {
                    priceFloor = transcoders[currentTranscoder].pendingPricePerSegment;
                }

                currentTranscoder = transcoderPool.getNext(currentTranscoder);
            }

             
             
            require(_pricePerSegment >= priceFloor && _pricePerSegment <= t.pendingPricePerSegment);

            t.pendingPricePerSegment = _pricePerSegment;

            TranscoderUpdate(msg.sender, t.pendingRewardCut, t.pendingFeeShare, _pricePerSegment, true);
        } else {
             
             
             
             
             
             
             
             

             
            require(MathUtils.validPerc(_rewardCut));
             
            require(MathUtils.validPerc(_feeShare));

             
            require(del.delegateAddress == msg.sender && del.bondedAmount > 0);

            t.pendingRewardCut = _rewardCut;
            t.pendingFeeShare = _feeShare;
            t.pendingPricePerSegment = _pricePerSegment;

            uint256 delegatedAmount = del.delegatedAmount;

             
            if (transcoderStatus(msg.sender) == TranscoderStatus.NotRegistered) {
                if (!transcoderPool.isFull()) {
                     
                    transcoderPool.insert(msg.sender, delegatedAmount, address(0), address(0));
                } else {
                    address lastTranscoder = transcoderPool.getLast();

                    if (delegatedAmount > transcoderTotalStake(lastTranscoder)) {
                         
                         
                         
                        transcoderPool.remove(lastTranscoder);
                        transcoderPool.insert(msg.sender, delegatedAmount, address(0), address(0));

                        TranscoderEvicted(lastTranscoder);
                    }
                }
            }

            TranscoderUpdate(msg.sender, _rewardCut, _feeShare, _pricePerSegment, transcoderPool.contains(msg.sender));
        }
    }

     
    function bond(
        uint256 _amount,
        address _to
    )
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
        Delegator storage del = delegators[msg.sender];

        uint256 currentRound = roundsManager().currentRound();
         
        uint256 delegationAmount = _amount;
         
        address currentDelegate = del.delegateAddress;

        if (delegatorStatus(msg.sender) == DelegatorStatus.Unbonded) {
             
             
             
            del.startRound = currentRound.add(1);
             
             
        } else if (del.delegateAddress != address(0) && _to != del.delegateAddress) {
             
             
             
             
             
            require(transcoderStatus(msg.sender) == TranscoderStatus.NotRegistered);
             
             
            del.startRound = currentRound.add(1);
             
            delegationAmount = delegationAmount.add(del.bondedAmount);
             
            delegators[currentDelegate].delegatedAmount = delegators[currentDelegate].delegatedAmount.sub(del.bondedAmount);

            if (transcoderStatus(currentDelegate) == TranscoderStatus.Registered) {
                 
                 
                transcoderPool.updateKey(currentDelegate, transcoderTotalStake(currentDelegate).sub(del.bondedAmount), address(0), address(0));
            }
        }

         
        require(delegationAmount > 0);
         
        del.delegateAddress = _to;
         
        delegators[_to].delegatedAmount = delegators[_to].delegatedAmount.add(delegationAmount);

        if (transcoderStatus(_to) == TranscoderStatus.Registered) {
             
             
            transcoderPool.updateKey(_to, transcoderTotalStake(del.delegateAddress).add(delegationAmount), address(0), address(0));
        }

        if (_amount > 0) {
             
            del.bondedAmount = del.bondedAmount.add(_amount);
             
            livepeerToken().transferFrom(msg.sender, minter(), _amount);
        }

        Bond(_to, currentDelegate, msg.sender, _amount, del.bondedAmount);
    }

     
    function unbond(uint256 _amount)
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
         
        require(delegatorStatus(msg.sender) == DelegatorStatus.Bonded);

        Delegator storage del = delegators[msg.sender];

         
        require(_amount > 0);
         
        require(_amount <= del.bondedAmount);

        address currentDelegate = del.delegateAddress;
        uint256 currentRound = roundsManager().currentRound();
        uint256 withdrawRound = currentRound.add(unbondingPeriod);
        uint256 unbondingLockId = del.nextUnbondingLockId;

         
        del.unbondingLocks[unbondingLockId] = UnbondingLock({
            amount: _amount,
            withdrawRound: withdrawRound
        });
         
        del.nextUnbondingLockId = unbondingLockId.add(1);
         
        del.bondedAmount = del.bondedAmount.sub(_amount);
         
        delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(_amount);

        if (transcoderStatus(del.delegateAddress) == TranscoderStatus.Registered && (del.delegateAddress != msg.sender || del.bondedAmount > 0)) {
             
             
             
             
             
            transcoderPool.updateKey(del.delegateAddress, transcoderTotalStake(del.delegateAddress).sub(_amount), address(0), address(0));
        }

         
         
        if (del.bondedAmount == 0) {
             
            del.delegateAddress = address(0);
             
            del.startRound = 0;

            if (transcoderStatus(msg.sender) == TranscoderStatus.Registered) {
                 
                resignTranscoder(msg.sender);
            }
        } 

        Unbond(currentDelegate, msg.sender, unbondingLockId, _amount, withdrawRound);
    }

     
    function rebond(
        uint256 _unbondingLockId
    ) 
        external
        whenSystemNotPaused
        currentRoundInitialized 
        autoClaimEarnings
    {
         
        require(delegatorStatus(msg.sender) != DelegatorStatus.Unbonded);

         
        processRebond(msg.sender, _unbondingLockId);
    }

     
    function rebondFromUnbonded(
        address _to,
        uint256 _unbondingLockId
    )
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
         
        require(delegatorStatus(msg.sender) == DelegatorStatus.Unbonded);

         
        delegators[msg.sender].startRound = roundsManager().currentRound().add(1);
         
        delegators[msg.sender].delegateAddress = _to;
         
        processRebond(msg.sender, _unbondingLockId);
    }

     
    function withdrawStake(uint256 _unbondingLockId)
        external
        whenSystemNotPaused
        currentRoundInitialized
    {
        Delegator storage del = delegators[msg.sender];
        UnbondingLock storage lock = del.unbondingLocks[_unbondingLockId];

         
        require(isValidUnbondingLock(msg.sender, _unbondingLockId));
         
        require(lock.withdrawRound <= roundsManager().currentRound());

        uint256 amount = lock.amount;
        uint256 withdrawRound = lock.withdrawRound;
         
        delete del.unbondingLocks[_unbondingLockId];

         
        minter().trustedTransferTokens(msg.sender, amount);

        WithdrawStake(msg.sender, _unbondingLockId, amount, withdrawRound);
    }

     
    function withdrawFees()
        external
        whenSystemNotPaused
        currentRoundInitialized
        autoClaimEarnings
    {
         
        require(delegators[msg.sender].fees > 0);

        uint256 amount = delegators[msg.sender].fees;
        delegators[msg.sender].fees = 0;

         
        minter().trustedWithdrawETH(msg.sender, amount);

        WithdrawFees(msg.sender);
    }

     
    function setActiveTranscoders() external whenSystemNotPaused onlyRoundsManager {
        uint256 currentRound = roundsManager().currentRound();
        uint256 activeSetSize = Math.min256(numActiveTranscoders, transcoderPool.getSize());

        uint256 totalStake = 0;
        address currentTranscoder = transcoderPool.getFirst();

        for (uint256 i = 0; i < activeSetSize; i++) {
            activeTranscoderSet[currentRound].transcoders.push(currentTranscoder);
            activeTranscoderSet[currentRound].isActive[currentTranscoder] = true;

            uint256 stake = transcoderTotalStake(currentTranscoder);
            uint256 rewardCut = transcoders[currentTranscoder].pendingRewardCut;
            uint256 feeShare = transcoders[currentTranscoder].pendingFeeShare;
            uint256 pricePerSegment = transcoders[currentTranscoder].pendingPricePerSegment;

            Transcoder storage t = transcoders[currentTranscoder];
             
            t.rewardCut = rewardCut;
            t.feeShare = feeShare;
            t.pricePerSegment = pricePerSegment;
             
            t.earningsPoolPerRound[currentRound].init(stake, rewardCut, feeShare);

            totalStake = totalStake.add(stake);

             
            currentTranscoder = transcoderPool.getNext(currentTranscoder);
        }

         
        activeTranscoderSet[currentRound].totalStake = totalStake;
    }

     
    function reward() external whenSystemNotPaused currentRoundInitialized {
        uint256 currentRound = roundsManager().currentRound();

         
        require(activeTranscoderSet[currentRound].isActive[msg.sender]);

         
        require(transcoders[msg.sender].lastRewardRound != currentRound);
         
        transcoders[msg.sender].lastRewardRound = currentRound;

         
         
        uint256 rewardTokens = minter().createReward(activeTranscoderTotalStake(msg.sender, currentRound), activeTranscoderSet[currentRound].totalStake);

        updateTranscoderWithRewards(msg.sender, rewardTokens, currentRound);

        Reward(msg.sender, rewardTokens);
    }

     
    function updateTranscoderWithFees(
        address _transcoder,
        uint256 _fees,
        uint256 _round
    )
        external
        whenSystemNotPaused
        onlyJobsManager
    {
         
        require(transcoderStatus(_transcoder) == TranscoderStatus.Registered);

        Transcoder storage t = transcoders[_transcoder];

        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];
         
        earningsPool.addToFeePool(_fees);
    }

     
    function slashTranscoder(
        address _transcoder,
        address _finder,
        uint256 _slashAmount,
        uint256 _finderFee
    )
        external
        whenSystemNotPaused
        onlyJobsManager
    {
        Delegator storage del = delegators[_transcoder];

        if (del.bondedAmount > 0) {
            uint256 penalty = MathUtils.percOf(delegators[_transcoder].bondedAmount, _slashAmount);

             
            del.bondedAmount = del.bondedAmount.sub(penalty);

             
             
             
            if (delegatorStatus(_transcoder) == DelegatorStatus.Bonded) {
                delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.sub(penalty);
            }

             
            if (transcoderStatus(_transcoder) == TranscoderStatus.Registered) {
                resignTranscoder(_transcoder);
            }

             
            uint256 burnAmount = penalty;

             
            if (_finder != address(0)) {
                uint256 finderAmount = MathUtils.percOf(penalty, _finderFee);
                minter().trustedTransferTokens(_finder, finderAmount);

                 
                minter().trustedBurnTokens(burnAmount.sub(finderAmount));

                TranscoderSlashed(_transcoder, _finder, penalty, finderAmount);
            } else {
                 
                minter().trustedBurnTokens(burnAmount);

                TranscoderSlashed(_transcoder, address(0), penalty, 0);
            }
        } else {
            TranscoderSlashed(_transcoder, _finder, 0, 0);
        }
    }

     
    function electActiveTranscoder(uint256 _maxPricePerSegment, bytes32 _blockHash, uint256 _round) external view returns (address) {
        uint256 activeSetSize = activeTranscoderSet[_round].transcoders.length;
         
        address[] memory availableTranscoders = new address[](activeSetSize);
         
        uint256 numAvailableTranscoders = 0;
         
        uint256 totalAvailableTranscoderStake = 0;

        for (uint256 i = 0; i < activeSetSize; i++) {
            address activeTranscoder = activeTranscoderSet[_round].transcoders[i];
             
            if (activeTranscoderSet[_round].isActive[activeTranscoder] && transcoders[activeTranscoder].pricePerSegment <= _maxPricePerSegment) {
                availableTranscoders[numAvailableTranscoders] = activeTranscoder;
                numAvailableTranscoders++;
                totalAvailableTranscoderStake = totalAvailableTranscoderStake.add(activeTranscoderTotalStake(activeTranscoder, _round));
            }
        }

        if (numAvailableTranscoders == 0) {
             
            return address(0);
        } else {
             
            uint256 r = uint256(_blockHash) % totalAvailableTranscoderStake;
            uint256 s = 0;
            uint256 j = 0;

            while (s <= r && j < numAvailableTranscoders) {
                s = s.add(activeTranscoderTotalStake(availableTranscoders[j], _round));
                j++;
            }

            return availableTranscoders[j - 1];
        }
    }

     
    function claimEarnings(uint256 _endRound) external whenSystemNotPaused currentRoundInitialized {
         
        require(delegators[msg.sender].lastClaimRound < _endRound);
         
        require(_endRound <= roundsManager().currentRound());

        updateDelegatorWithEarnings(msg.sender, _endRound);
    }

     
    function pendingStake(address _delegator, uint256 _endRound) public view returns (uint256) {
        uint256 currentRound = roundsManager().currentRound();
        Delegator storage del = delegators[_delegator];
         
        require(_endRound <= currentRound && _endRound > del.lastClaimRound);

        uint256 currentBondedAmount = del.bondedAmount;

        for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
            EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

            bool isTranscoder = _delegator == del.delegateAddress;
            if (earningsPool.hasClaimableShares()) {
                 
                currentBondedAmount = currentBondedAmount.add(earningsPool.rewardPoolShare(currentBondedAmount, isTranscoder));
            }
        }

        return currentBondedAmount;
    }

     
    function pendingFees(address _delegator, uint256 _endRound) public view returns (uint256) {
        uint256 currentRound = roundsManager().currentRound();
        Delegator storage del = delegators[_delegator];
         
        require(_endRound <= currentRound && _endRound > del.lastClaimRound);

        uint256 currentFees = del.fees;
        uint256 currentBondedAmount = del.bondedAmount;

        for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
            EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

            if (earningsPool.hasClaimableShares()) {
                bool isTranscoder = _delegator == del.delegateAddress;
                 
                currentFees = currentFees.add(earningsPool.feePoolShare(currentBondedAmount, isTranscoder));
                 
                 
                currentBondedAmount = currentBondedAmount.add(earningsPool.rewardPoolShare(currentBondedAmount, isTranscoder));
            }
        }

        return currentFees;
    }

     
    function activeTranscoderTotalStake(address _transcoder, uint256 _round) public view returns (uint256) {
         
        require(activeTranscoderSet[_round].isActive[_transcoder]);

        return transcoders[_transcoder].earningsPoolPerRound[_round].totalStake;
    }

     
    function transcoderTotalStake(address _transcoder) public view returns (uint256) {
        return transcoderPool.getKey(_transcoder);
    }

     
    function transcoderStatus(address _transcoder) public view returns (TranscoderStatus) {
        if (transcoderPool.contains(_transcoder)) {
            return TranscoderStatus.Registered;
        } else {
            return TranscoderStatus.NotRegistered;
        }
    }

     
    function delegatorStatus(address _delegator) public view returns (DelegatorStatus) {
        Delegator storage del = delegators[_delegator];

        if (del.bondedAmount == 0) {
             
            return DelegatorStatus.Unbonded;
        } else if (del.startRound > roundsManager().currentRound()) {
             
            return DelegatorStatus.Pending;
        } else if (del.startRound > 0 && del.startRound <= roundsManager().currentRound()) {
             
            return DelegatorStatus.Bonded;
        } else {
             
            return DelegatorStatus.Unbonded;
        }
    }

     
    function getTranscoder(
        address _transcoder
    )
        public
        view
        returns (uint256 lastRewardRound, uint256 rewardCut, uint256 feeShare, uint256 pricePerSegment, uint256 pendingRewardCut, uint256 pendingFeeShare, uint256 pendingPricePerSegment)
    {
        Transcoder storage t = transcoders[_transcoder];

        lastRewardRound = t.lastRewardRound;
        rewardCut = t.rewardCut;
        feeShare = t.feeShare;
        pricePerSegment = t.pricePerSegment;
        pendingRewardCut = t.pendingRewardCut;
        pendingFeeShare = t.pendingFeeShare;
        pendingPricePerSegment = t.pendingPricePerSegment;
    }

     
    function getTranscoderEarningsPoolForRound(
        address _transcoder,
        uint256 _round
    )
        public
        view
        returns (uint256 rewardPool, uint256 feePool, uint256 totalStake, uint256 claimableStake, uint256 transcoderRewardCut, uint256 transcoderFeeShare, uint256 transcoderRewardPool, uint256 transcoderFeePool, bool hasTranscoderRewardFeePool)
    {
        EarningsPool.Data storage earningsPool = transcoders[_transcoder].earningsPoolPerRound[_round];

        rewardPool = earningsPool.rewardPool;
        feePool = earningsPool.feePool;
        totalStake = earningsPool.totalStake;
        claimableStake = earningsPool.claimableStake;
        transcoderRewardCut = earningsPool.transcoderRewardCut;
        transcoderFeeShare = earningsPool.transcoderFeeShare;
        transcoderRewardPool = earningsPool.transcoderRewardPool;
        transcoderFeePool = earningsPool.transcoderFeePool;
        hasTranscoderRewardFeePool = earningsPool.hasTranscoderRewardFeePool;
    }

     
    function getDelegator(
        address _delegator
    )
        public
        view
        returns (uint256 bondedAmount, uint256 fees, address delegateAddress, uint256 delegatedAmount, uint256 startRound, uint256 lastClaimRound, uint256 nextUnbondingLockId)
    {
        Delegator storage del = delegators[_delegator];

        bondedAmount = del.bondedAmount;
        fees = del.fees;
        delegateAddress = del.delegateAddress;
        delegatedAmount = del.delegatedAmount;
        startRound = del.startRound;
        lastClaimRound = del.lastClaimRound;
        nextUnbondingLockId = del.nextUnbondingLockId;
    }

     
    function getDelegatorUnbondingLock(
        address _delegator,
        uint256 _unbondingLockId
    ) 
        public
        view
        returns (uint256 amount, uint256 withdrawRound) 
    {
        UnbondingLock storage lock = delegators[_delegator].unbondingLocks[_unbondingLockId];

        return (lock.amount, lock.withdrawRound);
    }

     
    function getTranscoderPoolMaxSize() public view returns (uint256) {
        return transcoderPool.getMaxSize();
    }

     
    function getTranscoderPoolSize() public view returns (uint256) {
        return transcoderPool.getSize();
    }

     
    function getFirstTranscoderInPool() public view returns (address) {
        return transcoderPool.getFirst();
    }

     
    function getNextTranscoderInPool(address _transcoder) public view returns (address) {
        return transcoderPool.getNext(_transcoder);
    }

     
    function getTotalBonded() public view returns (uint256) {
        uint256 totalBonded = 0;
        uint256 totalTranscoders = transcoderPool.getSize();
        address currentTranscoder = transcoderPool.getFirst();

        for (uint256 i = 0; i < totalTranscoders; i++) {
             
            totalBonded = totalBonded.add(transcoderTotalStake(currentTranscoder));
             
            currentTranscoder = transcoderPool.getNext(currentTranscoder);
        }

        return totalBonded;
    }

     
    function getTotalActiveStake(uint256 _round) public view returns (uint256) {
        return activeTranscoderSet[_round].totalStake;
    }

     
    function isActiveTranscoder(address _transcoder, uint256 _round) public view returns (bool) {
        return activeTranscoderSet[_round].isActive[_transcoder];
    }

     
    function isRegisteredTranscoder(address _transcoder) public view returns (bool) {
        return transcoderStatus(_transcoder) == TranscoderStatus.Registered;
    }

     
    function isValidUnbondingLock(address _delegator, uint256 _unbondingLockId) public view returns (bool) {
         
        return delegators[_delegator].unbondingLocks[_unbondingLockId].withdrawRound > 0;
    }

     
    function resignTranscoder(address _transcoder) internal {
        uint256 currentRound = roundsManager().currentRound();
        if (activeTranscoderSet[currentRound].isActive[_transcoder]) {
             
            activeTranscoderSet[currentRound].totalStake = activeTranscoderSet[currentRound].totalStake.sub(activeTranscoderTotalStake(_transcoder, currentRound));
             
            activeTranscoderSet[currentRound].isActive[_transcoder] = false;
        }

         
        transcoderPool.remove(_transcoder);

        TranscoderResigned(_transcoder);
    }

     
    function updateTranscoderWithRewards(address _transcoder, uint256 _rewards, uint256 _round) internal {
        Transcoder storage t = transcoders[_transcoder];
        Delegator storage del = delegators[_transcoder];

        EarningsPool.Data storage earningsPool = t.earningsPoolPerRound[_round];
         
        earningsPool.addToRewardPool(_rewards);
         
        del.delegatedAmount = del.delegatedAmount.add(_rewards);
         
        uint256 newStake = transcoderTotalStake(_transcoder).add(_rewards);
        transcoderPool.updateKey(_transcoder, newStake, address(0), address(0));
    }

     
    function updateDelegatorWithEarnings(address _delegator, uint256 _endRound) internal {
        Delegator storage del = delegators[_delegator];

         
         
        if (del.delegateAddress != address(0)) {
             
             
             
             
             
            require(_endRound.sub(del.lastClaimRound) <= maxEarningsClaimsRounds);

            uint256 currentBondedAmount = del.bondedAmount;
            uint256 currentFees = del.fees;

            for (uint256 i = del.lastClaimRound + 1; i <= _endRound; i++) {
                EarningsPool.Data storage earningsPool = transcoders[del.delegateAddress].earningsPoolPerRound[i];

                if (earningsPool.hasClaimableShares()) {
                    bool isTranscoder = _delegator == del.delegateAddress;

                    var (fees, rewards) = earningsPool.claimShare(currentBondedAmount, isTranscoder);

                    currentFees = currentFees.add(fees);
                    currentBondedAmount = currentBondedAmount.add(rewards);
                }
            }

             
            del.bondedAmount = currentBondedAmount;
            del.fees = currentFees;
        }

        del.lastClaimRound = _endRound;
    }

     
    function processRebond(address _delegator, uint256 _unbondingLockId) internal {
        Delegator storage del = delegators[_delegator];
        UnbondingLock storage lock = del.unbondingLocks[_unbondingLockId];

         
        require(isValidUnbondingLock(_delegator, _unbondingLockId));

        uint256 amount = lock.amount;
         
        del.bondedAmount = del.bondedAmount.add(amount);
         
        delegators[del.delegateAddress].delegatedAmount = delegators[del.delegateAddress].delegatedAmount.add(amount);

        if (transcoderStatus(del.delegateAddress) == TranscoderStatus.Registered) {
             
            transcoderPool.updateKey(del.delegateAddress, transcoderTotalStake(del.delegateAddress).add(amount), address(0), address(0));
        }

         
        delete del.unbondingLocks[_unbondingLockId];

        Rebond(del.delegateAddress, _delegator, _unbondingLockId, amount);
    }

     
    function livepeerToken() internal view returns (ILivepeerToken) {
        return ILivepeerToken(controller.getContract(keccak256("LivepeerToken")));
    }

     
    function minter() internal view returns (IMinter) {
        return IMinter(controller.getContract(keccak256("Minter")));
    }

     
    function roundsManager() internal view returns (IRoundsManager) {
        return IRoundsManager(controller.getContract(keccak256("RoundsManager")));
    }
}