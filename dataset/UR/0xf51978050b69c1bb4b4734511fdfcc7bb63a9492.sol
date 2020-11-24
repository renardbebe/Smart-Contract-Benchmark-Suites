 

pragma solidity ^0.4.18;

 
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
     
     
     
    return a / b;
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


 
contract CappedToken is MintableToken {

  uint256 public cap;

  function CappedToken(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    require(totalSupply_.add(_amount) <= cap);

    return super.mint(_to, _amount);
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

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    require(_value <= balances[msg.sender]);
     
     

    address burner = msg.sender;
    balances[burner] = balances[burner].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    Burn(burner, _value);
    Transfer(burner, address(0), _value);
  }
}

 
contract HardcapToken is CappedToken, PausableToken, BurnableToken {

  uint256 private constant TOKEN_CAP = 100 * 10**24;

  string public constant name = "Welltrado token";
  string public constant symbol = "WTL";
  uint8 public constant decimals = 18;

  function HardcapToken() public CappedToken(TOKEN_CAP) {
    paused = true;
  }
}

contract HardcapCrowdsale is Ownable {
  using SafeMath for uint256;

  struct Phase {
    uint256 capTo;
    uint256 rate;
  }

  uint256 private constant TEAM_PERCENTAGE = 10;
  uint256 private constant PLATFORM_PERCENTAGE = 25;
  uint256 private constant CROWDSALE_PERCENTAGE = 65;

  uint256 private constant MIN_TOKENS_TO_PURCHASE = 100 * 10**18;

  uint256 private constant ICO_TOKENS_CAP = 65 * 10**24;

  uint256 private constant FINAL_CLOSING_TIME = 1529928000;

  uint256 private constant INITIAL_START_DATE = 1524484800;

  uint256 public phase = 0;

  HardcapToken public token;

  address public wallet;
  address public platform;
  address public assigner;
  address public teamTokenHolder;

  uint256 public weiRaised;

  bool public isFinalized = false;

  uint256 public openingTime = 1524484800;
  uint256 public closingTime = 1525089600;
  uint256 public finalizedTime;

  mapping (uint256 => Phase) private phases;

  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);
  event TokenAssigned(address indexed purchaser, address indexed beneficiary, uint256 amount);


  event Finalized();

  modifier onlyAssginer() {
    require(msg.sender == assigner);
    _;
  }

  function HardcapCrowdsale(address _wallet, address _platform, address _assigner, HardcapToken _token) public {
      require(_wallet != address(0));
      require(_assigner != address(0));
      require(_platform != address(0));
      require(_token != address(0));

      wallet = _wallet;
      platform = _platform;
      assigner = _assigner;
      token = _token;

       
      phases[0] = Phase(15 * 10**23, 1250);
      phases[1] = Phase(10 * 10**24, 1200);
      phases[2] = Phase(17 * 10**24, 1150);
      phases[3] = Phase(24 * 10**24, 1100);
      phases[4] = Phase(31 * 10**24, 1070);
      phases[5] = Phase(38 * 10**24, 1050);
      phases[6] = Phase(47 * 10**24, 1030);
      phases[7] = Phase(56 * 10**24, 1000);
      phases[8] = Phase(65 * 10**24, 1000);
  }

  function () external payable {
    buyTokens(msg.sender);
  }

   
  function setTeamTokenHolder(address _teamTokenHolder) onlyOwner public {
    require(_teamTokenHolder != address(0));
     
    require(teamTokenHolder == address(0));
    teamTokenHolder = _teamTokenHolder;
  }

  function buyTokens(address _beneficiary) public payable {
    _processTokensPurchase(_beneficiary, msg.value);
  }

   
  function assignTokensToMultipleInvestors(address[] _beneficiaries, uint256[] _tokensAmount) onlyAssginer public {
    require(_beneficiaries.length == _tokensAmount.length);
    for (uint i = 0; i < _tokensAmount.length; i++) {
      _processTokensAssgin(_beneficiaries[i], _tokensAmount[i]);
    }
  }

   
  function assignTokens(address _beneficiary, uint256 _tokensAmount) onlyAssginer public {
    _processTokensAssgin(_beneficiary, _tokensAmount);
  }

  function finalize() onlyOwner public {
    require(teamTokenHolder != address(0));
    require(!isFinalized);
    require(_hasClosed());
    require(finalizedTime == 0);

    HardcapToken _token = HardcapToken(token);

     
    uint256 _tokenCap = _token.totalSupply().mul(100).div(CROWDSALE_PERCENTAGE);
    require(_token.mint(teamTokenHolder, _tokenCap.mul(TEAM_PERCENTAGE).div(100)));
    require(_token.mint(platform, _tokenCap.mul(PLATFORM_PERCENTAGE).div(100)));

     
    uint256 _tokensToBurn = _token.cap().sub(_token.totalSupply());
    require(_token.mint(address(this), _tokensToBurn));
    _token.burn(_tokensToBurn);

    require(_token.finishMinting());
    _token.transferOwnership(wallet);

    Finalized();

    finalizedTime = _getTime();
    isFinalized = true;
  }

  function _hasClosed() internal view returns (bool) {
    return _getTime() > FINAL_CLOSING_TIME || token.totalSupply() >= ICO_TOKENS_CAP;
  }

  function _processTokensAssgin(address _beneficiary, uint256 _tokenAmount) internal {
    _preValidateAssign(_beneficiary, _tokenAmount);

     
    uint256 _leftowers = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_tokenAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
       
      if (_leftowers < _tokenAmount) {
         _tokens = _tokens.add(_leftowers);
         _tokenAmount = _tokenAmount.sub(_leftowers);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_tokenAmount);
         _tokenAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE || _currentSupply == ICO_TOKENS_CAP);

     
    if (_phaseChanged) {
      _changeClosingTime();
    }

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenAssigned(msg.sender, _beneficiary, _tokens);
  }

  function _processTokensPurchase(address _beneficiary, uint256 _weiAmount) internal {
    _preValidatePurchase(_beneficiary, _weiAmount);

     
    uint256 _leftowers = 0;
    uint256 _weiReq = 0;
    uint256 _weiSpent = 0;
    uint256 _tokens = 0;
    uint256 _currentSupply = token.totalSupply();
    bool _phaseChanged = false;
    Phase memory _phase = phases[phase];

    while (_weiAmount > 0 && _currentSupply < ICO_TOKENS_CAP) {
      _leftowers = _phase.capTo.sub(_currentSupply);
      _weiReq = _leftowers.div(_phase.rate);
       
      if (_weiReq < _weiAmount) {
         _tokens = _tokens.add(_leftowers);
         _weiAmount = _weiAmount.sub(_weiReq);
         _weiSpent = _weiSpent.add(_weiReq);
         phase = phase + 1;
         _phaseChanged = true;
      } else {
         _tokens = _tokens.add(_weiAmount.mul(_phase.rate));
         _weiSpent = _weiSpent.add(_weiAmount);
         _weiAmount = 0;
      }

      _currentSupply = token.totalSupply().add(_tokens);
      _phase = phases[phase];
    }

    require(_tokens >= MIN_TOKENS_TO_PURCHASE || _currentSupply == ICO_TOKENS_CAP);

     
    if (_phaseChanged) {
      _changeClosingTime();
    }

     
    if (msg.value > _weiSpent) {
      uint256 _overflowAmount = msg.value.sub(_weiSpent);
      _beneficiary.transfer(_overflowAmount);
    }

    weiRaised = weiRaised.add(_weiSpent);

    require(HardcapToken(token).mint(_beneficiary, _tokens));
    TokenPurchase(msg.sender, _beneficiary, _weiSpent, _tokens);

     
     
     
    if (msg.value > 0) {
      wallet.transfer(_weiSpent);
    }
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
     
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
    require(_getTime() > INITIAL_START_DATE);
    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _preValidateAssign(address _beneficiary, uint256 _tokenAmount) internal {
     
    if (closingTime < _getTime() && closingTime < FINAL_CLOSING_TIME && phase < 8) {
      phase = phase.add(_calcPhasesPassed());
      _changeClosingTime();

    }
     
    require(_beneficiary != assigner);
    require(_beneficiary != platform);
    require(_beneficiary != wallet);
    require(_beneficiary != teamTokenHolder);

    require(_getTime() >= openingTime && _getTime() <= closingTime);
    require(_beneficiary != address(0));
    require(_tokenAmount > 0);
    require(phase <= 8);

    require(token.totalSupply() < ICO_TOKENS_CAP);
    require(!isFinalized);
  }

  function _changeClosingTime() internal {
    closingTime = _getTime() + 7 days;
    if (closingTime > FINAL_CLOSING_TIME) {
      closingTime = FINAL_CLOSING_TIME;
    }
  }

  function _calcPhasesPassed() internal view returns(uint256) {
    return  _getTime().sub(closingTime).div(7 days).add(1);
  }

 function _getTime() internal view returns (uint256) {
   return now;
 }

}

contract TeamTokenHolder is Ownable {
  using SafeMath for uint256;

  uint256 private LOCKUP_TIME = 24;  

  HardcapCrowdsale crowdsale;
  HardcapToken token;
  uint256 public collectedTokens;

  function TeamTokenHolder(address _owner, address _crowdsale, address _token) public {
    owner = _owner;
    crowdsale = HardcapCrowdsale(_crowdsale);
    token = HardcapToken(_token);
  }

   
  function collectTokens() public onlyOwner {
    uint256 balance = token.balanceOf(address(this));
    uint256 total = collectedTokens.add(balance);

    uint256 finalizedTime = crowdsale.finalizedTime();

    require(finalizedTime > 0 && getTime() >= finalizedTime.add(months(3)));

    uint256 canExtract = total.mul(getTime().sub(finalizedTime)).div(months(LOCKUP_TIME));

    canExtract = canExtract.sub(collectedTokens);

    if (canExtract > balance) {
      canExtract = balance;
    }

    collectedTokens = collectedTokens.add(canExtract);
    assert(token.transfer(owner, canExtract));

    TokensWithdrawn(owner, canExtract);
  }

  function months(uint256 m) internal pure returns (uint256) {
      return m.mul(30 days);
  }

  function getTime() internal view returns (uint256) {
    return now;
  }

   

   
  function claimTokens(address _token) public onlyOwner {
    require(_token != address(token));
    if (_token == 0x0) {
      owner.transfer(this.balance);
      return;
    }

    HardcapToken _hardcapToken = HardcapToken(_token);
    uint256 balance = _hardcapToken.balanceOf(this);
    _hardcapToken.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  event ClaimedTokens(address indexed _token, address indexed _controller, uint256 _amount);
  event TokensWithdrawn(address indexed _holder, uint256 _amount);
}