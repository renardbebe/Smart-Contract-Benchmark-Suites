 

 

pragma solidity ^0.4.24;

 
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
   
  function _mint(address account, uint256 value) internal;
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

contract MinterRole {
  using Roles for Roles.Role;

  event MinterAdded(address indexed account);
  event MinterRemoved(address indexed account);

  Roles.Role private minters;

  constructor() internal {
    _addMinter(msg.sender);
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender));
    _;
  }

  function isMinter(address account) public view returns (bool) {
    return minters.has(account);
  }

  function addMinter(address account) public onlyMinter {
    _addMinter(account);
  }

  function renounceMinter() public {
    _removeMinter(msg.sender);
  }

  function _addMinter(address account) internal {
    minters.add(account);
    emit MinterAdded(account);
  }

  function _removeMinter(address account) internal {
    minters.remove(account);
    emit MinterRemoved(account);
  }
}

 
contract ERC20Mintable is ERC20, MinterRole {
  
   
  function mint(
    address to,
    uint256 value
  )
    public
    onlyMinter
    returns (bool)
  {
    _mint(to, value);
    return true;
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

 
contract IncreasingPriceTCO is Crowdsale {
    using SafeMath for uint256;

    uint256[2][] private _rates;  
    uint8 private _currentRateIndex;  

    event NewRateIsSet(
    uint8 rateIndex,
    uint256 exRate,
    uint256 weiRaisedRange,
    uint256 weiRaised
  );
   
  constructor(uint256[2][] memory initRates) internal {
    require(initRates.length > 1, 'Rates array should contain more then one value');
    _rates = initRates;
    _currentRateIndex = 0;
  }
 
  function getCurrentRate() public view returns(uint256) {
    return _rates[_currentRateIndex][1];
  }

  modifier ifExRateNeedsUpdate {
    if(weiRaised() >= _rates[_currentRateIndex][0] && _currentRateIndex < _rates.length - 1)
      _;
  }

   
  function _updateCurrentRate() internal ifExRateNeedsUpdate {
    uint256 _weiRaised = weiRaised();
    _currentRateIndex++;  
    while(_currentRateIndex < _rates.length - 1 && _rates[_currentRateIndex][0] <= _weiRaised) {
      _currentRateIndex++;
    }
    emit NewRateIsSet(_currentRateIndex,  
                      _rates[_currentRateIndex][1],  
                      _rates[_currentRateIndex][0],  
                      _weiRaised);  
  }

   
  function rate() public view returns(uint256) {
    revert();
  }
  
   
  function _getTokenAmount(uint256 weiAmount)
    internal view returns (uint256)
  {
    return getCurrentRate().mul(weiAmount);
  }

   
  function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal
  {
    _updateCurrentRate();
  }
}

contract KeeperRole {
  using Roles for Roles.Role;

  event KeeperAdded(address indexed account);
  event KeeperRemoved(address indexed account);

  Roles.Role private keepers;

  constructor() internal {
    _addKeeper(msg.sender);
  }

  modifier onlyKeeper() {
    require(isKeeper(msg.sender), 'Only Keeper is allowed');
    _;
  }

  function isKeeper(address account) public view returns (bool) {
    return keepers.has(account);
  }

  function addKeeper(address account) public onlyKeeper {
    _addKeeper(account);
  }

  function renounceKeeper() public {
    _removeKeeper(msg.sender);
  }

  function _addKeeper(address account) internal {
    keepers.add(account);
    emit KeeperAdded(account);
  }

  function _removeKeeper(address account) internal {
    keepers.remove(account);
    emit KeeperRemoved(account);
  }
}

contract PauserRole {
  using Roles for Roles.Role;

  event PauserAdded(address indexed account);
  event PauserRemoved(address indexed account);

  Roles.Role private pausers;

  constructor() internal {
    _addPauser(msg.sender);
  }

  modifier onlyPauser() {
    require(isPauser(msg.sender));
    _;
  }

  function isPauser(address account) public view returns (bool) {
    return pausers.has(account);
  }

  function addPauser(address account) public onlyPauser {
    _addPauser(account);
  }

  function renouncePauser() public {
    _removePauser(msg.sender);
  }

  function _addPauser(address account) internal {
    pausers.add(account);
    emit PauserAdded(account);
  }

  function _removePauser(address account) internal {
    pausers.remove(account);
    emit PauserRemoved(account);
  }
}

 
contract Haltable is KeeperRole, PauserRole {
  event Paused(address account);
  event Unpaused(address account);
  event Closed(address account);

  bool private _paused;
  bool private _closed;

  constructor() internal {
    _paused = false;
    _closed = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  function isClosed() public view returns(bool) {
    return _closed;
  }

   
  function notClosed() public view returns(bool) {
    return !_closed;
  }

   
  modifier whenNotPaused() {
    require(!_paused, 'The contract is paused');
    _;
  }

   
  modifier whenPaused() {
    require(_paused, 'The contract is not paused');
    _;
  }

   
  modifier whenClosed(bool orCondition) {
    require(_closed, 'The contract is not closed');
    _;
  }

   
  modifier whenClosedOr(bool orCondition) {
    require(_closed || orCondition, "It must be closed or what is set in 'orCondition'");
    _;
  }

   
  modifier whenNotClosed() {
    require(!_closed, "Reverted because it is closed");
    _;
  }

   
  function pause() public onlyPauser whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyPauser whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }

   
  function close() internal whenNotClosed {
    _closed = true;
    emit Closed(msg.sender);
  }
}

 
contract CappedTCO is Crowdsale {
  using SafeMath for uint256;
  uint256 private _cap;
  
   
  constructor(uint256 cap) internal {
      require(cap > 0, 'Hard cap must be > 0');
      _cap = cap;
  }
  
   
  function cap() public view returns(uint256) {
      return _cap;
  }
  
   
  function capNotReached() public view returns (bool) {
      return weiRaised() < _cap;
  }
  
   
  function capReached() public view returns (bool) {
      return weiRaised() >= _cap;
  }
}

 
contract PostDeliveryCappedTCO is CappedTCO, Haltable {
  using SafeMath for uint256;

  mapping(address => uint256) private _balances;  

  uint256 private _totalSupply;  

  event TokensWithdrawn(
    address indexed beneficiary,
    uint256 amount
  );

  constructor() internal {}

   
  function withdrawTokensFrom(address beneficiary) public whenNotPaused whenClosedOr(capReached()) {
    uint256 amount = _balances[beneficiary];
    require(amount > 0, 'The balance should be positive for withdrawal. Please check the balance in the token contract.');
    _balances[beneficiary] = 0;
    _deliverTokens(beneficiary, amount);
    emit TokensWithdrawn(beneficiary, amount);
  }

   
  function withdrawTokens() public {
    withdrawTokensFrom(address(msg.sender));
  }

   
  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }

   
  function balanceOf(address account) public view returns(uint256) {
    return _balances[account];
  }

   
  function _preValidatePurchase(
      address beneficiary,
      uint256 weiAmount
  )
      internal
      view
  {
      require(capNotReached(),"Hardcap is reached.");
      require(notClosed(), "TCO is finished, sorry.");
      super._preValidatePurchase(beneficiary, weiAmount);
  }

   
  function _processPurchase(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _balances[beneficiary] = _balances[beneficiary].add(tokenAmount);
    _totalSupply = _totalSupply.add(tokenAmount);
  }
}

 
contract GutTCO is 
PostDeliveryCappedTCO, 
IncreasingPriceTCO, 
MinterRole
{
    bool private _finalized;

    event CrowdsaleFinalized();

    constructor(
    uint256 _rate,
    address _wallet,
    uint256 _cap,
    ERC20Mintable _token
  ) public 
  Crowdsale(_rate, _wallet, _token)
  CappedTCO(_cap)
  IncreasingPriceTCO(initRates())
  {
    _finalized = false;
  }

   
  function initRates() internal pure returns(uint256[2][] memory ratesArray) {
     ratesArray = new uint256[2][](4);
     ratesArray[0] = [uint256(100000 ether), 3000];  
     ratesArray[1] = [uint256(300000 ether), 1500];  
     ratesArray[2] = [uint256(700000 ether), 500];   
     ratesArray[3] = [uint256(1500000 ether), 125];  
  }

  function closeTCO() public onlyMinter {
     if(notFinalized()) _finalize();
  }

   
  function finalized() public view returns (bool) {
    return _finalized;
  }

   
  function notFinalized() public view returns (bool) {
    return !finalized();
  }

   
  function _finalize() private {
    require(notFinalized(), 'TCO already finalized');
    if(notClosed()) close();
    _finalization();
    emit CrowdsaleFinalized();
  }

  function _finalization() private {
     if(totalSupply() > 0)
        require(ERC20Mintable(address(token())).mint(address(this), totalSupply()), 'Error when being finalized at minting totalSupply() to the token');
     _finalized = true;
  }

   
  function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal 
  {
    super._updatePurchasingState(beneficiary, weiAmount);
    if(capReached()) _finalize();
  }
}