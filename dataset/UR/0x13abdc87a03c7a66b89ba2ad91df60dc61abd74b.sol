 

 

 

pragma solidity ^0.4.4;


 
 
contract Campaign {
   
   
  function owner() public constant returns(address) {}

   
   
  function version() public constant returns(string) {}

   
   
  function name() public constant returns(string) {}

   
   
  function contributeMethodABI() public constant returns(string) {}

   
   
  function refundMethodABI() public constant returns(string) {}

   
   
  function payoutMethodABI() public constant returns(string) {}

   
   
  function beneficiary() public constant returns(address) {}

   
   
  function expiry() public constant returns(uint256 blockNumber) {}

   
   
  function fundingGoal() public constant returns(uint256 amount) {}

   
   
  function fundingCap() public constant returns(uint256 amount) {}

   
   
  function amountRaised() public constant returns(uint256 amount) {}

   
   
  function created() public constant returns(uint256 timestamp) {}

   
   
  function stage() public constant returns(uint256);

   
   
  function contributions(uint256 _contributionID) public constant returns(address _sender, uint256 _value, uint256 _time) {}

   
  event ContributionMade (address _contributor);
  event RefundPayoutClaimed(address _payoutDestination, uint256 _payoutAmount);
  event BeneficiaryPayoutClaimed (address _payoutDestination);
}

 

 

pragma solidity ^0.4.4;


 
 
contract Enhancer {
   
   
  function setCampaign(address _campaign) public {}

   
   
   
   
   
   
   
  function notate(address _sender, uint256 _value, uint256 _blockNumber, uint256[] _amounts) public returns (bool earlySuccess) {}
}

 

 

pragma solidity ^0.4.4;


 
 
contract Owned {
   
  modifier onlyowner() {
    if (msg.sender != owner) {
      throw;
    }

    _;
  }

   
  address public owner;
}
 

 

pragma solidity ^0.4.4;


 
 
contract Claim {
   
  function claimMethodABI() constant public returns (string) {}

   
  event ClaimSuccess(address _sender);
}
 

 

pragma solidity ^0.4.4;


 
 
contract BalanceClaimInterface {
   
  function claimBalance() public {}
}


 
 
contract BalanceClaim is Owned, Claim, BalanceClaimInterface {
   
  function () payable public {}

   
  function claimBalance() onlyowner public {
     
    selfdestruct(owner);
  }

   
   
  function BalanceClaim(address _owner) {
     
    owner = _owner;
  }

   
   
  string constant public claimMethodABI = "claimBalance()";
}

 

 

pragma solidity ^0.4.4;


 
 
contract PrivateServiceRegistryInterface {
   
   
   
  function register(address _service) internal returns (uint256 serviceId) {}

   
   
   
  function isService(address _service) public constant returns (bool) {}

   
   
   
  function services(uint256 _serviceId) public constant returns (address _service) {}

   
   
   
  function ids(address _service) public constant returns (uint256 serviceId) {}

  event ServiceRegistered(address _sender, address _service);
}

contract PrivateServiceRegistry is PrivateServiceRegistryInterface {

  modifier isRegisteredService(address _service) {
     
    if (services.length > 0) {
      if (services[ids[_service]] == _service && _service != address(0)) {
        _;
      }
    }
  }

  modifier isNotRegisteredService(address _service) {
     
    if (!isService(_service)) {
      _;
    }
  }

  function register(address _service)
    internal
    isNotRegisteredService(_service)
    returns (uint serviceId) {
     
    serviceId = services.length++;

     
    services[serviceId] = _service;

     
    ids[_service] = serviceId;

     
    ServiceRegistered(msg.sender, _service);
  }

  function isService(address _service)
    public
    constant
    isRegisteredService(_service)
    returns (bool) {
    return true;
  }

  address[] public services;
  mapping(address => uint256) public ids;
}


 

 

 

pragma solidity ^0.4.4;

 

 


 
 
contract StandardCampaign is Owned, Campaign {
   
  enum Stages {
    CrowdfundOperational,
    CrowdfundFailure,
    CrowdfundSuccess
  }

   
  modifier atStage(Stages _expectedStage) {
     
    if (stage() != uint256(_expectedStage)) {
      throw;
    } else {
       
      _;
    }
  }

   
   
   
  modifier validContribution() {
     
     
    if (msg.value == 0
      || amountRaised + msg.value > fundingCap
      || amountRaised + msg.value < amountRaised) {
      throw;
    } else {
       
      _;
    }
  }

   
   
  modifier validRefundClaim(uint256 _contributionID) {
     
    Contribution refundContribution = contributions[_contributionID];

     
     
    if(refundsClaimed[_contributionID] == true  
      || refundContribution.sender != msg.sender){  
      throw;
    } else {
       
      _;
    }
  }

   
  modifier onlybeneficiary() {
    if (msg.sender != beneficiary) {
      throw;
    } else {
      _;
    }
  }

   
  function () public payable {
    contributeMsgValue(defaultAmounts);
  }

   
  function stage() public constant returns (uint256) {
     
    if (block.number < expiry
      && earlySuccess == false
      && amountRaised < fundingCap) {
      return uint256(Stages.CrowdfundOperational);

     
    } else if(block.number >= expiry
      && earlySuccess == false
      && amountRaised < fundingGoal) {
      return uint256(Stages.CrowdfundFailure);

     
     
     
    } else if((block.number >= expiry && amountRaised >= fundingGoal)
      || earlySuccess == true
      || amountRaised >= fundingCap) {
      return uint256(Stages.CrowdfundSuccess);
    }
  }

   
   
  function contributeMsgValue(uint256[] _amounts)
    public  
    payable  
    atStage(Stages.CrowdfundOperational)  
    validContribution()  
    returns (uint256 contributionID) {
     
    contributionID = contributions.length++;

     
    contributions[contributionID] = Contribution({
        sender: msg.sender,
        value: msg.value,
        created: block.number
    });

     
    contributionsBySender[msg.sender].push(contributionID);

     
    amountRaised += msg.value;

     
    ContributionMade(msg.sender);

     
     
     
     
    if (enhancer.notate(msg.sender, msg.value, block.number, _amounts)) {
       
       
       
       
       
      earlySuccess = true;
    }
  }

   
   
  function payoutToBeneficiary() public onlybeneficiary() {
     
     
     
     
    earlySuccess = true;

     
    if (!beneficiary.send(this.balance)) {
      throw;
    } else {
       
      BeneficiaryPayoutClaimed(beneficiary);
    }
  }

   
   
   
   
  function claimRefundOwed(uint256 _contributionID)
    public
    atStage(Stages.CrowdfundFailure)  
    validRefundClaim(_contributionID)  
    returns (address balanceClaim) {  
     
    refundsClaimed[_contributionID] = true;

     
    Contribution refundContribution = contributions[_contributionID];

     
    balanceClaim = address(new BalanceClaim(refundContribution.sender));

     
    refundClaimAddress[_contributionID] = balanceClaim;

     
    if (!balanceClaim.send(refundContribution.value)) {
      throw;
    }

     
    RefundPayoutClaimed(balanceClaim, refundContribution.value);
  }

   
  function totalContributions() public constant returns (uint256 amount) {
    return uint256(contributions.length);
  }

   
  function totalContributionsBySender(address _sender)
    public
    constant
    returns (uint256 amount) {
    return uint256(contributionsBySender[_sender].length);
  }

   
  function StandardCampaign(string _name,
    uint256 _expiry,
    uint256 _fundingGoal,
    uint256 _fundingCap,
    address _beneficiary,
    address _owner,
    address _enhancer) public {
     
    name = _name;

     
    expiry = _expiry;

     
    fundingGoal = _fundingGoal;

     
    fundingCap = _fundingCap;

     
    beneficiary = _beneficiary;

     
    owner = _owner;

     
    created = block.number;

     
    enhancer = Enhancer(_enhancer);
  }

   
  struct Contribution {
     
    address sender;

     
    uint256 value;

     
    uint256 created;
  }

   
  uint256[] defaultAmounts;

   
  Enhancer public enhancer;

   
  bool public earlySuccess;

   
  address public owner;

   
  uint256 public fundingGoal;

   
  uint256 public fundingCap;

   
  uint256 public amountRaised;

   
  uint256 public expiry;

   
  uint256 public created;

   
  address public beneficiary;

   
  Contribution[] public contributions;

   
  mapping(address => uint256[]) public contributionsBySender;

   
   
  mapping(uint256 => address) public refundClaimAddress;

   
   
  mapping(uint256 => bool) public refundsClaimed;

   
  string public name;

   
  string constant public version = "0.1.0";

   
   
  string constant public contributeMethodABI = "contributeMsgValue(uint256[]):(uint256)";

   
  string constant public payoutMethodABI = "payoutToBeneficiary()";

   
  string constant public refundMethodABI = "claimRefundOwed(uint256):(address)";
}

 

 

pragma solidity ^0.4.4;


 
 
contract EmptyEnhancer is Enhancer {
   
  function notate(address _sender, uint256 _value, uint256 _blockNumber, uint256[] _amounts)
  public
  returns (bool earlySuccess) {
    return false;
  }
}


 

pragma solidity ^0.4.4;


 
 
contract StandardCampaignFactory is PrivateServiceRegistry {
  function createStandardCampaign(string _name,
    uint256 _expiry,
    uint256 _fundingGoal,
    uint256 _fundingCap,
    address _beneficiary,
    address _enhancer) public returns (address campaignAddress) {
     
    campaignAddress = address(new StandardCampaign(_name,
      _expiry,
      _fundingGoal,
      _fundingCap,
      _beneficiary,
      msg.sender,
      _enhancer));

     
    register(campaignAddress);
  }
}