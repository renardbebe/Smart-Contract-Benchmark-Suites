 

 

pragma solidity ^0.4.18;

 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
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


 
contract TaylorToken is Ownable{

    using SafeMath for uint256;

     
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    event Burn(address indexed _owner, uint256 _amount);
     
    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;

     
    mapping (address => bool) public whitelistedTransfer;
    mapping (address => bool) public whitelistedBurn;

    string public name = "Taylor";
    string public symbol = "TAY";
    uint8 public decimals = 18;
    uint256 constant internal DECIMAL_CASES = 10**18;
    uint256 public totalSupply = 10**7 * DECIMAL_CASES;
    bool public transferable = false;

     
    modifier onlyWhenTransferable(){
      if(!whitelistedTransfer[msg.sender]){
        require(transferable);
      }
      _;
    }

     

     
    function TaylorToken()
      Ownable()
      public
    {
      balances[owner] = balances[owner].add(totalSupply);
      whitelistedTransfer[msg.sender] = true;
      whitelistedBurn[msg.sender] = true;
      Transfer(address(0),owner, totalSupply);
    }

     

     
    function activateTransfers()
      public
      onlyOwner
    {
      transferable = true;
    }

     
    function addWhitelistedTransfer(address _address)
      public
      onlyOwner
    {
      whitelistedTransfer[_address] = true;
    }

     
    function distribute(address _tgeAddress)
      public
      onlyOwner
    {
      whitelistedTransfer[_tgeAddress] = true;
      transfer(_tgeAddress, balances[owner]);
    }


     
    function addWhitelistedBurn(address _address)
      public
      onlyOwner
    {
      whitelistedBurn[_address] = true;
    }

     

     
    function transfer(address _to, uint256 _value)
      public
      onlyWhenTransferable
      returns (bool success)
    {
      require(_to != address(0));
      require(_value <= balances[msg.sender]);

      balances[msg.sender] = balances[msg.sender].sub(_value);
      balances[_to] = balances[_to].add(_value);
      Transfer(msg.sender, _to, _value);
      return true;
    }

     
    function transferFrom
      (address _from,
        address _to,
        uint256 _value)
        public
        onlyWhenTransferable
        returns (bool success) {
      require(_to != address(0));
      require(_value <= balances[_from]);
      require(_value <= allowed[_from][msg.sender]);

      balances[_from] = balances[_from].sub(_value);
      balances[_to] = balances[_to].add(_value);
      allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
      Transfer(_from, _to, _value);
      return true;
    }

     
    function approve(address _spender, uint256 _value)
      public
      onlyWhenTransferable
      returns (bool success)
    {
      allowed[msg.sender][_spender] = _value;
      Approval(msg.sender, _spender, _value);
      return true;
    }

       
    function increaseApproval(address _spender, uint _addedValue)
      public
      returns (bool)
    {
      allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

     
    function decreaseApproval(address _spender, uint _subtractedValue)
      public
      returns (bool)
    {
      uint oldValue = allowed[msg.sender][_spender];
      if (_subtractedValue > oldValue) {
        allowed[msg.sender][_spender] = 0;
      } else {
        allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
      }
      Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
      return true;
    }

     
    function burn(uint256 _amount)
      public
      returns (bool success)
    {
      require(whitelistedBurn[msg.sender]);
      require(_amount <= balances[msg.sender]);
      balances[msg.sender] = balances[msg.sender].sub(_amount);
      totalSupply =  totalSupply.sub(_amount);
      Burn(msg.sender, _amount);
      return true;
    }


     

     
    function balanceOf(address _owner) view public returns (uint256 balance) {
        return balances[_owner];
    }

     
    function allowance(address _owner, address _spender)
      view
      public
      returns (uint256 remaining)
    {
      return allowed[_owner][_spender];
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
    Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    Unpause();
  }
}


 
contract Crowdsale is Ownable, Pausable {

  using SafeMath for uint256;

   
  event Purchase(address indexed buyer, uint256 weiAmount, uint256 tokenAmount);
  event Finalized(uint256 tokensSold, uint256 weiAmount);

   
  TaylorToken public taylorToken;

  uint256 public startTime;
  uint256 public endTime;
  uint256 public weiRaised;
  uint256 public tokensSold;
  uint256 public tokenCap;
  uint256 public poolEthSold;
  bool public finalized;
  address public wallet;

  uint256 public maxGasPrice = 50000000000;

  uint256[4] public rates;

  mapping (address => bool) public whitelisted;
  mapping (address => bool) public whitelistedPools;
  mapping (address => uint256) public contributors;

   
  uint256 public constant poolEthCap = 1250 ether;
  uint256 public constant minimumPoolPurchase = 100 ether;
  uint256 public constant minimumPurchase = 0.01 ether;
  uint256 public constant maximumPoolPurchase = 250 ether;
  uint256 public constant maximumPurchase = 50 ether;
  uint256 public constant specialPoolsRate = 600000000000000;



   

   
  function Crowdsale(
    uint256 _startTime,
    uint256 _duration,
    uint256 _tokenCap,
    address _token,
    address _wallet)
    public
  {
    require(_startTime >= now);
    require(_token != address(0));
    require(_wallet != address(0));

    taylorToken = TaylorToken(_token);

    startTime = _startTime;
    endTime = startTime + _duration * 1 seconds ;
    wallet = _wallet;
    tokenCap = _tokenCap;
    rates = [700000000000000, 790000000000000, 860000000000000, 930000000000000];
  }


   

   
  function () payable whenNotPaused public {
    buyTokens();
  }

   
  function buyTokens() payable whenNotPaused public {
    require(isValidPurchase());

    uint256 tokens;
    uint256 amount = msg.value;


    if(whitelistedPools[msg.sender] && poolEthSold.add(amount) > poolEthCap){
      uint256 validAmount = poolEthCap.sub(poolEthSold);
      require(validAmount > 0);
      uint256 ch = amount.sub(validAmount);
      msg.sender.transfer(ch);
      amount = validAmount;
    }

    tokens  = calculateTokenAmount(amount);


    uint256 tokenPool = tokensSold.add(tokens);
    if(tokenPool > tokenCap){
      uint256 possibleTokens = tokenCap.sub(tokensSold);
      uint256 change = calculatePriceForTokens(tokens.sub(possibleTokens));
      msg.sender.transfer(change);
      tokens = possibleTokens;
      amount = amount.sub(change);
    }



    contributors[msg.sender] = contributors[msg.sender].add(amount);
    taylorToken.transfer(msg.sender, tokens);

    tokensSold = tokensSold.add(tokens);
    weiRaised = weiRaised.add(amount);
    if(whitelistedPools[msg.sender]){
      poolEthSold = poolEthSold.add(amount);
    }


    forwardFunds(amount);
    Purchase(msg.sender, amount, tokens);

    if(tokenCap.sub(tokensSold) < calculateTokenAmount(minimumPurchase)){
      finalizeSale();
    }
  }

   
  function addWhitelisted(address _address, bool isPool)
    public
    onlyOwner
    whenNotPaused
  {
    if(isPool) {
      whitelistedPools[_address] = true;
    } else {
      whitelisted[_address] = true;
    }
  }

   
  function changeMaxGasprice(uint256 _gasPrice)
    public
    onlyOwner
    whenNotPaused
  {
    maxGasPrice = _gasPrice;
  }

   
  function endSale() whenNotPaused public {
    require(finalized ==  false);
    require(now > endTime);
    finalizeSale();
  }

   

   
  function isValidPurchase() view internal returns(bool valid) {
    require(now >= startTime && now <= endTime);
    require(msg.value >= minimumPurchase);
    require(tx.gasprice <= maxGasPrice);
    uint256 week = getCurrentWeek();
    if(week == 0 && whitelistedPools[msg.sender]){
      require(msg.value >= minimumPoolPurchase);
      require(contributors[msg.sender].add(msg.value) <= maximumPoolPurchase);
    } else {
      require(whitelisted[msg.sender] || whitelistedPools[msg.sender]);
      require(contributors[msg.sender].add(msg.value) <= maximumPurchase);
    }
    return true;
  }



   
  function forwardFunds(uint256 _amount) internal {
    wallet.transfer(_amount);
  }

   
  function calculateTokenAmount(uint256 weiAmount) view internal returns(uint256 tokenAmount){
    uint256 week = getCurrentWeek();
    if(week == 0 && whitelistedPools[msg.sender]){
      return weiAmount.mul(10**18).div(specialPoolsRate);
    }
    return weiAmount.mul(10**18).div(rates[week]);
  }

   
  function calculatePriceForTokens(uint256 tokenAmount) view internal returns(uint256 weiAmount){
    uint256 week = getCurrentWeek();
    return tokenAmount.div(10**18).mul(rates[week]);
  }

   
  function getCurrentWeek() view internal returns(uint256 _week){
    uint256 week = (now.sub(startTime)).div(1 weeks);
    if(week > 3){
      week = 3;
    }
    return week;
  }

   
  function finalizeSale() internal {
    taylorToken.burn(taylorToken.balanceOf(this));
    finalized = true;
    Finalized(tokensSold, weiRaised);
  }

   

   
  function getCurrentRate() view public returns(uint256 _rate){
    return rates[getCurrentWeek()];
  }


}