 

pragma solidity 0.4.23;

 

 
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
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    emit OwnershipTransferred(owner, newOwner);
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
    emit Pause();
  }

   
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}

 

 
contract PausableCrowdsale is Crowdsale, Pausable {

   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal whenNotPaused {
    return super._preValidatePurchase(_beneficiary, _weiAmount);
  }
}

 

contract IDAVToken is ERC20 {

  function name() public view returns (string) {}
  function symbol() public view returns (string) {}
  function decimals() public view returns (uint8) {}
  function increaseApproval(address _spender, uint _addedValue) public returns (bool success);
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool success);

  function owner() public view returns (address) {}
  function transferOwnership(address newOwner) public;

  function burn(uint256 _value) public;

  function pauseCutoffTime() public view returns (uint256) {}
  function paused() public view returns (bool) {}
  function pause() public;
  function unpause() public;
  function setPauseCutoffTime(uint256 _pauseCutoffTime) public;

}

 

 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

   
  modifier onlyWhileOpen {
     
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

   
  function TimedCrowdsale(uint256 _openingTime, uint256 _closingTime) public {
     
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > closingTime;
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
    emit Finalized();

    isFinalized = true;
  }

   
  function finalization() internal {
  }

}

 

 
contract DAVCrowdsale is PausableCrowdsale, FinalizableCrowdsale {

   
  uint256 public openingTimeB;
   
  mapping(address => uint256) public contributions;
   
  mapping(address => bool) public whitelistA;
   
  mapping(address => bool) public whitelistB;
   
  uint256 public weiCap;
   
  uint256 public vinciCap;
   
  uint256 public minimalContribution;
   
  uint256 public maximalIndividualContribution;
   
  uint256 public gasPriceLimit = 50000000000 wei;
   
  address public tokenWallet;
   
  address public lockedTokensWallet;
   
  IDAVToken public davToken;
   
  uint256 public vinciSold;
   
  address public whitelistManager;

  constructor(uint256 _rate, address _wallet, address _tokenWallet, address _lockedTokensWallet, IDAVToken _token, uint256 _weiCap, uint256 _vinciCap, uint256 _minimalContribution, uint256 _maximalIndividualContribution, uint256 _openingTime, uint256 _openingTimeB, uint256 _closingTime) public
    Crowdsale(_rate, _wallet, _token)
    TimedCrowdsale(_openingTime, _closingTime)
  {
    require(_openingTimeB >= _openingTime);
    require(_openingTimeB <= _closingTime);
    require(_weiCap > 0);
    require(_vinciCap > 0);
    require(_minimalContribution > 0);
    require(_maximalIndividualContribution > 0);
    require(_minimalContribution <= _maximalIndividualContribution);
    require(_tokenWallet != address(0));
    require(_lockedTokensWallet != address(0));
    weiCap = _weiCap;
    vinciCap = _vinciCap;
    minimalContribution = _minimalContribution;
    maximalIndividualContribution = _maximalIndividualContribution;
    openingTimeB = _openingTimeB;
    tokenWallet = _tokenWallet;
    lockedTokensWallet= _lockedTokensWallet;
    davToken = _token;
    whitelistManager = msg.sender;
  }

   
  modifier onlyWhitelisted(address _beneficiary) {
    require(whitelistA[_beneficiary] || (whitelistB[_beneficiary] && block.timestamp >= openingTimeB));
    _;
  }

   
  modifier onlyWhitelistManager() {
    require(msg.sender == whitelistManager);
    _;
  }

   
  function setWhitelistManager(address _whitelistManager) external onlyOwner {
    require(_whitelistManager != address(0));
    whitelistManager= _whitelistManager;
  }

   
  function setGasPriceLimit(uint256 _gasPriceLimit) external onlyOwner {
    gasPriceLimit = _gasPriceLimit;
  }

   
  function addUsersWhitelistA(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistA[_beneficiaries[i]] = true;
    }
  }

   
  function addUsersWhitelistB(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistB[_beneficiaries[i]] = true;
    }
  }

   
  function removeUsersWhitelistA(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistA[_beneficiaries[i]] = false;
    }
  }

   
  function removeUsersWhitelistB(address[] _beneficiaries) external onlyWhitelistManager {
    for (uint256 i = 0; i < _beneficiaries.length; i++) {
      whitelistB[_beneficiaries[i]] = false;
    }
  }

   
  function closeEarly(uint256 _closingTime) external onlyOwner onlyWhileOpen {
     
    require(_closingTime <= closingTime);
     
    if (_closingTime < block.timestamp) {
       
      closingTime = block.timestamp;
    } else {
       
      closingTime = _closingTime;
    }
  }

   
  function recordSale(uint256 _weiAmount, uint256 _vinciAmount) external onlyOwner {
     
    require(weiRaised.add(_weiAmount) <= weiCap);
     
    require(vinciSold.add(_vinciAmount) <= vinciCap);
     
    require(!isFinalized);
     
    weiRaised = weiRaised.add(_weiAmount);
    vinciSold = vinciSold.add(_vinciAmount);
     
    token.transfer(lockedTokensWallet, _vinciAmount);
  }

  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal onlyWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
     
    require(weiRaised.add(_weiAmount) <= weiCap);
     
    require(vinciSold.add(_weiAmount.mul(rate)) <= vinciCap);
     
    require(_weiAmount >= minimalContribution);
     
    require(tx.gasprice <= gasPriceLimit);
     
    require(contributions[_beneficiary].add(_weiAmount) <= maximalIndividualContribution);
  }

  function _updatePurchasingState(address _beneficiary, uint256 _weiAmount) internal {
    super._updatePurchasingState(_beneficiary, _weiAmount);
     
    contributions[_beneficiary] = contributions[_beneficiary].add(_weiAmount);
     
    vinciSold = vinciSold.add(_weiAmount.mul(rate));
  }

  function finalization() internal {
    super.finalization();
     
    uint256 foundationTokens = weiRaised.div(2).add(weiRaised);
    foundationTokens = foundationTokens.mul(rate);
    uint256 crowdsaleBalance = davToken.balanceOf(this);
    if (crowdsaleBalance < foundationTokens) {
      foundationTokens = crowdsaleBalance;
    }
    davToken.transfer(tokenWallet, foundationTokens);
     
    crowdsaleBalance = davToken.balanceOf(this);
    davToken.burn(crowdsaleBalance);
     
    davToken.setPauseCutoffTime(closingTime.add(1814400));
     
    davToken.transferOwnership(owner);
  }

}