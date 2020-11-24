 

 
pragma solidity ^0.4.24;


 
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

 
 
pragma solidity ^0.4.24;


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
contract CanReclaimToken is Ownable {
  using SafeERC20 for ERC20Basic;

   
  function reclaimToken(ERC20Basic _token) external onlyOwner {
    uint256 balance = _token.balanceOf(this);
    _token.safeTransfer(owner, balance);
  }

}

 
 
pragma solidity ^0.4.24;


 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public cap;

   
  constructor(uint256 _cap) public {
    require(_cap > 0);
    cap = _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised >= cap;
  }

   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    require(weiRaised.add(_weiAmount) <= cap);
  }

}

 
 
pragma solidity ^0.4.24;


 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = true;
  }

   
  function remove(Role storage _role, address _addr)
    internal
  {
    _role.bearer[_addr] = false;
  }

   
  function check(Role storage _role, address _addr)
    internal
    view
  {
    require(has(_role, _addr));
  }

   
  function has(Role storage _role, address _addr)
    internal
    view
    returns (bool)
  {
    return _role.bearer[_addr];
  }
}

 
 
pragma solidity ^0.4.24;



 
contract RBAC {
  using Roles for Roles.Role;

  mapping (string => Roles.Role) private roles;

  event RoleAdded(address indexed operator, string role);
  event RoleRemoved(address indexed operator, string role);

   
  function checkRole(address _operator, string _role)
    public
    view
  {
    roles[_role].check(_operator);
  }

   
  function hasRole(address _operator, string _role)
    public
    view
    returns (bool)
  {
    return roles[_role].has(_operator);
  }

   
  function addRole(address _operator, string _role)
    internal
  {
    roles[_role].add(_operator);
    emit RoleAdded(_operator, _role);
  }

   
  function removeRole(address _operator, string _role)
    internal
  {
    roles[_role].remove(_operator);
    emit RoleRemoved(_operator, _role);
  }

   
  modifier onlyRole(string _role)
  {
    checkRole(msg.sender, _role);
    _;
  }

   
   
   
   
   
   
   
   
   

   

   
   
}

 
 
pragma solidity ^0.4.24;




 
contract Whitelist is Ownable, RBAC {
  string public constant ROLE_WHITELISTED = "whitelist";

   
  modifier onlyIfWhitelisted(address _operator) {
    checkRole(_operator, ROLE_WHITELISTED);
    _;
  }

   
  function addAddressToWhitelist(address _operator)
    public
    onlyOwner
  {
    addRole(_operator, ROLE_WHITELISTED);
  }

   
  function whitelist(address _operator)
    public
    view
    returns (bool)
  {
    return hasRole(_operator, ROLE_WHITELISTED);
  }

   
  function addAddressesToWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      addAddressToWhitelist(_operators[i]);
    }
  }

   
  function removeAddressFromWhitelist(address _operator)
    public
    onlyOwner
  {
    removeRole(_operator, ROLE_WHITELISTED);
  }

   
  function removeAddressesFromWhitelist(address[] _operators)
    public
    onlyOwner
  {
    for (uint256 i = 0; i < _operators.length; i++) {
      removeAddressFromWhitelist(_operators[i]);
    }
  }

}

 
 
pragma solidity ^0.4.24;



 
contract WhitelistedCrowdsale is Whitelist, Crowdsale {
   
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyIfWhitelisted(_beneficiary)
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

 
 
pragma solidity ^0.4.24;




 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
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

 
 
pragma solidity ^0.4.24;



 
contract TokenTimelock {
  using SafeERC20 for ERC20Basic;

   
  ERC20Basic public token;

   
  address public beneficiary;

   
  uint256 public releaseTime;

  constructor(
    ERC20Basic _token,
    address _beneficiary,
    uint256 _releaseTime
  )
    public
  {
     
    require(_releaseTime > block.timestamp);
    token = _token;
    beneficiary = _beneficiary;
    releaseTime = _releaseTime;
  }

   
  function release() public {
     
    require(block.timestamp >= releaseTime);

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0);

    token.safeTransfer(beneficiary, amount);
  }
}

 
 
pragma solidity ^0.4.24;




 
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

 
 
 
pragma solidity 0.4.24;



 
contract HbeCrowdsale is CanReclaimToken, CappedCrowdsale, MintedCrowdsale, WhitelistedCrowdsale, FinalizableCrowdsale, Pausable {
     
    address public constant ETH_WALLET = 0x9E35Ee118D9B305F27AE1234BF5c035c1860989C;
    address public constant TEAM_WALLET = 0x992CEad41b885Dc90Ef82673c3c211Efa1Ef1AE2;
    uint256 public constant START_EASTER_BONUS = 1555668000;  
    uint256 public constant END_EASTER_BONUS = 1555970399;    
     
    uint256 public constant ICO_HARD_CAP = 22e8;              
    uint256 public constant CHF_HBE_RATE = 0.0143 * 1e4;     
    uint256 public constant TEAM_HBE_AMOUNT = 200e6;         
    uint256 public constant FOUR = 4;             
    uint256 public constant TWO = 2;              
    uint256 public constant HUNDRED = 100;
    uint256 public constant ONE_YEAR = 365 days;
    uint256 public constant BONUS_DURATION = 14 days;    
    uint256 public constant BONUS_1 = 15;    
    uint256 public constant BONUS_2 = 10;    
    uint256 public constant BONUS_3 = 5;     
    uint256 public constant PRECISION = 1e6;  

     
     
    bool public isTeamTokensMinted;
    address[3] public teamTokensLocked;

     
     
    mapping(address => bool) public isManager;

    uint256 public tokensMinted;     
    uint256 public rateDecimals;     

     
    event ChangedManager(address indexed manager, bool active);
    event NonEthTokenPurchase(uint256 investmentType, address indexed beneficiary, uint256 tokenAmount);
    event RefundAmount(address indexed beneficiary, uint256 refundAmount);
    event UpdatedFiatRate(uint256 fiatRate, uint256 rateDecimals);

     
    modifier onlyManager() {
        require(isManager[msg.sender], "not manager");
        _;
    }

    modifier onlyValidAddress(address _address) {
        require(_address != address(0), "invalid address");
        _;
    }

    modifier onlyNoneZero(address _to, uint256 _amount) {
        require(_to != address(0), "invalid address");
        require(_amount > 0, "invalid amount");
        _;
    }

     
    constructor(
        uint256 _startTime,
        uint256 _endTime,
        address _token,
        uint256 _rate,
        uint256 _rateDecimals
        )
        public
        Crowdsale(_rate, ETH_WALLET, ERC20(_token))
        TimedCrowdsale(_startTime, _endTime)
        CappedCrowdsale(ICO_HARD_CAP) {
            setManager(msg.sender, true);
            _updateRate(_rate, _rateDecimals);
        }

     
    function updateRate(uint256 _rate, uint256 _rateDecimals) external onlyManager {
        _updateRate(_rate, _rateDecimals);
    }

     
    function mintTeamTokens() external onlyManager {
        require(!isTeamTokensMinted, "team tokens already minted");

        isTeamTokensMinted = true;

        TokenTimelock team1 = new TokenTimelock(ERC20Basic(token), TEAM_WALLET, openingTime.add(ONE_YEAR));
        TokenTimelock team2 = new TokenTimelock(ERC20Basic(token), TEAM_WALLET, openingTime.add(2 * ONE_YEAR));
        TokenTimelock team3 = new TokenTimelock(ERC20Basic(token), TEAM_WALLET, openingTime.add(3 * ONE_YEAR));

        teamTokensLocked[0] = address(team1);
        teamTokensLocked[1] = address(team2);
        teamTokensLocked[2] = address(team3);

        _deliverTokens(address(team1), TEAM_HBE_AMOUNT.div(FOUR));
        _deliverTokens(address(team2), TEAM_HBE_AMOUNT.div(FOUR));
        _deliverTokens(address(team3), TEAM_HBE_AMOUNT.div(TWO));
    }

     
    function batchNonEthPurchase(uint256[] _investmentTypes, address[] _beneficiaries, uint256[] _amounts) external {
        require(_beneficiaries.length == _amounts.length && _investmentTypes.length == _amounts.length, "length !=");

        for (uint256 i; i < _beneficiaries.length; i = i.add(1)) {
            nonEthPurchase(_investmentTypes[i], _beneficiaries[i], _amounts[i]);
        }
    }

     
    function getTeamLockedContracts() external view returns (address[3]) {
        return teamTokensLocked;
    }

     
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;

        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
         
        weiAmount = weiAmount.sub(refundLeftOverWei(weiAmount, tokens));

         
        tokens = tokens.add(_calcBonusAmount(tokens));

         
        weiRaised = weiRaised.add(weiAmount);
         
        _processPurchase(_beneficiary, tokens);
         
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

         
        _forwardFunds(weiAmount);
    }

     
    function capReached() public view returns (bool) {
        return tokensMinted >= cap;
    }

     
    function setManager(address _manager, bool _active) public onlyOwner onlyValidAddress(_manager) {
        isManager[_manager] = _active;
        emit ChangedManager(_manager, _active);
    }

     
    function addAddressToWhitelist(address _address)
        public
        onlyManager
    {
        addRole(_address, ROLE_WHITELISTED);
    }

     
    function removeAddressFromWhitelist(address _address)
        public
        onlyManager
    {
        removeRole(_address, ROLE_WHITELISTED);
    }

     
    function removeAddressesFromWhitelist(address[] _addresses)
        public
        onlyManager
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            removeAddressFromWhitelist(_addresses[i]);
        }
    }

     
    function addAddressesToWhitelist(address[] _addresses)
        public
        onlyManager
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            addAddressToWhitelist(_addresses[i]);
        }
    }

     
    function nonEthPurchase(uint256 _investmentType, address _beneficiary, uint256 _tokenAmount) public
        onlyManager
        onlyWhileOpen
        onlyNoneZero(_beneficiary, _tokenAmount)
    {
        _processPurchase(_beneficiary, _tokenAmount);
        emit NonEthTokenPurchase(_investmentType, _beneficiary, _tokenAmount);
    }

     
    function pause() public onlyManager whenNotPaused onlyWhileOpen {
        paused = true;
        emit Pause();
    }

     
    function unpause() public onlyManager whenPaused {
        paused = false;
        emit Unpause();
    }

     
    function finalize() public onlyManager {
        Pausable(address(token)).unpause();
        Ownable(address(token)).transferOwnership(owner);

        super.finalize();
    }

     
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
        onlyWhileOpen
        whenNotPaused
        onlyIfWhitelisted(_beneficiary) {
            require(_weiAmount != 0, "invalid amount");
            require(!capReached(), "cap has been reached");
        }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        tokensMinted = tokensMinted.add(_tokenAmount);
         
        require(tokensMinted <= cap, "tokensMinted > cap");
        _deliverTokens(_beneficiary, _tokenAmount);
    }

     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        return _weiAmount.mul(rate).div(rateDecimals).div(1e18).div(PRECISION);
    }

     
    function _calcBonusAmount(uint256 _tokenAmount) internal view returns (uint256) {
        uint256 currentBonus;

         
        if (block.timestamp < openingTime.add(BONUS_DURATION)) {
            currentBonus = BONUS_1;
        } else if (block.timestamp < openingTime.add(BONUS_DURATION.mul(2))) {
            currentBonus = BONUS_2;
        } else if (block.timestamp < openingTime.add(BONUS_DURATION.mul(3))) {
            currentBonus = BONUS_3;
        } else if (block.timestamp >= START_EASTER_BONUS && block.timestamp < END_EASTER_BONUS) {
            currentBonus = BONUS_2;
        }
         

        return _tokenAmount.mul(currentBonus).div(HUNDRED);
    }

     
    function refundLeftOverWei(uint256 _weiReceived, uint256 _tokenAmount) internal returns (uint256 refundAmount) {
        uint256 weiInvested = _tokenAmount.mul(1e18).mul(PRECISION).mul(rateDecimals).div(rate);

        if (weiInvested < _weiReceived) {
            refundAmount = _weiReceived.sub(weiInvested);
        }

        if (refundAmount > 0) {
            msg.sender.transfer(refundAmount);
            emit RefundAmount(msg.sender, refundAmount);
        }

        return refundAmount;
    }

     
    function _forwardFunds(uint256 _weiAmount) internal {
        wallet.transfer(_weiAmount);
    }

     
    function _updateRate(uint256 _rate, uint256 _rateDecimals) internal {
        require(_rateDecimals <= 18);

        rateDecimals = 10**_rateDecimals;
        rate = (_rate.mul(1e4).mul(PRECISION).div(CHF_HBE_RATE));

        emit UpdatedFiatRate(_rate, _rateDecimals);
    }
}

 