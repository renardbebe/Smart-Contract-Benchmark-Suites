 

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

  function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}


contract UAPToken is MintableToken, PausableToken {
  string public constant name = "Auction Universal Program";
  string public constant symbol = "UAP";
  uint8 public constant decimals = 18;
  
  uint256 public initialSuppy = 8680500000 * 10 ** uint256(18);
  
  function UAPToken(address _tokenWallet)  public {
    totalSupply = initialSuppy;
    balances[_tokenWallet] = initialSuppy ;
  }
}

 

contract UAPCrowdsale is Ownable {
  using SafeMath for uint256;

   
  bool public isFinalised;

   
  MintableToken public token;

   
  uint256 public mainSaleStartTime;
  uint256 public mainSaleEndTime;

   
  address public wallet;

   
  address public tokenWallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;
  
   
  uint256 public tokensToSell= 319500000 * 10 ** uint256(18);

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event FinalisedCrowdsale();

  function UAPCrowdsale(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime, uint256 _rate, address _wallet, address _tokenWallet) public {

     
    require(_mainSaleStartTime >= now);

     
    require(_mainSaleStartTime < _mainSaleEndTime);

    require(_rate > 0);
    require(_wallet != 0x0);
    require(_tokenWallet != 0x0);

    token = createTokenContract(_tokenWallet);

    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    
    rate = _rate;
    wallet = _wallet;
    tokenWallet = _tokenWallet;
    
    isFinalised = false;
  }

   
   
  function createTokenContract(address _tokenWallet) internal returns (MintableToken) {
    return new UAPToken(_tokenWallet);
  }

   
  function () public payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address beneficiary) public payable {
    require(!isFinalised);
    require(beneficiary != 0x0);
    require(msg.value != 0);

    require(now >= mainSaleStartTime && now <= mainSaleEndTime);

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);
    
    require(tokens <= tokensToSell);

     
    weiRaised = weiRaised.add(weiAmount);
    tokensToSell = tokensToSell.sub(tokens);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

  }

   
   

  function finaliseCrowdsale() external onlyOwner returns (bool) {
    require(!isFinalised);
     
    token.mint(tokenWallet, tokensToSell);
    token.finishMinting();
    forwardFunds();
    FinalisedCrowdsale();
    isFinalised = true;
    return true;
  }

   
  function setMainSaleDates(uint256 _mainSaleStartTime, uint256 _mainSaleEndTime) public onlyOwner returns (bool) {
    require(!isFinalised);
    require(_mainSaleStartTime < _mainSaleEndTime);
    mainSaleStartTime = _mainSaleStartTime;
    mainSaleEndTime = _mainSaleEndTime;
    return true;
  }
  
   
  function setRate(uint256 _rate) public onlyOwner returns(bool){
      require(_rate > 0);
      rate = _rate;
      return true;
  }

  function pauseToken() external onlyOwner {
    require(!isFinalised);
    UAPToken(token).pause();
  }

  function unpauseToken() external onlyOwner {
    UAPToken(token).unpause();
  }
  
   
  function transferTokenOwnership(address newOwner) external onlyOwner {
    require(newOwner != 0x0);
    UAPToken(token).transferOwnership(newOwner);
  }

   
  function mainSaleHasEnded() external constant returns (bool) {
    return now > mainSaleEndTime;
  }

   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
  
   
  function fetchFunds() onlyOwner public {
    wallet.transfer(this.balance);
  }

}