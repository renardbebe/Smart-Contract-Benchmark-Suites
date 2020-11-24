 

pragma solidity 0.5.1;

 

 
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
        require(isOwner(), "Only the owner can call this function.");
        _;
    }

     
    function isOwner() public view returns (bool) {
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

 

 

library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() public {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender), "Can only be called by pauser.");
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 

 
contract Pausable is PauserRole {
  event Paused();
  event Unpaused();

  bool private _paused = false;

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused, "Cannot call when paused.");
    _;
  }

   
  modifier whenPaused() {
    require(_paused, "Can only call this when paused.");
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused();
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused();
  }
}

 

contract ValidatorRole {
  using Roles for Roles.Role;

  event ValidatorAdded(address indexed account);
  event ValidatorRemoved(address indexed account);

  Roles.Role private validators;

  constructor(address validator) public {
    _addValidator(validator);
  }

  modifier onlyValidator() {
    require(
      isValidator(msg.sender),
      "This function can only be called by a validator."
    );
    _;
  }

  function isValidator(address account) public view returns (bool) {
    return validators.has(account);
  }

  function addValidator(address account) public onlyValidator {
    _addValidator(account);
  }

  function renounceValidator() public {
    _removeValidator(msg.sender);
  }

  function _addValidator(address account) internal {
    validators.add(account);
    emit ValidatorAdded(account);
  }

  function _removeValidator(address account) internal {
    validators.remove(account);
    emit ValidatorRemoved(account);
  }
}

 

 
 
contract IxtEvents {

  event MemberAdded(
    address indexed memberAddress,
    bytes32 indexed membershipNumber,
    bytes32 indexed invitationCode
  );

  event StakeDeposited(
    address indexed memberAddress,
    bytes32 indexed membershipNumber,
    uint256 stakeAmount
  );

  event StakeWithdrawn(
    address indexed memberAddress,
    uint256 stakeAmount
  );

  event RewardClaimed(
    address indexed memberAddress,
    uint256 rewardAmount
  );

  event InvitationRewardGiven(
    address indexed memberReceivingReward,
    address indexed memberGivingReward,
    uint256 rewardAmount
  );

  event PoolDeposit(
    address indexed depositer,
    uint256 amount
  );

  event PoolWithdraw(
    address indexed withdrawer,
    uint256 amount
  );

  event AdminRemovedMember(
    address indexed admin,
    address indexed userAddress,
    uint256 refundIssued
  );

  event MemberDrained(
    address indexed memberAddress,
    uint256 amountRefunded
  );

  event PoolDrained(
    address indexed refundRecipient,
    uint256 amountRefunded
  );

  event ContractDrained(
    address indexed drainInitiator
  );

  event InvitationRewardChanged(
    uint256 newInvitationReward
  );

  event LoyaltyRewardChanged(
    uint256 newLoyaltyRewardAmount
  );
}

 
 
contract RoleManager is Ownable, Pausable, ValidatorRole {

  constructor(address validator)
    public
    ValidatorRole(validator)
  {}
}

 
 
contract StakeManager {

   

  modifier isValidStakeLevel(StakeLevel level) {
    require(
      uint8(level) >= 0 && uint8(level) <= 2,
      "Is not valid a staking level."
    );
    _;
  }

   

   
   
  enum StakeLevel { LOW, MEDIUM, HIGH }

   

   
  uint256[3] public ixtStakingLevels;

   

   
   
  constructor(
    uint256[3] memory _ixtStakingLevels
  ) public {
    ixtStakingLevels = _ixtStakingLevels;
  }

}

 
 
contract RewardManager {

   

   
  uint256 public invitationReward;
   
  uint256 public loyaltyPeriodDays;
   
  uint256 public loyaltyRewardAmount;

   

   
   
   
  constructor(
    uint256 _invitationReward,
    uint256 _loyaltyPeriodDays,
    uint256 _loyaltyRewardAmount
  ) public {
    require(
      _loyaltyRewardAmount >= 0 &&
      _loyaltyRewardAmount <= 100,
      "Loyalty reward amount must be between 0 and 100."
    );
    invitationReward = _invitationReward;
    loyaltyPeriodDays = _loyaltyPeriodDays;
    loyaltyRewardAmount = _loyaltyRewardAmount;
  }

}

 
 
contract IxtProtect is IxtEvents, RoleManager, StakeManager, RewardManager {

   

  modifier isNotMember(address memberAddress) {
    require(
      members[memberAddress].addedTimestamp == 0,
      "Already a member."
    );
    _;
  }

  modifier isMember(address memberAddress) {
    require(
      members[memberAddress].addedTimestamp != 0,
      "User is not a member."
    );
    _;
  }

  modifier notStaking(address memberAddress) {
    require(
      members[memberAddress].stakeTimestamp == 0,
      "Member is staking already."
    );
    _;
  }

  modifier staking(address memberAddress) {
    require(
      members[memberAddress].stakeTimestamp != 0,
      "Member is not staking."
    );
    _;
  }

   

   
  struct Member {
    uint256 addedTimestamp;
    uint256 stakeTimestamp;
    uint256 startOfLoyaltyRewardEligibility;
    bytes32 membershipNumber;
    bytes32 invitationCode;
    uint256 stakeBalance;
    uint256 invitationRewards;
    uint256 previouslyAppliedLoyaltyBalance;
  }

   

   
  IERC20 public ixtToken;
   
  mapping(address => Member) public members;
   
  address[] public membersArray;
   
  uint256 public totalMemberBalance;
   
  uint256 public totalPoolBalance;
   
  mapping(bytes32 => address) public registeredInvitationCodes;
 

   

   
  uint256 public constant IXT_DECIMALS = 8;

   

   
   
   
   
   
   
  constructor(
    address _validator,
    uint256 _loyaltyPeriodDays,
    address _ixtToken,
    uint256 _invitationReward,
    uint256 _loyaltyRewardAmount,
    uint256[3] memory _ixtStakingLevels
  )
    public
    RoleManager(_validator)
    StakeManager(_ixtStakingLevels)
    RewardManager(_invitationReward, _loyaltyPeriodDays, _loyaltyRewardAmount)
  {
    require(_ixtToken != address(0x0), "ixtToken address was set to 0.");
    ixtToken = IERC20(_ixtToken);
  }

   
   
   

   

   
   
   
   
   
   
   
   
   

  function addMember(
    bytes32 _membershipNumber,
    address _memberAddress,
    bytes32 _invitationCode,
    bytes32 _referralInvitationCode
  ) 
    public
    onlyValidator
    isNotMember(_memberAddress)
    notStaking(_memberAddress)
  {
    require(
      _memberAddress != address(0x0),
      "Member address was set to 0."
    );
    Member memory member = Member({
      addedTimestamp: block.timestamp,
      stakeTimestamp: 0,
      startOfLoyaltyRewardEligibility: 0,
      membershipNumber: _membershipNumber,
      invitationCode: _invitationCode,
      stakeBalance: 0,
      invitationRewards: 0,
      previouslyAppliedLoyaltyBalance: 0
    });
    members[_memberAddress] = member;
    membersArray.push(_memberAddress);

     
    registeredInvitationCodes[member.invitationCode] = _memberAddress;
     
    address rewardMemberAddress = registeredInvitationCodes[_referralInvitationCode];
    if (
      rewardMemberAddress != address(0x0)
    ) {
      Member storage rewardee = members[rewardMemberAddress];
      rewardee.invitationRewards = SafeMath.add(rewardee.invitationRewards, invitationReward);
      emit InvitationRewardGiven(rewardMemberAddress, _memberAddress, invitationReward);
    }

    emit MemberAdded(_memberAddress, _membershipNumber, _invitationCode);
  }

   
   
   
   
   
  function depositStake(
    StakeLevel _stakeLevel
  )
    public
    whenNotPaused()
    isMember(msg.sender)
    notStaking(msg.sender)
    isValidStakeLevel(_stakeLevel)
  {
    uint256 amountDeposited = depositInternal(msg.sender, ixtStakingLevels[uint256(_stakeLevel)], false);
    Member storage member = members[msg.sender];
    member.stakeTimestamp = block.timestamp;
    member.startOfLoyaltyRewardEligibility = block.timestamp;
     
    registeredInvitationCodes[member.invitationCode] = msg.sender;
    emit StakeDeposited(msg.sender, member.membershipNumber, amountDeposited);
  }

   
   
  function withdrawStake()
    public
    whenNotPaused()
    staking(msg.sender)
  {

    uint256 stakeAmount = refundUserBalance(msg.sender);
    delete registeredInvitationCodes[members[msg.sender].invitationCode];
    Member storage member = members[msg.sender];
    member.stakeTimestamp = 0;
    member.startOfLoyaltyRewardEligibility = 0;
    emit StakeWithdrawn(msg.sender, stakeAmount);
  }

   
   
  function claimRewards()
    public
    whenNotPaused()
    staking(msg.sender)
  {
    uint256 rewardClaimed = claimRewardsInternal(msg.sender);
    emit RewardClaimed(msg.sender, rewardClaimed);
  }

   

   
   
  function getMembersArrayLength() public view returns (uint256) {
    return membersArray.length;
  }

   
   
   
  function getAccountBalance(address memberAddress)
    public
    view
    staking(memberAddress)
    returns (uint256)
  {
    return getStakeBalance(memberAddress) +
      getRewardBalance(memberAddress);
  }

   
   
   
  function getStakeBalance(address memberAddress)
    public
    view
    staking(memberAddress)
    returns (uint256)
  {
    return members[memberAddress].stakeBalance;
  }

   
   
   
  function getRewardBalance(address memberAddress)
    public
    view
    staking(memberAddress)
    returns (uint256)
  {
    return getInvitationRewardBalance(memberAddress) +
      getLoyaltyRewardBalance(memberAddress);
  }

   
   
   
  function getInvitationRewardBalance(address memberAddress)
    public
    view
    staking(memberAddress)
    returns (uint256)
  {
    return members[memberAddress].invitationRewards;
  }

   
   
   
  function getLoyaltyRewardBalance(address memberAddress)
    public
    view
    staking(memberAddress)
    returns (uint256 loyaltyReward)
  {
    uint256 loyaltyPeriodSeconds = loyaltyPeriodDays * 1 days;
    Member storage thisMember = members[memberAddress];
    uint256 elapsedTimeSinceEligible = block.timestamp - thisMember.startOfLoyaltyRewardEligibility;
    loyaltyReward = thisMember.previouslyAppliedLoyaltyBalance;
    if (elapsedTimeSinceEligible >= loyaltyPeriodSeconds) {
      uint256 numWholePeriods = SafeMath.div(elapsedTimeSinceEligible, loyaltyPeriodSeconds);
      uint256 rewardForEachPeriod = thisMember.stakeBalance * loyaltyRewardAmount / 100;
      loyaltyReward += rewardForEachPeriod * numWholePeriods;
    }
  }

   

   
   
   
  function depositPool(uint256 amountToDeposit)
    public
    onlyOwner
  {
    uint256 amountDeposited = depositInternal(msg.sender, amountToDeposit, true);
    emit PoolDeposit(msg.sender, amountDeposited);
  }

   
   
   
  function withdrawPool(uint256 amountToWithdraw)
    public
    onlyOwner
  {
    if (amountToWithdraw > 0) {
      require(
        totalPoolBalance >= amountToWithdraw &&
        ixtToken.transfer(msg.sender, amountToWithdraw),
        "Unable to withdraw this value of IXT."  
      );
      totalPoolBalance = SafeMath.sub(totalPoolBalance, amountToWithdraw);
    }
    emit PoolWithdraw(msg.sender, amountToWithdraw);
  }

   
   
   
   
   
   
  function removeMember(address userAddress)
    public
    isMember(userAddress)
    onlyOwner
  {
    uint256 refund = cancelMembershipInternal(userAddress);
    emit AdminRemovedMember(msg.sender, userAddress, refund);
  }

   
   
   
   
  function drain() public onlyOwner {
     
    for (uint256 index = 0; index < membersArray.length; index++) {
      address memberAddress = membersArray[index];
      bool memberJoined = members[memberAddress].stakeTimestamp != 0;
      uint256 amountRefunded = memberJoined ? refundUserBalance(memberAddress) : 0;

      delete registeredInvitationCodes[members[memberAddress].invitationCode];
      delete members[memberAddress];

      emit MemberDrained(memberAddress, amountRefunded);
    }
    delete membersArray;

     
    require(
      ixtToken.transfer(msg.sender, totalPoolBalance),
      "Unable to withdraw this value of IXT."
    );
    totalPoolBalance = 0;
    emit PoolDrained(msg.sender, totalPoolBalance);
    
    emit ContractDrained(msg.sender);
  }

   
   
   
  function setInvitationReward(uint256 _invitationReward)
    public
    onlyOwner
  {
    invitationReward = _invitationReward;
    emit InvitationRewardChanged(_invitationReward);
  }

   
   
   
   
   
  function setLoyaltyRewardAmount(uint256 newLoyaltyRewardAmount)
    public
    onlyOwner
  {
    require(
      newLoyaltyRewardAmount >= 0 &&
      newLoyaltyRewardAmount <= 100,
      "Loyalty reward amount must be between 0 and 100."
    );
    uint256 loyaltyPeriodSeconds = loyaltyPeriodDays * 1 days;
     
    for (uint256 i = 0; i < membersArray.length; i++) {
      Member storage thisMember = members[membersArray[i]];
      uint256 elapsedTimeSinceEligible = block.timestamp - thisMember.startOfLoyaltyRewardEligibility;
      if (elapsedTimeSinceEligible >= loyaltyPeriodSeconds) {
        uint256 numWholePeriods = SafeMath.div(elapsedTimeSinceEligible, loyaltyPeriodSeconds);
        uint256 rewardForEachPeriod = thisMember.stakeBalance * loyaltyRewardAmount / 100;
        thisMember.previouslyAppliedLoyaltyBalance += rewardForEachPeriod * numWholePeriods;
        thisMember.startOfLoyaltyRewardEligibility += numWholePeriods * loyaltyPeriodSeconds;
      }
    }
    loyaltyRewardAmount = newLoyaltyRewardAmount;
    emit LoyaltyRewardChanged(newLoyaltyRewardAmount);
  }

   
   
   

  function cancelMembershipInternal(address memberAddress)
    internal
    returns
    (uint256 amountRefunded)
  {
    if(members[memberAddress].stakeTimestamp != 0) {
      amountRefunded = refundUserBalance(memberAddress);
    }

    delete registeredInvitationCodes[members[memberAddress].invitationCode];

    delete members[memberAddress];

    removeMemberFromArray(memberAddress);
  }

  function refundUserBalance(
    address memberAddress
  ) 
    internal
    returns (uint256)
  {
    Member storage member = members[memberAddress];

     
    uint256 claimsRefunded = claimRewardsInternal(memberAddress);
    uint256 stakeToRefund = member.stakeBalance;

    bool userStaking = member.stakeTimestamp != 0;
    if (stakeToRefund > 0 && userStaking) {
      require(
        ixtToken.transfer(memberAddress, stakeToRefund),
        "Unable to withdraw this value of IXT."  
      );
      totalMemberBalance = SafeMath.sub(totalMemberBalance, stakeToRefund);
    }
    member.stakeBalance = 0;
    return claimsRefunded + stakeToRefund;
  }

  function removeMemberFromArray(address memberAddress) internal {
     
    for (uint256 index; index < membersArray.length; index++) {
      if (membersArray[index] == memberAddress) {
        membersArray[index] = membersArray[membersArray.length - 1];
        membersArray[membersArray.length - 1] = address(0);
        membersArray.length -= 1;
        break;
      }
    }
  }

  function claimRewardsInternal(address memberAddress)
    internal
    returns (uint256 rewardAmount)
  {
    rewardAmount = getRewardBalance(memberAddress);

    if (rewardAmount == 0) {
      return rewardAmount;
    }

    require(
      totalPoolBalance >= rewardAmount,
      "Pool balance not sufficient to withdraw rewards."
    );
    require(
      ixtToken.transfer(memberAddress, rewardAmount),
      "Unable to withdraw this value of IXT."  
    );
     
    totalPoolBalance -= rewardAmount;

    Member storage thisMember = members[memberAddress];
    thisMember.previouslyAppliedLoyaltyBalance = 0;
    thisMember.invitationRewards = 0;

    uint256 loyaltyPeriodSeconds = loyaltyPeriodDays * 1 days;
    uint256 elapsedTimeSinceEligible = block.timestamp - thisMember.startOfLoyaltyRewardEligibility;
    if (elapsedTimeSinceEligible >= loyaltyPeriodSeconds) {
      uint256 numWholePeriods = SafeMath.div(elapsedTimeSinceEligible, loyaltyPeriodSeconds);
      thisMember.startOfLoyaltyRewardEligibility += numWholePeriods * loyaltyPeriodSeconds;
    }
  }

  function depositInternal(
    address depositer,
    uint256 amount,
    bool isPoolDeposit
  ) 
    internal
    returns (uint256)
  {
     
     
    require(amount > 0, "Cannot deposit 0 IXT.");
    require(
      ixtToken.allowance(depositer, address(this)) >= amount &&
      ixtToken.balanceOf(depositer) >= amount &&
      ixtToken.transferFrom(depositer, address(this), amount),
      "Unable to deposit IXT - check allowance and balance."  
    );
    if (isPoolDeposit) {
      totalPoolBalance = SafeMath.add(totalPoolBalance, amount);
    } else {
      Member storage member = members[depositer];
      member.stakeBalance = SafeMath.add(member.stakeBalance, amount);
      totalMemberBalance = SafeMath.add(totalMemberBalance, amount);
    }
    return amount;
  }
}