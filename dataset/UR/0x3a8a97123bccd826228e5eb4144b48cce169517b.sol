 

pragma solidity ^0.4.11;

 

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 

contract QravityTeamTimelock {
    using SafeMath for uint256;

    uint16 constant ORIGIN_YEAR = 1970;

     
    address public controller;

    uint256 public releasedAmount;

    ERC20Basic token;

    function QravityTeamTimelock(ERC20Basic _token, address _controller)
    public
    {
        require(address(_token) != 0x0);
        require(_controller != 0x0);
        token = _token;
        controller = _controller;
    }

     
    function release(address _beneficiary, uint256 _amount)
    public
    {
        require(msg.sender == controller);
        require(_amount > 0);
        require(_amount <= availableAmount(now));
        token.transfer(_beneficiary, _amount);
        releasedAmount = releasedAmount.add(_amount);
    }

    function availableAmount(uint256 timestamp)
    public view
    returns (uint256 amount)
    {
        uint256 totalWalletAmount = releasedAmount.add(token.balanceOf(this));
        uint256 canBeReleasedAmount = totalWalletAmount.mul(availablePercent(timestamp)).div(100);
        return canBeReleasedAmount.sub(releasedAmount);
    }

    function availablePercent(uint256 timestamp)
    public view
    returns (uint256 factor)
    {
       uint256[10] memory releasePercent = [uint256(0), 20, 30, 40, 50, 60, 70, 80, 90, 100];
       uint[10] memory releaseTimes = [
           toTimestamp(2020, 4, 1),
           toTimestamp(2020, 7, 1),
           toTimestamp(2020, 10, 1),
           toTimestamp(2021, 1, 1),
           toTimestamp(2021, 4, 1),
           toTimestamp(2021, 7, 1),
           toTimestamp(2021, 10, 1),
           toTimestamp(2022, 1, 1),
           toTimestamp(2022, 4, 1),
           0
        ];

         
        uint256 timeIndex = 0;

        for (uint256 i = 0; i < releaseTimes.length; i++) {
            if (timestamp < releaseTimes[i] || releaseTimes[i] == 0) {
                timeIndex = i;
                break;
            }
        }
        return releasePercent[timeIndex];
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

 

library Bonus {
    uint16 constant ORIGIN_YEAR = 1970;
    struct BonusData {
        uint[7] factors;  
        uint[6] cutofftimes;
    }

     
    function initBonus(BonusData storage data)
    internal
    {
        data.factors = [uint256(300), 250, 200, 150, 100, 50, 0];
        data.cutofftimes = [toTimestamp(2018, 9, 1),
                            toTimestamp(2018, 9, 8),
                            toTimestamp(2018, 9, 15),
                            toTimestamp(2018, 9, 22),
                            toTimestamp(2018, 9, 29),
                            toTimestamp(2018, 10, 8)];
    }

    function getBonusFactor(uint timestamp, BonusData storage data)
    internal view returns (uint256 factor)
    {
        uint256 countcutoffs = data.cutofftimes.length;
         
        uint256 timeIndex = countcutoffs;

        for (uint256 i = 0; i < countcutoffs; i++) {
            if (timestamp < data.cutofftimes[i]) {
                timeIndex = i;
                break;
            }
        }

        return data.factors[timeIndex];
    }

    function getFollowingCutoffTime(uint timestamp, BonusData storage data)
    internal view returns (uint nextTime)
    {
        uint256 countcutoffs = data.cutofftimes.length;
         
        nextTime = 0;

        for (uint256 i = 0; i < countcutoffs; i++) {
            if (timestamp < data.cutofftimes[i]) {
                nextTime = data.cutofftimes[i];
                break;
            }
        }

        return nextTime;
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

 

 
pragma solidity ^0.4.11;




contract QCOToken is StandardToken {

     
    enum States {
        Initial,  
        ValuationSet,
        Ico,  
        Aborted,  
        Operational,  
        Paused          
    }

    mapping(address => uint256) public ethPossibleRefunds;

    uint256 public soldTokens;

    string public constant name = "Qravity Coin Token";

    string public constant symbol = "QCO";

    uint8 public constant decimals = 18;

    mapping(address => bool) public whitelist;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    address public tokenAssignmentControl;

    address public teamWallet;

    address public reserves;

    States public state;

    uint256 public endBlock;

    uint256 public ETH_QCO;  

    uint256 constant pointMultiplier = 1e18;  

    uint256 public constant maxTotalSupply = 1000000000 * pointMultiplier;  

    uint256 public constant percentForSale = 50;

    Bonus.BonusData bonusData;

    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;

     
    uint256 public pauseOffset = 0;

    uint256 public pauseLastStart = 0;


     
    function QCOToken(
        address _stateControl
    , address _whitelistControl
    , address _withdrawControl
    , address _tokenAssignmentControl
    , address _teamControl
    , address _reserves)
    public
    {
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdrawControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        moveToState(States.Initial);
        endBlock = 0;
        ETH_QCO = 0;
        totalSupply = maxTotalSupply;
        soldTokens = 0;
        Bonus.initBonus(bonusData);
        teamWallet = address(new QravityTeamTimelock(this, _teamControl));

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
        require(msg.value > 0);
         
         
        require(msg.data.length < 4);
        require(block.number < endBlock);

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

    function getCurrentBonusFactor()
    public view
    returns (uint256 factor)
    {
         
        return Bonus.getBonusFactor(now - pauseOffset, bonusData);
    }

    function getNextCutoffTime()
    public view returns (uint timestamp)
    {
        return Bonus.getFollowingCutoffTime(now - pauseOffset, bonusData);
    }

    function calcBonus(uint256 weiAmount)
    constant
    public
    returns (uint256 resultingTokens)
    {
        uint256 basisTokens = weiAmount.mul(ETH_QCO);
         
        uint256 perMillBonus = getCurrentBonusFactor();
         
        return basisTokens.mul(per_mill + perMillBonus).div(per_mill);
    }

    uint256 constant per_mill = 1000;


    function moveToState(States _newState)
    internal
    {
        StateTransition(state, _newState);
        state = _newState;
    }
     
     
     
    function updateEthICOVariables(uint256 _new_ETH_QCO, uint256 _newEndBlock)
    public
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet);
        require(_new_ETH_QCO > 0);
        require(block.number < _newEndBlock);
        endBlock = _newEndBlock;
         
        ETH_QCO = _new_ETH_QCO;
        moveToState(States.ValuationSet);
    }

    function startICO()
    public
    onlyStateControl
    requireState(States.ValuationSet)
    {
        require(block.number < endBlock);
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
        burnAndFinish();
        moveToState(States.Operational);
    }

    function anyoneEndICO()
    public
    requireState(States.Ico)
    {
        require(block.number > endBlock);
        burnAndFinish();
        moveToState(States.Operational);
    }

    function burnAndFinish()
    internal
    {
        totalSupply = soldTokens.mul(100).div(percentForSale);

        uint256 teamAmount = totalSupply.mul(22).div(100);
        balances[teamWallet] = teamAmount;
        Transfer(reserves, teamWallet, teamAmount);

        uint256 reservesAmount = totalSupply.sub(soldTokens).sub(teamAmount);
         
        Transfer(reserves, 0x0, balances[reserves].sub(reservesAmount).sub(teamAmount));
        balances[reserves] = reservesAmount;

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
        pauseLastStart = now;
    }

     
    function abort()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Aborted);
    }

     
    function resumeICO()
    public
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Ico);
         
        pauseOffset = pauseOffset + (now - pauseLastStart);
    }

     
    function requestRefund()
    public
    requireState(States.Aborted)
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

     
}