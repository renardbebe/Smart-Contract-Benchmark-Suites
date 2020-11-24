 

pragma solidity ^0.4.11;
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
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }

}
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];

         
         

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}
library Bonus {
    uint256 constant pointMultiplier = 1e18;  

    uint16 constant ORIGIN_YEAR = 1970;

    function getBonusFactor(uint256 basisTokens, uint timestamp)
    internal pure returns (uint256 factor)
    {
        uint256[4][5] memory factors = [[uint256(300), 400, 500, 750],
        [uint256(200), 300, 400, 600],
        [uint256(150), 250, 300, 500],
        [uint256(100), 150, 250, 400],
        [uint256(0),   100, 150, 300]];

        uint[4] memory cutofftimes = [toTimestamp(2018, 3, 24),
        toTimestamp(2018, 4, 5),
        toTimestamp(2018, 5, 5),
        toTimestamp(2018, 6, 5)];

         
        uint256 tokenAmount = basisTokens / pointMultiplier;

         
        uint256 timeIndex = 4;
        uint256 amountIndex = 0;

         
        if (tokenAmount >= 500000000) {
             
            amountIndex = 3;
        } else if (tokenAmount >= 100000000) {
             
            amountIndex = 2;
        } else if (tokenAmount >= 25000000) {
             
            amountIndex = 1;
        } else {
             
             
        }

        uint256 maxcutoffindex = cutofftimes.length;
        for (uint256 i = 0; i < maxcutoffindex; i++) {
            if (timestamp < cutofftimes[i]) {
                timeIndex = i;
                break;
            }
        }

        return factors[timeIndex][amountIndex];
    }

     
     
    function toTimestamp(uint16 year, uint8 month, uint8 day)
    internal pure returns (uint timestamp) {
        uint16 i;

         
        timestamp += (year - ORIGIN_YEAR) * 1 years;
        timestamp += (leapYearsBefore(year) - leapYearsBefore(ORIGIN_YEAR)) * 1 days;

         
        uint8[12] memory monthDayCounts;
        monthDayCounts[0] = 31;
        if (isLeapYear(year)) {
            monthDayCounts[1] = 29;
        }
        else {
            monthDayCounts[1] = 28;
        }
        monthDayCounts[2] = 31;
        monthDayCounts[3] = 30;
        monthDayCounts[4] = 31;
        monthDayCounts[5] = 30;
        monthDayCounts[6] = 31;
        monthDayCounts[7] = 31;
        monthDayCounts[8] = 30;
        monthDayCounts[9] = 31;
        monthDayCounts[10] = 30;
        monthDayCounts[11] = 31;

        for (i = 1; i < month; i++) {
            timestamp += monthDayCounts[i - 1] * 1 days;
        }

         
        timestamp += (day - 1) * 1 days;

         

        return timestamp;
    }

    function leapYearsBefore(uint year)
    internal pure returns (uint) {
        year -= 1;
        return year / 4 - year / 100 + year / 400;
    }

    function isLeapYear(uint16 year)
    internal pure returns (bool) {
        if (year % 4 != 0) {
            return false;
        }
        if (year % 100 != 0) {
            return true;
        }
        if (year % 400 != 0) {
            return false;
        }
        return true;
    }
}

contract ClearToken is StandardToken {

     
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

    string public constant name = "CLEAR Token";

    string public constant symbol = "CLEAR";

    uint8 public constant decimals = 18;

    mapping(address => bool) public whitelist;

    address public reserves;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    address public tokenAssignmentControl;

    States public state;

    uint256 public startAcceptingFundsBlock;

    uint256 public endTimestamp;

    uint256 public ETH_CLEAR;  

    uint256 public constant NZD_CLEAR = 50;  

    uint256 constant pointMultiplier = 1e18;  

    uint256 public constant maxTotalSupply = 102400000000 * pointMultiplier;  

    uint256 public constant percentForSale = 30;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;


     
    function ClearToken(
        address _stateControl
    , address _whitelistControl
    , address _withdrawControl
    , address _tokenAssignmentControl
    , address _reserves
    ) public
    {
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdrawControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        moveToState(States.Initial);
        endTimestamp = 0;
        ETH_CLEAR = 0;
        totalSupply = maxTotalSupply;
        soldTokens = 0;
        reserves = _reserves;
        balances[reserves] = totalSupply;
        Mint(reserves, totalSupply);
        Transfer(0x0, reserves, totalSupply);
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
    public
    requireState(States.Ico)
    {
        require(whitelist[msg.sender] == true);

        require(block.timestamp < endTimestamp);
        require(block.number >= startAcceptingFundsBlock);

        uint256 soldToTuserWithBonus = calcBonus(msg.value);

        issueTokensToUser(msg.sender, soldToTuserWithBonus);
        ethPossibleRefunds[msg.sender] = ethPossibleRefunds[msg.sender].add(msg.value);
    }

    function issueTokensToUser(address beneficiary, uint256 amount)
    internal
    {
        uint256 soldTokensAfterInvestment = soldTokens.add(amount);
        require(soldTokensAfterInvestment <= maxTotalSupply.mul(percentForSale).div(100));

        balances[beneficiary] = balances[beneficiary].add(amount);
        balances[reserves] = balances[reserves].sub(amount);
        soldTokens = soldTokensAfterInvestment;
        Transfer(reserves, beneficiary, amount);
    }

    function calcBonus(uint256 weiAmount)
    constant
    public
    returns (uint256 resultingTokens)
    {
        uint256 basisTokens = weiAmount.mul(ETH_CLEAR);
         
        uint256 perMillBonus = Bonus.getBonusFactor(basisTokens, now);
         
        return basisTokens.mul(per_mill + perMillBonus).div(per_mill);
    }

    uint256 constant per_mill = 1000;


    function moveToState(States _newState)
    internal
    {
        StateTransition(state, _newState);
        state = _newState;
    }
     
     
     
    function updateEthICOVariables(uint256 _new_ETH_NZD, uint256 _newEndTimestamp)
    public
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet);
        require(_new_ETH_NZD > 0);
        require(block.timestamp < _newEndTimestamp);
        endTimestamp = _newEndTimestamp;
         
        ETH_CLEAR = _new_ETH_NZD.mul(NZD_CLEAR);
         
        moveToState(States.ValuationSet);
    }

    function updateETHNZD(uint256 _new_ETH_NZD)
    public
    onlyTokenAssignmentControl
    requireState(States.Ico)
    {
        require(_new_ETH_NZD > 0);
        ETH_CLEAR = _new_ETH_NZD.mul(NZD_CLEAR);
    }

    function startICO()
    public
    onlyStateControl
    requireState(States.ValuationSet)
    {
        require(block.timestamp < endTimestamp);
        startAcceptingFundsBlock = block.number;
        moveToState(States.Ico);
    }

    function addPresaleAmount(address beneficiary, uint256 amount)
    public
    onlyTokenAssignmentControl
    {
        require(state == States.ValuationSet || state == States.Ico);
        issueTokensToUser(beneficiary, amount);
    }


    function endICO()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        finishMinting();
        moveToState(States.Operational);
    }

    function anyoneEndICO()
    public
    requireState(States.Ico)
    {
        require(block.timestamp > endTimestamp);
        finishMinting();
        moveToState(States.Operational);
    }

    function finishMinting()
    internal
    {
        mintingFinished = true;
        MintFinished();
    }

    function addToWhitelist(address _whitelisted)
    public
    onlyWhitelist
         
    {
        whitelist[_whitelisted] = true;
        Whitelisted(_whitelisted);
    }


     
    function pause()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        moveToState(States.Paused);
    }

     
    function abort()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Underfunded);
    }

     
    function resumeICO()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Ico);
    }

     
    function requestRefund()
    public
    requireState(States.Underfunded)
    {
        require(ethPossibleRefunds[msg.sender] > 0);
         
        uint256 payout = ethPossibleRefunds[msg.sender];
         
        ethPossibleRefunds[msg.sender] = 0;
        msg.sender.transfer(payout);
    }

     
    function requestPayout(uint _amount)
    public
    onlyWithdraw  
    requireState(States.Operational)
    {
        msg.sender.transfer(_amount);
    }

     
    function rescueToken(ERC20Basic _foreignToken, address _to)
    public
    onlyTokenAssignmentControl
    requireState(States.Operational)
    {
        _foreignToken.transfer(_to, _foreignToken.balanceOf(this));
    }
     

     
    function transfer(address _to, uint256 _value)
    public
    requireState(States.Operational)
    returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    requireState(States.Operational)
    returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address _account)
    public
    constant
    returns (uint256 balance) {
        return balances[_account];
    }

     
}