 

pragma solidity 0.4.26;


 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}




interface IOrbsRewardsDistribution {
    event RewardDistributed(string distributionEvent, address indexed recipient, uint256 amount);

    event RewardsDistributionAnnounced(string distributionEvent, bytes32[] batchHash, uint256 batchCount);
    event RewardsBatchExecuted(string distributionEvent, bytes32 batchHash, uint256 batchIndex);
    event RewardsDistributionAborted(string distributionEvent, bytes32[] abortedBatchHashes, uint256[] abortedBatchIndices);
    event RewardsDistributionCompleted(string distributionEvent);

    event RewardsDistributorReassigned(address indexed previousRewardsDistributor, address indexed newRewardsDistributor);

    function announceDistributionEvent(string distributionEvent, bytes32[] batchHashes) external;
    function abortDistributionEvent(string distributionEvent) external;

    function executeCommittedBatch(string distributionEvent, address[] recipients, uint256[] amounts, uint256 batchIndex) external;

    function distributeRewards(string distributionEvent, address[] recipients, uint256[] amounts) external;

    function getPendingBatches(string distributionEvent) external view returns (bytes32[] pendingBatchHashes, uint256[] pendingBatchIndices);
    function reassignRewardsDistributor(address _newRewardsDistributor) external;
    function isRewardsDistributor() external returns (bool);
}

 
contract OrbsRewardsDistribution is Ownable, IOrbsRewardsDistribution {

    struct Distribution {
        uint256 pendingBatchCount;
        bool hasPendingBatches;
        bytes32[] batchHashes;
    }

     
    IERC20 public orbs;

     
     
     
     
    mapping(string => Distribution) distributions;

     
     
     
     
     
    address public rewardsDistributor;

     
     
    constructor(IERC20 _orbs) public {
        require(address(_orbs) != address(0), "Address must not be 0!");

        rewardsDistributor = address(0);
        orbs = _orbs;
    }

     
     
     
     
     
     
     
    function announceDistributionEvent(string _distributionEvent, bytes32[] _batchHashes) external onlyOwner {
        require(!distributions[_distributionEvent].hasPendingBatches, "distribution event is currently ongoing");
        require(_batchHashes.length > 0, "at least one batch must be announced");

        for (uint256 i = 0; i < _batchHashes.length; i++) {
            require(_batchHashes[i] != bytes32(0), "batch hash may not be 0x0");
        }

         
        Distribution storage distribution = distributions[_distributionEvent];
        distribution.pendingBatchCount = _batchHashes.length;
        distribution.hasPendingBatches = true;
        distribution.batchHashes = _batchHashes;

        emit RewardsDistributionAnnounced(_distributionEvent, _batchHashes, _batchHashes.length);
    }

     
     
     
    function abortDistributionEvent(string _distributionEvent) external onlyOwner {
        require(distributions[_distributionEvent].hasPendingBatches, "distribution event is not currently ongoing");

        (bytes32[] memory abortedBatchHashes, uint256[] memory abortedBatchIndices) = this.getPendingBatches(_distributionEvent);

        delete distributions[_distributionEvent];

        emit RewardsDistributionAborted(_distributionEvent, abortedBatchHashes, abortedBatchIndices);
    }

     
     
     
     
     
     
    function _distributeRewards(string _distributionEvent, address[] _recipients, uint256[] _amounts) private {
        uint256 batchSize = _recipients.length;
        require(batchSize == _amounts.length, "array length mismatch");

        for (uint256 i = 0; i < batchSize; i++) {
            require(_recipients[i] != address(0), "recipient must be a valid address");
            require(orbs.transfer(_recipients[i], _amounts[i]), "transfer failed");
            emit RewardDistributed(_distributionEvent, _recipients[i], _amounts[i]);
        }
    }

     
     
     
     
     
     
     
    function distributeRewards(string _distributionEvent, address[] _recipients, uint256[] _amounts) external onlyRewardsDistributor {
        _distributeRewards(_distributionEvent, _recipients, _amounts);
    }

     
     
     
     
     
     
     
     
     
     
     
     
    function executeCommittedBatch(string _distributionEvent, address[] _recipients, uint256[] _amounts, uint256 _batchIndex) external {
        Distribution storage distribution = distributions[_distributionEvent];
        bytes32[] storage batchHashes = distribution.batchHashes;

        require(_recipients.length == _amounts.length, "array length mismatch");
        require(_recipients.length > 0, "at least one reward must be included in a batch");
        require(distribution.hasPendingBatches, "distribution event is not currently ongoing");
        require(batchHashes.length > _batchIndex, "batch number out of range");
        require(batchHashes[_batchIndex] != bytes32(0), "specified batch number already executed");

        bytes32 calculatedHash = calcBatchHash(_recipients, _amounts, _batchIndex);
        require(batchHashes[_batchIndex] == calculatedHash, "batch hash does not match");

        distribution.pendingBatchCount--;
        batchHashes[_batchIndex] = bytes32(0);  

        if (distribution.pendingBatchCount == 0) {
            delete distributions[_distributionEvent];
            emit RewardsDistributionCompleted(_distributionEvent);
        }
        emit RewardsBatchExecuted(_distributionEvent, calculatedHash, _batchIndex);

        _distributeRewards(_distributionEvent, _recipients, _amounts);
    }

     
     
     
     
     
    function getPendingBatches(string _distributionEvent) external view returns (bytes32[] pendingBatchHashes, uint256[] pendingBatchIndices) {
        Distribution storage distribution = distributions[_distributionEvent];
        bytes32[] storage batchHashes = distribution.batchHashes;
        uint256 pendingBatchCount = distribution.pendingBatchCount;
        uint256 batchHashesLength = distribution.batchHashes.length;

        pendingBatchHashes = new bytes32[](pendingBatchCount);
        pendingBatchIndices = new uint256[](pendingBatchCount);

        uint256 addNextAt = 0;
        for (uint256 i = 0; i < batchHashesLength; i++) {
            bytes32 hash = batchHashes[i];
            if (hash != bytes32(0)) {
                pendingBatchIndices[addNextAt] = i;
                pendingBatchHashes[addNextAt] = hash;
                addNextAt++;
            }
        }
    }

     
     
     
    function drainOrbs() external onlyOwner {
        uint256 balance = orbs.balanceOf(address(this));
        orbs.transfer(owner(), balance);
    }

     
     
     
     
    function reassignRewardsDistributor(address _newRewardsDistributor) external onlyOwner {
        emit RewardsDistributorReassigned(rewardsDistributor, _newRewardsDistributor);
        rewardsDistributor = _newRewardsDistributor;
    }

     
    function isRewardsDistributor() public view returns(bool) {
        return msg.sender == rewardsDistributor;
    }

     
    modifier onlyRewardsDistributor() {
        require(isRewardsDistributor(), "only the assigned rewards-distributor may call this method");
        _;
    }

     
     
     
     
    function calcBatchHash(address[] _recipients, uint256[] _amounts, uint256 _batchIndex) private pure returns (bytes32) {
        bytes memory batchData = abi.encodePacked(_batchIndex, _recipients.length, _recipients, _amounts);

        uint256 expectedLength = 32 * (2 + _recipients.length + _amounts.length);
        require(batchData.length == expectedLength, "unexpected data length");

        return keccak256(batchData);
    }
}