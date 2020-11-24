 

pragma solidity ^0.4.18;

 

 
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

 

 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic token) external onlyOwner {
    uint256 balance = token.balanceOf(this);
    token.safeTransfer(owner, balance);
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

 

 
contract ERC827 is ERC20 {

  function approve( address _spender, uint256 _value, bytes _data ) public returns (bool);
  function transfer( address _to, uint256 _value, bytes _data ) public returns (bool);
  function transferFrom( address _from, address _to, uint256 _value, bytes _data ) public returns (bool);

}

 

 
contract ERC827Token is ERC827, StandardToken {

   
  function approve(address _spender, uint256 _value, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.approve(_spender, _value);

    require(_spender.call(_data));

    return true;
  }

   
  function transfer(address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transfer(_to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function transferFrom(address _from, address _to, uint256 _value, bytes _data) public returns (bool) {
    require(_to != address(this));

    super.transferFrom(_from, _to, _value);

    require(_to.call(_data));
    return true;
  }

   
  function increaseApproval(address _spender, uint _addedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.increaseApproval(_spender, _addedValue);

    require(_spender.call(_data));

    return true;
  }

   
  function decreaseApproval(address _spender, uint _subtractedValue, bytes _data) public returns (bool) {
    require(_spender != address(this));

    super.decreaseApproval(_spender, _subtractedValue);

    require(_spender.call(_data));

    return true;
  }

}

 

contract PalliumToken is MintableToken, PausableToken, ERC827Token, CanReclaimToken {
    string public constant name = 'PalliumToken';
    string public constant symbol = 'PLMT';
    uint8  public constant decimals = 18;

    function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        require (totalSupply_ + _amount <= 250 * 10**6 * 10**18);
        return super.mint(_to, _amount);
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
    token = token;
  }

  function _postValidatePurchase(address, uint256) internal {
     
    token = token;
  }

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    token.transfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function _updatePurchasingState(address, uint256) internal {
     
    token = token;
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 

contract StagedCrowdsale is Crowdsale {
    struct Stage {
        uint    index;
        uint256 hardCap;
        uint256 softCap;
        uint256 currentMinted;
        uint256 bonusMultiplier;
        uint256 startTime;
        uint256 endTime;
    }

    mapping (uint => Stage) public stages;
    uint256 public currentStage;

    enum State { Created, Paused, Running, Finished }
    State public currentState = State.Created;

    function StagedCrowdsale() public {
        currentStage = 0;
    }

    function setStage(uint _nextStage) internal {
        currentStage = _nextStage;
    }

    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal {
        require(currentState == State.Running);
        require((now >= stages[currentStage].startTime) && (now <= stages[currentStage].endTime));
        require(_beneficiary != address(0));
        require(_weiAmount >= 200 szabo);
    } 

    function computeTokensWithBonus(uint256 _weiAmount) public view returns(uint256) {
        uint256 tokenAmount = super._getTokenAmount(_weiAmount);
        uint256 bonusAmount = tokenAmount.mul(stages[currentStage].bonusMultiplier).div(100); 
        return tokenAmount.add(bonusAmount);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokenAmount = computeTokensWithBonus(_weiAmount);

        uint256 currentHardCap = stages[currentStage].hardCap;
        uint256 currentMinted = stages[currentStage].currentMinted;
        if (currentMinted.add(tokenAmount) > currentHardCap) {
            return currentHardCap.sub(currentMinted);
        } 
        return tokenAmount;
    } 

    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        require(_tokenAmount > 0);

        super._processPurchase(_beneficiary, _tokenAmount);

        uint256 surrender = computeTokensWithBonus(msg.value) - _tokenAmount;
        if (msg.value > 0 && surrender > 0)
        {   
            uint256 currentRate = computeTokensWithBonus(msg.value) / msg.value;
            uint256 surrenderEth = surrender.div(currentRate);
            _beneficiary.transfer(surrenderEth);
        }
    }

    function _getTokenRaised(uint256 _weiAmount) internal view returns (uint256) {
        return stages[currentStage].currentMinted.add(_getTokenAmount(_weiAmount));
    }

    function _updatePurchasingState(address, uint256 _weiAmount) internal {
        stages[currentStage].currentMinted = stages[currentStage].currentMinted.add(computeTokensWithBonus(_weiAmount));
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

   
  function RefundVault(address _wallet) public {
    require(_wallet != address(0));
    wallet = _wallet;
    state = State.Active;
  }

   
  function deposit(address investor) onlyOwner public payable {
    require(state == State.Active);
    deposited[investor] = deposited[investor].add(msg.value);
  }

  function close() onlyOwner public {
    require(state == State.Active);
    state = State.Closed;
    Closed();
    wallet.transfer(this.balance);
  }

  function enableRefunds() onlyOwner public {
    require(state == State.Active);
    state = State.Refunding;
    RefundsEnabled();
  }

   
  function refund(address investor) public {
    require(state == State.Refunding);
    uint256 depositedValue = deposited[investor];
    deposited[investor] = 0;
    investor.transfer(depositedValue);
    Refunded(investor, depositedValue);
  }
}

 

contract StagedRefundVault is RefundVault {

    event ClosedStage();
    event Active();
    function StagedRefundVault (address _wallet) public
        RefundVault(_wallet) {
    }
    
    function stageClose() onlyOwner public {
        ClosedStage();
        wallet.transfer(this.balance);
    }

    function activate() onlyOwner public {
        require(state == State.Refunding);
        state = State.Active;
        Active();
    }
}

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 

contract PalliumCrowdsale is StagedCrowdsale, MintedCrowdsale, Pausable {
    StagedRefundVault public vault;

    function PalliumCrowdsale(uint256 _rate, address _wallet) public
        Crowdsale(_rate, _wallet, new PalliumToken())
        StagedCrowdsale(){  
             
            _processPurchase(_wallet, 25*(10**24));
            vault = new StagedRefundVault(_wallet);

            stages[0] = Stage(0, 5*(10**24), 33*(10**23), 0, 100, 1522540800, 1525132800);
            stages[1] = Stage(1, 375*(10**23), 2475*(10**22),  0, 50, 1533081600, 1535760000);
            stages[2] = Stage(2, 75*(10**24), 495*(10**23), 0, 25, 1543622400, 1546300800);
            stages[3] = Stage(3, 1075*(10**23), 7095*(10**22), 0, 15, 1554076800, 1556668800);
    }   

    function goalReached() internal view returns (bool) {
        return stages[currentStage].currentMinted >= stages[currentStage].softCap;
    }

    function hardCapReached() internal view returns (bool) {
        return stages[currentStage].currentMinted >= stages[currentStage].hardCap;
    }

    function claimRefund() public {
      require(!goalReached());
      require(currentState == State.Running);

      vault.refund(msg.sender);
    }

     
     
    function toggleVaultStateToAcive() public onlyOwner {
        require(now >= stages[currentStage].startTime - 1 days);
        vault.activate();
    }

    function finalizeCurrentStage() public onlyOwner {
        require(now > stages[currentStage].endTime || hardCapReached());
        require(currentState == State.Running);

        if (goalReached()) {
            vault.stageClose();
        } else {
            vault.enableRefunds();
        }

        if (stages[currentStage].index < 3) {
            setStage(currentStage + 1);
        } else
        {
            finalizationCrowdsale();
        }
    }

    function finalizationCrowdsale() internal {
        vault.close();
        setState(StagedCrowdsale.State.Finished);
        PalliumToken(token).finishMinting();
        PalliumToken(token).transferOwnership(owner);
    } 

    function migrateCrowdsale(address _newOwner) public onlyOwner {
        require(currentState == State.Paused);

        PalliumToken(token).transferOwnership(_newOwner);
        StagedRefundVault(vault).transferOwnership(_newOwner);
    }

    function setState(State _nextState) public onlyOwner {
        bool canToggleState
            =  (currentState == State.Created && _nextState == State.Running)
            || (currentState == State.Running && _nextState == State.Paused)
            || (currentState == State.Paused  && _nextState == State.Running)
            || (currentState == State.Running && _nextState == State.Finished);

        require(canToggleState);
        currentState = _nextState;
    }

    function manualPurchaseTokens (address _beneficiary, uint256 _weiAmount) public onlyOwner {
       
        _preValidatePurchase(_beneficiary, _weiAmount);

        uint256 tokens = _getTokenAmount(_weiAmount);

        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, _weiAmount, tokens);
        _updatePurchasingState(_beneficiary, _weiAmount);
    }

    function _forwardFunds() internal {
        vault.deposit.value(this.balance)(msg.sender);
    }

}