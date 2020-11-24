 

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

interface IPickFlixToken {
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

  function closeNow() public;
  function kill() public;
  function rate() public view returns(uint256);
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



 
library Roles {
  struct Role {
    mapping (address => bool) bearer;
  }

   
  function add(Role storage role, address account) internal {
    require(account != address(0));
    role.bearer[account] = true;
  }

   
  function remove(Role storage role, address account) internal {
    require(account != address(0));
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

  constructor(address minter) public {
    if(minter == 0x0) {
      _addMinter(msg.sender);
    } else {
      _addMinter(minter);
    }
  }

  modifier onlyMinter() {
    require(isMinter(msg.sender), "Only minter can do this");
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
    require(token.approve(spender, value));
  }
}



 
contract Crowdsale {
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

   
  constructor(uint256 rate, address wallet, IERC20 token) public {
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

   
  function buyTokens(address beneficiary) public payable {

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
  {
    require(beneficiary != address(0));
    require(weiAmount != 0);
  }

   
  function _postValidatePurchase(
    address beneficiary,
    uint256 weiAmount
  )
  internal
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
  uint256 internal _closingTime;

   
  modifier onlyWhileOpen {
    require(isOpen(), "Crowdsale is no longer open");
    _;
  }

   
  constructor(uint256 openingTime, uint256 closingTime) public {
     
    require(openingTime >= block.timestamp, "The Crowdsale must not start in the past");
    require(closingTime >= openingTime, "The Crowdsale must end in the future");

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
  {
    super._preValidatePurchase(beneficiary, weiAmount);
  }

}



 
contract DeadlineCrowdsale is TimedCrowdsale {
  constructor(uint256 closingTime) public TimedCrowdsale(block.timestamp, closingTime) { }
}



 
contract MintedCrowdsale is Crowdsale {

   
  function _deliverTokens(
    address beneficiary,
    uint256 tokenAmount
  )
  internal
  {
     
    require(
      ERC20Mintable(address(token())).mint(beneficiary, tokenAmount));
  }
}



contract PickFlixToken is ERC20Mintable, DeadlineCrowdsale, MintedCrowdsale {

  string public name = "";
  string public symbol = "";
  string public externalID = "";
  uint public decimals = 18;

  constructor(string _name, string _symbol, uint256 _rate, address _wallet, uint _closeDate, string _externalID)
  public
  Crowdsale(_rate, _wallet, this)
  ERC20Mintable()
  MinterRole(this)
  DeadlineCrowdsale(_closeDate)  {
    externalID = _externalID;
    name = _name;
    symbol = _symbol;
  }

  function closeNow() public {
    require(msg.sender == wallet(), "Must be the creator to close this token");
    _closingTime = block.timestamp - 1;
  }

  function kill() public {
    require(msg.sender == wallet(), "Must be the creator to kill this token");
    require(balanceOf(wallet()) >=  0, "Must have no tokens, or the creator owns all the tokens");
    selfdestruct(wallet());
  }
}



 
contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

   
  constructor() public {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

   
  function owner() public view returns(address) {
    return _owner;
  }

   
  modifier onlyOwner() {
    require(isOwner(), "Must be owner");
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
    require(newOwner != address(0), "Must provide a valid owner address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}



contract PickflixGameMaster is Ownable {
   
  using SafeMath for uint256;

   
  event Sent(address indexed payee, uint256 amount, uint256 balance);
  event Received(address indexed payer, uint256 amount, uint256 balance);

  string public gameName;
  uint public openDate;
  uint public closeDate;
  bool public gameDone;
  
   
   
  mapping (address => uint256) public boxOfficeTotals;

   
  struct Movie {
    uint256 boxOfficeTotal;
    uint256 totalPlayerRewards;
    bool accepted;
  }
   
  mapping (address => Movie) public movies;

   
  uint256 public tokensIssued = 0;  

   
  uint256 public oracleFee = 0;
  uint256 public oracleFeePercent = 0;
  uint256 public totalPlayerRewards = 0;
  uint256 public totalBoxOffice = 0;


   
  constructor(string _gameName, uint _closeDate, uint _oracleFeePercent) Ownable() public {
    gameName = _gameName;
    closeDate = _closeDate;
    openDate = block.timestamp;
    gameDone = false;
    oracleFeePercent = _oracleFeePercent;
  }

   
  function percent(uint numerator, uint denominator, uint precision) private pure returns(uint quotient) {
     
    uint _numerator = (numerator * 10 ** (precision+1));
     
    uint _quotient = ((_numerator / denominator)) / 10;
    return ( _quotient);
  }

   
  function () public payable {
    emit Received(msg.sender, msg.value, address(this).balance);
  }

   
  function sendTo(address _payee, uint256 _amount) private {
    require(_payee != 0 && _payee != address(this), "Burning tokens and self transfer not allowed");
    require(_amount > 0, "Must transfer greater than zero");
    _payee.transfer(_amount);
    emit Sent(_payee, _amount, address(this).balance);
  }

   
  function balanceOf() public view returns (uint256) {
    return address(this).balance;
  }

   
  function redeemTokens(address _player, address _tokenAddress) public returns (bool success) {
    require(acceptedToken(_tokenAddress), "Token must be a registered token");
    require(block.timestamp >= closeDate, "Game must be closed");
    require(gameDone == true, "Can't redeem tokens until results have been uploaded");
     
    IPickFlixToken _token = IPickFlixToken(_tokenAddress);
     
    uint256 _allowedValue = _token.allowance(_player, address(this));
     
    _token.transferFrom(_player, address(this), _allowedValue);
     
    uint256 _transferedTokens = _allowedValue;
     
    uint256 _playerPercentage = percent(_transferedTokens, _token.totalSupply(), 4);
     
    uint256 _playerRewards = movies[_tokenAddress].totalPlayerRewards.mul(_playerPercentage).div(10**4);
     
    sendTo(_player, _playerRewards);
     
    return true;
  }

   
  function acceptedToken(address _tokenAddress) public view returns (bool) {
    return movies[_tokenAddress].accepted;
  }

   
  function calculateTokensIssued(address _tokenAddress) private view returns (uint256) {
    IPickFlixToken _token = IPickFlixToken(_tokenAddress);
    return _token.totalSupply();
  }

  function closeToken(address _tokenAddress) private {
    IPickFlixToken _token = IPickFlixToken(_tokenAddress);
    _token.closeNow();
  }

  function calculateTokenRate(address _tokenAddress) private view returns (uint256) {
    IPickFlixToken _token = IPickFlixToken(_tokenAddress);
    return _token.rate();
  }

   
   
  function calculateOracleFee() private view returns (uint256) {
    return balanceOf().mul(oracleFeePercent).div(100);
  }

   
  function calculateTotalPlayerRewards() private view returns (uint256) {
    return balanceOf().sub(oracleFee);
  }

   
  function calculateTotalBoxOffice(uint256[] _boxOfficeTotals) private pure returns (uint256) {
    uint256 _totalBoxOffice = 0;
    for (uint256 i = 0; i < _boxOfficeTotals.length; i++) {
      _totalBoxOffice = _totalBoxOffice.add(_boxOfficeTotals[i]);
    }
    return _totalBoxOffice;
  }

   
  function calculateTotalPlayerRewardsPerMovie(uint256 _boxOfficeTotal) public view returns (uint256) {
     
    uint256 _boxOfficePercentage = percent(_boxOfficeTotal, totalBoxOffice, 4);
     
    uint256 _rewards = totalPlayerRewards.mul(_boxOfficePercentage).div(10**4);
    return _rewards;
  }

  function calculateRewardPerToken(uint256 _boxOfficeTotal, address tokenAddress) public view returns (uint256) {
    IPickFlixToken token = IPickFlixToken(tokenAddress);
    uint256 _playerBalance = token.balanceOf(msg.sender);
    uint256 _playerPercentage = percent(_playerBalance, token.totalSupply(), 4);
     
    uint256 _playerRewards = movies[tokenAddress].totalPlayerRewards.mul(_playerPercentage).div(10**4);
    return _playerRewards;
  }

   
  function calculateGameResults(address[] _tokenAddresses, uint256[] _boxOfficeTotals) public onlyOwner {
     
    require(_tokenAddresses.length == _boxOfficeTotals.length, "Must have box office results per token");
     
    require(gameDone == false, "Can only submit results once");
    require(block.timestamp >= closeDate, "Game must have ended before results can be entered");
    oracleFee = calculateOracleFee();
    totalPlayerRewards = calculateTotalPlayerRewards();
    totalBoxOffice = calculateTotalBoxOffice(_boxOfficeTotals);

     
    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      tokensIssued = tokensIssued.add(calculateTokensIssued(_tokenAddresses[i]));
      movies[_tokenAddresses[i]] = Movie(_boxOfficeTotals[i], calculateTotalPlayerRewardsPerMovie(_boxOfficeTotals[i]), true);
    }

     
    owner().transfer(oracleFee);
    gameDone = true;
  }

   
  function abortGame(address[] _tokenAddresses) public onlyOwner {
     
    require(gameDone == false, "Can only submit results once");
    oracleFee = 0;
    totalPlayerRewards = calculateTotalPlayerRewards();
    closeDate = block.timestamp;

    for (uint256 i = 0; i < _tokenAddresses.length; i++) {
      uint tokenSupply = calculateTokensIssued(_tokenAddresses[i]);
      tokensIssued = tokensIssued.add(tokenSupply);
      closeToken(_tokenAddresses[i]);
    }
    totalBoxOffice = tokensIssued;

     
    for (i = 0; i < _tokenAddresses.length; i++) {
      tokenSupply = calculateTokensIssued(_tokenAddresses[i]);
      movies[_tokenAddresses[i]] = Movie(tokenSupply, calculateTotalPlayerRewardsPerMovie(tokenSupply), true);
    }

    gameDone = true;
  }

  function killGame(address[] _tokenAddresses) public onlyOwner {
    for (uint i = 0; i < _tokenAddresses.length; i++) {
      IPickFlixToken token = IPickFlixToken(_tokenAddresses[i]);
      require(token.balanceOf(this) == token.totalSupply());
      token.kill();
    }
    selfdestruct(owner());
  }
}



 
contract PickflixGameFactory {

  struct Game {
    string gameName;
    address gameMaster;
    uint openDate;
    uint closeDate;
  }

   
  Game[] public games;

   
  mapping(address => address[]) public gameTokens;

   
  address public owner;

   
  address public oracleFeeReceiver;

   
  event OraclePayoutReceived(uint value);

  constructor() public {
    owner = msg.sender;
    oracleFeeReceiver = msg.sender;
  }

  function () public payable {
    emit OraclePayoutReceived(msg.value);
  }

   
  modifier onlyOwner {
    require(msg.sender == owner, "Only owner can execute this");
    _;
  }

   
  function createGame(string gameName, uint closeDate, uint oracleFeePercent) public onlyOwner returns (address){
    address gameMaster = new PickflixGameMaster(gameName, closeDate, oracleFeePercent);
    games.push(Game({
      gameName: gameName,
      gameMaster: gameMaster,
      openDate: block.timestamp,
      closeDate: closeDate
    }));
    return gameMaster;
  }

   
  function createTokenForGame(uint gameIndex, string tokenName, string tokenSymbol, uint rate, string externalID) public onlyOwner returns (address) {
    Game storage game = games[gameIndex];
    address token = new PickFlixToken(tokenName, tokenSymbol, rate, game.gameMaster, game.closeDate, externalID);
    gameTokens[game.gameMaster].push(token);
    return token;
  }

   
  function closeGame(uint gameIndex, address[] _tokenAddresses, uint256[] _boxOfficeTotals) public onlyOwner {
    PickflixGameMaster(games[gameIndex].gameMaster).calculateGameResults(_tokenAddresses, _boxOfficeTotals);
  }

   
  function abortGame(uint gameIndex) public onlyOwner {
    address gameMaster = games[gameIndex].gameMaster;
    PickflixGameMaster(gameMaster).abortGame(gameTokens[gameMaster]);
  }

   
  function killGame(uint gameIndex) public onlyOwner {
    address gameMaster = games[gameIndex].gameMaster;
    PickflixGameMaster(gameMaster).killGame(gameTokens[gameMaster]);
    games[gameIndex] = games[games.length-1];
    delete games[games.length-1];
    games.length--;
  }

   
  function setOwner(address newOwner) public onlyOwner {
    owner = newOwner;
  }

   
  function setOracleFeeReceiver(address newReceiver) public onlyOwner {
    oracleFeeReceiver = newReceiver;
  }

   
  function sendOraclePayout() public {
    oracleFeeReceiver.transfer(address(this).balance);
  }
}