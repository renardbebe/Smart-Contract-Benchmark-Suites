 

pragma solidity ^0.4.13;
 
contract Ownable {
    address public owner;

    function Ownable() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}

 
contract Killable is Ownable {
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

 
 
contract Haltable is Ownable {
    bool public halted;

    modifier stopInEmergency {
        require(!halted);
        _;
    }

    modifier onlyInEmergency {
        require(halted);
        _;
    }

     
    function halt() external onlyOwner {
        halted = true;
    }

     
    function unhalt() external onlyOwner onlyInEmergency {
        halted = false;
    }
}

 
contract Migrations is Ownable {
    uint public lastCompletedMigration;

    function setCompleted(uint completed) onlyOwner {
        lastCompletedMigration = completed;
    }

    function upgrade(address newAddress) onlyOwner {
        Migrations upgraded = Migrations(newAddress);
        upgraded.setCompleted(lastCompletedMigration);
    }
}
 
contract Pausable is Ownable {
    bool public stopped;

    modifier stopInEmergency {
        if (!stopped) {
            _;
        }
    }

    modifier onlyInEmergency {
        if (stopped) {
            _;
        }
    }

     
    function emergencyStop() external onlyOwner {
        stopped = true;
    }

     
    function release() external onlyOwner onlyInEmergency {
        stopped = false;
    }
}

 
contract ERC20 {
    uint public totalSupply;
    function balanceOf(address who) constant returns (uint);
    function allowance(address owner, address spender) constant returns (uint);
    function mint(address receiver, uint amount);
    function transfer(address to, uint value) returns (bool ok);
    function transferFrom(address from, address to, uint value) returns (bool ok);
    function approve(address spender, uint value) returns (bool ok);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}


 
contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        return c;
    }

    function safeDiv(uint a, uint b) internal returns (uint) {
        uint c = a / b;
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        return c;
    }

    function max64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal constant returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a >= b ? a : b;
    }

    function min256(uint256 a, uint256 b) internal constant returns (uint256) {
        return a < b ? a : b;
    }
}

 
contract ShareEstateToken is SafeMath, ERC20, Ownable {
    string public name = "ShareEstate Token";
    string public symbol = "SRE";
    uint public decimals = 4;

     
    address public crowdsaleAgent;
     
    bool public released = false;
     
    mapping (address => mapping (address => uint)) allowed;
     
    mapping(address => uint) balances;

     
    modifier canTransfer() {
        if(!released) {
            require(msg.sender == crowdsaleAgent);
        }
        _;
    }

     
     
    modifier inReleaseState(bool _released) {
        require(_released == released);
        _;
    }

     
    modifier onlyCrowdsaleAgent() {
        require(msg.sender == crowdsaleAgent);
        _;
    }

     
     
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

     
    modifier canMint() {
        require(!released);
        _;
    }

     
    function ShareEstateToken() {
        owner = msg.sender;
    }

     
    function() payable {
        revert();
    }

     
     
     
    function mint(address receiver, uint amount) onlyCrowdsaleAgent canMint public {
        totalSupply = safeAdd(totalSupply, amount);
        balances[receiver] = safeAdd(balances[receiver], amount);
        Transfer(0, receiver, amount);
    }

     
     
    function setCrowdsaleAgent(address _crowdsaleAgent) onlyOwner inReleaseState(false) public {
        crowdsaleAgent = _crowdsaleAgent;
    }
     
    function releaseTokenTransfer() public onlyCrowdsaleAgent {
        released = true;
    }
     
     
     
     
    function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], _value);
        balances[_to] = safeAdd(balances[_to], _value);

        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(2 * 32) canTransfer returns (bool success) {
        var _allowance = allowed[_from][msg.sender];

        balances[_to] = safeAdd(balances[_to], _value);
        balances[_from] = safeSub(balances[_from], _value);
        allowed[_from][msg.sender] = safeSub(_allowance, _value);
        Transfer(_from, _to, _value);
        return true;
    }
     
     
     
    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }

     
     
     
     
    function approve(address _spender, uint _value) returns (bool success) {
         
         
         
         
        require ((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
    function allowance(address _owner, address _spender) constant returns (uint remaining) {
        return allowed[_owner][_spender];
    }
}
 
contract ShareEstateTokenCrowdsale is Haltable, Killable, SafeMath {

     
    uint public constant PRE_FUNDING_GOAL = 1e6 * PRICE;

     
    uint public constant MIN_PRE_FUNDING_GOAL = 2e5 * PRICE;

     
    uint public constant TEAM_BONUS_PERCENT = 24;

     
    uint constant public PRICE = 100;

     
    uint constant public PRE_ICO_DURATION = 5 weeks;

     

    ShareEstateToken public token;

     
    address public multisigWallet;

     
    uint public startsAt;

     
    uint public preIcoEndsAt;

     
    uint public tokensSold = 0;

     
    uint public weiRaised = 0;

     
    uint public investorCount = 0;

     
    uint public loadedRefund = 0;

     
    uint public weiRefunded = 0;

     
    bool public finalized;

     
    uint public exchangeRate;

     
    uint public exchangeRateTimestamp;

     
    address public exchangeRateAgent;

     
    mapping (address => uint256) public investedAmountOf;

     
    mapping (address => uint256) public tokenAmountOf;

     
    struct Milestone {
     
    uint start;
     
    uint end;
     
    uint bonus;
    }

    Milestone[] public milestones;

     
     
     
     
     
     
     
    enum State{Unknown, Preparing, PreFunding, PreFundingSuccess, Failure, Finalized, Refunding}

     
    event Invested(address investor, uint weiAmount, uint tokenAmount);
     
    event Refund(address investor, uint weiAmount);
     
    event preIcoEndsAtChanged(uint endsAt);
     
    event ExchangeRateChanged(uint oldValue, uint newValue);

     
    modifier inState(State state) {
        require(getState() == state);
        _;
    }

    modifier onlyExchangeRateAgent() {
        require(msg.sender == exchangeRateAgent);
        _;
    }

     
     
     
     
     
    function ShareEstateTokenCrowdsale(address _token, address _multisigWallet, uint _preInvestStart, uint _preInvestStop) {
        require(_multisigWallet != 0);
        require(_preInvestStart != 0);
        require(_preInvestStop != 0);
        require(_preInvestStart < _preInvestStop);

        token = ShareEstateToken(_token);

        multisigWallet = _multisigWallet;
        startsAt = _preInvestStart;
        preIcoEndsAt = _preInvestStop;
        var preIcoBonuses = [uint(65), 50, 40, 35, 30];
        for (uint i = 0; i < preIcoBonuses.length; i++) {
            milestones.push(Milestone(_preInvestStart + i * 1 weeks, _preInvestStart + (i + 1) * 1 weeks, preIcoBonuses[i]));
        }
    }

    function() payable {
        buy();
    }

     
     
    function getCurrentMilestone() private constant returns (Milestone) {
        for (uint i = 0; i < milestones.length; i++) {
            if (milestones[i].start <= now && milestones[i].end > now) {
                return milestones[i];
            }
        }
    }

     
     
    function investInternal(address receiver) stopInEmergency private {
        var state = getState();
        require(state == State.PreFunding);

        uint weiAmount = msg.value;
        uint tokensAmount = calculateTokens(weiAmount);

        if(state == State.PreFunding) {
            tokensAmount += safeDiv(safeMul(tokensAmount, getCurrentMilestone().bonus), 100);
        }

        if(investedAmountOf[receiver] == 0) {
             
            investorCount++;
        }

         
        investedAmountOf[receiver] = safeAdd(investedAmountOf[receiver], weiAmount);
        tokenAmountOf[receiver] = safeAdd(tokenAmountOf[receiver], tokensAmount);
         
        weiRaised = safeAdd(weiRaised, weiAmount);
        tokensSold = safeAdd(tokensSold, tokensAmount);

        assignTokens(receiver, tokensAmount);
        var teamBonusTokens = safeDiv(safeMul(tokensAmount, TEAM_BONUS_PERCENT), 100 - TEAM_BONUS_PERCENT);
        assignTokens(multisigWallet, teamBonusTokens);

        multisigWallet.transfer(weiAmount);
         
        Invested(receiver, weiAmount, tokensAmount);
    }

     
     
    function invest(address receiver) public payable {
        investInternal(receiver);
    }

     
    function buy() public payable {
        invest(msg.sender);
    }

     
    function finalize() public inState(State.PreFundingSuccess) onlyOwner stopInEmergency {
        require(!finalized);

        finalized = true;
        finalizeCrowdsale();
    }

     
    function finalizeCrowdsale() internal {
         
         
    }

     
     
     
    function setExchangeRate(uint value, uint time) onlyExchangeRateAgent {
        require(value > 0);
        require(time > 0);
        require(exchangeRateTimestamp == 0 || getDifference(int(time), int(now)) <= 1 minutes);
        require(exchangeRate == 0 || (getDifference(int(value), int(exchangeRate)) * 100 / exchangeRate <= 30));

        ExchangeRateChanged(exchangeRate, value);
        exchangeRate = value;
        exchangeRateTimestamp = time;
    }

     
     
    function setExchangeRateAgent(address newAgent) onlyOwner {
        if (newAgent != address(0)) {
            exchangeRateAgent = newAgent;
        }
    }

    function getDifference(int one, int two) private constant returns (uint) {
        var diff = one - two;
        if (diff < 0)
        diff = -diff;
        return uint(diff);
    }

     
     
    function setPreIcoEndsAt(uint time) onlyOwner {
        require(time >= now);
        preIcoEndsAt = time;
        preIcoEndsAtChanged(preIcoEndsAt);
    }

     
    function loadRefund() public payable inState(State.Failure) {
        require(msg.value > 0);
        loadedRefund = safeAdd(loadedRefund, msg.value);
    }

     
    function refund() public inState(State.Refunding) {
        uint256 weiValue = investedAmountOf[msg.sender];
        if (weiValue == 0)
        return;
        investedAmountOf[msg.sender] = 0;
        weiRefunded = safeAdd(weiRefunded, weiValue);
        Refund(msg.sender, weiValue);
        msg.sender.transfer(weiValue);
    }

     
     
    function isMinimumGoalReached() public constant returns (bool reached) {
        return weiToUsdCents(weiRaised) >= MIN_PRE_FUNDING_GOAL;
    }

     
     
     
     
    function setCrowdsaleData(uint _tokensSold, uint _weiRaised, uint _investorCount) onlyOwner {
        require(_tokensSold > 0);
        require(_weiRaised > 0);
        require(_investorCount > 0);

        tokensSold = _tokensSold;
        weiRaised = _weiRaised;
        investorCount = _investorCount;
    }

     
     
    function getState() public constant returns (State) {
        if (finalized)
        return State.Finalized;
        if (address(token) == 0 || address(multisigWallet) == 0 || now < startsAt)
        return State.Preparing;
        if (now > startsAt && now < preIcoEndsAt - 2 days && !isMaximumPreFundingGoalReached())
        return State.PreFunding;
        if (isMinimumGoalReached())
        return State.PreFundingSuccess;
        if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised)
        return State.Refunding;
        return State.Failure;
    }

     
     
     
    function calculateTokens(uint weiAmount) internal returns (uint tokenAmount) {
        var multiplier = 10 ** token.decimals();

        uint usdAmount = weiToUsdCents(weiAmount);

        return safeMul(usdAmount, safeDiv(multiplier, PRICE));
    }

     
     
    function isMaximumPreFundingGoalReached() public constant returns (bool reached) {
        return weiToUsdCents(weiRaised) >= PRE_FUNDING_GOAL;
    }

     
     
     
    function weiToUsdCents(uint weiValue) private returns (uint) {
        return safeDiv(safeMul(weiValue, exchangeRate), 1e18);
    }

     
     
     
    function assignTokens(address receiver, uint tokenAmount) private {
        token.mint(receiver, tokenAmount);
    }
}