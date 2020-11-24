 

pragma solidity ^0.4.16;


 
contract Ownable {
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   

  modifier onlyOwner(){
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) onlyOwner public {
    if (newOwner != address(0)) {
      owner = newOwner;
    }
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

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) public returns (bool){
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
  mapping (address => mapping (address => uint256)) internal allowed;

   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

   

  function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract MintableToken is StandardToken, Ownable {

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
    Transfer(0X0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

contract FidentiaXToken is MintableToken {
   
  string public name = "fidentiaX";
  string public symbol = "fdX";
  uint256 public decimals = 18;

   
  bool public tradingStarted = false;

   
  modifier hasStartedTrading() {
    require(tradingStarted);
    _;
  }

   
  function startTrading() public onlyOwner {
    tradingStarted = true;
  }

   
  function transfer(address _to, uint _value) hasStartedTrading public returns (bool) {
    return super.transfer(_to, _value);
  }

   
  function transferFrom(address _from, address _to, uint _value) hasStartedTrading public returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function emergencyERC20Drain( ERC20 oddToken, uint amount ) public {
    oddToken.transfer(owner, amount);
  }
}



contract FidentiaXTokenSale is Ownable {

  using SafeMath for uint256;

   
  FidentiaXToken public token;

  uint256 public decimals;  

  uint256 public oneCoin;

   
  uint256 public startTimestamp;
  uint256 public endTimestamp;

   
  uint256 public tier1Timestamp;
  uint256 public tier2Timestamp;

   

  address public multiSig;

  function setWallet(address _newWallet) public onlyOwner {
    multiSig = _newWallet;
  }

   

  uint256 public rate;  

  uint256 public minContribution = 0.0001 ether;   

  uint256 public maxContribution = 200000 ether;   

   
   

  uint256 public weiRaised;

   

  uint256 public tokenRaised;

   

  uint256 public maxTokens;

   

  uint256 public tokensForSale;   

   

  uint256 public numberOfPurchasers = 0;

   
  address public cs;
   
  address public fx;

   

  bool    public freeForAll = false;

  mapping (address => bool) public authorised;  

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  event SaleClosed();

  function FidentiaXTokenSale() public {
    startTimestamp = 1509930000;  
     
    endTimestamp = 1512489599;    
    tier1Timestamp = 1510102799;  
    tier2Timestamp = 1510361999;  
    token = new FidentiaXToken();
    decimals = token.decimals();
    oneCoin = 10 ** decimals;
    maxTokens = 130 * (10**6) * oneCoin;
    tokensForSale = 130 * (10**6) * oneCoin;
  }

   
  function getRateAt(uint256 at) internal constant returns (uint256) {
    if (at < (tier1Timestamp))
      return 575;
    if (at < (tier2Timestamp))
      return 550;
    return 500;
  }

   
  function hasEnded() public constant returns (bool) {
    if (now > endTimestamp)
      return true;
    if (tokenRaised >= tokensForSale)
      return true;  
    return false;
  }

   
  modifier onlyCSorFx() {
    require((msg.sender == fx) || (msg.sender==cs));
    _;
  }

  modifier onlyFx() {
    require(msg.sender == fx);
    _;
  }

   
  modifier onlyAuthorised() {
    require (authorised[msg.sender] || freeForAll);
    require (now >= startTimestamp);
    require (!(hasEnded()));
    require (multiSig != 0x0);
    require (msg.value > 1 finney);
    require(tokensForSale > tokenRaised);  
    _;
  }

   
  function authoriseAccount(address whom) onlyCSorFx public {
    authorised[whom] = true;
  }

   
  function authoriseManyAccounts(address[] many) onlyCSorFx public {
    for (uint256 i = 0; i < many.length; i++) {
      authorised[many[i]] = true;
    }
  }

   
  function blockAccount(address whom) onlyCSorFx public {
    authorised[whom] = false;
  }

   
  function setCS(address newCS) onlyOwner public {
    cs = newCS;
  }

   
  function setFx(address newFx) onlyOwner public {
    fx = newFx;
  }

  function placeTokens(address beneficiary, uint256 _tokens) onlyFx public {
     
    require(_tokens != 0);
    require(!hasEnded());
    uint256 amount = 0;
    if (token.balanceOf(beneficiary) == 0) {
      numberOfPurchasers++;
    }
    tokenRaised = tokenRaised.add(_tokens);  
    token.mint(beneficiary, _tokens);
    TokenPurchase(beneficiary, beneficiary, amount, _tokens);
  }

   
  function buyTokens(address beneficiary, uint256 amount) onlyAuthorised internal {
     
    require(amount >= minContribution);
    require(amount <= maxContribution);

     
    uint256 actualRate = getRateAt(now);
    uint256 tokens = amount.mul(actualRate);

     
    weiRaised = weiRaised.add(amount);
    if (token.balanceOf(beneficiary) == 0) {
      numberOfPurchasers++;
    }
    tokenRaised = tokenRaised.add(tokens);  
    token.mint(beneficiary, tokens);
    TokenPurchase(beneficiary, beneficiary, amount, tokens);
    multiSig.transfer(this.balance);  
  }

   
  function finishSale() public onlyOwner {
    require(hasEnded());
     
    uint unassigned;
    if(maxTokens > tokenRaised) {
      unassigned  = maxTokens.sub(tokenRaised);
      token.mint(multiSig,unassigned);
    }
    token.finishMinting();
    token.transferOwnership(owner);
    SaleClosed();
  }

   
  function () public payable {
    buyTokens(msg.sender, msg.value);
  }

  function emergencyERC20Drain( ERC20 oddToken, uint amount ) public {
    oddToken.transfer(owner, amount);
  }
}