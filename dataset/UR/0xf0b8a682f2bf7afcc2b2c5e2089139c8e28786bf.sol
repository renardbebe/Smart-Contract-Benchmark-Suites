 

pragma solidity ^0.4.24;

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract IDealsSupport {

 

   
  function canBeCancelledByMerchant(uint _dealIndex) public view returns(bool);

   
  function getAffiliateRewardInfo(uint _referenceHash, uint _affiliateRewardIndex) public view returns(uint, uint);

   
  function getDealIndex(uint _referenceHash) public view returns(uint);

   
  function getDynamicDealInfo(uint _dealIndex) public view returns(uint[]);

   
  function getReferenceHash(uint _dealIndex, address _affiliateAddress) public view returns(uint);

   
  function isDealCancelled(uint _dealIndex) public view returns(bool);

   
  function isDealClosed(uint _dealIndex) public view returns(bool);

 

   
  function toggleBlockAffiliate(uint _referenceHash) public;

   
  function cancelDealByAdmin(uint _dealIndex) public;

   
  function changeAdmin(address _newAdminAddress) public;

 

   
  function getMyReward(uint _dealIndex) public;

 

   
  function approveAffiliate(uint _dealIndex, address _affiliateAddress) public;

   
  function cancelAllDealsByMerchant() public;

   
  function cancelDealByMerchant(uint _dealIndex) public;

   
  function createDeal(bytes4 _dealID, address _rewardTokenAddress, uint _rewardRatePpm, uint _daysOfCancellation, uint _daysBeforeClose, bool _isAcceptAnyAffiliate) public;

   
  function fillStake(uint _dealIndex, uint _amount) public;

   
  function getMyStakeBack(uint _dealIndex) public;

   
  function updateDeal(uint _dealIndex, uint _newRewardRatePpm) public;

}

contract DealsSupport is IDealsSupport {
  using SafeMath for uint;

  address public adminAddress;
  address public merchantAddress;

  mapping(uint => Affiliate) public affiliates;
  uint public affiliatesCount;

  mapping(uint => Deal) public deals;
  uint public dealsCount;

  mapping(address => uint[]) public affiliateDealIndexes;
  mapping(address => uint) public affiliateDealIndexesCount;

  mapping(uint => mapping(address => uint)) public dealAffiliateReferenceHash;
  mapping(uint => mapping(address => uint)) public dealAffiliateReferenceHashCount;
  mapping(uint => uint) public referenceHashDealIndex;

  event ApproveAffiliate(bytes4 _dealId, address indexed _merchantAddress, uint indexed _dealIndex, address indexed _affiliateAddress, uint _referenceHash);
  event CreateDeal(bytes4 _dealId, uint _dealIndex, address indexed _merchantAddress, address indexed _rewardTokenAddress, uint _rewardRatePpm, uint _daysOfCancellation, uint _daysBeforeClose, uint _dealsCount);
  event ToggleBlockAffiliate(bytes4 _dealId, uint _referenceHash, bool _isBlocked);
  event DealCancelled(bytes4 _dealId, uint _days, address _who);
  event StakeFilled(bytes4 _dealId, uint _fill, uint _left);
  event RewardClaimed(bytes4 _dealId, uint _referenceHash, uint _rewardAmount);
  event DealUpdated(bytes4 _dealId, uint _newRewardRatePpm);
  event RewardCreated(bytes4 _dealId, uint _referenceHash, uint _purchasedTokenAmount, uint _rewardAmount);

  struct Affiliate {
    address affiliateAddress;
    bool isBlocked;
    uint rewardAmount;
    uint affiliateRewardsCount;
    mapping(uint => AffiliateReward) affiliateRewards;
  }

  struct AffiliateReward {
    uint amount;
    uint createdAt;
  }

  struct Deal {
    address rewardTokenAddress;
    bool isCancelled;
    bool isCancelRequestedByMerchant;
    uint rewardRatePpm;
    uint daysOfCancellation;
    uint daysBeforeClose;
    uint createdAt;
    uint cancelRequestedAt;
    uint leftStakeAmount;
    uint affiliatesCount;
    uint lockedTokensAmount;
    uint[] referenceHashes;

    bytes4 dealId;
    bool allowAdminToAddAffiliate;
  }

   

   
  modifier activeDeal(uint _dealIndex) {
    require(!isDealCancelled(_dealIndex),"Deal is cancelled.");
    require(!isDealClosed(_dealIndex),"Deal is closed.");
    _;
  }

   
  modifier onlyAdmin() {
    require(msg.sender == adminAddress, "Admin rights required.");
    _;
  }

   
  modifier onlyMerchant() {
    require(msg.sender == merchantAddress, "Merchant rights required.");
    _;
  }

   
  modifier validDealIndex(uint _dealIndex) {
    require(_dealIndex < dealsCount, "That deal index does not exist.");
    _;
  }

   
  modifier validReferenceHash(uint _referenceHash) {
     
    require(_referenceHash != 0, "referenceHash can not be 0");
    require(_referenceHash <= affiliatesCount, "That referenceHash does not exist");
    _;
  }

   
  constructor(address _adminAddress, address _merchantAddress) public {
     
    require(_adminAddress != address(0), "Admin address can not be 0.");
    require(_merchantAddress != address(0), "Merchant address can not be 0.");
     
    adminAddress = _adminAddress;
    merchantAddress = _merchantAddress;
     
    affiliatesCount = 0;
  }

   

   
  function canBeCancelledByMerchant(uint _dealIndex) public view validDealIndex(_dealIndex) returns(bool) {
    bool canBeCancelled = true;
    if (deals[_dealIndex].isCancelled || deals[_dealIndex].isCancelRequestedByMerchant) {
      canBeCancelled = false;
    }
    return canBeCancelled;
  }

   
  function dealIdToIndex(bytes4 _dealId) public view returns(uint) {
    for (uint i = 0; i<dealsCount; i++) {
      if (deals[i].dealId == _dealId) {
        return i;
      }
    }
    revert("dealID not found");
  }

   
   
  function dealIndexToId(uint _dealIndex) public view returns(bytes4) {
    return deals[_dealIndex].dealId;
  }

   
  function getAffiliateRewardInfo(uint _referenceHash, uint _affiliateRewardIndex) public view validReferenceHash(_referenceHash) returns(uint, uint) {
    require(_affiliateRewardIndex < affiliates[_referenceHash].affiliateRewardsCount, "affiliateRewardIndex does not exist.");
    AffiliateReward memory affiliateReward = affiliates[_referenceHash].affiliateRewards[_affiliateRewardIndex];
    return (
      affiliateReward.amount,
      affiliateReward.createdAt
    );
  }

   
  function getDealIndex(uint _referenceHash) public view validReferenceHash(_referenceHash) returns(uint) {
    return referenceHashDealIndex[_referenceHash];
  }

   
  function getDealIndexesByAffiliate(address _affiliateAddress) public view returns(uint[]) {
    require(_affiliateAddress != address(0), "affiliateAddress can not be 0.");
    return affiliateDealIndexes[_affiliateAddress];
  }

   
  function getDynamicDealInfo(uint _dealIndex) public view validDealIndex(_dealIndex) returns(uint[]) {
    return deals[_dealIndex].referenceHashes;
  }

   
  function getReferenceHash(uint _dealIndex, address _affiliateAddress) public view validDealIndex(_dealIndex) returns(uint) {
     
    require(_affiliateAddress != address(0), "affiliateAddress can not be 0.");
    require(dealAffiliateReferenceHashCount[_dealIndex][_affiliateAddress] == 1, "dealAffiliateReferenceHash does not exist.");
     
    return dealAffiliateReferenceHash[_dealIndex][_affiliateAddress];
  }

   
  function getReferenceHashInfo(uint _referenceHash) public view validReferenceHash(_referenceHash) returns (address, uint) {
    return (
      affiliates[_referenceHash].affiliateAddress,
      referenceHashDealIndex[_referenceHash]
    );
  }

   
  function isDealCancelled(uint _dealIndex) public view validDealIndex(_dealIndex) returns(bool) {
    bool isCancelled = false;
    Deal memory deal = deals[_dealIndex];
    if (deal.isCancelled) {
      isCancelled = true;
    }
    if (deal.isCancelRequestedByMerchant && ((now - deal.cancelRequestedAt) >= (deal.daysOfCancellation * 24 * 60 * 60))) {
      isCancelled = true;
    }
    return isCancelled;
  }

   
  function isDealClosed(uint _dealIndex) public view validDealIndex(_dealIndex) returns(bool) {
    bool isClosed = false;
    Deal memory deal = deals[_dealIndex];
    if ((now - deal.createdAt) >= (deal.daysBeforeClose * 24 * 60 * 60)) {
      isClosed = true;
    }
    return isClosed;
  }

   

   
  function toggleBlockAffiliate(uint _referenceHash) public onlyAdmin validReferenceHash(_referenceHash) {
    affiliates[_referenceHash].isBlocked = !affiliates[_referenceHash].isBlocked;
    bytes4 dealId = deals[referenceHashDealIndex[_referenceHash]].dealId;
    emit ToggleBlockAffiliate(dealId, _referenceHash, affiliates[_referenceHash].isBlocked);
  }

   
  function cancelDealByAdmin(uint _dealIndex) public onlyAdmin validDealIndex(_dealIndex) {
    deals[_dealIndex].isCancelled = true;
    emit DealCancelled(deals[_dealIndex].dealId, deals[_dealIndex].daysOfCancellation, msg.sender);
  }

   
  function changeAdmin(address _newAdminAddress) public onlyAdmin {
    require(_newAdminAddress != address(0), "newAdmin can not be 0.");
    adminAddress = _newAdminAddress;
  }

   

   
  function getMyReward(uint _dealIndex) public validDealIndex(_dealIndex) {
     
    uint referenceHash = getReferenceHash(_dealIndex, msg.sender);
    require(!affiliates[referenceHash].isBlocked, "Affiliate is blocked.");
    require(affiliates[referenceHash].rewardAmount > 0, "rewardAmount for the affiliate is 0.");
    require(deals[_dealIndex].leftStakeAmount >= affiliates[referenceHash].rewardAmount, "There is not enough stake to pay the reward.");
     
    deals[_dealIndex].leftStakeAmount = deals[_dealIndex].leftStakeAmount.sub(affiliates[referenceHash].rewardAmount);
     
    uint tokenAmountToTransfer = affiliates[referenceHash].rewardAmount;
    affiliates[referenceHash].rewardAmount = 0;
    deals[_dealIndex].lockedTokensAmount = deals[_dealIndex].lockedTokensAmount.sub(tokenAmountToTransfer);
    ERC20(deals[_dealIndex].rewardTokenAddress).transfer(affiliates[referenceHash].affiliateAddress, tokenAmountToTransfer);
    emit RewardClaimed(deals[_dealIndex].dealId, referenceHash, tokenAmountToTransfer);
  }

   

   
  function approveAffiliate(uint _dealIndex, address _affiliateAddress) public validDealIndex(_dealIndex) activeDeal(_dealIndex) {
    if (!deals[_dealIndex].allowAdminToAddAffiliate) {
      require(msg.sender == merchantAddress, "Merchant permission required.");
    } else {
      require((msg.sender == adminAddress) || (msg.sender == merchantAddress), "Admin or merchant permission required.");
    }
     
    require(_affiliateAddress != address(0), "affiliateAddress can not be 0.");
     
    require(dealAffiliateReferenceHashCount[_dealIndex][_affiliateAddress] == 0, "Affiliate is already approved for this deal.");
     
    Affiliate memory affiliate;
    affiliate.affiliateAddress = _affiliateAddress;
     
    affiliatesCount = affiliatesCount.add(1);
    affiliates[affiliatesCount] = affiliate;
     
    uint _referenceHash = affiliatesCount;
    deals[_dealIndex].referenceHashes.push(_referenceHash);
    deals[_dealIndex].affiliatesCount = deals[_dealIndex].affiliatesCount.add(1);
     
    affiliateDealIndexes[_affiliateAddress].push(_dealIndex);
    affiliateDealIndexesCount[_affiliateAddress] = affiliateDealIndexesCount[_affiliateAddress].add(1);
     
    dealAffiliateReferenceHash[_dealIndex][_affiliateAddress] = affiliatesCount;
    dealAffiliateReferenceHashCount[_dealIndex][_affiliateAddress] = 1;
    referenceHashDealIndex[affiliatesCount] = _dealIndex;
     
    emit ApproveAffiliate(deals[_dealIndex].dealId, msg.sender, _dealIndex, _affiliateAddress, _referenceHash);
  }

   
  function cancelAllDealsByMerchant() public onlyMerchant {
    for (uint i = 0; i < dealsCount; i++) {
      if (canBeCancelledByMerchant(i)) {
        cancelDealByMerchant(i);
        emit DealCancelled(deals[i].dealId, deals[i].daysOfCancellation, msg.sender);
      }
    }
  }

   
  function cancelDealByMerchant(uint _dealIndex) public onlyMerchant validDealIndex(_dealIndex) {
     
    require(canBeCancelledByMerchant(_dealIndex),"Deal can not be cancelled by merchant.");
     
    deals[_dealIndex].isCancelRequestedByMerchant = true;
    deals[_dealIndex].cancelRequestedAt = now;
    if (deals[_dealIndex].daysOfCancellation == 0) {
      deals[_dealIndex].isCancelled = true;
    }
    emit DealCancelled(deals[_dealIndex].dealId, deals[_dealIndex].daysOfCancellation, msg.sender);
  }

   

  function createDeal(bytes4 _dealId, address _rewardTokenAddress, uint _rewardRatePpm, uint _daysOfCancellation, uint _daysBeforeClose, bool _allowAdminToAddAffiliate) public onlyMerchant {
     
    require(_rewardTokenAddress != address(0), "rewardTokenAddress can not be 0.");
    require(_rewardRatePpm > 0, "rewardRatePpm can not be 0.");
    require(_daysOfCancellation <= 90,"daysOfCancellation can not be >90.");
    require(_daysBeforeClose > 0, "daysBeforeClose should be >0.");
    require(_daysBeforeClose <= 365, "daysBeforeClose can not be >365.");
     
    Deal memory deal;
    deal.dealId = _dealId;
    deal.rewardTokenAddress = _rewardTokenAddress;
    deal.rewardRatePpm = _rewardRatePpm;
    deal.daysOfCancellation = _daysOfCancellation;
    deal.daysBeforeClose = _daysBeforeClose;
    deal.createdAt = now;
    deal.allowAdminToAddAffiliate = _allowAdminToAddAffiliate;
    deals[dealsCount] = deal;

     
    dealsCount = dealsCount.add(1);
     

    emit CreateDeal(_dealId, dealsCount - 1, msg.sender, _rewardTokenAddress, _rewardRatePpm, _daysOfCancellation, _daysBeforeClose, dealsCount);
  }

   
  function fillStake(uint _dealIndex, uint _amount) public onlyMerchant validDealIndex(_dealIndex) activeDeal(_dealIndex) {
     
    require(_amount > 0, "amount should be >0.");
    ERC20 rewardToken = ERC20(deals[_dealIndex].rewardTokenAddress);
    require(rewardToken.allowance(msg.sender, address(this)) >= _amount, "Allowance is not enough to send the required amount.");
     
    deals[_dealIndex].leftStakeAmount = deals[_dealIndex].leftStakeAmount.add(_amount);
    rewardToken.transferFrom(msg.sender, address(this), _amount);
    emit StakeFilled(deals[_dealIndex].dealId, _amount, deals[_dealIndex].leftStakeAmount);
  }

   
  function getMyStakeBack(uint _dealIndex) public onlyMerchant validDealIndex(_dealIndex) {
     
    require(isDealCancelled(_dealIndex), "Deal is not cancelled.");
    require(deals[_dealIndex].leftStakeAmount > 0, "There is no stake left.");
    require(deals[_dealIndex].leftStakeAmount >= deals[_dealIndex].lockedTokensAmount, "Stake is lower than lockedTokensAmount.");
     
    uint tokenAmountToWithdraw = deals[_dealIndex].leftStakeAmount - deals[_dealIndex].lockedTokensAmount;
    deals[_dealIndex].leftStakeAmount = deals[_dealIndex].lockedTokensAmount;
    ERC20(deals[_dealIndex].rewardTokenAddress).transfer(msg.sender, tokenAmountToWithdraw);
  }

   
  function updateDeal(uint _dealIndex, uint _newRewardRatePpm) public onlyMerchant validDealIndex(_dealIndex) activeDeal(_dealIndex) {
    require(_newRewardRatePpm > 0, "_newRewardRatePpm should be >0.");
    deals[_dealIndex].rewardRatePpm = _newRewardRatePpm;
    emit DealUpdated(deals[_dealIndex].dealId, _newRewardRatePpm);
  }

   

   
  function _rewardAffiliate(uint _referenceHash, uint _purchasedTokenAmount) internal validReferenceHash(_referenceHash) {
     
    uint dealIndex = getDealIndex(_referenceHash);
     
    uint rewardAmount = _purchasedTokenAmount.div(1000000).mul(deals[dealIndex].rewardRatePpm);
     
    AffiliateReward memory affiliateReward;
    affiliateReward.amount = rewardAmount;
    affiliateReward.createdAt = now;
    affiliates[_referenceHash].affiliateRewards[affiliates[_referenceHash].affiliateRewardsCount] = affiliateReward;
    affiliates[_referenceHash].affiliateRewardsCount = affiliates[_referenceHash].affiliateRewardsCount.add(1);
     
    affiliates[_referenceHash].rewardAmount = affiliates[_referenceHash].rewardAmount.add(rewardAmount);
     
    deals[dealIndex].lockedTokensAmount = deals[dealIndex].lockedTokensAmount.add(rewardAmount);
    emit RewardCreated(dealIndexToId(dealIndex), _referenceHash, _purchasedTokenAmount, rewardAmount);
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

contract MultistageCrowdsale is DealsSupport, Ownable {
  using SafeMath for uint256;

   
  event TokenPurchase(address indexed purchaser, address indexed affiliate, uint256 value, uint256 amount, bytes4 indexed orderID);

  struct Stage {
    uint32 time;
    uint64 rate;
    uint256 minInv;
    uint256 maxInv;

  }

  Stage[] stages;

  mapping(address => uint256) invested;

  address wallet;
  address token;
  address signer;
  uint32 saleEndTime;

   
  constructor(
    uint256[] _timesAndRates,
    address _wallet,
    address _token,
    address _signer,
    address _admin,
    address _merchant
  )
    public
    DealsSupport(_admin, _merchant)
  {
    require(_wallet != address(0), "Wallet address can not be 0.");
    require(_token != address(0), "Token address can not be 0.");

    storeStages(_timesAndRates);

    saleEndTime = uint32(_timesAndRates[_timesAndRates.length - 1]);
     
    require(saleEndTime > stages[stages.length - 1].time, "Sale end time should be after last stage opening time.");

    wallet = _wallet;
    token = _token;
    signer = _signer;
  }

  function setMinInvestmentAtStage(uint32 _stage, uint256 _value) onlyOwner public {
    require(_stage < stages.length, "Stage does not exist");
    require(_value != getMinInvAtStage(_stage),"That is the current minimum investment");
    require(getMaxInvAtStage(_stage) == 0 || _value <= getMaxInvAtStage(_stage),"Minimum should be lower than the maximum investment when it is not 0");
    stages[_stage].minInv = _value;
  }

  function setMaxInvestmentAtStage(uint32 _stage, uint256 _value) onlyOwner public {
    require(_stage < stages.length, "Stage does not exist");
    require(_value != getMaxInvAtStage(_stage),"That is the current minimum investment");
    require(_value == 0 || _value >= getMinInvAtStage(_stage),"Maximum should be either 0, or higher than the minimum investment");
    stages[_stage].maxInv = _value;
  }

   

  function invest(bytes32 _r, bytes32 _s, bytes32 _a, bytes32 _b) public payable {
     
    uint32 time = uint32(_b >> 224);
    address beneficiary = address(_a);
    uint256 outOfBandPaymentAmount = uint64(_b >> 160);
    uint256 referenceHash = uint256(_b << 96 >> 224);

     
    require(uint56(_a >> 192) == uint56(this), "Destination contract address does not match this contract address.");
    if (outOfBandPaymentAmount == 0) {
      outOfBandPaymentAmount = msg.value;
    } else {
      outOfBandPaymentAmount = outOfBandPaymentAmount.mul(1000000000);   
    }
    bytes4 orderID = bytes4(uint32(_a >> 160));
     
    require(ecrecover(keccak256(abi.encodePacked(uint8(0), uint248(_a), _b)), uint8(_a >> 248), _r, _s) == signer, "Signer address not matching.");
    require(beneficiary != address(0), "Beneficiary can not be 0.");

     
    require(outOfBandPaymentAmount>=getMinInvAt(now),"Investment below minimum required");
     
    require(outOfBandPaymentAmount+invested[beneficiary]<=getMaxInvAt(now) || getMaxInvAt(now)==0,"Investment over maximum allowed in current stage");
     
    uint256 rate = getRateAt(now);  
     
    require(rate == getRateAt(time), "rate not matching current stage rate.");
     
     
     
    uint256 purchasedTokenAmount = ceil(rate.mul(outOfBandPaymentAmount).div(1000000000), 10**3);
     
    require(purchasedTokenAmount > 0, "purchasedTokenAmount can not be 0.");

     
    if (msg.value > 0) {
      wallet.transfer(outOfBandPaymentAmount);
    }

     
    address affiliate = address(0);
    if (referenceHash != 0) {
      affiliate = affiliates[referenceHash].affiliateAddress;
      _rewardAffiliate(referenceHash, purchasedTokenAmount);
    }

     
    invested[beneficiary] += outOfBandPaymentAmount;
    ERC20(token).transferFrom(wallet, beneficiary, purchasedTokenAmount);
    emit TokenPurchase(beneficiary, affiliate, outOfBandPaymentAmount, purchasedTokenAmount, orderID);
  }

  function getParams() view public returns (uint256[] _times, uint256[] _rates, uint256[] _minInvs, uint256[] _maxInvs, address _wallet, address _token, address _signer) {
    _times = new uint256[](stages.length + 1);
    _rates = new uint256[](stages.length);
    _minInvs = new uint256[](stages.length);
    _maxInvs = new uint256[](stages.length);
    for (uint256 i = 0; i < stages.length; i++) {
      _times[i] = stages[i].time;
      _rates[i] = stages[i].rate;
      _minInvs[i] = stages[i].rate;
      _maxInvs[i] = stages[i].rate;
    }
    _times[stages.length] = saleEndTime;
    _wallet = wallet;
    _token = token;
    _signer = signer;
  }

  function storeStages(uint256[] _timesAndRates) internal {
     
    require(_timesAndRates.length % 4 == 1, "Wrong number of parameters in times and rates.");
     
    require(_timesAndRates.length >= 5, "There should be at least 1 complete stage, check number of parameters.");

    for (uint256 i = 0; i < _timesAndRates.length / 4; i++) {
      require(uint64(_timesAndRates[(i * 4) + 3]) == 0 || uint64(_timesAndRates[(i * 4) + 2]) <= uint64(_timesAndRates[(i * 4) + 3]), "Maximum should be higher than minimum, or 0");
      stages.push(Stage(uint32(_timesAndRates[i * 4]), uint64(_timesAndRates[(i * 4) + 1]), uint64(_timesAndRates[(i * 4) + 2]), uint64(_timesAndRates[(i * 4) + 3])));
      if (i > 0) {
         
        require(stages[i-1].time < stages[i].time, "Starting time should be higher than previous stage starting time.");
         
        require(stages[i-1].rate > stages[i].rate, "rate can not be higher than previous stage rate.");
      }
    }

     
    require(stages[0].time > now, "Sale start time should be in the future.");  

     
    require(stages[stages.length - 1].rate > 0, "Final rate can not be 0.");
  }

  function updateRateAtStage (uint256 _stage, uint256 _newRate) public onlyOwner {
     
    require(_stage < stages.length, "Stage does not exist");
    require(_newRate != getRateAtStage(_stage),"That is the current rate");
     
    if (_stage > 0) {
      require(stages[_stage-1].rate > _newRate, "New rate can not be higher than previous stage rate.");
    }
    stages[_stage].rate = uint64(_newRate);
  }

  function getRateAt(uint256 _now) view internal returns (uint256 rate) {
     
    if (_now < stages[0].time) {
      return 0;
    }
    for (uint i = 1; i < stages.length; i++) {
      if (_now < stages[i].time)
        return stages[i - 1].rate;
    }
     
    if (_now < saleEndTime)
      return stages[stages.length - 1].rate;
     
    return 0;
  }

  function getRateAtStage (uint256 _stage) view public returns (uint256 rate) {
     
    require(_stage < stages.length, "Stage does not exist");
    return stages[_stage].rate;
  }

  function getMinInvAt(uint256 _now) view public returns (uint256 inv) {
     
    require(_now >= stages[0].time, "Sale not started");
    require(_now < saleEndTime, "Sale finished");

    for (uint i = 1; i < stages.length; i++) {
      if (_now < stages[i].time)
        return stages[i - 1].minInv;
    }

     
    if (_now < saleEndTime)
      return stages[stages.length - 1].minInv;
  }

  function getMinInvAtStage(uint32 _stage) view public returns (uint256 inv) {
    require(_stage < stages.length, "Stage does not exist");
    return stages[_stage].minInv;
  }

  function getMaxInvAt(uint256 _now) view public returns (uint256 inv) {
     
    require(_now >= stages[0].time, "Sale not started");
    require(_now < saleEndTime, "Sale finished");

    for (uint i = 1; i < stages.length; i++) {
      if (_now < stages[i].time)
        return stages[i - 1].maxInv;
    }

     
    if (_now < saleEndTime)
      return stages[stages.length - 1].maxInv;
  }

  function getMaxInvAtStage(uint32 _stage) view public returns (uint256 inv) {
    require(_stage < stages.length, "Stage does not exist");
    return stages[_stage].maxInv;
  }

  function ceil(uint _value, uint _dec) pure private returns (uint) {
    return((_value + _dec - 1) / _dec) * _dec;
  }
 
   
}

library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}