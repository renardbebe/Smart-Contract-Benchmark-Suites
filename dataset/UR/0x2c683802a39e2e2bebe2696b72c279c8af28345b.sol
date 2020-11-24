 

pragma solidity 0.4.25;

contract TokenConfig {
  string public constant NAME = "MANGO";
  string public constant SYMBOL = "MANG";
  uint8 public constant DECIMALS = 5;
  uint public constant DECIMALSFACTOR = 10 ** uint(DECIMALS);
  uint public constant TOTALSUPPLY = 10000000000 * DECIMALSFACTOR;
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

 
library SafeMath {
   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b, "can't mul");

    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    require(b > 0, "can't sub with zero.");

    uint256 c = a / b;
     

    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a, "can't sub");
    uint256 c = a - b;

    return c;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a, "add overflow");

    return c;
  }

   
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0, "can't mod with zero");
    return a % b;
  }
}

library SafeERC20 {
  using SafeMath for uint256;

  function safeTransfer(IERC20 token, address to, uint256 value) internal {
    require(token.transfer(to, value), "safeTransfer");
  }

  function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
    require(token.transferFrom(from, to, value), "safeTransferFrom");
  }

  function safeApprove(IERC20 token, address spender, uint256 value) internal {
     
     
     
    require((value == 0) || (token.allowance(msg.sender, spender) == 0), "safeApprove");
    require(token.approve(spender, value), "safeApprove");
  }

  function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).add(value);
    require(token.approve(spender, newAllowance), "safeIncreaseAllowance");
  }

  function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
    uint256 newAllowance = token.allowance(address(this), spender).sub(value);
    require(token.approve(spender, newAllowance), "safeDecreaseAllowance");
  }
}

 
contract ReentrancyGuard {
   
  uint256 private _guardCounter;

  constructor () internal {
     
     
    _guardCounter = 1;
  }

   
  modifier nonReentrant() {
    _guardCounter += 1;
    uint256 localCounter = _guardCounter;
    _;
    require(localCounter == _guardCounter, "nonReentrant.");
  }
}

 
contract Ownable {
  address public owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner, "only for owner.");
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0), "address is zero.");
    owner = newOwner;
    emit OwnershipTransferred(owner, newOwner);
  }
}

 
contract Pausable is Ownable {
  event Paused(address account);
  event Unpaused(address account);

  bool private _paused;

  constructor() internal {
    _paused = false;
  }

   
  function paused() public view returns(bool) {
    return _paused;
  }

   
  modifier whenNotPaused() {
    require(!_paused, "paused.");
    _;
  }

   
  modifier whenPaused() {
    require(_paused, "Not paused.");
    _;
  }

   
  function pause() public onlyOwner whenNotPaused {
    _paused = true;
    emit Paused(msg.sender);
  }

   
  function unpause() public onlyOwner whenPaused {
    _paused = false;
    emit Unpaused(msg.sender);
  }
}

 
contract Whitelist is Ownable {
  event WhitelistAdded(address addr);
  event WhitelistRemoved(address addr);

  mapping (address => bool) private _whitelist;

   
  function addWhiteListAddr(address[] addrs)
    public
  {
    uint256 len = addrs.length;
    for (uint256 i = 0; i < len; i++) {
      _addAddressToWhitelist(addrs[i]);
    }
  }

   
  function removeWhiteListAddr(address addr)
    public
  {
    _removeAddressToWhitelist(addr);
  }

   
  function isWhiteListAddr(address addr)
    public
    view
    returns (bool)
  {
    require(addr != address(0), "address is zero");
    return _whitelist[addr];
  }

  modifier onlyAuthorised(address beneficiary) {
    require(isWhiteListAddr(beneficiary),"Not authorised");
    _;
  }

   
  function _addAddressToWhitelist(address addr)
    internal
    onlyOwner
  {
    require(addr != address(0), "address is zero");
    _whitelist[addr] = true;
    emit WhitelistAdded(addr);
  }

     
  function _removeAddressToWhitelist(address addr)
    internal
    onlyOwner
  {
    require(addr != address(0), "address is zero");
    _whitelist[addr] = false;
    emit WhitelistRemoved(addr);
  }
}

 
contract Crowdsale is TokenConfig, Pausable, ReentrancyGuard, Whitelist {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

   
  IERC20 private _token;

   
  address private _wallet;

   
  address private _tokenholder;

   
   
   
   
  uint256 private _rate;

   
  uint256 private _weiRaised;

   
  uint256 private _tokenSoldAmount;

   
  uint256 private _minWeiAmount;

   
  mapping (address => uint256) private _tokenBalances;

   
  mapping (address => uint256) private _weiBalances;

   
  uint256 private _openingTime;
  uint256 private _closingTime;

   
  uint256 private _hardcap;

   
  event TokensPurchased(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );
  event TokensDelivered(address indexed beneficiary, uint256 amount);
  event RateChanged(uint256 rate);
  event MinWeiChanged(uint256 minWei);
  event PeriodChanged(uint256 open, uint256 close);
  event HardcapChanged(uint256 hardcap);

  constructor(
    uint256 rate,
    uint256 minWeiAmount,
    address wallet,
    address tokenholder,
    IERC20 token,
    uint256 hardcap,
    uint256 openingTime,
    uint256 closingTime
  ) public {
    require(rate > 0, "Rate is lower than zero.");
    require(wallet != address(0), "Wallet address is zero");
    require(tokenholder != address(0), "Tokenholder address is zero");
    require(token != address(0), "Token address is zero");

    _rate = rate;
    _minWeiAmount = minWeiAmount;
    _wallet = wallet;
    _tokenholder = tokenholder;
    _token = token;
    _hardcap = hardcap;
    _openingTime = openingTime;
    _closingTime = closingTime;
  }

   
   
   

   
  function () external payable {
    buyTokens(msg.sender);
  }

   
  function token() public view returns(IERC20) {
    return _token;
  }

   
  function hardcap() public view returns(uint256) {
    return _hardcap;
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

   
  function openingTime() public view returns (uint256) {
    return _openingTime;
  }

   
  function closingTime() public view returns (uint256) {
    return _closingTime;
  }

   
  function tokenSoldAmount() public view returns (uint256) {
    return _tokenSoldAmount;
  }

   
  function minWeiAmount() public view returns(uint256) {
    return _minWeiAmount;
  }

   
  function isOpen() public view returns (bool) {
      
    return now >= _openingTime && now <= _closingTime;
  }

   
  function tokenBalanceOf(address owner) public view returns (uint256) {
    return _tokenBalances[owner];
  }

   
  function weiBalanceOf(address owner) public view returns (uint256) {
    return _weiBalances[owner];
  }

  function setRate(uint256 value) public onlyOwner {
    _rate = value;
    emit RateChanged(value);
  }

  function setMinWeiAmount(uint256 value) public onlyOwner {
    _minWeiAmount = value;
    emit MinWeiChanged(value);
  }

  function setPeriodTimestamp(uint256 open, uint256 close)
    public
    onlyOwner
  {
    _openingTime = open;
    _closingTime = close;
    emit PeriodChanged(open, close);
  }

  function setHardcap(uint256 value) public onlyOwner {
    _hardcap = value;
    emit HardcapChanged(value);
  }

   
  function buyTokens(address beneficiary)
    public
    nonReentrant
    whenNotPaused
    payable
  {
    uint256 weiAmount = msg.value;
    _preValidatePurchase(beneficiary, weiAmount);

     
    uint256 tokens = _getTokenAmount(weiAmount);

    require(_hardcap > _tokenSoldAmount.add(tokens), "Over hardcap");

     
    _weiRaised = _weiRaised.add(weiAmount);
    _tokenSoldAmount = _tokenSoldAmount.add(tokens);

    _weiBalances[beneficiary] = _weiBalances[beneficiary].add(weiAmount);
    _tokenBalances[beneficiary] = _tokenBalances[beneficiary].add(tokens);

    emit TokensPurchased(
      msg.sender,
      beneficiary,
      weiAmount,
      tokens
    );

    _forwardFunds();
  }

   
  function deliverTokens(address[] users)
    public
    whenNotPaused
    onlyOwner
  {
    uint256 len = users.length;
    for (uint256 i = 0; i < len; i++) {
      address user = users[i];
      uint256 tokenAmount = _tokenBalances[user];
      _deliverTokens(user, tokenAmount);
      _tokenBalances[user] = 0;

      emit TokensDelivered(user, tokenAmount);
    }
  }

   
   
   

   
  function _preValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
    internal
    view
    onlyAuthorised(beneficiary)
  {
    require(weiAmount != 0, "Zero ETH");
    require(weiAmount >= _minWeiAmount, "Must be equal or higher than minimum");
    require(beneficiary != address(0), "Beneficiary address is zero");
    require(isOpen(), "Sales is close");
  }

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
    internal
  {
    _token.safeTransferFrom(_tokenholder, beneficiary, tokenAmount);
  }

   
  function _getTokenAmount(uint256 weiAmount) internal view returns (uint256)
  {
    uint ethDecimals = 18;
    require(DECIMALS <= ethDecimals, "");

    uint256 covertedTokens = weiAmount;
    if (DECIMALS != ethDecimals) {
      covertedTokens = weiAmount.div((10 ** uint256(ethDecimals - DECIMALS)));
    }
    return covertedTokens.mul(_rate);
  }

   
  function _forwardFunds() internal {
    _wallet.transfer(msg.value);
  }
}