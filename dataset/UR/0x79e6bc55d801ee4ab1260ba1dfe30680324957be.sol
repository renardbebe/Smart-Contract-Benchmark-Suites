 

pragma solidity ^0.4.24;

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
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

 
contract QashbackCrowdsale {
  using SafeMath for uint256;

   
  event Purchase(address indexed buyer, address token, uint256 value, uint256 sold, uint256 bonus, bytes txId);
   
  event RateAdd(address token);
   
  event RateRemove(address token);

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;

     
    (uint256 tokens, uint256 left) = _getTokenAmount(weiAmount);
    uint256 weiEarned = weiAmount.sub(left);
    uint256 bonus = _getBonus(tokens);
    uint256 withBonus = tokens.add(bonus);

    _preValidatePurchase(_beneficiary, weiAmount, tokens, bonus);

    _processPurchase(_beneficiary, withBonus);
    emit Purchase(
      _beneficiary,
      address(0),
        weiEarned,
      tokens,
      bonus,
      ""
    );

    _updatePurchasingState(_beneficiary, weiEarned, withBonus);
    _postValidatePurchase(_beneficiary, weiEarned);

    if (left > 0) {
      _beneficiary.transfer(left);
    }
  }

   
   
   

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
    require(_tokens != 0);
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
  ) internal;

   
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
    uint256 _weiAmount,
    uint256 _tokens
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens, uint256 weiLeft);

  function _getBonus(uint256 _tokens) internal view returns (uint256);
}

contract MintingQashbackCrowdsale is QashbackCrowdsale {
    MintableToken public token;

    constructor(MintableToken _token) public {
        token = _token;
    }

    function _deliverTokens(
        address _beneficiary,
        uint256 _tokenAmount
    ) internal {
        token.mint(_beneficiary, _tokenAmount);
    }
}

contract Whitelist {
  function isInWhitelist(address addr) public view returns (bool);
}

contract WhitelistQashbackCrowdsale is QashbackCrowdsale {
  Whitelist public whitelist;

  constructor (Whitelist _whitelist) public {
    whitelist = _whitelist;
  }

  function getWhitelists() view public returns (Whitelist[]) {
    Whitelist[] memory result = new Whitelist[](1);
    result[0] = whitelist;
    return result;
  }

  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount,
    uint256 _tokens,
    uint256 _bonus
  ) internal {
    super._preValidatePurchase(_beneficiary, _weiAmount, _tokens, _bonus);
    require(canBuy(_beneficiary), "investor is not verified by Whitelist");
  }

  function canBuy(address _beneficiary) view public returns (bool) {
    return whitelist.isInWhitelist(_beneficiary);
  }
}

 
contract CountingQashbackCrowdsale is QashbackCrowdsale {
    uint256 public sold;

    function _updatePurchasingState(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokens
    ) internal {
        super._updatePurchasingState(_beneficiary, _weiAmount, _tokens);

        sold = sold.add(_tokens);
    }
}

 
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

   
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
     
     

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
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

contract QBKToken is BurnableToken, PausableToken, MintableToken {
  string public constant name = "QashBack";
  string public constant symbol = "QBK";
  uint8 public constant decimals = 18;

  uint256 public constant MAX_TOTAL_SUPPLY = 1000000000 * 10 ** 18;

  function mint(address _to, uint256 _amount) public returns (bool) {
    require(totalSupply_.add(_amount) <= MAX_TOTAL_SUPPLY);
    return super.mint(_to, _amount);
  }
}

contract PausingQashbackSale is Ownable {
    Pausable public pausableToken;

    constructor(Pausable _pausableToken) public {
        pausableToken = _pausableToken;
    }

    function pauseToken() onlyOwner public {
        pausableToken.pause();
    }

    function unpauseToken() onlyOwner public {
        pausableToken.unpause();
    }
}

 
contract TokenHolder is Ownable {
    using SafeMath for uint;

    event Released(uint amount);

     
    uint public start;
     
    uint public vestingInterval;
     
    uint public released;
     
    uint public value;
     
    ERC20Basic public token;

    constructor(uint _start, uint _vestingInterval, uint _value, ERC20Basic _token) public {
        start = _start;
        vestingInterval = _vestingInterval;
        value = _value;
        token = _token;
    }

     
    function release() onlyOwner public {
        uint toRelease = calculateVestedAmount().sub(released);
        uint left = token.balanceOf(this);
        if (left < toRelease) {
            toRelease = left;
        }
        require(toRelease > 0, "nothing to release");
        released = released.add(toRelease);
        require(token.transfer(msg.sender, toRelease));
        emit Released(toRelease);
    }

    function calculateVestedAmount() view internal returns (uint) {
        return now.sub(start).div(vestingInterval).mul(value);
    }
}

 
contract PoolQashbackCrowdsale is Ownable, MintingQashbackCrowdsale {
    enum StartType { Fixed, Floating }

    event PoolCreatedEvent(string name, uint maxAmount, uint start, uint vestingInterval, uint value, StartType startType);
    event TokenHolderCreatedEvent(string name, address addr, uint amount);

    mapping(string => PoolDescription) pools;

    struct PoolDescription {
         
        uint maxAmount;
         
        uint releasedAmount;
         
        uint start;
         
        uint vestingInterval;
         
        uint value;
         
        StartType startType;
    }

    constructor(MintableToken _token) MintingQashbackCrowdsale(_token) public {

    }

    function registerPool(string _name, uint _maxAmount, uint _start, uint _vestingInterval, uint _value, StartType _startType) internal {
        require(_maxAmount > 0, "maxAmount should be greater than 0");
        require(_vestingInterval > 0, "vestingInterval should be greater than 0");
        require(_value > 0 && _value <= 100, "value should be >0 and <=100");
        pools[_name] = PoolDescription(_maxAmount, 0, _start, _vestingInterval, _value, _startType);
        emit PoolCreatedEvent(_name, _maxAmount, _start, _vestingInterval, _value, _startType);
    }

    function createHolder(string _name, address _beneficiary, uint _amount) onlyOwner public returns (TokenHolder) {
        PoolDescription storage pool = pools[_name];
        require(pool.maxAmount != 0, "pool is not defined");
        require(_amount.add(pool.releasedAmount) <= pool.maxAmount, "pool is depleted");
        pool.releasedAmount = _amount.add(pool.releasedAmount);
        uint start;
        if (pool.startType == StartType.Fixed) {
            start = pool.start;
        } else {
            start = now + pool.start;
        }
        TokenHolder created = new TokenHolder(start, pool.vestingInterval, _amount.mul(pool.value).div(100), token);
        created.transferOwnership(_beneficiary);
        token.mint(created, _amount);
        emit TokenHolderCreatedEvent(_name, created, _amount);
        return created;
    }

    function getTokensLeft(string _name) view public returns (uint) {
        PoolDescription storage pool = pools[_name];
        require(pool.maxAmount != 0, "pool is not defined");
        return pool.maxAmount.sub(pool.releasedAmount);
    }
}

 
contract QBKSale is PausingQashbackSale, PoolQashbackCrowdsale, CountingQashbackCrowdsale, WhitelistQashbackCrowdsale {
    uint constant public HARD_CAP = 30000000 * 10 ** 18;
    uint constant public TRANSFER_HARD_CAP = 100000000 * 10 ** 18;
    uint constant public SUPPLY_HARD_CAP = 1000000000 * 10 ** 18;
    uint256 constant public START = 1541073600;  
    uint256 constant public END = 1545393600;  

    uint256 public rate;
    uint256 public transferred;
    address public operator;

    event UsdEthRateChange(uint256 rate);
    event Withdraw(address to, uint256 value);

    constructor(QBKToken _token, Whitelist _whitelist, uint256 _usdEthRate)
        PausingQashbackSale(_token)
        PoolQashbackCrowdsale(_token)
        WhitelistQashbackCrowdsale(_whitelist)
        public {

        operator = owner;
         
        emit RateAdd(address(0));
        setUsdEthRate(_usdEthRate);
        registerPool("Category_2", SUPPLY_HARD_CAP, 86400 * 365 * 10, 1, 100, StartType.Floating);  
        registerPool("Category_3", SUPPLY_HARD_CAP, 86400, 1, 100, StartType.Floating);  
        registerPool("Category_4", SUPPLY_HARD_CAP, 86400 * 7, 1, 100, StartType.Floating);  
        registerPool("Category_5", SUPPLY_HARD_CAP, 86400 * 30, 1, 100, StartType.Floating);  
        registerPool("Category_6", SUPPLY_HARD_CAP, 86400 * 90, 1, 100, StartType.Floating);  
        registerPool("Category_7", SUPPLY_HARD_CAP, 86400 * 180, 1, 100, StartType.Floating);  
        registerPool("Category_8", SUPPLY_HARD_CAP, 86400 * 270, 1, 100, StartType.Floating);  
        registerPool("Category_9", SUPPLY_HARD_CAP, 86400 * 365, 1, 100, StartType.Floating);  
    }

    function _preValidatePurchase(
        address _beneficiary,
        uint256 _weiAmount,
        uint256 _tokens,
        uint256 _bonus
    ) internal {
        super._preValidatePurchase(_beneficiary, _weiAmount, _tokens, _bonus);
        require(now >= START);
        require(now < END);
    }

    function setUsdEthRate(uint256 _usdEthRate) onlyOperatorOrOwner public {
        rate = _usdEthRate.mul(10).div(4);
        emit UsdEthRateChange(_usdEthRate);
    }

    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256 tokens, uint256 weiLeft) {
        tokens = _weiAmount.mul(rate);
        if (sold.add(tokens) > HARD_CAP) {
            tokens = HARD_CAP.sub(sold);
             
            uint256 weiSpent = (tokens.add(rate).sub(1)).div(rate);
            weiLeft =_weiAmount.sub(weiSpent);
        } else {
            weiLeft = 0;
        }
    }

    function directTransfer(address _beneficiary, uint _amount) onlyOwner public {
        require(transferred.add(_amount) <= TRANSFER_HARD_CAP);
        token.mint(_beneficiary, _amount);
        transferred = transferred.add(_amount);
    }

    function withdrawEth(address _to, uint256 _value) onlyOwner public {
        _to.transfer(_value);
        emit Withdraw(_to, _value);
    }

    function _getBonus(uint256) internal view returns (uint256) {
        return 0;
    }

     
    function getRate(address _token) public view returns (uint256) {
        if (_token == address(0)) {
            return rate * 10 ** 18;
        } else {
            return 0;
        }
    }

     
    function start() public pure returns (uint256) {
        return START;
    }

     
    function end() public pure returns (uint256) {
        return END;
    }

     
    function initialCap() public pure returns (uint256) {
        return HARD_CAP;
    }

    function setOperator(address _operator) onlyOwner public {
        operator = _operator;
    }

    modifier onlyOperatorOrOwner() {
        require(msg.sender == operator || msg.sender == owner);
        _;
    }
}