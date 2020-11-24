 

pragma solidity 0.4.19;

 
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

 

contract Crowdsale {
  using SafeMath for uint256;

   
  ERC20 public token;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

   
  function Crowdsale(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 
contract AllowanceCrowdsale is Crowdsale {
  using SafeMath for uint256;

  address public tokenWallet;

   
  function AllowanceCrowdsale(address _tokenWallet) public {
    require(_tokenWallet != address(0));
    tokenWallet = _tokenWallet;
  }

   
  function remainingTokens() public view returns (uint256) {
    return token.allowance(tokenWallet, this);
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transferFrom(tokenWallet, _beneficiary, _tokenAmount);
  }
}

 
contract WhitelistedCrowdsale is Crowdsale, Ownable {

  mapping(address => bool) public whitelist;

   
  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

   
  function addToWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = true;
  }
  
   
  function addManyToWhitelist(address[] _beneficiaries) external onlyOwner {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _beneficiary) external onlyOwner {
    whitelist[_beneficiary] = false;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
    require(now >= openingTime && now <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
    require(_openingTime >= now);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
    return now > closingTime;
  }
  
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhileOpen {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 
contract FinalizableCrowdsale is TimedCrowdsale, Ownable {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }
}


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
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

 
contract RTEBonusTokenVault is Ownable {
  using SafeERC20 for ERC20Basic;
  using SafeMath for uint256;

   
  ERC20Basic public token;

  bool public vaultUnlocked;

  bool public vaultSecondaryUnlocked;

   
  mapping(address => uint256) public balances;

  mapping(address => uint256) public lockedBalances;

   
  event Allocated(address _investor, uint256 _value);

   
  event Distributed(address _investor, uint256 _value);

  function RTEBonusTokenVault(
    ERC20Basic _token
  )
    public
  {
    token = _token;
    vaultUnlocked = false;
    vaultSecondaryUnlocked = false;
  }

   
  function unlock() public onlyOwner {
    require(!vaultUnlocked);
    vaultUnlocked = true;
  }

   
  function unlockSecondary() public onlyOwner {
    require(vaultUnlocked);
    require(!vaultSecondaryUnlocked);
    vaultSecondaryUnlocked = true;
  }

   
  function allocateInvestorBonusToken(address _investor, uint256 _amount) public onlyOwner {
    require(!vaultUnlocked);
    require(!vaultSecondaryUnlocked);

    uint256 bonusTokenAmount = _amount.div(2);
    uint256 bonusLockedTokenAmount = _amount.sub(bonusTokenAmount);

    balances[_investor] = balances[_investor].add(bonusTokenAmount);
    lockedBalances[_investor] = lockedBalances[_investor].add(bonusLockedTokenAmount);

    Allocated(_investor, _amount);
  }

   
  function claim(address _investor) public onlyOwner {
     
     
    require(vaultUnlocked);

    uint256 claimAmount = balances[_investor];
    require(claimAmount > 0);

    uint256 tokenAmount = token.balanceOf(this);
    require(tokenAmount > 0);

     
    balances[_investor] = 0;

    token.safeTransfer(_investor, claimAmount);

    Distributed(_investor, claimAmount);
  }

   
  function claimLocked(address _investor) public onlyOwner {
     
     
    require(vaultUnlocked);
    require(vaultSecondaryUnlocked);

    uint256 claimAmount = lockedBalances[_investor];
    require(claimAmount > 0);

    uint256 tokenAmount = token.balanceOf(this);
    require(tokenAmount > 0);

     
    lockedBalances[_investor] = 0;

    token.safeTransfer(_investor, claimAmount);

    Distributed(_investor, claimAmount);
  }
}

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  uint256 totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
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

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
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

 
contract WhitelistedPausableToken is StandardToken, Pausable {

  mapping(address => bool) public whitelist;

   
  modifier whenNotPausedOrWhitelisted(address _sender) {
    require(whitelist[_sender] || !paused);
    _;
  }

   
  function addToWhitelist(address _whitelistAddress) external onlyOwner {
    whitelist[_whitelistAddress] = true;
  }

   
  function addManyToWhitelist(address[] _whitelistAddresses) external onlyOwner {
    for (uint256 i = 0; i < _whitelistAddresses.length; i++) {
      whitelist[_whitelistAddresses[i]] = true;
    }
  }

   
  function removeFromWhitelist(address _whitelistAddress) external onlyOwner {
    whitelist[_whitelistAddress] = false;
  }

   
  function transfer(address _to, uint256 _value) public whenNotPausedOrWhitelisted(msg.sender) returns (bool) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) public whenNotPausedOrWhitelisted(msg.sender) returns (bool) {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) public whenNotPausedOrWhitelisted(msg.sender) returns (bool) {
    return super.approve(_spender, _value);
  }

  function increaseApproval(address _spender, uint _addedValue) public whenNotPausedOrWhitelisted(msg.sender) returns (bool success) {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPausedOrWhitelisted(msg.sender) returns (bool success) {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 
contract RTEToken is WhitelistedPausableToken {
  string public constant name = "Rate3";
  string public constant symbol = "RTE";
  uint8 public constant decimals = 18;

   
   
  uint256 public constant INITIAL_SUPPLY = (10 ** 9) * (10 ** 18);

   
  function RTEToken() public {
     
    totalSupply_ = INITIAL_SUPPLY;

     
    balances[msg.sender] = INITIAL_SUPPLY;
    Transfer(0x0, msg.sender, INITIAL_SUPPLY);
  }
}

 
contract RTECrowdsale is AllowanceCrowdsale, WhitelistedCrowdsale, FinalizableCrowdsale {
  using SafeERC20 for ERC20;

  uint256 public constant minimumInvestmentInWei = 0.5 ether;

  uint256 public allTokensSold;

  uint256 public bonusTokensSold;

  uint256 public cap;

  mapping (address => uint256) public tokenInvestments;

  mapping (address => uint256) public bonusTokenInvestments;

  RTEBonusTokenVault public bonusTokenVault;

   
  function RTECrowdsale(
    uint256 _openingTime,
    uint256 _closingTime,
    uint256 _rate,
    uint256 _cap,
    address _wallet,
    address _issueWallet,
    RTEToken _token
  )
    AllowanceCrowdsale(_issueWallet)
    TimedCrowdsale(_openingTime, _closingTime)
    Crowdsale(_rate, _wallet, _token)
    public
  {
    require(_cap > 0);

    cap = _cap;
    bonusTokenVault = new RTEBonusTokenVault(_token);
  }

   
  function capReached() public view returns (bool) {
    return allTokensSold >= cap;
  }

   
  function _calculateBonusPercentage() internal view returns (uint256) {
    return 20;
  }

   
  function getRTEBonusTokenVaultBalance() public view returns (uint256) {
    return token.balanceOf(address(bonusTokenVault));
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(msg.value >= minimumInvestmentInWei);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    uint256 bonusPercentage = _calculateBonusPercentage();
    uint256 additionalBonusTokens = _tokenAmount.mul(bonusPercentage).div(100);
    uint256 tokensSold = _tokenAmount;

     
    uint256 newAllTokensSold = allTokensSold.add(tokensSold).add(additionalBonusTokens);
    require(newAllTokensSold <= cap);

     
    super._processPurchase(_beneficiary, tokensSold);
    allTokensSold = allTokensSold.add(tokensSold);
    tokenInvestments[_beneficiary] = tokenInvestments[_beneficiary].add(tokensSold);

    if (additionalBonusTokens > 0) {
       
      allTokensSold = allTokensSold.add(additionalBonusTokens);
      bonusTokensSold = bonusTokensSold.add(additionalBonusTokens);
      bonusTokenVault.allocateInvestorBonusToken(_beneficiary, additionalBonusTokens);
      bonusTokenInvestments[_beneficiary] = bonusTokenInvestments[_beneficiary].add(additionalBonusTokens);
    }
  }

   
  function unlockSecondaryTokens() public onlyOwner {
    require(isFinalized);
    bonusTokenVault.unlockSecondary();
  }

   
  function claimBonusTokens(address _beneficiary) public {
    require(isFinalized);
    bonusTokenVault.claim(_beneficiary);
  }

   
  function claimLockedBonusTokens(address _beneficiary) public {
    require(isFinalized);
    bonusTokenVault.claimLocked(_beneficiary);
  }

   
  function finalization() internal {
     
    token.transferFrom(tokenWallet, bonusTokenVault, bonusTokensSold);

     
    bonusTokenVault.unlock();

    super.finalization();
  }
}