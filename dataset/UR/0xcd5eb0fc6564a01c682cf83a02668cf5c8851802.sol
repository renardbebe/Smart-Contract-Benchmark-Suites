 

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

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public constant returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);

  function allowance(address owner, address spender) public constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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

 
contract StandardToken is ERC20Basic {

  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
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

}

 
contract BurnableToken is StandardToken {

    event Burn(address indexed burner, uint256 value);

     
    function burn(uint256 _value) public {
        require(_value > 0);
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(burner, _value);
    }
}


 

contract MintableToken is BurnableToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
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

contract PausableToken is StandardToken, Pausable {

  function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
    return super.approve(_spender, _value);
  }

}

 
contract GESToken is MintableToken, PausableToken {
  string public constant name = "Galaxy eSolutions";
  string public constant symbol = "GES";
  uint8 public constant decimals = 18;
}

 

contract GESTokenCrowdSale is Ownable {
  using SafeMath for uint256;

  struct TimeBonus {
    uint256 bonusPeriodEndTime;
    uint percent;
    uint256 weiCap;
  }

   
  bool public isFinalised;

   
  MintableToken public token;

   
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

   
  address public wallet;

   
  address public tokenWallet;

   
  uint256 public rate = 100;

   
  uint256 public weiRaised;

   
  uint256 public saleMinimumWei = 100000000000000000; 

  TimeBonus[] public timeBonuses;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FinalisedCrowdsale(uint256 totalSupply, uint256 minterBenefit);

  function GESTokenCrowdSale(uint256 _mainSaleStartTime, address _wallet, address _tokenWallet) public {

     
    require(_mainSaleStartTime >= now);

     
    require(_wallet != 0x0);
    require(_tokenWallet != 0x0);

     
    timeBonuses.push(TimeBonus(86400 *  7,  30,    2000000000000000000000));  
    timeBonuses.push(TimeBonus(86400 *  14, 20,    5000000000000000000000));  
    timeBonuses.push(TimeBonus(86400 *  21, 10,   10000000000000000000000));  
    timeBonuses.push(TimeBonus(86400 *  60,  0,   25000000000000000000000));  

    token = createTokenContract();
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = mainSaleStartTime + 60 days;
    wallet = _wallet;
    tokenWallet = _tokenWallet;
    isFinalised = false;
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return new GESToken();
  }

   
  function () payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(!isFinalised);
    require(beneficiary != 0x0);
    require(msg.value != 0);
    require(now <= mainSaleEndTime && now >= mainSaleStartTime);
    require(msg.value >= saleMinimumWei);

     
    uint256 bonusedTokens = applyBonus(msg.value);

     
    weiRaised = weiRaised.add(msg.value);
    token.mint(beneficiary, bonusedTokens);
    TokenPurchase(msg.sender, beneficiary, msg.value, bonusedTokens);

  }

   

  function finaliseCrowdsale() external onlyOwner returns (bool) {
    require(!isFinalised);
    uint256 totalSupply = token.totalSupply();
    uint256 minterBenefit = totalSupply.mul(10).div(89);
    token.mint(tokenWallet, minterBenefit);
    token.finishMinting();
    forwardFunds();
    FinalisedCrowdsale(totalSupply, minterBenefit);
    isFinalised = true;
    return true;
  }

   
  function setMainSaleDates(uint256 _mainSaleStartTime) public onlyOwner returns (bool) {
    require(!isFinalised);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = mainSaleStartTime + 60 days;
    return true;
  }

   
  function pauseToken() external onlyOwner {
    require(!isFinalised);
    GESToken(token).pause();
  }

   
  function unpauseToken() external onlyOwner {
    GESToken(token).unpause();
  }

   
  function transferTokenOwnership(address newOwner) external onlyOwner {
    GESToken(token).transferOwnership(newOwner);
  }

   
  function mainSaleHasEnded() external constant returns (bool) {
    return now > mainSaleEndTime;
  }

   
  function forwardFunds() internal {
    wallet.transfer(this.balance);
  }

   
  function applyBonus(uint256 weiAmount) internal constant returns (uint256 bonusedTokens) {
     
    uint256 tokensToAdd = 0;

     
    uint256 tokens = weiAmount.mul(rate);
    uint256 diffInSeconds = now.sub(mainSaleStartTime);

    for (uint i = 0; i < timeBonuses.length; i++) {
       
      if(weiRaised.add(weiAmount) <= timeBonuses[i].weiCap){
        for(uint j = i; j < timeBonuses.length; j++){
           
          if (diffInSeconds <= timeBonuses[j].bonusPeriodEndTime) {
            tokensToAdd = tokens.mul(timeBonuses[j].percent).div(100);
            return tokens.add(tokensToAdd);
          }
        }
      }
    }
    
  }

   
  function fetchFunds() onlyOwner public {
    wallet.transfer(this.balance);
  }

}