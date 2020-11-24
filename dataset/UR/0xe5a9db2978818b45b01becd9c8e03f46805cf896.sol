 

 
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

 
contract ERC20Basic {
  uint256 public totalSupply;
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
    Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}


 
contract ICOToken is MintableToken, Pausable {

  string public constant name = "IPCHAIN Token";
  string public constant symbol = "IP";
  uint8 public constant decimals = 18;


   
  function ICOToken() public {
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

   
   
  function createTokenContract() internal returns (MintableToken) {
    return new MintableToken();
  }

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function getTokenAmount(uint256 weiAmount) internal view returns(uint256) {
    return weiAmount.mul(rate);
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

   
   
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

   
  function validPurchase() internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public view returns (bool) {
    return now > endTime;
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

 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

  function CappedCrowdsale(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
   
  function validPurchase() internal view returns (bool) {
    bool withinCap = weiRaised.add(msg.value) <= cap;
    return super.validPurchase() && withinCap;
  }

   
   
  function hasEnded() public view returns (bool) {
    bool capReached = weiRaised >= cap;
    return super.hasEnded() || capReached;
  }

}

contract ICOCrowdsale is Ownable, Pausable, FinalizableCrowdsale {

  uint256 constant PRESALE_CAP = 2727 ether;
  uint256 constant PRESALE_RATE = 316;
  uint256 constant PRESALE_DURATION = 23 days;

  uint256 constant MAIN_SALE_START = 1527771600;
  uint256 constant BONUS_1_CAP = PRESALE_CAP + 3636 ether;
  uint256 constant BONUS_1_RATE = 292;

  uint256 constant BONUS_2_CAP = BONUS_1_CAP + 7273 ether;
  uint256 constant BONUS_2_RATE = 269;

  uint256 constant BONUS_3_CAP = BONUS_2_CAP + 9091 ether;
  uint256 constant BONUS_3_RATE = 257;

  uint256 constant BONUS_4_CAP = BONUS_3_CAP + 10909 ether;
  uint256 constant BONUS_4_RATE = 245;

  uint256 constant NORMAL_RATE = 234;

  address tokenAddress;

  event LogBountyTokenMinted(address minter, address beneficiary, uint256 amount);

  function ICOCrowdsale(uint256 _startTime, uint256 _endTime, address _wallet, address _tokenAddress) public
    FinalizableCrowdsale()
    Crowdsale(_startTime, _endTime, NORMAL_RATE, _wallet)
  {
    require((_endTime-_startTime) > (15 * 1 days));
    require(_tokenAddress != address(0x0));
    tokenAddress = _tokenAddress;
    token = createTokenContract();
  }

   
  function createTokenContract() internal returns (MintableToken) {
    return ICOToken(tokenAddress);
  }

  function finalization() internal {
    super.finalization();

     
    ICOToken _token = ICOToken(token);
    if(_token.paused()) {
      _token.unpause();
    }
    _token.transferOwnership(owner);
  }

  function buyTokens(address beneficiary) public payable {
    uint256 minContributionAmount = 1 finney;  
    require(msg.value >= minContributionAmount);
    super.buyTokens(beneficiary);
  }

  function getRate() internal constant returns(uint256) {
     
    if (now < (startTime + PRESALE_DURATION)) {
      require(weiRaised <= PRESALE_CAP);
      return PRESALE_RATE;
    }

     
    require(now >= MAIN_SALE_START);

     
    if (weiRaised <= BONUS_1_CAP) {
        return BONUS_1_RATE;
    }

     
    if (weiRaised <= BONUS_2_CAP) {
        return BONUS_2_RATE;
    }

     
    if (weiRaised <= BONUS_3_CAP) {
        return BONUS_3_RATE;
    }

     
    if (weiRaised <= BONUS_4_CAP) {
        return BONUS_4_RATE;
    }

     
    return rate;
  }

  function getTokenAmount(uint256 weiAmount) internal constant returns(uint256) {
    uint256 _rate = getRate();
    return weiAmount.mul(_rate);
  }

  function createBountyToken(address beneficiary, uint256 amount) public onlyOwner returns(bool) {
    require(!hasEnded());
    token.mint(beneficiary, amount);
    LogBountyTokenMinted(msg.sender, beneficiary, amount);
    return true;
  }

}

contract ICOCappedRefundableCrowdsale is CappedCrowdsale, ICOCrowdsale {


  function ICOCappedRefundableCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _cap, address _wallet, address _tokenAddress) public
  	FinalizableCrowdsale()
    ICOCrowdsale(_startTime, _endTime, _wallet, _tokenAddress)
	CappedCrowdsale(_cap)
	{
	}

}