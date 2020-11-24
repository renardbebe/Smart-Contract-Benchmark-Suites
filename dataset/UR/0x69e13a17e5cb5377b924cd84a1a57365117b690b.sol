 

pragma solidity 0.4.24;

 

 
library SafeMath {

   
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
     
     
     
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

   
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
     
     
     
    return _a / _b;
  }

   
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

   
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}

 

 
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

   
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

   
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

 

 
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

   
  ERC20 public token;

   
  address public wallet;

   
   
   
   
  uint256 public rate;

   
  uint256 public weiRaised;

   
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
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
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

   
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

   
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

   
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  constructor(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 

 
contract FinalizableCrowdsale is Ownable, TimedCrowdsale {
  using SafeMath for uint256;

  bool public isFinalized = false;

  event Finalized();

   
  function finalize() public onlyOwner {
    require(!isFinalized);
    require(hasClosed());

    finalization();
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

 
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

   
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

   
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}

 

 
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


   
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

   
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

   
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

   
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

   
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

 

 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
     
    require(MintableToken(address(token)).mint(_beneficiary, _tokenAmount));
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

   
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

   
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

 

contract RealtyReturnsTokenInterface {
    function paused() public;
    function unpause() public;
    function finishMinting() public returns (bool);
}

 

 
contract PausableToken is StandardToken, Pausable {

  function transfer(
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transfer(_to, _value);
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.transferFrom(_from, _to, _value);
  }

  function approve(
    address _spender,
    uint256 _value
  )
    public
    whenNotPaused
    returns (bool)
  {
    return super.approve(_spender, _value);
  }

  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.increaseApproval(_spender, _addedValue);
  }

  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    whenNotPaused
    returns (bool success)
  {
    return super.decreaseApproval(_spender, _subtractedValue);
  }
}

 

 
contract RealtyReturnsToken is PausableToken, MintableToken {
    string public constant name = "Realty Returns Token";
    string public constant symbol = "RRT";
    uint8 public constant decimals = 18;

    constructor() public {
        pause();
    }
}

 

 
contract LockTokenAllocation is Ownable {
    using SafeMath for uint;
    uint256 public unlockedAt;
    uint256 public canSelfDestruct;
    uint256 public tokensCreated;
    uint256 public allocatedTokens;
    uint256 public totalLockTokenAllocation;

    mapping (address => uint256) public lockedAllocations;

    ERC20 public RR;

     
    constructor
        (
            ERC20 _token,
            uint256 _unlockedAt,
            uint256 _canSelfDestruct,
            uint256 _totalLockTokenAllocation
        )
        public
    {
        require(_token != address(0));

        RR = ERC20(_token);
        unlockedAt = _unlockedAt;
        canSelfDestruct = _canSelfDestruct;
        totalLockTokenAllocation = _totalLockTokenAllocation;
    }

     
    function addLockTokenAllocation(address beneficiary, uint256 allocationValue)
        external
        onlyOwner
        returns(bool)
    {
        require(lockedAllocations[beneficiary] == 0 && beneficiary != address(0));  

        allocatedTokens = allocatedTokens.add(allocationValue);
        require(allocatedTokens <= totalLockTokenAllocation);

        lockedAllocations[beneficiary] = allocationValue;
        return true;
    }


     
    function unlock() external {
        require(RR != address(0));
        assert(now >= unlockedAt);

         
        if (tokensCreated == 0) {
            tokensCreated = RR.balanceOf(this);
        }

        uint256 transferAllocation = lockedAllocations[msg.sender];
        lockedAllocations[msg.sender] = 0;

         
        require(RR.transfer(msg.sender, transferAllocation));
    }

     
    function kill() public onlyOwner {
        require(now >= canSelfDestruct);
        uint256 balance = RR.balanceOf(this);

        if (balance > 0) {
            RR.transfer(msg.sender, balance);
        }

        selfdestruct(owner);
    }
}

 

 

contract RealtyReturnsTokenCrowdsale is FinalizableCrowdsale, MintedCrowdsale, Pausable {
    uint256 constant public TRESURY_SHARE =              240000000e18;    
    uint256 constant public TEAM_SHARE =                 120000000e18;    
    uint256 constant public FOUNDERS_SHARE =             120000000e18;    
    uint256 constant public NETWORK_SHARE =              530000000e18;    

    uint256 constant public TOTAL_TOKENS_FOR_CROWDSALE = 190000000e18;   
    uint256 public crowdsaleSoftCap =  1321580e18;  

    address public treasuryWallet;
    address public teamShare;
    address public foundersShare;
    address public networkGrowth;

     
     
    address public remainderPurchaser;
    uint256 public remainderAmount;

    address public onePercentAddress;

    event MintedTokensFor(address indexed investor, uint256 tokensPurchased);
    event TokenRateChanged(uint256 previousRate, uint256 newRate);

     
    constructor
        (
            uint256 _openingTime,
            uint256 _closingTime,
            RealtyReturnsToken _token,
            uint256 _rate,
            address _wallet,
            address _treasuryWallet,
            address _onePercentAddress
        )
        public
        FinalizableCrowdsale()
        Crowdsale(_rate, _wallet, _token)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        require(_treasuryWallet != address(0));
        treasuryWallet = _treasuryWallet;
        onePercentAddress = _onePercentAddress;

         
        require(RealtyReturnsToken(token).paused());
    }

     
    function setRate(uint256 newRate) external onlyOwner {
        require(newRate != 0);

        emit TokenRateChanged(rate, newRate);
        rate = newRate;
    }

     
    function setSoftCap(uint256 newCap) external onlyOwner {
        require(newCap != 0);

        crowdsaleSoftCap = newCap;
    }

     
    function mintTokensFor(address beneficiaryAddress, uint256 amountOfTokens)
        public
        onlyOwner
    {
        require(beneficiaryAddress != address(0));
        require(token.totalSupply().add(amountOfTokens) <= TOTAL_TOKENS_FOR_CROWDSALE);

        _deliverTokens(beneficiaryAddress, amountOfTokens);
        emit MintedTokensFor(beneficiaryAddress, amountOfTokens);
    }

     
    function setTokenDistributionAddresses
        (
            address _teamShare,
            address _foundersShare,
            address _networkGrowth
        )
        public
        onlyOwner
    {
         
        require(teamShare == address(0x0) && foundersShare == address(0x0) && networkGrowth == address(0x0));
         
        require(_teamShare != address(0x0) && _foundersShare != address(0x0) && _networkGrowth != address(0x0));

        teamShare = _teamShare;
        foundersShare = _foundersShare;
        networkGrowth = _networkGrowth;
    }

     
     
    function hasClosed() public view returns (bool) {
        if (token.totalSupply() > crowdsaleSoftCap) {
            return true;
        }

        return super.hasClosed();
    }

     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        whenNotPaused
    {
        require(_beneficiary != address(0));
        require(token.totalSupply() < TOTAL_TOKENS_FOR_CROWDSALE);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 tokensAmount = _weiAmount.mul(rate);

         
        if (token.totalSupply().add(tokensAmount) > TOTAL_TOKENS_FOR_CROWDSALE) {
            tokensAmount = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            uint256 _weiAmountLocalScope = tokensAmount.div(rate);

             
            remainderPurchaser = msg.sender;
            remainderAmount = _weiAmount.sub(_weiAmountLocalScope);

             
            if (weiRaised > _weiAmount.add(_weiAmountLocalScope))
                weiRaised = weiRaised.sub(_weiAmount.add(_weiAmountLocalScope));
        }

        return tokensAmount;
    }

     
    function _forwardFunds() internal {
         
        uint256 onePercentValue = msg.value.div(100);
        uint256 valueToTransfer = msg.value.sub(onePercentValue);

        onePercentAddress.transfer(onePercentValue);
        wallet.transfer(valueToTransfer);
    }

     
    function finalization() internal {
         
        require(teamShare != address(0) && foundersShare != address(0) && networkGrowth != address(0));

        if (TOTAL_TOKENS_FOR_CROWDSALE > token.totalSupply()) {
            uint256 remainingTokens = TOTAL_TOKENS_FOR_CROWDSALE.sub(token.totalSupply());
            _deliverTokens(wallet, remainingTokens);
        }

         
        _deliverTokens(treasuryWallet, TRESURY_SHARE);
        _deliverTokens(teamShare, TEAM_SHARE);
        _deliverTokens(foundersShare, FOUNDERS_SHARE);
        _deliverTokens(networkGrowth, NETWORK_SHARE);

        RealtyReturnsToken(token).finishMinting();
        RealtyReturnsToken(token).unpause();
        super.finalization();
    }
}