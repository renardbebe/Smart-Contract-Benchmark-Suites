 

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



contract DeepToken is StandardToken {

    using SafeMath for uint256;

     
    enum States {
    Initial,  
    ValuationSet,  
    Ico,  
    Operational,  
    Paused  
    }

    string public constant name = "DeepToken";

    string public constant symbol = "DTA";

    uint8 public constant decimals = 18;

    uint256 public constant pointMultiplier = (10 ** uint256(decimals));

    mapping (address => bool) public whitelist;

    address public initialHolder;

    address public stateControl;

    address public whitelistControl;

    address public withdrawControl;

    address public usdCurrencyFunding;

    States public state;

    uint256 public tokenPriceInWei;

    uint256 public percentForSale;

    uint256 public totalNumberOfTokensForSale;

    uint256 public silencePeriod;

    uint256 public startAcceptingFundsBlock;

    uint256 public endBlock;

    uint256 public etherBalance;

    uint256 public usdCentsBalance;

    uint256 public tokensSold;

     
    function DeepToken(address _stateControl, address _whitelistControl, address _withdraw, address _initialHolder, address _usdCurrencyFunding) {
        require (_initialHolder != address(0));
        require (_stateControl != address(0));
        require (_whitelistControl != address(0));
        require (_withdraw != address(0));
        require (_usdCurrencyFunding != address(0));
        initialHolder = _initialHolder;
        stateControl = _stateControl;
        whitelistControl = _whitelistControl;
        withdrawControl = _withdraw;
        usdCurrencyFunding = _usdCurrencyFunding;
        moveToState(States.Initial);
        totalSupply = 0;
        tokenPriceInWei = 0;
        percentForSale = 0;
        totalNumberOfTokensForSale = 0;
        silencePeriod = 0;
        startAcceptingFundsBlock = uint256(int256(-1));
        endBlock = 0;
        etherBalance = 0;
        usdCentsBalance = 0;
        tokensSold = 0;
        balances[initialHolder] = totalSupply;
    }

    event Whitelisted(address addr);

    event Dewhitelisted(address addr);

    event Credited(address addr, uint balance, uint txAmount);

    event USDCentsBalance(uint balance);

    event TokenByFiatCredited(address addr, uint balance, uint txAmount, uint256 requestId);

    event StateTransition(States oldState, States newState);

    modifier onlyWhitelist() {
        require(msg.sender == whitelistControl);
        _;
    }

    modifier onlyStateControl() {
        require(msg.sender == stateControl);
        _;
    }

    modifier requireState(States _requiredState) {
        require(state == _requiredState);
        _;
    }

     

     
     
     
    function() payable
    requireState(States.Ico)
    {
        require(msg.sender != whitelistControl);
        require(whitelist[msg.sender] == true);
        uint256 deepTokenIncrease = (msg.value * pointMultiplier) / tokenPriceInWei;
        require(getTokensAvailableForSale() >= deepTokenIncrease);
        require(block.number < endBlock);
        require(block.number >= startAcceptingFundsBlock);
        etherBalance = etherBalance.add(msg.value);
        balances[initialHolder] = balances[initialHolder].sub(deepTokenIncrease);
        balances[msg.sender] = balances[msg.sender].add(deepTokenIncrease);
        tokensSold = tokensSold.add(deepTokenIncrease);
        withdrawControl.transfer(msg.value);
        Credited(msg.sender, balances[msg.sender], msg.value);
    }

    function recordPayment(uint256 usdCentsAmount, uint256 tokenAmount, uint256 requestId)
    onlyWhitelist
    requireState(States.Ico)
    {
        require(getTokensAvailableForSale() >= tokenAmount);
        require(block.number < endBlock);
        require(block.number >= startAcceptingFundsBlock);

        usdCentsBalance = usdCentsBalance.add(usdCentsAmount);
        balances[initialHolder] = balances[initialHolder].sub(tokenAmount);
        balances[usdCurrencyFunding] = balances[usdCurrencyFunding].add(tokenAmount);
        tokensSold = tokensSold.add(tokenAmount);

        USDCentsBalance(usdCentsBalance);
        TokenByFiatCredited(usdCurrencyFunding, balances[usdCurrencyFunding], tokenAmount, requestId);
    }

    function moveToState(States _newState)
    internal
    {
        StateTransition(state, _newState);
        state = _newState;
    }

    function getTokensAvailableForSale()
    constant
    returns (uint256 tokensAvailableForSale)
    {
        return (totalNumberOfTokensForSale.sub(tokensSold));
    }

     
     
     
     
     
     
    function updateEthICOThresholds(uint256 _newTotalSupply, uint256 _newTokenPriceInWei, uint256 _newPercentForSale, uint256 _newSilencePeriod, uint256 _newEndBlock)
    onlyStateControl
    {
        require(state == States.Initial || state == States.ValuationSet);
        require(_newTotalSupply > 0);
        require(_newTokenPriceInWei > 0);
        require(_newPercentForSale > 0);
        require(_newPercentForSale <= 100);
        require((_newTotalSupply * _newPercentForSale / 100) > 0);
        require(block.number < _newEndBlock);
        require(block.number + _newSilencePeriod < _newEndBlock);

        totalSupply = _newTotalSupply;
        percentForSale = _newPercentForSale;
        totalNumberOfTokensForSale = totalSupply.mul(percentForSale).div(100);
        tokenPriceInWei = _newTokenPriceInWei;
        silencePeriod = _newSilencePeriod;
        endBlock = _newEndBlock;

        balances[initialHolder] = totalSupply;

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
        burnUnsoldCoins();
        moveToState(States.Operational);
    }

    function anyoneEndICO()
    requireState(States.Ico)
    {
        require(block.number > endBlock);
        burnUnsoldCoins();
        moveToState(States.Operational);
    }

    function burnUnsoldCoins()
    internal
    {
         
        totalSupply = tokensSold.mul(100).div(percentForSale);
        balances[initialHolder] = totalSupply.sub(tokensSold);
    }

    function addToWhitelist(address _whitelisted)
    onlyWhitelist
    {
        whitelist[_whitelisted] = true;
        Whitelisted(_whitelisted);
    }

    function removeFromWhitelist(address _whitelisted)
    onlyWhitelist
    {
        whitelist[_whitelisted] = false;
        Dewhitelisted(_whitelisted);
    }

     
    function pause()
    onlyStateControl
    requireState(States.Ico)
    {
        moveToState(States.Paused);
    }

     
    function resumeICO()
    onlyStateControl
    requireState(States.Paused)
    {
        moveToState(States.Ico);
    }
     

     

    function transfer(address _to, uint256 _value)
    returns (bool success) {
        require((state == States.Ico) || (state == States.Operational));
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value)
    returns (bool success) {
        require((state == States.Ico) || (state == States.Operational));
        return super.transferFrom(_from, _to, _value);
    }

    function balanceOf(address _account)
    constant
    returns (uint256 balance) {
        return balances[_account];
    }

     
}