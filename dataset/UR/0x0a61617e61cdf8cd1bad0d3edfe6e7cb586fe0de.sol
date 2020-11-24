 

pragma solidity 0.5.0;

 
 
 

 

 
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
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
}

 

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter);
    }
}

 

contract ClusterRole {
    address payable private _cluster;

     
    modifier onlyCluster() {
        require(isCluster(), "onlyCluster: only cluster can call this method.");
        _;
    }

     
    constructor () internal {
        _cluster = msg.sender;
    }

     
    function cluster() public view returns (address payable) {
        return _cluster;
    }

     
    function isCluster() public view returns (bool) {
        return msg.sender == _cluster;
    }
}

 

contract OperatorRole {
    address payable private _operator;

    event OwnershipTransferred(address indexed previousOperator, address indexed newOperator);

     
    modifier onlyOperator() {
        require(isOperator(), "onlyOperator: only the operator can call this method.");
        _;
    }

     
    constructor (address payable operator) internal {
        _operator = operator;
        emit OwnershipTransferred(address(0), operator);
    }

     
    function transferOwnership(address payable newOperator) external onlyOperator {
        _transferOwnership(newOperator);
    }

     
    function _transferOwnership(address payable newOperator) private {
        require(newOperator != address(0), "_transferOwnership: the address of new operator is not valid.");
        emit OwnershipTransferred(_operator, newOperator);
        _operator = newOperator;
    }

     
    function operator() public view returns (address payable) {
        return _operator;
    }

     
    function isOperator() public view returns (bool) {
        return msg.sender == _operator;
    }
}

 

 
contract Crowdsale is ReentrancyGuard, ClusterRole, OperatorRole {
    using SafeMath for uint256;

    IERC20 internal _token;

     
    uint256 private _fee;
    uint256 private _rate;
    uint256 private _minInvestmentAmount;

     
    uint256 internal _weiRaised;
    uint256 internal _tokensSold;

     
    address private _newContract;
    bool private _emergencyExitCalled;

    address[] private _investors;

     
    struct Investor {
        uint256 eth;
        uint256 tokens;
        uint256 withdrawnEth;
        uint256 withdrawnTokens;
        bool refunded;
    }

    mapping(address => Investor) internal _balances;

     
    struct Bonus {
        uint256 amount;
        uint256 finishTimestamp;
    }

    Bonus[] private _bonuses;

    event Deposited(address indexed beneficiary, uint256 indexed weiAmount, uint256 indexed tokensAmount, uint256 fee);
    event EthTransfered(address indexed beneficiary,uint256 weiAmount);
    event TokensTransfered(address indexed beneficiary, uint256 tokensAmount);
    event Refunded(address indexed beneficiary, uint256 indexed weiAmount);
    event EmergencyExitCalled(address indexed newContract, uint256 indexed tokensAmount, uint256 indexed weiAmount);

     
    constructor (
        uint256 rate,
        address token,
        address payable operator,
        uint256[] memory bonusFinishTimestamp,
        uint256[] memory bonuses,
        uint256 minInvestmentAmount,
        uint256 fee
        ) internal OperatorRole(operator) {
        if (bonuses.length > 0) {
            for (uint256 i = 0; i < bonuses.length; i++) {
                if (i != 0) {
                    require(bonusFinishTimestamp[i] > bonusFinishTimestamp[i - 1], "Crowdsale: invalid bonus finish timestamp.");
                }

                Bonus memory bonus = Bonus(bonuses[i], bonusFinishTimestamp[i]);
                _bonuses.push(bonus);
            }
        }

        _rate = rate;
        _token = IERC20(token);
        _minInvestmentAmount = minInvestmentAmount;
        _fee = fee;
    }

     
     
     

     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address beneficiary) public nonReentrant payable {
        uint256 weiAmount = msg.value;

        _preValidatePurchase(beneficiary, weiAmount);

         
        uint256 fee = _calculatePercent(weiAmount, _fee);

         
        uint256 tokensAmount = _calculateTokensAmount(weiAmount);

         
        weiAmount = weiAmount.sub(fee);

        _processPurchase(beneficiary, weiAmount, tokensAmount);

         
        cluster().transfer(fee);

        emit Deposited(beneficiary, weiAmount, tokensAmount, fee);
    }

     
    function emergencyExit(address payable newContract) public {
        require(newContract != address(0), "emergencyExit: invalid new contract address.");
        require(isCluster() || isOperator(), "emergencyExit: only operator or cluster can call this method.");

        if (isCluster()) {
            _emergencyExitCalled = true;
            _newContract = newContract;
        } else if (isOperator()) {
            require(_emergencyExitCalled == true, "emergencyExit: the cluster need to call this method first.");
            require(_newContract == newContract, "emergencyExit: the newContract address is not the same address with clusters newContract.");

            uint256 allLockedTokens = _token.balanceOf(address(this));
            _withdrawTokens(newContract, allLockedTokens);

            uint256 allLocketETH = address(this).balance;
            _withdrawEther(newContract, allLocketETH);

            emit EmergencyExitCalled(newContract, allLockedTokens, allLocketETH);
        }
    }

     
     
     

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(weiAmount >= _minInvestmentAmount, "_preValidatePurchase: msg.amount should be bigger then _minInvestmentAmount.");
        require(beneficiary != address(0), "_preValidatePurchase: invalid beneficiary address.");
        require(_emergencyExitCalled == false, "_preValidatePurchase: the crowdsale contract address was transfered.");
    }

     
    function _calculatePercent(uint256 amount, uint256 percent) internal pure returns (uint256) {
        return amount.mul(percent).div(100);
    }

     
    function _calculateTokensAmount(uint256 weiAmount) internal view returns (uint256) {
        uint256 tokensAmount = weiAmount.mul(_rate);

        for (uint256 i = 0; i < _bonuses.length; i++) {
			if (block.timestamp <= _bonuses[i].finishTimestamp) {
			    uint256 bonusAmount = _calculatePercent(tokensAmount, _bonuses[i].amount);
			    tokensAmount = tokensAmount.add(bonusAmount);
			    break;
			}
		}

        return tokensAmount;
    }

     
    function _processPurchase(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal {
         
        _weiRaised = _weiRaised.add(weiAmount);
        _tokensSold = _tokensSold.add(tokenAmount);

         
        if (_balances[beneficiary].eth == 0 && _balances[beneficiary].refunded == false) {
            _investors.push(beneficiary);
        }

        _balances[beneficiary].eth = _balances[beneficiary].eth.add(weiAmount);
        _balances[beneficiary].tokens = _balances[beneficiary].tokens.add(tokenAmount);
    }

     
     
     

    function _withdrawTokens(address beneficiary, uint256 amount) internal {
        _token.transfer(beneficiary, amount);
        emit TokensTransfered(beneficiary, amount);
    }

    function _withdrawEther(address payable beneficiary, uint256 amount) internal {
        beneficiary.transfer(amount);
        emit EthTransfered(beneficiary, amount);
    }

     
     
     

     
    function getCrowdsaleDetails() public view returns (uint256, address, uint256, uint256, uint256[] memory finishTimestamps, uint256[] memory bonuses) {
        finishTimestamps = new uint256[](_bonuses.length);
        bonuses = new uint256[](_bonuses.length);

        for (uint256 i = 0; i < _bonuses.length; i++) {
            finishTimestamps[i] = _bonuses[i].finishTimestamp;
            bonuses[i] = _bonuses[i].amount;
        }

        return (
            _rate,
            address(_token),
            _minInvestmentAmount,
            _fee,
            finishTimestamps,
            bonuses
        );
    }

     
    function getInvestorBalances(address investor) public view returns (uint256, uint256, uint256, uint256, bool) {
        return (
            _balances[investor].eth,
            _balances[investor].tokens,
            _balances[investor].withdrawnEth,
            _balances[investor].withdrawnTokens,
            _balances[investor].refunded
        );
    }

     
    function getInvestorsArray() public view returns (address[] memory investors) {
        uint256 investorsAmount = _investors.length;
        investors = new address[](investorsAmount);

        for (uint256 i = 0; i < investorsAmount; i++) {
            investors[i] = _investors[i];
        }

        return investors;
    }

     
    function getRaisedWei() public view returns (uint256) {
        return _weiRaised;
    }

     
    function getSoldTokens() public view returns (uint256) {
        return _tokensSold;
    }

     
    function isInvestor(address sender) public view returns (bool) {
        return _balances[sender].eth != 0 && _balances[sender].tokens != 0;
    }
}

 

 
contract TimedCrowdsale is Crowdsale {
    uint256 private _openingTime;
    uint256 private _closingTime;

     
    modifier onlyWhileOpen() {
        require(isOpen(), "onlyWhileOpen: investor can call this method only when crowdsale is open.");
        _;
    }

     
    constructor (
        uint256 rate,
        address token,
        uint256 openingTime,
        uint256 closingTime,
        address payable operator,
        uint256[] memory bonusFinishTimestamp,
        uint256[] memory bonuses,
        uint256 minInvestmentAmount,
        uint256 fee
        ) internal Crowdsale(rate, token, operator, bonusFinishTimestamp, bonuses, minInvestmentAmount, fee) {
        if (bonusFinishTimestamp.length > 0) {
            require(bonusFinishTimestamp[0] >= openingTime, "TimedCrowdsale: the opening time is smaller then the first bonus timestamp.");
            require(bonusFinishTimestamp[bonusFinishTimestamp.length - 1] <= closingTime, "TimedCrowdsale: the closing time is smaller then the last bonus timestamp.");
        }

        _openingTime = openingTime;
        _closingTime = closingTime;
    }

     
     
     

     
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal onlyWhileOpen view {
        super._preValidatePurchase(beneficiary, weiAmount);
    }

     
     
     

     
    function refundETH() external onlyWhileOpen {
        require(isInvestor(msg.sender), "refundETH: only the active investors can call this method.");

        uint256 weiAmount = _balances[msg.sender].eth;
        uint256 tokensAmount = _balances[msg.sender].tokens;

        _balances[msg.sender].eth = 0;
        _balances[msg.sender].tokens = 0;

        if (_balances[msg.sender].refunded == false) {
            _balances[msg.sender].refunded = true;
        }

        _weiRaised = _weiRaised.sub(weiAmount);
        _tokensSold = _tokensSold.sub(tokensAmount);

        msg.sender.transfer(weiAmount);

        emit Refunded(msg.sender, weiAmount);
    }

     
     
     

     
    function getOpeningTime() public view returns (uint256) {
        return _openingTime;
    }

     
    function getClosingTime() public view returns (uint256) {
        return _closingTime;
    }

     
    function isOpen() public view returns (bool) {
        return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
    }

     
    function hasClosed() public view returns (bool) {
        return block.timestamp > _closingTime;
    }
}

 

 
contract ResponsibleCrowdsale is TimedCrowdsale {
    uint256 private _cycleId;
    uint256 private _milestoneId;
    uint256 private constant _timeForDisputs = 10 minutes;

    uint256 private _allCyclesTokensPercent;
    uint256 private _allCyclesEthPercent;

    bool private _operatorTransferedTokens;

    enum MilestoneStatus { PENDING, DISPUTS_PERIOD, APPROVED }
    enum InvestorDisputeState { NO_DISPUTES, SUBMITTED, CLOSED, WINNED }

    struct Cycle {
        uint256 tokenPercent;
        uint256 ethPercent;
        bytes32[] milestones;
    }

    struct Dispute {
        uint256 activeDisputes;
        address[] winnedAddressList;
        mapping(address => InvestorDisputeState) investorDispute;
    }

    struct Milestone {
        bytes32 name;
        uint256 startTimestamp;
        uint256 disputesOpeningTimestamp;
        uint256 cycleId;
        uint256 tokenPercent;
        uint256 ethPercent;
        Dispute disputes;
        bool operatorWasWithdrawn;
        bool validHash;
        mapping(address => bool) userWasWithdrawn;
    }

     
    mapping(uint256 => Cycle) private _cycles;

     
    mapping(uint256 => bytes32) private _milestones;

     
    mapping(bytes32 => Milestone) private _milestoneDetails;

    event MilestoneInvestmentsWithdrawn(bytes32 indexed milestoneHash, uint256 weiAmount, uint256 tokensAmount);
    event MilestoneResultWithdrawn(bytes32 indexed milestoneHash, address indexed investor, uint256 weiAmount, uint256 tokensAmount);

    constructor (
        uint256 rate,
        address token,
        uint256 openingTime,
        uint256 closingTime,
        address payable operator,
        uint256[] memory bonusFinishTimestamp,
        uint256[] memory bonuses,
        uint256 minInvestmentAmount,
        uint256 fee
        ) public TimedCrowdsale(rate, token, openingTime, closingTime, operator, bonusFinishTimestamp, bonuses, minInvestmentAmount, fee) {}

     
     
     

    function addCycle(
        uint256 tokenPercent,
        uint256 ethPercent,
        bytes32[] memory milestonesNames,
        uint256[] memory milestonesTokenPercent,
        uint256[] memory milestonesEthPercent,
        uint256[] memory milestonesStartTimestamps
        ) public onlyOperator returns (bool) {
         
        require(tokenPercent > 0 && tokenPercent < 100, "addCycle: the Token percent of the cycle should be bigger then 0 and smaller then 100.");
        require(ethPercent > 0 && ethPercent < 100, "addCycle: the ETH percent of the cycle should be bigger then 0 and smaller then 100.");
        require(milestonesNames.length > 0, "addCycle: the milestones length should be bigger than 0.");
        require(milestonesTokenPercent.length == milestonesNames.length, "addCycle: the milestonesTokenPercent length should be equal to milestonesNames length.");
        require(milestonesEthPercent.length == milestonesTokenPercent.length, "addCycle: the milestonesEthPercent length should be equal to milestonesTokenPercent length.");
        require(milestonesStartTimestamps.length == milestonesEthPercent.length, "addCycle: the milestonesFinishTimestamps length should be equal to milestonesEthPercent length.");

         
        require(_allCyclesTokensPercent + tokenPercent <= 100, "addCycle: the calculated amount of token percents is bigger then 100.");
        require(_allCyclesEthPercent + ethPercent <= 100, "addCycle: the calculated amount of eth percents is bigger then 100.");

        if (_cycleId == 0) {
            require(tokenPercent <= 25 && ethPercent <= 25, "addCycle: for security reasons for the first cycle operator can withdraw only less than 25 percent of investments.");
        }

        _cycles[_cycleId] = Cycle(
            tokenPercent,
            ethPercent,
            new bytes32[](0)
        );

        uint256 allMilestonesTokensPercent;
        uint256 allMilestonesEthPercent;

        for (uint256 i = 0; i < milestonesNames.length; i++) {
            if (i == 0 && _milestoneId == 0) {
                 
                require(milestonesStartTimestamps[i] > getClosingTime(), "addCycle: the first milestone timestamp should be bigger then crowdsale closing time.");
            } else if (i == 0 && _milestoneId > 0) {
                 
                uint256 previousCycleLastMilestoneStartTimestamp =  _milestoneDetails[_milestones[_milestoneId - 1]].startTimestamp;
                require(milestonesStartTimestamps[i] > previousCycleLastMilestoneStartTimestamp, "addCycle: the first timestamp of this milestone should be bigger then his previus milestons last timestamp.");
                require(milestonesStartTimestamps[i] >= block.timestamp + _timeForDisputs, "addCycle: the second cycle should be start a minimum 3 days after this transaction.");
            } else if (i != 0) {
                 
                require(milestonesStartTimestamps[i] > milestonesStartTimestamps[i - 1], "addCycle: each timestamp should be bigger then his previus one.");
            }

             
            require(milestonesTokenPercent[i] > 0 && milestonesTokenPercent[i] <= 100, "addCycle: the token percent of milestone should be bigger then 0 and smaller from 100.");
            require(milestonesEthPercent[i] > 0 && milestonesEthPercent[i] <= 100, "addCycle: the ETH percent of milestone should be bigger then 0 and smaller from 100.");

             
            bytes32 hash = _generateHash(
                milestonesNames[i],
                milestonesStartTimestamps[i]
            );

             
            uint256 disputesOpeningTimestamp = milestonesStartTimestamps[i] - _timeForDisputs;

             
            if (i == 0 && _milestoneId == 0) {
                disputesOpeningTimestamp = milestonesStartTimestamps[i];
            }

             
            _cycles[_cycleId].milestones.push(hash);
            _milestones[i + _milestoneId] = hash;
            _milestoneDetails[hash] = Milestone(
                milestonesNames[i],                  
                milestonesStartTimestamps[i],        
                disputesOpeningTimestamp,            
                _cycleId,                            
                milestonesTokenPercent[i],           
                milestonesEthPercent[i],             
                Dispute(0, new address[](0)),        
                false,                               
                true                                 
            );

            allMilestonesTokensPercent += milestonesTokenPercent[i];
            allMilestonesEthPercent += milestonesEthPercent[i];
        }

         
        require(allMilestonesTokensPercent == 100, "addCycle: the calculated amount of Token percent should be equal to 100.");
        require(allMilestonesEthPercent == 100, "addCycle: the calculated amount of ETH percent should be equal to 100.");

        _allCyclesTokensPercent += tokenPercent;
        _allCyclesEthPercent += ethPercent;

        _cycleId++;
        _milestoneId += milestonesNames.length;

        return true;
    }

    function collectMilestoneInvestment(bytes32 hash) public onlyOperator {
        require(_milestoneDetails[hash].validHash, "collectMilestoneInvestment: the milestone hash is not valid.");
        require(_milestoneDetails[hash].operatorWasWithdrawn == false, "collectMilestoneInvestment: the operator already withdrawn his funds.");
        require(getMilestoneStatus(hash) == MilestoneStatus.APPROVED, "collectMilestoneInvestment: the time for collecting funds is not started yet.");
        require(isMilestoneHasActiveDisputes(hash) == false, "collectMilestoneInvestment: the milestone has unsolved disputes.");
        require(_hadOperatorTransferredTokens(), "collectMilestoneInvestment: the operator need to transfer sold tokens to this contract for receiving investments.");

        _milestoneDetails[hash].operatorWasWithdrawn = true;

        uint256 milestoneRefundedTokens;
        uint256 milestoneInvestmentWei = _calculateEthAmountByMilestone(getRaisedWei(), hash);
        uint256 winnedDisputesAmount = _milestoneDetails[hash].disputes.winnedAddressList.length;

        if (winnedDisputesAmount > 0) {
            for (uint256 i = 0; i < winnedDisputesAmount; i++) {
                address winnedInvestor = _milestoneDetails[hash].disputes.winnedAddressList[i];

                uint256 investorWeiForMilestone = _calculateEthAmountByMilestone(_balances[winnedInvestor].eth, hash);
                uint256 investorTokensForMilestone = _calculateTokensAmountByMilestone(_balances[winnedInvestor].tokens, hash);

                milestoneInvestmentWei = milestoneInvestmentWei.sub(investorWeiForMilestone);
                milestoneRefundedTokens = milestoneRefundedTokens.add(investorTokensForMilestone);
            }
        }

        _withdrawEther(operator(), milestoneInvestmentWei);

        if (milestoneRefundedTokens != 0) {
            _withdrawTokens(operator(), milestoneRefundedTokens);
        }

        emit MilestoneInvestmentsWithdrawn(hash, milestoneInvestmentWei, milestoneRefundedTokens);
    }

     
     
     

    function openDispute(bytes32 hash, address investor) external onlyCluster returns (bool) {
        _milestoneDetails[hash].disputes.investorDispute[investor] = InvestorDisputeState.SUBMITTED;
        _milestoneDetails[hash].disputes.activeDisputes++;
        return true;
    }

    function solveDispute(bytes32 hash, address investor, bool investorWins) external onlyCluster {
        require(isMilestoneHasActiveDisputes(hash) == true, "solveDispute: no active disputs available.");

        if (investorWins == true) {
            _milestoneDetails[hash].disputes.investorDispute[investor] = InvestorDisputeState.WINNED;
            _milestoneDetails[hash].disputes.winnedAddressList.push(investor);
        } else {
            _milestoneDetails[hash].disputes.investorDispute[investor] = InvestorDisputeState.CLOSED;
        }

        _milestoneDetails[hash].disputes.activeDisputes--;
    }

     
     
     

    function collectMilestoneResult(bytes32 hash) public {
        require(isInvestor(msg.sender), "collectMilestoneResult: only the active investors can call this method.");
        require(_milestoneDetails[hash].validHash, "collectMilestoneResult: the milestone hash is not valid.");
        require(getMilestoneStatus(hash) == MilestoneStatus.APPROVED, "collectMilestoneResult: the time for collecting funds is not started yet.");
        require(didInvestorWithdraw(hash, msg.sender) == false, "collectMilestoneResult: the investor already withdrawn his tokens.");
        require(_milestoneDetails[hash].disputes.investorDispute[msg.sender] != InvestorDisputeState.SUBMITTED, "collectMilestoneResult: the investor has unsolved disputes.");
        require(_hadOperatorTransferredTokens(), "collectMilestoneInvestment: the operator need to transfer sold tokens to this contract for receiving investments.");

        _milestoneDetails[hash].userWasWithdrawn[msg.sender] = true;

        uint256 investorBalance;
        uint256 tokensToSend;
        uint256 winnedWeis;

        if (_milestoneDetails[hash].disputes.investorDispute[msg.sender] != InvestorDisputeState.WINNED) {
            investorBalance = _balances[msg.sender].tokens;
            tokensToSend = _calculateTokensAmountByMilestone(investorBalance, hash);

             
            _withdrawTokens(msg.sender, tokensToSend);
            _balances[msg.sender].withdrawnTokens += tokensToSend;
        } else {
            investorBalance = _balances[msg.sender].eth;
            winnedWeis = _calculateEthAmountByMilestone(investorBalance, hash);

             
            _withdrawEther(msg.sender, winnedWeis);
            _balances[msg.sender].withdrawnEth += winnedWeis;
        }

        emit MilestoneResultWithdrawn(hash, msg.sender, winnedWeis, tokensToSend);
    }

     
     
     

    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        require(_cycleId > 0, "_preValidatePurchase: the cycles/milestones is not setted.");
        super._preValidatePurchase(beneficiary, weiAmount);
    }

    function _generateHash(bytes32 name, uint256 timestamp) private view returns (bytes32) {
         
        return keccak256(abi.encodePacked(name, timestamp, address(this)));
    }

    function _calculateEthAmountByMilestone(uint256 weiAmount, bytes32 milestone) private view returns (uint256) {
        uint256 cycleId = _milestoneDetails[milestone].cycleId;
        uint256 cyclePercent = _cycles[cycleId].ethPercent;
        uint256 milestonePercent = _milestoneDetails[milestone].ethPercent;

        uint256 amount = _calculatePercent(milestonePercent, _calculatePercent(weiAmount, cyclePercent));
        return amount;
    }

    function _calculateTokensAmountByMilestone(uint256 tokens, bytes32 milestone) private view returns (uint256) {
        uint256 cycleId = _milestoneDetails[milestone].cycleId;
        uint256 cyclePercent = _cycles[cycleId].tokenPercent;
        uint256 milestonePercent = _milestoneDetails[milestone].tokenPercent;

        uint256 amount = _calculatePercent(milestonePercent, _calculatePercent(tokens, cyclePercent));
        return amount;
    }

    function _hadOperatorTransferredTokens() private returns (bool) {
         
        if (_token.balanceOf(address(this)) == getSoldTokens()) {
            _operatorTransferedTokens = true;
            return true;
        } else if (_operatorTransferedTokens == true) {
            return true;
        } else {
            return false;
        }
    }

     
     
     

    function getCyclesAmount() external view returns (uint256) {
        return _cycleId;
    }

    function getCycleDetails(uint256 cycleId) external view returns (uint256, uint256, bytes32[] memory) {
        return (
            _cycles[cycleId].tokenPercent,
            _cycles[cycleId].ethPercent,
            _cycles[cycleId].milestones
        );
    }

    function getMilestonesHashes() external view returns (bytes32[] memory milestonesHashArray) {
        milestonesHashArray = new bytes32[](_milestoneId);

        for (uint256 i = 0; i < _milestoneId; i++) {
            milestonesHashArray[i] = _milestones[i];
        }

        return milestonesHashArray;
    }

    function getMilestoneDetails(bytes32 hash) external view returns (bytes32, uint256, uint256, uint256, uint256, uint256, uint256, MilestoneStatus status) {
        Milestone memory mil = _milestoneDetails[hash];
        status = getMilestoneStatus(hash);
        return (
            mil.name,
            mil.startTimestamp,
            mil.disputesOpeningTimestamp,
            mil.cycleId,
            mil.tokenPercent,
            mil.ethPercent,
            mil.disputes.activeDisputes,
            status
        );
    }

    function getMilestoneStatus(bytes32 hash) public view returns (MilestoneStatus status) {
         
        if (block.timestamp >= _milestoneDetails[hash].startTimestamp) {
            return MilestoneStatus.APPROVED;
        } else if (block.timestamp > _milestoneDetails[hash].disputesOpeningTimestamp) {
                return MilestoneStatus.DISPUTS_PERIOD;
        } else {
            return MilestoneStatus.PENDING;
        }
    }

    function getCycleTotalPercents() external view returns (uint256, uint256) {
        return (
            _allCyclesTokensPercent,
            _allCyclesEthPercent
        );
    }

    function canInvestorOpenNewDispute(bytes32 hash, address investor) public view returns (bool) {
        InvestorDisputeState state = _milestoneDetails[hash].disputes.investorDispute[investor];
        return state == InvestorDisputeState.NO_DISPUTES || state == InvestorDisputeState.CLOSED;
    }

    function isMilestoneHasActiveDisputes(bytes32 hash) public view returns (bool) {
        return _milestoneDetails[hash].disputes.activeDisputes > 0;
    }

    function didInvestorOpenedDisputeBefore(bytes32 hash, address investor) public view returns (bool) {
        return _milestoneDetails[hash].disputes.investorDispute[investor] != InvestorDisputeState.NO_DISPUTES;
    }

    function didInvestorWithdraw(bytes32 hash, address investor) public view returns (bool) {
        return _milestoneDetails[hash].userWasWithdrawn[investor];
    }
}

 

library CrowdsaleDeployer {
    function addCrowdsale(
        uint256 rate,
        address token,
        uint256 openingTime,
        uint256 closingTime,
        address payable operator,
        uint256[] calldata bonusFinishTimestamp,
        uint256[] calldata bonuses,
        uint256 minInvestmentAmount,
        uint256 fee
        ) external returns (address) {
         return address(new ResponsibleCrowdsale(rate, token, openingTime, closingTime, operator, bonusFinishTimestamp, bonuses, minInvestmentAmount, fee));
    }
}

 
 
 

 

library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

     
    function add(Role storage role, address account) internal {
        require(account != address(0));
        require(!has(role, account));

        role.bearer[account] = true;
    }

     
    function remove(Role storage role, address account) internal {
        require(account != address(0));
        require(has(role, account));

        role.bearer[account] = false;
    }

     
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0));
        return role.bearer[account];
    }
}

 

contract ArbiterRole is ClusterRole {
    using Roles for Roles.Role;

    uint256 private _arbitersAmount;

    event ArbiterAdded(address indexed arbiter);
    event ArbiterRemoved(address indexed arbiter);

    Roles.Role private _arbiters;

    modifier onlyArbiter() {
        require(isArbiter(msg.sender), "onlyArbiter: only arbiter can call this method.");
        _;
    }

     
     
     

    function addArbiter(address arbiter) public onlyCluster {
        _addArbiter(arbiter);
        _arbitersAmount++;
    }

    function removeArbiter(address arbiter) public onlyCluster {
        _removeArbiter(arbiter);
        _arbitersAmount--;
    }

     
     
     

    function _addArbiter(address arbiter) private {
        _arbiters.add(arbiter);
        emit ArbiterAdded(arbiter);
    }

    function _removeArbiter(address arbiter) private {
        _arbiters.remove(arbiter);
        emit ArbiterRemoved(arbiter);
    }

     
     
     

    function isArbiter(address account) public view returns (bool) {
        return _arbiters.has(account);
    }

    function getArbitersAmount() external view returns (uint256) {
        return _arbitersAmount;
    }
}

 

interface ICluster {
    function solveDispute(address crowdsale, bytes32 milestoneHash, address investor, bool investorWins) external;
}

 

contract ArbitersPool is ArbiterRole {
    uint256 private _disputsAmount;
    uint256 private constant _necessaryVoices = 3;

    enum DisputeStatus { WAITING, SOLVED }
    enum Choice { OPERATOR_WINS, INVESTOR_WINS }

    ICluster private _clusterInterface;

    struct Vote {
        address arbiter;
        Choice choice;
    }

    struct Dispute {
        address investor;
        address crowdsale;
        bytes32 milestoneHash;
        string reason;
        uint256 votesAmount;
        DisputeStatus status;
        mapping(address => bool) hasVoted;
        mapping(uint256 => Vote) choices;
    }

    mapping(bytes32 => uint256[]) private _disputesByMilestone;
    mapping(uint256 => Dispute) private _disputesById;

    event Voted(uint256 indexed disputeId, address indexed arbiter, Choice choice);
    event NewDisputeCreated(uint256 disputeId, address indexed crowdsale, bytes32 indexed hash, address indexed investor);
    event DisputeSolved(uint256 disputeId, Choice choice, address indexed crowdsale, bytes32 indexed hash, address indexed investor);

    constructor () public {
        _clusterInterface = ICluster(msg.sender);
    }

    function createDispute(bytes32 milestoneHash, address crowdsale, address investor, string calldata reason) external onlyCluster returns (uint256) {
        Dispute memory dispute = Dispute(
            investor,
            crowdsale,
            milestoneHash,
            reason,
            0,
            DisputeStatus.WAITING
        );

        uint256 thisDisputeId = _disputsAmount;
        _disputsAmount++;

        _disputesById[thisDisputeId] = dispute;
        _disputesByMilestone[milestoneHash].push(thisDisputeId);

        emit NewDisputeCreated(thisDisputeId, crowdsale, milestoneHash, investor);

        return thisDisputeId;
    }

    function voteDispute(uint256 id, Choice choice) public onlyArbiter {
        require(_disputsAmount > id, "voteDispute: invalid number of dispute.");
        require(_disputesById[id].hasVoted[msg.sender] == false, "voteDispute: arbiter was already voted.");
        require(_disputesById[id].status == DisputeStatus.WAITING, "voteDispute: dispute was already closed.");
        require(_disputesById[id].votesAmount < _necessaryVoices, "voteDispute: dispute was already voted and finished.");

        _disputesById[id].hasVoted[msg.sender] = true;

         
        _disputesById[id].votesAmount++;

         
        uint256 votesAmount = _disputesById[id].votesAmount;
        _disputesById[id].choices[votesAmount] = Vote(msg.sender, choice);

         
        if (_disputesById[id].votesAmount == 2 && _disputesById[id].choices[0].choice == choice) {
            _executeDispute(id, choice);
        } else if (_disputesById[id].votesAmount == _necessaryVoices) {
            Choice winner = _calculateWinner(id);
            _executeDispute(id, winner);
        }

        emit Voted(id, msg.sender, choice);
    }

     
     
     

    function _calculateWinner(uint256 id) private view returns (Choice choice) {
        uint256 votesForInvestor = 0;
        for (uint256 i = 0; i < _necessaryVoices; i++) {
            if (_disputesById[id].choices[i].choice == Choice.INVESTOR_WINS) {
                votesForInvestor++;
            }
        }

        return votesForInvestor >= 2 ? Choice.INVESTOR_WINS : Choice.OPERATOR_WINS;
    }

    function _executeDispute(uint256 id, Choice choice) private {
        _disputesById[id].status = DisputeStatus.SOLVED;
        _clusterInterface.solveDispute(
            _disputesById[id].crowdsale,
            _disputesById[id].milestoneHash,
            _disputesById[id].investor,
            choice == Choice.INVESTOR_WINS
        );

        emit DisputeSolved(
            id,
            choice,
            _disputesById[id].crowdsale,
            _disputesById[id].milestoneHash,
            _disputesById[id].investor
        );
    }

     
     
     

    function getDisputesAmount() external view returns (uint256) {
        return _disputsAmount;
    }

    function getDisputeDetails(uint256 id) external view returns (bytes32, address, address, string memory, uint256, DisputeStatus status) {
        Dispute memory dispute = _disputesById[id];
        return (
            dispute.milestoneHash,
            dispute.crowdsale,
            dispute.investor,
            dispute.reason,
            dispute.votesAmount,
            dispute.status
        );
    }

    function getMilestoneDisputes(bytes32 hash) external view returns (uint256[] memory disputesIDs) {
        uint256 disputesLength = _disputesByMilestone[hash].length;
        disputesIDs = new uint256[](disputesLength);

        for (uint256 i = 0; i < disputesLength; i++) {
            disputesIDs[i] = _disputesByMilestone[hash][i];
        }

        return disputesIDs;
    }

    function getDisputeVotes(uint256 id) external view returns(address[] memory arbiters, Choice[] memory choices) {
        uint256 votedArbitersAmount = _disputesById[id].votesAmount;
        arbiters = new address[](votedArbitersAmount);
        choices = new Choice[](votedArbitersAmount);

        for (uint256 i = 0; i < votedArbitersAmount; i++) {
            arbiters[i] = _disputesById[id].choices[i].arbiter;
            choices[i] = _disputesById[id].choices[i].choice;
        }

        return (
            arbiters,
            choices
        );
    }

    function hasDisputeSolved(uint256 id) external view returns (bool) {
        return _disputesById[id].status == DisputeStatus.SOLVED;
    }

    function hasArbiterVoted(uint256 id, address arbiter) external view returns (bool) {
        return _disputesById[id].hasVoted[arbiter];
    }
}

 
 
 

 

interface IRICO {
    enum MilestoneStatus { PENDING, DISPUTS_PERIOD, APPROVED }

    function getMilestoneStatus(bytes32 hash) external view returns (MilestoneStatus status);
    
    function getMilestonesHashes() external view returns (bytes32[] memory milestonesHashArray);

    function didInvestorOpenedDisputeBefore(bytes32 hash, address investor) external view returns (bool);

    function isInvestor(address investor) external view returns (bool);

    function canInvestorOpenNewDispute(bytes32 hash, address investor) external view returns (bool);

    function openDispute(bytes32 hash, address investor) external returns (bool);

    function solveDispute(bytes32 hash, address investor, bool investorWins) external;

    function emergencyExit(address payable newContract) external;
}

 

interface IArbitersPool {
    function createDispute(bytes32 milestoneHash, address crowdsale, address investor, string calldata reason) external returns (uint256);

    function addArbiter(address newArbiter) external;

    function renounceArbiter(address arbiter) external;
}

 

contract Ownable {
    address payable private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address payable) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "onlyOwner: only the owner can call this method.");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address payable newOwner) private {
        require(newOwner != address(0), "_transferOwnership: the address of new operator is not valid.");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

contract BackEndRole is Ownable {
    using Roles for Roles.Role;

    event BackEndAdded(address indexed account);
    event BackEndRemoved(address indexed account);

    Roles.Role private _backEnds;

    modifier onlyBackEnd() {
        require(isBackEnd(msg.sender), "onlyBackEnd: only back end address can call this method.");
        _;
    }

    function isBackEnd(address account) public view returns (bool) {
        return _backEnds.has(account);
    }

    function addBackEnd(address account) public onlyOwner {
        _addBackEnd(account);
    }

    function removeBackEnd(address account) public onlyOwner {
        _removeBackEnd(account);
    }

    function _addBackEnd(address account) private {
        _backEnds.add(account);
        emit BackEndAdded(account);
    }

    function _removeBackEnd(address account) private {
        _backEnds.remove(account);
        emit BackEndRemoved(account);
    }
}

 

contract Cluster is BackEndRole {
    uint256 private constant _feeForMoreDisputes = 1 ether;

    address private _arbitersPoolAddress;
    address[] private _crowdsales;

    mapping(address => address[]) private _operatorsContracts;

    IArbitersPool private _arbitersPool;

    event WeiFunded(address indexed sender, uint256 indexed amount);
    event CrowdsaleCreated(
        address crowdsale,
        uint256 rate,
        address token,
        uint256 openingTime,
        uint256 closingTime,
        address operator,
        uint256[] bonusFinishTimestamp,
        uint256[] bonuses,
        uint256 minInvestmentAmount,
        uint256 fee
    );

     
     
     

    constructor () public {
        _arbitersPoolAddress = address(new ArbitersPool());
        _arbitersPool = IArbitersPool(_arbitersPoolAddress);
    }

    function() external payable {
        emit WeiFunded(msg.sender, msg.value);
    }

     
     
     

    function withdrawEth() external onlyOwner {
        owner().transfer(address(this).balance);
    }

    function addArbiter(address newArbiter) external onlyBackEnd {
        require(newArbiter != address(0), "addArbiter: invalid type of address.");

        _arbitersPool.addArbiter(newArbiter);
    }

    function removeArbiter(address arbiter) external onlyBackEnd {
        require(arbiter != address(0), "removeArbiter: invalid type of address.");

        _arbitersPool.renounceArbiter(arbiter);
    }

    function addCrowdsale(
        uint256 rate,
        address token,
        uint256 openingTime,
        uint256 closingTime,
        address payable operator,
        uint256[] calldata bonusFinishTimestamp,
        uint256[] calldata bonuses,
        uint256 minInvestmentAmount,
        uint256 fee
        ) external onlyBackEnd returns (address) {
        require(rate != 0, "addCrowdsale: the rate should be bigger then 0.");
        require(token != address(0), "addCrowdsale: invalid token address.");
        require(openingTime >= block.timestamp, "addCrowdsale: invalid opening time.");
        require(closingTime > openingTime, "addCrowdsale: invalid closing time.");
        require(operator != address(0), "addCrowdsale: the address of operator is not valid.");
        require(bonusFinishTimestamp.length == bonuses.length, "addCrowdsale: the length of bonusFinishTimestamp and bonuses is not equal.");

        address crowdsale = CrowdsaleDeployer.addCrowdsale(
            rate,
            token,
            openingTime,
            closingTime,
            operator,
            bonusFinishTimestamp,
            bonuses,
            minInvestmentAmount,
            fee
        );

         
        _crowdsales.push(crowdsale);
        _operatorsContracts[operator].push(crowdsale);

        emit CrowdsaleCreated(
            crowdsale,
            rate,
            token,
            openingTime,
            closingTime,
            operator,
            bonusFinishTimestamp,
            bonuses,
            minInvestmentAmount,
            fee
        );
        return crowdsale;
    }

     
     
     

    function emergencyExit(address crowdsale, address payable newContract) external onlyOwner {
        IRICO(crowdsale).emergencyExit(newContract);
    }

     
     
     

    function openDispute(address crowdsale, bytes32 hash, string calldata reason) external payable returns (uint256) {
        require(IRICO(crowdsale).isInvestor(msg.sender) == true, "openDispute: sender is not an investor.");
        require(IRICO(crowdsale).canInvestorOpenNewDispute(hash, msg.sender) == true, "openDispute: investor cannot open a new dispute.");
        require(IRICO(crowdsale).getMilestoneStatus(hash) == IRICO.MilestoneStatus.DISPUTS_PERIOD, "openDispute: the period for opening new disputes was finished.");

        if (IRICO(crowdsale).didInvestorOpenedDisputeBefore(hash, msg.sender) == true) {
            require(msg.value == _feeForMoreDisputes, "openDispute: for the second and other disputes investor need to pay 1 ETH fee.");
        }

        IRICO(crowdsale).openDispute(hash, msg.sender);
        uint256 disputeID = _arbitersPool.createDispute(hash, crowdsale, msg.sender, reason);

        return disputeID;
    }

     
     
     

    function solveDispute(address crowdsale, bytes32 hash, address investor, bool investorWins) external {
        require(msg.sender == _arbitersPoolAddress, "solveDispute: the sender is not arbiters pool contract.");

        IRICO(crowdsale).solveDispute(hash, investor, investorWins);
    }

     
     
     

    function getArbitersPoolAddress() external view returns (address) {
        return _arbitersPoolAddress;
    }

    function getAllCrowdsalesAddresses() external view returns (address[] memory crowdsales) {
        crowdsales = new address[](_crowdsales.length);
        for (uint256 i = 0; i < _crowdsales.length; i++) {
            crowdsales[i] = _crowdsales[i];
        }
        return crowdsales;
    }
    
    function getCrowdsaleMilestones(address crowdsale) external view returns(bytes32[] memory milestonesHashArray) {
        return IRICO(crowdsale).getMilestonesHashes();
    }

    function getOperatorCrowdsaleAddresses(address operator) external view returns (address[] memory crowdsales) {
        crowdsales = new address[](_operatorsContracts[operator].length);
        for (uint256 i = 0; i < _operatorsContracts[operator].length; i++) {
            crowdsales[i] = _operatorsContracts[operator][i];
        }
        return crowdsales;
    }
}