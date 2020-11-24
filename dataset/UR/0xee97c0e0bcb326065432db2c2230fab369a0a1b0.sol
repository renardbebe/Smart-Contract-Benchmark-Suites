 

pragma solidity ^0.4.13;

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

contract Crowdsale {
  using SafeMath for uint256;

   
  MintableToken public token;

   
  uint256 public startTime;
  uint256 public endTime;

   
  address public wallet;

   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet) {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != 0x0);

    token = createTokenContract();
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
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
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

   
  function hasEnded() public constant returns (bool) {
    return now > endTime;
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

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


   
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));

    uint256 _allowance = allowed[_from][msg.sender];

     
     

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
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

contract QiibeeTokenInterface {
  function mintVestedTokens(address _to,
    uint256 _value,
    uint64 _start,
    uint64 _cliff,
    uint64 _vesting,
    bool _revokable,
    bool _burnsOnRevoke,
    address _wallet
  ) returns (bool);
  function mint(address _to, uint256 _amount) returns (bool);
  function transferOwnership(address _wallet);
  function pause();
  function unpause();
  function finishMinting() returns (bool);
}

contract QiibeePresale is CappedCrowdsale, FinalizableCrowdsale, Pausable {

    using SafeMath for uint256;

    struct AccreditedInvestor {
      uint64 cliff;
      uint64 vesting;
      bool revokable;
      bool burnsOnRevoke;
      uint256 minInvest;  
      uint256 maxCumulativeInvest;  
    }

    QiibeeTokenInterface public token;  

    uint256 public distributionCap;  
    uint256 public tokensDistributed;  
    uint256 public tokensSold;  

    uint64 public vestFromTime = 1530316800;  

    mapping (address => uint256) public balances;  
    mapping (address => AccreditedInvestor) public accredited;  

     
    mapping (address => uint256) public lastCallTime;  
    uint256 public maxGasPrice;  
    uint256 public minBuyingRequestInterval;  

    bool public isFinalized = false;

    event NewAccreditedInvestor(address indexed from, address indexed buyer);
    event TokenDistributed(address indexed beneficiary, uint256 tokens);

     
    function QiibeePresale(
        uint256 _startTime,
        uint256 _endTime,
        address _token,
        uint256 _rate,
        uint256 _cap,
        uint256 _distributionCap,
        uint256 _maxGasPrice,
        uint256 _minBuyingRequestInterval,
        address _wallet
    )
      Crowdsale(_startTime, _endTime, _rate, _wallet)
      CappedCrowdsale(_cap)
    {
      require(_distributionCap > 0);
      require(_maxGasPrice > 0);
      require(_minBuyingRequestInterval > 0);
      require(_token != address(0));

      distributionCap = _distributionCap;
      maxGasPrice = _maxGasPrice;
      minBuyingRequestInterval = _minBuyingRequestInterval;
      token = QiibeeTokenInterface(_token);
    }

     
    function buyTokens(address beneficiary) public payable whenNotPaused {
      require(beneficiary != address(0));
      require(validPurchase());

      AccreditedInvestor storage data = accredited[msg.sender];

       
      uint256 minInvest = data.minInvest;
      uint256 maxCumulativeInvest = data.maxCumulativeInvest;
      uint64 from = vestFromTime;
      uint64 cliff = from + data.cliff;
      uint64 vesting = cliff + data.vesting;
      bool revokable = data.revokable;
      bool burnsOnRevoke = data.burnsOnRevoke;

      uint256 tokens = msg.value.mul(rate);

       
      uint256 newBalance = balances[msg.sender].add(msg.value);
      require(newBalance <= maxCumulativeInvest && msg.value >= minInvest);

      if (data.cliff > 0 && data.vesting > 0) {
        require(QiibeeTokenInterface(token).mintVestedTokens(beneficiary, tokens, from, cliff, vesting, revokable, burnsOnRevoke, wallet));
      } else {
        require(QiibeeTokenInterface(token).mint(beneficiary, tokens));
      }

       
      balances[msg.sender] = newBalance;
      weiRaised = weiRaised.add(msg.value);
      tokensSold = tokensSold.add(tokens);

      TokenPurchase(msg.sender, beneficiary, msg.value, tokens);

      forwardFunds();
    }

     
    function distributeTokens(address _beneficiary, uint256 _tokens, uint64 _cliff, uint64 _vesting, bool _revokable, bool _burnsOnRevoke) public onlyOwner whenNotPaused {
      require(_beneficiary != address(0));
      require(_tokens > 0);
      require(_vesting >= _cliff);
      require(!isFinalized);
      require(hasEnded());

       
      uint256 totalDistributed = tokensDistributed.add(_tokens);
      assert(totalDistributed <= distributionCap);

      if (_cliff > 0 && _vesting > 0) {
        uint64 from = vestFromTime;
        uint64 cliff = from + _cliff;
        uint64 vesting = cliff + _vesting;
        assert(QiibeeTokenInterface(token).mintVestedTokens(_beneficiary, _tokens, from, cliff, vesting, _revokable, _burnsOnRevoke, wallet));
      } else {
        assert(QiibeeTokenInterface(token).mint(_beneficiary, _tokens));
      }

       
      tokensDistributed = tokensDistributed.add(_tokens);

      TokenDistributed(_beneficiary, _tokens);
    }

     
    function addAccreditedInvestor(address investor, uint64 cliff, uint64 vesting, bool revokable, bool burnsOnRevoke, uint256 minInvest, uint256 maxCumulativeInvest) public onlyOwner {
        require(investor != address(0));
        require(vesting >= cliff);
        require(minInvest > 0);
        require(maxCumulativeInvest > 0);
        require(minInvest <= maxCumulativeInvest);

        accredited[investor] = AccreditedInvestor(cliff, vesting, revokable, burnsOnRevoke, minInvest, maxCumulativeInvest);

        NewAccreditedInvestor(msg.sender, investor);
    }

     
    function isAccredited(address investor) public constant returns (bool) {
        AccreditedInvestor storage data = accredited[investor];
        return data.minInvest > 0;
    }

     
    function removeAccreditedInvestor(address investor) public onlyOwner {
        require(investor != address(0));
        delete accredited[investor];
    }


     
    function validPurchase() internal constant returns (bool) {
      require(isAccredited(msg.sender));
      bool withinFrequency = now.sub(lastCallTime[msg.sender]) >= minBuyingRequestInterval;
      bool withinGasPrice = tx.gasprice <= maxGasPrice;
      return super.validPurchase() && withinFrequency && withinGasPrice;
    }

     
    function finalize() public onlyOwner {
      require(!isFinalized);
      require(hasEnded());

      finalization();
      Finalized();

      isFinalized = true;

       
      QiibeeTokenInterface(token).transferOwnership(wallet);
    }

     
    function setToken(address tokenAddress) onlyOwner {
      require(now < startTime);
      token = QiibeeTokenInterface(tokenAddress);
    }

}