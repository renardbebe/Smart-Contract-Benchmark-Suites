 

pragma solidity ^0.5.0;

 

 
 

pragma solidity ^0.5.12;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

 
 

pragma solidity ^0.5.12;




 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender], "too little");
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
 

pragma solidity ^0.5.12;



 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
 

pragma solidity ^0.5.12;




 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

 

 
pragma solidity ^0.5.12;


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

    string public constant name = "CRWDToken";

    string public constant symbol = "CRWT";

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

     
    constructor(
        address _stateControl,
        address _whitelistControl,
        address _withdrawControl,
        address _tokenAssignmentControl,
        address _notLocked,  
        address _lockedTeam,  
        address _lockedDev,  
        address _lockedCountry  
    ) public {
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdrawControl;
        tokenAssignmentControl = _tokenAssignmentControl;
        moveToState(States.Initial);
        weiICOMinimum = 0;
         
        weiICOMaximum = 0;
        endBlock = 0;
        ETH_CRWDTOKEN = 0;
        totalSupply_ = 0;
        soldTokens = 0;
        teamTimeLock = _lockedTeam;
        devTimeLock = _lockedDev;
        countryTimeLock = _lockedCountry;
        miscNotLocked = _notLocked;
    }

    event Whitelisted(address addr);

    event StateTransition(States oldState, States newState);

    modifier onlyWhitelist() {
        require(msg.sender == whitelistControl, "only whitelisted wallets");
        _;
    }

    modifier onlyStateControl() {
        require(msg.sender == stateControl, "only state-controller");
        _;
    }

    modifier onlyTokenAssignmentControl() {
        require(msg.sender == tokenAssignmentControl, "only assignment controller");
        _;
    }

    modifier onlyWithdraw() {
        require(msg.sender == withdrawControl, "only withdraw controller");
        _;
    }

    modifier requireState(States _requiredState) {
        require(state == _requiredState, "invalid token state");
        _;
    }

    modifier requireAnyOfTwoStates(States _requiredState1, States _requiredState2) {
        require(state == _requiredState1 || state == _requiredState2, "wrong token state");
        _;
    }

     

     
     
     
    function() external payable
    requireState(States.Ico)
    {
        require(whitelist[msg.sender] == true, "not whitelisted");
        require(address(this).balance <= weiICOMaximum, "weiICOMaximum");
         
        require(block.number < endBlock, "endBlock reached");
        require(block.number >= startAcceptingFundsBlock, "startBlock future");

        uint256 basisTokens = msg.value.mul(ETH_CRWDTOKEN);

        issueTokensToUser(msg.sender, basisTokens);
        ethPossibleRefunds[msg.sender] = ethPossibleRefunds[msg.sender].add(msg.value);
    }

    function issueTokensToUser(address beneficiary, uint256 amount)
    internal
    {
        balances[beneficiary] = balances[beneficiary].add(amount);
        soldTokens = soldTokens.add(amount);
        totalSupply_ = totalSupply_.add(amount.mul(100).div(percentForSale));
        emit Mint(beneficiary, amount);
        emit Transfer(address(0x0), beneficiary, amount);
    }

    function issuePercentToReserve(address beneficiary, uint256 percentOfSold)
    internal
    {
        uint256 amount = totalSupply_.mul(percentOfSold).div(100);
        balances[beneficiary] = balances[beneficiary].add(amount);
        emit Mint(beneficiary, amount);
        emit Transfer(address(0x0), beneficiary, amount);
    }

    function moveToState(States _newState)
    internal
    {
        emit StateTransition(state, _newState);
        state = _newState;
    }

     
     
     
     
     
    function updateEthICOThresholds(uint256 _newWeiICOMinimum, uint256 _newWeiICOMaximum, uint256 _silencePeriod, uint256 _newEndBlock)
    public
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet, "invalid state");
        require(_newWeiICOMaximum > _newWeiICOMinimum, "weiMax");
        require(block.number + silencePeriod < _newEndBlock, "high silence");
        require(block.number < _newEndBlock, "past endBock");
        weiICOMinimum = _newWeiICOMinimum;
        weiICOMaximum = _newWeiICOMaximum;
        silencePeriod = _silencePeriod;
        endBlock = _newEndBlock;
         
        ETH_CRWDTOKEN = maxTotalSupply.mul(percentForSale).div(100).div(weiICOMaximum);
         
        moveToState(States.ValuationSet);
    }

    function startICO()
    public
    onlyStateControl
    requireState(States.ValuationSet)
    {
        require(block.number < endBlock, "ended");
        require(block.number + silencePeriod < endBlock, "ended w silence");
        startAcceptingFundsBlock = block.number + silencePeriod;
        moveToState(States.Ico);
    }

    function addPresaleAmount(address beneficiary, uint256 amount)
    public
    onlyTokenAssignmentControl
    {
        require(state == States.ValuationSet || state == States.Ico, "invalid token state");
        issueTokensToUser(beneficiary, amount);
    }


    function endICO()
    public
    onlyStateControl
    requireState(States.Ico)
    {
        if (address(this).balance < weiICOMinimum) {
            moveToState(States.Underfunded);
        }
        else {
            burnAndFinish();
            moveToState(States.Operational);
        }
    }

    function anyoneEndICO()
    public
    requireState(States.Ico)
    {
        require(block.number > endBlock, "not ended");
        if (address(this).balance < weiICOMinimum) {
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

        totalSupply_ = soldTokens
        .add(balances[teamTimeLock])
        .add(balances[devTimeLock])
        .add(balances[countryTimeLock])
        .add(balances[miscNotLocked]);

        mintingFinished = true;
        emit MintFinished();
    }

    function addToWhitelist(address _whitelisted)
    public
    onlyWhitelist
         
    {
        whitelist[_whitelisted] = true;
        emit Whitelisted(_whitelisted);
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
        require(ethPossibleRefunds[msg.sender] > 0, "nothing to refund");
         
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
        _foreignToken.transfer(_to, _foreignToken.balanceOf(address(this)));
    }
     

     
    function transfer(address _to, uint256 _value)
    public
    requireAnyOfTwoStates(States.Operational, States.Ico)
    returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    public
    requireAnyOfTwoStates(States.Operational, States.Ico)
    returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address _account)
    public
    view
    returns (uint256 balance) {
        return balances[_account];
    }

     
}