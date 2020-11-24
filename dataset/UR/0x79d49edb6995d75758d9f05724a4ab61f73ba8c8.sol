 

pragma solidity ^0.5.0;


contract PalmTree {
  uint8 constant ENGAGEMENT_TYPE_REPOST = 1;
  uint8 constant SOCIAL_MEDIA_SOURCE_TWITTER = 1;


  struct Pledge {
    uint128 id;
    address recipient;
    address supporter;
    uint8 socialMediaSource;
    uint64 socialMediaContentId;
    uint8 engagementType;
    uint engagementRewardRate;
    uint engagementGoal;
    uint32 engagementDeadline; 
    uint engagementStart; 
    uint32 engagements;
    uint finalized; 
  }


  address public admin; 
  uint16 public adminCommission = 0; 
  uint public unclaimedRewards;
  uint public unclaimedFees;
  mapping (uint => Pledge) public pledges;


  modifier onlyAdmin() {
    require(admin == msg.sender);
    _;
  }


  constructor() public {
    admin = msg.sender;
  }


  function getAdmin() public view returns (address) {
    return admin;
  }

  function setAdminCommission(uint16 rate) public onlyAdmin {
    adminCommission = rate;
  }


  function getPledge (uint128 id) public view returns (
    address recipient
    , address supporter
    , uint8 socialMediaSource
    , uint64 socialMediaContentId
    , uint8 engagementType
    , uint engagementRewardRate
    , uint engagementGoal
    , uint32 engagementDeadline
    , uint engagementStart
    , uint64 engagements
    , uint finalized
    ) {
    Pledge storage p = pledges[id];
    return (
      p.recipient
      , p.supporter
      , p.socialMediaSource
      , p.socialMediaContentId
      , p.engagementType
      , p.engagementRewardRate
      , p.engagementGoal
      , p.engagementDeadline
      , p.engagementStart
      , p.engagements
      , p.finalized
    );
  }


  function startPledge (
    uint128 id
    , address recipient
    , uint8 socialMediaSource
    , uint64 socialMediaContentId
    , uint8 engagementType
    , uint engagementRewardRate
    , uint32 engagementDeadline) public payable {
    require (id != uint(0));

    Pledge storage p = pledges[id];
    require(p.id == uint128(0));
    require(recipient != address(0));
    require(recipient != msg.sender);
    require(socialMediaSource != uint8(0));
    require(socialMediaContentId != uint64(0));
    require(engagementType != uint8(0));
    require(engagementRewardRate > uint(0));
    require(engagementDeadline > uint32(0));
    require(msg.value > uint(0));

    p.id = id;
    p.recipient = recipient;
    p.supporter = msg.sender;
    p.socialMediaSource = socialMediaSource;
    p.socialMediaContentId = socialMediaContentId;
    p.engagementType = engagementType;
    p.engagementRewardRate = engagementRewardRate;
    p.engagementGoal = msg.value;
    p.engagementDeadline = engagementDeadline;
    p.engagementStart = now;

    unclaimedRewards += msg.value;

  }


  function getPledgeEndDate (uint128 id) public view returns (uint result) {
    Pledge storage p = pledges[id];
    require(p.id == id);
    require(p.engagementStart > uint(0));
    return p.engagementStart + p.engagementDeadline;
  }


  function finalizePledge (uint128 id, uint32 engagements) public onlyAdmin {
    Pledge storage p = pledges[id];
    require(p.id == id);
    require(p.engagementStart > uint(0));
    require(p.finalized == uint(0));

    p.engagements = engagements;
    p.finalized = now;

    uint reward;
    uint remainder;
    uint fees;
    (reward, remainder, fees) = calculateEngagementResults(p);

    unclaimedRewards -= (fees + reward + remainder);
    unclaimedFees += fees;

    if(reward > 0) {
      address payable recipient  = address(int160(p.recipient));
      recipient.transfer(reward);
    }

    if(remainder > 0) {
      address payable supporter  = address(int160(p.supporter));
      supporter.transfer(remainder);
    }
  }


  function withdrawFees () public onlyAdmin {
    if(unclaimedFees > 0){
      uint fees = unclaimedFees;
      unclaimedFees = 0;
      address(uint160(admin)).transfer(fees);
    }
  }


  function calculateEngagementResults (uint128 id) public view 
    returns (uint reward, uint remainder, uint fees){
    Pledge storage p = pledges[id];
    require(p.id == id);
    return calculateEngagementResults(p);
  }


  function calculateEngagementResults (Pledge memory p) private view 
    returns (uint reward, uint remainder, uint fees){
    if (p.finalized > uint(0)) {
      fees = (adminCommission * p.engagementGoal) / 10000;
      reward = p.engagementRewardRate * p.engagements;
      reward = reward < p.engagementGoal ? reward : p.engagementGoal;
      remainder = p.engagementGoal - reward;

      uint feeOverflow;
      if (remainder < fees){
        feeOverflow = fees - remainder;
      }

      reward -= feeOverflow;
      remainder -= fees - feeOverflow;

      assert(reward >= 0);
      assert(remainder >= 0);
      assert(fees >= 0);
      assert((reward + remainder + fees) == p.engagementGoal);
      return (reward, remainder, fees);

    }else{
      return (uint(0), uint(0), uint(0));
    }
  }
}