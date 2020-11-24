 

pragma solidity ^0.4.25;

 

 
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

 

 
contract ERC20 is IERC20 {
  using SafeMath for uint256;

  mapping (address => uint256) private _balances;

  mapping (address => mapping (address => uint256)) private _allowed;

  uint256 private _totalSupply;

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }

   
  function allowance(
    address owner,
    address spender
   )
    public
    view
    returns (uint256)
  {
    return _allowed[owner][spender];
  }

   
  function transfer(address to, uint256 value) public returns (bool) {
    _transfer(msg.sender, to, value);
    return true;
  }

   
  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));

    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }

   
  function transferFrom(
    address from,
    address to,
    uint256 value
  )
    public
    returns (bool)
  {
    require(value <= _allowed[from][msg.sender]);

    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
    _transfer(from, to, value);
    return true;
  }

   
  function increaseAllowance(
    address spender,
    uint256 addedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function decreaseAllowance(
    address spender,
    uint256 subtractedValue
  )
    public
    returns (bool)
  {
    require(spender != address(0));

    _allowed[msg.sender][spender] = (
      _allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }

   
  function _transfer(address from, address to, uint256 value) internal {
    require(value <= _balances[from]);
    require(to != address(0));

    _balances[from] = _balances[from].sub(value);
    _balances[to] = _balances[to].add(value);
    emit Transfer(from, to, value);
  }

   
  function _mint(address account, uint256 value) internal {
    require(account != 0);
    _totalSupply = _totalSupply.add(value);
    _balances[account] = _balances[account].add(value);
    emit Transfer(address(0), account, value);
  }

   
  function _burn(address account, uint256 value) internal {
    require(account != 0);
    require(value <= _balances[account]);

    _totalSupply = _totalSupply.sub(value);
    _balances[account] = _balances[account].sub(value);
    emit Transfer(account, address(0), value);
  }

   
  function _burnFrom(address account, uint256 value) internal {
    require(value <= _allowed[account][msg.sender]);

     
     
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(
      value);
    _burn(account, value);
  }
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
     
     
     
    require((value == 0) || (token.allowance(address(this), spender) == 0));
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

 

 
contract TokenRecover is Ownable {

   
  function recoverERC20(
    address tokenAddress,
    uint256 tokenAmount
  )
    public
    onlyOwner
  {
    IERC20(tokenAddress).transfer(owner(), tokenAmount);
  }
}

 

 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    require(!has(role, account));

    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
    require(has(role, account));

    role.bearer[account] = false;
  }

   
  function has(Role storage role, address account)
    internal
    view
    returns (bool)
  {
    require(account != address(0));
    return role.bearer[account];
  }
}

 

contract OperatorRole {
  using Roles for Roles.Role;

  event OperatorAdded(address indexed account);
  event OperatorRemoved(address indexed account);

  Roles.Role private _operators;

  constructor() internal {
    _addOperator(msg.sender);
  }

  modifier onlyOperator() {
    require(isOperator(msg.sender));
    _;
  }

  function isOperator(address account) public view returns (bool) {
    return _operators.has(account);
  }

  function addOperator(address account) public onlyOperator {
    _addOperator(account);
  }

  function renounceOperator() public {
    _removeOperator(msg.sender);
  }

  function _addOperator(address account) internal {
    _operators.add(account);
    emit OperatorAdded(account);
  }

  function _removeOperator(address account) internal {
    _operators.remove(account);
    emit OperatorRemoved(account);
  }
}

 

 
contract Contributions is OperatorRole, TokenRecover {

  using SafeMath for uint256;

  struct Contributor {
    uint256 weiAmount;
    uint256 tokenAmount;
    bool exists;
  }

   
  uint256 private _totalSoldTokens;

   
  uint256 private _totalWeiRaised;

   
  address[] private _addresses;

   
  mapping(address => Contributor) private _contributors;

  constructor() public {}

   
  function totalSoldTokens() public view returns(uint256) {
    return _totalSoldTokens;
  }

   
  function totalWeiRaised() public view returns(uint256) {
    return _totalWeiRaised;
  }

   
  function getContributorAddress(uint256 index) public view returns(address) {
    return _addresses[index];
  }

   
  function getContributorsLength() public view returns (uint) {
    return _addresses.length;
  }

   
  function weiContribution(address account) public view returns (uint256) {
    return _contributors[account].weiAmount;
  }

   
  function tokenBalance(address account) public view returns (uint256) {
    return _contributors[account].tokenAmount;
  }

   
  function contributorExists(address account) public view returns (bool) {
    return _contributors[account].exists;
  }

   
  function addBalance(
    address account,
    uint256 weiAmount,
    uint256 tokenAmount
  )
    public
    onlyOperator
  {
    if (!_contributors[account].exists) {
      _addresses.push(account);
      _contributors[account].exists = true;
    }

    _contributors[account].weiAmount = _contributors[account].weiAmount.add(weiAmount);
    _contributors[account].tokenAmount = _contributors[account].tokenAmount.add(tokenAmount);

    _totalWeiRaised = _totalWeiRaised.add(weiAmount);
    _totalSoldTokens = _totalSoldTokens.add(tokenAmount);
  }

   
  function removeOperator(address account) public onlyOwner {
    _removeOperator(account);
  }
}

 

 
contract BaseCrowdsale is TimedCrowdsale, CappedCrowdsale, TokenRecover {

   
  Contributions private _contributions;

   
  uint256 private _minimumContribution;

   
  modifier onlyGreaterThanMinimum(uint256 weiAmount) {
    require(weiAmount >= _minimumContribution);
    _;
  }

   
  constructor(
    uint256 openingTime,
    uint256 closingTime,
    uint256 rate,
    address wallet,
    uint256 cap,
    uint256 minimumContribution,
    address token,
    address contributions
  )
    public
    Crowdsale(rate, wallet, ERC20(token))
    TimedCrowdsale(openingTime, closingTime)
    CappedCrowdsale(cap)
  {
    require(contributions != address(0));
    _contributions = Contributions(contributions);
    _minimumContribution = minimumContribution;
  }

   
  function contributions() public view returns(Contributions) {
    return _contributions;
  }

   
  function minimumContribution() public view returns(uint256) {
    return _minimumContribution;
  }

   
  function started() public view returns(bool) {
    return block.timestamp >= openingTime();  
  }

   
  function ended() public view returns(bool) {
    return hasClosed() || capReached();
  }

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    onlyGreaterThanMinimum(weiAmount)
    view
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

   
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    super._updatePurchasingState(beneficiary, weiAmount);
    _contributions.addBalance(
      beneficiary,
      weiAmount,
      _getTokenAmount(weiAmount)
    );
  }
}

 

 
contract ForkTokenSale is BaseCrowdsale {

  uint256 private _currentRate;

  uint256 private _soldTokens;

  constructor(
    uint256 openingTime,
    uint256 closingTime,
    uint256 rate,
    address wallet,
    uint256 cap,
    uint256 minimumContribution,
    address token,
    address contributions
  )
    public
    BaseCrowdsale(
      openingTime,
      closingTime,
      rate,
      wallet,
      cap,
      minimumContribution,
      token,
      contributions
    )
  {
    _currentRate = rate;
  }

   
  function setRate(uint256 newRate) public onlyOwner {
    require(newRate > 0);
    _currentRate = newRate;
  }

   
  function rate() public view returns(uint256) {
    return _currentRate;
  }

   
  function soldTokens() public view returns(uint256) {
    return _soldTokens;
  }

   
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
    return weiAmount.mul(rate());
  }

   
  function _updatePurchasingState(
    address beneficiary,
    uint256 weiAmount
  )
    internal
  {
    _soldTokens = _soldTokens.add(_getTokenAmount(weiAmount));
    super._updatePurchasingState(beneficiary, weiAmount);
  }
}