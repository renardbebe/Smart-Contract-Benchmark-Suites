 

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

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

contract HeroCoin is StandardToken {

     
    enum States {
    Initial,  
    ValuationSet,
    Ico,  
    Underfunded,  
    Operational,  
    Paused          
    }

     
    address public  rakeEventPlaceholderAddress = 0x0000000000000000000000000000000000000000;

    string public constant name = "Herocoin";

    string public constant symbol = "PLAY";

    uint8 public constant decimals = 18;

    mapping (address => bool) public whitelist;

    address public initialHolder;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    States public state;

    uint256 public weiICOMinimum;

    uint256 public weiICOMaximum;

    uint256 public silencePeriod;

    uint256 public startAcceptingFundsBlock;

    uint256 public endBlock;

    uint256 public ETH_HEROCOIN;  

    mapping (address => uint256) lastRakePoints;


    uint256 pointMultiplier = 1e18;  
    uint256 totalRakePoints;  
    uint256 unclaimedRakes;  
    uint256 constant percentForSale = 30;

    mapping (address => bool) public contests;  

     
    function HeroCoin(address _stateControl, address _whitelistControl, address _withdraw, address _initialHolder) {
        initialHolder = _initialHolder;
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdraw;
        moveToState(States.Initial);
        weiICOMinimum = 0;
         
        weiICOMaximum = 0;
        endBlock = 0;
        ETH_HEROCOIN = 0;
        totalSupply = 2000000000 * pointMultiplier;
         
        balances[initialHolder] = totalSupply;
         
    }

    event ContestAnnouncement(address addr);

    event Whitelisted(address addr);

    event Credited(address addr, uint balance, uint txAmount);

    event StateTransition(States oldState, States newState);

    modifier onlyWhitelist() {
        require(msg.sender == whitelistControl);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == initialHolder);
        _;
    }

    modifier onlyStateControl() {
        require(msg.sender == stateControl);
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
        uint256 heroCoinIncrease = msg.value * ETH_HEROCOIN;
        balances[initialHolder] -= heroCoinIncrease;
        balances[msg.sender] += heroCoinIncrease;
        Credited(msg.sender, balances[msg.sender], msg.value);
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
         
        ETH_HEROCOIN = ((totalSupply * percentForSale) / 100) / weiICOMaximum;
         
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


    function endICO()
    onlyStateControl
    requireState(States.Ico)
    {
        if (this.balance < weiICOMinimum) {
            moveToState(States.Underfunded);
        }
        else {
            burnUnsoldCoins();
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
            burnUnsoldCoins();
            moveToState(States.Operational);
        }
    }

    function burnUnsoldCoins()
    internal
    {
        uint256 soldcoins = this.balance * ETH_HEROCOIN;
        totalSupply = soldcoins * 100 / percentForSale;
        balances[initialHolder] = totalSupply - soldcoins;
         
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
        require(balances[msg.sender] > 0);
         
        uint256 payout = balances[msg.sender] / ETH_HEROCOIN;
         
        balances[msg.sender] = 0;
        msg.sender.transfer(payout);
    }

     
    function requestPayout(uint _amount)
    onlyWithdraw  
    requireState(States.Operational)
    {
        msg.sender.transfer(_amount);
    }
     

     
    function transfer(address _to, uint256 _value)
    requireState(States.Operational)
    updateAccount(msg.sender)  
    updateAccount(_to)  
    enforceRake(msg.sender, _value)
    returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    requireState(States.Operational)
    updateAccount(_from)  
    updateAccount(_to)  
    enforceRake(_from, _value)
    returns (bool success) {
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address _account)
    constant
    returns (uint256 balance) {
        return balances[_account] + rakesOwing(_account);
    }

    function payRake(uint256 _value)
    requireState(States.Operational)
    updateAccount(msg.sender)
    returns (bool success) {
        return payRakeInternal(msg.sender, _value);
    }


    function
    payRakeInternal(address _sender, uint256 _value)
    internal
    returns (bool success) {

        if (balances[_sender] <= _value) {
            return false;
        }
        if (_value != 0) {
            Transfer(_sender, rakeEventPlaceholderAddress, _value);
            balances[_sender] -= _value;
            unclaimedRakes += _value;
             
            uint256 pointsPaid = _value * pointMultiplier / totalSupply;
            totalRakePoints += pointsPaid;
        }
        return true;

    }
     
     
    modifier updateAccount(address _account) {
        uint256 owing = rakesOwing(_account);
        if (owing != 0) {
            unclaimedRakes -= owing;
            balances[_account] += owing;
            Transfer(rakeEventPlaceholderAddress, _account, owing);
        }
         
        lastRakePoints[_account] = totalRakePoints;
        _;
    }

     
    function rakesOwing(address _account)
    internal
    constant
    returns (uint256) { 
         
        uint256 newRakePoints = totalRakePoints - lastRakePoints[_account];
         
         
        uint256 basicPoints = balances[_account] * newRakePoints;
         
         
        return (basicPoints) / pointMultiplier;
    }
     

     

    modifier enforceRake(address _contest, uint256 _value){
         
         
         
        if (contests[_contest]) {
            uint256 toPay = _value - ((_value * 99) / 100);
            bool paid = payRakeInternal(_contest, toPay);
            require(paid);
        }
        _;
    }

     


     
     
     
    function registerContest()
    {
        contests[msg.sender] = true;
        ContestAnnouncement(msg.sender);
    }
}