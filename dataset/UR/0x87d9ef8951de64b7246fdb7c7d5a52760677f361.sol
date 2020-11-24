 

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

 

 
contract TokenFaucet is TokenRecover {
  using SafeMath for uint256;

   
  struct RecipientDetail {
    bool exists;
    uint256 tokens;
    uint256 lastUpdate;
    address referral;
  }

   
  struct ReferralDetail {
    uint256 tokens;
    address[] recipients;
  }

   
  uint256 private _pauseTime = 1 days;

   
  ERC20 private _token;

   
  uint256 private _dailyRate;

   
  uint256 private _referralPerMille;

   
  uint256 private _totalDistributedTokens;

   
  mapping (address => RecipientDetail) private _recipientList;

   
  address[] private _recipients;

   
  mapping (address => ReferralDetail) private _referralList;

   
  constructor(
    address token,
    uint256 dailyRate,
    uint256 referralPerMille
  )
    public
  {
    require(token != address(0));
    require(dailyRate > 0);
    require(referralPerMille > 0);

    _token = ERC20(token);
    _dailyRate = dailyRate;
    _referralPerMille = referralPerMille;
  }

   
  function () external payable {
    require(msg.value == 0);

    getTokens();
  }

   
  function getTokens() public {
     
    _distributeTokens(msg.sender, address(0));
  }

   
  function getTokensWithReferral(address referral) public {
    require(referral != msg.sender);

     
    _distributeTokens(msg.sender, referral);
  }

   
  function token() public view returns (ERC20) {
    return _token;
  }

   
  function dailyRate() public view returns (uint256) {
    return _dailyRate;
  }

   
  function referralTokens() public view returns (uint256) {
    return _dailyRate.mul(_referralPerMille).div(1000);
  }

   
  function totalDistributedTokens() public view returns (uint256) {
    return _totalDistributedTokens;
  }

   
  function receivedTokens(address account) public view returns (uint256) {
    return _recipientList[account].tokens;
  }

   
  function lastUpdate(address account) public view returns (uint256) {
    return _recipientList[account].lastUpdate;
  }

   
  function nextClaimTime(address account) public view returns (uint256) {
    return !_recipientList[account].exists ? 0 : _recipientList[account].lastUpdate + _pauseTime;
  }

   
  function getReferral(address account) public view returns (address) {
    return _recipientList[account].referral;
  }

   
  function earnedByReferral(address account) public view returns (uint256) {
    return _referralList[account].tokens;
  }

   
  function getReferredAddresses(address account) public view returns (address[]) {
    return _referralList[account].recipients;
  }

   
  function getReferredAddressesLength(address account) public view returns (uint) {
    return _referralList[account].recipients.length;
  }

   
  function remainingTokens() public view returns (uint256) {
    return _token.balanceOf(this);
  }

   
  function getRecipientAddress(uint256 index) public view returns (address) {
    return _recipients[index];
  }

   
  function getRecipientsLength() public view returns (uint) {
    return _recipients.length;
  }

   
  function setRates(uint256 newDailyRate, uint256 newReferralPerMille) public onlyOwner {
    require(newDailyRate > 0);
    require(newReferralPerMille > 0);

    _dailyRate = newDailyRate;
    _referralPerMille = newReferralPerMille;
  }

   
  function _distributeTokens(address account, address referral) internal {
    require(nextClaimTime(account) <= block.timestamp);  

     
    if (!_recipientList[account].exists) {
      _recipients.push(account);
      _recipientList[account].exists = true;

       
      if (referral != address(0)) {
        _recipientList[account].referral = referral;
        _referralList[referral].recipients.push(account);
      }
    }

     
    _recipientList[account].lastUpdate = block.timestamp;  
    _recipientList[account].tokens = _recipientList[account].tokens.add(_dailyRate);

     
    _totalDistributedTokens = _totalDistributedTokens.add(_dailyRate);

     
    _token.transfer(account, _dailyRate);

     
    if (_recipientList[account].referral != address(0)) {
       
      address firstReferral = _recipientList[account].referral;

      uint256 referralEarnedTokens = referralTokens();

       
      _referralList[firstReferral].tokens = _referralList[firstReferral].tokens.add(referralEarnedTokens);

       
      _totalDistributedTokens = _totalDistributedTokens.add(referralEarnedTokens);

       
      _token.transfer(firstReferral, referralEarnedTokens);
    }
  }
}