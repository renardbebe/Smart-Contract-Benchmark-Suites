 

pragma solidity ^0.4.11;

library Bonus {
    uint256 constant pointMultiplier = 1e18;  

    function getBonusFactor(uint256 soldToUser)
    internal pure returns (uint256 factor)
    {
        uint256 tokenSold = soldToUser / pointMultiplier;
         

         
        if (tokenSold >= 100000) {
            return 100;
        }
         
        if (tokenSold >= 90000) {
            return 95;
        }
        if (tokenSold >= 80000) {
            return 90;
        }
        if (tokenSold >= 70000) {
            return 85;
        }
        if (tokenSold >= 60000) {
            return 80;
        }
        if (tokenSold >= 50000) {
            return 75;
        }
        if (tokenSold >= 40000) {
            return 70;
        }
        if (tokenSold >= 30000) {
            return 65;
        }
        if (tokenSold >= 20000) {
            return 60;
        }
        if (tokenSold >= 10000) {
            return 55;
        }
         
        if (tokenSold >= 9000) {
            return 50;
        }
        if (tokenSold >= 8000) {
            return 45;
        }
        if (tokenSold >= 7000) {
            return 40;
        }
        if (tokenSold >= 6000) {
            return 35;
        }
        if (tokenSold >= 5000) {
            return 30;
        }
        if (tokenSold >= 4000) {
            return 25;
        }
         
        if (tokenSold >= 3000) {
            return 20;
        }
        if (tokenSold >= 2500) {
            return 15;
        }
        if (tokenSold >= 2000) {
            return 10;
        }
        if (tokenSold >= 1500) {
            return 5;
        }
         
        return 0;
    }

}
library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

}
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) returns (bool) {

         
         
         
         
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

contract CrwdToken is StandardToken {

     
    enum States {
        Initial,  
        ValuationSet,
        Ico,  
        Underfunded,  
        Operational,  
        Paused          
    }

    mapping(address => uint256) public ethPossibleRefunds;

    uint256 public soldTokens;

    string public constant name = "Crwdtoken";

    string public constant symbol = "CRWD";

    uint8 public constant decimals = 18;

    mapping(address => bool) public whitelist;

    address public teamTimeLock;
    address public devTimeLock;
    address public countryTimeLock;

    address public miscNotLocked;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    address public tokenAssignmentControl;

    States public state;

    uint256 public weiICOMinimum;

    uint256 public weiICOMaximum;

    uint256 public silencePeriod;

    uint256 public startAcceptingFundsBlock;

    uint256 public endBlock;

    uint256 public ETH_CRWDTOKEN;  

    uint256 constant pointMultiplier = 1e18;  

    uint256 public constant maxTotalSupply = 45000000 * pointMultiplier;

    uint256 public constant percentForSale = 50;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

    bool public bonusPhase = false;


     
    function CrwdToken(
        address _stateControl
    , address _whitelistControl
    , address _withdrawControl
    , address _tokenAssignmentControl
    , address _notLocked  
    , address _lockedTeam  
    , address _lockedDev  
    , address _lockedCountry  
    ) {
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdrawControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        moveToState(States.Initial);
        weiICOMinimum = 0;
         
        weiICOMaximum = 0;
        endBlock = 0;
        ETH_CRWDTOKEN = 0;
        totalSupply = 0;
        soldTokens = 0;
        uint releaseTime = now + 9 * 31 days;
        teamTimeLock = address(new CrwdTimelock(this, _lockedTeam, releaseTime));
        devTimeLock = address(new CrwdTimelock(this, _lockedDev, releaseTime));
        countryTimeLock = address(new CrwdTimelock(this, _lockedCountry, releaseTime));
        miscNotLocked = _notLocked;
    }

    event Whitelisted(address addr);

    event StateTransition(States oldState, States newState);

    modifier onlyWhitelist() {
        require(msg.sender == whitelistControl);
        _;
    }

    modifier onlyStateControl() {
        require(msg.sender == stateControl);
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl);
        _;
    }

    modifier onlyWithdraw() {
        require(msg.sender == withdrawControl);
        _;
    }

    modifier requireState(States _requiredState) {
        require(state == _requiredState);
        _;
    }

     

     
     
     
    function() payable
    requireState(States.Ico)
    {
        require(whitelist[msg.sender] == true);
        require(this.balance <= weiICOMaximum);
         
        require(block.number < endBlock);
        require(block.number >= startAcceptingFundsBlock);

        uint256 basisTokens = msg.value.mul(ETH_CRWDTOKEN);
        uint256 soldToTuserWithBonus = addBonus(basisTokens);

        issueTokensToUser(msg.sender, soldToTuserWithBonus);
        ethPossibleRefunds[msg.sender] = ethPossibleRefunds[msg.sender].add(msg.value);
    }

    function issueTokensToUser(address beneficiary, uint256 amount)
    internal
    {
        balances[beneficiary] = balances[beneficiary].add(amount);
        soldTokens = soldTokens.add(amount);
        totalSupply = totalSupply.add(amount.mul(100).div(percentForSale));
        Mint(beneficiary, amount);
        Transfer(0x0, beneficiary, amount);
    }

    function issuePercentToReserve(address beneficiary, uint256 percentOfSold)
    internal
    {
        uint256 amount = totalSupply.mul(percentOfSold).div(100);
        balances[beneficiary] = balances[beneficiary].add(amount);
        Mint(beneficiary, amount);
        Transfer(0x0, beneficiary, amount);
    }

    function addBonus(uint256 basisTokens)
    public constant
    returns (uint256 resultingTokens)
    {
         
        if (!bonusPhase) return basisTokens;
         
        uint256 perMillBonus = getPhaseBonus();
         
        if (basisTokens >= pointMultiplier.mul(1000)) {
            perMillBonus += Bonus.getBonusFactor(basisTokens);
        }
         
        return basisTokens.mul(per_mill + perMillBonus).div(per_mill);
    }

    uint256 constant per_mill = 1000;

    function setBonusPhase(bool _isBonusPhase)
    onlyStateControl
         
    {
        bonusPhase = _isBonusPhase;
    }

    function getPhaseBonus()
    internal
    constant
    returns (uint256 factor)
    {
        if (bonusPhase) { 
            return 200;
        }
        return 0;
    }


    function moveToState(States _newState)
    internal
    {
        StateTransition(state, _newState);
        state = _newState;
    }
     
     
     
     
     
    function updateEthICOThresholds(uint256 _newWeiICOMinimum, uint256 _newWeiICOMaximum, uint256 _silencePeriod, uint256 _newEndBlock)
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet);
        require(_newWeiICOMaximum > _newWeiICOMinimum);
        require(block.number + silencePeriod < _newEndBlock);
        require(block.number < _newEndBlock);
        weiICOMinimum = _newWeiICOMinimum;
        weiICOMaximum = _newWeiICOMaximum;
        silencePeriod = _silencePeriod;
        endBlock = _newEndBlock;
         
        ETH_CRWDTOKEN = maxTotalSupply.mul(percentForSale).div(100).div(weiICOMaximum);
         
        moveToState(States.ValuationSet);
    }

    function startICO()
    onlyStateControl
    requireState(States.ValuationSet)
    {
        require(block.number < endBlock);
        require(block.number + silencePeriod < endBlock);
        startAcceptingFundsBlock = block.number + silencePeriod;
        moveToState(States.Ico);
    }

    function addPresaleAmount(address beneficiary, uint256 amount)
    onlyTokenAssignmentControl
    {
        require(state == States.ValuationSet || state == States.Ico);
        issueTokensToUser(beneficiary, amount);
    }


    function endICO()
    onlyStateControl
    requireState(States.Ico)
    {
        if (this.balance < weiICOMinimum) {
            moveToState(States.Underfunded);
        }
        else {
            burnAndFinish();
            moveToState(States.Operational);
        }
    }

    function anyoneEndICO()
    requireState(States.Ico)
    {
        require(block.number > endBlock);
        if (this.balance < weiICOMinimum) {
            moveToState(States.Underfunded);
        }
        else {
            burnAndFinish();
            moveToState(States.Operational);
        }
    }

    function burnAndFinish()
    internal
    {
        issuePercentToReserve(teamTimeLock, 15);
        issuePercentToReserve(devTimeLock, 10);
        issuePercentToReserve(countryTimeLock, 10);
        issuePercentToReserve(miscNotLocked, 15);

        totalSupply = soldTokens
        .add(balances[teamTimeLock])
        .add(balances[devTimeLock])
        .add(balances[countryTimeLock])
        .add(balances[miscNotLocked]);

        mintingFinished = true;
        MintFinished();
    }

    function addToWhitelist(address _whitelisted)
    onlyWhitelist
         
    {
        whitelist[_whitelisted] = true;
        Whitelisted(_whitelisted);
    }


     
    function pause()
    onlyStateControl
    requireState(States.Ico)
    {
        moveToState(States.Paused);
    }

     
    function abort()
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Underfunded);
    }

     
    function resumeICO()
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Ico);
    }

     
    function requestRefund()
    requireState(States.Underfunded)
    {
        require(ethPossibleRefunds[msg.sender] > 0);
         
        uint256 payout = ethPossibleRefunds[msg.sender];
         
        ethPossibleRefunds[msg.sender] = 0;
        msg.sender.transfer(payout);
    }

     
    function requestPayout(uint _amount)
    onlyWithdraw  
    requireState(States.Operational)
    {
        msg.sender.transfer(_amount);
    }

     
    function rescueToken(ERC20Basic _foreignToken, address _to)
    onlyTokenAssignmentControl
    requireState(States.Operational)
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(this));
    }
     

     
    function transfer(address _to, uint256 _value)
    requireState(States.Operational)
    returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    requireState(States.Operational)
    returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address _account)
    constant
    returns (uint256 balance) {
        return balances[_account];
    }

     
}
contract CrwdTimelock {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    uint256 public assignedBalance;
     
    address public controller;

     
    uint public releaseTime;

    CrwdToken token;

    function CrwdTimelock(CrwdToken _token, address _controller, uint _releaseTime) {
        require(_releaseTime > now);
        token = _token;
        controller = _controller;
        releaseTime = _releaseTime;
    }

    function assignToBeneficiary(address _beneficiary, uint256 _amount){
        require(msg.sender == controller);
        assignedBalance = assignedBalance.sub(balances[_beneficiary]);
         
         
        require(token.balanceOf(this) >= assignedBalance.add(_amount));
        balances[_beneficiary] = _amount;
         
        assignedBalance = assignedBalance.add(balances[_beneficiary]);
    }

     
    function release(address _beneficiary) {
        require(now >= releaseTime);
        uint amount = balances[_beneficiary];
        require(amount > 0);
        token.transfer(_beneficiary, amount);
        assignedBalance = assignedBalance.sub(amount);
        balances[_beneficiary] = 0;

    }
}