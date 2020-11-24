 

contract Ownable {
  address public owner;



   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


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

contract medibitICO is Pausable {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

mapping (address => mapping (address => uint256)) internal allowed;


   
  uint constant public minPublicContribAmount = 1 ether;
  

   
  medibitToken public token;
  uint256 constant public tokenDecimals = 18;


   
  uint256 public startTime; 
  uint256 public endTime; 


   
  bool public icoEnabled;

   
  address public walletOne;

   
  uint256 public weiRaised;

   
  uint256 public totalSupply = 50000000000 * (10 ** tokenDecimals);
  uint256 constant public toekensForBTCandBonus = 12500000000 * (10 ** tokenDecimals);
  uint256 constant public toekensForTeam = 5000000000 * (10 ** tokenDecimals);
  uint256 constant public toekensForOthers = 22500000000 * (10 ** tokenDecimals);


   
   
  uint256 public icoCap;
  uint256 public icoSoldTokens;
  bool public icoEnded = false;

  address constant public walletTwo = 0x938Ee925D9EFf6698472a19EbAc780667999857B;
  address constant public walletThree = 0x09E72590206d652BD1aCDB3A8e358AeB3f21513A;

   

  uint256 constant public STANDARD_RATE = 1500000;

  event Burn(address indexed from, uint256 value);


   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);



  function medibitICO(address _walletOne) public {
    require(_walletOne != address(0));
    token = createTokenContract();
    
     
    uint256 tokensToWallet1 = toekensForBTCandBonus;
    uint256 tokensToWallet2 = toekensForTeam;
    uint256 tokensToWallet3 = toekensForOthers;
    
    walletOne = _walletOne;
    
    token.transfer(walletOne, tokensToWallet1);
    token.transfer(walletTwo, tokensToWallet2);
    token.transfer(walletThree, tokensToWallet3);
  }


   
   
   

   
   
  function createTokenContract() internal returns (medibitToken) {
    return new medibitToken();
  }


   
  function enableTokenTransferability() external onlyOwner {
    require(token != address(0));
    token.unpause();
  }

   
  function disableTokenTransferability() external onlyOwner {
    require(token != address(0));
    token.pause();
  }

   
   function transferUnsoldIcoTokens() external onlyOwner {
    require(token != address(0));
    uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
    token.transfer(walletOne, unsoldTokens);
   }

   
   
   

   
  function setwalletOne(address _walletOne) external onlyOwner{
     
    require(!icoEnabled || now < startTime);
    require(_walletOne != address(0));
    walletOne = _walletOne;
  }


   
  function setContributionDates(uint64 _startTime, uint64 _endTime) external onlyOwner{
    require(!icoEnabled);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    startTime = _startTime;
    endTime = _endTime;
  }


   
   
   
   
  function enableICO() external onlyOwner{
    icoEnabled = true;
    icoCap = totalSupply;
  }

   
  function () payable whenNotPaused public {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 returnWeiAmount;

     
    uint rate = getRate();
    assert(rate > 0);
    uint256 tokens = weiAmount.mul(rate);

    uint256 newIcoSoldTokens = icoSoldTokens.add(tokens);

    if (newIcoSoldTokens > icoCap) {
        newIcoSoldTokens = icoCap;
        tokens = icoCap.sub(icoSoldTokens);
        uint256 newWeiAmount = tokens.div(rate);
        returnWeiAmount = weiAmount.sub(newWeiAmount);
        weiAmount = newWeiAmount;
    }

     
    weiRaised = weiRaised.add(weiAmount);

    token.transfer(beneficiary, tokens);
    icoSoldTokens = newIcoSoldTokens;
    if (returnWeiAmount > 0){
        msg.sender.transfer(returnWeiAmount);
    }

    emit TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
   
  function forwardFunds() internal {
    walletOne.transfer(address(this).balance);
  }



   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonMinimumPurchase;
    bool icoTokensAvailable = icoSoldTokens < icoCap;
 
    nonMinimumPurchase = msg.value >= minPublicContribAmount;
    

    return !icoEnded && icoEnabled && withinPeriod && nonMinimumPurchase && icoTokensAvailable;
  }



   
  function endIco() external onlyOwner {
    icoEnded = true;
     
    uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
    token.transfer(walletOne, unsoldTokens);
  }

   
  function hasEnded() public constant returns (bool) {
    return (icoEnded || icoSoldTokens >= icoCap || now > endTime);
  }


  function getRate() public constant returns(uint){
    require(now >= startTime);
      return STANDARD_RATE;

  }

   
  function drain() external onlyOwner {
    owner.transfer(address(this).balance);
  }

}







contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}


library SafeERC20 {
 function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    ERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    require(token.approve(spender, value));
  }
}


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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}



contract PausableToken is StandardToken, Pausable {
   
  modifier whenNotPausedOrOwner() {
    require(msg.sender == owner || !paused);
    _;
  }

  function transfer(address _to, uint256 _value) public whenNotPausedOrOwner returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrOwner returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPausedOrOwner returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPausedOrOwner returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPausedOrOwner returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }

}

contract medibitToken is PausableToken {
  string constant public name = "MEDIBIT";
  string constant public symbol = "MEDIBIT";
  uint256 constant public decimals = 18;
  uint256 constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 constant INITIAL_SUPPLY = 50000000000 * TOKEN_UNIT;


  function medibitToken() public {
     
    paused = true;
     
    totalSupply = INITIAL_SUPPLY;
    emit Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    balances[msg.sender] = INITIAL_SUPPLY;
  }

}

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}