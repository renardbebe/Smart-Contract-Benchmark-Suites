 

pragma solidity 0.4.24;


 
library SafeMathLibExt {

    function times(uint a, uint b) public pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function divides(uint a, uint b) public pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function minus(uint a, uint b) public pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function plus(uint a, uint b) public pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        if (halted) 
            revert();
        _;
    }

    modifier stopNonOwnersInEmergency {
        if (halted && msg.sender != owner) 
            revert();
        _;
    }

    modifier onlyInEmergency {
        if (!halted) 
            revert();
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }

}

 
contract PricingStrategy {

    address public tier;

     
    function isPricingStrategy() public pure returns (bool) {
        return true;
    }

     
    function isSane() public pure returns (bool) {
        return true;
    }

     
    function isPresalePurchase() public pure returns (bool) {
        return false;
    }

     
    function updateRate(uint oneTokenInCents) public;

     
    function calculatePrice(uint value, uint tokensSold, uint decimals) public view returns (uint tokenAmount);

    function oneTokenInWei(uint tokensSold, uint decimals) public view returns (uint);
}

 
contract FinalizeAgent {

    bool public reservedTokensAreDistributed = false;

    function isFinalizeAgent() public pure returns(bool) {
        return true;
    }

     
    function isSane() public view returns (bool);

    function distributeReservedTokens(uint reservedTokensDistributionBatch) public;

     
    function finalizeCrowdsale() public;
    
     
    function setCrowdsaleTokenExtv1(address _token) public;
}

 
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

 
contract FractionalERC20Ext is ERC20 {
    uint public decimals;
    uint public minCap;
}

contract Allocatable is Ownable {

   
    mapping (address => bool) public allocateAgents;

    event AllocateAgentChanged(address addr, bool state  );

   
    function setAllocateAgent(address addr, bool state) public onlyOwner  
    {
        allocateAgents[addr] = state;
        emit AllocateAgentChanged(addr, state);
    }

    modifier onlyAllocateAgent() {
         
        require(allocateAgents[msg.sender]);
        _;
    }
}

 
contract TokenVesting is Allocatable {

    using SafeMathLibExt for uint;

    address public crowdSaleTokenAddress;

     
    uint256 public totalUnreleasedTokens;

     
    uint256 private startAt = 0;
    uint256 private cliff = 1;
    uint256 private duration = 4; 
    uint256 private step = 300;  
    bool private changeFreezed = false;

    struct VestingSchedule {
        uint256 startAt;
        uint256 cliff;
        uint256 duration;
        uint256 step;
        uint256 amount;
        uint256 amountReleased;
        bool changeFreezed;
    }

    mapping (address => VestingSchedule) public vestingMap;

    event VestedTokensReleased(address _adr, uint256 _amount);
    
    constructor(address _tokenAddress) public {
        
        crowdSaleTokenAddress = _tokenAddress;
    }

     
    modifier changesToVestingFreezed(address _adr) {
        require(vestingMap[_adr].changeFreezed);
        _;
    }

     
    modifier changesToVestingNotFreezed(address adr) {
        require(!vestingMap[adr].changeFreezed);  
        _;
    }

     
    function setDefaultVestingParameters(
        uint256 _startAt, uint256 _cliff, uint256 _duration,
        uint256 _step, bool _changeFreezed) public onlyAllocateAgent {

         
        require(_step != 0);
        require(_duration != 0);
        require(_cliff <= _duration);

        startAt = _startAt;
        cliff = _cliff;
        duration = _duration; 
        step = _step;
        changeFreezed = _changeFreezed;

    }

     
    function setVestingWithDefaultSchedule(address _adr, uint256 _amount) 
    public 
    changesToVestingNotFreezed(_adr) onlyAllocateAgent {
       
        setVesting(_adr, startAt, cliff, duration, step, _amount, changeFreezed);
    }    

     
    function setVesting(
        address _adr,
        uint256 _startAt,
        uint256 _cliff,
        uint256 _duration,
        uint256 _step,
        uint256 _amount,
        bool _changeFreezed) 
    public changesToVestingNotFreezed(_adr) onlyAllocateAgent {

        VestingSchedule storage vestingSchedule = vestingMap[_adr];

         
        require(_step != 0);
        require(_amount != 0 || vestingSchedule.amount > 0);
        require(_duration != 0);
        require(_cliff <= _duration);

         
        if (_startAt == 0) 
            _startAt = block.timestamp;

        vestingSchedule.startAt = _startAt;
        vestingSchedule.cliff = _cliff;
        vestingSchedule.duration = _duration;
        vestingSchedule.step = _step;

         
        if (vestingSchedule.amount == 0) {
             
            ERC20 token = ERC20(crowdSaleTokenAddress);
            require(token.balanceOf(this) >= totalUnreleasedTokens.plus(_amount));
            totalUnreleasedTokens = totalUnreleasedTokens.plus(_amount);
            vestingSchedule.amount = _amount; 
        }

        vestingSchedule.amountReleased = 0;
        vestingSchedule.changeFreezed = _changeFreezed;
    }

    function isVestingSet(address adr) public view returns (bool isSet) {
        return vestingMap[adr].amount != 0;
    }

    function freezeChangesToVesting(address _adr) public changesToVestingNotFreezed(_adr) onlyAllocateAgent {
        require(isVestingSet(_adr));  
        vestingMap[_adr].changeFreezed = true;
    }

     
    function releaseMyVestedTokens() public changesToVestingFreezed(msg.sender) {
        releaseVestedTokens(msg.sender);
    }

     
    function releaseVestedTokens(address _adr) public changesToVestingFreezed(_adr) {
        VestingSchedule storage vestingSchedule = vestingMap[_adr];
        
         
        require(vestingSchedule.amount.minus(vestingSchedule.amountReleased) > 0);
        
         
        uint256 totalTime = block.timestamp - vestingSchedule.startAt;
        uint256 totalSteps = totalTime / vestingSchedule.step;

         
        require(vestingSchedule.cliff <= totalSteps);

        uint256 tokensPerStep = vestingSchedule.amount / vestingSchedule.duration;
         
        if (tokensPerStep * vestingSchedule.duration != vestingSchedule.amount) tokensPerStep++;

        uint256 totalReleasableAmount = tokensPerStep.times(totalSteps);

         
        if (totalReleasableAmount > vestingSchedule.amount) totalReleasableAmount = vestingSchedule.amount;

        uint256 amountToRelease = totalReleasableAmount.minus(vestingSchedule.amountReleased);
        vestingSchedule.amountReleased = vestingSchedule.amountReleased.plus(amountToRelease);

         
        ERC20 token = ERC20(crowdSaleTokenAddress);
        token.transfer(_adr, amountToRelease);
         
        totalUnreleasedTokens = totalUnreleasedTokens.minus(amountToRelease);
        emit VestedTokensReleased(_adr, amountToRelease);
    }

     
    function setCrowdsaleTokenExtv1(address _token) public onlyAllocateAgent {       
        crowdSaleTokenAddress = _token;
    }
}

 
contract CrowdsaleExt is Allocatable, Haltable {

     
    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;

    using SafeMathLibExt for uint;

     
    FractionalERC20Ext public token;

     
    PricingStrategy public pricingStrategy;

     
    FinalizeAgent public finalizeAgent;

    TokenVesting public tokenVesting;

     
    string public name;

     
    address public multisigWallet;

     
    uint public minimumFundingGoal;

     
    uint public startsAt;

     
    uint public endsAt;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public investorCount = 0;

     
    bool public finalized;

    bool public isWhiteListed;

       
    address public tokenVestingAddress;

    address[] public joinedCrowdsales;
    uint8 public joinedCrowdsalesLen = 0;
    uint8 public joinedCrowdsalesLenMax = 50;

    struct JoinedCrowdsaleStatus {
        bool isJoined;
        uint8 position;
    }

    mapping (address => JoinedCrowdsaleStatus) public joinedCrowdsaleState;

     
    mapping (address => uint256) public investedAmountOf;

     
    mapping (address => uint256) public tokenAmountOf;

    struct WhiteListData {
        bool status;
        uint minCap;
        uint maxCap;
    }

     
    bool public isUpdatable;

     
    mapping (address => WhiteListData) public earlyParticipantWhitelist;

     
    address[] public whitelistedParticipants;

     
    uint public ownerTestValue;

     
    enum State { Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized }

     
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);

     
    event Whitelisted(address addr, bool status, uint minCap, uint maxCap);
    event WhitelistItemChanged(address addr, bool status, uint minCap, uint maxCap);

     
    event StartsAtChanged(uint newStartsAt);

     
    event EndsAtChanged(uint newEndsAt);

    constructor(string _name, address _token, PricingStrategy _pricingStrategy, 
    address _multisigWallet, uint _start, uint _end, 
    uint _minimumFundingGoal, bool _isUpdatable, 
    bool _isWhiteListed, address _tokenVestingAddress) public {

        owner = msg.sender;

        name = _name;

        tokenVestingAddress = _tokenVestingAddress;

        token = FractionalERC20Ext(_token);

        setPricingStrategy(_pricingStrategy);

        multisigWallet = _multisigWallet;
        if (multisigWallet == 0) {
            revert();
        }

        if (_start == 0) {
            revert();
        }

        startsAt = _start;

        if (_end == 0) {
            revert();
        }

        endsAt = _end;

         
        if (startsAt >= endsAt) {
            revert();
        }

         
        minimumFundingGoal = _minimumFundingGoal;

        isUpdatable = _isUpdatable;

        isWhiteListed = _isWhiteListed;
    }

     
    function() external payable {
        buy();
    }

     
    function buy() public payable {
        invest(msg.sender);
    }

     
    function invest(address addr) public payable {
        investInternal(addr, 0);
    }

     
    function investInternal(address receiver, uint128 customerId) private stopInEmergency {

         
        if (getState() == State.PreFunding) {
             
            revert();
        } else if (getState() == State.Funding) {
             
             
            if (isWhiteListed) {
                if (!earlyParticipantWhitelist[receiver].status) {
                    revert();
                }
            }
        } else {
             
            revert();
        }

        uint weiAmount = msg.value;

         
        uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, tokensSold, token.decimals());

        if (tokenAmount == 0) {
           
            revert();
        }

        if (isWhiteListed) {
            if (weiAmount < earlyParticipantWhitelist[receiver].minCap && tokenAmountOf[receiver] == 0) {
               
                revert();
            }

             
            if (isBreakingInvestorCap(receiver, weiAmount)) {
                revert();
            }

            updateInheritedEarlyParticipantWhitelist(receiver, weiAmount);
        } else {
            if (weiAmount < token.minCap() && tokenAmountOf[receiver] == 0) {
                revert();
            }
        }

        if (investedAmountOf[receiver] == 0) {
           
            investorCount++;
        }

         
        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

         
        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

         
        if (isBreakingCap(tokensSold)) {
            revert();
        }

        assignTokens(receiver, tokenAmount);

         
        if (!multisigWallet.send(weiAmount)) revert();

         
        emit Invested(receiver, weiAmount, tokenAmount, customerId);
    }

     
    function allocate(address receiver, uint256 tokenAmount, uint128 customerId, uint256 lockedTokenAmount) public onlyAllocateAgent {

       
        require(lockedTokenAmount <= tokenAmount);
        uint weiPrice = pricingStrategy.oneTokenInWei(tokensSold, token.decimals());
         
        uint256 weiAmount = (weiPrice * tokenAmount)/10**uint256(token.decimals());         

        weiRaised = weiRaised.plus(weiAmount);
        tokensSold = tokensSold.plus(tokenAmount);

        investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
        tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);

         
        if (lockedTokenAmount > 0) {
            tokenVesting = TokenVesting(tokenVestingAddress);
             
            require(!tokenVesting.isVestingSet(receiver));
            assignTokens(tokenVestingAddress, lockedTokenAmount);
             
            tokenVesting.setVestingWithDefaultSchedule(receiver, lockedTokenAmount); 
        }

         
        if (tokenAmount - lockedTokenAmount > 0) {
            assignTokens(receiver, tokenAmount - lockedTokenAmount);
        }

         
        emit Invested(receiver, weiAmount, tokenAmount, customerId);
    }

     
     
     
     

    modifier inState(State state) {
        if (getState() != state) 
            revert();
        _;
    }

    function distributeReservedTokens(uint reservedTokensDistributionBatch) 
    public inState(State.Success) onlyOwner stopInEmergency {
       
        if (finalized) {
            revert();
        }

         
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.distributeReservedTokens(reservedTokensDistributionBatch);
        }
    }

    function areReservedTokensDistributed() public view returns (bool) {
        return finalizeAgent.reservedTokensAreDistributed();
    }

    function canDistributeReservedTokens() public view returns(bool) {
        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        if ((lastTierCntrct.getState() == State.Success) &&
        !lastTierCntrct.halted() && !lastTierCntrct.finalized() && !lastTierCntrct.areReservedTokensDistributed())
            return true;
        return false;
    }

     
    function finalize() public inState(State.Success) onlyOwner stopInEmergency {

       
        if (finalized) {
            revert();
        }

       
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.finalizeCrowdsale();
        }

        finalized = true;
    }

     
    function setFinalizeAgent(FinalizeAgent addr) public onlyOwner {
        assert(address(addr) != address(0));
        assert(address(finalizeAgent) == address(0));
        finalizeAgent = addr;

         
        if (!finalizeAgent.isFinalizeAgent()) {
            revert();
        }
    }

     
    function setEarlyParticipantWhitelist(address addr, bool status, uint minCap, uint maxCap) public onlyOwner {
        if (!isWhiteListed) revert();
        assert(addr != address(0));
        assert(maxCap > 0);
        assert(minCap <= maxCap);
        assert(now <= endsAt);

        if (!isAddressWhitelisted(addr)) {
            whitelistedParticipants.push(addr);
            emit Whitelisted(addr, status, minCap, maxCap);
        } else {
            emit WhitelistItemChanged(addr, status, minCap, maxCap);
        }

        earlyParticipantWhitelist[addr] = WhiteListData({status:status, minCap:minCap, maxCap:maxCap});
    }

    function setEarlyParticipantWhitelistMultiple(address[] addrs, bool[] statuses, uint[] minCaps, uint[] maxCaps) 
    public onlyOwner {
        if (!isWhiteListed) revert();
        assert(now <= endsAt);
        assert(addrs.length == statuses.length);
        assert(statuses.length == minCaps.length);
        assert(minCaps.length == maxCaps.length);
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            setEarlyParticipantWhitelist(addrs[iterator], statuses[iterator], minCaps[iterator], maxCaps[iterator]);
        }
    }

    function updateEarlyParticipantWhitelist(address addr, uint weiAmount) public {
        if (!isWhiteListed) revert();
        assert(addr != address(0));
        assert(now <= endsAt);
        assert(isTierJoined(msg.sender));
        if (weiAmount < earlyParticipantWhitelist[addr].minCap && tokenAmountOf[addr] == 0) revert();
         
        uint newMaxCap = earlyParticipantWhitelist[addr].maxCap;
        newMaxCap = newMaxCap.minus(weiAmount);
        earlyParticipantWhitelist[addr] = WhiteListData({status:earlyParticipantWhitelist[addr].status, minCap:0, maxCap:newMaxCap});
    }

    function updateInheritedEarlyParticipantWhitelist(address reciever, uint weiAmount) private {
        if (!isWhiteListed) revert();
        if (weiAmount < earlyParticipantWhitelist[reciever].minCap && tokenAmountOf[reciever] == 0) revert();

        uint8 tierPosition = getTierPosition(this);

        for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
            crowdsale.updateEarlyParticipantWhitelist(reciever, weiAmount);
        }
    }

    function isAddressWhitelisted(address addr) public view returns(bool) {
        for (uint i = 0; i < whitelistedParticipants.length; i++) {
            if (whitelistedParticipants[i] == addr) {
                return true;
                break;
            }
        }

        return false;
    }

    function whitelistedParticipantsLength() public view returns (uint) {
        return whitelistedParticipants.length;
    }

    function isTierJoined(address addr) public view returns(bool) {
        return joinedCrowdsaleState[addr].isJoined;
    }

    function getTierPosition(address addr) public view returns(uint8) {
        return joinedCrowdsaleState[addr].position;
    }

    function getLastTier() public view returns(address) {
        if (joinedCrowdsalesLen > 0)
            return joinedCrowdsales[joinedCrowdsalesLen - 1];
        else
            return address(0);
    }

    function setJoinedCrowdsales(address addr) private onlyOwner {
        assert(addr != address(0));
        assert(joinedCrowdsalesLen <= joinedCrowdsalesLenMax);
        assert(!isTierJoined(addr));
        joinedCrowdsales.push(addr);
        joinedCrowdsaleState[addr] = JoinedCrowdsaleStatus({
            isJoined: true,
            position: joinedCrowdsalesLen
        });
        joinedCrowdsalesLen++;
    }

    function updateJoinedCrowdsalesMultiple(address[] addrs) public onlyOwner {
        assert(addrs.length > 0);
        assert(joinedCrowdsalesLen == 0);
        assert(addrs.length <= joinedCrowdsalesLenMax);
        for (uint8 iter = 0; iter < addrs.length; iter++) {
            setJoinedCrowdsales(addrs[iter]);
        }
    }

    function setStartsAt(uint time) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(now <= time);  
        assert(time <= endsAt);
        assert(now <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        if (lastTierCntrct.finalized()) revert();

        uint8 tierPosition = getTierPosition(this);

         
        for (uint8 j = 0; j < tierPosition; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
            assert(time >= crowdsale.endsAt());
        }

        startsAt = time;
        emit StartsAtChanged(startsAt);
    }

     
    function setEndsAt(uint time) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(now <= time); 
        assert(startsAt <= time);
        assert(now <= endsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        if (lastTierCntrct.finalized()) revert();


        uint8 tierPosition = getTierPosition(this);

        for (uint8 j = tierPosition + 1; j < joinedCrowdsalesLen; j++) {
            CrowdsaleExt crowdsale = CrowdsaleExt(joinedCrowdsales[j]);
            assert(time <= crowdsale.startsAt());
        }

        endsAt = time;
        emit EndsAtChanged(endsAt);
    }

     
    function setPricingStrategy(PricingStrategy _pricingStrategy) public onlyOwner {
        assert(address(_pricingStrategy) != address(0));
        assert(address(pricingStrategy) == address(0));
        pricingStrategy = _pricingStrategy;

         
        if (!pricingStrategy.isPricingStrategy()) {
            revert();
        }
    }

     
    function setCrowdsaleTokenExtv1(address _token) public onlyOwner {
        assert(_token != address(0));
        token = FractionalERC20Ext(_token);
        
        if (address(finalizeAgent) != address(0)) {
            finalizeAgent.setCrowdsaleTokenExtv1(_token);
        }
    }

     
    function setMultisig(address addr) public onlyOwner {

       
        if (investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
            revert();
        }

        multisigWallet = addr;
    }

     
    function isMinimumGoalReached() public view returns (bool reached) {
        return weiRaised >= minimumFundingGoal;
    }

     
    function isFinalizerSane() public view returns (bool sane) {
        return finalizeAgent.isSane();
    }

     
    function isPricingSane() public view returns (bool sane) {
        return pricingStrategy.isSane();
    }

     
    function getState() public view returns (State) {
        if(finalized) return State.Finalized;
        else if (address(finalizeAgent) == 0) return State.Preparing;
        else if (!finalizeAgent.isSane()) return State.Preparing;
        else if (!pricingStrategy.isSane()) return State.Preparing;
        else if (block.timestamp < startsAt) return State.PreFunding;
        else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
        else if (isMinimumGoalReached()) return State.Success;
        else return State.Failure;
    }

     
    function isCrowdsale() public pure returns (bool) {
        return true;
    }

     
     
     

     
    function isBreakingCap(uint tokensSoldTotal) public view returns (bool limitBroken);

    function isBreakingInvestorCap(address receiver, uint tokenAmount) public view returns (bool limitBroken);

     
    function isCrowdsaleFull() public view returns (bool);

     
    function assignTokens(address receiver, uint tokenAmount) private;
}

 
contract StandardToken is ERC20 {

    using SafeMathLibExt for uint;
     
    event Minted(address receiver, uint amount);

     
    mapping(address => uint) public balances;

     
    mapping (address => mapping (address => uint)) public allowed;

     
    function isToken() public pure returns (bool weAre) {
        return true;
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        balances[msg.sender] = balances[msg.sender].minus(_value);
        balances[_to] = balances[_to].plus(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        uint _allowance = allowed[_from][msg.sender];

        balances[_to] = balances[_to].plus(_value);
        balances[_from] = balances[_from].minus(_value);
        allowed[_from][msg.sender] = _allowance.minus(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint _value) public returns (bool success) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) revert();

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

}

 
contract MintableTokenExt is StandardToken, Ownable {

    using SafeMathLibExt for uint;

    bool public mintingFinished = false;

     
    mapping (address => bool) public mintAgents;

    event MintingAgentChanged(address addr, bool state  );

     
    struct ReservedTokensData {
        uint inTokens;
        uint inPercentageUnit;
        uint inPercentageDecimals;
        bool isReserved;
        bool isDistributed;
        bool isVested;
    }

    mapping (address => ReservedTokensData) public reservedTokensList;
    address[] public reservedTokensDestinations;
    uint public reservedTokensDestinationsLen = 0;
    bool private reservedTokensDestinationsAreSet = false;

    modifier onlyMintAgent() {
         
        if (!mintAgents[msg.sender]) {
            revert();
        }
        _;
    }

     
    modifier canMint() {
        if (mintingFinished) revert();
        _;
    }

    function finalizeReservedAddress(address addr) public onlyMintAgent canMint {
        ReservedTokensData storage reservedTokensData = reservedTokensList[addr];
        reservedTokensData.isDistributed = true;
    }

    function isAddressReserved(address addr) public view returns (bool isReserved) {
        return reservedTokensList[addr].isReserved;
    }

    function areTokensDistributedForAddress(address addr) public view returns (bool isDistributed) {
        return reservedTokensList[addr].isDistributed;
    }

    function getReservedTokens(address addr) public view returns (uint inTokens) {
        return reservedTokensList[addr].inTokens;
    }

    function getReservedPercentageUnit(address addr) public view returns (uint inPercentageUnit) {
        return reservedTokensList[addr].inPercentageUnit;
    }

    function getReservedPercentageDecimals(address addr) public view returns (uint inPercentageDecimals) {
        return reservedTokensList[addr].inPercentageDecimals;
    }

    function getReservedIsVested(address addr) public view returns (bool isVested) {
        return reservedTokensList[addr].isVested;
    }

    function setReservedTokensListMultiple(
        address[] addrs, 
        uint[] inTokens, 
        uint[] inPercentageUnit, 
        uint[] inPercentageDecimals,
        bool[] isVested
        ) public canMint onlyOwner {
        assert(!reservedTokensDestinationsAreSet);
        assert(addrs.length == inTokens.length);
        assert(inTokens.length == inPercentageUnit.length);
        assert(inPercentageUnit.length == inPercentageDecimals.length);
        for (uint iterator = 0; iterator < addrs.length; iterator++) {
            if (addrs[iterator] != address(0)) {
                setReservedTokensList(
                    addrs[iterator],
                    inTokens[iterator],
                    inPercentageUnit[iterator],
                    inPercentageDecimals[iterator],
                    isVested[iterator]
                    );
            }
        }
        reservedTokensDestinationsAreSet = true;
    }

     
    function mint(address receiver, uint amount) public onlyMintAgent canMint {
        totalSupply = totalSupply.plus(amount);
        balances[receiver] = balances[receiver].plus(amount);

         
         
        emit Transfer(0, receiver, amount);
    }

     
    function setMintAgent(address addr, bool state) public onlyOwner canMint {
        mintAgents[addr] = state;
        emit MintingAgentChanged(addr, state);
    }

    function setReservedTokensList(address addr, uint inTokens, uint inPercentageUnit, uint inPercentageDecimals,bool isVested) 
    private canMint onlyOwner {
        assert(addr != address(0));
        if (!isAddressReserved(addr)) {
            reservedTokensDestinations.push(addr);
            reservedTokensDestinationsLen++;
        }

        reservedTokensList[addr] = ReservedTokensData({
            inTokens: inTokens,
            inPercentageUnit: inPercentageUnit,
            inPercentageDecimals: inPercentageDecimals,
            isReserved: true,
            isDistributed: false,
            isVested:isVested
        });
    }
}

 
contract MintedTokenCappedCrowdsaleExt is CrowdsaleExt {

     
    uint public maximumSellableTokens;

    constructor(
        string _name,
        address _token,
        PricingStrategy _pricingStrategy,
        address _multisigWallet,
        uint _start, uint _end,
        uint _minimumFundingGoal,
        uint _maximumSellableTokens,
        bool _isUpdatable,
        bool _isWhiteListed,
        address _tokenVestingAddress
    ) public CrowdsaleExt(_name, _token, _pricingStrategy, _multisigWallet, _start, _end,
    _minimumFundingGoal, _isUpdatable, _isWhiteListed, _tokenVestingAddress) {
        maximumSellableTokens = _maximumSellableTokens;
    }

     
    event MaximumSellableTokensChanged(uint newMaximumSellableTokens);

     
    function isBreakingCap(uint tokensSoldTotal) public view returns (bool limitBroken) {
        return tokensSoldTotal > maximumSellableTokens;
    }

    function isBreakingInvestorCap(address addr, uint weiAmount) public view returns (bool limitBroken) {
        assert(isWhiteListed);
        uint maxCap = earlyParticipantWhitelist[addr].maxCap;
        return (investedAmountOf[addr].plus(weiAmount)) > maxCap;
    }

    function isCrowdsaleFull() public view returns (bool) {
        return tokensSold >= maximumSellableTokens;
    }

    function setMaximumSellableTokens(uint tokens) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(now <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        assert(!lastTierCntrct.finalized());

        maximumSellableTokens = tokens;
        emit MaximumSellableTokensChanged(maximumSellableTokens);
    }

    function updateRate(uint oneTokenInCents) public onlyOwner {
        assert(!finalized);
        assert(isUpdatable);
        assert(now <= startsAt);

        CrowdsaleExt lastTierCntrct = CrowdsaleExt(getLastTier());
        assert(!lastTierCntrct.finalized());

        pricingStrategy.updateRate(oneTokenInCents);
    }

     
    function assignTokens(address receiver, uint tokenAmount) private {
        MintableTokenExt mintableToken = MintableTokenExt(token);
        mintableToken.mint(receiver, tokenAmount);
    }    
}

 
contract MintedTokenCappedCrowdsaleExtv1 is MintedTokenCappedCrowdsaleExt {

    address[] public investedAmountOfAddresses;
    MintedTokenCappedCrowdsaleExt public mintedTokenCappedCrowdsaleExt;

    constructor(
        string _name,
        address _token,
        PricingStrategy _pricingStrategy,
        address _multisigWallet,
        uint _start, uint _end,
        uint _minimumFundingGoal,
        uint _maximumSellableTokens,
        bool _isUpdatable,
        bool _isWhiteListed,
        address _tokenVestingAddress,
        MintedTokenCappedCrowdsaleExt _oldMintedTokenCappedCrowdsaleExtAddress
    ) public MintedTokenCappedCrowdsaleExt(_name, _token, _pricingStrategy, _multisigWallet, _start, _end,
    _minimumFundingGoal, _maximumSellableTokens, _isUpdatable, _isWhiteListed, _tokenVestingAddress) {
        
        mintedTokenCappedCrowdsaleExt = _oldMintedTokenCappedCrowdsaleExtAddress;
        tokensSold = mintedTokenCappedCrowdsaleExt.tokensSold();
        weiRaised = mintedTokenCappedCrowdsaleExt.weiRaised();
        investorCount = mintedTokenCappedCrowdsaleExt.investorCount();        

        
        for (uint i = 0; i < mintedTokenCappedCrowdsaleExt.whitelistedParticipantsLength(); i++) {
            address whitelistAddress = mintedTokenCappedCrowdsaleExt.whitelistedParticipants(i);

             

            uint256 tokenAmount = mintedTokenCappedCrowdsaleExt.tokenAmountOf(whitelistAddress);
            if (tokenAmount != 0){               
                tokenAmountOf[whitelistAddress] = tokenAmount;               
            }

            uint256 investedAmount = mintedTokenCappedCrowdsaleExt.investedAmountOf(whitelistAddress);
            if (investedAmount != 0){
                investedAmountOf[whitelistAddress] = investedAmount;               
            }

             
        }
    }
    
}