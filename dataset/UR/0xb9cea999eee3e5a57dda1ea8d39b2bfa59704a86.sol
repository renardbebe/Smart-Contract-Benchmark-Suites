 

pragma solidity ^0.4.23;

 

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
     
     
     
    if (a == 0) {
      return 0;
    }

    c = a * b;
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

   
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

 

 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 

 
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender)
    public view returns (uint256);

  function transferFrom(address from, address to, uint256 value)
    public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

 

 
contract Crowdsale {
  using SafeMath for uint256;

   
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
    token.transfer(_beneficiary, _tokenAmount);
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

 

contract ZeexWhitelistedCrowdsale is Crowdsale, Ownable {

  address public whitelister;
  mapping(address => bool) public whitelist;

  constructor(address _whitelister) public {
    require(_whitelister != address(0));
    whitelister = _whitelister;
  }

  modifier isWhitelisted(address _beneficiary) {
    require(whitelist[_beneficiary]);
    _;
  }

  function addToWhitelist(address _beneficiary) public onlyOwnerOrWhitelister {
    whitelist[_beneficiary] = true;
  }

  function addManyToWhitelist(address[] _beneficiaries) public onlyOwnerOrWhitelister {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelist[_beneficiaries[i]] = true;
    }
  }

  function removeFromWhitelist(address _beneficiary) public onlyOwnerOrWhitelister {
    whitelist[_beneficiary] = false;
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal isWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

  modifier onlyOwnerOrWhitelister() {
    require(msg.sender == owner || msg.sender == whitelister);
    _;
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
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

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
    uint _addedValue
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
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
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
    hasMintPermission
    canMint
    public
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() onlyOwner canMint public returns (bool) {
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
    require(MintableToken(token).mint(_beneficiary, _tokenAmount));
  }
}

 

 
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

contract ZeexCrowdsale is CappedCrowdsale, MintedCrowdsale, TimedCrowdsale, Pausable, ZeexWhitelistedCrowdsale {
  using SafeMath for uint256;

  uint256 public presaleOpeningTime;
  uint256 public presaleClosingTime;
  uint256 public presaleBonus = 25;
  uint256 public minPresaleWei;
  uint256 public maxPresaleWei;

  bytes1 public constant publicPresale = "0";
  bytes1 public constant privatePresale = "1";

  address[] public bonusUsers;
  mapping(address => mapping(bytes1 => uint256)) public bonusTokens;

  event Lock(address user, uint amount, bytes1 tokenType);
  event ReleaseLockedTokens(bytes1 tokenType, address user, uint amount, address to);

  constructor(uint256 _openingTime, uint256 _closingTime, uint hardCapWei,
    uint256 _presaleOpeningTime, uint256 _presaleClosingTime,
    uint256 _minPresaleWei, uint256 _maxPresaleWei,
    address _wallet, MintableToken _token, address _whitelister) public
    Crowdsale(5000, _wallet, _token)
    CappedCrowdsale(hardCapWei)
    TimedCrowdsale(_openingTime, _closingTime)
    validPresaleClosingTime(_presaleOpeningTime, _presaleClosingTime)
    ZeexWhitelistedCrowdsale(_whitelister) {

    require(_presaleOpeningTime >= openingTime);
    require(_maxPresaleWei >= _minPresaleWei);

    presaleOpeningTime = _presaleOpeningTime;
    presaleClosingTime = _presaleClosingTime;
    minPresaleWei = _minPresaleWei;
    maxPresaleWei = _maxPresaleWei;

    paused = true;
  }

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    super._preValidatePurchase(_beneficiary, _weiAmount);

    if (isPresaleOn()) {
      require(_weiAmount >= minPresaleWei && _weiAmount <= maxPresaleWei);
    }
  }

  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    return _weiAmount.mul(rate).add(getPresaleBonusAmount(_weiAmount));
  }

  function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
    uint256 weiAmount = msg.value;
    uint256 lockedAmount = getPresaleBonusAmount(weiAmount);
    uint256 unlockedAmount = _tokenAmount.sub(lockedAmount);

    if (lockedAmount > 0) {
      lockAndDeliverTokens(_beneficiary, lockedAmount, publicPresale);
    }

    _deliverTokens(_beneficiary, unlockedAmount);
  }
   

  function grantTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  function grantBonusTokens(address _beneficiary, uint256 _tokenAmount) public onlyOwner {
    lockAndDeliverTokens(_beneficiary, _tokenAmount, privatePresale);
  }

   

  function lockAndDeliverTokens(address _beneficiary, uint256 _tokenAmount, bytes1 _type) internal {
    lockBonusTokens(_beneficiary, _tokenAmount, _type);
    _deliverTokens(address(this), _tokenAmount);
  }

  function lockBonusTokens(address _beneficiary, uint256 _amount, bytes1 _type) internal {
    if (bonusTokens[_beneficiary][publicPresale] == 0 && bonusTokens[_beneficiary][privatePresale] == 0) {
      bonusUsers.push(_beneficiary);
    }

    bonusTokens[_beneficiary][_type] = bonusTokens[_beneficiary][_type].add(_amount);
    emit Lock(_beneficiary, _amount, _type);
  }

  function getBonusBalance(uint _from, uint _to) public view returns (uint total) {
    require(_from >= 0 && _to >= _from && _to <= bonusUsers.length);

    for (uint i = _from; i < _to; i++) {
      total = total.add(getUserBonusBalance(bonusUsers[i]));
    }
  }

  function getBonusBalanceByType(uint _from, uint _to, bytes1 _type) public view returns (uint total) {
    require(_from >= 0 && _to >= _from && _to <= bonusUsers.length);

    for (uint i = _from; i < _to; i++) {
      total = total.add(bonusTokens[bonusUsers[i]][_type]);
    }
  }

  function getUserBonusBalanceByType(address _user, bytes1 _type) public view returns (uint total) {
    return bonusTokens[_user][_type];
  }

  function getUserBonusBalance(address _user) public view returns (uint total) {
    total = total.add(getUserBonusBalanceByType(_user, publicPresale));
    total = total.add(getUserBonusBalanceByType(_user, privatePresale));
  }

  function getBonusUsersCount() public view returns(uint count) {
    return bonusUsers.length;
  }

  function releasePublicPresaleBonusTokens(address[] _users, uint _percentage) public onlyOwner {
    require(_percentage > 0 && _percentage <= 100);

    for (uint i = 0; i < _users.length; i++) {
      address user = _users[i];
      uint tokenBalance = bonusTokens[user][publicPresale];
      uint amount = tokenBalance.mul(_percentage).div(100);
      releaseBonusTokens(user, amount, user, publicPresale);
    }
  }

  function releaseUserPrivateBonusTokens(address _user, uint _amount, address _to) public onlyOwner {
    releaseBonusTokens(_user, _amount, _to, privatePresale);
  }

  function releasePrivateBonusTokens(address[] _users, uint[] _amounts) public onlyOwner {
    for (uint i = 0; i < _users.length; i++) {
      address user = _users[i];
      uint amount = _amounts[i];
      releaseBonusTokens(user, amount, user, privatePresale);
    }
  }

  function releaseBonusTokens(address _user, uint _amount, address _to, bytes1 _type) internal onlyOwner {
    uint tokenBalance = bonusTokens[_user][_type];
    require(tokenBalance >= _amount);

    bonusTokens[_user][_type] = bonusTokens[_user][_type].sub(_amount);
    token.transfer(_to, _amount);
    emit ReleaseLockedTokens(_type, _user, _amount, _to);
  }

   
  function getPresaleBonusAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 tokenAmount = 0;
    if (isPresaleOn()) tokenAmount = (_weiAmount.mul(presaleBonus).div(100)).mul(rate);

    return tokenAmount;
  }

  function updatePresaleMinWei(uint _minPresaleWei) public onlyOwner {
    require(maxPresaleWei >= _minPresaleWei);

    minPresaleWei = _minPresaleWei;
  }

  function updatePresaleMaxWei(uint _maxPresaleWei) public onlyOwner {
    require(_maxPresaleWei >= minPresaleWei);

    maxPresaleWei = _maxPresaleWei;
  }

  function updatePresaleBonus(uint _presaleBonus) public onlyOwner {
    presaleBonus = _presaleBonus;
  }

  function isPresaleOn() public view returns (bool) {
    return block.timestamp >= presaleOpeningTime && block.timestamp <= presaleClosingTime;
  }

  modifier validPresaleClosingTime(uint _presaleOpeningTime, uint _presaleClosingTime) {
    require(_presaleOpeningTime >= openingTime);
    require(_presaleClosingTime >= _presaleOpeningTime);
    require(_presaleClosingTime <= closingTime);
    _;
  }

  function setOpeningTime(uint256 _openingTime) public onlyOwner {
    require(_openingTime >= block.timestamp);
    require(presaleOpeningTime >= _openingTime);
    require(closingTime >= _openingTime);

    openingTime = _openingTime;
  }

  function setPresaleClosingTime(uint _presaleClosingTime) public onlyOwner validPresaleClosingTime(presaleOpeningTime, _presaleClosingTime) {
    presaleClosingTime = _presaleClosingTime;
  }

  function setPresaleOpeningClosingTime(uint256 _presaleOpeningTime, uint256 _presaleClosingTime) public onlyOwner validPresaleClosingTime(_presaleOpeningTime, _presaleClosingTime) {
    presaleOpeningTime = _presaleOpeningTime;
    presaleClosingTime = _presaleClosingTime;
  }

  function setClosingTime(uint256 _closingTime) public onlyOwner {
    require(_closingTime >= block.timestamp);
    require(_closingTime >= openingTime);

    closingTime = _closingTime;
  }

  function setOpeningClosingTime(uint256 _openingTime, uint256 _closingTime) public onlyOwner {
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  function transferTokenOwnership(address _to) public onlyOwner {
    Ownable(token).transferOwnership(_to);
  }
}