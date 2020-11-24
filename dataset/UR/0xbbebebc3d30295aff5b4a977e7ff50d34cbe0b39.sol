 

pragma solidity ^0.4.18;
 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
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
 
contract Crowdsale {
  using SafeMath for uint256;
   
  MintableToken public token;
   
  uint256 public startTime;
  uint256 public endTime;
   
  address public wallet;
   
  uint256 public rate;
   
  uint256 public weiRaised;
   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));
    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
  }
   
  function () external payable {
    buyTokens(msg.sender);
  }
   
  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    uint256 tokens = getTokenAmount(weiAmount);
     
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
   
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }
   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
  }
   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }
   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }
}
 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;
  uint256 public cap;
  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }
   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return capReached || super.hasEnded();
  }
   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return withinCap && super.validPurchase();
  }
}
 
contract FinalizableCrowdsale is Crowdsale, Ownable {
  using SafeMath for uint256;
  bool public isFinalized = false;
  event Finalized();
   
  function finalize() onlyOwner public {
    require(!isFinalized);
    require(hasEnded());
    finalization();
    Finalized();
    isFinalized = true;
  }
   
  function finalization() internal {
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
 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
 
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();
  bool public mintingFinished = false;
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }
   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}
 
contract BurnableToken is BasicToken {
  event Burn(address indexed burner, uint256 value);
   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     
    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
  }
}
contract MIKETANGOBRAVO18 is MintableToken, BurnableToken {
	string public constant name = "MIKETANGOBRAVO18";
	string public constant symbol = "MTB18";
	uint public constant decimals = 18;
    function() public {}
}
contract MIKETANGOBRAVO18Crowdsale is CappedCrowdsale, FinalizableCrowdsale, Pausable {
  uint256 public rate;
  uint256 public totalTokenCapToCreate;
  address public fundWallet;
  function MIKETANGOBRAVO18Crowdsale (
  	uint256 _startTime,
  	uint256 _endTime,
  	uint256 _rate,
    address _fundWallet,
    uint256 _totalCapInEthToRaise,
    uint256 _totalTokenCapToCreate,
    uint256 _initialTokenFundBalance
  	) public
    Crowdsale(_startTime, _endTime, _rate, _fundWallet)
    CappedCrowdsale(_totalCapInEthToRaise)
    FinalizableCrowdsale() {
      rate = _rate;
      fundWallet = _fundWallet;
      totalTokenCapToCreate = _totalTokenCapToCreate;
      token.mint(fundWallet, _initialTokenFundBalance);
    }
  function createTokenContract() internal returns (MintableToken) {
    return new MIKETANGOBRAVO18();
  }
   
   
  function validPurchase() internal view returns (bool) {
    bool withinTokenCap = token.totalSupply().add(msg.value.mul(rate)) <= totalTokenCapToCreate;
    bool nonZeroPurchase = msg.value != 0;
    return super.validPurchase() && withinTokenCap && nonZeroPurchase;
  }
   
   
  function hasEnded() public view returns (bool) {
    uint256 threshold = totalTokenCapToCreate.div(100).mul(99);
    bool thresholdReached = token.totalSupply() >= threshold;
    return super.hasEnded() || thresholdReached;
  }
   
   
  function finalization() internal {
    uint256 remaining = totalTokenCapToCreate.sub(token.totalSupply());
    if (remaining > 0) {
      token.mint(fundWallet, remaining);
    }
     
    token.transferOwnership(fundWallet);
    super.finalization();
  }
  function remaining() public returns (uint256) {
    return totalTokenCapToCreate.sub(token.totalSupply());
  }
   
  function buyTokens(address beneficiary) public payable {
    require(!paused);
    require(beneficiary != address(0));
    require(validPurchase());
    uint256 weiAmount = msg.value;
     
    uint256 tokens = weiAmount.mul(rate);
     
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);
    forwardFunds();
  }
}