 

pragma solidity ^0.4.15;

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

contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
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

contract GJCICO is Pausable{
  using SafeMath for uint256;

   
  uint constant public minContribAmount = 0.01 ether;

   
  GJCToken public token;
  uint256 constant public tokenDecimals = 18;

   
  TokenVesting public vesting;
  uint256 constant public VESTING_TIMES = 4;
  uint256 constant public DURATION_PER_VESTING = 52 weeks;

   
  uint256 public startTime;
  uint256 public endTime;

   
  bool public icoEnabled;

   
  address public multisignWallet;

   
  uint256 public weiRaised;

   
  uint256 constant public totalSupply = 100000000 * (10 ** tokenDecimals);
   
  uint256 constant public preSaleCap = 10000000 * (10 ** tokenDecimals);
   
  uint256 constant public initialICOCap = 60000000 * (10 ** tokenDecimals);
   
  uint256 constant public tokensForFounder = 10000000 * (10 ** tokenDecimals);
   
  uint256 constant public tokensForDevteam = 10000000 * (10 ** tokenDecimals);
   
  uint256 constant public tokensForPartners = 5000000 * (10 ** tokenDecimals);
   
  uint256 constant public tokensForCharity = 3000000 * (10 ** tokenDecimals);
   
  uint256 constant public tokensForBounty = 2000000 * (10 ** tokenDecimals);
    
   
  uint256 public soldPreSaleTokens; 
  uint256 public sentPreSaleTokens;

   
   
  uint256 public icoCap; 
  uint256 public icoSoldTokens; 
  bool public icoEnded = false;

   
  uint256 constant public RATE_FOR_WEEK1 = 525;
  uint256 constant public RATE_FOR_WEEK2 = 455;
  uint256 constant public RATE_FOR_WEEK3 = 420;
  uint256 constant public RATE_NO_DISCOUNT = 350;


    
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function GJCICO(address _multisignWallet) {
    require(_multisignWallet != address(0));
    token = createTokenContract();
     
    uint256 tokensToDao = tokensForDevteam.add(tokensForPartners).add(tokensForBounty).add(tokensForCharity);
    multisignWallet = _multisignWallet;
    token.transfer(multisignWallet, tokensToDao);
  }

  function createVestingForFounder(address founderAddress) external onlyOwner(){
    require(founderAddress != address(0));
     
    require(address(vesting) == address(0));
    vesting = createTokenVestingContract(address(token));
     
    vesting.createVestingByDurationAndSplits(founderAddress, tokensForFounder, now, DURATION_PER_VESTING, VESTING_TIMES);
     
    token.transfer(address(vesting), tokensForFounder);
  }

   
   
   

   
  
  function createTokenContract() internal returns (GJCToken) {
    return new GJCToken();
  }

   
   
  function createTokenVestingContract(address tokenAddress) internal returns (TokenVesting) {
    require(address(token) != address(0));
    return new TokenVesting(tokenAddress);
  }


   
  function enableTokenTransferability() external onlyOwner {
    require(token != address(0));
    token.unpause(); 
  }

   
  function disableTokenTransferability() external onlyOwner {
    require(token != address(0));
    token.pause(); 
  }


   
   
   

   
   
   
  function setSoldPreSaleTokens(uint256 _soldPreSaleTokens) external onlyOwner{
    require(!icoEnabled);
    require(_soldPreSaleTokens <= preSaleCap);
    soldPreSaleTokens = _soldPreSaleTokens;
  }

   
   
   
  function transferPreSaleTokens(uint256 tokens, address beneficiary) external onlyOwner {
    require(beneficiary != address(0));
    require(soldPreSaleTokens > 0);
    uint256 newSentPreSaleTokens = sentPreSaleTokens.add(tokens);
    require(newSentPreSaleTokens <= soldPreSaleTokens);
    sentPreSaleTokens = newSentPreSaleTokens;
    token.transfer(beneficiary, tokens);
  }


   
   
   

   
  function setMultisignWallet(address _multisignWallet) external onlyOwner{
     
    require(!icoEnabled || now < startTime);
    require(_multisignWallet != address(0));
    multisignWallet = _multisignWallet;
  }

   
  function delegateVestingContractOwner(address newOwner) external onlyOwner{
    vesting.transferOwnership(newOwner);
  }

   
  function setContributionDates(uint256 _startTime, uint256 _endTime) external onlyOwner{
    require(!icoEnabled);
    require(_startTime >= now);
    require(_endTime >= _startTime);
    startTime = _startTime;
    endTime = _endTime;
  }

   
   
   
   
  function enableICO() external onlyOwner{
    require(startTime >= now);

    require(multisignWallet != address(0));
    icoEnabled = true;
    icoCap = initialICOCap.add(preSaleCap).sub(soldPreSaleTokens);
  }


   
  function () payable whenNotPaused {
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

    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }

   
  
  function forwardFunds() internal {
    multisignWallet.transfer(this.balance);
  }

   
   
   
   
   
   
   

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonMinimumPurchase = msg.value >= minContribAmount;
    bool icoTokensAvailable = icoSoldTokens < icoCap;
    return !icoEnded && icoEnabled && withinPeriod && nonMinimumPurchase && icoTokensAvailable;
  }

   
  function endIco() external onlyOwner {
    require(!icoEnded);
    icoEnded = true;
     
    uint256 unsoldTokens = icoCap.sub(icoSoldTokens);
    token.transfer(multisignWallet, unsoldTokens);
  }

   
  function hasEnded() public constant returns (bool) {
    return (icoEnded || icoSoldTokens >= icoCap || now > endTime);
  }


  function getRate() public constant returns(uint){
    require(now >= startTime);
    if (now < startTime.add(1 weeks)){
       
      return RATE_FOR_WEEK1;
    }else if (now < startTime.add(2 weeks)){
       
      return RATE_FOR_WEEK2;
    }else if (now < startTime.add(3 weeks)){
       
      return RATE_FOR_WEEK3;
    }else if (now < endTime){
       
      return RATE_NO_DISCOUNT;
    }
    return 0;
  }

   
  function drain() external onlyOwner {
    owner.transfer(this.balance);
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
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

library SafeERC20 {
  function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
    assert(token.transfer(to, value));
  }

  function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
    assert(token.transferFrom(from, to, value));
  }

  function safeApprove(ERC20 token, address spender, uint256 value) internal {
    assert(token.approve(spender, value));
  }
}

contract TokenVesting is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ERC20Basic;

    ERC20Basic token;
     
    mapping (address => uint256) totalVestedAmount;

    struct Vesting {
        uint256 amount;
        uint256 vestingDate;
    }

    address[] accountKeys;
    mapping (address => Vesting[]) public vestingAccounts;

     
    event Vest(address indexed beneficiary, uint256 amount);
    event VestingCreated(address indexed beneficiary, uint256 amount, uint256 vestingDate);

     
    modifier tokenSet() {
        require(address(token) != address(0));
        _;
    }

     
    function TokenVesting(address token_address){
       require(token_address != address(0));
       token = ERC20Basic(token_address);
    }

     
    function setVestingToken(address token_address) external onlyOwner {
        require(token_address != address(0));
        token = ERC20Basic(token_address);
    }

     
    function createVestingByDurationAndSplits(address user, uint256 total_amount, uint256 startDate, uint256 durationPerVesting, uint256 times) public onlyOwner tokenSet {
        require(user != address(0));
        require(startDate >= now);
        require(times > 0);
        require(durationPerVesting > 0);
        uint256 vestingDate = startDate;
        uint256 i;
        uint256 amount = total_amount.div(times);
        for (i = 0; i < times; i++) {
            vestingDate = vestingDate.add(durationPerVesting);
            if (vestingAccounts[user].length == 0){
                accountKeys.push(user);
            }
            vestingAccounts[user].push(Vesting(amount, vestingDate));
            VestingCreated(user, amount, vestingDate);
        }
    }

     
    function getVestingAmountByNow(address user) constant returns (uint256){
        uint256 amount;
        uint256 i;
        for (i = 0; i < vestingAccounts[user].length; i++) {
            if (vestingAccounts[user][i].vestingDate < now) {
                amount = amount.add(vestingAccounts[user][i].amount);
            }
        }

    }

     
    function getAvailableVestingAmount(address user) constant returns (uint256){
        uint256 amount;
        amount = getVestingAmountByNow(user);
        amount = amount.sub(totalVestedAmount[user]);
        return amount;
    }

     
    function getAccountKeys(uint256 page) external constant returns (address[10]){
        address[10] memory accountList;
        uint256 i;
        for (i=0 + page * 10; i<10; i++){
            if (i < accountKeys.length){
                accountList[i - page * 10] = accountKeys[i];
            }
        }
        return accountList;
    }

     
    function vest() external tokenSet {
        uint256 availableAmount = getAvailableVestingAmount(msg.sender);
        require(availableAmount > 0);
        totalVestedAmount[msg.sender] = totalVestedAmount[msg.sender].add(availableAmount);
        token.transfer(msg.sender, availableAmount);
        Vest(msg.sender, availableAmount);
    }

     
    function drain() external onlyOwner {
        owner.transfer(this.balance);
        token.transfer(owner, this.balance);
    }
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
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

   
  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
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

contract GJCToken is PausableToken {
  string constant public name = "GJC";
  string constant public symbol = "GJC";
  uint256 constant public decimals = 18;
  uint256 constant TOKEN_UNIT = 10 ** uint256(decimals);
  uint256 constant INITIAL_SUPPLY = 100000000 * TOKEN_UNIT;

  function GJCToken() {
     
    paused = true;
     
    totalSupply = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
    balances[msg.sender] = INITIAL_SUPPLY;
  }
}