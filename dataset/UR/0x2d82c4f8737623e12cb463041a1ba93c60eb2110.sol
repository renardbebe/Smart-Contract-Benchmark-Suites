 

 
pragma solidity ^0.4.22;




 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0);  
    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}








 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}







 
library SafeERC20 {

  using SafeMath for uint256;

  function safeTransfer(
    IERC20 token,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transfer(to, value));
  }

  function safeTransferFrom(
    IERC20 token,
    address from,
    address to,
    uint256 value
  )
    internal
  {
    require(token.transferFrom(from, to, value));
  }

  function safeApprove(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0));
    require(token.approve(spender, value));
  }

  function safeIncreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance));
  }

  function safeDecreaseAllowance(
    IERC20 token,
    address spender,
    uint256 value
  )
    internal
  {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance));
  }
}



 
contract ReentrancyGuard {

   
  uint256 private _guardCounter;

  constructor() internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter);
  }

}


 
contract Crowdsale is ReentrancyGuard {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

   
  IERC20 private _token;

   
  address private _wallet;

   
   
   
   
  uint256 private _rate;

   
  uint256 private _weiRaised;

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

   
  constructor(uint256 rate, address wallet, IERC20 token) internal {
    require(rate > 0);
    require(wallet != address(0));
    require(token != address(0));

    _rate = rate;
    _wallet = wallet;
    _token = token;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function token() public view returns(IERC20) {
    return _token;
  }

   
  function wallet() public view returns(address) {
    return _wallet;
  }

   
  function rate() public view returns(uint256) {
    return _rate;
  }

   
  function weiRaised() public view returns (uint256) {
    return _weiRaised;
  }

   
  function buyTokens(address beneficiary) public nonReentrant payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

     
    _weiRaised = _weiRaised.add(weiAmount);

    _processPurchase(beneficiary, tokens);
    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(beneficiary, weiAmount);
  }

   
   
   

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
     
  }

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransfer(beneficiary, tokenAmount);
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _deliverTokens(beneficiary, tokenAmount);
  }

   
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
     
  }

   
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return weiAmount.mul(_rate);
  }

   
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}


 
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _openingTime;
  uint256 private _closingTime;

   
  modifier onlyWhileOpen {
    require(isOpen());
    _;
  }

   
  constructor(uint256 openingTime, uint256 closingTime) internal {
     
    require(openingTime >= block.timestamp);
    require(closingTime > openingTime);

    _openingTime = openingTime;
    _closingTime = closingTime;
  }

   
  function openingTime() public view returns(uint256) {
    return _openingTime;
  }

   
  function closingTime() public view returns(uint256) {
    return _closingTime;
  }

   
  function isOpen() public view returns (bool) {
     
    return block.timestamp >= _openingTime && block.timestamp <= _closingTime;
  }

   
  function hasClosed() public view returns (bool) {
     
    return block.timestamp > _closingTime;
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyWhileOpen
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}


 
contract FinalizableCrowdsale is TimedCrowdsale {
  using SafeMath for uint256;

  bool private _finalized;

  event CrowdsaleFinalized();

  constructor() internal {
    _finalized = false;
  }

   
  function finalized() public view returns (bool) {
    return _finalized;
  }

   
  function finalize() public {
    require(!_finalized);
    require(hasClosed());

    _finalized = true;

    _finalization();
    emit CrowdsaleFinalized();
  }

   
  function _finalization() internal {
  }
}






 
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 private _cap;

   
  constructor(uint256 cap) internal {
    require(cap > 0);
    _cap = cap;
  }

   
  function cap() public view returns(uint256) {
    return _cap;
  }

   
  function capReached() public view returns (bool) {
    return weiRaised() >= _cap;
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
    require(weiRaised().add(weiAmount) <= _cap);
  }

}


 


 



 





 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() internal {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

   
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

   
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

   
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



 
contract CustomAdmin is Ownable {
   
  mapping(address => bool) public admins;

  event AdminAdded(address indexed _address);
  event AdminRemoved(address indexed _address);

   
  modifier onlyAdmin() {
    require(isAdmin(msg.sender), "Access is denied.");
    _;
  }

   
   
  function addAdmin(address _address) external onlyAdmin returns(bool) {
    require(_address != address(0), "Invalid address.");
    require(!admins[_address], "This address is already an administrator.");

    require(_address != owner(), "The owner cannot be added or removed to or from the administrator list.");

    admins[_address] = true;

    emit AdminAdded(_address);
    return true;
  }

   
   
  function addManyAdmins(address[] _accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && !admins[account] && account != owner()) {
        admins[account] = true;

        emit AdminAdded(_accounts[i]);
      }
    }

    return true;
  }

   
   
  function removeAdmin(address _address) external onlyAdmin returns(bool) {
    require(_address != address(0), "Invalid address.");
    require(admins[_address], "This address isn't an administrator.");

     
    require(_address != owner(), "The owner cannot be added or removed to or from the administrator list.");

    admins[_address] = false;
    emit AdminRemoved(_address);
    return true;
  }

   
   
  function removeManyAdmins(address[] _accounts) external onlyAdmin returns(bool) {
    for(uint8 i = 0; i < _accounts.length; i++) {
      address account = _accounts[i];

       
       
       
      if(account != address(0) && admins[account] && account != owner()) {
        admins[account] = false;

        emit AdminRemoved(_accounts[i]);
      }
    }

    return true;
  }

   
  function isAdmin(address _address) public view returns(bool) {
    if(_address == owner()) {
      return true;
    }

    return admins[_address];
  }
}



 
contract CustomPausable is CustomAdmin {
  event Paused();
  event Unpaused();

  bool public paused = false;

   
  modifier whenNotPaused() {
    require(!paused, "Sorry but the contract isn't paused.");
    _;
  }

   
  modifier whenPaused() {
    require(paused, "Sorry but the contract is paused.");
    _;
  }

   
  function pause() external onlyAdmin whenNotPaused {
    paused = true;
    emit Paused();
  }

   
  function unpause() external onlyAdmin whenPaused {
    paused = false;
    emit Unpaused();
  }
}


 
contract CustomWhitelist is CustomPausable {
  mapping(address => bool) public whitelist;

  event WhitelistAdded(address indexed _account);
  event WhitelistRemoved(address indexed _account);

   
  modifier ifWhitelisted(address _account) {
    require(_account != address(0), "Account cannot be zero address");
    require(isWhitelisted(_account), "Account is not whitelisted");

    _;
  }

   
   
  function addWhitelist(address _account) external whenNotPaused onlyAdmin returns(bool) {
    require(_account != address(0), "Account cannot be zero address");

    if(!whitelist[_account]) {
      whitelist[_account] = true;

      emit WhitelistAdded(_account);
    }

    return true;
  }

   
   
  function addManyWhitelist(address[] _accounts) external whenNotPaused onlyAdmin returns(bool) {
    for(uint8 i = 0;i < _accounts.length;i++) {
      if(_accounts[i] != address(0) && !whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = true;

        emit WhitelistAdded(_accounts[i]);
      }
    }

    return true;
  }

   
   
  function removeWhitelist(address _account) external whenNotPaused onlyAdmin returns(bool) {
    require(_account != address(0), "Account cannot be zero address");
    if(whitelist[_account]) {
      whitelist[_account] = false;
      emit WhitelistRemoved(_account);
    }

    return true;
  }

   
   
  function removeManyWhitelist(address[] _accounts) external whenNotPaused onlyAdmin returns(bool) {
    for(uint8 i = 0;i < _accounts.length;i++) {
      if(_accounts[i] != address(0) && whitelist[_accounts[i]]) {
        whitelist[_accounts[i]] = false;

        emit WhitelistRemoved(_accounts[i]);
      }
    }
    
    return true;
  }

   
  function isWhitelisted(address _address) public view returns(bool) {
    return whitelist[_address];
  }
}



 
contract TokenSale is CappedCrowdsale, FinalizableCrowdsale, CustomWhitelist {
  event FundsWithdrawn(address indexed _wallet, uint256 _amount);
  event BonusChanged(uint256 _newBonus, uint256 _oldBonus);
  event RateChanged(uint256 _rate, uint256 _oldRate);

  uint256 public bonus;
  uint256 public rate;

  constructor(uint256 _openingTime,
    uint256 _closingTime,
    uint256 _rate,
    address _wallet,
    IERC20 _token,
    uint256 _bonus,
    uint256 _cap)
  public 
  TimedCrowdsale(_openingTime, _closingTime) 
  CappedCrowdsale(_cap) 
  Crowdsale(_rate, _wallet, _token) {
    require(_bonus > 0, "Bonus must be greater than 0");
    bonus = _bonus;
    rate = _rate;
  }

   
   
  function withdrawFunds(uint256 _amount) external whenNotPaused onlyAdmin {
    require(_amount <= address(this).balance, "The amount should be less than the balance/");
    msg.sender.transfer(_amount);
    emit FundsWithdrawn(msg.sender, _amount);
  }

   
  function withdrawTokens() external whenNotPaused onlyAdmin {
    IERC20 t = super.token();
    t.safeTransfer(msg.sender, t.balanceOf(this));
  }

   
  function withdrawERC20(address _token) external whenNotPaused onlyAdmin {
    IERC20 erc20 = IERC20(_token);
    uint256 balance = erc20.balanceOf(this);

    erc20.safeTransfer(msg.sender, balance);
  }

   
   
  function changeBonus(uint256 _bonus) external whenNotPaused onlyAdmin {
    require(_bonus > 0, "Bonus must be greater than 0");
    emit BonusChanged(_bonus, bonus);
    bonus = _bonus;
  }

   
   
  function changeRate(uint256 _rate) external whenNotPaused onlyAdmin {
    require(_rate > 0, "Rate must be greater than 0");
    emit RateChanged(_rate, rate);
    rate = _rate;
  }

   
  function hasClosed() public view returns (bool) {
    return super.hasClosed() || super.capReached();
  }

   
   
   
  function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) 
  internal view whenNotPaused ifWhitelisted(_beneficiary) {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

   
   
  function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
    uint256 tokenAmount = _weiAmount.mul(rate);
    uint256 bonusTokens = tokenAmount.mul(bonus).div(100);
    return tokenAmount.add(bonusTokens);
  }

   
   
  function _forwardFunds() internal {
     
  }
}