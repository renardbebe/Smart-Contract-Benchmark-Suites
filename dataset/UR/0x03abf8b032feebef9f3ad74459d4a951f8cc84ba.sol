 

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


   
  function transferOwnership(address newOwner) onlyOwner {
    require(newOwner != address(0));      
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

 
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}



 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

   
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }

}


 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
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

 

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(0x0, _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract Crowdsale {
  using SafeMath for uint256;
   
  MintableToken public token;

   
  uint256 public startBlock;
  uint256 public endBlock;

   
  address public wallet;

   
  uint256 public weiRaised;

   
  uint256 public rate;


   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startBlock, uint256 _endBlock, address _wallet) {
    require(_startBlock >= block.number);
    require(_endBlock >= _startBlock);
    require(_wallet != 0x0);

    token = createTokenContract();
    startBlock = _startBlock;
    endBlock = _endBlock;
    wallet = _wallet;
  }

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }


   
  function () payable {
    buyTokens(msg.sender);
  }


   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;

     
    uint256 tokens = weiAmount.mul(rate);

     
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    forwardFunds();
  }


   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = block.number >= startBlock && block.number <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return block.number > endBlock;
  }


}


 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal constant returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public constant returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner {
    require(!isFinalized);
    require(hasEnded());

    finalization();
    Finalized();
    
    isFinalized = true;
  }

   
  function finalization() internal {
  }
}


 
contract RefundVault is Ownable {
  using SafeMath for uint256;

  enum State { Active, Refunding, Closed }

  mapping (address => uint256) public deposited;
  address public wallet;
  State public state;

  event Closed();
  event RefundsEnabled();
  event Refunded(address indexed beneficiary, uint256 weiAmount);

  function RefundVault(address _wallet) {
    require(_wallet != 0x0);
    wallet = _wallet;
    state = State.Active;
  }

  function deposit(address investor) onlyOwner payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

  function refund(address investor) {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}


 
contract RefundableCrowdsale is FinalizableCrowdsale {
  using SafeMath for uint256;

   
  uint256 public goal;

   
  RefundVault public vault;

  function RefundableCrowdsale(uint256 _goal) {
    require(_goal > 0);
    vault = new RefundVault(wallet);
    goal = _goal;
  }

   
   
   
  function forwardFunds() internal {
    vault.deposit.value(msg.value)(msg.sender);
  }

   
  function claimRefund() {
    require(isFinalized);
    require(!goalReached());

    vault.refund(msg.sender);
  }

   
  function finalization() internal {
    if (goalReached()) {
      vault.close();
    } else {
      vault.enableRefunds();
    }

    super.finalization();
  }

  function goalReached() public constant returns (bool) {
    return weiRaised >= goal;
  }

}

contract GlobCoinToken is MintableToken {
  using SafeMath for uint256;
  string public constant name = "GlobCoin Crypto Platform";
  string public constant symbol = "GCP";
  uint8 public constant decimals = 18;

  modifier onlyMintingFinished() {
    require(mintingFinished == true);
    _;
  }
   
   
   
  function approve(address _spender, uint256 _value) public onlyMintingFinished returns (bool) {
      return super.approve(_spender, _value);
  }

   
   
   
  function transfer(address _to, uint256 _value) public onlyMintingFinished returns (bool) {
      return super.transfer(_to, _value);
  }

   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) public onlyMintingFinished returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

}

contract GlobcoinTokenSale is CappedCrowdsale, RefundableCrowdsale {

   
  uint256 public startSale;
  uint256 public endPresale;

   
  uint256 public constant PRESALERATE = 17000;

   
  uint256 public constant RATE1 = 13000;
  uint256 public constant RATE2 = 12000;
  uint256 public constant RATE3 = 11000;
  uint256 public constant RATE4 = 10000;


   
  uint256 public constant TIER1 =  3000000000000000000000;
  uint256 public constant TIER2 =  5000000000000000000000;
  uint256 public constant TIER3 =  7500000000000000000000;

   
  uint256 public weiRaisedPreSale;
  uint256 public presaleCap;

  function GlobcoinTokenSale(uint256 _startBlock, uint256 _endPresale, uint256 _startSale, uint256 _endBlock, uint256 _goal,uint256 _presaleCap, uint256 _cap, address _wallet) public
  CappedCrowdsale(_cap) FinalizableCrowdsale() RefundableCrowdsale(_goal) Crowdsale(_startBlock, _endBlock, _wallet) {
    require(_goal <= _cap);
    require(_startSale > _startBlock);
    require(_endBlock > _startSale);
    require(_presaleCap > 0);
    require(_presaleCap <= _cap);

    startSale = _startSale;
    endPresale = _endPresale;
    presaleCap = _presaleCap;
  }

  function createTokenContract() internal returns (MintableToken) {
    return new GlobCoinToken();
  }

   
  mapping (address => bool) public whiteListedAddress;
  mapping (address => bool) public whiteListedAddressPresale;

  modifier onlyPresaleWhitelisted() {
    require( isWhitelistedPresale(msg.sender) ) ;
    _;
  }

  modifier onlyWhitelisted() {
    require( isWhitelisted(msg.sender) || isWhitelistedPresale(msg.sender) ) ;
    _;
  }

   
  function whitelistAddresses( address[] _users) onlyOwner {
    for( uint i = 0 ; i < _users.length ; i++ ) {
      whiteListedAddress[_users[i]] = true;
    }
  }

  function unwhitelistAddress( address _users) onlyOwner {
    whiteListedAddress[_users] = false;
  }

   
  function whitelistAddressesPresale( address[] _users) onlyOwner {
    for( uint i = 0 ; i < _users.length ; i++ ) {
      whiteListedAddressPresale[_users[i]] = true;
    }
  }

  function unwhitelistAddressPresale( address _users) onlyOwner {
    whiteListedAddressPresale[_users] = false;
  }

  function isWhitelisted(address _user) public constant returns (bool) {
    return whiteListedAddress[_user];
  }

  function isWhitelistedPresale(address _user) public constant returns (bool) {
    return whiteListedAddressPresale[_user];
  }

  function () payable {
    if (validPurchasePresale()){
      buyTokensPresale(msg.sender);
    } else {
      buyTokens(msg.sender);
    }
  }

  function buyTokens(address beneficiary) payable onlyWhitelisted {
    require(beneficiary != 0x0);
    require(validPurchase());

    uint256 weiAmount = msg.value;
    uint256 tokens = calculateTokenAmount(weiAmount);
    weiRaised = weiRaised.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

  function buyTokensPresale(address beneficiary) payable onlyPresaleWhitelisted {
    require(beneficiary != 0x0);
    require(validPurchasePresale());

    uint256 weiAmount = msg.value;
    uint256 tokens = weiAmount.mul(PRESALERATE);
    weiRaisedPreSale = weiRaisedPreSale.add(weiAmount);

    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }

   
  function calculateTokenAmount(uint256 weiAmount) internal returns (uint256){
    uint256 amountToBuy = weiAmount;
    uint256 amountTokenBought;
    uint256 currentWeiRaised = weiRaised;
     if (currentWeiRaised < TIER1 && amountToBuy > 0) {
       var (amountBoughtInTier, amountLeftTobuy) = calculateAmountPerTier(amountToBuy,TIER1,RATE1,currentWeiRaised);
       amountTokenBought = amountTokenBought.add(amountBoughtInTier);
       currentWeiRaised = currentWeiRaised.add(amountToBuy.sub(amountLeftTobuy));
       amountToBuy = amountLeftTobuy;
     }
     if (currentWeiRaised < TIER2 && amountToBuy > 0) {
      (amountBoughtInTier, amountLeftTobuy) = calculateAmountPerTier(amountToBuy,TIER2,RATE2,currentWeiRaised);
      amountTokenBought = amountTokenBought.add(amountBoughtInTier);
      currentWeiRaised = currentWeiRaised.add(amountToBuy.sub(amountLeftTobuy));
      amountToBuy = amountLeftTobuy;
     }
     if (currentWeiRaised < TIER3 && amountToBuy > 0) {
      (amountBoughtInTier, amountLeftTobuy) = calculateAmountPerTier(amountToBuy,TIER3,RATE3,currentWeiRaised);
      amountTokenBought = amountTokenBought.add(amountBoughtInTier);
      currentWeiRaised = currentWeiRaised.add(amountToBuy.sub(amountLeftTobuy));
      amountToBuy = amountLeftTobuy;
     }
    if ( currentWeiRaised < cap && amountToBuy > 0) {
      (amountBoughtInTier, amountLeftTobuy) = calculateAmountPerTier(amountToBuy,cap,RATE4,currentWeiRaised);
      amountTokenBought = amountTokenBought.add(amountBoughtInTier);
      currentWeiRaised = currentWeiRaised.add(amountToBuy.sub(amountLeftTobuy));
      amountToBuy = amountLeftTobuy;
    }
    return amountTokenBought;
  }

   
  function calculateAmountPerTier(uint256 amountToBuy,uint256 tier,uint256 rate,uint256 currentWeiRaised) internal returns (uint256,uint256) {
    uint256 amountAvailable = tier.sub(currentWeiRaised);
    if ( amountToBuy > amountAvailable ) {
      uint256 amountBoughtInTier = amountAvailable.mul(rate);
      amountToBuy = amountToBuy.sub(amountAvailable);
      return (amountBoughtInTier,amountToBuy);
    } else {
      amountBoughtInTier = amountToBuy.mul(rate);
      return (amountBoughtInTier,0);
    }
  }

  function finalization() internal {
    if (goalReached()) {
       
      uint256 totalSupply = token.totalSupply();
       
      token.mint(wallet, totalSupply);
       
      token.mint(wallet, totalSupply.div(2));
      token.finishMinting();
    }
    super.finalization();
  }

   
  function validPurchase() internal constant returns (bool) {
    bool withinPeriod = block.number >= startSale && block.number <= endBlock;
    bool nonZeroPurchase = msg.value != 0;
    uint256 totalWeiRaised = weiRaisedPreSale.add(weiRaised);
    bool withinCap = totalWeiRaised.add(msg.value) <= cap;
    return withinCap && withinPeriod && nonZeroPurchase;
  }

   
  function validPurchasePresale() internal constant returns (bool) {
    bool withinPeriod = (block.number >= startBlock) && (block.number <= endPresale);
    bool nonZeroPurchase = msg.value != 0;
    bool withinCap = weiRaisedPreSale.add(msg.value) <= presaleCap;
    return withinPeriod && nonZeroPurchase && withinCap;
  }

   
  function goalReached() public constant returns (bool) {
    uint256 totalWeiRaised = weiRaisedPreSale.add(weiRaised);
    return totalWeiRaised >= goal || super.goalReached();
  }

}