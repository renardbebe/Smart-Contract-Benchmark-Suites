 

pragma solidity ^0.4.13;

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

contract EthicHubStorageInterface {

     
    modifier onlyEthicHubContracts() {_;}

     
    function setAddress(bytes32 _key, address _value) external;
    function setUint(bytes32 _key, uint _value) external;
    function setString(bytes32 _key, string _value) external;
    function setBytes(bytes32 _key, bytes _value) external;
    function setBool(bytes32 _key, bool _value) external;
    function setInt(bytes32 _key, int _value) external;
     
    function deleteAddress(bytes32 _key) external;
    function deleteUint(bytes32 _key) external;
    function deleteString(bytes32 _key) external;
    function deleteBytes(bytes32 _key) external;
    function deleteBool(bytes32 _key) external;
    function deleteInt(bytes32 _key) external;

     
    function getAddress(bytes32 _key) external view returns (address);
    function getUint(bytes32 _key) external view returns (uint);
    function getString(bytes32 _key) external view returns (string);
    function getBytes(bytes32 _key) external view returns (bytes);
    function getBool(bytes32 _key) external view returns (bool);
    function getInt(bytes32 _key) external view returns (int);
}

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

contract EthicHubReputationInterface {
    modifier onlyUsersContract(){_;}
    modifier onlyLendingContract(){_;}
    function burnReputation(uint delayDays)  external;
    function incrementReputation(uint completedProjectsByTier)  external;
    function initLocalNodeReputation(address localNode)  external;
    function initCommunityReputation(address community)  external;
    function getCommunityReputation(address target) public view returns(uint256);
    function getLocalNodeReputation(address target) public view returns(uint256);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

contract EthicHubBase {

    uint8 public version;

    EthicHubStorageInterface public ethicHubStorage = EthicHubStorageInterface(0);

    constructor(address _storageAddress) public {
        require(_storageAddress != address(0));
        ethicHubStorage = EthicHubStorageInterface(_storageAddress);
    }

}

contract EthicHubLending is EthicHubBase, Ownable, Pausable {
    using SafeMath for uint256;
     
    enum LendingState {
        Uninitialized,
        AcceptingContributions,
        ExchangingToFiat,
        AwaitingReturn,
        ProjectNotFunded,
        ContributionReturned,
        Default
    }
    mapping(address => Investor) public investors;
    uint256 public investorCount;
    uint256 public reclaimedContributions;
    uint256 public reclaimedSurpluses;
    uint256 public fundingStartTime;                                      
    uint256 public fundingEndTime;                                        
    uint256 public totalContributed;
    bool public capReached;
    LendingState public state;
    uint256 public annualInterest;
    uint256 public totalLendingAmount;
    uint256 public lendingDays;
    uint256 public borrowerReturnDays;
    uint256 public initialEthPerFiatRate;
    uint256 public totalLendingFiatAmount;
    address public borrower;
    address public localNode;
    address public ethicHubTeam;
     
    uint256 public borrowerReturnEthPerFiatRate;
    uint256 public ethichubFee;
    uint256 public localNodeFee;
    uint256 public tier;
     
     
    uint256 public constant interestBaseUint = 100;
    uint256 public constant interestBasePercent = 10000;
    bool public localNodeFeeReclaimed;
    bool public ethicHubTeamFeeReclaimed;
    uint256 public surplusEth;
    uint256 public returnedEth;

    struct Investor {
        uint256 amount;
        bool isCompensated;
        bool surplusEthReclaimed;
    }

     
    event onCapReached(uint endTime);
    event onContribution(uint totalContributed, address indexed investor, uint amount, uint investorsCount);
    event onCompensated(address indexed contributor, uint amount);
    event onSurplusSent(uint256 amount);
    event onSurplusReclaimed(address indexed contributor, uint amount);
    event StateChange(uint state);
    event onInitalRateSet(uint rate);
    event onReturnRateSet(uint rate);
    event onReturnAmount(address indexed borrower, uint amount);
    event onBorrowerChanged(address indexed newBorrower);
    event onInvestorChanged(address indexed oldInvestor, address indexed newInvestor);

     
    modifier checkProfileRegistered(string profile) {
        bool isRegistered = ethicHubStorage.getBool(keccak256(abi.encodePacked("user", profile, msg.sender)));
        require(isRegistered, "Sender not registered in EthicHub.com");
        _;
    }

    modifier checkIfArbiter() {
        address arbiter = ethicHubStorage.getAddress(keccak256(abi.encodePacked("arbiter", this)));
        require(arbiter == msg.sender, "Sender not authorized");
        _;
    }

    modifier onlyOwnerOrLocalNode() {
        require(localNode == msg.sender || owner == msg.sender,"Sender not authorized");
        _;
    }

     
     
     
     
     
     

    constructor(
        uint256 _fundingStartTime,
        uint256 _fundingEndTime,
        address _borrower,
        uint256 _annualInterest,
        uint256 _totalLendingAmount,
        uint256 _lendingDays,
        address _storageAddress,
        address _localNode,
        address _ethicHubTeam,
        uint256 _ethichubFee,
        uint256 _localNodeFee
        )
        EthicHubBase(_storageAddress)
        public {
        require(_fundingEndTime > fundingStartTime, "fundingEndTime should be later than fundingStartTime");
        require(_borrower != address(0), "No borrower set");
        require(ethicHubStorage.getBool(keccak256(abi.encodePacked("user", "representative", _borrower))), "Borrower not registered representative");
        require(_localNode != address(0), "No Local Node set");
        require(_ethicHubTeam != address(0), "No EthicHub Team set");
        require(ethicHubStorage.getBool(keccak256(abi.encodePacked("user", "localNode", _localNode))), "Local Node is not registered");
        require(_totalLendingAmount > 0, "_totalLendingAmount must be > 0");
        require(_lendingDays > 0, "_lendingDays must be > 0");
        require(_annualInterest > 0 && _annualInterest < 100, "_annualInterest must be between 0 and 100");
        version = 7;
        reclaimedContributions = 0;
        reclaimedSurpluses = 0;
        borrowerReturnDays = 0;
        fundingStartTime = _fundingStartTime;
        fundingEndTime = _fundingEndTime;
        localNode = _localNode;
        ethicHubTeam = _ethicHubTeam;
        borrower = _borrower;
        annualInterest = _annualInterest;
        totalLendingAmount = _totalLendingAmount;
        lendingDays = _lendingDays;
        ethichubFee = _ethichubFee;
        localNodeFee = _localNodeFee;
        state = LendingState.Uninitialized;
    }

    function saveInitialParametersToStorage(uint256 _maxDelayDays, uint256 _tier, uint256 _communityMembers, address _community) external onlyOwnerOrLocalNode {
        require(_maxDelayDays != 0, "_maxDelayDays must be > 0");
        require(state == LendingState.Uninitialized, "State must be Uninitialized");
        require(_tier > 0, "_tier must be > 0");
        require(_communityMembers > 0, "_communityMembers must be > 0");
        require(ethicHubStorage.getBool(keccak256(abi.encodePacked("user", "community", _community))), "Community is not registered");
        ethicHubStorage.setUint(keccak256(abi.encodePacked("lending.maxDelayDays", this)), _maxDelayDays);
        ethicHubStorage.setAddress(keccak256(abi.encodePacked("lending.community", this)), _community);
        ethicHubStorage.setAddress(keccak256(abi.encodePacked("lending.localNode", this)), localNode);
        ethicHubStorage.setUint(keccak256(abi.encodePacked("lending.tier", this)), _tier);
        ethicHubStorage.setUint(keccak256(abi.encodePacked("lending.communityMembers", this)), _communityMembers);
        tier = _tier;
        state = LendingState.AcceptingContributions;
        emit StateChange(uint(state));

    }

    function setBorrower(address _borrower) external checkIfArbiter {
        require(_borrower != address(0), "No borrower set");
        require(ethicHubStorage.getBool(keccak256(abi.encodePacked("user", "representative", _borrower))), "Borrower not registered representative");
        borrower = _borrower;
        emit onBorrowerChanged(borrower);
    }

    function changeInvestorAddress(address oldInvestor, address newInvestor) external checkIfArbiter {
        require(newInvestor != address(0));
        require(ethicHubStorage.getBool(keccak256(abi.encodePacked("user", "investor", newInvestor))));
         
        require(investors[oldInvestor].amount != 0);
         
        require(investors[newInvestor].amount == 0);
        investors[newInvestor].amount = investors[oldInvestor].amount;
        investors[newInvestor].isCompensated = investors[oldInvestor].isCompensated;
        investors[newInvestor].surplusEthReclaimed = investors[oldInvestor].surplusEthReclaimed;
        delete investors[oldInvestor];
        emit onInvestorChanged(oldInvestor, newInvestor);
    }

    function() public payable whenNotPaused {
        require(state == LendingState.AwaitingReturn || state == LendingState.AcceptingContributions || state == LendingState.ExchangingToFiat, "Can't receive ETH in this state");
        if(state == LendingState.AwaitingReturn) {
            returnBorrowedEth();
        } else if (state == LendingState.ExchangingToFiat) {
             
            sendBackSurplusEth();
        } else {
            require(ethicHubStorage.getBool(keccak256(abi.encodePacked("user", "investor", msg.sender))), "Sender is not registered lender");
            contributeWithAddress(msg.sender);
        }
    }

    function sendBackSurplusEth() internal {
        require(state == LendingState.ExchangingToFiat);
        require(msg.sender == borrower);
        surplusEth = surplusEth.add(msg.value);
        require(surplusEth <= totalLendingAmount);
        emit onSurplusSent(msg.value);
    }

     
    function declareProjectNotFunded() external onlyOwnerOrLocalNode {
        require(totalContributed < totalLendingAmount);
        require(state == LendingState.AcceptingContributions);
        require(now > fundingEndTime);
        state = LendingState.ProjectNotFunded;
        emit StateChange(uint(state));
    }

    function declareProjectDefault() external onlyOwnerOrLocalNode {
        require(state == LendingState.AwaitingReturn);
        uint maxDelayDays = getMaxDelayDays();
        require(getDelayDays(now) >= maxDelayDays);
        EthicHubReputationInterface reputation = EthicHubReputationInterface(ethicHubStorage.getAddress(keccak256(abi.encodePacked("contract.name", "reputation"))));
        require(reputation != address(0));
        ethicHubStorage.setUint(keccak256(abi.encodePacked("lending.delayDays", this)), maxDelayDays);
        reputation.burnReputation(maxDelayDays);
        state = LendingState.Default;
        emit StateChange(uint(state));
    }

    function setBorrowerReturnEthPerFiatRate(uint256 _borrowerReturnEthPerFiatRate) external onlyOwnerOrLocalNode {
        require(state == LendingState.AwaitingReturn, "State is not AwaitingReturn");
        borrowerReturnEthPerFiatRate = _borrowerReturnEthPerFiatRate;
        emit onReturnRateSet(borrowerReturnEthPerFiatRate);
    }

     
    function finishInitialExchangingPeriod(uint256 _initialEthPerFiatRate) external onlyOwnerOrLocalNode {
        require(capReached == true, "Cap not reached");
        require(state == LendingState.ExchangingToFiat, "State is not ExchangingToFiat");
        initialEthPerFiatRate = _initialEthPerFiatRate;
        if (surplusEth > 0) {
            totalLendingAmount = totalLendingAmount.sub(surplusEth);
        }
        totalLendingFiatAmount = totalLendingAmount.mul(initialEthPerFiatRate);
        emit onInitalRateSet(initialEthPerFiatRate);
        state = LendingState.AwaitingReturn;
        emit StateChange(uint(state));
    }

     
    function reclaimContributionDefault(address beneficiary) external {
        require(state == LendingState.Default);
        require(!investors[beneficiary].isCompensated);
         
        uint256 contribution = checkInvestorReturns(beneficiary);
        require(contribution > 0);
        investors[beneficiary].isCompensated = true;
        reclaimedContributions = reclaimedContributions.add(1);
        doReclaim(beneficiary, contribution);
    }

     
    function reclaimContribution(address beneficiary) external {
        require(state == LendingState.ProjectNotFunded, "State is not ProjectNotFunded");
        require(!investors[beneficiary].isCompensated, "Contribution already reclaimed");
        uint256 contribution = investors[beneficiary].amount;
        require(contribution > 0, "Contribution is 0");
        investors[beneficiary].isCompensated = true;
        reclaimedContributions = reclaimedContributions.add(1);
        doReclaim(beneficiary, contribution);
    }

    function reclaimSurplusEth(address beneficiary) external {
        require(surplusEth > 0, "No surplus ETH");
         
        require(state != LendingState.ExchangingToFiat, "State is ExchangingToFiat");
        require(!investors[beneficiary].surplusEthReclaimed, "Surplus already reclaimed");
        uint256 surplusContribution = investors[beneficiary].amount.mul(surplusEth).div(surplusEth.add(totalLendingAmount));
        require(surplusContribution > 0, "Surplus is 0");
        investors[beneficiary].surplusEthReclaimed = true;
        reclaimedSurpluses = reclaimedSurpluses.add(1);
        emit onSurplusReclaimed(beneficiary, surplusContribution);
        doReclaim(beneficiary, surplusContribution);
    }

    function reclaimContributionWithInterest(address beneficiary) external {
        require(state == LendingState.ContributionReturned, "State is not ContributionReturned");
        require(!investors[beneficiary].isCompensated, "Lender already compensated");
        uint256 contribution = checkInvestorReturns(beneficiary);
        require(contribution > 0, "Contribution is 0");
        investors[beneficiary].isCompensated = true;
        reclaimedContributions = reclaimedContributions.add(1);
        doReclaim(beneficiary, contribution);
    }

    function reclaimLocalNodeFee() external {
        require(state == LendingState.ContributionReturned, "State is not ContributionReturned");
        require(localNodeFeeReclaimed == false, "Local Node's fee already reclaimed");
        uint256 fee = totalLendingFiatAmount.mul(localNodeFee).mul(interestBaseUint).div(interestBasePercent).div(borrowerReturnEthPerFiatRate);
        require(fee > 0, "Local Node's team fee is 0");
        localNodeFeeReclaimed = true;
        doReclaim(localNode, fee);
    }

    function reclaimEthicHubTeamFee() external {
        require(state == LendingState.ContributionReturned, "State is not ContributionReturned");
        require(ethicHubTeamFeeReclaimed == false, "EthicHub team's fee already reclaimed");
        uint256 fee = totalLendingFiatAmount.mul(ethichubFee).mul(interestBaseUint).div(interestBasePercent).div(borrowerReturnEthPerFiatRate);
        require(fee > 0, "EthicHub's team fee is 0");
        ethicHubTeamFeeReclaimed = true;
        doReclaim(ethicHubTeam, fee);
    }

    function reclaimLeftoverEth() external checkIfArbiter {
        require(state == LendingState.ContributionReturned || state == LendingState.Default, "State is not ContributionReturned or Default");
        require(localNodeFeeReclaimed, "Local Node fee is not reclaimed");
        require(ethicHubTeamFeeReclaimed, "Team fee is not reclaimed");
        require(investorCount == reclaimedContributions, "Not all investors have reclaimed their share");
        if(surplusEth > 0) {
            require(investorCount == reclaimedSurpluses, "Not all investors have reclaimed their surplus");
        }
        doReclaim(ethicHubTeam, address(this).balance);
    }

    function doReclaim(address target, uint256 amount) internal {
        if ( address(this).balance < amount ) {
            target.transfer(address(this).balance);
        } else {
            target.transfer(amount);
        }
    }

    function returnBorrowedEth() internal {
        require(state == LendingState.AwaitingReturn, "State is not AwaitingReturn");
        require(msg.sender == borrower, "Only the borrower can repay");
        require(borrowerReturnEthPerFiatRate > 0, "Second exchange rate not set");
        bool projectRepayed = false;
        uint excessRepayment = 0;
        uint newReturnedEth = 0;
        emit onReturnAmount(msg.sender, msg.value);
        (newReturnedEth, projectRepayed, excessRepayment) = calculatePaymentGoal(borrowerReturnAmount(), returnedEth, msg.value);
        returnedEth = newReturnedEth;
        if (projectRepayed == true) {
            borrowerReturnDays = getDaysPassedBetweenDates(fundingEndTime, now);
            state = LendingState.ContributionReturned;
            emit StateChange(uint(state));
            updateReputation();
        }
        if (excessRepayment > 0) {
            msg.sender.transfer(excessRepayment);
        }
    }



     
     
    function contributeForAddress(address contributor) external checkProfileRegistered('paymentGateway') payable whenNotPaused {
        contributeWithAddress(contributor);
    }

     
     
     
     
     
    function contributeWithAddress(address contributor) internal whenNotPaused {
        require(state == LendingState.AcceptingContributions, "state is not AcceptingContributions");
        require(isContribPeriodRunning(), "can't contribute outside contribution period");

        uint oldTotalContributed = totalContributed;
        uint newTotalContributed = 0;
        uint excessContribValue = 0;
        (newTotalContributed, capReached, excessContribValue) = calculatePaymentGoal(totalLendingAmount, oldTotalContributed, msg.value);
        totalContributed = newTotalContributed;
        if (capReached) {
            fundingEndTime = now;
            emit onCapReached(fundingEndTime);
        }
        if (investors[contributor].amount == 0) {
            investorCount = investorCount.add(1);
        }
        if (excessContribValue > 0) {
            contributor.transfer(excessContribValue);
            investors[contributor].amount = investors[contributor].amount.add(msg.value).sub(excessContribValue);
            emit onContribution(newTotalContributed, contributor, msg.value.sub(excessContribValue), investorCount);
        } else {
            investors[contributor].amount = investors[contributor].amount.add(msg.value);
            emit onContribution(newTotalContributed, contributor, msg.value, investorCount);
        }
    }

     
    function calculatePaymentGoal(uint goal, uint oldTotal, uint contribValue) internal pure returns(uint, bool, uint) {
        uint newTotal = oldTotal.add(contribValue);
        bool goalReached = false;
        uint excess = 0;
        if (newTotal >= goal && oldTotal < goal) {
            goalReached = true;
            excess = newTotal.sub(goal);
            contribValue = contribValue.sub(excess);
            newTotal = goal;
        }
        return (newTotal, goalReached, excess);
    }

    function sendFundsToBorrower() external onlyOwnerOrLocalNode {
       
        require(state == LendingState.AcceptingContributions);
        require(capReached);
        state = LendingState.ExchangingToFiat;
        emit StateChange(uint(state));
        borrower.transfer(totalContributed);
    }

    function updateReputation() internal {
        EthicHubReputationInterface reputation = EthicHubReputationInterface(
            ethicHubStorage.getAddress(keccak256(abi.encodePacked("contract.name", "reputation")))
            );
        require(reputation != address(0));
        uint delayDays = getDelayDays(now);
        if (delayDays > 0) {
            ethicHubStorage.setUint(keccak256(abi.encodePacked("lending.delayDays", this)), delayDays);
            reputation.burnReputation(delayDays);
        } else {
            uint completedProjectsByTier = ethicHubStorage.getUint(keccak256(abi.encodePacked("community.completedProjectsByTier", this, tier))).add(1);
            ethicHubStorage.setUint(keccak256(abi.encodePacked("community.completedProjectsByTier", this, tier)), completedProjectsByTier);
            reputation.incrementReputation(completedProjectsByTier);
        }
    }
     
    function getDelayDays(uint date) public view returns(uint) {
        uint lendingDaysSeconds = lendingDays * 1 days;
        uint defaultTime = fundingEndTime.add(lendingDaysSeconds);
        if (date < defaultTime) {
            return 0;
        } else {
            return getDaysPassedBetweenDates(defaultTime, date);
        }
    }

     
    function getDaysPassedBetweenDates(uint firstDate, uint lastDate) public pure returns(uint) {
        require(firstDate <= lastDate, "lastDate must be bigger than firstDate");
        return lastDate.sub(firstDate).div(60).div(60).div(24);
    }

     
     
    function lendingInterestRatePercentage() public view returns(uint256){
        return annualInterest.mul(interestBaseUint)
             
            .mul(getDaysPassedBetweenDates(fundingEndTime, now)).div(365)
            .add(localNodeFee.mul(interestBaseUint))
            .add(ethichubFee.mul(interestBaseUint))
            .add(interestBasePercent);
    }

     
    function investorInterest() public view returns(uint256){
        return annualInterest.mul(interestBaseUint).mul(borrowerReturnDays).div(365).add(interestBasePercent);
    }

    function borrowerReturnFiatAmount() public view returns(uint256) {
        return totalLendingFiatAmount.mul(lendingInterestRatePercentage()).div(interestBasePercent);
    }

    function borrowerReturnAmount() public view returns(uint256) {
        return borrowerReturnFiatAmount().div(borrowerReturnEthPerFiatRate);
    }

    function isContribPeriodRunning() public view returns(bool) {
        return fundingStartTime <= now && fundingEndTime > now && !capReached;
    }

    function checkInvestorContribution(address investor) public view returns(uint256){
        return investors[investor].amount;
    }

    function checkInvestorReturns(address investor) public view returns(uint256) {
        uint256 investorAmount = 0;
        if (state == LendingState.ContributionReturned) {
            investorAmount = investors[investor].amount;
            if (surplusEth > 0){
                investorAmount = investors[investor].amount.mul(totalLendingAmount).div(totalContributed);
            }
            return investorAmount.mul(initialEthPerFiatRate).mul(investorInterest()).div(borrowerReturnEthPerFiatRate).div(interestBasePercent);
        } else if (state == LendingState.Default){
            investorAmount = investors[investor].amount;
             
            return investorAmount.mul(returnedEth).div(totalLendingAmount);
        } else {
            return 0;
        }
    }

    function getMaxDelayDays() public view returns(uint256){
        return ethicHubStorage.getUint(keccak256(abi.encodePacked("lending.maxDelayDays", this)));
    }

    function getUserContributionReclaimStatus(address userAddress) public view returns(bool isCompensated, bool surplusEthReclaimed){
        isCompensated = investors[userAddress].isCompensated;
        surplusEthReclaimed = investors[userAddress].surplusEthReclaimed;
    }
}